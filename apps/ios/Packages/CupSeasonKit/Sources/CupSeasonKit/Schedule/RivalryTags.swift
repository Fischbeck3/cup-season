// Cup Season — the pre-game record (`rivalryTag`, index.html 15732; M4/#7).
//
// A rival's round on the watch list — or their round sheet — wears the
// head-to-head BEFORE the round. Derived from `my_rivalries`, pure client.

import Foundation

public struct RivalryTag: Sendable, Equatable {
  /// "“The Grudge” · " or ""
  public let name: String
  /// "you lead 4–3 in the season · 7 weeks" · "Galen leads 4–3 in the season
  /// · 7 weeks" · "even 3–3 in the season · 6 weeks" · the duel forms
  public let record: String
  public var text: String { name + record }

  /// nil when there is nothing to say yet.
  ///
  /// X36 (1) · owner ruling 2026-09-29: the tag NAMES WHAT IT COUNTS. Season
  /// weeks are "in the season · N weeks", and the fallback's duels are "in
  /// Ryder clashes" — never a bare "clashes", which also names the weekly
  /// clash. Web twin: `rivalryTag` (bfce5aea).
  public static func of(_ pid: UUID?, rivals: [Rpc.my_rivalries.Row]) -> RivalryTag? {
    guard let pid, let r = rivals.first(where: { $0.opponent == pid }) else { return nil }
    let first = (r.display_name ?? "They").split(separator: " ").first.map(String.init) ?? "They"
    let w = r.wins ?? 0, l = r.losses ?? 0
    var rec: String?
    if let n = r.meetings, n > 0 {
      let wks = " in the season · \(n) week\(n == 1 ? "" : "s")"
      rec = w > l ? "you lead \(w)–\(l)\(wks)" : w < l ? "\(first) leads \(l)–\(w)\(wks)" : "even \(w)–\(l)\(wks)"
    } else {
      let dw = r.duel_wins ?? 0, dl = r.duel_losses ?? 0
      if dw != 0 || dl != 0 {
        rec = dw > dl ? "you lead \(dw)–\(dl) in Ryder clashes"
            : dw < dl ? "\(first) leads \(dl)–\(dw) in Ryder clashes"
            : "even \(dw)–\(dl) in Ryder clashes"
      }
    }
    guard let rec else { return nil }
    return RivalryTag(name: r.rivalry_name.map { "“\($0)” · " } ?? "", record: rec)
  }
}

/// `ensureRivals` (15724): one read, cached for the session.
public actor RivalsCache {
  public static let shared = RivalsCache()
  private var rows: [Rpc.my_rivalries.Row]?

  public func rivals(_ svc: SupabaseService = .shared) async -> [Rpc.my_rivalries.Row] {
    if let rows { return rows }
    let r = (try? await svc.call(Rpc.my_rivalries())) ?? []
    rows = r
    return r
  }

  public func invalidate() { rows = nil }
}
