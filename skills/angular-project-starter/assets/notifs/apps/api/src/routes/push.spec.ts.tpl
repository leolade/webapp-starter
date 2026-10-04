import { describe, expect, it, vi } from 'vitest';
import { createTestApp } from '../test/app.ts';
{{#if auth}}
import { signUp } from '../test/auth.ts';
{{/if}}

const subscription = { endpoint: 'https://push.example.test/abc', keys: { p256dh: 'p256dh-key', auth: 'auth-key' } };

describe('push API', () => {
  it('exposes the VAPID public key', async () => {
    const { app, close } = await createTestApp();
    const response = await app.inject({ method: 'GET', url: '/api/push/public-key' });
    expect(response.json()).toEqual({ publicKey: 'test-public-key' });
    await close();
  });

  it('stores a subscription, delivers a test notification, and prunes subscriptions that are gone', async () => {
    const gone = Object.assign(new Error('gone'), { statusCode: 410 });
    const send = vi.fn().mockResolvedValueOnce(undefined).mockRejectedValueOnce(gone);
    const { app, close } = await createTestApp({ send });
{{#if auth}}
    const cookie = await signUp(app, 'push@example.com');
    const headers = { cookie };
{{/if}}
{{#unless auth}}
    const headers = {};
{{/unless}}

    const created = await app.inject({ method: 'POST', url: '/api/push/subscriptions', headers, payload: subscription });
    expect(created.statusCode).toBe(204);

    const first = await app.inject({ method: 'POST', url: '/api/push/test', headers });
    expect(first.json()).toEqual({ delivered: 1 });

    const second = await app.inject({ method: 'POST', url: '/api/push/test', headers });
    expect(second.json()).toEqual({ delivered: 0 });

    const third = await app.inject({ method: 'POST', url: '/api/push/test', headers });
    expect(third.json()).toEqual({ delivered: 0 });
    expect(send).toHaveBeenCalledTimes(2);
    await close();
  });

  it('rejects a malformed subscription with 400', async () => {
    const { app, close } = await createTestApp();
{{#if auth}}
    const headers = { cookie: await signUp(app, 'bad-push@example.com') };
{{/if}}
{{#unless auth}}
    const headers = {};
{{/unless}}
    const response = await app.inject({ method: 'POST', url: '/api/push/subscriptions', headers, payload: { endpoint: 'not-a-url' } });
    expect(response.statusCode).toBe(400);
    await close();
  });
});
