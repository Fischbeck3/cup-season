# IOS-004 · Web → iOS Opportunity Map

*2026-08-27 · Phase 1 artifact · status: PROPOSED*

Where iOS should intentionally improve on the web, ranked. Each row states the current web behaviour, the problem, the native change, **what must remain intact** (rules live in Postgres and the decision log, not the client), and whether it needs a backend change. "⚑" marks an item that carries a decision in `DECISIONS.md`.

Sources: the nine audit slices in `docs/ios/audit/`, each of which has an opinionated "do differently" section; this is the merge, prioritised by **product impact × user frequency**.

---

## Tier 1 — the reasons to have a phone app at all

### 1. Home answers "what matters to me right now?" — and never fakes a fixture ⚑ IOS-008

- **Web:** one lane, fixed slot order: doors → hero → tiles → occasion → Up Next → digest → feed. The "make something" doors sit *above* the hero even mid-season (D94's own recorded tradeoff). Home merges ~10 reads on every open.
- **Problem:** the thing that says where you stand is below three buttons; the stream is assembled client-side from six round trips; nothing on Home ever shows a Ryder duel even when one is open.
- **iOS:** the hero leads, dispatched on the same lifecycle the web already encodes (`renderHomeHero`: leagueless rungs 7/6/5 · forming · pre-season · season · cup final · wrapped), with the doors moved to a `+` in the nav bar and the Clubhouse empty state. Slots become: **live-round banner** (resume / "X put you on the tee sheet") → **hero** → **"your match this week"** (only when a Ryder session is open: opponent, number to beat, days left, your best so far — built from `event_duels` + `event_session_targets`, no schema) → **next round** (scheduled_rounds) → Up Next → digest → feed. Cup Season has no fixture list (audit 04 §1); Home must not grow a "next opponent" slot that is empty for 90% of users.
- **Intact:** D27 "an open never reveals nothing"; D81 "the standing is a verb"; the digest's seen-cursor idea; the occasion engine's oblique copy.
- **Backend:** `native_home()` bootstrap RPC (one round trip) — IOS-009.

### 2. Posting a round in under a minute, one-handed

- **Web:** two boxes (front/back) are the door; the par-prefilled stepper is opt-in; course search is a two-stage dropdown; scan is a file input; the "how this round scores" preview trails the form on a phone and uses 100% allowance.
- **iOS:** the ⊕ opens **on the post form** (the 90% case), not a menu of three cards. Native course picker (cache-first, remembered courses on top, tee list with 9/18 badges). Stepper: large par-relative rows with haptic ±, swipe front↔back, sticky running gross, pars prefilled from `api_course_holes` when a tee is picked. Camera-first scan via VisionKit document capture, downscaled on device, unread cells highlighted in the confirm grid. Preview computed **with the league lens** ("9 pts in PIGL · 7 in Sunday Cup"). Draft autosave including the photo. The finish ceremony and epilogue port verbatim.
- **Intact:** two boxes stay the default (D32/D34); `touched` semantics and the even-par guard; every scan failure lands on the two boxes with the exact soft-failure copy; named bands; photo is garnish and never blocks; rating/slope always editable.
- **Backend:** `post_round()` RPC + a `round_holes` read RPC — IOS-009. (Today the client inserts `rounds` directly and the holes of a quick-posted round are unreadable through RLS.)

### 3. The live round as an event: scoreboard in the Dynamic Island, offline by default

- **Web:** the tee sheet is two desktop columns; a phone user scoring Wolf scrolls between the hole and the wolf buttons; sync is a localStorage queue (D85) flushed on visibility; guests join by copying a link.
- **iOS:** one screen per hole is *wrong* for this product (audit 03/04 agree) — keep the per-player rows with a big stepper, add swipe between holes, auto-advance on `holeDone`, and put the game card (match status / wolf / skins) **above** the rows as the sticky scoreboard. **Live Activity** for the round: `2 UP · DORMIE`, skins riding, "YOU'RE THE WOLF · HOLE 12", sync state — deep-links back to the current hole. Wolf pick becomes a prompt sheet at hole start, advisory and always overridable. Offline: SQLite queue, background flush, poisoned-write drop after N tries, honest "2 queued". Guests: share sheet + QR/AirDrop of the `/?claim=` link; a guest who has the app lands on the pencil via Universal Link.
- **Intact:** every engine rule in audit 04 §5 verbatim (port `sunnEngine` with its test vectors; write the same tests for match/wolf/skins); the `game_result` envelope shape; the finish gate (post/casual); LWW-by-writer-clock; token-is-identity for guests with the `member_id is null` guard; the settlement post and D78 hole strip.
- **Backend:** `live_set_scores` batch upsert and idempotent `finish_live_round` (G8) for the drain-on-resume path.

### 4. Push that means something ⚑ IOS-009

- **Web:** VAPID web push, permission asked only from a Settings button, every payload `url:'/'`, every `system` post pushes unconditionally, muting a member doesn't stop their pushes, invites promise a notification and send none.
- **iOS:** APNs first-class (the sender is already written and env-gated — set three secrets). Contextual permission ask after the first meaningful moment (card saved / first post / joined a league), with a pre-permission explainer. Payload carries `kind` + ids so the app routes: round → receipt, settlement → scorecard, chat → board, nudge → live round, request → Requests. Actionable categories: buddy request Accept/Decline, RSVP In/Out, invite Accept. Badge for **actionable items only** (requests + invites + open live rounds — never chat volume). Local notification "session closes tonight — you haven't posted" for open Ryder duels.
- **Intact:** `notify_rounds` / `notify_chat` / `notify_target` / `mutes` / `email_prefs` are server-enforced; the memory-layer guardrails (no engagement bait, no streak shame).
- **Backend:** deep-link fields in the APNs payload; `invite_golfer` → `push_nudges` fan-out; mute-aware recipient filter; a `notify_league_events` flag or `posts.subkind` so system noise can be curated.

### 5. The board and the feed feel alive across all your leagues

- **Web:** realtime only on the *open* league's channel; Home refetches everything on every insert; reactions are a six-emoji strip; the board is a segment inside the Clubhouse and a dialog on desktop.
- **iOS:** the Board is its own screen (a keyboard-anchored chat list with the composer at the bottom; announce is a Pro sheet). Reactions via long-press context menu with the six named emoji. Realtime on `posts` INSERT for **all** memberships, applied incrementally. Home stream cursor-paginated, bucketed Today / This week / Earlier as sections. Share sheet with image + text + URL in one action (the web has to choose files *or* url).
- **Intact:** chat is the only client-writable kind; reactions/comments write with the league *member* id (carry the memberships map); D77 copy laws; D57/D60 "sharing is the publish act".
- **Backend:** `home_stream(p_since)` and `board_page(p_league, p_before)` (G5) — nice, not blocking.

## Tier 2 — the season, legible

### 6. Standings that move

- **Web:** the climb + table stack two screens tall; five columns at 11px; the split-flap and storytelling sentence are excellent and buried.
- **iOS:** the standings sentence leads (serif); the climb is a matched-geometry list that re-orders on open with the split-flap on any rank that moved since the last snapshot; the phone table is rank · squad · Δ · pts; every squad and every number pushes to its receipt (counting rounds, ledger rows *with reasons*, roster). The individual race (Points King / Most Improved / Iron Man) is a second segment.
- **Intact:** §16 receipts behind every figure; the views are the only truth (no client recomputation); scenario line from `season_scenarios`.
- **Backend:** none for the read; a per-row ledger receipt already exists in `season_adjustments` — it just has no UI on any surface.

### 7. Stats that mean something (Memory > Statistics)

- **Web:** four career tiles, a form row, the individual table; "best" means max PvI on one screen and min differential on another.
- **iOS:** three insight surfaces, each with a sentence first: (a) **your number** — the index trajectory from `index_at_post` history with the counting 8-of-20 differentials highlighted and "you need a 78 at Papago to drop 0.5"; (b) **how you score** — per-hole distribution from `round_holes` × `api_course_holes` (par-3/4/5 averages, blow-up frequency, front vs back) — this data is already collected and currently invisible; (c) **where and with whom** — courses played, rounds per course with best, `last_round_with`, rivalries with receipts. No stat that needs extra tracking during play (vision doc "features to reject").
- **Intact:** one definition of "best" (⚑ decide: differential); career math stays server-side (`tour_card`, `career_record`).
- **Backend:** the `round_holes` read RPC (shared with #2).

### 8. Onboarding as a premium first run

- **Web:** door → one long card form (name, handle, index, GHIN toggle, marker grid) → orientation. Photo hidden behind ⚙ on You.
- **iOS:** the Forge (once per device) → email → 8 digits (autofill from the mail notification) → **three steps**: name+handle (live availability) → marker (native selection with haptics, photo offered here: "add a photo — the marker stays your stamp") → optional index/GHIN. Then a one-screen orientation on the four places. Invite/claim intents survive the OTP round-trip exactly as `cs_code`/`cs_claim` do.
- **Intact:** gate on `marker` AND `handle`; no default marker (S1-01); `set_handle` before `set_profile`; the reviewer door for App Review; OTP is 8 digits, code-only.
- **Backend:** `handle_available(p_handle)` (today availability is inferred from a discoverability-filtered search).

### 9. The pot, on the phone, honestly ⚑ IOS-007

- **Web:** three render paths for the pot; the ceremony *recomputes* the split client-side instead of reading `season_payouts`; dollars lose cents at the edge; marking a buy-in is a Pro tap on a name.
- **iOS:** one `PotSummary` from the server (cents end-to-end, always with the "N/M in" chip so the number never reads as cash on hand); the Pro marks buy-ins from the phone — that is where money actually changes hands; the ceremony and "you're owed" render **from `season_payouts`**; the D71 cancellation vote arrives as a push and is answered on the phone. D98 called the ledger desk work; audit 06 §10 makes the case that the *read* and *mark-paid* are phone-first while *overrides* are desk.
- **Intact:** D39 ledger-never-held language on every money surface; `$0` hides the money chrome (D70); the phone never computes money.

### 10. Events (the Ryder, the Major) with a pulse

- **Web:** the room is the right IA; the event board is a static list with no realtime, no reactions; every engine post pushes to every player.
- **iOS:** the room ports; "your match this week" surfaces on Home (#1); realtime + reactions parity on the event board; per-event mute of engine posts; the taunt opt-in stays opt-in; the closing-tonight local notification.
- **Backend:** `event_players.notify_board` (per-event mute).

## Tier 3 — native advantage (after the core is verified)

| # | Opportunity | Why it fits | Cost |
|---|---|---|---|
| 11 | **Widgets** — "where you stand" (rank + move + gap) and "your number to beat" (open duel / month floor) | Principle 5: the app feels alive from the home screen. Data already in `v_squad_standings` / `league_pulse`. | Swift + App Group + a background refresh RPC |
| 12 | **App Clip for the guest pencil** | The claim link is the product's strongest acquisition path; a guest today gets a kiosk web page. | Separate target, ~the `guest_live_*` trio only |
| 13 | **Shortcuts / App Intents** — "Post a round", "Start a live round at <course>" | Zero-friction entry from Siri / the Action button. | Small |
| 14 | **Watch** (D98 Phase E) | Scoring during play. Depends on the round state model being separable — a Phase 2 architecture constraint, not a v1 feature. | Large; timing unfixed by the owner |
| 15 | **Native share cards** rendered with `ImageRenderer` | The canvas code is the spec; native fonts and markers are already bundled. | Medium |
| 16 | **Offline read cache** for Home / standings / schedule | A cold launch on the course shows yesterday's table, not a spinner. | Medium (SQLite) |
| 17 | **Garmin / watch-ecosystem round import** | Strava's actual moat; D98 aside. Server integration. | Later, server-side |

## Deliberately NOT changed on iOS

- The competition model — every rule stays in Postgres. No client computes points, index, pot or settlement as truth.
- Email-OTP-only sign-in (⚑ IOS-010: no Sign in with Apple).
- No purchase UI in any app (D98 cross-store rule). Membership state is read-only on the phone.
- The public claim / join / share pages stay web (the ten anon endpoints); the phone consumes them via Universal Links.
- The wizard's twelve dials, the draft board's pick clock, ledger overrides and the founder desk stay desk work — with the scope carve-outs in IOS-007.
- The memory-layer guardrails: no infinite scroll, no like-counts-as-currency, no vanity metrics.

## Web behaviours the phone must not inherit

Reload-as-navigation (verify / sign-out / delete / transfer-pro) · the 8s boot watchdog string as UX · deploy-skew message sniffing · fail-open covenant when an RPC is missing · localStorage seen-marks and once-per-season ceremony gates · the demo diorama · the inert `.league-only` class · `confirm()` on Remove/Bye/Make Pro.
