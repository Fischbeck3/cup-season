# Cup Season — Session Tracks

Durable work **lanes** for branching focused sessions. A lane's charter outlives
any sprint — the current backlog just slots into whichever lane owns it. Keep a
session inside one lane so context stays tight; if a request is a different verb,
branch it.

**The routing rule (what verb is it?):**
Gameplay builds the rule · UX makes it legible · Social makes it sticky ·
Growth gets it in front of people · Business decides why it exists.

Shared context every lane inherits: `CLAUDE.md` (architecture, rules, current
state), the memory index, the task list (what's active), and
`spec/decision-log.md` (why a mechanic is the way it is). A branch prompt only
sets *focus* — it doesn't re-explain the project.

---

## The lanes

| Lane | Owns (durable charter) | Governed by |
|---|---|---|
| **Gameplay & Competition** | Mechanics: modes, scoring, handicaps, seasons, side games, events, rules | spec-v1.0, gameplay-modes, decision-log (level 4) |
| **Experience & Interface (UX)** | How it reads/feels: onboarding, no-tutorial clarity, info hierarchy, plain-language copy, visual/brand, accessibility, friction targets | Principle 2 (Low Friction), IA blueprint (level 5) |
| **Social & Engagement** | "Feels alive" + "memory > statistics": feed, rivalries, moments, trophies, photos, comments, notifications, retention loops | Principles 4 & 5 |
| **Growth, Launch & Scale** | Acquisition, deploy/ops, QA, performance, reliability, infra | prelaunch-qa, launch-state, db-push-handoff |
| **Business & Strategy** | Vision, roadmap, positioning, monetization, focus groups, partnerships | product-vision, prospectus (levels 1–2) |

---

## Kickoff prompts (paste one into a fresh session)

### Gameplay & Competition
```
This session owns GAMEPLAY & COMPETITION — the mechanics: modes, scoring,
handicaps, seasons, side games, events, rules (level 4 of the hierarchy of
truth). Governed by spec/spec-v1.0.md, spec/gameplay-modes-working.md, and
spec/decision-log.md — log every mechanic change before building. NOT this lane:
how it reads (UX), the feed/retention (Social), deploy/pricing (Growth/Business).
Read the task list for what's active. Talk-first; build on an explicit "build it."
```

### Experience & Interface (UX)
```
This session owns EXPERIENCE & INTERFACE — how Cup Season reads and feels:
onboarding, the never-need-a-tutorial standard, information hierarchy, plain-
language copy (say "your number," never "PvI"), visual/brand, accessibility, and
friction targets like the 60-second post. Level 5. Governed by product-vision
principle 2 (Low Friction) + the IA blueprint + the gameplay-audit findings.
The mechanics are the Gameplay lane's; you make them legible. Talk-first.
```

### Social & Engagement
```
This session owns SOCIAL & ENGAGEMENT — the "app feels alive" and "memory >
statistics" pillars: the feed/board, rivalries, moments, trophies, photos,
comments, notifications, and the between-rounds retention loops. Governed by
product-vision principles 4 & 5. Photos (#13) and feed texture live here. Read
the task list; talk-first on shape, then build.
```

### Growth, Launch & Scale
```
This session owns GROWTH, LAUNCH & SCALE — getting and keeping users and the
machinery under it: acquisition (the shareable-artifact loop — claim links,
settlement cards, season recaps), the deploy/ops runbook (db push / git push /
functions deploy / webhooks / pg_cron — the USER runs these; you sequence and
verify), QA, performance, reliability. Read spec/prelaunch-qa-2026-07-13.md +
memory launch-state + workflow-db-push-handoff. Ops + strategy, talk-first.
Don't build gameplay.
```

### Business & Strategy
```
This session owns BUSINESS & STRATEGY — the why and the where: vision, roadmap,
positioning, monetization (the parked per-league pricing + Founding League
badges), focus groups, partnerships. Levels 1–2 of the hierarchy, so decisions
here cascade downward — name any conflict. Governed by product-vision-v1.0.md +
the founding-prospectus memory + CLAUDE.md monetization. Strategy, talk-first,
no code.
```

---

*A lane is a focus, not a wall — a Gameplay session can note a UX or Growth
implication and hand it off (spawn a task or say "that's a UX-lane call"), it
just doesn't chase it. When in doubt, the routing rule above decides.*
