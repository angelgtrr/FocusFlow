# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

FocusFlow is a personal, single-user diary/focus tracker. You define goals grouped under a "dimension" (Exercise, Work, Learning, etc.), then log a daily entry against a goal with a score (0 = no progress, 1 = low effort, 2 = medium, 3 = excellent, 4 = exceeded expectations) plus a free-text note. The app surfaces streaks, a GitHub-style heatmap, and a 30-day trend chart built from that entry history.

Single shared password auth — it's built for one person, but tunneled to the internet via ngrok, so it's gated behind a login screen (see Architecture below).

## Commands

Run everything from the repo root:

```
npm install          # once, installs the root `concurrently` dependency
npm run dev           # starts both the API (4877) and the frontend (5173)
```

The root `dev` script just runs `client`'s and `server`'s own `dev` scripts concurrently. To work on one side in isolation, `cd` into it and run its script directly:

```
cd server && npm run dev      # node --watch src/index.js
cd client && npm run dev      # vite
```

Other client-side commands (run from `client/`):
```
npm run build     # tsc -b && vite build
npm run lint      # oxlint
npm run preview   # preview a production build
```

There is no test suite in either package yet.

## Architecture

Two independent processes, not a monorepo tool (no workspaces/turborepo) — just a root `package.json` whose only job is to launch both via `concurrently`.

**`server/`** — Express + `better-sqlite3`, plain JS (ESM, no build step, run directly with `node --watch`).
- `src/db.js` opens `server/focusflow.db` (created on first run, WAL mode) and creates the schema if missing. There are exactly two tables:
  - `goals` (id, title, description, dimension, status ∈ `active|paused|done`, created_at)
  - `entries` (id, goal_id → goals, date `YYYY-MM-DD`, score 0-4, note, created_at, updated_at) with a `UNIQUE(goal_id, date)` constraint — logging again for the same goal/day is an upsert, not a new row.
  - `dimension` is a free-text field on `goals`, not its own table. There's no dimension registry; the set of dimensions in the UI is derived by scanning goals client-side (`dimensionsFromGoals` in `client/src/utils.ts`).
- `src/routes/goals.js`, `src/routes/entries.js` — thin CRUD. `POST /api/entries` does the upsert via `ON CONFLICT(goal_id, date) DO UPDATE`. `GET /api/entries` joins in `goal_title`/`goal_dimension` so the client never has to cross-reference goals itself.
- No pagination, CORS wide open — intentional given the single-user scope.
- `src/middleware/auth.js` — a single shared password (`FOCUSFLOW_PASSWORD` in `server/.env`, gitignored; copy `.env.example` and set it) checked with `crypto.timingSafeEqual`, gating a signed httpOnly cookie (`focusflow_session`, 30-day maxAge, signed with `SESSION_SECRET` from `.env`) instead of a server-side session store — stateless, so it survives `node --watch` restarts without forcing re-login. `POST /api/login`, `POST /api/logout`, `GET /api/session` are unprotected; `requireAuth` gates everything under `/api/goals` and `/api/entries`.

**`client/`** — Vite + React 19 + TypeScript, Tailwind v4 (via `@tailwindcss/vite`, no `tailwind.config.js` — theme tokens live in `src/index.css`).
- `vite.config.ts` proxies `/api/*` to `http://localhost:4877` in dev, so `src/api.ts` just calls relative `/api/...` paths.
- `App.tsx` checks `GET /api/session` on mount before anything else; if unauthenticated it renders `LoginPage` instead of the app, and any subsequent API call that comes back `401` (thrown as `UnauthorizedError` from `src/api.ts`) drops the app back to the login screen. Otherwise it fetches `goals` and `entries` once on mount, holds them in state, and passes a `refresh()`-triggering callback down to both tabs. Neither `DailyPage` nor `AdminGoalsPage` fetch on their own — all writes go through `App.tsx`'s `handleLogEntry` / `handleCreateGoal` / `handleStatusChange`, which call the API then re-fetch everything. There's no optimistic update and no client-side cache layer.
- **Derived stats are computed client-side from raw entries on every render**, not stored or fetched pre-aggregated — see `src/utils.ts`: `currentStreak`, `weeklyProgressPct`, `buildHeatmap`, `buildTrend`. If you need a new stat, it almost certainly belongs there rather than as a new API endpoint, since the server has no notion of "this week" or "streak."
- Two tabs, toggled by local state in `App.tsx` (`tab: 'daily' | 'admin'`), not routed — there's no react-router, no URL-based navigation.
- `src/pages/DailyPage.tsx`: stats bar, today's entries, dimension-filterable heatmap + trend chart, and the "+" button that opens `LogEntryModal`.
- `src/pages/AdminGoalsPage.tsx`: goal creation form + goal list with an inline status `<select>` (active/paused/done) — there's no delete-goal UI, only status changes.
- `LogEntryModal` has a two-step cascading select: pick a dimension, which filters the goal `<select>` to goals in that dimension, then pick a score and note. It only ever offers goals with `status === 'active'`.
- Color coding: `src/constants.ts` has fixed score→color maps (`SCORE_COLORS`, `SCORE_RING_COLORS`) and a deterministic hash-based palette assigner for dimension badges (`dimensionColor`) — new dimensions get a color automatically, nothing to register.
