import { describe, expect, it } from 'vitest';
import { makeMoodPlan, estimateTripBudget } from './domain.js';

describe('NÉP journey planner', () => {
  it('creates a plan with three steps for a supported mood', () => {
    const plan = makeMoodPlan('Bình yên', 'Nửa ngày');
    expect(plan.steps).toHaveLength(3);
    expect(plan.duration).toBe('Nửa ngày');
  });
  it('rejects unsupported moods', () => {
    expect(() => makeMoodPlan('Không tồn tại', 'Một ngày')).toThrow();
  });
});

describe('NÉP budget estimator', () => {
  it('calculates total budget', () => {
    expect(estimateTripBudget(3, 250000, 2)).toBe(1500000);
  });
  it('rejects invalid values', () => {
    expect(() => estimateTripBudget(0, 200000, 1)).toThrow();
  });
});
