# Detector · Impeccable detector candidates DX, web (round 1)

| | |
|---|---|
| **Measured at** | web **`f88f538d`** (`index.html`, `get.html`, `support.html`, `legal.html`), the branch head when DX started. It is an ancestor of the candidate `9d84c483`. The baseline is the 214 candidates in `docs/design/ten-2026-09-27/detector-ledger.json`, taken at `5fabf861`. |
| **Status read at** | **`4a703402`**: `git log cf401dee..4a703402`, plus `f88f538d..cf401dee`. That covers root's fixes, N2's merge, and lanes W3 (`e8108e59`), W2 (`f46086b4`), W4 (`b8a61266`) and W5 (`4a703402`). W1 and W6 had not merged. |
| **Date** | 2026-09-28 |
| **Assessors** | **DX**, independent: Impeccable 4.3.1's detector (CLI 0.1.5) with three engines (static HTML, in-page, CLI URL). DX wrote no code. |
| **Raw evidence (outside git)** | `~/cup-season-claude-ten-gallery/evidence/detector/DETECTOR.md` · `…/detector/detector-resolution.json` (37,919 entries: `meta`, `counts`, `true_positives`, `observations_beyond_detector`, `groups`) · `…/detector/proposals/` (TP-01 to TP-22: 18 diffs and 4 notes, none applied) · `…/detector/measure/`, `…/raw/`, `…/snapshots/` (92 sanitised DOMs), `…/scripts/` |

Written by session C (docs). The verdicts and measurements are DX's; the status column is this file's, read from commits. The status words are as in CRITIQUE.md, and **every fix is verification pending** until DX2 (round 2) re-measures it.

DX's own redaction: the shipped markup carried real-person strings (the owner's contact address and handle, and first names in the static demo diorama). DX replaced them with bracketed tokens in 180 files of its raw data, and every verdict re-derived from the redacted files was identical. That is the same problem as X37 in OWNER-QUESTIONS.

**The gate** (SESSIONS §1): every detector candidate resolved. **Met for round 1:** 37,919 candidates resolved and 0 unresolved. What remains is fixing the 22 true positives, and DX2 (session D) re-running with this resolution as its baseline.

## 1 · Resolution totals

| Verdict | Candidates |
|---|---:|
| fixed | 100 |
| false positive | 13,598 |
| true positive, open | 11,924, which are **22 distinct defects** (7 P2, 15 P3; no P0 or P1) |
| accepted by canon | 12,297 |
| **total** | **37,919** |

- **The 214 baseline candidates:** 100 fixed, 58 false positive, 31 true positive, 25 accepted by canon.
- **The 177 file-scan candidates at `f88f538d`:** 117 false positive, 31 true positive, 29 accepted. By file: 168 in `index.html`, 2 in `get.html`, 2 in `support.html`, 5 in `legal.html`.
- **Why the totals are large:** 92 renders (23 states × 375 and 1280 × dark and light) repeat one stylesheet and one markup. Every candidate points to exactly one true positive or verdict.

### By rule

| Rule | fixed | false positive | true positive, open | accepted by canon | total |
|---|---:|---:|---:|---:|---:|
| low-contrast | 69 | 12,933 | 1,818 | 0 | 14,820 |
| all-caps-body | 0 | 0 | 6,486 | 4,639 | 11,125 |
| wide-tracking | 0 | 0 | 785 | 2,795 | 3,580 |
| tiny-text | 0 | 0 | 192 | 2,906 | 3,098 |
| side-tab | 8 | 81 | 1,698 | 0 | 1,787 |
| tight-leading | 0 | 0 | 0 | 1,605 | 1,605 |
| cramped-padding | 3 | 84 | 265 | 24 | 376 |
| clipped-overflow-container | 0 | 288 | 0 | 0 | 288 |
| gpt-thin-border-wide-shadow | 0 | 0 | 282 | 0 | 282 |
| text-overflow | 0 | 0 | 100 | 160 | 260 |
| skipped-heading | 0 | 88 | 81 | 0 | 169 |
| pulsing-dot | 0 | 0 | 161 | 0 | 161 |
| broken-image | 0 | 81 | 0 | 0 | 81 |
| layout-transition | 0 | 0 | 0 | 80 | 80 |
| line-length | 0 | 10 | 56 | 0 | 66 |
| cream-palette | 0 | 0 | 0 | 55 | 55 |
| em-dash-overuse | 0 | 21 | 0 | 9 | 30 |
| text-occlusion | 0 | 12 | 0 | 0 | 12 |
| dark-glow | 11 | 0 | 0 | 0 | 11 |
| first-viewport-column-overflow | 0 | 0 | 0 | 8 | 8 |
| kicker-above-heading | 0 | 0 | 0 | 8 | 8 |
| nested-cards | 0 | 0 | 0 | 8 | 8 |
| undersized-ui-text | 8 | 0 | 0 | 0 | 8 |
| flat-type-hierarchy | 1 | 0 | 0 | 0 | 1 |

The canon each acceptance rests on is keyed in `meta.canon_index`. The main ones:
- the agate label role and the 11px floor (UI_SYSTEM §1.2/§1.3, §16.2);
- the role leadings (name 1.16, agate 1.20, lead 1.14);
- the canon light ground (D270);
- the star rating's clip-width wipe (§11.1);
- the desk two-column body (§14.1);
- the page-header anatomy (§12.2);
- the receipt leaf in a sheet (§3.3);
- the tail ellipsis on a long course name, then canon's long-name policy (see TP-21).

## 2 · The 22 true positives, with status

Each is DX's element, rule, measurement and minimal fix at `f88f538d`, with its proposal file in `proposals/`.

| ID | Sev | Element | Rule · candidates | Defect, measured | DX's minimal fix | Status at `de3eaf35` |
|---|---|---|---|---|---|---|
| TP-01 | P2 | `#seasonTitle` on the live ember band | low-contrast · 34 | Set in ink, not brand-ink: 2.69:1 light, 3.05:1 dark | inherit brand-ink (5.76 / 5.27) | **fixed (38471687)** (AW P1-3, CQ-19) |
| TP-02 | P2 | Squad names in `#standingsStory` (`nameOf()`) | low-contrast · 80 | Squad pigment used as text: 2.09 and 2.20:1 on the light page | an ink name with a squad swatch (§16.4) | **fixed (49ee7d42)**, which landed before `9d84c483` (LEDGER X27) |
| TP-03 | P2 | `.hfcard.hfstory`, `.rcpt-moment.has-photo` | low-contrast · 176 | Light type over a photo has no dark ground while the photo loads or fails: 1.19–3.23:1 light | `background:var(--ceremony)` under the photo | **fixed in part (e8108e59)**: Home's photographed round sits on the pinned ceremony ground, "so scrim ink holds while the picture loads or if it fails (TP-03)" (2dce66e6). **Open:** the receipt moment, `.rcpt-moment.has-photo` (lane W1, not merged). |
| TP-04 | P2 | `.evclash .nm`, the Ryder room | text-overflow · 50 | Surnames cut at 375 (16–28px over) | initial the given name for the whole board before any truncation (§9.1) | **fixed (f46086b4)**: at a phone's width the clash board initials the given name on every row, and each pairing is one spoken group with every name whole (b6eb3925, naming TP-04) |
| TP-05 | P2 | `.vtog button.on` | low-contrast · 40 | `#0E1512` on the light act fill: 2.37:1 | `color:var(--bg0)` (6.93 / 5.85) | **fixed (38471687)** (AW P1-6) |
| TP-06 | P2 | `.bf-hdr`, the full-screen board | low-contrast · 40 | The title on a literal near-black band in light: 2.42:1 | the header ground from the theme | **fixed (38471687)**: `color-mix(in srgb, var(--bg0) 90%, transparent)`, title in ink (CQ-17) |
| TP-07 | P2 | `#phDelYes`, the delete-account confirm | low-contrast · 2 | White on the dark-printing neg fill: 2.81:1 | §7.1 destructive armed (4.58 / 4.62) | **fixed (38471687)** (CQ-24) |
| TP-08 | P3 | `.mini:hover` | low-contrast (hover) · 177 | The rule fill under mut, pos and dusk labels: 2.31–3.08:1 | hover steps to bg1 (§14.4) | **fixed (b263fd74)** |
| TP-09 | P3 | 13 spine rules (`.purse`, `.gamecard`, `.optcard`, `.nextcard`, `.ontheline`, `.ob-pcard`, `.hocc`, `.digest`, …) | side-tab · 1,698 | The retired 3–3.5px card spine | delete the stripes | **fixed in part.** Home's hero, digest and occasion spines are gone (e8108e59: ffdcd6b4, d9ee98da), and so is the Door wings' `.ob-pcard` (b8a61266: 2bc71749). **Open:** the Season page's `.purse`, `.nextcard` and `.ontheline` (root) and `.optcard` and `.gamecard` on Play and live scoring (lane W1). |
| TP-10 | P3 | `.optcard .livedot` | pulsing-dot · 161 | An infinite opacity pulse (it stops under Reduce Motion) | a steady ember dot | open · in lane W1 (the Play landing) |
| TP-11 | P3 | 23 caps producers (the table in `TP-11-phrase-caps.md`) | all-caps-body · 6,477 | Phrases and sentences set in caps | `is-phrase`, split the label from the gloss, or sentence case (§1.3) | **fixed in part.** Row 18, `#rulesHead`, is now "The rules" (735a63ec). Row 1, the Home feed's course-circle gloss, is sentence case (e8108e59: 2dce66e6, "TP-11 #1"). **Open, verification pending:** the other 21 producers, across courses, You, the draw room, live setup, the wizard, the Season rooms, the form lens and the settings sheet. Lanes W2–W5 swept their own surfaces' type without naming these rows (W5 moved the wizard's step heads and sentences out of mono, 1d6ed619); the shared `.eyebrow` and `label.f` roles are W6's (session B). |
| TP-12 | P3 | `get.html` `.status` | all-caps-body · 9 | A status clause in caps | drop the uppercase and the caps tracking | **fixed (b8a61266)**: "the status clause is sentence case (TP-12)" (0fca89d5) |
| TP-13 | P3 | the plate drawing in `.cs-plate` | low-contrast · 1,269 | Theme mut on the pinned ceremony ground (1.69:1 light) | `fill: var(--ceremony-mut)` | **fixed (b263fd74)** |
| TP-14 | P3 | `.sheet .panel` | gpt-thin-border-wide-shadow · 121 | A border on the sheet as well as its shadow | drop the border | **fixed (b263fd74)** |
| TP-15 | P3 | `.scoreboard`, the live round's sticky scoreboard (`body.cardview .scoreboard`) | gpt-thin-border-wide-shadow · 161 | A border plus an off-token shadow | drop both | open · in lane W1, live scoring (at `de3eaf35`, `.scoreboard` still has `border` and `box-shadow:0 6px 18px rgba(0,0,0,.18)`) |
| TP-16 | P3 | `#view-draft.room-dusk` | cramped-padding · 81 | A dusk ground with 0px inset | pad by the gutter | **fixed (b263fd74)** |
| TP-17 | P3 | view headings | skipped-heading · 81 | No h1; the outline opens at h2 or h4 | one h1 per view, h2 sections | **fixed (69f40d1f)** (AW P2-8) |
| TP-18 | P3 | five label-line rules at .06 or .10em | wide-tracking · 601 | Off-token tracking | the agate token (.08 / .09em) | **fixed in part (b263fd74)**: `.chart-note` and `.ontheline .os`. **Open:** `.inheritline` (`#postInheritText`, W1), `.htile .s` (Home, W3) and `.pdoorlink small` (`#crLinkBtn`, W3), still at .06 / .06 / .1em at `de3eaf35`. |
| TP-19 | P3 | `#rosterSub`, `.endgame-line`, `.climb-empty`, the standings' empty row | tiny-text, wide-tracking · 376 | Prose set as 11–12px tracked mono | the body role; an empty state as lead plus body | **fixed (b263fd74)** (and 735a63ec's roster sentence) |
| TP-20 | P3 | desk prose blocks (`p.fine` in many places, `.rulesec p`, `p.endgamefoot`, `.hocc > p`, `#optLive`/`#optPlan > p`) | line-length · 56 | 81–148 characters a line at 1280 | `max-width:60ch` at ≥960px | **fixed in part (735a63ec)**: `.rulesec p` is capped at 70ch (DX proposed 60ch). **Open:** the other blocks, across Home (W3), Season (root), Play (W1), You and settings (W2). |
| TP-21 | P3 | `.tslatx small`, the trophy sub-line | text-overflow · 50 | The ellipsis removes the date along with the course name | only the course name truncates | **fixed (38471687)**: `.tslatx b` and `small` wrap whole (`overflow-wrap:anywhere`) instead |
| TP-22 | P3 | `.prow` | cramped-padding · 184 | A bordered card whose content sits 0px from its left border | delete the card rule | **fixed (f46086b4)**: "Rivalries are rows on rules with faces (no 0-inset card)" (35b4f475) |

**Tally at `4a703402`:** 22 true positives. Every fixed item is verification pending until DX2.
- **fixed: 15.** TP-01, 02, 04, 05, 06, 07, 08, 12, 13, 14, 16, 17, 19, 21, 22.
- **fixed in part: 5.** TP-03, 09, 11, 18, 20.
- **open: 2.** TP-10 and TP-15, both in lane W1 (Play and live scoring), which had not merged.

## 3 · Found while measuring, outside the detector

These are DX's "observations beyond the detector". They are not candidates and not in the counts.

| ID | Sev | Finding | Status at `de3eaf35` |
|---|---|---|---|
| OB-01 | P2 | The receipt's `button.cs-tskip` is theme mut on the leaf's bone paper in the dark printing: 2.10:1 | **fixed (38471687)** (AW P1-2) |
| OB-02 | P2 | `#homeUpNext .upchip.hot > span.k` ("Month closes") is ember on bg2 in the dark printing: 3.81:1 | **fixed (38471687)** (AW P1-4, CQ-08) |
| OB-03 | P3 | `#structSeg` (wizard: 2/3/4 squads) is dimmed to opacity .4 but is neither `disabled` nor `aria-disabled`: 1.70–3.46:1 | **fixed (4a703402)**: "Squad options are never faded" (1d6ed619; CQ-23) |
| OB-04 | P3 | The `.hocc::before` stripe was neutralised (f0297c27) but not removed | **fixed (e8108e59)**: "The occasion is a quiet block on the rule: no box, no spine" (ffdcd6b4) |
| OB-05 | P3 | Eyebrows, `label.f`, `.lockbadge` and check-row sub-lines are set in Plex Mono, where canon moved them to the agate board face, and tracked at .10–.16em against a token of .09em | **fixed in part (e8108e59)**: Home's and the board's labels are agate, not mono (d9ee98da). **Open:** the shared `.eyebrow`, `label.f` and `.lockbadge` roles, W6 (session B). It is the root of many accepted caps and tiny-text candidates. |
| OB-06 | P3 | `.digest` (Home's "Since you were here" frame) has a 3px ember left border that no capture state drew | **fixed (e8108e59)**: "a quiet note on the rule, not a bordered box with a 3px EMBER spine", naming TP-09/OB-06 (d9ee98da) |

**The contrast census:** 121,448 text nodes in the 92 renders, with 2,008 failing pairs. Every failing pair belongs to TP-01, 02, 03, 05, 06, 07 or 13, to OB-01, 02 or 03, or to a disabled control (which WCAG exempts).

## 4 · Limits DX recorded
- **States never reached live:** no render reached the live-scoring round, the draw room, the full-screen board or the delete-account confirm. TP-05, 06, 07 and 15, part of TP-08, and some spines were judged from computed styles in the hidden DOM.
- **Widths:** only 375 and 1280, dark and light.
- **Photographs:** text over a photo was judged from live renders with and without the fixture photograph.
- **The native app** is out of DX's scope. Session A's detector sweep DXN covers `apps/ios` at `4112a3f0`: `~/cup-season-claude-ten-gallery/evidence/native/detector/`. **Pending (session A).**
- **Round 2:** DX2 (session D) re-runs at the round-2 SHA with this resolution as its baseline, and resolves every new candidate.
