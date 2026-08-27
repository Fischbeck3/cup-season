#!/usr/bin/env bash
# Cup Season — the deploy prompt. Run it on the Mac, from the repo root.
#
#   ./tools/ship.sh            check, then confirm each deploy
#   ./tools/ship.sh --dry-run  check and print, run nothing
#
# It exists because the three deploys are INDEPENDENT and forgetting one is
# silent. It always shows all three, asks separately for each, and refuses to
# ship anything at all if preflight is failing.
#
# `supabase db push` is deliberately confirmed by TYPING the word push, not by
# a keystroke: it mutates production and CLAUDE.md keeps a human at that wheel.

set -euo pipefail
cd "$(dirname "$0")/.."

DRY=0; [[ "${1:-}" == "--dry-run" ]] && DRY=1
BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GRN=$'\033[32m'; OFF=$'\033[0m'

say()  { printf '%s\n' "$*"; }
step() { printf '\n%s==>%s %s\n' "$BOLD" "$OFF" "$*"; }

# --- gate 1: preflight must pass ------------------------------------------
step "preflight"
if ! node tests/preflight.mjs; then
  say ""
  say "${RED}Preflight is failing. Nothing ships until it passes.${OFF}"
  say "${DIM}Every check there is a bug this repo already paid for.${OFF}"
  exit 1
fi

# --- gate 2: what is owed --------------------------------------------------
step "what is owed"
node tools/deploy-status.mjs
STATUS_JSON="$(node tools/deploy-status.mjs --json)"
have()  { printf '%s' "$STATUS_JSON" | node -e "
  let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{
    const j=JSON.parse(s); process.exit(j[process.argv[1]]?.state===process.argv[2]?0:1);});
" "$1" "$2"; }

if [[ $DRY == 1 ]]; then say ""; say "${DIM}--dry-run: stopping here.${OFF}"; exit 0; fi

confirm() {  # confirm <prompt> [required-word]
  local word="${2:-y}" ans
  printf '\n%s %s' "$1" "${DIM}[$word to proceed]${OFF} "
  read -r ans < /dev/tty || return 1
  [[ "$ans" == "$word" ]]
}

# --- database --------------------------------------------------------------
if have database owed; then
  step "DATABASE"
  say "${DIM}This mutates production. Migrations are never edited after they run;${OFF}"
  say "${DIM}a fix is always a NEW migration.${OFF}"
  if confirm "Run ${BOLD}supabase db push${OFF}?" "push"; then
    supabase db push
    say "${GRN}database pushed${OFF}"
    say "${DIM}Refresh the RPC snapshot if this added or re-signed a function:${OFF}"
    say "${DIM}  see the query in packages/db/contract.psv, then node tools/build-db.mjs${OFF}"
  else say "${DIM}skipped${OFF}"; fi
elif have database unknown; then
  say ""; say "${RED}Database state unknown — the CLI could not answer. Not skipping it silently.${OFF}"
fi

# --- edge functions --------------------------------------------------------
if have functions maybe; then
  step "EDGE FUNCTIONS"
  say "${DIM}Advisory: this compares a git commit time to a deploy time, not content.${OFF}"
  for fn in $(printf '%s' "$STATUS_JSON" | node -e "
    let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{
      const j=JSON.parse(s);(j.functions.stale||[]).forEach(x=>console.log(x.name));});"); do
    if confirm "Deploy ${BOLD}$fn${OFF}?" "y"; then supabase functions deploy "$fn"; say "${GRN}$fn deployed${OFF}"
    else say "${DIM}skipped $fn${OFF}"; fi
  done
fi

# --- client ----------------------------------------------------------------
if have client owed; then
  step "CLIENT"
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  if [[ -n "$(git status --porcelain)" ]]; then
    say "${RED}Uncommitted changes — commit them first; this script does not commit for you.${OFF}"
    git status --short
  elif [[ "$BRANCH" == "main" ]]; then
    if confirm "Push ${BOLD}main${OFF} (Netlify builds it)?" "y"; then
      git push -u origin main; say "${GRN}pushed — watch the deploy, then check #obCaption on cupseason.app${OFF}"
    else say "${DIM}skipped${OFF}"; fi
  else
    if confirm "Push ${BOLD}$BRANCH${OFF} to origin?" "y"; then git push -u origin "$BRANCH"; say "${GRN}pushed${OFF}"
    else say "${DIM}skipped${OFF}"; fi
    say ""
    say "${DIM}Netlify builds main, so the client is NOT live until $BRANCH merges.${OFF}"
    say "${DIM}Merging is a review decision — this script will not do it for you.${OFF}"
  fi
fi

step "done"
node tools/deploy-status.mjs --quiet || true
say "${DIM}Live check: cupseason.app's #obCaption shows v23 · <sha> — compare to git log.${OFF}"
