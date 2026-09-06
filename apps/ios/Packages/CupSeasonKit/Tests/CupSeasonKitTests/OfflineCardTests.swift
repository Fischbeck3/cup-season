// Cup Season — nothing a golfer typed is thrown away in silence.
//
// The live pencil was already durable: `LiveDisk` writes the whole card on
// every stroke and resume is local-first. What was not safe was the far end.
// The daily tick abandons an unfinished round twenty-four hours after tee-off
// (`20260904180000:40-43`), `live_set_score` then raises "Round is not live",
// and the client's `isDeadWrite` regex matched that and did `q.removeFirst()`
// — so a card scored in a canyon on Sunday and drained on Tuesday lost every
// stroke, one at a time, with nothing on screen. The next cold launch then
// deleted the snapshot too.
//
// These tests pin the three rules that came out of it: a card with strokes is
// KEPT rather than deleted; a card the golfer threw away is NOT kept; and the
// badge names the deadline the server is actually enforcing.

import Testing
import Foundation
@testable import CupSeasonKit

private func card(strokes: Bool, lr: UUID = UUID(), started: Int64? = nil) -> LiveRoundState {
  var s = LiveRoundState.fresh(players: [LivePlayer(n: "Jerecho", i: 10.6, ci: 1, guest: false),
                                         LivePlayer(n: "Galen", i: 8.1, ci: 1, guest: false)])
  s.active = true
  s.stage = LiveRoundState.Stage.live
  s.lr = lr
  s.code = "ABCD"
  s.startedAt = started
  if strokes { s.scores[0][0] = 5 }
  return s
}

private func tempDisk() -> LiveDisk {
  let dir = FileManager.default.temporaryDirectory
    .appendingPathComponent("cs-offline-tests/\(UUID().uuidString)", isDirectory: true)
  return LiveDisk(directory: dir)
}

@Suite struct KeptCardTests {

  @Test("a card with strokes is kept when the round is lost involuntarily")
  func theCardSurvives() async {
    let disk = tempDisk(), lr = UUID()
    let c = card(strokes: true, lr: lr)
    await disk.save(c)
    await disk.retire(c, lr: lr)
    await disk.clearSnapshots(keep: nil)

    #expect(await disk.snapshot(lr) == nil)          // the live snapshot is gone
    let kept = await disk.unsynced()
    #expect(kept.count == 1)                          // the card is not
    #expect(kept.first?.lr == lr)
    #expect(kept.first?.scores[0][0] == 5)            // with the strokes in it
  }

  /// A setup screen somebody backed out of is not a round.
  @Test("a card with no strokes is not kept")
  func nothingToKeep() async {
    let disk = tempDisk(), lr = UUID()
    await disk.retire(card(strokes: false, lr: lr), lr: lr)
    #expect(await disk.unsynced().isEmpty)
  }

  /// The retire path can fire from the flush AND from the rehydrator. The
  /// first write wins so a thinner card can never overwrite a fuller one.
  @Test("retiring twice does not overwrite the fuller card")
  func theFirstWriteWins() async {
    let disk = tempDisk(), lr = UUID()
    var full = card(strokes: true, lr: lr)
    full.scores[0][1] = 4
    await disk.retire(full, lr: lr)
    await disk.retire(card(strokes: true, lr: lr), lr: lr)   // thinner
    #expect(await disk.unsynced().first?.scores[0][1] == 4)
  }

  /// `clearSnapshots` is what `scrap()` calls. A golfer throwing a round away
  /// must not have it kept behind his back — that is the corpse the scrap
  /// path exists to bury.
  @Test("clearing does not keep anything by itself")
  func clearingIsNotKeeping() async {
    let disk = tempDisk(), lr = UUID()
    await disk.save(card(strokes: true, lr: lr))
    await disk.clearSnapshots(keep: nil)
    #expect(await disk.unsynced().isEmpty)
  }

  @Test("a kept card is removed once it is posted or scrapped")
  func keptCardsAreReleasable() async {
    let disk = tempDisk(), lr = UUID()
    await disk.retire(card(strokes: true, lr: lr), lr: lr)
    #expect(await disk.unsynced().count == 1)
    await disk.removeUnsynced(lr)
    #expect(await disk.unsynced().isEmpty)
  }

  @Test("retireAll keeps every scored card and no empty one")
  func retireAllIsSelective() async {
    let disk = tempDisk()
    await disk.save(card(strokes: true))
    await disk.save(card(strokes: true))
    await disk.save(card(strokes: false))
    await disk.retireAll()
    #expect(await disk.unsynced().count == 2)
  }
}

@Suite struct UnsentBadgeTests {
  private let now: Int64 = 1_757_000_000_000

  @Test("the badge names the deadline the server is enforcing")
  func theDeadlineIsSaid() {
    let s = card(strokes: true, started: now - 18 * 3_600_000)
    let t = LiveCopy.syncBadge(s, presence: ["Jerecho"], queued: 18, now: now)
    #expect(t.contains("18 unsent"))
    #expect(t.contains("closes in 6h"))
  }

  /// L-44 · a deadline nobody can compute is not one to print. Cards written
  /// before `startedAt` existed decode without it.
  @Test("with no tee-off time it says only what it knows")
  func noGuessedDeadline() {
    let t = LiveCopy.syncBadge(card(strokes: true), presence: [], queued: 3, now: now)
    #expect(t.contains("3 unsent"))
    #expect(!t.contains("closes"))
  }

  @Test("past the window it says so rather than counting backwards")
  func pastTheWindow() {
    let s = card(strokes: true, started: now - 30 * 3_600_000)
    #expect(LiveCopy.syncBadge(s, presence: [], queued: 4, now: now).contains("past its window"))
  }

  @Test("a retired round stops claiming it is syncing")
  func theRetiredBadge() {
    let t = LiveCopy.syncBadge(card(strokes: true), presence: [], queued: 4, retired: true, now: now)
    #expect(t.contains("saved on this phone"))
    #expect(!t.contains("unsent"))
  }

  @Test("nothing queued still reads synced")
  func synced() {
    #expect(LiveCopy.syncBadge(card(strokes: true), presence: ["A", "B"], queued: 0, now: now)
              .contains("synced"))
  }
}

/// `rounds` has exactly one unique index — `rounds_pkey` on a
/// `gen_random_uuid()` default — so a replayed insert is a second scoring
/// round, double-counted in the index, the standings and the participation
/// floor, which carries real money. The retry exists ONLY for deploy skew.
@Suite struct PostRetryTests {

  @Test("a network failure never earns a retry")
  func networkNeverRetries() {
    #expect(PostService.names(URLError(.timedOut), "api_course_id") == false)
    #expect(PostService.names(URLError(.networkConnectionLost), "photo_path") == false)
    #expect(PostService.names(URLError(.notConnectedToInternet), "api_course_id") == false)
  }

  @Test("only an error that NAMES the column earns one")
  func onlyTheNamedColumn() {
    let skew = RpcError(name: "rounds", underlying: "column \"api_course_id\" of relation \"rounds\" does not exist", droppedArgs: [])
    #expect(PostService.names(skew, "api_course_id"))
    #expect(PostService.names(skew, "photo_path") == false)
  }

  @Test("a refusal is not deploy skew")
  func aRefusalIsNotSkew() {
    #expect(PostService.names(RpcError(name: "rounds", underlying: "new row violates row-level security policy", droppedArgs: []),
                              "api_course_id") == false)
  }
}

// MARK: - the kept card has a door

/// Keeping a card is only half of it. `LiveRehydrate`'s toast promises "saved
/// on this phone to post yourself" and the badge says "your card is saved on
/// this phone" — both name a surface, and these pin that the surface can be
/// built from what was kept.
@Suite struct KeptCardComposeTests {
  private let now: Int64 = 1_757_000_000_000

  private func scored(_ holes: Int, me seat: Int = 0) -> LiveRoundState {
    var s = LiveRoundState.fresh(players: [
      LivePlayer(n: "Jerecho", i: 10.6, ci: 1, guest: false),
      LivePlayer(n: "Galen", i: 8.1, ci: 1, guest: false)])
    s.active = true; s.lr = UUID(); s.startedAt = now
    s.players[seat].me = true
    s.course.label = "Papago Golf Course"
    s.course.rating = 71.2; s.course.slope = 128
    for h in 0..<holes { s.scores[seat][h] = 4 }
    return s
  }

  @Test("a kept card becomes a composer card with the strokes in the grid")
  func itComposes() {
    let k = KeptCards.card(from: scored(18))
    #expect(k?.holesPlayed == 18)
    #expect(k?.total == 72)
    #expect(k?.isComplete == true)
    let c = KeptCards.compose(k!)
    #expect(c.mode == .holes)
    #expect(c.scores.filter { $0 > 0 }.count == 18)
    #expect(c.course == "Papago Golf Course")
    #expect(c.rating == "71.2")
    #expect(c.slope == "128")
    #expect(c.date != nil)          // the day it was PLAYED, not the day it is posted
  }

  /// A card with gaps is still worth handing back — the golfer fills them in.
  @Test("an unfinished card is kept and says how much is missing")
  func gapsAreShown() {
    let k = KeptCards.card(from: scored(14))
    #expect(k?.isComplete == false)
    #expect(k?.holesPlayed == 14)
    #expect(k?.line.contains("14 of 18 holes") == true)
    #expect(KeptCards.compose(k!).scores.filter { $0 > 0 }.count == 14)
  }

  /// L-19 · somebody else's scoring is not my round to post.
  @Test("a card with none of MY strokes on it is not offered")
  func notMyRound() {
    var s = scored(18, me: 0)
    s.scores[0] = Array(repeating: nil, count: 18)   // wipe mine, keep theirs
    s.scores[1] = Array(repeating: 5, count: 18)
    #expect(KeptCards.card(from: s) == nil)
  }

  /// L-07 · a card written before `startedAt` existed has no day to give, and
  /// the composer opens on today rather than inventing one.
  @Test("with no tee-off time the composer gets no date rather than a guess")
  func noGuessedDate() {
    var s = scored(18); s.startedAt = nil
    let k = KeptCards.card(from: s)
    #expect(k?.playedOn == nil)
    #expect(KeptCards.compose(k!).date == nil)
  }
}
