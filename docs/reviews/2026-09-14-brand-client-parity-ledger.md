# Brand and client parity ledger · living

Opened 2026-09-14 against `docs/planning/2026-09-14-brand-and-client-parity.md`.
Anchor: **`docs/brand/references/2026-09-14-owner-brand-board.jpg`**, sha256
`17ea615b30871073d82468cda9d41e15a21afedfbfc38e4e61685fccb83ec48d` — verified
byte-identical in this worktree before use. Codex's recolouring mockups are
review history and were not used.

Branch `claude/brand-client-parity`, worktree `~/cup-season-brand`, from
application **`1bc307f`** (live on cupseason.app at time of writing).

| | |
|---|---|
| **Checkpoint A candidate** | `bc22372` — superseded |
| **P0/P1 candidate** | **see the P0/P1 section below** |
| **Phone preview** | **https://deploy-preview-4--cupseason.netlify.app** — read back `v23 · bc22372` in the page **and** in `sw.js` at 08:22:33 |
| Native source | `1bc307f` + the shared `act` token generated into `Tokens.swift`. **No native UI change yet** — see the native column below |
| Live web | `1bc307f`, untouched. Nothing promoted. |
| Signing | separate, on `claude/testflight-890`; it does not gate this preview |
| Database / Edge | none owed, none touched |

Completion states used: **scoped · built · reviewed · preview-verified ·
production-verified**. A row is not closed because one client shipped.

---

## What the board actually says (read, not paraphrased)

Sampled from the image itself, so the targets are numbers rather than adjectives:

| Board element | Value read |
|---|---|
| Deep fescue ground (masthead) | `#0E1B14` — our `--bg0` is `#0F1A15`, already right |
| Cream mark / type on fescue | `#F7F4EB` — our `--ink` dark is `#F1F4EF`, already right |
| Warm paper panel | `#EFEBE0`–`#F7F3EA` — our light `--bg0` is `#F4F1E9`, already right |
| Icon tile | `#16281C` deep green, **sparse fine contours**, cream pennant |
| Palette dots | charcoal · deep green · **orange** · rust · tan — orange is one of five, not the interface |

**So the grounds were never the problem.** The gap was the *mark* (ember on
both grounds, where the board shows cream-on-fescue and dark-green-on-paper),
*orange on ordinary controls*, *contour density behind reading*, and the
*navigation band*.

---

## P0 · reconciling checkpoint A (2026-09-14, after `2e4d9c5` and `9201c08`)

The newer amendment — **D305/D313 · ember marks active competition; green
carries ordinary actions** — arrived after checkpoint A and changes two things
I had built, plus one thing I had written down wrongly. All three are corrected
rather than argued with.

| Finding | Disposition |
|---|---|
| `bc22372` painted a **decorative ember hairline** on the welcome and the receipt, and my ledger called it "the identity's hairline" | **corrected.** A welcome is the most ordinary surface there is, and a receipt for a finished round is not an active competition. The rule stays as composition and is now a `mut` hairline at half alpha. Not ported to native. |
| My receipt set the **gross in the editorial serif** | **corrected.** The serif is memory and honour; a gross is a competition figure, and this product sets every score, rank and column in the board face. `rm-fig` is `--board` with tabular figures. The sentence under it stays serif, because that one is a story. |
| My ledger row 2 said **native AX labels wrap** | **wrong, and mine.** `CSTabBand` sets `.lineLimit(1)` with `.minimumScaleFactor(0.55)` at accessibility sizes — it shrinks, it does not wrap. I took that from a stale comment above the code instead of the code. Row 2 is fixed below. |
| Native declared `act` but **no UI consumed it** | **done in P1 below.** |

Kept without change: the five-position band, the labelled outlined Play, the
cream/paper mark treatment, the serif *statement*, the quieter terrain, the
green ordinary controls, and the authentication flow — none of which the
amendment touches.

## P1 · shared identity and action roles, on both clients

`act` now reaches the native UI through shared sources, not local patches:

| Native consumer | Before | Now |
|---|---|---|
| `CSPrimaryStyle.fill` (every primary button) | `cs.brand` | `cs.act`; its ember budget drops to 0 |
| `CSTabBand` Play | `cs.brand` | `cs.act` — verified on the simulator, Play renders green in the band |
| `CSField` focus ring | `cs.brand` | `cs.act` |
| A lit choice's underline | `cs.brand` | `cs.act`; ember budget 0 |
| `CSTheme.livery(look:)` | replaced `brand` with the look's accent | replaces **`act`**; `brand` stays ember |
| `CSPalette.increasedContrast` | — | carries `act` through |

**One judgement call, flagged for review.** The livery used to substitute
`brand`, which at the time meant *both* ordinary actions and live competition —
one substitution doing two jobs. Those are separate roles now, so I pointed the
look at `act`: a golfer's chosen colour still reaches the thing they press,
while an active clash keeps ember, because the amendment's cross-surface rule
says a qualifying competition keeps its colour wherever it surfaces and a
personal dial should not repaint a live clash. That is my reading of "preserve
personal preference while separating ordinary action from the reserved
competition signal", and it changes existing look behaviour, so it wants an
explicit yes or no.

**Not done in P1, named rather than skipped.** `CSLook.tick` and
`CSLook.eyebrow` still fall back to `cs.brand` on homebase — routine decorative
ember on page headers. Neutralising it is a visual call across every header at
once, and the plan warns against blanket replacement, so I left it and I am
asking. My recommendation: `mut`, which is what the web's hairline became.

## The ledger

### 1 · Boot, welcome, email/code entry, join entry, branding

| | |
|---|---|
| **Native** | `DoorView` · `1bc307f`. Cream `CSBrandMark` on `bg0`, `CSTopoField(.page)`, statement in `.lead` (serif), Get started / Sign in. Already board-aligned on mark and ground. |
| **Web before** | `1bc307f`. Ember mark; statement in the **condensed** face in caps; terrain at a24/a56 running through the statement; **orange** primary button. |
| **Web now** | Cream mark (`ink`); statement in the **editorial serif**, sentence case, with a **neutral** hairline under it (it was ember in `bc22372`; the amendment reserves ember for active competition); terrain a08/a16 at 0.8 stroke; **green** primary action. Auth flow untouched — email → 8-digit code → verify, join code, resend, terms, version caption. |
| **Difference remaining** | Native's statement is `.lead` serif at 28pt; web's is 2.625rem serif — same face, different scale by platform measure. Native has no hairline under the statement. The board's "ROUNDS MAKE A GOOD LIFE." line is on neither. Native's primary entry buttons are green as of P1. |
| **Evidence** | `tests/brand-door-browser.js` at 320/390/1440/390×560, both themes, 200% text. Comparison image `compare-door.png`. |
| **Status** | web **preview-verified** · native **scoped** (hairline + parity of statement scale) |

### 2 · Header, five-position navigation, Play entry, back/dismiss

| | |
|---|---|
| **Native** | `CSTabBand` · five equal slots, every one labelled, `CSGlyph.play` outlined, selected = 26×2 rule in `ink`, Play tinted flat. This is the reference. |
| **Web before** | **Four** lanes; Play pulled out as a **filled ember disc floating above the bar** with its label suppressed (`font-size:0`); selected = a 4px ember dot. |
| **Web now** | Five equal slots in the phone's order — Home, Compete, Play, Golfers, You — Play **in** the band and **labelled**, drawing `CSGlyph.play`'s exact path, selected = 26×2 `ink` rule; Play carries `act`, flat. No disc, no glow, no ember on any slot. |
| **Difference remaining** | **Correction:** an earlier version of this row said native wraps its labels at AX3. It does not — `CSTabBand` sets `.lineLimit(1)` with `.minimumScaleFactor(0.55)`, so it shrinks, which is what the web does too. The two now agree. Desk (≥960) still uses the sidebar, by design (D222/D234). |
| **Evidence** | `tests/nav-band-browser.js` — order, labels, Play in-box, glyph path, rule size and colour, no ember, 44pt targets, routing. Fails on `1bc307f` at *"the band does not lay out five equal slots: 4"*. |
| **Status** | web **preview-verified** · native **already correct** (it is the reference) |

### 3 · Home: dispatch priority, season context, recent round, activity, plans

| | |
|---|---|
| **Native** | ranked dispatch, compact lead, wire, facts strip. |
| **Web** | same producers and ranking, unchanged by this pass; the ordinary action underline and the board link moved from ember to `act`; mark is cream. Home's hierarchy work (one lead, compact strip, next-round ownership) shipped earlier at `1bc307f`. |
| **Difference remaining** | Real photography on Home's activity is the account's own round photos on both clients; no marketing scenery was introduced. Editorial treatment of the *lead* is not yet the board's moment composition. |
| **Evidence** | `home-hierarchy-browser.js`, `home-function-browser.js`; `compare-home.png`. |
| **Status** | web **preview-verified** for the brand pass · **scoped** for editorial lead |

### 4 · Compete and season detail

| | |
|---|---|
| **Native** | Compete masthead with `CSTopoField` + tagline; season rooms. |
| **Web** | standings-bearing rows, the season room rail and the table-first order shipped at `1bc307f`; this pass turns the creation link green and keeps the head terrain at a08/a16. |
| **Difference remaining** | The board's Compete masthead sets the tagline over the topo field; web's head carries the contour but not the tagline. |
| **Evidence** | `compete-rows-browser.js`, `compete-start-browser.js`, `interior-brand-browser.js`; `compare-compete.png`. |
| **Status** | web **preview-verified** · masthead tagline **scoped** |

### 5 · Play / post

| | |
|---|---|
| **Native** | `PostRoundScreen`; Codex repaired the solo/squad counting copy at `90baa6b`. |
| **Web** | score → course/tee/date → action, format-aware counting copy, draft/retry/date protections — all at `1bc307f`. This pass changes only the primary action colour. |
| **Difference remaining** | none known on copy; the composer's brand treatment is not yet editorial. |
| **Evidence** | `post-hierarchy-browser.js`, `release-posting-browser.js`, `after-golf-repairs-browser.js`. |
| **Status** | **built** both clients · brand treatment **scoped** |

### 6 · League setup

| | |
|---|---|
| **Native** | `WizardState`; Codex repaired preset explanations at `90baa6b`. |
| **Web** | named steps and dial-derived preset copy at `1bc307f`; the selected preset tick is now `act` rather than ember. |
| **Difference remaining** | none known. |
| **Evidence** | `season-setup-browser.js`, `league-setup-browser.js`. |
| **Status** | **built** both clients · **reviewed** pending |

### 7 · Golfers, You, career/handicap, rivalry

| | |
|---|---|
| **Native** | `YouModel`; Codex hardened unknown career counts at `90baa6b`. |
| **Web** | three-state round count at `1bc307f`. Untouched by this pass. |
| **Difference remaining** | The board's rivalry card ("YOU vs GALEN · 1 UP" over photography) exists on neither client as a composed moment. |
| **Evidence** | `you-credential-browser.js`. |
| **Status** | **built** both clients · rivalry moment **scoped** |

### 8 · Round receipt, no-photo and with-photo, sharing, artifacts

| | |
|---|---|
| **Native** | `ReceiptSeed` rows; `CSArtifactFrame`/`CSArtifactFooter` sign exports. |
| **Web before** | a plain photo band, then a figures strip, then rows. |
| **Web now** | **the board's brand moment**: course and day in the metadata voice, the gross at 76px in the **tournament board face** (it was the serif in `bc22372` — corrected in P0), the verdict beneath in the serif, a neutral hairline, the mark signing the corner — over the round's photograph when there is one, and on the fescue ground with a sparse contour when there is not. Every value is the round's own; a missing fact leaves its line absent. D201 followed through — the strip and the sheet subtitle stopped repeating the gross, the course and the day. |
| **Difference remaining** | **The native receipt is not yet this composition** — the biggest open parity gap in this pass. With-photo state is verified only with a fixture URL; a real photo round is still unwalked (carried from the earlier follow-up packet). |
| **Evidence** | `home-receipt-browser.js`, `artifact-signature-browser.js`; `compare-rcpt.png`. |
| **Status** | web **preview-verified** (no-photo) · native **scoped** · with-photo **unverified both** |

### 9 · Icons, favicon, Apple touch, OG, boot, lockups

| | |
|---|---|
| **Native** | pennant app icon from `tools/build-beta-mark.sh`. |
| **Web** | candidate family generated into `brand/candidates/testflight-pennant/generated/web/`; **nothing references it** — the served favicon/PWA/apple-touch/OG are still the Tracer. |
| **Difference remaining** | the whole family, plus an OG composition (1200×630, not a square tile). The board shows the tile with **sparse fine contours**, which answers D339 open 2 in favour of contours — *restrained*, not wallpaper. The production mark decision remains the owner's. |
| **Status** | **scoped** · deliberately not promoted in this checkpoint |

### 10 · Appearance, light/dark, accessibility, keyboard/safe areas, cache

| | |
|---|---|
| **Web now** | both grounds carry the board's two mark treatments; door verified at 200% text, 320/390/1440 and a 560-tall viewport; band targets ≥44 at 320. |
| **Difference remaining** | **Physical iPhone Safari is unverified** — safe areas, keyboard, VoiceOver, Dynamic Type. Service-worker update/offline behaviour is untested; the harness bypasses caches and that proves freshness, not update behaviour. |
| **Status** | **preview-verified** in Chromium · device **open** |

### Platform-only

| Capability | Native | Web |
|---|---|---|
| Widgets, Live Activities, system share sheet | present | **no browser equivalent, and none invented** |
| Add to Home Screen / PWA install | n/a | present, but wearing the Tracer icon until row 9 closes |

---

## Bounded appearance amendment (recorded before implementation, as required)

Current canon (D269/D270, `metal` group) says ember is "LIVE, and the one
primary action". The owner's 2026-09-14 board supersedes the second half only:
**ember remains live/urgent and the identity's hairline; the ordinary primary
action becomes `act`**, a fescue-family green. `act` is a new token in
`packages/tokens/tokens.json` — one source, generated into `Tokens.swift`, so
both clients read the same value. Semantics (`pos`/`neg`) and earned gold are
untouched, and no global colour replacement was performed: the sites that moved
are listed in `bc22372`'s message.

## Next

**B · shared function gaps** — with-photo receipt on both clients, the native
receipt moment, Compete masthead tagline, the editorial lead. **C · asset
family** — row 9, behind the owner's mark ruling. Neither blocks the preview.
