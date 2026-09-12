# Inspection of `b61024d` — Home review follow-through

**2026-09-12 · read-only.** Codex's fix commit on
`codex/home-no-photo-2026-09-12`, reviewed against my `079a67f` findings and
re-run independently. Codex's branch and workspace were not edited.

**Verdict: five of five confirmed findings are genuinely fixed, and I
reproduced every number Codex reported.** One new finding, one behaviour worth
a ruling, and one coordination problem that will bite at merge.

---

## Independent verification

Run by me, in a detached worktree at `b61024d`, not in Codex's workspace.

| Check | Codex reported | I measured |
|---|---|---|
| Native, `CupSeasonKitTests` + `HomeNoPhotoTests`, iPhone 17 Pro, parallel off | 1,096 passed, 0 failed, 0 skipped | **1,096 passed, 0 failed, 0 skipped** — `xcresulttool` summary |
| `HomeNoPhotoTests` actually ran (not filtered out) | implied | **confirmed present and passed**, including the new `missingCourseIsSpokenAsMissingInsteadOfARound()` |
| Home browser flow at 390px | passed | **`{"passed":true}`**, 0 console errors |
| Home browser flow at 320px | passed | **`{"passed":true}`**, no horizontal overflow |
| `tests/app-tests.js` at 390px | 461 assertions, 0 failures | **`{"total":461,"failures":[]}`** |

Nothing was overstated. The counts match exactly.

---

## Findings 1–5: all fixed, and the fixes are right

**1 · Loading no longer renders a text slat.** `HomeWire.swift:86-100` now
splits three ways: success draws the band, `phase.error != nil` draws the
record, and loading reserves `cs.bg1.frame(height: 168)`. The geometry is
stable at 168pt through load, recycle and reload, so the scroll-position jump
is gone rather than merely rarer. The distinct identifier
`home.round.photo-loading` also un-collides `home.round.no-photo`, which had
started matching in both states. Checked the call site: `photo` is a
non-optional `URL` and `HomeView.swift:381` guards with `if let url`, so a
missing photo still takes the record path and the grey block is unreachable
for a null URL.

**2 · Destinations agree, on the record row.** The face is now its own 44pt
button to the golfer; the name opens the round, matching the web, where the
card is `role="button"` and only `.hfperson` is the golfer. See the new finding
below for the state this did not reach.

**3 · The web plus is gone on reveal,** and the CSS addition
`.hrx .hreact[hidden]{display:none;}` is necessary rather than belt-and-braces,
because `.hrx .hreact{display:inline-flex}` would otherwise beat the `[hidden]`
default. Focus moves to the first choice, which prevents the focus loss that
hiding the focused button would otherwise cause.

**4 · Missing-course copy.** Both clients now trim whitespace and say "Course
not recorded" visibly *and* in the spoken record. I diffed the two producers
string by string: `HomeWireCopy.roundLine` and `homeRoundLine` agree on all
four branches, and `roundDetail` / `homeRoundDetail` agree on every sentence
including the trailing full stops. No divergence introduced.

**5 · No milestone without a score.** The web now guards both `pviN` and
`milestone` on `r.gross != null`. Native already had
`guard r.gross != nil` in `roundDetail` — untouched by this commit, so native
was correct before and stays correct.

**6 and 7** are correctly left open with reasons, not silently dropped.

### Tests: no assertion was weakened

The `HomeNoPhotoTests` edits adapt to the new labels and, in the second test,
tap the name rather than the record body — which is coverage of the new
destination rule, not a loosening. `record.waitForExistence` and
`record.isHittable` are retained. The new Kit test asserts exact full
sentences over `nil`, `""` and `"   "` with and without a gross. The browser
test gains four genuine assertions. Nothing became conditional.

---

## New finding · the destination fix reached two of a photo row's three states

> **CORRECTION, 2026-09-12.** This finding is **wrong** and Codex was right to
> reject it. `b61024d` already carries
> `.accessibilityAction(named: Text("Open golfer"), openPerson)` on the **loaded**
> band at `HomeWire.swift:154`. I read the band's body to line 152 and stopped
> one line short of the modifier I was claiming was absent. VoiceOver has always
> had a route to the golfer on a photo row. **What survives** is the smaller
> half: the face was a bare `.onTapGesture` under the 44pt target its sibling
> states had, and Codex has since given it one. The accessibility claim should
> not have been made.


**CONFIRMED.** Severity: moderate. Accessibility and tap target, not data.

A photo row has three states, and this commit treated them differently:

| State | Golfer target | VoiceOver route to the golfer |
|---|---|---|
| Loading (`HomeWire.swift:93-100`) | — | **yes** — `.accessibilityAction(named: Text("Open golfer"), openPerson)`, added here |
| Failure → record (`:170-180`) | **44pt Button**, `"Open golfer card: \(name)"`, added here | yes |
| **Success → the photograph** (`:126-152`) | `CSFace(size: .list)` with a bare `.onTapGesture`, **≈38pt, unlabelled** | **no** |

The loaded band ends with `.accessibilityElement(children: .ignore)` followed
by a single `.accessibilityLabel("\(name). \(line)")`. Ignoring children
discards the face's tap gesture as an element, and no `.accessibilityAction`
replaces it. So **on the most common state of a photo row there is no VoiceOver
route to the golfer card at all**, and the touch target is under the 44pt
minimum the sibling states now meet.

Two things make this worth fixing rather than noting:

- **The loading placeholder is more accessible than the loaded photo.** That
  inversion is new, and it came from this commit adding the action to one state.
- **The web photo card already does it properly** —
  `<button class="hffacew hfperson" aria-label="Open golfer card: …">` around
  `face(..., 44)` (`index.html:15864`). So the client divergence my finding 2
  reported still stands on photo rows; it was closed on record rows only.

`.accessibilityElement(children: .ignore)` is pre-existing, so the band was
never accessible here. This is not a regression from the baseline. It is an
incomplete fix, and the commit's own stated goal was destination consistency.

**Suggested fix:** give the band the same `.accessibilityAction(named:
Text("Open golfer"), openPerson)` the loading state now has, and a 44pt
`contentShape` on the face. Both are additive and neither disturbs the scrim
layout.

---

## Worth a ruling · the web reveal is now one-way

Before, the plus toggled. Now it hides itself, so an opened row can only be
closed by choosing a reaction, which re-renders via `toggleHomeRx` →
`renderHomeFeed()`. I traced that path: the row does collapse on selection, so
the behaviour matches native's rule, quoted in `HomeWire.swift:263-271` from
the owner's own words — *"When I click + for emotes they reappear lets keep
them hidden with exception to when one is selected."*

So this is right. Two residues:

- **A revealed row with no choice made cannot be collapsed** until something
  re-renders the feed. Native behaves the same way, so the clients agree; the
  question is whether "reveal, change your mind, no way back" is the intended
  end state on both. It is a product call, not a defect.
- **Focus is destroyed on selection.** `renderHomeFeed()` replaces the DOM, so
  the focus this commit carefully placed on the first chip is lost the moment
  the chip is used, sending a keyboard user back to the top. Pre-existing, but
  the commit now handles focus on reveal and not on use, which is a visible
  asymmetry. Small and worth a follow-up rather than a revert.

Minor: `aria-expanded="true"` is set on a button that is hidden in the same
statement, so it can never be read. Harmless, but it can go.

---

## Coordination · `spec/inbox.md` will conflict at merge

`git merge-tree` against the common ancestor reports **`changed in both`** with
a real conflict marker in `spec/inbox.md`. Both branches appended a dated
section to the same region. It is the only overlapping file; `docs/reviews/`,
the Swift and the web changes are disjoint.

The tandem agreement says shared files need an identified owner before edits,
and we both edited this one. Not a defect in either commit, and trivial to
resolve — **both sections are wanted and neither supersedes the other, so the
resolution is to keep both, mine above Codex's, and delete the markers.**
Flagging it so it is resolved deliberately rather than by whoever merges first.

Decision-log numbering is clean: my catch-up used D331–D339 and Codex's
follow-through amends D340–D342. One note — the amendments are a `####`
sub-heading rather than `### D<n>` entries, so a reader grepping the file's
own convention for `### D3` will not find them.

---

## Not raised as findings

- The story card's visible copy now says "Course not recorded" where it said
  "a round". Unflagged in the commit message but consistent with the record
  card and with finding 4's intent.
- The native photo band visibly prints `roundLine`, so a course-less photo
  round now reads "84. Course not recorded." on the image, while the web story
  card reads "Course not recorded · Sep 12". Different sentences, both
  truthful, both from their own client's producer.
- A genuinely stalled image (no success, no error) leaves a blank grey 168pt
  block indefinitely. The accessibility label still carries the round, so the
  content is not lost to VoiceOver. Same as the pre-`bee364a` behaviour.

---

## Handoff

- **Branch and commit:** `claude/after-golf-audit`, this commit. Codex's
  `b61024d` was read, never edited.
- **Built or reviewed:** reviewed.
- **Verification:** native 1,096 / 0 / 0 reproduced via `xcodebuild test` in a
  detached worktree with its own derived-data path; `HomeNoPhotoTests`
  confirmed present in the result bundle; web flow re-run at 390 and 320px and
  `app-tests.js` re-run at 390px against a locally served copy of `b61024d`.
  Production untouched.
- **Findings still open:** the photo band's golfer action and tap target (new,
  mine to hand over, Codex's to fix); the two reveal residues; the
  `spec/inbox.md` merge conflict.
- **Database / Edge / client deploy owed:** none. TestFlight remains held.
- **Next owner and bounded task:** Codex, for the photo-band accessibility
  action and the 44pt face — both additive. The after-golf contract still waits
  on the four owner rulings in `2026-09-12-after-golf-contract-review.md` §4.
