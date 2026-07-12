import type { Goal, GoalStatus } from '../types';
import { dimensionColor } from '../constants';

interface GoalListProps {
  goals: Goal[];
  onStatusChange: (id: number, status: GoalStatus) => Promise<void>;
}

const STATUS_OPTIONS: GoalStatus[] = ['active', 'paused', 'done'];

const STATUS_STYLES: Record<GoalStatus, string> = {
  active: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40',
  paused: 'bg-amber-500/20 text-amber-300 border-amber-500/40',
  done: 'bg-slate-500/20 text-slate-400 border-slate-500/40',
};

export default function GoalList({ goals, onStatusChange }: GoalListProps) {
  if (goals.length === 0) {
    return <p className="text-sm text-slate-500">No goals yet. Add your first one.</p>;
  }

  return (
    <ul className="space-y-2">
      {goals.map((g) => (
        <li
          key={g.id}
          className="rounded-lg border border-slate-800 bg-slate-900/60 p-4"
        >
          <div className="flex flex-wrap items-start justify-between gap-2">
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <p className="font-medium text-slate-200">{g.title}</p>
                <span
                  className={`rounded-full border px-2 py-0.5 text-[11px] ${dimensionColor(g.dimension)}`}
                >
                  {g.dimension}
                </span>
              </div>
              {g.description && (
                <p className="mt-1 text-sm text-slate-500">{g.description}</p>
              )}
            </div>
            <select
              value={g.status}
              onChange={(e) => onStatusChange(g.id, e.target.value as GoalStatus)}
              className={`rounded-full border px-2 py-1 text-xs font-medium capitalize ${STATUS_STYLES[g.status]}`}
            >
              {STATUS_OPTIONS.map((s) => (
                <option key={s} value={s} className="bg-slate-900 text-slate-200">
                  {s}
                </option>
              ))}
            </select>
          </div>
        </li>
      ))}
    </ul>
  );
}
