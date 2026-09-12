#!/usr/bin/env bash
# Cup Season — archive, export and upload the iOS app to TestFlight (IOS-027).
#
#   tools/ios-archive.sh            archive + export an .ipa (no upload)
#   tools/ios-archive.sh --upload   … and upload to App Store Connect
#
# Build number = the commit count on this branch, so two archives from the
# same tree carry the same number and the store never sees a collision (the
# web stamps its version from the SHA for the same reason — CLAUDE.md rule 2).
# The marketing version stays in apps/ios/project.yml (MARKETING_VERSION).
#
# Upload needs an App Store Connect API key (Users and Access → Integrations →
# App Store Connect API → Team key, role App Manager). Put the .p8 under
# ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8 (where altool looks), then
# store the two ids in the login keychain ONCE — each prompts, so neither value
# reaches your shell history, a dotfile, or this repo (which is public):
#   security add-generic-password -U -a "$USER" -s cupseason-asc-issuer -w
#   security add-generic-password -U -a "$USER" -s cupseason-asc-key    -w
# After that `tools/ios-archive.sh --upload` needs no environment at all. An
# explicit ASC_KEY_ID / ASC_ISSUER_ID still overrides, for CI or a second team.
# Nothing here is stored in the repo.
#
# Before the first TestFlight upload: `supabase secrets unset APNS_SANDBOX`
# (runbook D5) — a production token against the sandbox host is pruned as dead.
set -euo pipefail
cd "$(dirname "$0")/../apps/ios"

case "${1:-}" in ""|--upload) ;; *) echo "Unknown option: $1"; exit 2 ;; esac
if [ -n "$(git status --porcelain)" ]; then
  echo "✗ Review and commit the working tree before archiving."
  exit 1
fi
BUILD=$(git rev-list --count HEAD)
SHA=$(git rev-parse --short HEAD)
mkdir -p build/archive
OUT=$(mktemp -d "build/archive/run-$BUILD-$SHA.XXXXXX")
ARCHIVE="$OUT/CupSeason.xcarchive"
EXPORT="$OUT/export"

echo "▸ xcodegen"
xcodegen generate >/dev/null

echo "▸ archive  build $BUILD ($SHA)"
xcodebuild -project CupSeason.xcodeproj -scheme CupSeason \
  -destination "generic/platform=iOS" -configuration Release \
  -archivePath "$ARCHIVE" -allowProvisioningUpdates \
  CURRENT_PROJECT_VERSION="$BUILD" \
  archive > "$OUT/archive.log" 2>&1 || {
    tail -40 "$OUT/archive.log"; echo "✗ archive failed"; exit 1;
  }
[ -d "$ARCHIVE" ] || { echo "✗ no archive produced"; exit 1; }

echo "▸ export"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" \
  -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates > "$OUT/export.log" 2>&1 || {
    tail -40 "$OUT/export.log"; echo "✗ export failed"; exit 1;
  }
shopt -s nullglob
IPAS=("$EXPORT"/*.ipa)
[ "${#IPAS[@]}" -eq 1 ] || { echo "✗ expected exactly one new .ipa"; exit 1; }
IPA="${IPAS[0]}"
[ -n "$IPA" ] || { echo "✗ no .ipa exported"; exit 1; }
echo "  ipa: $IPA"

if [ "${1:-}" = "--upload" ]; then
  # The issuer UUID and the key id come from the login KEYCHAIN, not from the
  # environment, not from a dotfile and never from this repo — which is public.
  # The .p8 itself already lives where altool looks
  # (~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8) and is not stored here.
  # Store them once, and each command PROMPTS so the value never lands in shell
  # history:
  #   security add-generic-password -U -a "$USER" -s cupseason-asc-issuer -w
  #   security add-generic-password -U -a "$USER" -s cupseason-asc-key    -w
  # An explicit ASC_ISSUER_ID / ASC_KEY_ID in the environment still wins, so CI
  # or a one-off override needs no edit here.
  kc() { security find-generic-password -a "$USER" -s "$1" -w 2>/dev/null || true; }
  ASC_ISSUER_ID="${ASC_ISSUER_ID:-$(kc cupseason-asc-issuer)}"
  ASC_KEY_ID="${ASC_KEY_ID:-$(kc cupseason-asc-key)}"

  if [ -z "${ASC_ISSUER_ID:-}" ] || [ -z "${ASC_KEY_ID:-}" ]; then
    echo "✗ no App Store Connect credentials."
    echo "  Store them once (each prompts, so nothing lands in your shell history):"
    echo "    security add-generic-password -U -a \"\$USER\" -s cupseason-asc-issuer -w"
    echo "    security add-generic-password -U -a \"\$USER\" -s cupseason-asc-key    -w"
    echo "  The .p8 belongs at ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8"
    exit 1
  fi

  KEYFILE="$HOME/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8"
  [ -f "$KEYFILE" ] || { echo "✗ key $ASC_KEY_ID has no .p8 at $KEYFILE"; exit 1; }

  echo "▸ upload (altool, API key $ASC_KEY_ID)"
  xcrun altool --upload-app --type ios -f "$IPA" --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tail -3
  echo "  uploaded build $BUILD — it appears in TestFlight after Apple's processing (5–15 min)."
  echo "  A build is NOT distributed just because altool succeeded — add it to a"
  echo "  beta group and check /v1/betaGroups/<id>/builds. 667 was uploaded and"
  echo "  nobody ever got it."
else
  echo "  (no upload — pass --upload; credentials come from the keychain)"
fi
