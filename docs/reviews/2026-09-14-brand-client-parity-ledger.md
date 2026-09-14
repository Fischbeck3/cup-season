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
| **Checkpoint A candidate** | **`bc22372`** |
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

## The ledger

### 1 · Boot, welcome, email/code entry, join entry, branding

| | |
|---|---|
| **Native** | `DoorView` · `1bc307f`. Cream `CSBrandMark` on `bg0`, `CSTopoField(.page)`, statement in `.lead` (serif), Get started / Sign in. Already board-aligned on mark and ground. |
| **Web before** | `1bc307f`. Ember mark; statement in the **condensed** face in caps; terrain at a24/a56 running through the statement; **orange** primary button. |
| **Web now** | `bc22372`. Cream mark (`ink`); statement in the **editorial serif**, sentence case, with the board's single ember hairline under it; terrain a08/a16 at 0.8 stroke; **green** primary action. Auth flow untouched — email → 8-digit code → verify, join code, resend, terms, version caption. |
| **Difference remaining** | Native's statement is `.lead` serif at 28pt; web's is 2.625rem serif — same face, different scale by platform measure. Native has no ember hairline yet. The board's "ROUNDS MAKE A GOOD LIFE." line is on neither. |
| **Evidence** | `tests/brand-door-browser.js` at 320/390/1440/390×560, both themes, 200% text. Comparison image `compare-door.png`. |
| **Status** | web **preview-verified** · native **scoped** (hairline + parity of statement scale) |

### 2 · Header, five-position navigation, Play entry, back/dismiss

| | |
|---|---|
| **Native** | `CSTabBand` · five equal slots, every one labelled, `CSGlyph.play` outlined, selected = 26×2 rule in `ink`, Play tinted flat. This is the reference. |
| **Web before** | **Four** lanes; Play pulled out as a **filled ember disc floating above the bar** with its label suppressed (`font-size:0`); selected = a 4px ember dot. |
| **Web now** | Five equal slots in the phone's order — Home, Compete, Play, Golfers, You — Play **in** the band and **labelled**, drawing `CSGlyph.play`'s exact path, selected = 26×2 `ink` rule; Play carries `act`, flat. No disc, no glow, no ember on any slot. |
| **Difference remaining** | Native's band grows its height and wraps labels at AX3; the web's labels shrink instead. Desk (≥960) still uses the sidebar, by design (D222/D234). |
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
| **Web now** | **the board's brand moment**: course and day in the metadata voice, the gross at 76px in the editorial serif, the verdict beneath, the ember hairline, the mark signing the corner — over the round's photograph when there is one, and on the fescue ground with a sparse contour when there is not. Every value is the round's own; a missing fact leaves its line absent. D201 followed through — the strip and the sheet subtitle stopped repeating the gross, the course and the day. |
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
