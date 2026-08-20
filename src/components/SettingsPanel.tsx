import { useState } from 'react';
import { GearConfig, REAR_SPROCKET_OPTIONS, DEFAULT_CONFIG } from '../lib/speed';
import { ConnectionStatus } from '../lib/client';

interface SettingsPanelProps {
  config: GearConfig;
  onChange: (cfg: GearConfig) => void;
  wsUrl: string;
  status: ConnectionStatus;
  onConnect: (url: string) => void;
  onDisconnect: () => void;
}

export function SettingsPanel({
  config,
  onChange,
  wsUrl,
  status,
  onConnect,
  onDisconnect,
}: SettingsPanelProps) {
  const [localUrl, setLocalUrl] = useState(wsUrl);

  function set<K extends keyof GearConfig>(key: K, raw: string) {
    const value = parseFloat(raw);
    if (!Number.isNaN(value) && value > 0) {
      onChange({ ...config, [key]: value });
    }
  }

  return (
      <details className="settings-panel">
      <summary aria-label="Ustawienia"><span aria-hidden="true">⚙</span> Ustawienia</summary>

      <div className="settings-grid">
        <h3>Połączenie VESC</h3>
        <label>
          WebSocket URL
          <input
            type="text"
            value={localUrl}
            onChange={(e) => setLocalUrl(e.target.value)}
          />
        </label>
        <div className="settings-actions">
          <button onClick={() => onConnect(localUrl)} disabled={status === 'connected'}>
            Połącz
          </button>
          <button onClick={onDisconnect} disabled={status === 'disconnected'}>
            Rozłącz
          </button>
        </div>

        <h3>Napęd BBS02B</h3>
        <label>
          Liczba par biegunów (VESC pole pairs)
          <input
            type="number"
            min="1"
            max="20"
            value={config.polePairs}
            onChange={(e) => set('polePairs', e.target.value)}
          />
        </label>
        <label>
          Przełożenie wewnętrzne silnika (1:x)
          <input
            type="number"
            min="1"
            step="0.1"
            value={config.motorGearRatio}
            onChange={(e) => set('motorGearRatio', e.target.value)}
          />
        </label>

        <h3>Przekładnia rowerowa</h3>
        <label>
          Zębatka przednia (zęby)
          <input
            type="number"
            min="1"
            value={config.frontTeeth}
            onChange={(e) => set('frontTeeth', e.target.value)}
          />
        </label>
        <label>
          Kaseta tylna – aktywna zębatka
          <select
            value={config.rearTeeth}
            onChange={(e) => set('rearTeeth', e.target.value)}
          >
            {REAR_SPROCKET_OPTIONS.map((t) => (
              <option key={t} value={t}>
                {t}T
              </option>
            ))}
          </select>
        </label>
        <label>
          Obwód koła (m)
          <input
            type="number"
            min="0.1"
            step="0.001"
            value={config.wheelCircumferenceM}
            onChange={(e) => set('wheelCircumferenceM', e.target.value)}
          />
        </label>

        <button
          className="reset-btn"
          onClick={() => onChange(DEFAULT_CONFIG)}
        >
          Przywróć domyślne
        </button>
      </div>
    </details>
  );
}
