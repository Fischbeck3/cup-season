# Cup Season — Product Vision & Requirements Document

Version 1.0 · from the 2026-07-12 requirements session · original text preserved

**Expansion draft — 2026-09-12.** The owner asked to expand the vision and plan the next build while TestFlight signing is blocked. The [next chapter](#expansion-draft--2026-09-12) below is a proposal for discussion, not approval of new mechanics, data collection, pricing, or a final brand mark. Existing decisions still govern implementation. The original “required” lists contain conflicts explicitly recorded in [the build plan](../docs/planning/2026-09-12-next-chapter.md); do not silently treat those lists as a new onboarding or posting specification.

---

## Vision

Cup Season is the operating system for amateur golf leagues.

Not another score tracking app. Not another handicap app. Not another shot
analysis tool.

Cup Season exists to make every round of golf matter because it belongs to a
season.

Golfers don't just post scores. They build rivalries. Win championships.
Create traditions. Relive memories. Write the story of their golf life.

## Product Principles

### 1. Golf First
The golfer is the product. Everything else supports that. Never optimize for
league management at the expense of making golfers excited to return.

### 2. Low Friction Wins
Every feature should ask: does this require more work from the golfer?
If yes — can the computer infer it instead? If not — don't build it.
Every additional tap loses users.

### 3. Real Golf
Everything is based on rounds golfers are already playing. No simulations.
No fake scoring. No fantasy players. Real golfers. Real friends. Real
courses. Real stories.

### 4. Memory > Statistics
Golfers don't remember "I averaged 31.8 putts." They remember "I birdied 18
to beat Jake." "I finally broke 80." "I won the club championship."
Create memories. Statistics only exist to support stories.

### 5. The App Should Feel Alive
Opening Cup Season should reveal something new. Someone posted. Standings
changed. A rivalry shifted. A streak continued. A season progressed.

## Target Personas

**1. The League Commissioner** (35–65). Runs the annual golf trip, Ryder
Cups, skins games; coordinates texts, collects money, updates spreadsheets.
Goals: spend less time organizing, more time playing, keep everyone engaged.
Pain: manual scorekeeping, spreadsheet fatigue, Venmo tracking, rule
confusion, constant texting. Promise: **"I'll run the league so you can
enjoy it."**

**2. The Competitive Weekend Golfer** (25–55). Plays every Saturday, tracks
handicap, loves trash talk, always wants to beat the same friends. Goals:
improve, win, brag. Pain: rounds disappear, no season, no history.
Promise: **"Every round counts."**

**3. The Golf Trip Guy.** Lives for Bandon, Scottsdale, Pinehurst, the
annual buddies trip. Needs: multiple formats, live scoring, memories,
photos, a champion.

**4. The Club Golfer.** Plays the same course, knows everyone, likes
season-long competition, wants history.

## What Cup Season Is NOT

Not Arccos. Not GHIN. Not a GPS app. Not a swing coach. Not a shot tracker.
Not a stat collector. Not a betting app.

If another app already owns that category — integrate with it someday.
Don't rebuild it.

## Core User Stories

**Identity**
- As a golfer, I want a permanent golfer profile, so every round I've ever
  played belongs to me.
- As a golfer, I want my handicap and history in one place, so my golf life
  follows me.

**Playing**
- As a golfer, I want posting a round to take under one minute, so I never
  dread doing it.
- As a golfer, I want hole-by-hole scoring, so matches and leagues can
  calculate automatically.

**Leagues**
- As a commissioner, I want to create a league in minutes, so organizing
  doesn't become work.
- As a golfer, I want standings to update automatically, so I never wonder
  where I stand.

**Rivalries**
- As a golfer, I want to know my lifetime record against friends, so every
  round has history.
- As a golfer, I want league history preserved, so championships actually
  mean something.

**Social**
- As a golfer, I want to see friends' rounds, so I stay connected between
  rounds.
- As a golfer, I want to celebrate milestones, without manually creating
  anything.

## Functional Requirements

**Profile — required:** name, home course, GHIN, handicap, photo, career
history, league history, achievements.

**Round — required:** course, date, hole-by-hole score, total score.
Automatically calculate: net, gross, differential, league points, match
results, standings updates, handicap impact.

**League — commissioner creates:** rules, season dates, draft, teams,
schedule, playoffs, cup finals. Automatic scoring, automatic standings,
automatic seeding.

**Feed — automatically generated.** Examples: "Mike posted an 81."
"Natalie won Week 4." "Jake moved into first." "Steve broke 90."
"Summer Cup has entered playoffs."

**Notifications — only meaningful ones.** Friend posted. League lead
changed. Championship clinched. Milestone reached. Invitation received.
Round approved. No spam.

## Future Features

Must require zero additional golfer effort. Examples: career timeline,
season recap, Golf Wrapped, predictions, weekly headlines, AI round
summaries, course history, rivalries, achievements, streaks, Hall of Fame,
league records.

## Features to Reject

Anything requiring additional tracking during play: club tracking, shot
tracking, GPS mapping, fairways hit, GIR, putts, club distances, wind, lie,
swing video, launch monitor.

The question is never "would this be cool?" The question is: **"would
enough golfers actually do this every round?"**

## Success Metrics

A golfer should: create a profile in under 2 minutes · join a league in
under 30 seconds · post a round in under 60 seconds · understand standings
in under 10 seconds · never need a tutorial.

## Product Philosophy

Every feature should pass these five questions:
1. Does this reduce friction?
2. Does this strengthen the season?
3. Does this create memories?
4. Does this encourage golfers to return?
5. Could this happen automatically from data we already collect?

If the answer is "no" to most of these, don't build it.

## The Cup Season Test

Before shipping any feature, ask: "If this feature disappeared tomorrow,
would golfers miss it because it made their golf life richer, or because it
was another stat they occasionally glanced at?"

Cup Season shouldn't win by having more data. It should win by making golf
feel more meaningful. The goal isn't to document every swing — it's to make
every round part of a larger story. That's a vision that can guide product
decisions for years and help keep the app from drifting into "just another
golf app."


---

## Expansion draft · 2026-09-12

### The promise we should build toward

**Cup Season turns the golf you play with your people into a season worth playing and a record worth keeping.**

This is proposed product language, not a replacement for the established brand promise, “Where amateur golf counts.” The category remains amateur golf competition. The golfer is the beneficiary; the Pro helps a group get organised. A person should gain value before joining a formal league, and that value should deepen when friends and a season arrive.

The expansion is continuity. The course you picked for Saturday should still be there when you post. The round you post should explain its effect on the season. The people you played with should lead to your shared history. The year should leave something worth keeping. The next season should inherit the group's identity and history while making its new rules explicit.

### One golf life, four connected objects

These objects already belong to the brand canon. They describe the product's purpose; they do not require four new tabs or four new database tables.

| Object | Promise | What the next expansion should deepen |
|---|---|---|
| **Crew** | Your people are easy to gather and recognise. | Carry the known people through planning, play, sharing and renewal, with appropriate invitations and privacy. A group does not need to become a formal league to matter. |
| **Cup** | Real rounds belong to a fair, understandable competition. | Show what changed and why; keep a path from every points figure to accepted rounds and adjustments. Expand formats only when an actual group need warrants it. |
| **Rivalry** | Playing the same friends accumulates meaning. | Surface existing head-to-head history at relevant moments. Distinguish a direct match from two unrelated posted rounds; never invent a head-to-head result. |
| **Record** | Your golf becomes a history you can return to. | Connect existing rounds, seasons, trophies, courses and optional photographs into readable chapters, with honest coverage and user-controlled visibility. |

### The experience across a week

**Before golf:** the app remembers the known day, course and people. Planning remains useful when a catalogue course lacks rated tees. Missing course facts stay missing; a plan does not fabricate a playable scorecard.

**During golf:** use the existing live or offline scoring path when useful. Ordinary golf does not require an open app. Recovery survives interruption and belongs to the correct golfer.

**After golf:** an eligible past plan offers a quiet way to close the loop. D345 already defines the approved window, participation and suppression rules. The next client work should let a golfer add the round, defer, or say they did not play. Known context may prefill an explicit draft; it must not overwrite unfinished work or become an automatic score submission. A photograph remains optional.

**Between rounds:** Home gives the most useful next action and a specific, supported story. A quiet week may stay quiet. It must not manufacture novelty, shame inactivity, or turn a pending invitation into evidence somebody played.

**Over months:** the Record makes a season legible as a chapter. A meaningful round can be revisited through a person, course or season. Shared artifacts expose only appropriate facts and take the recipient to something useful.

**Next season:** “Run it back” preserves continuity without silently carrying old rules, memberships or money commitments into a new competition.

### Three horizons, with earned entry gates

1. **The complete week — next build cycle.** Close planning-to-posting gaps, restore course discovery, make actions and recovery trustworthy, and settle the current brand rules. Success is an end-to-end journey on both clients, not another isolated screen.
2. **The accumulating record — following cycle.** Extend the Record and rivalry surfaces already built. Add a concise season chapter and contextually useful revisits before considering a large “Golf Wrapped” feature. Entry gate: the week loop works and the required facts have adequate coverage.
3. **Traditions that travel — later.** Improve existing guest, invite, trip and renewal paths so one golfer can bring a group along and the group can return next year. Portable season books and personal course history are candidate extensions. New course identity, visibility and export semantics require deliberate decisions before implementation.

These are dependency-based horizons, not calendar or delivery promises. Certificates do not need to hold up research, contracts, prototypes or local tests. A certificate delay alone is not a reason to combine every horizon into the next TestFlight build.

### Brand as part of the experience

The product should be recognisable with its logo removed: the printed tournament board, warm paper or green-black ground, real people, factual photography, a clear figure, and one well-chosen sentence. The logo signs the work; it does not supply all its personality.

Navigation glyphs explain actions. Golfer markers identify people. Drawn reactions are things people give. Trophy marks represent earned facts. The brand signature identifies Cup Season. Each needs a stable meaning across screens and clients. Removing every expressive mark would be as arbitrary as adding emoji everywhere.

Keep the established tokens, four type roles, protected gold and restrained motion. Resolve D339's pennant placement and icon-tile questions on real artifacts before extending the identity. “Any time. Anywhere.” can describe flexibility; “Where amateur golf counts” describes why the product exists. A surface chooses the sentence that answers its visitor's question.

### Requirements for every expansion

- Work with ordinary factual rounds and without mandatory photography, social posting or extra shot tracking. Reconcile the historical requirement conflicts before publishing a consolidated v1.1.
- Give every consequential action a clear success, failure, retry and return path. Preserve user work across interruption and server/client version differences.
- Use shared backend rules and copy producers where the decisions require them; give phone and desktop their appropriate layouts.
- Describe evidence and uncertainty separately. Never infer attendance from an invitation, a hole score from a course card, or a direct rivalry result from unrelated rounds.
- Make history useful and durable while respecting visibility, corrections and deletion. “The Record” does not promise to retain private data against a golfer's wishes.
- Keep the ceremony proportional to what happened. Sharing is optional; a golfer does not owe the product content.

### How we will know the expansion works

Retain the original friction targets: profile under two minutes, league join under thirty seconds, posting under sixty seconds, and standings understood in ten seconds. Measure these with representative tasks and real testers; test counts do not establish usability.

Proposed product measures are: successful first real round; eligible after-golf prompts that lead to a completed post; draft recovery without loss or duplicate submission; friend groups returning across several weeks; and revisits to a relevant round, course or season record. “Didn't play” is a successfully resolved prompt, not a played round. A prompt that was never seen does not establish abandonment. Establish a clean baseline before setting numerical growth targets; DEBUG telemetry is excluded under D338.

### Boundaries we keep

No GPS, swing coaching, shot tracking, synthetic competition, engagement bait or generic content feed. No public course-review marketplace, new payment model, paid tier or additional app platform in this expansion by default. Course opinions already have an implementation; their role and naming need reconciliation, not an invented duplicate feature. Personal course records, durable plan linkage and additional exports remain proposals until their specific semantics are agreed.
