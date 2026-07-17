import { Router } from 'express';
import db from '../db.js';
import { notifyProgress } from '../push.js';

const router = Router();

router.get('/public-key', (req, res) => {
  res.json({ publicKey: process.env.VAPID_PUBLIC_KEY ?? null });
});

router.post('/subscribe', (req, res) => {
  const subscription = req.body;
  if (!subscription || !subscription.endpoint) {
    return res.status(400).json({ error: 'a valid push subscription is required' });
  }

  db.prepare(
    `INSERT INTO push_subscriptions (endpoint, subscription)
     VALUES (@endpoint, @subscription)
     ON CONFLICT(endpoint) DO UPDATE SET subscription = excluded.subscription`
  ).run({ endpoint: subscription.endpoint, subscription: JSON.stringify(subscription) });

  res.status(201).json({ ok: true });
  notifyProgress().catch((err) => console.error('Push send failed:', err.message));
});

router.post('/unsubscribe', (req, res) => {
  const { endpoint } = req.body ?? {};
  if (!endpoint) return res.status(400).json({ error: 'endpoint is required' });
  db.prepare('DELETE FROM push_subscriptions WHERE endpoint = ?').run(endpoint);
  res.status(204).end();
});

export default router;
