#!/usr/bin/env bash
# Cup Season — the deploy prompt. Run it on the Mac, from the repo root.
#
#   ./tools/ship.sh              check, then confirm each deploy
#   ./tools/ship.sh --dry-run    check and print, run nothing
#   ./tools/ship.sh --check-jwt  read verify_jwt back for the webhook functions, nothing else
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

# --- C-05 · the functions that must run with verify_jwt OFF ------------------
# Database Webhooks and pg_cron call these with a shared secret and never a JWT.
# With verification on, the gateway 401s every call before the code runs and
# pg_net just records it: no pushes, no emails, no photo cleanup, and no error
# anywhere. supabase/config.toml pins them and the deploy below passes
# --no-verify-jwt; this reads the setting BACK from the platform, because a pin
# is a belief and `functions list` is the fact. Unreadable counts as wrong.
NOJWT="push season-email share-cleanup"
jwt_gate() {
  local out
  out="$(supabase functions list --output-format json 2>&1)" || true
  if printf '%s' "$out" | RED="$RED" OFF="$OFF" node -e "
    let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{
      const {RED,OFF}=process.env, docs=[], rows=[];
      const tryParse=t=>{try{docs.push(JSON.parse(t));return true;}catch{return false;}};
      const a=s.search(/[[{]/), z=Math.max(s.lastIndexOf('}'),s.lastIndexOf(']'));
      if(!tryParse(s) && !(a>=0 && tryParse(s.slice(a,z+1)))) s.split('\n').forEach(tryParse);
      const walk=v=>{ if(Array.isArray(v)) v.forEach(walk);
        else if(v&&typeof v==='object'){ if('verify_jwt' in v && (v.slug||v.name)) rows.push(v); Object.values(v).forEach(walk); } };
      docs.forEach(walk);
      let bad=0;
      for(const fn of process.argv[1].split(' ')){
        const r=rows.find(x=>x.slug===fn)??rows.find(x=>x.name===fn);
        const fix='supabase functions deploy '+fn+' --no-verify-jwt';
        if(!r){ bad++; console.log(RED+'  '+fn+': verify_jwt UNKNOWN (not readable from supabase functions list). Check it by hand; if it is on: '+fix+OFF); }
        else if(r.verify_jwt!==false){ bad++; console.log(RED+'  '+fn+': verify_jwt='+r.verify_jwt+' (every webhook/cron call now 401s). Fix now: '+fix+OFF); }
        else console.log('  '+fn+': verify_jwt=false');
      }
      process.exit(bad?1:0);
    });" "$NOJWT"; then
    say "${GRN}verify_jwt is off for every webhook function${OFF}"
  else
    say "${RED}${BOLD}JWT verification is ON (or unconfirmed) for a webhook function.${OFF}"
    say "${RED}Pushes, emails and photo cleanup stop silently until it is off. Run the fix above.${OFF}"
    return 1
  fi
}
if [[ "${1:-}" == "--check-jwt" ]]; then step "verify_jwt"; jwt_gate; exit $?; fi

# --- gate 1: preflight must pass ------------------------------------------
step "preflight"
# The free-identifier check (the `staged` lint, added after that name shipped
# and told every Pro "Lock failed" for 25 days) needs two dev-only packages.
# Without them it WARNs rather than passing — but say so here, or a fresh
# clone ships with the check quietly sitting out.
if [[ ! -d node_modules ]] && [[ -f package.json ]]; then
  say "${DIM}node_modules missing — run 'npm ci' to enable the free-identifier check.${OFF}"
fi
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

# --- ORDER GATE: a pending migration that widens a posts `kind` --------------
# X1 / R-2 · this script ships DATABASE first and EDGE FUNCTIONS second, and for
# one shape of release that order is the wrong one. `save_bag` writes a post of
# kind 'bag'; the posts INSERT webhook drives the `push` Edge Function; D238's
# person-homed branch fans to every accepted buddy; and the ONLY thing standing
# between a bag change and every buddy's lock screen is the guard in
# supabase/functions/push/index.ts. Push the database first and the first bag
# edit is the manufactured interruption L-22 forbids — in the week new testers
# arrive. Deploying the function first is safe in BOTH orders, so the rule is
# simply: function first, whenever a pending migration widens a kind check.
if have database owed; then
  KINDGUARD=""
  for m in $(printf '%s' "$STATUS_JSON" | node -e "
    let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{
      const j=JSON.parse(s);(j.database&&j.database.pending||[]).forEach(x=>console.log('supabase/migrations/'+(x.file||x)));});"); do
    [[ -f "$m" ]] && grep -qiE 'posts_kind_check' "$m" && KINDGUARD="$KINDGUARD $m"
  done
  if [[ -n "$KINDGUARD" ]]; then
    step "ORDER"
    say "${RED}A pending migration widens the posts KIND check:${OFF}${KINDGUARD}"
    say "${BOLD}Deploy the push Edge Function BEFORE the database.${OFF}"
    say "${DIM}Without its guard, the first post of the new kind fans to every${OFF}"
    say "${DIM}accepted buddy through D238's person-homed branch (L-22).${OFF}"
    say "${DIM}  supabase functions deploy push --no-verify-jwt${OFF}"
    if ! confirm "Has ${BOLD}push${OFF} already been deployed?" "deployed"; then
      say "${RED}Stopping. Deploy push, then run this again.${OFF}"; exit 1
    fi
    jwt_gate || exit 1
  fi
fi

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
  DEPLOYED=0
  for fn in $(printf '%s' "$STATUS_JSON" | node -e "
    let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{
      const j=JSON.parse(s);(j.functions.stale||[]).forEach(x=>console.log(x.name));});"); do
    if confirm "Deploy ${BOLD}$fn${OFF}?" "y"; then
      # C-05 · belt and braces with the config.toml pin (see NOJWT above)
      if [[ " $NOJWT " == *" $fn "* ]]; then supabase functions deploy "$fn" --no-verify-jwt
      else supabase functions deploy "$fn"; fi
      say "${GRN}$fn deployed${OFF}"; DEPLOYED=1
    else say "${DIM}skipped $fn${OFF}"; fi
  done
  if [[ $DEPLOYED == 1 ]]; then step "verify_jwt"; jwt_gate || exit 1; fi
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
