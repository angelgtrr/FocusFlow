import { Router } from 'express';
import db from '../db.js';

const router = Router();

router.get('/', (req, res) => {
  const dimensions = db.prepare('SELECT * FROM dimensions ORDER BY name ASC').all();
  res.json(dimensions);
});

router.post('/', (req, res) => {
  const { name } = req.body;
  if (!name || !name.trim()) {
    return res.status(400).json({ error: 'name is required' });
  }
  try {
    const result = db.prepare('INSERT INTO dimensions (name) VALUES (?)').run(name.trim());
    const dimension = db.prepare('SELECT * FROM dimensions WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(dimension);
  } catch (e) {
    if (e.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ error: 'dimension already exists' });
    }
    throw e;
  }
});

router.patch('/:id', (req, res) => {
  const dimension = db.prepare('SELECT * FROM dimensions WHERE id = ?').get(req.params.id);
  if (!dimension) return res.status(404).json({ error: 'dimension not found' });

  const { name } = req.body;
  if (!name || !name.trim()) {
    return res.status(400).json({ error: 'name is required' });
  }

  try {
    db.prepare('UPDATE dimensions SET name = ? WHERE id = ?').run(name.trim(), req.params.id);
    res.json(db.prepare('SELECT * FROM dimensions WHERE id = ?').get(req.params.id));
  } catch (e) {
    if (e.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ error: 'dimension already exists' });
    }
    throw e;
  }
});

router.delete('/:id', (req, res) => {
  db.prepare('UPDATE tasks SET dimension_id = NULL WHERE dimension_id = ?').run(req.params.id);
  db.prepare('DELETE FROM entries WHERE dimension_id = ?').run(req.params.id);
  const result = db.prepare('DELETE FROM dimensions WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'dimension not found' });
  res.status(204).end();
});

export default router;
