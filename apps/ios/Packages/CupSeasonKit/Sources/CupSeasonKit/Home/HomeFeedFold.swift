// Cup Season — D217 · the feed folds its league notes (the Home hard-look,
// 2026-09-02).
//
// Today's stream, unfolded, is seven system lines over two leagues in a row —
// "This week: Galen v Jerecho." · "The clash this week: Galen v Jerecho." ·
// the same two for the Fellas · "August is in the books…" twice, word for
// word — before the first round a person played. The notes are true and each
// one belongs in its league's Notices; on Home they bury the golf.
//
// The fold is pure and fixed, so the same rows always fold the same way:
//
//   1. a system line whose booking is already on the Coming-up card
//      (`scheduled_round_id` in the caller's upcoming set) is HIDDEN — the
//      card is the better door;
//   2. identical bodies across leagues within 48 hours (the month-close line,
//      posted per league by one job) collapse to ONE line carrying every
//      league's name;
//   3. what is left collapses to ONE `.notes` per league (per league-set) per
//      bucket — "Who's the bitch? · 2 league notes this week" — a door to that
//      league's Notices;
//   4. rounds and moments pass through untouched, in their order.
//
// A door exists iff a row knows its round: `live_round_id ?? round_id ??
// scheduled_round_id` (D219). A line that knows nothing is a plain line.

import Foundation

/// Where a feed line leads. Live first — a live round is the round.
public enum HomeFeedDoor: Sendable, Equatable {
  case live(UUID)
  case round(UUID)
  case scheduled(UUID)
}

/// One folded group of league notes.
public struct HomeFeedNotes: Sendable, Identifiable, Equatable {
  /// The leagues these notes belong to, in first-seen (newest) order.
  public let leagueIds: [UUID]
  public let leagueNames: [String]
  /// The notes themselves, newest first — one per distinct line.
  public let rows: [HomePost]
  public var count: Int { rows.count }
  public var newest: HomePost? { rows.first }
  public var id: String { "n-" + leagueIds.map(\.uuidString).joined(separator: "+") + "-" + (rows.first?.id.uuidString ?? "") }

  public init(leagueIds: [UUID], leagueNames: [String], rows: [HomePost]) {
    self.leagueIds = leagueIds; self.leagueNames = leagueNames; self.rows = rows
  }

  /// "Who's the bitch? · 2 league notes this week" / "Fellas & Who's the
  /// bitch? · 1 league note today" / "Fellas · 3 earlier league notes".
  /// `bucket` is the bucket's label: "today" and "this week" are a when and
  /// read after the noun; "earlier" is an adjective and reads before it
  /// ("3 league notes earlier" is not a sentence anyone says).
  public func line(bucket: String) -> String {
    let names = leagueNames.isEmpty ? "League" : leagueNames.joined(separator: " & ")
    let noun = "league note\(count == 1 ? "" : "s")"
    let when = bucket.lowercased()
    if when == "earlier" { return "\(names) · \(count) earlier \(noun)" }
    return "\(names) · \(count) \(noun) \(when)"
  }
}

public enum HomeFeedItem: Sendable, Identifiable {
  case round(HomeFeedRow, photoURL: URL?)
  case moment(HomePost, leagueName: String?)
  case notes(HomeFeedNotes)

  public var id: String {
    switch self {
    case .round(let r, _): "r-\(r.round_id?.uuidString ?? UUID().uuidString)"
    case .moment(let p, _): "p-\(p.id.uuidString)"
    case .notes(let n): n.id
    }
  }

  /// The door, if the line knows its round. A folded group opens through its
  /// one note when it has exactly one; more than one is the league's Notices.
  public var door: HomeFeedDoor? {
    switch self {
    case .round(let r, _): return r.round_id.map { .round($0) }
    case .moment(let p, _): return HomeFeedFold.door(for: p)
    case .notes(let n): return n.count == 1 ? n.rows.first.flatMap(HomeFeedFold.door(for:)) : nil
    }
  }
}

public struct HomeFeedBucket: Identifiable, Sendable {
  public let label: String     // "Today" · "This week" · "Earlier"
  public let items: [HomeFeedItem]
  public var id: String { label }
  public init(label: String, items: [HomeFeedItem]) { self.label = label; self.items = items }
}

public enum HomeFeedFold {
  /// Two calendar days: the month-close job posts one line per league in the
  /// same minute, and the clash lines land per league on the same morning.
  public static let sameNoteWindow: TimeInterval = 48 * 3600

  /// `live_round_id ?? round_id ?? scheduled_round_id` — D219.
  public static func door(for p: HomePost) -> HomeFeedDoor? {
    if let id = p.live_round_id { return .live(id) }
    if let id = p.round_id { return .round(id) }
    if let id = p.scheduled_round_id { return .scheduled(id) }
    return nil
  }

  /// The fold. `items` is `HomeStreamRepository.Result.items` (newest first);
  /// `upcoming` is the set of scheduled-round ids the Coming-up card already
  /// shows. Buckets come out as `HomeBuckets.bucket` would cut them.
  public static func fold(_ items: [HomeItem], upcoming: Set<UUID> = [], today: String = CSDate.today()) -> [HomeFeedBucket] {
    // 1 · hide what the Coming-up card already says.
    let kept = items.filter { i in
      if case .post(let p, _) = i, p.kind == "system", let s = p.scheduled_round_id, upcoming.contains(s) { return false }
      return true
    }
    // 2 · the same line in two leagues within 48h is one line. Newest survives
    //     and carries every league; the rest are dropped by id.
    var leagueSets: [UUID: [(id: UUID, name: String?)]] = [:]   // post id → leagues it now speaks for
    var dropped = Set<UUID>()
    let systems = kept.compactMap { i -> (HomePost, String?)? in
      if case .post(let p, let n) = i, p.kind == "system" { return (p, n) } ; return nil
    }
    for (i, (p, n)) in systems.enumerated() {
      guard !dropped.contains(p.id) else { continue }
      var set: [(id: UUID, name: String?)] = [(p.league_id ?? UUID(), n)]
      let body = key(p.body)
      guard !body.isEmpty else { leagueSets[p.id] = set; continue }
      for (q, qn) in systems[(i + 1)...] where !dropped.contains(q.id) {
        guard q.league_id != p.league_id, key(q.body) == body,
              abs((p.created_at ?? .distantPast).timeIntervalSince(q.created_at ?? .distantPast)) <= sameNoteWindow,
              !set.contains(where: { $0.id == q.league_id }) else { continue }
        set.append((q.league_id ?? UUID(), qn)); dropped.insert(q.id)
      }
      leagueSets[p.id] = set
    }
    // 3 · bucket, then one group per league-set per bucket; notes after the golf.
    return HomeBuckets.bucket(kept.filter { i in
      if case .post(let p, _) = i { return !dropped.contains(p.id) } ; return true
    }, today: today).map { b in
      var out: [HomeFeedItem] = []
      var groups: [[UUID]: HomeFeedNotes] = [:]
      var order: [[UUID]] = []
      for i in b.items {
        switch i {
        case .round(let r, let url): out.append(.round(r, photoURL: url))
        case .post(let p, let n):
          guard p.kind == "system" else { out.append(.moment(p, leagueName: n)); continue }
          // sorted by name, so "Fellas & Who's the bitch?" is one group whichever
          // league's copy of the note survived the dedupe above
          let set = (leagueSets[p.id] ?? [(p.league_id ?? UUID(), n)])
            .sorted { ($0.name ?? "", $0.id.uuidString) < ($1.name ?? "", $1.id.uuidString) }
          let k = set.map { $0.id }
          if let g = groups[k] {
            groups[k] = HomeFeedNotes(leagueIds: g.leagueIds, leagueNames: g.leagueNames, rows: g.rows + [p])
          } else {
            groups[k] = HomeFeedNotes(leagueIds: k, leagueNames: set.map { $0.name ?? "League" }, rows: [p])
            order.append(k)
          }
        }
      }
      return HomeFeedBucket(label: b.label, items: out + order.compactMap { groups[$0] }.map { .notes($0) })
    }
  }

  static func key(_ body: String?) -> String {
    (body ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }
}
