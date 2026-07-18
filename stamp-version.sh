#!/usr/bin/env bash
# ============================================================================
# stamp-version.sh — the deploy stamps its own identity AND assembles the
# publish allowlist.
#
# WHY (version): the version used to be two hand-edited lines (the sign-in
# caption and sw.js's VERSION). Every parallel session touched both, so every
# concurrent push collided on them. Nobody edits a version line now: the source
# carries the placeholder __CS_VERSION__ and the build replaces it with the
# commit. The two lines must move TOGETHER or the service worker keeps serving
# the previous shell — one placeholder, one substitution, both files.
#
# WHY (dist allowlist — OPS-C7, spec/launch-audit-2026-07-18.md): the old
# `publish = "."` served the ENTIRE repo at cupseason.app — every migration
# (the full schema + RLS model), CLAUDE.md, and the spec/ strategy docs were
# world-readable. We now copy ONLY the shippable assets into dist/ and publish
# that. Nothing else can ever be served. The source tree is left untouched
# (the copies are what get stamped), so the working tree stays clean.
# ============================================================================
set -euo pipefail

REF="${COMMIT_REF:-}"
if [ -z "$REF" ]; then
  REF="$(git rev-parse HEAD 2>/dev/null || true)"
fi
SHORT="${REF:0:7}"
if [ -z "$SHORT" ]; then
  SHORT="dev"
fi
echo "[stamp] build identity: $SHORT"

# --- the allowlist: the ONLY files that reach the web -----------------------
# Every asset index.html / manifest / sw.js reference at runtime, and nothing
# else. Adding a new served asset? Add it here or it won't ship.
DIST="dist"
rm -rf "$DIST"
mkdir -p "$DIST"
cp index.html sw.js manifest.webmanifest apple-touch-icon.png \
   icon-192.png icon-512.png icon-512-maskable.png og-image.png "$DIST/"
cp -r brand "$DIST/brand"

# --- stamp the COPIES (source keeps the placeholder) ------------------------
sed -i "s/__CS_VERSION__/${SHORT}/g" "$DIST/index.html" "$DIST/sw.js"

# A surviving placeholder means the substitution missed — fail rather than
# publish a shell whose cache key never changes.
if grep -q "__CS_VERSION__" "$DIST/index.html" "$DIST/sw.js"; then
  echo "[stamp] ERROR: placeholder survived in dist/index.html or dist/sw.js" >&2
  exit 1
fi

# The shell must exist and be non-empty, or the deploy is a blank site. Fail the
# build (Netlify then keeps the previous good deploy live) rather than ship it.
for f in index.html sw.js manifest.webmanifest; do
  if [ ! -s "$DIST/$f" ]; then
    echo "[stamp] ERROR: $DIST/$f is missing or empty" >&2
    exit 1
  fi
done

echo "[stamp] dist    : $(ls "$DIST" | tr '\n' ' ')"
echo "[stamp] index   : $(grep -o 'v23 · [0-9a-z]*' "$DIST/index.html" | head -1)"
echo "[stamp] sw.js   : $(grep -o "VERSION = '[^']*'" "$DIST/sw.js" | head -1)"
echo "[stamp] ok"
