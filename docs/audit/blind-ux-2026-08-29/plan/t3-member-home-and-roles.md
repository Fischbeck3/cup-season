# T3 — The member's Home and roles (takeaway 4 · TOP-3)

Remediation plan for the blind audit's third headline finding: *members are handed the organizer's controls, and no next step.* Scope: the forming hero, the wizard's doors, the server's role and phase gates, one league-state machine for every status string, the member's next step, the Start/Start/Join row, the two dead-end screens, one row per additional league, and the You tab. Everything below was re-read against the working tree at `34d20b6` (== HEAD, byte-identical to prod); every `file:line` is current.

**Traces to:** M-030 (P0), M-033, M-041, M-070, M-072 (P1), M-016, M-021, M-032, M-130 (P2), M-031 (P1, harness artifact — struck; a tooling item only), M-084 (the fabricated "is live" line only), M-138 (the standings row sheet — noted, deferred). Plus the CLAUDE.md rule this theme enforces: *identity is checked at the database, not by hiding a button.*

**Reading order for the builder:** §0 (what the code does today) → §1 (four PROPOSED decisions — nothing in §2 marked "needs D…" is built before its entry is logged) → §2 work items → §7 sequencing.

---

## 0. What the code does today (verified at HEAD)

### 0.1 The four unguarded doors into the Pro's wizard

| Door | Where | Who can walk through it |
|---|---|---|
| The forming hero's CTA `Lock it in and invite your crew` → `toWiz(2)` | `index.html:10096–10102` (branch 4 of `renderHomeHero`, `:10071–10116`) — the only role-ish test is `starter = state.phase==='season'` (`:10076`); `unnamed` / `solo` decide the label | every member of every league not in `season` (setup **and** draft — the normal post-lock, pre-draw window) |
| `switchView('wizard')` | `:4153–4200` — no gate; `:4163` even redirects `draft → wizard` for anyone in setup | anyone |
| `#homeSetup` "Continue" `data-go="wizard"` | `:3408`; `renderPhase` shows `#homeSetup` by phase alone (`:12186`) | every member of a setup-phase league |
| Clubhouse "Squads · View" `data-go="draft"` | `:3553` → `:4163` in setup → wizard | anyone |

Inside the wizard: `#lockBtn` (`:15471–15507`) runs `lockBylaws()` (`:15122–15219`) — four direct table writes plus `form_squads`; the member's `league_settings` update is filtered to zero rows by RLS `settings_write` (baseline `:2313`) *with no error*, and only `form_squads` (`20260711130000:21`) happens to raise `commissioner only`. `#wizCancel` (`:15527–15538`) shows a native `confirm("Cancel this league? … discards it completely.")` to every viewer and calls `delete_league` (refused server-side, `20260712230000:23`). `renderProChip` (`:14101–14110`) stamps whoever is signed in as "THE PRO · you run this league". D40's backstop — the *only* role check on this path — is `enterLeague` (`:14494–14501`).

### 0.2 The server picture

- `join_league` (`20260714040000_join_polish.sql:21–38`) has **no phase gate**: setup, draft, season and complete all accept a code. `respond_invite` (`20260729180000_round_card.sql`, body verbatim above its grant) and `add_friend_to_league` (`20260712050000`) likewise. `invite_golfer` (`20260827210000_push_wave7.sql:55`) gates only the inviter. So D40's premise "members can only join a locked league" is unenforced, and the setup-phase code displays D40 deferred as "harmless" (`#phaseSub` `:12207`, the `#hhCode` chip `:3366`, `#setupInviteSub` `:12840`, `.codebox` `:14412`) are live invitations into the unguarded state.
- The lock itself is not an RPC (see 0.1). T1 owns `lock_league`; this theme depends on it for the *server* half of "a member never locks" and adds the *client* half at the one choke point.
- `randomize_squads` / `start_season` (`20260722210000`) and `delete_league` are commissioner-checked — nothing was ever at risk server-side. The client presented the danger.

### 0.3 The status strings — one league, twelve authors

Every surface hand-derives its own label from `state.phase`. The audit's "five" are rows 1, 2, 5, 6 and 7; the full inventory:

| # | Surface | Lines | Strings |
|---|---|---|---|
| 1 | Home hero eyebrow / line | `:10103–10105` | `forming` · `season live` · "The season's on. *Rounds count from today.*" (fires for phase `season` before first tee — TOP-4's contradiction) |
| 2 | League switcher sheet `switcherChip` | `:15511–15519` (used `:15727`) | `Setup — invites open` (contradicts D40: invites open at lock) · `Squad formation` · `BEFORE FIRST TEE` · `CUP FINAL` · `WK n / N` · `In season` |
| 3 | `leaguePhaseLabel` | `:9797–9802` | `Setup · invites open` · `Squad formation` · `In season · you are the Pro` — **dead code, no caller** |
| 4 | Clubhouse group chips `renderClubGroups` | `:9848` | `Here` · `Your league` · `In season` (regardless of phase) |
| 5 | Room header `#hhPhase` | `:12873–12879` | `Setup — invites open` · `Squad formation` · `Season complete` · `Before first tee — …` · `Cup Final` · `Season live` |
| 6 | `#phaseSub` | `:12207–12216` | `SETUP · CODE X · N JOINED` · `Squad formation · rosters pending` · `BEFORE FIRST TEE · …` · `CUP FINAL · …` · `Wk n / N · …` |
| 7 | League tab `#hubDraftSub` | markup `:3553`, `:12229–12232` | `Complete · rosters locked` (markup default) · `Individual league — no squads` · `OPENS AFTER SETTINGS LOCK` · `LIVE NOW — CAPTAINS READY` (draft-engine vocabulary; no blind-draw league has captains) |
| 8 | `#homeDraft` phase hero | `:3414–3417`, `:12847` | `Squads are forming` · `The Pro has the list.` · `N PLAYERS IN THE POOL · k SEATS OPEN` (M-021: reads as capacity) |
| 9 | Kickoff banner | `:3428`, `:12225` | `SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON` |
| 10 | Board fallback / blank reset | `:14710`, `:11940` | `<league> is live — post the first round` · `<league> is live. Say hello on the board` (pushed regardless of phase) |
| 11 | Standings team cell | `:4692` | `CAPT. —` when no captain exists |
| 12 | `#homeSetup` checklist | `:3407–3411` | `League setup · three steps to first tee` — Pro copy, shown to every member in setup |

The phone has the same problem in fewer places: `LeagueCopy.phaseHeader/phaseSub/squadsSub/kickoff` (`apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/League/LeagueCopy.swift:145–197`, `:188` = `LIVE NOW — CAPTAINS READY`), `LeagueRecord.line` (`You/LeagueRecord.swift:39–40`, `Forming — invites open`), `BoardStore.swift:103–106` (the synthesized "is live" line), `DraftFormation.swift:85` (the developer line). `SeasonPhase` (`Models.swift:180–198`) collapses setup and draft into one `.forming`.

### 0.4 What the member is given instead of a verb

- Home for a member (`screenshots/join/20-P-home-member.jpg`): three equal pills `Start a league · Start an event · Join a league` (`renderHomeStart`, `:9938–9946`, rendered for every account per D81 R2 / D94), the Pro's hero CTA, the tiles, the month-close chip (T4's), the feed. No member verb anywhere.
- "See the squads" (`:12850` relabels the button for members, S3-04) opens `#view-draft` (`:2944–2962`) — no `.backlink` (every other routed view has one: `:2939`, `:2990`, `:3110`, `:3590`, `:3598`); `renderFormation` (`:14843–14905`) gates Draw/Start on `isC` but prints `THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW` and renders the pool as `<button class="mini">` chips that do nothing for a member.
- Clubhouse › Schedule: `setRoomSeg('schedule')` (`:4138–4142`) routes to `view-schedule`, whose only exit is `← Home` (`:3598`) — D93 made the schedule a destination and named "does not restore the Clubhouse segment state" as a tradeoff; seven of seven personas hit it (M-070).
- Home shows exactly one league (`renderHomeHero` picks `CS.league`); the other membership is invisible until visited; `:17536` toasts "Switch groups anytime from Home" although the switcher chips live in the Clubhouse (`#clubGroups`, `:9842`).
- The You tab (`data-v="stats"`, tabbar `:3647`) always renders the profile; M-031 was the harness substring-clicking "Lock it in and invite **You**r crew" (`#homeHero` `:2822` precedes the tabbar in DOM order). No product route change; a tooling fix (T3-12).

### 0.5 What the phone already has

`HomeView.swift:566–568` splits the forming line on `m.isPro` ("Your league is still forming. Lock the bylaws and the invite link is yours." vs "The bylaws lock at the tee.") and offers **no CTA in either case** (`HomeHero`, `:488–590`, has no button). `WizardState.ctaLock` (`Wizard/WizardState.swift:440`) is defined and unused. The iOS wizard is reached only from role-gated views (`StandingsPane.swift:37`, `DraftNightScreen.swift:93`) but the presenter itself (`Presenter.swift:31`, `MainTabView.swift:158` deep link, `ClubhouseView.swift:86`) has no role check. The draft screen already has a Close (`MainTabView.swift:225–232`). The doors are already a menu (`HomeView.swift:93–99`), which is where T3-07 takes the web.

---

## 1. DECISIONS NEEDED (PROPOSED entries for `spec/decision-log.md`)

Numbering: the log's last entry is D110 (+ addendum); D109 is a parked ⚑. These are drafted as **D111–D114**; the theme planners ran in parallel, so renumber at merge. Voice and format follow D107/D110. Items in §2 that "restore" a decision need no entry and say which one.

### D111 · The member's Home — the hero is a role × stage matrix, and the wizard is the Pro's by rule (D40 restored over D96)
*(2026-08-29, blind audit TOP-3 — M-030, M-033, M-041, M-032, M-016. IA + UI level; the hierarchy is the fix. Sources: `renderHomeHero` `index.html:10071–10116`, `switchView` `:4153–4200`, `enterLeague` `:14494–14501`, `#wizCancel` `:15527–15538`, `home-arc.md` §2 row 4, D40 (`decision-log.md:1139`), D96 (`:3422`), iOS `HomeView.swift:566–568`.)*
- **Current mechanic:** D40 (2026-07-20) ruled "a member must never see the Pro's configuration tool" and built it once, as the `enterLeague` route. D96 (2026-08-04) gave the forming hero a CTA — "Lock it in and invite your crew" → wizard step 2 — reasoning only about the abandoned solo Pro; its tradeoffs never mention a member. The hero has no role test and no setup/draft test, `switchView` has no wizard gate, and `home-arc.md` §2 row 4 ("phase setup/draft or pre-starter → Countdown") has neither a role column nor a draft branch. The Start/Start/Join doors lead Home for every account (D94's own "thing to watch in use").
- **Problem observed (audit 2026-08-29):** four of four player personas met the Pro's lock button as the biggest thing on their Home for the whole pre-tee window; two refused to press it for fear of locking the friend's league; one walked "← Back" to a step that named *him* "THE PRO · you run this league" and then a Cancel that offered to "discard it completely" — refused only by the server. The Pro of a league the server had locked was still told "Lock it in". No member persona could say what to do next; every one said they would text the organizer. Members are 80–90% of every league and this is their first week.
- **Recommendation:** (1) The hero is a **role × stage** matrix — one cell per (Pro | member) × (setup | draft | preseason), every cell with a move the viewer can make. Pro/setup keeps D96 unchanged; Pro/draft says "Draw the squads" (+ share the invite link); member cells name the Pro, the date and the member's own next move ("Plan a round" on the D107 tee sheet; "Post a practice round — it builds your number"), reading every number from the bylaws. (2) The D40 guarantee moves to the one choke point: `switchView('wizard')` bounces a non-Pro to Home with "Only the Pro edits the bylaws"; the `draft→wizard` redirect, `#homeSetup`'s Continue and `#wizCancel`'s discard are role-aware; the native `confirm` becomes the in-app sheet. Server-side the guarantee is by construction once T1's `lock_league` lands. (3) A member's "See the squads" is read-only with a back link and member-voiced copy (restores S3-04/D58's intent). (4) **AMENDS D94:** for a golfer with an active membership the three doors collapse to one quiet "Start something…" link; league-less accounts keep the doors leading (D94's reason for leading was the young product's need for *first* leagues, which a member already has). (5) `home-arc.md` §2 row 4 gains the role column and the draft branch so the spec stops describing a role-blind hero.
- **Principle served:** #5 The App Should Feel Alive — "what do I do now?" answered for the member, not only the Pro; #2 Low Friction — the Pro's one-tap lock (D40's mitigation) is untouched; D27 / D81 "a hero with no move is a stall" applied to the people D96 forgot.
- **Expected benefit:** every joiner gets a concrete first action on the day they join — the precondition for the first-round loop; the near-destructive path disappears; the "is this my job?" doubt that four personas logged is gone.
- **Tradeoffs:** the hero grows six cells (mitigated: one dispatcher, a 3 × 2 walk before commit); the member's pre-tee verb depends on T4's season-window sentence being true on the post form (until then the practice link says only "builds your number" and never promises points); the doors' demotion changes Home's opening voice for members (D94 called this the thing to watch — the audit watched it).
- **CONFLICT (named, resolved): D96 vs D40.** D96 put a wizard door on Home without re-reading D40, and D40's premise ("members can only join a locked league") was never enforced (D113). Resolution: D40 wins at the IA level; D96's CTA survives *for the Pro*, and gains the draft branch it lacked. The decision log did not record the regression until now.

### D112 · One league stage, one vocabulary — `leagueStage()` feeds every status string
*(2026-08-29, blind audit M-041, M-021, M-084 (the fabricated line), M-130. UI level with an IA spine; both clients. Sources: the twelve sites in §0.3, `LeagueCopy.swift:145–197`, `Models.swift:180–198`.)*
- **Current mechanic:** the league lifecycle is `leagues.phase` (setup → draft → season → complete) plus `seasons.status` (cup_final, complete) plus the calendar (`atStarter()`, `isCupFinal()`). Twelve renderers each re-derive a label from `state.phase` in their own words; one is dead code, one contradicts D40 ("invites open" in setup), one borrows the retired draft engine's vocabulary ("CAPTAINS READY"), one is pushed regardless of phase ("is live — post the first round").
- **Problem observed:** the same locked, undrawn league read `FORMING` (Home), `Squad formation` (room chip), `SQUADS ARE FORMING · The Pro has the list` (Standings), `Squads · LIVE NOW — CAPTAINS READY` (League tab), `… is live — post the first round` (Board) and `SQUADS LOCKED` (Clubhouse banner) at one moment, while the formation screen showed both squads "Empty". Logged by all six web personas; neither the Pro nor a joiner could say what stage the league was in.
- **Recommendation:** one classic-side `leagueStage()` → `setup | draft | preseason | season | cup_final | complete` (from `state.phase`, `CS.league.phase`, `CS.season.status`, `atStarter()`, `isCupFinal()`; `null` in demo so every demo branch stays), and one `STAGE_LABEL` table with a short and a long form per stage, consumed by every site in §0.3. Proposed vocabulary (owner's call — §6 Q2): **Forming → Squads drawing → Before first tee → Season live (Week n of N) → Cup Final → Season complete**; solo leagues skip "Squads drawing" and never say "squad" (M-130). Retired from status copy: "captains", "LIVE NOW", "SQUADS LOCKED", "invites open", "The Pro has the list", "rosters locked/pending". Seat counts read the structure's minimum ("1 in · need 4 to tee off"), never "seats open". The board's empty line is stage-aware and never says "post the first round" before first tee. The phone's `LeagueStage` is the same enum with the same table (D100 parity), and `SeasonPhase.forming` splits into setup and draft.
- **Principle served:** §16 every number shows its work (a stage word is a number's frame); #2 fewer words for one fact; D47's one-noun discipline; §15 — captains are "an optional label until the Final captain-playoff needs them", and D105 retired that playoff, so the word leaves status copy.
- **Expected benefit:** the five-way contradiction collapses to one string; the Pro can answer "is setup done?" and the member "what stage are we in?" from any screen.
- **Tradeoffs:** ~12 web renderers and 5 iOS copy functions touched in one pass (mitigated: pure-function tests for `leagueStage()` in `tests/app-tests.js` and the existing `LeagueRoomTests`); the iOS tests that pin today's strings (`LeagueRoomTests.swift:313–323`, `RoundsYouTests.swift:194–195`) are rewritten, not deleted.
- **CONFLICT:** none upward. Corrects two lower-level contradictions of D40 ("invites open") and §15/D105 ("captains").

### D113 · Membership opens at lock — `join_league`, `respond_invite` and `add_friend_to_league` refuse a setup-phase league (D40's premise becomes a server rule)
*(2026-08-29, validators' finding on TOP-3; touches TOP-2's consent surface. Mechanic level (who may join when). Sources: `20260714040000_join_polish.sql:21–38`, `20260729180000_round_card.sql` (`respond_invite`), `20260712050000_add_friend_to_league.sql`, `20260827210000_push_wave7.sql:55`, D40 `decision-log.md:1139–1170`, the "Add golfers always works" pilot fix `index.html:3373–3376`.)*
- **Current mechanic:** D40 says "members can only join a locked league" and "the public share link/code moves to AFTER lock", but the code accepts a join in every phase; the code is printed in setup on three surfaces; a Pro who texts the code early seats friends in an unlocked league whose bylaws — including the buy-in — can still change under them.
- **Problem observed:** D40's routing backstop is load-bearing and the hero walks around it (D111). Independently: the join covenant (S3-01) asks a joiner to consent to a stake that, pre-lock, is not yet fixed — consent to a moving target (TOP-2's finding sharpens here). A finished league (`complete`) is also joinable by code today.
- **Recommendation:** one migration. `join_league` raises in phase `setup` with a plain sentence the client passes through verbatim — "*<League> isn't open yet — the Pro is still setting the bylaws. Try the link again once it's locked.*" — and in phase `complete` — "*That season is finished — ask the Pro to run it back.*"; `respond_invite` (league invites) and `add_friend_to_league` get the same setup gate. `invite_golfer` is **unchanged**: the Pro may stage invites pre-lock (the row waits in `my_invites`; accepting it before the lock returns the same sentence). The three setup-phase code displays hide (`#phaseSub`, `#hhCode`, `#setupInviteSub`) — the follow-up D40 deferred. `join_covenant_info` (T2's item) returns `phase` so the door can say "not open yet" *before* the OTP round-trip. D37 discipline: explicit revoke from `public, anon`, grant to `authenticated`, on all three.
- **Principle served:** correctness > early seat-fill (D40's own line); S3-01 — a covenant is consent to fixed terms; §7/D106 — the pot's "owed" number is the roster, and a roster that can exist before the stake is fixed makes "owed" a guess.
- **Expected benefit:** every member of every league joined a locked league, so D111's member cells always have dates to show; no joiner ever consents to $50 and finds $75 at lock; the pilot's "joined a My Cup scaffold" confusion becomes impossible by construction rather than by routing.
- **Tradeoffs:** a Pro who has already shared a pre-lock code sends friends into a refusal — the sentence names the fix and the Pro's Home (D96/D111) says "Lock it in" until they do; no seat-filling before the lock (D40 accepted this; `openLockShare` hands over the link one tap later). §15's late-joiner rule ("assigned to the thinnest squad, logged") is *not* built for joins after `start_season` — out of scope here and flagged (§6 Q5).
- **CONFLICT (named):** the pilot fix "an unlocked league showed no add path at all — this button always works" (`index.html:3373–3376`, "Add golfers"). Resolution: inviting still always works; *becoming a member* waits for the lock. **Alternative for the owner (§6 Q1):** allow pre-lock joins and land them on D111's member/setup cell, with the covenant stating "the bylaws aren't locked yet — the Pro can still change them." Recommended: the gate, because the consent problem is real and D40 already chose it.

### D114 · Home shows every league — one hero, a compact row per additional league (amends D81 R2 / D94)
*(2026-08-29, blind audit M-072 (A7, the only tester living two real leagues). IA level. Sources: `renderHomeHero` `:10015–10018` (picks `CS.league`), `loadMemberships` `:14331–14339`, the toast `:17536`, `renderClubGroups` `:9842–9855`, iOS `HomeMode.of` `Models.swift:200–212`.)*
- **Current mechanic:** D81 made Home one hero slot; D94 kept it and added the tiles. The hero renders the *loaded* league (`CS.league` — the last one entered, or `cs_last_league` at boot); the other memberships exist only as Clubhouse switcher chips. Boot toasts "Switch groups anytime from Home", which is false — the switcher is in the Clubhouse.
- **Problem observed:** the observer's second league, and the 10-point deficit that should pull him back, was invisible until he happened to open it ten minutes in. Two-league golfers are the founding-league reality (PIGL + a buddy's league).
- **Recommendation:** keep the single hero (D81/D94 stand). Directly under it, one compact row per *other* active membership: `name · stage (D112 short) · your standing when in season · "you are the Pro"`; tap → `enterLeagueById(id)` and Home re-renders around that league. `loadMemberships` embeds the season (`seasons(status,starts_on,ends_on)`) so a row's stage needs no room load; standing for un-loaded leagues can ride `native_home` later (the phone already carries `Membership.standing`). The false toast goes. On the phone, `HomeMode.of` keeps choosing one membership and the same rows render beneath `HomeHero`.
- **Principle served:** #5 alive — the deficit in the other league is the thing that changed while you were away; #2 fewer doors — the row *is* the switcher, so the toast's promise becomes true instead of being deleted.
- **Expected benefit:** a golfer in two leagues sees both standings on the first screen; "switch from Home" is finally where it says it is.
- **Tradeoffs:** ~48px per extra league above the tiles (rows cap at three, then "and N more → Clubhouse"); the `seasons` embed is one more field the skew-retry must be able to drop.
- **CONFLICT:** none — amends D94's "one hero" by *adding beneath* it, not by a second hero; D81's "feed stays whole" is untouched.

---

## 2. WORK ITEMS

Effort: **S** ≤ 2h · **M** ≤ 1 day · **L** multi-day. Deploys: the owner runs `supabase db push`; `git push` ships the client; iOS builds locally (rule 6). Every item names its verification and its parity item.

### Summary

| id | title | layer | effort | needs | deploy |
|---|---|---|---|---|---|
| T3-01 | Gate the wizard at the choke point; Cancel and Lock know the viewer | client | S | — (restores D40) | client push |
| T3-02 | The hero as a role × stage matrix | client | M | D111, T3-03 | client push |
| T3-03 | `leagueStage()` + `STAGE_LABEL`, every status site rewired | client | M | D112 | client push |
| T3-04 | Membership opens at lock (join/respond/add gates) + hide setup code displays | db-migration + client | S + S | D113, T1 `humanError` pass-through | db push + client push |
| T3-05 | Members' formation screen: read-only, back link, plain copy, honest seat count | client + copy | S | — (restores D58 / S3-04) | client push |
| T3-06 | Schedule returns to where you came from | client | S | — (within D93) | client push |
| T3-07 | The doors demote for members | client | S | D111 (4) | client push |
| T3-08 | A compact row per additional league; the false toast goes | client | M | D114 | client push |
| T3-09 | The wizard names the league it is editing; in-app cancel sheet | client + copy | S | D111 (2) | client push |
| T3-10 | Telemetry: role + stage on the hero events, gate bounces, join refusals | telemetry | S | — | client push |
| T3-11 | `home-arc.md` §2 row 4 gains role × draft; IOS-028 parity record | spec | S | D111 | — |
| T3-12 | Harness click resolution + `leagueStage` tests | tooling | S | T3-03 | — |
| T3-P1 | iOS `LeagueStage` + one label table (LeagueCopy / LeagueRecord / DraftFormation / BoardStore) | ios | M | D112 | iOS build |
| T3-P2 | iOS HomeHero matrix with CTAs; `ctaLock` for the Pro only | ios | M | D111, T3-P1 | iOS build |
| T3-P3 | iOS presenter role guard on the wizard | ios | S | D111 | iOS build |
| T3-P4 | iOS additional-league rows under the hero | ios | S | D114, T3-P1 | iOS build |
| T3-P5 | iOS Board/Schedule: one title per screen | ios | S | — | iOS build |
| T3-P6 | iOS telemetry parity for T3-10 | ios | S | T3-10 | iOS build |

### T3-01 · Gate the wizard at the choke point; Cancel and Lock know the viewer
- **Layer:** client · **Effort:** S · **Deploy:** client push · **Issues:** M-030, M-016 (wizard part) · **Restores:** D40 — no new decision (D111 records the conflict).
- **Files:** `index.html:4153–4165` (`switchView`), `:3408` (`#homeSetup` Continue), `:12186` (`renderPhase` shows `#homeSetup`), `:15471–15476` (`#lockBtn`), `:15527–15538` (`#wizCancel`).
- **Change:** at the top of `switchView`, before the `:4163` redirect, compute `const pro = state.demo || !window.CS?.league || window.CS?.member?.role==='commissioner';`. If `v==='wizard' && !pro` → `qaEvent('wizard_gate_bounce',{from:v})`, `toast('Only the Pro edits the bylaws')`, `v='home'`. Make `:4163` role-aware: a Pro still gets "Lock settings first…" → wizard; a member gets `toast('The Pro is still setting up — squads form after the bylaws lock')` and `v='hub'`. In `renderPhase`, hide `#homeSetup`'s Continue button for non-Pros (`querySelector('#homeSetup [data-go="wizard"]').style.display`). `#lockBtn`'s handler gains an early `if(CS.league && CS.member?.role!=='commissioner'){ toast('Only the Pro locks the bylaws'); return; }` (belt; T1's RPC is the braces). `#wizCancel`'s handler gains the same early return, and its `confirm()` becomes an `openSheet` two-button confirm (T3-09 owns the copy). Keep the `enterLeague` backstop (`:14494–14501`) as is.
- **Verification:** `?exit`, sign in as `jerecho+blind2` (member, The Papago Grind, phase `draft` — or any member account after cleanup). Console: `switchView('wizard')` → lands on Home, toast, one `wizard_gate_bounce` row in `client_events`. Clubhouse → Squads › View in a setup-phase league → toast, stays in the room. `document.querySelector('#homeSetup [data-go=wizard]')` hidden for a member of a setup-phase league. As the Pro (`+blind1`): all three paths behave as today. Console clean.
- **Risk:** none server-side. **Parity:** T3-P3.

### T3-02 · The hero as a role × stage matrix
- **Layer:** client · **Effort:** M · **Deploy:** client push · **Issues:** M-030, M-033, M-041 (hero row) · **Needs:** D111, T3-03.
- **Files:** `index.html:10071–10116` (branch 4 of `renderHomeHero`), `:9998–10000` (`wire`/`seen`), `:12885–12889` (Pro-name derivation to reuse), `:12007` (`STRUCT_MIN`), `:9585` (`capN` from `state.cap`), `:11985–11988` (`daysToTee`, `firstTeeText`), `:16919` (`openDeclareSheet`).
- **Change:** replace the `unnamed`/`solo` dispatch with `const isPro = window.CS?.member?.role==='commissioner'; const stage = leagueStage();` and a six-cell table. Pro/setup: unchanged (Name your league → `toWiz(0,'#setName')`; Lock it in and invite your crew → `toWiz(2)`). Pro/draft: eyebrow `<name> · squads drawing`, figure = days to first tee, line `<n> in · need <STRUCT_MIN[structure]> to tee off · first tee <firstTeeText()>` (or `enough to draw` once ≥ min), CTA **Draw the squads** → `switchView('draft')`, secondary **Share the invite link** → `shareInvite()` (T1 upgrades that function to the invite sheet; the call site does not change). Pro/preseason: eyebrow `<name> · before first tee`, line `First tee <date> · <n> in`, CTA `Share the invite link` while short of the minimum, else **Plan the first round** → `openDeclareSheet(state.seasonStart)`. Member/setup: eyebrow `<name> · forming`, no figure (no season row yet), line `<Pro> is still setting the bylaws · they lock before first tee`, CTA **Open the Clubhouse** → `switchView('hub')`. Member/draft: eyebrow `<name> · squads drawing`, figure days, line `<Pro> draws the squads before <date> · <n> in`, CTA **Plan a round** → `openDeclareSheet()`, quiet link `Post a practice round — it builds your number` → `switchView('record')`. Member/preseason: eyebrow `<name> · before first tee`, figure days, line `First tee <date> · your best <capN> a month count, at least <state.floor>` (solo: drop "squad"; floor 0: drop the clause), same CTAs. `<Pro>` = the commissioner member's `display_name`, fallback "The Pro". The roster bar stays in every cell. `seen(tag)` emits `{state:'forming', stage, role}` (T3-10). Delete the `starter` path's "The season's on. *Rounds count from today.*" (`:10105`) — the preseason cells replace it; T4 owns the post-form sentence.
- **Verification:** the 3 × 2 walk: `+blind1` (Pro; Papago is `draft`) sees "Draw the squads"; `+blind5` (Pro; Desert Dogs is `season`, solo, before first tee) sees "Plan the first round"; `+blind2` (member, draft) sees "Plan a round" and the practice link, names Casey and Sat Sep 5, and `document.querySelector('#homeHero .hh-cta').textContent` never contains "Lock". A fresh Pro in setup still gets D96's two CTAs. `client_events` shows `home_hero_state` with `stage`/`role`. Console clean.
- **Risk:** copy reads bylaws (`state.floor`, `capN`, `STRUCT_MIN`) — never a literal; solo leagues must not say "squad" (M-130). In `setup` there is no season row, so no countdown — say so, never "—". **Parity:** T3-P2.

### T3-03 · `leagueStage()` + `STAGE_LABEL`, every status site rewired
- **Layer:** client · **Effort:** M · **Deploy:** client push · **Issues:** M-041, M-021, M-084 (fabricated line), M-130 · **Needs:** D112.
- **Files:** new helper beside the season helpers `index.html:11963–11996`; call sites `:10103–10105`, `:15511–15519`, `:9797–9802` (delete), `:9848`, `:12873–12879`, `:12207–12216`, `:3553` + `:12229–12232`, `:3414–3417` + `:12847`, `:3428` + `:12225`, `:14710`, `:11940`, `:4692`, `:3407`.
- **Change:** `function leagueStage(){ if(state.demo||!window.CS?.league) return null; if(window.CS.season?.status==='complete'||window.CS.league.phase==='complete') return 'complete'; if(state.phase==='setup') return 'setup'; if(state.phase==='draft') return 'draft'; if(atStarter()) return 'preseason'; if(isCupFinal()) return 'cup_final'; return 'season'; }` (note `enterLeague` maps `complete → season` at `:14397`, so the `CS.league.phase` test is load-bearing, as `renderStats` `:9597` already does). `const STAGE_LABEL = { setup:{k:'Forming', long:()=>'Forming — the Pro is setting the bylaws'}, draft:{k:'Squads drawing', long:()=>`Bylaws locked — squads draw before ${firstTeeText()}`}, preseason:{k:'Before first tee', long:()=>`Before first tee — ${firstTeeText()}`}, season:{k:()=>`Week ${currentWeek()} of ${totalWeeks()}`, long:()=>'Season live'}, cup_final:{k:'Cup Final', long:()=>`Cup Final — ${…} left`}, complete:{k:'Season complete', long:()=>'Season complete'} }` plus `stageLabel(kind)` that resolves functions and returns the demo string when `leagueStage()` is null. Rewire: hero eyebrow; `switcherChip` (keep the `· YOU ARE THE PRO` suffix at `:15727`); delete `leaguePhaseLabel`; `renderClubGroups` chip → `Here` / stage short; `#hhPhase` → long; `#phaseSub` → setup: `FORMING · <n> IN · THE INVITE LINK OPENS AT LOCK` (code hidden per T3-04), draft: `SQUADS DRAWING · <n> IN · NEED <min> TO TEE OFF`, others unchanged in shape but from the table; `#hubDraftSub` → solo: `Individual league — no squads`, setup: `Draws after the lock`, draft: `Drawing — <pool> in the pool`, season+: `Set · <k> squads`; `#homeDraft` k/n → `Squads drawing` / `<Pro> draws before <date> — it's random`; `#draftPoolSub` → `<pool> in the pool · need <min> to tee off` or `· enough to draw`; kickoff `#khCount` → drop `SQUADS LOCKED` (squads: `SQUADS SET`; solo: nothing) and leave the practice half to T4's sentence; board fallback `:14710` and `:11940` → stage-aware (`setup`/`draft`/`preseason`: `<league> opens at first tee — say hello on the board`; `season`: today's line); standings cell `:4692` → when `t.cap` is empty print `<n> GOLFERS` instead of `CAPT. —`; `#homeSetup` eyebrow `:3407` → member sees `Forming — the Pro is setting the bylaws` (no checklist). Add `tests/app-tests.js` cases: `leagueStage()` for the six states (stub `state.phase`, `CS.league.phase`, `CS.season.status`, `state.seasonStart/End`, `state.finish`) and `STAGE_LABEL` has every key.
- **Verification:** the 6-stage walk with real accounts for setup/draft/preseason (`+blind1`, `+blind2`, `+blind5`) and the owner's two leagues for season; `cup_final`/`complete` via `window.CS_HOME_STATE` plus a stubbed `CS.season.status` in the console. On each: Home eyebrow, switcher chip, `#hhPhase`, `#phaseSub`, `#hubDraftSub`, `#homeDraft`, the board's empty line all print the same stage word. Demo mode (`?exit` → Explore) untouched. `app-tests.js` PASS.
- **Risk:** ~12 renderers; do the walk before commit. Demo branches stay because `leagueStage()` returns null in demo. **Parity:** T3-P1.

### T3-04 · Membership opens at lock; the setup-phase code displays hide
- **Layer:** db-migration + client · **Effort:** S (migration) + S (client) · **Deploy:** `supabase db push` (owner) + client push · **Issues:** M-030 (server premise), M-022 (code placement) · **Needs:** D113; T1's `humanError` pass-through for RPC-authored sentences (`index.html:4106–4118`) — ship after it, or the refusal reads as the generic toast.
- **Files:** new `supabase/migrations/<ts>_membership_opens_at_lock.sql` (timestamp after `20260829091000`); bodies copied verbatim from `20260714040000_join_polish.sql:21–38` (`join_league`), `20260729180000_round_card.sql` (`respond_invite`), `20260712050000_add_friend_to_league.sql` (`add_friend_to_league`); client `index.html:12207` (`#phaseSub`), `:3366` + `:12871` (`#hhCode` chip), `:12840–12843` (`#setupInviteSub`), `:14412` (`.codebox`), `tests/db-checks.sql` (new check 15).
- **Change (migration):** in each of the three, after the league lookup: `select phase, name into v_phase, v_lname from leagues where id = v_league; if v_phase = 'setup' then raise exception '% isn''t open yet — the Pro is still setting the bylaws. Try the link again once it''s locked.', v_lname; end if; if v_phase = 'complete' then raise exception 'That season is finished — ask the Pro to run it back.'; end if;` (`respond_invite`: only when `mi.league_id is not null`; event invites untouched). `invite_golfer` unchanged. Then `revoke all on function public.join_league(text) from public, anon; grant execute … to authenticated;` and the same for `respond_invite(uuid, boolean)` and `add_friend_to_league(<its signature>)`. Add db-check 15: `pg_get_functiondef` of all three contains `isn''t open yet` → PASS, else FAIL (the claim self-enforces, the way check 10 does). **Change (client):** in setup, `#phaseSub` prints no code (T3-03's string), `#hhCode`'s chip and `#setupInviteSub`'s `CODE X ·` prefix hide while `leagueStage()==='setup'`, and `.codebox` fills stay (they live in the post-lock share). The join catches (`:15468`, `:15587`, `:17400`) log `qaEvent('join_refused',{reason})` when the message matches (T3-10).
- **Verification:** dry-run `supabase db query --linked "begin; \i <file>; select pg_get_functiondef('public.join_league'::regproc); rollback;"` and read the gate; `node tests/preflight.mjs` check 2/11 pass; after push `tests/db-checks.sql` check 3 still lists all three as granted and check 15 passes. Live: a fresh account opens `/?join=<code of a setup-phase league>` (one of the seven stalled prod leagues D96 measured: `select code from leagues where phase='setup' limit 1`, read-only) → the sentence, no membership row; `/?join=THEPTCQ5` (draft) still joins. As the Pro of a setup-phase league: `#hhPhase`/`#phaseSub` show no code; the code appears on `openLockShare` after the lock (T1).
- **Risk:** D37 grants (explicit in the file; check 3 catches a miss). Deploy skew: an old client against the new gate shows the generic "Could not join" toast until the client with T1's pass-through lands — acceptable for the hours between, unacceptable for days: sequence the pushes in one session. A Pro who already texted a pre-lock code sends friends into the sentence — that is the point. **Parity:** none needed (the phone calls the same RPCs and passes RPC sentences through `AuthRules.human`; T2 owns `join_covenant_info.phase` for the door copy on both clients).

### T3-05 · Members' formation screen: read-only, back link, plain copy, honest seat count
- **Layer:** client + copy · **Effort:** S · **Deploy:** client push · **Issues:** M-032, M-016 (formation part), M-021 · **Restores:** D58's S3-04 ("a member's tap opens a read-only draw view") — no new decision.
- **Files:** `index.html:2944–2946` (`#view-draft` markup), `:14843–14866` (`renderFormation`), `:14877–14881` (pool chips), `:12847` (`#draftPoolSub`), `:12885–12889` (Pro name).
- **Change:** first child of `#view-draft`: `<a href="#" class="backlink" data-go="hub">← Clubhouse</a>` (the `[data-go]` binding at `:12923` runs at load, so static markup routes). In `renderFormation`, when `!isC`: eyebrow `Squads · blind draw` (or `· Pro assign`), the clock's `.m` line → `<Pro> draws the squads before <firstTeeText()> — it's random. You'll see them here the moment they're set.` (the phone's `DraftCopy.memberReadOnly` voice), the pool renders as `<span class="mini">` (no buttons, no `[data-mem]` binding), `#resetDraft` stays hidden. For the Pro, `THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW` → `The draw is random and runs on the server — nobody can rig it.` `#draftPoolSub` per T3-03. `renderFormation` emits `qaEvent('formation_view',{role})` (T3-10).
- **Verification:** `+blind2` → Clubhouse → See the squads: `← Clubhouse` present and returns to the room; no `button[data-mem]` in `#pool`; the sentence names Casey and Sat Sep 5. `+blind1`: Draw squads still renders and still passes the server's own sentence on failure (T1's `humanError` item).
- **Risk:** none. **Parity:** already read-only with Close on the phone (`MainTabView.swift:225–232`); T3-P1 carries the copy line (`DraftFormation.swift:85`).

### T3-06 · Schedule returns to where you came from
- **Layer:** client · **Effort:** S · **Deploy:** client push · **Issues:** M-070 · **Within:** D93 (a named tradeoff, fixed at the UI level — no decision).
- **Files:** `index.html:4138–4142` (`setRoomSeg` schedule branch), `:9890–9891` (the Next tile → schedule), `:4197` (`switchView` schedule branch), `:3598` (the backlink).
- **Change:** `setRoomSeg('schedule')` sets `window._schedFrom='hub'` before routing; the Home tile and any other entry set `'home'`. In `switchView`'s `v==='schedule'` branch, before `renderCalendar()`: `const bl=document.querySelector('#view-schedule .backlink'); if(bl){ const hub=window._schedFrom==='hub' && window.CS?.league; bl.dataset.go = hub?'hub':'home'; bl.textContent = hub?'← Clubhouse':'← Home'; }` — the `[data-go]` listener reads `dataset.go` at click time (`:12923`), so no rebinding. Returning to `hub` lands on the Standings segment (`setRoomSeg` default); the room's chips are back.
- **Verification:** Clubhouse → Schedule → `← Clubhouse` → the room with league chips and segment strip; Home › Next tile → Schedule → `← Home`. Board/Album taps after returning work (the audit's silent failures were the room being gone).
- **Risk:** none. **Parity:** T3-P5 (the phone pushes with a back button already; only titles differ).

### T3-07 · The doors demote for members
- **Layer:** client · **Effort:** S · **Deploy:** client push · **Issues:** M-033 · **Needs:** D111 (4) (amends D94).
- **Files:** `index.html:9930–9950` (`renderHomeStart`), `:15564` (`openJoinSheet`), `:15543` (`openEventPicker`).
- **Change:** `const member = !state.demo && (window.CS?.memberships||[]).some(m=>m.league?.phase!=='complete');` When `member`: render one quiet line `<p class="fine"><a href="#" data-hgmore>Start something — a league, an event, or join with a code →</a></p>` that opens an `openSheet('Start something', '', …)` holding the same three buttons wired to `#wCreate`, `openEventPicker`, `openJoinSheet`; emit `qaEvent('home_doors_open')`. League-less accounts (and the run-it-back card) render exactly as today. The `homeStart` node keeps its D94 position at the head of the lane so nothing else moves.
- **Verification:** `+blind2` Home: no three pills, the quiet line present, the sheet opens all three; a fresh league-less account: the three doors lead. `home_doors_open` appears in `client_events` on tap.
- **Risk:** Home's opening voice changes for members (D94's watch item; this is the answer). **Parity:** none — the phone is already a menu (`HomeView.swift:93–99`).

### T3-08 · A compact row per additional league; the false toast goes
- **Layer:** client · **Effort:** M · **Deploy:** client push · **Issues:** M-072 · **Needs:** D114, T3-03.
- **Files:** `index.html:14331–14339` (`loadMemberships` select), `:10952–10960` (`renderHomeHub` order), new `renderHomeLeagues()`, `:17536` (the toast), `window.enterLeagueById` (module bridge, used at `:9854`).
- **Change:** extend the select to `id, role, index_current, league:leagues(id,name,code,phase, seasons(id,number,status,starts_on,ends_on))` with the skew-retry pattern (drop the embed on any error, as CLAUDE.md requires — never message-sniff). Refactor `leagueStage(m)` to accept an optional membership (phase + latest season + dates) so a row's stage needs no room load. `renderHomeLeagues()` renders under `#homeHero` one `.check.tap` row per other active membership: `name · stageLabel(m) · (role==='commissioner' ? 'you are the Pro' : '')`, capped at three then `and N more → Clubhouse`; tap → `window.enterLeagueById(id,false)` (Home re-renders around the new league; `renderHomeHub` already re-runs on `switchView('home')`). Delete the toast at `:17536`. Standing for un-loaded leagues is a follow-up (ride `native_home`'s `standing`, IOS-009) — the row says the stage now, the rung later.
- **Verification:** the owner's account (two leagues, two players each): Home shows the Fellas hero and a "Who's the bitch? · Week n of N" row; tap → hero swaps, row swaps; no toast at boot. A one-league account shows no rows. Deploy-skew: temporarily rename the embed in the console → the retry returns memberships without seasons and rows still render with the phase-only stage.
- **Risk:** the `leagues → seasons` embed is a single FK path (no ambiguity like the `live_rounds` one at `:7800`), but keep the retry. **Parity:** T3-P4.

### T3-09 · The wizard names the league it is editing; in-app cancel sheet
- **Layer:** client + copy · **Effort:** S · **Deploy:** client push · **Issues:** M-030 (the "Create your league … you run this league" framing), M-016 · **Needs:** D111 (2). T1 owns the lock vocabulary (M-006); this item touches only the header and the cancel.
- **Files:** `index.html:3222` (wizard eyebrow), `:12905–12911` (`renderWizard`), `:15527–15538` (`#wizCancel`).
- **Change:** in `renderWizard`, when a league row exists and is named (not `My Cup`): eyebrow `<name> · set the bylaws · they lock when you tap Lock`; otherwise today's `Create your league · locks at first tee` (T1 may rename the lock moments; the interpolation point is what this item adds). `#wizCancel`: replace `confirm()` with `openSheet('Discard this league?', '', '<p class="fine">It hasn't started, so nothing is lost but the name and the bylaws.</p><button class="btn" id="wzDiscard">Discard it</button><button class="btn dark" id="wzKeep">Keep it</button>')`; the handler body is unchanged after "Discard it". Non-Pros never reach it (T3-01).
- **Verification:** `+blind1` re-enters the wizard from Home: the eyebrow names The Papago Grind; Cancel on step 0 opens the sheet, "Keep it" closes it, "Discard it" runs `delete_league` (test on a throwaway league).
- **Risk:** none. **Parity:** the phone's `WizardScreen` header — check it reads the league name when `existingLeagueId != nil` (T3-P2 verifies; likely already true).

### T3-10 · Telemetry: role + stage on the hero events, gate bounces, join refusals
- **Layer:** telemetry (`client_events`) · **Effort:** S · **Deploy:** client push · **Issues:** all (measurement) · **Needs:** none.
- **Files:** `index.html:9998–10000` (`wire`/`seen`), `:15475` (`lock_attempt`), T3-01/T3-04/T3-05/T3-07 call sites.
- **Change:** `home_hero_state` props → `{state, stage:leagueStage(), role:CS.member?.role||'none'}`; `home_hero_tap` → `{cta, stage, role}`; `lock_attempt` → `{role}`; new `wizard_gate_bounce {from}`, `join_refused {reason:'setup'|'complete'}`, `formation_view {role}`, `home_doors_open`. No PII in props (the growth_events rule applies here too). `client_events` is RLS'd to `authenticated` — every event here is signed-in, so nothing is blind.
- **Verification:** after a member session, `select event, props from client_events where created_at > now()-interval '1 hour' order by created_at` shows the new props; the §5 queries return rows.
- **Risk:** none. **Parity:** T3-P6.

### T3-11 · `home-arc.md` §2 row 4 gains role × draft; IOS-028 parity record
- **Layer:** spec (documents, not the decision log) · **Effort:** S · **Deploy:** — · **Needs:** D111.
- **Files:** `spec/home-arc.md:45` (row 4), `docs/ios/DECISIONS.md` (append IOS-028 after IOS-027 at `:261`).
- **Change:** row 4 becomes three rows (setup · draft · preseason) with a "Pro / member" column listing the CTA per cell as built in T3-02. IOS-028 records the parity build (T3-P1…P6) in the file's existing format ("Decisions · Pipeline · Owner owes · Reversibility · Why P1").
- **Verification:** the row reads back the same six cells `renderHomeHero` renders.

### T3-12 · Harness click resolution + `leagueStage` tests
- **Layer:** tooling · **Effort:** S · **Deploy:** — · **Issues:** M-031 (struck), M-041 (tests) · **Needs:** T3-03.
- **Files:** the audit harness `bx.mjs` (session scratchpad; the audit cites `:119–131`, `:180–193` — it is not in the repo; the next audit's harness inherits the rule), `tests/app-tests.js`.
- **Change:** harness: resolve a bare `click "<label>"` as `getByRole('button'|'link'|'tab', {name, exact:true})` first, then the substring fallback, so "You" can never hit "…invite **You**r crew". `app-tests.js`: the T3-03 cases. The You tab itself needs no product change — record that in the re-run brief so the next persona clicks `css=.tabbar [data-v="stats"]`.
- **Verification:** re-running the joiner's Home → You step lands on the profile 3/3 with the role click.

### iOS parity

**T3-P1 · `LeagueStage` + one label table** — `Models.swift:180–198` gains `public enum LeagueStage { setup, draft, preseason, season(week:of:), cupFinal(weeksLeft:), complete }` with `LeagueStage.of(_ m: Me.Membership)` (`m.phase == "draft"` splits today's `.forming`; `SeasonPhase` becomes a thin map over it so `HomeMode` keeps compiling) and `LeagueStageCopy` (short/long per stage, the same words as `STAGE_LABEL`). `LeagueCopy.phaseHeader/phaseSub/squadsSub/kickoff` (`LeagueCopy.swift:145–197`), `LeagueRecord.line` (`LeagueRecord.swift:39–40`), `DraftFormation.boardWaitingK/formM/draftPoolSub` (`DraftFormation.swift:85,102`, `LeagueCopy.swift:182`) and `BoardStore.swift:103–106` read it; `LIVE NOW — CAPTAINS READY`, `Setup — invites open`, `Forming — invites open`, `SQUADS LOCKED` and the synthesized "is live — post the first round" go. Tests `LeagueRoomTests.swift:313–323` and `RoundsYouTests.swift:194–195` pin the new strings; one new test pins `LeagueStage.of` across a setup, draft, preseason, season, cup_final and complete membership fixture. **M.** Verify: `xcodebuild test` green; Clubhouse header, You › league record, League tab Squads row and the Board's empty line agree on the simulator (dev hatch, per memory `ios-sim-dev-hatch.md`).

**T3-P2 · HomeHero matrix with CTAs** — `HomeView.swift:521–583`: `.forming` dispatches on `LeagueStage.of(m)` and `m.isPro`; `HomeHero` gains a CTA slot (a `CSButton` under the line, plus an optional quiet link). Pro/setup: `WizardState.ctaLock` → `presenter.wizard = .init(existingLeagueId: m.league_id, initialStep: 2)` (the presenter comment at `Presenter.swift:30` already reserves `initialStep: 2` for this); Pro/draft: "Draw the squads" → `presenter.draft = m.league_id`, plus the `ShareLink` `StandingsPane.swift:60–66` already builds; member cells: line names `m.commissioner_name` (`Models.swift:87`) and the date from `m.season?.starts_on`; "Plan a round" → `presenter.declare = DeclarePrefill(...)`; "Post a practice round — it builds your number" → `presenter.showPost = true`. Figures and floor/cap read `m.settings` (`counting_cap`, `participation_floor`), never literals. **M.** Verify: the owner's account plus a seeded member account via `test-seed` (IOS-027) — the three cells per role on the simulator; VoiceOver reads the CTA.

**T3-P3 · Presenter role guard on the wizard** — `Presenter.swift:31`: add `func openWizard(_ target: WizardTarget, me: Me?)` that refuses when `target.existingLeagueId` names a membership whose `isPro` is false (toast "Only the Pro edits the bylaws"); `MainTabView.swift:158` (`case "wizard"` deep link), `ClubhouseView.swift:86` and `DraftNightScreen`'s `openWizard` (`MainTabView.swift:229`) route through it. The view-level gates (`StandingsPane.swift:37`, `DraftNightScreen.swift:93`) stay. **S.** Verify: a member account with a `cupseason://wizard` deep link (or the dev hatch's screen arg) lands on Home with the toast.

**T3-P4 · Additional-league rows** — `HomeView.swift` after `HomeHero` (`:38`): `ForEach(me.memberships.filter { $0.league_id != mode.membership?.league_id && LeagueStage.of($0) != .complete })` → a `CSRow` with `name · LeagueStageCopy.short · standing rank if present` (`Membership.standing` already rides `native_home`); tap sets `store.preferredLeague` and reloads (the same closure `InvitesBanner` uses at `:31`). **S.** Verify: the owner's account shows the second league's row with its rank.

**T3-P5 · Board/Schedule: one title per screen** — `MainTabView.swift:59–60, 88–97, 109–115`: `ScheduleScreen` and `BoardScreen` are pushed from both the Home and Clubhouse stacks; give each one `navigationTitle` regardless of path ("Your golf calendar"; "The Board · <league>") and drop the pane-vs-push duplication the iOS survey logged (M-070 iOS half). **S.**

**T3-P6 · Telemetry parity** — mirror T3-10's props in `CSTelemetry.event` (`Telemetry.swift`): `home_hero_state {stage, role, platform}`, `home_hero_tap`, `wizard_gate_bounce`, `join_refused`, `formation_view`. **S.**

---

## 3. QUICK WINS (no decision needed; this week)

- **T3-01** — the wizard gate, Cancel/Lock viewer checks (restores D40). Client push only. This alone closes the P0's destructive path.
- **T3-05** — read-only formation with a back link (restores D58 / S3-04).
- **T3-06** — Schedule's back link returns to the room (within D93).
- **T3-10** — telemetry props (so the baseline exists before T3-02 ships).
- **T3-12** — harness click rule + tests.

Everything else waits on a logged entry: T3-02/T3-07/T3-09 on D111, T3-03 on D112, T3-04 on D113 (and T1's `humanError` pass-through), T3-08 on D114. T3-02 also needs T3-03's `leagueStage()`.

---

## 4. PARITY (D100: nothing ships on the web alone)

| Web item | Phone | Note |
|---|---|---|
| T3-01 | T3-P3 | the phone's views are gated; the presenter is not |
| T3-02 | T3-P2 | the phone has the role split and no CTA — it gets the matrix |
| T3-03 | T3-P1 | `LeagueCopy` is the phone's copy of the twelve sites; `SeasonPhase.forming` splits |
| T3-04 | — | server rule; the phone calls the same RPCs. Door copy (`join_covenant_info.phase`) is T2's on both clients |
| T3-05 | T3-P1 (copy only) | Close already exists (`MainTabView.swift:225–232`) |
| T3-06 | T3-P5 | the phone pushes with a back; only titles differ |
| T3-07 | — | the phone is already a menu (`HomeView.swift:93–99`); the web moves toward it |
| T3-08 | T3-P4 | `HomeMode.of` keeps choosing one; rows beneath |
| T3-09 | verify in T3-P2 | `WizardScreen(existingLeagueId:)` header |
| T3-10 | T3-P6 | |

Web-only until the parity wave lands: none — T3-P1…P6 ride the same milestone (IOS-028). Native work runs locally (rule 6).

---

## 5. MEASUREMENT

**Events (client_events, `profile_id · event · props`)** — after T3-10:

```sql
-- 1 · who sees which hero, and what they press (weekly)
select props->>'role' as role, props->>'stage' as stage, event, count(*)
from client_events
where event in ('home_hero_state','home_hero_tap') and created_at > now() - interval '7 days'
group by 1,2,3 order by 1,2,3;
-- success: for role='player' in stages setup/draft/preseason, home_hero_tap / home_hero_state
-- rises from 0 (today no member CTA exists) toward the Pro's ratio; cta never 'datahform' for a player.

-- 2 · nobody but the Pro reaches the wizard or the lock
select event, props->>'role' as role, count(*) from client_events
where event in ('wizard_gate_bounce','lock_attempt') and created_at > now() - interval '7 days'
group by 1,2;
-- success: lock_attempt with role<>'commissioner' = 0; wizard_gate_bounce trends to 0 as stale links age out.

-- 3 · the join gate (D113)
select props->>'reason', count(*) from client_events
where event='join_refused' and created_at > now() - interval '30 days' group by 1;
-- read with the Pro's lock_ok in the same window: refusals should cluster before a lock, never after.

-- 4 · members reach the formation screen and leave it (M-032 / M-016)
select props->>'role', count(*) from client_events where event='formation_view' group by 1;
```

**Growth funnel (growth_events, `20260828160000`)** — the member's outcome metric is unchanged and already built: `link_opened(kind=join)` → `profile_created(came_via_kind=join)` → `first_round_posted`, by week and league in `v_growth_funnel`. T3's promise is that a joined member has a verb on day one; the number to watch is the share of `profile_created(join)` rows that reach `first_round_posted` within the first two weeks *of the season* (not of the join — pre-season joins post nothing, by T4's rule). Baseline today: the audit's four joiners, all pre-season.

**Acceptance (the blind re-run):** re-run **A6 New joiner, Journeys B–E** and **A1 Casual, Journeys C–D** on fresh `+blind` accounts against a *locked* league (phase `draft`), with the harness's exact-name click rule. Pass when, from the journey map's B.5 table: "What do I need to do next?" is answered from Home in one tap by the app's own sentence; the persona cannot reach a lock, a discard or "you run this league"; Home, the room header, Standings, the League tab and the Board print one stage word; "See the squads" has a way back and names who draws and when; Schedule returns to the room; the You tab renders the profile 3/3. Also re-run **A5 Organizer, Journey C** after the lock: the Pro's hero reads "Draw the squads", never "Lock it in", once the server has locked. iOS: the same five checks on the simulator via the dev hatch on the owner's account plus a seeded member.

---

## 6. OPEN QUESTIONS (for the owner)

1. **Pre-lock joins (D113):** enforce D40 as written — a code, an invite or "Add golfers" *seats* nobody until the bylaws are locked (recommended: the joiner's consent is to fixed terms) — or allow pre-lock joins and land them on D111's member/setup cell with a "bylaws may still change" line in the covenant? The pilot's "league no longer has ability to add people" pulled the other way once; the recommendation keeps *inviting* always working.
2. **The six stage words (D112):** proposed `Forming · Squads drawing · Before first tee · Season live · Cup Final · Season complete`. Testers read today's `FORMING` as "squads forming"; if "Forming" stays it must mean *setup* only. Solo leagues need a word for the locked-not-teed-off stage — "Before first tee" covers it if the draw stage is skipped. Your call on the nouns (D47 precedent).
3. **The member's first verb before first tee (D111):** "Plan a round" on the D107 tee sheet leads, with "Post a practice round — it builds your number" as the quiet second. Swap them? "Post" first is only honest once T4's season-window sentence is on the post form.
4. **The doors for members (D111 (4)):** collapse to one quiet "Start something…" link — D94 named this the thing to watch and four personas watched it. Confirm, or keep the three pills.
5. **Out of this theme's scope but exposed by D113:** §15's "late joiners assigned to the thinnest squad, logged" is not built — a join after `start_season` leaves a member squadless and `start_season`'s pool check never re-runs. Which theme owns it, or a ⚑ for the log?
6. **Pro/draft CTA and D54:** if a scheduled draw exists (D54's paced reveal), the Pro's hero should say "Squads draw <date>" rather than "Draw the squads". D54's state is not in `state`/`CS` today — confirm the field before T3-02 reads it, or ship the instant-draw CTA first.

---

## 7. SEQUENCING

1. **Day 1 (quick wins, one client push):** T3-10 → T3-01 → T3-05 → T3-06 → T3-12. Verify with `+blind1`/`+blind2` before cleanup, or re-seed.
2. **Log D111–D114** (owner reads §6 first; Q1 and Q2 decide the words in T3-02/T3-03/T3-04).
3. **Second client push:** T3-03 → T3-02 → T3-07 → T3-09 → T3-11 (spec rows). The 6 × 2 walk before commit.
4. **T3-04** as its own db push + client push in one session, *after* T1's `humanError` pass-through is live.
5. **T3-08** once T3-03's `leagueStage(m)` accepts a membership.
6. **iOS wave (IOS-028):** T3-P1 → P2 → P3 → P4 → P5 → P6, locally, one build; `xcodebuild test` and the preflight Swift checks (15–17) green.
7. **Acceptance:** the §5 re-run.

Dependencies on other themes: **T1** — `lock_league` RPC (server enforcement of the lock; T3-01 is the client belt) and the `humanError` pass-through (T3-04's sentences) and the invite sheet (`shareInvite` call sites in T3-02 are unchanged); **T2** — `join_covenant_info.phase` for the door's "not open yet" copy; **T4** — the season-window sentence the practice link and the kickoff banner defer to.

---

*Plan for theme 3 of the blind-audit remediation. Companions: `plan/t1-*.md` … `plan/t5-*.md`; the audit's own record is `../blind-ux-audit.md` §2 TOP-3, `../critical-findings.md` Part 1 TOP-3 and `../raw/synthesis-and-validation-results.json` (verdicts 5, 7, 9).*
