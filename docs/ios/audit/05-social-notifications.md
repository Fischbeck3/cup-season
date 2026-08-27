# Audit 05 — The social layer and every re-engagement channel

Read-only audit of `/Users/fischbeck3/cup-season` (index.html @ 17,767 lines, migrations through `20260826120000`, `packages/db/contract.psv` snapshot 2026-08-26) for the native iOS rebuild (D98). All line numbers are `index.html` unless a file is named. Migration paths are relative to `supabase/migrations/`.

**Headline facts, up front**
- The board is **per-league (or per-event)**: `posts.league_id` XOR `posts.event_id` (`posts_home_check`, `20260716160000_ryder_slice3.sql:24-29`). There is NO cross-league posts table.
- A **cross-league activity feed DOES exist** — `home_feed()` (definer RPC) returns the last 21 days of ROUNDS from your "circle" (accepted buddies ∪ league-mates ∪ event-mates), and `loadHome()` (16510) unions it with the last 20 non-chat/non-round posts across ALL your leagues into ONE Home stream ("Around your buddies", 2819-2821).
- A **friends graph DOES exist** (`friendships`, `20260712010000_social_graph.sql`), product noun "buddies" (D80). It is symmetric, request/accept, and feeds `home_feed`, `my_schedule.is_friend`, the Home hero ladder (D81 rung 5/6), and a push+email on request.
- Push is **web push (VAPID) + a dormant-until-secrets APNs branch** in the same Edge Function; both are driven by three Database Webhooks (`posts` INSERT, `push_nudges` INSERT, `friendships` INSERT/UPDATE). APNs is env-gated and lights up when `APNS_P8/APNS_KEY_ID/APNS_TEAM_ID` secrets exist (`supabase/functions/push/index.ts:150-190`).
- Email: Brevo transactional. Three mails exist: buddy request (push fn), season recap (D68), league cancellation (D71). Unsubscribe is a tokened anon RPC that can only flip one boolean OFF.

---

## 1 · Post kinds catalogue

`posts` CHECK constraint (latest, `20260715234500_round_moments.sql:32-35`): `kind IN ('chat','round','system','announce','moment')`. Columns (baseline 1195-1206 + later): `id, league_id (nullable since Ryder), event_id, season_id, kind, member_id (league_members.id — NOT profile id), round_id (FK rounds ON DELETE CASCADE), live_round_id (D92, `20260729120000_scorecard.sql:33`), body, push_title (D77, `20260727240000_name_resolution.sql:37`), created_at`.

| kind | who creates | payload shape | rendered as | pushed? | emailed? |
|---|---|---|---|---|---|
| `chat` | **client direct INSERT** (only client-writable kind; RLS `posts_chat` baseline:2227 checks `member_id = my_member_id(league_id)`) — `sendChatFrom()` 5399-5416 | `league_id, season_id, kind, member_id, body` (free text, unbounded) | Board: `.msgrow` with name + squad-colour bar + reactions, NO comment thread (`comments:false`) 5160-5166, 5303-5307. NOT on Home (`neq('kind','chat')` 16555). | Yes → league members except author, gated by `profiles.notify_chat` | No |
| `round` | **server trigger `round_to_board()`** on `rounds` INSERT (`20260727160000_board_voice.sql:57-75`; originally `20260712090000`). One post PER league the profile belongs to whose active/cup_final season spans `played_on`. Body: `"Jerecho posted 92 at Encanto GC."` (D77 first-name voice via `firstname()`). Carries `round_id`, `member_id`, `season_id`. | body + `round_id` | Board compact: `.msgrow` with reactions+comments 5147-5152; Board full: rich `.fcard` "story card" from `window.roundCache` (gross, band, counting status, streak tag, photo ground, marker stamp) 5245-5285; Home: NOT via posts — `home_feed` rows via `feedRow()` 10247-10295 | Yes → league members except author, gated by `profiles.notify_rounds` | No |
| `moment` | **server triggers** — `round_moments()` (one headline per round: barrier > PB > iron-man streak; `20260727160000_board_voice.sql` restored voice, carries `round_id` so deleting the round cascades the headline — `20260722100000`), `squad_lead_moments()` (lead change: "Mudsharks just snatched first from X." `20260716200000_post_round_peak.sql:150-160`, `member_id NULL`) | `body`, optional `round_id`, `member_id` (null for squad moments) | Board: `.momrow` "✦ …" 5167-5170; Home: `postRow()` quiet card with 🏁 avatar, "sealin" thock animation <48h 10297-10324 | Yes → all league members except author ("everything else always delivers") | No |
| `announce` | **Pro only** via RPC `announce(p_league, p_body)` (`20260712070000_announcements.sql`, 1-280 chars, `is_commissioner` check). UI: 📣 button on the board composer `#annBtn` 13862-13871 (reuses `#chatIn`). | `league_id, kind, member_id, body` | Board: latest announcement PINNED above the feed "📌 FROM THE PRO" 5132-5135, older ones inline "📣 FROM THE PRO" 5155-5158; Home: `postRow()` with 📣 avatar | Yes → all members except author | No |
| `system` | **server only** (no client insert path). ~60 emit sites; see list below. | `body` (≤400 chars typical), sometimes `member_id` (attributable) and `live_round_id` (settlement) and `push_title` (settlement short form) | Board: `sysRowHtml()` "◆ …" 5115-5121; a row with `lrid` becomes a button that opens the scorecard sheet (D92, `openScorecard()` 10336-10450). Home: `postRow()`. Event board: `.sysrow` list 12349-12353. | Yes → league members except author (or event players when `event_id`) | No (except the season close ALSO triggers the recap email via `seasons.status`, not via the post) |

**`system` emit sites (server) — the league-event vocabulary a native client must render:**
season lifecycle: draw/formation ("ROSTERS LOCKED — THE SEASON IS LIVE", `board_voice.sql:557-575`), kickoff/buy-ins (`20260712130000:56,75`), month close (floor penalties naming the golfer w/ `member_id`, monthly +15 bonus, "month closed" — `board_voice.sql:265-336`, `20260716180000_auto_bye.sql:73-134`), byes granted/removed (`auto_bye.sql:167-174`), endgame/crowning + pot settlement story (`20260716170000:257-265`, `20260724230000:187-195`), cup-final seeds; membership: "X JOINED THE LEAGUE" (`20260714040000:34`, `20260713180000:101`, `20260729180000:53`), added-by-friend (`20260712050000:35`), Pro role transfer (`20260712150000:179`), member removed; identity: handicap/index changes (`20260716100000:127`, `20260716110000:43`, `20260716120000:45-99`, `20260711150000:29`), photo reports (`20260723150000:59`), name changes (`20260716070000:50,83`); tee sheet: declared rounds + tags + tee time (`20260712150000:66,152`, `20260712170000:71`, `20260715230000:75`); games: settlements for match/wolf/skins/sunningdale/round-robin (`20260729120000_scorecard.sql:181-187` with `live_round_id`; `20260727240000:240-247` with `push_title`); forfeit ledger stakes (`20260724120000:83-143`); draft picks (`make_pick`); Ryder engine posts via `event_post()` (pairings at session open, results/scoreline at resolve, cup + MVP at completion — `20260716160000:47`, event-scoped) and Major posts via `major_post()` (`20260720193000:140`, dual league+event).

**Not post kinds but adjacent social objects:** `post_kudos` (reactions), `post_comments` (threads on round posts only), `round_comments` (threads on SCHEDULED rounds — tee sheet), `push_nudges` (per-recipient push rows, never rendered), `content_reports`.

---

## 2 · Screens & states inventory

All client. Function name → lines → states.

**A. The Board (league room, Clubhouse view)**
- Compact feed `#feedList` (3385) + composer `#chatIn`/`#chatSend`/`#annBtn` (3387, 13862). `renderFeed()` 5127-5205. Date separators, pinned announcement, quiet-day digest (`boardDigestHtml()` 5063-5113 — "SINCE YOU WERE HERE", localStorage seen-mark `cs_board_seen_<league>` 5029, frozen once per session in `window.bdAsOf`).
- Full-screen board `#boardFull` (3609) — `openBoardFull()` 5376, `renderFeedFull(force)` 5220-5340: Strava-style story cards with reactions+comments, scroll-position preservation, photo cards opening `openRoundReceipt()`.
- Loader: `loadStandingsAndFeed()` 14365-14539 — `posts` where `league_id`, ascending, `limit(120)` (14389). Retry without `live_round_id` on ANY error (skew). Then `rounds` + `v_rounds_ranked` into `window.roundCache`, batched `createSignedUrls` (1h TTL) for photos, then `fetchSocial()` for kudos/comments.
- Empty: synthetic sys row "<League> is live — post the first round" (14484). Loading: none (board renders empty until data). Error: silent (`console.warn`), feed stays.
- Chat send: optimistic echo, then direct insert; failure reverts + `toast(humanError)` 5399-5416. Realtime INSERT rebuilds the whole feed.

**B. Reactions + comments (`socialBar()` 4715-4740)**
- Vocabulary 4670-4676: 🔥 heater · 🦅 eagle · ⛳ dialed · 🧊 ice · 🐍 snake · 🚨 sandbagger (server column `post_kudos.emoji`, `20260716230000_post_reactions.sql`).
- `toggleRx()` 4767-4783 optimistic + `rxWrite()` 4762 direct `post_kudos` insert/delete keyed `(post_id, member_id, emoji)`. Comments: `sendComment()` 4785-4796 direct `post_comments` insert. Report: `reportPost()` 4834-4859 → `report_content` RPC in an in-app sheet (never `prompt()` — landmine).
- Comments only on ROUND posts (chat is `comments:false`). Comment thread is collapsible per card (`.cthread`), UI open-state captured/restored across re-renders (`socialUiCapture/Restore` 4972-5027).
- Home reactions: `fetchHomeSocial()` 10135-10180 maps each circle round → ONE deterministic post (open league's if member, else oldest), writes with the member id of THAT league (`toggleHomeRx` 10181-10200). Buddy-only rows (no shared league) get NO reaction strip (10120-10125 comment).

**C. Home feed (cross-league) `#view-home`**
- Order (D81/D94, 2790-2830): `#notifBanner` (pending league/event invites, `renderNotifications()` 12596-12622) → `#resumeBanner` → `#homeRequests` (incoming buddy requests, `renderRequestsInto()` 10742-10772) → hero slot (`renderHomeHero()` 9815) → occasion card → `#homeUpNext` chips (`renderUpNext()` 10684-10715: next round, "Buddy's playing", "Needs you N invites", month closes) → eyebrow "Around your buddies" + "THE BOARD ↗" → `#homeDigest` (`renderHomeDigest()` 10572-10614: "Since you were here … N rounds, a personal best from X, Ed 🔥'd your 84" OR "Quiet since your last visit — best recent thing"; seen-mark `cs.seen.<profile>` 10493) → `#homeFeed` (`renderHomeFeed()` 10628-10650: `home_feed` rows + `homePosts` merged, newest first, `slice(0,30)`, bucketed Today / This week / Earlier with CAP=8 per bucket behind `<details>` — `feedBuckets()` 10458-10486) → "Upcoming golf" `#homeRounds`.
- Loading: `skeletonRows(3)` while `homeFeedRows===undefined && homePosts===undefined` (10633). Empty: "No rounds from your buddies yet. Post one, or add some buddies." (10646). Error: swallowed; previous rows kept.
- Round card: `feedRow()` 10247-10295 — face+marker, gross, band phrase in third person, milestone tags (🔥 Personal best / ⛳ Broke 80 / 🎉 First round), photo "story card" variant, tap → `openRoundReceipt()`.

**D. Post-round peak (the emotional moment)**
- `finishCeremony()` 6040-6079 full-screen curtain `#finish` (3692): gross, band phrase, "+N PTS · COUNTS FOR <SQUAD>" gold when earned; haptic `navigator.vibrate([10,38,10])`; Share button → `shareRecapCard()`.
- `showEpilogue()` 5959-6021 sheet: band+points+counting rank, achievements earned (`EPI_ACH` 5943-5952), rivalry record moved (`rivals[]` from `round_epilogue()`), first-ever welcome, "Share the card" / "Share a link — no account needed" / "Turn off this link". Skipped silently on deploy skew or nothing-to-say.

**E. Trophy case / memory (You tab)**
- `#trophyCase` (2864) `renderTrophyCase()` 11051-11085: tiles for `my_trophies()` (kinds ryder/league/major/bracket; placements winner/runner_up/points_king; `trophyIcon()`) + `my_achievements()` (`ACH_META` 11032-11041: first_round, sub_100/90/80, personal_best, streak_4/8/12). "Engraver" animation for a trophy that arrives mid-session (`_trophySeen`). Empty: "No hardware yet. Break 80, post your first round, or win a Cup Final…". Loader `loadTrophies()` 16382-16390.
- `renderCareerRecord()` 11106-11135 (D67: cups, crowns, majors, events, runner-ups, settled money, D39 language).
- Rivalries `#youRivals` `renderRivalries()` 13215-13242 (`my_rivalries`: W-L-T weekly clash + Ryder duel facet + christened name); `openRivalrySheet()` 13244-13263 (`rivalry_weeks` receipts) → `openNameRivalry()` 13268 (`set_rivalry_name`).
- Last Round With (D63) `loadLastRoundWith()` 16202-16220: in-app-only reunion whisper, 90-day local dismiss.

**F. Buddies (You tab `#youPeople` 3572)**
- `renderCrewPeople()` 13164-13210: search input (debounced 350ms → `search_golfers`, one-letter search allowed), results with Add/Accept/Buddies/Requested tags, Requests section, Buddies list, Requested list. `openPeoplePicker()` 13452 is the reusable picker (befriend / invite modes). Header magnifier `#hdrSearch` 13860 → `openFindGolfers`.
- Tour Card sheet 13300-13430 (`tour_card` RPC): Add buddy / Accept / tags, "You vs" rivalry button, **Mute/Unmute** button (`set_mute`, W4) 13373-13381, 13412-13424, Report profile photo.
- Discoverability `set_discoverable('everyone'|'friends'|'nobody')` — UI in profile hub (the "Findable by" option, per D80 amendment).

**G. Notification preferences (profile hub `openProfileHub`, 13513-13840)**
- Buttons 13564-13567: `#phPushTog` "Enable/Disable on this device" (web push subscribe OR APNs register in Capacitor shell — `enablePush()` 14031-14065, `disablePush()` 14066-14090, `getPushSub()` 14024), `#phRoundsTog` "Round pings: ON/OFF" (`set_notify_rounds`), `#phChatTog` "Chat pings: ON/OFF" (`set_notify_chat`), `#phMailTog` "Season email: ON/OFF" (`set_email_recap`, hides itself if RPC missing).
- **The only place permission is ever requested is this settings button.** No contextual prompt after first post, first league, etc. `syncNativePush()` 14011-14022 re-registers APNs token on boot ONLY if permission already granted (called 17255, 17326).
- Ryder duel taunts: per-event toggle button in the event room 12266 → `window.ryderNotify` 16327 → `set_event_notify`.
- Mute per person: Tour Card (above). Enforced by RLS, not client filter.

**H. Invites banner** `renderNotifications()` 12596-12622: `my_invites()` rows (league or Ryder) with Accept / Details sheet (Accept & join / Decline) → `respondInvite` 16344. Also counted into the "Needs you" up-next chip.

**I. Tee-sheet social (round object, D38/D69)**: `openRoundSheet()` ~16780-16835 — RSVP (`set_round_rsvp`), "On the board" comment thread (`add_round_comment`, `round_comments`), tagged names, "BUDDY"/"LEAGUE MATE"/"YOU'RE IN" tags from `my_schedule` (12143). D86 doorbell: `start_live_round` → `push_nudges` per invited member + `live_open` broadcast on the league channel.

**J. Public/share surfaces (signed-out)**: `/?share=TOKEN` `renderShareView()` 17396-17575 (round / settlement / recap cards; dead-token copy "This link is dead."; CTA "Play this with your crew"); `/?unsub=TOKEN` 17371-17393 full-screen confirmation; `/?claim=TOKEN` 17580-17632 (stored in `localStorage cs_claim`, claimed after auth+golfer card via `claim_round` then `claim_scan_round`; "still live" keeps the token); `/?join=CODE` door.

**K. Event board (Ryder/Major)**: `loadEvent()` 15878-15882 reads `posts` where `event_id` (limit 30, desc); `renderEvent()` 12349-12353 plain `.sysrow` list. No reactions, no chat, **no realtime** (only `lg-` and `live-` channels exist).

---

## 3 · RPC table (social + notification slice; from `packages/db/contract.psv`)

| name | args | returns | security | grant | migration / note |
|---|---|---|---|---|---|
| `announce` | p_league, p_body | void | definer | auth | `20260712070000` — Pro only, 1-280 chars |
| `report_content` | p_post?, p_reason?, p_kind='post', p_profile? | void | definer | auth | `20260718174500` + `20260723150000` (profile_photo kind) |
| `friend_request` | p_profile | text ('friend'\|'requested') | definer | auth | `20260712010000` — mutual pending → instant accept |
| `friend_respond` | p_id, p_accept | void | definer | auth | decline DELETES the row |
| `unfriend` | p_profile | void | definer | auth | no client call site found (grep) |
| `my_friends` | — | TABLE(friendship_id, profile_id, handle, display_name, city, marker, index_current, status, incoming) | definer | auth | pending first, then by name |
| `search_golfers` | p_q | TABLE(profile_id, handle, display_name, city, home_course, marker, index_current, rel) | definer | auth | honours `discoverable`; `20260717194623` loosened |
| `set_discoverable` | p_mode | void | definer | auth | everyone/friends/nobody |
| `set_handle` | p_handle | void | definer | auth | reserved list |
| `tour_card` | p_profile | jsonb | definer | auth | `20260726190000` — rel, vs record, recent rounds, `visible:false` when hidden |
| `home_feed` | p_days=21 | TABLE(round_id, profile_id, golfer, marker, handle, gross, pvi, played_on, created_at, course, is_pr, is_first, is_sub80, is_me, photo_path) | definer | auth | `20260714120000` → `20260716050000` → `20260723090000`; limit 40; circle = self ∪ buddies ∪ league-mates ∪ event-mates; **muted members' rounds still show** (documented honest edge) |
| `set_mute` / `my_mutes` | p_profile, p_on / — | void / uuid[] | definer | auth | `20260722013000`; enforced in `posts_read` + `comments_read` policies |
| `set_notify_chat` / `set_notify_rounds` | p_on | void | definer | auth | `20260711170000` / `20260716030000` — flags on `profiles` |
| `set_event_notify` | p_event, p_on | void | definer | auth | `event_players.notify_target` (Ryder taunts, default false) |
| `register_device_token` / `unregister_device_token` | p_token, p_platform='ios' / p_token | void | definer | auth | `20260722013000` / `20260826120000` — `device_tokens`, platform CHECK `('ios')` only |
| `set_email_recap` | p_on=null | boolean | definer | auth | `20260725140000` — read w/o arg, write with; lazily creates `email_prefs` |
| `email_unsubscribe` | p_token | boolean (always true) | definer | **anon**,auth | the 7th anon endpoint (D68); one-way OFF |
| `season_email_payload` | p_season | jsonb | definer | service_role only | composes recipients+tokens+payout; backfills `email_prefs`; excludes `@cupseason.invalid`, `@sandbox.cupseason.test`; returns `solo` flag (D77) |
| `mark_email_sent` / `mark_cancellation_sent` | p_id, p_error? | void | definer | service_role | |
| `create_share` | p_kind ('round'\|'settlement'\|'recap'), p_ref | uuid token | definer | auth | `20260722190000`; ownership check; re-mint returns live token |
| `revoke_share` | p_token | boolean | definer | auth | deletes `shared/{token}.jpg` copy first (`20260723210000`) |
| `share_info` | p_token | jsonb\|null | definer | **anon**,auth | fail-closed; round branch has NO league key (D60a); settlement `result` = curated keys incl. `holes` (D78, `20260727120000`), `photo` bool |
| `claim_round_info` / `scan_claim_info` | p_token | jsonb | definer | anon,auth | claim funnel door copy |
| `claim_round` / `claim_scan_round` | p_token | jsonb | definer | auth | attaches the round to the claimer |
| `league_by_code` / `join_covenant_info` | p_code | text / jsonb | definer | anon,auth | invite link door |
| `my_trophies` | — | TABLE(id, kind, title, subtitle, placement, season_year, earned_on) | definer | auth | `20260713200000` |
| `my_achievements` | — | TABLE(kind, label, earned_on, meta) | definer | auth | `20260716020000` |
| `award_event_trophies` / `award_season_trophies` | p_event / p_season | void | definer | auth / none | triggered by `trg_event_complete`; season via crowning |
| `career_record` | — | jsonb | definer | auth | D67 |
| `my_rivalries` / `rivalry_weeks` / `set_rivalry_name` | — / p_opponent / p_opponent, p_name | TABLE / TABLE / void | definer | auth | `20260716010000`, `20260716210000`, duel facet `20260716160000` |
| `round_epilogue` | p_round | jsonb | definer | auth | `20260716200000` — pvi, points, month_rank, earned[], rivals[] |
| `last_round_with` | — | TABLE(profile_id, display_name, marker, last_on, shared_cards) | definer | auth | D63 |
| `my_invites` / `respond_invite` / `invite_golfer` | — / p_id,p_accept / p_league,p_event,p_profile | TABLE / void / uuid | definer | auth | `20260713180000` (`member_invites`) |
| `add_friend_to_league` | p_league, p_profile | void | definer | auth | `20260712050000` (posts a system row) |
| `add_round_comment` / `set_round_rsvp` | p_round,p_body / p_round,p_status | void | definer | auth | `20260718192400`, `20260725160000` |
| `my_schedule` | p_from, p_to | TABLE(… is_friend, shared_league, tagged_me, rsvp_in, my_rsvp, comment_n …) | definer | auth | tee-sheet social |
| `live_round_card` | p_live_round | jsonb | definer | auth | D92 scorecard behind a settlement post |
| `founder_desk` / `founder_note` / `submit_feedback` | | | definer | auth | reports land on the founder desk |
| Triggers (not callable): `round_to_board`, `round_moments`, `squad_lead_moments`, `round_duel_nudge`, `round_major_story`, `sched_major_story`, `season_email_on_complete`, `trg_event_complete`, `tag_founder` | | | definer | none/auth | |

Direct table access from the client (no RPC): `posts` INSERT (chat only), `post_kudos` INSERT/DELETE, `post_comments` INSERT, `push_subscriptions` UPSERT, `posts`/`post_kudos`/`post_comments`/`rounds`/`league_members` SELECT, storage `media` (signed) and `shared` (public) buckets.

---

## 4 · Data model

- **`posts`** — see §1. Indexes: `posts_event_created`. RLS `posts_read` (latest `20260722013000:57-69`): league member OR event member OR event-league member, AND author not in viewer's `mutes` (system posts with null `member_id` always pass). `posts_chat` INSERT policy is the only client write. Realtime-published.
- **`post_kudos`** `(post_id, member_id, emoji, created_at)` PK `(post_id, member_id, emoji)`; RLS `kudos_all` (league member; write only as own member). Realtime-published.
- **`post_comments`** `(id, post_id, member_id, body, created_at)`; RLS `comments_add` (own member in that league), `comments_read` (+ mute check). Realtime-published.
- **`round_comments`** `(id, round_id→scheduled_rounds, profile_id, body, created_at)`; RLS via `can_see_round()`; delete-own.
- **`friendships`** `(id, requester, addressee, status pending|accepted, created_at, responded_at)`; unique on unordered pair; RLS select own rows only; writes via RPC. `profiles.handle` (unique, `^[a-z0-9_]{3,20}$`), `profiles.discoverable`.
- **`mutes`** `(muter, muted, created_at)`; no policies; RPC-only.
- **`push_subscriptions`** `(id, profile_id, endpoint UNIQUE, p256dh, auth, created_at)`; owner RLS; client upserts directly on `endpoint`. Pruned by the push fn on 404/410.
- **`device_tokens`** `(token PK, profile_id, platform CHECK ('ios'), created_at)`; RLS no policies (service-role read, RPC write). Pruned on APNs 410/BadDeviceToken.
- **`push_nudges`** `(id, profile_id, title, body, created_at)`; no policies; written by `round_duel_nudge()` trigger and `start_live_round()`; one row = one push to one person.
- **`profiles.notify_chat`, `profiles.notify_rounds`** (default true). **`event_players.notify_target`** (default false).
- **`email_prefs`** `(profile_id PK, recap default true, token uuid, updated_at)`; definer-only, no client reach (deliberately not on `profiles` — a league-mate can read your profile row). **`email_queue`** `(id, season_id, kind='season_recap', created_at, sent_at, error)` UNIQUE(season_id, kind). **`cancellation_notices`** `(id, payload jsonb {league, recipients[{email,name,cents}]}, sent_at, error)` — self-contained because the league row is already deleted.
- **`shares`** `(token PK, kind, ref_id, created_by, revoked, created_at)`; RLS no policies; partial unique `(kind, ref_id, created_by) WHERE NOT revoked`. Storage bucket **`shared`** (PUBLIC, 2 MB, jpeg+png since D89 `20260729060000`): `{token}.jpg` (round photo copy, D60) and `{token}.png` (settlement card, D78 amendment); insert/delete policies fenced by `shares.created_by`.
- **`trophies`** `(id, profile_id, kind, title, subtitle, placement, event_id, league_id, season_year, earned_on)`; unique per event/profile and per league/profile/placement/year; RLS own rows. **`achievements`** `(profile_id, kind UNIQUE per profile, label, earned_on, round_id SET NULL, meta)`; RPC read only. **`season_lead`** state row for lead-change detection. **`rivalry_names`** `(pair_low, pair_high, name, named_by)`.
- **`member_invites`** `(league_id XOR event_id, profile_id, invited_by, status pending|accepted|declined)`. Legacy email **`invites`** table (commissioner RLS) still exists as the not-on-the-app fallback.
- **`content_reports`** `(post_id, reporter, reason, resolved, kind, profile_id)`.
- **Triggers on `rounds` INSERT** (all AFTER): `round_to_board`, `round_moments` (also writes `achievements`), `squad_lead_moments`, `round_duel_nudge`, `round_major_story`, `score_round` (BEFORE), `round_refresh_index`, `rounds_no_future`. On `seasons` UPDATE OF status: `seasons_email_on_complete` (sandbox-fenced). On `events` UPDATE: `event_complete_award`.
- **Webhooks (dashboard-configured, not in migrations; verify with `pg_get_triggerdef` per CLAUDE.md landmine):** `posts` INSERT → `push`; `push_nudges` INSERT → `push` (runbook v23.163 §③); `friendships` INSERT/UPDATE → `push` (stated in `20260712010000` header + push fn; NOT in any runbook checklist — see §10); `email_queue` INSERT → `season-email`; `cancellation_notices` INSERT → `season-email` (D71). All authenticate with `x-push-secret`.
- **Cron:** `run_month_closes`, `run_week_snapshots`, `daily_season_tick`, `run_event_sessions` — these produce `system` posts (month close, seeds, Ryder sessions) and therefore push.
- **Realtime publication** (`supabase_realtime`): `posts`, `post_kudos`, `post_comments`, `drafts`, `draft_picks`, `live_rounds`, `live_round_players`, `live_scores`.

---

## 5 · Notification matrix (event → channel(s) → rule / mute flag)

Sender rules live in `supabase/functions/push/index.ts`. Copy budget: title ≤80, body ≤140, word-boundary clamp (D77). Headline = `posts.push_title` if present, else the first sentence of `body`; context line = league/event name. **Empty body → skip, never filler.** Payload `url` is always `'/'` (no deep links yet, 84-86). Web push and APNs get identical text; APNs payload `{aps:{alert:{title,body}, sound:'default'}}`, topic default `app.cupseason.ios`, sandbox via `APNS_SANDBOX`.

| Event | Board post? | Push (web+APNs) | Rule / mute | Email | In-app |
|---|---|---|---|---|---|
| League-mate posts a round | `round` (one per shared league) | → every league member except author | `profiles.notify_rounds` (default ON) | — | Board card, Home feed row, digest line, reactions |
| Someone chats on the board | `chat` | → members except author | `profiles.notify_chat` (default ON) | — | Board only (not Home) |
| Pro announces | `announce` | → members except author | ALWAYS | — | Pinned on board, Home quiet card |
| Moment (broke 80 / PB / streak / lead change) | `moment` | → members except author (squad moments: `member_id` null → author exclusion cannot match → everyone incl. the poster) | ALWAYS | — | ✦ row, Home card, achievements pinned, epilogue |
| Any `system` post (joins, index changes, month close, floors, bonuses, settlements, forfeits, draft picks, declared rounds, tee times, seeds, crowning…) | `system` | → members except author (author often NULL → everyone) | ALWAYS — **no mute exists for system noise** | — | ◆ row; settlement rows open the scorecard |
| Ryder engine post (pairings / results / cup) | `system` w/ `event_id` | → every `event_players` profile (no author exclusion, no mute) | ALWAYS | — | Event board list |
| Opponent posts into your open Ryder duel | — (`push_nudges` row via `round_duel_nudge`) | → you only: "<Event>" / "<Name> posted — +2.3 to beat · 3 days left" | `event_players.notify_target` opt-IN (default OFF) | — | number-to-beat chips |
| Someone starts a live round with you on the tee sheet (D86) | — (`push_nudges` per member player) | → invited members except starter: "<First> put you on the tee sheet" / "Live round at <course> — open the app to score it with them" | ALWAYS (no flag) | — | `live_open` broadcast on `lg-<league>` → `rehydrateLiveRound()` banner |
| Buddy request | — | → addressee: "<First> wants in your crew" / "Tap to accept" | ALWAYS | **Yes** (Brevo, if `BREVO_API_KEY`; skips `@cupseason.invalid`) "wants in your crew" HTML | Home `#homeRequests`, You tab requests, Tour Card |
| Buddy accepted | — | → requester: "<First> is in your crew" / "You'll see their rounds now" | ALWAYS | — | tags flip |
| League/event invite (`invite_golfer`) | — | **none** (despite UI copy "Invited golfers get a notification" 16363) | — | — | `#notifBanner`, "Needs you" chip |
| Reaction / comment on your round | — | **none** | — | — | Home digest "Ed 🔥'd your 84", realtime re-fetch |
| Season completes | `system` crowning post (pushes as system) | (via the post) | ALWAYS | **Yes** — season recap to every league member with a real email and `email_prefs.recap` (default ON), own payout line, unsubscribe token; sandbox leagues never | Ceremony sheet, recap share |
| League cancelled with consent (D71) | (league deleted) | — | — | **Yes** — cancellation notice, only when real money is owed, never sandbox | — |
| Month close / floors / bonus | `system` | → all (see above) | ALWAYS | — | month seal card on Home |
| Trophy minted | (via crowning/event post) | — | — | — | engraver animation in trophy case |
| Last Round With (D63) | — | **none by design** (D23: no push class for longing) | — | — | quiet card, 90-day local dismiss |
| Guest claim link / share link viewed | — | — | — | — | (public pages) |

Mute-a-member (`mutes`): hides their `chat`/`round`/`moment`/`announce`/`system` posts WITH a `member_id` and their comments, everywhere posts are read incl. realtime — but does NOT stop their pushes to you (push fn reads `league_members`, never `mutes`) and does NOT hide their rounds in `home_feed`.

---

## 6 · Realtime architecture

- **Two Supabase clients.** `sb` (auth + data) and `rtClient` (12808) — a second `createClient` with `persistSession:false, autoRefreshToken:false, lock:(_n,_t,fn)=>fn()`, created lazily (14688, 14744). Token forwarded on every `onAuthStateChange` (12809-12813) and at subscribe. Landmine: channel joins on `sb` fail with `CHANNEL_ERROR — transport failure`; never move them back.
- **Channel 1: `lg-<leagueId>`** (`subscribeLeague()` 14684-14722), one per open league, torn down on league switch (14685, 15273):
  - `postgres_changes` INSERT on `public.posts` filter `league_id=eq.<id>` → `loadStandingsAndFeed()` + `loadHome()` (+ `loadLeagueData()` during draft — the board carries the draw reveal). Full refetch, not incremental.
  - `postgres_changes` `*` on `post_kudos` and `post_comments` (no filter possible — RLS scopes them) → debounced 250 ms `refreshSocial()` (re-pull kudos/comments for board + Home + digest).
  - `broadcast` `live_open` (D86 doorbell) → `rehydrateLiveRound()`; payload is a nudge, never trusted.
  - Subscribe status logged + `bootTrace` breadcrumb on anything but SUBSCRIBED/CLOSED.
- **Channel 2: `live-<liveRoundId>-<joinCode>`** (`liveSync` 14727-14800, D85): broadcast `live` (score events, `self:false`) + presence (`{n:name}` keyed by user id or guest token) + localStorage durable queue flushed through RPCs. Guests ride the anon key on the same transport.
- **No channel for:** event boards (Ryder/Major posts are fetch-on-open), buddy requests (Home polls on `loadHome`), invites, trophies, leagues you are a member of but don't have open (Home only refreshes on the OPEN league's post inserts or a manual reload).
- **Publication** must keep `posts` (and the kudos/comments/live tables); `20260711210000` guards it.

---

## 7 · Sharing surfaces and what they generate

| Surface | Trigger | What is generated | Where |
|---|---|---|---|
| **Round recap card** (D30) | Finish curtain `#finShare` (6087) or epilogue "Share the card" (6012) | 1080×1350 canvas PNG (`drawRecapCard()` 5616-5681): marker, NAME, hero gross (serif 300px), band phrase (third person), badge, course, date, points, "Cup Season / cupseason.app"; optional round photo as backdrop. `navigator.share({files,text})` else download + caption copied. Caption `recapText()` 5682. **No league name on the card** (D60a). | classic block |
| **Round share link** (D57) | Epilogue "Share a link — no account needed" 6003 | `create_share('round', roundId)` → `/?share=<token>`; if a photo exists, compresses + uploads a copy to public `shared/{token}.jpg` (D60, consent line in the button label). `navigator.share({title,text,url})` else clipboard. Revoke button → `csRevokeLink()` 5923-5935. | `csShareLink()` 5864-5922 |
| **Settlement card** (D78) | Live-round recap sheet `#lrShareCard` 9296 | 1080×1350 canvas PNG (`drawSettlementCard()` 5727-5838): margin hero, two sides, the 18-cell **hole strip** (`renderHoleStrip` 8041-8072), the money. Caption = `result.share` (D77 authored short form). | |
| **Settlement link** | `#lrShareLink` 9300 | `create_share('settlement', liveRoundId)`; uploads the card PNG to `shared/{token}.png` so the link preview IS the card (D78 amendment, D89 fixed the bucket MIME). | |
| **Season recap link** | Season ceremony 17080-17085 | `create_share('recap', seasonId)` / revoke. Public page shows league name, top-5 table, champion, points king. No canvas card for the recap. | |
| **Major jug card** | `shareMajorCard()` 12573, 12522 | canvas PNG "START YOURS AT CUPSEASON.APP". | |
| **Invite link** | `shareInvite()` 13911-13925; lock celebration `openLockShare()` 13931; draft card `#draftShare`; picker footer | `https://cupseason.app/?join=<CODE>` + "You're invited to <league> on Cup Season"; share sheet else clipboard else toast the code. | |
| **Guest claim link** (§13.3) | Tee-sheet guest rows 9273-9330, scan partner rows 6681 | `/?claim=<claim_token>` per guest; clipboard copy. Door greets with the round ("Marcus — 84 at Papago"). | |
| **Link previews (OG)** | Any `/?share=` request | Netlify Edge Function `netlify/edge-functions/share-preview.ts` rewrites `<title>`, `og:title/description/image` per token by calling anon `share_info`; round → "<Name> shot 84 at <course>" + traveled photo; settlement → `result.share` + `shared/{token}.png` (1080×1350); recap → "<League> — <Champ> take the Cup". Fail-open. Root/`/?join`/`/?claim` still get the static `og-image.png` (index.html 17-33). | |
| **Season email** | `seasons.status → complete` | HTML mail: champion, score line + margin "12 clear of X", tiebreak, runner-up, points king, top-5 table, "Your cut of the pot: $180 — Whoever collected it sends it on.", CTA "See the rounds behind it", unsubscribe link `/?unsub=<token>`. Subject "The Cup goes to <First/Squad> by N — <League>". | `season-email/index.ts` |
| **Buddy-request email** | friendships INSERT | "<First> wants in your crew" — "Accept and their rounds land in your feed, all season." CTA opens cupseason.app. No token/deep link. | `push/index.ts:196-212` |
| **Cancellation email** | `cancellation_notices` INSERT | "<League> is off — your $40 comes back" | `season-email/index.ts:154-180` |

Share copy law (D77): result first, first names outbound, no engine vocabulary (DIFF/PvI/bank/allowance) on any outbound surface; `story` (feed row, full names) ≠ `share` (thread, ~60 chars) ≠ `push_title`. `spec/share-copy-audit-2026-07-27.md` is the line-by-line audit of 128 strings.

---

## 8 · Does a friends graph exist? — DEFINITIVE: YES

- Table `public.friendships` (`20260712010000_social_graph.sql:18-31`): symmetric, one row per unordered pair, `status pending|accepted`, decline deletes. RPCs `friend_request` (mutual-intent auto-accept), `friend_respond`, `unfriend`, `my_friends`, `search_golfers` (respects `profiles.discoverable`), `set_handle`, `set_discoverable`. Product noun: **buddies** (D80; "friend" is banned in UI copy, `is_friend` stays in schema).
- It is a real graph with consequences, not decoration: `home_feed` circle (rounds from buddies with no shared league appear on Home), `my_schedule.is_friend` (tee-sheet BUDDY tag, "Buddy's playing" chip, watch list), Home hero ladder rungs 5/6 (`window.buddyCount` 16578), buddy-request push + email, `add_friend_to_league`, `last_round_with` (reunion), `tour_card.rel`.
- Also relationship-like: **rivalries** (derived, not stored — computed from shared-league weeks + Ryder duels; only the christened NAME is stored in `rivalry_names`), **mutes** (one-directional, stored), **member_invites** (container invites, not a graph).
- Explicitly NOT present: follows (asymmetric), contacts import/scraping (D63 rules it out), follower counts (memory-layer guardrail: "no vanity metrics"), a "buddy has no league" surface (RLS-invisible, cut in D81), viewing another golfer's trophy case (`trophies_read` is own-rows; `tour_card` returns a curated subset).
- Board (`posts`) is **per league / per event**; the only cross-league stream is Home's merged feed (rounds via `home_feed` + non-chat posts across memberships, `loadHome()` 16553-16560). Chat never leaves its league.

---

## 9 · Web-specific / clunky things native should do differently (opinionated)

**What MUST remain intact (the rules are in the database and the decision log, not the client):**
1. Post kinds, their server-side generation (`round_to_board`, moments, system events) and immutability (§16). Native renders; it never composes league events.
2. Chat is the only client-writable post kind; reactions/comments/kudos write with the LEAGUE MEMBER id, not the profile id — native must carry the memberships map (`CS.memberships`) to react from a cross-league Home.
3. The curation contract: `notify_chat`, `notify_rounds`, `notify_target`, `mutes`, `email_prefs` — all server-enforced. Native adds no client-side filtering that could disagree with RLS.
4. D77 copy laws on every outbound artifact; D57 fail-closed tokens; D60/D78 "the act of sharing is the publish act" (nothing uploads to the public bucket until the user taps share).
5. The seven/ten anon endpoints stay a web (desktop) concern — D98 says the public claim/join/share pages live on the web client. Native consumes those links via Universal Links (AASA already corrected per D98) and hands off `claim`/`join`/`share` params to the same RPCs.
6. Memory-layer guardrails: no infinite scroll, no engagement-bait, no like-counts-as-currency, no streak shame beyond one dignified line.
7. `rtClient`-style isolation: keep realtime on its own socket in the native client too (the failure was an auth-lock race on a busy client; RN will have the same shape).

**What should change:**
- **APNs is already 80% there; make it first-class.** The push fn's `sendApns()` branch exists, `device_tokens` + `register/unregister_device_token` exist, the secrets are named. Native registers on first meaningful moment (after the golfer card / first post / first league) with a pre-permission explainer — the web only asks from a Settings button, which is why the pilot's phones are mostly silent. Add `platform='android'` to the CHECK before Android (`device_tokens.platform CHECK ('ios')` will reject it) and FCM in the fn (native-arc.md:144).
- **Deep links in the push payload.** Every payload is `url:'/'`. The fn already has `record.id`, `record.round_id`, `record.live_round_id`, `record.league_id`, `record.event_id`; put them in `aps` custom keys and route: round → receipt, settlement → scorecard, chat → board, nudge → live round, buddy request → requests. The SW `notificationclick` navigate-then-focus fix (sw.js:77-95) was written for a day that never came on web.
- **Notification categories with actions.** Buddy request → Accept/Decline as APNs actionable buttons (server RPC `friend_respond` is ready). Tee-sheet doorbell → "Open the pencil". Invite → Accept (`respond_invite`), which today sends NO push at all despite the UI promising one — the cheapest win in this slice is an `invite_golfer` → `push_nudges` fan-out (server change, one migration).
- **Rich push.** Round post pushes could carry the photo (`rounds.photo_path` → signed URL in a Notification Service Extension) and the band phrase; the fn's `headline()` split already isolates the result line.
- **Badge counts + a real inbox.** Web has no unread badge, only two localStorage "seen" marks (`cs_board_seen_<league>`, `cs.seen.<profile>`) and a digest sentence. Native should: persist a per-profile seen cursor SERVER-side (one small table or a `profiles` column — a phone and a desktop should agree), show app-icon badge for actionable items only (requests + invites + open live rounds — NOT chat volume, per guardrails), and turn `#notifBanner + #homeRequests + upNext "Needs you"` into one Inbox/Requests screen.
- **Activity feed.** Keep Home's merged stream but fetch it as ONE RPC (today: `home_feed` + `posts` across leagues + `post_kudos` + `post_comments` + `league_members` names + `my_friends` + signed URLs = 6-7 round trips on every open, all repeated on every realtime INSERT). Propose `home_stream(p_since)` returning rounds + posts + social counts + names in one page, cursor-paginated, and a per-league `board_page(p_league, p_before)` instead of `limit(120)` ascending + full re-render on every insert. Bucket rendering (Today / This week / Earlier, cap 8) is a good UX rule to keep; implement it as sections, not `<details>`.
- **Realtime granularity.** Subscribe to `posts` INSERT for ALL memberships (one channel with `in.(...)` filter or one per league) so Home updates without the league being "open"; apply inserts incrementally (the row is in the payload) rather than refetching standings + feed + home. Keep the 250 ms social debounce.
- **Share sheet.** `UIActivityViewController` with the PNG + text + URL together (web has to choose files OR url — `navigator.share` with files drops the url, so the recap card and the link are two separate taps today). Generate the recap/settlement cards natively (SwiftUI/Skia or an `ImageRenderer`) — the canvas code is the SPEC (5616-5838), but the fonts (Charter/IBM Plex Mono) and the marker `Path2D` glyphs (`window.MARKERS`) must be bundled. Keep the "share = publish" consent copy on the link button.
- **Reactions.** Long-press tray + 6-emoji palette maps naturally to a context menu / haptic tray; keep the one-write-path rule (`rxWrite`: never fall back to a different emoji on error).
- **Board composer.** Web overloads `#chatIn` for both chat and announce (📣 button). Native: an announce sheet for the Pro, chat input for everyone, both still writing to `posts`.
- **Mute vs push.** Muting a member should ALSO stop their pushes to you; today it does not (push fn ignores `mutes`). Fix in the fn (join `mutes` when filtering recipients) — server change, applies to both transports.
- **System-post volume.** Everything `system` pushes unconditionally, including index changes, declared rounds and draft picks. Before native launch add a `notify_league_events` flag or reclassify `system` sub-kinds (e.g. `posts.subkind`) so the fn can curate. The memory-layer guardrail ("every push names an emotion") is currently violated by "X changed their index".
- **Email on native** — nothing to build; keep the season email and add the `/?unsub` handler to Universal Links (or just let it open in Safari; it is a one-screen page).
- **Event boards** need realtime + reactions parity or they will feel dead next to the league board; today they are a plain list fetched once.
- **Drop from the phone:** the full-screen `#boardFull` overlay/body-lock machinery (5340-5375), the `visualViewport` keyboard hacks, the SW push handler, localStorage seen-marks, VAPID key.

---

## 10 · Open questions

1. **Is the `friendships` webhook actually configured in prod?** The push fn branch exists and the migration header says "second webhook on friendships", but neither deploy runbook lists it (only `posts` and `push_nudges`), and CLAUDE.md names only two. Verify with `pg_get_triggerdef` (masking `x-push-secret`). If absent, buddy requests currently produce no push and no email.
2. **Is the `email_queue` / `cancellation_notices` → `season-email` webhook pointed at the right function?** The D68 landmine says it was once mis-pointed at `push`. Same verification.
3. **APNs secrets** — D98 says the APNs key survives; are `APNS_P8/KEY_ID/TEAM_ID` set in Supabase secrets, and is `APNS_TOPIC` = `app.cupseason.ios` the bundle id the Expo app will ship with?
4. **`device_tokens.platform` CHECK is `('ios')` only** — Android (native-arc Phase C) needs a migration; should it land now?
5. **Author exclusion on `system`/`moment` posts with `member_id NULL`** (squad lead changes, month closes, engine posts) pushes to the poster too — intended?
6. **Push for invites** (`invite_golfer`) — UI copy promises a notification (16363, 15946); none is sent. Add a `push_nudges` fan-out?
7. **Push for reactions/comments on your round** — none today; the digest treats them as news. Wanted as a (muted-by-default?) class, or kept in-app only per guardrails?
8. **Server-side seen cursor** — is a cross-device unread state worth a migration, or is per-device fine for a phone-first product?
9. **`home_feed` shows muted members' rounds** (documented). Native surfaces rounds more prominently (feed + pushes) — revisit?
10. **Recap share has no card** (only a link + public page); the season email is the artifact. Should native draw a recap card, or is the email + `/?share` recap page enough?
11. **Per-share OG for `/?join` and `/?claim`** — still static (F6). Native Universal Links will unfurl the same generic card in iMessage; is that acceptable for the claim funnel, the product's strongest acquisition path?
12. **Realtime for event boards and cross-league Home** — filter design (`league_id=in.(…)`) vs one channel per membership; Supabase channel limits per connection?
13. **`unfriend`** has no client call site — is removing a buddy intentionally unsupported in UI, or an oversight native should expose (App Store "block" expectations are met by mute + report, but "remove" is a common ask)?
