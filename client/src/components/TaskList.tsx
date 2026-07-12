import type { Task, TaskStatus } from '../types';
import { dimensionColor, NO_DIMENSION_STYLE } from '../constants';

interface TaskListProps {
  tasks: Task[];
  onStatusChange: (id: number, status: TaskStatus) => Promise<void>;
  onDeleteTask?: (id: number) => Promise<void>;
  showDimension?: boolean;
}

const STATUS_OPTIONS: TaskStatus[] = ['active', 'paused', 'done'];

const STATUS_STYLES: Record<TaskStatus, string> = {
  active: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40',
  paused: 'bg-amber-500/20 text-amber-300 border-amber-500/40',
  done: 'bg-slate-500/20 text-slate-400 border-slate-500/40',
};

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

export default function TaskList({
  tasks,
  onStatusChange,
  onDeleteTask,
  showDimension = true,
}: TaskListProps) {
  if (tasks.length === 0) {
    return <p className="text-sm text-slate-500">No tasks yet. Add your first one.</p>;
  }

  return (
    <ul className="space-y-2">
      {tasks.map((t) => (
        <li
          key={t.id}
          className="rounded-lg border border-slate-800 bg-slate-900/60 p-4"
        >
          <div className="flex flex-wrap items-start justify-between gap-2">
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <p className="font-medium text-slate-200">{t.title}</p>
                {showDimension && (
                  <span
                    className={`rounded-full border px-2 py-0.5 text-[11px] ${
                      t.dimension_name ? dimensionColor(t.dimension_name) : NO_DIMENSION_STYLE
                    }`}
                  >
                    {t.dimension_name ?? 'No dimension'}
                  </span>
                )}
              </div>
              {t.description && (
                <p className="mt-1 text-sm text-slate-500">{t.description}</p>
              )}
              <p className="mt-1 text-xs text-slate-600">Added {formatDate(t.created_at)}</p>
            </div>
            <div className="flex items-center gap-2">
              <select
                value={t.status}
                onChange={(e) => onStatusChange(t.id, e.target.value as TaskStatus)}
                className={`rounded-full border px-2 py-1 text-xs font-medium capitalize ${STATUS_STYLES[t.status]}`}
              >
                {STATUS_OPTIONS.map((s) => (
                  <option key={s} value={s} className="bg-slate-900 text-slate-200">
                    {s}
                  </option>
                ))}
              </select>
              {onDeleteTask && (
                <button
                  onClick={() => onDeleteTask(t.id)}
                  className="text-xs text-slate-500 hover:text-rose-400"
                  aria-label={`Delete ${t.title}`}
                >
                  Delete
                </button>
              )}
            </div>
          </div>
        </li>
      ))}
    </ul>
  );
}
