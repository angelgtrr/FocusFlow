import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import type { TrendPoint } from '../utils';

interface TrendChartProps {
  data: TrendPoint[];
}

export default function TrendChart({ data }: TrendChartProps) {
  return (
    <ResponsiveContainer width="100%" height={220}>
      <LineChart data={data} margin={{ top: 8, right: 12, left: -20, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
        <XAxis
          dataKey="date"
          tick={{ fill: '#64748b', fontSize: 11 }}
          tickFormatter={(v: string) => v.slice(5)}
          minTickGap={20}
        />
        <YAxis
          domain={[0, 4]}
          ticks={[0, 1, 2, 3, 4]}
          tick={{ fill: '#64748b', fontSize: 11 }}
        />
        <Tooltip
          contentStyle={{ background: '#0f172a', border: '1px solid #334155', borderRadius: 8 }}
          labelStyle={{ color: '#cbd5e1' }}
        />
        <Line
          type="monotone"
          dataKey="avgScore"
          stroke="#a78bfa"
          strokeWidth={2}
          dot={false}
          activeDot={{ r: 4 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
