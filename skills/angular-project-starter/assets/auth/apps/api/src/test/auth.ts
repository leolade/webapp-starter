import type { buildApp } from '../app.ts';

/** Registers a user through the real endpoint and returns a `cookie` header value for authenticated `inject()` calls. */
export const signUp = async (app: Awaited<ReturnType<typeof buildApp>>, email: string): Promise<string> => {
  const response = await app.inject({
    method: 'POST',
    url: '/api/auth/sign-up/email',
    payload: { name: 'Test User', email, password: 'correct-horse-battery' },
  });
  if (response.statusCode !== 200) throw new Error(`sign-up failed: ${response.statusCode} ${response.body}`);
  return response.cookies.map((cookie) => `${cookie.name}=${cookie.value}`).join('; ');
};
