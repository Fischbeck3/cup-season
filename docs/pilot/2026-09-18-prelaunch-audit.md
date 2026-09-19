# Pre-launch audit — 2026-09-18

Strict grades, evidence-cited, against the question "could this go live next
week and succeed?" Production reads were read-only; fixes found during the
audit are on `claude/pilot-readiness-2026-09-15`, deployed nowhere. Counts
are aggregates; no golfer or league is named (public repository).

## Verdict

**The engine and the walls are launch-grade. The way in and the way out are
not yet.** Scoring, authorization and the server side of the core loop have
been proven against the real functions and recompute exactly. What blocks a
launch is operational and legible, not architectural: the live web and the
Friends build are a week behind the verified code, the two-phone device
checks have never been run, and the growth loop — invites, share links,
guest claims — is built but essentially unexercised (1 of 29 guest seats
ever claimed, 1 link open on record). A cold public launch next week would
violate two of our own ratified gates. A staged launch — web current +
Friends on a fresh build this weekend, independent groups next week — is on
track, with the capped public cohort roughly three to five weeks out if the
gates pass.

The strongest signal in production: **every golfer who ever posted a round
posted again** (21 of 21). The product retains the people who get in. The
pilot exists to prove people can get in without the founder.

## Grades

| Area | Grade | Evidence | Blocking? |
|---|---|---|---|
| Score integrity & engine | **A−** | 12/12 league rounds and both standings recompute exactly; rounds immutable; duplicate posts/starts refused by the database; month closes correct; db-checks 34/34 after today's fix (below). Minus: the gameplay sim's band-skew finding (most real rounds land in the bottom two bands) is a feel question still open. | No |
| Authorization & privacy | **A−** | 72 restricted-role probes PASS / 0 FAIL across six actors, tables and RPCs; claim cards leak nothing; emails sealed. Minus: db-check 23 caught a default-privilege leak TODAY — the two pilot tables granted TRUNCATE/TRIGGER to signed-in clients (founder-only data, no scores reachable). Fix `20261109090000` written, validated, NOT pushed. Process lesson recorded: new tables revoke-then-grant. | Push the revoke |
| Core loop, server | **A−** | Start-or-join per booking, seat-gated joins, idempotent finish, claim-once, offline write clocks — all proven on the real functions. Known trap: only the host (or a league-member seat) can finish a league-less round; a dead host phone strands the group until the host resumes. Documented for testers; candidate for a later widening. | No |
| Core loop, clients/devices | **C+** | The web double-start class is fixed and regression-tested, but the two-phone checks (A1–A11, R1–R7, G1–G2) are NOT RUN, three composer UI tests are still blocked on a simulator sign-in, and this audit found two Compete suites red since the Scoreboard landed (asserting the old shape; suites updated today — a coverage-discipline miss, mine). | **Yes — the Friends gate** |
| Onboarding & comprehension | **C** | The founder himself could not find a buddy's booking from its notification (fixed on-branch, undeployed) and did not retain what the allowance means (copy gloss proposed, awaiting a yes). The five timed onboarding gates were last run in July on v23.163. The wizard discloses every rule but explains none. | Partially |
| Growth loop | **D** | 29 account-less guest seats ever, **1 claimed**. 7 share links minted, **1 opened**. 0 email invites, 2 member invites, 0 growth-attributed profiles. The loop that a public launch depends on is built and almost never exercised. Friday's task: walk the claim journey end-to-end and find where it dies. | **Yes — for public** |
| Distribution currency | **D+** | Live web = Sep 13 commit; Friends = build 795 (Sep 12); Owner = 934; the branch tip is ahead of all three. Every fix from F1–F13, the finish loop, the note door — invisible to everyone but the owner. One review + one push + one build fixes this; that is Saturday. | **Yes** |
| Platform/store readiness | **B** | In-app account deletion on both clients; legal page live (HTTP 200); TestFlight external review previously passed; 934 VALID. Recent crash rows are dev-build or pre-905 only. Minus: no dedicated crash pipeline beyond client_events. | No |
| Ops & measurement | **B+** | deploy-status, db-checks, preflight, the read-only scorecard, attempt-keyed telemetry, the founder-only pilot record — all in place. Minus: the cohort table is empty (name cohorts before reading pilot numbers), and ops is one person. | No |
| Business readiness | **C** | Deliberately parked: season-pass pricing is a hypothesis with an interview guide, tested on nobody. Not a launch blocker by plan; it becomes one at the paid-competition stage. | No |

## Found and fixed during this audit (on-branch, not deployed)

1. **TRUNCATE/TRIGGER grant leak** on the two pilot tables → `20261109090000_truncate_is_not_a_client_verb.sql`, validated on the sandbox; pilot-record suite re-proves founder-only at 13 PASS.
2. **Two Compete suites red since F11** (asserted the pre-Scoreboard shape) → updated to the ratified contract; both PASS.
3. **The web band said the rank twice** (figure + sub's leading rank clause) and **dropped the lead season's status line** ("The clash closes today") → both fixed; native band verified unaffected (its row model folds status into the sub).
4. Pilot-record test made idempotent on a shared sandbox.

## The week, if launch means "staged launch starts now"

| Day | Who | What |
|---|---|---|
| Thu (done) | Claude | This audit; the four fixes above; suites green (preflight 0, Kit 1224/198, app 100/19, web suites incl. the two repaired). |
| Fri | Claude | Walk the guest-claim journey end-to-end and fix or file where it dies; allowance gloss if approved; assemble the release candidate summary for review. |
| Sat | Codex + owner | Codex reviews the two branches. Owner: `supabase db push` (the revoke), merge to main (web goes current), archive + upload a fresh build to Owner. |
| Sat–Sun | Owner + one friend | The two-phone checklist on the fresh build, recorded PASS/FAIL in `owner-checks.md`. **This is the Friends gate.** |
| Mon | Owner (+ Claude fixes) | Fix fallout; promote the build to Friends; name cohorts in the pilot record; send the Friends task sheets (drafts ready; owner sends). |
| Tue–Thu | Everyone | Friends rounds happen unassisted; support log runs; recruit 3–5 independent groups (outreach drafts ready); one competition group toward a season lock. |
| Next Thu | Owner | Weekly review against `gates-and-stop-conditions.md` → go/no-go for the independent stage. |

## Decisions the owner owes this plan

1. Saturday's pushes (database revoke, web merge, new build) after Codex review.
2. Friends promotion after the two-phone checks pass — and only after.
3. The allowance gloss: one sentence in the wizard info and three words in the covenant clause — yes or no.
4. Whatever Friday's claim-journey walk finds, if it needs more than copy.
