# Blind UX / gameplay / retention audit — Cup Season, 2026-08-29

**What this folder is.** The complete record of a blind usability, gameplay and retention audit of Cup Season (season-long fantasy-style golf for friend groups): the web PWA at cupseason.app, production build `34d20b6` — byte-identical `index.html` to this branch, so every client defect recorded here is live in prod — and the native iPhone app in `apps/ios` at the same commit (static screens only). Seven blind personas drove the real product on real prod accounts; synthesis agents read everything against the spec; fifteen independent validators attacked the five headline findings. Everything below — persona reports, structured results, screenshots, the deduplicated issue dataset, the synthesis documents and the seven written deliverables — is in this directory. Start with `blind-ux-audit.md`; if you only have ten minutes, read `critical-findings.md` Part 1 and Part 4.

## How the audit was run

**Blind drive.** Seven personas — an organizer ("Casey", ~14), a league novice ("Dana", ~18, twenty years of golf, never in a league), a new joiner ("Marcus", ~12), a casual golfer ("Jordan", shoots 95–100, no handicap), a competitive golfer ("Priya", 6.4), a skeptic ("Sam", ~15, group runs on a group text and a spreadsheet) and a strictly read-only mid-season observer on the owner's real account — each got a persona brief and *no* product knowledge: no spec, no decision log, no rules. They drove a local serve of the prod build at an iPhone viewport in a headless Chromium (console captured on every step, sign-in codes read from a real Gmail inbox) on accounts `jerecho+blind1..6@fischbeck3.com`, walking Journeys A–G (discovery, join, create, first round, mid-season, finale, next season) plus the ten discovery questions cold and again at the end, a 30-second explain-it-to-a-friend, a glossary, a confusion-debt list, a verdict and ten 1–10 scores. Casual, competitive, skeptic and iOS ran twice; the second run landed on already-used accounts, signed out, redid the cold paths and flagged the contamination. An eighth pass surveyed the native iPhone app's landing screens through a developer launch hatch (no taps). The two organizers created the two audit leagues (**The Papago Grind** `THEPTCQ5` and **Desert Dogs** `DESEUU0K`); the four joiners entered The Papago Grind through the organizer's invite. Raw output: `raw/agent*.md`, `raw/ios-screen-survey.md`, `raw/persona-results.json` (12 result rows, 424 raw items).

**Synthesis.** Five synthesis agents then read every report *with* the spec, the product vision and the decision log open and wrote the six `synthesis-*.md` files (terminology, rules / mental model, loop / information hierarchy, retention / monetization, side games / setup, triage). Triage built 127 master issues from the 284 items the first pass could see; `tools/merge_issues.py` then folded the 140 run-1 items of the re-run personas (133 folded, 7 appended) and the joiner attempt-1 harness item into the final dataset — **135 deduplicated issues from 425 raw items** (`issues.json`, `issues.csv`, `issues-counts.json`, `issues-README.md`): P0 7 · P1 44 · P2 65 · P3 19. Where the spec explains something the screen did not, that is recorded as the finding, never as an excuse.

**Adversarial validation and the orchestrator's own checks.** The top five findings were each handed to three independent validators with different lenses — *unfamiliarity vs interface* (would it clear up in minutes for a normal user?), *does it reproduce / is it intended* (a fresh signed-out drive plus the spec and decision log), and *root cause across the hierarchy* (vision → principles → IA → mechanics → UI copy → implementation) — who re-drove the product, read the source and migrations, and queried prod telemetry read-only. All fifteen verdicts came back **Confirmed UX problem**; the sub-claims they refuted or trimmed are carried in every document (`raw/synthesis-and-validation-results.json`). Separately the orchestrator confirmed the hard defects directly against `index.html` and the database: the `staged` ReferenceError at `index.html:15218` that fires *after* the lock's server writes commit; the `[live-resume]` PostgREST embed ambiguity at `:7800`; the blank-date `played_on` NOT NULL failure narrated as "please try again"; the five 502s from the `courses` edge function; both leagues' first tee defaulting a week out; and that the read-only observer wrote nothing (0 rounds, 0 posts). The seven deliverables were written from all of that and then passed through one editor pass for consistency (see *Editor's corrections* at the end).

## File index

| File | One line |
|---|---|
| `README.md` | This file — start here. |
| `blind-ux-audit.md` | The master report: method, personas, executive verdict (the ten scores and the method behind them), the five biggest problems, mental model, loop, rules, setup, side games, retention, monetization, the backlog, recommended changes, validation, what the product is selling, the zero-instruction test, hard defects with file:line, test footprint, artifact index. |
| `critical-findings.md` | TOP-1…TOP-5 in full OBSERVATION / INTERPRETATION / IMPACT / ROOT CAUSE / RECOMMENDATION form with each validator classification; twelve hard defects with repro, cause and fix; every P0/P1 issue in a table; the zero-instruction test; the prioritized backlog. |
| `user-journey-map.md` | Journeys A–G as lived: timestamped paths with frames, the required questions answered by exact copy, USER ASSUMPTION / ACTUAL PRODUCT BEHAVIOR pairs, hesitation moments, per-journey verdicts, the cross-journey friction table. |
| `gameplay-loop.md` | The scored transition table (T1–T8: clarity / motivation / friction / payoff / information), the macro loop and its break points, screen-by-screen information hierarchy (web and iOS), the competition-visibility matrix, side games, the social pressure test. |
| `rules-and-mental-model-audit.md` | 46 competition rules scored on discover / understand / predict / explain / reinforce, the four priority tiers, the held vs intended mental model, the noun-by-noun break table, the ~120-term glossary, confusion debt by journey. |
| `retention-audit.md` | The retention lifecycle (Day 0 → season + 30), the emotional loop, "why would I start another season", the five retention questions, monetization readiness, the competitor mental model, what would be missed. |
| `issues.json` · `issues.csv` · `issues-counts.json` · `issues-README.md` | The master dataset (135 issues; schema, provenance and merge rules in `issues-README.md`); regenerated by `tools/merge_issues.py` from `raw/issues.first-pass.json`. |
| `synthesis-terminology.md` | ~97-row glossary; shipped strings that contradict logged decisions; never-defined terms. |
| `synthesis-rules-mental-model.md` | 45 rules scored (the base the 46-rule deliverable consolidates); six headline rule failures; explain-to-a-friend comparison. |
| `synthesis-loop-hierarchy.md` | Seven scored transitions; ~28 web + 11 iOS screens; competition visibility; intent-vs-shipped. |
| `synthesis-retention-monetization.md` | Lifecycle, emotional loop, social pressure, the five "why would I" questions, monetization readiness, competitors. |
| `synthesis-sidegames-setup.md` | Side-game discovery / understanding / effect / money / social; the organizer's path S0–S4 and P1–P7; league-vs-season; the D40 vs D96 conflict. |
| `synthesis-triage.md` | Top five, zero-instruction answer, 63 friction points, 48 confusion-debt items, severity re-check, backlog. |
| `raw/agent1-casual.md` … `raw/agent7-retention-observer.md`, `raw/ios-screen-survey.md` | The persona reports (run 2 overwrote run 1 for casual, competitive, skeptic and iOS; run-1 detail survives in `persona-results.json`). |
| `raw/agent6-new-joiner-attempt1-harness-artifact.md` | The joiner's first attempt; its "code never arrived" P0 is a **test-harness artifact** — only its door/Terms observations are evidence. |
| `raw/persona-results.json` | The 12 structured result rows (scores, verdicts, 30-second explanations, blockers, discovery answers, glossaries, issues). |
| `raw/synthesis-and-validation-results.json` | Triage output, the five synthesis summaries, the 15 validation verdicts. |
| `raw/issues.first-pass.json` | The 127-issue triage snapshot the merge script starts from. |
| `screenshots/` | 742 tester frames as `<session>/<frame>.jpg` (`org` organizer · `nov` novice · `obs` observer · `join` joiner · `cas` casual · `comp` competitive · `skep` skeptic · `ios`) plus the validator frames `v-TOP-{1,2,3i,4,5}/*.png`; documents cite them as `<session>/<frame>.png`. Git-ignored (`screenshots/.gitignore`, ~96 MB) — delete that file to commit them. |
| `tools/merge_issues.py`, `tools/collect_screenshots.py` | Rebuild the dataset; copy the frames out of the session scratchpad. |

## Personas and verdicts

Each persona answered its own key question with a 1–10 score. Where a persona ran twice the score reads run 1 / run 2.

| Persona | Who | Account | Key question | Score |
|---|---|---|---|---|
| A5 Organizer | "Casey Ortega", ~14, Phoenix; wants to run a season for six friends | +blind1 | Is creating and running a season simple enough that one person will actually do it? | **3** — "Not today … Fix the lock bug and add a real invite and this is a 7." |
| A3 League novice | "Dana Whitfield", ~18, Tempe; never in a league | +blind5 | Can this person create/join a season and understand the rules without outside instruction? | **4** — "Create — yes, barely, and the app told me I had failed." |
| A7 Mid-season observer | Existing member of two running leagues (2 players each), strict read-only | owner | I just finished a season — why would I start another? | **4** — "To beat Galen … the app never told me what winning would have meant." |
| A6 New joiner | "Marcus Bell", ~12, Chandler; invited by Casey | +blind2 | Can you understand what you are joining before accepting? | **3** — "No … I did not know who was in it (not even that Casey ran it)." |
| A1 Casual | "Jordan Reyes", Mesa; shoots 95–100, no handicap | +blind3 | Can a normal golfer understand this without becoming a golf-league nerd? | **5 / 4** — "Posting a score is genuinely easy … Understanding what the score did is not." |
| A2 Competitive | "Priya Nair", 6.4, TPC Scottsdale | +blind4 | Does Cup Season feel strategically compelling enough to care about all season? | **5 / 5** — "As shipped I'd play for the skins and shrug at the table." |
| A4 Skeptic | "Sam Kowalski", ~15; group text + spreadsheet + 18Birdies | +blind6 | Does Cup Season provide enough obvious value to justify changing behavior? | **4 / 3** — "The value that would justify switching … is the LEAST visible thing in the product." |
| iOS survey | First-time golfer reading the phone's landing screens (no taps) | owner | Looking only at the phone's screens, does Cup Season tell a first-time golfer what it is and why to care? | **4.5 / 4** — "They do not say what the game is." |

Verdict: **median 4/10**; mean 3.75 taking each family's latest run (4.0 across all 12 result rows).

## The ten executive-verdict scores

Each is the **median of all 12 result rows** in `raw/persona-results.json` (eight persona families; the four re-run personas contribute both runs). The method is stated once, in `blind-ux-audit.md` §1; companion documents that quote a *mean* use each family's latest run and say so.

| Question | Score /10 | Range |
|---|---|---|
| Easy to pick up? | **5** | 4–7 |
| Concept immediately understandable? | **5** | 4–7 |
| League setup understandable? | **4** | 3–6 (n=11; the read-only observer could not score it) |
| Rules understandable? | **4** | 3–5 |
| Gameplay compelling? | **6** | 4–7 |
| Side games compelling? | **6** | 4–8 (7–8 from everyone who ran one, 4–5 from those who only read about them) |
| Season creates meaningful stakes? | **6** | 3–6 (the only tester living a real season scored 3) |
| Would a user invite friends? | **4** | 3–6 |
| Would they play another season? | **6** | 4–7 |
| Would they pay for another year? | **3.5** | 2–5 |

## The five biggest problems

Same ids and titles in `blind-ux-audit.md` §2 and `critical-findings.md` Part 1; all five **Confirmed UX problem** on all three validation lenses.

- **TOP-1 — The organizer cannot finish: "Lock" reports failure after the server has already committed, and the invite never appears.** `index.html:15218` throws `staged is not defined` after the lock's four server writes commit; both organizers saw "Lock failed" six times; the only surface that prints the join URL never opens; prod telemetry: `lock_ok` = 1 all-time (pre-D97), `lock_fail` = 11; a hidden $75 default buy-in rides along. *Activation.*
- **TOP-2 — Nobody can tell what they are joining until after they have committed to $50.** A slogan door, a one-line invite landing, and a consent sheet with no roster, Pro, dates, scoring or payment path before "Join — I'm in for $50"; "Not now" loses the invite; the signed-in join path skips the covenant entirely. *Activation.*
- **TOP-3 — Members are handed the organizer's controls, and no next step.** Every player's Home hero is the Pro's "Lock it in and invite your crew" → the create-league wizard with a live lock button and a "discards it completely" cancel (only the server refused); one league's status is stated five ways; no member verb anywhere. *Engagement.*
- **TOP-4 — The first round contradicts itself: points promised, zero delivered, sign inverted, receipt stops short.** Six of six posters were promised "LEAGUE POINTS THIS ROUND 5/6/12" a week before first tee and got 0 with no sentence saying why; minus reads as good to golfers; three scoring engines and two definitions of "season"; the 95% allowance is shown and never seen acting. *Engagement — the core loop.*
- **TOP-5 — "How do I win?" is answered nowhere, and the money that rides on it has no way to be paid.** The Cup Final is one bylaw row four taps deep behind a collapsed admin panel; LOCKED / seed / "EVERYONE ADVANCES" / "GENEROUS CEILING" are undefined; the built foreshadow is sorted out of view on 154 of 155 days; ties are stated nowhere; the pot has no payee, method or deadline. *Retention → monetization.*

## The zero-instruction test

> If the developer disappeared and a new user downloaded Cup Season tomorrow, could that user run a season with five friends without asking another human how it works?

**Answer: NO.** The exact reasons, from evidence only (this block is identical in `blind-ux-audit.md` §14, `critical-findings.md` Part 4 and `README.md`):

1. **The organizer cannot complete setup and know it.** Both organizers saw "Lock failed" on every tap (`staged is not defined`, `index.html:15218`); one learned the league was live only by reloading; the post-lock share sheet never opened. (M-001)
2. **The five friends cannot be invited from the app.** No email/SMS invite exists; "Add golfers" finds only existing accounts; the join URL is never displayed — only a code in a vanishing toast. The organizer must text "download Cup Season, tap 'I have an invite code', type THEPTCQ5" — which is asking another human. (M-002, M-003)
3. **A friend who opens the link cannot tell what they are joining** before "Join — I'm in for $50" (no roster, Pro, dates, scoring or payment path) — so they text the organizer to ask. (M-023, M-024, M-025)
4. **Once in, every friend's Home hands them the organizer's lock button** and no member-facing next step. (M-030, M-033)
5. **Their first round promises 5/6/12 league points and delivers zero with no explanation**, described with three different signs; nobody could say what they earned. (M-040, M-045, M-044)
6. **Nobody can answer "how do we win."** The Cup Final, seeds, ties and the floor are undefined or contradictory in-product; the rules sit four taps deep behind a collapsed panel. Every persona said, in those words, that the organizer would explain it in the parking lot. (M-055, M-056, M-057, M-054)
7. **Money is a ledger nobody knows how to settle**, with a $75 default nobody chose. (M-110, M-004)

**What WOULD pass:** an already-formed, already-running league where members only post rounds and play live side games. The post form, course → tee → rating/slope autofill, the live bands, the receipt's differential arithmetic, the live scorer's stroke line ("Marco gets 4: holes 3, 6, 16, 18"), the running skins ledger, guest play without an account, and the settlement card were praised by every persona (side-game verdicts 7–8/10). The season wrapper around them — setup, invite, consent, status, endgame, money — is what fails the test.

---

## Test footprint and cleanup

Everything the audit wrote to prod sits inside the seven `+blind` accounts and the two audit leagues; the read-only observer and the iOS survey used the owner's real account and wrote nothing (DB check: 0 rounds, 0 posts; nothing touched Fellas or Who's the bitch?).

| Item | Detail |
|---|---|
| Accounts | `jerecho+blind1@fischbeck3.com` (Casey, Pro of The Papago Grind) · `+blind2` (Marcus) · `+blind3` (Jordan) · `+blind4` (Priya) · `+blind5` (Dana, Pro of Desert Dogs) · `+blind6` (Sam) · `+blind2x` (a diagnostic send during the joiner's first attempt; never signed in, but the OTP send created the `auth.users` row) |
| Leagues | **The Papago Grind** — code `THEPTCQ5`, Pro +blind1, members +blind2/3/4/6; phase `draft`, squads undrawn, $50 buy-in, first tee Sat Sep 5 2026. **Desert Dogs** — code `DESEUU0K`, +blind5 alone; the Solo retry rewrote it to phase `season` with two empty squads standing (a state §15 forbids; `delete_league` will refuse it because it is past `draft`) |
| Inside those leagues only | posted rounds (incl. the attested 93 / 89 / 103 Priya's live skins round wrote to Casey, Marcus and Jordan), a $5 match-play story with guest **Marco** (a name-only guest on a `live_round_players` row — no account, no profile), an 18-hole skins round and its settlement card, two pride stakes, tee-sheet entries for Sep 5, board chat lines, one buddy request (Priya → Casey) |
| Telemetry | `client_events` rows for the lock attempts (`lock_attempt` 12, `lock_fail` 11, 2026-08-29 13:32–13:34 UTC) — they cascade away with the profiles; query them first if you want to keep the evidence |

Cleanup SQL. Dry-run it first exactly as written (it ends in `rollback`), read the counts, then change the last line to `commit;`. Per CLAUDE.md the owner runs mutating SQL; `supabase db query --linked "$(cat cleanup.sql)"` works without Docker.

```sql
begin;

-- 0 · what is about to go
select email from auth.users where email like 'jerecho+blind%@fischbeck3.com';        -- expect 7 rows
select code, name, phase from public.leagues where code in ('THEPTCQ5','DESEUU0K');   -- expect 2 rows

-- 1 · references to test profiles that have NO on-delete clause and would block step 3
--     (courses.created_by, events.created_by, member_invites.invited_by — all almost certainly empty here)
update public.courses set created_by = null
 where created_by in (select id from public.profiles where email like 'jerecho+blind%@fischbeck3.com');
delete from public.member_invites
 where invited_by in (select id from public.profiles where email like 'jerecho+blind%@fischbeck3.com');
delete from public.events
 where created_by in (select id from public.profiles where email like 'jerecho+blind%@fischbeck3.com');

-- 2 · the two audit leagues. ON DELETE CASCADE takes league_members, league_settings, seasons (→ squads,
--     cup_finalists, season_adjustments), posts, buy_ins, invites, live_rounds (→ live_round_players incl.
--     guest "Marco", live_scores, game_results), forfeits (the pride stakes), commissioner_log, feedback;
--     scheduled_rounds, trophies and events keep their rows with league_id set null.
delete from public.leagues where code in ('THEPTCQ5','DESEUU0K');

-- 3 · the seven accounts. profiles_id_fkey is ON DELETE CASCADE, so profiles go with auth.users, and from
--     profiles: rounds (incl. the attested cards from the live skins game), round_holes, scheduled_rounds,
--     buddies / buddy requests, device_tokens, photos, client_events (the lock telemetry).
delete from auth.users where email like 'jerecho+blind%@fischbeck3.com';

-- 4 · nothing should remain
select count(*) from public.profiles where email like 'jerecho+blind%@fischbeck3.com';  -- 0
select count(*) from public.leagues  where code in ('THEPTCQ5','DESEUU0K');            -- 0

rollback;   -- → commit; once the counts read right
```

Also on the owner's account: a buddy request from Priya (+blind4) may sit in the owner's inbox if it was addressed there rather than to Casey — the reports say it went to Casey; if the `crew` list on the real account shows a `+blind` name after cleanup, that row cascaded with the profile and needs nothing.

## Caveats — what this audit could not see

- **No native share sheet or clipboard** in the headless browser: every "Share…" / "Copy…" outcome was judged on visible fallback feedback only. A real iPhone usually gets the OS share sheet first; the fallback the testers saw is still what a desktop or a denied-clipboard user sees, and no surface prints the join URL as text except the lock share sheet that never opens.
- **No in-season play could be observed**: both audit leagues' first tee is Sat Sep 5, a week out. Month closes, floors, squad scoring, the Cup Final, seeds and payouts were read about, not lived; every posted round in the audit is pre-season by construction — which is also the default first week of every new league.
- **No finished season exists on any account**; Journeys F and G (finale, next season) are partly inferred from what the live app says about endings and from what the code and decision log say is built (D41, D66, D67, D68, D105, D106 — built or proposed, none observable).
- **The owner's two real leagues have two players each**, which makes "biggest threat", "everyone advances" and LOCKED trivially true and the mid-season rivalry score partly an n=2 artifact.
- **The App Review sandbox was unavailable**; the iOS survey saw static landing screens via a developer launch hatch — no taps, no scroll; the Live screen's missing chrome may be the hatch bypassing a presenting container.
- **Three accounts were contaminated by earlier runs** (casual, competitive, skeptic); those agents signed out, redid the cold paths and flagged it; their sign-up screens are cited from the first run's frames.
- **Two harness artifacts are labelled wherever they appear and struck from every backlog**: the first joiner attempt's "code never arrived" P0 (Supabase recorded every send; the mail connector hid messages past the fifth in a thread — `M-163`, kept as P3 with a note) and "the You tab opens the wizard" (`M-031` — the driver's substring click on "You" hit "Lock it in and invite **You**r crew"; kept at its triage severity with a note so the counts stay reproducible).
- **`v23 · __CS_VERSION__` on the door** is the expected unstamped local build (CLAUDE.md rule 2); prod reads `v23 · 34d20b6`. Struck from the evidence.
- **Course search hit the third party's bad day** in one session (five 502s from the `courses` edge function for "TPC Scottsdale" / "Papago"; "Ken Mc" hit the cache); 502s on Post / Tee off / Finish / tee-sheet writes were logged by three personas and their endpoint was not identified.
- **"Scrap this round"** was dead in one session and a two-tap confirm in another — unresolved, flagged for reproduction (`M-090`). Whether a member's tap on the lock is refused server-side was not tested: nobody pressed it on the shared league.

## Editor's corrections (what the consistency pass changed)

Executive-verdict scores were recomputed from `raw/persona-results.json` and the stated method corrected (the numbers were already 12-row medians; the text had claimed a family-averaged method and an n=7 that is n=11); the verdict mean "3.9 (12 rows)" became 4.0, with 3.75 as the latest-run-per-family mean every companion document uses. The five problems now carry the same ids and titles (TOP-1…TOP-5) in `blind-ux-audit.md` and `critical-findings.md`. Issue counts everywhere now equal `issues-counts.json` (135 issues from 425 raw items; P0 7 · P1 44 · P2 65 · P3 19 — three documents still said 127 / 6·43·62·16 from the first triage pass), and the two appended hard defects got their ids (`M-159` blank date, `M-160` course search 502s) in every backlog and table. The zero-instruction answer is byte-identical in `blind-ux-audit.md` §14, `critical-findings.md` Part 4 and this file. The lock's committed writes are cited at the same lines everywhere (`:15127–15149`, `:15189–15196`, `:15203`, `:15211`, throw at `:15218`), the forming hero at `:10072–10116` (CTA `:10102`), the clipboard→auth misdiagnosis at `:4112`. Three "never" claims were checked against `index.html` and softened: Standings' NEXT UP card does carry a bare "Live round" button (`:3454`); the two-player heroes do name the only other player (`heroMyRung`, `:10189–10199`); "captains" do exist in the unbuilt draft's copy (`:2948–2958`). The install-banner cause no longer cites `.composer` (`:1354`) as the FAB. The rules deliverable's own tally is reconciled (46 rules, 45 flagged, 12 at 1–2; rulesClear mean 4.0 not 3.9). `M-031` gained a harness-artifact `note` in the dataset (and in `tools/merge_issues.py`, so a regen keeps it). The 742 tester frames and nine validator frames were copied into `screenshots/` and every "the folder is empty / copy before the scratchpad is reaped" line was replaced with the real path and extension. Each document now ends with a one-line pointer to the others.

---

*Companion documents in this folder: `blind-ux-audit.md` (master report) · `critical-findings.md` · `user-journey-map.md` · `gameplay-loop.md` · `rules-and-mental-model-audit.md` · `retention-audit.md` · `issues.json` / `issues.csv` / `issues-counts.json` (`issues-README.md`) · the six `synthesis-*.md` files · `raw/` · `screenshots/` · `tools/`.*
