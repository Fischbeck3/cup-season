// Cup Season — synthetic reads for COMPETE and the season BOOK: every
// golfer's entries in every season (the one model the Book, the standings and
// `native_home` all read, so the three always agree), `season_book` built to
// pass `SeasonBookSnapshot.validate`, and the month counters.
//
// Nothing here scores. The entries are the answer the server's producers
// would give, written down; the client only renders and validates them.

#if DEBUG
import Foundation
import CupSeasonKit

/// One line of a golfer's season: a round (counting or dropped), a bye, or a
/// correction. `contribution` is what it adds to the table.
struct SynthEntry: Sendable {
  let id: String
  let round: String?
  let person: Int
  let week: Int?
  let day: Int?
  let kind: String            // round | bye | floor_penalty | override
  let points: Int
  let contribution: Int
  let state: String           // counting | dropped | adjustment | bye
  let reason: String
}

extension SyntheticWorld {
  func competeRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    case "season_book":
      guard let l = league(r.string("p_league_id")) ?? league(r.string("p_season_id")) else {
        return SynthOut.error("That season is not in this record.", code: "P0001", status: 400)
      }
      return SynthOut.json(seasonBook(l))
    case "my_month_counters":
      let rows: [[String: Any]] = leagues.filter { $0.status != "complete" }.map { l in
        let used = myEntries(l).filter { $0.state == "counting" && ($0.day ?? -99) >= firstOfMonthOffset }.count
        return ["league_id": l.ids, "league_name": l.name, "season_id": l.seasonIds, "cap": 4,
                "structure": l.solo ? "solo" : "squads3", "counters": ["used": min(4, used), "worst": 6] as [String: Any]]
      }
      return SynthOut.json(rows)
    default: return nil
    }
  }

  // MARK: the entries

  /// Every entry of every golfer in `l`, keyed by person number.
  func entries(_ l: SynthLeague) -> [Int: [SynthEntry]] {
    var out: [Int: [SynthEntry]] = [:]
    for pn in l.memberOrder { out[pn] = pn == me.n ? myEntries(l) : generatedEntries(l, pn) }
    return out
  }

  /// Avery's own rounds in the season window, the best four per calendar
  /// month counting — real round ids, so the Book's receipts open the same
  /// rounds the golfer sees on Home and You.
  func myEntries(_ l: SynthLeague) -> [SynthEntry] {
    let d = seasonDates(l)
    let mine = myRounds.filter { $0.day >= d.starts && $0.day <= 0 && $0.points != nil }
    let byMonth = Dictionary(grouping: mine, by: { monthKey($0.day) })
    var counting = Set<Int>()
    for (_, rs) in byMonth {
      let best = rs.sorted { a, b in (a.points ?? 0) != (b.points ?? 0) ? (a.points ?? 0) > (b.points ?? 0) : a.day > b.day }
      for r in best.prefix(4) { counting.insert(r.n) }
    }
    return mine.sorted { $0.day < $1.day }.map { r in
      let counts = counting.contains(r.n)
      let pts = Int(r.points ?? 0)
      return SynthEntry(id: "round:\(r.ids)", round: r.ids, person: me.n, week: week(of: r.day, l), day: r.day, kind: "round",
                        points: pts, contribution: counts ? pts : 0, state: counts ? "counting" : "dropped",
                        reason: counts ? "Counts: one of the best 4 this calendar month." : "Outside the best 4 for this calendar month; the round stays in the record.")
    }
  }

  /// A golfer we only know through the table: a round most weeks, points that
  /// add up to the golfer's target, and — for the last golfer on the roster —
  /// a missed monthly minimum recorded as a correction with its reason.
  func generatedEntries(_ l: SynthLeague, _ pn: Int) -> [SynthEntry] {
    let target = l.targets[pn] ?? 20
    let d = seasonDates(l)
    let played = Array(1...max(1, l.week)).filter { w in (pn * 3 + w) % 5 != 0 && d.starts + (w - 1) * 7 <= 0 }
    let weeks = played.isEmpty ? [1] : played
    // The last golfer on a solo roster carries one ruling from the Pro, so the
    // Book and the member sheet both have an adjustment with its reason.
    let penalty = l.solo && pn == l.memberOrder.last && l.week >= 3
    let pool = target + (penalty ? 3 : 0)
    let each = pool / weeks.count, extra = pool % weeks.count
    var out: [SynthEntry] = []
    for (i, w) in weeks.enumerated() {
      let day = min(0, d.starts + (w - 1) * 7 + ((pn + w) % 5))
      let pts = each + (i < extra ? 1 : 0)
      let rid = fids(45_000 + (l.n % 10) * 1_000 + pn * 40 + w)
      out.append(SynthEntry(id: "round:\(rid)", round: rid, person: pn, week: w, day: day, kind: "round",
                            points: pts, contribution: pts, state: "counting", reason: "Counts: one of the best 4 this calendar month."))
      if (pn + w) % 7 == 0 {
        let drop = fids(46_000 + (l.n % 10) * 1_000 + pn * 40 + w)
        out.append(SynthEntry(id: "round:\(drop)", round: drop, person: pn, week: w, day: max(d.starts, day - 1), kind: "round",
                              points: max(1, pts / 2), contribution: 0, state: "dropped",
                              reason: "Outside the best 4 for this calendar month; the round stays in the record."))
      }
    }
    if penalty {
      let closeDay = max(d.starts, firstOfMonthOffset)
      out.append(SynthEntry(id: "adjustment:\(fids(47_000 + (l.n % 10) * 100 + pn))", round: nil, person: pn,
                            week: week(of: closeDay, l), day: closeDay, kind: "override", points: -3, contribution: -3,
                            state: "adjustment", reason: "Posted from the wrong tee on \(monthDay(closeDay - 3)); corrected by the Pro"))
    }
    return out
  }

  /// A round for a Book entry of a golfer we only know through the table,
  /// so its receipt opens too.
  func bookRound(_ ids: String) -> SynthRound? {
    for l in leagues {
      for (_, list) in entries(l) {
        guard let e = list.first(where: { $0.round == ids }), let day = e.day else { continue }
        var r = SynthRound(n: 0, owner: person(e.person), day: day, gross: 78 + (e.person * 7 + (e.week ?? 1) * 3) % 17,
                           course: courses[(e.week ?? 1) % 2], points: Double(e.points), counts: e.state == "counting",
                           pvi: Double(e.points - 6) / 2)
        r.overrideID = ids
        return r
      }
    }
    return nil
  }

  func week(of day: Int, _ l: SynthLeague) -> Int? {
    let w = (day - seasonDates(l).starts) / 7 + 1
    return (1...l.weeksTotal).contains(w) ? w : nil
  }

  /// "2026-09-01" for the month holding `day`.
  func monthKey(_ day: Int) -> String { String(self.day(day).prefix(7)) + "-01" }
  func monthName(_ day: Int) -> String {
    guard let d = CSDate.local(self.day(day)) else { return "Last month" }
    let f = DateFormatter()
    f.setLocalizedDateFormatFromTemplate("MMMM")
    return f.string(from: d)
  }
  /// Offset of the 1st of the anchor's month.
  var firstOfMonthOffset: Int { -((Int(anchor.suffix(2)) ?? 1) - 1) }

  // MARK: season_book

  func seasonBook(_ l: SynthLeague) -> [String: Any] {
    let d = seasonDates(l)
    let current = l.status == "complete" ? l.weeksTotal : l.week
    let weeks: [[String: Any]] = (1...l.weeksTotal).map { w in
      ["week": w, "starts_on": day(d.starts + (w - 1) * 7), "ends_on": day(d.starts + w * 7 - 1)]
    }
    let all = entries(l)
    let totals = l.memberOrder.map { pn in (pn, all[pn, default: []].reduce(0) { $0 + $1.contribution }) }
    let ranked = rankTable(totals)
    var rows: [[String: Any]] = []
    if !l.solo {
      for s in squadNames {
        for pn in l.memberOrder where squadOf(pn, in: l) == s.n {
          rows.append(bookRow(id: "contribution:\(fids(s.n)):\(l.memberIds(pn))", kind: "contribution", name: person(pn).name,
                              member: l.memberIds(pn), squad: fids(s.n), rank: nil, tied: false, mine: pn == me.n,
                              entries: all[pn, default: []], squadID: fids(s.n), l: l, current: current))
        }
      }
    }
    for (pn, _) in totals {
      let place = ranked[pn] ?? (rank: 1, tied: false)
      rows.append(bookRow(id: "golfer:\(l.memberIds(pn))", kind: "golfer", name: person(pn).name, member: l.memberIds(pn),
                          squad: nil, rank: place.rank, tied: place.tied, mine: pn == me.n,
                          entries: all[pn, default: []], squadID: nil, l: l, current: current))
    }
    if !l.solo {
      let squadTotals = squadNames.map { s in
        (s.n, l.memberOrder.filter { squadOf($0, in: l) == s.n }.flatMap { all[$0, default: []] }.reduce(0) { $0 + $1.contribution })
      }
      let squadRanked = rankTable(squadTotals)
      for s in squadNames {
        let members = l.memberOrder.filter { squadOf($0, in: l) == s.n }
        let place = squadRanked[s.n] ?? (rank: 1, tied: false)
        rows.append(bookRow(id: "squad:\(fids(s.n))", kind: "squad", name: s.name, member: nil, squad: fids(s.n),
                            rank: place.rank, tied: place.tied, mine: members.contains(me.n),
                            entries: members.flatMap { all[$0, default: []] }, squadID: fids(s.n), l: l, current: current))
      }
    }
    return [
      "version": 1, "league_id": l.ids, "season_id": l.seasonIds, "name": l.name, "number": 2, "status": l.status,
      "starts_on": day(d.starts), "ends_on": day(d.ends), "timezone": "America/Phoenix", "generated_at": stamp(0, 7, 30),
      "current_week": current, "structure": l.solo ? "solo" : "squads3", "field_size": l.memberOrder.count,
      "counting_cap": 4, "participation_floor": 2, "rules_note": NSNull(), "coverage_complete": true,
      "weeks": weeks, "rows": rows,
    ]
  }

  /// Standard competition ranks, ties shared: [person or squad: (rank, tied)].
  func rankTable(_ totals: [(Int, Int)]) -> [Int: (rank: Int, tied: Bool)] {
    let sorted = totals.sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0 < $1.0 }
    var out: [Int: (rank: Int, tied: Bool)] = [:]
    for (i, t) in sorted.enumerated() {
      let first = sorted.firstIndex { $0.1 == t.1 } ?? i
      out[t.0] = (first + 1, sorted.filter { $0.1 == t.1 }.count > 1)
    }
    return out
  }

  private func bookRow(id: String, kind: String, name: String, member: String?, squad: String?, rank: Int?, tied: Bool,
                       mine: Bool, entries: [SynthEntry], squadID: String?, l: SynthLeague, current: Int) -> [String: Any] {
    let wire: [[String: Any]] = entries.map { e in
      [
        "id": e.id, "round_id": e.round ?? NSNull(), "member_id": l.memberIds(e.person), "squad_id": squadID ?? NSNull(),
        "week": e.week ?? NSNull(), "recorded_on": e.day.map { day($0) } ?? NSNull(),
        "affected_month": e.day.map { monthKey($0) } ?? NSNull(), "kind": e.kind, "points": e.points,
        "contribution": e.contribution, "withdrawn": false, "count_state": e.state, "reason": e.reason,
      ]
    }
    let cells: [[String: Any]] = (1...l.weeksTotal).map { w in
      let future = w > current
      let inWeek = entries.filter { $0.week == w }
      let through = entries.filter { ($0.week ?? Int.max) <= w }
      let pts: Any = future || inWeek.isEmpty ? NSNull() : inWeek.reduce(0) { $0 + $1.contribution }
      let cum: Any = future || through.isEmpty ? NSNull() : through.reduce(0) { $0 + $1.contribution }
      return ["week": w, "future": future, "points": pts, "cumulative": cum]
    }
    return [
      "id": id, "kind": kind, "name": name, "member_id": member ?? NSNull(), "squad_id": squad ?? NSNull(),
      "points": entries.reduce(0) { $0 + $1.contribution }, "points_rank": rank ?? NSNull(), "tied": tied, "mine": mine,
      "reconciled": true, "unplaced_points": entries.filter { $0.week == nil }.reduce(0) { $0 + $1.contribution },
      "entries": wire, "cells": cells,
    ]
  }
}
#endif
