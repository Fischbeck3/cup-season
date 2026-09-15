# The next gameplay sprint · four candidates, one recommendation — 2026-09-14

Prepared from the owner's competitor exercise (Squabbit's low-friction
participation, 18Birdies' clear league entry). **Inventory first**: every
opportunity below was checked against what already exists in the database, the
web client and the phone before anything was proposed, and each is marked
**implemented / incomplete / absent / awaiting decision** with the evidence.
Nothing here is in the current release; the visual and function work continues
on `claude/brand-client-parity` while this is decided.

The four personas are `spec/personas-dashboards-v1.0.md`'s: **the Pro**
(commissioner), **the Golfer**, **the Captain**, and **the Club Admin**
(future, never exposed to golfers).

---

## A · Join and understand

*Invitation → understand the commitment and rules → join → first counting round.*

### What exists

| Stage | Backend | Web | iOS | Status |
|---|---|---|---|---|
| Invitation | `invite_golfer` + `push_nudges('invite')`; `my_invites` carries `event_kind`, `buy_in`; `respond_invite`; `league_by_code`; an `invites` table for email | `openInviteSheet`, `shareInvite`, post-lock share, `?join=` boot | `WizardLockShareSheet`, `MembersSheet`, `JoinIntent.code(from:)`, `InvitesBanner` | **implemented** (link + code + in-app invite, APNs `CS_INVITE`) |
| Email invitation | web inserts `invites` rows; **no function or trigger mails them** | `lockBylaws` writes the rows | — | **incomplete** |
| The covenant | `join_covenant_info` (anon: name, stake, preset, floor, finish, structure, phase; signed-in adds roster, Pro, dates, cap, allowance, split); `join_covenant_for_invite` | `covenantGate` fails closed, renders at every stake incl. $0 | `CovenantSheet`, `JoinService.covenant`, invite-side terms | **implemented**, both doors, both clients |
| Joining | `join_league` + join window + late seat; `lock_league` one transaction, idempotent | `#joinGo`, `openJoinSheet`, `openLeagueWelcome` | `JoinLeagueFlow`, `LeagueWelcomeSheet` | **implemented** |
| First counting round | `v_rounds_ranked` window + allowance + `month_rank`; floor waiver for mid-month joiners in `league_pulse` | first-round rung, welcome copy "best rounds each month count", `growthEvent('first_round_posted')` | `HomeFirstRound`, `HomePage.firstRound`, `Growth.firstRoundPosted` | **incomplete** — copy names it; nothing on any surface says *this round was your first that counted*; `native_home` does not carry the mid-month joiner facts |
| Guest / unauthenticated | `/?claim=`, `guest_live_*` (twelve anon endpoints, capped by D250) | claim page | `LiveClaim` | **implemented** for claims; guest *scoring in a league* is **absent by design** |

### The actual gap

The chain is built and fail-closed. What it lacks is the **receipt at the
end of it**: the moment a new member's first round counts, nobody says so, and
nothing shows the stranger who the host is until after sign-in (the anon
covenant deliberately withholds roster and Pro). Email invitations are written
and never sent.

### One short example

The Pro locks the Fellas and taps *Share the invite*. The Golfer opens it on
the phone, reads the covenant at $0, joins, and posts an 84 on Sunday. Today
the epilogue says *+7 pts · counts for Fellas*. It does not say **"Your first
counting round in the Fellas"** — the sentence that turns a join into a
membership. The Captain sees the new name on the roster and nothing else; the
Club Admin is not in this story.

### Smallest useful paired increment

1. **"Your first counting round" is said once, on both clients**, in the
   post-round epilogue and the receipt — a producer, not a card: the server's
   `round_epilogue` already returns `rank_before/after`; add `first_counting:
   boolean` to it (one column on an RPC the clients already read), rendered by
   `csNextAct` / `PostNextAct` as the counting rung's first-time form.
2. **The host is named on the invite covenant at $0** for a signed-in reader
   (already the case) and the invite *link preview* carries the league name
   and the Pro's first name through the existing `share-preview.ts` edge
   rewrite — no new anon endpoint, no thirteenth read.
3. Keep the editable league setup exactly as it is.

### Backend dependencies · decisions

- `round_epilogue.first_counting` — one migration, additive, skew-safe (clients
  default it false). **No decision required.**
- Email invitations: a `season-email`-style consumer of `invites` — **decision
  required** on whether email is a channel the product wants at all (the
  product has been code-only OTP and push; D68 governs unsubscribe).
- Guest scoring inside a league: **out of scope** — it needs an identity and
  integrity design (who owns the round, RLS, the counting cap); the claim link
  already covers "a guest played with us".

### Effort · acceptance · outcome

**Effort: small.** Acceptance: a labelled fixture account joins through a real
invitation on both clients, posts, and both epilogue and receipt say it was the
first counting round, once. **Outcome to measure:** invitation-opened →
first-counting-round completion, which `growth_events` already records at both
ends (`invite` nudge → `first_round_posted`).

---

## B · Understand why the next round matters

### What exists

| Moment | Backend | Web | iOS | Status |
|---|---|---|---|---|
| Before — what can count | `month_rank`, `cup_points`, `round_worth(cap, used, worst)`, the `need:` Home item (*"You are 3 back of Jade… one counting round in the top band closes it"*) | `seasonNote`, `csCountingRule`, composer `#calcSeason`, month meter, `csRoundWorthLine` — **rendered only in the scheduled-round sheet** | `RoundWorth.line`, `PostSeasonRule.countingNote`, `StandingsMath.closer()` | **implemented**, unevenly surfaced |
| At post — what changed | `round_epilogue`: `rank_before`, `rank_after`, `of`, `passed[]`, `gap_to_next_after` | `csMovementSentence`, `csNextAct` (eight rungs) | `EpilogueMovement`, `PostNextAct` | **implemented** — the one explicit before/after in the product |
| After — the path back | `round_card`: points, `month_rank`, `counting_cap`, band | `roundCardBody` (`COUNTING #n` / `BUMPED`) | `ReceiptRows` (`COUNTING #n OF cap`) | **incomplete** — current state only; the delta is lost on reopen; **no door from the receipt to the counting set** |
| Rank prediction | — | — | — | **absent by design** (D24: a ceiling, never a probability; `closer()` speaks only when the arithmetic guarantees it) |

### The actual gap

Three producers already answer the question; they are not on the surfaces
where the question is asked. The composer says points but not the cap; the
worth line lives only under a *scheduled* round; the receipt cannot show what
the round changed once the epilogue is dismissed, and cannot open the rounds
that are counting. The `need:` item exists only for solo structures with a
cap.

### One short example

The Golfer opens the composer on Saturday. Today it says *counts for Fellas*.
It could say, from `round_worth`, **"Worth up to 12 · your best 4 count and
you have 3"** — the sentence the scheduled-round sheet already prints. The Pro
is asked "why didn't Mike's round count?" and opens Mike's receipt: it says
`BUMPED` but not which four are counting. The Captain wants the same for the
squad.

### Smallest useful paired increment

1. **The worth line in the composer**, both clients, from the producer that
   already exists (`csRoundWorthLine` / `RoundWorth.line`). No new number.
2. **The receipt keeps its delta**: `round_card` returns `rank_before` and
   `rank_after` when the round was the one that moved them (a read of the
   `round_epilogue` facts it already computes at post time), and the receipt
   prints the same movement sentence the epilogue did.
3. **A door from the receipt to the counting set** — *"the four that count"*
   opens the season page's month, filtered to this golfer, which both clients
   already render.

### Backend dependencies · decisions

- `round_card.rank_before/rank_after` — one additive migration. **No decision.**
- The `need:` item for squads: a producer change in `home_dispatch` — **awaiting
  decision** on what a squad's "one round closes it" honestly means (the
  squad's counting rounds are several golfers').
- **No new scoring mechanic, no prediction.** Everything here is a ceiling or a
  recorded fact.

### Effort · acceptance · outcome

**Effort: small–medium** (two RPC columns, three surfaces × two clients).
Acceptance: on a fixture league, the composer, epilogue and reopened receipt
say the same three things about the same round, and the receipt's door lands
on the counting rounds. **Outcome:** receipt → counting-set door taps, and
the qualitative gate from `2026-09-12-next-chapter.md` — an unfamiliar golfer
explains what changed and finds the round behind a statement.

---

## C · Keep the group's tradition alive

### What exists

| Area | Backend | Web | iOS | Status |
|---|---|---|---|---|
| Group identity | `leagues(name, code, commissioner_id)`, per-league marker, `league_pulse`; **no league crest object** | roster, marker picker, Pro name | `LeagueRoomModel`, `RosterDoor` | **implemented** (name + marker), crest **absent** |
| Season history | `close_season`, `award_season_trophies`, `cup_finalists`, `trophies` (self-only RLS), `season_story`, the `lastseason:` Home item | `renderSeasonStory`, trophy case, `drawRecapCard` | `SeasonStory`, `TrophyMeta`, `CareerRecord`, `SeasonCeremonyView` | **implemented**; `wrap` phase is **client-derived** (no DB phase) |
| Rivalries | `rivalries`, `head_to_head`, `week_clashes`, the Ryder | `renderRivalries`, `openHeadToHead` | `HomeClash`, `RivalriesSection`, `Callout` | **implemented** |
| Earned moments | `achievements`, `post_round_peak.earned[]`, moments | `CARD_BADGE`, `momentRow` | `PostEpilogue`, `TrophyMeta` | **implemented** |
| Run it back | `run_it_back(p_league, dates, buy-in, months, pay note)` — SECURITY DEFINER, idempotent, carries the roster, board post | `runItBack`, role-gated card | `RunItBackService`, `LeaguelessDoors`, `SeasonPhases` | **incomplete** — `run_it_back` is **unpushed against prod**; the covenant re-fire is unreachable (neither client sends the stake/length); the wizard prefill is dead code; **no acceptance artefact** — no `agreed_at`, no re-confirmation of participation or rules |

### The actual gap

Everything a returning group needs is drawn except the one thing the owner
insists on: **explicit confirmation of participation and rules for season
two.** Run-it-back re-seats the roster as a count; nobody is asked, nothing is
recorded, and the RPC is not in production. This is also the item
`spec/inbox.md` (lines ~470–486) already names as awaiting decision.

### One short example

The Fellas' season wraps in October. The Pro taps *Run it back*. Today, on a
pushed migration, eight members would be re-seated silently. The Golfer who
moved away is still "in". The Captain is still captain of a squad that was
re-formed without asking. What the group needs is the same door they came in
through: **the covenant, again**, with last season's result on it — *"You
finished 3rd of 8 in the Fellas. Season two: same stake, same rules. In?"*

### Smallest useful paired increment

1. **Push `run_it_back`** as it stands (it is reviewed, idempotent and refuses
   to touch memberships) — and make the covenant re-fire *reachable* by sending
   the stake and length both clients already know.
2. **Re-confirmation as a covenant, not a new object:** `join_covenant_info`
   already answers for a league in `setup`; season two is that door with two
   added facts from `season_story` — last season's finish and whether the
   terms moved. Acceptance writes the one column that does not exist:
   `league_members.agreed_at` (with the season number), which is the artefact
   `spec/inbox.md` says the schema lacks.
3. **No crew object, no new chat, no crest system.** The league's name, marker
   and story are already its identity; the season chapter prototype in
   `2026-09-12-next-chapter.md` stays a prototype until this lands.

### Backend dependencies · decisions

- `run_it_back` push — reviewed, held; **owner decision** on timing only.
- `league_members.agreed_at` + season — one migration. **Decision required**
  (the inbox's open question): does season two re-ask for consent and money,
  or does the standing agreement carry and the copy stop claiming an opt-in?
  The recommendation is **re-ask**, because the product's promise is that every
  golfer understood what they joined.
- Whether the Pro may change terms through run-it-back at all — **awaiting
  decision**; the safe default is *same terms carry, changed terms re-covenant*.

### Effort · acceptance · outcome

**Effort: medium** (one held migration, one new column, one door reused on two
clients). Acceptance: a fixture league runs back; every member sees the
covenant with last season's result; only those who accept are seated; the
board says who is in. **Outcome:** members of a wrapped league who accept
season two within 14 days of the ceremony.

---

## D · Welcome and sustain a community

### What exists

| Area | Backend | Web | iOS | Status |
|---|---|---|---|---|
| A public league page | `league_by_code` → **the name only**; the anon covenant withholds roster, Pro and dates | `covenantGate` | `CovenantSheet` | **absent** (host identity before sign-in) |
| Shareable invitations | `share_info` for round / settlement / recap / person / plan; `redeem_share`; OG rewrite at the edge | `renderShareView`, one CTA *"Play this with your crew"* | — | **implemented** |
| Discoverability | `profiles.discoverable`, `search_golfers`, `friendships` (two-sided) | Golfers tab | `GolfersScreen` | **implemented**; no follows, no crews (declined, D250) |
| Host surfaces | `league_members.role='commissioner'`; a plan's host `scheduled_rounds.profile_id`; `ask_for_a_seat` notifies the host | Pro checks; founder desk | — | **implemented** for members; nothing public |
| Notifications | `invite`, `request` (+ email), friend-accept, `rsvp`, `nudge`, `callout`, post fan-outs with `notify_rounds` / `notify_chat` / `mutes`; nine D248 kinds (`rank_change`, `clash_pressure`, `friend_round`, `tee_tomorrow`…) **have no producer**; APNs delivery **never proven in production** (one sandbox token) | VAPID web push | `PushService`, routing, actions, badge | direct invitations **implemented**; relevant changes **absent**; friend starts / birdies **absent** (and refused as fan-out until a sharing model exists) |

### The actual gap

A stranger can be invited and can join, but cannot **see a league before
signing in** — not who hosts it, not what it expects, not a first thing to do.
For the two people the owner named this is the whole difference: a woman new
to golf and to the city needs to see a welcoming host and a low first step
before she gives an email; a club professional needs a page to send members
that says what the league is and who runs it.

### One short example

A club pro (the Pro) creates "Tuesday Nine" and shares one link with forty
members. Today the link is a join code with a name. Proposed: the same link
opens **a league page** — the name and marker, the Pro's first name and face,
the expectations in the covenant's own words (stake, how a round counts, when
it starts), and one first opportunity: *Ask for a seat* for a signed-out
reader, which becomes `ask_for_a_seat` on sign-in. A Golfer new to the city
finds it from a friend's shared round card — the recap already carries *"Play
this with your crew"*; it would carry the league page instead. The Captain and
the Club Admin are not in the pilot.

### Smallest useful paired increment

1. **The league page as a fourteenth anon read? No.** D250 caps anon endpoints
   at twelve with a written refusal of the thirteenth. Instead: **extend
   `join_covenant_info`** — the anon endpoint that already exists — with the
   Pro's first name and marker and the season's first tee, which are the facts
   the page needs and not private (the roster stays behind sign-in). One
   producer, no new surface area.
2. **Render it on both clients** as the covenant with a head: the web share
   route already exists (`/?join=`), the phone's `JoinLeagueFlow` already opens
   on a code.
3. **Notifications inside these journeys only:** the invitation and the RSVP
   already deliver; add nothing. Prove APNs in production first (it is
   env-gated and has one sandbox token). *Group catch-up* stays the Home digest.
   Friend starts and birdies are **not activated**: no sharing/following model,
   no supporting data for a birdie, and D248's self-check would raise.

### Backend dependencies · decisions

- `join_covenant_info` additions — one migration; **decision required** on
  exposing the Pro's first name and marker anonymously (recommended: yes,
  first name and marker only, never email or roster).
- APNs production proof — a runbook step, no code.
- **Deferred:** a public marketplace, follows, a crews table, birdie/friend-
  start fan-out, the nine unproduced push kinds.

### Effort · acceptance · outcome

**Effort: small–medium.** Acceptance: a signed-out phone opens a league link
and sees the host, the expectations and one first step; the ask lands with the
Pro as a notification that is proven delivered. **Outcome:** link-opened →
seat-asked → joined, for a pilot of one hosted league.

---

## Recommendation

**Run B first, then A, as one sprint: "the round that counts, explained."**

- B is the largest reader gain for the smallest change — three producers
  exist and are not on the surfaces where the question is asked; two additive
  RPC columns, no new mechanic, no prediction.
- A's first increment (*"your first counting round"*) is the same epilogue
  and receipt, one more boolean, and it is the moment that converts an
  invitation into a member. The invitation chain is already built and
  fail-closed on both clients.
- C is the right second sprint, and it is gated on the one decision the
  inbox has carried since D243: whether season two re-asks. Push `run_it_back`
  and make that decision; the work is small once it is made.
- D is a pilot worth running with one club professional after C, because a
  welcoming page for a group that cannot yet return for a second season is a
  page with no second act.

What this favours, as asked: invitation-to-first-round completion (A),
understandable competition impact (B), groups returning across seasons (C) —
over any new format.

### Held out of the current release

Every item above. The current release carries the visual and function work on
`claude/brand-client-parity` only. Database and Edge deployments remain the
owner's, and none is proposed here without its migration named.

### Backend dependency the current work already recorded

`home_feed` does not carry `points`, `month_rank` or `counting_cap`, so the
new compact scorecard's *competition story* is a desk-only reach through the
board cache until it does (D360). It belongs to sprint B's migration.
