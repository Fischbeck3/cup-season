# Claude: finish the database and web launch repairs against current main

The owner asked: “Prompt claude to build what they own and build what you own,” following Codex's recommendations on the open audit items. Implement your database/web responsibilities while Codex builds native on `codex/native-audit-repairs-2026-09-24` in `/private/tmp/cup-season-native-audit`.

Start by fetching origin and reading AGENTS.md, CLAUDE.md, docs/doc-map.md, the relevant canon, and Codex's review at `/private/tmp/cup-season-audit-design-review/docs/reviews/2026-09-24-audit-design-reconciliation.md` (commit `ba21a7a9`). Preserve the dirty original checkout. Create your own NEW worktree and branch based on current `origin/main` (reviewed at `32fc9413`). Bring forward your repair work through `4d7ef398` selectively. Do not work on Codex's branch and do not reset the existing repair branch.

## Ownership and integration

You own Supabase migrations/functions, backend tests, `index.html`, web tests, the combined database contract, and reconciliation of decision IDs. Codex owns `apps/ios/` native implementation and native tests. Codex is importing your existing native fixes as a base; do not duplicate or replace those files. Codex may add the already-reviewed `my_league_record` and `withdraw_round_shares` declarations to its source contract for compilation. At integration, union the contracts and regenerate with `node tools/build-db.mjs`; never choose one generated file over the other.

Preserve the approved Scoreboard, continuous topo behind text, Book Weeks/Totals/Race, and small-league Rounds & points. The web implementation on main is the visual baseline. This is a repair pass, not another redesign.

**Read `docs/planning/2026-09-24-native-audit-contract.md` on Codex’s branch before implementing sharing.** It specifies preparation/completion/status RPCs, durable cleanup semantics and additive payload fields. Native now declares these RPCs too; union the source contract at integration.

## Required database work

1. Resolve the migration-version collision: `20261118090000_the_book.sql` is ALREADY APPLIED. Never edit/rename it. Your unapplied `...the_record_book_has_one_door.sql` needs a unique version before its dependent repairs. Verify the ledger read-only before changing any supposedly-unapplied file. Reconcile the two D381 decisions without dropping either ruling; record the owner's implementation instruction and the recommendations it follows, including per-season trophies.
2. Rework S3 against main's actual `native_home`. Its old text anchors abort with “rank anchor found 0 times; expected twice.” Preserve `points_rank` and `points_tied` for points standing; keep final placement, champion and runner-up separate. Preserve the new `in_season` field and all prior features. Test a live points tie and a Final whose champion was not the points leader.
3. Fix Book eligibility in a NEW migration: S7 excludes pre-seat rounds in `v_squad_standings`, but `season_book` still includes them in squad/contribution receipts. Codex reproduced total 280 versus receipts 326. Apply consistent eligibility to Book, Race and the squad tie-ladder month scores. Preserve the golfer's individual rounds. Test late seating, season close, round withdrawal, cap displacement, penalties and multiple seasons.
4. Freeze completed-season scoring lines and supply explicit withdrawn-round provenance to the Book/receipt contract. Recommended additive Book-entry field: `withdrawn: boolean` (default false in old-client decoding). Preserve points/explanations while removing access to deleted private round details. Keep points standing distinct from final results.
5. Finish photo withdrawal robustly: revoke immediately and persist cleanup work server-side until both JPG and PNG Storage API removals succeed, including old-client operations and process/network interruption. Do not delete storage.objects with SQL. Do not treat revocation as byte deletion. Provide owner-readable pending/completed/error state and a retry path. Coordinate additive RPC/status names in a checked-in contract note before requiring them in native. Codex implements native cleanup/error handling with the existing typed RPC while your durable backend covers eventual cleanup.
6. Finish Cup Final `season_story` / `season_scenarios` using `cup_finalists`, not the live table, and preserve the approved final-position/seed distinction.
7. Finish and verify S1–S12's backend work, including per-season trophies and verified backfill. Leave the late-joiner participation-floor policy unchanged. Do not bundle a new rule into this integration.

## Required web work

Finish your previously handed-off web halves within the current design:
- Completed seasons: “The final table,” champion/final placing; no live cuts, counting progress or “N back” chase language. Keep Book points and receipts.
- Season-two pending invitation opens the terms; accepted opens the season; declined/expired never appears live. Refresh after posting and renewal.
- Pro's unseated-player controls in roster/Pro tools, with a conditional season-page link only when needed.
- Sharing: labelled “Turn off this link”; reuse photo-less links with unchanged consent; remove/revoke newly minted work on cancellation without revoking a previously completed share. Handle unsupported web-share/download paths truthfully; don't claim successful delivery merely because a link was minted.
- Covenant variants derived from the actual bylaws, keeping the fixed money sentence. Codex is drafting native copy; carry the same facts for solo/squads2/squads3+, $0/staked, short seasons, qualification, Points King, index/playing handicap.
- Handle derivation until genuinely edited; guest orientation/YOU/named score labels/sign-in alternative; promised join-with-code doors; suppress duplicate LAST when the feed leads with that round.

## Verification and delivery

Use a fresh task-owned local PostgreSQL/Supabase stack. Test the FULL combined migration sequence plus fresh install and reapply; the old 254-migration audit stack alone is insufficient. Run existing Book reconciliation tests and Codex's probe; it deliberately executes repair SQL by filename and is not proof the version collision is solved. Test Storage failure and interrupted cleanup, not only successful removal. Run Node checks, preflight, and browser checks with cleared caches. Record what is source-only, fixture, integration, simulator or physical-device evidence.

Commit your owned branch locally and provide exact commits, migration order, RPC/payload changes, test evidence and remaining gates. No production migrations, Edge deploys, secret changes, remote-main update, App Store submission or TestFlight distribution is authorized by this build request. Preserve the known deployment-security concern for this public repository; do not publish an unpatched production vulnerability's repair before coordinating deployment.

Do not wait for Codex's UI work to complete your independent tasks. Keep changes scoped to your ownership, and leave a concrete integration handoff.
