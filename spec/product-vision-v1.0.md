# Cup Season — Product Vision & Requirements Document

Version 1.0 · from the 2026-07-12 requirements session · verbatim

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
