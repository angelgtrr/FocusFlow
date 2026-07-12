import { useMemo, useState } from 'react';
import type { Goal } from '../types';
import { SCORE_LABELS } from '../types';
import { dimensionsFromGoals } from '../utils';
import { SCORE_RING_COLORS } from '../constants';

interface LogEntryModalProps {
  goals: Goal[];
  onClose: () => void;
  onSubmit: (data: { goal_id: number; score: number; note: string }) => Promise<void>;
}

export default function LogEntryModal({ goals, onClose, onSubmit }: LogEntryModalProps) {
  const activeGoals = useMemo(() => goals.filter((g) => g.status === 'active'), [goals]);
  const dimensions = useMemo(() => dimensionsFromGoals(activeGoals), [activeGoals]);

  const [dimension, setDimension] = useState(dimensions[0] ?? '');
  const goalsInDimension = useMemo(
    () => activeGoals.filter((g) => g.dimension === dimension),
    [activeGoals, dimension]
  );
  const [goalId, setGoalId] = useState<number | ''>(goalsInDimension[0]?.id ?? '');
  const [score, setScore] = useState<number | null>(null);
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function handleDimensionChange(dim: string) {
    setDimension(dim);
    const first = activeGoals.find((g) => g.dimension === dim);
    setGoalId(first?.id ?? '');
  }

  async function handleSubmit() {
    if (!goalId || score === null) {
      setError('Pick a goal and a score first.');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await onSubmit({ goal_id: goalId, score, note });
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Something went wrong.');
    } finally {
      setSubmitting(false);
    }
  }

  if (activeGoals.length === 0) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4">
        <div className="w-full max-w-md rounded-xl border border-slate-800 bg-slate-900 p-6">
          <p className="text-slate-300">
            No active goals yet. Head to <span className="text-violet-400">Admin Goals</span> to
            create one first.
          </p>
          <button
            onClick={onClose}
            className="mt-4 w-full rounded-lg bg-slate-800 py-2 text-sm text-slate-200 hover:bg-slate-700"
          >
            Close
          </button>
        </div>
      </div>
    );
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md rounded-xl border border-slate-800 bg-slate-900 p-6"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 className="text-lg font-semibold text-slate-100">Log today's progress</h2>

        <label className="mt-4 block text-xs uppercase tracking-wide text-slate-500">
          Dimension
        </label>
        <select
          value={dimension}
          onChange={(e) => handleDimensionChange(e.target.value)}
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100"
        >
          {dimensions.map((d) => (
            <option key={d} value={d}>
              {d}
            </option>
          ))}
        </select>

        <label className="mt-4 block text-xs uppercase tracking-wide text-slate-500">Goal</label>
        <select
          value={goalId}
          onChange={(e) => setGoalId(Number(e.target.value))}
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100"
        >
          {goalsInDimension.map((g) => (
            <option key={g.id} value={g.id}>
              {g.title}
            </option>
          ))}
        </select>

        <label className="mt-4 block text-xs uppercase tracking-wide text-slate-500">Score</label>
        <div className="mt-2 grid grid-cols-5 gap-2">
          {[0, 1, 2, 3, 4].map((s) => (
            <button
              key={s}
              onClick={() => setScore(s)}
              className={`rounded-lg border py-2 text-sm font-medium transition ${
                score === s
                  ? `ring-2 ${SCORE_RING_COLORS[s]} border-transparent text-slate-100`
                  : 'border-slate-700 text-slate-400 hover:border-slate-500'
              }`}
            >
              {s}
            </button>
          ))}
        </div>
        {score !== null && (
          <p className="mt-1 text-xs text-slate-500">{SCORE_LABELS[score]}</p>
        )}

        <label className="mt-4 block text-xs uppercase tracking-wide text-slate-500">Note</label>
        <textarea
          value={note}
          onChange={(e) => setNote(e.target.value)}
          rows={3}
          placeholder="What did you do today?"
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-600"
        />

        {error && <p className="mt-2 text-sm text-rose-400">{error}</p>}

        <div className="mt-5 flex gap-2">
          <button
            onClick={onClose}
            className="flex-1 rounded-lg border border-slate-700 py-2 text-sm text-slate-300 hover:bg-slate-800"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={submitting}
            className="flex-1 rounded-lg bg-violet-600 py-2 text-sm font-medium text-white hover:bg-violet-500 disabled:opacity-50"
          >
            {submitting ? 'Saving...' : 'Save entry'}
          </button>
        </div>
      </div>
    </div>
  );
}
