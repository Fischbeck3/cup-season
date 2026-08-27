// Cup Season — the display case (index.html `trophyIcon` 11030, `ACH_META`
// 11032–11041, `achSubtitle` 11042–11048, `renderTrophyCase` 11051–11085).
//
// Two systems share the case: TROPHIES (season hardware — cups, crowns, the
// Ryder, a Major) and ACHIEVEMENTS (career milestones — first round, broke
// 80, streaks). Icons are the web's, verbatim; emoji stay emoji.

import Foundation

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

  /// `achSubtitle(a)`.
  public static func achSubtitle(kind: String?, label: String?, meta: JSONValue?) -> String {
    let k = kind ?? ""
    if k == "personal_best", let d = meta?["diff"]?.double { return "Diff \(RoundCopy.f1(d))" }
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

  /// The credential's engraved lines (`#youTros`, Tour Card `trosLines`):
  /// "🔥 Broke 80 · '26", then "+N more in the case" / "+N more".
  public static func credLines(_ achievements: [Rpc.my_achievements.Row], max: Int, moreSuffix: String) -> [String] {
    var lines = achievements.prefix(max).map { a in
      let m = meta(kind: a.kind, label: a.label)
      return "\(m.icon) \(m.title)\(yearTag(earnedOn: a.earned_on))"
    }
    if achievements.count > max { lines.append("+\(achievements.count - max)\(moreSuffix)") }
    return lines
  }
}

/// One tile in the case.
public struct TrophyTile: Sendable, Identifiable, Equatable {
  public let id: String
  public let icon: String
  public let title: String
  public let sub: String
  public init(id: String, icon: String, title: String, sub: String) { self.id = id; self.icon = icon; self.title = title; self.sub = sub }
}

public enum TrophyCase {
  /// `renderTrophyCase`'s tiles: hardware first, then milestones.
  public static func tiles(trophies: [Rpc.my_trophies.Row], achievements: [Rpc.my_achievements.Row]) -> [TrophyTile] {
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
                            sub: TrophyMeta.achSubtitle(kind: a.kind, label: a.label, meta: a.meta) + TrophyMeta.yearTag(earnedOn: a.earned_on)))
    }
    return out
  }

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
