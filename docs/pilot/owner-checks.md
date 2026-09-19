# Stage A · Owner verification — two phones, one afternoon

Record each row as PASS / FAIL / NOT RUN with the build number on each phone.
Phone 1 is the host. Phone 2 is a golfer the host tags. Use a real course from
the picker so the card's pars are the course's own (the tally and the birdie
moment stay silent on a template card by design).

What the sandbox already proved (`tests/pilot/authz-flow.py`, real functions,
row security on) is marked ✔ below; the two-phone checks are about the
CLIENTS, which the sandbox cannot drive.

## Lifecycle

| # | Check | Server proof | Phones |
|---|---|---|---|
| A1 | Phone 1 books a round for today, tags Phone 2. Phone 2 sees the booking on Home and says IN. | ✔ | |
| A2 | Phone 1 opens the booking → **Tee it up**. Live setup shows the course and Phone 2's golfer seated, pending golfers named as pending. | — | |
| A3 | Phone 1 tees off. Phone 2 opens the same booking → Tee it up → lands in the SAME round (joined), roster and scores as Phone 1 has them, no second round on Compete. | ✔ join | |
| A4 | Both phones enter scores for two holes; each sees the other's within a few seconds. Phone 1 corrects a score; Phone 2 sees the correction. | ✔ clocks | |
| A5 | Phone 2 kills the app and reopens: the round resumes at the right hole with every score. | — | |
| A6 | Phone 1 goes to airplane mode, scores three holes, comes back: the scores land, nothing is lost, nothing doubles. | ✔ stale-clock rule | |
| A7 | A birdie on a known-par hole shows the ember moment once, under the header, and leaves; the tally line updates. A par shows nothing. | — | |
| A8 | Phone 1 finishes. Recap says **Round posted** for Phone 1's own card; **View round** opens the receipt; **Add a photo** opens the same receipt with the photo control ready. | ✔ ids | |
| A9 | Phone 2's recap (or its next open) also says Round posted for ITS card; both receipts exist; Home on both phones no longer offers the booking. | ✔ | |
| A10 | Phone 1 taps finish again (or Phone 2 does): "already final", nothing posts twice. | ✔ | |
| A11 | The receipt's tally reads e.g. `1 birdie`; a receipt from an OLD round (before 932) shows no tally at all. | ✔ provenance | |

## Recovery and honesty

| # | Check | Phones |
|---|---|---|
| R1 | Start a round with no signal: the failure is visible, the app is back in setup, nothing half-started. | |
| R2 | Two taps on tee-off in quick succession: one round. | |
| R3 | Finish with no signal, then regain it: one finish, one set of posted cards. | |
| R4 | Kill the app mid-finish; reopen: either the recap or the live round, never a blank state and never a duplicate. | |
| R5 | Every full-screen flow has a way out: live round (Close keeps it running), post cover, wizard, receipt preview, camera. | |
| R6 | The + button opens the Play cover with **Post a round**, **Score it live** and **Start something** as three distinct doors. | |
| R7 | A tester who was tagged but not seated tries Tee it up after the host started: told the group teed off without a seat; nothing else changes. | |

## Account-less guest

| # | Check | Phones |
|---|---|---|
| G1 | Host seats "Pat" (no account). After the finish the recap shows Pat's claim link; the link opens signed-out and shows name, gross, course, date only. | ✔ fields |
| G2 | Pat creates an account and claims: one round appears on Pat's record; claiming again says already; a second person cannot take it. | ✔ |

## Known, by design (tell testers)

- Only the host — or a league member seat — can finish a league-less round. A seated golfer without a league cannot finish it; the host must.
- The tally and the birdie moment stay silent unless the card's pars came from the course or were typed in.
