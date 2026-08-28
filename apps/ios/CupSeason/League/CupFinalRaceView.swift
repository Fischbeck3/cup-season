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
      let ax = typeSize.isA11y
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 6) {
          Text("The Cup Final").csEyebrow(cs.gold)
          Text("· \(dl) DAY\(dl == 1 ? "" : "S") LEFT" + (race.seed_rung.map { " · SEEDED BY \($0.uppercased())" } ?? ""))
            .font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText).lineLimit(ax ? nil : 1)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { CSHairline() }
        ForEach(Array(race.race.enumerated()), id: \.element.seed) { i, f in
          row(i, f, capN: race.cap_n)
        }
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel("The Cup Final, \(dl) days left")
    }
  }

  private func row(_ i: Int, _ f: CupFinalRace.Finalist, capN: Int?) -> some View {
    let team = model.teams.first { $0.id == f.teamId }
    let ci = team?.ci ?? (i % 4)
    let name = team?.name ?? f.name
    let lead = i == 0 && f.total > 0
    let sub = (f.head_start > 0 ? "STARTS +\(CSCopy.points(f.head_start)) · TOP SEED · " : "")
      + "WINDOW \(CSCopy.points(f.window_points)) PTS · \(f.rounds_used) ROUND\(f.rounds_used == 1 ? "" : "S")"
      + ((capN ?? 10000) < 10000 ? " OF \(capN!)" : "")
    return Button { router.open(.finalist(f)) } label: {
      A11yStack(spacing: 10, columnSpacing: 4) {
        HStack(spacing: 10) {
          Text("S\(f.seed)").font(CSFont.monoMediumBody).csTabular().foregroundStyle(lead ? cs.gold : cs.mut).frame(minWidth: 34, alignment: .leading)
          RoundedRectangle(cornerRadius: 3).fill(cs.squad(ci)).frame(width: 10, height: 10)
          VStack(alignment: .leading, spacing: 1) {
            Text(name).font(CSFont.subhead.weight(lead ? .semibold : .regular)).foregroundStyle(cs.ink)
            Text(sub).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        Text(CSCopy.points(f.total)).font(CSFont.stat).csTabular().foregroundStyle(lead ? cs.gold : cs.ink)
      }
      .padding(.horizontal, 4).padding(.vertical, 10).frame(minHeight: 56).contentShape(Rectangle())
      .overlay(alignment: .bottom) { Rectangle().fill(lead ? cs.gold.opacity(0.55) : cs.line).frame(height: 1) }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Seed \(f.seed), \(name), \(CSCopy.points(f.total)) points in the Final" + (f.head_start > 0 ? ", starts plus \(CSCopy.points(f.head_start))" : ""))
    .accessibilityHint("Opens the rounds behind the number")
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
    SheetFrame(name, sub: "SEED \(f.seed) · \(CSCopy.points(f.total)) PTS IN THE FINAL") {
      VStack(alignment: .leading, spacing: 0) {
        if f.head_start > 0 { RoomMathRow(k: "Head start · top seed", v: "+" + CSCopy.points(f.head_start), tone: cs.pos) }
        RoomMathRow(k: "Window rounds · scored fresh", v: CSCopy.points(f.window_points))
        if let r = f.seed_rung { RoomMathRow(k: "Seeded by", v: r.uppercased()) }
        RoomMathRow(k: "Total in the Final", v: CSCopy.points(f.total), total: true)
      }
      Text("The rounds").csEyebrow().padding(.top, 6)
      if f.rounds.isEmpty {
        RoomFine("No counting rounds in the window yet — the slate is still clean.").padding(.vertical, 8)
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
                Text("\(StandingsMath.sgn(h.pvi ?? 0)) vs index · \(CSCopy.points(h.points)) PTS")
                  .font(CSFont.monoSmall).csTabular().foregroundStyle(cs.ink).lineLimit(typeSize.isA11y ? nil : 1)
              }
              .padding(.vertical, 10).frame(minHeight: 44).contentShape(Rectangle())
              .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
            }
            .buttonStyle(.plain)
            .disabled(h.round_id == nil)
            .accessibilityElement(children: .combine)
            .accessibilityHint(h.round_id == nil ? "" : "Opens the round")
          }
        }
      }
      RoomFine("Only rounds inside the four-week window count here, up to the monthly cap. The regular season is the seed; this is the race.").padding(.top, 10)
    }
  }
}
