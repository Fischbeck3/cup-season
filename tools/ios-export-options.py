"""Write the manual-signing ExportOptions for tools/ios-archive.sh.

The two profile NAMES are read from the vault rather than committed here: they
carry the date they were made, and a name in the repository would rot the next
time the identity is refreshed. VAULT and OPTS arrive in the environment.
"""
import json, os, plistlib

vault = os.environ["VAULT"]
made = json.load(open(os.path.join(vault, "profiles.json")))
plistlib.dump({
    "method": "app-store-connect",
    "teamID": "3F7BK4WVH8",
    "signingStyle": "manual",
    "signingCertificate": "Apple Distribution",
    "provisioningProfiles": {ident: info["name"] for ident, info in made.items()},
    "uploadSymbols": True,
    "manageAppVersionAndBuildNumber": False,
    "destination": "export",
}, open(os.environ["OPTS"], "wb"))
