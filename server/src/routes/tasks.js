import { Router } from 'express';
import db from '../db.js';

const router = Router();

const TASKS_WITH_DIMENSION = `
  SELECT tasks.*, dimensions.name AS dimension_name
  FROM tasks
  LEFT JOIN dimensions ON dimensions.id = tasks.dimension_id
`;

router.get('/', (req, res) => {
  const tasks = db.prepare(`${TASKS_WITH_DIMENSION} ORDER BY tasks.created_at DESC`).all();
  res.json(tasks);
});

router.post('/', (req, res) => {
  const { title, description = '', dimension_id = null } = req.body;
  if (!title || !title.trim()) {
    return res.status(400).json({ error: 'title is required' });
  }
  if (dimension_id != null && !db.prepare('SELECT id FROM dimensions WHERE id = ?').get(dimension_id)) {
    return res.status(400).json({ error: 'dimension not found' });
  }
  const result = db
    .prepare('INSERT INTO tasks (title, description, dimension_id) VALUES (?, ?, ?)')
    .run(title.trim(), description.trim(), dimension_id);
  const task = db
    .prepare(`${TASKS_WITH_DIMENSION} WHERE tasks.id = ?`)
    .get(result.lastInsertRowid);
  res.status(201).json(task);
});

router.patch('/:id', (req, res) => {
  const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(req.params.id);
  if (!task) return res.status(404).json({ error: 'task not found' });

  const { title, description, dimension_id, status } = req.body;
  if (status && !['active', 'paused', 'done'].includes(status)) {
    return res.status(400).json({ error: 'invalid status' });
  }
  if (dimension_id != null && !db.prepare('SELECT id FROM dimensions WHERE id = ?').get(dimension_id)) {
    return res.status(400).json({ error: 'dimension not found' });
  }

  db.prepare(
    'UPDATE tasks SET title = ?, description = ?, dimension_id = ?, status = ? WHERE id = ?'
  ).run(
    title?.trim() ?? task.title,
    description?.trim() ?? task.description,
    dimension_id !== undefined ? dimension_id : task.dimension_id,
    status ?? task.status,
    req.params.id
  );

  res.json(db.prepare(`${TASKS_WITH_DIMENSION} WHERE tasks.id = ?`).get(req.params.id));
});

router.delete('/:id', (req, res) => {
  db.prepare('DELETE FROM task_completions WHERE task_id = ?').run(req.params.id);
  const result = db.prepare('DELETE FROM tasks WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'task not found' });
  res.status(204).end();
});

export default router;
