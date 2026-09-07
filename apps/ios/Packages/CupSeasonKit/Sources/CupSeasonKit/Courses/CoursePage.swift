// Cup Season — the course as a PLACE, not a database record (D272 / D275,
// IOS-048, `surfaces/course.md` §2.5, §2.7, §7).
//
// THE ONE THING THE SHIPPED COURSE SHEET HAD NO WAY TO SAY: who of yours has
// played it. Four faces above the fold and a sentence that names them is the
// single biggest change from the shipped screen, where the only social fact is
// a footnote at the bottom — and it is also the difference between a page
// about a place and a row from a table.
//
// **NO NEW SERVER FUNCTION WAS WRITTEN FOR IT, AND NONE WAS NEEDED.**
// `course.md` §7.3 asks for a `course_page(p_course_id)` producer and says of
// the facts behind it: *"Every underlying fact already exists on `rounds`;
// none of it is currently reachable for a course other than the viewer's
// own."* The second half is what turned out not to be true. `rounds` carries
// `api_course_id` (20260714050000) and `photo_path` (20260718045514), and the
// `rounds_read` policy has always been *mine, plus anyone I share a league
// with* — so the rounds posted at a course, by the people the viewer may
// already see, are one filtered select away under the RLS this database
// already enforces. The overhaul is a client-side wave; this read keeps it one.
//
// WHAT THAT COSTS, STATED. The set is league mates and me — **not** accepted
// buddies, who share no `league_members` row, and not event field mates. It is
// the same set the album and the receipt already draw from, it is narrower
// than the page's own copy would like, and widening it is a `course_page` RPC
// on the server's own predicate rather than a client change. The page never
// claims more than it read: the sentence names the golfers it actually has.
//
// THREE HONESTY RULES, the same three the course book is built on:
//
//   L-32 · A FAILED READ IS NOT AN EMPTY ONE. `failed` is a case, and the page
//     keeps what is on screen rather than drawing "nobody has played it" over
//     a network error.
//   L-44 · NOTHING IS INVENTED. No tee name (there is no `tee_name` on
//     `rounds`), so the slat's sub-line is the date and nothing else. No
//     photographer's name without a profile row behind it. No hero at all when
//     no round here carries a photograph.
//   D37 / skew · every select that names a newer column retries WITHOUT it on
//     ANY error, never on the message — 42501 never names its column.

import Foundation
import Supabase

/// One round posted at this course, as the page's own row.
public struct CourseRoundRow: Sendable, Identifiable, Equatable {
  public let id: UUID
  public let profileId: UUID?
  public let name: String
  public let marker: String?
  public let gross: Int?
  public let playedOn: String?
  public let holesPlayed: Int?
  public let photoPath: String?
  public var photoURL: URL?
  public let isMine: Bool

  public init(id: UUID, profileId: UUID?, name: String, marker: String?, gross: Int?,
              playedOn: String?, holesPlayed: Int?, photoPath: String? = nil,
              photoURL: URL? = nil, isMine: Bool = false) {
    self.id = id; self.profileId = profileId; self.name = name; self.marker = marker
    self.gross = gross; self.playedOn = playedOn; self.holesPlayed = holesPlayed
    self.photoPath = photoPath; self.photoURL = photoURL; self.isMine = isMine
  }

  /// `Aug 30` · `Aug 30 · nine holes`. **Never a tee name**: `rounds` does not
  /// carry one, and the design's *"Aug 30 · blue tees"* would be a guess.
  public func subline(now: Date = Date(), calendar: Calendar = .current) -> String {
    let day = playedOn.map { LeagueDates.dowMonDay($0, calendar: calendar) } ?? ""
    guard (holesPlayed ?? 18) == 9 else { return day }
    return day.isEmpty ? "Nine holes" : day + " · nine holes"
  }
}

/// The hero photograph and its credit — rung 1 of the ladder (§10.1).
public struct CoursePhoto: Sendable, Equatable {
  public let url: URL
  /// `GALEN'S ROUND · AUG 24`. **The credit is not optional**: it is the
  /// difference between an image the product borrowed and an image somebody
  /// took, and a photo with no name behind it is not shown at all.
  public let credit: String
  public init(url: URL, credit: String) { self.url = url; self.credit = credit }
}

/// Everything the page knows about who has played here.
public struct CoursePageAnswer: Sendable, Equatable {
  /// Every round the viewer may see at this course, newest first.
  public let rounds: [CourseRoundRow]
  /// The viewer's own best gross here. nil = you have not played it, and the
  /// plate's panel is ABSENT rather than dashed (§4, D-9).
  public let myBest: Int?
  /// One row per OTHER golfer, their best here, best first. The faces row and
  /// the sentence that names them both come off this.
  public let others: [CourseRoundRow]
  public let hero: CoursePhoto?
  /// L-32 · the read failed and there is nothing behind it. Never rendered as
  /// "nobody has played it".
  public let failed: Bool

  public init(rounds: [CourseRoundRow] = [], myBest: Int? = nil, others: [CourseRoundRow] = [],
              hero: CoursePhoto? = nil, failed: Bool = false) {
    self.rounds = rounds; self.myBest = myBest; self.others = others
    self.hero = hero; self.failed = failed
  }

  /// How many golfers the sentence names before it stops. Six is a group; a
  /// list of nine first names is a roster, which is the event's device.
  public static let namedCap = 6

  /// *"Galen, Tash, Jade and Dev. Galen's {79} is the best of them."* — the
  /// braces are the figure run's mark, and the producer is here so both
  /// clients print one sentence (§2.5). Empty when nobody else has played it;
  /// the block does not render rather than saying so.
  public var friendsLine: String {
    let names = others.compactMap { $0.name.isEmpty ? nil : CourseNames.first($0.name) }
    guard !names.isEmpty else { return "" }
    let list = CourseNames.list(Array(names.prefix(CoursePageAnswer.namedCap)))
    guard let best = others.first(where: { $0.gross != nil }), let g = best.gross else { return list + "." }
    return "\(list). \(CourseNames.first(best.name))’s {\(g)} is the best of them."
  }
}

/// The words this file is allowed to say about people, in one place.
public enum CourseNames {
  /// `Galen Marr` → `Galen`. A course row is a first-name room.
  public static func first(_ full: String) -> String {
    full.split(separator: " ").first.map(String.init) ?? full
  }

  /// `Galen, Tash, Jade and Dev` — the Oxford-less list the product uses
  /// everywhere a set of golfers is named.
  public static func list(_ names: [String]) -> String {
    switch names.count {
    case 0: return ""
    case 1: return names[0]
    case 2: return "\(names[0]) and \(names[1])"
    default: return names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
    }
  }
}

public struct CoursePageRepository: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  private var db: SupabaseClient { svc.client }

  private struct RoundAtCourse: Decodable, Sendable {
    let id: UUID
    let profile_id: UUID?
    let gross: Int?
    let played_on: String?
    let holes_played: Int?
    let voided: Bool?
    let photo_path: String?
  }
  private struct PersonRow: Decodable, Sendable {
    let id: UUID
    let display_name: String?
    let marker: String?
  }

  private static let cols = "id, profile_id, gross, played_on, holes_played, voided"

  /// The rounds posted at one course, the viewer's own best, the other golfers
  /// who have played it, and the hero photograph.
  ///
  /// Every failure is a `failed: true` answer rather than a throw: a course
  /// page with no signal still has a plate, a facts line and a leaf, all of
  /// them off the phone's own book, and none of that should disappear because
  /// a social read did not answer.
  public func page(courseId: String?, me: UUID?) async -> CoursePageAnswer {
    guard let courseId, !courseId.isEmpty, !courseId.hasPrefix("never-kept") else {
      return CoursePageAnswer()
    }
    var raw: [RoundAtCourse]
    do {
      raw = try await db.from("rounds").select(Self.cols + ", photo_path")
        .eq("api_course_id", value: courseId)
        .order("played_on", ascending: false).limit(60).execute().value
    } catch {
      // The skew retry, on ANY error: a database without `photo_path` granted
      // still answers the rest, and 42501 never names its column.
      do {
        raw = try await db.from("rounds").select(Self.cols)
          .eq("api_course_id", value: courseId)
          .order("played_on", ascending: false).limit(60).execute().value
      } catch {
        return CoursePageAnswer(failed: true)
      }
    }
    let live = raw.filter { !($0.voided ?? false) }
    guard !live.isEmpty else { return CoursePageAnswer() }

    // the names and the markers, so every row can carry a face (§6)
    let ids = Array(Set(live.compactMap(\.profile_id)))
    var people: [UUID: PersonRow] = [:]
    if !ids.isEmpty,
       let rows: [PersonRow] = try? await db.from("profiles")
         .select("id, display_name, marker").in("id", values: ids).execute().value {
      for p in rows { people[p.id] = p }
    }

    let rounds: [CourseRoundRow] = live.map { r in
      let p = r.profile_id.flatMap { people[$0] }
      return CourseRoundRow(id: r.id, profileId: r.profile_id,
                            name: p?.display_name ?? "",
                            marker: p?.marker,
                            gross: r.gross, playedOn: r.played_on,
                            holesPlayed: r.holes_played, photoPath: r.photo_path,
                            isMine: r.profile_id != nil && r.profile_id == me)
    }

    // **A NINE IS NOT A BEST.** The first shot of the courses list printed a
    // `35` in the YOUR BEST column beside four eighteen-hole grosses — real
    // data, and a comparison nobody would make. A best gross is an eighteen;
    // a nine has no round to be better than.
    let myBest = rounds.filter { $0.isMine && ($0.holesPlayed ?? 18) == 18 }.compactMap(\.gross).min()

    // one row per OTHER golfer, their best here, best first — the faces row is
    // a group of people, not a list of rounds
    var bestByPerson: [UUID: CourseRoundRow] = [:]
    for r in rounds where !r.isMine {
      guard let pid = r.profileId, !r.name.isEmpty, (r.holesPlayed ?? 18) == 18 else { continue }
      if let had = bestByPerson[pid], (had.gross ?? 999) <= (r.gross ?? 999) { continue }
      bestByPerson[pid] = r
    }
    let others = bestByPerson.values.sorted {
      ($0.gross ?? 999, $0.name) < ($1.gross ?? 999, $1.name)
    }

    return CoursePageAnswer(rounds: rounds, myBest: myBest, others: others,
                            hero: await hero(rounds, people: people), failed: false)
  }

  /// **Your best gross at every course you have played**, keyed by
  /// `api_course_id` — one read for a whole list, so the courses screen can
  /// print the column its head names instead of heading an empty one.
  ///
  /// It is allowed to answer nothing. This list is the one screen that must
  /// work on the boot-failed path with no session at all (OE-1), and there the
  /// column simply is not there.
  public func myBests(me: UUID?) async -> [String: Int] {
    guard let me else { return [:] }
    struct Row: Decodable, Sendable {
      let api_course_id: String?; let gross: Int?; let voided: Bool?; let holes_played: Int?
    }
    guard let rows: [Row] = try? await db.from("rounds")
      .select("api_course_id, gross, voided, holes_played")
      .eq("profile_id", value: me)
      .not("api_course_id", operator: .is, value: "null")
      .order("played_on", ascending: false).limit(400).execute().value else { return [:] }
    var out: [String: Int] = [:]
    for r in rows {
      // eighteens only — a nine's 35 is not a best (see `page`)
      guard let id = r.api_course_id, let g = r.gross, !(r.voided ?? false),
            (r.holes_played ?? 18) == 18 else { continue }
      if let had = out[id], had <= g { continue }
      out[id] = g
    }
    return out
  }

  /// **Rung 1 of the ladder.** The most recent round photo at this course from
  /// someone the viewer can see, with the photographer's name and the round's
  /// date. A photo whose signing fails, or whose golfer has no name, is not
  /// shown — an uncredited photograph is not one of the three legal images.
  private func hero(_ rounds: [CourseRoundRow], people: [UUID: PersonRow]) async -> CoursePhoto? {
    let candidates = rounds.filter { ($0.photoPath?.isEmpty == false) }
    guard !candidates.isEmpty else { return nil }
    let paths = candidates.compactMap(\.photoPath)
    let urls = await RoundsRepository(svc).signedURLs(paths)
    for r in candidates {
      guard let path = r.photoPath, let url = urls[path] else { continue }
      let who = r.isMine ? "Your round" : (r.name.isEmpty ? "" : "\(CourseNames.first(r.name))’s round")
      guard !who.isEmpty else { continue }
      let when = r.playedOn.map { LeagueDates.monDay($0) } ?? ""
      return CoursePhoto(url: url, credit: when.isEmpty ? who : "\(who) · \(when)")
    }
    return nil
  }
}

// MARK: - The rating (D275)

/// A course's rating: the community's number, your golfers' number, yours, and
/// the sentences behind them.
///
/// **`course_rating` / `rate_course` / `unrate_course` ARE LIVE** — the owner
/// pushed `20261007090000` on 2026-09-07, and that migration's own "THIS FILE
/// HAS NOT BEEN RUN" header is stale (rule 2 leaves a run migration alone).
/// D289 adds the sentence: `course_ratings.note`, 140 characters, written by
/// the same call, plus up to three of YOUR GOLFERS' notes on the read.
///
/// `.unavailable` survives as the honest name for a read that did not happen —
/// no signal, or a database that predates a function — and it is drawn exactly
/// like "not rated", because an unrated course and an unreachable one both
/// show a rail a golfer can still tap.
public struct CourseRating: Sendable, Equatable {
  /// The community's mean, or nil when nobody has rated it.
  public let stars: Double?
  public let count: Int
  /// The mean among golfers the viewer can see, or nil.
  public let friends: Double?
  public let friendsCount: Int
  /// The viewer's own, or nil. **Never zero** — the sheet's third slot reads
  /// `NOT YOURS YET` and its value slot does not render.
  public let mine: Double?
  /// **What YOU said about it** (D289), or nil. 140 characters, one line, and
  /// nil is a real state: a star with no sentence behind it is the common case
  /// and the field is empty rather than absent.
  public let mineNote: String?
  /// Up to three of your golfers' sentences, newest first. Never a stranger's,
  /// and never one with no name behind it — an uncredited opinion is the thing
  /// this product does not print.
  /// The read did not happen: no function on this database, or no signal. It
  /// is not "not rated", and the two are drawn the same way on purpose — an
  /// unrated course and an unreachable one both show the rail a golfer can
  /// still tap. Only the sheet distinguishes them, because only the sheet can
  /// do anything about it.
  public let unavailable: Bool

  public let notes: [CourseNote]

  public init(stars: Double? = nil, count: Int = 0, friends: Double? = nil,
              friendsCount: Int = 0, mine: Double? = nil, mineNote: String? = nil,
              notes: [CourseNote] = [], unavailable: Bool = false) {
    self.stars = stars; self.count = count; self.friends = friends
    self.friendsCount = friendsCount; self.mine = mine; self.mineNote = mineNote
    self.notes = notes; self.unavailable = unavailable
  }

  public static let none = CourseRating(unavailable: true)

  /// *"Your golfers give it {4.9}."* — the marked string the figure run reads.
  /// Empty when none of them has rated it: the line does not render rather
  /// than saying nobody has.
  public var friendsLine: String {
    guard let f = friends, friendsCount > 0 else { return "" }
    return "Your golfers give it {\(String(format: "%.1f", f))}."
  }

  /// *"Rated by twenty-four golfers, four of them yours."* — the sheet's one
  /// line under the two figures. One rating per golfer per course, so a count
  /// of ratings and a count of golfers are the same number and the sentence
  /// says the one a person would.
  ///
  /// **L-33 · small numbers are words**, through `CSCopy.spelled` — the one
  /// producer, rather than a fourth copy of a table this repo has already
  /// written four times.
  public var countLine: String {
    guard count > 0 else { return "" }
    let head = "Rated by \(CSCopy.spelled(count)) golfer\(count == 1 ? "" : "s")"
    guard friendsCount > 0 else { return head + "." }
    return head + ", \(CSCopy.spelled(friendsCount)) of them yours."
  }
}

/// One golfer's sentence about a course (D289). The name is REQUIRED: the
/// producer drops a note whose profile carries no display name, because an
/// uncredited opinion is not one this product prints.
public struct CourseNote: Sendable, Equatable, Identifiable {
  public let who: String
  public let marker: String?
  public let stars: Double?
  public let note: String
  public var id: String { who + "·" + note }
  public init(who: String, marker: String? = nil, stars: Double? = nil, note: String) {
    self.who = who; self.marker = marker; self.stars = stars; self.note = note
  }
  /// *"Galen Marr · 4.5"* — the attribution under the quote.
  public var line: String {
    guard let stars else { return who }
    return "\(who) · \(String(format: "%.1f", stars))"
  }
}

/// `course_rating` · `rate_course` · `unrate_course` · `my_course_ratings`,
/// hand-declared until the owner's push regenerates `Rpc.swift` from the
/// contract (the standing rule — `MyCourseBooksCall` is the precedent, one
/// file over).
public struct CourseRatingCall: RpcCall {
  public static let name = "course_rating"
  public static let optionalArgs: [String] = []
  public typealias Returns = JSONValue
  public var p_course_id: String
  public init(p_course_id: String) { self.p_course_id = p_course_id }
}

/// D289 · `p_note` is DEFAULTED server-side and droppable here, so a client
/// newer than its database still sets the star. **Null leaves the note alone;
/// `""` takes it off** — which is what makes the default safe for a client
/// that predates notes and never sends the argument at all.
public struct RateCourseCall: RpcCall {
  public static let name = "rate_course"
  public static let optionalArgs: [String] = ["p_note"]
  public typealias Returns = JSONValue
  public var p_course_id: String
  public var p_stars: Double
  public var p_note: String?
  public init(p_course_id: String, p_stars: Double, p_note: String? = nil) {
    self.p_course_id = p_course_id; self.p_stars = p_stars; self.p_note = p_note
  }
}

/// `my_course_ratings()` — every course you have rated, best first, in ONE
/// read. The record (`VISUAL_PASS` §5.4) is a list sorted by your own star,
/// and twenty courses cannot be twenty `course_rating` round trips.
public struct MyCourseRatingsCall: RpcCall {
  public static let name = "my_course_ratings"
  public static let optionalArgs: [String] = []
  public typealias Returns = JSONValue
  public init() {}
}

/// One row of the record: your star and sentence at a course, with the
/// community's mean and count beside them.
public struct MyCourseRating: Sendable, Equatable, Identifiable {
  public let courseId: String
  public let mine: Double
  public let note: String?
  public let all: Double?
  public let count: Int
  public var id: String { courseId }
  public init(courseId: String, mine: Double, note: String? = nil,
              all: Double? = nil, count: Int = 0) {
    self.courseId = courseId; self.mine = mine; self.note = note
    self.all = all; self.count = count
  }
}

public struct UnrateCourseCall: RpcCall {
  public static let name = "unrate_course"
  public static let optionalArgs: [String] = []
  public typealias Returns = JSONValue
  public var p_course_id: String
  public init(p_course_id: String) { self.p_course_id = p_course_id }
}

public struct CourseRatingService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  public func rating(_ courseId: String?) async -> CourseRating {
    guard let courseId, !courseId.isEmpty,
          let v = try? await svc.call(CourseRatingCall(p_course_id: courseId)) else { return .none }
    return CourseRatingService.decode(v)
  }

  /// Half stars only. The value is rounded on the way out as well as in the
  /// function, because a control and a constraint should agree before the
  /// round trip rather than after it.
  ///
  /// `note` follows the column's own contract: **nil leaves the sentence
  /// alone, `""` takes it off** (D289). A one-tap rating on the page passes
  /// nil and cannot erase what a golfer wrote in the sheet.
  public func rate(_ courseId: String, stars: Double, note: String? = nil) async throws -> CourseRating {
    let half = (stars * 2).rounded() / 2
    let v = try await svc.call(RateCourseCall(p_course_id: courseId, p_stars: half,
                                              p_note: note.map { String($0.prefix(140)) }))
    return CourseRatingService.decode(v)
  }

  /// The record, in one read. Empty when the read did not happen — the caller
  /// draws the list it already has rather than an emptied one.
  public func mine() async -> [MyCourseRating] {
    guard let v = try? await svc.call(MyCourseRatingsCall()), let rows = v.array else { return [] }
    return rows.compactMap { r in
      guard let id = r["course_id"]?.string, let s = r["stars"]?.double else { return nil }
      return MyCourseRating(courseId: id, mine: s, note: r["note"]?.string,
                            all: r["all"]?.double, count: r["count"]?.int ?? 0)
    }
  }

  public func unrate(_ courseId: String) async throws -> CourseRating {
    let v = try await svc.call(UnrateCourseCall(p_course_id: courseId))
    return CourseRatingService.decode(v)
  }

  /// One decoder for all three calls, because all three return the same
  /// aggregate — the write returns the read, so the client never adds one to a
  /// number it was holding.
  public static func decode(_ v: JSONValue) -> CourseRating {
    CourseRating(stars: v["stars"]?.double,
                 count: v["count"]?.int ?? 0,
                 friends: v["friends"]?.double,
                 friendsCount: v["friends_count"]?.int ?? 0,
                 mine: v["mine"]?.double,
                 mineNote: v["mine_note"]?.string,
                 notes: (v["notes"]?.array ?? []).compactMap { n in
                   guard let who = n["who"]?.string, !who.isEmpty,
                         let note = n["note"]?.string, !note.isEmpty else { return nil }
                   return CourseNote(who: who, marker: n["marker"]?.string,
                                     stars: n["stars"]?.double, note: note)
                 },
                 unavailable: false)
  }
}
