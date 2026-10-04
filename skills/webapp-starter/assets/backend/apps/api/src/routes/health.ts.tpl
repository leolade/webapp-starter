import { healthResponseSchema } from '@{{scope}}/shared';
import type { FastifyPluginCallbackZod } from 'fastify-type-provider-zod';

export const healthRoutes: FastifyPluginCallbackZod = (app, _options, done) => {
  app.get('/health', { schema: { response: { 200: healthResponseSchema } } }, () => ({
    status: 'ok' as const,
    uptimeSeconds: process.uptime(),
  }));
  done();
};
