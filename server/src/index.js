import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import tasksRouter from './routes/tasks.js';
import entriesRouter from './routes/entries.js';
import dimensionsRouter from './routes/dimensions.js';
import taskCompletionsRouter from './routes/task-completions.js';
import dayNotesRouter from './routes/day-notes.js';
import datesRouter from './routes/dates.js';
import pushRouter from './routes/push.js';
import { login, logout, session, requireAuth } from './middleware/auth.js';
import { startProgressRefresh } from './push.js';

const app = express();
const PORT = process.env.PORT || 4877;

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(cookieParser(process.env.SESSION_SECRET));

app.post('/api/login', login);
app.post('/api/logout', logout);
app.get('/api/session', session);
app.get('/api/health', (req, res) => res.json({ ok: true }));

app.use('/api/tasks', requireAuth, tasksRouter);
app.use('/api/entries', requireAuth, entriesRouter);
app.use('/api/dimensions', requireAuth, dimensionsRouter);
app.use('/api/task-completions', requireAuth, taskCompletionsRouter);
app.use('/api/day-notes', requireAuth, dayNotesRouter);
app.use('/api/dates', requireAuth, datesRouter);
app.use('/api/push', requireAuth, pushRouter);

app.listen(PORT, () => {
  console.log(`FocusFlow API listening on http://localhost:${PORT}`);
});

startProgressRefresh();
