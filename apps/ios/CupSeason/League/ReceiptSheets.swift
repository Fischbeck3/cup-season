// Cup Season — the receipts (§16: no points figure without the rounds behind it).
//   SquadReceiptSheet   `showSquadReal`  index.html 11644–11666 — plus the ledger
//                       rows WITH reasons, the one select the web never made
//   MemberHistorySheet  `openMemberHist` 11278–11288 — counting vs BUMPED

import SwiftUI
import CSDesign
import CupSeasonKit

struct SquadReceiptSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.cs) private var cs
  let team: Team

  var body: some View {
    let rows = model.indRows.filter { r in model.squads.first { $0.id == team.id }?.seats(r.mid) ?? false }.sorted { $0.pts > $1.pts }
    let fromRounds = rows.reduce(0) { $0 + $1.pts }
    let adj = team.pts - fromRounds   // the ledger's net: bonuses − penalties
    let ledger = model.ledger(squad: team.id)
    SheetFrame(team.name, sub: "\(team.cap.isEmpty ? "" : "CAPT. \(team.cap.uppercased()) · ")\(rows.count) PLAYERS · \(CSCopy.points(team.pts)) PTS") {
      VStack(alignment: .leading, spacing: 0) {
        RoomMathRow(k: "Counting rounds", v: CSCopy.points(fromRounds))
        if ledger.isEmpty {
          if adj != 0 { RoomMathRow(k: "Bonuses & penalties · the ledger", v: (adj > 0 ? "+" : "") + CSCopy.points(adj), tone: adj > 0 ? cs.pos : cs.neg) }
        } else {
          ForEach(ledger) { a in
            RoomMathRow(k: ledgerLabel(a), v: (a.points > 0 ? "+" : "") + String(a.points), tone: a.points > 0 ? cs.pos : a.points < 0 ? cs.neg : cs.mut)
          }
          if ledger.reduce(0, { $0 + Double($1.points) }) != adj {
            RoomMathRow(k: "Bonuses & penalties · the ledger", v: (adj > 0 ? "+" : "") + CSCopy.points(adj), tone: adj > 0 ? cs.pos : cs.neg)
          }
        }
        RoomMathRow(k: "Total", v: CSCopy.points(team.pts), total: true)
      }
      Text("Who built it").csEyebrow().padding(.top, 6)
      VStack(spacing: 0) {
        ForEach(rows) { p in
          Button { router.open(.member(p)) } label: {
            HStack(spacing: 10) {
              RoundedRectangle(cornerRadius: 3).fill(cs.squad(p.ci)).frame(width: 10, height: 10)
              VStack(alignment: .leading, spacing: 2) {
                Text(p.n).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
                Text("\(p.r) ROUND\(p.r == 1 ? "" : "S") · AVG vs index \(p.r > 0 ? StandingsMath.sgn(p.avg) : "—")")
                  .font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
              }
              Spacer()
              Text(CSCopy.points(p.pts)).font(CSFont.monoMediumBody).csTabular().foregroundStyle(cs.ink)
            }
            .padding(.vertical, 10).frame(minHeight: 48).contentShape(Rectangle())
            .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
          }
          .buttonStyle(.plain)
        }
        if rows.isEmpty { RoomFine("No rounds posted yet — the squad is waiting on its first counter.").padding(.vertical, 8) }
      }
      RoomFine("Squad points = everyone's counting rounds + the ledger. Tap any player for the rounds behind their number.").padding(.top, 6)
    }
  }

  /// "Aug · Dave · 1 round short of the floor" — month · who · reason (§14.2).
  private func ledgerLabel(_ a: LeagueRoom.Adjustment) -> String {
    var parts: [String] = []
    if let m = a.month { parts.append(LeagueDates.monDay(m).split(separator: " ").first.map(String.init) ?? m) }
    if let mid = a.member_id { parts.append(model.memName(mid)) }
    parts.append(a.reason ?? a.kind.replacingOccurrences(of: "_", with: " "))
    return parts.joined(separator: " · ")
  }
}

struct MemberHistorySheet: View {
  @Environment(\.roomLinks) private var links
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  let row: IndRow

  var body: some View {
    SheetFrame(row.n, sub: "\(row.r) ROUND\(row.r == 1 ? "" : "S") · \(CSCopy.points(row.pts)) PTS") {
      if row.hist.isEmpty {
        CSEmptyState(icon: "⛳", line: "No rounds this season yet — post one and you're on the board.",
                     cta: links.openRecord == nil ? nil : "Post a round") { dismiss(); links.openRecord?() }
      } else {
        VStack(spacing: 0) {
          ForEach(row.hist) { h in
            Button {
              if let id = h.round_id { dismiss(); links.openReceipt(id) }
            } label: {
              HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(h.played_on + (h.holes_played == 9 ? " · 9 HOLES" : "") + (h.counting ? "" : " · BUMPED"))
                  .font(CSFont.label).tracking(0.6).foregroundStyle(h.counting ? cs.mut : cs.dimText)
                Spacer()
                Text("\(StandingsMath.sgn(h.pvi)) vs index · \(CSCopy.points(h.points)) PTS")
                  .font(CSFont.monoSmall).csTabular().foregroundStyle(h.counting ? cs.ink : cs.mut).lineLimit(1)
              }
              .padding(.vertical, 10).frame(minHeight: 44).contentShape(Rectangle())
              .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
            }
            .buttonStyle(.plain)
            .disabled(h.round_id == nil)
          }
        }
        if row.hist.contains(where: { !$0.counting }) {
          RoomFine("Bumped rounds still happened — a better round took their monthly slot. A better round always bumps your worst counter.").padding(.top, 10)
        }
        if let pid = row.profileId {
          RoomMini("Tour Card") { dismiss(); links.openTourCard(pid) }.padding(.top, 6)
        }
      }
    }
  }
}
