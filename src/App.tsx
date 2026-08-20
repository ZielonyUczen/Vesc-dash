import type { CSSProperties, ReactNode } from 'react'

import './App.css'

type MetricCardProps = {
  className?: string
  icon: ReactNode
  label: string
  unit: string
  value: string
}

type NavItemProps = {
  active?: boolean
  icon: ReactNode
  label: string
}

const gearStats = [
  { gear: 1, maxSpeed: 25, maxErpm: '3 200', minVoltage: 71.2, maxBatteryCurrent: 80.5, maxMotorCurrent: 75.0 },
  { gear: 2, maxSpeed: 35, maxErpm: '4 500', minVoltage: 71.0, maxBatteryCurrent: 82.1, maxMotorCurrent: 77.3 },
  { gear: 3, maxSpeed: 45, maxErpm: '5 800', minVoltage: 70.8, maxBatteryCurrent: 85.3, maxMotorCurrent: 80.5 },
  { gear: 4, maxSpeed: 55, maxErpm: '7 200', minVoltage: 70.6, maxBatteryCurrent: 87.7, maxMotorCurrent: 82.9 },
  { gear: 5, maxSpeed: 65, maxErpm: '8 700', minVoltage: 70.3, maxBatteryCurrent: 90.2, maxMotorCurrent: 85.6 },
  { gear: 6, maxSpeed: 75, maxErpm: '10 100', minVoltage: 70.1, maxBatteryCurrent: 92.4, maxMotorCurrent: 87.8 },
  { gear: 7, maxSpeed: 85, maxErpm: '11 600', minVoltage: 69.9, maxBatteryCurrent: 94.8, maxMotorCurrent: 90.1 },
  { gear: 8, maxSpeed: 95, maxErpm: '13 200', minVoltage: 69.6, maxBatteryCurrent: 96.6, maxMotorCurrent: 91.8 },
  { gear: 9, maxSpeed: 105, maxErpm: '14 800', minVoltage: 69.4, maxBatteryCurrent: 98.3, maxMotorCurrent: 93.5 },
  { gear: 10, maxSpeed: 115, maxErpm: '16 500', minVoltage: 69.1, maxBatteryCurrent: 100.0, maxMotorCurrent: 95.0 },
]

function App() {
  return (
    <main className="app-shell">
      <section className="screens-grid">
        <DashboardScreen />
        <StatsScreen />
      </section>
    </main>
  )
}

function DashboardScreen() {
  return (
    <PhoneFrame>
      <StatusBar />

      <section className="dashboard-hero">
        <div className="erpm-panel">
          <span className="panel-label">eRPM</span>
          <strong>12 450</strong>
          <span className="panel-unit">ERPM</span>
        </div>

        <div className="speed-panel">
          <SpeedGauge value={85} max={120} />
        </div>
      </section>

      <section className="gear-controls" aria-label="Gear controls">
        <button type="button" className="gear-button" aria-label="Decrease gear">
          <span className="gear-symbol">–</span>
          <span>BIEG</span>
        </button>

        <div className="gear-indicator" aria-label="Current gear">
          <span className="gear-current">5</span>
          <span className="gear-divider">/</span>
          <span className="gear-total">10</span>
        </div>

        <button type="button" className="gear-button" aria-label="Increase gear">
          <span className="gear-symbol">+</span>
          <span>BIEG</span>
        </button>
      </section>

      <section className="metrics-grid">
        <MetricCard
          className="span-2"
          icon={<BatteryIcon />}
          label="NAPIĘCIE BATERII"
          value="72.6"
          unit="V"
        />
        <MetricCard
          className="span-2"
          icon={<BoltIcon />}
          label="MOC WEJŚCIOWA"
          value="5.23"
          unit="kW"
        />
        <MetricCard
          className="span-2 row-end"
          icon={<BatteryPowerIcon />}
          label="PRĄD BATERII"
          value="72.4"
          unit="A"
        />
        <MetricCard
          className="span-3"
          icon={<MotorIcon />}
          label="PRĄD SILNIKA"
          value="68.7"
          unit="A"
        />
        <MetricCard
          className="span-3 row-end"
          icon={<DutyIcon />}
          label="DUTY"
          value="78.5"
          unit="%"
        />
        <MetricCard
          className="span-2"
          icon={<ThermometerIcon />}
          label="TEMP. MOSFET"
          value="54"
          unit="°C"
        />
        <MetricCard
          className="span-2"
          icon={<ShieldIcon />}
          label="TEMP. SILNIKA"
          value="62"
          unit="°C"
        />
        <MetricCard
          className="span-2 row-end"
          icon={<RegenIcon />}
          label="REGEN"
          value="ON"
          unit=""
        />
      </section>
    </PhoneFrame>
  )
}

function StatsScreen() {
  return (
    <PhoneFrame>
      <StatusBar />

      <section className="stats-header">
        <h1>STATYSTYKI BIEGÓW</h1>
      </section>

      <section className="stats-table-card">
        <table>
          <thead>
            <tr>
              <th>BIEG</th>
              <th>MAX PRĘDKOŚĆ [km/h]</th>
              <th>MAX ERPM</th>
              <th>MIN NAPIĘCIE [V]</th>
              <th>MAX PRĄD BATERII [A]</th>
              <th>MAX PRĄD SILNIKA [A]</th>
            </tr>
          </thead>
          <tbody>
            {gearStats.map((row) => (
              <tr key={row.gear}>
                <td>{row.gear}</td>
                <td>{row.maxSpeed}</td>
                <td>{row.maxErpm}</td>
                <td>{row.minVoltage.toFixed(1)}</td>
                <td>{row.maxBatteryCurrent.toFixed(1)}</td>
                <td>{row.maxMotorCurrent.toFixed(1)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <nav className="bottom-nav" aria-label="Main navigation">
        <NavItem icon={<DashboardIcon />} label="DASHBOARD" />
        <NavItem active icon={<StatsIcon />} label="STATYSTYKI" />
        <NavItem icon={<SettingsIcon />} label="USTAWIENIA" />
      </nav>
    </PhoneFrame>
  )
}

function PhoneFrame({ children }: { children: ReactNode }) {
  return <article className="phone-frame">{children}</article>
}

function StatusBar() {
  return (
    <header className="status-bar">
      <div className="brand" aria-label="VESC">
        <span className="brand-accent">V</span>ESC
      </div>
      <span className="status-time">12:45</span>
      <div className="status-icons" aria-hidden="true">
        <span>⟠</span>
        <span>◔</span>
        <span>▮▮▮</span>
        <span className="battery-status">
          <span className="battery-fill" />
        </span>
      </div>
    </header>
  )
}

function SpeedGauge({ max, value }: { max: number; value: number }) {
  const progress = Math.min(value / max, 1)
  const gaugeStyle = { '--progress': `${progress}` } as CSSProperties

  return (
    <div className="speed-gauge" style={gaugeStyle}>
      <div className="gauge-track" />
      <div className="gauge-glow" />
      <div className="gauge-content">
        <div className="speed-value">
          <span className="speed-number">{value}</span>
          <span className="speed-unit">km/h</span>
        </div>
      </div>
    </div>
  )
}

function MetricCard({ className = '', icon, label, unit, value }: MetricCardProps) {
  return (
    <section className={`metric-card ${className}`.trim()}>
      <div className="metric-icon" aria-hidden="true">
        {icon}
      </div>
      <div className="metric-content">
        <span className="metric-label">{label}</span>
        <strong className="metric-value">{value}</strong>
        {unit ? <span className="metric-unit">{unit}</span> : null}
      </div>
    </section>
  )
}

function NavItem({ active = false, icon, label }: NavItemProps) {
  return (
    <button type="button" className={`nav-item ${active ? 'active' : ''}`.trim()}>
      <span className="nav-icon" aria-hidden="true">
        {icon}
      </span>
      <span>{label}</span>
    </button>
  )
}

function IconFrame({ children }: { children: ReactNode }) {
  return (
    <svg viewBox="0 0 32 32" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      {children}
    </svg>
  )
}

function BatteryIcon() {
  return (
    <IconFrame>
      <rect x="8" y="5" width="14" height="22" rx="2" />
      <path d="M13 2h4" />
      <path d="M11 19h8" />
    </IconFrame>
  )
}

function BoltIcon() {
  return (
    <IconFrame>
      <path d="M18 3 8 18h7l-1 11 10-15h-7l1-11Z" />
    </IconFrame>
  )
}

function BatteryPowerIcon() {
  return (
    <IconFrame>
      <rect x="8" y="5" width="14" height="22" rx="2" />
      <path d="M13 2h4" />
      <path d="M16 10v10" />
      <path d="m13 17 3-7 3 7" />
    </IconFrame>
  )
}

function MotorIcon() {
  return (
    <IconFrame>
      <rect x="5" y="9" width="22" height="14" rx="2" />
      <path d="M9 9V6" />
      <path d="M14 9V6" />
      <path d="M18 9V6" />
      <path d="M23 9V6" />
      <path d="M9 23v3" />
      <path d="M14 23v3" />
      <path d="M18 23v3" />
      <path d="M23 23v3" />
      <path d="M10 14h12" />
      <path d="M10 18h12" />
    </IconFrame>
  )
}

function DutyIcon() {
  return (
    <IconFrame>
      <circle cx="16" cy="16" r="11" />
      <path d="M16 16 23 10" />
      <path d="M16 16V7" />
    </IconFrame>
  )
}

function ThermometerIcon() {
  return (
    <IconFrame>
      <path d="M13 7a3 3 0 0 1 6 0v10.2a6 6 0 1 1-6 0Z" />
      <path d="M16 14v7" />
    </IconFrame>
  )
}

function ShieldIcon() {
  return (
    <IconFrame>
      <path d="M16 4 7 8v7c0 6 3.8 10.3 9 13 5.2-2.7 9-7 9-13V8l-9-4Z" />
      <path d="m12 18 3 3 5-7" />
    </IconFrame>
  )
}

function RegenIcon() {
  return (
    <IconFrame>
      <path d="M7 17a9 9 0 0 0 15 6" />
      <path d="m19 23 3 1-1 3" />
      <path d="M25 15A9 9 0 0 0 10 9" />
      <path d="m13 9-3-1 1-3" />
    </IconFrame>
  )
}

function DashboardIcon() {
  return (
    <IconFrame>
      <path d="M7 21a9 9 0 1 1 18 0" />
      <path d="M16 16 22 12" />
      <path d="M16 16V9" />
    </IconFrame>
  )
}

function StatsIcon() {
  return (
    <IconFrame>
      <path d="M8 24V14" />
      <path d="M16 24V8" />
      <path d="M24 24V11" />
    </IconFrame>
  )
}

function SettingsIcon() {
  return (
    <IconFrame>
      <circle cx="16" cy="16" r="4.5" />
      <path d="M16 5v3" />
      <path d="M16 24v3" />
      <path d="m8.5 8.5 2.1 2.1" />
      <path d="m21.4 21.4 2.1 2.1" />
      <path d="M5 16h3" />
      <path d="M24 16h3" />
      <path d="m8.5 23.5 2.1-2.1" />
      <path d="m21.4 10.6 2.1-2.1" />
    </IconFrame>
  )
}

export default App
