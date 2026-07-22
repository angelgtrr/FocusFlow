import { useEffect, useRef, useState } from 'react';
import { toDateKey, todayKey } from '../utils';

const TOP = 12;
const NECK = 80;
const BOTTOM = 148;
const LEFT = 15;
const RIGHT = 105;
const DAY_MINUTES = 24 * 60;

function computeProgress(): number {
  const now = new Date();
  const minutesSinceMidnight = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60;
  return Math.min(1, Math.max(0, minutesSinceMidnight / DAY_MINUTES));
}

function formatRemaining(progress: number): string {
  if (progress >= 1) return 'Day complete';
  const now = new Date();
  const endOfDay = new Date(now);
  endOfDay.setHours(24, 0, 0, 0);
  const diffMs = endOfDay.getTime() - now.getTime();
  const h = Math.floor(diffMs / 3_600_000);
  const m = Math.floor((diffMs % 3_600_000) / 60_000);
  return `${h}h ${m}m left today`;
}

// Builds a wavy horizontal strip closed far below `y` so it reads as a
// water body with a rippling surface once clipped to the bulb triangle.
function wavePath(y: number, xStart: number, xEnd: number, phase: number): string {
  const amplitude = 2.5;
  const wavelength = 18;
  const offset = phase * wavelength;
  let x = xStart - wavelength + (offset % wavelength);
  let d = `M${x},${y}`;
  let up = true;
  while (x < xEnd) {
    const nx = x + wavelength / 2;
    const cy = up ? y - amplitude : y + amplitude;
    d += ` Q${x + wavelength / 4},${cy} ${nx},${y}`;
    x = nx;
    up = !up;
  }
  d += ` L${xEnd},200 L${xStart},200 Z`;
  return d;
}

interface HourglassProgressProps {
  onDayRollover?: (previousDateKey: string, newDateKey: string) => void;
}

export default function HourglassProgress({ onDayRollover }: HourglassProgressProps) {
  const [progress, setProgress] = useState(computeProgress);
  const [phase, setPhase] = useState(0);
  const [flipped, setFlipped] = useState(false);
  const dateKeyRef = useRef(todayKey());

  useEffect(() => {
    const progressId = setInterval(() => {
      setProgress(computeProgress());
      const dateKey = toDateKey(new Date());
      if (dateKey !== dateKeyRef.current) {
        const previousDateKey = dateKeyRef.current;
        dateKeyRef.current = dateKey;
        setFlipped((f) => !f);
        onDayRollover?.(previousDateKey, dateKey);
      }
    }, 1000);
    return () => clearInterval(progressId);
  }, [onDayRollover]);

  useEffect(() => {
    let frame: number;
    const start = performance.now();
    const tick = (now: number) => {
      setPhase(((now - start) / 1600) % 1);
      frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, []);

  // Each bulb is a triangle, so cross-section width — and therefore drawn
  // area — scales with the square of the distance from the neck (apex).
  // A surface that moves linearly with `progress` would drain area fast
  // near the wide top and barely move near the narrow neck. To make the
  // drawn area (i.e. the volume the eye reads) drain at a constant rate,
  // the distance from the neck must scale with sqrt(1 - progress) instead.
  const bulbHeight = NECK - TOP; // == BOTTOM - NECK, bulbs are congruent
  const distanceFromNeck = bulbHeight * Math.sqrt(1 - progress);
  const topSurfaceY = NECK - distanceFromNeck;
  const bottomSurfaceY = NECK + distanceFromNeck;
  const streamBottom = Math.max(bottomSurfaceY, NECK - 2);
  const running = progress < 1 && streamBottom > NECK - 2;

  return (
    <div className="flex flex-col items-center gap-2">
      <svg
        viewBox="0 0 120 166"
        className="h-40 w-auto"
        role="img"
        aria-label="Progress through the day"
        style={{
          transform: flipped ? 'rotate(180deg)' : 'rotate(0deg)',
          transition: 'transform 1.1s cubic-bezier(0.65, 0, 0.35, 1)',
        }}
      >
        <defs>
          <linearGradient id="hg-water" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#38bdf8" />
            <stop offset="100%" stopColor="#0ea5e9" />
          </linearGradient>
          <clipPath id="hg-top-clip">
            <polygon points={`${LEFT},${TOP} ${RIGHT},${TOP} 60,${NECK}`} />
          </clipPath>
          <clipPath id="hg-bottom-clip">
            <polygon points={`${LEFT},${BOTTOM} ${RIGHT},${BOTTOM} 60,${NECK}`} />
          </clipPath>
        </defs>

        <rect x="8" y="4" width="104" height="6" rx="2" fill="#475569" />
        <rect x="8" y="156" width="104" height="6" rx="2" fill="#475569" />

        <g clipPath="url(#hg-top-clip)">
          <path d={wavePath(topSurfaceY, LEFT - 10, RIGHT + 10, phase)} fill="url(#hg-water)" opacity={0.9} />
        </g>

        <g clipPath="url(#hg-bottom-clip)">
          <path d={wavePath(bottomSurfaceY, LEFT - 10, RIGHT + 10, phase)} fill="url(#hg-water)" opacity={0.9} />
        </g>

        {running && (
          <line
            x1="60"
            y1={NECK - 2}
            x2="60"
            y2={streamBottom}
            stroke="#38bdf8"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeDasharray="4 4"
            className="hourglass-stream"
          />
        )}

        <path
          d={`M${LEFT},${TOP} L${RIGHT},${TOP} L60,${NECK} L${RIGHT},${BOTTOM} L${LEFT},${BOTTOM} L60,${NECK} Z`}
          fill="none"
          stroke="#94a3b8"
          strokeWidth="2"
          strokeLinejoin="round"
        />
      </svg>
      <p className="text-xs text-slate-400">{formatRemaining(progress)}</p>
    </div>
  );
}
