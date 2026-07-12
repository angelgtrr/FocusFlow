import type { Entry, Goal } from './types';

export function toDateKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export function todayKey(): string {
  return toDateKey(new Date());
}

export function startOfWeek(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay(); // 0 = Sunday
  d.setDate(d.getDate() - day);
  d.setHours(0, 0, 0, 0);
  return d;
}

export function entriesInCurrentWeek(entries: Entry[]): Entry[] {
  const start = startOfWeek(new Date());
  const startKey = toDateKey(start);
  const endKey = todayKey();
  return entries.filter((e) => e.date >= startKey && e.date <= endKey);
}

export function weeklyProgressPct(entries: Entry[], activeGoals: Goal[]): number {
  const weekEntries = entriesInCurrentWeek(entries);
  if (activeGoals.length === 0) return 0;
  const daysSoFar = new Date().getDay() + 1; // Sun=0 -> 1 day so far
  const possible = activeGoals.length * daysSoFar * 4; // max score 4 per goal per day
  if (possible === 0) return 0;
  const achieved = weekEntries.reduce((sum, e) => sum + e.score, 0);
  return Math.round((achieved / possible) * 100);
}

export function currentStreak(entries: Entry[]): number {
  const daysWithProgress = new Set(
    entries.filter((e) => e.score >= 1).map((e) => e.date)
  );
  let streak = 0;
  const cursor = new Date();
  cursor.setHours(0, 0, 0, 0);

  if (!daysWithProgress.has(toDateKey(cursor))) {
    cursor.setDate(cursor.getDate() - 1);
  }

  while (daysWithProgress.has(toDateKey(cursor))) {
    streak += 1;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

export interface HeatmapDay {
  date: string;
  avgScore: number | null;
}

export function buildHeatmap(entries: Entry[], weeks = 12): HeatmapDay[] {
  const byDate = new Map<string, number[]>();
  for (const e of entries) {
    const list = byDate.get(e.date) ?? [];
    list.push(e.score);
    byDate.set(e.date, list);
  }

  const days: HeatmapDay[] = [];
  const end = new Date();
  end.setHours(0, 0, 0, 0);
  const start = startOfWeek(end);
  start.setDate(start.getDate() - (weeks - 1) * 7);

  const cursor = new Date(start);
  while (cursor <= end) {
    const key = toDateKey(cursor);
    const scores = byDate.get(key);
    days.push({
      date: key,
      avgScore: scores ? scores.reduce((a, b) => a + b, 0) / scores.length : null,
    });
    cursor.setDate(cursor.getDate() + 1);
  }
  return days;
}

export interface TrendPoint {
  date: string;
  avgScore: number;
}

export function buildTrend(entries: Entry[], days = 30): TrendPoint[] {
  const byDate = new Map<string, number[]>();
  for (const e of entries) {
    const list = byDate.get(e.date) ?? [];
    list.push(e.score);
    byDate.set(e.date, list);
  }

  const points: TrendPoint[] = [];
  const end = new Date();
  end.setHours(0, 0, 0, 0);
  const start = new Date(end);
  start.setDate(start.getDate() - (days - 1));

  const cursor = new Date(start);
  while (cursor <= end) {
    const key = toDateKey(cursor);
    const scores = byDate.get(key);
    points.push({
      date: key,
      avgScore: scores ? scores.reduce((a, b) => a + b, 0) / scores.length : 0,
    });
    cursor.setDate(cursor.getDate() + 1);
  }
  return points;
}

export function dimensionsFromGoals(goals: Goal[]): string[] {
  return Array.from(new Set(goals.map((g) => g.dimension))).sort();
}
