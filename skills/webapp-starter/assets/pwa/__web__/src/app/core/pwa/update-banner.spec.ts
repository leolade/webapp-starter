import { TestBed } from '@angular/core/testing';
import { SwUpdate, type VersionEvent } from '@angular/service-worker';
import { Subject } from 'rxjs';
import { UpdateBanner } from './update-banner';

describe('UpdateBanner', () => {
  const versionUpdates = new Subject<VersionEvent>();

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [{ provide: SwUpdate, useValue: { versionUpdates } }] });
  });

  it('is hidden until a new version is ready', async () => {
    const fixture = TestBed.createComponent(UpdateBanner);
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('[role="status"]')).toBeNull();
  });

  it('asks the user to reload once a new version is ready', async () => {
    const fixture = TestBed.createComponent(UpdateBanner);
    await fixture.whenStable();
    versionUpdates.next({
      type: 'VERSION_READY',
      currentVersion: { hash: 'a' },
      latestVersion: { hash: 'b' },
    });
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('[role="status"]')?.textContent).toContain('new version');
  });
});
