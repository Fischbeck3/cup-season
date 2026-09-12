# TestFlight 815 · archived, blocked at signing

**2026-09-12.** Owner authorised the TestFlight push. Candidate `ca682da`
(Codex's audited client), build **815**. **Archived successfully. Export
failed, and it cannot be worked around from here.**

## What happened

```
▸ archive  build 815 (ca682da)      OK
▸ export
error: exportArchive No Accounts
error: exportArchive No signing certificate "iOS Distribution" found
** EXPORT FAILED **
```

## Why, established rather than guessed

The App Store export needs an **Apple Distribution** identity. There is not one
on this machine, in any keychain:

| Probe | Result |
|---|---|
| `security find-identity -p codesigning` (incl. invalid) | **4 identities, all "Apple Development: Jerecho Fischbeck (B5C7VAN96B)"** |
| `security find-certificate -c "Apple Distribution"` across `login.keychain-db` and `System.keychain` | **none** |
| `security find-certificate -c "iPhone Distribution"` | **none** |

**It was here earlier today.** Build 795's shipped `.ipa` is signed
`Authority=Apple Distribution: Fischbeck3 LLC (3F7BK4WVH8)`, read straight off
`~/cup-season-release-795/.../export/Cup Season.ipa` with `codesign -dvvv`. So
the certificate and its private key were present for 795 and are gone now.

`-allowProvisioningUpdates` cannot recover it: the second error, **No
Accounts**, means no Apple ID is signed into Xcode on this machine, so nothing
can request a replacement from the developer portal.

## What I did not do, and why it is the owner's call

The App Store Connect API *can* mint a new distribution certificate
(`POST /v1/certificates` with a CSR) and a matching profile, and the API
credentials for that are in the keychain. **I did not.** The authorisation was
to push a build to TestFlight, not to create a new signing identity on the
Apple Developer account. That is account-level and consequential: distribution
certificates are capped per team, a new one can push an existing one out, and
revoking the wrong one breaks every other build. It wants a deliberate decision
and the owner's eyes, not an inference from "push the build".

## The work is not lost

The archive is intact and preserved outside `/tmp`:

```
~/cup-season-release-815/run-815-ca682da.ZXcL1h/CupSeason.xcarchive   (142 MB)
```

Once a distribution identity exists, the export is seconds, not another archive:

```sh
cd <a worktree at ca682da>/apps/ios
xcodebuild -exportArchive \
  -archivePath ~/cup-season-release-815/run-815-ca682da.ZXcL1h/CupSeason.xcarchive \
  -exportPath  ~/cup-season-release-815/export \
  -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates
```

then upload and distribute:

```sh
tools/ios-archive.sh --upload      # or xcrun altool with the same .ipa
python3 tools/asc.py ship 815      # What to Test → Friends group → SUBMIT
```

## What the owner needs to do, in order

1. **Sign in to Xcode** with the Apple ID on team `3F7BK4WVH8`
   (Xcode → Settings → Accounts). This alone may restore automatic signing,
   because Xcode will fetch or create the distribution certificate itself.
2. If the certificate is genuinely revoked rather than merely absent, create a
   new **Apple Distribution** certificate and let Xcode manage the profile.
3. Re-run the export above. **No rebuild is needed**, and the build number
   stays 815 because it is derived from the commit count at `ca682da`.

## State, unchanged

- **Nothing was uploaded.** App Store Connect has not seen build 815.
- **TestFlight still serves 795.** No tester is affected.
- **No production database change.** D345 remains held and unpushed, exactly as
  Codex's preparation requires.
- Codex's workspace was not touched; the archive ran in a throwaway worktree
  at `ca682da`, now removed.
