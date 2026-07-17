# Cup Season — Fresh-Tester Walkthrough (hand this to the golfer)

**Gate: the deploy runbook must be GREEN first** (`spec/deploy-runbook-v23.163.md`
— cupseason.app `#obCaption` must read v23.163). A timed run against a stale
prod measures nothing.

## Setup (the operator does this, once, before the golfer arrives)
- **Installed PWA:** open cupseason.app on the phone → Add to Home Screen → run
  the whole thing from the icon, full-screen (not the browser tab).
- **Fresh identity:** a plus-alias nobody's used — `you+t1@gmail.com`. Each run
  gets a new alias so it's a true first-timer.
- **Two roles:** one person **reads the stopwatch and writes**; the golfer
  **drives untouched**. No coaching. If they hesitate, that hesitation is the
  finding — write down *where*, don't rescue them.
- Have ready to hand the golfer: a **league join code**, a **real invite link**,
  and the name of a **real course** (e.g. one that returns tees like `papago`).

## The five timed gates — read the task aloud, start the clock, stay silent

**Gate 1 — Make your profile.  Target < 2:00.**
> "Get yourself into the app."
Clock starts at the sign-in screen. Watch: did the **code email land fast**
(note the seconds — Brevo/Gmail lag is the risk)? Did they get the **@handle**?
Did the **index field stall them** (it's optional — did they know)?
Stop when they're standing in the clubhouse. **Time ___**

**Gate 2 — Join a league.  Target < 0:30 (then repeat by link).**
> "Join your league. Here's the code." … then … "Now join this other one — here's a link."
Watch: was **Start or join a league** findable without hunting? Did the **invite
link auto-join**, or dead-end? **Code time ___  Link time ___**

**Gate 3 — Post a round.  Target < 1:00.**  *(this is the reshaped gate)*
> "You just played. Post your round."
Default path is **hole-by-hole**: pick Course (type the real course → pick →
pick tee, rating/slope autofill) + date → the **grid opens on par** → tap the
holes they didn't par until **"Gross NN"** reads right → Post. **Time ___**
- ⚠ **The F2 watch:** does the tester NOTICE the grid defaults to par? If they
  hit Post without adjusting, they log an accidental even-par. The live
  "Gross NN" line is the only safeguard — **confirm with your eyes that they
  read it.** If they miss it, that's the highest-value finding of the day.
- Then: *"Do it again the fast way."* → **Just the total** → front/back gross →
  post. **Time ___** (the speed floor — should beat the grid).
- Then: *"Now a course that isn't in the system."* → type a name with no match →
  type rating/slope by hand → post. **Still under a minute? ___**

**Gate 4 — Read the standings.  Target < 0:10.**
> "Who's winning — and what do they have to do to take the cup?"
Correct answer in ___ seconds. The storytelling line ("leads by 25 · 25 back")
should answer it *before* they read the table.
- **Test BOTH endgames** (008 dial): a **Cup-Final** league ("Cup line · top 2
  advance," +10 head-start) AND a **points-table** league (leader crowned
  outright — is that obvious, or do they expect a playoff?).
- Tap a points figure → the rounds behind it open. A round card reads
  "84 · beat your number by 0.6 → 7 pts" — flag any "PvI"/"differential" leak.

**Gate 5 — Zero tutorial (runs across all of the above).**
Did they ever ask **"what do I do here?"** — where? Every spot is a fix.
Probe the **new v23.163 surfaces** (none existed at the last audit):
- **Tee off → pick a game** (Match / Wolf / Skins): does the strokes preview
  ("Danny gets 3: holes 2, 7, 14") + the settlement recap explain themselves?
- **The Ryder** scoreboard: are "First to 9½," the duel chips, and
  "Duel taunts: OFF" self-evident?
- **Wizard**: endgame + pot-split choices, the roster-fit dimming, the
  fine-print disclosure.
- **Handicap "establishing"**: a new golfer sees "2 of 3 · Building your number"
  — reassuring or confusing?

## Record each run
Per gate: **time**, **pass/miss vs target**, and the **exact screen** where any
hesitation happened. A miss is a friction fix to log, not an argument. File
findings under `spec/prelaunch-qa-2026-07-13.md` → Findings log.

---

# Operator's prod-plumbing checks (not timed — run alongside)

These confirm the machinery the golfer can't see. Do them on real prod.

**OTP email** — first-time AND repeat sign-in. Code arrives ≤ ~30s, **code-only
(no link)**, works on first entry. (Gmail's scanner eats magic links — code-only
is the fix; if a link appears, the email template regressed.)

**Add to home screen** — install prompt fires; app opens full-screen with the
**current** icon (flag + four-color orbit ring), not the old mark.

**Course search live** — in the real PWA post flow, type **`papago`** → tees
return. This exercises the `courses` Edge Function + its server-side key in
prod. No tees = the Edge Function secret isn't set, or the fn didn't deploy.
Confirm a second, cold course too (results cache into `api_courses` after first
hit — a repeat should be instant).

**Realtime** — two devices, same league. Device A posts a round (or a chat
message); it must **land on Device B without a refresh**. If it doesn't:
realtime rides the dedicated `rtClient`, not `sb` — check the subscribe-status
breadcrumb in Device B's console (`?debug`) for `SUBSCRIBED` vs `CHANNEL_ERROR`,
and confirm `posts` is still in the `supabase_realtime` publication.

**Push** — with the PWA installed and notifications granted: from another device
post something that should notify (a round to a league you're in) → the
subscribed device buzzes. Then the **duel-taunt path**: run a Ryder duel round
where taunts are opted in → the rival's device gets the taunt (this is the new
`push_nudges` webhook — if the round-post push works but the taunt doesn't, the
webhook from runbook step ③ is missing or its `x-push-secret` is wrong; check
push Function Logs for `[push] kind=nudge` and any 401).

**Light mode + one-handed** — re-run Gate 3 in light mode, thumb-only. Contrast
and reach are the watch.
</content>
