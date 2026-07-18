import { useState } from 'react';
import type { RecurringType } from '../types';
import { todayKey } from '../utils';

interface DateFormProps {
  onSubmit: (data: { title: string; note: string; date: string; recurring: RecurringType }) => Promise<void>;
}

export default function DateForm({ onSubmit }: DateFormProps) {
  const [title, setTitle] = useState('');
  const [date, setDate] = useState(todayKey());
  const [recurring, setRecurring] = useState(false);
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) {
      setError('Title is required.');
      return;
    }
    if (!date) {
      setError('Date is required.');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await onSubmit({
        title: title.trim(),
        note: note.trim(),
        date,
        recurring: recurring ? 'yearly' : 'none',
      });
      setTitle('');
      setDate(todayKey());
      setRecurring(false);
      setNote('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="rounded-xl border border-slate-800 bg-slate-900/60 p-4 space-y-3"
    >
      <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
        New date
      </h2>

      <div>
        <label className="block text-xs uppercase tracking-wide text-slate-500">Title</label>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="e.g. Mom's birthday"
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-600"
        />
      </div>

      <div>
        <label className="block text-xs uppercase tracking-wide text-slate-500">Date</label>
        <input
          type="date"
          value={date}
          onChange={(e) => setDate(e.target.value)}
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100"
        />
      </div>

      <label className="flex items-center gap-2 text-sm text-slate-300">
        <input
          type="checkbox"
          checked={recurring}
          onChange={(e) => setRecurring(e.target.checked)}
          className="h-4 w-4 rounded border-slate-700 bg-slate-800 text-violet-600"
        />
        Repeats yearly
      </label>

      <div>
        <label className="block text-xs uppercase tracking-wide text-slate-500">Note</label>
        <textarea
          value={note}
          onChange={(e) => setNote(e.target.value)}
          rows={2}
          placeholder="Optional note"
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-600"
        />
      </div>

      {error && <p className="text-sm text-rose-400">{error}</p>}

      <button
        type="submit"
        disabled={submitting}
        className="w-full rounded-lg bg-violet-600 py-2 text-sm font-medium text-white hover:bg-violet-500 disabled:opacity-50"
      >
        {submitting ? 'Adding...' : 'Add date'}
      </button>
    </form>
  );
}
