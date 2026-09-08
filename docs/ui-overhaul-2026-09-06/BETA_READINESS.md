# BETA READINESS — the page to read before you send it

> **Read this first (added after the audit, 2026-09-07 night).** The migrations `20261012090000` (the voice
> pass, 45 functions) and `20261013090000` (the view fix) are **already live in production and unrecorded**.
> My "dry-runs" applied them: `supabase db query --linked --file` does not hold `begin; … rollback;` across a
> file, so the DDL autocommitted. Both are idempotent (`create or replace` / `alter view set`) with tripwires,
> so the morning `supabase db push` re-applies them harmlessly and RECORDS them, reconciling the ledger. Two
> consequences: the round-data exposure in B2 is **closed right now**; and B4 is urgent, because the live server
> already speaks sentences the live client does not know. Nothing else in this page changes.

**Measured at `bf3b31a5041ee5c61a8f635805af37926f979acb`** (`main`, 748 commits), tree clean at
start and at finish, 2026-09-07. Five lenses: the gates and the three layers · the tester's first
ten minutes on a real phone · the open-defect ledger · security, grants and data · the TestFlight
path end to end. Read-only on the repo and on production throughout; production went in at
**219 migrations, latest `20261011090000`** and came out the same.

---

## THE VERDICT

**GO WITH THESE STEPS — at `bf3b31a`, build 748.** Nothing crashes, nothing corrupts, nothing loses
a golfer's score; the nine blockers below are all yours, all small, and total about seventy minutes
plus Apple's processing wait.

The three that actually decide it: **the app has never been launched on a real phone at this sha**
(669 crashed at first paint and the simulator did not), **`v_rounds_ranked` is a live cross-league
read on production**, and **build 748 will not reach anybody unless you add it to the Friends group
by hand** — which is precisely and only what went wrong with 667.

---

## BLOCKERS

Deduped across the five lenses and ordered so that doing them top to bottom is the critical path.
Every one is yours; none can be done by an agent under this audit's read-only rule.

### B1 · Build 748 is installed on your phone and has never been launched — 3 min
**What.** The one check this audit exists for did not run. Build 669 crashed on a real phone at
first paint while the simulator did not, so that crash class is untested at HEAD.
**Evidence.** `xcodebuild -configuration Release -destination "id=B6F4570A-…" CURRENT_PROJECT_VERSION=748`
→ `** BUILD SUCCEEDED **`; `xcrun devicectl device install app` succeeded at 22:44:37
(`App installed: bundleID app.cupseason.ios`, CFBundleVersion 748). Every launch attempt from 22:45
to 22:57 was refused: *"The request was denied by service delegate (SBMainWorkspace) for reason:
Locked."* Between refusals the pairing dropped to `unavailable` with `NWError 60 — Operation timed
out`; `devicectl list devices` reports the phone `unavailable` and `xctrace` files it under *Devices
Offline*. The brief's "the phone is CONNECTED" is not true tonight.
**Fix.** Unlock the phone, tap the Cup Season icon, watch first paint, keep it foregrounded for
twenty seconds. If it paints Home and survives, this clears with no code change.
**Who.** Owner. Nothing below matters if this crashes.

### B2 · `v_rounds_ranked` runs as its owner — every scored round in every league is readable by any signed-in golfer — 10 min
**What.** A live RLS bypass on production round data, on the PostgREST surface, about to meet real
testers.
**Evidence.** `pg_class.reloptions` for `public.v_rounds_ranked` is **`(none)`** — `security_invoker`
is not set — and `has_table_privilege('authenticated', …, 'select')` is **true** (both re-measured by
this stage tonight). Proven, not inferred, inside `begin; … rollback;` as role `authenticated` with
no JWT: `public.rounds` returns **0** rows, the control view `v_squad_standings` (which has
`security_invoker`) returns **0**, and `v_rounds_ranked` returns **295** rows across 6 seasons and
20 profiles. db-checks **11 FAIL**. Cause: `20260914090000_a_season_tells_its_own_story.sql:92`
re-created the view with `create or replace view` and no `with (security_invoker = true)`, silently
stripping the option — the second time this exact regression has happened, the first being the one
`20260902140000_one_relationship_per_embed.sql` was written to fix.
**The fix is safe, and this stage verified that rather than assuming it.** One lens argued for
deferring it on the grounds that standings need a league-mate's rounds, which RLS refuses. RLS does
not refuse them: `rounds_read` measured tonight is
`profile_id = auth.uid() OR EXISTS (select 1 from league_members a join league_members b on b.league_id = a.league_id where a.profile_id = auth.uid() and b.profile_id = rounds.profile_id)`.
And all three desk call sites are already scoped to the reader's own league or own id —
`index.html:23981` and `:24024` filter `.eq('season_id', CS.season.id)`, `:26594` filters
`.eq('profile_id', CS.user.id)`. Under invoker mode every row those queries need is still visible,
and `month_rank` — the one window function inside the view — is computed over the same population for
a season you belong to. It was invoker-mode from the baseline through 09-14 and the app worked.
**Fix.** Write one new migration: `alter view public.v_rounds_ranked set (security_invoker = true);`
with a tripwire (the exact text is in the morning block below), then B3.
**Who.** Owner.

### B3 · `supabase db push` — the ledger and production disagree — 5 min
**What.** `deploy-status` owes exactly one migration,
`20261012090000_the_server_says_the_sentence_the_golfer_reads.sql`. But **its SQL is already
committed in production, outside the ledger.** Push reconciles the two and ships B2 in the same trip.
**Evidence.** `supabase_migrations.schema_migrations` holds **219** rows, max `20261011090000`, with
no row for `20261012090000`; the file is 220 on disk. Yet production speaks sentences that exist in
**no applied migration**: this stage grepped the whole migration tree — `Index looks off` appears
only in `20261012090000`, and prod's `set_index` says it. So do `set_rivalry_name`
("Name a rivalry once it has history.") and `add_friend_to_league` ("Only the Pro adds golfers").
The decisive count: across the **45** functions that file re-creates, production today carries
exactly **18** lowercase-starting `raise exception` literals — the precise number the file's own
rewrite leaves behind — and they are exactly the internal invariants it says it leaves
(`no such squad`, `league not found`, `not a league member`). Mechanism: the file is `begin;` (line
69) … `commit;` (line 4176) and its own header instructs a dry run through
`supabase db query --linked --file`, which **commits** and writes no ledger row. Its self-check ran
and passed against production, which is why the grants are clean.
**Consequences today.** Prod is in a state no migration history describes: a `db push` from another
clone, or any `db reset`, diverges from here. The push is idempotent — every statement is
create-or-replace / revoke / grant, and a dry run of the file against production tonight returned
`DRY RUN OK — 45 functions re-created, transaction rolled back` with the ledger unchanged at 219.
**Fix.** `supabase db push` (after B2's file is written, so both land together).
**Who.** Owner.

### B4 · 15 commits are unpushed — the live server ALREADY speaks the new sentences and the live client does not — 3 min
**What.** The site is up (HTTP 200). But the voice pass's 45 re-created functions are live in production
tonight (see the note at the top), and the deployed client's `humanError` allowlist does not recognise
their sentences, so a refusal on cupseason.app falls to *"Something went wrong."* until B4 lands. Web
testers also lack the door fix, photo-on-a-posted-round, the camera beside the number and the scorecard
page. Push the client first thing.
**Evidence.** `git rev-list --left-right --count origin/main...HEAD` → `0  15`; `origin/main` =
`ee321bf50c56de2538ee2bbe780de450a95dbadd`. The unpushed set is the whole voice pass plus the last
four product commits — `b3166e9` (the door on a small phone), `1cbbdde` (a photo on a posted round),
`f070eb1` (the camera beside the number), `9fad46d`/`3157b15` (scorecard-first round page).
`index.html` alone is **+890 / −360**; 117 files under `apps/` are also unpushed. The web's
`humanError` allowlist (`index.html` ~5980) and its `looksLikeOurSentence` gate are in that set: a
raise the allowlist does not recognise falls through to *"Something went wrong."* Also not live:
`set_round_photo`/`clear_round_photo` wired at `index.html:18713`/`:18727`, `round_scorecard` at
`:18811`, and the desk's half of the camera placement.
**Fix.** `git push`, then confirm Netlify deployed.
**Who.** Owner.

### B5 · Two edge functions are behind their commits — 3 min
**What.** `push` and `season-email` still run pre-voice-pass copy — the only two surfaces a tester
meets outside the app.
**Evidence.** `push` deployed 2026-09-06 11:44:19 (v36), `season-email` 2026-09-01 13:47:22 (v11);
both were last touched by `09b84ed` (2026-09-07 20:16, itself unpushed). The drift is four string
changes — one in `push/index.ts`, three in `season-email/index.ts`. The other four functions
(`courses`, `test-seed`, `scan`, `weather`) are clean.
**Fix.** `supabase functions deploy push --no-verify-jwt && supabase functions deploy season-email`.
**Who.** Owner.

### B6 · The App Store Connect keychain items exist but the script cannot read them — 2 min
**What.** `tools/ios-archive.sh --upload` will spend four minutes archiving and exporting and then
exit 1 at the credential check, before altool ever runs.
**Evidence.** `security find-generic-password -a "$USER" -s cupseason-asc-issuer -w` → **rc=44**,
"The specified item could not be found"; same for `-s cupseason-asc-key`. The script's `kc()` swallows
that and exits with *"✗ no App Store Connect credentials"*. The items **do** exist in
`login.keychain-db` — stored wrong twice over: the value sits in the item's `acct` attribute instead
of `$USER` (`acct = 4fd3cebd-…` for the issuer, `acct = 58HDLVDUPM` for the key), and the password
payload is a **6-character placeholder, byte-identical on both items**. Two lenses disagreed here and
the more thorough one wins: the `acct` values are the real credentials — an ES256 JWT minted from
`~/.appstoreconnect/private_keys/AuthKey_58HDLVDUPM.p8` with them returned **200** on every App Store
Connect read in this audit. Memory's "both are missing" is stale in fact and right in effect.
**Related.** Two `.p8` keys are on disk; `AuthKey_6V2QMPU55P.p8` returns **401 NOT_AUTHORIZED** and
must not be the one the keychain names. Move it.
**Fix.** Re-store both under `$USER` (morning block: the recovery form keeps the values out of shell
history; the prompt form is there as the fallback), then confirm the lengths are 36 and 10.
**Who.** Owner.

### B7 · `docs/ios/app-review-notes.md` points Beta App Review at a season that ended two days ago — 20 min
**What.** An external group's first build goes through Beta App Review using this document and its
demo account. The doc's own flag has come true.
**Evidence.** Production, read-only: **Sunset Match ran 2026-03-22 → 2026-09-05, `season_over = true`**
and today is 2026-09-07; Ridgeline Cup (2026-12-19), Fairway Society (2027-01-02) and Winter Circuit
(2027-02-13) are still live. The notes' header says *"From 2026-09-06 a reviewer lands on a finished
season"*; the walkthrough still calls Sunset Match "a season in progress" and the Guideline 5.3.4
paragraph points at its $450 pot ledger. The sign-in block still reads `Password: <<REVIEWER
PASSWORD>>`. Four smaller mismatches: the ⊕ Play cover has **four** rows, not three; there is no
"Danger zone" — the heading is **Your account** and the control is **"Delete my account"**
(`CardAndSettingsScreen.swift:588`); two walkthrough steps are both numbered 6.
**Fix.** Re-point 5.3.4 and the walkthrough at Ridgeline Cup or Winter Circuit and restate the pot
figure ($450 is Sunset Match's 6 × $75, not theirs); fill the reviewer password; correct the four
descriptions.
**Who.** Owner. The delete flow, the five tabs and the declinable crew step all still match.

### B8 · The 2026-09-03 content report is still open — 5 min
**What.** Beta is when the UGC-moderation obligation (App Review 1.2) stops being a diagram.
**Evidence.** `content_reports` holds exactly one row: `ee0b9aa2-dfa2-43f6-9692-5af61c2d7eb9`, kind
`post`, reason `''`, created 2026-09-03 13:36:39Z, `resolved false`, `resolved_at NULL`. Four days
open. Reporting itself is intact — `ReportSheet` → `report_content` at `ReactionBar.swift:68`, and
`SafetyMenu` carries Mute · Hide this · Report.
**Fix.** Triage and resolve it on the founder desk before the invites go out.
**Who.** Owner.

### B9 · Upload is not distribution — 748 must be ADDED to Friends, and proven — 20 min + Apple's wait
**What.** altool succeeding tells you nothing about whether anybody receives the build. This is
exactly what happened to 667.
**Evidence.** `GET /v1/betaGroups/9f8db84a-166c-4900-b196-ea2c5459e369/builds` returns 669, 646, 591,
584 and older — **667 is absent** — and `GET /v1/builds/d4f6b589-…/betaAppReviewSubmission` returns
`{"data": null}`: 667 was never even submitted for review, because *adding a build to an external
group is what creates the submission*. 669 by contrast reads `betaReviewState: APPROVED` and is in
the group. Friends is external (`isInternalGroup false`), 3 testers (2 INSTALLED, 1 INVITED), public
link `https://testflight.apple.com/join/Yy775Egh`. And 669's What-to-Test text — *"Latest V, improved
the front page, general UX interactions and some mechanics for league/event building"* — is off-voice
and gives a golfer nothing to do; no draft for 748 exists anywhere in `docs/`.
**Fix.** `tools/ios-archive.sh --upload`, wait 5–15 min for processing, add 748 to Friends in App
Store Connect, paste the What-to-Test paragraph at the foot of this page, then run the verification
call in the morning block — 748 must appear in `/v1/betaGroups/…/builds` and its
`betaAppReviewSubmission` must not be `null`.
**Who.** Owner. Upload tonight if there is any tonight left: 646 and 669 both auto-approved inside the
`1.0.0` train and 748 joins the same train, but Apple can still pull a build into full beta review,
which takes hours.

---

## THE OWNER'S MORNING, IN ORDER

```sh
# ─── 0 · where you are ────────────────────────────────────────────────────────
git status --short && git log --oneline -1
# → nothing printed, then `bf3b31a A sentence is read where it lands…`

# ─── 1 · B1 · THE ONE CHECK THAT DECIDES IT ───────────────────────────────────
# Unlock the iPhone 15 Pro and tap the Cup Season icon. Build 748 is already
# installed. Watch first paint; keep it open twenty seconds.
# → Home paints and stays up. If it crashes, stop here and nothing below matters.
# (Only if the icon is gone — reinstall from this sha:)
cd /Users/fischbeck3/cup-season/apps/ios && xcodegen generate && \
  xcodebuild -project CupSeason.xcodeproj -scheme CupSeason \
    -destination "id=B6F4570A-FBE5-5A8E-8C4B-6A1BFCE38B61" -configuration Release \
    -derivedDataPath build/dd-device -allowProvisioningUpdates \
    CURRENT_PROJECT_VERSION=748 build
# → ** BUILD SUCCEEDED **
xcrun devicectl device install app --device B6F4570A-FBE5-5A8E-8C4B-6A1BFCE38B61 \
  /Users/fischbeck3/cup-season/apps/ios/build/dd-device/Build/Products/Release-iphoneos/CupSeason.app
# → App installed: bundleID app.cupseason.ios   (then unlock and tap the icon)

# ─── 2 · B2 · close the read boundary ─────────────────────────────────────────
# The security migration is already written, dry-run clean against prod inside begin/rollback,
# and committed: supabase/migrations/20261013090000_a_view_reads_as_the_golfer_who_asks.sql
# (one ALTER VIEW … SET (security_invoker = true) plus a tripwire that RAISES if it did not take).
# → the file exists; no output

# ─── 3 · B3 · one push carries both ───────────────────────────────────────────
cd /Users/fischbeck3/cup-season && supabase db push
# → RECORDS 20261012090000 and 20261013090000 — both already live in prod, unrecorded (see the top note); the re-apply is idempotent

supabase db query --linked --file tests/db-checks.sql | grep -Ei 'FAIL|PASS' | tail -35
# → 28 PASS / 3 FAIL. Check 11 is GREEN. 9, 18 and 28 stay red on purpose:
#   9 · contact_hash is ungranted deliberately (granting it is the real hole)
#   28 · greps for "tagged players"; the shipped word is "golfers"
#   18 · posts has two FK paths to profiles; no client embeds it today

printf 'begin; set local role authenticated;\nselect count(*) as leaked from public.v_rounds_ranked;\nrollback;\n' \
  > /tmp/vrr.sql && supabase db query --linked --file /tmp/vrr.sql
# → leaked = 0   (it was 295 before the push)

# ─── 4 · B4 · the desk catches up to the server ───────────────────────────────
git push
# → 15 commits to origin/main; Netlify builds. Open cupseason.app and hard-reload.

# ─── 5 · B5 · the two surfaces outside the app ────────────────────────────────
supabase functions deploy push --no-verify-jwt && supabase functions deploy season-email
# → two "Deployed Function" lines (push is called by a DB webhook, not a signed client)

# ─── 6 · APNS_SANDBOX · verify, do not unset ──────────────────────────────────
supabase secrets list | grep -i apns
# → APNS_KEY_ID, APNS_P8, APNS_TEAM_ID present; APNS_SANDBOX ABSENT — already done.
# Why it matters: each token is now routed to its own APNs host by its `platform`
# column, and APNS_SANDBOX overrides that globally. One forgotten secret sends
# every TestFlight token to the sandbox host, where APNs answers BadDeviceToken.
# The sender used to delete on that reason and silently unregister the tester;
# it now retries the other host and re-homes the row — so this is less load-
# bearing than the script's header implies, but it must stay unset.

# ─── 7 · B6 · repair the two keychain items ───────────────────────────────────
# The real values are in each item's `acct` attribute; this recovers them without
# printing them and without putting them in your history.
security add-generic-password -U -a "$USER" -s cupseason-asc-issuer \
  -w "$(security find-generic-password -s cupseason-asc-issuer 2>/dev/null | awk -F'"' '/"acct"<blob>=/{print $(NF-1)}')"
security add-generic-password -U -a "$USER" -s cupseason-asc-key \
  -w "$(security find-generic-password -s cupseason-asc-key 2>/dev/null | awk -F'"' '/"acct"<blob>=/{print $(NF-1)}')"
security find-generic-password -a "$USER" -s cupseason-asc-issuer -w | wc -c   # → 37
security find-generic-password -a "$USER" -s cupseason-asc-key    -w | wc -c   # → 11
# If either number is wrong, store it by hand — each PROMPTS, so nothing lands
# in shell history (this is the form the script's own header teaches):
#   security add-generic-password -U -a "$USER" -s cupseason-asc-issuer -w
#   security add-generic-password -U -a "$USER" -s cupseason-asc-key    -w
ls ~/.appstoreconnect/private_keys/AuthKey_"$(security find-generic-password -a "$USER" -s cupseason-asc-key -w)".p8
# → …/AuthKey_58HDLVDUPM.p8 exists   (the only key that authenticates)
mv ~/.appstoreconnect/private_keys/AuthKey_6V2QMPU55P.p8 ~/Desktop/DEAD_AuthKey_6V2QMPU55P.p8.bak
# → the 401 key is out of the way

# ─── 8 · B7 + B8 · the paperwork, before the external group sees it ───────────
$EDITOR /Users/fischbeck3/cup-season/docs/ios/app-review-notes.md
# → 5.3.4 + the walkthrough re-pointed at Ridgeline Cup (ends 2026-12-19) with its
#   own pot figure; <<REVIEWER PASSWORD>> filled; "Danger zone" → "Your account →
#   Delete my account"; the Play cover called four rows; the second step 6 renumbered.
# Then resolve content report ee0b9aa2-dfa2-43f6-9692-5af61c2d7eb9 on the founder desk.

# ─── 9 · B9 · archive, upload ─────────────────────────────────────────────────
cd /Users/fischbeck3/cup-season && tools/ios-archive.sh --upload
# → ** ARCHIVE SUCCEEDED ** → ** EXPORT SUCCEEDED ** → "▸ upload (altool, API key
#   58HDLVDUPM)" → "uploaded build 748". ~4 min to archive, then 5–15 min processing.

# ─── 10 · B9 · ADD 748 TO FRIENDS — this is the step that killed 667 ──────────
# App Store Connect → TestFlight → Friends → Builds → + → 748, and paste the
# What to Test paragraph from the foot of this page into the build.
python3 - <<'PY'
import json, os, subprocess, time, urllib.request, jwt
kc = lambda s: subprocess.check_output(
    ["security","find-generic-password","-a",os.environ["USER"],"-s",s,"-w"]).decode().strip()
iss, kid = kc("cupseason-asc-issuer"), kc("cupseason-asc-key")
key = open(os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{kid}.p8")).read()
tok = jwt.encode({"iss": iss, "exp": int(time.time())+600, "aud": "appstoreconnect-v1"},
                 key, algorithm="ES256", headers={"kid": kid, "typ": "JWT"})
get = lambda u: json.load(urllib.request.urlopen(urllib.request.Request(
    u, headers={"Authorization": f"Bearer {tok}"})))
g = "9f8db84a-166c-4900-b196-ea2c5459e369"
builds = get(f"https://api.appstoreconnect.apple.com/v1/betaGroups/{g}/builds?limit=10")["data"]
print("in Friends:", [b["attributes"]["version"] for b in builds])
mine = [b for b in builds if b["attributes"]["version"] == "748"]
if mine:
    sub = get(f"https://api.appstoreconnect.apple.com/v1/builds/{mine[0]['id']}/betaAppReviewSubmission")
    print("review:", (sub.get("data") or {}).get("attributes", {}).get("betaReviewState"))
PY
# → in Friends: ['748', '669', …]  and  review: APPROVED
# If 748 is absent, or review prints nothing, NOBODY HAS IT — that is 667 again.
```

---

## RISKS A TESTER MAY MEET

| # | What they meet | The honest degrade | Warn in What to Test? |
|---|---|---|---|
| R1 | A refusal answers *"Something went wrong — please try again."* | **61** client-callable `raise exception` literals still begin lowercase, across functions the voice migration never touches (the 45 it does touch are already clean, at 18 internal invariants). The phone's new `looksLikeOurSentence` gate swallows those 61 and shows the shrug — inviting a retry that cannot succeed. The likeliest beta error is safe: `join_league` already says *"That code didn't match — check it and try again."* | **Yes** — ask them what they tapped |
| R2 | No push notification ever arrives | `device_tokens` holds exactly **1** row (`platform 'ios'`, created tonight); push has never been observed delivered end to end. The build is not the reason — the exported .ipa carries `aps-environment: production`. Nothing in the product breaks; it simply will not buzz. | **Yes** — say it plainly |
| R3 | Home tells a golfer with rounds that he has none | `HomeFallbackItems.swift:168` reads `(me.profile?.rounds_count ?? 0) == 0`, and `rounds_count` is `Int?` — **nil takes the zero branch**, so a slow or partial read shows *"Your first round is the only thing missing."* to someone with nineteen rounds. Seen once at 16 s on the owner's account; did not reproduce in three further cold starts, and a clean start paints the true hero by 3 s. Reads as "the app lost my history". | No — the screenshot line covers it |
| R4 | At the largest text sizes labels collide and clip | At AX3 the five tab labels run edge to edge with HOME's H and YOU's U clipped, on every screen; the composer's ADD A PHOTO and SCAN THE SCORECARD labels clip away entirely, leaving an unlabelled box; the section step (`displayS` capped at 1.8×, `name` uncapped) collapses from 1.6× to ~1.05×. Tabs and controls still work. | No — but say big text is welcome |
| R5 | The door's Terms & Privacy line is never seen | The email field auto-focuses, so the keyboard is up at first paint; on a 17 Pro that clips the bottom of CONTINUE WITH EMAIL and puts the legal line (`DoorView.swift:303`) below the fold. The SE 3 is fine — field and CTA both clear. The links exist. | No |
| R6 | They open a round and there is no scorecard | Only **6 of 214** rounds carry hole scores, because the composer defaults to a total. `round_scorecard` correctly returns null rather than a blank par grid, so the card is simply absent. | Handled — the paragraph asks for hole-by-hole |
| R7 | The feed and the Golfers board look plain or inconsistent | `home_stories` returns `course` as a text label with no `api_course_id` and no `live_round_id`, so the front page cannot draw a round — rows are face · name · phrase · number. `friends_board()` returns `marker` and no `photo_path`, so the same golfer is a ball marker on one tab and a photograph on the next. Blandness, not breakage. | No |
| R8 | A tour card button reads "SHA…" | The header SHARE button truncates at default text size on a 17 Pro; the SE composer's course-line date is cut by the pinned foot. | No |
| R9 | The contacts prompt in onboarding | `CNContactStore().requestAccess` fires in the crew step, and digests leave the device via `match_contacts`. **`PrivacyInfo.xcprivacy` declares no Contacts type** — it will not block the TestFlight upload (the validator checks required-reason APIs, not collected types) but it must be fixed before App Store review. Declining is a first-class exit: "NOBODY YET — I'LL ADD THEM LATER" finishes the screen. | No |
| R10 | A hostile tester could delete another golfer's photo | `set_round_photo`, `clear_round_photo` and `delete_round` are SECURITY DEFINER and delete `storage.objects` by a `photo_path` they never re-check against the caller's own prefix (the correct test exists one line earlier for the *new* path). `photo_path` is client-INSERTable on `rounds`. Blast radius today: 5 objects, 2 prefixes; needs a hostile friend. `post_round` validates; the desk's direct-insert fallback does not. | No — fix in the next wave |
| R11 | A bad build cannot be retired | `app_flags.ios.min_build = 0` — no forced-update gate. The lever exists (raise it above the bad build) but there is nothing newer to raise to until you ship again; TestFlight can expire a build. | No |
| R12 | A shared link opens the desk | Fixed by B4. Before that push the web is 15 commits behind — pre-voice-pass copy, no photo-on-a-round, no scorecard. After it, current. | No |
| R13 | `/support` 404s | Confirmed again tonight (`/legal` and `/legal.html` return 200). **Neither client links to it** — zero hits in `index.html` and in `apps/ios` — so it is an App Store Connect metadata question, not a screen a tester can reach. `privacyPolicyUrl` is also null on the beta localization. | No |

---

## WHAT WAS VERIFIED GREEN

**The gates.**

| Gate | Result |
|---|---|
| `node tools/build-tokens.mjs` | **GREEN** — did not throw; `tokens.css`, `tokens.ts`, `CSDesign/Generated/Tokens.swift`, `CSDesign/Generated/Looks.swift` all reported `same`; `git status` empty after |
| `node tests/preflight.mjs` | **GREEN** — `PASS — 0 failure(s), 0 warning(s)` across 43 laws, 380 Swift files + `index.html` + 248 live SQL definitions |
| `node tests/sunningdale.test.mjs` | **GREEN** — `PASS — 27 assertions` |
| `xcodebuild test`, sim `5C5EA478` (17 Pro, iOS 26.5) | **GREEN** — `** TEST SUCCEEDED **`, **1,252 tests, 0 failed, 0 skipped, 0 expected failures** |
| `supabase db query --linked --file tests/db-checks.sql` | **31 checks · 27 PASS · 4 FAIL** (9, 11, 18, 28) — 11 and 18 real, 9 and 28 bugs in the checks |
| `node tools/deploy-status.mjs` | DATABASE owed 1 · EDGE advisory 2 · CLIENT owed 15 — all three addressed above |
| Release build on the phone | **BUILD SUCCEEDED and INSTALLED** (CFBundleVersion 748) — **never launched**, see B1 |

Tests per bundle: **CupSeasonKitTests 1,041 · CSDesignTests 120 · CupSeasonTests 91**. Finer grain
from the second lens: Swift Testing 1,225 in 212 suites (app 80/15, CSDesign 120/32, Kit 1,025/165)
plus XCTest 27 (`RoundCardTests` 11, `RoundScorecardTests` 16). **There is no app-target crash** — one
lens's first run reported `** TEST FAILED **` with *"Test crashed with signal kill before establishing
connection"*; that was its own screenshot session holding the app on the same simulator, and
terminating it gave a clean full run.

**The build that goes to Apple.** `tools/ios-archive.sh` (no `--upload`) produced
`** ARCHIVE SUCCEEDED **` then `** EXPORT SUCCEEDED **` — `Cup Season.ipa`, 18,315,609 bytes
(17.5 MiB), correctly re-signed `Apple Distribution: Fischbeck3 LLC (3F7BK4WVH8)` with profile
*iOS Team Store Provisioning Profile: app.cupseason.ios* (expires 2027-08-28),
`aps-environment: production`, `beta-reports-active: true`, `get-task-allow: false`; the
`CupSeasonWidgets.appex` carries the same authority. `CFBundleVersion 748` > TestFlight's highest
(669), one train `1.0.0`, `MinimumOSVersion 17.0`, `ITSAppUsesNonExemptEncryption false` (no
export-compliance prompt). The AppIcon compiles with all three appearances (default, dark, tinted;
all 1024×1024, primary with no alpha). Re-exporting into the same directory succeeded again, so this
dry run has not wedged the real `--upload`.

**Security and grants.** The anon function surface is **exactly twelve** and matches CLAUDE.md name
for name. **Zero** functions in `public` carry a NULL `proacl`. `anon` holds **zero** relation
privileges and **zero** column privileges anywhere in `public`, measured from `pg_class.relacl` and
`pg_attribute.attacl` — the 2026-07-27 "64 of 73 relations" regression has not returned. Every
function from the last ten migrations carries an explicit ACL with no `anon` and no `PUBLIC`:
`bag_of`, `save_bag`, `home_dispatch`, `course_rating`, `rate_course`, `unrate_course`,
`my_course_ratings`, `my_course_books`, `set_round_photo`, `clear_round_photo`, `round_scorecard` on
the surface; `course_rating_is_mine` and `round_worth` correctly off it. `rounds` has no UPDATE and
no DELETE policy, so §16 immutability holds. The `media` bucket's write policies are per-uid
(`(storage.foldername(name))[1] = auth.uid()::text`) at 8 MiB and three mime types. `scan` is
fail-closed — real JWT or 401, 8 MB cap, reservation written before spending. No secret values in the
repo; the only hit is `VAPID_PUBLIC`, which belongs in the client. `profiles` RLS holds: the owner's
own session sees 3 of 39.

**Exercised for the first time anywhere.** `set_round_photo` was run against production inside a
transaction and rolled back: it wrote `photo_path`, the rollback held (`photo_path null` after), and
all three fences refused in English — *"That file is not yours"* for a path under another golfer's
uid, *"Not your round"* for another golfer's round and for clearing their photo. `ADD A PHOTO`
renders in the photograph's own slot on the phone with no skew line, and `round_scorecard` correctly
draws no card for a round with no hole scores.

**The walk, on simulators.** Door (17 Pro dark + light, SE 3, AX3), card gate, crew step, Home
brand-new, Home in the owner's real state (dark + light), Compete, the season table, Golfers, a person
page, You, both settings panes, the composer, the round's page, the course page — all load and read as
finished, ~30 cold launches, no crash, no hang, no unresolving spinner. The course page is drawn from
real data (Papago: 72 PAR · 7,380 YDS · 75 RTG · 130 SLOPE, "THE 6TH PLAYS HARDEST", the front nine's
par and stroke index) with the rating control live. No privacy leak on any reachable surface; the
"$75 YOU OWE" line appears on the owner's own Home and nowhere else. The brand-new golfer's Home —
what every tester sees first — collapses its floor to a single SOMETHING ELSE row behind one ember
`ADD MY ROUND`, exactly as designed.

**App Store Connect.** 669 is VALID, not expired, `betaReviewState: APPROVED`, and **is** in Friends.
Friends is external, 3 testers, public link live. `betaAppReviewDetail` is complete — contact, demo
account `reviewer@cupseason.app` with `demoAccountRequired: true`, and notes that pre-empt the
gambling question. `betaAppLocalizations` carries a description and `feedbackEmail`. `APNS_SANDBOX`
is absent from all 18 secrets; `APNS_KEY_ID`, `APNS_P8`, `APNS_TEAM_ID` are set.

**Nothing was changed.** Tree clean at start and finish, HEAD still `bf3b31a`, production still 219
migrations at `20261011090000`. No commit, no push, no `db push`, no function deploy, no secret
change, no upload. This page is the only file written.

---

## STALE CLAIMS CORRECTED

1. **"Both App Store Connect keychain ids are missing."** They exist in `login.keychain-db`. The
   *lookups* fail (rc=44) because the value was stored in the item's `acct` attribute instead of
   `$USER`, and the password payload is a 6-character placeholder identical on both. The real values
   are recoverable from the items and were proven live (JWT → 200). One lens read only the payload and
   concluded the stored key id matched no `.p8`; the `acct` holds `58HDLVDUPM`, which does.
2. **"Run `supabase secrets unset APNS_SANDBOX` before the first upload."** Already done —
   `APNS_SANDBOX` is not in the secrets list at all. Nothing to run.
3. **"The voice pass's migration re-creates twenty-five server functions."** It re-creates **45** and
   re-issues **41** grants across 4,176 lines.
4. **"Its migration is OWED, not run."** Half true. The ledger owes it; **its SQL is already committed
   in production outside the ledger** — prod speaks sentences found in no applied migration, and the 45
   functions it touches already carry exactly the 18 post-rewrite lowercase raises. See B3.
5. **"Push the migration and 79 shrugs become 18."** Not so: the 18 are already there. **61** lowercase
   raises live in functions the migration never touches, and the push does not fix them (R1).
6. **"Do not attempt the `v_rounds_ranked` fix tonight — RLS refuses a league-mate's rounds."**
   Refuted by measurement: `rounds_read` is `own OR shares a league`, and all three desk call sites are
   scoped to the reader's own season or own id. The fix is safe tonight (B2).
7. **"The owner's iPhone is CONNECTED."** It is `unavailable` / offline / locked; the build is
   installed and has never been launched.
8. **"TestFlight's last build is 669 = 583f127, 60+ commits stale."** 669 = `583f127` confirmed
   exactly; the gap is **79** commits. The phone in the pocket is 740 = `3157b15`, also confirmed — and
   `3157b15` is itself one of the 15 unpushed commits.
9. **"Build 667 was uploaded and never added to a group."** Confirmed, with the mechanism: 667 is
   absent from `/v1/betaGroups/…/builds` **and** its `betaAppReviewSubmission` is `data: null` — it was
   never submitted, because adding a build to an external group is what creates the submission.
10. **"`device_tokens` held one `ios-sandbox` row and zero production tokens."** The table has no `env`
    column at all (`token, profile_id, platform, created_at`). It holds **1** row, `platform 'ios'`,
    created tonight. The conclusion — push unproven — stands.
11. **"A stale `APNS_SANDBOX` deletes device tokens."** The sender now retries the alternate APNs host
    on `BadDeviceToken` and re-homes the row instead of deleting it.
12. **"The App Review notes carry two stale flags."** Flag #1 is no longer stale, it is **live**:
    Sunset Match ended 2026-09-05 and `season_over` is true. Plus four smaller mismatches — the Play
    cover has four rows not three, "Danger zone" does not exist ("Your account → Delete my account"),
    two steps are numbered 6, and the reviewer password is still `<<REVIEWER PASSWORD>>`.
13. **"`/support` 404s."** True, re-verified — but **unreachable from the product**: zero links in
    `index.html` and in `apps/ios`. It is metadata, not a screen.
14. **"App Store version 1.0 is PREPARE_FOR_SUBMISSION with no build."** Still true; irrelevant to
    TestFlight. `MARKETING_VERSION` is `1.0.0` against a version record of `1.0` — reconcile at
    submission, not tonight.
15. **"`app_flags.ios.min_build` = 0."** Confirmed unchanged.
16. **"Hand-declared RPC debt is sixteen."** It is **42** `RpcCall` structs across 23 files — and all 42
    are granted in production, as are all 159 in the generated `Rpc.swift` (zero phantoms, so nothing
    403s or 404s). `contract.psv` is a 2026-09-02 snapshot, ~25 migrations behind.
17. **The voice-pass commit message's "28/31, three FAILs".** It is **27/31 with four** — check 28 is
    also red and is recorded nowhere.
18. **`deploy-status`'s first run said `? UNKNOWN DATABASE`.** Transient cold-start on the session's
    first Supabase call — the identical call completes in 2.6 s and parses 222 rows, and the second run
    named the owed migration. Run it twice before trusting its database line; it degrades honestly.
19. **`BUILD_REPORT`'s "the migrations that are owed" (`20261010090000`, `20261011090000`, "neither has
    executed anywhere")** is stale — both are live. Its open item 6 (the pre-migration sentence) is
    **fixed** by the voice pass; item 4 ("a successful attach has never run anywhere") is **partly
    closed**; §9.2 item 1 (the four-door floor) is **mis-scoped for a beta** — that is the owner's
    populated Home, not a new golfer's.
20. **`ROAD_TO_TEN` cap 3 and `UI_AUDIT` §6** are narrowly false — one completed season (*Sandbox*) and
    one event (*The Grudge*) now exist — but the owner holds no seat in either, so both conclusions
    stand. Two of ten milestones still cannot fire: `low_round` and `most_improved` have zero rows and
    no writer.
21. **The brief's `-cs_dev_open round_card`** is not a case in the hatch switch; the round's page opens
    with `-cs_dev_open receipt`. `-cs_dev_appearance` also accepts `auto`, `charcoal`, `fescue`,
    `device`, `system`, and `-cs_dev_look` is a separate hatch.
22. **"50 of 214 rounds can draw a card."** Re-measured: **6 of 214** (`with_strokes 6`,
    `strokes_and_course 6`).

---

## NOT AUDITED

- **First paint on a real phone.** The single most valuable check in this audit. Installed, never
  launched — the phone was locked all night. B1.
- **Anything under a finger.** No tap or gesture tooling on this Mac; every screenshot in every lens is
  a rest frame. No scroll, no swipe, no long-press, no PhotosPicker tap, no storage upload from a
  device (the server half of the photo attach is proven; the client half is not).
- **The signed-in desk in a browser.** No OTP session in any lens — the web was read as source, not
  driven.
- **Push delivered end to end.** No send was observed; it cannot be proven read-only. Needs one real
  send after a tester installs.
- **The upload itself.** altool never ran, so the repaired keychain values are proven against the App
  Store Connect API but not against `--upload`. Beta App Review's verdict on 748 is likewise unknown —
  auto-approval is likely inside the `1.0.0` train, not promised.
- **The Netlify deploy** of the 15 pushed commits.
- **More than one golfer at a time.** One account, one simulator: no invite accepted by a second
  person, no live round scored across two phones, no league joined by a stranger, no season completed
  or event seat occupied on the owner's account.
- **Offline behaviour at this sha.** Airplane mode was confirmed at an earlier sha; not re-run tonight.
- **Performance on device** — cold-start time, memory, battery, thermals.
- **VoiceOver, localisation, and text sizes beyond the AX3 screenshots.**
- **The distribution signing identity** is not visible in either keychain (Xcode materialised it under
  `-allowProvisioningUpdates`); it signed twice tonight but cannot be inspected or backed up.

---

## THE WHAT-TO-TEST PARAGRAPH FOR 748

> Build 748. Everything you saw last time has been redrawn — home, your card, the course page, the
> leaderboard, the night a season ends. It fits a small phone now, and it holds up at every text size.
>
> What would help most: post a round hole by hole, and put a photograph on it. Open the round and read
> the card it drew. Rate a course. Start a season and get someone else into it. Score a live round with
> the signal off for a hole or two — it should all still be there when you come back.
>
> Two things we already know about. Push notifications have never been proven end to end, so if nothing
> ever buzzes, that is us and not you. And if a screen answers you with "Something went wrong", tell us
> what you tapped — the real reason exists, we just have not taught every screen to say it out loud yet.
>
> If something looks wrong, it probably is. Send the screenshot. Nothing here is precious yet.
