import Foundation
import Testing
@testable import CupSeasonKit

struct BetweenRoundsWidgetTests {
  let owner = UUID(), round = UUID()
  let now = Date(timeIntervalSince1970: 1_790_323_200)
  private func detail(tagged: Bool = true, status: String? = nil) -> RoundDetail {
    .init(id: round, profileId: UUID(), ownerName: "Galen", ownerMarker: nil, mine: false, taggedMe: tagged,
      playOn: "2030-09-26", teeTime: "07:10", note: nil, courseLabel: "Papago", courseId: nil,
      myRsvp: status, course: nil, rsvp: [], comments: [])
  }
  private func suite() -> UserDefaults { UserDefaults(suiteName: "cs.widgets.tests.\(UUID())")! }

  @Test func privateLinksRoundTripAndRejectAmbiguity() {
    for kind in BetweenRoundsKind.allCases {
      let destination = WidgetDestination(kind: kind, id: round, owner: owner)
      #expect(WidgetDestination(url: destination.url) == destination)
      let empty = WidgetDestination(kind: kind, id: nil, owner: owner)
      #expect(WidgetDestination(url: empty.url) == empty)
      #expect(WidgetDestination(url: URL(string: destination.url.absoluteString + "&id=\(round)")!) == nil)
    }
    #expect(WidgetDestination(url: URL(string: "https://widget?kind=CSSeasonWidget&id=\(round)&owner=\(owner)")!) == nil)
    #expect(WidgetDestination(url: URL(string: "cupseason://widget?kind=money")!) == nil)
  }

  @Test func signedOutAndLatePreviousSessionsCannotPublish() throws {
    let d = suite()
    DispatchSnapshot.claim(owner: owner, defaults: d)
    let epoch = d.string(forKey: BetweenRoundsSnapshot.epochKey)
    var value = BetweenRoundsSnapshot(owner: owner)
    value.nextTee = .init(try #require(BetweenRoundsCopy.tee(detail(), now: now)), at: now)
    #expect(value.write(d, epoch: epoch))
    #expect(BetweenRoundsSnapshot.read(d) == value)
    DispatchSnapshot.claim(owner: nil, defaults: d)
    #expect(BetweenRoundsSnapshot.read(d) == nil)
    #expect(!value.write(d, epoch: epoch))
    DispatchSnapshot.claim(owner: owner, defaults: d)
    #expect(!value.write(d, epoch: epoch), "Even the same golfer's earlier session must stay retired")
  }

  @Test func slicesKeepSeparateClocksAndTimelineExpiresActions() throws {
    var value = BetweenRoundsSnapshot(owner: owner)
    value.race = .init(nil, at: now.addingTimeInterval(-86_400))
    value.nextTee = .init(try #require(BetweenRoundsCopy.tee(detail(), now: now)), at: now)
    #expect(value.isStale(.race, at: now))
    #expect(!value.isStale(.nextTee, at: now))
    #expect(value.timelineDates(now: now).contains(now.addingTimeInterval(86_400)))
    #expect(value.timelineDates(now: now).contains(value.nextTee!.value!.closesAt))
    #expect(value.isStale(.nextTee, at: now.addingTimeInterval(86_400)))
    #expect(value.isStale(.nextTee, at: now.addingTimeInterval(-301)))
  }

  @Test func onlyInvitedFuturePlansOfferReplies() throws {
    #expect(BetweenRoundsCopy.tee(detail(tagged: false), now: now) == nil)
    let tee = try #require(BetweenRoundsCopy.tee(detail(), now: now))
    #expect(tee.allowsReply(at: tee.closesAt.addingTimeInterval(-1)))
    #expect(!tee.allowsReply(at: tee.closesAt))
    #expect(BetweenRoundsCopy.tee(detail(), now: tee.closesAt) == nil)
  }

  @Test func datesStayLocalAndUnknownTimeExpiresAtNextMidnight() throws {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "America/Phoenix")!
    let end = try #require(BetweenRoundsCopy.closesAt(day: "2030-09-26", time: nil, calendar: cal))
    #expect(cal.component(.day, from: end) == 27)
    #expect(cal.component(.hour, from: end) == 0)
    let tee = try #require(BetweenRoundsCopy.closesAt(day: "2030-09-26", time: "07:10:00", calendar: cal))
    #expect(cal.component(.day, from: tee) == 26)
    #expect(cal.component(.hour, from: tee) == 7)
    #expect(BetweenRoundsCopy.closesAt(day: "2030-09-26", time: "28:99", calendar: cal) == nil)
    #expect(BetweenRoundsCopy.closesAt(day: "2030-13-26", time: nil, calendar: cal) == nil)
  }

  @Test func theRecordNeverInventsTwoNines() {
    func record(_ holes: Int, _ out: Int?, _ inn: Int?) -> BetweenRoundsSnapshot.Record {
      .init(id: round, headline: "Your round", course: "Papago", date: "Sep 26", gross: 79, holes: holes, out: out, inn: inn, earned: false)
    }
    #expect(record(18, 38, 41).out == 38)
    #expect(record(18, 39, 41).out == nil)
    #expect(record(18, 38, nil).out == nil)
    #expect(record(9, 38, 41).inn == nil)
  }

  @Test func raceUsesServerTiesAndSquadTotals() throws {
    for fixture in ["squads", "tie", "audit-live"] {
      let data = try Data(contentsOf: Bundle.module.url(forResource: fixture, withExtension: "json")!)
      let book = try JSONDecoder().decode(SeasonBookSnapshot.self, from: data)
      let race = try #require(BetweenRoundsCopy.race(book))
      #expect(race.rows.count <= 3 && race.rows.contains(where: \.mine))
      for row in race.rows {
        let source = try #require(book.rows.first { $0.id == row.id })
        #expect(row.points == source.points)
        #expect(source.kind == (book.hasSquads ? "squad" : "golfer"))
      }
      if fixture == "tie" {
        #expect(race.rows.allSatisfy { $0.rank == "01" })
        #expect(race.story == "Tied for the lead.")
      }
    }
  }

  @Test func weeklyRivalryDoesNotBlendRyderWins() throws {
    let data = Data("{\"opponent\":\"\(round)\",\"display_name\":\"Galen Marr\",\"meetings\":12,\"wins\":6,\"losses\":5,\"ties\":1,\"duel_wins\":9}".utf8)
    let row = try JSONDecoder().decode(Rpc.my_rivalries.Row.self, from: data)
    let latest = try JSONDecoder().decode(Rpc.rivalry_weeks.Row.self, from: Data("{\"wk\":\"2026-09-21\",\"winner\":\"them\"}".utf8))
    let rival = try #require(BetweenRoundsCopy.rivalry(row, latest: latest))
    #expect(rival.wins == 6 && rival.losses == 5 && rival.ties == 1)
    #expect(rival.scope == "Weekly clashes · All time")
    #expect(rival.story == "Galen took the last one.")
  }

  @Test @MainActor func replyChangesOnlyAfterAcknowledgement() async throws {
    let d = suite(); DispatchSnapshot.claim(owner: owner, defaults: d)
    var value = BetweenRoundsSnapshot(owner: owner)
    value.nextTee = .init(try #require(BetweenRoundsCopy.tee(detail(), now: now)), at: now)
    value.race = .init(nil, at: now.addingTimeInterval(-90_000))
    value.write(d, epoch: d.string(forKey: BetweenRoundsSnapshot.epochKey))
    var writes = 0
    try await WidgetRSVP.run(round: round, owner: owner, status: "in", defaults: d,
      currentOwner: { owner }, read: { _ in detail() }, save: { id, status in
        #expect(id == round && status == "in")
        #expect(BetweenRoundsSnapshot.read(d)?.nextTee?.value?.status == nil)
        writes += 1
      }, now: now)
    #expect(writes == 1)
    #expect(BetweenRoundsSnapshot.read(d)?.nextTee?.value?.status == "in")
    #expect(BetweenRoundsSnapshot.read(d)?.isStale(.race, at: now) == true)
  }

  @Test @MainActor func failedReplyKeepsStatusAndShowsAnHonestError() async throws {
    let d = suite(); DispatchSnapshot.claim(owner: owner, defaults: d)
    var value = BetweenRoundsSnapshot(owner: owner)
    value.nextTee = .init(try #require(BetweenRoundsCopy.tee(detail(), now: now)), at: now)
    value.write(d, epoch: d.string(forKey: BetweenRoundsSnapshot.epochKey))
    do {
      try await WidgetRSVP.run(round: round, owner: owner, status: "in", defaults: d,
        currentOwner: { owner }, read: { _ in detail() }, save: { _,_ in throw WidgetRSVPError.unavailable }, now: now)
      Issue.record("A failed RPC reported success")
    } catch {}
    #expect(BetweenRoundsSnapshot.read(d)?.nextTee?.value?.status == nil)
    #expect(BetweenRoundsSnapshot.read(d)?.nextTee?.value?.replyError != nil)
  }

  @Test @MainActor func accountChangedDuringReadAndRevokedInviteNeverWrite() async throws {
    for changedOwner in [true, false] {
      let d = suite(); DispatchSnapshot.claim(owner: owner, defaults: d)
      var writes = 0
      do {
        try await WidgetRSVP.run(round: round, owner: owner, status: "in", defaults: d, currentOwner: { owner },
          read: { _ in
            if changedOwner { DispatchSnapshot.claim(owner: UUID(), defaults: d) }
            return detail(tagged: changedOwner)
          }, save: { _,_ in writes += 1 }, now: now)
        Issue.record("A revoked action reported success")
      } catch {}
      #expect(writes == 0)
    }
  }
}
