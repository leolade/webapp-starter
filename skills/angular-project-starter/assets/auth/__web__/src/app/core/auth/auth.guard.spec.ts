import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter, Router, type UrlTree } from '@angular/router';
import { Auth } from './auth';
import { authGuard } from './auth.guard';

describe('authGuard', () => {
  const run = (signedIn: boolean) => {
    TestBed.configureTestingModule({
      providers: [provideRouter([]), { provide: Auth, useValue: { isSignedIn: signal(signedIn) } }],
    });
    return TestBed.runInInjectionContext(() => authGuard({} as never, {} as never));
  };

  it('lets signed-in users through', () => {
    expect(run(true)).toBe(true);
  });

  it('redirects anonymous visitors to /login', () => {
    const result = run(false);
    expect(TestBed.inject(Router).serializeUrl(result as UrlTree)).toBe('/login');
  });
});
