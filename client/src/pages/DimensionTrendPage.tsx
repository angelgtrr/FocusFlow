import TrendChart from '../components/TrendChart';
import { dimensionColor } from '../constants';
import { buildTrend } from '../utils';
import type { Dimension, Entry } from '../types';

interface DimensionTrendPageProps {
  dimension: Dimension;
  entries: Entry[];
  onBack: () => void;
}

export default function DimensionTrendPage({ dimension, entries, onBack }: DimensionTrendPageProps) {
  const dimensionEntries = entries.filter((e) => e.dimension_id === dimension.id);
  const trendData = buildTrend(dimensionEntries);

  return (
    <div className="mx-auto max-w-5xl px-6 py-6 space-y-6">
      <div className="flex items-center gap-3">
        <button
          onClick={onBack}
          aria-label="Back"
          className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-700 text-slate-300 hover:bg-slate-800"
        >
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="h-4 w-4">
            <path
              fillRule="evenodd"
              d="M17 10a.75.75 0 0 1-.75.75H5.612l4.158 3.96a.75.75 0 1 1-1.04 1.08l-5.5-5.25a.75.75 0 0 1 0-1.08l5.5-5.25a.75.75 0 1 1 1.04 1.08L5.612 9.25H16.25A.75.75 0 0 1 17 10Z"
              clipRule="evenodd"
            />
          </svg>
        </button>
        <span className={`rounded-full border px-2 py-0.5 text-xs ${dimensionColor(dimension.name)}`}>
          {dimension.name}
        </span>
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">30-day trend</h2>
      </div>

      <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
        <TrendChart data={trendData} />
      </div>
    </div>
  );
}
