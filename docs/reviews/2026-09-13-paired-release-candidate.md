# Paired release candidate · web/iOS parity matrix · Claude handoff

Date 2026-09-13. **Acknowledging `docs/planning/2026-09-13-paired-release-checkpoint.md`
(`972af72`)** and returning its matrix with each row's actual status.

Branch **`claude/mobile-web-integration`**, worktree `~/cup-season-mobile-web-integration`,
built on the reviewed candidate `8f85dac`. `claude/mobile-safari-experience` and
`claude/d339-web-half` are untouched; Codex's review branches were read, never written.

## The candidate and the deployed version

| | |
|---|---|
| **Candidate** | **`227189b`**, the tip of this branch. **The application source is `0251e86`** — `227189b` is this document, so `git diff 0251e86..227189b -- index.html tools apps` is empty. |
| **Preview** | **https://deploy-preview-3--cupseason.netlify.app** — PR #3, the same preview. **PR #1 and PR #2 are retired as review links**; #3 is the only integrated one. |
| Live web | `https://cupseason.app` unchanged at `963d0e6`. Nothing promoted, nothing written to the backend. |
| Native | build 857 archived from `963d0e6`; export still blocked on distribution signing. **No native source change in this branch** beyond the LINT-14 test correction already in the baseline. |
| Database / Edge | none owed; none touched. |

Commits since the reviewed candidate:

| Commit | Work |
|---|---|
| `4b59b37` | WA1, WA2 (=F2) |
| `bd2bc3b` | WA3, F1 |
| `da23d77` | F3 |
| `67a831d` | WA4, WA6 |
| `cb5d5be` | MW-05 |
| `f79140b` | regression corrections |
| `3c335fb` | **MW-04, MW-06** |
| `74b7efc` | **D339 I-2** |
| `cfb44b5` | **D339 I-3** |
| `0163979` | **D339 I-4** (candidate family; nothing installed) |
| `0251e86` | WA6 correction — my own over-reach, reverted |
| `227189b` | this document |

---

## The parity matrix

**built / verified / delivered**, per the packet. "Verified" means a regression
drives the rendered control and asserts the destination; native rows cite the
file or the test that carries the evidence.

| Area | Web | iOS | Paired status |
|---|---|---|---|
| **Welcome and masthead** | built + verified · fescue/topo welcome, compact signature, narrow masthead; **F3 fixed** — the statement is `rem` so enlargement reaches it and breaks rather than clipping inside the fixed overlay. `brand-door-browser.js` at 320/390/1440/390×560, dark+light, both entry controls at 44 under 200% text | reference composition unchanged (`DoorView`); Codex's run passed `AfterGolfComposerTapTests` on the baseline | **paired.** Residual: at 200% the web statement breaks mid-word (`ANYWHE / RE.`) — a visual call, named below |
| **Home hierarchy** | built + verified · one lead, compact strip, recent golf, **F1 fixed** — the scheduled round appears exactly once, owned by whatever prints it. `home-hierarchy-browser.js` counts it after the whole render at 320/390/1440 and across the 960 boundary | no counterpart defect: `MeStripCopy.Strip.suppress` is `Set(slots.map(\.fact))` — derived from what the strip renders. The phone has one strip; the web bug came from my compact/full split and the fix adopts the phone's rule | **paired** |
| **Home receipt and plan doors** | built + verified · **WA1 fixed** — `csOpenPostedRound` resolves cached and uncached posted ids through `round_card`, with a loading state and an honest error; scheduled doors still read `round_detail`. `home-receipt-browser.js` | already correct: `HomeView` `.receipt(id) → presenter.receipt`, `.plan(id) → presenter.scheduledRound` (`HomeView.swift:530-531`); Codex's `AcceptedRoundReviewTests/testReplayedAcceptedCompletionOpensReceipt` passed | **paired** |
| **Compete and season navigation** | built + verified · **WA2 fixed** — `csOpenSeason` loads, confirms the context changed, then opens the room; failed, thrown and non-membership cases stay put and say why. Both Home and Compete share it | already correct: `MainTabView.openCompetition` sets `preferredLeague`, resets the path and pushes `.season(id, pane:)` (`MainTabView.swift:932`); Codex's `CompeteGameplayReviewTests/testRealCompeteSeasonAndCreationDoors` passed | **paired** |
| **Season / standings / rules** | built + verified · **MW-04** — a rail of the season's own rooms on phones (the desk has the sidebar list), built only from panes that exist and wired to the existing `setRoomSeg`; the table precedes the climb below 960. **WA4** — a history row with a round opens the posted receipt; bumped/counting wording unchanged. `season-setup-browser.js`, `home-receipt-browser.js` | native season rooms unchanged; no counterpart defect found for either | **paired** |
| **Posting and after-golf** | built + verified · **MW-05** — `csCountingNote()` reads the league's own `CS.settings`; four truthful shapes (solo / squads / Unlimited / no season). Score → course/tee/date → action on phones; optional media quiet, and an attached photo takes its frame back. Date/draft/retry protections unchanged (`after-golf-repairs`, `release-posting` green) | **NATIVE DEFECT — the same sentence, unrepaired.** `PostRoundScreen.swift:545` appends *"each month count toward your squad …"* in **every** league, and falls back to the word *"few"* with no cap. This is MW-05's phone half | **web ahead.** Named for Codex's workspace |
| **League setup** | built + verified · **MW-06** — each wizard step is named (`Step 2 of 3 · The rules`); each preset's lead is painted from `PRESETS` and the same `CAP_DB` ladder the picker writes, so card and dial cannot drift. Suggestion still opt-in, every dial still editable, no default or creation-timing change | **NATIVE DEFECT — the same mood copy.** The Kit's wizard dials still carry *"The default. Honest scores, light guardrails."* and *"Tight. Vouched where you can, and the screws in."*, pinned by `WizardTests.swift:30-32, 59, 61` | **web ahead.** Named for Codex |
| **You / golfer record** | built + verified · **WA3** — three states, not two: em dash before the read lands or after it fails, the number when it arrives, zero only for a real empty history; the refresh no longer waits on a building index. `you-credential-browser.js` | **lesser instance, worth a look.** `YouScreen.swift:240,296` ends `… ?? p.rounds_count ?? 0` — the same terminal zero, but with a server-supplied count in front of it, and `noRounds` (`:102`) correctly gates on `model.loaded`. Not observed as a live false zero | **paired in effect**; native hardening suggested, not required |
| **Golfers / plans / invitations / events** | unchanged this pass; entry paths verified present by the existing suites (`app-tests`, `league-setup-browser`) | unchanged | **unchanged both sides.** No concrete missing capability found; not independently re-walked this pass |
| **Round receipt explanation** | built + verified · **WA6** — `(gross − rating) × 113 ⁄ slope` grouped as computed; the head verdict says one thing once and turns to the third person as a whole sentence. Server figures and the league lens untouched | **NATIVE DEFECT.** `ReceiptSeed.swift:199` prints the same ungrouped `\(gross) − \(rt) × 113 ⁄ \(slope)` | **web ahead.** Named for Codex |
| **Shared artwork** | built + verified · **D339 I-2** — one `csArtifactSignature` on the recap, round, settlement and Major artifacts: the generated pennant as `Path2D`, CUP SEASON, the brand line from `CS_BRAND`, the address. `artifact-signature-browser.js` measures the mark's own ink and requires the four bands to agree within a third | `CSArtifactFrame` / `CSArtifactFooter` already do this; the web now mirrors them | **paired** |
| **Interior branding** | built + verified · **D339 I-3** — the accepted terrain behind the Compete, season and head-to-head heads at a08/a16, behind the type, inert, never near a table. `interior-brand-browser.js` asserts the paths are byte-identical to the door's | `CSTopoField` on the native heads, unchanged | **paired** |
| **Icons / install / link preview** | **prepared, not installed** · **D339 I-4** — `tools/build-beta-mark.sh` now emits `brand/candidates/testflight-pennant/generated/web/`: icon-192, icon-512, icon-512-maskable, apple-touch-icon, favicon-32, from the same source and `draw()` as the iOS set. Nothing references them; the served favicon/PWA/apple-touch/OG family is still the Tracer | the beta pennant icon family exists | **deferred by design.** See "what the owner will see" below |
| **Platform integrations** | no web imitation added | widgets, Live Activities, system share unchanged | **explicit difference list below** |

---

## Deferred rows: what the owner will see, and whether it blocks

| Row | What the owner sees today | Blocks the paired release? |
|---|---|---|
| **Icons / install / link preview (I-4)** | The phone's icon is the pennant; installing the web app or sharing a link still shows **the Tracer**. The two families sit side by side for review: `brand/candidates/testflight-pennant/generated/web/` versus the iOS asset set | **No** — but it is the most visible remaining difference, and it is one commit once two things are ruled: the production mark, and D339 **open 2** (the tile draws contours behind the mark while `brand/README.md` calls for a solid field — visible in `icon-512.png`). The OG image is still to be composed: it is a 1200×630 composition, not a square tile |
| **F3 at 200% text** | The welcome statement breaks mid-word rather than shrinking | **No.** Nothing is lost and the controls stay usable. Enlargement fidelity versus shrink-to-fit is a visual call; shrink-to-fit would mean the reader's text setting stops reaching that line |
| **Platform integrations** | Widgets, Live Activities and the system share sheet are the phone's; the web shares through its own artifacts and links | **No.** The packet excludes web imitations |

---

## Native defects for Codex's workspace

I do not edit native application source; these are named with their evidence.

1. **`apps/ios/CupSeason/Post/PostRoundScreen.swift:545`** — `countingLine` appends
   *"each month count toward your squad — a better round always replaces your
   lowest, in real time."* unconditionally, and yields *"Your best few …"* when
   `membership?.settings?.counting_cap` is nil. A solo league has no squad, and
   Unlimited is a rule rather than an unknown. The web's shape is
   `csCountingNote()`; four cases, all read from the league's own settings.
2. **`apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Rounds/ReceiptSeed.swift:199`**
   — `"\(gross) − \(RoundCopy.f1(rt)) × 113 ⁄ \(slope)"`. Read as printed that
   multiplies the rating first, which is not the figure beside it.
3. **The Kit's wizard preset copy** — *"light guardrails"* and *"the screws
   in"*, pinned by `WizardTests.swift:30-32, 59, 61`. The web now paints each
   card from `PRESETS` + `CAP_DB`; the same two dials exist natively.
4. *(lesser)* **`apps/ios/CupSeason/You/YouScreen.swift:240,296`** — terminal
   `?? 0` on the round count, mitigated by `p.rounds_count` in front of it.

Two web findings recorded rather than changed: `vsShort` is declared twice in
`index.html` (the first shadowed, dead), and one earlier repair of mine
over-reached — see `0251e86`, which reverts it with the probe that disproved it.

---

## Evidence

`npm run preflight` — **PASS, 0 failures, 0 warnings.**

| Suite | 320 | 390 | 1440 |
|---|---|---|---|
| `home-receipt-browser.js` (WA1, WA4, WA6) | passed | passed | passed |
| `home-hierarchy-browser.js` (WA2, F1, MW-02) | passed | passed | passed |
| `you-credential-browser.js` (WA3) | passed | passed | passed |
| `post-hierarchy-browser.js` (MW-05) | passed | passed | passed |
| `season-setup-browser.js` (MW-04, MW-06) **new** | passed | passed | passed |
| `artifact-signature-browser.js` (I-2) **new** | — | passed | — |
| `interior-brand-browser.js` (I-3) **new** | passed | passed | passed |
| `brand-door-browser.js` (F3) | passed | passed | passed (+390×560) |
| `compete-start`, `compete-rows`, `home-function`, `after-golf-repairs`, `release-posting`, `league-setup`, `app-tests` | — | all passed | — |

**Every repair fails on the reviewed candidate `8f85dac`**, served from its own
`index.html`: *"the lead's receipt never opened"* · *"the other league's season
door never opened the season"* · `placesTheScheduledRoundAppears: []` · *"an
unread career printed a zero: 0"* (with only the test bridge added) · *"the
statement ignored the reader's text size (still 42px)"* · *"a SOLO league is
still told its rounds count toward a squad"* · no season rail · no
`csArtifactSignature` · no `csPaintTopoHeads`.

**Captures** (local, labelled fixtures, no account data): the composer, the
standings history, the door at 200%, the Compete head with its terrain, and a
rendered recap artifact showing the new signature — under
`…/scratchpad/{wa,i3,sig}/`.

---

## Not done, said plainly

- **Actual iPhone Safari** — safe areas, keyboard, VoiceOver, Dynamic Type.
  Everything above is Chromium at the stated viewports.
- **A signed-in walk on the preview origin by me** — Codex's account walk is the
  signed-in evidence; repeating it on this candidate is the point of the audit.
- **Write paths** — no round, league, invitation, plan or profile change was
  submitted from any tree in this pass.
- **The OG image** for the candidate icon family.
- **Golfers / plans / invitations / events** were not independently re-walked.

## Handoff

Branch `claude/mobile-web-integration`. Database deploy owed: none. Edge deploy
owed: none. Client deploy owed: the reviewed candidate's publication, which is
Codex's under the release sequence. Recommended next: audit `227189b` at the PR
#3 preview, repeat the signed-in read paths, run the paired native checks on
this exact source, and take the three named native defects into your own
workspace.
