# Theme 2 — Joining and consent (TOP-2, takeaways 1 + 6)

*Remediation plan from the blind UX audit of 2026-08-29. Every file:line below was re-read against `34d20b6` (== HEAD, branch `native/m0-foundation`) on 2026-08-29. This is a PLAN — no product file, migration, spec or decision-log line has been edited. Decisions are drafted as PROPOSED entries for `spec/decision-log.md` and must be logged (owner: "talk first") before any item that depends on them is built.*

**Audit issues covered:** M-023 (P0), M-024, M-025, M-026, M-028, M-143, M-144, M-133 (P1); M-020, M-027, M-029 (P2); M-163 (P3, harness artifact — one copy line only). Touches M-002/M-003 only where the invite text is concerned; the invite *sheet* (URL as text, Copy) is Theme 1's item and is referenced, not duplicated.

---

## 0. What is actually true in the code today (verified)

| Claim in the audit | Verified at | Note |
|---|---|---|
| The consent sheet renders four rows and nothing else | `index.html:15422–15440` (`covenantGate`) | Renders exactly the RPC payload: BUY-IN, PRESET, FLOOR, FINISH. `structure` arrives and is unused. `$0` leagues skip the sheet entirely (`:15425`). Fails OPEN when the RPC is missing (`return true`). |
| `join_covenant_info` returns name/buyin/preset/floor/finish/structure only | `supabase/migrations/20260722211500_covenant_pulse_pairings.sql:29–42` | `leagues ⋈ league_settings`; no `seasons`, no `league_members`, no `profiles`. Anon + authenticated, revoked from public. Fail-closed null on unknown code. |
| `league_by_code` returns only the name | `20260714040000_join_polish.sql:14–19` | Same file defines `join_league` (`:21–38`): **no phase check** — a pre-lock join succeeds (contradicts D40's "members can only join a locked league"; Theme 1/3 question, noted in §F). |
| Landing copy promises instant membership | `:17914` ("You're invited to X. Enter your email and you're in."), `:17832` (the warm-up rewrite), `:15453–15454` (manual-code branch: "you'll join X the moment your sign-in code lands") | Real path: OTP → golfer card → D82 orientation → covenant. |
| `?join=` is consumed to `localStorage` and the URL is rewritten | `:17815–17818` | `growthEvent('link_opened','join',code)` fires at `:17820` — that node exists and is the top of the funnel already. |
| "Not now" loses the invite | `:17564` removes `cs_code`/`cs_code_name` BEFORE `covenantGate(pend)` at `:17568`; decline = toast only at `:17572` | Home tile then reads "None yet · JOIN OR START" (`:9873–9874`); the Join sheet's `#jCode` (`:15566`) is empty. |
| `boot()`'s signed-in join path skips the covenant | `:17506–17515` | Calls `join_league` with no gate — a returning user tapping a link is put on the pot sheet with zero disclosure. |
| **Not in the audit:** a SECOND covenant-less signed-in path | `:17384–17396` (`#wCodeGo`, the league-less Clubhouse's "I have an invite code" at `:3351–3355`) | Same defect, same fix (T2-05). |
| Cold door is slogan + two buttons | `:2635` (h1), `:2643` / `:2650` (buttons), `:2656` (Terms · Privacy) | The one-breath definition ships only in `<meta name="description">` at `:22`. Wings are `display:none` below 1100px (`:1818–1819`). Owner decision D83 (`spec/decision-log.md:2878–2907`). |
| The seasons row does not exist before lock | `:15183–15196` (client inserts `seasons` at lock) | Any prospectus must read "forming · first tee not set" when there is no season row — a pre-lock join is possible today. |
| iOS mirrors the four rows | `apps/ios/CupSeason/People/JoinLeagueFlow.swift:122–158` (`CovenantSheet`), `Packages/CupSeasonKit/…/People/JoinLeague.swift:55–95` (`Covenant`) | The phone FAILS CLOSED on a missing RPC (`JoinService.covenant`, `JoinLeague.swift:~105`) — stricter than the web; keep that. |
| iOS loses the invite on "Not now" too | `apps/ios/CupSeason/RootView.swift:31` (`JoinIntent.clear()` in `.onAppear`, before the sheet even opens) | And the phone door (`Door/DoorView.swift`) never mentions a pending code at all — no "You're invited" line exists on the phone. |
| The legal page's contact is a personal address | `legal.html:63`, `:75` (`mailto:jerecho@fischbeck3.com`) | The Prize Pool Disclaimer (`:79–82`) is the clearest money statement in the product; the door links only `#terms` and `#privacy` (`:2656`); the You tab links `#pot` (`:13801`). |
| Four names for one code | `:2650` "I have an invite code" · `:2652`/`:3353`/`:15566` "LEAGUE CODE" · `:14127` "Invite code: X" · `:12932` "Invite code X copied" · `:3366` "Code · X" · `:15565` "Got an invite code?" · `:15757` "Got an invite code?" · iOS `JoinLeagueFlow.swift:30` "I HAVE AN INVITE CODE" | D47 (`decision-log.md:1364–1392`) already ruled **one code noun: league code**. |

Two audit recommendations collide with logged decisions and are corrected in this plan:

- **"Cup Season keeps the tab, never the cash"** — D39 (`decision-log.md:1101–1138`) retired every "never" promise about money; canon is present-tense ledger language: *"Cup Season keeps the ledger; the money moves between friends."* The payment note uses that.
- **Show `allowance_pct` on the covenant** — D1/D2 and D8/D48 say the allowance is never shown outside receipts and presets never mention it (the audit's own §5.5 lists the preset cards' "95% hcp" at `:3250` as a violation). The prospectus does NOT return or render the allowance.

---

## (a) DECISIONS NEEDED — drafted as PROPOSED decision-log entries

Numbering: the log ends at **D110** (`decision-log.md:4090`, with a same-day addendum); D109 is a parked ⚑. These are **D111–D113**. Voice matches the last fifteen entries (Current · Problem · Recommendation · Principle · Benefit · Tradeoffs · CONFLICT).

### D111 · The invite is an artifact — the code opens a prospectus, and the covenant is the decision sheet
*(2026-08-29, blind UX audit TOP-2 (M-023/M-024/M-026/M-133/M-020). IA level. Extends setup-QA S3-01 (`spec/setup-qa-findings.md:62`) and D57's anon-window law; builds the "sharpen" line the GTM doc wrote and never logged (`spec/gtm-year1.md:97–99`). PROPOSED — talk first.)*
- **Current:** `join_covenant_info` (anon, `20260722211500:29–42`) returns name · buy-in · preset · floor · finish · structure; `covenantGate` (`index.html:15422–15440`) renders four of them under "THE FINE PRINT, UP FRONT" and "Join — I'm in for $50". `league_by_code` (`20260714040000:14–19`) returns the name only, so the invite door says "You're invited to The Papago Grind" and nothing else. The share text is `You're invited to ${name} on Cup Season` + URL (`:14118`). Nothing before `join_league` names the Pro, the roster, the dates, the bands, the split, or how the $50 is paid.
- **Problem:** the covenant was scoped by S3-01 as a *money disclosure* ("money never surprises anybody"), not as the joiner's *decision surface*. Joiner verdict 3/10 ("I did not know who was in it — not even that Casey ran it"); the skeptic named the sheet as the bail point ("wait, fifty bucks for what?"). Growth is foursome-by-foursome with no paid acquisition (decision-log:722), so the invite must sell itself; today it depends on the friend's nagging. Every fact the joiner lacks is one join away in the database and deliberately not fetched.
- **Recommendation:**
  1. **One RPC, richer, same signature.** `join_covenant_info(p_code)` gains, all nullable for skew: `pro_name`, `pro_marker`, `member_count`, `members` (display name + marker, first 8 by `joined_at`; a profile with `discoverable = 'nobody'` contributes its marker only), `phase`, `starts_on`, `ends_on`, `weeks`, `season_status`, `counting_cap`, `floor_penalty`, `draft_type`, `payout_champ/runnerup/king`, `pot_cents` (= buy-in × roster — D106's *owed* number, never "collected"). **Never** email, handle, index, or the allowance. Fail-closed null on an unknown code, as today. **Signed-out callers get everything except the `members` array** (Pro + count only) — the names land on the signed-in covenant, so a bare link is not a roster reader. (Owner may loosen this: §F Q1.)
  2. **The invite door renders a league card above the email box** when a code is pending (web `safeBoot` pending branch `:17909–17918`; phone `DoorView`): league name · "Casey runs it (THE PRO)" · "5 in" · "Sat Sep 5 → Sat Jan 2 · 17 wks" or "forming · first tee not set" · "2 squads · blind draw" · "$50 buy-in → $250 pot · 60 / 25 / 15" · the Guide's own sentence ("Every round you post, anywhere, scores against your own number.") · "How scoring works →". The status line under it is honest about the path: *"Sign in to join — you'll confirm the $50 before anything's final."*
  3. **The covenant becomes the decision sheet**, same two buttons, in this order: WHO (Pro + roster chips) · WHEN (dates · weeks, or forming) · HOW ("scored against your own number · 5–12 pts a round · best 4 a month count" — the bands table is one tap away) · FLOOR with its consequence ("2 rounds a month · −5 squad pts per round short · first miss forgiven") · FINISH defined in a sentence · STAKE ("$50 → $250 pot · champs 60 / runner-up 25 / points king 15 · you settle with Casey directly — Cup Season keeps the ledger; the money moves between friends") · PRESET tappable → the preset's bylaw summary · D50's parked paragraph ("The Pro rules. Every ruling is a logged entry with a reason…") · "How scoring works →". A `$0` league gets the same sheet without the STAKE row and a plain "Join" (D70 forbids pot *surfaces*, not disclosure).
  4. **The share text carries the offer**: "Casey invited you to The Papago Grind on Cup Season — 5 in · first tee Sat Sep 5 · $50 buy-in. Review and join: <url>" (the sharer's own league, in their own message).
- **Principle served:** product-vision #2 Low Friction ("join a league in under 30 seconds · never need a tutorial" — the tutorial is currently the friend); spec §7 track-never-hold and D106 (the pot is what the roster owes); spec §16 (every points claim on the card taps through to the bands); D57's law (a curated, fail-closed, SECURITY DEFINER window — never an anon table grant, CLAUDE.md D37).
- **Benefit:** the invite is a yes-to-a-thing; "fifty bucks for what?" is answered on the same sheet as the button; the pot's purpose and payee are stated pre-commit, which D106's collection depends on; the Pro's recruiting is done by the artifact (gtm-year1 leading indicator: invite→accept).
- **Tradeoffs:** the code becomes a read credential for the Pro's name, roster size and dates (already the join credential, already leaks the name; names themselves stay behind sign-in by default). One more payload to keep true on two clients. The sheet is longer — mitigated by D112's one-fewer-screen.
- **CONFLICT (named):** none with D83 (the *cold* door is untouched here — see D113). Amends S3-01's scope from disclosure to decision. Restates D39's ledger language in the STAKE row and explicitly withholds the allowance per D2/D48.

### D112 · Consent on every join path; a decline is a state, not a loss; the invitee skips the orientation
*(2026-08-29, TOP-2 (M-025) + defect 2.8. IA/flow level. Two of its three parts restore S3-01 and need no new ruling; the third AMENDS D82. PROPOSED — talk first.)*
- **Current:** three of five signed-in join entrances pass `covenantGate` (`:15459`, `:15575`, `:17568`); two do not — `boot()`'s pending-code path (`:17506–17515`) and the league-less Clubhouse's `#wCodeGo` (`:17384–17396`). `resumeAfterProfile` removes `cs_code` before the sheet (`:17564`, "so a failure can't loop"), so "Not now" leaves a 2.4-s toast, a "None yet" tile and an empty code box. A first-timer arriving by invite sees the D82 orientation (`:13191–13195`) *before* the covenant that the code's own comment calls their teaching (`:17552–17555`).
- **Problem:** a returning user who taps a link is put on a pot sheet with zero disclosure (an S3-01 violation on the highest-value funnel); a declined invite is indistinguishable from a failed one; an invitee sees three teaching screens where one is theirs.
- **Recommendation:** (1) every signed-in `join_league` call is preceded by `covenantGate` — no exceptions, and a grep-able rule (T2-05). (2) The loop guard protects the *attempt*, not the *sheet*: `cs_code` is removed only when the golfer taps Join; "Not now" moves the code to `cs_invite_declined` (code · name · timestamp), which `boot()` never auto-joins from. Home's league tile (`:9873–9874`) and the phone's league-less doors render **"Invited · The Papago Grind · REVIEW"** from it; Review reopens the covenant with the code; the Join sheet pre-fills `#jCode`; "Not interested" (in the sheet) and sign-out clear it. (3) For `viaInvite` (`:17555`) the D82 orientation is skipped: door(card) → email/code → golfer card → covenant → welcome. `cs_oriented` is still set so it never fires later by surprise; You › How it works reopens it.
- **Principle served:** S3-01 (money never surprises anybody — on *every* path); product-vision #2 (one fewer screen for the path most recipients take); D27's spirit (Home never opens on nothing when there is something to say).
- **Benefit:** the "Not now" cohort is recovered instead of lost; the returning-user link path is honest; the invite path is one screen shorter.
- **Tradeoffs:** one more localStorage key on each client; a declined card sits on Home until dismissed (bounded: one card, one league).
- **CONFLICT (named):** **AMENDS D82** ("ONE skippable orientation screen after the golfer card") for invitees only — the covenant + welcome carry the same two teachings for them. No conflict with D83.

### D113 · D83 amendment — the door keeps its splash and gains one sentence
*(2026-08-29, TOP-2 (M-143) + the iOS survey (M-144 "the screens do not say what the game is"). UI level. The audit's validators refuted "the slogan door is a defect" — D83 is an owner decision — and asked for an amendment instead. PROPOSED — owner's call.)*
- **Current:** the signed-out door is the seared wordmark, "Rally your crew. Post real rounds. Take the cup." (`:2635`; phone `ForgeView.swift:161–162`), two buttons and the Terms line. The product's one-breath definition — *"Season-long golf with the people you already play with — points, pot, pressure."* — exists only in the meta description (`:22`); the Guide's opening sentence (`Cup-Season-Guide.md:3–6`) is a second copy of the same idea. On a phone the door explains nothing; the Prize Pool Disclaimer on the legal page explains the product better than the door does.
- **Problem:** D83 delegated the sell to the invite and to "the walkthrough artifacts"; the invite is fixed by D111, but a cold visitor (App Store, a shared recap, word of mouth) still meets a slogan. Five of eight personas said the door "is a slogan, not a mechanism".
- **Recommendation:** ONE sentence under the h1, sourced from the existing meta-description string (never a third paraphrase — D82's "copy must be kept true" rule), plus a quiet **"How it works"** text link that opens a three-row sheet built from the existing `GUIDE.games` (`:13223`), `GUIDE.posting` and the scoring bands (`openScoringHelp`, `:17274`) — no new copy, callable signed-out. No demo, no cards on the door itself, no pricing (D101: "no pricing on the front door"). Phone: the same sentence under `ForgeView`'s slogan and the same link opening `GuideCopy.sheets["games"]` + scoring.
- **Principle served:** #2 (a visitor who wants the mechanism gets it in one tap; one who doesn't loses nothing); #3 Real Golf (no fiction returns — this is the opposite of the demo D83 retired).
- **Benefit:** the door answers "what is this" in one line and "how does it work" in one tap, for the first time on a phone.
- **Tradeoffs:** one line of copy on the most-seen surface; the wings' fiction (D84 debt) is untouched.
- **CONFLICT (named):** amends **D83**'s "the door sells with its own splash, not a fiction" — the splash stays; a sentence is not a fiction. Does not reopen D84.

**Needs NO new decision (restores an existing one):** T2-02 landing copy (S3-01 truth) · T2-05 covenant on every path (S3-01) · T2-08 league-code noun (D47) · T2-09 legal contact (housekeeping; D39 says legal.html stays factual) · T2-16 Guide/GUIDE "whoever opens it joins" (S3-01 truth) · T2-10 door row collapse (UI hygiene under D82/D83).

---

## (b) WORK ITEMS

Effort: S ≤ 2 h · M ≤ 1 day · L multi-day. Deploys are the owner's (`./tools/ship.sh`; `supabase db push` confirmed by typing `push`). Migrations are timestamp-named after the latest (`20260828160000`); the builder picks the real stamp.

### T2-01 · `join_covenant_info` becomes the prospectus — **db-migration / rpc** · M · needs **D111**
- **Files:** new `supabase/migrations/2026083012xxxx_covenant_prospectus.sql` (`create or replace function public.join_covenant_info(p_code text) returns jsonb` — same signature, so `contract.psv:96` and `Rpc.swift:761–769` keep their shape); `packages/db/contract.psv` + `node tools/build-db.mjs` (snapshot refresh — the function's row is unchanged but the snapshot should be re-taken after the push, as `afde4fb` did); `tests/db-checks.sql:34–54` (check 2's list is unchanged — same name).
- **Change:** `language sql stable security definer set search_path = public`. Keep the six existing keys verbatim. Add: `pro_name`, `pro_marker` (from `profiles` via `leagues.commissioner_id`); `member_count` (`count(*) from league_members where league_id = l.id`); `members` (jsonb array of `{name, marker}` — `display_name` + `coalesce(lm.marker, p.marker)`, first 8 by `joined_at`; when `p.discoverable = 'nobody'` emit `{name: null, marker}`; **emit the array only when `auth.uid() is not null`**, else `null`); `phase` (`leagues.phase`); `starts_on`, `ends_on`, `season_status`, `weeks` (`((ends_on - starts_on) + 1) / 7`) from the latest `seasons` row (`order by number desc limit 1`) — all null pre-lock; `counting_cap`, `floor_penalty`, `draft_type`, `payout_champ`, `payout_runnerup`, `payout_king` from `league_settings`; `pot_cents` (`buyin_cents × member_count`). Do NOT emit `handicap_allowance`, `verification`, emails, handles, ids. Unknown code → `null` exactly as today. `revoke all … from public; grant execute … to anon, authenticated;` (D37). Add a `do $$ … raise if not has_function_privilege('anon', …) $$` self-check like `20260828160000`'s tail.
- **dependsOn:** D111.
- **deployNeeds:** db push (then `contract.psv` refresh + `build-db` as a follow-up commit; preflight 11/17 pass either way because the name/signature is unchanged).
- **verification:** `supabase db query --linked "select public.join_covenant_info('THEPTCQ5')"` as the linked role shows the new keys; probed with a real anon client (`sb.rpc('join_covenant_info',{p_code:'THEPTCQ5'})` signed out) returns `members: null` and everything else; an unknown code returns `null`; `tests/db-checks.sql` checks 2, 3, 9, 10 all PASS after the push; `node tests/preflight.mjs` clean.
- **risk:** RLS/grants (D37: definer-only read of `profiles.display_name/marker/discoverable` — fine, definer bypasses column grants; never grant anon a relation). Privacy: names behind sign-in by default (§F Q1). Skew: old clients ignore new keys; new clients render rows only when present. Data: none.

### T2-02 · Landing copy tells the truth — **copy** · S · quick win (restores S3-01)
- **Files:** `index.html:17912–17917` (`safeBoot` pending branch), `:17832` (the warm-up rewrite — and its regex guard at `:17831` must track the new generic line), `:15453–15454` (`#joinGo` signed-out branch).
- **Change:** replace "Enter your email and you're in." / "you'll join X the moment your sign-in code lands" with *"Sign in to join The Papago Grind — you'll review the league and confirm before anything's final."* (generic: *"You're invited. Sign in to review the league before you join."*). Keep `league_by_code` as the pre-email typo check at `:15448–15450`.
- **dependsOn:** none (T2-03 replaces the line's context but not its truth).
- **deployNeeds:** client push.
- **verification:** open `localhost:8791/?join=THEPTCQ5` signed out (SW + caches cleared): `#obStatus` reads the new line; manual code path at the door shows the manual variant; the a11y tree carries the same text.
- **risk:** none.

### T2-03 · The invite door card — **client** · M · needs **D111**, T2-01
- **Files:** `index.html:2643–2656` (door markup — add an empty `<div id="obInvite" class="ob-invite" hidden>` above `#obEmail`), CSS beside `.joinbox` (~`:1790–1830`), `:17813–17835` (`joinParam`: call `join_covenant_info` in addition to `league_by_code`; cache the payload in memory + `cs_code_info` in localStorage for the reload after OTP), `:17909–17918` (`safeBoot` pending branch: render the card from the cached payload, hide `#obJoin` while a code is pending, relabel `#obEmail` "Continue with email to join"), `openScoringHelp` `:17274` (verify `openSheet` renders above `.onboard` signed-out — if not, the sheet needs `z-index` above the door).
- **Change:** render, in this order and only for keys present: eyebrow "YOU'RE INVITED" · league name · "Casey runs it · THE PRO" (marker glyph via `mkr()`) · "5 in" · dates + weeks or "Forming · first tee not set yet" · "2 squads · blind draw" (from `structure`/`draft_type`, `STRUCT_NAMES` exists) · stake line "$50 buy-in → $250 pot · 60 / 25 / 15" (omit for `$0`) · the Guide sentence · `How scoring works →` (`openScoringHelp`). Below it the T2-02 status line. Never render an empty card: if the RPC returns null (unknown code) fall back to today's generic line and show "No league with that code — check with your Pro" (the `:15450` string).
- **dependsOn:** D111, T2-01, T2-02.
- **deployNeeds:** client push (skew-safe: on an old DB the payload lacks the new keys → the card degrades to name + status line).
- **verification:** browser: `/?join=THEPTCQ5` signed out renders the card with Pro, count, "Forming · first tee not set" (the audit leagues are unlocked) and the stake; `/?join=XXXXXXXX` shows the fallback; after OTP + card the same league reaches the covenant with the code carried (no retyping); `document.querySelector('#obJoin').hidden === true` while pending. Persona re-run: §E.
- **risk:** classic↔module boundary — `joinParam` runs in the module block; the card renderer should live beside `openEmailBox` (`:15244`, classic) and be called through `window.*` with an existence guard (CLAUDE.md landmine). Skew as above.

### T2-04 · The covenant becomes the decision sheet — **client** · M · needs **D111**, T2-01
- **Files:** `index.html:15422–15440` (`covenantGate`), `:14341` (`loadBylaws` — not needed; the RPC carries everything), preset summaries (reuse the three `.preset p` strings at `:3244–3256` MINUS the "NN% hcp" fragment — D48 — or write one sentence per preset from spec §8 without the allowance column).
- **Change:** (1) Drop the `$0` early-return: show the sheet whenever `info` is non-null; keep `return true` when `info` is null (skew fail-open, as today; the phone stays fail-closed). (2) Rows in D111 §3 order — WHO (Pro row + up to 8 `{marker name}` chips; "+N more"), WHEN, HOW, FLOOR (consequence from `floor_penalty`: `deduct` → "−5 squad pts per round short · first miss forgiven (bye)", `forfeit`, `none`), FINISH ("Cup Final · the last 4 weeks, scored fresh; the season seeds it" / "Points table crowns it"), STAKE (D39 ledger language; `pot_cents`; split), PRESET (tappable → one-sentence summary, no allowance), then D50's paragraph verbatim from `decision-log.md:1460–1462`, then `How scoring works →`. (3) Buttons unchanged: "Join — I'm in for $50" / "Join" for `$0`, and "Not now". (4) Add "Prize pool →" (`/legal.html#pot`) as a fine link under STAKE (T2-09). (5) Fire `qaEvent('covenant_shown', {code, stake_cents, path})` on open and `covenant_join` / `covenant_decline` on the buttons (T2-12).
- **dependsOn:** D111, T2-01.
- **deployNeeds:** client push.
- **verification:** browser (`?exit`, sign in as `+blind2`): `openJoinSheet()` → `THEPTCQ5` → the sheet shows WHO with Casey + 4 chips, "Forming", FLOOR consequence, STAKE with "$50 → $250" and the ledger sentence; tapping PRESET opens the summary; `How scoring works` opens the bands; on an old DB (simulate by stubbing `sb.rpc` to return the six-key payload) the sheet shows today's four rows plus the generic HOW/FINISH sentences — never an empty row. Persona re-run: §E.
- **risk:** middot encoding in the template (CLAUDE.md: anchor Edits on ASCII lines). Copy drift: HOW/FINISH sentences must be lifted from `openScoringHelp`/`GUIDE.games`, not re-paraphrased.

### T2-05 · Every signed-in join passes the covenant — **client** · S · quick win (restores S3-01; part of D112's rule)
- **Files:** `index.html:17506–17515` (`boot()`), `:17384–17396` (`#wCodeGo`).
- **Change:** in `boot()`: keep `pend`, but do not remove the keys until the gate resolves; `if(!(await covenantGate(pend))) { declineInvite(pend) ; } else { remove keys; join_league; … }` (`declineInvite` is T2-06 — until it lands, decline = today's toast). In `#wCodeGo`: insert `if(!(await covenantGate(code))) return;` before `join_league`, exactly as `:15459`. Add a one-line comment rule above `covenantGate`: "every `join_league` call in this file is preceded by `covenantGate` — grep before adding a sixth entrance."
- **dependsOn:** none.
- **deployNeeds:** client push.
- **verification:** browser: sign in as `+blind3` (already a member — use a fresh `+blind7`), open `/?join=THEPTCQ5` → the covenant appears BEFORE membership changes (`select count(*) from league_members` unchanged until Join); Clubhouse league-less "I have a league code" → covenant → join. `grep -c "rpc('join_league'" index.html` equals `grep -c "covenantGate(" index.html` minus the definition.
- **risk:** none (the gate already fails open on skew).

### T2-06 · The decline persists — Home card, pre-filled code — **client** · M · needs **D112**
- **Files:** `index.html:17557–17575` (`resumeAfterProfile` pending block), `:17506–17515` (`boot()`, with T2-05), `:9871–9877` (`renderHomeTiles` league tile), `:9914–9950` (`renderHomeStart` — optional second surface), `:15564–15568` (`openJoinSheet` — pre-fill `#jCode`), `:18002` (`SIGNED_OUT` — also clear the new key), `covenantGate` (add "Not interested" as a third, quiet action that clears the key).
- **Change:** introduce `cs_invite_declined` = `JSON.stringify({code, name, at})`. Remove `cs_code`/`cs_code_name` only inside the Join branch (before `join_league`, so a failing join still cannot loop). On Not now → write the declined key; toast stays. `renderHomeTiles`: when no league and a declined invite exists → `{ t:'League', v:'Invited', s:NAME.toUpperCase()+' · REVIEW', go: () => window.reviewInvite(code) }` where `reviewInvite` runs the same gate→join→enter→welcome sequence as `openJoinSheet`'s `go`. `openJoinSheet` pre-fills `#jCode` from the key. Clear on join success, on "Not interested", on sign-out. `boot()` must never auto-join from the declined key.
- **dependsOn:** D112, T2-05.
- **deployNeeds:** client push.
- **verification:** browser: fresh account via `/?join=THEPTCQ5` → Not now → Home tile reads "Invited · THE PAPAGO GRIND · REVIEW"; tap → covenant → Join → in the league, tile gone; reload before joining keeps the card; sign out clears it; `openJoinSheet()` shows `THEPTCQ5` pre-filled. Telemetry: `invite_resume` fires on the tile tap (T2-12).
- **risk:** the D94 tile row is classic; `covenantGate` is module — bridge `reviewInvite` via `window.*` with an existence guard.

### T2-07 · The invitee skips the orientation — **client** · S · needs **D112** (amends D82)
- **Files:** `index.html:13190–13195` (card-save handler), `:13204–13207` (`showOrientation`).
- **Change:** `const viaInvite = !!(localStorage.getItem('cs_code') || localStorage.getItem('cs_claim'));` before the `oriented` check; `if(!oriented && !viaInvite) showOrientation(); else { if(!oriented) localStorage.setItem('cs_oriented','1'); await resumeAfterProfile(); }`. Comment cites D112.
- **dependsOn:** D112.
- **deployNeeds:** client push.
- **verification:** browser: invite path lands on the covenant directly after "Save my card"; a direct (no-code) signup still sees the orientation; You › How it works reopens it for both.
- **risk:** none.

### T2-08 · One code noun: league code — **copy** · S · quick win (restores D47)
- **Files:** `index.html:2650` ("I have an invite code" → "I have a league code"), `:3351` (same), `:15565` ("Got an invite code?" → "Got a league code?"), `:15757` (same), `:14127` (`toast('League code ' + code + ' — text it to the group')`), `:12932` (`Invite code ${code} copied` → `League code ${code} copied`), `:3366` (`Code ·` → `League code ·`), `:2652`/`:3353`/`:15566` placeholders already read "LEAGUE CODE" — keep. iOS: `JoinLeagueFlow.swift:30` sub "I HAVE AN INVITE CODE" → "I HAVE A LEAGUE CODE"; `CSField("League code")` already right.
- **Change:** literal replacements; "invite link" stays only where a link is actually produced (`shareInvite`, the welcome's "Share the invite link").
- **dependsOn:** none. (Theme 1's invite sheet owns the "link as text" fallback at `:14127`; this item only fixes the noun in the fallback toast.)
- **deployNeeds:** client push + iOS build.
- **verification:** `grep -n -i "invite code" index.html apps/ios -r` returns zero user-facing hits (comments excepted); screenshots of door, hub chip, join sheet.
- **risk:** none.

### T2-09 · Legal page: real support address, prize-pool link from the money rows — **copy** · S · quick win (owner confirms the mailbox)
- **Files:** `legal.html:63`, `:75` (`mailto:`), `index.html:2656` (door Terms line → "Terms · Privacy · Prize pool"), `covenantGate` STAKE row (T2-04) → "Prize pool →" link, iOS `DoorView.swift:182–190` (`legal` — add the third `Link` to `CSConfig.legal("pot")`).
- **Change:** replace the personal address with `hello@cupseason.app` (exists in the share-copy audit as the intended address, `spec/share-copy-audit-2026-07-27.md:2290`; **the mailbox/forward must exist first** — §F Q3). Add the `#pot` link where money is first mentioned (door Terms line, covenant STAKE row). Also M-163's one line: under the door's "No code yet?" caption add "Still nothing after two resends? Email hello@cupseason.app."
- **dependsOn:** owner confirms the mailbox.
- **deployNeeds:** client push (legal.html is already in the dist allowlist, `stamp-version.sh:38`) + iOS build.
- **verification:** send a test mail to the address; `curl -s https://cupseason.app/legal.html | grep -c fischbeck3` = 0 after deploy.
- **risk:** none. (D39: legal.html's money statements stay present-tense fact — untouched.)

### T2-10 · The door stops stacking rows — **client** · S · quick win (M-028)
- **Files:** `index.html:15244–15258` (`openEmailBox`, `#obEmail` handler), `:15402–15408` (`#obJoin` handler), CSS for `.onboard` (~`:1790–1830`), `:2643–2653` (markup).
- **Change:** when any branch opens, add `.branch-open` on `#obDoor` and hide the two chooser buttons (`#obEmail`, `#obJoin`) with a quiet "← Back" text link that resets; after Go, collapse the email row to one line "Sent to jerecho+…@… · Change"; keep `#obStatus` + `#obResend` directly under `#codebox` so the status is above the fold at 390×844; when a code is pending, `#obJoin` is hidden regardless (T2-03).
- **dependsOn:** none.
- **deployNeeds:** client push.
- **verification:** browser at 390×844 (`?exit`): after Go, `#obStatus.getBoundingClientRect().top < 700`; only one input row visible at a time; Back restores the two doors. Screens `join/05-E-after-go.jpg` and `skep/03-join-link.jpg` re-taken.
- **risk:** the `#obStatus`/`#obResend` re-parenting in `openEmailBox` — keep the element order it establishes.

### T2-11 · D83 amendment: one sentence and a How-it-works link on the door — **client / ios** · S · needs **D113**
- **Files:** `index.html:2635` (h1) — add `<p class="ob-one">` after it, text = the meta-description sentence at `:22`; `:2656` Terms line — prepend a `How it works` link; new `openDoorGuide()` in the classic block composing `GUIDE.games[2]` (`:13223`), `GUIDE.posting[2]` and the bands card from `openScoringHelp` (`:17274–17296`) into one sheet (verify `openSheet` renders over `.onboard`). iOS: `ForgeView.swift:160–163` (the sentence under the slogan), `DoorView.swift` legal row (the link) opening `GuideCopy.sheets["games"]` + the scoring sheet (`JoinScoringHelpSheet`, `JoinLeagueFlow.swift:~212`).
- **Change:** one sentence, one link, no cards on the door, no pricing (D101), no demo (D83).
- **dependsOn:** D113.
- **deployNeeds:** client push + iOS build.
- **verification:** `skep/02-cold-door.jpg` and `ios/01-door.jpg` re-taken: the sentence is under the slogan; the link opens the sheet signed out; iOS survey question "does the door say what the game is" re-asked.
- **risk:** none; copy sourced from existing strings only.

### T2-12 · Measure the funnel: `league_joined` node + covenant breadcrumbs — **telemetry / db-migration** · S
- **Files:** new `supabase/migrations/2026083012xxxx_growth_league_joined.sql` — `alter table growth_events drop constraint growth_events_node_check` (name per `\d`; re-add with `league_joined` in the list), `create or replace function public.log_growth_event(...)` with `league_joined` in BOTH `in (...)` lists (`20260828160000:~70` and `~74`) but never allowed signed-out, `create or replace function public.join_league(p_code)` (from `20260714040000:21–38`, unchanged logic) inserting `growth_events(node='league_joined', kind='join', token=upper(p_code), league_id, actor)` directly on a genuine join (server-decided fact, like `first_round_posted`), `create or replace view v_growth_funnel` with a `joined` column; re-grant `join_league` to authenticated, revoke from public/anon; re-grant `log_growth_event` to anon, authenticated. Client: `qaEvent('covenant_shown'|'covenant_join'|'covenant_decline'|'invite_resume', {...})` at the T2-04/T2-06 points (`client_events`, authenticated only — no PII in props; code is not PII). iOS: `CSTelemetry.event("covenant_shown", …)` etc. (`Telemetry.swift:41`).
- **Change:** as above. `growth_events` keeps zero relation privileges; the insert runs inside the definer.
- **dependsOn:** none (ships independently; T2-04/T2-06 emit the client events when they land).
- **deployNeeds:** db push + client push + iOS build.
- **verification:** `tests/db-checks.sql` check 2 (anon surface unchanged) and 3 (`join_league` still granted) PASS; `select node, count(*) from growth_events group by 1` shows `league_joined` after a test join; `select * from v_growth_funnel where kind='join'` has `opened ≥ joined`.
- **risk:** D37 — the re-created `join_league` MUST carry its explicit grant/revoke (CLAUDE.md: "a new RPC that silently 403s in prod is almost always a missing grant"). Skew: the client never calls the new node directly.

### T2-13 · The share text carries the offer — **client / ios** · S · needs **D111**
- **Files:** `index.html:14114–14128` (`shareInvite`), `JoinLeagueFlow.swift:~185–192` (`ShareLink` message).
- **Change:** build the text from in-memory state (`CS.league`, `loadBylaws`, `state.seasonStart`): "Casey invited you to The Papago Grind on Cup Season — 5 in · first tee Sat Sep 5 · $50 buy-in. Review and join: <url>" (omit any fragment whose fact is missing; `$0` → "bragging rights"). The sharer's own name comes from `CS.profile.display_name` (it is their message).
- **dependsOn:** D111. (The URL-as-text fallback is Theme 1's invite sheet.)
- **deployNeeds:** client push + iOS build.
- **verification:** with `navigator.share` stubbed, the shared `text` contains the four facts; the group-text preview reads as an offer.
- **risk:** none.

### T2-14 · iOS parity for D111/D112 — **ios** · L · needs **D111**, **D112**, T2-01
- **Files:** `Packages/CupSeasonKit/…/People/JoinLeague.swift:55–95` (`Covenant` — add the optional fields; keep the fail-closed `covenant()` at `~105`, but return a covenant for `$0` leagues too when the payload is non-null), `JoinLeagueFlow.swift:122–158` (`CovenantSheet` — D111 §3 rows, the `byrow` helper exists; preset row → a summary sheet; D50 paragraph; scoring link → `JoinScoringHelpSheet`), `RootView.swift:31` (**do not** `JoinIntent.clear()` in `.onAppear` — `JoinModel.join()` already clears on success at `JoinLeagueFlow.swift:107`; add `JoinIntent.decline()` writing a declined key), `Door/DoorView.swift` (new invite card above the email stage when `JoinIntent.pending()` — the phone door currently says nothing about a pending code; use `Rpc.join_covenant_info` signed-out via `SupabaseService`), `Wizard/LeaguelessDoors.swift:13–45` (a fourth door "Invited · <name> · Review" from the declined key → `JoinLeagueFlow(code:)`), `CupSeasonApp.swift:30` (unchanged — `link_opened` already logs), `WizardState.swift:423` copy, `Generated/Rpc.swift` (regenerates via `node tools/build-db.mjs` after the `contract.psv` refresh; no hand edits), `Tests/CupSeasonKitTests/PeopleScheduleTests.swift` (Covenant decoding of the new payload; nil-tolerant).
- **Change:** as listed; the phone has no D82 orientation screen (only `CardGateView` → `.ready`), so D112 §3 needs nothing there.
- **dependsOn:** D111, D112, T2-01, T2-08.
- **deployNeeds:** iOS build (TestFlight); native work runs LOCALLY (CLAUDE.md rule 6 / D98 Phase B).
- **verification:** `xcodebuild test` on `CupSeasonKitTests` (Covenant decodes six-key and full payloads); simulator via the dev hatch (memory: sim-dev-hatch): Universal Link `cupseason.app/?join=THEPTCQ5` signed out → door card → sign in → covenant with roster → Not now → league-less doors show "Invited · Review" → Review → Join; preflight 15–17 clean (no colour of its own, OTP discipline, RPC grants).
- **risk:** iOS parity is the risk itself (D100) — nothing in T2-03/T2-04/T2-06 ships to the web without this item scheduled in the same wave, or an explicit "web-only until <TestFlight build N>" note in the handoff.

### T2-15 · iOS Home: the rank card explains itself — **ios** · S · no decision (M-144; shared with the scoring theme)
- **Files:** `apps/ios/CupSeason/Home/HomeView.swift:487–591` (`HomeHero`: `line` at `~553–577`, `foot` at `~580–591`), `League/BylawsCard.swift:46` (`router.open(.scoringHelp)` — the route exists), `League/RoomBits.swift:181`.
- **Change:** in `.season`/`.cupFinal` modes append a quiet `Button("How points work →")` under `foot` opening `RoomScoringHelpSheet` (`LeagueRoomScreen.swift:94`); name the field — "10 back of Galen · 2nd of 2" — from `m.standing` (leader name is in the standings payload the Clubhouse already renders); "held" / "floors waived" get a one-line footnote on tap.
- **dependsOn:** none.
- **deployNeeds:** iOS build.
- **verification:** `ios/01-door.jpg` re-taken: the leader is named, the link is present; iOS survey question re-asked.
- **risk:** IOS-019 "one hero, one lane" — a text button inside the hero is within the rule; not a second card.

### T2-16 · The Guide stops saying "whoever opens it joins" — **copy / spec** · S · quick win (restores S3-01 truth)
- **Files:** `index.html:13233` (`GUIDE.buddies`: "whoever opens it joins that league" → "whoever opens it can review the league and join"), `Packages/CupSeasonKit/…/You/GuideCopy.swift` (the same `buddies` paragraph), `Cup-Season-Guide.md:106–109` ("everyone joins with the league code or an invite link" is fine; the "or invite by email" clause at `:106–107` is Theme 1's M-002 — not touched here).
- **dependsOn:** none.
- **deployNeeds:** client push + iOS build.
- **verification:** grep for "whoever opens it joins" = 0 in both clients.
- **risk:** none.

---

## (c) QUICK WINS — no decision needed, ship this week

**T2-02** (landing copy) · **T2-05** (covenant on `boot()` and `#wCodeGo`) · **T2-08** (league-code noun) · **T2-09** (legal contact + prize-pool link; owner confirms the mailbox) · **T2-10** (door rows collapse) · **T2-16** (Guide sentence) · **T2-12** (funnel node — a migration, but no mechanic changes; it makes the acceptance metric possible before the decisions land) · **T2-15** (iOS rank card link).

Order: T2-05 first (it is the S3-01 violation on the highest-value path); then T2-02 + T2-08 + T2-16 together as one copy commit; T2-10; T2-09 once the mailbox exists; T2-12 with the next db push.

---

## (d) PARITY — what the phone needs per item (D100)

| Item | Phone |
|---|---|
| T2-01 | Nothing to build; `Rpc.swift` regenerates from the refreshed `contract.psv` (signature unchanged). |
| T2-02 | The phone has no landing line at all — `DoorView` never mentions a pending code. Covered by T2-14's door card. |
| T2-03 | T2-14 door card (`DoorView`, signed-out RPC call). |
| T2-04 | T2-14 `CovenantSheet` rows + `Covenant` model. |
| T2-05 | Already true on the phone: `JoinModel.go()` gates every join (`JoinLeagueFlow.swift:87–99`); `InvitesBanner` accept (`respond_invite`) is the in-app invite, a different object. No item. |
| T2-06 | T2-14: remove `JoinIntent.clear()` from `RootView.swift:31`; declined key; "Invited · Review" door in `LeaguelessDoors`. |
| T2-07 | No orientation screen on the phone — nothing to skip. |
| T2-08 | `JoinLeagueFlow.swift:30` sub copy (in T2-08). |
| T2-09 | `DoorView.swift:182–190` third legal link (in T2-09). |
| T2-10 | The phone door is already single-stage (`vm.stage` switch, `DoorView.swift:33–37`). No item. |
| T2-11 | `ForgeView.swift:160–163` sentence + door link (in T2-11). |
| T2-12 | `CSTelemetry.event` calls at the covenant (in T2-12). |
| T2-13 | `LeagueWelcomeSheet`'s `ShareLink` message (in T2-13). |
| T2-15 | Phone-only item. |
| T2-16 | `GuideCopy.swift` `buddies` paragraph (in T2-16). |

Nothing in this theme is proposed "web-only". If T2-14 slips a wave, the handoff must say "web-only until TestFlight build N" explicitly.

---

## (e) MEASUREMENT

**Funnel (growth_events — `20260828160000`, one anon-safe writer):** per join code, `link_opened(kind=join)` (fires today at `index.html:17820` / `CupSeasonApp.swift:30`) → `profile_created(kind=join)` (fires today at `:13186` / `CSGrowth.profileCreated`) → **`league_joined`** (new, T2-12, written by `join_league` itself) → `first_round_posted`. **Invite→accept rate = `league_joined / link_opened` per code** — the leading indicator `spec/gtm-year1.md:43` asks for and the product has never been able to read. `v_growth_funnel` gains the `joined` column (founder/service-role read only).

**Decision surface (client_events — authenticated, `20260717153000`):** `covenant_shown {code, stake_cents, path: invite|code|hub|boot|resume, keys: n}` · `covenant_join` · `covenant_decline` · `invite_resume` (the Home card). Decline rate = `covenant_decline / covenant_shown`; resume rate = `invite_resume / covenant_decline`. Signed-out taps on the door's "How it works" (T2-11) cannot be written to either table by design (anon writes only a real `link_opened`) — accepted blind spot; the door→`profile_created(direct)` ratio is the proxy.

**Acceptance test (the blind persona re-run):** re-run **Journey B with persona A6 "Marcus" (new joiner)** and **A4 "Sam" (skeptic)** on fresh accounts (`+blind7`, `+blind8`) against a re-locked test league whose Pro shares `/?join=` from the T2-13 text. Pass criteria, in the persona's own words before tapping Join: who runs it, how many are in, when it runs, how a round becomes points, what the $50 is for and who it is paid to. Then: "Not now" → Home card → Review → Join with no retyping; a second, already-signed-in account opening the same link sees the covenant before anything changes in `league_members`. Targets: joiner key question ≥ 7/10 (from 3); `conceptClear` ≥ 6 for all four joiner personas (today 5/6/4/5); the skeptic's "fifty bucks for what?" answered on the sheet. Re-take `join/02`, `join/11`, `join/12`, `skep/02`, `ios/01`.

---

## (f) OPEN QUESTIONS FOR THE OWNER

1. **Roster names before sign-in?** D111 defaults to Pro name + count for a signed-out code-holder and names only on the signed-in covenant. Loosen to names pre-auth (better pitch, wider read surface for a link that escapes the group chat) or keep?
2. **"Who invited you."** The code is league-level; the RPC cannot know who shared the link, so the card says "Casey runs it (THE PRO)". Acceptable for now? Per-member invite tokens (D57-shaped, revocable) would name the actual sharer — a later decision if wanted.
3. **`hello@cupseason.app`** — does the mailbox (or a Porkbun forward) exist? T2-09 waits on it.
4. **`$0` leagues get the decision sheet** (WHO/WHEN/HOW, no STAKE row, plain "Join") — D111 §3 proposes yes; D70 forbids pot surfaces, not disclosure. Confirm.
5. **Money posture on the cold door.** The audit wants "Free to play. Leagues set their own buy-in…" under the slogan; D101 says "no pricing on the front door". D113 keeps money OFF the cold door and ON the invite card. Confirm.
6. **Pre-lock joins.** `join_league` has no phase check, so a member can join an unlocked league (contradicts D40's "members can only join a locked league"). The prospectus will read "Forming · first tee not set" for those. Refuse pre-lock joins server-side (D40 literal) or keep the code passive-but-live? Cross-theme (Theme 1/3).
7. **M-029, the sign-in email subject** threads twenty codes into one Gmail conversation. The templates live in the Supabase dashboard, not the repo (CLAUDE.md: code-only OTP). Vary the subject with the code's last digits if the template engine allows `{{ .Token }}` in the subject; the body cannot be league-aware (GoTrue knows no league). Owner-run; low priority.
8. **The D82 amendment (D112 §3)** — comfortable with invitees never seeing the "Four places" screen unless they open You › How it works?

---

*Cross-references: Theme 1 (TOP-1) owns the invite sheet with the URL as text (`openLockShare`, `shareInvite` fallback, M-002/M-003) and the `humanError` clipboard misdiagnosis; Theme 3 (TOP-3) owns role-gating and the forming hero; Theme 4/5 own the scoring sign and the endgame copy that the covenant's HOW/FINISH rows link to. The covenant's payment note is the precondition for Theme 5's `buy_in_note` / `buy_in_due_on` (D106 follow-up) — when that lands, the STAKE row reads it.*
