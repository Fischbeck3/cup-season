// Cup Season — IOS-034 · what the home screen may know, and for how long.
//
// The widget draws strings somebody else produced, so the interesting rules
// are all in the snapshot: money can never reach it, time is never lied about,
// and a stale read offers no door. Each is a value here rather than a habit in
// the drawing code — a widget is the one surface nobody looks at while they
// are building it.

import Testing
import Foundation
@testable import CupSeasonKit

struct WidgetSnapshotTests {
  static func facts(_ pairs: [(String, String)]) -> [DispatchSnapshot.Fact] {
    pairs.map { .init(label: $0.0, value: $0.1) }
  }

  @Test("L-10 · the money fact cannot reach a home screen, whoever passes it")
  func moneyNeverRides() {
    let s = DispatchSnapshot(seasonRow: "FELLAS · WEEK 7 OF 26",
                             facts: Self.facts([("YOUR NUMBER", "12.4"), ("LAST", "84 · SAT"),
                                                ("NEXT", "SAT · PAPAGO"), ("STILL OWE", "$50")]))
    #expect(s.facts.count == 3)
    #expect(!s.facts.contains { $0.label == "STILL OWE" })
    // and the same through a round trip, since the filter runs in init
    let back = try? JSONDecoder().decode(DispatchSnapshot.self, from: JSONEncoder().encode(s))
    #expect(back?.facts.count == 3)
  }

  @Test("every money label the strip could produce is refused, not just the exact one")
  func moneyIsMatchedByMeaning() {
    for label in ["STILL OWE", "still owe", "Owe", "THE POT", "pot", "BUY-IN"] {
      let s = DispatchSnapshot(seasonRow: nil, facts: Self.facts([(label, "$50"), ("LAST", "84")]))
      #expect(s.facts.map(\.label) == ["LAST"], "\(label) reached the home screen")
    }
  }

  @Test("L-44 · past a day it says so, and stops offering the verb")
  func staleness() {
    let now = Date()
    let fresh = DispatchSnapshot(seasonRow: nil, facts: [], leadHeadline: "Galen posted 79",
                                 leadVerb: "See it", savedAt: now.addingTimeInterval(-3600))
    #expect(!fresh.isStale(now: now))
    #expect(fresh.verb(now: now) == "See it")
    #expect(fresh.asOf(now: now).hasPrefix("AS OF "))
    #expect(!fresh.asOf(now: now).contains("OPEN TO REFRESH"))

    let old = DispatchSnapshot(seasonRow: nil, facts: [], leadHeadline: "Galen posted 79",
                               leadVerb: "See it", savedAt: now.addingTimeInterval(-25 * 3600))
    #expect(old.isStale(now: now))
    #expect(old.verb(now: now) == nil, "a day-old door was still being offered")
    #expect(old.asOf(now: now).contains("OPEN TO REFRESH"))
    // the headline itself stays: it was true when it was read, and it says so
    #expect(old.leadHeadline == "Galen posted 79")
  }

  @Test("the edge is 24 hours exactly, and it is the same edge both ways")
  func theEdge() {
    let now = Date()
    let justUnder = DispatchSnapshot(seasonRow: nil, facts: [], leadVerb: "Go",
                                     savedAt: now.addingTimeInterval(-(24 * 3600 - 1)))
    let exactly = DispatchSnapshot(seasonRow: nil, facts: [], leadVerb: "Go",
                                   savedAt: now.addingTimeInterval(-24 * 3600))
    #expect(justUnder.verb(now: now) == "Go")
    #expect(exactly.verb(now: now) == nil)
  }

  @Test("a stale snapshot's tap lands on Home, never on a route it can no longer promise")
  func theDoor() {
    let now = Date()
    let live = "cupseason://live"
    let fresh = DispatchSnapshot(seasonRow: nil, facts: [], leadRoute: live, savedAt: now)
    #expect(fresh.url(now: now).absoluteString == live)
    let old = DispatchSnapshot(seasonRow: nil, facts: [], leadRoute: live,
                               savedAt: now.addingTimeInterval(-48 * 3600))
    #expect(old.url(now: now).absoluteString == "cupseason://home")
    // no route at all is Home too — never nil, never a crash on a missing door
    #expect(DispatchSnapshot(seasonRow: nil, facts: []).url(now: now).absoluteString == "cupseason://home")
  }

  @Test("the App Group round-trips, and a container that is not there is not a crash")
  func theContainer() throws {
    let suite = "cupseason.widget.tests.\(UUID().uuidString)"
    let d = try #require(UserDefaults(suiteName: suite))
    defer { d.removePersistentDomain(forName: suite) }
    #expect(DispatchSnapshot.read(d) == nil)
    let s = DispatchSnapshot(seasonRow: "FELLAS · WEEK 7 OF 26",
                             facts: Self.facts([("YOUR NUMBER", "12.4")]),
                             leadHeadline: "Galen posted 79", leadVerb: "See it")
    #expect(s.write(d))
    let back = DispatchSnapshot.read(d)
    #expect(back?.seasonRow == "FELLAS · WEEK 7 OF 26")
    #expect(back?.leadHeadline == "Galen posted 79")
    #expect(back?.facts.first?.value == "12.4")
    // a nil container (the App Group not yet provisioned) writes nothing and
    // says so, rather than throwing on a device the owner has not re-signed
    #expect(s.write(nil) == false)
  }

  @Test("the feed copies the strip's sentences; it never writes one of its own")
  func theFeedProducesNothing() {
    let strip = MeStripCopy.Strip(
      slots: [.init(fact: .myNumber, label: "YOUR NUMBER", value: "12.4", door: .yourCard, voiceOver: "your number, 12.4"),
              .init(fact: .myMoney, label: "STILL OWE", value: "$50", door: .yourCard, voiceOver: "still owe, $50")],
      seasonRow: .init(leagueId: UUID(), text: "FELLAS · 2ND OF 8", parts: ["FELLAS", "2ND OF 8"]))
    let s = DispatchSnapshotFeed.make(strip: strip, lead: nil)
    #expect(s.seasonRow == "FELLAS · 2ND OF 8")
    #expect(s.facts.map(\.value) == ["12.4"], "the money slot rode along")
    #expect(s.leadHeadline == nil)
    #expect(s.verb() == nil, "a verb was invented with no lead to carry it")
  }

  @Test("nothing to draw writes nothing — a failed read never blanks a good snapshot")
  func anEmptyLoadIsNotAWrite() throws {
    let suite = "cupseason.widget.tests.\(UUID().uuidString)"
    let d = try #require(UserDefaults(suiteName: suite))
    defer { d.removePersistentDomain(forName: suite) }
    DispatchSnapshot(seasonRow: "FELLAS · 2ND OF 8", facts: []).write(d)
    let empty = MeStripCopy.Strip(slots: [], seasonRow: nil)
    #expect(DispatchSnapshotFeed.publish(strip: empty, lead: nil, owner: nil, defaults: d) == false)
    #expect(DispatchSnapshot.read(d)?.seasonRow == "FELLAS · 2ND OF 8", "an empty load wiped the widget")
  }
  @Test("the timeline includes the exact expiry even if the OS postpones a reload")
  func expiryEntry() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let s = DispatchSnapshot(seasonRow: "Regulars", facts: [], savedAt: now.addingTimeInterval(-3600))
    let dates = s.timelineDates(now: now)
    #expect(dates.count == 2)
    #expect(s.verb(now: dates[1]) == nil)
    #expect(s.isStale(now: dates[1]))
    #expect(s.timelineDates(now: dates[1]) == [dates[1]])
    let future = DispatchSnapshot(seasonRow: "Regulars", facts: [], savedAt: now.addingTimeInterval(3600))
    #expect(future.isStale(now: now))
  }

  @Test("legacy persisted facts are filtered when read and a sign-out removes the snapshot")
  func persistedPrivacy() throws {
    let suite = "cupseason.widget.privacy.\(UUID().uuidString)"
    let d = try #require(UserDefaults(suiteName: suite))
    defer { d.removePersistentDomain(forName: suite) }
    let s = DispatchSnapshot(seasonRow: "Regulars", facts: [.init(label: "LAST", value: "84")])
    var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as? [String: Any])
    json["facts"] = [["label": "BUY-IN", "value": "$50"], ["label": "LAST", "value": "84"]]
    d.set(try JSONSerialization.data(withJSONObject: json), forKey: CSAppGroup.snapshotKey)
    #expect(DispatchSnapshot.read(d)?.facts.map(\.value) == ["84"])
    DispatchSnapshot.forget(d)
    #expect(DispatchSnapshot.read(d) == nil)
  }

  @Test("an old account's delayed Home cannot refill a cleared widget")
  func accountBoundary() throws {
    let suite = "cupseason.widget.accounts.\(UUID().uuidString)"
    let d = try #require(UserDefaults(suiteName: suite))
    let first = UUID(), next = UUID()
    defer { d.removePersistentDomain(forName: suite) }
    let strip = MeStripCopy.Strip(slots: [],
      seasonRow: .init(leagueId: UUID(), text: "Regulars", parts: ["Regulars"]))
    DispatchSnapshot.claim(owner: first, defaults: d)
    #expect(DispatchSnapshotFeed.publish(strip: strip, lead: nil, owner: first, defaults: d))
    DispatchSnapshot.claim(owner: nil, defaults: d)
    #expect(DispatchSnapshot.read(d) == nil)
    #expect(!DispatchSnapshotFeed.publish(strip: strip, lead: nil, owner: first, defaults: d))
    DispatchSnapshot.claim(owner: next, defaults: d)
    #expect(!DispatchSnapshotFeed.publish(strip: strip, lead: nil, owner: first, defaults: d))
    #expect(DispatchSnapshot.read(d) == nil)
    #expect(DispatchSnapshotFeed.publish(strip: strip, lead: nil, owner: next, defaults: d))
    DispatchSnapshot.claim(owner: next, defaults: d)
    #expect(DispatchSnapshot.read(d)?.seasonRow == "Regulars")
  }

}
