"""Create the distribution certificate for the vault's key, then the two
App Store provisioning profiles bound to it. Read-and-create only: nothing is
revoked, deleted or printed. The App Store Connect key comes from the login
keychain, exactly as tools/ios-archive.sh already reads it."""
import os, sys, json, base64, subprocess, datetime, urllib.request, urllib.error

vault = os.environ["VAULT"]


def kc(service):
    try:
        return subprocess.run(
            ["security", "find-generic-password", "-a", os.environ.get("USER", ""),
             "-s", service, "-w"],
            capture_output=True, text=True, check=True).stdout.strip()
    except Exception:
        return ""


issuer, key_id = kc("cupseason-asc-issuer"), kc("cupseason-asc-key")
keyfile = os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{key_id}.p8")
try:
    import jwt
except ImportError:
    sys.exit("       x PyJWT missing - pip3 install pyjwt cryptography")


def token():
    now = datetime.datetime.now(datetime.timezone.utc)
    return jwt.encode({"iss": issuer, "iat": int(now.timestamp()),
                       "exp": int((now + datetime.timedelta(minutes=15)).timestamp()),
                       "aud": "appstoreconnect-v1"},
                      open(keyfile).read(), algorithm="ES256",
                      headers={"kid": key_id, "typ": "JWT"})


def call(method, path, body=None):
    req = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path,
        data=json.dumps(body).encode() if body else None, method=method,
        headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            return json.load(r) if r.status != 204 else {}
    except urllib.error.HTTPError as e:
        sys.exit(f"       x Apple refused {method} {path}: HTTP {e.code} - {e.read().decode()[:400]}")


cert = call("POST", "/v1/certificates", {"data": {"type": "certificates", "attributes": {
    "certificateType": "DISTRIBUTION",
    "csrContent": open(os.path.join(vault, "req.csr")).read()}}})["data"]
open(os.path.join(vault, "cert.cer"), "wb").write(
    base64.b64decode(cert["attributes"]["certificateContent"]))
print(f"       certificate {cert['attributes'].get('certificateType')} "
      f"expires {str(cert['attributes'].get('expirationDate'))[:10]}")

bundles = {b["attributes"]["identifier"]: b["id"]
           for b in call("GET", "/v1/bundleIds?limit=200")["data"]}
stamp = datetime.date.today().isoformat()
made = {}
for ident in ["app.cupseason.ios", "app.cupseason.ios.widgets"]:
    bid = bundles.get(ident)
    if not bid:
        sys.exit(f"       x bundle id not registered: {ident}")
    p = call("POST", "/v1/profiles", {"data": {
        "type": "profiles",
        "attributes": {"name": f"CS App Store {ident} {stamp}", "profileType": "IOS_APP_STORE"},
        "relationships": {
            "bundleId": {"data": {"id": bid, "type": "bundleIds"}},
            "certificates": {"data": [{"id": cert["id"], "type": "certificates"}]}}}})["data"]
    path = os.path.join(vault, ident + ".mobileprovision")
    open(path, "wb").write(base64.b64decode(p["attributes"]["profileContent"]))
    made[ident] = {"name": p["attributes"]["name"], "file": path}
    print(f"       profile {p['attributes']['name']}")
json.dump(made, open(os.path.join(vault, "profiles.json"), "w"))
