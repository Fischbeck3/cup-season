# Scheduled rounds → a first-class round object (build-toward plan)

> **STATUS: BUILT 2026-07-18 (all six stages).** Migration `20260718192400_round_object`
> + the `weather` Edge Function + the client (`openRoundSheet` detail sheet, declare
> course search, calendar/watch/Home entry points, Home "Coming up" rich cards).
> Ships client-first (deploy-skew-safe); needs `db push` + `functions deploy weather`
> for live data. The one true-scoping caveat (`league_id`) is in the migration,
> unused — retire the `shared_league` proxy when per-league schedules matter.

Written 2026-07-18 from pilot feedback (batch 3). Today a scheduled round is a
calendar row: a date, a course label, a note, a tee time, and a `tagged[]` list.
The pilot wants to **click into it** — a lightweight event/message-board thread
per round, with course info, weather, who's-in, and chat — and wants the **Home
feed** to carry the social planning picture while the **League Room stays
league-scoped** (the scoping shipped in `4991af9`).

This is the staged path there. It adds **no paid dependency** (weather is
keyless; course data is already cached), which keeps it inside the bank-account
contract.

## What already exists (the foundation)

- `scheduled_rounds` (profile-scoped): `play_on`, `course_label`, `note`,
  `tee_time`, `tagged[]`. RPCs: `declare_round`, `scratch_round`, `retag_round`.
- `my_schedule(from,to)` returns each row with social flags: `mine`,
  `is_friend`, `shared_league`, `tagged_me`, `tagged_names`.
- The course cache — `api_courses` (incl. **`latitude`/`longitude`**, rating),
  `api_course_tees`, `api_course_holes` — already holds everything a detail
  view needs about the course.
- Surfaces: League Room calendar (grid + list + watch list, now league-scoped),
  Home `renderUpNext` (keeps buddies), the "I'm in" watch-list add.

## The arc — six stages, Stage 1 is the keystone

**Stage 1 — the round detail sheet ("click into it"). THE KEYSTONE.**
Tapping a scheduled round (from the calendar, the watch list, or Home) opens one
detail sheet — the container every later stage hangs on. It shows date + tee
time, course, tagged players, note, and consolidates the manage actions
(cancel / edit group / change date) that today are scattered.
- Schema: add `scheduled_rounds.course_id uuid` (nullable FK → `api_courses`) so
  the sheet can pull real course data; wire the course picker into
  `declare_round` (it already flows through the course search). Small migration.
- Client: one `openRoundSheet(id)`; point the calendar/watch/Home taps at it.
- Everything below layers into this sheet.

**Stage 2 — RSVP / "who's in".** Tagged players (and league-mates who can see
it) set In / Maybe / Out. New `round_rsvp(round_id, profile_id, status,
updated_at)` + `set_round_rsvp(round_id, status)` RPC. The existing "I'm in"
button becomes a real RSVP; the sheet shows the attendee list with statuses.
Turns a plan into a coordination object. Independent of 3–6.

**Stage 3 — comments (the "message board" part).** A thread on the round,
mirroring the board's comment pattern. New `round_comments(round_id,
profile_id, body, created_at)` + `add_round_comment` RPC (optionally reactions,
reusing the `post_kudos` emoji-chip pattern). Rendered in the sheet. Independent
of 2, 4–6.

**Stage 4 — course info.** With `course_id` linked (Stage 1), the sheet shows
the real course from the cache: name, city, tee rating/slope, par, hole list.
Pure client — read `api_courses`/`api_course_tees`/`api_course_holes`. No new
backend.

**Stage 5 — weather.** With the course's `latitude`/`longitude` (from
`api_courses`) + `play_on`, fetch a forecast. Use **Open-Meteo** (free, keyless)
behind a small cached `weather` Edge Function — routing through `*.supabase.co`
keeps the locked CSP `connect-src` intact and lets us cache so we don't refetch
per render. Forecast only inside the ~16-day window; older/further rounds show
nothing. Temp / conditions / wind in the sheet. **No paid API, no key to leak.**

**Stage 6 — Home enrichment.** Home surfaces upcoming rounds (yours + buddies')
as rich cards that tap into the Stage-1 sheet — course glance, weather glance,
RSVP count. This is where "more visibility on the Home feed" lands; the League
Room stays league-scoped, but both open the same detail sheet.

## Dependencies & order

```
Stage 1 (detail sheet + course_id)  ──┬──▶ Stage 4 (course info)   [needs course_id]
                                      ├──▶ Stage 5 (weather)       [needs course lat/lon → course_id]
                                      └──▶ Stage 6 (Home cards)    [needs the sheet]
Stage 2 (RSVP)      ── independent, layers into the sheet
Stage 3 (comments)  ── independent, layers into the sheet
```

Stage 1 first; then 2, 3, 4, 5, 6 in any order (2 and 3 are the highest social
value; 5 is the highest "wow"). Each stage is additive and deploy-skew-safe:
new columns default null, new RPCs are called with fallbacks, the client hides
a stage's UI until its migration lands.

## The one true-scoping caveat to retire along the way

The League Room scope uses `shared_league` ("shares *any* league with me") as a
proxy, because scheduled rounds aren't tied to a league. If per-league schedules
ever matter (a round that belongs to *this* league's board), Stage 1's
`course_id` migration is the natural place to also add an optional
`league_id`/`event_id` — then the League Room can scope to *its own* rounds
exactly, and a round can post to a specific board.

## Principles this serves

#5 Feels Alive (a round you can rally the crew around, not just a date) · #2 Low
Friction (one sheet, one tap, all the info) · the growth loop (a shared round
with weather + who's-in is a reason to open the app before you tee off). No paid
dependency — it stays free to run.
