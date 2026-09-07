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

  /// **D291 · the shelf rule, and it is one rule on two clients.** Hardware
  /// is every trophy row; BESTS is a number you beat or a scoring award;
  /// everything else — the first card, the streaks, Iron Man, and any kind a
  /// future migration mints that this build has never heard of — is quiet at
  /// the foot, which is the safe place for an unknown.
  public static func shelf(kind: String?, isHardware: Bool) -> TrophyShelf {
    if isHardware { return .hardware }
    switch kind ?? "" {
    case "sub_100", "sub_90", "sub_80", "personal_best", "low_round", "most_improved": return .bests
    default: return .along
    }
  }

  /// **D291 · a BESTS slat says the round it was won on** — `79 at Papago ·
  /// Aug 24` — because a milestone that opens the afternoon it happened is
  /// the one engaging thing already wired into this surface (`round_id` has
  /// been on `my_achievements` since 2026-09-02) and nobody could find it.
  ///
  /// Every part is optional and every part is dropped rather than faked: no
  /// round in hand → `79 · Aug 24`; no figure anywhere → the date alone; no
  /// date either → nothing, and the slat prints its title and no sub-line.
  public static func milestoneSub(kind: String?, label: String?, meta: JSONValue?,
                                  earnedOn: String?, round: MilestoneRound?) -> String {
    var lead = ""
    let course = round?.courseLabel.flatMap { $0.isEmpty ? nil : RoundCopy.course($0) }
    // A MILESTONE PRINTS THE FIGURE IT IS ABOUT. A threshold is about a gross
    // (`79 at Papago`); a personal best is about the DIFFERENTIAL (D210's "vs
    // course" — `4.1 vs course · Papago`). Taking the gross for both put the
    // same sentence under BROKE 80 and PERSONAL BEST when one round earned
    // them together, which is the owner's own complaint arriving inside the
    // fix for it.
    if kind == "personal_best", let d = meta?["diff"]?.double {
      lead = RoundCopy.f1(d) + " vs course"
      if let course { lead += " · " + course }
    } else if let g = round?.gross ?? meta?["gross"]?.int {
      lead = String(g)
      if let course { lead += " at " + course }
    }
    // NEVER `achSubtitle`'s label fallback here: the slat's own title already
    // reads BROKE 80, and "Broke 80 · Aug 24" beneath it is the name twice
    // (brand canon 3 — one fact, one place). With no figure it is the date.
    let on = round?.playedOn ?? earnedOn
    let when = on.map { BoardText.shortDate($0) } ?? ""
    if lead.isEmpty { return when }
    return when.isEmpty ? lead : lead + " · " + when
  }

  /// D291 · `'26` alone, for the hardware line's own right-flush slot. The
  /// dotted form below stays for the milestone sub-lines it is part of.
  public static func yearTrail(seasonYear: Int?) -> String? {
    guard let y = seasonYear else { return nil }
    return "\u{2019}" + String(String(y).dropFirst(2))
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

/// **D291 · WHICH SHELF a tile sits on.** The case was eleven identical 50pt
/// slats in which a Cup sat at exactly the weight of *"Posted"* — every mark
/// 28pt, every row the same height, nothing outranking anything. `BRIEF` §7
/// says do not make every item visually equal and §8 wants a primary, a
/// secondary and a tertiary; three shelves are those three.
///
/// The rule is the same on both clients (`csTrophyShelf` on the desk, D234),
/// and the ORDER of the cases is the order they render in.
public enum TrophyShelf: String, Sendable, Equatable, CaseIterable {
  /// silverware — every `my_trophies` row: the Cup, the points crown, a
  /// Major, the Ryder, runner-up. **44pt**, with the year trailing.
  case hardware
  /// **what your scoring did** — the thresholds, a personal best, the low
  /// round, most improved. 28pt, and **the slat is a door into the round it
  /// was won on**, which is the change that makes the case engaging at all.
  case bests
  /// **what your turning up did** — the first card, the streaks, Iron Man.
  /// 28pt in `mut`, quiet and doorless.
  case along

  public var head: String {
    switch self {
    case .hardware: "Hardware"
    case .bests: "Bests"
    case .along: "Along the way"
    }
  }
  /// The drawn mark's size on this shelf. This one number is the whole of
  /// "scale and consequence" — the audit's finding was never the glyph.
  public var mark: Double { self == .hardware ? 44 : 28 }
  /// The order the shelves print in.
  public var rank: Int { TrophyShelf.allCases.firstIndex(of: self) ?? 9 }
}

/// D291 · the round a milestone was won on, as much of it as the client
/// holds. The desk keeps 400 rounds in memory and the phone keeps five, so
/// this is `nil` far more often on the phone — and the sub-line degrades to
/// the figure and the date rather than inventing a course (L-44).
public struct MilestoneRound: Sendable, Equatable {
  public let gross: Int?
  public let courseLabel: String?
  public let playedOn: String?
  public init(gross: Int?, courseLabel: String?, playedOn: String?) {
    self.gross = gross; self.courseLabel = courseLabel; self.playedOn = playedOn
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
  /// D291 · which of the three shelves it prints on, and therefore how big
  /// its mark is drawn and whether the slat is a door.
  public let shelf: TrophyShelf
  /// D291 · the right-flush slot on the line — the season year on a piece of
  /// hardware (`'25`), and nil everywhere else. It came OUT of `sub`, where
  /// it was the last two characters of a sentence.
  public let trail: String?
  public init(id: String, glyph: String, numeral: String? = nil, title: String, sub: String,
              roundId: UUID? = nil, shelf: TrophyShelf = .along, trail: String? = nil) {
    self.id = id; self.glyph = glyph; self.numeral = numeral
    self.title = title; self.sub = sub; self.roundId = roundId; self.shelf = shelf; self.trail = trail
  }
}

public enum TrophyCase {
  /// `renderTrophyCase`'s tiles: hardware first, then milestones.
  ///
  /// - round: D291 · what the client knows about the round a milestone was
  ///   won on. Returning `nil` for everything is the honest default and the
  ///   sub-line simply keeps its figure and its date.
  public static func tiles(trophies: [Rpc.my_trophies.Row], achievements: [Achievement],
                           round: (UUID) -> MilestoneRound? = { _ in nil }) -> [TrophyTile] {
    var out: [TrophyTile] = []
    for t in trophies {
      let key = t.id?.uuidString ?? "\(t.title ?? t.kind ?? "")|\(t.season_year.map(String.init) ?? t.earned_on ?? "")"
      out.append(TrophyTile(id: "t" + key,
                            glyph: TrophyMeta.trophyGlyph(kind: t.kind, placement: t.placement),
                            title: t.title ?? "—",
                            sub: t.subtitle ?? t.kind ?? "",
                            shelf: .hardware,
                            trail: TrophyMeta.yearTrail(seasonYear: t.season_year)))
    }
    for a in achievements {
      let key = "\(a.label ?? a.kind ?? "")|\(a.earned_on ?? "")"
      let m = TrophyMeta.meta(kind: a.kind, label: a.label)
      // `low_round` carries its gross INSIDE the mark — the numeral is the
      // achievement, and a rule under it is the product's own signature.
      let numeral = m.glyph == "lowRound" ? (a.meta?["gross"]?.int).map(String.init) : m.numeral
      let shelf = TrophyMeta.shelf(kind: a.kind, isHardware: false)
      // A BESTS slat names its round; the quiet shelf keeps the dated line it
      // has always had, because "Posted · '26" is the whole of that fact.
      let sub = shelf == .bests
        ? TrophyMeta.milestoneSub(kind: a.kind, label: a.label, meta: a.meta,
                                  earnedOn: a.earned_on, round: a.round_id.flatMap(round))
        : TrophyMeta.achSubtitle(kind: a.kind, label: a.label, meta: a.meta) + TrophyMeta.yearTag(earnedOn: a.earned_on)
      out.append(TrophyTile(id: "a" + key, glyph: m.glyph, numeral: numeral, title: m.title,
                            sub: sub, roundId: a.round_id, shelf: shelf))
    }
    return out
  }

  /// **D291 · the case, grouped.** Three shelves in `TrophyShelf`'s own
  /// order, each with its head, and **an empty shelf is absent** — a head
  /// over nothing is a heading that lies about what is under it.
  public static func shelves(_ tiles: [TrophyTile]) -> [(shelf: TrophyShelf, tiles: [TrophyTile])] {
    TrophyShelf.allCases.compactMap { s in
      let rows = tiles.filter { $0.shelf == s }
      return rows.isEmpty ? nil : (s, rows)
    }
  }

  /// **D291 · the empty, given a shape** (§17). Four marks a golfer has NOT
  /// cut, drawn at 12%, under one head and one sentence — never a card with a
  /// grey line in it. The keys are `CSTrophyMark.Mark`'s and the numerals the
  /// thresholds', so the row is four real marks and not four placeholders.
  public static let emptyMarks: [(glyph: String, numeral: String?)] =
    [("cup", nil), ("threshold", "80"), ("personalBest", nil), ("crown", nil)]
  public static let emptyHead = "The case is empty"
  public static let emptyLead = "Break 80, post a first round, or win a Cup Final."

  // Y-02's `emptyLine` — one 118-character grey sentence inside a card — is
  // DELETED. D291 gives the empty a SHAPE (§17): the four marks above, the
  // head and the lead. Both clients render that; nothing renders a paragraph.
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
