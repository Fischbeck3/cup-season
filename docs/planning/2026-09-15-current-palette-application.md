# Current palette, more distinctive use

**Selected for implementation handoff, 2026-09-15: option 2 · Scoreboard.** The owner accepted adding the recommended direction to Claude's handoff. The exploration text below records the reasoning; selection supersedes its earlier pending-status language. See the current owner amendment in `spec/decision-log.md`. No app changes or deployment have been performed by Codex.

2026-09-15. Owner steering: “Ok let's explore our current color set and how they can be more distinctive.” Exploration only; no production token or client change. Earlier palette alternatives remain unselected. Existing pennant geometry stays unchanged.

## Diagnosis and proposal

Small accents are carrying too many jobs while large surfaces remain almost identical. The same fescue field, thin rule and tiny color tick cannot establish a distinct competition experience. Keep the actual colors and give them larger, more consistent roles.

| Current source role | Existing dark value | Proposed application |
|---|---|---|
| Fescue / raised forest | #0F1A15 / #1A2620 | The everyday app and stable navigation shell; Home, Play, Golfers and You |
| Paper / ink | #F4F1E9 / #F1F4EF | Legible score panels, leaderboard leaves and editorial contrast |
| Ordinary action | #5FA271 | Tee it up, ordinary Play actions and applause selected state |
| Ember | #E8622C | A recognizable competition treatment: mastheads, scoreboard bands or major match panels |
| Earned gold | #D8B25A | Earned trophies/recognition, never generic section decoration |

Values checked against `packages/tokens/tokens.json` in the current Claude checkout. Existing light counterparts still apply: this is not permission to use dark ember for small text on paper. Semantic pos/neg, team identity and other protected values retain their meanings. Generated art is not a substitute for contrast verification.

Calculated from these exact source colors: fescue text on ember 5.27:1, cream text on ember 3.05:1, fescue text on action green 5.85:1, and dark ink on paper 15.49:1. Use dark ink on the proposed large ember panels; cream is substantially weaker there. These are solid-color calculations, not certification of generated pixels or every control state.

**Proposed amendment:** ember becomes competition identity, not a claim that every colored item is currently live. Competitions can carry it before, during and after play, with explicit state words. It follows a competition onto Home. A plain booked round does not become ember just because its date is today. This broadens the September 14 active-only rule; it requires recording the selected direction before implementation. The owner has requested exploration, not selected a treatment yet.

## Three applications of the same colors

1. **Header:** a substantial ember masthead/ribbon, fescue content and cream scores. Quietest option, but lower competition content may still resemble ordinary Home.
2. **Scoreboard:** fescue masthead, one broad ember season/score panel with dark ink, quieter forest match rows, paper leaderboard. Recommended balance: competition is immediately recognizable while most reading remains calm.
3. **Full field:** ember competition ground, dark type and paper score panels. Highest energy; prototype long sessions and large data surfaces before considering it as a default. May suit a compact match or final view better than every Compete screen.

Keep a coherent section language: Compete overview, season room, event and matchup should share the chosen treatment. A miniature version signs the same item in Home or a notification preview. Status, eligibility, ownership and actual match state come from their producers, not from color. Theme selection cannot silently change those meanings.

## Review and delivery

[Phone-viewable board](../brand/references/2026-09-15-current-palette-application-final.png). [Built-in generation prompt](../brand/references/2026-09-15-current-palette-prompt.md). The board shows option 2 at scale and all three treatments beneath it.

Judge color area, hierarchy and distinction first. Retain exact logo source and established type roles in any implementation. Example names/scores and course photography are illustrative. Any incidental drawing, icon, copy or shading variation in generated boards is not an approved product change.

After selection, build deterministic Home/Compete examples and the same competition in upcoming/live/finished states, light/dark and enlarged text. Validate contrast for normal text and controls and confirm gold cannot be mistaken for an ordinary win probability or predicted outcome. Update color-role decisions, then token sources and both clients together. No deployment is part of this exploration.
