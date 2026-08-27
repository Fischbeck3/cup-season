# IOS-001 · Full Product & Feature Audit

*2026-08-27 · Phase 1 artifact · read-only audit of `index.html` (17,767 lines), 113 migrations, 6 Edge Functions, the RPC snapshot (156 callable functions), the specs, and the existing native work. Evidence: nine slices in `docs/ios/audit/`, every claim line-number-cited there.*

This document is the summary and the **parity matrix** (§6). It does not repeat the slices; it points at them.

---

## 1. What Cup Season is — corrected against the directive

The directive was written in the vocabulary of a generic league app (next match, opponent, match approaching, scheduling). Cup Season's actual model, from `spec/spec-v1.0.md` and the code:

```
POST a round (anywhere, any day) → SCORE it (differential → PvI → 12/9/7/6/5 band)
  → COUNT it (best N per calendar month; floors; auto-bye)
  → RANK squads (points race + ledger) → CROWN (four-week Cup Final or the table)
```

- **There is no fixture list and no "next opponent."** Head-to-head months (Format B) were retired by D48. The only *scheduled* opponent in the product is a **Ryder duel** inside a standalone event; Home never shows it today. Four objects can honestly be called a match — the tee-sheet game (created on the first tee), the Ryder duel, the Major (no opponent), the retroactive weekly clash (audit 04 §1). → IOS-008.
- **A social graph exists** ("buddies", D80), plus a cross-league Home stream, a "since you were here" digest, six named reactions, comments on round posts, a per-league board that is the product's spine (audit 05).
- **Every competitive number is computed in Postgres** — `score_round()`, `cup_points()`, `v_rounds_ranked`, `v_squad_standings`, `close_month()`, `close_season()`, `resolve_session()`, `settle_major()`. The client previews and renders; nothing on any surface computes standings, index, pot or settlement as truth (audit 03, 06, 07).
- **Money is a ledger, never held** (D39): buy-ins are booleans the Pro ticks; payouts are `season_payouts` rows written once at close; Stripe is parked; no purchase UI in any app (D98).
- **Identity is checked at the database** (D37): `anon` has zero relation privileges and exactly ten SECURITY DEFINER endpoints; every client-called RPC needs an explicit grant.

## 2. What the web has, by domain

| Domain | Live on web | Specced but unbuilt | Slice |
|---|---|---|---|
| **Auth & onboarding** | Email OTP, 8 digits, code-only; reviewer door; card gate on marker + handle (no default marker); once-per-device orientation; invite/claim intents survive the OTP round trip | — | 01 |
| **Profile & handicap** | Global profile; WHS-lite index from the best of the last 20 differentials, NULL until 3 rounds ("n of 3"); manual starter refused once established; handle rules (60-day, announced); GHIN as reference; discoverability tri-state; avatars with the marker as floor; per-league marker; tombstone-vs-hard delete | spec §5 caps (rise cap, max 30, monthly revision) | 01, 03 |
| **Leagues & seasons** | Create → wizard (3 steps, ~12 dials, presets) → lock → join by code/covenant/invite → blind draw or Pro assign → start; weekly snapshots, month closes with floors/auto-bye, Cup Final at `ends_on−27` (dial: cup final or table), 48h grace, crown with the §14.3 ladder, trophies, payouts, ceremony, run it back; D71 consent-gated cancellation | snake / live draft engines (schema ready); late-joiner proration; first-tee post (`kicked_off` dead); mid-season remove; points override with reason; reversible ledger | 02 |
| **Rounds & scoring** | Two-box post (front/back), opt-in par-prefilled stepper, course search (GolfCourseAPI cache-first) + tee pick with per-hole par/SI, scorecard scan (Claude vision, capped, fail-closed) with partner claim links, photos, finish ceremony + epilogue + share card/link, receipts behind every figure, delete (owner only), scheduled rounds with RSVP/comments/weather | commissioner void; "Mark This"; sim rounds (constraint forbids); Stableford/quota engine | 03 |
| **Live games** | Tee sheet: Match Play (singles/2v2/round-robin), Wolf (comeback rule), Skins (carry), Sunningdale (tested); group-phone sync (LWW, broadcast, durable local queue); guest pencil + claim; settlement card + post + D78 hole strip; visitor rounds | Nassau/presses; mid-round milestone posts; wolf dials (carries, blind) | 04 |
| **Events** | The Ryder (sessions, auto pairings, bench rotation, number to beat, opt-in taunts, clinch, MVP, lineage series); the Major (window, field, exhibition, countback, 60/25/15 or WTA, jug card, annual lineage); rivalries (weekly clash + duel facets, named) | Bracket; Ryder buy-in/settlement; captains-pick draft; D52 weekly clash spotlight; Callout | 04 |
| **Social** | Board (chat/round/moment/announce/system), reactions, comments, mutes (RLS-enforced), buddies, Tour Card, invites, Home stream + digest, share cards/links with OG previews, trophy case with engraver, achievements, Last Round With | Push for invites/reactions; event-board realtime; cross-device seen cursor | 05 |
| **Notifications** | Web push (VAPID) + dormant APNs branch, three webhooks, curation by `notify_rounds`/`notify_chat`/`notify_target`; Ryder taunts; tee-sheet doorbell; season recap + cancellation + buddy-request email via Brevo; one-way tokened unsubscribe | Deep-linked payloads; mute-aware sending; system-post curation | 05, 07 |
| **Money & admin** | Pot (stake × roster, split presets), Pro mark-paid, forfeits (never dollars), ceremony, career earnings, D71 cancellation with refund notice, Pro tools (index, bye, remove-in-setup, transfer, announce, finish dial), founder desk (stats, reports, feedback, field note), sandbox league, `app_flags` kill switches, telemetry | Pricing / membership (D56 visible model, no checkout); report resolution UI; override tool; `commissioner_log` reader | 06 |
| **Design & IA** | 34 tokens single-sourced (preflight check 10); charcoal-first; two metals + heat axis; three type voices; the Forge; storytelling standings; 14 markers; four places (Home · Clubhouse · ⊕ · You); the voice | A type scale; Dynamic Type; AA contrast on the `dim` tier; a navigation stack | 08 |

## 3. What the iOS app currently has

`apps/mobile/` — an Expo SDK 56 / RN 0.85 / expo-router scaffold, **uncommitted**: OTP sign-in (through `packages/db/auth.ts`, which makes magic links and 6-digit inputs unrepresentable), chunked-Keychain session storage, AppState-driven token refresh, a theme adapter that converts the 34 tokens without inventing a colour, and one Home screen that calls one typed RPC (`tour_card`). Preflight 14/14, `tsc` clean, doctor 21/22 (Hermes regression pending SDK 57), iOS bundle builds. **The B1 gate (a real sign-in on the owner's iPhone) is not evidenced**; the only build-to-device attempt failed on code signing ("no team set"). `ios-wrapper/` is the abandoned Capacitor shell (D98). Slice 09.

## 4. The backend at a glance

47 tables and 6 views across identity, leagues/seasons, rounds/scoring, live games/events, social, money, ops · **156 callable RPCs** (10 anon) · 13 triggers on `rounds`/`seasons`/`events`/`profiles` · 4 pg_cron jobs (Phoenix-pinned) · 5 Database Webhooks (dashboard-only) · 6 Edge Functions (`courses`, `weather`, `scan`, `push`, `season-email`, `test-seed`) · 2 storage buckets (`media` private, `shared` public) · realtime on 8 tables with live scoring over broadcast. Full map with every column: slice 07. **Gaps for a native client** (07 §12): no bootstrap RPC (Home is ~10 reads), no deep-link data in pushes, no `round_holes` read path, the direct `rounds` insert, no version gate, `close_month` re-granted to everyone, `device_tokens.platform` iOS-only.

## 5. Status vocabulary for the matrix

| Mark | Meaning |
|---|---|
| ✅ | Port as-is — the web behaviour is right; native re-presents it |
| ✦ | Port, improved — native pattern replaces the web's (IOS-004 says how) |
| ⏳ | Needs a backend change first (IOS-009) |
| ⚑ | Carries a decision (`DECISIONS.md`) |
| 🖥 | Desk surface per D98 / IOS-007 — phone reads, does not author |
| — | Unbuilt on web too; not in the iOS scope unless decided |

## 6. Feature-parity matrix

WEB FEATURE → iOS EXPERIENCE → DATA SOURCE → BUSINESS LOGIC (where it lives) → STATUS

### 6.1 Identity

| Web feature | iOS experience | Data source | Business logic | Status |
|---|---|---|---|---|
| The door: email → 8-digit code | Forge once per device; native fields; code autofills from Mail; no reload after verify | `auth.signInWithOtp`/`verifyOtp` (code-only) | Supabase Auth + Brevo; 8 digits; resend retires older codes | ✦ |
| Reviewer door (`reviewer@cupseason.app`) | Same hidden password path | `signInWithPassword` | App Review only | ✅ |
| Invite code before sign-in | Same: validate by code, then email | `league_by_code` (anon) | — | ✅ |
| Golfer card gate (name, handle, marker, index?, GHIN?) | Three-step native flow with haptic marker pick; photo offered at the marker step | `set_handle` then `set_profile` | Gate on `marker` AND `handle`; no default marker; handle rules server-side | ✦ ⏳ (`handle_available`) |
| Orientation (four places) | One screen, once per device | UserDefaults | D82 | ✅ |
| Your card (edit name/city/home/marker/photo/handle/discoverable/GHIN) | Its own screen under You | `set_profile`, `set_handle`, `set_discoverable`, storage `{uid}/avatar.jpg` | `set_profile` null-keeps; '' clears GHIN/photo; 60-day handle cooldown | ✦ |
| Handicap index ("n of 3", starter, engine handoff) | Same copy; refusal shown as information | `profiles.index_current`, `handicap_index`, `set_index` | WHS-lite in `handicap_index_asof`; `round_refresh_index` | ✅ |
| Avatars with the marker floor; per-league marker | Same rule; native image pipeline (HEIC → 512² JPEG) | `media` signed URLs, `set_league_marker` | `can_see_media`; no silhouette state | ✅ |
| Settings: notifications, appearance, email recap, sign out | Native settings screen; APNs toggle honest about system permission | `set_notify_*`, `set_email_recap`, `register/unregister_device_token` | server flags | ✦ |
| Delete account (two-step; tombstone vs hard) | Same, meeting 5.1.1(v); blocker message with a link to the league | `delete_account` | server decides; loud FK failure | ✅ |
| Legal (privacy, terms, pot) | In-app browser to `cupseason.app/legal.html` | static | — | ✅ |
| Mute / report photo | Tour Card actions | `set_mute`, `report_content` | RLS-enforced mutes | ✅ |

### 6.2 Home

| Web feature | iOS experience | Data source | Business logic | Status |
|---|---|---|---|---|
| Lifecycle-dispatched hero (leagueless rungs 7/6/5 · forming · preseason · season MOVE · cup final · wrapped) | Same dispatch, hero first | `native_home()` (until then: memberships + views + `standings_snapshots`) | D81 "the standing is a verb"; snapshots for the move | ✦ ⏳ |
| Doors (start league / start event / join) above the hero | `+` in the toolbar; Clubhouse empty state | — | D94 reversed for phone only | ✦ ⚑ IOS-012 |
| Live-round resume/invite banner | First slot; also the Live Activity | `live_rounds` (RLS), `my_visitor_rounds` | D86/D88 | ✦ |
| *(none)* — Ryder duel on Home | "Your match this week" card when a session is open | `event_duels`, `event_session_targets` | D12 noun | ✦ ⚑ IOS-008 |
| Up Next chips (next round, buddy's playing, needs you, month closes) | Same | `my_schedule`, `my_invites`, `league_pulse` | — | ✅ |
| Occasion card (oblique calendar winks) | Same engine, same copy | client calendar | "the wink IS the feature" | ✅ |
| "Since you were here" digest | Same; seen cursor per device (server-side if decided) | `home_feed`, posts, kudos | D27 "an open never reveals nothing" | ✅ ⚑ (cursor) |
| Cross-league stream (Today / This week / Earlier, cap 8) | Paginated list with sections; realtime across all leagues | `home_feed` + posts (→ `home_stream`) | reactions write with the league member id | ✦ |
| Hero/CTA telemetry | Same events + `platform:'ios'` | `client_events` | — | ✅ |

### 6.3 Leagues & seasons (Clubhouse)

| Web feature | iOS experience | Data source | Business logic | Status |
|---|---|---|---|---|
| League switcher (leagues + events) | Toolbar menu | memberships, events | `cs_last_league` → persisted choice | ✅ |
| Standings: sentence, climb, table, movement, split-flap, scenario line | Native animations (matched geometry, split-flap on open); phone table rank · squad · Δ · pts | `v_squad_standings`, `standings_snapshots`, `season_scenarios` | views are truth; never recomputed | ✦ |
| Individual race (Points King / Most Improved / Iron Man) | Segment; in-season labelled as projection; complete seasons read the stored king | `v_individual_standings`, `v_rounds_ranked`, `seasons.points_king_member_id` | client-derived on web (drift risk) | ✦ |
| Squad receipt, member history (counting vs BUMPED) | Pushed detail screens; ledger rows **with reasons** | views, `season_adjustments` | §16 | ✦ |
| Cup Final state | From `seasons.status` + `cup_finalists` (seeds, head start), window race computed from `v_rounds_ranked` | `cup_finalists`, views | web derives from dates; "fresh slate" invisible in views (02 §7.8) | ✦ |
| Trophy Room / ceremony / run it back | Ceremony from `season_payouts`; once-per-member gate | `seasons.champion_*`, `season_payouts`, `career_record` | D66/D67 stored facts | ✦ ⚑ (seen flag) |
| Bylaws card (cap, floor, penalty, allowance, buy-in, split, span, finish) | Read-only card; Pro's endgame dial | `league_settings`, `set_league_finish` | locked by RLS after lock | ✅ |
| Wizard (name, preset, ~12 dials, review, lock) | **Quick-start** (name · preset · stake) on phone; dials + lock on desk | `create_league`, `league_settings`, lock = five client writes | lock should become one RPC | 🖥 ⚑ IOS-007 |
| Join by code + covenant | Native sheet with the fine print | `join_covenant_info`, `join_league` | fail-closed on phone (not fail-open) | ✦ |
| Invite golfers (people picker), pending invites | Share sheet + people picker; Requests screen | `invite_golfer`, `my_invites`, `respond_invite` | no push today | ✦ ⏳ |
| Blind draw / Pro assign / start season | Draw + Start on phone (single RPCs, the appointment moment); assign desk-first | `randomize_squads`, `assign_player`, `start_season` | server validates ≥4 / no unassigned | ✦ ⚑ IOS-007 |
| Draft night (snake/live) | Read-only reveal | `drafts`, `draft_picks` | engines unbuilt on web | 🖥 — |
| Members sheet (starter index, bye, remove, make Pro) | Pocket tools with native confirms | `set_member_index`, `set_member_bye`, `remove_member`, `transfer_pro` | remove = setup only | ✦ ⚑ IOS-007 |
| Season calendar (D93) | Native calendar; reachable from Home and Clubhouse | `my_schedule` | — | ✅ |
| Album | Grid with month dividers | `rounds.photo_path` signed | — | ✅ |
| Cancel/delete league, D71 vote | Vote on phone (arrives as push); request either surface | D71 RPCs | unanimity for money leagues | ✦ |

### 6.4 Rounds

| Web feature | iOS experience | Data source | Business logic | Status |
|---|---|---|---|---|
| ⊕ hub (post / play / plan) | ⊕ opens on Post; Play and Plan one tap away | — | IOS-011 | ✦ |
| Two-box post (front/back, 18/9) | Same door | direct `rounds` insert → `post_round()` | `score_round()` trigger; `rounds_no_future` | ✦ ⏳ |
| Par-prefilled stepper, set the pars, even-par guard | Large stepper rows, haptics, swipe front/back, sticky gross | `round_holes` (write) | `touched` semantics | ✦ |
| Course search + tee pick | Native picker, cache-first, remembered courses | `api_courses/_tees/_holes`, `courses` fn | serve-always cache, 180-day refresh | ✦ |
| Scan the card (Claude vision, caps) | VisionKit capture; confidence per cell; partner claims sheet | `scan` fn, `app_flags.scan`, `create_scan_claim` | fail-closed caps; degrade to typed | ✦ |
| Photo | Native picker, compress on device | `media` | garnish, never blocks | ✅ |
| "How this round scores" preview + bands table | League-lens preview, labelled as preview; league-aware bands sheet | `league_settings` | preview ≠ truth | ✦ |
| Draft restore | Autosave including photo | local | — | ✅ |
| Finish ceremony + POSTED stamp | Same, with `.success` haptic | `round_epilogue` | gold only when points > 0 | ✅ |
| Epilogue (band, rank, achievements, rivals, share) | Same | `round_epilogue`, `create_share` | D57/D60 | ✅ |
| Round receipt (arithmetic row, band, counting, attested, played with) | Pushed screen; opens from cache, enriches | `round_card` | §16 | ✅ |
| Scorecard view | For **every** round with holes (today live rounds only) | `live_round_card` → `round_holes_of()` | RLS bug on `round_holes` | ✦ ⏳ |
| Delete a round | Owner only; index refresh after | `delete_round` (+ `handicap_index`) | immutable otherwise | ✅ |
| Scheduled rounds (declare, RSVP, comments, weather, tags) | Native sheets; Home "next round" | `declare_round`, `set_round_rsvp`, `add_round_comment`, `weather` fn | D69 RSVP for the invited | ✅ |
| Share recap card + link | `ImageRenderer` card + one share sheet (image + text + URL) | `create_share`, `shared` bucket | D77 copy laws | ✦ |

### 6.5 Live games & events

| Web feature | iOS experience | Data source | Business logic | Status |
|---|---|---|---|---|
| Tee sheet setup (course, foursome, court, game, stake, strokes preview) | 3-step sheet; drag-to-swap court; preview as confirmation | `start_live_round` | validation per game; stake locked | ✦ |
| Live scoring (sticky scoreboard, rows, stepper, hole dots) | Game card above rows; swipe holes; haptics; auto-advance | `live_set_score`, `live_set_wolf`, `live_state` | LWW by `client_ts` | ✦ |
| Match Play / Wolf / Skins / Sunningdale engines | Ported pure functions **with test vectors** | client engines → Swift | rules in audit 04 §5 | ✅ |
| Group phones (broadcast + presence + local queue) | SQLite queue, background flush, honest sync state | Realtime broadcast on `join_code`; RPCs | D85 | ✦ ⏳ (batch write) |
| Guest pencil / claim link | Share sheet + QR/AirDrop; Universal Link | `guest_live_*` (anon), `claim_round` | token is identity; `member_id is null` guard | ✦ |
| *(none)* — lock-screen presence | Live Activity / Dynamic Island for the round | `RoundState` | — | ✦ |
| Finish sheet (post / casual) + settlement recap | Native recap; hole strip; share | `finish_live_round`, `live_round_card` | completeness rule; guests never post | ✅ |
| Scrap / abandon; 24h auto-abandon | Same | `abandon_live_round`, tick | — | ✅ |
| Ryder room (scoreboard, sessions, duels, targets, taunts, roster, board) | Native room; realtime + reactions on the event board | `create_event`, `event_*`, `event_session_targets`, `set_event_notify` | `resolve_session`, clinch | ✦ ⏳ (`notify_board`) |
| Major room (leaderboard, field, horn, jug card, lineage) | Native room | `create_major`, `enter_major`, `major_leaderboard`, `settle_major` | countback, 60/25/15 | ✅ |
| Create a Ryder / Major | On phone (small sheets) | `create_event`, `create_major` | Sunday rule server-side | ✅ ⚑ IOS-007 |
| Rivalries (weekly clash + duel facet, name it) | You → Rivalries with receipts | `my_rivalries`, `rivalry_weeks`, `set_rivalry_name` | ISO weeks (02/04 note the Sunday mismatch) | ✅ |
| Personal stakes (D51) | — | no RPC exists | client scaffold only | — |
| Weekly clash spotlight (D52) | — | — | decided, unbuilt | — ⚑ |

### 6.6 Social & notifications

| Web feature | iOS experience | Data source | Business logic | Status |
|---|---|---|---|---|
| Board (chat, round story cards, moments, announce pinned, system rows) | Own screen; keyboard-anchored list; announce sheet for the Pro | `posts` (chat insert direct), `announce` | kinds server-generated | ✦ |
| Reactions (six emoji), comments on rounds | Context menu; inline thread | `post_kudos`, `post_comments` | member id; one write path | ✅ |
| Realtime (open league only) | All memberships, incremental | dedicated realtime client | CHANNEL_ERROR landmine | ✦ |
| Buddies (search, request, respond, list) | You → Buddies; Requests inbox | `search_golfers`, `friend_request`, `friend_respond`, `my_friends` | discoverability | ✅ |
| Tour Card | Pushed screen | `tour_card` | visibility fence | ✅ |
| Trophy case + achievements + engraver | Same, with the engraver | `my_trophies`, `my_achievements` | — | ✅ |
| Career record, Last Round With | Same | `career_record`, `last_round_with` | D63 no push | ✅ |
| Web push (VAPID), permission from Settings only | APNs, contextual ask, categories with actions, badge for actionable only | `register_device_token`, `push` fn | curation flags server-side | ✦ ⏳ |
| Push payload `url:'/'` | Routed payloads | `push` fn | — | ⏳ |
| Ryder taunts (opt-in), tee-sheet doorbell | Same (doorbell gains a mute) | `push_nudges` | — | ✅ |
| Season recap / cancellation / buddy emails | Unchanged (web/email) | `season-email`, `push` fn | D68 unsubscribe | ✅ |
| Share links + OG previews (`?share`) | Consumed via web; never claimed by the app | `share_info` (anon) | AASA excludes `?share` | ✅ |

### 6.7 Money, stats, admin

| Web feature | iOS experience | Data source | Business logic | Status |
|---|---|---|---|---|
| Pot (amount, split, on-the-line bar, payers) | One `PotSummary`; cents end-to-end; "N/M in" chip always | `league_settings`, `buy_ins` | stake × roster (⚑ open question) | ✦ ⚑ IOS-007 |
| Pro marks buy-ins | On phone | `mark_buy_in` | posts the tally | ✅ ⚑ IOS-007 |
| Forfeits (pride ledger) | Same, never dollars | `create/settle/scrap_forfeit` | D64 | ✅ |
| Season ceremony ("you're owed") | From `season_payouts` (web recomputes) | `season_payouts` | D67 | ✦ |
| Career earnings | Same | `career_record` | excludes Major prizes (open) | ✅ |
| Stats: career tiles, form, league table, member history | Three insight surfaces (your number · how you score · where/with whom) | `tour_card`, rounds history, `round_holes` × `api_course_holes` | one definition of "best" (IOS-016) | ✦ ⏳ |
| Founder desk (stats, reports, feedback) | Field note only | `founder_note` | desk | 🖥 |
| Feedback sheet | Same | `submit_feedback` | — | ✅ |
| `app_flags` (scan, courses) | Read on boot; fail-closed | `app_flags` | + `min_ios_build` | ✅ ⏳ |
| Sandbox league, `test-seed` | — | — | founder/QA; `test-seed` ungated (fix) | 🖥 |
| Membership / Pro Shop ("coming at launch") | Read-only plan state once `pricing` flag exists | `app_flags.pricing` (unbuilt) | no purchase UI in any app | — |
| Demo diorama | Not on the phone | — | D83 | ✗ |

## 7. Landmines the iOS build must honour (consolidated)

The slices list ~90; these are the ones that bite a second client first.

1. Never call an auth method synchronously inside `onAuthStateChange`. (01)
2. 8-digit OTP, code-only, no `emailRedirectTo`. (01)
3. Gate onboarding on `marker` AND `handle`, never on row existence; `set_handle` before `set_profile` on the card, the reverse on edits. (01)
4. `set_profile` null = keep; '' clears GHIN/photo; never send `p_index` from the edit sheet. (01)
5. Every client RPC needs its grant; a "silent 403" is a missing grant. Retry on ANY error by dropping optional args — never sniff messages. (07)
6. Realtime on a dedicated client; forward the token on every auth change. (07)
7. `played_on` is a local calendar date; never build dates through ISO parsing. (02, 03)
8. Rounds are immutable; `delete_round` is the only mutation; the client inserts `rounds` directly today. (03)
9. The preview uses 100% allowance; the league lens uses 95/90; band edge at −1.0 differs between server and client — use the server's. (03)
10. `round_holes` are unreadable through RLS for quick-posted rounds. (03)
11. 9-hole tees store the 9-hole rating in both `rating` and `nine_rating`. (03)
12. Two lifecycle columns: route "live" on `phase='season' AND today ≥ starts_on`, "Cup Final" on `seasons.status`; the web uses date arithmetic. (02)
13. There is no server event at first tee (`kicked_off` is dead) — local notification only. (02)
14. `transfer_pro` does not update `leagues.commissioner_id`; `delete_account` keys on it. (02)
15. Late joiners score retroactively; `join_league` has no phase gate. (02)
16. The pot is stake × roster including unpaid and tombstoned members. (02, 06)
17. `close_month` is callable by any signed-in user — never call it; ship the revoke. (02, 06, 07)
18. `game_result` envelope shape is a contract with the server, the share page and the scorecard. (04)
19. `live_round_players.claim_token` defaults on member rows too; the `member_id is null` guard is the only fence. (04)
20. Live finishes stamp `played_on` in UTC; rivalry weeks are ISO Monday-start; Ryder sessions are Sunday-start. (04)
21. Clinch leaves later Ryder sessions unopened; `defender` draw rule is dead. (04)
22. Reactions/comments write with the league **member** id, not the profile id. (05)
23. Mutes hide posts but do not stop pushes; `home_feed` still shows muted members' rounds. (05)
24. `system` posts push unconditionally; `member_id NULL` posts push to the author too. (05)
25. Three copies of settlement arithmetic; render the ceremony from `season_payouts`. (06)
26. Founder identity is one hard-coded email; call `founder_id()`. (06)
27. `handle_new_user` trigger binding exists only in prod, not in any migration. (01, 07)
28. Signed media URLs expire in 1h; refresh on foreground; a non-visible path is a broken image, not an error. (01, 07)

## 8. Bugs and debt found — worth fixing regardless of iOS

- **Security:** `close_month` re-granted to `authenticated` (02 §7.1, 06 §9.1, 07 G9). `test-seed` not founder-gated (06 §9.9). `adj_write` lets a Pro insert silent overrides (06 §9.10).
- **Correctness:** `transfer_pro` / `commissioner_id` (02 §7.2); UTC `played_on` on live finishes (04 §7.4); Ryder clinch orphans sessions (04 §7.1); `set_profile` cannot clear city/home (01 Q2); deleting a round leaves the index and the photo stale (03 §7.7); `season_format` default `'hybrid'` (02 §7.13); `trophies` unique per calendar year (02 §7.15); the engine runs on a league stuck in `draft` (02 §7.3).
- **Promises not kept:** invite "notification" never sent (05); §14.2 "reversible via the log" (nothing can reverse a ledger row); §9 override/void (unbuilt); §14.1 late-joiner proration (unbuilt).
- **Docs drift:** CLAUDE.md says seven anon endpoints; prod has ten (07 G13).

## 9. Open questions

Collected in `DECISIONS.md` → "Open questions surfaced by the audit". Slice-level detail: 01 §7 (14), 02 §9 (15), 03 §10 (13), 04 §10 (10), 05 §10 (13), 06 §11 (12), 08 §8 (14).
