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
  status <build>     what ASC thinks of that build number
  ship <build>       poll -> What to Test -> add to Friends -> SUBMIT -> read back
"""
import json, os, sys, time, urllib.request, urllib.error
from datetime import datetime, timedelta, timezone

import jwt

APP_ID = "6806251118"
GROUP_ID = "9f8db84a-166c-4900-b196-ea2c5459e369"   # "Friends", EXTERNAL
BASE = "https://api.appstoreconnect.apple.com"

ISSUER = os.environ.get("ASC_ISSUER_ID", "").strip()
KEY_ID = os.environ.get("ASC_KEY_ID", "").strip()
if not ISSUER or not KEY_ID:
    sys.exit("no ASC_ISSUER_ID / ASC_KEY_ID in the environment")
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
    st, d = call("GET", f"/v1/betaGroups/{GROUP_ID}/builds?limit=200")
    ids = [x["id"] for x in (d.get("data") or [])] if st == 200 else []
    print(f"    in Friends group  {'YES' if b['id'] in ids else 'no'}  ({len(ids)} build(s) in the group)")


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
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    if sys.argv[1] == "status":
        cmd_status(sys.argv[2])
    elif sys.argv[1] == "ship":
        note = sys.argv[3] if len(sys.argv) > 3 else "A new build."
        cmd_ship(sys.argv[2], note)
    else:
        sys.exit(__doc__)
