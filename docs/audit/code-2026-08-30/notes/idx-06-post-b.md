# idx-06-post-b — `index.html` 6500–7458 (the rest of the post composer)

Read: every line of 6500–7458 (`postInputs` · `renderPostHoles` · `recalc` · the
post-draft mirror · the `#postBtn` submit · the photos/scan arc · `resetPostComposer`
· `attachCourseSearch` and its two call sites · the live 9/18 picker).
Cross-checked against: `spec/decision-log.md` (D34, D72, D122, D123), `spec/spec-v1.0.md`
§2.1/§2.2/§16, `supabase/migrations/00000000000000_initial_baseline.sql`
(`rounds` DDL, `score_round`, `v_rounds_ranked`), `20260718045514_photos_scan_spine.sql`
(`create_scan_claim` / `claim_scan_round`), `20260718174500_ugc_safety.sql`
(`rounds_no_future`), `supabase/functions/scan/index.ts` (the scan output schema).

## What is right

- **The Q-22 rating guard works for the rating.** A blank rating with a gross
  entered lands in the early return at `6584–6589`, sets `state.lastPost=null`,
  and Post is dead. Both early returns in `recalc` null `lastPost`, so there is
  no stale-preview path into the insert. ✅
- **The Q-21 date guard works.** `6753–6764` blocks an empty date, marks the
  field `aria-invalid`, scrolls it into view and logs `post_blocked`. The
  server's `rounds.played_on` NOT NULL is no longer the only gate.
- **Future dates are server-blocked** by `rounds_no_future` (`played_on >
  current_date + 1`), and its sentence survives `humanError`'s gauntlet
  (`looksLikeOurSentence` passes it), so a future date reads
  "Post failed. A round date can't be in the future". Not a bug — only a wasted
  round trip; `#inDate` has no `max`.
- **9-hole halving agrees with the engine.** Client `Math.ceil(base[0]/2)`
  (6608) vs the view's `ceil(cup_points(...)::numeric / 2)::integer`
  (baseline `:1362`). Same rounding, same direction. ✅
- **The delegated course-search retry fires and cannot double-fire.** One
  `mousedown` listener on `dd`, attached once per `attachCourseSearch` call,
  before `dd` is inserted; `ev.preventDefault()` keeps focus on the input so the
  blur-hide never races it. `closest('[data-csretry]')` matches the `<b>` inside
  the button. ✅
- **`openSheet` writes title/sub with `textContent`**, so the course name in
  `openPostParsSheet`'s subtitle is not an injection sink. Every user string in
  the scan sheets goes through `esc()`.
- **The scan payload is shape-safe** — `arr18()` in the edge function guarantees
  exactly 18 ints for `holes` and `par_row`, so `scanApply` cannot produce a
  short `state.post.scores`.

## Findings (11 bugs, 5 opportunities)

### B1 · P1 — the preview scores at 100 %; the engine scores at the league allowance (default 95 %)
`6594` / `6606`: `vs=state.myIndex-diff`. `v_rounds_ranked` computes
`round(index_at_post * handicap_allowance / 100.0 - differential, 1)` and
`league_settings.handicap_allowance` **defaults to 95**. Index 12.4, 84 gross at
71.5/125: preview `vs = 1.1` → **9 pts, "You beat your number by 1.1"**; server
`pvi = round(11.8 − 11.3, 1) = 0.5` → **7 pts**. The board card the golfer lands
on renders the server's `pvi`, so the contradiction is visible seconds later.
Already decided as **D123** ("the preview included") and unbuilt; `CS.settings`
is the whole `league_settings` row, so the number is already in memory.

### B2 · P1 — everything after the successful insert runs inside the `catch → "Post failed."`
`try {` at `6791`, `} catch(e){ toast(humanError(e,'Post failed.')); }` at `6940`.
`await window.loadStandingsAndFeed()` (6925), `finishCeremony(...)`,
`switchView('home')`, `renderFeed()` — all inside. `loadStandingsAndFeed` has no
try/catch of its own and calls `memName()` (the F-007 landmine), `renderClimb`,
`renderStandings`, `renderPot`, `renderBylaws`, `renderFeed`. Any throw there,
**after the round is in the database**, tells the golfer the post failed — the
exact behaviour the pilot already reported ("entered a second round thinking the
first failed"), now producing a real duplicate that scores twice.

### B3 · P1 — a blank slope previews at 113 and posts as `null`
`6576 const slope=parseFloat($('#inSlope').value)||113;` vs
`6787 const slope=parseInt($('#inSlope').value)`. The `||113` runs *before* the
Q-22 guard, so `!(slope>0)` can never be true for a blank field — that half of
the guard is dead. Type a rating off the scorecard, leave slope blank, enter the
nines: the panel shows real points; Post sends `slope: NaN` → JSON `null` →
`rounds.slope` NOT NULL → "Post failed. That didn't go through — please try
again." with no field marked. Identical to the Q-21 loop that was just fixed for
dates.

### B4 · P1 — a 9-hole scan mints partner claims as 18-hole rounds
`6871 slope: payload.slope, played_on: payload.played_on, holes: 18,` — hard 18,
while the poster's own `payload.holes_played` is `nine ? 9 : 18`. `7127
p_holes: ctx.holes||18` → `claim_scan_round` inserts `holes_played=18,
nine_rating=null` and scores `(45 − 71.4)·113/125 = −23.9` for a partner's
9-hole 45. That is 12 points and a −23.9 differential poisoning their
auto-handicap. Second half of the same line: `rating: payload.rating` is a
*9-hole* rating whenever `state.post.rating9` is true, and the server halves it
again (`case when v_nine then c.rating / 2`).

### B5 · P2 — retyping the same query kills the course search
`7308 if(q.length<3 …){ hide(); return; }` does not reset `lastQ`;
`7309 if(q===lastQ){ return; }`. Type "tpc" → results; backspace to "tp" → the
list hides; type "c" → `q === lastQ` → early return, no search, no dropdown, no
message. The golfer must type a *different* string to get search back. This is
the same "dead search says nothing" failure Q-24 set out to close.

### B6 · P2 — a late search response re-opens the dropdown after the golfer has moved on
`7206 hide = () => { … dd.dataset.stage=''; }` and `7274 const fresh = () =>
lastQ===q && dd.dataset.stage!=='tees';`. Picking a tee calls `hide()`, which
clears the stage back to `''`; the still-in-flight `courses` invoke then passes
`fresh()` and calls `showCourses()`. `.coursedd` is in normal flow
(`max-height:230px`), so a 230px list inserts itself between the course field and
Rating just as the golfer reaches for Rating — the tap lands on a course button,
replacing the picked course. Same on plain blur.

### B7 · P2 — "Enter at least one nine first" is the wrong sentence for a missing rating
`6750 if(!state.lastPost){toast('Enter at least one nine first');return;}`.
Since Q-22 nulls `lastPost` for a missing rating/slope, the nines *are* entered
and the panel says "Pick a tee — or type the rating and slope", while the button
blames the nines.

### B8 · P2 — the post-card draft is not scoped to the account
`6645 const POST_DRAFT_KEY='cs_post_draft'` — one global key, and no sign-out
path clears it (`$('#phOut')`/`$('#wOut')` do `signOut()` + reload). A drafts a
round, signs out; B signs in on the same phone; `restorePostDraft()` (module
boot, `18214`) restores A's gross/course/date into B's composer and toasts "Your
unposted round came back". B posts A's round on their own card.

### B9 · P2 — "Start over" leaves the composer in 9-hole mode
`7145–7165 resetPostComposer()` resets values, mode, scores, touched, scan —
but not `state.post.side` or `state.post.rating9`, which the post-success reset
*does* (`6914`). After a 9-hole card is scrapped, the next round's form still
reads "9-hole gross" with the back-nine box hidden, and posts at half value.

### B10 · P2 — 19 × 19 px steppers are the scan-confirm surface
`6556–6560` emits `<button data-phm>−</button> … <button data-php>+</button>`;
`index.html:980` sizes them `width:19px; height:19px` with a 3px gap. That grid
*is* the confirmation surface for every scanned card (`scanApply` flips
`mode='holes'`), so correcting the model's misread is an 19px target next to
another 19px target — well under 44px, and §16 says the receipt stores what the
golfer confirmed.

### B11 · P3 — `rating9` is cleared one event *after* `recalc` reads it
`6634` registers `recalc` on `#inRating`; `6638` registers the
`state.post.rating9=false` listener on the same element. Listeners run in
registration order, so a single input event (a paste, or one backspace) previews
with the *old* flag and then flips it — the panel's points and
`state.lastPost.pts` are computed against a 9-hole rating while the payload
sends `rating/2`. Self-corrects on the next keystroke; a paste-then-Post does not
get one.

### O1 · no plausibility bounds on rating/slope
`6576`/`6787` accept any positive number. A rating typed as `715` instead of
`71.5` previews "You torched your number by 639.0" and posts cleanly
(`numeric(4,1)` holds 715.0, no CHECK). Bounding rating to 55–80 and slope to
55–155 in the composer would also close B3 for free.

### O2 · the date is not reset after a successful post
`6911–6919` clears F9/B9/course/rating/slope but not `#inDate`, and the draft is
cleared, so nothing restores today. Post a scanned card dated three weeks ago,
then post tonight's round: it silently carries the old date. `resetPostComposer`
already has the one-liner that puts today back (`7151–7154`).

### O3 · the course-cache reads drop `{error}`
`7355`, `7360`, `7396`, `7403`: `const { data: tees } = await …` /
`const { data: holes } = await …` with no `error`. A missing grant or a schema
change makes "real pars never load" indistinguishable from "this course isn't
cached", permanently and silently. Same at `7018` (`app_flags`, fails closed —
acceptable) and `6936` (`round_epilogue`, whose comment claims the `catch` covers
a missing RPC; supabase-js does not throw, so `epi` is `undefined` and the
`catch` only fires on `showEpilogue`'s own TypeError).

### O4 · "the link is on screen to copy by hand" — it isn't
`7133 catch(err){ toast(humanError(err, 'Could not make the link.')); …}`. A
clipboard denial produces "Could not make the link. Copy didn't work — the link
is on screen to copy by hand." Both halves are false: the claim WAS minted
(`p._token` is cached) and the link is never rendered in that sheet. Print the
`/?claim=` URL in the row on a copy failure.

### O5 · a failed insert orphans an uploaded photo
`6812–6819` uploads to `media/${user.id}/${uuid}.jpg` before the insert. If the
insert then fails (B3's blank slope, a gross out of range), the object stays and
each retry adds another. Nothing in the composer deletes it.

## Cross-range notes (root outside 6500–7458, effect inside)

- `14901 state.myIndex = Number(m.index_current);` has no `!= null` guard (unlike
  `13522`), so a member with a null index makes `state.myIndex === 0` and
  `recalc` previews every round as a scratch golfer's.
- `recalc` reads `state.myIndex` rather than `CS.profile.index_current`; the
  server snapshots `index_at_post` from `profiles` at insert time. Two producers
  for one number (D123's lens rule would collapse them).
- The demo/local-echo fallback at `6944–6965` is reachable by a real signed-in
  user whenever `window.sb` is missing — the documented silent-demo landmine. It
  fabricates a board row and awards points to "Mudsharks". Known; not re-filed.
