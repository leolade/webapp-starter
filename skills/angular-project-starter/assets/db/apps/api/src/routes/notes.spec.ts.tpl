import { noteListSchema, noteSchema } from '@{{scope}}/shared';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { createTestApp } from '../test/app.ts';
{{#if auth}}
import { signUp } from '../test/auth.ts';
{{/if}}

describe('notes API', () => {
  let ctx: Awaited<ReturnType<typeof createTestApp>>;

  beforeEach(async () => {
    ctx = await createTestApp();
  });

  afterEach(async () => {
    await ctx.close();
  });
{{#if auth}}

  it('rejects anonymous requests with 401', async () => {
    const response = await ctx.app.inject({ method: 'GET', url: '/api/notes' });
    expect(response.statusCode).toBe(401);
  });

  it("creates a note and lists only the caller's notes", async () => {
    const alice = await signUp(ctx.app, 'alice@example.com');
    const bob = await signUp(ctx.app, 'bob@example.com');

    const created = await ctx.app.inject({ method: 'POST', url: '/api/notes', headers: { cookie: alice }, payload: { body: 'alice note' } });
    expect(created.statusCode).toBe(201);
    expect(noteSchema.parse(created.json()).body).toBe('alice note');

    const aliceList = await ctx.app.inject({ method: 'GET', url: '/api/notes', headers: { cookie: alice } });
    const bobList = await ctx.app.inject({ method: 'GET', url: '/api/notes', headers: { cookie: bob } });
    expect(noteListSchema.parse(aliceList.json())).toHaveLength(1);
    expect(noteListSchema.parse(bobList.json())).toHaveLength(0);
  });

  it('rejects an empty body with 400', async () => {
    const cookie = await signUp(ctx.app, 'carol@example.com');
    const response = await ctx.app.inject({ method: 'POST', url: '/api/notes', headers: { cookie }, payload: { body: '' } });
    expect(response.statusCode).toBe(400);
  });
{{/if}}
{{#unless auth}}

  it('creates a note and lists it', async () => {
    const created = await ctx.app.inject({ method: 'POST', url: '/api/notes', payload: { body: 'first note' } });
    expect(created.statusCode).toBe(201);
    expect(noteSchema.parse(created.json()).body).toBe('first note');

    const list = await ctx.app.inject({ method: 'GET', url: '/api/notes' });
    expect(noteListSchema.parse(list.json())).toHaveLength(1);
  });

  it('rejects an empty body with 400', async () => {
    const response = await ctx.app.inject({ method: 'POST', url: '/api/notes', payload: { body: '' } });
    expect(response.statusCode).toBe(400);
  });
{{/unless}}
});
