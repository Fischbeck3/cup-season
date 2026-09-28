# Web capture coverage

Code baseline: `5fabf861c4bee83e2492769f8e76ab3f9cda8281`. 297 outputs; 38 screenshot states. All four widths in both themes unless a reduced-viewport proxy or fixture gap is named.

Server: 127.0.0.1:8792; 8791 belongs to another checkout and was left untouched. No real account used, no live account writes, Supabase network requests aborted. New isolated browser context per state; workers blocked and caches cleared.

Instrumentation: local response-only bridge exposes the existing `showWelcome` function, so synthetic identity enters the actual empty shell. The shipped `csHomeState` loader resolves date tokens. Product CSS/functions and on-disk source are unchanged.

Home fixture scope: existing fixture source only supplies dispatch, profile, and a few ranker inputs; unrelated populated-account read models are absent. Treat Home captures as that state scope, not complete populated-account density evidence.

Book synthetic SQL fixtures contain names matching known pilot people. Name-bearing views were withheld entirely; no renaming/new fixture data was used.

Screenshot capture is not human usability, screen-reader, real software-keyboard, or device behavior evidence. `short-viewport` images only resize the CSS viewport.

## Captured states

- 01-launch: door, door-email, door-email-short-viewport, home-brand-new, composer-first-round, composer-short-viewport, post-receipt
- 03-public-round: public-round, public-round-photo, public-round-long, public-round-no-band, public-round-broken-photo
- 04-read-get-support-legal: get, support, legal
- 05-season-book: book-squads, book-squads-receipt, book-squads-race, book-upcoming, book-error
- 02-home-states: home-rounds_no_buddies, home-event_live, home-between_seasons, home-ceremony_night, home-preseason
- 08-app-empty: app-record-empty, app-post-empty, app-compete-empty, app-golfers-empty, app-stats-empty, app-schedule-empty, app-play-empty, app-wizard-empty, app-event-empty
- 06-profile-settings: profile-card-settings, settings
- 07-round-course: round-receipt, course-circle

## JavaScript and geometry

Page exceptions across stored captures: 0; unique: {}.
Console warnings include Supabase lock-option deprecation and expected Playwright worker blocking. Network failures on consented-but-unavailable image are harness-induced and retained in the manifest.

Document overflow >1px: app-compete-empty--375--dark.png +2px, app-compete-empty--375--light.png +2px, app-compete-empty--402--dark.png +2px, app-compete-empty--402--light.png +2px, app-golfers-empty--375--dark.png +2px, app-golfers-empty--375--light.png +2px, app-golfers-empty--402--dark.png +2px, app-golfers-empty--402--light.png +2px

## Not captured, not scored

- book-tie: legacy pilot names visible; screenshot withheld
- book-finished: legacy pilot names visible; screenshot withheld
- claim and named invite recipient states: No safe deterministic recipient fixture found in reused browser harnesses; not captured, not scored
- legacy demo-only families / populated season, live round, event, draft, pot, bag, H2H: Legacy demo names are explicitly pilot crew; no new synthetic fixture authored. Missing states not captured, not scored.
- real keyboard, VoiceOver, actual device behavior: Headless Chromium captures prove CSS geometry only; keyboard images use a reduced viewport proxy, not an iOS software keyboard.
- home-buddies_no_competition: Existing synthetic fixture uses a name matching a pilot identity; screenshot excluded entirely without rewriting fixture.
- home-event_ahead: Existing synthetic fixture uses a name matching a pilot identity; screenshot excluded entirely without rewriting fixture.
- home-inactive: Existing synthetic fixture uses a name matching a pilot identity; screenshot excluded entirely without rewriting fixture.
- home-invited: Existing synthetic fixture uses a name matching a pilot identity; screenshot excluded entirely without rewriting fixture.
- home-callout_pending: Existing synthetic fixture uses a name matching a pilot identity; screenshot excluded entirely without rewriting fixture.
- home-round_morning: Existing synthetic fixture uses a name matching a pilot identity; screenshot excluded entirely without rewriting fixture.
- home-round_evening: Existing synthetic fixture uses a name matching a pilot identity; screenshot excluded entirely without rewriting fixture.
- home-after_golf: Existing synthetic fixture uses a name matching a pilot identity; screenshot excluded entirely without rewriting fixture.
- home-after_golf_wire: Existing synthetic fixture uses a name matching a pilot identity; screenshot excluded entirely without rewriting fixture.
- home-round-records: Existing synthetic fixture uses a name matching a pilot identity; screenshot excluded entirely without rewriting fixture.

## Independent visual verification correction

The eight app-record-empty files resolve to Play, not History. They are invalid as History evidence and excluded from scoring, representative images and the combined gallery. Thus297 produced outputs include289 usable outputs and8 wrong-route exclusions. Book receipt-named captures remain the overview, so selection behavior is not proved.
