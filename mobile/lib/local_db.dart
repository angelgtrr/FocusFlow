import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Local offline cache.
///
/// Two tables:
/// - `cache`: last known state of every server entity, stored as a JSON blob
///   keyed by (entity_type, id). Entities are looked up as plain maps using
///   the same field names the server API uses (snake_case), so a row here
///   round-trips straight through the model `fromJson`/`toJson` factories.
/// - `pending_ops`: mutations made while offline (or that raced a flaky
///   connection), replayed in creation order once the server is reachable.
///
/// Locally-created dimensions/tasks get a negative, timestamp-derived id
/// until they sync and the server assigns a real one. [remapId] rewrites
/// every place that temp id shows up — other cached rows and still-queued
/// ops — once the real id is known.
class LocalDb {
  static const dimension = 'dimension';
  static const task = 'task';
  static const entry = 'entry';
  static const taskCompletion = 'task_completion';
  static const dayNote = 'day_note';
  static const savedDate = 'saved_date';
  static const settings = 'settings';

  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final path = await getDatabasesPath();
    final db = await openDatabase(
      '$path/focusflow_cache.db',
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
        await db.execute('''
          CREATE TABLE pending_ops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            op_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL
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

  // --- Cache reads ---

  Future<List<Map<String, dynamic>>> getAll(String entityType) async {
    final db = await _database;
    final rows = await db.query('cache', columns: ['json'], where: 'entity_type = ?', whereArgs: [entityType]);
    return rows.map((r) => jsonDecode(r['json'] as String) as Map<String, dynamic>).toList();
  }

  // --- Cache writes ---

  /// Replaces the entire cached set for [entityType] — used after a
  /// successful network refresh, where the server response is authoritative.
  Future<void> replaceAll(String entityType, List<Map<String, dynamic>> rows, {required String idField}) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('cache', where: 'entity_type = ?', whereArgs: [entityType]);
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert('cache', {
          'entity_type': entityType,
          'id': row[idField].toString(),
          'json': jsonEncode(row),
        });
      }
      await batch.commit(noResult: true);
    });
  }

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

  /// Renames a locally-created entity's id to the id the server assigned,
  /// and rewrites every reference to the old id in other cached rows and
  /// still-queued ops.
  Future<void> remapId(String entityType, int oldId, int newId) async {
    final db = await _database;
    await db.transaction((txn) async {
      final rows = await txn.query('cache', where: 'entity_type = ? AND id = ?', whereArgs: [entityType, oldId.toString()]);
      if (rows.isNotEmpty) {
        final json = jsonDecode(rows.first['json'] as String) as Map<String, dynamic>;
        json['id'] = newId;
        await txn.delete('cache', where: 'entity_type = ? AND id = ?', whereArgs: [entityType, oldId.toString()]);
        await txn.insert('cache', {
          'entity_type': entityType,
          'id': newId.toString(),
          'json': jsonEncode(json),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final refField = entityType == dimension ? 'dimension_id' : entityType == task ? 'task_id' : null;
      if (refField != null) {
        final allRows = await txn.query('cache');
        for (final row in allRows) {
          final json = jsonDecode(row['json'] as String) as Map<String, dynamic>;
          if (json[refField] == oldId) {
            json[refField] = newId;
            await txn.update(
              'cache',
              {'json': jsonEncode(json)},
              where: 'entity_type = ? AND id = ?',
              whereArgs: [row['entity_type'], row['id']],
            );
          }
        }
      }

      final ops = await txn.query('pending_ops');
      for (final op in ops) {
        final payload = jsonDecode(op['payload'] as String) as Map<String, dynamic>;
        var changed = false;
        for (final key in ['target_id', 'dimension_id', 'task_id']) {
          if (payload[key] == oldId) {
            payload[key] = newId;
            changed = true;
          }
        }
        if (changed) {
          await txn.update('pending_ops', {'payload': jsonEncode(payload)}, where: 'id = ?', whereArgs: [op['id']]);
        }
      }
    });
  }

  // --- Pending ops queue ---

  Future<int> enqueueOp(String opType, Map<String, dynamic> payload) async {
    final db = await _database;
    return db.insert('pending_ops', {
      'op_type': opType,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<PendingOp>> getQueue() async {
    final db = await _database;
    final rows = await db.query('pending_ops', orderBy: 'id ASC');
    return rows
        .map((r) => PendingOp(
              id: r['id'] as int,
              opType: r['op_type'] as String,
              payload: jsonDecode(r['payload'] as String) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<int> queueLength() async {
    final db = await _database;
    final result = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pending_ops'));
    return result ?? 0;
  }

  Future<void> removeOp(int id) async {
    final db = await _database;
    await db.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  /// A negative, effectively-unique id for entities created while offline.
  static int tempId() => -DateTime.now().microsecondsSinceEpoch;
}

class PendingOp {
  final int id;
  final String opType;
  final Map<String, dynamic> payload;

  PendingOp({required this.id, required this.opType, required this.payload});
}
