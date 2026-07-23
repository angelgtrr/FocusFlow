import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// The local, on-device store — the sole source of truth for this app.
///
/// One table, `cache`: current state of every entity, stored as a JSON blob
/// keyed by (entity_type, id). Entities are looked up as plain maps using
/// the same field names the model `fromJson`/`toJson` factories expect, so a
/// row here round-trips straight through them.
///
/// There is no server, so ids are assigned once at creation time by [newId]
/// and never change.
class LocalDb {
  static const dimension = 'dimension';
  static const task = 'task';
  static const entry = 'entry';
  static const taskCompletion = 'task_completion';
  static const dayNote = 'day_note';
  static const savedDate = 'saved_date';

  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final path = await getDatabasesPath();
    final db = await openDatabase(
      '$path/focusflow_local.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache (
            entity_type TEXT NOT NULL,
            id TEXT NOT NULL,
            json TEXT NOT NULL,
            PRIMARY KEY (entity_type, id)
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  Future<void> init() async {
    await _database;
  }

  /// Absolute path to the live db file, for backup export/import.
  Future<String> databaseFilePath() async {
    final path = await getDatabasesPath();
    return '$path/focusflow_local.db';
  }

  /// Closes the current connection so the underlying file can be safely
  /// replaced (used when importing a backup).
  Future<void> close() async {
    final existing = _db;
    if (existing != null) {
      await existing.close();
      _db = null;
    }
  }

  // --- Reads ---

  Future<List<Map<String, dynamic>>> getAll(String entityType) async {
    final db = await _database;
    final rows = await db.query('cache', columns: ['json'], where: 'entity_type = ?', whereArgs: [entityType]);
    return rows.map((r) => jsonDecode(r['json'] as String) as Map<String, dynamic>).toList();
  }

  // --- Writes ---

  Future<void> put(String entityType, dynamic id, Map<String, dynamic> json) async {
    final db = await _database;
    await db.insert('cache', {
      'entity_type': entityType,
      'id': id.toString(),
      'json': jsonEncode(json),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remove(String entityType, dynamic id) async {
    final db = await _database;
    await db.delete('cache', where: 'entity_type = ? AND id = ?', whereArgs: [entityType, id.toString()]);
  }

  /// A negative, effectively-unique local id for newly-created entities.
  static int newId() => -DateTime.now().microsecondsSinceEpoch;
}
