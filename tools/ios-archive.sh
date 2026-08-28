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
# ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8 (where altool looks) and:
#   export ASC_KEY_ID=XXXXXXXXXX ASC_ISSUER_ID=xxxxxxxx-xxxx-…
# Nothing here is stored in the repo.
#
# Before the first TestFlight upload: `supabase secrets unset APNS_SANDBOX`
# (runbook D5) — a production token against the sandbox host is pruned as dead.
set -euo pipefail
cd "$(dirname "$0")/../apps/ios"

BUILD=$(git rev-list --count HEAD)
SHA=$(git rev-parse --short HEAD)
OUT="build/archive"
ARCHIVE="$OUT/CupSeason-$BUILD-$SHA.xcarchive"
mkdir -p "$OUT"

echo "▸ xcodegen"
xcodegen generate >/dev/null

echo "▸ archive  build $BUILD ($SHA)"
xcodebuild -project CupSeason.xcodeproj -scheme CupSeason \
  -destination "generic/platform=iOS" -configuration Release \
  -archivePath "$ARCHIVE" -allowProvisioningUpdates \
  CURRENT_PROJECT_VERSION="$BUILD" \
  archive 2>&1 | /usr/bin/grep -E "error:|warning: .*(entitlement|provision)|ARCHIVE (SUCCEEDED|FAILED)" || true
[ -d "$ARCHIVE" ] || { echo "✗ no archive produced"; exit 1; }

echo "▸ export"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$OUT/export-$BUILD" \
  -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates 2>&1 | /usr/bin/grep -E "error:|EXPORT (SUCCEEDED|FAILED)" || true
IPA=$(ls "$OUT/export-$BUILD"/*.ipa 2>/dev/null | head -1)
[ -n "$IPA" ] || { echo "✗ no .ipa exported"; exit 1; }
echo "  ipa: $IPA"

if [ "${1:-}" = "--upload" ]; then
  : "${ASC_KEY_ID:?set ASC_KEY_ID}" "${ASC_ISSUER_ID:?set ASC_ISSUER_ID}"
  echo "▸ upload (altool, API key $ASC_KEY_ID)"
  xcrun altool --upload-app --type ios -f "$IPA" --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tail -3
  echo "  uploaded build $BUILD — it appears in TestFlight after Apple's processing (5–15 min)."
else
  echo "  (no upload — pass --upload with ASC_KEY_ID / ASC_ISSUER_ID set)"
fi
