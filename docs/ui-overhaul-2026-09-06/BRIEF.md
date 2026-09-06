# CUPSEASON — HARD UI OVERHAUL (the owner's brief, verbatim, 2026-09-06)

> Received 2026-09-06. The trailing instruction was: *"Design on scheme on Fable, pause so we can build on Opus."* — i.e. Phases 1–2 (audit + system) are designed in this session; Phase 3+ (building) is a later session on another model. Nothing in this folder is code.

## Mission

The UX architecture and core flows of CupSeason have now been substantially improved.

Your job is to take a **hard, uncompromising look at the UI**.

This is a separate phase.

Do not assume that because the UX is now logically sound, the product looks or feels good.

The objective is to transform CupSeason from an application that is functionally usable into a **premium, distinctive, modern golf product that people actually want to look at and open.**

This is not a cosmetic polish pass.

It is a **UI system overhaul**.

---

# 1. THE STANDARD

CupSeason should feel like a product that could sit alongside the best consumer sports apps.

It should feel: premium · confident · editorial · athletic · social · competitive · distinctly golf · modern · slightly irreverent

It should NOT feel like: a golf scorekeeping app · a generic SaaS dashboard · an admin tool · a template-based React app · a collection of cards · a developer-built MVP · a fantasy sports clone · an overly minimalist fintech app

The visual design should create an emotional response: **"Damn, this looks good."**

# 2. DO NOT START BY CODING

First inspect the entire existing UI. Explore every meaningful screen and state.

Audit: typography · spacing · hierarchy · colors · contrast · buttons · inputs · cards · navigation · tabs · headers · icons · avatars · player cards · course cards · feed items · leaderboards · standings · score displays · event pages · season pages · profile · empty states · modals · sheets · notifications · loading states · error states · success states

Also inspect: mobile dimensions · small screens · large screens where applicable · long content · empty data · many users · long names · large scores · missing profile photos · courses with long names

Create `UI_AUDIT.md`. For every significant screen identify: What works · What feels cheap · What feels generic · What feels visually confusing · What lacks hierarchy · What lacks personality · What has unnecessary visual noise · What looks inconsistent · What could feel significantly more premium. Be ruthless.

# 3. DESIGN THE SYSTEM BEFORE POLISHING SCREENS

Create `UI_SYSTEM.md`. Define the CupSeason visual language: typography · type scale · font weights · spacing scale · corner radius system · shadows · borders · iconography · button hierarchy · input styles · surface hierarchy · avatar system · badges · pills · dividers · cards · navigation · motion · transitions · image treatment · data visualization · color roles. Do not simply define dozens of arbitrary values. Build a coherent visual system.

# 4. CREATE A STRONG VISUAL IDENTITY

CupSeason needs a recognizable visual language. Do not default to whatever styling already exists in the codebase. Ask: *If I removed the CupSeason logo, would this still look like CupSeason?* The answer should eventually be yes.

Explore how the product can express — GOLF (course imagery, fairways, scorecards, clubhouse aesthetics, topography, grass / earth / natural materials, tournament graphics) · COMPETITION (rank, movement, position, wins, losses, head-to-head, stakes) · SOCIAL (faces, friends, activity, shared rounds, comments, reactions) · HISTORY (archives, records, course history, season history, rivalries). These should influence the visual language without becoming literal golf clichés.

Avoid: golf-ball icons everywhere · excessive green · cartoon golf graphics · cheesy country-club aesthetics · generic sports gradients

# 5. TYPOGRAPHY

Typography should carry a significant portion of the brand. Establish: **Display** (major scores, player names, season titles, event titles, major numbers) · **Heading** (section hierarchy, important information) · **Body** (descriptions, feed content, supporting information) · **Metadata** (dates, course information, secondary stats). Typography should create visual hierarchy without relying on boxes around everything. Ask constantly: *Can typography solve this hierarchy problem better than another card?*

# 6. STOP USING CARDS AS THE DEFAULT UI

**Do not put everything inside a rounded rectangle.** Cards should have a purpose. Use whitespace, typography, dividers, alignment, imagery, grouping, hierarchy to create structure. Cards should indicate meaningful conceptual boundaries, not simply separate every piece of content. If the existing UI has card inside card inside card, remove it.

# 7. HOME / FEED VISUAL REDESIGN

Home is the visual centerpiece. It should feel like opening a premium sports feed. The hierarchy should immediately communicate WHAT'S HAPPENING · WHAT MATTERS · WHAT'S NEXT. Do not make every feed item visually equal. Different visual treatments for:

- **Competition moments** — big / prominent. e.g. **YOU MOVED TO 2ND** · ↑ 2 spots · Jake — 4 pts ahead
- **Friend round** — more social. e.g. **Jake shot 74 at Troon North** · photo/avatar · 82 → 74
- **Course discovery** — more editorial. e.g. **PUNTA BRAVA** · ★★★★★ · "Best course I've played this year."
- **Season moment** — more dramatic. e.g. **THE FINAL IS HERE** · Round 10 · Saturday
- **Minor activity** — quiet.

Do not give every action the same visual weight.

# 8. BUILD A VISUAL CONTENT HIERARCHY

Every screen should have PRIMARY (what absolutely matters) · SECONDARY (what supports it) · TERTIARY (what can be visually quiet). If everything is bold, nothing is important.

# 9. PLAYER CARDS

Player cards are a major part of CupSeason's identity. They should feel collectible. A player card should communicate: face/avatar · name · handicap · current status · recent form · competition position · course activity. e.g. **JAKE** · 8.4 HCP · **2ND** · ↑ 1 · Troon North · 74 · ★★★★★. Do not cram every statistic into the card. Use hierarchy.

# 10. PLAYER PROFILE

The profile should feel like a **golfer's identity page**, not an account settings screen. HERO (photo, name, handicap, location if appropriate) · COMPETITION (wins, losses, current season, rivalries) · GOLF (recent rounds, top courses, courses played) · HISTORY (past seasons, career record, course history). The profile should feel aspirational. A golfer should enjoy showing it to someone.

# 11. COURSE UI

Courses are becoming a major part of CupSeason. Treat them as editorial objects. A course should visually communicate: name · location · rating · image · difficulty · friend activity · recent rounds. Course cards should feel more like travel/editorial content than database records. When imagery is available, use it. A beautiful course image can be one of the strongest visual elements in the entire app.

# 12. COURSE RATING

Make ratings visually satisfying. ★★★★★ should feel like a meaningful piece of content, not a form field. Consider: large rating treatment · half stars where appropriate · community rating · friend's rating · user's rating. e.g. **PUNTA BRAVA** · **4.8 ★** CupSeason golfers · **Your friends: 4.9 ★**. This is information users should want to explore.

# 13. SEASONS

Seasons should have a distinct visual identity. A season is a **story**, not a settings page. Give it: title · identity · participants · current standings · progress · upcoming event · season narrative · history. The current leader should visually matter. Movement should be obvious. Important matchups should be visually emphasized. Avoid turning the season page into a spreadsheet.

# 14. EVENTS

Events should feel like moments. Strong visual treatment for: event title · course · date · participants · stakes · countdown · leaderboard. Think **TOURNAMENT GRAPHIC**, not **DATABASE RECORD**.

# 15. LEADERBOARDS

Leaderboards should be extremely readable. Hierarchy: POSITION · PLAYER · SCORE / POINTS · MOVEMENT · STAKE. Do not overdesign them. The user should be able to scan a leaderboard instantly. Movement should be visually obvious — **↑ 3** should immediately communicate more than a paragraph of explanation.

# 16. SCORE DISPLAYS

Golf numbers are visually important. Treat score · differential · points · position · handicap as visual objects. Don't bury important numbers in tiny gray metadata. A score of **74** should look like a meaningful piece of information.

# 17. EMPTY STATES

Empty states are opportunities to create personality. Do not use generic "Nothing here yet." Instead create visually strong invitations. e.g. YOUR NEXT COMPETITION · **Nothing scheduled yet.** · Your next round could change that. · **Start Something**. Empty states should feel intentional rather than unfinished.

# 18. BUTTONS & INTERACTION

Reduce button complexity. Primary (one obvious action) · Secondary (useful alternative) · Tertiary (quiet action). Avoid: five equally prominent buttons · excessive outlines · buttons that look like links · inconsistent button sizes. The primary action should be obvious without explanation.

# 19. ICONOGRAPHY

Audit every icon. Icons should feel like one coherent family. Do not mix random icon libraries, emoji, inconsistent stroke weights, different visual metaphors. If an icon isn't necessary, remove it.

# 20. IMAGERY

Photography should be an important part of CupSeason's visual identity. Use imagery where it adds emotional value: courses · rounds · player profiles · events · travel/discovery. Do not add stock photography simply to fill space. Course imagery should feel authentic, beautiful, editorial, aspirational.

# 21. MOTION

Add subtle motion where it communicates state: leaderboard movement · score submission · challenge acceptance · season progression · successful competition creation · feed interactions. Motion should communicate **"Something changed."** Avoid animation for animation's sake. The app should feel alive, not gimmicky.

# 22. MICRO-INTERACTIONS

Opportunities around: rating a course · completing a round · moving up a leaderboard · winning an event · joining a season · challenging a friend · reacting to a post. These moments should have small moments of delight.

# 23. VISUAL STATES

Every major component must have intentional default · hover where relevant · pressed · selected · disabled · loading · success · error · empty states. Do not let browser/framework defaults define the product.

# 24. RESPONSIVENESS

Audit at small phone · standard phone · large phone · tablet if supported · desktop/web if supported. Do not simply allow components to shrink. Redesign hierarchy where necessary.

# 25. ACCESSIBILITY

Premium UI must still be usable. Audit contrast · font sizes · touch targets · keyboard interaction where relevant · screen reader labels · focus states · dynamic content · color-only communication. Do not sacrifice usability for aesthetics.

# 26. DESIGN CONSISTENCY AUDIT

After establishing the new system, search the entire application for inconsistent implementations: duplicate button styles · duplicate card styles · inconsistent spacing · inconsistent typography · inconsistent radii · inconsistent colors · inconsistent icon sizes · inconsistent modal behavior · inconsistent navigation. Consolidate them into reusable components/tokens.

# 27. REMOVE VISUAL DEBT

Explicitly look for: unnecessary borders · unnecessary shadows · excessive rounded corners · excessive pills · tiny text · dense layouts · excessive labels · redundant icons · repetitive headers · competing CTAs · decorative UI with no purpose. The goal is not to add more design. The goal is to **make the important things feel important.**

# 28. DESIGN REVIEW

Before implementation is considered complete, review the product screen-by-screen. For every screen ask:
1. What is the most important thing on this screen?
2. Can I identify it instantly?
3. Does the visual hierarchy support the UX?
4. Does this look like CupSeason?
5. Does this look premium?
6. Does anything feel like a generic template?
7. Is there unnecessary UI?
8. Could this screen be 20% simpler?
9. Is there an opportunity for personality?
10. Would I be proud to screenshot this screen and post it?

That final question is important.

# 29. CREATE A UI SCORECARD

Create `UI_SCORECARD.md`. Score every major screen from 1–10 on: Visual hierarchy · Typography · Spacing · Consistency · Brand identity · Premium feel · Readability · Emotional appeal · Information density · Mobile usability. Anything below **8/10** should be considered unfinished. Anything below **6/10** requires redesign rather than polish.

# 30. IMPLEMENTATION ORDER

Phase 1 Audit (`UI_AUDIT.md`) · Phase 2 Visual system (`UI_SYSTEM.md`) · Phase 3 Redesign the highest-visibility surfaces: 1 Home/feed · 2 Player cards · 3 Player profile · 4 Course cards/pages · 5 Season · 6 Event · 7 Leaderboards · Phase 4 Propagate the design system · Phase 5 Remove visual inconsistencies · Phase 6 Responsive/accessibility audit · Phase 7 Final blind visual review.

# 31. IMPORTANT: DO NOT MAKE EVERYTHING LOOK THE SAME

A design system does NOT mean every screen should look identical. There should be a hierarchy of visual moments. HOME social / dynamic · PROFILE identity / personal · COURSE editorial / discovery · SEASON competition / narrative · EVENT tournament / moment · HISTORY archive / achievement. Use the same underlying visual language while allowing each surface to have its own character.

# 32. DO NOT OVER-CARD THE PRODUCT

If your instinct is "Let's put this into a card." — stop. Ask: could hierarchy, whitespace, typography, or imagery communicate this better? Cards are a tool, not the design language.

# 33. DO NOT OVER-GAMIFY

CupSeason already has inherently compelling things: friends · golf · scores · competition · courses · money/stakes · seasons · rivalries. Do not cover those with badges everywhere, XP, meaningless points, cartoon animations, streak spam, achievement clutter. Make the real golf feel exciting.

# 34. THE VISUAL TEST

After the overhaul, take screenshots of Home · Feed · Player card · Player profile · Course page · Season · Event · Leaderboard · Add round · Empty state. Put them next to screenshots from leading consumer sports/social apps. Ask: *Does CupSeason look like it belongs in this category?* If not, keep working.

# 35. FINAL STANDARD

CupSeason should not look like **an app that contains a cool golf competition product.** It should look like **a cool golf product.** The UI should make the underlying product feel more valuable. When someone sees a CupSeason screenshot, they should be able to tell: **Golf. Competition. Friends. Premium. CupSeason.** And they should want to tap into it.
