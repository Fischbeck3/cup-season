# C0 · Week-loop contract review

**2026-09-12 · Claude Code (C0) · branch `claude/next-loop-contract` · base `205a0ef` · status: Proposed.**
Independent review of the expansion draft (`spec/product-vision-v1.0.md`), the build plan (`docs/planning/2026-09-12-next-chapter.md`) and the queue (`docs/planning/ACTIVE_WORK.md`), checked against the source at `205a0ef`.

**How to read this.** This is a static review. I read files only. I did not run tests, a database, the simulator, a browser or anything against production. Every statement is marked:

- **OBSERVED** means read in source at the cited file and line. Behaviour described as OBSERVED is what the code says. It has not been exercised at runtime unless the text says so.
- **REPORTED** means stated by an earlier review or decision entry, and not re-verified here.
- **PROPOSAL** means a recommendation. It changes nothing until the right owner accepts it.
- **DECISION OWED** means an owner ruling is needed before anyone builds it.

The tests in §5 are proposals and have not been executed. This review does not reopen D345's approved participation, window, cap or suppression rulings. It only covers how clients and contracts consume them. No real account names or data appear here. Identities and courses are placeholders.

---

## 0 · Ranked findings

| # | Sev | Finding | Where (OBSERVED) | Section |
|---|---|---|---|---|
| F1 | **High** | **The "Add my round" door opens a composer dated today, for a round played 1–3 days ago.** A post left on today's date lands in the wrong week, month or season window. It also fails D345's same-day suppression, so the golfer gets asked again about a round they just posted: the "duplicate ask" D345 chose to avoid. The audited candidate clients already send `p_today`, so pushing D345 turns this door on for them. | migration `20261024090000…sql:752-753`, `:720`; `PostRoundModel.swift:57`; `index.html:20936`, `:10081`; `HomeStream.swift:147`; `index.html:16806` | §2.8, §3.3 |
| F2 | **High** | **Native draft restore looks unreachable, and seeding overwrites a draft.** `init` sets `card.date`, and `isBlank` requires `date == nil`, so `restoreDraft` returns before restoring. Separately, a kept live scorecard is seeded *after* restore and replaces the card in memory and then on disk. No test drives the model. Confirm with a test before building any resume/replace choice on top of it. | `PostRoundModel.swift:57`, `:254`; `PostCard.swift:91-93`; `PostRoundScreen.swift:50-60`; `PostRoundModel.swift:67-72`, `:226-235` | §3.1 |
| F3 | **High (latent)** | **Removing the bare-course filter as-is turns a hidden course into a failed plan.** `scheduled_rounds.course_id` is a foreign key to `api_courses(id)`, and `declare_round` inserts the id unchecked. Bare remote hits past the three-fetch cap have no `api_courses` row. | `20260718192400_round_object.sql:16`; `20261023090000…sql:114-116`; `courses/index.ts:216-219` | §4.4 |
| F4 | **Med-High** | **A new plan-id argument on `post_round` would trip both clients' missing-function fallback into a direct `rounds` insert** on a server that lacks the argument. PostgREST reports an unknown argument as PGRST202, the same code as a missing function. | `PostService.swift:153-155`, `:184-190`; `index.html:10124-10129` | §3.4 |
| F5 | **Medium** | **`answer_plan_followup` returns `void`.** A stale "Later" that the terminal guard ignores looks identical to one that was accepted. "Plan gone" and "no longer tagged" arrive only as P0001 message text. Clients would have to sniff messages, which the repo's own landmines warn against. | migration `:59-85`, `:84` | §2.4, §2.10 |
| F6 | **Medium** | **Answers are per plan, but the one-per-day cap is applied after them.** Answering Later or Didn't play on the earliest-tee plan immediately shows a second plan from the same day. Nothing tests this. | migration `:701`, `:713-716`, `:723`; `tests/after-golf-postgres.py:94-96` | §2.8 |
| F7 | **Medium** | **"Later" is day-granular and bounded by the window.** Later at 23:30 comes back after midnight. Later on the third eligible day never comes back. Clients must not promise "tomorrow". | migration `:81`, `:708`, `:716` | §2.5 |
| F8 | **Medium** | **Two different "ratings" sit side by side and are not distinguished.** The course page shows the golfers' star average ("4.6 · Cup Season · N ratings", "Not rated · the first rating sets the number") directly above the USGA Course Rating ("72.5 RTG"). The RPC `course_rating` returns stars, while the column `api_course_tees.course_rating` holds the USGA figure. "Sets the number" reuses Home's word for the handicap. | `CourseScreen.swift:143-148`, `:575-582`, `:601-603`; `Course.swift:404`, `:425`; `index.html:14122`, `:14169`; `CoursePage.swift:421-422` | §1.1 |
| F9 | **Medium** | **Ordinary composer posts are not idempotent on either client.** They go through `post_round`; the web keeps a direct insert as fallback. Only kept phone scorecards use `post_round_once`. The Wave 1 gate asks for "post retry … no duplicate scored round". | `PostRoundModel.swift:326-328`; `index.html:10112-10141`; `20261021090000…sql:18-73` | §3.1, §5 |
| F10 | **Medium** | **The web search is stricter than Swift.** It also drops tees that lack rating or slope. The web draft key is shared across accounts on a device. The web leaves the last posted date in the date field, so a prefilled past date would leak into the next post. | `index.html:10745-10747`, `:9904`, `:10219-10231` | §3.1, §4.3 |
| F11 | **Medium** | **The Edge cache writer is not transactional.** It deletes tees, then inserts them, with the upsert error unchecked. A bare course selected again re-hits the upstream API and counts against the daily cap every time. | `courses/index.ts:95-108`, `:125`, `:253-282`, `:175` | §4.1 |
| F12 | Low | **The afterplan headline repeats the day already in its eyebrow**, which is L-34's exact complaint about the COMING band. D345's "today belongs to the live bridge" only holds for hosts on native, because `todaysPlan` filters `mine != false`. That is a caveat on the reasoning, not a request to reopen the ruling. | migration `:741-746`, cf. `:658-663`; `LiveRepository.swift:399-403` | §1.3 |
| F13 | Low | **`contract.psv` has no `home_dispatch` or `answer_plan_followup`**, and still lists two stale `declare_round` overloads. | `packages/db/contract.psv:124-125` | §2.7 |
| F14 | Low | **The actual-RPC harness runs on a stub schema.** Its `my_schedule` has no `course_id`, and `rounds` has four columns. That is honest about its limits, but it does not prove the function against production-shaped data. | `tests/fixtures/after-golf-db.sql:10-25`; harness docstring `:2-5` | §5 |

---

## 1 · Vision and brand: conflicts, duplicates, naming

### 1.1 Social rating vs numeric Course Rating: not clearly named (F8)

**OBSERVED, native course page.** `CourseScreen.swift:143-148` draws `CSRating` first (D322), then `facts(book)`, which comes from `vm.facts(tee)` at `:575-582`.

- The star block shows the figure `CSRating.format(value)` (one decimal, `Course.swift:442`) with the label `"Cup Season · N ratings"` (`:404`). It also shows `"Your rating · 4.5"` or `"Not yours yet"` (`:413`), the empty line `"Not rated · the first rating sets the number"` (`:425`), and the door `"Rate it"` or `"Say something about it"` (`:435`).
- The facts line directly underneath reads `72 par · 7,068 yds · 72.5 rtg · 130 slope`; VoiceOver reads the abbreviation, `"72.5 rtg"` (`:601-603`).
- The rating sheet's eyebrow is `"Your rating"` (`RateCourseSheet.swift:67`), and its comparison figures are labelled `"Cup Season"` and `"Your buddies"` (`:195`, `:200`). The failure copy is `"Your rating is as it was"` (`CourseScreen.swift:270`).

**OBSERVED, web.** A course row puts a star rail beside `Rate it` (`index.html:14166-14169`), and its facts line carries `[course_rating,'rtg']` (`:14122`, `:14211`). The course picker prints `Rating 71.2 · Slope 128` (`:10704`). The composer asks for "rating and slope".

**OBSERVED, data layer.** `CourseRatingCall.name = "course_rating"` returns stars (`CoursePage.swift:421-422`). `api_course_tees.course_rating` is the USGA value (`courses/index.ts:115`), and it is what fills `card.rating` (`PostCard.swift:175`). Swift uses `CourseRating` for stars and `CourseTee.course_rating` for USGA. `docs/ux-overhaul-2026-09-04/TERMINOLOGY.md` has no entry for "rating" or "slope" at all.

**Why it matters.** Two one-decimal ink figures, both called "rating", sit within one screen of each other. The empty state says a star "sets the number", while Home uses "number" for the golfer's handicap (migration `:815`, "Your number is yours…"). The plan correctly says there is already a feature (next-chapter `:18`, `:45`). What is missing is a name.

**PROPOSAL (UI/copy, Codex builds, owner approves wording):**

1. Add a terminology row: *Course Rating* (USGA, with Slope) is always spelled out on reading surfaces. The golfers' opinion is *stars*, or a phrase such as "what golfers think". It is never a bare "rating".
2. Change the facts line to spoken and visible "Course rating 72.5 · Slope 130", or keep `RTG` visually but give VoiceOver the full words.
3. Change the empty star line to something like "No stars yet". Drop "sets the number".
4. Do not rename deployed RPCs. Record the `course_rating` naming collision in the contract notes so nobody treats it as the USGA figure.

This amends D275's copy (`decision-log.md:6588`), so it needs a UI decision entry.

### 1.2 Duplicates and boundary tensions

- **Course opinions are not new work.** OBSERVED: `course_ratings` plus `rate_course`/`unrate_course`/`my_course_ratings` are live (REPORTED in `spec/inbox.md:113-122`; code at `CoursePage.swift:417-516`). Any "course reviews" task in Wave 2/3 is a naming and reachability task.
- **CONFLICT to name, not resolve.** The vision boundary rules out a "public course-review marketplace" (`product-vision-v1.0.md:245`). D275 displays a community mean from all Cup Season golfers, `"Cup Season · N ratings"` (`Course.swift:404`), while notes are limited to your own golfers (`CourseScreen.swift:263-267`). An aggregate of strangers' stars is not a marketplace, but the boundary sentence should say that the aggregate exists and where it stops. DECISION OWED (owner): keep the community mean or show only your golfers'.
- **Record and career are not new work.** OBSERVED: `apps/ios/CupSeason/You/RecordPage.swift` exists, as the plan says. No finding.
- **Brand line.** OBSERVED: the canon promise is "Cup Season is where amateur golf counts" (`spec/brand-canon.md:22`). The built native line is `ANY TIME.\nANYWHERE.` (`CSDesign/Brand.swift:72`, D339). The draft's hierarchy (next-chapter `:100`) fits both. No conflict, but D339's two open questions stay open.
- **Inbox is stale against the D345 correction.** `spec/inbox.md:328` still asks Codex to delete `HomeDispatch.localHeadline`. The D345 release correction keeps it (`decision-log.md:7399`). The inbox line should be reconciled by its owner, Codex.

### 1.3 Copy details inside the new band (F12)

OBSERVED: the afterplan eyebrow is `SAT · <COURSE>` (migration `:741-743`), and the headline repeats the day: "You planned a round for Saturday." / "…for yesterday." (`:744-746`). The COMING band avoids exactly this repeat and explains why (`:658-663`). PROPOSAL: headline "You planned this one." or "<Host> had you on this one." and leave the day to the eyebrow. This is wording only; D345's rule that the copy asserts no attendance is preserved.

---

## 2 · D345 contract packet

### 2.1 Deployment state

- REPORTED (`decision-log.md:7401`; `docs/reviews/2026-09-12-d345-handoff-inspection.md:78`): D343 and D344 are applied, and D345 `20261024090000` is **not** applied. Production exposes the one-argument `home_dispatch(integer)`. I did not verify this.
- OBSERVED: the migration at `205a0ef` already contains the release corrections: `j jsonb := e` (`:727`), band gated on `p_today is not null` (`:707`), non-asserting copy (`:744-746`), terminal guard (`:84`), upcoming refresh (`:145-158`).
- OBSERVED: both candidate clients send `p_today`: native `HomeStream.swift:142-151`, web `index.html:16806`. **Pushing D345 activates the after-golf band on those builds.** See F1 before doing that.

### 2.2 `home_dispatch` request

```
POST /rest/v1/rpc/home_dispatch
{ "p_days": 21, "p_today": "2026-09-14" }      // device-local calendar day, YYYY-MM-DD
```

- Signature after the migration: `home_dispatch(p_days integer default 21, p_today date default null)`, created by drop and recreate (`:98-100`), with grants re-issued (`:891-892`) and a uniqueness self-check (`:898-901`). OBSERVED.
- The server day is `v_today := cs_local_day(p_today)`, which clamps to `current_date ± 1` (`:26-30`, `:112`). OBSERVED.
- If `p_today` is null, the upcoming read and the whole window stay on the server day, and **no afterplan items** are produced (`:707`). OBSERVED.
- Client day source: native `CSDate.today()` (`HomeStream.swift:147`); web `isoAgo(0)`, built from local `getFullYear/getMonth/getDate` (`index.html:5551-5554`), which is landmine-safe. OBSERVED.

### 2.3 `home_dispatch` response: the afterplan item

OBSERVED shape (`:732-757`), with placeholder values:

```json
{
  "key": "afterplan:00000000-0000-4000-8000-00000000000a",
  "tier": "changed", "band": 800, "mods": 6, "mod_reason": "M8 6 (a dated thing)",
  "subject": "you", "human_subject": true,
  "eyebrow": "SAT · EXAMPLE LINKS",
  "headline": "Host had you on the plan for Saturday.",
  "standfirst": "Nothing posted yet.",
  "action": "Add my round",
  "route": { "kind": "composer" },
  "league_id": null, "suppress": [], "spine": "ember",
  "at": "2026-09-12",
  "rank": 2, "score": 806, "rank_reason": "B2 800 + 6 (M8 6 (a dated thing)) = 806"
}
```

**What the item does not carry.** OBSERVED:

- The plan id exists only inside `key`.
- There is no raw course label (only the uppercased label inside `eyebrow`), no `course_id`, and no `tee_time`.
- The route carries no id.

So a client cannot prefill a course faithfully, and it must string-parse the key to answer. `at` is the plan's `play_on`.

**Eligibility.** OBSERVED, and these are the approved D345 rules, not reopened:

- the reader is the host, or tagged (`:709`);
- not RSVP `out` (`:710-712`);
- no `didnt_play` answer and no active snooze (`:713-716`);
- `play_on` between `v_today-3` and `v_today-1` (`:708`);
- no non-voided round by the reader on that day, unless both sides name a course and the courses differ (`:717-722`);
- one item per `play_on`, earliest tee first with nulls last, then `created_at` (`:701`, `:723`).

### 2.4 `answer_plan_followup`: request, response, errors

```
POST /rest/v1/rpc/answer_plan_followup
{ "p_plan": "<plan-uuid>", "p_answer": "later" | "didnt_play", "p_today": "2026-09-14" }
→ 204 / null (returns void)
```

OBSERVED (`:59-87`). Checks run in this order, and each raise uses default SQLSTATE `P0001`, which PostgREST returns as an error body:

| Order | Condition | Message | Client meaning (PROPOSAL) |
|---|---|---|---|
| 1 | `auth.uid()` null (`:68`) | `Sign in first` | Session expired. Keep the card and re-auth. |
| 2 | answer not in set (`:69`) | `That is not an answer` | Programmer error. Keep the card and log it. |
| 3 | plan row absent (`:70-71`) | `That round is not on the schedule` | Scratched, or cascaded away. **Resolve:** drop the card, refetch. |
| 4 | not host and not tagged (`:74-76`) | `Only the people on this round can answer` | Untagged since render. **Resolve:** drop the card, refetch. |
| 5 | `play_on >= cs_local_day(p_today)` (`:77`) | `That round has not happened yet` | Clock skew. Keep the card and refetch. |

**Write effects.** OBSERVED:

- Upsert on the primary key `(scheduled_round_id, profile_id)`.
- `later` sets `snooze_until = v_day + 1`; `didnt_play` sets `snooze_until = null` (`:79-81`).
- The update is skipped when the stored answer is already `didnt_play` (`:84`). The call still returns success.
- Nothing writes `round_rsvp`, `posts` or `rounds`.

Not checked by the function (OBSERVED, harmless): the window's lower bound, and an RSVP of `out`. The read already ignores those plans.

### 2.5 Date contract (F7)

| Case | `p_today` | Effect | Evidence |
|---|---|---|---|
| Phoenix 18:00 on the day of play; server already D+1 | D | Clamp allows D. The plan is "today": no item, and answering raises #5. | `:26-30`, `:77`, `:708` |
| Next morning | D+1 | Item appears. | `:708` |
| Later at 23:30 local on D+1 | D+1 | `snooze_until = D+2`. The item returns at **00:00 local on D+2**, 30 minutes later. | `:81`, `:716` |
| Later on the last eligible day (`play_on = D-3`) | D | Snooze to D+1, but on D+1 the plan is D-4 and outside the window. **Later behaves as dismissal.** | `:708`, `:716` |
| Device clock 1 day ahead | real D+1 | Clamp allows it. A premature "yesterday" prompt on the day of play. | `:28-29` |
| Old client, no day | null | No afterplan items; upcoming on the server day. | `:707`, `:147` |

**PROPOSAL (copy law, both clients).** "Later" never promises when the question returns. The confirmation says only what happened, e.g. "Okay — it's off Home for now." The client never computes the snooze locally. It always re-reads dispatch.

### 2.6 Visibility

OBSERVED:

- `plan_followups` has RLS, and the only policy is `select … using (profile_id = auth.uid())` (`:47-57`). There are no insert or update policies; writes go through the definer RPC only.
- `anon` gets nothing (`:56`, `:86`).
- `cs_local_day` is revoked from `authenticated` (`:31`).
- A tagged golfer's item names the host's first name (`:704`, `:746`). The plan already shares that name with them.

**PROPOSAL, a consumer rule for both clients and later waves:**

- A `didnt_play` answer is never shown to another golfer.
- It never changes a roster, `rsvp_in`, a rivalry, Record facts or a board post.
- The plan sheet will keep showing a golfer who answered "Didn't play" as `in` if they RSVP'd in. That is D345's accepted tradeoff (`decision-log.md:7390`). Wave 2 fact selection must not infer attendance from either table.

### 2.7 Old/new server × client matrix

"New client" means the audited candidate at `205a0ef`, which sends `p_today`. "Controls client" means a future build with Later / Didn't play and prefill.

| | Server without D345 (production, REPORTED) | Server with D345 |
|---|---|---|
| **Old client** (sends only `p_days`) | Unchanged. | `p_today` null → no afterplan; upcoming on server day. **Identical to today.** OBSERVED `:707`. |
| **New client** (`205a0ef`) | First call errors (PGRST202). Native `SupabaseService.call` drops `p_today` on *any* first error and retries (`SupabaseService.swift:149-167`, `HomeStream.swift:144`). Web retries without it on any error (`index.html:16807`). Result: old Home. Asserted by `tests/home-function-browser.js:19-26` (not run here). | Band renders with **"Add my round" → blank composer dated today** (F1). No answer controls. |
| **Controls client** | Same retry, so no afterplan; answer controls never render. If an answer RPC is ever called, it errors PGRST202; show failure and keep the card. | Full behaviour. |

**Retry caveat.** OBSERVED: both retries fire on transient network errors too, so one bad first attempt produces a Home without afterplan items for that load. That is acceptable degradation, since it matches today.

**Generated contract (F13).** OBSERVED: `home_dispatch` is hand-declared on the phone (`HomeStream.swift:131-148`), and `answer_plan_followup` is not in `contract.psv`. The controls client must hand-declare the answer call until the post-push refresh regenerates `Rpc.swift`. Refresh `contract.psv` from the pushed database only (Claude supplies it, Codex generates it). Its stale `declare_round` rows (`:124-125`) should go in the same refresh.

### 2.8 Races and terminal answers

| Race | Server outcome (OBSERVED unless marked) | Required client behaviour (PROPOSAL) |
|---|---|---|
| Didn't play on phone, then a stale Later from web | `didnt_play` kept (`:84`); Later returns success with no effect. | Web hides the card on success, then refetches; the card stays gone. Correct end state, but see §2.10 for telling the two apart. |
| Later and Didn't play from two devices at once | Primary-key upsert serialises the rows. Later-then-DP ends DP. DP-then-Later ends DP. **DP is terminal either way.** | Refetch after either write. |
| Double-tap Later | Idempotent upsert. | Disable the controls while the write is in flight. |
| Host scratches the plan while the guest views the card | Plan hard-deleted (`20260712150000…sql:78-84`); followups cascade (`:39`); answer raises #3. | Treat #3 as resolved: drop the card and refetch. No failure toast. |
| Host retags and removes the guest | Answer raises #4; dispatch no longer lists the item (`:709`). | Same as scratch. |
| Answer fails (offline or 5xx) | No row written. | **Keep the card**, show a failure, allow retry. No offline queue for answers. |
| Golfer taps "Add my round", posts on the plan's date | Round suppresses the item if either course id is null or they match (`:717-722`). | Refetch dispatch after an accepted post. Native `store.reload()` (`PostRoundModel.swift:405`); web `refreshHomeLead()` (`index.html:10238`). |
| **Golfer posts with today's date (F1)** | `rd.played_on ≠ sr.play_on`, so **the item survives**. The round scores against today's week, month and season window (`post_round` derives the season from the date, `20260910090000…sql:17-19`, `:237`). | **Prefill the plan date** (§3.3). Do not ship the band to a client that cannot. |
| Posts on the plan day at a different catalogue course, when the plan names one | The item survives, by design (`:722`). | None. This is D345's heuristic. |
| Later or DP on the earliest plan when a second plan shares the day (F6) | Followup exclusion runs before `distinct on (play_on)`, so **the second plan's card appears immediately** (`:701`, `:713-716`). | DECISION OWED (§7). The fix consistent with D345's "a missed prompt over a duplicate ask" is to apply answers per `(golfer, play_on)`: keep `distinct on`, and move the followup predicate onto the whole day. |
| Didn't play, then the golfer actually posts that round | Posting is independent, and works. The prompt was already gone. | None. There is no undo for Didn't play. The ⊕ composer remains the way back. |
| Offline relaunch with a card visible | Dispatch is refetched on launch; a failed read renders fallback items with no afterplan items. | Never synthesise an afterplan item locally or in `HomeFallbackItems`. |

### 2.9 Client obligations: answer controls (PROPOSAL, Codex builds)

1. Controls appear only on items whose key starts with `afterplan:`. Parse the UUID after the prefix, or use `route.id` if §2.10's amendment lands. An unparseable id shows the item with the composer door only.
2. Tapping Later or Didn't play disables both controls, then calls the RPC. **Hide the card only on success** (or on resolved errors #3 and #4), then re-read dispatch.
3. On failure the card stays put and the message comes from one shared producer. Nothing is written to local state.
4. "Didn't play" needs no confirmation dialog (it is reversible by posting), but the button must not be the visually primary action; "Add my round" keeps ember.
5. On phone and web, the answers are layout-level controls on the item, never a new route kind: G1 drops unknown kinds (`HomeDispatch.swift:85-95`; `index.html:16601-16620`).
6. Telemetry, if any, records the door family and the answer only. No plan id, course or names (next-chapter `:104`).

### 2.10 Contract amendments before D345 is pushed (PROPOSAL, backend owner Claude, owner approval)

The migration is unapplied, so these can go into it before its first push. After a push they need a new migration: a return-type change requires drop and recreate plus re-grant.

1. **Return a status, not void:**
   ```json
   { "plan_id": "<uuid>", "answer": "didnt_play", "snooze_until": null,
     "applied": false, "reason": "terminal" }
   ```
   `reason` is one of `null | "terminal" | "not_available"`. Plan absent and not-a-participant both return `applied:false, reason:"not_available"` rather than raising. One reason for both avoids telling a stranger whether a plan id exists. Keep raising for signed-out, bad answer and not-yet.
2. **Carry the plan context on the item, outside the route:**
   `"context": {"plan_id": "<uuid>", "play_on": "YYYY-MM-DD", "course_label": "<raw>", "course_id": "<text|null>"}`, plus `route: {"kind":"composer","id":"<plan-uuid>"}`.
   OBSERVED compatibility: the Swift item decoder reads named keys only and ignores extras (`HomeDispatch.swift:164-189`). `Route.make` ignores `id` for `composer` (`:87`). Web `csItemDoor` ignores `id` for `composer` (`index.html:16605`). The values are ones the participant can already read through `my_schedule`.
3. **Per-day answer semantics** (F6), if the owner rules it.
4. **Headline wording** (§1.3).
5. Add the actual-RPC cases in §5.1 to `tests/after-golf-postgres.py`.

---

## 3 · Draft continuity, `sourceLive` vs `sourcePlan`, prefill, linkage

### 3.1 What the drafts actually do today (OBSERVED)

**Native composer (`PostRoundModel`).**

- One draft per owner in `UserDefaults`, key `cs_post_draft.<uid>` (`:224`). It is written 350 ms after any card change (`:16`, `:226-235`) and flushed on background or disappear (`PostRoundScreen.swift:42-45`). TTL is 24 h unless `sourceLive` is set (`PostCard.swift:440`, `:451`).
- **F2(a): restore looks unreachable.** `init` sets `card.date` to today (`:57`). `isBlank` requires `date == nil` (`PostCard.swift:91-93`). `restoreDraft` returns early `guard card.isBlank` (`:254`) before assigning the draft. Read statically, a fresh composer never restores a typed draft. The first edit then overwrites the stored draft (`:233-234`). No test drives this model: `PostTests.swift:189-201` covers only `PostDraft` encode and decode. **Verify with a model-level test first.** This is inferred from source, not observed at runtime.
- **F2(b): seeding replaces the card.** The screen calls `open()` (which restores) and then `seed(...)` for a kept live scorecard (`PostRoundScreen.swift:50-60`; its comment at `:51-53` says the seed "wins over a restored draft"). `seed` assigns `card` (`:67-72`), which triggers `scheduleDraft`, which overwrites the stored draft. Any unrelated typed draft is lost silently. (Today F2(a) probably masks this, because restore never assigned anything.)
- After a post: `clearAfterPost()` then `day = Date()` (`:383-387`), so the date resets to today.
- Post paths:
  - `seededFrom != nil` uses the frozen `OfflinePost` envelope and `post_round_once` with `request = liveRoundId` (`:299-325`).
  - Otherwise `post_round`, **not idempotent** (`:326-328`; F9).

**Web composer.**

- One global key `cs_post_draft`, the same key for every account on the browser (`index.html:9904`). D332 moved the phone to per-owner keys; the web was not changed (`decision-log.md:7253`).
- Restore happens once at boot after sign-in (`:27791`, `:9924-9943`), not when the composer opens. The date field is set to today at boot (`:20936`).
- **After a post the date field is not reset** (`:10219-10231` clears every other field). A prefilled past date would carry into the next post.
- Posting uses `post_round`, falling back to a direct insert only on missing-function errors (`:10112-10141`). Not idempotent.

### 3.2 `sourceLive` is an identity with side effects; a plan is not

OBSERVED: `seededFrom` / `PostDraft.sourceLive` (`PostCard.swift:446`) is a **local live-scorecard request id**. It controls:

- no draft TTL (`:451`);
- refusing Start over (`PostRoundModel.swift:176-178`);
- photo upload ordering and failure copy (`:293-296`, `:314-317`);
- posting through `OfflinePostDisk` with `post_round_once(p_request_id = lr)` (`:299-325`);
- deleting `LiveDisk` and `OfflineRounds` files on success (`:341-346`);
- "phone scorecard" error copy (`:330-332`).

**Why a plan id must not be put in `sourceLive`.** Each of those effects would be false for a plan:

- A plan has no scorecard to release. Deleting "the phone copy" is meaningless.
- A plan draft would lose its TTL and block Start over.
- The receipt table is keyed `(owner, request_id)` with **no round foreign key**, precisely so that "a deleted round cannot turn a retry into a new one" (`20261021090000…sql:14`, `:43-47`). A golfer who posts against a plan, deletes the wrong round, and posts again under the same plan id would get the **deleted round's stored response** back.
- Four golfers share one plan. An owner-scoped receipt is fine, but the scorecard semantics do not apply.

**PROPOSAL: a separate, inert context field.**

```swift
public struct PlanContext: Codable, Sendable, Equatable {
  public var planId: UUID
  public var playOn: String        // YYYY-MM-DD, as served
  public var courseLabel: String?
  public var courseId: String?     // a hint only; never stamped without a tee pick (see §3.3)
}
// PostDraft gains: public var sourcePlan: PlanContext?   (optional; old builds ignore the key)
```

Rules:

- `sourcePlan` never changes the post path, TTL, Start over or photo handling.
- It is display context: "From your plan · Sat · Example Links".
- It is cleared on Start over and after an accepted post.
- `sourceLive` and `sourcePlan` may not both be set. **`sourceLive` wins**, and the plan is shown only as a hint.
- Web mirrors this as `{..., plan:{id,play_on,course_label,course_id}}` inside its draft JSON.

### 3.3 Smallest safe prefill (PROPOSAL)

**Smallest faithful prefill: the date, plus the course label as text.** Nothing else.

- **Date is the one fact that resolves the loop.** OBSERVED at `:720-722`: a round with the same `played_on` suppresses the prompt whenever either course id is null. A date-correct post with a typed or untyped course closes the item. A wrong date neither closes it nor scores in the right week (F1).
- **The course label is a convenience.** It goes into the field as text, exactly as a course-memory chip does (`PostCard.swift:199-202`, which sets `courseId = nil`). The golfer still picks a tee or types rating and slope. `PostCalc.blocked` already refuses a missing rating (`PostCard.swift:276-280`).
- **Do not stamp `courseId` from the plan.** Without a tee there is no rating or slope. A stamped id with a typed rating would claim catalogue identity for figures the catalogue did not supply. If the plan has a `course_id` and the phone's course book holds that course, the tee stage for that id may *open* (`CourseSearchModel.showTees`), but the id is set only by a tee pick. This matches today's rule (`PostCourseSearchField.swift:56-63`).
- Holes, gross, partners, photo and tee are never prefilled. Tagged golfers are not added as partners: a tag is not attendance (vision `:233`).

**Conflict rules when the composer opens from an afterplan item:**

| Composer state at open | Behaviour |
|---|---|
| Blank. Define `isBlankIgnoringDefaultDate`: all typed fields empty, grid untouched, and date is nil **or** today. | Apply prefill silently. Show the "From your plan" line. |
| Has a typed draft with `sourceLive == nil` | **Keep the draft.** Show a choice: "Keep the round you started" (default, no change) or "Start <Sat>'s round". The second replaces it only after an explicit tap. DECISION OWED: whether the replace needs a second confirmation. |
| Draft or seed has `sourceLive != nil` | **Never replace.** Show "Finish your kept scorecard first" with the plan as a hint. |
| Draft already has the same `sourcePlan.planId` | Resume it. No choice. |
| The plan was scratched after the composer opened | Prefill stays as plain values (a plan scores nothing). Posting succeeds. The line "From your plan" drops on the next dispatch read. |

Preconditions on the same slice:

- Fix F2(a) and F2(b) and test them.
- On web, reset `#inDate` to today after an accepted post, and move the draft key to a per-user key (`cs_post_draft.<uid>`) with a one-time migration of the old key only if it was written for the same user. Because the old key is not user-scoped, the safe version is to drop it.

### 3.4 Durable plan-to-round linkage: options (DECISION OWED)

The vision (`:245`) and plan (next-chapter `:69`) keep this out of UI work. The options:

| Option | Shape | Pros | Cons / hazards |
|---|---|---|---|
| **A · No link** (status quo) | Heuristic suppression only (`:717-722`). | Zero schema; already approved. | A missed prompt when there are two rounds on one day and courses are missing. No stable identity for Wave 2 "you played this plan" facts. |
| **B · `rounds.scheduled_round_id`** | Nullable uuid on `rounds`, written at insert by the post RPC. | One join. Exact suppression. | **§16 says rounds are factual and never mutated.** `on delete set null` on plan scratch *mutates* the round; no FK means a dangling id. Adds a column to a table with column-level grant history (CLAUDE.md seal landmine), so it needs an explicit grant. A new arg on `post_round` hits F4. |
| **C · Link table `plan_rounds`** | `(scheduled_round_id, profile_id, round_id, created_at)`, PK `(scheduled_round_id, profile_id)` or `(round_id)`; cascades from both parents; RLS own-only; written in the same transaction as the post. | Rounds stay untouched. Deleting the plan or the round removes only the link. Visibility is controlled separately from both parents. | One more table. The write must go inside `post_round` / `post_round_once` to be atomic. |
| **D · Extend `plan_followups`** | Add answer `posted` plus `round_id`. | One row per (plan, golfer) holds all three outcomes; the prompt reads one predicate. | Mixes a factual link into a "question answered" table. Its own-only RLS limits later social use to definer functions. Round deletion must clear `posted` (FK `on delete cascade` deletes the whole answer row, which reopens the prompt, arguably correctly). |

**Skew hazard for B/C/D (F4, OBSERVED).**

- Native `postRound` treats any `isMissingFunction` error as permission to take the direct-insert fallback (`PostService.swift:153-155`, `:184-190`).
- The web falls back when the message includes `pgrst202`, `schema cache` or `could not find the function` (`index.html:10124-10129`).
- PostgREST reports a call with an **unknown named argument** as PGRST202 "Could not find the function…".
- So a client that adds `p_plan_id` to `post_round`, talking to a server without it, would insert directly into `rounds`. That is the consequential direct write CLAUDE.md names as a defect, and a post that skips server-side season derivation.

**Safe transports, if linkage is chosen:**

- **(i)** Carry `plan_id` inside `post_round_once`'s `p_payload` jsonb. An old server ignores the unknown key (OBSERVED: `20261021090000…sql:56-61` reads only named fields), so it degrades to no link. Make the ordinary composer use `post_round_once` too, which also closes F9.
- **(ii)** A separate `link_round_to_plan(p_round, p_plan)` RPC after acceptance. It is non-atomic but harmless if it fails.

**Recommendation.** C through transport (i), and only after the owner rules. If Wave 2 needs no "played this plan" fact, stay on A and spend the effort on F9 instead.

**Server validation any linkage must enforce (PROPOSAL):**

- Caller is host or tagged.
- `plan.play_on = round.played_on`. A mismatch refuses the link, **not the post**.
- A missing plan skips the link silently and still posts.
- One link per (plan, golfer).
- Never infer or write another golfer's attendance.
- Never write RSVP.

### 3.5 Draft decision entry (PROPOSED text, for Codex to integrate; not in `decision-log.md`)

> **D3xx · A post can start from a plan, and the plan never becomes the round** · mechanic/persistence level · D332, D345, §16, L-32
> - **Current:** the after-golf door opens a blank composer dated today; D345 suppresses by same-day heuristic.
> - **Recommendation:** an after-golf door carries plan context. A blank composer takes the plan's date and course name as text; a started card is kept unless the golfer explicitly starts the plan's round; a kept phone scorecard is never replaced. Plan context is display only — it does not alter the post path, TTL or identity, and adds no partners.
> - **Linkage (separate ruling):** A no link / C link table via `post_round_once` payload. Rounds are never mutated to record it.
> - **Principle:** real golf, low friction, truth before tone.
> - **Tradeoffs:** a plan-dated round is back-dated by design; the golfer can still change the date. Without linkage, two rounds on one day can still miss a prompt (D345's chosen error).

---

## 4 · Bare-course selection: Swift, web, Edge

### 4.1 Edge function `courses` (OBSERVED)

**`search`** (`index.ts:179-238`):

- Maps upstream hits with `flattenTees`; the upstream search payload now carries counts, so tees come back empty (`:58-63`, `:202`).
- Fills tees from `api_course_tees` for known ids (`:206-215`).
- Detail-fetches **at most 3** still-bare courses per search through `fetchAndStore` (`:216-230`).
- **Returns remaining courses bare on purpose** (`:232-235`).
- Enrichment failures are caught; the search still answers.

**`cache`** (`:240-283`):

- If `api_courses` has the id **and** holes exist, it answers from cache, with a background refresh past 180 days (`:250-277`).
- Otherwise it fetches and stores every time (`:281`). A genuinely tee-less course therefore re-hits the upstream API on every selection.

**`fetchAndStore`** (`:91-133`), hazards (F11):

- It upserts `api_courses` **without checking the error** (`:95-106`).
- It **deletes all tees for the course** (`:108`), then inserts tees one by one, skipping failures (`:109-131`).
- If the detail payload ever arrives without tee arrays, the way the search payload changed (`:58-63`), a 180-day background refresh erases a working card.

**Gates and failures:**

- Signed-in user required (401, `:142-147`).
- Per-user daily cap, default 150, answered with 429 (`:153-162`). Every action, including `cache`, inserts a usage row (`:175`).
- Upstream errors return 502 with a message (`:286-290`).

### 4.2 Swift (OBSERVED)

- **One search producer:** `CourseBookStore.searchCourses` (`:228-242`) merges disk books, the Supabase cache read and the remote Edge search.
- **Two filters drop bare courses:** `ScheduleService.searchCacheResult` `.filter { !$0.tees.isEmpty }` (`:148`) and `searchRemote` (`:160`). Disk books can never be bare either, because `keep` returns early when no tees exist (`CourseBookStore.swift:132`).
- **The bare copy already exists and cannot be reached:** "No rated tees listed — type the rating and slope by hand." in the planner (`DeclareRoundSheet.swift:333-334`), composer (`PostCourseSearchField.swift:52-53`) and live setup (`LiveSetupView.swift:522-523`).
- **Selection differs by surface:**
  - Planner and composer set `courseId` when the *course row* is tapped (`DeclareRoundSheet.swift:326`, `PostCourseSearchField.swift:45`).
  - Live setup sets nothing until a tee is picked (`LiveSetupView.swift:516`).
  - The planner calls `cacheCourse` only on a tee pick (`:343-344`). **Nothing ensures an `api_courses` row for a course picked without a tee.**
- A bare row's subline would read "… · 0 tees" (`ScheduleModels.swift:633`).
- **Swift does not filter tees lacking rating or slope.** A composer tee pick then fills rating `0` (`PostRoundModel.swift:152-153`) and the post is blocked `.noRating`. The web hides such tees instead (§4.3).
- D333 (`decision-log.md:7258-7265`) already refuses live scoring without real pars, and `prepare()` drops unrated tees (`CourseBookStore.swift:187-188`).

### 4.3 Web (OBSERVED, verified independently)

- Every source goes through `shapeCourse`, which **also removes tees whose `course_rating` or `slope_rating` is null** (`index.html:10745-10747`). Then:
  - cache `.filter(c=>c.tees.length)` (`:10766`);
  - saved books (`:10771`);
  - remote (`:10783`).
- So the web drops bare courses **and** courses whose tees are all unrated. Swift drops only bare courses. **The two clients disagree.**
- Bare copy exists and cannot be reached: `showTees` empty branch (`:10703-10705`). Subline "0 tees" (`:10732`).
- Row tap sets `dataset.courseId` (`:10737`). The planner attaches search with no rating fields (`:27041`) and sends `p_course_id` from the dataset (`:27052`). Its fallback retries only on a missing function, and only when name or game is present (`:27070`).
- Offline and failure states: "Course search is down — type …" plus Try again, or the `searchOffline` note (`:10792-10813`). A 429 cap response reads as "search is down" (no distinct state).

### 4.4 The FK hazard (F3, OBSERVED)

- `scheduled_rounds.course_id text references public.api_courses(id) on delete set null` (`20260718192400_round_object.sql:16`).
- `declare_round` inserts `nullif(trim(p_course_id),'')` unchecked (`20261023090000…sql:114-116`).
- `rounds.api_course_id` has **no FK** (`20260714050000_course_cache_reconcile.sql:58`; web comment `index.html:10083-10084`).

So:

- **Posting** a round with a bare catalogue id is safe.
- **Planning** one is safe only if an `api_courses` row exists. Cache-read hits and courses that went through `fetchAndStore` have rows. Remote bare hits past the fetch cap do not, and `declare_round` would fail with 23503.
- Web shows `humanError(e)`. Native shows `HumanError.text(error)` (`DeclareRoundSheet.swift:229`). Either way the plan is not saved.

I did not verify the production constraint; confirm with a read-only catalog query before building.

### 4.5 Readiness states (PROPOSAL, one producer, both clients)

| State | Evidence | Planner | Composer | Live setup | Row label |
|---|---|---|---|---|---|
| `catalogue` | id + name, zero tees | Selectable. The tee stage is skipped; the course is "Planned at <course>". | Selectable as a name. Rating and slope typed. | Listed but **not startable**: "No scorecard yet". | "No rated tees yet" |
| `rated` | ≥1 tee with rating **and** slope, holes absent or partial | Selectable | Tee pick fills rating and slope; pars stay template. | Tee shows **Not ready** (D333). | "N rated tees" |
| `ready` | Rated tee + complete real pars | Selectable | Tee pick + pars | Startable | "N tees" |
| `unrated-tees` | Tees exist, none rated | As `catalogue` | As `catalogue`; don't offer tees that fill 0 | Not startable | "No rated tees yet" |
| `checking` | Selection-time fetch in flight | Choice kept; submit waits on id ensure (≤ a bounded timeout) | Non-blocking | Blocking with a visible state | — |
| `failed` / `offline` / `capped` | Edge 5xx or no signal / 429 | Plan saves **with label only** (`course_id` null) and says so | Typed path | Existing copy | Distinct copy for the cap: "Course lookups are resting for today" |

Readiness is derived from the payload the client already receives: tee count, rating and slope presence. Pars readiness comes from D333's existing checks. No new server field is required for this slice. A shared `CourseReadiness` producer in the Kit, with a web twin, keeps the labels identical.

### 4.6 Selection-time detail fetch (PROPOSAL, Edge change, owner: Claude)

1. **New action `ensure`** (or extend `cache`): `{ action: "ensure", id }` →
   ```json
   { "ok": true, "id": "<id>", "known": true, "tees": 3, "rated_tees": 3, "ready_tees": 2, "from_cache": true }
   ```
   It guarantees an `api_courses` row, even with zero tees, **before** answering. It returns counts only, so the client can relabel without a second read. A course fetched as bare within the last N days is answered from cache: mark `cached_at` and skip the upstream call, so a tee-less course is not re-fetched on every tap. Errors: 401, 429 `{error:"daily course-lookup limit reached"}`, 502 `{error:"golfcourseapi <status>"}`. On 502 the client continues with label only.
2. **Make `fetchAndStore` safe:** check the upsert error; fetch and flatten *before* deleting; never delete existing tees when the fresh payload flattens to zero tees; log every branch. Postgres has no transactions across supabase-js calls, so the replacement must be a security-definer SQL function taking the flattened tees as jsonb, or at minimum a "zero fresh tees → keep old" guard.
3. **Keep the three-fetch cap** (per `2026-09-12-tee-less-course-tree.md` Q5).
4. **Planner submit ordering:** if a catalogue course was chosen and `ensure` has not confirmed, submit with `p_course_id` only once ensure returns `ok`. Otherwise submit label-only and say "Saved without the course link". Alternatively `declare_round` could drop an unknown id server-side (a new migration). DECISION OWED between client ordering and server tolerance. Server tolerance is simpler and removes the race.

### 4.7 Deployment boundaries

| Change | Layer | Deploy | Independent of |
|---|---|---|---|
| Remove the two Swift filters, add readiness labels, skip tee stage in the planner | Native | TestFlight build | Web, DB, Edge. Safe alone **only** with (a) `ensure` or server tolerance, **or** (b) planner submitting label-only for unconfirmed bare hits. |
| Remove the web filters and the stricter tee filter, same labels | Web (`index.html`) | `git push` → Netlify | Same condition as above. |
| `ensure` action + `fetchAndStore` safety | Edge `courses` | `supabase functions deploy courses` (owner-run) | Clients: an old client never calls `ensure`. A new client calling an old function gets `400 unknown action` and must treat it as "label only". |
| `declare_round` tolerates an unknown course id (if chosen) | Database | New migration, `supabase db push` (owner-run) | Clients. `create or replace` with an unchanged signature, grants re-asserted. |
| D345 activation | Database | `supabase db push` of `20261024090000` | **Should wait for a client with date prefill** (F1), or accept F1 for one build. |

A client push does not deploy the Edge function or the database, and the reverse is also true.

---

## 5 · Proposed acceptance cases (not executed)

### 5.1 Actual-RPC SQL cases

Extend `tests/after-golf-postgres.py`, which runs the real migration on a disposable cluster. The fixture should gain production-shaped `my_schedule` (with `course_id`), `rounds.api_course_id` and `scheduled_rounds.course_id` FK columns.

| ID | Setup | Call | Expect |
|---|---|---|---|
| S1 | Host plan D-1, `p_today = D` | `home_dispatch(21, D)` | One `afterplan:<id>` item; `route.kind='composer'`; `at = D-1`; the item has exactly the keys in §2.3 (plus `context` if §2.10.2 is taken). |
| S2 | Same | `home_dispatch(21)` and `home_dispatch(p_days=>21)` and `home_dispatch()` | All resolve to the one function; no afterplan; `pg_proc` count = 1. |
| S3 | Server UTC D+1, plan D, `p_today = D` | dispatch + answer | No item; `answer` raises `has not happened yet`. |
| S4 | Plan D-3; `later` with `p_today = D` | dispatch `D+1` | **No item** (window expired). Documents F7. |
| S5 | Plan D-1; `later` with `p_today = D` | dispatch `D` / `D+1` | Hidden / shown once. |
| S6 | Two plans D-1 (08:00 and 13:00) | `later` on the 08:00 plan; dispatch D | Documents F6: currently the 13:00 card appears. Flip the assertion if the owner rules per-day. |
| S7 | `didnt_play` then `later` | read the row as the owner | `answer = didnt_play`, `snooze_until` null; if §2.10.1 lands, the second call returns `applied:false, reason:"terminal"`. |
| S8 | Concurrent `later` + `didnt_play` in two sessions (two psql processes, `pg_sleep` interleave) | read | Exactly one row; `didnt_play` if it committed at any point. |
| S9 | Plan scratched (`delete`) after render | answer | Raises `not on the schedule` (or `not_available`); `plan_followups` has 0 rows. |
| S10 | Guest untagged by `retag_round` after render | dispatch + answer | No item for the guest; answer raises `Only the people` (or `not_available`). |
| S11 | Guest RSVP `out` | answer `didnt_play` | Writes (inert); dispatch still no item; `round_rsvp` unchanged. |
| S12 | Any answer | — | `round_rsvp`, `rounds`, `posts` row counts unchanged (a before/after checksum). |
| S13 | Host posts round `played_on = D-1`, `api_course_id` null, plan `course_id` set | dispatch D | Suppressed. |
| S14 | Host posts round `played_on = D` (today) for a D-1 plan | dispatch D | **Item remains.** Documents F1's server half. |
| S15 | Role isolation | Guest `select * from plan_followups` | Only the guest's rows; `anon` gets permission denied on the table and both RPCs. |
| S16 | Grants after drop/recreate | `has_function_privilege` | authenticated: both true; anon: both false; `cs_local_day` authenticated false. |
| S17 | `declare_round` with an id absent from `api_courses` | call | Today: 23503 raised (proves F3). After a tolerance fix: plan saved with `course_id` null. |
| S18 | `post_round` called with an extra unknown named arg through PostgREST (staging branch, not linked prod) | HTTP call | Returns PGRST202. Proves F4's premise. |

### 5.2 Edge cases (staging function or local `supabase functions serve`; never prod)

| ID | Case | Expect |
|---|---|---|
| E1 | `search` for a query with >3 bare hits | Response includes bare hits with `tees: []`; ≤3 detail fetches logged. |
| E2 | `ensure` on a bare id not in `api_courses` | Row exists afterwards; `tees: 0`; second `ensure` makes no upstream call. |
| E3 | `ensure` when upstream returns 500 | 502 JSON; no rows deleted. |
| E4 | Background refresh where detail flattens to zero tees | Existing tees and holes **unchanged**. |
| E5 | 151st call in 24 h | 429 with the cap body; client shows the cap copy, not "search is down". |
| E6 | Unsigned or anon JWT | 401. |
| E7 | Old function, new client calls `ensure` | 400 `unknown action`; client proceeds label-only. |

### 5.3 Native (Kit unit + UI tests)

- N1 `PostRoundModel` opened with a stored typed draft → the draft **is restored** (fails today if F2(a) holds).
- N2 A stored typed draft plus a kept live seed → the typed draft is preserved on disk, or an explicit choice is shown; never silently replaced (fails today if F2(b) holds).
- N3 Afterplan open, blank composer → `card.date == play_on`, `card.course == label`, `courseId == nil`, `sourcePlan.planId == id`, `sourceLive == nil`.
- N4 Afterplan open with a typed draft → the draft is unchanged until "Start <day>'s round" is tapped.
- N5 Afterplan open with a `sourceLive` card → never replaced.
- N6 After an accepted post from a plan → the next composer's date is today and `sourcePlan` is nil.
- N7 Later tap: in-flight disables the controls; failure keeps the card and shows the toast; success hides the card and re-reads dispatch.
- N8 Resolved errors #3/#4 → the card drops without a failure toast.
- N9 `DispatchCall` encodes `p_today` as local `YYYY-MM-DD` at 23:30 in `America/Phoenix` and in UTC+13 (inject calendar and clock).
- N10 Item with an unknown extra `context` key and `route.id` on composer → decodes; `Route.composer`.
- N11 Search answer with a bare remote hit (filter removed) → row label "No rated tees yet"; planner skips the tee stage; live setup cannot start.
- N12 Composer post retry after a simulated timeout (response lost, server committed) → one round (requires F9's `post_round_once` path; fails today).

### 5.4 Web (`tests/*-browser.js` style, local server, SW and caches cleared)

- W1 `loadHomeDispatch` old-server retry (exists: `tests/home-function-browser.js:19-26`).
- W2 Afterplan item renders Later / Didn't play; keyboard-operable; the card is hidden only after a mocked RPC success; failure keeps it.
- W3 Door → `#inDate.value === play_on` built from the string (no `new Date('YYYY-MM-DD')`), course label as text, `dataset.courseId` empty.
- W4 Existing restored draft + plan door → the draft is kept; the choice is shown.
- W5 After a successful post → `#inDate` resets to today (fails today, `index.html:10219-10231`).
- W6 Draft written by user A is not restored for user B on the same origin (fails today, `:9904`).
- W7 Search with a bare hit and an unrated-tees hit → both listed with labels; planner submit without a confirmed id sends `p_course_id: null` or waits for ensure.
- W8 Course page: facts line reads "Course rating" in accessible text; star block has no "sets the number".

### 5.5 Integrated (Q1, both clients, staging database with D345 applied, one real device smoke)

- I1 Evening plan for tonight, Phoenix 18:00 → no after-golf card tonight; card next morning on both clients; answer on phone → gone on web after refresh.
- I2 Friday plan, open Monday → card; Later Monday → gone, and **does not return Tuesday** (window). Copy promised nothing.
- I3 Door → post dated to the plan → card disappears on both clients; standings and receipt show the round in the plan's week.
- I4 Door with an unfinished draft → draft survives, choice honoured, no duplicate round after an airplane-mode retry.
- I5 Scratch plan between render and answer → card disappears without an error.
- I6 Offline relaunch with the card previously shown → no locally fabricated card; the answer is refused with a retry path.
- I7 Bare course planned, then posted with typed rating → plan saved with or without id per §4.6 ruling; no 23503 visible.

---

## 6 · Recommended smallest build slice

**S1 · "The after-golf question can be answered and the round lands on the right day."**

1. **Backend (Claude), inside the unapplied migration, if the owner accepts §2.10:**
   - status return (§2.10.1);
   - `context` + `route.id` (§2.10.2);
   - per-day answer semantics if ruled (F6);
   - headline wording (§1.3);
   - SQL cases S1–S16.
   - No new tables beyond D345's, no linkage.
2. **Native (Codex):**
   - fix and test F2(a)/(b) first;
   - answer controls (§2.9);
   - plan prefill with the conflict rules (§3.3) and `PostDraft.sourcePlan`;
   - hand-declared answer call.
3. **Web (Codex, sole editor of `index.html`):**
   - the same controls and prefill;
   - `#inDate` reset after post;
   - per-user draft key.
4. **Gate:** §5.1, N1–N10, W1–W6, I1–I6.
5. **Deploy order:** clients carrying S1 ship → then `db push` D345 (owner-run). Old clients keep today's Home under the D345 null-day rule. Build 815/candidate clients would show the band without prefill if D345 were pushed first (F1), so hold the push until S1 is in the field, or accept that for one build as an explicit owner choice.

**Deliberately not in S1:**

- Bare-course unfiltering (C1: needs F3's ruling and the Edge `ensure` deploy; ship it as its own slice with §4.5–4.7).
- Durable linkage (§3.4).
- Composer idempotency (F9; recommended as the next backend-plus-client slice, because the Wave 1 gate requires "no duplicate scored round").
- Rating naming (§1.1; a UI decision entry and Codex copy pass).

---

## 7 · Decisions owed

1. **F6: answers apply per plan or per `(golfer, day)`.** Recommend per day, consistent with D345's chosen error. This clarifies the D345 cap; it does not reopen it.
2. **§2.10: amend the unapplied migration** (status return, `context`, wording) before its first push. Owner authorisation for a D345 contract change.
3. **§3.3: replacing a started draft** needs one explicit tap or a second confirmation.
4. **§3.4: durable linkage.** A (none) vs C (link table via `post_round_once` payload); and whether the ordinary composer moves to `post_round_once` (F9).
5. **§4.6: an unknown `course_id` on `declare_round`.** Client waits for `ensure` vs server drops unknown ids.
6. **§1.1: star rating and Course Rating vocabulary** (UI decision entry amending D275/D289 copy).
7. **§1.2: community star mean vs the vision's "no public course-review marketplace" boundary.**
8. **§4.7: D345 push timing** relative to a prefill-capable client (F1).

---

## Handoff

```text
Branch: claude/next-loop-contract (base 205a0ef, no upstream)
Goal: C0 independent critique and week-loop contract packet
What changed: this review only
Files changed: docs/reviews/next-loop-contract.md (new)
Verification run: static source/doc reading only; no tests, database, simulator,
  browser, Edge or production access. §5 cases are proposed, not executed.
Database deploy owed: none from this packet. D345 (20261024090000) remains
  unapplied per the D345 release correction; recommend pushing it only after a
  client with date prefill ships (F1).
Edge deploy owed: none from this packet; §4.6 proposes a `courses` change with
  its own `supabase functions deploy courses`.
Client deploy owed: none from this packet.
Open questions / risks: §7 decisions 1–8; F2 must be confirmed by a model test;
  F3 production FK and F4 PGRST202 premise need a read-only/staging check.
Recommended next step: owner rules §7.1–7.3 and §7.8; Claude amends the unapplied
  D345 migration + SQL cases; Codex builds S1 on both clients; bare-course C1
  follows as its own slice with the Edge deploy.
Not committed — Codex imports with attribution at integration.
```
