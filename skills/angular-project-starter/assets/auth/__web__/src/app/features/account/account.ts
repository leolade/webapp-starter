import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { Auth } from '../../core/auth/auth';

@Component({
  selector: 'app-account',
  template: `
    <section aria-labelledby="account-heading" class="mt-6">
      <h2 id="account-heading" class="text-lg font-medium">Account</h2>
      <p>Signed in as {{ auth.user()?.email }}</p>
      <button type="button" (click)="signOut()" class="mt-3 rounded border px-3 py-1">Sign out</button>
    </section>
  `,
})
export class Account {
  protected readonly auth = inject(Auth);
  readonly #router = inject(Router);

  protected async signOut(): Promise<void> {
    await this.auth.signOut();
    await this.#router.navigateByUrl('/login');
  }
}
