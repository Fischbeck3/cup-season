# Slice: `supabase/functions/` — line-by-line audit

Date: 2026-08-30 · Auditor: Claude (Opus 5) · 1,765 lines across six functions:
`courses` (291), `push` (501), `scan` (233), `season-email` (266),
`test-seed` (367), `weather` (107). Every line read.

**Session-code note:** `git diff --stat 34d20b6..HEAD -- supabase/functions/`
is **empty**. None of this slice was touched by this session's seventeen
commits, so nothing here got the extra-hard pass; the whole slice was read at
the same depth instead.

**Live verification performed** (read-only `supabase db query --linked`):
webhook trigger targets and their event types; `relacl` / `relrowsecurity` /
policy counts on the eight tables these functions write; whether the deployed
`season_email_payload` returns `solo`. Findings that rest on those are marked.

---

## The headline

The two functions that spend money — `courses` (GolfCourseAPI) and `scan`
(Anthropic vision) — both carry cost-control machinery that is **weaker than
its own comments claim**. `scan`'s header promises "fail closed, always before
spending"; four consecutive reads in that path drop `{error}`, and every one of
them fails *open*. `courses`' per-user cap is a read-then-write with the write
neither awaited nor checked. Neither is currently costing money — the caps are
generous and traffic is a pilot league — but both are the CLAUDE.md landmine
("supabase-js NEVER throws on a database error") applied to the exact code
whose job is to refuse.

The one finding I'd fix first is not a cost bug, though. It's F1: the course
cache **deletes before it knows the replacement is good**, on a code path that
runs unattended against courses that were previously healthy.

---

## `courses/index.ts` — the paid proxy

Auth is right, and better than the platform default: the file knows that
`verify_jwt` accepts the bare anon key and resolves a real `uid` before doing
anything (`:139-147`). The comment explaining why is the kind that earns its
keep. `gca()` logs status + a body snippet and explicitly never logs headers,
because `KEY` rides in `Authorization` (`:44-45`). Good.

**F1 — `fetchAndStore` empties the cache before it can fill it.** `:108-131`:

```ts
await admin.from("api_course_tees").delete().eq("course_id", cid);
for (const te of flattenTees(c)) { ... }
```

`flattenTees` returns `[]` for any payload whose `tees.male` / `tees.female`
isn't an array — which is **exactly the upstream shape change this same file
documents at `:58-62`**, where `tees.male` became the number `8` and every
search 502'd for twelve days. That incident hit the search endpoint. Nothing
says the detail endpoint is immune, and if it ever does the same thing, the
delete has already run: the course's tees and holes are gone, the function
returns `cid`, and the handler answers `{ok:true, id}`.

The path that makes this dangerous is the *background* one. `:265-272` calls
`fetchAndStore` on a cache HIT — a course that has `holeCount > 0` and is
merely 180 days old — after the response is already sent, with only a
`console.error` behind it. So the failure converts a healthy cached course into
an empty one, unattended, and the "serve-always from cache, a course NEVER goes
stale from the user's view" guarantee written at `:243-249` is broken by the
routine that maintains it. The `api_courses` upsert two lines up (`:95-106`)
also drops `{error}`, so an upsert failure reaches the delete too.

Fix is small: flatten first, refuse to touch the cache when the list is empty.

**F3 — the daily cap is advisory.** `:153-176`. Count, then insert *without
awaiting and with both callbacks empty*:

```ts
admin.from("courses_usage").insert({ profile_id: uid, action: ... })
  .then(() => {}, () => {});
```

Two consequences. Concurrent requests all read the same `used` (a burst at
`used = 149` all pass a cap of 150). And if `courses_usage` ever stops
accepting rows, the counter freezes and the cap **never fires again** — the
error is discarded by construction. The `scan` function three directories over
solves precisely this with a reserve-then-count (`scan:115-146`, and its comment
names the TOCTOU race). `courses` didn't get the same treatment.

**F4 — cache hits burn the cap.** The ledger row is written at `:175`, *before*
the action branch, so `action:"cache"` counts even when `:276` returns
`from_cache: true` having made zero API calls. `index.html:7229` fires that
action on **every tee pick**. A Pro setting tees on already-cached courses can
be 429'd off a paid-API limit having cost the business nothing.

**F15 — raw error text on the wire.** `:286-290` returns `(e as Error).message`
to the client. Bounded today; one future throw inside `fetchAndStore` puts a
PostgREST message there.

Not bugs, checked and cleared: the `fetches >= 3` enrichment bound works (it
re-tests `c.tees.length` after the cache fill, so the loop over `courses`
rather than `bare` is correct); `new Date(hit.cached_at ?? 0)` degrades to a
refresh, which is the safe direction; the per-course try/catch at `:188-200`
does stop one malformed row from 502-ing a search.

---

## `weather/index.ts` — the free one

**F2 — one cache row for every manual location on earth.** `:54` defaults
`courseId` to the literal `"manual"`; `:73-77` and `:99-101` key the cache on
`(course_id, play_on)` — confirmed to be the primary key at
`20260718192400_round_object.sql:112`. So golfer A in Phoenix and golfer B in
Seattle asking about the same date within six hours **share a forecast**, and
B gets A's. The row stores `lat` and `lon` and never reads them back, which is
what tells you the key was meant to include the location.

**F16 — today's weather vanishes at 5pm.** `:68-70`. `day` is the date parsed
at UTC midnight; `day < now - 24h` becomes true once wall-clock passes
`date + 24h UTC` = **17:00 Phoenix** on the day of the round (14:00 in Hawaii).
A golfer opening a 5:30pm round sheet for today gets `out_of_range` and a
hidden weather line. The CLAUDE.md UTC-midnight landmine, in its comparison
rather than its rendering form.

Everything else here is sound and the fail-soft discipline is genuinely good:
no key, nothing to leak, nothing to bill, and every refusal is a named `reason`.

---

## `scan/index.ts` — the vision call

I loaded the `claude-api` reference before judging the API call, per its trigger.
The call shape is **correct and current**: `claude-opus-4-8` is a live model
($5/$25 per MTok); `output_config: { format: { type: "json_schema", schema } }`
is the current parameter (the deprecated one is `output_format`); checking
`stop_reason === "end_turn"` before reading content is right, and it correctly
treats `refusal` / `max_tokens` as content outcomes rather than exceptions.
`normalize()` is careful — `Math.round(Number(x))` then `Number.isFinite`, the
0-20 clamp, the 6-player slice, the par 3-6 filter. No bug in the model call.

**F5 — a request that cost nothing still burns a slot.** `:131-146` reserves,
`:181-196` finalizes. The reservation is deleted **only** on cap-reject. A 400
(a HEIC mislabelled `image/jpeg`, an oversized image), a 401 (bad key), or the
`no_api_key` path all leave the row standing. The comment at `:190-191` argues
"it still spent the call, so it counts" — true for 429/5xx/refusal, false for
every 4xx where the API rejected the request. The code has `r.status` in hand
at `:184` and doesn't branch on it. Five bad photos and the golfer is locked
out for 24 hours, having cost zero.

**F6 — the kill switch fails open.** `:120-123`:

```ts
const { data: flagRow } = await admin.from("app_flags")...
const flag = flagRow?.value ?? {};
if (flag.enabled === false) return soft("disabled");
```

`{error}` is dropped. Any read failure gives `flag = {}`, `enabled` is
`undefined`, `undefined !== false`, and scanning proceeds. Same at `:131` (the
reservation — a failed insert yields `resvId = null` and a count that doesn't
include this call) and at `:136-141` (both count queries). The header's
"1. kill switch … fail closed, always before spending" is not what the code
does; it fails open on all four.

**F20 (opportunity)** — `claude-opus-5` is the same $5/$25 per MTok as
`claude-opus-4-8`. A same-price capability upgrade for an OCR task, whenever
this is next touched. Not a bug; the current model is valid and supported.

`media_type` (`:109`) is unvalidated and forwarded to the API, but the only
caller sends the constant `'image/jpeg'` (`index.html:7055`), so this is a
contributor to F5 rather than a finding of its own.

---

## `push/index.ts` — the sender

This is the most carefully written file in the slice. The D68 lesson is fully
absorbed: `reply()` at `:90-96` names every exit and logs it, `:344` logs every
invocation before branching, and the ECDSA/JWS work at `:215-228` is correct
(raw r‖s from WebCrypto is exactly what ES256 wants; `iss`+`iat` with no `exp`
is exactly what APNs wants; the 45-minute cache sits inside Apple's 20-60
minute window).

**F7 — HTML injection into the friend-request email.** `:322-334`:

```ts
const who = firstName(fromName);
return `... <strong>${who}</strong> wants in your crew ...`;
```

`fromName` is `profiles.display_name`. `firstName` only takes the first
whitespace-delimited token, so anything without a space survives intact —
`<a/href="https://evil.example">Verify</a>` is one token. Every person the
attacker friend-requests receives that inside a Cup Season-branded email from
`hello@cupseason.app`. The neighbouring `season-email` defines `esc()` at
`:39-41` and escapes every single interpolation; `push` has no escaper at all.

**F17 (opportunity)** — `:260` fires one `actionable_count_of` RPC per distinct
recipient. The comment bounds it ("≤ a dozen recipients per post") and that's
true today; a `uuid[]` overload would make it one call and stop the bound from
mattering.

**F18 (opportunity)** — the file never asserts `table`. After the `friendships`
and `push_nudges` branches, **anything** falls into the post path (`:424+`). I
confirmed four webhooks point here. A fifth, wired by mistake, would answer
`no-league-or-event` — which reads as a data problem, not as the misroute it
is. One `if (table !== 'posts') return reply('unexpected-table', {table})`
finishes the discipline the rest of the file keeps so carefully.

**F11** — `:337` compares the secret with `!==`. Non-constant-time. I could not
construct a realistic remote timing attack against a Deno edge isolate, so I'm
filing this as hardening, not a bug. It does fail closed when the env var is
unset (`null !== undefined`), which is the important half.

Checked and cleared: `postKind`'s settlement routing (`:142-147`) matches the
D92 comment and the `notify_system` bypass for settlements at `:457` is
deliberate; `prefsOf`'s array/object normalisation (`:466`) is a real PostgREST
quirk, correctly handled; no PII reaches any response (`who()` selects `email`
at `:350` and it only ever goes to Brevo).

---

## `season-email/index.ts` — the recap

Escaping is thorough here (`esc()` on every interpolation), the money formatter
is correct, and the "be liberal in what we accept, never bail silently"
handling at `:185-227` — logging the actual key names it received — is a
direct and good response to the D68 incident.

**F9 — the duplicate-send guard reads a field that is always null.** `:229`
`if (row.sent_at) return new Response('already sent')`. But the invoker is
`CREATE TRIGGER season_email AFTER INSERT ON public.email_queue` (verified live),
so `record.sent_at` is NULL by construction on every webhook delivery. And
`mark_email_sent` (`20260725140000:173-178`) is an unconditional
`update … where id = p_id`, not a compare-and-set. Nothing in the path reads
back committed state, so any second delivery re-sends the full recap to the
whole league. Worth noting: the sibling `push-friends` trigger IS
`AFTER INSERT OR UPDATE` — the shape is present in this codebase.

**F10 — the cancellation branch mails whatever the body names.** `:191-215`.
`rec` falls back to the bare request body, and the loop takes `email`, `name`
and `cents` **straight from it** — never reading `cancellation_notices` back by
`rec.id`. Only the shared `x-push-secret` gates it, and that secret is on four
other webhooks. The season path does this properly (recipients come from
`season_email_payload`); this one should re-read the row.

**F19 (opportunity)** — `Payload` (`:30-37`) has no `solo`, but `:250` reads
`p.solo`. I checked the deployed function: `season_email_payload` **does**
return `solo`, so this works at runtime. The type is simply decorative — and
nothing type-checks these files (no `deno` in the toolchain; `ship.sh` only
deploys them).

---

## `test-seed/index.ts` — blast radius

**The authorization is correct**, and this is the thing the slice brief asked
about most directly. `:343-346` reads `profiles.is_founder` with the *service*
client after resolving the JWT, and `allowed = !profErr && prof?.is_founder === true`
fails closed on a read error. A non-owner cannot invoke it. Every call logs
caller + verdict. IOS-024 did its job.

**F14 — but `reset` is global, not caller-scoped.** The header at `:12-13` says
"Caller-scoped: only ever seeds the signed-in account". `reset` (`:59-115`)
deletes **every** `@cupseason.test` auth user and every league they commission,
regardless of `me`; the `me` argument narrows only the "The Grudge" lookup at
`:85`. So `{action:"reset", target_email:"reviewer@…"}` — the documented App
Review flow at `:348-351` — also destroys the founder's own test world.

**F13 — every insert result is dereferenced unchecked.** `:163-165`, `:177`,
`:184`, `:190`, `:198`, `:281`, `:289`, `:302`. League codes are hardcoded
constants (`TSTRDG`…), and `reset` finds leagues only via bot `commissioner_id`
— so a league whose bot rows were partially cleaned is invisible to teardown,
its code survives, and the next seed dies at `const leagueId = lg.id` with
`Cannot read properties of null` **after** creating eight auth users.

**F12 — a guard that is always true.** `:292`
`if (tRed.captain_player_id === undefined)`. `tRed` came from
`.select("id").single()`, so it carries only `id`; the property is undefined on
every run. The Blue team on the next line does the same update unconditionally,
which is what this line amounts to.

Minor, noted not filed: `listUsers` pages to 4,000 users (`:65`) with no
warning past that; `sundayOffsetWeeks` uses the Deno runtime's UTC-local `Date`
so seeded dates can land a day off Phoenix — self-consistent, and `:38`
acknowledges it.

---

## Cross-cutting: grants (verified live)

`scan_usage`, `courses_usage`, `push_nudges`, `device_tokens`, `email_queue`,
`cancellation_notices` all carry `authenticated=arwdDxtm` in `relacl`, with
`relrowsecurity = true` and **zero policies**. RLS denies today, so nothing is
exposed — I want to be precise about that. But this is the same two-layers-
one-working shape CLAUDE.md records from the 2026-07-27 audit; the D37 sweep
(`20260727220000`) removed *anon*'s relation privileges, not *authenticated*'s.
The concrete risk is future-tense and specific: add one `select` policy to
`scan_usage` for a "your scan history" screen and `DELETE` arrives with it —
a golfer clearing their own cap counter. `TRUNCATE` (the `D`) is never
governed by RLS at any point. (F8)

---

## Coverage

All 1,765 lines read. Not assessed: I could not execute any function, so every
failure scenario above is reasoned from the code plus verified schema, not
observed. I did not attempt to induce a `courses_usage` / `scan_usage` write
failure (F3, F6 rest on that), and I could not test GolfCourseAPI's detail
payload shape (F1's trigger is the same upstream drift the file already
survived once on a different endpoint, not a shape I observed). Secrets: I
read every `Deno.env.get` site and traced each — no secret reaches a response
or a log in any of the six functions; the one masking rule (`x-push-secret` in
`pg_get_triggerdef`) I applied to my own verification query.
