# Cup Season — Personas & Role Dashboards (requirements session 2)

2026-07-12 · from Natalie Ramirez's session notes · lightly structured, content verbatim in spirit

## Persona dashboards — the Home adapts to ROLE, not just league state

**1. Commissioner (the Pro) — command central.**
Top: current season, week number, rounds still missing, matches in progress,
quick actions. ("Summer Cup · Week 6 of 12 · ✓ 18/24 scores submitted ·
Waiting on: Jake, Steve, Mike.")
League-health cards: scores missing, next matchup, upcoming playoff lock,
players who haven't played, rules needing attention.
Functions: create/edit league, invite/remove golfers, change rules, create
schedule, seed playoffs, lock scores, resolve disputes, pause/end season,
start new season, duplicate previous season.
**Communication = announcements, not chat.** ("Round deadline moved to
Sunday." "Playoffs begin next week." Nothing more.)

**2. Golfer — where do I stand, what do I do next.**
Top: current standing, record, next opponent, points behind first, playoff
status. Then: **"My next round matters because…"** (win and move into
first / need 2 points to clinch / must beat Jake).
Quick actions: enter round, standings, matchup, league — "that's 90% of usage."

**3. Team Captain** (leagues that name captains): roster, team points,
upcoming matches, player availability, captain messages, roster management.

**4. Club Admin (future):** multiple leagues, tournaments, member management,
calendar, reporting. Never exposed to regular golfers.

## Shared views

**League Home — the heart of the app:** standings, schedule, upcoming
matches, league records, season progress, championship countdown.

**Matchup View — one of the best screens:** current score, hole-by-hole,
net/gross, projected winner, head-to-head history, season implications.

**Standings tell a story:** every row carries its narrative —
"1 Jake (+42) · Clinched playoffs · 2 Natalie (+39) · 1 point behind ·
3 Mike (+37) · Controls own destiny · 4 Steve (+35) · Must win."

**League History:** every season, champion, record, trophy — more valuable
every year.

**Player Profile — competitive identity:** current handicap, career
championships, career wins, current leagues, season history, head-to-head
records. No swing stats. No shot data.

## Feature: League Calendar → League Activity Timeline

Not scheduling — **anticipation**. Fantasy football has fixture times; golf
doesn't. If Jake plays Thursday and you play Saturday, you currently have no
visibility into when the standings might change.

- **User story:** as a golfer, I want to know when everyone else is playing,
  so I understand when the standings could change.
- **Calendar view:** league month with declared rounds ("Thu 14 · Jake —
  TPC Scottsdale"), deadlines ("Playoff cutoff"), season events
  ("Championship Match").
- **Tap a declared round → projection:** course, tee time, current position,
  and scenario ladder — beats his handicap → projected 1st · plays to it →
  stays 2nd · struggles → drops to 4th. "Now you're invested before he even
  tees off."
- **Timeline framing:** upcoming events, not just dates — "Jake playing
  tomorrow · Mike has two rounds left · Week closes Sunday · Playoffs begin
  Friday."
- **Watch List:** the week's stakes at a glance — "Natalie · Saturday ·
  could move 3rd → 1st. Jake · Thursday · could clinch. Steve · Sunday ·
  must win to stay alive."
- **Live status:** "🟢 Jake is currently playing · hole 12 · projected to
  move into first." Everyone checks — not because it's social, because the
  competition is unfolding.
- Notifications: not spam (curated, rides the events engine).
