# Owner questions · the decision memo for the "10/10" launch

| | |
|---|---|
| **Measured at** | the round-1 evidence: web `9d84c483` (captures at `02636007` and `9d84c483`) and native `4112a3f0`. Source and canon were read at `de3eaf35`, and the web's current behaviour at `4a703402` wherever a lane changed it. |
| **Status read at** | **`144ee0b0`** on integration: every lane (W1–W6), root's fixes through `7141516f`, and E's native phase 1 (`6716b0ed`). The web shipped as `272c2da1`. |
| **Date** | 2026-09-28 |
| **Assessors** | The owner rules; this memo, by session C (docs), only recommends. The evidence behind it: the panel's **category**, **craft** and **owner** judges, critiques **A** and **B**, audit **AW** and detector **DX**, plus the questions lanes W2–W5, session B and N2 forwarded through root. Four read-only research passes gathered the canon; none of them scored anything. |
| **Raw evidence (outside git)** | `~/cup-season-claude-ten-gallery/evidence/` (`panel/`, `critique-A/`, `critique-B/`, `audit-web/`, `detector/`, `SESSIONS.md` §C) and root's messages of 2026-09-28 |

**How to read it.** Each question gives:
- the question in one line;
- the evidence and the canon each option rests on;
- the options, with what each changes on the web and on the phone;
- a recommendation and its reason;
- what stays blocked until it is answered.

Settled items are recorded as settled, with the commit that settled them. A defect that canon already rules is recorded as a defect, so nobody waits on a ruling it does not need.

**Privacy.** The repo is public. This memo names no real person, handle, city or course. Where the product prints the owner's identity, it says "the owner's first name", "@handle", "city" or "home course" and gives line numbers.

**What this program may not do by itself.** PRODUCT.md: "No dependency, brand replacement, mechanics or data changes are authorized by this program." An option that needs a migration, a mechanic change or a brand change therefore needs:
- the owner's separate yes;
- a decision-log entry written before it is built (CLAUDE.md rule 5);
- for a migration, the owner's `supabase db push`, which is always a separate deploy from the client's `git push`.

## 0 · Decide today: this one takes effect on Oct 1

### Q31 · The phone's default look on launch day (DEC-N4-2): Fall from Oct 1, or Fescue?
**Why it is urgent.** The phone's look dial defaults to the calendar, and the calendar's Fall window opens on Oct 1. On launch day every new golfer's ordinary actions take Fall's accent. Session A measured it at ΔE76 16 from ember in the light theme, close enough that the ordinary action reads as the competition signal. Two Teams paints its panels near `neg`.

**The question.** Launch with the dial defaulting to Fescue (homebase) until Fall and Two Teams are re-cut, or accept the looks as they are?

**What the source says.**
- `PersonalLook.default` is `.calendar` (`CupSeasonKit/Looks/LookResolver.swift`, D103a, IOS-025).
- `PersonalLook(rawValue:)` also maps a missing stored value to `.calendar`. **A golfer who never touched the dial gets the calendar through that path**, so the change must reach it, not only `default`.
- `.none` is "Fescue only".
- The web has no personal looks. Its "fall" entry is a Home occasion (an invitation to a fall Major), not a palette. This is a phone-only change.

**Canon.**
- D359: a personal look may style the ordinary action (`act`), but "may not repaint the reserved competition signal, earned gold or the semantic colours".
- D313 (the looks).
- BRAND-02 in preflight: a calendar look may take no reserved value. It checks tokens, not perceptual distance, which is how Fall passes it.
- Session A's DEC-N4-2 (`evidence/native/N4-WORKLIST.md` §5), from critique B's season finding.

**Options.**
- **(a) Re-cut Fall's and Two Teams' accents** in `packages/tokens`, regenerate both clients' tokens, and add a perceptual floor to BRAND-02. That is palette work with a generated-Swift change, the day before launch.
- **(b) Default the dial to Fescue for Oct 1:** a missing stored value resolves to `.none`, and `default` follows. A one-line change on the phone, plus a Kit test; golfers who chose a look keep it. Then (a) after launch.
- **(c) Accept the looks as they are.**

**Recommendation: (b), today.**
- It is the smallest change that keeps D359's signal readable on launch day, and it touches no palette.
- It needs a phone build: TestFlight 1324 is being archived from `144ee0b0` without it.
- So the ruling decides whether 1324 is the launch build or whether E makes the change and a new build is archived.

**Blocked until ruled:** N4-105; which build ships on Oct 1.

## Rule these first
These block work in flight or define the gate.
0. **Q31, the phone's default look on launch day** (§0 above).
1. **Q9, how the gate counts ceilings.** Round 2 is scored on the answer.
2. **X38, public privacy.** The one data exposure, and it needs a migration.
   - **X42 (§D)** is round 2's top open item (category P0, owner P1). It needs a migration written and your `db push`.
3. **X37, the owner and the pilot crew in the product.** Real people on a public page and in a public repo.
4. **Q24 and Q25, the wordmark and the button label.** Session B's lockup and CTA grammar have landed everywhere else; the Door and the in-app `.btn` wait on these.
5. **Q1, the recap's double strip.** Lane N4 is on the recap now.
6. **X36, X40, Q7, Q23 and Q5.** Words that must read the same on both clients.
7. **Q2's TERMINOLOGY amendment.** The nine two-squad defects can start without it.

## Summary

| # | The question | Kind | Recommendation | Rule by |
|---|---|---|---|---|
| X36 | Which rivalry record each surface shows, and whether it names what it counts | decision | Every surface names its facet now; rule "faceted, no summed record" against "one summed record" after launch | freeze |
| X37 | The owner and the pilot crew in the demo diorama and placeholders | decision | Recast with the synthetic cast on both clients; the feedback line to the owner's taste; gate the `?cs_home_state` hatch | freeze |
| X38 | What a stranger with a link reads | decision · migration | Person link: the stranger shape (D394) plus "Turn off my card link". Settlement: drop who-pays-whom, plus a disclosure line | before launch |
| X39 | Milestones on a first round | decision | Fold a first round's milestones into FIRST ROUND; the PB rule goes into the X41 migration | freeze |
| X40 | "7.9 vs course" on a personal best | decision | "83 at ‹course› · ‹date›", printed once; the differential stays on the receipt | freeze |
| Q1 | The live recap draws its hole strip twice | decision | Keep the card's strip, with one visible footer line and the chips under it | freeze (N4) |
| Q2 | Two-squad "cut" wording | defect + one canon conflict | The covenant line is not live; fix nine producers; make TERMINOLOGY rows 11, 141 and 142 structure-aware | freeze |
| Q3 | GuideCopy's third wording of the minimum | fixed on both clients (5777f011, 1a0703c8) | — | — |
| Q4 | The Pro's Home is a member's Home | decision | Build D226's ranked Pro item after launch; correct CLAUDE.md's claim now | after launch |
| Q5 | Where the build stamp lives | decision | Hidden on the Door, off the sidebar, kept in Settings | freeze |
| Q6 | A specimen on the phone Door (the desk wings are fixed: labelled, and still since 7141516f) | decision | Keep the phone Door as it is; real permissioned examples later | after launch |
| Q7 | The line that signs the Door and shared artifacts | decision | "Where amateur golf counts", by the vision's own rule | freeze |
| Q8 | One colour for round points | settled (W4, UI_SYSTEM §2.4) | — | — |
| Q9 | How the gate counts content, genre and device-or-human cells | decision | Every defect cell to 9; name each ceiling per cell; report two means | before round 2 |
| Q10 | Home: an upcoming Ryder, the clash holder, the crown | decision | After launch, with Q4's item | after launch |
| Q11 | Season context on a public round | decision | No; rule it with X38 | with X38 |
| Q12 | Structural performance before Oct 1 | decision | Home's single render and the fonts now; code splitting after, as a named exception | freeze |
| Q13 | An already-claimed card | settled (W4, 5d536f41) | The phone's twin (N4) | — |
| Q14 | X18, the install nudge | decision (B25 is fixed, 6c5f251b) | In the page on league-less Home | freeze |
| Q15 | May a lane re-lay a ruled sentence? | decision | Layout yes; one-line D364 amendment; the covenant in three heads | freeze |
| Q16 | Old test bundles with host-wide simulator logs | decision | Delete, after root checks nothing cites them | any time |
| Q17 | Tier the wire into slats (against D360) | decision | Keep D360 now; tier upward as the answer to inbox #22 | after launch |
| Q18 | Band words on a 30-day average | canon allows; two defects beside it | An "on average" gloss | freeze (copy) |
| Q19 | "Around your buddies" with no buddies | decision + canon conflict | "Your rounds" when no buddy round is listed; TERMINOLOGY wins over THE WIRE | freeze |
| Q20 | "2 days left" against "3 days" | defect + decision | Exclude today, on the league's timezone | freeze |
| Q21 | "LAST FIVE" in a count slot | defect (recorded) | The window moves into the label | no ruling needed |
| Q22 | The finished Ryder's MVP | decision | On the board for Oct 1; a stored MVP after | after launch |
| Q23 | "Share the card" | defect + decision | "Share your round"; the web ceremony shares the link too | freeze |
| Q24 | The Door's wordmark (every other surface now wears the one lockup) | decision (brand) | The lockup's name on the Door; the serif kept for the Door's statement | freeze |
| Q25 | The in-app `.btn` label role (get, support and the public shell are done) | defect + canon conflict | `name` 17 at 50px, as the phone does | freeze |
| Q26 | "YOUR MOMENTS" or "MATCHES & WEEKENDS" | decision | YOUR MOMENTS; close the conflict in writing | any time |
| Q27 | The league's name when a Pro resumes setup | decision | Prefill it, editable | freeze |
| Q28 | Wizard presets; the desk's empty Compete | decision | Keep W5's dials; leave empty Compete with its one door | after launch |
| Q29 | At AX3 the Ryder room's side roster scrolls sideways | defect (recorded) | Stack the sides (§16.3), in lane N4 | no ruling needed |
| Q30 | A chasing golfer's lead door | decision | "Add my round", with Q10's and Q4's ranker work | after launch |
| **Q31** | **The phone's default look on Oct 1 (DEC-N4-2)** | **decision, urgent** | **Fescue by default until Fall and Two Teams are re-cut** | **today** |
| Q32 | Toolbar Close at about 42.6pt in partial-detent sheets | decision | Accept as device-or-human with a thumb test, as root has | any time |
| Q33 | The when-fork's "Right now" in ember (DEC-N4-3) | decision | Ink; nothing is live yet | freeze |
| Q34 | Three canon tensions (DEC-N4-5) | decision | Names wrap (1); (2) and (3) are yours | any time |
| Q35 | The Cup Final's one sentence (DEC-01) | decision | "Scored fresh" plus the counting-limit clause | freeze |
| Q36 | Does a live moment keep an ember rail? | decision | Retire it; the dot and eyebrow say live | freeze |
| Q37 | Whose words, when canon names none (DEC-COPY) | decision | The Kit's, where it is the older producer | any time |

"freeze" means before the Sep 30 visual freeze, because the answer changes words or layout on both clients.

## A · The ledger's questions (LEDGER §4f, X36–X40)

### X36 · The rivalry record: which number is "the" record, and where?
**The question.** You and the plan print one record ("3–4 · THEY LEAD", "leads 4–3"), and the person page and the head-to-head print another ("All square between you, 5–5.", "MET 10"). Which record does each surface show, and does each say what it counts?

**Why the numbers differ** (read from the SQL, not run):
- `my_rivalries()` counts **season weeks**, one per calendar week in which both golfers have a ranked round in a season they share. Ryder duels are separate columns (`20260716210000_named_rivalries.sql`). `rivalry_weeks()` and `tour_card.vs_you` count the same way.
- `head_to_head()` returns six facets and makes its `record` **the sum of all of them** (`20260917090000_the_record_between_two_golfers.sql`, "the record is the SUM of the same rows the facets counted"):
  - season weeks (counted per season-week, so not deduplicated across two shared seasons);
  - settled clashes;
  - rounds played together;
  - live games;
  - Ryder duels;
  - callouts.
- So the person page's number is a blend of facets, and even its season facet can count a week twice when two golfers share two seasons. The fixture's viewer shares two leagues with the same rival, which fits the 7-versus-10 gap.

**Where each surface reads.**
- **Web.**
  - You: `renderRivalries` on `my_rivalries`, head "Rivalries · all leagues".
  - The plan: `rivalryTag` on `my_rivalries`, with no facet named, and "clashes" for the duel fallback.
  - The person page: `csH2HHeadline` / `csH2HPersonClause` on `head_to_head`'s sum. W3's `3324ae89` reworded it to "All square between you, 5–5."
  - The head-to-head page: facet rows, no headline figure.
- **Phone.**
  - You: `RivalryLine.from` on `my_rivalries`, printing "‹FIRST› LEADS" where the web prints THEY LEAD. The row opens the **head-to-head page**, whose big figure is the sum, so a "3–4" row opens a page reading "5–5".
  - The plan: `RivalryTag.of`.
  - The person page: `rivalryBlock`, on the sum.
  - Its fallback (`PeopleService.headToHeadFallback`) sums season weeks and duels, but takes the lead from season weeks alone, so it can name a leader its own figures contradict.

**Canon, and where it conflicts.**
- Gameplay-modes 7c #18, bound through D12 ("Rivalry (lifetime record, faceted per 7c #18)"): "One rivalry object per pair, faceted — never a single blended W-L number."
- On the other side, a single headline:
  - IA §10.3/§10.4 and the component spec P-6 (`CSRivalLine`: "the record is always attached to a name and a direction") name `head_to_head` as the one read;
  - TERMINOLOGY row 99 rules the form "You lead 6–5";
  - R-H's quiet-day line reads "He is 6–5 up all-time".
- The IA's own mock has facet rows that add up to 9–6 under a 6–5 headline, so "headline = sum of facets" is how R4 was built, not something the IA says.
- The product vision: "never invent a head-to-head result", and distinguish a direct match from two unrelated rounds.
- "Weekly clash" names two different counts: every week both golfers posted (You's sheet, the widget) and the settled D52/D108 spotlight (the head-to-head facet). A bare "clashes" also means Ryder duels on the plan.

**Options.**
- **(1) Every surface names its facet, and nothing claims to be "the" record.**
  - Copy on both clients: You and the plan say "in the season · 7 weeks"; the rivalry sheet stops calling season weeks "weekly clash"; the person page and head-to-head say "across every meeting".
  - Web: `renderRivalries`, `rivalryTag`, `csH2HHeadline`, `csH2HPersonClause`, the post-round next act.
  - Phone: `RivalryLine`, `RivalryTag`, `HeadToHeadCopy`, `PersonPage.rivalryBlock`, `HeadToHeadPage`, the widget's scope.
  - No database change. It amends TERMINOLOGY row 99 and P-6's copy rule, at UI level.
- **(2) `head_to_head` is THE record everywhere,** as P-6 and the IA are written.
  - You and the plan switch reads, which needs a list-shaped RPC (a migration), plus the dedupe and cross-facet fixes, or the one number is inflated.
  - Mechanic level, with a CONFLICT line against 7c #18: a summed W–L across facets is the blended number 7c #18 forbids.
- **(3) Faceted everywhere, with no summed W–L** (7c #18 taken literally). The headline becomes a meetings count ("Ten meetings"), with the facet records beneath.
  - Client-only: both clients stop printing `head_to_head.record`.
  - It amends IA §10.3/§10.4, P-6, TERMINOLOGY row 99 and R-H's example, so it needs the owner's ruling at IA level.
- **(4) Season weeks is THE record on every surface.** The person page and head-to-head headlines read the season facet.
  - It needs the season-week dedupe fix (a migration), or You and the person page still disagree.

**Recommendation: (1) for Oct 1, then rule (3) against (2) after launch.**
- (1) removes the contradiction a golfer sees, with words only, on both clients, and invents no number.
- (3) is the only option that honours both 7c #18 and "never invent a head-to-head result", but it rewrites the IA's person page and head-to-head page, and that is not a freeze-week change.
- The parity defects need no ruling and go to lanes: the phone's "‹FIRST› LEADS" against the web's THEY LEAD, and the phone fallback's contradictory lead (N4).
- So does `head_to_head`'s season-week dedupe, a migration the owner pushes when convenient.

**Round 2:** the owner judge raises it again as a P1, "unchanged since round 1", and the category judge as a P2 (PANEL.md, Round 2).

**Blocked until ruled:** the owner judge's P1 (PANEL.md #15, and round 2's); the "weekly clash" wording on both clients; You's rivalry row on the phone, which opens a page with a different number.

### X37 · The owner's own identity in the product
**The question.** The web demo diorama's "you" is the owner, with the owner's first name, @handle, city and home course, cast as the Pro and the founder. The crew around that "you" carries real pilot golfers' first names, and several placeholders use the owner's home course and league. Keep the owner (and the crew) in the product, or recast with fictional golfers?

**Where it shows.** This memo gives line numbers only.
- **The diorama.**
  - Demo mode is the boot default for every visitor (`state.demo:true`). The diorama paints behind the Door, and no user path turns it on (D83 retired them).
  - It is still reachable in production in three ways (code-read, not tested against production):
    1. `?cs_home_state=<anything>`: the D259 hatch's boot lifts the Door whenever the query key is present. Its own comment says it "cannot exist in production" because its fixture fetch 404s there, but the Door lift does not wait for the fetch.
       - Found by session C, read from the code.
       - Root confirmed it on a prod-like server (no `tests/`): `cf401dee` lifted the Door.
       - **Fixed (45d40eb3), and shipped.** The hatch lifts the Door only when its fixture was served, and otherwise keeps it up with the shell inert. Web `272c2da1` is live, and root's production smoke shows the Door stays up with the query key. The exposure ended at that ship.
    2. The up-to-3s window while a returning session's Door waits hidden (69f40d1f). Unverified.
    3. View-source: `index.html` ships whole.
  - The keyboard path behind the Door is closed: covers make the app inert (38471687).
- **Seen by real users, outside the diorama** (at `4a703402`):
  - The feedback sheet's fine print names the owner as the recipient: web; phone `FeedbackSheet.swift:53`.
  - Three field placeholders use the owner's home course and league: web `#stNote`, `#drName`, `#mjName`; phone `PotPane.swift:427`, `PlanCopy.namePlaceholder`, `MajorSetupSheet.swift:79`.
  - The Door wings' example rows use real local course names, including the owner's (D84's named debt).
  - The shipped static pages carry the operator company (which bears the owner's surname), a contact address and the owner's city (`legal.html`, `get.html`, `support.html`).
- **Fixed since:** the golfer card's handle placeholder is now "@yourname" (W2, 35b4f475). The phone's was always generic.
- **The phone** (session A's DEC-N4-1).
  - **Two user-visible lines ship:** the feedback line that names the owner (`FeedbackSheet.swift:53`), and the Major setup's placeholder, which is the real beta league's name (`MajorSetupSheet.swift:79`).
  - Ten more lines compile into Release as sample data (`PricingParts.swift:117`, and `SeasonPreviews.swift` nine times). 285 comment, DEBUG, preview and test lines carry the identity too; `evidence/native/work-x37-native.json` lists them by file, line and term type only. E counts 57 Swift files.
  - A recommends keeping the feedback line, replacing the Major placeholder with a prompt ("Name the jug"), and recasting the sample data and previews with cast golfers.
  - N2's 7388e04e replaced the owner's name in one DEBUG fixture. A sibling DEBUG hatch (`-cs_dev_nearby_invite`, `LiveRoundStore.swift:291`) still sends it. Several preview-only and DEBUG fixtures carry the owner's or pilot golfers' identities, including `HomeStateFixtures.swift`, which is generated from `tests/fixtures/home-states.json`.
- **The public repo.** Canon files and tests also print identity: CLAUDE.md, a TERMINOLOGY row, and tests (`tests/app-tests.js`; the phone's `ShareKindTests.swift:97` pins a real first name, as session B's report notes). LEDGER X37 no longer does (ba6935a5).

**Canon, and where it conflicts.**
- CLAUDE.md: "Demo mode is a diorama".
- D83: retires every user path to the demo, calls the cast "seven fictional players", and keeps `state.demo` as the boot default and write guard. The code's own comment calls the cast "the seven players who pilot this thing". The two disagree about whether the diorama's people are real.
- D65: "the diorama never fabricates people".
- D84: the wings' fiction is named debt, "invented scores to REAL named courses", its conflict logged but never resolved.
- D259: the hatch "cannot exist in production".
- Vision #3: "No fantasy players. Real golfers."
- PRODUCT.md: "Legacy fixtures containing real pilot identities are not safe public evidence merely because they are called demo."
- N2's rule (no real person's name in a fixture) exists only in a commit message.
- No entry reconciles "real in production, synthetic in demos and fixtures".

**Options.**
- **(1) Recast with a synthetic "you" and crew,** keeping D83's plumbing.
  - Web: swap the diorama's data (`DEMO_ME`, the teams, feed, roster, players, trophies, the demo tour card, the seeded history) for the synthetic cast the harness already uses; make the placeholders generic; name a role on the feedback line.
  - Phone: the same placeholders and the feedback line; move the DEBUG and preview fixtures to the synthetic cast; regenerate `HomeStateFixtures.swift` from a rewritten `home-states.json`, which preflight checks for freshness.
  - A decision entry that puts N2's rule into canon and amends D65 and D83's description.
- **(2) Delete the diorama** (finish D83). The largest change: about 236 `state.demo` references, and a fragile boot (CLAUDE.md).
- **(3) Keep the owner as the product's face, with the owner's consent, and replace everyone else** (the pilot golfers never consented) and the real courses. A decision entry records a consented exception to vision #3 and PRODUCT.md.
- **(4) Minimal: fix only what a real user sees.** The placeholders, the feedback line and the wings' courses on both clients; leave the unreachable diorama.

**Two defects under every option:**
- Gate the `?cs_home_state` hatch so it lifts the Door only when its fixture is served (D259; client only). **Fixed (45d40eb3) and shipped (272c2da1).**
- Replace the pilot golfers' first names wherever a user or a capture can see them (PRODUCT.md).

**Recommendation: (1), with the feedback line left to the owner's taste.**
- The pilot golfers did not consent to being the product's specimen.
- The owner's handle, city and course are printed on a public page and in a public repo.
- The synthetic cast already exists on both clients' harnesses, so this is a data swap, not a design change.
- Whether feedback "goes straight to" the owner by name is a voice choice, not a privacy defect, since the owner chose to be the product's contact. Keep it if the owner wants it, or name the role ("the founder").
- Scrubbing git history is out of scope.
- Root has since taken the handle out of the LEDGER's X37 line (ba6935a5). The handle was already public in `index.html` for weeks as the old placeholder, so git history is not being rewritten.

**Blocked until ruled:** the diorama's data on the web; the phone's placeholders and fixtures; N2's rule entering canon; the TERMINOLOGY row whose ruled example carries a real surname.

### X38 · Public privacy: the settlement page and the person landing
**The question.** A public settlement link shows every player's full name, gross score and who pays whom, including players who never chose to share. A person link shows the golfer's index and dated course visits to anyone holding it. What may a stranger with a link read?

**What the pages read.** Both come from the anon SECURITY DEFINER RPC `share_info` (latest body `20260921100000_the_plan_link.sql`).
- **The settlement branch** returns every player's `display_name` and gross, and the `transfers` (who pays whom, and how much), with no `discoverable` check. The web renders "X pays Y $N", every name and gross, the course and the date.
- The published card PNG and the Netlify link preview carry the side names and the money line too.
- Any player in the round may mint it; only the link's creator may revoke it. The phone's revoke leaves the PNG to D385's cleanup queue, whose deploy is still owed.
- **The person branch** returns the name, marker, `index_current`, rounds played, the best gross, and the last three rounds with course and date, again with no `discoverable` check. A golfer with no rounds is shown an INDEX (a typed starter shown as established).
- No client says, at the moment of sharing, what the page will show. Neither client has a control to turn off a person link.
- The phone renders no public page (public pages are the web's job, D234). Its signed-in ask shows the index where the web shows rounds and best.

**Canon, and where it conflicts.**
- **Settlement: a public game artifact.** D57 ("the golfer publishes; the app never does"; the payload is "curated (already-shoutable)"; "no differential, no index, no jargon in the public snapshot"); D60a ("A settlement is about the game"); D78 (the page lists the grosses); spec §13.3 ("The recap is the funnel").
- **Against it: consent.** D380 ("a photo attached for one's leagues is not a photo agreed to for anyone holding a link") and D115 ("a bare link is not a roster reader"; a `nobody` golfer is a marker only).
- **Person: two rulings disagree.**
  - D241: the person link is "a curated public card — name, marker, number, recent rounds — in the D57 shape".
  - D394: "a stranger sees name, @handle and marker"; index and rounds are for buddies, league-mates and event-mates, and there is to be no "public directory of where people play and how good they are". "`nobody` still hides a golfer everywhere."
  - D394 was built for search, contacts and the tour card, not for `share_info`, and its CONFLICT line says "None".
  - D241's "number" also breaks D57's "no index in the public snapshot".

**A client-only fix is cosmetic,** because the data is in the anon RPC's JSON. A real fix is a migration (`create or replace share_info`) that the owner pushes. Grants are unchanged, so the anon surface stays at twelve. Both clients' renderers already cope with missing fields.

**Options: the person landing.**
- **(P1) D394 governs.** The person branch returns the stranger shape (name, marker, rounds played) and drops the index, the best and the dated rounds. A migration and `db push`; a decision entry amending D241, which also closes D57's gap. The phone's signed-in ask switches from the index to rounds played, for parity.
- **(P2) D241 governs, as the golfer's own publication.** Keep the payload; say at mint what the card shows, on both clients; add "Turn off my card link" on both. Client-only, plus an entry scoping D394 to search, contacts and the tour card.
- **(P3) The middle.** Keep name, marker, rounds and best; show the index only once established, else label it a starter (D395); drop the dated course rows. A migration.
- **(P4) Honour findability on the link.** A `nobody` or `friends` golfer's link shows the card face only. A migration; combinable with P2.

**Options: the settlement page.**
- **(S1) Keep it, and say so.** An entry ruling that a settlement is the game's, and that any player may publish everyone's gross and who pays whom. One disclosure sentence at the share control on both clients. The phone's revoke removes the PNG. No migration.
- **(S2) Narrow the payload.** First names only (as the plan branch does); drop the gross or the players; drop `transfers` (keep "$N a side" or nothing); honour `discoverable='nobody'`. A migration, plus the card PNG producers on both clients and the link preview. Cards already published keep their content until revoked.
- **(S3) Per-player consent** at the finish, as D380 does for photos. The largest option: a column, the RPC, the finish write and both finish sheets.
- **(S4) Only the starter or the Pro may publish.** A migration; narrows who publishes, not whose data.

**Recommendation.**
- **Person: P1**, with P2's "Turn off my card link" on both clients.
  - D394 is the owner's most recent privacy ruling, and D57 already kept the index out of public snapshots.
  - The migration is one branch, and the clients already cope.
  - A card that tells strangers where a golfer played last Sunday is the directory D394 refused.
- **Settlement: S2's narrowest cut, dropping `transfers`, plus S1's disclosure sentence.**
  - The game (the sides, the result, the strip) stays public, as D57 and D60a intend.
  - Who owes whom money is between friends (the brand's money sentence: "the money moves between friends").
  - If the owner reads the settlement as fully shoutable, S1 alone is the ruled alternative.

**Blocked until ruled:** the `share_info` migration and its `db push`; the share controls' disclosure copy on both clients; the phone revoke path; the craft public-round D cell (Q11) and the claim-invite privacy cells, which the panel "recorded, not scored".

### X39 · Trophies on a first round
**The question.** A golfer's first round can earn several milestones at once ("Broke 100", "Broke 90", and in some paths "Personal best"). Should a milestone need a previous round to break?

**What mints them today.**
- The `round_moments()` trigger (latest in `20260921090000_a_post_can_be_homed_on_a_person.sql`) awards every Broke-N threshold an 18-hole round newly crosses. There is no prior-round requirement, so a debut 85 mints Broke 100 and Broke 90 together, and the board posts "broke 90 for the first time — an 85".
- A **personal best** on that forward path needs a prior round. But `rederive_achievements()`, which runs after every round delete (`20260902173000`), and the July backfill both award a PB to a lone round. The harness fixture models the rederive path, which is why the capture `you--one-round--375--dark.png` shows PERSONAL BEST.
- `home_feed.is_sub80` fires on a first round, and on a nine (X41).

**Canon.**
- No entry says a milestone needs a prior round.
- What bears on it:
  - memory-layer v1 (one headline per round: barrier > PB > streak);
  - D22 ("a round is one story, not three");
  - D166, whose principle is that every line states something the data supports ("The bad round must never land on a beginner");
  - D291 (BESTS, and several milestones "together");
  - L-44 (every number that counts must count something);
  - the product vision ("I finally broke 80.").
- For the nine: D391's amendment ("Nines are never compared") and PRODUCT.md ("A nine without recorded side cannot claim a comparable best").
- PRODUCT.md also says this program authorises no mechanic or data change, so options that move a trigger need the owner's separate approval and a `db push`.

**Options.**
- **(1) A milestone needs a previous round.** The trigger, `rederive_achievements`, `home_feed` and `home_stories` gain the guard (migrations); the clients are unchanged. Mechanic level.
  - Tradeoff: a golfer whose first posted round is an 85 can never earn Broke 100 or Broke 90, because no later round is "the first time".
- **(2) The first round is a baseline, and the display folds its milestones into FIRST ROUND.**
  - The trophy case folds a BESTS row that shares the first round's `round_id` into the FIRST ROUND slat.
  - The epilogue drops "You broke 90 for the first time" when this is the first round.
  - The feed prefers `is_first`.
  - Both clients: the web's `renderTrophyCase`, epilogue and feed; the phone's `TrophyMeta`, `PostEpilogue` and `HomeWireCopy`/`HomeDigest`. UI level.
  - The board's debut headline still needs the trigger guarded (a migration).
- **(3) Keep the thresholds, and make the producers agree.** `rederive_achievements` and the backfill adopt the trigger's rule that a PB needs a prior round, and the fixture follows. A migration, with a short entry stating the rule, since no canon does.

**Recommendation: (2) now, and (3)'s PB rule in the X41 migration.**
- (2) says what the data can support: a first round is the first round, not the first time under 90. It keeps every threshold earnable. It is client-side on both clients.
- (1) would lock a strong debut out of two trophies forever.
- (3)'s rederive fix is a one-rule change in the same migration the owner already owes for X41.

**Blocked until ruled:** the owner identity E cell; the first-round rendering of the trophy case and epilogue on both clients; what X41's migration carries.

### X40 · "7.9 vs course" on a personal best
**The question.** A personal best's line reads "7.9 vs course · ‹course› · ‹date›". Keep "vs course", or print the round the golfer knows ("83 at ‹course› · ‹date›") on both clients? W2 forwarded the same choice.

**What the number is.** It is the round's **differential** (`(gross − rating) × 113 ⁄ slope`, doubled for a nine), the handicap engine's input. Lower is better. It is not the vs-your-playing-HCP figure, which runs the other way (plus is better). You also shows a separate "Best vs your playing HCP" tile, which can name a different round.

**Where "vs course" prints today.**
- Web: the PB slat (`csMilestoneSub`); the receipt row (the permitted place); and the tour card sheet's "Best round vs course" and "VS COURSE ‹diff›" in recent rounds.
- Phone: the PB slat (`TrophyMeta.milestoneSub`); the receipt; and the composer's "21.5 vs course" for a golfer with no number yet (`PostCard.vsText`).
- Three tests pin the PB string.

**Canon, and where it conflicts.**
- D291 (UI level, 2026-09-07): "a personal best reads `4.1 vs course · ‹course› · Aug 24`". Its reason: the gross put the identical sentence under BROKE 80 and PERSONAL BEST. It carries no CONFLICT line.
- TERMINOLOGY row 92 (shipped through D249): "vs the course" appears "on the receipt beside the arithmetic; nowhere else", because "it is the differential wearing a label".
- P-16: the differential lives on the receipt row "and nowhere else".
- L-14: "'differential' and 'PvI' never on a user surface; a bare float is always labelled".
- PRODUCT.md and brand canon: no differential on any user surface.
- D210, D209 and IOS-016: the on-screen best is the playing-HCP figure.
- The direct conflict is D291 against TERMINOLOGY row 92, P-16 and L-14.
  - D291 is later and more specific, but it skipped the CONFLICT line CLAUDE.md requires.
  - R-M and D260 rename the comparison to the handicap; they do not forbid "vs course" outright.

**Options.**
- **(1) Receipt only.** The PB slat names its round, "83 at ‹course› · ‹date›", and when BROKE N and PB share a round the line prints once, which answers D291's reason.
  - Both clients' slat producers change (`csMilestoneSub`, `TrophyMeta.milestoneSub`), with their three tests.
  - If applied everywhere, the tour card sheet and the phone composer follow.
  - No database change; an amendment to D291.
- **(2) The PB round in the playing-HCP lens.** Read the server's existing figure for that round. No database change.
  - But the PB is still chosen by lowest differential, so its printed figure may not be the golfer's best vs playing HCP.
  - And a round outside every league has no figure.
- **(2b) Redefine the PB as the best vs playing HCP.** A trigger, rederive and `home_feed` change (migrations), at mechanic level.
- **(3) Ratify "vs course" on the PB slat.** Amend TERMINOLOGY row 92 and P-16 to name it as the one other permitted place, with the CONFLICT line D291 lacked, and perhaps a direction cue.

**Recommendation: (1).**
- It keeps the differential where every higher rule puts it.
- It prints the fact a golfer remembers (the score and the course).
- It resolves D291's duplicate-sentence worry by printing the shared line once.
- It is copy on both clients.

Session A counts the phone's twins as detector findings TPN-35 (the composer, for a golfer with no number) and TPN-36 (the trophy line, `TrophyMeta.swift:135`), and leaves the ruling to the owner.

**Blocked until ruled:** the owner identity R cell; the PB slat's producers and their tests on both clients; the D291 amendment.

## B · Raised since the ledger (SESSIONS §C)

### Q1 · The live recap draws its hole strip twice
**The question.** Now that N2 fixed the settlement card so it shows, the phone's live-round recap draws the hole strip twice: inside the card, and again under it with its own legend. Which one stays?

**What is on the screen** (phone, `LiveFinishViews.swift`, `LiveRecapSheet`):
1. The takeover band.
2. The 1080×1350 settlement card, with its strip and legend. Per D90 it has no footer.
3. A second strip (`LiveHoleStrip`), whose visible footer reads "THRU n" / "CLOSED ON n" and whose VoiceOver label is "Hole strip, thru N".
4. A second copy of the legend.
5. The highlight chips, the only place the phone shows them.

N2's `1a33a6aa` reported the double strip "for a D360 decision, not changed here", and `8a9ba48a` made the card and the strip one VoiceOver element each. N2's suggestion (SESSIONS §C): keep the card's strip. On the **web** recap there is no in-app card: `showLiveRecap` draws a text settlement row and the strip once, and the card is drawn only for Share.

**Canon, and where it conflicts.**
- D277 and UI_SYSTEM §11.3: the settlement card is rendered in the app "at the geometry it exports at … no second in-app rendering to drift from the PNG".
- D78 and D90: the strip belongs in the finish recap, and "the in-app hole strip keeps its footer" because the card deliberately has none.
- D360 and L-34: one fact, one place. D201 calls "the same thing said twice on one screen" the product's main failure mode.
- UI_SYSTEM chart 4: a strip is "one VoiceOver element in the product's voice", the precedent for a spoken footer.
- D234: D277's in-app card was built on the phone only, so the two recaps already differ.

**Options.**
- **(1) N2's: keep the card's strip.** Delete `LiveHoleStrip` and its legend, keep the chips, and speak the footer only in the card's label. Sighted golfers lose "THRU/CLOSED ON", which amends D90's scope (a new entry). The UI test at `N2LiveRecapUITests.swift:120` changes.
- **(2) As (1), but keep the footer visible as one agate line with the chips under the card,** and in its label. Every fact appears once, and D90 and D277 both hold. Phone only; a short entry applying D360 to the recap.
- **(3) Take the card out of the recap.** Keep it only as the Share preview; the phone matches the web. Reverses D277 and §11.3.
- **(4) Keep both as a named exception** ("the artifact shown as an object, and the in-app reading"), and at least drop the repeated legend. An entry recording the exception to D360.

Session A's DEC-03 carries the same question and leaves it to the owner.

**Recommendation: (2).**
- It is the only option that says every fact once without deleting one.
- It keeps D277's card and D90's footer.
- It is a small phone-only change that lane N4 can test.
- Separately, the owner rules whether D277's in-app card is owed to the web (D234). Recommend yes, after launch.

**Blocked until ruled:** the phone recap's layout and its UI test; E's `N2LiveRecapUITests` expectations.

### Q2 · The join covenant's "between the top two" (not live; the real work is elsewhere)
**The question as asked.** The join covenant says "between the top two" for two squads: defect or decision?

**What the source says.**
- At `de3eaf35` a two-squad covenant does **not** print "between the top two" on either client. The phrase is only the fallback for a payload with no structure, and `join_covenant_info` always returns `structure`, whose column is NOT NULL and defaults to two squads.
  - The web's two-squad ending: "Both squads meet in a four-week Cup Final, and the squad leading on points starts it 10 up."
  - The phone's: "Both squads play a four-week Cup Final, scored fresh. The leading squad carries a 10-point head start."
- The two-squad ending is worded three ways: the web covenant, the phone covenant, and D126's rules-page producer ("… scored fresh, and the leader carries +10 in").
- Root has since ruled that the covenant's ending uses the phone's words on both clients (L-34), and session B is aligning the web (§E).

**Canon.** Spec §14.3: both squads play at two-squad scale, and the leader starts +10. D126 ("Both squads reach the Cup Final … The season decides who starts +10", with one producer on each client); D127; SA-3 (at a field of two, the clause never says "the top two seed"). "Between the top two" came from IA and core-flow mock copy, and was never ruled.

**It is a defect, not a decision, and it is not the last one.** Other producers still word a two-squad season as a cut, against spec §14.3, D126 and SA-3. No ruling is needed for any of them. The lines below are at `de3eaf35`; the W2–W5 merges since may have moved them:

| # | Producer | Web | Phone |
|---|---|---|---|
| 1 | The finalist receipt during the Final: "The weeks before it decided who is in; this is the race." | `index.html:7955` | `CupFinalRaceView.swift:141` |
| 2 | Once the Final opens, the scenario line names one squad "INTO THE CUP FINAL". It is the live points leader, not seed 1; `meta.seeds` is sent but read by neither client. The web says "SEEDS SET" where TERMINOLOGY rules "The Final is set". | `index.html:29050` | `StandingsMath.swift:702` |
| 3 | The live Final's section head "top two" | — | `SeasonPage.swift:261` |
| 4 | Climb badges IN / OUT: the trailing squad reads OUT of a Final it is in | `index.html:7785` | (in unused `ClimbMath`) |
| 5 | The SQL board post when a Pro sets the finish: "… top seeds only." | `20260831120000_board_voice_natural_case.sql:1792` (a migration) | (prints the post) |
| 6 | A tie's "in the Final by {rung}", where the rung decided the +10, not entry | `index.html:7918`, `:7944` | `CupFinalRaceView.swift:30`, `:107` |
| 7 | The wizard's finish help: "Top two …" | `index.html:5663`, `:13254` | `WizardState.swift:62`, `LeagueSetup.swift:64` |
| 8 | Season story rung 3: "The top two are level …" | `index.html:7315`, `:7320` | `SeasonStory.swift:326`, `:332` |
| 9 | The covenant's no-structure fallback (dead code) | `index.html:29894` | `JoinLeague.swift:269` |

Rows 1–4 and 6–9 are client copy for the web (root/W6) and N4. Row 5 is a migration the owner would push. Row 2 also breaks L-44 ("a hero never claims a table rank as a seed").

**The one real question: the canon conflict.** TERMINOLOGY rows 141–142 rule "IN the Final ✓ / Out" and "Cut line · top two reach the Final" without regard to structure, which is itself the cut wording spec §14.3 and D126 forbid at two squads. TERMINOLOGY row 11 also gives every structure "the leader starts +10", where the engine gives it only to two squads.

**Recommendation.** Make TERMINOLOGY rows 11, 141 and 142 structure-aware, citing spec §14.3 (the higher level) and D126: at two squads, "Both squads play the Final; the leader starts +10." Then treat rows 1–9 as defects on both clients, with row 5 in the next migration.

**Blocked until ruled:** only the TERMINOLOGY amendment. The defects can start now.

### Q3 · GuideCopy states the monthly minimum a third way (a defect; recorded)
**Status: a defect on both clients with a ruled fix. No owner ruling is needed.** **Both halves are fixed:**
- the web (f6cb4760: 5777f011): "What counts" prints `floorSentence()` when a league is in hand, and keeps its general account without one;
- the phone (6716b0ed: 1a0703c8): `GuideCopy` states the league's `floorSentence`, fed from the season page, the join welcome and Card & settings, with two new `FloorSentenceTests`.

**What the source says.**
- The scoring guide (the phone's `GuideCopy.scoring(solo:)`, the web's `openScoringHelp`) says "Miss it once and your bye covers you automatically … the penalty bites from the second miss". It is word for word on both clients, and it never sees the league's floor or preset.
- The rules page uses `floorSentence`, verbatim twins on both clients.
- In a Casual two-squad league with a minimum, the rules page says "Nothing is docked if you miss", and one tap later the guide says the penalty bites. The guide also leaves out that short months are waived.

**Canon.** Q-27 in the blind-audit remediation plan ("`floorSentence()` — one floor everywhere", listing this guide paragraph among its consumers, and marked done though the guide never switched); D128 ("two producers … kept in step across clients by tests"); D234; L-34; D14 (the bye is automatic; floors bite from the second breach); D140 (a solo floor is a habit).

**The fix.**
- When a league is known, the guide's minimum clause is that league's `floorSentence`. The phone passes the league's floor, preset and structure into `ScoringHelpSheet` from its three entry points; the web's `openScoringHelp` calls `floorSentence()` whenever a league is set.
- With no league, the guide does not restate the rule.
- Ship both halves together (D234), with a twin test beside `tests/app-tests.js`' current pins.
- Phone: lane N4. Web: root or W6.

**Also for canon's owner:** both `floorSentence` producers read the penalty from the preset, not from `floor_penalty` as Q-27 says. They are correct today only because both wizards derive one from the other. Spec §3.2 still calls the bye "commissioner-approved", which D14 superseded.

### Q4 · The Pro's Home is identical to a member's
**The question.** On the desk (and on the phone) a Pro's Home is the member's Home: nothing names the Pro's pending jobs. Should Home carry a Pro item, and when?

**What the source says.**
- The desk captures of `home/pro` and `home/member` are byte-identical (COVERAGE §1.4).
- The web's role-aware pieces stand down under a lead: the D119 hero, and the pulse card's "Waiting on ‹names›", which can never render. So in the captured state nothing on the desk Home reads the role.
- The server's only role branch is `home_dispatch`'s `runitback:` item, which W3 confirmed and forwarded.
- The phone's Home reads no role at all. It retired the D119 hero, which the web still draws, a parity gap.
- On both clients the Pro's jobs (buy-ins, the finish, seats and byes, announcements, the draw) live on the season page.

**Canon.**
- D226:
  - the ME strip and the lead are the same for every viewer;
  - "The Pro's pending action becomes one ranked item (Tier 6, once per condition)", ruled but unbuilt;
  - the Pro's tools are a season-page row, "never a mode and never the identity of a screen".
- D234 and R-C: the web leans into the Pro's desk.
- UI_SYSTEM §14.1 and §14.3; D280, which bars the "THE DESK" label.
- Constraints on any Pro item: D23 (once per condition, no badge counts), D129 ("You still owe" is self-only) and D318 (money off the phone's Home).
- CLAUDE.md says a "role-aware Home" is live, which the code no longer bears out.

**Options.**
- **(1) One Home on purpose.** D226's lead and strip rule stands, and the Pro's desk is the season page. Decline D226's ranked item; delete the unreachable pulse card; correct CLAUDE.md's claim. Web only.
- **(2) Build D226's ranked Pro item on both clients.** A `pro:<league>` item in `home_dispatch` names the one pending job and routes to the season page, once per condition, with no money on the phone's Home. The pending job is one of:
  - unpaid buy-ins;
  - unseated late joiners;
  - floor stragglers;
  - a league still unlocked or undrawn before first tee.

  A migration and `db push`, and an entry marking D226's item built.
- **(3) A desk-only Pro block** from reads the desk already has. Web only; it needs an entry justifying no phone half (D234) and reconciling D226's "never a mode".
- **(4) One duty line under the lead** on both clients, client-only, amending the L-34 stand-down rule.

**Recommendation: (2), after launch; for Oct 1, (1)'s correction of CLAUDE.md's claim.**
- D226 already ruled the item, so building it follows canon rather than inventing it.
- But it is a server ranker change across two clients, the same shape as Q10's event item, and the two should land together.
- The web's leftover D119 hero is a parity defect for W6, whichever option wins.

**Blocked until ruled:** the owner desk cells about the Pro; D226's item; CLAUDE.md's role-aware sentence (root's to edit).

### Q5 · Where the build stamp lives
**The question.** `v23 · <sha>` shows on the Door's face (`#obCaption`), in every desk sidebar's foot, and in the settings sheet's foot. The judges ask to take it off the welcome and out of the sidebar; W2 asks whether it goes into "How it works".

**What depends on it.**
- CLAUDE.md's deploy discipline uses `#obCaption` as the "is it live" diagnostic, and `tools/ship.sh` tells the human to check it.
- The web's feedback sheet reads its version from `#obCaption`.
- `stamp-version.sh` substitutes and verifies the placeholders.
- Preflight asserts exactly four in `index.html` and one in `sw.js`.
- `tests/brand-door-browser.js` fails if the caption is gone.
- On the phone, the Door shows "v1 · build N" and Settings shows "Cup Season · v1 · build N". Settings' long-press is the only door to the Developer section; `project.yml` calls the two "CLAUDE.md rule 2's native equivalent".

**Canon.**
- CLAUDE.md rule 2 names "the sign-in caption and `sw.js`'s `VERSION`", plus the diagnostic.
- UI_SYSTEM row 84: "`v23 · <sha>` in Settings and at the foot of the desk's sidebar". It never names the Door.
- D280 (the §14.1 foot carries "the viewer's face, their number and the build identity") is the only decision entry on placement.
- The two canons name different homes.
- The judges (owner.json): keep it where the diagnostic is needed "but off the welcome's face"; "Support or behind a long-press"; "Move the stamp" from the sidebar; "How it works" in Settings.

**Options.**
- **(B1) Hide it on the Door, drop it from the sidebar, keep Settings.**
  - The Door caption stays in the DOM, visually hidden or revealed by a long-press on the pennant, so the diagnostic, the feedback read and the Door test keep working.
  - The sidebar foot goes, and preflight's count drops from four to three.
  - The phone's Door caption goes behind a long-press; Settings keeps its line and its developer door.
  - An entry amending D280 and UI_SYSTEM row 84. No CLAUDE.md change.
- **(B2) Move the diagnostic into a `<meta name="cs-version">` tag,** and delete the Door caption and the sidebar foot. Settings keeps its line or moves it into "How it works". The feedback read, the preflight count, the Door test, CLAUDE.md's diagnostic and `ship.sh` all change.
- **(B3) Move it to `support.html`.** `stamp-version.sh`'s substitution and survival check are extended to that file. The diagnostic becomes `/support`.
- **(B4) Keep everything, and rule it.** An entry records why the Door caption stays.

**Recommendation: (B1).**
- It gives the judges what they asked for: off the welcome's face and out of the sidebar.
- It keeps every consumer of the stamp working without touching CLAUDE.md or `ship.sh`.
- Settings is where UI_SYSTEM already puts it.
- "How it works" can hold it later, if the owner prefers it there to Settings' foot.

**Blocked until ruled:** the owner Door C and P cells, settings P and desk B; preflight's placeholder count.

## C · Found in the round-1 evidence, or forwarded by the lanes

These are the panel's `decision` cells: 32 of the 649 web cells below 9, and the native half's 15 (root, 2026-09-28), which mostly repeat web questions and add Q29 and Q30. They also include the questions lanes W2–W5, session B and N2 forwarded through root. LANE-BRIEF tells every lane to list a decision rather than make it.

### Q6 · The Door's proof: does the phone Door carry a specimen too?
**Status.** The defect is fixed, in two steps.
- W4's `2bc71749` (merged at `b8a61266`) turned the desk wings into labelled examples ("How a round reads", "How a season reads", an example-season foot), standing down on a link landing.
- They still ticked. Round 2 (session D) caught it, and root stilled them at `7141516f`. An earlier version of this memo called the labels the whole fix; it was not.

What is left is a design choice for the phone. Round 2's category judge still marks "The phone Door still shows no product" (P2).

**The question.** Should the phone Door, which shows only the mark, the promise and the sign-in, carry one labelled specimen of the game as the desk does?

**Evidence.** Craft door B 8 and D 8 (decision: "bring one live rail card onto the phone door"); owner door P 7 and E 6 (decision: "one real-looking round-to-table moment"); category door H 7 (`door--initial--375--dark.png`).

**Canon.**
- PRODUCT.md: no invented claims (the labelled examples meet it).
- CONTENT-CEILINGS.md `web/door.E`: real permissioned examples are the eventual source of the Door's social proof.
- D234: two shapes, so the phone need not copy the desk.
- ROAD_TO_TEN §4: emotional appeal has a ceiling near 6.5 without real content.

**Options.**
- **(a) Keep the phone Door as it is.** Only the desk shows the example.
- **(b) One labelled specimen card on the phone Door** under the actions, drawn by the same example producer. Web `#onboard` at phone widths, and `DoorView.swift` on the phone (N4).
- **(c) Later: real permissioned examples** (consent and an anon SECURITY DEFINER producer, so a migration and the owner's `db push`).

**Recommendation: (a) for Oct 1, then (c).** The P1 is gone. A phone specimen is new design on both clients two days before freeze, and the phone Door's job is the sign-in, which root already tuned (dd01225d). Session B's wordmark work ([WM], Q24) is also landing on the Door.

**Blocked until ruled:** the phone Door's B, D, E and P cells with craft and owner.

### Q7 · Which line signs the Door and the shared artifacts?
**The question.** The Door leads with "Any time. Anywhere.", and every shared artifact is signed "ANY TIME. ANYWHERE." Should they carry the promise, "Where amateur golf counts"?

**Evidence.**
- Owner judge, share B 9 (decision): the artifact is unmistakably Cup Season, but its signature line is not the brand's why (`artifacts/share--recap-no-photo--375x667--dark.png`).
- Owner judge, door E 6 (decision): "Any time. Anywhere." answers when and where, not why.
- Category judge, door H 7: the phone Door's tagline does not say what Cup Season is.

**Canon.**
- `spec/brand-canon.md` §1 and PRODUCT.md: "Cup Season is where amateur golf counts."
- `spec/product-vision-v1.0.md`, "Keep the established tokens…": "Any time. Anywhere." can describe flexibility; "Where amateur golf counts" says why the product exists. "A surface chooses the sentence that answers its visitor's question."

**Options.**
- **(a) Apply the vision's rule as written.** A stranger on the Door and a recipient of a shared card are both asking "what is this?", so both carry "Where amateur golf counts". "Any time. Anywhere." stays where flexibility is the question (posting from any course). This is copy on both clients: the web Door and the artifact renderers, and the phone's Door and `RecapCardView`/share card (lane N4).
- **(b) Keep "Any time. Anywhere." on both.** No change; the owner and category cells stay.
- **(c) Split.** The Door carries the promise and the artifacts keep "Any time. Anywhere." as a sign-off, or the reverse.

**Recommendation: (a).** Canon already states the rule; this only confirms which question each surface answers. No new decision entry is needed beyond a line noting the reading, and the change is words, not layout.

**Blocked until ruled:** owner door E, owner share B, category door H; the copy on the phone's Door and share card.

### Q8 · One colour for round points (settled in lane W4; recorded)
**Status: settled by canon, no ruling needed unless the owner disagrees.** W4 applied UI_SYSTEM §2.4, merged at `b8a61266`:
- round points are ink in the finish ceremony and on the card (df111545);
- they are mut in the Door's example (2bc71749);
- the leader's points stay the one gold figure.

**Canon.**
- UI_SYSTEM §2.4: gold marks "a thing that was WON", with "at most one gold object per viewport", and "an average is not won".
- D359: ember is active competition only.
- D254's metal rule reads "a figure that runs in your favour" as green (`pos`). That is the only other reading, and the owner can choose it instead.

**Blocked until ruled:** nothing.

### Q9 · The gate itself: content, genre and device-or-human ceilings
**The question.** The §29 gate says no cell below 9, but 28 cells can only be raised by a real device or person, 80 name content the product does not have yet, and 17 "decision" cells (14 category, 3 craft) say the genre is the ceiling ("It is a rules page"; "None required"). How are those cells counted?

**Evidence.**
- PANEL.md §4.
- Category legal E 4, rules E 5, support P 5, settings B 5 and E 5, each with "None" or "None required" as its change.
- Craft rules E 5: "the genre is the ceiling".
- The 28 device-or-human cells: motion, haptics, real photographs, real keyboards and the OTP round trip.

**Canon.**
- The ASSESSOR-BRIEF names four kinds of barrier ("a concrete visible defect …, a content ceiling, a ratified decision, or device/human evidence").
- ROAD_TO_TEN §4 ("the part of the answer you should read twice") puts emotional appeal near 6.5 without real content, premium near 7.5 without photography, and density near 7 without real leagues. It also says mobile usability "cannot honestly pass 6 until somebody puts a finger on it".
- LEDGER's rule: human gates are never marked from automation.

**Options.**
- **(a) Hold the gate literally.** Every cell must reach 9. By the program's own canon that cannot happen by Oct 1 without real golfers' content and device runs, so launch would wait on adoption.
- **(b) Hold every defect cell to 9, and name the rest per cell.** Content ceilings go in CONTENT-CEILINGS.md with their source, genre ceilings go as named exceptions, and device-or-human cells go to HUMAN.md rows whose result decides them. The mean is reported twice: over all cells, and over cells without a named ceiling.
- **(c) Re-score genre pages against their genre** (a legal page against the best legal pages), which asks the judges to change their lens mid-program.

**Recommendation: (b).** It uses the categories the assessors already wrote, it keeps "no defect below 9" absolute, and it makes the remaining gap an honest list rather than a moving score. Root should give the judges the ruling before round 2, so the native half and round 2 are scored the same way.

**Blocked until ruled:** what "gate met" means for every row, and so the launch call; how round 2 is read.

### Q10 · Home's missing moments: an upcoming Ryder, the clash holder, the crown
**The question.** Home's ranker has no event item, the week's clash hides who holds it ("You and Devon are both in."), and a crowning is text only. Which of these should Home say, and when?

**Evidence.**
- Owner judge, home E 7 (decision): "say who holds the clash; give the crown its trophy object; add an event item to home_dispatch" (`home--hatch-event_ahead--375--dark--first.png`, `home--dispatch-ceremony_night--375--dark--first.png`).
- The harness's own fixture note (`tests/fixtures/ten/home-states.synthetic.json`, `event_ahead`): "The ranker has no event item and no event route." `home_dispatch` has fifteen item kinds, and the phone's `HomeDispatch.Route` has no `.event` case.
- W3 forwarded all three as questions.
- Root adds that the clash lead is the server's own sentence: `home_dispatch`, `20261006093000:243`.
- Round 2's owner judge repeats it as a P2: the lead "never says who holds the week … while the season page shows YOU 9 · DEVON 7".

**Canon.** D234 (the server ranks Home for both clients); D176 and D216 (the lead card's rungs); D108 and D207 (the clash); D254's metal rule (a rivalry record taken off somebody is gold). Neither the withheld holder nor the text-only crown is ruled in the entries this memo read.

**Options.**
- **(a) All three before launch.**
  - A new `event` item kind and route: a `home_dispatch` migration, the web ranker, and `HomeDispatch.Route.event` in Swift.
  - The clash holder in the lead: the same migration, since the sentence is the server's.
  - The crown's trophy object: client drawing on both.
  - A decision entry at IA level, and the owner's `db push`.
- **(b) Keep Home as it is for Oct 1,** and write (a) as a decision entry now so it is built first after launch.
- **(c) Only the crown's object now** (client-only), with the event item and the clash holder after launch.

**Recommendation: (b), or (c) if a lane has capacity after W1.** The event item and the clash holder are server ranker changes with two clients and tests behind them, and the freeze is Sep 30. Hiding the holder may also be deliberate suspense, which is the owner's to say.

**Blocked until ruled:** the owner home E cell; the clash lead's sentence (a database change, root's third "database owed" item).

### Q11 · Should a public round say which season it counted in?
**The question.** The public round names the golfer, the course and the score but not the season it counted in. Add one line?

**Evidence.** Craft public-round D 7 (decision): "Owner call: one line of season context on public rounds" (`public-round--public--375--dark.png`).

**Canon.** D394 ("Findable is not readable: what a stranger sees") and D241 (the anon surface stays at twelve endpoints), which X38 turns on.

**Options.**
- **(a) Keep the public round to the round's own facts.**
- **(b) Add the league and season name.** This discloses league membership to anyone holding the link, and if `share_info` does not already return it, it is an anon RPC change (a migration).

**Recommendation: (a), and rule it together with X38.** Adding what a stranger reads is the opposite direction from X38's question, and the two should not be answered separately.

**Blocked until ruled:** the craft public-round D cell only.

### Q12 · Structural performance before Oct 1?
**The question.** AW's two performance items are structural. Do they ship before launch, or stand as named exceptions with a date?

**Evidence.**
- AW P2-11: its Door flash is fixed (69f40d1f), and W3 removed one of Home's three re-lays (a buddy request no longer tops Home, e8108e59). But Home still renders in stages; CLS was 0.55 at 375 at `9d84c483` and has not been re-measured.
- AW P3-25: one 2.05 MB document, 508 KB brotli, parsed by every visitor, with every view resident.
- Performance is 2/4 in AUDIT.md, and the audit gate is 18/20.

**Canon.**
- The owner's direction: "We ship all before launch."
- SESSIONS §1: implementation ready Sep 29, freeze Sep 30.
- CLAUDE.md: "A future split into real modules is welcome; preserve the boot semantics." The classic↔module boundary is a named landmine.
- AW itself labels code splitting "structural, post-launch".

**Options.**
- **(a) Both before launch.** It is a restructure of the boot on a two-day clock, and the boot is where CLAUDE.md's landmines are.
- **(b) The cheap half now, the split after.** Render Home once in its final slot order (or reserve the slots), and self-host or preload the two Plex faces, before freeze; code splitting gets a post-launch date as a named exception.
- **(c) Both after launch,** as named exceptions.

**Recommendation: (b).** The layout shift is what a golfer sees on every open; the parse cost is invisible at 1× CPU (FCP 88–152 ms). A boot restructure two days before freeze risks the single failure a launch cannot absorb.

**Blocked until ruled:** AW's performance dimension, and with it the 18/20 gate.

### Q13 · An already-claimed card (settled in lane W4; recorded)
**Status: settled, no ruling needed unless the owner disagrees.** A kept scorecard landed on the plain Door with no sentence (`links--claim-used--375--dark.png` was byte-identical to `door--initial--375--dark.png`), and the judges split on it: category "by design", craft "a decision", owner a defect. W4's `5d536f41` (merged at `b8a61266`) now says: "That scorecard is already on a golfer's record. If it's yours, sign in with the same email and it's in your rounds." It is not an error, and it reveals no more than the dead-token line does. The harness now pins that line instead of the silence.

**Canon.** The dead-token branch's own comment (F3, the shareability audit) had already ruled silence on a link a defect.

**Still owed:** the phone's claim link (`Links.swift`) should say the same (lane N4; `TERMINOLOGY` T-01: "scorecard", not "card").

### Q14 · X18 · the install nudge over league-less Home
**The question.** On league-less Home the install nudge (D186) sits fixed over the top of the page, above the sticky header, until it is dismissed. Keep it, move it into the page, or show it only after the first round?

**Evidence.** LEDGER §4c X18, a "named barrier · owner"; critique B lists the nudge as not captured.

**What the source says.**
- `#installNudge` is `position:fixed` with `z-index:24`, over the header's 20, and its copy leads with D186's reason: "Safari signs you out after a week away. On your home screen, you stay signed in."
- Three earned moments fire it: the first real round (1.4s later), joining by invite (3.2s), and landing league-less (3.4s, D186's third moment).
- **Two defects under every option, now fixed.** Code-audit item B25 (`docs/audit/code-2026-08-30/code-audit.md`) was still open at `de3eaf35`; root fixed both halves at 6c5f251b, prompted by this memo:
  - `dismiss()` never clears `shown`, so a dismissed banner comes back on the next view switch for the rest of the session;
  - the busy list names `view-record`, not the composer's `view-post`, so the nudge can sit over the composer.
- The phone has no install nudge (web only by construction).

**Canon.**
- D186: the nudge leads with the reason; it is shown "once ever per device, still silent when installed, still silent over a working surface". It names no delay and no position.
- D23 and L-20: once per triggering condition, and V1 nudges are Home-surfaced chips.
- Home's slot table (`HOME_STATE_MATRIX.md`): the deck never carries "a tip; a promotion", so an in-flow nudge needs a named slot.

**Options.**
- **(a) Keep the overlay, and fix B25.** Clear `shown` on dismiss, re-show only when eligible, add `view-post` to the busy list, and sit the banner under the header as B25 proposes. No new entry.
- **(b) In the page, at the head of league-less Home, drawn at first paint,** so nothing shifts at 3.4s and nothing covers the header. It needs a one-line entry amending D186's presentation and naming the slot for league-less Home only. B25 is fixed as in (a).
- **(c) Only after the first round.** Remove the league-less trigger. This reverses D186's third moment and loses the cohort Safari's seven-day wipe takes, which D186's own comment names.

**Recommendation: (b).** B25 is fixed (6c5f251b), whatever the ruling.
- It keeps D186's reason and moment.
- League-less Home is the emptiest page in the product, so a slot there displaces nothing.
- It removes the only fixed overlay on a page a stranger is reading.
- Drawing it at first paint avoids the layout-shift class AW measured (Q12).
- If the owner prefers not to name a slot, (a) is the fallback.

**Blocked until ruled:** X18; league-less Home's first-screen captures.

### Q15 · May a lane re-lay a ruled sentence without a ruling?
**The question.** Three decision cells ask to present words an owner decision fixed, without changing them. Can the lanes act, or does each need a ruling?

**Evidence.**
- Category post R 7: D364's worth line carries four numbers in one block ("break it into two short lines per league").
- Category courses Sp 7: "AVAILABLE OFFLINE · SAVED TODAY" repeats under every course ("once per list").
- Craft claim-invite D 7: the covenant is nine stacked paragraphs ("group them under three heads: who, how it scores, the money"). W4 forwarded it as a choice: headings, or a terms rail.

**Canon.**
- D364: "A course reference says *Available offline · saved today*", and the worth line's three parts in order.
- D351 and D353a: the terms reach the golfer on every door into a league, and the covenant says the allowance, the whole counting rule and the dates.

**Options.**
- **(a) Yes to all three.** The words stay; the layout changes. The second changes where D364's sentence appears (once per list rather than once per course reference), so it amends D364 in one line. For the covenant, the choice is three heads (who, how it scores, the money) or a terms rail beside the Join. The rail is a desk shape (D234) that the phone would not share.
- **(b) Layout-only changes need no ruling (the first and third); the second waits.**
- **(c) No.** Ruled sentences keep their current layout.

**Recommendation: (b), and a yes on the second as a one-line amendment to D364.** A saved course list says "saved today" once, and the reason D364 gave (L-32: say what the copy is and when it is from) holds either way. For the covenant, recommend the three heads: they work in both shapes and keep D351/D353a's terms whole. Root has already ruled that the covenant's ending uses the phone's words on both clients (§E).

**Blocked until ruled:** three cells; lanes W1 (composer), root (courses) and W4 (covenant) are waiting on this.

### Q16 · Old test bundles with host-wide simulator logs
**The question.** Some older result bundles in the local gallery (outside git) contain xcodebuild's automatic diagnostics, which include host-wide simulator logs. Delete them?

**Evidence.** LEDGER §4g: `results/t5`–`t9`, `ui1`–`ui4` and `unit1`, and the `UI-se3-*.xcresult` bundles under `before/` and `after/`. Every run since `t10` uses `-collect-test-diagnostics never`.

**Canon.** SESSIONS §5: diagnostics sweep in host-wide simulator logs and "must never reach git or the gallery".

**Options.**
- **(a) Delete the listed bundles.**
- **(b) Keep them local**, and never publish the gallery.

**Recommendation: (a),** after root confirms that no ledger row cites a file inside them. Deleting is irreversible, and it is the owner's call by §4g.

**Blocked until ruled:** nothing on the launch path.

### Q17 · Tier Home's wire into slats? (it would amend the ratified D360)
**The question.** Should the wire give big rounds a larger treatment and ordinary rounds a one-line slat, or should every round without a photograph stay D360's compact record?

**Evidence.**
- Craft: "Tier the wire: photo/first/PB rounds large, ordinary rounds one slat".
- Category: rounds that moved a table deserve a heavier treatment (BRIEF §7), and Earlier should collapse after five rounds.
- Critique B asks for the record kept to identity, title and figure, story, and one foot row, which is D360 itself.
- W3 forwarded it: tiering downward "would contradict the ratified D360".
- Both clients draw the D360 record today (web `feedRow`; phone `HomeWireSlat`).
- The phone sets the course title in condensed caps where the web moved it to title case, a parity gap.

**Canon.**
- D360: the no-photo round "is a compact scorecard on both clients", with one story, and the photograph keeps its own presentation.
- D340 replaced a one-line slat as a loss of presence.
- BRIEF §7: "Do not make every feed item visually equal". It is still open as `spec/inbox.md` #22, "whether a personal best is allowed to be bigger".

**Options.**
- **(1) Keep D360** and finish the compatible asks: collapse Earlier, and give the phone's course title the web's title case.
- **(2) Tier upward.** The D360 record is the floor; a personal best, a first round and a sub-80 get a heavier treatment from flags `home_feed` already carries. A decision entry. "Moved a table" would need `home_feed` to carry points, month rank and cap: a migration.
- **(3) Tier downward** (the craft ask). One-line slats for ordinary rounds, amending D340 and D360 on both clients and rewriting their tests. The reaction and Receipt foot is lost unless the slat keeps one.
- **(4) A hybrid:** records for Today and This week, slats for Earlier.

**Recommendation: (1) for Oct 1, and (2) as the ruling on inbox #22.** (2) answers BRIEF §7 without undoing D340's reason, and it needs no data for the flags that exist.

**Blocked until ruled:** the wire's density cells (craft and category Home); inbox #22.

### Q18 · Band words on a 30-day average
**The question.** The Golfers board names each buddy's 30-day average with a band word ("beat their number by …"). Bands are defined per round. May they name an average?

**What the source says.** Both clients apply `bandName` to `friends_board`'s 30-day average (web `csBoardBand`; phone `FriendsBoard.Row.band`), under "vs playing HCP · plus is better".

**Canon.**
- Spec §2.2 defines the bands per round, and D260 says the five labels do not move.
- But D245 rules the Golfers form lens "displayed as a **band**", and D281 names it with `bandName`. Canon allows it as built.

**Two defects found beside it** (no ruling needed):
- The board labels its figure "vs playing HCP" (the index times the league's allowance), but the SQL averages against the index at 100%. So a round can sit in a different band on the board than on its own receipt (L-01). Fix the label or the read.
- The phone's head "THE BOARD" breaks TERMINOLOGY A-3 ("the friends ranking is **not** the board"); the web has already fixed it.

**Options.**
- (1) Keep as built.
- (2) Drop the band word on the board; keep the figure and the beats count.
- (3) A separate form vocabulary: a TERMINOLOGY row, a producer on each client and a lint (preflight pins the five words).
- (4) Copy only: an "on average" gloss beside the band.

**Recommendation: (4).** It keeps D245 and D281, and it tells the golfer the word describes an average. None of the options needs a migration.

**Blocked until ruled:** the Golfers board's R cells.

### Q19 · "Around your buddies" when a golfer has no buddies
**The question.** The web's feed head is always "Around your buddies", even when every row is the golfer's own. Condition it, rename it, or keep it?

**What the source says.**
- The web prints the ruled head over whatever `home_feed` returns, and reuses it as a lead eyebrow.
- The phone never prints it: its head is "The wire", drawn only without datelines.

**Canon.**
- TERMINOLOGY §2.2 keeps "Around your buddies" because it is "the feed's true scope" (D217, D218).
- TERMINOLOGY §3.2 lists "the wire" as a design word never shown on screen, and names AROUND YOUR BUDDIES as the on-screen head.
- **Conflict:** UI_SYSTEM prints THE WIRE on purpose (`surfaces/home.md`; the blind-review request to remove it was "Declined"), as do D287 and IOS-046.

**Options.**
- (1) Keep it always.
- (2) "Your rounds" when no buddy round is in the list, on both clients.
- (3) No head; the datelines lead.
- (4) A scope-neutral name.

Each is a TERMINOLOGY §2.2 amendment with a decision entry, and no migration.

**Recommendation: (2),** and settle the conflict for TERMINOLOGY. It is the shipped vocabulary table (D249), and "the wire" is its own named design word. The phone's "The wire" head then becomes a defect with one fix on each client.

**Blocked until ruled:** the feed head on both clients.

### Q20 · "2 days left" and "3 days": one way to count days
**The question.** With a Ryder and the month both ending Sep 30, the Ryder says "2 days left" and the month clock says "3 days" on Sep 28. Which count is right, and on whose clock?

**What the source says.**
- **The Ryder eyebrow** excludes today, on both clients.
- **The month clock** includes today, on both clients.
- **The phone's Home month line** excludes today, so the phone disagrees with itself.
- **Three web month counts** round an instant difference, so they change with the time of day.
- **The server's fields** exclude today: `native_home.season.days_left`, on the season's timezone, and events carry `tz`.
- **The Ryder taunt push** counts on UTC.
- **The clients** count on the device's clock.

**Canon.** D246 (`days_left` is produced by `native_home`, "on the SEASON's timezone rather than the device's", in calendar days); D378(vi) (the league's date). No rule says whether today counts.

**It is part defect, part decision.**
- **Defect** (D201, L-44 and D246's calendar-day rule): one fact counted three ways inside each client, and the web's instant-rounded counts.
- **Decision:**
  1. Exclude today everywhere ("N days left"; "closes tonight" or "last day" at the end), which matches every server field.
  2. Include today everywhere.
  3. No arithmetic: "through Wed Sep 30".
  4. Separately: count on the league's or event's timezone rather than the device's.

**Recommendation: (1), counted on the league's or event's timezone.** It agrees with the server and D246. The month clocks change on both clients. The push's UTC count is a later migration.

**Blocked until ruled:** the month clocks' copy on both clients.

### Q21 · "LAST FIVE" in a section head's count slot (a defect; recorded)
**Status: a defect against UI_SYSTEM §16A.2. No ruling is needed unless the owner prefers §8.**
- §16A.2: "The right-of-rule slot on a section head carries a count and nothing else — not a date, not a range, not a filter, not a link". It names "a filter (`LAST FIVE`)" as the example.
- §8 lists `LAST FIVE` among its examples of what the slot may hold.
- Both landed in one commit. §16A was "added after the blind review" and names the case, so it governs.
- **The fix, on each client:** the window moves into the label ("Form · last five"), and the slot keeps a count ("Two of five" is a count).
  - Web: `formRowHtml`.
  - Phone: `CredentialCopy.formCount`, the head-to-head slot, and the Golfers board's `LAST 30 DAYS`.
- Canon cleanup: strike §8's examples and the same lines in the `CSSectionHead` doc and two surface specs.

### Q22 · The finished Ryder's MVP
**The question.** The finished Ryder names its MVP only inside the completion board post. Should the finished room show the MVP, and from what data?

**What the source says.** The MVP is computed once in `resolve_session` (best record, then total vs-playing-HCP, `limit 1`, with no final tiebreak) and written only as prose into the board post. No column or read returns it, and neither client has an MVP string.

**Canon.**
- `spec/ryder-v1.md`: the MVP is "computed and NAMED on the recap board post". Today conforms.
- D62: completion "mints the shared team trophy + MVP", but no MVP record or trophy is minted.
- CLAUDE.md says "MVP + shared trophies" is live.

**Options.**
- (1) A migration adds the MVP (the player and their record) to the event, written by `resolve_session` and backfilled, and both clients' finished plates read it.
- (2) Both clients compute it from the duels they hold. That is a second producer of a server fact (D296, D355b), which can break a tie differently.
- (3) Leave it on the board.

**Recommendation: (3) for Oct 1, then (1).** Correct D62's and CLAUDE.md's claims now, or mint the trophy with (1).

**Blocked until ruled:** the finished room's MVP moment (the owner and craft events cells).

### Q23 · "Share the card": the ceremony's button, and what it shares
**The question.** The finish ceremony's button says "Share the card". TERMINOLOGY T-01 says "card" is the person. D380 says a posted round shares "the card and the link together". What does the button say?

**What the source says** (web at `b8a61266`; phone at `de3eaf35`).
- **Web.**
  - The ceremony's "Share the card" shares the **card only, with no link**. That is a defect against D380.
  - Its `_ceremonyOwnsShare` flag is set but never read, so the epilogue's own share door shows too.
  - The epilogue says "Share your round" (card plus link).
- **Phone.**
  - The ceremony, epilogue and receipt say "Share the card" (the epilogue also says "Share your first card").
  - They open a preview whose button is "Share" (card plus link).
- The two clients' epilogue labels differ, which is a parity defect.

**Canon.**
- T-01 and TERMINOLOGY row 88 ("'card' is the person").
- D380 ("One Share from a posted round: the card and the link together").
- D131 already listed "Share the card" among the colliding senses of "card". D294 and D295 later used "the card" for the scorecard.

**Options.**
- (1) "Share your round" everywhere.
- (2) "Share", D380's own word.
- (3) Keep "Share the card", and amend T-01 to allow the artifact.
- (4) "Share the scorecard" on the receipt only.

**Recommendation: (1),** and fix the web ceremony to share through `csShareRound` (the card and the link), with one share door per posted round. Session A's DEC-02 recommends the same wording, by T-01.
- It is what D380 shares, and it cannot be read as the golfer's card.
- The web epilogue already says it.
- A copy entry, with no migration.

**Blocked until ruled:** the ceremony, epilogue and receipt labels on both clients. The web's link omission is a defect and is not blocked.

### Q24 · The Door's wordmark
**Status at `fd27ace4`.** Session B's one lockup (`.cs-lockup`: the pennant plus "Cup Season" in the `name` role, the phone masthead's geometry) now signs the phone-width header, the desk sidebar, the public shell and get, support and legal (5498a79f, merged at f6cb4760; `tests/lockup-browser.mjs`, 192 checks). **The Door alone keeps its serif name**, on root's ruling that this is the owner's brand call. UI_SYSTEM §12.3 now carries a note on the one lockup (1688c9d7, at fd27ace4).

**The question.** Does the Door keep its serif "CUP SEASON", or sign with the lockup like every other surface?

**Canon.**
- D358 rules only the mark (the pennant "wherever Cup Season signs its identity"), not the wordmark's face.
- IOS-046 moved the phone's masthead to the board face ("The artboards won").
- UI_SYSTEM §12.3 stated a mono wordmark, which B's note now places in the Tracer era. A re-cut is reserved to the owner.
- `brand/README.md` (2026-08-06): "The door's seared serif 'CUP SEASON' is the door's voice, not the lockup's."
- The owner's 2026-09-14 board survives only as a path in a review file; the image is not in the repo, and no decision entry records it.
- The phone's Door already agrees with the lockup: its entry crest is condensed caps, and its welcome stage prints no wordmark text.
- The web Door shows three serif lines, where UI_SYSTEM §1.4 allows "one appearance per viewport, maximum". That is a defect whatever the ruling.

**Options.**
- (1) **Keep the serif name on the Door,** as a named exception: the Door's voice. For parity the phone's crest would change to match.
- (2) **The Door takes the lockup** like every other surface. One change on the web Door; the phone already matches.
- (3) **The lockup's name on the Door, and the Door's serif kept for its statement**, the sentence under the name. This is the split `brand/README` already draws between "the door's voice" and "the lockup". Web Door only; the phone already matches. It also takes one serif line off the Door (§1.4).
- (4) A full re-cut (regenerating the lockups and the og-image). Changes under `brand/` are the owner's alone (SESSIONS §2).

Each needs a decision entry, and (1) needs the README's sentence restated as the rule.

**Recommendation: (3).**
- It gives the judges their one lockup (the consistency cells on the Door, Home, the desk and the public pages).
- It keeps the serif the owner's own board chose for the Door, as its voice.
- It matches the phone's Door with no native change.
- It clears one of the Door's three serif lines.

**Blocked until ruled:** the web Door's name; the §1.4 serif count on the Door.

### Q25 · The product-wide `.btn` label role
**The question.** Should the web's `.btn` label take UI_SYSTEM §7.1's `name` role, as the phone's buttons already do?

**What the source says.**
- The web's in-app `.btn` is system sans at 14px and weight 600, with a 46px minimum height, at 118 sites. 14px is not one of the type roles.
- Session B moved get's and support's `.btn` and the public shell's action to the `name` role (3588886b, merged at f6cb4760). Root ruled that the in-app `.btn` waits for this question.
- The phone's primary and secondary styles use `.csType(.name)` (condensed caps, 17) at 50pt.

**Canon, and where it conflicts.**
- §7.1: the primary is "50pt … label `name` 17". The `name` role is Plex Condensed SemiBold 17/15, uppercase.
- §1.1 gives controls to SF Pro, and §1.2's body row says "600 for buttons".
- §7.1's "`brand` fill" is out of date: D359 moved primaries to `act`.

**Options.**
- (1) The web takes `name` 17 and a 50px height; strike §1.1 and §1.2's button text.
- (2) Both clients move to body 600; amend §7.1.
- (3) The desk keeps sans as its own shape, with an entry.

None needs a migration.

**Recommendation: (1).**
- The phone already ships §7.1, the component rule is more specific than the role table, and D234 wants one component language.
- Fix §7.1's fill to `act` in the same entry.

**Blocked until ruled:** session B's shared `.btn` work (W6).

### Q26 · The head over Ryders, Majors and weekends: "YOUR MOMENTS" or "MATCHES & WEEKENDS"?
**The question.** Compete's second section head is "YOUR MOMENTS" on both clients. TERMINOLOGY A-4 argues for "MATCHES & WEEKENDS". Which ships?

**Evidence.** Forwarded by W5 (merged at `4a703402`). Preflight check 25 fails a push that prints "MATCHES & WEEKENDS". The web prints "Your moments" (`index.html` Compete lists); the phone's `CompeteRoot.Head.moments` is YOUR MOMENTS.

**Canon.**
- `OWNER_RULINGS.md` R-D ("The tabs are Compete and Golfers — DECIDED") names YOUR SEASONS and YOUR MOMENTS as the heads inside Compete. Its own close lists this as "still open after this sitting: the section head (`YOUR MOMENTS` ships, `MATCHES & WEEKENDS` argued)".
- `TERMINOLOGY.md` A-4: "'Moment' is a designer word and never a label". It is also `posts.moment`, a schema word.
- The decision log's named conflict, inside D254, lets the ruling win, turns check 25 to guard it, and sends "the question … to the owner in the ship report, in one sentence, with A-4's reasoning attached". It was never answered.
- W5 adds that D297's class-3 amendment also keeps R-D pending.

**Options.**
- **(a) YOUR MOMENTS, as ruled.** No change: it ships on both clients, and check 25 guards it. A one-line entry closes the conflict.
- **(b) MATCHES & WEEKENDS, as A-4 argues.**
  - Both clients' head producers change.
  - Check 25 flips direction, and TERMINOLOGY row 25 closes.
  - A decision entry resolves the conflict against R-D.
- **(c) A third wording** that names what the section holds without either word.

**Recommendation: (a).** It is the owner's own word, it ships and is lint-held on both clients, and A-4's objection is a schema overlap no golfer sees. Closing the conflict in writing matters more than which word wins.

**Blocked until ruled:** the conflict entry; the Compete head's wording in round 2.

### Q27 · The league's name when a Pro resumes setup
**The question.** When a Pro comes back to a league still in setup, should step 1 prefill the league's name, or offer to rename it?

**Evidence.**
- Forwarded by W5.
- Critique B (wizard, P3 "The wizard never shows the league's name"): step 1's `#setName` is empty, with a placeholder clipped at 375, while the desk sidebar already shows the league's name (`wizard--step-1-league--1280--light.png`, `wizard--step-1-league--375--dark.png`). B's fix: prefill the field when resuming, and title the aside with the name.

**Canon.** D346 ("an editable starting point"; retain a known created league for a safe retry; "choosing frequency alone never overwrites custom rules"); D111 (the lock goes through `lock_league`).

**Options.**
- **(a) Prefill the field with the league's current name, editable.** Saving writes the same league. Web wizard step 1 and the phone's `WizardScreen`. A client change only if the resume path already updates the existing league rather than creating one; if not, it needs an RPC and a migration.
- **(b) Show the name as a fact with a Rename link.**
- **(c) Leave it empty** (today): the Pro re-types a name the product already knows.

**Recommendation: (a),** once root confirms that resuming writes to the league already created (D346's "known created league"). A field that shows its current value is the least surprising behaviour, and an empty field over a named league reads as a lost setup.

**Blocked until ruled:** the wizard's step-1 cells; the phone's resume path (N4).

### Q28 · The wizard's presets, and what the desk's empty Compete holds below its band
**The question.** Should the wizard's presets become illustrated choices, or show the season-to-be building as the dials move? And what, if anything, should the desk's empty Compete hold under its band?

**Evidence.**
- Owner judge, wizard P 6 (defect): "Presets as illustrated choices; each dial with its consequence sentence beside it."
- Owner judge, wizard E 6 (content): "Show the future table (members, pot, first tee) building as dials move."
- Owner judge, competition E 7 (content): "One example competition object with the door."
- W5 has made empty Compete the Scoreboard band's "nothing yet" printing with one act button, and its empty second column now stands down at every width (645296bd).
- W5 forwarded both as questions.

**Canon.**
- D346: brief questions, literal answers, and a concise agreement from the exact outgoing settings.
- CONTENT-CEILINGS.md: no invented activity.
- D234: the desk is its own shape.
- UI_SYSTEM §16A.5: an empty state has one act door.

**Options.**
- **Presets.**
  - (a) Illustrated preset cards: new drawing on both clients.
  - (b) A "future table" that builds from the Pro's own inputs: the golfers invited so far, the pot, the first tee. It is truthful because every figure is the Pro's own.
  - (c) Keep W5's grouped dials with sentences.
- **Empty Compete on the desk.**
  - (a) Nothing below the band (today, after W5).
  - (b) A labelled example object, as the Door now does.
  - (c) Real open seasons among buddies to join, which needs a producer.

**Recommendation.**
- **Presets: (c) for Oct 1, with (b) as the next wizard entry.** W5 has just rebuilt step 2. A live preview is the most persuasive of the three and invents nothing, but it is new work on both clients.
- **Empty Compete: (a) for Oct 1.** One door is the ruled empty state, and an example object would be the second authored specimen in the product.

**Also from the native half:** the phone wizard's count omits 7 and 9 without saying why (owner native wizard R 8, "a stepper, or say what the counts mean", `17pro/wizard-dark-large.png`). Recommendation: say what the counts mean. That is a copy line on the phone, and it needs no ruling.

**Blocked until ruled:** the wizard's P and E cells; competition E.

### Q29 · At AX3 the Ryder room's side roster scrolls sideways (a defect; recorded)
**Status: a defect against UI_SYSTEM §16.3 for lane N4. No ruling is needed unless the owner prefers the scroll.**

At accessibility sizes the phone's `CSSideRoster` (the two named groups of UI_SYSTEM §15.5a) scrolls sideways, so the second side is cut at the screen edge (category native events M 7, `17pro/event-live-dark-AX3.png`). The judge's change: "Stack the two sides at accessibility sizes (§16.3) instead of scrolling". §16.3 is the AX3 table, "stated as layouts". Its rule for comparable objects is that the object grows the page and "never scrolls inside itself". The web has no side roster at AX3; its twin is the desk's roster table.

### Q30 · When the golfer is chasing, which door does the lead offer?
**The question.** On the phone's populated Home, the lead says "… and you are the one closing" and "ten back with seven weeks left", but its one door is "Open the season". Should a chasing golfer's lead offer "Add my round", with the season one row down?

**Evidence.**
- Owner judge, native home H 8 (decision): "When the golfer is chasing, the lead's door is 'Add my round'; the season stays one row down" (`17pro/home-populated-dark-large.png`).
- The lead's action text and route come with the served `home_dispatch` item, on both clients. The phone's fallback producers use "Open the season" for season items (`HomeFallbackItems.swift`).

**Canon.** D176 and D216 (the lead card's rungs, and whose door it is); D234 (the server ranks Home for both clients); the brand-new Home's one primary is "Add my round" (W3's ffdcd6b4).

**Options.**
- **(a) Keep "Open the season".**
- **(b) The chasing item's door becomes "Add my round".** This is `home_dispatch`'s action for that item, so it is a migration, and both clients follow.
- **(c) A client-side override** of the served action. This splits the producer, which D234 argues against.

**Recommendation: (b), with Q10's and Q4's ranker changes after launch.** All three touch `home_dispatch`, and they should be one migration and one decision entry.

**Blocked until ruled:** the owner native home H cell.

### Q32 · Toolbar Close at about 42.6pt in partial-detent sheets
**The question.** On iOS 26 a sheet at a partial detent is drawn inset and scaled (386/402 = 0.960). Every such sheet's toolbar Close therefore lands at about 42.6pt on the glass, under the 44pt floor: `RateCourseSheet`, and the `.medium` sheets that use `csCloseButton`. E fixed the inline Closes with a 48pt target (`.fittedSheet`, 7ad93aef). A toolbar item is sized by the system. Accept it, or move those sheets' dismiss inline?

**Canon.** UI_SYSTEM §16.2 (44pt targets); Apple's own toolbar sizing; HUMAN.md's device rows.

**Options.**
- (a) **Accept as a device-or-human item**, named in HUMAN.md, with a thumb test on a device. Root has accepted it on those terms.
- (b) Move those sheets' dismiss inline, with the `.fittedSheet` 48pt target.

**Recommendation: (a) for Oct 1, then (b) if the device test misses.** The shortfall is the platform's scale, measured, not a drawn control. An inline Close changes each sheet's layout the day before launch.

**Blocked until ruled:** nothing on the launch path.

### Q33 · Does "the live act keeps ember" (L-40) cover the when-fork's "Right now" before any round is live? (DEC-N4-3)
**The question.** The phone's `IntentSheet` cites L-40 to paint "Right now" in ember, before any round exists. Both critics read D359 as ink until a round is live. Which holds?

**Canon.** L-40; D359/F11 (ember is active competition); UI_SYSTEM §16A.6.

**Options.**
- (a) Ink for both answers: nothing is live on the fork.
- (b) Keep ember on "Right now", as the source reads L-40.

**Recommendation: (a),** as session A recommends. Ember arrives with the live round, and a choice between two ordinary actions is not competition. Phone only (`IntentSheet.swift:117-120`); the web has no fork.

**Blocked until ruled:** N4-113; part of TPN-17.

### Q34 · Three canon tensions the native detector found (DEC-N4-5)
**The question.** Three pairs of rules disagree. Which one governs in each pair?
1. UI_SYSTEM §9.1 keeps "abbreviate first, ellipsis last" for the slat and the Book, while the program brief and SESSIONS §5 say long names wrap whole.
2. §10.1 puts one brand (ember) dot on the course contour's hardest hole, against D359/F11 (ember for competition and identity only).
3. §16.2's carve-out for the star rail, against D289, which put one-tap rating on a rail with no stepper beside it.

**Options.**
- (a) The newer rule governs each time: names wrap; ember leaves the contour dot; the star rail's targets meet 44pt.
- (b) The older section stands, with a recorded exception.

**Recommendation: (a) for (1),** since the program brief rules it and N4-086 already assumes it. (2) and (3) are yours, and nothing is blocked today. Of the two, I lean to (a) on (2), because D359 is the colour ruling the rest of the product now obeys.

**Blocked until ruled:** N4-086 (on (1)); nothing else today.

### Q35 · The Cup Final's one sentence (DEC-01)
**The question.** The Cup Final is stated two ways. Which sentence states it everywhere?
- "Scored fresh": spec §14.3, D126, the endgame line, the phone's covenant.
- The monthly-counting disclosure: D212 and D346, in both agreements.

**Canon.**
- D346 records the CONFLICT: the engine ranks the Final by the monthly cap, not fresh. It leaves a truly fresh Final to the owner.
- Spec §14.3; D126; D212.

**Options.**
- (a) Keep "scored fresh" and add the counting-limit clause wherever the Final is stated, which is true of today's engine.
- (b) Retire "scored fresh" for the counting-limit wording everywhere.
- (c) Make the Final genuinely fresh: a mechanic change, with a decision entry first and a migration.

**Recommendation: (a),** as session A's parity pass recommends. It is the only option true today with no mechanic change, and its words land on both clients through the endgame producers.

**Blocked until ruled:** N4-200's and N4-208's Final words, and their web halves; `tests/fixtures/endgame.json` regenerates.

### Q36 · Does a live moment keep an ember rail?
**The question.** The board's moment rows keep a 3px ember rail: the web's `.momrow`, whose comment says "a live moment keeps its ember rail", and the phone's `MomentRow`, which draws it on every moment, including a personal best or a buddy request (TPN-19). UI_SYSTEM §0.3 retired the card spine, and D359 reserves ember for competition. Keep the rail for live moments, or retire it?

**Evidence.** DX's TP-09 leaves `.momrow` open at `fd27ace4` (DETECTOR.md), and DXN's TPN-19 finds the phone's rail on every moment.

**Canon.** UI_SYSTEM §0.3 ("The 3.5pt spine leaves the card edge and becomes the 44pt rank rail"); D359/F11; D265 and D266 (the spine's retirement).

**Options.**
- (a) Retire the rail on both clients. A live moment says so with the ember dot and an agate eyebrow, as W3 did for Home's hero (ffdcd6b4) and W1 for the live cards (ab687232).
- (b) Keep a rail for live moments only, as a named exception in §0.3. The phone's rail on non-live moments goes either way.
- (c) Keep it as it is.

**Recommendation: (a).** It finishes the retirement both clients have already carried out everywhere else, and it removes the one place ember marks something that is not competition (the phone's personal-best moments).

**Blocked until ruled:** TP-09's last rule; TPN-19.

### Q37 · Whose words, when canon names none? (DEC-COPY)
**The question.** Where the two clients say one fact two ways and no ruling picks the words, whose words become the one producer's?

**Where it applies** (session A's parity pass): Home's fallback eyebrows, Compete's empty head with buddies, You with no rounds, the Ryder taunt's on-state, the season-two invitation row, and the season clash head.

**Canon.** D234 (one set of producers); L-34.

**Options.**
- (a) The Kit's words, pinned in both suites.
- (b) The web's words.
- (c) Row by row.

**Recommendation: (a) where the Kit is the older producer** (most of these), otherwise row by row. This is session A's recommendation, and the same rule root applied to the covenant's ending (8b87a90d).

**Blocked until ruled:** the six rows' final words. No mechanic moves.

## D · Owner actions owed (not questions)

These need the owner's hands, not a ruling.

- **X41 · Broke 80 on a nine.**
  - The server half: a new migration is needed (none exists at `de3eaf35`). It makes `home_feed.is_sub80`, its prior-window check and every other sub-80 producer require `holes_played = 18`. The owner applies it with `supabase db push`.
  - The client half: the web guard is lane W3's, and the phone's `HomeWireCopy` guard is lane N4's.
  - With the client guard in place, either deploy order is safe (CLAUDE.md, deploy-skew safety).
  - It is critique's CQ-01 and the category judge's P0.
- **X42 · The public plan's "in".**
  - The server half: a new migration so that `the_plan_link`'s public card counts only an explicit yes as in (today `coalesce(rsvp,'in') <> 'out'`). The owner runs `supabase db push`.
  - The client half: the in-app producer is lane W2's.
  - It is CQ-04 and a category P1.
- **Human proof.** HUMAN.md's gates are NOT RUN: G1–G4 need three people who have never opened Cup Season, on their own phones, and D1–D13 are the owner's device checks, including finishing a live round (D12) and the album's retry (D13). No capture or test can pass them.
- **Pushes and deploys.** Nothing after `cf401dee` is pushed (SESSIONS §0). Every web push, `db push`, functions deploy and TestFlight upload waits on the owner's yes to root.
- **Three defects found or raised again while writing this memo.**
  - The `?cs_home_state` hatch lifted the Door on any host (X37). Found by C from the code; root confirmed it on a prod-like server (`cf401dee` lifted the Door). **Fixed (45d40eb3):** the Door stays up, with the shell inert, unless the hatch's fixture is served. The exposure is live on cupseason.app until the ship.
  - The LEDGER's X37 line printed the owner's handle. **Fixed (ba6935a5):** it names the handle by role. History is not rewritten, since the handle had been public in `index.html` as the old placeholder.
  - Code-audit B25, the install nudge re-showing after dismiss and sitting over the composer (Q14). **Fixed (6c5f251b).**
- **B's held migration, `d30f1ecb`.** Home's invitation says "See the terms before you're in", by patching `home_dispatch` in migration `20261211094500_the_terms_before_youre_in.sql`.
  - It is idempotent and restates the grants.
  - It is proven on a disposable PostgreSQL 17 cluster (the full chain).
  - It was reverted on B's branch at `d355b115`, so it is held off main.
  - **Owner action:** take `d30f1ecb` from `claude/ten-w6-shared-2026-09-28` and `supabase db push` when you want it.
  - Its twins, when taken: `HomeFallbackItems.swift:100` and `SyntheticWorld+Home.swift:143` (N4), and the web fixture line.
- **X42 in round 2.** The public plan link's "are in" is the top open item in round 2: category P0, owner P1. It still needs its migration written; none exists on integration.
- **The clash lead's sentence** (`home_dispatch`, `20261006093000:243`) hides who holds the week. Root lists it as database owed, and it rides with Q10.

## E · Recorded by root, with no question
- **The covenant's ending uses the phone's words on both clients** (L-34). Done at 8b87a90d (merged with W6): the web's ending is `JoinLeague.endingLine` word for word, and the structure is its own fact. Q2 lists the other two-squad producers.
- **Root's rulings sent to session B with GO.**
  - The Door keeps its serif until the owner rules Q24.
  - One index label per object: YOUR NUMBER on the viewer's own figure, and "Handicap index" on another golfer's card (57ca5eee; the phone's `YouScreen.swift:328` twin goes to N4).
  - The in-app `.btn` type role is the owner's (Q25).
  - The index-label ruling also answers session A's DEC-N4-4 for the index. The live seat's "PLAYING HCP" names a different figure, the index times the allowance.
- **The wizard's "best four" is right** (W5, root: "resolved, not a defect"). Standard is best 3 with a two-round minimum, and the fixture league is a customised Standard (`counting_cap` 4). W5's `1d6ed619` now says "Custom, built on Standard" when the dials leave a preset.
- **Counsel should see one rename.** W4 renamed the "Prize Pool Disclaimer" to "The pot" in `legal.html` and `legal/*.md`, following TERMINOLOGY T-12 (0fca89d5). Every other clause is counsel's text, unchanged. It ships with the next web push, and a revert is one line.
