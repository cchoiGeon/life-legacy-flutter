import {
  periodForHour,
  PUSH_SLOT_AM_HOUR,
  PUSH_SLOT_PM_HOUR,
  seoulDayUtcRange,
  seoulNowParts,
  seoulSlotUtcRange,
} from './daily-question-scheduler.service';

describe('daily-question schedule helpers', () => {
  it('maps 09 → am and 14 → pm', () => {
    expect(periodForHour(PUSH_SLOT_AM_HOUR)).toBe('am');
    expect(periodForHour(PUSH_SLOT_PM_HOUR)).toBe('pm');
    expect(periodForHour(10)).toBeNull();
  });

  it('computes Seoul calendar day as UTC range (KST = UTC+9)', () => {
    const { startUtc, endUtc } = seoulDayUtcRange({
      year: 2026,
      month: 8,
      day: 6,
      hour: 9,
      weekday: 4,
    });
    expect(startUtc.toISOString()).toBe('2026-08-05T15:00:00.000Z');
    expect(endUtc.toISOString()).toBe('2026-08-06T15:00:00.000Z');
  });

  it('computes slot hour window in UTC', () => {
    const { startUtc, endUtc } = seoulSlotUtcRange(
      { year: 2026, month: 8, day: 6, hour: 9, weekday: 4 },
      'am',
    );
    expect(startUtc.toISOString()).toBe('2026-08-06T00:00:00.000Z');
    expect(endUtc.toISOString()).toBe('2026-08-06T01:00:00.000Z');
  });

  it('reads weekday/hour in Asia/Seoul', () => {
    // 2026-08-06 09:05 KST = 2026-08-06 00:05 UTC (Thursday)
    const parts = seoulNowParts(new Date('2026-08-06T00:05:00.000Z'));
    expect(parts.year).toBe(2026);
    expect(parts.month).toBe(8);
    expect(parts.day).toBe(6);
    expect(parts.hour).toBe(9);
    expect(parts.weekday).toBe(4);
  });
});
