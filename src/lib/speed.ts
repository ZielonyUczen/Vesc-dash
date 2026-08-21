/**
 * VESC speed calculation for BBS02B mid-drive motor.
 *
 * Physical constants for Marketbase 75200 V2 + BBS02B setup:
 *   Motor internal gear ratio  : 1:21.9  (motor shaft → crank)
 *   Front chainring            : 40 teeth
 *   Rear cassette range        : 11–42 teeth
 *   Motor pole pairs           : 8  (BBS02B uses a 3-phase 8-pole-pair BLDC)
 *
 * Speed formula:
 *   eRPM = mechanical_RPM * pole_pairs
 *   crank_RPM = eRPM / pole_pairs / motor_gear_ratio
 *   wheel_RPM = crank_RPM * (front_teeth / rear_teeth)
 *   speed_km_h = wheel_RPM * wheel_circumference_m * 60 / 1000
 */

export interface GearConfig {
  /** Motor pole pairs (BBS02B default: 8) */
  polePairs: number;
  /** Internal gear ratio of the motor (motor shaft : crank output) */
  motorGearRatio: number;
  /** Front chainring tooth count */
  frontTeeth: number;
  /** Currently engaged rear sprocket tooth count */
  rearTeeth: number;
  /** Wheel circumference in meters */
  wheelCircumferenceM: number;
}

export const DEFAULT_CONFIG: GearConfig = {
  polePairs: 8,
  motorGearRatio: 21.9,
  frontTeeth: 40,
  rearTeeth: 22, // middle of 11-42 range as sensible default
  wheelCircumferenceM: 2.155, // 26" wheel with typical tyre (approx 2.155 m)
};

/**
 * Calculates speed in km/h from VESC eRPM.
 */
export function erpmToSpeedKmh(erpm: number, config: GearConfig): number {
  if (erpm <= 0) return 0;
  const mechanicalRpm = erpm / config.polePairs;
  const crankRpm = mechanicalRpm / config.motorGearRatio;
  const wheelRpm = crankRpm * (config.frontTeeth / config.rearTeeth);
  const speedKmh = (wheelRpm * config.wheelCircumferenceM * 60) / 1000;
  return Math.max(0, speedKmh);
}

/**
 * Calculates eRPM from a target speed in km/h (inverse of erpmToSpeedKmh).
 */
export function speedKmhToErpm(speedKmh: number, config: GearConfig): number {
  if (speedKmh <= 0) return 0;
  const wheelRpm = (speedKmh * 1000) / (config.wheelCircumferenceM * 60);
  const crankRpm = wheelRpm / (config.frontTeeth / config.rearTeeth);
  const mechanicalRpm = crankRpm * config.motorGearRatio;
  const erpm = mechanicalRpm * config.polePairs;
  return Math.max(0, erpm);
}

/**
 * Rear sprocket options for an 11-42T cassette (common 9/10-speed steps).
 */
export const REAR_SPROCKET_OPTIONS = [11, 13, 15, 17, 20, 23, 26, 30, 34, 38, 42];
