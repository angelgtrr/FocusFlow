import 'dart:io';

import 'package:flutter/foundation.dart';

import 'date_utils.dart';
import 'local_db.dart';
import 'models.dart';
import 'notifications.dart';

/// Holds all app data in memory, backed by [LocalDb] as the on-device
/// source of truth. There is no server and nothing to sync — every mutation
/// updates the in-memory lists and writes straight through to the local db.
class AppState extends ChangeNotifier {
  final LocalDb localDb = LocalDb();

  bool initializing = true;
  String? error;

  List<Dimension> dimensions = [];
  List<Task> tasks = [];
  List<Entry> entries = [];
  List<TaskCompletion> taskCompletions = [];
  List<DayNote> dayNotes = [];
  List<SavedDate> dates = [];

  Future<void> init() async {
    try {
      await localDb.init();
      await _hydrateFromCache();
      if (Platform.isAndroid) {
        await updateProgressNotificationFrom(dimensions: dimensions, entries: entries);
      }
    } catch (e) {
      error = 'Failed to load local data.';
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<void> _hydrateFromCache() async {
    dimensions = (await localDb.getAll(LocalDb.dimension)).map(Dimension.fromJson).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    tasks = (await localDb.getAll(LocalDb.task)).map(Task.fromJson).toList();
    entries = (await localDb.getAll(LocalDb.entry)).map(Entry.fromJson).toList();
    taskCompletions = (await localDb.getAll(LocalDb.taskCompletion)).map(TaskCompletion.fromJson).toList();
    dayNotes = (await localDb.getAll(LocalDb.dayNote)).map(DayNote.fromJson).toList();
    dates = (await localDb.getAll(LocalDb.savedDate)).map(SavedDate.fromJson).toList();
  }

  /// Re-reads everything from disk — used on app resume, and after a backup
  /// import replaces the underlying db file.
  Future<void> reload() async {
    await _hydrateFromCache();
    if (Platform.isAndroid) {
      await updateProgressNotificationFrom(dimensions: dimensions, entries: entries);
    }
    notifyListeners();
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
      id: existingIndex >= 0 ? entries[existingIndex].id : LocalDb.newId(),
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
    if (Platform.isAndroid) {
      await updateProgressNotificationFrom(dimensions: dimensions, entries: entries);
    }
    notifyListeners();
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
          id: LocalDb.newId(),
          taskId: taskId,
          date: date,
          createdAt: DateTime.now().toIso8601String(),
          taskTitle: title,
        );
        taskCompletions = [...taskCompletions, completion];
        await localDb.put(LocalDb.taskCompletion, completion.id, completion.toJson());
      }
    } else {
      final removed = taskCompletions.where((c) => c.taskId == taskId && c.date == date).toList();
      taskCompletions = taskCompletions.where((c) => !(c.taskId == taskId && c.date == date)).toList();
      for (final c in removed) {
        await localDb.remove(LocalDb.taskCompletion, c.id);
      }
    }
    notifyListeners();
  }

  Future<void> createDimension(String name) async {
    final id = LocalDb.newId();
    final dim = Dimension(id: id, name: name, createdAt: DateTime.now().toIso8601String());
    dimensions = [...dimensions, dim]..sort((a, b) => a.name.compareTo(b.name));
    await localDb.put(LocalDb.dimension, id, dim.toJson());
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> createTask({
    required String title,
    required String description,
    required int? dimensionId,
  }) async {
    final id = LocalDb.newId();
    final dimName = dimensionId == null
        ? null
        : dimensions
            .firstWhere((d) => d.id == dimensionId, orElse: () => Dimension(id: dimensionId, name: '', createdAt: ''))
            .name;
    final task = Task(
      id: id,
      title: title,
      description: description,
      dimensionId: dimensionId,
      dimensionName: dimName,
      status: TaskStatus.active,
      createdAt: DateTime.now().toIso8601String(),
    );
    tasks = [task, ...tasks];
    await localDb.put(LocalDb.task, id, task.toJson());
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> deleteTask(int id) async {
    tasks = tasks.where((t) => t.id != id).toList();
    final removedCompletions = taskCompletions.where((c) => c.taskId == id).toList();
    taskCompletions = taskCompletions.where((c) => c.taskId != id).toList();
    for (final c in removedCompletions) {
      await localDb.remove(LocalDb.taskCompletion, c.id);
    }
    await localDb.remove(LocalDb.task, id);
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> createDate({
    required String title,
    required String note,
    required String date,
    required bool recurringYearly,
  }) async {
    final id = LocalDb.newId();
    final now = DateTime.now().toIso8601String();
    final recurring = recurringYearly ? 'yearly' : 'none';
    final savedDate = SavedDate(
      id: id,
      title: title,
      note: note,
      date: date,
      recurring: recurring,
      createdAt: now,
      updatedAt: now,
    );
    dates = [...dates, savedDate];
    await localDb.put(LocalDb.savedDate, id, savedDate.toJson());
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> deleteDate(int id) async {
    dates = dates.where((d) => d.id != id).toList();
    await localDb.remove(LocalDb.savedDate, id);
    notifyListeners();
  }
}
