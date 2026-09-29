# Audit · Impeccable audits AW and AW2 (web, rounds 1 and 2) and AN (native)

| | |
|---|---|
| **Measured at** | web **`9d84c483`**, source read from the snapshot `candidate-9d84c483/`. Live probes ran against the pinned server, which served `index.html` sha256 `2ac5c63a…`. Round 2 (AW2): **`ed8e6837`** (served as `272c2da1`); its four changes were measured in-process at `ed8e6837`, and everything else on the pinned `fd27ace4` server, identical outside them (§5). The native half (AN): `4112a3f0` (§4). |
| **Status read at** | **`7b9c17e4`**, live on the web since 03:53 MST on 2026-09-29, and Owner TestFlight 1335 from the same SHA: every web lane, E's native phase 1 (`6716b0ed`) and phase 2 set 1 (`146401bb`), and root's fixes through `7b9c17e4`. |
| **Date** | 2026-09-28; round 2 added 2026-09-29 |
| **Assessors** | **AW**, an independent web audit with Impeccable 4.3.1 `audit`. AW wrote no code. Round 2: **AW2**, a fresh independent audit run by session D, which opened none of AW's scored outputs; D itself checked round 1's six P1s. The native half: session A (AN). |
| **Raw evidence (outside git)** | `~/cup-season-claude-ten-gallery/evidence/audit-web/AUDIT-web.md` and `audit-web.json` · `…/audit-web/raw/` (probe results) · `…/audit-web/shots/` · `…/audit-web/snapshots/` and `…/audit-web/detector/` (sanitised DOMs and detector runs) · `…/audit-web/probe/aw-probe.mjs` · round 2: `…/evidence/r2-fd27ace4/audit-web/AUDIT-web.md`, `audit-web.json`, `raw/`, `shots/`, and D's `…/r2-fd27ace4/delta/` and `…/sessions/D-report.md` |

Written by session C (docs). Findings and scores are AW's; the status column is this file's, read from commits. The status words are as in CRITIQUE.md. *fixed (sha)* means the commit message or diff shows the fix (for a lane, the lane's own commit names it, and the sha is its merge). Round 2 checked round 1's six P1s at `ed8e6837`; a fix after that build is verification pending until round 3.

**The gate** (SESSIONS §1): at least 18/20, web and native. **Round 1: 12/20, "Acceptable (10–13)". Not met.** **Round 2 (AW2, `ed8e6837`): 13/20, still "Acceptable". Not met** (§5).

## 1 · Score by dimension

| # | Dimension | AW score | AW's key finding | What stands between it and 4 (AW) | Where it stands at `7b9c17e4` |
|---|---|:-:|---|---|---|
| 1 | Accessibility | **2** | Full-screen takeovers don't isolate what they cover (8–12 of every 14–18 Tab stops sit on invisible controls); five AA contrast failures | inert takeovers; fix the contrast pairs and the placeholder colour; `[data-tc]` rows as buttons; `<main>`, a skip link and one h1 per view | Every named change has a commit: P1-1 to P1-6, P2-7, P2-8 and P2-9 are fixed, and P3-23 in part (§2). |
| 2 | Performance | **2** | A signed-in cold open paints the sign-in Door first, then rebuilds Home three times (CLS 0.55 at 375); the whole 2.05 MB app is parsed on every visit | decide door-or-app before first paint; render Home once in final slot order; load signed-in code after the session check ("structural, post-launch") | The Door flash is fixed (69f40d1f). Home's staged render (CLS) and code splitting are open; the second is Q12 in OWNER-QUESTIONS, because the owner's direction defers nothing. |
| 3 | Responsive design | **3** | No overflow anywhere from 320 to 1600; about 15 control types under 44px; long names cut with an ellipsis; You and Schedule on the desk are the phone column stretched | 44px hit boxes; names wrap; a desk second column for You and Schedule | Every named change has a commit: targets and ellipses (38471687); You and Schedule on the desk (f46086b4). |
| 4 | Theming | **3** | 92 tokens and a verified dark-first default, but `SQHEX` bypasses the D270 tokens, three inks sit on the wrong ground, `.room-dusk` carries pre-D270 values, and theme-color doesn't match the ground | map `SQHEX` to `var(--sq*)`; fix the three ink pairings; re-point `.room-dusk`; theme-color = `bg0` | All four are fixed: 38471687 (SQHEX, the ink pairings, `.room-dusk`) and 69f40d1f (theme-color, manifest). P3-24 is fixed too (69f40d1f, 735a63ec, e8108e59, f46086b4). |
| 5 | Implementation integrity | **2** | A coherent product-specific system, but ratified retirements are not carried through: the 3.5px spine on 6+ components, fiction labelled "live" on the Door, ember CTAs and mono sentences on share views | delete the spines; label or re-word the wings; share CTAs to `act`, sentences to serif or sans | Every change AW named has a commit: share CTAs and sentences (38471687), the Door wings (b8a61266), and every spine AW listed (e8108e59, b8a61266, 1e9eb856, b82eabd9). DX's longer spine list still has two (TP-09). |
| | **Total** | **12/20** | | | **Re-measured in round 2: 13/20** (§5). AW2 moved accessibility from 2 to 3 and kept the other four where AW had them. |

AW's integrity verdict: "Pass, with verified drift."

## 2 · Every finding (P0 0 · P1 6 · P2 11 · P3 8), with status

| AW id | Sev | Dimension | Finding | Where (AW, at `9d84c483`) | Status at `7b9c17e4` |
|---|---|---|---|---|---|
| P1-1 | P1 | accessibility | Full-screen takeovers leave the covered page in the Tab order and the accessibility tree (Door, card gate, claim link, public round, person landing) | `#onboard` (index.html:4512); csModal excluded the Door (:9192); `#shareView` (:33137) | **fixed (38471687)**: the app under the Door, a link's share view or the unsubscribe page is inert (`csModal` COVERS); Tab presses on the app behind the Door went from 16 of 30 to 0. Verified at `ed8e6837` (the delta); AW2 finds all 14 takeovers inert. |
| P1-2 | P1 | accessibility | The receipt's count link is `mut` on the cream leaf in dark (2.10:1) | `.cs-tskip` in `#rcptBody` | **fixed (38471687)** "the leaf's quiet link" (DX OB-01). Verified at `ed8e6837`: 5.42:1 in dark, measured by session D (it was 2.10:1). |
| P1-3 | P1 | accessibility | The Season masthead title is ink on the ember band: 2.69:1 in light | `.seasontitle{color:var(--ink)}` | **fixed (38471687)** (DX TP-01, CQ-19). Verified at `ed8e6837`. |
| P1-4 | P1 | accessibility | The Home "Month closes" chip label is ember on bg2 (3.81:1 at 11px, dark) | `.upchip.hot .k` | **fixed (38471687)** (DX OB-02, CQ-08). Verified at `ed8e6837`. |
| P1-5 | P1 | accessibility | Placeholder text is the browser default `#757575` on at least ten fields (2.79:1 dark, 3.24:1 light) | `input.f`/`textarea.f` with no `::placeholder` | **fixed (38471687)** "every placeholder". Verified at `ed8e6837`: 5.11:1 and 4.64:1, measured by session D. |
| P1-6 | P1 | accessibility | Desk live scoring in light: the selected HOLE/CARD segment is 2.37:1 | `.vtog button.on` | **fixed (38471687)** (DX TP-05). Verified at `ed8e6837`. |
| P2-7 | P2 | accessibility | Golfer rows and the sidebar league name work only with a mouse | `[data-tc]` rows; `#sideLeague` | **fixed (38471687)** "golfer rows and the sidebar league switch work from the keyboard" |
| P2-8 | P2 | accessibility | No `main` landmark, no skip link, few headings | `section.view`, no `<main>` | **fixed (69f40d1f)**: one h1 per view, the views' container is `main`, and a skip link is the first stop. The skipped heading levels remain: DX2's TP-17 and AW2-18 find them at `ed8e6837`. |
| P2-9 | P2 | accessibility | The composer's score box has no focus indicator | `.grossbox{outline:0}` | **fixed (38471687)** "the score box draws a focus ring" |
| P2-10 | P2 | responsive | Touch targets under the 44px floor: steppers 36, chips 28, sheet Close 26×31, remove × 22×21, header search 33, course line 28, "See the receipt" 23, "THE BOARD ↗" 14, "Start over" 16, feed report/comment, delete-round ×, half-star buttons, calendar arrows | `.step button`, `.whochip`, `.selchip`, `.sheet .x`, `.pslot .sx`, `#hdrSearch`, `#postInherit`, … | **fixed (38471687)** for the controls the commit names: steppers, golfer chips, sheet Close, remove ×, header search, the inherit line, the lead's action, go-links, back links, Start over, facts, show-more, `.mini`, desk nav, HOLE/CARD, delete-round ×, reaction controls. **Open, verification pending:** the half-star buttons and the calendar arrows, which it does not name. |
| P2-11 | P2 | performance | A signed-in cold open flashes the sign-in Door, then re-lays Home three times (CLS 0.55 at 375) | the boot sequence; the pre-paint script doesn't check for a session | **fixed in part.** With a stored session the Door waits hidden until boot decides (69f40d1f). A buddy request no longer tops Home: it sits under the lead or stands down for the dispatch (e8108e59), which removes AW's third re-lay. **Open:** rendering Home once, in its final slot order. AW2 re-measured it at `ed8e6837`: CLS 0.43–0.80 at 375, now a P1 (AW2-01, Q12). |
| P2-12 | P2 | theming | Squad colour bypasses the tokens: the `SQHEX` literal palette at 26 sites | `SQHEX = ['#57A8FF', …]` | **fixed (38471687, 1e9eb856)**: `SQHEX = [0,1,2,3].map(i => var(--sq${i}))`. W1 then swept the raw squad hex left in live scoring's chips and rows and in the points receipt (f75fe107, 3547ba9c, 4b605522). |
| P2-13 | P2 | integrity | The retired 3.5px card spine is still painted (`.purse`, `.gamecard`, `.optcard`, `.nextcard`, `.ontheline`, `.ob-pcard`, …) | 11 selectors in CSS; `raw/stripes.json` | **fixed.** Home's hero, digest and occasion spines (e8108e59: ffdcd6b4, d9ee98da); the Door wings' `.ob-pcard` (b8a61266: 2bc71749); the Play landing's option cards, the live match, skins, wolf and settlement cards and the live banner (1e9eb856: ab687232); and the Season page's `.purse`, `.phasehero`, `.nextcard` and `.ontheline` (b82eabd9). DX2 finds all ten `::before` stripes gone at `ed8e6837`. DX's longer list keeps others open (TP-09), and AW2-13 still finds `.momrow`'s spine and, in source, `.sysrow`'s and `.hmoment`'s. |
| P2-14 | P2 | responsive | Long names are cut with an ellipsis instead of wrapping | `.yrow .cs-name-s`, `.cs-agate-s.is-phrase`, `#youMeta`, `#glfBoard .fbn b`, the person-landing rows | **fixed (38471687)**: 13 ellipsis rules removed (names and course lines wrap whole, and the Golfers board name "wraps whole; it was cut at 320"). Five ellipsis rules remain, none of them AW's: the trip figures, the credential's figure sub-line, the Home tile value, and two in the Door wings. W2's two-column You squeezed a long course name to three lines; root fixed that regression at 65a1a11a (course-leaf 122/122). |
| P2-15 | P2 | responsive | You and Schedule on the desk are the phone column stretched (D234) | `view-stats` and Schedule at ≥1024 | **fixed (f46086b4)**: You is identity, form and golf left with buddies and the record in the 340 aside (35b4f475); Schedule is the calendar in the reading column with plans in the aside (57325028) |
| P2-16 | P2 | integrity | The Door wings show authored fiction as live data ("Rounds hitting the board", "The season, live") | index.html:4529, :4653, data :6435–6446 | **fixed (b8a61266, 7141516f)**: labelled examples ("How a round reads", "How a season reads", an example season) that stand down on a link landing (2bc71749), and, since round 2 found them still ticking, still (7141516f; CQ-06). Whether the phone Door shows a specimen is Q6. |
| P2-17 | P2 | integrity | Share and unsubscribe takeovers paint the ordinary action in ember and set sentences in mono | person landing "Get the app" `C.hot`; unsubscribe `#FF5A2E`; the share view's base font MONO | **fixed (38471687)**: "act, not ember, for the way in; sentences in sans, labels in mono" |
| P3-18 | P3 | theming | theme-color and the manifest colours don't match the `bg0` ground | index.html:6, :4429; `manifest.webmanifest` | **fixed (69f40d1f)** |
| P3-19 | P3 | theming | `.room-dusk` re-asserts pre-D270 values (deleted tokens, old squad hues, a pre-token ground) | index.html:4052–4064 | **fixed (38471687)**: the room is the ceremony ground under the current dark printing (D277) |
| P3-20 | P3 | accessibility | The reduced-motion backstop kills the surfaces' own reduced alternatives (the toast's fade) | index.html:4309–4316 | **fixed (69f40d1f)**: the toast keeps its designed fade under Reduce Motion |
| P3-21 | P3 | accessibility | Two focus-ring systems (the browser's 1px ring on about a quarter of stops; `.mini`'s 28% glow) | `:focus-visible` rules | **fixed (69f40d1f)**: one 2px act ring, with a zero-specificity baseline replacing the browser's |
| P3-22 | P3 | accessibility | The manifest locks the installed app to portrait (WCAG 1.3.4) | `manifest.webmanifest` | **fixed (69f40d1f)** |
| P3-23 | P3 | accessibility | Errors aren't tied to their fields or to focus | `#obCodeIn`; `#obStatus`; the composer's post failure | **fixed in part.** The Door's fields name `#obStatus` and an error marks its field invalid (69f40d1f); the status lands in view at 375×380 (d15b5f18); and a refused post stays inline (`#postErr`, role=alert) with the button described by it and keeping focus (1e9eb856: 84983c4c; CQ-09). **Open:** AW2-18 finds that focus drops to `<body>` after a Door send failure, at `ed8e6837`. An earlier version of this file called P3-23 fixed. |
| P3-24 | P3 | theming | Small colour misuses: `::selection` in the retired hot, the Pro's note in pre-token gold, a pointer on non-Pro payer rows, dim "·" separators on You | index.html:3594, :4248–4262, :1338–1343 | **fixed.** `::selection` is act (69f40d1f); only the Pro's payer rows are buttons with a pointer (735a63ec); the Pro's note is on tokens with no gold, naming AW P3-24 (e8108e59: ffdcd6b4); and the facts' separators (`.cs-facts .sep`) are opaque mut (f46086b4: 35b4f475; f6cb4760: 71d9b41d). The phone's gold "From the Pro" goes to N4. |
| P3-25 | P3 | performance | One 2.05 MB document is parsed by every visitor, and every view's DOM stays resident | index.html (1.64 MB inline JS, 285 KB CSS); render-blocking Google Fonts CSS | **open.** AW calls it "structural, post-launch"; the owner's direction defers nothing, so this is Q12 in OWNER-QUESTIONS. AW2-12 measures 2.26 MB at `ed8e6837`, about 778 KB of it comments. |

**Tally at `7b9c17e4`:** 25 findings. Round 2 checked the six P1s at `ed8e6837` and all six are resolved. The P2s and P3s were not re-read one by one; AW2's own findings contradict one of them, P3-23.
- **fixed: 22.** P1-1 to P1-6; P2-7 to P2-10 and P2-12 to P2-17; P3-18 to P3-22 and P3-24. P2-10 keeps two controls its commit does not name (the half-star buttons and the calendar arrows); AW2-19 still finds the half-stars.
- **fixed in part: 2.** P2-11: Home's single render remains (AW2-01). P3-23: the Door's send failure (AW2-18).
- **open: 1.** P3-25, code splitting (Q12, AW2-12).

## 3 · What stands between 13/20 and 18/20

AW2 scored 13/20. For each dimension, this is what AW2 says stands between it and 4, with the findings' status at `7b9c17e4` (§5):
- **Accessibility (3):** name `#phIdx` (fixed, 7b9c17e4) and the card gate's `#pfBands` (AW2-10); un-nest the course row's `<summary>` (AW2-09); the receipt leaf's focus ring (AW2-11); the heading-level skips (AW2-18); and 44px on the Season board's report flag and "The season's story" (AW2-19).
- **Performance (2):** render Home once, from the combined boot state, with the lead's space reserved (AW2-01); strip the comments at build and split the Door and public shell from the signed-in app (AW2-12). Both are Q12.
- **Responsive (3):** pad the golfer page's course columns (fixed, 41cf8050); cap the 640–959 measure (AW2-20); stop live scoring, the card gate and the 800px desk rail resting content under sticky chrome (AW2-21); and the 44px targets (AW2-19).
- **Theming (3):** tokenise the literals, give the static pages a `theme-color`, delete the dead D76 CSS, and retire the glass (AW2-17).
- **Integrity (2):** mono labels and sentences to the agate and body roles (AW2-06); money in the figure role (AW2-07); no typed arrows or dingbats, with web twins of LINT-12 and LINT-13 (AW2-08); one standings object and one pot per viewport on the desk Season page (AW2-04); one clock line on Home's lead (AW2-05). AW2's verdict is FAIL until these rules hold on the web.

At 18/20, at most two points can be lost across the five dimensions. With performance at 2, the other four must all reach 4.

## 4 · Native audit AN (session A, measured at `4112a3f0`, TestFlight 1180)

Session A ran Impeccable's `audit` with `reference/audit.native.md`. Files: `~/cup-season-claude-ten-gallery/evidence/native/audit/AUDIT-native.{md,json}`.

| Dimension | Score | Where the web stands (AW) |
|---|:-:|:-:|
| Accessibility (Dynamic Type, VoiceOver names and order) | **2** | 2 |
| Performance (as far as source shows it) | **3** | 2 |
| Responsive (SE 3 against 17 Pro, and AX3) | **2** | 3 |
| Theming | **3** | 3 |
| Implementation integrity | **2** | 2 |
| **Total** | **12/20**, "Acceptable (10–13)"; the gate is 18 | 12/20 |

Issues: P0 0, P1 2, P2 15, P3 10. Session A also notes that the 4112 matrix wrote no accessibility trees, so VoiceOver order is read from source and from N2's trees at other SHAs.

| AN id | Sev | Dimension | Finding | Where (A, at `4112a3f0`) | Status at `144ee0b0` |
|---|---|---|---|---|---|
| AN-01 | P1 | accessibility | At AX3 the composer scrolls the gross field out of view while the keypad types into it | `CupSeason/Post/PostRoundScreen.swift:251` | **fixed (146401bb: bf67db31)**, in TestFlight 1335 |
| AN-02 | P1 | accessibility | Type set over round photographs fails WCAG AA in both themes (2.0:1 to 3.4:1) | `Packages/CSDesign/Sources/CSDesign/Course.swift:573` | open · N4-070. The fix is ruled from canon (OWNER-QUESTIONS §E): an inset 3:2 plate with its copy on the card ground (UI_SYSTEM §10.3), on both clients. Not built at `7b9c17e4`. |
| AN-03 | P2 | accessibility | CSFactStrip gives VoiceOver every fact three times, out of order (Home's ME strip, the story head) | `Packages/CSDesign/Sources/CSDesign/Chrome.swift:533` | open · N4 (not in E's phase 1) |
| AN-04 | P2 | accessibility | Nine screen names set in raw `display` are not headings, on pages that blank the navigation title | `CupSeason/Season/SeasonStoryPane.swift:57` | open · N4 (not in E's phase 1) |
| AN-05 | P2 | accessibility | Plan rows open on .onTapGesture and are not buttons to VoiceOver | `CupSeason/Schedule/ScheduleScreen.swift:89` | open · N4 (not in E's phase 1) |
| AN-06 | P2 | accessibility | Home's header links, every round's Comments button and the applause count miss the 44pt target | `CupSeason/Home/HomeWire.swift:344` | **fixed in part (6716b0ed: 5c25d24c)**: the Comments door is a whole 44pt target. **Open:** Home's header links and the applause count (E measured it at 20pt wide). |
| AN-07 | P2 | responsive | At AX3, rows with a trailing control break the person's name mid-word | `CupSeason/People/Links.swift:200` | open · N4 (not in E's phase 1) |
| AN-08 | P2 | responsive | The Scoreboard band breaks the league name mid-word at AX3 ('PLACEHOLDE / R SQUADS') | `CupSeason/Compete/CompeteScoreboard.swift:18` | open · N4 (not in E's phase 1) |
| AN-09 | P2 | responsive | The record's figures strip breaks 'SEASONS' mid-word at AX3 | `CupSeason/You/RecordPage.swift:114` | open · N4 (not in E's phase 1) |
| AN-10 | P2 | responsive | The declare sheet's DAY \| TEE TIME row clips and breaks words at AX3 | `CupSeason/Schedule/DeclareRoundSheet.swift:51` | **fixed (6716b0ed: 7ab58c24)**: at the AX sizes the declare sheet's day and tee time stack |
| AN-11 | P2 | responsive | FlowLayout lets an over-wide chip run off the screen (the wizard's roster at AX3) | `CupSeason/Schedule/DeclareRoundSheet.swift:283` | open · N4 (not in E's phase 1) |
| AN-12 | P2 | responsive | The Tour Card's Share action reads 'SHA…' on both phones at every size | `CupSeason/Golfers/PersonPage.swift:562` | open · N4 (not in E's phase 1) |
| AN-13 | P2 | responsive | The bag's fields cut the golfer's own words, and at AX3 the club slot itself ('Driv…') | `CupSeason/You/BagSheet.swift:113` | open · N4 (not in E's phase 1) |
| AN-14 | P2 | responsive | The photo receipt's marker stamp overprints the round's date on the 17 Pro | `CupSeason/Rounds/ReceiptMoment.swift:79` | open · N4 (not in E's phase 1) |
| AN-15 | P2 | responsive | The forced-update screen truncates its instruction at SE3 AX3 | `CupSeason/RootView.swift:487` | open · N4 (not in E's phase 1) |
| AN-16 | P2 | integrity | Ember and gold outside their ratified roles (D359/F11, UI_SYSTEM §2.4) at about a dozen sites | `CupSeason/RootView.swift:379` | **fixed in part (6716b0ed)**: "You're in —" is ink (561328ce) and the Pro's note is not a metal (2fcd0878). **Open:** the other sites; E also saw the buy-in and the board's note spine in gold. |
| AN-17 | P2 | integrity | Retired type voices still render: Charter (D268) on shared surfaces, and Plex Mono as every section head (§1.4) | `Packages/CSDesign/Sources/CSDesign/Surfaces.swift:208` | open · N4 (not in E's phase 1) |
| AN-18 | P3 | integrity | LINT-14, LINT-12 and LINT-29 leftovers: uppercased display strings, emoji on shared surfaces, `dim` as a word | `CupSeason/Compete/CompeteScreen.swift:376` | open · N4 (not in E's phase 1) |
| AN-19 | P3 | integrity | The retired card spine survives in shared rows and the draft room | `CupSeason/People/Links.swift:214` | open · N4 (not in E's phase 1) |
| AN-20 | P3 | integrity | The product's tab band has no tab-bar semantics, puts an action in a tab slot, and icons mix three sets | `Packages/CSDesign/Sources/CSDesign/Chrome.swift:395` | open · N4 (not in E's phase 1) |
| AN-21 | P3 | accessibility | Icons do not follow Dynamic Type | `Packages/CSDesign/Sources/CSDesign/Chrome.swift:107` | open · N4 (not in E's phase 1) |
| AN-22 | P3 | performance | Photos outside Home decode at full size through AsyncImage, avatars included | `Packages/CSDesign/Sources/CSDesign/Person.swift:161` | open · N4 (not in E's phase 1) |
| AN-23 | P3 | performance | Shared date helpers allocate a DateFormatter on every call | `Packages/CSDesign/Sources/CSDesign/Surfaces.swift:104` | open · N4 (not in E's phase 1) |
| AN-24 | P3 | responsive | At AX3 a pinned foot shears a sentence, and the Door's primary starts below the fold on SE3 | `CupSeason/People/LinkConfirmationSheet.swift:24` | open · N4 (not in E's phase 1) |
| AN-25 | P3 | integrity | A round with one comment reads '1 comments' on Home | `CupSeason/Home/HomeWire.swift:341` | **fixed (6716b0ed: 5c25d24c)**: one comment reads as one |
| AN-26 | P3 | integrity | The activity inbox's empty state is a sentence with no door (LINT-21) | `CupSeason/Home/SocialActivitySheet.swift:86` | open · N4 (not in E's phase 1) |
| AN-27 | P3 | responsive | Live scoring truncates a player's running line on SE3 at the default size | `CupSeason/Live/LivePlayView.swift:448` | **fixed (6716b0ed: 327d6708, d27d3b6e, b9e42723)**: the SE keeps its 20pt gutter, and a live row wraps its name and breaks its facts on their separator |

**Tally at `7b9c17e4`:** 27 findings.
- **fixed: 4.** AN-01 (a P1, in E's phase 2 set 1), AN-10, AN-25 and AN-27.
- **fixed in part: 2.** AN-06 and AN-16.
- **open: 21.** Among them is the other P1, AN-02, whose fix is ruled but not built.

N4-WORKLIST.md tracks each by its N4 id.

## 5 · Round 2 · AW2 at `ed8e6837` (13/20)

Session D ran a fresh audit, AW2, at `ed8e6837`, the web ship candidate, which production serves as `272c2da1`.
- **Where each measurement was taken:** the candidate's four changes (`5df6d4cc` the course row, `7adee204` the desk rail, PAR-01, PAR-03) were measured in-process at `ed8e6837`, and everything else on the pinned `fd27ace4` server. Only `index.html` differs between the two.
- **Galleries:** `root/harness-fd27ace4/` (1,126 captures) and `root/harness-ed8e6837/` (356) (COVERAGE.md §3).
- **Not measured:** PAR-01 and PAR-03 cannot be reached in the fixture world, so root's in-page probe is their only evidence.
- AW2 opened none of AW's scored outputs.

| # | Dimension | AW | AW2 | AW2's key finding |
|---|---|:-:|:-:|---|
| 1 | Accessibility | 2 | **3** | Colour and focus hold everywhere: 0 of 9,753 text nodes are below AA in either theme, and all 14 full-screen takeovers make the shell inert. But the Handicap index field has no accessible name. |
| 2 | Performance | 2 | **2** | A signed-in cold open of Home jumps (CLS 0.43–0.80 at 375): an interim season card paints and vanishes, and 14 Home containers are rewritten 83 times. The whole 2.26 MB document is parsed on every visit. |
| 3 | Responsive design | 3 | **3** | No page overflows sideways at 8 widths or in 1,482 captures, and the desk is its own composition (D234). But the golfer page reads "SEP 202 ROUNDS". |
| 4 | Theming | 3 | **3** | Tokens carry 96.6% of colour declarations, dark-first holds, and a live theme switch leaves 0 stale values. 49 literal-only colour declarations remain. |
| 5 | Implementation integrity | 2 | **2** | Ember, gold, `act` and the Door's labels hold. Mono labels and sentences, serif money, typed arrows and dingbats, pills and card spines are not carried through, and L-34 breaks on the desk Season page and Home's lead. |
| | **Total** | **12/20** | **13/20** | "Acceptable (10–13)". The gate is 18. |

**Integrity: FAIL.** AW2 finds four ratified rules not carried through on the web:
- UI_SYSTEM §1.4: mono is never a label, button or sentence, and a number is never serif (AW2-06, AW2-07);
- §5.2: typed arrows and dingbats are deleted (AW2-08);
- §0.3 and §8: the card spine and the pill are deleted (AW2-13);
- L-34 / D360: one fact, one place (AW2-04, AW2-05, AW2-16).

The phone's lints LINT-12 and LINT-13 scan Swift only, so preflight's 0/0 says nothing about these rules on the web.

**What holds, measured:**
- 0 of 9,753 text nodes are below AA;
- all 14 takeovers make the shell inert;
- a live theme switch leaves nothing stale;
- no page overflows sideways from 320 to 1600;
- preflight is 0/0;
- `ed8e6837`'s desk rail scrolls, and its foot is reachable by Tab.

| AW2 id | Sev | Dimension | Finding | Where (AW2) | Status at `7b9c17e4` |
|---|---|---|---|---|---|
| AW2-01 | **P1** | performance | Home jumps and rebuilds on every signed-in cold open: CLS 0.43–0.80 at 375, and an interim season card paints and vanishes | the boot: 83 `innerHTML` writes to 14 Home containers in about 50 ms (`raw/boot.json`, `raw/perf-a.json`) | **open: Q12.** AW2's fix: hold Home until `home_dispatch` and the ME read have both answered, reserve the lead's height, render once, and never paint the fallback card when a lead is coming (CLS below 0.1 at 375 and at 4× CPU). |
| AW2-02 | **P1** | accessibility | The Handicap index field in Card & settings has no accessible name (WCAG 4.1.2, 1.3.1) | `#phIdx` | **fixed (7b9c17e4)**: labelled by its own eyebrow, and described by the sentence under it |
| AW2-03 | P2 | responsive | The golfer page reads "LAST PLAYED SEP 202 ROUNDS" | `.dtab td.rt` with no left padding | **fixed (41cf8050)** (CRITIQUE CQ2-11) |
| AW2-04 | P2 | integrity | The desk Season page prints its standings and its pot two to four times in one viewport (L-34) | the climb card, the standings table, its legend and the pot aside, at 1280 | open |
| AW2-05 | P2 | integrity | Home's lead says the clock twice: "… CLOSES IN 5 DAYS" and "The week closes in 5 days." (L-34, D360) | `#homeLead`, eyebrow and sentence | open |
| AW2-06 | P2 | integrity | Mono sets button labels, eyebrows and sentences (§1.4): every phone tab label, the back links, Season's jump chips and sentences, the receipt's math rows | `.tab`, `.backlink`, `.seasonjump button`, `#climbNote`, `#scenarioLine`, `#potMath`, `#lineSplit`, `.mathrow` | open. DX2's OB-05 names the same mono remnants. |
| AW2-07 | P2 | integrity | Numbers are set in the serif (§1.4, §1.6): the pot's $600, the standings legend, the receipt's band sentence, Home lead headlines with digits | `.heronum` on `#potAmt` and `#lineAmt`; `#standingsStory`; `.rm-say`; `.hl.cs-lead` | open |
| AW2-08 | P2 | integrity | The retired glyphs live on in web copy (§5.2): 81 code lines with typed arrows or dingbats, and LINT-12/13 scan Swift only | the season dateline's "→", "Open the Book →", "OPEN ↗", back links' "←", "⚑", "◆" | open |
| AW2-09 | P2 | accessibility | A course row nests a focusable `<summary>` inside `role=button`, and the row's card disclosure drops out of the accessibility tree | `.cs-krow` holding `details.cs-cardleaf` (at `ed8e6837`, after 5df6d4cc) | open |
| AW2-10 | P2 | accessibility | The card gate's "What do you usually shoot?" radiogroup has no accessible name (WCAG 1.3.1), nor does "Ball marker" | `#pfBands` without `aria-labelledby` | open |
| AW2-11 | P2 | accessibility | The focus ring is 2.54:1 on the receipt's leaf buttons in dark (WCAG 1.4.11) | the act ring over `.rcpt-leaf .cs-tskip` | open |
| AW2-12 | P2 | performance | Every visit parses the whole 2.26 MB document (about 778 KB of it comments) and 291 KB of supabase-js, the Door and public links included | `index.html`; 17 esm.sh modules | **open: Q12** (round 1's P3-25) |
| AW2-13 | P3 | integrity | Retired shapes still drawn: card spines (`.momrow`; `.sysrow` and `.hmoment` in source), 14 pill rules, the glass header and tab bar | `.momrow`; `.sysrow`; `.seasonjump button` at 999px; `.hdr` and `.tabbar` blur | open. `.momrow`'s rail is Q36; DX2's TP-09. |
| AW2-14 | P3 | integrity | Ember and act exceptions: ember on "Score it live", ember as a side colour in the public settlement strip, bg2 primaries on two public pages, a gold "me" spark | `#optLive`; `.sv-strip`; the public round's and dead link's calls to action; the desk climb's spark | open |
| AW2-15 | P3 | integrity | Tracked caps on phrases read aloud (§1.3) | "SIDE GAMES · TRACKED LIVE, SETTLED BETWEEN FRIENDS", "HOW OFTEN WILL MOST OF YOU PLAY?", "VS PLAYING HCP · PLUS IS BETTER", the recent-round lines | open (DX2's TP-11) |
| AW2-16 | P3 | integrity | One fact twice: "AVERY FIXTURE 1 UP" twice in the live match's viewport; the desk You prints the same five grosses in Form and in Recent rounds | `#sbHero` and `#matchStatus`; the desk You | open |
| AW2-17 | P3 | theming | Theming leftovers: 49 literal-only colour declarations (a pre-token gold among them), dead D76 CSS, and no `theme-color` on the static pages | `rgba(233,190,98,…)`; `.svfc`, `.btn.gold`; the heads of get, support and legal | open |
| AW2-18 | P3 | accessibility | Heading levels skip, decorative SVGs are exposed as unnamed images, and focus drops to `<body>` after a Door send failure | Home h1→h4, Play h1→h4, You h1→h3, wizard h1→h4 | open (DX2's TP-17; round 1's P3-23) |
| AW2-19 | P3 | responsive | Targets under the 44px floor, all above WCAG 2.5.8's 24px | the Season board's report flag, "The season's story →", "OPEN ↗", the desk rail's league link, the course lead's half-stars | open (round 1's P2-10 residual) |
| AW2-20 | P3 | responsive | Long measures: from 640 to 959px the phone column stretches edge to edge, and desk Season prose runs about 90 characters a line | the phone shape at tablet widths; `#endgameFoot`, `.rulesec p` | open (DX2's TP-20) |
| AW2-21 | P3 | responsive | Content rests under sticky chrome: live scoring's context line and "Change setup", the card gate's Save over the marker note, the 1280×800 rail's foot with no cue | live scoring at rest; `#pfSave`; `aside.side` | open. The card gate's Save is the delta's one open regression (PANEL.md). |
| AW2-22 | P3 | responsive | A credential label still truncates on the golfer page ("BEST · …") | `.cfig small` | open |
| AW2-23 | P3 | performance | Performance polish: width transitions, `will-change` left on at rest, three backdrop blurs | the star sweep and bars; `.ob-pcard`, `.ob-lbrow`; `.hdr`, `.tabbar`, `.bf-hdr` | open |

**Tally at `7b9c17e4`:** 23 findings (0 P0, 2 P1, 10 P2, 11 P3).
- **fixed: 2.** AW2-02 and AW2-03. Both came after `ed8e6837`, so they are verification pending until round 3.
- **open: 21.** Two of them, AW2-01 (the P1) and AW2-12, are Q12 in OWNER-QUESTIONS.
