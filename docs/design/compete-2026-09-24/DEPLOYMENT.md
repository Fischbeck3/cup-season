# Selected Compete deployment · September 24, 2026

The owner requested “Push and deploy,” then explicitly said “Not test flight yet.” This supersedes the earlier local-only push/deploy boundary for the selected database and web implementation. All repository work remains in `/Users/fischbeck3/cup-season-compete-explore`, on `codex/compete-explorations-2026-09-24`. No other worktree was touched; no merge or rebase was performed.

## Current status

- **Branch pushed:** code/review candidate `d9cfe2b39d0f85e476b27f61d38bcbb072de227d`, with upstream `origin/codex/compete-explorations-2026-09-24`.
- **Database deployed:** `20261118090000_the_book.sql`, the only migration listed by the dry run. Production now has **255 migrations**, latest `20261118090000`; a following dry run reports up to date with no pending migrations. The applied migration is immutable.
- **Production verification:** **37/37 checks pass**. `season_book(uuid,uuid)` exists, stable/security-definer, `search_path=public`, authenticated execution allowed, anon/public execution denied. `native_home` contains `points_tied`.
- **Web pending Netlify authentication:** publish build and service worker both stamp `d9cfe2b`. Netlify's offline production build passes, including `share-preview` edge-function bundling. The CLI has no active login; a login request was presented to the owner. No Netlify publish has occurred yet.
- **Supabase Edge:** no deployment performed or owed by this change.
- **TestFlight:** explicitly held. No ASC commands, archive, upload or distribution performed.

## Candidate and web release scope

`origin/main` is `1e79279331baa22ffedecbba8b3b1c47965859b6`, an ancestor of the candidate with 51 commits between them. The branch includes the earlier Owner-beta work as well as the selected Compete implementation. Served changes include the earlier share/photo-consent work, support/install pages and rewrites, contrast corrections, and consent-aware share-preview function. Its preceding database migrations were already applied before this release.

The web candidate uses the repository's `netlify.toml` and `stamp-version.sh` allowlist. `dist/` includes the public pages, assets, manifest and Apple association file; repository docs, app source, migrations and function source are not served. The Netlify CLI deploy must include build/function bundling and headers/rewrites. A direct production deployment preserves main; main remains behind this candidate and its future builds must account for that difference.

## Evidence

- [Applied migration output](evidence/selected-deploy/deploy-database.log)
- [Following database dry run](evidence/selected-deploy/deploy-db-dry-run.log)
- [Production contract readback](evidence/selected-deploy/production-contract.json)
- [Production checks](evidence/selected-deploy/production-checks.json)
- [Preflight: 0 failures / 0 warnings](evidence/selected-deploy/deploy-preflight.log)
- [Netlify build, including share-preview](evidence/selected-deploy/netlify-build.log)

Native checks, simulator captures, Node results and preserved earlier failures remain in [selected verification](SELECTED-VERIFICATION.md). All capture and functional test data was synthetic. Production checks above were read-only introspection/invariant checks, with no fixture seeding or product-account sign-in.
