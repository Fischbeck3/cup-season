# The timed comprehension tests — W1 (launch plan §3)

Four gates, a stopwatch, three people who have not seen the app, no
walkthrough. First run on the Friends build over Fri 25 – Sun 27 September;
the stranger run on the shipped build by 17 October with three people from the
public link. The gates are `spec/prelaunch-qa-2026-07-13.md`'s, last run in
July on v23.163; nothing here is passed from a simulator, ever — the owner
supplies the phone and the person, and the sheet below is the evidence.

## The four gates

| # | Gate | Starts when | Stops when | Target |
|---|---|---|---|---|
| G1 | **The golfer card** | The tester has the app open on the sign-in screen and their email in hand | The card is saved and Home is on screen | under 2 minutes |
| G2 | **Joining** | A join link or a code is in the tester's hand, signed in | The tester is on the season page of that league | under 30 seconds |
| G3 | **Posting a round** | The tester is on Home with a real round's front and back nines written on paper | The finish ceremony is on screen | under 60 seconds |
| G4 | **A standings figure, explained** | The tester is on the standings table and is asked "where did your points come from?" | The tester names the rounds behind the figure (they opened the receipt) | under 10 seconds |

## The protocol — read this to the tester, then say nothing

> I am going to time four things. I will not help, and I will not answer
> questions until all four are done — if you get stuck, say "stuck" and keep
> going or give up, and both are fine. There is nothing you can break.

1. Hand over the phone with the app on the sign-in screen. Start the watch when
   they touch the screen. Stop when Home shows. Write G1.
2. Send them the join link (or read them the code). Start when the link is
   tapped or the code is on screen. Stop on the season page. Write G2.
3. Hand them the paper with a front nine, a back nine and a course name. Start
   when they touch the ⊕. Stop on the ceremony. Write G3.
4. Open the standings on their phone. Ask the question. Start on the last word.
   Stop when they say which rounds. Write G4.
5. Then, and only then: *Where did you slow down? What did you expect to
   happen that did not?* Write it down in their words.

The passive view reads G1 and G2 afterwards without a watch
(`v_pilot_gates`: `gate1_seconds`, `gate2_seconds`, founder-only); G3 and G4
have no passive timer and are timed by hand only. The two readings of G1/G2
should agree within reason; where they do not, the watch wins and the
difference is filed.

## The results sheet — one row per tester per gate, no names

Build numbers, not names. A tester is `T1`, `T2`, `T3` on the day; the
mapping to a person stays in the founder's private notes.

| Run | Date | Build (web SHA / iOS build) | Tester | Gate | Seconds | Met? | Stuck where (the screen, in their words) |
|---|---|---|---|---|---|---|---|
| Friends | | | T1 | G1 | | | |
| Friends | | | T1 | G2 | | | |
| Friends | | | T1 | G3 | | | |
| Friends | | | T1 | G4 | | | |
| Friends | | | T2 | G1 | | | |
| Friends | | | T2 | G2 | | | |
| Friends | | | T2 | G3 | | | |
| Friends | | | T2 | G4 | | | |
| Friends | | | T3 | G1 | | | |
| Friends | | | T3 | G2 | | | |
| Friends | | | T3 | G3 | | | |
| Friends | | | T3 | G4 | | | |

Copy the block for the stranger run.

## What "done" means

- Three runs recorded per gate with the build number on the row.
- Each gate met by two of three, **or** the miss filed in `spec/inbox.md` the
  same day, naming the screen it stalled on in the tester's words — a miss is
  a finding, not a failure of the tester.
- The passive view read the same week for G1/G2, and the two agree within
  reason.
- Observed friction is fixed narrowly on `claude/october-launch` and the
  failed gate re-run on the next build; the sheet keeps both rows.

Nothing on this sheet is marked met from a simulator, a screen recording or
the founder's own run.

The release checklist (`docs/planning/2026-09-22-release-checklist.md`) carries
this gate as not passed until the sheet above is filled with build numbers.
