import { fromNodeHeaders } from 'better-auth/node';
import type { preHandlerAsyncHookHandler } from 'fastify';

/** Route guard: 401 without a valid session, otherwise `request.user` is the signed-in user. */
export const requireUser: preHandlerAsyncHookHandler = async (request, reply) => {
  const session = await request.server.auth.api.getSession({ headers: fromNodeHeaders(request.headers) });
  if (!session) return reply.code(401).send({ error: 'unauthorized' });
  request.user = session.user;
};
