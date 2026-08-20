/**
 * VESC real-time telemetry data structure (firmware 7.x).
 * Fields mirror the VESC Tool "RT Data" packet.
 */
export interface VescTelemetry {
  /** Battery pack voltage (V) */
  voltageInput: number;
  /** Motor phase current (A) */
  currentMotor: number;
  /** Battery input current (A) */
  currentInput: number;
  /** Motor duty cycle (0–100 %) */
  dutyCycle: number;
  /** Electrical RPM */
  erpm: number;
  /** Amp-hours consumed (Ah) */
  ampHours: number;
  /** Watt-hours consumed (Wh) */
  wattHours: number;
  /** MOSFET temperature (°C) */
  tempMosfet: number;
  /** Motor winding temperature (°C) — optional sensor */
  tempMotor: number;
  /** Fault code (0 = no fault) */
  faultCode: number;
  /** Unix timestamp of this reading */
  timestamp: number;
}

export const INITIAL_TELEMETRY: VescTelemetry = {
  voltageInput: 0,
  currentMotor: 0,
  currentInput: 0,
  dutyCycle: 0,
  erpm: 0,
  ampHours: 0,
  wattHours: 0,
  tempMosfet: 0,
  tempMotor: 0,
  faultCode: 0,
  timestamp: 0,
};

/** Human-readable VESC fault codes (firmware 7.x) */
export const FAULT_CODES: Record<number, string> = {
  0: 'No fault',
  1: 'Over voltage',
  2: 'Under voltage',
  3: 'DRV fault',
  4: 'ABS over current',
  5: 'Over temp FET',
  6: 'Over temp motor',
  7: 'Gate driver over voltage',
  8: 'Gate driver under voltage',
  9: 'MCU under voltage',
  10: 'Booting from watchdog reset',
  11: 'Encoder SPI fault',
  12: 'Encoder sincos below min amplitude',
  13: 'Encoder sincos above max amplitude',
  14: 'Flash corruption',
  15: 'High offset current sensor 1',
  16: 'High offset current sensor 2',
  17: 'High offset current sensor 3',
  18: 'Unbalanced currents',
};

/**
 * Calculates instantaneous power in watts from telemetry.
 */
export function calcPowerW(telemetry: VescTelemetry): number {
  return telemetry.voltageInput * telemetry.currentInput;
}
