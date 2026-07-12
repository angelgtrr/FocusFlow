import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'date_utils.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();

  bool initializing = true;
  bool authenticated = false;
  bool loadingData = false;
  String? error;

  List<Dimension> dimensions = [];
  List<Task> tasks = [];
  List<Entry> entries = [];
  List<TaskCompletion> taskCompletions = [];

  Future<void> init() async {
    await api.load();
    if (api.hasBaseUrl) {
      try {
        authenticated = await api.getSession();
        if (authenticated) await refresh();
      } catch (_) {
        authenticated = false;
      }
    }
    initializing = false;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    await api.setBaseUrl(url);
    notifyListeners();
  }

  Future<void> login(String password) async {
    await api.login(password);
    authenticated = true;
    await refresh();
  }

  Future<void> logout() async {
    await api.logout();
    authenticated = false;
    dimensions = [];
    tasks = [];
    entries = [];
    taskCompletions = [];
    notifyListeners();
  }

  Future<void> refresh() async {
    loadingData = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.getTasks(),
        api.getEntries(),
        api.getDimensions(),
        api.getTaskCompletions(),
      ]);
      tasks = results[0] as List<Task>;
      entries = results[1] as List<Entry>;
      dimensions = results[2] as List<Dimension>;
      taskCompletions = results[3] as List<TaskCompletion>;
    } on UnauthorizedException {
      authenticated = false;
    } catch (e) {
      error = e is ApiException ? e.message : 'Failed to load data.';
    } finally {
      loadingData = false;
      notifyListeners();
    }
  }

  Future<void> logEntry({
    required int dimensionId,
    required int score,
    required String note,
    String? date,
  }) async {
    await api.logEntry(dimensionId: dimensionId, date: date ?? todayKey(), score: score, note: note);
    await refresh();
  }

  Future<void> toggleTaskCompletion(int taskId, bool completed, [String? forDate]) async {
    final date = forDate ?? todayKey();
    if (completed) {
      await api.completeTask(taskId, date);
    } else {
      await api.uncompleteTask(taskId, date);
    }
    await refresh();
  }

  Future<void> createDimension(String name) async {
    await api.createDimension(name);
    await refresh();
  }

  Future<void> renameDimension(int id, String name) async {
    await api.updateDimension(id, name);
    await refresh();
  }

  Future<void> deleteDimension(int id) async {
    await api.deleteDimension(id);
    await refresh();
  }

  Future<void> createTask({
    required String title,
    required String description,
    required int? dimensionId,
  }) async {
    await api.createTask(title: title, description: description, dimensionId: dimensionId);
    await refresh();
  }

  Future<void> updateTaskStatus(int id, TaskStatus status) async {
    await api.updateTaskStatus(id, status);
    await refresh();
  }

  Future<void> deleteTask(int id) async {
    await api.deleteTask(id);
    await refresh();
  }
}
