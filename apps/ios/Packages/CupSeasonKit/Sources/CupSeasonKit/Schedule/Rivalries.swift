// Cup Season — the pre-game record (`rivalryTag`, index.html 15732; M4/#7).
//
// A rival's round on the watch list — or their round sheet — wears the
// head-to-head BEFORE the round. Derived from `my_rivalries`, pure client.

import Foundation

public struct RivalryTag: Sendable, Equatable {
  /// "“The Grudge” · " or ""
  public let name: String
  /// "you lead 3–1" · "Galen leads 2–1" · "even 1–1" · the duel forms
  public let record: String
  public var text: String { name + record }

  /// nil when there is nothing to say yet.
  public static func of(_ pid: UUID?, rivals: [Rpc.my_rivalries.Row]) -> RivalryTag? {
    guard let pid, let r = rivals.first(where: { $0.opponent == pid }) else { return nil }
    let first = (r.display_name ?? "They").split(separator: " ").first.map(String.init) ?? "They"
    let w = r.wins ?? 0, l = r.losses ?? 0
    var rec: String?
    if (r.meetings ?? 0) > 0 {
      rec = w > l ? "you lead \(w)–\(l)" : w < l ? "\(first) leads \(l)–\(w)" : "even \(w)–\(l)"
    } else {
      let dw = r.duel_wins ?? 0, dl = r.duel_losses ?? 0
      if dw != 0 || dl != 0 {
        rec = dw > dl ? "you lead duels \(dw)–\(dl)" : dw < dl ? "\(first) leads duels \(dl)–\(dw)" : "even in duels \(dw)–\(dl)"
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
