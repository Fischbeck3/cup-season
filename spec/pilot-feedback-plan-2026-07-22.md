# Pilot feedback action plan — 2026-07-22

Source: 12 `pilot_feedback` rows (founder dogfooding, 7/19–7/22). Every bug
root-caused in code before this plan; no fix ships without its batch. Order:
B → A → C → D → E → F. Batches A–D land before TestFlight.

---

## Root causes (investigated, not guessed)

| # | Feedback | Root cause |
|---|----------|-----------|
| 1 | Deleted round remains in "This week" | `achievements()` / `round_moments()` trigger posts (kind `moment`) carry **no `round_id`** — the round's own board post cascades (`posts.round_id` FK, 20260712090000), its moment posts orphan. Durable `achievements` trophy rows also have no round link. |
| 2 | Photo attach kicked me out of page | iOS Safari evicts the PWA while the camera/picker is open (memory pressure; full-res HEIC decode in `compressPhoto` raises the odds). Return = full reload; **post sheet has no draft persistence** (tee sheet got local-first resume in v23.174, post sheet never did). Photos invisible because the post died with the eviction. |
| 3 | Ryder/Major sheets slide while scrolling; date selector falls off screen | `.sheet` is `position:fixed` but **body scroll is never locked** and `.panel` lacks `overscroll-behavior:contain` — panel scroll chains to the page behind (slide-around); focusing `input[type=date]` makes iOS scroll the *body* to reveal it, shoving the fixed sheet off-screen. |
| 4 | League can't add people ("My Cup") | Not a regression. Invite link deliberately gated on lock (D40, 7/20) — but the pre-lock league room shows **nothing** instead of "lock first, then invite." Gate exists; legibility doesn't. |
| 5 | Wizard proceeds without a name | "Start a league" fires `createLeague()` **immediately** with scaffold `'My Cup'` (index.html ~12237) — real DB row before any typing. Lock is name-gated (D5); creation isn't. Husk leagues accumulate (his `121b3d0c` = the reported "My Cup"). |
| 6 | Live round didn't pull course API | `attachCourseSearch` is wired to `#inCourse` (post) and `#drCourse` (tee time) only. **`#lrCourse` is a plain text input** — the live-round sheet never touches the courses Edge Function. |
| 7 | Buddy's round finished 10:20am, still open to join 7:57pm | No lifecycle close on `live_rounds`: `status='live'` persists until explicit finish/scrap. Client resume filters at 2 days but the row (and any join surface) stays open forever. Founder dashboard `live_open` counts the same rot. |

Design/mechanic items (no code root cause needed): #8 handles lock? · #9 unify
add-friend with the event picker · #10 friend search bar + recommended · ideas
#11 live-scoring layout + projected score, #12 iOS proximity join.

---

## Batch B — sheet mechanics (client, smallest, touches every mobile session)
- Body scroll lock while any `.sheet` is open: `position:fixed` body with saved
  scrollY, restored on close. `overscroll-behavior:contain` on `.panel`.
- Focused inputs scroll the *panel*, not the body; confirm all sheet inputs are
  ≥16px font (iOS zoom also displaces fixed sheets).
- Verify on iPhone: Ryder create, Major create, tee time (all have date inputs).

## Batch A — data integrity + trust (one migration + small client)
- New migration: `create or replace` `achievements()` (and legacy
  `round_moments()` if still attached) stamping `new.id` as `round_id` on moment
  posts → FK cascade cleans them on delete. Add `round_id uuid references
  rounds(id) on delete cascade` to `achievements` table + stamp it (new rounds).
  D37 discipline: explicit revoke/grant block.
- Live-round lifecycle (decision-log entry first): `daily_season_tick` closes
  `live_rounds` rows `status='live'` with `started_at` older than 24h →
  `status='abandoned'`. Join windows die when the round finalizes or expires.
- Client: after `delete_round`, refresh the home feed too (today only the career
  card reloads).
- One-time cleanup (owner, SQL editor): delete the orphaned moment post he saw;
  delete husk league `121b3d0c` ("My Cup").

## Batch C — league creation flow (client)
- Name gate: "Start a league" asks for the name BEFORE `createLeague()` fires
  (small sheet: name input + Create). No more eager scaffold rows.
- Pre-lock legibility: unlocked league room's people section says "Lock the
  bylaws to open the invite link" with a Lock button — the D40 gate becomes
  visible instead of a dead end.

## Batch D — live-round course wire-up (client)
- `attachCourseSearch('#lrCourse','#lrRate','#lrSlope')` — same widget, same
  cache action. On tee pick, prefill per-hole par/SI into the live stepper from
  `api_course_holes` where cached.

## Batch E — photo arc hardening (client)
- Post-sheet draft persistence: mirror `state.post` form fields (mode, nines,
  hole grid, course, date) to localStorage on change; restore on boot if <24h
  old. Photo blob can't survive eviction — the typed round surviving is the
  point; re-pick the photo.
- Compress smarter: try `createImageBitmap(file,{resizeWidth})` decode-downscale
  where supported; fallback to current path.
- Discoverability: round receipt sheet + You-tab round rows show the photo chip
  (career signed-URL loader already exists ~10122); board story backdrop stays.

## Batch F — people & flows (design pass first, then build)
- One people-picker component: search bar + recommended chips (league mates,
  recent partners, friends) — used by post-a-round tagging, tee sheet roster,
  Ryder/Major rosters. Retires the odd-one-out add-friend flow (#9, #10).
- Handles: decision needed — recommend free edit with 30-day cooldown once set
  (identity stability without support tickets). D-log entry either way.

## Backlog (logged, not scheduled)
- Live-scoring mobile layout: bigger tap targets, leader strip pinned top,
  projected-finish line on both post types. Fold into next tee-sheet UX pass.
- iOS proximity / tap-to-join: parked until the wrapper ships; QR/link join is
  the near-term answer.
