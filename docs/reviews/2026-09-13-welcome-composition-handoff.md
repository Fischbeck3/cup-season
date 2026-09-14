# The welcome composition, integrated — Claude handoff for Codex review

Date 2026-09-13. Answers `docs/reviews/2026-09-13-welcome-preview-correction.md`.
Branch **`claude/mobile-web-integration`**, worktree `~/cup-season-mobile-web-integration`.
Neither source branch was reset: it is checkpoint A (`claude/mobile-safari-experience`
at `343ffa1`) with the identity branch (`claude/d339-web-half` at `ebeaf91`) merged
on top (`458036b`), then one commit for the composition.

**Candidate: `8f85dac`.** Identity and repairs remain separate commits in its history.

## The one preview

| | |
|---|---|
| **Web preview** | **https://deploy-preview-3--cupseason.netlify.app** — Netlify deploy preview for [PR #3](https://github.com/Fischbeck3/cup-season/pull/3) (draft, not for merge). Read back at 18:41: `#obCaption` `v23 · 8f85dac`, `sw.js` `VERSION = '8f85dac'`. |
| Contains | MW-01 (Compete's creation control), MW-02 (Home on the phone), MW-03 (Compete rows) **and** the D339 identity with the complete welcome composition. |
| Live web | `https://cupseason.app` unchanged at `963d0e6`. Nothing promoted. |
| Native | no app change; build 857 archived from `963d0e6`; export still blocked on signing. |
| Backend | the same production Supabase project the live site uses; nothing written from the preview. Sign-in on the preview origin is real. |

`tests/brand-door-browser.js` was also run **against the preview origin** at 390: passed.
The white bar at the foot of every capture is Netlify's collaboration drawer —
preview tooling, not the product; it is also the source of the three report-only
CSP console lines on the preview origin.

## What was built (`8f85dac`)

| Brief item | Done |
|---|---|
| 1 · Fescue ground, visible terrain | bg0 is the fescue token already; the ember glow and radial wash are removed. The accepted `CSGolfTerrain` paths (`surrounds`, `edges` — what `CSTopoField(.page)` draws on the phone's door) are inline as one SVG, fixed under the door, anchored to the **upper right**, at least the drawing's own width so a phone crops the approach and keeps the green; `min(62vw, 900px)` on the desk. Hair-width strokes in `mut`: surrounds at **a24**, green and bunker edges at **a56** (UI_SYSTEM's own contour value on the credential) so they read at ordinary brightness. No gradient anywhere on the door (asserted). Paper light mode kept. |
| 2 · Smaller brand signature | `.ob-sig`: the generated pennant at 40×23 beside CUP SEASON in the name role, top-left. The central crest and the tracked serif wordmark are gone. Geometry unchanged (the beta pennant source). |
| 3 · Type hierarchy | ANY TIME. / ANYWHERE. in the **condensed display role** (`--board`, 42 / 64 on the desk), the one dominant statement; "Golf with your people, all season." in the **story role** (serif 21, mut); actions and legal in system sans. Asserted by computed family. |
| 4 · Intentional space | A left-aligned column: signature → statement → entry, the entry pushed to the foot of a tall phone by auto margin and simply next on a short one. `.onboard` stays `overflow:auto` with `min-height`, never a fixed height; verified at 390×560 and with the email field open. |
| 5 · Quiet, functional entry | Every control and flow untouched: Continue with email → field → 8-digit code (input still `maxlength=10`), I have a league code, Back, resend, terms, pending-invitation line, version caption. The secondary is a hairline button, same 46-tall target. Found and fixed: the join-code input's placeholder width pushed its Join button past a 320 viewport. |
| 6 · Static and immediate | The Forge — tracers, sparks, sears, fuse, stamp, `cs_forge` pre-paint switch, comet-head script, entrance delays on the hero/door/caption — removed, not layered under. Controls live at first paint; reduced motion has nothing left to reduce. |

## Evidence

`npm run preflight` — PASS, 0 failures, 0 warnings (BRAND-01 holds the door's copy
to `CS_BRAND`). Browser suites at 390 on the integrated tree: `brand-door`,
`compete-start`, `home-hierarchy`, `compete-rows`, `home-function`,
`after-golf-repairs`, `release-posting` (11, network disabled),
`league-setup` (20), `app-tests` (461) — all passed. `brand-door` additionally
at 320, 1440 and 390×560 (`tools/web-verify.mjs --height`, added).

**Before/after captures** (local, not committed — public repo):
`…/scratchpad/welcome/{before,after}/{w320,w390,w1440,short,light}` plus
`after/large` (body zoom 1.3 — the type roles are px, so text-size settings
do not scale them; 320 is the honest large-text proxy), `after/email` (the
field open at 390×560), and `after/fx-{home,compete,compete-sheet}` (the
functional fixtures on the same preview). What the after-captures show: the
signature top-left, the statement, the standfirst, the terrain's green and
bunkers upper-right with the approach contours running down the left, the
entry at the foot; on the desk the same column between the two wings with
the terrain at editorial scale behind the right wing; short and open-field
states keep the primary reachable; light mode on paper with ink strokes.

## Native parity disposition

| Surface | Phone | Web now | Discrepancy, named |
|---|---|---|---|
| Ground + terrain | `bg0` + `CSTopoField(.page)`: both weights at `mut·a24`, scaled to width/420, y +30 | same paths; surrounds a24, edges **a56**; anchored upper-right | the stronger edge alpha is deliberate for a non-retina ground; if the owner wants strict parity it is one number |
| Signature | `CSBrandMark` 112×64 leading, ink | pennant 40×23 + CUP SEASON name role | the web adds the name; the phone's mark is larger |
| Statement | `.lead` (serif 28) | `.cs-display` (condensed 42/64) | the brief chose the display role for the web; the phone's welcome uses the serif lead — a parity call for the owner |
| Entry | Get started / Sign in → one email flow | Continue with email / I have a league code | the web's one-step door, kept on purpose |
| Icons, favicon, og-image | pennant tile | Tracer | D339 open 2 |

## Not done, said plainly

- Actual iPhone Safari (safe areas, keyboard, VoiceOver, Dynamic Type) — Chromium only.
- A signed-in walk on the preview origin (needs a fresh code from the owner).
- Checkpoint B (MW-04/05/06) — next, on `claude/mobile-safari-experience`, then re-integrated here.
- Production keeps its door and mark until the owner approves this on a phone.
