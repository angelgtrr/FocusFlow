import type { Task } from '../types';
import { dimensionColor, NO_DIMENSION_STYLE } from '../constants';

interface TaskChecklistProps {
  tasks: Task[];
  completedTaskIds: Set<number>;
  onToggle: (taskId: number, completed: boolean) => Promise<void>;
}

export default function TaskChecklist({ tasks, completedTaskIds, onToggle }: TaskChecklistProps) {
  if (tasks.length === 0) {
    return (
      <p className="text-sm text-slate-500">
        No active tasks. Head to <span className="text-violet-400">Tasks</span> to create one.
      </p>
    );
  }

  return (
    <ul className="space-y-2">
      {tasks.map((t) => {
        const completed = completedTaskIds.has(t.id);
        return (
          <li
            key={t.id}
            className="flex items-center gap-3 rounded-lg border border-slate-800 bg-slate-900/60 p-3"
          >
            <input
              type="checkbox"
              checked={completed}
              onChange={() => onToggle(t.id, !completed)}
              className="h-4 w-4 flex-shrink-0 rounded border-slate-600 bg-slate-800 text-violet-600 focus:ring-violet-500"
              aria-label={`Mark ${t.title} as ${completed ? 'not completed' : 'completed'}`}
            />
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <p className={`font-medium ${completed ? 'text-slate-500 line-through' : 'text-slate-200'}`}>
                  {t.title}
                </p>
                <span
                  className={`rounded-full border px-2 py-0.5 text-[11px] ${
                    t.dimension_name ? dimensionColor(t.dimension_name) : NO_DIMENSION_STYLE
                  }`}
                >
                  {t.dimension_name ?? 'No dimension'}
                </span>
              </div>
            </div>
          </li>
        );
      })}
    </ul>
  );
}
