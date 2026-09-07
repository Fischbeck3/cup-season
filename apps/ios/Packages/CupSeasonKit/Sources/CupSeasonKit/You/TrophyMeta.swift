// Cup Season — the display case (index.html `trophyIcon` 11030, `ACH_META`
// 11032–11041, `achSubtitle` 11042–11048, `renderTrophyCase` 11051–11085).
//
// Two systems share the case: TROPHIES (season hardware — cups, crowns, the
// Ryder, a Major) and ACHIEVEMENTS (career milestones — first round, broke
// 80, streaks). Icons are the web's, verbatim; emoji stay emoji.

import Foundation

/// The fields the case reads off an achievement — the generated
/// `Rpc.my_achievements.Row` has them, and so does `Achievement` below.
public protocol AchievementFields {
  var kind: String? { get }
  var label: String? { get }
  var earned_on: String? { get }
  var meta: JSONValue? { get }
}
extension Rpc.my_achievements.Row: AchievementFields {}

/// Y-20 · `my_achievements()` as the You tab decodes it: the generated row
/// plus the OPTIONAL `round_id` the server is gaining — a missing key decodes
/// to nil (deploy skew), and a tile without one is inert rather than broken.
public struct Achievement: AchievementFields, Decodable, Sendable, Equatable {
  public let kind: String?
  public let label: String?
  public let earned_on: String?
  public let meta: JSONValue?
  public let round_id: UUID?
  public init(kind: String?, label: String?, earned_on: String?, meta: JSONValue?, round_id: UUID? = nil) {
    self.kind = kind; self.label = label; self.earned_on = earned_on; self.meta = meta; self.round_id = round_id
  }
}

public struct AchMeta: Sendable, Equatable {
  /// The DRAWN mark's key (`CSTrophyMark.Mark`), never an emoji. The Kit sits
  /// below `CSDesign`, so it names the mark and the view draws it — the same
  /// contract the marker table already uses.
  public let glyph: String
  /// The value the mark carries when the mark is parametric: `80` inside the
  /// crossed threshold, `4` for a run of four weeks. nil for a pure drawing.
  public let numeral: String?
  public let title: String
  public init(glyph: String, numeral: String? = nil, title: String) {
    self.glyph = glyph; self.numeral = numeral; self.title = title
  }
}

public enum TrophyMeta {
  /// **The hardware's drawn mark.** A Cup, a major and an event are
  /// silverware and take the cup; a points crown is a season won on the
  /// TABLE and takes the filled disc on a rail, which ladders to the rank
  /// rail rather than inventing a second trophy; second place takes the open
  /// disc one notch down. §5.2: **two achievements may never share a glyph**,
  /// and the shipped case drew 🏆 for all four of these.
  public static func trophyGlyph(kind: String?, placement: String?) -> String {
    if placement == "runner_up" { return "runnerUp" }
    switch kind {
    case "ryder":   return "duel"
    case "bracket": return "bracket"
    case "points_king", "crown": return "crown"
    default:
      return placement == "points_king" ? "crown" : "cup"
    }
  }

  /// `ACH_META` — career milestones → the drawn mark, its numeral, and the
  /// title. **`sub_100` and `sub_90` no longer share 🎯 and `streak_4` and
  /// `streak_8` no longer share 📈**: the mark is the same shape and the
  /// NUMERAL inside it is the difference, which is the whole of §5.2.
  public static let ach: [String: AchMeta] = [
    "first_round": AchMeta(glyph: "firstCard", title: "First round"),
    "sub_100": AchMeta(glyph: "threshold", numeral: "100", title: "Broke 100"),
    "sub_90": AchMeta(glyph: "threshold", numeral: "90", title: "Broke 90"),
    "sub_80": AchMeta(glyph: "threshold", numeral: "80", title: "Broke 80"),
    "personal_best": AchMeta(glyph: "personalBest", title: "Personal best"),
    "streak_4": AchMeta(glyph: "streak", numeral: "4", title: "4-week streak"),
    "streak_8": AchMeta(glyph: "streak", numeral: "8", title: "8-week streak"),
    "streak_12": AchMeta(glyph: "ironman", title: "Iron Man"),
    "low_round": AchMeta(glyph: "lowRound", title: "Low round of the season"),
    "most_improved": AchMeta(glyph: "improved", title: "Most improved"),
  ]

  /// A kind this build has no mark for draws the medal — a real mark rather
  /// than a hole in the case.
  public static func meta(kind: String?, label: String?) -> AchMeta {
    if let kind, let m = ach[kind] { return m }
    return AchMeta(glyph: "medal", title: (label ?? "").isEmpty ? "Milestone" : label!)
  }

  /// `achSubtitle(a)`. D210 · the personal best is the engine's lowest
  /// round vs course (IOS-016's mechanic); the receipt's own name for that
  /// figure is "Round vs course", so the tile says "7.8 vs course" — never
  /// the banned word, never a bare float.
  public static func achSubtitle(kind: String?, label: String?, meta: JSONValue?) -> String {
    let k = kind ?? ""
    if k == "personal_best", let d = meta?["diff"]?.double { return "\(RoundCopy.f1(d)) vs course" }
    if k.hasPrefix("sub_"), let g = meta?["gross"]?.int { return "\(g) gross" }
    if k.hasPrefix("streak_"), let w = meta?["weeks"]?.int { return "\(w) weeks" }
    if k == "first_round" { return "Posted" }
    return label ?? ""
  }

  /// `" · '26"` from a season year, or "" — `String(year).slice(2)`.
  public static func yearTag(seasonYear: Int?) -> String {
    guard let y = seasonYear else { return "" }
    return " · '" + String(String(y).dropFirst(2))
  }
  /// `" · '26"` from an earned_on date string, or "" — `slice(2,4)`.
  public static func yearTag(earnedOn: String?) -> String {
    guard let e = earnedOn, e.count >= 4 else { return "" }
    let s = e.index(e.startIndex, offsetBy: 2), t = e.index(e.startIndex, offsetBy: 4)
    return " · '" + String(e[s..<t])
  }

  /// Y-33 · an engraved line as VoiceOver should HEAR it. Kept for the one
  /// caller that still speaks a produced line; the emoji-prefixed credential
  /// chips it was written for are deleted with the hero (YRS-03).
  public static func spoken(_ line: String) -> String {
    guard let first = line.first, !first.isLetter, !first.isNumber, first != "+" else { return line }
    return String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
  }
}

/// One tile in the case.
public struct TrophyTile: Sendable, Identifiable, Equatable {
  public let id: String
  /// The DRAWN mark's key — `CSTrophyMark.Mark`'s raw value, never an emoji.
  public let glyph: String
  /// The value inside a parametric mark (`80`, `4`), nil for a pure drawing.
  public let numeral: String?
  public let title: String
  public let sub: String
  /// Y-20 · the round the milestone was earned on — a door to its receipt when set
  public let roundId: UUID?
  public init(id: String, glyph: String, numeral: String? = nil, title: String, sub: String, roundId: UUID? = nil) {
    self.id = id; self.glyph = glyph; self.numeral = numeral
    self.title = title; self.sub = sub; self.roundId = roundId
  }
}

public enum TrophyCase {
  /// `renderTrophyCase`'s tiles: hardware first, then milestones.
  public static func tiles(trophies: [Rpc.my_trophies.Row], achievements: [Achievement]) -> [TrophyTile] {
    var out: [TrophyTile] = []
    for t in trophies {
      let key = t.id?.uuidString ?? "\(t.title ?? t.kind ?? "")|\(t.season_year.map(String.init) ?? t.earned_on ?? "")"
      out.append(TrophyTile(id: "t" + key,
                            glyph: TrophyMeta.trophyGlyph(kind: t.kind, placement: t.placement),
                            title: t.title ?? "—",
                            sub: (t.subtitle ?? t.kind ?? "") + TrophyMeta.yearTag(seasonYear: t.season_year)))
    }
    for a in achievements {
      let key = "\(a.label ?? a.kind ?? "")|\(a.earned_on ?? "")"
      let m = TrophyMeta.meta(kind: a.kind, label: a.label)
      // `low_round` carries its gross INSIDE the mark — the numeral is the
      // achievement, and a rule under it is the product's own signature.
      let numeral = m.glyph == "lowRound" ? (a.meta?["gross"]?.int).map(String.init) : m.numeral
      out.append(TrophyTile(id: "a" + key, glyph: m.glyph, numeral: numeral, title: m.title,
                            sub: TrophyMeta.achSubtitle(kind: a.kind, label: a.label, meta: a.meta) + TrophyMeta.yearTag(earnedOn: a.earned_on),
                            roundId: a.round_id))
    }
    return out
  }

  /// Y-02 · THE one empty state for a case with nothing in it. The record
  /// strip above it renders nothing when it has no items, so a new golfer
  /// reads one sentence, not two.
  public static let emptyLine = "Nothing in the case yet. Break 80, post your first round, or win a Cup Final — milestones and trophies land here."
}

/// Which tiles this device has already shown — a tile only engraves on
/// ARRIVAL (the web's `_trophySeen`, kept per session; here it persists so a
/// trophy that landed since the last open takes its name behind the needle).
public struct TrophySeenStore: Sendable {
  let key: String
  public init(userId: UUID) { key = "cs_trophy_seen_\(userId.uuidString)" }
  /// nil = never rendered on this device (first paint engraves nothing).
  public func load() -> Set<String>? {
    (UserDefaults.standard.array(forKey: key) as? [String]).map(Set.init)
  }
  public func save(_ ids: Set<String>) { UserDefaults.standard.set(Array(ids).sorted(), forKey: key) }
  /// The ids to engrave this paint: those not in the stored set (none when
  /// the store is empty — first paint is a boot render, not an arrival).
  public static func fresh(_ tiles: [TrophyTile], seen: Set<String>?) -> Set<String> {
    guard let seen else { return [] }
    return Set(tiles.map(\.id)).subtracting(seen)
  }
}
