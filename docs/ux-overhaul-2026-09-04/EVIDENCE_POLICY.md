# Evidence policy — what counts as a reason, and what does not

*Owner ruling, 2026-09-05, mid-build. **This outranks every artifact, including `OWNER_RULINGS.md`, on the question of what evidence a decision may rest on.** Where an artifact justifies a choice with a production count of what people did, that justification is void and the choice must be re-grounded or re-argued.*

---

## The ruling

> *"Right now there are only two really active users since we haven't launched. Don't make decisions off of our users and behaviors. Work on our escalations (Galen and I and our league) and our own viewed data through bots, walkthroughs etc."*

**Cup Season has not launched.** The production database holds two genuinely active golfers — the owner and Galen — inside their own league. Everything else in there is scaffolding: seeded bots, `@cupseason.test` accounts, the App Review reviewer, the seven `+blind` personas from the August audit, sandbox leagues, and half-built rows nobody ever returned to.

So a count of rows in production is **not** a measurement of human behaviour. It is a measurement of what we and our tools have left lying around.

## What production is still good for

Read-only production remains the right source for facts about the **system**, and those uses are unaffected:

- Does this SQL compile and apply? (the rolled-back dry-run — keep doing it)
- Does this grant hold, does this policy bite, is the anon surface still twelve?
- What **shape** does a payload have; what states *can* exist; what does a real course name look like when it is long.
- Is a migration applied; is the client and the database in step.

The distinction is simple: **facts about the machine, yes. Facts about people, no.**

## What is now void as a reason

Every one of these appears in the artifacts as support for a decision. Each is struck as *evidence of behaviour*. Some of the decisions they were attached to are still right — but they must stand on the brief, on an escalation, or on a walkthrough, not on these:

| Figure that was cited | Why it is void |
|---|---|
| "14 of 39 golfers belong to no league" | 39 profiles are mostly test and seeded accounts; the ratio measures our seeding, not a cohort |
| "21 of 26 live rounds abandoned (81 %)" | Those are our own aborted test sessions, not users giving up |
| "6 of 6 setup leagues are a founder sitting alone" | Those are leagues we created and never finished; it says nothing about organisers |
| "8 web-only against 5 phone-only golfers in 30 days" | Both numbers are us and the tooling. It cannot decide a client strategy — and the owner has ruled that question anyway |
| "one real multi-league golfer" | True of today's data, and no reason to design for one league |
| "`push_prompt_shown` 1 ever, accepted 0" | Nobody has been asked. This is not evidence that the ask is wrong |
| "`post_submit` p50 39 s, p90 76 s" | n=24, and the posters are us. Not a benchmark |
| "0 forfeits, 0 rivalry names, 0 clash winners, 0 game_results ever" | **Absence in an unlaunched product is not evidence against a feature.** Nothing here has had a chance to be used |
| "lock telemetry: 1 lifetime" | Same |

**The general rule: at n≈2, absence proves nothing and presence proves nothing.** A feature nobody used is not unwanted; a screen nobody reached is not unreachable. Do not reason from either.

## What replaces it

Three sources, in this order of authority:

**1 · Escalations from the owner's league.** What the owner and Galen actually hit while playing their real season — a screen that lied, a number that was wrong, a thing they wanted and could not find. This is the highest-value evidence the product has, because it is the only genuinely lived use. When one exists, it outranks everything below it. *(The Fellas' first-tee date being silently moved by a migration's self-check is the archetype: a real escalation, found by playing, that changed the product.)*

**2 · Bot walkthroughs and seeded worlds.** States we create on purpose and then walk: a squads league in season, a Pro mid-season, draft night, a ceremony, a golfer with no league, an event-only golfer, App Review's own path. The completeness critic named exactly these as never having been walked, and this is how they get walked. A seeded world is legitimate evidence about *the product* — what a screen says in a state — as long as nobody claims it is evidence about *people*.

**3 · The brief, the canon and reasoning from them.** The owner's brief, `spec/voice-and-tone.md`, `spec/product-vision-v1.0.md`, the decision log and the immutable laws. A design may rest on these alone; it does not need a number.

The blind persona walks stay useful and keep their standing: they are a **reasoning tool** for finding where a screen fails to answer a question. They were never user research and must not be described as such.

## What this changes in practice, right now

- **No remaining wave, and no review, prove, repair or re-audit step, may justify a choice with a production count of behaviour.** If a justification in the plan or the artifacts is one of the struck figures above, the wave still does the work — the work was ordered by the brief — but it does not repeat the number as the reason.
- **Prioritisation stops citing cohort sizes.** "This matters because 14 of 39 golfers…" becomes "this matters because the brief requires a golfer with no season to have something to open the app for."
- **Nothing already built is reverted on this ruling.** Every wave so far implements the brief; the ruling changes what may be said in support of it, and re-opens any choice that rested on a struck figure *and nothing else*. The Prove and Repair phases name any they find.
- **The coverage gaps get walked with bots, not inferred.** The states no persona sat in — a squads league in season, the Pro mid-season, draft night, the ceremony, an event-only golfer, App Review — are seeded and walked before the overhaul is called done.
- **A seeded world is never presented as a user.** Screenshots from a seeded league are labelled as seeded, always.

## One thing this does not license

It does not license inventing a user. The canon's fabrication laws are untouched: no manufactured stakes, no fabricated content in an empty state, no claimed behaviour nobody exhibited. Reasoning from the brief is honest; reasoning from an imagined golfer's imagined habits is not.
