import Database from 'better-sqlite3';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dbPath = process.env.DB_PATH
  ? path.resolve(process.env.DB_PATH)
  : path.join(__dirname, '..', 'focusflow.db');

fs.mkdirSync(path.dirname(dbPath), { recursive: true });

const db = new Database(dbPath);

db.pragma('journal_mode = WAL');

const tableExists = (name) =>
  db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name = ?").get(name);

if (tableExists('goals') && !tableExists('tasks')) {
  db.exec('ALTER TABLE goals RENAME TO tasks');
}
if (tableExists('entries')) {
  const hasGoalId = db
    .prepare("PRAGMA table_info(entries)")
    .all()
    .some((c) => c.name === 'goal_id');
  if (hasGoalId) {
    db.exec('ALTER TABLE entries RENAME COLUMN goal_id TO task_id');
  }
}

db.exec(`
  CREATE TABLE IF NOT EXISTS dimensions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
`);

if (tableExists('tasks')) {
  const hasDimensionId = db
    .prepare("PRAGMA table_info(tasks)")
    .all()
    .some((c) => c.name === 'dimension_id');
  if (!hasDimensionId) {
    db.exec('ALTER TABLE tasks ADD COLUMN dimension_id INTEGER REFERENCES dimensions(id)');

    const hasLegacyDimension = db
      .prepare("PRAGMA table_info(tasks)")
      .all()
      .some((c) => c.name === 'dimension');
    if (hasLegacyDimension) {
      const distinctDims = db
        .prepare(
          "SELECT DISTINCT dimension FROM tasks WHERE dimension IS NOT NULL AND trim(dimension) != ''"
        )
        .all();
      const insertDim = db.prepare('INSERT OR IGNORE INTO dimensions (name) VALUES (?)');
      const getDimId = db.prepare('SELECT id FROM dimensions WHERE name = ?');
      const setDimId = db.prepare('UPDATE tasks SET dimension_id = ? WHERE dimension = ?');
      const backfill = db.transaction(() => {
        for (const { dimension } of distinctDims) {
          insertDim.run(dimension);
          setDimId.run(getDimId.get(dimension).id, dimension);
        }
      });
      backfill();
      db.exec('ALTER TABLE tasks DROP COLUMN dimension');
    }
  }
}

if (tableExists('entries')) {
  const hasTaskId = db
    .prepare("PRAGMA table_info(entries)")
    .all()
    .some((c) => c.name === 'task_id');
  if (hasTaskId) {
    db.exec('ALTER TABLE entries RENAME TO entries_old');
    db.exec(`
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dimension_id INTEGER NOT NULL REFERENCES dimensions(id),
        date TEXT NOT NULL,
        score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 4),
        note TEXT DEFAULT '',
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        UNIQUE(dimension_id, date)
      )
    `);
    db.exec(`
      INSERT OR IGNORE INTO entries (id, dimension_id, date, score, note, created_at, updated_at)
      SELECT entries_old.id,
             (SELECT dimension_id FROM tasks WHERE tasks.id = entries_old.task_id),
             entries_old.date, entries_old.score, entries_old.note,
             entries_old.created_at, entries_old.updated_at
      FROM entries_old
      WHERE (SELECT dimension_id FROM tasks WHERE tasks.id = entries_old.task_id) IS NOT NULL
    `);
    db.exec('DROP TABLE entries_old');
  }
}

db.exec(`
  CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    dimension_id INTEGER REFERENCES dimensions(id),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'done')),
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dimension_id INTEGER NOT NULL REFERENCES dimensions(id),
    date TEXT NOT NULL,
    score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 4),
    note TEXT DEFAULT '',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(dimension_id, date)
  );

  CREATE TABLE IF NOT EXISTS task_completions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    date TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(task_id, date)
  );

  CREATE TABLE IF NOT EXISTS day_notes (
    date TEXT PRIMARY KEY,
    note TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS push_subscriptions (
    endpoint TEXT PRIMARY KEY,
    subscription TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
`);

export default db;
