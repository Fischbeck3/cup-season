// Codex S3 · a course id and a populated array are NOT proof of par.
// The card carries provenance; the snapshot carries it; the moment and the
// tally read it. Every case here is one the review named.
import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct ParProvenanceTests {
  private func rows(_ n: Int, par: Int = 4) -> [(par: Int, handicap: Int)] { (0..<n).map { (par: par, handicap: $0 + 1) } }

  @Test func aFreshCardIsNotVerified() {
    #expect(LiveCourseCard().parsVerified == false)
  }

  /// The template is installed the moment a course is picked, BEFORE any card
  /// read — a known course with a failed fetch keeps template pars, and they
  /// are a guess.
  @Test func theTemplateIsAGuessEvenForAKnownCourse() {
    var c = LiveCourseCard()
    c.parsCourse = "100"
    c.installTemplate()
    #expect(c.parsVerified == false)
    #expect(c.pars == LiveCourseCard.postParStd)
  }

  /// The course's own card, for every hole in play: verified.
  @Test func aCompleteCardReadVerifies() {
    var c = LiveCourseCard(); c.parsCourse = "100"
    c.load(holes: rows(18), playing: 18)
    #expect(c.parsVerified == true)
    var nine = LiveCourseCard(); nine.parsCourse = "100"
    nine.load(holes: rows(9), playing: 9)
    #expect(nine.parsVerified == true)
  }

  /// An incomplete array leaves template holes behind: not verified.
  @Test func anIncompleteCardDoesNotVerify() {
    var c = LiveCourseCard(); c.parsCourse = "100"
    c.load(holes: rows(12), playing: 18)
    #expect(c.parsVerified == false)
    var zero = LiveCourseCard()
    zero.load(holes: rows(17) + [(par: 0, handicap: 18)], playing: 18)
    #expect(zero.parsVerified == false, "a zero par is a missing par")
  }

  /// The golfer wrote the card: confirmed.
  @Test func aHandWrittenCardIsConfirmed() {
    var c = LiveCourseCard()
    c.save(front: [4,4,3,5,4,4,3,4,5], back: [4,3,4,5,4,4,3,4,5], nine: false)
    #expect(c.parsVerified == true)
    var n = LiveCourseCard()
    n.save(front: [4,4,3,5,4,4,3,4,5], back: nil, nine: true)
    #expect(n.parsVerified == true)
  }

  /// The flag rides the snapshot both ways, and a historical snapshot without
  /// it (every round before this) reads as unverified.
  @Test func provenanceRidesTheSnapshot() {
    var c = LiveCourseCard(); c.parsCourse = "100"
    c.load(holes: rows(18), playing: 18)
    let snap = c.snapshot(holes: 18, rating9: false)
    #expect(snap["pars_verified"]?.bool == true)
    let back = LiveCourseCard.from(snapshot: snap, courseLabel: "Bajamar", siEstimated: false)
    #expect(back.parsVerified == true)
    let historical: JSONValue = .object(["pars": .array((0..<18).map { _ in .number(4) }), "holes": .number(18)])
    #expect(LiveCourseCard.from(snapshot: historical, courseLabel: "Bajamar", siEstimated: false).parsVerified == false)
  }

  /// Codex S2 · the row-to-state conversion refuses a caller with no seat.
  @Test func hydrationRequiresASeat() {
    let me = UUID(), other = UUID(), lr = UUID()
    func row(seated: Bool) -> JSONValue {
      .object(["id": .string(lr.uuidString), "game": .string("none"), "game_config": .object([:]), "join_code": .string("J"),
               "starter_profile_id": .string(other.uuidString), "course_snapshot": .object(["pars": .array((0..<18).map { _ in .number(4) })]),
               "course_label": .string("Bajamar"),
               "live_round_players": .array([
                 .object(["id": .string(UUID().uuidString), "position": .number(1), "guest_name": .string("Galen"), "guest_profile_id": .string(other.uuidString)]),
                 .object(["id": .string(UUID().uuidString), "position": .number(2), "guest_name": .string("Me"),
                          "guest_profile_id": .string((seated ? me : UUID()).uuidString)])])])
    }
    let s = LiveRehydrator.fromServerRow(row(seated: true), myPid: me)
    #expect(s != nil)
    #expect(s?.mine == false, "the starter is someone else")
    #expect(s?.lr == lr && s?.code == "J")
    #expect(s?.players.contains { $0.me } == true, "and my seat is mine")
    let none = LiveRehydrator.fromServerRow(row(seated: false), myPid: me)
    #expect(none?.players.contains { $0.me } != true, "an unseated caller is nobody in that roster")
  }
}
