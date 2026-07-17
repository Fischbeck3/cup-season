# Artifact → Claim → Signup — Instrumentation Proposal

Growth/Launch lane · 2026-07-17 · **proposal for the eng/Gameplay lane — no
code or migrations in this doc by design** (lane guardrail). This is GTM
experiment №1 ("prereq for everything; do first") and bible §11 step 4.

## Why first

The entire Year-1 plan bets on the organic loop: a settlement card or recap
leaves the app, a non-user opens it, claims their round, and becomes a member.
GTM §14.2 names the loop's conversion rate as a make-or-break assumption, and
§10 gates all paid spend on knowing it. Today the loop **works** (guest claim
live since v23.157) but is **unmeasured** — we cannot currently answer "how
many members did last month's shares create?"

## The funnel to measure (five edges, four rates)

```
artifact shared → link opened → claim started → profile created → first round posted
```

Per-edge, attributable to: artifact kind (settlement / recap / invite / claim),
source league, and sharing member. That's enough to compute the organic
coefficient per league and per artifact type — nothing more is needed for the
Q1 read.

## Proposed shape (eng lane owns the actual design)

1. **One append-only events table** (`growth_events` or similar): occurred_at,
   event kind (the five above), artifact kind, source league, source member,
   claim/invite token, created profile (nullable). Insert-only, RLS-closed to
   users, written by security-definer RPCs / server paths only — consistent
   with "writes with game consequences go through RPCs."
2. **Attribution on the profile** — the durable version of the same fact:
   which token/artifact/league created this profile. One nullable column-set
   or a side table; enables "members created by shares" without event-table
   archaeology. (This mirrors how `round_to_board()` fans facts — record at
   the moment of truth, derive views later.)
3. **The hard edge is `link opened`.** Client-side logging only fires after
   our page loads — fine for opens of the claim page itself (log on mount,
   token in hand, before any auth). No third-party pixels, no analytics SaaS
   — the single-file ethos and the privacy posture both say build the counter
   ourselves.
4. **`artifact shared` fires on the share action** (Web Share API invoke /
   copy-link tap), not on render — render counts are vanity.
5. **A weekly funnel view** (`v_growth_funnel`?): by week × artifact kind ×
   league, the four rates. This is the number the GTM dashboard (§1) reads,
   and the one that decides whether paid ever un-parks.

## Deploy-skew note (per CLAUDE.md discipline)

New RPC args / columns need the client-side retry-without-new-field guard,
and new SQL params need defaults, so either deploy order stays safe. Migration
is timestamp-named; `supabase db push` is the user's command — state it in the
handoff.

## Explicitly out of scope

Dashboards/charts (a SQL view is enough for Q1) · A/B machinery · any
third-party analytics · retargeting pixels (GTM §10 keeps paid parked; when a
warm-retargeting test is ever approved, that's its own proposal and its own
privacy conversation).

## Acceptance (definition of done for the eng lane)

By end of month 1 of the 90-day plan (bible §7): every settlement card, recap
card, and claim link written after the migration produces a complete funnel
row-set, and one query answers *"how many profiles did shares create this
week, from which leagues, via which artifact kind?"*
