import type { FastifyReply, FastifyRequest } from 'fastify';
import fp from 'fastify-plugin';
import { createAuth, type Auth, type AuthOptions, type SessionUser } from './auth.ts';

declare module 'fastify' {
  interface FastifyInstance {
    auth: Auth;
  }
  interface FastifyRequest {
    user: SessionUser;
  }
}

/** Better Auth speaks the web `Request`/`Response` API; Fastify speaks Node. These two helpers translate. */
const toWebRequest = (request: FastifyRequest): Request => {
  const url = new URL(request.url, `http://${request.headers.host ?? 'localhost'}`);
  const headers = new Headers();
  for (const [key, value] of Object.entries(request.headers)) {
    if (value !== undefined) headers.append(key, Array.isArray(value) ? value.join(', ') : value);
  }
  const hasBody = request.method !== 'GET' && request.body !== undefined;
  return new Request(url, { method: request.method, headers, body: hasBody ? JSON.stringify(request.body) : undefined });
};

const sendWebResponse = async (reply: FastifyReply, response: Response) => {
  void reply.status(response.status);
  for (const [key, value] of response.headers) {
    if (key !== 'set-cookie') void reply.header(key, value);
  }
  const cookies = response.headers.getSetCookie();
  if (cookies.length > 0) void reply.header('set-cookie', cookies);
  return reply.send(response.body ? await response.text() : null);
};

/**
 * Mounts Better Auth under /api/auth/* and exposes `app.auth` plus `request.user` (set by `requireUser`).
 * Wrapped in fastify-plugin so the decorators are visible to sibling routes.
 */
export const authPlugin = fp<AuthOptions>(
  (app, options, done) => {
    const auth = createAuth(options);
    app.decorate('auth', auth);
    app.decorateRequest('user');

    app.route({
      method: ['GET', 'POST'],
      url: '/api/auth/*',
      handler: async (request, reply) => sendWebResponse(reply, await auth.handler(toWebRequest(request))),
    });
    done();
  },
  { name: 'auth' },
);
