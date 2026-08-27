# Cup Season audit — slice 01: Auth · Onboarding · Profile · Handicap · Photos/Avatars · Settings · Account deletion · Legal

Read-only audit of `/Users/fischbeck3/cup-season` on 2026-08-27 (branch `native/b1-scaffold`). Line numbers are `index.html` unless a file is named. Migration paths are relative to `supabase/migrations/`. RPC shapes are verbatim from `packages/db/contract.psv` (the pg_proc snapshot, refreshed 2026-08-26).

Scope reminder: the native app is the **phone** surface of D98 (Expo/RN, iOS first). It owns what happens on a tee box; the wizard, draft, ledger and founder desk stay on the desktop web client. Everything in this slice IS phone territory (sign-in, card, settings, photo, deletion) except the founder desk's report pane.

---

## 1. Screens & states inventory

### 1.1 The Door (signed-out) — `#onboard` / `#obDoor`  (HTML 2561–2649)

| Item | Detail |
|---|---|
| Purpose | Sign in or create an account with an email code; alternatively enter an invite code first. One door — "Create" and "Sign in" were merged because they were the same OTP (comment 15149–15152). |
| Entry points | Cold load with no session (`boot()` 17237 → `return` with door visible); `SIGNED_OUT` → `backToDoor()` 4110 / 17744; `/?exit` 17634; a failed boot. Also arrival variants: `/?join=CODE` 17560, `/?claim=TOKEN` 17582, Supabase `#error=` hash 17346–17358. |
| Visual | The "Forge" ignition animation (SVG crest 2574–2618, seared wordmark 2620) plays fully once per device (`cs_forge` localStorage, `html.ob-fast` on later visits, `?forge` replays) 2501–2509. Desktop-only "wings" (fake feed + fake leaderboard, `#obFeed`, `#obLb`) are acknowledged fiction (D84). |
| Controls | `#obEmail` "Continue with email" → reveals `#emailbox` (`#obEmailIn`, `#obEmailGo`). `#codebox` (`#obCodeIn` inputmode=numeric **maxlength=10**, `autocomplete="one-time-code"`; `#obCodeGo`). `#obStatus` (aria-live). `#obResend` (hidden until a code is sent). `#obJoin` "I have an invite code" → `#joinbox` (`#joinCode` maxlength 8, `#joinGo`). Terms/Privacy links to `/legal.html#terms|#privacy`. `#obCaption` = `v23 · __CS_VERSION__` build stamp (2714). |
| Email step (`#obEmailGo` 15109–15147) | Validates `includes('@')` only. Special-case: `reviewer@cupseason.app` flips **reviewer mode** (W3): code box becomes a password field, `signInWithPassword` (15113–15121, 15019–15034). Otherwise `requestOtpCode(email)` = `sb.auth.signInWithOtp({ email })` with NO `emailRedirectTo` (14119–14124). On success: `CS.pendingEmail=email`, code box opens, status "Sent to X. Type the sign-in code from the newest email.", toast "Code sent", 30s resend cooldown (15074–15086), 20s "check spam" hint (15087–15094). Error mapping 15133–15146: banned/deleted/403 → "This account was closed and can't sign in again. Start fresh with a different email."; 429/rate → "Too many sign-in emails for now — the mailer limits sends per hour."; else raw message. |
| Code step (`#obCodeGo` 15036–15053) | Strips non-digits; requires ≥6 (loose guard); `sb.auth.verifyOtp({ email, token, type:'email' })`. Success → status "Signed in, loading…" then **`window.location.replace(pathname)` after 400 ms** — a full reload is the deliberate handoff so boot runs from fresh state. Failure → `humanError` + "Codes expire with resends, use the newest email." |
| Auto-submit (15058–15071) | Input handler strips non-digits live; at **8 digits** it vibrates (10 ms) and clicks Verify; `otpAuto` flag + 1.5 s re-arm prevents double-fire. Reviewer mode bypasses this. |
| Resend (`#obResend` 15095–15107) | Re-calls `signInWithOtp`; "Fresh code sent … the newest email wins." |
| Invite-code path (`#joinGo` 15192–15220) | Signed-out: `league_by_code(p_code)` (anon endpoint) validates the code BEFORE the email round-trip; `null` → "No league with that code"; `undefined` (RPC missing) → proceed anyway. Stores `cs_code` (+`cs_code_name`), then opens the email box under the join box with "Enter your email — you'll join {name} the moment your sign-in code lands." Signed-in: `covenantGate(code)` (15172–15190; `join_covenant_info` shows buy-in/floor/finish when buy-in > 0) → `join_league` → `enterLeague` → `openLeagueWelcome`. |
| Door messages from URL state (`safeBoot` 17654–17731) | Pending invite: "You're invited to {name}. Enter your email and you're in." Pending claim: `claim_round_info` / `scan_claim_info` → "{guest} — {gross} at {course}, {weekday date}. Enter your email to keep it."; dead token → error status + token dropped (F3). Claim opened mid-round → `guest_live_state` → `enterGuestLive` (D85/D87; NOT this slice). |
| Hash errors (17346–17358) | `#error=…&error_code=otp_expired` → explanatory status; hash cleared via `history.replaceState`. Legacy of link-era templates; harmless now. |
| States | idle · email open · sending · code open (waiting; spam hint at 20 s) · verifying · error (`.ob-status.err`) · ok · reviewer-password · invite-armed · claim-armed · boot-stalled ("Boot stalled at [step]" 17230) · boot-failed ("Boot failed at [step]: …" 17289). |

### 1.2 The Golfer Card gate — `#obProfile`  (HTML 2650–2678; JS `showProfileGate` 12889–12951, save 12953–12995)

| Item | Detail |
|---|---|
| Purpose | First-run identity: name, @handle, optional starter index, optional GHIN, **required ball marker**. "Just a name and a marker to start — this card follows you into every league." |
| Entry | `boot()` 17243–17248: after `loadProfile()`, if `!profile || !profile.marker || !profile.handle` → `showProfileGate(); return`. So the gate is **marker + handle**, not "profile row exists" (the m001 trigger always creates the row). Also shown if the profile SELECT fails (the 2026-07-23 photo_path grant incident sent every user here). |
| Fields | `#pfName` — pre-filled from `display_name` ONLY if it is not the email-derived default (normalized compare vs email local part, 12912–12918). `#pfHandle` — auto-derived from name as you type until touched (13066–13072), live availability check via `search_golfers` debounce 360 ms (13046–13062; note: availability is inferred from a discoverability-filtered search, so a hidden/`nobody` golfer's handle reads "available" until the RPC rejects it). `#pfIdx` optional starter index. `#pfGhinToggle` → `#pfGhin` (revealed on demand; 13075–13081). `#pfMarkers` radiogroup with roving tabindex + arrow keys + 10 ms haptic (12927–12950). No default marker (`pfMarker=null`, S1-01 — "every skipper was a saguaro"). |
| Save (12953–12995) | Validation order: name required → marker required ("Pick your ball marker — it's your face here.") → handle `^[a-z0-9_]{3,20}$`. Then `set_handle(p_handle)` FIRST, then `set_profile({p_name, p_city:null, p_home:null, p_index (or null), p_marker, p_ghin (or null)})`. City/home course deliberately deferred to the You-tab editor. Then `loadProfile()`, hide gate, toast "Card saved. Welcome, {name}." Then `cs_oriented` check → `showOrientation()` or `resumeAfterProfile()`. Error → `#pfStatus = humanError(e,'Save failed.')`. |
| Claim context | If `cs_claim` is set, a gold note "Saving your card attaches the round you're claiming." is prepended (12900–12909). |
| States | fresh · name-derived-handle · handle checking / available / taken · marker unpicked error · saving · error · saved. |

### 1.3 Orientation — `#obOrient` (HTML 2691–2712; JS 13000–13007, `#orGo` 13005) — D82/D83

Shown exactly once per DEVICE (`cs_oriented` set on SHOW, not dismiss, so a crash can't trap the user). Two teachings: four places (Home / Clubhouse / ⊕ / You) and long game vs short game. One CTA "Take me in" → `resumeAfterProfile()`. Re-openable forever from You › How it works (`#youGuide` 2908–2915, `GUIDE` sheets 13011–13040). The demo CTA was retired (D83).

### 1.4 League-less Home ("welcome fork") — `showWelcome()` 17089–17110+

Not a separate screen: `body.noleague` class reshapes the SAME app shell. `CS.league=null`, `state.demo=false`, header "Cup Season", sub "No league yet, your golf still counts" / "Your leagues are a tap away…". Loads league record, trophies, career, career record. `#obWelcome` (2679–2689) exists in HTML but `showWelcome()` no longer displays it — it's dead markup.

### 1.5 The You tab — `#view-stats` (HTML 2829–2917)

| Region | Source / notes |
|---|---|
| Credential card `#youCard` | `refreshWhoChip()` 13086–13136 paints: `#youMk` = `face(uid, marker, 56)`; `#youName`; `#youMeta` = `@handle · city · home_course`; `#youAnchor` = `GHIN nnn · Member since Mon YYYY` OR `Member since … · add your GHIN` link (opens hub scrolled to `#phGhin`) 13097–13112; `#youIdx` = `fmtIdx(index_current)` OR **"n of 3"** with title "Building your number — your index appears at 3 posted rounds" (13113–13123, D3 "building, not broken"); `#youWm` marker watermark; `#youTros` top-3 trophies; `#youForm` form row. `#youProfile` ⚙ opens the hub. |
| `#pilotChip` feedback row | `submit_feedback` (other slice). |
| `#founderDesk` | display toggled only when `CS.user.id === FOUNDER_ID` (12874–12877); server-gated. Reports pane rendered at 15450–15452 ("Content reports · last 15", 🚩/✓). |
| Display case, The record, Lifetime stats, Recent rounds (`renderCareer` 11152–11197 — owner-only delete-round × with `confirm()` → `delete_round`), Your buddies door, Rivalries, This season, League record, How it works. |

### 1.6 Card & settings sheet — `openProfileHub()` 13504–13820

Opened by `#youProfile` (13823). Refuses when `!CS.profile` ("Demo golfer: sign in…"). One bottom sheet (`openSheet`) with a two-segment switch `#phSeg`: **Your card** | **Settings** (pilot audit 2026-07-17: identity vs device/account).

**Your card pane** (`#phPaneCard` 13523–13563):
- Name `#phName`, City `#phCity`, Home course `#phHome` (free text — no course picker/geo).
- Ball marker grid `#phMarkers` (`renderPhMarkers` 13138–13148, `phMarker` seeded from profile or 'saguaro').
- Photo row: `#phFace` (current face), `#phPhotoBtn` "Add a photo"/"Change photo", `#phPhotoRm` "Remove", hidden `<input type=file accept="image/*">`. Photo add/remove save **immediately**, not on Save (13612–13676): `cropSquare` → center-crop to 512×512 JPEG q0.85 via canvas (uses `photoDrawable` 6521–6541 which handles HEIC via `<img>` fallback) → `sb.storage.from('media').upload('{uid}/avatar.jpg', blob, {upsert:true})` → `set_profile({p_name, p_photo_path})` (skew message if the 7-arg fn is absent) → `createSignedUrl(path, 3600)` → `window.avatarUrl[uid]`. Remove: `set_profile({…, p_photo_path:''})` then best-effort `storage.remove`.
- Handle `#phHandle` ("moves once / 60 days"), Findable-by `#phDisc` (everyone/friends/nobody → `set_discoverable`, instant, 13763–13775).
- GHIN `#phGhin` with disclaimer "A reference on your card — we never resell or verify it."
- `#phSave` "Save card" → dirty-state arms to "Save changes" (13627–13633). Save (13678–13706): `set_profile({p_name, p_city||null, p_home||null, p_index:null, p_marker, p_ghin:''-clears})` FIRST, then `set_handle` only if changed; a handle error (cooldown/taken) is reported inline WITHOUT losing the card save ("Card saved · handle: {msg}"). Sheet stays open; inline "Card saved ✓".
- Handicap index block: `#phIdx` + `#phIdxGo` "Update index" → range check −10..54 → `set_index` (13708–13724). The "comes from your scores" refusal is shown verbatim as information, not error. Copy: "Your index builds automatically… appears once you've posted 3. Set it here to seed a starter; once you have 3 rounds your scores take over. Changes are announced on your league boards, crew-policed." + "How scoring works →" (`openScoringHelp` 17025–17045).
- Your leagues: read-only rows `{name} PRO|PLAYER · CODE`.

**Settings pane** (`#phPaneSettings` 13565–13593):
- Notifications: `#phPushTog` (web-push VAPID subscribe / native APNs via Capacitor bridge — 13975–14080), `#phRoundsTog` → `set_notify_rounds`, `#phChatTog` → `set_notify_chat`, `#phMailTog` → `set_email_recap` (read with `{}`; hides itself if the RPC errors, 13822–13838). Copy: "Moments, reveals, and month closes always come through. Round posts and chat each have their own switch."
- Appearance `#phTheme`: Charcoal (`dark`) / Light / Match device (`auto`) → `window.setTheme` (13780–13793). Device-local (`cs_theme`), NOT synced to the profile.
- Membership & billing: static "PLAN FREE · PILOT" (Stripe parked).
- `#phOut` Sign out → `sb.auth.signOut(); location.reload()` (13728–13731).
- Danger zone: `#phDelete` link → two-step inline confirm `#phDelConfirm` with the tombstone copy ("Rounds you've posted stay in the record … you'll just show as 'Former member'") → `#phDelYes` → `delete_account` → `signOut` → `location.replace(pathname)` (13738–13760). Failure keeps the user signed in and toasts the server message.
- Build identity `Cup Season · v23 · __CS_VERSION__` + Privacy · Terms · Prize pool links (`/legal.html#…`, `target=_blank`).

### 1.7 Tour Card (any golfer, incl. self) — `openTourCard(profileId)` 13293–13457

Opened from any `[data-tc]` element (delegated 13459–13462). Refuses in demo / signed-out. Loads `tour_card` + `my_friends` in parallel. `visible:false` → "This golfer keeps their card private, or you don't share a league yet." Renders face (avatar or marker), name, `@handle · city · est. Mon YYYY`, index (or —), trophies, form row, vs-you chip, buddy action, Career (rounds/best diff/avg vs index/home course/GHIN), Recent 5 rounds, **Mute/Unmute** (`set_mute`, W4, 13387–13392 + 13418–13428) and **Report photo** (only when a signed avatar URL exists and it isn't yours; two-tap arm; `report_content({p_kind:'profile_photo', p_profile, p_reason:'profile photo'})` 13320–13324, 13434–13446).

### 1.8 Members sheet — per-league marker override — `openMembersSheet()` 16891–17022

Row for self carries `#msMkMine` "Marker here" → grid of all markers + "Use my profile marker" → `set_league_marker(p_league, p_marker|null)` (16938–16955). Updates `CS.member.marker`, `me.mk`. The Pro's "Set index" (starter) → `set_member_index` via an in-app sheet (never `prompt()`, S4-03) 16997–17021.

### 1.9 Takeover pages (no app boot; `window._csShareView=true`)

- `/?unsub=TOKEN` (17370–17393): calls `email_unsubscribe` (anon) then paints a full-screen charcoal card "You're unsubscribed" / "That link has expired" + "Open Cup Season". Always answers the same regardless of token validity (D68).
- `/?share=TOKEN` (17395–17556): public card view (other slice).

### 1.10 Legal — `legal.html` (97 lines) / `legal/*.md`

Single static page with three anchors: `#privacy` (Privacy Policy, last updated July 18 2026), `#terms`, `#pot` (Prize Pool Disclaimer). Reads `cs_theme` from same-origin localStorage to match theme (legal.html 88–95). Contact `jerecho@fischbeck3.com`. Privacy names: name, email, handicap, league activity, scores, photos; third parties for auth, storage, analytics, email, "AI-assisted scorecard reading" (Anthropic) with a no-training statement; "You may request to update or delete your account at any time."

### 1.11 Boot sequence, watchdog, demo mode (module script 12783 → 17763)

- Client: `createClient(SUPABASE_URL, publishable key, { auth: { lock: pass-through } })` 12787–12793 — the pass-through lock dodges origin-wide `navigator.locks`. Session lives in localStorage (browser default).
- `bootStep` breadcrumbs ('init' → 'session' → 'profile' → 'memberships' → 'enterLeague' → ['blank-slate','bylaws','season-dates','league-data'] inside `enterLeague` → 'reveal'); exposed on `window.bootStep` via a getter (17226) so the classic-side error handlers can stamp it into `client_events`.
- `boot()` 17227–17298: **8 s watchdog** → `authStatus('Boot stalled at [step] — network or auth hang','err')` (does NOT abort). `getSession()` → no session = show door. `loadProfile()` → gate on marker+handle. `loadMemberships()`. `syncNativePush()` (not awaited). Pending `cs_code` → `join_league` → enter. `cs_intent` legacy cleanup. No memberships → `showWelcome()`. Else enter `cs_last_league` or `memberships[0]`. `finally`: clear watchdog, `bootStep='reveal'`, `restorePostDraft()`.
- `resumeAfterProfile()` 17300–17342: same tail after the card gate; also fires `claimPendingRound()` and the install nudge after a covenant.
- `safeBoot(force)` 17646–17733: idempotent via `bootResolved`; gated off when `_csShareView`. Triggered by `INITIAL_SESSION` (force=false), `SIGNED_IN` (force=true), and a 3 s fallback timer (17763). `SIGNED_OUT` clears state and `cs_code*`. All handlers defer via `setTimeout(…,0)` — **never call auth inside `onAuthStateChange`** (17740–17741).
- iOS resume (17751–17757): on `visibilitychange` after >2.5 s hidden, re-subscribe realtime and refresh board/invites (signed-in only).
- `?exit` hatch 17634–17636: `signOut()` then `location.replace(pathname)`. QA reset.
- Error surface: `#errbar` 3628 shown only with `CS_DEBUG` (`/?debug` persists in `cs_debug`; `?debug=off` clears) 3630–3640; `window.onerror` / `unhandledrejection` keep a 4-frame stack + bootStep and post `client_events` via `qaEvent` (3650–3676; `qaEvent` 6100–6110 — signed-in only, RLS).
- **Demo mode** = `state.demo` (default `true` at 3772) is the classic-side write guard: every real-data path is gated with `!state.demo`. `resetToBlank()` 11735 / `showWelcome()` 17093 / 7884 set it `false` on entering a real league or league-less home. Since D83 there is **no user path that turns demo on**; it is boot scaffolding and the "diorama" data (fabricated players, `DEMO_ME`, 'The Sunday Cup') still lives in the classic script. A missing `window.*` bridge silently drops you into demo-shaped local echo — CLAUDE.md landmine.
- Theme: pre-paint IIFE 2476–2510 reads `cs_theme` (default `'dark'`, D76), sets `data-theme`, `color-scheme`, `<meta theme-color>` (#EFF2EE light / #0C0D0F dark), listens to `prefers-color-scheme` for `auto`.

---

## 2. RPC table (this slice)

Role column: `auth` = authenticated, `anon,auth` = both. All are SECURITY DEFINER unless noted. Source of truth: `packages/db/contract.psv`.

| RPC | Args | Returns | Role | Defining migration(s) | Notes |
|---|---|---|---|---|---|
| `set_profile` | `p_name text, p_city text=null, p_home text=null, p_index numeric=null, p_marker text=null, p_ghin text=null, p_photo_path text=null` | void | auth | `20260716060000` (6-arg) → `20260716070000` (name-change announce) → `20260723150000` (7-arg, current) | INSERT … ON CONFLICT upsert keyed on `auth.uid()`; email sourced from `auth.users`. `coalesce(new, old)` for name/city/home/index/marker ⇒ **null never clears** those; `p_ghin`: null=keep, ''=clear; `p_photo_path`: null=keep, ''=clear, must match `^{uid}/`. A real name change inserts a `system` post on every league board: `"{OLD} NOW GOES BY {NEW}"`. `p_index` here bypasses `set_index`'s guard/announcement — the client always sends null on edits. |
| `set_handle` | `p_handle text` | void | auth | `20260712010000` → `20260716070000` | Normalizes (`@` stripped, lower, trim); regex `^[a-z0-9_]{3,20}$`; reserved list `pro,demo,cupseason,admin,support,help,official,cup,season,sndycup`; no-op if unchanged; **60-day cooldown** on genuine change (`handle_set_at`), message names the next date; unique_violation → "That handle is taken"; re-handle announced on boards (first claim silent). |
| `set_discoverable` | `p_mode text` | void | auth | `20260712010000` | `everyone|friends|nobody`. |
| `set_index` | `p_index numeric` | void | auth | `20260711150000` → `20260716100000` → `20260716120000` (current) | Range −10..54; **refuses if `handicap_index(uid)` is non-null** ("Your number comes from your scores now (N). A starter only helps before 3 posted rounds."); sets `index_source='self'`; announces on every league board unless unchanged. |
| `set_member_index` | `p_member uuid, p_index numeric` | void | auth | `20260716110000` → `20260716120000` | Pro-only starter for a member; same established-refusal; board post "THE PRO SET X'S STARTER INDEX TO N". |
| `handicap_index` | `p_profile uuid` | numeric | auth | `20260716100000` | `handicap_index_asof(p, null, null)`; null until 3 counted rounds. |
| `handicap_index_asof` | `p_profile uuid, p_before_date date, p_before_id uuid` | numeric | auth | `20260716100000` | WHS-lite; see §4.3. |
| `tour_card` | `p_profile uuid` | jsonb `{visible, profile{id,display_name,handle,marker,city,home_course,index_current,ghin,member_since,is_me}, career{rounds,best,avg_pvi}, trophies[], recent[≤5], vs_you{wins,losses,ties}|null}` | auth | `20260716060000` → `20260716070000` | Visibility fence: self OR accepted friend OR shared league OR shared event OR target `discoverable='everyone'`; tombstoned → `visible:false`. The B1 phone scaffold already calls this (`apps/mobile/app/home.tsx`). |
| `search_golfers` | `p_q text` | table(profile_id, handle, display_name, city, home_course, marker, index_current, rel) | auth | `20260712010000` → `20260715210000` → `20260717194623` | ≥1 char, substring on handle or name, excludes self + tombstoned, respects `discoverable`, buddies→league-mates→handle-prefix ordering, limit 10. Used for the handle availability check. |
| `my_friends` | — | table(friendship_id, profile_id, handle, display_name, city, marker, index_current, status, incoming) | auth | `20260712010000` → `20260715210000` | Used by Tour Card for the relationship. |
| `delete_account` | — | void | auth | `20260714200000` → `…210000` → `20260715210000` → `20260717205347` → **`20260718172300` (current)** | See §4.7. Raises if you run a league/event with others in it. Hard-delete when no footprint, else tombstone + `banned_until='infinity'`. |
| `set_league_marker` | `p_league uuid, p_marker text` | void | auth | `20260723150000` | Self-only; `nullif(p_marker,'')`; ≤24 chars; raises 'not your league'. |
| `report_content` | `p_post uuid=null, p_reason text=null, p_kind text='post', p_profile uuid=null` | void | auth | `20260718174500` (2-arg) → `20260723150000` (4-arg) | `profile_photo` kind requires a shared league/event/friendship; upsert on `(profile_id, reporter)`. |
| `set_mute` / `my_mutes` | `p_profile uuid, p_on boolean` / — | void / uuid[] | auth | `20260722013000` | Enforced by `posts_read` / `comments_read` RLS; rounds in `home_feed` still show (scores are facts). |
| `set_notify_rounds` / `set_notify_chat` | `p_on boolean` | void | auth | `20260716030000` / earlier push migration | Profile flags read by the `push` Edge Function (`functions/push/index.ts` 297–305). |
| `set_email_recap` | `p_on boolean=null` | boolean | auth | `20260725140000` | Read with no arg (creates `email_prefs` row), write with one. |
| `email_unsubscribe` | `p_token uuid` | boolean | **anon,auth** | `20260725140000` | Only ever flips `recap=false`; always returns true (D68, fail-closed, unenumerable). |
| `register_device_token` | `p_token text, p_platform text='ios'` | void | auth | `20260722013000` | Upsert on token PK (reassigns profile on conflict). |
| `unregister_device_token` | `p_token text` | void | auth | `20260826120000` | Scoped to caller. |
| `founder_id` | — | uuid | **anon,auth** | `20260714220000` | Client badges the founder; no PII. |
| `founder_desk` / `founder_note` | — / `p_body` | jsonb / uuid | auth (server-gated to founder) | `20260721191500` → `20260723150000` | Reports pane. Desktop surface per D98. |
| `join_league`, `league_by_code` (anon), `join_covenant_info` (anon), `claim_round`, `claim_scan_round`, `claim_round_info` (anon), `scan_claim_info` (anon), `guest_live_state` (anon) | — | — | — | — | Touched by the door/boot path; owned by other slices. |
| Triggers (not callable): `handle_new_user` (auth.users → profiles), `tag_founder` (profiles), `score_round` (rounds BEFORE INSERT), `round_refresh_index` (rounds AFTER INSERT). | | | | | |

Direct table reads the client still does in this slice (no RPC): `profiles` own row (`loadProfile` 12856–12866, named columns, NO email), `league_members` (+ embedded `profiles`), `rounds` own rows (`loadCareer` 16412–16419), `push_subscriptions` upsert/delete (web push only), Storage `media` (`createSignedUrl(s)`, `upload`, `remove`).

---

## 3. Tables / columns / triggers / RLS touched

### 3.1 `public.profiles` (baseline 1212–1226 + later ALTERs)

| Column | Origin | Notes |
|---|---|---|
| `id uuid PK → auth.users(id) ON DELETE CASCADE` | baseline 1881 | Hard delete of the auth row cascades the profile. |
| `display_name text NOT NULL` | baseline | Seeded by `handle_new_user` from `raw_user_meta_data.display_name` or the email local part. |
| `email text NOT NULL` | baseline | **Sealed**: column revoked from anon/authenticated (`20260718172300` 102; table-level SELECT revoked and an explicit column list re-granted in `20260721214500`). Client reads email from the auth session only. |
| `ghin_number text` | baseline | Optional reference; readable only via league/event-mate RLS + `tour_card`. |
| `created_at` | baseline | "Member since" tenure anchor (D-identity-legit). |
| `city`, `home_course`, `index_current numeric`, `marker text` | baseline | `marker` = onboarding gate. |
| `card_quote`, `the_miss`, `walk_ride`, `beverage` | baseline | Legacy "card" fields; NOT read or written anywhere in this slice (dead columns). |
| `handle text` + unique index `lower(handle)` + CHECK `^[a-z0-9_]{3,20}$` | `20260712010000` 11–14 | |
| `discoverable text NOT NULL default 'everyone'` CHECK in (everyone,friends,nobody) | `20260712010000` 16–17 | |
| `notify_chat boolean`, `notify_rounds boolean NOT NULL default true` | push migrations / `20260716030000` | |
| `is_founder boolean` | `20260714220000` | `tag_founder` BEFORE INSERT OR UPDATE OF email sets it for the owner's address. |
| `deleted_at timestamptz` | `20260714200000` | Tombstone marker; `tour_card`, `my_friends`, `search_golfers`, `founder_desk` filter on it. |
| `index_source text` | `20260716100000` | `'app'` (engine) / `'self'` / `'ghin'` (reserved, never set by code). |
| `handle_set_at timestamptz` | `20260716070000` | 60-day cooldown clock. |
| `photo_path text` | `20260723150000` + column grant `20260723170000` | `{uid}/avatar.jpg`. |

RLS on `profiles` (current): `profiles_self_select` (id=uid), `profiles_league_read` (shared league), `profiles_event_read` (shared event, `20260718172300` 95–100); the blanket `profiles_read USING(true)` was DROPPED (`20260718172300` 93). UPDATE policies `profiles_self_update` / `profiles_write` (own row) still exist from the baseline, but the client never issues a direct UPDATE — all writes go through definer RPCs. **Column grants are frozen** (`20260721214500` 66–81): any new profiles column needs `grant select (col) on public.profiles to authenticated` or every select naming it fails 42501 without naming the column (`tests/db-checks.sql` check 9 asserts this).

### 3.2 `auth.users`

- `handle_new_user()` (baseline 411–421, SECURITY DEFINER) inserts the profile row. **The trigger binding on `auth.users` (`on_auth_user_created`, "m001") is NOT in any migration file in the repo** — `grep` finds only the function and the CLAUDE.md mention. It exists in prod only. A fresh environment (`supabase db reset`, a branch) would sign users in with no profile row; `set_profile`'s upsert would still create one on card save, but `loadProfile` returning null before that is the expected path anyway (gate). Flagging as an environment-reproducibility landmine (§7).
- `delete_account` writes `auth.users.banned_until='infinity'` (tombstone) or `DELETE FROM auth.users` (hard). A banned user's `signInWithOtp` fails → the door maps it to "This account was closed…" (15137–15140).

### 3.3 `public.league_members.marker text` (`20260723150000`) — per-league marker override; effective marker = `league_members.marker → profiles.marker → 'saguaro'` (client 14303; `memberMarker` 10244).

### 3.4 `public.rounds` (this slice's reads): `differential`, `index_at_post`, `index_source_at_post`, `voided`, `source` ('app'|'live'|'sim'…), `photo_path`. Triggers: `score_round` BEFORE INSERT computes differential and the index snapshot (`20260716100000` 66–90); `round_refresh_index` AFTER INSERT recomputes `profiles.index_current` (`20260716120000` 78–105); `rounds_no_future` (`20260718174500`).

### 3.5 Storage bucket `media` (private) — `20260718045514` 21–30; caps `8 MB`, MIME `image/jpeg|png|webp` (`20260718174500` 52–55). Policies: `media_insert`/`media_delete` own-prefix (`(storage.foldername(name))[1] = auth.uid()`); `media_read` = `bucket_id='media' AND can_see_media(prefix)` where `can_see_media` = self OR league-mate OR accepted friend (`20260718173100` 21–46). Avatar path `{uid}/avatar.jpg`. Signed URLs 3600 s (batched per league load 14309–14322; own avatar in `loadProfile` 12867). Share page copies use a separate PUBLIC `shared` bucket (D60) — avatars never travel there.

### 3.6 `public.content_reports` (`20260718174500` 15–26, widened `20260723150000` 89–97): `post_id` nullable, `reporter`, `reason ≤500`, `resolved`, `kind` ('post'|'profile_photo'), `profile_id`; CHECK target present; partial unique `(profile_id, reporter) WHERE kind='profile_photo'`. RLS enabled with NO policies (RPC writes, `founder_desk`/service reads).

### 3.7 `public.mutes` (`20260722013000` 22–29) — no policies; `set_mute`/`my_mutes` only; enforced in `posts_read` & `comments_read`.

### 3.8 `public.device_tokens` (`20260722013000` 79–86): `token PK`, `profile_id`, `platform CHECK ('ios')`, `created_at`. No policies; service-role reads in `functions/push/index.ts` (APNs branch env-gated on `APNS_P8/KEY_ID/TEAM_ID`, topic default `app.cupseason.ios`, 410 pruning). `public.push_subscriptions` (web push) — direct client upsert/delete with RLS.

### 3.9 `public.email_prefs` (`20260725140000` 21–29): `profile_id PK`, `recap default true`, `token uuid` (unsubscribe), `updated_at`; RLS with no policies, all grants revoked — definer RPCs only. `functions/season-email/index.ts` 103 builds `/?unsub=TOKEN`.

### 3.10 `public.friendships` — deleted on tombstone (`20260715210000`); `public.client_events` — error telemetry (authenticated insert only).

---

## 4. Business rules (with citations)

### 4.1 Authentication
- **Email OTP only, code-only.** `signInWithOtp({ email })` with no `emailRedirectTo` (14119–14124). Brevo SMTP behind Supabase Auth; both "Magic Link" and "Confirm signup" templates render `{{ .Token }}` and contain no `{{ .ConfirmationURL }}` (CLAUDE.md). Rationale: Gmail's link scanner consumes single-use tokens (landmine). D98 upholds "email-OTP-only sign-in, which is what keeps Sign in with Apple optional" — **adding any third-party login obliges Sign in with Apple** (`spec/native-arc.md` 202).
- **Codes are 8 digits** (prod). The local `supabase/config.toml` says `otp_length = 6` / `otp_expiry = 3600` — that file is the LOCAL dev config, not prod; the app and `packages/db/auth.ts` (`OTP_LENGTH = 8`) encode 8. Never `maxlength=6`.
- A resend retires earlier codes ("the newest email wins").
- Rate limits: Supabase mailer per-hour cap surfaces as 429 → friendly copy.
- Verify success on web = full page reload; the native scaffold instead lets the session provider hear `SIGNED_IN` (`apps/mobile/app/index.tsx` 62–66).
- **Reviewer door (W3, kept by D98):** `reviewer@cupseason.app` + password from App Review notes → `signInWithPassword`. The account is otherwise a normal golfer.
- `?exit` = sign out + clean reload (QA hatch). `/?debug` = error bar.
- Sessions: web keeps the session in localStorage with a pass-through lock; native keeps it in Keychain (chunked ≤1536 B, `AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY`, `apps/mobile/src/secure-store.ts`) and starts/stops auto-refresh with `AppState` (`src/supabase.ts`).

### 4.2 Onboarding / the card
- The m001 trigger creates the profile row at signup with an email-derived `display_name`; therefore **"has a profile row" means nothing** — gate on `marker` (and now also `handle`) (boot 17243–17248; CLAUDE.md landmine).
- The card requires **name + @handle + marker**; index and GHIN optional; city/home course deferred (12960–12985).
- No default marker (S1-01). 14 markers in `MARKERS` (12820–12845): 8 "shape" archetypes (saguaro, island, lighthouse, lonetree, pews, dunes, beer→"The Beverage", shark) + 6 oblique famous-golf nods (azalea, jug, weebridge, no2, stamp, thistle) — "never named" is the legal safe zone. Each is an SVG path; `mkr(k)` 12846. Unknown key → saguaro (never empty).
- Handle rules: 3–20 `[a-z0-9_]`, reserved words, unique case-insensitively, first claim silent, later change once per 60 days and announced to boards (`20260716070000`).
- Name change is announced to every league board ("X NOW GOES BY Y") — accountability, not lockdown (`20260716070000` header).
- Orientation shows once per device (`cs_oriented`) — D82/D83.
- Invite (`cs_code`) and claim (`cs_claim`) intents survive the OTP round-trip in localStorage and are consumed in `boot()`/`resumeAfterProfile()`; a failed auto-join removes the code first so it can't loop.
- Founding-league / founder badge: `founder_id()` (anon) + `founderTag()` client-side.

### 4.3 Handicap engine (spec §5, amended; migrations `20260716100000/110000/120000`; D44, D49)
- Every round stores `differential = (gross − rating) × 113 / slope` (9-hole: `(gross − nine_rating) × 113 / slope × 2`), index-independent — computed by `score_round()`.
- `handicap_index_asof(profile, before_date, before_id)`: last **20** non-voided, non-`sim` rounds with a differential, ordered `(played_on, id) desc`; count `c`:
  - `c < 3` → **NULL** (not established).
  - best-N average with adjustment: c=3 → lowest 1 −2.0; c=4 → lowest 1 −1.0; c=5 → lowest 1; c=6 → lowest 2 −1.0; 7–8 → lowest 2; 9–11 → lowest 3 −1.0; 12–14 → lowest 4; 15–16 → lowest 5; 17 → 6; 18 → 7; 19–20 → 8. Rounded to 0.1. (WHS table, minus the soft/hard caps and the 96% multiplier — "WHS-lite".)
- `score_round()` index snapshot precedence: caller-supplied `index_at_post` → `profiles.index_current` → engine as-of this round → this round's own differential (first-round provisional). **NEVER a blind 18** (the bug the engine killed).
- `round_refresh_index()` AFTER INSERT: if the engine is non-null (≥3 rounds) it overwrites `index_current` and sets `index_source='app'` on every insert; announces ONLY the one-time handoff from a manual starter (`self`/`ghin` → `app`) and only if the number moved: "X'S NUMBER NOW COMES FROM THEIR SCORES — {old|STARTER} → {new}". Routine per-round updates are silent. (Deletes via `delete_round` do not re-fire this trigger — see §7.)
- **Starter ("behavior B")**: a manual index (self via `set_index`, Pro via `set_member_index`) fills the gap before 3 rounds and is REFUSED once established. Range −10..54 (client and server). Announced to boards. `set_profile.p_index` on the card gate is the silent path for a brand-new user's starter (no boards yet).
- Display: `index_current == null` → "n of 3" on the You card (n = min(career rounds, 3)) 13113–13123; the post eyebrow reads "your index builds at 3 rounds" (14243–14246); native scaffold shows "—" never 0.0 (`home.tsx` 152–155). `fmtIdx` renders plus-handicaps as `+N.N` (7181–7186).
- D49: provisional rounds score normally off the starter (flat-7 retired); D44: Majors flag un-established players as exhibition — "established" is always the engine's definition (`handicap_index()` non-null), never a parallel count.
- spec §5's table (index rise cap +1.0, exceptional-score cut, max 30.0, monthly revision, "GHIN required Standard+") is the ORIGINAL spec; the built engine implements none of the caps and revises per round, not monthly. Verified-tier GHIN is dead (CLAUDE.md monetization). Treat §5 as superseded by the migration headers + D44/D49 unless the decision log says otherwise.
- Career stats (`loadCareer` 16409–16450, `tour_card`): PvI = `index_at_post − differential` (100% allowance); "beat" = PvI ≥ 1.

### 4.4 GHIN
- Optional reference string on the card; "we never resell or verify it" (13549). `set_profile.p_ghin`: null keeps, '' clears. Never imports an index; `index_source='ghin'` is reserved but unset. Readable only by league/event-mates (RLS) and via `tour_card` (shown on the card as "GHIN nnn"). Tombstone nulls it (`20260718172300` H1b).

### 4.5 Photos & avatars (D36 → D59, `spec/photos-arc-2.md`)
- Avatar = `{uid}/avatar.jpg` in the private `media` bucket; client square-crops to 512 JPEG q0.85 before upload; upsert.
- **Fallback is ALWAYS the marker — no silhouette state exists** (`face()` 10228–10243). With a photo, the marker rides as a badge for sizes ≥32 px. Demo/diorama never fabricates faces.
- Read fence: self / league-mate / accepted friend (`can_see_media`). Friends-only surfaces (people picker rows) keep the marker floor in v1 (D59 tradeoffs).
- Per-league marker override lives on `league_members.marker` (self-set).
- Round photos carry the poster's marker medallion; share pages get a public copy but never the avatar (D60).
- Moderation: `report_content(kind='profile_photo')` two-tap from the Tour Card, visible only when a signed avatar URL exists; lands on the founder desk; Pro-side takedown deferred (D19 precedent).

### 4.6 Settings & appearance
- Theme: `cs_theme` ∈ {dark (default, D76 Charcoal — supersedes D35 light-first), light, auto}; device-local, not on the profile. `legal.html` mirrors it.
- Notification switches: `notify_rounds`, `notify_chat` (profile, server-read by `push`); web push subscription (VAPID) or APNs token (native) per device; season recap email opt-out (`email_prefs.recap`) + unsubscribe token in every email (D68).
- Discoverability: everyone / friends / nobody — gates `search_golfers` and `tour_card`.
- Mute is profile-level, enforced by RLS on posts/comments; rounds still show.

### 4.7 Account deletion (`20260718172300` = current body; lineage `20260714200000` → `…210000` → `20260715210000` → `20260717205347`)
1. Blocked (raises) if you are commissioner of a league that has other members, or creator of an event with other players — "Hand it off or delete that league first".
2. `has_footprint` = any `rounds` OR `season_adjustments` OR `draft_picks` OR shared `live_round_players` rows.
3. No footprint → **hard delete**: explicit child-first cleanup (posts/comments, solo live rounds, feedback, captaincy, solo leagues/events, invites, course provenance) then `DELETE FROM auth.users` (cascades). Any unknown FK blocker → **RAISES with table.constraint and rolls everything back** ("Nothing was changed — screenshot this and send it in via Feedback"); the account stays usable and the email is NOT burned. (`20260717205347` — "loud", after the owner's own email got silently tombstoned on 2026-07-14.)
4. Footprint → **tombstone**: `display_name='Former member'`, handle/city/home/marker/ghin → null, `discoverable='nobody'`, `deleted_at=now()`; friendships deleted; push subscriptions deleted; `auth.users.banned_until='infinity'`. Rounds, ledger and standings are untouched (§16 rounds immutable; a departure never shifts anyone else's pot).
5. Client: two-step inline confirm → `delete_account` → `signOut` → reload to the door. A later `signInWithOtp` on a tombstoned email fails and the door explains it.
6. Not done by the RPC: avatar object in `media` is NOT removed on tombstone (photo_path is not nulled either — see §7); `device_tokens` cascade only on hard delete (FK ON DELETE CASCADE) and are NOT deleted on tombstone; `email_prefs` likewise persists (recap emails filter on membership so a tombstoned member with a real email could still be listed — see §7).

### 4.8 Legal / privacy
- Terms & Privacy links on the door and in Settings; Prize Pool Disclaimer (D39 "track, never hold") — all static HTML, last updated 2026-07-18. Privacy already discloses AI scorecard reading and photos. `spec/appstore-runbook.md` carries the App Store nutrition-label list (email, name, city, photos, usage events) and the listing decisions D98 says hold verbatim.

---

## 5. Edge cases & landmines the iOS build must honor

1. **Never call an auth method synchronously inside `onAuthStateChange`** — internal lock deadlock, zero output. Use `onAuth`/`deferAuthWork` from `@cs/db`. (17740; `packages/db/auth.ts`.)
2. **8-digit OTP**, never a 6-cap input; `textContentType="oneTimeCode"` for iOS autofill (already in `index.tsx`). Auto-submit at 8; re-arm after a failed verify.
3. **Code-only OTP; no `emailRedirectTo`; no magic links.** `requestEmailCode(client, email)` takes no options bag on purpose.
4. **Gate onboarding on `marker` AND `handle`, not on profile existence.** Pre-fill name only when it isn't the email-derived default (normalized compare).
5. **Save order on the card:** `set_handle` first, then `set_profile`. On the edit sheet the order is reversed (card first, handle second) so a cooldown error never discards the rest of the edits — keep that asymmetry.
6. **`set_profile` null semantics:** null = keep for name/city/home/index/marker; `p_ghin` and `p_photo_path` use '' = clear. You cannot clear city/home course through the RPC at all (the web sends `|| null` which keeps the old value — a latent bug, see §7).
7. **Never send `p_index` from the edit sheet** — the index moves only via `set_index` (announced). The card gate is the one legitimate `p_index` sender.
8. **Deploy skew:** Netlify can ship a client before/after its migration. Retry on ANY error by dropping optional args (`call(..., { skewOptional })`), never sniff messages — the `photo_path` 42501 error never named the column. Reads of `profiles` must name columns (email is sealed) and fall back to a legacy column list.
9. **Established-index refusal is information, not an error** — show the server text verbatim ("Your number comes from your scores now (N)…").
10. **"n of 3" state** for a null index; never render 0.0 or "—" as the index of a golfer with 0–2 rounds without the building copy.
11. **Avatar fallback is the marker; never a silhouette.** Unknown marker key → saguaro. Signed URLs expire in 1 h — refresh on foreground resume. Read fence means a signed URL for a non-connected golfer fails to a broken image → fall to marker.
12. **Avatar path must be `{uid}/avatar.jpg`** (server checks prefix; storage policy checks folder). Upsert; the bucket rejects >8 MB and non-JPEG/PNG/WebP — downscale on device first (web crops to 512; HEIC needs conversion — iOS `UIImage`/ImageManipulator handles it natively).
13. **Per-league marker** = `league_members.marker` overrides the profile marker on league surfaces only; Tour Card / You card use the profile marker.
14. **Tombstone semantics:** `display_name='Former member'`, `deleted_at` set; filter them from social pickers; `tour_card` returns not-visible; a banned user's OTP request fails → explain "account closed".
15. **Delete-account guard messages** come from the server (league/event ownership); surface them verbatim and keep the user signed in on failure.
16. **`cs_code` / `cs_claim` / `cs_last_league` / `cs_oriented` / `cs_theme`** are device-local state with ordering rules: consume the invite code BEFORE attempting the join; keep a claim token when the round is "still live" (D86).
17. **Reviewer door** must exist in the native app (App Review can't receive Brevo mail): `reviewer@cupseason.app` → password path, invisible otherwise.
18. **Dates**: never `new Date('YYYY-MM-DD')`; use `localDate`/`isoDate`. Member-since uses `created_at` timestamptz (safe via Date).
19. **Realtime on a dedicated client** (not this slice, but the session token must be forwarded to it on every auth change — 12809–12813).
20. **Every RPC needs its grant** (D37). Preflight check 14 asserts each `call(...)` name has a grant in migrations; a new profile RPC that "silently 403s" is a missing grant.
21. **`handle_new_user` trigger is not in the migrations** — a branch/preview database will not auto-create profile rows. The card gate still works (upsert), but any code assuming the row exists pre-card will differ between prod and a branch.
22. **Sign-out on web reloads the page** to flush classic-side state. Native must instead reset all in-memory state (league, members, avatar map, mutes, pending intents) on `SIGNED_OUT`.
23. **Push toggle is one control, two transports** — native uses APNs via `register_device_token`/`unregister_device_token` and must re-register the token on every signed-in boot when permission already stands (APNs re-issues tokens) without prompting (`syncNativePush` 14011–14022 is the reference behaviour).
24. **Watchdog semantics:** 8 s is a *report*, not an abort; the boot continues. Keep breadcrumbs (`bootStep`) in whatever telemetry the phone posts to `client_events` (authenticated only — signed-out failures are invisible to telemetry today).
25. **Email column is unreadable** by any client role; show the email from the session (`session.user.email`).

---

## 6. What's clunky / web-specific — and what a native app should do differently (opinionated)

**Keep intact (non-negotiable functionality):** email-OTP-only with the reviewer door; card gate on marker+handle with no default marker; the 14-marker set and the marker-as-floor avatar rule; handle rules (format, reserved, 60-day, announced); name-change announcement; starter index → engine handoff and the established refusal; GHIN as an optional reference; discoverability tri-state; mute + report photo (Guideline 1.2 — D98 lists these as survivors); tombstone-vs-hard delete with the loud FK failure; Terms/Privacy/Pot disclaimer reachable from the door and settings; unsubscribe link handling (can stay web — it's an email deep link to `cupseason.app`).

**Do differently:**

1. **Kill the reload-as-navigation pattern.** Verify → `location.replace`, sign-out → `location.reload`, delete → `location.replace`, transfer-pro → `location.reload` are all web crutches for a non-reactive classic script. Native: one session provider, one router; `SIGNED_IN`/`SIGNED_OUT` drive navigation (the B1 scaffold already does this correctly).
2. **Collapse boot into a state machine with visible states.** `boot()`'s watchdog + `authStatus` string is a debug surface, not UX. Native should render explicit states: restoring session → loading card → (card gate) → loading leagues → home, with a retry affordance instead of an 8-second "stalled" string. Keep `bootStep`-style breadcrumbs for telemetry only.
3. **Onboarding should be a 2–3 step native flow, not one long form.** Name → handle (with live availability from a dedicated check, not `search_golfers` — see §7) → marker grid (a real native selection control with haptics) → optional "know your index? / GHIN" as a single collapsed step. Photo can be offered at the marker step ("add a photo, the marker stays your stamp") — the web hides it behind ⚙ which is why the pilot had to be told where photos live.
4. **Use a proper image pipeline.** `expo-image-picker` / `expo-image-manipulator` for HEIC→JPEG, 512² square crop with a native crop UI, then upload with the same path. Cache signed URLs with `expo-image` and refresh on foreground.
5. **Split "Your card" and "Settings" into two native screens** under You (the web packs both into one bottom sheet with a segment). Settings groups: Notifications (system permission state shown honestly, one toggle → APNs), Appearance (Charcoal/Light/Match device — map to `useColorScheme`; keep it device-local), Account (email read-only, sign out), Danger zone (delete), Legal, Build version.
6. **Delete account must meet App Store 5.1.1(v)**: keep the two-step confirm, but native should also show what will happen BEFORE the tap (hard vs tombstone) — the server decides, so call nothing beforehand; mirror the copy. Surface the league/event-ownership block with a deep link to that league.
7. **Theme is device-local and should stay that way** (no profile column) — but use the system appearance API rather than `matchMedia`.
8. **Handle availability**: today it's a debounced `search_golfers` (a discoverability-filtered search). Ask for a tiny `handle_available(p_handle) → boolean` RPC (or accept the server error at save time) — the phone should not infer uniqueness from a search result.
9. **Card gate pre-fill** should also read `raw_user_meta_data.display_name` only if present; otherwise leave name blank (the web's normalized-email compare is a workaround for the m001 default).
10. **Web push / service worker / install nudge / `?debug` / `?exit` / `?forge`** — none of it ports. `device_tokens` + APNs replaces web push; there is no SW; the QA hatches become a dev menu.
11. **The You tab's "founder desk"** is desk work (D98) — do not build it on the phone; the report pane stays on desktop.
12. **Members-sheet marker override** should live on the league's member list with the same "Use my profile marker" reset; it's a self-only action so it can also sit on Your card as "marker in {league}".
13. **Legal**: open `https://cupseason.app/legal.html#…` in an in-app browser (SFSafariViewController) rather than re-shipping the text; but App Review needs a Privacy Policy URL anyway, so this is a plus.
14. **Loose error mapping (`humanError` 4084–4097)** is regex-on-message; the shared `humanAuthError` is the start of a better one. Native should map by `code`/`status` where Supabase provides them and fall back to server text for RPC business errors (they are already written for humans: "Your number comes from your scores now…", "That handle is taken", "Your @handle can change once every 60 days — next change on Aug 14").

---

## 7. Open questions

1. **`on_auth_user_created` trigger provenance.** `handle_new_user()` is in the baseline but its binding on `auth.users` is in no migration. Is it managed in the dashboard? A Supabase branch (which the MCP tooling can create) will not mirror it. Either capture it in a migration (can a migration create a trigger on `auth.users`? — yes with the postgres role) or document that branches need it applied by hand.
2. **`set_profile` cannot clear city / home course** (`coalesce(excluded.city, profiles.city)`); the web edit sheet sends `null` for an emptied field, which keeps the old value. Bug or intentional? A native settings screen will expose it immediately.
3. **Tombstone leaves `photo_path` set and the avatar object in storage.** `can_see_media` still lets former league-mates sign a URL for a "Former member" avatar. Should `delete_account` null `photo_path` and delete `{uid}/avatar.jpg`? Also `device_tokens` and `email_prefs` survive a tombstone (tokens: banned user can't refresh a session so pushes should stop, but the row lingers; email_prefs: `season_email_payload` filters on `league_members` + `p.email`, and a tombstoned member is still in `league_members` with a real email — do they receive the recap?).
4. **`delete_round` and the index**: `round_refresh_index` is AFTER INSERT only. Deleting a counted round leaves `index_current` stale until the next post. Acceptable, or should `delete_round` recompute? (Other slice owns `delete_round`, but the You tab exposes the × here.)
5. **Handle check via `search_golfers`** reports "available" for handles owned by `discoverable='nobody'` golfers until the save fails. Worth a `handle_available` RPC before the native build relies on it?
6. **`index_source='ghin'`** is referenced by the trigger but never set. Dead value or planned?
7. **spec §5 vs the engine**: max index 30.0, +1.0 in-season rise cap, exceptional-score cut, monthly revision — none are implemented; the engine revises per round with no caps. Is §5 formally superseded (D44/D49 amend only parts)? Native copy ("WHS-style best of your recent rounds") should match what's built.
8. **Local `config.toml` says `otp_length = 6`** while prod issues 8. Should the local config be aligned so a local stack doesn't train a 6-digit habit?
9. **Legacy profile columns** (`card_quote`, `the_miss`, `walk_ride`, `beverage`) — dead? Drop, or resurrect on the native card?
10. **Reviewer account on native**: same `reviewer@cupseason.app` password path — does the account exist in prod today, and does D98's Expo app need it before TestFlight (yes for App Review)?
11. **Orientation on native**: `cs_oriented` is device-local by design (D82). Fine to re-show on a first native install for existing web users? Probably yes — worth confirming the copy ("four places") matches the phone's IA, which per D98 lacks the wizard/draft.
12. **`?unsub` handling**: stays a web page; should the phone register the universal link so it opens in-app, or deliberately leave it to Safari? (The AASA exists from W2.)
13. **Photo report reader**: only the founder desk reads `content_reports`. Is a Pro-side takedown still deferred for launch (D59 says until real abuse)?
14. **Email exposure via `delete_account` hard path**: `member_invites` rows keyed by email for a deleted user are removed; but `invites` (league email invites) referencing that email are not touched — data-retention question for the privacy policy.
