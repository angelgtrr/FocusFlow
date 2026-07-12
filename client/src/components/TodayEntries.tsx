import type { Entry } from '../types';
import { SCORE_LABELS } from '../types';
import { SCORE_COLORS, dimensionColor } from '../constants';

interface TodayEntriesProps {
  entries: Entry[];
}

export default function TodayEntries({ entries }: TodayEntriesProps) {
  if (entries.length === 0) {
    return (
      <p className="text-sm text-slate-500">
        Nothing logged yet today. Tap the + button to add your first entry.
      </p>
    );
  }

  return (
    <ul className="space-y-2">
      {entries.map((e) => (
        <li
          key={e.id}
          className="flex items-start gap-3 rounded-lg border border-slate-800 bg-slate-900/60 p-3"
        >
          <span className={`mt-0.5 h-2.5 w-2.5 flex-shrink-0 rounded-full ${SCORE_COLORS[e.score]}`} />
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <p className="font-medium text-slate-200 truncate">{e.goal_title}</p>
              <span
                className={`rounded-full border px-2 py-0.5 text-[11px] ${dimensionColor(e.goal_dimension)}`}
              >
                {e.goal_dimension}
              </span>
            </div>
            <p className="text-xs text-slate-500">{SCORE_LABELS[e.score]}</p>
            {e.note && <p className="mt-1 text-sm text-slate-400">{e.note}</p>}
          </div>
        </li>
      ))}
    </ul>
  );
}
