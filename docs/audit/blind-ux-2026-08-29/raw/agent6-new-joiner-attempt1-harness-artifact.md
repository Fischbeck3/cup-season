# Blind UX audit — Agent 6: New player joining an existing league

**Persona:** Marcus Bell, Chandler AZ, ~12 handicap, home course Bear Creek Golf Complex. Zero context about the league. A friend (Casey Ortega) texted: "yo, set us up on Cup Season for the fall — link: https://cupseason.app/?join=THEPTCQ5 — code THEPTCQ5". League: "The Papago Grind".
**Account:** jerecho+blind2@fischbeck3.com · **Session:** `join` (iPhone viewport, local build at http://127.0.0.1:8791/)
**Date:** 2026-08-29 · all times UTC
**Screenshots:** `../screenshots/join/`

Key question for this persona: **"Can you understand what you are joining before accepting?"**

---

## 0. The invitation itself

- **Email invitation:** NONE. Gmail search `"Cup Season" newer_than:6h` (and later `from:noreply@cupseason.app`) returned only sign-in-code emails addressed to other people. Nothing addressed to jerecho+blind2@fischbeck3.com. So the app sent me nothing when Casey invited me — the only invitation is Casey's text.
- **The text:** a link and a code. The link carries the league name nowhere; I only know it's "The Papago Grind" because Casey told me. The text says nothing about dates, money, format, or who else is in.

USER ASSUMPTION: opening the link will show me a page about the league (who, when, what, how much) with a "Join" button.
ACTUAL PRODUCT BEHAVIOR: see §2 — the link opens the generic sign-in door with one extra sentence.

---

## 1. JOURNEY A — Discovery, signed out (14:12:47 UTC)

**Screen: cold door** — `../screenshots/join/01-cold-door.jpg`

What is on screen, verbatim: orange flag-and-club logo · "CUP SEASON" · "Rally your crew. Post real rounds. **Take the cup.**" · button "Continue with email" · button "I have an invite code" · "By continuing you agree to the Terms & Privacy Policy." · "v23 · __CS_VERSION__".

Accessibility tree names the dialog "Cup Season sign-in". Behind the dialog (NOT visible to a person) the page has a header "Cup Season", "Around your buddies", "THE BOARD ↗", and a tab bar Home / Clubhouse / Post / You.

**3-second read:** A golf app (flag logo), something about a "cup", and I must sign in. Two buttons.
**10-second read:** "Post real rounds" — I will be entering golf scores. "Rally your crew" — this is for a group. "Take the cup" — there's a trophy/winner. The word "invite code" tells me groups are private.
**30-second read / what I could do:** Enter an email or an invite code. That's it. Nothing tells me what a season is, how long it lasts, whether money is involved, or what "the cup" is. There is no "how it works", no screenshots, no example. The version line "v23 · __CS_VERSION__" is developer junk visible to a user.

**Honest first answers (signed out):**
1. What does the app do? — Some kind of golf competition among friends where you post your scores. Beyond that, no idea.
2. Primary action? — "Continue with email" (it's the big orange button). But I have a code, so I'm torn between the two buttons.
3. What is a "season"? — Not defined anywhere. Guess: a stretch of weeks/months.
4. What is a "league"? — The word does not appear on the door at all (it appears later as a "LEAGUE CODE" placeholder). Guess: a friend group.
5. What is a "cup"? — "Take the cup" implies a trophy. Undefined.
6. What am I competing for? — Unknown. "The cup", whatever that is. Money? Unknown.
7. Who am I competing against? — "your crew" — presumably Casey and friends. Unknown how many.
8. How do rounds work? — "Post real rounds" — I guess I enter scores from real golf. How, where, when: unknown.
9. What happens after a round? — Unknown.
10. What makes this different from just playing golf with friends? — Cannot say. Presumably a running score across the season toward "the cup".

Console: one deprecation warning from the auth library (`The "lock" option is deprecated`). No errors.

---

## 2. Opening Casey's link (14:13:34 UTC)

`goto http://127.0.0.1:8791/?join=THEPTCQ5` → **Screen: invite landing** — `../screenshots/join/02-invite-landing.jpg`

OBSERVATION: The URL bar immediately rewrote itself to the bare root (`http://127.0.0.1:8791/`) — the `?join=THEPTCQ5` vanished. The same door appears, with the email field already open and one extra monospaced line under it:

> "You're invited to The Papago Grind. Enter your email and you're in."

Both "Continue with email" AND "I have an invite code" are still shown above the email box.

Pre-join questions (what the link landing answers):
| Question | Answered? | Evidence |
|---|---|---|
| What am I joining? | **Partially** — a name only | "You're invited to The Papago Grind." Nothing says what a Papago Grind *is* (a league? a season? a tournament?). |
| Who is participating? | **Not answered** | No names, no count, not even Casey's name. |
| What does the season look like? | **Not answered** | No dates, no length, no format. |
| The rules? | **Not answered** | Nothing. |
| Stakes / money? | **Not answered** | Nothing. |
| How long does it last? | **Not answered** | Nothing. |
| What commitment is expected? | **Not answered** | Nothing — not "post a round a month", not "play every week", nothing. |

INTERPRETATION: The landing treats the invite as an authentication shortcut, not as an invitation. "Enter your email and you're in" is the whole pitch. A person who is cautious about money or time has nothing to evaluate.
IMPACT: The persona's key question — "can I understand what I'm joining before accepting?" — is answered **no** at the point of commitment.

USER ASSUMPTION: I have a code, and there's a button that says "I have an invite code", so I should tap it.
ACTUAL PRODUCT BEHAVIOR: Tapping it (14:13:50) swapped the email box for a "LEAGUE CODE" box + "Join" button (`03-invite-code-tap.jpg`), while the caption above it STILL said "Enter your email and you're in." Three words for one thing in two taps: *invite code* (button) → *LEAGUE CODE* (placeholder) → and later "sign-in code" (a different code entirely).

Typed THEPTCQ5 → Join (14:14:20) → `04-after-code-join.jpg`: the code field stays, an email field + "Go" appears BELOW it, caption changes to:
> "Enter your email — you'll join The Papago Grind the moment your sign-in code lands."

Now five stacked controls on one screen (Continue with email / I have an invite code / THEPTCQ5 + Join / email + Go) and the Terms link is pushed off the bottom of the phone. The two top buttons are dead weight at this point — they stay bright and tappable but I have already gone past them.

Note: the link-landing was redundant with the code — the link pre-filled nothing visible about the code; I re-typed the code the link already contained. (Whether the link alone would have joined me, I cannot tell; the screen gave no indication the code was "already applied".)

---

## 3. Sign-in: the email code never arrived (14:14:45 → ) — **P0 BLOCKER**

- 14:14:45 typed jerecho+blind2@fischbeck3.com → Go. Screen: "Sent to jerecho+blind2@fischbeck3.com. Type the sign-in code from the newest email." + "Resend code (25s)" countdown. `05-after-email-go.jpg`, `07-signin-scrolled.jpg`. Now SIX stacked controls; "CODE FROM EMAIL" + "Verify" is the sixth row, half off-screen until I scroll.
- 14:15:37 no email. 14:16:23 no email (inbox or spam). Other testers' codes (blind3, blind4) landed at 14:14:05 and 14:14:18 — seconds before my request — so the pipe was working for them.
- 14:16:43 tapped "Resend code" → "Fresh code sent to jerecho+blind2@fischbeck3.com — the newest email wins." Nothing arrived by 14:17:35, 14:18:59.
- 14:19:21 tapped "Go" again (what a person does when they think they mis-tapped) → "Sent to …". Nothing by 14:20:19, 14:21:39.
- Console: clean (one library deprecation warning). No error surfaced to the user at any point.

OBSERVATION: Three times the app asserted an email was sent; zero emails arrived in 7+ minutes; no error, no "try again later", no "we're rate-limited", no alternate path.
INTERPRETATION: Either a silent send failure or a throttle that the UI reports as success. From the user's chair these are the same thing: the app lied three times.
IMPACT: A real Marcus has now texted Casey "your app doesn't work" and put his phone down. For a friend-invited joiner, this is the whole funnel.

### 3a. What I did while stuck at the door: the Terms page (14:22 UTC) — `08-terms.jpg`

A person stuck waiting for a code, wondering whether money is involved, might tap "Terms". I did. `/legal.html` is a plain page with three sections: Privacy Policy · Terms of Service · Prize Pool Disclaimer.

OBSERVATION: The **Prize Pool Disclaimer** is the first and only place before sign-in that explains what the product is or that money can be involved:
> "CupSeason is a golf league management app for private groups who play real, handicapped golf together."
> "Any prize pool shown in the app is managed entirely by league organizers and participants… CupSeason does not collect, hold, transfer, or distribute money…"
> "If you are unsure whether a money pool is allowed where you live, keep your league to bragging rights."

INTERPRETATION: The clearest one-sentence description of Cup Season lives in the legal disclaimer, and so does the only pre-signin hint that leagues can have money on them. A joiner learns "there might be a prize pool" from the lawyer, not from the invitation.
IMPACT: For a new joiner the money question is the single biggest "what am I agreeing to?" — and it is buried on a page most people never open.
Also on this page: the contact address is a personal email (`jerecho@fischbeck3.com`), and the "Prize Pool Disclaimer" is a third tab on a page whose door only advertised "Terms & Privacy Policy".

- 14:23:23 fourth send attempt, this time via the plain link landing (email → Go). "Sent to jerecho+blind2@fischbeck3.com." again.
- 14:25:08 nothing (inbox, spam, anywhere). 10.5 minutes since the first send, 4 attempts, 4 on-screen "Sent" confirmations.

### Running glossary at the door (before ever getting in)
| Term | Where seen | What I think it means | Confusing? |
|---|---|---|---|
| cup | door tagline "Take the cup." | a trophy for whoever wins | yes — never defined |
| season | app name | a stretch of time the competition runs | yes — undefined |
| crew | "Rally your crew." | my friend group | no |
| real rounds | "Post real rounds." | scores from actual golf, not a video game | mostly clear |
| invite code | door button | the code Casey texted | clear, but then renamed |
| LEAGUE CODE | placeholder after tapping the button | same code as above, different name | yes — two names, one thing |
| league | placeholder only | the group ("The Papago Grind"?) | yes — assumed |
| sign-in code | "you'll join … the moment your sign-in code lands" | an emailed 8-digit code | yes — a third "code" within two screens |
| The Papago Grind | invite line | Casey's league, named after Papago Golf Course presumably | what *kind* of thing it is is never said |
| prize pool | legal page only | money the group plays for | yes — first mention is the disclaimer |

### Confusion debt accrued before entering
1. What a "league" is and whether The Papago Grind is one.
2. What a "season" is and when this one starts/ends.
3. What "the cup" is.
4. Whether money is involved (only the legal page hints yes).
5. Whether entering my email = agreeing to join (the copy says "you're in", but nothing says what "in" commits me to).
6. Whether I should tap "Continue with email" or "I have an invite code" when the link already opened an email box.
7. Whether the link had already applied the code, or I needed to type it again.
8. Why "Sent" four times produced no email.
- 14:28:38 **Diagnostic:** sent a code to a variant of my own address (jerecho+blind2x@fischbeck3.com) via the link landing. "Sent to jerecho+blind2x…". Nothing by 14:29:35. Conclusion: not address-specific — **no email from noreply@cupseason.app has been delivered to ANY tester since 14:14:18 UTC.** The app kept reporting "Sent" throughout.

### Pre-join issues (recorded while stuck)
- **J-01 (P0, onboarding)** Sign-in email never arrives; the app says "Sent" every time and offers no error state. Five attempts across two addresses, 15+ minutes.
- **J-02 (P0, comprehension)** The invite link answers none of "what am I joining / who / when / rules / money / how long / what's expected". Its entire content is "You're invited to The Papago Grind. Enter your email and you're in."
- **J-03 (P1, onboarding)** No invitation email was ever sent to the invitee; the whole invitation is whatever the friend pastes into a text.
- **J-04 (P1, navigation)** The link landing keeps both "Continue with email" and "I have an invite code" live above the pre-opened email box; a code-holder doesn't know which path is theirs. I took the wrong one and re-typed a code the link already carried.
- **J-05 (P1, terminology)** invite code → LEAGUE CODE → sign-in code: three labels, two different things, within three taps.
- **J-06 (P2, visual-hierarchy)** The sign-in sheet accretes: by the code step there are six stacked rows; the active row ("CODE FROM EMAIL"/Verify) is the last one and sits half off-screen; Terms link scrolled away.
- **J-07 (P1, monetization)** First mention of money/prize pools is in the legal page's "Prize Pool Disclaimer"; the door and the invite say nothing.
- **J-08 (P2, comprehension)** The clearest statement of what the product is ("a golf league management app for private groups who play real, handicapped golf together") lives on the legal page, not the door.
- **J-09 (P3, polish)** Version caption shows the raw placeholder "v23 · __CS_VERSION__" to the user on this build.
- **J-10 (P2, comprehension)** Copy contradiction: after tapping "I have an invite code", the caption still reads "Enter your email and you're in" above a field labelled "LEAGUE CODE".
- **J-11 (P2, onboarding)** The URL strips `?join=` instantly; if the page reloads or the user switches apps to fetch the code, is the invite still attached? Nothing on screen says. (Later verified: after a fresh `goto` of the bare root the invite line was gone — the link must be re-opened.)

### Timeline of the outage as I experienced it
| UTC | What I did | What the app said | Email arrived? |
|---|---|---|---|
| 14:14:45 | link → code path → email → Go | "Sent to jerecho+blind2@fischbeck3.com. Type the sign-in code from the newest email." | no |
| 14:16:43 | Resend code | "Fresh code sent to jerecho+blind2@fischbeck3.com — the newest email wins." | no |
| 14:19:21 | Go again | "Sent to …" | no |
| 14:23:23 | reopened link, email → Go | "Sent to …" | no |
| 14:28:38 | reopened link, variant address → Go | "Sent to jerecho+blind2x@fischbeck3.com" | no |
| 14:33 / 14:39 / 14:45 / 14:52 | polled inbox + spam | — | nothing for anyone since 14:14:18 |

What the door offers a person in this state: a "No code yet? Check spam for the newest Cup Season email — older codes retire when a new one sends." caption and a "Resend code" link with a ~28-second cooldown. There is no "something's wrong on our end", no "contact", no alternate sign-in, no status. The caption's advice ("check spam") is the only diagnosis offered, and it was wrong.
