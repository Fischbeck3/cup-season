// Cup Season — THE CUP FINAL block (D105; web `renderCupRace`, index.html 4522):
// the finalists in race order, the seed, the +10 head start as its own line,
// window points and rounds of the cap, days left, the rung that seeded. It
// leads Standings while the window is open; the full-season table drops
// beneath it as "The regular season — final". Fed by cup_final_race() — the
// rows close_season crowns from, so this block and the ceremony agree (§16).

import SwiftUI
import CSDesign
import CupSeasonKit

struct CupFinalRaceView: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  var body: some View {
    if let race = model.cupRace, race.isLive {
      let dl = race.days_left ?? model.clock.daysLeft
      // §10 · **the same slat.** The block's own 21pt finalist total was the
      // only points figure in the shipped set above 14pt, and generalising it
      // is exactly what `figure` 27 is: the Cup Final's board is the season
      // board's board, at the season board's geometry, with the seed in the
      // rail. The head's own gold eyebrow went with it — nothing here has been
      // won yet, and the rail already carries the one metal this block spends.
      VStack(alignment: .leading, spacing: 0) {
        CSSectionHead("The Cup Final",
                      count: "\(dl) day\(dl == 1 ? "" : "s") left"
                        + (race.seed_rung.map { " · in the Final by \($0)" } ?? ""))
          .csGutter()
          .padding(.bottom, CSTokens.Space.s2)
        CSStandingsBoard(count: race.race.count) { i, _ in
          row(i, race.race[i], capN: race.cap_n)
        }
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel("The Cup Final, \(dl) days left")
    }
  }

  /// **`THRU` in place of `GAP`** is §15.5's rule for an EVENT board; a Cup
  /// Final is a season's endgame and its change cell is the head start, which
  /// is a fact about the seed rather than about movement — so the cell is the
  /// gap to the leader and the movement column is absent. `cup_final_race`
  /// carries no prior rank, and a triangle derived from nothing is the
  /// invention D-7 forbids.
  private func row(_ i: Int, _ f: CupFinalRace.Finalist, capN: Int?) -> some View {
    let team = model.teams.first { $0.id == f.teamId }
    let name = team?.name ?? f.name
    let lead = i == 0 && f.total > 0
    let mine = f.teamId != nil && f.teamId == model.myTeamId
    let sub = (f.head_start > 0 ? "Starts +\(CSCopy.points(f.head_start)) · top seed · " : "")
      + "Window \(CSCopy.points(f.window_points)) pts · \(f.rounds_used) round\(f.rounds_used == 1 ? "" : "s")"
      + ((capN ?? 10000) < 10000 ? " of \(capN!)" : "")
    let leader = model.cupRace?.race.first?.total ?? f.total
    return Button { router.open(.finalist(f)) } label: {
      CSSlat(rank: f.seed,
             field: lead ? .earned : (mine ? .mine : .none),
             face: face(f),
             name: mine && (team?.solo ?? false) ? "You" : name,
             sub: sub,
             squad: team.map { $0.solo ? nil : (cs.squad($0.ci), "") } ?? nil,
             movement: nil,
             gap: SeasonBoardCopy.gap(leader: leader, row: f.total),
             variant: lead ? .leader : .table) {
        CSFigure(CSCopy.points(f.total), size: lead ? .l : .m, label: nil)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityHint("Opens the rounds behind the number")
  }

  /// A SQUAD's rung draws no disc — the rail and the swatch already say which
  /// side it is, and a face there would be one of four golfers standing in for
  /// four (§1's own `face: nil` rule).
  private func face(_ f: CupFinalRace.Finalist) -> CSFace.Model? {
    guard let team = model.teams.first(where: { $0.id == f.teamId }), team.solo,
          let m = model.member(team.id) else { return nil }
    return CSFace.Model(id: m.profile_id, marker: m.mk, photoURL: model.avatarURL[m.profile_id],
                        isViewer: model.viewer?.id == m.profile_id)
  }
}

/// A finalist's receipt: head start + the window rounds = the total on the table.
struct FinalistReceiptSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let finalist: CupFinalRace.Finalist

  var body: some View {
    let f = finalist
    let name = model.teams.first { $0.id == f.teamId }?.name ?? f.name
    // QB-17 · this sheet is a rung, and a rung is usually somebody else. Only
    // my own rung may say "your playing HCP".
    let whose = (f.teamId != nil && f.teamId == model.myTeamId) ? "your" : "their"
    SheetFrame(name, sub: "SEED \(f.seed) · \(CSCopy.points(f.total)) PTS IN THE FINAL") {
      VStack(alignment: .leading, spacing: 0) {
        if f.head_start > 0 { RoomMathRow(k: "Head start · top seed", v: "+" + CSCopy.points(f.head_start), tone: cs.pos) }
        RoomMathRow(k: "Window rounds · scored fresh", v: CSCopy.points(f.window_points))
        if let r = f.seed_rung { RoomMathRow(k: "In the Final by", v: r.uppercased()) }
        RoomMathRow(k: "Total in the Final", v: CSCopy.points(f.total), total: true)
      }
      Text("The rounds").csEyebrow().padding(.top, 6)
      // D212 · the calendar cap does not stop at the window's edge, and the
      // sentence that says so is the SERVER's, not a second copy on the phone.
      if let note = model.cupRace?.cap_note { RoomFine(note).padding(.top, 4) }
      if f.rounds.isEmpty {
        RoomFine("No rounds in the window yet.").padding(.vertical, 8)
      } else {
        VStack(spacing: 0) {
          ForEach(f.rounds) { h in
            Button {
              if let id = h.round_id { dismiss(); links.openReceipt(id) }
            } label: {
              A11yStack(rowAlignment: .firstTextBaseline, spacing: 10, columnSpacing: 2) {
                Text(LeagueDates.monDay(h.played_on).uppercased()
                     + (h.holes_played == 9 ? " · 9 HOLES" : "")
                     + (f.squad_id != nil ? " · \((h.golfer ?? "").uppercased())" : ""))
                  .font(CSFont.label).tracking(0.6).foregroundStyle(cs.mut)
                Spacer()
                Text("\(StandingsMath.sgn(h.pvi ?? 0)) vs \(whose) number · \(CSCopy.points(h.points)) PTS")
                  .csType(.columnS).foregroundStyle(cs.ink).lineLimit(typeSize.isA11y ? nil : 1)
              }
              .padding(.vertical, 10).frame(minHeight: 44).contentShape(Rectangle())
              .overlay(alignment: .bottom) { Rectangle().fill(cs.rule).frame(height: 1) }
            }
            .buttonStyle(.plain)
            .disabled(h.round_id == nil)
            .accessibilityElement(children: .combine)
            .accessibilityHint(h.round_id == nil ? "" : "Opens the round")
          }
        }
      }
      RoomFine("Only rounds inside the four-week window count here, up to the monthly cap. The weeks before it decided who is in; this is the race.").padding(.top, 10)
    }
  }
}
