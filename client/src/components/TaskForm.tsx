import { useState } from 'react';
import type { Dimension } from '../types';

interface TaskFormProps {
  dimensions: Dimension[];
  initialDimensionId?: number | null;
  onSubmit: (data: { title: string; description: string; dimension_id: number | null }) => Promise<void>;
}

export default function TaskForm({ dimensions, initialDimensionId, onSubmit }: TaskFormProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [dimensionId, setDimensionId] = useState<number | null>(initialDimensionId ?? null);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) {
      setError('Title is required.');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await onSubmit({ title: title.trim(), description: description.trim(), dimension_id: dimensionId });
      setTitle('');
      setDescription('');
      setDimensionId(initialDimensionId ?? null);
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
        New task
      </h2>

      <div>
        <label className="block text-xs uppercase tracking-wide text-slate-500">Title</label>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="e.g. Run 3x a week"
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-600"
        />
      </div>

      <div>
        <label className="block text-xs uppercase tracking-wide text-slate-500">Dimension</label>
        <select
          value={dimensionId ?? ''}
          onChange={(e) => setDimensionId(e.target.value === '' ? null : Number(e.target.value))}
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100"
        >
          <option value="">No dimension</option>
          {dimensions.map((d) => (
            <option key={d.id} value={d.id}>
              {d.name}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="block text-xs uppercase tracking-wide text-slate-500">
          Description
        </label>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          rows={2}
          placeholder="Brief description of the task"
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-600"
        />
      </div>

      {error && <p className="text-sm text-rose-400">{error}</p>}

      <button
        type="submit"
        disabled={submitting}
        className="w-full rounded-lg bg-violet-600 py-2 text-sm font-medium text-white hover:bg-violet-500 disabled:opacity-50"
      >
        {submitting ? 'Adding...' : 'Add task'}
      </button>
    </form>
  );
}
