import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Not authenticated']);
}

/// The request never reached the server — no connection, DNS failure,
/// timeout, etc. Distinct from [ApiException] (a response the server did
/// send back, e.g. a validation error) so callers can tell "we're offline"
/// apart from "the server rejected this."
class NetworkException extends ApiException {
  NetworkException([super.message = 'Could not reach the server. Check your connection.']);
}

class ApiClient {
  static const _baseUrlPrefsKey = 'focusflow_base_url';
  static const _cookiePrefsKey = 'focusflow_cookie';
  static const _timeout = Duration(seconds: 8);

  String baseUrl = '';
  String? _cookie;
  final http.Client _client = http.Client();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString(_baseUrlPrefsKey) ?? '';
    _cookie = prefs.getString(_cookiePrefsKey);
  }

  bool get hasBaseUrl => baseUrl.trim().isNotEmpty;

  bool get hasSession => _cookie != null;

  Future<void> setBaseUrl(String url) async {
    baseUrl = url.trim();
    if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefsKey, baseUrl);
  }

  Future<void> _persistCookie() async {
    final prefs = await SharedPreferences.getInstance();
    if (_cookie == null) {
      await prefs.remove(_cookiePrefsKey);
    } else {
      await prefs.setString(_cookiePrefsKey, _cookie!);
    }
  }

  Future<void> clearSession() async {
    _cookie = null;
    await _persistCookie();
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl/api$path').replace(queryParameters: query);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    if (!hasBaseUrl) {
      throw ApiException('Server address is not set.');
    }
    final uri = _uri(path, query);
    final headers = {'Content-Type': 'application/json', 'Cookie': ?_cookie};

    http.Response res;
    try {
      switch (method) {
        case 'GET':
          res = await _client.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          res = await _client
              .post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
              .timeout(_timeout);
          break;
        case 'PATCH':
          res = await _client
              .patch(uri, headers: headers, body: body == null ? null : jsonEncode(body))
              .timeout(_timeout);
          break;
        case 'DELETE':
          res = await _client.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          throw ApiException('Unsupported method $method');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      // Covers unreachable hosts, DNS failures, and the timeout above — any
      // case where we never got a response back from the server at all.
      throw NetworkException('Could not reach server at $baseUrl. Check the address and your connection.');
    }

    final setCookie = res.headers['set-cookie'];
    if (setCookie != null) {
      _cookie = setCookie.split(';').first;
      await _persistCookie();
    }

    if (res.statusCode == 401) {
      throw UnauthorizedException();
    }
    if (res.statusCode >= 400) {
      String message = 'Request failed: ${res.statusCode}';
      try {
        final parsed = jsonDecode(res.body);
        if (parsed is Map && parsed['error'] != null) message = parsed['error'].toString();
      } catch (_) {}
      throw ApiException(message);
    }
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  // --- Auth ---

  Future<void> login(String password) async {
    await _request('POST', '/login', body: {'password': password});
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/logout');
    } finally {
      await clearSession();
    }
  }

  Future<bool> getSession() async {
    final data = await _request('GET', '/session');
    return data['authenticated'] == true;
  }

  // --- Dimensions ---

  Future<List<Dimension>> getDimensions() async {
    final data = await _request('GET', '/dimensions') as List;
    return data.map((e) => Dimension.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createDimension(String name) =>
      _request('POST', '/dimensions', body: {'name': name}).then((r) => r as Map<String, dynamic>);

  Future<void> updateDimension(int id, String name) =>
      _request('PATCH', '/dimensions/$id', body: {'name': name});

  Future<void> deleteDimension(int id) => _request('DELETE', '/dimensions/$id');

  // --- Tasks ---

  Future<List<Task>> getTasks() async {
    final data = await _request('GET', '/tasks') as List;
    return data.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createTask({
    required String title,
    required String description,
    required int? dimensionId,
  }) => _request(
    'POST',
    '/tasks',
    body: {'title': title, 'description': description, 'dimension_id': dimensionId},
  ).then((r) => r as Map<String, dynamic>);

  Future<void> updateTaskStatus(int id, TaskStatus status) =>
      _request('PATCH', '/tasks/$id', body: {'status': status.name});

  Future<void> deleteTask(int id) => _request('DELETE', '/tasks/$id');

  // --- Entries ---

  Future<List<Entry>> getEntries() async {
    final data = await _request('GET', '/entries') as List;
    return data.map((e) => Entry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> logEntry({
    required int dimensionId,
    required String date,
    required int score,
    required String note,
  }) => _request(
    'POST',
    '/entries',
    body: {'dimension_id': dimensionId, 'date': date, 'score': score, 'note': note},
  );

  // --- Task completions ---

  Future<List<TaskCompletion>> getTaskCompletions() async {
    final data = await _request('GET', '/task-completions') as List;
    return data.map((e) => TaskCompletion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> completeTask(int taskId, String date) =>
      _request('POST', '/task-completions', body: {'task_id': taskId, 'date': date});

  Future<void> uncompleteTask(int taskId, String date) => _request(
    'DELETE',
    '/task-completions',
    query: {'task_id': taskId.toString(), 'date': date},
  );

  // --- Day notes ---

  Future<List<DayNote>> getDayNotes() async {
    final data = await _request('GET', '/day-notes') as List;
    return data.map((e) => DayNote.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveDayNote(String date, String note) =>
      _request('POST', '/day-notes', body: {'date': date, 'note': note});

  // --- Dates ---

  Future<List<SavedDate>> getDates() async {
    final data = await _request('GET', '/dates') as List;
    return data.map((e) => SavedDate.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createDate({
    required String title,
    required String note,
    required String date,
    required String recurring,
  }) => _request(
    'POST',
    '/dates',
    body: {'title': title, 'note': note, 'date': date, 'recurring': recurring},
  ).then((r) => r as Map<String, dynamic>);

  Future<void> updateDate(
    int id, {
    required String title,
    required String note,
    required String date,
    required String recurring,
  }) => _request(
    'PATCH',
    '/dates/$id',
    body: {'title': title, 'note': note, 'date': date, 'recurring': recurring},
  );

  Future<void> deleteDate(int id) => _request('DELETE', '/dates/$id');
}
