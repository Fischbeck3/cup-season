import XCTest
import CupSeasonKit
@testable import CupSeason

/// F16 · the album's six states, held apart: loading, a read that answered
/// with nothing, an initial failure, an offline failure, the retry that
/// lands, and a refresh that fails with photographs already up.
@MainActor
final class AlbumModelTests: XCTestCase {
  private let league = UUID(uuidString: "f1c70000-0000-4000-8000-000000001001")!
  private let mate = LeagueMate(profileId: UUID(uuidString: "f1c70000-0000-4000-8000-000000000002")!,
                                displayName: "Blake Sample", marker: "lonetree", photoPath: nil)
  private func row(_ n: Int) -> RoundRow {
    RoundRow(id: UUID(uuidString: String(format: "f1c70000-0000-4000-8000-%012d", 4_100 + n))!,
             profile_id: mate.profileId, gross: 80 + n, differential: nil, index_at_post: nil,
             played_on: "2026-09-2\(n)", course_label: "North Grove (fixture)", holes_played: 18,
             photo_path: "rounds/x/\(n).jpg", photo_url: URL(string: "https://example.invalid/\(n).jpg"))
  }
  private struct Refused: Error {}

  func testStartsLoadingAndAnAnsweredReadWithNoPhotographsIsEmpty() async {
    let m = AlbumModel(leagueId: league) { _ in ([self.mate], []) }
    XCTAssertEqual(m.phase, .loading)
    await m.load()
    XCTAssertEqual(m.phase, .empty)
    XCTAssertNil(m.refreshNote)
  }

  func testALeagueWithNobodyInItIsEmptyNotFailed() async {
    let m = AlbumModel(leagueId: league) { _ in ([], []) }
    await m.load()
    XCTAssertEqual(m.phase, .empty)
  }

  func testAFailedReadIsNeverTheEmptyAlbum() async {
    let m = AlbumModel(leagueId: league) { _ in throw Refused() }
    await m.load()
    XCTAssertEqual(m.phase, .failed(offline: false))
    XCTAssertTrue(m.rows.isEmpty)
    XCTAssertNotEqual(m.phase, .empty, "a failed read must not send the golfer off to add photographs")
  }

  func testNoSignalIsItsOwnFailure() async {
    for code: URLError.Code in [.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed] {
      let m = AlbumModel(leagueId: league) { _ in throw URLError(code) }
      await m.load()
      XCTAssertEqual(m.phase, .failed(offline: true), "\(code)")
    }
    // a server that answered with an error is not "offline"
    let refused = AlbumModel(leagueId: league) { _ in throw URLError(.badServerResponse) }
    await refused.load()
    XCTAssertEqual(refused.phase, .failed(offline: false))
    // a wrapped transport error still reads as no signal
    let wrapped = NSError(domain: "PostgREST", code: 1, userInfo: [NSUnderlyingErrorKey: URLError(.notConnectedToInternet)])
    XCTAssertTrue(AlbumModel.isOffline(wrapped))
  }

  func testTheRetryLandsAndTheFailureGoes() async {
    var attempts = 0
    let m = AlbumModel(leagueId: league) { _ in
      attempts += 1
      if attempts == 1 { throw Refused() }
      return ([self.mate], [self.row(1), self.row(2)])
    }
    await m.load()
    XCTAssertEqual(m.phase, .failed(offline: false))
    await m.load()
    XCTAssertEqual(m.phase, .ready)
    XCTAssertEqual(m.rows.count, 2)
    XCTAssertNil(m.refreshNote)
    XCTAssertEqual(m.mates[self.mate.profileId]?.displayName, "Blake Sample")
  }

  func testARefreshThatFailsKeepsThePhotographsAndSaysSo() async {
    var attempts = 0
    var offline = false
    let m = AlbumModel(leagueId: league) { _ in
      attempts += 1
      if attempts > 1 { throw offline ? URLError(.notConnectedToInternet) : Refused() }
      return ([self.mate], [self.row(1), self.row(2), self.row(3)])
    }
    await m.load()
    XCTAssertEqual(m.phase, .ready)
    await m.load()
    XCTAssertEqual(m.phase, .ready, "loaded photographs stay on a failed refresh")
    XCTAssertEqual(m.rows.count, 3)
    XCTAssertEqual(m.refreshNote?.offline, false)
    offline = true
    await m.load()
    XCTAssertEqual(m.rows.count, 3)
    XCTAssertEqual(m.refreshNote?.offline, true)
  }

  func testPhotographsNoneOfWhichCouldBeSignedAreAFailureNotAnEmptyAlbum() async {
    let m = AlbumModel(leagueId: league) { _ in throw AlbumUnsignable() }
    await m.load()
    XCTAssertEqual(m.phase, .failed(offline: false))
    XCTAssertNotNil(m.why)
  }

  func testTheWhyIsTheProductsSentenceAndOfflineSaysSignal() async {
    let m = AlbumModel(leagueId: league) { _ in throw URLError(.notConnectedToInternet) }
    await m.load()
    XCTAssertEqual(m.why, "Connection hiccup — check your signal and try again.")
  }

  func testTheCopyNeverSendsAFailureToTheCamera() {
    for line in [AlbumCopy.failedHead, AlbumCopy.refreshFailed, AlbumCopy.retry] {
      XCTAssertFalse(line.lowercased().contains("add one"), line)
      XCTAssertFalse(line.lowercased().contains("add a photo"), line)
    }
    XCTAssertEqual(AlbumCopy.failedHead, "The album didn\u{2019}t load")
    XCTAssertEqual(AlbumCopy.refreshFailed, "The album didn\u{2019}t refresh.")
  }
}
