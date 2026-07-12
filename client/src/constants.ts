export const SCORE_COLORS: Record<number, string> = {
  0: 'bg-slate-800',
  1: 'bg-rose-900',
  2: 'bg-amber-700',
  3: 'bg-emerald-700',
  4: 'bg-emerald-400',
};

export const SCORE_RING_COLORS: Record<number, string> = {
  0: 'ring-slate-600',
  1: 'ring-rose-500',
  2: 'ring-amber-500',
  3: 'ring-emerald-500',
  4: 'ring-emerald-300',
};

const DIMENSION_PALETTE = [
  'bg-violet-500/20 text-violet-300 border-violet-500/40',
  'bg-sky-500/20 text-sky-300 border-sky-500/40',
  'bg-amber-500/20 text-amber-300 border-amber-500/40',
  'bg-emerald-500/20 text-emerald-300 border-emerald-500/40',
  'bg-rose-500/20 text-rose-300 border-rose-500/40',
  'bg-fuchsia-500/20 text-fuchsia-300 border-fuchsia-500/40',
  'bg-cyan-500/20 text-cyan-300 border-cyan-500/40',
  'bg-orange-500/20 text-orange-300 border-orange-500/40',
];

export function dimensionColor(dimension: string): string {
  let hash = 0;
  for (let i = 0; i < dimension.length; i++) {
    hash = (hash * 31 + dimension.charCodeAt(i)) >>> 0;
  }
  return DIMENSION_PALETTE[hash % DIMENSION_PALETTE.length];
}
