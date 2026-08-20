/**
 * VESC WebSocket / Serial bridge client.
 *
 * The dashboard expects a lightweight bridge server (e.g. vesc-express or a
 * custom Node.js serial-to-WebSocket proxy) that forwards VESC RT data as
 * JSON over WebSocket. Message format:
 *
 *   { type: "rt_data", payload: VescTelemetry }
 *
 * The bridge URL defaults to ws://localhost:8765 but can be overridden via
 * the VITE_VESC_WS_URL environment variable at build time or the in-app
 * settings panel at runtime.
 */

import { VescTelemetry } from './vesc';

export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

export type TelemetryCallback = (data: VescTelemetry) => void;
export type StatusCallback = (status: ConnectionStatus) => void;

const DEFAULT_WS_URL = import.meta.env.VITE_VESC_WS_URL ?? 'ws://localhost:8765';

export class VescClient {
  private ws: WebSocket | null = null;
  private url: string;
  private onTelemetry: TelemetryCallback;
  private onStatus: StatusCallback;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private shouldReconnect = false;

  constructor(
    onTelemetry: TelemetryCallback,
    onStatus: StatusCallback,
    url: string = DEFAULT_WS_URL,
  ) {
    this.onTelemetry = onTelemetry;
    this.onStatus = onStatus;
    this.url = url;
  }

  connect(url?: string): void {
    if (url) this.url = url;
    this.shouldReconnect = true;
    this._open();
  }

  disconnect(): void {
    this.shouldReconnect = false;
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    if (this.ws) {
      // Nullify callbacks before closing so a racing `onclose` does not
      // overwrite a subsequent new connection's status.
      this.ws.onopen = null;
      this.ws.onmessage = null;
      this.ws.onerror = null;
      this.ws.onclose = null;
      this.ws.close();
      this.ws = null;
    }
    this.onStatus('disconnected');
  }

  private _open(): void {
    this.onStatus('connecting');
    try {
      this.ws = new WebSocket(this.url);
    } catch {
      this.onStatus('error');
      this._scheduleReconnect();
      return;
    }

    this.ws.onopen = () => {
      this.onStatus('connected');
    };

    this.ws.onmessage = (event: MessageEvent) => {
      try {
        const msg = JSON.parse(event.data as string) as {
          type: string;
          payload: VescTelemetry;
        };
        if (msg.type === 'rt_data') {
          this.onTelemetry({ ...msg.payload, timestamp: Date.now() });
        }
      } catch {
        // malformed message — ignore
      }
    };

    this.ws.onerror = () => {
      this.onStatus('error');
    };

    this.ws.onclose = () => {
      this.onStatus('disconnected');
      if (this.shouldReconnect) this._scheduleReconnect();
    };
  }

  private _scheduleReconnect(): void {
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    this.reconnectTimer = setTimeout(() => {
      if (this.shouldReconnect) this._open();
    }, 3000);
  }
}
