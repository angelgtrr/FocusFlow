import { useMemo } from 'react';
import type { Goal, GoalStatus } from '../types';
import GoalForm from '../components/GoalForm';
import GoalList from '../components/GoalList';
import { dimensionsFromGoals } from '../utils';

interface AdminGoalsPageProps {
  goals: Goal[];
  onCreateGoal: (data: { title: string; description: string; dimension: string }) => Promise<void>;
  onStatusChange: (id: number, status: GoalStatus) => Promise<void>;
}

export default function AdminGoalsPage({
  goals,
  onCreateGoal,
  onStatusChange,
}: AdminGoalsPageProps) {
  const existingDimensions = useMemo(() => dimensionsFromGoals(goals), [goals]);
  const sortedGoals = useMemo(
    () =>
      [...goals].sort((a, b) => {
        const order: Record<GoalStatus, number> = { active: 0, paused: 1, done: 2 };
        return order[a.status] - order[b.status];
      }),
    [goals]
  );

  return (
    <div className="mx-auto max-w-5xl px-6 py-6 grid gap-6 md:grid-cols-[minmax(0,1fr)_320px]">
      <section>
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400 mb-3">
          Goals
        </h2>
        <GoalList goals={sortedGoals} onStatusChange={onStatusChange} />
      </section>
      <section>
        <GoalForm existingDimensions={existingDimensions} onSubmit={onCreateGoal} />
      </section>
    </div>
  );
}
