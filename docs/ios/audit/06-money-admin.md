# Audit 06 — Money, admin, and operations

Read-only audit of the Cup Season web client (`index.html`, 17,767 lines), the
Supabase migrations (`supabase/migrations/*.sql`), the RPC snapshot
(`packages/db/contract.psv`), and the specs, for the native rebuild. All paths
are relative to `/Users/fischbeck3/cup-season`. Line numbers are against the
working tree on 2026-08-27 (branch `native/b1-scaffold`).

---

## 1. The pot: model, lifecycle, math, who sees what

### 1.1 The model in one paragraph

A league pot is **a ledger, never a balance**. The stake is one integer on the
bylaws row (`league_settings.buyin_cents`, default 7500 = $75; `$0` is
first-class "bragging rights"), the split is three integers that must sum to
100 (`payout_champ / payout_runnerup / payout_king`, CHECK `payout_sums_100`,
baseline `00000000000000_initial_baseline.sql:1073-1101`). Collection state is
one boolean per member per season (`buy_ins.paid`, baseline `:885-892`),
flipped only by the Pro through `mark_buy_in()`. Settlement is **computed** at
close (`close_season()` posts a pot line; `award_season_trophies()` writes
`season_payouts` rows in cents — D67) and **rendered** as a ceremony takeover
that resolves the split to people (D66). The app never holds, moves, collects,
or refunds a cent; the canon phrase since D39 is *"Cup Season keeps the ledger;
the money moves between friends."* `legal.html:78-84` ("Prize Pool
Disclaimer") states the present-tense facts and is deliberately untouched by
D39.

### 1.2 Lifecycle

| Stage | Where it happens | Money-relevant fact |
|---|---|---|
| Wizard: stake dial | `index.html:3250-3254` (`#stakeDown/#stakeUp`, `#stakeVal`), stepper handlers keep `state.stake` in dollars | Copy: "Per player · $0 = bragging rights". Buy-in lives INSIDE the "Customize" disclosure (`#wizDials`, `:3249`; `:7144-7157`) — a Pro using the preset fast path never sees the buy-in dial and inherits the DB default of $75 unless `state.stake` was seeded otherwise. Verify the preset default in the wizard state before native copies it. |
| Wizard: pot split | `:3288-3294` `#paySeg` — three presets only: `60,25,15` Balanced (default) · `70,20,10` Winner-heavy · `50,30,20` Spread it. Handler `:7131-7143` sets `state.payout`. No custom-% editor (D8/D46). |
| Wizard: live portrait | `wizPortrait()` `:11847-11890` — pot row = `stake × wizRoster()` with a split bar; $0 renders "Bragging rights · $0 STAKE" |
| Lock (bylaws written) | module `:14888-14923` — a DIRECT `sb.from('league_settings').update({... buyin_cents: state.stake*100, payout_*: ..., locked_at: now})`. Not an RPC. Allowed by RLS `settings_write` (commissioner AND `locked_at IS NULL`, baseline `:2313`) — so the lock is also the last legal write; the bylaws are immutable after first tee by RLS, not by an RPC guard. |
| Join covenant | `covenantGate()` `:15176-15194` calls `join_covenant_info(p_code)` (anon-callable, `20260722211500_covenant_pulse_pairings.sql:29-44`) and, when `buyin_cents > 0`, blocks the join on a sheet titled "THE FINE PRINT, UP FRONT": BUY-IN / PRESET / FLOOR / FINISH rows + "Joining puts you on the pot sheet for $N. Cup Season keeps the tab; money moves between you." + "Join — I'm in for $N". Fails OPEN to plain join if the RPC is absent (skew). |
| Collection | `renderPot()` `:6973-7050`; Pro taps a name → `mark_buy_in(p_season, p_member, p_paid)`; non-Pro tap toasts "The Pro marks buy-ins as money moves between you"; pre-season toasts "Buy-ins open once the bylaws lock" (`:7012-7013`). Marking PAID posts "DANNY'S BUY-IN IS IN — 4/5 COLLECTED" to the board (`20260712130000_buyins_and_kickoff.sql:20-63`); unmarking is silent. |
| In-season display | Home stat tile `#chipPot` + `#paidChip` (`:3427`), gold "On the line" bar `#lineAmt/#lineSplit` (`:3446-3453`), Pot pane `#room-pot` (`:3497-3525`) with `#potAmt`, `#potMath`, `#pay1/2/3`, `#payers`. D70 hides the on-the-line bar and the Pot tab entirely when stake is 0 (`renderBylaws()` `:11928-11940`). |
| Endgame dial | `set_league_finish()` (`20260716170000_endgame_dial.sql:39-62`) — Pro can flip cup_final ↔ points_table until `ends_on − 27`; UI button injected into the bylaws card `:11912-11926`. |
| Close | `daily_season_tick()` → `close_season()` (`20260724230000_season_result_columns.sql:26-212`, service-role only): writes `champion_*`, `runnerup_*`, `points_king_member_id`, `champion_score`, `runnerup_score`, `tiebreak_rung`; posts the story and the pot line `"The pot: $X — champs $A · runner-up $B · points king $C · settle between yourselves"`; then `award_season_trophies()` mints trophies AND `season_payouts` rows (`20260725190000_payout_penny_fixes.sql`). |
| Ceremony | `openSeasonCeremony()` `:11509-11600`, `csSettlement()` `:11479-11508` — takeover once per member per season (`localStorage cs_cer_<season>`), re-openable from the League Room. Renders per-person rows ("Cup champion + Points king · $180"), an "Unclaimed · no eligible finisher" row when a share has nobody to go to, and "You're owed $N". |
| Career record | `career_record()` → `renderCareerRecord()` `:11103-11132` — titles first, then "$X · Settled across N seasons" = `sum(season_payouts.cents)`. |
| Season-end email | `season_email_payload()` (`20260725140000_season_email.sql:63-115`) carries each recipient's own `cents` from `season_payouts`. |
| Cancellation (D71) | `request_league_cancel` / `vote_league_cancel` / `withdraw_league_cancel` / `league_cancel_status` (`20260726100000_league_cancellation.sql`). Free league: Pro cancels alone. Money league: unanimous; any decline kills it. `cancel_league_now()` snapshots each member's own PAID buy-in into `cancellation_notices.payload` BEFORE the cascade delete, so the refund NOTICE email survives the league. Banner UI `renderCancelBanner()` `:15563-15616` shows "You get back $N — your buy-in." |
| Account deletion | `delete_account()` (`20260717205347_delete_account_loud.sql`) — a profile with ledger rows (`season_adjustments`), rounds, draft picks or shared live games is TOMBSTONED ("Former member", banned), never hard-deleted, precisely so nobody's standings or pot arithmetic shifts. |

### 1.3 The math (three copies — see landmines)

- **Pot total** = `buyin_cents × count(league_members)` — the whole roster, paid
  or not (`award_season_trophies` `payout_penny_fixes.sql:71-73`; `close_season`
  `season_result_columns.sql:196-198`; client `csSettlement` `:11483`).
- **Split**: `runner = round(pot × payout_runnerup/100)`, `king = round(pot ×
  payout_king/100)`, `champ = max(0, pot − runner − king)` — champion absorbs
  the rounding remainder (`payout_penny_fixes.sql:76-78`, client `:11485-11487`).
- **Per-seat**: a squad share is split evenly in cents with the remainder
  pennies riding the earliest seats (`csSplitCents` `:11471-11476`; server
  mirrors it via `row_number() over (order by pid)` `:104-131` of the penny
  fix). A golfer who is both champion and Points King gets ONE summed row.
- **Majors** (`20260720193000_the_major.sql:465-492`): pot = `buy_in ×
  contender entrants` (exhibition rows never buy in); split fixed 60/25/15 or
  `wta`; unfilled places roll up to the champion; a no-card buy-in "stays in
  the pot" (`:12469`). Prize is written to `event_major_cards.prize` in
  NUMERIC dollars with `round(…, 2)` — a different rounding regime from the
  season pot's integer cents.

### 1.4 Who sees what

| Surface | Member | Pro | Anon |
|---|---|---|---|
| `buy_ins` rows | read (RLS `buyins_read`, is_league_member) | read + write via `mark_buy_in` (table policy `buyins_write` also allows direct writes by the commissioner, baseline `:2006`) | none |
| `league_settings` (stake, split) | read | read; update only while `locked_at IS NULL` | `join_covenant_info` exposes `buyin_cents`, preset, floor, finish, structure by league CODE — anyone with a code learns the stake |
| `season_payouts` | SELECT if league member (`career_record.sql:29-35`) | same | none |
| Ceremony / "You're owed" | every member; the whole table is shown to the room | same | none |
| Refund on cancel | each member sees only their OWN refund (`league_cancel_status.you_refund_cents`) | sees vote tally | none |
| Career earnings | own only (`career_record()` is auth.uid()-scoped) | — | — |
| Public share page (`share_info`) | out of scope here; verify it never carries pot figures before native links to it |

---

## 2. Screens & states inventory

All classic-script unless noted. "Module" = the `type="module"` block (line
~12798 onward) where `sb` lives.

| Screen / state | Function(s) | Lines | Loading / empty / error handling |
|---|---|---|---|
| Wizard — buy-in stepper, pot split seg, `#ih-payout` help | markup; handlers `#stakeUp/Down`, `#paySeg` | `3250-3254`, `3288-3294`, `7131-7143` | none needed (local state). Help copy: "The pot lives on the books here — the app keeps the ledger, money moves friend-to-friend." |
| Wizard — live portrait / bylaws review | `wizPortrait()`, `renderBylaws()` | `11847-11947` | `$0` → "Bragging rights"; `#bylawsReview` mirrors `#bylawsHub` |
| Lock (bylaws write) | module lock handler | `14885-14925` | skew retry drops `finish` on column-absent error |
| Join covenant | `covenantGate(code)` | `15176-15194` | fails open when RPC absent; "Not now" resolves false |
| Post-join welcome (D3 covenant) | `openLeagueWelcome()` | `17045-17058` | third rule: "The pot lives on the books." |
| Home stat tile "The pot" + `#paidChip` | `renderPot()`, `renderBylaws()` | `3427`, `6973-7050` | `$0` → "None" / "Bragging rights" |
| "On the line" bar | `renderBylaws()` | `3446-3453`, `11931-11946` | hidden when stake 0 |
| League Room ▸ Pot pane | `renderPot()`, `setRoomSeg('pot')` | `3497-3525`, `4115-4136` | old `#pot` deep links remap to hub+segment; `#payers` = one `<button class="payer">` per member, `.paid` class = tick; empty roster renders a single "You" row |
| Pot pane ▸ forfeit ledger (D64, non-money stakes) | `loadStakes()` (module), `#stakesList`, `#stakeAdd` | `3518-3524`, `10933+`, `16219+` | "prose, never dollars"; settle = a party's tap or the Pro |
| Bylaws card in League Room | `renderBylaws()` | `11891-11926` | Pro-only "Finish: … switch to …" button until the final window |
| Ceremony takeover | `openSeasonCeremony(force)`, `csSettlement()` | `11465-11600` | returns false in demo / not complete / already seen; "Unclaimed" row for a share with no finisher |
| Career record (You tab) | `renderCareerRecord()`, `loadCareerRecord()` | `11103-11132`, `16398-16402` | `null` → "Your record fills in when a season closes."; RPC absence is `console.warn` only |
| Members & invites sheet (Pro tools) | `openMembersSheet()` | `16891-17036` | Pro-only buttons per row: **Set index** (any phase), **Remove** (setup only) OR **Bye** (in season), **Make Pro**. Remove/Bye/Make Pro still use native `confirm()` (`:16957`, `:16972`, `:16981`) — the S4-03 lesson (installed PWAs swallow `confirm/prompt`) was applied to Set index (`:17000-17020`) but NOT to these three. |
| Scoring help sheet | `openScoringHelp()` | `17021-17043` | "The money" paragraph = D39 line |
| Cancel banner (D71) | `renderCancelBanner()`, `refreshCancelStatus()`, `cancelVote()`, `cancelWithdraw()` | `15563-15616` | status RPC absent → no banner (skew-safe); three states: Pro (Call it off + tally), approved (waiting), undecided (Approve/Decline) |
| Delete / cancel league | `#hhDelete` handler | `15618-15683` | pre-tee: solo → plain sheet; others → typed-name gate; in-season → D71 sheet "Start the cancellation" |
| League switcher scrap button | `openLeagueSwitcher()` | `15470-15480` | `canScrap` = Pro AND phase in setup/draft |
| Delete account (You ▸ settings) | markup + `#phDelYes` | `13584-13591`, `13745-13757` | inline two-step (no native confirm); on success `signOut` + `location.replace`; error → toast with the server's blocker message |
| Membership & billing (You ▸ settings) | static | `13578-13580` | "PLAN · FREE · PILOT — Cup Season membership lands at launch." |
| Pro Shop card (League Room ▸ League) | static | `3539-3550` | "CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE"; disabled button |
| Feedback sheet | `openFeedback()` | `15347-15393` | category chips; context auto-attached (view, version, league, event, path, UA); requires sign-in |
| Founder desk card (You tab) | markup; `openFounderNote()`, `openFounderDesk()` | `2849-2860`, `15395-15457` | card `display:none` unless `CS.user.id === FOUNDER_ID` (`:12872-12877`); desk sheet: 8 stat tiles, newest 12 cards, last 30 client events (bug icon on `/error|reject/`), last 20 feedback, last 15 content reports (only when the RPC returns `reports`); error → "The desk is not deployed yet — push the founder_desk migration." |
| Report a post | classic `#report…` handler | `4832-4860` | reason sheet → `report_content(p_post, p_reason)`; emits `qaEvent('content_reported')` |
| Report a profile photo / mute | Tour Card `#tcReport`, `#tcMute` | `13405-13442` | two-tap arm ("Sure? Report this photo"), `report_content(p_kind:'profile_photo', p_profile, p_reason)`; mute → `set_mute` |
| Major create — buy-in, split | `openMajorCreate` sheet | `16033-16040`, `16105-16125` | `#mjSplitWrap` shown only when buy-in > 0; `create_major(p_buy_in, p_pot_split…)` with a skew retry that drops `p_lineage` |
| Major page — pot line + fine print | `renderMajor…` | `12389-12404`, `12504-12507` | "The fine print." paragraph includes "Pot is a ledger — 60/25/15, top three; money moves between friends." only when buy-in > 0 |
| Legal links | You ▸ settings footer | `13598` | `/legal.html#privacy`, `#terms`, `#pot` ("Prize pool") |
| Demo diorama | `state.demo` default `true` (`:3772`); flipped false at `enterGuestLive` `:7884`, `resetToBlank` `:11736`, league-less shell `:17093`; demo pot uses `state.payers` (`:7036-7049`); demo ledger `ADJ` `:11422-11426` | every real read/write is gated `!state.demo`; D83 removed all user paths INTO the demo, the plumbing stays as a write-guard |

---

## 3. RPC table (money / admin / ops slice)

`security` and grants are verbatim from `packages/db/contract.psv` (live
snapshot 2026-08-26). "Role" = who the BODY lets through.

| RPC | Args | Returns | Body gate | Grants | Migration | Client call site |
|---|---|---|---|---|---|---|
| `mark_buy_in` | `p_season uuid, p_member uuid, p_paid bool` | void | `is_commissioner(league of season)`; member must belong | auth | `20260712130000` | `:7016` |
| `set_member_index` | `p_member, p_index numeric` | void | Pro; range −10..54; sets `profiles.index_current`, `index_source='self'`; posts to board | auth | `20260716110000` | `:17012` |
| `set_member_bye` | `p_member, p_month date, p_on bool` | void | Pro; member must be in an active season squad; one bye per season (deletes prior); writes `season_adjustments kind='bye'`; posts | auth | `20260716180000:142-178` | `:16974` (always `p_on:true`, current month) |
| `remove_member` | `p_member` | void | Pro; not self; **phase = 'setup' only** ("mid-season tools are coming"); deletes squad_members + buy_ins + membership, nulls their posts' member_id; writes `commissioner_log`; posts | auth | `20260712150000:125-156` | `:16960` |
| `transfer_pro` | `p_member` | void | Pro; swaps roles; `commissioner_log`; posts | auth | `20260712150000:157-182` | `:16985` (then `location.reload()`) |
| `set_league_finish` | `p_league, p_finish text` | void | Pro; refused once `status='cup_final'` or `today ≥ ends_on−27` | auth | `20260716170000:39-62` | `:11919` |
| `announce` | `p_league, p_body` | void | Pro; 1–280 chars | auth | `20260712070000` | `:13868` |
| `delete_league` | `p_league` | void | Pro; phase setup/draft, or season not kicked off and first tee ahead; complete = never | auth | `20260712230000` | `:15656` |
| `request_league_cancel` | `p_league` | text `done|open` | Pro; not complete; free → immediate; money → open vote (Pro's request counts as approval; solo Pro executes inline) | auth | `20260726100000:88-120` | `:15632` |
| `vote_league_cancel` | `p_league, p_approve` | text `declined|pending|done` | league member; decline deletes the request | auth | same | `:15600` |
| `withdraw_league_cancel` | `p_league` | text | Pro | auth | same | `:15611` |
| `league_cancel_status` | `p_league` | jsonb `{open, members, approved, you_approved, you_refund_cents, is_pro, requested_by_me}` or null | member | auth | same | `:15592` |
| `cancel_league_now` | `p_league` | void | internal; EXECUTE revoked from API roles | none | same | — |
| `mark_cancellation_sent` | `p_id, p_error` | void | service_role | none | same | edge fn |
| `close_season` | `p_season` | void | engine only (tick) | none (service_role) | `20260724230000` | — |
| `award_season_trophies` | `p_season` | void | engine only | none | `20260725190000` | — |
| `close_month` | `p_season, p_month date` | void | **NO caller check** — see §9.1 | **auth** (re-granted by `20260727160000:341` after D37 revoked it at `20260718172300:44`) | `20260727160000:210-341` | **none** — the client never calls it |
| `career_record` | — | jsonb `{cups, runner_ups, crowns, majors, events, trophies, earnings_cents, seasons_done, leagues}` | self | auth | `20260725190000` | `:16398` |
| `season_email_payload` | `p_season` | jsonb | (edge fn reads) | auth | `20260725140000` | edge fn |
| `join_covenant_info` | `p_code text` | jsonb `{name, buyin_cents, preset, floor, finish, structure}` | none (by code) | anon, auth | `20260722211500:29-44` | `:15178` |
| `delete_account` | — | void | self; refuses if you run a league with others or created an event with others; hard-delete only with zero footprint, else tombstone + ban | auth | `20260717205347` | `:13750` |
| `submit_feedback` | `p_category, p_body, p_context jsonb` | uuid | signed in; category coerced to `confusing|friction|idea|bug|other` | auth | `20260714160000` | `:15383` |
| `founder_id` | — | uuid | none | anon, auth | `20260714220000` | `:12872` |
| `founder_desk` | — | jsonb | `auth.uid() = founder_id()` | auth | `20260721191500`, reports pane added `20260723150000:141-196` | `:15423` |
| `founder_note` | `p_body` | uuid | founder | auth | `20260721191500` | `:15413` |
| `report_content` | `p_post, p_reason, p_kind='post', p_profile` | void | league member for posts; any signed-in for `profile_photo` | auth | `20260718174500`, widened `20260723150000:93-139` | `:4852`, `:13434` |
| `set_mute` / `my_mutes` | `p_profile, p_on` / — | void / uuid[] | self; cannot mute self | auth | `20260722013000` | `:13418`, `:12881` |
| `sandbox_arm/rewind/week/advance/scrap` | see contract | jsonb | `profiles.is_founder` via `assert_sandbox()` | auth (founder inside) | `20260724170000`, `…190000`, `…200000`, `…210000` | **none** — SQL-editor / console driven |
| `sandbox_find` / `sandbox_reshape` | `p_code` / `p_league, p_back, p_long` | uuid / jsonb | founder | auth | `20260724190000/210000` | none |
| `create_major` | `…, p_buy_in numeric=0, p_pot_split text='places', …` | uuid | signed in | auth | `20260720193000:191-230` | `:16113` |
| `settle_major` | `p_session` | void | organizer / tick | auth | `20260720193000:373-530` | — |
| `create_forfeit` / `settle_forfeit` / `scrap_forfeit` | see contract | uuid / void / void | crew member / a party or the Pro / poster or Pro | auth | `20260724120000` | module `16219+` |

Not RPCs but direct table access the client relies on (all through RLS):
`league_settings` select+update (`:14137`, `:14888`), `buy_ins` select
(`:14331`), `app_flags` select (`:6583`), `client_events` insert (`:6103`),
`invites` select (Pro, `:16897`), `league_members` count (`:15646`).

---

## 4. Data model

| Table / view | Columns that matter here | Policies / grants | Notes |
|---|---|---|---|
| `league_settings` (baseline `:1073-1101`) | `buyin_cents int default 7500`, `payout_champ 60 / payout_runnerup 25 / payout_king 15` (CHECK sum=100), `finish` (`20260716170000`), `locked_at`, + every bylaw dial | `settings_read` member; `settings_write` commissioner AND `locked_at IS NULL` | Bylaws are locked by RLS, not by an RPC. No "edit bylaws mid-season" exists except `set_league_finish`. |
| `buy_ins` (`:885-892`) | PK `(season_id, member_id)`, `amount_cents`, `paid`, `marked_by` (member id), `marked_at` | `buyins_read` member; `buyins_write` commissioner (ALL) | `amount_cents` snapshots the stake at mark time. Deleted by `remove_member`. |
| `season_adjustments` (`:1275-1290`) | `season_id, squad_id, member_id, month, kind, points, reason, created_by (member), created_at`; `kind ∈ floor_penalty, floor_forfeit, matchup_bonus, bye, override, month_closed` (widened `20260718172300:212-214`) | `adj_read` member; `adj_write` INSERT for commissioner | Writers in practice: `close_month()` (floor penalties, sentinel) and `set_member_bye()`. **`override` has no writer anywhere** — there is no "adjust points" tool. `created_by IS NULL` distinguishes engine rows from human rows (sentinel check at `20260727160000:221-224`). |
| `v_squad_standings` (`:1411-1435`) | `points = counting rounds + sum(adjustments where squad_id not null)` | security_invoker | The client shows the net as "Bonuses & penalties · the ledger" (`:11649-11651`) — one number, no per-row receipt UI. |
| `commissioner_log` (`:898-905`) | `league_id, actor_id (member), action, detail jsonb` | `clog_add` commissioner; `clog_read` member | Written by `remove_member`, `transfer_pro`, `form_squads` (`20260722210000:151`), `20260727160000:565`. **Never read by the client** — spec §9's "every override logged and visible" is half-built. |
| `seasons` | `champion_squad_id / champion_member_id / runnerup_* / points_king_member_id / champion_score / runnerup_score / tiebreak_rung / kicked_off / grace_hours` | `seasons_read` member; `seasons_write` commissioner | |
| `season_payouts` (`20260725100000:18-35`) | PK `(season_id, profile_id, reason)`, `cents int`, `reason ∈ 'Cup champion','Runner-up','Points king'` | SELECT for league members; no API writes | THE settlement of record (D67). |
| `league_cancellations`, `cancellation_votes`, `cancellation_notices` (`20260726100000`) | request/approvals/refund snapshot | ALL revoked from API roles; RPC-only | `notices.payload = {league, recipients:[{email,name,cents}]}` |
| `events` (`20260720193000:40-41`) | `buy_in numeric default 0`, `pot_split ∈ places, wta` | | Majors only (Ryder events have no buy-in). |
| `event_major_cards` | `prize numeric`, `rank`, `exhibition`, `no_card` | | Major settlement of record. |
| `forfeits` (`20260724120000:18-43`) | `name, terms, kind, party_a, party_b (null = standing bounty), hangs_on, status, winner, settled_by` | select member | Non-money stakes; never rendered as dollars. |
| `app_flags` (`20260718045514:43-53`) | `key text PK, value jsonb, updated_at` | `flags_read` SELECT authenticated; **no write policy** (SQL editor only) | see §6 |
| `client_events` (`20260717153000:20-37`) | `profile_id default auth.uid()`, `event text ≤64`, `props jsonb`, `created_at` | `ce_insert_own` INSERT only; no read policy | see §7 |
| `pilot_feedback` (`20260714160000`) | `profile_id, category, body ≤4000, context jsonb` | own SELECT; writes via RPC | category gains `founder` in `20260721191500` |
| `feedback` (baseline `:1019-1027`) | legacy league-scoped | `fb_add/fb_read` member | **dead** — no client code uses it (noted in `20260714160000` header) |
| `content_reports` (`20260718174500:16-27`, widened `20260723150000:82-91`) | `post_id (nullable), profile_id, kind ∈ post, profile_photo, reporter, reason, resolved` | no API policies; RPC writes, founder_desk reads | No resolve UI anywhere — `resolved` only flips in the SQL editor. |
| `profiles.is_founder` (`20260714220000`) | trigger `tag_founder` sets true when `lower(email) = 'jerecho@fischbeck3.com'` | | Founder identity is keyed to ONE hard-coded email. |
| `leagues.sandbox bool` (`20260724170000:34`) | | | Fenced tenant flag; `cancel_league_now` skips the refund email for sandboxes. |
| `scan_usage`, `courses_usage` | cost ledgers | service-role only | counters behind the `app_flags` caps |
| `mutes`, `device_tokens` (`20260722013000`) | | | |

---

## 5. Commissioner & founder capability matrix

"Pro" = `league_members.role = 'commissioner'` (`is_commissioner()`, baseline
`:427-433`). There is exactly one per league; `transfer_pro` moves it. Self-
promotion was killed in D37 (the `members_self` UPDATE policy).

| Capability | Pro | Member | Founder | Phase gate | Where enforced |
|---|---|---|---|---|---|
| Set buy-in, split, every bylaw | yes (direct `league_settings` update) | no | — | only while `locked_at IS NULL` | RLS `settings_write` |
| Lock the league | yes | no | — | setup | same |
| Mark a buy-in paid/unpaid | yes | no (toast) | — | season exists | `mark_buy_in` body |
| Flip the endgame (cup final ↔ points table) | yes | no | — | until `ends_on−27` | `set_league_finish` body |
| Set a member's starter index | yes | self via `set_index` | — | any | body; posted to board |
| Grant / clear a bye | yes | no (auto-bye fires itself) | — | active season | body |
| Remove a member | yes | no | — | **setup only** | body ("mid-season tools are coming") |
| Hand off the Pro role | yes | no | — | any | body |
| Announce to the board | yes | no | — | any | body |
| Add golfers / see pending invites | yes | share link only | — | post-lock (D40) | RLS `invites_all` |
| Form / randomize squads, start draft, make picks, start season | yes | picks if captain | — | draft phase | other slice (draft audit) |
| **Adjust points / write an `override` row** | policy allows a direct INSERT (`adj_write`) but **no UI and no RPC exists** | no | — | — | nothing calls it |
| Void / edit / delete a member's round | **no** — `delete_round` is owner-only (`20260715170000:16-17`); rounds are immutable (§16, D37) | own delete only | — | — | |
| Close a month early | not intended — but see §9.1 | see §9.1 | — | — | |
| Delete a pre-tee league | yes | no | — | setup/draft or not-kicked-off | `delete_league` |
| Cancel a live league | free: alone; money: needs unanimous | vote | — | not complete | D71 RPCs |
| Settle / scrap a forfeit | yes (backstop) | a party / the poster | — | — | `20260724120000:92-140` |
| Create a Major with a buy-in | anyone | anyone | — | — | `create_major` |
| Mute / report | anyone | anyone | — | — | |
| Read `commissioner_log` | policy allows | policy allows | — | — | **no UI** |
| Founder desk (stats, events, feedback, reports) | — | — | **only** `auth.uid() = founder_id()` | — | RPC body |
| Field note | — | — | founder | — | RPC body |
| Sandbox league (arm/rewind/week/advance/scrap/reshape/find) | — | — | founder (`is_founder`) | — | `assert_sandbox`; console only |
| Flip `app_flags` (kill switches, caps) | — | — | SQL editor / dashboard only — no RPC, no UI | — | no write policy |
| Resolve a content report | — | — | SQL editor only | — | no RPC |
| `test-seed` edge function (seed/reset a test world under the caller) | **any signed-in user** | any | — | — | `supabase/functions/test-seed/index.ts:329-331` — gated on "signed in", not on founder |

---

## 6. `app_flags` inventory

| Key | Seeded value | Seeded by | Read by | What it gates |
|---|---|---|---|---|
| `scan` | `{"enabled": true, "daily_per_user": 5, "monthly_global": 400}` | `20260718045514:51-53` | client `loadScanFlag()` `:6579-6588` (hides the scan button when the row is missing or `enabled:false` — fail-closed); `supabase/functions/scan/index.ts:121-125` (kill switch, per-user daily cap, global monthly cap; API failure / credits out → `{unavailable:true}` HTTP 200) | Scorecard scan (Anthropic vision). Budget changes and the kill switch are an UPDATE, never a deploy. |
| `courses` | `{"daily_per_user": 150}` | `20260718173100:78-80` | `supabase/functions/courses/index.ts:146-149` | GolfCourseAPI per-user daily cap |
| `pricing` | **not seeded** — proposed in `spec/handoffs/pricing-integration-plan.md:35-80` as `{visible, anchor_cents, bands[], season1_free, founding:{cap, closed, ids}}` | none (no migration exists) | nothing yet | Would flip pricing copy and hold the Founding League badge map (league UUID → badge number) without a schema change. D56 says visible-model-at-launch; D98 re-anchors that from "iOS launch" to the web client. |

RLS: `flags_read` SELECT for `authenticated` only (`20260718045514:49`); anon
cannot read flags; there is no write policy — every flip is dashboard/SQL
editor work. Native should read flags on boot (authenticated) and treat a
missing row as "off" for anything fail-closed, exactly as `loadScanFlag` does.

---

## 7. Telemetry / `client_events` shape

- Table: `client_events(id, profile_id default auth.uid(), event text ≤64,
  props jsonb, created_at)` — INSERT-only for the owner, unreadable through the
  API; the founder desk reads the last 30 as owner (`20260721191500:56-62`).
- Emitter: `qaEvent(event, props)` `:6100-6105`; bridged to the module as
  `window.qaEvent` (`:6110`). Never fires in demo; every failure is swallowed.
- Event names actually emitted (grep of `qaEvent(`): `post_open`,
  `post_submit` (`{mode, secs, gross, holes}` — read by `v_post_timings`),
  `post_mode_switch`, `post_even_par_confirmed`, `scan_post`,
  `scan_claim_minted`, `content_reported`, `home_hero_state`, `home_hero_tap`,
  `home_occasion_tap` (×2), `client_error` (×2 — `window.error` and
  `unhandledrejection` handlers at `:3659-3675`, props `{kind, msg ≤300,
  stack (4 frames), step: bootStep}`), and module-side `league_create`,
  `lock_attempt`, `lock_blocked`, `lock_ok`, `invite_open`.
- Operator-only views (revoked from API roles): `v_pilot_gates` (signup →
  card → first league → first round timings, joins `auth.users`) and
  `v_post_timings` (`20260717153000:44-88`).
- Coverage caveat (CLAUDE.md): RLS lets only `authenticated` insert, so
  signed-out sessions are invisible to telemetry.
- Feedback: `pilot_feedback` via `submit_feedback` with context `{view,
  version, league_id, league_name, event_id, demo, path, ua}` (`:15370-15380`).

Native equivalent: keep the same table and event vocabulary; add a
`platform`/`build` prop so the desk can split web vs phone; keep the 4-frame
stack rule for `client_error`.

---

## 8. Business rules with citations

1. **The pot is a ledger, never held; the app moves nothing.** D39 (retires
   "never held" as a forever promise; keeps the door open to a future
   collection/distro SERVICE that would be a money-transmission compliance
   project, not a copy edit). `legal.html:78-84` remains present-tense fact.
   CLAUDE.md header. Spec §7 ("Track, never hold") is the pre-D39 wording.
2. **$0 buy-in is first-class and hides the money chrome.** D70; D46 ("money
   is a choice, not a default" for Majors). Note the LEAGUE default is still
   $75 in the schema (`buyin_cents default 7500`) — the wizard's own default
   should be verified in native.
3. **Split presets only; sum to 100.** D8 (no custom-% editor), `payout_sums_100`
   CHECK. Spec §7 default 60/25/15.
4. **Bylaws lock at first tee; set it once, argue never.** Spec principle 4
   (`spec-v1.0.md:10`), RLS `settings_write ... locked_at IS NULL`. The one
   in-season dial is the finish (D-endgame migration 008 / `set_league_finish`),
   locked at `ends_on−27`.
5. **Money never surprises anybody at the door.** Setup-QA S3-01 → the join
   covenant names the stake before `join_league` (`:15173-15194`), and
   `join_covenant_info` is anon-callable for exactly that.
6. **Settlement is stored fact, not recomputation.** D66 (scores and rung
   stored on `seasons`), D67 (`season_payouts` written once at close;
   `career_record` sums rows). Spec §16 extended to the crown and the money.
7. **Pennies: parts always sum to the pot.** D66 tradeoffs; `payout_penny_fixes`
   (earliest seats absorb remainders; champion absorbs the top-level remainder).
8. **Cancellation is consent-gated by money.** D71 — free: Pro alone; money:
   unanimous, any decline kills; refund is a NOTICE; a complete season can never
   be cancelled (§16 record book).
9. **Departure never disturbs the ledger.** `delete_account` tombstones anyone
   with a footprint (`20260717205347:49-58`); `remove_member` is setup-only;
   pilot decision 2026-07-15 ("gone gone" socially, kept competitively).
10. **Identity is checked at the database, never by hiding a button.** D37;
    the founder desk card's `display:none` is "courtesy, not security"
    (`:2849-2851`). Every new client RPC needs an explicit `grant execute …
    to authenticated` and a `revoke … from public`.
11. **Ledger reasons are mandatory and visible.** Spec §14.2 ("every adjustment
    carries a reason, reversible via the log"), §16 (squad totals decompose
    into rounds + bonuses − penalties with ledger reasons).
12. **Pricing posture.** CLAUDE.md Monetization: one general membership; a
    per-league season pass paid by the Pro from the pot (~$49–99 ≈ $5–8/player);
    golfer free forever; Founding Leagues (PIGL + first ~5–10) free forever;
    charge at season-2 "run it back"; Stripe parked; never resell the index.
    D56 unparks a VISIBLE model with NO checkout; D98 moves D56's trigger from
    "iOS launch" to the web client and makes "no purchase UI in any app" a
    cross-store rule. `spec/pricing-arc.md` and `pricing-integration-plan.md`
    are the design; nothing is built (`:3542` and `:13578-13580` are static
    "coming at launch" copy).
13. **Founding Pro playbook.** `spec/founding-pro-playbook.md` — Founding
    League = free for life + badge + direct line, cap ~10, soft obligation to
    play a season and answer monthly. Badge storage proposed as
    `app_flags.pricing.founding.ids`.
14. **Forfeits are never money.** D64 — no dollar rendering, no conversion to
    the pot, "store-review posture guarded".
15. **Sandbox is a fenced production tenant, not a mock.** D65 — founder-only,
    single-league bots, scrappable, invisible to everyone else.
16. **Demo never touches the database.** CLAUDE.md landmine; D83 retired the
    user paths but kept `state.demo` as the write-guard.

---

## 9. Edge cases & landmines (what must be backend-authoritative)

### 9.1 `close_month` is callable by ANY signed-in user (regression of D37 C3)

`20260718172300_security_hardening_launch_blockers.sql:44` revoked
`close_month(uuid, date)` from `anon, authenticated` because the season-
lifecycle RPCs have no in-body caller check. `20260727160000_board_voice.sql`
re-created `close_month` (`:210-339`, still no `is_commissioner` / `auth.uid()`
check — the only `is_commissioner` in that file, `:529`, is inside `make_pick`)
and then at `:340-341` did `revoke … from public, anon; grant execute … to
authenticated`. The live contract confirms it: `close_month|…|definer|auth`.
The client never calls it (zero hits in `index.html`; it is not in
`tests/db-checks.sql` check 3's list), so the grant is boilerplate, not intent.

Consequence: any member of any league — in fact any authenticated user, since
the body never checks membership either — can call `close_month(<season>,
<month>)` mid-month. It assesses floor penalties / forfeits on partial data into
`season_adjustments`, posts "JULY CLOSED — LEDGER POSTED", and writes the
`month_closed` sentinel, after which the real cron close on the 1st is a no-op.
The premature penalties are never corrected. Fix is a NEW migration that
`revoke execute … from anon, authenticated` (or adds a caller gate); the
contract snapshot and `tests/db-checks.sql` should then be refreshed. Flagged
here only — this audit is read-only.

### 9.2 Three copies of the settlement arithmetic

- Server of record: `award_season_trophies()` → `season_payouts` (cents, penny-
  exact).
- Server prose: `close_season()` pot line uses `round(pot × pct/100)` in
  DOLLARS (`season_result_columns.sql:196-205`) — can disagree with the cents
  rows by a dollar on odd pots.
- Client: `csSettlement()` `:11479-11508` RECOMPUTES from `state.stake ×
  CS.members.length` and the bylaws — it never reads `season_payouts`. If the
  roster changes after close (a member removed, an account hard-deleted —
  possible only with zero footprint, but possible), the ceremony drifts from the
  record, which is the exact failure D67 was written to prevent. Native should
  render the ceremony FROM `season_payouts` and use the client math only as a
  pre-close preview.

### 9.3 Pot total counts the whole roster, paid or not

`pot = buyin_cents × count(league_members)` everywhere. An unpaid member still
inflates the pot and the payout lines; a member who never pays is only visible
on the `#payers` ticks. The ceremony's "what each is owed" can therefore exceed
what was actually collected. Intended (the ledger shows who owes), but native
copy should keep the "N/M buy-ins in" chip next to every pot figure so the
number never reads as cash on hand.

### 9.4 Stake snapshots vs live bylaws

`buy_ins.amount_cents` snapshots the stake when marked; `renderPot` uses it if
present, else `state.stake` (`:6996`). Since bylaws are RLS-frozen after lock
this rarely matters, but a re-lock (skew retry path at `:14905-14923`) or a
sandbox `reshape` could desync them. Backend should be the only source.

### 9.5 The Major uses a different money regime

`event_major_cards.prize` is NUMERIC dollars rounded to 2dp, split 60/25/15 or
`wta`, exhibition excluded, unfilled places roll to the champion, "no card ·
buy-in stays in the pot" (`:12469`); a no-card buy-in "settles as a donation,
on the card" (D46). There are no `season_payouts`-style rows for Majors, so
`career_record.earnings_cents` excludes Major money. Two ledgers, two rounding
rules — native should not merge them without a decision entry.

### 9.6 Cancellation edge cases

- `vote_league_cancel` counts `league_members`, so a member added AFTER the
  request re-opens the unanimity bar; a member removed cannot happen in-season
  (`remove_member` is setup-only), so the bar only ever rises.
- A single decline deletes the request AND all approvals; the Pro must restart
  from zero.
- The refund snapshot excludes members with no email, `@cupseason.invalid`, and
  `@sandbox.cupseason.test` addresses — bots never get a refund email; a real
  member with a blank email silently gets no notice.
- `you_refund_cents` sums PAID buy-ins across every season of the league, not
  just the current one.

### 9.7 Account deletion is loud, and the Pro cannot leave

`delete_account` refuses a Pro who runs a league with other members ("Hand it
off or delete that league first"). `transfer_pro` is the only way out. A
tombstoned member keeps their `league_members` row (so `count(league_members)`
— and therefore the pot — still includes "Former member"). Confirm that is the
intended arithmetic before native reproduces it.

### 9.8 Founder identity is a hard-coded email

`tag_founder` matches `jerecho@fischbeck3.com` exactly (`20260714220000:8-19`).
The owner's other address (the one this session runs under) would NOT be
tagged. Native must never infer founder-ness client-side; call `founder_id()`
and let `founder_desk()` refuse.

### 9.9 `test-seed` is not founder-gated

`supabase/functions/test-seed/index.ts:329-333` only requires a signed-in user;
any account can seed/reset a bot world under itself with the service role. It
mints `@cupseason.test` auth users. Fine for a pilot, not for a public store
build — either gate on `is_founder` or remove before launch.

### 9.10 The `override` kind and `commissioner_log` are built but inert

No RPC writes `season_adjustments.kind='override'`; the `adj_write` policy
would let a commissioner INSERT one directly, with an arbitrary `points` and
`reason`, and it would flow straight into `v_squad_standings`. No UI reads
`commissioner_log`. Spec §9 ("Commissioner can void/edit any round — every
override logged and visible") is therefore NOT implemented, and §16 D37 says
rounds are immutable anyway. Decide (decision-log entry) whether native gets a
points-adjustment tool with a mandatory reason, or whether the policy should be
tightened to RPC-only.

### 9.11 Native `confirm()` still guards three Pro actions

Remove (`:16957`), Bye (`:16972`), Make Pro (`:16981`) use `confirm()`, which
installed PWAs and webviews swallow (setup-QA S4-03). Native gets real alerts,
but the desktop rewrite should finish the sheet conversion.

### 9.12 Deploy skew fallbacks that native must not inherit as behavior

`covenantGate` fails OPEN when `join_covenant_info` is missing; `career_record`
absence is a warn; `league_cancel_status` absence hides the banner. On native,
a missing RPC is a version-mismatch error to surface, not a silent downgrade —
the phone cannot be redeployed by a `git push`.

### 9.13 Things that must stay backend-authoritative

Pot total and split · per-person settlement rows · buy-in paid state · bye and
floor-penalty rows · month close (with a real caller gate — §9.1) · season
close, crown, tiebreak rung · cancellation votes and refund snapshots · founder
identity · every kill switch and cap · report/mute state · account deletion and
the tombstone decision. The phone renders; it never computes money.

---

## 10. Web-specific / clunky things, and the "desk work" claim

D98 / `spec/native-arc.md:16-21` / `spec/native-b1-brief.md:31-32` assign the
wizard, draft board, ledger and founder desk to desktop only. Evaluated against
what each screen actually does:

| Screen | What it really is | Verdict |
|---|---|---|
| **Wizard** (`:3207-3310`, ~56 client refs) | ~12 dials, three presets, a live portrait, a review card, invite staging. Set once per season. | **Desk work — agreed.** It is a form you fill once at a kitchen table. The phone should still be able to *read* the bylaws card and *join* via the covenant. |
| **Draft board** | not this slice | Agreed per D98 (117 refs, pick order, clock). |
| **Ledger — the pot pane** (`:3497-3525`, `renderPot`) | One number, three payout tiles, and a list of names you tap as cash changes hands. | **Not desk work.** Marking a buy-in happens exactly where money moves — the parking lot, the 19th hole, the group text — i.e. on a phone. The read side (pot, split, N/M in, "you owe / you're owed") is a phone read. Recommend: phone gets the pot pane INCLUDING `mark_buy_in` for the Pro; desktop gets the same plus any future adjustments UI. |
| **Ledger — `season_adjustments` receipts** (`:11640-11661` one net line) | Currently one number ("Bonuses & penalties · the ledger"). No per-row view exists on either surface. | Desk work only in the sense that nobody built the receipt view. The §16 receipt (rows with reasons) is a read and belongs on both; any future *write* (override with reason) is desk work. |
| **Ceremony / settlement** (`:11465-11600`) | A screenshot-shaped takeover with "You're owed $N". | **Phone-first.** This is the artifact people share from their pocket. |
| **Members & invites — Pro tools** (`:16891-17036`) | Set index, bye, remove (setup only), make Pro. Four taps a season. | Split: **Bye** and **Set index** are phone-worthy (a member texts "I'm out for July" from the course); Remove and Make Pro are rare and fine on either. |
| **Cancellation** (`:15563-15683`) | Pro requests; members approve/decline from a banner. | Vote = phone (it arrives as a push). Request = either. |
| **Founder desk** (`:15395-15457`) | 8 counters, three "last N" lists. Read-only except field notes. | **Desk work for triage, but the field note is a phone thing** — the owner writes "what you noticed, before it slips" at the course. Keep `founder_note` on the phone; leave the dashboard, report resolution, `app_flags` flips and the sandbox on desktop/SQL. |
| **Feedback / report / mute / delete account** | Store-review requirements (D98 "what survives"). | Phone, mandatory. |
| **Membership card / Pro Shop** (`:3539-3550`, `:13578-13580`) | Static "coming at launch". | D98: no purchase UI in any app. Phone shows the plan state read-only (Founding badge / free season / paid) once the `pricing` flag exists; checkout is web. |

Web-specific clunk native should not copy:

- Money is rendered from `state.stake` (an integer DOLLAR value rounded from
  `buyin_cents`, `:14146`) — cents are lost at the edge; native should carry
  cents end-to-end.
- Three separate code paths render the pot (Home tile, on-the-line bar, pot
  pane) and D70's hide/show toggles them by DOM id — a single `PotSummary`
  view model from one query.
- `renderPot` sizes the pot off `max(members, invited+1, 1)` (`:6992`) — it
  guesses from staged invite emails pre-lock. Native should use the roster
  count the server uses.
- `transfer_pro` triggers `location.reload()` (`:16988`) because role change
  "reshapes the whole UI"; native re-fetches membership.
- The League Room "Pot" segment is hidden by inline `style.display` when
  `stake===0`; native derives tab visibility from data.
- The ceremony's once-per-season gate is `localStorage` (`:11513`); native
  should persist "seen" server-side or per-device intentionally (D66 says "once
  per member").
- Ten RPC calls include a "pre-migration / skew" try/catch that silently
  downgrades; native should surface version mismatch (§9.12).

---

## 11. Open questions

1. **`close_month` grant (§9.1):** confirm it is unintended and ship the revoke
   migration before any public build; add `close_month` to a "never granted to
   API roles" assertion in `tests/db-checks.sql`.
2. **Pot arithmetic vs unpaid / tombstoned members (§9.3, §9.7):** is the pot
   `stake × roster` (what is owed) or `sum(paid buy_ins)` (what is in hand)?
   Today every surface says the former; the ceremony's "You're owed" can exceed
   collected cash. Needs a decision-log line, because native will carry it
   into a store listing.
3. **Ceremony source of truth (§9.2):** should the client stop recomputing and
   read `season_payouts`? (Recommended yes; also fixes the dollar-vs-cent
   mismatch in the `close_season` post.)
4. **Points adjustments (§9.10):** does the product want a Pro "override with
   reason" tool (spec §9 / §14.2 promise it) or should `adj_write` be revoked
   and the ledger be engine-only? Either way, a per-row ledger receipt UI is
   missing on every surface.
5. **`commissioner_log` visibility:** members can read it by policy; nothing
   renders it. Is it the "override log" spec §9 promises, or dead?
6. **Founder identity (§9.8):** one hard-coded email. Should `is_founder`
   become a dashboard-set column so a second address (or a co-founder) works
   without a migration?
7. **`test-seed` gate (§9.9):** founder-only or delete before launch?
8. **Pricing surfaces:** D98 re-anchors D56 to the web client — does the
   `pricing` `app_flags` key and the Founding badge map ship in the web client
   before the phone app, and does the phone ever show the badge/plan card?
9. **Mid-season member tools:** `remove_member` says "mid-season tools are
   coming" (`20260712150000:137`). Is a mid-season departure (with a squad
   playing short — spec §9 "Dropouts") a native v1 need for PIGL?
10. **Majors money and career earnings:** should Major prizes be recorded as
    payout rows so `career_record` includes them, and should Major rounding be
    moved to cents to match the season ledger?
11. **Cancellation unanimity drift (§9.6):** should the required approval count
    freeze at request time?
12. **Report resolution:** no path exists to resolve a `content_reports` row
    outside SQL — acceptable for the founder desk on desktop, but App Review
    expects a working moderation loop; confirm the desk gets a "resolve"
    RPC before submission.
