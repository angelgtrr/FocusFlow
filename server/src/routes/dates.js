import { Router } from 'express';
import db from '../db.js';

const router = Router();

router.get('/', (req, res) => {
  const rows = db.prepare('SELECT * FROM dates ORDER BY date ASC').all();
  res.json(rows);
});

router.post('/', (req, res) => {
  const { title, note = '', date, recurring = 'none' } = req.body;
  if (!title || !title.trim() || !date) {
    return res.status(400).json({ error: 'title and date are required' });
  }
  if (!['none', 'yearly'].includes(recurring)) {
    return res.status(400).json({ error: 'invalid recurring value' });
  }

  const result = db
    .prepare('INSERT INTO dates (title, note, date, recurring) VALUES (?, ?, ?, ?)')
    .run(title.trim(), note.trim(), date, recurring);

  const row = db.prepare('SELECT * FROM dates WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(row);
});

router.patch('/:id', (req, res) => {
  const existing = db.prepare('SELECT * FROM dates WHERE id = ?').get(req.params.id);
  if (!existing) return res.status(404).json({ error: 'date not found' });

  const { title, note, date, recurring } = req.body;
  if (title !== undefined && !title.trim()) {
    return res.status(400).json({ error: 'title is required' });
  }
  if (recurring !== undefined && !['none', 'yearly'].includes(recurring)) {
    return res.status(400).json({ error: 'invalid recurring value' });
  }

  db.prepare(
    `UPDATE dates SET title = ?, note = ?, date = ?, recurring = ?, updated_at = datetime('now') WHERE id = ?`
  ).run(
    title !== undefined ? title.trim() : existing.title,
    note !== undefined ? note.trim() : existing.note,
    date ?? existing.date,
    recurring ?? existing.recurring,
    req.params.id
  );

  res.json(db.prepare('SELECT * FROM dates WHERE id = ?').get(req.params.id));
});

router.delete('/:id', (req, res) => {
  const result = db.prepare('DELETE FROM dates WHERE id = ?').run(req.params.id);
  if (result.changes === 0) {
    return res.status(404).json({ error: 'date not found' });
  }
  res.status(204).end();
});

export default router;
