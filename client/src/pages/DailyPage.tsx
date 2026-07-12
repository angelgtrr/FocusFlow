import { useMemo, useState } from 'react';
import type { Entry, Goal } from '../types';
import StatsBar from '../components/StatsBar';
import Heatmap from '../components/Heatmap';
import TrendChart from '../components/TrendChart';
import TodayEntries from '../components/TodayEntries';
import LogEntryModal from '../components/LogEntryModal';
import {
  buildHeatmap,
  buildTrend,
  currentStreak,
  dimensionsFromGoals,
  todayKey,
  weeklyProgressPct,
} from '../utils';

interface DailyPageProps {
  goals: Goal[];
  entries: Entry[];
  onLogEntry: (data: { goal_id: number; score: number; note: string }) => Promise<void>;
}

export default function DailyPage({ goals, entries, onLogEntry }: DailyPageProps) {
  const [modalOpen, setModalOpen] = useState(false);
  const [dimensionFilter, setDimensionFilter] = useState<string>('all');

  const activeGoals = useMemo(() => goals.filter((g) => g.status === 'active'), [goals]);
  const dimensions = useMemo(() => dimensionsFromGoals(activeGoals), [activeGoals]);

  const filteredEntries = useMemo(
    () =>
      dimensionFilter === 'all'
        ? entries
        : entries.filter((e) => e.goal_dimension === dimensionFilter),
    [entries, dimensionFilter]
  );

  const todaysEntries = useMemo(
    () => entries.filter((e) => e.date === todayKey()),
    [entries]
  );

  const heatmapDays = useMemo(() => buildHeatmap(filteredEntries), [filteredEntries]);
  const trendData = useMemo(() => buildTrend(filteredEntries), [filteredEntries]);

  return (
    <div className="mx-auto max-w-5xl px-6 py-6 space-y-8">
      <StatsBar
        activeGoals={activeGoals.length}
        weeklyProgressPct={weeklyProgressPct(entries, activeGoals)}
        streak={currentStreak(entries)}
        loggedToday={todaysEntries.length}
      />

      <section>
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
            Today's log
          </h2>
          <button
            onClick={() => setModalOpen(true)}
            className="flex h-9 w-9 items-center justify-center rounded-full bg-violet-600 text-xl leading-none text-white shadow-lg hover:bg-violet-500"
            aria-label="Log new entry"
          >
            +
          </button>
        </div>
        <div className="mt-3">
          <TodayEntries entries={todaysEntries} />
        </div>
      </section>

      <section>
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
            Consistency
          </h2>
          <select
            value={dimensionFilter}
            onChange={(e) => setDimensionFilter(e.target.value)}
            className="rounded-lg border border-slate-700 bg-slate-800 px-2 py-1 text-xs text-slate-200"
          >
            <option value="all">All dimensions</option>
            {dimensions.map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </select>
        </div>
        <div className="mt-3 rounded-xl border border-slate-800 bg-slate-900/60 p-4">
          <Heatmap days={heatmapDays} />
        </div>
      </section>

      <section>
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
          30-day trend
        </h2>
        <div className="mt-3 rounded-xl border border-slate-800 bg-slate-900/60 p-4">
          <TrendChart data={trendData} />
        </div>
      </section>

      {modalOpen && (
        <LogEntryModal
          goals={goals}
          onClose={() => setModalOpen(false)}
          onSubmit={onLogEntry}
        />
      )}
    </div>
  );
}
