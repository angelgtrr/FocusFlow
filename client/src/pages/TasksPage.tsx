import { useMemo, useState } from 'react';
import type { Dimension, Task, TaskStatus } from '../types';
import TaskForm from '../components/TaskForm';
import TaskList from '../components/TaskList';

interface TasksPageProps {
  tasks: Task[];
  dimensions: Dimension[];
  onCreateTask: (data: { title: string; description: string; dimension_id: number | null }) => Promise<void>;
  onStatusChange: (id: number, status: TaskStatus) => Promise<void>;
  onDeleteTask: (id: number) => Promise<void>;
}

const STATUS_ORDER: Record<TaskStatus, number> = { active: 0, paused: 1, done: 2 };

export default function TasksPage({
  tasks,
  dimensions,
  onCreateTask,
  onStatusChange,
  onDeleteTask,
}: TasksPageProps) {
  const [dimensionFilter, setDimensionFilter] = useState<number | 'all' | 'none'>('all');

  const filteredTasks = useMemo(() => {
    const list =
      dimensionFilter === 'all'
        ? tasks
        : dimensionFilter === 'none'
          ? tasks.filter((t) => t.dimension_id === null)
          : tasks.filter((t) => t.dimension_id === dimensionFilter);
    return [...list].sort((a, b) => {
      const statusDiff = STATUS_ORDER[a.status] - STATUS_ORDER[b.status];
      if (statusDiff !== 0) return statusDiff;
      return b.created_at.localeCompare(a.created_at);
    });
  }, [tasks, dimensionFilter]);

  return (
    <div className="mx-auto max-w-5xl px-6 py-6 grid gap-6 md:grid-cols-[minmax(0,1fr)_320px]">
      <section className="space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">
            Tasks
          </h2>
          <select
            value={dimensionFilter}
            onChange={(e) =>
              setDimensionFilter(
                e.target.value === 'all' || e.target.value === 'none'
                  ? e.target.value
                  : Number(e.target.value)
              )
            }
            className="rounded-lg border border-slate-700 bg-slate-800 px-2 py-1 text-xs text-slate-200"
          >
            <option value="all">All dimensions</option>
            <option value="none">No dimension</option>
            {dimensions.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
          </select>
        </div>
        <TaskList tasks={filteredTasks} onStatusChange={onStatusChange} onDeleteTask={onDeleteTask} />
      </section>
      <section>
        <TaskForm dimensions={dimensions} onSubmit={onCreateTask} />
      </section>
    </div>
  );
}
