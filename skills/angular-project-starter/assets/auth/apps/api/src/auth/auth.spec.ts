import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { createTestApp } from '../test/app.ts';
import { signUp } from '../test/auth.ts';

describe('authentication', () => {
  let ctx: Awaited<ReturnType<typeof createTestApp>>;

  beforeEach(async () => {
    ctx = await createTestApp();
  });

  afterEach(async () => {
    await ctx.close();
  });

  it('returns no session for anonymous requests', async () => {
    const response = await ctx.app.inject({ method: 'GET', url: '/api/auth/get-session' });
    expect(response.statusCode).toBe(200);
    expect(response.body === 'null' || response.body === '').toBe(true);
  });

  it('signs up, then signs in with the same credentials', async () => {
    await signUp(ctx.app, 'dana@example.com');
    const response = await ctx.app.inject({
      method: 'POST',
      url: '/api/auth/sign-in/email',
      payload: { email: 'dana@example.com', password: 'correct-horse-battery' },
    });
    expect(response.statusCode).toBe(200);
    expect(response.cookies.length).toBeGreaterThan(0);
  });

  it('rejects a wrong password', async () => {
    await signUp(ctx.app, 'erin@example.com');
    const response = await ctx.app.inject({
      method: 'POST',
      url: '/api/auth/sign-in/email',
      payload: { email: 'erin@example.com', password: 'not-the-password' },
    });
    expect(response.statusCode).toBe(401);
  });
});
