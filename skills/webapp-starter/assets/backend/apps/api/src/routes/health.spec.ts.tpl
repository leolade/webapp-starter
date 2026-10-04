import { healthResponseSchema } from '@{{scope}}/shared';
import { describe, expect, it } from 'vitest';
import { createTestApp } from '../test/app.ts';

describe('GET /api/health', () => {
  it('answers 200 with a body that satisfies the shared schema', async () => {
    const { app, close } = await createTestApp();
    const response = await app.inject({ method: 'GET', url: '/api/health' });

    expect(response.statusCode).toBe(200);
    expect(healthResponseSchema.parse(response.json())).toMatchObject({ status: 'ok' });
    await close();
  });
});
