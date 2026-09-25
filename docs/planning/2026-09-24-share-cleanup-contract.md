# Share cleanup contract (D385 durable withdrawal) · 2026-09-24

For Codex's native half and the web. Migration `20261201090000_a_withdrawn_photo_is_gone.sql`, Edge Function `supabase/functions/share-cleanup`. **Additive only:** no existing RPC changes shape, and `withdraw_round_shares(p_round) → text[]` (already in Codex's source contract) is unchanged.

## Why

Revoking a share disables the app's page. It does **not** remove the public bytes at `shared/{token}.jpg|png`. Before this change, both clients threw cleanup failures away, and an old client (986) never cleaned at all. Now every revocation, from any path, creates a durable obligation that stays open until the server **confirms** that both copies are gone from Storage.

## The obligation (`public.share_cleanup`, one row per revoked token)

| status | meaning |
|---|---|
| `pending` | revoked; the copies may still be public; nothing has failed yet |
| `error` | an attempt did not remove them; `last_error` says why; `next_attempt_at` is the next try (2, 4, 8 … minutes, at most a day) |
| `completed` | the server checked `storage.objects`: neither `{token}.jpg` nor `{token}.png` exists |

A trigger on `shares` creates the row whenever `revoked` turns true: remove, replace, delete, "Turn off this link", a cancelled share, or an old client. The owner can read their own rows; clients never write them.

## RPCs (all `authenticated`, owner-scoped; nothing new for `anon`)

| RPC | returns | use |
|---|---|---|
| `withdraw_round_shares(p_round uuid)` | `text[]` tokens | unchanged: revoke the round's links and get every token to clean (call **before** `delete_round`) |
| `confirm_share_cleanup(p_token uuid)` | `{token, status, remaining, last_error}` | after the client removed `{token}.jpg` and `{token}.png` through the Storage API. The server counts what is still stored: `completed` with `remaining: 0`, or `error` with the count. Never report success from the Storage call alone |
| `my_share_cleanup()` | `[{token, kind, ref_id, status, attempts, last_error, requested_at, next_attempt_at, completed_at, paths}]` | the owner's own obligations, newest first; the receipt/settings state |
| `retry_share_cleanup(p_token uuid)` | `{token, status, paths}` | the owner's retry: back to `pending` (the service sweep picks it up; the client may also remove `paths` and confirm) |

Service role only (Edge Function): `_share_cleanup_due(p_limit)`, `_share_cleanup_report(p_token, p_error)`.

## Client flow (both clients)

1. Remove, replace or delete, as today (the server revokes).
2. `withdraw_round_shares` → for each token, Storage `remove([t.jpg, t.png])` → `confirm_share_cleanup(t)`.
3. If any confirm is not `completed`, **say so**: the photo is off its link, but a public copy is still being removed. Offer "Try again", which calls `retry_share_cleanup` and then repeats step 2. Never tell the golfer it's gone until `completed`.
4. Old clients and interrupted clients need nothing: the service sweep completes their rows.

Native decoding: status is a string; treat unknown values as `pending`. `next_attempt_at` is null once completed.

## Deploy owed (owner; not done)

`supabase functions deploy share-cleanup --no-verify-jwt`; `supabase secrets set SHARE_CLEANUP_SECRET=…`; in the dashboard, a Database Webhook on `public.share_cleanup` for **INSERT and UPDATE** that calls `share-cleanup` with header `x-cleanup-secret`. Verify the webhook's target from the database, per CLAUDE.md, and mask the secret. Until the webhook exists the obligation is still durable and visible, and client confirms still complete it.

## Evidence

`tests/fixtures/launch-repair/storage-cleanup.sh` against a local Supabase stack (real Storage API and Edge runtime), 20/20: an old client's remove and delete, a Storage failure then a retry, an interrupted client, the confirm refusing while copies remain, owner isolation, and a call without the secret. **Local integration evidence only**; production Storage has not been exercised.
