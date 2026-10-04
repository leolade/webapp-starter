import { computed, Service, signal } from '@angular/core';
import type { SignIn, SignUp } from '@{{scope}}/shared';
import { createAuthClient } from 'better-auth/client';

export interface AuthUser {
  id: string;
  name: string;
  email: string;
}

/**
 * Session state for the whole app. The session itself is an HTTP-only cookie (same origin as the API),
 * so there is nothing to store here: `user` mirrors what the server says.
 */
@Service()
export class Auth {
  readonly #client = createAuthClient();
  readonly #user = signal<AuthUser | undefined>(undefined);

  readonly user = this.#user.asReadonly();
  readonly isSignedIn = computed(() => this.#user() !== undefined);

  /** Reads the current session from the server. Never throws: an unreachable API simply means "signed out". */
  async refresh(): Promise<void> {
    try {
      const { data } = await this.#client.getSession();
      this.#user.set(data ? { id: data.user.id, name: data.user.name, email: data.user.email } : undefined);
    } catch {
      this.#user.set(undefined);
    }
  }

  async signIn(credentials: SignIn): Promise<void> {
    const { error } = await this.#client.signIn.email(credentials);
    if (error) throw new Error(error.message ?? 'Sign-in failed');
    await this.refresh();
  }

  async signUp(details: SignUp): Promise<void> {
    const { error } = await this.#client.signUp.email(details);
    if (error) throw new Error(error.message ?? 'Registration failed');
    await this.refresh();
  }

  async signOut(): Promise<void> {
    await this.#client.signOut();
    this.#user.set(undefined);
  }
}
