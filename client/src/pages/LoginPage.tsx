import { useState } from 'react';
import { api } from '../api';

interface LoginPageProps {
  onSuccess: () => void;
}

export default function LoginPage({ onSuccess }: LoginPageProps) {
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await api.login(password);
      onSuccess();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-950">
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-sm rounded-lg border border-slate-800 bg-slate-900 p-8"
      >
        <p className="text-sm text-violet-400 font-medium">FocusFlow</p>
        <h1 className="text-xl font-semibold text-slate-100 mt-1">Enter password</h1>
        <input
          type="password"
          autoFocus
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="mt-6 w-full rounded-md border border-slate-700 bg-slate-950 px-3 py-2 text-slate-100 focus:outline-none focus:ring-2 focus:ring-violet-500"
          placeholder="Password"
        />
        {error && <p className="mt-3 text-sm text-rose-400">{error}</p>}
        <button
          type="submit"
          disabled={submitting || !password}
          className="mt-4 w-full rounded-md bg-violet-600 px-4 py-2 text-sm font-medium text-white hover:bg-violet-500 disabled:opacity-50"
        >
          {submitting ? 'Checking…' : 'Log in'}
        </button>
      </form>
    </div>
  );
}
