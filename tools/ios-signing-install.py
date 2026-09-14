"""Install the two freshly created profiles where Xcode looks for them. A
profile is named on disk by its own UUID, which is inside the signed blob, so
it is read back out rather than guessed."""
import json, os, plistlib, shutil, subprocess

vault = os.path.expanduser("~/.appstoreconnect/cupseason-dist")
dest = os.path.expanduser("~/Library/MobileDevice/Provisioning Profiles")
os.makedirs(dest, exist_ok=True)
made = json.load(open(os.path.join(vault, "profiles.json")))
for ident, info in made.items():
    raw = subprocess.run(["security", "cms", "-D", "-i", info["file"]],
                         capture_output=True, check=True).stdout
    uuid = plistlib.loads(raw)["UUID"]
    shutil.copyfile(info["file"], os.path.join(dest, uuid + ".mobileprovision"))
    print(f"       installed {ident} -> {uuid}")
