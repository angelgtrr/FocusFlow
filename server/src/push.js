import webpush from 'web-push';
import db from './db.js';

const TAG = 'focusflow-daily-progress';

const vapidConfigured = Boolean(
  process.env.VAPID_PUBLIC_KEY && process.env.VAPID_PRIVATE_KEY && process.env.VAPID_SUBJECT
);

if (vapidConfigured) {
  webpush.setVapidDetails(
    process.env.VAPID_SUBJECT,
    process.env.VAPID_PUBLIC_KEY,
    process.env.VAPID_PRIVATE_KEY
  );
} else {
  console.warn('VAPID keys not configured — push notifications are disabled.');
}

function todayKey() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function computeTodaysProgress() {
  const today = todayKey();

  const { total: totalDimensions } = db
    .prepare('SELECT COUNT(*) AS total FROM dimensions')
    .get();
  const { logged: dimensionsLogged } = db
    .prepare('SELECT COUNT(DISTINCT dimension_id) AS logged FROM entries WHERE date = ?')
    .get(today);

  const { total: totalTasks } = db
    .prepare("SELECT COUNT(*) AS total FROM tasks WHERE status = 'active'")
    .get();
  const { done: tasksDone } = db
    .prepare(
      `SELECT COUNT(*) AS done
       FROM task_completions
       JOIN tasks ON tasks.id = task_completions.task_id
       WHERE task_completions.date = ? AND tasks.status = 'active'`
    )
    .get(today);

  return { dimensionsLogged, totalDimensions, tasksDone, totalTasks };
}

export async function notifyProgress() {
  if (!vapidConfigured) return;

  const subscriptions = db.prepare('SELECT endpoint, subscription FROM push_subscriptions').all();
  if (subscriptions.length === 0) return;

  const { dimensionsLogged, totalDimensions, tasksDone, totalTasks } = computeTodaysProgress();
  const payload = JSON.stringify({
    title: 'FocusFlow',
    body: `${dimensionsLogged}/${totalDimensions} dimensions · ${tasksDone}/${totalTasks} tasks done today`,
    tag: TAG,
  });

  const deleteSub = db.prepare('DELETE FROM push_subscriptions WHERE endpoint = ?');

  await Promise.all(
    subscriptions.map(async (row) => {
      try {
        await webpush.sendNotification(JSON.parse(row.subscription), payload);
      } catch (err) {
        if (err.statusCode === 404 || err.statusCode === 410) {
          deleteSub.run(row.endpoint);
        } else {
          console.error('Push send failed:', err.message);
        }
      }
    })
  );
}

export function startProgressRefresh(intervalMs = 15 * 60 * 1000) {
  if (!vapidConfigured) return;
  setInterval(() => {
    notifyProgress().catch((err) => console.error('Push refresh failed:', err.message));
  }, intervalMs);
}
