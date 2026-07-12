import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import goalsRouter from './routes/goals.js';
import entriesRouter from './routes/entries.js';
import { login, logout, session, requireAuth } from './middleware/auth.js';

const app = express();
const PORT = process.env.PORT || 4877;

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(cookieParser(process.env.SESSION_SECRET));

app.post('/api/login', login);
app.post('/api/logout', logout);
app.get('/api/session', session);
app.get('/api/health', (req, res) => res.json({ ok: true }));

app.use('/api/goals', requireAuth, goalsRouter);
app.use('/api/entries', requireAuth, entriesRouter);

app.listen(PORT, () => {
  console.log(`FocusFlow API listening on http://localhost:${PORT}`);
});
