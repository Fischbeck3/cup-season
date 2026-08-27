# Cup Season · mobile (D98 Phase B)

Expo has changed. Read the docs for the EXACT SDK this project is pinned to
before writing code: https://docs.expo.dev/versions/v56.0.0/

## Why SDK 56, not 57

Expo Go on the App Store runs exactly one SDK at a time, and the phone that
carries the B1 gate had a Go that answered SDK 57 with "Project is incompatible
with this version of Expo Go". So the project was pinned to 56 to match the
phone, not the other way round. When Expo Go on the phone is updated, upgrade:

    npx expo install expo@^57.0.9 --fix

That upgrade also closes the one open `expo-doctor` item: SDK 56 ships a
Hermes V1 build (250829098.0.10) with a known memory regression; the fix is in
0.16+, which arrives with SDK 57 / RN 0.86.2. It does not block the scaffold.

## Dependency notes (each cost a round-trip)

- `react-native-reanimated` and `react-native-worklets` are pinned EXACT to
  the versions in `node_modules/expo/bundledNativeModules.json`. Tilde ranges
  let npm float reanimated to a patch Expo does not expect.
- `overrides.react-dom = 19.2.3` pins a web-only optional peer of expo-router
  to the same version as `react`; without it npm ERESOLVEs on a package the
  phone never loads.
- `expo-font` is a direct dependency so expo-symbols' loose `*` peer resolves
  to the SDK 56 copy instead of a second, newer one.
- `newArchEnabled` is not a valid app.json key on this SDK — the new
  architecture is always on.

`npx expo-doctor` should read 21/22 with only the Hermes note failing.

## Rules that do not change because the client is native

See `../../spec/native-b1-brief.md` and `../../CLAUDE.md`. In short: every
colour comes from `@cs/tokens` via `src/theme.ts` (preflight check 12), every
auth call goes through `@cs/db/auth.ts` (check 13), every RPC through
`call()` (check 14). Run `node tests/preflight.mjs` from the repo root before
every push.
