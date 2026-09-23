#!/usr/bin/env python3
"""Cup Season — the App Store Connect chain after an upload.

IT LIVES IN THE REPO NOW, AND THAT IS THE POINT. The previous copy sat in a
session scratchpad, went with it, and had to be rewritten from the decision log
the next time a build shipped. It carries NO SECRETS — the issuer and key ids
come from the environment (tools/ios-archive.sh reads the same two keychain
items) and the .p8 is never here — so a public repo is the right home for it.

  tools/ios-archive.sh --upload     archive, export, upload
  tools/asc.py ship <build> "notes" everything after the upload

THE STEP THAT IS EASY TO MISS AND WAS MISSED FOR 669's SUCCESSORS:
**adding a build to an EXTERNAL group is NOT distribution.** After the add,
`externalBuildState` sits at READY_FOR_BETA_SUBMISSION and no tester has
anything. You must POST /v1/betaAppReviewSubmissions with the build id; it
then auto-approves (201 -> IN_BETA_TESTING / APPROVED). An older note said the
group add auto-submits. It does not.

Credentials never touch this file, the repo (which is public) or the shell
history: the issuer and key ids arrive in the environment, and the .p8 is read
from ~/.appstoreconnect/private_keys/.

  ASC_ISSUER_ID=... ASC_KEY_ID=... python3 asc.py <command>

Commands:
  status <build>          what ASC thinks of that build number (both groups)
  builds [n]              the latest n uploads (default 5) and which group has each   · read-only
  groups                  the newest builds in Owner and in Friends                   · read-only
  owner <build> "notes"   poll -> What to Test -> add to OWNER (internal) only -> read back
                          availability. Never touches Friends, never submits for review.
  ship <build>            poll -> What to Test -> add to Friends -> SUBMIT -> read back
                          (EXTERNAL: Friends + Beta App Review — not for an Owner beta)
"""
import json, os, subprocess, sys, time, urllib.request, urllib.error
from datetime import datetime, timedelta, timezone

import jwt

APP_ID = "6806251118"
GROUP_ID = "9f8db84a-166c-4900-b196-ea2c5459e369"   # "Friends", EXTERNAL
FRIENDS_GROUP_ID = GROUP_ID
OWNER_GROUP_ID = "c4a784fe-22c5-4a75-bd4b-ca864b63574a"   # "Owner", INTERNAL
BASE = "https://api.appstoreconnect.apple.com"

def _keychain(service: str) -> str:
    """The same two login-keychain items `tools/ios-archive.sh` reads, read the
    same way. This script asked ONLY the environment when it was written, which
    made it the odd one of the pair: the archive half ran with no setup and the
    distribute half refused until you exported two variables by hand. An
    explicit ASC_ISSUER_ID / ASC_KEY_ID still wins, for CI or a second team."""
    try:
        out = subprocess.run(
            ["security", "find-generic-password", "-a", os.environ.get("USER", ""),
             "-s", service, "-w"],
            capture_output=True, text=True, timeout=10)
        return out.stdout.strip()
    except Exception:
        return ""


ISSUER = os.environ.get("ASC_ISSUER_ID", "").strip() or _keychain("cupseason-asc-issuer")
KEY_ID = os.environ.get("ASC_KEY_ID", "").strip() or _keychain("cupseason-asc-key")
if not ISSUER or not KEY_ID:
    sys.exit("no App Store Connect credentials — not in the environment and not in the keychain.\n"
             "  Store them once (each prompts, so nothing lands in your shell history):\n"
             '    security add-generic-password -U -a "$USER" -s cupseason-asc-issuer -w\n'
             '    security add-generic-password -U -a "$USER" -s cupseason-asc-key    -w')
KEYFILE = os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8")
if not os.path.exists(KEYFILE):
    sys.exit(f"no .p8 for key {KEY_ID}")


def token() -> str:
    """ES256, aud appstoreconnect-v1, 15 minutes. The `aud` is the part that
    silently 401s when it is wrong."""
    now = datetime.now(timezone.utc)
    return jwt.encode(
        {"iss": ISSUER, "iat": int(now.timestamp()),
         "exp": int((now + timedelta(minutes=15)).timestamp()),
         "aud": "appstoreconnect-v1"},
        open(KEYFILE).read(), algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})


def call(method: str, path: str, body=None):
    """urllib, never `requests` — this Mac has no `requests` and adding one for
    a deploy script is a dependency nobody will remember."""
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", "Bearer " + token())
    if data:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return r.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, {"raw": raw.decode(errors="replace")[:400]}


def find_build(number: str):
    st, d = call("GET", f"/v1/builds?filter[app]={APP_ID}&filter[version]={number}&limit=1")
    if st != 200:
        return None, (st, d)
    items = d.get("data") or []
    return (items[0] if items else None), None


def show(b):
    a = b["attributes"]
    print(f"  build {a.get('version')}  id {b['id']}")
    print(f"    processingState    {a.get('processingState')}")
    print(f"    expired            {a.get('expired')}")
    # **`externalBuildState` IS NOT ON `builds`.** Asking for it in
    # `fields[builds]` is a 400 ("not a valid field name") and reading it off
    # the build's own attributes silently returns None — which reads as "no
    # information" when it is in fact the single attribute that says whether
    # testers have this build. It lives on `buildBetaDetail`.
    st, d = call("GET", f"/v1/builds/{b['id']}/buildBetaDetail")
    det = (d.get("data") or {}).get("attributes", {}) if st == 200 else {}
    print(f"    externalBuildState {det.get('externalBuildState') if st == 200 else f'({st})'}")
    print(f"    internalBuildState {det.get('internalBuildState') if st == 200 else f'({st})'}")


def cmd_status(number):
    b, err = find_build(number)
    if err:
        sys.exit(f"lookup failed: {err}")
    if not b:
        sys.exit(f"no build {number} on the app yet")
    show(b)
    st, d = call("GET", f"/v1/builds/{b['id']}/betaAppReviewSubmission")
    print(f"    betaReviewState   {(d.get('data') or {}).get('attributes', {}).get('betaReviewState') if st == 200 else f'({st})'}")
    for label, gid in (("Owner", OWNER_GROUP_ID), ("Friends", FRIENDS_GROUP_ID)):
        ids = group_build_ids(gid)
        if ids is None:
            print(f"    in {label:<8} group  (could not read the group)")
        else:
            print(f"    in {label:<8} group  {'YES' if b['id'] in ids else 'no'}  ({len(ids)} build(s) in the group)")


def group_builds(group_id):
    """Every build in a beta group, following pagination; None when the read fails."""
    out, url = [], f"/v1/betaGroups/{group_id}/builds?limit=200&fields[builds]=version,processingState,uploadedDate,expired"
    while url:
        st, d = call("GET", url)
        if st != 200:
            return None
        out.extend(d.get("data") or [])
        url = (d.get("links") or {}).get("next")
    return out


def group_build_ids(group_id):
    rows = group_builds(group_id)
    return None if rows is None else {x["id"] for x in rows}


def internal_state(build_id):
    st, d = call("GET", f"/v1/builds/{build_id}/buildBetaDetail")
    return (d.get("data") or {}).get("attributes", {}).get("internalBuildState") if st == 200 else f"({st})"


def cmd_builds(n="5"):
    """Read-only: the latest uploads, newest first, and which group has each."""
    st, d = call("GET", f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit={int(n)}"
                        "&fields[builds]=version,processingState,uploadedDate,expired")
    if st != 200:
        sys.exit(f"lookup failed: {st} {d}")
    owner, friends = group_build_ids(OWNER_GROUP_ID), group_build_ids(FRIENDS_GROUP_ID)
    for b in d.get("data") or []:
        a = b["attributes"]
        where = [g for g, ids in (("Owner", owner), ("Friends", friends)) if ids and b["id"] in ids]
        print(f"  {a.get('version'):>6}  {a.get('processingState'):<11} uploaded {a.get('uploadedDate')}  "
              f"expired={a.get('expired')}  groups: {', '.join(where) or '—'}")


def cmd_groups():
    """Read-only: the newest five builds each group carries."""
    for label, gid in (("Owner (internal)", OWNER_GROUP_ID), ("Friends (external)", FRIENDS_GROUP_ID)):
        rows = group_builds(gid)
        if rows is None:
            print(f"  {label}: could not read the group"); continue
        nums = sorted((int(x["attributes"]["version"]) for x in rows
                       if str(x["attributes"].get("version", "")).isdigit()), reverse=True)
        print(f"  {label}: {len(rows)} build(s); newest {', '.join(map(str, nums[:5])) or '—'}")


def cmd_owner(number, notes):
    """The INTERNAL Owner beta: never Friends, never Beta App Review. Succeeds
    only when the build is in Owner, internally IN_BETA_TESTING, and not in
    Friends — an upload or a group add alone is not availability."""
    print(f"▸ waiting for build {number} to reach VALID")
    b = None
    for i in range(60):                       # 60 x 30s = 30 minutes, bounded
        b, err = find_build(number)
        if b and b["attributes"].get("processingState") == "VALID":
            break
        state = b["attributes"].get("processingState") if b else "not visible yet"
        print(f"  [{i:02d}] {state}")
        time.sleep(30)
    if not b or b["attributes"].get("processingState") != "VALID":
        sys.exit("gave up waiting — re-run `status` later; nothing was distributed")
    bid = b["id"]
    show(b)

    friends = group_build_ids(FRIENDS_GROUP_ID)
    if friends is None:
        sys.exit("could not read the Friends group — refusing to continue blind")
    if bid in friends:
        sys.exit(f"build {number} is ALREADY in Friends — stop and tell the owner; this command never removes it")

    st, d = call("GET", f"/v1/builds/{bid}/betaBuildLocalizations")
    locs = d.get("data") or []
    if locs:
        st, _ = call("PATCH", f"/v1/betaBuildLocalizations/{locs[0]['id']}",
                     {"data": {"type": "betaBuildLocalizations", "id": locs[0]["id"],
                               "attributes": {"whatsNew": notes}}})
    else:
        st, _ = call("POST", "/v1/betaBuildLocalizations",
                     {"data": {"type": "betaBuildLocalizations",
                               "attributes": {"locale": "en-US", "whatsNew": notes},
                               "relationships": {"build": {"data": {"type": "builds", "id": bid}}}}})
    print(f"▸ what to test -> {st}")

    owner = group_build_ids(OWNER_GROUP_ID)
    if owner is not None and bid in owner:
        print("▸ already in Owner — no add")
    else:
        st, d = call("POST", f"/v1/betaGroups/{OWNER_GROUP_ID}/relationships/builds",
                     {"data": [{"type": "builds", "id": bid}]})
        print(f"▸ add to Owner -> {st}" + ("" if st in (201, 204) else f"  {d}"))

    # READ IT BACK: membership, internal availability, and Friends untouched.
    print("▸ reading it back")
    state = None
    for i in range(20):                       # up to ~5 minutes for the internal state
        state = internal_state(bid)
        if state == "IN_BETA_TESTING":
            break
        print(f"  [{i:02d}] internalBuildState {state}")
        time.sleep(15)
    owner, friends = group_build_ids(OWNER_GROUP_ID), group_build_ids(FRIENDS_GROUP_ID)
    in_owner = owner is not None and bid in owner
    in_friends = friends is None or bid in friends
    print(f"    in Owner group     {'YES' if in_owner else 'no'}")
    print(f"    internalBuildState {state}")
    print(f"    in Friends group   {'YES — NOT EXPECTED' if friends is not None and bid in friends else ('unknown' if friends is None else 'no')}")
    if not (in_owner and state == "IN_BETA_TESTING" and not in_friends):
        sys.exit("NOT available to Owner yet — see the lines above; nothing further was changed")
    print(f"✓ build {number} is available to the internal Owner group, and not in Friends")


def cmd_ship(number, notes):
    # 1 · poll until Apple has processed it. VALID is the only state that can
    #     be distributed; PROCESSING means the bits are still being chewed.
    print(f"▸ waiting for build {number} to reach VALID")
    b = None
    for i in range(60):                       # 60 x 30s = 30 minutes
        b, err = find_build(number)
        if b and b["attributes"].get("processingState") == "VALID":
            break
        state = b["attributes"].get("processingState") if b else "not visible yet"
        print(f"  [{i:02d}] {state}")
        time.sleep(30)
    if not b or b["attributes"].get("processingState") != "VALID":
        sys.exit("gave up waiting — re-run `status` later; nothing was distributed")
    bid = b["id"]
    show(b)

    # 2 · What to Test. A build with no notes can still be distributed, but the
    #     testers get a blank release, which is how 669's successors read.
    st, d = call("GET", f"/v1/builds/{bid}/betaBuildLocalizations")
    locs = d.get("data") or []
    if locs:
        st, _ = call("PATCH", f"/v1/betaBuildLocalizations/{locs[0]['id']}",
                     {"data": {"type": "betaBuildLocalizations", "id": locs[0]["id"],
                               "attributes": {"whatsNew": notes}}})
        print(f"▸ what to test  PATCH -> {st}")
    else:
        st, _ = call("POST", "/v1/betaBuildLocalizations",
                     {"data": {"type": "betaBuildLocalizations",
                               "attributes": {"locale": "en-US", "whatsNew": notes},
                               "relationships": {"build": {"data": {"type": "builds", "id": bid}}}}})
        print(f"▸ what to test  POST -> {st}")

    # 3 · add to the group.
    st, d = call("POST", f"/v1/betaGroups/{GROUP_ID}/relationships/builds",
                 {"data": [{"type": "builds", "id": bid}]})
    print(f"▸ add to Friends -> {st}" + ("" if st in (201, 204) else f"  {d}"))

    # 4 · **THE STEP THAT IS NOT THE GROUP ADD.** Without this the build sits
    #     at READY_FOR_BETA_SUBMISSION and nobody has it.
    st, d = call("POST", "/v1/betaAppReviewSubmissions",
                 {"data": {"type": "betaAppReviewSubmissions",
                           "relationships": {"build": {"data": {"type": "builds", "id": bid}}}}})
    print(f"▸ beta review submission -> {st}" + ("" if st == 201 else f"  {json.dumps(d)[:300]}"))

    # 5 · READ IT BACK. An add that reports success is not a build anybody has
    #     (667 was uploaded and never added, and nobody noticed for days).
    print("▸ reading it back")
    time.sleep(5)
    cmd_status(number)


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "groups":
        cmd_groups(); sys.exit(0)
    if len(sys.argv) == 2 and sys.argv[1] == "builds":
        cmd_builds(); sys.exit(0)
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    if sys.argv[1] == "status":
        cmd_status(sys.argv[2])
    elif sys.argv[1] == "builds":
        cmd_builds(sys.argv[2])
    elif sys.argv[1] == "owner":
        if len(sys.argv) < 4:
            sys.exit('owner <build> "What to Test" — the notes are required')
        cmd_owner(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "ship":
        note = sys.argv[3] if len(sys.argv) > 3 else "A new build."
        cmd_ship(sys.argv[2], note)
    else:
        sys.exit(__doc__)
