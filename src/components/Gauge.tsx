interface GaugeProps {
  value: number;
  max: number;
  label: string;
  unit: string;
  color?: string;
  decimals?: number;
}

export function Gauge({ value, max, label, unit, color = '#00d4ff', decimals = 1 }: GaugeProps) {
  const pct = Math.min(100, Math.max(0, (value / max) * 100));
  const radius = 54;
  const circumference = 2 * Math.PI * radius;
  // Arc covers 270° (from 135° to 405°)
  const arcLength = (circumference * 270) / 360;
  const dashOffset = arcLength - (arcLength * pct) / 100;

  return (
    <div className="gauge-card">
      <svg viewBox="0 0 120 120" className="gauge-svg">
        {/* Background arc */}
        <circle
          cx="60"
          cy="60"
          r={radius}
          fill="none"
          stroke="#1e2a3a"
          strokeWidth="10"
          strokeDasharray={`${arcLength} ${circumference}`}
          strokeDashoffset="0"
          strokeLinecap="round"
          transform="rotate(135 60 60)"
        />
        {/* Value arc */}
        <circle
          cx="60"
          cy="60"
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth="10"
          strokeDasharray={`${arcLength} ${circumference}`}
          strokeDashoffset={dashOffset}
          strokeLinecap="round"
          transform="rotate(135 60 60)"
          style={{ transition: 'stroke-dashoffset 0.4s ease' }}
        />
        <text x="60" y="58" textAnchor="middle" className="gauge-value" fill="white">
          {value.toFixed(decimals)}
        </text>
        <text x="60" y="72" textAnchor="middle" className="gauge-unit" fill="#8899aa">
          {unit}
        </text>
      </svg>
      <div className="gauge-label">{label}</div>
    </div>
  );
}
