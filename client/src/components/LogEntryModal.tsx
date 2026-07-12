import { useState } from 'react';
import type { Dimension } from '../types';
import { SCORE_LABELS } from '../types';
import { SCORE_RING_COLORS } from '../constants';
import { todayKey } from '../utils';

interface LogEntryModalProps {
  dimensions: Dimension[];
  initialDimensionId?: number;
  initialScore?: number | null;
  initialNote?: string;
  initialDate?: string;
  onClose: () => void;
  onSubmit: (data: { dimension_id: number; date: string; score: number; note: string }) => Promise<void>;
}

export default function LogEntryModal({
  dimensions,
  initialDimensionId,
  initialScore = null,
  initialNote = '',
  initialDate,
  onClose,
  onSubmit,
}: LogEntryModalProps) {
  const [dimensionId, setDimensionId] = useState<number | ''>(
    initialDimensionId ?? dimensions[0]?.id ?? ''
  );
  const [date, setDate] = useState(initialDate ?? todayKey());
  const [score, setScore] = useState<number | null>(initialScore);
  const [note, setNote] = useState(initialNote);
  const isEditing = initialScore !== null && initialScore !== undefined;
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit() {
    if (!dimensionId || !date || score === null) {
      setError('Pick a dimension, a date, and a score first.');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await onSubmit({ dimension_id: dimensionId, date, score, note });
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Something went wrong.');
    } finally {
      setSubmitting(false);
    }
  }

  if (dimensions.length === 0) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4">
        <div className="w-full max-w-md rounded-xl border border-slate-800 bg-slate-900 p-6">
          <p className="text-slate-300">
            No dimensions yet. Head to <span className="text-violet-400">Dimensions</span> to
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
        <h2 className="text-lg font-semibold text-slate-100">
          {isEditing ? 'Update progress' : 'Log progress'}
        </h2>

        <label className="mt-4 block text-xs uppercase tracking-wide text-slate-500">
          Dimension
        </label>
        <select
          value={dimensionId}
          onChange={(e) => setDimensionId(Number(e.target.value))}
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100"
        >
          {dimensions.map((d) => (
            <option key={d.id} value={d.id}>
              {d.name}
            </option>
          ))}
        </select>

        <label className="mt-4 block text-xs uppercase tracking-wide text-slate-500">Date</label>
        <input
          type="date"
          value={date}
          max={todayKey()}
          onChange={(e) => setDate(e.target.value)}
          className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 [color-scheme:dark]"
        />

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
