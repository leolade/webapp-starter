import webpush from 'web-push';
import type { Config } from '../config.ts';

interface PushTarget {
  endpoint: string;
  keys: { p256dh: string; auth: string };
}

interface PushMessage {
  title: string;
  body: string;
  /** Page opened when the user taps the notification. */
  url?: string;
}

/** Delivers one message to one subscription. Rejects with `statusCode` 404/410 when the subscription is gone. */
export type Send = (target: PushTarget, message: PushMessage) => Promise<void>;

/**
 * The real sender (web-push, VAPID). VAPID details are applied on first use so tests, which inject a fake
 * `Send`, never need valid keys. The payload shape is what Angular's service worker turns into a notification.
 */
export const createSender = (config: Pick<Config, 'VAPID_PUBLIC_KEY' | 'VAPID_PRIVATE_KEY' | 'VAPID_SUBJECT'>): Send => {
  let configured = false;
  return async (target, message) => {
    if (!configured) {
      webpush.setVapidDetails(config.VAPID_SUBJECT, config.VAPID_PUBLIC_KEY, config.VAPID_PRIVATE_KEY);
      configured = true;
    }
    const notification = {
      title: message.title,
      body: message.body,
      data: { onActionClick: { default: { operation: 'navigateLastFocusedOrOpen', url: message.url ?? '/' } } },
    };
    await webpush.sendNotification(target, JSON.stringify({ notification }));
  };
};

export const isGoneError = (error: unknown): boolean =>
  typeof error === 'object' && error !== null && 'statusCode' in error && (error.statusCode === 404 || error.statusCode === 410);
