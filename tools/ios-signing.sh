#!/bin/sh
# Cup Season — put a distribution signing identity on this Mac (2026-09-14).
#
# WHY THIS EXISTS. An App Store Connect API key cannot use a CLOUD-MANAGED
# distribution certificate: the key authenticates, reads the app and mints
# profiles, and then `xcodebuild -exportArchive` fails with "Cloud signing
# permission error / No signing certificate iOS Distribution found". Builds
# 835 through 890 archived and never shipped for exactly that reason, after the
# previous distribution certificate reached its one-year expiry.
#
# WHAT IT DOES. Generates a private key HERE, asks Apple for a distribution
# certificate against it, creates the two App Store provisioning profiles bound
# to that certificate, installs the profiles where Xcode looks, and leaves the
# identity in a vault at ~/.appstoreconnect/cupseason-dist (mode 700).
# `tools/ios-archive.sh` picks the vault up on its own and exports manually.
#
# WHAT IT NEVER DOES. It never revokes or modifies an existing certificate,
# never writes to the login keychain, never prints a key, and never touches
# application source. The vault is outside the repository, which is public.
#
# WHEN TO RUN IT. Once a year, when the certificate expires — Apple stops
# returning an expired certificate, so the symptom is the export error above
# and not a warning. Re-running reuses the key already in the vault.
set -eu
DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT="$HOME/.appstoreconnect/cupseason-dist"
mkdir -p "$VAULT"; chmod 700 "$VAULT"

if [ -f "$VAULT/key.pem" ]; then
  echo "- reusing the signing key already in the vault"
else
  openssl genrsa -out "$VAULT/key.pem" 2048 2>/dev/null
  chmod 600 "$VAULT/key.pem"
  echo "- generated a signing key in $VAULT"
fi
openssl req -new -key "$VAULT/key.pem" -out "$VAULT/req.csr" \
  -subj "/CN=Cup Season Distribution/O=Cup Season/C=US" 2>/dev/null

VAULT="$VAULT" python3 "$DIR/ios-signing-create.py"
python3 "$DIR/ios-signing-install.py"

P12=$(openssl rand -hex 16)
openssl x509 -inform DER -in "$VAULT/cert.cer" -out "$VAULT/cert.pem" 2>/dev/null
openssl pkcs12 -export -legacy -inkey "$VAULT/key.pem" -in "$VAULT/cert.pem" \
  -name "Cup Season Distribution" -out "$VAULT/identity.p12" -passout "pass:$P12" 2>/dev/null \
  || openssl pkcs12 -export -inkey "$VAULT/key.pem" -in "$VAULT/cert.pem" \
       -name "Cup Season Distribution" -out "$VAULT/identity.p12" -passout "pass:$P12" 2>/dev/null
chmod 600 "$VAULT/identity.p12"
printf '%s' "$P12" > "$VAULT/identity.pass"; chmod 600 "$VAULT/identity.pass"
echo "- identity ready. tools/ios-archive.sh --upload will now sign from it."
