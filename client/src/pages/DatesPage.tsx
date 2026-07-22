import type { RecurringType, SavedDate } from '../types';
import DateForm from '../components/DateForm';
import DateList from '../components/DateList';

interface DatesPageProps {
  dates: SavedDate[];
  onCreate: (data: { title: string; note: string; date: string; recurring: RecurringType }) => Promise<void>;
  onUpdate: (id: number, data: { title: string; note: string; date: string; recurring: RecurringType }) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
}

export default function DatesPage({ dates, onCreate, onUpdate, onDelete }: DatesPageProps) {
  return (
    <div className="mx-auto max-w-5xl px-6 py-6 grid gap-6 md:grid-cols-[minmax(0,1fr)_320px]">
      <section className="space-y-3">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-400">Dates</h2>
        <DateList dates={dates} onUpdate={onUpdate} onDelete={onDelete} />
      </section>
      <section>
        <DateForm onSubmit={onCreate} />
      </section>
    </div>
  );
}
