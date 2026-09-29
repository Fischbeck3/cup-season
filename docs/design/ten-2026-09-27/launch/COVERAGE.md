# Coverage · what the round-1 evidence captured, and what it did not

| | |
|---|---|
| **Measured at** | web **`9d84c483`**: 886 captures taken at `02636007`, whose web client renders those families byte-identically, and 256 taken at `9d84c483`. Native **`4112a3f0`**, the same native tree as `cf401dee` and Owner TestFlight 1.0.0 (1180). |
| **Status read at** | **`b8a61266`**: `git log cf401dee..b8a61266` covers root's fixes, N2's merge at `de3eaf35`, and the merges of lanes W3 (`e8108e59`), W2 (`f46086b4`) and W4 (`b8a61266`); `9d84c483..cf401dee` adds the three client fixes that shipped between them |
| **Date** | 2026-09-28 |
| **Assessors** | No assessor scored coverage. The captures came from WX's web harness (`tests/ten-capture.mjs`) and FX's native capture tool (`tools/native-synthetic-captures.py`). The gaps in §1.5 are quoted from the assessors' own scope notes: judges **category**, **craft** and **owner**, critiques **A** and **B**, audit **AW** and detector **DX**. |
| **Raw evidence (outside git)** | `~/cup-season-claude-ten-gallery/root/harness-9d84c483/manifest.json` (and its PNGs, `--first.png` crops, `artifacts/`, `merge.log`) · `~/cup-season-claude-ten-gallery/native-4112/manifest.json`, `failed.json`, `logs/summary.txt`, `logs/matrix.log`, `flows/README.md` · the assessors' scope fields in `~/cup-season-claude-ten-gallery/evidence/{panel,critique-A,critique-B}/` |

Written by session C (docs), which re-captured nothing and changed no product code. `~/cup-season-claude-ten-gallery/` is the local evidence gallery, and the evidence stays outside git.

**The rules this file keeps.**
- A state counts as captured only when a capture renders the state it is named for. Two states with byte-identical captures prove one state, not two (§1.4, §2.4).
- An uncaptured state stays **open**, never n/a. The only n/a is a surface that does not exist on that client: `families.json` gives public-round no native surface and widgets no web surface.
- Screenshots cannot certify a keyboard, VoiceOver, motion, haptics, outdoor light, real email or a real device. Those are device-or-human evidence (HUMAN.md D1–D13, G1–G4), and none of them has been run.

## Summary

| Half | Assessed SHA | Captures | States | Matrix | Open |
|---|---|---:|---:|---|---|
| Web | `9d84c483` | 1,142, plus 482 first-screen crops and 24 exported share artifacts | 141 in 22 families | 375, 402, 1280, 1600 × dark, light, plus a 375×380 keyboard proxy for 16 states | 320 CSS, `auto` theme, tablet widths; about 150 named states (§1.5); 4 captures that prove less than their names (§1.4) |
| Native | `4112a3f0` | 752 (all four passes) plus 14 flow screenshots | 77 family states (94 capture names) in 18 families | iPhone 17 Pro (402pt) and SE 3 (375pt) × large and AX3 × dark and light | the Door, wizard steps 2–3 and live scoring are not captured; `story` failed on all 8 cells; 40 captures with unanswered requests, whose verdict is session A's; 4 byte-identical pairs (§2.4) |

---

## 1 · Web

### 1.1 Where the gallery came from
- **Manifest:** `root/harness-9d84c483/manifest.json` merges four runs:
  1. 1,078 captures at `02636007` (harness at `02636007`);
  2. 256 captures at `9d84c483` (harness at `d15b5f18`): every row of `play`, `receipt`, `record`, `you`, `golfers` and `book`;
  3. and 4. 16 captures each at `7b822772` and at `9d84c483` (harness at `7b822772`). These re-took `book/upcoming` and `book/squads` after a25882fc taught the harness the Book's new date head. In `merge.log`, run 2's 16 FAIL lines are that stale expectation, not a product failure.
- **Final composition:** 886 rows at `02636007` and 256 at `9d84c483`. Between the two SHAs, `index.html` changes only live-scoring CSS/JS and round/Book date formatting, all inside the six re-captured families (the brief, and AW's `git diff 02636007 9d84c483 -- index.html`).
- **Counts:** 0 route failures, 0 page errors, 0 fixture gaps, 0 request storms, 0 `overflowX`. Every `*.supabase.co` request was answered in-process from `tests/fixtures/ten/` or aborted; esm.sh and Google Fonts were replayed offline with 0 misses; service workers were blocked.
- **Served files:** `index.html` sha256 `4b3917cd…` on the `02636007` rows and `2ac5c63a…` on the `9d84c483` rows. The static pages carry no index hash.

### 1.2 Families × states × widths × themes

Every family below is captured at every listed width in both themes. The 375×380 proxy is taken only for the states listed in its column.

| Family | States | Captures | Captured at | Widths | 375×380 proxy | Themes |
|---|---|---:|---|---|---|---|
| `door` | `initial`, `email`, `sending`, `code-entry`, `code-error`, `send-failed`, `league-code` | 68 | `02636007` | 375, 402, 1280, 1600 | every state but `initial` | dark + light |
| `onboarding` | `card-gate` | 10 | `02636007` | 375, 402, 1280, 1600 | `card-gate` | dark + light |
| `home` | `member`, `member-populated`, `pro`, `member-invited`, `inbox`, `league-less-brand_new`, `league-less-rounds_no_buddies`; the 15 `hatch-*` states (brand_new, rounds_no_buddies, buddies_no_competition, event_ahead, event_live, between_seasons, ceremony_night, inactive, invited, callout_pending, preseason, round_morning, round_evening, after_golf, after_golf_wire); the 10 `dispatch-*` states (preseason, event_live, invited, round_morning, round_evening, after_golf, after_golf_wire, ceremony_night, between_seasons, inactive) | 256 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `golfers` | `list`, `list-empty`, `person`, `h2h`, `board` | 40 | `9d84c483` | 375, 402, 1280, 1600 | — | dark + light |
| `you` | `empty`, `one-round`, `populated`, `error` | 32 | `9d84c483` | 375, 402, 1280, 1600 | — | dark + light |
| `record` | `populated`, `photos-none`, `photo-broken`, `photo-credited`, `photo-withdrawn` | 40 | `9d84c483` | 375, 402, 1280, 1600 | — | dark + light |
| `receipt` | `round`, `points` | 16 | `9d84c483` | 375, 402, 1280, 1600 | — | dark + light |
| `composer` | `first-round`, `member`, `filled`, `post-failed` | 36 | `02636007` | 375, 402, 1280, 1600 | `first-round`, `member` | dark + light |
| `share` | `recap-no-photo`, `recap-photo`, `recap-long-course` (+ 24 exported artifacts) | 24 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `season` | `narrative`, `leaderboard`, `story`, `pot`, `pot-pro`, `rules` | 48 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `compete` | `empty`, `populated` | 16 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `book` | `upcoming`, `squads`, `scoreboard-upcoming`, `race`, `tie`, `finished`, `error`, `cell-receipt` | 64 | `9d84c483` | 375, 402, 1280, 1600 | — | dark + light |
| `events` | `live`, `finished`, `unavailable`, `failed-read` | 32 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `public-round` | `public`, `photo`, `long-name-nine`, `escaped-name`, `no-band`, `broken-photo`, `dead-link`, `settlement`, `recap` | 72 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `links` | `claim-valid`, `claim-scan-partner`, `claim-used`, `claim-unfinished`, `claim-not-started`, `claim-dead`, `claim-signed-in-ask`, `join-valid`, `join-unavailable`, `join-covenant`, `join-covenant-free`, `join-already-in`, `invite-banner`, `invite-terms`, `person-landing`, `person-landing-new`, `person-signed-in-ask` | 152 | `02636007` | 375, 402, 1280, 1600 | the six `claim-*` signed-out states, `join-valid`, `join-unavailable` | dark + light |
| `schedule` | `populated`, `empty`, `plan-sheet`, `plan-landing` | 32 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `wizard` | `step-1-league`, `step-2-rules`, `step-2-help-open`, `step-2-dials`, `step-3-review` | 40 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `courses` | `books`, `card-18`, `card-9-no-yardage`, `card-long-tee` | 32 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `settings` | `card`, `settings`, `delete-confirm` | 24 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `static` | `get`, `support`, `legal` | 24 | `02636007` | 375, 402, 1280, 1600 | — | dark + light |
| `desk` | `home`, `season`, `compete`, `golfers`, `you` | 20 | `02636007` | 1280, 1600 only | — | dark + light |
| `play` | `setup-empty`, `setup-filled`, `scoring`, `sync-pending`, `match-scoring`, `skins-scoring`, `finish-confirm`, `finish` | 64 | `9d84c483` | 375, 402, 1280, 1600 | — | dark + light |
| **total** | **141 states** | **1,142** | 886 · `02636007`, 256 · `9d84c483` | | 16 states | |

Viewports: 375×667, 402×874, 1280×1000 and 1600×1000 at DSF 1, and 375×380 for the proxy. Captures are full-page except the proxy; a page taller than its viewport also has a `--first.png` first-screen crop (482 of them), which is where fixed chrome is judged.

### 1.3 Which rows were captured at which SHA
- **At `9d84c483` (32 states, 256 captures):** `play` (8), `book` (8), `record` (5), `golfers` (5), `you` (4), `receipt` (2).
- **At `02636007` (109 states, 886 captures):** everything else. That is `door`, `onboarding`, `home`, `composer`, `share`, `season`, `compete`, `events`, `public-round`, `links`, `schedule`, `wizard`, `courses`, `settings`, `static` and `desk`.
- **Nothing is captured at a SHA after `9d84c483`.** Every fix listed in CRITIQUE.md, AUDIT.md and DETECTOR.md is un-captured until round 2 (session D) builds `harness-<sha>` on the final SHA, after W1, W5 and W6 merge. That covers root's 38471687, 735a63ec, 69f40d1f, dd01225d, b263fd74, 65db32a0, d15b5f18 and d7a5a07d, and the lane merges e8108e59, f46086b4 and b8a61266. The lanes' own harness runs (W2 150, W3 316 and W4 340 captures, per their merge messages) are their verification, not the gallery.

### 1.4 Captures that prove less than their names
Found by grouping the manifest's `sha256` across states. A byte-identical pair proves one rendering.

| States | Identical cells | What it means | Status |
|---|---|---|---|
| `home/pro` = `home/member` | 4 of 8: all desk cells (1280, 1600 × both themes); the phone cells differ | The Pro's desk Home is the member's Home, pixel for pixel. | decision (OWNER-QUESTIONS Q4) |
| `home/member-populated` = `home/member` | 8 of 8 | Two harness states render one page; `member-populated` adds no coverage. | open (harness) |
| `record/populated`, `record/photos-none`, `record/photo-broken` = `you/populated` (and `courses/books`, `desk/you`) | 8 of 8 | The record lives on You (`view-stats`), and the populated world shows no photograph in the first place. The two photo states pass their checks ("no photograph", "no broken image") without ever drawing a fallback. The owner judge: "the photo states are not captured". | open (harness: a record with a photograph that then fails) |
| `share/recap-no-photo` = `share/recap-photo` | 8 of 8 at 02636007 | A product defect, not a harness gap: the no-photo ceremony offered "Include round photo" (critique B P1 · owner P1). | fixed (38471687), un-captured |
| `links/claim-used` = `door/initial` | 6 of 8 (the 1280 cells differ) | An already-claimed card landed on the plain Door with no sentence. The harness expected that silence, and the judges split: category "by design", craft "a decision", owner a defect (R 6). | fixed (b8a61266): the kept scorecard now says so, and the harness pins the line (5d536f41). Recorded as Q13 in OWNER-QUESTIONS. |
| `record/photo-withdrawn` = `public-round/dead-link` | 8 of 8 | By design: the harness defines the withdrawn photo's public link as dead ("This link is dead"). The withdrawn state on the golfer's own record is not captured. | open (harness) |
| `desk/golfers` = `golfers/list` | 4 of 4 | Expected: the desk state is the same page at desk width. | — |

### 1.5 Gaps (all open)

**Widths, themes and devices not in the gallery**
- **320 CSS.** It is not in the gallery. Some page suites run 320, and AW probed 320 for overflow only. LEDGER X24 names 320 a named exception, because it is below every supported iPhone (375pt SE is the floor).
- **The `auto` theme.** It is not captured. It resolves to dark or light (AW verified the resolution in code, not in a capture).
- **640, 768 and 1024.** These are not captured. AW's reflow probe found 0 overflow at 640, 768 and 1024, and the desk shape starts at 1024.
- **Not certifiable from any capture, on every row:** keyboard order and focus rings, screen-reader output, motion and Reduce Motion, haptics, outdoor glare, the iOS keypad (375×380 is a CSS proxy), real OTP email, the OS share sheet and link previews. These are HUMAN.md's.

**States not captured, per row** (from the assessors' scope notes, deduplicated)

| Row | Not captured |
|---|---|
| door | Verify in progress; the signed-in handoff; the 20s spam hint; resend re-enabled; a wrong league code; a closed-account failure; the `?join` invitation Door; `initial` at 375×380 (B) |
| home | loading or skeleton; a failed, stale or offline feed; applause given; accept / decline / Later / Didn't-play results; Run it back; the hero; the X18 install nudge; a Pro-specific Home (§1.4); AX sizes (B); pull-to-refresh and live updates (category) |
| post (composer) | busy, success and field-validation states; a nine-hole post; scan-the-scorecard; photo attach; a network failure (only a server refusal is captured) (A, B, craft, category) |
| share | the photo switch's off state; the D380 Share with its public page and preview; a cancelled or failed share; Turn off this link; a withdrawn or replaced photo; cards for the other three bands; a nine-hole round; a round without a band; the OS share sheet (A, B, craft, owner) |
| public-round | loading; a failed read; the person and plan branches; a recap with a champion; strip-less and bragging-rights settlements; other games; link previews and og images; the 375 below-window action (B, category, owner) |
| claim-invite | every post-sign-in continuation; the Details/Decline sheet; Not now / × / Back; event and season-two invitations; a rate-limited `league_by_code`; the covenant's Join write (A, B, category) |
| identity | saving the card (success, failure); photo upload; a handle-availability failure; the index field, Your seasons and Save card below the sheet's first screen; the gate's lower half at 375; AX sizes (A, B, category) |
| golfers | search results; a stranger's card; accept/decline results; applause given; the comment thread; the Play-with sheet; a pride bet; any failed read (B, craft, category) |
| history | the receipt's explanation leaf, per-league verdicts, Share, Turn off this link and the conversation (receipt captures stop at the grid); two-league receipts; the counting-rounds door; the photo-removal flow; the photo states (§1.4) (B, owner) |
| season | loading, failure and stale reads; Leave/Cancel confirmations; the Pro's payer toggle feedback and undo; the scoring sheet; a solo season; a Cup Final season page; a complete season's ceremony (A, B, craft) |
| competition | Book loading; the Pro's Book; Totals mode; adjustment-only and bye receipts; Golfers filtered to a squad; Compete with a Major; Compete loading/failed; the live Scoreboard updating (B, category) |
| events | a Major; a callout room; an event before it starts; setup, forming and pairing; organiser controls; Run it back's confirm and result; the taunt opt-in once set; a tie at the clinch (all five assessors) |
| schedule | the plan composer; the day sheet; RSVP after tapping; Tee it up (D354b); past and dead plan landings; failures; the October view (A, B) |
| wizard | a pay note entered; lock success and `#lockErr`; D384 short-season coercion; solo; the busy-friends suggestion; the joiner's covenant; the payout help; empty-name validation; the draw reveal (A, B, craft) |
| courses | the D391 circle course page; `course_home`; catalogue search; the rating sheet; a tee change; `noCard`; offline; a real course photo (A, B, owner, category) |
| settings | toggle results; the push prompt; sign-out; the deletion result; opened guides; error toasts (A, B) |
| play | Wolf and Sunningdale in play; the guest pencil; the D368 birdie moment and tally; D367 "Saved on this phone" / "Not posted"; the CARD view; past-hole correction; Change setup mid-round; Scrap armed; a partial-card finish; a finish with a failed post; offline (A, B, craft, owner) |
| rules | the scoring sheet; solo, points-table and Unlimited leagues' rules; pre-tee and Final rules; the Pro's view; a failed rules read; the "How scoring & handicaps work" guide (A, B) |
| get · support · legal | the configured iPhone-link state; hover/focus; anchor landings; `auto` theme; 200% zoom (B) |
| desk | desk loading states; a solo season's LAST FIVE column; hover; window resizing between breakpoints; print (A, B, category) |

---

## 2 · Native

### 2.1 Where the matrix came from
- **Source:** `native-4112/manifest.json` holds 752 rows. Every row is from `4112a3f0` with a clean tree (`sourceDirty: false`), in the DEBUG synthetic world (`-cs_dev_synthetic`, invented identities at `@example.invalid`).
- **Four passes of 188 captures each**, as `logs/matrix.log` records:

  | Pass | Started | xcodebuild | Merged total |
  |---|---|---|---|
  | 17 Pro, large | 17:37 | exit 65 | 188 rows, 12 flagged |
  | 17 Pro, AX3 | 18:07 | exit 65 | 376 rows, 24 flagged |
  | SE 3, large | 18:37 | exit 65 | 564 rows, 36 flagged |
  | SE 3, AX3 | 19:12 | exit 65 | 752 rows, 48 flagged |

  The matrix finished at 19:41. Exit 65 is the UI-test runner's status: its capture steps include the flagged routes.
- **`logs/summary.txt`:** "752 captures · 8 root FAILED · 40 with unanswered requests". `failed.json` holds those 48 rows (§2.3).
- **`flows/`:** 14 screenshots from `SyntheticRouteTests`, all 17 Pro, large, dark. Two carry caveats in `flows/README.md`:
  - `flow__live-recap--at-72e76e3a.png` is from FX's run at `72e76e3a`, not `4112a3f0`;
  - `flow__album-failed.png` shows photographs, so it is not evidence of the failed state (LEDGER X35).

### 2.2 Row × phone × text size × theme

A ✓ means both themes are captured for that pass. Every captured state below has all eight cells, except where §2.3 and §2.4 say otherwise.

| Native row | Captured states (capture names) | 17 Pro L | 17 Pro AX3 | SE3 L | SE3 AX3 | Open |
|---|---|:-:|:-:|:-:|:-:|---|
| native/door | — | — | — | — | — | **Not captured.** The signed-out Door is not in the synthetic plan. |
| native/home | populated, empty, loading, offline, failed-read, forced-update, long-names, populated-no-season; plus the three looks on Home | ✓ | ✓ | ✓ | ✓ | `long-names` is byte-identical to `populated` in 5 of 8 cells (§2.4) |
| native/post | composer, cover, first-round, keyboard; flows `composer-keyboard`, `post-failed` | ✓ | ✓ | ✓ | ✓ | posting in progress; success; scan; photo; the live recap and ceremony (`families.json` says so) |
| native/share | flows `finish-ceremony`, `share-preview` only | 1 of 8 (dark) | — | — | — | 7 of 8 cells; the photo-consent, cancel and withdraw paths |
| native/public-round | no native surface (`families.json`: `native: null`) | n/a | n/a | n/a | n/a | — |
| native/claim-invite | claim-confirm, claim-pencil, invite-covenant, invite-door | ✓ | ✓ | ✓ | ✓ | `invite-covenant` (capture `invite-signedin`) has unanswered requests on all 8 cells (§2.3) |
| native/identity | You populated, empty and failed-read; person, own page, other golfer's tour card, tour card, bag; onboarding card-gate and crew-step; the three looks on You | ✓ | ✓ | ✓ | ✓ | `you-failed` is byte-identical to `you-populated` in 4 of 8 cells (§2.4) |
| native/golfers | populated (list, head-to-head), empty, keyboard (search), season-board | ✓ | ✓ | ✓ | ✓ | a stranger's card; failed read |
| native/history | record, record-empty, album, album-failed, receipt photo / no photo / broken / withdrawn | ✓ | ✓ | ✓ | ✓ | `album-failed` is byte-identical to `album` in 1 cell (SE3 large light), the X35 pattern |
| native/season | populated (pot), live-solo, live-squads, loading, failed-read, ceremony, cup-final, season-story; plus the three looks on Season | ✓ | ✓ | ✓ | ✓ | **`season-story` failed on all 8 cells** (root not found); `ceremony` has unanswered requests on all 8 |
| native/competition | scoreboard, populated (Book), squads, intent, when-fork, empty, cup-final, failed-read; the three looks on Compete; flows `book-adjustment`, `book-cell-receipts`, `book-round-receipt` | ✓ | ✓ | ✓ | ✓ | `when-fork` has unanswered requests on all 8; `cup-final` is byte-identical to the scoreboard in 6 of 8 (§2.4) |
| native/events | ryder-live, ryder-complete, major-live, picker, unavailable, failed-read | ✓ | ✓ | ✓ | ✓ | the Ryder setup; a callout room |
| native/schedule | populated, empty, planned-round, declare | ✓ | ✓ | ✓ | ✓ | RSVP results; failures |
| native/wizard | first-step only | ✓ | ✓ | ✓ | ✓ | **steps 2 and 3, the review, the lock and the draw are not captured** |
| native/courses | populated, course-home, kept, never-kept, whole-card | ✓ | ✓ | ✓ | ✓ | `whole-card` has unanswered requests on all 8 |
| native/settings | populated | ✓ | ✓ | ✓ | ✓ | sheets; delete confirm; sign-out |
| native/play | setup only; flows `live-finish-sheet`, `live-recap` (at `72e76e3a`) | ✓ (setup) | ✓ (setup) | ✓ (setup) | ✓ (setup) | **live scoring rows are not captured**: scoring, match, skins, sync-pending, finish. FX has no synthetic live round (LEDGER §4g). |
| native/rules | populated | ✓ | ✓ | ✓ | ✓ | unanswered requests on all 8 |
| native/widgets | home widgets (empty; Rivalry, Record, Next tee, Season), Live Activity (closed, missed, long) | ✓ | ✓ | ✓ | ✓ | — |

### 2.3 `failed.json`: 48 rows (six routes × two themes × four passes)
The **verdict** on each row (does it render correctly, why, and the file) belongs to session A. This table records only what the manifest says.

| Route (capture) | State | Manifest | Coverage status |
|---|---|---|---|
| `story` | season / season-story | **FAIL**, root not found ("text:The story"), 8 of 8 cells | **not captured** until session A's verdict |
| `course-wholecard` | courses / whole-card | PASS, root found, unanswered requests, 8 of 8 | captured · verdict pending (A) |
| `whenfork` | competition / when-fork | PASS, root found, unanswered requests, 8 of 8 | captured · verdict pending (A) |
| `invite-signedin` | claim-invite / invite-covenant | PASS, root found, unanswered requests, 8 of 8 | captured · verdict pending (A) |
| `rules` | rules / populated | PASS, root found, unanswered requests, 8 of 8 | captured · verdict pending (A) |
| `season-ceremony` | season / ceremony | PASS, root found, unanswered requests, 8 of 8 | captured · verdict pending (A) |

The failures world's read counters (for example `home-failed` "fails=21" and `you-failed` "fails=39") are the intended failed reads, not flags.

### 2.4 Byte-identical native captures

| States | Identical cells | Status |
|---|---|---|
| `compete-final` = `compete` (scoreboard) | 6 of 8 (17 Pro AX3, SE3 large, SE3 AX3; both themes) | The Cup Final state is proven only in the 17 Pro large cells. Open, verification pending (A). |
| `home-long` = `home-populated` | 5 of 8 (17 Pro large light, 17 Pro AX3, SE3 AX3) | Long names are proven only where the captures differ. Open, verification pending (A). |
| `you-failed` = `you-populated` | 4 of 8 (both AX3 passes) | At AX3 the failed read cannot be told from a populated You. The failure line may sit below the first screen, or the read may never have failed. Open, verification pending (A). |
| `album-failed` = `album` | 1 of 8 (SE3 large light) | The X35 pattern at `4112a3f0`. N2's `a65b6959`/`d18ac598` changed the seam so the failure lands after the route's mark; that is proven on N2's tree (3 of 3 per phone), not in this matrix. |

### 2.5 Native evidence after `4112a3f0` (outside the matrix)
- **`launch/n1/`** in git: 12 synthetic before/after shots and `contrast-f05.json`, from N1's lane.
- **`launch/n2/`** in git: 31 synthetic before/after shots with a SHA-256 `MANIFEST.json`. They cover F08, F10, F11, F12, F13, F16, R02, S8, S9, X35, the Form row and the recap, on N2's tree.
- **Neither is the merged native tree.** N2 tested only its own tree. Phase 0 of lane N4 (session E) builds and tests `de3eaf35` before any archive (LEDGER §4g). Until that run reports, every native row stays measured at `4112a3f0`.

### 2.6 Native gaps (all open)
- **native/door:** the whole row.
- **native/wizard:** steps 2 and 3, the review, the lock and the draw.
- **native/play:** every live scoring row: scoring, match, skins, sync-pending and the finish. It needs a synthetic live round (FX gap, LEDGER §4g).
- **native/share:** seven of eight cells, and the consent, cancel and withdraw paths.
- **native/season:** the `story` route (§2.3).
- **native/post:** posting in progress, success, scan and photo.
- **Single-round You:** no scenario exists (FX gap, LEDGER §4g).
- **The album's refresh-failure and offline routes:** unit-tested only (LEDGER §4g).
- **Device-or-human, never from a capture:** VoiceOver order and speech, haptics, Live Activity on a Lock Screen, outdoor light, finishing a live round on a device (HUMAN.md D12), and the album retry on a device (D13).
