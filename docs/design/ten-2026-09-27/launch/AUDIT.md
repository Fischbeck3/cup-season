# Audit · Impeccable audit AW, web (round 1)

| | |
|---|---|
| **Measured at** | web **`9d84c483`**, source read from the snapshot `candidate-9d84c483/`. Live probes ran against the pinned server, which served `index.html` sha256 `2ac5c63a…`. |
| **Status read at** | **`4a703402`**: `git log cf401dee..4a703402`, plus `9d84c483..cf401dee`. That covers root's fixes, N2's merge, and lanes W3 (`e8108e59`), W2 (`f46086b4`), W4 (`b8a61266`) and W5 (`4a703402`). W1 and W6 had not merged. |
| **Date** | 2026-09-28 |
| **Assessors** | **AW**, an independent web audit with Impeccable 4.3.1 `audit`. AW wrote no code. |
| **Raw evidence (outside git)** | `~/cup-season-claude-ten-gallery/evidence/audit-web/AUDIT-web.md` and `audit-web.json` · `…/audit-web/raw/` (probe results) · `…/audit-web/shots/` · `…/audit-web/snapshots/` and `…/audit-web/detector/` (sanitised DOMs and detector runs) · `…/audit-web/probe/aw-probe.mjs` |

Written by session C (docs). Findings and scores are AW's; the status column is this file's, read from commits. The status words are as in CRITIQUE.md. *fixed (sha)* means the commit message or diff shows the fix (for a lane, the lane's own commit names it, and the sha is its merge). **Every fix is verification pending** until round 2 (session D, audit AW2) re-measures it.

**The gate** (SESSIONS §1): at least 18/20, web and native. **Round 1: 12/20, "Acceptable (10–13)". Not met.**

## 1 · Score by dimension

| # | Dimension | AW score | AW's key finding | What stands between it and 4 (AW) | Where it stands at `de3eaf35` |
|---|---|:-:|---|---|---|
| 1 | Accessibility | **2** | Full-screen takeovers don't isolate what they cover (8–12 of every 14–18 Tab stops sit on invisible controls); five AA contrast failures | inert takeovers; fix the contrast pairs and the placeholder colour; `[data-tc]` rows as buttons; `<main>`, a skip link and one h1 per view | Every named change has a commit: P1-1 to P1-6, P2-7, P2-8 and P2-9 are fixed (§2). Open: P3-23's composer half. |
| 2 | Performance | **2** | A signed-in cold open paints the sign-in Door first, then rebuilds Home three times (CLS 0.55 at 375); the whole 2.05 MB app is parsed on every visit | decide door-or-app before first paint; render Home once in final slot order; load signed-in code after the session check ("structural, post-launch") | The Door flash is fixed (69f40d1f). Home's staged render (CLS) and code splitting are open; the second is Q12 in OWNER-QUESTIONS, because the owner's direction defers nothing. |
| 3 | Responsive design | **3** | No overflow anywhere from 320 to 1600; about 15 control types under 44px; long names cut with an ellipsis; You and Schedule on the desk are the phone column stretched | 44px hit boxes; names wrap; a desk second column for You and Schedule | Every named change has a commit: targets and ellipses (38471687); You and Schedule on the desk (f46086b4). |
| 4 | Theming | **3** | 92 tokens and a verified dark-first default, but `SQHEX` bypasses the D270 tokens, three inks sit on the wrong ground, `.room-dusk` carries pre-D270 values, and theme-color doesn't match the ground | map `SQHEX` to `var(--sq*)`; fix the three ink pairings; re-point `.room-dusk`; theme-color = `bg0` | All four are fixed: 38471687 (SQHEX, the ink pairings, `.room-dusk`) and 69f40d1f (theme-color, manifest). P3-24 is fixed too (69f40d1f, 735a63ec, e8108e59, f46086b4). |
| 5 | Implementation integrity | **2** | A coherent product-specific system, but ratified retirements are not carried through: the 3.5px spine on 6+ components, fiction labelled "live" on the Door, ember CTAs and mono sentences on share views | delete the spines; label or re-word the wings; share CTAs to `act`, sentences to serif or sans | Share CTAs and sentences (38471687) and the Door wings (b8a61266) are fixed. The spines are fixed in part (e8108e59, b8a61266); those on the Season page (root) and the Play cards (W1) are open. |
| | **Total** | **12/20** | | | **Not re-measured.** Performance (Q12) and integrity (the remaining spines) are the two dimensions with open items. |

AW's integrity verdict: "Pass, with verified drift."

## 2 · Every finding (P0 0 · P1 6 · P2 11 · P3 8), with status

| AW id | Sev | Dimension | Finding | Where (AW, at `9d84c483`) | Status at `de3eaf35` |
|---|---|---|---|---|---|
| P1-1 | P1 | accessibility | Full-screen takeovers leave the covered page in the Tab order and the accessibility tree (Door, card gate, claim link, public round, person landing) | `#onboard` (index.html:4512); csModal excluded the Door (:9192); `#shareView` (:33137) | **fixed (38471687)**: the app under the Door, a link's share view or the unsubscribe page is inert (`csModal` COVERS); Tab presses on the app behind the Door went from 16 of 30 to 0 |
| P1-2 | P1 | accessibility | The receipt's count link is `mut` on the cream leaf in dark (2.10:1) | `.cs-tskip` in `#rcptBody` | **fixed (38471687)** "the leaf's quiet link" (DX OB-01) |
| P1-3 | P1 | accessibility | The Season masthead title is ink on the ember band: 2.69:1 in light | `.seasontitle{color:var(--ink)}` | **fixed (38471687)** (DX TP-01, CQ-19) |
| P1-4 | P1 | accessibility | The Home "Month closes" chip label is ember on bg2 (3.81:1 at 11px, dark) | `.upchip.hot .k` | **fixed (38471687)** (DX OB-02, CQ-08) |
| P1-5 | P1 | accessibility | Placeholder text is the browser default `#757575` on at least ten fields (2.79:1 dark, 3.24:1 light) | `input.f`/`textarea.f` with no `::placeholder` | **fixed (38471687)** "every placeholder" |
| P1-6 | P1 | accessibility | Desk live scoring in light: the selected HOLE/CARD segment is 2.37:1 | `.vtog button.on` | **fixed (38471687)** (DX TP-05) |
| P2-7 | P2 | accessibility | Golfer rows and the sidebar league name work only with a mouse | `[data-tc]` rows; `#sideLeague` | **fixed (38471687)** "golfer rows and the sidebar league switch work from the keyboard" |
| P2-8 | P2 | accessibility | No `main` landmark, no skip link, few headings | `section.view`, no `<main>` | **fixed (69f40d1f)**: one h1 per view, the views' container is `main`, and a skip link is the first stop (DX TP-17) |
| P2-9 | P2 | accessibility | The composer's score box has no focus indicator | `.grossbox{outline:0}` | **fixed (38471687)** "the score box draws a focus ring" |
| P2-10 | P2 | responsive | Touch targets under the 44px floor: steppers 36, chips 28, sheet Close 26×31, remove × 22×21, header search 33, course line 28, "See the receipt" 23, "THE BOARD ↗" 14, "Start over" 16, feed report/comment, delete-round ×, half-star buttons, calendar arrows | `.step button`, `.whochip`, `.selchip`, `.sheet .x`, `.pslot .sx`, `#hdrSearch`, `#postInherit`, … | **fixed (38471687)** for the controls the commit names: steppers, golfer chips, sheet Close, remove ×, header search, the inherit line, the lead's action, go-links, back links, Start over, facts, show-more, `.mini`, desk nav, HOLE/CARD, delete-round ×, reaction controls. **Open, verification pending:** the half-star buttons and the calendar arrows, which it does not name. |
| P2-11 | P2 | performance | A signed-in cold open flashes the sign-in Door, then re-lays Home three times (CLS 0.55 at 375) | the boot sequence; the pre-paint script doesn't check for a session | **fixed in part.** With a stored session the Door waits hidden until boot decides (69f40d1f). A buddy request no longer tops Home: it sits under the lead or stands down for the dispatch (e8108e59), which removes AW's third re-lay. **Open:** rendering Home once, in its final slot order. CLS is not re-measured (Q12). |
| P2-12 | P2 | theming | Squad colour bypasses the tokens: the `SQHEX` literal palette at 26 sites | `SQHEX = ['#57A8FF', …]` | **fixed (38471687)**: `SQHEX = [0,1,2,3].map(i => var(--sq${i}))` |
| P2-13 | P2 | integrity | The retired 3.5px card spine is still painted (`.purse`, `.gamecard`, `.optcard`, `.nextcard`, `.ontheline`, `.ob-pcard`, …) | 11 selectors in CSS; `raw/stripes.json` | **fixed in part.** Home's hero spine, the digest's and the occasion's are gone (e8108e59: ffdcd6b4, d9ee98da), and so is the Door wings' `.ob-pcard` spine (b8a61266: 2bc71749). **Open:** the Season page's `.purse`, `.nextcard` and `.ontheline` (root) and the Play landing's and live scoring's `.optcard` and `.gamecard` (lane W1). DX's TP-09 diff covers them. |
| P2-14 | P2 | responsive | Long names are cut with an ellipsis instead of wrapping | `.yrow .cs-name-s`, `.cs-agate-s.is-phrase`, `#youMeta`, `#glfBoard .fbn b`, the person-landing rows | **fixed (38471687)**: 13 ellipsis rules removed (names and course lines wrap whole, and the Golfers board name "wraps whole; it was cut at 320"). Five ellipsis rules remain, none of them AW's: the trip figures, the credential's figure sub-line, the Home tile value, and two in the Door wings. |
| P2-15 | P2 | responsive | You and Schedule on the desk are the phone column stretched (D234) | `view-stats` and Schedule at ≥1024 | **fixed (f46086b4)**: You is identity, form and golf left with buddies and the record in the 340 aside (35b4f475); Schedule is the calendar in the reading column with plans in the aside (57325028) |
| P2-16 | P2 | integrity | The Door wings show authored fiction as live data ("Rounds hitting the board", "The season, live") | index.html:4529, :4653, data :6435–6446 | **fixed (b8a61266)**: labelled examples ("How a round reads", "How a season reads", an example season) that stand down on a link landing (2bc71749; CQ-06). Whether the phone Door shows a specimen is Q6. |
| P2-17 | P2 | integrity | Share and unsubscribe takeovers paint the ordinary action in ember and set sentences in mono | person landing "Get the app" `C.hot`; unsubscribe `#FF5A2E`; the share view's base font MONO | **fixed (38471687)**: "act, not ember, for the way in; sentences in sans, labels in mono" |
| P3-18 | P3 | theming | theme-color and the manifest colours don't match the `bg0` ground | index.html:6, :4429; `manifest.webmanifest` | **fixed (69f40d1f)** |
| P3-19 | P3 | theming | `.room-dusk` re-asserts pre-D270 values (deleted tokens, old squad hues, a pre-token ground) | index.html:4052–4064 | **fixed (38471687)**: the room is the ceremony ground under the current dark printing (D277) |
| P3-20 | P3 | accessibility | The reduced-motion backstop kills the surfaces' own reduced alternatives (the toast's fade) | index.html:4309–4316 | **fixed (69f40d1f)**: the toast keeps its designed fade under Reduce Motion |
| P3-21 | P3 | accessibility | Two focus-ring systems (the browser's 1px ring on about a quarter of stops; `.mini`'s 28% glow) | `:focus-visible` rules | **fixed (69f40d1f)**: one 2px act ring, with a zero-specificity baseline replacing the browser's |
| P3-22 | P3 | accessibility | The manifest locks the installed app to portrait (WCAG 1.3.4) | `manifest.webmanifest` | **fixed (69f40d1f)** |
| P3-23 | P3 | accessibility | Errors aren't tied to their fields or to focus | `#obCodeIn`; `#obStatus`; the composer's post failure | **fixed in part:** the Door's fields name `#obStatus` and an error marks its field invalid (69f40d1f); the status lands in view at 375×380 (d15b5f18). **Open:** a refused post is still a toast with focus on `<body>` (in lane W1, not merged; the same path as CQ-09). |
| P3-24 | P3 | theming | Small colour misuses: `::selection` in the retired hot, the Pro's note in pre-token gold, a pointer on non-Pro payer rows, dim "·" separators on You | index.html:3594, :4248–4262, :1338–1343 | **fixed.** `::selection` is act (69f40d1f); only the Pro's payer rows are buttons with a pointer (735a63ec); the Pro's note is on tokens with no gold, naming AW P3-24 (e8108e59: ffdcd6b4); You's course-fact separators are opaque mut (f46086b4: 35b4f475); whether those are the separators AW measured is verification pending. The phone's gold "From the Pro" goes to N4. |
| P3-25 | P3 | performance | One 2.05 MB document is parsed by every visitor, and every view's DOM stays resident | index.html (1.64 MB inline JS, 285 KB CSS); render-blocking Google Fonts CSS | **open.** AW calls it "structural, post-launch"; the owner's direction defers nothing, so this is Q12 in OWNER-QUESTIONS. |

**Tally at `4a703402`:** 25 findings. Every fixed item is verification pending until round 2.
- **fixed: 21.** P1-1 to P1-6; P2-7, 8, 9, 10, 12, 14, 15, 16 and 17; P3-18, 19, 20, 21, 22 and 24. P2-10 keeps two controls its commit does not name (the half-star buttons and the calendar arrows); they are open, verification pending.
- **fixed in part: 3.**
  - P2-11: Home's single render remains.
  - P2-13: the Season and Play spines remain.
  - P3-23: the composer's refusal remains (W1).
- **open: 1.** P3-25, code splitting (Q12).

## 3 · What stands between 12/20 and 18/20

This is a reading of AW's rubric against the commits, not a score.
- **Accessibility, theming and responsive:** every change AW named for 4 has a commit, except You and Schedule on the desk (W2) and the P3 residuals. Round 2 decides whether they reach 4.
- **Integrity:** the Door wings are true now (b8a61266). The spines left are on the Season page (root) and the Play cards (W1).
- **Performance:** AW's route to 4 is structural (decide door-or-app before first paint, render Home once, split the signed-in code). The first part landed in 69f40d1f; the rest is Q12.

At 18/20, at most two points can be lost across the five dimensions. With performance left at 2 or 3, the other four must be at 4, or at 4, 4, 4 and 3.

## 4 · Native audit

**Pending (session A).** Session A runs audit AN on `4112a3f0` with `reference/audit.native.md`, scoring accessibility (Dynamic Type, VoiceOver names and order from the AX trees), performance as far as source shows it, responsive (SE 3 375pt against 17 Pro 402pt, and AX3), theming and integrity, 0–4 each. Output: `~/cup-season-claude-ten-gallery/evidence/native/audit/AUDIT-native.{md,json}`. The gate is the same 18/20.
