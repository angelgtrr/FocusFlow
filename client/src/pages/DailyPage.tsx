import { useMemo, useState } from 'react';
import type { DayNote, Dimension, Entry, Task, TaskCompletion } from '../types';
import { SCORE_LABELS } from '../types';
import StatsBar from '../components/StatsBar';
import Heatmap from '../components/Heatmap';
import TrendChart from '../components/TrendChart';
import TodayEntries from '../components/TodayEntries';
import TaskChecklist from '../components/TaskChecklist';
import LogEntryModal from '../components/LogEntryModal';
import MonthCalendar from '../components/MonthCalendar';
import DayNoteEditor from '../components/DayNoteEditor';
import { SCORE_COLORS, dimensionColor } from '../constants';
import {
  activeDateKeys,
  buildDimensionProgress,
  buildHeatmap,
  buildTrend,
  completedTaskIdsForDate,
  currentStreak,
  formatDayHeading,
  todayKey,
  weeklyProgressPct,
} from '../utils';

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
  const [dimensionFilter, setDimensionFilter] = useState<number | 'all'>('all');
  const [selectedDate, setSelectedDate] = useState(todayKey());
  const isToday = selectedDate === todayKey();

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

  const todaysEntries = useMemo(
    () => filteredEntries.filter((e) => e.date === selectedDate),
    [filteredEntries, selectedDate]
  );

  const allTodaysEntries = useMemo(
    () => entries.filter((e) => e.date === selectedDate),
    [entries, selectedDate]
  );

  const dimensionProgress = useMemo(
    () => buildDimensionProgress(dimensions, allTodaysEntries),
    [dimensions, allTodaysEntries]
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

  return (
    <div className="mx-auto max-w-5xl px-6 py-6 space-y-8">
      <section>
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
          {formatDayHeading(selectedDate)}
        </h2>
        <div className="mt-3">
          <MonthCalendar
            selectedDate={selectedDate}
            onSelect={setSelectedDate}
            activeDates={activeDates}
          />
        </div>
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
          Dimensions
        </h2>
        {dimensionProgress.length === 0 ? (
          <p className="mt-3 text-sm text-slate-500">
            No dimensions yet. Head to the Dimensions tab to add one.
          </p>
        ) : (
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            {dimensionProgress.map((row) => (
              <div
                key={row.dimension.id}
                className="rounded-xl border border-slate-800 bg-slate-900/60 p-4"
              >
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5">
                    <span className={`rounded-full border px-2 py-0.5 text-xs ${dimensionColor(row.dimension.name)}`}>
                      {row.dimension.name}
                    </span>
                    <button
                      onClick={() => {
                        setEditDimensionId(row.dimension.id);
                        setModalOpen(true);
                      }}
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
              </div>
            ))}
          </div>
        )}
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

      <StatsBar
        dimensionCount={filteredDimensions.length}
        weeklyProgressPct={weeklyProgressPct(filteredEntries, filteredDimensions)}
        streak={currentStreak(filteredEntries)}
        tasksDoneToday={tasksDoneToday}
        tasksDoneLabel={isToday ? 'Tasks Done Today' : 'Tasks Done'}
      />

      <section>
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
            {isToday ? "Today's log" : `Log for ${formatDayHeading(selectedDate)}`}
          </h2>
          <button
            onClick={() => {
              setEditDimensionId(null);
              setModalOpen(true);
            }}
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
