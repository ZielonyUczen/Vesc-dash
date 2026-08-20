import { ConnectionStatus } from '../lib/client';

interface ConnectionBadgeProps {
  status: ConnectionStatus;
}

const STATUS_LABELS: Record<ConnectionStatus, string> = {
  disconnected: 'Rozłączono',
  connecting: 'Łączenie…',
  connected: 'Połączono',
  error: 'Błąd połączenia',
};

const STATUS_COLORS: Record<ConnectionStatus, string> = {
  disconnected: '#888',
  connecting: '#f0a500',
  connected: '#00c853',
  error: '#f44336',
};

export function ConnectionBadge({ status }: ConnectionBadgeProps) {
  return (
    <span
      className="connection-badge"
      style={{ background: STATUS_COLORS[status] }}
    >
      {STATUS_LABELS[status]}
    </span>
  );
}
