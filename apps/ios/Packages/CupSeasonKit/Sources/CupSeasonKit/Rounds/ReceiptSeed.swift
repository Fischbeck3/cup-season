// Cup Season — the round receipt's facts (D95, index.html 11317–11418).
//
// The sheet opens INSTANTLY from whatever row the caller held, then enriches
// from `round_card()`. "Anything missing is simply absent — a receipt never
// guesses at a number it does not hold." The seed is that row; `ReceiptRows`
// is `roundCardBody`, line for line.

import Foundation

/// A round as some surface held it: a `rounds` row, a `home_feed` item, an
/// album cell, or the full `round_card` payload. Every field optional.
public struct ReceiptSeed: Sendable, Equatable {
  public var id: UUID?
  public var profileId: UUID?
  public var gross: Int?
  public var differential: Double?
  public var indexAtPost: Double?
  public var playedOn: String?
  public var courseLabel: String?
  public var holesPlayed: Int?
  public var photoPath: String?
  public var photoURL: URL?
  public var rating: Double?
  public var slope: Int?
  public var nineRating: Double?
  public var pvi: Double?
  public var points: Double?
  public var monthRank: Int?
  public var countingCap: Int?
  public var attested: Bool?
  public var playedWith: [String]
  public var liveRoundId: UUID?
  public var isMine: Bool?
  /// The poster's marker for the medallion (`memberMarker` on the web) —
  /// carried by the caller because `round_card` does not return it.
  public var marker: String?

  public init(id: UUID? = nil, profileId: UUID? = nil, gross: Int? = nil, differential: Double? = nil, indexAtPost: Double? = nil,
              playedOn: String? = nil, courseLabel: String? = nil, holesPlayed: Int? = nil, photoPath: String? = nil, photoURL: URL? = nil,
              rating: Double? = nil, slope: Int? = nil, nineRating: Double? = nil, pvi: Double? = nil, points: Double? = nil,
              monthRank: Int? = nil, countingCap: Int? = nil, attested: Bool? = nil, playedWith: [String] = [], liveRoundId: UUID? = nil,
              isMine: Bool? = nil, marker: String? = nil) {
    self.id = id; self.profileId = profileId; self.gross = gross; self.differential = differential; self.indexAtPost = indexAtPost
    self.playedOn = playedOn; self.courseLabel = courseLabel; self.holesPlayed = holesPlayed; self.photoPath = photoPath; self.photoURL = photoURL
    self.rating = rating; self.slope = slope; self.nineRating = nineRating; self.pvi = pvi; self.points = points
    self.monthRank = monthRank; self.countingCap = countingCap; self.attested = attested; self.playedWith = playedWith; self.liveRoundId = liveRoundId
    self.isMine = isMine; self.marker = marker
  }

  /// `r.pvi ?? index_at_post − differential` (11374, 11399).
  public var resolvedPvi: Double? {
    if let pvi { return pvi }
    if let i = indexAtPost, let d = differential { return i - d }
    return nil
  }

  /// Header title: "<gross> gross", else "The round".
  public var title: String { gross.map { "\($0) gross" } ?? "The round" }

  /// Header sub: "COURSE · 18 HOLES · DATE" — "somewhere out there" only when
  /// no surface has named the course yet (the D95 fallback).
  public var subtitle: String {
    [courseLabel ?? "somewhere out there", "\(holesPlayed ?? 18) holes", playedOn ?? ""]
      .filter { !$0.isEmpty }.joined(separator: " · ").uppercased()
  }

  /// `Object.assign({}, seed, data)` — every key the payload carries wins,
  /// null included; keys it does not carry (photo_url, marker) survive.
  public func merged(with json: JSONValue) -> ReceiptSeed {
    guard case .object(let o) = json else { return self }
    var r = self
    func has(_ k: String) -> Bool { o[k] != nil }
    if has("id") { r.id = o["id"]?.string.flatMap(UUID.init) }
    if has("profile_id") { r.profileId = o["profile_id"]?.string.flatMap(UUID.init) }
    if has("gross") { r.gross = o["gross"]?.int }
    if has("differential") { r.differential = o["differential"]?.double }
    if has("index_at_post") { r.indexAtPost = o["index_at_post"]?.double }
    if has("played_on") { r.playedOn = o["played_on"]?.string }
    if has("course_label") { r.courseLabel = o["course_label"]?.string }
    else if has("course") { r.courseLabel = o["course"]?.string }          // the D95 alias
    if has("holes_played") { r.holesPlayed = o["holes_played"]?.int }
    if has("photo_path") { r.photoPath = o["photo_path"]?.string }
    if has("photo_url") { r.photoURL = o["photo_url"]?.string.flatMap(URL.init) }
    if has("rating") { r.rating = o["rating"]?.double }
    if has("slope") { r.slope = o["slope"]?.int }
    if has("nine_rating") { r.nineRating = o["nine_rating"]?.double }
    if has("pvi") { r.pvi = o["pvi"]?.double }
    if has("points") { r.points = o["points"]?.double }
    if has("month_rank") { r.monthRank = o["month_rank"]?.int }
    if has("counting_cap") { r.countingCap = o["counting_cap"]?.int }
    if has("attested") { r.attested = o["attested"]?.bool }
    if has("played_with") { r.playedWith = (o["played_with"]?.array ?? []).compactMap(\.string).filter { !$0.isEmpty } }
    if has("live_round_id") { r.liveRoundId = o["live_round_id"]?.string.flatMap(UUID.init) }
    if has("is_mine") { r.isMine = o["is_mine"]?.bool }
    if has("marker") { r.marker = o["marker"]?.string }
    return r
  }

  /// A seed from any jsonb row (a feed item, a cached round).
  public static func from(json: JSONValue) -> ReceiptSeed { ReceiptSeed().merged(with: json) }
}

/// One line of the receipt. `sub` is the web's `.mathrow.sub` (the arithmetic
/// and the index-that-day line, quieter than the verdict rows).
public enum ReceiptRow: Sendable, Equatable, Identifiable {
  case math(label: String, value: String, sub: Bool)
  case playedWith([String])
  case scorecard(UUID)

  public var id: String {
    switch self {
    case .math(let l, _, _): "m:\(l)"
    case .playedWith: "with"
    case .scorecard(let id): "sc:\(id)"
    }
  }
}

public enum ReceiptRows {
  /// `roundCardBody(r, pvi, capN)` — called twice: once with the row the
  /// caller had (instant), once with the full payload.
  /// - capN: the league's counting cap; nil = unlimited (the web's `Infinity`).
  /// - viewerId: decides "Your" vs "Their" when the row lacks `is_mine`.
  public static func build(_ r: ReceiptSeed, capN: Int?, viewerId: UUID?) -> [ReceiptRow] {
    let mine = r.isMine ?? (r.profileId == nil || r.profileId == viewerId)
    var rows: [ReceiptRow] = []

    // THE COURSE AND ITS TEETH — an 86 means nothing until you know the course was 64.9/111.
    if let rating = r.rating, let slope = r.slope {
      rows.append(.math(label: "The course", value: "\(RoundCopy.f1(rating)) / \(slope)", sub: false))
    }
    // the arithmetic, shown rather than asserted (§16)
    if let diff = r.differential, let rating = r.rating, let slope = r.slope, let gross = r.gross {
      let holes = r.holesPlayed == 9 ? 9 : 18
      let rt = (holes == 9 && r.nineRating != nil) ? r.nineRating! : rating
      rows.append(.math(label: "\(gross) − \(RoundCopy.f1(rt)) × 113 ⁄ \(slope)", value: "\(RoundCopy.f1(diff)) DIFFERENTIAL", sub: true))
    }
    if let idx = r.indexAtPost {
      rows.append(.math(label: "\(mine ? "Your" : "Their") number that day", value: RoundCopy.f1(idx), sub: true))
    }
    if let pvi = r.resolvedPvi {
      let band = mine ? RoundCopy.bandName(pvi) : RoundCopy.theirs(RoundCopy.bandName(pvi))
      rows.append(.math(label: mine ? "Against your number" : "Against their number",
                        value: "\(pvi >= 0 ? "+" : "")\(RoundCopy.f1(pvi)) — \(band.uppercased())", sub: false))
    }
    if let pts = r.points { rows.append(.math(label: "Points", value: CSCopy.points(pts), sub: false)) }
    if let rank = r.monthRank {
      let cap = r.countingCap ?? capN
      let counting = cap.map { rank <= $0 } ?? true
      rows.append(.math(label: "This month", value: counting ? "COUNTING #\(rank)" : "BUMPED", sub: false))
    }
    if r.holesPlayed == 9 { rows.append(.math(label: "Nine holes", value: "HALF VALUE · HALF A ROUND", sub: false)) }
    if r.attested == true { rows.append(.math(label: "Attested", value: "PLAYED WITH THE GROUP", sub: false)) }
    if !r.playedWith.isEmpty { rows.append(.playedWith(r.playedWith)) }
    if let live = r.liveRoundId { rows.append(.scorecard(live)) }
    return rows
  }
}

/// The web's `window.roundCache`: a surface that lists rounds drops the rows it
/// held here, so a receipt opened by id still opens instantly.
public actor ReceiptCache {
  public static let shared = ReceiptCache()
  private var rows: [UUID: ReceiptSeed] = [:]
  public func put(_ seed: ReceiptSeed) { if let id = seed.id { rows[id] = seed } }
  public func put(_ seeds: [ReceiptSeed]) { for s in seeds { put(s) } }
  public func get(_ id: UUID) -> ReceiptSeed? { rows[id] }
}
