# IOS-003 · iOS Design Direction

*2026-08-27 · Phase 1 artifact · status: PROPOSED (P1 — proceeding with the recommendation; the two open sub-decisions are flagged inline)*

Evidence: `docs/ios/audit/08-web-ia-design.md` (the design system as built, token by token), `packages/tokens/tokens.json`, `spec/brand-bible.md`, `spec/motion-brief.md`, D76 (Charcoal), D81/D94 (Home), D82 (four places).

The brief in one line: **keep every identity element the web earned, and rebuild the *chrome* around it in Apple's grammar.** The web's palette, type voices, ceremonies and voice are product, not polish. Its navigation, density, forms and z-index ladder are Safari survival and go.

---

## 1. What carries over unchanged (the identity contract)

These are non-negotiable. If any of them changes, it stops being Cup Season.

| Element | Rule (as enforced on web today) | On iOS |
|---|---|---|
| **Charcoal ground** | `bg0` #0C0D0F page · `bg1` surface · `bg2` raised. Dark is the default for a brand-new user (D76). Light is "same bones, dawn palette"; `auto` matches the device. | `preferredColorScheme` from a device-local setting with the same three options: **Charcoal / Light / Match device**. Not synced to the profile (web rule). |
| **Two metals, never swapped** | `brand` ember #E8622C = **LIVE** (primary action, momentum, the ⊕). `gold` champagne #D8B25A = **EARNED only** (leads, pot, trophies, the leader's hairline, the `.earned` hero spine, points only when > 0). | Same tokens, same law. The single most important design rule to encode as a lint: no gold on anything unearned. |
| **One heat axis** | `warm` (building) → `hot` (burning) → `fire` (peak) · `cool` slate (falling). "Temperature is semantic, never decorative… never red-means-bad." | Standings movement, pressure meter, skins carry chip, streaks. |
| **`pos` / `neg` are semantic only** | Performance up / money in · performance down / money owed. Never a progress bar, never a focus ring. | Same. |
| **Squad colours** | `sq0` blue · `sq1` orange · `sq2` violet · `sq3` teal — identity in standings, the climb, the settlement. | Same. |
| **Three type voices with jobs** | **Mono = the scorer's tent** (labels, eyebrows, stats, codes, inputs — 196 uses). **Serif = memory & honor** (hero numbers, standings sentence, trophies, wordmark, the 84–96pt finish gross). **Sans = now** (body, buttons). | IBM Plex Mono bundled (OFL). Serif: **Charter ships on iOS as a system face** — use it directly, no bundling. Sans: SF Pro (the token stack's `-apple-system` resolves here by design). |
| **The spine** | 3.5px left accent bar as the card grammar: ember = live, gold = earned, squad colour = squad, `pos` = live banner. | Same motif on native cards. |
| **Radii** | `r` 16 cards · `rc` 10 controls · `rs` 24 sheets. | Same three, from tokens. |
| **The roll** | `cubic-bezier(.16,.84,.36,1)` — "fast start, long soft settle, like a putt dying at the hole." Toasts roll out; "golf doesn't bounce." | The one timing curve for every transition. No spring bounces. |
| **The ceremonies** | POSTED ✓ stamp + thock · the finish screen (ball rolls into the cup under the serif gross) · split-flap rank flip · the climb re-ordering · the engraver on a fresh trophy · the month seal (48h cant) · heatPulse ("a breath, not a blink", one per screen). | These are the "storytelling standings" — they ship in Phase 3, not Phase 4. |
| **The Forge door** | Tracers draw on the heat ramp, the wordmark sears in, the survivor hands off to the mark. **Once per device**; rest frame is the logo; reduced motion rests immediately. | Launch → first-run transition. `cs_forge` → UserDefaults. |
| **Markers as identity** | 14 named glyphs (The Saguaro … The Thistle). Avatar floor — **no silhouette state exists**. Marker medallion on photos. Per-league override. | Ship the 14 paths as SwiftUI `Shape`s / `Path` from the same SVG data. VoiceOver announces the marker's name. |
| **Emoji stay emoji** | Reactions 🔥🦅⛳🧊🐍🚨 with named meanings; markers and achievements are their own systems. | Same. Accessibility labels from `RXLABEL`. |
| **The Tracer mark** | Ember on charcoal, ink on light. | App icon already derived from it. |
| **The voice** | Bands not differentials ("beat your number by 2.4"); "the Pro", "the board", "your card", "on the books"; every empty state ends in a next move; two-tap "Sure?" never `alert()`; first names leave the app. | Copy is ported verbatim wherever the screen exists. New copy follows `spec/share-copy-audit-2026-07-27.md`. |
| **The four places** | Home · Clubhouse · ⊕ · You, and "the long game / the short game." | Tab bar canon (D82). See IOS-002. |
| **Build identity** | `v23 · <sha>` visible in Settings. | Build number + commit in Settings. |

## 2. What changes (and why)

### 2.1 Type scale → Dynamic Type

The web has **no scale** — sizes are picked per component, 84 declarations are ≤10px, everything is px. Native must have one. Proposed mapping (mono/serif/sans are the *face*; the size comes from the text style so Dynamic Type works end to end):

| Role | Web today | iOS text style | Face |
|---|---|---|---|
| Eyebrow / section header | mono 11.5, .16em, uppercase | `.caption1` (12pt floor) tracking 1.4 | Plex Mono 500 |
| Stat label / table head | mono 11 | `.caption2` (11pt floor) | Plex Mono |
| Tile label | mono **8.5** | `.caption2` — never below 11pt | Plex Mono |
| Tab label | mono 10.5 | system tab label | SF |
| Stat value | mono 21 tabular | `.title2` tabular | Plex Mono 600 |
| Hero number (rank, index, pot) | serif 36–52 | `.largeTitle` + `@ScaledMetric` for the 44–52 tier | Charter Bold |
| Finish gross | serif clamp(84–96) | custom `@ScaledMetric(relativeTo: .largeTitle)` 88 | Charter Bold |
| Standings sentence | serif 13 | `.callout` | Charter |
| Body / helper (`.fine`) | 13 dim | `.subheadline` / `.footnote` | SF |
| Button | 14/600 | `.body` semibold | SF |
| Inputs | mono 16 | `.body` | Plex Mono |

Rule: **nothing renders below 11pt at the default size**, and every layout tolerates the accessibility sizes (test at AX3 minimum; hero numbers may cap growth via `maxFontSizeMultiplier`-style relative metrics, labels never).

### 2.2 The `dim` tier fails contrast — ⚑ sub-decision (P2, proceeding)

`dim` #5C646B on `bg0` ≈ 3.1:1 and on `bg1` ≈ 2.8:1 — **below AA for text**, and it is the colour of every eyebrow, tab label, table head and helper paragraph. Light theme has the same problem (≈2.7:1).

Recommendation: on iOS, **text** that the web sets in `dim` renders in `mut` (#8E979E, ≈6.2:1); `dim` is kept for hairlines, dots, disabled glyphs and watermarks where contrast rules do not apply. This is a native mapping, not a token change, so `tokens.json` and preflight check 10 are untouched. If the owner prefers to fix the token itself (which would also lift the web), that is a one-line change to `tokens.json` under a decision-log entry — flagged, not done.

### 2.3 Density

The web reads as "a designer's dashboard, not an outdoor phone app you use with one hand at the turn" (audit 08 §7.1.6). Native widens: 16pt gutters become 20; card padding 16 → 16/20; row heights ≥ 44pt; stat tiles hold one number each; tables lose the trend-sparkline column on phones and keep rank · squad · Δ · pts.

### 2.4 Chrome and components

| Web | iOS |
|---|---|
| `switchView` + `← Back` text links | `NavigationStack` per tab; system back; large titles off (the app's own eyebrow+serif header is the title). |
| One global `#sheet` (57 call sites, body replaced on every open) | `.sheet` with detents (`.medium`/`.large`) for *actions*; pushed detail screens for *objects* (Tour Card, round receipt, scorecard, members). |
| `#boardFull` dialog | The Board is a screen (the chat wants a keyboard-anchored list). |
| `.btn` 46px ember | Primary: ember fill, `bg0` ink, 50pt, r10. Quiet: `bg2` + `line`. Gold: champagne + `#171204` — earned CTAs only ("Share the card" after a win, "Run it back"). |
| `.mini` pill | Small bordered capsule, mono, 36pt. |
| `.seg` | Native segmented control styled to the tokens (or a custom pill seg — the web's is close to Apple's anyway). |
| `input.f` | Native fields, mono face, `bg2` fill, r10, focus ring in `focus`. |
| `<select>` tees, `type=date` | Pickers; the course/tee picker is its own screen. |
| Toast | Bottom pill, ink on `bg0`, rolls out. Keep. |
| Skeleton shimmer | Redacted placeholders in the same shapes. |
| `emptyState({icon,line,cta})` | One component: a quiet SF Symbol or emoji, one line in voice, one next move. Every dead end becomes a next move. |
| Z-index ladder (50→99999) | Gone. Presentation contexts. |

### 2.5 Iconography

- **Chrome:** SF Symbols at the web sprite's weight (2px stroke ≈ `.regular`), 14–17pt. Tab icons: `house`, a flag-in-clubhouse custom symbol (export the web path as a custom SF Symbol), the ⊕ circle, `person.text.rectangle`.
- **Emoji systems** unchanged.
- **Markers** as vector paths; the same 14 assets feed avatars, medallions, the occasion wink.

### 2.6 Photography

Round photos and avatars: private bucket, signed URLs cached for their 1h TTL, refreshed on foreground. Story cards keep the dusk wash and the marker medallion. Never a silhouette; never a fabricated face. `.room-dusk` (#0A0908 / #191614) stays the ceremony ground in **every** theme — settlements, trophies, the finish, share cards.

### 2.7 Motion

- One easing (the roll). View transitions: 6pt rise + fade, 0.26s.
- Ceremonies (§1) rebuilt with SwiftUI animation + `sensoryFeedback`. The Forge: Core Animation on the four tracer paths (keyframe data is in `index.html` 2561–2614) — ⚑ **sub-decision (P2, proceeding):** rebuild in code rather than Lottie/video, because the reduced-motion rest frame must be the live logo, not a poster frame, and the door must resize to every device.
- `prefers-reduced-motion` → `accessibilityReduceMotion`: everything above degrades to the rest frame, exactly as the 22 web media blocks do.

### 2.8 Haptics vocabulary (new — the web has one `vibrate([10,38,10])`)

| Moment | Feedback |
|---|---|
| Stroke ± on the stepper | `.selection` |
| Hole complete (all players scored) | `.impact(.medium)` |
| POSTED ✓ / finish ceremony | `.success` (the thock) |
| Reaction tap | `.selection` |
| Two-tap destructive arm ("Sure?") | `.warning` |
| Rank moved up on open | `.impact(.light)` once |
| Skins carry hits ≥2 | `.impact(.rigid)` |

No haptic on scroll, on navigation, or on errors that already toast.

### 2.9 Data visualisation (native)

Swift Charts with token colours; no gridlines, no legends where a label will do. The four native charts:
- **The climb** — squad rungs re-ordering (the web's FLIP animation becomes a matched-geometry list).
- **Standings sparkline** — kept on the squad receipt, dropped from the phone table.
- **Pressure meter** — the month floor gauge (warm→hot→fire fill).
- **Index trajectory** — new (IOS-004 §8): `index_at_post` over time with the counting differentials highlighted.

Numbers stay serif/mono; "what does this mean" copy sits above every chart, in voice.

### 2.10 Competition and win/loss states

| State | Visual |
|---|---|
| Standing moved up | ▲ in `warm` (1) / `hot` (2+); rank flips (split-flap) once per fresh load |
| Standing moved down | ▼ in `cool` — slate, never red |
| Held | — in `mut` |
| 1st place | `.earned` gold spine on the hero; gold rank hairline in the table |
| Band phrase | Torched it / Beat your number / Played to it / A little loose / Posted anyway — never PvI |
| Points | gold only when > 0 in a season; otherwise "COUNTS ON YOUR CARD" |
| Tee-sheet win | dusk room settlement: `⚔️ A def. B 3&2`, transfers, the 18-cell hole strip |
| Tee-sheet loss | same card, no gold, "LOSER PAYS WINNER $10 · SETTLE UP" |
| Cup Final | seed figure + "Four weeks, scored fresh." |
| Season wrapped | Trophy Room hero, engraver on the trophy, ceremony takeover once per member |

## 3. Empty and loading states

- Loading: redacted placeholder in the final shape, never a spinner in content (a spinner is allowed only on a button in flight).
- Empty: the web's `emptyState` contract — quiet icon · one line · one next move. The copy already exists for every surface (audit 08 §1.1) and ports verbatim.
- Error: server text verbatim when it is written for humans ("Your number comes from your scores now (12.4)…"); the three `humanError` phrasings for transport failures; never a raw code.
- Offline: yesterday's data with an honest line ("Showing what you had at 7:14am"); never a blank.

## 4. Do not

Generic SwiftUI cards on every screen · Apple blue anywhere (links are `dawn`) · a dashboard grid of KPI tiles (one hero, one lane) · placeholder icons · alerts for confirmation · light-first defaults · gold on anything unearned · red for "down" · a font below 11pt · a bounce.

## 5. Open sub-decisions carried in this artifact

| # | Question | Priority | Recommendation | Action |
|---|---|---|---|---|
| a | `dim` contrast: native text mapping vs token change | P2 | Native mapping (§2.2) | Proceeding |
| b | The Forge: code vs Lottie | P2 | Code (§2.7) | Proceeding |
| c | iPad | P1 | **Out of scope for v1**; the desktop surface covers the big screen (D98). `supportsTablet: false`. | Proceeding unless overruled |
