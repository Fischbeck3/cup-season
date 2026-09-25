# Native audit integration contract

Codex's local native branch uses the following additive contract. Claude owns its database/web implementation and migration/grant tests. **Do not release the native build until the combined integration tests pass.** A missing share preparation RPC falls back to sharing the card alone with an explicit link error; it never silently mints through the old ambiguous path.

## Round share lifecycle

- `prepare_round_share(p_round uuid, p_include_photo boolean, p_attempt uuid) -> jsonb`: owner checked, idempotent on attempt. Return `{token: uuid, created: boolean, include_photo: boolean}`. Reuse a *completed* token with unchanged recorded consent (including photo-less PNGs). If consent changes, revoke and durably enqueue JPG/PNG cleanup. A new attempt owns a new token, subject to a short server lease. Do not let concurrent incomplete attempts borrow/revoke each other's tokens. If a round/photo is withdrawn while an attempt is prepared, its completion must never reactivate it. Missing consent on legacy tokens requires safe rotation, not a guess from PNG presence.
- `finish_round_share(p_attempt uuid, p_completed boolean) -> jsonb`: idempotent acknowledgement. Completed makes this attempt's link durable. Cancelled/failed retires **only a new token owned by this attempt**, never a reused completed link. Enqueue cleanup durably. Expire and reclaim abandoned preparations when the app exits or callback never arrives. Late/duplicate acknowledgements must not reactivate revoked links. Return success only once that state is durable.
- `round_share_status(p_round uuid) -> jsonb`: owner-only, read-only, no mint. Return `{token: uuid|null, cleanup_pending: boolean}` and optional details. Pending remains true until Storage API removal of **both** copies is verified. A missing token is not proof that public bytes are gone.
- Existing `withdraw_round_shares(p_round uuid) -> text[]`: revoke immediately, persist server cleanup, return *all* relevant prior token names for idempotent client removal. Must continue to work for withdrawn/deleted rounds via creator ownership. Native also removes both objects through Storage API and surfaces a failure; the server remains responsible for eventual cleanup and verifying status even if the client exits.

Native uploads new copies only for `created=true`; an existing completed link keeps its original artifact. Actual OS share-sheet completion drives acknowledgement and growth telemetry. Completion acknowledgements are persisted per owner and retried on authenticated reload. The server lease covers death before callback. Do not expose `shares` through direct client table grants.

## Additive payload fields

- `native_home.memberships[].in_season: boolean` remains the accepted-membership predicate. `renewal_status: "pending"|"accepted"|"declined"|"expired"` is optional for skew but required for declined-before-first-tee fidelity. A pending next season opens the covenant by code; expired/declined never renders as live.
- `join_covenant_info.structure`: same bylaw values as league settings. Native omits structure when absent. Copy: solo stands individually; squads count together; two-squad Final includes both squads, with +10 to the leader; larger squads qualify the top two; points table has no reset. Floor is not narrated for solo. Omit zero-percent award shares.
- `season_book.entries[].withdrawn: boolean`: optional old-payload decoding, default false. Preserve the ledger contribution/reason; withdrawn entries have no private round door.

Native final table uses the stored champion/runner-up IDs followed by tied points ranks of the remaining field, matching `_final_place`; Book continues to rank season points. Native Cup Final rail ranks race totals while the clause explicitly labels qualification seed.

Native declarations added to `packages/db/contract.psv` are planned integration declarations, not evidence these RPCs exist in production. Union both branches' contract sources and regenerate. No production deployment was performed.

- Per-season trophies: include `Season N` in the existing `subtitle` returned by `my_trophies` and `tour_card.case` (and backfill/award producer), preserving the year separately. Native already renders both fields and keys hardware by trophy ID; it must not infer a season number from a calendar year.
- Squad receipt now reads the validated Book squad/contribution rows, so it inherits the corrected seat eligibility and frozen completed ledger. It does not reconstruct squad contributions from individual totals.
