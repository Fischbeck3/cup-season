# Reader · screens-visual — what the eye sees (SV-)

Cup Season · repo tip `3bba87e` (2026-09-04) · read-only · 54 frames read with the Read tool, every claim below is tagged **SAW** (in a frame or in code at the cited line) or **INFER**.

## 0. Provenance — what each image set actually is

| Set | Path | Count | What it is (SAW) | Client · theme · build |
|---|---|---|---|---|
| A | `docs/audit/signup-walk-2026-08-31/` | 11 PNG | Sign-up walk. Every frame carries the **web's** chrome: the unstamped caption `v23 · __CS_VERSION__` (`index.html:2914`, CLAUDE.md rule 2 — "unstamped is the tell that you're not on a Netlify build"), `← Back` text links, the search glass + "Cup Season" top bar, mono-caps `HOME · CLUBHOUSE · YOU` tab labels with a floating ⊕, the `#sheet` bottom sheet with an ✕ ("Card & settings", "How scoring works"). | **Web PWA served locally, 3-tab era**, dark. **Not the phone.** The brief calls this "the phone's signup walk at build ~669"; the frames say otherwise. Findings drawn from it are WEB findings and are marked so. |
| B | `apps/ios/Screenshots/6.9/` | 6 PNG | The App Store set: seeded fixture "Sunset Match" (code `TSTSUN`, the Pro "Sam Whitlock", reviewer "Sam Reviewer"), device clock 6:58, FRI AUG 28. | Native, dark, files dated Sep 1. |
| C | `scratchpad/ux/shots/` | 22 PNG | Fresh captures 17:00–17:04 today on the owner's real account (leagues "Who's the bitch?" and "Fellas", Sep 4). Frames `20–23` are named "dark" but are **pixel-for-pixel the same layout and palette as the light frames** — every one of the 22 is the light (paper) theme. `-cs_dev_*` hatches were used for `14-live-seeded` and `16-live-setup-nearby` (`MainTabView.swift:32-45`). | Native, **light in every frame**, door stamp `v1 · build 1` (a local build; `DoorView.swift:193`). |
| D | `docs/audit/blind-ux-2026-08-29/screenshots/ios/` | 12 of 13 read | The prior audit's native frames (owner's account, Aug 29). | Native, dark. |
| E | `…/screenshots/obs/` (4) · `…/screenshots/org/` (4) | 8 | The prior audit's web Home/Clubhouse frames — observer (member of two leagues) and organizer (a forming league). | Web, dark, 3-tab era. |

Theme note (INFER, see SV-01 and §5): the native default is `CSAppearance.default = .charcoal` (`CSDesign/Theme.swift:17`, stored under `cs_theme`, `CupSeasonApp.swift:11,23`); the web's is `'dark'` (`index.html:2650-2651`). Set C being light therefore means either a persisted `cs_theme=light` on that simulator or a capture harness that never flipped it — not a code default. The ground itself is no longer charcoal: D103a/b moved home to **Fescue** green-black (`bg0 #0B1410`, `Generated/Tokens.swift:47`; `decision-log.md:3769,3829`), and the native picker labels it "Fescue" (`Theme.swift:20`) while the web pill still says "Charcoal" (frame A-10). IOS-003 §1's "Charcoal ground `#0C0D0F`" row is stale text, not a defect.

---

## 1. The map — every screen / sheet / state in this area

| # | Screen · state | How reached | What it shows FIRST (top of viewport) | Primary action | Exits | Frames |
|---|---|---|---|---|---|---|
| 1 | Native door · signed out | `RootView .signedOut` → `DoorView` | Tracer mark, serif "Cup Season", ember hairline, tagline, `EMAIL` field | "Continue with email" | Terms · Privacy (dawn links) | C-15, C-23 |
| 2 | Web door · signed out | `#obDoor` | Tracer mark, tracked-caps wordmark, ember hairline, 3-line serif tagline with "Take the cup." in ember | "Continue with email" | "I have a league code" (`index.html:2809`) · Terms · Privacy | A-1 |
| 3 | Web door · email / code | same, stepped | same hero, then `← Back`, email field + Go, then `CODE FROM EMAIL` + Verify, mono status line in mint, "Resend code (27s)" | Go / Verify | ← Back | A-2, A-3 |
| 4 | Web golfer card | after verify | `✓ SIGNED IN` mint chip, "Set up your **golfer card.**", 5 fields + 3 helper paragraphs + 14 marker tiles | "Save my card" (ember, sticky) | none | A-4, A-5 |
| 5 | Native card gate (3 steps) | `RootView .cardGate` → `CardGateView` | (not captured) name+@handle → marker → index/GHIN | "Next" / "Save my card" (`CardGateView.swift:62`) | none | — |
| 6 | Orientation (both clients) | once, after the card (`RootView.swift:36-40`; `index.html:2887-2912`) | "Four places. **Two ways to play.**" + 6 cards | "Take me in" | none (pinned CTA) | A-6 |
| 7 | Web crew step | after orientation | `✓ CARD SAVED`, "Who are you **playing with?**", paragraph, `GOT A LEAGUE CODE?` field+Join, "Find your buddies", "Start a league instead", "I'll do this later" | Join (ember) | 3 other doors | A-7 |
| 8 | Home · league-less (web) | first landing | 3 doors (Join / Start a league / Start an event), grey paragraph, YOUR CARD hero with `INDEX ●—— 0 OF 3` bar and "Post your first round" | Post your first round | 3 doors, 3 mini tiles, ⊕ | A-8, E-org-13/14 |
| 9 | Home · league-less (native) | `HomeView` + `LeaguelessDoors` | 3 quiet doors then the card ladder ("Three rounds and your index goes live. Nothing else needed." `HomeView.swift:951`) | Post | + menu | (not captured) |
| 10 | Home · member (native) | tab 1 | "Cup Season" serif title · `FRI · SEP 4` · ember + · **THE CLASH** lead card · standing hero (`2nd of 2 — held`) with 3 foot lines · "Fellas" row · NEXT ROUND · AROUND YOUR BUDDIES lane · COMING UP | Lead-card action ("See the receipt →" / "Post a round") | See the table →, league row ›, THE CALENDAR ↗, YOUR BUDDIES ↗, Show earlier · 10, + menu (5 items, `HomeView.swift:178-186`) | C-00, C-01, C-20, D-01, D-14 |
| 11 | Home · member (web) | tab 1 | 3 doors, hero `1st` gold with "You lead by 22 points over Jade.", `AUG FLOOR 1/2` bar, 3 mini tiles, `MONTH CLOSES in 2 days` chip, AROUND YOUR BUDDIES | (none primary) ⊕ | THE BOARD ↗, tiles | E-obs-04/05 |
| 12 | Clubhouse · league room (native) | tab 2 | Nav title = league name, page dots, switcher; **league hero** (name, "Season live", `Code · WHOS84L9`, two mono meta lines, "Add golfers"); pane strip STANDINGS · BOARD · SCHEDULE · (POT) · ALBUM · LEAGUE; 4-column season strip; pressure meter; NEXT UP card; SEASON RACE · THE CLIMB | "Live round" pill in NEXT UP | 5–6 panes, switcher, page swipe, Add golfers | C-02, C-21, B-02, D-03 |
| 13 | Clubhouse (web) | tab 2 | `YOUR GROUPS` chips, hero card, seg tabs, pressure bar, THE CLIMB | — | tabs | E-obs-08/09, E-org-37/45 |
| 14 | Board (native) | Clubhouse pane / Home "THE BOARD ↗" | `THE BOARD` (mint) + league name; `TODAY · SEP 4` rule; rows; composer "Message the league…" + Send | Send | ‹ back | C-03, D-04, B-03 |
| 15 | Board · empty | same, new league | one grey line "◆ Your league is live — post the first round", ~1,300 px of nothing | Send (disabled) | ‹ | C-03, D-04 |
| 16 | Your golf calendar | Clubhouse SCHEDULE / Home THE CALENDAR ↗ / + menu | eyebrow repeating the title, IN YOUR CREW'S PLANS row, month grid, legend, "Tap any day…", "Put a round on the tee sheet" | Put a round on the tee sheet | ‹, day tap, ←/→ month | C-04, D-05 |
| 17 | You (native) | tab 4 | "You" serif · ⚙ · **credential hero** (photo panel or crest, name, FOUNDER, meta, marker caption, gold index, trophy chips, FORM dots + sentence) · Your buddies row · THIS SEASON stats · RIVALRIES · EVERY SEASON · display case | (none; ⚙ and rows) | Tour Card (tap hero), Your buddies, rivalries ›, seasons › | C-05, C-06, C-22, B-05, D-06 |
| 18 | You (web) | tab 3 | avatar card with `0 of 3 / HANDICAP INDEX`, "Tell us how it's going", YOUR BUDDIES row, YOUR GOLF, DISPLAY CASE empty plate | — | rows, ⊕ | A-9 |
| 19 | Your Tour Card (sheet) | tap hero / any name | "Your Tour Card · THIS IS HOW YOUR BUDDIES SEE YOU", photo credential (fixed dark), CAREER table, RECENT ROUNDS | — | drag down | C-13 |
| 20 | Card & settings | ⚙ on You | eyebrow "What your buddies see", segmented Your card / Settings, fields, 14 marker tiles, photo, handle, findable-by | Save card pill | ‹ | C-07, B-06, A-10 (web) |
| 21 | How scoring works (web sheet) | Card & settings → guide | two paragraphs then the band table | — | ✕, ‹ Card & settings | A-11 |
| 22 | Your buddies | You row / Home ↗ / + menu | FIND GOLFERS search, "Send an invite link" card, BUDDIES · 7 list | search | ‹ | C-08, D-08 |
| 23 | Post cover "Golf" | tab 3 (⊕) | "Golf" + serif sub, three prose rows (LIVE · Play now / Post a round / Plan a tee time) | Play now (ember spine, arrow) | Close | C-09 |
| 24 | Post a round (composer) | cover row 2 | dusk preview card ("— gross / Enter at least one nine."), COURSE & TEES search, RECENT COURSES, Rating/slope edit, YOUR CARD 18/9, FRONT 9 / BACK 9 fields, sticky "Post round" | Post round | ‹, Play now, Start over | C-10, D-09/10, B-04 |
| 25 | Play now · live setup | cover row 1 | SET UP THE ROUND card (course, no-match note, Tee/Rating/Slope, 18/9, par-72 paragraph, "Enter the pars"), THE FOURSOME 2×2 slots, NEARBY chip, search, ADD A GUEST | (Start — below fold) | Close | C-16, D-11 |
| 26 | Live round (play) | setup → start | ALL SQUARE + player chips, "Solo pencil…", LIVE ROUND meta, HOLE 15 serif, 18-dot strip, 4 scorer rows, SIDE GAMES card, "Group phones" | +/− steppers | Close, ←/→ hole, Change setup | C-14 |
| 27 | Start an event (sheet) | + menu / door | "Start an event · SHORT FORM · ITS OWN LITTLE TROPHY", The Ryder (LIVE), Bracket (SOON) | The Ryder | Close | C-12, D-13 |
| 28 | Name your league (wizard step 0) | Start a league | "Name your league / THE BANNER EVERYTHING HANGS UNDER", one field, fine print, Start the league, Cancel | Start the league | Cancel | C-11, D-12 |

Screens mapped: **28** (states counted separately where the eye sees a different screen).

---

## 2. Per-image notes

Legend: **Big** = biggest element and what it says · **H** = hierarchy 1 › 2 › 3 · **Stranger** = what a first-timer thinks the screen is for · **Type** = sizes/density (px in the capture; A-set = 1170 px wide ≈ 3× of 390 pt, C-set = 1206 px ≈ 3× of 402 pt, B/D = 1320 px ≈ 3× of 440 pt) · **Cards** · **Acts** = distinct actions · **Tone** · **Brand** = Gnd (fescue/charcoal ground) · Emb (ember) · Chp (champagne) · Mkr (marker glyph) · Mono (mono eyebrows) · Ser (serif numbers/sentences) · Spn (spine).

### Set A — signup walk (WEB, dark)

- **A-1 `1-door.png`** · Big: the 3-line serif tagline "Rally your crew. / Post real rounds. / **Take the cup.**" (≈100 px caps). H: tagline › ember "Continue with email" › tracked wordmark. Stranger: "a golf competition app; email to enter." Type: legal line ≈ 34 px grey at ~40% opacity (below AA by eye); caption `v23 · __CS_VERSION__` mono ≈ 28 px. Cards 0. Acts 4 (email, league code, Terms, Privacy). Tone: premium/editorial. Brand: Gnd Emb Ser Mono; hairline glow. **Strong.**
- **A-2 `2-email.png`** · Big: same tagline. H: tagline › email field (ember focus ring) + "Go" › `← Back`. Stranger: same. Type: placeholder ≈ 44 px. Cards 0. Acts 4. Tone: premium. Brand: Gnd Emb Ser. Note: the hero does not shrink to make room — the field sits at the fold.
- **A-3 `3-code.png`** · Big: tagline. H: tagline › two stacked field rows (email+Go, CODE FROM EMAIL+Verify) › mint mono sentence "Sent to … Type the sign-in code from the newest email." Stranger: "type the code." Type: mono status ≈ 36 px in `pos` mint — a status sentence in the semantic colour. Cards 0. Acts 5 (Go, Verify, Resend, Back, legal). Tone: premium → utility. Brand: Gnd Emb Ser Mono. Two ember buttons ("Go" still live after the code was sent) — redundant.
- **A-4 `4-golfer-card.png`** · Big: "Set up your **golfer card.**" serif ≈ 90 px. H: headline › `✓ SIGNED IN` mint chip › NAME ON THE CARD field. Stranger: "make a profile." Type: eyebrows mono ≈ 30 px tracked (≈10 pt), helper paragraphs ≈ 38 px grey; the handle caveat is 3 lines about a 60-day rule. Cards 0 (a form). Acts 3 fields visible + scroll. Tone: form / admin. Brand: Gnd Emb Ser Mono. The tracer mark still occupies the top 40 %.
- **A-5 `5-card-filled.png`** · Big: the 4×4 marker grid (14 tiles ≈ 240×210 px each). H: marker grid › ember "Save my card" › `+ Add your GHIN number` mono pill. Stranger: "pick an icon." Type: tile labels mono caps ≈ 34 px; helper prose ≈ 38 px. Cards 14 tiles. Acts 17 (14 tiles, GHIN, index field, Save). Tone: settings form. Brand: Gnd Emb Mkr Mono. The ember selection ring on "THE LIGHTHOUSE" is the only ember above the CTA — good.
- **A-6 `6-orientation.png`** · Big: "Four places. / **Two ways to play.**" serif ≈ 90 px. H: headline › 2×3 card wall › ember "Take me in". Stranger: "a tutorial — four tabs and two game types." Type: card subs mono caps ≈ 30 px in `dim`. Cards 6. Acts 1. Tone: explainer slide. Brand: Gnd Emb Chp (the SHORT GAME eyebrow in gold — gold on an unearned label) Ser Mono. **This is the explainer slide the brief forbids.**
- **A-7 `7-crew-step.png`** · Big: "Who are you **playing with?**" serif ≈ 90 px, centred. H: headline › `LEAGUE CODE` + ember Join › "Find your buddies" (quiet) › "Start a league instead" (mono mini) › "I'll do this later" (text). Stranger: "enter a code or find people." Type: 4 helper sentences ≈ 38 px grey. Cards 0. Acts 5. Tone: onboarding, four button styles. Brand: Gnd Emb Ser Mono. Four doors, no hierarchy between the three that are not Join.
- **A-8 `8-home-league-less.png`** · Big: ember "Post your first round" (≈ 970×130 px with a white outer glow — the loudest control in the set). H: CTA › the 3 doors row › `INDEX ●———— 0 OF 3` bar. Stranger: "a dashboard; I'm supposed to join/start something and post a round." Type: doors ≈ 40 px sans; grey paragraphs ≈ 40 px; mini-tile labels mono ≈ 28 px (≈ 9 pt); the monthly-floor paragraph is 4 lines of rules for a user with no league. Cards 1 hero + 3 mini tiles + 3 doors. Acts 8. Tone: **SaaS dashboard** (KPI tiles, progress bar, three top buttons). Brand: Gnd Emb Spn (ember spine on YOUR CARD; grey/gold/grey spines on tiles) Ser (None yet / Open) Mono. The floating ⊕ sits on the "AROUND YOUR BUDDIES" eyebrow.
- **A-9 `9-you.png`** · Big: the avatar card with a 250-px marker watermark (the Lighthouse) bleeding off the right edge. H: name "Walker" › `0 of 3 / HANDICAP INDEX` › "Tell us how it's going". Stranger: "my profile, empty." Type: `@WALKER` mono ≈ 34 px `dim`; "add your GHIN" ember underlined link; section eyebrows with ember dash ≈ 30 px. Cards 4 (hero, feedback row, buddies row, empty case plate). Acts 4. Tone: profile/admin. Brand: Gnd Emb Mkr Mono Ser. Two "YOUR BUDDIES" (eyebrow + row title) in 100 px.
- **A-10 `10-card-and-settings.png`** · Big: "Card & settings" sans bold ≈ 60 px. H: title › segmented Your card | Settings › NOTIFICATIONS pill wall. Stranger: "settings." Type: eyebrow "YOUR CARD IS WHAT YOUR BUDDIES SEE · SETTINGS RUN THE APP" mono ≈ 30 px; toggles rendered as mono pills with state in the label ("Round pings: ON"). Cards 0. Acts 9 (4 pills, 3 appearance, Sign out, ✕). Tone: admin. Brand: Gnd Mono; selected "Charcoal" outlined in `pos` mint (semantic colour as selection). `PLAN · FREE · PILOT`.
- **A-11 `11-guide-scoring.png`** · Big: "How scoring works" ≈ 60 px. H: title › two 6-line paragraphs › band table (Torched it · beat it by 3+ · 12 pts …). Stranger: "the rulebook." Type: prose ≈ 40 px grey, 12 lines before the first bold number. Cards 1 (band plate). Acts 2 (✕, ‹). Tone: documentation. Brand: Gnd Mono; the ember-dash eyebrows. The table is the only thing a golfer needs and it starts at 80 % of the viewport.

### Set B — App Store set (native, dark, seeded)

- **B-01 `01-home.png`** · Big: `2nd` serif ≈ 100 px on an ember-washed hero. H: 2nd › "Four weeks, scored fresh. Whoever's hottest takes the cup. 2 left." (serif sentence) › AROUND YOUR BUDDIES list. Stranger: "I'm second in a golf thing; a feed of people's streaks." Type: eyebrow `SUNSET MATCH · CUP FINAL` mono ember ≈ 32 px; feed rows sans ≈ 40 px; six identical checkered-flag avatars. Cards 1 hero + 6 list rows. Acts 3 (＋, THE BOARD ↗, rows). Tone: editorial → feed. Brand: Gnd Emb Ser Mono Spn (ember spine + wash). "2 left." lacks its unit; three consecutive rows say "X has posted 4 weeks running. Iron man doesn't take weeks off." — a shop-window frame showing repetition.
- **B-02 `02-clubhouse.png`** · Big: "Sunset Match" serif ≈ 80 px in a peach-washed hero. H: hero › `CUP FINAL · WK 23 / 24 · FRESH SLATE · STANDARD RULES` + span line › pane strip › a second hero "Four weeks, scored fresh." › 4-column strip (W23/24 · $450 gold · 10.9 ▼1.5 · 3 rounds) › NEXT UP › ON THE LINE. Stranger: "a league admin page: code, rules, dates, tabs, KPIs." Type: hero meta mono caps ≈ 32 px `dim`; 4 stat labels ≈ 30 px; "Add golfers" in dawn blue. Cards 4 stacked (hero, cup-final hero, strip, NEXT UP, ON THE LINE) — two heroes on one screen. Acts 10+ (6 panes, switcher, code chip, Add golfers, Live round). Tone: **admin dashboard with editorial accents**. Brand: Gnd Emb Chp ($450, ON THE LINE spine) Ser Mono Spn. Clock says "8 DAYS LEFT" where Home said "2 left".
- **B-03 `03-board.png`** · Big: three near-identical round cards (Priya Anand × 3). H: card titles › `+2.5` mint / `-4.9` red pills › `9 / PTS` stats. Stranger: "a feed of scores with reaction buttons." Type: `87 GROSS · POSTED ANYWAY` mono caps ≈ 32 px; `COUNTING #5 THIS MONTH` mint mono; date `2026-04-12` raw ISO; 12 circular reaction buttons in one viewport. Cards 3 + 2 system rows + 1 chat. Acts 12 reactions + composer + back. Tone: social feed, dense. Brand: Gnd Emb (spine) Mkr Mono; **red/green signed differentials** on every card; the marker (Saguaro) appears at 22 px only.
- **B-04 `04-post.png`** · Big: `84` serif ≈ 150 px on the dusk preview. H: 84 › "Played to your number" serif › `7 pts · Sunset Match` chip and `-0.4 vs your index` **red** chip. Stranger: "I typed 84; it scored it." Type: `POST A ROUND · YOUR INDEX 10.9` mono ≈ 30 px; course list sans ≈ 40 px; `72 / 126` rating/slope ≈ 36 px. Cards 1 + a list. Acts 8 (Play now, ‹, 3 courses, edit, 18/9, Post round, Start over). Tone: editorial hero on a form. Brand: Gnd Emb Ser Mono; dusk ground. The preview is excellent; the red pill under it undoes the band sentence.
- **B-05 `05-you.png`** · Big: `10.9` in champagne serif ≈ 110 px on a gold-spined hero. H: name "Sam Reviewer" › 10.9 › three gold trophy chips (📈 4-week streak · ⛳ First round · 🎯 Broke 100) › FORM ●●●●● (all grey, no legend) › YOUR DISPLAY CASE: 4 emoji tiles on a black plate. Stranger: "my profile with badges." Type: `@REVIEWER · PHOENIX, AZ · PAPAGO GOLF COURSE` mono ≈ 30 px; "add your GHIN" ember link. Cards 1 hero + 1 case plate (4 tiles). Acts 2 (⚙, chips). Tone: **gamified** (emoji badges, "Broke 100 · 80 gross" beside "Broke 90 · 80 gross"). Brand: Gnd Chp (5 gold elements) Ser Mkr Mono Spn. "No silverware yet — every season starts level." with no next move.
- **B-06 `06-settings.png`** · Big: the 14-tile marker grid again. H: title › segmented › fields › grid. Stranger: "edit profile." Type: eyebrow `YOUR CARD IS WHAT YOUR BUDDIES SEE · SETTINGS RUN THE APP` mono ≈ 32 px; tile labels sans ≈ 30 px. Cards 14 tiles. Acts 20+. Tone: settings form. Brand: Gnd Emb (selection ring) Mkr Mono. `FINDABLE BY All/Buddies/Nobody` with the selected pill outlined in `pos` mint.

### Set C — fresh captures (native, LIGHT in every frame)

- **C-00 `00-launch-default.png`** · Big: `2nd` serif ≈ 130 px. H: THE CLASH card (serif "You v Galen. Best round of the week takes it.") › `2nd of 2 — held` › a 4-line footnote paragraph about the Cup Final seeding › Fellas row › NEXT ROUND › AROUND YOUR BUDDIES. Stranger: "I'm losing to Galen in something with weeks and seeds." Type: eyebrows mono ≈ 30 px in ember/`mut`; the foot paragraph sans ≈ 36 px (footnote) — 4 lines × 55 chars; "89 · -2.0 · FRI" in green ≈ 40 px. Cards 2 heroes + 1 row + 1 strip. Acts 8 (＋, See the receipt →, See the table →, Fellas ›, NEXT ROUND ›, YOUR BUDDIES ↗, tab bar). Tone: editorial hero, then a rulebook foot. Brand: paper Gnd, Emb (spines, +, links), Ser, Mono; **no champagne anywhere** (nothing is earned on this Home). Light theme at launch (see §0).
- **C-01 `01-home-bottom.png`** · Big: the TODAY round card with `89 / gross`. H: 89 › `✦ FOUNDER` gold capsule › "1.4 over your number" › THIS WEEK collapsed rows. Stranger: "someone posted 89." Type: `QUIET SINCE YOUR LAST VISIT` mono ≈ 30 px; collapsed league notes ≈ 40 px with chevrons; COMING UP card mono caps ≈ 30 px in three colours (`WITH YOU` gold, `1 in` mint chip, `YOU'RE IN` gold, `☀️ 78° · 13mph`). Cards 2. Acts 6. Tone: feed. Brand: Emb Chp Mkr Mono Ser. **Defect SAW:** the name column beside the FOUNDER tag is squeezed to one glyph per line ("\ ( ( l") — the golfer's name is illegible on the ME round on Home.
- **C-02 `02-clubhouse.png`** · Big: "Who's the bitch?" serif ≈ 90 px on a peach-washed hero. H: hero › `Code · WHOS84L9` chip › two mono meta lines › "Add golfers" (dawn blue) › pane strip › 4-column strip › ember pressure bar "27 days left in September" › NEXT UP › `01 Galen IN 19` in gold. Stranger: "the league's admin page — code, dates, rules, tabs, stats — then the table starts." Type: meta ≈ 30 px mono caps `dim`; strip values mono ≈ 60 px; strip subs ≈ 34 px; four hues in one viewport (ember, gold, mint, dawn). Cards 3 + strip. Acts 12 (switcher, 5 panes, code share, Add golfers, Live round, page dots, climb rows). Tone: **admin record + KPI row**, editorial name. Brand: Emb Chp Mkr Mono Ser Spn (ember). WHO'S WINNING appears at y ≈ 1,740 of 2,000.
- **C-03 `03-board.png`** · Big: empty paper. H: `THE BOARD` (mint) › `TODAY · SEP 4` rule › one grey line "◆ Your league is live — post the first round" › ~1,300 px empty › disabled composer. Stranger: "a chat nobody has used." Type: system line sans ≈ 40 px `mut`; a 3.5-px gold spine at 50 %. Cards 0. Acts 1 (Send, disabled). Tone: blank. Brand: Chp (spine) Mono. **No next move** despite the line naming one.
- **C-04 `04-schedule.png`** · Big: the month grid card (≈ 830×690 px). H: grid › ember "Put a round on the tee sheet" › IN YOUR CREW'S PLANS row (`ON THE TEE SHEET` gold, `you lead 1–0 · YOU'RE IN` gold). Stranger: "a calendar with dots." Type: eyebrow "YOUR GOLF CALENDAR · YOURS, YOUR BUDDIES', YOUR LEAGUES'" mono ≈ 30 px repeats the nav title; legend 3 dots ≈ 30 px; "Tap any day…" + the button say the same thing. Cards 1 + 1 row. Acts 5 (‹, ← →, day taps, button). Tone: utility. Brand: Emb Chp Mkr Mono Ser (`SEP 2026` mono). Fine, redundant.
- **C-05 `05-you.png`** · Big: the photograph (the golfer at a flag, ≈ 830×830 px). H: photo › "Jerecho Fischbeck" › `10.6` in gold serif ≈ 110 px › FOUNDER gold chip › 3 gold trophy chips (📉 Personal best · 📈 4-week streak · ⛳ …) › FORM dots + 2-line legend. Stranger: "my golfer card; I'm a 10.6." Type: meta mono ≈ 30 px `GHIN 12828189 · est. Jul 2026`; marker caption "The Azalea" ≈ 34 px; form sentence ≈ 36 px. Cards 1 hero + 1 row. Acts 3 (⚙, hero → Tour Card, buddies). Tone: **premium, editorial — the best screen in the set**. Brand: Chp ×5 (spine, 10.6, FOUNDER, 3 chips), Mkr (corner medallion + caption), Ser, Mono, Spn (gold). Photo-owned credential (D202/D214) reads as a magazine cover.
- **C-06 `06-you-bottom.png`** · Big: the stats table ("Rounds posted 2 / Best vs your playing number **+2.6** / Avg **+0.3** / Index move **▼ 2.3**"). H: mono values ≈ 60 px › RIVALRIES rows (`2–0 / YOU LEAD` mint) › EVERY SEASON rows. Stranger: "stats, then head-to-heads." Type: `ACROSS 2 COUNTING ROUNDS` mono caps ≈ 28 px (≈ 9.5 pt at 3×) under each figure; row subs `SEASON I · 2ND OF 2 · 15 PTS` mono ≈ 28 px. Cards 0 (rows). Acts 4 arrows. Tone: **stats sheet**. Brand: Mkr Mono; `pos` mint on "2–0". Memory (rivalries) sits under statistics — vision principle 4 inverted.
- **C-07 `07-settings.png`** · Big: the 3×5 marker grid (native tiles ≈ 260×145 px, label sans). H: grid › fields › segmented. Stranger: "edit my card." Type: eyebrow "WHAT YOUR BUDDIES SEE" ≈ 30 px; helper "Your icon on the board…" ≈ 40 px. Cards 14 tiles. Acts 20+. Tone: form. Brand: Emb (selection ring) Mkr Mono. The Azalea ring is ember; ✓.
- **C-08 `08-people.png`** · Big: BUDDIES list (7 rows, 44-px marker discs). H: search field › "Send an invite link" card (ember link icon, mono caps sub `CHOOSE THE LEAGUE · WORKS FOR ANYONE, ACCOUNT OR NOT`) › list. Stranger: "contacts." Type: subs `@blake · Costa Mesa` ≈ 40 px. Cards 1 + 7 rows. Acts 9. Tone: utility list — clean. Brand: Emb Mkr Mono. Handles like `lcsimpson12` shown as names.
- **C-09 `09-post-cover.png`** · Big: "Golf" serif ≈ 90 px + serif sub. H: `● LIVE` ember row "Play now — score the group" (4-line paragraph) › "Post a round — after you play" › "Plan a tee time — before" › **1,000 px empty**. Stranger: "three kinds of golf thing; the first is live." Type: three paragraphs sans ≈ 40 px, 8 lines total before the third option. Cards 0 (rows with spines). Acts 4. Tone: editorial menu. Brand: Emb (spine, LIVE dot, arrow) Ser Mono. The smallest useful action is the second row and the sheet reads before it acts.
- **C-10 `10-post-composer.png`** · Big: the dusk preview card (≈ 830×470 px) on paper — the only dark object on a light screen. H: dusk card ("— gross / Enter at least one nine.") › COURSE & TEES search › RECENT COURSES list with `74 / 133` numerals › 18/9 segment › sticky "Post round". Stranger: "pick a course, then… where do I type the score?" Type: eyebrows mono ≈ 30 px; course rows sans ≈ 44 px; "Enter your card to see the score." ≈ 36 px above an ember button that looks live. Cards 1 + list. Acts 9. Tone: form under an editorial hero. Brand: Emb Ser Mono; dusk. The score fields are below the fold.
- **C-11 `11-wizard.png`** · Big: empty paper (≈ 1,300 px). H: "Name your league" sans bold ≈ 60 px › `THE BANNER EVERYTHING HANGS UNDER` mono › one field › ember "Start the league" › quiet "Cancel". Stranger: "type a name." Type: placeholder "The Big Slice, The Sunday Cup, Dew Sweep…" ≈ 44 px; fine "You can rename it any time before the bylaws lock." Cards 0. Acts 2. Tone: form step. Brand: Emb Mono. One field, one screen, two-thirds blank.
- **C-12 `12-events.png`** · Big: the sheet "Start an event" over a dimmed Home. H: The Ryder row (⚔️, mint outline, `LIVE` mint) › Bracket row (🥊, `SOON`) › "Every event mints a trophy for your display case." Stranger: "two event types, one not ready." Type: subs ≈ 36 px; `SHORT FORM · ITS OWN LITTLE TROPHY` mono ≈ 30 px. Cards 2 rows. Acts 3 (Close, Ryder, Bracket → toast). Tone: menu, half built. Brand: Mono; `pos` mint as "available" outline; emoji as event icons.
- **C-13 `13-tourcard.png`** · Big: the photograph (≈ 830×800 px). H: photo + name › `10.6` gold serif ≈ 110 px › trophy lines right-aligned (📉 Personal best · 📈 4-week streak · ⛳ First round · +2 more) › FORM + sentence › CAREER table (Rounds 18 · Best round **+2.6** · Avg **-3.7** · Home course). Stranger: "a baseball card." Type: `CAREER · VS YOUR PLAYING NUMBER` mono ≈ 30 px; table sans ≈ 44 px. Cards 1 (dusk card in any theme). Acts 0 visible. Tone: **premium** card, then a stat sheet. Brand: Chp Mkr Ser Mono; dusk ground (`CSDusk`). Keep the card; question the table.
- **C-14 `14-live-seeded.png`** · Big: `HOLE 15` serif ≈ 100 px between ←/→ discs. H: HOLE 15 › the 18-dot strip (14 ember, 1 outlined, 3 grey) › 4 scorer rows with squad spines and `− – +` steppers › ALL SQUARE header chips › SIDE GAMES card. Stranger: "a live scorecard; four players; a match." Type: `8.4 IDX · 2 STK` mono ≈ 30 px; `55 / THRU / 14 / -1` stacked 4 lines ≈ 30 px; `SIDE GAMES · TRACKED LIVE, SETTLED BETWEEN FRIENDS` ≈ 30 px caps; "Solo pencil · scores live on this phone". Cards 1 + 4 rows + 3 chips. Acts 14 (12 stepper buttons, ←/→, Change setup, Group phones, Close). Tone: **scorer's tent — athletic, dense by design**. Brand: Emb (dots), Ser, Mono, squad Spn (blue/orange/violet/grey). The strongest "golf-first" frame in the set. The empty-score dash reads as a second minus.
- **C-15 `15-door.png`** · Big: the tracer mark (≈ 340×420 px) in burnt ember. H: mark › "Cup Season" serif ≈ 90 px › ember hairline › serif tagline with "**Take the cup.**" in ink italic › EMAIL field (ember ring) › ember button. Stranger: "a golf app; sign in with email." Type: "One code, no password. Codes come from the newest email." ≈ 36 px; Terms/Privacy in dawn blue; `v1 · build 1` mono ≈ 34 px. Cards 0. Acts 3. Tone: clean, quieter than the web door — the tracked-caps wordmark and the ember "Take the cup." are gone. Brand: Emb Ser Mono; paper Gnd. No Forge frame captured.
- **C-16 `16-live-setup-nearby.png`** · Big: the SET UP THE ROUND form card (≈ 830×900 px). H: COURSE field "Bajamar Golf Club" › "No match — type the course, rating and slope by hand." › Tee / Rating / Slope › 18 | 9 seg (ember) › 2-line par-72 paragraph › "Enter the pars" pill › THE FOURSOME 2×2 dashed slots › NEARBY `BUDDY Jade · 11.2 ASK` › "Search the app — add any golfer". Stranger: "a configuration screen." Type: eyebrows mono ≈ 30 px ×7 on one screen; dashed `TAP A PLAYER BELOW` ≈ 28 px. Cards 2 (form card, foursome card) + 4 slots + chips. Acts 12+. Tone: **dense form / admin**. Brand: Emb Mono; dashed placeholders (a web pattern). This is the "we're playing this weekend" intent rendered as setup.
- **C-20 `20-dark-home.png`** · identical to C-00 (same light palette, same content, "QUIET SINCE YOUR LAST VISIT" visible at the foot). Not dark. 
- **C-21 `21-dark-clubhouse.png`** · identical to C-02. Not dark.
- **C-22 `22-dark-you.png`** · identical to C-05. Not dark.
- **C-23 `23-dark-door.png`** · identical to C-15. Not dark.

### Set D — prior audit, native (dark, Aug 29)

- **D-01 `01-door.jpg`** (actually Home) · Big: `2nd` serif on fescue. H: 2nd › "10 points back of the lead." serif › `— held` chip › AROUND YOUR BUDDIES › gold-spined Galen 79 card ("🔥 Personal best" gold) › checkered-flag system row › "Show earlier · 18" dawn. Stranger: "I'm 2nd; Galen shot 79." Type: eyebrows ≈ 32 px; `Partial month · floors waived` ≈ 36 px `mut`. Cards 2. Acts 5. Tone: editorial. Brand: Gnd(fescue) Emb Chp(earned: PB) Mkr Mono Ser Spn. Cleaner than C-00 — the Sep 4 Home added the clash card, a 4-line foot, a league row and NEXT ROUND above the same lane.
- **D-03 `03-clubhouse.jpg`** · same skeleton as C-02 in fescue; pressure bar warm→fire "3 days left in August" ember; `01 Galen LOCKED 19` gold, `02 You · Jerech… LOCKED 9`, an ember sparkline; "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS". Tone: admin + editorial. Brand: all. The "LOCKED" chips in mint (`pos` as state).
- **D-04 `04-board.jpg`** · the same empty board as C-03, in fescue, Aug 29 → unchanged at tip.
- **D-06 `06-you.jpg`** · Big: `11.3` gold serif; hero with a 64-px photo disc + `NO. 2` eyebrow; three gold chips; FORM dots with the last lit ember, **no legend**; display case: 5 emoji tiles including "Personal best · **Diff 9.3**" and "Broke 100 · 88 gross" + "Broke 90 · 88 gross". Tone: gamified. Brand: Gnd Chp ×5 Mkr Mono Ser Spn. (D202/D214 since rebuilt the panel; "Diff" is gone at tip — `TrophyMeta.swift:66-73` prints "7.8 vs course".)
- **D-08 `08-people.jpg`** · "Find a golfer" quiet button + a search field (two search affordances), BUDDIES · 6 with a mint `BUDDIES` pill on every row (a state chip that says the section name), REQUESTED rows. Tone: utility. Brand: Gnd Mkr Mono; `pos` as a label colour. (Tip's C-08 dropped the per-row pill and the duplicate button — improved.)
- **D-09 / D-10 `09-post.jpg`, `10-postround.jpg`** · the composer as C-10 in fescue, with FRONT 9 / BACK 9 fields visible (41 / 43) because the screen is taller; `GROSS —` unresolved while both nines are typed; "Enter your card to see the score." — the feedback lags the input.
- **D-11 `11-live.jpg`** · the live setup as C-16 plus `ADD A GUEST` (Name / Index / Add) and a 4-line paragraph "Pick who plays with who under the game — pairings, stakes, the lot. League members post to the season; guests play every game, post nothing, no account needed. Leave index blank for an estimated 18." Tone: dense form. 8 eyebrows on one screen.
- **D-12 `12-wizard.jpg`** · as C-11 in fescue.
- **D-13 `13-events.jpg`** · as C-12 in fescue; fine print adds "More styles land after the pilot."
- **D-14 `14-home-again.jpg`** · as D-01.
- **D-05 `05-schedule.jpg`** · as C-04 in fescue; `"Major"` in quotes on the crew row; the 29th outlined in ember.

### Set E — prior audit, web Home/Clubhouse (dark)

- **E-obs-04 `04-home-first.jpg`** · Big: `1st` in champagne serif with "You lead by **22 points** over **Jade**." H: 1st › three top doors (Start a league · Start an event · Join a league) › `AUG FLOOR 1/2 ━━━ 1 MORE · 2D` bar › 3 mini tiles (LEAGUE 1st / NEXT FRI / BOARD Open) › `MONTH CLOSES in 2 days` chip › Galen 79 card. Stranger: "a dashboard: I'm first, a deadline is coming." Type: tile labels mono ≈ 26 px (≈ 8.5–9 pt), tile subs `QUINTERO GOLF …` truncated; tab labels mono 10.5 px. Cards 1 hero + 3 tiles + 3 doors + 1 card. Acts 9. Tone: **SaaS dashboard**. Brand: Gnd Emb Chp (earned lead — correct) Mkr Mono Ser Spn. The ⊕ overlaps "LONE TREE GOLF CLUB [⊕] · AUG 23".
- **E-obs-05 `05-home-full.jpg`** · the same page at full height: after the fold, the checkered system row "Galen broke 80 for the first time — a 79. That one goes on the wall." (bold sans) and `SHOW EARLIER · 18` mono button. The tab bar renders mid-page in the tall capture (capture artifact).
- **E-obs-08 `08-club-top.jpg`** · Big: `YOUR GROUPS` chips (Fellas HERE mint · Who's the bitch? IN SEASON) then the hero card (name, "Season live", span, THE PRO · JADE), a `.seg` (Standings Board Schedule Pot Album League), the pressure bar, THE CLIMB with `01 Jerecho F…` gold + sparkline + `LOCKED` mint + 32, `02 Jade LOCKED 10`. Tone: admin tabs + editorial climb. Brand: Gnd Emb Chp Mkr Mono Ser. Two `LOCKED` chips in mint on a race table.
- **E-obs-09 `09-club-mid.jpg`** · Big: `$150` champagne serif on the ON THE LINE card (gold spine). H: $150 › YOUR INDEX 11.3 / COUNTING ROUNDS 1/4 **tiles** (bordered) › NEXT UP card › THE INDIVIDUAL RACE 3 tiles (Jerecho POINTS KING · 32 PTS / — MOST IMPROVED / Jerecho IRON MAN · 6 RDS). Stranger: "KPIs." Type: `CHAMPS $90 · RUNNER-UP $38 · POINTS KING $23 · $0 COLLECTED` mono ≈ 30 px. Cards 2 tiles + 1 card + 1 gold card + 3 tiles = **7 tiles/cards in one viewport**. Tone: **dashboard**. Brand: Gnd Emb Chp Mono Ser Spn.
- **E-org-13 / 14 `13-home-empty.jpg`, `14-home-empty-full.jpg`** · the league-less web Home as A-8 (same build), with "No rounds from your buddies yet. Post one, or **add some**" under the ⊕. The full-height frame shows nothing below AROUND YOUR BUDDIES.
- **E-org-37 `37-league-room-forming.jpg`** · a forming league: hero with `Code · THEPTCQ5`, "Squad formation", `Add golfers` pill, **"Cancel & delete this league" in red** + "(only possible before the first tee)"; seg tabs; ember-spined "SQUADS ARE FORMING / **The Pro has the list.** / 1 PLAYER IN THE POOL · 3 SEATS OPEN" with a "Form the squads" ember button under the ⊕; THE INDIVIDUAL RACE 3 empty tiles (— / — / —); a PLAYER · R · AVG VS INDEX · PTS table with one row; 4 lines of bylaw fine print ("Points King takes 15 % … bylaws §4"). Tone: **admin console**. Brand: Gnd Emb Mono Ser; `neg` red on a link.
- **E-org-45 `45-league-tab.jpg`** · the same hero, LEAGUE pane: rows "Members & invites · 1 PLAYER · View", "Share the season", "Squads · LIVE NOW — CAPTAINS READY · View", "▶ LEAGUE RULES & PRO SHOP". Tone: settings list. Brand: Gnd Emb Mono.

---

## 3. Flows in this area

### F1 · Sign up → first useful screen (web A-1…A-8; native RootView)
- **Goal:** get in and see something worth coming back for.
- **Friction (SAW):** the tracer mark + wordmark + tagline hold the top 55 % of every door step (A-1/2/3) so the fields sit at the fold; the golfer card asks 5 facts + a 14-tile choice with three helper paragraphs (A-4/5); then a 6-card explainer (A-6); then a 4-door crew step in four button styles (A-7); then a Home that is three doors, a rules paragraph and a KPI row (A-8). Native shortens the card to three steps (`CardGateView.swift:1-4`) but keeps the orientation (`RootView.swift:36-40`).
- **Unnecessary complexity:** the handle's 60-day rule and "your leagues are told when it does" before the user has a league; the monthly-floor paragraph on a league-less Home (`index.html:12506,12555`).
- **Terminology (quoted):** "golfer card", "marker", "Ball marker", "Four places. Two ways to play.", "THE LONG GAME / THE SHORT GAME", "One league: table, board, pot", "Monthly floor · Post 2 rounds a month. Miss once and your season bye covers it automatically; from the second miss your squad loses 5 points for every round you're short. Short months are waived.", "LEAGUE ONLY".
- **Dead ends:** none hard; "I'll do this later" lands on A-8 where the same three doors repeat.
- **Redundant actions:** Join a league appears on A-7 (field), A-8 (door), the ⊕, and A-1's "I have a league code".
- **Missing feedback:** A-3 keeps "Go" lit after the code is sent; A-5's Save is sticky but the index field's "starting point" caveat says nothing about what happens on Save.
- **Delight opportunity:** the marker pick is the one joyful moment in the walk (14 named glyphs) — it's buried at the bottom of a form. Make it the first thing after the name, full-bleed, and skip everything else until the first round.

### F2 · The native door (C-15, C-23)
- **Goal:** trust + enter. **Friction:** none functionally. **Loss:** the web door's identity (tracked-caps wordmark, ember "Take the cup.", the Forge tracers, `I have a league code`) is reduced to a serif name and an ink italic (`DoorView.swift:102-111,187-193`). **Missing feedback:** none. **Delight:** the Forge exists in code (`ForgeView.swift`) — no frame shows it firing.

### F3 · Home, member (C-00/01/20, B-01, D-01/14, E-obs-04/05)
- **Goal:** in three seconds — what happened, am I winning, what's next, what do I do.
- **Friction:** two heroes stacked (clash card, then standing hero) before any friend's round; a 4-line rules paragraph inside the standing hero (`LeagueCopy.swift:398-414` via `HomeHeroCopy.footEndgame:183`, rendered `HomeView.swift:990-995`); the league I lead is a one-line 11-pt row ("Fellas · Week 7 of 26 · 1st of 2, 28 clear of Jade · $150 on the books · $0 collected", `HomeView.swift:1033-1036`); the friend lane starts at ~85 % of the first viewport; the ME round card's name column is crushed (SV-02).
- **Unnecessary complexity:** "2nd of 2 — held" + "4 back of Galen · 15 – 19" + "Best 4 rounds a month count · 1 posted · 26 days left in September" + the seeding paragraph = four registers of the same standing.
- **Terminology:** "held", "scored fresh", "seed", "Months won breaks it", "on the books", "collected", "QUIET SINCE YOUR LAST VISIT", "league notes", "See the receipt".
- **Dead ends:** none. **Redundant:** "THE CALENDAR ↗" (C-01) and "NEXT ROUND ›" (C-00) both lead to the calendar; "YOUR BUDDIES ↗" and the + menu's "Find golfers".
- **Missing feedback:** the clash card never says who is winning the week in words — my line is green, Galen's is "Nothing posted"; the reader infers.
- **Delight:** the clash card's serif sentence is the right voice; let it be the whole hero ("You v Galen. You're up — 89, level with your number. Two days.") and demote the table to one line.

### F4 · Clubhouse, member (C-02/21, B-02, D-03, E-obs-08/09)
- **Goal:** who's winning, what's on the line, what do I need to do this month.
- **Friction:** the eye meets a record (`Code · WHOS84L9`, `WK 5 / 13 · POINTS RACE · STANDARD RULES`, `Mon Aug 3 → Mon Nov 2 · 13 wks · THE PRO · GALEN`, "Add golfers") — `LeagueRoomScreen.swift:158-190`, `LeagueCopy.phaseSub:231-239` — then a 5–6-pane strip (`RoomBits.swift:223-224`), then a 4-column KPI strip (`StandingsPane.swift:173-214`), then a pressure meter, then NEXT UP, and only then the climb. On the App Store frame a second hero ("Four weeks, scored fresh.") sits between the strip and the hero.
- **Unnecessary complexity:** three switchers (page dots, `arrow.left.arrow.right` menu `ClubhouseView.swift:66-76`, tab bar); the code chip on every open of a live league.
- **Terminology:** "POINTS RACE", "STANDARD RULES", "FRESH SLATE", "Bragging rights", "COUNTING ROUNDS · your best 4 count", "SEASON RACE · THE CLIMB", "IN"/"LOCKED", "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS", "ON THE LINE · CHAMPS $270 · RUNNER-UP $113".
- **Dead ends:** POT pane hidden on a $0 league (fine). **Redundant:** "Add golfers" in the hero and again under the table (`StandingsPane.swift:113-125`); "Live round" pill duplicates the ⊕.
- **Missing feedback:** none. **Delight:** the climb (`ClimbView`) with the split-flap and the sparkline is the moment — it should be the hero; the record belongs in the LEAGUE pane.

### F5 · The board (C-03, D-04, B-03)
- **Goal:** talk, react, see rounds. **Friction:** an empty board is a blank page with a disabled Send (`BoardScreen.swift:74-83`, no `CSEmptyState`; `BoardRows.swift:78-115` renders a non-interactive note). A busy board (B-03) is three identical cards with 4 reaction buttons each, a red/green pill, an ISO date (`BoardLogic.swift:77`), and a mint `COUNTING #N THIS MONTH` line. **Terminology:** "POSTED ANYWAY", "BEAT THEIR NUMBER", "COUNTING #5 THIS MONTH". **Missing feedback:** the empty line names a move ("post the first round") and offers none. **Delight:** make the first-round line a door to the composer; make the pill a band word.

### F6 · Post (C-09, C-10, D-09/10, B-04)
- **Goal:** add my round in 20 seconds. **Friction:** the ⊕ opens a three-paragraph menu (`PostCoverView.swift:90-102`); the composer puts the preview and the course list above the two fields that matter (C-10); the preview says "Enter at least one nine." while the nines are off-screen; the Post button looks enabled under "Enter your card to see the score." **Terminology:** "Enter at least one nine", "A preview — your league's own math scores it on the books", "vs your index", "Start over — clear this card". **Delight:** the filled preview (B-04: `84`, "Played to your number", `7 pts · Sunset Match`) is exactly the reward — put the score fields first so it appears in the first second.

### F7 · Play now (C-16, D-11, C-14)
- **Goal:** we're on the tee, score the group. **Friction:** the setup is a form with seven eyebrows, three numeric fields, a par-72 paragraph and a dashed 2×2 (`LiveSetupView.swift:107,153-154,472`); the guest paragraph (D-11) is four lines. **Terminology:** "OFF THE SCORECARD", "Enter the pars", "Solo pencil", "Group phones", "STROKES OFF LOW MAN (CHUCK)", "IDX · STK". **Delight:** the play screen (C-14) is the best athletic frame in the app — the setup should look like its first hole, not like its settings.

### F8 · You → Tour Card → Card & settings (C-05/06/07/13, B-05/06, D-06, A-9/10)
- **Goal:** my golf, my standing, my people, my history. **Friction:** the credential is superb; under it the page becomes a stats sheet (C-06) with rivalries and seasons below; five gold elements on one card dilute the metal; the display case is emoji tiles; settings repeat the 14-tile grid. **Terminology:** "playing number", "ACROSS 2 COUNTING ROUNDS", "Index move · SEASON TO DATE", "No silverware yet — every season starts level.", "FORM", "MOVES ONCE / 60 DAYS", "FINDABLE BY". **Dead ends:** the empty case offers no move (B-05, A-9). **Delight:** lead the lower half with RIVALRIES ("Jade 2–0 YOU LEAD") and EVERY SEASON — the memories — and fold the four figures into one sentence.

### F9 · Start something (C-11/12, D-12/13, A-7/8)
- **Goal:** "I want to beat Jake / we're playing Saturday / run a season." **Friction:** creation begins with a noun ("Name your league") on a two-thirds-empty screen; events begin with a menu whose second item toasts "Bracket isn't built yet" (`EventPickerSheet.swift:27`). **Delight:** none visible yet; the intent-first doors the brief describes are absent from every frame.

---

## 4. Findings

Severity: P0 blocks a goal · P1 major · P2 minor · P3 polish. "Q" = which of the brief's five questions is damaged (1 what's happening · 2 why it matters to me · 3 what can I do now · 4 who am I competing with · 5 what happens next).

**SV-01 · The fresh build renders LIGHT at launch and its "dark" captures are not dark — P1 (unverified cause)**
Observed: `00-launch-default.png` and all 22 frames in set C are the paper palette (`bg0 #EFF2EE`, `Tokens.swift:73`); `20–23-dark-*.png` are the same frames. Code: `CSAppearance.default = .charcoal` (`CSDesign/Theme.swift:17`), loaded once at launch (`CupSeasonApp.swift:11,23`) and forced via `preferredColorScheme` (`Theme.swift:27-33`) — so a device in dark mode cannot produce light unless `cs_theme=light` is persisted. IOS-003 §1 (D76) and §4 ("light-first defaults" is a do-not). Q: all — the brand's first impression. Recommendation: confirm on a wiped simulator / real device that the first run is Fescue; make the capture harness set `cs_theme` explicitly; treat every light-theme finding below as second-priority until the default is confirmed.

**SV-02 · The golfer's name collapses to one glyph per line beside the FOUNDER tag on the Home round card — P1**
Observed: `01-home-bottom.png` — the TODAY card shows "\ / ( ( l" stacked where the name should be; the gold `✦ FOUNDER` capsule and the `89 / gross` column are intact. Code: `HomeView.swift:560-563` places `Text(who)` and `FoundingTag` in an `HStack(alignment: .firstTextBaseline)`; `FoundingTag` is `.fixedSize()` (`FoundingTag.swift:21`) and the name has no `lineLimit`, `fixedSize` or `layoutPriority`, inside an `A11yStack` whose trailing gross column also claims width. Q1, Q4. Recommendation: `Text(who).lineLimit(1).layoutPriority(1)` (or put the tag on its own line); add the fixture to the screenshot pass.

**SV-03 · An empty board is a blank page — P1**
Observed: `03-board.png`, `04-board.jpg` (unchanged Aug 29 → Sep 4): "◆ Your league is live — post the first round" in `mut`, then ~1,300 px of ground, then a disabled Send. Code: `BoardScreen.swift:74-83` has no empty branch; `SystemRow` with `opens == nil` is a non-interactive note (`BoardRows.swift:78-115`). IOS-003 §3: "Empty: quiet icon · one line · one next move"; `CSEmptyState` exists with a CTA slot (`Components.swift:151-176`). Q3, Q5. Recommendation: when `items` is empty render `CSEmptyState(icon:…, line: "Nobody's said anything yet.", cta: "Post the first round")` wired to the composer, or make the ◆ row a door.

**SV-04 · Signed differentials in red/green on six surfaces — P1**
Observed: composer `-0.4 vs your index` red chip (`04-post.png`; `PostRoundScreen.swift:428`, tone `p.vs >= 0 ? cs.pos : cs.neg`); board cards `-4.9` red / `+2.5` green pills (`03-board.png`; `RoundStoryCard.swift:77-82` via `CSBands.pviChip:92-94`); Home clash "89 · **-2.0** · FRI" in green (`00-launch-default.png`; `HomeLead.sideLine:209-216` via `CSBands.vsShort:61-66`); You "Best vs your playing number **+2.6** / Avg **+0.3**" (`06-you-bottom.png`; `Career.swift:134-160`); Tour Card "Best round +2.6 · Avg -3.7" (`13-tourcard.png`); rivalry headline "YOU +1.2 · GALEN -0.3" (`Rivalries.swift:64`, rendered `RivalriesSection.swift:122`); standings Δ (`StandingsTableView.swift:105`), individual race avg (`IndividualRaceView.swift:80`). Canon: brand-canon §3 lines 62-63 "never PvI/differential on any user surface"; §7 line 229-230 "flashing red/green … never urgent"; IOS-003 §4 "red for 'down'" is a do-not; D210 removed the *word* and left the number. Two lenses are also named two ways on one phone: "vs your index" (composer) vs "vs your playing number" (You, D209). Q2, Q4. Recommendation: one rule — a round's figure is the band word ("Played to it", "1.4 over"), and a signed float appears only inside a receipt, in ink, labelled "vs your playing number".

**SV-05 · Four accent hues compete on every league surface, so no hierarchy wins — P1**
Observed in one viewport of `02-clubhouse.png`: ember (spine, `NEXT UP`, +, pressure bar), champagne (`01 Galen IN 19`, `ON THE TEE SHEET`, `FOUNDER`), mint `pos` (`▼ 3.0 this season`, the counting dot, `THE BOARD` title, `1 in`, `LIVE`), dawn blue (`Add golfers`, `Show earlier · 10`, `THE CALENDAR ↗`, `YOUR BUDDIES ↗`, `edit`, Terms). Code: `LeagueRoomScreen.swift:188` (dawn), `BoardScreen.swift:46` (pos on a title), `HomeView.swift:463` (dawn), `UpcomingRoundsSection.swift:35,93`, `ClimbView.swift:52,61-63`. The brief asks that WHAT'S HAPPENING / WHO'S WINNING / WHAT'S NEXT / WHAT CAN I DO be instant; the palette gives each a colour and the eye gets a legend instead of an answer. Q1, Q3, Q4, Q5. Recommendation: two accents per screen maximum — ember for the one action, gold for the one earned thing; links in `ink` underlined or in `mut`; state chips in `mut`/`line2`.

**SV-06 · `pos` (mint) is used as a selection and label colour — P2**
Observed: selected appearance pill outlined mint (`10-card-and-settings.png`; native `CardAndSettingsScreen.swift:358-361`), selected marker (`MembersSheet.swift:132-138`), selected buddy chips (`DeclareRoundSheet.swift:176-181`), draft picks (`DraftBits.swift:70,156,159`), `THE BOARD` title (`BoardScreen.swift:46`), `BUDDIES`/`LOCKED`/`HERE`/`LIVE` chips (`08-people.jpg`, `08-club-top.jpg`, `12-events.png`), counting dots (`StandingsPane.swift:207`), the mint status sentence on the web code step (`3-code.png`). IOS-003 §1: "`pos` / `neg` are semantic only … never a progress bar, never a focus ring." Q2. Recommendation: selection = ember ring (as the marker grid already does, `07-settings.png`); labels = `mut`; keep mint for money-in and performance-up only.

**SV-07 · Gold is not scarce on the identity card — P2**
Observed `05-you.png` / `13-tourcard.png`: gold spine, gold `10.6`, gold `FOUNDER`, three gold trophy chips — five champagne elements on one object; `ClimbView.swift:52,61` adds gold rank numerals and `IN` chips; `ScheduleScreen.swift:80,209` gold `ON THE TEE SHEET` / `LEAGUE MATE`. Code intent: `YouHero.swift:52-53,80` ("gold once the index is established (earned)"). Brand canon lines 118-123: gold "means earned … scarcity of gold is the design-system version of 'the board is earned.'" An index is a measurement; a founder tag is a fact. Q2, Q4. Recommendation: gold for trophies and the lead only; the index in ink serif; the founding tag in `mut` mono; rank numerals in `mut` with the leader's hairline gold (IOS-003 §2.10).

**SV-08 · Achievements are emoji clip-art, and two of them share a glyph — P2**
Observed: `05-you.png` (B), `06-you.jpg`, `13-tourcard.png`: 🎯 Broke 100, 🎯 Broke 90, 🔥 Broke 80, 📉 Personal best (a falling chart for a best), 📈 4-week streak, 🏅 fallback, 💪 Iron Man — `TrophyMeta.swift:47-56`; event icons ⚔️ 🥊 (`EventPickerSheet.swift:26-27`, `TrophyMeta.swift:42-44`). IOS-003 §1: "Emoji stay emoji — reactions …; markers and achievements are their own systems." Brief §18: "gamification clichés". Q2. Recommendation: draw the trophies as the markers are drawn (one stroke family, `CSMarkerView`-style paths), engrave them in mono; keep emoji for reactions only.

**SV-09 · One round mints two "Broke" tiles — P2**
Observed: "Broke 100 · 80 gross" beside "Broke 90 · 80 gross" (`05-you.png` B); "88 gross" twice (`06-you.jpg`). Minting is server-side (`20260716020000_achievements.sql`; ordering `20260716200000_post_round_peak.sql:63-64`). No ruling found that stacks them (searched the log for `sub_90`/`sub_100`). Q2 ("why it matters" reads as padding). Recommendation: the highest threshold crossed is the one that hangs; earlier thresholds are implied, or fold to one tile "Broke 90 (and 100) · 88".

**SV-10 · A four-line rulebook paragraph lives inside the Home hero — P1**
Observed `00-launch-default.png`: under `2nd of 2 — held` and "4 back of Galen · 15 – 19": "Best 4 rounds a month count · 1 posted · 26 days left in September" then "The top 2 golfers seed into a four-week Cup Final from Tue Oct 6 — scored fresh, so the regular season sets the seeds, not the winner. Level on points? Months won breaks it." in footnote size. Code: `LeagueCopy.endgame` `LeagueCopy.swift:398-414`, `HomeHeroCopy.footEndgame:183-187`, `footRule:154`, `footMoney:196`, rendered as `foots` `HomeView.swift:990-995`. D126 asked for "a sentence you can always see"; this is three sentences in the smallest face on the largest card. Brief: understand "WITHOUT understanding … commissioner mechanics". Q1, Q5. Recommendation: one foot line, one clause ("Cup Final from Oct 6 · top 2 go"), with "how it works" one tap away; move the seeding rule to the Clubhouse LEAGUE pane.

**SV-11 · The Clubhouse hero is a database record — P1**
Observed `02-clubhouse.png`, `B-02`, `D-03`, `E-obs-08`: name; "Season live"; `Code · WHOS84L9`; `WK 5 / 13 · POINTS RACE · STANDARD RULES`; `Mon Aug 3 → Mon Nov 2 · 13 wks · THE PRO · GALEN`; `Add golfers` (blue). Code: `LeagueRoomScreen.swift:158-190`; `LeagueCopy.phaseSub:231-239`; the web `#hh…` hero (`index.html:3621-3634`). Who's winning is at 87 % of the viewport. Brief: navigation must mirror the mental model, "League → Season → Event → Match must not be the UI". Q1, Q4, Q5. Recommendation: the hero = the league name + one serif sentence about the race ("Galen leads by 4 with 8 weeks left.") + the one action; the code, span, rules and Pro go to the LEAGUE pane; "Add golfers" is a Pro tool, not hero copy.

**SV-12 · The season strip reads as a KPI row — P2**
Observed: `SEASON W5/13 · THE POT None / Bragging rights · YOUR INDEX 10.6 ▼3.0 · COUNTING ROUNDS 1/4 ●○○○` (`02-clubhouse.png`; `StandingsPane.swift:173-214`, whose own comment says "Not a grid of tiles (IOS-003 §4)"); on the web they are bordered tiles (`E-obs-09`: 7 tiles/cards in one viewport). IOS-003 §4: "a dashboard grid of KPI tiles (one hero, one lane)" is a do-not. Q3. Recommendation: keep exactly one figure that changes what I do this month ("1 of 4 counting · 27 days") as a sentence under the hero; index and pot have homes on You and the Pot pane.

**SV-13 · Three navigation systems on the Clubhouse — P2**
Observed `02-clubhouse.png`: page dots (D203 paging), an `arrow.left.arrow.right` menu (`ClubhouseView.swift:66-76`), a 5–6-item pane strip (`RoomBits.swift:223-224`), and the tab bar. Brief: "~4–5 destinations", "excessive tabs" is a do-not. Q3. Recommendation: one league switcher (the title is the menu); panes reduced to Race · Board · Calendar with Pot/Album/League folded into the race page's tail and a ⋯.

**SV-14 · Density: 11-pt tracked-caps mono carries the load on every league screen — P2**
Observed: eight `CSFont.label` (11 pt, `Typography.swift:26`) eyebrows in one viewport of `16-live-setup-nearby.png`; the Home league row's whole standing line in `label` (`HomeView.swift:1036`: "Week 7 of 26 · 1st of 2, 28 clear of Jade · $150 on the books · $0 collected"); the Clubhouse meta lines (`LeagueRoomScreen.swift:179-185`); `ACROSS 2 COUNTING ROUNDS` under every You figure (`06-you-bottom.png`); the calendar legend; `TAP A PLAYER BELOW`. Contrast clears (light `mut #52625A` on `#EFF2EE`, `dimText` mapping `Theme.swift:57-60`), so this is density, not legibility — the "admin aesthetic" and "tiny text" the brief names. Q1. Recommendation: cap eyebrows at two per screen; anything that is a sentence about *me* goes to `sentence`/`subhead`.

**SV-15 · Raw ISO dates on the board round card, in the App Store set — P2**
Observed `03-board.png` (B): "Grand Canyon University GC · 18 holes · 2026-04-12". Code: `BoardLogic.courseLine` `BoardLogic.swift:75-78` interpolates `r.playedOn` unformatted; Home formats with `CSDate.short` (`HomeView.swift:528`). Q1. Recommendation: `CSDate.short(r.playedOn)` and regenerate the App Store frame.

**SV-16 · The App Store set shows a clock that disagrees with itself and a feed that repeats — P2**
Observed: Home hero "… 2 left." (no unit) vs Clubhouse "8 DAYS LEFT" for the same fixture (`01-home.png` vs `02-clubhouse.png`); three consecutive rows "X has posted 4 weeks running. Iron man doesn't take weeks off." D212 shares `finalClock` between hero and row — whether "2 left." is still unit-less at tip is unverified (§5). Q5. Recommendation: regenerate the six frames from tip with a fixture whose feed has six different kinds of story.

**SV-17 · The native door dropped the web door's identity — P3**
Observed `15-door.png` vs `1-door.png`: no tracked-caps wordmark, "Take the cup." in ink italic not ember, no Forge frame captured, no "I have a league code" (`index.html:2809` has it; `DoorView.swift:102-111` does not — D117 may intend this), legal links in dawn blue that reads as Apple blue on paper (`DoorView.swift:187-189`), a `v1 · build 1` stamp (`:193`, a local build). IOS-003 §1 "The Forge door … the wordmark sears in". Q2. Recommendation: restore the ember "Take the cup."; verify the Forge fires on first run; stamp the real build.

**SV-18 · The orientation is the explainer slide the brief forbids — P1**
Observed `6-orientation.png` (web) and `OrientationScreen.swift:46-59` (native, shown once after the card, `RootView.swift:36-40`): "Four places. Two ways to play." over a 2×3 card wall (Home / Clubhouse / Post / You / A league / An event) with mono-caps definitions and a gold `THE SHORT GAME` eyebrow (gold on an unearned label). Brief: "Onboarding: no explainer slides". Q3 (the first post-signup screen offers no action but "Take me in"). Recommendation: delete; let Home teach by being useful (the "How it works" sheet already exists under ⚙).

**SV-19 · The web golfer card is a 19-control form — P2 (web)**
Observed `4-golfer-card.png` / `5-card-filled.png`: name, handle (+3-line caveat), home course, index (+3-line caveat), GHIN pill, 14 marker tiles, "Save my card" — one scroll, three helper paragraphs. Native is three steps (`CardGateView.swift:1-4`). Q3. Recommendation: name → marker (full-bleed) → done; everything else on first post.

**SV-20 · The web crew step offers four doors in four button styles — P2 (web)**
Observed `7-crew-step.png`: ember Join, quiet "Find your buddies", mono-mini "Start a league instead", text "I'll do this later" (`index.html:2862-2877`). No native equivalent captured. Q3. Recommendation: one question, two answers ("I have a code" / "Just me for now") — buddies come from the first round's foursome.

**SV-21 · The league-less Home is a dashboard about a league the user does not have — P1 (web), P2 (native)**
Observed `8-home-league-less.png`, `E-org-13/14`: three doors row; grey paragraph; YOUR CARD hero with an `INDEX ●———— 0 OF 3` progress bar and a glowing CTA; three mini tiles reading `None yet · Open · —`; a 4-line monthly-floor paragraph (`index.html:12506,12555`); AROUND YOUR BUDDIES empty. Native (`LeaguelessDoors.swift:14-60`, `HomeView.swift:951`) keeps the three doors and the ladder line. Brief: "Play comes before league … Home must never become an empty dashboard." Q1, Q2, Q3. Recommendation: a league-less Home is one thing: "Post your first round" as the hero with the friends lane under it; no tiles, no floor rules, doors folded into the +.

**SV-22 · The ⊕ opens a menu you must read — P1**
Observed `09-post-cover.png`: "Golf" + a serif sub, three rows totalling eight lines of prose, 1,000 px empty below (`PostCoverView.swift:90-102`). The brief's smallest useful action ("Add my round") is row two. Q3. Recommendation: the ⊕ lands on the composer with the gross field focused; "Play now" and "Plan" are two chips on it.

**SV-23 · The composer puts the fields last — P2**
Observed `10-post-composer.png`, `09-post.jpg`: dusk preview ("— gross / Enter at least one nine.") › course search › three recent courses › Rating/slope edit › 18/9 › FRONT 9 / BACK 9 below the fold › a live-looking "Post round" under "Enter your card to see the score." Code: `PostRoundScreen.swift:382,434`; `PostRoundModel.swift:201`. Q3. Recommendation: gross first (two big mono fields), course second, preview updates in place; disable the button visibly.

**SV-24 · Live setup is a dense form — P1**
Observed `16-live-setup-nearby.png`, `11-live.jpg`: COURSE, "No match — type the course, rating and slope by hand." (`LiveSetupView.swift:472`), Tee/Rating/Slope, 18|9, "Standard par-72 card. The stepper opens on each hole's par — pick your course above and the real pars load.", "Enter the pars" (`:107`), THE FOURSOME dashed 2×2 `TAP A PLAYER BELOW` (`:153-154`), NEARBY `ASK` (`:246`), search, ADD A GUEST + a 4-line paragraph. Brief: "dense forms" is a do-not; "we're playing this weekend" is an intent. Q3. Recommendation: the setup is the first hole: course (auto from location), four faces, "Tee off"; pars, ratings and guests are disclosed on demand.

**SV-25 · The live stepper's empty score reads as a second minus — P3**
Observed `14-live-seeded.png`: every row shows `[ − ][ – ][ + ]`. Q3. Recommendation: render the empty value as a hollow dot or the par in `dim`.

**SV-26 · The calendar says the same thing three times — P3**
Observed `04-schedule.png`: nav title "Your golf calendar", eyebrow "YOUR GOLF CALENDAR · YOURS, YOUR BUDDIES', YOUR LEAGUES'" (`ScheduleScreen.swift:34`), "Tap any day to put a round on the tee sheet." + a full ember "Put a round on the tee sheet" (`:40`). Q3. Recommendation: title + grid + one button.

**SV-27 · You's lower half is a stats sheet above the memories — P2**
Observed `06-you-bottom.png`: four mono figures with `ACROSS 2 COUNTING ROUNDS` captions (`Career.swift:134-160`) precede RIVALRIES ("Jade · 2–0 YOU LEAD") and EVERY SEASON. Vision principle 4 "Memory > Statistics" (`spec/product-vision-v1.0.md:36`). Q2, Q4. Recommendation: rivalries and seasons first; the four figures become one serif sentence ("Two rounds this season, both under your number — the index is down 2.3.").

**SV-28 · The league I lead is an 11-pt footnote under the league I'm losing — P2**
Observed `00-launch-default.png`: "Fellas · Week 7 of 26 · 1st of 2, 28 clear of Jade · $150 on the books · $0 collected ›" in `label` (`HomeView.swift:1024-1040`, D121). Q4 ("who am I competing with" — the answer where I'm winning is the quietest line). Recommendation: the hero rotates to the league with the live moment (a clash closing, a lead threatened); the other league gets a serif line, not a mono one.

**SV-29 · `2nd of 2` at 130 px makes Home a daily loss banner — P2 (design judgement)**
Observed `00-launch-default.png`; produced by `HomeHeroCopy.caption:90-93` and rendered as `CSFont.hero`. In a two-person league the figure is honest and useless; the clash card above already frames the rivalry. Q2. Recommendation: at n ≤ 3 the figure is the gap ("4 back") or the week's clash, never the ordinal.

**SV-30 · The clash card does not say who is winning the week — P3**
Observed `00-launch-default.png`: "You 89 · -2.0 · FRI" in green vs "Galen Nothing posted"; the verdict is a colour. `HomeLead.sideLine:209-216`, `clashAction:219-226` ("See the receipt" for a leader — a ledger word). Q4. Recommendation: one serif line "You're up — Galen hasn't played." and the action "Hold it" / "Post a better one".

**SV-31 · The web tab bar's floating ⊕ overlaps content — P2 (web)**
Observed `8-home-league-less.png` ("AROUND YOUR BUDD[⊕]"), `E-obs-04` ("LONE TREE GOLF CLUB [⊕] · AUG 23"), `E-org-37` (over "Form the squads"). The current `index.html:3909-3912` has the four-tab bar with Post as a tab; whether the FAB is gone in prod is unverified (§5). Q3. Recommendation: confirm the 4-tab bar is live; retire the FAB.

**SV-32 · Deadline-pressure chrome on the web Home hero — P2 (web)**
Observed `E-obs-04`: `AUG FLOOR 1/2 ━━━━ 1 MORE · 2D` bar, `MONTH CLOSES in 2 days` chip, `NEXT FRI` tile; `index.html:12156,12322` comment on the same. Brief: notifications and UI "create anticipation, never manufacture engagement". Q5. Recommendation: one calm line ("One more round this month — the 31st.").

**SV-33 · A red destructive link in the league hero — P2**
Observed `E-org-37/45` ("Cancel & delete this league (only possible before the first tee)", `index.html:3634` in `--neg`); native `LeagueRoomScreen.swift:191-202` renders the same for the Pro in `cs.neg`. Q2. Recommendation: the danger link lives at the foot of the LEAGUE pane, in `mut`, two-tap.

**SV-34 · Settings as a pill wall; the marker grid repeated — P2 (web) / P3 (native)**
Observed `10-card-and-settings.png`: "Enable on this device", "Round pings: ON", "Chat pings: ON", "Season email: ON" as mono buttons with the state inside the label; `Charcoal | Light | Match device` with the choice in mint. Native `07-settings.png` / `06-settings.png` (B): the 14-tile grid again under NAME/CITY/HOME COURSE. Q3. Recommendation: native toggles; the marker grid opens from the medallion, not inline.

**SV-35 · "How scoring works" buries the band table under two paragraphs — P2 (web)**
Observed `11-guide-scoring.png`: 12 lines of prose before "Torched it · beat it by 3+ · 12 pts". `CSBands.bandName:42-48` is the whole system. Q2. Recommendation: table first, one sentence, then the rest under "the fine print".

**SV-36 · The event picker ships a dead option with an emoji — P2**
Observed `12-events.png`, `13-events.jpg`: Bracket 🥊 "SOON" → toast "Bracket isn't built yet" (`EventPickerSheet.swift:27`). Q3. Recommendation: one live style is a screen, not a menu; unbuilt styles are not listed.

**SV-37 · "Name your league" is a full screen for one field — P2**
Observed `11-wizard.png`, `12-wizard.jpg`: two-thirds empty (`WizardScreen.swift:73-81`, copy `WizardState.swift:368-377`). Brief: creation starts from intent with progressive disclosure. Q3. Recommendation: the name is the last question, pre-filled ("Galen & Jerecho's Cup"); the first is "who?".

**SV-38 · Home's largest text is the brand, not me — P3**
Observed `00-launch-default.png`: "Cup Season" serif 34 pt + `FRI · SEP 4` + ember +. Brief's hierarchy: ME first. Q2. Recommendation: the title is the lead sentence; the brand is the mark.

**SV-39 · Admin facts on the identity card — P3**
Observed `05-you.png`, `13-tourcard.png`: `GHIN 12828189 · est. Jul 2026`, `@JERECHO · PHOENIX, AZ · LOOKOUT MOUNTAIN GOLF CLUB` in mono caps; "add your GHIN" ember link on a card with an established index (`YouHero.swift`, `CredentialCard.swift:50`). Q2. Recommendation: name, marker, home course, index; GHIN and dates in settings.

**SV-40 · Three chips in three colours on the coming-up card — P3**
Observed `01-home-bottom.png`: `WITH YOU` gold, `1 in` mint capsule, `YOU'RE IN` gold, `☀️ 78° · 13mph` (`UpcomingRoundsSection.swift:93-108`). Q5. Recommendation: one line in `mut`: "Mon · Gold Canyon · with Galen · 78° and breezy".

**SV-41 · A non-token white glow on the web's first CTA — P3 (web)**
Observed `8-home-league-less.png`, `E-org-13`: "Post your first round" with a white outer ring. Q3. Recommendation: the ember fill is the emphasis; no halos.

**SV-42 · Mechanics exposed in the preview caption — P3**
Observed `04-post.png` (B): "A preview at 100% of your number — your league's own math scores it on the books." (`PostRoundScreen.swift:434`). Q2. Recommendation: "Sunset Match scores it on the books." — the allowance is the receipt's business.

**SV-43 · The dusk preview card is the only dark object on a paper page — P3 (light theme)**
Observed `10-post-composer.png`: a `CSDusk` card on `#EFF2EE`. IOS-003 §2.6 keeps dusk for ceremonies in every theme; a blank preview is not a ceremony. Q3. Recommendation: dusk only once the figure exists; before that, `bg1`.

**SV-44 · The display case's empty state has no next move — P2**
Observed `9-you.png` (web) "The case is empty — for now. Cups, crowns and event wins hang here when you take them." and `05-you.png` (B) "No silverware yet — every season starts level." — neither offers a door (IOS-003 §3 "one next move"). Q3, Q5. Recommendation: "… Start an event" / "Post a round" as the CTA.

**SV-45 · FORM dots need a sentence to be read — P3**
Observed `05-you.png`: five dots + "Your last five rounds, oldest first — a lit dot beat your playing number." (`Career.swift:207`, D214). Q2. Recommendation: five tiny band words, or the last five grosses.

**SV-46 · A green down-arrow — P3**
Observed `02-clubhouse.png`: `▼ 3.0 this season` in mint (`StandingsPane.swift:194-196`); `06-you-bottom.png`: `▼ 2.3` in ink. Correct semantics, contradictory glyph. Q2. Recommendation: "down 3.0 — better" in words, no arrow.

**SV-47 · The board's reaction bar is four buttons per card — P2**
Observed `03-board.png` (B): 12 circular buttons in one viewport (🔥 + ⚑ 💬). Q3. Recommendation: one 🔥 and a ⋯ (long-press already opens the six reactions, `HomeView.swift:585-595`).

**SV-48 · Web selected-state chips use mint and shout — P3 (web)**
Observed `E-obs-08`: `Fellas HERE` mint outline, `LOCKED` ×2 mint on the race table. Q1. Recommendation: as SV-06.

**SV-49 · Settings eyebrow reads as an instruction to the user about themselves — P3**
Observed `06-settings.png` (B): "YOUR CARD IS WHAT YOUR BUDDIES SEE · SETTINGS RUN THE APP" (tip: "What your buddies see" / "How the app runs", `CardAndSettingsScreen.swift:43` — already softened). Q2. Keep the tip copy; regenerate the frame.

**SV-50 · The prior audit's "Diff 9.3" tile is fixed at tip — record, no action**
`06-you.jpg` showed "Personal best · Diff 9.3"; `TrophyMeta.achSubtitle` `TrophyMeta.swift:66-73` now prints "7.8 vs course". Not a finding — listed so the redesign does not re-open it.

---

## 5. Verdict on the visual system

**What it does well (keep — with citations).**
1. The photo-owned credential (`05-you.png`, `13-tourcard.png`; `CredentialFace`, D202/D214, `CSPhotoScrim` `CSDesign/PhotoScrim.swift`) — the one object that looks like a premium sports product. The marker medallion in the corner and "The Azalea" caption keep identity without a silhouette.
2. Serif hero figures and serif sentences — `2nd`, `84`, `HOLE 15`, `10.6`; "You v Galen. Best round of the week takes it."; "Four weeks, scored fresh." (`Typography.swift:37-48`; `HomeLead.clashLine:207`). This is the editorial voice the brief wants.
3. The spine + wash card grammar (`Surfaces.swift:29-58`, `Components.swift:13-40`) and the looks system giving each league its wash (D103a; `ClubhouseView.swift:57`).
4. The band words (`CSBands.swift:42-55`: Torched it / Beat your number / Played to it / A little loose / Posted anyway; "1.4 over your number") and the filled composer preview (`04-post.png`: `84` · "Played to your number" · `7 pts · Sunset Match`).
5. The live play screen (`14-live-seeded.png`): hole serif, the 18-dot strip, squad spines, thumb-sized steppers — athletic and golf-first.
6. The clash lead card as a rivalry frame (`HomeLeadCard.swift`, D176) — right idea, right voice.
7. The coming-up card with weather and who's in (`UpcomingRoundsSection.swift:57-108`) — anticipation, not engagement.
8. `CSEmptyState` with a CTA slot (`Components.swift:151-176`) and voice on empties ("No stakes on the books. The cookout isn't going to bet itself." `PotPane.swift:134`).
9. Dynamic Type floors and the `dimText` mapping (`Typography.swift:8,26`; `Theme.swift:57-60`); the web's 8.5-px labels did not port.
10. The native tab bar: four places, the ember Post disc, system labels (`MainTabView.swift:169-230`).
11. The door's tracer mark, ember hairline and serif tagline (both clients); the web's tracked-caps wordmark.
12. Mono eyebrows with the ember dash (web) / hairline heads (`CSSectionHead`) — when there are two, not eight.

**The patterns that must change (with the example that proves each).**
- **Record-first heroes → sentence-first heroes.** The Clubhouse hero (`02-clubhouse.png`) is a code, a span, a rules preset and an admin link; the Home hero carries a seeding paragraph. The hero says one true sentence about the race and offers one action; the record lives in a pane.
- **Four accents → two.** `02-clubhouse.png` has ember, gold, mint and dawn in one viewport. Ember acts, gold is earned, everything else is ink or `mut`.
- **Signed floats with red/green → band words.** `-0.4 vs your index` (red), `-4.9`, `89 · -2.0 · FRI`, `+2.6 / +0.3`. The canon already forbids it; the phone prints it on six surfaces.
- **KPI strips and tile rows → one figure and a lane.** The season strip, the web's 7-tile Clubhouse (`E-obs-09`), the league-less Home's three mini tiles.
- **Forms as first screens → the first hole / the first score.** Live setup (`16-live-setup-nearby.png`), the composer (`10-post-composer.png`), the web golfer card (`5-card-filled.png`), "Name your league" (`11-wizard.png`).
- **Explainers → nothing.** The orientation (`6-orientation.png`), the "Golf" cover (`09-post-cover.png`), "How scoring works" prose before the table.
- **Emoji trophies → drawn trophies.** `05-you.png` (B), `TrophyMeta.swift:47-56`.
- **Semantic colours as chrome → semantic only.** Mint selection rings, mint titles, gold rank numerals, gold founder tags.
- **Empty = blank → empty = a door.** The board (`03-board.png`), the display case, the web's league-less lane.
- **Density by eyebrow → hierarchy by size.** Eight 11-pt caps labels on the live setup; `ACROSS 2 COUNTING ROUNDS` under every figure on You.

Against IOS-003 §1, the identity contract survives in the tokens and type (ground, two metals, three voices, spine, radii, markers) and is broken in use on four rows: **two metals never swapped** (gold on the index, the founder tag, rank numerals; mint as chrome), **`pos`/`neg` semantic only** (selection rings, titles), **emoji stay emoji** (achievements), and **the voice** (differentials on six surfaces). The Forge, the ceremonies and the split-flap are not visible in any frame.

---

## 6. What I could not determine from reading

1. **Why set C is light.** Code says charcoal is the default (`Theme.swift:17`); the harness left no notes in `scratchpad/ux/shots/`. Needs a wiped-simulator launch.
2. **Whether the "dark" captures failed at the harness or in the app** — same test.
3. **The first-run Forge and the ceremonies** (POSTED stamp, finish screen, split-flap, engraver, month seal) — no frame shows them; cannot judge motion from stills.
4. **The App Store set's "2 left." at tip** — `HomeHeroCopy.finalClock` may already print "2 weeks left" (D212); the frames are from Sep 1.
5. **Whether the web FAB is retired in prod** — `index.html:3909-3912` has the four-tab bar at tip; the Aug 31 frames show three tabs + FAB; cupseason.app was not loaded.
6. **The exact `who` string that collapsed in SV-02** (`HomeStream.who:170` returns "You" for `is_me`); the frame shows four fragments — possibly the name plus a wrap at a width near zero. Needs a reproduction.
7. **Whether stacking `sub_90` + `sub_100` is intended** — no ruling found in `spec/decision-log.md`.
8. **Accessibility sizes and the light-theme contrast of `dawn` (`#38678C`) on paper** — not captured; D211 stepped only gold/brand/pos/neg.
9. **The native card gate, the native crew step (if any), the join covenant, the wizard's later steps, the pot pane, the album, receipts, the finish ceremony, the Ryder room** — none captured in any set; outside what the eye was shown.
10. **Dark rendering at tip** — only Aug 29 (D) and the Sep 1 App Store set (B) show Fescue; D211/D214 changed light values only, so B/D should still represent dark at tip, but that is an inference.
