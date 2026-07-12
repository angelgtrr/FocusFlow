import { useEffect, useState } from 'react';

interface DayNoteEditorProps {
  date: string;
  note: string;
  onSave: (date: string, note: string) => Promise<void>;
}

export default function DayNoteEditor({ date, note, onSave }: DayNoteEditorProps) {
  const [value, setValue] = useState(note);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    setValue(note);
    setSaved(false);
  }, [date, note]);

  async function handleSave() {
    setSaving(true);
    setSaved(false);
    try {
      await onSave(date, value);
      setSaved(true);
    } finally {
      setSaving(false);
    }
  }

  const dirty = value !== note;

  return (
    <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
      <textarea
        value={value}
        onChange={(e) => {
          setValue(e.target.value);
          setSaved(false);
        }}
        rows={3}
        placeholder="Anything worth remembering about this day?"
        className="w-full rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-600"
      />
      <div className="mt-2 flex items-center gap-3">
        <button
          onClick={handleSave}
          disabled={saving || !dirty}
          className="rounded-lg bg-violet-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-violet-500 disabled:opacity-50"
        >
          {saving ? 'Saving...' : 'Save note'}
        </button>
        {saved && !dirty && <span className="text-xs text-emerald-400">Saved</span>}
      </div>
    </div>
  );
}
