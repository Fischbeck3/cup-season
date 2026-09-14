# TestFlight signing · diagnosis before rebuilding — 2026-09-14

Branch `claude/testflight-890`, worktree `~/cup-season-signing`, from the
reviewed application commit **`1bc307f`**. Codex's workspace
(`~/cup-season-paired-release`) was **read only**: the reviewed archive was
copied out of it, never modified.

Read first: `docs/reviews/2026-09-14-paired-release-evidence.md` at `dfc232c`
on `origin/codex/paired-release-2026-09-14`.

**No credential contents appear in this document, and nothing was revoked.**

---

## 1 · What is actually wrong

The prior reports said the operator "has not been given cloud-signing access".
That is the symptom Apple prints. Read from the account itself, the cause is
simpler and one level deeper:

| Read (read-only, via the existing App Store Connect API key) | Result |
|---|---|
| `GET /v1/certificates` | **one** certificate on the whole team: `DEVELOPMENT`, expires 2027-08-27 |
| `GET /v1/profiles` | **zero** provisioning profiles |
| `GET /v1/bundleIds` | `app.cupseason.ios`, `app.cupseason.ios.widgets`, `*` — both shipping ids registered |
| `GET /v1/users` | one member, roles `ACCOUNT_HOLDER` + `ADMIN`, `provisioningAllowed: true` |
| `GET /v1/apps` | reachable — the key authenticates and reads fine |

Locally:

| Check | Result |
|---|---|
| `security find-identity -v -p codesigning` | 4 identities, **all** `Apple Development` |
| every keychain in the search list, searched for `Apple Distribution` / `iPhone Distribution` | **none** (two `Developer ID` certs exist — those are for Mac apps outside the store and cannot sign an iOS App Store build) |
| `~/Library/MobileDevice/Provisioning Profiles` | **empty** |
| Xcode account items in the keychain | none |
| any `.p12` / `.cer` backup under Desktop, Documents, Downloads, `~/.appstoreconnect` | none |
| fastlane / `match` | not present |

**So: there is no iOS distribution certificate anywhere — not on this Mac, and
not in the Apple Developer account.** Cloud-managed signing had nothing to
fetch, which is why `signingStyle: automatic` fails.

## 1a · When it broke, and the likeliest reason — read 2026-09-14

`GET /v1/apps/<app>/builds` returns **11 builds**, and the most recent uploads
are:

| Uploaded | Build | State |
|---|---|---|
| 2026-09-12 | **795** | VALID |
| 2026-09-11 | 791 | VALID |
| 2026-09-09 | 762 | VALID |
| 2026-09-08 | 758 | VALID |

**Distribution signing worked on 2026-09-12** — build 795 uploaded that day — and
the first failed export was 2026-09-13 (build 835). So the certificate was
present on the 12th and absent on the 13th.

Nothing in the account was misconfigured in that window, and no permission was
withdrawn: the Apple ID is still `ACCOUNT_HOLDER` with `provisioningAllowed:
true`. An Apple Distribution certificate is valid for one year, and Apple drops
expired certificates from the list — which is exactly the state the account is
in, with **no** distribution certificate of any kind remaining. **The likeliest
explanation is that the certificate reached its expiry on or about 2026-09-12,
having signed build 795 on its last day.** This cannot be proved from here,
because an expired certificate is no longer returned by the API; revocation
would leave the same trace. Either way the remedy is the same, and it is
ordinary annual maintenance rather than a repair.

Two corrections to the record, both mine or inherited:

- earlier reports (including my own on 2026-09-13) said the operator needed to
  be *granted* cloud-signing access. That access is present and was never the
  problem.
- builds 835, 855, 857 and 890 were **archived but never uploaded**. The last
  build actually on App Store Connect is **795**. Saying "the workflow that
  produced 669 through 835" was wrong; it produced 669 through 795.

## 2 · Why the API key does not fix it by itself

`tools/ios-archive.sh` already passes the key to both phases
(`-allowProvisioningUpdates -authenticationKeyPath/-KeyID/-KeyIssuerID`), and
the key is present and valid on this machine. Reproduced today at `1bc307f`,
exporting a copy of the reviewed archive with the key supplied:

```
error: exportArchive Cloud signing permission error
error: exportArchive No signing certificate "iOS Distribution" found
exit 70
```

An App Store Connect **API key cannot use a cloud-managed distribution
certificate** — cloud-managed signing is bound to an Apple ID signed into
Xcode, not to an API key. The key can *create* a certificate if its role allows,
but it cannot borrow the account's managed one. That is the whole gap between
"the key works" (it does: it reads the app, the users, the bundle ids) and "the
export can sign".

The owner's Apple ID is `ACCOUNT_HOLDER` with `provisioningAllowed: true`, so
**no permission needs to be granted to anyone.** The earlier recommendation —
"the Account Holder or an Admin grants this Apple ID access to the cloud-managed
distribution certificate" — was aimed at a permission that is already in place.
What is missing is the certificate itself.

## 3 · The reviewed artifact is eligible

| | |
|---|---|
| Archive | `run-890-1bc307f` — present in Codex's workspace, copied to `apps/ios/build/archive/reuse-890` |
| `CupSeason.app` | `CFBundleShortVersionString` 1.0.0, `CFBundleVersion` **890** |
| `CupSeasonWidgets.appex` | 1.0.0 / **890** — app and widget agree |
| Archive `ApplicationProperties:CFBundleVersion` | 890 |
| Source | `1bc307f`; this worktree's `git rev-list --count HEAD` is **890**, so a rebuild would mint the same number from the same source |
| Build-number availability | `python3 tools/asc.py status 890` → *"no build 890 on the app yet"* — 890 is free |

Nothing needs rebuilding. The archive only needs to be signed and exported.

## 4 · The two ways to restore signing

Both create the first distribution certificate; **neither revokes anything**,
and the account currently has 0 of its distribution slots used.

**A · The owner's own Xcode workflow (the established one).**
Xcode → Settings → Accounts → sign in with the Account Holder Apple ID → select
the team (`3F7BK4WVH8`) → *Manage Certificates…* → **+** → **Apple
Distribution**. Xcode creates the certificate and places it in the login
keychain. Nothing else changes. I then export the reviewed 890 archive and
upload. This is the workflow that produced the earlier TestFlight builds.

**B · From this machine, using the API key already here.**
Generate a private key and CSR locally, `POST /v1/certificates` with
`certificateType: DISTRIBUTION`, import the returned certificate beside its key
in the login keychain, then export and upload. Additive, scriptable, repeatable;
the private key stays on this Mac and is never printed. This is one credential
creation on the owner's Apple Developer account, which is why it is the owner's
call and not mine — my attempt to run it was correctly held for approval.

Either way, once an `Apple Distribution` identity exists the rest is unchanged:
`-allowProvisioningUpdates` with the API key can then mint the two App Store
provisioning profiles (`app.cupseason.ios`, `app.cupseason.ios.widgets`) itself.

## 5 · What is ready to run the moment signing exists

```sh
cd ~/cup-season-signing/apps/ios
xcodebuild -exportArchive \
  -archivePath build/archive/reuse-890/CupSeason.xcarchive \
  -exportPath  build/archive/reuse-890/export \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY" -authenticationKeyID "$KID" -authenticationKeyIssuerID "$ISS"
xcrun altool --upload-app -f build/archive/reuse-890/export/CupSeason.ipa -t ios \
  --apiKey "$KID" --apiIssuer "$ISS"
python3 ../../tools/asc.py status 890      # processing state
python3 ../../tools/asc.py ship 890        # attach to the beta group
```

(The issuer and key id come from the login keychain, as `tools/ios-archive.sh`
already reads them; they are never written into this public repo.)

**Delivery is not upload.** The report will name: the source SHA, the build
number actually available in App Store Connect, its processing state, and
whether it is attached to the owner's existing beta group.

## 5a · What is already clear downstream of signing

Checked read-only today, so none of it can surprise the upload:

| | |
|---|---|
| Export compliance | `ITSAppUsesNonExemptEncryption: false` is in the archived `Info.plist` for build 890 — no post-upload questionnaire will block it |
| Beta group | **"Friends"**, `isInternalGroup: false`, **4 testers** |
| Consequence | an **external** group means **Beta App Review** stands between a processed build and a tester's phone. Upload is not delivery, and neither is `VALID`; the build has to clear review and be attached |
| App record | reachable; 11 builds in its history |

## 6 · Scope

No feature, brand, database or Edge change belongs to this recovery, and none
was made. The only changes on this branch are this document and the follow-up
packet beside it.
