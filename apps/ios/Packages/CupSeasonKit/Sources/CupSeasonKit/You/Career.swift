// Cup Season — the lifetime tiles and the form row (index.html `loadCareer`
// 16409–16449, `formRowHtml` 11140–11150).
//
// D209 · ONE lens on You. Every figure here is the engine's allowance PvI —
// `v_rounds_ranked.pvi`, the number a round's points were scored against —
// labelled "vs your playing number". The phone never re-derives it: a round
// with no ranked row (card-only, outside every season window) shows no figure
// and a slate FORM dot. IOS-016's "best = lowest differential" stays an
// engine fact (the Personal best tile); on screen "best" is the best round
// against the playing number (D210's CONFLICT line).
//
// D208 · "Played in" counts leagues that STARTED — or that hold one of your
// rounds — never a sandbox; an event counts once you are on its roster.

import Foundation

public struct Career: Sendable, Equatable {
  public let rounds: Int
  /// the best round against the playing number — max `pvi` over the rounds that carry one
  public let best: Double?
  /// mean `pvi` over the same rounds
  public let avg: Double?
  /// how many rounds carry a figure — the ones a league counted
  public let counting: Int
  /// D208 — "Leagues & events · Played in"
  public let played: Int
  /// The five newest rounds on the card.
  public let recent: [RoundRow]
  /// round id → the allowance figure. One per round: the preferred league's
  /// season when a round scored in more than one, else the first lens seen.
  public let figures: [UUID: Double]
  /// round id → the points the engine gave it (already halved for nines)
  public let points: [UUID: Double]

  public init(rounds: Int, best: Double?, avg: Double?, counting: Int, played: Int, recent: [RoundRow],
              figures: [UUID: Double], points: [UUID: Double]) {
    self.rounds = rounds; self.best = best; self.avg = avg; self.counting = counting; self.played = played
    self.recent = recent; self.figures = figures; self.points = points
  }

  /// - rows: my rounds, newest first, as `myRounds` returns them.
  /// - ranked: my `v_rounds_ranked` rows, every league lens.
  /// - preferredSeason: the season whose lens wins when a round has several.
  public static func compute(rows: [RoundRow], ranked: [RankedRound], preferredSeason: UUID?, played: Int) -> Career {
    var figures: [UUID: Double] = [:], points: [UUID: Double] = [:]
    for r in ranked {
      guard let id = r.round_id, let v = r.pvi else { continue }
      if figures[id] == nil || (preferredSeason != nil && r.season_id == preferredSeason) {
        figures[id] = v
        points[id] = r.points
      }
    }
    let onCard = rows.compactMap { figures[$0.id] }
    return Career(
      rounds: rows.count,
      best: onCard.max(),
      avg: onCard.isEmpty ? nil : onCard.reduce(0, +) / Double(onCard.count),
      counting: onCard.count,
      played: played,
      recent: Array(rows.prefix(5)),
      figures: figures, points: points)
  }

  /// The one figure a You surface prints for a round; nil = card-only.
  public func figure(for round: RoundRow) -> Double? { figures[round.id] }

  /// D209 · FORM off the same figures — oldest→newest dots from the newest five.
  public var form: FormRow? {
    FormRow.from(rounds: recent.map { r in figures[r.id].map { FormRow.Dot(pvi: $0, points: points[r.id]) } })
  }

  // the tile strings, as the web writes them (`sign(v)`)
  public var roundsText: String { String(rounds) }
  public var bestText: String { best.map(RoundCopy.signed) ?? "—" }
  public var avgText: String { avg.map(RoundCopy.signed) ?? "—" }
  public var playedText: String { String(played) }
  /// Y-14 · what the best and the average are computed OVER — and, when the
  /// cell is a dash, why it is one. Both figures carry it because both are
  /// read off the same set: with one counting round they are the SAME number,
  /// and nothing else on the panel says so ("Rounds posted 17" sits two rows
  /// above and counts something else — every round on the card).
  public var figureScope: String { counting == 0 ? YouCopy.noCountingRounds : YouCopy.acrossCounting(counting) }

  /// "n of 3" — the establishing meter (D3 "building, not broken").
  public static func establishing(rounds: Int) -> String { "\(min(max(rounds, 0), 3)) of 3" }

  // MARK: - D208 · "Played in"

  /// One league as the count sees it.
  public struct LeagueSeen: Sendable, Equatable {
    public let seasonId: UUID?
    /// the current season's number — a second season means the first one ran
    public let seasonNumber: Int?
    public let seasonStatus: String?
    public let startsOn: String?
    public let sandbox: Bool
    public init(seasonId: UUID?, seasonNumber: Int?, seasonStatus: String?, startsOn: String?, sandbox: Bool) {
      self.seasonId = seasonId; self.seasonNumber = seasonNumber; self.seasonStatus = seasonStatus; self.startsOn = startsOn; self.sandbox = sandbox
    }
  }

  /// D208 · a league counts when its first season kicked off or the golfer
  /// holds a round in it; a sandbox never; an event counts once on its
  /// roster. `native_home()` does not carry `kicked_off`, so "kicked off" is
  /// read the way the tick sets it — a running season whose first tee is on
  /// or before today — or a season number past the first.
  public static func playedIn(leagues: [LeagueSeen], events: Int, rankedSeasons: Set<UUID>, today: String = CSDate.today()) -> Int {
    let running: Set<String> = ["active", "cup_final", "complete"]
    let counted = leagues.filter { l in
      if l.sandbox { return false }
      if let s = l.seasonId, rankedSeasons.contains(s) { return true }
      if let n = l.seasonNumber, n > 1 { return true }
      guard let st = l.seasonStatus, running.contains(st), let start = l.startsOn else { return false }
      return start <= today
    }
    return counted.count + events
  }

  /// D208 · "an event counts once the golfer is on its roster." `native_home()`
  /// returns an event the caller PLAYS IN **or organizes**, and the only roster
  /// evidence it carries is the team slot — so an event is counted when it has
  /// one, or when the caller is not its organizer (the row can then only have
  /// come from `event_players`). An organizer with no team yet waits for one:
  /// the count leans toward under-counting rather than toward a fiction.
  public static func onRoster(_ events: [Me.Event]) -> Int {
    events.filter { $0.my_team_slot != nil || $0.is_organizer != true }.count
  }
}

/// The You tab's own lines — one source, so the web twin (`#view-stats`) can
/// be held to the same words.
public enum YouCopy {
  /// D209 · the one lens every You figure is labelled with
  public static let vsPlayingNumber = "vs your playing number"
  public static let avgVsPlayingNumber = "Avg vs your playing number"
  /// Y-28/Y-14 · the "best" row on BOTH You stat panels. All time used to call
  /// the same figure "Best round" with the lens in a grey sub under it, which
  /// made one pair of stats read as two — D210's banned word is out of both,
  /// and so is the second name.
  public static let bestVsPlayingNumber = "Best vs your playing number"
  /// The same figure on the TOUR CARD, where D209 names the lens once in the
  /// section eyebrow and the rows underneath carry their own short words
  /// (`TourCard.bestLabel`). Not for a You panel: there the row label is the
  /// only place the lens is said.
  public static let bestRound = "Best round"
  /// Y-14 · the scope of a figure, WITH its denominator. "across counting
  /// rounds" said nothing about how many, so a best and an average that were
  /// one round twice read as two measurements.
  public static func acrossCounting(_ n: Int) -> String { "across \(n) counting round\(n == 1 ? "" : "s")" }
  public static let noCountingRounds = "No counting rounds yet"
  /// D131/D208 · the tile that counts leagues and events
  public static let leaguesAndEvents = "Leagues & events"
  public static let playedIn = "Played in"
  public static let roundsPosted = "Rounds posted"
  /// Y-14 · "All time" and "This season" USED to ride the first row of each
  /// panel as its sub, under a section head that already said the same word.
  /// The head owns the scope (brand canon §3, one fact one place); the rows
  /// say what they are computed over instead.
  /// Y-28 · the Index-move row: its scope, and why it is a dash
  public static let indexMove = "Index move"
  public static let seasonToDate = "Season to date"
  /// Y-14 · two rounds IN THIS SEASON. Without the last two words it read as
  /// nonsense beside "Rounds posted 17" one row above.
  public static let needsTwoRounds = "Needs 2 rounds this season"
  /// Y-28 · two rounds, and the number did not move — not a missing figure
  public static let held = "Held"
  /// Y-29 · the one empty state for a card with no rounds
  public static let noRoundsLine = "No rounds yet — your card fills as you play."
  public static let postFirst = "Post your first round"
  /// Y-17 · the quiet line over a partial load, and its one door
  public static let partialLine = "Some of your card did not load."
  public static let retry = "Retry"
  /// Y-28 · the block did not come back at all. A dash under "across counting
  /// rounds" says the opposite of why it is a dash.
  public static let didNotLoad = "Did not load"
  /// Y-12 · a round with no course on it — the row still opens.
  public static let unnamedCourse = "Somewhere out there"
  /// Y-33 · what a dash says to VoiceOver
  public static let notYet = "not yet"
  /// the hero's line while the index is building (the web's `#youIdx` title)
  public static let buildingNumber = "Building your number — your index appears at 3 posted rounds"
  /// Y-14 · the FORM row's key. The dots had no legend anywhere on the phone
  /// except by accident, when a streak pill happened to sit beside them; a
  /// VoiceOver label is not a legend for the golfer looking at the screen.
  ///
  /// Web twin: `CS_FORM_KEY` (index.html). Byte-for-byte, both clients.
  public static let formKey = formSentence(lead: "Your last five rounds", whose: "your")

  /// The same key in the CARD's register (`CredentialCard`, the Tour Card).
  /// Two things differ and only two: the card is denser than the You tab, so
  /// the lead is short — "FORM" and five drawn dots have already said which
  /// rounds and how many, and a summary that counts what is on screen beside
  /// it is the D201 defect. And the Tour Card is the surface headed "this is
  /// how your buddies see you", which means it is usually somebody ELSE's
  /// card, so the possessive is theirs.
  ///
  /// Assembled from the same sentence as `formKey` rather than retyped: a
  /// second copy of a line is the version that drifts (D201), and the dots
  /// mean one thing on every surface that draws them.
  public static func formKeyCard(mine: Bool) -> String {
    formSentence(lead: "Last five", whose: mine ? "your" : "their")
  }

  /// The one sentence both keys are cut from. The tail is the load-bearing
  /// half — the reading order, and what a lit dot IS.
  private static func formSentence(lead: String, whose: String) -> String {
    "\(lead), oldest first — a lit dot beat \(whose) playing number."
  }
}

/// D76 — FORM L5: the card runs a temperature. Dots read oldest→newest; ember
/// = beat your number.
public struct FormRow: Sendable, Equatable {
  /// one round's lens for a dot — the allowance figure and the points it earned
  public struct Dot: Sendable, Equatable {
    public let pvi: Double
    public let points: Double?
    public init(pvi: Double, points: Double?) { self.pvi = pvi; self.points = points }
  }

  /// oldest → newest; true = beat the number, false = did not, nil = no number
  public let dots: [Bool?]
  /// consecutive `beat` rounds counted from the newest
  public let streak: Int
  /// Y-22 · what each dot says, oldest → newest — the points when the engine
  /// gave them, the band name otherwise, "no number" for a slate dot. Empty
  /// when the row was built from verdicts alone (the Tour Card).
  public let words: [String]

  public init(dots: [Bool?], streak: Int, words: [String] = []) { self.dots = dots; self.streak = streak; self.words = words }

  public var tag: String? { streak >= 2 ? "\(streak) STRAIGHT UNDER" : nil }
  /// `heathot` at 3+, `heatwarm` at 2.
  public var hot: Bool { streak >= 3 }
  /// Y-22 · the dots said out loud, oldest → newest: "Form, last five: 7, 9,
  /// 12, no number, 6, 3 straight under". Without the figures behind them (the
  /// Tour Card builds from verdicts alone) it stays "Form, last 5 rounds".
  public var accessibilityLabel: String {
    let tail = streak >= 2 ? ", \(streak) straight under" : ""
    guard !words.isEmpty else { return "Form, last \(dots.count) rounds" + tail }
    let n = ["", "one", "two", "three", "four", "five"]
    return "Form, last \(dots.count < n.count ? n[dots.count] : String(dots.count)): " + words.joined(separator: ", ") + tail
  }

  /// `beats` newest first (the order every payload arrives in). Returns nil
  /// when there is nothing to draw — no rounds, or (the skew rule) no entry
  /// carries a `beat` verdict at all: "a payload whose entries carry NO `beat`
  /// key renders nothing at all — no row, no error."
  public static func from(beats: [Bool?]) -> FormRow? {
    let last5 = Array(beats.prefix(5))
    guard !last5.isEmpty, last5.contains(where: { $0 != nil }) else { return nil }
    var stk = 0
    for b in last5 { if b == true { stk += 1 } else { break } }
    return FormRow(dots: last5.reversed(), streak: stk)
  }

  /// D209 · the same row off the engine's figures, newest first; nil entries
  /// are card-only rounds. Beat the number = pvi ≥ 1 (D76), unchanged.
  public static func from(rounds: [Dot?]) -> FormRow? {
    let last5 = Array(rounds.prefix(5))
    guard let base = from(beats: last5.map { $0.map { $0.pvi >= 1 } }) else { return nil }
    let words: [String] = last5.reversed().map { d in
      guard let d else { return "no number" }
      if let p = d.points { return CSCopy.points(p) }
      return CSBands.bandName(d.pvi)
    }
    return FormRow(dots: base.dots, streak: base.streak, words: words)
  }
}
