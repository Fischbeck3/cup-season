# Verify · SP-10 · lens "is-it-structural"

Repo `/Users/fischbeck3/cup-season` at tip `3bba87e` (2026-09-04). Read-only; prod read via `supabase db query --linked`. SAW = read in code/prod/screenshot; INFER = reasoned.

Question under test: can a copy change, a single-screen change, a default change (or an implementation-level producer/lint/telemetry change) dissolve SP-10 with no IA or mental-model change, without leaving the brief's five questions unanswered for at least one persona?

## Verdict

**holds = false** (as a STRUCTURAL problem). The evidence is real and reproduces at tip with the corrections below, but every item dissolves at level 6 — a governance entry, six single-line/single-screen bug fixes, a lint per copy law, and one-line telemetry changes — and no persona's Q1–Q5 stays unanswered *because of SP-10* after that set. The draft concedes the criterion in its own text: "It is not a screen" (statement, "why_structural") and "it damages no persona's session directly" (`structural-problems-draft.md:308`); `hierarchy_level` is implementation. SP-10 is the redesign's **programme gate**, not a tenth structural product problem; re-file it as such (see Corrections §8) and keep its "land before the first build" sequencing, which is the useful content.

## The refutation — the dissolve set, all level 6, none IA

**(a) The reference ambiguity — a default/governance change, zero screens.**
- SAW `CLAUDE.md:301-303` "The web client is the behavioural reference; the phone owns operating the league, the desk owns authoring it (IOS-007)" — stale against IOS-018 (`docs/ios/DECISIONS.md:179-189`: "the phone builds *everything the web has* … Only after parity is real does the ecosystem question get asked … a later decision") and D100 (`spec/decision-log.md:3633-3658`).
- SAW IOS-011 `DECISIONS.md:127` "⊕ is a full-screen cover opening **on the post form**" vs the D110 addendum `decision-log.md:4116-4119` "the ⊕ … now ALWAYS open the cover".
- SAW the "web owed" notes: D121 `:4243` "The web row is still owed."; D130 `:4334` "the web hero still repeats it … a web task"; D219 `:5671` "a web task under this entry"; D216/D217/D218 `:5640-5660` "BUILT 2026-09-02 — client only".
- Fix: one decision-log entry answering the question IOS-018 deferred (the O-15 shape the canon reader already specified: which client is the reference, the parity rule going forward), a three-line CLAUDE.md edit, one IOS-0xx line superseding IOS-011's ⊕ clause. No route, tab, noun or mental model changes for any golfer.

**(b) The divergent facts — six single-screen fixes, each with a producer that already exists.**
- WB-02: SAW `index.html:20066` `if(CS.memberships.length > 1) toast('Switch groups anytime from Home');` with no Home switcher. Fix: delete the line, or port `HomeLeagueRows` (D121 says the data is already in `native_home()`, no migration).
- WB-03: SAW `:10987` `if(r.mine === false) return;` (never reads `tagged_me`/`my_rsvp`); the Next tile `:11052-11054` filters only the date over `watchAll`. Fix: one `plans()` mirroring `ScheduleModels.swift:388-389`.
- WB-05: SAW `:10877` "you've posted ${fmtN(credits)}". Fix: one string.
- WB-06: SAW `:14125` `(sn.standings&&sn.standings.squads)||[]`. Fix: the `solo ? individuals : squads` ternary the file already uses at `:4660, :5093, :11498`.
- CJ-50: SAW `:17705` `if(!info || !Number(info.buyin_cents)) return true;` — the comment `:17699-17701` justifies the fail-open as deploy skew ("while the RPC isn't deployed"); `join_covenant_info` is in `packages/db/contract.psv` and is one of the twelve anon endpoints (L-45), so the reason is gone. The Kit is explicit the other way: `CupSeasonKit/People/JoinLeague.swift:99-106` "On the phone a missing or failing RPC is an ERROR (fails closed) — the web fell open". Fix: one token; restores L-12 ("every join passes the covenant").
- PP-01: SAW `PostCard.swift:238-244` `let rating = card.ratingValue` with no `> 0` guard, `PostRoundModel.swift:201` `guard preview != nil`; the web's Q-22 `:6989-6999` refuses to score a blank rating. Fix: mirror Q-22 in `PostCalc.preview` — one screen.

**(c) "Every copy law has two homes with one lint" — the repo's own discipline, extended.**
- SAW `tests/preflight.mjs:635-657` (check 20) compares `STAGE_LABEL` to `LeagueCopy.Stage.label`; SAW `:14635` hand-derives `'Squad formation'` beside `STAGE_LABEL.drawing = 'Squads drawing'` (`:6221`) — the exact bypass D201 diagnosed (`decision-log.md:5449`).
- The canon's own law is L-43: "six words from **one producer per client**, gated by preflight 20" — so the fix is a lint per law (bands, endgame, floor sentence, week number) or a server-returned string (DL-05's `week_no`, DL-26's `band_name()`), plus `STAGE_LABEL[leagueStage()]` at `:14635`. Implementation; no IA.

**(d) The scoreboard — one-line client changes.**
- SAW `index.html:6900` `if(state.demo || !window.sb) return;`; `state.demo` starts `true` (`:4083` `demo:true`) and is cleared in the league-less shell / `showWelcome` (`:19847` `state.demo = false;`), AFTER `crew_step_shown/done` (`:15012, :15016`) and the signup `covenant_declined` (`:20108`) fire. D185 removed the identical guard from `growthEvent` and proved it against prod (`decision-log.md:5110-5114`: "The guard is deleted, not narrowed … the server is the real gate"). Prod: zero `crew_step_*` / `covenant_declined` rows, ever. Fix: the same one line, or clear `state.demo` before the crew step.
- SAW `Telemetry.swift:41-48` `event()` sends `{event, props}` with no platform; `product()` `:55-56` adds `build` (+ `league_id`). Fix: one key in each writer. Prod: `client_events` columns are `id, profile_id, event, props, created_at` — no client column; `rounds` has `source` but no client column.
- SAW DL-30: no `app_open`/view event on either client; the table accepts any event name ≤ 64 chars. Fix: three event names on both clients.
- SAW `apps/ios/Screenshots/6.9/05-you.png` (Sep 1) renders "Member since Aug 2026", "YOUR DISPLAY CASE", "THE RECORD · No silverware yet", "LIFETIME"; tip has `CSSectionHead("Display case")` (`YouScreen.swift:135, 144`) and `TourCard.swift:146` "'Member since' is retired". Fix: reshoot from the submitted build.

## Persona residue after the dissolve set

- **D** — the Aug-31 screenshot's Home differing from the code (`persona-D:5, 25, 49`) is artefact staleness (the signup-walk set is the WEB, `reader-screens-visual.md:9`); D's real Q3 gap (start a league behind `+`) belongs to SP-2/SP-3, not to the two-client split.
- **A** — "I have a league code" on the web door (`index.html:2825`) and not `DoorView.swift:102-111` is a single-screen add or removal; A "has no code anyway" (`persona-A:44`).
- **E** — the link → browser → App Store → no deferred deep link seam (`persona-E:369`, `JoinIntent.store` only in `onOpenURL`) is the one genuinely cross-client *experience*, and `verify-SP-6-is-it-structural.md` already holds on exactly that (R2). E's "no telemetry records the link" is measurement, not experience.
- Nobody in the six walks uses both clients in one session; prod shows 4 golfers firing both vocabularies in 30 days (WB §0) and the walks do not exercise them.

Result: with the set above applied, no persona's Q1–Q5 remains unanswered because of SP-10. holds = false.

## Immutable-law check (canon reader §3A)

No fix breaks a wall law. Three must be phrased to respect one, and one remedy in the draft is at the wrong level:
- **L-23** ("`state.demo` plumbing stays as a write guard"): the FR-09 fix follows D185's precedent — `client_events` INSERT is RLS'd to `authenticated` (`Telemetry.swift:8-11`; CLAUDE.md "RLS lets only `authenticated` insert there"), so the diorama cannot write; say "the server is the gate", do not say "remove the demo guard".
- **L-43** ("one producer **per client** … gated by preflight 20"): the statement's "shared producers" should read "a producer per client + a lint per law, or a server-returned string"; the repo's only cross-language sharing mechanism is fixtures (`tests/fixtures/endgame.json`, WB §2b row 29).
- **L-36** (`?share=` stays web; claim/join links consumed the same way on both clients; L-45 the twelve anon endpoints): any "freeze the web" ruling must keep the door/link/guest surfaces alive — WB §6 does; the entry should say so explicitly.
- **L-22** (no vanity metrics): `app_open`/WAU-MAU are internal telemetry, not a user surface — no conflict, but the entry should pre-empt the objection in one line.
- **Level of the ruling**: the draft calls the remedy "a one-line D-numbered ruling"; D100 was logged as "SCOPE / IA, level 3-5" (`:3633-3636`) and a ruling on what the web IS is the same level, so it needs the log's CONFLICT-line format at level 3 (preamble `:20-21`), naming IOS-018/D100 and CLAUDE.md:301-303 as superseded. Still not a change to any golfer's mental model — a scope decision about clients.

## Corrections to the statement and evidence

1. **"nothing stamps the platform" is false at tip.** SAW `HomeView.swift:87, 91` and `OrientationScreen.swift:153` stamp `"platform": "ios"` by hand; `Telemetry.swift:55-56` stamps `build` on the five product events; phone crash rows carry `device`/`os`/`build`. Prod: 5 rows with a `platform` key, 24 with `build`, of 273 total; the web stamps neither. Correct to: "`CSTelemetry.event` does not stamp platform centrally and `qaEvent` never does; no column exists; attribution today is by event NAME and works only because the two vocabularies barely overlap (`client_error`, `home_occasion_tap` are the shared names)."
2. **"the lock has fired zero telemetry since its fix" reads as a dead pipe; it is zero locks.** Prod: lifetime `lock_attempt` 1, `lock_ok` 1, `lock_fail` 0, `invite_open` 1 — all 2026-07-27; the only leagues created since 08-20 are four seeded on 08-28 already in `season` (Ridgeline Cup, Fairway Society, Winter Circuit, Sunset Match). The emitters exist on both clients (`index.html:17774-17814`; `Telemetry.swift:30` `league_locked`). Keep PA-032's wording: "fixed and unproven — no lock has happened since".
3. **FR-09's mechanism**: not "keeps the `state.demo` guard" as such but that `state.demo` starts `true` (`:4083`) and is cleared at `:19847`, after the crew step and the signup covenant decline emit; cite `:4083`, `:19847` with `:6900`, and D185 `:5110-5114` as the precedent.
4. **File/line fixes**: "JoinLeague.swift:99-106" → the throw and its comment are `CupSeasonKit/People/JoinLeague.swift:99-106`; the app flow that catches it is `CupSeason/People/JoinLeagueFlow.swift:99-101` (not "Kit/People/JoinLeague.swift" as CJ-50 has it). "`:10985-10986`" → `:10987`. "eight Home rulings since 2026-09-02" → four ruled 08-29 (D121/D126/D129/D130) and four ruled 09-02 (D216–D219), all BUILT 09-02; D126 is not wholly web-owed — the web has `endgameLine` (`:6318-6337`), one of D126's three homes.
5. **"one device token"** → one token, one golfer, platform `ios-sandbox` (prod `device_tokens`); say sandbox — it is SP-9/EN-01's gate, not a scoreboard fact.
6. **The 30-day split holds**: web-only names 8 golfers (`home_hero_state` 44 rows/8 golfers, last 09-01; `post_open` 69/4, last 09-05) vs phone-only 5 (`signed_in` 14/5, last 09-03).
7. **YP-41 confirmed** by viewing `apps/ios/Screenshots/6.9/05-you.png`; whether build 669 or the shot set is the stale one is still undetermined (the reader could not tell either).
8. **Re-file, do not rank.** Rename SP-10 to a programme gate (e.g. "G-0 · One reference, one producer per law, a scoreboard — before the first build") and split it into three tickets: (i) the O-15 level-3 entry + CC-33/CC-34 corrections (zero build); (ii) the six false-fact defects — WB-02, WB-03, WB-05, WB-06, CJ-50, PP-01 — filed as bugs NOW, independent of the redesign (they are the price of keeping the web up, WB §6); (iii) the scoreboard — the FR-09 one-liner, a `platform` key in both writers, `app_open` / `home_empty_state_seen` / `empty_state_cta_tapped` on both clients, the reshoot tied to the ship checklist. Keep the sequencing note ("land before the first build so the redesign has a baseline") — it is the only part of SP-10 that constrains SP-1..SP-9.
9. **"every success metric the brief names is unmeasurable today" — narrow it.** Competition creation (`league_create`/`league_created`, `growth_events`' five funnel nodes), first-round timing (`v_post_timings`, n=24) and signup (`signed_in`, `card_set`) are measurable; activation-as-app-open, time-to-aha, WAU/MAU, D7/D30 and empty-state engagement are not.

## What I could not determine
- Whether the four 08-28 leagues are sandbox-flagged (the `leagues` columns I used do not say); the point stands either way — no real lock has been attempted since D111.
- Whether any real golfer opens both clients in one week (the 4 "both" golfers are, per WB, likely the owner/reviewer); no walk exercised it.
