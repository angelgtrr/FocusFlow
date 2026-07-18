import NotificationToggle from './NotificationToggle';

interface HeaderProps {
  tab: 'daily' | 'dimensions' | 'tasks' | 'dates';
  onTabChange: (tab: 'daily' | 'dimensions' | 'tasks' | 'dates') => void;
  onLogout: () => void;
}

function todayLabel(): string {
  return new Date().toLocaleDateString(undefined, {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
  });
}

export default function Header({ tab, onTabChange, onLogout }: HeaderProps) {
  return (
    <header className="border-b border-slate-800">
      <div className="mx-auto max-w-5xl px-6 pt-8 pb-4">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-violet-400 font-medium">FocusFlow</p>
            <h1 className="text-2xl font-semibold text-slate-100">
              Welcome back, Angel!
            </h1>
            <p className="text-sm text-slate-500 mt-1">{todayLabel()}</p>
          </div>
          <div className="flex items-center gap-4">
            <NotificationToggle />
            <button
              onClick={onLogout}
              className="text-sm text-slate-500 hover:text-slate-300 transition-colors"
            >
              Log out
            </button>
          </div>
        </div>
        <nav className="mt-6 flex gap-1">
          <button
            onClick={() => onTabChange('daily')}
            className={`px-4 py-2 text-sm font-medium rounded-t-lg border-b-2 transition-colors ${
              tab === 'daily'
                ? 'border-violet-500 text-violet-300'
                : 'border-transparent text-slate-400 hover:text-slate-200'
            }`}
          >
            Daily
          </button>
          <button
            onClick={() => onTabChange('dimensions')}
            className={`px-4 py-2 text-sm font-medium rounded-t-lg border-b-2 transition-colors ${
              tab === 'dimensions'
                ? 'border-violet-500 text-violet-300'
                : 'border-transparent text-slate-400 hover:text-slate-200'
            }`}
          >
            Dimensions
          </button>
          <button
            onClick={() => onTabChange('tasks')}
            className={`px-4 py-2 text-sm font-medium rounded-t-lg border-b-2 transition-colors ${
              tab === 'tasks'
                ? 'border-violet-500 text-violet-300'
                : 'border-transparent text-slate-400 hover:text-slate-200'
            }`}
          >
            Tasks
          </button>
          <button
            onClick={() => onTabChange('dates')}
            className={`px-4 py-2 text-sm font-medium rounded-t-lg border-b-2 transition-colors ${
              tab === 'dates'
                ? 'border-violet-500 text-violet-300'
                : 'border-transparent text-slate-400 hover:text-slate-200'
            }`}
          >
            Dates
          </button>
        </nav>
      </div>
    </header>
  );
}
