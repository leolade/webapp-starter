import { publicKeyResponseSchema, pushSubscriptionSchema, unsubscribeSchema } from '@{{scope}}/shared';
import { eq } from 'drizzle-orm';
import type { FastifyPluginCallbackZod } from 'fastify-type-provider-zod';
{{#if auth}}
import { requireUser } from '../auth/require-user.ts';
{{/if}}
import type { Config } from '../config.ts';
import type { Database } from '../db/client.ts';
import { pushSubscriptions } from '../db/schema.ts';
import { isGoneError, type Send } from '../push/sender.ts';

interface PushRouteOptions {
  config: Pick<Config, 'VAPID_PUBLIC_KEY'>;
  db: Database;
  send: Send;
}

export const pushRoutes: FastifyPluginCallbackZod<PushRouteOptions> = (app, { config, db, send }, done) => {
  app.get('/push/public-key', { schema: { response: { 200: publicKeyResponseSchema } } }, () => ({ publicKey: config.VAPID_PUBLIC_KEY }));

  app.post(
    '/push/subscriptions',
{{#if auth}}
    { preHandler: requireUser, schema: { body: pushSubscriptionSchema } },
{{/if}}
{{#unless auth}}
    { schema: { body: pushSubscriptionSchema } },
{{/unless}}
    async (request, reply) => {
      const { endpoint, keys } = request.body;
      await db
        .insert(pushSubscriptions)
        .values({ endpoint, p256dh: keys.p256dh, auth: keys.auth{{#if auth}}, userId: request.user.id{{/if}} })
        .onConflictDoUpdate({
          target: pushSubscriptions.endpoint,
          set: { p256dh: keys.p256dh, auth: keys.auth{{#if auth}}, userId: request.user.id{{/if}} },
        });
      return reply.code(204).send();
    },
  );

  app.delete(
    '/push/subscriptions',
{{#if auth}}
    { preHandler: requireUser, schema: { body: unsubscribeSchema } },
{{/if}}
{{#unless auth}}
    { schema: { body: unsubscribeSchema } },
{{/unless}}
    async (request, reply) => {
      await db.delete(pushSubscriptions).where(eq(pushSubscriptions.endpoint, request.body.endpoint));
      return reply.code(204).send();
    },
  );

  // Sends a test notification to the caller's subscriptions{{#unless auth}} (to every subscription: there is no user){{/unless}}; unreachable ones are pruned.
  app.post(
    '/push/test',
{{#if auth}}
    { preHandler: requireUser },
{{/if}}
{{#unless auth}}
    {},
{{/unless}}
    async (request, reply) => {
{{#if auth}}
      const targets = await db.select().from(pushSubscriptions).where(eq(pushSubscriptions.userId, request.user.id));
{{/if}}
{{#unless auth}}
      const targets = await db.select().from(pushSubscriptions);
{{/unless}}
      let delivered = 0;
      for (const target of targets) {
        try {
          await send(
            { endpoint: target.endpoint, keys: { p256dh: target.p256dh, auth: target.auth } },
            { title: 'Test notification', body: 'Push notifications are working.', url: '/' },
          );
          delivered += 1;
        } catch (error: unknown) {
          if (!isGoneError(error)) throw error;
          await db.delete(pushSubscriptions).where(eq(pushSubscriptions.id, target.id));
        }
      }
      return reply.code(200).send({ delivered });
    },
  );
  done();
};
