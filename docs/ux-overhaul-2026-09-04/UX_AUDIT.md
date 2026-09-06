# Cup Season — UX Audit (Phase 1 of the first-principles overhaul)

Repo `/Users/fischbeck3/cup-season` at tip `3bba87e` (main, clean) · 2026-09-04 · read-only.

This is the Phase 1 artifact the overhaul brief asks for (its §19). It is the foundation every later artifact (IA blueprint, screen specs, copy deck, decision-log entries) must cite. It is written for the owner: evidence first, no padding, complete.

---

## 0. How to read this

### 0.1 Scope

Two clients, one product.

- **The native iPhone app** — `apps/ios` (SwiftUI). App target = views; `Packages/CupSeasonKit` = domain + data; `Packages/CSDesign` = design system. **This is the shipping product**: TestFlight build 669 is with external testers and App Store submission is being prepared. Tabs: Home · Clubhouse · ⊕ Post (a centre verb that presents a cover) · You (`apps/ios/CupSeason/Main/MainTabView.swift:128,146-224`); boot states in `RootView.swift`.
- **The web PWA** — `index.html` at the repo root, one 20,567-line file (1.2 MB). Tabbar Home · Clubhouse · Post · You; views `view-home`, `view-hub`, `view-record`, `view-post`, `view-play`, `view-stats`, `view-people`, `view-schedule`, `view-wizard`, `view-draft`, `view-event`. Declared the behavioural reference for the phone (`docs/ios/DECISIONS.md` IOS-018; `CLAUDE.md:301-303`) — **a declaration the owner's revised R-C supersedes: two clients, one product, one set of producers, two shapes, and `CLAUDE.md:301-303` is corrected in Wave 0** — but at the time of this audit the phone had moved past it on Home since 2026-09-02 (D121, D126, D129, D130, D176, D216–D219 are phone-first with "web owed" notes).
- **Backend** — Supabase; 185 migrations; the RPC contract snapshot `packages/db/contract.psv` (198 functions, 159 client-granted, 12 anon); edge functions under `supabase/functions` (`push`, `season-email`, …).

### 0.2 Sources

Twelve Map readers, each a full report with its own finding prefix, and six blind persona walks. All are in the session scratchpad (`scratchpad/ux/audit/`); this document condenses them and keeps their evidence. Finding ids in this document refer to those reports.

| Prefix | Reader | Findings (P0 / P1 / P2 / P3) |
|---|---|---|
| FR- | First run (phone + web twin) | 38 (0 / 10 / 16 / 12) |
| HM- | Home on the phone | 45 (3 / 9 / 27 / 6) |
| CH- | Clubhouse tab + league room | 56 (1 / 9 / 27 / 19) |
| PP- | Post and play (⊕, composer, live) | 39 (1 / 7 / 11 / 20) |
| YP- | You · People · profile · settings · pricing | 50 (1 / 9 / 21 / 19) |
| CJ- | Create and join | 58 (4 / 17 / 29 / 8) |
| WB- | The web client and its divergence | 32 (1 / 5 / 18 / 8) |
| DL- | Data layer (what the backend can already say) | 33 (1 / 10 / 18 / 4) |
| PA- | Prior-audit delta (2026-08-29 → tip) | 33 (2 / 19 / 10 / 2) |
| CC- | Canon and constraints | 52 (5 / 19 / 25 / 3) |
| TM- | Terminology | 59 (0 / 12 / 34 / 13) |
| EN- | Empty states and notifications | 36 (1 / 11 / 15 / 9) |
| SV- | Screens (visual) | 50 (0 / 11 / 24 / 14, +1 closed record) |

Roughly **580 findings, 20 of them P0**. Many overlap by design (the same defect seen from five seats); the overlaps are the signal.

Six blind personas (they saw only the App Store listing, the screenshots and what the SwiftUI views render for their state; no spec, no decision log):

| Persona | Seat | Score / 10 | Goal reached |
|---|---|---|---|
| A · Tyler | New golfer, no code, wants one Saturday with three friends | 4 | No |
| B · Dana | Member between seasons (4th of 8, season wrapped two weeks ago) | 4 | No |
| C · Marcus | Active competitor, 3rd of 8, week 7 of 26, owes $50 | 6 | Yes (by brute force) |
| D · Casey | Organiser, six friends, a spreadsheet and a $50 pot | 5 | No |
| E · Jordan | Invited joiner, texted a `?join=` link, $50, starts tomorrow | 6 | No |
| F · Priya | Five buddies, nine rounds, no league | 5 | No |

Canon consulted by readers (never by personas): `spec/product-vision-v1.0.md`, `spec/spec-v1.0.md`, `spec/decision-log.md` (D1–D221), `spec/voice-and-tone.md`, `spec/brand-canon.md`, `CLAUDE.md`, `docs/ios/DECISIONS.md` (IOS-001…027), `docs/ios/IOS-002-architecture.md`, `Cup-Season-Guide.md`, the prior blind audit `docs/audit/blind-ux-2026-08-29` (135 issues, TOP-1..5, remediated as D111–D139).

Prod facts were read **read-only** via `supabase db query --linked` on 2026-09-04 and are consolidated in Appendix A *(a snapshot of an unlaunched database — scaffolding, not behaviour; see EVIDENCE_POLICY.md)*. Never the "Supabase Casa" MCP.

### 0.3 Conventions

- **SAW** = read in code at tip, seen in a screenshot, or returned by a prod query. **INFER** = concluded from code paths without running the app. Every finding in the source reports carries one of the two; this document keeps the distinction where it matters.
- Line numbers are as of tip `3bba87e`. Web citations are `index.html:NNNN` unless a path is given.
- **Q1–Q5** are the brief's five first-seconds questions: Q1 what is happening · Q2 why it matters to me · Q3 what I can do right now · Q4 who I am competing with · Q5 what happens next.
- Severity: P0 blocks a goal · P1 major · P2 minor · P3 polish.
- "The Pro" = the league organiser (`role='commissioner'` in the database; the UI word is ruled, D132). "Buddies" = the mutual accepted tie (D80). "The board" = a league's posts + chat. "The books" / "the pot" = money.

### 0.4 What was NOT observed live (limits of this audit)

1. **No reader drove the phone in a simulator for this pass.** The phone is described from code plus five screenshot sets. There is **no screenshot of the phone's first run** anywhere in the repo; the eleven frames in `docs/audit/signup-walk-2026-08-31/` are the **web PWA** (caption `v23 · __CS_VERSION__`, `index.html:2914`; single-page card with City/Home course; the web-only D151 crew step), not the phone as the folder name suggests (FR §How to read, SV §0).
2. **The 22 fresh native captures (`scratchpad/ux/shots/`, Sep 4) all render the light paper theme**, including the four named `*-dark-*`; code defaults to charcoal/Fescue (`CSDesign/Theme.swift:17`). Cause undetermined (SV-01). Dark rendering at tip is inferred from the Aug 29 and Sep 1 sets.
3. **Push has never reached a production phone**: `device_tokens` holds one `ios-sandbox` row; the contextual ask has fired once ever; `invites` has 0 rows (EN-01). Every notification in §7 is theoretical for the shipping product; whether `APNS_*` / `BREVO_API_KEY` secrets are set could not be read.
4. **The web was not loaded in a browser**; its "first thing shown" is DOM order plus render functions. Whether the FAB is retired in prod, whether `#obWelcome` is reachable, and whether the wizard's "4 Squads" pre-selected markup flashes were not verified.
5. **Runtime behaviours were inferred, not run**: PP-01 (hand-typed course cannot post), PP-08 (Change setup orphans a live round), HM-14 (pull-to-refresh misses four child loads), SV-02's exact collapsed string, D221's four unapplied migrations' effect on the inventory, `index_provisional` in prod (0 rows).
6. **Telemetry is thin and partly dead**: `CSTelemetry` does not stamp `platform`; the web's `qaEvent` is suppressed while `state.demo` is true so `crew_step_*` and `covenant_declined` have never recorded (FR-09); no app-open/view event exists, so WAU/MAU, D7/D30 and empty-state engagement cannot be read from the schema (DL-30). 199 of 212 rounds are backdated/seeded.
7. **Rendering judgments** (fold positions at Dynamic Type sizes, VoiceOver order, the Forge and the ceremonies in motion) are outside what stills and code can settle.

Each source report closes with its own "could not determine" list; the union is Appendix B.

---

## 1. Current information architecture

### 1.1 The phone — every destination as a tree (SAW)

```
RootView (SessionStore.state)
├─ .booting            BootingView "Restoring your session"                  RootView.swift:26-27
├─ .signedOut          DoorView  ── ForgeView plays once per device (cs_forge) DoorView.swift:53-87
│    ├─ email stage → code stage (8 digits, auto-verify) → [password stage: reviewer only]
│    ├─ Sign in with Apple  (flag app_flags.ios.apple_sign_in — CLOSED in prod)   DoorView.swift:104-110
│    └─ (no "I have a league code" field on the phone door; the web has one)        index.html:2811
├─ GuestPencilScreen   /?claim=TOKEN while signed out → LivePlayView pencil → door RootView.swift:29-30
├─ .cardGate           CardGateView 3 steps: name+@handle · marker (14, no default) · starter index+GHIN
├─ .orienting          OrientationScreen (once per device; only with no league/event/round/pending join)
│    "Four places. Two ways to play." + LeaguelessDoors (Join · Start a league · Start an event) + "Take me in"
├─ .mustUpdate         MustUpdateView (no button)                              RootView.swift:153-165
├─ .failed             BootFailedView "Boot stalled" · Try again · Sign out     RootView.swift:138-165
└─ .ready              MainTabView  ── Tab { home, clubhouse, post, you }      MainTabView.swift:128
     │  overlays: LiveNowBar (above tabs) · PushPromptSheet (drains when nothing presented) · toasts
     │  app-level sheets: TourCardSheet · FeedbackSheet · desk/field note · PeoplePickerSheet ·
     │    EventPickerSheet → RyderSetupSheet / MajorSetupSheet(flag, CLOSED) · EventRoomScreen (cover) ·
     │    WizardScreen (fullScreenCover, no Close) · DraftNightScreen (cover) · JoinLeagueFlow →
     │    CovenantSheet → LeagueWelcomeSheet · LiveRoundHost (fullScreenCover) · PostCoverView (fullScreenCover)
     │
     ├─ HOME tab  (HomeView, one ScrollView, fixed slot order)                   HomeView.swift:43-137
     │    header: wordmark · date · "+" Menu (Start a league · Start an event · Join with a code ·
     │            Your golf calendar · Find golfers)                             HomeView.swift:178-190
     │    slots: InvitesBanner · BuddyRequests · LiveResumeBanner · HomeLeadCard (ladder: clash › floor ›
     │           move › milestone › nothing) · HomeHero (six modes, §4) · HomeLeagueRows (D121) ·
     │           OccasionCard · UpNextChips · "Around your buddies" head → digest → feed buckets
     │           (Today / This week / Earlier, folded system rows) · "Coming up" cards / "Put a round on the calendar →"
     │    routes (HomeRoute): .league(id) → ClubhouseView on STANDINGS · .pot(id) → Pot pane ·
     │           .people → PeopleScreen · .schedule → ScheduleScreen · ClubRoute.board(id) → BoardScreen
     │    sheets: RoundReceiptSheet · ScorecardSheet · ScheduledRoundSheet · TourCardSheet
     │
     ├─ CLUBHOUSE tab (ClubhouseView)                                            ClubhouseView.swift
     │    ├─ league-less: RunItBackCard? · LeaguelessDoors · fine line · "Add golfers"   :137-157
     │    └─ ≥1 league: EventChips strip · paged rooms (D203, dots + ⇄ menu)     :45-134
     │         LeagueRoomScreen = LeagueHeaderCard (name · phase · code chip · rules meta · span · THE PRO ·
     │           Add golfers · Pro: Cancel/Delete) · CancelBanner · CSTabStrip
     │           STANDINGS (pane) · BOARD (door → BoardScreen) · SCHEDULE (door → global ScheduleScreen) ·
     │           POT (pane; hidden at $0) · ALBUM (pane) · LEAGUE (pane)         LeagueRoomScreen.swift:67-137
     │         STANDINGS by phase: setupChecklist · draftHero · atStarter kickoff + live body · live body
     │           (RoomSeasonStrip · PressMeter · NextCard · On the line · Climb · ClashCard · table · race) ·
     │           Cup Final race · wrappedHero + live body
     │         sheets: SquadReceipt · MemberHistory · FinalistReceipt · ScoringHelp · SeasonCeremony ·
     │           MembersSheet · SetIndex · ForfeitCreate/Settle · CancelLeague · DeleteLeague · Announce ·
     │           Report · Scorecard · Day · DeclareRound · ScheduledRound
     │
     ├─ ⊕ POST (selection snaps back; presents PostCoverView "Golf")             MainTabView.swift:336-339
     │    ├─ "Play now — score the group" (ember hero) → LiveRoundHost: LiveSetupView → LivePlayView
     │    │     (HOLE / CARD, landscape) → LiveFinishSheet → LiveRecapSheet → (lands on empty setup)
     │    │     + LiveCardSheet (pars) · LiveRosterPickerSheet · nearby ask alert · LiveGroupSheet · Live Activity
     │    ├─ "Post a round — after you play" → PostRoundScreen (composer) → course dropdown · rating/slope fold ·
     │    │     PostScorecardStrip · PostParsSheet · PostEvenParSheet · PostDateSheet · camera/scan ·
     │    │     PostScanPickSheet → FinishCeremonyView → EpilogueSheet → PostPartnersSheet → close
     │    └─ "Plan a tee time — before" → DeclareRoundSheet
     │
     └─ YOU tab (YouScreen)                                                       YouScreen.swift:47-190
          hero (photo/crest · name · meta · index or "n of 3" · trophy chips · FORM) · Your buddies door ·
          LastRoundWithCard · "Your golf" (Display case · All time · Recent rounds) ·
          "Your seasons" (This season strip · Rivalries · Every season)
          routes (YouRoute): .people → PeopleScreen · .settings → CardAndSettingsScreen · .addGhin
            PeopleScreen: requests · Find golfers · invite-link row (only with a league code) · buddies · Findable by
            CardAndSettingsScreen: "Your card" pane (~26 controls) · "Settings" pane (~33 controls) ·
              Developer (1-s long-press on the build line): desk · field note · "Tell us how it's going"
          sheets: TourCardSheet (own / other / PRIVATE) → RivalrySheet → NameRivalrySheet · receipts · guide sheets ×5
```

Push routes (12 kinds → receipt / scorecard / board / live / event room / invites banner / requests / round sheet / Home; `docs/ios/push-contract.md:38-48`). Universal links claimed: `/?join=` and `/?claim=` only (`CupSeasonApp.swift:28-36`); no `?event=` route.

Counts: 4 tabs · 3 boot-time gates (door, card, orientation) · 17 Home slots · 6 room panes (2 are doors) · ~15 room sheets · 34 post/play screens and states · 21 You/People/Settings screens · ~60 controls behind one ⚙ · 5 items in the "+" · 6 placements of the same three creation doors (Orientation, league-less Clubhouse, Card & settings ×2, Home "+", Occasion; CJ-40).

### 1.2 The web beside it (SAW, DOM order — not rendered)

```
#onboard door: Forge · h1 "Rally your crew. Post real rounds. Take the cup." · Continue with email ·
   "I have a league code" (validates via league_by_code BEFORE the email round-trip)   index.html:2790-2816, 17745-17748
   desktop ≥1100px: two fiction "wings" (MARCUS +9 PTS …)                              :4284-4300
#obProfile golfer card (ONE page: name · handle · home course · city · index · GHIN · 14 markers)  :2817-2852
#obOrient orientation (same copy as the phone)                                          :2891-2913
#obCrew  crew step (D151, WEB ONLY): "Who are you playing with?" · code box · Find your buddies ·
   Start a league instead · I'll do this later                                          :2859-2878, 15006-15043
nav.tabbar (<960px): Home · Clubhouse · Post (aria "Post a round") · You                :3908-3913
aside.side (≥960px): Home · Post a round · Clubhouse · You   (order and label differ)   :2931-2949
switchView(v): the one choke point — aliases feed→home, cal→schedule, pot→hub+pot, board→dialog;
   gates: wizard Pro-only, draft after lock                                             :4512-4590
view-home: #resumeBanner · #homeRequests · #homeStart doors (league-less: Join · Start a league ·
   Start an event; member: "Start something else…") · #homeLead (D176 ladder) · #homeHero (275-line
   role×stage matrix, with CTAs on every non-season state) · #homeTiles League · Next · Board ·
   #homeOccasion · #homeUpNext · #homePulse floor fine print · "Around your buddies · THE BOARD ↗" · feed
view-hub: #hubLeagueless (Start a league · I have a league code · Add golfers · Sign out) or
   #clubGroups chip switcher · #hubHeader · six segments Standings · Board · Schedule(→ view-schedule) ·
   Pot · Album · League
view-record ("Golf", three cards) → view-post (two-column form, calc panel trails) / view-play (tee sheet)
view-wizard (3 steps; Customize ~12 dials; "4 Squads" pre-selected in markup) → openLockShare → openInviteSheet
   (URL as text · Copy link · Copy message · Share… · "read them the league code")
view-draft · view-event (Ryder scoreboard / Major room) · event picker (Ryder LIVE · Bracket SOON · Major LIVE)
view-schedule · view-people · view-stats (You: "Tell us how it's going" chip, Founder's desk) · Card & settings sheet
covenantGate (6 call sites; FAILS OPEN for $0) · openLeagueWelcome · openJoinSheet · openFeedback
```

### 1.3 Phone vs web — the divergence table (SAW; condensed from WB §2b's 29 rows and the other readers)

| # | Surface | Phone | Web | Ruling / status |
|---|---|---|---|---|
| 1 | Onboarding: crew step ("Who are you playing with?") | **absent** (`OrientationScreen.swift:9-13` says so) | built (`#obCrew`) | D151 built web-only; the brief keeps this question |
| 2 | Golfer card fields | 3 steps; name · @handle · marker · starter index · GHIN; city/home course deferred to You (`CardGateView.swift:141`) | 1 page; adds home course + city (`:2830-2835`) | D151 §2 landed on one client |
| 3 | League code on the signed-out door | none | "I have a league code", validated pre-email | D151 named this gap; the phone has it inverted |
| 4 | Invite-link door copy | slogan only; `DoorView` never reads `JoinIntent` | "Enter your email — X is one step away; you'll review it before you're in." (`:17751-17753`) | FR-07 |
| 5 | Covenant "Not now" | loses the invite (`RootView.swift:43` clears on appear) | keeps `cs_code`, but no "Invited · REVIEW" card renders | D116 §2 unbuilt both |
| 6 | Covenant for $0 leagues | none (`JoinLeague.swift:104`) | none (`:17705`, fails open) | D136 ruled a sheet for $0 — unbuilt both |
| 7 | Home league-less hero CTA | **none** (hero is not a Button, `HomeView.swift:810-812`) | "Post your first round" / "Find your buddies" / "Start a league" ladder (`:11439-11475`) | D81 ladder web-only |
| 8 | Home rung 5 (buddies, no league) | does not exist (`Models.swift:308-309`) | "Four makes a league. You have 3." | web-only |
| 9 | Home doors placement | header "+" menu (IOS-012) | `#homeStart` is slot one | IOS-012 phone-only |
| 10 | Home tiles League · Next · Board | none | `renderHomeTiles` (Board tile disabled "LEAGUE ONLY" when league-less) | D94 web-only |
| 11 | Home second-league rows (D121) | built | absent; boot still toasts "Switch groups anytime from Home" (`:20066`) | web owed; the brief's Home must speak for every membership a golfer holds, and R-C gives every wave a web half |
| 12 | Home hero: leader by name with totals, owe line, endgame foot | built (D126/D129/D130) | neighbour named, no totals; no owe line; no endgame foot; tiebreak repeated in a second wording (`:11520` vs `:6328`) | web owed |
| 13 | Home lead card ladder, clash yield, first-week sentence | built (D176/D207/D216) | rung 1 fires whenever `home_clash` returns a row; no yield | phone-only |
| 14 | Home system-row fold (D217) and booking doors (D219) | built | every system post is its own card; booking rows open only on `live_round_id` | phone-only |
| 15 | Feed head door | "YOUR BUDDIES ↗" → People (D218) | "THE BOARD ↗" → one league's board dialog (`:3024`) | web owed |
| 16 | `upcomingFromSchedule` | plans = (mine or tagged) and rsvp ≠ out | drops rounds booked with you, keeps your declined booking; Next tile uses a third unfiltered source (`:10985-10986`, `:11048-11052`) | WB-03 false fact |
| 17 | Week number | `LeagueDates.currentWeek` (1-based) | three client formulas (`:13637`, `:16819`, `:11304`) + server `snapshot_week` (0-based) | DL-05 / WB-07 |
| 18 | Solo-league week-by-week archive | (no equivalent found) | prints empty "WK n" rows (reads `standings.squads` only, `:14125`) | WB-06 false fact |
| 19 | Floor credits sentence | "You're 0.5 short of the floor. One round covers it." | "you've posted 2.5" prints credits as rounds (`:10877`) | WB-05 |
| 20 | Clubhouse league switching | swipe paging + dots + ⇄ menu (D203) | horizontal chip strip (`:3622`) | D203 |
| 21 | Clubhouse header stage word | one producer | hand-derived "Squad formation" (`:14635`) bypasses `STAGE_LABEL` | D201's "third pattern" |
| 22 | League-less Clubhouse | Join · Start a league · Start an event · Add golfers | Start a league · I have a league code · Add golfers · **Sign out** | D151 §4 reordered Home only |

**A note on the "web owed" cells above.** They are the historical record of how the last eight Home rulings shipped — the state this audit found on 2026-09-04 — and they are kept as evidence. **They are not a backlog.** The owner's revised **R-C** (2026-09-05) rules that every wave has a phone half and a web half and is not done until both ship, so there is no lag to owe from; the parity these rows describe is closed by the overhaul's own waves, in its own desktop-first shape, and no new "web owed" note is written anywhere in this set.
| 23 | ⊕ | full-screen "Golf" cover; composer is a scorecard with a live gross hero (IOS-020) | `view-record` page → two-column form | IOS-011 / D110 addendum contradict each other about what the ⊕ opens (CC-33) |
| 24 | Composer rating guard (Q-22) | **none** — blank rating posts 0 and hits a check constraint (PP-01) | "Pick a tee — or type the rating and slope" (`:6989-6999`) | phone behind |
| 25 | Rating/slope placeholders | "72.1" / "128" read as values (`PostRoundScreen.swift:194-195`) | "—" | PA-025 |
| 26 | Pot pane payment terms (D129) | **not rendered**; member rows are buttons that toast | rendered (`:7962-7963`); Pro edits them | phone behind (CH-03) |
| 27 | Invite sheet after lock | native ShareLink + Add golfers only | URL as text · Copy link · Copy message · Share… · code | D114 phone half unbuilt |
| 28 | Major | flag-closed (`app_flags.ios` has no `major`) while three Home occasion cards sell it | LIVE | IOS-022 (7) |
| 29 | Boot failure | card "Boot stalled" + Try again + Sign out | raw "Boot failed at [step]: <error>" / "Boot stalled at [memberships] — network or auth hang" on the door (`:19997`, `:20068`) | IOS-004 named this |
| 30 | Push / live | APNs, PushRouter, badge, Live Activities, Nearby | web push + a dead Capacitor branch (`:16314-16322`) | phone-only |
| 31 | Signed bare differentials (`sgn()`) | labelled but signed/coloured on six surfaces (SV-04) | five surfaces (`:5011, :13020, :13021, :13054, :13070, :14254, :14260`) | D123 "retire sgn()" unbuilt |
| 32 | Reference client | `CLAUDE.md:301-303` still names the web | IOS-018 says parity first, rethink later | WB-01: the reference has already flipped in fact; no entry opened the question |

Telemetry split (last 30 days, by event name since `platform` is not stamped): 8 golfers fired web-only names vs 5 phone-only (4 both) — the audit's record of what `client_events` held, not a measure of where golfers are. The client question is ruled, not counted: the owner's revised **R-C** makes it two clients, one product, one set of producers, two shapes, built inline (WB §6).

---

## 2. All major screens

One row per screen, sheet or distinguishable state; phone unless marked (web). "First thing shown" is what the eye meets at the top. "Primary action" is the loudest control. Evidence is the file at tip; the fuller per-screen tables are in the source reports (FR §1, HM §1, CH §1, PP §1, YP §1, CJ §1, EN §1, SV §1).

### 2.1 Onboarding and boot

| Screen | Reached by | First thing shown | Primary action | Exits |
|---|---|---|---|---|
| Boot · restoring | cold launch with a session | spinner + "Restoring your session" (`RootView.swift:27`) | — | → tabs / door / card / orientation / failed |
| Boot failed | bootstrap failure | "Boot stalled" · human reason · Try again · Sign out (`RootView.swift:144-147`) | Try again | Sign out (drops the session on a network failure) |
| Must update | `min_build` gate (0 in prod) | "Update Cup Season …" · "needs build N" (`:158-161`) | **none** — no store link | — |
| Door · Forge (once per device) | first launch | 2.2 s animation; "Rally your crew. Post real rounds." / "Take the cup." (`ForgeView.swift:161-162`) | (field rises at ~1.8 s) | → email stage |
| Door · email | every later launch, sign-out | EMAIL field · "Continue with email" · "One code, no password. Codes come from the newest email." · legal · `v1 · build N` (`DoorView.swift:91-114,193`) | Continue with email | Apple button only if flag (closed in prod); no code field; no product sentence (D117 unbuilt) |
| Door · code | after send | "THE 8 DIGITS" · numberPad `oneTimeCode` · Verify · Resend 30 s · Change email; spam hint after 20 s (`:116-159,331-341`) | typing 8 digits auto-verifies | → card (new) / tabs |
| Door (web) | cupseason.app signed out | seared wordmark · same slogan · "Continue with email" · **"I have a league code"** · fiction wings on desktop (`index.html:2790-2816, 4284-4300`) | Continue | code box validates pre-email |
| Guest pencil (signed out `/?claim=`) | universal link mid/after a live round | "Finding your card" → live pencil; after: "NAME — 84 at COURSE, Sat Jul 25. Enter your email to keep it." (`LiveClaim.swift:50-63`) | Enter your email to keep it | → door → card (claim thread line) |
| Card gate 1 of 3 | first sign-in (`needsCard`) | "Who's on the card?" · "Just a name and a marker to start — this card follows you into every league." · NAME · @HANDLE (auto-derived; "changes once every 60 days") · live availability (`CardGateView.swift:92-136`) | Next | — |
| Card gate 2 of 3 | Next | "Pick your ball marker" · 14 named tiles, no default · "City and home course live on your card — add them any time from the You tab." (`:138-167`) | Next (refuses without a pick) | Back |
| Card gate 3 of 3 | Next | "Know your number?" · "Optional. Your index builds itself at 3 posted rounds…" · STARTER INDEX · GHIN (+USGA footnote) (`:169-178`) | Save my card (`set_handle` → `set_profile`; queues the push ask `:238`) | Back |
| Golfer card (web) | after code | one page: name · handle (+60-day policy, "your leagues are told") · home course · city · index · GHIN · 14 markers · "Save my card" (`:2817-2852`) | Save my card | toast "Card saved. Welcome, X." |
| Orientation | first `.ready` with no league/event/round/pending join; once per device | "Four places. / Two ways to play." · "Thirty seconds, then you're in." · four tab rows · THE LONG GAME "A league · Months. Every round counts toward a table." / THE SHORT GAME "An event · A weekend or a few weeks. Its own little trophy." · fine line · three doors · pinned "Take me in" (`OrientationScreen.swift:46-71,137-191`) | Take me in | Join sheet / wizard / event picker; "Reopen … You › ⚙ › How it works." |
| Crew step (web only) | after orientation, cold arrivals | "✓ CARD SAVED · Who are you playing with? · … Bring them now and your first round already counts for something." · code box + Join · Find your buddies · Start a league instead · I'll do this later (`:2859-2878`) | Join (code) | each door → `leaveCrewStep(how)` (telemetry never records, FR-09) |
| Push prompt sheet | drains over the first Home when nothing else is presented (`MainTabView.swift:330-335,444-447`) | "Hear it when it happens" · "YOUR CARD IS IN" / "FIRST ONE ON THE BOARD" / "YOU'RE ON THE ROSTER" · "A round lands on the board. A duel is closing. The table moves." · … · "Nothing else. No streaks, no noise, no badge you didn't earn." (`PushAsk.swift:76-99`) | Turn on notifications → iOS dialog | Not now (14-day snooze) |

### 2.2 Home

| Screen / slot | Reached by | First thing shown | Primary action | Exits |
|---|---|---|---|---|
| Home root | tab 1; push `.home`/`.invites` | wordmark "Cup Season" · "FRI · SEP 4" · orange "+" (a11y "Start or join") (`HomeView.swift:48,178-190`) | none in the header | 17 slots below |
| "+" menu | tap "+" | Start a league · Start an event · Join with a code · Your golf calendar · Find golfers (`:178-190`) | — | wizard cover / event picker / join sheet / Schedule push / People push |
| Invites banner | pending `my_invites` | "League invite · PIGL · from Jerecho" or "Ryder invite · … · first tee 2026-09-12" (raw ISO; every event is "Ryder") · Accept · Details (`InvitesBanner.swift:43-90`, `PeopleModels.swift:129-141`) | Accept (one tap; **no covenant**, `respond_invite`) | Details sheet → Accept & join / Decline |
| Buddy requests | pending friendships | "Requests · N" · "@galen · wants to be golf buddies" · Accept · ✕ (`BuddyRequests.swift:74-89`) | Accept | toast "Golf buddies ✓" |
| Live resume banner | a live round I am seated on | "Continue your round · PAPAGO GC · MATCH PLAY · HOLE 5 · THRU 4 →" or "Galen put you on the tee sheet · JUST TEED OFF · JOIN" (`LiveCopy.swift:269-277`) | tap | LiveRoundHost cover (also offered by the LiveNowBar above the tabs — twice on one screen, HM-35) |
| Lead card | `HomeLead.choose` ladder, lead league only | ONE of: clash ("The clash · closes today · You v Galen. Best round of the week takes it.") / floor / move ("Up 1") / milestone ("Around your buddies · Dev — 🔥 Personal best") / nothing (`HomeLead.swift:159-184,195-235`) | the face's one verb | composer / receipt / STANDINGS |
| Hero (six modes) | always | eyebrow · big figure · one sentence · foot lines (rule · endgame · money · owe) · "See the table →"; the whole card is a Button **only with a membership** (`HomeView.swift:793-1000`; matrix in §4) | See the table → (members) / **none** (league-less) | ClubhouseView STANDINGS; owe line → Pot pane |
| Other-league rows (D121) | 2+ non-wrapped memberships | up to 3 rows "Fellas · Week 7 of 26 · 1st of 2, 28 clear of Jade · $150 on the books …" › (11-pt mono) (`HomeView.swift:1015-1069`) | tap re-renders Home around that league | "and N more →" Clubhouse |
| Occasion card | calendar window, once per year | "The oldest one · Links weather is a state of mind. · Name the jug →" etc. (`HomeStream.swift:201-214`); dark Jul 25–Sep 17 | the act link | event picker (Major flagged off → dead end) / wizard / ✕ |
| Up Next chips | next round / buddy's plan / invites+requests / month ≤10 days **and any membership** | "NEXT ROUND · Sat Sep 5 · Papago with Dre ›" · "BUDDY'S PLAYING · Tash · sun ›" · "NEEDS YOU · 2 invites ›" · "MONTH CLOSES · in 3 days ›" (`ScheduleModels.swift:374-410`) | tap chip | round sheet / Schedule / People / STANDINGS |
| Digest row | second visit onward | "SINCE YOU WERE HERE · 3 rounds, a personal best from Galen, and Galen 🔥'd your 83." / "QUIET SINCE YOUR LAST VISIT · Yesterday — Galen posted 83 …" (`HomeDigest.swift:74-100`) | quiet frame's thumb → receipt | — |
| Feed | `home_feed(21)` ∪ league posts, folded, ≤30 | round cards (photo ground or plain; "Beat their number by 2.4" · 84 gross · course · date · 🔥) · post rows · folded "Fellas · 2 league notes this week ⌄" · "Show 3 more" (`HomeView.swift:445-490,724-770`) | card → receipt; 🔥 (only when a shared-league post exists, HM-11) | receipt / scorecard / round sheet / Tour Card / board |
| Feed · loading | first load | three redacted rows (`:118-119`) | — | — |
| Feed · empty | no rows | "No rounds from your buddies yet. Post one, or **add some buddies.**" (only the last three words link; `:120-126`) — also rendered on a network failure with nothing cached (`:283-288`) | add some buddies. | People |
| Coming up | always (D176) | ≤5 `HomeRoundCard`s "SAT SEP 5 · WITH YOU · Dre · PAPAGO GC · 7:10a · 2 in · 💬1 · ☀ 98°" or "Put a round on the calendar →" (`UpcomingRoundsSection.swift:30-61`) | tap card | round sheet; empty row → ScheduleScreen (not the declare sheet, HM-24) |
| Home (web) league-less | first landing | three doors · fine line · hero "YOUR CARD · Three rounds and your index goes live. Nothing else needed. · INDEX ●— 0 OF 3 · **Post your first round**" · tiles LEAGUE None yet / NEXT Open / BOARD — LEAGUE ONLY (disabled) (`:11086-11146,11439-11475,11036-11075`) | Post your first round | tiles, doors |
| Home (web) member | tab | `#homeStart` "Start something else…" · hero (gap line + floor foot, no endgame) · three tiles · MONTH CLOSES chip · feed | — | tiles |

### 2.3 Season / league creation

| Screen | Reached by | First thing shown | Primary action | Exits |
|---|---|---|---|---|
| Wizard · name sheet | any "Start a league" door; Run it back (prefilled "· S2") | "Name your league" · "THE BANNER EVERYTHING HANGS UNDER" · placeholder "The Big Slice, The Sunday Cup, Dew Sweepers…" · "You can rename it any time before the bylaws lock." (`WizardScreen.swift:70-86`) | **"Start the league" — mints a league row** (`create_league`, `:252-268`); toast "X is on the books — set the bylaws" | Cancel (nothing minted) |
| Wizard step 1/3 | after the name | "Create your league — set the rules once, lock them in" · three dots · LEAGUE NAME (asked again) · "PRO — THAT'S YOU · @handle · you run this league · THE PRO" (`WizardSteps.swift:11-41`) | Next → | Cancel = two-tap discard (`delete_league`); no Close on later steps (CJ-08) |
| Wizard step 2/3 | Next | "How serious is your league?" ⓘ · Casual / Standard ✓ / Cutthroat cards ("95% hcp · post what you'd post to GHIN · best 3 / mo count · 2-round floor") · summary · "Verification is a norm the league holds, not a filter the engine applies." · **"Use these defaults →"** · "Customize ⌄" · portrait "YOUR LEAGUE SO FAR" (2 SQUADS · BLIND DRAW · Bragging rights · $0 STAKE · 13 wk · FINAL 4) · PricingPassCard (flag-hidden) (`WizardSteps.swift:45-183`, `WizardState.swift:66-73,101-107`) | Use these defaults → (jumps to review) | Back · Next · Customize |
| Wizard dials (Customize) | inline | Buy-in ladder 0/25/50/75/100/150/200 · Season length (13-rung ladder) · First tee (default next Saturday, no past guard) · TEAMS Solo / 2 / 3 / 4 Squads (default squads2, dimmed for a roster of 1, "1 golfer staged — solo fits") · HOW TEAMS FILL · HOW IT ENDS · POT SPLIT · Counting cap · Participation floor ("MIN ROUNDS / MONTH · −5 SQD PTS SHORT"); six ⓘ paragraphs of 60–90 words (`WizardSteps.swift:110-163`, `WizardState.swift:387-407`) | — | Hide options |
| Wizard step 3/3 review | Next / fast path | "Review the bylaws, then lock it in" · 10–11 all-caps rows (STRUCTURE · Squad formation · PRESET · HANDICAP ALLOWANCE 95% · VERIFICATION · COUNTING CAP · PARTICIPATION FLOOR · BUY-IN · POT SPLIT 60/25/15 champ/2nd/king · SEASON · CUP FINAL "scored fresh") · "Lock opens the invite link — … The code works until first tee, or until you close the roster. Squads need four to tee off; solo tees off at two." (`WizardSteps.swift:187-214`, `LeagueCopy.swift:131-155`) | "Lock the bylaws & form the squads" (solo: "Lock the bylaws") → `lock_league` (one transaction, 18 args) | Back |
| Lock share sheet | after lock | "Bylaws locked ⛳ · One link fills the league" · seat-math line · card "You're invited to X on Cup Season · cupseason.app/?join=CODE" (`WizardLockShareSheet.swift:29-57`) | Share the invite link (system ShareLink; no Copy message, no code as a code) | Add golfers → People picker · "Later — it lives in the league room" → Clubhouse tab |
| Draft night (formation) | draft-phase room button; `presenter.draft` | dusk · "Form squads · blind draw" · "THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW" · "Minimum four to tee off — 1 in so far. Share the invite link." · empty squad cards · pool (`DraftNightScreen.swift:99-150`) | Pro: Draw squads → Start the season → | Close; member sees the same screen with "See the squads" (M-032) |
| Run it back card | league-less doors / room with a `complete` membership | "Season wrapped · X · Run it back — Season 2 · Same crew, same bylaws, fresh table — change anything in the wizard." (`LeaguelessDoors.swift:67-110`) — shown to every member, not only the Pro | Run it back → the whole wizard again → a **new** league id and code | Close |
| Wizard (web) | doors, hero CTA, `runItBack`; Pro-only gate | same three steps; desktop aside "Your league so far"; "4 Squads" pre-selected in markup (`:3541`) | Lock (`lockBylaws` → `lock_league`, client fallback path) | → `openInviteSheet` (URL · Copy link · Copy message · Share · code) |

### 2.4 Event creation

| Screen | Reached by | First thing shown | Primary action | Exits |
|---|---|---|---|---|
| Event picker | Start an event (any door), occasion cards, "+" | "Start an event · Short form · its own little trophy" · ⚔️ The Ryder "Two teams · weekly vs-index duels · first to the clinch" LIVE · 🥊 Bracket "Knockout · seeded · last golfer standing" SOON (toast "Bracket isn't built yet") · [🏆 A Major — only if `app_flags.ios.major`, absent in prod] · "Every event mints a trophy for your display case." (`EventPickerSheet.swift:21-48`) | The Ryder | Close |
| Ryder setup | picker; run-back prefills | "Start a Ryder · Two teams trade weekly duels against their own numbers — first to the clinch takes it" · Event name · Team A / Team B · Sessions 3–6 · Cadence · First tee (a Sunday — warned after the fact, not constrained) · Attach to a league (optional, **defaults to `preferredLeague`**) · Add players (EventStagePicker) · "How it plays" · "You captain Team A" (`RyderSetupSheet.swift:38-117`) | Create the event → `create_event` → invites (`try?`, errors swallowed) → room | Cancel |
| Ryder room | after create; EventChips; push | "NAME · FORMING" · scoreboard Red 0–0 Blue · "Add players to both teams to set the target." · "Pairings not set." · "No one assigned yet." · taunt toggle · organiser: Invite players · Scrap (`RyderRoomView.swift:10-216`) | organiser: Invite / Generate pairings / Score this session; **no door for a non-member** (CJ-15) | Close |
| Major setup / room | picker (flag; never in prod) | "Start a Major · A championship window — every card on one board, one name on the jug" · Name the jug · final day · window · buy-in · pot pays · run it with a league · Add golfers → room: "A MAJOR · 4 DAYS · FIELD OF 1" · Enter the field · "Needs 2 in the field to open." · Open the window now · Scrap (`MajorSetupSheet.swift`, `MajorRoomView.swift`) | Set the Major / Enter the field | Close |
| Event chips (Clubhouse) | league room top | "NAME · Ryder · Live" / attached Ryder you have not joined: "· Enter the field" (no way in, CJ-15) (`EventChips.swift:24-43`) | tap → event room | — |

### 2.5 Joining

| Screen | Reached by | First thing shown | Primary action | Exits |
|---|---|---|---|---|
| Join a league sheet | doors, "+" Join with a code, or a pending `/?join=` after the card (`RootView.swift:43-48`, which **clears the intent** on appear) | "Join a league · I HAVE A LEAGUE CODE" · code field (or prefilled code, `go()` auto-runs `:49`) · "You're invited to X." once validated (`JoinLeagueFlow.swift:29-64`) | Join → `league_by_code` → `join_covenant_info` → covenant if buy-in > 0 → `join_league` | Cancel (invite lost); error "No league with that code — check with your Pro" |
| Covenant sheet | a league with a buy-in > 0 **only** | "Before you join X · THE FINE PRINT, UP FRONT" · BUY-IN "$50 / player · on the pot sheet" · PRESET "Standard" · PARTICIPATION FLOOR "2 rounds / mo" · FINISH "Cup Final · final 4 weeks" · ledger line (`:125-158`; `Covenant` drops `structure`/`phase` the RPC returns, `JoinLeague.swift:67-74`) | "Join — I'm in for $50" | "Not now" (covenant nils; the code is already cleared) |
| Welcome sheet | after `join_league` | "Welcome to X · THREE THINGS TO KNOW" · (paid: "You're on the pot sheet: $50 buy-in. The Pro tracks who's paid.") · three rules ("You can't hurt your standing by playing badly. Only by not playing." …) · "How scoring works →" · "Who else plays with you? … any member's link works." · "Share the invite link"; **no Done button** (`:173-220`) | Share the invite link | swipe → `onJoined` → Clubhouse tab (a draft league = "Squads are forming · The Pro has the list.") |
| Invite banner Details (Home) | Details on an in-app invite | "A season-long league. Invited by Jerecho" / "A Ryder event — two teams, vs-index duels. Invited by Galen. First tee 2026-09-12." (`PeopleModels.swift:137-141`) | Accept & join → `respond_invite` (**no covenant, no welcome; the $50 is never shown**, YP-12/CJ-22) | Decline |
| People picker (invite mode) | lock share "Add golfers"; room "Add golfers" (Pro); Ryder/Major "Invite players" | "Add golfers · Invited golfers get a notification and choose to join" · search by name/@handle · buddies · Add / Added ✓ / In · "Share an invite link instead" (league mode) (`PeoplePickerSheet.swift:16-99`) — a stranger gets a plain Add (D118 unbuilt) | Add → `invite_golfer` (push "X put you on the tee sheet") | Done |
| Invite door (web) | `/?join=CODE` signed out | the door with the email box open + "Enter your email — X is one step away; you'll review it before you're in." (`:17749-17753`); fallback "You're invited. Enter your email and you're in." (`:20460`) | Go | → code → card → covenant (crew step + orientation skipped) |
| Covenant (web) | six `covenantGate` sites | same four rows; **returns true for $0** (`:17705`) | Join | Not now (code kept; no card shows it) |

### 2.6 Scoring, posting and live play

| Screen | Reached by | First thing shown | Primary action | Exits |
|---|---|---|---|---|
| ⊕ cover "Golf" | ⊕ tab (snaps back); Clubhouse "record door" (`ClubhouseView.swift:171`) | "Golf · Play one live, post one you just finished, or plan the next" · ● LIVE **"Play now — score the group"** (ember hero, 4-line sub) · "Post a round — after you play · Gross + tee, 20 seconds · counts on your card and in every league" · "Plan a tee time — before" · ~1,000 px empty (`PostCoverView.swift:85-116`; SV-22) | Play now | Close; rows |
| Composer "Post a round" | cover row 2; Home lead card (clash/floor); You empty state; every "post" CTA (`postOnComposer`) | dusk preview ("— gross · Enter at least one nine." · "A preview — your league's own math scores it on the books." · league-less: "No league yet? The round still counts on your card…") · COURSE & TEES search · Recent courses ("Papago GC — 72 / 126", unlabeled) · "Rating / slope — / — · edit" (placeholders "72.1"/"128") · YOUR CARD 18/9 · FRONT 9 GROSS · BACK 9 GROSS (**below the fold**; no single Score box) · "Enter your card" · DETAILS pills (date · Scan · Add a photo) · folded "How points work" (`PostRoundScreen.swift`, `PostRoundModel.swift`) | sticky "Post round" (enabled even with rating blank → server refuses, PP-01) | Back → the cover (even when never seen) · "● Play now" toolbar · "Start over — clear this card" |
| Course dropdown / pars / even-par guard / date / scan-pick | inside the composer | "No match — type the course, rating and slope by hand." · "Set the pars · PAPAGO · PARS ONLY" (nine-digit strings) · "Post as even par? · YOU HAVEN'T ENTERED YOUR CARD YET" · calendar (max = tomorrow) · "Whose card is this? · TAP YOUR ROW" | — | — |
| Finish ceremony | successful insert | dusk, ball rolls into cup, serif gross, band sentence ("Beat your number by 2.4"), points line in gold only when earned ("+9 PTS · COUNTS FOR THE PINES") else "PRACTICE · SEASON STARTS SAT SEP 5" / "COUNTS ON YOUR CARD"; asserts "beat your number by N" for a golfer with no number (PP-03) (`FinishCeremonyView.swift`, `PostEpilogue.swift:155-172`) | Share the card (recap PNG) | "Back to the board" (does not go to a board) |
| Epilogue | after the ceremony when rows exist, or the first-ever round | "Your round" / "Welcome to the season ⛳" (also league-less, PP-12) · "84 AT PAPAGO" · band + pts + "counts #2 this month" · milestones ("That one goes on the wall") · rivalry ("You lead Jade 3–1 all-time") · "Share a link — no account needed" · "Turn off this link" (`EpilogueSheet.swift`) | Share | swipe → `onDone` closes the whole cover — **no next act** (PP-02) |
| Partners sheet | a scan carried other rows | "Send their rounds · ONE SCAN, THE WHOLE GROUP" · Copy link per row (`create_scan_claim`; 0 minted in prod) | Copy link | swipe |
| Round receipt | feed, You, board, lead card, push — **never from the post flow** | "84 gross" · "PAPAGO GC · 18 HOLES · 2026-08-22" (ISO) · photo · The course 71.2 / 128 · Your number that day · Playing number · "84 − 71.2 × 113 ⁄ 128 = 11.3 VS COURSE" · "Against your playing number +2.4 — BEAT YOUR NUMBER" · Points · This month COUNTING #2 · Attested · Played with · See the scorecard (`ReceiptSeed.swift:74-211`); no delete, no "Entered by" | — | Scorecard sheet |
| Live setup "Play now" | cover hero; composer toolbar; Clubhouse "Live round"; LiveNowBar; nearby accept | "Set up the round" · optional plan bridge "On your tee sheet today · Load it →" (course + group, no game) · COURSE card (search · "Tee & rating — off the scorecard" Tee/Rating/Slope · 18/9 · par-72 note · "Enter the pars") · THE FOURSOME · 1/4 (2v2/solo seg · dashed slots · chips You / Nearby ASK / You play with / League / Buddies / Guests · "Search the app" · Add a guest Name + Index · 40-word fine print) · GAME "pick one" Just score / Match play / Wolf / Skins / Sunningdale Rules · stake field (four nouns) · strokes preview · "Who's on this tee" Bluetooth card (`LiveSetupView.swift:24-184`) — ~20 concepts, seven eyebrows, no Customize fold (PP-04) | "Tee off →" (solo: 3 taps total) | Close (nothing saved before tee-off) |
| Live round (play) | Tee off / resume / invite | scoreboard band ("ALL SQUARE", "GALEN LEADS · -2 NET THRU 3") · chips · sync badge ("Solo pencil · scores live on this phone") · "Live round · Papago · Blue · 71.2/128" · "Change setup" (orphans the server round, PP-08) · HOLE n · PAR 4 · SI 7 · player rows "12.4 IDX · 3 STK" with −/+ · Side games cards · settlement ledger · Group phones · finish status line · Finish round (& post to season) · 60-word teaching paragraph (stale vs D125a/D107) · two-tap Scrap (`LivePlayView.swift`, `LiveCopy.swift`) | −/+ per player | Close (round continues) · landscape CARD view |
| Finish sheet → Recap | Finish | "ONE FINISH — EVERY CARD POSTS TO ITS GOLFER" · "Complete cards post to the season, attested by the group; 2 guests get a recap to claim." · missing-hole warnings · "Post 3 cards to the season" / "This one was casual — post nothing" → "Round posted · 3 CARDS TO THE SEASON" · result row · hole strip + highlights ("WON 3 STRAIGHT · 4-6") · posted rows "✓ ATTESTED" (unconditional) · guest recap links · Share the card / settlement (`LiveFinishViews.swift`) | Post N cards | swipe → **an empty "Set up the round" screen** (PP-10); posted rows not tappable |
| Nearby invite alert | another phone's ASK | "Join this round? · Jerecho wants you in a round at Papago · Match play." · Join · Not me (`LiveRoundHost.swift:229-241`) | Join → "You're in — waiting for Jerecho to tee off" | Not me |
| LiveNowBar / Live Activity | any tab while live; Dynamic Island | "● LIVE · Papago · Hole 5 →" / "ON THE TEE · Waiting for Jerecho to tee off"; stale at 45 min | tap → host | — |
| Plan a tee time (declare) | cover row 3; calendar; You "Stage it"; "I'm in" on a buddy's plan | "Put a round on the tee sheet · BUDDIES & LEAGUE MATES SEE IT THE MOMENT YOU POST" · Day (next Saturday) · Tee time · optional · Course · Note · Tag your group (buddies + league mates, ≤7; league-less with no buddies: "No one to tag yet. Add buddies from the You tab, or invite the league.") · fine "Posts to your leagues' boards …" (`DeclareRoundSheet.swift:20-80`) — no game, no stake, no "vs" (CJ-19) | "On the tee sheet" → toast "On the tee sheet: the boards know" | Cancel |
| Scheduled round sheet | chips, calendar, Coming up, push | "Sat Sep 12 · 7:40a tee" · course · tee/weather chips · note · rivalry line "◇ you lead 1–0 · one more round." · WHO'S IN · 2 in (rows) · **I'm in / Maybe / Can't only for the host or a tagged golfer** (a buddy seeing two open seats gets no button, persona F) · ON THE BOARD comments · owner: Edit group / Cancel round (`ScheduledRoundSheet.swift`) | I'm in | Done |
| Post (web) | ⊕ → view-record → view-post | eyebrow "Post a round · your index 12.4" · course+tees · rating/slope ("—") · 18/9 · front/back · date · photo/scan · live gross line · calc panel + bands table trailing (`:3361-3474`) | Post round | ← Golf · Start over |

### 2.7 Social, friends and profiles

| Screen | Reached by | First thing shown | Primary action | Exits |
|---|---|---|---|---|
| You (loaded, league) | tab 4 | "You" · ⚙ · hero (photo/crest · name · FOUNDER · `@handle · city · home course` · `est. Aug 2026 · add your GHIN` · marker caption · index in gold or "0 of 3" · ≤3 trophy chips · FORM dots + key) · "Your buddies · Find golfers, see who you play with →" (never the buddy count) · Last round with · YOUR GOLF (Display case · All time · Recent rounds ✕) · YOUR SEASONS (This season strip · Rivalries · all leagues · Every season) (`YouScreen.swift:86-190`) | (reading) | ⚙ · buddies · rows → receipts / Tour Card / Clubhouse |
| You · no rounds (16/39 in prod) | `career.rounds == 0` | hero "0 of 3 · HANDICAP INDEX" · "Building your number…" · ⛳ "No rounds yet — your card fills as you play." · "Post your first round" (`:130-138`) | Post your first round → composer directly | — |
| You · league-less (14/39) | no memberships | as above minus "Your seasons"; All time prints "— / NO COUNTING ROUNDS YET" over nine posted rounds; FORM dots never light (persona F) | — | — |
| Your buddies (People) | You door; Home ↗ / "add some buddies."; "+" Find golfers; Clubhouse "Add golfers"; push | Requests · "Find golfers · Search by name or @handle" · results · "Send an invite link · PIGL · WORKS FOR ANYONE, ACCOUNT OR NOT" (**only if a league has a code** — a league-less golfer has no link, YP-01) · "Buddies · n" / "No buddies yet. Search up top to add them." · Requested (inert; no withdraw) · Findable by All / Buddies / Nobody (`PeopleScreen.swift:26-58,112-129,201-212`) | search / Accept | Person row → Tour Card |
| Tour Card (another golfer) | any name (23 call sites) | "Tour Card · @HANDLE" · credential (photo/crest · name · founding tag · index or "n of 3" · ≤3 milestone chips · FORM) · "VS YOU · 3–2 · YOU LEAD" (only with shared-season clash weeks; name of a christened rivalry dropped, YP-05) · Report photo · Add buddy / Accept / Buddies / Requested · CAREER (Rounds · Best round vs course · Avg vs their number · "Lower is better against the course; against their number, + is better." · Home course · GHIN) · Recent rounds "85 GROSS · PAPAGO GC · VS COURSE 7.8" · 🔇 Mute (`TourCardSheet.swift:38-139`); `courses`/`shared_courses` the server emits are discarded (YP-03) | Add buddy | VS YOU chip → Rivalry sheet |
| Tour Card · own / PRIVATE / failed | own name; server `visible:false` | "Your Tour Card · THIS IS HOW YOUR BUDDIES SEE YOU" (no share) / "PRIVATE · This golfer keeps their card private, or you don't share a league yet." (no Add buddy) / "COULD NOT LOAD … Try again" | — | — |
| Rivalry sheet "You vs Galen" | VS YOU chip only (the You rivalry row opens the Tour Card instead, YP-04) | "3–2 · WEEKLY CLASH · BETTER ROUND VS YOUR PLAYING NUMBER TAKES THE WEEK" · gold name if christened · week cards "WK OF JUL 6 · WON · YOU +1.2 · GALEN −0.4" · "Name this rivalry" (`Rivalries.swift`, `RivalriesSection.swift`) | Name this rivalry → "The Grudge", 40 chars | dismiss |
| Members sheet | League pane "View"; draft toolbar | "Members & invites · 6 PLAYERS · CODE TSTSUN" · rows face · name · THE PRO · "@handle · INDEX 12.4 · SQUAD" · me: "Marker here" · Pro tools per row: Set index · Remove (setup only) / Bye · Make Pro (two-tap arms) · "Invites out ✉ x@y · WAITING" · Add golfers · Share the invite link (`MembersSheet.swift`) | Add golfers | face → Tour Card |
| Last round with | You, threshold-fired (≥3 shared cards, ≥12 months) — cannot fire for anyone yet (DL-32) | "You and Cole — last card together 14 months ago. · 3 rounds shared · one tap stages a Saturday · Stage it · Later" | Stage it → declare sheet prefilled | Later |

### 2.8 Notifications (surfaces; the kinds are in §7)

| Screen | Reached by | First thing shown | Primary action | Exits |
|---|---|---|---|---|
| Settings › Notifications | ⚙ → Settings pane | "NOTIFICATIONS" · pills "Enable on this device" · "Round pings: ON" · "Chat pings: ON" · "Season email: ON" (read the profile flag, not the device, M-136) · unconfirmed line · "Moments, reveals, and month closes always come through." (`CardAndSettingsScreen.swift:487-505`) | pills | OS-denied → toast with no deep link |
| Push toasts | enable / disable | "Notifications on. The board will find you." · "Notifications blocked: allow them in Settings" · "Could not get a device token from Apple. Try again." (`PushService.swift:114-147`) | — | — |
| Lock-screen actions | APNs categories | CS_INVITE Accept · CS_REQUEST Accept/Decline · CS_RSVP I'm in/Can't (`PushPayload.swift:137-143`); failure → local "That one didn't take — open the app." | — | — |

### 2.9 Payment, pot and pricing

| Screen | Reached by | First thing shown | Primary action | Exits |
|---|---|---|---|---|
| Pot pane | strip "Pot" (hidden at $0, D70); Home owe line (`HomeRoute.pot`); "On the line" card | "Season stakes" · gold "The pot · $450 · 6 × $75 · $375 collected · 1 still owe" · trio "$270 Cup champs · $113 Runner-up · $68 Points king" (rounds to $451, CH-25) · [PotPassCard flag-hidden] · "Buy-ins · 5/6 in" · one Button row per member with a dim ✓ (member tap → toast "The Pro marks buy-ins as the money moves between friends") · "The other stakes · pride, on the books · Post a stake" · "No stakes on the books. The cookout isn't going to bet itself." (`PotPane.swift:20-134`); **D129's pay note / due date never rendered** (`LeagueRoomModel.swift:197` omits the columns; CH-03) | Pro: tap a name to mark paid. Member: nothing | Forfeit sheets |
| Forfeit create / settle | "Post a stake" / row "Settle" | "Post a stake · Pride, on the books — never money" · Name it · The shape (Loser hosts / Winner picks the course / Strokes next time / Standing bounty / Name your own) · The terms · Against · Rides on · "Put it on the books" / "Settle the stake · Who took it?" (`PotPane.swift:171-281`); 0 forfeits ever in prod; league-only (`create_forfeit` 'crew only') | Put it on the books | Cancel |
| Home owe line | hero foot, stake > 0, unpaid | "You still owe $75 · Venmo @casey · by Sat Sep 5" or "· ask the Pro how to pay — money moves between you" (`HomeHeroCopy.swift:225-237`); every open until paid | tap → Pot pane (which falls silent) | — |
| Season ceremony | once per member 400 ms after a complete room loads; "See how it ended" | dusk "The Cup Final · Season complete · Priya · took the Cup Final · 38–31 · by 7" · Runner-up · Points king · "You're owed $270 — Cup champion" · "The pot — $450 · collected $375" (PREVIEW when client math) · "Still owed to the pot" · ledger line · "Run it back — Season 2" (`SeasonCeremonyView.swift`) | Run it back | Close |
| Membership card / League pass cards | Settings › Membership; wizard stakes step; Pot pane (Pro) — `pricing.visible=false` in prod | "PLAN · FREE · Everything is free — every league, every event, every round. No trial, nothing to enter." / (flag on) "The league pass · One pass, the whole league … $89 · ≈ $7.40 a player · ✓ Your first year is free." (`MembershipCard.swift:42-45`, `PricingPassCard.swift`) | nothing tappable; no paywall anywhere | — |
| Pot pane (web) | hub › Pot | the pot / payouts trio / ledger line / **How to pay (Pro's note + due)** / buy-ins / "Post a stake" (`:3785-3814, 7962-7963`) | mark paid (Pro) | — |

### 2.10 Empty states (headline rows; the full 68-row inventory is §7.1)

| Screen / state | Copy (exact) | Door |
|---|---|---|
| Home hero · league-less rung 7 | "Your card · 0 of 3 · Three rounds and your index goes live. Nothing else needed." | **none** |
| Home hero · league-less rung 6 | "Established. Nobody's seen it yet — you haven't joined a league." | none |
| Home feed empty (and on network failure) | "No rounds from your buddies yet. Post one, or add some buddies." | "add some buddies." only |
| Standings table empty | "NO ROUNDS YET." / "SQUADS FORM WHEN THE PRO LOCKS — STANDINGS START AT THE FIRST POSTED ROUND." (`LeagueCopy.swift:374-377`) | none |
| Climb empty | "THE RACE STARTS WITH THE FIRST POSTED ROUND" / "SHARE THE LEAGUE CODE TO FILL THE TEE SHEET" (`ClimbView.swift:20-26`) | none (names a share, offers none) |
| Board empty | synthetic "◆ <League> is live — post the first round" whatever the phase, then ~1,300 px of ground and a disabled Send (`BoardStore.swift:105-107`) | none |
| Clubhouse league-less | "Join a league · Start a league · Start an event" + "Post a round — it counts on your card. Leagues score it when you join one." + "Add golfers" | four peer doors, no intent |
| Display case empty | "No hardware yet. Break 80, post your first round, or win a Cup Final — milestones and trophies land here." (shown only to golfers who have posted, EN-28) | none |
| Another member's history | "No rounds this season yet — post one and you're on the board." + Post a round (regardless of whose sheet, M-138) | wrong door |
| Web Home league-less tile | "League · None yet · JOIN OR START" (`:11044`); Board tile "— · LEAGUE ONLY" disabled | dead tile |

### 2.11 Settings

| Screen | Reached by | First thing shown | Primary action | Exits |
|---|---|---|---|---|
| Card & settings · "Your card" pane | You ⚙; "add your GHIN"; push `.settings` | eyebrow "What your buddies see" · segmented Your card / Settings · NAME ON THE CARD · CITY · HOME COURSE · BALL MARKER (14 tiles, above the photo) · YOUR PHOTO (commits immediately) · HANDLE · 60-DAY LOCK (native alert on change — the app's only alert) · FINDABLE BY · GHIN # · Save card / Save changes (no-op toast "Card saved") · HANDICAP INDEX ("Your number is the engine's now · 12.4" / starter editor) · YOUR LEAGUES "PIGL PRO · THEPTCQ5" (inert rows) or the league-less doors (`CardAndSettingsScreen.swift:283-441`) | Save card | ⚙ back |
| Card & settings · "Settings" pane | pane 1 | NOTIFICATIONS (4 pills) · APPEARANCE (Fescue / Light / Auto) · PALETTE dial (13 rows: Follow the calendar · Fescue only · 9 looks · 2 disabled) · MEMBERSHIP (PLAN · FREE) · (league-less doors) · How it works (5 guide rows) · Privacy · Terms · **Prize pool** (→ legal.html "takes no fee or cut" — a retired promise, TM-35) · Sign out (the only full-width button) · DANGER ZONE Delete my account (two-step) · "Cup Season · v1 · build 669" (1-s long-press → Developer) (`:485-609`) | Sign out | — |
| Developer section | 1-s long press on the build line | "Developer" · 📈 Open the desk / ✏️ Field note (founder) · 💬 **Tell us how it's going** (everyone; the only feedback door; 0 rows in prod) (`:590-607`) | feedback | — |
| League pane (room "settings") | strip "League" | Members & invites · Share the season (Link · ✕ arm beside a link that may not exist) · ROSTER OPEN · N IN "Works until you close it, or until first tee — Sat Sep 5." · Roster's set / Reopen · Squads · View · Dress the room · League notices toggle · DisclosureGroup "League rules" → BylawsCard (all-caps engine keys, not doors) → "How scoring & handicaps work →" (four taps deep) (`LeaguePane.swift:29-118`) | — | sheets |
| Card & settings (web) | ⚙ | one 30-row sheet: card fields · index · How scoring works · Your leagues · Notifications (pill wall) · Appearance "Charcoal | Light | Match device" · Membership · Sign out (`:15769+`) | Save card | ✕ |

---

## 3. Flow by flow

Each flow: the user's goal · current friction · unnecessary complexity · confusing terminology (exact strings) · dead ends · redundant actions · missing feedback · opportunities for delight. Findings are cited by id; the file:line evidence is in those findings' source reports and repeated here where it is load-bearing.

### 3.1 Onboarding (door → card → orientation → first Home)

**Goal.** "I downloaded this because a friend mentioned it. Let me see what it is and add a round." The brief: ask handicap / who you play with / what golf you play, then land in a useful Home; understand within seconds.

**Current friction (SAW code; INFER paint).** Phone cold install to a usable Home is **8 surfaces / ~8 taps plus an email round-trip and an app switch**: Forge/email → 8-digit code → card ×3 → orientation → Home, then a notification-permission sheet rising over the very first Home (FR Flow A; `CardGateView.swift:238`, `MainTabView.swift:330-335,444-447`). Persona A: ~4.5 minutes, 10 taps to the first Home, 11 with the sheet dismissed; persona E (invited): ~4:30 and 17 taps to a Home that still did not say what to do on Saturday. The web is 7 surfaces / 7 taps and adds the crew step. The door is a slogan ("Rally your crew. Post real rounds. Take the cup.") with no product sentence on either client (FR-04, PA-004, CC-07; D117 PROPOSED and unbuilt; the definition lives only in `<meta name="description">`, `index.html:22`). Sign in with Apple is built but flag-closed (`app_flags.ios` has no `apple_sign_in`, FR-20), so every phone first run is email-only.

**Unnecessary complexity.** Three card screens where one question would do; a forced choice among fourteen insider marker names with no default (FR-11; "the Pews? No. 2?" — personas A and E); a 60-day handle policy at signup (FR-12); a mandatory third screen for two optional fields spoken in "Starter index / GHIN / USGA record" (FR-13); an explainer slide teaching league vs event and table/board/pot to a golfer who has none of them (FR-03, SV-18, CC-06, WB-31); the orientation carrying both an explainer and three doors plus a pinned exit — five actions on the screen whose job was "thirty seconds, then you're in" (FR-22).

**Confusing terminology.** "this card follows you into every league." · "It changes once every 60 days." · "Pick your ball marker" · "Know your number?" / "Starter index" / "GHIN (a reference on your card — we never resell or verify it)" · "Four places. Two ways to play." · "One league: table, board, pot" · "THE LONG GAME · A league · Months. Every round counts toward a table." · "THE SHORT GAME · An event" (a golf term reused, TM 2b-1) · "0 of 3 · Three rounds and your index goes live. Nothing else needed." · push ask "A round lands on the board. A duel is closing. The table moves." (FR §Flow A; persona A's glossary lists 45 words met before Saturday).

**Dead ends.** The first Home's hero is a fact with no door (FR-01, HM-02): `HomeHero` is a Button only with a membership (`HomeView.swift:801-813`); "Post one" in the empty-feed sentence is plain text (`:123`). A texted code has nowhere to go on the signed-out phone door (FR-21, CJ-06). An invite link opens a door that never mentions the friend or the league — `DoorView` never reads `JoinIntent` (FR-07); opening from the App Store's "Open" rather than re-tapping the link loses the code entirely (persona E). "Not now" on the covenant loses the invite (FR-08). The web's `#obWelcome` "You're in." appears unreachable (FR-36).

**Redundant actions.** The orientation's doors duplicate the "+" menu and the league-less Clubhouse; its places list duplicates the tab bar the user is about to see (FR §A). Three orderings of the same three verbs across crew step, Home doors and Clubhouse on the web (FR-37). Six placements of the same doors on the phone (CJ-40).

**Missing feedback.** No "welcome, NAME" beat after "Save my card" on the phone (FR-35; the web toasts it, `:14977`); after "Take me in" the reward is a permission sheet speaking of boards and duels the golfer does not have (FR-05, EN-16). The web's crew-step and covenant-declined telemetry has never recorded (`qaEvent` keeps `state.demo` guard, `index.html:6900`; FR-09) — the one screen built to move activation is unmeasurable.

**What the brief asked vs what is asked.** Asked: email · name · @handle · marker (required) · starter index · GHIN · an explainer · a permission. Not asked: **who you play with** (never on the phone — the D151 crew step is web-only, FR-02/YP-06/CJ-21/CC-08), **what golf you play** (never on either client; no data home, CC-29/DL-22). Handicap is asked, in insider terms.

**Opportunities for delight.** The Forge is genuinely good (keep). The moment after "Save my card" wants a credential reveal. The web crew step's sentence — "Who are you playing with? Cup Season is a game you play with people you know. Bring them now and your first round already counts for something." — is the best sentence in the walk and should be the first screen after the card on both clients (FR §B). The guest-claim path (`GuestPencilScreen` → door → card with "Saving your card attaches the round you're claiming.") is the one first run that starts from a real round and a real friend — the model for the rest (FR Flow F). The 8-digit code auto-verifying from the Mail notification is a small joy every persona noticed.

### 3.2 Home

**Goal.** In three seconds: what happened, am I winning, what's next, what can I do. ME → NOW as the brief's first two layers.

**Current friction.** Home is an empty dashboard for a golfer with no league and no buddies — the state every golfer starts in, and the one the brief requires the product to serve (HM-01). The league-less hero has no action at all on the phone while the web's identical hero offers three (HM-02). Events do not exist on Home — `native_home` carries `events` and `open_duels`, the phone decodes them and never renders them; an event-only golfer sees "you haven't joined a league" (HM-03). Every non-season hero is a dead end: forming/preseason/wrapped all say "See the table →" to an empty or settled table (HM-05); the forming Pro is told "Lock the bylaws and the invite link is yours" with no door (HM-04; L-32 — every empty state ends in a next move); the wrapped hero says "Run it back." with no run-back door (HM-07; persona B: "a sentence, not a button"); a solo champion is never told their name goes on the cup (HM-06; solo is a first-class structure, D205, and L-17 says the endgame is a sentence you can always see). In season the hero is strong (leader by name, "12 back of Tommy · 4 back of 2nd") but its foot is a 13-pt mono rules/money paragraph (HM-08, SV-10) and the man being chased is "2nd", not "Dre" (persona C; DL-07 — `standing` names only the leader and runner-up). "Add my round" is not on Home in any mode (HM-12). Rung 6 lies when buddies exist — "Nobody's seen it yet" (HM-10; persona F: "Five people I play with see my rounds every week"). A buddy-only round cannot be reacted to, silently (HM-11; persona F could not 🔥 Dev's best). Home re-reads ~13–16 RPCs per open and pull-to-refresh misses chips, calendar, invites and requests (HM-14/15).

**Unnecessary complexity.** Four registers of the same standing on one screen ("2nd of 2 — held" + "4 back of Galen · 15 – 19" + "Best 4 rounds a month count · 1 posted · 26 days left" + the seeding paragraph; SV §F3); the move stated three times when the move card fires (HM-17); live round offered twice (bar + banner, HM-35); creation as a bare "+" with five items in two registers — D176 itself complains "a plus sign reads make something, not go somewhere" (HM-09, CC-37); the wrap vanishes from Home for anyone who also has a live league (HM-26); the hero's league follows the Clubhouse pager as a side effect (HM-38, CH-52).

**Confusing terminology.** "— held" (persona C: "the app didn't notice my Saturday round"; HM-16) · "Month floor 2/4 · 2 more" · "Partial month · floors waived" · "on the books" · "scored fresh" · "Months won breaks it" · "seed" · "Beat their number by 2.4" / "gross" (HM-36) · "league notes" · "+2.4" unlabeled band on the clash card (HM-28) · "Needs you · 2 invites" counting buddy requests (HM-22) · "You's first round" (HM-18) · occasion riddles "Azaleas are blooming somewhere." / "Name the jug" (HM-20) · raw ISO dates and "Ryder invite" for every event (HM-21).

**Dead ends.** The league-less hero (rungs 7 and 6). "Put a round on the calendar →" pushes a calendar rather than the declare sheet (HM-24, FR-28). The occasion "teams" card lands on a generic picker (HM-43); the jug cards lead to a picker without the Major (CJ-16). A network failure with nothing cached reads as "No rounds from your buddies yet." (HM-25, EN-10).

**Redundant actions.** "THE CALENDAR ↗" and "NEXT ROUND ›" both lead to the calendar; "YOUR BUDDIES ↗" and "+ › Find golfers"; the floor said as chip and foot (HM-17; web says it three times, WB-14).

**Missing feedback.** Nothing on Home says "post a round" (personas C, E); nothing says who is directly above me; nothing says what happens when the round is posted; the clash's result arrives as a folded footnote (HM-34); the clash card never says in words who is winning the week (SV-30); no telemetry for hero state or CTA taps on the phone (HM-44).

**Opportunities for delight.** The lead-card ladder, the hero that names the leader with totals, D217 fold, D219 doors, the digest, "Coming up" with weather and headcount (persona F's "that is the group chat, compressed"), the six-reaction vocabulary — all keep (§8). The hero could be the post button at rung 7; rung 5 could name the buddies and offer the smallest competition with them; a settled clash deserves a lead-card face for a day; the wrap deserves a face whatever else is live; the between-seasons Home could carry "Season 2 · not started — Marcus can run it back" (persona B's one line).

### 3.3 Season creation (the wizard, from intent to first tee)

**Goal.** "Get my Saturday group into a season with something on it." The brief: start from intent, ask Who? When? What are we playing for?, advanced settings behind Customize.

**Current friction (SAW; PROD).** Every door is a database noun — "Join a league · Start a league · Start an event" (CJ-01); nowhere can a golfer say "play with friends", "beat Jake", "this Saturday", "money on it". A row is minted at the name sheet before any decision (CJ-03; `WizardScreen.swift:252-268`) and the first invite surface is the share sheet on screen 5 after Lock (D40) — **so a league row can exist, and stay, before anybody has been told it exists**. The default path walks 5 screens and ~48 terms (~75 with Customize) (CJ §2.1). The two things persona D needed — $50 and no teams — are both non-default and both behind Customize (PA-009: D113 ruled the buy-in above "Use these defaults →", unbuilt); the default structure is squads2 for a roster of one, dimmed and selected at once (CJ-14; the web defaults to 4 Squads, WB-22). Every new league opens in a dead week: the default first tee is next Saturday and the invite link is tied to it (CJ-13); persona D locked on a Friday and discovered afterwards that four friends without the app had ~24 hours, with "Cancel & delete this league" as the only fix on screen. There is no non-destructive exit from the wizard (CJ-08; M-016). One preset tap silently sets five bylaws including a floor penalty that is never a dial (CJ-10); "HANDICAP ALLOWANCE 95%" prints on the review against D2/D48 (CJ-10).

**Unnecessary complexity.** Name typed twice; step 0 carries no decision (CJ-07). Nine dials for one decision the brief wants ("what are we playing for?"); six ⓘ paragraphs of 60–90 words written for a second-time Pro (persona D). The bylaws told three times before a second member exists — portrait, review, share line (CJ-31). A pricing card lives inside step 1, flag-hidden (CJ-32). After lock, a squads league is three verbs and a wait (Form the squads · Draw squads · Start the season →) with "Minimum four to tee off — 1 in so far" (CJ-12).

**Confusing terminology.** "Lock the bylaws & form the squads" (squads are minted empty at lock; they fill at the draw, CJ-35) · "Assign" / "Pro assign" / "you seat the squads" · "Solo" / "Individual — no squads" / "SOLO · EVERY PLAYER" (five names, TM-13) · "Cup Final" / "FINAL 4" / "Final 4 weeks · scored fresh" · "1 golfer staged — solo fits" (D97 removed staging) · "Standard rules locked for the season" toast two screens before Lock (CJ-30) · "Points King" undefined until an ⓘ · "−5 SQD PTS SHORT" · "95% hcp · post what you'd post to GHIN · best 3 / mo count · 2-round floor" (persona A: "abbreviation soup"; persona D: "Points King takes 15% of my pot by default") · "One Pro-approved bye month" contradicting D14 (CJ-29, TM-23; the web's copy was fixed, the phone's not) · "the halfway turn" · "the wizard" reaching users (CJ-52) · the code format "DEWS7K2Q" hard to say aloud (CJ-54).

**Dead ends.** The wizard's later steps (no Close). "Bracket · SOON" in the picker. The Members sheet's Remove exists only in setup (CH F8). A first-tee picker that allows the past (CJ-55).

**Redundant actions.** "Share the invite link" on five placements (M8, M9, M23, welcome, room header) — but the first is on screen 5 (CJ §2.1). "Add golfers" ×3 and the code chip ×3 in one room (CH-30). Three landings for one lock (CJ-47).

**Missing feedback.** After "Start the league" the Pro is not told a code exists, that it admits nobody yet, or that abandoning means deleting; after Lock nothing says how many people were told (`invite_open` logged with `sent: 0` unconditionally); "Joins have gone quiet" only after 48 h (CJ §2.1); nothing promises the Pro will be told when someone joins (persona D: "come back here and count to 6"). Whether a real Pro has locked since the fix is unknown — zero `lock_attempt/ok/fail` rows since 2026-08-29 (PA-032).

**Opportunities for delight.** The engine already knows everything needed to make creation a sentence: "The Sunday Cup · you + 3 · first tee Sat Sep 12 · 13 weeks · Standard · bragging rights" — one card, editable inline, Lock underneath. "Bylaws locked ⛳ — One link fills the league" with the text pre-written is persona D's "oh, that's cool" moment (keep, move it earlier). The blind draw's "The hat has spoken" is the one ceremonial beat and members never see it live. The Pro chip could be the first question ("Who runs it? You.") rather than a non-decision.

### 3.4 League creation vs season creation (the two-level model)

The brief asks that League → Season → Event → Match not be the UI. Today it is the UI's own grammar: "Start a league" · "Season length" · "Run it back — Season 2" · "SEASON II · 2ND OF 8" · "your league season is live" · "Leagues & events" (TM-01). A first-timer is asked to hold both nouns before the first round, and the four canonical brand objects (Crew · Cup · Rivalry · the Record, `brand-canon.md:33-37`) are not the UI's nouns (League · Season · Event · Squad · Board · Pot · Card · Tee sheet are). "Run it back" makes a **new** league id and code and the crew must re-join by code (CJ-46, D41 "continuity by convention") — persona B, a member, opened it and found a wizard that would make *her* the Pro of a second "Dew Sweepers" (the same gold button shows to every member with no ownership on it). Nothing distinguishes a league (the crew's standing name) from a season (the thing you join, run and win); the terminology reader proposes the collapse (TM 2b-1 "Season") as a design-phase ruling since D11 named "league" the container.

### 3.5 Event creation (the Ryder, a Major, "we're playing this weekend")

**Goal.** "Two teams of my friends, a few weekends, bragging rights" / "we're playing Saturday, make it count."

**Current friction.** The picker is intent-shaped (good) but the sheets are forms: the Ryder asks eight fields for one decision, warns about its Sunday rule after the fact instead of constraining the picker (CJ-23/24), defaults "Attach to a league" to `preferredLeague` under a label that says optional, then chips "Enter the field" to league mates who cannot enter (CJ-15). The Major is flag-closed on the phone while three Home occasion cards sell it (CJ-16, TM-31). "Start an event" is offered to a golfer with nobody and lands on a room with three empty states (CJ-44). There is no link or code for an event (CJ-45). Events have no Home presence at all (HM-03). One event has ever existed in prod (a completed Ryder); zero Majors — the audit's snapshot, not a verdict on either object. The declared round ("we're playing Saturday") carries no game, no stake, no "vs" (CJ-19); the plan → live bridge fires only on the day and loads course + group but not a game (CJ-48). Live setup builds a foursome, not a match — the game is the third card and "vs" appears nowhere, so nothing in the setup names the competition (CJ-18, CJ-49). ⚠ RE-ARGUE: that live rounds go unfinished *because of this setup* rested only on prod's abandoned-round ratio, struck as behaviour; it needs an escalation from the owner's league or a seeded bot walk of setup → play → finish to stand.

**Unnecessary complexity.** Eleven new nouns on the Major sheet (CJ-25); "Sessions", "Cadence", "vs-index duels", "the clinch", "W-L-H", "SERIES LEVEL", "DEFENDS" (TM-32); sheet-over-sheet for the Ryder (CJ-58); "@?" on every run-it-back invitee (CJ-42).

**Confusing terminology.** "Two teams · weekly vs-index duels · first to the clinch" (unchanged since the prior audit; persona F: "sounds like a month, not a Sunday") · "Every event mints a trophy for your display case." · "Standalone — invite anyone" describing the wrong difference (CJ-57) · "the jug" · "AWAITING THE HORN" · "Yet to card" · "Exhibition" (TM-44) · "the clubhouse" for the Major's leaderboard (TM-30) · "duel" — D12 retired it, the same shape is "the clash" in leagues (TM-15).

**Dead ends.** Bracket → toast. A Ryder invite accepted from the banner lands on Home, not in the room (CJ-17). An attached Ryder's "Enter the field" chip with no door.

**Missing feedback.** "Event created — 3 invited" can be false (invites are fire-and-forget, `try?`, CJ-24). A tagged golfer not on the app gets nothing.

**Opportunities for delight.** The Ryder's duel engine (`event_duels`, `resolve_session`, `event_session_targets`, opt-in taunts, W-L-H) is exactly the pair-vs-own-number machine a "Challenge" needs, wearing team-and-session clothing (CJ-02, DL-01, CC-11). The Ryder taunt push "Galen posted — +2.3 to beat · 3 days left" is the one true anticipation notification in the product (EN §keep). "Nearby · ASK" is the consent grammar a challenge wants (D158). The occasion grammar (an oblique golf moment, one verb, dismiss per year) is the model for every door, every day (CJ-34).

### 3.6 Joining (link, code, in-app invite)

**Goal.** "Know what I am joining before I say yes to $50; get in; know what to do Saturday."

**Current friction.** The joiner decides on four money rows or on nothing: the covenant renders BUY-IN · PRESET · PARTICIPATION FLOOR · FINISH only when buy-in > 0; a $0 league joins from a link with **no consent tap at all** (CJ-04/05, PA-001/002, TM-06; D115 and D136 ruled and unbuilt on both clients; the phone even drops the `structure`/`phase` fields the RPC returns). The Pro's name, the roster, the dates, solo vs squads, whether it has started and how money is paid are never shown before the join; the welcome's "Who else plays with you?" heading is a recruiting pitch, not the roster (persona E: "the most misleading line in the flow"). The welcome has no Done button (persona E swiped on a guess). The in-app invite's one-tap Accept bypasses the covenant and the welcome entirely, so a friend who accepts from the Home banner never sees the $50 (YP-12, CJ-22; persona D's Dev texted "what's this cost?"). "Not now" loses the invite on the phone (`RootView.swift:43`) and keeps it invisibly on the web (PA-003). The signed-out phone door has no code field (CJ-06). Refusals ("<name> isn't open yet — the Pro is still locking in the rules.") arrive after the Join tap though `phase` is available before it (CJ §2.6). Contact/SMS invites were declined by ruling (D136 Q-07) against the brief's friend-connection metric (PA-017). Strangers get a plain Add in the picker (YP-10, PA-016; D118 unbuilt).

**Unnecessary complexity.** Three surfaces, three stories for the floor: covenant "PARTICIPATION FLOOR · 2 rounds / mo" vs scoring sheet "In a solo league the monthly minimum is a habit, not a penalty" vs bylaws "2 / mo · −5 sqd pts / round short" (persona E's #4). The invited golfer on the phone still sees the orientation unless a pending intent exists (PA-005). "THREE THINGS TO KNOW" over four bold items (FR-29, CJ-38).

**Confusing terminology.** "I HAVE A LEAGUE CODE" over a pre-filled code (CJ-37) · "on the pot sheet" (a fifth money noun, TM-35) · "PRESET · Standard" undefined (M-026) · "FINISH · Cup Final · final 4 weeks" · "THE FINE PRINT, UP FRONT" · "No league with that code — check with your Pro" to someone with no Pro (FR-30, YP-30) · "Ryder invite" for any event (CJ-17).

**Dead ends.** Cancel on the join sheet; "Not now" on the covenant; a joiner's first screen in a draft league is a wait ("Squads are forming · The Pro has the list." + "See the squads" → the Pro's draw screen, CJ-39, CH-13).

**Redundant actions.** The web has two code doors before the app exists (door and crew step) and a third on the Clubhouse (WB §F1).

**Missing feedback.** Nothing before the OTP says who runs it or how many are in; nothing says how the $50 is paid on the covenant (PA-011); nothing tells the joiner what to do tomorrow (persona E's #10 — the only Saturday plan on Home exists if the Pro booked a tee time).

**Opportunities for delight.** "Join — I'm in for $50" puts the number in the verb — the best button in the flow (persona E). The welcome's three rules kill the fear at the door ("You can't hurt your standing by playing badly. Only by not playing."). The owe line on Home thirty seconds later ("You still owe $50 · Venmo @casey-ng · by Sat Sep 5") is the store listing's promise made real. Every fact the joiner wants is in the database one join away (D115's own point): faces · first tee · the stake · one rules sentence could be the invite artifact itself, seen before the OTP (PA-001's recommendation).

### 3.7 Scoring (post a round; hole-by-hole; live play; finish)

**Goal.** "I shot 84 at Papago. Put it on my record and see what it did." The brief: course, score, opponents, optional game — done; trivial.

**Current friction (SAW; PROD).** A league-less golfer CAN post (⊕ → cover → Post → course/tee → two nines → Post: 6–10 taps against the cover's promised "20 seconds", PP §tap counts — ⚠ RE-ARGUE: the only measurement of that promise was prod's post_open→post_submit timing, struck as behaviour; the overpromise needs a timed walk of the composer by the owner's league or a seeded bot before "too slow" can be claimed) and CAN play live (⊕ → Play now → Tee off = 3 taps solo). What breaks the brief: **a hand-typed course cannot be posted** — blank rating posts 0, hits the `rounds` check constraint, and the golfer sees a 2.6-s "Post failed" toast with nothing highlighted; the web fixed exactly this as Q-22, the phone did not (PP-01, P0 INFER). The tab says "Post", the cover says "Golf", the first row is "Play now" — posting is the quiet second row behind a tab named for it (TM-03, CC-05, FR-17, SV-22). The composer puts the preview and the course list above the two fields that matter; FRONT 9 / BACK 9 are below the fold; there is no single Score box and an 18-hole total typed into Front 9 silently posts a nine at half value (PP-06, SV-23). No "who did you play with" on a typed round (PP-05) — no rivalry, clash or challenge can hang off it. After the post the flow ends in a close: no receipt door, no "make the next one count", `openReceipt`/`openPeople` links dead-wired (PP-02). The ceremony and the shared PNG assert "beat your number by N" for a golfer with no number (PP-03; D124 violation). Live setup is a settings page — ~20 concepts before Tee off, no who/what/stakes order, no Customize fold (PP-04, SV-24, CJ-18); "Change setup" orphans the server round (PP-08); finishing lands on an empty setup screen with untappable posted rows (PP-10). Placeholders "72.1"/"128" read as values (PA-025).

**Unnecessary complexity.** Tee selection is mandatory in practice because it is the only thing that fills rating/slope; the 18/9 seg, "Enter your card", the pars sheet, the even-par guard and the "How points work" table share one scroll with the two numbers that matter (PP Flow A). The cover is an extra tap for the 90% case (its own header says so, `PostCoverView.swift:5-7`). The epilogue carries "Turn off this link" and revocation fine print on the first-ever round (PP-38). The scan — D36's "fastest way to post" — is a pill under Details rather than a door of its own (PP-18). Four stake nouns across four games (PP-04, CJ-20). The Bluetooth card with a 40-word privacy paragraph on every setup (PP-16). Guest add asks for an "Index" (PP-17).

**Confusing terminology.** "Gross + tee, 20 seconds · counts on your card and in every league" · "Your card" (form eyebrow) vs "counts on your card" (record) vs "Start over — clear this card" vs "Scan the card" vs "Share the card" — five senses on one screen (PP-07, TM-04) · "-0.4 vs your index" beside "Played to your number" (PP-13) · "A preview — your league's own math scores it on the books." to a golfer with no league (PP-14) · "Every posted round scores. Your best few each month count toward your squad" league-less (FR-06) · "Welcome to the season ⛳" with no season (PP-12) · "9 holes · half value" vs the Guide's "a real round" (PP-24) · "Solo pencil" · "12.4 IDX · 3 STK" · "PAR 4 · SI 7" · "EST 18.0 IDX" · "STROKES OFF LOW MAN" · "2 RIDING" · "1 SKIN DIED CARRIED" · "3U" (PP-27/28, TM-33) · "the tee sheet" for the live scorer (D131 assigned it to the calendar, PP-07, TM-08) · "Back to the board" on a button that goes to no board (PP-22) · "auto-attested" / "Only league members' rounds post to the season" (both stale, PP-09) · "✓ ATTESTED" printed unconditionally.

**Dead ends.** PP-01 (the constraint). The whole post flow (PP-02). The recap (PP-10). "Round finished from another phone — the cards posted" ending a visitor's round with a 2.6-s toast (PP-19).

**Redundant actions.** Back from a CTA-opened composer lands on a cover the golfer never saw (PP-21); the ceremony's "Back to the board" + the epilogue's swipe are two dismissals for one moment; the first-round row can print twice (`firstEver` + the `first_round` achievement, PP-12); the plan bridge's "Load it →" plus the same course search below it.

**Missing feedback.** Rating required — never said. Post failure — a toast. Blank rating/slope on live setup silently falls to 72/113. An ASK that gives up after 20 s toasts for 2.6 s. After posting, "what did that do to my standing" is answered only by closing everything and finding the feed; no rank-before/after exists anywhere (DL-06).

**Opportunities for delight.** The composer is already a scorecard, not a form (live gross hero, band sentence, course memory, a tee pick fills rating/slope and real pars); the ceremony (ball-into-cup, `.success` haptic, gold only when earned, the D122 "PRACTICE · SEASON STARTS" line) is the best moment in the app; the draft survives an app kill; degrade-never-dead-end (photo failure posts anyway; scan failures fall to typed entry); the live play screen is the most athletic, golf-first frame in the product (SV §5); the recap's hole strip and highlights; the guest door's first sentence. Add: a "Played with" chip row (the cheapest competition-creation loop in the product — a tagged partner gets "Jerecho posted an 84 with you — post yours?"), a third act after the ceremony keyed to state, camera-first "Snap the card" on the cover, a Score box first.

### 3.8 Social / friends (buddies, invites, reactions, the circle)

**Goal.** Connect a friend in seconds; see my friends' golf; compete with them. The brief's COMMUNITY: friends, groups, recent opponents, rankings.

**Current friction.** The plumbing exists (every name opens a Tour Card from 23 call sites; buddy requests reach Home; search is buddies-first) but the social graph changes almost nothing a golfer sees: friendship changes visibility (feed, tee sheet, Tour Card, invite picking) and **nothing competitive** — no record, ranking, clash or stake can exist between two buddies who share no league (DL §C INFER; `posts_home_check` forbids a post not homed in a league or an event, DL-01). A league-less golfer cannot invite anyone, anywhere — the only invite link is a league's (YP-01, FR-26, WB-24). The phone never asks "who do you play with?" (YP-06). "I want to beat Jake" has no verb — rivalries are a by-product of co-posting in a shared league week and have no front door to christen one; their rows open the Tour Card rather than the rivalry (YP-02/04). Jake's Tour Card does not tell his story with you — no shared seasons, rounds together, rivalry name or hardware; `courses`/`shared_courses` from the server are discarded (YP-03; persona F: "two rulers, no me"). A buddy seeing two open seats on a buddy's round has no I'm in (persona F). A buddy's plan that Home shows as a full card is invisible on the calendar titled "your buddies'" (persona F #4). Reactions are league-only, silently (HM-11). "Findable by · Buddies" means findable by nobody new (YP-11). No unfriend or withdraw (YP-25). `discoverable='nobody'` takes a golfer out of every search (DL-16).

**Unnecessary complexity.** Buddy search in three places on the web (WB-24). "Findable by" in two places on the phone (YP-33). Two vocabularies for one relationship on the server (`rel` vs `status`+`incoming`, DL F3). Ten people-nouns (buddy · golf buddies · crew · league mate · golfers · players · members · roster · the field · the foursome · the pool, TM-38).

**Confusing terminology.** "wants in your crew" (push) vs "wants to be golf buddies" (screen) vs "Buddies" (section) vs "Add golfers" (door) (EN-19) · "Around your buddies" when the circle is buddies plus league mates (YP-40; persona E had zero buddies and saw two) · "Tour Card" (a professional's playing privilege) for a profile (TM-37) · "VS YOU · 3–2 · YOU LEAD" (3–2 of what?) · "85 GROSS · PAPAGO GC · VS COURSE 7.8" (a raw differential, YP-14) · "Mute — hide their posts from your boards" to a golfer with no boards.

**Dead ends.** A PRIVATE card has no Add buddy — the one act that would open it (YP-24). Search miss with no league: "No golfers found under that name. They may not be on Cup Season yet." with no door (YP-09). The Requested section.

**Missing feedback.** After "Add buddy" nothing says what Jake sees next; friend-accept push lands on the Requests list where the accepted request is not (EN-14); a christened rivalry's name is dropped on the chip (YP-05); the rivalry record and the weekly clash can disagree by construction (YP-22, DL-09 — three implementations of one rule).

**Opportunities for delight.** The rivalry naming voice ("Give it a name your crew would actually say — 'The Grudge,' 'Border War.'") is right and only needs a front door. `my_friends` already returns every friend's `index_current` — a friends board is one client sort away (DL A). `home_feed`'s circle is already buddies ∪ league-mates ∪ event co-players. A person-level "play with me" link, a "Played with" capture at post time, and a Challenge object (§9) would turn the watching half into the doing half (persona F's verdict).

### 3.9 Profiles (You, the Tour Card, the record)

**Goal.** "Who am I here and how am I doing?" The brief's ME (my golf, standing, streaks, friends) and HISTORY (career, rivalries, records).

**Current friction.** You is record-first: three screens of statistics under two group heads, standing ("Every season") last, rivalries below a four-row stats strip (YP-07, SV-27 — vision principle 4 "Memory > Statistics" inverted). An empty card says "not yet" with one verb (YP-08). A league-less You has no competitive content at all and its comparison surfaces go to dashes and grey FORM dots ("— / NO COUNTING ROUNDS YET" over nine posted rounds; persona F: "this looks broken"). The hero's largest glyph on an empty card is a fraction, "0 of 3" (YP-16). "Leagues & events · Played in 2" is a figure with no door. The buddies door never reports the buddy count (YP-44).

**Unnecessary complexity.** Two stat panels with identical row names differing only by head (YP F1). Five gold elements on one identity card dilute the metal (SV-07). Achievements as emoji clip-art, two sharing a glyph, one round minting two "Broke N" tiles (SV-08/09, YP-15).

**Confusing terminology.** "Best vs your playing number" · "Avg vs your playing number" · "across 4 counting rounds" · "No counting rounds yet" · "Index move ▲ 1.2 · SEASON TO DATE" · "Leagues & events · PLAYED IN" · "FORM" bare · "Rivalries · all leagues" (league-mates only, DL-28) · "Iron Man" naming two objects (TM-14) · "Your number is the engine's now · 12.4" / "crew-policed" (YP-20) · GHIN visible to buddies (YP-26) · `est. Aug 2026` and admin facts in mono on the identity card (SV-39).

**Dead ends.** The empty display case has no next move (SV-44). The "+N more in the case" chip. Own Tour Card cannot be shared (YP-36).

**Redundant actions.** Own Tour Card repeats the You hero with a different frame.

**Missing feedback.** Whether `FormRowView` renders the streak tag (`3 STRAIGHT UNDER`) is unverified; the PB history is overwritten server-side (DL-13); `career_record.seasons_done` counts paying seasons only, so every golfer shows 0 seasons and $0 (DL-14/15).

**Opportunities for delight.** The hero object — photo-owned credential, marker medallion, gold index once earned, FORM with a key, the trophy engraving — is "the best object in the app" (YP §keep, SV §5 "reads as a magazine cover"). Lead the lower half with rivalries and every season (the memories), fold the four figures into one serif sentence, make "the Record" the name of a place (TM-HISTORY).

### 3.10 Notifications

**Goal.** Anticipation, never manufactured engagement; one tap to the right place.

**Current friction (SAW; PROD).** No production phone has ever registered for push — one `ios-sandbox` token; the ask shown once ever; `invites` 0 rows (EN-01). Push fans by `league_members`, so a golfer with no league is never notified about golf even though Home shows a buddy's round (EN-02). Multi-league members get the same round and month-close N times (per-league post ids differ, nothing collapses, EN-03). None of the brief's anticipation notifications exist — no rank change, points-to-next, seat count, challenge, or season-start countdown; the vision's own "League lead changed. Championship clinched." has no producer (EN-04). Three invitations wear one title "<First> put you on the tee sheet" — league invite, RSVP tag, live-round nudge (EN-05). The duel reminder only schedules if you opened the room that day (EN-06). The ask precedes the aha: it fires at card-save over the very first Home and snoozes 14 days (EN-16, FR-05). Settings pills read "ON" while the device is off (EN-12, M-136).

**Unnecessary complexity.** Four pills plus a fine line naming "Moments, reveals, and month closes" — schema kinds as settings copy (TM-46). Foreground banners for the screen you are on (EN-30).

**Confusing terminology.** "Round pings" · "Chat pings" · "Enable on this device" · "A duel is closing. The table moves." · "wants in your crew" · email footer "Manage notifications in your Tour Card" (wrong place, EN-19) · web Ryder-invite detail "vs-index duels" (EN-34).

**Dead ends.** OS-denied → toast with no deep link to Settings; `MustUpdateView` with no store button (EN-17); the founder's report nudge routes Home (EN-25); web notification taps always land Home (EN-13); the season email CTA opens the web root (EN-32).

**Missing feedback.** After "Turn on notifications" the only reply is a toast; no preview of what the first one will say. Nothing is ever said to a golfer about their own golf ("your number's live: 14.2").

**Opportunities for delight.** The push explainer's three lines are brand canon ("Nothing else. No streaks, no noise, no badge you didn't earn."); the badge counts only actionable items and seen clears it (D179); lock-screen I'm in / Can't and Accept / Decline; the Ryder taunt ("Galen posted — +2.3 to beat · 3 days left") is the brief's notification already built — generalise it to leagues and challenges under D23's fence; the season-recap email's subject carries the margin ("The Cup goes to Galen by 12 — PIGL").

### 3.11 Payment, pot and pricing

**Goal (member).** How much, to whom, how, by when. **(Pro)** Who has paid. **(Brief)** "we want money on it" as an intent, App-Review-safe.

**Current friction.** The Pot pane cannot say how money gets paid: D129's terms (`buy_in_note`, `buy_in_due_on`) exist server-side and reach Home's owe line but never the pane (`LeagueRoomModel.swift:197` omits them, 0 refs in `PotPane.swift`; CH-03, PA-010); a member's row tap only toasts "The Pro marks buy-ins as the money moves between friends" (CH-24); persona C left the app to text Ray. The pane omits the terms even when the Pro has set them (PA-009); with no `season_payouts` row an earnings surface renders zero rather than saying it has nothing to show yet (DL-15). The buy-in is still a dial behind Customize (PA-009); "$20 on it" is impossible — the ladder is 0/25/50/75/100/150/200 (CJ-20). Money has four vocabularies (buy-in / stake per side / dollars per skin / bank unit) and "stake" means money on one pane and never-money on the next (TM-05, CH-26; D131 unbuilt). The payout trio rounds $450 to $451 (CH-25). Points King takes 15% of the pot by default and is undefined (persona D).

**Unnecessary complexity.** A five-field sheet for a one-sentence pride bet (CH F5). A flag-hidden pricing card between the trio and the buy-ins (CH F4) and inside the wizard's step 1 (CJ-32). The "Prize pool" legal link whose page still promises "takes no fee or cut" — a promise the brand canon retired (TM-35).

**Confusing terminology.** "the pot" · "pot sheet" · "the books" · "on the books" · "ledger" · "stake" · "Prize pool" — seven money nouns (TM-35) · "Season stakes" vs "The other stakes · pride, on the books" · "Cup champs" (D131 → "the winning squad") · "champ / 2nd / king" · four phrasings of the pot's status across strip, hero, head and Home (CH-53).

**Dead ends.** A member has no action on the Pot pane except pride bets. The covenant never says how or when the $50 is paid (PA-011).

**Missing feedback.** Pro marking a buy-in: haptic only. A member cannot nudge the Pro. Money is the loudest daily line under the standing ("You still owe $75" in warm on every open, HM-27).

**Pricing (dormant, correct).** One flag (`pricing.visible=false`), three inert cards, a durable free line ("Everything is free — every league, every event, every round. No trial, nothing to enter."); nothing gates value; D183 parks the question at 1,000 golfers (YP F11). The wizard is the one place a price could ever sit inside a creation flow (YP-48) — never mid-form when it returns.

**Opportunities for delight.** "You still owe $75 · Venmo @casey · by Sat Sep 5" is the clearest money copy in the product — put it on the pane it links to. The ceremony's "You're owed $270 — Cup champion" and "Still owed to the pot" by name are the emotional payoff; the season-long pane could carry "If it ended today: you'd take $270". "The cookout isn't going to bet itself." is the right voice for pride bets — make the whole forfeit one line.

### 3.12 Empty states

**Goal.** Every empty state an opportunity, never a failure (brief); "quiet icon · one line in voice · one next move" (IOS-003 §3).

**Current friction.** 68 states mapped (53 phone, 15 web; §7.1). `CSEmptyState` exists with a CTA slot and the door is optional; ~25 empties use bare `CSFine`/`Text` with no door (EN-36). The league-less Home hero is the loudest empty in the product and has no door on the phone (EN-23). Standings and climb empties are ALL-CAPS mechanics with no door — "SHARE THE LEAGUE CODE TO FILL THE TEE SHEET" with no share (EN-08, CH-15). The Board's empty row announces "is live — post the first round" whatever the phase, a phrase D120 retired (EN-09); an empty board is a blank page under a disabled Send (SV-03; unchanged Aug 29 → Sep 4). Home's network failure reads as a social verdict (EN-10). Another member's empty history invites *me* to post (EN-11, M-138). "Add buddies from the You tab." is a route description, not a door (EN-21). The occasion calendar is dark for eight weeks either side of today (EN-24). The web carries the banned literal "League · None yet · JOIN OR START" and raw "Boot stalled at [step]" strings (EN-27, EN-07). The display case tells a golfer who has posted to "post your first round" (EN-28). The trophy case and the You "All time" strip look broken rather than empty without a league (persona F). An empty Clubhouse tab is four peer buttons and a sign that says build one (persona F: "this tab isn't for me").

**Confusing terminology in empties.** "the slate is still clean" · "waiting on its first counter" · "snapshot writes Sunday night" (EN-20) · "seeds" / "roster" / "pool" · "THE BOARD SEEDS FROM YOUR ROSTER ONCE INVITES LAND" (EN-22) · "Bracket isn't built yet" (EN-29).

**What already works.** The one-line-one-door pattern where it is used (You's "No rounds yet — your card fills as you play." + Post your first round; the race's CSEmptyState; the album); "Put a round on the calendar →" as the empty state; skeletons not spinners; Y-17 "never 'nothing yet' while the reads are still out"; partial failure says so and offers Retry; structure hidden over an empty room (D178); search-miss distinguished from list-empty (D178); the digest's quiet frame; voice where it lands ("The cookout isn't going to bet itself.", "No cards yet — first one takes the clubhouse.", "Just you so far — tag your group.").

**Constraint.** Empty states cannot be filled with sample content: D83/D84 forbid fiction and D27 forbids fabrication (CC-21). The ruled pattern is D81's ladder of next-unmet facts plus doors and real facts (the golfer's own rounds, the bands, the calendar, the tee sheet).

### 3.13 Settings

**Goal.** Notifications, look, account — quickly.

**Current friction.** ~60 controls behind one ⚙ across two panes (YP-18): a 13-row palette dial sits above notifications, membership, help, legal, sign out and delete; the card pane is five kinds of thing under one Save (identity, reach, reference, the index engine, an inert league list) with two commit models (photo immediate, text on Save) and a no-op "Card saved" toast (YP-19, M-141). Feedback is hidden behind a one-second long press on the build line (YP-27; the web shows a visible chip). ⚠ RE-ARGUE: that the hiding has cost real feedback rested only on the empty `feedback` table, struck as behaviour; without a tester escalation the finding stands on the gesture alone. The handle change is the app's one native alert, against IOS-003 §4 (YP-28). "How it works" (help) lives in settings; "Your leagues" (the Clubhouse's) and "Findable by" (People's) are duplicated here.

**Confusing terminology.** "Danger zone" · "Round pings" · "Chat pings" · "Prize pool" · "Handle · 60-day lock" · "Fescue only · Homebase, all year" · look names (Azaleas · Silver · The Test · Stars · Claret · Two Teams …) undefined (TM-45) · "Membership · PLAN · FREE" on a product with league memberships (TM-50) · "Moments, reveals, and month closes" (TM-46).

**Dead ends.** "No leagues yet. Start one or join with a code." as text (EN-33). Inert "Your leagues · PRO · CODE" rows printing the join code under identity (YP-34).

**What already works.** Handle safety (abandoned handles held, four consequences stated before the change, D159); delete-account copy tells the truth about what stays; the two-step arm with a VoiceOver announcement; the developer tooling out of the golfer's way (the right instinct even though it swallowed the feedback door); the palette system itself (looks tint spines and washes only, L-28).

---

## 4. The Home state matrix — as it exists today (phone, SAW)

`HomeMode` distinguishes exactly six modes (`Models.swift:286-292`): `leagueless(rung 7 | rung 6)`, `forming`, `preseason`, `season`, `cupFinal`, `wrapped`. Everything else the brief lists is a cross-cutting slot or is not distinguished. The hero is a door only with a membership (`HomeView.swift:802-812`). Web CTAs are noted where they differ.

| State | Hero eyebrow · figure · line (quoted) | Foot lines | Hero door | Lead card can be | Feed when empty | Up Next / Coming up | Primary action offered |
|---|---|---|---|---|---|---|---|
| **Rung 7** — no live league, `rounds_count < 3` | "Your card" · "0 of 3" · "Three rounds and your index goes live. Nothing else needed." (`HomeView.swift:875,895,951`) | none | **none** (not a Button) | milestone only (a buddy's PB/first/sub-80 today) | "No rounds from your buddies yet. Post one, or add some buddies." | no month chip; "Put a round on the calendar →"; occasion "fresh" Dec 27–Jan 15 only | **nothing on the card.** The ⊕ tab or "+" menu. Web: "Post your first round" |
| **Rung 6** — no live league, `rounds_count ≥ 3`, **buddies ignored** | "Your card" · "12.4" (or "—") · "Established. Nobody's seen it yet — you haven't joined a league." (`:952`) | none | none | milestone only | same | same | nothing. Web rung 6: "Find your buddies"; web rung 5: "Four makes a league. You have 3." + Start a league. **The phone has no rung 5** |
| **Buddies but no league** | identical to rung 6/7 — the buddies are not acknowledged; "Nobody's seen it yet" is false (their feeds carry your rounds via `home_feed`) | — | — | milestone | buddies' rounds DO appear (so not empty) but carry no reaction strip | "Buddy's playing" chip possible | none |
| **No buddies, no league** | rung 6/7 | — | — | none in practice | the empty sentence; visit 2+: "Quiet since your last visit · Yesterday — You posted 91 at Papago" (your own round, HM-42) | — | none |
| **Invited** (league or event) | whatever mode applies | — | — | — | — | "NEEDS YOU · 1 invite ›" | Accept in the banner (no covenant); orientation skipped only for a pending link intent, not a server-side invite |
| **Forming — setup** (no season, phase setup) | "My Cup · forming" · "—" · Pro: "Your league is still forming. Lock the bylaws and the invite link is yours." / member: "Galen is setting the bylaws. You'll see them the moment they lock." (`:881-882,897-898,956-962`) | cap only ("Best 3 rounds a month count"); endgame nil; money nil | → STANDINGS, which reads "NO ROUNDS YET. / SQUADS FORM WHEN THE PRO LOCKS — …"; "See the table →" | milestone only | usual | **"MONTH CLOSES · in N days ›" appears** (gate is `hasMemberships`, HM-13) | **none** — the lock lives in the Clubhouse League pane; nothing points there. Web: "Name your league" / "Lock it in and invite your crew". L-32: an empty state ends in a next move |
| **Forming — draft** | "Fellas · squads drawing" · days or "—" · Pro: "Bylaws locked. Draw the squads when the crew is in." / member: "Galen draws the squads before first tee — it's random." | cap; endgame; **money** "$150 on the books · $0 collected · 2 still owe"; owe line | → STANDINGS (empty) | milestone | usual | month chip | none. Web: "Share the invite link" / "Draw the squads" |
| **Preseason** (`starts_on` > today) | "Fellas · before first tee" · "26d" · "First tee in 26 days. Rounds before it build your number." (`:883,899-901,965-968`) | cap; the 40-word endgame sentence; money; owe | → STANDINGS (empty) | milestone (no clash before week 1) | usual | month chip (meaningless — edge month waived) | none on the card. Web: "Plan a round" + "Post a round". The D121 row for a *different* preseason league knows "First tee Sat Sep 5 · 5 on the roster"; the hero for *this* one never says the roster (HM-29) |
| **Season week 1** | "Winter Circuit · week 1 of 24" · rank ordinal · "Level with Galen · 0 – 0." or "Standings start at the first posted round." | squads: "Partial month · floors waived" / solo: "Best 4 rounds a month count · 0 posted · 26 days left in September"; endgame; money; owe | → STANDINGS | **clash** (two-person league, idle, shows once: "It's the two of you — every week is the clash." / "Post a round"); bigger league idle → yields; floor no; move no (no `prev_rank`); milestone | usual | month chip ≤10 days | clash card's "Post a round" when it fires; else none |
| **Mid-season, up** | "Fellas · week 7 of 26" · "1st" "of 2" · chip "▲ up 1" · "You lead Jade by 22 · 31 – 9" / "6 clear of Jade"; gold wash at rank 1 | rule ("Month floor 2/4 · 2 more" / "Month floor met · 6/4" / solo cap+posted+clock); endgame; money; owe; "See the table →" | → STANDINGS | ladder: clash → floor (≤3 days, squads only) → **move** ("Up 1" / "See the table") → milestone | usual | month chip; next round; buddy's playing | lead card's verb; else nothing but the table |
| **Mid-season, down** | chip "▼ down 1" · "12 back of Galen · 9 – 21" (n=2) / "12 back of Galen · 3 back of 2nd" (rank>2; the neighbour unnamed) | same | same | move: "Down 1" | | | |
| **Mid-season, held** | chip "— held" (mut) · same lines; "Level with Galen · 14 – 14." | same | same | no move card; clash / floor / milestone | | | |
| **Clash open, I'm in it** (`home_clash` non-null) | any season hero | | | "The clash · closes today" / "You v Galen. Best round of the week takes it." / "You — 83 · +2.4 · SAT" V "Galen — Nothing posted" / "See the receipt" · "Post a better one" · "Post a round"; a named rivalry replaces "The clash" | | | the card's verb |
| **Floor short, month closing** (squads, ≤3 days, not partial) | | "Month floor 2/4 · 2 more" | | "The month closes in 2 days" / "You're 2 short of the floor. One round covers it." / "Post a round" | | "MONTH CLOSES · in 2 days" (warm) | composer |
| **Cup final — finalist** | "Sunset Match · cup final" · "1st" "seed" (gold at seed 1) · "Four weeks, scored fresh. Whoever's hottest takes the cup. 1 week left." | rule; endgame (still the "seed into…" sentence, now past); money; owe | → STANDINGS | clash / floor / milestone; move never | usual | month chip | none beyond the table |
| **Cup final — non-finalist** | "5th" "of 8" · "Galen v Jade for the cup. Your place on the table is still live — 12 back of Galen. 1 week left." | same | same | same | | | |
| **Wrapped** — shown only when every membership has wrapped; a wrapped league beside a live one is invisible on Home (HM-26) | "Sandbox · season wrapped" · "3rd" "of 4" · squads champion: gold + "Your name goes on the cup."; everyone else **including a solo champion**: "The cup's been lifted. Run it back." (`:869,980-981`) | none | → STANDINGS; "See the table →" | milestone only | usual | month chip still appears | **no run-back door on Home** (`RunItBackCard` lives in `LeaguelessDoors` and the room). Web: "Season recap →" + "Run it back — Season 2" |
| **Multiple leagues** | hero = `preferredLeague` if in the pool, else server order (phase season first, then `joined_at desc`) | | | lead card pinned to its league | | | D121 rows re-render Home; "and N more → Clubhouse" |
| **Live round open** | any | | | | | | slot 5 card + LiveNowBar, both to the same cover |
| **Events only** (in an event, no league) | **rung 6/7 hero** — nothing about the event, its duel, its deadline | | | milestone (event-mates' rounds are in the circle) | event-mates' rounds appear; event posts do not | "NEEDS YOU" only for a pending invite | none |
| **Sandbox** | `sandbox` decoded and ignored by `HomeMode` — a sandbox-only member gets a real "season wrapped" hero (HM-37, INFER) | | | | | | |
| **Network failure, nothing cached** | last hero | | | | "No rounds from your buddies yet." (`:283-288`) | | pull to refresh |

Cross-cutting slots that render in any mode: invites banner (server invites), buddy requests, live banner + bar, occasion card (calendar windows only), digest (second visit on), Coming up (never vanishes).

---

## 5. The persona results

Six blind walks. Each persona saw only the App Store listing, the screenshots and what the SwiftUI views render for their state. Scores are their own, out of 10. The tables are their five-question answers at the **first Home**.

### 5.1 Persona A — Tyler, the new golfer · score 4 · goal not reached

Tyler (31, Scottsdale, shoots ~90, no handicap) wants one Saturday competition with three friends who are not on the app. He installed for the listing's one paragraph about the live round and skins. The door, eight-digit code, three-step card (marker quiz, "Know your number?") and the orientation took ~4.5 minutes and 10 taps; the orientation's "two ways to play" — "Months" and "A weekend or a few weeks" — offered no third door for one round. His first Home was a non-tappable "YOUR CARD · 0 of 3 · Three rounds and your index goes live. Nothing else needed." with the previous screen's three doors gone behind an unlabeled "+". He found the right tool for his goal — ⊕ → "Play now — score the group … Friends without the app just play" — by exploring, but Close saves nothing, so Saturday could not be staged on Friday night. The only door that hands out an invite is "Start a league", so he made "Saturday Boys": a 13-week, two-squad, $25 season whose first tee is tomorrow and whose code, per the fine print, stops working at first tee. **Stalled at** the Clubhouse after locking — "Saturday Boys · Squads drawing · SQUADS DRAWING · ROSTERS PENDING", Home saying "1d · Bylaws locked. Draw the squads when the crew is in." — with three friends who have not installed and no sentence saying what Saturday's round is worth to a golfer with no index. His real-life plan: leave the league standing and use "Play now" on the first tee.

| Q | Answered? | Time / taps | Evidence |
|---|---|---|---|
| Q1 What is happening | Partly | ~3 s · 0 | "YOUR CARD · 0 of 3 …" — nothing states the app's state for me |
| Q2 Why it matters | No | — | "Nothing else needed" reads as "you're done" |
| Q3 What can I do | Partly | ~15 s · 1 to discover | "Post one, or add some buddies." · "Put a round on the calendar →" · the doors hidden in "+" |
| Q4 Who am I competing with | No | 0 | "No rounds from your buddies yet." |
| Q5 What happens next | No | — | only "0 of 3" is forward-looking |

*Explain to a friend:* "Cup Season is a fantasy-league app for a golf crew: somebody sets up a months-long season with squads and a pot, everyone posts real scores, and the scores turn into points against your own handicap. Buried under the plus button in the middle there's also a live scorer for skins, match play and Wolf that works for one round with anyone, even guys without the app — that part is what you and I would actually use on a Saturday; the season part is for a group that plays all year."

Cool moment: the ⊕ cover's "Friends without the app just play; their card is waiting when they want it." and the guest row "Name · Index · Add · Leave index blank for an estimated 18."

### 5.2 Persona B — Dana, between seasons · score 4 · goal not reached

Dana (44, Tempe, 14.1, 4th of 8 in Dew Sweepers, which wrapped two weeks ago; six buddies, 22 rounds, one Iron Man trophy; not the Pro) opened the app on a Tuesday evening asking "What should I do?" Home led with a tombstone: "DEW SWEEPERS · SEASON WRAPPED / 4th of 8 / The cup's been lifted. Run it back. / See the table →" — the winner unnamed, "Run it back" a sentence not a door, the card opening the standings. Below it the feed was genuinely alive (three buddy rounds since her last visit). The room contradicted itself: "Season complete · settled" over "Post 2 more rounds this month — best 3 count, you've posted 0." over "TOP 2 ADVANCE TO THE CUP FINAL" and "Priya lead by 9 · Marcus a good weekend back." **Stalled at** the gold "Run it back — Season 2" button (tap 5–6), which opened a wizard already named "Dew Sweepers · S2" with "Run it back — last season's bylaws carried over. Review and lock." — as a member she could not tell whether locking would make her the organiser of a rival league, whether Marcus would be told, or whether the crew would be invited; the same button shows to every member. She cancelled and texted Marcus. The board's last message was Jules on Aug 18: "when's S2 Marcus" — unanswered.

| Q | Answered? | Time / taps | Evidence |
|---|---|---|---|
| Q1 | Yes, mostly | ~2 s · 0 | "SEASON WRAPPED" · "The cup's been lifted." — the winner's name is one tap down |
| Q2 | No | — | "4th of 8" is a finish, not a stake; nothing says what 4th means now |
| Q3 | Partly | ~8 s · 0 | doors exist; none answers what to do; "Run it back." leads to the table |
| Q4 | No | — | nobody named; "Priya · 0–2 THEY LEAD" is on You, three screens away, as history |
| Q5 | No | — | nothing says whether there will be a Season 2, when, or who decides |

*Explain to a friend:* "It's the app our golf league ran on — you post your scores, it works out your handicap and points, there's a table and a chat board. Our season ended two weeks ago. Right now it shows me I came 4th, that Priya won, my Iron Man trophy, and a feed of who's still posting rounds. There's a big gold 'Run it back — Season 2' button but it's the same button for everyone, so I think if I pressed it I'd become the organiser. Until Marcus starts a new one, it's a nice trophy cabinet."

Cool moment: "Dana · Iron Man · 14 rounds" on the race tile and the same trophy on her display case — "the app kept score of the thing I actually did"; the ceremony's "Priya · took the Cup Final · 38–31 · by 7".

### 5.3 Persona C — Marcus, the active competitor · score 6 · goal reached (by brute force)

Marcus (38, Chandler, 9.8, 3rd of 8 in a solo league, week 7 of 26, Dre 4 ahead, Tommy 12 ahead, owes $50, tagged on Dre's Saturday round) asked "Where do I stand and what do I need to do next?" The first half was answered instantly and well — "DESERT DOGS · WEEK 7 OF 26 / 3rd of 8 / 12 back of Tommy · 4 back of 2nd" — the best first screen of any league app he has used, with two wrinkles: "— held" after a Saturday climb (measured from Sunday's snapshot, never said) and the man he is chasing named only as "2nd". The second half was never stated: no "post a round", "pay Ray", or "RSVP" — facts, not actions. The Climb was his "oh, that's cool" (a table built around him, "Dre Wilson · 4 ahead of you", "CUT LINE · 4 BACK", Kev "6 behind you") but its caption called Dre "the top seed" (wrong — Tommy is). Working out what beating Dre takes needed Clubhouse › LEAGUE › League rules › "How scoring & handicaps work →" (5 taps) to find the 5/6/7/9/12 bands, then his own arithmetic. Paying: the owe line landed on the Pot pane, tapping his own row toasted "The Pro marks buy-ins…"; no name, note, due date or handle on the money screen, so he left the app to text Ray. Saturday's RSVP (2 taps, "I'm in" goes green) was "the one thing that felt like a normal app".

| Q | Answered? | Time / taps | Evidence |
|---|---|---|---|
| Q1 | Yes | ~2 s · 0 | "3rd of 8 / 12 back of Tommy · 4 back of 2nd" |
| Q2 | Partly | ~15 s · 0 | the Cup Final sentence + the books + the owe line; "4 out of the Final" never said |
| Q3 | No (implied) | verbs 1–5 taps away | only verb on the hero is "See the table →" |
| Q4 | Partly | 0 / 1 tap + scroll | leader named; the chased man is "2nd" until the Climb |
| Q5 | Partly | ~10 s · 0 | "Sat Sep 5 · Papago with Dre"; "Week closes Sun · 2d" only in the Clubhouse strip; the clash never explained |

*Explain to a friend:* "It's a season-long golf league app: everyone posts real rounds from wherever they play, each round earns 5 to 12 points depending on how you did against your own handicap, your best four a month count, and the top two after 26 weeks play a four-week shootout for the cup and most of the $400 pot. Home tells you your place and gaps in one glance, the Clubhouse has the full table built around you, and the money is a ledger the commissioner ticks off — you still Venmo him yourself."

Ten taps and one leave-the-app "for something a single 'Next' line on the hero could have done in zero."

### 5.4 Persona D — Casey, the organiser · score 5 · goal not reached

Casey (46, Phoenix, runs a Saturday game for six with a Google Sheet and a $50 pot; two friends already on the app) wanted six friends in a season. Home hid the door — the three doors seen on the orientation vanished behind a bare "+" ("add a score?"). The wizard was three steps once found; her two must-haves — $50 and no teams — were both non-default and both behind "Customize", with "Use these defaults →" big and orange above it. "2 Squads" was selected and dimmed at once; "1 golfer staged — solo fits" left "staged" undefined; the portrait said "THE POT $50" for a $300 pot. The review kept "Squad formation — Blind draw" and "−5 sqd pts" in a solo league and listed a "king" taking 15% she never chose. She read "The code works until first tee" as boilerplate. **Stalled at** the League pane after locking: "ROSTER OPEN · 1 IN · Works until you close it, or until first tee — Sat Sep 5." — tomorrow; the link already texted to six people; the bylaws locked with no edit; the only fix on screen "Cancel & delete this league". Whether six get in was out of her hands. Dev, accepting the in-app invite from his Home banner, never saw the $50.

| Q | Answered? | Time / taps | Evidence |
|---|---|---|---|
| Q1 | Partly | ~5 s · 0 | nothing is happening; the screen thinks I'm here to build a handicap |
| Q2 | No | — | no league sentence on a league-less Home |
| Q3 | Partly | ~20 s · 1 to discover | start a league = a bare "+" whose only label is for VoiceOver |
| Q4 | Yes (nobody) | ~2 s | "No rounds from your buddies yet." |
| Q5 | No | — | "Three rounds and your index goes live" — not "invite your crew" |

*Explain to a friend:* "It's a league app for our Saturday game — you post your scores, it handicaps everyone off real rounds, keeps a table for the season and tracks who's paid into the pot; I set it up once, texted you a link, and if you're in by Saturday every round you post counts toward a cup in December."

12 decision points before anything shareable existed; 3 actively made; 9 defaults accepted, two of them (first tee, Points King) she would not have accepted had she understood them. Cool moment: "Bylaws locked ⛳ — One link fills the league" with the text already written; and, via Dev, the covenant "BUY-IN $50 … [Not now]" — "the app is going to do the nagging for me."

### 5.5 Persona E — Jordan, the invited joiner · score 6 · goal not reached

Jordan (29, Mesa, shoots 95–100, never had a handicap) was texted "cupseason.app/?join=THEPTCQ5 — get in, $50, starts Saturday". After install, neither the door nor the three-step card acknowledged the invite for four screens; he went back to Messages and re-tapped the link on a guess (had he opened from the App Store's "Open", the code would never have been captured). The covenant was the best screen so far ("Join — I'm in for $50" puts the number in the verb) and raised the most questions (PRESET · Standard? pot sheet? who else is in?). The welcome's "Who else plays with you?" was a recruiting pitch he read as the roster; it had no Done button. Home named the league, the countdown ("1d"), the pot and — the single most useful line — "You still owe $50 · Venmo @casey-ng · by Sat Sep 5". The roster appeared 19 taps in (the standings table) or 23 (Members). The floor rule was stated three ways across covenant, scoring sheet and bylaws; a solo league said "SQUADS LOCKED", "Squad formation", "−5 sqd pts" and "the squad race". "What do I actually do Saturday?" was never answered: the only Saturday plan existed because Casey booked a tee time, and the verb "post a round" lived behind the bare ⊕. He texted Casey.

| Q | Answered? | Cost | Evidence |
|---|---|---|---|
| Q1 | Yes | ~3 s · 0 extra | "THE PUTT CLUB · BEFORE FIRST TEE · 1d · First tee in 1 day. Rounds before it build your number." |
| Q2 | Partly | ~30 s re-reading | the books + the owe line; the split two taps away; no sentence about my stake beyond a due date |
| Q3 | Weakly | — | pay Casey; "See the table →"; RSVP only if Casey booked; nothing says "post a round" |
| Q4 | No, not at Home | 2 or 6 taps | eight names only in the Clubhouse table / Members sheet |
| Q5 | Partly | ~20 s | "First tee in 1 day" + Casey's booking + the endgame sentence in small mono jargon |

*Explain to a friend:* "It's a golf league app: you post your real scores after you play, any course, and each round is worth 5 to 12 points based on how you did against your own handicap — so my 98 can score the same as Casey's 80 if we both played to our number. Best three rounds a month count, you're supposed to post at least two, and after three months the top two play a four-week final for a $400 pot, $240 to the winner. The $50 goes to Casey on Venmo, not the app; the app just keeps the tab." (Sayable only after the Clubhouse and the scoring sheet; at the first Home, only the first and last sentences.)

### 5.6 Persona F — Priya, buddies but no league · score 5 · goal not reached

Priya (35, Gilbert, 6.4, five buddies, nine rounds, no league) asked "Is something happening in my golf world, and is there a reason to make Sunday count?" Home answered the first half well: "SINCE YOU WERE HERE · 2 rounds and a personal best from Dev.", the Today card, "BUDDY'S PLAYING · Tash · sun", and the Coming up card with tee time, headcount, a comment and the weather ("the group chat, compressed"). The hero told her "Established. Nobody's seen it yet — you haven't joined a league." when five people see her rounds every week. She could not 🔥 Dev's best (reactions are league-only, silently); Tash's Sunday round sheet showed "WHO'S IN · 2 in" and no I'm in / Maybe / Can't for an untagged buddy; the calendar titled "yours, your buddies', your leagues'" had no dot on the Sunday Home had just shown; declaring her own Sunday round made a second, competing Sunday with two chips for one round; You's "All time" printed "— / NO COUNTING ROUNDS YET" over nine rounds and every FORM dot was grey; Dev's Tour Card had "two rulers, no me". The live Match Play / Wolf / Skins door that would make Sunday count was never linked to the Sunday round. The Clubhouse tab was three doors and "Add golfers" — "this tab isn't for me". She put the phone down and texted the group chat: "Whirlwind Sunday 7:10 — Dev's on a heater, skins?" — the sentence she wanted the app to write.

| Q | Answered? | Time / taps | Evidence |
|---|---|---|---|
| Q1 | Yes | ~5 s · 0 | the digest line, Dev's PB card, Tash's chip and Coming up card |
| Q2 | No | — | the only sentence about me is the hero, and it is false-feeling |
| Q3 | Partly | ~15 s · 1 to act | doors visible; no way to react or to say I'm in |
| Q4 | No | — | no standing, no buddy table, no head-to-head |
| Q5 | Partly | ~5 s · 0 | what happens for Tash; nothing for me |

*Explain to a friend:* "It's a golf app where you post your rounds and it keeps your handicap; add your friends and Home shows their rounds and who's playing when, with the weather. Join a league and it becomes a season with standings and a weekly match — but without one it mostly just watches: I could see Dev's best round but couldn't fire-emoji it, and I could see Tash's Sunday tee time but couldn't say I'm in."

### 5.7 The cross-persona pattern

1. **Nobody reached their goal on the first Home; one reached it at all, by brute force.** Scores 4–6. Every persona left the app to text a person: Tyler (a group text with a link that dies tomorrow), Dana (Marcus), Marcus (Ray, for a Venmo handle), Casey (the group: "DOWNLOAD IT TONIGHT"), Jordan (Casey: "what do I do Saturday?"), Priya (the group chat: "skins?"). In every case the app held the facts and did not turn them into a sentence.

2. **Q1 is answered; Q3 never is.** "What is happening" was Yes or Partly for six of six (the in-season and pre-season heroes are strong; even the tombstone says "wrapped"). "What can I do right now" was No or Partly for six of six: the hero's only verb is "See the table →", "post a round" is a tab that does not post, the doors live behind a bare "+", and the one instruction the product offers a member ("Post 2 more rounds this month") lives one tab over and contradicts itself.

3. **Q2 fails for everyone outside a live season.** Four personas got "No" on "why it matters": the league-less hero ("Nothing else needed"), the wrapped hero ("4th of 8"), the buddies-only hero ("Nobody's seen it yet"). Only the two golfers inside a live or imminent season got "Partly", and only by re-reading a 40-word endgame sentence.

4. **Q4 is a name at most.** The leader is named in season; the man being chased is "2nd"; the roster is 19–23 taps from an invite; a buddy is never a rival; between seasons nobody is named at all. Five of six could not say who they were competing with at the first Home.

5. **The database's model is the one they learn.** The 30-second explanations reconstruct league → Pro → bylaws → squads → season → best-N-a-month → floor → Cup Final "scored fresh" → pot split — the prior audit found 8/8 doing the same (PA §3.4). Two of six reached for "fantasy league". Nobody said ME → NOW → COMPETE. The product's four canonical objects (Crew · Cup · Rivalry · the Record) appear in no explanation.

6. **The same ten strings hurt everyone.** "Nothing else needed" · the bare "+" · "SQUADS LOCKED / Squad formation / −5 sqd pts / the squad race" in solo leagues (A, C, D, E) · the floor said three ways (C, E) · "scored fresh / seed / Months won breaks it" (A, C, E) · "the Pro" undefined when money is owed (C, E) · "tee sheet" vs "calendar" (B, F) · "Use these defaults →" hiding the two decisions that mattered (A, D) · "The code works until first tee" with first tee tomorrow (A, D) · "Run it back" with no owner (B).

7. **The "oh, that's cool" moments are all already built and all buried.** The live scorer with guests (A), the Iron Man on the display case and the ceremony (B), the Climb (C), "Bylaws locked ⛳ — One link fills the league" and the covenant (D), "Join — I'm in for $50" and "Venmo @casey-ng · by Sat Sep 5" (E), the Coming up card with weather (F). Each is one to fifteen taps from where the persona started. The redesign's job is to move them to the front, not to invent them.

8. **First tee tomorrow is a trap two personas fell into** (A, D): the wizard's default first tee is the next Saturday and the invite link is tied to it; both locked on a Friday and learned afterwards that friends without the app had ~24 hours.

9. **The watching half is good; the doing half is missing** (F's verdict, true of B and E too): feed, digest, Coming up, weather, headcount — then no reaction, no I'm in, no game on the plan, no roster at the join, no run-back door.

---

## 6. Terminology inventory (condensed to the rows that matter)

The full inventory (eight tables, ~130 rows, with first-contact citations) is in the terminology reader. This section keeps the collisions that decide whether a first-timer can read the product, and the rulings each row would touch. Verdicts: KEEP · DEFINE (keep, define at first contact) · RENAME → · HIDE (engine word). "Status" = whether a ruling already covers it and whether that ruling is built.

### 6.1 Five ruled collisions still shipping

| Term | Senses in the binary (SAW) | Ruling | Status | Verdict |
|---|---|---|---|---|
| **card** | the profile ("Your card", "Card & settings", "golfer card", "Tour Card"); the record ("counts on your card", "lands on your card", "HIT YOUR CARD", "Pinned to your card"); the scorecard ("Your card" form eyebrow, "Enter your card", "Scan the card", "Course card", "EST. CARD", "3 CARDS READY"); the artifact ("Share the card", settlement card); a Major's entry ("No card", "Yet to card") — ≥8 senses; 16 record-sense strings on the phone, 11 on the web (TM-04, PP-07, YP-17) | D131: card = the golfer card only; the hole-by-hole thing = the scorecard; the record sense retires → "posts to your rounds — every league you're in reads it" | **unbuilt**; "COUNTS ON YOUR CARD" is still the finish fallback (`PostEpilogue.swift:163`) — the string every prior tester read as "counted" | RENAME → profile "your card"; "your scorecard"; "your rounds / your record"; artifacts by name |
| **stake / the books** | money ("$150 on the books", "Stake per side", "$0 STAKE") and never-money ("The other stakes · pride, on the books", "Post a stake", "Put it on the books", "The pot stays money; this never is.") on one pane (`PotPane.swift:133-223`) (TM-05, CH-26) | D131: stake = money on a live game only; pride bets = **forfeits**; the books = money, full stop | **unbuilt** (the `forfeits` table already carries the noun) | RENAME → "Forfeits · pride, never money" · "Post a forfeit" · "Put it on the record" |
| **tee sheet** | the calendar ("Put a round on the tee sheet") and the live scorer ("On your tee sheet today", "Marcus put you on the tee sheet", "3 on the sheet · synced", "You're on a live tee sheet") — 18 phone strings, 27 web (TM-08, PP-07) | D131: tee sheet = the shared calendar; the live scorer = "a live round" | **unbuilt** | RENAME → Schedule for the calendar; "live round" for the scorer |
| **cup points / Cup champs** | "HANDICAPS · CUP POINTS · THE MONEY" (`GuideCopy.swift:90,122`); "CHAMPS $315 · RUNNER-UP · POINTS KING"; "Cup champion" (`PotMath.swift:120`) (TM-40) | D131: "Cup points" → "points"; "Cup champs" → "the winning squad"; "Cups & events" → "Leagues & events" (built, D208) | partly built | as ruled |
| **the Pro** | "THE PRO · GALEN" (room header), "ask the Pro how to pay" (Home owe line), "check with your Pro" (join error), "THE PRO" chip (Members, setup checklist), "Pro — that's you" (wizard, defined only for the person who is it); 0 hits for "runs the league" in either client; three of eight prior testers read it as the club professional (TM-02, CC-19, PA-015) | D132 RULING: "the Pro" stays (owner declined "Commissioner") and is DEFINED at first contact — orientation's league card, covenant WHO row, Clubhouse chip "THE PRO · GALEN · runs the league" | retirements built; **definition unbuilt** | DEFINE ("Casey runs the league (the Pro)") — the noun is immutable; the definition is owed |

### 6.2 The containers (the brief's "league vs season" problem)

| Term | First contact | Problem | Verdict |
|---|---|---|---|
| **League** | Orientation "THE LONG GAME · A league · Months. Every round counts toward a table." | clear as a word; indistinguishable from a season until "Run it back — Season 2" / "SEASON II" | KEEP the word; collapse the pair |
| **Season** | Home eyebrow "week 3 of 13"; wizard "Season length"; "Season live / complete"; "Season 2" | never defined; the two-level model is the UI's grammar (TM-01) | RENAME (structural): **season** = the thing you join/run/win ("Start a season", "Season 2 of the Fellas"); **league** = the crew's standing name only. *Overrides D11's "league is the container" at the UI level; the data model keeps both* |
| **Event / the short game / the long game** | Orientation | "event" is a category, never a thing a golfer says; "short game" is chipping and putting; D12 said "event" is schema-only and it is not enforced | RENAME → name the things ("Start a Ryder", "Set a Major"); "A season" / "A weekend" as heads |
| **the cup** | Door "Take the cup." | the app's name and its least-defined word: the season title, cup points, Cup Final, "Cups" (trophy count), the Ryder's prize, "Your name goes on the cup" | DEFINE once ("The cup is the season title"); HIDE "cup points"; the Ryder awards "the Ryder" |
| **the Ryder** | Picker "Two teams · weekly vs-index duels · first to the clinch" | three undefined tokens in nine words, unchanged since the prior audit | KEEP the name; DEFINE in plain words ("Two teams. Every week each of you plays one opponent, scored against your own number. First team past halfway wins.") |
| **a Major** | Guide, picker (flagged off in prod) | promised by orientation, guide and listing; unreachable on the phone | KEEP; ship it or stop promising it |
| **Bracket · SOON** | Picker | a toast since July | HIDE until built |

### 6.3 The places and the standings

| Term | Problem | Verdict |
|---|---|---|
| **Post (tab) → Golf (cover) → Play now (row 1)** | three names for the do-a-round door; "Post" implies after-the-fact, the cover leads with live (TM-03, CC-05) | RENAME → one verb family: tab **Play** (or Round); rows "Score live now · Add a round you played · Plan a round" |
| **Standings · the table · the climb · the race** | four nouns for one list ("See the table →", "Season race · the climb", "The individual race", "NOBODY TO RACE YET") (TM-10) | RENAME → **Standings** on doors and heads; race/table only inside prose |
| **the Board / on the board / the boards** | never defined; "on the board" doubles as a standings idiom ("post one and you're on the board") (TM-29) | DEFINE once ("the Board — where the league talks and rounds land"); say "on the standings" when meant |
| **Clubhouse** | fine as a tab word; reused for the Major's leaderboard ("first one takes the clubhouse") (TM-30); the blueprint's slot was "Compete" and D11 retired "clubhouse" from copy (CC-04) | KEEP or restore the question; "Leaderboard" for the Major |
| **League (pane)** | "The league… is a tab inside the league?" | RENAME → "Settings" / "The rules & the roster" |
| **Schedule · Your golf calendar · the tee sheet · the calendar · Stage it · Plan a tee time · Declared round** | three nouns and four verbs for one thing (TM-39, TM-48) | RENAME → **Schedule** + **Plan a round** |
| **buddy / crew / league mate / golfers / players / members / roster / the field / the foursome / the pool / squad** | ten people-nouns; buddy vs league mate defined only in the guide (TM-38) | KEEP buddy (define on the Buddies head) · league mate · golfers (headcount); "the pool" → "not yet on a squad"; "the field" → "who's playing"; crew as register only |
| **Tour Card** | a professional's playing privilege, used for a profile (TM-37) | RENAME → "‹Name›'s card" once "card" stops meaning the scorecard |

### 6.4 The clock and the stages

| Term | Problem | Verdict |
|---|---|---|
| **Forming · Squads drawing · Before first tee · Season live · Cup Final · Season complete** | one producer, lint-checked (D120/D136) — **built** | KEEP; sweep the leftovers below |
| **"Squads are forming — The Pro has the list." · "Squad formation" · "LIVE NOW — CAPTAINS READY" · "Complete · rosters locked" · "SQUADS LOCKED" · "1 OF 4 IN — 3 SEATS OPEN" · "THE HAT SHUFFLES SERVER-SIDE" · "THE BOARD SEEDS FROM YOUR ROSTER ONCE INVITES LAND" · "CAPT. —"** | D120 retired these strings; the stage labels were built and the surrounding strings were not swept (TM-21, PA-008) | HIDE all but the stage label + "Draw the squads" + "The hat has spoken" |
| **Season wrapped vs Season complete** | two words for the end state (TM-25) | one |
| **Wk 3 / 13 · Week 3 of 13 · week 3 of 13 · W3 · WK 1 · Δ Wk** | six formats and two definitions of "week" (TM-26, DL-05) | "Week 3 of 13" everywhere; "Since Sunday" for the delta; one producer |
| **Cup Final · the Final · FINAL 4 · scored fresh · fresh slate · regular season · carries +10 · seed** | the endgame sentence is finally on Home — in engine words (TM-07; personas C and E read it three times) | DEFINE: "The last four weeks are the Cup Final. Points restart at zero — the leader starts +10 — and the most points in those four weeks takes the cup. Tied? Months won decides." |
| **seed / SEEDS LOCKED / A CUP SEED / seeds into / EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS / CUT LINE** | playoff jargon on a beer-league table; "seeds" as a verb elsewhere; D136 chose IN over SEEDED for the badge but the captions survive (TM-09) | RENAME → "in the Final" / "starts the Final +10"; D127's sentences |
| **IN** | six senses on one phone: clinched badge · headcount ("5 IN") · paid ("buy-in in") · RSVP ("I'm in") · consent ("Join — I'm in for $50") · welcome ("You're in.") (TM-27) | the badge reads "In the Final ✓" |
| **LIVE** | available (picker), a live round (bar), a live season (stage), a live Major (TM-28) | reserve for a round in progress |
| **— held** | "held since when?" (persona C thought his round was missed) (HM-16) | drop when nothing moved, or "same as last week" |
| **Month closes … · floors assessed · Partial month · floors waived · short month** | "closes = locked?"; two adjectives for one thing | say the consequence: "September's rounds lock Oct 1 — 1 more makes your minimum" |
| **bye · Pro-approved bye month** | the wizard ⓘ contradicts D14 (automatic); the web fixed it, the phone not (TM-23) | KEEP "bye"; fix the ⓘ |

### 6.5 Scoring and the number

| Term | Problem | Verdict |
|---|---|---|
| **your number · index · Handicap index · IDX · EST 18.0 IDX · SELF · starter · playing number · Your number that day · vs course** | eight names for two numbers (TM-36); "playing number" met on You before it is defined (TM-20); "vs index" and bare signed numbers survive on the race table and receipts after D209/D210 (TM-19, SV-04) | "your number" everywhere; "Handicap index" only as the card's figure label; "vs your number" with the arithmetic on the receipt |
| **Torched it · Beat your number · Played to it · A little loose · Posted anyway** | one producer, golf-native, the best-understood mechanic — every persona who met the table praised it (five taps deep) | KEEP; amend spec §2.2's Read column to match |
| **counting cap · COUNTING CAP · counter · counting round · bumped · "NO COUNTING ROUNDS YET"** | D51 said never "counting cap"; the bylaws row still prints it; "counting" toward what? (persona F) | "Best 3 rounds a month count"; "counting round"; keep "bumped" |
| **floor · Participation floor · Month floor 2/4 · short of the floor · monthly minimum** | "floor" is a ceiling word; the guide uses both in one paragraph; consequence stated three ways (TM-16) | "monthly minimum" ("2 a month · 1 to go") |
| **allowance · HANDICAP ALLOWANCE 95% · 95% hcp** | D2/D8/D48 withheld it from user surfaces; the preset cards and the bylaws print it | HIDE from presets; in the rules "Scored at 95% of your number", tappable |
| **Casual · Standard · Cutthroat · PRESET · Standard rules** | met outside the wizard with no sentence (TM-17) | carry `presetSummary`'s first clause wherever the name appears |
| **attested · auto-attested · Attested · PLAYED WITH THE GROUP · receipts required** | ×8 phone, ×12 web; D13/D125 say "vouch" (TM-18) | "vouched by the group" |
| **9 holes · half value · HALF A ROUND** | undefined vs the Guide's "a real round" (TM-55, PP-24) | "nine holes count half a round" |

### 6.6 Money, live play, the guest

| Term | Problem | Verdict |
|---|---|---|
| **the pot · pot sheet · the books · ledger · buy-in · stake · Prize pool** | seven nouns; "Prize pool" is sportsbook vocabulary and its legal page promises "takes no fee or cut" (TM-35) | "the pot"; "on the books" for money only; the ledger line verbatim; legal link "The pot (legal)" |
| **Points King · king · Points crown · champ · CHAMPS · Cup champion** | three spellings, undefined until fine print; takes 15% by default (TM-14) | "Points King" · "Champion" · "Runner-up" |
| **Iron Man (award) vs Iron man (12-week streak badge)** | one name, two objects (TM-14) | badge → "12 weeks running" |
| **Just score · Stroke play · THE ROUND** | three names for the no-game mode | one |
| **Wolf · Skins · Sunningdale Rules · riding · DIED CARRIED · bank a unit · 3U · SI 15 · the stepper · STROKES OFF LOW MAN · STK** | teaching appears only once the seat count is legal (D133 unbuilt); "riding" → "carried over" ruled; "the stepper" is a widget word (TM-33) | D133 as written; "carried over" · "never claimed" · "3 units" · "HCP 15" · "strokes" |
| **BRAGGING POINTS · Wolf's points** | collide with season points (TM-41) | "Wolf points"; add D133's "never touch season points" |
| **pencil · claim link · recap link · scorecard link · settlement link** | five names for the guest's one link (TM-34) | "your scorecard link"; "Keep this round" |
| **lock · lock it in · Lock the bylaws & form the squads · Lock opens the invite link · locked at first tee · Rosters locked · SEEDS LOCKED · Order locks** | three moments, one verb (TM-24; prior audit #10) | "Publish the season" (the tap); "Rules freeze at first tee" (the date); nothing else locks |
| **bylaws · League rules · Season settings · The stakes, the rules, the format** | three names for one thing; "bylaws" reads as legal (TM 2b-7) | "the rules" |
| **Blind draw · Assign · Pro assign · Draft night · the draft · the pool · the hat** | "draft" (pick) and "draw" (random) sound alike and are opposites here; "Draft night" titles a random draw; the store says "Captains draft squads" (TM-22) | "The draw"; "Random draw" / "Pro picks the squads" |

### 6.7 The engine's vocabulary that still reaches users (the log said it would not)

`HANDICAP ALLOWANCE 95%` · `COUNTING CAP` · `PARTICIPATION FLOOR · −5 sqd pts / round short` · `SEEDS LOCKED` · `A CUP SEED` · `EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS` · `CUT LINE` · `LIVE NOW — CAPTAINS READY` · `The Pro has the list.` · `THE HAT SHUFFLES SERVER-SIDE` · `One Pro-approved bye month` · `Attested` ×8 · `vs index` · `Δ Wk` · `R` · `IDX · STK · U · W-L-H · sqd pts · rds · wks` · `Moments, reveals, and month closes` · `the wizard` · `server-side` · `snapshot writes Sunday night` · `the stepper` — every one cited in TM §0 and §3.

### 6.8 The proposal table, by the brief's hierarchy (draft; the design phase decides)

The terminology reader's full draft table (TM §3b) organises replacements under ME / NOW / COMPETE / COMMUNITY / HISTORY and names the ruling each row would override. The rows most likely to be contested: **Season** as the thing you join (overrides D11 at the UI level); **Play** as the tab (overrides D110's naming, not its ember-live rule); **the Pro** — define or take D132's recorded alternative (Commissioner); **playing number** folded into "your number" with the arithmetic on the receipt (touches D209's labels); "the Record" made a place on You (brand canon §1/§5).

---

## 7. Empty states and notifications inventory

### 7.1 Empty, loading and error states (68 mapped: 53 phone, 15 web)

Columns: state · exact copy · door. "none" = the copy names a next move but nothing on that surface performs it. Full tables with file:line in the empty-states reader (EN §1a–1f).

**Boot and door**

| State | Copy | Door |
|---|---|---|
| Boot restoring | "Restoring your session" (on a cold launch with no session too) | — |
| Boot failed | "Boot stalled" · human reason · Try again · **Sign out** (throws the session away for a connectivity problem) | Try again |
| Must update | "Update Cup Season · This build is behind the season. Grab the newest one from TestFlight or the App Store, then come back." | **none** — no link |
| Code idle 20 s | "No code yet? Check spam for the newest Cup Season email — older codes retire when a new one sends." | Resend |
| Orientation (once) | "Four places. Two ways to play." | Take me in |
| Web boot stalled | "Boot stalled at [memberships] — network or auth hang" / "Boot failed at [step]: <raw error>" | none |

**Home**

| State | Copy | Door |
|---|---|---|
| Hero · league-less, < 3 rounds | "Your card · 0 of 3 · Three rounds and your index goes live. Nothing else needed." | **none** on the hero (web: "Post your first round") |
| Hero · league-less, ≥ 3 rounds | "Established. Nobody's seen it yet — you haven't joined a league." | none (web: "Find your buddies") |
| Hero · forming (member / Pro) | "<Pro> is setting the bylaws. You'll see them the moment they lock." / "Your league is still forming. Lock the bylaws and the invite link is yours." | tap → an empty table |
| Hero · preseason | "First tee in N days. Rounds before it build your number." | table |
| Hero · wrapped | "The cup's been lifted. Run it back." / "Your name goes on the cup." (squads only) | table; the run-back door lives elsewhere |
| Feed loading | three redacted rows | — |
| Feed empty **and** feed read failed with nothing cached | "No rounds from your buddies yet. Post one, or add some buddies." | "add some buddies." only |
| Coming up empty | "Put a round on the calendar →" | ScheduleScreen (not the declare sheet) |
| Occasion | six calendar windows; dark Jul 25 → Sep 17 | the card's act (jug cards → a picker without the Major) |
| Digest quiet | "Quiet since your last visit · <day> — Rosa broke 80 — 74 at Papago GC" (can resurface your own round) | receipt |
| Web tile league-less | "League · None yet · JOIN OR START" · Board tile "— · LEAGUE ONLY" disabled | hub / dead |

**Clubhouse**

| State | Copy | Door |
|---|---|---|
| League-less tab | LeaguelessDoors + "Post a round — it counts on your card. Leagues score it when you join one." + Add golfers | four peer doors |
| Room loading / failed | "Loading the room…" (hero skeleton only) / "The room did not load" · Try again | Try again |
| Standings table empty | "NO ROUNDS YET." / "SQUADS FORM WHEN THE PRO LOCKS — STANDINGS START AT THE FIRST POSTED ROUND." (solo: "INDIVIDUAL RACE — NO SQUADS." / "…TOP 2 MEET IN THE CUP FINAL.") | **none** |
| Climb empty | "THE RACE STARTS WITH THE FIRST POSTED ROUND" / "SHARE THE LEAGUE CODE TO FILL THE TEE SHEET" | **none** — no share |
| Individual race empty | ⛳ "The race fills in once your league season is live and rounds land." + Post a round | ⊕ hub (not the composer) |
| Squad receipt empty | "No rounds posted yet — the squad is waiting on its first counter." | none |
| Player receipt empty (any player) | ⛳ "No rounds this season yet — post one and you're on the board." + Post a round — not gated on `row.me` | wrong door |
| Cup Final race empty | "No counting rounds in the window yet — the slate is still clean." | none |
| Pot $0 / stakes empty | "No buy-ins — this league plays for bragging rights." / "No stakes on the books. The cookout isn't going to bet itself." | (Post a stake) |
| Album empty | 📷 "Photos land here when rounds carry them — add one from the Post card." + Post a round | ⊕ hub |
| Board loading / empty / failed | BoardSkeleton / synthetic "◆ <League> is live — post the first round" dated today, whatever the phase, over ~1,300 px of ground and a disabled Send / toast "Could not load the board." over a blank list | none / none |
| Schedule tee sheet empty | "Nothing on the tee sheet for <Month>. Put one up: league mates and buddies see it the moment you do." | button elsewhere |
| Week by week empty | "Nothing recorded yet: the first snapshot writes Sunday night, and every week lands here for the season." (wrong for any non-Sunday-closing league) | none |
| Round sheet · RSVP / comments / tag picker empty | "Just you so far — tag your group." / "No messages yet — kick it off." / "No one to tag yet. Add buddies from the You tab." | (+) / field / **none** |
| Declare tag empty | "No one to tag yet. Add buddies from the You tab, or invite the league." (league-less: no league to invite) | none |
| Course search miss | "No match — type the course, rating and slope by hand." / "No rated tees listed — type the rating and slope by hand." | manual fields (which then cannot post, PP-01) |
| Event room error / no event | "The room did not load" / "No event loaded." | Try again / none |
| Ryder roster / session empty | "No one assigned yet." / "Pairings not set." (organiser: Generate pairings) | organiser only |
| Major no cards | "No cards yet — first one takes the clubhouse." · "No card · buy-in stays in the pot" | none |
| Event picker Bracket | toast "Bracket isn't built yet" | none |
| Draft error / pool empty / squads empty / done | "The room did not load" / "Pool is empty. Players appear here as they join with the league code." / "Squad formation · Waiting on the players · THE BOARD SEEDS FROM YOUR ROSTER ONCE INVITES LAND" / "Pool's empty. Every player has a squad." · "Squads are set / Good luck, everybody / Rosters locked · season opens W1" | Try again / none / none / Start (Pro) |

**Post and live**

| State | Copy | Door |
|---|---|---|
| Composer, no league | "No league yet? The round still counts on your card — points apply in any league you join." | — |
| Composer, no number | "No number yet — this round starts it" (D124) | — |
| Hole grid empty on Post | "Post as even par? · YOU HAVEN'T ENTERED YOUR CARD YET" | Post / back |
| Live setup, no league mates | "No league mates to tap yet — search the app or add a guest below." | search / guest |
| Pickers empty query / miss | "Type a name or @handle to search — buddies you add appear here." / "No golfers found. Invite links still work for everyone else." | search / none |
| Live guests empty / finish nothing | "No guests in this round." / "Nothing to post." | — |
| LiveNowBar | "LIVE" / "ON THE TEE" + line | live cover |
| Wizard loading / missing | "Loading the wizard…" / toast "No league with that id — it may have been deleted." | — |

**You, People, Settings**

| State | Copy | Door |
|---|---|---|
| You loading | placeholder bars (never "nothing yet" while reads are out, Y-17) | — |
| You no rounds | ⛳ "No rounds yet — your card fills as you play." + Post your first round | composer |
| You partial failure | "Some of your card did not load. Retry"; tiles "—" "Did not load" | Retry |
| Trophy case empty | "No hardware yet. Break 80, post your first round, or win a Cup Final — milestones and trophies land here." (shown only to golfers with rounds) | none |
| Rivalries | hidden at 0; sheet: "No head-to-head weeks yet. A clash counts a week you both post." | Name this rivalry |
| Tour Card loading / failed / private | "Pulling the card…" / "Could not pull the card — check your signal and try again." Try again / "This golfer keeps their card private, or you don't share a league yet." | Try again / **no Add buddy** |
| Buddies empty / search miss | "No buddies yet. Search up top to add them." / "No golfers found under that name. They may not be on Cup Season yet." (+ "The link below works for anyone." only if a league has a code) | search / none for the league-less |
| Settings leagues empty | "No leagues yet. Start one or join with a code." | **text only** |
| Notifications | "Enable on this device" · "Round pings: ON" · "Chat pings: ON" · "Season email: ON" · unconfirmed line · "Moments, reveals, and month closes always come through." | pills |
| Push toasts | "Notifications on. The board will find you." · "Notifications blocked: allow them in Settings" · "Could not get a device token from Apple. Try again." · "Could not save this device." · "Notifications off on this device" | none (no Settings deep link) |
| Join code miss | "No league with that code — check with your Pro" | retype |
| Generic write failures | "Connection hiccup — check your signal and try again." · "Just updated — give it a second and try again." · "That didn't go through — please try again." · "Something went wrong — please try again." (2.6-s toasts, no retry) | none |
| Web-only | "Photo saved after the next server update — try again tomorrow" · "Push not wired up yet: key pending" · "Notifications need the installed app: add to home screen first" · founder desk "Nothing yet." | — |

Pattern count: of the ~53 phone empties only four pass a CTA through `CSEmptyState` (You no rounds, race, player receipt, album); ~25 use bare `CSFine`/`Text` with no door (EN-36).

### 7.2 Notifications — every kind (21: 12 push kinds incl. 3 nudge variants, 2 local, 1 realtime, 3 email, badge)

Sender: `supabase/functions/push/index.ts` (title ≤80, body ≤140; an authored `push_title` wins, else the first sentence). APNs adds `thread-id`, `badge` (actionable count), `category` for the three answerable kinds. Web push payload is always `{title, body, url:'/'}`.

| # | Kind | Trigger | Recipients | Exact copy | Lands | Lock-screen | Class |
|---|---|---|---|---|---|---|---|
| N1 | `round` | `posts` INSERT kind=round — one row **per league** the golfer is in | league members minus author; `notify_rounds`; mutes | "Jerecho posted 89 at UNM Championship" / "<League>" | receipt | — | noise-adjacent: per league, not per friend (a buddy sharing no league never hears it) |
| N2 | `chat` | posts kind=chat (4 ever) | `notify_chat`; mutes | first sentence / "<League> · rest" | Board | — | fine — ⚠ RE-ARGUE: "rare" rested on the chat row count, struck as behaviour |
| N3 | `announce` | 📣 by the Pro | all | first sentence / league | Board | — | meaningful |
| N4 | `moment` | posts kind=moment (85 ever): "Galen broke 80 for the first time" / "a 79. That one goes on the wall." | all | authored | Board | — | **the best kind** — anticipation/meaning |
| N5 | `system` | posts kind=system (54): "August is in the books. The ledger is posted." · "The clash this week: Galen v Jerecho." · "<Name> joined the league." · "Rosters locked. The season is live. Post a round." · "Minimum four to tee off — N in so far." | all unless `leagues.notify_system=false` (no client control exists) | first sentence / league | Board | — | mixed: month close meaningful; joins and tee-sheet declarations are feed, not push |
| N6 | `settlement` | a system post with `live_round_id` | all | authored short share string | scorecard | — | meaningful |
| N7 | `event` | event-board post | **all `event_players` including the author** | first sentence / event | event room | — | author-ping is a bug (EN-15) |
| N8 | `invite` (CS_INVITE) | `invite_golfer` — **0 rows ever** | invitee | "<League or event>" / "<First> put you on the tee sheet" | invites banner | Accept | wrong sentence for a league |
| N9 | `request` (CS_REQUEST) | `friend_request` (6 ever) | addressee; mutes | "<First> wants in your crew" / "Tap to accept" | Requests | Accept · Decline | meaningful |
| N10 | `rsvp` (CS_RSVP) | `declare_round` / `retag_round` per tagged (1 ever) | tagged | "<First> put you on the tee sheet" / "Sat Sep 5 · Encanto GC — in or out?" | round sheet | I'm in · Can't | **anticipation** — the brief's "Saturday" shape |
| N11 | `nudge` (live round) | `start_live_round` per seated member | seated | "<First> put you on the tee sheet" / "Live round at <course> — open the app to score it with them" | live round | — | meaningful |
| N12 | `nudge` (Ryder taunt) | `round_duel_nudge` on a `rounds` INSERT when the opponent is in a pending duel | the opponent | "<Event>" / "Galen posted — +2.3 to beat · 3 days left" (or "· closes tonight") | event room | — | **the one true anticipation push** — generalise it |
| N13 | `nudge` (founder report) | `content_reports` INSERT | founder | "A report needs you" / "Someone reported a comment. Open the founder's desk." | **Home** (no desk route) | — | ops |
| N14 | friend-accept | `friendships` pending→accepted | requester | "<First> is in your crew" / "You'll see their rounds now" | Requests (where the accepted request is not) | — | meaningful, wrong landing |
| N15 | friend-request **email** | `friendships` INSERT (Brevo) | addressee | "<First> wants in your crew" … "Manage notifications in your Tour Card." (wrong place) | cupseason.app | — | fine; footer wrong |
| N16 | local · duel reminder | scheduled by `EventRoomModel.load()` — only if you opened the room that day | me | "Your duel closes tonight" / "You haven't posted." | event room | — | anticipation, conditional on opening the app |
| N17 | local · action failed | a lock-screen action threw | me | "<title>" / "That one didn't take — open the app." | — | — | fine |
| N18 | realtime `live_open` | league channel broadcast | app open only | LiveNowBar "ON THE TEE · …" | live cover | — | in-app only |
| N19 | email · season recap | `seasons.status → complete` — **never fired** (0 completed seasons) | members with `email_prefs.recap` | subject "The Cup goes to <First> by 12 — <League>"; "SEASON COMPLETE / <Champion> / … / Your cut of the pot: $180 · Whoever collected it sends it on. / FINAL TABLE / [See the rounds behind it] / Cup Season keeps the ledger; the money moves between friends." | web root | — | **story** — the one artefact that reads as a season |
| N20 | email · league cancelled | `cancellation_notices` INSERT — never fired | members | "<League> is off — your $50 comes back" · "Your rounds stay on your card — all of them." | — | — | meaningful |
| N21 | email · auth OTP | Supabase Auth default template | signer-in | (not in repo) | — | — | transactional |
| — | badge | `actionable_count_of` = pending requests + open invites + open live rounds; seen clears | — | — | — | — | good discipline |

**Permission ask.** Never on launch; three moments — `card_saved` (before Home has ever rendered), `first_round`, `league_joined` — only when OS status is `.notDetermined` and "Not now" is ≥14 days old; copy "Hear it when it happens · A round lands on the board. A duel is closing. The table moves. · A buddy request, a tee time, an invite — answered from the lock screen. · Nothing else. No streaks, no noise, no badge you didn't earn." Prod: shown once, accepted 0, declined 0.

**What the brief wants that does not exist (no sender, no post kind, no trigger):**

| Brief's example | Closest thing today | Gap |
|---|---|---|
| "Jake just passed you" | Home hero move chip on open; Ryder-only taunt | no rank-change post kind; the vision's "League lead changed" has no producer |
| "You're 4 points from 2nd" | D130 stake line (in-app only, "Push: none", unbuilt on the client) | — |
| "Saturday's event is filling up" | nothing (invites 0 ever; RSVP push per tag only) | no seat-count / fill push |
| "Mike challenged you" | RSVP tag ("in or out?"); Ryder duel | no challenge object between two golfers |
| "Your season starts in 3 days" | hero "First tee in N days", in-app only | no scheduled push; "Rosters locked. The season is live." fires at lock, not at first tee |
| "you won the clash" | the opening is a system post; the result is a Home lead card only | the result is the story, the opening is the schedule |
| "your index just went live" | nothing | the league-less golfer's one milestone has no sentence |

**How a golfer with no league is ever notified:** only by another person acting on them — a buddy request, a buddy accepting, being tagged, being seated on a live round, or an invite (never sent). League posts fan by `league_members`, so a buddy's round never reaches a league-less golfer's lock screen although it appears in their Home feed (EN-02). Nothing is ever said about their own golf.

---

## 8. What already serves the brief (the keep list)

The redesign must not delete working value. This list is generous on purpose; every item is cited by the reader that verified it. Grouped by area.

### 8.1 First run and the door
- **The Forge** (`ForgeView.swift`): a 2.2-s once-per-device ceremony that rests on the live logo, honours Reduce Motion and hands focus to the email field at handoff. Premium, editorial, golf-first.
- **Code-only sign-in done right** (`DoorView.swift:116-159`): 8-digit field with `oneTimeCode` autofill, auto-verify on the eighth digit, 30-s resend, "Change email", the spam pointer after 20 s, human error copy, one path in. Every persona noticed the code lifting itself out of Mail.
- **The card gate's honesty**: no default marker, the email-derived name never pre-filled, Apple's one-shot name captured and consumed once, live handle availability, the claim thread line "Saving your card attaches the round you're claiming.", `set_handle` before `set_profile`. Its definitions ("Pick your ball marker · It's your face here until you add a photo — and your stamp on every round after."; GHIN "a reference on your card — we never resell or verify it") are the pattern for every other noun (TM §4).
- **The orientation's mechanics** (not its content): decided once on the way into `.ready`, written on decision so a crash never traps anyone, skipped for the invited (D116 §3) and for anyone with evidence, telemetry on show and exit.
- **The web crew step's copy** ("Who are you playing with? Cup Season is a game you play with people you know. Bring them now and your first round already counts for something." · "A buddy texted you one? This is where it goes.") and the web's validate-code-before-email door.
- **The web's rung ladder** (`index.html:11439-11475`): one next-unmet fact, never a chore list — "Three rounds and your index goes live. Nothing else needed." → "Find your buddies" → "Four makes a league. 2 more and your rounds start counting for something." This *is* the brief's funnel, missing only on the phone.
- **The league-less fine line** "Post a round — it counts on your card. Leagues score it when you join one." and **Join first** among the doors (D151 §4).
- **The guest claim path** (`GuestPencilScreen`, `LiveClaimAfterAuth`): the one first run that begins with a real round and a real friend; "Ed — 84 at Papago, Sat Aug 22. Enter your email to keep it." is the best first sentence in the product.
- **The invite-link plumbing**: AASA claims only `/?join=` and `/?claim=`; `growth link_opened` logged; the pending join consumed after the card with the covenant in the way.
- **The push ask's policy** (never on launch, after a moment, 14-day snooze, swipe = Not now) and its third line "Nothing else. No streaks, no noise, no badge you didn't earn."
- **The listing's money and price lines** ("What it costs, plainly. Nothing." · "Cup Season keeps the ledger; the money moves between friends") and the keyword discipline.

### 8.2 Home
- **The lead-card ladder** — one slot, fixed order, first match wins, no card as the resting state, every face a door that never dead-ends; 0–0 mid-week yields (D216); the opener shows once; pinned to its league; 30 tests (`HomeLead.swift:159-184`, `HomeLeadTests.swift`).
- **The hero names the leader by name and says the score at n=2** — "12 back of Galen · 9 – 21", "You lead Jade by 22 · 31 – 9", "Level with Galen · 14 – 14."; the Final is honest to a non-finalist; gold is earned only; pinned by the whole n × rank × structure × stake × skew matrix in `HomeHeroCopyTests`. Persona C: "the best first screen of any league app I've used."
- **One stage vocabulary** (`LeagueCopy.Stage`) and **one week producer** shared by hero, row and Clubhouse (`SeasonPhase.of`) — the prior audit's "week 4 of 14 vs 13" is closed.
- **D217 fold** (system lines fold to one line per league per bucket; the golf passes through) and **D219 doors** (a feed row is a door iff it knows its round; a booking already on the calendar card is drawn once).
- **The digest** ("Since you were here · 3 rounds, a personal best from Galen, and Galen 🔥'd your 83." and the quiet frame); the seen-mark read once per load.
- **Failed read ≠ empty feed** (D220) when rows are cached; one load per key with a generation guard.
- **Every Up Next chip is a door**, amber only at ≤3 days, "today" never "tonight".
- **"Coming up" never vanishes**; "WITH YOU" / "YOU'RE IN"; weather and headcount — persona F's "the group chat, compressed".
- **Buddy requests and invites answered in line** with toasts and a reload.
- **The live invitation face** ("Galen put you on the tee sheet · JUST TEED OFF · NOTHING SCORED YET · JOIN") and the bar that follows you across tabs.
- **The reaction vocabulary** — heater · the eagle · dialed · ice · snake · sandbagger; the bare 🔥 always present; long-press tray; optimistic flip with revert.
- **The photo card** (the photograph is the ground; milestones "🔥 Personal best", "⛳ Broke 80 — first time", "🎉 First round on the card" computed server-side over the whole record).
- **D121 rows** — quiet, learnable order, a real door, a headcount noun the room agrees with.
- **Accessibility work** — combined elements, rotor actions, hit-slop on eyebrow links, named glyphs.
- **Occasions dismiss per year** so the azaleas come back; **deploy-skew tolerance** (v1 payloads still render honest sentences; a missing column retries without it).

### 8.3 Clubhouse and the season
- **The story sentence over the table** ("Scorpions lead by 12 · Coyotes a good weekend back.") and **the Climb** — a you-centred window with the cut drawn across, "12 ahead of you — the top seed", "Galen, 4 behind you", IN/OUT badges, "··· 3 more ···" padding that grows with distance. Persona C's "oh, that's cool". The room's best idea; promote it.
- **The scenario line that never invents a clinch** and the climb note that refuses "EVERYONE ADVANCES" for a hollow field (`ScenarioLine.parts`, `ClimbMath.note`).
- **Every points figure opens the rounds behind it** (§16): squad receipt with ledger *reasons* ("Aug · Dave · 1 round short of the floor"), member history with BUMPED, finalist receipt with head start + window. "Everything shows its work."
- **The ceremony** — once per member, 400 ms after the data, server rows preferred, "PREVIEW" when not, "You're owed $270 — Cup champion", "Still owed to the pot" by name, the ledger line verbatim. The one screen that is a memory (personas B and C).
- **The rank-up haptic, once, for the room in hand** and the split-flap rank on a fresh load (reduced-motion aware).
- **The clash card mid-week** — best-so-far picked exactly as the settle picks, named bands in third person, each side a receipt door.
- **D70 at $0** (Pot tab and On-the-line vanish); **the code hidden in setup** (D161); **the roster door reads the same three facts the server gates on**.
- **No alerts** — every consequential act is a two-tap arm with its reason shown while armed (`RoomBits.swift:39-66`, `MembersSheet.swift:85-105`).
- **The cancel banner** tells the member their refund and that their rounds stay.
- **Board plumbing** — optimistic writes that revert with a toast, realtime on a dedicated client, the "SINCE YOU WERE HERE" digest on a quiet day, settlement rows that open the scorecard, `easeCaps`, the moment rows' voice ("✦ Priya set a personal best. New number to chase.").
- **The photo as ground** on a story card; **money in two numbers, never blended** (D106).
- **Voice where it exists**: "Joins have gone quiet — a nudge in the group chat usually does it." · "The cookout isn't going to bet itself." · "Bumped rounds still happened — a better round took their monthly slot." · "Whoever's hottest takes the cup." · "Deciding this before anyone tees off is what keeps October friendly."
- **Schedule anticipation pieces** — the weather chip, "◇ you lead 1–0 · one more round.", "I'm in" from a buddy's plan, "Get in on it".
- **`RunItBackCard`** for the returning golfer; **the individual race tile that names the thing you actually did** ("Dana · Iron Man · 14 rounds").

### 8.4 Post and play
- **The three-tense cover with LIVE leading** (one sentence, three doors, the live door breathes) and **the ⊕ as a verb that snaps back** — right pattern, wrong default for the 90% case.
- **Solo "Play now" in three taps**; a league-less golfer can score alone or with strangers and it posts to their record (D107 built).
- **The composer is a scorecard, not a form**: live gross hero with `numericText` transitions, the band sentence, points/vs chips, course memory, a tee pick fills rating/slope *and* real pars, a 9-hole tee flips the side.
- **The provisional hero is honest** ("No number yet — this round starts it"); **the draft survives an app kill** (24 h) with a human toast.
- **Degrade, never dead-end**: photo failure posts the round anyway; scan failures fall to typed entry with named toasts; course search never hides silently.
- **The ceremony**: dusk, 2.5-s stagger, ball-into-cup, `.success` haptic, gold only when points are real, the D122 note that says *why* a round did not score.
- **The epilogue names feelings, not stats** ("That one goes on the wall", "Iron man doesn't take weeks off") and speaks the rivalry.
- **The recap PNG obeys D2**: gross, third-person band, course/date/points, one badge, no index/differential/league.
- **The live round follows you** (LiveNowBar, the Home banner, the Live Activity that goes stale honestly at 45 min, Close that never ends the round).
- **The nearby handshake asks on the other phone** and gives up out loud after 20 s.
- **The scoreboard speaks the game's sentence** ("ALL SQUARE", "HOLE 7 WORTH 3 SKINS", "GALEN IS THE WOLF · COMEBACK"); side games above the finish block (D153).
- **Finish is neutral and stateful** ("ALL 18 IN · 4 CARDS READY" / "JADE'S CARD IS SHORT"); the sheet names the missing holes and offers "This one was casual — post nothing".
- **Two-tap scrap that disarms itself**; **landscape reads the card**; stroke pips only when the SI is real.
- **The recap's hole strip and highlights**; guest recap links per row; **the receipt opens instantly from cache and shows its work** (including D124's sentence and D209's playing number).
- **The strokes preview in plain sentences** ("**Jade** gets 3: holes 2, 7, 11"; "Galen gets 9 — the 9 hardest holes … Strokes off the low man (Galen)"); **"On the tee, good luck everybody"**; "Card read — 2 holes I couldn't make out are set to par"; "Your unposted round came back — it's waiting in Post a round".

### 8.5 You, people, settings
- **Every name is a door** — the Tour Card opens from 23 call sites as one sheet. Q4's plumbing exists.
- **The hero object** — photo owns the card, marker is the crest when there is none, gold index only once earned, trophy chips with in-place `+N more`, FORM with its key sentence. "The best object in the app"; "reads as a magazine cover".
- **Buddy requests reach you where you are**; mutual intent auto-accepts ("Golf buddies ✓" instantly).
- **Search is right**: one letter, buddies → league mates → handle → name, 350-ms debounce.
- **Loading honesty**: placeholder bars, one Retry line, a failed block says "Did not load" rather than "not yet".
- **The trophy engraving** — a new tile takes its name behind a gold needle once.
- **The rivalry naming voice** and its misuse valve (either side renames or clears).
- **The Welcome sheet** — three rules, "How scoring works →", "any member's link works" + share: the funnel the brief describes, already written.
- **The invite link names its league** and works for anyone; **handle safety** (D159); **delete-account copy** tells the truth; **pricing never interrupts value** (D183).
- **Deleted rounds keep standings whole** ("Former member"); You's delete is a two-tap arm in a line.
- **`Last round with`** is threshold-only, in-app only, never streak grammar (D63).
- **The developer/founder tooling is out of the golfer's way** (even though it swallowed the feedback door).

### 8.6 Create and join
- **"Use these defaults →"** — one tap from step 1 to review (the escape hatch exists; it sits under the rulebook).
- **A row is minted only after a name** (no "My Cup husks", D5).
- **The lock is one server transaction, idempotent, and the server decides the phase**; a retap after an ambiguous failure returns the truth; nothing droppable can lock on defaults (D111/D206). The prior audit's one P0 is closed in code.
- **The wizard's defaults are the row's defaults** (re-entry shows what the founder chose); **the lock ends on the share moment**; **"First tee <date>" is said instead of "Season is live" until the date comes**.
- **Solo tees off at two and every minimum derives from one table** (D205); **guidance never blocks** (a structure that doesn't fit is dimmed and toasted, never disabled).
- **The covenant names the stake BEFORE `join_league` and fails closed on the phone**; "Join — I'm in for $50" / "Not now" are honest; the ledger line is one constant.
- **Server refusals reach the golfer verbatim, with the league's name**; **the pending code is removed before the attempt so a failure can't loop**; **the invited skip the orientation**.
- **The tee sheet is league-less by design** (D107); **"Nearby · ASK" is consent-shaped** (D158); accepted rounds land you in them (D163).
- **`LiveGame.note` is plain golf** ("Low net takes the hole's skin; ties carry the pot.").
- **The Ryder sheet needs one field**; run-it-back prefills the benches; **the declare sheet needs zero fields** and has the "Get in on it / I'm in" twin.
- **The Occasion cards** are the right grammar for a door (an oblique golf moment, one verb, dismiss per year).
- **The blind draw's copy** ("Argument-proof." · "The hat has spoken"); **any member's link works**; **D119's member sentences name the Pro** rather than handing members the lock button.
- **The Ryder duel engine** — the challenge primitive the brief wants already exists; it is wearing the wrong clothes.
- **The web invite sheet** (URL as text · Copy link · Copy a message · Share… · the code) and `inviteMessage` in the product's voice — reuse for "invite from intent".

### 8.7 Data, canon and gates
- `native_home()` as one typed round trip (leader/runner-up names in the board's voice, `gap_to_next`, `prev_rank`, the books as parts, the Final's locked seed); `home_feed`'s circle already buddies ∪ league-mates ∪ event co-players with milestone flags; `my_schedule` already friend-aware; `declare_round`'s consent + push; `my_rivalries` + `rivalry_weeks` + `rivalry_names`; `tour_card.shared_courses`; achievements with `round_id` receipts re-derived on delete; `season_payouts` as fact; `season_scenarios`' honesty rule and `cup_final_race`; the weekly clash engine (pairing cascade with rotation, quiet when idle, band-decided, receipted); `home_clash` as the model for "engine fact → granted, caller-scoped read"; league-less live rounds; forfeits with no money column; the push contract; `growth_events` fail-closed; the handicap engine (never a blind 18); `v_rounds_ranked` as the single scoring lens; D37 grant discipline made structural (`contract.psv` → generated `Rpc.swift`); round posts already in the Gentleman's voice.
- Canon that agrees with the brief: "the home is the feed — full stop"; the blueprint's four questions (What happened? · Where do I stand? · I'm playing · How am I doing?); D27 curate-never-fabricate and D216 never-manufacture-stakes; D107/D110 play-before-league; D151's crew question; D176/D218/D217/D219 (one card, every door says where it goes, one fact one place); D126 the endgame as a sentence you can always see; D52's clash as the week's appointment; D166's six moments in the canon's voice; D34/IOS-020/D124/D178 the 60-second post; D8 dials only inside Custom; D113/D46/D70/D106/D129 money honesty; D23/D104/D179 notifications; D82's "depth stays AT the doors"; D93's one authoritative surface per question; D177's "two on a page is a spine"; the identity contract (dark ground, two metals, one heat axis, three type voices, the spine, the roll, the ceremonies, markers); the gates (preflight 19/20/12/15, db-checks 2/10/19/21/23).
- Visual: the photo-owned credential; serif hero figures and sentences; the spine + wash card grammar; band words; the live play screen; the clash lead card; the coming-up card; `CSEmptyState`; Dynamic Type floors; the native tab bar; the door's mark, hairline and tagline; mono eyebrows when there are two, not eight (SV §5).

---

## 9. Data the backend already has that no screen surfaces — and the gaps

From the data-layer reader (DL). Prod counts are in Appendix A.

### 9.1 Already computable, not surfaced (or surfaced on one client only)

| Fact | Where it lives (SAW) | Where it should show | Status |
|---|---|---|---|
| Events and open duels (opponent, `closes_on`, my/their number to beat) | `native_home.events`, `open_duels` (`native_home.sql:398-456`) | Home | decoded on the phone, never rendered (HM-03) |
| The runner-up by name; `gap_to_next` for everyone | `standing.runner_up_name/points`, `gap_to_next` (`20260902200000:265-303`) | the hero ("4 back of Dre") | only the leader is named on the hero; the row above rank ≥3 has no name (DL-07) |
| `prev_rank` from the last Sunday snapshot | `native_home.standing.prev_rank` | the move chip | shown as "— held" with no "since Sunday" |
| The Pro's payment note and due date | `league_settings.buy_in_note/due_on`, `native_home.buy_in.note/due_on` (D129) | Pot pane | Home owe line only on the phone; the pane omits the columns (CH-03) |
| `structure` and `phase` on the covenant | `join_covenant_info` returns them (`20260830300000:242-253`) | the join sheet | `Covenant.init` drops both (CJ-04) |
| `courses` and `shared_courses` on a Tour Card | `tour_card` emits both (`20260902180000:171-208`) | Jake's card ("you've both played Papago") | phone discards; web renders "You've both played" (YP-03) |
| A christened rivalry's name | `my_rivalries.rivalry_name` | the VS chip | dropped on the Tour Card path (YP-05) |
| Every friend's `index_current` | `my_friends` (`20260715210000:85`) | a friends board by handicap | one client sort away (DL A) |
| `home_feed` milestone flags (`is_pr`, `is_first`, `is_sub80`) | per row, window functions over the golfer's history | the feed | phone prints them; the trophy case disagrees on which milestones exist (DL-24) |
| "3 friends playing this weekend" | `my_schedule.is_friend`, `play_on`; rides `native_home.upcoming_rounds` | Home | computable; 1 future declared round in prod (DL-10) |
| "You've beaten Mike 3 of the last 5" (league-mate) | `rivalry_weeks` newest-first | the Tour Card / rivalry | exists; three separate implementations (DL-09) |
| Predictions inside a league | `season_scenarios` (clinched / eliminated / `needs`), `cup_final_race` | the Climb ("one Torched-it round passes Dre") | shown as engine captions; never as a sentence about me (persona C did the arithmetic himself) |
| Season countdowns | `season.starts_on/ends_on/status`; Final = `ends_on − 27` | the hero | client-derived twice (phone `Models.swift:270-281`, web `:11263`) (DL-11) |
| Solo-league champion | `seasons.champion_member_id` | the wrapped hero | phone checks only `champion_squad_id` (HM-06) |
| The last week's clash result | `week_clashes` settled row; a system post | Home | a folded footnote (HM-34) |
| `set_league_notify_system` | RPC granted and used by the model | League pane | no control string in either client (EN-31) |
| `unfriend` | RPC granted | Tour Card | zero references (YP-25) |
| Last season's result for a member | `standings_snapshots` last week + `seasons.champion_*` | Home between seasons | absent from `native_home` (DL-31) |

### 9.2 What does NOT exist in the schema (the brief's between-friends layer)

| Wanted | Verdict | Evidence |
|---|---|---|
| A friend-to-friend competition object ("Jake challenged you") | **No table, no push kind, no post home** | `friendships` is a visibility relation; the only pair-wise competitive rows are `week_clashes` (engine-picked, league-only), `event_duels` (Ryder), `forfeits` (crew-only); `posts_home_check` forbids a post not homed in a league or an event (DL-01) |
| "You're #4 among your friends" | no server read; by index client-side only | no function joins `friendships` to `rounds` (DL-02); ranking friends at all is unruled (CC-10) |
| A friend's milestones for a golfer who shares no league | never reach them | `home_feed` is rounds-only; moments are written to league boards; the phone reads posts for my leagues only (DL-03) |
| Head-to-head outside a shared league season | does not exist | live-round results (`game_result` JSON), same-day rounds, `week_clashes.winner_member` are never counted; three copies of the shared-season rule (DL-09) |
| Streaks ("3 straight under 85"; current streak) | self-only, client-side; forward-only once-ever weekly badges | `achievements` is `unique (profile_id, kind)` (DL-08) |
| Movement since my last round | not computable | `prev_rank` is the Sunday snapshot; `round_epilogue` has no before/after rank (DL-06) |
| One week number | three server formulas, three client formulas; `native_home` carries none | DL-05 / WB-07 |
| A story home for a golfer without a league | none | `round_moments` inserts posts only via `league_members`; `finish_live_round` skips the board when `league_id` is null (DL-18) |
| "Who I play with" | seats only | `recent_partners` and `last_round_with` read live-round seats; a typed round has no `played_with` (DL-17, PP-05) |
| A lightweight outing ("we're playing this weekend" with identity) | `create_event` needs 7 args; a tee-sheet row is one golfer's plan with tags | DL-29 |
| Side-game records | JSON on the round; nothing writes `game_results` (0 rows) | DL-19 |
| Notifications to a friend | recipients are league members; no kind for a friend's round, a clash opening, a rank change | DL-12, EN-02 |
| App-open / view events for activation, WAU/MAU, D7/D30, empty-state engagement | none | DL-30 |
| Onboarding fields ("who you play with", "what golf you play") | `set_profile` has neither; four dormant personality columns exist on `profiles` | DL-21/22, CC-29 |

### 9.3 What the redesign can lean on, and what it must ask for

**A · Computable today, no schema change**: friend activity feed (rounds only); "beaten Mike 3 of 5" for a league-mate; friends by handicap (client sort); own streaks (client pass over own rounds); friends playing this weekend; league predictions under D24's honesty rule; season countdown; closest competitor for ranks 1–2; "win this week and you move to 2nd" (client-side, inside a league, with the row above me by name); career records; who's winning; the pot; what's next in my event.

**B · Needs a new RPC over existing tables** (a migration + contract refresh + `Rpc.swift` regeneration): `friends_board()`; `head_to_head(p_opponent)` with named facets (replaces three copies); `home_stories(p_days, p_league)` — one typed, ranked, deduplicated stream (round · milestone · plan · clash_open · clash_verdict · lead_change · trophy · invite) ending the two client merge algorithms; `my_streaks()`; `round_epilogue` extended with `rank_before/after`, `passed[]`; `native_home` v3 keys (`week_no`, `weeks_total`, `week_ends_on`, `days_to_first_tee`, `days_left`, `final_opens_on`, `next_up{name, points}`, `last_round_on`, `last_season{…}`, `clash` inlined); `my_side_games()`; `season_story(p_season)`; `match_contacts(p_hashes)` (strictly C — needs a `contact_hash` column); `band_name(p_pvi)` beside `cup_points`; D123's server half (`home_feed(p_days, p_league)`).

**C · Needs new tables or mechanics — and therefore a decision-log entry**: a `challenges` table (the friend-to-friend object, built on the Ryder duel at n=2 / the clash settle; with `push_nudges` kind `challenge` and a CS_CHALLENGE category; forfeits gain `challenge_id`); what a casual "meeting" is (same course + day? tagged together? — a `played_with` capture is the honest answer and the same one DL-17 needs); an `outing` (or `scheduled_rounds` promoted with a name); a story home for a golfer without a league (relax `posts_home_check` to `profile_id`, or synthesise from `achievements`); repeatable streaks; onboarding fields; a crew without a league (is a `setup`-phase $0 league that container, or a lighter `crews` table?); one week producer; ranking friends at all. Every new table is born wide open — `pg_default_acl` still grants everything (D221; CC-52) — so each migration seals its own grants and adds a db-check line.

### 9.4 One-fact-many-places hazards (named, so the redesign does not add to them)

| Fact | Places |
|---|---|
| The week number | `snapshot_week` (0-based, day-7 start) · `open_week_clash`/`home_clash`/`settle` (1-based) · `sandbox_week` · web `weekCloseDate` · web hero · web weeks-left · phone `LeagueDates.currentWeek` (with `totalWeeks = ceil(days/7)` vs server `ceil((days+1)/7)`) — the moments migration refuses to print a week number because of this (`20260831130000:20-21,37-38`) |
| PvI | `v_rounds_ranked` (allowance) · `home_feed` (100%) · `tour_card.avg_vs_index` (100%) · `tour_card.recent.beat` (100%) — one round, two numbers on one Home (DL-04, PA-012) |
| The band names | seven copies (server ×5, phone, web); the −1.0 edge already drifted once |
| The head-to-head W-L-T | `my_rivalries` · `rivalry_weeks` · `tour_card.vs_you` |
| The headcount | `roster` (living) vs `members` vs `buy_in.players` — deliberately three, documented |
| `seasons_done` | `career_record` (paid seasons) vs You's "Every season" |
| The clash window | server and `ClashMath.window` — the same expression, copied |
| Days-to / days-left | phone, web, and only two server payloads |

---

## 10. The prior audit delta (2026-08-29 → tip)

The blind audit of 2026-08-29 found 135 issues, seven personas, TOP-1..5 and seven zero-instruction reasons; its remediation was ruled as D111–D139. The prior-audit reader re-verified all 51 P0/P1 issues in code at tip on both clients plus four read-only prod queries: **16 FIXED-BUILT (some with residuals), 19 PARTIAL (ruled, half-built — usually web-only or phone-only), 8 RULED-NOT-BUILT, 7 OPEN (no ruling), 1 SUPERSEDED (harness artifact)**. Full status table with file:line for every row in PA §3.1.

### 10.1 TOP-1..5

| Headline | Status at tip | What is left |
|---|---|---|
| **TOP-1 · The organizer cannot finish** | FIXED-BUILT: `lock_league` atomic (`index.html:17316`; `WizardService.swift:117`); the web invite sheet; buy-in defaults to $0 (prod-verified) | the buy-in row is still behind Customize on both clients (D113 ruled it above "Use these defaults →", unbuilt); contact invites declined (D136 Q-07); the phone invite sheet is ShareLink-only; **zero `lock_attempt/ok/fail` rows in prod since the fix** — activation unproven |
| **TOP-2 · Nobody can tell what they are joining** | RULED-NOT-BUILT on both clients — the least-moved headline | the covenant sheet, invite door and cold door are byte-for-byte the audit's; `join_covenant_info` not extended (no Pro, roster, dates, bands, split, pay path); a $0 league gets no sheet; "Not now" loses the invite on the phone and keeps it invisibly on the web; D115/D116/D117 owed. Only "consent on every path" (web, six `covenantGate` sites) and "code survives Not now" (web) are built |
| **TOP-3 · Members handed the Pro's controls** | FIXED-BUILT on both (`switchView` gate; role × stage hero; doors collapse for members) | six retired stage strings still print on both ("The Pro has the list.", "SQUADS LOCKED", "LIVE NOW — CAPTAINS READY", "Complete · rosters locked", "OPENS AFTER SETTINGS LOCK", "SETUP · LOCK THE BYLAWS TO OPEN INVITES"); "the Pro" undefined at first contact on the phone |
| **TOP-4 · The first round contradicts itself** | FIXED-BUILT at the core (one `seasonNote` producer; preview at the league's allowance; half-open bands; the no-number line; the Playing number row) | `home_feed` still computes pvi at 100% (D123's server half unbuilt); `sgn()` survives on five web surfaces; phone placeholders "72.1"/"128" read as values; no correction path on the receipt (OPEN); "COUNTS ON YOUR CARD" remains the fallback verdict |
| **TOP-5 · How do I win / pay** | PARTIAL | the endgame sentence exists on both but has one home on the web (climb note) and the Season tile sort hides the Cup Final line on both; rules remain a collapsed disclosure on both (D128 unbuilt); the scoring help lacks ENDGAME / TIES / THE SQUAD; the phone Pot pane renders no payment terms; the D130 stake line unbuilt; "scored fresh" undefined by any tap |

### 10.2 The seven zero-instruction reasons

| Reason | Status | Note |
|---|---|---|
| ZI-1 setup cannot complete | FIXED-BUILT | unproven in prod |
| ZI-2 friends cannot be invited from the app | PARTIAL | link + message yes; contact invite declined; phone has no Copy message |
| ZI-3 a friend cannot tell what they are joining | **OPEN in effect** (ruled, unbuilt) | D115/D116/D117 |
| ZI-4 Home hands members the lock button | FIXED-BUILT | — |
| ZI-5 the first round promises points, delivers 0 | FIXED-BUILT | residuals above |
| ZI-6 nobody can answer "how do we win" | PARTIAL | sentence exists; placement + rules place + help sections missing |
| ZI-7 money nobody knows how to settle | PARTIAL | web Pot terms built; phone pane not; covenant line not |

### 10.3 Still-open P0/P1 inheritance, ranked by damage to the five questions (PA §3.2)

1. M-023 / M-026 / M-058 — the joiner decides blind (P0, both). 2. M-025 — a declined invite is a loss on the phone, invisible on the web. 3. M-143 — the door is a slogan (D117 PROPOSED, never decided). 4. M-054 / M-055 / M-056 / M-059 — the win condition has too few homes; rules are still admin. 5. M-110 — pot terms on the web only; nobody has set any. 6. M-041 — six retired stage words still print. 7. M-047 / M-045 — a round can show two numbers; five web surfaces print signed bare numbers. 8. M-004 placement — buy-in behind Customize. 9. M-019 — strangers get a plain Add in the picker; D118 (exact @handle only) unbuilt. 10. M-072 (web) — one league on Home. 11. M-123 — no "this round matters because". 12. M-093 recourse — "that wasn't me" / "Entered by" unbuilt. 13. M-080 — fix a wrong score from the receipt (OPEN). 14. M-076 (phone) — placeholders as values. 15. M-010 / M-011 / M-008 / M-009 / M-006 — wizard copy, mostly OPEN. 16. M-051 — starter vs GHIN precedence. 17. M-002 — contact invites (declined; reopen under the brief's friend-connection metric). 18. M-129 chrome / M-120 board dates / M-018 banner — unverified or open polish.

Seven of the audit's P1s were never ruled (M-008, M-010, M-011, M-051, M-080, M-120, M-018) — the redesign should own them explicitly rather than inherit them silently (PA-033).

### 10.4 What the phone gained and lost relative to the web since the audit

Gained: multi-league rows (D121), the hero foot with the endgame (D126), the owe line (D129), the leader by name with the score (D130), the lead card and clash beats (D176/D216), the fold (D217), the doors (D218/D219), the paged Clubhouse (D203), the live scorer's title and Close (D173). Lost or behind: money (no pot terms on the pane), placeholders, decline persistence, the invite sheet, the Q-22 rating guard, the crew step.

### 10.5 What the personas actually learn (PA §3.4, 8/8)

Users reconstruct the database: league → Pro → bylaws → squads → season window → month caps/floors → Cup Final → pot split. They never form ME → NOW → COMPETE. Two things they never resolve: what "the cup" is, and whether *this* round counted. Two things they resolve only by asking the organiser: how to win, and how to pay. Five of eight reached for "fantasy league". Six of eight explanations end with the organiser as the tutorial. This session's six personas reproduced the same pattern (§5.7).

### 10.6 Rulings the new brief supersedes (do not build these as written; PA §3.6, CC §3B)

- **D83/D117** (the door sells with its own splash + one sentence): the brief wants understanding in seconds; a slogan plus one line is the floor, not the design.
- **D81/D94/D121** (one hero, one lane, a compact row per other league): the brief's Home is a living feed across everything I am in; keep the honesty rules (D23 self-only money, D27 no empty hero), drop the single-league hero as an axiom.
- **D119** (role × stage hero matrix): correct as a fix; hard-codes the database's stages as the user's reality. The brief wants NOW, not PHASE.
- **D115** (the covenant as the decision sheet): the brief wants the *invite* to sell and the join to be one tap; roster and dates belong on the link preview and the pre-OTP door.
- **D128** (rules as a place inside the League pane): the endgame and floor sentences are the season's cover copy, not a pane.
- **D136 Q-07** (contact invites not scheduled): conflicts with the friend-connection metric and "I want to beat Jake".
- **D151 / D119(4)** (Join a league leads; Start a league; Start something else…): play before league — the smallest action is "Add my round", and creation starts from intent.
- **D132** ("the Pro" stays): compatible, but the definition must be a by-product of seeing a person's name on the invite, not a glossary entry.

---

## 11. Immutable laws and overridable rulings (for the design phase to inherit)

Condensed from the canon reader (CC §3A–3D). The hierarchy of truth is vision → principles → IA → mechanics → UI → implementation (`spec/decision-log.md:8-21`); "Changes at level N require only level-N authority unless they leak upward." The redesign's nav is a **level-3 change** and must be logged as one, with a named CONFLICT line against the IA blueprint, D82, D93, D94, IOS-011 and IOS-002 §2, before anything is built (CC-01, P0 process gate).

### 11.1 The wall — 45 immutable laws (one line each; sources in CC §3A)

| # | Law |
|---|---|
| L-01 | Every number shows its work — no points figure without a tap-through to the rounds/ledger (spec §16; CLAUDE.md rule 4). |
| L-02 | Rounds are immutable; deletion is `delete_round()` only; adjustments live in a ledger with reasons. |
| L-03 | Writes with game consequences are SECURITY DEFINER RPCs; nothing authoritative is computed on a client. |
| L-04 | Grants are explicit: every client-called function `grant execute … to authenticated` + `revoke … from public, anon`; anon holds ZERO relation privileges and executes EXACTLY twelve endpoints; a new profiles column needs `grant select (col)`. |
| L-05 | Migrations are timestamp-named and never edited after they run; a fix is a NEW migration; self-checks never mutate a real row. |
| L-06 | No 6-digit OTP; code-only email; no passwords; Apple the flagged second door; no other third-party login. |
| L-07 | Calendar dates are `YYYY-MM-DD` strings parsed only by `localDate()` / `CSDate.local`. |
| L-08 | Onboarding gates on `marker` AND `handle`, never "row exists". |
| L-09 | The ledger line verbatim from one constant per client: "Cup Season keeps the ledger; the money moves between friends." Never "never held", never "takes no cut", never "between you". |
| L-10 | The pot is a ledger with two numbers, never blended; a $0 league shows NO pot surfaces; unpaid state is self-only on Home; the Pro's note is instructions, never a rail. |
| L-11 | Buy-in defaults to $0; money is a choice, not a default. |
| L-12 | Membership opens at lock; the code works lock → first tee (floor: a week); the Pro's door closes at the halfway turn; a decline always works; a member never sees the Pro's configuration tool; every join passes the covenant (preflight 19). |
| L-13 | A round scores for a league only inside its season window, at the league's allowance; outside it, it builds your number. One PvI per round (the league lens). |
| L-14 | One lens on You — the playing number; "differential" and "PvI" never on a user surface; a bare float is always labelled. |
| L-15 | Two numbers on a round card — gross and points — joined by one band phrase; bands Torched it / Beat your number / Played to it / A little loose / Posted anyway, half-open at −1.0. |
| L-16 | Dials live only inside Custom; presets never mention them; build a dial's UI when two leagues ask. |
| L-17 | The endgame is a sentence you can always see; the Cup Final is the final four weeks scored fresh; seeds lock at `ends_on − 27`; a non-finalist is told the truth; no last-place mechanic. |
| L-18 | Season shape: N whole weeks from any first-tee weekday; caps/floors are calendar-month machinery; floors waived in partial edge months; the auto-bye forgives the first miss; solo floors track a habit and never assess. |
| L-19 | Verification tiers and vouching are per golfer; a round posted to you by another phone is attested only if your device was in the session. |
| L-20 | Notifications: only meaningful ones; a nudge names one of eight emotions or does not render; once per condition; no shame, no badge counts; the badge counts only actionable items and means UNSEEN; the permission ask is contextual, never on launch. |
| L-21 | Home never opens on nothing — curate, never fabricate; natural cadence is 2–4×/week, not daily. |
| L-22 | Memory-layer guardrails: no infinite scroll; no vanity metrics; no engagement-bait notifications; no addictive mechanics (streak-shame beyond a single dignified reminder, FOMO, dark patterns); no generic social features. |
| L-23 | Real golf, no simulations: the demo is retired from every user path; empty states are never filled with fabricated content; faces are never fabricated. |
| L-24 | Identity: the marker is the floor (no silhouette state); a photo owns the card, the marker is the crest; 14 named markers; first names leave the app. |
| L-25 | Two metals, never swapped: ember = LIVE (primary action, the ⊕); champagne gold = EARNED only. Gold on a button/tab/nav is a defect. |
| L-26 | One heat axis (warm → hot → fire; cool slate for falling), semantic never decorative; `pos`/`neg` semantic only; never red-means-bad; squad quartet is identity. |
| L-27 | Dark is the default; light one tap away; auto third; the ground is Fescue green-black (`bg0 #0B1410`). |
| L-28 | A look may tint spines, washes, eyebrows, the ⊕ halo — never ground, ink, `pos`/`neg`, the heat ramp, the squads, gold's meaning, ceremonies or share cards. |
| L-29 | Three type voices: serif = the story (never on controls); mono = the record (never prose); sans = the workhorse. No fourth family. Nothing below 11 pt at default; every layout tolerates AX sizes. |
| L-30 | One easing everywhere — the roll; nothing bounces; reduced motion rests on the frame; the Forge plays once per device. |
| L-31 | The ceremonies are product, not polish; the season ENDS with a takeover once per member and the pot resolves to PEOPLE; the Trophy Room is screenshot-shaped. |
| L-32 | Every empty state ends in a next move; loading is a redacted shape, never a spinner in content; a failed read is never an empty one; two-tap "Sure?" never `alert()`; server sentences pass through verbatim when written for humans. |
| L-33 | The voice is the Gentleman Instigator: scene → stakes → observation; never wink, never explain the joke; no emoji in prose, no exclamation, no sportsbook/frat/country-club register; function first on controls; natural case at the generator; copy says what happens to you. |
| L-34 | One fact, one place. |
| L-35 | Numbers are spoken as story first, table second; Memory > Statistics. |
| L-36 | The public/anon surface is a curated, tokened, fail-closed SECURITY DEFINER window — never an anon table grant. |
| L-37 | Strangers: exact @handle or a buddy in the invite picker; the Tour Card gate is the one privacy rule; no location index of users without its own decision. |
| L-38 | Report, block (mute), hide/unhide, suspend, delete account exist on every surface where content is (App Store 1.2) and survive any redesign. |
| L-39 | No purchase UI in any app; no pricing on the front door; FREE until 1,000 onboarded golfers; the pass noun is "league pass"; founding leagues free forever; never resell the index. |
| L-40 | The free door is the tee sheet: any signed-in golfer starts a live game with anyone; guests need no account; side games never touch season points; live leads the ⊕ in ember. |
| L-41 | Formation integrity: no league in season with empty squads; the lock is one server transaction, idempotent; blind draw/assign are the free structures. |
| L-42 | One headline per round (mark > barrier > PB > streak); the poster hears it first; comments and reactions exist only in service of the round's story; reactions are the six-emoji crew vocabulary. |
| L-43 | Stage vocabulary is six words from one producer per client, gated by preflight 20; solo leagues never say "squad". |
| L-44 | Every number that counts must count something; a refresh that fails keeps what is on screen; a hero never claims a table rank as a seed; a stale Live Activity goes stale at 45 min. |
| L-45 | The twelve anon endpoints are the whole signed-out surface. |

Five P0 engineering gates the design phase must honour by name: the nav is a level-3 entry (CC-01); "we want money on it" must land on D113's buy-in row with the ledger line, defaults $0, never odds/action/units vocabulary — or it reads as a betting app to App Review (CC-26); any new join door pairs with `covenantGate` (CC-50); report/mute/hide/suspend/delete stay reachable wherever a person or post is shown (CC-51); any new table seals its own grants (CC-52).

### 11.2 The doors — 15 rulings the brief explicitly overrides (each needs a CONFLICT line; CC §3B)

| # | Ruling (level) | What the brief says instead | The superseding entry must contain |
|---|---|---|---|
| O-01 | The four places; "Tab order and names do not change." (preamble; D82; D93 "NAV UNCHANGED"; D94; IOS-011; IOS-002 §2) — level 3 | ~4–5 destinations mirroring the user's mental model; ME → NOW → COMPETE → COMMUNITY → HISTORY | the new destinations mapped to the brief's five questions AND to the blueprint's four (What happened? · Where do I stand? · I'm playing · How am I doing?); every deep link, push route, widget and `openLeague` retargeted; the Guide, `#obOrient`, `OrientationCopy`, `GuideCopy` re-taught; D93's rejection of the quadrant Home addressed explicitly |
| O-02 | The league room is where the product lives; Clubhouse root = Standings; six segments; paged (IOS-002 §5; D203; D93) | the competition is a story inside ME/NOW/COMPETE; the room is a chapter, not a destination | where standings, board, pot, schedule, bylaws each live; D93's "one place per thing" upheld, its container not |
| O-03 | The orientation screen (D82; D117 PROPOSED; D116) | no explainer slides; ask handicap / who you play with / what golf you play | the three questions as the onboarding; the guide kept under ⚙; "what golf you play" has no data home (a migration + column grant, or device-local) |
| O-04 | The Start/Start/Join doors lead Home (D94; D119(4); D136; D151(4); IOS-012) | creation from intent with progressive disclosure | intent doors resolving to existing objects (league / event / declared round / callout / stake); D40/D112/D113 untouched; money lands on D113 + `CS_LEDGER` |
| O-05 | "The Pro" as the hero's addressee / role × stage matrix (D119; D96) | ME first; no commissioner mechanics required for understanding | ME leads for everyone; the Pro's pending action becomes a NOW item; the D40 guarantee (a member never sees the wizard) moves to the new choke point; "the Pro" the NOUN stays (D132) |
| O-06 | "Clubhouse" as a tab (preamble; D11 retired the word from copy; the blueprint's slot was "Compete") | COMPETE / COMMUNITY | ride on O-01; note the restoration |
| O-07 | The ⊕ opens the three-tense cover (D110 + addendum; IA P4; IOS-011 contradicts) | Add My Round must be trivial | one-tap Add My Round with Play/Plan reachable; resolve IOS-011 vs the addendum; D110's ember-live rule (L-25) and D107's free door keep a first-screen sighting |
| O-08 | D93/D94's measured Home layouts; "the home IS the feed" | agrees: a living feed, no dashboard | say which of D94's layouts it is NOT (never layout A); keep the feed whole; may reorder the lane; D27 and D217 stay |
| O-09 | The D121 compact rows (a switcher of the single-league lens) | every membership's movement is a NOW item; no switcher | restate D123's lens rule for a Home with no open league (CC-13 — removing the open league changes which allowance lens Home scores by, not only navigation); `preferredLeague` / `openLeague` retarget |
| O-10 | Y-16 `openLeague` lands on the room's STANDINGS (D218) | doors say where they go (kept); where they go changes | one entry line: every `.league(id)` / `.pot(id)` lands on the new COMPETE object; "a door named for a table opens a table" survives |
| O-11 | The lead-card ladder is fixed and never reorders (D176; D216) | NOW = the living feed | keep D176's two rules (one card, fixed order) as principles or argue why a ranked NOW list is learnable; D23/D216 stay |
| O-12 | You grouped by scope with two heads; buddies door under the hero (D177) | ME and HISTORY as separate destinations | keep D177's naming fixes and D209's one lens |
| O-13 | The Clubhouse pages between leagues (D203) | no league room | falls with O-02; the pattern may be reused |
| O-14 | The crew step (D151, web only) | the brief KEEPS this question | not overridden — restated as one of the three onboarding questions and built on the phone |
| O-15 | IOS-018 / D100: parity first; the web rethought later | this brief is the later decision | one entry that opens the web-rethink question, names the reference client (the phone + Kit producers), states the parity rule going forward (shared producers, not shared screens), and corrects `CLAUDE.md:301-303` |

The web-client reader's evidence-based recommendation on O-15 (WB §6): make the web **secondary now** — the desk (wizard dials, Pro assign, draft grid, receipts, public season page, founder desk), the door for the account-less (guest pencil, `?join=`/`?claim=`, the covenant), and an interim operating surface held at *contract parity* (same RPC payloads, same shared copy tables), not IA parity; fix its four false-fact findings (WB-02 toast, WB-03 next round, WB-05 credits, WB-06 solo archive) as the price of keeping it up; freeze its operating surfaces at a point the owner names. Cost of a phone redesign to the web under "reference" = build everything twice in a 20.5k-line file (the D215–D220 wave shows the real outcome: eight phone builds, zero web); under "secondary" = shared producers plus the wizard; under "frozen now" = a live surface left asserting false facts. **The owner's revised R-C supersedes this recommendation** (2026-09-05): the web is built inline, in its own desktop-first shape, and every wave has a web half — the cohort comparison the "secondary now" case rested on is void as evidence (EVIDENCE_POLICY.md).

### 11.3 Terms of art already ruled (use these words; do not invent peers; CC §3D)

card = the golfer card only; the scorecard; recap / settlement / Tour Card as named artifacts (D131) · stake = money on a live game only; pride bets = forfeits; the books = money (D131, D64) · tee sheet = the shared calendar; the live scorer = a live round (D131) · cup = the season title; "Cup points" → points; "Cup champs" → the winning squad; Cup Final keeps its name (D131, D126) · "the Pro" STAYS and is defined at first contact; DB keeps `commissioner`, UI never says it; "Pro Shop" and "the pilot" retired (D132, D183) · the six stage words (D120, D136) · the playing number; never "differential"/"PvI"; "your number" in band copy (D209/D210, D1) · buddies = the mutual tie; crew = the people in prose; league = the competition container; "friend", "your profile", "clubhouse" retired from copy (D80, D11, D47) · Match · Rivalry (christened) · the Ryder · a Major; "duel", "event", "session", "window" are schema words (D12, D19, D46, D62) · vouch, never "attest"; "Entered by Priya · live round"; "UNCONFIRMED" (D13, D125) · IN (never SEEDED/LOCKED); CUP badge; "2 weeks left" never "final week"; "today" never "tonight" (D126, D136–D138, D176) · the pot · collected · still owe · buy-in ("None · bragging rights") · the ledger · "Every dollar on the books" · Run it back (D106, D70, D129, D39, D41) · league code (one noun); an invite link; a claim link; Copy link / Copy message (D47, D114) · Crew · Cup · Rivalry · the Record — the four objects the brand is about (brand canon §1) · the bands; "Best 3 a month count" (never "counting cap"); "the floor"; "the bye" (spec §2.2, D51, D3, D14) · Wolf / Skins / Match play / Sunningdale Rules; "$ per side / per point / per skin / per unit · $0 = bragging rights"; "carried over" never "riding" (D133) · the moments' lines are canon with their guards (D166).

### 11.4 Ruled-but-unbuilt — the redesign must cite these as executed or superseded, never re-propose them (CC-30)

D115 (the prospectus / decision sheet: WHO · WHEN · HOW · FLOOR · FINISH · STAKE) · D116 §2 ("Invited · X · REVIEW" card; a decline is a state) · D117 (door sentence + "How it works") · D118 (strangers by exact @handle only) · D123's server half (`home_feed(p_days, p_league)`) · D126 (4) / D127 (the climb captions as sentences) · D128 (rules are a place; "How this season is won") · D129 (4) (the covenant's "due before first tee") · D130 client (`homeStakeLine()` — "this round matters because") · D131 (the noun table + a preflight lint) · D132's definition of the Pro · D133 (game how-tos regardless of seat count; "never touch season points") · D134 (six placements of the live door inside the season) · D125 stage 2 ("That wasn't me" / "Entered by") · D151 on the phone (the crew step) · D114's phone half (Copy message + seat line) · D121's web half · D138's web hero · D219's web `upcomingFromSchedule`.

### 11.5 The process, in fifteen steps (CC §3C, condensed)

Talk first; code only on "build it" · an entry BEFORE build in the six-part format with a named CONFLICT line where one exists · UX/IA entries at level 3 or 5, citing the level · a voice conflict is resolved for `voice-and-tone.md` and the decision amended in the log; palette/type/motion ride the design lane with a note in `brand-canon.md`, but anything touching what a colour MEANS gets an entry first · iOS-specific decisions also get an `IOS-0xx` entry · migrations timestamp-named, never edited, every new function granted and revoked in the same file, every new profiles column granted, new RPC params default (skew) · after a push, refresh `contract.psv` and run `node tools/build-db.mjs` (writes `rpc.ts` AND `Rpc.swift`; preflight 11 fails if stale) · `node tests/preflight.mjs` must pass 21/21; `app-tests.js`, the Kit/app XCTest suites, `db-checks.sql` after any grant-touching push · verify by looking (local serve; simulator `-cs_dev_*` hatches) · design passes and structural builds ride separately · native work runs locally; remote sessions keep migrations/specs/web · the OWNER runs every mutating deploy (`supabase db push`, `git push`, `supabase functions deploy`); `./tools/ship.sh` prompts; `node tools/deploy-status.mjs` answers "what do I owe?" · native ship via `tools/ios-archive.sh`; a missing RPC on an old binary is a version mismatch to surface (`app_flags.min_ios_build`) · this work is the Experience & Interface lane; a mechanic change is a Gameplay call, the feed/notifications are Social's — name the hand-off · prod reads only via `supabase db query --linked` from the repo root.

### 11.6 Canon contradicting itself (fix in the same pass; CC-02/03/33/34/35/36)

`brand-canon.md` §4 lists Fairway green as the primary while D76/D103 and `tokens.json` make ember the live metal and Fescue the ground (no note was added) · `brand-canon.md` §7 still says "Tracked, never held" in every money surface while §3 retires it · IOS-011 says the ⊕ opens ON the post form; the D110 addendum says it ALWAYS opens the cover; neither was amended · `CLAUDE.md:301-303` still names the web as the behavioural reference and the desk as the authoring surface, both superseded by IOS-018 · the middle door is "⊕" in the Guide, "Golf" in the blueprint and the cover, "Post" on both bars · the voice doc's UI examples include "Submit Round"; the shipped voice never says "submit" · the IA blueprint is frozen HTML in `spec/handoffs/`; the redesign's IA needs a markdown artifact under `docs/` the log can cite by path (CC-32) · when and by what ruling the "Compete" slot became "Clubhouse" could not be determined (CC §5).

---

## Appendix A — Prod facts used (read-only, 2026-09-04, `supabase db query --linked`)

| Fact | Value |
|---|---|
| profiles (live / deleted) | 39 / 0 |
| carded (marker AND handle) | 29 |
| profiles with no league membership | **14 of 39** (11 of the 29 carded; 10 of those with no round) |
| profiles with no accepted buddy | **27 of 39** |
| profiles with a photo / GHIN / home course | 1 / 4 / 9 |
| profiles with ≥1 round / ≥3 rounds / zero rounds | 23 / 19 / 16 |
| `discoverable` everyone / nobody | 24 / 15 |
| friendships accepted / pending; pairs with no shared league | 12 / 12; **6** |
| rounds (not voided); in the last 21 days | 212; **14** (product-wide) |
| rounds with `played_on < created_at` (backdated/seeded) | 199 of 212 |
| rounds with a photo / with holes / outside any season window | 1 / 6 / 26 |
| leagues by phase | setup 6 (**every one with exactly 1 member**, all "My Cup", Jul 17–21) · season 6 · complete 1 (Sandbox) |
| real vs seeded in-season leagues | 2 real (Fellas, Who's the bitch? — both solo, 2 members) · 4 created 2026-08-28 at $75 (INFER seeded); 3 of 6 in-season leagues are solo |
| golfers holding 2+ non-complete leagues | 11 of 17 active |
| posts by kind | round 224 · moment 85 · system 54 · **chat 4** · announce 0 |
| post_kudos / post_comments | 5 / **0** |
| forfeits / rivalry_names / game_results / season_payouts | **0 / 0 / 0 / 0** |
| week_clashes (open / settled / with a winner) | 8 (6 / 2 / **0**) |
| scheduled_rounds (future / tagged) · round_rsvp · round_comments | 4 (1 / 3) · 1 · 1 |
| live_rounds by status (abandoned / final / open) | 26 (**21** / 5 / 0) — 81% abandoned; by game: none 13 · match 9 · sunningdale 4 · wolf 0 · skins 0; league-less 6 |
| live_round_players · guest seats · claimed | 63 · 29 · 1 |
| events / event_duels / Majors | 1 (a completed Ryder) / 9 / 0 |
| member_invites (ever / pending) · `invites` | 2 (both accepted) / 0 · **0 rows** |
| buy_ins (paid) · leagues with a pay note · season leagues at $75 | 36 (28) · **0 of 13** · 5 of 6 |
| trophies / achievements | 8 / 111 (first_round 23 · sub_100 23 · sub_90 22 · personal_best 20 · streak_4 13 · sub_80 9 · streak_8 1) |
| standings_snapshots (seasons, max week) | 13 (6, wk 23) |
| device_tokens · push_subscriptions | **1 (`ios-sandbox`)** · 1 |
| push_nudges by kind | nudge 11 · request 6 · rsvp 1 · invite 0 |
| `push_prompt_shown` / accepted / declined · `push_opened` | 1 / 0 / 0 · 7 |
| notify_chat / notify_rounds touched | 0 of 39 |
| email_queue (season recap) · cancellation_notices | 0 · 0 |
| client_events lifetime: `post_open` / `post_submit` | 109 (8 golfers) / 24 (5 golfers) — open→submit median 39 s, mean 47 s, p90 76 s |
| client_events lifetime: `league_create` / `lock_attempt` / `lock_ok` / `invite_open` | 2 / 1 / 1 / 1 (zero lock rows since 2026-08-29) |
| client_events: `home_hero_state` (web) by rung | rung7 ×12 · rung6 ×2 · rung5 ×5 · forming ×25 · season ×34; `home_hero_tap` ×2 ever |
| client_events: `orientation_shown` / `orientation_done` / `crew_step_*` / `covenant_declined` | 5 (all 2026-09-02) / 0 / **0 ever** / **0 ever** |
| growth_events | 10 (`link_opened·join` 1 · `first_round_posted` 7 · `artifact_shared·join` 2 · `profile_created` 0) |
| telemetry by event-name platform (30 days) | web-only names: 8 golfers · phone-only: 5 · both: 4 |
| feedback rows | **0** (build 669 with external testers) |
| `app_flags.ios` | `{note, min_build: 0}` — no `apple_sign_in`, no `major` |
| `app_flags.pricing.visible` · `founding.ids` | false · {} |
| scan_post / scan_claim_minted / scan_claims | 1 / 0 / 0 |
| shares / mutes | 7 / 1 |

## Appendix B — What could not be determined from reading (union of the readers' §5 lists)

How the phone's first run looks on a device (no screenshot exists) · why the Sep 4 captures are light and whether dark renders at tip · whether iOS `oneTimeCode` autofill fires for Brevo's template · why `orientation_shown` = 5 with `orientation_done` = 0 and why `growth_events` has no `profile_created` · the Supabase `rate_limit_otp` value · the cold-start Universal Link race when the app is already on Home · whether `#obWelcome` is reachable on the web · time-to-first-Home in seconds · whether Apple sign-in will be on at submission · PP-01, PP-08, PP-12 on a device · the Dynamic Island's rendering · whether `index_provisional` is being set in prod and which of D221's four unapplied migrations touch the inventory (the contract file's count and the generator's count differ) · `native_home` payload sizes and latency · whether the posts and nudges webhooks are wired and whether `APNS_*` / `BREVO_API_KEY` are set · the exact JSON shape of `live_rounds.game_result` · realtime subscriptions · the cron schedule · why 15 of 39 profiles are `discoverable='nobody'` · whether a Major ever creates a `member_invites` row · whether the card gate's starter index writes `index_current` · `store.preferredLeague`'s initial value · how often the lead card is nil on a real day (no phone telemetry) · the Clubhouse's setup/draft/before-first-tee/wrapped rooms as rendered (only a seed league in Cup Final was captured) · whether `EventChips` ever show for a real user · whether the server posts a board line when a buy-in is marked · `PeoplePickerSheet`'s explanation of the code/link split · the draw cover as seen by a member · whether `FormRowView` renders the streak tag · how the badge count composes and whether a buddy-request push lands on iOS · whether D118 was deferred or dropped · the 65 rivalry pairs' recognisability · whether the wizard's web "4 Squads" markup flashes · whether a buddy sees a league-less golfer's declared round in their stream · why 21 of 26 live rounds are abandoned · what Universal Links do when the app is not installed · which build the App Store screenshots came from (six strings tip has retired) · when the "Compete" slot became "Clubhouse" · build status of D21 (the Callout), D17, D63, D133 · whether the twelve anon endpoints in `CLAUDE.md` match db-check 2 at tip · which `IA P1–P5` texts govern the phone · the owner's intent for "Clubhouse" as a word when the tab goes.

## Appendix C — The P0 findings across all readers (20)

HM-01 Home is an empty dashboard for a golfer with no league · HM-02 the league-less hero has no action on the phone · HM-03 events do not exist on Home · CH-01 the room's first screen answers none of the five questions · PP-01 a hand-typed course cannot be posted and nothing says why · YP-01 a league-less golfer cannot invite anyone · CJ-01 every creation door is a database noun · CJ-02 "Challenge a friend" has no object · CJ-03 the wizard produces leagues of one · CJ-04 the joiner decides on four money rows or on nothing · WB-01 the web is still called the reference while the phone has the newer behaviour · DL-01 no friend-to-friend competition object · PA-001 the joiner's decision sheet is the audit's · PA-002 a $0 league gets no consent and no teaching · CC-01 the nav is a level-3 change and must be logged as one · CC-26 "money on it" must land on ruled money surfaces · CC-50 any new join door must call `covenantGate` · CC-51 report/mute/hide/suspend/delete must stay reachable · CC-52 `pg_default_acl` leaves every new table wide open · EN-01 no production phone has ever registered for push.

*Sources: the twelve reader reports and six persona walks in the session scratchpad (`scratchpad/ux/audit/reader-*.md`, `persona-*.md`); every citation above resolves to a file:line in those reports at tip `3bba87e`.*

---

## 12. The structural problems, ranked (Step 3 output — added 2026-09-05)

The ten structural problems synthesised from this audit were each attacked through three independent read-only lenses at tip `3bba87e` — *reproduces-at-tip* (does the evidence still hold in the shipping phone client, on the web and in prod?), *already-ruled* (is it fixed, or ruled in D111–D221 / IOS-0xx / the prior plan, and if ruled, built?), and *is-it-structural* (can a copy, default or single-screen change dissolve it for the walked personas' five questions?). **All ten survived** the two-of-three bar — five on 3/3, five on 2/3 — but the five 2/3 survivors were refuted *as framed* and are carried forward reframed. The full entries, with the amended statements, the evidence split into ruled-and-built / ruled-and-unbuilt / unruled, the laws that bound each fix, "what a solution must do" and the metric each moves, are in **`STRUCTURAL_PROBLEMS.md`** beside this file; the framings and sub-claims that did **not** survive are in its §3, so they are not re-argued.

| # | Id | Problem (amended) | Verdict | Level | Success metric it moves |
|---|---|---|---|---|---|
| 1 | SP-1 | The league season is the only unit of engagement — a posted round outside it has no story home, no push and no reaction, and no link brings a newcomer into a leagueless golfer's circle | 3/3 | mechanics — four rails: story home · signal · reaction · invite | friend connection · activation for the leagueless · D7/D30 · empty-state engagement |
| 2 | SP-2 | Home is one league's standing card, dispatched by phase, with no ME layer — and the phone never built the doors the web has | 2/3 | UI/implementation debt + data layer; one IA question deferred to a multi-league walk | the five questions at every open · empty-state engagement · D7/D30 · season repeat |
| 3 | SP-3 | Creation asks the organiser to configure the engine before anything exists; no intent can be said | 3/3 | IA (an intent layer above the doors) with mechanics beneath | competition creation · season repeat · friend connection · "money on it" |
| 4 | SP-5 | The smallest useful action is not trivial and does not funnel | 3/3 | mechanics (the post's *who*; the direct insert) → IA (the act after the ceremony) | activation · time-to-aha · competition creation · competition repeat |
| 5 | SP-6 | Onboarding and joining build a database row, not a golfer's context | 3/3 | IA (the sequence) with a mechanic underneath (D115's pre-join read; a decline state; a link that survives a cold install) | activation · time-to-aha · friend connection · invited-joiner conversion |
| 6 | SP-4 | "I want to beat Jake" has no **door** — the pair objects exist (D205's two-golfer season, the live match, D21's callout unbuilt) but nothing on a person leads to them | 2/3 | IA door (SP-3's layer) + one ruled-unbuilt mechanic (D21) + five amendments | competition creation between friends · friend connection · competition repeat |
| 7 | SP-9 | The product is silent between opens: the notification graph is the league graph, no personal or countdown producer exists, and the rail is unproven | 3/3 | notification mechanics (D104's level), fenced by D23 (level 2, extension path CC-22) | WAU/MAU · D7/D30 · season repeat · competition repeat — behind a production-token gate |
| 8 | SP-7 | Navigation and the season object: the nav is frozen by ruling, the room's shape is ruled-and-unheld UI, and the season arc was parked by D41 | 2/3 | level-3 process constraint (CC-01) + UI debt + one unruled mechanic (the arc) | season repeat · time-to-aha inside a league · WAU/MAU between seasons |
| 9 | SP-8 | The vocabulary is the engine's and the schema's — the noun rulings are half-built and no lint guards them | 2/3 | UI (5) + implementation (6); an execution requirement attached to SP-7 | time-to-aha · "never need a tutorial" · a retired-terms lint reading 0 at ship |
| 10 | SP-10 | **G-0** · Two clients, no ruled reference, no producer-per-law, no scoreboard | 2/3 | implementation/process (a level-3 entry, then one-liners) | makes activation, time-to-aha, WAU/MAU, D7/D30 and empty-state engagement **measurable**; moves none directly |

**Sequence is not the ranking.** SP-10's reference ruling and its three metric events land **before the first build** (they are the baseline). SP-7's level-3 nav entry lands before any navigation is built (CC-01) and decides SP-8's nouns. SP-1's four rails and SP-3's intent layer are the two builds that change what the product *is*; SP-4's door and SP-9's kinds hang off them. SP-2, SP-5 and SP-6 carry large ruled-but-unbuilt blocks that can ship in parallel and are worth shipping even if the redesign slipped.

**Two gaps the verification exposed in this audit's own evidence base:** no persona walked held **two leagues**, and none held an **event** — the two states in which SP-2's and SP-7's remaining IA claims would be tested. ⚠ RE-ARGUE: how common either state is rested on prod cohort counts, struck as behaviour — no production row can settle it either way. Both states are **seeded and walked** (EVIDENCE_POLICY.md §What replaces it, 2) before ruling on a multi-membership Home or on events-as-peers.
