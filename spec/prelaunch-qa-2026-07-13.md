# Cup Season — Pre-launch QA (success-metrics walkthrough)

Task #14. Run this **on the installed PWA** (add to home screen first), with a
**stopwatch**, using **fresh plus-alias emails** (`you+t1@gmail.com`,
`you+t2@…`) so each run is a true first-timer. One tester reads the clock; the
golfer never gets coached — if they hesitate, that hesitation IS the finding.

Structural audit (v23.78, 2026-07-13) passed all five flows on code-read + demo
drive. This is the timed confirmation the audit can't fake.

---

## The five gates

Mark each run. A miss is a friction fix, not a fail to argue with.

### 1. Profile created — target < 2:00
- [ ] Land on sign-in → enter email → **code arrives** (note seconds; Brevo/Gmail lag is the risk)
- [ ] Enter code → golfer card
- [ ] Fill name, accept the suggested @handle, pick a marker → **Save my card**
- [ ] Landed in the clubhouse. **Time: ____** (target < 2:00)
- Watch for: did the code land fast? Did they understand the handle? Did the index field stall them (it's optional — did they know that)?

### 2. League joined — target < 0:30
- [ ] From clubhouse, find **Start or join a league** → enter the code
- [ ] Landed in the league. **Time: ____** (target < 0:30)
- [ ] Repeat via **invite link** (paste a real invite URL) → auto-join. **Time: ____**
- Watch for: was "join" findable without hunting? Did the link auto-join or dead-end?

### 3. Round posted — target < 1:00
- [ ] Post tab → **18-hole gross** + **Course** (type a real course → pick course → pick tee; rating/slope autofill) + date → **Post round**
- [ ] Round shows on the board + standings moved. **Time: ____** (target < 1:00)
- [ ] Also post the way with **no course match** (type a course not in the DB) → type rating/slope by hand → post. Still under a minute?
- Watch for: course search speed, tee list clarity, whether the autofill was trusted.

### 4. Standings understood — target < 0:10
- [ ] Open the league standings cold. Ask: **"Who's winning, and what do they need to do to take the cup?"**
- [ ] Answered correctly in **____ seconds** (target < 0:10)
- Watch for: did "Cup line · top 2 advance" / the +10 head-start read without explanation? Was "on the line" in the pot clear?

### 5. Zero tutorial
- [ ] Did the tester ask "what do I do here?" at any screen? **Where: ____________**
- Every such spot is the highest-value fix.

---

## Also verify (not timed, but launch-blocking)
- [ ] **OTP email**: arrives within ~30s, code-only (no link), works on first entry. Test a fresh address AND a repeat sign-in.
- [ ] **Add to home screen**: install prompt works; the app opens full-screen with the current icon.
- [ ] **Course search live**: `papago` returns tees on the real PWA (confirms the Edge Function + secret in prod).
- [ ] **Realtime**: post from one device, watch it land on another without refresh.
- [ ] **Light mode + one-handed**: run gate 3 in light mode and thumb-only.

## Findings log
_(date · gate · what stalled · fix)_
-
