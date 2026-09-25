#!/bin/bash
# I5 · durable photo withdrawal, against a LOCAL Supabase stack only (real Storage API,
# real Edge runtime). Usage: storage-cleanup.sh <api-url e.g. http://127.0.0.1:55321> <supabase-dir>
# The function is served locally from <supabase-dir> (never deployed); users, rounds and
# images are synthetic (*@cleanup.invalid). Refuses anything that is not 127.0.0.1.
set -u
API="$1"; SDIR="$2"
case "$API" in http://127.0.0.1:*) ;; *) echo "REFUSING: not a local API"; exit 1;; esac
PUB=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
SVC=sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz
SECRET=local-cleanup-test-secret
T="$(mktemp -d /private/tmp/cs-cleanup-XXXXXX)"
FN="$API/functions/v1/share-cleanup"
pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then echo "PASS $3"; pass=$((pass+1)); else echo "FAIL $3  (got '$1', want '$2')"; fail=$((fail+1)); fi; }

user() { # email -> access token (local admin create + password sign-in)
  curl -s -X POST "$API/auth/v1/admin/users" -H "apikey: $SVC" -H "authorization: Bearer $SVC" -H 'content-type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"cleanup-pass-1\",\"email_confirm\":true}" >/dev/null
  curl -s -X POST "$API/auth/v1/token?grant_type=password" -H "apikey: $PUB" -H 'content-type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"cleanup-pass-1\"}" | python3 -c "import json,sys;print(json.load(sys.stdin)['access_token'])"; }
uid_of() { python3 -c "import json,base64,sys;p=sys.argv[1].split('.')[1];p+='='*(-len(p)%4);print(json.loads(base64.urlsafe_b64decode(p))['sub'])" "$1"; }
rpc() { curl -s -X POST "$API/rest/v1/rpc/$2" -H "apikey: $PUB" -H "authorization: Bearer $1" -H 'content-type: application/json' -d "$3"; }
put() { curl -s -o /dev/null -w '%{http_code}' -X POST "$API/storage/v1/object/$2/$3" -H "apikey: $PUB" -H "authorization: Bearer $1" -H "content-type: $4" -H 'x-upsert: false' --data-binary @"$5"; }
pub() { curl -s -o /dev/null -w '%{http_code}' "$API/storage/v1/object/public/shared/$1"; }
job() { rpc "$1" my_share_cleanup '{}' | python3 -c "import json,sys;j=[r for r in json.load(sys.stdin) if r['token']=='$2'];print(j[0]['status'] if j else 'none')"; }
sweep() { # optional: an env file for the served function
  curl -s -X POST "$FN" -H "x-cleanup-secret: $SECRET" -H 'content-type: application/json' -d '{}' ; }
serve() { # (re)serve the function with the given bucket
  pkill -f "functions serve" 2>/dev/null; sleep 1
  printf 'SHARE_CLEANUP_SECRET=%s\nSHARE_CLEANUP_BUCKET=%s\n' "$SECRET" "$1" > "$T/fn.env"
  (cd "$SDIR/.." && nohup supabase functions serve share-cleanup --no-verify-jwt --env-file "$T/fn.env" > "$T/serve-$1.log" 2>&1 &)
  for i in $(seq 1 30); do sleep 1; code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$FN" -H 'x-cleanup-secret: nope'); [ "$code" = 401 ] && return 0; done
  echo "function did not come up"; tail -5 "$T/serve-$1.log"; exit 1; }

# fixture images
python3 -c "open('$T/p.jpg','wb').write(b'\xff\xd8\xff\xe0'+b'x'*2048+b'\xff\xd9'); open('$T/c.png','wb').write(b'\x89PNG\r\n\x1a\n'+b'y'*2048)"
A=$(user "cleanup-a-$(date +%s)@cleanup.invalid"); UA=$(uid_of "$A")
B=$(user "cleanup-b-$(date +%s)@cleanup.invalid")

shared_round() { # label -> "round token": a posted round with a photo and both public copies
  local rid tok path
  rid=$(rpc "$A" post_round_once "{\"p_request_id\":\"$(uuidgen | tr A-Z a-z)\",\"p_payload\":{\"gross\":84,\"rating\":71.2,\"slope\":128,\"holes_played\":18,\"course_label\":\"$1\",\"played_on\":\"2026-09-20\"},\"p_hole_scores\":[],\"p_played_with\":[]}" \
        | python3 -c "import json,sys;print(json.load(sys.stdin)['round']['id'])")
  path="$UA/$(uuidgen | tr A-Z a-z).jpg"
  put "$A" media "$path" image/jpeg "$T/p.jpg" >/dev/null
  rpc "$A" set_round_photo "{\"p_round\":\"$rid\",\"p_photo_path\":\"$path\"}" >/dev/null
  tok=$(rpc "$A" create_share "{\"p_kind\":\"round\",\"p_ref\":\"$rid\"}" | tr -d '"')
  put "$A" shared "$tok.png" image/png "$T/c.png" >/dev/null
  put "$A" shared "$tok.jpg" image/jpeg "$T/p.jpg" >/dev/null
  echo "$rid $tok"; }

serve shared
ok "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$FN" -d '{}')" 401 "the function refuses a call without its secret"

echo "== 1 · an OLD client (986) removes the photo and never cleans"
read R1 K1 <<<"$(shared_round 'Old client')"
ok "$(pub $K1.jpg)/$(pub $K1.png)" 200/200 "before: both public copies are served"
rpc "$A" clear_round_photo "{\"p_round\":\"$R1\"}" >/dev/null
ok "$(job "$A" $K1)" pending "the revocation queued a pending cleanup"
ok "$(pub $K1.jpg)/$(pub $K1.png)" 200/200 "revocation alone leaves the bytes public (why the queue exists)"
sweep > "$T/sweep1.json"
ok "$(job "$A" $K1)" completed "the service sweep removed both copies and confirmed it"
ok "$(pub $K1.jpg)/$(pub $K1.png)" 400/400 "after: neither copy is served"

echo "== 2 · Storage FAILS (the function removes from the wrong bucket), then the owner retries"
read R2 K2 <<<"$(shared_round 'Storage failure')"
rpc "$A" clear_round_photo "{\"p_round\":\"$R2\"}" >/dev/null
serve wrong-bucket
sweep > "$T/sweep2.json"
ok "$(job "$A" $K2)" error "a removal that did not remove is recorded as an error, not completed"
ok "$(rpc "$A" my_share_cleanup '{}' | python3 -c "import json,sys;j=[r for r in json.load(sys.stdin) if r['token']=='$K2'][0];print(j['attempts']>=1 and 'still stored' in (j['last_error'] or ''))")" True "the owner can read the attempt and why it failed"
ok "$(pub $K2.jpg)" 200 "the copy is still public while it is in error"
ok "$(rpc "$A" retry_share_cleanup "{\"p_token\":\"$K2\"}" | python3 -c "import json,sys;print(json.load(sys.stdin)['status'])")" pending "the owner's retry puts it back in the queue"
serve shared
sweep > "$T/sweep3.json"
ok "$(job "$A" $K2)" completed "the retry completes once Storage works"
ok "$(pub $K2.jpg)/$(pub $K2.png)" 400/400 "and both copies are gone"

echo "== 3 · a client revokes, then dies before removing anything (interrupted cleanup)"
read R3 K3 <<<"$(shared_round 'Interrupted')"
rpc "$A" withdraw_round_shares "{\"p_round\":\"$R3\"}" >/dev/null
ok "$(job "$A" $K3)" pending "the obligation survives the client's death"
sweep > "$T/sweep4.json"
ok "$(job "$A" $K3)/$(pub $K3.jpg)" completed/400 "the next sweep finishes the job"

echo "== 4 · a new client cleans its own copies and asks the server to confirm"
read R4 K4 <<<"$(shared_round 'Client path')"
rpc "$A" withdraw_round_shares "{\"p_round\":\"$R4\"}" >/dev/null
ok "$(rpc "$A" confirm_share_cleanup "{\"p_token\":\"$K4\"}" | python3 -c "import json,sys;j=json.load(sys.stdin);print(j['status'],j['remaining'])")" "error 2" "confirming while the copies remain is refused: the server checks storage, not the client's word"
curl -s -o /dev/null -X DELETE "$API/storage/v1/object/shared" -H "apikey: $PUB" -H "authorization: Bearer $A" -H 'content-type: application/json' -d "{\"prefixes\":[\"$K4.jpg\",\"$K4.png\"]}"
ok "$(rpc "$A" confirm_share_cleanup "{\"p_token\":\"$K4\"}" | python3 -c "import json,sys;j=json.load(sys.stdin);print(j['status'],j['remaining'])")" "completed 0" "after the client's own removal the server confirms completion"

echo "== 5 · an old client deletes the round outright"
read R5 K5 <<<"$(shared_round 'Deleted round')"
rpc "$A" delete_round "{\"p_round\":\"$R5\"}" >/dev/null
ok "$(job "$A" $K5)" pending "delete_round's revocation queued the cleanup"
sweep > "$T/sweep5.json"
ok "$(job "$A" $K5)/$(pub $K5.png)" completed/400 "a deleted round's copies are removed for good"

echo "== 6 · another golfer"
ok "$(rpc "$B" my_share_cleanup '{}')" "[]" "another golfer sees none of the owner's cleanup"
ok "$(rpc "$B" confirm_share_cleanup "{\"p_token\":\"$K2\"}" | python3 -c "import json,sys;print(json.load(sys.stdin).get('message','-'))")" "Nothing to confirm" "and cannot confirm or touch the owner's"

pkill -f "functions serve" 2>/dev/null
echo "evidence: $T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
