STATUS: CONTRACT READY (v1.3 · release-review corrections applied · first issued v1 · 2026-09-25 · Claude, branch claude/social-course-backend-2026-09-26)

Changes after v1 are appended under "Revisions" at the bottom with a date; names and
shapes above that line do not change without a revision entry.

# Cup Season — connected social/course read + write contract (native ↔ server)

Every client-called function below is `SECURITY DEFINER`, `revoke all from public, anon`,
`grant execute to authenticated`. None is callable signed-out. All return ONE `jsonb`
object (compact, additive, skew-safe: unknown keys must be ignored; a missing key means
"old server"). All timestamps are ISO-8601 `timestamptz` strings; all dates `YYYY-MM-DD`
(parse with the local-date helpers, never `Date('YYYY-MM-DD')`).

**Skew rule for native:** if an RPC fails with `PGRST202` / `42883` / "could not find the
function" the server predates the migration — hide the door (comments, bell, course
people) rather than show an error. Any other error = a failed read (L-32), keep what is
on screen.

Migrations (not yet deployed; Codex deploys after review):
- `20261207090000_the_round_keeps_its_conversation.sql` — comments, threads, notifications, prefs
- `20261208090000_a_course_keeps_its_circle.sql` — `course_page`, `posted_rounds_social`

## 0 · Shared objects

`person` (used everywhere a human is shown):
```json
{ "id": "uuid", "name": "Theo Park", "marker": "saguaro|null", "handle": "theo|null" }
```
`name` is `profiles.display_name`. Deleted profiles never appear (their rows are dropped,
not renamed).

### The circle (who may see whose posted rounds)
The server predicate `home_feed` already uses, restated once in `_social_circle(viewer)`:
**me ∪ accepted friends (either direction) ∪ anyone I share a league with ∪ anyone I
share an event with.** `discoverable='everyone'` does NOT widen it (that is a search
gate, not consent to publish scores). Relation priority for labels: `me` > `friend` >
`league` > `event`.

A posted round R (owner O) is visible to viewer V iff: V signed in, R exists,
`not R.voided`, O's profile not deleted, O ∈ circle(V), and **no mute either direction**
between V and O (`mutes` is the product's block). Invisible and non-existent answer
identically (`not_visible`) — no existence leak.

## 1 · Posted-round comments (one thread per posted round)

Storage: `post_comments` is EXTENDED (no parallel table): new nullable columns
`round_id → rounds(id) on delete cascade`, `profile_id → profiles`, `parent_id`,
`root_id` (→ post_comments, on delete set null), `client_id uuid`; `post_id` and
`member_id` become nullable; check `post_id is not null or round_id is not null`.
A round-thread comment has `round_id` set and `post_id` null. The legacy board policy
(`comments_read`) keys on `post_id`, so round-thread rows are invisible to direct
selects and to Realtime — they are read only through the RPCs below.
`round_comments` / `add_round_comment` (scheduled rounds) are untouched.

The thread a golfer reads = round-thread comments on R **plus** every legacy board
comment on any `posts` row with `round_id = R` that the viewer can already read (league
board rules unchanged). Legacy rows come back with `origin: "board"` and
`can_reply: false` (a reply would expose a league-only conversation to friends).

### `posted_round_thread(p_round uuid, p_focus uuid default null)` → jsonb
Send `p_focus` ONLY when opening a target comment (a notification, a just-sent comment).
One function, no overload: a one-argument call still works. If the server predates v1.3
(`PGRST202` on the two-argument call), retry with `p_round` alone.
```json
{
  "ok": true,
  "round": {
    "id": "uuid", "owner": { person }, "is_mine": false,
    "gross": 79, "holes": 18, "played_on": "2026-09-20",
    "course": { "api_course_id": "12345|null", "name": "North Grove Municipal|null",
                "label": "raw course_label", "tee_name": "White|null", "tee_key": "white@70.1/124|null" },
    "photo_path": "owner-uuid/…jpg|null"
  },
  "can_comment": true,
  "comment_block_reason": null,
  "thread": { "state": "none", "following": false, "muted": false },
  "notify_prefs": { "own_round": true, "replies": true, "followed": true },
  "count": 240,                          // the true total of visible comments
  "page": { "newest": 200, "limit": 200, "truncated": true, "focus_id": "uuid|null" },
  "comments": [ comment, … ]            // display order (oldest first) — see below
}
```
Not visible: `{ "ok": false, "reason": "not_visible" }`. Signed out: `{ "ok": false, "reason": "signed_out" }`.

`comments` = the NEWEST 200 visible comments, plus — when `p_focus` names a visible
comment of this round outside that page — the focus, its visible parent and its visible
root; all sorted oldest first. `page.newest` = how many came from the newest page;
`page.truncated` = older comments exist that are not returned; `page.focus_id` = the focus
id when it is visible and returned, else `null`. A focus that is hidden, removed, by a
deleted or muted-either-way author, from another round, or made up is answered EXACTLY
like no focus (nothing disclosed). There is no older-page cursor; the web prints "The
newest N of M comments." when truncated.

`comment_block_reason` ∈ `null | "blocked" | "not_visible"`. `thread.state` ∈ `"none" | "following" | "muted"`.

`comment`:
```json
{
  "id": "uuid", "round_id": "uuid",
  "parent_id": "uuid|null",           // the comment this one answers
  "root_id": "uuid|null",             // top-level comment it hangs under (null = top-level)
  "reply_to": { "id": "uuid", "name": "Mara Chen" } ,   // null when top-level OR parent no longer visible
  "author": { person },
  "body": "Did the putt on 18 drop?",
  "created_at": "2026-09-25T17:02:11.123Z",
  "origin": "round",                  // "round" | "board" (legacy league-board comment)
  "is_mine": true,
  "can_reply": true
}
```
Render: group by `root_id ?? id`; replies under their root, oldest first. A reply whose
root is not in the list renders top-level. Hidden (moderated / author-removed),
deleted-author and muted-either-way comments are never returned.

### `add_posted_round_comment(p_round uuid, p_body text, p_parent uuid default null, p_client_id uuid default null)` → jsonb
- body trimmed, 1–500 chars (`22023` "Say something first" / "Keep it under 500 characters").
- `p_parent` must be a visible round-thread (`origin:"round"`) comment of **the same
  round**; otherwise `22023` "That reply lost its comment". Reply depth: stored parent is
  the comment answered; root is the parent's root (flat, one visual level).
- Not visible / blocked → `42501` "You can only comment on rounds you can see".
- **Idempotent:** send a fresh `p_client_id` (UUID) per compose; retries reuse it. Same
  author + client_id → the original comment is returned with `"replayed": true` and no
  second notification. Same client_id with a different round/body/parent → `22023`
  "That comment was already sent differently".
- Rate guard: 30 comments / 10 minutes / author → `P0001` "Easy — try again in a minute".
- Success:
```json
{ "ok": true, "replayed": false, "comment": { comment }, "count": 5 }
```
- **Drafts:** clients keep the draft until `ok:true` arrives; on any error the draft stays.

### `remove_posted_round_comment(p_comment uuid)` → jsonb
Author only (soft: `hidden_at`, reason `author_removed`). `{ "ok": true }` /
`42501`. Replies stay; their `reply_to` becomes null.

### Reporting / moderation (existing RPCs, extended)
`report_content(p_kind => 'comment', p_comment => <id>, p_reason => text)` now accepts
round-thread comments the reporter can see. `hide_content('comment', id)`: founder, or a
Pro of any league the round's owner plays in. `unhide_content('comment', id)` for
round-thread comments: founder only. `moderation_queue()` gains `comment_body`,
`comment_author`, `comment_round_id` keys (additive). Mute = `set_mute` (unchanged).

## 2 · Thread follow / mute and notification preferences

### `set_round_thread_state(p_round uuid, p_state text)` → jsonb
`p_state` ∈ `"following" | "muted" | "none"`. Requires the round to be visible.
`{ "ok": true, "state": "following" }`. Bad state → `22023`.
Muted beats everything for that thread: no notification of any kind from it.

### `social_notify_prefs()` → jsonb
`{ "own_round": true, "replies": true, "followed": true }` (defaults true; no row = defaults).

### `set_social_notify_prefs(p_own_round boolean default null, p_replies boolean default null, p_followed boolean default null)` → jsonb
Null = leave unchanged. Returns the same shape as `social_notify_prefs()`.

## 3 · Persistent in-app notifications

Table `social_notifications` (RLS on, NO direct grants — RPC-only). One row per
(recipient, comment). Written inside `add_posted_round_comment`'s transaction.

Fan-out for comment C by actor A on round R (owner O), parent author P:
| kind | recipient | pref |
|---|---|---|
| `reply` | P (author of the comment answered) | `replies` |
| `own_round` | O | `own_round` |
| `followed` | every profile with thread state `following` on R | `followed` |

One row per recipient, priority `reply` > `own_round` > `followed`. Never: A itself; a
recipient who muted the thread; a mute either direction between recipient and A; a
recipient who cannot see R; deleted profiles.

### `my_notifications(p_before timestamptz default null, p_limit integer default 30, p_before_id uuid default null)` → jsonb
The cursor is the PAIR `(created_at, id)`, strictly after the sort `created_at desc, id desc`.
Next page: pass `p_before = next_before` AND `p_before_id = next_before_id`. `p_before`
alone keeps the v1 meaning (timestamp only) for old clients. One function, no overload.
```json
{
  "ok": true,
  "unread": 2,
  "items": [
    {
      "id": "uuid",
      "kind": "reply",                 // "reply" | "own_round" | "followed"
      "created_at": "…", "read": false, "read_at": null,
      "actor": { person },
      "round_id": "uuid", "comment_id": "uuid",
      "excerpt": "Caught the left edge. Finally.",   // ≤140 chars of the comment
      "course_name": "North Grove Municipal|null",
      "round_owner_name": "Alex Reed",
      "link": { "kind": "round_comment", "round_id": "uuid", "comment_id": "uuid",
                "web": "/?round=<round_id>&comment=<comment_id>" }
    }
  ],
  "next_before": "timestamptz|null",   // the LAST returned item's created_at, null when no more
  "next_before_id": "uuid|null"        // the LAST returned item's id, null when no more
}
```
`p_limit` clamped 1–50. Identical timestamps across a page edge are never skipped or repeated. Items whose comment was hidden/removed, whose round is no longer
visible, or whose actor is deleted/muted-either-way are dropped at read time and are not
counted in `unread`. Newest first.

Sentence producers (both clients print exactly these):
- reply → "**{actor first}** replied to your comment."
- own_round → "**{actor first}** commented on your round."
- followed → "**{actor first}** commented in a conversation you follow."

### `notification_badge()` → jsonb
`{ "unread": 2 }` — cheap; poll on foreground / after actions.

### `mark_notifications_read(p_ids uuid[] default null, p_all boolean default false)` → jsonb
Marks the caller's own rows only (others' ids are ignored silently). Returns
`{ "ok": true, "unread": 1 }`. Opening a notification = call with `[id]`, then open
`posted_round_thread(round_id)` and scroll to/highlight `comment_id`.

### Push (dark until flipped)
Server inserts `push_nudges(kind='comment', payload={round_id, comment_id,
notification_id, profile_id: actor})` ONLY when `app_flags.social_comment_push.enabled`
is true (seeded `false`). The Edge `push` function learns the kind (`cs.kind = "comment"`,
ids `round_id`, `comment_id`, `notification_id`, `profile_id`). Native: add `comment` to
`PushKind`/`PushRoute` → open the thread at `comment_id` and call
`mark_notifications_read([notification_id])`. Until the flag is flipped nothing rings.

## 4 · Feed augmentation — `posted_rounds_social(p_rounds uuid[])` → jsonb
For any feed (native `home_feed`, web board posts with `round_id`). Max 60 ids; invisible
or unknown ids are silently omitted.
```json
{
  "items": [
    {
      "round_id": "uuid",
      "comment_count": 4,
      "can_comment": true,
      "thread_state": "none",
      "course": {                               // null when the round has no api_course_id
        "api_course_id": "12345", "name": "North Grove Municipal",
        "circle_golfers": 3,                    // distinct circle golfers (incl. you) with a visible round there
        "faces": [ { person }, … ]              // ≤3, friends first, excludes the viewer
      }
    }
  ]
}
```
Course door copy: "Your friends at {name}" when `faces` non-empty, else just `{name}`;
sub-line "See their rounds and course bests".

## 5 · Course page — `course_page(p_course_id text, p_tee text default null, p_holes integer default null)` → jsonb

`p_course_id` = `api_course_id` (the stable course id; free-typed rounds never appear —
`course_key` returns null for them). `p_tee` = a `tee_key` from `tees[]` (opaque — echo it, never parse or build it); `p_holes` 9|18.
Invalid/absent selections fall back to the default (most eligible rounds at 18, ties →
most recent).

```json
{
  "ok": true,
  "course": { "api_course_id": "12345", "name": "North Grove Municipal",
              "city": "Oak Valley", "state": "CA", "country": "USA" },
  "scope": { "key": "circle", "label": "Your circle",
             "best_label": "Your circle best",
             "note": "From your rounds and the rounds of friends, league mates and event mates. Not an official course record." },
  "selection": { "tee_key": "white:male:18@70.1/124", "tee_name": "White", "holes": 18 },
  "tees": [ { "key": "white:male:18@70.1/124", "name": "White", "gender": "male|female",
              "rating": 70.1, "slope": 124, "rounds": 7 } ],
  "holes_options": [ { "holes": 18, "rounds": 9 }, { "holes": 9, "rounds": 2 } ],
  "unknown_tee_rounds": 3,
  "best_unavailable": null,            // "nine_side_unrecorded" when holes = 9 (best, my_best, every best_in_selection are null)
  "best": {
    "gross": 72, "tied": false, "eligible_rounds": 7,
    "holders": [ { "round_id": "uuid", "person": { person }, "played_on": "2026-09-20" } ]
  },
  "my_best": { "gross": 84, "round_id": "uuid", "played_on": "2026-09-15", "rounds": 3 },
  "people_total": 4,
  "people": [
    {
      "person": { person }, "relation": "friend",      // "me"|"friend"|"league"|"event"
      "rounds_total": 5, "latest_played_on": "2026-09-20",
      "best_in_selection": { "gross": 72, "round_id": "uuid", "played_on": "2026-09-20" },
      "rounds": [                                        // newest first, ≤30 per person, ALL tees/holes
        { "round_id": "uuid", "played_on": "2026-09-20", "gross": 72, "holes": 18,
          "tee_key": "white:male:18@70.1/124|null", "tee_name": "White|null",
          "has_photo": true, "in_selection": true }
      ]
    }
  ]
}
```
`best`/`my_best`/`best_in_selection` are `null` when nothing is eligible. `holders` has
>1 entry (and `tied: true`) when several rounds share the low gross; ordered by
`played_on` ascending (first to post it first), one per round.

**Best semantics (authoritative, computed over ALL rounds in scope — no page cap):**
eligible = visible to the viewer (circle, no mute either way, owner not deleted) ∧ same
`api_course_id` ∧ `not voided` ∧ `tee_key` KNOWN and equal to the selection ∧
`holes_played` = 18 = the selection. **Nines are never eligible** (D391 amended): no round
records which nine was played, so with `holes = 9` the page lists history only and returns
`best_unavailable: "nine_side_unrecorded"`. Gross only; no net, no points, no scoring change.
It is labelled **"Your circle best"**, never "course record": no existing consent lets
Cup Season publish a stranger's score app-wide, so the scope is the viewer's circle and
the label says so (see D-entry).

**Tee identity (never invented):** `rounds` carries no tee column. A round's tee is KNOWN
only when the cached `api_course_tees` rows at exactly its `(rating, slope)` resolve to ONE
layout = one (tee name, gender, number of holes), each stated by the cache. The tee named
after the last " · " in `course_label` may narrow the candidates by name, but a name never
settles two layouts (men's/women's of one name, or gender-less 18/9 cards). Anything else →
`tee_key: null`, `tee_name: null`; the round stays in history, never in a best.
`tee_key` is OPAQUE (currently `name:gender:holes@rating/slope`, e.g. `white:male:18@70.1/124`).
Nines appear in history and the hole filter but are never compared (see above).

People order: `best_in_selection.gross` asc (nulls last), then name. Everyone in the
circle with ≥1 visible round at the course appears (any tee), including me.

## 6 · Web deep link
`/?round=<round_id>&comment=<comment_id>` opens the round thread with that comment
highlighted (web client handles it after sign-in).

## Revisions
- **v1.1 · 2026-09-25 (clarifications, no shape change).** `tees[].rounds` = visible rounds
  on that tee across both hole counts. `holes_options[].rounds` = visible rounds on the
  SELECTED tee at that hole count (only counts > 0 are listed). `people[].relation` is
  one value per golfer by the priority above. `posted_round_thread.can_comment` is
  always `true` when `ok:true` (a viewer who could not comment gets `not_visible`), so
  `comment_block_reason` is `null` today and reserved. Implemented and tested: 82
  assertions pass on the full chain (`node tests/social-course-database.mjs`).
  Generated Swift names are `Rpc.<function_name>` (all return `JSONValue`).
- **v1.1 · push kind.** Edge `push` now knows `cs.kind = "comment"` with ids
  `round_id`, `comment_id`, `notification_id`, `profile_id` (actor). Nothing sends it
  until `app_flags.social_comment_push.enabled` is flipped true.
- **v1.1 · moderation.** A pre-existing constraint made every comment report fail
  (23514); migration 1 widens `content_reports_target` to accept `comment_id`. Native's
  existing comment report path starts working once the migration is pushed.
- **v1.2 · 2026-09-25 · copy law (preflight vocabulary §4.22/§4.36).** `course_page.scope.note`
  is now: "From your rounds, your friends' rounds and the rounds of the golfers in your
  seasons, Ryders and Majors. Not an official course record." Relation labels the web
  prints (native should match): `me` → "You", `friend` → "Friend", `league` → "In your
  seasons", `event` → "In your Ryders and Majors" — never "league mate" or "event".
  Other copy the web prints (reuse verbatim): thread head "Conversation", empty "The
  conversation is yours to start.", composer labels "Add a comment" / "Your reply",
  buttons "Comment" / "Reply" / "Follow" / "Following" / "Mute conversation" /
  "Unmute conversation", course door sub-line "Who of yours has played here, and your
  circle's best", best eyebrow "Your circle best · gross", tie "Shared best", unknown
  tees "N round(s) without a tee we can prove is/are listed but never compared."
- **v1.2 · web shipped against this contract** (committed on the branch): bell + inbox
  + prefs, the conversation on the posted-round receipt (friends outside the league
  open it via `posted_round_thread` when `round_card` refuses), Home wire doors, board
  round-post door, course sheet, `/?round=&comment=` deep link. Nothing changed shape.
- Repo copy: `docs/planning/2026-09-25-d391-social-course-contract.md` (same text).
- **v1.3 · 2026-09-25 · release-review corrections (all additive for native; migrations
  were corrected in place — they have never run in production — and drop the v1
  signatures so no overload can exist).**
  1. `posted_round_thread(p_round uuid, p_focus uuid default null)`: returns the NEWEST
     200 visible comments (display order oldest first) plus a visible focus and its
     visible parent/root; new key `page { newest, limit, truncated, focus_id }`. Invisible
     focus → identical to no focus. Old one-argument calls unchanged in shape.
  2. `my_notifications(p_before, p_limit, p_before_id uuid default null)`: composite cursor;
     new key `next_before_id`. `next_before` is now the LAST returned item's timestamp.
  3. Web: every new door (course best/history row, notification, deep link, feed
     conversation door) opens FRESH — `posted_round_thread` is the visibility gate, a
     cached receipt is never shown for a round now voided/deleted/muted (cache dropped,
     "That round isn't available any more."). `round_card` still decides points; a friend
     with no shared league opens the thread's facts with no points. Native does the same.
  4. `course_page`: nines are never compared; new key `best_unavailable`
     (`null | "nine_side_unrecorded"`); web copy: "Nines aren't compared: which nine was
     played isn't recorded. They stay in each golfer's history."
  5. `tee_key` is opaque and now `name:gender:holes@rating/slope`; a tee is known only when
     the matching cache rows are ONE (name, gender, holes) layout with gender and holes
     stated. Rounds that were "known" by name alone under v1 may now be unknown.
  Generated Swift: `Rpc.posted_round_thread(p_round:, p_focus: UUID? = nil)`,
  `Rpc.my_notifications(p_before:, p_limit:, p_before_id: UUID? = nil)`.
  Tests: `node tests/social-course-database.mjs` → 102 assertions (209/210-comment thread
  with old and new focus, hidden/foreign/made-up/muted focus undisclosed, 60+ notifications
  at ONE timestamp paged with the pair cursor, tee layouts, nines).
