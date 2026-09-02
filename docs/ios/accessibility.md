# Accessibility day — wave 8 (2026-08-28)

The phone, screen by screen, against IOS-003 §2.1 (Dynamic Type — every role
is a text style + face, nothing below 11pt), §2.2 (`dim` text → `mut`), §2.7
(reduce motion → rest frames), §3 and §4. IOS-022 item 9 had already handled
the season strip, the scorecard strip and the tab strip at the accessibility
sizes; everything else is here.

Method: every screen launched on a simulator clone at
`UICTContentSizeCategoryAccessibilityL` (AX3) and
`…AccessibilityXXXL` (AX5) through the `-cs_dev_open` hatch, screenshot,
read, fixed, re-shot. VoiceOver labels were read from the code (the simulator
cannot narrate); reduce motion was verified through the environment in
previews and by reading every `withAnimation` / `.animation` / `.transition`
site. Contrast by grep for `cs.dim` outside hairlines and dots. Targets by
grep for fixed frames under 44 on anything tappable, then by reading every
`Button` whose label is bare text.

## The helpers (`Packages/CSDesign/Sources/CSDesign/A11y.swift`)

| Helper | What it is |
|---|---|
| `A11yStack` | an `HStack` at reading sizes, a `VStack` at the accessibility sizes — the one-line branch that gets a row there. `alignment` is the column's, `rowAlignment` the row's; `columnSpacing` overrides `spacing` in the column. |
| `.a11yHitSlop(vertical:horizontal:)` | a hit area larger than the drawn view on every side without moving anything (padding → `contentShape` → negative padding). Inside the `Button` label. 12 × 8 turns a text link into a 44pt target. |
| `.a11yMinTarget()` | `frame(minWidth: 44, minHeight: 44)` + `contentShape`. Inside the label. |
| `DynamicTypeSize.isA11y` | `isAccessibilitySize`, named for the branches. |

The rule the helpers encode: a fixed-width trailing figure (points, a code
chip, a stepper) never squeezes a name; at AX1+ it takes its own line.

## What was checked, what was fixed

`file:line` is the line in the wave-8 commit. "AX" = the accessibility sizes.

### The door (`Door/DoorView.swift`)
- Checked at AX3/AX5 by reading (the clone is signed in; the door only shows signed out).
- Fixed: the "Resend / Change email" pair was an `HStack` of bare text buttons — now `A11yStack` with 44pt labels (`:139`); the password stage's "Change email" and the Terms/Privacy links got 44pt frames; the code and password fields got VoiceOver labels ("The 8 digit code", "Password").
- Reduce motion: already rested — the Forge does not play and the stage rises without animation.

### The card gate (`Onboarding/CardGateView.swift`)
- Fixed: the 4-column marker grid is 2 columns at AX (`:29`) with the names on two lines; "Back" is a 44pt target; the three progress capsules read as "Step n of 3".

### Home (`Home/HomeView.swift`) — hero/header untouched (another builder's)
- Fixed: the photo feed card had a fixed 220pt image with the text overlaid — at AX5 the text overflowed the photo. The photo is now the card's *background* and the text sets the height (220 minimum) (`:353`). The gross-only card drops the gross under the name at AX (`:393`). The empty-feed sentence + its link stack at AX and the link is a 44pt target (`:62`). "Show earlier" / "Show N more" are 44pt. The occasion card's ✕ and its call to action gained hit slop and labels (`:198`, `:205`).
- VoiceOver: a feed round is one element ("Galen — 84 at Papago, beat your number by 2.4", hint "Opens the round") with rotor actions for the Tour Card and each of the six reactions (`:412–417`, `A11yReactionActions`) — the nested face button and reaction chips were unreachable before. A league post without a scorecard is no longer a dimmed button; it is a plain combined row (`:597`). Reaction chips: 44pt hit area (`:604`), value on/off.

### Clubhouse (`League/…`; `ClubhouseView.swift` / `LeaguePane.swift` untouched)
- **Hero** (`LeagueRoomScreen.swift:151`): the phase sentence and the code chip broke mid-word at AX5 ("Seaso n live", "Co de ·"). The line is an `A11yStack` (chip on its own line at AX); the chip is one `Text` with `lineLimit(1).minimumScaleFactor(0.7)` (`:229`). "Add golfers" + the danger link stack at AX (`:171`); both are label-form 44pt buttons. The cancel banner's minis wrap (`FlowRow`).
- **Climb** (`ClimbView.swift:49`): points + gap take a second line at AX; the name no longer truncates there; the marker is hidden from VoiceOver (the label already says the name).
- **Table** (`StandingsTableView.swift:83`): the four fixed columns (58/48/44pt) clipped at AX. At AX the row is three lines — the rank + move chip, the name + sub, then "Δ WK +12 · PTS 27" — and the column heads are hidden (each row says its own). VoiceOver: "1st, Galen, 27 points, up 1 this week" — the em-dash became a comma; hint says what opens.
- **Race** (`IndividualRaceView.swift:23,59`): the trio stacks at AX (no more `lineLimit(1)` scaling to 0.8); the table rows put "R 4 · VS INDEX +1.2 · PTS 27" on a second line; heads hidden at AX; "1st, Galen, 4 rounds, 27 points".
- **Pane pieces** (`StandingsPane.swift`): "On the line" stacks at AX (`:147`) and is one VoiceOver element with the hint "Opens the pot"; Next-up stacks (`:301`); the season-live tools stack (`:105`).
- **Pot** (`PotPane.swift:40`): the payout trio stacks at AX. The unpaid ✓ stays `dim` — a disabled glyph, allowed by §2.2 — but is hidden from VoiceOver; the row's label says "buy-in in / not in" and the hint says who marks it. The stake sheet's Cancel/Put-it-on-the-books row stacks at AX and Cancel loses its 110pt width there (`:204`).
- **Bylaws** (`BylawsCard.swift:23`): the 118pt key column is a line over its value at AX; each row is one element. "How scoring works": the band lines are one `Text` each so they wrap as prose.
- **Members** (`MembersSheet.swift:56,76,92`): face + name across, "Marker here" under them at AX; the Pro's three pills wrap (`FlowRow`) instead of clipping; the marker grid is 2 columns at AX with the picked marker `isSelected`; the face button has hit slop.
- **Room bits** (`RoomBits.swift`): `RoomMini` is at least 44 wide (the "✕" mini was 36) (`:78`); `RoomCheckRow`'s trailing control drops under the text at AX (`:127`); `RoomMathRow` stacks and combines.
- **Receipts** (`ReceiptSheets.swift:41,95`): "Who built it" rows and the member history rows stack at AX, with full VoiceOver sentences.
- **Ceremony** (`SeasonCeremonyView.swift:81,89`): the runner-up / points-king / pay rows stack at AX and combine; Close is a 44pt label-form button.

### The Board (`Board/…` — rows are another builder's parity work; changes kept to accessibility modifiers, plus one AX-only layout branch, flagged)
- **Composer** (`BoardScreen.swift:100`): field, then the 📣 + Send under it at AX (the field had shrunk to "Mess…").
- **Story card** (`RoundStoryCard.swift:34`): at AX5 the name rendered one letter per line beside the PvI chip and the points. *This is a layout branch inside a row file*: at AX the chip + points drop under the text (`A11yStack`); at reading sizes the layout is byte-for-byte the old `HStack`. The name button has hit slop; the card reads "Ed Metz, 84 gross · beat his number, Papago · 18 holes · Aug 22, 9 points" with a rotor action for the Tour Card (`:46–55`).
- **Reaction bar** (`ReactionBar.swift:33,44,60,95,105`): every 36pt chip has a 44pt hit area; the comments button says its count; "More reactions" is also a rotor action on the 🔥 chip; the comment field is labelled.
- **Rows** (`BoardRows.swift:128`): the chat name is a 44pt door with a hint; the digest eyebrow was `mut` at 70% (under AA) → `dimText`; ✦ and ◆ glyphs are hidden and the rows combine.
- **Scorecard** (`ScorecardSheet.swift:124`): the cells now say "Hole 7, par 4, 5 strokes" / "…, not scored" / "…, won the hole" / "…, under par" — this did **not** exist here before (it existed on the composer's strip, `PostStrip.cellLabel`); the par row says "Hole n, par p, stroke index s"; the head and SI rows are hidden (the cells carry them); a player's name cell is a header; OUT/IN/TOT are named.

### The composer (`Post/…`)
- **Screen** (`PostRoundScreen.swift`): course-memory rows and the rating/slope line stack at AX (`:150`, `:166`); the rating + slope fields stack (`:182`); the "Your card" eyebrow + 18/9 seg stack and the seg loses its 200pt cap at AX (`:214`); the two big gross figures + the sum stack (`:246`); "Enter your card", "Front & back", "Scrap the scan" are label-form 44pt buttons (their `frame(minHeight: 44)` sat *outside* the `Button`, which does not enlarge the hit area); the hero's chips wrap.
- **Strip** (`PostHoleGrid.swift`): the − / + steppers are `minWidth/minHeight` 60 (they were fixed 60 — fine, but now grow with Bold Text); the 18/9 pills have labels; the pars sheet's total is one live element; the pars fields are labelled.
- **Ceremony** (`FinishCeremonyView.swift:101,103`): already rested under reduce motion (stage 5 at once, the ball sits in the cup). Verified, unchanged.
- **The ⊕ rise** (`PostCoverView.swift` `PostCoverRise`): already lands on the rest frame under reduce motion. Verified, unchanged.

### The live round (`Live/…`)
- **Setup** (`LiveSetupView.swift`): "TAP A PLAYER BELOW" was drawn in `cs.dim` — the one text-in-dim left in the app → `dimText` (`:131`). Tee/Rating/Slope stack at AX and the tee field loses its 96pt width (`:83`); the guest name/index/Add row stacks (`:117`); the slot grid is one column at AX; the court's two zones stack (`:253`); `LiveSeg` stacks (`:322`). Player chips and game pills: the 44pt frame moved *inside* the label (it was outside, so the target was 36/40); they carry labels and hints. The seat chip's ✕ (28pt) has a 44pt hit area (`:278`); a seat chip is one element with its index and "selected"; the court chips are announced as buttons with a swap hint.
- **Scoreboard / stepper** (`LivePlayView.swift`): the scoreboard is `updatesFrequently`; the hole header is a header; the player row is name + sub over totals + stepper at AX (`:134`) — the − / + are 44pt, the score cell says "Hole 7, 5 strokes, under par", the totals combine; the tally is one "name · figure" line per player at AX (`:337`) instead of four truncated columns; wolf pills have their 44pt frame inside the label; "Change setup" has hit slop.
- **Settlement / recap** (`LiveFinishViews.swift:81`): guest rows stack at AX; "Revoke a shared link" is a full-width 44pt label-form button; check rows combine; the legend combines.

### The wizard (`Wizard/…`)
- `WizardScreen.swift`: the Cancel/Back + Next row stacks at AX (`:113`); the step scroll and the dots' width animation are off under reduce motion (`:119`, `:166`).
- `WizardSteps.swift`: the "Customize" disclosure and the step-1 dials animate only without reduce motion (`:62`); a preset card is one element, button + selected (`:118`); the first-tee row stacks (`:198`); the review rows stack and combine (`:233`); `WizardSetRow` puts the value + steppers on a second line at AX (`:281`) with the value labelled "Buy-in, $50"; `WizardSeg` is a column at AX (`:383`) — three pills at `minimumScaleFactor(0.8)` could not share the width; the info "i" reports expanded/collapsed; the portrait rows stack; **the 7pt "FINAL 4" caption** in the season band was below the 11pt floor — it is now a `CSFont.label` beside the block.
- `LeaguelessDoors.swift:26`: the three doors are a column at AX; the run-back card's header combines.

### Draft night (`Draft/…`)
- `DraftNightScreen.swift:242`: the Pro's three minis wrap (`FlowRow`) — an armed "Sure? Undo it" never clips.
- `DraftBits.swift`: a squad card reads "The Pines, 3 players: Ed (captain), Mitch, Logan" and is a button only while a pick is selected (`.accessibilityRemoveTraits(.isButton)` otherwise); pool rows stack at AX (`:177`) and say "Galen, 11.3" with "Drafts them" / "Not your pick"; the lock badge and snake rows combine.

### Events (`Events/…`)
- Setup sheets (`RyderSetupSheet.swift:80,108`, `MajorSetupSheet.swift:99`): Team A/B fields stack at AX; Cancel + Create stack and Cancel loses its 120pt cap; every field is labelled.
- `RyderRoomView.swift`: the A · score · B scoreboard is a column at AX (`:36`) and reads "Red 6½, Blue 4½. First to 9½"; organizer minis wrap (`:86`); roster rows are announced as buttons with a hint; duel rows stack at AX (`:186`).
- `MajorRoomView.swift`: board rows read "Champion, Galen, 79 · 2 cards, +3.1 vs index"; the champions roll combines; the year column is `minWidth`.
- `EventBits.swift`: `EventSeg` is a column at AX (`:57`); the staged-invitee row stacks (`:94`) and "Remove" says whom; the league picker is labelled; the event header is a header. `EventPickerSheet.swift`: emoji hidden; "The Ryder, two teams…, coming soon" as one label.

### You (`You/…`; `YouHero.swift` untouched)
- `YouScreen.swift:160`: "add your GHIN" has hit slop and stacks with "Member since" at AX.
- `YouSections.swift`: the last-round-with card puts Stage it / Later under the sentence at AX (`:20`); the silverware strip is one figure per line at AX (`:54`); recent rounds: date/course over gross at AX, the delete ✕ is 44 × 44 (was 36), each row reads "Aug 22, Papago, 84 gross, differential 12.4" (`:114`).
- `YouRows.swift:18`: stat rows stack at AX; door glyphs and arrows hidden (the row combines).
- `TrophyCaseView.swift:39,73,88`: the case is 2 columns at AX with titles on up to 3 lines (was 3 columns, `lineLimit(1)`); the engraver already rested under reduce motion — verified.
- `RivalriesSection.swift:22`: the record drops under the name at AX; the marker hidden; hint "Opens the Tour Card".
- `CredentialCard.swift:61`: the index + trophies stack at AX, the trophy lines no longer truncate there and read as "Trophies: …".
- `TourCardSheet.swift`: mute/unmute has a plain label (no emoji as the only cue); report-photo hint says it asks twice.

### Settings (`Settings/…`; the palette section untouched)
- `CardAndSettingsScreen.swift`: the pane picker is labelled; City/Home course stack at AX (`:199`); the marker grid is 2 columns at AX (`:193`); photo row stacks (`:224`); handle + findable-by stack and the three findable pills wrap with 44pt hit areas and `isSelected` (`:249`); save + status stack (`:281`); index field + Update stack (`:289`); the league rows stack and combine; "How scoring works", "Delete my account" and Cancel are 44pt label-form buttons; the delete row stacks (`:433`); the notification pills (35pt) have 44pt hit areas (`:458`); the footer links are 44pt; the middots are hidden.
- `FeedbackSheet.swift:34`: category pills have 44pt hit areas and `isSelected`; both text editors are labelled.

### Sheets shared by rounds / You / Tour Card (`Rounds/SliceComponents.swift`)
- `CheckRow` drops its trailing control under the text at AX (`:44`); `MathRow` stacks (`:103`); the marker stamp on a photo is hidden; the receipt's "Played with" line wraps.

### Design system
- `Components.swift:160`: the empty-state CTA is a 44pt target; the icon is hidden.
- `Toast.swift:55`: the pill fades in place under reduce motion (it rolled up from the bottom regardless). The slice toast (`SliceComponents.swift`) and the board toast already did / do the same.
- `Surfaces.swift:160` (another builder's file — one modifier): the section-head link has a 44pt hit area.
- `People/Links.swift` (another builder's — one modifier): `CSMini` is at least 44 wide, so an icon-only mini is a full target.

### Contrast (`cs.dim` outside hairlines and dots, after the day)
- `LiveSetupView.swift` "TAP A PLAYER BELOW" → `dimText` (fixed).
- `BoardRows.swift` "SINCE YOU WERE HERE" `mut` at 70% → `dimText` (fixed).
- Left, by the §2.2 rule: `StandingsPane.swift:196` (a ring stroke on the fill meter), `LivePlayView.swift:136` (a 4pt spine bar), `PotPane.swift:102` (the unpaid ✓, a disabled glyph, hidden from VoiceOver).
- Every artifact renderer (recap card, settlement card, jug card) uses `fixedSize` fonts on purpose — they are images, not UI.

### Copy over a photograph (D214)
- Text on a photo panel goes through `CSPhotoScrim` (`CSDesign/PhotoScrim.swift`), never a hand-rolled gradient: the **settle** dissolves the panel into the card, the **plate** is the copy's own ground on the band the words occupy. `CSDesignTests.PhotoScrimTests` composites `mut` over a paper-bright and a dusk-dark subject in both palettes and holds 4.5:1 — it is what stops a scrim being lightened for the picture's sake at the small print's expense (which is exactly what happened on 2026-09-02).
- Verify by measuring a screenshot, not by reading tokens: contrast against a photograph is not a property of the palette. `-cs_dev_cred photo` is the deliberate worst case (a nearly white subject); `-cs_dev_cred crest` is the control that isolates the scrim from the tokens.

### Increase Contrast / Bold Text
- Nothing broke. The mono and serif faces are bundled/custom, so Bold Text does not embolden them (iOS only weights the system faces); they stay legible because `mut` already passes AA at every size and the mono labels never drop below 11pt. Tokens are the same under Increase Contrast — `mut` (≈6.2:1) and `ink` clear AA on `bg0`/`bg1`/`bg2`. Not changed: a `legibilityWeight` swap to the Medium/SemiBold Plex faces would be a design decision (IOS-003 §2.1), flagged, not done.

## What remains (and why)

- **`ClubhouseView.swift`, `LeaguePane.swift`, `YouHero.swift`, `HomeView.swift`'s hero/header, the palette section** — untouched by instruction. Read at AX5: the Home hero wraps cleanly (serif figure + move chip on one line, the sentence under). The Clubhouse header's switcher and the You hero's chip strip already scroll sideways. Nothing observed broken there.
- **`People/` and `Schedule/`** (another builder's parity pass): `InvitesBanner`'s Accept/Details pair and `HomeRoundCard`'s trailing column (RSVP count · comments · weather) still sit beside the text at AX5 and squeeze it; `CSCheckRow` (the bordered check row) keeps its trailing slot beside the text. Each is a one-line `A11yStack` when that pass lands; only `CSMini`'s width was touched here.
- **`RoundStoryCard` at reading sizes** — unchanged by design; only the AX branch is new. If the parity pass restructures the face, the branch is the `A11yStack` wrapper and the `.padding(.leading, 15.5)` on the chip line.
- **The Board story card at AX5 was verified by reading and at AX3 by screenshot** — on the clone the "Since you were here" digest sat above the first story card on every open, so the AX5 frame never reached it without a finger. The AX3 shot and the composer's AX5 shot are in the set.
- **The date separator** on the board keeps `fixedSize()` on its label — "SAT · AUG 22" fits at AX5 on every iPhone width; a longer locale date would overflow. Not changed: the app is `en_US_POSIX` on that formatter.
- **Fixed-size SF Symbols** (`.font(.system(size: 13…20))`) on icon buttons do not scale with Dynamic Type. Their targets are 44pt and their labels are text, so they read; scaling them is a design pass, not an accessibility fix.
- **VoiceOver was verified by reading, not by listening** — the simulator has no screen reader in this session. The labels are in the app's voice and every interactive element has one; a device pass with VoiceOver on is the remaining check before the App Store.

## Build · tests · preflight

- `xcodebuild … build` — BUILD SUCCEEDED.
- `xcodebuild … test` — TEST SUCCEEDED: 325 tests in 80 suites (CupSeasonKit), 11 in 4 (CupSeason), 8 in 3 (CSDesign), all passing (Swift Testing; the XCTest counters read "Executed 0 tests" by design).
- `node tests/preflight.mjs` — PASS, 0 failures, 0 warnings (checks 15–17: 213 Swift files palette-pure, OTP discipline, 111 phone RPCs granted).

## Screenshots

`scratchpad/shots/before-*.png` / `after-*.png` per screen at AX5 (`…-ax5`) and AX3 (`…-ax3`), taken in-session (see the wave-8 report). The pairs that show the fixes: `clubhouse-ax5` (the hero's phase line and code chip), `board-ax5` (the story card's name and the composer), `clubhouse-standings-ax5` / `clubhouse-race-ax5` (the two tables), `post-total-ax5` (the two gross figures), `live-ax5` (the setup card), `you-ax5` / `you-bottom-ax5` (the case and the record), `settings-ax5` / `settings-pane-ax5`.
