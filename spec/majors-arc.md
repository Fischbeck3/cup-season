# Majors arc — design the mechanic, build it, launch the first one

*Brief for a GAMEPLAY & COMPETITION lane session (level 4 of the hierarchy).
Talk-first. Every mechanic decision gets a `spec/decision-log.md` entry BEFORE
it's built (CLAUDE.md rule 5), and the design lands in
`spec/gameplay-modes-working.md` as a new numbered section with ⚑ flags
resolved with the user. Code only on an explicit "build it."*

## Where "the Major" stands today

It is a **name, not a mechanic.** The IA blueprint
(`spec/handoffs/ia-blueprint.html`) canonizes it twice — "Start something ·
League · Ryder · Bracket · Major" and the ARENA container list "League, Event
(Ryder, Bracket, Major), or Live Round" — but `spec/gameplay-modes-working.md`
has no Majors section. Ryder (§4) is fully designed AND built end-to-end;
Bracket and Major are IOUs. This arc pays the Major IOU: **design → log →
build → launch a real one.**

## ⚑ FIRST DECISION — what IS a Major? (resolve before anything else)

Two honest readings; pick with the user:

- **(A) A standalone championship event** on the Ryder's rails — a compressed,
  ceremony-heavy, everyone-on-one-leaderboard event a crew runs over a day, a
  weekend, or a defined window. The IA precedent (Major listed beside Ryder
  under "Start something") points here. **Recommended as the v1 shape.**
- **(B) An in-season mechanic** — a league designates "major weekends" inside
  its season (its own four majors, mirroring golf's four) that score bonus
  weight toward the Cup. Bigger blast radius: touches `cup_points()`, caps,
  §14 machinery, and the season's fairness story.
- **(A→B) is compatible:** design the standalone event so a season can later
  *adopt* one ("this weekend, our Major counts toward the Cup") without
  rework. Name the interface, build A, park B with a flag.

## Design questions the session must resolve (⚑ each, log each)

1. **Format & window** — 18 holes in a day? 36 over a weekend? A four-round
   Major over four weeks (mirrors real majors, rides the existing weekly
   session tick)? Where does the round come from — any posted round in the
   window (spec §16 immutable facts), or a declared tee time?
2. **Scoring** — net stroke play off "your number" (index snapshot at entry,
   same integrity rules as `index_at_post`)? Or the named-bands voice? The
   UI language must stay bands-first ("beat your number by 3"), whatever the
   engine does. Receipts required — no leaderboard figure without a path to
   the rounds (§16).
3. **The field** — league-scoped, or open cross-league like the Ryder
   (events + event_players)? **Guests via claim links** would make every
   Major an acquisition surface (the GTM's cheapest wedge) — strongly
   consider from v1.
4. **Ties** — §14.3 tiebreak ladder, or a playoff mechanic (sudden-death on
   the next posted round)? Keep it decidable without a human.
5. **Entry & pot** — ledger only, money moves between friends (D39 posture);
   bragging-rights ($0) option from day one; settlement card at the end.
6. **Ceremony** — this is the mode's soul: a Major mints a PERMANENT trophy
   (trophy case), a champion board post, and a shareable recap card. Consider
   the parked earned-markers idea (gameplay-modes §9) — a champion's marker
   is exactly the kind of earned cosmetic that fits, but it's PARKED; flag it,
   don't build it silently.
7. **Anti-sandbag guardrails** — minimum established rounds to enter? Index
   frozen at entry vs at tee-off? The auto-handicap engine (WHS-lite,
   establishes at 3) is the substrate; decide the eligibility line.
8. **Naming & calendar** — "the Majors" plural suggests a circuit. Does a
   crew run one, or up to four a year with a season-long Majors race
   (order-of-merit)? v1 can be one-at-a-time with the plural as branding.
   Real-major anchoring (Masters week etc.) is a MARKETING tie-in
   (brand-bible seasonal campaigns), not a mechanic dependency — next men's
   major is Masters, April 2027; do not block launch on the golf calendar.

## Build path (after the design is logged)

The Ryder is the architectural template — reuse its rails, don't fork them:
`events` + `event_players` containers, sessions opened/resolved by the
`run_event_sessions` pg_cron tick, event board posts, MVP/trophies,
settlement. Likely shape: a new event type on those tables + a scoring RPC +
client surfaces (Start something → Major wizard, event room, leaderboard with
receipts, recap/trophy artifacts).

Non-negotiables from CLAUDE.md:
- **Migration discipline:** timestamp-named, never edited after prod; every
  client-called RPC gets `grant execute … to authenticated` (D37 — a
  "silent 403" is a missing grant); writes with game consequences go through
  security-definer RPCs; RLS scoped by `is_league_member`-style helpers.
- **Deploy-skew safety:** new RPC args default server-side; client
  try/catches new calls so old client + new DB (and vice-versa) both live.
- **Two deploys, always separate** — the USER runs `supabase db push`;
  handoff states the exact commands.
- Client: esc() every user string; classic↔module bridges via `window.*`;
  mixed-middot Edit landmine; `__CS_VERSION__` untouched; verify locally
  (server 8791, browser MCP, SW+caches cleared, console clean).
- Shareable artifacts follow the GTM design rule (gtm-year1 §3): make the
  sharer look good, carry a claim/join path, show what a spreadsheet can't.

## "Build to launch this event" — the launch is part of the arc

Shipping code isn't the finish line; **running the first real Major is.**
The arc ends with:
1. A QA pass in the tester-walkthrough style (create → invite → post →
   leaderboard → settle → trophy) on prod.
2. A **PIGL Major** scheduled with the user — name it something worth
   winning (the user picks; "PIGL Championship" is the placeholder), date
   set by the crew's calendar, announced on the board.
3. The recap/settlement artifacts verified share-ready (they're the
   marketing — coordinate with the Socials lane, which is planning beats
   around exactly these artifacts; see `spec/socials-outreach-brief.md`).

## Success gate

A full Major runs end-to-end on prod with real rounds from the real crew;
every leaderboard number taps to a receipt; the winner has a permanent
trophy in the case; the recap card exists and carries a join path; and every
mechanic decision on the way is in the decision log dated before its build.
