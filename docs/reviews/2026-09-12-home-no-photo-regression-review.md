# Regression review — bee364a and de338d8

**2026-09-12 · read-only.** Both commits live on `codex/home-no-photo-2026-09-12`.
Nothing here was changed; the branch is Codex's. Findings are ranked, and each
is marked CONFIRMED (the code path was traced end to end) or PLAUSIBLE (it
looks wrong and could not be fully verified without running it).

Scope reviewed: the full diffs of both commits, `HomeWire.swift`,
`HomeView.swift`, `HomeDigest/HomePage/HomeWireCopy.swift`, `index.html`,
`tests/app-tests.js`, `tests/home-function-browser.js`, `tools/web-verify.mjs`,
`tests/preflight*`, and the authors' own notes in
`docs/reviews/2026-09-12-home-no-photo.md` and `…-home-function-audit.md`.

---

## 1 · CONFIRMED — a photo row renders as a text slat while it loads, and again every time it is recycled

`apps/ios/CupSeason/Home/HomeWire.swift:85-94` (de338d8).

```swift
AsyncImage(url: photo) { phase in
  if let image = phase.image { band(image) } else { HomeWireSlat(...) }
}
```

The baseline drew a fixed-height `bg1` placeholder, so a photo row was 168pt
from first paint. Now the **loading** phase renders the whole no-photo slat —
course, gross, story — and then swaps to the 168pt band when the image arrives.

`AsyncImage` does not cache. Scroll a photo row off screen and back and it
reloads, so the row collapses to slat height and grows again, moving everything
under it. On a cold or slow network the first Home paint is a column of text
rows that then reflows.

**Trigger:** any Home feed holding at least one round with a photo.

**Second effect, on the tests.** The loading slat carries
`accessibilityIdentifier("home.round.no-photo")`, so that identifier no longer
means "this round has no photo". `HomeNoPhotoTests` matches it in both states,
which is why the suite stays green.

The author's note concedes "image arrival can change native row height". It
does not mention the recycling case or the identifier collision.

---

## 2 · CONFIRMED — the whole name row opens the golfer on the phone and the round on the web

`HomeWire.swift:160-174` makes the header a full-width `Button(action: openPerson)`
with `Spacer(minLength: 0)`, `.frame(minHeight: 44)` and
`.contentShape(Rectangle())`. Everything from the face to the right edge now
opens the tour card. Before, only the 38pt face did.

The web did not follow. `index.html:15868-15871`: the card itself is
`role="button"` opening the round, and only `.hfperson` — the face — is a
button for the golfer. The name sits in a plain `<div class="hfid">` inside the
card button.

**So the same tap on the same round goes to two different places depending on
the client.** That is the D234 rule ("one product, two shapes") failing on a
destination, which is the half that is supposed to be shared. Neither commit
message nor review doc mentions the change.

---

## 3 · CONFIRMED — the web leaves the `+` control visible after the reactions expand

Native `HomeWire.swift:262-270` is `if open { rest } else if !rest.isEmpty { plus }`
— the `+` is replaced. The web's `homeRxChipsHtml` emits the chips, the
`data-hreact` button **and** a hidden `.hrx-options` span, and `wireHomeSocial`
only unhides the span. The expanded web row therefore shows four chips plus a
lingering `+`.

`tests/home-function-browser.js` counts `[data-hrx]` only, so the new browser
test cannot see it.

---

## 4 · CONFIRMED — "Course not recorded" is visible-only; the spoken sentence still says "a round"

`HomeWireCopy.swift:28` still computes `let course = r.course ?? "a round"`, and
the slat's `accessibilityLabel` is `"\(name). \(roundLine(row))"`. A screen
reader hears *"Sam. 84 at a round."* while the screen reads **Course not
recorded**. The web has the identical split: `aria-label="… at ${course}"` at
`index.html:15868` against `Course not recorded` at `:15875`.

Both clients diverge the same way, so this is one copy fix in the shared
producer, not two.

**Trigger:** any round with a null or empty course. *(Relevant: 4 of 5 plans
and a material share of rounds carry no course id in production.)*

---

## 5 · CONFIRMED — a milestone with no gross survives on web photo cards and vanishes on web record cards

In `index.html`'s `feedRow`, the story branch still renders `milestone`
("Personal best"), while the record branch goes through `homeRoundDetail`,
which returns `''` when `r.gross` is null. The same round shows the milestone
with a photo and nothing without one. Native is consistent — both paths go
through `roundDetail`.

The "do not assert a milestone without the figure behind it" rule was applied
to one of the two web branches.

---

## 6 · PLAUSIBLE — `wireHomePhotos` re-enters `renderHomeFeed` synchronously

`if (img.complete && img.naturalWidth === 0) failed();` calls `renderHomeFeed()`
from inside `renderHomeFeed()`. The outer call then runs its split-flap arming
(`if (box.querySelector('.sfc:not(.go)')) { sfGo(box); window._sfRid = null; }`)
against DOM the inner render has already replaced, so the arrival animation can
be armed twice or dropped.

**Trigger:** a broken photo URL already in the HTTP cache on the just-posted
round. Not reproduced.

---

## 7 · PLAUSIBLE — cosmetic: the gross column lost its minimum width on native only

The web keeps `.hfrecord .hfgross{min-width:62px}`; the native slat dropped the
old `.frame(minWidth: 62, …)` along with the `dynamicTypeSize` leading/trailing
swap. Columns of two- and three-digit scores no longer align.

---

## Categories checked and clean

- **Preflight baselines.** Every entry moved **down**: LINT-06 1195→1193,
  LINT-09 29→24, LINT-10 258→254, LINT-12 36→35, LINT-14 143→141, and
  `preflight.mjs`'s `BELOW_11` 78→67. Nothing rose, so no new violation is
  hidden behind a raised number. This is the ratchet working as intended.
- **`tests/app-tests.js`.** No assertion was weakened to mask a code bug; each
  changed expectation was checked against the shipped `index.html`. The one
  deleted test (Y-08) exercised `formRowHtml(rec, caption)`, whose `caption`
  argument has been ignored since IOS-047 — it was asserting against code that
  no longer exists. Residual gap worth an inbox line: `caption` / `CS_FORM_KEY`
  is now a dead parameter that nothing asserts.
- **`tools/web-verify.mjs`.** Strictly stricter — eval exceptions now enter
  `bad` and force a non-zero exit. It cannot pass where it previously failed.
- **Null and optional handling.** One new force-unwrap,
  `URL(string: "data:image/png;base64,invalid")!` at
  `HomeNoPhotoFixture.swift:28`, inside `#if DEBUG` and statically non-nil. No
  new array indexing.
- **DEBUG paths in Release.** Clean. The fixture is wholly inside `#if DEBUG`,
  the `RootView.swift:93` overlay sits inside the existing guard, and
  `tests/home-function-browser.js` is not referenced by `index.html`.
- **Blank or duplicated rows.** No blank case found. The digest dedupe was
  traced on both clients and nothing orphans. One residual, low: a fresh round
  landing ninth or later in a bucket sits behind the `CAP=8` expander while the
  digest has already yielded it, so its only mention is collapsed.

---

## Suggested order for Codex

1 and 2 are the two that change what a golfer sees and where a tap goes. 4 is a
one-line fix in a shared producer. 3 and 5 are web-only and small. 6 wants a
repro before anyone touches it. 7 is cosmetic.
