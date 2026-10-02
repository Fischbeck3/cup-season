# App Store package · 1.0 · drafted 2026-09-30 · FOR OWNER REVIEW

**Status (2026-10-01 evening): the 1.0 release package for the candidate on
`claude/app-store-listing-2026-09-30` (origin/main `e034915a` + the readiness
commits + the Home Scorebook, D404). The App Review notes are final (§10).**

**Original status: draft for review. Nothing in this file has been pasted into App Store
Connect, uploaded or submitted.** It is built from the release source
`origin/main` `e034915a`; cupseason.app served the same commit
(`v23 · e034915`) when this was written. Once approved, it replaces §1–§8 of
`app-store-listing.md` and the copy in `app-review-notes.md`.

Settled owner decisions this package follows:
- name Cup Season
- United States only
- free at launch
- manual release after approval
- operator Fischbeck3 LLC.

Still unresolved, and nothing here decides them:
- **The pot's legal classification and counsel approval.**
- Device testing remains incomplete. No bugs are known, but that is not
  verification.

Every capability named below was checked against the Release build of the
iPhone app. Each one is reachable by an ordinary signed-in user and is not
behind a DEBUG gate or an off flag. Evidence is in the
[audit notes](#evidence-and-audit-notes).


---

## Build status · 2026-10-01 (branch `claude/app-store-listing-2026-09-30`)

**What the readiness build changed** (D402 as amended, D403). All of it is **local and
undeployed**; the deploy order is at the foot of this section.

| Item | State in this branch | Still needed |
|---|---|---|
| Text filter (1.2 filtering, text) | Built: `20261221090000`, triggers on 19 tables. Corrected 2026-10-01: adds home course, a scan claim's partner name and course, every typed course name, and the Pro's ruling reason. Official catalogue course names pass. Both clients pass the one refusal through and keep the draft (the web's course note included) | Database deploy |
| Golfer reports | **Fixed defect**: both clients send `p_kind 'profile'`, which `report_content` refused ("nothing to report"). The branch is added and the founder is pushed. | Database deploy |
| Photo takedown, account removal | Built on the existing desk (web): `takedown_photo`, `ban_account`, `unban_account`, audit rows, a PostgREST pre-request gate for open sessions, restrictive storage policies. Corrected 2026-10-01: the taken-down **file** is moved into the private `moderation-hold` bucket by `share-cleanup`, so links sent before the takedown stop at the origin (proven on a real local stack). The gate now runs for `service_role` as well; without that grant every Edge function would have failed. Corrected again (review of 0e463792): only the taken-down object can be moved or deleted (the path is locked to writes until removal is confirmed plus 10 minutes, and worker claims never overlap), and account deletion removes held copies too (D396). Retention is up to 90 days, **confirmed by the owner on 2026-10-01**. | Database deploy, **then** the `share-cleanup` and `scan` deploys; owner rehearses once on test accounts |
| Scan consent on the server | Built: `scan` refuses (403, zero provider calls) without a stored yes. Corrected 2026-10-01: the server's no is final. Neither client writes a yes back on a refusal; they clear what they held and ask, and retry only on a yes tapped for that attempt. Corrected again: each scan is bound to the golfer who started it and dropped whole if the account changes mid-scan. Corrected a third time (review of a3115801): the consent **write** is bound too, on both clients, and the phone's scan now really rides its golfer's token (supabase-swift overwrote the header a3115801 set). Proven through the real supabase-js 2.112.4 and the real supabase-swift request path | **Database deploy first**, then the Edge redeploy; web and native builds |
| Live-stake ceiling | Built: the phone clamps at $200, and a server trigger refuses new or changed stakes above $200. Corrected 2026-10-01: `stake` and `unit` are validated each on its own, and malformed shapes are refused, never read as zero. History is untouched | Database deploy + native build |
| Money door labels | "Buy-in" before the first tee, "Pride bet" after, on both clients | Client deploys |
| Photo audience line | Both composers say who sees an attached photo, a scanned card included, beside the remove control | Client deploys |
| Privacy manifest | Contacts linked; Other Financial Info, Emails or Text Messages and Other Diagnostic Data added | Native build; App Store Connect answers entered by the owner (§7 of the listing) |
| Photo filtering before publication | **RULED 2026-10-01: not in 1.0.** The owner reviews photos golfers report; nothing is screened before publication. See Part D | Review notes must not claim automated photo filtering |
| Home Scorebook (D404) | **Included on the owner's yes** (2026-10-01): Codex's matte score panels and spaced rules between Home rounds, merged and renumbered from its branch's D401 | Web and native builds |
| Ban gate, token lifetime | **RULED 2026-10-01: fail-open, 1-hour tokens kept for 1.0.** See Part E | Nothing for 1.0 |
| Pot classification | **No counsel opinion** (D402). The cap and labels resolve nothing legally. | Owner risk, recorded |

**Deploy order (each step needs the owner's separate approval):**
1. `supabase db push`: `20261221090000`, `20261222090000`, `20261223090000`. Then run `tests/db-checks.sql`; check 60 must PASS (it now also asserts that the gate runs for `service_role`).
2. `supabase functions deploy scan` and `supabase functions deploy share-cleanup` (`--no-verify-jwt` is pinned for share-cleanup in `config.toml`).
   - `scan` reads `account_bans`, which exists only after step 1.
   - `share-cleanup` is skew-safe either way, but takedown files move only once it is deployed.
   - Confirm its every-minute schedule is still active in production.
3. `git push` → Netlify (web).
4. Archive and upload the native build. TestFlight first; App Store submission is separate.

## Part D · Photo filtering before publication: RULED, not in 1.0

**Owner, 2026-10-01:** "I should only need to review photos others report." So 1.0
ships with the text filter and with report → founder push → takedown for photos, and
nothing screens a photo before league-mates see it. Neither option below is built. The
review notes say exactly that. The residual risk: App Review may read 1.2's filter
bullet as covering photos; the answer would then be screening (option 2) in an update.
The analysis below is kept as the record of the choice.

Guideline 1.2 asks for "a method for filtering objectionable material from being
posted". The text filter covers words. **No photo is filtered before others see
it**; reported photos come down afterwards (takedown, including shared copies),
which is response, not filtering. Volume today: **7 round photos in the last 30
days, 1 profile photo in total** (production, read-only, 2026-10-01).

| Option | How it works | Friction / workload | Third party / consent | Build |
|---|---|---|---|---|
| **1 · Owner review hold** (recommended if no AI) | A new round photo, profile photo or league image is stored privately and visible only to its owner and the founder until approved on the desk. The round, its scores and its points post immediately; only the picture waits. | Photos appear when reviewed (target within 24h). One decision per new photo: about 8 a month at the volume above. The time per decision has not been measured. | None | 2–3 days: a held state, a storage policy, desk Approve/Remove, "Waiting for review" on both clients |
| **2 · Anthropic image screening** (existing provider) | `scan`-style Edge Function classifies each new social photo. A pass publishes; a fail or an outage holds it for the owner (fail closed). | No delay in the normal case | Photos go to Anthropic: guideline 5.1.2(i) requires **explicit permission** (a second consent, separate from scanning) plus a privacy update. Rough cost: ~1¢ a photo on Opus 5.5, ~¼¢ on Haiku 4.5; today, pennies a month. | 3–4 days: function, budget ledger under the $25 cap, consent on both clients |
| 3 · Apple SensitiveContentAnalysis (on device) | iOS 17's nudity check | None | None. **Not a filter:** it runs only when the golfer has turned on Sensitive Content Warning or Communication Safety, it needs a new entitlement, and it does not cover web uploads | Not recommended |
| 4 · A bundled on-device model | Core ML classifier | None | None | A new model dependency: not authorized |
| 5 · Status quo | Report → founder push → takedown within 24h | None | None | Built. Does not meet 1.2's filter bullet for photos. |

The owner's text ruling was "no AI". Options 1 and 2 are the two that actually filter
photos before publication. Option 1 keeps the no-AI posture at the cost of a delay.
Option 2 removes the delay at the cost of a consent prompt and a third party.
## Part E · The ban gate's limits, and the alternative (RULED: unchanged for 1.0)

**Owner, 2026-10-01:** keep the fail-open gate and the current 1-hour tokens for 1.0.
Shorter tokens are tested after launch; the production setting changes only on a
separate approval. Nothing below is built or changed.

**What the gate is.** `cs_internal.request_gate` runs before every PostgREST request
(`pgrst.db_pre_request` on `authenticator`). It refuses a golfer with an unlifted ban
(`account_bans`), including one whose access token was minted before the ban. Proven
live on a local stack: the removed golfer's token got 403 "This account has been
closed." from tables and RPCs, Storage refused the upload, and after restore it worked
again.

**Its limits, as built:**
1. **It fails open.**
   - Any error inside the gate lets the request through. This is deliberate (CLAUDE.md): a bug in a function that runs before every request must not take the whole API down.
   - The consequence: **a confirmed ban is not enforced on the API while the ban lookup is failing.**
   - Sign-in and token refresh are still refused by `auth.users.banned_until`, and the golfer's sessions and refresh tokens were deleted at the ban.
   - So the exposure is a token already issued (at most its lifetime, one hour by default), for as long as the lookup keeps failing.
2. **It fails closed where it cannot help it.**
   - A role without `EXECUTE` on the gate, or a dropped or renamed gate while the role setting still names it, makes **every** request fail.
   - The first case was live in b3472292 for `service_role` and is fixed now; db-check 60 asserts it.
   - The second is a rule for future migrations: reset `pgrst.db_pre_request` before touching the function.
3. **Realtime is not behind it.**
   - Realtime authorises a socket on the JWT and RLS, not through PostgREST.
   - A removed golfer's already-open socket can keep receiving what RLS lets them read until the token expires.
   - Sending still goes through PostgREST and is refused.
4. **Edge functions:** a function a golfer calls has to check `account_bans` itself, as `scan` does. `courses` and `weather` do not check it; they serve course and weather data and hold nothing of the golfer's. The webhook-driven functions (`push`, `season-email`, `share-cleanup`) are not called by golfers.

**The alternative (not built; your call):**
- **Option A, fail closed on lookup errors.** A failed lookup refuses the request instead of passing it.
  - Ban enforcement becomes unconditional on the API.
  - The cost is availability: a broken `account_bans` read, a bad migration or a lock timeout would refuse every signed-in golfer.
  - Mitigation if chosen: keep the lookup to one indexed primary-key read (it already is), and alert on gate errors.
- **Option B, keep fail-open and shorten the window.**
  - Set the project's JWT expiry to 10–15 minutes instead of an hour, so a removed golfer's leftover token dies sooner even if the lookup fails.
  - The cost: more token refreshes for everyone, and the clients already refresh on their own.
  - It also bounds the Realtime exposure in limit 3.
- **Recommendation:** B now, because it is a dashboard setting and changes no code. Consider A only if bans become frequent.
- Either way, no copy may say a removal is enforced "instantly and unconditionally": a removed golfer's open sessions stop at their next API request, within the limits above.

## iPhone UI tests · disposition of the 26 failures (updated 2026-10-01 evening)

| Tests | Count | Result tonight | Evidence |
|---|---|---|---|
| `HomeNoPhotoTests` (4), `HomePhotoStabilityTests` (5) | 9 | **PASS, rewritten** against main's Match Programme Home (PR #8). Each keeps the behaviour it protected: distinct golfer and round doors, the photo under the record, applause, the D360 story rules, and every D361 photo-loading case. Only the deliberately removed 168pt loading frame was dropped. Test files only; no app source. | 25/25 across the five related classes, then 26/26 executions with `-test-iterations 2` (commits `094bc8a9`, `9bb930ce`) |
| `AfterGolfWirePlacementTests.testDisplacedCardWithAnEmptyFeedKeepsAllThreeActions` | 1 | **PASS: a stale assertion, corrected.** `e8e9f84b` removed the compact lead on purpose; every lead is now a labelled container plus its own `home.lead.action` door, which five other tests depend on. | Same runs |
| `MatchProgrammeTests.testHomeRecordsAndPhotoFallback` | 1 | **PASS** with `CS_PROGRAMME_QA_PHOTO` supplied to the runner | Same runs |
| `CoursePrepReviewTests` (3), `CompeteGameplayReviewTests` (4 of 5), `AcceptedRoundReviewTests` (2), `ComposerWorthUITests` (3), `CompeteBoldReviewTests` (2) | 15 | **BLOCKED.** They need a simulator signed in to a seeded backend. DEBUG builds already default to a local stack (`CSConfig.auditBackend`), so production is not needed. But the disposable stack sends 6-digit codes, the app accepts only 8 (as production does), and the auto-mode classifier refused the one-line local config change (`otp_length = 8`). Awaiting the owner's OK for that local edit. | No run; nothing seeded |

- `CompeteGameplayReviewTests.testRulesAndHeadToHeadDoors` makes no assertions, so it passes signed out and is not counted among the 15.
- `ReceiptMomentTests` and `ReceiptLensesUITests` open with `-cs_dev_open receipt` and need the same signed-in backend.
- **Gap left for the native lane (not a regression):** `home.md` §7 asks for the Home lead to be one VoiceOver element. On main its parts are separate stops inside the labelled container, as they have been since `bf434ae6` (2026-09-06). Fixing it means deciding how the after-golf door stays separately tappable.
- Matching failures on main never stood in for signed-in behaviour. The 15 stay BLOCKED until they run.

## Live local proof · how it was run (2026-10-01)

The SQL suite (`tests/db/app-store-readiness.sql`) runs on a bare Postgres sandbox with stubbed Storage, and the worker tests mock Storage. Neither proves HTTP behaviour.

`tests/storage/takedown-live.mjs` does, against a real **local** Supabase stack (Storage with image transformation, PostgREST, Auth, the Edge runtime). It refuses to run against any host other than localhost.

To reproduce:
1. Start a stack from a scratch workdir **under your home folder**. Colima mounts only `$HOME`, so the Edge runtime cannot see functions anywhere else.
   - Set a distinct `project_id`, shifted ports and `[storage.image_transformation] enabled = true`.
   - Leave the scratch `migrations` folder empty.
2. Run `supabase start`, then prepare the database:
   - Revoke `supabase_admin`'s default `anon` grants in `public`. The local image ships them; the D37 seal migration refuses to apply over them.
   - Apply every migration in order as `postgres`.
   - Apply `tests/sim/sandbox/post.sql` as `supabase_admin` (the signup trigger).
3. Run `supabase functions serve --env-file <file with SHARE_CLEANUP_SECRET>`.
4. Run the test with `CS_LOCAL_URL`, `CS_LOCAL_ANON`, `CS_LOCAL_SERVICE`, `CS_LOCAL_DB_URL` and `CS_CLEANUP_SECRET` set from `supabase status`.

**Proven there:**
- URLs minted before a takedown serve before it and fail once the real `share-cleanup` has run, all six of them: original signed, transformed signed, the owner's own signed avatar, its transform, the public share copy, and its public transform.
- **A signed URL kept working between the takedown and the worker's run (measured: HTTP 200).** That is b3472292's behaviour for the file's whole life, since it never moved the file. Now the window is bounded by the worker's next run.
- The evidence sits in `moderation-hold`, readable by the service role and signable by no golfer.
- The ban gate behaves as described in Part E.
- `scan` refuses a revoked consent with no reservation written. As a positive control, a fresh yes passes the consent check.
- Only the taken-down object (review of 0e463792):
  - A replacement upload at a taken-down path is refused, as an insert or an upsert, until removal is confirmed and the 10-minute grace has run.
  - After that the replacement is accepted, readable by a league-mate, and untouched by later sweeps.
  - A move that landed without its report: the retry touches nothing and the evidence is kept.
  - Two concurrent sweeps move each file exactly once.
  - A failed move, because the destination already exists, still removes the published original.
- Account deletion after quarantine, while pending and while a move is in flight:
  - The held copy is gone, and the account's cleanup completes only after the in-flight move reports.
  - No evidence is kept for an account deleted while its takedown was pending.
  - Another golfer's evidence is untouched.

- The consent write's binding (review of a3115801), with `tests/storage/consent-live.mjs` and the real supabase-js 2.112.4:
  - A request bound with `setHeader` lands on the token's golfer, whoever the client is signed in as; unbound, the client's session at send time decides (the race's root).
  - index.html's own consent functions on that real client: B signing in while A's yes resolves its token writes nothing for B, and a switch after A's token is resolved still lands it on A only. On `a3115801` the first case wrote A's yes onto B.
- Tonight's candidate run (2026-10-01 evening): takedown 8/8, consent 3/3, db-checks 60/60 (check 60 included; pg_cron exists on the local image).

**Not provable locally:** CDN behaviour.
- The local stack has no CDN.
- Production may serve an already-cached response for a URL until the CDN invalidates it. Supabase's Smart CDN invalidates a deleted or moved object within about a minute, per Supabase's Storage CDN documentation. Without it, the bound is the object's `cache-control` max-age, one hour by default.
- Check which applies to the project in the dashboard.
- Copies a viewer already downloaded or screenshotted cannot be recalled by anyone.

---

## Part A · Publishable copy

### 1. App name · 10/30

```
Cup Season
```

### 2. Subtitle

**Recommended · 29/30**

```
Golf where every round counts
```

This joins the golfer's promise from the vision doc ("Every round counts") to
the brand promise ("Where amateur golf counts"). It puts *golf* in an indexed
field, which the name does not, and it speaks to the golfer rather than to
whoever administers the season.

Alternatives:
- `Golf with your friends` · 22/30. This is the IOS-035 line. It is plain and
  warm, but it is the generic phrase other golf apps also use.
- `Where amateur golf counts` · 25/30. This is the Level 0 brand promise,
  verbatim. It has the most character and is the least concrete in the two
  seconds a subtitle gets.

### 3. Promotional text · 150/170

You can change this at any time without review.

```
The rounds you already play, made into a season: standings with your friends, rivalries that keep score, a Cup at the end, and a record worth keeping.
```

### 4. Description · 2,366/4,000

Plain text: Apple renders no HTML or markdown, so the capitals are the
headings.

```
Cup Season turns the rounds you already play into a season with your friends.

Post a score from any course and it counts: on the table, against the friends you always play, and toward a Cup at the end. Months later it's all still there: the round, the rivalry, the year you finally won.

START A SEASON, OR JOIN ONE
Whoever runs the group is the Pro. The Pro sets the season up once: who's in, how many weeks, how many rounds count each month, and how it ends, with a four-week Cup Final or on the points table. Play it solo or in squads. Everyone else joins with a code or a link.

POST THE ROUND YOU PLAYED
Pick the course and tees, then type your score: the total, the front and back nines, or hole by hole. Have a paper scorecard? Take a photo and, if you agree, the app reads the scores for you. Your number builds itself from the rounds you post, and every round tells you plainly how it went: beat your number, played to it, or a little loose. It's Cup Season's own number, not an official handicap.

FOLLOW THE COMPETITION
The table moves as rounds come in. Tap a golfer to see the rounds behind their points, so every point has a receipt. In bigger seasons, the Book lays out every week. See where you stand among your buddies, and every meeting between you and any one of them.

SCORE IT LIVE
Match play, Wolf, Skins, Sunningdale, or just the score, hole by hole, on one phone or the whole group's. Guests don't need an account. If the signal drops, the scores stay on the phone. Keep score from the Lock Screen, then finish and share the card.

KEEP THE MEMORIES
Trophies stay in the case. Round photos go into the season's album. Every season ends with a final table and a moment for the champion, and it's all there when you come back. Share a round, a rivalry or the season's result with anyone. When it's over, the Pro can run it back.

BETWEEN ROUNDS
The board is where the group talks. Put Saturday's tee time on the schedule, with the forecast, and see who's in. Home Screen widgets show the race, your next tee time and what's on. You can report a post or block a golfer at any time.

THE POT
Some groups play for a pot, and some play for bragging rights. Cup Season keeps the ledger; the money moves between friends. Nothing is paid through the app.

FREE
Cup Season is free. There are no in-app purchases and no ads.

Where amateur golf counts.
```

**THE POT paragraph is publishable only after counsel.** It is in Part B
(B-1) for that reason. The rest of the description stands without it.

**Left out on purpose:**
- **The Ryder and A Major.** A Release user can reach the event picker only
  from a seasonal Home card, so a reviewer may never find it. Copy that names
  a feature the reader cannot find is a 2.1 and 2.3.1 risk.
- **Drafts.** Captains do not draft; squads fill by random draw or are
  placed by the Pro (TM-22).
- **Sign in with Apple.** It is flagged off.
- **Nearby phones.**
- **Pride bets.** A pride bet is a forfeit agreed in words. The in-app door to
  it reads "Put money on it" (see B-2).

### 5. Keywords · 96/100 bytes

```
handicap,skins,wolf,match,play,scorecard,league,standings,buddies,friends,rivalry,score,tee,live
```

The field has no spaces, no words from the name (cup, season) and no words
from the recommended subtitle (golf, where, every, round, counts). Every term
is longer than two characters. It contains no trademark (`ryder` was dropped),
no competitor and no category name.

It also leaves out `fantasy` and `draft`, which would bring in fantasy-golf
and draft searchers for mechanics the app does not run. It contains none of
the banned money or sportsbook vocabulary.

If you choose the `Golf with your friends` subtitle, swap `friends` for
`trip` (the same 96 bytes).

### 6. Categories

| | Recommendation |
|---|---|
| **Primary** | **Sports.** Apple's definition explicitly includes amateur and recreational sports and score trackers. |
| **Secondary** | **Lifestyle.** This keeps the earlier listing's choice. Social Networking describes the board accurately, but it adds a category signal that invites more 1.2 scrutiny while automated screening is unbuilt (B-4). Revisit once screening ships. |

### 7. URLs

All three return 200 on cupseason.app as of 2026-09-30. The live legal page is
byte-identical to the repo's `legal.html`. The support page differs from the
repo copy only in link style: Netlify serves pretty URLs (`/legal` rather
than `/legal.html`).

| Field | Value |
|---|---|
| Support URL (required) | `https://cupseason.app/support` |
| Marketing URL (optional) | `https://cupseason.app` |
| Privacy Policy URL (required) | `https://cupseason.app/legal.html#privacy` |

The support page names the operator and carries a working contact address,
`jerecho@fischbeck3.com`. It has no postal address or phone number. Apple's
help text ties the contact information it expects to local law. For a US-only
launch, email is the conventional minimum, but counsel should confirm (B-7).

### 8. Copyright · 19 characters

```
2026 Fischbeck3 LLC
```

Apple adds the © itself, so the field takes the year and the owner only.
`legal.html` and `support.html` already name Fischbeck3 LLC as operator. The
listing's old "no legal entity is named anywhere in the repo" flag was stale
and has been corrected in `app-store-listing.md` §5.

**Confirmed by the owner on 2026-10-01:** Fischbeck3 LLC holds the app's
rights (the code, name and artwork), and the App Store Connect seller is the
LLC, not an individual. This field is ready to paste.

### 9. Screenshots · iPhone 6.9", 8 frames

The app is iPhone-only (`TARGETED_DEVICE_FAMILY: "1"`), so no iPad set is
needed. A 6.9" set is enough: 1320 × 2868 is an accepted size, and smaller
classes scale down from it. Apple takes 1–10 PNG or JPEG frames with no
alpha.

Keep the headline + caption layout you approved on 2026-09-25. The table
below is the shooting order with captions written to the **current** screens.
The eight images now in the App Store Connect draft are the September 25 set.
About 300 native UI commits have landed since, including Match Programme Home
and Compete, Club Spread league identity and the Fescue default, so the set
must be recaptured from the final candidate (B-3).

| # | Screen (current Release label) | Headline | Caption |
|---|---|---|---|
| 1 | Season page: "The squads" + "Every golfer" | A SEASON WITH YOUR FRIENDS | Every round you post moves the table. |
| 2 | Play → "Add my round" composer, course and tees chosen | POST THE ROUND YOU PLAYED | Course, tees and score, or hole by hole. |
| 3 | Golfer → head to head: "Rivals", "Every meeting" | THE RIVALRY KEEPS SCORE | Every meeting between you and one friend. |
| 4 | Live round, hole view, four golfers | SCORE IT LIVE | Match play, Wolf or Skins, hole by hole. |
| 5 | Round receipt from a table row | EVERY POINT HAS A RECEIPT | Open a round to see what it was worth. |
| 6 | "Open the Book", Weeks view (10 or more golfers, or squads) | THE SEASON, WEEK BY WEEK | Follow every week in the Book. |
| 7 | Season ceremony, "See how it ended" | IT ENDS WITH A CHAMPION | The final table, kept for good. |
| 8 | You → "The record" with "Trophies" | A RECORD WORTH KEEPING | Your rounds, seasons and trophies in one place. |

Optional ninth frame: the What's On and The Race widgets on a Home Screen,
captioned "BETWEEN ROUNDS · What's on, at a glance."

Frames 1–3 show in search results, which is why they carry the season, the
round and the rivalry. Statistics come later, consistent with memory over
statistics.

Capture rules:
- Use only the synthetic fictional cast (X37). No "QA" prefixes, no real
  golfer, no owner name.
- Use fictional courses, so a rating on screen is not read as a claim about a
  real course.
- No price, no dollar figure as the hero, and no ledger screen. Money never
  leads (brand canon §7).
- No other platform's chrome, per 2.3.10.

### 10. App Review notes · final text (3,949 of 4,000 bytes)

Paste-ready copy: [`app-review-notes-1.0.txt`](app-review-notes-1.0.txt) (ASCII, 3,949
bytes by `wc -c`). Every label was checked against the code at `f4b60223`, and every
figure was read from production, read-only, at 18:15–18:39 MST on 2026-10-01
(`reviewer@cupseason.app`, Ridgeline Cup). The password goes **only** in App Store
Connect's sign-in fields, never in this repo or a handoff.

Corrections against the outline this replaces:
- The password field appears after tapping "Send code", not on typing. Nothing is emailed.
- "Go head to head" is a "Start something" option. The golfer page carries a "You and <name>" record.
- Deletion is You → Card & settings → Settings → "Your account" → "Delete my account" → "Delete permanently".
- Reports cover posts, comments and golfers. Golfer reasons include "An inappropriate photo".
- The safety section follows the 2026-10-01 rulings: photos are not screened before they appear, and a removed account's earlier token lapses within an hour (fail-open).

The figures go stale at the November 1 month close and when Ridgeline flips to its Cup
Final on November 22. The notes quote only individual figures, which the close does not
move.

```
SIGN-IN
Sign in as reviewer@cupseason.app (App Review Information). Enter it and tap "Send code": nothing is emailed; a Password field appears ("Review access: enter the password from the notes"). The password is in the Sign-in fields, not here. Every other golfer signs in with an emailed 8-digit code. There is no third-party or social login, so 4.8 does not apply.

WHAT THE ACCOUNT HOLDS
Four seeded leagues of fictional golfers; the reviewer is a player in each, never the organiser ("the Pro"). Please use Ridgeline Cup: active, July 5 to December 19, 2026; 8 golfers in two squads (Mudsharks, Sandbaggers); $75 buy-in.

WALKTHROUGH
1. Compete > Ridgeline Cup (YOUR SEASONS): "The squads", then "Every golfer". Tap a golfer (Tara Nguyen leads: 17 rounds, 112 points) for the rounds behind the points, then a round for its receipt. "Open the Book" shows the season week by week.
2. Same league, scroll to "The pot" > "Who has paid": $600 pot ($75 each), 5 of 8 paid.
3. Play (centre tab) > "Add a round you played" > "Add my round". Posting is fine.
4. Play > "Score it live", pick a format, "Tee off", "Finish the round".
5. Golfers > Marcus Reyes > the ... menu: "Block Marcus", "Report".
6. You > Card & settings > Settings > "Your account" > "Delete my account" (please do not confirm).

THE POT
Some leagues keep a pot; others play for bragging rights ($0). Cup Season keeps the ledger; the money moves between friends. The organiser records each golfer's buy-in (up to $200) and who has paid. A live game can record an optional amount per point or skin (up to $200) and its card shows totals. Cup Season and Fischbeck3 LLC do not collect, hold, transfer or pay out money, take no fee, and sell nothing in the app.

SAFETY (1.2)
- Filter: names, posts, comments, plans, league and course names and pride-bet words are checked by our own database for slurs, explicit sexual terms and threats before they save; refused text stays in the draft.
- Report: posts, comments and golfers, each with a reason (golfer reasons include "An inappropriate photo"). Block hides their posts and comments and stops their requests, invites and notifications.
- Reports reach the operator, who reviews within 24 hours and can take down posts, comments and photos and remove accounts. A removed account cannot sign in or refresh; our server refuses its requests, and in any case a token issued earlier lapses within an hour.
- Photos are not screened before they appear. The board is seen only by a league's golfers; a round photo, by golfers in the same seasons and accepted buddies. A reported photo is reviewed by the operator and leaves storage within minutes of takedown; a private copy is kept up to 90 days as the record, and deleting the account removes it sooner. Public links exist only when a golfer taps Share.

ACCOUNT DELETION (5.1.1(v))
You > Card & settings > Settings > "Your account" > "Delete my account" > "Delete permanently". The confirm text lists what goes: name, email, profile, posts, comments, shared links; photos are queued for removal; the login closes for good. Posted rounds stay as "Former member" so standings hold. Please do not confirm; we will give a throwaway account on request.

AI (5.1.2)
Only the optional scorecard scan. "Scan the scorecard" first asks "Scan with Claude?"; only after a yes saved to the golfer's account does our server send the photo to Anthropic's Claude to read the scores (not used for training). Off in Settings: "Scorecard scanning with Claude". The scanned card also becomes the round's photo, seen by golfers in their seasons and buddies; it can be removed before posting.

OTHER
Contacts only on "Check my contacts": SHA-256 hashes of emails and phone numbers are compared on our server and not stored. Push is opt-in. The "Who's on this tee" switch (Score it live) is off by default; turning it on shows the Local Network prompt. No purchases, ads or tracking; Settings shows "PLAN FREE".
```

---

## Part B · Needs live verification, final-build evidence or legal approval

Nothing in this part is safe to paste or answer from the repository alone.

| # | Item | Owner of the answer | Why it blocks |
|---|---|---|---|
| **B-1** | **The pot: legal classification and the exact words in the description, review notes and age rating.** **RULED 2026-10-01 (D402, option B): no counsel opinion is required before submission.** The age rating answers Gambling: No. THE POT paragraph is publishable once B-2's two fixes ship. The text that follows in this row is the counsel brief, kept in case the owner consults later. | Counsel, then owner | Counsel has not approved. Send counsel the real features, not the paragraph alone: season buy-ins up to $200 with winner, runner-up and Points King splits; live-game amounts per point or skin (uncapped on iPhone); settlement totals; pride bets; no age gate; US-only. Whether 5.3/5.3.4 applies turns on the functionality. The age-rating Gambling answer (B-8) follows the same ruling. |
| **B-2** | **Money surfaces found in the release build.** **D402: both fixes are required before submission and wait for "build it".** First, cap the phone's stake at $200 (a server clamp is recommended). Second, rename the money door on both clients; proposed: "Play for something". | Owner, with counsel | (a) On the web, the live-game stake is capped at $200 (`index.html:6974`, `CS_STAKE_MAX`). The iPhone field is a free decimal with no ceiling (`LiveSetupView.swift:428-430`, `LiveRoundStore.swift:567`), and no server clamp exists. D192's cap therefore holds on the web only. The old §6 and the review notes claim otherwise. (b) The start sheet's modifier row reads **"Put money on it"** (`StartIntent.swift:75`) and opens "Post a pride bet". The listing must not repeat either phrase; whether the in-app copy changes is your call. No code is changed by this package. |
| **B-3** | **Screenshots recaptured from the final candidate.** Pipeline built 2026-10-01: §9's frames from the app's own fictional fixtures, on a 6.9" simulator, composed in the September 25 layout. | Engineering, then owner approval | The current App Store Connect set (8 images, `APP_IPHONE_67`) predates about 300 native UI commits. **Owner, 2026-10-01: wait for the final candidate.** Capture §9's order from that build, not from `e034915a`, so the set is not shot twice. |
| ~~B-4~~ | **1.2's "method for filtering objectionable material". RULED 2026-10-01:** the D403 text filter ships; photos are reviewed when golfers report them, not screened first. The review notes say so. The text that follows is the original finding. | Owner | There is no automated screening before publication. The only server-side sanitising strips control characters. Takedown covers posts and comments; no function takes down a photo, and there is no ban function apart from self-deletion. The Terms promise to "remove the accounts that posted it". Report, block and operator notification exist. The review notes' safety section depends on whether screening ships in this build. |
| **B-5** | **Privacy manifest corrections. They ride the final candidate build, and they do NOT block submission.** Corrected 2026-10-01: Apple enforces the manifest's required-reason API section at upload. The collected-data section feeds Xcode's privacy report, which developers "refer to" when filling App Store Connect privacy details. What must be accurate at submission is the App Store Connect answers (C-1), and those can be changed without a build. | Owner, then engineering | The manifest says Contacts is not linked, but the stored buddy list is a linked social graph. Its comment, and `app-review-notes.md`, call the contact hashes "salted"; the device sends plain SHA-256 (`ContactHash.swift:61-65`). Other Diagnostic Data, Emails or Text Messages, and Other Financial Info are undeclared if you accept the C-section recommendations. A scanned scorecard becomes the round photo (`PostRoundModel.swift:404`), which the scan consent does not say. |
| ~~B-6~~ | **Copyright holder. CLOSED 2026-10-01.** | Owner | The owner confirmed that Fischbeck3 LLC holds the rights and that the App Store Connect seller is the LLC, which meets 5.1.1(ix)'s legal-entity expectation. `2026 Fischbeck3 LLC` stands. |
| **B-7** | **Support page contact sufficiency, and an inbox that works.** | Counsel / owner | Apple ties the required contact information to local law. Confirm that email alone is acceptable, and that `jerecho@fischbeck3.com` receives mail. The App Review contact also needs a phone number in `+1` format. |
| **B-8** | **The age-rating questionnaire, answered live** (Part C). | Owner; counsel for Gambling | All answers in App Store Connect are blank. The computed rating is **not known** until the form is filled. Do not assume 13+. |
| **B-9** | **The App Privacy questionnaire, answered live** (Part C). | Owner | App Store Connect has no API read of the privacy answers, so the current state there is unknown. |
| **B-10** | **App Store Connect settings that disagree with your decisions.** Re-read 2026-10-01 18:29 MST (GET only): unchanged. Version 1.0 PREPARE_FOR_SUBMISSION, release type AFTER_APPROVAL, availability 404, price rows 404 (a $0.00 USD price point exists, Free not confirmed), every localization field empty, subtitle/privacy URL/categories null, all 24 age-rating answers null, no App Review detail, no build, screenshots APP_IPHONE_67 × 8 (September 25). | Owner, in App Store Connect | The 2026-09-30 read-only read showed release type **AFTER_APPROVAL**; it must become **Manually release this version**. App availability is **not set up**; it must be United States only, with "future countries" unchecked. The price schedule exists with base territory USA, but the free tier could not be read back. Subtitle, categories, privacy URL, copyright, description, keywords, promotional text, support and marketing URLs are all empty. No build is attached. No App Review detail exists, so there is no contact, sign-in or notes. In-app purchases: 0. |
| **B-11** | **The reviewer path on the final build.** Verified read-only 2026-10-01: the account exists, its email is confirmed, it is not banned, a password is set, it is a player (never the Pro) in four seed leagues, and every member is a seed account. The path is in Release code (`DoorView.swift`, `AuthRules.swift:39`, web door). | Owner on the phone | Confirm that the `reviewer@cupseason.app` password sign-in works in the Release build, then fill App Store Connect's sign-in fields. Re-read the Ridgeline Cup figures in the app. **Do not reseed.** `test-seed`'s reset removes every seed-domain league, not only the reviewer's, and Ridgeline is already valid through December 19. |
| **B-12** | **Build provenance and push entitlement.** | Engineering | The source of the attached build must map to a committed SHA. `aps-environment` reads `development` in `project.yml`, so confirm that the App Store export carries `production`. |
| **B-13** | **Deletion's asynchronous photo cleanup is deployed.** Read-only 2026-10-01: `cs-share-cleanup` runs every minute and is healthy (60 of 60 runs, HTTP 200), but on the OLD code until `share-cleanup` is redeployed. | Engineering (read-only check) | `share-cleanup`, its secret and its schedule or webhook are deploy steps that are not visible in the repo. The confirm text's "queued for removal" is accurate only if they run. |
| **B-14** | **Reviewer account hygiene.** Found read-only 2026-10-01 (counts only; nothing about real golfers was read). | Owner, on the desk or as the reviewer | One accepted buddy of the reviewer is a NON-seed account and shows on its Golfers tab: confirm it is yours or remove the friendship. One unresolved test report filed by the reviewer (2026-09-03, a post) sits in the founder queue. The reviewer profile is discoverable by everyone. A finished Ryder event, "The Grudge", shows under FINISHED in Compete; the notes do not mention it, which is harmless. |

---

## Part C · Audits

### C-1 · App Privacy answers against actual behavior

> **Owner, 2026-10-01: agreed with the recommended changes.**
> - Contacts → Linked.
> - Declare Emails or Text Messages and Other Diagnostic Data.
> - Correct the "salted" comment in the manifest.
> - Other Financial Info is read as **declare** (the recommended lean), pending the owner's yes.
>
> The App Store Connect answers can be entered from this table now. The
> manifest edits ride the final candidate build (B-5).

Read from the code and migrations at `e034915a`. Nothing is tracked
(`NSPrivacyTracking=false`), and there is no AdSupport, no ATT and no
third-party analytics SDK; the only dependency is `supabase-swift`. Every
collected type below is **linked to the user** and **not used for tracking**.

| Apple type | Recommended answer | Purpose | In manifest? | In old §7? | Basis |
|---|---|---|---|---|---|
| Name | Collect | App Functionality | yes | yes | `profiles.display_name`; guest names on live rounds and scans |
| Email Address | Collect | App Functionality | yes | yes | sign-in, Brevo codes, season emails |
| User ID | **Collect** | App Functionality | yes | **missing** | the @handle (public, searchable), the account UUID, `handle_history`, optional GHIN # |
| Device ID | Collect | App Functionality | yes | yes | APNs token in `device_tokens` |
| Photos or Videos | Collect | App Functionality | yes | yes | round photos, avatar, league images, scans sent to Anthropic, public share copies on tap |
| Other User Content | Collect | App Functionality | yes | yes | rounds, hole scores, posts, comments, card fields, plans, side-bet terms |
| Customer Support | **Collect** | App Functionality | yes | **missing** | "Tell us how it's going" → `pilot_feedback`, with device and build |
| Crash Data | Collect | App Functionality | yes | yes (mislabelled "crash **and hang**") | MetricKit crashes → `client_events` |
| Performance Data | **Collect** | App Functionality | yes | **missing** | MetricKit hangs, composer timing |
| Product Interaction | Collect | Analytics | yes | yes | `client_events`, `growth_events` (the old §7 named a migration as if it were a table) |
| Contacts | Collect, **Linked = Yes** (recommended) | App Functionality | yes, but **Not linked** | yes, Not linked | Hashes are sent and not stored, but the buddy list (`friendships`) is a stored, linked social graph, and Apple's Contacts type includes "social graph". |
| Emails or Text Messages | **Declare** (recommended) | App Functionality | no | no | Apple puts in-app messages between users here; that is the league board chat and comments. |
| Other Diagnostic Data | **Declare** (recommended) | App Functionality | no | no | device type, OS, build and error text on diagnostic rows |
| Other Financial Info | **Owner decision** (lean declare) | App Functionality | no | "not collected" | Apple's definition includes debts. The ledger stores buy-ins, who has paid, payouts, live-game amounts and settlement totals. No payment instrument exists. |
| Gameplay Content | Optional | App Functionality | no | no | Standings and live games can sit under Other User Content; declaring both is harmless. |
| Coarse / Precise Location | Not collected | | | | No CoreLocation, and photo EXIF is stripped. The typed city is user content. Weather uses the course's coordinates on the server. |
| Health, Fitness, Payment, Purchases, Browsing, Search, Sensitive, Audio, Advertising Data | Not collected | | | | none in code |

Copy that must stay consistent with the label: `legal.html` §Privacy already
names Anthropic, Supabase, Brevo, Netlify, GolfCourseAPI, Open-Meteo, Apple,
Google Fonts and esm.sh.

Its retention sentence ("While your account exists") is broader than what
the tombstone actually keeps. Telemetry, feedback, `handle_history` and
filed reports stay linked to the retired account ID. That is a legal-copy
reconciliation for counsel; this package does not change it.

### C-2 · Age rating (current questionnaire; Apple computes the result)

The answers below are recommendations from observed behavior, with the
rating floor each one triggers according to Apple's published definitions.
**The final rating is whatever App Store Connect computes from the submitted
answers.** With Gambling: No (D402) and the other recommended answers, the highest
floor triggered is **13+** (Contests: Frequent, Social Media, Simulated
Gambling or Alcohol at Infrequent). Read the rating Apple shows back after
the form is filled; do not assume it.

| Question | Recommended answer | Floor | Status | Basis |
|---|---|---|---|---|
| Parental Controls | No | — | Recommended | none exist |
| Age Assurance | No | — | Recommended | No DOB, no attestation, no stored terms acceptance. The gate is ruled for after submission (D197 r3 / D379). |
| Unrestricted Web Access | No | — | Recommended | no in-app browser; fixed links (legal, support, `/get`) open in Safari; user text is never linked |
| User-Generated Content | Yes | 4+ | Recommended | posts, comments, photos, league names |
| Messaging and Chat | Yes | 4+ | Recommended | league board, comments, round threads (no 1:1 DMs) |
| Social Media | **Owner decision** (lean Yes) | 13+ | **Unresolved** | A Home feed of buddies' rounds with applause, comments and shares fits Apple's definition, even inside private circles. |
| Social Media Disabled for Under-13s | No | — | Recommended | there is no age signal to disable it on |
| Advertising | No | — | Recommended | none |
| Contests | **Frequent** (owner confirms) | 13+ | Recommended | The product is a standings competition with a champion. Apple's own example list includes sport contests. |
| Gambling | **No** (owner, D402) | — | **Ruled 2026-10-01** | Real-money amounts are recorded between friends (buy-ins, live-game amounts, settlement), with no payment rail. Apple's definition is betting with real money. This follows B-1. |
| Simulated Gambling | **Counsel / owner** | 13+ if Infrequent | **Unresolved** | Pride bets are wagers with no money. Ask counsel alongside Gambling. |
| Alcohol, Tobacco or Drug Use or References | **Infrequent** (or change the copy) | 13+ | **Unresolved** | A selectable ball marker "The Beverage" (a beer glass), and the call-out placeholder "Loser buys the beers" (`Callout.swift:201`). |
| Profanity or Crude Humor | None | — | Recommended | none in the app's own copy; user content is covered above |
| Loot Boxes; Health or Wellness; Medical; Horror; Mature; Sexual (both); Violence (all three); Guns | None / No | — | Recommended | none present |

If seasons with a buy-in end up 18+ only (a counsel question under D379), the
Terms' minimum age rises and Apple requires the rating to be overridden to
match it.

---

## Evidence and audit notes

- **Read-only App Store Connect read, 2026-09-30.** Version 1.0
  PREPARE_FOR_SUBMISSION. All localization fields empty. Screenshots
  `APP_IPHONE_67` × 8. No build attached. No App Review detail. App info
  subtitle, privacy URL and categories null. Every age-rating answer null.
  Availability resource absent. Price schedule base territory USA. In-app
  purchases 0. Script:
  `scratchpad/asc_read.py`, GET only, never prints the demo password.
- **Read-only production read, 2026-09-30.** The reviewer profile exists
  (Sam Reviewer, @reviewer, marker set).

  | League | Status | Dates | Golfers | Buy-in | Marked paid |
  |---|---|---|---|---|---|
  | Sunset Match | complete | ended 2026-09-05 | 6 | $75 | |
  | Ridgeline Cup | active | 2026-07-05 → 2026-12-19 | 8 | $75 | $375 |
  | Fairway Society | active | → 2027-01-02 | 5 | | |
  | Winter Circuit | active | → 2027-02-13 | 9 | | |

  The reviewer is not the Pro in any of them.
- **Live web, 2026-09-30.** `/`, `/support`, `/legal.html`, `/get` and the
  AASA file all return 200, stamped `e034915`.
- **Apple sources, fetched 2026-09-30:**
  - [platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
    (promotional text 170, description 4,000, keywords 100 bytes, copyright
    format, support URL, review notes 4,000 bytes)
  - [app information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
    (name 2–30, subtitle 30, privacy policy URL required)
  - [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
  - [age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions)
  - [app privacy details](https://developer.apple.com/app-store/app-privacy-details/)
  - [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
    (updated June 8, 2026: 1.2, 2.3, 4.8, 5.1.1, 5.3)
  - [manual release](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/)
  - [availability](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store/)
  - [categories](https://developer.apple.com/app-store/categories/)
- **Feature claims in the description, each traced to Release-reachable
  code:**
  - season wizard and endgame: `WizardState.swift:22-71`
  - join by code or link: `JoinLeagueFlow.swift`, AASA
  - composer and nines: `PostRoundScreen.swift`
  - scan consent: `ScanConsent.swift`; flag `scan.enabled` seeded true
  - bands: `CSBands.swift:27-59`
  - receipts: `ReceiptSheets.swift`
  - the Book threshold: `SeasonPage.swift:302-314`
  - head to head: `HeadToHeadPage.swift`
  - live formats: `LiveModels.swift:12-80`
  - guests and multi-phone: `LiveSetupView.swift`
  - offline: `RootView.swift:368-383`
  - Live Activity: `LiveActivityHost.swift`
  - trophies: `RecordPage.swift`
  - album and ceremony: `SeasonPage.swift`, `SeasonCeremonyView.swift`
  - Run it back: `LeagueCopy.swift:609-629`
  - board: `BoardScreen.swift`
  - plans, RSVP and forecast: `ScheduledRoundSheet.swift`, `weather/index.ts`
  - widgets: `CupSeasonWidgets.swift:21-30`
  - report and block: `SafetyMenu.swift`
  - ledger sentence: `MoneyCopy.swift:28`
  - free: `MembershipCard.swift`, `pricing.visible=false`; no StoreKit
