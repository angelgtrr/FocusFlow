import { useState } from 'react';
import type { RecurringType, SavedDate } from '../types';
import { keyToDate, nextOccurrence } from '../utils';
import DateForm from './DateForm';

interface DateListProps {
  dates: SavedDate[];
  onUpdate: (id: number, data: { title: string; note: string; date: string; recurring: RecurringType }) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
}

const RECURRING_BADGE = 'bg-violet-500/20 text-violet-300 border-violet-500/40';

function formatDaysUntil(daysUntil: number): string {
  if (daysUntil === 0) return 'Today';
  if (daysUntil === 1) return 'Tomorrow';
  if (daysUntil === -1) return 'Yesterday';
  if (daysUntil > 1) return `in ${daysUntil} days`;
  return `${-daysUntil} days ago`;
}

function formatOccurrence(occurrenceKey: string): string {
  return keyToDate(occurrenceKey).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
}

function DateCard({
  date,
  onUpdate,
  onDelete,
}: {
  date: SavedDate;
  onUpdate: (id: number, data: { title: string; note: string; date: string; recurring: RecurringType }) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
}) {
  const [editing, setEditing] = useState(false);
  const { occurrenceKey, daysUntil } = nextOccurrence(date.date, date.recurring);

  if (editing) {
    return (
      <li>
        <DateForm
          initial={date}
          onSubmit={(data) => onUpdate(date.id, data)}
          onCancel={() => setEditing(false)}
        />
      </li>
    );
  }

  return (
    <li className="rounded-lg border border-slate-800 bg-slate-900/60 p-4">
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <p className="font-medium text-slate-200">{date.title}</p>
            {date.recurring === 'yearly' && (
              <span className={`rounded-full border px-2 py-0.5 text-[11px] ${RECURRING_BADGE}`}>Yearly</span>
            )}
          </div>
          {date.note && <p className="mt-1 text-sm text-slate-500">{date.note}</p>}
          <p className="mt-1 text-xs text-slate-600">
            {formatOccurrence(occurrenceKey)} · {formatDaysUntil(daysUntil)}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => setEditing(true)}
            className="text-xs text-slate-500 hover:text-violet-400"
            aria-label={`Edit ${date.title}`}
          >
            Edit
          </button>
          <button
            onClick={() => onDelete(date.id)}
            className="text-xs text-slate-500 hover:text-rose-400"
            aria-label={`Delete ${date.title}`}
          >
            Delete
          </button>
        </div>
      </div>
    </li>
  );
}

export default function DateList({ dates, onUpdate, onDelete }: DateListProps) {
  if (dates.length === 0) {
    return <p className="text-sm text-slate-500">No dates saved yet. Add your first one.</p>;
  }

  const withOccurrence = dates.map((d) => ({ date: d, ...nextOccurrence(d.date, d.recurring) }));
  const upcoming = withOccurrence
    .filter((d) => d.daysUntil >= 0)
    .sort((a, b) => a.daysUntil - b.daysUntil);
  const past = withOccurrence
    .filter((d) => d.daysUntil < 0)
    .sort((a, b) => b.daysUntil - a.daysUntil);

  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <h3 className="text-xs font-semibold uppercase tracking-wide text-slate-500">Upcoming</h3>
        {upcoming.length === 0 ? (
          <p className="text-sm text-slate-500">Nothing upcoming.</p>
        ) : (
          <ul className="space-y-2">
            {upcoming.map(({ date }) => (
              <DateCard key={date.id} date={date} onUpdate={onUpdate} onDelete={onDelete} />
            ))}
          </ul>
        )}
      </div>
      {past.length > 0 && (
        <div className="space-y-2">
          <h3 className="text-xs font-semibold uppercase tracking-wide text-slate-500">Past</h3>
          <ul className="space-y-2">
            {past.map(({ date }) => (
              <DateCard key={date.id} date={date} onUpdate={onUpdate} onDelete={onDelete} />
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
