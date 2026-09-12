// Cup Season — ONBOARDING (D247, D233, D224; IOS-033).
//
// Four rules these tests exist to hold, and each one is a rule the build could
// silently lose:
//
//   1 · THREE QUESTIONS, and the first is asked in a golfer's units.
//   2 · THE MARKER AND THE HANDLE ARE DEFAULTED — deterministically, so the
//       same golfer gets the same marker twice, and on both clients.
//   3 · THE GATE IS STILL `marker` AND `handle`. Defaulting is not skipping,
//       and CLAUDE.md's own landmine says this line has been wrong before.
//   4 · A DECLINED STARTER LABELS THE STRIP `STARTER` AND NEVER REACHES THE
//       ENGINE. D124 is an owner ruling; this is the assertion that keeps the
//       build inside it.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct OnboardingTests {

  // MARK: - 1 · the three questions, in a golfer's units

  @Test func theHandicapIsAskedInScores() {
    #expect(OnboardingCopy.shootQuestion == "What do you usually shoot?")
    #expect(ScoreBand.allCases.map(\.title) == ["Under 80", "80s", "90s", "100+", "No idea"])
    // The word "index" appears nowhere in the question or its sub — that is the
    // whole point of asking in scores (a persona walk stalled on "I don't know
    // what index means").
    for s in [OnboardingCopy.shootQuestion, OnboardingCopy.shootSub] {
      #expect(!s.lowercased().contains("index"), Comment(rawValue: s))
      #expect(!s.lowercased().contains("differential"))   // L-14
    }
    #expect(OnboardingCopy.shootSub.contains("three posted rounds"))
  }

  @Test func noIdeaImpliesNoNumber() {
    #expect(ScoreBand.noIdea.starter == nil)
    #expect(ScoreBand.noIdea.stripPreview == "— · BUILDING")
    // Every other band implies one, and they run in the right direction:
    // a better scorer has a lower number.
    let named = ScoreBand.allCases.compactMap(\.starter)
    #expect(named.count == 4)
    #expect(named == named.sorted())
    #expect(ScoreBand.eighties.stripPreview == "STARTER 13")
  }

  @Test func ghinIsOffOnboarding() {
    // D247 moves GHIN to the card. Its sentence must SAY where it went — a
    // field that vanishes with no forwarding address is a feature nobody can
    // find again.
    #expect(OnboardingCopy.ghinMovedNote.contains("GHIN"))
    #expect(OnboardingCopy.ghinMovedNote.contains("You"))
  }

  // MARK: - 2 · the defaults

  @Test func theHandleIsDerivedFromTheName() {
    #expect(OnboardingGate.handle(from: "Jerecho Fischbeck") == "jerechofischbeck")
    #expect(OnboardingGate.handle(from: "Ray O'Neill") == "rayoneill")
    // 20 characters, never more — `set_handle` refuses a longer one.
    #expect(OnboardingGate.handle(from: String(repeating: "a", count: 40)).count == 20)
  }

  @Test func aDerivedHandleThatIsIllegalIsCaughtBeforeTheSave() {
    // A one-word nickname derives a handle the server refuses. The card asks
    // rather than failing at `set_handle` with a message about a regex.
    #expect(!OnboardingGate.handleIsLegal(OnboardingGate.handle(from: "JT")))
    #expect(OnboardingGate.handleIsLegal("jer"))
    #expect(OnboardingGate.handleIsLegal("a_b_9"))
    #expect(!OnboardingGate.handleIsLegal("Jer"))        // upper case is not a handle
    #expect(!OnboardingGate.handleIsLegal("jer ome"))
  }

  @Test func theMarkerIsDefaultedDeterministicallyAndIsOneOfTheFourteen() {
    let a = MarkerDefault.assign(handle: "jerecho")
    let b = MarkerDefault.assign(handle: "jerecho")
    #expect(a == b)                                    // a floor that moves is not a floor
    #expect(CSMarkerKeys.contains(a))
    // and different golfers do not all get the saguaro
    let spread = Set(["jerecho", "galen", "jade", "tash", "dev", "ray", "cj", "lc"].map(MarkerDefault.assign(handle:)))
    #expect(spread.count > 1)
    #expect(!MarkerDefault.name(a).isEmpty)
  }

  @Test func theDefaultedMarkerIsTheWebsMarker() {
    // THE PARITY FIXTURE. `tests/app-tests.js` asserts these four EXACT pairs
    // against `csMarkerDefault`. Both run djb2 with a per-step mod over the
    // same key order (the `MARKERS` table generates `CSMarkers.all`), so a
    // golfer's marker is the same on their phone and at the desk — and if
    // either implementation drifts, one of the two suites fails loudly rather
    // than a floor quietly differing between a golfer's two screens.
    #expect(MarkerDefault.assign(handle: "jerecho") == "island")
    #expect(MarkerDefault.assign(handle: "galen") == "lighthouse")
    #expect(MarkerDefault.assign(handle: "jade") == "shark")
    #expect(MarkerDefault.assign(handle: "tash") == "dunes")
  }

  @Test func theMarkerFootnoteNamesWhatWasAssignedAndWhereToChangeIt() {
    // L-24: still the floor, still one of the fourteen, still CHANGEABLE — and
    // the screen has to say so, or a default reads as a decision made for you.
    let note = OnboardingCopy.markerFootnote("The Saguaro")
    #expect(note.contains("The Saguaro"))
    #expect(note.lowercased().contains("tap it"))
    #expect(note.contains("You"))
    // R-14 · and what it is FOR. A default that says only where to change it
    // has not taught the golfer what a marker is, which is the pattern
    // TERMINOLOGY §4 holds this sentence up as.
    #expect(note.contains("your face here until you add a photo"))
    #expect(note.contains("stamp on every round"))
  }

  // MARK: - 3 · the gate is marker AND handle

  @Test func theGateIsMarkerAndHandle() {
    #expect(OnboardingGate.passes(marker: "saguaro", handle: "jer"))
    #expect(!OnboardingGate.passes(marker: nil, handle: "jer"))
    #expect(!OnboardingGate.passes(marker: "saguaro", handle: nil))
    #expect(!OnboardingGate.passes(marker: nil, handle: nil))
    // Whitespace is not a value. The m001 trigger writes neither, but a seeder
    // or a backfill that writes " " would otherwise pass.
    #expect(!OnboardingGate.passes(marker: "  ", handle: "jer"))
    #expect(!OnboardingGate.passes(marker: "saguaro", handle: " "))
  }

  @Test func aTriggerWrittenProfileDoesNotPass() {
    // The signup trigger creates a row with an email-derived display name and
    // neither a marker nor a handle. A row existing proves nothing.
    let trigger = Me.Profile(id: UUID(), display_name: "jerecho", handle: nil, marker: nil, city: nil,
                             home_course: nil, index_current: nil, index_source: nil, photo_path: nil,
                             rounds_count: 0, member_since: nil, is_founder: nil)
    #expect(!OnboardingGate.passes(trigger))
    #expect(!OnboardingGate.passes(nil))
  }

  // MARK: - 4 · the declined starter

  @Test func aDeclinedStarterLabelsTheStripStarterAndNeverReachesTheEngine() {
    let d = UserDefaults(suiteName: "cs.onboarding.starter.\(UUID().uuidString)")!
    StarterIndex.set(.eighties, defaults: d)

    // it is held, and only while the engine has nothing of its own
    #expect(StarterIndex.current(engineIndex: nil, defaults: d) == 13)
    #expect(StarterIndex.current(engineIndex: 11.2, defaults: d) == nil)   // spent at three rounds

    // and it renders as STARTER, never as YOUR NUMBER (L-14)
    let p = Me.Profile(id: UUID(), display_name: "Jerecho", handle: "jer", marker: "saguaro", city: nil,
                       home_course: nil, index_current: nil, index_source: nil, photo_path: nil,
                       rounds_count: 0, member_since: nil, is_founder: nil)
    let slot = MeStripCopy.make(Me(profile: p), upcoming: [], today: "2026-09-05", starter: 13)
      .slots.first { $0.fact == .myNumber }
    #expect(slot?.label == "STARTER")
    #expect(slot?.value == "13")
    #expect(slot?.voiceOver == "starter number, 13")

    // "No idea" writes nothing at all — a guess dressed as a number is what
    // L-44 forbids, and BUILDING is the honest state.
    StarterIndex.set(.noIdea, defaults: d)
    #expect(StarterIndex.current(engineIndex: nil, defaults: d) == nil)
    // On the producer: the assembled strip stands down when BUILDING is all
    // there is to say, so the label is asserted where it is decided.
    let building = MeStripCopy.numberSlot(p, starter: nil)
    #expect(building?.label == "BUILDING")
    #expect(building?.value == "—")
    #expect(building?.isPlaceholder == true)
  }

  @Test func theStarterIsNotAServerValue() {
    // D124's declined form, as an assertion rather than a comment: the client
    // holds the figure and the SERVER's `index_source` is untouched. A profile
    // that has never been written by a starter still reads `app` / nil, and
    // `set_profile` is called with a nil index by the card gate — which is a
    // fact about `CardGateView`, but this is the value that makes it checkable:
    // the strip's STARTER label is reachable with NO server index at all.
    let p = Me.Profile(id: UUID(), display_name: "Jerecho", handle: "jer", marker: "saguaro", city: nil,
                       home_course: nil, index_current: nil, index_source: nil, photo_path: nil,
                       rounds_count: 0, member_since: nil, is_founder: nil)
    let s = MeStripCopy.make(Me(profile: p), upcoming: [], today: "2026-09-05", starter: 20)
    #expect(s.slots.first?.label == "STARTER")
    #expect(p.index_source == nil)
  }

  // MARK: - the crew step's four routes, and the first Home the answer buys

  @Test func theCrewStepOffersFourRoutesAndTheExitIsNotAFailure() {
    let r = OnboardingCopy.crewRoutes
    #expect(r.count == 4)
    #expect(r.map(\.title) == ["Find your friends",
                              "Search by name or @handle",
                              "Text an invite to somebody else",
                              "Nobody yet — I’ll add them later"])
    // contacts is FIRST: it is the only route that can find somebody a golfer
    // cannot name (R-G's whole point).
    #expect(r.first == .contacts)
    #expect(r.last == .later)
    // and the exit is a sentence a golfer can say about themselves, not a
    // "skip" that reads as a failure
    #expect(!OnboardingCopy.CrewRoute.later.title.lowercased().contains("skip"))
  }

  @Test func theAnswerChangesTheFirstHome() {
    #expect(OnboardingCopy.FirstHome.of(buddiesAdded: 0) == .alone)
    #expect(OnboardingCopy.FirstHome.of(buddiesAdded: 1) == .withPeople)
    #expect(OnboardingCopy.FirstHome.of(buddiesAdded: 3) == .withPeople)
  }

  // MARK: - IOS-033 · the link that survives the boot

  @Test func aPendingTokenSurvivesUntilItIsAnswered() {
    let d = UserDefaults(suiteName: "cs.onboarding.link.\(UUID().uuidString)")!
    #expect(PendingLink.first(defaults: d) == nil)
    #expect(!PendingLink.invited(defaults: d))

    JoinIntent.store("FELLAS", name: "The Fellas", defaults: d)
    #expect(PendingLink.first(defaults: d) == .join)
    #expect(PendingLink.invited(defaults: d))
    #expect(PendingLink.doorLine(defaults: d) == "You're joining The Fellas. Sign in to review and join.")

    // A claim outranks a join: a guest pencil is already holding a round.
    ClaimIntent.store(UUID().uuidString, defaults: d)
    #expect(PendingLink.first(defaults: d) == .claim)

    // and a token is retired only by `spend`
    PendingLink.claim.spend(defaults: d)
    #expect(PendingLink.first(defaults: d) == .join)
    PendingLink.join.spend(defaults: d)
    #expect(PendingLink.first(defaults: d) == nil)
    #expect(PendingLink.doorLine(defaults: d) == nil)
  }

  @Test func everyClaimedLinkKindHasADoorSentence() {
    for k in PendingLink.allCases {
      let d = UserDefaults(suiteName: "cs.onboarding.link.\(k.rawValue).\(UUID().uuidString)")!
      switch k {
      case .join:   JoinIntent.store("ABCD", defaults: d)
      case .claim:  ClaimIntent.store(UUID().uuidString, defaults: d)
      case .person: ShareIntent.person.store(UUID(), defaults: d)
      case .plan:   ShareIntent.plan.store(UUID(), defaults: d)
      }
      #expect(k.isPending(defaults: d))
      #expect(PendingLink.invited(defaults: d))
      let line = PendingLink.doorLine(defaults: d)
      #expect(line?.isEmpty == false, Comment(rawValue: k.rawValue))
      k.spend(defaults: d)
      #expect(!k.isPending(defaults: d))
    }
  }
}

/// The fourteen, read from the generated catalogue so a marker added or
/// renamed there does not need this file edited.
private let CSMarkerKeys: Set<String> = {
  Set(MarkerDefault.allKeys)
}()
