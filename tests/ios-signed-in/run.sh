#!/usr/bin/env bash
# Cup Season · run the signed-in review UI tests against the DISPOSABLE LOCAL stack.
#
#   tests/ios-signed-in/run.sh <repo-or-worktree> <derived-data-dir> [result-bundle]
#
# 1. seeds the local world (idempotent, seed.sh)
# 2. creates a throwaway "CS-RC-UITests" iPhone 17 Pro simulator, installs the built app
# 3. points the app at the local stack (cs_audit_url / cs_audit_key in the app's own prefs)
# 4. signs the local test golfer in through the DEBUG hatch (-cs_dev_email / -cs_dev_code);
#    the code comes from the LOCAL auth admin API (generate_link → email_otp), because the
#    local stack's email template carries a link only, no {{ .Token }}
# 5. runs the classes with test-without-building, then deletes the simulator
#
# Build first:  cd <repo>/apps/ios && xcodegen generate && xcodebuild build-for-testing \
#   -project CupSeason.xcodeproj -scheme CupSeason -destination 'generic/platform=iOS Simulator' \
#   -derivedDataPath <derived-data-dir>
# Never use -cs_audit_backend prod. Refuses any non-local stack.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="${1:?repo path}"; dd="${2:?derived data path}"; bundle="${3:-${TMPDIR:-/tmp}/cs-signed-in-$(date +%Y%m%d-%H%M%S).xcresult}"
workdir="${CS_STACK_WORKDIR:-$HOME/.cache/cs-readiness-stack}"
GOLFER="${CS_UITEST_GOLFER:-rc-uitest-golfer@example.invalid}"
BID=app.cupseason.ios

"$here/seed.sh"

env_file="$(mktemp)"; trap 'rm -f "$env_file"' EXIT
supabase status --workdir "$workdir" -o env 2>/dev/null > "$env_file"
# shellcheck disable=SC1090
source "$env_file"
case "$API_URL" in http://127.0.0.1:*|http://localhost:*) ;; *) echo "refusing: API_URL is not local" >&2; exit 2;; esac

sim="$(xcrun simctl create CS-RC-UITests 'iPhone 17 Pro' com.apple.CoreSimulator.SimRuntime.iOS-26-5)"
echo "simulator $sim"
cleanup() { xcrun simctl shutdown "$sim" >/dev/null 2>&1 || true; xcrun simctl delete "$sim" || true; rm -f "$env_file"; }
trap cleanup EXIT
xcrun simctl boot "$sim"; xcrun simctl bootstatus "$sim" -b >/dev/null
app="$(ls -d "$dd"/Build/Products/Debug-iphonesimulator/CupSeason.app)"
xcrun simctl install "$sim" "$app"
prefs="$(xcrun simctl get_app_container "$sim" "$BID" data)/Library/Preferences/$BID.plist"
mkdir -p "$(dirname "$prefs")"
/usr/libexec/PlistBuddy -c "Add :cs_audit_url string $API_URL" -c "Add :cs_audit_key string $ANON_KEY" "$prefs" >/dev/null

code="$(curl -sf -X POST "$API_URL/auth/v1/admin/generate_link" \
  -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" -H "Content-Type: application/json" \
  -d "{\"type\":\"magiclink\",\"email\":\"$GOLFER\"}" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("email_otp") or (d.get("properties") or {}).get("email_otp") or "")')"
[ "${#code}" = 8 ] || { echo "no 8-digit code (is [auth.email] otp_length = 8 on the stack?)" >&2; exit 3; }
xcrun simctl launch "$sim" "$BID" -cs_dev_email "$GOLFER" -cs_dev_code "$code" -cs_dev_look none >/dev/null
unset code
for _ in $(seq 1 30); do
  signed="$(psql "$DB_URL" -Atc "select count(*) from auth.sessions s join auth.users u on u.id = s.user_id where u.email = '$GOLFER' and s.created_at > now() - interval '2 minutes'")"
  [ "$signed" != "0" ] && break; sleep 1
done
[ "$signed" != "0" ] || { echo "the simulator did not sign in" >&2; exit 4; }
sleep 5; xcrun simctl terminate "$sim" "$BID" || true

xctestrun="$(ls "$dd"/Build/Products/*.xctestrun | head -1)"
cd "$repo/apps/ios"
xcodebuild test-without-building -xctestrun "$xctestrun" -destination "platform=iOS Simulator,id=$sim" \
  -resultBundlePath "$bundle" \
  -only-testing:CupSeasonUITests/CoursePrepReviewTests \
  -only-testing:CupSeasonUITests/CompeteGameplayReviewTests \
  -only-testing:CupSeasonUITests/CompeteBoldReviewTests \
  -only-testing:CupSeasonUITests/AcceptedRoundReviewTests \
  -only-testing:CupSeasonUITests/ComposerWorthUITests \
  -only-testing:CupSeasonUITests/ReceiptMomentTests \
  -only-testing:CupSeasonUITests/ReceiptLensesUITests || true
echo "result bundle: $bundle"
xcrun xcresulttool get test-results tests --path "$bundle" | python3 -c '
import sys, json
def walk(n, out):
    if n.get("nodeType") == "Test Case": out.append((n.get("nodeIdentifier"), n.get("result")))
    for c in n.get("children", []) or []: walk(c, out)
out = []
for t in json.load(sys.stdin).get("testNodes", []): walk(t, out)
for i, r in out: print(r, i)
'
