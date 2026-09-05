# Persona F — Priya, buddies but no league · blind walk

**Who I am.** Priya, 35, Gilbert AZ, 6.4 index. I've had Cup Season for a month. Five buddies added (Marco, Dev, Tash, Ravi, Jules). Nine rounds posted. No league. No event. Two buddies posted this week — Marco an 84 at Western Skies on Tuesday, Dev an 81 at Kokopelli today (his best yet). Tash has a round on the books for Sunday, Sep 6, 7:10a at Whirlwind — Devil's Claw, with Ravi already "in". I was not tagged on it. I last opened the app Monday.

**When.** Thursday night. (The brief dates "today" as Friday Sep 4; the persona opens on Thursday night, so I've read the header as it would print on Sep 3. Nothing below changes if it's Friday except the day names.)

**Goal.** "Is something happening in my golf world, and is there a reason to make Sunday count?"

**Method note.** I experienced the product through the screenshots in the three named folders and by following the view code from `RootView.swift` → `MainTabView.swift` → each tab's screen → the branch a person in my state would land in → the copy constants in `CupSeasonKit`. Comments are not UI; I quote only what renders. Where a screen depends on server data I assumed the data I'd have. A system reminder surfaced the repo's `CLAUDE.md` unasked; I did not use it.

---

## The walk

### Screen 0 — launch (0 taps, ~2 s)

Tap the icon. A spinner with a small caps line: **"RESTORING YOUR SESSION"**. Then the tabs. No orientation screen — I saw that a month ago, and it never comes back for someone with rounds on the card.

Four tabs along the bottom: **Home · Clubhouse · ⊕ Post · You**. Home is selected.

### Screen 1 — Home, above the fold (0 taps, ~5 s of reading)

Top left, a serif wordmark **"Cup Season"**; to its right a small mono eyebrow **"THU · SEP 3"** and an orange **+**.

First card (orange spine on the left):

> **AROUND YOUR BUDDIES**
> **Dev — 🔥 Personal best**
> **See the round →**

Oh — Dev shot his best. That's news. I don't tap yet; I scroll to see what else is here.

Second card, the big one (the "hero"):

> **YOUR CARD**
> **6.4**
> Established. Nobody's seen it yet — you haven't joined a league.

I stop here. *Nobody's seen it?* Five people I play with see my rounds every week in this app — that's the whole reason I have it. I read "seen" as "counted by something," but the sentence says seen. The line reads like a nudge to join a league, dressed up as a fact about me. Mildly annoyed. (Later I confirm from the code this is the only sentence a league-less golfer with 3+ rounds ever gets on the hero; there is no version of this card that mentions buddies.)

Under it, one chip in a horizontal strip:

> **BUDDY'S PLAYING** **Tash · sun** ›

Good — that's Sunday. That's what I came for.

Then a section head: **AROUND YOUR BUDDIES** ………………… **YOUR BUDDIES ↗**

First row under it, small caps then a sentence with the first two words bold:

> **SINCE YOU WERE HERE**
> **2 rounds** and a personal best from Dev.

Then **TODAY**, a card with a gold spine:

> [Dev's marker] **Dev**  🔥 Personal best ……… **81** gross
> Kokopelli GC · Thu, Sep 3

I look for the 🔥 chip to fire back at him — every other social app has one under a card like this. There isn't one. No chip, no long-press tray does anything I can see (I later confirm: reactions only exist for rounds that share a league with me; a buddies-only circle gets no reaction strip at all). So I can see Dev's best round and cannot say "nice" on it. That's the first place I'd actually leave the app to text him.

Also: Dev's personal best is now on this screen three separate times (lead card · digest sentence · Today card). Nice that the app noticed; odd that it says it three ways in a row.

### Screen 1, continued — Home, scrolled (0 taps)

**THIS WEEK**
> **Marco** · played to their number ……… **84** gross · Western Skies GC · Tue, Sep 1
> **You** · beat your number by 1.6 ……… **82** gross · Kokopelli GC · Sat, Aug 29

Then **Show earlier · 14** in blue (tap-to-expand; I don't).

Then a section head **COMING UP** ………………… **THE CALENDAR ↗**, and one card:

> [Tash's marker] **SUN SEP 6** · BUDDY
> Tash · WHIRLWIND — DEVIL'S CLAW · **7:10a**
> right side: **2 in** (green pill) · 💬 1 · ☀️ 93° · 5mph

That's genuinely good. I know when, where, what tee time, that two people are already in, that someone said something, and the weather. This is the one thing on Home that answers "is there something to do Sunday."

End of Home. Nothing on Home ranks me against anybody, and nothing says what a good Sunday would *do* for me.

**Screens so far: 1. Taps: 0.**

### Screen 2 — Dev's round (tap 1: the lead card's "See the round →")

A sheet: **Dev · 81 gross** (title) / **KOKOPELLI GC · THU, SEP 3** (sub). Rows:

> The course ……… 70.1 / 125
> Their number that day ……… 9.8
> 81 − 70.1 × 113 ⁄ 125 ……… 9.9 VS COURSE
> Against their number ……… **level — PLAYED TO IT**
> Played with **Jules**

It's a receipt. Honest, a little cold. "PLAYED TO IT" for a personal best reads odd until I work out it's "he played to his handicap" — right, a 9.8 shooting 81 is dead on. No button to react, no button to comment. Swipe down.

### Screen 3 — Dev's Tour Card (tap 2: his face on the Today card)

**Tour Card** / **@DEV**. A dark credential: his photo, **Dev Patel**, "@dev · Chandler, AZ · est. Aug 2026", **9.8** in gold, **HANDICAP INDEX**, a chip "⛳ First round · '26", then **FORM** with five grey dots and the key **"Last five, oldest first — a lit dot beat their playing number."** — all five unlit, on a guy who just shot his best round. I don't know what "playing number" is or why none are lit. (Code: form dots only light from rounds a *league* scored; a league-less golfer's dots are always slate.)

A green tag **Buddies**. Then:

> **CAREER**
> Rounds ……… 7
> Best round vs course ……… 6.1
> Avg vs their number ……… +0.4
> Home course ……… Kokopelli GC
> *Lower is better against the course; against their number, + is better.*

Two scales going in opposite directions, and a footnote apologising for it. Nothing here is *me vs Dev*. I do the comparison in my head (I'm 6.4, he's 9.8, fine). No "vs you" line, no record, no "you've played together 3 times". (The code has a "VS YOU · 3–2 · YOU LEAD" chip, but only from league clash weeks; for buddies without a league it never appears.)

**RECENT ROUNDS**: "SEP 3 · 81 GROSS · KOKOPELLI GC · VS COURSE 9.9" and so on.

Bottom: **🔇 Mute — hide their posts from your boards**. Boards? I don't have a board. Swipe down.

### Screen 4 — Tash's Sunday round (tap 3: the "BUDDY'S PLAYING · Tash · sun ›" chip)

A sheet. **Tash's round** / **7:10a tee**. Course: **Whirlwind — Devil's Claw**, "BLUE · 71.6 / 130 · PAR 72", "Chandler, AZ". Chips: **7:10a tee** and a gold-tinted **☀️ 93° · 5mph**.

> **WHO'S IN** · **2 in**
> Tash  HOST ……… IN
> Ravi ……… IN

And then — no buttons. I expected **I'm in / Maybe / Can't**. They aren't there. (Code: RSVP is only shown to the host or someone tagged on the round.) I wasn't tagged, so the app shows me a foursome with two open seats and gives me no way to ask for one.

Below: **ON THE BOARD** — "Ravi: bringing the good balls" — and a field **"Say something to the group…"** with **Send**. That works. I type "room for a 3rd? 🙋‍♀️" and send. It appears under Ravi's line. That's the closest thing to "make Sunday count" that Home offered me, and it's a text message I could have sent in iMessage.

**Taps: 4 (chip, field, type, Send). Screens: 4.**

### Screen 5 — Your golf calendar (tap 5: "THE CALENDAR ↗" on Coming up)

Pushed screen, back chevron, title **Your golf calendar**. Eyebrow: **"YOUR GOLF CALENDAR · YOURS, YOUR BUDDIES', YOUR LEAGUES'"**.

I expect Tash's round here. There is no **IN YOUR CREW'S PLANS** section at all. The grid for **SEP 2026**: today outlined, and **Sunday the 6th has no dot**. The legend reads **● ON THE TEE SHEET · ● LEAGUE MATE · ● SEASON DATE** — no "buddy" colour. I go back to Home to check I'm not crazy: the Coming up card is still there, Sunday, Tash, Whirlwind. Return to the calendar: nothing on the 6th.

(Code: the calendar only draws rounds that are mine, in a shared league, or that I'm tagged on. A buddy's plan that Home shows as a full card is invisible on the screen titled "your buddies'".) This is the most disorienting moment of the walk — two adjacent screens disagree about whether Sunday exists.

Under the grid: "Tap any day to put a round on the tee sheet." and a big orange **Put a round on the tee sheet**. Then **ON THE TEE SHEET** — "Nothing on the tee sheet for Sep. Put one up: league mates and buddies see it the moment you do."

### Screen 6 — Put a round on the tee sheet (tap 6)

A sheet: **Put a round on the tee sheet** / **BUDDIES & LEAGUE MATES SEE IT THE MOMENT YOU POST**.

**Day** picker — defaults to **Sat Sep 5**. I want Sunday. I change it (tap 7, tap 8). **Tee time · optional** → "Set a tee time". **Course**: I type "Whirl" and pick **Whirlwind — Devil's Claw** then the **Blue** tee (taps 9–11); toast "Tees set — rating and slope filled". **Note · optional** placeholder "buddies trip, looking for a 4th". Then:

> **TAG YOUR GROUP · 0 TAGGED**
> [chips] Marco · Dev · Tash · Ravi · Jules

I tap **Tash** and **Ravi** (taps 12, 13). Button **On the tee sheet** (tap 14). Toast: **"On the tee sheet: your group is named on the boards"**. Fine print under the button: *"Posts to your leagues' boards: tagged golfers are named. Scratch it any time from the calendar."*

Which boards? I don't have a league. I'll assume Tash gets something; the app doesn't tell me what she sees.

So now there are two Sunday rounds at Whirlwind — Tash's, with Tash and Ravi in, and mine, with Tash and Ravi tagged. I'm not sure whether I just joined her round or started a competing one. Nothing on screen says.

Back on Home the chip strip now reads **NEXT ROUND** **Whirlwind — Devil's Claw · in 3 days** › next to **BUDDY'S PLAYING · Tash · sun**. Two chips for what I think is one round.

**Taps: 14. Screens: 6.**

### Screen 7 — Clubhouse tab (tap 15)

Title **Clubhouse**. Three grey doors in a row:

> **Join a league** · **Start a league** · **Start an event**

Under them, a footnote: **"Post a round — it counts on your card. Leagues score it when you join one."** Then one more wide button: **Add golfers**.

That's the whole tab. An empty room with a sign that says build one. I have five buddies and nine rounds and this tab has nothing for me. So yes — the app does tell me to start a league; it just does it politely and in a room I have no reason to enter twice.

### Screen 8 — You tab (tap 16)

**You** with a ⚙ at the right. A big card: my photo, **Priya Raman**, "@priya · Gilbert, AZ · Kokopelli GC", "est. Aug 2026 · **add your GHIN**", a small marker line "The Saguaro", then **6.4** in gold, **HANDICAP INDEX**, one chip "⛳ First round · '26", then **FORM ○ ○ ○ ○ ○** and **"Your last five rounds, oldest first — a lit dot beat your playing number."** Five grey dots. I *know* I beat my number two Saturdays ago; Home said so ("beat your number by 1.6"). So why is nothing lit? Same reason as Dev's card — and I can't know that.

A row: **Your buddies** / "Find golfers, see who you play with" →.

**YOUR GOLF** (a group head), then **DISPLAY CASE**: "The case is empty — for now. Cups, crowns and event wins hang here when you take them." Then **ALL TIME**:

> Rounds posted ……… **9**
> Best vs your playing number ……… **—** / NO COUNTING ROUNDS YET
> Avg vs your playing number ……… **—** / NO COUNTING ROUNDS YET
> Leagues & events ……… **0** / PLAYED IN

Nine rounds posted and two dashes that say I have no counting rounds. "Counting" toward what? This looks broken. (Code: "counting" means scored by a league; no league, no figure, even though the index is right there.)

**RECENT ROUNDS**: "AUG 29 · 82 gross · Kokopelli GC →", "AUG 22 · 85 gross · Western Skies GC →" … five rows, each with a small ✕. No "vs your number" line under any of them (again: no league, no figure).

No "Your seasons" section. Nothing here compares me to anyone.

### Screen 9 — ⊕ Post (tap 17)

A cover slides up: **Golf** / *Play one live, post one you just finished, or plan the next*.

> ● LIVE **Play now — score the group** — Everyone scores from their own phone — Match Play, Wolf or Skins — and it settles up at the end. Friends without the app just play; their card is waiting when they want it. →
> **Post a round — after you play** — Gross + tee, 20 seconds · counts on your card and in every league →
> **Plan a tee time — before** — Put a round on the tee sheet · your buddies and leagues see it the moment you post →

*This* is the reason to make Sunday count — a skins game with Tash and Ravi that scores itself. It is one tap from anywhere, and it is not mentioned anywhere near Sunday: not on the Coming up card, not on Tash's round sheet, not on the calendar. On Thursday night this door has nothing to do for me except be remembered. I tap it once to look: **Play now** / SET UP THE ROUND / a course field, tee & rating fields, **18 holes / 9 holes**, **THE FOURSOME · 1 / 4** with "You · 6.4 IDX" and three "Open slot · TAP A PLAYER BELOW". Close.

### Screen 10 — the + on Home (tap 18)

A menu: **Start a league · Start an event · Join with a code · Your golf calendar · Find golfers**. "Join with a code" — what code? Nobody sent me one. I tap **Start an event** (tap 19):

> **Start an event** / SHORT FORM · ITS OWN LITTLE TROPHY
> ⚔️ **The Ryder** — Two teams · weekly vs-index duels · first to the clinch — LIVE
> 🥊 **Bracket** — Knockout · seeded · last golfer standing — SOON
> *Every event mints a trophy for your display case.*

"Weekly" and "clinch" don't sound like one Sunday with three friends. I close it.

### Where I stop

I'm not stuck — I found Sunday, I found Dev's best round, I put my own round up. But the goal question is only half answered and I've run out of places to look. In real life at this point I put the phone down and text the group chat: "Whirlwind Sunday 7:10 — Dev's on a heater, skins?" — which is the sentence I wanted the app to write for me.

**Total: 19 taps, 10 screens, roughly 6–7 minutes.**

---

## The five questions, as at the first Home

| # | Question | Answered? | Time / taps | Evidence |
|---|---|---|---|---|
| 1 | What is happening? | **Yes** | ~5 s, 0 taps | "SINCE YOU WERE HERE · **2 rounds** and a personal best from Dev." · Today: "Dev · 🔥 Personal best · 81 gross · Kokopelli GC" · chip "BUDDY'S PLAYING · Tash · sun" · Coming up: "SUN SEP 6 · BUDDY · Tash · WHIRLWIND — DEVIL'S CLAW · 7:10a · 2 in" |
| 2 | Why does it matter to me? | **No** | — | The only sentence about me is the hero: "6.4 · Established. Nobody's seen it yet — you haven't joined a league." Nothing links Dev's round or Tash's Sunday to my golf. |
| 3 | What can I do right now? | **Partly** | ~15 s, 0 taps to find, 1 to act | Doors visible: "See the round →", the chip "›", "YOUR BUDDIES ↗", "THE CALENDAR ↗", the "+" and the ⊕. Not visible: any way to react to Dev, any way to say "I'm in" on Tash's round. |
| 4 | Who am I competing with? | **No** | — | Nobody. No standing, no buddy ranking, no head-to-head. The hero explicitly says I'm not in a league; the Clubhouse offers to fix that. |
| 5 | What happens next? | **Partly** | ~5 s, 0 taps | "BUDDY'S PLAYING · Tash · sun" and the Coming up card say what happens for *Tash*. Nothing says what's next for me, or what Sunday would do for my card. |

## Explain it to a friend (30 s)

"It's a golf app where you post your rounds and it keeps your handicap; you add your friends and Home shows you their rounds and who's playing when, with the weather. If you join a league it turns into a season with standings and a weekly match — but if you don't, it mostly just watches. I could see Dev's best round but couldn't even fire-emoji it, and I could see Tash's Sunday tee time but couldn't say I'm in."

## Glossary — words I didn't know when I met them

- **Your card** (Home hero eyebrow) — my handicap card? My profile? Both, it turns out.
- **Established** — that my index is real now (3+ rounds). Not explained on screen.
- **Nobody's seen it** — unclear who "nobody" is when five buddies see my rounds.
- **Personal best** — fine, but *best what*: lowest gross, or best against his number? (It's the lowest differential; the screen never says.)
- **played to their number / beat your number by 1.6** — "number" = handicap; took a beat.
- **playing number** (Tour Card, You) — different from "number"? Never defined. (It's the handicap after a league's allowance; no league, no such thing.)
- **VS COURSE** (receipt row "81 − 70.1 × 113 ⁄ 125 · 9.9 VS COURSE") — the differential, unnamed.
- **counting rounds / NO COUNTING ROUNDS YET** — counting toward what? Nothing on the You tab says.
- **tee sheet** — used for both "a plan for a future round" and "the live scoring screen". Two meanings, one word.
- **on the books / the boards / your leagues' boards** — I have neither books nor boards.
- **LEAGUE MATE** (calendar legend) — the calendar has a colour for league mates and none for buddies.
- **Clubhouse** — I expected the place my friends hang out. It's the league room.
- **The Ryder · weekly vs-index duels · first to the clinch** — every word.
- **Join with a code** — what code, from whom.
- **Tour Card** — a profile. Nice name, no hint.
- **Display case / mints a trophy** — fine once seen, but empty on day 30.
- **HOST** (round sheet) — the person who put the round up.
- **Scratch it** (fine print) — cancel a planned round; sounds like a scorecard term.
- **GHIN** — I know this one; a 6.4 who doesn't would not.

## Ten most confusing moments

1. **Home hero** · "Established. Nobody's seen it yet — you haven't joined a league." · *I thought:* the app doesn't know I have buddies. · *I needed:* "6.4 · 9 rounds · your buddies see every one" — or say what a league adds.
2. **Home, Dev's Today card** · no 🔥 chip under "🔥 Personal best · 81 gross" · *I thought:* reactions are broken. · *I needed:* one chip to fire, or a line saying reactions live in leagues.
3. **Tash's round sheet** · "WHO'S IN · 2 in" then straight to "ON THE BOARD" — no I'm in / Maybe / Can't · *I thought:* I'm supposed to be able to join this. · *I needed:* "Ask to join" or "I'm in" for a buddy, since I can see two open seats.
4. **Your golf calendar** · eyebrow "YOURS, YOUR BUDDIES', YOUR LEAGUES'" · Sunday the 6th has no dot; no "In your crew's plans" section · *I thought:* Tash scratched it, or I mis-read Home. · *I needed:* the same Sunday round Home just showed me.
5. **Put a round on the tee sheet** · toast "On the tee sheet: your group is named on the boards" · fine print "Posts to your leagues' boards" · *I thought:* did anything happen? Did Tash get it? · *I needed:* "Tash and Ravi will see this on their Home."
6. **Home after declaring** · two chips, "NEXT ROUND · Whirlwind — Devil's Claw · in 3 days" and "BUDDY'S PLAYING · Tash · sun" · *I thought:* I made a duplicate. · *I needed:* one Sunday, one card, both of us on it.
7. **You › All time** · "Rounds posted 9" above "Best vs your playing number — / NO COUNTING ROUNDS YET" · *I thought:* broken. · *I needed:* my best and average against my own index, which the app plainly has.
8. **You hero and Dev's Tour Card** · FORM ○○○○○ under "a lit dot beat your playing number" · *I thought:* neither of us has ever beaten our number, which Home just contradicted. · *I needed:* dots lit from the same "beat your number by 1.6" Home already computes.
9. **Dev's Tour Card** · "Best round vs course 6.1 · Avg vs their number +0.4 · Lower is better against the course; against their number, + is better." · *I thought:* two rulers, no *me*. · *I needed:* "Dev vs you · 3 rounds together · you're 3.4 lower."
10. **Clubhouse tab** · "Join a league · Start a league · Start an event · Post a round — it counts on your card. Leagues score it when you join one. · Add golfers" · *I thought:* this tab isn't for me. · *I needed:* something for a five-buddy circle — a buddies table, a skins Sunday, anything.

(Runner-up: **Start an event › The Ryder · "Two teams · weekly vs-index duels · first to the clinch"** — the only "event" on offer sounds like a month, not a Sunday.)

## Verdict on the goal

**"Is something happening in my golf world?"** — Yes, and Home tells me well: the since-you-were-here line, Dev's best, Tash's Sunday with weather and headcount. This is the strongest thing in the app for me.

**"Is there a reason to make Sunday count?"** — Not one the app makes. It shows me Sunday and then steps back: I can't RSVP to a buddy's round, can't react to a buddy's round, can't see myself against a buddy anywhere, and the one genuinely exciting door (live Match Play / Wolf / Skins that scores itself) is never connected to the Sunday it could animate. The comparison surfaces (You › All time, FORM, Tour Card) go blank without a league and look broken rather than empty. The Clubhouse tab and the Home hero both, in effect, tell me to start a league.

**Does it show my friends' golf?** Yes. **Compare me to them?** No. **Offer to turn Sunday into something?** Half — a plan, a comment box, no seat, no game. **Tell me to start a league?** Yes, in the hero's one sentence and the whole of the Clubhouse tab.

**Score: 5 / 10.** The watching half is good; the doing half is missing for anyone who hasn't signed a league.

## The "oh, that's actually cool" moment

The **Coming up** card on Home — "SUN SEP 6 · BUDDY · Tash · WHIRLWIND — DEVIL'S CLAW · 7:10a · 2 in · 💬 1 · ☀️ 93° · 5mph" — paired with the **"BUDDY'S PLAYING · Tash · sun"** chip above it. It knew about a round I wasn't invited to, told me the tee time, who's in, that someone's talking, and the weather, in one glance. That is the group chat, compressed. The pity is what happens when I tap it.

## What I'd text my friend

"ok the app knew you were playing Whirlwind Sunday before you told me 😂 but it won't let me say I'm in. put me on it? and Dev shot 81 today, I couldn't even 🔥 it"
