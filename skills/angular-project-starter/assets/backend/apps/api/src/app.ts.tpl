import helmet from '@fastify/helmet';
import Fastify from 'fastify';
import { serializerCompiler, validatorCompiler, type ZodTypeProvider } from 'fastify-type-provider-zod';
import type { Config } from './config.ts';
{{#if db}}
import type { Database } from './db/client.ts';
{{/if}}
import { healthRoutes } from './routes/health.ts';
{{#if db}}
import { noteRoutes } from './routes/notes.ts';
{{/if}}
{{#if auth}}
import { authPlugin } from './auth/plugin.ts';
{{/if}}
{{#if notifs}}
import { createSender, type Send } from './push/sender.ts';
import { pushRoutes } from './routes/push.ts';
{{/if}}

export interface AppOptions {
  config: Config;
{{#if db}}
  db: Database;
{{/if}}
{{#if notifs}}
  /** Push delivery. Defaults to web-push with the configured VAPID keys; tests inject a fake. */
  send?: Send;
{{/if}}
}

/**
 * Builds the Fastify instance without listening, so tests can drive it with `app.inject()`.
 * Request/response validation comes from the Zod schemas in the shared package (the DTOs).
 */
export const buildApp = async ({ config{{#if db}}, db{{/if}}{{#if notifs}}, send{{/if}} }: AppOptions) => {
  const app = Fastify({ logger: config.NODE_ENV === 'test' ? false : { level: 'info' } }).withTypeProvider<ZodTypeProvider>();
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  await app.register(helmet);
  // Everything lives under /api: the web app and the API share one origin (dev proxy, production reverse proxy).
  await app.register(healthRoutes, { prefix: '/api' });
{{#if auth}}
  await app.register(authPlugin, { config, db });
{{/if}}
{{#if db}}
  await app.register(noteRoutes, { prefix: '/api', db });
{{/if}}
{{#if notifs}}
  await app.register(pushRoutes, { prefix: '/api', config, db, send: send ?? createSender(config) });
{{/if}}

  return app;
};
