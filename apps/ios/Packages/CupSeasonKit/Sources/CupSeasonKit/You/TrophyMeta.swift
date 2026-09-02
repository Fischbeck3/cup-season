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
  public let icon: String
  public let title: String
  public init(icon: String, title: String) { self.icon = icon; self.title = title }
}

public enum TrophyMeta {
  /// `trophyIcon(kind)`.
  public static func trophyIcon(_ kind: String?) -> String {
    kind == "ryder" ? "⚔️" : kind == "bracket" ? "🥊" : "🏆"
  }

  /// `ACH_META` — career milestones (achievements table) → tile icon + title.
  public static let ach: [String: AchMeta] = [
    "first_round": AchMeta(icon: "⛳", title: "First round"),
    "sub_100": AchMeta(icon: "🎯", title: "Broke 100"),
    "sub_90": AchMeta(icon: "🎯", title: "Broke 90"),
    "sub_80": AchMeta(icon: "🔥", title: "Broke 80"),
    "personal_best": AchMeta(icon: "📉", title: "Personal best"),
    "streak_4": AchMeta(icon: "📈", title: "4-week streak"),
    "streak_8": AchMeta(icon: "📈", title: "8-week streak"),
    "streak_12": AchMeta(icon: "💪", title: "Iron Man"),
  ]

  /// `ACH_META[a.kind] || {icon:'🏅', title:a.label||'Milestone'}`
  public static func meta(kind: String?, label: String?) -> AchMeta {
    if let kind, let m = ach[kind] { return m }
    return AchMeta(icon: "🏅", title: (label ?? "").isEmpty ? "Milestone" : label!)
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

  /// How many engraved chips a credential shows before "+N more". The You hero
  /// showed 3 and the Tour Card 4, for no reason either surface could name —
  /// ONE constant now, so the phone and the web twin (`#youTros`, `trosLines`)
  /// can be held to the same number in one place.
  public static let credentialChips = 3
  /// What follows "+N" on your own credential — the hero says where the rest
  /// are. Someone else's Tour Card passes its own suffix; there is no case of
  /// theirs to open from it.
  public static let moreInCase = " more in the case"
  /// The other half of "+N more in the case" — the row folds back the same way
  /// it opened, so the expansion is not a one-way door.
  public static let showFewer = "Show fewer"

  /// The credential's engraved lines (`#youTros`, Tour Card `trosLines`):
  /// "🔥 Broke 80 · '26", then "+N more in the case" / "+N more".
  public static func credLines<A: AchievementFields>(_ achievements: [A], max: Int = TrophyMeta.credentialChips,
                                                     moreSuffix: String = TrophyMeta.moreInCase) -> [String] {
    var lines = credChips(achievements.prefix(max))
    if achievements.count > max { lines.append(moreLine(achievements.count - max, suffix: moreSuffix)) }
    return lines
  }
  /// Every engraved line, no "+N more" — the hero expands to these in place.
  public static func credChips<S: Sequence>(_ achievements: S) -> [String] where S.Element: AchievementFields {
    achievements.map { a in
      let m = meta(kind: a.kind, label: a.label)
      return "\(m.icon) \(m.title)\(yearTag(earnedOn: a.earned_on))"
    }
  }
  /// "+2 more in the case"
  public static func moreLine(_ n: Int, suffix: String) -> String { "+\(n)\(suffix)" }

  /// Y-33 · an engraved line as VoiceOver should HEAR it: the leading icon is
  /// decoration ("fire", "chart increasing" is not a milestone), so it is
  /// dropped. The visible line keeps it — this is the spoken twin only.
  public static func spoken(_ line: String) -> String {
    guard let first = line.first, !first.isLetter, !first.isNumber, first != "+" else { return line }
    return String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
  }
}

/// One tile in the case.
public struct TrophyTile: Sendable, Identifiable, Equatable {
  public let id: String
  public let icon: String
  public let title: String
  public let sub: String
  /// Y-20 · the round the milestone was earned on — a door to its receipt when set
  public let roundId: UUID?
  public init(id: String, icon: String, title: String, sub: String, roundId: UUID? = nil) {
    self.id = id; self.icon = icon; self.title = title; self.sub = sub; self.roundId = roundId
  }
}

public enum TrophyCase {
  /// `renderTrophyCase`'s tiles: hardware first, then milestones.
  public static func tiles(trophies: [Rpc.my_trophies.Row], achievements: [Achievement]) -> [TrophyTile] {
    var out: [TrophyTile] = []
    for t in trophies {
      let key = t.id?.uuidString ?? "\(t.title ?? t.kind ?? "")|\(t.season_year.map(String.init) ?? t.earned_on ?? "")"
      out.append(TrophyTile(id: "t" + key, icon: TrophyMeta.trophyIcon(t.kind), title: t.title ?? "—",
                            sub: (t.subtitle ?? t.kind ?? "") + TrophyMeta.yearTag(seasonYear: t.season_year)))
    }
    for a in achievements {
      let key = "\(a.label ?? a.kind ?? "")|\(a.earned_on ?? "")"
      let m = TrophyMeta.meta(kind: a.kind, label: a.label)
      out.append(TrophyTile(id: "a" + key, icon: m.icon, title: m.title,
                            sub: TrophyMeta.achSubtitle(kind: a.kind, label: a.label, meta: a.meta) + TrophyMeta.yearTag(earnedOn: a.earned_on),
                            roundId: a.round_id))
    }
    return out
  }

  /// Y-02 · THE one empty state for a case with nothing in it. The record
  /// strip above it renders nothing when it has no items, so a new golfer
  /// reads one sentence, not two.
  public static let emptyLine = "No hardware yet. Break 80, post your first round, or win a Cup Final — milestones and trophies land here."
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
