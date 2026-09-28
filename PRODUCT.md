# Product: Cup Season

<!-- impeccable:product-schema 1 -->

Compiled context, 2026-09-27, from source baseline `5fabf861` and the [owner interview](docs/planning/2026-09-27-impeccable-ten-prompt.md). This is a cited view of existing canon, not a new authority. Vision → principles → information architecture → mechanics → UI → implementation; ratified decisions and canonical sources win conflicts. Approval of this compilation is pending the program checkpoint.

## Platform

web

The root record carries shared product truth and the single-file PWA in `index.html`. [The phone record](apps/ios/PRODUCT.md) scopes SwiftUI/iOS; it does not change shared rules. Two clients, one product, two shapes: the phone at the turn; the web at the desk. [CLAUDE.md, The phone](CLAUDE.md#the-phone-d99-2026-08-27), D234 in [decision-log](spec/decision-log.md).

## Users

Amateur golfers in real friend groups, posting real handicapped rounds from anywhere, and the Pro who runs their league. On the phone, at the turn or just after golf, post in seconds and see the season consequence. At a desk, read the season and run the league. [Owner interview](docs/planning/2026-09-27-impeccable-ten-prompt.md), [vision: personas and user stories](spec/product-vision-v1.0.md).

## Product Purpose

Turn rounds people already play into standings, rivalries, a Cup Final or points-table endgame, and a record that accumulates. Reduce work; make the golf matter. Each points figure must lead to the rounds or adjustments that produced it. The launch-path task is door → first round → post → share → Home. [Vision](spec/product-vision-v1.0.md), [rules §16](spec/spec-v1.0.md), [owner interview](docs/planning/2026-09-27-impeccable-ten-prompt.md).

## Positioning

“Cup Season is where amateur golf counts.” The mechanism is competition and memory made from real golf with real friends. It is not a GPS, shot tracker, swing coach, betting app or statistics collector. [Brand canon §1](spec/brand-canon.md), [vision](spec/product-vision-v1.0.md).

## Operating Context

Phone use is interrupted, outdoors and one-handed; desk use allows season reading and league administration. Five destinations remain Home, Compete, Play, Golfers and You. The web keeps its sidebar and wide two-column body; it does not reproduce phone tabs at desktop width. Supabase owns competition logic, shared by the clients. [D234 and D222](spec/decision-log.md), [UI_SYSTEM §14](docs/ui-overhaul-2026-09-06/UI_SYSTEM.md), [AGENTS §§5,9](AGENTS.md).

## Capabilities and Constraints

- Post real rounds, read their receipts, keep a golf record, and play season and event competition. Do not collect extra in-play information without approval. [Vision](spec/product-vision-v1.0.md), [AGENTS §9](AGENTS.md).
- Every points total is traceable; factual rounds are not silently rewritten. No scoring logic is reimplemented in a client. [Rules §16](spec/spec-v1.0.md), [AGENTS §§5,7](AGENTS.md).
- The literal money sentence is **Cup Season keeps the ledger; the money moves between friends.** Keep one constant per client and the placement from UI_SYSTEM §16A.1. [Brand canon §3](spec/brand-canon.md).
- UI says **the Pro**, **Run it back**, and named performance bands; no PvI/differential, sportsbook language, corporate golf language, hype or streak shame. One fact, one place. [AGENTS §10](AGENTS.md), [D360](spec/decision-log.md).
- Shared round conversation, guarded findability and circle-scoped course bests follow D391–D396. A nine without recorded side cannot claim a comparable best. Share/photo consent and cancellation semantics follow D380/D385. [Decision log](spec/decision-log.md).
- Source generation stays at its source: tokens, RPC contracts, marker tables and the pennant source. No dependency, brand replacement, mechanics or data changes are authorized by this program. [AGENTS §6](AGENTS.md), [owner request](docs/planning/2026-09-27-impeccable-ten-prompt.md).
- October 1 remains submission/public launch; September 30 is visual freeze. The program's source changes require a later explicit “build it” with named scope; no launch inclusion is implied. [D371](spec/decision-log.md), [visual sprint](docs/planning/2026-09-22-visual-ui-sprint.md).

## Brand Commitments

Use the existing canon, [tokens](packages/tokens/tokens.json) and [UI_SYSTEM including amendments](docs/ui-overhaul-2026-09-06/UI_SYSTEM.md). D358 ratified the CS pennant. D359/F11 distinguish ordinary actions (`act`) from competition ember; D381 narrows Compete's full ember band to live competition. D368 retains its narrow earned-play-moment exception. Gold is earned; secondary words use opaque `mut`. Dark-first (D76), two themes, bounded personal looks (D305/D313 as amended by D359). The compiled [DESIGN.md](DESIGN.md) is subordinate to those sources. No mark/icon/production-asset replacement.

## Evidence on Hand

PIGL, the beta league and existing fixtures exist; they are not testimonials or acquisition claims. No press, testimonials or customer claims are available to invent. This public repository receives only demonstrably synthetic captures and their provenance. Legacy fixtures containing real pilot identities are not safe public evidence merely because they are called demo. No fabricated faces. Missing fixture means not captured, not scored. [Owner interview](docs/planning/2026-09-27-impeccable-ten-prompt.md), [UI_SYSTEM §6/§10](docs/ui-overhaul-2026-09-06/UI_SYSTEM.md).

## Product Principles

Golf first. Low friction wins. Real golf only. Memory over statistics. The app should feel alive. Apply the five-question filter: reduce friction, strengthen the season, create memories, encourage return, and prefer what can happen automatically from data already collected. [Vision](spec/product-vision-v1.0.md), [AGENTS §9](AGENTS.md).

## Accessibility & Inclusion

WCAG AA contrast in both themes; 44pt/px touch targets; Dynamic Type through AX3; VoiceOver, keyboard access where relevant and Reduce Motion. Every number has a readable label and color has a second channel. A screenshot is not a usability pass: timed unassisted tasks require human evidence. [Owner interview](docs/planning/2026-09-27-impeccable-ten-prompt.md), [UI_SYSTEM §16](docs/ui-overhaul-2026-09-06/UI_SYSTEM.md).

## Open decisions

Content acquisition and consent plan, launch-safe slices, stale-doc corrections and tool/canon conflicts await the checkpoint. Broader evidence budgets beyond the requested matrix are (inferred — confirm). No inference here ratifies a rule.
