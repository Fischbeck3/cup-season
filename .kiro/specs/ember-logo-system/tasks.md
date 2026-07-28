# Implementation Plan: Ember Logo System

## Overview

Implement the governed Ember Logo System as a staged TypeScript/Node ESM package under `brand/ember-logo-system/`. The plan builds immutable policy and evidence records, deterministic validators and selectors, automated acceptance tooling, and migration planning without drawing a final logo or replacing production assets.

## Tasks

- [ ] 1. Establish the staged package and immutable domain contracts
  - [x] 1.1 Create the TypeScript/Node ESM package structure and test configuration
    - Add isolated source, fixture, generated-evidence, and test directories without changing current production paths.
    - Configure Node's test runner and pin an exact compatible `fast-check` version in the lockfile.
    - _Requirements: 8.1, 11.10, 13.7_
  - [x] 1.2 Implement schemas, domain types, canonical serialization, versions, and checksums
    - Define the design's authority, candidate, geometry, composition, variant, export, validation, study, exception, migration, and evidence models.
    - Reject invalid references and make identity/evidence records immutable by ID, version, and checksum.
    - _Requirements: 8.3, 12.3, 13.1, 13.3, 13.7_

- [ ] 2. Implement authority, candidate, and semantic eligibility policy
  - [~] 2.1 Implement the authority registry and conflict resolver
    - Resolve the highest applicable active authority and retain superseded statements and complete conflict records.
    - Encode D76 precedence over conflicting green-led or gold-forward statements and block unresolved conflicts.
    - _Requirements: 1.3, 1.7, 1.8_
  - [ ]* 2.2 Write the property test for ordered, auditable authority resolution
    - **Property 1: Authority resolution is ordered and auditable**
    - Generate authority graphs and conflicts for at least 100 runs; persist reproducible counterexamples with the required feature/property tag.
    - **Validates: Requirements 1.3, 1.7, 1.8**
  - [~] 2.3 Implement candidate intake and the semantic mapper
    - Enforce three to five new territories, exactly one legacy-evolution control, and at least one motion-native new territory.
    - Require named silhouettes, required details, negative-space signatures, anti-cliche/anti-betting declarations, and complete Product Story mappings.
    - _Requirements: 1.1, 1.2, 2.1, 2.4, 2.5, 2.7, 10.1, 10.2, 10.8, 12.1, 13.4_
  - [ ]* 2.4 Write the property test for complete candidate meaning
    - **Property 3: Every candidate feature has complete product meaning**
    - Generate candidate manifests and dangling feature references for at least 100 runs.
    - **Validates: Requirements 1.1, 2.1, 13.4**
  - [ ]* 2.5 Write the property test for candidate intake composition
    - **Property 4: Candidate intake has one fair comparison set**
    - Generate candidate/control combinations and motion-native flags for at least 100 runs.
    - **Validates: Requirements 12.1**
  - [~] 2.6 Implement the D76 semantic validator
    - Enforce the six-role identity palette, Heat Grammar, earned-metal reservation, money treatment, and exclusions for cliche and betting cues.
    - Mark role swaps, merged meanings, decorative heat, betting signals, and unsupported artwork colors ineligible.
    - _Requirements: 1.4, 1.5, 1.6, 4.1, 4.6, 4.7, 4.8, 10.3, 10.4, 10.5, 13.5_
  - [ ]* 2.7 Write the property test for D76 semantic integrity
    - **Property 2: D76 semantic roles cannot drift**
    - Generate role/value assignments and semantic contexts for at least 100 runs.
    - **Validates: Requirements 1.4, 1.5, 1.6, 4.1, 4.6, 4.7, 4.8, 10.3, 10.4, 10.5, 13.5**
  - [ ]* 2.8 Write unit tests for authority and semantic rejection examples
    - Cover superseded guidance, incomplete conflict records, unsupported colors, generic golf cues, betting cues, and incompatible money treatments.
    - _Requirements: 1.6, 1.7, 1.8, 10.2, 10.4, 10.5_

- [~] 3. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Implement geometry, composition, variant, and size policy
  - [~] 4.1 Implement the geometry and composition catalog validators
    - Validate vector-only masters, exact Wordmark text, outlined lettering, labeled silhouette/details, finite artboards/view boxes/bounds/optical centers, contour closure, path integrity, lockup layouts, spacing, and clear space.
    - Support Core, conditional Small-Size, Wordmark, horizontal, stacked, settled-motion, full-color, one-color, and monochrome records without modifying artwork.
    - _Requirements: 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.11, 4.2, 4.3, 4.4, 4.5, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 13.1_
  - [ ]* 4.2 Write the property test for master geometry integrity
    - **Property 5: Master geometry preserves identity without hidden dependencies**
    - Generate geometry manifests and vector fixtures for at least 100 runs.
    - **Validates: Requirements 2.5, 2.6, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7**
  - [~] 4.3 Implement the deterministic composition selector
    - Select omission, Small-Size, Core, exact-name Wordmark, or eligible Lockup from width, physical size, text support, background, process, semantic use, and motion preference.
    - Return explicit unsupported/rejected outcomes and enforce CSS/mm minima, gap ratios, clear space, and no invalid Wordmark-enabled Lockup.
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 6.12, 13.2_
  - [ ]* 4.4 Write the property test for deterministic total composition selection
    - **Property 6: Composition selection is deterministic and total**
    - Generate valid selection contexts for at least 100 runs and assert repeated results are identical.
    - **Validates: Requirements 3.1–3.10, 6.12, 13.2**
  - [~] 4.5 Implement safe variant fallback and process selection
    - Use flat full color only when valid, fall back to a documented one-color variant, select monochrome for incompatible processes, and reject when no conforming choice exists.
    - Never synthesize ad hoc recolorings or transparency-dependent identifying details.
    - _Requirements: 4.2, 4.3, 4.4, 4.9, 4.10_
  - [ ]* 4.6 Write the property test for safe variant fallback
    - **Property 7: Variant choice fails over safely**
    - Generate backgrounds, contrast outcomes, process capabilities, and variant catalogs for at least 100 runs.
    - **Validates: Requirements 4.2, 4.3, 4.4, 4.9, 4.10**
  - [~] 4.7 Implement small-size and target-process geometry validators
    - Measure silhouette/detail retention, one-device-pixel stroke/gap limits, and optical center at every integer size from 16–32 and all approved variants.
    - Prefer the primary mark unless it fails and enforce screen, print, engraving, and embroidery minima after unit conversion.
    - _Requirements: 5.1, 5.2, 5.3, 5.5, 5.7, 5.8, 8.8, 8.9, 8.10_
  - [ ]* 4.8 Write the property test for pixel-safe minimal divergence
    - **Property 8: Small-size identity is pixel-safe and minimally divergent**
    - Generate sizes, variants, primary/simplified geometry, and measurements for at least 100 runs.
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.5, 5.7, 5.8**
  - [ ]* 4.9 Write the property test for target-process minima
    - **Property 11: Geometry respects every target-process minimum**
    - Generate scales, units, strokes, gaps, details, and processes for at least 100 runs.
    - **Validates: Requirements 8.8**
  - [ ]* 4.10 Write boundary and geometry fixture tests
    - Cover 15/16/31/32 px, every CSS/mm lockup minimum, exact Wordmark cases, malformed paths, hidden dependencies, and known physical-process limits.
    - _Requirements: 2.6, 3.1–3.10, 4.5, 5.1–5.5, 8.3–8.10_

- [ ] 5. Implement platform export and accessibility validation
  - [~] 5.1 Implement the export planner and vector/raster/crop validators
    - Generate canonical `ExportSpec` records for favicon PNG/ICO, PWA, maskable, Apple touch, iOS master, social profile, Social Share Card, and approved SVG outputs.
    - Validate exact dimensions, ICO membership, master equivalence, sRGB, alpha, edge opacity, optical center, safe regions, masks/crops, and iOS no-rounding rules.
    - _Requirements: 2.8, 5.4, 6.1–6.12, 8.11, 8.12, 8.13, 13.3_
  - [ ]* 5.2 Write the property test for platform export conformance
    - **Property 9: Platform exports conform to master and crop contracts**
    - Generate export manifests, measured outputs, masks, and crops for at least 100 runs.
    - **Validates: Requirements 2.8, 5.4, 6.1–6.5, 6.7–6.10, 8.11–8.13, 13.3**
  - [~] 5.3 Implement contrast, non-color, and accessible-image validators
    - Calculate every touching color/background ratio; enforce size-specific Core, Small-Size, and Wordmark thresholds.
    - Validate non-color distinctions, informative/decorative image semantics, color-vision evidence records, and static/motion/fallback meaning parity.
    - _Requirements: 7.1–7.10, 9.11_
  - [ ]* 5.4 Write the property test for accessibility parity
    - **Property 10: Accessibility meaning survives color and motion removal**
    - Generate touching-color graphs, sizes, semantic states, image roles, and fallback records for at least 100 runs.
    - **Validates: Requirements 7.1–7.5, 7.7, 7.9, 7.10, 9.11**
  - [ ]* 5.5 Write automated export and accessibility example tests
    - Cover exact dimensions, opaque corners, safe-region masks, avatar crops, contrast values below/equal/above 3:1 and 4.5:1, accessible names, decorative images, and color-vision evidence completeness.
    - _Requirements: 5.4, 6.1–6.11, 7.1–7.10, 8.11–8.13_

- [~] 6. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Implement motion policy and automated behavior validation
  - [~] 7.1 Implement the motion controller and validator
    - Model quiet/warm-to-settled transitions with bounded roll-out easing, a 1,200 ms deadline, exact settled geometry/colors, finite ember ignition, event-scoped replay guards, and non-blocking content.
    - Bypass or replace spatial motion for reduced motion and resolve preference changes or playback failures to the equivalent static state within 100 ms.
    - _Requirements: 9.1–9.13_
  - [ ]* 7.2 Write the property test for bounded and fallback-safe motion
    - **Property 12: Motion is bounded, event-idempotent, and fallback-safe**
    - Generate endpoints, timeline samples, event streams, preference changes, and failure events for at least 100 runs.
    - **Validates: Requirements 9.1–9.4, 9.6, 9.7, 9.9, 9.10, 9.12, 9.13**
  - [ ]* 7.3 Write automated motion integration tests
    - Exercise qualifying and non-qualifying events, replay guards, operable controls/content, pre-start and mid-play reduced motion, failure fallback, settled-frame equality, and persistent non-motion meaning.
    - _Requirements: 7.9, 7.10, 9.1–9.13_

- [ ] 8. Implement study protocols, gate scoring, and fail-closed approval
  - [~] 8.1 Implement immutable study protocols and exact gate scorers
    - Freeze one twelve-person panel definition, exposure, display sizes, comparison grid, prompts, options, scoring, and balanced presentation seed for every candidate.
    - Compute recognition, association, category-position, Hat, and Archive pass/fail boundaries exactly while retaining blinded raw counts.
    - _Requirements: 2.2, 2.3, 5.6, 10.6, 10.7, 12.2, 12.4–12.9_
  - [ ]* 8.2 Write the property test for protocol-identical exact scoring
    - **Property 13: Study scoring is protocol-identical and exact**
    - Generate all valid panel counts and protocol references for at least 100 runs.
    - **Validates: Requirements 12.2, 12.4–12.9**
  - [~] 8.3 Implement the gate aggregator, exceptions, and derivative revalidation
    - Require complete machine, study, accessibility, visual-review, physical-proof, motion, and export evidence before approval.
    - Preserve measured failures, validate every owner-exception field, invalidate stale dependent evidence after version changes, and require remediated derivatives to rerun all applicable checks.
    - _Requirements: 12.3, 12.10, 12.11, 12.12, 12.13, 13.8, 13.9_
  - [ ]* 8.4 Write the property test for complete fail-closed approval
    - **Property 14: Approval is complete and fail-closed**
    - Generate matrices, gates, exceptions, catalogs, dependency versions, and remediated derivatives for at least 100 runs.
    - **Validates: Requirements 12.3, 12.10–12.13, 13.1, 13.7–13.9**
  - [ ]* 8.5 Write study and approval boundary tests
    - Cover every score boundary from 0–12, protocol drift, missing matrix fields, each omitted exception field, stale checksums, failed physical/visual evidence, and derivative remediation.
    - _Requirements: 2.2, 2.3, 5.6, 10.6, 10.7, 12.2–12.13, 13.8, 13.9_

- [ ] 9. Implement migration inventory and non-mixed transition planning
  - [~] 9.1 Implement the migration inventory scanner and planner
    - Read known legacy references from brand documentation, manifests, service worker, HTML metadata, email/press/social inventories, and iOS resources without modifying them.
    - Require exactly one treatment per asset-consumer pair, public-path continuity, cache/refresh/versioning data, recoverable checksummed archives, rollback details, identity-only scope, and atomic legacy-or-D76 surface resolution.
    - _Requirements: 11.1–11.10_
  - [ ]* 9.2 Write the property test for total non-mixed migration
    - **Property 15: Migration is total, identity-only, and non-mixed**
    - Generate inventories, treatments, cache records, dependency sets, archive states, and failure conditions for at least 100 runs.
    - **Validates: Requirements 11.2, 11.3, 11.5, 11.8, 11.9**
  - [ ]* 9.3 Write repository-fixture migration tests
    - Cover current public paths, missing consumers, duplicate/no treatments, aliases, cache refresh triggers, mixed surfaces, broken archives, and migration approval withholding.
    - _Requirements: 11.1–11.9_

- [ ] 10. Generate acceptance artifacts and wire the pipeline
  - [~] 10.1 Implement the evidence packager and generated usage artifacts
    - Generate authoritative composition/variant guidance, deterministic selection tables, export manifests, semantic/Heat Grammar maps, Evaluation Matrix, Migration Map, and labeled contact-sheet manifests.
    - Include machine, accessibility, color-vision review, study, production-proof, motion, and export evidence with versions, checksums, timestamps, measured thresholds, outcomes, and remediation references.
    - _Requirements: 12.3, 13.1–13.7_
  - [~] 10.2 Implement the pipeline CLI and dependency invalidation flow
    - Wire authority freeze, candidate intake, semantic eligibility, validators, evidence ingestion, gate aggregation, packaging, and migration planning in the approved acceptance sequence.
    - Keep generated candidate outputs namespaced and prevent writes to current production assets or promotion without a separate implementation phase.
    - _Requirements: 1.7, 11.9, 11.10, 12.10–12.13, 13.7–13.9_
  - [ ]* 10.3 Write end-to-end package integration tests
    - Run canonical eligible, ineligible, failed-gate, complete-exception, remediated-derivative, and migration-blocked fixtures through the CLI.
    - Assert deterministic outputs, complete traceability, no production-path writes, and no disagreement between generated reports and the package manifest.
    - _Requirements: 1.1–1.8, 2.1–2.8, 4.1–4.10, 7.1–7.10, 8.1–8.13, 9.1–9.13, 10.1–10.8, 11.1–11.10, 12.1–12.13, 13.1–13.9_

- [~] 11. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional automated test tasks and can be skipped for a faster MVP.
- Every correctness property has exactly one dedicated `fast-check` task with at least 100 generated runs and the required property comment tag.
- Human perception studies, color-vision review, and physical proofs are represented as immutable evidence inputs; conducting those activities is not a coding task.
- This plan does not draw final artwork, replace production assets, alter manifests/service workers/iOS resources, deploy, or perform migration.
- Each task references granular requirements for traceability.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2"] },
    { "id": 2, "tasks": ["2.1", "2.3"] },
    { "id": 3, "tasks": ["2.2", "2.4", "2.5", "2.6"] },
    { "id": 4, "tasks": ["2.7", "2.8", "4.1"] },
    { "id": 5, "tasks": ["4.2", "4.3", "4.7"] },
    { "id": 6, "tasks": ["4.4", "4.5", "4.8", "4.9", "4.10"] },
    { "id": 7, "tasks": ["4.6", "5.1", "5.3"] },
    { "id": 8, "tasks": ["5.2", "5.4", "5.5", "7.1", "8.1", "9.1"] },
    { "id": 9, "tasks": ["7.2", "7.3", "8.2", "8.3", "9.2", "9.3"] },
    { "id": 10, "tasks": ["8.4", "8.5", "10.1"] },
    { "id": 11, "tasks": ["10.2"] },
    { "id": 12, "tasks": ["10.3"] }
  ]
}
```
