import { useEffect, useState } from 'react';

interface DayNoteEditorProps {
  date: string;
  note: string;
  onSave: (date: string, note: string) => Promise<void>;
}

export default function DayNoteEditor({ date, note, onSave }: DayNoteEditorProps) {
  const [editing, setEditing] = useState(false);
  const [value, setValue] = useState(note);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    setValue(note);
    setSaved(false);
    setEditing(false);
  }, [date, note]);

  async function handleSave() {
    setSaving(true);
    setSaved(false);
    try {
      await onSave(date, value);
      setSaved(true);
      setEditing(false);
    } finally {
      setSaving(false);
    }
  }

  function handleCancel() {
    setValue(note);
    setEditing(false);
  }

  const dirty = value !== note;

  if (!editing) {
    return (
      <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
        <div className="flex items-start justify-between gap-3">
          {note ? (
            <p className="whitespace-pre-wrap text-sm text-slate-100">{note}</p>
          ) : (
            <p className="text-sm text-slate-600">Anything worth remembering about this day?</p>
          )}
          <button
            onClick={() => setEditing(true)}
            aria-label="Edit day note"
            className="shrink-0 rounded-lg p-1.5 text-slate-400 hover:bg-slate-800 hover:text-slate-100"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" className="h-4 w-4">
              <path d="M12 20h9" />
              <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4Z" />
            </svg>
          </button>
        </div>
        {saved && <span className="mt-2 inline-block text-xs text-emerald-400">Saved</span>}
      </div>
    );
  }

  return (
    <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
      <textarea
        autoFocus
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
        <button
          onClick={handleCancel}
          disabled={saving}
          className="rounded-lg px-3 py-1.5 text-sm font-medium text-slate-400 hover:text-slate-100 disabled:opacity-50"
        >
          Cancel
        </button>
      </div>
    </div>
  );
}
