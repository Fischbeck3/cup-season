# Cup Season — blind UX audit 2026-08-29 — User Journey Map

**What this is.** Seven blind personas drove the real product (headless iPhone-viewport browser, real prod accounts, prod build `34d20b6` — byte-identical `index.html` to what was tested, so every client defect below is live on cupseason.app) plus a look-only survey of the native iPhone app. This document walks the seven journeys the brief named — A Discovery · B Join · C Create · D First round · E Mid-season · F Finale · G Next season — as the testers actually lived them: who ran it, the path with timestamps and screenshots, the journey's required questions answered one by one with the exact copy that answered (or failed to answer) them, the USER ASSUMPTION / ACTUAL PRODUCT BEHAVIOR pairs pulled verbatim from the raw reports, the moments of hesitation with tap counts and elapsed time, and a verdict.

**Evidence conventions.** Raw reports are in `docs/audit/blind-ux-2026-08-29/raw/` and are cited by short name: **ORG** = agent5-organizer (Casey Ortega, +blind1) · **NOV** = agent3-league-novice (Dana Whitfield, +blind5) · **JOIN** = agent6-new-joiner (Marcus Bell, +blind2) · **CAS** = agent1-casual (Jordan Reyes, +blind3) · **COMP** = agent2-competitive (Priya Nair, +blind4) · **SKEP** = agent4-skeptic (Sam Kowalski, +blind6) · **OBS** = agent7-retention-observer (the owner's real account, read-only) · **IOS** = ios-screen-survey. Screenshots are cited as `shots/<session>/<file>.png` as the testers named them; the frames live in this folder as `screenshots/<session>/<file>.jpg` (742 tester frames, copied out of the session scratchpad by `tools/collect_screenshots.py`; the validator frames `screenshots/v-TOP-*/` stay `.png`; the folder is git-ignored). `index.html:N` is a line in the tested build. Findings keep **OBSERVATION / INTERPRETATION / IMPACT / RECOMMENDATION** separate. Where the spec or decision log explains something the UI did not, that is recorded as the finding, not as an excuse.

**Two runs.** CAS, COMP and SKEP ran twice: a clean first run at 14:12–14:45 UTC (structured results only, in `raw/persona-results.json` `_run: 1`) and a second run at 15:21 UTC on the same, now-contaminated accounts (the `.md` reports). The second-run agents found their accounts already signed in and already members, signed out through the app's own UI, re-did the cold door and the invite landing signed out, and said so in their blockers. Where this map quotes a first-run figure it says `(run 1)`. JOIN's first attempt (`raw/agent6-new-joiner-attempt1-harness-artifact.md`) reported "the sign-in code never arrived" as a P0; that was the mail connector hiding messages past the fifth in a Gmail thread — Supabase recorded every send. Only its door and Terms-page observations are used here.

**Method limits, stated once.** The headless browser has no native share sheet and a denied clipboard, so every "Share…" outcome below is the visible fallback, not what an iPhone would show. No in-season play could be observed (both audit leagues had first tee Sat Sep 5, seven days out). No finished season exists on any account, so Journeys F and G are reconstructed from what the live app says about endings, from the code, and from the observer's projection. The owner's two real leagues have two players each, which makes "biggest threat" trivial and "EVERYONE ADVANCES" literally true. The App Review sandbox was unavailable. The iOS survey saw static landing screens only, no taps. The harness auto-accepted native `confirm()` dialogs.

**Validation caveats that change two findings.** Fifteen independent validators re-tested the five headline findings against code, prod telemetry and live sessions (`raw/synthesis-and-validation-results.json`); all fifteen returned "Confirmed UX problem", but two sub-claims were refuted and are carried that way here: (1) the "You tab opens the wizard" symptom (CAS A1, COMP, JOIN J-02 tail) was reproduced live as a **harness artifact** — the driver's substring click on "You" matched "Lock it in and invite **you**r crew" (`shots/v-TOP-3i/01-after-click-You.png` vs `02-after-role-You.png`); the underlying finding (a member's Home CTA opens the Pro's wizard) stands. (2) The "✓ next to names who still owe" on the Pot tab (OBS, CAS run 1) is a transparent glyph picked up by the text dump; unpaid rows render an empty box. Also trimmed by validation: the bare "Invite code: X" toast is the **double fallback** (`navigator.share` → clipboard → toast, `index.html:14127`); a real phone likely gets an OS share sheet — but no surface except the never-reached post-lock sheet prints the join URL as text.

---

## Coverage matrix

| Journey | ORG | NOV | JOIN | CAS | COMP | SKEP | OBS | IOS |
|---|---|---|---|---|---|---|---|---|
| A · Discovery (cold door, 10 questions) | full | full | full | full (r1 + r2) | full (r1 + r2) | full (r1 + r2) | door only | landed signed-in |
| B · Join a league | opened own `?join=` link | — | full (clean) | full (r1 clean; r2 re-entry) | r1 clean; r2 re-entry | r1 clean; r2 re-entry | — | — |
| C · Create a league | full (lock ×6 failed) | full (lock ×6 "failed", succeeded) | reached wizard as a member | reached wizard as a member | reached wizard as a member | reached wizard as a member | — | name sheet only |
| D · First round | posted 87 | posted 91 | posted 87 | posted 97 (+103 written by another's game) | posted 74 + 84, live skins 18 holes | posted 91 (1 failed attempt) | form seen, nothing typed | post screen seen |
| E · Mid-season | pre-season proxy | pre-season proxy | pre-season proxy | pre-season proxy | pre-season proxy | pre-season proxy | full (two live leagues, wk 6/26 and 4/13) | Home + Clubhouse |
| F · Finale | copy only | copy only | copy only | copy only | copy only | copy only | copy + projection | copy only |
| G · Next season | — | — | — | — | — | — | answered | — |

Persona verdicts (1–10): ORG 3 · NOV 4 · JOIN 3 · CAS 4 (r1: 5) · COMP 5 · SKEP 3 (r1: 4) · OBS 4 · IOS 4 (r1: 4.5) — mean 3.75, median 4. `rulesClear` averaged 4.0 and `wouldPay` 3.75 (means of each family's latest run; the executive-verdict *medians* across all 12 result rows — `rulesClear` 4, `wouldPay` 3.5 — are in `blind-ux-audit.md` §1, where the method is stated once).

---

# Journey A — Discovery

**Who ran it.** Every web persona opened the cold door signed out: ORG and NOV at 13:18:42 UTC on brand-new accounts; JOIN at 15:21:36; CAS, COMP and SKEP first at 14:12:47 (run 1, new accounts) and again at 15:21–15:26 after signing out through the app (run 2). OBS saw the same door at 13:18 before signing in but was not asked the ten questions cold. IOS launched into a signed-in Home (a session already existed on the simulator), so the phone door was never seen.

## A.1 The door

Exact copy, all sessions (`screenshots/skep/02-cold-door.jpg`, `screenshots/org/01-door.jpg`, `screenshots/nov/01-door.jpg`, `screenshots/join/01-A-cold-door.jpg`; source `index.html:2635`):

> orange flag-in-cup mark · **CUP SEASON** · "Rally your crew. / Post real rounds. / **Take the cup.**" · [Continue with email] · [I have an invite code] · "By continuing you agree to the Terms & Privacy Policy." · `v23 · __CS_VERSION__`

Nothing below the fold (`screenshots/cas/10-A01-door-scrolled.jpg`; validator `shots/v-TOP-2/02-door-scrolled.png`). The desktop "The season, live" wing is `display:none` under 1100px (`index.html:1818-1819`), so the phone door is slogan-only by construction. The `<meta name="description">` at `index.html:22` already carries "Season-long golf with the people you already play with — points, pot, pressure" — a sentence the door itself never shows.

**Timing.** Door → signed in: ORG ~30 s (13:20:32 tap → code email 13:20:52 → auto-verified); NOV 13:19:35 → 13:20:18; JOIN 15:23:18 → 15:23:51 (email in 2 s); SKEP run 1 ~75 s; SKEP run 2 **3.5 min** (15:23:44 → 15:27:23), almost all of it hunting a Gmail thread of 20 identical "Your Cup Season sign-in code" subjects, one Resend. Every code auto-submitted on the 8th digit — "the 'Verify' button was gone before I could tap it" (ORG, NOV, CAS, COMP, SKEP, OBS all noted the affordance/behaviour mismatch).

### The 3 s / 10 s / 30 s reads

| Persona | 3 seconds | 10 seconds | 30 seconds — what could I do? |
|---|---|---|---|
| ORG | "Orange flag-in-a-hole logo, big serif wordmark, three-line slogan, one orange button. Definitely golf. 'Take the cup' means there's a trophy." | "'Post real rounds' — I'll be entering my actual scores. 'Rally your crew' — I bring my friends. 'Cup' — some kind of championship. Two ways in: email, or an invite code." | "I can tap 'Continue with email' to start. I can't do anything else. There is no 'how it works', no screenshot, no sample, no 'what is a season'. The bottom line `v23 · __CS_VERSION__` looks like a developer placeholder that leaked — small trust ding for an organizer about to ask six friends to sign up." |
| NOV | "Golf (flag), the word 'cup', 'crew'. Two buttons. It is a golf thing for a group." | "'Post real rounds' — I will type in scores I actually shot. 'Take the cup' — there is a prize/trophy. 'Rally your crew' — I am supposed to bring my friends. The invite code button tells me somebody else could have sent me a code, but nobody did, so I'm the one who starts." | "I could tap Continue with email. That is the only thing to do. There is no 'learn more', no 'how it works', no screenshots, no pricing. I have to sign up to learn anything." |
| JOIN | "An orange flag logo, 'CUP SEASON', a three-line slogan, one big orange button. Golf, friends, something you can win." | "'Post real rounds' implies I log scores; 'Take the cup' implies a prize; 'I have an invite code' implies groups are private. Nothing tells me whether it is fantasy golf, a handicap tracker, a betting app or a league manager." | "I could sign in with email or enter a code. That is all I could do. There is no 'how it works', no example, no screenshot, no pricing, no mention of money." |
| CAS | "A golf-ish flag, the name, three punchy lines, two buttons. It's a golf thing for a group ('crew'), you post scores, there's a cup to win." | "'Post real rounds' tells me I type in scores from actual golf, not a video game. 'Take the cup' says somebody wins something. No idea how, how long, or whether money is involved." | "The only things I can *do* are sign in with email or enter an invite code. There is no 'how it works', no screenshots, no preview. I would not tap Terms/Privacy (nobody does); I noticed the raw '__CS_VERSION__' string, which looks like a bug to a normal person." |
| COMP | "A golf app; something about a 'cup'; you post rounds. Dark, confident, looks like a real product." | "Three verbs — rally, post, take. It is social ('crew') and competitive ('take the cup'). I do not know what the cup is, how long a season is, or whether money is involved. I have no idea what 'real rounds' means (GHIN? attested? photos?)." | "I can either sign in with email or enter an invite code. There is nothing else to do; no 'how it works', no screenshots, no preview of a league. Everything I know comes from the tagline." |
| SKEP | "Golf (the flag), a competition ('cup'), a friends thing ('crew'). Orange-on-black, looks like a sports-betting app." | "I can sign in with email or with a code someone gave me. 'Post real rounds' — so I type in scores. 'Take the cup' — win something. Nothing tells me WHAT the cup is, how long a season is, whether it costs money, or how it differs from 18Birdies." | "I could sign up. I could not tell you what I'd be signing up FOR. There is no 'how it works', no screenshots, no example, no 'learn more'. **The door is a wall with two handles.**" |

Terms/Privacy: ORG and (first-attempt) JOIN opened `/legal.html`. Both found that the **Prize Pool Disclaimer** explains the product better than the door: "CupSeason is a golf league management app for private groups who play real, handicapped golf together … does not collect, hold, transfer, or distribute money, takes no fee or cut of any prize pool" (`screenshots/org/04-legal.jpg`, `screenshots/join/08-terms.jpg`). ORG: "this is important information … and I only found it in the legal fine print."

### The invite-link door (`/?join=THEPTCQ5`, signed out)

Same door plus an auto-opened email box and one monospaced line: **"You're invited to The Papago Grind. Enter your email and you're in."** (`screenshots/join/02-B-join-link-landing.jpg`, `screenshots/cas/11-A02-join-link-cold.jpg`, `screenshots/skep/03-join-link.jpg`; `index.html:17832/17914`). The URL is rewritten to `/` on load (`index.html:17815-17819`); the `?join=` survives only in `localStorage`. Both big buttons stay above the box (CAS A27, SKEP SK-30, COMP C2-26). Tapping "I have an invite code" swaps the email box for a field labelled `LEAGUE CODE` while the caption still says "Enter your email and you're in" (JOIN, `screenshots/join/03-C-invite-code-tap.jpg`). The anon RPC behind the landing, `league_by_code`, returns only the league's **name** (validator TOP-2, migration `20260714040000:14-17`), so the landing cannot show more than it does.

## A.2 The ten discovery questions — BEFORE (cold, signed out)

Sources: each report's "Journey A" section; run-1 answers from `raw/persona-results.json`. Cells are condensed; the reports carry the full sentences.

| # | Question | ORG (Casey) | NOV (Dana) | JOIN (Marcus) | CAS (Jordan) | COMP (Priya) | SKEP (Sam) |
|---|---|---|---|---|---|---|---|
| 1 | What does the app do? | "Golf friends compete over a stretch of time by entering real scores; someone 'takes the cup'." | "Track golf rounds you actually play, with a group of friends, and somebody wins a 'cup' at the end of a 'season'. Beyond that, no idea." | "Golf buddies post rounds and compete for a 'cup'; how, unknown." | "A golf thing for a group of friends: post real scores, somebody wins a cup." | "Tracks golf rounds among friends and turns them into a season-long competition for a 'cup' — inferred from three tagline sentences only." | "A golf thing where buddies post scores and someone 'takes the cup' — can't tell if it's a day, a month, a year, a ladder or a fantasy league." |
| 2 | Primary action? | "'Continue with email' — sign up. After that, presumably 'post a round'." | "'Continue with email' — sign up. In-app, presumably 'post a round.'" | "Continue with email / I have an invite code." | "Continue with email (sign in)." | "'Continue with email' (only real button); presumably post a round." | "Continue with email (sign up) — nothing else to do." |
| 3 | What is a "season"? | "A multi-week window during which rounds count; unknown length." | "A stretch of time … during which rounds count. Not stated anywhere." | "Guess: months during which rounds count; not stated on the door." | "Not defined; guessed a few months." | "Guess: a stretch of months in which rounds count." | "Not defined; guessed 'the fall'" (from Casey's text, not the app). |
| 4 | What is a "league"? | "My friend group; joined with a 'LEAGUE CODE'." | "Word not on the door; 'crew' used. Assumed league = my group of friends." | "Word absent from the door; assumed a group of friends." | "Word absent from the door; guessed 'your group'." | "Not on the door; guess: my friend group ('crew')." | "Word absent from the door; assumed 'our group'." |
| 5 | What is a "cup"? | "The trophy at the end of a season; maybe a playoff." | "A trophy; real, badge or money unknown." | "Trophy for the season winner; not stated." | "The trophy for winning; real, cash or bragging unknown." | "Unknown — a trophy? a playoff? the logo is a flag, not a cup." | "No idea." |
| 6 | Competing for? | "The cup / bragging rights; legal page mentions prize pools." | "'The cup' — bragging rights or money, unknown." | "'The cup'; money unknown." | "The cup; money not mentioned." | "Unknown ('the cup'). Money? Bragging rights?" | "Unknown. 'The cup.' No mention of money." |
| 7 | Against whom? | "My crew; maybe teams." | "My buddies; individual vs team unknown." | "'Your crew'; individuals vs teams unknown." | "Your crew." | "Presumably Casey's invitees; individual or team unknown." | "'Your crew.'" |
| 8 | How do rounds work? | "Play anywhere, type in a score; gross/net unclear." | "Go play anywhere, type the score in; gross/net/course relevance unknown." | "Type a score after playing, presumably." | "Post real rounds — how, unknown." | "Enter a score after I play; 'real rounds' hints at verification, method unknown." | "Type a score after playing; no idea what's required or how handicapped." |
| 9 | After a round? | "Unknown; points or leaderboard." | "Nothing said; assumed a leaderboard updates." | "Unknown." | "Unknown." | "Unknown; probably points." | "Unknown; presumably a leaderboard moves." |
| 10 | Different from golf with friends? | "Keeps a running score across rounds and crowns a winner." | "Presumably keeps score across rounds and crowns a winner; not stated." | "A running score across rounds, presumably." | "A running tally and a cup." | "Door doesn't say; guess: keeps score across a season." | "Door gives nothing to answer this with." |

Six of six: "unknown" or a guess on every question except #2. The word "league" does not appear on the door (four testers flagged it independently). The two words in the product's name — "cup" and "season" — were undefined for all six.

## A.3 The ten questions — AFTER (end of session, 28–48 minutes in)

| # | Question | ORG | NOV | JOIN | CAS | COMP | SKEP |
|---|---|---|---|---|---|---|---|
| 1 | What does the app do? | "A months-long league where every real round posted anywhere scores 5–12 points vs your own handicap, best 4/month count for a blind-drawn squad, ending in a 4-week Cup Final; keeps a money ledger; runs live side games with guests; also short 'events'." | "A months-long handicap-golf competition among friends … points accrue to your squad, last 4 weeks are a playoff for a cash pot the organizer collects; plus live side games with guests." | "A months-long league between friends: rounds scored against your own handicap into points, points stack for a squad, a pot pays out at the end." | "Season-long points competition … each round scored 5–12 pts vs your own handicap; best 4/month count for your squad; live side games and a tracked money pot." | "A months-long, handicapped, two-squad golf league from posted rounds with a tracked money pot, plus a live scoring pencil for money games." | "A season-long competition … best 4 a month count for a randomly drawn squad, 2-round monthly floor, 4-week Cup Final decides a $250 pot the app tracks but doesn't hold. Assembled from a welcome sheet, a scoring sheet, a collapsed bylaws accordion and a guide at the bottom of the profile tab." |
| 2 | Primary action? | "Post a round via the ⊕. For an organizer it was 'Start a league', which dead-ended at Lock." | "Post a round (orange +). For an organizer the real job is getting 3 more people in, which the app does not treat as primary." | "Post rounds via the unlabeled + — but my Home still shouts 'Lock it in and invite your crew'." | "Post a round after you play (the ⊕)." | "The ⊕: Post a round after you play, Play now during. The door never says so." | "Post a round via the ⊕." |
| 3 | Season? | "N months from a 'first tee' date (4 mo · Sat Sep 5 → Sat Jan 2 · 17 wks), calendar-month caps/floors, last 4 weeks = Cup Final. Never defined in one place." | "A fixed run of N weeks (13, Sat Sep 5 → Sat Dec 5) with monthly caps/floors and a 4-week Cup Final." | "Sat Sep 5 → Sat Jan 2 · 17 wks · 4 mo, monthly caps/floors, Cup Final last 4 weeks." | "Sep 5 → Jan 2 (17 wks); last 4 weeks a 'Cup Final · scored fresh' (still undefined)." | "Sat Sep 5 → Sat Jan 2, 17 weeks … learned from the bylaws table only." | "Sat Sep 5 → Sat Jan 2, 17 weeks, monthly closes, final 4 weeks — learned only from the bylaws." |
| 4 | League? | "Group + bylaws + pot + board, made by 'the Pro', joined by code; has squads; also called 'your groups' and 'the room'." | "A named group with locked 'bylaws', squads, a pot and a board; 'buddies' are a separate points-free thing." | "The group + bylaws + pot; its room is the Clubhouse." | "Named group with a code, an organizer ('the Pro'), bylaws, a pot and 2 squads." | "Named group with a Pro, code, bylaws, pot, board, and two blind-drawn squads — squads were a surprise." | "A named group with a Pro, bylaws, a pot, two squads and a board." |
| 5 | Cup? | "**Still fuzzy**: 'Take the cup', 'Cup Final', 'Cup champs', 'full cup experience', and 'Cups & events · 1 · played in' all use the word differently." | "The trophy AND the name of the optional 4-week end playoff." | "**Still never defined**; inferred from 'Cup champs' and 'Cup Final'." | "**Still unclear** whether the cup is the squad race or the whole season." | "**Still fuzzy** … this is the app's name and I still can't define it." | "**Still not defined in a sentence anywhere**; best guess = the Cup Final whose winners take 60%." |
| 6 | Competing for? | "The pot (60/25/15), display-case trophies, Points King / Most Improved / Iron Man, bragging rights, $ per side in side games." | "A cash pot (default $75/player hidden behind Customize; I set $25) split 60/25/15, plus Most Improved, Iron Man, badges." | "$250 pot: 60% champs / 25% runner-up / 15% Points King, plus trophies." | "$250 pot (60/25/15) + display-case trophies." | "60/25/15 of the pot + Most Improved, Iron Man, display-case trophies." | "$150 to the winning squad (split unknown), $63 runner-up, $38 Points King, plus badges." |
| 7 | Against whom? | "Two blind-drawn squads for the cup; every individual for Points King; my playing partners for side games." | "My squad vs the other squad(s); individually vs everyone for Points King." | "Two blind-drawn squads of the five of us; I don't know mine." | "My squad vs the other squad, plus every individual for Points King / Most Improved / Iron Man." | "My squad vs the other squad (not drawn yet) and everyone individually for Points King." | "My squad vs the other squad (blind draw) plus individual races — did not learn it was a team game until tab six of the league room." |
| 8 | Rounds? | "Post front/back gross + tee after any round, or score live; app computes differential, compares to my index, bands into points; guests can play live without accounts." | "Front/back gross + course & tee; (gross − rating) × 113 / slope vs my index → 5–12 points; best 4 a month; 2/month floor." | "Gross + tee + date; app computes differential vs index; bands 5–12 pts; best 4 per month count." | "Front/back gross + course/tee → differential → band points; or live hole-by-hole." | "Gross + tee (rating/slope) + date → differential → band vs my index; 9 holes at half value; or score live (auto-attested); or scan." | "Gross front/back + tee → differential vs rating/slope → compared to my index → 5–12 points; best 4/month; 2/month floor." |
| 9 | After a round? | "Result sheet + badges + board story + receipt with formula; points to squad only if the season has started (mine hadn't — form still promised 6)." | "Card + celebration + board post; points to standings — except before the first tee, when they don't, and Home/form/Clubhouse disagree about it." | "A card, trophies, a feed post, a receipt with math; whether it counted for the league — unknown." | "A card with gross + 'X over your number', a receipt, a feed item; points/standings did not move for me." | "A band, a board card, badges, a share card; counts for the season only once it starts (never stated — my two rounds show 0)." | "Posts to the Board and my card with a receipt; pre-season it changed nothing in the standings and the app did not say why." |
| 10 | Different from golf with friends? | "Every round anywhere counts for months; you can't hurt your squad by playing badly; the app referees handicaps, strokes, side bets and money. A real pitch the door never makes." | "Every casual round counts for months; bad rounds still score; daily players can't bury weekly ones; ghosting penalised; receipts show the math — learned from a help sheet four taps deep." | "Handicap-normalised points so a 15 and a 6 compete evenly, a running table, a pot on the books." | "Handicap-relative points make a 97-shooter and an 80-shooter equals … Real idea, buried at the bottom of the You tab." | "A standing table with a participation floor, a money ledger, and live games that settle themselves." | "A fair points race across handicaps from any course, with a pot ledger and a final — genuinely different, and the least visible thing in the product." |

**What the AFTER column shows.** Every persona rebuilt spec §1's POST → SCORE → COUNT pipeline almost verbatim. Not one could define "the cup" (question 5 stayed "fuzzy" for 6/6 after 30–48 minutes), and the answer to "what makes this different" — the product's actual pitch — was found by each of them "at the bottom of the You tab", "four taps deep", "in a collapsed bylaws accordion". The door taught none of it.

## A.4 Required questions — answered by what copy?

| Required question | Answered on the door? | Copy that answered / failed |
|---|---|---|
| What is this? | No | "Rally your crew. Post real rounds. Take the cup." — SKEP: "'Rally / post / take' is a slogan, not a mechanism." The one-sentence definition exists on `/legal.html` ("a golf league management app for private groups who play real, handicapped golf together") and in `index.html:22`'s meta description; neither renders on the door. |
| How long? | No | Nothing. First stated in Clubhouse after joining: "Sat Sep 5 → Sat Jan 2 · 17 wks". |
| Does it cost money? | No | Nothing on the door or invite landing. First stated after account creation: "Before you join The Papago Grind … BUY-IN $50 / player" (Journey B). SKEP: "If Casey hadn't texted me, I'd close the tab." |
| What do I win? | No | "Take the cup." First stated on the Pot tab post-join: "$150 Cup champs · $63 Runner-up · $38 Points king". |
| Team or individual? | No | Nothing until the collapsed bylaws: "STRUCTURE 2 squads · Squad formation Blind draw" (SKEP: "tab six"). |
| What is a round worth? | No | Nothing until the post form's POINT BANDS. |
| Is it finished software? | Damaged | `v23 · __CS_VERSION__` (8/8 noticed; local build artifact — prod stamps the SHA — but a P3 to fix in the placeholder path regardless). |

## A.5 USER ASSUMPTION / ACTUAL PRODUCT BEHAVIOR (verbatim)

- **UA:** "The door will tell me what a season is / what I win." **APB:** "Only 'Rally your crew. Post real rounds. Take the cup.'" (CAS)
- **UA:** "'invite code' and 'LEAGUE CODE' are the same thing." (ORG) **APB:** They are; the button says invite code, the field says LEAGUE CODE, the toast later says "Invite code:", the chip says "Code ·" — "three names for one thing" (JOIN J-15).
- **UA:** "the app is free (nothing says otherwise)." (ORG) **APB:** A $50–$75 buy-in and a "membership [that] lands at launch" appear later; no price anywhere.
- **UA:** "'the cup' is a trophy at the end of a season." (ORG) **APB:** Used in four senses (cup, cup points, Cup Final, Cup champs, "Cups & events · 1 · played in"); never defined.
- **UA:** "the link in the text will show me the league before I sign in." (SKEP) **APB:** "You're invited to The Papago Grind. Enter your email and you're in." — the league name and nothing else.
- **UA:** "'I have an invite code' will take me to a place where I type THEPTCQ5 and land in Casey's league." (SKEP) **APB:** It swaps the email box for a `LEAGUE CODE` box and still asks for email; JOIN "re-typed a code the link already carried".

## A.6 Hesitation moments

| Moment | Who | Taps / time |
|---|---|---|
| Which button — "Continue with email" or "I have an invite code" — when the link already opened an email box | JOIN, CAS, COMP, SKEP | 1 wasted tap (JOIN typed the code again); "momentary 'do I still need to press these?'" (CAS A27) |
| Hunting the sign-in code in a threaded inbox | SKEP r2 3.5 min; CAS r2 one Resend; COMP r2 ~3 min; OBS 12 min (tooling) | Product delivery was 1–3 s in every case; the subject line "Your Cup Season sign-in code" threads 20 codes together (SKEP SK-28) |
| Reading Terms to find out whether money is involved | ORG, JOIN attempt 1 | 1 tap → new tab, no in-app feedback (ORG ORG-40) |

## A.7 Major findings

**A-F1 · P1 · The door sells nothing but a slogan.** OBSERVATION: nine words, two buttons, no how-it-works, no example, no cost, no length; 6/6 cold answers "unknown". INTERPRETATION: D83 retired the demo and made the door auth-only; the only explanatory layer (desktop wings) is `display:none` on phones (`index.html:1818`). IMPACT: activation rests entirely on the friend who sent the code — "The only reason I continue is social obligation" (SKEP). RECOMMENDATION: put the Guide's own sentence and a three-card how-it-works on the door (what a round becomes, best-4 + floor, how the season ends), above the buttons.

**A-F2 · P1 · The invite landing is an auth shortcut, not an invitation.** OBSERVATION: "You're invited to The Papago Grind. Enter your email and you're in." — no Pro, roster, dates, buy-in or format; `league_by_code` returns `name` only. INTERPRETATION: the link was built as plumbing ("rides the existing cs_code auto-join machinery", `index.html:17813`), not as the artifact the growth model depends on. IMPACT: the product's only acquisition channel carries no pitch and no stake; the $50 is disclosed after account creation (Journey B). RECOMMENDATION: extend the anon covenant RPC to return Pro, count, dates, pot and split; render a league card above the email box; fix the landing copy to "Sign in to review The Papago Grind — you'll confirm before you join." (validator TOP-2 fix, verbatim).

**A-F3 · P3 · Raw version placeholder.** OBSERVATION: `v23 · __CS_VERSION__` on the door and in Settings. INTERPRETATION: unstamped local build (prod stamps the SHA). IMPACT: to a skeptic it "reads as unfinished software" before a single tap. RECOMMENDATION: render nothing when the placeholder is unreplaced.

## A.8 Verdict — 3/10

The door answers exactly one of the seven questions a golfer brings to it (how to sign in) and damages a second (is this finished?). Sign-in itself is fast and the auto-verify is good. But six of six testers left the door unable to say what a season is, what the cup is, whether money is involved, or whether they would be on a team, and the two who read the legal page learned more there than on the product. Every AFTER answer in A.3 was assembled from surfaces that sit two to four taps deep after commitment; the discovery journey teaches nothing and defers everything to the friend who sent the text.

---

# Journey B — Join a league

**Who ran it.** JOIN (Marcus, +blind2) ran the clean, timed path from Casey's text to membership at 15:22–15:28 UTC. CAS, COMP and SKEP joined The Papago Grind (code THEPTCQ5) on fresh accounts in run 1 (14:13–14:20 UTC) and re-entered via the invite link signed out in run 2. ORG opened `/?join=THEPTCQ5` himself at 14:05:53 to see what his friends would be told. The invitation in every case was a text from "Casey Ortega" with a link and the code; three testers searched Gmail for an invitation email and found none — the only league-related mail in the inbox was a buddy request, "Priya wants in your crew", addressed to Casey (JOIN §0, SKEP, CAS).

## B.1 The path, step by step (JOIN, clean run)

| UTC | Step | Copy on screen | Screenshot |
|---|---|---|---|
| 15:21:36 | Cold door | "Rally your crew. Post real rounds. Take the cup." | `screenshots/join/01-A-cold-door.jpg` |
| 15:22:08 | Opened `/?join=THEPTCQ5` — URL rewritten to `/` immediately | "You're invited to The Papago Grind. Enter your email and you're in." | `02-B-join-link-landing.jpg` |
| 15:22:33 | Tapped "I have an invite code" | `LEAGUE CODE` field + Join; caption still "Enter your email and you're in" | `03-C-invite-code-tap.jpg` |
| 15:22:53 | Typed THEPTCQ5, Join | Code row stays; email row appears: "Enter your email — you'll join The Papago Grind the moment your sign-in code lands." | `04-D-after-code-join.jpg` |
| 15:23:18 | Email, Go | Third row: `CODE FROM EMAIL` + Verify; "Sent to … Type the sign-in code from the newest email." below the fold | `05-E-after-go.jpg` |
| 15:23:20 | Email arrived (2 s) | Subject "Confirm your email address"; body "Welcome to Cup Season · Your sign-in code: 73603342 · Type it on the sign-in screen." — nothing about the league or Casey | — |
| 15:23:51 | Pasted code → signed in without tapping Verify | "✓ SIGNED IN · Set up your golfer card." — The Papago Grind not mentioned | `06-F-after-verify.jpg` |
| 15:24:49–15:25:04 | Golfer card: name, handle (auto-changed to @marcus), index 12, marker THE SAGUARO, Save | "Just a name and a marker to start — this card follows you into every league." | `09-H-card-filled.jpg` |
| 15:25:04 | Orientation | "Four places. Two ways to play. Thirty seconds, then you're in." — **first definition of "league"**: "A league · MONTHS. EVERY ROUND COUNTS TOWARD A TABLE." | `10-I-after-save.jpg` |
| 15:25:19 | "Take me in" → consent sheet | "Before you join The Papago Grind · THE FINE PRINT, UP FRONT · BUY-IN $50 / player · on the pot sheet · PRESET Standard · PARTICIPATION FLOOR 2 rounds / mo · FINISH Cup Final · final 4 weeks · Joining puts you on the pot sheet for $50. Cup Season keeps the tab; money moves between you. · [Join — I'm in for $50] [Not now]" | `11-J-after-take-me-in.jpg` |
| 15:25:50 | Tapped "Not now" to look around | Invite gone; Home "LEAGUE · None yet · JOIN OR START"; a status "Not joined — use code THEPTCQ5 whenever you're ready" existed in the accessibility tree and never appeared on screen | `12-K-not-now.jpg` |
| 15:26:12 | "Join a league" | Empty "Join with a code" sheet — code not pre-filled | `13-L-join-a-league.jpg` |
| 15:27:26 | Re-typed the code → consent sheet again | same four rows | `15-M-rejoin-sheet.jpg` |
| 15:27:46 → 15:27:50 | "Join — I'm in for $50" → **member** | "Welcome to The Papago Grind · THREE THINGS TO KNOW" (four bold items) | `16-N-after-join.jpg`, `17-N-after-join-full.jpg` |

**Elapsed: 5 min 42 s from link to member; 13 taps, 4 text fields, one email round-trip, one code typed twice** (about 4 min without the deliberate "Not now" detour). CAS run 1 measured the same shape: door → signed in ≈ 30 s; join gate → joined ≈ 6 min because of a "Not now" detour "hunting in the You tab before daring to join" (CAS r1 A2). SKEP run 1: link 14:13:54 → signed in 14:16:35 → card saved 14:17:50 → "joined for $50" 14:19:30 (5.5 min).

## B.2 Pre-join — could the joiner understand what they were joining?

Everything visible before the "$50" button, in order: the text (link + code + name), the landing line, the code screen, the sign-in email, the golfer card, the orientation card, the consent sheet.

| Question | Verdict | Exact copy that answered (or did not) |
|---|---|---|
| What am I joining? | **Partially — at the very last step** | Landing: "You're invited to The Papago Grind." Consent: "Before you join The Papago Grind · THE FINE PRINT, UP FRONT". What kind of thing a league is: only the orientation card's "A league · MONTHS. EVERY ROUND COUNTS TOWARD A TABLE." three screens in. |
| Who is participating? | **Not answered** | No names, no count, not even "Casey invited you". Roster (Priya, Jordan, Sam, Casey, Marcus) appears after joining, in Clubhouse › Members. |
| What the season looks like | **Partially** | "FINISH · Cup Final · final 4 weeks". No start date, end date or length before commit (after: "Sat Sep 5 → Sat Jan 2 · 17 wks"). |
| The rules | **Not answered** | "PRESET · Standard" — undefined; tapping it does nothing (SKEP r1 SK-03). Point bands only in the post-join "How scoring works". |
| Stakes / money | **Amount yes, mechanics no** | "BUY-IN · $50 / player · on the pot sheet" · "Joining puts you on the pot sheet for $50. Cup Season keeps the tab; money moves between you." Who to pay, how, by when, what can be won: none. |
| How long it lasts | **Not answered** | Only "final 4 weeks" of something of unknown length. |
| Commitment expected | **Partially** | "PARTICIPATION FLOOR · 2 rounds / mo". The consequence of missing it is not on the sheet (three different explanations appear later, B.5). |

The consent sheet is capped by what its RPC returns: `join_covenant_info` (migration `20260722211500`) returns only name / buyin / preset / floor / finish / structure, and `covenantGate()` (`index.html:15422-15440`) renders four of them. The Pro's name, member count, `seasons.starts_on/ends_on` and the point bands are one join away and not selected (validator TOP-2, confirmed in code). Validation also found that the signed-in boot path (`index.html:17506`) skips the covenant entirely — consent is bolted onto two of three join paths.

## B.3 During — friction log

| # | Moment | Copy / evidence | Reaction |
|---|---|---|---|
| 1 | Link landing is the same door plus one line | "Enter your email and you're in." (`02-B`) | "Who's in it? What is it? I have a code too — do I need it?" |
| 2 | "I have an invite code" | field `LEAGUE CODE`; status still "Enter your email and you're in" (`03-C`) | "Two names for one thing; contradictory instruction" |
| 3 | Entered code → Join | "you'll join The Papago Grind the moment your sign-in code lands." (`04-D`) | "Am I joined already? 'the moment your code lands' sounds automatic" |
| 4 | Go | third stacked row; status below the fold (`05-E`; SKEP r1: "Three stacked inputs (Join / Go / Verify)") | "Cluttered; I had to scroll to learn what happened" |
| 5 | Email | "Confirm your email address" / "Welcome to Cup Season · Your sign-in code…" | "Nothing about the league; reads like a generic account, not an invitation" |
| 6 | Signed in on paste | golfer card; The Papago Grind not mentioned (`06-F`) | "did the join happen?" |
| 7 | Golfer card | "Ball marker" grid of 14 famous-hole names, no explanation it is an avatar (`07-G`) | "What is a marker for?" (6/7 testers) |
| 8 | Orientation | "Home · Clubhouse · The ⊕ · You" · "A league · MONTHS…" (`10-I`) | "First definition of 'league' — three screens in" |
| 9 | Fine print | four rows + "Join — I'm in for $50" (`11-J`) | "$50 with no roster, no dates, 'Standard' undefined, 'pot sheet' undefined." CAS r1: "USER ASSUMPTION: I would be asked for a credit card immediately after tapping Join." SKEP: "the single most likely bail point — 'wait, fifty bucks for what?'" |
| 10 | "Not now" | Invite gone; Home "LEAGUE None yet" (`12-K`) | "Did I just decline Casey?" |
| 11 | "Join a league" → empty code box (`13-L`) | retyped the code | "The app knew my code (hidden status) and made me type it again" |
| 12 | Joined | "THREE THINGS TO KNOW" — four bold items | "'Squad', 'The Pro', 'your number', 'the board' — all new" |

The "Not now" loss is code, not chance: `cs_code` / `cs_code_name` are removed from `localStorage` before `covenantGate` runs ("so a failure can't loop", `index.html:17564`), so a decline leaves a 2.4 s toast and nothing else (validator TOP-2).

## B.4 Immediately after — the welcome sheet

Signing in through the link (or tapping Join) lands on Home under a sheet, "Welcome to The Papago Grind · THREE THINGS TO KNOW" (`screenshots/cas/15-B03b-welcome-full.jpg`, `screenshots/skep/05-after-verify.jpg`, `screenshots/org/95-join-link-view.jpg`; `index.html:17299`):

1. "**You're on the pot sheet: $50 buy-in.** The Pro tracks who's paid; money moves between you."
2. "**You can't hurt your squad by playing badly.** Only by not playing. Every posted round scores — a rough day is still points on the board."
3. "**Rounds score against your own number.** Beat your handicap and it's a big day, whatever you shot. Your best rounds each month count; a better round always bumps your worst."
4. "**The pot lives on the books.** Cup Season keeps the tab and shows who owes what; money moves between you."

then "How scoring works →" and "Who else plays with you? Growing the league isn't the Pro's chore — any member's link works. [Share the invite link]".

Five testers counted four items under "three" (CAS A11, SKEP SK-04, JOIN J-16, COMP, ORG). SKEP: "The first thing the product tells me after sign-up is that I owe $50. Casey's text did not mention money. The door did not mention money." ORG, seeing it as the Pro: "This is a good join covenant … **The Pro is never shown it** — I found it by typing the URL."

## B.5 "What do I do now?" — the finding

After the sheet closes, a member's Home is (`screenshots/join/20-P-home-member.jpg`, `screenshots/cas/19-C02b-home-full.jpg`, `screenshots/skep/09-home-full.jpg`):

> [Start a league] [Start an event] [Join a league — drawn highlighted] · "THE PAPAGO GRIND · FORMING · **7 days** to first tee. **5 golfers in.** *The bylaws lock at the tee.*" · ROSTER ▬▬▬ 5 IN · **[Lock it in and invite your crew]** · LEAGUE The Papag… OPEN THE ROOM · NEXT Open PLAN A ROUND · BOARD 6 NEW TODAY · "MONTH CLOSES in 2 days" · "Monthly floor · 2 rounds a month. Miss it and your squad loses 5 points for every round you're short. Short months are waived." · the ⊕ (unlabelled)

JOIN: "**Not obvious.** … As a person who just accepted a friend's invite, that button reads as somebody else's job, and 'lock' sounds irreversible. … There is no 'post a round' or 'here's what to do this week' for a member." CAS: "The honest answer to 'what do I do now' from the UI is 'wait 7 days', but the UI never says that; it shouts 'Lock it in' and 'Month closes'." SKEP: "Do I owe 2 rounds in the 2 remaining days of August, before the season even starts?" CAS r1 A7: "USER ASSUMPTION: Tapping it might lock the league for everyone. … I was afraid to tap it and did not know what to do next … I would have messaged Casey."

What the button does when tapped (JOIN 15:35:41, `screenshots/join/39-U-lock-it-in.jpg`; SKEP `screenshots/skep/50-lock-page.jpg`; COMP `screenshots/comp/19-lock-tap.jpg`): opens "CREATE YOUR LEAGUE · LOCKS AT FIRST TEE / REVIEW THE BYLAWS, THEN LOCK IT IN" pre-filled with Casey's bylaws and a live "Lock the bylaws & form the squads" button. "← Back" walks deeper into the wizard ("Competitiveness — pick once, argue never", then "League name · Pro — that's you · **Marcus @marcus · you run this league THE PRO**", `56-AI-you-escape.jpg`). "Cancel" prompts "Cancel this league? It hasn't started, so this discards it completely." and fails only because the server refuses: console `Could not discard. commissioner only`; toast "Could not discard. Something went wrong — please try again." No tester pressed the lock on the shared league. Code: `renderHomeHero`'s forming branch (`index.html:10072-10116`) builds `nextStep = { label:'Lock it in and invite your crew', go:toWiz(2, null) }` at `:10102` with no role check; D40's "a member must never see the Pro's configuration tool" backstop exists only in `enterLeague` (`:14500`). Validation (three lenses) confirmed it live on the joiner profile and added that the CTA is phase-blind too: The Papago Grind was already locked (`draft`), so this is the normal window every invited member lives in until first tee.

### The joiner's questions, answered from the app only (JOIN §6, with taps from Home)

| Question | Answer found | Where | Taps |
|---|---|---|---|
| What does the league mean? | "A league · MONTHS. EVERY ROUND COUNTS TOWARD A TABLE."; Clubhouse "Sat Sep 5 → Sat Jan 2 · 17 wks · THE PRO · CASEY" | orientation; Clubhouse header | 1 |
| What am I competing for? | "THE POT $250 · 5 × $50" → "$150 Cup champs · $63 Runner-up · $38 Points king"; "Points King / Most Improved / Iron Man" | Pot; Standings | 2 |
| Who am I competing against? | Priya, Jordan, Sam, Casey — but "2 squads · Blind draw" and both squads "Empty"; "I don't know my team or my opponents" | Members; See the squads | 3 |
| How does scoring work? | "Torched it · beat it by 3+ · 12 pts … Posted anyway · rough day · 5 pts"; "best 4 / mo" | How scoring works; Post form | 1–2 |
| How do I win? | Inferred only; "Cup Final · final 4 weeks · scored fresh" never explained | League › collapsed bylaws | 3 |
| What does each round mean? | "Every posted round scores"; 5–12 pts vs my own number | Post form | 1 |
| What if I miss a round? | Three versions: Home "your squad loses 5 points for every round you're short. Short months are waived." · scoring sheet "Miss it once and your season bye covers you automatically… the floor bites from the second miss" · bylaws "2 / mo · −5 sqd pts / round short" | Home; sheet; bylaws | 0–3 |
| What happens at the end? | "CUP FINAL Final 4 weeks · from Sun Dec 6 · scored fresh"; 60/25/15 | bylaws; Pot | 3 |
| Is there money involved? | Yes — $50, $250 pot, "Cup Season keeps the books. Buy-ins and payouts move friend-to-friend." How/when/to whom: **never stated** | fine print; Pot | 0–2 |
| What do I need to do next? | **Not stated.** Best guess: wait for Sep 5, then post 2+ rounds a month | Home hero | — |

## B.6 USER ASSUMPTION / ACTUAL PRODUCT BEHAVIOR (verbatim)

- **UA:** "opening the friend's link would show me the league (who's in, what it costs, when it runs) before asking for anything." **APB:** "the link shows one sentence, demands email + code, a profile, an orientation, and only then a four-line fine print with no people and no dates." (JOIN)
- **UA:** "'I have an invite code' and the link are two different things." **APB:** "they are the same code; tapping the button while on the link landing shows a 'LEAGUE CODE' box while the status line still says 'Enter your email and you're in'." (JOIN)
- **UA:** "'Not now' on the fine print means 'let me look around, I'll decide in a minute.'" **APB:** "the invite vanishes from view; Home shows 'LEAGUE · None yet · JOIN OR START'; the 'Join with a code' sheet is empty and I had to retype the code." (JOIN)
- **UA:** "Opening Casey's link = joined." **APB:** "Door + 'Enter your email and you're in'; the $50 fine print and covenant come after sign-in." (CAS)
- **UA:** "the invite link would show me the league (who's in, the stakes, when it starts) before asking for my email." **APB:** "the door only says 'You're invited to The Papago Grind. Enter your email and you're in.' The $50 buy-in is disclosed after joining." (COMP)
- **UA:** "'three things' means three." **APB:** "four paragraphs." (CAS)
- **UA:** "'The Pro' is a golf pro at a course." **APB:** "it's the league organizer, Casey." (CAS)
- **UA:** "'squad' = the whole league." **APB:** "the league is split into 2 squads by a blind draw; I'm not in one yet." (CAS)
- **UA:** "the big orange button on my Home is the thing I'm supposed to do." **APB:** "it launches 'CREATE YOUR LEAGUE · Review the bylaws, then lock it in' with a live 'Lock the bylaws & form the squads' button, pre-filled with The Papago Grind's bylaws." (JOIN)
- **UA:** "The Pot checkboxes are for me to tick when I've paid." **APB:** "'The Pro marks buy-ins as money moves between you.'" (CAS; toast only, invisible in the screenshot 1.5 s later — SKEP)

## B.7 Hesitation moments

| Moment | Who | Taps / time |
|---|---|---|
| Deciding "Join — I'm in for $50" with no roster, dates or rules | JOIN, CAS r1, SKEP r1 | JOIN: 31 s on the sheet then "Not now"; CAS r1: 2 min detour to the You tab "looking for reassurance before paying"; SKEP r1: joined "grudgingly" |
| Re-typing the league code after "Not now" | JOIN, CAS r1 | 3 taps + 8 characters; 1 min 36 s (JOIN 15:25:50 → 15:27:26) |
| Reconciling "you're in" with four more screens | JOIN, CAS, SKEP, COMP | interpretation only |
| Reading the member Home and not tapping the lock | CAS r1 ("afraid to tap it"), SKEP ("I didn't dare tap"), COMP ("refused to press Lock for fear of mutating Casey's league") | 0 taps, then exploration: JOIN tried OPEN THE ROOM, each tab, See the squads, Members, then the lock CTA, then the ⊕ — 6 detours before finding the post form |
| Sign-in code buried in a Gmail thread | SKEP r2 3.5 min; CAS r2 1 Resend; COMP r2 ~3 min | app delivery 2–3 s every time |

## B.8 Major findings

**B-F1 · P0 · The consent sheet withholds what the decision needs.** OBSERVATION: four rows — `BUY-IN $50 / player · on the pot sheet`, `PRESET Standard`, `PARTICIPATION FLOOR 2 rounds / mo`, `FINISH Cup Final · final 4 weeks` — then "Join — I'm in for $50"; no Pro, no roster, no dates, no scoring, no payment path (`screenshots/join/11-J-after-take-me-in.jpg`). INTERPRETATION: the sheet was scoped by setup-QA S3-01 as a money-surprise fix ("name the stake") and never grew into the offer; `join_covenant_info` does not select the roster count, Pro or season dates. IMPACT: JOIN verdict 3/10 — "Before the $50 button I knew: the league's name, that it costs $50 … I did not know who was in it (not even that Casey ran it), when it started or ended, how scoring worked, or how money moved." RECOMMENDATION: extend the RPC (pro_name, member_count, first names+markers, starts_on/ends_on/weeks, pot split, allowance, cap); render "Casey (THE PRO) invited you · 4 in so far · Sat Sep 5 → Sat Jan 2 · 17 wks", define "Standard" inline, add "How points work →" (the existing `openScoringHelp()`) and a one-line payment note; mirror in `JoinLeagueFlow.swift`.

**B-F2 · P1 · The landing copy contradicts the flow it introduces.** OBSERVATION: "Enter your email and you're in." / "you'll join The Papago Grind the moment your sign-in code lands." — actual path: email → code → golfer card → orientation → $50 consent. INTERPRETATION: copy written for the pre-covenant instant-join flow, never updated (`index.html:17832`, `:17914`, `:15452-15454`). IMPACT: JOIN: "The landing copy actively contradicts the flow"; trust is spent before the sheet appears. RECOMMENDATION: "Sign in with your email — you'll see the league before you join."

**B-F3 · P1 · "Not now" loses the invitation.** OBSERVATION: decline → Home "LEAGUE · None yet"; Join sheet empty; only an invisible accessibility status "Not joined — use code THEPTCQ5 whenever you're ready". INTERPRETATION: `cs_code` deleted before `covenantGate` as an anti-loop guard (`index.html:17564`) — an engineering safeguard with an unlogged UX side-effect. IMPACT: the cautious joiner (the persona most worth keeping) is the one punished; a code must be retyped from a text message. RECOMMENDATION: persist the pending invite as a Home card ("Casey invited you to The Papago Grind · $50 · [Review]") until joined or dismissed explicitly.

**B-F4 · P0 · Members are handed the Pro's lock button as their only next step.** OBSERVATION: for every player persona, the Home hero's only CTA is "Lock it in and invite your crew" → "CREATE YOUR LEAGUE … [Lock the bylaws & form the squads]" → "← Back" deeper → "Cancel this league? … discards it completely." INTERPRETATION: `renderHomeHero` forming branch has no role check and no setup/draft distinction (`index.html:10072-10116`); D96 (2026-08-04) reopened the door D40 (2026-07-20) closed, reasoning only about the Pro. The wizard has no role concept; only RLS refuses. IMPACT: "the biggest button on every member's Home is one they are afraid to touch, and it nearly deleted the friend's league" (triage); "what do I do now?" has no answer. RECOMMENDATION: branch the hero on role × phase — members get a read-only forming card ("Casey draws the squads at first tee · first tee Sat Sep 5 · rounds count from then · post from the ⊕") — and gate `switchView('wizard')` on `CS.member.role==='commissioner'` (validator TOP-3 fix).

**B-F5 · P1 · No invitation exists as an object.** OBSERVATION: no invitation email reached any of four invitee accounts; the only artifact is the friend's text; the sign-in email says nothing about the league. INTERPRETATION: `shareInvite()`'s text is `You're invited to ${name} on Cup Season: url` (`index.html:14118`); there is no email/SMS invite UI although `Cup-Season-Guide.md` claims one. IMPACT: the invitee learns about money from a lawyer (`/legal.html`) or from the consent sheet after commitment. RECOMMENDATION: an invitation email/SMS with the covenant's lines (league, Pro, dates, buy-in, "three things", link) — or delete the Guide's claim.

## B.9 Verdict — 3/10

Joining works mechanically and quickly — four to six minutes, one email round-trip, an auto-verifying code — and the welcome sheet is good copy. But the decision point is hollow: a joiner commits $50 knowing the league's name, an undefined "PRESET Standard", a floor with no consequence and a "Cup Final" with no definition, and nothing about who runs it, who is in it, when it runs, how a round scores, or how to pay. Declining loses the invite. And the reward for accepting is a Home whose single call to action is the organizer's lock button, with a "MONTH CLOSES in 2 days" pill and a floor threat for a season seven days from starting. Every joiner persona answered "what do I do now?" with "I'd text Casey."

---

# Journey C — Create a league

**Who ran it.** ORG (Casey, +blind1, "The Papago Grind", THEPTCQ5, 13:23:43–13:45 UTC) and NOV (Dana, +blind5, "Desert Dogs", DESEUU0K, 13:23:09–13:43 UTC), both on brand-new accounts, both reading every (i). Four player personas (JOIN, CAS, COMP, SKEP) reached the same wizard uninvited through the member Home CTA (Journey B). IOS saw the name sheet only.

## C.1 The path, step by step

| UTC | ORG (Papago Grind) | NOV (Desert Dogs) | Screenshots |
|---|---|---|---|
| 13:23:43 / 13:23:09 | "Start a league" (1 tap from the league-less Home) | same | `screenshots/org/14-home-empty-full.jpg`, `screenshots/nov/10-home-empty.jpg` |
| — | Name sheet: "Name your league — THE BANNER EVERYTHING HANGS UNDER … You can rename it any time before the bylaws lock. [Start the league]". Empty-name tap: nothing happened (1 wasted tap) | same; "nothing happened — no message, no shake, no red text" | `org/15-wizard-1.jpg`, `nov/12-wizard-1.jpg`, `nov/13-wizard-2.jpg` |
| 13:24:55 / 13:24:22 | Named → toast (accessibility tree only) "The Papago Grind is on the books — set the bylaws" — the league row now exists | "Desert Dogs is on the books — set the bylaws" | `org/17-wizard-3.jpg`, `nov/14-wizard-3.jpg` |
| step 1/3 | "CREATE YOUR LEAGUE · LOCKS AT FIRST TEE · PRO — THAT'S YOU: Casey @casey · you run this league — THE PRO" | same | — |
| 13:24:55 → 13:31:44 (ORG ~7 min); 13:24:43 → 13:30:52 (NOV ~6 min) | Step 2 "COMPETITIVENESS — PICK ONCE, ARGUE NEVER"; opened Customize; read every (i); set $50 · 4 mo · 2 Squads · Blind draw · Cup Final · Balanced · Best 4 · 2/mo | Customize; found **Buy-in $75 (DEFAULT)** "(!!!)"; set $25 · 3 mo · kept 2 Squads | `org/18-wizard-step2.jpg`, `org/21-customize-open.jpg`, `org/22-cust-buyin.jpg`, `org/23-cust-teams.jpg`; `nov/15-wizard-step2.jpg`, `nov/19-wizard-customize-full.jpg`, `nov/27-cust-teams2.jpg` |
| 13:31:44 / 13:30:52 | Step 3 "REVIEW THE BYLAWS, THEN LOCK IT IN" — "VERIFICATION Attested" never chosen; footer "Lock opens the invite link — one link fills the league … **Minimum four to tee off.**" | same; "'Minimum four to tee off' is revealed on the LAST step. I have three people total." | `org/30-wizard-step3.jpg`, `nov/28-wizard-step3.jpg` |
| **13:32:14 / 13:31:21 — LOCK** | Tapped "Lock the bylaws & form the squads": screen unchanged; status "Lock failed. Something went wrong — please try again."; console `[cs] error: Lock failed. staged is not defined`. **Six attempts over ~3 min** (tap again; Back → Next → Lock; Clubhouse showed no league; Home → "Lock it in and invite your crew" → Lock; reload; reload again) | Same toast (~1.7 s), same console; **six attempts, ~2 min** (13:31:21 → 13:33:22) incl. switching Teams to Solo | `org/31-after-lock.jpg`…`36-lock-from-home.jpg`; `nov/30-after-lock.jpg`, `33-lock-fail-toast.jpg` |
| 13:36:30 / 13:33:37 | Found the league room by accident via the Home tile "LEAGUE The Papago Grind — OPEN THE ROOM" (the Clubhouse tab had shown no league): "Squad formation · [Code · THEPTCQ5] · Sat Sep 5 → Sat Jan 2 · 17 wks · THE PRO · CASEY"; Standings "SQUADS ARE FORMING — The Pro has the list. 1 PLAYER IN THE POOL · 3 SEATS OPEN" | Reloaded: Home "DESERT DOGS · SEASON LIVE — The season's on. Rounds count from today. ROSTER 1 IN"; Clubhouse ten seconds later "BEFORE FIRST TEE — KICKS OFF IN 7 DAYS · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" with Squad 1 / Squad 2 — **the first tap had locked; the Solo retry was discarded** | `org/37-league-room-forming.jpg`; `nov/34-reload-home.jpg`, `nov/35-clubhouse-1.jpg` |
| 13:37 | "Share the invite link" → status "Invite code: THEPTCQ5" (1.5 s); code chip → same; no URL ever shown | same, DESEUU0K; "I never saw a URL" | `org/38-share-invite.jpg`, `org/40-code-chip.jpg`; `nov/45-share-link.jpg` |
| 13:38 | "Add golfers" → "Find golfers by name or @handle"; typed a friend's email → "No golfers found. Invite links still work for everyone else."; typed "@jerecho" → two strangers with [Add] buttons | typed an email and "Mike" → "No golfers found." | `org/41-add-golfers.jpg`, `42-add-golfers-email.jpg`, `43-add-golfers-search.jpg`; `nov/46`, `47-search-email.jpg` |
| 13:41 / 13:36:19 | Found "How scoring works": Clubhouse → League → expand "▶ LEAGUE RULES & PRO SHOP" → "[How scoring & handicaps work →]" — "18 minutes after starting the wizard, and only because the lock failed and I went digging" | "4 taps deep, behind a collapsed disclosure" | `org/49-scoring-help2.jpg`; `nov/42-scoring-a.jpg` |
| 13:42 / 13:39:56 | Squads › View → "FORM SQUADS · BLIND DRAW · THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW · [Draw squads]" → "Draw failed. Something went wrong — please try again." Console: `Not enough golfers to cover every squad — 1 in, 2 squads. Share the invite link first.` | same | `org/53-draw-squads-tap.jpg`; `nov/53-after-draw.jpg` |
| 13:44 | "Share the season → Link" → "Could not make the link. Please sign in again." (signed in; console: clipboard write denied) | — | `org/60-season-share-tap.jpg` |
| 14:05:53 | Opened `/?join=THEPTCQ5` himself to see what friends are told — the Pro is never shown the covenant | — | `org/95-join-link-view.jpg` |

**Totals.** ORG: ~48 min as a user, ~9 min in the wizard, ~6 min retrying a lock "that never worked"; never saw a success state. NOV: league create 8 min including retries; learned the league was live only by reloading.

## C.2 The lock — orchestrator-verified and validated

OBSERVATION: 12 taps of "Lock the bylaws & form the squads" across two Pros, 12 "Lock failed" toasts, 12 console `staged is not defined`. ORG's league was in fact locked from the first tap (the room chip read "Squad formation" = phase `draft`) while Home kept offering "Lock it in and invite your crew". NOV's fifth/sixth attempts with Teams switched to Solo re-ran the writes: settings rewritten `solo`, season reused, `form_squads` skipped, phase set to `season` — so Home said "SEASON LIVE" while the Clubhouse showed two empty squads "SQUADS LOCKED" (`screenshots/nov/34`, `35`).

INTERPRETATION (verified): `lockBylaws()` ends with `return { emails: emails.length, invited: staged.length, nextPhase }` (`index.html:15218`); D97 (commit `1fd47e1`, 2026-08-04) deleted `const staged = state.wizInvitees || []` and its loop but left this line. The ReferenceError fires **after** `league_settings.update` with `locked_at` (`:15127–15149`), the `seasons` insert (`:15189–15196`), the `form_squads` RPC (`:15203`) and `leagues.update({phase})` (`:15211`) have all committed. The click handler's catch (`:15494-15505`) maps it through `humanError` (`:4117`, no ReferenceError pattern) to the generic sentence and never reaches `openLockShare()` — the only surface in the file that prints the join URL as text. Prod telemetry (`client_events`, read-only query by validators): `lock_ok` = 1 (2026-07-27, pre-D97); `lock_fail` = 11, all 2026-08-29, all `staged is not defined`. **No league has locked successfully through the client since 2026-08-04**; the four leagues that locked on 08-28 were server-seeded. cupseason.app serves `34d20b6`, which contains the line.

IMPACT: the single tap that turns an account into a league reports failure 100% of the time; retries are not idempotent (the solo path writes `phase:'season'` directly and skips D58's `start_season` min-4 gate, so a one-person league went live); the intended invite moment (`openLockShare`, D40's "one share moment") is unreachable, which is why every "Share the invite link" finding in this audit is a code toast. ORG verdict: "Fix the lock bug and add a real invite and this is a 7."

RECOMMENDATION (client, ship today): `return { emails: emails.length, invited: 0, nextPhase }`; split commit from celebration so any post-commit exception re-reads `leagues.phase`/`locked_at` and renders success; render errors inline under `#lockBtn`, not a 1.7 s toast; pass user-written RPC messages ("Not enough golfers to cover every squad — 1 in, 2 squads. Share the invite link first.") through `humanError` untouched; add a preflight lint for unresolved identifiers (`node --check` cannot see a free identifier). Structural (log a decision first, rule 5): one SECURITY DEFINER `lock_league(p_league, p_settings)` RPC, idempotent on `locked_at`, used by web and `WizardService.swift`.

## C.3 Every decision in the wizard

| Decision | What the user thought | What it actually is | Default sensible? | Terminology clear? | Consequence clear? |
|---|---|---|---|---|---|
| **Name the league → "Start the league"** | "the button said 'Start' when it really meant 'Next'" (NOV N-32); IOS: "no idea what happens next, how many steps, what a league needs" | Creates the `leagues` row immediately (toast "…is on the books — set the bylaws", `index.html:17449`); phase `setup` | n/a | "bylaws" and "lock" both unintroduced on the sheet | No — that a league now exists is not shown; empty-name tap is a silent no-op (ORG, NOV N-31) |
| **Pro — that's you** | "for a beat I thought the app was assigning me a pro" (NOV); "I got it from context; a friend would not" (ORG) | The commissioner role (`league_members.role='commissioner'`) — locks, draws, marks buy-ins, grants byes | n/a | No — golf already owns the word; D15 chose the collision knowingly | Partly: what the job entails (byes, money, squads) surfaces piecemeal later ("Nobody told me that would be my job" — NOV on "Pro-approved bye") |
| **Header "LOCKS AT FIRST TEE"** | Both Pros: "settings freeze on the season's first day (Sep 5)" | The bylaws lock at the **button tap** (D40); the season starts at first tee; the endgame stays switchable after lock (NOV saw "[Finish: Cup Final — switch to points table]" on the League tab) | — | No — "three different lock moments in one screen" (ORG ORG-08): header, button, footer "Lock opens the invite link" | No |
| **Competitiveness preset (Casual / Standard / Cutthroat) + "Use these defaults →"** | "choosing a difficulty level"; "GHIN rounds — does Standard mean my buddies without a GHIN can't post?" (ORG); "does this mean players must ALSO post to GHIN? Does the app check?" (NOV N-11) | §8 bundles: allowance 100/95/90 · index source · verification Honor/Attested/GHIN+attested · cap · floor. "Use these defaults →" jumps to review and resets nothing (ORG ORG-36: "the label is wrong in the safe direction") | Standard as default: yes | No — "seven jargon items in three lines, none defined on the card" (ORG ORG-13): hcp, honor scores, GHIN rounds, counting, floor, attested, rated tees. The (i) adds "Every individual dial unlocks with Pro Shop" above a free Customize button | No — what "Attested" will demand of a friend at post time is unanswerable (ORG ORG-07, NOV N-11, JOIN J-23) |
| **Customize (the reveal)** | "Nothing on the Standard card warned me that these existed — a person who taps 'Use these defaults →' accepts all of the following without seeing them" (NOV) | Nine dials, one of them money | — | — | No — the money dial is below the fold of an optional panel |
| **Buy-in** | "**$75** (DEFAULT). (!!!) … I would have sent my buddies a league with a $75 buy-in without knowing." (NOV N-02, P0); ORG ORG-04 | §7 default $75; `state.stake:75` (`index.html:3793`), static `$75` markup (`:3263`), DB `buyin_cents` default 7500. Steps None/$25/$50/$75/$100/$150/$200 — "No way to enter $10 or $20. One tap of − from $75 goes straight to 'None'" (NOV N-19) | **No** — a money commitment made unseen; the Prize Pool Disclaimer's own advice is "keep your league to bragging rights" if unsure | "$0 = bragging rights" clear | No — the ledger sentence ("money moves friend-to-friend") lives in the *pot split* (i), not here: "That sentence belongs next to the buy-in dial" (ORG) |
| **Season length** | Clear; dates recompute live (ORG, NOV) | §14.0 whole weeks from a flexible first-tee weekday | 6 mo — arguable | Yes | Yes; nit: label read "2 mo" for two different end dates (NOV N-35) |
| **First tee** | Clear | `seasons.starts_on`; defaulted to next Saturday, **Sep 5 — a week out** (both leagues) | Debatable — it put every joiner into a seven-day pre-season with no explanation (Journey D) | "First tee as a label for a date took a second" (NOV) | Yes |
| **Teams (Solo / 2 / 3 / 4 Squads)** | "Three contradictory signals on one control: highlight says 2, caption says 4, warning says solo" (NOV N-07); ORG: "with 7 players, 2 squads = 3 v 4. Nothing says how uneven squads are scored" | Markup defaults 4 Squads + its note; JS state defaults `squads2` and re-highlights; `#structNote` rewritten only on click (`index.html:12030`); "staged" is a D97-retired word still in `renderStructFit` | 2 squads: fine for 4–7 | No — this (i) is the **first definition of "squad"** in the product, "behind an (i) on an optional Customize panel" (NOV); "+10 head start — 10 of what?" (ORG) | No — uneven squads are not normalised (§3.3) and the Pro cannot find that out |
| **How teams fill (Blind draw / Assign)** | Clear after the (i) | §15; server-side draw at lock | Yes | Yes | Yes |
| **How it ends (Cup Final / Points table)** | "First time the word 'cup' is explained, and it is explained as a *playoff*. 'Top seeds only' — how many? What happens to non-seeds?" (NOV); "What is a *seed*? Top how many?" (ORG) | §14.3: 2-squad leagues both advance, leader +10; solo top-2; final four weeks scored fresh; non-finalists keep the individual races | Cup Final: yes | No — this (i) is the **only in-app definition of the Cup Final** and it is Pro-only | No |
| **The pot split (Balanced / Winner-heavy / Spread it)** | "Points King is defined only inside the (i)"; the ledger sentence is here | §7 60/25/15 | Yes | "champ / 2nd / king" abbreviation; "Points King" first met here | No — how a squad's 60% divides among its members is stated nowhere (ORG, COMP, SKEP SK-21) |
| **Counting cap (i)** | "the best copy in the wizard" (NOV); good explainer (ORG) | §3.1 best-4/month | Yes | Yes | Yes |
| **Participation floor (i)** | "'Pro-approved' means I'll be adjudicating my friends' vacations. Nobody told me that would be my job." (NOV) | §3.2; **the (i) still says "One Pro-approved bye month" — a pre-D14 leftover; the scoring sheet says the bye is automatic** (JOIN J-08: three floor explanations) | 2/mo: yes | Partly | No — two contradictory bye rules |
| **Review row "VERIFICATION Attested"** | "I never chose 'attested'. Step 2 said Standard = 'GHIN rounds'; Cutthroat = 'verified + attested'. The review uses a third vocabulary." (ORG) | The preset card shows §8's *index-source* column; the review shows the *verification* column; both true, never bridged; "attested" is defined only on the live scoring screen after tee-off | — | No | No — "As the Pro I now cannot tell my friends what verification rule we're under" |
| **Footer "Minimum four to tee off"** | "revealed on the LAST step. I have three people total. Nothing earlier said four." (NOV N-06) | D58's `start_season` gate — which the solo path skips; NOV's one-person league went "SEASON LIVE" | — | Yes | No — "Catch-22 for a novice: you must commit before you can rally anyone" |
| **"Lock the bylaws & form the squads"** | "am I about to draw teams with just me in them?" (NOV); ORG: "tapping this will blind-draw squads with one player and freeze the rules before anyone joins" | Four direct client writes + one RPC, then a ReferenceError (C.2) | — | No — "form the squads" with a roster of one | **The consequence delivered was a failure message** |

## C.4 After the lock — invites, status, rules, money

**Invites.** "Share the invite link" / "Share an invite link instead" / the code chip all produced "Invite code: THEPTCQ5" (1.5 s status). "Add golfers" searches only existing accounts; an email typed in returns "No golfers found. Invite links still work for everyone else." Typing "@jerecho" surfaced "Jerecho Fischbeck ✦ Founder" and "jerechosb" — two strangers with [Add] buttons (ORG ORG-15: "I can drop strangers into my private money league"; "Findable by: All" is the default). No pending/invited/joined state exists anywhere: "There is nothing to track because nothing was sent." (NOV). The DOM contains the template `https://cupseason.app/?join=` but the app never displayed the link (ORG). Validation trimmed the toast claim: on a phone, `navigator.share` fires first; the toast is the double fallback — but `openLockShare` is the only URL-as-text surface and it never opens (C.2). There is no email/SMS path despite `Cup-Season-Guide.md` ("or invite by email"): `#emailSlots` is absent from the markup and `state.emails` is always `['']`.

**Status.** One unlocked one-member league was described as "forming" (Home), "Squad formation" (room header), "Squads · LIVE NOW — CAPTAINS READY" (League tab, `index.html:12231`), and "◆ The Papago Grind is live — post the first round" (Board) — "As the Pro I cannot tell my friends what state we are in." (ORG ORG-10). NOV's League tab said "Squads · Complete · rosters locked" over two empty squads. Standings: "SQUADS ARE FORMING — **The Pro has the list.**" (`:3416`) — "what list? No list is shown"; "1 PLAYER IN THE POOL · 3 SEATS OPEN" — "reads as a capacity of 4 for a league meant for 7" (ORG ORG-20). Empty-league Standings carried "TOP SEED · +10", "TOP 1 ADVANCE · PROJECTED UNDER A GENEROUS CEILING", "CAPT. —", "Δ WK", "COUNTING ROUNDS 0 / 4 · August" for a season starting in September (NOV N-13, N-16).

**Rules for friends.** Path: Clubhouse → League → "▶ LEAGUE RULES & PRO SHOP" → bylaws table → "[How scoring & handicaps work →]". The sheet is "the single most important text in the app and it is four taps deep" (ORG); "THE page … It is not linked from Home, not from onboarding, not from the wizard, and not from the Standings tab where the numbers appear" (NOV N-08). The disclosure that holds the rules also holds the upsell: "The Pro Shop — CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE — SOON Custom rules … [Coming at launch]" — "am I 'the pilot'?" (NOV, ORG). "bylaws §4" is cited on Standings (`:3506`) and no §4 is served anywhere.

**Money.** Pot tab: "THE POT $50 — 1 × $50 · $0 collected · 1 still owe — $30 CUP CHAMPS · $13 RUNNER-UP · $8 POINTS KING — Cup Season keeps the books. Buy-ins and payouts move friend-to-friend." — "This is the sentence the buy-in dial in the wizard needed" (ORG); $30 + $13 + $8 = $51 on $50; "the app never says how a squad payout is divided among its members". Settings: "Membership & billing — PLAN FREE · PILOT — Cup Season membership lands at launch. Nothing to pay during the pilot." — "I cannot tell whether we will be charged mid-season, who pays (me? each player?), or how much. This is the one money question the app does not answer anywhere." (ORG). D101 decided the answer ($89/league-year, first year free, paid from the pot); no surface states it.

**What the Pro sees when nobody has joined.** Home: "Just you so far. Lock the bylaws and the invite link is yours. ROSTER 1 IN [Lock it in and invite your crew]" — the button leads to the step that fails. Standings: "[Form the squads] [Share the invite link]" — the first fails with a hidden reason, the second yields a code. "What a friend sees when they join: the app never shows me." (ORG). The hidden setup checklist ("League setup · three steps to first tee · 1 Season settings · 2 Invite the crew · 3 Squad formation", `index.html:3407-3411`) is `display:none`.

## C.5 The distinction test — league · season · round · cup · match · side game · standings · points · pot

| Noun | What the product means | What the organizers (and members) said | Pass / fail |
|---|---|---|---|
| **League** | The container: crew + bylaws + pot + board + squads; runs many seasons ("SEASON I") | Clear (8/8) — but also called "your groups" (switcher) and "the room" (Home tile); the door says "crew", the field says "LEAGUE CODE", the button "invite code" (JOIN: "three names for one thing") | Pass on concept, fail on naming |
| **Season** | A numbered window inside a league: N whole weeks from first tee; months are the cap/floor unit; last 4 weeks the Cup Final | "the league's competition window … Never defined in one place; assembled from the wizard" (ORG). **Nobody drew the league/season distinction**; "league" and "season" were used interchangeably by every persona; the wizard says "Start the league" while configuring season 1; You says "SEASON I"; NOV: "week/month/season are three clocks, never explained together" | Fail (invisible until "Run it back", which no one reached) |
| **Round** | A profile fact (gross, rating, slope, date, index snapshot, differential) that every league *reads*; immutable | "A 'round' in this app = any 18 or 9 you post, any day, any course" (NOV — correct). But "counts on your card" was read as "counted" (NOV, JOIN, CAS), and "card" carries five senses (SKEP SK-34: your card, on the card, scorecard, settlement card, Post card) | Half — the lens model never landed |
| **Cup** | The season championship (the trophy), decided by the Cup Final or the points table | "'the cup' — still fuzzy … the app also uses it as a count of leagues I'm in ('Cups & events · 1')" (ORG); "two meanings — the trophy and the 4-week playoff" (NOV); "unclear whether it's the squad race or the whole season" (CAS); "this is the app's name and I still can't define it" (COMP) | **Fail, 8/8** — four senses (cup, cup points, Cup Final, Cup champs, "Cups & events"), zero definitions |
| **Match** | A live match-play game on a parallel ledger; the round posts, the result never touches cup points | Understood at the live screen (ORG, COMP: "They do not affect the season standings as far as any copy says"); read as "a test artifact" when a three-hole "Casey def. Marco 1 UP THRU 3 · $5 on the line" appeared flagged red as incomplete (SKEP SK-25, CAS r1 A6: "A declared winner whose only scored hole is worse than the loser's") | Pass at the live door; fail on the board |
| **Side game** | Skins / Wolf / Sunningdale / match play under the ⊕ LIVE door; money "settled between you", never on the pot | "USER ASSUMPTION (before): side-game dollars go on the Pot ledger. ACTUAL: only the buy-in pot is money; skins/match/Wolf cash is shown once … and then gone." (NOV N-24); "Nothing in one place states that side games don't affect season points while the gross score does" (CAS A36); Wolf "never explained" | Half — mechanics right at play, relation to season and pot unstated |
| **Standings** | Squad table + individual race + the Climb (you-centred ladder with clinch math) | ORG on his own empty league: "'TOP SEED · +10', 'TOP 1 ADVANCE', 'PROJECTED UNDER A GENEROUS CEILING' — I do not know what any of these mean. +10 what? Why does Squad 1 have +10 with zero rounds?"; COMP: "I cannot compute a squad score" — no formula for how members' counting rounds become a squad total | Fail — vocabulary shipped without definitions; the squad formula is nowhere |
| **Points** | Cup points per round (5–12) → counting points (best 4/mo) → squad month → season total; individual layer beside it | Per-round: 7/8 correct. Aggregation: "I still don't totally get how the squad points and the individual points fit together" (CAS); "nothing says whether the individual Pts column is capped too" (COMP) | Pass on round → points, fail on points → table |
| **Pot** | Stake × roster (owed) and collected (cash); split 60/25/15 by role; resolved to people at the ceremony; a ledger the app never holds | The ledger concept: 8/8 ("Cup Season keeps the books; money moves between you"). The path: 0/8 — "how, to whom, by when" never stated; "four money nouns (buy-in, pot, stake per side, stake) with different rules each, and the Pot tab's 'Post a stake' explicitly *cannot* be money while the side game's 'stake per side' explicitly *is*" (ORG ORG-24) | Pass on concept, fail on mechanics |
| *(bonus)* **Squad** | A team drawn at lock; squad points = Σ members' counting points − penalties | "Squad = the whole league" (CAS); "three things at once — a team, a formation state, a points target" (SKEP); first defined in an organizer (i); nobody learned their own squad | Fail — introduced by its penalty (Home floor line) before its definition |

## C.6 USER ASSUMPTION / ACTUAL PRODUCT BEHAVIOR (verbatim)

- **UA:** "the app will use MY index (18.2) for the season." **APB:** "the copy says it is only 'a starting point' that the app overrides with its own calculation after rounds. So the app runs ITS OWN handicap system … whose number wins, mine or the app's? Not explained." (NOV)
- **UA:** "my 14.2 is my handicap in this app." **APB:** "the next screen (Home) said `INDEX 0 OF 3 · Three rounds and your index goes live.` — so the app treats what I typed as provisional." (ORG)
- **UA:** "'Rally your crew' means I invite my friends and we're all in one group competing head to head." **APB:** "I assumed crew = league; the app says buddies are a separate, points-free thing." (NOV)
- **UA:** "tapping this will blind-draw squads with one player and freeze the rules before anyone joins." **APB:** "it never succeeded, so unknown" (ORG) — in fact the server locked on tap one.
- **UA:** "my league holds 4 players" (from "3 SEATS OPEN"). **APB:** "unknown; 2 squads 'fits 4–7' per step 2." (ORG)
- **UA:** "some averaging" for 3 v 4 squads. **APB:** "unknown from the UI." (ORG) — §3.3: squads are not normalised.
- **UA:** "something was copied to my clipboard" after "Share the invite link". **APB:** "unknown; clipboard read is denied" (NOV); on a phone, likely a share sheet; the URL is never printed.
- **UA:** "Use these defaults" resets my customisations. **APB:** "the review still showed BUY-IN $50 · SEASON 4 mo — the button does not 'use the defaults', it just advances." (ORG)
- **UA:** "'Lock opens the invite link'." **APB:** "The league code exists before the lock: THEPTCQ5. … untrue, or at least the code is already here." (ORG)

## C.7 Hesitation moments

| Moment | Who | Taps / time |
|---|---|---|
| Lock tapped repeatedly, then a reload to learn it had worked | ORG 6 taps / ~3 min (never learned); NOV 6 taps / ~2 min then reload | P0 |
| Open Customize and read every (i) to find the $75 and the dials "Use these defaults" would have set | ORG ~7 min; NOV ~6 min | — |
| Choose a Teams structure for 7 from a control whose highlight, caption and note disagree | ORG, NOV | guess |
| Reconcile "GHIN rounds" (card) with "Attested" (review) | ORG, NOV | interpret; never resolved |
| Find the league room after the Clubhouse tab showed no league | ORG (13:32 → 13:36:30) | 4 min, found via a Home tile |
| Type friends' emails into Add golfers | ORG ×1, NOV ×2 | cannot |
| Tap Share ×4 → a code toast; try to verify anything was copied | ORG, NOV | — |
| Retry "Draw squads" against a generic error the server had explained | ORG, NOV | 1–2 taps each |
| Find the rules | ORG 18 min in; NOV 4 taps | — |
| Find the invite code at the bottom of a long Standings page, under a red "Cancel & delete this league" | NOV N-29 | — |
| Re-enter the wizard via Home → review → Back → Back to edit the name | ORG | 3 taps, undiscoverable |
| Open the join URL manually to see what friends will be told | ORG | leave-screen |

## C.8 Major findings

**C-F1 · P0 · Lock reports failure after committing** — see C.2.

**C-F2 · P0 · The five friends cannot be invited from the app.** OBSERVATION: no email/SMS invite; "Add golfers" finds only existing accounts (and strangers); every share control degrades to "Invite code: X"; the link is never printed. INTERPRETATION: A-W2/D40 put the one URL-as-text surface on the lock's success path; D97 removed the email-slot UI but the Guide still promises it. IMPACT: the organizer's whole job — "get 3 more people in" — is a code relayed by hand: "download Cup Season, tap 'I have an invite code', type THEPTCQ5, and hope" (ORG). RECOMMENDATION: print the link as selectable text with Copy + a prewritten message on Members & invites and the forming hero; an email/SMS invite carrying the covenant's lines; "N invited · N joined · need 4 to tee off" on the hero; default Findable to Buddies.

**C-F3 · P0 · $75 per player is the hidden default buy-in.** OBSERVATION: "Use these defaults →" is the primary button; the $75 stepper appears only after "Customize" (`screenshots/nov/19-wizard-customize-full.jpg`). INTERPRETATION: §7's default is designed; hiding it is not; `#stakeVal` is static `$75` markup and `buyin_cents` defaults to 7500 server-side. IMPACT: a Pro who trusts defaults commits six friends to $75 unseen — exactly what the Prize Pool Disclaimer says to avoid; it lands in every invitee's covenant. RECOMMENDATION: buy-in, season length and first tee above the fold on step 2; default $0; free entry or $5 steps; the ledger sentence beside the dial; restate the buy-in in the lock confirmation (spec §7 should change — log it).

**C-F4 · P1 · One league, four statuses, and a generic error hiding a perfect one.** OBSERVATION: "forming" / "Squad formation" / "LIVE NOW — CAPTAINS READY" / "is live"; "Complete · rosters locked" over empty squads; "Draw failed. Something went wrong" over the server's "Not enough golfers … Share the invite link first." INTERPRETATION: status strings hard-coded per component (`index.html:3415, 12231, 14710, 15513`); `humanError` has no pattern for D58's message; "captains" belong to a retired mechanic. IMPACT: "I cannot tell my friends what state we are in." RECOMMENDATION: one derived `leagueStage()` → one label table feeding every surface (Forming → Squads drawing → Before first tee → Season live → Cup Final → Complete); pass server messages through; retire "captains", "The Pro has the list", "staged".

**C-F5 · P1 · The rules that decide the winner are filed as admin.** OBSERVATION: four taps, a collapsed disclosure shared with the Pro Shop upsell, a spec-sheet table ("PRESET Standard · VERIFICATION Attested · COUNTING CAP Best 4 / mo · scored fresh"), a citation to "bylaws §4". INTERPRETATION: D82 put depth "at the doors"; the league room never got one; D13's "Vouch" was never applied (0 hits; "attested" ×15). IMPACT: both Pros: "I would still have to explain them verbally." RECOMMENDATION: "Rules" as a first-class sub-tab in sentences; link "How scoring works" from step 2, the Standings caption and the post form's bands; define verification where it is chosen; move the upsell out of the rules panel; state the D101 price where the buy-in is set.

## C.9 Verdict — 2/10

The wizard's shape is good and both organizers said so — one preset, dials behind Customize, an explainer on every dial, a review table; the counting-cap (i) is "the best copy in the wizard". Then the one button that completes it fails twelve times out of twelve with a JavaScript remnant, the league is live without the Pro knowing, the invite the copy promised "opens on lock" never opens, the money default is $75 behind a fold, the minimum-four rule is revealed last and then bypassed, the league's status is four different strings, and the rules the friends need are four taps deep next to a paywall that does not exist. "Is creating and running a season simple enough that one person will actually do it?" — "Not today: 3/10" (ORG); "Create — yes, barely, and the app told me I had failed" (NOV). As a journey it scores below both, because prod telemetry says no Pro has completed it through the client since 2026-08-04.

---

# Journey D — First round

**Who ran it.** Six web personas posted a round through the ⊕ → "Post a round — after you play" form on Aug 29, seven days before either league's first tee: ORG (87, Papago · White, 13:49:03), NOV (91, Ken McDonald · White, 13:47:26), JOIN (87, Papago · White, 15:39:14), CAS (97, Ken McDonald · White, 15:43:17; run 1 also 97 at Papago 14:34:03), COMP (74 TPC Scottsdale Champions and 84 Ken McDonald · Black, 15:40:54 / 15:44:08; run 1 the same pair at ~14:30), SKEP (91, Ken McDonald · White, 15:38:14; run 1: one failed attempt at 14:33:22, posted 14:34:05). COMP additionally ran a full 18-hole live skins round that wrote attested cards to three other testers' accounts (15:56:00). OBS opened the form read-only and typed nothing. IOS saw the native post screen (`screenshots/ios/09-post.jpg`).

## D.1 The path (representative: NOV, with the others' deltas)

| UTC | Step | Copy | Screenshot |
|---|---|---|---|
| 13:43:59 | ⊕ → "GOLF · BEFORE, DURING AND AFTER THE ROUND" — three cards: "● LIVE Play now — score the group live · Hole-by-hole · match play, Wolf & the settle-up · every complete card posts at the finish. Guests welcome, no account needed." / "**Post a round — after you play** · Gross + tee, 20 seconds · counts on your card and in every league" / "Plan a tee time — before" | All testers called this the first screen that "clicked" (ORG, NOV, SKEP). ORG: the install banner sat exactly on the ⊕ — "Two taps on the ⊕ did nothing until I found the banner's 'Not now'" (`document.elementFromPoint` verified, ORG-09, `screenshots/org/84-live-door2.jpg`) | `screenshots/nov/64-post-1.jpg`, `screenshots/org/61-post-sheet.jpg` |
| 13:44:30 | Post form: "← Golf · POST A ROUND · your index 18.2 · COURSE & TEES [Search a course, or type your own] · Rating [72.1] · Slope [128] · YOUR CARD [18 holes] [9 holes] · Front 9 gross [41] · Back 9 gross [43] · Date [2026-08-29] · [Scan the card] [Add a photo] · [Post round] · Start over — clear this card · HOW THIS ROUND SCORES — League points this round – · Enter at least one nine. · **No league yet? The round still counts on your card — points apply in any league you join.** · POINT BANDS: Beat your index by 3+ 12 · Beat it by 1–3 9 · Within a stroke either way 7 · Over by 1–3 6 · Rough day, posted anyway 5 · Every posted round scores. Your best 4 each month count toward your squad…" | "No league yet?" shown to a member of a league (6/7 flagged; static HTML at `index.html:3198`). Rating/Slope placeholders "72.1 / 128" and "41 / 43" "render like values" (CAS A5, COMP, IOS 1.8) | `screenshots/nov/65-post-form.jpg`, `screenshots/org/62-post-round-form.jpg` |
| 13:45:59 | "Ken McDonald" → one result → tee list (Tips 72.3/127 … White 68.7/115 …) → White → "Ken Mcdonald Golf Course · White", Rating 68.7 / Slope 115 auto-filled; toast "Tees set — rating and slope filled" | "**This part is excellent** — the scary rating/slope boxes disappear as a problem the moment you pick a real course" (NOV); "better than 18Birdies' course picker, honestly" (SKEP). Deltas: "Papago" returned two identical rows in every session that searched it; JOIN's first tap logged a 502 and showed no tees; COMP run 1: "TPC Scottsdale" and "Papago" returned nothing at all — five 502s from the courses edge function, no spinner, no error — "Ken Mc" hit the cache | `screenshots/nov/67-course-search.jpg`, `68-tees.jpg`; `screenshots/join/43-X-course-search.jpg`; COMP r1 `34-course-search3` |
| 13:47:11 | 46 / 45 → live preview: "LEAGUE POINTS THIS ROUND **5** — Rough one, but posted rounds always score. — **91** GROSS · **-3.7** VS YOUR INDEX" (red) | "USER ASSUMPTION on first read: 'I beat my index by 3.7 — why only 5 points?' ACTUAL: the sign convention is inverted from golf." | `screenshots/nov/71-pre-post2.jpg` |
| 13:47:26 | Post round (one tap, ~3 s; ORG 7 s; SKEP 6 s) → full-screen "Round posted": "KEN MCDONALD GOLF COURSE · WHITE · SAT AUG 29 — **91** — 3.7 over your number — [COUNTS ON YOUR CARD] — [Share the card] · Back to the board" — stacked behind it an add-to-home-screen prompt and "Welcome to the season ⛳ · 🎉 Your first round is on the board · 🏆 You broke 100 for the first time · Pinned to your card · ⛳ Your first round is on the board · [Share a link — no account needed] [Turn off this link] — The page stops working for everyone who has it." | Three stacked dialogs after one tap; "Your first round is on the board" twice; a trophy for a 91 on a first-ever round; "Turn off this link" for a link nobody made (NOV N-25, JOIN J-25, ORG ORG-21, CAS A12 r1). Console during the post: 502 ×1–3 (CAS, SKEP, JOIN, COMP) | `screenshots/nov/72-posted.jpg`, `73-welcome-season.jpg`; `screenshots/org/69-after-post.jpg` |
| 13:48 | Home feed: "You · 🎉 First round on the card · **9 1** GROSS · KEN MCDONALD GOLF COURSE · WHITE · AUG 29" (odometer digits; accessibility tree reads "6 3 0 9 2 8 5 1 gross") | — | `screenshots/nov/74-home-after-post.jpg` |
| 13:49:03 | Receipt (tap the card): "**91 gross** — KEN MCDONALD GOLF COURSE · WHITE · 18 HOLES · 2026-08-29 — The course 68.7 / 115 — 91 − 68.7 × 113 ⁄ 115 = **21.9 DIFFERENTIAL** — YOUR NUMBER THAT DAY 18.2 — Against your number **-3.7 — POSTED ANYWAY**" · [Close] | "The math is shown — genuinely good … But: (a) no '5 points'; (b) '-3.7' again with the inverted sign; (c) 'POSTED ANYWAY' … Three labels for one band. No edit, no delete, no 'wrong course' path." | `screenshots/nov/77-round-detail.jpg`, `screenshots/org/71-round-detail.jpg` |
| 13:49:40 | Standings: "COUNTING ROUNDS 0 / 4 · August · your best 4 count"; "01 Dana · R 0 · — · 0 pts" | "I earned 0 league points and the app told me 5." Every poster: standings 0 R · 0 Pts (`screenshots/join/51-AD-standings-after.jpg`, `screenshots/comp/40-standings-after74.jpg`, `screenshots/skep/37-standings-after.jpg`, `screenshots/cas/57-H01-standings-after.jpg`, `screenshots/org/72-standings-after-round.jpg`); tapping one's own row: "No rounds this season yet — post one and you're on the board." (`screenshots/join/52-AE-marcus-row.jpg`); You: "LIFETIME · Rounds posted 1 … THIS SEASON · ROUNDS POSTED 0" | `screenshots/nov/78-standings-after.jpg` |

**Time to post:** NOV ~3 min from ⊕ to posted, one attempt; CAS r1 ≈ 2.5 min; CAS r2 **4 attempts** to get a tee selected; SKEP r1 **5 attempts / ~2.5 min** to get 70.1/120 into the form plus one failed post; COMP r1 typed her own course from memory after the search returned nothing.

## D.2 The ten questions, answered from the form before typing

| # | Question | ORG | NOV | JOIN | CAS | COMP | SKEP |
|---|---|---|---|---|---|---|---|
| 1 | How do I know what round I'm playing? | "I don't — there is no 'this week's round'. I just post whatever I played." | "I don't — there is no 'round 3 of 13'. A 'round' here just means one 18 (or 9) I played, any day." | "Not answered. No round number, no week, no 'this counts for The Papago Grind'." | "I don't — there's no notion of 'the round you're supposed to play'. Whether it counts for the season (Sep 5) is not stated." | "I don't. No 'Week 1' framing; a blank card with a date pre-filled from an old draft (2026-08-25)." | "I don't 'play a round' in the app — I report one. No notion of a scheduled league round." |
| 2 | Who am I playing? | "Nobody in particular. Season = me vs my own number, summed for my squad." | "Nobody, apparently. Me vs my own index." | "Nobody. It is a solo score entry." | "Nobody. This is me alone with my gross score." | "Nobody. The after-the-fact form is solo." | "Nobody. Nothing on the form names an opponent or a squad." |
| 3 | What format? | "Stroke play vs my handicap, banded into 5/6/7/9/12. Unstated on this screen." | "Stroke play gross, converted to points against my index. Nothing says stroke play but 'gross' implies it." | "Gross stroke play scored against my own index (point bands shown)." | "Stroke play, front nine + back nine gross." | "Implicit stroke play against my own index. Header 'POST A ROUND · YOUR INDEX 6.4'." | "Individual stroke play against my own handicap, inferred from 'vs your index' — never stated." |
| 4 | What are the rules? | "League tab → collapsed panel → link. Not from here." (later: the bands are on the form — "the best screen in the app") | "The point bands are right here on the form — good: 12/9/7/6/5. 'Best 4 each month count.'" | "Partial: point bands + 'Your best 4 each month count toward your squad'." | "The 'POINT BANDS' box … 'Every posted round scores. Your best 4 each month count toward your squad'." | "The Point-bands table sits under the form — good." | "The five point bands are here (good — the best placement of them in the app). Nothing about attestation, allowed tees, or non-member rounds." |
| 5 | How are handicaps applied? | "'95% allowance' per bylaws; what that does to my 14.2 is never shown." | "'vs your index' — my 18.2. Nothing mentions the 95% allowance. USER ASSUMPTION: compared to 18.2. ACTUAL: unknown — the bylaws say 95%." | "'vs your index' only. The bylaws' 'HANDICAP ALLOWANCE 95%' never appears on the form." | "'vs your index' — but I have no index (You tab says '1 of 3'). What happens then is not said." | "'vs your index' in the preview; the 95% allowance in the bylaws is nowhere." | "'YOUR INDEX 15.2' in the header; how index + rating + slope turn into 'beat it by 3' is not shown; 95% appears nowhere." |
| 6 | What do I need to enter? | "'Gross + tee, 20 seconds' — a total score and which tees." | "Course, rating, slope, front 9, back 9, date. Rating and slope asked as raw numbers — a novice-league organizer would be stuck." | "Course & tees, Rating, Slope, 18/9, Front 9, Back 9, Date. Rating/Slope auto-filled once I picked a tee." | "Course, tee, Rating and Slope (numbers I have never typed in my life — the placeholders looked filled in), Front 9, Back 9, Date." | "Course (search / recent chips), tee, 18 or 9, Front 9, Back 9, date; optional scan / photo." | "Course, tee (or rating + slope), front 9, back 9, date. Clear." |
| 7 | What counts toward the season? | "'counts on your card and in every league' — so every posted round counts (subject to best-4, not mentioned here)." | "'Every posted round scores' — but the Clubhouse said practice rounds hit your card, and Home said 'Rounds count from today'. Three different answers on three screens." | "**Unclear.** 'No league yet? …' even though I'm in a league. Nothing says the season starts Sep 5." | "'Your best 4 each month count toward your squad.' Nothing about the season not having started." | "'Gross + tee, 20 seconds · counts on your card and in every league' — which turned out to be untrue for the league this week." | "The season starts Sep 5 and today is Aug 29; the form does NOT say this round will not count. The preview will show 'League points this round' regardless." |
| 8 | What counts toward side games? | "Unknown; presumably only the LIVE door." | "Nothing here. Side games live on the LIVE door; this form has no relation to them." | "Not mentioned on the form." | "Nothing on this form." | "Nothing here; side games only exist in the LIVE flow." | "Nothing here." |
| 9 | If something goes wrong? | "Unknown; no mention of edit/delete anywhere yet." (later: "no edit, delete, or 'report a mistake' control anywhere on the receipt") | "'Start over — clear this card' BEFORE posting. Nothing says whether a posted round can be edited or deleted." | "Before: 'Start over'. After: the You tab's recent-round row has an '×' — no copy says what it does." | "'Start over — clear this card' before posting. After: nothing on the form or receipt; a tiny ✕ on the You tab." | "'Start over' before; after: only 'Delete round' on the You page (native confirm). No edit." | "'Start over — clear this card' before. After: the You tab has an ✕ 'Delete round'. No edit. Not stated on this form." |
| 10 | Do I understand whether I won or lost / what I earned? (after posting) | "USER ASSUMPTION: yes, 6 points. ACTUAL: unclear … Standings 0. The post form showed 6 and the round produced 0 league points." | "Partly … I earned either 5 points or nothing, and the app will not tell me which." (Standings: "I earned 0 league points and the app told me 5.") | "Partly. I understand 87 was 3.9 worse than my number … I do **not** know whether I earned the 5 points the preview promised." | "No. The same round was described three ways in four minutes … The preview promised 5; the Standings then showed me at 0 … I earned… nothing, and nothing told me why." | "So: no." (12 and 5 promised; 0 delivered; "No rounds this season yet — post one and you're on the board.") | "I understand I played badly relative to my index. I do not know what I earned (5? 0?)." |

## D.3 One round, three verdicts

| Persona | Form preview | Posted card | Receipt | Standings / You |
|---|---|---|---|---|
| ORG (87, index 14.2) | "LEAGUE POINTS THIS ROUND **6** — A little loose, still cash in the bank. — 87 GROSS · **-1.7** VS YOUR INDEX" | "87 · **1.7 over your number** · COUNTS ON YOUR CARD" | "87 − 70.1 × 113 ⁄ 120 → 15.9 DIFFERENTIAL · YOUR NUMBER THAT DAY 14.2 · Against your number **-1.7 — A LITTLE LOOSE**" | "01 Casey · R 0 · — · Pts **0**"; You "This season · Rounds posted **0**" |
| NOV (91, 18.2) | "5 · Rough one … **-3.7** VS YOUR INDEX" | "91 · **3.7 over your number**" | "21.9 DIFFERENTIAL · 18.2 · **-3.7 — POSTED ANYWAY**"; You "Best vs index **-3.7 · Career best**" | 0 / 0 |
| JOIN (87, 12.0) | "5 · Rough one … **-3.9** VS YOUR INDEX" (red) | "87 · **3.9 over your number**" | "15.9 · 12.0 · **-3.9 — POSTED ANYWAY**" | "Marcus · 0 · — · 0"; row sheet "No rounds this season yet — post one and you're on the board." |
| CAS (97, **no index**) | with blank rating/slope: "**-79.0** VS YOUR INDEX", Post still enabled; with White: "5 · Rough one … **-9.8** vs your index" | "97 · **9.8 over your number**" | "97 − 68.7 × 113 ⁄ 115 = 27.8 DIFFERENTIAL · YOUR NUMBER THAT DAY 27.8 · Against your number **+0.0 — PLAYED TO IT**" | 0 / 0; You "2 of 3 Handicap index" |
| COMP (74, 6.4) | "**12** · You torched your number by 5.0. **Sandbagger alert.** · 74 GROSS · **+5.0** VS YOUR INDEX" | "74 · beat your number by 5.0 · COUNTS ON YOUR CARD" | "1.4 DIFFERENTIAL … +5.0 — TORCHED IT" — no points row | "Priya 0 R · — · 0 Pts"; "No rounds this season yet" |
| SKEP (91, 15.2) | "5 · Rough one … **-6.7** VS YOUR INDEX" | "91 · **6.7 over your number**" | "21.9 · 15.2 · **-6.7 — POSTED ANYWAY**"; You "Best vs index **-4.5 · Career best**" (r1) | "Sam R 0 · — · Pts 0" |

Six of six read the minus as under-par-good at least once ("USER ASSUMPTION: '-9.8 vs your index' means I was 9.8 *better* (minus = good in golf)" — CAS; NOV; SKEP: "how is that 4.5 UNDER my index?"). Spec §2.1 defines PvI positive = beat your number; D1 said the display becomes words; `vsPhrase()` (`index.html:5709`) does that on the posted card only — the form (`:6339`), the receipt (`:11519`), Standings "AVG VS INDEX" and You "Best vs index" print the raw signed number. The receipt has no points row pre-season (`Points` renders only when the round is in a season) and no allowance row although spec §16 requires it; CAS's "27.8 / 27.8 / +0.0" is `score_round()`'s fallback (no index → `index_at_post` = the round's own differential) rendered as a verdict.

## D.4 What each poster would tell a friend (verbatim)

**ORG:** "I shot 87 from the whites at Papago. The app turned that into a 15.9 differential — that's the 87 minus the course rating, scaled by slope. My number is 14.2, so I was about 1.7 worse than my number, which the app calls 'a little loose'. That's worth 6 points for my squad — 12 is the max if you crush your number, 5 is the floor for just posting. Only my best four rounds a month count." — "I could say that, but only because I read the scoring explainer and the receipt. I could NOT tell them whether the app used 14.2 or 95% of it, why the receipt says minus 1.7 when I was over, or whether this round counted for The Papago Grind."

**NOV:** "I put in my 91 from Ken McDonald, white tees. The app worked out I played about 22 against a rating of 68.7, and since my handicap is 18-ish that's 3 or 4 shots worse than my number, so it's the bottom band — 5 points, which apparently you get just for posting. Whether those 5 points count for anything I honestly can't tell you, because one screen says the season started today and another says nothing counts till next Saturday. And I'm on 'Squad 1' by myself, so I guess I'm winning?"

**JOIN:** "I shot 87 at Papago off the whites. The app took the 70.1 rating and 120 slope, said that's a 15.9 differential, compared it to my 12.0 and told me I was 3.9 over my number, which is the bottom band — 'posted anyway', worth 5 points. But then the standings say I've got zero rounds and zero points this season, so I honestly can't tell you whether those 5 points went anywhere. I think it's because the season doesn't start till the 5th, but nothing on the screen said that."

**CAS:** "I typed in my 49 and 48 at Ken McDonald and it said I got 5 points for a rough day, and that I was minus 9.8 against my index, which I don't have. Then the card said I was 9.8 *over* my number, and the receipt said I played *to* my number, plus zero. The standings still say I have zero rounds and zero points. So I think it went on my 'card' but not in the league, maybe because the league starts next Saturday? It didn't say." — and on what the round did to the standings: "Nothing. Everyone in The Papago Grind is on 0 rounds and 0 points, me included, before and after."

**COMP:** "I posted a 74 from the Champions course, rating 72.4 slope 133. The app worked out a 1.4 differential, compared it to my 6.4 and said I beat my number by 5.0 — top band, 'torched it', which the form said is 12 points. Then the result screen just said 'counts on your card', and the league standings still show me at zero, so as far as I can tell it earned nothing for the league — I think because the season hasn't started, but nothing in the app says that. The 84 was 4.5 over, 'posted anyway', 5 points on paper, also zero in the standings."

**SKEP:** "I typed in my 91 from Ken McDonald, front and back, picked the white tees. It told me I was 6.7 over my number, which apparently means I played 6.7 strokes worse than my handicap — it computes a differential like GHIN does. The preview said I'd get 5 league points, which is the minimum you get for just posting. Then it said the round counts on my card and… it doesn't show up in the league standings. I think that's because the season hasn't started, but the app didn't say that. So: I logged a round, got a badge for 'breaking 100', and nothing happened to the competition."

## D.5 Orchestrator-verified mechanical failures on the posting path

- **Pre-season points (all six).** `recalc()` (`index.html:6306-6341`) computes `vs = state.myIndex − diff; pts = pointsFor(vs)` with no season window under the static heading "League points this round" (`:3191`); the server's `v_rounds_ranked` scores a round only when `played_on between starts_on and ends_on`. The finish ceremony already knows (its comment at `:6584-6591`: a pre-season round "scores 0 server-side, so the ceremony must NOT flash COUNTS THIS SEASON") and falls to "COUNTS ON YOUR CARD" — it never says why. Home's hero meanwhile prints "The season's on. Rounds count from today." (`:10105`) because `starter = state.phase==='season'` is true for any locked league (`:10076`), while the Clubhouse under the same `atStarter()` condition prints "PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" (`:3428`, `:12225`) — NOV saw both 30 s apart (`screenshots/nov/34`, `35`). No decision-log entry states the mechanic "a round scores for a league only inside its window, at its allowance" (rule 5).
- **Blank date → generic failure (SKEP run 1, 14:33:22).** After "Start over — clear this card" the Date field is emptied to `mm/dd/yyyy` with no required marker; "Post round" → toast "Post failed. That didn't go through — please try again." with no field highlighted. Real cause (console): `null value in column "played_on" violates not-null constraint` (plus 4×502, 1×400); `humanError` maps any `not-null` to the transient-sounding sentence (`index.html:4116`). "A first-time member cannot post a round and is told the problem is transient." (SK-01 r1, P0). Reproduce: open Post, pick a course, tap Start over, fill scores, Post.
- **Course search 502s.** COMP run 1: "TPC Scottsdale" (3 attempts incl. key-by-key) and "Papago" produced no suggestions, no spinner, no error; five `502` responses from the `courses` edge function at 14:29 UTC; "Ken Mc" returned a cached course. She typed her own course and rating/slope from memory — "undermines 'Attested' verification and adds friction to every post." JOIN: first tap on "Papago" logged a 502 and showed no tees; the second worked. "Papago Golf Course · Phoenix, AZ · 13 tees" listed twice in every session (ORG, NOV, JOIN, CAS, COMP, SKEP).
- **Rating/Slope trap.** Typing the nines before picking a tee closes the tee list; with Rating/Slope blank the preview computed "**-79.0** VS YOUR INDEX" (CAS), "**-77.6**" (COMP), "**-75.8**" (SKEP r1) in red and "Post round" stayed enabled — "A user who posts here records a nonsense round" (SKEP r1 SK-08: 5 attempts / ~2.5 min).
- **502s during Post round** logged by CAS (×3 twice), SKEP, JOIN, COMP; no UI message. `[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'` on every Home load after a live round (ORG, NOV, CAS, SKEP, JOIN, OBS) — a PostgREST ambiguity: `live_scores` and `game_results` each carry FKs to both tables, so the embed at `index.html:7800` needs an explicit hint (`live_round_players!live_round_players_live_round_id_fkey`). Consequence for the user: the promised "Continue your round banner is waiting on Home" never appears (CAS A8); D86's doorbell is dark.
- **A 103 written to a card by someone else's game (CAS A7).** COMP's live skins round seated "Jordan" and finished; "You · Played to your number · 103 gross · Papago · Blue" appeared on CAS's Home with a receipt "28.0 / 28.0 / +0.0 — PLAYED TO IT · Attested PLAYED WITH THE GROUP · Played with Casey, Marcus, Priya" (`screenshots/cas/86-K03-103-receipt.jpg`, `87-K04-scorecard.jpg`). No notification, no "that was me / wasn't me"; his index count moved. "To a casual golfer this is alarming: someone else can put a 103 on my record." COMP, from the other side: "one phone can post + attest four cards (I did)."
- **Correction path.** The receipt and the posted card have no edit/delete; the only control is an unlabelled ✕ on You › Recent rounds with a native `confirm()` ("Delete this round? It leaves your card and any league standings it counted toward.") and no undo (ORG ORG-35, NOV N-12, CAS A26, COMP C2-27). Badges survived deletion: "Broke 100 / Broke 90 / Broke 80 · 74 gross" stayed with "Rounds posted 0" (COMP).
- **Scrap this round.** Dead for CAS (three methods, no confirm, no toast, no console error, `#discardBtn`, `screenshots/cas/93-L03-scrap-test.jpg`); a two-tap red confirm for NOV (`screenshots/nov/93-scrap-confirm.jpg`); CAS run 1: the confirm "times out and reverts before a second tap; took three tries". Unresolved — flag for reproduction.
- **Stacked celebration** (D.1): three layers, duplicated line, first-round "Broke 90 / Broke 100" trophies for an 87 (ORG: "they will be mocked in the group chat"; SKEP: "a trophy for shooting 91"), "Turn off this link" for an unrequested link; "Share the card" → hidden status "Card downloaded" and nothing visible (SKEP SK-16, JOIN, CAS, COMP).

## D.6 USER ASSUMPTION / ACTUAL PRODUCT BEHAVIOR (verbatim)

- **UA:** "Rating 72.1 / Slope 128 are filled in." **APB:** "Placeholders; blank until a tee is picked; the form computed '-79.0 vs your index' with them blank." (CAS)
- **UA:** "'-9.8 vs your index' means I was 9.8 *better* (minus = good in golf)." **APB:** "Posted card says '9.8 over your number'; receipt says '+0.0 — PLAYED TO IT'." (CAS)
- **UA:** "'League points this round 5' = I will get 5 points." **APB:** "Standings 0 R / 0 Pts; You tab 'This season · Rounds posted 0'." (CAS)
- **UA:** "I just banked 17 points." **APB:** "12 and 5 promised, 0 delivered, zero explanation anywhere; Home's 'MONTH CLOSES in 2 days' implies August IS a scoring month." (COMP r1)
- **UA:** "'beat it by 3+' means three strokes under my course handicap." **APB:** "it is index minus differential (1.4 vs 6.4 = 5.0), a slope-adjusted number." (COMP)
- **UA:** "'HANDICAP ALLOWANCE 95%' reduces the strokes I give in live games or the number I'm scored against." **APB:** "no visible calculation applies it (live strokes looked like 100% off the low man; season preview used the raw 6.4)." (COMP)
- **UA:** "With no index, my first round would be neutral or unscored." **APB:** "Three screens, three different verdicts (5 pts/rough, 7.3 over, played to it/+0.0 which per the bands is 7 pts), then 0 in the table." (CAS r1)
- **UA:** "this 91 will show up as 5 points for my squad." **APB:** "it counted for nothing in the league. The preview's 'LEAGUE POINTS THIS ROUND 5' was wrong for this date." (SKEP)
- **UA:** "'The board · rounds land here automatically' — my round will be on the league Board." **APB:** "Board showed joins, match plays and chat; my round only on Home's feed." (CAS A16)
- **UA:** "deleting a round removes what it earned." **APB:** "the 'Broke 80 / 90 / 100 · 74 gross' badges stayed after the 74 was deleted." (COMP)
- **UA:** "Only I can put scores on my card." **APB:** "A 103 'Attested · PLAYED WITH THE GROUP' landed on my card from someone else's live game." (CAS)
- **UA:** "'Share the card' opens a share sheet or copies a link." **APB:** "nothing visible happened." (COMP); hidden status "Card downloaded" (SKEP)

## D.7 Hesitation moments

| Moment | Who | Taps / time |
|---|---|---|
| Dismiss the install banner before the ⊕ responds | ORG | 2 dead taps |
| Pick a tee before typing scores; interpret "-79.0 / -77.6 / -75.8 vs your index" | CAS (4 attempts), SKEP r1 (5 attempts, ~2.5 min), COMP | repeat / interpret |
| Choose between two identical "Papago Golf Course" rows; retry after a 502 | ORG, NOV, JOIN, CAS, COMP, SKEP | 1–2 extra taps |
| Recover from "Post failed … please try again" with no field flagged | SKEP r1 | ~40 s and the developer console |
| Dismiss three stacked post-round sheets; decode "Turn off this link" | all six | 3 taps |
| Check Standings, You and the own-row sheet to discover the promised points never landed, then guess why | all six | ~2 min each; "two testers believed the post failed" (triage) |
| Reconcile "-3.7" / "3.7 over" / "-3.7 — POSTED ANYWAY" (or "-9.8 / 9.8 over / +0.0 played to it") | all six | interpret |
| Reverse-engineer from the receipt that "beat by 3" is differential, not strokes; try and fail to reproduce the 95% | COMP, ORG, NOV | calculate |
| Find delete: a tiny ✕ on You, a native confirm, no undo, no edit | ORG, NOV, CAS, COMP | navigate / confirm |
| Discover a 103 posted to my card by someone else; find no way to dispute except delete | CAS | ask |
| Scrap a live round: 3 attempts, nothing (CAS) / confirm reverts before second tap (CAS r1) | CAS | repeat |
| Resume a live round via ⊕ → Play now because the promised Home banner never appears | CAS | navigate |

## D.8 Major findings

**D-F1 · P0 · Points promised, zero delivered, and no surface says why.** OBSERVATION: 6/6 posters saw "LEAGUE POINTS THIS ROUND 5/6/12", then "COUNTS ON YOUR CARD", then "R 0 · Pts 0" and "No rounds this season yet — post one and you're on the board." Home said "Rounds count from today"; the Clubhouse said the opposite. INTERPRETATION: PvI and points are computed in four places under three rules (client preview at 100%/no window; `home_feed` at 100%; `v_rounds_ranked` at 95%/windowed; `score_round`'s no-index fallback); the pilot fix (commit `75682a1`, 2026-07-24) encoded the window at the ceremony and nowhere upstream or downstream. IMPACT: "the first promise the product made me did not happen" — the loop's payoff is unreadable on day one; two testers assumed the post had failed. RECOMMENDATION: one client predicate `roundCounts(played_on)` (the ceremony's own test at `:6588-6590`) used by `recalc()`, the ceremony, the receipt, the member-row empty state and the You tile: "Season starts Sat Sep 5 — this round builds your number; no league points yet"; make Home's `starter` = `phase==='season' && !atStarter()` and reuse the Clubhouse string; gate "No league yet?" on `!window.CS?.league`; log the mechanic (rule 5).

**D-F2 · P1 · The sign reads backwards to golfers, on five surfaces.** OBSERVATION: "-3.7 VS YOUR INDEX" (red) under "Rough one"; "Best vs index -3.7 · Career best"; "AVG VS INDEX -4.0" in red for a leader whose rounds beat his number (OBS). INTERPRETATION: spec §2.1's sign is faithful; D1's "words, not signs" was applied to one of five surfaces. IMPACT: 6/7 misread it; "the single most important number in the product reads backwards" (SKEP). RECOMMENDATION: route every signed PvI through `vsPhrase()` / `bandName()`; if a figure must stay, label it "over / under"; never a bare red minus.

**D-F3 · P1 · The receipt stops short of the spec.** OBSERVATION: differential arithmetic shown (praised 7/7), but no points row pre-season, no "Index 14.2 × 95% = 13.5" row (§16 requires the allowance snapshot; only the demo receipt at `:11912` has it), ISO date, no correction control. INTERPRETATION: `roundCardBody` prints the raw index beside an allowance-applied verdict, so the arithmetic does not close — ORG: "I cannot reproduce the number by hand from what is on screen." IMPACT: the "shows its work" promise is half-kept exactly where trust is formed. RECOMMENDATION: add "League points: 6 · counts for Squad 2 · #3 this month" or "practice · season starts Sep 5"; add the allowance row; "Fix / delete this round" with an in-app confirm and undo.

**D-F4 · P1 · The posting path has real server failures the UI narrates as user error or success.** OBSERVATION: blank-date not-null → "please try again"; five 502s → empty course search with no message; 502s during Post; the live-resume embed failing on every boot. INTERPRETATION: `humanError` collapses distinct causes into one sentence; the courses edge function's failures are swallowed; the embed ambiguity is a schema fact the query does not disambiguate. IMPACT: a first-time member "cannot post a round and is told the problem is transient"; the doorbell that would have told Jordan he was on Priya's card never rang. RECOMMENDATION: mark the date required and say so; surface search failures ("Course lookup is down — type the course and tees from the card"); hint the FK at `:7800`; surface or log every 502 on a write path.

**D-F5 · P1 · Attestation without consent.** OBSERVATION: a 103 landed on CAS's card from another member's live game; no notification; no confirm/dispute; index moved. INTERPRETATION: §13.1 "every round posts at once" + D85 "any phone can fix any score" is a fairness feature for the group and a consent gap for the individual; D86's push nudge did not fire (embed error). IMPACT: trust — "someone else can put a 103 on my record." RECOMMENDATION: notify on being seated and on finish; "That was me / That wasn't me" on rounds you did not enter; fix the doorbell.

## D.9 Verdict — 4/10

Posting a round is the best thirty seconds in the product — course search → tee → rating/slope autofill → live band preview → a receipt with the formula — and every persona said so. Then the outcome betrays it: the form promises points the season cannot pay, the card says "COUNTS ON YOUR CARD" without saying what that means, the receipt shows a minus for a bad round, the standings show zero, and the own-row sheet tells a golfer who just posted to "post one and you're on the board." Six of six could describe their gross and their differential; none could say what they had earned. Add the blank-date failure, the 502-silenced course search, the placeholder trap and a stranger's 103, and "easy to post, impossible to understand what it did" is the honest summary.

---

# Journey E — Mid-season

**Who ran it.** OBS (the owner's real account, jerecho@fischbeck3.com, strict read-only: 0 rounds, 0 posts written — DB-checked) at 13:18–13:47 UTC, a member of two live leagues: **Fellas** (week 6 of 26, Mon Jul 20 → Mon Jan 18, $75 buy-in, solo, 2 players, 1st by 22) and **Who's the bitch?** (week 4 of 13, Mon Aug 3 → Mon Nov 2, bragging rights, 2 players, 2nd by 10). IOS surveyed the same account's Home and Clubhouse without tapping (15:21–15:27). The five Papago Grind members (JOIN, CAS, COMP, SKEP + Casey) and NOV's Desert Dogs stand in for a *fresh* league: all pre-season (first tee Sep 5), squads undrawn, standings all zero — the real week 1 of every new league.

## E.1 The path (OBS)

| UTC | Screen | Copy that mattered | Screenshot |
|---|---|---|---|
| 13:32:06 | Home (signed in, first view) | "FELLAS · WEEK 6 OF 26 · **1st** · — HELD · You lead by **22 points** over **Jade**. · AUG FLOOR 1/2 ▬▬▬▬░░░ 1 MORE · 2D" · tiles LEAGUE 1st FELLAS / NEXT FRI QUINTERO GOLF … / BOARD Open THE LEAGUE · "MONTH CLOSES in 2 days" · feed: "Galen · 🔥 Personal best · 79 GROSS · LONE TREE GOLF CLUB · BLUE · AUG 23"; story "Galen broke 80 for the first time — a 79. That one goes on the wall. WHO'S THE BITCH? · AUG 24" | `screenshots/obs/04-home-first.jpg`, `05-home-full.jpg` |
| 13:33:13 | Clubhouse › Fellas › Standings (1 tap) | chips "Fellas / HERE · Who's the bitch? / IN SEASON" · "Season live · Mon Jul 20 → Mon Jan 18 · 26 wks · THE PRO · JADE" · "3 days left in August" bar · "SEASON RACE · THE CLIMB: 01 Jerecho F… LOCKED 32 / 02 Jade LOCKED 10 · Jade 22 behind you · EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" · STANDINGS table (PLAYER · TREND · Δ WK · PTS: +10 / 32; 0 / 10) · "JERECHO FISCHBECK HAS LOCKED A CUP SEED" · tiles "SEASON W6 / 26 · Week closes Sun · 1d" · "THE POT $150 · 0/2 buy-ins in" · "YOUR INDEX 11.3 · ▼ 1.1 this season" · "COUNTING ROUNDS 1 / 4" · "NEXT UP · AUGUST · Post 1 more round this month — best 4 count, you've posted 1. [Live round]" · "ON THE LINE $150 · CHAMPS $90 · RUNNER-UP $38 · POINTS KING $23 · $0 COLLECTED" · THE INDIVIDUAL RACE (Points King / Most Improved / Iron Man; AVG VS INDEX -4.0 / -13.8 both red) · "bylaws §4" | `06-league-tile.jpg`, `07-league-full.jpg`, `08-club-top.jpg`, `09-club-mid.jpg` |
| 13:34:21 | Own row → receipt | "6 ROUNDS · 32 PTS · 2026-08-16 +2.6 vs index · 9 PTS / 2026-07-29 -5.1 · 5 PTS / 2026-07-26 -14.0 · 5 PTS / 2026-07-24 · 9 HOLES · BUMPED -6.2 · 3 PTS / 2026-07-24 -1.2 · 6 PTS / 2026-07-20 +0.0 · 7 PTS" — no courses, no gross, no total; "I had to add 9+5+5+6+7 myself" | `10-my-row.jpg` |
| 13:35 | Pot | "$150 · 2 × $75 · $0 collected · 2 still owe · $90 Cup champs · $38 Runner-up · $23 Points king" · "Buy-ins · 0/2 in" | `12-on-the-line.jpg` |
| 13:35:44 | Schedule | left the Clubhouse for "YOUR GOLF CALENDAR · ← HOME"; "Galen BUDDY · FRI SEP 4 · QUINTERO … · you lead 1–0 · YOU'RE IN · 'Major' · ON THE TEE SHEET"; "Nothing on the tee sheet for Aug" beneath it; "WEEK BY WEEK: WK 4 / WK 3 / WK 2 / WK 1" with nothing beside them | `13-sub-Schedule.jpg` |
| 13:37–13:38 | League tab → "▸ LEAGUE RULES & PRO SHOP" → bylaws; "How scoring works" | "CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh" — "**the ONLY place the app told me the season ends with a Cup Final**"; "Squad formation · Blind draw" and "−5 sqd pts" printed for an "Individual — no squads" league; the scoring sheet: four sections, "says nothing about the Cup Final, seeds, 'locked', or tiebreaks", "talks about 'your squad' four times" | `21-bylaws-open.jpg`, `22-how-scoring2.jpg` |
| 13:38 | Board | oldest-first, compose box under the newest post; "Jerecho posted 83 at Cave Creek GC." and "85 at Encanto GC." on Thu Aug 27 while Standings says "you've posted 1" this month; two post formats; "Sunningdale … bank: … 6 units", "Diff 17.8", "July closed — Ledger posted · Partial month, floors waived" | `19-sub-Board.jpg` |
| 13:40:13 | Who's the bitch? chip | 2nd, "10 back of Galen" — a league Home had not shown at all until now | `28-wtb-standings2.jpg` |
| 13:41:25 | You | "11.3 HANDICAP INDEX · FORM ●●●●●"; "RIVALRIES · YOUR RECORD · Jade · 2 weeks head-to-head · 2–0 · Galen · 1 week head-to-head · 1–0"; "LEAGUE RECORD: Fellas SEASON I · 1ST OF 2 · 32 PTS · Who's the bitch? SEASON I · 2ND OF 2 · 9 PTS"; "Index move ▲ 1.2" (Standings said "▼ 1.1"; board said "12.2 → 12.6") | `29-you-full.jpg` |
| 13:43:10 | Home › Board tile | Home's hero had silently become "WHO'S THE BITCH? · WEEK 4 OF 13 · 2nd — HELD · 10 points back of Galen." — the hero follows the last league opened in the Clubhouse; no switcher on Home; a hidden status "Switch groups anytime from Home" names nothing visible | `35-board-tile.jpg`, `36-home-earlier.jpg` |
| 13:47:26 | Home › THE BOARD ↗ | in-season round cards are the best surface in the product: "85 GROSS · A LITTLE LOOSE · COUNTING #2 THIS MONTH · -1.2 · 6 PTS" | `45-the-board-link.jpg` |

**IOS Home** (`screenshots/ios/01-door.jpg`): "WHO'S THE BITCH? · WEEK 4 OF **14**" / "2nd" / "— held" / "10 points back of the lead." / "Partial month · floors waived" / "QUIET SINCE YOUR LAST VISIT" followed by an item. **IOS Clubhouse** (`03-clubhouse.jpg`): "WK 4 / **13**"; "01 Galen (LOCKED) 19 · **10 back of Galen** [drawn under Galen's row] · 02 You (LOCKED) 9 · EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS". **IOS Board** (`04-board.jpg`): "◆ Your league is live — post the first round" under TODAY, 85% empty, while Home shows "Show earlier · 18".

## E.2 The twelve mid-season questions

Observer answers from `raw/agent7-retention-observer.md` Journey E and `persona-results.json`; fresh-league answers from the Papago Grind members (JOIN §6/§8, COMP "RIVALRY", CAS §7, SKEP) and NOV's one-member league.

| # | Question | Observer (Fellas / WTB) | Taps · time | Fresh league (pre-season, 5 members) | Taps |
|---|---|---|---|---|---|
| 1 | Who is winning? | Fellas: **me** — "1st · You lead by 22 points over Jade". WTB: **Galen** 19–9 — "Home never showed it until I opened that league." | 0 · 3 s / 3 taps · ~1 min | Nobody: five rows "0 · — · 0" (`screenshots/join/23-Q-clubhouse-full.jpg`); NOV: "01 Squad 1 0 · TOP SEED · +10 … 02 Squad 2 0" for two empty squads | 1–2 |
| 2 | How far behind am I? | Fellas: not behind. WTB: "10 points back of Galen / a good weekend back." | 3 | "—"; the feed shows gross only (Sam 91, Jordan 97, Priya 84/74): "the app scores against each person's number, so gross tells me nothing about points" (JOIN) | 1 |
| 3 | Biggest threat? | Jade / Galen — "trivially, each league has two players. The app never frames a threat, only 'Jade 22 behind you'." | 0–3 | None named; COMP: "the app itself never picks a rival for me"; the only index comparison is Members & invites (Priya 6.4 · Sam 15.2 · Casey 14.2 · Marcus 12.0) | 3 |
| 4 | Who am I ahead of? | Jade. | 0 | Nobody; tapping a rival's row: "0 ROUNDS · 0 PTS · [Post a round]" — "reads as posting for them" (JOIN J-20) | 3 |
| 5 | Rounds / weeks remaining? | "WEEK 6 OF 26 → 20 weeks by my own arithmetic; end date Mon Jan 18 in Clubhouse. Rounds remaining never stated; only '1 more' for the August floor." | 0–1 | "7 days to first tee" (Home); "Sat Sep 5 → Sat Jan 2 · 17 wks" (Clubhouse); no "what to do this week" | 0–1 |
| 6 | What do I need to do to win? | "**Not answered anywhere.** Home: post 1 more round in 2 days (penalty avoidance). Bylaws (4 taps + a disclosure, ~5 min): 'CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh' — so the lead is apparently a seed; what the final is and how ties break is nowhere." | 4 + disclosure · ~5 min · still unanswered | "How do I win? Inferred only: squad with most points; 'Cup Final · scored fresh' is never explained" (JOIN); COMP Cup Final confidence 2/10, ties 1/10; ORG: "'+10 head start' — 10 of what?" | 3 |
| 7 | If I win my next round? | "Not projected. Band table (4 taps deep): +12 max → 44. No 'if you post X' line exists." | 4 | "nothing says 'post one more to lock your 4th counter' or 'Casey is 3 points ahead'" (COMP) | — |
| 8 | If I lose? | "Cannot lose points by playing ('Posted anyway · rough day · 5 pts'); only by not playing (−5 per round short, first miss forgiven by a 'season bye'). Found only in the explainer." | 4 | Understood from the welcome sheet ("You can't hurt your squad by playing badly") — the best-taught rule (7/8) | 0–1 |
| 9 | Side games? | Individual race (Points King 15% of pot, Most Improved, Iron Man); live games on the board (match play, "Sunningdale · bank · 6 units"); "A 'Major' with Galen Sep 4"; Rivalries on You. | 1 tap + scroll; 2 for You | Found only via ⊕ → LIVE (7/7); board cards "Priya took 7 skins and $60", "Match play: Priya def. Casey 2 UP THRU 3 · $5 on the line"; nothing on Home/Standings/League points there | 2 |
| 10 | Which side games am I winning? | Fellas: Points King + Iron Man (Most Improved "needs 2+ rounds"). WTB: Galen holds all three. Head-to-head 2–0 vs Jade, 1–0 vs Galen. | 1–2 | COMP after skins: "the $60 lives only as a board card"; pride stake "Loser buys the beers · Jordan vs Casey" on the Pot tab; no head-to-head record after "Priya def. Casey 2 UP" (COMP C2-24) | 2 |
| 11 | Money / stakes? | Fellas: $150 = 2 × $75, **$0 collected** six weeks in, split $90/$38/$23. WTB: "None · Bragging rights". "Home shows no money at all." | 1 + scroll | "$250 · 5 × $50 · $0 collected · 5 still owe"; how/to whom/by when to pay: never stated; tapping a row → "The Pro marks buy-ins as money moves between you" | 2 |
| 12 | Who to talk trash to? | Galen — "10 up on me, just broke 80, I lead him 1–0, we play Friday." Jade — "22 down, 0 rounds in August, still hasn't paid." "No taunt/nudge/share control exists on any of these surfaces." | 2 | The stake card "Loser buys the beers" is "the one object in the app that reads like our group text" (SKEP); the Board has 🔥, +, ⚑ (= Report, unlabelled) and zero replies in any league | 2–3 |

## E.3 Home and Standings reads (3 s / 10 s / 30 s)

| Surface | 3 s | 10 s | 30 s | Still unexplained after exploring |
|---|---|---|---|---|
| Home (Fellas) | big gold "1st", "You lead by 22 points over Jade." — "I'm winning, Jade is second" | week 6 of 26; "AUG FLOOR 1/2 · 1 MORE · 2D"; "MONTH CLOSES in 2 days"; next round Friday at Quintero; Galen's 79 | tiles, feed, 🔥, the ⊕; "why are Start/Start/Join the FIRST thing on a mid-season member's home?" | "HELD" (held what?); "floor 1/2"; "month closes" (what closes? what happens?); why a story is signed "Who's the bitch?" — a second league not represented anywhere on Home |
| Standings (Fellas) | chips, season card, segmented control — "the race itself is below the fold on a phone" | two names, 32 vs 10, LOCKED, "Everyone advances" | pot $150 nobody has paid, index 11.3, "1 more" in August, Points King + Iron Man | "what 'LOCKED' locks (a 'cup seed' — what is a cup seed?)"; "advances to what?"; why "AVG VS INDEX" is negative and red for both of us while my rounds "beat my number"; "bylaws §4"; "Δ WK +10" with no round in two weeks; "squad race" in a no-squad league; "0/2 buy-ins in" with nothing to do about it |
| IOS Home | "2nd", a league called "Who's the bitch?", Galen shot 79 | 2nd in week 4 of 14, 10 back; a buddy set a personal best | THE BOARD, 🔥, Show earlier, the +, four tabs — "I still could not tell you what a 'point' is or how to get one" | "held"; "floors … waived"; "Partial month"; why THIS WEEK shows Aug 23 on Aug 29; who leads (unnamed); "2nd" of how many |

## E.4 Data that disagrees with itself (all on one account, one afternoon)

| Contradiction | Surfaces | Evidence |
|---|---|---|
| August rounds: Board shows 83 at Cave Creek and 85 at Encanto on Thu Aug 27; Standings "you've posted 1" this month; Home "AUG FLOOR 1/2 · 1 MORE"; You lists Encanto 85 as 2026-07-24 | Board vs Standings vs Home vs You | `screenshots/obs/19-sub-Board.jpg`, `29-you-full.jpg` — "Either the two Aug 27 rounds don't count (no reason shown) or the standings are stale. A member would not know which." (board dates are posting dates; nothing says so) |
| One round, two numbers: Home story "Beat your number by 3.3" vs receipt "+2.6 vs index · 9 PTS" — "by this table 3.3 would be 12 pts" | Home vs Standings receipt | `04-home-first.jpg` vs `10-my-row.jpg`. Validated arithmetic: Home computes at 100% (13.6 − 10.3 = 3.3); the league applies Standard's 95% (12.9 − 10.3 = 2.6). Both right; the allowance is the whole difference and it is printed nowhere |
| Index movement: "▼ 1.1 this season" (green) / "Index move ▲ 1.2" (green) / "12.2 → 12.6" | Standings tile vs You vs Board | `09-club-mid.jpg`, `29-you-full.jpg`, `19-sub-Board.jpg` |
| Season length: "WEEK 4 OF 14" (iOS Home) vs "WK 4 / 13 · 13 wks" (iOS Clubhouse) | iOS Home vs Clubhouse | `screenshots/ios/01-door.jpg`, `03-clubhouse.jpg` (`HomeView.swift:526` vs `LeagueCopy.swift:165`) |
| The Board: "◆ Your league is live — post the first round" (iOS, TODAY) vs "Show earlier · 18" on Home; web Board header "ROUNDS LAND HERE AUTOMATICALLY" while members' pre-season rounds appear only on Home's feed | iOS Board vs Home; web Board vs Home | `screenshots/ios/04-board.jpg`; CAS A16 |
| The gap line "10 back of Galen" rendered under Galen's row, above the divider that starts the viewer's row | iOS Clubhouse | `screenshots/ios/03-clubhouse.jpg` y≈1630 — "reads as though Galen is 10 back of himself" |
| Squad vocabulary in a solo league: "Squad formation · Blind draw", "−5 sqd pts / round short", "your squad" ×4, "the squad race — bylaws §4" | bylaws, scoring sheet, footnote | `21-bylaws-open.jpg`, `22-how-scoring2.jpg` |
| Cross-league leakage: "Match play: Jerecho def. Jade 4&3" on the WTB board (Jade is not in it); the same personal-best story on Home twice, once per league | Boards, Home feed | `25-wtb-Board.jpg`, `36-home-earlier.jpg` |

## E.5 The emotional loop, as observed

| Element | Present? | Evidence |
|---|---|---|
| Anticipation | Partial | "MONTH CLOSES in 2 days", "3 days left in August", "NEXT FRI QUINTERO", "Week closes Sun · 1d" — "But what happens at close is never said." No weekly clash chip was on any screen (D108's `renderClash` at `index.html:4613` renders nothing without a `week_clashes` row) |
| Rivalry | Present (structurally) | "You lead by 22 points over Jade", "10 back of Galen", Rivalries 2–0 / 1–0 — records from live match play, two taps away; "the app itself never picks a rival for me" (COMP) |
| Identity | Present | @handle, 14 markers, photo, Points King / Iron Man titles; undermined by unearned badges ("Broke 100 / Broke 90 both 88 gross" — IOS) |
| Progression | Present, distrusted | index with trend, "Personal best. New number to chase." — three contradictory index stories on one account |
| Stakes | Weak | "$150 · $0 COLLECTED · 2 still owe" at week 6; no payment path; side-game cash never on any ledger |
| Bragging rights | Partial | "That one goes on the wall" stories; scorecard sheets with gold holes — "the best-looking objects in the app — and they have no share/export control" |
| Unfinished business | Partial | "1 MORE · 2D"; "a good weekend back" — only a penalty to avoid, never a gain to chase |
| Social pressure | Weak | 🔥 and a compose box; ⚑ = Report beside 🔥; zero replies in any league; rival's floor/payment status invisible; no emails or pushes in 60 days beyond sign-in codes |
| Redemption / title defense | Absent | nothing frames 2nd as a comeback; "No silverware yet"; "SEASON I" everywhere |

## E.6 USER ASSUMPTION / ACTUAL PRODUCT BEHAVIOR (verbatim)

- **UA:** "'HELD' means I held 1st place from last week (no movement)." **APB:** correct (`moved===0`, `index.html:10185`) — "no tooltip, not tappable"; IOS read it as "held what — position? a hold on me?"
- **UA:** "'AUG FLOOR 1/2 · 1 MORE · 2D' means I must post 2 rounds in August, I have 1, and 2 days remain." **APB:** correct — "no explanation on Home of what happens if I don't."
- **UA:** "I'm in two leagues because board stories carry both names." **APB:** "Home shows only Fellas; no visible switcher." The hero follows the last league opened in the Clubhouse.
- **UA:** "'LOCKED' = my place in the standings can't change." **APB:** "the caption says I 'locked a cup seed' — apparently a seat in a later 'cup'; the standings themselves remain live." IOS: "both rows carry it, so it cannot distinguish us."
- **UA:** "'Avg vs index -4.0' means I'm averaging 4 better than my index." **APB:** "minus = WORSE than index. The sign is the opposite of what a golfer reads."
- **UA:** "Home is 'everything I'm in' (the app's own How-it-works says so)." **APB:** "the hero shows exactly one league — the last one I opened in the Clubhouse."
- **UA:** "'10 back of Galen' belongs to my row." **APB:** "it is drawn under Galen's row … before the divider that starts my row." (IOS)
- **UA:** "'NO. 2' = my rank." **APB:** "it is the ball-marker's name … Coincidence with my actual rank makes this actively misleading today." (IOS, `screenshots/ios/06-you.jpg`)
- **UA:** "the board is the league's activity feed." **APB:** "on this capture it is a nearly empty chat whose only item contradicts the Home feed." (IOS)
- **UA:** "'Month closes in 2 days' means I need 2 rounds in the next 2 days." **APB:** "Unknown; season hasn't started." (CAS — fresh league)

## E.7 Hesitation moments

| Moment | Who | Taps · time |
|---|---|---|
| Find the Cup Final rule, and still not know how the winner is decided | OBS | 4 taps + a disclosure · ~5 min |
| Discover the second league (where I'm losing) | OBS | by accident, ~10 min in, via the Clubhouse chip |
| Cross-check board dates against standings and receipts to find the count of August rounds | OBS | ~4 min |
| Sum 9+5+5+6+7 on the receipt to confirm 32; subtract 26 − 6 for weeks left | OBS | calculate |
| Decode HELD / AUG FLOOR 1/2 / MONTH CLOSES on the hero | OBS, IOS | guess; never resolved on-screen |
| Reconcile "Beat your number by 3.3" with "+2.6 vs index · 9 PTS" | OBS | interpret; unresolved |
| Scroll to the bottom of the oldest-first board for the newest post | OBS | navigate |
| Recover from the Schedule tab leaving the Clubhouse | OBS, IOS, all web personas (7/7) | 1–3 failed taps |
| Reconcile "WEEK 4 OF 14" with "WK 4 / 13"; an empty Board with 18 items on Home | IOS | interpret |
| Decode "you lead 1–0 · YOU'RE IN · 'Major' · BUDDY" on the plan card | OBS, IOS | interpret |

## E.8 Major findings

**E-F1 · P1 · "How do I win?" is answered nowhere a member can reach.** OBSERVATION: the endgame is one bylaw row behind "▸ LEAGUE RULES & PRO SHOP"; the Climb prints LOCKED / "HAS LOCKED A CUP SEED" / "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" (`index.html:4478-4480`, `:14812-14823`) with no definitions; "How scoring works" (`:17274-17296`) has no finish or ties section; the +10 head start and "top 2 meet in the Cup Final" live in Pro-only wizard copy (`:3293/3298`, `:12000-12002`). INTERPRETATION (validated): D4's "season-long foreshadow" was implemented as one line in `#statFinal`'s nearest-deadline sort (`:9614-9637`), which "Week closes Sun" beats on every day but one of Fellas' 155-day run-up; D105 (2026-08-28) records "foreshadow shipped, the race itself never did." IMPACT: OBS rulesClear 3; "the lead I've watched for 22 weeks may mean nothing and I don't know it"; COMP: "Do the first 13 weeks matter at all?" RECOMMENDATION: one endgame sentence under the hero gap line and as the standings caption ("Top 2 seed into the 4-week Cup Final from Dec 22 · scored fresh · the leader starts +10"), a permanent Cup Final countdown in the Season tile, a fifth "The finish" section in the explainer with §14.3's ladder, tap-to-explain on LOCKED and the Climb note.

**E-F2 · P1 · Home shows one league, and it is whichever you last opened.** OBSERVATION: the WTB standing (2nd, 10 back) was invisible on Home for ten minutes; the hero silently switched after a Clubhouse visit. INTERPRETATION: `renderHomeHero` renders `CS.league` only; the "Switch groups anytime from Home" status names nothing visible. IMPACT: the league where the member is losing — the one that needs a nudge — is hidden. RECOMMENDATION: a per-league row (name · rank · gap · next deadline) on Home, or a visible switcher.

**E-F3 · P1 · The numbers disagree.** OBSERVATION: E.4 — August round counts, 3.3 vs 2.6, three index deltas, 14 vs 13 weeks, an empty Board under an 18-item Home, the gap line on the wrong row. INTERPRETATION: PvI computed at 100% in the feed and 95% in the view with no allowance row; board rows dated by posting; two week-count sources on iOS; per-surface copy. IMPACT: "the single most basic fact about the season is inconsistent between the two most-visited screens; it undermines trust in every other number" (IOS). RECOMMENDATION: one PvI producer (feed reads `v_rounds_ranked.pvi` in-window), "posted" vs "played" labels, one week-count source, render the gap on the viewer's row, name the leader on iOS Home.

**E-F4 · P2 · The pot is a bill with no instructions.** OBSERVATION: "$150 · $0 collected · 2 still owe" six weeks in; "0/2 buy-ins in"; no payee, method or due date; member rows are buttons that toast "The Pro marks buy-ins". INTERPRETATION: the ledger schema has no payment-note or deadline field; D106 (owed vs collected) is proposed, not built. IMPACT: stakes are stated, not felt (OBS stakesMeaningful 3). RECOMMENDATION: a Pro-set "Pay Casey — Venmo @…" line on the Pot tab and in the covenant; member rows as status; an unpaid-buy-in nudge on Home.

**E-F5 · P2 · Nothing leaves the app.** OBSERVATION: no share on the scorecard sheets or stories; "Share the card" invisible; zero product emails or pushes in 60 days beyond sign-in codes; notification toggles read "ON" under an unpressed "Enable on this device" (SKEP SK-32). INTERPRETATION: D23/D27 chose Home-surfaced nudges over push by policy; the shareable objects were never given a share control (`openScorecard` at `index.html:10512` has none). IMPACT: "The app creates screenshot-worthy objects but no social objects that leave it on their own." RECOMMENDATION: share/export on the scorecard and story sheets; a month-close / floor-warning email or push the member opted into.

## E.9 Verdict — 5/10

This is the product's best stretch and it still only half-works. For the one league Home chooses to show, "where do I stand?" is answered in three seconds with a name and a number — the only place in the whole audit that happened — and the in-season round card ("85 GROSS · A LITTLE LOOSE · COUNTING #2 THIS MONTH · 6 PTS") is the model the rest of the app should copy. But "what do I do to win?" is answered nowhere; the finale that the product is named after is a collapsed bylaw row and a sort that hides its own countdown; the second league is invisible; the floor is a threat with no stated consequence; the pot has $0 in it and no way to change that; and the account's own numbers disagree with each other on four surfaces. For a fresh five-player league the same screens show zeros, gross-only feed cards, undrawn squads described three ways, and a rival the app never names. The observer's lifecycle scores say it plainly: 6 mid-season, 4 late, 3 at the finale.

---

# Journey F — Season finale

**What could not be observed, stated plainly.** No account in the audit had a finished season: OBS's two leagues are both `SEASON I` and live (weeks 6/26 and 4/13); the two audit leagues were seven days pre-season. Nobody saw seeds lock, a Cup Final window open, a month close with a podium, a tie break, a ceremony, a settlement card, a trophy room, or the season-end email. Everything below is (a) what the live app *says* about endings on the screens a member can reach, (b) what the code and decision log say is built for endings, and (c) the observer's projection. The scores are projections and are labelled as such.

## F.1 What the live app says about endings (exact copy, all surfaces found)

| Surface | Copy | Taps from Home | Who found it |
|---|---|---|---|
| League tab › "▸ LEAGUE RULES & PRO SHOP" › bylaws | "CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh" (Fellas) / "from Sun Dec 6" (Papago Grind) / "from Sun Nov 8" (Desert Dogs) — `index.html:12100` | 4 + a disclosure | OBS, ORG, NOV, JOIN, CAS, COMP, SKEP — "the ONLY place the app told me the season ends with a Cup Final" (OBS) |
| Wizard › Customize › How it ends (i) — **Pro only** | "Cup Final: the last four weeks reset and score fresh — top seeds only, whoever's hottest takes the cup." / "Points table crowns whoever leads when the season ends: the whole year is the race, no reset." | Pro-only | ORG, NOV — "'top seeds only' — how many? What happens to non-seeds?" |
| Wizard › Teams sub-copy — **Pro only** | Solo: "top 2 players meet in the Cup Final in the final four weeks." 2 Squads: "Both squads reach the Cup Final; the regular-season leader carries a +10 head start." 3 Squads: "Cut line after 2nd: top 2 advance." | Pro-only | ORG — "'+10 head start' — 10 of what?" |
| Standings › The Climb captions | "LOCKED" ×2 · "JERECHO FISCHBECK HAS LOCKED A CUP SEED" · "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" (live league); "TOP SEED · +10" · "TOP 1 ADVANCE · PROJECTED UNDER A GENEROUS CEILING" (empty league) | 1 + scroll | OBS, NOV, IOS — none could define seed, LOCKED, advances, ceiling |
| Standings › Season tile | "SEASON W6 / 26 · Week closes Sun · 1d" — the Cup Final line exists in `#statFinal` and loses the nearest-deadline sort (`:9614-9637`) on every day but one of the run-up | 1 | OBS, IOS |
| Pot tab | "$90 Cup champs · $38 Runner-up · $23 Points king" · "Cup Season keeps the books … shows a settlement card; the money moves between you." | 2 | all; "Cup champs" plural with no per-member split |
| "Leagues vs events" (You › How it works) | "…every round you post counts toward a table, and the endgame settles it: a Cup Final or the points table." | 2 + scroll | SKEP, OBS, JOIN |
| "How scoring works" | four sections — Your number / Every round → cup points / What counts / The money. **No finish, no seeds, no ties.** | 2–4 | all |
| You › THE RECORD | "No silverware yet — every season starts level." · "LEAGUE RECORD: Fellas SEASON I · 1ST OF 2 · 32 PTS" · "Cups & events 2 · Played in" (which two? not linked) | 1 | OBS |
| Season card | "Season live · Mon Jul 20 → Mon Jan 18 · 26 wks" — "the end is a date in a range" | 1 | OBS |
| Ties | **Nothing.** "Not in bylaws, scoring sheet, standings footnote, or the welcome sheet" (COMP, confidence 1/10). §14.3's ladder (h2h months won → best single month → fewest rounds used → logged coin flip) exists in `close_season` and `seed_rung`, and in no copy | — | COMP, OBS |

## F.2 The finale questions

| Question | Answer from the live app | Copy |
|---|---|---|
| How does the season end? | A "Cup Final" in the final four weeks, "scored fresh" — undefined | bylaw row only |
| When? | A date in a bylaw row; no countdown on Home or Standings (the Season tile shows "Week closes Sun") | "from Tue Dec 22" |
| Who plays it? | Not stated to members (Pro-only wizard copy says both squads / top 2) | "top seeds only" (Pro) |
| What happens to my accumulated points? | Not stated. "Do the first 13 weeks matter at all if the final 4 are 'scored fresh'?" (COMP); "the lead I've watched for 22 weeks may mean nothing" (OBS) | — |
| How do ties break? | Nowhere | — |
| What does winning pay *me*? | A squad share ("Cup champs $150") with no per-member division; the pot has $0 collected | Pot tab |
| What does the ending look like? | Unknown. "THE RECORD · No silverware yet" is the only trace of a trophy | You |
| Will I be told? | No countdown, no "final starts in N weeks", no preview of the settlement card; no emails in 60 days beyond sign-in codes | — |

## F.3 What is built for the ending and could not be seen

| Mechanism | Decision | Status per code | Why no tester saw it |
|---|---|---|---|
| Season-long foreshadow ("Season crowns 2 Cup seeds · Cup starts fresh Dec 22") | D4 (2026-07-15: "reads as a rug-pull") | `#statFinal` option at `index.html:9614-9637` | Suppressed by its own "nearest deadline wins" sort — validated by reproducing the arithmetic: the Cup Final line wins on 1 of 155 pre-window days |
| Cup Final race view (seeds, +10, rounds used) | D105 (2026-08-28, PROPOSED) | `cup_final_race` read at `:14605`; block at `:4533-4541` | Gated to `season.status==='cup_final'` — appears only once the window opens, the exact moment D4 called the rug-pull |
| Magic-number / clinch line | D24 | `renderScenarioLine` `:14803+` | Renders "HAS LOCKED A CUP SEED" with no explanation of the words |
| Season-end takeover with margin, deciding rung, per-person payout | D66 | `csSettlement` `:11641-11714` | No completed season; nothing on a live season previews it |
| Season-end email "The Cup goes to <champ> by <gap> — <league>" | D68 | `supabase/functions/season-email/index.ts:251` | No completed season |
| Career record / titles | D67 | `career_record()` | Nothing to aggregate |
| Pot: owed vs collected, ceremony pays from cash | D106 | **PROPOSED** | "$0 collected" beside computed payouts ($90/$38/$23) is the un-built decision |
| Month-close podium | D53 | `20260727160000_board_voice.sql` | Both observer leagues' first close was a partial month → "July closed — Ledger posted · Partial month, floors waived" only |

## F.4 USER ASSUMPTION / ACTUAL PRODUCT BEHAVIOR (verbatim)

- **UA:** "'LOCKED' = my place in the standings can't change." **APB:** "I 'locked a cup seed' — apparently a seat in a later 'cup'." (OBS)
- **UA:** "'Cup champs $150' is what I win." **APB:** "unknown — probably a squad share; never stated." (COMP)
- **UA:** "the top squads start fresh and whoever's hottest wins the pot." (NOV) vs **UA:** "the regular season is only for seeding (guess)." (COMP) vs **UA:** "a final few weeks that decides who takes the pot." (SKEP) — three readings of one row, none confirmed.

## F.5 Major finding

**F-F1 · P1 (projected P0 at `ends_on − 27`) · The name of the product is a bylaw row.** OBSERVATION: eight of eight personas could not explain how the Cup is won; the only member-facing sentence is "CUP FINAL · Final 4 weeks · from … · scored fresh" four taps deep; the built foreshadow is out-sorted by "Week closes Sun"; the ladder exists only in SQL. INTERPRETATION: the mechanic (§14.3) and the engine (`season_scenarios`, `cup_final_race`, `close_season`) are complete; every pre-window member surface was authored without an endgame slot, and the vocabulary shipped without definitions. IMPACT: "the Cup Final arrives unannounced; the lead I've watched for 22 weeks may mean nothing and I don't know it" — observer late-season return 5, finale 4. A two-player league where "everyone advances" is structurally hollow and nothing warns the Pro. RECOMMENDATION: a permanent Cup Final countdown from lock onward (the "persistent banner real estate" D4 already accepted); one endgame paragraph from §14.3 reused in the explainer, as the bylaw row's tap target and behind LOCKED; rewrite the two jargon captions in member words; preview the settlement card during the season; build D106 before any pot is paid out.

## F.6 Verdict — 2/10 (projection)

"The database reached its final row." (OBS.) Judged only on what a member can see before the last four weeks, the season has a beginning and a middle and no end: no countdown, no bracket or seed graphic, no tiebreak text, no statement of what the lead converts into, no preview of what winning pays, and a pot nobody has paid. The ceremony, the email, the career record and the run-it-back card are the best-designed beats in the decision log and the least-evidenced in the product; the audit could not see any of them fire, and neither can a member until the day the reset happens.

---

# Journey G — Start another season

**What could not be observed.** No season has completed on any account; "Run it back" (`runItBack`, `index.html:14383`, hero "Season wrapped · Your name goes on the cup. · [Run it back — Season 2]" at `:10026-10033`) was unreachable. D41 makes "Run it back" open the wizard prefilled with a `· S2` name as a **new league id** — "continuity by convention"; "defending champs" and the margin line were explicitly deferred.

## G.1 What the live app offers a member between seasons

| Signal | Copy / evidence |
|---|---|
| A title to defend | "THE RECORD · No silverware yet — every season starts level."; "SEASON I" on every league record; "Cups & events 2 · Played in" unlinked |
| A recap object | none visible on a live season; D30's recap PNG ("Share the card") produced a hidden "Card downloaded" |
| A reason in the inbox | "No app emails/notifications were received in 60 days" other than sign-in codes (OBS Gmail search 13:46). Email inventory in code: sign-in code, buddy request, season-end ceremony (D68), cancellation. No month-close, floor-warning, clash or "your rival just posted" email; V1 nudges are Home-surfaced by policy (D23/D27) |
| A rival | "RIVALRIES · YOUR RECORD · Jade 2–0 · Galen 1–0" (live-match record, two taps down); no rival is chosen or announced by the app |
| A price | "CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE"; "PLAN FREE · PILOT"; no number anywhere (D101's $89/league-year, first year free, is decided and unshown) |
| History | none — "There is no multi-season record yet to leave behind" |

## G.2 The question, answered by the personas

"I just finished a season — why would I start another?"

- **OBS:** "To beat Galen — he's the only name the app made me care about — and only if more of the group is actually in it. The cup final is a line in the bylaws, the pot was never collected, and the app never told me what winning would have meant." If the group stayed at two: "fun, but I don't need the app again." Lifecycle projection: season + 1 day 3/3/3/3/3/3; season + 30 days 2/2/2/2/2/2.
- **SKEP:** "If Cup Season disappeared tomorrow … Immediately: nothing — the season hasn't started, and my 91 lives in 18Birdies too." What cannot be replaced: "The rule set — best-4-a-month vs your own index, the floor, the squad race, the Cup Final 'scored fresh' — automatically applied across any course, and the receipt that shows the math for every point. **That is the product. It is also the part the app hides.**" On paying $79/year: "I'd pay $79 split six ways for THAT, if it were visibly true on day one. Today I've seen the ledger and the formula; I haven't seen the race."
- **COMP:** "Fix the endgame explanation, the pre-season honesty and a head-to-head view and I'd care; as shipped I'd play for the skins and shrug at the table."
- **CAS:** "Would I open this between rounds? Yes, a little, for the feed … The 'MONTH CLOSES in 2 days / lose 5 points' banner is the opposite of a reason to open it; it's a reason to feel guilty."
- **ORG:** would play again 7 — "Fix the lock bug and the invite-by-contact gap and this becomes a 7"; would pay "~$5/player if the Pro Shop is the price; unknown."

`wouldPlayAgain` across personas: 7, 6, 5, 6, 5, 7, 4, 6 (mean 5.75). `wouldPay`: 5, 4, 3, 5, 3, 5, 2, 3 (mean 3.75).

## G.3 Major finding

**G-F1 · P1 · Nothing pulls a lapsed member back except a friend.** OBSERVATION: no title, no history, no recap, no rival named by the app, no email between the buddy request and the (unseen) season-end mail, no price. INTERPRETATION: the renewal moment is designed (D41, D66, D67, D68, D101) and unproven; D41 mints a fresh `SEASON I` league, so title defense stays absent by decision; push is opt-in behind an unpressed "Enable on this device". IMPACT: the observer's +30-day projection is 2/10 on every dimension; `wouldPay` 3.75. RECOMMENDATION: (1) preview the ceremony during the season so a member sees what winning looks like before it is decided; (2) D106 so "you're owed $90" is cash; (3) true multi-season continuity — same league, "defending champs", the margin line; (4) one off-app touch per month (month-close result, floor warning) the member opted into; (5) state the price where the buy-in is set.

## G.4 Verdict — 2/10 (projection)

The only renewal reason any tester could name was a specific person, and the app gave them that person by accident (two-player leagues). Everything the product intends to make a season worth repeating — a title on the wall, a margin to avenge, a rivalry record, a recap in the group chat, an email that says who took the cup — is either built and invisible or explicitly deferred. Until one real season closes and its ending is watched, "why start another" has no answer the product itself supplies.

---

# Cross-journey table — P0 / P1 friction points by journey

Severity is the master-dataset severity (`issues.json`); type uses the triage vocabulary (repeat · guess · interpret · navigate · ask · confirm · calculate · wait · leave-screen); "Validated" marks the items re-tested by the fifteen adversarial validators (all confirmed, with the two refuted sub-claims noted in the front matter). Master IDs reference `issues.json`.

| # | Journey | Friction point | Sev | Type | Who hit it | Master / validation |
|---|---|---|---|---|---|---|
| 1 | A | The door explains nothing beyond a nine-word slogan; no how-it-works, cost, length, team structure | P1 | guess / ask | 8/8 | M-143 · TOP-2 (weaker component: an owner decision, D83) |
| 2 | A | Invite landing shows only the league name; "Enter your email and you're in" | P1 | interpret | JOIN, CAS, COMP, SKEP | M-024 · TOP-2 confirmed |
| 3 | B | Consent sheet withholds roster, Pro, dates, scoring and payment path before "Join — I'm in for $50" | P0 | guess / ask | JOIN, CAS r1, SKEP r1, COMP r1 | M-023 · TOP-2 confirmed (RPC returns five fields) |
| 4 | B | "Not now" drops the invite; code must be retyped | P1 | repeat / remember | JOIN, CAS r1 | M-025 · TOP-2 confirmed (`cs_code` removed pre-covenant) |
| 5 | B | "PRESET Standard" on the consent sheet, defined nowhere; tapping does nothing | P1 | guess | JOIN, SKEP r1, COMP r1 | M-026 |
| 6 | B | No invitation email exists; sign-in mail says nothing about the league; identical subjects thread 20 codes | P1 / P2 | leave-screen | JOIN, CAS, COMP, SKEP | M-002 / M-029 |
| 7 | B → E | Member Home hero = "Lock it in and invite your crew" → live "Lock the bylaws & form the squads" → "Cancel this league? … discards it completely" | P0 | navigate-back / confirm | JOIN, CAS, COMP, SKEP | M-030 · TOP-3 confirmed live; role- and phase-blind (`index.html:10072-10116`); "You tab → wizard" sub-claim refuted as harness artifact |
| 8 | B → E | Member Home leads with Start / Start / Join pills and "Join a league" highlighted after joining | P1 | interpret | CAS, SKEP, OBS, JOIN | M-033 |
| 9 | B / D | "MONTH CLOSES in 2 days" + floor threat seven days before first tee; floor copy on the league-less Home | P1 / P2 | interpret | CAS, SKEP, COMP, ORG, NOV | M-042 |
| 10 | C | Lock reports failure after committing; 12 of 12 taps; later Solo retry silently discarded; Pro never sees success | P0 | repeat / leave-screen | ORG, NOV | M-001 · TOP-1 confirmed (`index.html:15218`; prod `lock_ok` = 1 all-time, pre-D97; `lock_fail` = 11, all 2026-08-29) |
| 11 | C | No invite-by-email/SMS; "Add golfers" finds only accounts (and strangers); link never printed; every share → code toast | P0 / P1 | repeat / ask | ORG, NOV (+ every share tap by all) | M-002, M-003 · TOP-1 (toast = double fallback; URL-as-text only on the unreachable sheet) |
| 12 | C | Buy-in defaults to a hidden $75 behind "Customize"; steps skip $10/$20 | P0 | read / navigate | ORG, NOV | M-004 (upgraded to P0 in triage) |
| 13 | C | Three lock moments on one screen; "Lock opens the invite link" while the code already exists | P1 | think / confirm | ORG, NOV | M-006 |
| 14 | C | "Minimum four to tee off" revealed on the last step, then bypassed (solo path skips `start_season`) | P1 | guess | NOV | M-007 |
| 15 | C | Teams control: highlight says 2, caption says 4, note says solo | P1 | guess | NOV, ORG | M-008 |
| 16 | C | "GHIN rounds" (card) vs "VERIFICATION Attested" (review) vs "auto-attested" (live) | P1 | interpret | ORG, NOV, JOIN | M-011 |
| 17 | C | Seven undefined tokens per preset card; "unlocks with Pro Shop" above a free Customize | P1 | read | ORG, NOV | M-010 |
| 18 | C | "Draw failed. Something went wrong" over the server's usable sentence | P1 | repeat | ORG, NOV | M-017 |
| 19 | C / E | One league, four statuses ("forming" / "Squad formation" / "LIVE NOW — CAPTAINS READY" / "is live"; "Complete · rosters locked" over empty squads) | P1 | interpret | ORG, NOV, JOIN, CAS, COMP, SKEP | M-041 · TOP-3 (status strings per component) |
| 20 | C / E | Rules four taps deep behind "▸ LEAGUE RULES & PRO SHOP"; "bylaws §4" cites nothing served; the manual is the last block on You | P1 | navigate | 8/8 | M-054 |
| 21 | C | Uneven squads, seeds, +10, squad split of 60% — no worked example | P1 | ask | ORG, COMP, SKEP | M-009 |
| 22 | C | Global user directory; "Findable by: All" default | P1 | — | ORG | M-019 |
| 23 | D | Install banner sits exactly over the ⊕; two dead taps | P1 | repeat | ORG (+ NOV's double "Add") | M-018 |
| 24 | D | Pre-season round: "LEAGUE POINTS THIS ROUND 5/6/12" → "COUNTS ON YOUR CARD" → 0 R · 0 Pts → "post one and you're on the board"; Home "Rounds count from today" vs Clubhouse "practice rounds" | P0 | navigate / guess | 6/6 posters | M-040 · TOP-4 confirmed (four PvI producers; window only at the ceremony) |
| 25 | D | Sign convention inverted on form, receipt, Standings, You ("-3.7", "Best vs index -3.7 · Career best") | P1 | interpret | 6/7 | M-045 · TOP-4 confirmed (D1 applied to one of five surfaces) |
| 26 | D | Rating/Slope placeholders read as values; typing nines closes the tee list; "-79.0 vs your index" with Post enabled | P1 | repeat / interpret | CAS (4 attempts), SKEP r1 (5 attempts), COMP | M-076 |
| 27 | D | Blank date after "Start over" → "Post failed. That didn't go through — please try again." (not-null on `played_on`) | P0 | repeat | SKEP r1 | M-159 · orchestrator-verified; `index.html:6846`, `:6501`, `:4116` |
| 28 | D | Course search: five 502s, no message ("TPC Scottsdale", "Papago"); duplicate "Papago" rows; 502 on first tee pick | P1 / P2 | guess / repeat | COMP r1, JOIN, all | M-160, M-077, M-086 · orchestrator-verified |
| 29 | D | Receipt: no points row, no allowance row, no correction path; delete only via an unlabelled ✕ on You with a native confirm and no undo | P1 | navigate / confirm | ORG, NOV, CAS, COMP, JOIN | M-044, M-080 · TOP-4 |
| 30 | D | "beat by 3" is differential not strokes; 95% allowance applied nowhere visible; the two engines straddle a band (3.3 vs 2.6) | P1 | calculate | COMP, ORG, NOV, OBS | M-046, M-047, M-049 · TOP-4 |
| 31 | D | A 103 posted to a member's card by another member's live game; no notice, no dispute; one phone attests four cards | P1 | ask | CAS (COMP as the writer) | M-093 |
| 32 | D | "Scrap this round" dead (CAS) / confirm reverts before the second tap (CAS r1) | P1 | repeat | CAS (NOV saw a working two-tap) | M-090 (unresolved) |
| 33 | D | `[live-resume]` embed fails on every boot; the promised "Continue your round" banner never appears | P1 | navigate | all sessions | M-085 · orchestrator-verified (`index.html:7800`) |
| 34 | D | Three stacked post-round sheets; first-round "Broke 90 / Broke 100" trophies; "Turn off this link" for an unrequested link; badges survive deletion | P2 | read / confirm | all posters | M-078, M-079 |
| 35 | E | Cup Final one bylaw row; LOCKED / seed / advances / "generous ceiling" undefined; foreshadow suppressed by its own sort; ties nowhere | P1 | navigate / ask | 8/8 | M-055, M-056 · TOP-5 confirmed (`#statFinal` wins 1 of 155 days) |
| 36 | E | Floor explained three inconsistent ways; wizard (i) still says "Pro-approved bye" (pre-D14) | P1 | interpret | JOIN, SKEP, NOV | M-057 · TOP-5 |
| 37 | E | Home shows one league — the last opened in the Clubhouse; no switcher | P1 | navigate | OBS | M-072 |
| 38 | E | Board dates vs standings counts (two Aug 27 rounds vs "you've posted 1"); one round "3.3" vs "+2.6 · 9 PTS"; index delta three ways | P1 | calculate / interpret | OBS | M-120, M-047, M-121 |
| 39 | E | HELD / AUG FLOOR 1/2 / MONTH CLOSES undefined on the hero; "what happens at close" never said | P1 | guess | OBS, IOS, CAS, SKEP | M-059 |
| 40 | E | Schedule tab exits the Clubhouse to a global calendar with "← HOME" | P1 | navigate-back | 7/7 + IOS | M-070 |
| 41 | E | No rival, gap-to-leader, head-to-head or "this round matters because" line; no clash chip observed | P1 | ask | COMP, OBS, CAS | M-123 (D51 unbuilt; D108 unobserved) |
| 42 | E | Pot: how to pay, to whom, by when — never stated; $0 collected at week 6; member rows are buttons | P1 | ask | JOIN, CAS, SKEP, OBS | M-110 · TOP-5 (✓ sub-claim refuted; feature gap confirmed) |
| 43 | E (iOS) | "WEEK 4 OF 14" vs "WK 4 / 13" | P1 | interpret | IOS | M-145 |
| 44 | E (iOS) | Board "◆ Your league is live — post the first round" while Home shows 18 items; web Board header "ROUNDS LAND HERE AUTOMATICALLY" while pre-season rounds land only on Home | P1 | interpret | IOS, CAS | M-084 |
| 45 | E (iOS) | Gap line "10 back of Galen" under Galen's row; leader unnamed on Home; "2nd" of an unstated 2 | P1 | interpret | IOS | M-129 |
| 46 | E (iOS) | Live setup has no title, no exit, no game named; post placeholders 41/43 read as values; "A preview at 100% of your number — your league's own math scores it on the books" | P1 | interpret | IOS | M-102, M-150 |
| 47 | E (iOS) | Nothing on 11 screens says what a point is or how a season is won | P1 | ask | IOS | M-144 |
| 48 | F | No countdown, bracket, tiebreak text or settlement preview before the window; two-player "everyone advances" hollow and unwarned | P1 (P0 at `ends_on − 27`) | ask | OBS, COMP, NOV | M-124 · TOP-5 |
| 49 | G | No title, history, recap, named rival, email or price between seasons; "Run it back" mints a fresh SEASON I | P1 | — | OBS, SKEP | M-126, M-133, M-012 |

Journey scores: **A 3 · B 3 · C 2 · D 4 · E 5 · F 2 (projection) · G 2 (projection).**

---

## Appendix A — Persona score sheet (as reported)

| Persona | concept | setup | rules | pickUp | gameplay | sideGames | stakes | invite | again | pay | verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| ORG (Casey) | 5 | 4 | 5 | 4 | 7 | 8 | 6 | 4 | 7 | 5 | 3 |
| NOV (Dana) | 5 | 4 | 5 | 5 | 7 | 7 | 6 | 4 | 6 | 4 | 4 |
| JOIN (Marcus) | 5 | 4 | 5 | 4 | 6 | 4 | 6 | 4 | 6 | 5 | 3 |
| CAS (Jordan, r2) | 5 | 5 | 3 | 4 | 5 | 6 | 6 | 4 | 5 | 3 | 4 |
| COMP (Priya, r2) | 6 | 5 | 4 | 7 | 5 | 8 | 5 | 6 | 7 | 5 | 5 |
| SKEP (Sam, r2) | 4 | 4 | 4 | 6 | 4 | 4 | 5 | 3 | 4 | 2 | 3 |
| OBS (observer) | 7 | — | 3 | 6 | 5 | 5 | 3 | 5 | 5 | 3 | 4 |
| IOS survey | 4 | 3 | 3 | 5 | 6 | 4 | 4 | 5 | 6 | 3 | 4 |
| **Mean** | 5.1 | 4.1 | 4.0 | 5.1 | 5.6 | 5.8 | 5.1 | 4.4 | 5.75 | **3.75** | 3.75 |

The pattern across every journey: `sideGames` and `gameplay` are the highest columns (the people who *ran* a live game scored it 7–8; those who only read about it 4–5); `rules`, `setup` and `pay` are the lowest. The mechanic is liked; its legibility, its setup and its price are not trusted.

## Appendix B — Test footprint

| Item | Detail |
|---|---|
| Accounts | jerecho+blind1 (Casey, Pro of The Papago Grind) · +blind2 (Marcus) · +blind3 (Jordan) · +blind4 (Priya) · +blind5 (Dana, Pro of Desert Dogs) · +blind6 (Sam) · +blind2x (a diagnostic send during JOIN's first attempt; never signed in) · jerecho@fischbeck3.com (owner's real account, read-only; DB check: 0 rounds, 0 posts written) |
| Leagues | **The Papago Grind** (THEPTCQ5; Pro +blind1; members +blind2/3/4/6; 2 squads · blind draw · Standard · $50 · 4 mo · Sat Sep 5 → Sat Jan 2 · Cup Final; phase `draft`, squads undrawn) · **Desert Dogs** (DESEUU0K; Pro +blind5; 1 member; $25 · 3 mo · Sat Sep 5 → Sat Dec 5; first lock 2 squads, later Solo retry rewrote settings; phase `season`) |
| Rounds | Papago Grind: Casey 87 (deleted), Marcus 87, Jordan 97 (+ a 103 attested by Priya's live skins round), Priya 74 (Aug 27) + 84 (Aug 25) (earlier-run duplicates deleted and re-posted) + 78 live, Sam 91, Casey 93 and Marcus 89 (attested by Priya's live round). Desert Dogs: Dana 91 |
| Live games | A $5 match-play story "Casey def. Marco 1 UP THRU 3" (guest **Marco**, index 18); a full 18-hole $5/skin skins round (Priya 78, Casey 93, Marcus 89, Jordan 103; "Priya took 7 skins and $60"); Jordan's abandoned $5 match vs Casey (hole 1 scored; scrap dead); Dana's 2-hole skins round with guest Mike (scrapped) |
| Board / Pot artifacts | pride stakes "Loser buys the beers · Jordan vs Casey" and "Low net of September · Priya vs Casey"; a chat line "Sam · 91 at Papago. Casey you owe me a beer for the Grind sign-up."; tee-sheet entries Sat Sep 5 Papago (Jordan tagging Casey; Priya 07:30 tagging Casey + Marcus); buddy request "Priya wants in your crew" to Casey |
| Sessions (UTC) | ORG 13:18–14:06 · NOV 13:18–14:05 · OBS 13:18–13:47 · CAS r1 14:12–14:40, r2 15:21–16:01 · COMP r1 14:12–~14:45, r2 15:21–16:03 · SKEP r1 14:12–14:44, r2 15:21–15:49 · JOIN attempt 1 14:12–14:52 (harness artifact), attempt 2 15:21–15:46 · IOS r1/r2 15:21–15:27 |
| Console signatures seen in every session | `[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'` (every Home/Board load after a live round); `Failed to load resource: 502` during Post round (CAS ×3 twice, SKEP, JOIN, COMP) and on Tee off (COMP ×3); five 502s on course search (COMP r1); `[cs] error: Lock failed. staged is not defined` ×12 (ORG, NOV); `Draw failed. Not enough golfers to cover every squad — 1 in, 2 squads. Share the invite link first.`; `Could not discard. commissioner only` (JOIN); `null value in column "played_on" violates not-null constraint` (SKEP r1); `[cs] Boot stalled at [league-data] — network or auth hang` with a 6–8 s sign-in door on every cold open for a signed-in user (NOV); "Multiple GoTrueClient instances detected" |

## Appendix C — Evidence index (fast lookup)

- **Door / landing:** `screenshots/skep/02-cold-door.jpg`, `screenshots/org/01-door.jpg`, `screenshots/join/01-A-cold-door.jpg`, `02-B-join-link-landing.jpg`, `03-C-invite-code-tap.jpg`; validators `shots/v-TOP-2/01-04`, `v-TOP-1/01-join-landing.png`. Code `index.html:22, 1818-1819, 2635, 17815-17832, 17914-17918`.
- **Consent / welcome:** `screenshots/join/11-J-after-take-me-in.jpg`, `12-K-not-now.jpg`, `13-L-join-a-league.jpg`, `16-N`, `17-N-after-join-full.jpg`; `screenshots/org/95-join-link-view.jpg`; `screenshots/cas/15-B03b-welcome-full.jpg`. Code `:15422-15440, 17299, 17564`; migration `20260722211500` (`join_covenant_info`).
- **Member Home / lock leak:** `screenshots/join/20-P-home-member.jpg`, `39-U-lock-it-in.jpg`, `56-AI-you-escape.jpg`; `screenshots/cas/19-C02b-home-full.jpg`; `screenshots/skep/09-home-full.jpg`, `50-lock-page.jpg`; `screenshots/comp/19-lock-tap.jpg`; validators `shots/v-TOP-3i/01-02`. Code `:10072-10116, 10102, 14500, 4163, 15527`.
- **Wizard / lock:** `screenshots/org/15`–`36`, esp. `22-cust-buyin.jpg`, `23-cust-teams.jpg`, `30-wizard-step3.jpg`, `31-after-lock.jpg`; `screenshots/nov/12`–`34`, esp. `19-wizard-customize-full.jpg`, `27-cust-teams2.jpg`, `33-lock-fail-toast.jpg`, `34-reload-home.jpg`, `35-clubhouse-1.jpg`. Code `:3263, 3325, 3793, 12030, 15122-15219, 15218, 15494-15505, 4106-4117`; commit `1fd47e1` (D97).
- **Invites / status / rules:** `screenshots/org/37`–`53`, `60-season-share-tap.jpg`; `screenshots/nov/44`–`53`; `screenshots/skep/13-tab-League.jpg`. Code `:3416, 3506, 12231, 14127, 14135-14170, 14890`.
- **First round:** `screenshots/org/62, 65, 68, 69, 71, 72, 73`; `screenshots/nov/65, 67, 68, 71, 72, 73, 74, 77, 78`; `screenshots/join/41, 43, 45, 46, 47, 48, 51, 52, 53`; `screenshots/cas/42, 46, 48, 51, 52, 53, 56, 57, 58, 61, 86, 87, 93`; `screenshots/comp/34, 35, 38, 40, 41, 42, 45, 47, 48`; `screenshots/skep/28, 31, 32, 33, 36, 37`. Code `:3191-3198, 6306-6341, 6339, 6584-6596, 5709, 7800, 10076, 10105, 3428, 12225, 11480-11524, 11912, 4116`; migration baseline `:1347-1393` (`v_rounds_ranked`); commit `75682a1`.
- **Mid-season:** `screenshots/obs/04, 05, 07, 08, 09, 10, 12, 13, 19, 21, 22, 28, 29, 35, 36, 37, 42, 45`; `screenshots/ios/01, 03, 04, 05, 06, 09, 11`. Code `:4478-4480, 9614-9637, 10185, 10190-10198, 12100, 14803-14823, 17274-17296, 4613`.
- **Endings (built, unobserved):** `index.html:4533-4541, 9614-9637, 10026-10033, 11641-11714, 14383, 14605`; `supabase/functions/season-email/index.ts:251`; migrations `20260828170100_cup_final_race.sql`, `20260727160000_board_voice.sql`; decisions D4, D24, D41, D53, D66, D67, D68, D105, D106.
- **Validation verdicts:** `raw/synthesis-and-validation-results.json` → `verdicts[]` (15 entries, three lenses × five findings); companion syntheses `synthesis-triage.md` (friction F1–F63, confusion debt 1–48), `synthesis-rules-mental-model.md` (45 rules scored), `synthesis-loop-hierarchy.md` (T1–T7, screen hierarchy), `synthesis-retention-monetization.md` (lifecycle, emotional loop), `synthesis-sidegames-setup.md` (wizard S0–S4, P1–P7), `synthesis-terminology.md` (~120 terms).

---

*Companion documents in this folder: `README.md` (start here) · `blind-ux-audit.md` (master report) · `critical-findings.md` · `gameplay-loop.md` · `rules-and-mental-model-audit.md` · `retention-audit.md` · `issues.json` / `issues.csv` / `issues-counts.json` (`issues-README.md`) · the six `synthesis-*.md` files · `raw/` · `screenshots/`.*
