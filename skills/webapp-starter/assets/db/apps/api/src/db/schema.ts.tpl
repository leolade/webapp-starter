import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';
{{#if auth}}
import { user } from './auth-schema.ts';

export * from './auth-schema.ts';
{{/if}}

/** Reference resource: copy this shape (table here, DTO in packages/shared, route + spec in apps/api). */
export const notes = pgTable('notes', {
  id: uuid().primaryKey().defaultRandom(),
{{#if auth}}
  userId: text()
    .notNull()
    .references(() => user.id, { onDelete: 'cascade' }),
{{/if}}
  body: text().notNull(),
  createdAt: timestamp({ withTimezone: true }).notNull().defaultNow(),
});
{{#if notifs}}

/** One row per browser push subscription. `endpoint` is unique: re-subscribing updates the keys. */
export const pushSubscriptions = pgTable('push_subscriptions', {
  id: uuid().primaryKey().defaultRandom(),
{{#if auth}}
  userId: text()
    .notNull()
    .references(() => user.id, { onDelete: 'cascade' }),
{{/if}}
  endpoint: text().notNull().unique(),
  p256dh: text().notNull(),
  auth: text().notNull(),
  createdAt: timestamp({ withTimezone: true }).notNull().defaultNow(),
});
{{/if}}
