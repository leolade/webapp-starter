import { z } from 'zod';

/** What `PushSubscription.toJSON()` produces in the browser (extra fields such as expirationTime are dropped). */
export const pushSubscriptionSchema = z.object({
  endpoint: z.url(),
  keys: z.object({
    p256dh: z.string().min(1),
    auth: z.string().min(1),
  }),
});
export type PushSubscriptionDto = z.infer<typeof pushSubscriptionSchema>;

export const unsubscribeSchema = z.object({ endpoint: z.url() });

export const publicKeyResponseSchema = z.object({ publicKey: z.string().min(1) });
export type PublicKeyResponse = z.infer<typeof publicKeyResponseSchema>;
