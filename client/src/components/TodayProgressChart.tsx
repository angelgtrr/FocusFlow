import type { Dimension } from '../types';
import type { DimensionProgress } from '../utils';
import { SCORE_COLORS, dimensionColor } from '../constants';

interface TodayProgressChartProps {
  progress: DimensionProgress[];
  onSelectDimension?: (dimension: Dimension) => void;
}

export default function TodayProgressChart({ progress, onSelectDimension }: TodayProgressChartProps) {
  if (progress.length === 0) {
    return <p className="text-sm text-slate-500">No dimensions yet. Add one in the Dimensions tab.</p>;
  }

  const sorted = [...progress].sort((a, b) => (b.entry?.score ?? 0) - (a.entry?.score ?? 0));

  return (
    <div className="space-y-3">
      {sorted.map((row) => (
        <button
          key={row.dimension.id}
          type="button"
          onClick={() => onSelectDimension?.(row.dimension)}
          aria-label={`View 30-day trend for ${row.dimension.name}`}
          className="flex w-full items-center gap-3 rounded-lg text-left hover:bg-slate-800/60"
        >
          <span
            className={`w-24 shrink-0 truncate rounded-full border px-2 py-0.5 text-center text-xs ${dimensionColor(row.dimension.name)}`}
          >
            {row.dimension.name}
          </span>
          <div className="h-4 flex-1 overflow-hidden rounded-full bg-slate-800">
            <div
              className={`h-full rounded-full ${row.entry ? SCORE_COLORS[row.entry.score] : ''}`}
              style={{ width: row.entry ? `${(row.entry.score / 4) * 100}%` : '0%' }}
            />
          </div>
          <span className="w-4 shrink-0 text-right text-xs font-semibold text-slate-300">
            {row.entry ? row.entry.score : '–'}
          </span>
        </button>
      ))}
    </div>
  );
}
