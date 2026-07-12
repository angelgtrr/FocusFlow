import { useState } from 'react';
import type { Dimension, Task } from '../types';
import { dimensionColor } from '../constants';
import { tasksByDimensionId } from '../utils';

interface DimensionsPageProps {
  dimensions: Dimension[];
  tasks: Task[];
  onCreate: (name: string) => Promise<void>;
  onRename: (id: number, name: string) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
}

function DimensionRow({
  dimension,
  taskCount,
  onRename,
  onDelete,
}: {
  dimension: Dimension;
  taskCount: number;
  onRename: (id: number, name: string) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
}) {
  const [editing, setEditing] = useState(false);
  const [name, setName] = useState(dimension.name);
  const [submitting, setSubmitting] = useState(false);

  async function handleSave() {
    if (!name.trim() || name.trim() === dimension.name) {
      setEditing(false);
      setName(dimension.name);
      return;
    }
    setSubmitting(true);
    try {
      await onRename(dimension.id, name.trim());
    } finally {
      setSubmitting(false);
      setEditing(false);
    }
  }

  async function handleDelete() {
    const message =
      taskCount > 0
        ? `Delete "${dimension.name}"? ${taskCount} task(s) will become dimension-less.`
        : `Delete "${dimension.name}"?`;
    if (window.confirm(message)) {
      await onDelete(dimension.id);
    }
  }

  return (
    <li className="flex items-center justify-between gap-2 rounded-lg border border-slate-800 bg-slate-900/60 p-4">
      <div className="flex min-w-0 items-center gap-2">
        {editing ? (
          <input
            autoFocus
            value={name}
            onChange={(e) => setName(e.target.value)}
            onBlur={handleSave}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSave();
              if (e.key === 'Escape') {
                setEditing(false);
                setName(dimension.name);
              }
            }}
            disabled={submitting}
            className="rounded-lg border border-slate-700 bg-slate-800 px-2 py-1 text-sm text-slate-100"
          />
        ) : (
          <button
            onClick={() => setEditing(true)}
            className={`rounded-full border px-3 py-1 text-xs font-medium ${dimensionColor(dimension.name)}`}
          >
            {dimension.name}
          </button>
        )}
        <span className="text-xs text-slate-500">
          {taskCount} {taskCount === 1 ? 'task' : 'tasks'}
        </span>
      </div>
      <button
        onClick={handleDelete}
        className="text-xs text-slate-500 hover:text-rose-400"
        aria-label={`Delete ${dimension.name}`}
      >
        Delete
      </button>
    </li>
  );
}

export default function DimensionsPage({
  dimensions,
  tasks,
  onCreate,
  onRename,
  onDelete,
}: DimensionsPageProps) {
  const [newName, setNewName] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const byDimension = tasksByDimensionId(tasks);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!newName.trim()) {
      setError('Name is required.');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await onCreate(newName.trim());
      setNewName('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="mx-auto max-w-5xl px-6 py-6 grid gap-6 md:grid-cols-[minmax(0,1fr)_320px]">
      <section className="space-y-3">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
          Dimensions
        </h2>
        {dimensions.length === 0 ? (
          <p className="text-sm text-slate-500">
            No dimensions yet. Add one to start grouping tasks.
          </p>
        ) : (
          <ul className="space-y-2">
            {dimensions.map((d) => (
              <DimensionRow
                key={d.id}
                dimension={d}
                taskCount={byDimension.get(d.id)?.length ?? 0}
                onRename={onRename}
                onDelete={onDelete}
              />
            ))}
          </ul>
        )}
      </section>
      <section>
        <form
          onSubmit={handleCreate}
          className="rounded-xl border border-slate-800 bg-slate-900/60 p-4 space-y-3"
        >
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
            New dimension
          </h2>
          <div>
            <label className="block text-xs uppercase tracking-wide text-slate-500">Name</label>
            <input
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              placeholder="e.g. Exercise, Work, Learning"
              className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-600"
            />
          </div>
          {error && <p className="text-sm text-rose-400">{error}</p>}
          <button
            type="submit"
            disabled={submitting}
            className="w-full rounded-lg bg-violet-600 py-2 text-sm font-medium text-white hover:bg-violet-500 disabled:opacity-50"
          >
            {submitting ? 'Adding...' : 'Add dimension'}
          </button>
        </form>
      </section>
    </div>
  );
}
