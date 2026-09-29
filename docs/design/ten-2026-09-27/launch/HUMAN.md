# Human proof, run sheet for the owner

**Status: NOT RUN.** Every row below starts NOT RUN.
- No simulator, screen recording, synthetic fixture or founder run can pass one of them.
- This packet is ready before the candidate so the owner can book people now.
- The candidate's identities are filled in at release, not before.

The protocol and gates are the pilot's own:
- [timed tests](../../../pilot/timed-tests.md)
- [tester sheet](../../../pilot/tester-task-sheet.md)
- [owner checks](../../../pilot/owner-checks.md)

This page adds only the ten program's recipient, accessibility and device rows, and ties every row to one build.

## 0 · The candidate (filled at release)

| Layer | Identity | How to confirm on the device |
|---|---|---|
| Web | main `cf401dee` | cupseason.app → sign-in caption reads `v23 · cf401de`; it must match |
| iPhone | Owner TestFlight 1.0.0 (`1180`) from `cf401dee` | TestFlight → Cup Season → build number; in the app, Settings → version |

Filled on 2026-09-28 for the owner's testing release ([LEDGER §4e](LEDGER.md)). If a later candidate ships before the testers arrive, replace both rows and re-run every gate on it.

Use the candidate on both clients for every row. A row run on an older build is recorded, but it does not count.

## 1 · Before the testers arrive (owner, 10 minutes)

1. **People:** three people who have **never opened Cup Season**. Friends of friends are fine; the pilot league is not.
2. **Phones:** their own phones.
   - Install the TestFlight **Owner** build via the Owner group, or use the web app at cupseason.app, whichever the tester will really use. Record which.
3. **A join link for a real season** each tester may join, e.g. a test season the owner runs.
   - Membership changes are real and owner-managed.
   - Delete the test memberships afterwards per the pilot protocol.
4. **A paper card per tester:** a course name, a front nine and a back nine (G3).
5. **The results table** from §2, and a stopwatch.

## 2 · The four timed gates

Read [the protocol](../../../pilot/timed-tests.md#the-protocol--read-this-to-the-tester-then-say-nothing) aloud, word for word, then give no help.

| Gate | Start → stop | Target |
|---|---|---|
| G1 golfer card | touches the sign-in screen → Home shows with the card saved | < 120 s |
| G2 joining | taps the link / has the code → the season page | < 30 s |
| G3 posting | touches ⊕ on Home with the paper card → the finish ceremony | < 60 s |
| G4 points explained | the last word of "where did your points come from?" on standings → names the rounds (receipt open) | < 10 s |

A gate is met when **2 of 3** testers make it. Otherwise file the miss in `spec/inbox.md` the same day, naming the screen and the tester's words.

| Date | Client + build | Phone / OS | Tester | Gate | Seconds | Met? | Stuck where (their words) |
|---|---|---|---|---|---|---|---|
| | | | T1 | G1 | | NOT RUN | |
| | | | T1 | G2 | | NOT RUN | |
| | | | T1 | G3 | | NOT RUN | |
| | | | T1 | G4 | | NOT RUN | |
| | | | T2 | G1 | | NOT RUN | |
| | | | T2 | G2 | | NOT RUN | |
| | | | T2 | G3 | | NOT RUN | |
| | | | T2 | G4 | | NOT RUN | |
| | | | T3 | G1 | | NOT RUN | |
| | | | T3 | G2 | | NOT RUN | |
| | | | T3 | G3 | | NOT RUN | |
| | | | T3 | G4 | | NOT RUN | |

Then ask: *Where did you slow down? What did you expect to happen that did not?* Record the answer verbatim.

## 3 · Right after the gates (observed, no pass threshold)

| # | Step | What to watch for | Result |
|---|---|---|---|
| O1 | Open the posted round → **Share** → describe what is included → **Cancel** once | They can say what leaves the phone (photo only on a yes); cancel publishes nothing | NOT RUN |
| O2 | Share again → send to a consenting recipient | Share sheet, card and link together (D380) | NOT RUN |
| O3 | Recipient opens the public round / claim link; installs if needed; opens the link again | They recognise the round; the next step is clear; nothing private shows | NOT RUN |
| O4 | Back to Home; again the next morning | Home stops offering the posted round; no stale "round to play" | NOT RUN |

## 4 · Owner device checks (candidate build, on your own phone)

| # | Check | How | Result |
|---|---|---|---|
| D1 | VoiceOver names and order | Settings → Accessibility → VoiceOver. Swipe through Door, Home, the composer, a receipt and a sheet. Every control is named; the order follows the screen; sheets take focus and return it | NOT RUN |
| D2 | Real keyboard | Door email + 8-digit code; the composer's gross, rating and slope. The primary action is never hidden under the keyboard | NOT RUN |
| D3 | Larger text | Settings → Display → Text Size at the largest AX size. Live scoring, the course card, the Book and You read whole, nothing clipped | NOT RUN |
| D4 | Reduce Motion | Settings → Accessibility → Motion. The finish ceremony and a Cup moment rest on their final frame | NOT RUN |
| D5 | Outdoors | Full sun, at the course. Live scoring, the receipt and the Book are readable in light and dark | NOT RUN |
| D6 | Offline → reconnect | Airplane mode mid-round, score 3 holes, reconnect. Nothing lost, nothing doubled | NOT RUN |
| D7 | Kill → resume | Swipe the app away mid-round; reopen at the right hole with every score | NOT RUN |
| D8 | Two-phone integrity | [owner checks](../../../pilot/owner-checks.md) A1–A11, R1–R7, G1–G2 | NOT RUN |
| D9 | Widgets (system host) | Add each Cup Season widget to the Home Screen: empty and populated read correctly; a tap opens the right place | NOT RUN |
| D10 | Live Activity (system host) | Start a live round; Lock Screen and Dynamic Island show the round; the tap returns to it; it ends at the finish | NOT RUN |
| D11 | Autumn look in Light (F05) | Settings → Palette → Autumn, Light appearance. Primary buttons are readable | NOT RUN |
| D12 | Live finish → recap (LEDGER X34) | Score a live round with at least one other golfer → **Finish the round** → the sheet's **Finish the round**. The recap takeover appears ("N cards to the season"); the "Live round in progress" bar is gone; the round is on Home | NOT RUN |
| D13 | Album that fails to load (LEDGER X35) | Airplane mode → You → Album. It reads "The album didn't load" with **Try again**, never an empty album. Reconnect → **Try again** → the photographs return | NOT RUN |

When a corrected build fixes a failed row, keep the failed row and add the new one beneath it.
