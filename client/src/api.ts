import type { DayNote, Dimension, Entry, RecurringType, SavedDate, Task, TaskCompletion, TaskStatus } from './types';

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
  getTasks: () => request<Task[]>('/tasks'),

  createTask: (data: { title: string; description: string; dimension_id: number | null }) =>
    request<Task>('/tasks', { method: 'POST', body: JSON.stringify(data) }),

  updateTask: (
    id: number,
    data: Partial<{ title: string; description: string; dimension_id: number | null; status: TaskStatus }>
  ) => request<Task>(`/tasks/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),

  deleteTask: (id: number) => request<void>(`/tasks/${id}`, { method: 'DELETE' }),

  getDimensions: () => request<Dimension[]>('/dimensions'),

  createDimension: (name: string) =>
    request<Dimension>('/dimensions', { method: 'POST', body: JSON.stringify({ name }) }),

  updateDimension: (id: number, name: string) =>
    request<Dimension>(`/dimensions/${id}`, { method: 'PATCH', body: JSON.stringify({ name }) }),

  deleteDimension: (id: number) => request<void>(`/dimensions/${id}`, { method: 'DELETE' }),

  getEntries: (since?: string) =>
    request<Entry[]>(`/entries${since ? `?since=${since}` : ''}`),

  logEntry: (data: { dimension_id: number; date: string; score: number; note: string }) =>
    request<Entry>('/entries', { method: 'POST', body: JSON.stringify(data) }),

  deleteEntry: (id: number) => request<void>(`/entries/${id}`, { method: 'DELETE' }),

  getTaskCompletions: (date?: string) =>
    request<TaskCompletion[]>(`/task-completions${date ? `?date=${date}` : ''}`),

  completeTask: (task_id: number, date: string) =>
    request<TaskCompletion>('/task-completions', {
      method: 'POST',
      body: JSON.stringify({ task_id, date }),
    }),

  uncompleteTask: (task_id: number, date: string) =>
    request<void>(`/task-completions?task_id=${task_id}&date=${date}`, { method: 'DELETE' }),

  getDayNotes: () => request<DayNote[]>('/day-notes'),

  saveDayNote: (date: string, note: string) =>
    request<DayNote>('/day-notes', { method: 'POST', body: JSON.stringify({ date, note }) }),

  getDates: () => request<SavedDate[]>('/dates'),

  createDate: (data: { title: string; note: string; date: string; recurring: RecurringType }) =>
    request<SavedDate>('/dates', { method: 'POST', body: JSON.stringify(data) }),

  deleteDate: (id: number) => request<void>(`/dates/${id}`, { method: 'DELETE' }),

  getPushPublicKey: () => request<{ publicKey: string | null }>('/push/public-key'),

  subscribePush: (subscription: PushSubscriptionJSON) =>
    request<{ ok: boolean }>('/push/subscribe', { method: 'POST', body: JSON.stringify(subscription) }),

  login: (password: string) =>
    request<{ ok: boolean }>('/login', { method: 'POST', body: JSON.stringify({ password }) }),

  logout: () => request<{ ok: boolean }>('/logout', { method: 'POST' }),

  getSession: () => request<{ authenticated: boolean }>('/session'),
};
