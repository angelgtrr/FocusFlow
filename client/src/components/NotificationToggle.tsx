import { useEffect, useState } from 'react';
import { enablePushNotifications, getPushPermissionState, type PushPermissionState } from '../push';

export default function NotificationToggle() {
  const [state, setState] = useState<PushPermissionState>('unsupported');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getPushPermissionState().then(setState);
  }, []);

  async function handleEnable() {
    setBusy(true);
    setError(null);
    try {
      await enablePushNotifications();
      setState('subscribed');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to enable notifications');
    } finally {
      setBusy(false);
    }
  }

  if (state === 'unsupported') return null;

  if (state === 'denied') {
    return <span className="text-xs text-slate-600">Notifications blocked</span>;
  }

  if (state === 'subscribed') {
    return <span className="text-xs text-slate-500">Notifications on</span>;
  }

  return (
    <div className="flex items-center gap-2">
      <button
        onClick={handleEnable}
        disabled={busy}
        className="text-xs text-slate-500 hover:text-slate-300 transition-colors disabled:opacity-50"
      >
        {busy ? 'Enabling...' : 'Enable notifications'}
      </button>
      {error && <span className="text-xs text-rose-400">{error}</span>}
    </div>
  );
}
