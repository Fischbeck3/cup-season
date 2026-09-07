// Cup Season — THE BOARD (Wave 5, `surfaces/season.md` §1.4).
//
// One standings object, not three. The shipped page rendered a table, then the
// climb, then the individual race — three tables for a field of two (CS-21, a
// P0) — under column heads sitting 140–200px left of the columns they named
// (CS-18). All of that is one `CSStandingsBoard` of `CSSlat`s now:
//
//   │ 01 │ ◍ GALEN MARR          │  —  │  19 │
//   │gold│   Held since week three│     │     │
//     44  12  38/30    flex        58    50
//
// WHAT SURVIVES VERBATIM, because the audit calls it a real ceremony:
// `RankFlipText`, its deterministic decoys, the `freshStandings` replay gate
// and the `iClimbed` rank-up haptic. What went: `header(solo:)` and its
// swallowed alignment, `moveChip`'s tinted field, the squad `RoundedRectangle`
// as identity (CS-11), the gold "Cut line · top 2 advance" band (nothing there
// is won yet) and the trend column's red/green float.
//
// THE CLIMB'S WINDOW SURVIVES AS A BEHAVIOUR. Over ten in the field, the board
// renders the leader, the cut neighbours and you ±1 with `ClimbMath`'s
// ellipsis rung between, and a tertiary link opens the whole field. The climb
// as a SECOND TABLE is gone.

import SwiftUI
import CSDesign
import CupSeasonKit

struct StandingsTableView: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs
  @State private var flipOnce = false
  /// The window opens on demand; the door is a tertiary link, not a push, so
  /// the golfer never loses the page he was reading.
  @State private var wholeField = false

  /// nil = the whole board; a set = the window's rows plus where the ellipsis
  /// goes. **Per BOARD, not per row** — one grammar down the column.
  private var window: (rows: [Int], hidden: [Int: Int])? {
    let n = model.teams.count
    guard n > 10, !wholeField else { return nil }
    let mine = model.myTeamId.flatMap { id in model.teams.firstIndex { $0.id == id } }
    var keep = Set([0, 1, 2])
    if let m = mine { for i in (m - 1)...(m + 1) where i >= 0 && i < n { keep.insert(i) } }
    keep.insert(n - 1)
    let rows = keep.sorted()
    var hidden: [Int: Int] = [:]
    for (k, i) in rows.enumerated() where k > 0 {
      let gap = i - rows[k - 1] - 1
      if gap > 0 { hidden[i] = gap }
    }
    return (rows, hidden)
  }

  var body: some View {
    let teams = model.teams
    if teams.isEmpty {
      empty
    } else {
      let indices = window?.rows ?? Array(teams.indices)
      let hidden = window?.hidden ?? [:]
      VStack(spacing: 0) {
        CSStandingsBoard(count: indices.count, cut: cutLabel, cutAfter: cutAfter(in: indices)) { k, abbreviate in
          let i = indices[k]
          if let n = hidden[i] { ellipsis(n) }
          row(i, teams[i], abbreviate: abbreviate)
        }
        if window != nil {
          HStack {
            CSDoor(.link("Every golfer") { wholeField = true })
            Spacer()
          }
          .csGutter()
          .padding(.top, CSTokens.Space.s3)
        }
      }
      .onAppear(perform: armTheFlip)
    }
  }

  // MARK: the cut

  /// A Cup-Final concept, meaningless for a points table or a field of two.
  private var cutLabel: String? {
    model.bylaws.finish == "cup_final" && model.teams.count > 2 ? SeasonBoardCopy.cut : nil
  }
  /// The cut draws after the SECOND ROW OF THE BOARD, wherever the window put
  /// it — a cut drawn after a hidden row is a cut drawn nowhere.
  private func cutAfter(in indices: [Int]) -> Int? {
    guard cutLabel != nil, let k = indices.firstIndex(of: 1) else { return nil }
    return k + 1
  }

  // MARK: a row

  @ViewBuilder private func row(_ i: Int, _ t: Team, abbreviate: Bool) -> some View {
    let solo = t.solo
    let mine = model.myTeamId == t.id
    let leader = i == 0
    let pr = model.priorRank[t.id]
    let flips = flipOnce && pr != nil && pr != i
    Button {
      if solo, let r = model.indRow(t.id) { router.open(.member(r)) } else { router.open(.squad(t)) }
    } label: {
      CSSlat(rank: i + 1,
             field: leader ? .earned : (mine ? .mine : .none),
             face: face(t),
             name: name(t, mine: mine, abbreviate: abbreviate),
             sub: clause(i, t, mine: mine),
             squad: squad(t),
             movement: movement(t, at: i),
             gap: SeasonBoardCopy.gap(leader: model.teams.first?.pts ?? t.pts, row: t.pts),
             emphasis: leader, railHidesNumeral: flips) {
        // the trailing column repeats down the table, so it carries no rule
        // and no label — position is already the hierarchy (§9.2). The
        // LEADER's total is `figure` 40 (D-5), and it is INK: the leader's
        // gold is the rail's field, and the surface's second gold is the pot.
        CSFigure(CSCopy.points(t.pts), size: leader ? .l : .m, label: nil)
      }
      .contentShape(Rectangle())
      // SF-6 · the rank slots on a fresh load, over the rail's own numeral
      .overlay(alignment: .leading) {
        if flips {
          RankFlipText(text: String(format: "%02d", i + 1), flip: true,
                       tone: leader || mine ? cs.panelInk : cs.ink)
            .frame(width: CSTokens.Space.rail)
            .frame(maxHeight: .infinity)
            .allowsHitTesting(false)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityHint(solo ? "Opens their rounds" : "Opens the squad receipt")
  }

  /// The viewer's own row reads **`YOU` alone**, product-wide: at the 375pt
  /// measure the fixed columns leave 141pt and `YOU · SAM RIDLEY` measures 143.
  private func name(_ t: Team, mine: Bool, abbreviate: Bool) -> String {
    // **`YOU` is a person's row, never a squad's.** The viewer's own squad
    // keeps its name and says "yours" with the rail's field — a table whose
    // top row reads `YOU / 3 golfers` has stopped naming the side that is
    // winning.
    if mine, t.solo { return "You" }
    guard abbreviate, t.solo else { return t.name }
    let parts = t.name.split(separator: " ")
    guard parts.count > 1, let first = parts.first?.first else { return t.name }
    return "\(first). " + parts.dropFirst().joined(separator: " ")
  }

  private func face(_ t: Team) -> CSFace.Model? {
    guard t.solo, let m = model.member(t.id) else { return nil }
    return CSFace.Model(id: m.profile_id, marker: m.mk,
                        photoURL: model.avatarURL[m.profile_id],
                        initials: "", isViewer: model.viewer?.id == m.profile_id)
  }

  /// **The swatch is CONDITIONED, not deleted** (CS-11 recorded a squad swatch
  /// in a two-golfer SOLO season). In a squads season an individual row leads
  /// its clause with a 4 × 14 bar and the squad's NAME — colour never carries
  /// the squad alone, because the four marks are 1.58:1 apart at best.
  private func squad(_ t: Team) -> (Color, String)? {
    // a SQUAD's own row carries the bar and no name — the name is the row's.
    if !t.solo { return (cs.squad(t.ci), "") }
    guard !model.bylaws.solo, let r = model.indRow(t.id), !r.sq.isEmpty else { return nil }
    return (cs.squad(r.ci), squadName(t.id) ?? r.sq)
  }

  /// **The squad's NAME, not `IndRow.sq`.** `StandingsMath.sqOf` returns the
  /// first four letters upper — a web-era abbreviation for a 60pt column — and
  /// §1.4a is explicit that colour never carries the squad alone, so the swatch
  /// is followed by a NAME. `MUDS` is not a name. The producer is untouched
  /// (a test pins it); the row resolves the full one from the roster it holds.
  private func squadName(_ memberId: UUID) -> String? {
    model.squads.first { $0.seats(memberId) }?.name
  }

  private func clause(_ i: Int, _ t: Team, mine: Bool) -> String {
    let story = model.seasonStory
    let row = story?.table.first { $0.id == t.id.uuidString.lowercased() || $0.id == t.id.uuidString }
    let run = story?.facts?.leader?.run_weeks
    let sinceWeek = run.flatMap { r -> Int? in
      guard let w = story?.facts?.week_no, r > 1 else { return nil }
      return max(1, w - r + 1)
    }
    let arr = model.series[t.id] ?? []
    let cooled = arr.count > 1 && arr[arr.count - 1] < arr[arr.count - 2]
    if !t.solo { return squadClause(t) }
    return SeasonBoardCopy.clause(isLeader: i == 0, runSince: sinceWeek, runWeeks: run,
                                  isMe: mine, counted: row?.counted, cap: model.bylaws.cap,
                                  rounds: t.solo ? t.sub : 0, solo: t.solo,
                                  left: row?.left == true, cooled: cooled)
  }

  /// `3 golfers · 3 counting` — a squad's row states its roster, because a
  /// squad has no rounds of its own and its points are the seats' sum.
  private func squadClause(_ t: Team) -> String {
    let seats = model.squads.first { $0.id == t.id }?.squad_members.count ?? 0
    guard seats > 0 else { return "" }
    let seatIds = Set(model.squads.first { $0.id == t.id }?.squad_members.map(\.member_id) ?? [])
    let counting = model.indRows.filter { seatIds.contains($0.mid) && $0.r > 0 }.count
    return "\(seats) golfer\(seats == 1 ? "" : "s")" + (counting > 0 ? " · \(counting) counting" : "")
  }

  /// `CSMovement` on the page's own ground — no chip, no fill, no tint.
  /// `▼` means *you fell* and nothing else.
  private func movement(_ t: Team, at i: Int) -> CSMovement.State? {
    guard let pr = model.priorRank[t.id] else { return nil }
    let d = pr - i
    if d > 0 { return .up(d) }
    if d < 0 { return .down(-d) }
    return .held
  }

  private func ellipsis(_ hidden: Int) -> some View {
    Text("\(hidden) more between").csType(.agateS, caps: true).foregroundStyle(cs.mut)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, CSTokens.Space.rail + CSSlatMetrics.railGap)
      .padding(.vertical, min(16, 3 + Double(hidden) * 1.5))   // distance looks like distance
      .accessibilityLabel("\(hidden) more between")
  }

  // MARK: the empty table

  /// §3 · **a fact about the world, never the golfer's omission**, and the door
  /// is required rather than optional.
  private var empty: some View {
    CSEmpty(glyph: .emptyRail,
            eyebrow: "The first card",
            headline: "The season starts with the first posted round.",
            fact: LeagueCopy.standingsEmpty(solo: model.solo).line2.capitalizedFirst,
            number: nil,
            door: links.openRecord.map { go in .primary("Add my round", go) } ?? .elsewhere("The season fills as rounds land."))
      .csGutter()
  }

  // MARK: the flip's replay gate

  /// SF-6 · rank flips on a FRESH data load only, consumed here so a re-render
  /// stays static. R-11 · the rank-up haptic, once, and only if YOUR row moved.
  private func armTheFlip() {
    guard model.freshStandings else { return }
    flipOnce = true
    model.freshStandings = false
    if let my = model.myTeamId, let i = model.teams.firstIndex(where: { $0.id == my }),
       let pr = model.priorRank[my], pr > i {
      CSHaptic.impact(.light)
    }
  }
}

private extension String {
  var capitalizedFirst: String { isEmpty ? self : prefix(1).uppercased() + dropFirst().lowercased() }
}

/// `#scenarioLine` (D24) — clinch / eliminated, never invented. **One `agateS`
/// line**, not a 13–14pt mono console message (CS-20), and the clinch keeps no
/// metal of its own: the surface's gold is the leader's rail and the pot.
struct ScenarioLineView: View {
  @Environment(\.cs) private var cs
  let parts: [ScenarioPart]
  var body: some View {
    if parts.isEmpty { EmptyView() } else {
      Text(parts.map(\.text).joined())
        .csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(parts.map(\.text).joined())
    }
  }
}

/// SF-6 — one rank as a split-flap: each glyph rides three deterministic
/// decoys (`sfWrap`, char-code offsets, no randomness) then lands, ~80ms
/// per character stagger. Reduced motion renders flat.
struct RankFlipText: View {
  let text: String
  let flip: Bool
  let tone: Color
  var body: some View {
    HStack(spacing: 0) {
      ForEach(Array(text.enumerated()), id: \.offset) { i, ch in
        FlipChar(final: ch, decoys: Self.decoys(ch, i), delay: Double(i) * 0.08, flip: flip, tone: tone)
      }
    }
    .csType(.figureM)
    .accessibilityLabel(text)
  }

  static func decoys(_ ch: Character, _ i: Int) -> [Character] {
    let pool: [Character]
    let base: Int
    if let d = ch.wholeNumberValue, ch.isNumber { pool = Array("0123456789"); base = d }
    else if let a = ch.uppercased().unicodeScalars.first?.value, a >= 65, a <= 90 { pool = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"); base = Int(a) - 65 }
    else { return [] }
    return [1, 2, 3].map { k in
      var x = (base + k * 7 + i * 3) % pool.count
      if x == base { x = (x + 1) % pool.count }
      return pool[x]
    }
  }
}

private struct FlipChar: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let final: Character
  let decoys: [Character]
  let delay: Double
  let flip: Bool
  let tone: Color
  @State private var shown: Character = " "
  @State private var angle: Double = 0

  var body: some View {
    Text(String(shown)).csTabular().foregroundStyle(tone)
      .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
      .onAppear { shown = final; if flip { run() } }
      .onChange(of: flip) { _, now in if now { run() } }
  }

  private func run() {
    guard !reduceMotion, !decoys.isEmpty else { shown = final; return }
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(delay))
      for next in decoys + [final] {
        CSMotion.run(CSMotion.tick) { angle = 90 }
        try? await Task.sleep(for: .milliseconds(150))
        shown = next
        angle = -90
        CSMotion.run(CSMotion.tick) { angle = 0 }
        try? await Task.sleep(for: .milliseconds(180))
      }
      shown = final; angle = 0
    }
  }
}


/// **EVERY GOLFER** — the individual table beneath the squad table in a squads
/// season (§1.4a). One component, one geometry: the same slat, the same rail,
/// the same merged change cell.
///
/// **DEGRADE, stated.** `indRows` carries no prior rank — `standings_snapshots`
/// snapshots SQUADS, not golfers — so an individual row in a squads season has
/// a gap and no movement mark. The alternative was a triangle derived from
/// nothing, which is the invention D-7 forbids.
struct GolferTableView: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.cs) private var cs

  var body: some View {
    let rows = model.indRows
    CSStandingsBoard(count: rows.count) { i, abbreviate in
      let p = rows[i]
      Button { router.open(.member(p)) } label: {
        CSSlat(rank: i + 1,
               field: i == 0 ? .earned : (p.me ? .mine : .none),
               face: face(p),
               name: p.me ? "You" : abbreviated(p.n, abbreviate),
               sub: clause(p),
               squad: p.sq.isEmpty ? nil : (cs.squad(p.ci), squadName(p.mid) ?? p.sq),
               movement: nil,
               gap: SeasonBoardCopy.gap(leader: rows.first?.pts ?? p.pts, row: p.pts),
               emphasis: i == 0) {
          CSFigure(CSCopy.points(p.pts), size: i == 0 ? .l : .m, label: nil)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint("Opens their rounds")
    }
  }

  private func squadName(_ memberId: UUID) -> String? {
    model.squads.first { $0.seats(memberId) }?.name
  }

  private func face(_ p: IndRow) -> CSFace.Model? {
    guard let m = model.member(p.mid) else { return nil }
    return CSFace.Model(id: m.profile_id, marker: m.mk, photoURL: model.avatarURL[m.profile_id],
                        isViewer: model.viewer?.id == m.profile_id)
  }

  private func clause(_ p: IndRow) -> String {
    SeasonBoardCopy.clause(isLeader: false, runSince: nil, runWeeks: nil,
                           isMe: p.me, counted: model.myMonth.map { Int($0.counting) },
                           cap: p.me ? model.bylaws.cap : nil,
                           rounds: p.r, solo: true, left: false)
  }

  private func abbreviated(_ name: String, _ on: Bool) -> String {
    guard on else { return name }
    let parts = name.split(separator: " ")
    guard parts.count > 1, let f = parts.first?.first else { return name }
    return "\(f). " + parts.dropFirst().joined(separator: " ")
  }
}
