import { useEffect, useState } from 'react';
import Header from './components/Header';
import DailyPage from './pages/DailyPage';
import AdminGoalsPage from './pages/AdminGoalsPage';
import LoginPage from './pages/LoginPage';
import { api, UnauthorizedError } from './api';
import type { Entry, Goal, GoalStatus } from './types';

export default function App() {
  const [tab, setTab] = useState<'daily' | 'admin'>('daily');
  const [goals, setGoals] = useState<Goal[]>([]);
  const [entries, setEntries] = useState<Entry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [authed, setAuthed] = useState(false);

  async function refresh() {
    try {
      const [goalsData, entriesData] = await Promise.all([
        api.getGoals(),
        api.getEntries(),
      ]);
      setGoals(goalsData);
      setEntries(entriesData);
    } catch (e) {
      if (e instanceof UnauthorizedError) {
        setAuthed(false);
        return;
      }
      throw e;
    }
  }

  useEffect(() => {
    api
      .getSession()
      .then((s) => {
        setAuthed(s.authenticated);
        if (s.authenticated) return refresh();
      })
      .catch((e) => setError(e instanceof Error ? e.message : 'Failed to load'))
      .finally(() => setLoading(false));
  }, []);

  async function handleLoginSuccess() {
    setAuthed(true);
    setLoading(true);
    try {
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  }

  async function handleLogout() {
    await api.logout();
    setAuthed(false);
    setGoals([]);
    setEntries([]);
  }

  async function handleLogEntry(data: { goal_id: number; score: number; note: string }) {
    const today = new Date();
    const date = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(
      today.getDate()
    ).padStart(2, '0')}`;
    await api.logEntry({ ...data, date });
    await refresh();
  }

  async function handleCreateGoal(data: { title: string; description: string; dimension: string }) {
    await api.createGoal(data);
    await refresh();
  }

  async function handleStatusChange(id: number, status: GoalStatus) {
    await api.updateGoal(id, { status });
    await refresh();
  }

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center text-slate-500">
        Loading FocusFlow...
      </div>
    );
  }

  if (!authed) {
    return <LoginPage onSuccess={handleLoginSuccess} />;
  }

  if (error) {
    return (
      <div className="flex min-h-screen items-center justify-center text-rose-400">
        {error} — is the API server running on port 4000?
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950">
      <Header tab={tab} onTabChange={setTab} onLogout={handleLogout} />
      {tab === 'daily' ? (
        <DailyPage goals={goals} entries={entries} onLogEntry={handleLogEntry} />
      ) : (
        <AdminGoalsPage
          goals={goals}
          onCreateGoal={handleCreateGoal}
          onStatusChange={handleStatusChange}
        />
      )}
    </div>
  );
}
