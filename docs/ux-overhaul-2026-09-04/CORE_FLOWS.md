# Cup Season — Core flows

*Phase 3. Written 2026-09-05 against `INFORMATION_ARCHITECTURE.md`, `UX_PRINCIPLES.md` and `DECISIONS_TO_LOG.md`. Repo `/Users/fischbeck3/cup-season` at tip `3bba87e`; read-only on the repo but for this folder.*

Twelve flows, each written the same way: **goal · entry points · the screens in order, with the copy quoted and the fields named · taps and seconds · what the other party sees · the reads and the writes · the failure and empty branches · the aha line**, where the flow carries one. Every screen that changes names its current file. Every fact traces to an existing read (**class A**), a new RPC over existing tables (**class B**), or a new table/column/mechanic (**class C**). The B and C items used here are collected in §17; the ones the spine did not already have are marked **NEW HERE** and say which drafted decision entry must gain a clause.

---

## 0 · Spine amendments proposed

Four places where building the flow end to end forced a deviation from the spine. Each is stated with its evidence, because each is a thing the spine asserts and the code contradicts.

### A-1 · The two-golfer season seats the second golfer through an **invite**, not `add_friend_to_league`

`INFORMATION_ARCHITECTURE.md` §2.2 and §9 mint D205's pair with `create_league` → `lock_league(p_structure:'solo', …)` → **`add_friend_to_league(jake)`**, described as "buddies only — the Pro vouches, no code, no wait".

Read the function. `add_friend_to_league` (`supabase/migrations/20260830300000_join_window.sql:142-184`) checks `is_commissioner`, checks an accepted `friendships` row, calls `_join_gate(p_league, true)`, and then **inserts the `league_members` row directly**. There is no invite, no acceptance, no covenant, and the only trace Jake gets is a `posts` system row reading `"JAKE FENNER WAS ADDED BY THE PRO — WELCOME TO THE LEAGUE"`. At `buyin_cents > 0` that seats a golfer on a pot sheet he never agreed to, which **L-12** ("every join passes the covenant") forbids and which D136 exists to prevent.

**The flows therefore mint the pair with `invite_golfer(p_league, null, jake)`** (`contract.psv:158`), which writes a `member_invites` row *and* a `push_nudges` row of kind `invite` (`20260827210000_push_wave7.sql:69-86`), and Jake's acceptance runs the covenant before `respond_invite`. That is the same fix A-7 already demands for `InvitesBanner`, applied to the one path the spine routed around it. `add_friend_to_league` survives for exactly one act — the Pro adding a buddy to a **$0** roster from the season page — and even there the seated golfer's next Home carries a Tier-1 acknowledgement item naming the terms.

**Cost:** Jake taps once more. That tap is the covenant, and it is the difference between a competition and a conscription.

### A-2 · `lock_league` gains `p_pay_note` so "required at publish" is one transaction

D225 rules the Pro's payment note **required at publish**. Two facts make that unbuildable as drafted:

1. `set_buy_in_terms(p_league, p_note, p_due_on)` exists (`contract.psv:258`) and has **zero call sites on the phone** — `grep` over `apps/ios/CupSeason` and `apps/ios/Packages` finds it only in the generated `Rpc.swift`. The web calls it at `index.html:6310`. So on the shipping client the Pro literally cannot record how to pay, which is the fact two persona walks hit.
2. `lock_league`'s signature (`contract.psv:179`) has no note parameter, and **L-41** requires formation to be one transaction. Calling `lock_league` then `set_buy_in_terms` as two taps' worth of network means a season can go live with a stake and no way to pay it.

**Proposed:** a new migration adds `p_pay_note text default null` to `lock_league`, written into `league_settings` in the same statement. Filed as **R18** (§17), defaulted and skew-safe per `CLAUDE.md:77-80`, and **now named in D225**. `set_buy_in_terms` stays as the after-the-fact edit and finally gets its phone call site on the pot section.

### A-3 · The callout needs one small migration, not zero

`INFORMATION_ARCHITECTURE.md` §9.1 and D237 build the callout as "a Ryder with a field of two and one session… **One sheet, roughly 120 lines, no migration.**" Three clauses of `create_event` (`supabase/migrations/20260830190000_ryder_dials.sql:33-103`) say otherwise:

- **`if extract(dow from p_starts_on) <> 0 then raise exception 'The Ryder starts on a Sunday — sessions run Sun to Sat'`** (`:43-45`). A callout raised on a Thursday for Saturday **cannot be created at all**. D213 already retired the Sunday snap for a season's first tee; for a one-session event it protects nothing.
- **`draw_rule` is now `check (draw_rule = any (array['team_pvi','shared']))`** (`:29-31`), so the sheet must send `team_pvi`; `assign` is not a draw rule.
- **`add_event_player` leaves `team_id` null** (`20260830200000_event_teams_rls_and_consent.sql:70-74`) and so does `respond_invite`'s event branch (`20260830300000_join_window.sql:222-226`). A field of two with no teams has no clash.

**Proposed, and now carried into the entry:** one definer RPC, **R19 `call_out(p_opponent, p_closes_on, p_forfeit_terms)`**, that mints the event, names the two teams for the two golfers, seats both **with their teams assigned**, and writes the callout nudge — plus **R20 `respond_callout(p_event, p_accept)`**. Roughly 60 lines of SQL over existing tables, **no new table**, which is the load-bearing half of D237 and stays intact. D237 is still PROPOSED, so it **has gained the clause** rather than being superseded: its "No migration" line is struck and R19/R20 are named in it.

### A-4 · A weekend's stake is a **forfeit**, and the money field on `scheduled_rounds` is not built in wave 1

C-3 (D240) gives `scheduled_rounds` a `name`, a `game` and a **`stake_cents`**. T-02 and D242 rule that an optional stake between friends with no season is a **forfeit**, and `forfeits` carries a load-bearing "no money column" rule (`20260724120000:10-13`) that D242's own entry restates for store review. A cents column on a plan is a second money object outside the pot ledger, on a surface with no ledger, no collected figure and no L-09 line.

**Proposed, and now carried into the entry:** `scheduled_rounds` gains `name` and `game` only. "Something on it" on a weekend is a **forfeit** through the widened `create_forfeit` (C-5), and the money case is the live round's own `game_config` stake, which already exists (`LiveSetupView.swift:296`). D240 keeps its two columns, loses its third, and gains **R22** — because two columns no shipped read returns are two columns nobody outside the host can see.

---

## 1 · Conventions

**Reads and writes.** Every line names the RPC. **A** = shipping, in `packages/db/contract.psv`. **B** = a new RPC over existing tables (§17). **C** = a new table, column or mechanic (§17). A write that is a direct table insert today is called out as a defect on the path, per **L-03**.

**Taps and seconds.** A *tap* is one discrete touch on a control; typed characters are counted separately as `(+n typed)`. Seconds are **targets**, not measurements, and the only measured baseline in the product is `post_submit` (n=24, p50 39 s, p90 76 s, `UX_PRINCIPLES.md` §P-2). Every target below that competes with that baseline is written to beat it, and §18 says how each is checked.

**"What the other party sees."** Push copy obeys **L-20**: one of D23's eight emotions, once per condition, no shame, and no push until one production APNs token has received one real push (`device_tokens` holds one `ios-sandbox` row). Where a flow's push kind is one of D248's ten new ones it is named as such.

**The four laws this document is required to keep.** **L-12** (every join passes the covenant) · **L-11** ($0 is the default) · **L-09** (the ledger line verbatim from `MoneyCopy.ledger`, `MoneyCopy.swift:28`) · **L-40** (the free door). Each is honoured in named flows, and the full address list is **§15** — stated once, there, so it cannot drift from the flows it points at.

**Voice.** Every quoted string is a proposal and obeys `spec/voice-and-tone.md`: the Gentleman Instigator, function first on controls, natural case for authored sentences, no exclamation, no emoji in prose. The six reaction emoji (D25) are a vocabulary, not prose, and survive.

---

## 2 · Onboarding — cold

**Goal.** A stranger who found the app on their own reaches a Home with a person or a round in it, having **done** something, in under two minutes. Four frames, three questions, two of which the app could not have answered itself.

**Entry points.** The App Store listing (rewritten as IOS-035, `INFORMATION_ARCHITECTURE.md` §13.6) · `cupseason.app` signed out · a friend's verbal recommendation.

**Current files.** `Door/DoorView.swift` · `Onboarding/CardGateView.swift` (three steps at `:55-57`) · `Onboarding/OrientationScreen.swift` (**deleted**, O-03/D224) · `RootView.swift`.

### 2.1 The screens

**Frame 1 · The door** (`DoorView.swift:91-113`, kept, two additions)

> **Cup Season turns the golf you already play**
> **into a season with your friends.**
> Every dollar on the books.
>
> **Email** `you@example.com`
> **Continue with email**
>
> *One code, no password. Codes come from the newest email.*
> *I have a code →*

- **Asked:** email. **Inferred:** everything else.
- **"I have a code"** is the web's control (`index.html`'s join door) and the phone does not have it; it validates against `league_by_code` (A, anon, `contract.psv:169`) **before** the email round trip, so a golfer who was handed a code never types their email into a door that cannot use it.
- **The two lines are swapped, and that is an override with a CONFLICT line.** D39 put *"Every dollar on the books"* at the head of the door (`spec/brand-canon.md:69`). It is a good sentence and it stays on the screen — as the **standfirst**. It does not lead, because the first thing a stranger reads on a product whose L-11 makes **$0 the default** should not be a money claim, and because the brief's own rule is that monetization never interrupts the core. The headline is D117's unbuilt sentence, finally written: it is the §1 paragraph's first clause and it is the only thing on the screen that answers *"what is this"*. It is also the first line of the rewritten App Store description (`INFORMATION_ARCHITECTURE.md` §13.6), so the two first screens now say the same thing. **CONFLICT (named): D39's UI clause (the door's headline) — superseded at level 5, copy order only. D39's mechanic — the ledger, the books, money moving between friends — is untouched, and the sentence survives verbatim one line down.** Carried in D247.
- 8-digit code, no `maxlength`, code-only, no magic link (**L-06**).

**Frame 2 · Your card** — one scrolling frame, not three steps (`CardGateView.swift:55-57` is the three-case switch that dies)

> **Your card**
> This follows you into every season, every round, every group.
>
> **Name** `First and last`
> **What do you usually shoot?**  ( Under 80 ) ( 80s ) ( 90s ) ( 100+ ) ( No idea )
> *Your number builds itself from three posted rounds. This just gets you started.*
>
> **Save my card**
>
> *You're @jerecho and your marker is The Saguaro. Change either on your card.*

- **Asked:** name; a scoring band. **Inferred and defaulted:** the **handle** (auto-filled from the name, as it already is) and the **marker** (assigned from the fourteen). **L-08** requires both to be *set*, not *chosen* — they are set. **L-24** is satisfied: still one of the fourteen, still the floor, still changeable, and no silhouette state is created. The screen persona A spent forty seconds on (`CardGateView.swift:80` "Pick your ball marker") is gone.
- **Moved off:** GHIN and the typed index (`CardGateView.swift:171-175`) go to You → your card. GHIN is a reference, never a number the app uses (**L-39**).
- The band writes a **starter** figure through `set_profile(p_index, p_index_source:'starter')` — **which is two filed items, not one call**: `set_profile` hard-codes `index_source = 'self'` today (`20260716120000:68`) and has no source argument (`contract.psv:274`), so it needs **R23**; and `'starter'` is a fourth value against CHECKs that admit only self/app/ghin (`initial_baseline.sql:1065, :1267`), so it needs **C-13**. Three honesty rules ride with it (D247, and `INFORMATION_ARCHITECTURE.md` §11.1 states the engine's behaviour in full): the ME strip labels it **`STARTER 13`**, never `YOUR NUMBER`; it never renders as a bare float dressed as an index (**L-14**); and at three posted rounds the engine's figure **actually** replaces it — which requires widening `round_refresh_index`'s gate from `= 'app'` to `in ('app','starter')` (`20260716100000:245`) and the announce branch with it (`20260831120000:1636`), or the promise is false against the shipped trigger (**L-44**).
- **It scores, and the app says so.** `score_round` takes `index_at_post` from *caller → `profiles.index_current` → `handicap_index_asof` → this round's own differential*, so a starter in `index_current` scores the first three rounds. That is **D124's option (ii)**, which D124 declined in favour of option (i); D247 carries the CONFLICT line and it is an **owner question** (`INFORMATION_ARCHITECTURE.md` §19 item 1). If it is declined, the starter is held client-side, labels the strip, and never reaches the engine.

**Frame 3 · Who do you play with** — D151's crew step, **web-only today**, built on the phone (O-14 → D233)

> **Who do you play with?**
> `Find golfers by name or @handle`
> ( Galen Fischbeck · @galen · The Saguaro )  **Add**
> ( Jade Ruiz · @jade )  **Add**
>
> **Text an invite to somebody else**
> **Nobody yet →**

- **Asked:** nothing required. Every row is optional and **Nobody yet** is a real door, not a skip link in grey.
- **L-37** is unchanged: `search_golfers` (A, `contract.psv:254`) matches an exact @handle or an existing relation; it does not browse strangers.
- **"Text an invite to somebody else"** is the **person link** (C-4/D241) — `shares.kind='person'` inside the existing anon `share_info`. Its landing mints a **buddy request**, not a friendship (D80). This is the first time in the product's life that an account-to-account invite exists without a league; today the only link `PeopleScreen.swift:105-129` can hand over is a **league's** join code, and a golfer with no league gets nothing.

**Frame 4 · Your first move** — one door, chosen by frame 3's answer

| Frame 3 answered | The screen | The DONE act |
|---|---|---|
| 2+ buddies added | **"Galen and Jade are already here."** / *They played four rounds between them last week.* | **Add my round** — *"It lands in their feeds tonight."* |
| 1 buddy | **"Galen is already here."** / *He posted a 78 at Kokopelli in July.* | **Add my round** |
| a link was texted | **"The invite is out to two people."** / *You'll see them here the moment they're in.* | **Add my round** |
| *(and the Home behind it)* | **S1's outbound branch** (`HOME_STATE_MATRIX.md` SA-7) carries the same sentence — *"Two invitations are out. Nothing back yet."* — so the next screen does not contradict the one before it (**L-44**). Reads: `friendships` outgoing (A) + `shares` of kind `person` (**C-4**) and `plan` (**C-12**) | |
| nobody | **"Add a round you already played."** / *Course, score, done. Your number starts building at three.* | **Add my round** |

Every branch's door is the composer. **No orientation screen** (prod: `orientation_shown` 5, `orientation_done` **0**).

### 2.2 Taps and seconds

| Step | Taps | Typed | Target |
|---|---|---|---|
| Door → email → code | 3 | email + 8 digits | 35 s (mail round trip dominates) |
| Card | 2 (band, Save) | name | 18 s |
| Who do you play with | 1–3 | a name or nothing | 20 s |
| First move → composer | 1 | — | 3 s |
| **To a useful Home** | **7–9** | | **≈ 75 s** |

Against today: eight surfaces, three required choices, one of which ("pick your marker") has no default and one of which ("starter index") most golfers cannot answer.

### 2.3 Reads and writes

- Reads: `door_flags` (A, anon) · `search_golfers` (A) · `my_friends` (A) · **R1** `home_dispatch` on landing (B).
- Writes: Supabase auth OTP (**L-06**) · `set_profile(p_name, p_index)` (A) · `set_handle(p_handle)` (A, `contract.psv:263`) · `friend_request(p_profile)` (A) · `create_share(p_kind:'person', p_ref: me)` (A + **C-4**'s CHECK widening on `shares.kind`, today `check (kind in ('round','settlement','recap'))` at `20260722190000_public_shares.sql:25`).
- **Not written:** no `profiles.play_style` column. The brief's third question is **inferred** from the buddy count, the arrival path and the first round (D247, D250 (5)).

### 2.4 Failure and empty branches

| Branch | What happens |
|---|---|
| The code never arrives | The code stage keeps its resend and its "Codes come from the newest email" line (`DoorView.swift:111`, kept verbatim — it is the correct sentence). |
| `search_golfers` finds nobody | *"No one by that name yet. Text them a link — it works for anyone, account or not."* with the person link under it. **Never** an empty list with no door (**L-32**). |
| The band is skipped ("No idea") | No starter is written; the ME strip reads `— · BUILDING` and the composer's ceremony says *"Eighty-four at Papago. Your number starts building — two more and it goes live."* (the PP-03 fix). |
| Offline at the card | The card is held locally and retried; the gate does not advance on a failed `set_profile`, and the error is the server's own sentence (**L-32**). |

**The push ask is not here.** D104 §6's copy and mechanism are kept verbatim — it is the best-written screen in the app — and only its **timing** moves: after the first round is posted, or when the first buddy accepts, or at the first join. Today it fires over the first Home, before there is anything to be notified about.

### 2.5 The aha line

For a cold golfer with no buddies there is no two-minute social aha and this document does not pretend otherwise. Theirs arrives on round three: **"That is your third. Your number is live: 12.4."** For a cold golfer who found two buddies it arrives at the first post: **"Galen and Jade saw that."**

---

## 3 · Onboarding — invited

**Goal.** A golfer who was sent a link by a friend is inside that friend's season, having answered a real question, in under two minutes — and the first thing they do is **with people**.

**Entry points.** `?join=CODE` in a text message · a shared link on the web door · a `?p=TOKEN` person link (C-4) · an in-app invite (§5.3).

**Current files.** `index.html:20455-20460` (the web door — the real first screen for every invitee) · `CupSeasonApp.swift:28-36` (`onOpenURL`) · `RootView.swift:43` (`JoinIntent.clear()` on appear) · `Door/DoorView.swift` · `Onboarding/CardGateView.swift` · `People/JoinLeagueFlow.swift`.

### 3.1 The screens

**Screen 0 · The web door, app not installed** (`index.html:20455-20460`)

> **Galen put you on the Fellas.**
> Thirteen weeks of golf with six people, starting Saturday.
> **Get Cup Season** *(App Store)*
> **Open it in the browser**

The App Store link **does not exist today** and is the single cheapest fix in the invited path (G-05). The Smart App Banner carries the code in `app-argument`.

**Screen 1 · The door, naming the invitation**

> **The Fellas is one step away.**
> Enter your email and you're in — you'll see the terms before you join.
>
> **Email** `you@example.com` · **Continue with email**

The phone's `DoorView` **never reads `JoinIntent`** today (FR-07) while the web says exactly this sentence. The phone adopts it.

**Screen 2 · Your card** — §2's single frame, unchanged, with one added line at the head: *"Saving your card puts you in front of the Fellas."* (the existing claim-flow line at `CardGateView.swift:51` generalised).

**Screen 3 · The covenant** — §5.1. Always, including $0 (**L-12**).

**Screen 4 · Welcome**, kept (`JoinLeagueFlow.swift:173-220`) **plus a Done button** — today you swipe it away, which is the one screen in the product with no exit control.

**Screen 5 · Home, already about the season**, and the second item is a DONE act. **Two branches, and the second is the common one.**

*If the Pro has a round on the schedule:*

> **YOU'RE IN THE FELLAS**
> Six golfers, thirteen weeks from Saturday. Galen runs the season (the Pro).
> **See the table →**
>
> **Galen has a round on the schedule for Saturday, 7:10 at Papago.**
> **Say you're in →**

*If nobody has declared anything — which is what prod actually looks like:*

> **YOU'RE IN THE FELLAS**
> Six golfers, thirteen weeks from Saturday. Galen runs the season (the Pro).
> **See the table →**
>
> **Five others are in. Here's who.**
> Marcus, Dev, Tash, Ravi and Jules.
> **See the season →**   ·   **Add my round**

**Prod holds one future planned round across 39 profiles.** A Pro who publishes a season and declares nothing is the norm, not the failure case — persona D's own walk ends exactly there. So the invited golfer's first DONE act cannot rest on a plan existing: the fallback is **the roster**, which is five real names and always exists once a season is locked (`native_home.roster`, A; **R9**'s roster on the join path), and **Add my round**, which works with no buddies, no plan and no index. `HOME_STATE_MATRIX.md` S15 carries the same two branches, and neither invents a tee time.

### 3.2 The link survives the boot, and the cold case has a door

**What is true, and what is not.** Today an App Store "Open" loses the invitation and the golfer must type a code they were never shown (`JoinIntent.store` has exactly one call site, `CupSeasonApp.swift:35`). Four fixes make the link survive **the boot** — the app being installed, backgrounded, bounced to the card gate, killed:

1. `JoinIntent.pending()` is read on **`DoorView`** and on **`CardGateView`**, not only on the route handler.
2. The Smart App Banner's `app-argument` carries the code — **delivered by Safari on a later visit**, which is a real path once the app exists on the phone.
3. An `NSUserActivity` handler for the universal link (the same path as `.onOpenURL`, a different API).
4. **`JoinIntent.clear()` moves to after the covenant resolves** — today `RootView.swift:43` clears it on appear, so a golfer bounced to the card gate loses the invitation between two screens of their own signup.

**None of the four survives a cold install, and iOS does not offer a mechanism that would.** After an App Store install the system passes nothing to the app: `.onOpenURL` (`CupSeasonApp.swift:29-37`) never fires, so `JoinIntent.store` is never reached, and parts 1 and 4 only help once an intent has been stored. There is no deferred deep linking on the platform. A builder chasing "the link survives a cold install" spends a week on something that does not exist.

**So the cold case gets a door instead of a promise.** The primary recovery is the door's **"I have a code"** (§5.3), which is why that control is in this wave and not a later one — a golfer who taps a link, installs, and opens finds a field that asks for the one thing the sender can re-send in the same thread. The secondary recovery is **re-tapping the original link**, which does work once the app is installed, and which the web landing tells them to do in one line: *"Already installed? Tap the link again."* If a genuine deferred link is ever wanted, a first-launch clipboard read is the only mechanism, and it is **its own entry with its own privacy note** — not a clause here.

### 3.3 Taps and seconds

| Step | Taps | Target |
|---|---|---|
| Link → App Store → open | 2 | (out of our hands) |
| Door → email → code | 3 (+ email, 8 digits) | 35 s |
| Card | 2 (+ name) | 18 s |
| Covenant → Join | 1 | 12 s (read) |
| Welcome → Done | 1 | 4 s |
| Home → **Say you're in** *(only if a plan exists — usually it does not)* | 0–1 | 3 s |
| Home → **Add my round** *(the branch that always exists)* | 1 (+ a score) | 12 s |
| **To a first DONE act** | **10** | **≈ 75 s** with a plan · **≈ 85 s** without |

The crew step (§2, frame 3) is **skipped for an invitee** — they arrived with people. D116's "invitees skip the explainer" survives as "invitees skip the question they have already answered".

### 3.4 What the other party sees

- Galen's Home, Tier 2: **"Marcus is in. Six of six."** — VERDICT, one item, from `native_home.memberships` (A) via **R1**.
- Galen's board: the existing `posts` system row from `join_league` (`20260830300000_join_window.sql:215-220`), unchanged.
- Galen's push: none. A join is feed-only under D248's `system` split — the roster filling is not an emotion.
- If Marcus said he was in for Saturday, Galen gets `rsvp` (A, the existing nudge and the best anticipation surface in the product): **"Marcus is in for Saturday, 7:10 at Papago."**

### 3.5 Failure and empty branches

| Branch | What happens |
|---|---|
| The code is dead or the league was deleted | *"No season with that code. Check with whoever sent it."* (`JoinService.joinError`, `JoinLeague.swift:117-121`, kept — it correctly reads as the Pro's problem, not the golfer's). |
| The season is in `setup` | The server's own sentence, verbatim (**L-32**): *"The Fellas isn't open yet — the Pro is still locking in the rules. Try again once they have."* (`_join_gate`, `20260830300000:54-56`). The invite is **kept**, and Home carries a Tier-6 item: *"The Fellas opens when Galen starts it."* |
| Past the halfway turn | The server's sentence, verbatim: *"Past the halfway turn — the roster's set for this season. They're welcome on the tee sheet, and in the next one the moment you run it back."* The door offered instead is **the schedule**, which is genuinely open (D107). |
| The season is `complete` | *"That season is finished — ask the Pro to run it back."* plus, for the newcomer, **Find golfers** and **Add my round**. Never a dead end. |
| "Not now" on the covenant | The invite is **kept** in a `declined` state, the code is kept, and Home carries a Tier-6 item: *"The Fellas is still holding a seat for you."* Today declining is terminal on the phone. |

### 3.6 The aha line

**"You're playing Saturday at Papago with five people, and there's a table."** It is reachable in one screen because the invitation carried the people with it.

---

## 4 · The first round — Add my round

**Goal.** The smallest useful act in the product: course, score, done. It works with no buddies, no season, no index and no GHIN, and it produces a real receipt. This is **P-2** and it is the flow every other flow funnels back into.

**Entry points.** The ⊕ (long-press → the composer directly) · the ⊕ cover's second row · Home's first foot door **Add my round** · every explicit "Add a round" CTA in the app (`presenter.postOnComposer = true`, `MainTabView.swift:296`) · the epilogue's next act · a weekend's page after the day.

**Current files.** `Post/PostCoverView.swift` (the cover, ~1,000 px of dead space, SV-22) · `Post/PostRoundScreen.swift` (the composer) · `Post/PostRoundModel.swift` · Kit `Post/PostCard.swift`, `Post/PostService.swift` · `Post/FinishCeremonyView.swift` · `Post/EpilogueSheet.swift`.

### 4.1 The ⊕ cover — three rows, live first (L-40)

```
  PLAY                                            [Close]
  ▌ ● Score it live — you and the group, hole by hole      ← ember, first
  ▌   Add a round you played
  ▌   Plan a round
```

- **L-40's clause is held immutable**: live leads the ⊕ in ember. The 90 % case is served three other ways, all of which exist or are one line — a **long-press on the ⊕** opens the composer with the gross field focused, every explicit "Add a round" CTA already jumps there (`PostCoverView.swift:30-35`, D110's own addendum), and Home's first foot door is Add my round.
- When a live round is open, the ⊕ **opens the round** — it agrees with `LiveNowBar` (`MainTabView.swift:134`) instead of offering the same door twice.
- The cover's dead space closes: three rows, one line of gloss each, nothing else.

### 4.2 The composer

```
  Your round                                  [Close]
  PAPAGO GC  ›                                  ← last course, a chip
  ┌──────────────────────────────────────┐
  │              84                      │      ← ONE box, focused on open, SANS
  │            YOUR GROSS                │        (a focused numeric input is a
  └──────────────────────────────────────┘        control — serif never goes on one, L-29)
  Blue · 71.2 / 128 · today  ⌄                  ← one editable line, all inherited
  Who was out there?  ( Galen ✓ ) ( + )         ← optional; buddies and league mates only
  Add my round                                  ← sticky, ember
```

**Asked: one number.** **Inferred:** course, tee, rating, slope and date, from my last posted round at that course, shown as **one editable line** rather than five fields (`PostRoundScreen.swift:143-215` is five fields and a fold today). This is vision principle 2 applied to the one screen the whole product depends on.

**Behind the fold, unchanged and complete (P-6):** 18/9, front/back, the pars sheet, the scorecard scan, the photo, the date sheet, "How points work" (`PostRoundScreen.swift:219-368`). Nothing is deleted.

**Four defects on this path, fixed here because they sit on it:**

| Defect | Today | Fixed |
|---|---|---|
| The one consequential direct write on the phone | `db.from("rounds").insert(…)` at `PostService.swift:84`, with `round_holes` best-effort at `:93` | **R11 `post_round(p_gross, p_course_id, p_tee_id, p_course_label, p_played_on, p_played_with)` → `{round, epilogue}`** (B). **L-03**: a write with game consequences is an RPC. The holes insert stays best-effort, mirroring the web, so a hole-detail hiccup never un-posts a round |
| PP-01 · the rating guard | A blank rating posts 0 and hits a check constraint; the web has had the guard since `index.html:6989-6999` | Rating and slope are inherited, so they are never blank. A hand-typed course prompts *"Type the rating and slope off the scorecard — they're on the back of the card."* An assumed rating is **never invented**: a round with no rating posts to your rounds, earns **no** season points, and the receipt says so (**V-3**) |
| PA-025 · the placeholders | `72.1` and `128` read as values (`PostRoundScreen.swift:194-195`) | `—` and `—` |
| The hand-typed course | `PostPayload.build` sends `api_course_id: card.courseId` and a typed course has none (`PostCard.swift:291-307`), so it never gets a course key and never becomes a "recent course" | A typed course mints a `course_key` the same way the live round does, so the next post inherits from it |

### 4.3 Taps and seconds

| Path | Taps | Typed | Target |
|---|---|---|---|
| ⊕ long-press → `84` → Add my round | **2** | 2 digits | **18 s** |
| ⊕ → cover → Add a round you played → `84` → Add my round | 3 | 2 digits | 24 s |
| First-ever round (no course memory) | 5 | course, 2 digits, rating, slope | 55 s |

The measured baseline is `post_submit` p50 39 s / p90 76 s. The second row must beat the p50 and the first row must halve it; §18 says how that is checked.

### 4.4 What the other party sees

- **A buddy with a shared season**: the round lands on the board through `round_to_board()` (A) and in their wire through `home_feed` (A). Push: `round` (A), landing on the receipt — **fanned by person, not per league** (D248), so a golfer who shares three seasons with me stops getting three pushes for one round.
- **A buddy with no shared season**: today **nothing at all reaches them** — `posts_home_check` requires `league_id` or `event_id` (`20260716160000_ryder_slice3.sql:26-28`), so a leagueless round has no post row, cannot be reacted to, and cannot fire the webhook. **C-1 (D238)** gives a round a person home (`posts.profile_id`), which is what makes `friend_round` possible at all. Push copy: **"Galen posted 84 at Papago."**
- **Someone I tagged in "Who was out there"** gets a decision card, not an assertion: *"Marcus says you played Papago on Saturday — that right?"* → **Yes** / **No**. **C-2 (D239)**: `round_players(round_id, profile_id, confirmed_at)` + `confirm_round_partner` (**R15**). A tag is **never a vouch** (**L-19**) and the receipt says "Played with Marcus" and nothing about attestation.

### 4.5 Reads and writes

- Reads before: `native_home.profile` (A) for the index and the course memory · **R3**'s `profile.last_round_on` / `last_gross` · the course cache (`api_courses`, A).
- Writes: **R11 `post_round`** (B) → `rounds` insert → `score_round()` trigger → `v_rounds_ranked` → `round_to_board()`; `round_holes` best-effort; `round_players` rows (**C-2**).
- Reads after: `round_epilogue` (A, extended by **R7**) — returned **inside R11's response**, so the ceremony and the epilogue do not cost a second round trip.

### 4.6 Failure and empty branches

| Branch | What happens |
|---|---|
| Offline | The card is held and the post retries. The composer says *"Held. It posts the moment you're back."* — never a silent success, and never a spinner in content (**L-32**). |
| No index yet (< 3 rounds) | The ceremony's broken assertion is fixed (PP-03): instead of "beat your number by N" to a golfer with no number, it says *"Eighty-four at Papago. Your number starts building — two more and it goes live."* |
| No rating (hand-typed course, skipped) | Posts to your rounds; earns no season points; the receipt says *"No rating on this one, so it builds your number and nothing else."* |
| The round is outside every season window | It posts to your rounds and builds your number, and the receipt says which (**L-13**): *"Outside the Fellas' window, so it's yours and not the table's."* |
| The insert fails | The server's sentence, verbatim, and the card is **kept** — the golfer never retypes a score. |

### 4.7 The aha line

Third round: **"Your number is live: 12.4."** For a golfer with buddies, first round: **"Galen and Jade saw that."**

---

## 5 · Joining a competition

**Goal.** Every join — by link, by code, or by an in-app invite — passes the same covenant, at every stake including $0. **L-12**, and it is the one law this product breaks on two of its three paths today.

### 5.1 The covenant, which is the same screen on all three paths

> **Before you join the Fellas**
> **Galen Fischbeck runs the season (the Pro).** Marcus, Dev, Tash, Ravi, Jules and two more are in.
> Thirteen weeks from Saturday, Sep 12. **$50 each.**
> Standard rules: honor scores, best three a month count, two a month keeps you in.
> It ends with a four-week Cup Final between the top two.
> Cup Season keeps the ledger; the money moves between friends.
> If you take it: sixty percent to the champion, twenty-five to the runner-up, fifteen to the points king.
> *(with no posted rounds)* With no posted rounds your starter number scores your first cards until three of your own take over.
>
> **Join — I'm in for $50** · **Not now**

- **WHO comes before the money.** The roster is the fact every persona wanted and no client shows.
- **L-09**: the ledger line is printed from `MoneyCopy.ledger` (`MoneyCopy.swift:28`), never retyped. It appears **only when the stake is above $0**, and so does the split clause under it — which answers the question a persona asked out loud (*what does $50 buy*) on the screen where she asked it, rather than behind a rules door she has not met.
- **At $0** the same screen renders without the money lines, without the split, and the button reads **Join the Fellas**. It still renders. Today **both clients fail open at $0** — `JoinLeague.swift:104` returns nil unless `buyinCents > 0`, and `index.html:17705` does the same — so the golfer who joins a free season never meets the Pro, the length, the rules or the ending.
- **The starter clause renders above $0 and below it**, whenever the joiner has fewer than three posted rounds. `score_round` reaches `profiles.index_current` before its own-differential fallback, so a starter number really does score the first cards, and a golfer joining the night before a first tee is entitled to know that before she taps (§2.1, `INFORMATION_ARCHITECTURE.md` §11.1).
- **Reads, and three of them are new work.** `join_covenant_info(p_code)` (A, `contract.psv:166`) returns name, buyin, preset, **floor**, finish, structure, `has_pay_note`, `buy_in_due_on` (`20260830040000:76-85`) — and **`Covenant.init` drops `has_pay_note` and `buy_in_due_on`** (`JoinLeague.swift:67-74` decodes name, buyin, preset, floor, finish and nothing else), which are exactly the two facts the money line and §13.4's "Ask Galen" branch need. **`phase` is not returned at all** and is added by R9. So the screen above needs **R9**: `roster{count, names[6], markers[6], pro_name}` · `starts_on` · `weeks` · `counting_cap` (the payload's `floor` is the *other* number, so "best three a month count" is unsayable without it) · `split{champion, runner_up, points_king}` · `phase` — all **granted to signed-in callers only, anon signature unchanged, fail-closed**. `join_covenant_info` is one of L-45's twelve anon endpoints; none of this may ride the anon path.

### 5.2 By link — `?join=CODE`

Screens: §3's five. The link is the invited path and it is written up there in full. Two facts belong here:

- **The join itself** is `join_league(p_code)` (A). The window is `_join_gate(p_league, false)`: open before the first tee, closed to self-serve after it, closed entirely past the halfway turn (`20260830300000:66-78`). Each refusal is the server's own sentence, passed through verbatim (**L-32**).
- **What Galen sees:** the roster count moves on his season page and his Home; `posts` gets its system row; no push (a join is not an emotion).

### 5.3 By code — typed

Two doors, and both need it:

1. **Signed out**, on `DoorView` — **"I have a code"**, validated by `league_by_code` (A, anon) before the email round trip. New on the phone.
2. **Signed in**, from the intent sheet's footer *"I have a code →"* and from Home's fourth foot door **Join with a code** — `JoinLeagueFlow.swift:35-42`, kept.

> **Your code**
> `League code` · **Join**
> *Whoever's running it will have sent you one.*

The placeholder is **`League code`**, not `8-digit code`: prod's codes are **alphanumeric** — 9 leagues at eight characters and 4 at six, and §7.5's own example is `8F3K2P7Q` — while **L-06 owns "8 digits"** for the email OTP, which this golfer met four minutes earlier in the same flow. Two different eight-character fields, one of them digits-only, is a trap the copy can simply not set. T-13 owns the noun.

Then §5.1's covenant, then the welcome, then Home. **Taps: 2 (+8 characters) · target 25 s.**

**Failure:** *"No season with that code. Check with whoever sent it."* (`JoinLeague.swift:117-121`, kept). Empty: the field opens focused with the keypad up; there is no state where this screen has nothing to do.

### 5.4 By in-app invite — the path that skips the covenant today

`InvitesBanner.swift` renders a one-tap **"Accept & join"** (`:71`) whose handler calls `people.respondInvite` → `respond_invite` **directly** (`:84-90`). A golfer accepts a $50 season without ever seeing the $50. That is A-7, and it is a live **L-12** violation on the shipping client.

**The fix is four lines of routing, not a new screen.** The invite row's primary control becomes **See the terms**, which fetches `join_covenant_info` + **R9** for the invited league and presents §5.1's covenant. **Join — I'm in for $50** then calls `respond_invite(p_id, true)` (A). **Decline** stays where it is and stays one tap — *saying no must always work*, which is the server's own rule (`respond_invite`'s decline branch is ungated, `20260830300000:229-231`).

> **Galen put you on the Fellas.**
> Six golfers, thirteen weeks from Saturday. $50 each.
> **See the terms →** · **Not now**

**Taps: 2 · target 15 s.** What Galen sees: his invite row flips to a member row; `push` fires nothing (his own act triggered it — D248's "the event push stops pinging its own author" applies to invites too).

### 5.5 A member never sees the Pro's tool

**L-12**'s other half. A member inside a season who taps **Start something** gets the intent sheet with "Run a season" meaning *a new one*, and their in-season acts are **Post a forfeit** and **Call someone out** — real acts, not a disabled button. `WizardModel.load` already refuses a non-`setup` league (`WizardScreen.swift:238`: `if head.phase != "setup" { alreadyLocked(id); return }`) and D40 is untouched.

---

## 6 · Creating a competition — the five intents

**Goal.** An organiser says a sentence and gets a competition. They never choose an object; the app chooses it. **P-4**, D225, and the death of `EventPickerSheet` ("Ryder LIVE · Bracket SOON · Major"), which is a menu of schema objects.

**Entry points.** Compete's head (**Start something**) · Home's second foot door · the post-round next act · a person's page · Golfers → a buddy row.

**Current files.** `Events/EventPickerSheet.swift` (**deleted**) · `Wizard/WizardScreen.swift` · Kit `Wizard/WizardState.swift` · `Wizard/LeaguelessDoors.swift` · `Home/HomeView.swift:178-190` (the `+` menu, retired into the four foot doors).

### 6.1 The intent sheet

> **What do you want to do?**
>
> **Play with my friends** — a round with whoever is around
> **Run a season** — weeks of golf that add up to a table
> **We're playing this weekend** — one day, and a name for it
> **I want to beat one guy** — you and him, whatever length you like
>
> ─────
> **Put money on it** — add a pot to any of the above
> *I have a code →*

Five sentences, no object nouns. **The fifth is a modifier and renders as a footer line**, below a hairline, because money is a choice *on* a competition and never a competition (**L-11**, D46 — two of two organisers in the audit met a $75 stake they never chose). Nothing is minted by opening this sheet.

### 6.2 What each intent resolves to

| Intent | Resolves to | RPCs | New? |
|---|---|---|---|
| **Play with my friends** | a live round now, or a planned round (§6.3) | `start_live_round` (A) · `declare_round` (A) | no |
| **Run a season** | a season and its crew name (§7) | `create_league` → `lock_league` (A, + **R18**) | one defaulted arg |
| **We're playing this weekend** | a **named weekend** — a plan with a name and a game (§8.1). **It mints no trophy**, which is why the gloss says *a name for it* and not *one trophy*: a sheet may not sell a door that does not open (**L-32**, and C-3/D240's own text refuses the trophy) | `declare_round` + **C-3** + **R22** | two columns, one read |
| **I want to beat one guy** | **the golfer, then the length — all three lengths always offered** (**R-F**, §9) | `start_live_round` · **R19 `call_out`** · `create_league`/`lock_league`/`invite_golfer` | one RPC pair |
| **Put money on it** | the buy-in dial on a season · the stake field on a live game · a **forfeit** for pride (§6.4) | `lock_league(p_buyin_cents)` · `create_forfeit` (widened, **C-5**) | one widening |

### 6.3 Intent 1 — "Play with my friends"

**Goal.** The organiser has no competition in mind; they have people and a day.

**Screen A · When?**

> **When are you playing?**
> **Right now** — score it live, hole by hole
> **A day this week** — put it on the schedule

**Right now** → `LiveSetupView` (§10.1). **A day this week** → `DeclareRoundSheet` (§8.1's weekend, minus the name if they do not want one).

**Taps: 2 to a decision, then §10.1 or §8.1.** **Target: 4 s to the fork.**

**Why this fork and not a guess:** it is the one question the app genuinely cannot infer, and it costs one tap to avoid dropping a golfer into a live scorer they did not want. Everything after it is inferred.

### 6.4 Intent 5 — "Put money on it"

**Goal.** Money attaches to a competition that already exists, or to the one being created. It never creates one.

**Screen A · What's it on?** — a list of what is actually live for me, from `native_home` (A):

> **What's the money on?**
> **The Fellas** — thirteen weeks, six golfers, no pot yet
> **Saturday at Papago** — four in
> **You and Galen** — nothing on it yet
> ─────
> **Something new →** *(returns to the intent sheet)*

**Screen B, by what was picked:**

| Picked | What opens | Write | Law |
|---|---|---|---|
| A season **before its first tee** | the buy-in row: **Bragging rights ✓ · $25 · $50 · $100 · Other ⌄** | `lock_league(p_buyin_cents)` (A) | **L-11** — Bragging rights is selected. **Other** opens a numeric field, because `WizardDials.stakes` is `[0, 25, 50, 75, 100, 150, 200]` (`WizardState.swift:17`) and **$20 is impossible today** |
| A season **already under way** | *"The Fellas started on Saturday and the rules froze at the first tee. You can put a forfeit on it."* → the forfeit sheet | `create_forfeit` (A) | **L-12** — rules freeze at the first tee. A pot cannot be added to a running season, and saying so is more honest than hiding the door |
| A weekend or a plan | the forfeit sheet, scoped to the plan | `create_forfeit` (A + **C-5**) | T-02 — an optional stake is a **forfeit**, never a fourth noun (spine amendment A-4) |
| A live round | the game card's stake field, which already exists (`LiveSetupView.swift:296`) | `start_live_round(p_config)` (A) | **L-40** — side games settle between friends and **never touch season points**, said on the card (D133 (3)) |
| You and one guy, no season | the forfeit sheet | `create_forfeit` (A + **C-5**: `forfeits.league_id` nullable, `event_id` / `scheduled_round_id` added, exactly one home) | **0 rows in prod**, the safest migration in the set. `forfeits` has **no money column** by rule (`20260724120000:10-13`) and that rule is load-bearing for store review |

**The forfeit sheet** is the one that exists (`League/PotPane.swift:186-215`), moved out of the pot pane so it is reachable without a season:

> **What's on it?**
> **Name it** `The Lawn Bet`
> **The terms** `Loser mows the winner's lawn`
> **Who** ( Galen ) ( The field )
> **When it settles** `Sunday's clash · first ace · the Cup Final`
> **Put it on the record**

**Taps: 3 (+ two short fields) · target 30 s.** **What the other party sees:** the forfeit appears on the shared surface's ledger and, where a season exists, as a board row. No push — a forfeit is a fact, not a summons.

**Failure and empty:** if I share nothing with anybody, Screen A holds one row — **Something new →** — and the sheet says *"Nothing to put money on yet. Start something first."* An empty state with a door (**L-32**).

### 6.5 The one rule that governs all five

**Nothing is minted until the organiser has said what they want.** Six of six `setup` leagues in prod are a founder alone, because the wizard mints a `leagues` row on a **name** (`WizardScreen.swift:70-86` → `:252-268`). In every flow below, the row is minted at the **Start** tap, in one transaction with `lock_league` (**L-41**). An abandoned intent sheet leaves nothing behind, and the check is `select count(*) from leagues where status='setup'` before and after (**A-3**).

---

## 7 · Season creation — the Pro's path

**Goal.** An organiser gets from "I want to run a season" to a published season with an invite link in their hand, in three questions, without meeting the words *league*, *bylaws*, *lock*, *preset*, *structure*, *allowance*, *counting cap* or *participation floor*.

**Entry points.** The intent sheet's **Run a season** · Home's foot door **Start something** · a wrapped season's **Run it back** (§7.7) · the epilogue's next act *"Four rounds between you this month — four is a season."*

**Current files.** `Wizard/WizardScreen.swift` (three steps; the name sheet at `:70-86`; `create()` at `:252-268`; **no Close**, CJ-08) · `Wizard/WizardSteps.swift` · Kit `Wizard/WizardState.swift` (the stake ladder at `:17`; the preset cards at `:62-72`) · `Wizard/WizardLockShareSheet.swift` (a bare `ShareLink`, `:29-57`).

### 7.1 Step 1 · Who's playing?

> **Who's playing?**
> Pick from your buddies, or send a link when you're done.
>
> ( ✓ Galen Fischbeck · The Saguaro )
> ( ✓ Jade Ruiz )
> ( Dev Patel )   ( Tash Boyle )
>
> **+ Someone not here yet — text them a link**
> **Just me for now**
>
> *Two is a season. Four opens squads.*

**The empty branch — which is every first-time organiser's state, and it was missing.**

> **Who's playing?**
> *No buddies yet. Two ways in.*
>
> **Find your friends** — *check your contacts for golfers already here*
> **+ Someone not here yet — text them a link**
> **Just me for now** — *you can add people any time before the first tee*

A golfer signed in an hour has no `my_friends` and no `recent_partners`, and `search_golfers` matches **an exact @handle or an existing relation only** (L-37) — so they cannot find two friends who are already on the app, which is exactly where persona D stalled. §7.9's failure table covers *"the Pro publishes alone"*, which is a **post-publish** state; this is the state before the first tap.

**Contacts matching sits here** (**R-G**, **C-11**, drafted as **D251**), with its consent sentence at the point of the ask — *"We'll check your contacts against the golfers already here. We send hashes, never your contacts, and we keep nothing that doesn't match."* — the ability to decline and still finish the step, and a **gracefully empty result**: *"None of your contacts is here yet. Text one a link."* With 39 golfers on the app most matches return nothing, and the copy is written for that rather than against it.

- **Asked:** who. **Inferred:** the **structure** — solo at two, a question at four or more, derived from `Bylaws.structMin` and never printed as a literal. This kills two live bugs at once: `squads2` minted for a roster of one (D206), and the "2 Squads selected and greyed out at the same time" state.
- Reads: `my_friends` (A) · `recent_partners` (A) · `search_golfers` (A) · **`match_contacts(p_hashes)`** (**C-11**).
- **Nothing is written by this step** except, if the golfer consents, their own `profiles.contact_hash`.

### 7.2 Step 2 · How long, and when's the first tee?

> **How long, and when's the first tee?**
> **Thirteen weeks** ⌄     **First tee: Saturday, Sep 12** ⌄
>
> *Ends Saturday, Dec 12. Rounds you post before the first tee still build your number.*

- **Asked:** two dials, both defaulted (thirteen weeks is D206's default; the first tee defaults to the next Saturday, `WizardDials.startISO`).
- The trailing sentence is **L-13** stated in a golfer's words, at the moment it matters: six of six audit posters were promised points a week before their first tee.
- **The weekday is real.** `spec/spec-v1.0.md` §14.0 v1.1 dropped the Sunday snap and D213 recorded it; the label derives the actual weekday and never hardcodes one.
- Reads: none. Writes: none.

### 7.3 Step 3 · What's on it?

> **What's on it?**
> ( **Bragging rights** ✓ )  ( $25 )  ( $50 )  ( $100 )  ( Other ⌄ )
>
> *— if above $0 —*
> $50 each. Six in makes $300.
> **Cup Season keeps the ledger; the money moves between friends.**
>
> **How do they pay you?**  `Venmo @galen`
> *Everyone who owes will see this. It's the only place they can look.*

- **L-11**: **Bragging rights** is selected. **L-09**: the second line is `MoneyCopy.ledger`, printed verbatim from the constant (`MoneyCopy.swift:28`), never retyped.
- **Other** opens a numeric field. `$20` is impossible today (`WizardState.swift:17`).
- **The payment note is required above $0** (D225) and is written **in the same transaction as the publish** via **R18** (`lock_league` + `p_pay_note`). See spine amendment **A-2** — today `set_buy_in_terms` has **zero call sites on the phone**, so a Pro on iOS cannot record it at all, and two persona walks ended owing money with nowhere to look.
- At $0 the whole block below the ladder is **absent**, not greyed (**L-10**: a $0 season shows no pot surface anywhere).

### 7.4 Then, and only then

> **Standard rules.** Honest scores, best three a month count, two a month keeps you in, ninety-five percent of your number.
> *More settings ⌄*
>
> **Name it**  `Galen & Jerecho`   ← pre-filled from the roster
>
> **Start the season**

- **The name is asked last** and pre-filled. The `leagues` row is minted **at this tap**, in one transaction with `lock_league` (**L-41**).
- **The preset card stops naming its dials.** `WizardState.presets` (`WizardState.swift:62-72`) prints *"95% hcp · post what you'd post to GHIN · best 3 / mo count · 2-round floor"* on a preset card, which is a **live L-16 violation** on the shipping client. It becomes one sentence, and the wording is **TERMINOLOGY's**, cited rather than restated: *"Standard — the default. Honest scores, light guardrails."* (`TERMINOLOGY.md` §2.3, the presets row).
- **More settings** holds all twelve dials verbatim with their ⓘ paragraphs (`WizardDials.structNotes`, `draftNotes`, `finishNotes`, `payNotes`). Nothing is deleted (**P-6**).
- **The wizard gains a Close on every step** (CJ-08: it is a `fullScreenCover` with no exit today).

### 7.5 The publish, and the invite in the same breath

One tap on **Start the season** does all of it:

```
create_league(p_name, p_code)          (A)  ─┐
lock_league(p_league, …, p_pay_note)   (R18) ┘ one moment, minted on the tap
invite_golfer(p_league, null, ‹each picked buddy›)   (A) — one per row from step 1
```

Then the share screen, **which is the same screen, not five screens later**:

> **The Fellas is live.**
> Thirteen weeks from Saturday, Sep 12. Two in, and the link works for anyone.
>
> `cupseason.app/?join=8F3K2P7Q`
> **Copy link** · **Copy message** · **Share…**
>
> **Open the season →**

`WizardLockShareSheet.swift:29-57` offers a bare `ShareLink`; it gains the web's four controls (D114's phone half). The URL is visible as text, because a golfer reading it aloud in a group chat is a real thing that happens.

### 7.6 Taps and seconds

| Step | Taps | Typed | Target |
|---|---|---|---|
| Intent sheet → Run a season | 2 | — | 5 s |
| Who's playing (2 buddies) | 2 | — | 15 s |
| How long / first tee (defaults) | 1 (Next) | — | 8 s |
| What's on it ($0) | 1 (Next) | — | 6 s |
| What's on it ($50) | 2 + note | `Venmo @galen` | 25 s |
| Name it → Start the season | 1 | — (pre-filled) | 8 s |
| Share | 1 | — | 6 s |
| **$0 season, published and shared** | **8** | **0** | **≈ 48 s** |
| **$50 season, published and shared** | **9** | **~14** | **≈ 68 s** |

Today: the name is asked twice, the second step recites four dials on three cards, the third prints ten all-caps bylaw rows, and the invite surface is the fifth screen.

### 7.7 Run it back

A wrapped season's Pro gets **Run it back**; a member gets **Ask Galen to run it back**, which sends one nudge, once per season per member (**L-20**). Today `RunItBackCard` has no role gate and mints a **new league id and a new code**, so every member must re-join — the tax D41 left behind.

**R10 `run_it_back(p_league)`** (B) clones `league_settings`, mints the `seasons` row and **re-seats every living `league_members` row**. Season 2 of the Fellas is a second `seasons` row under the same `leagues` row, which is what §2.2 of the IA says a season *is*.

**What the Pro sees when a member asks.** The member's nudge is not a message into a void: it renders on the Pro's Home as a band-6 item, **counted and never itemised** — *"Three of the Dew Sweepers have asked for season two."* → **Run it back →** (`HOME_STATE_MATRIX.md` S7). Naming who asked would turn a request into a chase (L-22). **And the member's own Home does not go blank once their one ask is spent**: the lead keeps its sentence and swaps its verb to **See how it ended**, with **Start something** as the ranked act (S7). The nudge is once per season per member (L-20), so there is no second ask and no count of how long the Pro has not answered.

**What every member sees when it happens:** push `season_countdown` (D248, **anticipation**) — **"The Fellas runs it back. First tee Saturday."** — landing on the season page. Nobody re-joins and nobody re-reads the covenant, because the terms are the ones they already accepted; if the Pro **changed** the stake or the length on the run-back, the covenant fires again for everyone. That branch is the one thing R10 must not get wrong.

### 7.8 The Pro before the first tee, and during

**Before** (the state persona D reached): the season page's head is a sentence, not a checklist — *"One golfer in. Two makes a season, four opens squads. The link is yours."* — with **Share the invite link** as the one action.

**During**: a **row at the foot of the season page**, never a mode and never the identity of a screen (**V-1**, O-05 → D226). Seven verbs, each already an RPC: `invite_golfer` · `mark_buy_in` · `announce` · `close_roster` · `set_member_bye` · `set_league_finish` · `request_league_cancel` (all A). Each has a stated moment where it surfaces on Home as a Tier-6 item (`INFORMATION_ARCHITECTURE.md` §7.5).

**Draft night, both seats** (`Draft/DraftNightScreen.swift`, which today shows the Pro's screen to a member with the verb swapped, CH-13):

- **The Pro:** *"The hat is ready. Six in, four to a squad."* → **Draw the squads** (`randomize_squads`, A) → the draw animates → **Start the season →**.
- **A member:** a different screen — *"Galen draws the squads before the first tee. It's random — nobody picks."* → **See who's in →**. No verb they cannot press.
- All 13 prod leagues are `draft_type = 'random'`; the `assign` and `snake` branches (`DraftNightScreen.swift:126-262`) have never been reachable and are **specified as deleted** unless the wizard offers them.

### 7.9 Failure and empty branches

| Branch | What happens |
|---|---|
| `create_league` succeeds, `lock_league` fails | The two are one transaction (**L-41**), so there is no half-state. If the whole tap fails, the sheet keeps every answer and says the server's sentence. |
| The Pro publishes alone | Legal and expected. The season page's head reads *"One golfer in. Two makes a season."* and the one action is the link. It is **not** an error and it is **not** a ghost — the row is minted deliberately. |
| A buddy in step 1 declines the invite | The roster shows them as invited-and-declined **only to the Pro**, once, with no repeat nudge (**L-20**, no shame). |
| Above $0 with no payment note | **Start the season is disabled** and the field carries *"They'll need somewhere to send it."* This is the one required field the wizard gains. |
| Offline at the publish tap | Nothing is minted. The sheet holds the answers and retries. |

### 7.10 Solo vs squads, said both ways

- **At two golfers** the season is D205's pair. It is **solo** by derivation, the weekly clash *is* the pair, and the product already has the right words: *"It's the two of you — every week is the clash."* (D207, `HomeLead.swift:68,85`). No draft night, no squads, no captain.
- **Above two golfers the clash is not mine most weeks, and every flow in this document must be read with that in hand.** `open_week_clash` seats **one pair per season-week** (`20260831160000:60-115`) and `home_clash` returns null unless I am one of the two (`:507-513`) — so in a season of eight, a member is spotlighted roughly one week in four. **Both real seasons in prod are n=2**, which is why the whole clash grammar reads as though it always applies. It does not: §10.3's clash row, §11.2's first epilogue rung and §16's pair line are the **n=2 and spotlighted-week** cases. The other three weeks are `HOME_STATE_MATRIX.md`'s **F6** — the pair that does have the week, rendered as somebody else's golf, never as a stake I cannot enter.
- **At four or more** step 1 asks one extra question — *"Squads, or every man for himself?"* — with the roster-fit line under it, and squads adds draft night (§7.8) and the squad table (`StandingsPane.swift:53-71`).
- **A squads captain** gains exactly one thing a member does not: a line on the squad's row naming who is short this month, with a door to the members sheet (`MembersSheet.swift:56-92` already renders captain pills, D58). There are no captain tools beyond that.

---

## 8 · Event creation — a weekend, the Ryder, a Major

Three moments, one page grammar, three different clocks. The word **event** is retired from every button (D12, `INFORMATION_ARCHITECTURE.md` §15.5): a one-day thing is **a weekend**, a two-team run is **the Ryder**, a championship window is **a Major**.

### 8.1 A weekend — the lightest moment in the product

**Goal.** "We're playing Saturday and it should mean something" becomes one screen and three taps, on rails that already send a push.

**Entry points.** The intent sheet's third line · Home's UPCOMING item *"Three of yours are out Saturday"* · Golfers → **Playing soon** · the schedule.

**Current file.** `Schedule/DeclareRoundSheet.swift` (`:44-76`), which today asks day, tee time, course, note and tags — and has **no name, no game and nothing on it**.

**The screen** (three new fields, all optional, all defaulted or absent):

> **We're playing Saturday**
>
> **Day** `Sat Sep 12`   **Tee** `7:10` *(optional)*
> **Course** `Papago GC`
> **Who's in**  ( Galen ✓ ) ( Jade ✓ ) ( Dev ) ( + )
>
> **Call it something** *(optional)*  `Saturday at Papago`
> **Playing anything?** ( Just golf ✓ ) ( Skins ) ( Match play ) ( Wolf )
> **Put something on it →** *(a forfeit — §6.4)*
>
> **Put it on the schedule**

- **Asked:** day and course. **Inferred:** the tee time is optional, the name is pre-filled from the course and the day, the game defaults to **Just golf**, and the golfers offered are `recent_partners` (A) ordered by who I actually play with.
- **C-3 (D240), amended by A-4:** `scheduled_rounds` gains **`name`** and **`game`** and *not* `stake_cents`; `declare_round` gains `p_name` and `p_game`, both defaulted and skew-safe. Money on a weekend is a **forfeit** (T-02, C-5) or the live round's own stake — never a second cents column outside the pot ledger.
- On the day, **Score it live** opens `LiveSetupView` pre-loaded from the plan — the bridge exists and already carries the course and the group (`LiveSetupView.swift:62-75`); **C-3** gives it the game.

**Taps: 4 (+ a course search) · target 35 s.**

**The weekend's page:**

```
  SATURDAY AT PAPAGO
  SAT SEP 12 · 7:10 · 4 IN
  Skins, $5 a hole. Carry-overs on.
  ─────────────────────────────────
  WHO'S IN     Jerecho ✓  Galen ✓  Jade ✓
               Dev is asked
  ON THE BOARD  "bringing the good clubs" — Galen
  ─────────────────────────────────
  Send the link →
  Score it live on the day →
```

**No seat count, no absence column, no nudge.** `scheduled_rounds` has no capacity column and C-3 does not add one, so "2 SEATS" was an assumed foursome — a number that counts nothing (**L-44**), and `SEATS` is on the §15 lint list. *"Dev — hasn't said"* named another golfer's failure on a surface, which **G7** forbids exactly as it forbids naming mine; an asked golfer reads **`Dev is asked`**, the state of the invitation rather than a verdict on the man. And there is **no [Nudge] control** — no RPC is minted to chase somebody onto a tee sheet, which keeps this page consistent with its own failure branch below.

**The non-host reads need R22.** `scheduled_rounds`' only SELECT policy is `sched_own` (`profile_id = auth.uid()`, `20260712150000:33`) and `my_schedule` returns `rsvp_in` and `tagged_names` — a count and names without ids (`contract.psv:206`). So **a tagged golfer cannot read the name, the game, or who has answered**. **R22** extends `my_schedule` with `name`, `game` and `rsvp[]{profile_id, display_name, marker, status}`; it is a return-type change, and its fallback is the row as it renders today.

**What the other party sees.** Each tagged golfer gets the existing `rsvp` push (A) — *"Galen put you on Saturday, 7:10 at Papago."* — landing on the plan sheet, where **I'm in / Can't** is one tap (`set_round_rsvp`, A). Their Home carries it as an INVITATION item, Tier 1, until they answer. A buddy who was **not** tagged sees it in **Playing soon** on the Golfers tab with **Ask for a seat →** — which writes a `push_nudges` row to the host and **never writes to the tee sheet** (**R16**, and D69's consent rule at `20260902203000:89-100` is intact).

**When it finishes**, the page offers the promotion once: *"Six of you played. Make it a thing?"* → a Ryder or a season. **A weekend may be promoted to a moment; never the reverse.** It gets no board of its own and mints no trophy.

**Failure and empty branches.** No course match → *"No match — type the course, rating and slope by hand."* (`DeclareRoundSheet.swift:237`, kept). Nobody RSVPs by the morning → **no nudge fires** and the page never counts absences (**L-22**); it says *"7:10 tomorrow. Two in."*

**Nobody tagged — and this is the organiser the brief describes.** The plan is mine alone and the page says *"Just you so far. The link works for anyone."* **That sentence is now true**, because the link exists: **C-12**, `shares.kind='plan'` and `?plan=TOKEN`. It is the same mechanism as the person link one more time — **one more value on the CHECK C-4 already widens**, one `share_info` branch, one `db-checks.sql` line, one AASA path — and the anon surface stays at twelve endpoints. Its landing names the day, the course and who is in; its one door is **Get the app**; on sign-in the token RSVPs the golfer onto the plan (`set_round_rsvp`, A) **and** mints a buddy request to the host (D80's two-sided consent, unchanged).

**Without it there is no door at all for the organiser whose friends are not on the app**, and that is persona A's whole goal — three friends, none of them here, a competition this Saturday. `declare_round` tags **accounts only**; C-4's person link mints a buddy request, not a seat; and the season code is for a season he does not want. This is §28's fourth question — *can I organise a round with friends without learning terminology* — and the answer is Yes only because C-12 ships. Drafted as **D253**.

**Aha line:** *"Four of you, Saturday, and skins on it."*

### 8.2 The Ryder

**Goal.** Two teams, several weeks, one trophy. The engine is complete and shipping; what changes is the words and the doors.

**Entry point.** The intent sheet → **Run a season** → *"Or two teams instead of a table →"*, and from a season page's foot. It is deliberately **not** a top-level intent: no persona asked for one, and the intent sheet's five lines are the five things golfers say.

**Current files.** `Events/RyderSetupSheet.swift` (`:79-110`) · `Events/RyderRoomView.swift` · `Events/EventRoomScreen.swift` · `Events/EventChips.swift` (mounted **only** inside the league room, `ClubhouseView.swift:87`).

**The sheet, re-worded** (the fields are unchanged; `create_event`'s signature is untouched):

> **Two teams**
> **Call it** `The Grudge Match`
> **The sides** `Red` v `Blue`
> **How many weeks** ( 3 ⌄ )  **First tee** `Sun Sep 14`
> **Who's playing** — **Search the app or tap a buddy**
> **Create it**
>
> *You captain Red. Everyone you add gets an invite to accept; you draw or assign the sides once they're in.*

- **The Sunday rule is real and stays visible here.** `create_event` raises *"The Ryder starts on a Sunday — sessions run Sun to Sat"* (`20260830190000_ryder_dials.sql:43-45`), and the sheet's date picker offers **Sundays only** rather than letting the golfer discover the rule as an error. The sheet already surfaces that one server sentence verbatim (`RyderSetupSheet.swift:141-143`), which is the correct handling and is kept.
- **Words retired** (`INFORMATION_ARCHITECTURE.md` §15.5): "duel" → **the clash**; "session" → **week two**; "W-L-H" → **2 wins, 1 loss**; "SERIES LEVEL / DEFENDS / dead rubbers" → *"Red hold the Ryder"* and *"Blue can no longer catch them, which nobody has told Tash."*
- **The door that does not exist today:** a Ryder is reachable only from inside a league room, so a golfer with a Ryder and no season has no way in and no shareable address. It gains `CompeteRoute.event(id)` and a **`?event=` universal link** (§13.5 of the IA).

**Taps: 5 (+ a name) · target 50 s.** **The other party:** `invite_golfer(null, p_event, profile)` (A) → the existing `invite` push, landing on the event page. **Reads:** `event_lineage` (A) for "Last year, Blue took it 4–2" · `event_session_targets` (A) for the number to beat · `native_home.open_duels` (A — **decoded at `Models.swift:234` and read by no Home view today**).

**Failure and empty.** A non-Sunday date is refused before the tap, not after. A field of one is legal and the room says *"One in. It needs two sides."* A session that closes with nobody posted resolves to `halve` and **no "never showed" line is ever written** (D21's own recommendation, **L-22**).

### 8.3 A Major

**Goal.** A championship window: best card in N days takes the jug.

**The state today.** `create_major` exists (A, `contract.psv:117`), `MajorRoomView.swift` and `MajorSetupSheet.swift` are built, and the door is gated on `app_flags.ios.major`, read fail-closed (`EventPickerSheet.swift:17-18, :38`). **The flag is off in prod** while three Home occasion cards advertise a Major — a door that is sold and does not open, which is a dishonesty under **L-32/L-44**.

**The owner has ruled it: the flag opens** (**R-E**, drafted as **D252**). `app_flags.ios.major` is set true and the phone's Major surfaces are made good enough to receive the traffic. **Until the flag is on in prod the three occasion cards that sell a Major do not render** — they ship in the same wave as the flag and never before it. The Major is specified as follows.

> **A Major**
> **Name the jug** `The PIGL Championship`
> **Final day** `Sun Sep 28`   **Window** ( 4 days ⌄ )
> **Buy-in** `$0`
> **Who's playing** — **Search the app or tap a buddy**
> **Set the Major**

- Words: "the field" → **who's playing**; "the clubhouse" → **leaderboard**; "AWAITING THE HORN" → **opens Saturday**; "Yet to card" → **still to post**; **the jug** is kept and defined once.
- Reads: `major_leaderboard` (A, `contract.psv:184`) · `event_lineage` (A). Writes: `create_major` (A) · `add_event_player` (A) · `invite_golfer` (A).
- **L-11 holds here too:** the buy-in field defaults to `0` and shows no pot surface at $0.

**Taps: 4 (+ a name) · target 45 s.**

---

## 9 · Challenging a friend

**Goal.** "I want to beat Jake" gets an object. Four of them exist and the person's own state chooses the shape; **none of them is a new table**.

**Entry points.** The intent sheet's fourth line · a person's page (the four doors at its foot) · the head-to-head page · Golfers → a buddy row → **Play him**.

**The picker.** *"Who?"* → `my_friends` (A) then `recent_partners` (A), most-played first. One tap.

### 9.1 One more step, never a guess — the length

**The owner ruled the shape and ruled the words** (**R-F**). After the golfer, one question, and **all three lengths are always offered**:

```
  I want to beat one guy ›  <pick a golfer>

  How long?
  ▌ This Saturday   → a live match, on one card
  ▌ One week        → best round by Sunday takes it
  ▌ A season        → a table, and a cup at the end
```

| The length | What it mints | Built from |
|---|---|---|
| **This Saturday** | a live match on one card | `start_live_round(p_game:'match', p_players)` (A) — the free door, **L-40** |
| **One week** | the callout (§9.3) | **R19 `call_out`** (B) — D21 built as a Ryder at a field of two, **no new table** |
| **A season** | a two-golfer season (§9.2) | `create_league` → `lock_league(p_structure:'solo', …)` → **`invite_golfer`** (A; **not** `add_friend_to_league` — spine amendment **A-1**) |

**The person's state may order the three; it may never withhold one.** A golfer already in a live round sees *This Saturday* first; two who already share a season see *A season* last, and gain a fourth line — **Put a forfeit on it** (`create_forfeit`, A; T-02's noun) — because that is the act that fits what is already running. **The golfer never meets the object's name**, and the stake, if any, is a forfeit or the live game's own; never a fourth money noun.

*This settles the "which door is first" question the earlier draft filed as open, and §19 no longer carries it.*

### 9.2 "Make it a season" — the pair, in full

At two golfers a season **is** the pair: `league_settings.structure = 'solo'`, two `league_members`, the weekly clash is the pair and the Final seats two (D205, `decision-log.md:5542-5551`). Both real seasons in prod are exactly this.

> **You and Galen**
> **How long?** ( Thirteen weeks ⌄ )
> **First tee** `Today` ⌄     ← the first tee **may be today**: `v_starts := coalesce(p_starts_on, current_date)` (`20260902163000:156`), and `season_months` clamps at 1 (D143)
> **What's on it?** ( Bragging rights ✓ ) ( $25 ) ( $50 ) ( Other )
> **Name it** `Galen & Jerecho`
> **Start the season**

Then, and this is the amendment: **`invite_golfer(p_league, null, galen)`**, so Galen sees the covenant and agrees to the terms before he is on a pot sheet. **L-12.**

**Taps: 4 · target 30 s.** **What Galen sees:** the `invite` push — *"Jerecho started a season with you. Thirteen weeks, starting today."* — then §5.1's covenant, then **the two of them on a table**. The product already has the right sentences at n=2 and they are kept verbatim: *"It's the two of you — every week is the clash."* and *"You v Galen. Best round of the week takes it."* (D207, `HomeLead.swift:68,85,195-206`).

### 9.3 "Call him out" — the one genuinely missing case

D21 is **ruled and unbuilt** (zero code hits at tip). It is built here as a Ryder with teams of one and one session.

> **Call Galen out**
> **This week** — best round by Sunday takes it ⌄
> **What's on it?** ( Nothing, just the record ✓ ) ( A forfeit → )
> **Send it**

**What it mints** (all of it inside **R19 `call_out(p_opponent, p_closes_on, p_forfeit_terms)`**, one definer RPC, no new table):

| D21's clause | The engine's existing part |
|---|---|
| the window | one `event_sessions` row, opened and resolved by `run_event_sessions` (the cron) |
| the declared number to beat | `event_session_targets(p_session)` (A) → `native_home.open_duels{my_pvi, their_pvi}` (A) |
| the verdict | `event_duels.result ∈ {pending, a, b, halve}`, decided on best PvI in the window |
| the receipt | the round behind each side |
| the story | `event_post(p_event, body)` (A) |
| the anticipation push | N12, generalised — *"Galen posted. +2.3 to beat, three days left."* — the one true anticipation push in the product |
| the record | `my_rivalries` facet 2, which already unions duels with shared-season weeks |
| the trophy | minted at completion |

**Why R19 exists at all** (spine amendment **A-3**): `create_event` refuses any first tee that is not a Sunday (`20260830190000:43-45`), `draw_rule` no longer accepts `assign` (`:29-31`), and neither `add_event_player` nor `respond_invite` assigns a `team_id` (`20260830200000:70-74`; `20260830300000:222-226`). A callout raised on Thursday for Saturday cannot be created by the shipping RPC, and if it could, it would have no teams and therefore no clash. R19 mints the event, names the two teams for the two golfers, seats both **with their teams**, and writes the callout nudge. Roughly 60 lines of SQL. **D237's load-bearing claim — no new table — is untouched; its "no migration" claim is not true and the entry gains the clause.**

**D21's three flagged questions, closed in its own recommended direction:**

- **(a) The settle basis** is the best PvI in the window — the named band's own terms, labelled, never a raw differential (**L-14**).
- **(b) A tie** is `result = 'halve'`, rendered **"All square. Nobody buys."**
- **(c) Nobody posts** by the settle date: it resolves to whoever posted; if neither did, it halves and closes quietly. **No "never showed" line is ever written** (**L-22**).

**Three more rules that ride with the build:** buddies only, mirroring the RSVP consent rule (D69) — a callout is not an invitation to a stranger; **one open callout per pair at a time**; **zero points, always** — if a future version wants callouts to score, that is a new level-4 decision.

**Consent.** Galen is a buddy, so `add_event_player`'s own D148 rule permits the seat — but he still gets a door out. **R20 `respond_callout(p_event, p_accept)`** (B): his Home carries a Tier-1 item, **"Galen called you out"** / *"Best round by Sunday takes it. Nothing on it but the record."* → **I'm in** · **Not this week**. A decline closes the event silently, writes no story, and suppresses any further callout push from me this week.

**Taps (me): 3 · target 20 s. Taps (Galen): 1.**

**Failure and empty branches.** No buddies → the picker's empty state is *"Callouts are between buddies. Add one first."* with **Find golfers**. An open callout already exists with the same person → the door reads **See the callout →**. The window closes with no rounds → `halve`, quiet, no push, no line.

**The gate, kept from the engineer's seat:** nobody has ever seen the Ryder room in LIVE or COMPLETE (G-08), which is the entire life of a callout. **The reviewer seed's "The Grudge" is walked through a live and a completed session before this is committed.** If it does not hold, the named fallback is a `callouts` table and a two-week swing — and only then.

**Aha line:** **"You called it. You posted 84 — 2.0 under your number. Galen has to beat that off his."**

*Why not "Galen needs 82".* `event_session_targets` returns **PvI only** — `(index_at_post * allowance / 100.0) − differential` per side (`20260716150000:280-300`) — and so does `native_home.open_duels` (`20260902200000:579-580`). Turning my PvI into his gross needs his index **and** the rating and slope of a course he has not chosen yet. It is not a missing read; it is not computable. The sentence above is what the shipped N12 push already says, and it is on the §15 lint list so nobody writes the other one back in.

---

## 10 · Playing and recording a result

Two tenses. **Live** is the free door and the funnel; **after** is the composer of §4. Both end in the same place: a round on my card, a story on the wire, and one ranked next act.

### 10.1 Live — score it hole by hole

**Goal.** Four people on a first tee, one of whom has the app, start scoring in under a minute — including a guest with no account.

**Entry points.** The ⊕ cover's first row, in ember (**L-40**) · `LiveNowBar` when one is already open (`MainTabView.swift:134`) · a weekend's page on the day, pre-loaded · a nearby invite (`csNearbyInvite`, `MainTabView.swift:140`).

**Current files.** `Live/LiveSetupView.swift` (**the 20-concept specimen**: seven eyebrows, no fold, `:24-184`) · `Live/LiveRoundHost.swift` · `Live/LivePlayView.swift` · `Live/LiveFinishViews.swift` · `Live/LiveCardView.swift`.

**The setup, folded** — three concepts above the fold, everything else beneath:

> **Who's on this tee**
> ( You ) ( Galen ✓ ) ( + a buddy ) ( + a guest )
>
> **Where**  `Papago GC · Blue`   ⌄
>
> **What are you playing**  ( Just score ✓ ) ( Match play ) ( Skins ) ( Wolf )
>
> **Tee off →**
>
> ⌄ *Strokes, stakes, and the pars*

- **Above the fold: Who · Where · What.** Below it: the stroke ladder, the stake field, guest indexes, the pars sheet and the Bluetooth/nearby card — all unchanged and complete (**P-6**, **P-8**).
- **A guest needs no account** (**L-40**): added by name and index (`LiveSetupView.swift:131-132`), scored like anyone, and handed a claim link at the finish.
- **The game card carries its own three-line how-to, always** (D133), and one added sentence, which is a law stated in words: **"Side games settle between you. They never touch season points — your score posts like any round."**

**Taps: 4 (+ a course search on a new course) · target 45 s** — against `LiveSetupView`'s current seven eyebrows and twenty concepts on one screen.

**During.** `LivePlayView` unchanged. The Live Activity and its tap-back (`CSRoundActivityLink`, D155) unchanged; it **goes stale at 45 minutes** and says so (**L-44**).

**The finish.** `finish_live_round(p_live_round, p_cards, p_casual, p_result)` (A) writes every player's round, settles the side game and posts the settlement card. Then:

- **Me:** the finish ceremony (**L-31**, kept) → the epilogue (§11).
- **A player with an account:** their round is on their card; push `round` (A) → the receipt.
- **A guest:** a claim link, whose door sentence is the best first sentence in the product and is kept verbatim — ***"NAME — 84 at COURSE, Sat Jul 25. Enter your email to keep it."*** (`create_scan_claim` → `claim_round_info`, both A). **One addition:** the claim landing now also offers **the buddy request**, so a guest can become a buddy without joining anything.

**Failure and empty branches.** No signal mid-round → the local store keeps the card and syncs; the bar says *"Scoring offline. It'll sync."* A player leaves → their card finishes at the holes they played. `finish_live_round` fails → the cards are **kept** and retried; nobody retypes 18 holes. A guest never claims → the round stays attached to the link forever and no reminder is ever sent (**L-22**).

**What the other party sees.** A settlement card on the board of every league the players share (`finish_live_round`'s board write — today guarded by `if lr.league_id is not null`, which **C-1** removes so a leagueless group gets one too). Push: `settlement` (A) → the scorecard.

### 10.2 After — a round already played

This is §4 in full. Two additions belong to "recording a result" rather than to the first round:

- **"Who was out there?"** (**C-2**) is what turns a solo post into a result between people. It is optional, it offers buddies and league mates only, and it is a **claim with a state** — the tagged golfer confirms from their own Home, and until they do the head-to-head facet reads *"Galen hasn't confirmed."*
- **The same-day, same-course fallback** is used to seed the head-to-head facet and is **labelled as a fallback**, because 155 of 212 quick rounds in prod carry no course id and the facet would otherwise be thin for months. A fallback meeting is never called a "beat" without the qualifier.

### 10.3 A result inside a clash, a callout or a session

The round is the receipt for all three, and the golfer does nothing extra:

| Container | What settles it | What the golfer sees |
|---|---|---|
| A weekly clash **that seats me** | `settle_week_clash(p_season, p_week)` (A, cron) | the epilogue: *"That takes the clash. Second week running."* → the head-to-head |
| A weekly clash **that seats two other golfers** — the common case above n=2 | the same cron; `home_clash` returns null for me | **nothing in my epilogue**, and a CIRCLE item on Home the evening it settles: *"Tommy took the week off Kev."* (`HOME_STATE_MATRIX.md` F6). A verdict I was not in is somebody else's golf, never a stake and never a shortfall |
| A Ryder session | `resolve_session(p_session)` (A, cron `run_event_sessions`) | *"Week two is yours. Red lead 3–1."* |
| A callout | the same session machinery, at a field of two (**R19**) | *"You called it. You posted 84 — 2.0 under your number. Galen has to beat that off his."* |
| A month's counting cap | `close_month()` (cron) | *"That is two of your best three in September."* — **counted from `v_rounds_ranked` rows with `month_rank <= counting_cap` against `settings.counting_cap`** (`BoardRepository.swift:167`), never from `pulse.credits`, which measures the participation floor and knows nothing about the cap (`20260722211500:45-85`) |

**Nothing here asks the golfer to declare a result.** Every verdict is a count over rounds that already exist, which is **L-44** and the reason the product can be trusted with a rivalry.

---

## 11 · Post-round — the epilogue and the funnel

**Goal.** The casual → competition → recurring funnel fires at the one moment a golfer is provably engaged: three seconds after a good round. It is **a sentence, not a card wall** (**P-3**).

**Current files.** `Post/FinishCeremonyView.swift` (kept, **L-31**) · `Post/EpilogueSheet.swift` (81 lines; `onDone` closes the whole cover with **no next act** — PP-02) · Kit `Post/PostEpilogue.swift`.

### 11.1 The order

1. **The ceremony** — POSTED ✓, the number, the band phrase. Kept whole; its one broken assertion fixed (PP-03, §4.6).
2. **The epilogue, as a page with one ranked next act.** Today it is a sheet of achievement rows, a share button and a link button, and then nothing.

### 11.2 The one ranked next act

| If | The sentence | The door | Read |
|---|---|---|---|
| the round settled an open clash | "That takes the clash. Second week running." | See the head-to-head → | `settle_week_clash` (A) + **R4** |
| it moved my rank | "That moved you past Jade into second." | See the table → | **R7** `round_epilogue` + `rank_before/after/passed[]` |
| a callout was open on this round | "You called it. You posted 84 — 2.0 under your number. Galen has to beat that off his." | See the callout → | `event_session_targets` (A), which returns PvI only — a gross target for the other golfer is not computable (§9.3) |
| I played with someone and we share no season | "Galen was out there too. Four rounds between you this month — four is a season." | **Start a season with Galen →** | `recent_partners` (A) / **C-2** / the live seats |
| I played with someone and we do share one | "You and Galen have played eleven together. He leads six." | See the record → | **R4** |
| I am leagueless with buddies | "Three of yours played this week. Nobody is playing for anything." | Start something → | `home_feed` (A) + `my_friends` (A) |
| I am leagueless with no buddies | "That is your third. Your number goes live now." | Find golfers → | `rounds_count` (A) |
| nothing above | "That is two of your best three in September." | Done | `v_rounds_ranked` `month_rank` vs `settings.counting_cap` — **not `league_pulse.credits`**, which is the monthly minimum's figure, not the cap's |

**Eight rows, eight distinct sentences, one door each.** *"Make the next one count"* appears in **exactly one row** — the fourth — so it means one thing. That is the check (**P-3**).

**Taps to the next act: 1. Target: the page is on screen 2 s after the post.** It is not a second network round trip: `round_epilogue` rides back inside **R11**'s response.

**The share artifacts survive** — the recap card and the round link (`EpilogueSheet.swift:33-41`, `create_share` A) — as the *second* row on the page, below the ranked act. They are the marketing (`spec/photos-arc.md`), and demoting them below the act is the only change.

### 11.3 What the other party sees

The wire item, the push (`round`, fanned **by person**), and — where the round settles something — a VERDICT item on their Home the same evening: *"Galen posted 79. That is the number, and you have three days."*

### 11.4 Failure and empty branches

| Branch | What happens |
|---|---|
| `round_epilogue` returns nothing | The ceremony still fires and the page shows the eighth row's fallback with **Done**. A missing epilogue never blocks a post (`PostService.epilogue` already returns nil on skew, `PostService.swift:106-109`). |
| Offline at the finish | The ceremony fires from the local card; the epilogue says *"Held. The rest lands when you're back."* |
| The round earned no points (no rating) | The eighth row reads *"No rating on this one, so it builds your number and nothing else."* **V-3**: a points figure is never computed from a rating nobody measured. |

---

## 12 · Social interaction

Five acts. Four of them are one tap; the fifth is the one the product cannot do at all today.

### 12.1 Add a buddy

**Entry points.** Golfers → **Find golfers** · a person's page · the crew step in onboarding · a claim landing · **You play with (not buddies yet)** on the Golfers tab.

> `Find golfers by name or @handle`
> ( Ravi Menon · @ravi · four rounds together )  **Add**

- **Taps: 2 · target 12 s.** Write: `friend_request(p_profile)` (A), which already writes the `request` push (`20260827210000:119-121`) and already handles mutual intent — if Ravi had asked first, we are buddies instantly and nobody is rung twice.
- **What Ravi sees:** the push *"Jerecho wants in your crew · Tap to accept"* (kept verbatim — it is the built copy and it passes) with **Accept / Decline** from the lock screen (D104's routed actions), and a REQUESTS row at the head of his Golfers tab.
- **L-37 is unchanged:** exact @handle or an existing relation. `search_golfers` (A) does not browse strangers.
- **After the accept, the notification lands on the person's card**, not on Requests, where the accepted request no longer is (D248's fourth correction).

**Empty branch:** no match → *"No one by that name yet. Text them a link — it works for anyone, account or not."* → §12.5.

### 12.2 React to a round

Six emoji, the crew vocabulary (D25, **L-42**): heater · the eagle · dialed · ice · snake · sandbagger.

- **Taps: 1.** Write: today a **direct insert** into `post_kudos` (`BoardRepository.swift:213,216` / `HomeSocial.swift:104,107`) — RLS-guarded, no scoring consequence, and acceptable under the model, but the FK is the problem, not the write.
- **The defect:** `post_kudos` keys to `league_members`, so **a round with no league cannot be reacted to at all**. **C-1 (D238)** re-keys it to `profiles` (new PK `(post_id, profile_id)`, backfilled from `league_members.profile_id` — **5 rows in prod**) and gives a leagueless round a post row to hang from. This is the second of A-2's four rails.
- **No counts anywhere** beyond the round's own row: no reaction leaderboard, no "most-liked round", no attention metric (**L-22**).

### 12.3 Comment

- **Taps: 2 (+ typing) · target 20 s.** Write: `add_round_comment(p_round, p_body)` (A) for a round; the chat `posts` insert (`BoardRepository.swift:205,222`) for a board line.
- **L-42:** comments exist in service of the round's story. The poster hears the headline first; a comment never becomes a second headline.
- **L-38:** report, block, hide, and mute the tagger. It is **a named pattern, not an assertion** — **P-17** (`COMPONENT_SYSTEM.md` §4) — and it is mounted on every surface where content is: the board, a round's comments, a weekend's board, **the person page**, **the head-to-head page**, **every wire row**, **every moment page** and **the callout**. Several of those did not exist when "unchanged" was true, and this design promotes `TourCardSheet` (which carries mute at `:134-137` and the two-step report at `:151-169`) into a page — exactly the move that drops them if nobody checks. The App Store Guideline 1.2 walk is an acceptance test (`INFORMATION_ARCHITECTURE.md` §18.1, test 4).

### 12.4 Name a rivalry

The most under-used built thing in the product: `set_rivalry_name(p_opponent, p_name)` (A, `contract.psv:275`) exists, `my_rivalries.rivalry_name` (A) is **returned and discarded by the phone**, and no surface offers the verb.

**Entry point.** The head-to-head page (§10.4 of the IA), one row:

> **Name it →**   *("The Grudge")*

- **Taps: 2 (+ a short name) · target 15 s.**
- **What the other party sees:** the name, on their head-to-head page and on every clash and callout between the two of us. **No push** — a nickname is not an event. Either party may change it; the last write wins and the page says who named it.
- Read: **R4 `head_to_head(p_opponent)`** (B), which replaces the **three** implementations of the same record today (`my_rivalries`, `rivalry_weeks`, `tour_card.vs_you`), none of which can count two buddies who share no season, because `my_rivalries`'s `shared` CTE joins `league_members × seasons` (`20260716210000:76-83`).

### 12.5 Invite a person who is not here

**The rail that does not exist.** The only account-to-account link in the product is a **league's** (`PeopleScreen.swift:105-129` renders the invite row only if a league has a code), and the code comment says it plainly: *"A buddy-invite link is a different mechanic and would need a decision, not a tidy."* This is that decision.

> **Jerecho wants you in his golf.**
> He has posted nine rounds since July. His best is a 78 at Kokopelli.
> Cup Season keeps score for a group of friends — every round, against everyone's own number.
> **Get the app**

- **Taps: 2 · target 10 s.** Write: `create_share(p_kind:'person', p_ref: me)` (A) — **C-4 (D241)** widens the `shares.kind` CHECK, today `check (kind in ('round','settlement','recap'))` (`20260722190000_public_shares.sql:25`), and branches the existing anon `share_info`. **The signed-out surface stays at twelve endpoints** (**L-36/L-45**): fail-closed, unguessable token, SECURITY DEFINER, no anon table grant, and a made-up token logs nothing and returns the same shape.
- **On sign-in it mints a buddy request, not a friendship** — consent stays two-sided (D80) — so the newcomer's very first Home has a person in it.
- **Contacts matching is built** (**R-G**, **C-11**, drafted as **D251**): `profiles.contact_hash` — salted SHA-256 of normalised emails and phone numbers, salt server-side, never a raw contact and never a reversible digest — plus `match_contacts(p_hashes)` copying `nearby_resolve`'s consent envelope (`20260830250000:84-120`). It carries an **App Store privacy-label change** at the next submission, which is the owner's to file. It is asked at **§7.1's step 1** and at the crew step, declinable without blocking either, and **gracefully empty**: *"None of your contacts is here yet. Text one a link."* The person link ships beside it, because it is the only door that reaches somebody who is not on the app at all.

**Aha line for the recipient:** **"Jerecho has been keeping score since July, and he wants you in it."**

---

## 13 · Paying the pot

**Goal.** A golfer who owes $50 can always find out, in one tap, **who to pay and how** — without ever being chased, shamed or counted down at. Money is the fastest way to lose a friend group, so this flow is the most constrained in the document.

**The four rules it is written to** (**L-10**, **L-11**, **L-09**, D129): $0 is the default and a $0 season shows **no pot surface anywhere** · the pot is two numbers, never blended · the unpaid state is **self-only** · the ledger line is one constant, printed verbatim.

**Current files.** `League/PotPane.swift` (the two numbers, correctly separate at `:33-38`) · `Home/HomeView.swift:995-1008` (`owe` + `OweAction`) · Kit `MoneyCopy.swift:28`.

### 13.1 The member — finding out, and finding out how

**Where it lives: the ME strip's fourth slot, on every Home open.**

```
 12.4  ·  78 SAT  ·  SAT 7:10  ·  $50 YOU
 YOUR NUMBER  LAST   NEXT       STILL OWE
```

- It **fires from state**, not from a once-per-condition card. This is D129 **relocated, not demoted**: today the owe line is a hero clause that a closing clash can preempt, so the golfer who owes money can go a week without seeing it.
- It renders in `neg`, **never gold** — gold means *earned*, and money owed is not earned (**L-25**). **Never a countdown, never a badge, never a red dot** (**L-10**).
- **At $0 the slot is absent entirely** — not zeroed, not greyed (D70).
- Read: `native_home.buy_in.paid == false` (A) via **R1**.
- **Tap → the pot.**

**The pot section on the season page:**

> **THE POT**
> **$300** on the books · **$150** collected
> **You still owe $50.**
> **Galen collects · Venmo @galen**
> Cup Season keeps the ledger; the money moves between friends.
>
> *Champion 60% · Runner-up 25% · Points King 15%*

- **Two numbers, never blended** (D106) — the pot is stake × roster; collected is cash. `PotPane.swift:33-38` already gets this right and the wording is kept.
- **"Galen collects · Venmo @galen"** is the fact two persona walks needed and could not get. It comes from `league_settings`, written at publish by **R18** (spine amendment **A-2**) and editable afterwards by `set_buy_in_terms` (A) — which today has **zero call sites on the phone**.
- **L-09**: the ledger line prints from `MoneyCopy.ledger`. The voice audit of 2026-09-01 found it written twenty-two ways across two clients; the constant exists precisely so that cannot recur.

**Taps to "how do I pay": 2 (ME strip → the pot). Target: 8 s.**

**The payment itself happens outside the app**, and that is the design (D39/D184). Cup Season keeps the book; it does not move money and shows no purchase UI anywhere (**L-39**).

### 13.2 The Pro — marking it

> **BUY-INS · 4/6 in**
> ✓ Galen (you)     ✓ Jade
> ✓ Marcus          ✓ Dev
> ○ Tash            ○ Ravi
>
> *Tap a name when their money lands.*

- **Taps: 1 per person.** Write: `mark_buy_in(p_season, p_member, p_paid)` (A). It is reversible: tapping again unmarks.
- **What Tash sees:** her ME strip's owe slot **disappears** the next time Home loads. **No push, ever** — being marked paid is not one of D23's eight emotions, and a push about somebody else's money is the shape L-10 exists to prevent.
- **What the Pro sees on Home:** one Tier-6 item, **at most once a week** — *"Four of six have paid."* Never a chase list, never a per-member reminder.

### 13.3 The ceremony pays from **collected**

At the end, `SeasonCeremonyView` (kept whole, **L-31**) shows the champion, the margin, the tiebreak rung, the runner-up, the points king, **"You're owed"** and the pay rows. It pays from **collected**, never from the pot — a settlement card must be true on the day it is shared.

`season_payouts` (A) holds **0 rows for everyone in prod**, so when it is empty the pot clause is **omitted, never guessed**, and the record's THE BOOKS section renders only what is true (**L-44**: no $0 "earnings" figure dressed as a stat).

### 13.4 Failure and empty branches

| Branch | What happens |
|---|---|
| **$0 season** | No owe slot, no pot section, no payout trio, no ledger line. The forfeit ledger, which is pride and not money, moves to the season page under **Bets for pride**. This is the whole flow's absence, and it is the common case. |
| No payment note (a season published before **R18**) | The pot section says *"Ask Galen where to send it."* with **Ask Galen →**, which sends one nudge, **once per member per season** (L-20). **It ships with the Pro's item or it does not ship:** the Pro's Home carries a band-6 item, *"Two golfers are asking where to send the $50."* → **Add how they pay you →** (`set_buy_in_terms`, A), **counted and never itemised** — naming who asked would turn a request into a chase (L-22). `INFORMATION_ARCHITECTURE.md` §7.5 carries the table. Never a blank where instructions should be. |
| The Pro never marks anyone | Collected stays at $0, the owe slot stays, and **nothing escalates**. There is no due date, no reminder cadence and no "overdue" state, by law. |
| A member leaves the season (**C-9**, D244) | *"Your rounds stay where they are. Your name stays on the season you played. You stop scoring from today."* Money already collected is not refunded by the app, because the app never held it; the pot line says so. |
| The season is cancelled by vote | The Tier-1 item names the pot's fate **before** the vote: *"Your $50 comes back. Your rounds stay where they are — all of them."* At $0 the Pro ends it alone (D71) and the sentence is a verdict, not a vote. |

### 13.5 The aha line

There isn't one, and there should not be. The best outcome this flow can produce is that nobody ever thinks about it.

---

## 14 · The failure and empty branches, in one table

Every flow above carries its own; this is the cross-cutting set, because **an empty state is an opportunity, a failed read is not an empty state, and neither is ever a dead end** (**§6 of `UX_PRINCIPLES.md`**).

| Condition | Where it bites | The rule |
|---|---|---|
| **A read fails with content on screen** | every list | Keep what is on screen (**L-44**). `HomeView.swift:283-288` already does this correctly for the feed and is the model. |
| **A read fails with nothing on screen** | Home, the season page, Golfers | *"Cup Season can't reach the desk right now. Nothing here is missing — it just hasn't arrived."* · **Try again**. **Never the empty-feed sentence**, which today doubles as the failure state. |
| **Offline with a cache** | Home | Yesterday's items, dimmed, under `AS OF FRI 6:12 PM · OFFLINE`. **No action is disabled** — a golfer may still write, and the write queues. |
| **A new RPC is absent (deploy skew)** | every B item | Every one ships with a **declared client fallback** (§17) and every new argument is defaulted (`CLAUDE.md:77-80`). The app degrades to today's behaviour; it never blanks. |
| **An empty surface** | every list | Four parts and no more: a quiet icon · one line in voice · one true fact if one exists · **one next move**. `CSEmptyState`'s optional door is the pattern defect; the door becomes required. |
| **An empty state that names my absence** | the pulse, the month, the feed | Forbidden. *"Nothing posted this month"* opens on absence; *"Two rounds gets you back in the Fellas table before it closes"* opens on the move. |
| **Loading** | everywhere | A redacted shape (`HomeView.swift:192-195` is the model), never a spinner inside content. |
| **A destructive act** | leave the season, end the season, discard | Two-tap **"Sure?"**, never `alert()` (`WizardCancelButton`, `WizardScreen.swift:174-190`, is the built pattern and is reused). |
| **A server refusal written for humans** | joining, adding, locking | Passed through **verbatim**. `_join_gate`'s four sentences are better than anything a client would write. |

---

## 15 · The law ledger — where the four named laws live

| Law | Kept at |
|---|---|
| **L-12** — membership opens at lock; **every** join passes the covenant | **§5.1** (the one covenant screen, shared by all three paths, rendering at $0) · **§5.3** (by code) · **§5.4** (the in-app invite, which skips it today — `InvitesBanner.swift:71,84-90`) · **§9.2** (the pair season seats through `invite_golfer`, spine amendment **A-1**) · **§5.5** and **§7** (a member never sees the Pro's tool; "Run a season" always mints a new one) · **§7.3** (rules freeze at the first tee, so a pot cannot be added to a running season) |
| **L-11** — $0 is the default and selected | **§6.1** (money is the sheet's footer modifier, not a peer) · **§7.3** (**Bragging rights ✓** is pre-selected; **Other** makes $20 possible) · **§8.3** (a Major's buy-in defaults to `0`) · **§13.4** (a $0 season shows no pot surface anywhere) |
| **L-09** — the ledger line verbatim from `MoneyCopy.ledger` | **§5.1** (the covenant, above $0 only) · **§7.3** (the wizard's stake step) · **§13.1** (the pot section) · **§13.3** (the ceremony). One constant, `MoneyCopy.swift:28`, printed — never retyped, in any of the four |
| **L-40** — the free door | **§4.1** (live leads the ⊕ in ember, held immutable) · **§10.1** (any signed-in golfer starts a live game with anyone; a guest needs no account; side games never touch season points, **said on the game card**) · **§10.1** (the guest's claim link, its sentence kept verbatim) · **§6.4** (a live game's stake is the game's, not the season's) |

---

## 16 · The aha lines, in one place

Nine flows carry one. They are listed together so the set can be read for repetition — the failure mode P-3 names.

| Flow | The line | Reachable by |
|---|---|---|
| Onboarding, cold, with buddies | "Galen and Jade saw that." | first post |
| Onboarding, cold, alone | "Your number is live: 12.4." | round three |
| Onboarding, invited | "You're playing Saturday at Papago with five people, and there's a table." | first Home |
| First round | "Eighty-four at Papago. Your number starts building — two more and it goes live." | the ceremony |
| A weekend | "Four of you, Saturday, and skins on it." | the plan's page |
| The callout | "You called it. You posted 84 — 2.0 under your number. Galen has to beat that off his." | the epilogue |
| The pair season | "It's the two of you — every week is the clash." | the season page (D207, kept verbatim) |
| Post-round funnel | "Galen was out there too. Four rounds between you this month — four is a season." | the epilogue, **one row only** |
| Invite a person | "Jerecho has been keeping score since July, and he wants you in it." | the recipient's landing |

**The brief's own target sentence** — *"You're playing Jake Saturday. Jake has beaten you 3 of the last 5. Want to put something on it?"* — is assembled from `my_schedule` (A), **R4** and §9.3's callout, and is reachable for a golfer who arrives invited or with buddies. For a cold golfer with no buddies it is not, and §2.5 says so rather than pretending.

---

## 17 · The reads and writes these flows need

### 17.1 Class A — already shipping, used above

`native_home` · `home_feed` · `home_clash` · `my_schedule` · `my_friends` · `my_invites` · `my_rivalries` · `rivalry_weeks` · `recent_partners` · `last_round_with` · `tour_card` · `career_record` · `my_trophies` · `league_pulse` · `league_cancel_status` · `round_epilogue` · `round_card` · `search_golfers` · `create_league` · `lock_league` · `join_league` · `join_covenant_info` · `league_by_code` · `invite_golfer` · `respond_invite` · `add_friend_to_league` *(restricted to $0, see A-1)* · `declare_round` · `set_round_rsvp` · `add_round_comment` · `start_live_round` · `finish_live_round` · `live_state` · `guest_live_state` · `create_forfeit` · `settle_forfeit` · `create_event` · `create_major` · `add_event_player` · `set_event_team` · `resolve_session` · `event_session_targets` · `event_lineage` · `major_leaderboard` · `event_post` · `mark_buy_in` · `set_buy_in_terms` · `announce` · `close_roster` · `set_member_bye` · `set_league_finish` · `request_league_cancel` · `vote_league_cancel` · `randomize_squads` · `form_squads` · `set_profile` · `set_handle` · `set_rivalry_name` · `friend_request` · `friend_respond` · `create_share` · `share_info` · `create_scan_claim` · `claim_round_info` · `claim_round` · `settle_week_clash` · `my_actionable_count` · `season_scenarios` · `cup_final_race` · `season_payouts` · `delete_round` · `delete_league` · `transfer_pro`.

**Six of these are already on the payload and rendered by nothing**, and cost nothing to use: `native_home.events`, `native_home.open_duels` (`Models.swift:233-234`), `tour_card.courses`/`shared_courses` (`TourCard.swift:93-126`), **`join_covenant_info.structure`, `has_pay_note` and `buy_in_due_on`** (all dropped by `Covenant.init`, `JoinLeague.swift:67-74`; the last two are what §5.1's money line and §13.4's "Ask Galen" branch need), `seasons.champion_member_id` (`Models.swift:50`, unread at `HomeView.swift:869,980`), `my_rivalries.rivalry_name`. **`phase` is not among them** — `join_covenant_info` does not return it (`20260830040000:76-85`); **R9** adds it.

**One is granted, generated and called by nothing on the phone:** `set_buy_in_terms` (`contract.psv:258`; web at `index.html:6310`).

### 17.2 Class B — a new RPC over existing tables

Every one carries `grant execute … to authenticated` and `revoke … from public, anon` (**L-04**), every new argument is defaulted, and every load-bearing read ships with a declared client fallback (`CLAUDE.md:77-80`).

| # | Name | Used by | Fallback if absent | Status |
|---|---|---|---|---|
| **R1** | `home_dispatch(p_days default 21)` | every flow's landing | **`HomeFallbackItems`**, a named client producer built in Wave 1b — items from `native_home` + `home_feed` + `my_invites` + `home_clash`, sorted CLOSING → CHANGED → COMING → CIRCLE, no lead card. **Not "as today"**: `INFORMATION_ARCHITECTURE.md` §17.1 deletes `HomeMode`, `HomeLead` and `HomeHeroCopy` | spine, **corrected** |
| **R2** | `home_stories(p_days default 21, p_league default null)` | the wire; a leagueless buddy's milestone | `home_feed` as today | spine |
| **R3** | `native_home` v3 keys (`season.week_no`, `standing.next_up/next_down`, `profile.last_round_on/last_gross`, `membership.pro_name`, the inlined clash) | the ME strip; §5.1's covenant head; §7's season page | keys absent → today's render | spine |
| **R4** | `head_to_head(p_opponent)` | §9.1, §11.2, §12.4, the person page | `my_rivalries` as today (season-only) | spine |
| **R5** | `friends_board()` | Golfers → the board | the section does not render | spine |
| **R6** | `season_story(p_season)` | the season page's story line | the page renders without it | spine |
| **R7** | `round_epilogue` + `rank_before/after/of/passed[]` | §11.2 rows 2 | the epilogue's existing rows | spine |
| **R8** | `my_streaks()` | the ME strip; a leagueless CHAPTER | the line does not render | spine |
| **R9** | `join_covenant_info` **+ roster**, signed-in callers only, anon signature unchanged, fail-closed | §5.1's WHO row | the covenant renders the count, as today | spine |
| **R10** | `run_it_back(p_league)` | §7.7 | mints a new league as today | spine |
| **R11** | `post_round(p_gross, p_rating, p_slope, p_holes_played, p_nine_rating, p_course_id, p_course_label, p_played_on, p_photo_path, p_played_with)` → `{round, epilogue}` — **the real eleven-column payload** (`PostCard.swift:280-307`); `season_id` is **derived server-side** from `played_on` against every membership's window at that membership's allowance (D123/L-13), which is what replaces `preferredLeague` under D229 | §4, §10.2 | **`PostService.insert` is kept and fires on a function-missing error** (PGRST202): the `rounds` insert → `score_round` → `round_to_board` path as today, with the epilogue fetched via `round_epilogue(p_round)`. "n/a" was the only cell in this table with no answer, and CLAUDE.md's skew rule does not cover a function that does not exist yet | spine, **corrected** |
| **R15** | `confirm_round_partner(p_round, p_confirm)` | §4.4, §10.2 | rides **C-2** | spine |
| **R16** | `ask_for_a_seat(p_scheduled_round)` | §8.1 | the row does not render | spine |
| **R18** | **`lock_league` + `p_pay_note text default null`** | §7.3, §7.5, §13.1 | the note is absent and §13.4's "Ask Galen" branch renders | **NEW HERE** — D225 must gain the clause (spine amendment **A-2**) |
| **R19** | **`call_out(p_opponent, p_closes_on, p_forfeit_terms default null)` → `uuid`** | §9.3 | the door does not render | **NEW HERE** — D237 must gain the clause (spine amendment **A-3**) |
| **R20** | **`respond_callout(p_event, p_accept)`** | §9.3 | the Tier-1 item renders with **See it** only | **NEW HERE** — same entry as R19 |
| **R21** | **`tour_card` + `case[]` and `career.best_round`** | §11.2's record clause, the person page | both rows do not render | **NEW HERE** — `trophies` RLS is self-only (`20260713200000:31-34`) and `career.best` is `min(differential)` with no gross, course or date (`20260902180000:119`) |
| **R22** | **`my_schedule` + `name`, `game`, `rsvp[]`** | §8.1's page, §3.1's plan item, Home's UPCOMING | the row renders as today: course, date, count | **NEW HERE** — `sched_own` is `profile_id = auth.uid()` (`20260712150000:33`), so **C-3's two columns reach no non-host client without it**. A return-type change |
| **R23** | **`set_profile` + `p_index_source text default null`** | §2.1's band | the source is `'self'` as today, and the starter cannot be distinguished from a typed index | **NEW HERE** — rides **C-13**; `set_profile` hard-codes `'self'` (`20260716120000:68`) |

`R12` (`career_record` split), `R13` (`band_name`), `R14` (D123's server lens) and `R17` (`my_side_games`) are used by the record and the person page rather than by these twelve flows, and are carried unchanged from the spine.

### 17.3 Class C — a new table, column or mechanic

| # | Change | Used by | Entry |
|---|---|---|---|
| **C-1** | `posts.profile_id` — a round can be homed on a person; `post_kudos` re-keys to `profiles`; `round_to_board` and `finish_live_round` write a person-homed post when no season owns the round; the webhook gains a friendship branch | §4.4, §10.1, §12.2 — the four leagueless rails | D238 |
| **C-2** | `round_players(round_id, profile_id, confirmed_at)` + `confirm_round_partner` — **not** a `played_with` column (**L-02**: a `rounds` row is never updated; a claim needs a state) | §4.2, §4.4, §10.2, §12.4 | D239 |
| **C-3** | `scheduled_rounds` gains **`name`** and **`game`**; `declare_round` gains `p_name`, `p_game`, defaulted | §8.1 | D240, **amended**: the third column `stake_cents` is dropped (spine amendment **A-4**) |
| **C-4** | `shares.kind` CHECK gains `'person'`; `share_info` branches; one line in `db-checks.sql`; the AASA path. **The anon surface stays at twelve endpoints** | §2.1 frame 3, §12.5 | D241 |
| **C-5** | `forfeits.league_id` nullable; `event_id` and `scheduled_round_id` added; CHECK exactly one home; `create_forfeit`'s "crew only" becomes "a shared season, a shared moment, a shared plan, or accepted buddies". **0 rows in prod.** The **no money column** rule (`20260724120000:10-13`) is restated and kept | §6.4, §8.1, §9.1, §9.3 | D242 |
| **C-6** | `push_nudges.kind` CHECK extended for ten kinds; the producers in `push/index.ts` | §3.4, §4.4, §7.7, §9.3, §10.1 | D248 |
| **C-9** | `leave_season(p_league)` — forward-only | §13.4 | D244 |
| **C-11** | `profiles.contact_hash` (salted SHA-256, salt server-side, `grant select (contact_hash)` in the same file) + `match_contacts(p_hashes)` on `nearby_resolve`'s envelope — **built** (**R-G**), carrying an App Store privacy-label change | §7.1 step 1, §12.5 | **D251** |
| **C-12** | `shares.kind` CHECK gains **`'plan'`** — the same CHECK C-4 widens — plus one `share_info` branch, one `db-checks.sql` line, one AASA path, the web landing. On sign-in it RSVPs the golfer onto the plan and mints a buddy request to the host. **The anon surface stays at twelve endpoints** | §8.1, §2.1 frame 4 | **D253** |
| **C-13** | `index_source = 'starter'` — the two sibling CHECK audits (`initial_baseline.sql:1065, :1267`) and the widening of `round_refresh_index`'s gate and the announce branch from `= 'app'` to `in ('app','starter')`, **so the promised replacement at three rounds actually happens**. Rides **R23**. **Supersedes D124's option (i); an owner question** | §2.1 frame 2 | **D247**, with its CONFLICT line |

### 17.4 What these flows deliberately do **not** add

A `challenges` table · a `callouts` table (R19 is the door; the table is D237's named two-week fallback if the reviewer-seed walk fails) · an `outings` table · a `crews` table · `profiles.play_style` · `rounds.played_with` · a thirteenth anon endpoint · `scheduled_rounds.stake_cents` · an `event_buy_ins` table · a capacity column on `scheduled_rounds`. All ten are declined in writing in D250, and the last three are added to it here.

**And one promise this document previously made and no longer does:** *"the link survives a cold install"* (§3.2). iOS has no deferred deep linking; the link survives **the boot**, and the cold case is answered by the door's "I have a code" and by re-tapping the link once installed. A first-launch clipboard read is the only mechanism that would do more, and it would be its own entry with its own privacy note.

---

## 18 · The walk list — where these flows behave differently, said both ways

Every row is designed from the code, not from a persona, because no persona sat in any of them. This table is the **literal pre-ship walk**.

| Seat | What differs in these flows |
|---|---|
| **A member of a squads season** | §4's post shows the squad's colour on the receipt spine (**L-26**, identity not decoration). §7's creation is not theirs to run. §13's owe slot is identical. The one real difference is the monthly minimum: it says **who it costs** — *"You are two rounds short. The Mudsharks carry the penalty, not you."* (D14's anti-ghosting rule, stated in words for the first time). |
| **A member of a solo season** | The minimum **never assesses** (D140, **L-18**): the equivalent line is a habit with no penalty — *"Two rounds in September. Your best three count."* At two golfers the clash **is** the pair and §9.2's sentences apply. |
| **A member of a season of more than two** | **The clash is not mine most weeks**, and every flow above must be read with that in hand. `open_week_clash` seats one pair per season-week (`20260831160000:60-115`) and `home_clash` returns null unless I am one of the two (`:507-513`) — at a roster of eight that is roughly one week in four. §10.3's clash row, §11.2's first rung and §16's pair line are the **spotlighted-week** cases; the other weeks are `HOME_STATE_MATRIX.md`'s **F6**, where the pair is somebody else's golf and never a stake I cannot enter. Both real seasons in prod are n=2, which is why this needed saying. |
| **A squads captain** | One line on the squad's row naming who is short this month, with a door to the members sheet (`MembersSheet.swift:56-92`). **No captain tools beyond that.** A captain is a player with a name on a squad. |
| **The Pro during a season** | §7.8's verb row at the foot of the season page — seven verbs, seven RPCs, never a mode. §13.2 is theirs. Everything else in this document is identical to a member's, which is **V-1** and is checked by opening both Homes on the same seeded season. |
| **The Pro before the first tee** | §7.8's sentence-not-checklist head, with **Share the invite link** as the one action. |
| **Draft night, both seats** | §7.8: two screens, not one screen with a swapped verb (CH-13). The member's screen offers no verb they cannot press. |
| **A golfer in a moment with no season** | §8.2 and §9.3 both reach the event page from **Compete** and from a `?event=` link. Today `EventChips` mounts only inside the league room (`ClubhouseView.swift:87`) and no `?event=` link is claimed, so this seat is a dead end. |
| **A guest on a tee sheet** | §10.1. No account, no gate, the claim link, and now the buddy request on its landing. Untouched otherwise (**L-40**). |
| **The season ceremony night** | §13.3. The takeover fires **from Home**, once per member, and **ends somewhere** — the run-back for the Pro (§7.7), the nudge for a member. |
| **The cancel vote** | §13.4's last row. A Tier-1 item for every member, naming the pot's fate before the vote, with its own push kind (`season_cancel`, D248). Today Home is silent while a season is being ended — `league_cancel_status` is read only by the room (`contract.psv:170`). |
| **App Review's own walk** | The reviewer seed holds four seasons, is a squads captain, and its Sunset Match season ended **2026-09-05** — so from today the reviewer lands on a finished season. §7.7 and §13.3 make that landing a champion and a next move rather than a tombstone. **§9.3's callout is walked on "The Grudge" through a live and a completed session before it is committed** — this is the gate, not a nice-to-have. |
| **Two or more seasons** | §13.1's owe slot reads the season with the nearest deadline and taps to *that* pot; a second season's money is its own dispatch item. **No switcher.** The multi-league walk on the App Review seed is Wave 1's release gate. |
| **Light theme** | Every quoted surface is specified in tokens. The named risk is **ember-on-paper contrast for the one action** in §4.1, §7.4 and §11.2 — the three screens whose entire hierarchy is one ember verb. It is the first thing checked in a light pass. |
| **Accessibility sizes and VoiceOver** | AX3 is an acceptance test for **the composer's one box** (§4.2) and **the ME strip's owe slot** (§13.1), which keeps its VoiceOver action (`HomeView.swift:1001-1008`). The intent sheet's five lines and the covenant's six wrap rather than truncate; the trailing action wraps **below** the text, which is the exact AX5 squeeze already recorded for `InvitesBanner`. |
| **Offline** | §14. Every flow's write queues; no flow's action is disabled by a failed read. |
| **A push arriving with the app closed** | Every landing named in this document resolves to a page that exists, which is the current failure mode for `.event` on a golfer with no season. A cold-start tap is stashed until Home exists, unchanged (`PushRouter.swift`). |
| **The desktop web** | **Built inline, in its own desktop-first shape** (**R-C**, revised 2026-09-05; `INFORMATION_ARCHITECTURE.md` §16). Every wave has a web half and is not done without it — so the intent sheet, the one-box composer, the person page and the covenant's new facts all land on the web too, in a **sidebar and a wide two-column body** rather than as a phone reflowed. The web keeps and owns the signed-out door (§3, screen 0 — and gains the App Store link), the anon surface (§5.2, §10.1's claim, §12.5's person link, §8.1's plan link) and the founder's desk (§13.2 is genuinely better on a big screen). Its six false facts are fixed first, `index.html:17705`'s $0 fail-open among them. **Verification for a web half is CLAUDE.md's recipe and is not optional:** serve locally, clear the service worker and caches first, drive the flow, and the console must be clean but for the one known boot rejection. |

### 18.1 The three acceptance tests these flows must pass

1. **The cold-account walk** — install → door → card → composer → posted, counting taps and seconds against `post_submit` (n=24, p50 39 s, p90 76 s). §4.3's first row must halve it.
2. **The covenant walk on all four join paths** — link, code, in-app invite, **and $0** — on both clients. Preflight 19 is extended to the in-app path.
3. **The abandoned-creation query** — `select count(*) from leagues where status='setup'` is unchanged after an abandoned intent sheet and an abandoned wizard. Prod holds **six founder-alone `setup` leagues** today because the wizard mints on a name.

Plus: one production APNs token receiving one real push before anything in §3.4, §4.4, §7.7, §9.3 or §10.1 that depends on a notification is built.

---

## 19 · What only the owner can decide, in these flows

**Three of the six are answered and are struck.** **R-F** settles the "beat one guy" order — the length is asked and **all three are always offered** (§9.1), so item 1 is a design, not a question. **R-B** settles the ⊕: the immutable clause stands, live leads in ember, and "Add my round" is one tap by three routes that exist (§4.1); D227 records the reconciliation, not an override. **R-E** opens the Major (§8.3), with the occasion cards shipping in the same wave as the flag and never before it.

**Four remain, and one is new.**

1. **Does the starter index write to `profiles.index_current`?** (§2.1 frame 2.) `score_round` reaches `profiles.index_current` before its own-differential fallback, so a band-derived figure **scores** the first three rounds — which is **D124's option (ii)**, an option that owner ruling considered and declined in favour of option (i). D247 carries the CONFLICT line; only the owner may overturn an owner ruling. *If declined:* the starter is client-side only, labels the ME strip, never reaches the engine, and **C-13**/**R23** come out of the plan.
2. **Whether `add_friend_to_league` survives at all** (spine amendment **A-1**). This document restricts it to a $0 roster add by the Pro. The stricter reading — every seat but your own is an invite — is one line simpler and costs the Pro nothing; it is named here rather than taken.
3. **`assign` and `snake` on draft night** (§7.8). Delete both unreachable branches, or promote one deliberately in the wizard. Carrying two unreachable UIs through a redesign is how the next audit finds them.
4. **Whether a weekend may ever carry money directly** (spine amendment **A-4**). This document routes it to a forfeit or to the live round's own stake. If the owner wants `scheduled_rounds.stake_cents`, it needs a ledger, a collected figure and the L-09 line on a surface that has none of those — which is a bigger change than a column, and §17.4 declines it in writing.

---

## 20 · Known gaps

| # | The gap | Why it is recorded rather than resolved | What reopens it |
|---|---|---|---|
| **1** | **The cold-install link is a door, not a mechanism** (§3.2). A golfer who taps a link, installs from the App Store and opens the app arrives with nothing carried over, because iOS passes nothing after an install. | The platform does not offer deferred deep linking. Promising it would cost a week and deliver nothing. | A first-launch clipboard read, which is its own entry with its own privacy note. |
| **2** | **Nine of the twelve flows depend on a push channel that has never delivered a real notification.** `device_tokens` holds one `ios-sandbox` row and `push_prompt_shown` has zero accepts. | It is a gate, not a risk: **no notification work begins until one production APNs token has received one real push** (§1, D248). Every push in this document is a specification until then. | The Wave-0 gate passing. |
| **3** | **The callout's whole life is unproven.** Nobody has ever seen the Ryder room in LIVE or COMPLETE (G-08), which is exactly the state a callout lives in for its entire existence. | The engine is complete and the design rests on it; walking it is cheaper than building a `callouts` table against a hypothesis. | The reviewer seed's "The Grudge" walked through a live and a completed session. If it does not hold, D237's named fallback is the table and a two-week swing. |
| **4** | **`post_submit` is the only measured baseline in the product** (n=24, p50 39 s, p90 76 s). Every other target in this document is a target, not a measurement. | Stating targets as measurements would be the exact L-44 failure this design exists to end; §1 says so. | Wave 0's `cta_tapped` / `first_act` events, which give the second and third baselines. |

---

*Companion documents: `OWNER_RULINGS.md` (R-A…R-H, which outrank these flows and are merged into them), `INFORMATION_ARCHITECTURE.md` (the destinations, the season page, the data contract), `HOME_STATE_MATRIX.md` (what every flow lands on), `UX_PRINCIPLES.md` (the rules every screen above is judged by), `COMPONENT_SYSTEM.md` (the patterns these screens are built from), `TERMINOLOGY.md` (every word above, and the checks that hold them), `DECISIONS_TO_LOG.md` (D222–D253 and IOS-028–IOS-036 — drafted, authorised 2026-09-05, appended wave by wave; three of them, D225, D237 and D240, have gained the clauses named in §0).*
