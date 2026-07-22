# Photos arc 2 — retrieval, identity, travel

**Status:** DESIGN APPROVED (owner, 2026-07-22) — build on explicit "build it,"
one checkpoint per push. Successor to `spec/photos-arc.md` (D36 built capture;
this arc makes photos retrievable, makes them identity, and lets one travel).
**Lane:** Social/Growth seam; the D36 identity reversal is the arc's headline
decision (D58).

## Why (the finding)

Photos are write-mostly. Capture shipped (composer photo + scan, board-card
ground, recap-card backdrop, You-tab last-5 thumbs) but there is no
aggregation, no browse, no memory surface — a photo appears once in feed
scroll, then is effectively gone. Pilot flagged findability ("no idea where
round photos live"). D10 ranked the photo as THE "remember when" artifact;
capture without retrieval never compounds it.

---

## Ckpt 1 — retrieval (the memory half)

**1a · Receipts sheet.** Any posted round opened anywhere (feed card, You
recent, album) renders its photo full-bleed atop the receipt. Rows that
already carry `photo_url` (feed-signed) use it; older rows sign on demand —
one `createSignedUrl` at open, silent skip on failure. Pure client.

**1b · Season album.** League Room gains an **Album** pane: 3-column grid of
the league's round photos, newest first, month dividers. Tap → lightbox:
photo + one line (name · gross · band · course · date) + "Open the round" →
receipts sheet. Data = the league round query the feed already runs
(`photo_path` present); batched `createSignedUrls`, 1h TTL, same pattern as
the board. Empty state: "Photos land here when rounds carry them." Demo
diorama shows the same empty state — no fabricated photos.

**1c · Quiet-day resurface.** D27's fallback highlight renders its round's
photo as a thumb when one exists. Requires `home_feed` to return
`photo_path`: one `create or replace` migration. Skew rule: payload without
the field → no thumb, never an error.

**Cost:** one tiny migration (`home_feed` replace); rest client. No new
tables, no new RPCs, no anon-surface change. Decision-log: **non-entry**
(presentation of existing facts) — noted at the batch foot when D58 lands.

---

## Ckpt 2 — identity (the D36 reversal, D58)

**2a · Profile photo.** `profiles.photo_path`; file at `{uid}/avatar.jpg` in
the EXISTING private `media` bucket — current policies already fit
(own-prefix write/delete, signed-in read, 8MB/image-only caps hold). Golfer
card edit gains "Add a photo": square crop, client compression ~512px
(reuse the round-photo compressor). Write rides `set_profile` with a new
DEFAULTED `p_photo_path` param — skew-safe in both directions.

**2b · Avatar chips, marker as the floor.** Avatars render wherever identity
renders: feed author lines, members/roster, standings rows, comments, tour
card. Signed URLs batched at league/friends load (1h, same pattern).
**Fallback is always the marker — no gray-silhouette state exists.** Every
golfer has a face from day one; D36's marker survives as the guaranteed
identity floor. That fallback is what makes the reversal cheap.

**2c · Marker stamp on round photos.** Poster's marker medallion,
bottom-right, on photo-backed board cards and the album lightbox. Recap
canvas untouched (marker already center-stage). Attribution + brand mark —
the marker's new second job.

**2d · Per-league marker.** `league_members.marker` nullable override;
league surfaces resolve override → profile marker; You/global surfaces use
the profile marker. Changed from the members sheet (your own row), any
time — "seasonal" is freedom, not a mechanism. New definer RPC
`set_league_marker(p_league, p_marker)`, self-only, granted authenticated.

**2e · Moderation.** Avatars are signed-in-visible only (bucket already
private). `report_content` gains kind `profile_photo` → founder desk.
Pro-side takedown valve DEFERRED until real abuse appears (D19 precedent).

**Cost:** one migration (`profiles.photo_path` + `league_members.marker` +
`set_profile` param + `set_league_marker` + report-kind widen) + a client
pass (crop/upload, avatar chip component, stamp overlay, league marker
picker). **D58 logged BEFORE the migration** — CONFLICT with D36 named:
marker demoted from sole identity to floor + brand mark; owner call;
tradeoffs: moderation surface arrives, signing cost, crop UI.

---

## Ckpt 3 — the photo travels (growth, D59)

**Constraint:** the share page is anon; `media` is private; definer SQL
cannot sign storage URLs. Weighed: edge-function proxy (server machinery,
per-request cost) · signed-URL-in-payload (impossible from SQL) ·
**publish-by-copy (chosen)**.

**3a · Copy on mint.** New PUBLIC bucket `shared`. When a shared round
carries a photo, the mint flow also uploads the compressed copy to
`shared/{TOKEN}.jpg`, client-side (the sharer's device holds read access;
no server piece). Storage policies gate writes by the `shares` table
itself: insert/delete allowed only where the filename's token has a row
with `created_by = auth.uid()`. Flat token path — **no uid, no ids in the
URL** (D57 law holds). Public bucket = stable URL, zero signing.

**3b · Page render.** `share_info`'s round branch gains
`'photo': exists(copy)` (one `create or replace`; definer reads
`storage.objects`). The page renders the photo as the card backdrop under
the board card's dark wash. Marker stamp rides (2c). **Avatars never reach
the share page** — faces stay signed-in; the marker is the public face.

**3c · Revoke kills both.** Revoke deletes the copy, then revokes the
token. The copy is a snapshot: deleting the photo from the round later
does not reach the page until revoke — consistent, the share IS a snapshot.

**Publish consent:** the photo already went to the league board; tapping
"Share a link" is the publish act (D57's golfer-publishes spirit). The
button says so when a photo will travel: **"Share a link — card + photo."**
Logged as a D59 tradeoff.

**Cost:** one migration (bucket + policies + `share_info` replace) + mint/
revoke client work. **D59 logged BEFORE the migration** (extends D57).

---

## Cuts (named, not silent)

- Settlement + recap share pages stay photo-less in v1 (no single photo).
- Wrapped / season photo mosaic (the Record) — parks until season end; own
  design when unparked.
- Pro-side avatar takedown — deferred until real abuse (2e).
- True storage-level league ACLs — still launch-hygiene #34, unchanged.

## Skew & discipline rails (all three pushes)

- Every migration: explicit `grant execute ... to authenticated` + `revoke
  ... from public, anon` (D37). No anon-surface change in this arc except
  `share_info`'s replace (same grant set it already has; db-checks list
  unchanged at five).
- Client tolerates every missing column/param with the established
  retry-without pattern; photo fields absent → surfaces render photo-less,
  never error.
- `tests/preflight.mjs` before every push; checks 2/3/9 after any
  grant-touching push.
- Demo diorama never fabricates photos or avatars (marker floor covers it).

## Build order & exit criteria

Three pushes, in order, each independently shippable:

1. **Ckpt 1 live:** album pane + receipts photo + digest thumb; `home_feed`
   migration pushed.
2. **Ckpt 2 live:** D58 in the log · avatars with marker floor everywhere
   identity renders · stamp on photo cards · per-league marker · report
   kind widened.
3. **Ckpt 3 live:** D59 in the log · `shared` bucket + policies ·
   share-page photo backdrop · mint copies, revoke deletes both.

Arc done when: a photo posted in March is findable in July (album), every
face in the app is either a chosen photo or a marker (never empty), and a
shared round link shows the photo to someone with no account.
