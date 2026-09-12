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

**2026-09-10, with a screenshot of Home:**

> Before I added a photo for this round at Oak Quarry it just had that bland
> "1 round" tagline. We need to be bold with postings even absent of images

*Item 21. The line he quoted is the DIGEST, not the round row — and the digest
says less when there is more to say.*

**2026-09-10, a direction note:**

> Each round needs to be a card IMO. With a photo great if not we need the score
> card and absent of that we need something to keep it interesting. Maybe cap 3
> per section; today, this week and last week. Consistency across cards, clarity
> moving from card to course and succinctness in working back through them.
>
> Post a new round at a course -> friend sees the round/rating/picture and
> schedules a round at the course directly from the course homepage. Day of the
> round a round is posted it needs to sync with that scheduled round. Maybe even
> (if one goes to post a round in that same day) -> live round -> "are you teeing
> it up at XXX course?" If so that info is preloaded and the round starts

*Items 22-24. **The fallback ladder he describes already exists verbatim as
§10.1** and is built — it just never reaches the feed.*

***A CORRECTION TO WHAT I TOLD HIM ON THE 10th.*** I said a course rating was
&ldquo;specified in the brief with the view built and no producer.&rdquo; **Rating a
course is SHIPPED.** `course_ratings` exists (`20261007090000`, keyed
`api_course_id` + `profile_id`), `RateCourseSheet` exists, and `CSRating` is on
the course screen, the courses screen and the scheduled-round sheet. **Prod holds
one rating, on one course, by one person.** What is missing is not the feature —
it is that the only way to reach it is a course page you can barely get to (item
27), and that a rating never travels with a round (item 26). `HomeWire.swift:297`
still says *&ldquo;the product has no ratings table at all&rdquo;*; that comment
is stale and predates the migration.

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
| 21 | **The digest counts when it could narrate, and it is worst exactly when there is news.** *"1 round."* is `HomeDigest.make`'s `.since` branch: `bits.append("\(freshRounds.count) round…")` (`HomeDigest.swift:109`), joined and given a full stop. For one ordinary round — not a personal best, not a sub-80, not a first — the whole sentence is the count. **`HomeDigest.line()` sits twenty lines above it and narrates properly** — *"You posted 84 at Oak Quarry"* (`:85-91`) — **and is used only on the QUIET branch.** So a round posted since your last visit gets *"1 round."*, and the same round seen on a quiet day gets a sentence with who, what and where. **It is worse in two more ways:** the digest computes `label: "Since you were here"` and the renderer draws **only `d.body`** (`HomeView.swift:420-422`), so the count arrives unlabelled; and `.since` sets `roundId: nil`, so unlike the quiet line **it is not even tappable** — no door, which is the one thing LINT-21 exists to prevent. *(2026-09-10, from his screenshot)* | UX | S | `line()` already exists and already handles the PR / sub-80 / first-round cases. The question is only what a MULTI-round digest becomes — one sentence about the best of them, or a count that earns its place by leading to something. |
| 22 | **&ldquo;Each round needs to be a card&rdquo; is NOT a reversal of the brief — but it does collide with the brief's other half.** `BRIEF.md` §6 is *&ldquo;stop using cards as the DEFAULT UI&hellip; cards should indicate **meaningful conceptual boundaries**, not simply separate every piece of content&rdquo;* — a round is such a boundary, so a round-object is squarely inside the rule. What Wave 9 deleted was `CSCard` as the default wrapper (157 call sites to zero; `LINT-30` is zero-tolerance and `CSCard` no longer exists). **The real collision is with §7 of the same brief**: *&ldquo;Do not make every feed item visually equal&rdquo;*, which is the whole reason the wire has five weights and no containers. *&ldquo;Consistency across cards&rdquo;* pulls the other way. *(2026-09-10)* | UX | **L** | Both can hold only if the card has internal weights — one object whose shape is constant and whose loudness is not. The decision is whether a round always looks the same, or whether a personal best is allowed to be bigger than a Tuesday 92. |
| 23 | **The photo → scorecard → something-interesting ladder is already law, already built, and does not reach the feed.** §10.1 is exactly his three rungs: **rung 1** a golfer's own round photo credited in agate, **rung 2 the DRAWN CARD from real par, stroke index and yardage**, **rung 3 the contour** — and with none of the three, *&ldquo;no image at all, the space collapses, which is honest and better looking than a placeholder.&rdquo;* It is `CSDrawnCard` (`CSDesign/Course.swift:31`), and it **refuses to draw when it has no real card to draw from** because *&ldquo;fake data as ornament is less premium than a plain colour&rdquo;* — three blind reviewers, three sentences. **It is used on the scheduled-round sheet, the course screen and the courses screen. It is used NOWHERE on Home** — the feed's no-photo round goes straight to a slat with no image, skipping rungs 2 and 3. *(2026-09-10)* | UX | S | The gap is small and the component is built. The only real question is whether rung 2 on a FEED row is the course's shape or the round's own scores — see the caveat below, they are not the same thing and only one of them exists. |
| 24 | **&ldquo;The scorecard&rdquo; is two different objects and only one of them has data.** The COURSE's shape lives in `api_course_holes` — **17,019 hole rows**, well populated, and it is what `CSDrawnCard` draws. The ROUND's own hole-by-hole scores live in `round_holes` — **8 rounds, 135 rows, out of every round ever posted.** So a drawn card under a photo-less round is buildable today off the course; a real per-hole scorecard of that round is available almost never. **And rung 2 needs the course to be in the catalogue**, which is item 11 — Oak Quarry would show no image at all under the ladder as written. *(prod, 2026-09-10)* | Gameplay | S | Which one did he mean? If the course's shape, it ships now. If the round's scores, it needs the post paths to start writing holes first, and that is a much bigger change than a feed treatment. |
| 25 | **On &ldquo;cap 3 per section; today, this week and last week&rdquo;: no cap exists, and one of the three sections does not.** The wire's periods are `ahead` / `today` / `week` / `earlier` (`HomePage.swift:37`) — there is **no &ldquo;last week&rdquo;**, everything older than this week falls into `earlier`. Nothing is capped anywhere. **And a period holding ONE row gets no head at all** (D321, deliberately — a head for a single sentence was two of them shouting on his own Home), which is why his screenshot shows a bare *&ldquo;1 round.&rdquo;* sitting where a dateline would otherwise be. *(2026-09-10)* | UX | S | A cap needs a door — three shown, and the rest reachable — or it is silently hiding rounds. And D321 is the entry to read before giving a one-row group its head back. |
| 26 | **THREE OF HIS FOUR LINKS ARE ALREADY BUILT. Link 1 is the one that is genuinely missing, and it is the smallest.** A feed row carries `course: String?` and **no course id** (`Rpc.swift:741-757`) — so nothing on Home, the board, a round card or a receipt can open a course, because the row does not know which course it is. The sentence is composed from the label (`HomeWireCopy.swift:27-47`). *&ldquo;Clarity moving from card to course&rdquo;* is blocked on one missing field, not on a design. *(2026-09-10)* | UX | S | Put `api_course_id` on the feed row and the board round, and card→course becomes a door rather than a project. |
| 27 | **The &ldquo;schedule a round from the course page&rdquo; door EXISTS — in a branch that hides it.** `CourseScreen.swift:361-362` is `Put it on the plan` → `DeclarePrefill(course:courseId:)`, and it is **the only site in the app that seeds a plan from a course.** It lives inside `neverKept` (`:355-370`), the branch for a course this phone has never kept and cannot draw — **so on a course the page actually renders, the door is unreachable.** The page even knows about plans and says so as prose: *&ldquo;On your schedule · Sat&rdquo;* (`:449-451`). That is a sentence, not a control. **And there is no course page on the web at all** (`switchView` has no `course` branch). *(2026-09-10)* | UX | S | Moving one door out of one branch is most of link 2. The web having no course page is the bigger half and its own decision. |
| 28 | **Link 3 is genuinely absent: nothing ties a posted round to the plan it was played on.** `rounds` has no `scheduled_round_id`; `scheduled_rounds` has no `round_id`, no `played` flag, no status. `post_round` never mentions a plan; `declare_round` never looks at `rounds`. The only join between them anywhere is `my_course_books`, an aggregate **per course** — which is what makes the course page say *&ldquo;On your schedule&rdquo;* — never per round. **The plan just ages out of the today→+8 window and is never spoken of again.** *(2026-09-10; this is item 16's missing closing act, seen from the data side)* | Gameplay | **M** | One nullable column and a reconcile in `post_round` is the whole mechanic. **And the notification kind already exists**: `push_nudges` admits `tee_tomorrow` and the client routes it — **no function in the repo has ever inserted one.** |
| 29 | **Link 4 &mdash; &ldquo;are you teeing it up at XXX?&rdquo; &mdash; is BUILT on the live path, and shallow.** `LiveSetupView.swift:67-78` already draws the plan bridge: ***&ldquo;Your round today · Gold Canyon&rdquo;*** / *&ldquo;Load the course and your group into the round · with Galen &amp; Dev&rdquo;* / `[Load it]`, fed by `LiveRepository.todaysPlan()`. **But `loadPlan` copies the course LABEL string and matches players by lowercased NAME** (`LiveRoundStore.swift:419-433`) — no `course_id`, no tee time, no rating, no slope, no tee, and `sr.id` is never read, so the round still does not know which plan it came from. **The web is worse**: its bridge never sets `dataset.courseId`, so a plan-loaded live round posts with a **null course id and no tees** (`index.html:12671-12699` vs `:13365`). **The composer has no bridge at all** — `PostRoundModel` never reads the schedule. *(2026-09-10)* | Gameplay | S | The affordance he asked for is on screen today. Deepening what it carries is small; giving the composer the same bridge is the other half. |
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

**AND THE WIDER PATTERN, WHICH IS NOW FOUR DEEP: the app already contains the
good version of almost everything he has reported, one branch away.**

- `courseMemory` holds his rating and slope, shown only while the search box is empty (14).
- The share artifact falls back to the right marker; the stamp sixty lines above it does not (18).
- `HomeWireSlat` — the no-photo round row — is documented as *"the majority case today, and it must be beautiful"* and is genuinely rich: face, name, sentence, rule-and-figure.
- `HomeDigest.line()` narrates, and runs only on the quiet path (21).
- §10.1's photo → drawn card → contour ladder is built and reaches the course pages, never the feed (23).
- `HomeWireCourse` — a course with a star rail, drawn thumbnail and sub-line — is **fully built with no producer**, and is §7 of his own brief (*&ldquo;Course discovery &mdash; PUNTA BRAVA &middot; ★★★★★&rdquo;*).
- **Rating a course is SHIPPED** — table, sheet, three surfaces, one rating in prod — and he asked on the 10th whether it fits the vision.
- A **per-hole scorecard already renders on the round receipt, on both clients, independent of the photo** (`RoundCardLeaf` / `csRoundCardHTML`). It is absent from the feed, the board and the course page.
- The **&ldquo;put it on the plan&rdquo; door** exists on the course page, in the one branch that hides it (27).
- The **live round's &ldquo;are you teeing it up at X?&rdquo; bridge** is on screen today, carrying a string (29).
- `push_nudges` admits a **`tee_tomorrow`** kind the client already routes, and nothing has ever inserted one (28).

**Nothing here needs inventing. It needs the good branch reaching the case the
golfer is actually in.** That is a much cheaper wave than it looks from the list.

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

## What earns its place (2026-09-11)

Measured against **production**, not argued from the roadmap:
**https://claude.ai/code/artifact/fe5df00e-02d8-4147-ad46-51c553bf0ee9**

**The measurement reframes the keep/ditch question.** 213 rounds exist and
**171 are backfilled history**; only **20** were posted within two days of being
played. **6 golfers active in the last fortnight.** The composer is opened
**219** times and submitted **24**. Live scoring: **28 started, 21 abandoned, 7
finished** — and `abandoned` is the database's own word for it.

So breadth is not the constraint. **The single act everything depends on fails
nine times in ten**, and every note of the last two days describes a reason why.

**It also retires one of my own proposals.** Item 5, comments on Home, assumed
comments exist elsewhere. `post_comments` holds **zero rows** — nobody has ever
left one, on any surface. And it weakens the case I made for Wave 3: scheduling
is 2,535 lines and prod holds **four plans**. The wave is still worth doing, but
as a *bet that plans are unused because nothing ever comes of one* — which is a
weaker claim than I made, and should be named as one.

---

## The build plan (2026-09-10)

Nineteen findings as four sequenced waves:
**https://claude.ai/code/artifact/a1bf141f-2164-4b1a-9fa2-8c2b592abbe1**

**Wave 1 needs no decision and can start without him** — the six findings where
the product asserts something untrue. Wave 2 is one missing field (`api_course_id`
on a feed row) that opens the whole card→course→plan loop. Wave 3 is the closing
act and is the keystone. Wave 4 waits on the card ruling.

Five items are HELD deliberately: they wait on an answer, not on time.

---

## The decision tree (2026-09-10)

The four decisions behind items 11-20, with what each branch commits to, is a
page: **https://claude.ai/code/artifact/82ae0f4b-df13-410f-923e-eee52db113ac**

It is a working document, not a record — **the record is here and in
`decision-log.md`.** When a decision is made it comes back as a `D` entry with
its reasoning, and the item here closes. The page exists because a branching
structure reads badly in a terminal and the owner is reading it from a phone.

**One question on it can delete a whole branch before the session starts:**
whether Oak Quarry is actually absent upstream, or is being hidden by the
no-rated-tees filter (item 11). Answer that first and Decision B may never open.

---

## Where this connects

- `spec/session-tracks.md` — the five lanes an item routes into.
- `spec/decision-log.md` — why a mechanic is the way it is. An item that
  contradicts a decision is not a bug report until that decision is read.
- `docs/ios/DECISIONS.md` — what was actually built, and its gate.
- `CLAUDE.md` — architecture, the landmines, and the current state.



### 2026-09-12 · Gameplay · plan entry, item 12 BUILT; three left

**Item 12 is built** (D343, migration `20261022090000_the_host_has_a_seat.sql`, unpushed): `declare_round` now seats the host. Owner ruled "write it then let's build it". Proven on a throwaway cluster, not on prod. **Owed: `supabase db push`** — it is the owner's to run.

The other three plan-entry defects, in the order I would take them:

- **The evening rejection.** `declare_round` compares against `current_date` and prod runs UTC, so after 17:00 Phoenix a golfer cannot schedule tonight's round: *"Pick a day that has not happened yet"*, about today, for seven hours a day. `DeclareRoundSheet.swift:51` has no `in:` range on the picker, so nothing stops them walking into it. First question: fix with the `p_today`/`cs_local_day` work the after-golf prompt needs anyway, and put a minimum on the picker?
- **The course page cannot start a plan.** `CourseScreen.swift:361` "Put it on the plan" lives only inside `neverKept`, the branch for a course the phone has never kept. On a page that renders, the door is absent. Moving one door.
- **Search hides real courses.** `ScheduleService.swift:148` and `:160` both end `.filter { !$0.tees.isEmpty }`, and 12 of 115 cached courses have no tee rows, so they are invisible and indistinguishable from "no such course". This is why Oak Quarry looked missing. First question: what should a tee-less course offer — it cannot be planned against properly, and the unlisted-course path was deliberately demoted by D150.

### 2026-09-12 · Gameplay · after-golf contract, second pass (owner rulings owed)

Follow-up: `docs/reviews/2026-09-12-after-golf-contract-review.md`. Two of my own proposals were proven wrong on a throwaway PostgreSQL 17 cluster and are corrected there: a defaulted second argument would have created an **overload** and broken every existing `home_dispatch` caller with `is not unique` (the fix is drop-and-recreate in one migration, re-issuing the grants the drop discards), and an action routed to `{kind:'plan'}` reaches no posting flow on either client (the phone opens the plan sheet, the web opens the schedule list and discards the id) — it must be "Add my round" to `{kind:'composer'}`.

**Four owner rulings are owed before anyone builds this:** the window length (three days proposed); whether `maybe` and unanswered tags qualify; one prompt per day when two plans share a day; and — the real one — **same-day suppression when the plan has no course id**. Four of five prod plans have none, so the match is a heuristic, never an established link: the choice is between a missed prompt and asking a golfer to post a round they already posted. First question: which of those two errors do you prefer? The ambiguity disappears with item 28's nullable column.

### 2026-09-12 · Gameplay / UX · the after-golf prompt, audited

Full audit: `docs/reviews/2026-09-12-after-golf-audit.md` (contract + 30 acceptance cases). It is items 16, 28 and 29 read together. Implementation is Codex's.

- Confirmed against the DEPLOYED function, not the migration: `home_dispatch` sees a plan only in `v_today … v_today + 8`, and `native_home` feeds it from `my_schedule(v_today, v_today + 14)` — both forward-only, so widening one clause changes nothing.
- **Found in passing, unrelated to the prompt:** prod `TimeZone` is UTC, so after 17:00 Phoenix `current_date` is already tomorrow and `declare_round`'s `p_play_on < current_date` guard refuses a plan for this evening. First question: fix by passing the client's local date, or by giving a golfer a timezone?
- **Also found:** `packages/db/contract.psv` is stale — it lists the dropped 5/6-arg `declare_round` and a 17-column `my_schedule` against today's 8 and 21. `build-db.mjs` generates `Rpc.swift` from it. Refresh after the next push.

### 2026-09-12 · UX · regressions in bee364a / de338d8 (Codex branch)

Full review: `docs/reviews/2026-09-12-home-no-photo-regression-review.md`. Two that change what a golfer sees: a photo row renders as a text slat while loading and again on every recycle (`HomeWire.swift:85-94`), and the whole name row now opens the golfer on the phone while the same tap opens the round on the web (`HomeWire.swift:160-174` vs `index.html:15871`). Left for Codex to fix on its own branch.
