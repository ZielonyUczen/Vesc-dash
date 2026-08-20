import { useState } from 'react';
import { useVesc } from '../hooks/useVesc';
import { DEFAULT_CONFIG, erpmToSpeedKmh, GearConfig } from '../lib/speed';
import { calcPowerW, FAULT_CODES } from '../lib/vesc';
import { Gauge } from './Gauge';
import { StatCard } from './StatCard';
import { ConnectionBadge } from './ConnectionBadge';
import { SettingsPanel } from './SettingsPanel';

export function Dashboard() {
  const [config, setConfig] = useState<GearConfig>(DEFAULT_CONFIG);
  const { telemetry, status, wsUrl, connect, disconnect } = useVesc();

  const speed = erpmToSpeedKmh(Math.abs(telemetry.erpm), config);
  const power = calcPowerW(telemetry);
  const faultLabel = FAULT_CODES[telemetry.faultCode] ?? `Kod ${telemetry.faultCode}`;
  const hasFault = telemetry.faultCode !== 0;

  return (
    <div className="dashboard">
      <header className="dash-header">
        <h1>VESC Dash <span className="dash-subtitle">Marketbase 75200 V2 · BBS02B</span></h1>
        <ConnectionBadge status={status} />
      </header>

      {hasFault && (
        <div className="fault-banner" role="alert">
          ⚠ Błąd VESC: {faultLabel}
        </div>
      )}

      {/* Speed — prominent centre gauge */}
      <div className="speed-wrap">
        <Gauge
          value={speed}
          max={60}
          label="Prędkość"
          unit="km/h"
          color="#00d4ff"
          decimals={1}
        />
      </div>

      {/* Secondary gauges */}
      <div className="gauge-row">
        <Gauge
          value={telemetry.voltageInput}
          max={60}
          label="Napięcie"
          unit="V"
          color="#ffd700"
          decimals={1}
        />
        <Gauge
          value={Math.abs(telemetry.currentMotor)}
          max={100}
          label="Prąd silnika"
          unit="A"
          color="#ff6b35"
          decimals={1}
        />
        <Gauge
          value={power / 1000}
          max={3}
          label="Moc"
          unit="kW"
          color="#00e676"
          decimals={2}
        />
        <Gauge
          value={telemetry.dutyCycle}
          max={100}
          label="Duty cycle"
          unit="%"
          color="#aa80ff"
          decimals={0}
        />
      </div>

      {/* Stat cards */}
      <div className="stats-row">
        <StatCard label="eRPM" value={Math.abs(telemetry.erpm).toFixed(0)} />
        <StatCard label="Prąd baterii" value={telemetry.currentInput} unit="A" />
        <StatCard label="Zużycie" value={telemetry.wattHours} unit="Wh" />
        <StatCard label="Pojemność" value={telemetry.ampHours} unit="Ah" />
        <StatCard
          label="Temp. MOSFET"
          value={telemetry.tempMosfet}
          unit="°C"
          warning={telemetry.tempMosfet > 70}
        />
        <StatCard
          label="Temp. silnika"
          value={telemetry.tempMotor}
          unit="°C"
          warning={telemetry.tempMotor > 80}
        />
      </div>

      <SettingsPanel
        config={config}
        onChange={setConfig}
        wsUrl={wsUrl}
        status={status}
        onConnect={connect}
        onDisconnect={disconnect}
      />
    </div>
  );
}
