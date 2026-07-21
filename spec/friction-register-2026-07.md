# Friction register — 2026-07-21

*Deliverable of the friction-audit brief (`spec/friction-audit-brief.md`). A
REGISTER, not fixes — the owner picks batches after. Zero app-code changed this
session; this file is the only write. Read-only against PROD Supabase throughout
(guardrail honored — see §Evidence & method).*

---

## Executive summary (10 lines)

1. **New findings: 7** — P0 ×0, P1 ×3, P2 ×1, P3 ×3. Plus a large "verified
   clean" set and cross-refs to the launch audit / design reviews (nothing
   re-filed).
2. The product is in good shape: signed-out boot and the full demo diorama
   (Home, You, post/live/draft, the League Room's 5 tabs) render **clean in
   light + dark, at 375 and 1280** — no `undefined`/`NaN`/`${}` leaks, **no
   horizontal overflow on any view**, no stray prod calls.
3. **Scariest #1 — F-007 (P1):** a **live production error on real (iOS) users**,
   fired twice on 2026-07-21 (`client_events`): `Can't find variable: memName` —
   a classic↔module bridge miss (`const memName` lives in the module, is called
   from a classic block, and is never `window.*`-bridged). Silently breaks board
   name / kudos / comment rendering for signed-in users. WebKit-only phrasing =
   iOS, the submission target.
4. **Scariest #2 — F-001 (P1):** the demo's "Start a league" CTA fires the real
   `create_league` RPC (no `!state.demo`/auth guard) → prod round-trip → a raw
   Postgres error on the acquisition tour. Reproduced live. No data risk (insert
   fails atomically).
5. **Scariest #3 — F-002 (P1):** 3 **new** unescaped user-string sinks the
   launch audit didn't list (Ryder team names ×2, friend `display_name` in tag
   chips); the SEC-C6 esc() cluster is otherwise **now fixed**. Plus **F-003
   (P2):** ~70 sites surface raw backend `.message` jargon to users.
6. **`client_events` mined** (Docker back up): 20 events / 4 users / since
   2026-07-17. The **only** error rows were the two F-007 rejections. Funnel
   hint (small N, watch not file): 13 `post_open` → 4 `post_submit` across 4 → 2
   users.
7. Positive confirmations worth banking: **legal.html is live** (Privacy +
   Terms + Prize-Pool disclaimer — closes the launch-audit App-Store blocker);
   **all 71 client RPCs are granted** (no silent 403s); sw.js cache ⊆ dist
   allowlist; OTP `maxlength=10`; date landmines clean; demo gating otherwise
   airtight.
8. **Recommended Batch 1 (client-only, no migration, ~½ day):** **F-007 + F-001
   + F-003** — bridge `memName` (one line, stops a live iOS error), guard
   `createLeague`, humanize the error surface. Highest value per hour.
9. **Batch 2 (fold into the launch-audit hardening pass):** **F-002** — 3
   `esc()` wraps, ships with the SEC-C6 security work.
10. **Batch 3 (polish):** **F-004/F-005/F-006** — bridge `window.E`, empty
    Ryder view, maskable-icon offline parity.

---

## Findings

### F-001 · Demo "Start a league" fires the real `create_league` RPC → raw DB error · **P1**
- **Surface:** demo diorama → Home ("Peek at a live season") · both viewports · both themes.
- **Repro (reproduced live):**
  1. Sign-out door → tap **Peek at a live season** (`#obDemo`, enters demo; `state.demo=true`, `CS.user=null`).
  2. On the demo Home, tap **Start a league** (`index.html:6620`, a `[data-hgnew]` card that forwards to `#wCreate`, `:6630`).
  3. `#wCreate` handler (`:11790`) calls `createLeague()` with no demo/auth guard.
  4. `createLeague()` (`:10042`) calls `sb.rpc('create_league', …)` → **hits PROD** → Postgres rejects on NOT-NULL `commissioner_id` (no auth) → caught at `:11810` and shown via `authStatus('Create failed: '+e.message)`.
- **Evidence:** console `[error] [cs] Create failed: null value in column "commissioner_id" of relation "leagues" violates not-null constraint`. Post-check: `CS.league=null` → **no row created** (single-RPC insert fails atomically; PIGL untouched, no orphan).
- **Suspected cause:** `createLeague` (`index.html:10042`) and its caller `#wCreate` (`:11786-11811`) have **no `!state.demo` gate and no `CS.user` check** before the write. The demo-gating pattern that guards every other `sb.*` path is missing here. (Also mechanically enabled by launch-audit **SEC-C5** default-execute-to-anon — the RPC accepts an anon caller instead of 403-ing.)
- **Effort:** S — early-return/route-to-sign-in when `state.demo || !CS.user`; humanize the caught error.
- **Batch:** 1 (with F-003). Client-only, no migration.
- **Dedup:** not in launch audit or design reviews. The raw-error symptom overlaps F-003; the guard gap is the root finding.
- **Disclosure:** this was triggered inadvertently by a click on an unlabeled button during the read-only walk. The insert was rejected by Postgres before any write landed — **no PIGL data was created or modified.** Surfaced here because it is a real, user-reachable defect in the demo (an acquisition surface).

### F-002 · Three new unescaped user-string sinks (residual stored-XSS) · **P1**
*(same class as launch-audit **SEC-C6**, which is otherwise now fixed — verified escaped at current lines. These three were not in that list.)*
- **Surface:** Ryder scoreboard (event room) + declare/retag round sheets · all viewports/themes · **code-read** (need signed-in event/friend data to render live).
- **Repro (code-read):** `esc()` (`:3057`) escapes `& < > " '`. These interpolate user-controlled text into `innerHTML` without it:
  | file:line | field (user-controlled) | surface |
  |---|---|---|
  | `index.html:8041` | event team name `A.name`/`B.name` (organizer free-text, `#rsA/#rsB`) | Ryder `statusChip` → `#eventBody.innerHTML` (`:8049`) |
  | `index.html:8046` | event team name | Ryder `clinchLine` → `#eventBody.innerHTML` (`:8056`) |
  | `index.html:11331` | friend/member `display_name` (`c.name`, from `my_friends`/`CS.members`) | `tagChipHtml` → declare sheet (`:11369`) + retag sheet (`:11537`) |
- **Evidence:** sibling renders at `:8052/8054/8078/8079` and `:11128/11129` DO `esc()` the same values — proves oversight. `display_name` is only `.trim()`ed server-side (`set_profile`); token lives in `localStorage` (default `persistSession`) → account-takeover class per SEC-C6.
- **Suspected cause:** missed `esc()` wraps at the three lines above.
- **Effort:** S — 3 wraps. **Middot caveat:** line **8046 contains 2 literal `·` (U+00B7)** — anchor the Edit on that byte, not `·` (nearby lines in the same function use the `·` escape form; file is mixed).
- **Batch:** 2 (ship with the SEC-C6 hardening pass). Inherits that finding's launch-blocker status.
- **Dedup:** extends launch-audit SEC-C6 (cite). Not a re-file — the SEC-C6 lines are now escaped; these three are new.

### F-007 · `memName` referenced across the classic↔module boundary, unbridged → live iOS `ReferenceError` · **P1**
- **Surface:** signed-in board / social render (chat board names, kudos attribution, comments) · real users · **`client_events` + code-read**.
- **Repro (real-user evidence + code-read):**
  1. `client_events` holds 2 `client_error` rows, both `{"msg":"async: Can't find variable: memName","kind":"rejection"}`, at 2026-07-21 00:30 and 02:17 UTC — real signed-in users, not this session.
  2. `memName` is a top-level **`const`** in the **module** block (`index.html:9696`; module spans `<script type="module">` 8544-12070).
  3. It is called from the **classic** block (2837-8538) at `:3546` (`myBoardName`), `:3614` and `:3616` (`fetchSocial` → kudos/comment name mapping).
  4. A top-level `const` is block-scoped to its own `<script>` and is **not** a `window` property, so classic code cannot see it; there is **no `window.memName =` bridge** anywhere. Bare `memName(...)` in classic → `ReferenceError` → WebKit renders it "Can't find variable: memName" (Chrome/V8 would say "memName is not defined"), caught by the global `unhandledrejection` handler.
- **Evidence:** `client_events` (event=`client_error`, ×2, today). Script-block boundaries: classic `2837-8538`, module `8544-12070`. `memName` def at `:9696`; unbridged (grep shows no `window.memName`). Same failure class as the historical `window.sb` demo-fallback landmine (CLAUDE.md).
- **Suspected cause:** `index.html:9696` `const memName` not exposed to classic; classic callers at `:3546/3614/3616` assume it's global. The `.toUpperCase()`-style siblings elsewhere are in-module (fine); only the three classic callers throw.
- **Impact:** silent — the affected social render aborts (names don't resolve on the board / kudos / comments) for whoever hits the path; no visible crash, so it went unnoticed until instrumentation caught it. WebKit-only phrasing = **iOS users**, the submission target.
- **Effort:** S — one bridge line in the module (`window.memName = memName;`) next to the existing `window.CS/sb/…` bridges; classic callers then resolve it. Verified the siblings do NOT need it: `memPid`/`memMk`/`memCi` (`:9700/9701/9727`) are module-defined AND only called module-side (`:9739-9960`) — `memName` is the sole cross-boundary caller.
- **Batch:** 1 (cheapest, stops a live error).
- **Dedup:** NOT the already-owned boot rejection ("reading 'n'" — different message); genuinely new. Same landmine *class* as CLAUDE.md's bridge note, new instance.

### F-003 · ~70 raw backend error strings surfaced to users · **P2**
- **Surface:** toasts + auth/boot screens across the app · all viewports/themes · code-read + one live instance (F-001).
- **Repro (code-read):** raw `.message` interpolated into user-facing `toast()`/`authStatus()`/`textContent`. Worst class — **bare `toast(e.message||…)`** with no humanizing: `index.html:7784, 9988, 10605, 10656, 11072, 11080, 11088, 11105, 11145, 11161, 11180, 11412, 11552, 11618, 11631, 11643, 11659`. Labeled-but-still-raw (Postgres jargon after a prefix): ~33 sites incl. `:8840, 9034, 9327, 10001, 10359, 10519, 11857`. Auth/boot: `:9179, 9186, 9248, 10213, 11810` (F-001's surface), `11923`.
- **Evidence:** live example from F-001 — user sees *"null value in column commissioner_id of relation leagues violates not-null constraint."* Design-review-2026-07-16 §5 and launch-audit UX-Medium both name this ("~20 toasts"); this is the fuller inventory.
- **Suspected cause:** no shared error-humanizer; each catch appends `e.message`.
- **Effort:** M — a `humanError(e)` helper mapping known classes (constraint/schema-cache/network/auth), raw kept to console/`client_events`. Do the bare-`toast(e.message)` set first.
- **Batch:** 1 (with F-001 — the helper fixes F-001's surface too).
- **Dedup:** design-review-2026-07-16 §5 + launch-audit UX-Medium (cite; this adds the line list).

### F-004 · `window.E` never bridged → feedback rows always get `event_id: null` · **P3**
- **Surface:** feedback submit (You tab / former pill) · code-read.
- **Repro (code-read):** `submit_feedback` reads `window.E?.event?.id` at `index.html:10508`, but `window.E` is **never assigned** anywhere (the real event global is a local `const E=window.CS_EVENT` at `:8026/11120` — a different name). Optional-chained, so no crash — the field is silently always `null`.
- **Evidence:** bridge audit found no `window.E =` in the module; every other classic↔module bridge (`window.CS/sb/mkr/…`) is present.
- **Suspected cause:** typo/rename — should read the event context that actually exists (`CS_EVENT`/`CS.event`), or drop the field.
- **Effort:** S.
- **Batch:** 3. **Dedup:** none.

### F-005 · Ryder `view-event` renders empty ("← HOME" only) with no event context · **P3**
- **Surface:** Ryder room reached without a selected event · demo · both viewports.
- **Repro (live):** `switchView('event')` in demo with no `CS_EVENT` → `view-event` body is just a back link (6 chars of text). A user who lands here sees a blank room.
- **Evidence:** demo view-scan — `view-event` len=6 ("← HOME") vs 400-700 chars for every other view.
- **Suspected cause:** no empty-state guard when the event room is shown without a loaded event; likely low real-world reachability (entry points load an event first), so low severity.
- **Effort:** S — empty-state copy, or block the transition when no event is loaded.
- **Batch:** 3. **Dedup:** none (design-review §3 flags League/Ryder duplication conceptually, not this render).

### F-006 · `icon-512-maskable.png` not in the SW SHELL precache · **P3**
- **Surface:** PWA install while fully offline · n/a theme.
- **Repro (code-read):** `manifest.webmanifest:15` references `icon-512-maskable.png`; sw.js `SHELL` (`:10-13`) precaches only `/`, manifest, `icon-192`, `icon-512`. It's in the dist allowlist so it resolves from network — absent only in the pathological "add-to-home-screen while offline" case.
- **Evidence:** sw/dist cross-check.
- **Suspected cause:** SHELL deliberately minimal; maskable icon omitted.
- **Effort:** S — add `/icon-512-maskable.png` to SHELL for offline-install parity (optional).
- **Batch:** 3. **Dedup:** none.

---

## Verified clean / not reproduced (coverage receipts — no finding)

- **esc() SEC-C6 cluster (prior launch-audit lines):** all now **escaped** at current lines (7382, 9956/9960, 3434, 5795/5799/5801, 7518, 6260/6268, 3506/3514). Fixed since 2026-07-18.
- **F3 "stray `—` dialog" (design-review-2026-07-20):** not reproduced — only `#sheet` (the shared scaffold, empty when closed) exists; no dash-only modal in any state walked.
- **RPC grants:** all 71 client `.rpc()` names have `grant execute … to authenticated`; the only 4 anon-granted are the sanctioned public endpoints. No silent-403 gap.
- **sw.js:** VERSION uses `__CS_VERSION__` (not hand-edited); precache ⊆ dist allowlist; no install-time 404.
- **OTP:** input `maxlength=10`, validator `< 6` (accepts 8-digit), auto-submit at 8. Correct.
- **Date landmines:** clean. The one suspect (`new Date(p.member_since)`, `:8958`) is a **false positive** — `member_since` maps to `p.created_at` (timestamptz, has time) at migration `20260716070000_identity_legit.sql:118`, so it parses correctly in Phoenix. No `toISOString().slice` date-writes.
- **`color-scheme`:** `<meta content="light dark">` (`:7`) — native pickers match theme. Not dark-hardcoded.
- **`alert()`:** zero. **`console.log`:** 2, both benign breadcrumbs (`[realtime]`, `[boot]`), no PII/token.
- **Demo gating:** every `sb.*` path gated except F-001. Confirmed live — **zero prod network calls during the entire demo walk.**
- **Classic↔module bridges:** all present except `window.E` (F-004).
- **Responsive:** no horizontal overflow (`scrollWidth == 375`) on home/record/post/play/stats/draft at 375; League Room tabs clean at both sizes.
- **Themes:** light + dark both render clean (dark bodyBg `rgb(10,14,12)`, no leaks) via the app's own `setTheme`.
- **legal.html:** served 200 (5924 B), in dist allowlist, contains Privacy Policy + Terms of Service + Prize Pool Disclaimer → **closes launch-audit App-Store blocker** (no legal docs).
- **Boot (signed-out):** splash reveals (forceReveal net intact), `#errbar` empty/hidden, bridges present, `#obCaption` = `v23 · __CS_VERSION__` (expected local unstamped). No console errors.

---

## Cross-referenced elsewhere (owner already has these — NOT re-filed)

- **Security P0/P1 cluster** (self-promote to Pro, forge rounds, anon lifecycle/Ryder calls, default-execute-to-anon, `profiles_read`, `test-seed`, `finish_live_round`): **launch-audit-2026-07-18** §2-3. F-001 and F-002 touch this surface; cite, don't re-file.
- **REL-C1 month-close bomb (first fire Aug 1, 2026)** + **REL-C2 scan-claim bomb** (CHECK-constraint mismatches): launch-audit §7. Calendar-driven, P0 reliability — flagged here only so the friction register is self-aware; fix lives in the hardening migration.
- **OPS-C7 publish-dir leak:** **resolved** — dist allowlist exists (`stamp-version.sh:38`, D37). Confirmed legal.html routes through it.
- **Wizard W1-W6 · Welcome/tour T1-T4 · Noun sweep N1-N8 · ceremony F9-F14 · feed F11-F13 · a11y F1/F2/--dim:** **design-review-2026-07-20** (+ `-07-16`). Owner has the resolution plan; F1 light-CTA contrast + `--dim` AA fail still reproduce (confirmed `--dim=#8C9992` light) but are that review's to batch.
- **Courses function rate-limit (SEC-M1 / task #27)**, **media read-scoping (SEC-M3)**, **launch hygiene (task #34)**, **timed QA ritual (task #14)**: cited, out of this register's scope.

---

## Evidence & method (five sources)

1. **Browser walkthrough — DONE.** Local serve `python -m http.server 8791`
   (single listener PID 21776; served bytes == local 684991 → port-multibind
   landmine cleared). SW unregistered + `cupseason-__CS_VERSION__` cache deleted
   before testing. Walked read-only via the **demo diorama** (`obDemo` — verified
   makes zero prod calls) + signed-out door: Home, You/stats, record, post, live,
   draft, Crew → League Room (Standings/Board/Schedule/Pot/League), × 375/1280 ×
   light/dark. State probed via JS (splash-screenshot + console-doubling landmines
   avoided). **Not walkable read-only** (need a signed-in real league = a write —
   repro-by-reading per guardrail): OTP entry, real wizard→lock, real posting,
   guest-claim, scan upload.
2. **Code audit — DONE.** Four parallel read-only sweeps: esc() sinks; `window.*`
   bridges + demo gating; date/OTP/error/color-scheme; RPC-grant + sw-cache
   cross-check. Findings above; middot encoding noted per affected line.
3. **Pilot feedback + design reviews — DONE.** No `pilot_feedback_rows*.csv`
   exists anywhere in the tree (only the `feedback`/`pilot_instrumentation`
   migrations). Tester feedback is captured in design-review-2026-07-20 Part II
   (W/T/N) — cited, not re-filed.
4. **`client_events` — DONE (Docker back up).**
   `supabase db dump --linked --data-only -s public` (read-only; dumped to local
   scratchpad, PII never surfaced). Table = **20 rows / 4 users / since
   2026-07-17** (instrumentation's first day). Columns: `id, profile_id, event,
   props, created_at`. Distribution: 13 `post_open`, 4 `post_submit`, 1
   `scan_post`, **2 `client_error`**. Both error rows are the **F-007**
   `memName` rejection (2026-07-21 00:30 + 02:17 UTC) — the audit's most
   valuable single finding came from here. Funnel observation (small N — noted,
   not filed): 13 `post_open` → 4 `post_submit` across 4 → 2 distinct users;
   worth watching once volume grows (post-flow completion). (Earlier this
   session the dump was blocked — the CLI shells out to Docker for the dump
   role and Docker was down; re-run succeeded once it was up.)
5. **Console + network — DONE.** Signed-out boot: no console errors, 3× GET
   index.html (200) only. Demo walk: **no supabase requests** (guardrail
   confirmed) + the F-001 create error. Known pre-existing boot async rejection
   ("reading 'n'") + repeated-boot: already owned — folded in, not re-filed
   (did not fire on the signed-out path this session).

---

*Filed by the Growth/Launch friction-audit lane, 2026-07-21. Zero app-code
changed. Owner reads the summary and picks Batch 1.*
