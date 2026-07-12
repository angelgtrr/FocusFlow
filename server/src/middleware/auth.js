import crypto from 'node:crypto';

const COOKIE_NAME = 'focusflow_session';
const MAX_AGE_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

function checkPassword(candidate) {
  const expected = process.env.FOCUSFLOW_PASSWORD ?? '';
  const a = Buffer.from(candidate ?? '');
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

export function login(req, res) {
  if (!process.env.FOCUSFLOW_PASSWORD) {
    return res.status(500).json({ error: 'Server has no password configured' });
  }
  const { password } = req.body ?? {};
  if (!checkPassword(password)) {
    return res.status(401).json({ error: 'Incorrect password' });
  }
  res.cookie(COOKIE_NAME, 'authenticated', {
    httpOnly: true,
    sameSite: 'lax',
    maxAge: MAX_AGE_MS,
    signed: true,
  });
  res.json({ ok: true });
}

export function logout(req, res) {
  res.clearCookie(COOKIE_NAME);
  res.json({ ok: true });
}

export function session(req, res) {
  res.json({ authenticated: req.signedCookies?.[COOKIE_NAME] === 'authenticated' });
}

export function requireAuth(req, res, next) {
  if (req.signedCookies?.[COOKIE_NAME] === 'authenticated') return next();
  res.status(401).json({ error: 'Not authenticated' });
}
