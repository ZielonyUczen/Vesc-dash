import { useState, useCallback, useEffect, useRef } from 'react';
import { VescClient, ConnectionStatus } from '../lib/client';
import { VescTelemetry, INITIAL_TELEMETRY } from '../lib/vesc';

interface UseVescOptions {
  url?: string;
  autoConnect?: boolean;
}

export function useVesc(options: UseVescOptions = {}) {
  const [telemetry, setTelemetry] = useState<VescTelemetry>(INITIAL_TELEMETRY);
  const [status, setStatus] = useState<ConnectionStatus>('disconnected');
  const [wsUrl, setWsUrl] = useState(options.url ?? 'ws://localhost:8765');
  const clientRef = useRef<VescClient | null>(null);

  const connect = useCallback(
    (url?: string) => {
      const target = url ?? wsUrl;
      if (url) setWsUrl(url);
      clientRef.current?.disconnect();
      clientRef.current = new VescClient(setTelemetry, setStatus, target);
      clientRef.current.connect();
    },
    [wsUrl],
  );

  const disconnect = useCallback(() => {
    clientRef.current?.disconnect();
  }, []);

  useEffect(() => {
    if (options.autoConnect) connect();
    return () => {
      clientRef.current?.disconnect();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return { telemetry, status, wsUrl, setWsUrl, connect, disconnect };
}
