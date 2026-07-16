export const SCORE_COLORS: Record<number, string> = {
  0: 'bg-slate-800',
  1: 'bg-rose-900',
  2: 'bg-amber-700',
  3: 'bg-emerald-700',
  4: 'bg-emerald-400',
};

// RGB stops matching SCORE_COLORS, used to interpolate smooth in-between
// shades for fractional average scores (e.g. multiple dimensions/day).
const SCORE_COLOR_STOPS: [number, number, number][] = [
  [30, 41, 59], // slate-800
  [136, 19, 55], // rose-900
  [180, 83, 9], // amber-700
  [4, 120, 87], // emerald-700
  [52, 211, 153], // emerald-400
];

const NO_ENTRY_COLOR = 'rgb(15, 23, 42)'; // slate-900

export function scoreColorForAvg(avgScore: number | null): string {
  if (avgScore === null) return NO_ENTRY_COLOR;
  const clamped = Math.min(4, Math.max(0, avgScore));
  const lower = Math.floor(clamped);
  const upper = Math.min(4, lower + 1);
  const t = clamped - lower;
  const [r1, g1, b1] = SCORE_COLOR_STOPS[lower];
  const [r2, g2, b2] = SCORE_COLOR_STOPS[upper];
  const r = Math.round(r1 + (r2 - r1) * t);
  const g = Math.round(g1 + (g2 - g1) * t);
  const b = Math.round(b1 + (b2 - b1) * t);
  return `rgb(${r}, ${g}, ${b})`;
}

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

export const NO_DIMENSION_STYLE = 'bg-slate-800/50 text-slate-500 border-slate-700';

export function dimensionColor(dimension: string): string {
  let hash = 0;
  for (let i = 0; i < dimension.length; i++) {
    hash = (hash * 31 + dimension.charCodeAt(i)) >>> 0;
  }
  return DIMENSION_PALETTE[hash % DIMENSION_PALETTE.length];
}
