# Cup Season — the inbox

**What this is:** the one place a follow-up goes when there is no session to
build it in. Started 2026-09-09, when the owner said he would be away and asked
where to drop notes.

**Why it is a file and not a conversation.** Notes dropped in a chat live in
that chat. Resume it and they are there; start a fresh session next week and
they are gone, and neither of us finds out until the thing is forgotten. This
file is in the repo, so it is pushed, versioned, readable from a phone through
GitHub, and picked up by any session — including one that knows nothing about
the session that wrote it.

**How to add:** one line is enough. A fragment is enough. *"the epilogue feels
long"* is a usable entry — deciding what it means is the work, and that is the
half you should not have to do from a phone. Put it under **Raw** and stop
thinking about it.

**What happens to an entry.** It gets read, checked against the code (most
"problems" are already fixed, already ruled on, or two problems), routed to a
lane from `session-tracks.md`, and given a size and a first question. That
turns a list into a session with a plan instead of a session that starts by
sorting.

> **THIS REPO IS PUBLIC.** Product and engineering follow-ups belong here.
> Anything with a real person's name, money, legal exposure, or league
> politics does not — say it in the session instead, and it goes in the private
> memory. The same rule that keeps `renders/` and `docs/audit/ship-2026-08-31/`
> out of the tree.

---

## Raw — drop anything here

**2026-09-09, from the owner:**

> I searched a course and it was not found so I input the rating/slope/pars.
> Went to schedule a round and that info didn't pull and searched the course
> "Oak Quarry" again and it was not found again. This should be saved and maybe
> we need a "we don't have that course in our database, enter its info"

> I noticed this before but I scheduled a round, since I created it I should
> auto be "opted in"

*Both were investigated the same day. They became **four** items — 11 and 12 are
the two reported, 13 and 14 are things found while looking. Left here as
written, because the words a bug is reported in are worth keeping next to what
it turned out to be.*

**2026-09-09, later:**

> I entered the pars slope rating etc in a live round as well and it seems to
> have not saved

*Confirmed, and it is the sharpest of the three — see item 15. Together with 12
they name a pattern rather than three bugs.*

**2026-09-10:**

> Another note. I played Oak quarry and didn't see the prompt to add a photo.
> Idk where the course rating should come in "First time playing Oak Quarry give
> it a rating" or "back at Oak quarry. How has it held up" - maybe the course
> rating doesn't fit our vision, if it does it needs to be organic and seamless

*Two things, and they turn out to be one surface — items 16 and 17.*

**2026-09-10, later:**

> photos I post have a little cactus icon in bottom right corner. Not sure why

*It is not your marker — see item 18. Yours is the azalea. The cactus is a
silent fallback firing, and the fact that you did not recognise a mark whose
whole job is attribution is the second half of the finding.*

*Item 11 was filed wrong the first time and corrected the same hour: I wrote
that the empty `courses` table was an oversight nobody had wired up. It is not.
D150 retired it and the owner ruled there that free-typed courses stay demoted,
naming "invisible to course history forever" as the accepted cost. The report is
that cost being paid. **A decision is not a bug, and calling one a bug is how a
ruling gets quietly reversed by somebody who never read it.***

---

## Yours, not mine

Things no session can do, because they need an account, a person, or a ruling.

| | Item | Notes |
|---|---|---|
| 1 | **John has never accepted his TestFlight invite** | INVITED, not INSTALLED, unchanged for weeks. Jade and Galen are both on 762. Nothing in the product fixes this; he needs a nudge from you. |
| 2 | **Consider rotating the App Store Connect key** | The issuer and key ids were pasted into a chat transcript on 2026-09-09. Neither is the signing secret — the `.p8` is — so this is hygiene, not an incident. Rotating means a new key in Users and Access, the new `.p8` into `~/.appstoreconnect/private_keys/`, and re-storing the key id. Both scripts pick it up with no edit. |
| 3 | **The derived-name profiles are a prod-data decision** | Some production profiles carry a display name derived from an email localpart, created before either client guarded against it. **The count needs re-taking with the real rule** (`OnboardingGate.isDerivedName`) — a quick approximation on 2026-09-09 returned a different number than the note from 2026-09-04, which means one of them is measuring the wrong thing. Renaming somebody is not the app's to do; the humane form is a prompt that ASKS, and that is a build. The decision to build it is yours. |

---

## Open — found and verified, not built

Each of these was confirmed in the code on the date given. None is a guess.

| | Item | Lane | Size | The first question |
|---|---|---|---|---|
| 4 | **The eight-week streak is the weakest mark in the epilogue column.** `CSTrophyMark.streakMark` divides a fixed box into `n` ticks, so eight at 18pt are hairlines beside the four-week's chunky four and the twelve-week's doubled block — three marks of one family at three weights, adjacent for the first time. On a 28pt shelf they are never neighbours and it does not exist. *(2026-09-09, D330 gate; crop at `renders/streak-marks-crop.png`)* | UX | S | It is a weight problem **in the component**, and the component also draws the trophy case, which you have already approved. Fix it there and the case moves too. Is that acceptable, or does the epilogue need its own size? |
| 5 | **Comments do not exist on Home, and did not before the wire either.** `post_comments` is drawn by three surfaces and all three are league boards — so a golfer may react to a round on Home and never say a word about it, and a golfer with no league has no board to go to. Same wall D238 knocked down for reactions and never knocked down for comments. *(IOS-076; you chose to give it its own wave rather than bolt it on)* | Social | **L** | It needs a thread on the wire, a write path, and the reporting surface the board already has. Is this the next wave, or does it wait behind something? |
| 6 | **Embedding a post's author will break both clients.** `posts` has two foreign keys to `profiles` (`profile_id` + the `hidden_by` audit column), so an unqualified PostgREST embed returns PGRST201. Nothing embeds it today — verified across both clients, netlify and the edge functions — so it is a trap, not a bug. `profile_id` exists precisely so a post can be homed on a person, which is what makes it likely somebody writes that embed. *(2026-09-09, D327; accepted by name in db-checks 18)* | Growth/Ops | S | When it happens: name the relationship (`profile:profiles!posts_profile_id_fkey(...)`), or drop `posts_hidden_by_fkey` first — D199's rule is that when a pair is reduced the AUDIT key goes and the semantic one stays. |
| 7 | **The web still says "league code".** `index.html:4001` is a button reading *I have a league code*, and the phrase is in four more places. LV-14 is explicit that a league is never a thing you join — the container is a SEASON. The phone was fixed; the desk was not. *(re-verified 2026-09-09)* | UX | S | Straight copy pass, or does the word "code" itself need re-thinking on the door? |
| 8 | **`HomeWire.swift:91`'s tap seal is inherited, which is the fragile kind.** The band's photograph overhangs its 168pt frame and is capped by a `contentShape` at line 128, one level up. That line reads like a *"make the transparent parts tappable"* idiom, which is exactly how it gets deleted — and deleting it reopens D301 on the Home feed. *(2026-09-09, D328)* | UX | XS | A defensive `contentShape` after line 91 is one line and free. Worth it, or is the comment enough? |
| 9 | **`Person.swift:635-641` is the same bug class with nothing marking it.** A `GeometryReader` under a fixed `.frame(height:)` does not clip, and its child may be taller. There is no `.clipped()` there to make it findable by grep. The neighbour below is drawn later and is safe today. *(2026-09-09, D328)* | UX | XS | Safe today is a fact about today's layout, not about the view. Shape it, or leave it named? |
| 11 | **A hand-entered course is not saved — but the first thing to rule out is that the course was never missing.** ~~The table meant to hold it is empty and was never wired up.~~ **I filed that this morning and it is wrong, and the correction matters more than the original entry.** The `courses` table's zero rows are not an oversight: **D150 RETIRED it** (*"retires the use of `courses`/`course_tees` without dropping them"*) and the owner ruled there that **free text is kept but DEMOTED** — *"typed text still posts … but is marked an unlisted course and does not feed course history or discovery"*, with *"free-typed rounds stay invisible to course history forever unless someone re-picks them; **that is the accepted cost of not guessing**"* stated as the tradeoff. What has now been reported is that accepted cost being paid by the owner himself. That is a legitimate reason to revisit a ruling. It is not a gap to quietly fill. **AND THE PROXIMATE CAUSE IS PROBABLY NOT ABSENCE.** Both client readers hard-drop any course with no rated tees (`ScheduleService.swift:148` and `:160`), and the edge function only back-fills tees for the **first three** bare courses per search (`supabase/functions/courses/index.ts:216`). A course ranked fourth or later comes back with `tees: []` and is dropped silently — **indistinguishable from "no such course."** Measured on prod 2026-09-09: **12 of 115 cached courses (10.4%) have no tee rows and are invisible to search today**, and they are already in the catalogue. Oak Quarry Golf Club is a real, well-known course. *(prod: `courses` 0 rows · `api_courses` 115, none matching Oak Quarry · his plan carries `course_label` "Oak Quarry" and a NULL `course_id`)* | Gameplay | **M** | **Prove the filter first — it may be the whole bug, and it needs no new table.** Only if Oak Quarry is genuinely absent upstream does storage become the question, and then the question is provenance: differentials already compute from the round's OWN hand-typed rating and slope, so a per-golfer course adds no correctness risk that does not exist today. A SHARED course is different in kind — one golfer's wrong tee becomes everyone's pre-fill, silently, which turns a self-inflicted error into a contagious one. Which of those three you want is yours to rule. |
| 13 | **The empty state names an action the screen cannot perform.** All three course pickers and the web show *"No match — type the course, rating and slope by hand."* On the composer that is true. **On the declare sheet there are no rating or slope fields at all** (`DeclareRoundSheet.swift:40-119` renders Day, Tee time, Course, Note, Name, Game, Forfeit, Tags — and the same sentence at `:314`), and the web omits them too (`index.html:26949`). So the one place the owner went looking told him to do something impossible. **LINT-21 does not reach this**: the lint is enforced through the `CSEmpty` type's declaration, and these dropdown states are raw `Text`, so a door was never required of them. *(2026-09-09)* | UX | S | Two fixes and they are independent: make the sentence true per surface, and decide whether the schedule sheet should gain the fields or should stop claiming it has them. |
| 14 | **The app already remembers his rating and slope, in a lane he was not in.** `PostService.courseMemory` keeps the last 30 labelled rounds deduped to **three** chips of `label · rating/slope` — but only in the composer, never in the schedule sheet or live setup, and **only while the search field is EMPTY** (`PostRoundScreen.swift:323,326`). The moment he typed "Oak" to search, the chips vanished and the dropdown said *No match*. *(2026-09-09)* | UX | S | Widening this existing memory into the dropdown's empty state, and into the other two pickers, delivers most of what the report asks for with **no new table and no new trust surface** — and it sits inside D150's ruling rather than against it. Worth doing before anything structural. |
| 12 | **Creating a plan does not seat you on it, and both clients say it did.** `declare_round` writes NO row to `round_rsvp` — verified against the deployed function source, not the migration. So the host is left with no RSVP, Home then offers them *"Say you're in"* about their own round, and **both clients toast *"You're in — it's on both boards"*** the moment it is created (`DeclareRoundSheet.swift:226`, `index.html:26983`). The copy asserts a state the server never wrote. *(prod, 2026-09-09: his Oak Quarry plan was created 19:51:19 and his own RSVP landed 19:52:18 — **58 seconds later, as a separate act**. A plan from 2026-09-01 still has its host unseated.)* | Social | S | Seat the host inside `declare_round` — one insert, and the toast becomes true. The only real question is the status: `in` is what the copy already promises, and it is what he did by hand a minute later both times. Worth checking whether a host who then says "out" on their own round is a state the schedule handles. |
| 15 | **A live round's card is never saved until you tee off, and the app says it was.** Typing pars, rating and slope in live setup calls `LiveRoundStore.saveCard` (`:489`), which writes to **in-memory state only** — `LiveCourseCard.save` is a `mutating func` on a value type (`LiveModels.swift:273`) — and then toasts ***"Card saved: every league gets it from here."*** Nothing has left memory. `persist()` (`LiveRoundStore.swift:653`) refuses to write to disk while `state.lr` is nil, which it is until tee-off, and the card reaches the server only as `live_rounds.course_snapshot` at tee-off (`LiveModels.swift:282`, *"the snapshot shipped at tee-off"*). **Back out, get interrupted, or never tee off, and every figure typed is gone.** *(prod, 2026-09-09: **no live round exists for today at all** — the newest is 2026-09-01 — so nothing he typed was ever written anywhere)* | Gameplay | S | The toast is the part that is indefensible regardless of the fix: it should not say "saved" for something held in memory. Whether setup should also snapshot to disk before tee-off is the real question, and it is the same question as the composer's 24-hour draft — which does persist, and which discards pars anyway. |
| 16 | **A plan whose day has passed is never asked about, so the photo prompt he expected was never reachable.** He planned Oak Quarry for 2026-09-09 at 16:30, played it, and saw nothing. **The photo prompt is not broken — it lives inside a post he never made, and nothing invited him to make one.** `home_dispatch` looks at plans **only in the window `today … today + 8`**, so the moment a tee time passes the plan drops off Home entirely; the function mentions photos nowhere. There is no nudge kind for it either — production holds exactly three (`nudge`, `request`, `rsvp`). **The plan loop has no closing act.** *(prod, 2026-09-10: the plan is `play_on 2026-09-09`, and no round at Oak Quarry exists on any surface)* | Social | **M** | This is the missing moment the other notes keep pointing at: a played plan should ask *how did it go*, and that one surface is where the score, the photo and — if it ever exists — the course opinion all belong. Does it live on Home, in a push, or both? |
| 17 | **A course opinion might fit, but it CANNOT be called a "rating."** His own framing (*"First time playing Oak Quarry give it a rating"* / *"back at Oak Quarry, how has it held up"*) is a review — an opinion of the course. **In this product "course rating" already means the USGA number that drives every differential**: `rounds.rating`, the figure `post_round` bounds to 25–90, the thing he has spent two days typing by hand, and the words the empty state uses (*"type the course, rating and slope by hand"*). Shipping a second, unrelated "rating" would make one word mean two things on the same object — the exact failure D326 fixed for the fire glyph, in the vocabulary rather than the marks. *(2026-09-10)* | Business | — | **This is a vision question and it is yours, not a bug.** Three sub-questions worth separating: (a) does an opinion of a course belong in a product whose thesis is *real golf, your crew* rather than a review site — his own *"maybe it doesn't fit our vision"* deserves a real answer before any design; (b) if yes, what is it CALLED, since "rating" is taken and "score" is worse; (c) his *"organic and seamless"* has an obvious home now — item 16's missing closing act, asked once on the way past rather than as a form. |
| 18 | **The cactus on his photos is not his marker — it is a silent fallback, and it is showing the wrong golfer's identity.** `CSMarkers.marker` is documented as *"The floor. Unknown or nil → The Saguaro"* (`Markers.swift:38`), so **any nil key draws a cactus and nothing says so.** **His profile marker is `azalea`; his `league_members.marker` is NULL** (prod, 2026-09-10). The receipt's stamp is fed from a LEAGUE-MATES lookup — `AlbumScreen.swift:78`, `marker: r.profile_id.flatMap { mates[$0]?.marker }` — which is nil for him, so it floors to the Saguaro. **The same file already knows the right answer sixty lines further down**: the share artifact reads `r.marker ?? store.me?.profile?.marker ?? ""` (`RoundReceiptSheet.swift:269`) while the stamp above it passes `r.marker` bare (`:208`). So his shared card carries the azalea and his own screen carries a cactus. | UX | S | The one-line fix is the fallback the artifact already uses. The wider question is whether a stamp should read a per-league override at all when the golfer has no league — D59 introduced that override, and this is the first surface where its absence is visible. |
| 19 | **A mark whose entire job is attribution has no label anywhere, and its author did not recognise it.** D59 put the marker on round photos as *"attribution + brand"* — the poster's credit, and the marker's second job so it would not become a relic when photos took over identity. **It carries no caption, no tooltip, and `accessibilityHidden(true)` in BOTH implementations**, so VoiceOver does not explain it either. There is no channel in the product that says what it is. The owner — who made the decision — asked what it was. *(2026-09-10)* | UX | S | On your OWN photo, attribution is redundant; you know who took it. It earns its place on somebody else's round in a feed. Is the credit worth keeping where it is, worth moving to where it answers a real question, or worth a label? |
| 20 | **One mark, three implementations, already drifted.** `MarkerStamp` (`SliceComponents.swift:282`, glyph **15**pt, `cs.ink`, `cs.bg0` ground), `RoundStoryCard.medallion` (`:130`, glyph **16**pt, `onPhotoInk`, `CSDusk.ground`), and the web's `.mkstamp` CSS (`index.html:1363`). Same 26pt circle, same 0.55 ground opacity, three sources of truth — and the phone's two already disagree by a point. *(2026-09-10)* | UX | XS | Pure L-34. One `CSDesign` component, three call sites, and the drift closes itself. Worth folding into whichever of 18 or 19 gets built. |
| 10 | **The wizard's headcount chips wrap 7 + 1, orphaning `12+`.** The row is a `FlowLayout`, which is what keeps it safe at the accessibility sizes; pinning it to a grid to kill the orphan trades a cosmetic nit for a clipping risk at AX3. *(carried from D-earlier; re-check before building)* | UX | XS | Is the orphan worth an AX3 risk? Probably not — this may be a "close it as won't-fix" entry. |

---

## The pattern under 12, 14 and 15

Three of these are one shape: **the product tells a golfer something is kept
when it is held in memory, or not held at all.**

- Declaring a plan toasts *"You're in — it's on both boards"* and writes no RSVP (12).
- Saving a live card toasts *"Card saved: every league gets it from here"* and writes nothing anywhere (15).
- The composer keeps his rating and slope and then hides them the moment he types (14).

Each is small alone. Together they are why a golfer stops trusting that anything
he enters survives — which is a worse problem than any one of the three, and an
argument for doing them as one wave rather than three fixes.

**And item 16 is the other half of the same story.** Everything he typed went
nowhere partly because he never finished a post — and nothing ever asked him to.
A plan he made, played, and was never asked about is the moment where the score,
the photo and the course's shape would all have been captured at once. Fixing
the three "we said saved and did not" bugs without giving that moment somewhere
to happen fixes the symptom and leaves the hole.

---

## Closed since this file started

*(nothing yet)*

---

## Where this connects

- `spec/session-tracks.md` — the five lanes an item routes into.
- `spec/decision-log.md` — why a mechanic is the way it is. An item that
  contradicts a decision is not a bug report until that decision is read.
- `docs/ios/DECISIONS.md` — what was actually built, and its gate.
- `CLAUDE.md` — architecture, the landmines, and the current state.
