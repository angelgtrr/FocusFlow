interface StatsBarProps {
  activeGoals: number;
  weeklyProgressPct: number;
  streak: number;
  loggedToday: number;
}

function StatCard({ label, value, sub }: { label: string; value: string; sub?: string }) {
  return (
    <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
      <p className="text-xs uppercase tracking-wide text-slate-500">{label}</p>
      <p className="mt-1 text-2xl font-semibold text-slate-100">{value}</p>
      {sub && <p className="text-xs text-slate-500 mt-0.5">{sub}</p>}
    </div>
  );
}

export default function StatsBar({
  activeGoals,
  weeklyProgressPct,
  streak,
  loggedToday,
}: StatsBarProps) {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
      <StatCard label="Active Goals" value={String(activeGoals)} />
      <StatCard label="This Week" value={`${weeklyProgressPct}%`} sub="of max possible progress" />
      <StatCard
        label="Current Streak"
        value={`${streak} ${streak === 1 ? 'day' : 'days'}`}
        sub={streak > 0 ? 'keep it going' : 'log today to start one'}
      />
      <StatCard label="Logged Today" value={`${loggedToday}/${activeGoals}`} sub="goals checked in" />
    </div>
  );
}
