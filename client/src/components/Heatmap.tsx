import { scoreColorForAvg } from '../constants';
import type { HeatmapDay } from '../utils';

interface HeatmapProps {
  days: HeatmapDay[];
}

const LEGEND_STEPS = 9;

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
                className="h-3.5 w-3.5 rounded-sm"
                style={{ backgroundColor: scoreColorForAvg(day.avgScore) }}
              />
            ))}
          </div>
        ))}
      </div>
      <div className="mt-2 flex items-center gap-1 text-xs text-slate-500">
        <span>Less</span>
        {Array.from({ length: LEGEND_STEPS }, (_, i) => (4 * i) / (LEGEND_STEPS - 1)).map((s) => (
          <span
            key={s}
            className="h-3 w-3 rounded-sm"
            style={{ backgroundColor: scoreColorForAvg(s) }}
          />
        ))}
        <span>More</span>
      </div>
    </div>
  );
}
