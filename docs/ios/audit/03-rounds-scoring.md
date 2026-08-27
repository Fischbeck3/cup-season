# Audit slice 03 — Posting a round and everything that scores it

Read-only audit of the Cup Season web app (`/Users/fischbeck3/cup-season`) for the native iOS rebuild. All paths are repo-relative; line numbers are against `index.html` (17,767 lines) and the migrations as of commit `e0bd5a9` (branch `native/b1-scaffold`, 2026-08-27).

Canon cited: `spec/spec-v1.0.md` (§), `spec/decision-log.md` (D-numbers), `spec/photos-arc.md`, `spec/scheduled-rounds-arc.md`, `CLAUDE.md`.

---

## 0. The one-paragraph model

A **round is a fact that belongs to a profile** (`rounds`), stored as gross / rating / slope / nine_rating / date / `index_at_post`. A BEFORE INSERT trigger (`score_round()`) computes the **differential** and snapshots the index. Nothing else is stored about scoring. Every league is a **lens**: the view `v_rounds_ranked` fans each round into every league the profile belongs to whose season window contains `played_on`, applies that league's allowance % to the index, computes PvI, maps it through `cup_points()` bands, halves 9-hole points, and ranks the month (`month_rank`). `v_individual_standings` / `v_squad_standings` sum counting rounds (`month_rank <= counting_cap`) plus the `season_adjustments` ledger. `close_month()` (pg_cron, 1st of the month) assesses floors into that ledger. Rounds are **immutable** (§16); the only write after insert is `delete_round()` by the owner. The client inserts rounds **directly** (RLS `rounds_owner_insert`), not through an RPC — the one exception to CLAUDE.md's "game writes go through RPCs" rule, and it is load-bearing for native.

---

## 1. Screens & states inventory (web)

### 1.1 Entry: the Golf hub (`#view-record`, index.html:2958–2975)
Three option cards: **Post a round — after you play** (`data-go="post"`), **Play now — score the group live** (`#optLive`, out of this slice), **Plan a tee time — before** (`#optPlan` → `openDeclareSheet`, §1.9).

### 1.2 The post composer (`#view-post`, index.html:3097–3200; logic 6121–6520)
Markup, top to bottom:
- Eyebrow "Post a round · your index N" (static text — see landmine 7.12).
- `#inCourse` course search input + `#courseChips` (last 3 courses, `loadCourseMemory` 14092–14113; reads `rounds` for the user's last 30 labels).
- `#inRating` (number, step .1) / `#inSlope` (number) — always editable; prefilled by tee pick.
- "Your card" row: `#postMode` seg (**hidden by D34**, `display:none`, still wired) and `#postSide` seg **18 holes / 9 holes** (D72, always visible).
- `#postHolesWrap` (hidden unless `state.post.mode==='holes'`): `#postHoleGridF` / `#postHoleGridB` — 9-cell `.pgrid` per side, each `.pcell` shows `N · P<par>`, a `−` button, the score, a `+` button; cells colour by `eag`/`bird`/`bog` vs par (renderPostHoles 6131–6162). Link `#postSetPars` → `openPostParsSheet` (6272–6323): two 9-digit strings (3–6 only), validates each side, resets scores to pars. Link `#postScanBack` "Scrap the scan — type front & back instead".
- `#postTotalWrap` (default): `#inF9` "Front 9 gross" + `#inB9` "Back 9 gross" (9-hole side hides B9 and relabels F9 "9-hole gross").
- `#inDate` (date input; empty = server default `current_date`).
- `#postPhotoRow` (real accounts only): `#postScanBtn` "Scan the card" (flag-gated, `capture="environment"` file input `#postScanFile`), `#postPhotoBtn` "Add a photo" (`#postPhotoFile`), `#postPhotoClear`; preview `#postPhotoPrev`.
- `#postGrossLine` live readout ("Gross 84 · 18 holes" / "Enter your card to see the score.").
- `#postBtn` "Post round"; `#postReset` "Start over — clear this card".
- Right column "How this round scores" (`.calc`, aria-live): `#calcPts` (big), `#calcMsg`, `#calcGross`, `#calcVs` "vs your index", and a static **Point bands** table (3187–3197).

State machine (`state.post`, declared 6119): `{ mode:'total'|'holes', side:18|9, pars[18], scores[18], touched, rating9, parsCourse, photo, scan }`.

States:
- **Empty**: calc shows `–`, msg "Enter at least one nine to see the points." (recalc 6193–6198).
- **Live preview**: `recalc()` (6163–6208) recomputes on every input; uses `state.myIndex` at **100% allowance** (landmine 7.3).
- **Even-par guard** (F2): in holes mode with `touched=false`, Post opens a sheet "Post as even par?" with "Enter my card" / "Post even par anyway" (6325–6337; telemetry `post_even_par_confirmed`).
- **Submitting**: `#postBtn.disabled=true` (6348); photo uploads first; insert with two deploy-skew retries (6378–6388).
- **Error**: `toast(humanError(e,'Post failed.'))` (6499); button re-enabled.
- **Success**: sets `window._sfRid` (split-flap arrival), writes `round_holes` best-effort (6396–6401), emits `post_submit` + `scan_post` breadcrumbs, clears the form, resets to total/18, clears the localStorage draft, reloads standings/career/home, `switchView('home')`, then **finishCeremony** (6040–6084: full-screen dusk curtain: course · date eyebrow, serif gross, `vsPhrase` band line, `+N PTS · COUNTS FOR <SQUAD>` in gold only if the date falls inside the season window, else "COUNTS ON YOUR CARD"; Share button → `shareRecapCard`), then either **scanPartnersSheet** (if the scan carried other rows) or **showEpilogue** (5959–6020: band + points + counting rank, achievements this round earned, rivalry records, first-round welcome, "Share the card" / "Share a link — no account needed" / revoke).
- **Draft restore**: `savePostDraft`/`restorePostDraft` (6217–6270) mirror the typed card to `localStorage.cs_post_draft` (24h TTL) because iOS evicts the PWA when the camera opens; toast "Your unposted round came back". Photo blob does not survive.
- **Demo path** (6501–6519): pushes a fake feed row; never touches the DB.

### 1.3 Course search + tee pick (`attachCourseSearch`, 6729–6862; post wiring 6863–6902)
Two-stage dropdown (`.coursedd`): type ≥3 chars → 320ms debounce → **cache first** (`api_courses` ilike on club/course name, joined tees, 12 rows; 6784–6795) painted immediately → then `functions.invoke('courses',{action:'search',q})` merged in (6803–6812). Pick a course → tee list (`Rating X · Slope Y`, women's tees tagged; "No rated tees listed — type the rating and slope by hand"). Pick a tee → fills rating/slope, stamps `input.dataset.courseId`, fires `courses {action:'cache', id}` in the background, toast "Tees set — rating and slope filled". States: no match → "No match — type the course, rating and slope by hand."; API down but cache hit → cache stands; both empty → dropdown hides. Keyboard nav (arrows/Enter/Escape) added S6-06.
Post-specific `onTee` (6863–6902): if `tee.number_of_holes===9` → side=9 and `rating9=true`; on a **course change** resets pars to `POST_PAR_STD`; awaits the cache call, reads `api_course_tees` → `api_course_holes` for the picked tee, loads real pars into the grid (9-hole tee fills front nine only).

### 1.4 Scorecard scan (6579–6692)
- `loadScanFlag()` reads `app_flags.scan`; button hidden when no row or `enabled===false` (fail closed).
- Tap → camera → `compressPhoto(f,2200,.9)` → base64 → `functions.invoke('scan')`. Button text "Reading the card…".
- Responses: `unavailable` (`daily_cap` → "Scan limit for today — type your nines in"; `disabled` also hides the button; anything else "Scan's resting — type your nines in"); no players → "Couldn't read the card — type your nines in".
- `scanPickRow` (6620–6631): if >1 player row, sheet "Whose card is this? — TAP YOUR ROW" listing name, total, `holes_read/18`.
- `scanApply` (6632–6657): flips mode to `holes` programmatically (grid becomes the confirm surface), side from whether holes 10–18 have values, pars from `par_row` if ≥9 valid, unreadable cells (0) default to par, `touched=true`, course name fills if empty, **the card's written date overrides today**, the scan photo becomes the round photo; toast "Card read — N holes I couldn't make out are set to par".
- After post: `scanPartnersSheet` (6658–6692) mints `create_scan_claim` per partner row → copies `${origin}/?claim=<token>` to clipboard.

### 1.5 Round photo (6521–6578)
Client-side compress to ≤1600px JPEG q.82 (`createImageBitmap` with resize, `<img>` fallback for HEIC on Safari). Upload to private bucket `media` at `${uid}/${uuid}.jpg` before the insert; failed upload → "Photo didn't stick — posting the round without it" and the round posts photo-less.

### 1.6 The round receipt sheet (`openRoundReceipt` 11392–11418, `roundCardBody` 11317–11362, `enrichRoundReceipt` 11363–11391)
Opened from the board story card, Home feed rows (`wireFeedReceipts` 10616–10627), the You tab recent list, and the album. Opens **instantly** with whatever the caller held, then enriches via `round_card(p_round)`. Rows: "The course 64.9 / 111" · arithmetic row `86 − 64.9 × 113 ⁄ 111 → 21.5 DIFFERENTIAL` · "Your/Their number that day" · "Against your number +X — BAND" · Points · "This month COUNTING #n / BUMPED" · "Nine holes HALF VALUE · HALF A ROUND" · "Attested PLAYED WITH THE GROUP" · "Played with …" · "See the scorecard" (when `live_round_id`). Photo hero with marker medallion (`.mkstamp`), signed on demand (1h). Header title "<gross> gross", sub "COURSE · 18 HOLES · DATE". Fallback copy "somewhere out there" when no course (D95 traced this to a field-name mismatch: `home_feed` returns `course`, receipt read `course_label` — aliased at 11395).

### 1.7 Round cards on the board (`renderFeedFull` 5230–5275; compact feed `digestRoundLine` 5036–5046)
Story card per `kind='round'` post with `round_id`: face + name, `course · N holes · date`, `<gross> GROSS · <BAND>` (third-person `theirs()` for others), counting line (`COUNTING #n THIS MONTH` / `BUMPED — OUTSIDE THE BEST 4 THIS MONTH` / `PRE-SEASON · NOT COUNTING` when `month_rank` is null), streak tag `N STRAIGHT UNDER` (D76, walked off `roundCache`), PvI chip `+1.4`, points badge, photo as background with dusk wash, social bar. Data: `window.roundCache` built in `loadStandingsAndFeed` (14426–14468) from `rounds` + `v_rounds_ranked` (season-scoped) + batched signed URLs.

### 1.8 Home feed round rows (`feedRow` 10247–10296; data `home_feed` RPC via `loadHome` 16510–16540)
Two shapes: photo story card (`.hfstory`) and rail card (`.hfrail`). Name ("You" for self), milestone (`🔥 Personal best` / `⛳ Broke 80 — first time` / `🎉 First round on the card`) or `vsPhrase`, gross, `course · date`, reactions. Whole card opens the receipt.

### 1.9 Stats / insight surfaces (detail in §9)
- Home stats strip (3425–3444): Season week, pot, **Your index** (`#statIdx`, "Building your number · n of 3" until established; mint ring animation when it first becomes a number), **Counting rounds** fill-meter (`#statCount`, dots per cap slot), month pressure meter (`#pressMeter`), "Next up" card (`#nextTxt`). Logic `renderStats` 9406–9520.
- You tab (2843–2882): FORM row (`formRowHtml`, last 5 dots, "N STRAIGHT UNDER"), career record card (`renderCareerRecord` 11103–11133), four tiles Rounds posted / Best vs index / Avg vs index / Cups & events, recent rounds list with photo + delete × (`renderCareer` 11152–11194).
- League individual table (`renderIndStatsReal` 11250–11296): R / Avg vs index / Pts; award tiles Points King / Most Improved / Iron Man; tap → `openMemberHist` (11300–11312: counting vs BUMPED rows).
- Squad receipt (`showSquadReal` 11607–11630): Counting rounds + ledger net + Total, roster.
- Tour Card (`openTourCard` 13293–13400): index, trophies, form, vs-you record, Career (Rounds / Best diff / Avg vs index / home course / GHIN), Recent rounds (5).
- Season album (`renderAlbum` 16456–16505): league round photos grid, month dividers, tap → receipt.

### 1.10 Scheduled rounds (built; `spec/scheduled-rounds-arc.md`)
- `openDeclareSheet` (16670–16724): day (default next Saturday), tee time, course (same search; stamps `course_id`), note (≤140), tag chips; RPC `declare_round` with `p_course_id` skew-retry.
- `openRoundSheet` / `renderRoundSheet` (16733–16837): course header from cache (tee · rating/slope · PAR) or typed label; tee chip; weather chip `#rsWx` (`loadRoundWeather` 16839–16850: hides on any miss); RSVP list + In/Maybe/Can't (only host or tagged, D69); comments thread; Edit group / Cancel round (owner).
- Home "Coming up" cards (`homeRoundCard` 10682, `fillHomeWeather` 10720).

### 1.11 Delete a round
You tab recent list × → `confirm('Delete this round? It leaves your card and any league standings it counted toward.')` → `delete_round` RPC → reload career/standings/home (11178–11192).

### 1.12 Claim funnel (`claimPendingRound` 17588–17632; door card in `safeBoot` 17690–17720)
`/?claim=<token>` → stored in `localStorage.cs_claim` → after sign-in + golfer card, tries `claim_round` (live guest) then `claim_scan_round`; door copy "<name> — 84 at <course>, Sat Jul 25. Enter your email to keep it." via `claim_round_info` / `scan_claim_info` (anon).

---

## 2. RPC / endpoint table

All from `packages/db/contract.psv` unless noted; "role" = execute grant. Migration = where the current body lives.

| Name | Args | Returns | Role | Migration | Notes |
|---|---|---|---|---|---|
| **(direct insert) `rounds`** | row: gross, rating, slope, nine_rating, holes_played, source, played_on, course_label, api_course_id, season_id, photo_path | id | RLS `rounds_owner_insert` (profile_id = auth.uid(), defaulted by trigger) | baseline:2280 | index.html:6350–6388. Not an RPC. |
| **(direct insert) `round_holes`** | round_id, hole_number 1–18, strokes 1–15 | — | RLS `rholes_add` (owner of round) | baseline:2261 | best-effort after the round insert (6396–6401) |
| `score_round()` trigger | — | trigger BEFORE INSERT on rounds | definer | `20260716100000` | differential + index snapshot (§5.1) |
| `score_round(p_gross,p_rating,p_slope,p_nine_rating,p_index,p_allowance,p_holes)` | 7 args | TABLE(o_diff,o_pvi,o_points) | invoker, auth | baseline:692 | **Orphan**: pure-SQL calculator, unused since `20260711190000` repointed the trigger. Handy as a native unit-test oracle. |
| `cup_points(p_pvi)` | numeric | int | invoker, auth | baseline:247 | the bands (§5.2) |
| `round_refresh_index()` trigger | — | AFTER INSERT | definer | `20260716120000` | recomputes `profiles.index_current` from scores once ≥3 rounds; announces the starter→engine handoff |
| `round_to_board()` trigger | — | AFTER INSERT | definer | `20260727160000` (board_voice) | fans a `kind='round'` post to every active/cup_final season containing `played_on` |
| `round_moments()` trigger | — | AFTER INSERT | definer | `20260722100000` | one headline: barrier > PB > streak; also writes `achievements` |
| `round_duel_nudge()`, `round_major_story()`, `squad_lead_moments()` | — | AFTER INSERT triggers | definer | events/majors migrations | out of slice; fire on every round insert |
| `rounds_no_future()` trigger | — | BEFORE INSERT/UPDATE | invoker | `20260718174500` | `played_on > current_date + 1` → exception |
| `delete_round(p_round)` | uuid | void | definer, auth | `20260715170000` | `delete … where profile_id = auth.uid()`; cascades round_holes, posts(round_id), attestations |
| `round_card(p_round)` | uuid | jsonb | definer, auth | `20260729180000` | the receipt read (§1.6); guard: yours or shared-league |
| `round_epilogue(p_round)` | uuid | jsonb | definer, auth | `20260716200000` | owner-only: pvi/points/month_rank (under `rounds.season_id`), achievements this round, rivals this week |
| `home_feed(p_days=21)` | int | TABLE(round_id, profile_id, golfer, marker, handle, gross, pvi, played_on, created_at, course, is_pr, is_first, is_sub80, is_me, photo_path) | definer, auth | `20260723090000` | circle = self + buddies + league-mates + event-mates; **pvi at 100% allowance** (`index_at_post − differential`) |
| `league_pulse(p_league)` | uuid | TABLE(profile_id, display_name, marker, credits, floor, at_floor, is_me, partial) | definer, auth | `20260716040000` | this month's floor credits per member; `partial` = edge month |
| `tour_card(p_profile)` | uuid | jsonb {visible, profile, career{rounds,best,avg_pvi}, trophies, recent[5]{…,beat}, vs_you} | definer, auth | `20260726190000` | visibility fence: self / buddy / league-mate / event-mate / discoverable=everyone |
| `career_record()` | — | jsonb {cups, runner_ups, crowns, majors, events, trophies, earnings_cents, seasons_done, leagues} | definer, auth | `20260725100000` | exact sums of `trophies` + `season_payouts` |
| `handicap_index(p_profile)` | uuid | numeric | definer, auth | `20260716100000` | WHS-lite (§5.3) |
| `handicap_index_asof(p_profile,p_before_date,p_before_id)` | | numeric | definer, auth | `20260716100000` | same, before a given round |
| `set_index(p_index)` | numeric −10..54 | void | definer, auth | `20260716120000` | **refuses** once established (≥3 rounds); sets `index_source='self'`; posts a board line |
| `set_member_index(p_member,p_index)` | | void | definer, auth | `20260716120000` | Pro's starter tool, same refusal |
| `close_month(p_season,p_month)` | uuid, date | void | definer, auth | `20260716180000` | §5.6; idempotent via `month_closed` sentinel |
| `run_month_closes()` | — | void | definer, none (cron) | baseline:630 | loops active/cup_final seasons, closes previous month |
| `set_member_bye(p_member,p_month,p_on)` | | void | definer, auth | `20260716180000` | Pro grant/revoke; one bye per season |
| `create_scan_claim(p_name,p_gross,p_strokes,p_course,p_rating,p_slope,p_played,p_holes=18)` | | uuid token | definer, auth | `20260718045514` | 8/day cap per creator |
| `scan_claim_info(p_token)` | uuid | jsonb {guest_name, gross, course_label, played_on, claimed} | definer, **anon**+auth | `20260718045514` | door card |
| `claim_scan_round(p_token)` | uuid | jsonb {claimed, posted, gross?, already?} | definer, auth | `20260718045514` | inserts `rounds` (source `scan_claim`) + `round_holes` on the claimer's profile |
| `claim_round_info` / `claim_round` | uuid | jsonb | anon / auth | `20260716140000` | live-guest twin of the above (live slice) |
| `declare_round(p_play_on,p_course,p_note,p_tagged,p_tee,p_course_id)` | | uuid | definer, auth | `20260718192400` | future date only (today..+365), note ≤140 |
| `round_detail(p_round)` | uuid | jsonb {…, course{name,city,state,lat,lon,rating,slope,par,tee}, rsvp[], comments[], my_rsvp} | definer, auth | `20260718192400` | gated by `can_see_round` |
| `my_schedule(p_from,p_to)` | dates | TABLE(…, course_id, rsvp_in, my_rsvp, comment_n) | definer, auth | `20260718192400` | |
| `set_round_rsvp(p_round,p_status)` | uuid, 'in'|'maybe'|'out' | void | definer, auth | `20260725160000` (D69) | host or tagged only |
| `add_round_comment(p_round,p_body)` | | void | definer, auth | `20260718192400` | ≤500 chars |
| `scratch_round(p_id)`, `retag_round(p_id,p_tagged)` | | void | definer, auth | `20260712150000`/`20260712190000` | |
| `live_round_card(p_live_round)` | uuid | jsonb {round, players[{strokes[18]}]} | definer, auth | `20260729120000` (D92) | the only hole-by-hole read surface |
| `my_visitor_rounds()` | — | jsonb | definer, auth | `20260728220000` | live slice |
| **Edge `courses`** | POST `{action:'search',q}` / `{action:'cache',id}` | `{courses:[{id,club_name,course_name,city,state,tees[…]}]}` / `{ok,id,from_cache}` | signed-in user JWT (anon key rejected) | `supabase/functions/courses/index.ts` | GolfCourseAPI key server-side; `app_flags.courses.daily_per_user` (default 150) via `courses_usage` ledger; serve-always cache, 180-day background refresh |
| **Edge `scan`** | POST `{image:b64, media_type}` | `{ok, scan:{course_name,date,par_row[18],players[≤6]{name,holes[18],total,holes_sum,holes_read}}}` or `{unavailable, reason}` (HTTP 200) | signed-in user | `supabase/functions/scan/index.ts` | model `claude-opus-4-8`, structured output; caps in `app_flags.scan` (enabled, daily_per_user 5, monthly_global 400); reserve-then-count in `scan_usage` |
| **Edge `weather`** | POST `{lat?,lon?,date,course_id?}` | `{ok, weather:{hi,lo,wind,summary,icon}}` or `{unavailable,reason}` | signed-in user | `supabase/functions/weather/index.ts` | Open-Meteo, keyless; today..+16d; `weather_cache` 6h |
| Storage `media` bucket | upload `{uid}/*.jpg`; `createSignedUrl(s)` 1h | | auth; insert/delete own prefix; read via `can_see_media` (`20260718173100`) | `20260718045514` | photos |

Tables read directly by the client (RLS): `rounds` (own + shared-league), `round_holes` (RLS is broken for most rounds — §7.6), `v_rounds_ranked`, `v_individual_standings`, `v_squad_standings`, `standings_snapshots`, `api_courses` / `api_course_tees` / `api_course_holes` (auth read), `app_flags` (auth read), `client_events` (insert).

---

## 3. Data model

### 3.1 `rounds` (baseline:1244 + later columns)
| column | type | notes |
|---|---|---|
| id | uuid pk | |
| profile_id | uuid | owner; trigger defaults to `auth.uid()` |
| season_id | uuid null, FK seasons ON DELETE SET NULL (`20260718173100` L6) | **client-supplied only** (`CS.season?.id`); every server-side insert leaves it NULL (D92 debt). Only consumers: `round_epilogue`, `rholes_read` RLS. Not used by scoring. |
| live_round_id | uuid null | set by `finish_live_round` |
| course_id | uuid null | legacy `courses` uuid schema — dead |
| api_course_id | text null, **no FK** (`20260714050000`) | soft link to `api_courses.id`; client stamps from tee pick |
| tee_id | uuid null | live rounds only |
| course_label | text NOT NULL | free text; client sends `null` when empty → insert would fail NOT NULL (see 7.13) |
| played_on | date NOT NULL default current_date | `rounds_no_future`: ≤ today+1 |
| holes_played | int 9\|18 | |
| gross | int 18..200 | |
| rating | numeric(4,1) NOT NULL, CHECK 25..90 (NOT VALID) | **always the 18-hole rating** by convention; for a real 9-hole tee the client sends the tee's 9-hole rating here AND in nine_rating (D72 nuance — see 7.4) |
| slope | int NOT NULL, CHECK 55..155 (NOT VALID) | |
| nine_rating | numeric(4,1) null | the 9-hole rating actually scored against |
| index_at_post | numeric(4,1) NOT NULL | snapshot; resolved by trigger (§5.1) |
| differential | numeric(5,1) | computed by trigger |
| source | text CHECK in ('quick','live','scan_claim') | `'sim'` is referenced by views/engine but **cannot be inserted** |
| attested | bool default false | only `finish_live_round` sets true |
| voided | bool default false | nothing in the client/RPCs sets it; views honour it |
| index_source_at_post | text 'self'\|'app'\|'ghin' default 'self' | client never sets it (always 'self' on quick posts); live inserts write 'app' |
| photo_path | text null (`20260718045514`) | `media/{uid}/{uuid}.jpg` |
| created_at | timestamptz | |

Indexes/RLS: `rounds_read` = own OR shares a league (baseline:2288); `rounds_owner_insert`; `rounds_owner_update` **dropped** (D37 `20260718172300`); no delete policy (delete only via `delete_round`).

### 3.2 `round_holes` (baseline:1232) — `round_id` FK CASCADE, `hole_number` 1..18, `strokes` 1..15, PK (round_id, hole_number). No par/SI stored — par comes from the course cache or `live_rounds.course_snapshot`.

### 3.3 `league_settings` (baseline:1073) — the dials scoring reads: `handicap_allowance` (90|95|100, default 95), `counting_cap` (null = unlimited; wizard maps 2/4/6), `participation_floor` 0..4 (default 2), `floor_penalty` none|deduct|forfeit, `season_format` points|h2h|hybrid (D48 retired h2h/hybrid; `close_month` still honours 'hybrid'), `sim_rounds_allowed`, `nine_hole_allowed`, `preset`, `locked_at`.

### 3.4 `season_adjustments` (baseline:1275; kinds widened `20260718172300`): kind ∈ floor_penalty | floor_forfeit | matchup_bonus | bye | override | month_closed; `points`, `reason`, `member_id`, `squad_id`, `month`, `created_by` (null = system).

### 3.5 Views (baseline only — never redefined)
- `v_rounds_ranked` (1347): per (round × league membership × season whose window contains played_on, status active|cup_final|complete), `playing_index`, `pvi`, `points`, `floor_credit`, `month_rank` = `row_number() over (partition by member_id, season_id, month(played_on) order by points desc, pvi desc, played_on desc)`. Filters: `not voided`, sim rule, `nine_hole_allowed or holes=18`.
- `v_individual_standings` (1396): per member×season: `points` = Σ points where `month_rank <= coalesce(counting_cap,999)`, `rounds_posted` = count.
- `v_squad_standings` (1411): Σ counting points over squad members + Σ `season_adjustments.points` where `squad_id` not null.

### 3.6 Course cache: `api_courses` (id text = GolfCourseAPI id, club_name, course_name, city, state, country, latitude, longitude, raw jsonb, cached_at), `api_course_tees` (id uuid, course_id, gender, tee_name, course_rating, slope_rating, bogey_rating, par_total, total_yards, number_of_holes; unique (course_id, gender, tee_name)), `api_course_holes` (tee_id, hole_number, par, yardage, handicap=SI). Legacy `courses`/`course_tees`/`course_holes` (uuid) are dead weight (`20260714050000` explains the collision).

### 3.7 Scan/photos: `app_flags` (key, value jsonb; rows `scan`, `courses`), `scan_usage` (service-role only), `scan_claims` (token, created_by, guest_name, course_label, rating, slope, played_on, gross, strokes jsonb[18], holes_played, claimed_profile), storage bucket `media` (private).

### 3.8 Derived/memory: `achievements` (profile_id, kind unique per profile, label, earned_on, round_id SET NULL, meta), `attestations` (round_id, attested_by text, is_member), `posts` (`round_id` FK CASCADE, `live_round_id`), `standings_snapshots` (weekly), `season_lead`.

### 3.9 Scheduled rounds: `scheduled_rounds` (profile_id, play_on, course_label, note, tee_time, tagged uuid[], course_id text FK api_courses, league_id), `round_rsvp`, `round_comments`, `weather_cache` (course_id, play_on, lat, lon, payload, fetched_at).

### 3.10 Profile fields in play: `profiles.index_current` (numeric, null until established or a starter is set), `index_source` ('app'|'self'|'ghin'), `ghin_number`, `home_course`. `league_members.index_current` exists (seeded at join with `coalesce(profile.index_current, 18.0)`) but **scoring never reads it**.

---

## 4. The scoring pipeline, tap to standings

1. **Tap Post** (`#postBtn`, 6325). Preconditions: `state.lastPost` non-null (at least one nine), even-par guard passed if in holes mode.
2. **Client assembles the payload** (6350–6366): `gross` = f9+b9 or the single nine; `rating` (18-hole field); `nine_rating` = `rating` if `rating9` else `rating/2` for a 9-hole post, else null; `slope`; `holes_played`; `source:'quick'`; `played_on` (or null → server today); `course_label`; `api_course_id`; `season_id = CS.season?.id`.
3. **Photo upload** (6367–6377) to `media/{uid}/{uuid}.jpg`; path rides as `photo_path`.
4. **`insert into rounds`** via PostgREST; RLS `rounds_owner_insert` requires `profile_id = auth.uid()` (the trigger fills it in). Skew retries drop `api_course_id` / `photo_path` on a column error.
5. **BEFORE INSERT `rounds_no_future`** rejects `played_on > today+1`.
6. **BEFORE INSERT `score_round()`** (`20260716100000`): differential (§5.1); `index_at_post` := caller-provided → `profiles.index_current` → `handicap_index_asof(profile, played_on, id)` → **this round's own differential** (first-round provisional). Never 18.
7. **AFTER INSERT `round_refresh_index`** (`20260716120000`): if `handicap_index(profile)` is non-null (≥3 real rounds) → `profiles.index_current := it`, `index_source := 'app'`; posts "X'S NUMBER NOW COMES FROM THEIR SCORES — a → b" the first time it overrides a self/ghin starter and the number moved.
8. **AFTER INSERT `round_to_board`** (`20260727160000`): one `posts` row (`kind='round'`, `round_id`, `member_id`) per league where the golfer is a member AND a season is active/cup_final AND `played_on` is inside `[starts_on, ends_on]`. Body: "Jerecho posted 84 for nine at Papago." A round outside every window produces **no board post** (it still exists on the card).
9. **AFTER INSERT `round_moments`** (`20260722100000`): headline (barrier 80/90/100 > personal-best differential > iron-man streak at 4/8/12 weeks), posts `kind='moment'` with `round_id`, writes `achievements` (first_round, sub_100/90/80, personal_best evolves, streak_N). Also `squad_lead_moments`, `round_duel_nudge`, `round_major_story` fire.
10. **Client writes `round_holes`** (holes mode only; 6396–6401) — after the round exists, best-effort, never blocks.
11. **Views recompute on read.** `v_rounds_ranked` fans the row into every qualifying (league, season): `playing_index = round(index_at_post × allowance/100, 1)`, `pvi = round(playing_index − differential, 1)`, `points = cup_points(pvi)` (ceil(/2) for nine), `floor_credit` 1.0/0.5, `month_rank` within (member, season, calendar month of played_on).
12. **Standings**: `v_individual_standings` sums `month_rank <= counting_cap`; `v_squad_standings` adds the ledger. A new better round displaces the worst counting round instantly (§3.1) — nothing is stored, ranks shift on the next read.
13. **Client post-flow**: `round_epilogue` (owner: pvi/points/month_rank under `rounds.season_id`, achievements by `round_id`, rivals this week) → ceremony/epilogue sheets → share card / share link.
14. **Month close** (pg_cron `run_month_closes`, 1st ~00:10 Phoenix): `close_month(season, prev_month)` — floor credits vs `participation_floor`, auto-bye on first miss (D14), `-5 × ceil(short)` deduct or forfeit of counting points, `month_closed` sentinel, board post "JULY CLOSED — LEDGER POSTED". Floors waived when the month is partial (§14.0).
15. **Receipts** (§16): `round_card` re-reads the same view row (`points`, `month_rank`, `playing_index`, `pvi`) plus the stored inputs — the screen and the standings share one source.

---

## 5. Formulas (as they exist in SQL)

### 5.1 Differential — `score_round()` trigger, `20260716100000`
```sql
if new.holes_played = 9 and new.nine_rating is not null then
  new.differential := round(((new.gross - new.nine_rating) * 113.0 / new.slope) * 2, 1);
else
  new.differential := round((new.gross - new.rating) * 113.0 / new.slope, 1);
end if;
-- index snapshot
if new.index_at_post is null then select index_current into new.index_at_post from profiles where id = new.profile_id; end if;
if new.index_at_post is null then new.index_at_post := handicap_index_asof(new.profile_id, new.played_on, new.id); end if;
new.index_at_post := coalesce(new.index_at_post, new.differential);
```
Note: a 9-hole round with `nine_rating` NULL scores against the **18-hole rating undoubled** — the client always sends `nine_rating` for nines, `claim_scan_round` sends `rating/2`, `finish_live_round` skips the card if no nine rating. No adjusted-gross / net-double-bogey capping anywhere (D32 confirms: scoring reads gross only).

### 5.2 PvI and points — `v_rounds_ranked` (baseline:1347) + `cup_points` (baseline:247)
```sql
playing_index = round(index_at_post * handicap_allowance / 100.0, 1)
pvi           = round(index_at_post * handicap_allowance / 100.0 - differential, 1)
cup_points(p) = case when p >= 3 then 12 when p >= 1 then 9 when p > -1 then 7 when p >= -3 then 6 else 5 end
points        = holes_played = 9 ? ceil(cup_points(pvi) / 2.0) :: int  -- 12→6, 9→5, 7→4, 6→3, 5→3
                                  : cup_points(pvi)
floor_credit  = holes_played = 9 ? 0.5 : 1.0
month_rank    = row_number() over (partition by member_id, season_id, date_trunc('month', played_on)
                                   order by points desc, pvi desc, played_on desc)
```
Band edges (spec §2.2 vs code): spec says "−0.9 to +0.9 = 7" and "−3.0 to −1.0 = 6"; code's `cup_points` uses `p > -1` for 7 so **exactly −1.0 scores 6**, and the orphan 7-arg `score_round` uses `>= -1` (7). The client `pointsFor`/`bandName` (5566–5579) use `>= -1` (7). At one decimal this only bites at pvi = −1.0 exactly — native must pick the server's rule (`cup_points`) and the receipts will agree.

### 5.3 Handicap index — `handicap_index_asof` (`20260716100000`)
Last 20 non-voided, non-sim differentials (ordered played_on desc, id desc, strictly before the given round when provided). With `c` = count:
```
c < 3  → NULL (not established)
m (how many best to average): c≤5→1, ≤8→2, ≤11→3, ≤14→4, ≤16→5, 17→6, 18→7, else 8
adj: c=3→2.0, c=4→1.0, c=6→1.0, c∈{9,10,11}→1.0, else 0
index = round(avg(lowest m differentials) − adj, 1)
```
(WHS-lite; the official table's c=3/4/5 adjustments are −2.0/−1.0/0 — matched; the c=6 −1.0 and c=9–11 −1.0 are the WHS table's "−1" rows.) No soft/hard caps, no exceptional-score reduction, no PCC. Starter (manual) index: `set_index`/`set_member_index` only allowed while `handicap_index()` is NULL; range −10..54; source 'self'.

### 5.4 Client preview — `recalc()` (6163–6208)
```js
18: diff = (gross − rating) × 113 / slope;              vs = state.myIndex − diff
 9: rating9 = state.post.rating9 ? rating : rating/2;  diff = ((g9 − rating9) × 113 / slope) × 2; vs = state.myIndex − diff; pts = ceil(pointsFor(vs)/2)
```
Uses `state.myIndex` (profile index or member index, `|| 18` fallback at 14872) at **100% allowance** — differs from the server whenever the league allowance is 95/90 (7.3).

### 5.5 Career aggregates
- `tour_card.career`: `rounds = count(*)`, `best = min(differential)`, `avg_pvi = round(avg(index_at_post − differential), 1)` (100% allowance, global across leagues; excludes voided/sim).
- `tour_card.recent[].beat = (index_at_post − differential) >= 1` (D76 form).
- Client `loadCareer` (16409–16449): `best = max(index_at_post − differential)` (**a PvI**, whereas the server's `best` is the **lowest differential** — same word, different quantity, see 9.3), `avg` = mean PvI, `played` = memberships + events.
- `indRows` (14494–14508): per member, `avg` = mean of `v_rounds_ranked.pvi` this season, `best` = max pvi, `d` = last `index_at_post` − first `index_at_post` (Most Improved = most negative `d` ≤ −0.05).
- `myMonth` (14510–14513): `credits` = Σ floor_credit, `counting` = count(month_rank ≤ cap) for rounds whose `played_on` starts with the **device's** current `YYYY-MM`.
- `myIndexDelta` (14514–14516): `profile.index_current − first index_at_post this season`.

### 5.6 Month close — `close_month` (`20260716180000`)
```
is_partial = season.starts_on > p_month OR season.ends_on < last_day(p_month)
for each squad member (skip if a 'bye' row exists for this month):
  credits = Σ floor_credit (this season, this month); counting_pts = Σ points where month_rank ≤ cap
  short = greatest(0, floor − credits)
  if short > 0 and floor > 0 and penalty in (deduct, forfeit) and not is_partial:
    if no 'bye' row for this member this season → insert bye (0 pts) + post "X'S BYE KICKED IN…"   -- D14 auto-bye
    elif deduct → insert floor_penalty  points = −5 × ceil(short) + post "FLOOR MISSED — N PTS OFF THE BOARD"
    elif forfeit and counting_pts > 0 → insert floor_forfeit points = −counting_pts + post "MONTH FORFEITED…"
if season_format = 'hybrid' → +15 matchup_bonus to the top squad (dormant since D48)
insert month_closed sentinel (0 pts) + post "<MONTH> CLOSED — LEDGER POSTED[ · PARTIAL MONTH, FLOORS WAIVED]"
```
Ledger rows carry `squad_id`, so `v_squad_standings` picks them up; individual standings do **not** include penalties (they are squad-level).

---

## 6. Business rules with citations

1. **Every posted round scores; 5-point floor** — §2.2, design principle 1; `cup_points` else-branch 5; client copy "Rough one, but posted rounds always score" (5570).
2. **12-point ceiling is the anti-sandbag** — §2.2; `cup_points` caps at 12; D49 accepts the bounded exposure of a padded starter.
3. **PvI is the engine currency; the screen says "your number"** — D1, D2: cards show gross + band phrase; differential/index/allowance only inside receipts (`roundCardBody`). Bands: Torched it / Beat your number / Played to it / A little loose / Posted anyway (`bandName` 5573). Third-person `theirs()` for others' rounds (5591).
4. **9-hole rounds: half value, half a floor credit, doubled differential** — §2.4, D72, D73; `v_rounds_ranked` ceil(/2) and 0.5; trigger ×2. `nine_hole_allowed=false` drops nines from the league lens entirely.
5. **Counting cap: best N per calendar month; displacement is real-time and visible** — §3.1, D3 (fill meter, "BUMPED" rows); `month_rank` ordering points desc, pvi desc, played_on desc.
6. **Participation floor with auto-bye on first miss** — §3.2, D14; floors **waived in partial edge months** (§14.0, `is_partial`); Pro pre-grant/revoke via `set_member_bye`; late joiners on/after the 15th waived (§14.1 — **not implemented**: `close_month` has no join-date logic; only the blanket partial-month rule exists).
7. **Rounds are immutable; deletion is owner-only via `delete_round`** — §16, D37 (dropped `rounds_owner_update`), `20260715170000`. Commissioner void/edit (§9) **does not exist** — `voided` is never set by any path.
8. **A round belongs to the local date played; the window is the season's `[starts_on, ends_on]`** — §9, §14.0; `round_to_board` and `v_rounds_ranked` both key on `played_on`. Backdating allowed to any past date (no 7-day rule from §9 is enforced); future beyond tomorrow rejected (`rounds_no_future`). The ceremony only says "COUNTS THIS SEASON" if the date is inside the window (6428–6440).
9. **Index emerges from scores; a manual index is a starter, not an override** — `20260716100000`/`110000`/`120000`; established at 3 rounds; `set_index` refuses afterwards; the engine handoff is announced once. The "Building your number · n of 3" meter (renderStats 9459–9463). D49: provisional rounds score normally (no flat 7).
10. **Index snapshot is receipts-grade** — §16 "how the handicap was known": `index_at_post` + `index_source_at_post` (the latter is effectively always 'self' for quick posts — see 7.9).
11. **Sim rounds** — §2.4 toggle exists in settings and views, but `rounds_source_check` forbids `'sim'`; the toggle is dead.
12. **Allowance %** — §2.1, D48: fixed per preset (Casual 100 / Standard 95 / Cutthroat 90), applied only in `v_rounds_ranked`. Everything "career"/global uses 100%.
13. **Photos are garnish, the round is the fact** — photos-arc ckpt 1; failed upload never blocks a post; private bucket, signed URLs, visibility via `can_see_media`.
14. **Scan: the model proposes, the golfer confirms; failure degrades to typed entry; cost fails closed** — D36, photos-arc; caps in `app_flags.scan`; `scan_usage` reserve-then-count; every soft failure is HTTP 200 `{unavailable}`.
15. **One scan can post the foursome; the claim is the invite** — D36 stretch; `scan_claims` 8/day; partner round posts on the claimer's profile with the poster's rating/slope.
16. **Attested = played in a live round** — §6, §13.1; only `finish_live_round` sets `attested=true`; no partner-confirm flow for quick posts.
17. **Course data is a seed, not a runtime dependency** — §13.1; cache-first search, serve-always cache, 180-day background refresh; API key never in the client.
18. **Weather is keyless and fails soft** — scheduled-rounds arc Stage 5.
19. **Scheduled rounds: RSVP is for the invited; visibility for the crew** — D17, D38, D69.
20. **Every points figure opens the rounds behind it** — §16, D5, D95; `round_card`, `openMemberHist`, `showSquadReal`.
21. **One headline per round** (barrier > PB > streak; D22's "Mark This" user mark is **not built** — no mark column, no stepper tap).

---

## 7. Edge cases & landmines

1. **Rounds are inserted directly by the client, not via an RPC.** `sb.from('rounds').insert(payload)` (6378). Native must replicate the exact column set and the two skew-retry patterns, or switch to a new `post_round()` RPC (recommended — see §8). RLS requires `profile_id = auth.uid()`; the trigger fills it, so omit it.
2. **`course_label` is NOT NULL but the client sends `null` when the field is empty** (6362). A course-less post fails at the DB with a generic error. The composer never enforces a course; the failure surfaces as "Post failed."
3. **Preview ≠ server when allowance ≠ 100%.** `recalc()` uses `state.myIndex` at 100%; `v_rounds_ranked` applies 95/90. A Standard-league golfer with index 12.0 sees a preview PvI 0.6 higher than the league's. The ceremony then prints the preview's `pts` (6444) — can disagree with the epilogue's server `points`.
4. **9-hole rating convention is subtle.** Field `rating` is "18-hole" by convention, but for a real 9-hole tee the client puts the tee's 9-hole `course_rating` into BOTH `rating` and `nine_rating` (`rating9=true`, 6355–6360) — so `rounds.rating` is a 9-hole number for those rows. D72's text claims "a real 9-hole tee stores 2× its 9-hole rating" — the code does not do that. `rounds_rating_sane` (25..90) tolerates it. Receipts (`roundCardBody` 11330) print `nine_rating` for nines, so the math shown is right; anything that reads `rating` for a nine is not.
5. **`rounds.season_id` is NULL on every server-side insert** (live finish, scan claim, sandbox) and is the client's *currently entered* league on quick posts — a golfer in two leagues gets a `season_id` for only one. Consumers: `round_epilogue` (returns null pvi/points when NULL → epilogue shows no band row), `rholes_read` RLS. Logged as debt in D92/D95. Native should not rely on it.
6. **`round_holes` is unreadable through RLS for most rounds** (`rholes_read` joins `seasons` on `rounds.season_id`). The only working read is `live_round_card()` (live rounds). **There is no read path for the holes of a quick-posted or scanned round** — the stepper's per-hole detail is write-only today. Native needs a `round_holes_for(round)` definer RPC (or fix the policy to owner-or-shared-league).
7. **Deleting a round does not recompute the index.** `round_refresh_index` is AFTER INSERT only; `profiles.index_current` stays at the value that included the deleted round until the next post. Also the storage object at `photo_path` is orphaned (no cleanup), `achievements.round_id` goes NULL (trophy survives), and a personal-best achievement earned by the deleted round is not re-evaluated.
8. **Band edge at exactly −1.0**: server 6, client 7 (§5.2).
9. **`index_source_at_post` is meaningless on quick posts** — always the default 'self' even when the index came from the engine; the §16 promise is only honoured by the trigger's `index_at_post` value, not the provenance flag. Native: send `index_source_at_post` = profile `index_source` (or let the trigger set it).
10. **Provisional first round scores against itself** (`coalesce(index_at_post, differential)` → pvi = 0 → 7 points at 100%; 95% → slightly negative). By design (D49) but surprising; the UI badges it only via "Building your number".
11. **Month boundaries use three different clocks**: `v_rounds_ranked` = calendar month of `played_on` (date, tz-free); `myMonth`/pressure meter/`renderStats` = device local month; `run_month_closes` = server `current_date` at cron time (07:10 UTC = 00:10 Phoenix, safe). A Phoenix user posting a July 31 round from a UTC+ device after local midnight is fine (date input is a plain date), but "counting rounds this month" on Home can flip a day early for travellers.
12. **The composer eyebrow "your index 12.4" is hardcoded** (3101) — never updated.
13. **`state.myIndex` falls back to 18** at 14872 for a fresh league creator; preview only.
14. **Scan partner claims inherit the poster's tee** (rating/slope/date/course), `p_holes` hardcoded 18 (6478) even for a 9-hole scan — a nine-hole scan mints 18-hole partner claims with `strokes` zeros for 10–18 (`claim_scan_round` skips 0 holes but posts `gross` as an 18-hole round).
15. **Backdating is unlimited** (only the future is blocked). A round backdated into a previous, already-closed month lands in `v_rounds_ranked` for that month and changes historical standings, but `close_month`'s penalty for that month is never revisited (sentinel). §9's "7 days then override" rule is not built.
16. **Sim rounds** cannot be inserted (constraint) although the engine excludes them everywhere.
17. **`v_rounds_ranked` includes `complete` seasons** — career/lens views across seasons are fine, but it also means a round posted after a season completes with `played_on` inside the old window still ranks there (and `round_to_board` will not post it, since it requires active/cup_final).
18. **Two-league fan-out is invisible in the composer**: the preview shows one number; the round may score differently in each league (different allowance/cap). The board post and the epilogue only reflect the entered league.
19. **HEIC/large photos**: `createImageBitmap` resize fallback exists for Safari; the PWA eviction on camera open is why the draft exists. Native has none of this problem.
20. **Deploy-skew retries fire on message sniffing** (`/api_course_id/`, `/photo_path/`); CLAUDE.md's own landmine says 42501 never names the column. Native talks to one known contract — drop the sniffing, but keep "new column optional" discipline.
21. **`attestations` is written only by live finish**; the "PLAYED WITH THE GROUP" line depends on `live_round_players` or attestation rows — quick posts with tagged partners have no attestation path.
22. **`league_members.index_current`** is a stale copy seeded at join; nothing scoring reads it. Do not surface it.
23. **The orphan 7-arg `score_round(...)`** is still granted to `authenticated` and IMMUTABLE — usable as a scoring oracle for native tests (`select * from score_round(84, 71.2, 128, null, 12.0, 95, 18)`), but its band edge (`>= -1`) differs from `cup_points` (`> -1`).
24. **`round_to_board` requires an active season**; a round posted during `setup`/`draft` never hits the board but does count later if the season window (set at lock) covers its date — the client's "PRE-SEASON · NOT COUNTING" line reads `month_rank == null` from the season-scoped view, which is correct.

---

## 8. Web-specific / clunky things native should do differently (opinionated)

### Must remain intact (the contract)
- **The math lives in the database.** Native never computes the differential, index, PvI or points as truth — it previews. Keep `score_round()`, `v_rounds_ranked`, `cup_points`, `close_month` untouched; native reads `round_card`/`v_rounds_ranked` for every number it shows.
- **Two boxes are the front door** (D32/D34): Front 9 / Back 9 (or one nine). Do not make hole-by-hole the default.
- **The hole-by-hole stepper is par-prefilled** ("adjust only what you didn't par"), with `−`/`+` per hole, colour by result, a Set-the-pars escape, and the even-par guard. Keep `touched` semantics (interaction, not scores≠pars).
- **Camera-first scan is the accelerator, never a dependency**; every failure lands on the two boxes with the exact soft-failure vocabulary (`daily_cap` / `disabled` / else). Keep the "Whose card is this?" row picker and the "N holes I couldn't make out are set to par" honesty. Keep the partner-claim sheet immediately after the post (the crew is standing right there).
- **Named bands and the phrase producer** (`bandName`, `vsPhrase`, `theirs`) are copy law (D1/D2). No differential/index on cards; receipts show the arithmetic row exactly as `roundCardBody` does.
- **Rating/slope always editable**; manual course entry always possible; "type the rating and slope by hand" copy.
- **The finish is a ceremony** (gross, band phrase, `+N PTS · COUNTS FOR <SQUAD>` gold only when earned, "COUNTS ON YOUR CARD" otherwise), then the epilogue (achievements, rivals, share).
- **Delete = owner-only, confirm copy** "It leaves your card and any league standings it counted toward."
- **Photo is optional garnish**; upload before insert; never block the post.

### Do differently
1. **Add a `post_round()` SECURITY DEFINER RPC** taking the full payload including `p_holes int[]` (nullable) and `p_photo_path`, returning `{round_id, epilogue}` in one round-trip. It fixes 7.1/7.2/7.5/7.6/7.9 in one place: sets `season_id` for *every* qualifying season or drops the column from the contract, writes `round_holes` transactionally, stamps `index_source_at_post` from the profile, validates `course_label` with a real message, and returns `round_epilogue` inline. Web can adopt it later (deploy-skew: the client keeps the direct insert as fallback).
2. **Add a hole read RPC** (`round_holes_of(p_round)` guarded like `round_card`) so native can render the card for quick-posted/scanned rounds. Today the stepper's data is invisible after posting — a native scorecard view for *every* round is the obvious upgrade, and the data is already there.
3. **Preview with the league lens.** Native has the memberships list; compute the preview per league (allowance × index) and show "9 pts in PIGL · 7 pts in Sunday Cup" or at least use the entered league's allowance. Keep the preview labelled as a preview.
4. **Course search should be a native picker**: cache-first results instantly (query `api_courses` directly), remote merge, tee list as a second sheet with `number_of_holes` badges, remembered courses at the top (replace `courseChips`). Persist the last-used tee per course locally. Stamp `api_course_id` and (new) `tee_id` text so receipts can name the tee (`round_card` currently cannot; `rounds.tee_id` is uuid for legacy tees).
5. **Stepper on a phone**: one hole per screen is wrong for this product — the web's 9-cell grid per side is the right density, but native should use a large stepper row (par label, big score, −/+ with haptics), swipe between front/back, a running gross in a sticky footer, and keyboard-free entry. Prefill from `api_course_holes` (par + SI) when a tee is picked; never inherit the previous course's pars (the Palo Verde bug, 6871–6879).
6. **Scan**: use the native camera with document-edge guidance; downscale to ≤2200px JPEG q.9 before upload (the function rejects >8MB b64); show the read confidence per cell (0 = unread, highlighted) in the confirm grid; keep the scan photo as the round photo by default with a toggle.
7. **Drafts**: native has no PWA eviction, but keep an autosaved draft anyway (app kill mid-entry) including the photo file URI.
8. **Dates**: use a native date picker defaulting to today in the device zone; send a plain `YYYY-MM-DD`. Never construct dates via ISO parsing (CLAUDE.md landmine).
9. **Skew retries by message sniffing go away**; native pins to the contract snapshot and treats optional columns as optional at the type level.
10. **Receipts**: open instantly from cached row, enrich from `round_card` (same two-pass pattern) — keep, it is good.
11. **Delete**: after `delete_round`, native should call `handicap_index(profile)` and refresh the profile (or, better, add index refresh to a `delete_round` v2 migration) so the index does not go stale (7.7). Also remove the storage object.
12. **Home "counting rounds"/pressure meter** should read `league_pulse` (server month, `partial` flag) rather than device-month arithmetic (7.11).
13. **The composer's static "Point bands" table** should become a league-aware sheet ("in PIGL your best 4 count; 95% allowance") built from `league_settings`.
14. **Album/photos**: batch-sign once per screen (as web does); cache signed URLs for their 1h TTL.

---

## 9. Existing stats/insight surfaces and what data is available for richer stats

### 9.1 What is shown today
| Surface | Figures | Source |
|---|---|---|
| Home stats strip (`renderStats`) | index (+ season delta ▼/▲), counting rounds fill-meter n/cap, month pressure, "Next up" floor prompt | `CS.profile.index_current`, `myIndexDelta`, `myMonth`, `league_pulse.partial` |
| You tab career tiles (`renderCareer`) | Rounds posted, **Best vs index** (max PvI @100%), **Avg vs index**, Cups & events; FORM last-5 dots + streak tag; recent 5 rounds `date · course · gross · differential` | direct `rounds` select (400 rows), client math |
| Career record (`renderCareerRecord`) | cups, crowns, majors, events, runner-ups, earnings settled, seasons done | `career_record()` |
| League individual table (`renderIndStatsReal`) | rank, R, Avg vs index (league lens), Pts; Points King / Most Improved (index drop) / Iron Man (most rounds) | `v_individual_standings` + `v_rounds_ranked` |
| Member history sheet (`openMemberHist`) | per-round date, 9-hole flag, BUMPED, pvi, points | `indRows.hist` |
| Squad receipt (`showSquadReal`) | counting rounds, ledger net, total, roster with avg | `indRows`, `v_squad_standings` |
| Round receipt (`roundCardBody`) | course rating/slope, arithmetic, index that day, band, points, month rank, nine, attested, played-with | `round_card` |
| Tour Card (`openTourCard`) | index, trophies, form, vs-you weekly-clash record, Rounds / **Best diff** (min differential) / Avg vs index, recent 5 | `tour_card` |
| Board story card | gross, band, counting line, streak N STRAIGHT UNDER, pvi chip, points | `roundCache` |
| Home feed row | milestone flags (PB / broke 80 / first), phrase, gross | `home_feed` |
| Scorecard (live rounds only, `openScorecard`) | par/SI rows, strokes per hole per player, OUT/IN/TOT, birdie colouring, match ledger | `live_round_card` |
| Season album | photo grid by month | `rounds.photo_path` |

Note the inconsistency: "Best" means **max PvI** on the You tab and **min differential** on the Tour Card.

### 9.2 Data available but unused for stats
- **`round_holes`** for every stepper/scan/live round — per-hole strokes. With `api_course_holes` (par, SI, yardage) joined via `rounds.api_course_id` → tee (or `live_rounds.course_snapshot`), native can compute: scoring average by par-3/4/5, birdies/pars/bogeys/doubles distribution, front vs back splits, best/worst holes at a home course, "blow-up hole" frequency, net double-bogey adjusted gross (the missing WHS ESC), Stableford/quota (§2.5 roadmap engine "unlocks with no new data plumbing").
- **`index_at_post` history** per round = the index trend line (D55's sunlight chip: "12.4 · was 11.2 in May"). Also enables "index 60/90 days ago".
- **`differential` series** → handicap trajectory, best-8-of-20 visualisation with the counting differentials highlighted (the engine's own receipt — currently invisible), "you need a X to drop 0.5".
- **`v_rounds_ranked`** across seasons/leagues → per-league PvI, counting vs bumped rate, points per month, band distribution (how often "Torched it").
- **`api_courses` lat/lon + `course_label`** → courses played map/list, rounds per course, course-specific scoring average and best.
- **`played_on` cadence** → rounds per month, weekday pattern, iron-man streak (already computed in `round_moments` but not surfaced beyond 4/8/12).
- **`attestations` / `live_round_players`** → who you play with most (`last_round_with()` exists), record vs each partner (`my_rivalries()` exists for league clashes).
- **`achievements`**, `trophies`, `season_payouts`, `standings_snapshots` (weekly standings history per season — the Week Review browser).
- **`scan_usage` + `client_events`** — operator only.
- **`weather_cache`** — could stamp weather on a posted round if the posting date/course match a cached forecast (not a fact of the round; treat as decoration).

### 9.3 Gaps to fill for richer native stats (needs migrations)
- A `round_holes` read path (7.6).
- Storing `tee_id`/tee name/par_total on the round (today only rating/slope survive; the tee is implied by `api_course_id` + rating match, which is what the post `onTee` does at 6884).
- Optional front/back split (D32 deferred: "41/43 texture").
- A unified definition of "best" (PvI vs differential).
- Per-league career (`tour_card.career` is global @100%).

---

## 10. Open questions

1. **Direct insert vs RPC**: is native allowed to add `post_round()` (a migration, hence a remote-session task), or must the B-phase native client mirror the web's direct insert for parity first?
2. **`rounds.season_id`**: retire the column from the contract (D92 debt) or have `post_round()` populate it — and if so, for which season when the golfer is in several?
3. **9-hole `rating` storage**: keep the current "9-hole rating in both columns" behaviour, or normalise to D72's stated convention (18-equivalent in `rating`)? Changing it needs a backfill and touches `rounds_rating_sane`.
4. **Band edge at pvi = −1.0**: server says 6, client says 7; which is canon for v1.1? (Spec §2.2 table literally excludes −1.0 from both rows.)
5. **Index refresh on delete**: acceptable to add an AFTER DELETE trigger, or keep deletes rare and stale-until-next-post?
6. **Hole detail visibility**: who may read another golfer's `round_holes` — league-mates (as `rounds_read`) or owner only?
7. **Commissioner void/override** (§9): never built. Is it in native's scope, or does `delete_round` + the Pro's ruling (D50, procedural) stay the answer?
8. **Late-joiner floor proration** (§14.1, "on/after the 15th") is not implemented; is the blanket partial-month waiver considered sufficient?
9. **Scan on native**: keep the Edge Function (base64 JSON body) or add a storage-upload path so the function reads from the bucket (smaller request, and the photo is already the round photo)?
10. **Preview allowance**: should the native preview use the entered league's allowance, all leagues, or stay at 100% "your card" math with the league number deferred to the epilogue?
11. **"Mark This" (D22)**: still wanted? It implies a `rounds.marked_hole` column and a stepper tap.
12. **Tee identity on the receipt**: worth a `rounds.tee_label`/`api_tee_id` column so `round_card` can say "Copper tees · 64.9/111"?
13. **Weather on posted rounds**: decoration only, or never (it is not a fact the golfer attested)?
