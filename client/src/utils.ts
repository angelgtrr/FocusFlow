import type { DayNote, Dimension, Entry, RecurringType, Task, TaskCompletion } from './types';

export function toDateKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export function todayKey(): string {
  return toDateKey(new Date());
}

export function keyToDate(key: string): Date {
  const [y, m, d] = key.split('-').map(Number);
  return new Date(y, m - 1, d);
}

export function addDays(date: Date, n: number): Date {
  const d = new Date(date);
  d.setDate(d.getDate() + n);
  return d;
}

export function addMonths(date: Date, n: number): Date {
  const d = new Date(date);
  d.setMonth(d.getMonth() + n);
  return d;
}

export function startOfWeek(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay(); // 0 = Sunday
  d.setDate(d.getDate() - day);
  d.setHours(0, 0, 0, 0);
  return d;
}

export interface MonthGridDay {
  key: string;
  date: Date;
  inMonth: boolean;
}

export function buildMonthGrid(monthDate: Date): MonthGridDay[] {
  const firstOfMonth = new Date(monthDate.getFullYear(), monthDate.getMonth(), 1);
  const lastOfMonth = new Date(monthDate.getFullYear(), monthDate.getMonth() + 1, 0);
  const start = startOfWeek(firstOfMonth);
  const end = startOfWeek(lastOfMonth);
  end.setDate(end.getDate() + 6);

  const days: MonthGridDay[] = [];
  const cursor = new Date(start);
  while (cursor <= end) {
    days.push({
      key: toDateKey(cursor),
      date: new Date(cursor),
      inMonth: cursor.getMonth() === monthDate.getMonth(),
    });
    cursor.setDate(cursor.getDate() + 1);
  }
  return days;
}

export interface DateOccurrence {
  occurrenceKey: string;
  daysUntil: number;
}

export function nextOccurrence(dateKey: string, recurring: RecurringType): DateOccurrence {
  const today = keyToDate(todayKey());
  const original = keyToDate(dateKey);

  if (recurring === 'none') {
    const daysUntil = Math.round((original.getTime() - today.getTime()) / 86400000);
    return { occurrenceKey: dateKey, daysUntil };
  }

  let occurrence = new Date(today.getFullYear(), original.getMonth(), original.getDate());
  if (occurrence < today) {
    occurrence = new Date(today.getFullYear() + 1, original.getMonth(), original.getDate());
  }
  const daysUntil = Math.round((occurrence.getTime() - today.getTime()) / 86400000);
  return { occurrenceKey: toDateKey(occurrence), daysUntil };
}

export function activeDateKeys(
  entries: Entry[],
  taskCompletions: TaskCompletion[],
  dayNotes: DayNote[]
): Set<string> {
  const keys = new Set<string>();
  for (const e of entries) keys.add(e.date);
  for (const c of taskCompletions) keys.add(c.date);
  for (const n of dayNotes) {
    if (n.note.trim()) keys.add(n.date);
  }
  return keys;
}

export function formatDayHeading(dateKey: string): string {
  const date = keyToDate(dateKey);
  const includeYear = date.getFullYear() !== new Date().getFullYear();
  return date.toLocaleDateString(undefined, {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    ...(includeYear ? { year: 'numeric' } : {}),
  });
}

export function entriesInCurrentWeek(entries: Entry[]): Entry[] {
  const start = startOfWeek(new Date());
  const startKey = toDateKey(start);
  const endKey = todayKey();
  return entries.filter((e) => e.date >= startKey && e.date <= endKey);
}

export function weeklyProgressPct(entries: Entry[], dimensions: Dimension[]): number {
  const weekEntries = entriesInCurrentWeek(entries);
  if (dimensions.length === 0) return 0;
  const daysSoFar = new Date().getDay() + 1; // Sun=0 -> 1 day so far
  const possible = dimensions.length * daysSoFar * 4; // max score 4 per dimension per day
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

export function tasksByDimensionId(tasks: Task[]): Map<number | null, Task[]> {
  const grouped = new Map<number | null, Task[]>();
  for (const task of tasks) {
    const key = task.dimension_id;
    const list = grouped.get(key) ?? [];
    list.push(task);
    grouped.set(key, list);
  }
  return grouped;
}

export interface DimensionProgress {
  dimension: Dimension;
  entry: Entry | null;
  loggedToday: boolean;
}

export function buildDimensionProgress(
  dimensions: Dimension[],
  todaysEntries: Entry[]
): DimensionProgress[] {
  const byDim = new Map(todaysEntries.map((e) => [e.dimension_id, e]));

  return dimensions.map((dimension) => {
    const entry = byDim.get(dimension.id) ?? null;
    return { dimension, entry, loggedToday: entry !== null };
  });
}

export function completedTaskIdsForDate(completions: TaskCompletion[], date: string): Set<number> {
  return new Set(completions.filter((c) => c.date === date).map((c) => c.task_id));
}
