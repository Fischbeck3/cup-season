# Selected Compete deployment · September 24, 2026

The owner requested “Push and deploy,” explicitly held TestFlight, then directed deployment through the Git repository. The existing Git → Netlify path was used. All repository work remains in `/Users/fischbeck3/cup-season-compete-explore`, on `codex/compete-explorations-2026-09-24`. No other worktree was touched; no merge commit, rebase or force push was performed.

## Release result

- **Git release:** remote `main` fast-forwarded from `1e79279331baa22ffedecbba8b3b1c47965859b6` to `300266e4be55c38515288a6aa2d251a3e13d6a4b` with `git push origin HEAD:refs/heads/main`. The owned feature branch was already pushed and remains the working branch.
- **Web live:** [cupseason.app](https://cupseason.app/) and `/sw.js` both read **300266e**, verified **2026-09-25 02:06:33–34 UTC** (September 24 in Phoenix). Netlify published automatically from Git; no Netlify CLI login or direct CLI deploy was required.
- **Release CI:** [run 36084838146](https://github.com/Fischbeck3/cup-season/actions/runs/36084838146) passes Client invariants and Migration hygiene. Supabase Preview also reports success. Local pre-push preflight passes with **0 failures / 0 warnings**.
- **Database deployed:** `20261118090000_the_book.sql`, the only pending migration in the pre-deploy dry run. Production now has **255 migrations**, latest `20261118090000`; a following dry run reports no pending migrations. The applied migration is immutable.
- **Production database verification:** **37/37 checks pass**. `season_book(uuid,uuid)` exists, stable/security-definer, `search_path=public`, authenticated execution allowed, anon/public execution denied. `native_home` contains `points_tied`.
- **Supabase Edge:** no deployment performed or owed by this change. Netlify's existing share-preview function travels with the web build; its local Netlify bundle passed before release.
- **TestFlight:** explicitly held. No ASC commands, archive, upload or distribution performed.

This release-record follow-up changes documentation and evidence only. A later Git build of those records can carry a newer stamp with the same served implementation; **300266e is the first verified production release of this implementation**, not a claim that future documentation commits retain that stamp.

## Live verification

A fresh browser tab renders the signed-out door and `v23 · 300266e`, with no console errors and no production-account sign-in. The existing Supabase SDK emits a deprecation warning for its lock option; startup succeeds.

The live service worker matches the stamped source byte for byte and has `no-cache,no-store,must-revalidate`. HTML, `/get`, `/support` and `/legal` match the committed content after Netlify's normal pretty-URL/attribute normalization. The initial raw-byte HTML assertion differed only at Netlify-rewritten legal links; the semantic comparison passes, and `/legal` returns 200. Frame/content-type protection headers are present. Manifest and Apple association files return valid JSON; repository instructions and the migration source return 404.

## Candidate and web release scope

The release is a 52-commit fast-forward from the previous main, including the earlier Owner-beta work, the selected Compete implementation and deployment records. Served changes include the earlier share/photo-consent work, support/install pages and rewrites, contrast corrections, and consent-aware share-preview function. Its preceding database migrations were already applied before this release.

The web uses `netlify.toml` and `stamp-version.sh` unchanged for deployment: the publish allowlist contains public pages, assets, manifest and Apple association file; repository docs, app source, migrations and function source are not served. Netlify builds and bundles from the repository, preserving its redirects and headers. The earlier CLI-authentication detour did not publish anything or change site settings; it is superseded by this Git release.

## Evidence

- [Live page and service-worker identity](evidence/selected-deploy/git-web-identity.json)
- [Live public-route, content and header checks](evidence/selected-deploy/git-web-smoke.json)
- [Signed-out browser check](evidence/selected-deploy/signed-out-browser.txt)
- [GitHub release CI](evidence/selected-deploy/git-release-ci.json)
- [Pre-push preflight](evidence/selected-deploy/git-release-preflight.log)
- [Applied migration output](evidence/selected-deploy/deploy-database.log)
- [Following database dry run](evidence/selected-deploy/deploy-db-dry-run.log)
- [Production contract readback](evidence/selected-deploy/production-contract.json)
- [Production checks](evidence/selected-deploy/production-checks.json)
- [Local Netlify build, including share-preview](evidence/selected-deploy/netlify-build.log)

Native checks, simulator captures, Node results and preserved earlier failures remain in [selected verification](SELECTED-VERIFICATION.md). All capture and functional test data was synthetic. Production database checks were read-only introspection/invariant checks, with no fixture seeding or product-account sign-in.
