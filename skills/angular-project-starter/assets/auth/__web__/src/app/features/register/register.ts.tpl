import { Component, inject, signal } from '@angular/core';
import { form, FormField, submit, validateStandardSchema } from '@angular/forms/signals';
import { Router, RouterLink } from '@angular/router';
import { signUpSchema } from '@{{scope}}/shared';
import { Auth } from '../../core/auth/auth';

@Component({
  selector: 'app-register',
  imports: [FormField, RouterLink],
  template: `
    <section aria-labelledby="register-heading" class="mt-6 max-w-sm">
      <h2 id="register-heading" class="text-lg font-medium">Create an account</h2>
      <form (submit)="onSubmit($event)" class="mt-4 flex flex-col gap-3" novalidate>
        <label class="flex flex-col gap-1">
          Name
          <input type="text" autocomplete="name" [formField]="details.name" class="rounded border px-2 py-1" />
        </label>
        @for (problem of details.name().touched() ? details.name().errors() : []; track problem.kind) {
          <p role="alert" class="text-sm text-red-700">{{ problem.message }}</p>
        }
        <label class="flex flex-col gap-1">
          Email
          <input type="email" autocomplete="email" [formField]="details.email" class="rounded border px-2 py-1" />
        </label>
        @for (problem of details.email().touched() ? details.email().errors() : []; track problem.kind) {
          <p role="alert" class="text-sm text-red-700">{{ problem.message }}</p>
        }
        <label class="flex flex-col gap-1">
          Password
          <input type="password" autocomplete="new-password" [formField]="details.password" class="rounded border px-2 py-1" />
        </label>
        @for (problem of details.password().touched() ? details.password().errors() : []; track problem.kind) {
          <p role="alert" class="text-sm text-red-700">{{ problem.message }}</p>
        }
        @if (failure()) {
          <p role="alert" class="text-sm text-red-700">{{ failure() }}</p>
        }
        <button type="submit" class="rounded bg-slate-900 px-3 py-2 text-white">Create account</button>
      </form>
      <p class="mt-3 text-sm">Already registered? <a routerLink="/login" class="underline">Sign in</a></p>
    </section>
  `,
})
export class Register {
  readonly #auth = inject(Auth);
  readonly #router = inject(Router);

  protected readonly model = signal({ name: '', email: '', password: '' });
  protected readonly details = form(this.model, (path) => {
    validateStandardSchema(path, signUpSchema);
  });
  protected readonly failure = signal('');

  protected async onSubmit(event: Event): Promise<void> {
    event.preventDefault();
    await submit(this.details, async () => {
      try {
        await this.#auth.signUp(this.model());
        await this.#router.navigateByUrl('/account');
      } catch (error: unknown) {
        this.failure.set(error instanceof Error ? error.message : 'Registration failed');
      }
    });
  }
}
