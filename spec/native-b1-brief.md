# B1 · Scaffold — the brief for the local session

D98 Phase B, milestone 1. **This is written to be the first thing a local
Claude Code session on the Mac reads.** It exists so that session starts from
decisions already made rather than re-deriving them.

Read alongside `spec/native-arc.md` (the whole arc) and `CLAUDE.md` (the rules
that do not change just because the client is native).

---

## Where the work happens, and why it changed

Phase B runs in **Claude Code on the Mac**, not in a remote session. A remote
session cannot run `npx expo start`, cannot drive a simulator, cannot read the
actual crash, and cannot build to a phone. For native work that is the whole
job. Remote sessions keep migrations, specs, decisions and the web client.

**One branch, one machine.** There are two clones of this repo now. Whoever
owns a branch owns it exclusively — pull at the start of a session, push at
the end, and never have a remote and a local session on the same branch. The
version-line collisions in this repo's history were one symptom of parallel
sessions; the build stamp fixed that symptom, not the general problem.

## What B1 is

An Expo app that boots, wears the real palette, and signs a real person in.
Nothing else.

Explicitly NOT in B1: live scoring, the board, push, standings, the tee sheet.
And not ever on the phone: the wizard, the draft board, the ledger, the founder
desk — those are desk work and belong to the desktop surface (D98).

## Gate

**You sign in on your own iPhone, in Expo Go, with a real email code, and land
on a screen wearing the Charcoal palette.** Not a simulator, not a screenshot
of a login form — your actual phone, your actual account.

## Decisions already made — do not reopen these in B1

- **Expo / React Native, TypeScript.** iOS first; Android comes from the same
  codebase in Phase C.
- **Location: `apps/mobile/`.** Alongside `packages/`, not inside it.
- **NO root `package.json`.** A4 deferred it, and the reason still holds:
  Netlify auto-installs dependencies when it detects a root manifest, and this
  site has none to install. Adding one puts a new failure mode in front of a
  live deploy for no gain. Give `apps/mobile/` its own manifest and lockfile,
  and point Metro at the shared code with `watchFolders` +
  `resolver.nodeModulesPaths`. If that turns out to be genuinely painful, it is
  a decision to revisit deliberately — with the Netlify implication handled,
  not discovered.
- **Import the shared layer from day one.** `packages/tokens/tokens.ts` is the
  theme (34 tokens, both themes, dark default per D76). `packages/db` is the
  typed RPC surface and the data layer. Phase A exists precisely so B1 does not
  invent a second palette or a second API client. If something is missing from
  the shared layer, add it THERE, not in the app.

## Landmines that still apply on native

These are not web quirks. They are properties of this backend and they cost
real debugging time already — `packages/db/client.ts` encodes each one, so use
it rather than calling Supabase directly.

- **Never call a Supabase auth method synchronously inside
  `onAuthStateChange`** — the internal lock deadlocks with zero error output.
  Use `deferAuthWork`.
- **Supabase issues 8-digit OTPs.** No six-character input, ever.
- **Code-only OTP.** No magic links, no `emailRedirectTo` — Gmail's scanner
  consumes single-use tokens before the user clicks.
- **Realtime lives on a dedicated client**, never the one serving queries and
  auth. Not needed in B1, but do not lay groundwork that assumes otherwise.
- **Dates:** `new Date('YYYY-MM-DD')` parses as UTC midnight and renders the
  previous day in Phoenix. Use `localDate` / `isoDate` from the data layer.
- **Every client-called RPC needs its grant** (D37). A new RPC that "silently
  403s" is almost always a missing `grant execute … to authenticated`.

## Verification standard

`CLAUDE.md`'s rule is "verify before commit," and for a native client that
means **running it**, not compiling it. A screenshot of a build succeeding is
not evidence the app works. The gate above is the evidence.

Run `node tests/preflight.mjs` before every push, as always. It is 12 checks
now and knows nothing about the app yet — B1 is a good moment to consider
whether it should.

## Branch

`native/b1-scaffold`, cut from `main`. Merge to `main` when the gate passes.

Merging native code to main early is safe here and unusually so:
`stamp-version.sh` is a strict allowlist — Netlify publishes `index.html`,
`legal.html`, `sw.js`, the manifest, the icons, `brand/` and the AASA, and
nothing else. `apps/mobile/` is invisible to the website. So main stays the
single truth with no risk to the live site.

## Xcode

B1 does not need it. Expo Go on a physical phone is enough to reach the gate.

B5 (push) DOES need a development build, which needs full Xcode — Expo Go
cannot deliver iOS push. That download is already running; it just needs to
finish before B5, not before B1.
