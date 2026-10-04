import { httpResource } from '@angular/common/http';
import { DecimalPipe } from '@angular/common';
import { Component } from '@angular/core';
import { healthResponseSchema } from '@{{scope}}/shared';

/**
 * Reference feature: `httpResource` for reads, response validated by the schema shared with the API.
 * Copy this shape for new features (route component + data resource + explicit loading/error states).
 */
@Component({
  selector: 'app-status',
  imports: [DecimalPipe],
  template: `
    <section aria-labelledby="status-heading" class="mt-6">
      <h2 id="status-heading" class="text-lg font-medium">API status</h2>
      @if (health.hasValue()) {
        <p>API is {{ health.value().status }} (up {{ health.value().uptimeSeconds | number: '1.0-0' }} s)</p>
      } @else if (health.error()) {
        <p role="alert" class="text-red-700">The API is unreachable.</p>
      } @else {
        <p>Checking the API…</p>
      }
    </section>
  `,
})
export class Status {
  protected readonly health = httpResource(() => '/api/health', { parse: (raw) => healthResponseSchema.parse(raw) });
}
