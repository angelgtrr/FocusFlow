import { Router } from 'express';
import db from '../db.js';

const router = Router();

router.get('/', (req, res) => {
  const rows = db.prepare('SELECT * FROM day_notes ORDER BY date DESC').all();
  res.json(rows);
});

router.post('/', (req, res) => {
  const { date, note = '' } = req.body;
  if (!date) {
    return res.status(400).json({ error: 'date is required' });
  }

  db.prepare(
    `INSERT INTO day_notes (date, note)
     VALUES (@date, @note)
     ON CONFLICT(date) DO UPDATE SET
       note = excluded.note,
       updated_at = datetime('now')`
  ).run({ date, note: note.trim() });

  const row = db.prepare('SELECT * FROM day_notes WHERE date = ?').get(date);
  res.status(201).json(row);
});

export default router;
