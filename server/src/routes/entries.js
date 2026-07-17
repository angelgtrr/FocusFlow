import { Router } from 'express';
import db from '../db.js';
import { notifyProgress } from '../push.js';

const router = Router();

const ENTRIES_WITH_DIMENSION = `
  SELECT entries.*, dimensions.name AS dimension_name
  FROM entries
  JOIN dimensions ON dimensions.id = entries.dimension_id
`;

router.get('/', (req, res) => {
  const { since } = req.query;
  const entries = since
    ? db
        .prepare(`${ENTRIES_WITH_DIMENSION} WHERE entries.date >= ? ORDER BY entries.date DESC`)
        .all(since)
    : db.prepare(`${ENTRIES_WITH_DIMENSION} ORDER BY entries.date DESC`).all();
  res.json(entries);
});

router.post('/', (req, res) => {
  const { dimension_id, date, score, note = '' } = req.body;
  if (!dimension_id || !date || score === undefined || score === null) {
    return res.status(400).json({ error: 'dimension_id, date and score are required' });
  }
  if (score < 0 || score > 4) {
    return res.status(400).json({ error: 'score must be between 0 and 4' });
  }

  const dimension = db.prepare('SELECT id FROM dimensions WHERE id = ?').get(dimension_id);
  if (!dimension) return res.status(404).json({ error: 'dimension not found' });

  db.prepare(
    `INSERT INTO entries (dimension_id, date, score, note)
     VALUES (@dimension_id, @date, @score, @note)
     ON CONFLICT(dimension_id, date) DO UPDATE SET
       score = excluded.score,
       note = excluded.note,
       updated_at = datetime('now')`
  ).run({ dimension_id, date, score, note: note.trim() });

  const entry = db
    .prepare(`${ENTRIES_WITH_DIMENSION} WHERE entries.dimension_id = ? AND entries.date = ?`)
    .get(dimension_id, date);

  res.status(201).json(entry);
  notifyProgress().catch((err) => console.error('Push send failed:', err.message));
});

router.delete('/:id', (req, res) => {
  const result = db.prepare('DELETE FROM entries WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'entry not found' });
  res.status(204).end();
  notifyProgress().catch((err) => console.error('Push send failed:', err.message));
});

export default router;
