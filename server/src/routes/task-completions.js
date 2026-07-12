import { Router } from 'express';
import db from '../db.js';

const router = Router();

const COMPLETIONS_WITH_TASK = `
  SELECT task_completions.*, tasks.title AS task_title
  FROM task_completions
  JOIN tasks ON tasks.id = task_completions.task_id
`;

router.get('/', (req, res) => {
  const { date } = req.query;
  const rows = date
    ? db.prepare(`${COMPLETIONS_WITH_TASK} WHERE task_completions.date = ?`).all(date)
    : db.prepare(`${COMPLETIONS_WITH_TASK} ORDER BY task_completions.date DESC`).all();
  res.json(rows);
});

router.post('/', (req, res) => {
  const { task_id, date } = req.body;
  if (!task_id || !date) {
    return res.status(400).json({ error: 'task_id and date are required' });
  }

  const task = db.prepare('SELECT id FROM tasks WHERE id = ?').get(task_id);
  if (!task) return res.status(404).json({ error: 'task not found' });

  db.prepare('INSERT OR IGNORE INTO task_completions (task_id, date) VALUES (?, ?)').run(task_id, date);

  const row = db
    .prepare(`${COMPLETIONS_WITH_TASK} WHERE task_completions.task_id = ? AND task_completions.date = ?`)
    .get(task_id, date);

  res.status(201).json(row);
});

router.delete('/', (req, res) => {
  const { task_id, date } = req.query;
  if (!task_id || !date) {
    return res.status(400).json({ error: 'task_id and date query params are required' });
  }
  const result = db.prepare('DELETE FROM task_completions WHERE task_id = ? AND date = ?').run(task_id, date);
  if (result.changes === 0) return res.status(404).json({ error: 'completion not found' });
  res.status(204).end();
});

export default router;
