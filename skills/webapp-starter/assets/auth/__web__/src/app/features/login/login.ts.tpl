import { Component, inject, signal } from '@angular/core';
import { form, FormField, submit, validateStandardSchema } from '@angular/forms/signals';
import { Router, RouterLink } from '@angular/router';
import { signInSchema } from '@{{scope}}/shared';
import { Auth } from '../../core/auth/auth';

/**
 * Reference form: Signal Forms + the Zod schema shared with the API (`validateStandardSchema`).
 * Copy this shape for new forms: model signal, `form()`, `[formField]` bindings, `submit()`.
 */
@Component({
  selector: 'app-login',
  imports: [FormField, RouterLink],
  template: `
    <section aria-labelledby="login-heading" class="mt-6 max-w-sm">
      <h2 id="login-heading" class="text-lg font-medium">Sign in</h2>
      <form (submit)="onSubmit($event)" class="mt-4 flex flex-col gap-3" novalidate>
        <label class="flex flex-col gap-1">
          Email
          <input type="email" autocomplete="email" [formField]="credentials.email" class="rounded border px-2 py-1" />
        </label>
        @for (problem of credentials.email().touched() ? credentials.email().errors() : []; track problem.kind) {
          <p role="alert" class="text-sm text-red-700">{{ problem.message }}</p>
        }
        <label class="flex flex-col gap-1">
          Password
          <input type="password" autocomplete="current-password" [formField]="credentials.password" class="rounded border px-2 py-1" />
        </label>
        @for (problem of credentials.password().touched() ? credentials.password().errors() : []; track problem.kind) {
          <p role="alert" class="text-sm text-red-700">{{ problem.message }}</p>
        }
        @if (failure()) {
          <p role="alert" class="text-sm text-red-700">{{ failure() }}</p>
        }
        <button type="submit" class="rounded bg-slate-900 px-3 py-2 text-white">Sign in</button>
      </form>
      <p class="mt-3 text-sm">No account yet? <a routerLink="/register" class="underline">Create one</a></p>
    </section>
  `,
})
export class Login {
  readonly #auth = inject(Auth);
  readonly #router = inject(Router);

  protected readonly model = signal({ email: '', password: '' });
  protected readonly credentials = form(this.model, (path) => {
    validateStandardSchema(path, signInSchema);
  });
  protected readonly failure = signal('');

  protected async onSubmit(event: Event): Promise<void> {
    event.preventDefault();
    await submit(this.credentials, async () => {
      try {
        await this.#auth.signIn(this.model());
        await this.#router.navigateByUrl('/account');
      } catch (error: unknown) {
        this.failure.set(error instanceof Error ? error.message : 'Sign-in failed');
      }
    });
  }
}
