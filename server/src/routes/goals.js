import { Router } from 'express';
import db from '../db.js';

const router = Router();

router.get('/', (req, res) => {
  const goals = db.prepare('SELECT * FROM goals ORDER BY created_at DESC').all();
  res.json(goals);
});

router.post('/', (req, res) => {
  const { title, description = '', dimension } = req.body;
  if (!title || !title.trim() || !dimension || !dimension.trim()) {
    return res.status(400).json({ error: 'title and dimension are required' });
  }
  const result = db
    .prepare('INSERT INTO goals (title, description, dimension) VALUES (?, ?, ?)')
    .run(title.trim(), description.trim(), dimension.trim());
  const goal = db.prepare('SELECT * FROM goals WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(goal);
});

router.patch('/:id', (req, res) => {
  const goal = db.prepare('SELECT * FROM goals WHERE id = ?').get(req.params.id);
  if (!goal) return res.status(404).json({ error: 'goal not found' });

  const { title, description, dimension, status } = req.body;
  if (status && !['active', 'paused', 'done'].includes(status)) {
    return res.status(400).json({ error: 'invalid status' });
  }

  db.prepare(
    'UPDATE goals SET title = ?, description = ?, dimension = ?, status = ? WHERE id = ?'
  ).run(
    title?.trim() ?? goal.title,
    description?.trim() ?? goal.description,
    dimension?.trim() ?? goal.dimension,
    status ?? goal.status,
    req.params.id
  );

  res.json(db.prepare('SELECT * FROM goals WHERE id = ?').get(req.params.id));
});

router.delete('/:id', (req, res) => {
  const result = db.prepare('DELETE FROM goals WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'goal not found' });
  res.status(204).end();
});

export default router;
