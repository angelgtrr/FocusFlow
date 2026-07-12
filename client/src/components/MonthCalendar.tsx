import { useEffect, useState } from 'react';
import { addDays, addMonths, buildMonthGrid, todayKey, toDateKey } from '../utils';

interface MonthCalendarProps {
  selectedDate: string;
  onSelect: (date: string) => void;
  activeDates: Set<string>;
}

const WEEKDAY_LABELS = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

export default function MonthCalendar({ selectedDate, onSelect, activeDates }: MonthCalendarProps) {
  const [viewMonth, setViewMonth] = useState(() => new Date(selectedDate));

  useEffect(() => {
    const selected = new Date(selectedDate);
    if (
      selected.getFullYear() !== viewMonth.getFullYear() ||
      selected.getMonth() !== viewMonth.getMonth()
    ) {
      setViewMonth(selected);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedDate]);

  const today = todayKey();
  const grid = buildMonthGrid(viewMonth);
  const monthLabel = viewMonth.toLocaleDateString(undefined, { month: 'long', year: 'numeric' });

  function stepDay(n: number) {
    onSelect(toDateKey(addDays(new Date(selectedDate), n)));
  }

  return (
    <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
      <div className="flex items-center justify-between gap-2">
        <button
          onClick={() => stepDay(-1)}
          className="rounded-lg border border-slate-700 px-2 py-1 text-xs text-slate-300 hover:bg-slate-800"
        >
          ← Day
        </button>
        <button
          onClick={() => onSelect(today)}
          className="rounded-lg border border-slate-700 px-2 py-1 text-xs text-slate-300 hover:bg-slate-800"
        >
          Today
        </button>
        <button
          onClick={() => stepDay(1)}
          disabled={selectedDate >= today}
          className="rounded-lg border border-slate-700 px-2 py-1 text-xs text-slate-300 hover:bg-slate-800 disabled:opacity-40 disabled:hover:bg-transparent"
        >
          Day →
        </button>
      </div>

      <div className="mt-3 flex items-center justify-between">
        <button
          onClick={() => setViewMonth(addMonths(viewMonth, -1))}
          aria-label="Previous month"
          className="flex h-7 w-7 items-center justify-center rounded-lg text-slate-400 hover:bg-slate-800 hover:text-slate-200"
        >
          ‹
        </button>
        <p className="text-sm font-medium text-slate-200">{monthLabel}</p>
        <button
          onClick={() => setViewMonth(addMonths(viewMonth, 1))}
          aria-label="Next month"
          className="flex h-7 w-7 items-center justify-center rounded-lg text-slate-400 hover:bg-slate-800 hover:text-slate-200"
        >
          ›
        </button>
      </div>

      <div className="mt-3 grid grid-cols-7 gap-1 text-center text-[11px] text-slate-500">
        {WEEKDAY_LABELS.map((label) => (
          <span key={label}>{label}</span>
        ))}
      </div>
      <div className="mt-1 grid grid-cols-7 gap-1">
        {grid.map((day) => {
          const isFuture = day.key > today;
          const isSelected = day.key === selectedDate;
          const isToday = day.key === today;
          return (
            <button
              key={day.key}
              onClick={() => onSelect(day.key)}
              disabled={isFuture}
              className={`relative h-8 rounded-lg text-xs transition disabled:cursor-not-allowed disabled:opacity-30 ${
                isSelected
                  ? 'bg-violet-600 text-white'
                  : day.inMonth
                    ? 'text-slate-200 hover:bg-slate-800'
                    : 'text-slate-600 hover:bg-slate-800/50'
              } ${isToday && !isSelected ? 'ring-1 ring-violet-500' : ''}`}
            >
              {day.date.getDate()}
              {activeDates.has(day.key) && !isSelected && (
                <span className="absolute bottom-1 left-1/2 h-1 w-1 -translate-x-1/2 rounded-full bg-emerald-400" />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}
