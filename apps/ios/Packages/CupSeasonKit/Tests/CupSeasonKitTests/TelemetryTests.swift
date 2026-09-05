import Testing
import Foundation
@testable import CupSeasonKit

// IOS-024 — the reliability floor's two pure pieces: the two-second dedupe
// window behind `CSTelemetry.event`, and the MetricKit call-stack-tree walk
// that turns a crash into the four-frame `stack` the web's rows carry.

/// `#expect` captures its expression, so a mutating call on a local `var`
/// cannot sit inside it; the value type is driven through a reference here.
private final class Window {
  var w = TelemetryDedupe()
  func admit(_ k: String, at t: TimeInterval) -> Bool { w.admit(k, at: t) }
}

@Suite struct TelemetryDedupeTests {
  @Test func firstSendAdmitsAndTheBurstDoesNot() {
    let w = Window()
    let k = TelemetryDedupe.key("round_posted", ["build": .number(12)])
    #expect(w.admit(k, at: 100.0))
    #expect(!w.admit(k, at: 100.5))
    #expect(!w.admit(k, at: 101.9))
  }

  @Test func theWindowIsTwoSeconds() {
    let w = Window()
    let k = TelemetryDedupe.key("signed_in", [:])
    #expect(w.admit(k, at: 0))
    #expect(!w.admit(k, at: 1.999))
    #expect(w.admit(k, at: 2.0))
    #expect(!w.admit(k, at: 3.0))       // the clock restarts on the send that went through
  }

  @Test func differentPropsAreDifferentEvents() {
    let w = Window()
    #expect(w.admit(TelemetryDedupe.key("post_mode_switch", ["to": .string("holes")]), at: 0))
    #expect(w.admit(TelemetryDedupe.key("post_mode_switch", ["to": .string("gross")]), at: 0.1))
    #expect(w.admit(TelemetryDedupe.key("post_open", ["to": .string("holes")]), at: 0.2))
  }

  @Test func theKeyIsOrderIndependent() {
    let a = TelemetryDedupe.key("x", ["a": .number(1), "b": .string("two"), "c": .bool(true)])
    let b = TelemetryDedupe.key("x", ["c": .bool(true), "b": .string("two"), "a": .number(1)])
    #expect(a == b)
    #expect(a.hasPrefix("x|{"))
    #expect(TelemetryDedupe.key("x", [:]) == "x|{}")
  }

  @Test func nestedPropsCanonicaliseToo() {
    let a = TelemetryDedupe.key("e", ["o": .object(["z": .null, "y": .array([.number(1)])])])
    let b = TelemetryDedupe.key("e", ["o": .object(["y": .array([.number(1)]), "z": .null])])
    #expect(a == b)
  }

  @Test func theTableIsPrunedNotUnbounded() {
    let w = Window()
    for i in 0..<200 { #expect(w.admit("e\(i)", at: Double(i))) }
    // the early keys fell out of the window and were pruned; re-admitting them is fine
    #expect(w.admit("e0", at: 300))
    #expect(!w.admit("e0", at: 301))
  }

  @Test func theProductEventsCarryTheirWebNames() {
    #expect(CSTelemetry.Product.signedIn.rawValue == "signed_in")
    #expect(CSTelemetry.Product.cardSet.rawValue == "card_set")
    #expect(CSTelemetry.Product.leagueCreated.rawValue == "league_created")
    #expect(CSTelemetry.Product.leagueLocked.rawValue == "league_locked")
    #expect(CSTelemetry.Product.roundPosted.rawValue == "round_posted")
    #expect(CSTelemetry.clientError == "client_error")
  }
}

// D234 — the platform stamp. Four callers hand-wrote `platform: "ios"` and
// nothing else did, so `client_events` could not be split by client; the stamp
// now lives in one place on each client and preflight check 22 keeps it there.

@Suite struct TelemetryPlatformTests {
  @Test func everyRowCarriesThePlatform() {
    #expect(CSTelemetry.platform == "ios")
    #expect(CSTelemetry.stamped([:])["platform"] == .string("ios"))
    #expect(CSTelemetry.stamped(["win": .string("fall")])["platform"] == .string("ios"))
    // the caller's own props survive beside it
    #expect(CSTelemetry.stamped(["win": .string("fall")])["win"] == .string("fall"))
  }

  @Test func aCallerWrittenPlatformIsOverwrittenNotMerged() {
    // the whole point: the client names itself in one place, so a caller that
    // types its own — or types the WRONG one — cannot split an event in two
    #expect(CSTelemetry.stamped(["platform": .string("web")])["platform"] == .string("ios"))
    #expect(CSTelemetry.stamped(["platform": .null])["platform"] == .string("ios"))
  }

  @Test func theFourMetricEventsExistAndCarryTheirNames() {
    #expect(CSTelemetry.Metric.appOpen.rawValue == "app_open")
    #expect(CSTelemetry.Metric.homeStateSeen.rawValue == "home_state_seen")
    #expect(CSTelemetry.Metric.ctaTapped.rawValue == "cta_tapped")
    #expect(CSTelemetry.Metric.firstAct.rawValue == "first_act")
    // four, and only four — a fifth added without an entry fails here
    #expect(Set([CSTelemetry.Metric.appOpen, .homeStateSeen, .ctaTapped, .firstAct].map(\.rawValue)).count == 4)
  }

  @Test func theStampDoesNotMoveTheDedupeWindow() {
    // a constant key on every row collapses no burst that was not already
    // collapsing, and splits none that was not
    let w = Window()
    let bare = TelemetryDedupe.key("cta_tapped", ["door": .string("post")])
    let stamped = TelemetryDedupe.key("cta_tapped", CSTelemetry.stamped(["door": .string("post")]))
    #expect(bare != stamped)                       // the row really does carry it
    #expect(w.admit(stamped, at: 0))
    #expect(!w.admit(stamped, at: 1.999))          // the window is still two seconds
    #expect(w.admit(stamped, at: 2.0))
    // two different doors are still two events
    #expect(w.admit(TelemetryDedupe.key("cta_tapped", CSTelemetry.stamped(["door": .string("play")])), at: 2.1))
  }
}

@Suite struct AppOpenGateTests {
  /// `#expect` captures its expression, so the mutating calls run through a box.
  private final class Gate {
    var g = AppOpenGate()
    func foreground() -> Bool { g.foreground() }
    func background() { g.background() }
  }

  @Test func theFirstForegroundCountsAndTheSecondDoesNot() {
    let g = Gate()
    #expect(g.foreground())
    #expect(!g.foreground())
    #expect(!g.foreground())
  }

  @Test func onlyATripThroughTheBackgroundRearmsIt() {
    let g = Gate()
    #expect(g.foreground())
    // a banner, the app switcher, Face ID: `.inactive` and back, never
    // `.background`. None of those is an open, and counting them would inflate
    // the number every rate in the design set is divided by.
    #expect(!g.foreground())
    g.background()
    #expect(g.foreground())
    #expect(!g.foreground())
  }

  @Test func aBackgroundBeforeAnyForegroundStillCountsOnce() {
    let g = Gate()
    g.background()
    #expect(g.foreground())
    #expect(!g.foreground())
  }
}

@Suite struct MetricsStackTests {
  /// A MetricKit-shaped tree, the way MetricKit actually builds it: the ROOT
  /// frame is the innermost (the crash site) and each `subFrames` step is the
  /// caller, so `names` reads inner → outer, `crash → … → main → start`. The
  /// first fixture here was written root-is-main, and the walk was tested
  /// against it; both were wrong together (the fix that turned this around).
  private func tree(_ names: [(String, Int)], attributed: Bool = true) -> [String: Any] {
    var chain: [String: Any]? = nil
    for (name, off) in names.reversed() {
      var f: [String: Any] = ["binaryName": name, "offsetIntoBinaryTextSegment": off, "sampleCount": 1, "address": 4_000_000 + off]
      if let chain { f["subFrames"] = [chain] }
      chain = f
    }
    return ["callStackRootFrames": [chain!], "threadAttributed": attributed]
  }

  private func data(_ stacks: [[String: Any]]) -> Data {
    try! JSONSerialization.data(withJSONObject: ["callStacks": stacks])
  }

  @Test func keepsTheFourInnermostFramesInnermostFirst() {
    // inner → outer: the crash site is the root; main and dyld are the leaves
    let d = data([tree([("libsystem_kernel", 0x500), ("CupSeason", 0x400), ("libswiftCore", 0x300), ("CupSeason", 0x200), ("CupSeason", 0x100), ("dyld", 0x10)])])
    #expect(MetricsStack.frames(fromCallStackTree: d) == "libsystem_kernel+0x500 <- CupSeason+0x400 <- libswiftCore+0x300 <- CupSeason+0x200")
  }

  @Test func theRootFrameIsTheCrashSiteAndIsTheOneRecorded() {
    // the regression: a deep stack must keep its ROOT (the crash) and drop its
    // tail (main), never the other way round
    var chain: [(String, Int)] = [("CupSeason", 0xdead)]
    for i in 1...12 { chain.append(("Foundation", i)) }
    chain.append(("CupSeason", 0x1))   // main
    chain.append(("dyld", 0x0))        // start
    let s = MetricsStack.frames(fromCallStackTree: data([tree(chain)]))
    #expect(s.hasPrefix("CupSeason+0xdead <- Foundation+0x1"))
    #expect(!s.contains("dyld"))
    #expect(s.components(separatedBy: " <- ").count == MetricsStack.keptFrames)
  }

  @Test func aShallowStackKeepsWhatItHas() {
    let d = data([tree([("CupSeason", 0xabc), ("dyld", 0x10)])])
    #expect(MetricsStack.frames(fromCallStackTree: d) == "CupSeason+0xabc <- dyld+0x10")
  }

  @Test func prefersTheAttributedThread() {
    let other = tree([("Foundation", 0x2), ("libsystem_kernel", 0x1)], attributed: false)
    let mine = tree([("CupSeason", 0x4), ("dyld", 0x3)], attributed: true)
    #expect(MetricsStack.frames(fromCallStackTree: data([other, mine])) == "CupSeason+0x4 <- dyld+0x3")
    // none attributed: the first thread
    let d2 = data([tree([("a", 1)], attributed: false), tree([("b", 2)], attributed: false)])
    #expect(MetricsStack.frames(fromCallStackTree: d2) == "a+0x1")
  }

  @Test func followsTheHeaviestBranchOfAFork() {
    // a sampled hang: the busy frame is the root; its callers fork under it
    let light: [String: Any] = ["binaryName": "Light", "offsetIntoBinaryTextSegment": 1, "sampleCount": 2]
    let heavy: [String: Any] = ["binaryName": "Heavy", "offsetIntoBinaryTextSegment": 2, "sampleCount": 9]
    let root: [String: Any] = ["binaryName": "busy", "offsetIntoBinaryTextSegment": 0, "sampleCount": 11, "subFrames": [light, heavy]]
    let d = data([["callStackRootFrames": [root], "threadAttributed": true]])
    #expect(MetricsStack.frames(fromCallStackTree: d) == "busy+0x0 <- Heavy+0x2")
  }

  @Test func garbageAndEmptyTreesGiveAnEmptyStackNotACrash() {
    #expect(MetricsStack.frames(fromCallStackTree: Data()) == "")
    #expect(MetricsStack.frames(fromCallStackTree: Data("not json".utf8)) == "")
    #expect(MetricsStack.frames(fromCallStackTree: Data("{\"callStacks\":[]}".utf8)) == "")
    #expect(MetricsStack.frames(fromCallStackTree: Data("{\"callStacks\":[{\"threadAttributed\":true}]}".utf8)) == "")
    #expect(MetricsStack.frames(fromCallStackTree: Data("[1,2,3]".utf8)) == "")
  }

  @Test func aMissingBinaryNameStillRendersTheOffset() {
    let f: [String: Any] = ["offsetIntoBinaryTextSegment": 0x2a, "sampleCount": 1]
    let d = data([["callStackRootFrames": [f], "threadAttributed": true]])
    #expect(MetricsStack.frames(fromCallStackTree: d) == "?+0x2a")
  }

  @Test func joinCapsAtTheWebsFourHundredCharacters() {
    let long = Array(repeating: String(repeating: "x", count: 150), count: 4)
    let s = MetricsStack.join(long)
    #expect(s.count == MetricsStack.maxLength)
    #expect(MetricsStack.join([]) == "")
    // join takes inner → outer and keeps that order
    #expect(MetricsStack.join(["inner", "outer"]) == "inner <- outer")
    #expect(MetricsStack.join(["1", "2", "3", "4", "5", "6"]) == "1 <- 2 <- 3 <- 4")
  }
}
