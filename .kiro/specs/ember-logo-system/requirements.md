# Requirements Document

## Introduction

The Ember Logo System will replace the functional green-era Cup Season mark with a complete, production-ready identity family aligned with the owner-approved D76 Charcoal direction: charcoal grounds, ember heat for live momentum, and champagne gold for earned honor. The system must make Cup Season recognizable as the operating system for season-long amateur golf competition rather than as a score tracker, country-club crest, or betting product.

The recommended creative territory is a compact, ownable synthesis of the golf cup or ball marker, season progression, and an ember that is heating up. The requirements intentionally define the meaning and performance of that synthesis without selecting a final illustration. Candidate concepts should include a motion-native route and an evolution of the existing mark as a migration control.

This requirements phase follows the project hierarchy of truth: Product Vision → Product Principles → Information Architecture → Mechanics → User Interface → Implementation. `spec/product-vision-v1.0.md` governs the product meaning. `spec/decision-log.md` D76 governs the current charcoal, ember, heat, and earned-gold identity. The unchanged promise, voice, hat test, archive test, typography, motion, and guardrails in `spec/brand-canon.md` continue to govern. D76 supersedes the canon's earlier green-led and gold-forward color statements. No implementation code or existing production asset is modified in this phase.
## Glossary

- **Logo_System**: The complete Cup Season identity family, usage rules, production masters, platform exports, motion behavior, and migration contract.
- **Core_Mark**: The primary symbol that identifies Cup Season without accompanying text.
- **Wordmark**: The distinctive typographic rendering of the name “Cup Season.”
- **Lockup**: An approved fixed arrangement of the Core_Mark and Wordmark.
- **Small_Size_Mark**: An optically adjusted Core_Mark intended for display from 16 through 32 CSS pixels.
- **D76_Identity**: The owner-approved Charcoal identity in decision D76: charcoal for stable surfaces, amber-to-ember heat for live momentum and action, slate for stable or cooling states, and champagne gold for earned honor.
- **Heat_Grammar**: The D76 rule that increasing momentum moves from amber to ember, stable or cooling states use slate, and heat color is semantic rather than decorative.
- **Earned_Metal**: Champagne gold reserved for earned outcomes such as leads, trophies, settlements, founders, and ceremony.
- **Product_Promise**: “Cup Season is where amateur golf counts,” including rounds being scored, mattering within a season, and accumulating into a lasting record.
- **Product_Story**: The combined ideas of real golf, season-long competition, crew rivalry, momentum, ceremony, and a durable record.
- **Hierarchy_of_Truth**: Product Vision → Product Principles → Information Architecture → Mechanics → User Interface → Implementation, with lower levels prohibited from silently contradicting higher levels.
- **Platform_Asset_Set**: The approved exports for browser, PWA, iOS, social profile, and social-share contexts.
- **PWA**: The installable Progressive Web App served from cupseason.app.
- **CSS_Pixel**: The device-independent display unit used to specify on-screen logo size.
- **Maskable_Icon**: A PWA icon with an opaque background and all essential identity content inside the central 80 percent safe region so operating systems may apply supported masks.
- **Safe_Region**: The central 80 percent of an icon canvas that must contain every essential identifying feature.
- **Social_Share_Card**: A 1200 by 630 pixel Open Graph or equivalent preview image.
- **Contrast_Ratio**: The relative luminance ratio between a foreground identity element and the intended background.
- **Vector_Geometry**: Resolution-independent paths and shapes whose appearance does not depend on a fixed pixel grid.
- **Production_Master**: The authoritative editable Vector_Geometry from which approved variants and raster exports are generated.
- **SVG**: Scalable Vector Graphics, the vector export format for supported digital contexts.
- **PNG**: Portable Network Graphics, the raster export format for required fixed-size contexts.
- **Optical_Center**: The visually balanced position of a mark, which may differ from the mathematical center.
- **Color_Vision_Simulation**: A preview of the identity under protanopia, deuteranopia, tritanopia, and grayscale viewing conditions.
- **Clear_Space**: The minimum empty area around a Core_Mark, Wordmark, or Lockup.
- **Motion_Sequence**: The one-shot animated expression of the Core_Mark used in approved in-app contexts.
- **Qualifying_Entry_Event**: An app-entry context explicitly approved to show identity motion, such as a cold launch or onboarding entrance.
- **Reduced_Motion_Fallback**: The settled static identity shown without spatial movement when reduced motion is requested.
- **Legacy_Mark**: The existing flag-in-cup symbol with the four-color orbit and IBM Plex Mono uppercase wordmark.
- **Migration_Map**: The inventory that maps every existing logo asset and consumer context to a replacement or documented compatibility treatment.
- **Cliche_Cue_Set**: Swinging golfer silhouettes, crossed clubs, generic flag clip art, heraldic crests, “EST.” dates, Roman numerals, argyle, cartoon gophers, and generic technology swooshes.
- **Betting_Cue_Set**: Odds boards, betting chips, playing cards, dice, roulette forms, currency as the hero, flashing red and green urgency, and casino-neon treatments.
- **Target_Panel**: Twelve representative users comprising at least four league-running Pros and eight competitive recreational golfers.
- **Recognition_Test**: A blinded evaluation in which a participant sees a mark without the Wordmark for five seconds and later identifies the mark from a grid containing at least eight category-adjacent marks.
- **Association_Test**: A blinded evaluation in which a participant selects up to three concepts from a balanced list after viewing a mark without brand copy.
- **Hat_Test**: The canon evaluation asking whether a participant would proudly wear the Core_Mark without prior product knowledge.
- **Archive_Test**: The canon evaluation asking whether the identity would look appropriate in a printed Cup Season season book in 2046.
- **Evaluation_Matrix**: The recorded pass-or-fail evidence for every objective logo-system acceptance gate.

## Requirements
### Requirement 1: Preserve Brand Authority and Meaning

**User Story:** As a brand owner, I want the logo system grounded in the current hierarchy of truth, so that the identity expresses the product without reviving superseded brand decisions.

#### Acceptance Criteria

1. THE Logo_System SHALL map real golf, season-long competition, crew rivalry, momentum, ceremony, and durable record to named visible identity elements or documented composition behaviors.
2. THE Logo_System SHALL express the Product_Promise through the mapped Product_Story elements.
3. THE Logo_System SHALL conform to the Product Vision and Product Principles before applying user-interface-level brand choices.
4. THE Logo_System SHALL apply only the color values and semantic roles documented by D76_Identity as the controlling color and momentum direction.
5. THE Logo_System SHALL reserve amber-to-ember heat for live momentum and action and Earned_Metal for earned outcomes, founders, and ceremony.
6. IF a candidate swaps, merges, or decoratively reassigns the semantic roles of ember heat and Earned_Metal, THEN THE Logo_System SHALL exclude the candidate from approval.
7. IF a candidate conflicts with a higher level in the Hierarchy_of_Truth, THEN THE Logo_System SHALL record the conflicting statements, governing source, exclusion or proposed resolution, decision owner, and resolution status before further evaluation.
8. IF an earlier green-led or gold-forward brand statement conflicts with D76_Identity, THEN THE Logo_System SHALL apply D76_Identity and document the superseded statement in the acceptance evidence.

### Requirement 2: Create a Distinctive Core Mark

**User Story:** As a golfer, I want an ownable Cup Season symbol, so that I recognize the product before reading the name.

#### Acceptance Criteria

1. THE Core_Mark SHALL combine a real-golf cue, a season-long competition cue, and an ember-momentum cue in one coherent silhouette.
2. WHEN evaluated without the Wordmark or brand copy by the Association_Test, THE Core_Mark SHALL meet the golf, season-or-competition, and ember-or-momentum thresholds in Requirement 12.
3. WHEN evaluated at 32 by 32 pixels without the Wordmark or brand copy by the Recognition_Test, THE Core_Mark SHALL meet the unaided recognition threshold in Requirement 12.
4. THE Core_Mark SHALL use an outer silhouette distinguishable from each item in the Cliche_Cue_Set.
5. THE Core_Mark SHALL designate one primary outer silhouette and the internal details required for identification in every approved variant.
6. WHEN rendered in one color without gradients, shadows, animation, or transparency, THE Core_Mark SHALL preserve the designated outer silhouette and every required internal detail.
7. WHEN the Core_Mark appears beside the Legacy_Mark and at least eight category-adjacent marks, THE Core_Mark SHALL present a distinct combination of outer silhouette and dominant internal negative space.
8. WHEN the Core_Mark is placed in a circle crop, THE Core_Mark SHALL retain the complete designated outer silhouette and every required internal detail at least 5 percent of the crop diameter inside the crop boundary.

### Requirement 3: Define Wordmark and Lockup Behavior

**User Story:** As a prospective user, I want the product name paired consistently with the symbol, so that I can connect the mark with Cup Season.

#### Acceptance Criteria

1. THE Wordmark SHALL render the exact name “Cup Season” with the documented capitalization and without abbreviation or added wording.
2. THE Logo_System SHALL use a Wordmark in a Lockup only after the Wordmark satisfies the exact-name criterion.
3. THE Wordmark SHALL preserve the existing serif role for story, mono role for records, and sans role for interface utility without introducing a fourth product-interface type family.
4. THE horizontal Lockup SHALL place the Core_Mark to the left of the Wordmark, vertically center both elements, and separate both elements by 25 percent of Core_Mark width.
5. THE stacked Lockup SHALL place the Core_Mark above the horizontally centered Wordmark and separate both elements by 20 percent of Core_Mark width.
6. THE Logo_System SHALL preserve Clear_Space on every side of the Core_Mark, Wordmark, and each Lockup equal to at least 25 percent of Core_Mark width.
7. THE Logo_System SHALL set minimum widths of 96 CSS pixels or 25 millimeters for the Wordmark, 128 CSS pixels or 34 millimeters for the horizontal Lockup, and 80 CSS pixels or 21 millimeters for the stacked Lockup.
8. WHEN available width is below a Lockup minimum and at least 32 CSS pixels, THE Logo_System SHALL use the Core_Mark.
9. WHEN available width is from 16 through 31 CSS pixels, THE Logo_System SHALL use the Small_Size_Mark.
10. WHEN available width is below 16 CSS pixels, THE Logo_System SHALL omit the graphic mark and preserve the accessible product name in surrounding content.
11. WHERE a ceremonial surface is used, THE Lockup SHALL preserve the serif story role and mono record role assigned by the brand canon.
### Requirement 4: Support Color, Theme, and Monochrome Variants

**User Story:** As a product designer, I want approved variants for every brand surface, so that the identity remains consistent without ad hoc recoloring.

#### Acceptance Criteria

1. THE Logo_System SHALL use only the charcoal, paper, amber, ember, slate, and champagne-gold values explicitly documented by D76 for identity artwork.
2. THE Logo_System SHALL provide a flat full-color dark-surface variant without gradients, shadows, texture, or transparency-dependent identity details.
3. THE Logo_System SHALL provide a flat full-color light-surface variant without gradients, shadows, texture, or transparency-dependent identity details.
4. THE Logo_System SHALL provide one-color dark and one-color light or reversed variants.
5. THE Logo_System SHALL provide a monochrome variant that preserves the designated outer silhouette and required internal details in single-ink print, engraving, stamping, and single-thread embroidery tests.
6. WHERE live momentum is represented, THE Logo_System SHALL apply the documented D76 amber-to-ember values according to Heat_Grammar.
7. THE Logo_System SHALL exclude Earned_Metal from routine interface chrome.
8. WHERE earned honor is represented, THE Logo_System SHALL apply Earned_Metal according to D76_Identity.
9. IF an approved full-color variant cannot meet the applicable contrast criterion on a target background, THEN THE Logo_System SHALL use a documented one-color variant or exclude the background pairing.
10. IF a reproduction process cannot preserve an approved color relationship, THEN THE Logo_System SHALL use a documented one-color variant rather than create an ad hoc recoloring.

### Requirement 5: Preserve Recognition at Small Sizes

**User Story:** As a returning user, I want to recognize Cup Season in a browser tab and on a home screen, so that I can find the app at a glance.

#### Acceptance Criteria

1. WHEN rendered at each integer size from 16 through 32 CSS pixels at device-pixel ratio 1, THE Small_Size_Mark SHALL preserve the designated outer silhouette and at least one required Cup Season-specific internal detail.
2. WHEN rendered at each integer size from 16 through 32 CSS pixels at device-pixel ratio 1, THE Small_Size_Mark SHALL contain no required stroke or gap narrower than one device pixel.
3. WHEN rendered at each integer size from 16 through 32 CSS pixels at device-pixel ratio 1, THE Small_Size_Mark SHALL place the measured visual bounds within one device pixel of the documented Optical_Center on each axis.
4. WHEN rendered at 180, 192, 400, 512, or 1024 pixels square, THE Core_Mark SHALL place the measured visual bounds within one device pixel of the documented Optical_Center on each axis.
5. THE Small_Size_Mark SHALL pass the silhouette, internal-detail, stroke, gap, and Optical_Center criteria for every approved full-color and one-color variant.
6. WHEN evaluated by the Recognition_Test at 16 and 32 pixels, THE Small_Size_Mark SHALL achieve correct re-identification by at least 9 members of the Target_Panel at each size.
7. WHEN the primary Core_Mark satisfies every 16-through-32-pixel criterion, THE Logo_System SHALL use the primary Core_Mark without optical simplification.
8. IF the primary Core_Mark cannot satisfy any 16-through-32-pixel criterion, THEN THE Logo_System SHALL approve an optical simplification only after the optical simplification passes every criterion in this requirement.

### Requirement 6: Cover Browser, PWA, iOS, and Social Contexts

**User Story:** As a release owner, I want a complete platform asset family, so that Cup Season presents one identity everywhere the product appears.

#### Acceptance Criteria

1. THE Platform_Asset_Set SHALL include favicon PNG exports at exactly 16, 32, 48, and 96 pixels square and a favicon container containing the 16, 32, and 48 pixel exports.
2. THE Platform_Asset_Set SHALL include PWA PNG icons at exactly 192 and 512 pixels square.
3. THE Platform_Asset_Set SHALL include a Maskable_Icon PNG at exactly 512 pixels square.
4. THE Platform_Asset_Set SHALL include an Apple touch icon PNG at exactly 180 pixels square and an iOS App Icon PNG master at exactly 1024 pixels square.
5. THE Platform_Asset_Set SHALL include a social-profile avatar PNG master at exactly 400 pixels square.
6. THE Platform_Asset_Set SHALL include a Social_Share_Card at exactly 1200 by 630 pixels using an approved Lockup and D76_Identity.
7. THE Maskable_Icon SHALL place the designated outer silhouette and every required internal detail inside the Safe_Region.
8. WHEN previewed with circle, square, rounded-square, and squircle masks, THE Maskable_Icon SHALL retain the complete designated outer silhouette and every required internal detail.
9. WHEN previewed in circle and rounded-square crops, THE social-profile avatar SHALL retain the complete designated outer silhouette and every required internal detail inside the crop boundary.
10. THE Maskable_Icon, Apple touch icon, and iOS App Icon SHALL use an opaque background extending to every canvas edge.
11. THE iOS App Icon master SHALL omit pre-applied corner rounding.
12. WHEN a platform context prohibits text or renders the Wordmark below the documented minimum, THE Platform_Asset_Set SHALL use the Core_Mark or Small_Size_Mark according to Requirement 3.
### Requirement 7: Meet Accessibility and Contrast Needs

**User Story:** As a user with low vision or color-vision differences, I want the identity to remain perceivable without color-dependent interpretation, so that I can recognize Cup Season across themes.

#### Acceptance Criteria

1. THE Evaluation_Matrix SHALL record the calculated Contrast_Ratio between every identity color that touches an approved background and that background for every approved pairing.
2. THE Core_Mark SHALL achieve a boundary Contrast_Ratio of at least 3 to 1 against every approved background at 24 pixels and larger.
3. THE Small_Size_Mark SHALL achieve a boundary Contrast_Ratio of at least 4.5 to 1 against every approved background from 16 through 23 pixels.
4. THE Wordmark SHALL achieve a Contrast_Ratio of at least 4.5 to 1 against every approved background at the documented minimum size.
5. THE Logo_System SHALL distinguish live heat, stable slate, and Earned_Metal through shape, position, pattern, or text in addition to color.
6. WHEN simulated under protanopia, deuteranopia, tritanopia, and grayscale conditions, THE Core_Mark and every approved color variant SHALL preserve the designated outer silhouette, required internal details, and non-color state distinctions.
7. WHEN a standalone brand image communicates the product identity or meaning, THE Logo_System SHALL provide an accessible name that communicates the same identity or meaning.
8. WHEN a brand image duplicates adjacent accessible content and communicates no additional meaning, THE Logo_System SHALL designate the image as decorative.
9. IF a Motion_Sequence conveys state, progress, or meaning, THEN THE Logo_System SHALL expose the same state, progress, or meaning through persistent non-motion content.
10. WHEN reduced motion is requested, THE Reduced_Motion_Fallback SHALL preserve the same identity, meaning, accessible name, and non-color distinctions as the Motion_Sequence.

### Requirement 8: Supply Production-Ready Vector Geometry

**User Story:** As a production designer, I want clean vector masters and reproducible exports, so that the logo works in software, print, engraving, stamping, and embroidery.

#### Acceptance Criteria

1. THE Production_Master SHALL define the Core_Mark, Wordmark, Lockups, Small_Size_Mark, and approved color variants as Vector_Geometry.
2. THE Production_Master SHALL label the primary outer silhouette and every internal detail required for identification.
3. THE Production_Master SHALL specify numeric artboard dimensions, SVG view-box coordinates, geometry bounding boxes, and Optical_Center coordinates for each master composition.
4. THE Production_Master SHALL contain zero embedded or linked raster images.
5. THE Production_Master SHALL convert all production-export lettering to outlined Vector_Geometry and contain zero runtime font dependencies.
6. THE Production_Master SHALL use closed contours for every filled, engraved, stamped, or embroidered shape.
7. THE Production_Master SHALL contain zero self-intersecting paths and zero unintended open paths.
8. THE Logo_System SHALL set minimum required stroke widths, gaps, and isolated details to 1 device pixel for screen output, 0.25 millimeters for print, 0.30 millimeters for engraving, and 1.0 millimeter for embroidery.
9. WHEN reproduced at two inches wide in three thread colors, THE Core_Mark SHALL preserve the primary outer silhouette and every required internal detail at or above the embroidery limits.
10. WHEN engraved at 20 millimeters wide in one color, THE Core_Mark SHALL preserve the primary outer silhouette and every required internal detail at or above the engraving limits.
11. WHEN exported to SVG, THE Platform_Asset_Set SHALL match the approved master view box, path geometry, D76 color values, and transparency rules.
12. WHEN exported to PNG, THE Platform_Asset_Set SHALL match the required pixel dimensions, approved master geometry bounds, Optical_Center coordinates, D76 color values, color space, and transparency rules.
13. THE Evaluation_Matrix SHALL record pass-or-fail results for path closure, path intersection, raster dependency, font dependency, dimensions, geometry bounds, Optical_Center, color values, color space, and alpha behavior for every production export.

### Requirement 9: Define Motion and Reduced-Motion Behavior

**User Story:** As an app user, I want the logo to feel like momentum heating up and settling, so that motion reinforces the Cup Season identity without delaying access.

#### Acceptance Criteria

1. THE Motion_Sequence SHALL transform from a quiet or warm initial state into the settled Core_Mark.
2. THE Motion_Sequence SHALL use the documented roll-out easing character with every animated value remaining within the range bounded by the initial and final values.
3. THE Motion_Sequence SHALL settle within 1,200 milliseconds of playback start.
4. WHEN the Motion_Sequence settles, THE Motion_Sequence SHALL match the approved static Core_Mark geometry, Optical_Center, and final D76 color values.
5. THE Motion_Sequence SHALL use ember heat to communicate ignition or momentum rather than continuous decoration.
6. THE Motion_Sequence SHALL start only in response to a Qualifying_Entry_Event.
7. WHEN a Qualifying_Entry_Event occurs, THE Motion_Sequence SHALL run no more than once for that event.
8. WHILE the Motion_Sequence is running, THE Logo_System SHALL keep navigation, controls, and primary content operable.
9. WHEN reduced motion is detected before playback, THE Logo_System SHALL display the Reduced_Motion_Fallback without starting spatial movement.
10. WHEN reduced motion is detected during playback, THE Logo_System SHALL replace spatial movement with the Reduced_Motion_Fallback within 100 milliseconds.
11. THE Reduced_Motion_Fallback SHALL present the same final identity, meaning, and information as the Motion_Sequence.
12. IF animation playback fails or is unsupported while reduced motion is not requested, THEN THE Logo_System SHALL display the settled Core_Mark within 100 milliseconds of detecting the failure.
13. WHILE reduced motion is requested, IF animation playback fails or is unsupported, THE Logo_System SHALL display the Reduced_Motion_Fallback within 100 milliseconds of detecting the failure.
### Requirement 10: Avoid Generic Golf and Betting Signals

**User Story:** As a brand owner, I want the identity to look like Cup Season rather than a generic golf club or sportsbook, so that the product occupies an ownable and trustworthy category position.

#### Acceptance Criteria

1. THE Core_Mark SHALL derive golf meaning from a Cup Season-specific composition that combines golf with season progression, crew rivalry, or momentum.
2. THE Core_Mark SHALL exclude an isolated or standalone item from the Cliche_Cue_Set as the dominant identifying feature.
3. THE Logo_System SHALL communicate competition through season progression, crew relationship, rivalry, or earned ceremony rather than through the Betting_Cue_Set.
4. THE Logo_System SHALL exclude every item in the Betting_Cue_Set from approved identity compositions.
5. THE Logo_System SHALL present money-related ceremony only through Earned_Metal and established ledger language.
6. WHEN evaluated by the Association_Test, THE Core_Mark SHALL meet the combined golf-plus-season-or-rivalry-or-momentum, open-or-muni character, betting, and gated-club thresholds in Requirement 12.
7. WHEN evaluated by the Archive_Test, THE Logo_System SHALL meet the archive-durability threshold in Requirement 12.
8. WHEN compared with the Legacy_Mark and at least eight category-adjacent marks, THE Core_Mark SHALL satisfy the distinct silhouette and internal negative-space criterion in Requirement 2.

### Requirement 11: Preserve Backward Compatibility During Migration

**User Story:** As a release owner, I want a controlled migration from the legacy assets, so that users see a deliberate identity change without broken icons, stale references, or missing brand surfaces.

#### Acceptance Criteria

1. THE Migration_Map SHALL inventory every Legacy_Mark asset and every browser, PWA, iOS, email, press, social, share, and in-product consumer context.
2. THE Migration_Map SHALL assign each inventoried asset and consumer exactly one treatment: approved replacement, compatibility alias, retirement action, or owner-approved exception.
3. THE Migration_Map SHALL document the expected replacement event, cache lifetime or refresh trigger, and validation method for browser cache, service-worker cache, installed PWA icons, Apple touch icons, and iOS App Icons.
4. WHEN the Logo_System is released, THE Platform_Asset_Set SHALL preserve each existing public asset path until every consumer reference using the path has migrated or the path serves a compatibility alias.
5. WHEN an active product surface loads identity assets, THE Logo_System SHALL display either the complete Legacy_Mark treatment or the complete D76_Identity treatment and prevent a mixed legacy/D76 presentation.
6. IF a platform continues to cache a Legacy_Mark after the documented replacement event, THEN THE Migration_Map SHALL apply the documented versioning, invalidation, reinstall, or refresh treatment for that platform.
7. THE Migration_Map SHALL preserve a recoverable archive containing every Legacy_Mark production asset, source path, checksum, retirement date, and replacement rationale.
8. THE Migration_Map SHALL distinguish identity-only changes from product mechanics, information architecture, and implementation behavior.
9. IF any inventory, public-path, cache, mixed-surface, archive, or replacement validation fails, THEN THE Logo_System SHALL withhold migration approval until remediation passes the failed validation.
10. WHEN production asset or code replacement is planned, THE Logo_System SHALL require a separate implementation phase before replacement occurs.
### Requirement 12: Pass Objective Evaluation Gates

**User Story:** As a product owner, I want evidence-based selection criteria, so that the final mark is chosen for recognition, meaning, durability, and production performance rather than personal taste alone.

#### Acceptance Criteria

1. THE Logo_System SHALL evaluate from three through five new candidate territories and exactly one Legacy_Mark evolution control.
2. THE Logo_System SHALL evaluate every candidate and the Legacy_Mark evolution control with the same Target_Panel, exposure time, display sizes, comparison grid, prompt wording, response options, and scoring rules.
3. THE Evaluation_Matrix SHALL record the tested candidate, test date, evaluator composition, test method, measured result, threshold, pass range, fail range, and pass-or-fail outcome for every gate.
4. WHEN evaluated by the Recognition_Test at 32 pixels, THE selected Core_Mark SHALL pass with 10 through 12 correct re-identifications and fail with 0 through 9 correct re-identifications from the Target_Panel.
5. WHEN evaluated by the Association_Test, THE selected Core_Mark SHALL pass the golf gate with 9 through 12 golf selections and fail the golf gate with 0 through 8 golf selections from the Target_Panel.
6. WHEN evaluated by the Association_Test, THE selected Core_Mark SHALL pass the season-and-momentum gate with at least 8 season, competition, progression, or rivalry selections, at least 8 heat, ember, energy, or momentum selections, and at least 8 participants selecting golf plus one concept from either group; THE selected Core_Mark SHALL fail the gate when any count is below 8.
7. WHEN evaluated by the Association_Test, THE selected Core_Mark SHALL pass the category-position gate with at least 8 open, public, or muni selections, no more than 1 betting, casino, or sportsbook selection, and no more than 2 country-club or gated-club selections; THE selected Core_Mark SHALL fail the gate when any count falls outside the stated range.
8. WHEN evaluated by the Hat_Test, THE selected Core_Mark SHALL pass with 9 through 12 affirmative responses and fail with 0 through 8 affirmative responses from the Target_Panel.
9. WHEN evaluated by the Archive_Test, THE selected Logo_System SHALL pass with 10 through 12 affirmative responses and fail with 0 through 9 affirmative responses from the Target_Panel.
10. THE selected Logo_System SHALL pass every color, small-size, platform-mask, contrast, color-vision, monochrome, vector-integrity, reproduction, and export criterion in Requirements 4 through 8.
11. THE selected Logo_System SHALL pass every Motion_Sequence and Reduced_Motion_Fallback criterion in Requirement 9.
12. IF a candidate fails a gate, THEN THE Evaluation_Matrix SHALL mark the candidate as not approved or record an owner exception containing the failed gate, named decision owner, decision date, rationale, scope, and required remediation.
13. IF an owner exception omits any required exception field, THEN THE Evaluation_Matrix SHALL retain the candidate status as not approved.

### Requirement 13: Deliver Usage Guidance and Acceptance Evidence

**User Story:** As a future designer or developer, I want one authoritative logo-system package, so that later assets remain consistent with the approved identity.

#### Acceptance Criteria

1. THE Logo_System SHALL document every approved Core_Mark, Small_Size_Mark, Wordmark, horizontal Lockup, stacked Lockup, color variant, and motion composition.
2. THE Logo_System SHALL document a deterministic selection rule based on available width, background, platform text support, motion preference, reproduction process, and semantic use for every approved composition.
3. THE Logo_System SHALL specify the file name, composition, dimensions, file format, color space, D76 color values, transparency rule, crop rule, and intended consumer for every production export.
4. THE Logo_System SHALL map each visible feature and composition behavior to real golf, season-long competition, crew rivalry, ember momentum, ceremony, or durable record meaning.
5. THE Logo_System SHALL document how Heat_Grammar and Earned_Metal apply to every approved static and animated identity variant.
6. THE Logo_System SHALL include labeled contact-sheet previews naming the composition, variant, size, background, crop, and production context for charcoal, light paper, monochrome, favicon, PWA, maskable, Apple, iOS, social-profile, Social_Share_Card, engraving, and embroidery contexts.
7. THE Logo_System SHALL include the completed Evaluation_Matrix, Migration_Map, export-validation results, accessibility evidence, production-test evidence, and motion-test evidence in the acceptance package.
8. IF a derivative asset violates a documented composition, color, sizing, spacing, crop, accessibility, motion, or production rule, THEN THE Logo_System SHALL reject the derivative and identify the conforming replacement or required remediation.
9. WHEN a rejected derivative is remediated, THE Logo_System SHALL require the derivative to pass every applicable acceptance criterion before approval.

## Out of Scope for This Phase

- Selecting or drawing the final logo artwork.
- Modifying `index.html`, manifests, service-worker behavior, iOS wrapper files, production icons, social images, or existing `brand/` assets.
- Changing Cup Season competition mechanics, product information architecture, product copy, or the D76 theme.
- Deploying, cache-busting, or migrating production assets.