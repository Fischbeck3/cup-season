// Cup Season — the league room's copy, verbatim from index.html:
//   the bylaws card            renderBylaws     11889–11947
//   the phase strings          renderPhase      11985–12040, renderLeagueMeta 12626–12705
//   the season tile deadlines  renderStats      9406–9500
//   the next-up card, the press meter           9500–9530
// The state mapping is `applyBylaws` (14144–14175): the DB row → the dials
// the renderers read (preset index, cap index, stake in dollars).

import Foundation

public enum RoomPhase: String, Sendable, Equatable { case setup, draft, season }

/// `applyBylaws` — the bylaws as the renderers read them.
public struct Bylaws: Sendable, Equatable {
  public static let capLabels = ["Best 2", "Best 4", "Best 6", "Unlimited"]
  public static let capVals: [Int?] = [2, 4, 6, nil]
  public static let presetNames = ["Casual", "Standard", "Cutthroat"]
  public static let allow = [100, 95, 90]
  public static let verif = ["Honor system", "Attested", "GHIN-verified + attested"]
  public static let penalty = ["None", "−5 sqd pts / round short", "Forfeit month"]
  public static let fmtNames = ["Points Race", "Head-to-Head", "Hybrid"]
  public static let structNames = ["solo": "Individual — no squads", "squads2": "2 squads", "squads3": "3 squads", "squads4": "4 squads"]
  public static let structMin = ["solo": 2, "squads2": 4, "squads3": 6, "squads4": 8]
  public static let draftNames = ["random": "Blind draw", "assign": "Pro assign", "snake": "Snake · async", "live": "Live · pick clock"]

  /// Dollars. 0 = bragging rights.
  public let stake: Int
  public let floor: Int
  public let capIdx: Int
  public let presetIdx: Int
  public let fmtIdx: Int
  public let structure: String
  public let payout: [Int]
  public let finish: String
  public let draftType: String

  public init(stake: Int = 0, floor: Int = 2, capIdx: Int = 1, presetIdx: Int = 1, fmtIdx: Int = 0, structure: String = "squads2",
              payout: [Int] = [60, 25, 15], finish: String = "cup_final", draftType: String = "random") {
    self.stake = stake; self.floor = floor; self.capIdx = capIdx; self.presetIdx = presetIdx; self.fmtIdx = fmtIdx
    self.structure = structure; self.payout = payout; self.finish = finish; self.draftType = draftType
  }

  public static func from(_ b: LeagueRoom.Settings?) -> Bylaws {
    guard let b else { return Bylaws() }
    let capMap: [Int: Int] = [2: 0, 4: 1, 6: 2]
    let presets = ["casual", "standard", "cutthroat"]
    let pi = presets.firstIndex(of: b.preset ?? "") ?? 1
    return Bylaws(
      stake: Int((Double(b.buyin_cents ?? 0) / 100).rounded()),
      floor: b.participation_floor ?? 0,
      capIdx: b.counting_cap == nil ? 3 : (capMap[b.counting_cap!] ?? 1),
      presetIdx: pi,
      fmtIdx: max(0, ["points", "h2h", "hybrid"].firstIndex(of: b.season_format ?? "") ?? 0),
      structure: b.structure ?? "squads2",
      payout: [b.payout_champ ?? 60, b.payout_runnerup ?? 25, b.payout_king ?? 15],
      finish: b.finish ?? "cup_final",
      draftType: ["random", "assign", "snake", "live"].contains(b.draft_type ?? "") ? b.draft_type! : "random")
  }

  public var capN: Int { Self.capVals[capIdx] ?? Int.max }
  public var capLabel: String { Self.capLabels[capIdx] }
  public var presetName: String { Self.presetNames[presetIdx] }
  public var solo: Bool { structure == "solo" }
  public var structMin: Int { Self.structMin[structure] ?? 4 }
}

/// The season's clock as the renderers see it (`seasonS/E`, `atStarter`,
/// `isCupFinal`, `currentWeek`, `totalWeeks`, `daysToTee`).
public struct RoomClock: Sendable, Equatable {
  public let phase: RoomPhase
  public let startsOn: String?
  public let endsOn: String?
  public let status: String?
  public let finish: String
  public let today: String

  public init(phase: RoomPhase, startsOn: String?, endsOn: String?, status: String?, finish: String, today: String = CSDate.today()) {
    self.phase = phase; self.startsOn = startsOn; self.endsOn = endsOn; self.status = status; self.finish = finish; self.today = today
  }

  public var hasSeason: Bool { startsOn != nil && endsOn != nil }
  public var done: Bool { status == "complete" }
  /// Locked, first tee still ahead (11785).
  public var atStarter: Bool { phase == .season && startsOn != nil && today < startsOn! }
  /// From `seasons.status`, never the calendar (README; audit 02 §8).
  public var isCupFinal: Bool { finish == "cup_final" && phase == .season && status == "cup_final" }
  public var totalWeeks: Int { guard let s = startsOn, let e = endsOn else { return 1 }; return LeagueDates.totalWeeks(start: s, end: e) }
  public var currentWeek: Int { guard let s = startsOn, let e = endsOn else { return 1 }; return LeagueDates.currentWeek(start: s, end: e, today: today) }
  public var daysToTee: Int { guard let s = startsOn else { return 0 }; return max(0, CSDate.days(from: today, to: s) ?? 0) }
  public var daysLeft: Int { guard let e = endsOn else { return 0 }; return max(0, CSDate.days(from: today, to: e) ?? 0) }
  public var firstTeeText: String { startsOn.map { LeagueDates.dowMonDay($0) } ?? "—" }
  public var cupFinalStart: String? { endsOn.map { LeagueDates.cupFinalStart(end: $0) } }
  public var spanText: String {
    guard let s = startsOn, let e = endsOn else { return "Season dates lock with the bylaws" }
    return LeagueDates.spanText(start: s, end: e)
  }
}

public struct BylawRow: Sendable, Equatable, Identifiable {
  public let k: String
  public let v: String
  public var id: String { k }
  public init(_ k: String, _ v: String) { self.k = k; self.v = v }
}

public enum LeagueCopy {
  // MARK: bylaws (11889–11908)

  public static func bylawsRows(_ b: Bylaws, clock: RoomClock) -> [BylawRow] {
    var rows: [BylawRow] = [
      BylawRow("STRUCTURE", Bylaws.structNames[b.structure] ?? b.structure),
      BylawRow("Squad formation", Bylaws.draftNames[b.draftType] ?? b.draftType),
      BylawRow("PRESET", b.presetName),
      BylawRow("HANDICAP ALLOWANCE", "\(Bylaws.allow[b.presetIdx])%"),
      BylawRow("VERIFICATION", Bylaws.verif[b.presetIdx]),
      BylawRow("COUNTING CAP", "\(b.capLabel) / mo"),
      BylawRow("PARTICIPATION FLOOR", "\(b.floor) / mo · \(Bylaws.penalty[b.presetIdx])"),
    ]
    if b.stake == 0 {
      rows.append(BylawRow("BUY-IN", "None · bragging rights"))
    } else {
      rows.append(BylawRow("BUY-IN", "\(PotMath.dollars(b.stake)) / player"))
      rows.append(BylawRow("POT SPLIT", "\(b.payout.map(String.init).joined(separator: " / ")) · champ / 2nd / king"))
    }
    let tw = clock.totalWeeks
    rows.append(BylawRow("SEASON", (clock.hasSeason && tw >= 8 ? LeagueDates.durLabel(tw) + " · " : "") + clock.spanText))
    if b.finish == "cup_final", clock.hasSeason, tw >= 6, let cf = clock.cupFinalStart {
      rows.append(BylawRow("CUP FINAL", "Final 4 weeks · from \(LeagueDates.dowMonDay(cf)) · scored fresh"))
    } else {
      rows.append(BylawRow("FINISH", "Points table crowns it · whole season, one race"))
    }
    return rows
  }

  /// The Pro's endgame dial (11912–11926) — until the final window opens.
  public static func finishDial(current: String) -> (label: String, next: String, toast: String) {
    let cup = current == "cup_final"
    let next = cup ? "points_table" : "cup_final"
    return ("Finish: \(cup ? "Cup Final" : "points table") — switch to \(cup ? "points table" : "the Cup Final")", next,
            next == "cup_final" ? "The Cup Final returns — final 4 weeks, scored fresh" : "Points table crowns the champion — posted to the board")
  }

  // MARK: the header (12668–12704)

  /// D120 · ONE league stage, one vocabulary — the Swift half of the web's
  /// `STAGE_LABEL` / `leagueStage()`. The blind audit found the same league
  /// described five different ways in a single session across the two clients;
  /// these six strings are the whole vocabulary and `tests/preflight.mjs`
  /// check 20 fails the push if they stop matching index.html.
  /// "Forming" means SETUP only — testers read the old "Squad formation" label
  /// as the setup stage, so the drawing stage gets its own word. The retired
  /// "Setup — invites open" also contradicted D112: nothing opens until lock.
  public enum Stage: String, CaseIterable, Sendable {
    case forming, drawing, preseason, season, final, complete
    public var label: String {
      switch self {
      case .forming:   return "Forming"
      case .drawing:   return "Squads drawing"
      case .preseason: return "Before first tee"
      case .season:    return "Season live"
      case .final:     return "Cup Final"
      case .complete:  return "Season complete"
      }
    }
  }

  public static func stage(_ c: RoomClock) -> Stage {
    switch c.phase {
    case .setup: return .forming
    case .draft: return .drawing
    case .season:
      if c.done { return .complete }
      if c.atStarter { return .preseason }
      if c.isCupFinal { return .final }
      return .season
    }
  }

  /// D122 · a round scores for a league only inside its season window. The web
  /// half is `seasonNote()`; these are the same sentences so a golfer who posts
  /// on the phone and reads the receipt on the web is told one story.
  /// The audit's testers were promised 5/6/12 league points a week before first
  /// tee and shown zero afterwards, with nothing connecting the two facts.
  public static func seasonNote(_ st: Stage, firstTee: String?, short: Bool = false) -> String {
    switch st {
    case .season, .final: return ""
    case .complete:
      return short ? "Season complete" : "The season is over — this round lands on your card."
    case .forming, .drawing, .preseason:
      guard let when = firstTee, !when.isEmpty else {
        return short ? "Practice round"
                     : "Practice — the season has not started. This round builds your number; it earns league points once it does."
      }
      return short ? "Practice · season starts \(when)"
                   : "Practice — the season starts \(when). This round builds your number; it earns league points from then on."
    }
  }

  /// The no-league case, which is not a stage — the golfer simply has no league.
  public static let noLeagueNote = "This round lands on your card — join a league and it scores there too."
  public static let noLeagueNoteShort = "On your card"

  public static func phaseHeader(_ c: RoomClock) -> String {
    let st = stage(c)
    return st == .preseason ? "\(st.label) — \(c.firstTeeText)" : st.label
  }

  /// `#phaseSub` (12008–12020).
  public static func phaseSub(_ c: RoomClock, b: Bylaws, code: String?, members: Int) -> String {
    switch c.phase {
    case .setup: return "SETUP · LOCK THE BYLAWS TO OPEN INVITES"
    case .draft: return "\(Stage.drawing.label) · rosters pending"
    case .season:
      if c.atStarter { return "BEFORE FIRST TEE · \(c.firstTeeText.uppercased()) · \(c.daysToTee) DAY\(c.daysToTee == 1 ? "" : "S")" }
      if c.isCupFinal { return "CUP FINAL · Wk \(c.currentWeek) / \(c.totalWeeks) · fresh slate · \(b.presetName) rules" }
      return "Wk \(c.currentWeek) / \(c.totalWeeks) · \(Bylaws.fmtNames[b.fmtIdx]) · \(b.presetName) rules"
    }
  }

  public static func players(_ k: Int) -> String { "\(k) PLAYER\(k == 1 ? "" : "S")" }

  /// `#setupInviteSub` (12640–12643).
  public static func seatFill(code: String?, members n: Int, min: Int, locked: Bool = true) -> String {
    let short = max(0, min - n)
    // D161 · in setup the code admits nobody, so it is not shown as if it did
    return (locked ? "CODE \(code ?? "—") · " : "JOINS OPEN AT THE LOCK · ")
      + (short > 0 ? "\(n) OF \(min) IN — \(short) SEAT\(short == 1 ? "" : "S") OPEN" : "\(n) JOINED — ENOUGH FOR THE DRAW")
  }

  /// `#draftPoolSub` (12647–12648).
  public static func draftPoolSub(pool: Int, members n: Int, min: Int) -> String {
    let short = max(0, min - n)
    return "\(players(pool)) IN THE POOL" + (short > 0 ? " · \(short) SEAT\(short == 1 ? "" : "S") OPEN" : "")
  }

  /// `#hubDraftSub` (12034–12037).
  public static func squadsSub(_ c: RoomClock, solo: Bool) -> String {
    if solo { return "Individual league — no squads" }
    switch c.phase {
    case .setup: return "OPENS AFTER SETTINGS LOCK"
    case .draft: return "LIVE NOW — CAPTAINS READY"
    case .season: return "Complete · rosters locked"
    }
  }

  /// `#kickoffHero` (12024–12030).
  public static func kickoff(_ c: RoomClock) -> (tee: String, count: String) {
    let d = c.daysToTee
    return ("First tee \(c.firstTeeText)", "KICKS OFF IN \(d) DAY\(d == 1 ? "" : "S") · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON")
  }

  /// The danger zone (12688–12703).
  public static func danger(_ c: RoomClock) -> (link: String, note: String, preTee: Bool) {
    let preTee = c.phase == .setup || c.phase == .draft || c.atStarter
    return (preTee ? "Cancel & delete this league" : "Cancel this league",
            preTee ? "(only possible before the first tee)" : "(the season is under way — a pot needs every member to approve)",
            preTee)
  }

  // MARK: the season tile (9412–9455)

  public struct Deadline: Sendable, Equatable {
    public let text: String
    public let gold: Bool
  }

  public static func weekValue(_ c: RoomClock) -> String {
    c.done ? String(c.totalWeeks) : (c.atStarter ? "—" : "W\(c.currentWeek)")
  }

  public static func deadline(_ c: RoomClock, b: Bylaws) -> Deadline {
    if c.done { return Deadline(text: "Season complete · settled", gold: true) }
    if c.atStarter { return Deadline(text: "First tee \(c.firstTeeText)", gold: true) }
    if c.isCupFinal {
      let left = c.daysLeft
      return Deadline(text: "CUP FINAL LIVE · \(left) day\(left == 1 ? "" : "s") left", gold: true)
    }
    let today = c.today
    let dTo = { (iso: String) in CSDate.days(from: today, to: iso) ?? 0 }
    let sun = LeagueDates.nextSunday(today)
    let first = LeagueDates.firstOfNextMonth(today)
    var opts: [(n: Int, pri: Int, gold: Bool, t: String)] = [
      (dTo(sun), 0, false, dTo(sun) == 0 ? "Week closes tonight" : "Week closes Sun · \(dTo(sun))d"),
      (dTo(first), 1, false, "Month closes \(LeagueDates.monDay(first).split(separator: " ").first.map(String.init) ?? "") 1 · floors assessed"),
    ]
    if b.finish == "cup_final" {
      if let cf = c.cupFinalStart, cf >= today { opts.append((dTo(cf), 2, true, "Cup Final · \(LeagueDates.dowMonDay(cf)) · \(dTo(cf))d")) }
    } else if let en = c.endsOn, en >= today {
      opts.append((dTo(en), 2, true, "Points table crowns it · ends \(LeagueDates.monDay(en)) · \(dTo(en))d"))
    }
    let nx = opts.sorted { a, b in a.n != b.n ? a.n < b.n : a.pri > b.pri }[0]
    return Deadline(text: nx.t, gold: nx.gold)
  }

  /// `fmtN` — whole numbers plain, else one decimal (0.5 floor credits).
  public static func fmtN(_ n: Double) -> String { n == n.rounded() ? String(Int(n)) : String(format: "%.1f", n) }

  /// The index tile's sub line (9462–9480).
  public static func indexSub(established: Bool, delta: Double?) -> String {
    guard established else { return "Building your number" }
    guard let d = delta, d.isFinite, abs(d) >= 0.05 else { return "Season to date" }
    return (d < 0 ? "▼ " : "▲ ") + String(format: "%.1f", abs(d)) + " this season"
  }

  /// `#statCountD` (9494).
  public static func countingSub(month: String, capN: Int) -> String {
    month + (capN == Int.max ? " · every round counts" : " · your best \(capN) count")
  }

  // MARK: the press meter (9496–9510)

  public struct PressMeter: Sendable, Equatable {
    public let fill: Double      // 0…1
    public let legend: String
    public let hot: Bool
  }
  public static func pressMeter(today: String) -> PressMeter {
    let dim = LeagueDates.daysInMonth(today)
    let left = CSDate.days(from: today, to: LeagueDates.firstOfNextMonth(today)) ?? 0
    return PressMeter(fill: min(1, max(0, Double(dim - left) / Double(dim))),
                      legend: "\(left) day\(left == 1 ? "" : "s") left in \(LeagueDates.monthLong(today))",
                      hot: left <= 7)
  }

  // MARK: next up (9512–9530)

  public static func nextUp(_ c: RoomClock, b: Bylaws, credits: Double, partial: Bool) -> (k: String, text: String) {
    if c.atStarter { return ("Next up · kickoff", "First tee \(c.firstTeeText). Practice rounds hit your card, not the season.") }
    let month = LeagueDates.monthLong(c.today)
    let rem = max(0, Double(b.floor) - credits)
    let text = partial
      ? "\(month) is a short month — no floor to clear. Every round still counts."
      : rem > 0
        ? "Post \(fmtN(rem)) more round\(rem == 1 ? "" : "s") this month — \(b.capLabel.lowercased()) count, you've posted \(fmtN(credits))."
        : "\(month) is covered — \(fmtN(credits)) rounds counting. A better one always replaces your lowest."
    return ("Next up · \(month)", text)
  }

  /// `#lineSplit` (11943).
  public static func lineSplit(total: Int, payout: [Int]) -> String {
    let t = PotMath.trioDollars(total: total, payout: payout)
    return "CHAMPS \(PotMath.dollars(t.champ)) · RUNNER-UP \(PotMath.dollars(t.runner)) · POINTS KING \(PotMath.dollars(t.king))"
  }

  /// The standings empty state (4516–4518).
  public static func standingsEmpty(solo: Bool) -> (line1: String, line2: String) {
    solo ? ("INDIVIDUAL RACE — NO SQUADS.", "STANDINGS START AT THE FIRST POSTED ROUND; TOP 2 MEET IN THE CUP FINAL.")
         : ("NO ROUNDS YET.", "SQUADS FORM WHEN THE PRO LOCKS — STANDINGS START AT THE FIRST POSTED ROUND.")
  }
}
