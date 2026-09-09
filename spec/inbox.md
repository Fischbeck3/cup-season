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

*(empty — this is your end of the file)*

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
| 10 | **The wizard's headcount chips wrap 7 + 1, orphaning `12+`.** The row is a `FlowLayout`, which is what keeps it safe at the accessibility sizes; pinning it to a grid to kill the orphan trades a cosmetic nit for a clipping risk at AX3. *(carried from D-earlier; re-check before building)* | UX | XS | Is the orphan worth an AX3 risk? Probably not — this may be a "close it as won't-fix" entry. |

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
