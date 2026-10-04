import { DatePipe } from '@angular/common';
import { HttpClient, httpResource } from '@angular/common/http';
import { Component, inject, signal } from '@angular/core';
import { form, FormField, submit, validateStandardSchema } from '@angular/forms/signals';
import { createNoteSchema, noteListSchema } from '@{{scope}}/shared';
import { firstValueFrom } from 'rxjs';

/**
 * Reference feature (list + create): `httpResource` for the read, an HTTP call for the write, a Signal Form
 * validated by the schema shared with the API. Copy this shape for new resources.
 */
@Component({
  selector: 'app-notes',
  imports: [DatePipe, FormField],
  template: `
    <section aria-labelledby="notes-heading" class="mt-6">
      <h2 id="notes-heading" class="text-lg font-medium">Notes</h2>
      <form (submit)="add($event)" class="mt-3 flex gap-2" novalidate>
        <label class="flex flex-1 flex-col gap-1">
          New note
          <input type="text" [formField]="noteForm.body" class="rounded border px-2 py-1" />
        </label>
        <button type="submit" class="self-end rounded bg-slate-900 px-3 py-2 text-white">Add note</button>
      </form>
      @if (notes.hasValue()) {
        <ul class="mt-4 flex flex-col gap-2">
          @for (note of notes.value(); track note.id) {
            <li class="rounded border p-2">
              {{ note.body }}
              <span class="block text-xs text-slate-600">{{ note.createdAt | date: 'medium' }}</span>
            </li>
          } @empty {
            <li>No notes yet.</li>
          }
        </ul>
      } @else if (notes.error()) {
        <p role="alert" class="mt-4 text-red-700">Could not load the notes.</p>
      }
    </section>
  `,
})
export class Notes {
  readonly #http = inject(HttpClient);

  protected readonly notes = httpResource(() => '/api/notes', { parse: (raw) => noteListSchema.parse(raw) });
  protected readonly draft = signal({ body: '' });
  protected readonly noteForm = form(this.draft, (path) => {
    validateStandardSchema(path, createNoteSchema);
  });

  protected async add(event: Event): Promise<void> {
    event.preventDefault();
    await submit(this.noteForm, async () => {
      await firstValueFrom(this.#http.post('/api/notes', this.draft()));
      this.draft.set({ body: '' });
      this.notes.reload();
    });
  }
}
