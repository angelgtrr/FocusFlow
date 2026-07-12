import { Router } from 'express';
import db from '../db.js';

const router = Router();

router.get('/', (req, res) => {
  const { since } = req.query;
  const entries = since
    ? db
        .prepare(
          `SELECT entries.*, goals.title AS goal_title, goals.dimension AS goal_dimension
           FROM entries JOIN goals ON goals.id = entries.goal_id
           WHERE entries.date >= ? ORDER BY entries.date DESC`
        )
        .all(since)
    : db
        .prepare(
          `SELECT entries.*, goals.title AS goal_title, goals.dimension AS goal_dimension
           FROM entries JOIN goals ON goals.id = entries.goal_id
           ORDER BY entries.date DESC`
        )
        .all();
  res.json(entries);
});

router.post('/', (req, res) => {
  const { goal_id, date, score, note = '' } = req.body;
  if (!goal_id || !date || score === undefined || score === null) {
    return res.status(400).json({ error: 'goal_id, date and score are required' });
  }
  if (score < 0 || score > 4) {
    return res.status(400).json({ error: 'score must be between 0 and 4' });
  }

  const goal = db.prepare('SELECT id FROM goals WHERE id = ?').get(goal_id);
  if (!goal) return res.status(404).json({ error: 'goal not found' });

  db.prepare(
    `INSERT INTO entries (goal_id, date, score, note)
     VALUES (@goal_id, @date, @score, @note)
     ON CONFLICT(goal_id, date) DO UPDATE SET
       score = excluded.score,
       note = excluded.note,
       updated_at = datetime('now')`
  ).run({ goal_id, date, score, note: note.trim() });

  const entry = db
    .prepare(
      `SELECT entries.*, goals.title AS goal_title, goals.dimension AS goal_dimension
       FROM entries JOIN goals ON goals.id = entries.goal_id
       WHERE entries.goal_id = ? AND entries.date = ?`
    )
    .get(goal_id, date);

  res.status(201).json(entry);
});

router.delete('/:id', (req, res) => {
  const result = db.prepare('DELETE FROM entries WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'entry not found' });
  res.status(204).end();
});

export default router;
