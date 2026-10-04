import { describe, expect, it } from 'vitest';
import { healthResponseSchema } from './health.ts';

describe('healthResponseSchema', () => {
  it('accepts a valid body', () => {
    expect(healthResponseSchema.parse({ status: 'ok', uptimeSeconds: 12.5 })).toEqual({ status: 'ok', uptimeSeconds: 12.5 });
  });

  it('rejects an unknown status', () => {
    expect(healthResponseSchema.safeParse({ status: 'down', uptimeSeconds: 1 }).success).toBe(false);
  });
});
