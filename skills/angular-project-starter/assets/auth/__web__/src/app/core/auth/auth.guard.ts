import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { Auth } from './auth';

/** Sends anonymous visitors to /login. The session is loaded before the first navigation (see app.config). */
export const authGuard: CanActivateFn = () => (inject(Auth).isSignedIn() ? true : inject(Router).createUrlTree(['/login']));
