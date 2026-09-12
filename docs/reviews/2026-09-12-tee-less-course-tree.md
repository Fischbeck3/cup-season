# The tee-less course — a decision tree

**2026-09-12 · read-only.** Every fact below was read from source or measured
on production with SELECT. Nothing is built.

---

## The reframe, before the tree

I have been calling this "what should a tee-less course offer". Having read the
code, **that is the wrong first question**, because three separate things are
being conflated and only one of them is a product decision.

**1 · The client throws away what the server deliberately sends.** The courses
edge function fills tees from our cache, detail-fetches a bounded few unknowns,
and then returns the rest **bare on purpose** — its own comment says *"bare
courses still answer, the client's manual-entry row covers the rest"*
(`supabase/functions/courses/index.ts:232-234`). Both client readers then end
with `.filter { !$0.tees.isEmpty }` (`ScheduleService.swift:148` and `:160`).
**The server and the client disagree about the contract**, and the client wins.

**2 · One search serves two different needs.** The same call feeds planning
(`DeclareRoundSheet.swift:429`) and live scoring setup
(`LiveSetupView.swift:574`). **Planning does not need a tee at all** —
`scheduled_rounds` has no tee column, and `declare_round` takes only a label
and an optional `course_id`. Live scoring does need one. So a filter written
for live scoring's needs is silently deleting courses from the planner.

**3 · Some courses are genuinely not upstream.** Oak Quarry matches nothing in
`api_courses` at all. This is the only part that is a real product decision,
and it is the one D150 already ruled on.

*(Measured: 12 of 115 cached courses have no tee rows. The backfill cap is
`fetches >= 3` per search, `index.ts:217`.)*

---

## Q1 · Should a course with no rated tees appear in search?

- **No** → nothing changes. Oak Quarry stays invisible, a real course keeps
  looking like one the product has never heard of, and D150's accepted cost
  keeps being paid by the owner. *You have already reported this as a bug, so
  this branch is presumably closed — it is here to be closed explicitly.*
- **Yes** → **Q2**.

## Q2 · Everywhere, or only where a tee is not needed?

| | What it means | Cost |
|---|---|---|
| **A · Everywhere, labelled** | Delete both filters; the row carries a status such as "No rated tees". | One search, one rule. Live setup will offer a course it cannot score. |
| **B · Only in the planner** | Two searches: the planner keeps bare courses, live setup filters them. | Precise, and two code paths to keep honest. |

**Recommendation: A.** Codex's D333 already made live setup honest about a card
it cannot use — a tee with missing pars shows **Not ready** and is never filled
with defaults. So the dangerous version of A is already closed. The label does
the remaining work, and one search with one rule is the thing that will still
be true in six months.

## Q3 · What does a bare course carry into a plan?

**Nothing to build.** `declare_round` already takes a label and an optional
`course_id`, and **four of five plans in production carry no `course_id` at
all**. A bare course plans exactly like a typed one, only better, because it
keeps the catalogue id for later.

One real edge: the declare sheet has a **tee stage** after course selection,
and a bare course would land there empty. Since a plan stores no tee, the
honest behaviour is to skip that stage for a bare course. **That is the one
piece of genuine UI work in this branch**, and it is small. *(I am flagging it
rather than calling it free, having already once told you a door move was
"moving one door" when it was not.)*

## Q4 · What happens when someone tries to score or post one?

**Nothing to build; both paths already exist and are already honest.**

- **Live:** D333 refuses a card without real pars and says **Not ready**.
- **Posting:** the golfer types rating and slope, and the differential has
  always been computed from the round's own typed figures. A round at a bare
  course scores exactly like any other.

## Q5 · Raise the three-per-search backfill cap?

- **Raise it** → more courses arrive complete, at the cost of upstream calls
  and search latency on every query.
- **Leave it, and fetch on *selection* instead** → one detail fetch, at the
  moment a golfer actually picks that course, and the dataset builds itself
  along real usage rather than along typing.

**Recommendation: the second.** It is strictly less work per search, it targets
the course somebody actually wants, and `fetchAndStore` already exists.

## Q6 · The genuinely absent course — the only real ruling

Oak Quarry is in no catalogue we can reach. Q1 to Q5 do nothing for it.

This is where **D150** bites: it retired `courses`/`course_tees` and demoted
free text, with the tradeoff stated at the time as *"free-typed rounds stay
invisible to course history forever unless someone re-picks them; that is the
accepted cost of not guessing."* What has changed is not the argument but who
is paying: **the owner is now the one paying it, on his own home course**, and
that is a legitimate reason to revisit a ruling rather than quietly patch
around it.

Three shapes, and they are not equivalent:

| | What it is | The risk |
|---|---|---|
| **i · Keep the demotion** | Type the name, post the round, no history, no discovery. Today's behaviour. | The reported complaint stands. |
| **ii · A per-golfer course** | Your typed course is yours: your rating, your slope, your history. | None that does not already exist — differentials already come from the round's own figures. |
| **iii · A shared course** | One golfer's entry becomes everyone's pre-fill. | **One wrong tee becomes contagious.** A self-inflicted error turns into everybody's. |

**Recommendation: ii, and not iii.** It answers the complaint, it adds no
correctness risk that today's typed rounds do not already carry, and it keeps
the one property D150 was actually protecting — that nobody inherits a stranger's
guess. If a shared catalogue is ever wanted, it should be a promotion path with
a human in it, not a side effect of one person typing.

---

## What this costs, if you take the recommendations

| Branch | Work |
|---|---|
| Q2 A | Delete two `.filter` calls; add a status label to the row |
| Q3 | Skip the tee stage for a bare course in the declare sheet |
| Q4 | None — already built |
| Q5 | Move the detail fetch from search to selection |
| Q6 ii | A per-golfer course record, a decision entry, and a migration |

Q2 to Q5 are one small client change and one edge-function change, and they
fix the reported bug for the twelve courses that are **already in the
catalogue**. Q6 is a separate wave with a real decision entry, and it is the
only part that needs a ruling before anybody writes code.

**My order:** take Q2 to Q5 now as one change, and hold Q6 until you have
ruled, because the first four make the second one easier to judge — with bare
courses visible you will find out quickly how often a course is genuinely
absent rather than merely bare.
