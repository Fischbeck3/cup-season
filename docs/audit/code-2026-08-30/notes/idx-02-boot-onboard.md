# idx-02 · `index.html` 2494–3763 — theme pre-paint, the door, view markup, the error handlers

**Read:** every line of 2494–3763 (`sed -n '2494,3763p'`). Cross-read for call-site
judgement: `.hdr`/`.mini`/`.check`/`.onboard` CSS (160–2490), `openEmailBox` +
`#obBack` + `joinGo` + `pfSave` (13380–13700, 15800–16150), `loadCareer` /
`indRows` (15200–15270, 17300–17360), `installNudge` (13378–13412),
`stamp-version.sh`, `netlify.toml`, `cup_points()` / `set_index()` /
`set_profile()` in `supabase/migrations/`.

The slice is two small classic scripts (2494–2528 theme pre-paint, 3668–3724 the
global error handlers + SW registration) wrapped around ~1200 lines of static
markup: the SVG sprite, the onboarding door, and every `<section class="view">`
skeleton. Session hunks (34d20b6..HEAD) that land inside it: the `obJoin`/`wJoin`
copy, the two "Avg vs your number" stat tiles, the draft backlink (Q-11),
`inRating`/`inSlope`/`inF9`/`inB9` placeholders (Q-22), `#calcSeason`,
`#lockErr`, the `ih-floor` rewrite (D14), `#payHow` (D129), and the
`#installNudge` relocation (Q-13).

## What I checked and cleared

* **Theme pre-paint (2499–2517).** `applyTheme` reads `cs_theme`, defaults
  `'dark'` (D76 — verified from the code, not the comment), maps `'auto'`
  through `prefers-color-scheme`, sets `dataset.theme`, `style.colorScheme` and
  the `theme-color` meta (which does exist, line 6). The `matchMedia` change
  listener re-reads the pref, so an explicit choice is never clobbered by a
  system flip. Correct.
* **Error handlers (3690–3715).** They keep the 4-frame stack and the
  `bootStep` — and `bootStep` *is* reachable from classic scope: the module
  bridges it with `Object.defineProperty(window,'bootStep',{get})` at 18135,
  so the `typeof bootStep!=='undefined'` guard resolves the live value rather
  than a permanent `null`. `qaEvent` is a top-level `function` declaration in
  classic block 3 (6497), so its `typeof` guard also holds. CLAUDE.md's claim
  survives review.
* **`CS_DEBUG` (3673–3679).** `/[?&]debug(?!=off)/` correctly excludes
  `?debug=off`, and the `else if` ordering means `debug=off` clears the
  localStorage flag before it is read back. Correct.
* **`legal.html`** (linked from the door's consent line) **is** in
  `stamp-version.sh`'s dist allowlist, so the Terms/Privacy links are not the
  404 the D37 allowlist rule warns about.
* **`#obCaption`** carries the untouched `__CS_VERSION__` placeholder. Left
  alone (rule 2).
* **`#obCodeIn maxlength="10"`** is not the 6-digit landmine, and reviewer mode
  explicitly `removeAttribute('maxlength')` before asking for a password
  (15964) — that trap is already closed.
* **`#lockErr hidden`** (new this session) is safe: `.fine` sets no `display`,
  so the UA `[hidden]{display:none}` still wins, and `lockErr()` sets
  `textContent` before flipping `hidden`.
* **`#lrCourse value="Encanto GC" / 70.2 / 123`** looks like a fabricated tee
  waiting to be posted, but `primeRealRoster()` blanks all four fields for a
  real account (7922) — demo scenery only. Not a bug.
* **`#installNudge` show path** sets `display:'flex'`, matching the inline
  `align-items:center`. Correct.
* **`.check` rows** are ~60px tall, so the guide rows meet the 44px floor —
  their problem is keyboard, not size.

## Findings (11)

See the structured report. The headline is **IDX02-01**: the golfer card's
optional index field is the one index entry point in the app with *no* range
guard on either side of the wire, while the You-tab editor and `set_index()`
both enforce −10..54. A missing decimal point (`124` for `12.4`) writes
`index_current = 124.0`, `score_round()` snapshots it into `index_at_post`, and
`v_rounds_ranked` pays `cup_points(124×0.95 − differential)` = 12 on every
round until the engine establishes at three. Those rounds are immutable (§16)
and their points feed the Points King's 15% of the pot.

Next in weight: **IDX02-02**, this session's own Q-13 fix. Moving
`#installNudge` from `bottom:76px; z-index:60` to `top:safe-area+8px;
z-index:24` got it off the ⊕, but `.hdr` is `z-index:20`, so the banner now
lands exactly on the header row and eats `#hdrSearch` and `#hdrLogo` instead.
Same bug, new victims.

Then **IDX02-03/04**: two screens that state a scoring rule the engine does not
follow — the new "across counting rounds" captions over averages computed across
*all* rounds, and the static Point-bands card that still promises 7 points at
exactly −1.0 (the very boundary the session's Q-20 commit unified everywhere
else) and hardcodes "best 4" against a cap dial that offers Best 2 / 4 / 6 /
Unlimited.

## Cross-range causes worth someone else's slice

These are real, but their root lines are outside 2494–3763:

1. **`csHideInstallNudge` resurrects a dismissed nudge** (13395–13399).
   `dismiss()` sets `cs_nudge_done` and `display:none` but leaves `shown=true`;
   the next `switchView` out of a BUSY view runs `else if(shown) n.style.display
   = 'flex'`. Tap ✕, open the live round, come back — the banner is up again,
   forever, on every view change.
2. **`#obBack` never hides `#obResend`** (15838–15845). The `#obJoin` handler
   *does* (16010). Request a code, tap ← Back, and a bare "Resend code" button
   sits on the door with no code box; tapping it fires another OTP.
3. **`#obBack` is created once and never re-anchored** (15834–15850).
   `openEmailBox` moves `#emailbox` to a new anchor on every call, but the
   `if(!back)` guard leaves the Back button stranded at the previous anchor —
   visible on the email→join→email path.
4. **`joinGo` drops `{error}` and reports the wrong cause** (16052–16055).
   `try { const { data } = await sb.rpc('league_by_code', …); name = data; }
   catch(e){ name = undefined; }` — supabase-js never throws, so an undeployed
   or ungranted RPC yields `data:null`, `name === null`, and the golfer is told
   "No league with that code — check with your Pro". The comment's stated
   degrade-to-`undefined` path is unreachable.
5. **The guest-live door misses enterApp's background-tab net** (8464). It adds
   `.hide` without the `display:none` kill, and `body.guestlive` (which would
   force `display:none`) is only added when `!signedIn`. A signed-in golfer
   opening a group-live link in a background tab keeps a `visibility:visible;
   opacity:0` overlay at z-index 50.
6. **`CS.reviewerMode` is never cleared** (15962). Once armed, `#obCodeIn` stays
   `type="password"` and `#obCodeGo` keeps the password branch even if the
   reviewer backs out and types a normal address.
7. **`.mini` has no `min-height`** (855–859): ~38px, under 44. Every other
   control class in this file is explicitly floored at 44 (414, 456, 489, 1198,
   1218, 1238, 2054), which makes `.mini` look like an oversight rather than a
   density choice. It is the class on `#nudgeX`, `#calPrev/#calNext`,
   `#bfClose`, `#hhAdd`.
8. **`loadCareer` caps at `limit(400)`** (17318) with no indicator, so "Rounds
   posted / All time" silently plateaus at 400.

## Not reported (deliberate, per spec / decision log)

* Multiple simultaneous `aria-modal` dialogs — `#onboard` hides via
  `visibility:hidden` (plus `enterApp`'s `display:none` net), which removes it
  from the a11y tree.
* The `<svg style="display:none">` sprite — that is the standard pattern, and
  `href=` (not `xlink:href`) on `<use>` is fine on every browser this ships to.
* `postMode` hidden rather than deleted — D34 says so explicitly, with a
  restore note.
* `<div class="title" style="display:none">` in the header — the comment says it
  is kept so existing setters never null-ref. Only its `<h1>` is a finding.
