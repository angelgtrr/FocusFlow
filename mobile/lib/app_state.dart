import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'date_utils.dart';
import 'local_db.dart';
import 'models.dart';
import 'notifications.dart';

class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();
  final LocalDb localDb = LocalDb();

  bool initializing = true;
  bool authenticated = false;
  bool loadingData = false;
  bool offline = false;
  int pendingOpsCount = 0;
  String? error;
  String userName = '';

  List<Dimension> dimensions = [];
  List<Task> tasks = [];
  List<Entry> entries = [];
  List<TaskCompletion> taskCompletions = [];
  List<DayNote> dayNotes = [];
  List<SavedDate> dates = [];

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _flushing = false;

  Future<void> init() async {
    await api.load();
    await localDb.init();
    await _hydrateFromCache();
    pendingOpsCount = await localDb.queueLength();

    if (api.hasBaseUrl && api.hasSession) {
      // Trust the saved session optimistically so cached data is usable the
      // instant the app opens, even with no signal. refresh() verifies the
      // session and syncs in the background; it only logs the user out if
      // the server explicitly rejects the cookie (not on a network failure).
      authenticated = true;
      initializing = false;
      notifyListeners();
      unawaited(refresh());
    } else {
      initializing = false;
      notifyListeners();
    }

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && authenticated) refresh();
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _hydrateFromCache() async {
    dimensions = (await localDb.getAll(LocalDb.dimension)).map(Dimension.fromJson).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    tasks = (await localDb.getAll(LocalDb.task)).map(Task.fromJson).toList();
    entries = (await localDb.getAll(LocalDb.entry)).map(Entry.fromJson).toList();
    taskCompletions = (await localDb.getAll(LocalDb.taskCompletion)).map(TaskCompletion.fromJson).toList();
    dayNotes = (await localDb.getAll(LocalDb.dayNote)).map(DayNote.fromJson).toList();
    dates = (await localDb.getAll(LocalDb.savedDate)).map(SavedDate.fromJson).toList();
    final settingsRows = await localDb.getAll(LocalDb.settings);
    userName = settingsRows.isEmpty ? '' : (settingsRows.first['name'] as String? ?? '');
  }

  /// Purely local — the server has no notion of a display name, so this
  /// never goes through the sync queue.
  Future<void> setUserName(String name) async {
    userName = name;
    await localDb.put(LocalDb.settings, 'profile', {'name': name});
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
    try {
      await api.logout();
    } catch (_) {
      // Best-effort — the cookie is cleared locally by api.logout() even if
      // the network call itself fails, which is all that matters offline.
    }
    authenticated = false;
    dimensions = [];
    tasks = [];
    entries = [];
    taskCompletions = [];
    dayNotes = [];
    dates = [];
    if (Platform.isAndroid) await hideProgressNotification();
    notifyListeners();
  }

  Future<void> refresh() async {
    loadingData = true;
    notifyListeners();
    try {
      await _flushQueue();
      if (offline) return;

      final results = await Future.wait([
        api.getTasks(),
        api.getEntries(),
        api.getDimensions(),
        api.getTaskCompletions(),
        api.getDayNotes(),
        api.getDates(),
      ]);
      tasks = results[0] as List<Task>;
      entries = results[1] as List<Entry>;
      dimensions = results[2] as List<Dimension>;
      taskCompletions = results[3] as List<TaskCompletion>;
      dayNotes = results[4] as List<DayNote>;
      dates = results[5] as List<SavedDate>;
      await Future.wait([
        localDb.replaceAll(LocalDb.task, tasks.map((t) => t.toJson()).toList(), idField: 'id'),
        localDb.replaceAll(LocalDb.entry, entries.map((e) => e.toJson()).toList(), idField: 'id'),
        localDb.replaceAll(LocalDb.dimension, dimensions.map((d) => d.toJson()).toList(), idField: 'id'),
        localDb.replaceAll(LocalDb.taskCompletion, taskCompletions.map((c) => c.toJson()).toList(), idField: 'id'),
        localDb.replaceAll(LocalDb.dayNote, dayNotes.map((n) => n.toJson()).toList(), idField: 'date'),
        localDb.replaceAll(LocalDb.savedDate, dates.map((d) => d.toJson()).toList(), idField: 'id'),
      ]);
      offline = false;
      error = null;
      if (Platform.isAndroid) {
        await updateProgressNotificationFrom(dimensions: dimensions, entries: entries);
      }
    } on UnauthorizedException {
      authenticated = false;
    } on NetworkException {
      offline = true;
    } catch (e) {
      offline = true;
      final hasCache = dimensions.isNotEmpty || tasks.isNotEmpty || entries.isNotEmpty;
      if (!hasCache) error = e is ApiException ? e.message : 'Failed to load data.';
    } finally {
      loadingData = false;
      pendingOpsCount = await localDb.queueLength();
      notifyListeners();
    }
  }

  // --- Sync engine ---
  //
  // Every mutation below applies immediately to the in-memory lists and the
  // local cache, then queues the equivalent API call and fires off a
  // best-effort sync in the background (unawaited) — callers see the change
  // instantly whether or not there's a connection right now.

  Future<void> _trySync() async {
    await _flushQueue();
    await _hydrateFromCache();
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
  }

  Future<void> _flushQueue() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.every((r) => r == ConnectivityResult.none)) {
        offline = true;
        return;
      }
      while (true) {
        final queue = await localDb.getQueue();
        if (queue.isEmpty) break;
        final op = queue.first;
        try {
          await _applyOp(op);
          await localDb.removeOp(op.id);
          offline = false;
        } on NetworkException {
          offline = true;
          break;
        } on UnauthorizedException {
          authenticated = false;
          break;
        } on ApiException catch (e) {
          // The server rejected this op outright (stale reference, conflict,
          // validation failure) — retrying won't help, so drop it rather
          // than block every op queued after it.
          debugPrint('Dropping unsyncable op ${op.opType}: ${e.message}');
          await localDb.removeOp(op.id);
        }
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _applyOp(PendingOp op) async {
    final p = op.payload;
    switch (op.opType) {
      case 'createDimension':
        final server = await api.createDimension(p['name'] as String);
        await localDb.remapId(LocalDb.dimension, p['temp_id'] as int, server['id'] as int);
        break;
      case 'renameDimension':
        await api.updateDimension(p['target_id'] as int, p['name'] as String);
        break;
      case 'deleteDimension':
        await api.deleteDimension(p['target_id'] as int);
        break;
      case 'createTask':
        final server = await api.createTask(
          title: p['title'] as String,
          description: p['description'] as String,
          dimensionId: p['dimension_id'] as int?,
        );
        await localDb.remapId(LocalDb.task, p['temp_id'] as int, server['id'] as int);
        break;
      case 'updateTaskStatus':
        await api.updateTaskStatus(p['target_id'] as int, taskStatusFromString(p['status'] as String));
        break;
      case 'deleteTask':
        await api.deleteTask(p['target_id'] as int);
        break;
      case 'logEntry':
        await api.logEntry(
          dimensionId: p['dimension_id'] as int,
          date: p['date'] as String,
          score: p['score'] as int,
          note: p['note'] as String,
        );
        break;
      case 'completeTask':
        await api.completeTask(p['task_id'] as int, p['date'] as String);
        break;
      case 'uncompleteTask':
        await api.uncompleteTask(p['task_id'] as int, p['date'] as String);
        break;
      case 'saveDayNote':
        await api.saveDayNote(p['date'] as String, p['note'] as String);
        break;
      case 'createDate':
        final server = await api.createDate(
          title: p['title'] as String,
          note: p['note'] as String,
          date: p['date'] as String,
          recurring: p['recurring'] as String,
        );
        await localDb.remapId(LocalDb.savedDate, p['temp_id'] as int, server['id'] as int);
        break;
      case 'updateDate':
        await api.updateDate(
          p['target_id'] as int,
          title: p['title'] as String,
          note: p['note'] as String,
          date: p['date'] as String,
          recurring: p['recurring'] as String,
        );
        break;
      case 'deleteDate':
        await api.deleteDate(p['target_id'] as int);
        break;
    }
  }

  // --- Mutations ---

  Future<void> logEntry({
    required int dimensionId,
    required int score,
    required String note,
    String? date,
  }) async {
    final d = date ?? todayKey();
    final now = DateTime.now().toIso8601String();
    final dimName = dimensions
        .firstWhere((x) => x.id == dimensionId, orElse: () => Dimension(id: dimensionId, name: '', createdAt: now))
        .name;
    final existingIndex = entries.indexWhere((e) => e.dimensionId == dimensionId && e.date == d);
    final entry = Entry(
      id: existingIndex >= 0 ? entries[existingIndex].id : LocalDb.tempId(),
      dimensionId: dimensionId,
      date: d,
      score: score,
      note: note,
      createdAt: existingIndex >= 0 ? entries[existingIndex].createdAt : now,
      updatedAt: now,
      dimensionName: dimName,
    );
    entries = existingIndex >= 0
        ? ([...entries]..[existingIndex] = entry)
        : [...entries, entry];
    await localDb.put(LocalDb.entry, entry.id, entry.toJson());
    await localDb.enqueueOp('logEntry', {'dimension_id': dimensionId, 'date': d, 'score': score, 'note': note});
    pendingOpsCount = await localDb.queueLength();
    if (Platform.isAndroid) {
      await updateProgressNotificationFrom(dimensions: dimensions, entries: entries);
    }
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> toggleTaskCompletion(int taskId, bool completed, [String? forDate]) async {
    final date = forDate ?? todayKey();
    if (completed) {
      if (!taskCompletions.any((c) => c.taskId == taskId && c.date == date)) {
        final title = tasks
            .firstWhere(
              (t) => t.id == taskId,
              orElse: () => Task(
                id: taskId,
                title: '',
                description: '',
                dimensionId: null,
                dimensionName: null,
                status: TaskStatus.active,
                createdAt: DateTime.now().toIso8601String(),
              ),
            )
            .title;
        final completion = TaskCompletion(
          id: LocalDb.tempId(),
          taskId: taskId,
          date: date,
          createdAt: DateTime.now().toIso8601String(),
          taskTitle: title,
        );
        taskCompletions = [...taskCompletions, completion];
        await localDb.put(LocalDb.taskCompletion, completion.id, completion.toJson());
      }
      await localDb.enqueueOp('completeTask', {'task_id': taskId, 'date': date});
    } else {
      final removed = taskCompletions.where((c) => c.taskId == taskId && c.date == date).toList();
      taskCompletions = taskCompletions.where((c) => !(c.taskId == taskId && c.date == date)).toList();
      for (final c in removed) {
        await localDb.remove(LocalDb.taskCompletion, c.id);
      }
      await localDb.enqueueOp('uncompleteTask', {'task_id': taskId, 'date': date});
    }
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> createDimension(String name) async {
    final tempId = LocalDb.tempId();
    final dim = Dimension(id: tempId, name: name, createdAt: DateTime.now().toIso8601String());
    dimensions = [...dimensions, dim]..sort((a, b) => a.name.compareTo(b.name));
    await localDb.put(LocalDb.dimension, tempId, dim.toJson());
    await localDb.enqueueOp('createDimension', {'temp_id': tempId, 'name': name});
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> renameDimension(int id, String name) async {
    final idx = dimensions.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      final updated = Dimension(id: id, name: name, createdAt: dimensions[idx].createdAt);
      dimensions = [...dimensions]..[idx] = updated;
      dimensions.sort((a, b) => a.name.compareTo(b.name));
      await localDb.put(LocalDb.dimension, id, updated.toJson());

      tasks = tasks
          .map((t) => t.dimensionId == id
              ? Task(
                  id: t.id,
                  title: t.title,
                  description: t.description,
                  dimensionId: t.dimensionId,
                  dimensionName: name,
                  status: t.status,
                  createdAt: t.createdAt,
                )
              : t)
          .toList();
      for (final t in tasks.where((t) => t.dimensionId == id)) {
        await localDb.put(LocalDb.task, t.id, t.toJson());
      }

      entries = entries
          .map((e) => e.dimensionId == id
              ? Entry(
                  id: e.id,
                  dimensionId: e.dimensionId,
                  date: e.date,
                  score: e.score,
                  note: e.note,
                  createdAt: e.createdAt,
                  updatedAt: e.updatedAt,
                  dimensionName: name,
                )
              : e)
          .toList();
      for (final e in entries.where((e) => e.dimensionId == id)) {
        await localDb.put(LocalDb.entry, e.id, e.toJson());
      }
    }
    await localDb.enqueueOp('renameDimension', {'target_id': id, 'name': name});
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> deleteDimension(int id) async {
    dimensions = dimensions.where((d) => d.id != id).toList();
    tasks = tasks
        .map((t) => t.dimensionId == id
            ? Task(
                id: t.id,
                title: t.title,
                description: t.description,
                dimensionId: null,
                dimensionName: null,
                status: t.status,
                createdAt: t.createdAt,
              )
            : t)
        .toList();
    for (final t in tasks.where((t) => t.dimensionId == null)) {
      await localDb.put(LocalDb.task, t.id, t.toJson());
    }
    final removedEntries = entries.where((e) => e.dimensionId == id).toList();
    entries = entries.where((e) => e.dimensionId != id).toList();
    for (final e in removedEntries) {
      await localDb.remove(LocalDb.entry, e.id);
    }
    await localDb.remove(LocalDb.dimension, id);
    await localDb.enqueueOp('deleteDimension', {'target_id': id});
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> createTask({
    required String title,
    required String description,
    required int? dimensionId,
  }) async {
    final tempId = LocalDb.tempId();
    final dimName = dimensionId == null
        ? null
        : dimensions
            .firstWhere((d) => d.id == dimensionId, orElse: () => Dimension(id: dimensionId, name: '', createdAt: ''))
            .name;
    final task = Task(
      id: tempId,
      title: title,
      description: description,
      dimensionId: dimensionId,
      dimensionName: dimName,
      status: TaskStatus.active,
      createdAt: DateTime.now().toIso8601String(),
    );
    tasks = [task, ...tasks];
    await localDb.put(LocalDb.task, tempId, task.toJson());
    await localDb.enqueueOp(
      'createTask',
      {'temp_id': tempId, 'title': title, 'description': description, 'dimension_id': dimensionId},
    );
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> updateTaskStatus(int id, TaskStatus status) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx >= 0) {
      final old = tasks[idx];
      final updated = Task(
        id: old.id,
        title: old.title,
        description: old.description,
        dimensionId: old.dimensionId,
        dimensionName: old.dimensionName,
        status: status,
        createdAt: old.createdAt,
      );
      tasks = [...tasks]..[idx] = updated;
      await localDb.put(LocalDb.task, id, updated.toJson());
    }
    await localDb.enqueueOp('updateTaskStatus', {'target_id': id, 'status': status.name});
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> deleteTask(int id) async {
    tasks = tasks.where((t) => t.id != id).toList();
    final removedCompletions = taskCompletions.where((c) => c.taskId == id).toList();
    taskCompletions = taskCompletions.where((c) => c.taskId != id).toList();
    for (final c in removedCompletions) {
      await localDb.remove(LocalDb.taskCompletion, c.id);
    }
    await localDb.remove(LocalDb.task, id);
    await localDb.enqueueOp('deleteTask', {'target_id': id});
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> saveDayNote(String date, String note) async {
    final now = DateTime.now().toIso8601String();
    final idx = dayNotes.indexWhere((n) => n.date == date);
    final updated = DayNote(
      date: date,
      note: note,
      createdAt: idx >= 0 ? dayNotes[idx].createdAt : now,
      updatedAt: now,
    );
    dayNotes = idx >= 0 ? ([...dayNotes]..[idx] = updated) : [...dayNotes, updated];
    await localDb.put(LocalDb.dayNote, date, updated.toJson());
    await localDb.enqueueOp('saveDayNote', {'date': date, 'note': note});
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> createDate({
    required String title,
    required String note,
    required String date,
    required bool recurringYearly,
  }) async {
    final tempId = LocalDb.tempId();
    final now = DateTime.now().toIso8601String();
    final recurring = recurringYearly ? 'yearly' : 'none';
    final savedDate = SavedDate(
      id: tempId,
      title: title,
      note: note,
      date: date,
      recurring: recurring,
      createdAt: now,
      updatedAt: now,
    );
    dates = [...dates, savedDate];
    await localDb.put(LocalDb.savedDate, tempId, savedDate.toJson());
    await localDb.enqueueOp(
      'createDate',
      {'temp_id': tempId, 'title': title, 'note': note, 'date': date, 'recurring': recurring},
    );
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> updateDate(
    int id, {
    required String title,
    required String note,
    required String date,
    required bool recurringYearly,
  }) async {
    final recurring = recurringYearly ? 'yearly' : 'none';
    final idx = dates.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      final old = dates[idx];
      final updated = SavedDate(
        id: id,
        title: title,
        note: note,
        date: date,
        recurring: recurring,
        createdAt: old.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      dates = [...dates]..[idx] = updated;
      await localDb.put(LocalDb.savedDate, id, updated.toJson());
    }
    await localDb.enqueueOp(
      'updateDate',
      {'target_id': id, 'title': title, 'note': note, 'date': date, 'recurring': recurring},
    );
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }

  Future<void> deleteDate(int id) async {
    dates = dates.where((d) => d.id != id).toList();
    await localDb.remove(LocalDb.savedDate, id);
    await localDb.enqueueOp('deleteDate', {'target_id': id});
    pendingOpsCount = await localDb.queueLength();
    notifyListeners();
    unawaited(_trySync());
  }
}
