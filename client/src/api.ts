import type { Entry, Goal, GoalStatus } from './types';

export class UnauthorizedError extends Error {}

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`/api${path}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    if (res.status === 401) throw new UnauthorizedError(body.error ?? 'Not authenticated');
    throw new Error(body.error ?? `Request failed: ${res.status}`);
  }
  if (res.status === 204) return undefined as T;
  return res.json();
}

export const api = {
  getGoals: () => request<Goal[]>('/goals'),

  createGoal: (data: { title: string; description: string; dimension: string }) =>
    request<Goal>('/goals', { method: 'POST', body: JSON.stringify(data) }),

  updateGoal: (
    id: number,
    data: Partial<{ title: string; description: string; dimension: string; status: GoalStatus }>
  ) => request<Goal>(`/goals/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),

  deleteGoal: (id: number) => request<void>(`/goals/${id}`, { method: 'DELETE' }),

  getEntries: (since?: string) =>
    request<Entry[]>(`/entries${since ? `?since=${since}` : ''}`),

  logEntry: (data: { goal_id: number; date: string; score: number; note: string }) =>
    request<Entry>('/entries', { method: 'POST', body: JSON.stringify(data) }),

  deleteEntry: (id: number) => request<void>(`/entries/${id}`, { method: 'DELETE' }),

  login: (password: string) =>
    request<{ ok: boolean }>('/login', { method: 'POST', body: JSON.stringify({ password }) }),

  logout: () => request<{ ok: boolean }>('/logout', { method: 'POST' }),

  getSession: () => request<{ authenticated: boolean }>('/session'),
};
