# Selected repair release · September 28, 2026

Owner authorization: **“Ship it”**, after the completed build handoff disclosed inherited checks and missing human/device proof.

Owned branch/worktree: `codex/ten-ship-2026-09-28`, `/Users/fischbeck3/cup-season-ten-ship`.

Baseline: freshly fetched `origin/main` `5fabf861`. Approved Door `a4101f71` integrates as `111f8f3e`; Home `f884696b` integrates as `68e8716f`. Documentation `025d8f87` and its baseline/context ancestors are included. Only `index.html` and native `DoorView.swift` change in production source. No database, RPC, Edge, generated runtime token, icon or production mark change.

Delivery scope: main/Netlify web and internal Owner TestFlight. No public App Store submission, Friends distribution, new dependency or production-data mutation.

Current state: candidate integration complete; release checks and delivery read-backs pending. Nothing is claimed deployed by this planning record. The completed [BUILD.md](BUILD.md) remains the source for capture matrices, semantic tests and known limits. Release verification and exact build/artifact identities will be appended after the actual steps.

Known limits retained: pre-existing 1600px Door terrain assertion; unsigned-simulator keychain entitlement test; fixture console warnings; complete authenticated UI, physical-device and human checks. These are not newly introduced by the two fixes, and shipping authorization does not turn them into test passes.

Database deploy owed: none. Edge deploy owed: none. Client delivery: authorized, pending verification and release.
