import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Notes } from './notes';

describe('Notes', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideHttpClient(), provideHttpClientTesting()] });
  });

  it('lists the notes returned by the API', async () => {
    const fixture = TestBed.createComponent(Notes);
    TestBed.tick();
    TestBed.inject(HttpTestingController)
      .expectOne('/api/notes')
      .flush([{ id: '6f1f1f4e-3f0a-4a52-9d46-2b0f1f8c9a11', body: 'buy milk', createdAt: '2026-01-01T10:00:00.000Z' }]);
    await fixture.whenStable();

    expect((fixture.nativeElement as HTMLElement).textContent).toContain('buy milk');
  });

  it('shows an empty state', async () => {
    const fixture = TestBed.createComponent(Notes);
    TestBed.tick();
    TestBed.inject(HttpTestingController).expectOne('/api/notes').flush([]);
    await fixture.whenStable();

    expect((fixture.nativeElement as HTMLElement).textContent).toContain('No notes yet.');
  });
});
