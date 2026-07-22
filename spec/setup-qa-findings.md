# Setup-QA findings — 2026-07-22 prod fresh-account walk

Run per `spec/setup-qa-brief.md`: prod (v23 · ca3de31 through eaebd9a mid-walk),
375×812, fresh throwaway accounts (`+qs1` Quincy / `+qs2` Rex / `+qs3` Gus),
throwaway leagues only (The Quincy Cup — deleted in-walk · Quincy Assign QA
`9ec0a9f8-ee7a-4d2b-a53d-9e32dbc2ef45` — delete at cleanup). No real league
touched. Driven via JS-dispatched events (pane compositor dead); mousedown-only
UIs retested with proper events before registering. One caveat flagged inline
where automation could color a result.

Format: `ID · [bug|friction|copy|a11y] · where · what · repro`.

## The register

### S1 · Door → golfer card
- S1-01 · RETRACTED as bug, kept as friction · golfer card · the walk's
  "markerless save" was instrumentation error — `pfMarker` defaults to
  'saguaro' with aria-checked from first paint (the probe read aria-pressed),
  so every save carries a marker. Real observation: the identity marker
  arrives PRE-PICKED — a stranger can save without ever making the choice,
  and every skipper is a saguaro · fresh signup → save without touching the
  marker grid
- S1-02 · copy · golfer card · handle pre-suggested from EMAIL local-part
  (`@jerechofischbeckqs1`) before any name typed, while caption reads
  "Suggested from your name"; re-suggests correctly once a name is typed ·
  fresh signup, look at handle field
- S1-03 · a11y · door · signed-out door lacks aria-modal/inert — app nav
  (Home/Clubhouse/Post/You, Find golfers) stays in tab order behind the overlay
- S1-04 · a11y · marker pickers (onboarding + settings) · marker buttons carry
  no aria-pressed/selected state; wizard preset cards' ✓ is in the a11y tree on
  unselected cards too (transparent, but SR reads three checks)
- S1-05 · copy · You tab, league-less · "THIS SEASON ·" dangling middot and
  "YOUR LEAGUE" header with no league behind them
- S1-06 · bug · boot · `Boot failed at [reveal]: (window.homeFeed || []).map is
  not a function` (also `[memberships]`) fires repeatedly on prod signed-in
  boot; errbar/watchdog recover silently, slow devices eat the stall · sign in,
  read console. homeFeed is an Array once settled — transient non-array value at
  reveal (classic↔module race family)
- ✓ clean: OTP input attrs (maxlength 10 / numeric / one-time-code), name gate,
  60-day handle rule, findable-by control, `?exit` reset

### S2 · Create league (wizard → lock)
- S2-01 · bug · wizard dates · default start 2026-07-25 is a SATURDAY (§14.0:
  seasons start Sunday); customize labels it "Sat Jul 25", review + league card
  label the same date "Sun Jul 25", Cup Final "from Sun Dec 27" math assumes a
  Sun Jul 26 start — off-by-one default plus weekday-label disagreement across
  three surfaces · create league, read customize vs review
- S2-02 · bug · wizard review · "SEASON FORMAT — Points Race" renders even when
  the endgame dial is Cup Final, alongside the CUP FINAL row (contradiction);
  correct when Points table is chosen · pick Cup Final, read review
- S2-03 · friction · wizard stake · buy-in defaults to $75/player (Standard
  preset) with no explicit choice; the dial's own hint says "$0 = bragging
  rights" and a Major defaults $0 — a stranger locks a $75 pot without noticing
  · defaults → review shows BUY-IN $75
- S2-04 · copy · lock-share moment · "N in so far" wrong on both runs (0 shown
  with 1 member; 2 shown with 1 member); assign-formation league still gets
  "the draw runs when the crew is in"
- ✓ clean: nlName gate + rename copy, preset cards' bylaw summaries, review as
  fine-print disclosure, lock → share-link moment, code + /?join link minted

### S3 · Invites & join
- S3-01 · bug · join covenant · no pre-join disclosure on EITHER path: invite
  link + fresh signup auto-joins during card save (Rex landed in a $75-stake
  league sight unseen); signed-in Join-with-code joins instantly and the
  "three things to know" sheet shows only after. Stake/bylaws consent never
  happens · /?join=CODE → sign up; or Join with a code signed in
- S3-02 · friction · join/claim landings · signed-out join door shows raw code,
  not the league name (anon `league_by_code` could personalize); claim door
  prints raw ISO date ("2026-07-22")
- S3-03 · copy · hhAdd sheet · "No golfers found. Invite links still work for
  everyone else." fires before anything is typed
- S3-04 · copy · league room, member view · "Form the squads" button for
  non-Pros opens a read-only draw view — spectator control labeled as action
- ✓ clean: invalid code error, hhAdd search + link fallback, member invite-link
  copy ("any member's link works")

### S4 · Draw / assign
- S4-01 · bug · blind draw · engine accepts degenerate draws: ran with 1 player
  (1–0), redraw with 2 players put BOTH in Squad 1 (2–0, Squad 2 empty — a
  2-player/2-squad draw must be 1–1), "Start the season →" offered on the
  result, and once the pool empties no redraw control remains — league stuck;
  "minimum four to tee off" unenforced client and server · lock 2-squad league
  → Draw squads at 1 player → join 1 → Draw again
- S4-02 · bug · formation view · ignores the formation bylaw: a Pro-assign
  league opens the BLIND DRAW UI (no assign controls exist anywhere) and the
  server happily runs the draw on it; with two leagues the view also held the
  OTHER league's formation state pre-reload (stale league context) — putting a
  wrong-league "Start the season" one tap away · create assign league → Form
  the squads
- S4-03 · bug · hhDelete · delete hatch depends on native confirm()/prompt();
  session console logged "prompt() is not supported" (no dialog, silent no-op)
  — installed/standalone PWA contexts have the same hole, exactly where the
  app lives; needs an in-app confirm sheet · tap Cancel & delete in any context
  without native dialogs
- S4-04 · copy · draw view + story · "1 PLAYERS"; "Pool is empty. players
  appear here…" (lowercase sentence); board story "SQUAD 1 — 1 JOES · SQUAD 2
  — 0 JOES" (JOES + broken singular) on the league's biggest setup moment
- S4-05 · copy · clubhouse group chips · HERE badge lags a room switch (chip
  keeps HERE on the other league while the room below has switched)
- S4-06 · bug · assign engine (found during fix verification) · `assign_player`
  inserts commissioner_log WITHOUT actor_id (NOT NULL) — every assign died on
  the constraint; unreachable in prod until S4-02's client fix rendered the
  assign UI at all · assign league → tap player → tap squad → "Assign failed"

### S5 · Event setup (Ryder · Major)
- S5-01 · bug · Ryder pairings · "Generate pairings" with an empty opposing
  team toasts "Pairings set" while the session still reads "Pairings not set.",
  and the session flips UPCOMING → OPEN with zero pairings · create Ryder, add
  nobody, Generate pairings
- S5-02 · friction · Ryder scoreboard · sessions render newest-first before
  anything has been played — Session 3 on top, the next-up Session 1 buried
- S5-03 · copy · Major board story · event name lowercased ("Quincy set qa
  major — …")
- ✓ clean: Ryder sheet horizontal pan + date-input width at 375px (e5c9f0c
  holds), Ryder Sunday-anchored default date, sessions self-labeled with real
  week windows, taunts opt-in, Major window/exhibition/tiebreak explainers,
  Major $0 default

### S6 · Tee sheet (live round)
- S6-01 · bug · live-round finish · one blank hole silently kills the whole
  post: the finish sheet promises "Post N cards" counting MEMBERS (not
  complete cards), nothing warns which holes are still open, and Finish is
  final — the server (correctly) skips the incomplete card, the round is
  unrecoverable, and the guest claim attaches an empty payload. VERIFIED root
  cause on source: sheet count = `memberN`, no client completeness check; the
  walk's card was 17/18 (one hole skipped en route) and died exactly this way
  · live round, leave one hole blank, Finish → Post → "0 CARDS · INCOMPLETE
  CARD"
- S6-02 · bug · tee sheet copy · the default game card renders raw escape
  codes as text — backslash-u-2014 where the em dash should be and
  backslash-u-2019 where the apostrophe should be ("Stroke play [\ u2014] your
  card, your pace… post when you[\ u2019]re done", spaces added here so the
  codes survive this doc)
- S6-03 · friction · index display · unestablished member (0 of 3 rounds) is
  badged "18.0 IDX" / "YOUR INDEX 18.0" as flat fact; guests get "EST 18.0" —
  members should read est/— until established
- S6-04 · copy · live-round eyebrow · course value already ends "· Blue", then
  "— ${tee}" appends → "PAPAGO GOLF COURSE · BLUE — BLUE" (index.html:6239)
- S6-05 · copy · pre-pick card note · "Demo card loaded: par 72" wording on the
  real-account path ("demo" was supposed to die on live surfaces)
- S6-06 · a11y · course dropdown · results/tees bind mousedown only — keyboard
  and AT users can never pick a course or tee (Enter fires click, no handler)
- S6-07 · copy · finish sheet · "1 guest get a recap"
- ✓ clean: course search → 13 real tees → rating/slope fill → REAL par + SI
  lift ("Card loaded: par 72 — real pars and stroke index"), roster order
  league chips → app search → guest, par-prefilled stepper, draft persistence
  across a FULL reload (course/rating/slope/F9 all restored)

### S7 · Guest claim
- S7-01 · note · funnel works end-to-end: token minted, anon claim info
  personalizes the door ("Gus — Papago Golf Course · Blue"), signup attaches,
  honest toast on empty payload — value gated behind S6-01
- S7-02 · friction · claim → golfer card · the card screen drops the claim
  context (no "claiming Gus's round" breadcrumb between door promise and save)

### SX · Cross-cutting
- SX-01 · bug · home floor nudge/digest · "Your Jul · 0/2 — Post 2 more to
  clear this month's floor" and "0/1 cleared the 2-round floor. Waiting on
  Quincy." shown (a) days BEFORE the season starts and (b) for a partial edge
  month where floors are waived by blanket rule (§14.0) · join/lock a league
  mid-July, read Home

## Severity batches

**A — blocks/dataloss:** S4-01 · S4-02 · S6-01
**B — confuses/stalls:** S1-01 · S1-06 · S2-01 · S2-02 · S2-03 · S3-01 ·
S4-03 · S5-01 · S6-02 · S6-03 · SX-01
**C — polish:** S1-02..05 · S2-04 · S3-02..04 · S4-04..05 · S5-02..03 ·
S6-04..07 · S7-02

Fix A then B this lane (server-side pieces — draw balancing, formation check —
ride as migrations for the user's `supabase db push`); C only where trivial.
