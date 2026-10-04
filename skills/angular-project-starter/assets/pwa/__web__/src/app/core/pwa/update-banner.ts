import { DOCUMENT } from '@angular/common';
import { Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { SwUpdate, type VersionEvent, type VersionReadyEvent } from '@angular/service-worker';
import { filter, map } from 'rxjs';

const isVersionReady = (event: VersionEvent): event is VersionReadyEvent => event.type === 'VERSION_READY';

/** Tells the user a new version has been downloaded and lets them choose when to reload. */
@Component({
  selector: 'app-update-banner',
  template: `
    @if (updateReady()) {
      <div role="status" class="fixed inset-x-0 bottom-0 flex items-center justify-between gap-4 bg-slate-900 p-3 text-white">
        <span>A new version is available.</span>
        <button type="button" (click)="reload()" class="rounded bg-white px-3 py-1 text-slate-900">Reload</button>
      </div>
    }
  `,
})
export class UpdateBanner {
  readonly #document = inject(DOCUMENT);

  protected readonly updateReady = toSignal(
    inject(SwUpdate).versionUpdates.pipe(
      filter(isVersionReady),
      map(() => true),
    ),
    { initialValue: false },
  );

  protected reload(): void {
    this.#document.location.reload();
  }
}
