import { useEffect, useState } from 'react';
import Header from './components/Header';
import DailyPage from './pages/DailyPage';
import DimensionsPage from './pages/DimensionsPage';
import TasksPage from './pages/TasksPage';
import DatesPage from './pages/DatesPage';
import LoginPage from './pages/LoginPage';
import { api, UnauthorizedError } from './api';
import type { DayNote, Dimension, Entry, RecurringType, SavedDate, Task, TaskCompletion, TaskStatus } from './types';

export default function App() {
  const [tab, setTab] = useState<'daily' | 'dimensions' | 'tasks' | 'dates'>('daily');
  const [tasks, setTasks] = useState<Task[]>([]);
  const [entries, setEntries] = useState<Entry[]>([]);
  const [dimensions, setDimensions] = useState<Dimension[]>([]);
  const [taskCompletions, setTaskCompletions] = useState<TaskCompletion[]>([]);
  const [dayNotes, setDayNotes] = useState<DayNote[]>([]);
  const [dates, setDates] = useState<SavedDate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [authed, setAuthed] = useState(false);

  async function refresh() {
    try {
      const [tasksData, entriesData, dimensionsData, taskCompletionsData, dayNotesData, datesData] = await Promise.all([
        api.getTasks(),
        api.getEntries(),
        api.getDimensions(),
        api.getTaskCompletions(),
        api.getDayNotes(),
        api.getDates(),
      ]);
      setTasks(tasksData);
      setEntries(entriesData);
      setDimensions(dimensionsData);
      setTaskCompletions(taskCompletionsData);
      setDayNotes(dayNotesData);
      setDates(datesData);
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
    setTasks([]);
    setEntries([]);
    setDimensions([]);
    setTaskCompletions([]);
    setDayNotes([]);
    setDates([]);
  }

  async function handleLogEntry(data: { dimension_id: number; date: string; score: number; note: string }) {
    await api.logEntry(data);
    await refresh();
  }

  async function handleToggleTaskCompletion(taskId: number, date: string, completed: boolean) {
    if (completed) {
      await api.completeTask(taskId, date);
    } else {
      await api.uncompleteTask(taskId, date);
    }
    await refresh();
  }

  async function handleSaveDayNote(date: string, note: string) {
    await api.saveDayNote(date, note);
    await refresh();
  }

  async function handleCreateTask(data: { title: string; description: string; dimension_id: number | null }) {
    await api.createTask(data);
    await refresh();
  }

  async function handleStatusChange(id: number, status: TaskStatus) {
    await api.updateTask(id, { status });
    await refresh();
  }

  async function handleDeleteTask(id: number) {
    await api.deleteTask(id);
    await refresh();
  }

  async function handleCreateDimension(name: string) {
    await api.createDimension(name);
    await refresh();
  }

  async function handleRenameDimension(id: number, name: string) {
    await api.updateDimension(id, name);
    await refresh();
  }

  async function handleDeleteDimension(id: number) {
    await api.deleteDimension(id);
    await refresh();
  }

  async function handleCreateDate(data: { title: string; note: string; date: string; recurring: RecurringType }) {
    await api.createDate(data);
    await refresh();
  }

  async function handleDeleteDate(id: number) {
    await api.deleteDate(id);
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
      {tab === 'daily' && (
        <DailyPage
          tasks={tasks}
          entries={entries}
          dimensions={dimensions}
          taskCompletions={taskCompletions}
          dayNotes={dayNotes}
          onLogEntry={handleLogEntry}
          onToggleTaskCompletion={handleToggleTaskCompletion}
          onSaveDayNote={handleSaveDayNote}
        />
      )}
      {tab === 'dimensions' && (
        <DimensionsPage
          dimensions={dimensions}
          tasks={tasks}
          onCreate={handleCreateDimension}
          onRename={handleRenameDimension}
          onDelete={handleDeleteDimension}
        />
      )}
      {tab === 'tasks' && (
        <TasksPage
          tasks={tasks}
          dimensions={dimensions}
          onCreateTask={handleCreateTask}
          onStatusChange={handleStatusChange}
          onDeleteTask={handleDeleteTask}
        />
      )}
      {tab === 'dates' && (
        <DatesPage dates={dates} onCreate={handleCreateDate} onDelete={handleDeleteDate} />
      )}
    </div>
  );
}
