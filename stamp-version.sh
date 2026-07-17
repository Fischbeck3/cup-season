#!/usr/bin/env bash
# ============================================================================
# stamp-version.sh — the deploy stamps its own identity.
#
# WHY: the version used to be two hand-edited lines (the sign-in caption and
# sw.js's VERSION). Every parallel session touched both, so every concurrent
# push collided on them and someone had to re-bump by hand. Nobody edits a
# version line now: the source carries the placeholder __CS_VERSION__ and
# Netlify replaces it with the commit at build time.
#
# The two lines must still move TOGETHER — if sw.js's VERSION doesn't change,
# the service worker keeps serving the previous shell. One placeholder, one
# substitution, both files: they cannot drift apart again.
# ============================================================================
set -euo pipefail

# Netlify exports COMMIT_REF. Fall back to git (local runs), then to a literal
# so the value is NEVER empty — an empty sw.js VERSION would silently pin every
# user to one cache bucket forever.
REF="${COMMIT_REF:-}"
if [ -z "$REF" ]; then
  REF="$(git rev-parse HEAD 2>/dev/null || true)"
fi
SHORT="${REF:0:7}"
if [ -z "$SHORT" ]; then
  SHORT="dev"
fi

echo "[stamp] build identity: $SHORT"

sed -i "s/__CS_VERSION__/${SHORT}/g" index.html sw.js

# A surviving placeholder means the substitution missed — fail the build rather
# than publish a shell whose cache key never changes.
if grep -q "__CS_VERSION__" index.html sw.js; then
  echo "[stamp] ERROR: placeholder survived in index.html or sw.js" >&2
  exit 1
fi

echo "[stamp] index.html : $(grep -o 'v23 · [0-9a-z]*' index.html | head -1)"
echo "[stamp] sw.js      : $(grep -o "VERSION = '[^']*'" sw.js | head -1)"
echo "[stamp] ok"
