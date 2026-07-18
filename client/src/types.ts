export type TaskStatus = 'active' | 'paused' | 'done';

export interface Dimension {
  id: number;
  name: string;
  created_at: string;
}

export interface Task {
  id: number;
  title: string;
  description: string;
  dimension_id: number | null;
  dimension_name: string | null;
  status: TaskStatus;
  created_at: string;
}

export interface Entry {
  id: number;
  dimension_id: number;
  date: string; // YYYY-MM-DD
  score: number; // 0-4
  note: string;
  created_at: string;
  updated_at: string;
  dimension_name: string;
}

export interface TaskCompletion {
  id: number;
  task_id: number;
  date: string; // YYYY-MM-DD
  created_at: string;
  task_title: string;
}

export interface DayNote {
  date: string; // YYYY-MM-DD
  note: string;
  created_at: string;
  updated_at: string;
}

export type RecurringType = 'none' | 'yearly';

export interface SavedDate {
  id: number;
  title: string;
  note: string;
  date: string; // YYYY-MM-DD
  recurring: RecurringType;
  created_at: string;
  updated_at: string;
}

export const SCORE_LABELS: Record<number, string> = {
  0: 'No progress',
  1: 'Low effort',
  2: 'Medium progress',
  3: 'Excellent progress',
  4: 'Exceeded expectations',
};
