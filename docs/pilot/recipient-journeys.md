# The recipient journeys — W3 (launch plan §3)

Two ways a stranger arrives, walked end to end **as the recipient**, on a
physical phone, signed out, with no one explaining. Each row is PASS / FAIL /
NOT RUN with the build number and the web stamp on the phone that ran it;
names never enter this file (a tester is T1, T2). Simulator fixtures do not
satisfy any row here — the Mac pass of 2026-09-22 says so itself.

**The evidence rule.** A row is PASS when the owner has: the screen on a real
phone (a photo or screenshot), the build number or web stamp, and — for the
consent rows — the Storage API answers below, copied in. Nothing else counts.

## A · The claim link (`/?claim=TOKEN`)

Setup: T1 (the host) tees off a live round on their own phone and seats T2 as
an account-less guest named on the tee sheet; the recap hands T1 a claim link,
which T1 sends to T2's phone by message. T2 has never had an account.

| # | Step, as T2 | What must be true | Result · build · evidence |
|---|---|---|---|
| A1 | Open the link while the round is still live | Lands in the pencil: the round, the roster, their own card to score, no account asked for | |
| A2 | Open the same link after the host finishes | The door card: *T2 — 84 at COURSE, DATE. Enter your email to keep it.* | |
| A3 | Open a link from a round the host abandoned | The true sentence: *This round was never finished, so there's no card to keep…* and the token is dropped (opening it again does not ask again) | |
| A4 | Open a link from a round not yet teed off | *That round hasn't teed off yet — your card lands here when it finishes.* The pencil is kept | |
| A5 | Enter the email, type the code, fill the golfer card | The round is on T2's record; the toast says it; opening the link again says *already* | |
| A6 | T3 opens T2's already-claimed link | Told it is already on a record; nothing about T2 beyond name, gross, course and date was ever visible signed out | |
| A7 | Install the app, then open the link again from the message | The link lands inside the app (universal link); the same card, the same outcome | |

The server half is `tests/pilot/claim-walkthrough.py` (24 of 24 on PR #6);
this table is the client half and the device half.

## B · The season invitation (`/?join=CODE`, and the re-up)

Setup: the Pro locks a season and copies the invite message; T2 receives it.
For the re-up: a league whose first season is complete runs it back, so every
member is asked again.

| # | Step, as T2 | What must be true | Result · build · evidence |
|---|---|---|---|
| B1 | Open the link signed out | The door says who invited them and to which season; nothing else is revealed before sign-in | |
| B2 | Sign in, land on the covenant | *Before you join NAME*, WHO first, the length, the rules with the allowance clause, the ending, the money above $0 only, the join button with the stake | |
| B3 | Tap Not now | Nothing written; the invitation is still there next time | |
| B4 | Tap Join | Seated the way the door seats (loose before the draw, thinnest squad after the start); the welcome; the season page | |
| B5 | Re-up: open the invitation for season 2 | *Season 2 invite* · *Season 2 of NAME is on. Same rules, fresh table.* | |
| B6 | Re-up: the covenant | *Season 2 of NAME* · SAME RULES — EVERYTHING BEFORE YOU TAP · the season fact first, with last season's finish when the server could compute it · *I'm in for season 2 — $N* | |
| B7 | Re-up: say yes | *You're in for season 2. Same rules — the table starts fresh.* The Pro's roster stops saying NOT IN YET beside T2; the yes count goes up by one | |
| B8 | Re-up: open the covenant again after the yes | *You're already in for season 2.* and no join button | |
| B9 | The Pro taps Ask again on a member without a yes | *NAME is asked again — it rings on their phone.* The member's phone rings | |

## C · The share consent gate — Storage API evidence, not a screenshot

The share flow's promise (D380) is that the photo appears in the message,
on the public page and in the link's preview **only on a yes**, and that a
withdrawn yes cannot be served from the old url. The proof is what the
Storage API and the public endpoint answer, on the release build, against
production — never a local mock and never a simulator.

Set once, in the shell that runs the checks (the publishable key is public;
nothing here needs a session):

```bash
BASE=https://zddbfcokmvneltrgukzf.supabase.co
KEY=<the publishable anon key from index.html>
share_info() { curl -s "$BASE/rest/v1/rpc/share_info" -H "apikey: $KEY" -H "authorization: Bearer $KEY" -H "content-type: application/json" -d "{\"p_token\":\"$1\"}"; }
copy()       { curl -s -o /dev/null -w '%{http_code}\n' "$BASE/storage/v1/object/public/shared/$1.$2"; }
preview()    { curl -s "https://cupseason.app/?share=$1" | grep -o '<meta property="og:image" content="[^"]*"'; }
```

| # | Step on the phone | Then read | PASS when | Result · build · evidence |
|---|---|---|---|---|
| C1 | Share a round that has a photo with **Include round photo ON** | `share_info TOKEN`; `copy TOKEN png`; `copy TOKEN jpg`; `preview TOKEN` | `"photo": true` · png 200 · jpg 200 · og:image is the card png | |
| C2 | Share the same round again with the toggle **OFF** | the message carries a **new** token; `copy OLD jpg`; `copy OLD png`; `share_info OLD`; `share_info NEW`; `copy NEW jpg`; `preview NEW` | old jpg 400/404 · old png 400/404 · old `share_info` null (revoked) · new `"photo": false` · new jpg 400/404 · new og:image is the card png without the photo | |
| C3 | Share a round that has **no photo** | the sheet shows no toggle; `share_info TOKEN`; `copy TOKEN jpg` | `"photo": false` · jpg 400/404 · the card and the link in the message | |
| C4 | Turn off the link from the epilogue | `share_info TOKEN`; `copy TOKEN png`; `copy TOKEN jpg`; `preview TOKEN` | `share_info` null · both copies 400/404 · the preview is the brand image | |
| C5 | Open a NEW token's public page signed out on another phone | the page | the card's facts; the photo as the ground only when C1 said yes; no other golfer's photo, ever | |

What this proves and what it cannot: C2 proves the old url stops serving the
withdrawn photo. It does not and cannot recall a preview a messaging app
already saved on a recipient's phone; the fine print under the toggle says
so, and no row here claims otherwise.

## D · Where the results go

Build numbers and stamps on every row; names nowhere. A FAIL is filed the
same day in `spec/inbox.md` with the screen it happened on in the tester's
words; the fix rides `claude/october-launch`'s successor branch and the row
is re-run on the next build. The release checklist
(`docs/planning/2026-09-22-release-checklist.md`) points at this file for
its recipient and consent gates and marks them not passed until these tables
are filled.
