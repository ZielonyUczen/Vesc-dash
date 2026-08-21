import { describe, it, expect } from 'vitest';
import {
  erpmToSpeedKmh,
  speedKmhToErpm,
  DEFAULT_CONFIG,
  GearConfig,
} from '../lib/speed';

// BBS02B default config:
//   polePairs=8, motorGearRatio=21.9, frontTeeth=40, rearTeeth=22, wheelCirc=2.155 m
const cfg = DEFAULT_CONFIG;

describe('erpmToSpeedKmh', () => {
  it('returns 0 for 0 eRPM', () => {
    expect(erpmToSpeedKmh(0, cfg)).toBe(0);
  });

  it('returns 0 for negative eRPM', () => {
    expect(erpmToSpeedKmh(-100, cfg)).toBe(0);
  });

  it('calculates a known value correctly', () => {
    // mechanical RPM = 10000 / 8 = 1250
    // crank RPM = 1250 / 21.9 ≈ 57.076
    // wheel RPM = 57.076 * (40/22) ≈ 103.775
    // speed = 103.775 * 2.155 * 60 / 1000 ≈ 13.41 km/h
    const speed = erpmToSpeedKmh(10000, cfg);
    expect(speed).toBeCloseTo(13.41, 1);
  });

  it('scales linearly with eRPM', () => {
    const s1 = erpmToSpeedKmh(10000, cfg);
    const s2 = erpmToSpeedKmh(20000, cfg);
    expect(s2).toBeCloseTo(s1 * 2, 5);
  });

  it('is faster on small rear sprocket than large one', () => {
    const cfgSmall: GearConfig = { ...cfg, rearTeeth: 11 };
    const cfgLarge: GearConfig = { ...cfg, rearTeeth: 42 };
    expect(erpmToSpeedKmh(20000, cfgSmall)).toBeGreaterThan(
      erpmToSpeedKmh(20000, cfgLarge),
    );
  });
});

describe('speedKmhToErpm', () => {
  it('returns 0 for 0 km/h', () => {
    expect(speedKmhToErpm(0, cfg)).toBe(0);
  });

  it('is the inverse of erpmToSpeedKmh', () => {
    const erpm = 15000;
    const speed = erpmToSpeedKmh(erpm, cfg);
    expect(speedKmhToErpm(speed, cfg)).toBeCloseTo(erpm, 1);
  });
});
