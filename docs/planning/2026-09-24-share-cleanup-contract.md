# Share lifecycle and cleanup contract (D385) · 2026-09-24

The server half of Codex's `docs/planning/2026-09-24-native-audit-contract.md` (branch `codex/native-audit-repairs-2026-09-24`), for both clients. Migrations `20261201090000_a_withdrawn_photo_is_gone.sql` (the durable cleanup obligation) and `20261202090000_one_share_one_attempt.sql` (the lifecycle); Edge Function `supabase/functions/share-cleanup`. **Additive only:** `create_share`, `revoke_share` and `withdraw_round_shares` keep working for older clients.

## The lifecycle (the names and shapes in Codex's contract)

| RPC | returns |
|---|---|
| `prepare_round_share(p_round uuid, p_include_photo boolean, p_attempt uuid)` | `{token, created, include_photo, state, active, rotated?}` |
| `finish_round_share(p_attempt uuid, p_completed boolean)` | `{attempt, state, token, created, active, cleanup_pending}` |
| `round_share_status(p_round uuid)` | `{token, include_photo, cleanup_pending, cleanup:[{token,status,last_error,next_attempt_at}], preparing}` |
| `withdraw_round_shares(p_round uuid)` | `text[]`, unchanged |

What the server guarantees (each item is a verified scenario in `tests/fixtures/launch-repair/verify.py`):
- **Idempotent on the attempt.** The same `p_attempt` returns the same answer, however often it is called.
- **Reuse.** A *completed* live link whose recorded consent equals the request is reused (`created:false`), so a photo-less link stays photo-less. Upload copies only when `created:true`.
- **Rotation.** A changed consent, or a legacy link whose consent was never recorded, is rotated: the old link is revoked and its copies are queued for durable cleanup, and a new token is minted for this attempt (`created:true, rotated:true`). The server never guesses consent from which copies exist.
- **Concurrency.** A 15-minute lease. While another attempt is open, only a same-consent reuse may run beside it; anything else is refused with "This round is already being shared. Try again in a moment." No attempt ever borrows or revokes another's token.
- **Finish.** `completed:true` makes a link this attempt created durable. `completed:false` (cancelled or failed) retires **only** a token this attempt created and never completed; a reused, completed link is untouched.
- **Never reactivated.** A late or duplicate acknowledgement, an expired lease, or a withdrawal during the preparation (remove, replace or delete) can never make a revoked link live again. `active:false` says so.
- **Abandoned preparations** (the app died before the callback) are reclaimed when their lease lapses. The next `prepare` for that round does it, and so does every `share-cleanup` sweep: never-completed tokens are revoked, and their cleanup is queued.
- **`round_share_status` never mints.** `cleanup_pending` stays true until Storage is verified clean for every revoked token of the round. A missing token is not proof that the bytes are gone.

## The cleanup obligation (`public.share_cleanup`, one row per revoked token)

A trigger on `shares` creates the row whenever `revoked` turns true, whatever path revoked it: remove, replace, delete, turn off, a cancelled share, a lapsed lease, or an old client. Statuses:

| status | meaning |
|---|---|
| `pending` | revoked; the copies may still be public |
| `error` | an attempt did not remove them; `last_error` says why; `next_attempt_at` is the next try (2, 4, 8 … minutes, at most a day) |
| `completed` | the server checked `storage.objects`: neither `{token}.jpg` nor `{token}.png` exists |

Owner RPCs (`authenticated`, owner-scoped; nothing new for `anon`):
- `my_share_cleanup()`: the owner's obligations, for a receipt or settings state.
- `retry_share_cleanup(p_token)`: back to `pending`; returns the `paths`.
- `confirm_share_cleanup(p_token)`: after the client removed both copies through the Storage API. The server counts what is still stored and answers `completed` with `remaining:0`, or `error` with the count. A Storage call reporting success is not proof.

Service role only: `_share_cleanup_due`, `_share_cleanup_report` (which re-verifies before completing), and `_expire_share_attempts`.

## Client flow

Share: `prepare` → upload copies only if `created` → open the system sheet → `finish(completed: the sheet's real outcome)`. Persist unacknowledged attempts and retry `finish` on the next authenticated load. **Minting a link is not delivery**: say "shared" only on a real completion.

Withdraw (remove, replace, delete): as today, then `withdraw_round_shares` → Storage `remove([t.jpg, t.png])` → `confirm_share_cleanup(t)`. If any answer is not `completed`, say the photo is off its link but a public copy is still being removed, and offer "Try again" (`retry_share_cleanup`, then remove and confirm). The server sweep completes the obligation even if the client never returns.

## Deploy owed (owner; nothing here was deployed)

The migrations; then `supabase functions deploy share-cleanup --no-verify-jwt`; `supabase secrets set SHARE_CLEANUP_SECRET=…`; and a Database Webhook on `public.share_cleanup` for **INSERT and UPDATE** that calls `share-cleanup` with header `x-cleanup-secret`. Verify the webhook's target from the database (CLAUDE.md) with the secret masked. A scheduled call is optional; every webhook call also sweeps whatever is due, including lapsed preparations.

## Evidence (local only; production Storage never exercised)

- `tests/fixtures/launch-repair/run.sh`: a fresh PG17 cluster with the full chain and a reapply; the lifecycle, 13 checks.
- `tests/fixtures/launch-repair/storage-cleanup.sh`: a local Supabase stack (real Storage API and Edge runtime), 20 checks: an old client's remove and delete, a Storage failure then a retry, an interrupted client, confirm refused while copies remain, owner isolation, and a call without the secret.
