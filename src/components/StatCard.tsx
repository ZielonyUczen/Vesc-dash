interface StatCardProps {
  label: string;
  value: string | number;
  unit?: string;
  warning?: boolean;
}

export function StatCard({ label, value, unit, warning }: StatCardProps) {
  return (
    <div className={`stat-card${warning ? ' stat-card--warning' : ''}`}>
      <div className="stat-label">{label}</div>
      <div className="stat-value">
        {typeof value === 'number' ? value.toFixed(1) : value}
        {unit && <span className="stat-unit"> {unit}</span>}
      </div>
    </div>
  );
}
