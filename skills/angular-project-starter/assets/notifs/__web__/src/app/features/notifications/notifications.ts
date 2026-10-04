import { Component, inject, signal } from '@angular/core';
import { Push } from '../../core/push/push';

@Component({
  selector: 'app-notifications',
  template: `
    <section aria-labelledby="notifications-heading" class="mt-6">
      <h2 id="notifications-heading" class="text-lg font-medium">Notifications</h2>
      @if (!push.isSupported) {
        <p>Push notifications are only available in the installed production build.</p>
      } @else {
        @if (push.isSubscribed()) {
          <button type="button" (click)="toggle()" class="rounded border px-3 py-1">Disable notifications</button>
        } @else {
          <button type="button" (click)="toggle()" class="rounded bg-slate-900 px-3 py-2 text-white">Enable notifications</button>
        }
        @if (failure()) {
          <p role="alert" class="mt-2 text-red-700">{{ failure() }}</p>
        }
      }
    </section>
  `,
})
export class Notifications {
  protected readonly push = inject(Push);
  protected readonly failure = signal('');

  protected async toggle(): Promise<void> {
    this.failure.set('');
    try {
      await (this.push.isSubscribed() ? this.push.disable() : this.push.enable());
    } catch (error: unknown) {
      this.failure.set(error instanceof Error ? error.message : 'Could not change the notification setting');
    }
  }
}
