# Detector · Impeccable detector candidates DX, web (round 1)

| | |
|---|---|
| **Measured at** | web **`f88f538d`** (`index.html`, `get.html`, `support.html`, `legal.html`), the branch head when DX started. It is an ancestor of the candidate `9d84c483`. The baseline is the 214 candidates in `docs/design/ten-2026-09-27/detector-ledger.json`, taken at `5fabf861`. |
| **Status read at** | **`144ee0b0`** on integration: every web lane, root's fixes through `7141516f`, and E's native phase 1 (`6716b0ed`). The web shipped as `272c2da1`, serving `ed8e6837`'s files. |
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
| TP-03 | P2 | `.hfcard.hfstory`, `.rcpt-moment.has-photo` | low-contrast · 176 | Light type over a photo has no dark ground while the photo loads or fails: 1.19–3.23:1 light | `background:var(--ceremony)` under the photo | **fixed (e8108e59, 1e9eb856)**: Home's photographed round sits on the pinned ceremony ground (2dce66e6), and so does the receipt moment under a photograph that is loading or failed (ab687232, naming TP-03) |
| TP-04 | P2 | `.evclash .nm`, the Ryder room | text-overflow · 50 | Surnames cut at 375 (16–28px over) | initial the given name for the whole board before any truncation (§9.1) | **fixed (f46086b4)**: at a phone's width the clash board initials the given name on every row, and each pairing is one spoken group with every name whole (b6eb3925, naming TP-04) |
| TP-05 | P2 | `.vtog button.on` | low-contrast · 40 | `#0E1512` on the light act fill: 2.37:1 | `color:var(--bg0)` (6.93 / 5.85) | **fixed (38471687)** (AW P1-6) |
| TP-06 | P2 | `.bf-hdr`, the full-screen board | low-contrast · 40 | The title on a literal near-black band in light: 2.42:1 | the header ground from the theme | **fixed (38471687)**: `color-mix(in srgb, var(--bg0) 90%, transparent)`, title in ink (CQ-17) |
| TP-07 | P2 | `#phDelYes`, the delete-account confirm | low-contrast · 2 | White on the dark-printing neg fill: 2.81:1 | §7.1 destructive armed (4.58 / 4.62) | **fixed (38471687)** (CQ-24) |
| TP-08 | P3 | `.mini:hover` | low-contrast (hover) · 177 | The rule fill under mut, pos and dusk labels: 2.31–3.08:1 | hover steps to bg1 (§14.4) | **fixed (b263fd74, f6cb4760)**: hover steps to bg1; W6 then made hover and focus ring-only (71d9b41d) |
| TP-09 | P3 | 13 spine rules (`.squad.onclock`, `.purse`, `.preset.sel`, `.gamecard`, `.optcard`, `.phasehero`, `.nextcard`, `.ontheline`, `.hhero`, `.hocc`, `.sysrow`, `.momrow`, `.livebanner`, `.ob-pcard`; plus `.digest` and the dead `.pro`) | side-tab · 1,698 | The retired 3–3.5px card spine | delete the stripes | **fixed in part.** Gone: Home's hero, digest and occasion (e8108e59); the Door wings (b8a61266); Play's option cards, the live game cards and the banner (1e9eb856); the wizard's chosen preset, overridden in the wizard (4a703402: 1d6ed619); and the Season page's `.purse`, `.pro`, `.phasehero`, `.nextcard` and `.ontheline` (b82eabd9). **Open at `fd27ace4`:** `.squad.onclock`, the draw room's `inset 3px` squad stripe, and `.momrow`, the board moment row's 3px ember `border-left`, which a comment keeps as "its ember rail"; whether a moment keeps a rail is Q36 (the phone's twin is TPN-19). Three other 3.5px bars (`.round .bar`, `.msgrow .bar`, `.clock .accent`) are on no list; DX2 will say whether they are spines. |
| TP-10 | P3 | `.optcard .livedot` | pulsing-dot · 161 | An infinite opacity pulse (it stops under Reduce Motion) | a steady ember dot | **fixed (1e9eb856)**: "the Play landing's live dot is steady ember" (ab687232, naming TP-10) |
| TP-11 | P3 | 23 caps producers (the table in `TP-11-phrase-caps.md`) | all-caps-body · 6,477 | Phrases and sentences set in caps | `is-phrase`, split the label from the gloss, or sentence case (§1.3) | **fixed in part.** Row 18, `#rulesHead`, is now "The rules" (735a63ec). Row 1, the Home feed's course-circle gloss, is sentence case (e8108e59: 2dce66e6, "TP-11 #1"). **Open, verification pending:** the other 21 producers, across courses, You, the draw room, live setup, the wizard, the Season rooms, the form lens and the settings sheet. Lanes W2–W5 swept their own surfaces' type without naming these rows (W5 moved the wizard's step heads and sentences out of mono, 1d6ed619); the shared `.eyebrow` and `label.f` roles are W6's (session B). |
| TP-12 | P3 | `get.html` `.status` | all-caps-body · 9 | A status clause in caps | drop the uppercase and the caps tracking | **fixed (b8a61266)**: "the status clause is sentence case (TP-12)" (0fca89d5) |
| TP-13 | P3 | the plate drawing in `.cs-plate` | low-contrast · 1,269 | Theme mut on the pinned ceremony ground (1.69:1 light) | `fill: var(--ceremony-mut)` | **fixed (b263fd74)** |
| TP-14 | P3 | `.sheet .panel` | gpt-thin-border-wide-shadow · 121 | A border on the sheet as well as its shadow | drop the border | **fixed (b263fd74)** |
| TP-15 | P3 | `.scoreboard`, the live round's sticky scoreboard (`body.cardview .scoreboard`) | gpt-thin-border-wide-shadow · 161 | A border plus an off-token shadow | drop both | **fixed (1e9eb856)**: "the live scoreboard drops its border and its off-token shadow" (ab687232, naming TP-15) |
| TP-16 | P3 | `#view-draft.room-dusk` | cramped-padding · 81 | A dusk ground with 0px inset | pad by the gutter | **fixed (b263fd74)** |
| TP-17 | P3 | view headings | skipped-heading · 81 | No h1; the outline opens at h2 or h4 | one h1 per view, h2 sections | **fixed (69f40d1f)** (AW P2-8) |
| TP-18 | P3 | five label-line rules at .06 or .10em | wide-tracking · 601 | Off-token tracking | the agate token (.08 / .09em) | **fixed.** `.chart-note` and `.ontheline .os` (b263fd74); `.pdoorlink small` loses its tracking (e8108e59: 3324ae89); `.htile .s` is gone with W3's foot list (e8108e59: ffdcd6b4); and `.inheritline` becomes an agate key over a sans value (1e9eb856: 84983c4c). Read in the source at `fd27ace4`. |
| TP-19 | P3 | `#rosterSub`, `.endgame-line`, `.climb-empty`, the standings' empty row | tiny-text, wide-tracking · 376 | Prose set as 11–12px tracked mono | the body role; an empty state as lead plus body | **fixed (b263fd74)** (and 735a63ec's roster sentence) |
| TP-20 | P3 | desk prose blocks (`p.fine` in many places, `.rulesec p`, `p.endgamefoot`, `.hocc > p`, `#optLive`/`#optPlan > p`) | line-length · 56 | 81–148 characters a line at 1280 | `max-width:60ch` at ≥960px | **fixed in part (735a63ec)**: `.rulesec p` is capped at 70ch (DX proposed 60ch). **Open:** the other blocks, across Home (W3), Season (root), Play (W1), You and settings (W2). |
| TP-21 | P3 | `.tslatx small`, the trophy sub-line | text-overflow · 50 | The ellipsis removes the date along with the course name | only the course name truncates | **fixed (38471687)**: `.tslatx b` and `small` wrap whole (`overflow-wrap:anywhere`) instead |
| TP-22 | P3 | `.prow` | cramped-padding · 184 | A bordered card whose content sits 0px from its left border | delete the card rule | **fixed (f46086b4)**: "Rivalries are rows on rules with faces (no 0-inset card)" (35b4f475) |

**Tally at `fd27ace4`:** 22 true positives. Every fixed item is verification pending until DX2.
- **fixed: 19.** TP-01, 02, 03, 04, 05, 06, 07, 08, 10, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22.
- **fixed in part: 3.**
  - TP-09: `.squad.onclock` and `.momrow` remain.
  - TP-11: 21 caps producers, the next wave (P3).
  - TP-20: the desk prose measure, the next wave (P3).
- **open: 0.**

## 3 · Found while measuring, outside the detector

These are DX's "observations beyond the detector". They are not candidates and not in the counts.

| ID | Sev | Finding | Status at `de3eaf35` |
|---|---|---|---|
| OB-01 | P2 | The receipt's `button.cs-tskip` is theme mut on the leaf's bone paper in the dark printing: 2.10:1 | **fixed (38471687)** (AW P1-2) |
| OB-02 | P2 | `#homeUpNext .upchip.hot > span.k` ("Month closes") is ember on bg2 in the dark printing: 3.81:1 | **fixed (38471687)** (AW P1-4, CQ-08) |
| OB-03 | P3 | `#structSeg` (wizard: 2/3/4 squads) is dimmed to opacity .4 but is neither `disabled` nor `aria-disabled`: 1.70–3.46:1 | **fixed (4a703402)**: "Squad options are never faded" (1d6ed619; CQ-23) |
| OB-04 | P3 | The `.hocc::before` stripe was neutralised (f0297c27) but not removed | **fixed (e8108e59)**: "The occasion is a quiet block on the rule: no box, no spine" (ffdcd6b4) |
| OB-05 | P3 | Eyebrows, `label.f`, `.lockbadge` and check-row sub-lines are set in Plex Mono, where canon moved them to the agate board face, and tracked at .10–.16em against a token of .09em | **fixed (e8108e59, f6cb4760)**: Home's and the board's labels (d9ee98da); then the shared `.eyebrow`, `label.f` and the sheet `.sub` go to agate (71d9b41d), and W5's last mono labels (a819b5c9) |
| OB-06 | P3 | `.digest` (Home's "Since you were here" frame) has a 3px ember left border that no capture state drew | **fixed (e8108e59)**: "a quiet note on the rule, not a bordered box with a 3px EMBER spine", naming TP-09/OB-06 (d9ee98da) |

**The contrast census:** 121,448 text nodes in the 92 renders, with 2,008 failing pairs. Every failing pair belongs to TP-01, 02, 03, 05, 06, 07 or 13, to OB-01, 02 or 03, or to a disabled control (which WCAG exempts).

## 4 · Limits DX recorded
- **States never reached live:** no render reached the live-scoring round, the draw room, the full-screen board or the delete-account confirm. TP-05, 06, 07 and 15, part of TP-08, and some spines were judged from computed styles in the hidden DOM.
- **Widths:** only 375 and 1280, dark and light.
- **Photographs:** text over a photo was judged from live renders with and without the fixture photograph.
- **The native app** is out of DX's scope; session A's DXN covers it (§5).
- **Round 2:** DX2 (session D) re-runs at the round-2 SHA with this resolution as its baseline, and resolves every new candidate.


## 5 · Native detector DXN (session A, `apps/ios` at `4112a3f0`, located at `de3eaf35`)

Session A scanned the native source for the native forms of the canon lints:
- mono used for a sentence; serif numerals; `dim` as a word;
- gold on an unearned fact; ember outside competition;
- text under 11pt; targets under 44pt; clamps on names;
- colours outside Tokens;
- banned words.

Files: `~/cup-season-claude-ten-gallery/evidence/native/detector/DETECTOR-native.{md,json}`.

| Verdict | Candidates |
|---|---:|
| false positive | 1,482 |
| accepted by canon | 300 |
| true positive | 259, which are **36 distinct defects** (9 P2, 27 P3) |
| fixed | 0 |
| **total** | **2,041**, all resolved |

| TPN | Sev | Rule | Defect | Status at `144ee0b0` |
|---|---|---|---|---|
| TPN-01 | P2 | R6 | The in-app settlement, recap and round-record cards print their small type at 5-10pt | open · N4 (not in E's phase 1) |
| TPN-02 | P2 | R7 | A 44pt frame that is not the target: 31 controls tap only on their drawn words, glyph or pill | open · N4 (not in E's phase 1) |
| TPN-03 | P2 | R2 | Numerals set in the serif inside lead and story sentences | open · N4 (not in E's phase 1) |
| TPN-04 | P2 | R2 | Numerals set in the serif on the shared cards | open · N4 (not in E's phase 1) |
| TPN-05 | P2 | R2 | The retired Charter serif still sets live copy, numerals included | open · N4 (not in E's phase 1) |
| TPN-06 | P2 | R3 · R9 | The drawn course card's hole numerals are a dimmer grey (mut at a56) - below AA | open · N4 (not in E's phase 1) |
| TPN-07 | P2 | R4 | Gold paints scorecard cells: under-par holes, birdies, eagles and holes won | open · N4 (not in E's phase 1) |
| TPN-08 | P2 | R8 | The golfer's own card clamps and cuts names | open · N4 (not in E's phase 1) |
| TPN-09 | P2 | R8 | The record leaf cuts the competition's name at the default size | open · N4 (not in E's phase 1) |
| TPN-10 | P3 | R1 | Questions and sentences set as mono eyebrows | open · N4 (not in E's phase 1) |
| TPN-11 | P3 | R1 | Sentences set in the mono record face (columnS / CSFont.label) | open · N4 (not in E's phase 1) |
| TPN-12 | P3 | R3 · R9 | The receipt moment dims its words with invented opacities | open · N4 (not in E's phase 1) |
| TPN-13 | P3 | R3 | A disabled chip's label is `dim` | open · N4 (not in E's phase 1) |
| TPN-14 | P3 | R4 | Gold on a buy-in - money put in, not won | open · N4 (not in E's phase 1) |
| TPN-15 | P3 | R4 | A rivalry's typed name wears gold | open · N4 (not in E's phase 1) |
| TPN-16 | P3 | R4 | Gold on facts nobody won | open · N4 (not in E's phase 1) |
| TPN-17 | P3 | R5 | Ember on ordinary actions and selected states | open. Its when-fork "Right now" waits on **Q33** (DEC-N4-3); the other sites are N4's. |
| TPN-18 | P3 | R5 | Ember on status words, notes and notification counts | open · N4 (not in E's phase 1) |
| TPN-19 | P3 | R5 | Every board moment and buddy request wears an ember spine | **decision Q36**: does a moment keep an ember rail? The web's twin is `.momrow`, which TP-09 leaves open. |
| TPN-20 | P3 | R6 | The plan sheet's game chips shrink under 11pt | open · N4 (not in E's phase 1) |
| TPN-21 | P3 | R6 | Initials in a small face drop to 9.6pt | open · N4 (not in E's phase 1) |
| TPN-22 | P3 | R7 | A 12pt line with the default hit slop is a ~40pt target | open · N4 (not in E's phase 1) |
| TPN-23 | P3 | R7 | Controls with no target sizing at all | open · N4 (not in E's phase 1) |
| TPN-24 | P3 | R7 | System segmented pickers at 32pt where CSSegment exists | open · N4 (not in E's phase 1) |
| TPN-25 | P3 | R7 | Shaped targets drawn under 44pt | open · N4 (not in E's phase 1) |
| TPN-26 | P3 | R8 | Clash rows and score rails cut golfer and side names | open · N4 (not in E's phase 1) |
| TPN-27 | P3 | R8 | The live round cuts names and the course place | **fixed in part (6716b0ed: d27d3b6e, b9e42723)**: a live row wraps its name and breaks its facts on their separator. **Open:** the other live surfaces listed. |
| TPN-28 | P3 | R8 | Name rows cut long names | open · N4 (not in E's phase 1) |
| TPN-29 | P3 | R8 | Course names cut or clamped | open · N4 (not in E's phase 1) |
| TPN-30 | P3 | R8 | Two-line clamps on names at the accessibility sizes | open · N4 (not in E's phase 1) |
| TPN-31 | P3 | R8 | Names that can never wrap push past the measure | open · N4 (not in E's phase 1) |
| TPN-32 | P3 | R9 | Hand-rolled photo scrims with invented alphas | open · N4 (not in E's phase 1) |
| TPN-33 | P3 | R9 | Invented alphas standing in for the disabled and busy states | open · N4 (not in E's phase 1) |
| TPN-34 | P3 | R9 | Invented alphas and a material on tokens | open · N4 (not in E's phase 1) |
| TPN-35 | P3 | R10 | "vs course" in the composer | **decision X40** |
| TPN-36 | P3 | R10 | "vs course" on a trophy line | **decision X40** |

**Tally at `144ee0b0`:** 36 true positives.
- **fixed in part: 1.** TPN-27, by E's phase 1.
- **waiting on a decision: 4.** TPN-19 (Q36) and TPN-35/36 (X40) wait on one outright; TPN-17 waits on Q33 for its when-fork site.
- **open for N4 phase 2: 31.**

Session A also records three canon tensions the detector surfaced (DEC-N4-5, Q34 in OWNER-QUESTIONS).
