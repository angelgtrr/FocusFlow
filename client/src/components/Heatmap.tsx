import { SCORE_COLORS } from '../constants';
import type { HeatmapDay } from '../utils';

interface HeatmapProps {
  days: HeatmapDay[];
}

function scoreColor(avgScore: number | null): string {
  if (avgScore === null) return 'bg-slate-900';
  const bucket = Math.min(4, Math.max(0, Math.round(avgScore)));
  return SCORE_COLORS[bucket];
}

export default function Heatmap({ days }: HeatmapProps) {
  const weeks: HeatmapDay[][] = [];
  for (let i = 0; i < days.length; i += 7) {
    weeks.push(days.slice(i, i + 7));
  }

  return (
    <div className="overflow-x-auto">
      <div className="flex gap-1">
        {weeks.map((week, wi) => (
          <div key={wi} className="flex flex-col gap-1">
            {week.map((day) => (
              <div
                key={day.date}
                title={`${day.date}: ${day.avgScore === null ? 'no entry' : day.avgScore.toFixed(1)}`}
                className={`h-3.5 w-3.5 rounded-sm ${scoreColor(day.avgScore)}`}
              />
            ))}
          </div>
        ))}
      </div>
      <div className="mt-2 flex items-center gap-1 text-xs text-slate-500">
        <span>Less</span>
        {[0, 1, 2, 3, 4].map((s) => (
          <span key={s} className={`h-3 w-3 rounded-sm ${SCORE_COLORS[s]}`} />
        ))}
        <span>More</span>
      </div>
    </div>
  );
}
