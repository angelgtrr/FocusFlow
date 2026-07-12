import { useState } from 'react';

interface GoalFormProps {
  existingDimensions: string[];
  onSubmit: (data: { title: string; description: string; dimension: string }) => Promise<void>;
}

export default function GoalForm({ existingDimensions, onSubmit }: GoalFormProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [dimension, setDimension] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim() || !dimension.trim()) {
      setError('Title and dimension are required.');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await onSubmit({ title: title.trim(), description: description.trim(), dimension: dimension.trim() });
      setTitle('');
      setDescription('');
      setDimension('');
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
        New goal
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
        <input
          value={dimension}
          onChange={(e) => setDimension(e.target.value)}
          placeholder="e.g. Exercise, Work, Learning"
          list="dimension-suggestions"
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-600"
        />
        <datalist id="dimension-suggestions">
          {existingDimensions.map((d) => (
            <option key={d} value={d} />
          ))}
        </datalist>
      </div>

      <div>
        <label className="block text-xs uppercase tracking-wide text-slate-500">
          Description
        </label>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          rows={2}
          placeholder="Brief description of the goal"
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-600"
        />
      </div>

      {error && <p className="text-sm text-rose-400">{error}</p>}

      <button
        type="submit"
        disabled={submitting}
        className="w-full rounded-lg bg-violet-600 py-2 text-sm font-medium text-white hover:bg-violet-500 disabled:opacity-50"
      >
        {submitting ? 'Adding...' : 'Add goal'}
      </button>
    </form>
  );
}
