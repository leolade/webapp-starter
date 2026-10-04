import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Status } from './status';

describe('Status', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideHttpClient(), provideHttpClientTesting()] });
  });

  it('shows the API state once the response arrives', async () => {
    const fixture = TestBed.createComponent(Status);
    TestBed.tick();
    TestBed.inject(HttpTestingController).expectOne('/api/health').flush({ status: 'ok', uptimeSeconds: 42 });
    await fixture.whenStable();

    expect((fixture.nativeElement as HTMLElement).textContent).toContain('API is ok');
  });

  it('reports an unreachable API', async () => {
    const fixture = TestBed.createComponent(Status);
    TestBed.tick();
    TestBed.inject(HttpTestingController).expectOne('/api/health').flush('boom', { status: 500, statusText: 'Server Error' });
    await fixture.whenStable();

    expect((fixture.nativeElement as HTMLElement).querySelector('[role="alert"]')).not.toBeNull();
  });
});
