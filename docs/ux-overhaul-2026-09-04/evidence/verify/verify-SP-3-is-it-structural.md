# Verify · SP-3 · lens "is-it-structural"

*Adversarial verifier, 2026-09-04. Repo `/Users/fischbeck3/cup-season` at tip `3bba87e` (main, clean). Read-only. Line numbers as of tip. Prod numbers re-queried via `supabase db query --linked` (read-only). SAW = read at the cited line; INFER marked inline.*

**Verdict: HOLDS (structural), with corrections.** The strongest copy + default + single-screen bundle I could construct dissolves the evidence for personas B and D almost entirely, but leaves persona A's and persona F's five questions unanswered, because the intents "we're playing Saturday, skins, $5, three guys without the app" and "make Sunday count" resolve to no object that can carry them without a mechanic change (an RPC signature, a new pre-tee state, or a new object) plus a layer above the doors that routes the intent. Nothing in the fix requires breaking a wall law, but two lines of the statement brush against L-11 and L-12 and must be reworded.

---

## 1 · The refutation attempt (the strongest non-structural fix)

All level-5/6, no IA or mental-model change:

| # | Change | Where | What it dissolves |
|---|---|---|---|
| F1 | Default `structure = "solo"`; `defaultStart` = today; ladder gains 20; buy-in row above "Use these defaults →" (D113 as ruled) | `WizardState.swift:17, :102, :148-154`; `WizardSteps.swift:61, :110-114`; `index.html:3516-3521` | CJ-13, CJ-14, CJ-20 (league half), PA-009; persona D's two must-haves; persona D's roster window (a lock on/after first tee earns D180's week floor, `20260831190000_roster_door.sql:82-92`) |
| F2 | Rename the doors and the `+` menu to intents | `WizardState.swift:462-464`; `HomeView.swift:178-190` | CJ-01's *labels*, CC-37 |
| F3 | Name sheet gains "Who's in?" (`PeoplePickerSheet` in invite mode — `invite_golfer` is allowed pre-lock, D112 `:4155`) and the stake row; share sheet first after lock | `WizardScreen.swift:69-90`; `WizardLockShareSheet.swift:57` | CJ-03 for golfers already on the app; CJ-11 |
| F4 | Role-gate `RunItBackCard` to the Pro; members read "the Pro hasn't run it back" | `LeaguelessDoors.swift:23` (renders for ANY `complete` membership) | persona B's "if I pressed it I'd become the organiser" |

## 2 · Test against the five questions, per persona

**Persona A (Friday night; Saturday skins with three friends not on the app) — the bundle FAILS.**
- "Run a season" (F2) still mints a season whose minimum is 2 whole weeks (`WizardDials.durs` `WizardState.swift:18`; L-18 says a season is N whole weeks — a one-day intent must never be a shorter league). No door can resolve "one round".
- "We're playing this weekend" → `DeclareRoundSheet` (`:42-74`): day · tee · course · note · tags; `declare_round` takes no game and no stake (`contract.psv` declare_round; `Rpc.swift:398-410`); tags reach buddies/league mates only ("No one to tag yet", `:66`); no link exists for a scheduled round. → *who am I competing with* and *why it matters* unanswered.
- "Play now" → `LiveSetupView`: nothing is saved before tee-off — `persist()` guards on `state.active && state.lr != nil` (`LiveRoundStore.swift:625-629`); the guest pencil links live only in `LivePlayView` after tee-off (`LivePlayView.swift:84, :472-492`). → *what can I do right now* (on Friday) unanswered; *what happens next* unanswered.
- To answer A you need either a game + stake on `declare_round` (RPC signature = mechanic, level 4), a persisted pre-tee live round with a shareable link (new state + anon endpoint, L-45), or a lightweight outing object (DL C-3) — AND a surface that asks the intent before choosing the object (level 3). No copy, default or single screen does it.

**Persona F (Sunday with Tash and Ravi, no league) — the bundle FAILS on the same mechanics.** "Is there a reason to make Sunday count" needs a game/stake on the plan or a live round attached to the plan; the plan→live bridge fires only on the day and loads course + group, never a game (`LiveSetupView.swift:28, :64-75`). The event door resolves to the Ryder (`create_event`: 7 args, sessions × weeks, `contract.psv`) — "one Sunday with three friends" has no object. NOTE: a plan already carries an RSVP (`set_round_rsvp`, `contract.psv:276`; `ScheduledRoundSheet.swift`), so the missing pieces on the plan are exactly game and stake.

**Persona D (commissioner; $50, solo, six friends, four without the app) — the bundle MOSTLY SUCCEEDS.** F1 puts $50 and Solo on the first screen; F1's today-default earns the week floor; F3 stages Dev and Marcus before lock. What remains: (a) the four friends without accounts cannot be named before lock — `invite_golfer` is profile-only (`20260827210000`), email/SMS invites were declined (D114 `:4185`); (b) the code/link closes at first tee for a league locked before it (`roster_door.sql:82-92`; D161 `:4801-4804`), and the Pro's own door to the halfway turn is never said on screen. (b) is copy + a mechanic that already exists; (a) is invite reach (CJ-11), not creation. D is a weak structural witness for SP-3.

**Persona B (member between seasons) — the bundle SUCCEEDS at the IA level.** F4 is a single-screen role gate. What survives is D41's own named tradeoff: run-it-back mints a NEW league id and the crew re-joins (`LeaguelessDoors.swift:92-110` → `WizardScreen(existingLeagueId: nil, runBack:)` → `create()` → `createLeague`; D41 `:1189-1195` defers true continuity to "its own decision"). That is a mechanic-level cost to season repeat, not an IA-level one.

**Conclusion.** Two of four personas defeat every non-structural fix; the fix they need is a layer that asks Who / When / What-for and resolves to an object that can carry the answer, and at least one of those objects does not exist or cannot carry it today. holds = true.

## 3 · Immutable-law check (canon reader §3A)

The fix as stated in *why_structural* does NOT require breaking a wall law, provided the statement is reworded in two places:

- **L-12 (membership opens at lock; code lock→first tee; a member never sees the Pro's tool).** "The first invite surface is five screens away / nothing between asks who is in" must not be read as "open the link before lock" — D40/D112 named that alternative and the owner declined it (`:4159`, "consent to a moving target"). The intent layer must move the LOCK earlier (bylaws derived from the answers, one tap) or stage invites via `invite_golfer` (allowed pre-lock, D112). Say so explicitly.
- **L-11 (buy-in defaults to $0).** "$0 when money was the point" reads as a complaint about the default. The default is law (D46, D113). The defect is placement: D113 ruled the row above "Use these defaults →" and it is unbuilt on both clients (`WizardSteps.swift:61, :110-114`; `index.html:3516-3521`). Reword.
- **L-18 (a season is N whole weeks).** "There is no dial for 'one round'" is correct AND must stay that way — the one-round intent resolves to a live round / plan / event, never to a shorter season.
- **L-16 (dials only in Custom; presets never mention them)** — the statement's D8 point is consistent with the law; the fix serves it.
- **L-41 (formation integrity), L-40 (free tee sheet, guests need no account), L-09/L-10 (ledger line, pot as two numbers), CC-26 (money lands on ruled surfaces)** — compatible; a single stake grammar "with CS_LEDGER under it" is what CC-26 asks for.
- **L-33 (function first on controls; no first-person quips as buttons)** — CAUTION: intent doors phrased as quotes ("I want to beat Jake") would collide with the voice law; the doors must name the press ("Beat a buddy", "Run a season").
- **L-03/L-05/L-45** — any new object/pre-tee link is a new SECURITY DEFINER RPC + migration + db-check edit; the statement's "level-3 entry that also touches mechanics" is the right level.

## 4 · Evidence verified / corrected

Prod (re-queried 2026-09-04): leagues by phase — complete 1 (2+ members), season 6 (all 2+), **setup 6 (all exactly one member)**; `client_events`: league_create 2 · lock_attempt 1 · lock_ok 1 · invite_open 1; `live_rounds`: abandoned 21 · final 5; forfeits 0; events 1; scheduled_rounds 4; buy-ins: season 5 × 7500 + 1 × 0, complete 1 × 5000, setup 6 × 0; `buy_in_note` set on 0 rows. All statement numbers confirmed.

Code: `LeaguelessDoors.swift:28-30`, `WizardState.swift:17, :66-73, :102, :148-154, :171-179, :387-407, :462-464`, `WizardScreen.swift:252-268` (create at the name sheet → `create_league(p_name, p_code)`), `WizardSteps.swift:61, :110-114`, `LeagueCopy.swift:131-155`, `HomeView.swift:178-190`, `StandingsPane.swift:32-47`, `LiveModels.swift:71-78`, `PotPane.swift:189`, `Rpc.swift:398-410`, `LiveSetupView.swift:24-35, :64-75`, `DeclareRoundSheet.swift:42-74`, `index.html:3516-3521` — all as cited.

Corrections to the statement/evidence:
1. **"first tee tomorrow"** → the default is the NEXT SATURDAY, never today (`WizardState.swift:148-154`); it was "tomorrow" only because the walks ran on a Friday. The structural point (a dead pre-season week; a code that closes at a first tee the app chose) is day-independent — state it that way.
2. **"a code that dies at first tee"** → precise: the LINK/code closes at first tee for a league locked before it (D180's week floor applies only when lock ≥ first tee, `roster_door.sql:82-92`); the Pro's own door (`invite_golfer` / `add_friend_to_league` / `respond_invite`) stays open to the halfway turn (D161) but reaches only golfers who already have an account. Persona D's "the only fix on screen is Cancel & delete" is a misread of the room ("Add golfers" is there); the defect is that nothing says it.
3. **"$0 when money was the point"** → "$0 hidden inside Customize when money was the point" (L-11 is law; D113's placement is unbuilt).
4. **"$20 impossible"** → true for the league ladder only (`WizardState.swift:17`); a live game takes any amount (`LiveSetupView.swift:296`, decimal pad); the Major takes `p_buy_in`; a plan takes nothing. Reword: "'$20 on it' has three homes with three grammars and no home on a plan". The per-game labels (per skin / per point / per side) are golf-correct units, not a defect in themselves — the structural part is the fixed league ladder plus the plan's silence.
5. **"web pre-selects 4 Squads (WB-22)"** → the web state default is `squads2` (`index.html:4083`); the static markup marks 4 Squads "on" (`:3540`) and `syncWizSegs` re-syncs on render (`:8031-8037`). Keep only if WB-22 saw it rendered.
6. **"six placements of the same three doors"** → on the phone I can confirm the string at `HomeView.swift:180`, `LeaguelessDoors.swift:29`, `HomeStream.swift:213` (occasion card); the six rests on CJ-40's list (Orientation, Clubhouse, Card & settings ×2) — cite CJ-40's lines or say "at least four".
7. **Root cause "D5 (no husks) led to minting on a name"** → D5 in `spec/decision-log.md:87` is "Receipts exist in schema, not in UI"; the "My Cup scaffold" ruling is D96 (`:3426-3433`, "Unnamed → Name your league") and D40's pilot (`:1149`). The code comment `WizardState.swift:475` cites "(D5)" for the scaffold name — a stale cross-reference. Re-attribute.
8. **"5 of 6 season leagues at $75"** → all five are July pilots locked under the old `DEFAULT 7500` (D113 `:4166`, prod verified); they are evidence of the old default, not of organisers choosing $75. Frame as legacy.
9. **"no intent can be said anywhere"** → the WHO question exists once, on the web at signup only (`index.html:2862`, D151's crew step), disconnected from creation; the phone never asks it (`OrientationScreen.swift:9-13`, O-14). Say "never feeds creation" rather than "anywhere".
10. **personas_hit** → keep A and F as the structural witnesses; downgrade B (level-5 role gate + D41's named mechanic debt) and D (defaults + roster-window copy dissolve most of the stall; what remains is invite reach, CJ-11).
11. **"Run it back … the same gold button shows to every member"** → confirmed (`LeaguelessDoors.swift:23`), but it is a level-5 defect and arguably a D41 intent violation ("the Pro reviews and locks"), not IA.
12. **why_structural should add the "must not" list**: the intent layer does not reopen D40/D112 (invites open at lock), does not change L-11 ($0 default), does not shorten a season below whole weeks (L-18), and resolves one-day intents to live/plan/event objects only.

## 5 · What I could not determine
- Whether the ~48 / ~75 term counts (CJ §2.1) are exact — I did not recount; cite as the reader's count.
- Why 21 of 26 live rounds are abandoned — no setup telemetry exists (CJ-49); the statement's "4 in 5 live rounds abandoned" is true as a number and unexplained as a cause.
