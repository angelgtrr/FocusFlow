export type GoalStatus = 'active' | 'paused' | 'done';

export interface Goal {
  id: number;
  title: string;
  description: string;
  dimension: string;
  status: GoalStatus;
  created_at: string;
}

export interface Entry {
  id: number;
  goal_id: number;
  date: string; // YYYY-MM-DD
  score: number; // 0-4
  note: string;
  created_at: string;
  updated_at: string;
  goal_title: string;
  goal_dimension: string;
}

export const SCORE_LABELS: Record<number, string> = {
  0: 'No progress',
  1: 'Low effort',
  2: 'Medium progress',
  3: 'Excellent progress',
  4: 'Exceeded expectations',
};
