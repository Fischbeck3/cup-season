# Photos arc (#13) — one storage build, three checkpoints

Built 2026-07-18 (D36). This doc is the arc's map: what shipped, the decisions
that shaped it, and the dials the Pro holds.

## The three checkpoints (all shipped together)

**Ckpt 1 — round photos.** Private `media` storage bucket; quick post gets
"Add a photo" (client-side compression to ≤1600px JPEG before upload, own-
`{uid}/` prefix writes only); the path rides on `rounds.photo_path`; the full
board's story cards render it via one batched signed-URL call (1h expiry).
Decisions: **no profile photos in v1** (the ball marker IS identity — revisit
only if the pilot asks) · visibility is signed-in-only at the storage layer,
league-scoped at the UI layer for v1 (true storage-level league ACLs deferred;
noted for launch hygiene #34).

**Ckpt 2 — the shareable layer.** The Round Recap Card composites the round's
photo as a cover-cropped backdrop under a heavy brand-dark wash — every text
position unchanged, the card keeps its one fixed face.

**Ckpt 3 — scorecard scan (D36).** Composer "Scan the card" → `scan` Edge
Function → claude-opus-4-8 vision with structured outputs (schema-guaranteed
JSON: course, date, par row, up to 6 player rows of 18 holes; 0 = unreadable)
→ the D34 grid revives as the confirm surface (model proposes, golfer fixes,
§16 receipts hold) → posts with `round_holes` + the scan photo attached.
Multi-row cards ask "whose card is this?"; **stretch shipped:** partner rows
mint claim links (`scan_claims`, the same `/?claim=` funnel as tee-sheet
guests) — one scan can post the whole foursome, and each claim is an invite.

## Cost discipline (the founder's bank-account contract)

Worst case is a number chosen in advance:

- **Kill switch + caps in `app_flags.scan`** — `enabled`, `daily_per_user`
  (5), `monthly_global` (400). Checked server-side BEFORE the paid call; all
  fail CLOSED. Change them with an UPDATE in the SQL editor, no deploy:
  `update app_flags set value = jsonb_set(value,'{enabled}','false') where key='scan';`
- **Prepaid Anthropic credits, no auto-reload.** Credits out → the function
  returns `unavailable` → the client quietly falls back to typed front/back
  entry. The scan's failure mode is the current app.
- **Abandonment is free by construction.** The one paid moment is the scan
  tap (~2¢ on claude-opus-4-8). Composer opens, photos taken, grid edits,
  abandoned posts: all $0.
- **Accuracy is measured, not guessed.** `scan_usage` (service-role ledger,
  one row per attempt) + the `scan_post` breadcrumb (`fixed` = cells the
  golfer corrected, `misses` = cells the model couldn't read). When the data
  says a cheaper model reads cards as well, the model swap is one line in the
  function.

Scale math: cost tracks scans-per-league, which tracks the season pass —
~$4–6/league-season on Opus at Best-4 cadence. "Who pays at scale" is PARKED
with the pricing decision; the caps make the interim safe.

## Monday additions (QA ritual #14)

```sql
-- spend + accuracy, this month
select count(*) scans, count(*) filter (where not ok) failures
  from scan_usage where created_at > date_trunc('month', now());
select props->>'fixed' as cells_fixed, props->>'misses' as unread, created_at
  from client_events where event = 'scan_post' order by created_at desc;
```

## Deploy surfaces

- Migration `20260718045514_photos_scan_spine` (bucket + policies,
  `rounds.photo_path`, `app_flags`, `scan_usage`, `scan_claims` + claim RPCs).
- Edge Function `scan` — `supabase functions deploy scan` + secret
  `ANTHROPIC_API_KEY` (console key with prepaid credits, no auto-reload).
- Client: composer photo/scan UI, confirm-grid revival, feed/recap rendering,
  claim-funnel fallback. All deploy-skew-safe: pre-migration clients hide the
  scan button (no flag row) and retry inserts/selects without `photo_path`.
