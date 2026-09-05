# Persona E — Jordan, the invited joiner

**Who I am.** Jordan Reyes, 29, Mesa AZ. I shoot 95–100 on a good day, I've never had a handicap, never been in a league. My buddy Casey texted me on Friday Sep 4:

> cupseason.app/?join=THEPTCQ5 — get in, $50, starts Saturday

**My goal.** What am I joining, who else is in, what does $50 buy, what do I have to do each week, and how do I win? And: where do I learn what I have to do *tomorrow*?

**How this walk was built.** I am blind to everything except (a) the App Store copy, (b) the screenshots in the three audit folders, and (c) what the SwiftUI views under `apps/ios` would actually render for someone in my state. Where a screen depends on server data I assumed the data a person in my situation would have (listed below). Every quoted string is on-screen copy the view code emits or a screenshot shows; I never read a code comment as UI. A `CLAUDE.md` was auto-injected into my context by the harness; I did not use anything from it.

**The data I assumed the server holds** (so the reader can check my sentences against the producers):

| Thing | Value |
|---|---|
| League | "The Putt Club", code `THEPTCQ5`, the Pro is Casey Nguyen |
| Structure | Individual — no squads (solo); Standard preset (95% allowance); counting cap Best 3 / mo; floor 2 / mo; $50 buy-in; 60/25/15 split; finish = Cup Final |
| Season | Sat Sep 5 → Sat Dec 5 (13 wks), locked Sun Aug 30; today is Fri Sep 4, so first tee is tomorrow |
| Roster | 8 after I join; 3 have paid ($150 collected); my buy-in row: unpaid, note "Venmo @casey-ng", due Sat Sep 5 |
| Feed | league-mates' recent rounds: Casey 91 at Dobson Ranch (Aug 30), Marcus 84 at Longbow (Sep 1); one system post from lock day |
| Casey's Saturday | he put Sat Sep 5 · 7:10 · Dobson Ranch on the tee sheet, 3 RSVP'd (I note what changes if he didn't) |
| Me | jordan.reyes@…, no rounds, no buddies, no index |

---

## The walk

### 0 · The text (0 taps, 0:00)

"cupseason.app/?join=THEPTCQ5 — get in, $50, starts Saturday." I know exactly three things: it's called Cup Season, it's fifty bucks, it starts tomorrow. The "?join=" and the code look like a link that will do the work for me. Good.

### 1 · Tap the link → Safari → the App Store (taps 1–2, ~0:20)

The app isn't installed, so the link opens a web page. I can't see the web page in this walk; I assume it points me at the App Store. What I read on the store listing:

- **Cup Season** — *Run your golf season*
- Promo: "Season three of the founding league is under way. Draft the crew, post real rounds, and race a season-long cup with standings that show their work."
- Description, first line: "**Retire the spreadsheet. Run your golf season in your pocket.**" then "Captains draft squads, everyone posts real rounds from any course, points pile up month after month, and the season ends the way a season should: with a Cup."
- "**How a season works.** The Pro sets the bylaws once — squads or solo, the handicap allowance, how many rounds count a month, the endgame — and locks them at first tee…"
- "**What it costs, plainly.** Nothing. … there are no in-app purchases."
- "**The money, plainly:** Cup Season keeps the ledger; the money moves between friends — not through the app. No wagering, no deposits, no payouts."

What I think: OK — "the Pro" is Casey. "Squads," "bylaws," "handicap allowance," "Cup" — I don't know these yet but the gist is: post your scores, points, a winner. The money bit is reassuring: the $50 is *between us*, the app isn't a betting thing. I do not read the whole 2,500-character description; nobody does. I got as far as "post real rounds from any course" and "**Nothing.**"

New words met here: *Pro, bylaws, squads, handicap allowance, Cup, the ledger, first tee, draft.*

### 2 · Install → Open (taps 3–4, ~1:30)

"Get," Face ID, wait, "Open." The app launches: a brief "Restoring your session" line, then the door.

### 3 · The door (tap 4 lands here)

The first-run door plays a little animation of the flag crest, then the words rise in:

> Rally your crew. Post real rounds.
> **Take the cup.**

Then: `EMAIL` · a field `you@example.com` · an orange **Continue with email** · "One code, no password. Codes come from the newest email." · "By continuing you agree to the Terms & Privacy Policy." · "v1 · build 1".

**What I expected and did not get:** anything that says *The Putt Club*, *Casey*, *$50*, or "you were invited." The link I tapped was the whole reason I'm here and the door does not know it. I genuinely wonder whether I need to go back and tap the link again — so I do (tap 5): back to Messages, tap the link, the app comes to the front, and… the door is identical. Nothing acknowledges the code. (Reading the code afterwards: the app *does* quietly store `THEPTCQ5` at that moment — `onOpenURL` → `JoinIntent.store` — but `DoorView` never reads `JoinIntent`, so there's no way to know. If I had *not* gone back and re-tapped, the code would never have been stored at all and I'd have come out the other side of sign-up in a league-less Home, having to type `THEPTCQ5` by hand.)

What I'd text Casey right now: "did the link work? it's just asking for my email."

I type my email (tap 6), **Continue with email** (tap 7). A toast: "Code sent." The field becomes `THE 8 DIGITS` and the note reads "Sent to jordan.reyes@gmail.com. Type the 8 digits from the newest email." with **Verify**, "Resend in 30s", "Change email".

Eight digits is more than I'm used to, but the code arrives, iOS lifts it out of the Mail notification (tap 8), and the app verifies on its own the moment the eighth digit lands — I don't even have to press Verify. "Signed in, loading…". Nice.

### 4 · The golfer card (taps 9–13, ~2:30–3:15)

Three progress bars, `YOUR CARD`, and:

**Step 1 — "Who's on the card?"** · "Just a name and a marker to start — this card follows you into every league." · `NAME` "First and last" · `@HANDLE` "handle" · "3–20 letters, numbers or _. It changes once every 60 days." I type Jordan Reyes (tap 9); the handle auto-fills `jordanreyes` and a line says "@jordanreyes is available ✓". **Next** (tap 10).

**Step 2 — "Pick your ball marker"** · "It's your face here until you add a photo — and your stamp on every round after." A 4-wide grid of little icons with names: The Saguaro, The Island, The Lighthouse, The Lone Tree, The Pews, The Dunes, The Beverage, The Shark, The Azalea, The Jug, The Wee Bridge, No. 2, The Postage Stamp, The Thistle. I pick The Saguaro because I'm from Mesa (tap 11). "City and home course live on your card — add them any time from the You tab." **Next** (tap 12).

**Step 3 — "Know your number?"** · "Optional. Your index builds itself at 3 posted rounds; a starter only helps before then." · `STARTER INDEX` "e.g. 12.4" · `GHIN (A REFERENCE ON YOUR CARD — WE NEVER RESELL OR VERIFY IT)` · "GHIN # · e.g. 1234567" · "Links your USGA record — that's identity, not your number. Your index still comes from your posted scores."

I don't have a number. I don't know what GHIN is. "Your index builds itself at 3 posted rounds" — I read that as "you need to post three rounds before you have a handicap." Is that before Saturday? I have no idea. I leave both blank and tap **Save my card** (tap 13).

Still nothing about the league. Three screens in, the invite is invisible.

### 5 · Home flashes → the join review rises (0 taps, ~3:20)

Because a code was pending, the app skips its orientation screen (the "Four places. Two ways to play." one in the screenshots — I never see it) and goes straight to the tabs. For a split second I see a Home with the Cup Season wordmark, then a sheet slides up:

> **Join a league**
> I HAVE A LEAGUE CODE
> `THEPTCQ5`
> You're invited to The Putt Club.
> [ **Join** ]

*Finally* — a name. "The Putt Club." I never tap Join; before I can, a second sheet rises over it:

### 6 · The covenant (tap 14, ~3:25)

> **Before you join The Putt Club**
> THE FINE PRINT, UP FRONT
>
> BUY-IN                 $50 / player · on the pot sheet
> PRESET                 Standard
> PARTICIPATION FLOOR    2 rounds / mo
> FINISH                 Cup Final · final 4 weeks
>
> Joining puts you on the pot sheet for $50. Cup Season keeps the ledger; the money moves between friends.
>
> [ **Join — I'm in for $50** ]
> [ Not now ]

This is the best screen so far and also the one that raises the most questions:

- "**on the pot sheet**" — I take it to mean "there's a list of who's paid." Fine. But "pot sheet" is not a phrase I've heard.
- "**PRESET · Standard**" — standard *what*? Preset of what? There's no link, no sub-line. I'm reading "the rules are the default ones."
- "**PARTICIPATION FLOOR · 2 rounds / mo**" — this is the closest thing to "what do I have to do." I read it as: I have to play at least two rounds a month. What happens if I don't? Not said here.
- "**FINISH · Cup Final · final 4 weeks**" — a playoff at the end, I guess. Who's in it? Not said.
- The button is great: "**Join — I'm in for $50**." That button is the consent. I know exactly what tapping means.

Not on this screen and I wish it were: who else is in (Casey, and who?), when it starts (Casey told me Saturday; the app doesn't), how many rounds count.

I tap **Join — I'm in for $50** (tap 14).

### 7 · Joined → the welcome (0 taps)

A toast: "Joined The Putt Club." A haptic. The covenant drops and a new sheet rises:

> **Welcome to The Putt Club**
> THREE THINGS TO KNOW
>
> **You're on the pot sheet: $50 buy-in.** The Pro tracks who's paid.
>
> **You can't hurt your standing by playing badly.** Only by not playing. Every posted round scores — a rough day is still points on the board.
>
> **Rounds score against your own number.** Beat your handicap and it's a big day, whatever you shot. Your best rounds each month count; a better round always bumps your worst.
>
> **The pot lives on the books.** Cup Season keeps the ledger; the money moves between friends. The settlement card shows who owes what.
>
> How scoring works →
> ───
> **Who else plays with you?** Growing the league isn't the Pro's chore — any member's link works.
> [ Share the invite link ]

Reactions, honestly:
- "You can't hurt your standing by playing badly. Only by not playing." — as a 95–100 shooter this is the sentence I needed. Good.
- "Rounds score against your own number." — but I *don't have* a number. The card just told me it takes 3 rounds. So what happens to my first three rounds? Nobody says.
- "The Pro tracks who's paid." — so I Venmo Casey. OK. But *when*? Not here.
- "**Who else plays with you?**" — I read this as the heading of the section that will list the roster. It isn't. It's a pitch to invite *more* people. I just joined; I don't know who's in yet; I'm being asked to recruit. This is the most misleading line in the flow for my persona.
- There is **no close button**. The sheet has a drag indicator and two doors ("How scoring works →", "Share the invite link"). I stare for a second, then swipe it down (tap 15).

I did tap "How scoring works →" first (tap 15a) because I wanted to know what my rounds would be worth. What it shows (a sheet over the sheet): **How scoring works** · HANDICAPS · CUP POINTS · THE MONEY · "Your number" — "Your handicap index builds from your scores — no typing. Every round measures how you played against the course's difficulty (rating & slope), and your best recent rounds set your number, WHS-style. It appears once you've posted **3 rounds**; until then it shows as building." · "You (or the Pro) can set a **starter** to get going sooner — but once you have 3 posted rounds, your scores take over…" · "Every round → cup points" — "Every round is scored against **your own number** — a 22-index beating their number is worth exactly what a 6-index beating theirs is:" then a card:

> **Torched it** · beat it by 3 or more · **12 pts**
> **Beat your number** · by 1 to 2.9 · **9 pts**
> **Played to it** · less than 1 either way · **7 pts**
> **A little loose** · 1 to 3 over · **6 pts**
> **Posted anyway** · more than 3 over · **5 pts**

then "The number the bands measure from is your **playing number** — your number with the league's allowance applied: Standard scores you against 95% of it, Casual 100%, Cutthroat 90%." · "The 12-point ceiling caps what a padded number can buy; the 5-point floor means a posted 98 still beats an unposted 82. **You can't hurt your standing by playing badly — only by not playing.**" · "What counts" — "Your best rounds each month count — a better round always bumps your worst counter. In a solo league the monthly minimum is a habit, not a penalty — there's no squad to dock. Your league's exact numbers are in **League rules**." · "The money" — "The pot is **on the books**. Cup Season keeps the ledger; the money moves between friends. The settlement card shows who owes what."

That table is the single clearest thing in the app: every round is worth 5–12 points, a 98 beats not playing. **But** it introduces "playing number," "allowance," "rating & slope," "WHS," "Standard/Casual/Cutthroat," "solo league," "squad" — six new words in one sheet — and it tells me the floor "is a habit, not a penalty" *right after the covenant listed "PARTICIPATION FLOOR 2 rounds / mo" as a term I agreed to*. Which is it? I'm now unsure whether I owe two rounds a month or not.

I swipe both sheets down (taps 15b, 15). The join sheet dismisses itself. Home.

### 8 · The push ask (tap 16)

Half a second later a medium sheet: **Hear it when it happens** · YOU'RE ON THE ROSTER · "A round lands on the board. A duel is closing. The table moves." · "A buddy request, a tee time, an invite — answered from the lock screen." · "Nothing else. No streaks, no noise, no badge you didn't earn." · **Turn on notifications** · Not now.

I tap **Turn on notifications** (tap 16) and accept the system prompt (tap 17). "Duel," "the board," "the table" — three more words, but the pitch is fine.

### 9 · THE FIRST HOME (at tap 17, ~4:30 since the text)

Top to bottom, exactly what renders for me:

```
Cup Season                              FRI · SEP 4    +

┌─ hero (whole card is a button) ──────────────────────┐
│ THE PUTT CLUB · BEFORE FIRST TEE                     │
│ 1d                                                   │
│ First tee in 1 day. Rounds before it build your      │
│ number.                                              │
│ Best 3 rounds a month count                          │
│ The top 2 golfers seed into a four-week Cup Final    │
│ from Sun Nov 8 — scored fresh, so the regular        │
│ season sets the seeds, not the winner. Level on      │
│ points? Months won breaks it.                        │
│ $400 on the books · $150 collected · 5 still owe     │
│ You still owe $50 · Venmo @casey-ng · by Sat Sep 5   │
│                                   See the table →    │
└──────────────────────────────────────────────────────┘

[ BUDDY'S PLAYING  Casey · tomorrow › ]          ← only if Casey booked it

AROUND YOUR BUDDIES                     YOUR BUDDIES ↗
──────────────────────────────────────────────────────
THIS WEEK
  ┌ Marcus · 84 gross · Longbow Golf Club · Sep 1  🔥 ┐
EARLIER
  ┌ Casey · 91 gross · Dobson Ranch · Aug 30      🔥 ┐
  The Putt Club · 1 earlier league note          ⌄

COMING UP                               THE CALENDAR ↗
──────────────────────────────────────────────────────
  ┌ Tomorrow · LEAGUE MATE                             ┐
  │ Casey · DOBSON RANCH · 7:10 AM         3 in  ☀ 96° │   ← only if Casey booked it
  └────────────────────────────────────────────────────┘

   Home        Clubhouse        ⊕ Post        You
```

(No lead card above the hero: pre-season there is no clash, the floor rung is off for a solo league, no rank move yet, no buddy milestone today. No other-league rows: one league. No orientation. No occasion card in early September.)

Reading it as Jordan:

- **"THE PUTT CLUB · BEFORE FIRST TEE" / "1d" / "First tee in 1 day."** — I get it: it starts tomorrow. Good. "Rounds before it build your number." — so if I play today it doesn't count for the league but builds my handicap. That answers the question the welcome left open. Good sentence, small type.
- **"Best 3 rounds a month count"** — OK, so three a month. But the covenant said "2 rounds / mo." Two *floor*, three *count*? I'm inferring; nothing says "at least 2, best 3 count."
- **The endgame sentence** — "The top 2 golfers seed into a four-week Cup Final from Sun Nov 8 — scored fresh, so the regular season sets the seeds, not the winner. Level on points? Months won breaks it." I read it three times. My translation: for two months you collect points; the top two go to a four-week playoff starting Nov 8, where the points reset; ties broken by… "months won"? What's a month "won"? This is the *how do I win* answer and it is packed into one 40-word mono line at the bottom of a card. It is *there*, which is more than most apps do. It is not *legible* on first contact.
- **"$400 on the books · $150 collected · 5 still owe"** — 8 × $50 = $400, three people paid. So the pot is $400. That's what my $50 buys: a share of a $400 pot. (The 60/25/15 split is not on Home.)
- **"You still owe $50 · Venmo @casey-ng · by Sat Sep 5"** — this is the single most useful line on the screen for me. It tells me *how* and *by when*. If Casey hadn't typed a note it would say "ask the Pro how to pay — money moves between you," which is fine too.
- **"See the table →"** — table of what? I assume standings.
- **"BUDDY'S PLAYING · Casey · tomorrow ›"** and the **Coming up** card — this is the *only* thing on Home that connects "first tee tomorrow" to a real tee time I could show up to. And it exists only because Casey put the round on the tee sheet. If he didn't, Home tells me the season starts tomorrow and nothing else: no "here's what to do Saturday."
- **"AROUND YOUR BUDDIES"** — I have zero buddies, but Marcus and Casey appear, because league-mates count. So the section header is slightly wrong for me and the content is right. The 🔥 chip invites a reaction. Tapping Marcus's face would open his "Tour Card" — that's how I'd find out who Marcus is.
- **"The Putt Club · 1 earlier league note ⌄"** — folded; I open it (tap 18) and see "The Putt Club is live — say hello on the board" · Aug 30 · then "THE BOARD ↗". OK, there's a chat. Nobody has said anything to *me*.
- **"Put a round on the calendar →"** would show if Casey hadn't booked; either way the calendar door is there.

What I would text Casey at this point: "ok I'm in — venmo'd you. what time saturday and where? and do I need a handicap first?"

### 10 · Exploring: the hero → the Clubhouse (tap 19)

I tap the hero. The Clubhouse opens on the league (the same room the Clubhouse tab shows):

**Header card:** "The Putt Club" · "Before first tee — Sat Sep 5" · chip "Code · THEPTCQ5" (tapping it opens the share sheet) · "BEFORE FIRST TEE · SAT SEP 5 · 1 DAY" · "SAT SEP 5 → SAT DEC 5 · 13 WKS · THE PRO · CASEY NGUYEN" · "Add golfers".

**Tab strip:** STANDINGS · BOARD · SCHEDULE · POT · ALBUM · LEAGUE.

**Standings pane, top to bottom:**
- A hero: "Before first tee" · "First tee Sat Sep 5" · "KICKS OFF IN 1 DAY · **SQUADS LOCKED** · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON". *Squads?* The scoring sheet just told me this is a solo league with "no squad to dock." Which squads are locked?
- The season strip: **SEASON** "— / 13" "First tee Sat Sep 5" · **THE POT** "$400" "3/8 buy-ins in" · **YOUR INDEX** "0 of 3" "Building your number" · **COUNTING ROUNDS** "0 / 3" ○○○ "September · your best 3 count".
  - "0 of 3" under YOUR INDEX and "0 / 3" under COUNTING ROUNDS are two different threes six centimetres apart. One is rounds-until-I-have-a-handicap, one is rounds-that-count-this-month. I only know that because I read the scoring sheet.
- A card: "Next up · kickoff" · "First tee Sat Sep 5. Practice rounds hit your card, not the season." · **Live round**.
- A gold card: "On the line" · "$400" · "CHAMPS $240 · RUNNER-UP $100 · POINTS KING $60 · $150 COLLECTED →". **Here** is what $50 buys, in dollars. First place $240, second $100, and a $60 "Points King" — which I take to be a separate prize for most points. Two taps from Home.
- "SEASON RACE · THE CLIMB" — the eight of us listed at 0 points. Then "STANDINGS" — a table, `PLAYER · Δ WK · PTS`, all eight names, "0 ROUNDS", "WK 1", "0". **This is where I finally see who else is in**: Casey Nguyen, Marcus…, and six names I half-know. Nineteen taps in.
- "THE INDIVIDUAL RACE · EVERY PLAYER" — "— Points King · — Most Improved · — Iron Man", then the same eight names, then: "Points King takes 15% of the pot at season's end. Most Improved is index drop since Week 1; Iron Man is most rounds posted. All three run in parallel with **the squad race** — see How scoring works." Squads again.
- Bottom: "Code · THEPTCQ5" · "Add golfers".

**POT pane (tap 20):** "Season stakes" · "The pot" "$400" · "8 × $50 · $150 collected · 5 still owe" · "$240 Cup champs · $100 Runner-up · $60 Points king" · "Cup Season keeps the ledger; the money moves between friends." · "Buy-ins · 3/8 in" · eight names with a ✓ (three lit). I tap my own name (tap 21): a toast — "The Pro marks buy-ins as the money moves between friends." OK: I can't mark myself paid; Casey does. Then "The other stakes · pride, on the books" / "Post a stake" / "No stakes on the books. The cookout isn't going to bet itself." — cute, and clearly not money.

**LEAGUE pane (tap 22):** "Members & invites · 8 players · View" · "Share the season · A public page — the standings so far, no account needed · Link ✕" · "ROSTER OPEN · 8 IN" "Works until you close it, or until first tee — Sat Sep 5." · "Squads · Individual league — no squads · View" · "League notices reach your phone — floors, closes, season news" · "League rules ⌄".
- **Members & invites → View (tap 23):** "Members & invites" · "8 PLAYERS · CODE THEPTCQ5" · each row: face, name, "THE PRO" next to Casey, "@casey · INDEX 14.2"; mine says "@jordanreyes" with a "Marker here" button. This is the roster. Twenty-three taps from the text.
- **League rules (tap 24):** "The bylaws · locked at first tee" · STRUCTURE "Individual — no squads" · **SQUAD FORMATION "Blind draw"** · PRESET "Standard" · HANDICAP ALLOWANCE "95%" · VERIFICATION "Post what you'd post to GHIN" · COUNTING CAP "Best 3 / mo" · **PARTICIPATION FLOOR "2 / mo · −5 sqd pts / round short"** · BUY-IN "$50 / player" · POT SPLIT "60 / 25 / 15 · champ / 2nd / king" · SEASON "3 mo · Sat Sep 5 → Sat Dec 5 · 13 wks" · CUP FINAL "Final 4 weeks · from Sun Nov 8 · scored fresh" · "How scoring & handicaps work →".
  - So the floor *does* have a penalty: "−5 sqd pts / round short." In a league with no squads. Three surfaces, three stories: covenant (a term), scoring sheet ("a habit, not a penalty"), bylaws ("−5 sqd pts"). I still don't know if missing a month costs me anything.
  - "SQUAD FORMATION · Blind draw" in an "Individual — no squads" league.

**BOARD (tap 25):** "THE BOARD" · "TODAY · SEP 4" (or the lock day) · "◆ The Putt Club is live — say hello on the board" · a "Message the league…" box · Send. Empty chat. I could say hi. I don't yet.

### 11 · Saturday: where do I learn what I have to do?

I went looking for a sentence like "Play a round Saturday, then tap ⊕ and post your score." It does not exist. What I found, assembled:

1. Home hero: "First tee in 1 day." (a date, not an instruction)
2. Home: "BUDDY'S PLAYING · Casey · tomorrow" + the Coming up card "Tomorrow · Casey · DOBSON RANCH · 7:10 AM · 3 in" — **if and only if** Casey booked it. Tapping it opens the round sheet where I can RSVP "in." That's the one place Saturday becomes a plan.
3. The ⊕ tab (tap 26): a cover — "Golf" · "Play one live, post one you just finished, or plan the next" · "**Play now — score the group**" "Everyone scores from their own phone — Match Play, Wolf or Skins — and it settles up at the end…" · "**Post a round — after you play**" "Gross + tee, 20 seconds · counts on your card and in every league" · "**Plan a tee time — before**". "Post a round — after you play" is the verb I need. Nothing on Home pointed me at it.
4. The Clubhouse "Next up · kickoff" card says "Practice rounds hit your card, not the season" — which tells me *not* to bother today, and nothing about tomorrow.

So: the *when* is Casey's booking (or Casey's text), the *what* is the ⊕ cover, and the *why-it-matters* is the scoring sheet. Three places, none of them Home. In real life I text Casey.

---

## The five questions — as at the first Home (tap 17, ~4:30)

| # | Question | Answered? | Cost | On-screen evidence |
|---|---|---|---|---|
| 1 | **What is happening?** | **Yes** | 0 extra taps, ~3 s | Hero eyebrow "THE PUTT CLUB · BEFORE FIRST TEE", figure "1d", line "First tee in 1 day. Rounds before it build your number." |
| 2 | **Why does it matter to me?** | **Partly** | ~30 s of re-reading | "$400 on the books … 5 still owe" + "You still owe $50 · Venmo @casey-ng · by Sat Sep 5" says money is real and due tomorrow; the endgame line says there's a Cup. What's missing at Home: the split ($240/$100/$60 — two taps away in "On the line") and any sentence about *my* stake in the outcome beyond a due date. |
| 3 | **What can I do right now?** | **Weakly** | — | Pay Casey (the owe line). Tap "See the table →". RSVP to Casey's round *if* it's booked. Nothing says "post a round" on Home; the ⊕ is a bare glyph until tapped (1 tap to the cover, which is clear). The card told me rounds build my number, so "play and post" is inferable, not stated. |
| 4 | **Who am I competing with?** | **No, not at Home** | 2 taps (hero → table) or 6 (League → Members) | Home shows Marcus and Casey in the feed and "8 × $50" implies eight people; the names are only in the Clubhouse table / Members sheet. The join review and the welcome never listed a roster — the welcome's "Who else plays with you?" heading is a recruiting pitch, not the answer. |
| 5 | **What happens next?** | **Partly** | ~20 s | "First tee in 1 day" + "BUDDY'S PLAYING · Casey · tomorrow" (conditional on Casey booking). Then: post rounds, best 3 count, top 2 into a Cup Final from Nov 8 — all in the hero foot, all in small mono type, all jargon-heavy. What happens *if I don't* post two a month is contradicted across three screens. |

---

## Explain it to a friend in 30 seconds

"It's a golf league app. You post your real scores after you play — any course — and each round is worth 5 to 12 points depending on how you did *against your own handicap*, so a 98 from me scores the same as an 80 from Casey if we both played to our number. Best three rounds a month count, you're supposed to post at least two, and after three months the top two go to a four-week playoff for a $400 pot — $240 to the winner. The $50 goes to Casey on Venmo, not the app; the app just keeps the tab."

(I could say that only *after* the Clubhouse and the scoring sheet. At the first Home I could say the first and last sentences.)

---

## Glossary — every word I didn't know at the moment I met it

| Word | Where I met it | What I guessed | What it turned out to mean (as far as the app told me) |
|---|---|---|---|
| **the Pro** | store listing; covenant "The Pro tracks who's paid" | the golf pro at a course | the person running the league (Casey). Never defined; inferred from "THE PRO · CASEY NGUYEN" |
| **bylaws** | store; League pane "The bylaws · locked at first tee" | legal stuff | the league's rule settings |
| **squads** | store; "SQUADS LOCKED"; "−5 sqd pts"; "SQUAD FORMATION · Blind draw" | teams | teams — which my league doesn't have, yet the word appears four times in my league's room |
| **Cup / Cup Final** | store; covenant "Cup Final · final 4 weeks" | the trophy / a playoff | a four-week playoff for the top 2, "scored fresh" |
| **first tee** | card, hero, everywhere | the first hole | the season's start date |
| **ledger / "on the books"** | store; covenant; welcome | accounting | the app's record of who owes what; no money moves through it |
| **handicap / index / "your number" / "playing number"** | card step 3; welcome; scoring sheet | my handicap (which I don't have) | index = handicap from 3+ posted rounds; playing number = index × the league's allowance (95%). Four names for two things |
| **GHIN** | card step 3 | ? (never heard it) | "Links your USGA record" — still not sure what it is or whether I need one (I don't) |
| **ball marker** | card step 2 | the coin you mark your ball with | my icon |
| **pot sheet** | covenant; welcome | the list of who paid | same — and "the books," "the ledger," "the pot" are all used for it |
| **Preset · Standard** | covenant | default settings | one of Casual / Standard / Cutthroat, which sets the 100/95/90% allowance and the floor penalty — learned only in the scoring sheet + bylaws |
| **participation floor** | covenant | minimum rounds | minimum rounds per month; consequence contradicted across three screens |
| **band** | scoring sheet | ? | one of the five point tiers (Torched it … Posted anyway) |
| **rating & slope / WHS** | scoring sheet | course difficulty numbers | never explained; I'm expected to know |
| **allowance** | scoring sheet | ? | the 95% |
| **Casual / Cutthroat** | scoring sheet | other rule sets | alternatives to Standard my league didn't pick — noise for me |
| **solo league** | scoring sheet ("In a solo league…") | a league of one? | a league with no squads. Nowhere on my Home or covenant did the word "solo" or "individual" appear before this |
| **scored fresh** | hero foot; bylaws | ? | points reset for the Cup Final |
| **seed / "sets the seeds"** | hero foot | tournament seeding | the top-2 ranking entering the Final |
| **"Months won breaks it"** | hero foot | ? | a tiebreak on… months won? Never defined |
| **the board / the table / the climb / the race** | push ask; hero; Clubhouse | ? | board = league chat/feed; table = standings; climb = the standings again, shown as a ladder; race = the standings, again |
| **duel / the clash** | push ask; (later) | head-to-head match | a weekly head-to-head the app pairs — never saw one pre-season |
| **Points King / Iron Man / Most Improved** | Clubhouse | side prizes | Points King = most points, gets 15% of pot; the others are bragging rights |
| **Tour Card** | Members sheet ("Casey's Tour Card") | a PGA card | a player's profile |
| **Live round / Play now / Match Play, Wolf, Skins** | Clubhouse "Live round" button; ⊕ cover | scoring games | live scoring modes; irrelevant to my Saturday question |
| **Roster open** | League pane | ? | the join link still works until Sat Sep 5 |
| **"a stake" / "pride, on the books"** | Pot pane | money bets | non-money side bets (cookout) |

---

## The ten most confusing moments

1. **The door · "Rally your crew. Post real rounds. Take the cup." + an email field** · *What I thought:* did the link do anything? Am I in the right app? · *What I needed:* one line — "You're invited to The Putt Club. Sign in to review it." — and the same line on the card. (And if I open from the App Store instead of re-tapping the link, the code is never captured; I'd have to type it.)

2. **Card step 3 · "Know your number? … Your index builds itself at 3 posted rounds"** · *Thought:* do I need three rounds before Saturday counts? · *Needed:* "You don't need one — your first rounds still score. Skip this."

3. **Covenant · "PRESET · Standard" / "$50 / player · on the pot sheet"** · *Thought:* standard what? What's a pot sheet? · *Needed:* "Standard rules — 95% handicap, best 3 a month" and "pot" instead of "pot sheet"; or a tap-to-expand on each row.

4. **Covenant · "PARTICIPATION FLOOR · 2 rounds / mo"** vs **scoring sheet · "In a solo league the monthly minimum is a habit, not a penalty"** vs **bylaws · "2 / mo · −5 sqd pts / round short"** · *Thought:* am I on the hook for two rounds a month or not? · *Needed:* one sentence, said once: "Post at least 2 a month. In this league there's no penalty if you miss."

5. **Welcome · "Who else plays with you? Growing the league isn't the Pro's chore — any member's link works." + [Share the invite link]** · *Thought:* this is the roster. It isn't — it's asking me to recruit, thirty seconds after joining, before I've seen a single name. · *Needed:* the eight names (or "8 in: Casey, Marcus, …") right here.

6. **Welcome · no Done/Close button; two doors and a drag bar** · *Thought:* how do I get out? · *Needed:* a "Take me to the league" button — the sheet is the last gate before Home and it has no forward door.

7. **Home hero foot · "The top 2 golfers seed into a four-week Cup Final from Sun Nov 8 — scored fresh, so the regular season sets the seeds, not the winner. Level on points? Months won breaks it."** · *Thought:* (read it three times) · *Needed:* "Top 2 after Nov 7 play a 4-week final for the cup." — and "months won" defined somewhere.

8. **Clubhouse · "KICKS OFF IN 1 DAY · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON"** + **"SQUAD FORMATION · Blind draw"** + **"−5 sqd pts"** + **"the squad race"** in a league whose own bylaws say "Individual — no squads" · *Thought:* are there teams or not? · *Needed:* the solo league to never say "squad."

9. **Season strip · "YOUR INDEX 0 of 3 · Building your number" next to "COUNTING ROUNDS 0 / 3 · your best 3 count"** · *Thought:* which three? · *Needed:* different shapes for different threes ("3 rounds to a handicap" vs "0 of best-3 this month"), or one of them elsewhere.

10. **Home, Saturday · "First tee in 1 day." and nothing else** · *Thought:* what do I actually *do* tomorrow? · *Needed:* a one-line instruction on the pre-season Home: "Play Saturday, then post the score from ⊕ — any course, front and back nine." The only Saturday plan on Home exists if Casey booked a tee time; the only "post" verb is behind the ⊕ glyph.

Honourable mentions: "AROUND YOUR BUDDIES" when I have zero buddies (they're league-mates); "Tell us how it's going" / "Founder" tags I can't parse; eight-digit code (worked, but I blinked); "Live round" button on the pre-season standings — irrelevant and prominent.

---

## Verdict

**Goal: "What am I joining, who else is in, what does $50 buy, what do I have to do each week, and how do I win?"**

- *What am I joining* — yes, by the covenant and the hero: a 13-week league starting tomorrow with a $400 pot and a Cup Final. The *shape* (solo, Standard) is never said in words I know until the bylaws.
- *Who else is in* — **not** at the join review, **not** at the welcome, **not** at Home. Two taps (hero → table) or six (Members sheet). The one screen headed "Who else plays with you?" is the wrong answer.
- *What $50 buys* — the covenant and Home say "$400 on the books"; the split is two taps away. Adequate.
- *What I do each week* — nothing says "post rounds" on Home; "Best 3 a month count" and "2 rounds / mo" are monthly, and the floor's consequence is stated three different ways. Weak.
- *How I win* — the endgame sentence is on Home, verbatim, and dense; the point bands are one tap from the welcome and genuinely excellent. Adequate-to-good if you read; poor if you skim.

**Score: 6 / 10.** The join review is the right idea executed well ("Join — I'm in for $50" is the best button in the flow), the owe line on Home is exactly what a joiner needs, and the point-band table is the clearest explanation of a handicap league I've read. Against that: the door and the card ignore the invite for four screens; the roster is hidden at the exact moment "who's in" matters most; the floor rule contradicts itself; a solo league keeps saying "squad"; and nothing on Home tells me what to do on Saturday. **Goal reached: no — not at the first Home. Reached after ~8 more taps of exploring plus a text to Casey.**

**Where I stalled.** Never hard-stuck. Two near-stalls: (1) the door — nothing acknowledged the link, so I went back and re-tapped it on a guess; had I not, the whole invite path would have been lost and I'd have been typing `THEPTCQ5` into a "Join a league" field later; (2) the welcome sheet — no forward button, swiped down on a guess. The one question the app never answers ("what do I do Saturday?") I answered by texting Casey, which is what I'd do in real life.

## The "oh, that's actually cool" moment

Two, and they're related. The covenant button — **"Join — I'm in for $50"** — puts the number *in the verb*; I never had to wonder what I was agreeing to. And then Home, thirty seconds later: **"You still owe $50 · Venmo @casey-ng · by Sat Sep 5"** — the app knows how Casey wants to be paid and when, and says it in one line under my standing. Money between friends, tracked, not touched. That is the store listing's promise made real, and it's the first thing I'd tell someone about the app. (Runner-up: the eight-digit code lifting itself out of the Mail notification and verifying with no tap.)

---

## Notes for whoever fixes this (tester's aside, not persona voice)

- `DoorView` and `CardGateView` never read `JoinIntent.pending()`; `CardGateView` does read `ClaimIntent.pending()` for the claim thread. The join thread deserves the same one-liner on both screens.
- `JoinIntent.store` runs only in `onOpenURL`. A first-launch from the App Store's "Open" button (no re-tap) yields a league-less Home + orientation, and the code must be typed. If deferred deep-linking isn't feasible, the door's "I have a league code" affordance (present on the web door screenshot, absent on the phone's `DoorView`) would at least name the path.
- `CovenantSheet` has no roster line; `LeagueWelcomeSheet` has no roster and no close button; `Covenant.floorLine` and `Bylaws.penalty` both render for `structure == "solo"`, contradicting `GuideCopy.scoring(solo: true)`.
- `LeagueCopy.kickoff` ("SQUADS LOCKED"), `LeagueCopy.bylawsRows` ("Squad formation"), `Bylaws.penalty[1]` ("−5 sqd pts"), and `IndividualRaceView`'s fine print ("the squad race") all render in a solo room.
- Home's pre-season hero has no verb. `LeagueCopy.seasonNote` already owns the "Practice — the season starts …" sentence; a pre-season Home could carry "Play Saturday, then post it from ⊕" in the same slot the in-season lead card uses.
