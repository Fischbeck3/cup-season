# Mobile Safari experience catch-up · Claude build packet

Date: 2026-09-13. Status: **Ready for Claude; not dispatched or implemented by Codex.**

Outcome: opening cupseason.app on a phone should make the current competition and the next useful action clear, and every visible entry point should work. Preserve the recently shipped gameplay and continuity work.

Read the [mobile web audit](../reviews/2026-09-13-mobile-web-experience-audit.md) first. Its finding IDs are the acceptance checklist.

## Ownership and starting point

Claude is lead builder and sole editor of `index.html` for this packet, plus narrowly related web tests and handoff documentation. Codex independently reviews commits and helps with local/device acceptance. Neither agent edits the other's active branch. Owner handles Apple certificate/signing access separately.

Create a new `claude/mobile-safari-experience` branch/workspace from freshly fetched current `origin/main`. Confirm it contains audited live source `963d0e6`; if main has advanced, inspect the intervening diff and record the exact new base. Obtain these audit/brief docs from `codex/mobile-web-audit-2026-09-13` without switching or modifying that workspace. The audit workspace starts at release-evidence checkpoint `eca1b3c`.

Read AGENTS.md, CLAUDE.md, docs/doc-map.md and the canonical sources linked in the audit. Current scope is responsive web implementation; no native, token-system, gameplay, database or production-mark rewrite.

## Checkpoint A — working doors and a useful first screen

Make small reviewable commits in this order.

1. **MW-01:** reproduce the failure through the actual visible Compete control. Bind it to the existing creation intent sheet. Add a meaningful regression that fails on the current dead link and passes after the repair. Exercise both populated and empty entry paths with proper roles. Cancel/back must not create a league.
2. **MW-02:** simplify Home's hierarchy. One lead/primary action, a compact personal and competition context, then recent golf. Apply existing suppression precedence to after-golf, active play and other urgent states. Avoid duplicate facts and anonymous identical stories from different leagues. Keep useful round photography and no-photo records.
3. **MW-03/MW-07:** make Compete scan as competition: name, real standing where known, one meaningful status; clear creation and existing join/discovery controls. Remove empty archive chrome. Apply existing mobile typography/spacing/icon roles without changing the wide-screen IA.

Inspect existing authoritative per-membership facts, including the shared Home/Me payload, before proposing another data source. Join facts by league identity. A missing rank stays missing; a stale/error state must not render a fabricated leader. Do not calculate competition scoring in JavaScript.

Return checkpoint A commit, before/after captures and tests while the remaining packet is still in progress. Codex reviews that commit; Claude remains the sole builder and fixes findings.

## Checkpoint B — understand, post and customize

4. **MW-04:** make the season table and contribution the first useful content. Use existing room navigation and route semantics for board, money and rules; consolidate repeats where they truly describe the same fact. Preserve individual and squad distinctions, tie semantics, receipts, ledger details and administrator access. A new navigation model would need a separate explicit proposal.
5. **MW-05:** give posting a clear score → course/tee/date → action hierarchy. Optional photo/scan/partners remain accessible without dominating. Replace generic squad/counting claims with current format-aware copy. Keep all release fixes for date reset, draft ownership, retry, photo/no-photo and after-golf linking intact.
6. **MW-06:** shorten setup copy and expose progress in ordinary words. Explain actual preset consequences; preserve explicit pace suggestions, custom values, no minimum/Unlimited and exact review agreement. Do not change draft creation timing, durable retry keys or league rules as a layout cleanup.

Finish with consistency across these screens: token typography, readable metadata, quiet rules/bands, one primary action, familiar icons with labels where needed. Keep the existing mark and semantic colors. Do not add a new font or third-party dependency.

## Required evidence

| Area | Acceptance |
|---|---|
| Real controls | Tests enter through rendered tabs, buttons and links. Assert the resulting route/sheet/state, not merely a callable helper or a clean console. |
| Mobile layout | Before/after at 390×844 and 320×844. No horizontal overflow; readable hierarchy and reachable actions. With enlarged text, allow natural scrolling rather than forcing everything into one viewport. |
| Wider web | 1440px remains coherent with existing sidebar/two-column IA. Check dark and light themes. |
| Home/Compete states | Populated and empty, loading/error, missing standing, multiple leagues, urgent after-golf/active play, long names and no-photo/photo activity. Fixtures are explicitly labeled. |
| Setup | Suggestion decline/apply, custom/off-ladder values, back/review, cancellation and retry preserve exact choices. A name-sheet click is not proof that a league was successfully published. |
| Posting | Required-field errors, correct solo/squad copy, course/tee/date editing, photo/no-photo, draft restoration, failed retry and accepted-post reset remain correct. Use controlled local/test data for submissions. |
| Points and routes | Table → contribution/receipt remains intact; board, money and rules open the intended existing destination. |
| Accessibility/Safari | Keyboard focus, labels, touch targets, large text, VoiceOver and actual iPhone Safari safe areas/keyboard/navigation. Chromium screenshots do not satisfy the Safari gate. |
| Checks | Small meaningful regressions first; existing relevant browser/domain tests; `npm run preflight` before push. Report exact failures and untested items. |

Do not fix test expectations to fit the new screen when they describe a real product requirement. Conversely, update obsolete selector/layout assertions without preserving unwanted chrome. Test the behavior that protects the user.

## Boundaries and delivery

No new notification audiences, Live Activity mechanics, public discovery model, scoring rules, default competition commitments, mark selection or web look picker. No database/Edge deployment or secret changes in this packet. If a backend limitation blocks truthful presentation, return the exact missing fact and compatible proposal before widening scope.

Record the candidate hash, files, findings disposition, test results and before/after evidence in one handoff. Mark each audit item fixed/partial/deferred with reasons. Keep private screenshots local or use clearly labeled fixtures for shareable evidence.

A finished build is ready for review, not automatically live. After review, follow the existing authorized release workflow: preflight, web deployment and independent HTML/service-worker SHA readback, then real iPhone Safari acceptance. Report DB, Edge, web and TestFlight independently. Signing work must not block the web catch-up.

## Copyable kickoff

> Take lead on the mobile Safari catch-up sprint. Read docs/planning/2026-09-13-mobile-safari-experience-sprint.md and docs/reviews/2026-09-13-mobile-web-experience-audit.md from codex/mobile-web-audit-2026-09-13 (local workspace /Users/fischbeck3/cup-season-mobile-web-audit). Start a separate claude/mobile-safari-experience branch/workspace from current origin/main and record the base. You own web implementation and tests; Codex reviews. First reproduce and fix the dead Compete → Start something control through a real DOM interaction, then complete checkpoint A (Home and Compete hierarchy), followed by checkpoint B (season, posting and setup). Preserve shipped gameplay, editable rules and draft/retry behavior. Use current tokens and approved design hierarchy. Return small committed checkpoints with screenshots and actual flow assertions; no production DB/Edge changes, new mechanics or mark replacement. Flag actual Safari/device checks as outstanding until performed.
