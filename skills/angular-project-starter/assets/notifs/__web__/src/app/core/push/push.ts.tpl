import { HttpClient } from '@angular/common/http';
import { inject, Service, signal } from '@angular/core';
import { SwPush } from '@angular/service-worker';
import { publicKeyResponseSchema, pushSubscriptionSchema } from '@{{scope}}/shared';
import { firstValueFrom } from 'rxjs';

/**
 * Web Push from the browser side. Only works with the production build (the service worker is disabled in
 * `ng serve`): `isSupported` is false otherwise and the UI should explain that instead of failing.
 */
@Service()
export class Push {
  readonly #swPush = inject(SwPush);
  readonly #http = inject(HttpClient);
  readonly #subscribed = signal(false);

  readonly isSupported = this.#swPush.isEnabled;
  readonly isSubscribed = this.#subscribed.asReadonly();

  async enable(): Promise<void> {
    const { publicKey } = publicKeyResponseSchema.parse(await firstValueFrom(this.#http.get('/api/push/public-key')));
    const subscription = await this.#swPush.requestSubscription({ serverPublicKey: publicKey });
    await firstValueFrom(this.#http.post('/api/push/subscriptions', pushSubscriptionSchema.parse(subscription.toJSON())));
    this.#subscribed.set(true);
  }

  async disable(): Promise<void> {
    const subscription = await firstValueFrom(this.#swPush.subscription);
    if (!subscription) return;
    await firstValueFrom(this.#http.delete('/api/push/subscriptions', { body: { endpoint: subscription.endpoint } }));
    await subscription.unsubscribe();
    this.#subscribed.set(false);
  }
}
