# packages/ — the shared layer

D98 Phase A. Everything here is consumed by more than one surface: the React
Native phone app (Phase B), the React desktop rewrite (Phase D), and the live
single-file client at `index.html` until Phase D replaces it.

| | Source of truth | Generated from it | Guarded by |
|---|---|---|---|
| `tokens/` | `tokens.json` | `tokens.css`, `tokens.ts` | preflight check 10 |
| `db/` | `contract.psv` | `rpc.ts` | preflight check 11 |
| `db/client.ts` | hand-written | — | `tsc --strict` |

**Never hand-edit a generated file.** Edit the source and run
`node tools/build-tokens.mjs` or `node tools/build-db.mjs`. Both take
`--check`, and preflight runs them that way, so a stale artifact fails the
push instead of shipping.

## A4 · Repo shape — monorepo here, workspace manifest deferred

The decision is a monorepo in this repo. What is deliberately **not** here yet
is a root `package.json`.

`netlify.toml` declares `command = "bash ./stamp-version.sh"`, so the build
command itself is safe. But Netlify runs an automatic dependency install when
it detects a root manifest, and this site has no dependencies to install — it
is a single HTML file and a shell script. Adding a manifest today buys nothing
and puts a new failure mode in front of a live deploy.

So: every tool in `tools/` and `tests/` is plain Node with zero dependencies,
exactly as `tests/preflight.mjs` already was. The workspace manifest arrives in
Phase B, when the RN app is the thing that actually needs one, and it arrives
with the Netlify implications handled on purpose rather than by accident.

## How the live client relates to `tokens/`

`index.html` does **not** import `tokens.css`. It is a single-file PWA and
inlines its own CSS by design; changing that would mean putting a build step in
front of a deploy pipeline whose whole virtue is that it has none.

Instead, `tokens.json` is the source of truth and **preflight check 10 fails if
the client disagrees with it** — on any token, in either theme, in either
direction. The guarantee is the same one a build step would give (one palette,
not two); it is enforced at push time instead of assembled at build time, and
it required no change to a client that is serving real leagues today.

When Phase D replaces `index.html` with React, that client imports
`tokens.css` or `tokens.ts` directly and this note retires.

## `db/contract.psv`

A verbatim `pg_proc` snapshot, refreshed with the read-only query in its own
header after any migration that adds, drops or re-signs a function. It is what
lets preflight answer a question the migrations alone cannot: *does this
function exist in prod, spelled the way the client spells it?*

Check 2 proves a grant exists somewhere in the migrations. Check 11 proves the
function exists in the database. They miss different bugs, which is why both
are worth running.
