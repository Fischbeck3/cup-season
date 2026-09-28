# Assessment B — selected Cup Season repairs

Isolated detector/browser assessment by `/root/selected_critique_b`. Assessment A and prior critiques were not read. This is an evidence handoff to the parent synthesis, not a heuristic score.

## Target fingerprints

| Target | Baseline | SHA-256 |
|---|---|---|
| door · S1A_WORKTREE/index.html#door | `5fabf861c4bee83e2492769f8e76ab3f9cda8281` | `32f458977a5aa5fab74346433c605c3e923204cdfb5ee0664139d66604be7c30` |
| home · S1B_WORKTREE/index.html#view-home | `5fabf861c4bee83e2492769f8e76ab3f9cda8281` | `2c7d9388991af0ccc48e8167fb21071b8171712ac507cdd254001edf3802db0a` |
| native Door · S1A_WORKTREE/apps/ios/CupSeason/Door/DoorView.swift | `5fabf861c4bee83e2492769f8e76ab3f9cda8281` | `b11b905d9e2a92d58c7a838d85c8f090a2a2ae87d4e2674f3ac7dac6719a85e7` |

Web source hashes match the capture provenance. Branches: `codex/ten-door-label-2026-09-28` and `codex/ten-home-contrast-2026-09-28`. Both are parent-owned review targets; this pass did not pull, edit, build, or switch them.

## Deterministic scan

Exactly one `impeccable detect --json index.html` run in each changed web worktree. Each exited 2 with **205 records: 202 warnings and 3 advisories** (171 quality, 34 style). Combined raw total: 410; the normalized rule/snippet sets are identical across the two files.

| Rule | Door | Home |
|---|---:|---:|
| side-tab | 19 | 19 |
| low-contrast | 125 | 125 |
| dark-glow | 11 | 11 |
| broken-image | 1 | 1 |
| all-caps-body | 17 | 17 |
| wide-tracking | 8 | 8 |
| cramped-padding | 1 | 1 |
| undersized-ui-text | 8 | 8 |
| tiny-text | 10 | 10 |
| gpt-thin-border-wide-shadow | 2 | 2 |
| skipped-heading | 1 | 1 |
| pulsing-dot | 1 | 1 |
| em-dash-overuse | 1 | 1 |

Every record names its changed `index.html` but reports **line 0**, so source line attribution is unavailable. These are full-SPA counts, including other screens and dynamic templates; they are not 205 proven defects in either target. Exact source locations below come from independent tracing. Raw CLI files remain local in `/private/tmp/cup-ten-selected-b-{door,home}-cli.json`; no detector rerun is needed.

## What the selected repairs prove

### B-fix-door

Persistent Email label is linked with for=obEmailIn. The two-column grid puts the label across both columns while retaining email keyboard/autocomplete metadata.

- Live AX tree reports text field EMAIL.
- Clicking label focused obEmailIn; native labels list contains Email.
- Live 1280x720: input 261.92x46, Go 62.83x46, label 11px and opaque mut.
- 375px initial-entry and re-entry captures in both themes show the persistent label without clipping.
- 375x380 re-entry short-viewport capture keeps Go at y331.27..377.27; this is a viewport proxy, not real iPhone keyboard evidence.

Contrast ratios: `{"label_dark": 7.07, "label_light": 5.851}`.

Source: S1A_WORKTREE/index.html:3069, S1A_WORKTREE/index.html:3070, S1A_WORKTREE/index.html:4398.

### B-fix-home

Occasion ground now uses bg1; normal and earned actions use act. Heading/body ink pairs clear AA and earned action remains ordinary-action green.

- Source delta changes only occasion background and action color roles.
- Visually inspected dark/light Home and earned light captures at 375 and 1280.
- Capture source hashes match current HTML.
- Independent token contrast calculation matches stored computed-style ratios.
- The 375 full-page capture has the fixed tab bar across part of the occasion; the 1280 captures visibly expose the whole text and action. A still alone does not prove mobile reachability.

Contrast ratios: `{"dark": {"heading": 14.103, "body": 6.211, "action": 5.136}, "light": {"heading": 14.021, "body": 5.296, "action": 6.272}, "earned_light_action": 6.272}`.

Source: S1B_WORKTREE/index.html:2319, S1B_WORKTREE/index.html:2327, S1B_WORKTREE/index.html:2328.

## Native Door fallback

The native counterpart is fixed for the targeted simulator matrix: an explicit accessibilityLabel("Email") now supplies the field name that the baseline runtime lacked. The existing visible label remains.

No Swift detector run; native semantic test, source, and capture evidence are the supported fallback. The web detector was not rerun.

- Source diff is one accessibilityLabel("Email") line after CSField, preserving keyboard/content type, submit behavior, and visible copy.
- Eight final observations (SE3 and17Pro, light/dark, large/default andAX3) report Email before typing and after fixture@example.com is entered; visibleEmailLabel is true in all8.
- Four actual final XCTest executions each pass1 test with0 failures; each execution covers both themes. Only DoorAfter-* bundles are counted.
- All eight final screenshot hashes and their source fingerprints were independently matched by B. The contact sheet visually shows the intended email stage with keyboard visible and action exposed at both text sizes.
- The final source fingerprint matches the parent-owned DoorView file: b11b905d9e2a92d58c7a838d85c8f090a2a2ae87d4e2674f3ac7dac6719a85e7.

Evidence: LOCAL_GALLERY/native-approved-verification/REPORT.md, LOCAL_GALLERY/native-approved-verification/manifest-after.json, LOCAL_GALLERY/native-approved-verification/ax-observations-after.json, LOCAL_GALLERY/native-approved-verification/ui-test-summary-after.json, LOCAL_GALLERY/native-approved-verification/door-after-contact.jpg.

Native evidence limitation: Tests and captures were produced by the independent native-verification agent on task-created simulators, then reviewed by B. This is not a physical-device or human VoiceOver session and does not establish full native-suite success. Native Home rendered occasion evidence remains not captured/not scored.

## Existing residual issues, separate from the approved delta

- **[P2] Back remains a small dim text control.** Live unhovered Back measures 28.75x15 CSS px and rgb(94,106,98). Token contrast on page is 3.15:1 dark and 2.89:1 light; default source has no 44px minimum target. Existing initial/re-entry captures show the same small control. Misses project 44px target and small-text AA contrast requirements for returning to the chooser. Later scoped repair: give Back a 44px hit area and opaque mut text while retaining quiet treatment. Source: S1A_WORKTREE/index.html:3145, S1A_WORKTREE/index.html:28686.
- **[P2] Occasion Dismiss remains a 24px low-contrast icon control.** Source sets width/height24px and dim ink. Current bg1 gives 2.77:1 dark and 2.61:1 light. Dismiss is visible in fixture captures and has an accessible label in source. Below project 44px target and 3:1 non-text control contrast. Later scoped repair: enlarge transparent hit area to 44px and use a readable existing ink role. Source: S1B_WORKTREE/index.html:2331, S1B_WORKTREE/index.html:17255.
- **[P2] Empty-state helper sentences still use dim.** The visible No rounds from your buddies yet and Add a round helper sentences use .fine at 13px and dim on bg0: 3.15:1 dark and 2.89:1 light. Present in captured fixture in both themes. Secondary copy remains below 4.5:1 and current canon assigns readable secondary text to opaque mut. Later scoped repair: use mut for these Home helper sentences. Source: S1B_WORKTREE/index.html:1322, S1B_WORKTREE/index.html:16816, S1B_WORKTREE/index.html:18228.

No new defect is proven in the approved web delta. This is not a full release, physical-device, or usability sign-off.

## False positives, unresolved records, and canon

- The CLI scans the whole SPA twice. Equal 205 counts do not establish a shared target regression. No precise raw finding can be assigned to a selector because all report line0.
- The scan includes inferred black/white text/background pairs. The measured Door label and Home occasion pairs are explicitly different and pass; a black-text or white-background report is not proof against these elements. No blanket contrast suppression applied.
- Meaningful short record labels are intentional. The new Email label is11px, a labeled field name, and uses mut. Do not reclassify it as body prose or require a new typography system. Existing10px functional labels elsewhere remain assessable; they are not waived.
- Raw entries refer to full-file content or other route/template structures; no proven target-local instance established in this bounded pass.
- Custom five-destination navigation is approved; no replacement by generic native/browser navigation proposed.
- Board, story, record and functional typography roles remain approved; only meaningful record labels receive label-context judgment.
- Dark-first and warm-paper light are required, not detector defects.
- Production CS pennant remains unchanged.
- Competition/earned semantic spines remain distinct; ordinary controls use act. This is a scoped reading of known elements, not a blanket side-tab or color-rule suppression.
- No global detector suppressions were added or used.

The report does not claim exact false-positive counts. Without useful detector locations, unresolved raw entries remain unresolved. It does not silently suppress full rule families.

## Browser and cleanup notes

- Fresh Door tab: opened the email branch without typing or submitting data, inspected AX/DOM/screenshot, clicked the native label, and confirmed focus. Fresh Home tab: the sign-in Door still gated the route, so Home used the no-account fixture captures.
- Mutable injection is unavailable under the documented read-only evaluate API. No mutation was attempted, no detector overlay was injected, no browser detector console results are claimed, and no `[Human]` overlay tab exists.
- The Door hidden-tab request was accepted; the Home hidden request reported unsupported visibility in a subagent. Opening Home without the override succeeded. No visibility set/get result is claimed.
- No Impeccable live server was started. Both assessment-created tabs were closed. No viewport override was set. Parent static servers were left running.
- The six requested captures and additional initial-entry/desktop confirmation captures were visually inspected. Source fingerprints and screenshot hashes are in the JSON. Initial-entry and re-entry Door captures are distinguished. The short web capture is a viewport proxy, not a native keyboard test.
- Context ran once. The separate target worktree reported missing PRODUCT/DESIGN, so the parent-supplied current canonical compilation was read. Ignore lists were absent. No prior critique report was read.
- Final JSON/Markdown and two raw CLI JSON files are deliberately retained locally. Intermediate assembly scripts/data were removed. No source or account data was changed by Assessment B.

Questions skipped: Assessment B is the isolated evidence pass; the parent owns the combined critique and next-step question.
