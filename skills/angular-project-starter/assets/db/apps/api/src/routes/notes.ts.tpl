import { createNoteSchema, noteListSchema, noteSchema } from '@{{scope}}/shared';
{{#if auth}}
import { desc, eq } from 'drizzle-orm';
{{/if}}
{{#unless auth}}
import { desc } from 'drizzle-orm';
{{/unless}}
import type { FastifyPluginCallbackZod } from 'fastify-type-provider-zod';
{{#if auth}}
import { requireUser } from '../auth/require-user.ts';
{{/if}}
import type { Database } from '../db/client.ts';
import { notes } from '../db/schema.ts';

const toDto = (row: typeof notes.$inferSelect) => ({ id: row.id, body: row.body, createdAt: row.createdAt.toISOString() });

export const noteRoutes: FastifyPluginCallbackZod<{ db: Database }> = (app, { db }, done) => {
{{#if auth}}
  app.get('/notes', { preHandler: requireUser, schema: { response: { 200: noteListSchema } } }, async (request) => {
    const rows = await db.select().from(notes).where(eq(notes.userId, request.user.id)).orderBy(desc(notes.createdAt));
    return rows.map(toDto);
  });

  app.post('/notes', { preHandler: requireUser, schema: { body: createNoteSchema, response: { 201: noteSchema } } }, async (request, reply) => {
    const [row] = await db.insert(notes).values({ body: request.body.body, userId: request.user.id }).returning();
    if (!row) throw new Error('insert returned no row');
    return reply.code(201).send(toDto(row));
  });
{{/if}}
{{#unless auth}}
  app.get('/notes', { schema: { response: { 200: noteListSchema } } }, async () => {
    const rows = await db.select().from(notes).orderBy(desc(notes.createdAt));
    return rows.map(toDto);
  });

  app.post('/notes', { schema: { body: createNoteSchema, response: { 201: noteSchema } } }, async (request, reply) => {
    const [row] = await db.insert(notes).values({ body: request.body.body }).returning();
    if (!row) throw new Error('insert returned no row');
    return reply.code(201).send(toDto(row));
  });
{{/unless}}
  done();
};
