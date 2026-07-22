import { useMemo, useState } from 'react';
import type { DayNote, Dimension, Entry, Task, TaskCompletion } from '../types';
import { SCORE_LABELS } from '../types';
import StatsBar from '../components/StatsBar';
import Heatmap from '../components/Heatmap';
import TrendChart from '../components/TrendChart';
import TaskChecklist from '../components/TaskChecklist';
import LogEntryModal from '../components/LogEntryModal';
import MonthCalendar from '../components/MonthCalendar';
import TodayProgressChart from '../components/TodayProgressChart';
import HourglassProgress from '../components/HourglassProgress';
import DayNoteEditor from '../components/DayNoteEditor';
import DimensionTrendPage from './DimensionTrendPage';
import { SCORE_COLORS, dimensionColor } from '../constants';
import {
  activeDateKeys,
  addDays,
  buildDimensionProgress,
  buildHeatmap,
  buildTrend,
  completedTaskIdsForDate,
  currentStreak,
  formatDayHeading,
  keyToDate,
  toDateKey,
  todayKey,
  todayProgressPct,
  weeklyProgressPct,
} from '../utils';
import type { DimensionProgress } from '../utils';

interface DailyPageProps {
  tasks: Task[];
  entries: Entry[];
  dimensions: Dimension[];
  taskCompletions: TaskCompletion[];
  dayNotes: DayNote[];
  onLogEntry: (data: { dimension_id: number; date: string; score: number; note: string }) => Promise<void>;
  onToggleTaskCompletion: (taskId: number, date: string, completed: boolean) => Promise<void>;
  onSaveDayNote: (date: string, note: string) => Promise<void>;
}

export default function DailyPage({
  tasks,
  entries,
  dimensions,
  taskCompletions,
  dayNotes,
  onLogEntry,
  onToggleTaskCompletion,
  onSaveDayNote,
}: DailyPageProps) {
  const [modalOpen, setModalOpen] = useState(false);
  const [editDimensionId, setEditDimensionId] = useState<number | null>(null);
  const [trendDimension, setTrendDimension] = useState<Dimension | null>(null);
  const [dimensionFilter, setDimensionFilter] = useState<number | 'all'>('all');
  const [selectedDate, setSelectedDate] = useState(todayKey());
  const [calendarOpen, setCalendarOpen] = useState(false);
  const isToday = selectedDate === todayKey();

  function goToYesterday() {
    setSelectedDate(toDateKey(addDays(keyToDate(todayKey()), -1)));
  }

  function goToToday() {
    setSelectedDate(todayKey());
  }

  const activeTasks = useMemo(() => tasks.filter((t) => t.status === 'active'), [tasks]);

  const filteredEntries = useMemo(
    () =>
      dimensionFilter === 'all' ? entries : entries.filter((e) => e.dimension_id === dimensionFilter),
    [entries, dimensionFilter]
  );

  const filteredDimensions = useMemo(
    () =>
      dimensionFilter === 'all' ? dimensions : dimensions.filter((d) => d.id === dimensionFilter),
    [dimensions, dimensionFilter]
  );

  const allTodaysEntries = useMemo(
    () => entries.filter((e) => e.date === selectedDate),
    [entries, selectedDate]
  );

  const dimensionProgress = useMemo(
    () => buildDimensionProgress(dimensions, allTodaysEntries),
    [dimensions, allTodaysEntries]
  );

  const pendingDimensionProgress = useMemo(
    () => dimensionProgress.filter((row) => row.entry?.score !== 4),
    [dimensionProgress]
  );

  const doneDimensionProgress = useMemo(
    () => dimensionProgress.filter((row) => row.entry?.score === 4),
    [dimensionProgress]
  );

  const completedTaskIds = useMemo(
    () => completedTaskIdsForDate(taskCompletions, selectedDate),
    [taskCompletions, selectedDate]
  );

  const tasksDoneToday = useMemo(
    () => ({
      done: activeTasks.filter((t) => completedTaskIds.has(t.id)).length,
      total: activeTasks.length,
    }),
    [activeTasks, completedTaskIds]
  );

  const heatmapDays = useMemo(() => buildHeatmap(filteredEntries), [filteredEntries]);
  const trendData = useMemo(() => buildTrend(filteredEntries), [filteredEntries]);

  const activeDates = useMemo(
    () => activeDateKeys(entries, taskCompletions, dayNotes),
    [entries, taskCompletions, dayNotes]
  );

  const selectedDayNote = useMemo(
    () => dayNotes.find((n) => n.date === selectedDate)?.note ?? '',
    [dayNotes, selectedDate]
  );

  if (trendDimension) {
    return (
      <DimensionTrendPage
        dimension={trendDimension}
        entries={entries}
        onBack={() => setTrendDimension(null)}
      />
    );
  }

  return (
    <div className="mx-auto max-w-5xl px-6 py-6 space-y-8">
      <StatsBar
        dimensionCount={filteredDimensions.length}
        weeklyProgressPct={weeklyProgressPct(filteredEntries, filteredDimensions)}
        todayProgressPct={todayProgressPct(dimensionProgress)}
        streak={currentStreak(filteredEntries)}
        tasksDoneToday={tasksDoneToday}
        tasksDoneLabel={isToday ? 'Tasks Done Today' : 'Tasks Done'}
      />

      <section className="flex justify-center rounded-xl border border-slate-800 bg-slate-900/60 py-4">
        <HourglassProgress
          onDayRollover={(previousDateKey, newDateKey) =>
            setSelectedDate((current) => (current === previousDateKey ? newDateKey : current))
          }
        />
      </section>

      <section>
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
            {formatDayHeading(selectedDate)}
          </h2>
          <div className="flex items-center gap-2">
            <button
              onClick={isToday ? goToYesterday : goToToday}
              className="rounded-lg border border-slate-700 px-2 py-1 text-xs text-slate-300 hover:bg-slate-800"
            >
              {isToday ? 'Yesterday' : 'Today'}
            </button>
            <button
              onClick={() => setCalendarOpen((v) => !v)}
              aria-label="Toggle calendar"
              aria-expanded={calendarOpen}
              className={`flex h-7 w-7 items-center justify-center rounded-lg border border-slate-700 text-slate-300 hover:bg-slate-800 ${
                calendarOpen ? 'bg-slate-800 text-violet-400' : ''
              }`}
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 20 20"
                fill="currentColor"
                className="h-4 w-4"
              >
                <path
                  fillRule="evenodd"
                  d="M5.75 2a.75.75 0 0 1 .75.75V4h7V2.75a.75.75 0 0 1 1.5 0V4h.5A2.25 2.25 0 0 1 17.75 6.25v9A2.25 2.25 0 0 1 15.5 17.5h-11A2.25 2.25 0 0 1 2.25 15.25v-9A2.25 2.25 0 0 1 4.5 4H5V2.75A.75.75 0 0 1 5.75 2ZM3.75 8v7.25c0 .414.336.75.75.75h11a.75.75 0 0 0 .75-.75V8h-12.5Z"
                  clipRule="evenodd"
                />
              </svg>
            </button>
          </div>
        </div>
        {calendarOpen && (
          <div className="mt-3">
            <MonthCalendar
              selectedDate={selectedDate}
              onSelect={setSelectedDate}
              activeDates={activeDates}
            />
          </div>
        )}
      </section>

      <section>
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
          Dimensions
        </h2>
        {dimensionProgress.length === 0 ? (
          <p className="mt-3 text-sm text-slate-500">
            No dimensions yet. Head to the Dimensions tab to add one.
          </p>
        ) : (
          <>
            <h3 className="mt-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
              Pending
            </h3>
            <div className="mt-3 grid gap-3 sm:grid-cols-2">
              {pendingDimensionProgress.map((row) => (
                <DimensionCard
                  key={row.dimension.id}
                  row={row}
                  onEdit={() => {
                    setEditDimensionId(row.dimension.id);
                    setModalOpen(true);
                  }}
                />
              ))}
            </div>

            {doneDimensionProgress.length > 0 && (
              <>
                <h3 className="mt-6 text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Done
                </h3>
                <div className="mt-3 grid gap-3 sm:grid-cols-2">
                  {doneDimensionProgress.map((row) => (
                    <DimensionCard
                      key={row.dimension.id}
                      row={row}
                      onEdit={() => {
                        setEditDimensionId(row.dimension.id);
                        setModalOpen(true);
                      }}
                    />
                  ))}
                </div>
              </>
            )}
          </>
        )}
      </section>

      <section>
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
          Day note
        </h2>
        <div className="mt-3">
          <DayNoteEditor date={selectedDate} note={selectedDayNote} onSave={onSaveDayNote} />
        </div>
      </section>

      <section>
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
          Tasks
        </h2>
        <div className="mt-3">
          <TaskChecklist
            tasks={activeTasks}
            completedTaskIds={completedTaskIds}
            onToggle={(taskId, completed) => onToggleTaskCompletion(taskId, selectedDate, completed)}
          />
        </div>
      </section>

      <div className="flex flex-wrap items-center gap-2">
        <span className="text-xs uppercase tracking-wide text-slate-500">Filter</span>
        <select
          value={dimensionFilter}
          onChange={(e) => setDimensionFilter(e.target.value === 'all' ? 'all' : Number(e.target.value))}
          className="rounded-lg border border-slate-700 bg-slate-800 px-2 py-1 text-xs text-slate-200"
        >
          <option value="all">All dimensions</option>
          {dimensions.map((d) => (
            <option key={d.id} value={d.id}>
              {d.name}
            </option>
          ))}
        </select>
      </div>

      <section>
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
          Consistency
        </h2>
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

      <section>
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
          Today's progress
        </h2>
        <div className="mt-3 rounded-xl border border-slate-800 bg-slate-900/60 p-4">
          <TodayProgressChart progress={dimensionProgress} onSelectDimension={setTrendDimension} />
        </div>
      </section>

      {modalOpen && (
        <LogEntryModal
          dimensions={dimensions}
          initialDimensionId={editDimensionId ?? undefined}
          initialScore={
            editDimensionId != null
              ? (allTodaysEntries.find((e) => e.dimension_id === editDimensionId)?.score ?? null)
              : null
          }
          initialNote={
            editDimensionId != null
              ? (allTodaysEntries.find((e) => e.dimension_id === editDimensionId)?.note ?? '')
              : ''
          }
          initialDate={selectedDate}
          onClose={() => {
            setModalOpen(false);
            setEditDimensionId(null);
          }}
          onSubmit={onLogEntry}
        />
      )}
    </div>
  );
}

function DimensionCard({ row, onEdit }: { row: DimensionProgress; onEdit: () => void }) {
  return (
    <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
      <div className="flex items-center justify-between">
        <span className="flex items-center gap-1.5">
          <span className={`rounded-full border px-2 py-0.5 text-xs ${dimensionColor(row.dimension.name)}`}>
            {row.dimension.name}
          </span>
          <button
            onClick={onEdit}
            className="text-slate-500 hover:text-slate-300"
            aria-label={`Log progress for ${row.dimension.name}`}
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              className="h-3.5 w-3.5"
            >
              <path d="M13.586 3.586a2 2 0 1 1 2.828 2.828l-8.5 8.5a2 2 0 0 1-.878.507l-3.06.875a.5.5 0 0 1-.618-.618l.875-3.06a2 2 0 0 1 .507-.878l8.5-8.5Z" />
            </svg>
          </button>
        </span>
        {row.loggedToday && row.entry ? (
          <span className="flex items-center gap-1.5 text-sm text-slate-300">
            <span className={`h-2.5 w-2.5 rounded-full ${SCORE_COLORS[row.entry.score]}`} />
            {SCORE_LABELS[row.entry.score]}
          </span>
        ) : (
          <span className="text-sm text-slate-500">Not logged</span>
        )}
      </div>
      {row.loggedToday && row.entry?.note && (
        <p className="mt-2 whitespace-pre-line text-sm text-slate-400">{row.entry.note}</p>
      )}
    </div>
  );
}
