# 1.0 phone checks · the owner's solo run sheet

**Build:** Cup Season 1.0.0 (**2114**) from `c8cd8ea3` (the same files as main's `ebbbfea3`),
on your own iPhone through TestFlight (Owner group). It is 2097 plus D405, comments in line under
the round (R12, R13), which reworks Home's round cards, so run every row on 2114, R10 included.
Every server layer it needs is deployed (D405's migration and web client on 2026-10-02, the rest
on 2026-10-01), so the filter, takedown, ban and scan-consent checks below test the candidate's
own server.

**No strangers.** No testers are recruited for 1.0 (owner, 2026-10-01). Where a second golfer
is needed, use one of your own `jerecho+…@fischbeck3.com` test accounts. Never use
`reviewer@cupseason.app` except for R1, and never confirm a deletion on it.

Mark each row PASS or FAIL with a screenshot of anything wrong. Anything not done stays
NOT RUN.

## The readiness checks (new in this candidate)

| # | Check | Steps | Expected | Result |
|---|---|---|---|---|
| R1 | Reviewer door (B-11) | Sign out. Type `reviewer@cupseason.app`, tap **Send code**. Enter the password you will put in App Store Connect. | A Password field appears ("Review access: enter the password from the notes"); nothing is emailed; you land signed in. Compete → Ridgeline Cup → "Every golfer": Tara Nguyen 112 points, 17 rounds. Sign out after. | NOT RUN |
| R2 | Scan consent | Post a round → **Scan the scorecard**. Tap **Type it in**. Then scan again → **Scan with Claude** → photograph a card. Then Settings → **Scorecard scanning with Claude** off → scan again. | "Type it in" sends nothing ("Nothing was sent — type your nines in"). The yes scans and fills the rows. After switching off, the next scan asks again. | NOT RUN |
| R3 | Text filter | On a test league's board, type a word from the D403 list and post it. | The refusal sentence appears and your draft stays in the box. Remove the word and it posts. | NOT RUN |
| R4 | Photo takedown, rehearsed once | As a test account, post a round with a photo. As yourself, report it (golfer ⋯ → Report → "An inappropriate photo"). On the web desk, take it down. | The founder push arrives. After the takedown, the photo is gone from Home within about a minute, and a link to it shared before the takedown stops loading. | NOT RUN |
| R5 | Ban, rehearsed once (optional) | On the desk, remove a test account (type its handle). Use the app as that account. Then restore it. | Its next action is refused ("This account has been closed."); it cannot sign in again. After restore, it works. | NOT RUN |
| R6 | Live stake ceiling | **Score it live** → set an amount per point above $200. | The field stops at $200. | NOT RUN |
| R7 | Money door | Open the start sheet before a season's first tee, then after it. | It reads "Buy-in" before, "Pride bet" after. The listing never says "Put money on it". | NOT RUN |
| R8 | Photo audience line | Attach a photo in the composer, then scan a card. | Beside the remove control, the line says who sees the photo; a scanned card says the same. | NOT RUN |
| R9 | Account deletion | On a THROWAWAY test account only: You → Card & settings → Settings → **Your account** → **Delete my account** → **Delete permanently**. | The confirm text matches the review notes; the account signs out and cannot sign in again. | NOT RUN |
| R10 | Home Scorebook (D404) | Open Home with a few posted rounds. | Each round has its matte score panel (gold, silver or bronze by how the round went) and a spaced rule after it; the round opens its receipt and the golfer opens their card. | NOT RUN |
| R11 | Standings head (candidate 2) | Compete → a league in season that is past its first Sunday → the table. One of your own leagues, or Ridgeline Cup while you are signed in as the reviewer for R1. | The column head reads "GAP · SINCE SUN". On 2094 it printed a raw timestamp (`2026-09-27T07:20:00…`). | NOT RUN |
| R12 | Comments in line (D405) | On Home, tap the comments line of a buddy's round (have one of your test accounts comment first if none has any). Write a comment and send it. Tap the same line again. Then do the same on a league board post. | The thread opens right under the round: no new page, no sheet. The newest three comments show, with "Earlier comments (N)" above them when there are more. The box reads "Comment on [first name]’s [score]…" (on your own round, "Comment on your [score]…"). Your comment appears in line at once with "Updates from this conversation are on."; the same tap folds the thread. No button anywhere says "Follow". | NOT RUN |
| R13 | Whose round, and who hears (D405) | Tap into that buddy's round from Home and open its ⋯ menu. Then have a test account reply to the comment you left in R12. | The page is titled "[first name]’s round" beside their face ("Your round" on yours), and its conversation head reads "On [first name]’s [score]". The ⋯ menu offers "Notify me about": Every comment · Replies to me · Nothing. The reply reaches your notices as "[name] replied to you on [first name]’s round." Back on Home, a round with comments shows its newest one under the card before any tap. | NOT RUN |

## Carried from `docs/design/ten-2026-09-27/launch/HUMAN.md` §4

Run at least these on 2094: **D1** VoiceOver names and order, **D2** real keyboard, **D6**
offline → reconnect, **D7** kill → resume, **D9** widgets, **D10** Live Activity, **D12**
live finish → recap. D3–D5, D8, D11 and D13 are as written there.
