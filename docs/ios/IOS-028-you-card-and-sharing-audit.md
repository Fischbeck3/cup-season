# IOS-028 · The You tab under the glass, and the sharing surface

*2026-09-01. Owner's ask: "a magnifying glass look at You, tour card (I want the
profile pic bigger I think), the settings button takes you to a page with another
settings button. Then look at our sharable items and look for opportunity on iOS.
What will make users want to add friends, share rounds, pictures, scorecards and
therefore share Cup Season."*

Review only — nothing here is built (CLAUDE.md rule 1). Every mechanic change
proposed in Part E needs a `spec/decision-log.md` entry before it ships (rule 5).

**Read:** `apps/ios/CupSeason/You/*`, `Settings/CardAndSettingsScreen.swift`,
`People/PeopleScreen.swift`, `Post/{EpilogueSheet,RecapCardView,FinishCeremonyView,PostScanSheets}.swift`,
`Live/LiveFinishViews.swift`, `Board/ScorecardSheet.swift`, `Rounds/RoundReceiptSheet.swift`,
`Events/MajorJugCard.swift`, `CupSeasonApp.swift`, `.well-known/apple-app-site-association`,
`netlify/edge-functions/share-preview.ts`, `index.html` (`.cred`, `openProfileHub`,
`csShareLink`, `renderShareView`), `supabase/migrations/20260722190000_public_shares.sql`,
`20260828160000_growth_events.sql`. Production counts in Part C are read-only queries
run 2026-09-01.

---

## Part A · The You tab and the Tour Card

### A1 · The face is 56pt on a screen whose whole subject is identity — and it is not a tap target

`YouHero` (You/YouHero.swift:45) and `CredentialCard` (You/CredentialCard.swift:36)
both draw `CSFace(size: 56)`. That is the same 56 the web uses (`index.html:14897`),
which is correct parity and wrong design: on the web the credential is a card
inside a scrolling page, on the phone it is **the one hero on a full screen**
(IOS-019 rule 1). Beside it sit a 20pt name, a 40pt serif index, a founding tag,
a meta line, an anchor line, a trophy chip rail and a form row. The face is the
smallest element on the card carrying the largest share of the identity.

The owner's instinct is right. Recommendation: **88pt on the You hero**, 72pt on
the Tour Card (the Tour Card is a sheet, not a screen, and its 150pt marker
watermark already carries weight). The marker badge rides at `size * 0.42`, so
88pt gives a 37pt badge — still legible, still the guaranteed floor D59 promised.

Worse than the size: **the face does nothing when tapped.** It is a bare `CSFace`,
not a `Button`. The most obvious tap target on the screen — the one every other
app on the phone has trained people to tap — is inert. See A3 for what it should do.

### A2 · The settings button opens a page whose right half is a settings button

Confirmed, on both clients, exactly as the owner describes:

- iOS: `YouScreen.swift:68` — a `gearshape`, accessibility label "Card & settings",
  pushes `CardAndSettingsScreen`. That screen opens on `pane = 0`
  (`CardAndSettingsScreen.swift:16`; `CSDevHatch.settingsPane` returns 0 in Release),
  which is **"Your card"** — the identity editor. The segmented control's other half
  is labelled **"Settings"**.
- Web: `#youProfile` → `openProfileHub()` (`index.html:15340`) → the same segment,
  the same default pane.

So: tap a gear → land on a form → tap a control labelled Settings → now you are in
settings. A gear means *settings* everywhere on iOS. It cannot land on something else.

This is not only a naming problem. The pane split was right in 2026-07 (one sheet,
two intents), but it put the card editor behind a glyph that does not mean "edit
your card", and it buried the single highest-value profile action four taps deep
(see A3).

**Recommendation — one change, three findings closed:**

| Door | Today | Proposed |
|---|---|---|
| ⚙ gear | → Card & settings, "Your card" pane | → **Settings** (the pane, alone) |
| Your card | nowhere — only behind the gear | **tap the hero** (face, name, or an "Edit card" affordance on it) |

The card editor becomes what it is: the thing you reach by touching your card. The
gear becomes what a gear is. The face becomes a tap target. The segmented control
disappears, and with it a screen that opens on the wrong half of itself.

*(If the owner prefers to keep the two panes: the minimum fix is that the gear lands
on `pane = 1`. That fixes the reported symptom and none of the rest.)*

### A3 · Nothing in the app ever asks for a photo — 1 profile in 39 has one

The card gate is three steps: name → marker → number (`Onboarding/CardGateView.swift:54`).
Step 2's subtitle says *"It's your face here until you add a photo"* — the app names
the photo, then never offers it. The only path to one is:

> You → ⚙ → (already on "Your card") → scroll past the 12-tile marker grid → "Add a photo"

Four taps and a scroll, behind a glyph that does not suggest identity. Production
result: **1 of 39 profiles carries a photo.** Twelve of the remaining 38 are the
default saguaro, three have no marker at all. The board (`RoundStoryCard.swift:51`)
renders these at 22pt, so a busy board is a column of small identical cacti — the
exact failure D174 flagged for the marker grid, one surface downstream.

The marker-as-floor decision (D59) is sound and should stay. But a floor is not an
ambition. Nothing on the You page, the board, or the Tour Card ever says "this could
be your face."

### A4 · The hero asks for the GHIN and not for the photo

`YouScreen.swift:189` — when there is no GHIN, the anchor line renders a live
"add your GHIN" link. GHIN is documented as an optional reference field that Cup
Season will never resell or verify (CLAUDE.md, Monetization). The photo is the field
that changes how every other golfer experiences the app. The hero prompts for the
one that does nothing and stays silent about the one that does.

### A5 · The Tour Card cannot leave the app

`TourCardSheet` has: buddy action, mute, report photo, career table, recent rounds,
a vs-you chip. It has **no share**. There is no `share` kind for a card
(`create_share`'s check constraint is `('round','settlement','recap')`), so there is
no public page for a golfer either.

This is the app's one object that is *shaped like a thing people post*: a face, a
name, a gold number, engraved trophies, a form row, on a fixed dark identity that
ignores the viewer's theme (D30). It is a trading card. It cannot travel.

---

## Part B · Every shareable artifact, both clients

| # | Artifact | Where it can be shared from | Web | iOS | Carries a URL | Logged to the funnel |
|---|---|---|---|---|---|---|
| 1 | Recap card PNG (round, 1080×1350) | epilogue sheet · finish ceremony — **only** | ✅ | ✅ | ❌ image + caption only | ❌ |
| 2 | Round share link (`?share=`) | epilogue sheet — **only** | ✅ | ✅ | ✅ | ✅ |
| 3 | Settlement card PNG (1080×1350) | live finish sheet — **only** | ✅ | ✅ | ❌ | ❌ |
| 4 | Settlement link (`?share=`) | live finish sheet — **only** | ✅ | ✅ | ✅ | ❌ iOS · ✅ web |
| 5 | Season recap link (`?share=`) | league pane | ✅ | ✅ | ✅ | ✅ |
| 6 | Major jug card PNG | the Major room | ✅ | ✅ | ❌ | ❌ |
| 7 | League invite (`?join=CODE`) | 5 places on iOS, wizard lock, members sheet, standings | ✅ | ✅ | ✅ | ✅ |
| 8 | Guest claim link (`?claim=`) — scan partner rows | post-scan partners sheet | ✅ | ✅ | ✅ | ✅ |
| 9 | Guest pencil link (`?claim=`) — live round | "Group phones" sheet | ✅ | ✅ | ✅ | ❌ |
| — | **Tour Card** | *nowhere* | ❌ | ❌ | — | — |
| — | **Scorecard** (the D92 card, gold on the decisive holes) | *nowhere* | ❌ | ❌ | — | — |
| — | **A trophy / an achievement** | *nowhere* | ❌ | ❌ | — | — |
| — | **Standings / where you stand** | *nowhere* | ❌ | ❌ | — | — |
| — | **A buddy invite** (no league needed) | *does not exist* | ❌ | ❌ | — | — |

Structural facts behind that table:

- **Rows 1–4 are a 30-second window.** Every round share lives in the epilogue sheet
  or the finish ceremony. `RoundReceiptSheet` (iOS) and `openRoundReceipt` (web) have
  no share of any kind. Dismiss the sheet and that round can never be shared again,
  on either client. 211 posted rounds; 3 round shares ever minted.
- **Every PNG share ships without a link.** `RecapCardView.shareItem` returns
  `[image, caption]`; `LiveFinishViews.shareCard` returns `[img, text]`;
  `MajorShareButton` is `ShareLink(item: image, message: caption)`. The card prints
  `cupseason.app` as *ink*. Nobody types ink. The image path — the one people actually
  use, because it lands in a group thread as a picture — is the one with no way back.
- **`?share=` is not a Universal Link.** The AASA claims only `?claim=` and `?join=`
  (`.well-known/apple-app-site-association`), and `onOpenURL` handles only those two
  (`CupSeasonApp.swift:34–36`). A recipient who already has the app gets Safari.
- **No App Store handoff anywhere.** `grep -r "apps.apple.com"` across `index.html`,
  `netlify/`, and `apps/ios/` returns nothing. `renderShareView`'s CTA is
  "Play this with your crew" → `/`, i.e. the web door, plus an "Installs like an app,
  no App Store needed" sheet. Every share link the phone mints sends a stranger to the
  PWA and never mentions the app the sender is holding.
- **The instrumentation is blind to the image shares.** `CSGrowth.log(.artifactShared…)`
  fires on the round link, the recap link, the scan claim, and five join links. It does
  not fire on: the recap card render, the settlement card, the settlement link, the jug,
  or the guest pencil. `claim_started` is never logged on iOS at all.

The infrastructure under all of this is genuinely good — a revocable token per
artifact, fail-closed `share_info`, per-token OG rewriting at the edge with a HEAD
check before pointing a scraper at an image, the photo and the settlement card
published to a public bucket at mint time. **The plumbing is finished. The taps are
missing.**

---

## Part C · What production says (read-only, 2026-09-01)

| | |
|---|---|
| Profiles | **39** (23 have posted a round) |
| Profiles with a photo | **1** (2.6%) |
| Profiles on the default saguaro | 12 · plus 3 with no marker at all |
| Posted rounds (not voided) | **211** |
| Rounds with a photo | **1** (0.5%) |
| Leagues | 13 |
| Board posts | 356 · of which **4** are chat |
| Buddy links | 22 total — **12 accepted, 10 still pending** |
| Shares ever minted | **7** (3 round · 2 settlement · 2 recap) |
| Live rounds settled | 5 |
| Scan claims ever minted | **0** |
| `growth_events` rows, all time | 9 (7 `first_round_posted`, 1 `artifact_shared/join`, 1 `link_opened/join`) |

Two of these deserve to be said plainly.

**Seven shares against 211 rounds is a 3% share rate on the app's core act.** Not a
copy problem. A *placement* problem: the only door is a sheet that closes.

**Zero scan claims.** IOS-004 ranks the claim link as "the product's strongest
acquisition path" and D36 built an Anthropic-vision scorecard reader to feed it. It
has been used zero times. Either nobody scans, or the partner rows never mint. That is
a separate investigation and it should be opened.

*(The growth funnel only began recording on 2026-08-31, per D185, so the 9 rows are a
one-day floor, not a history. The `shares`, `scan_claims`, `friendships` and photo
counts are all-time and real.)*

---

## Part D · The gaps, ranked

1. **The share window closes.** No round, settlement, or card can be shared after its
   moment passes. (Every "share more" idea downstream is worth nothing until there is
   a permanent door.)
2. **The identity object can't travel and the face is empty.** No Tour Card share, no
   public golfer page, no photo prompt, 1 photo in 39.
3. **Images travel without links.** The most-used share path is the one with no route
   back, no attribution, and no measurement.
4. **The buddy loop has no invite.** `PeopleScreen.swift:104` says it out loud in a
   comment: *"The link is the LEAGUE's join link, which is the only invite link that
   exists. A buddy-invite link is a different mechanic and would need a decision."*
   A league-less golfer — which every stranger arriving from a golf forum is — has no
   way to bring anyone. And 10 of 22 buddy requests are unanswered, so the requests
   that do get sent are landing softly.
5. **The scorecard has no export.** The single most screenshot-native object in golf.
   `ScorecardSheet` already renders it — gold on the holes the ledger says decided it —
   and there is no way to get it out.
6. **Strangers who land on a share page are never told the app exists**, and people who
   have the app get bounced to Safari.
7. **The scan-claim loop has never fired once.**

---

## Part E · Recommendations

Ordered by (impact ÷ cost). Each needs a decision-log entry before it is built.

### E1 · Make sharing permanent — put the door on the artifact, not on the moment · **small**
A share button on `RoundReceiptSheet` (and the web receipt), on `ScorecardSheet`, on
the Tour Card, on the settlement recap row in the board. Every artifact that can be
looked at can be sent. Nothing new is minted, nothing new is rendered — `create_share`
already returns the live token for a re-share, and `RecapCardView.render` already takes
a `PostRecap` the receipt holds. **This is the highest-return change in the document.**

### E2 · Every image share carries its link · **trivial**
`[image, caption]` → `[image, caption, url]`, everywhere: the recap card, the settlement
card, the jug. Mint the token first (it is idempotent per artifact), then hand the share
sheet all three. iMessage renders the image and keeps the link tappable. Log
`artifact_shared` on the same tap, so the funnel finally sees the path people use.

### E3 · The gear means Settings; the card is reached by touching the card · **small**
Per A2. Gear → Settings pane. Hero face/name → the card editor. Retire the segmented
control. Carry the same change to the web's `openProfileHub` so the two clients keep
telling the same story.

### E4 · Ask for the photo where the photo matters · **small**
Three placements, in order of expected return:
- **The hero, when empty:** the "add your GHIN" slot becomes "add your photo" when
  `photo_path` is null (GHIN keeps the slot once a photo exists). A4's inversion, undone.
- **The face is a button:** tap → photo picker when empty, card editor when set.
- **The card gate, step 2:** an optional "Add a photo" beside the marker grid, skippable,
  with the marker still the floor. The step already promises the photo in its subtitle.

Success metric is blunt and already measurable: profiles-with-photo above 2.6%.

### E5 · Bigger face · **trivial**
`CSFace(size: 88)` on the You hero, `72` on the Tour Card. Check Dynamic Type at the
accessibility sizes — `YouHero`'s `HStack` does not currently drop to `A11yStack`, and a
bigger face plus a wrapped name is the case that would show it.

### E6 · The Tour Card travels — a `card` share kind and a public golfer page · **medium**
A fourth `create_share` kind, `card`, referencing a profile; `share_info` returns the
same curated payload the Tour Card already renders (respecting `discoverable`, which
already exists); the `?share=` view gains a card branch; `share-preview.ts` gains a
`card` case so the link previews as the golfer, not as the brand. Then a "Share my card"
on the Tour Card and on You.

This is the artifact most likely to be posted *unprompted* — it is a golfer's number,
their trophies, their form, their face, in the brand's fixed dark identity. It is also
the one artifact whose recipient is guaranteed to be another golfer.

**Owner's call needed:** does a shared card show the *index*? The number is the most
personal thing on it, and CLAUDE.md's monetization line ("never resell the Handicap
Index") is about a business model, not about display — but a public page is a different
exposure from a league-visible one. Recommendation: yes, gated on `discoverable`, and
revocable like every other share.

### E7 · A buddy invite that does not need a league · **medium**
Closes the comment at `PeopleScreen.swift:104`. Two shapes:
- **(a) The card link is the invite.** E6's `?share=` card page gains "Add me on Cup
  Season" — the invite is the identity object, which is the thing worth sending anyway.
  No new mechanic, one new button.
- **(b) A dedicated `?buddy=` token** on the golfer, mirroring `?join=`.

Recommendation: **(a)**. It reuses E6 entirely, it gives the invite a face instead of a
code, and it means one artifact serves both "look at my card" and "add me" — which is
how every other social product does it. (b) is a second token surface, a second anon
endpoint, and a second thing to revoke, for the same outcome.

Also worth pairing: 10 of 22 buddy requests are unanswered. D177 gave the request a row
on Home; whether it also earns a push is a §7 curation question, not a build.

### E8 · The share page knows the app exists · **small**
`renderShareView`'s footer gains a second, quieter line: "Get Cup Season for iPhone" →
App Store, beside the existing "Play this with your crew". Add `?share` to the AASA and
to `onOpenURL` so a recipient who has the app opens the card natively instead of in
Safari. Both are gated on the app actually being on the store — until then, E8 is a
one-line placeholder and a note in the launch list.

### E9 · Find out why the scan-claim loop has never fired · **investigation**
Zero rows in `scan_claims`. Before more is invested in the claim funnel, establish
whether the scan is being used at all, whether partner rows are being detected, and
whether the mint is silently failing. Read `app_flags.scan` (kill switch and caps) first
— a tripped cap would explain it completely and costs nothing to check.

---

## What actually makes people share this app

The through-line of Parts A–D: **Cup Season built the artifacts and forgot the
occasions.** A 1080×1350 card rendered in the brand's own fonts, a revocable public
page, per-token OG tags rewritten at the edge — all of it real, all of it reachable
from exactly one sheet that closes after thirty seconds.

People share three things about golf: **their number, their card, and their beat.** Cup
Season has all three as objects and none of them as a door. The order to fix it in is
E1 (a permanent door), E2 (the link rides the image), E3–E5 (the face becomes a face),
then E6–E7 (the card travels and the card *is* the invite).

Nothing above changes a rule of the competition. Every item is a surface, a link, or a
tap target.

---

## Status — what shipped, 2026-09-01

The owner ruled all three calls in one line ("B, A, A. Build it!") and the build
followed in the same session. Logged as **D186** (`spec/decision-log.md`, the
mechanics) and **IOS-029** (`docs/ios/DECISIONS.md`, the surface).

| Item | State | Where |
|---|---|---|
| E1 · a permanent share door | **built** — round receipt, both clients | `RoundReceiptSheet.swift`, `openRoundReceipt` |
| E2 · every image share carries its link + logs | **built** — recap card, settlement card | `csShareToken`, `RecapCardView.shareItem(url:)` |
| E3 · the gear means Settings, the card is a door | **built** — both clients | `YouRoute.card`, `openProfileHub('settings')` |
| E4 · ask for the photo | **built** — hero anchor, tappable face, photo leads the editor | `YouScreen`, `refreshWhoChip` |
| E5 · the bigger face | **built** — 88pt / 88px | `YouHero`, `#youMk` |
| E6 · the card travels (call 2 · A) | **built** — `card` share kind, public page, OG case | `20260901120000_share_card.sql`, `share-preview.ts` |
| E7 · the card is the invite (call 3 · A) | **built** — `share_buddy`, "Add me on Cup Season" | same migration, `renderShareView` |
| E8 · App Store handoff + `?share=` universal link | **built** — the phone renders a shared card, so the link is safe to claim | see D188 |
| E9 · why `scan_claims` is zero | **answered** — D187: not a defect, an unopened door | `20260901140000_round_source_scan.sql` + breadcrumbs |
| Scorecard PNG export | **not built** | needs a card renderer, its own pass |

**E8 and E9 followed in the same session** (owner: "Now do E8 and E9") and are
logged as **D188** and **D187**, with IOS-030 recording the pair. Both of E8's
blockers were cleared rather than worked around: the phone renders a shared card
now (`SharedCardSheet`), which is what makes `?share=` safe to claim, and the
store CTA hangs off `door_flags()` so it stays invisible until there is a
listing. E9 turned out not to be a defect in the loop at all — 92 composer opens
since the scan shipped and 0 invocations — but it exposed two real ones:
`source` was hardcoded `'quick'` on both clients, and every scan breadcrumb
fired too late to answer the question. Both fixed.

The scorecard PNG export remains the one item from this audit not built.
