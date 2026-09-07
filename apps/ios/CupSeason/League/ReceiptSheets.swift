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
  @Environment(\.dynamicTypeSize) private var typeSize
  let team: Team

  var body: some View {
    let rows = model.indRows.filter { r in model.squads.first { $0.id == team.id }?.seats(r.mid) ?? false }.sorted { $0.pts > $1.pts }
    let fromRounds = rows.reduce(0) { $0 + $1.pts }
    let adj = team.pts - fromRounds   // the ledger's net: bonuses − penalties
    let ledger = model.ledger(squad: team.id)
    SheetFrame(team.name, sub: "\(team.cap.isEmpty ? "" : "CAPT. \(team.cap.uppercased()) · ")\(rows.count) GOLFERS · \(CSCopy.points(team.pts)) PTS") {
      // §6 · **the same leaf as the round's receipt.** One receipt shape in the
      // product: label rows on hairlines, the arithmetic quieter than the
      // answer, and the total under a 2pt `leafInk` rule ending in a figure.
      CSLeaf(padding: CSTokens.Space.s3) {
        HStack(alignment: .firstTextBaseline) {
          Text("What this squad is worth").csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
          Spacer(minLength: CSTokens.Space.s2)
          Text("\(rows.count) golfers").csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
        }
        RoomMathRow(k: "Counting rounds", v: CSCopy.points(fromRounds))
        if ledger.isEmpty {
          if adj != 0 { RoomMathRow(k: "Bonuses & penalties · the ledger", v: (adj > 0 ? "+" : "") + CSCopy.points(adj)) }
        } else {
          ForEach(ledger) { a in
            RoomMathRow(k: ledgerLabel(a), v: (a.points > 0 ? "+" : "") + String(a.points))
          }
          if ledger.reduce(0, { $0 + Double($1.points) }) != adj {
            RoomMathRow(k: "Bonuses & penalties · the ledger", v: (adj > 0 ? "+" : "") + CSCopy.points(adj))
          }
        }
        RoomMathRow(k: "Total", v: CSCopy.points(team.pts), total: true)
      }
      // the table's Trend column (web 4547) lives here on the phone, as
      // promised in StandingsTableView — on the PAGE, not on the leaf: a leaf
      // holds a grid, and a sparkline is not one.
      if let s = model.series[team.id], s.count >= 2 {
        HStack {
          Text("Trend").csType(.agateS, caps: true).foregroundStyle(cs.mut)
          Spacer()
          RoomTrendBars(values: s)
        }
        .padding(.vertical, CSTokens.Space.s2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trend, \(s.suffix(7).map { CSCopy.points($0) }.joined(separator: ", ")) over the last \(min(7, s.count)) weeks")
      }
      CSSectionHead("Who built it").padding(.top, CSTokens.Space.s2)
      VStack(spacing: 0) {
        ForEach(rows) { p in
          Button { router.open(.member(p)) } label: {
            A11yStack(spacing: 10, columnSpacing: 4) {
              HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3).fill(cs.squad(p.ci)).frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                  Text(p.n).csType(.name).foregroundStyle(cs.ink)
                  // QB-17 · the row is one golfer's average; only my own row
                  // may say "your". `IndRow.me` has always known which.
                  Text("\(p.r) ROUND\(p.r == 1 ? "" : "S") · AVG vs \(p.me ? "your" : "their") number \(p.r > 0 ? StandingsMath.sgn(p.avg) : "—")")
                    .font(CSFont.label).tracking(0.8).foregroundStyle(cs.mut)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
              }
              Spacer()
              Text(CSCopy.points(p.pts) + (typeSize.isA11y ? " PTS" : "")).csType(.columnM).foregroundStyle(cs.ink)
            }
            .padding(.vertical, 10).frame(minHeight: 48).contentShape(Rectangle())
            .overlay(alignment: .bottom) { Rectangle().fill(cs.rule).frame(height: 1) }
          }
          .buttonStyle(.plain)
          .accessibilityLabel("\(p.n), \(p.r) round\(p.r == 1 ? "" : "s"), \(CSCopy.points(p.pts)) points")
          .accessibilityHint("Opens their rounds")
        }
        if rows.isEmpty { RoomFine("No rounds posted yet — the squad is waiting on its first counter.").padding(.vertical, 8) }
      }
      RoomFine("Squad points = everyone's counting rounds + the ledger. Tap any player for the rounds behind their points.").padding(.top, 6)
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
  @Environment(\.dynamicTypeSize) private var typeSize
  let row: IndRow

  /// QB-17 · **WHOSE NUMBER.**
  ///
  /// This sheet lists ONE golfer's rounds, and every row said "vs your
  /// number" — inside a sheet about somebody else. A reader opening his rival's
  /// rounds stopped dead: *"Whose number? It's a list of Cal's rounds — it must
  /// be his — but the label says your. I checked twice. Half of what this sheet
  /// is for is comparing him to me, so the one ambiguous pronoun in it is the
  /// pronoun that decides the meaning."*
  ///
  /// `IndRow.me` already answers it, and has all along.
  private var whose: String { row.me ? "your" : "their" }

  var body: some View {
    SheetFrame(row.n, sub: "\(row.r) ROUND\(row.r == 1 ? "" : "S") · \(CSCopy.points(row.pts)) PTS") {
      if row.hist.isEmpty {
        // §13.1 · a fact about the world, never the golfer's omission — and
        // a door that is there whether or not the composer can be reached
        // from here. `CSEmptyState` made both optional and dropped the door
        // silently; `CSEmpty.Door` is non-optional and the compiler is LINT-21.
        CSEmpty(glyph: .scorecard,
                eyebrow: row.me ? "Your season" : "Their season",
                headline: row.me ? "No rounds on the board yet."
                                 : "Nothing on the board this season.",
                fact: "A round posts here the moment it is scored.",
                door: links.openRecord == nil
                  ? .elsewhere("Add my round from the play tab.")
                  : .primary("Add my round") { dismiss(); links.openRecord?() })
      } else {
        VStack(spacing: 0) {
          ForEach(row.hist) { h in
            Button {
              if let id = h.round_id { dismiss(); links.openReceipt(id) }
            } label: {
              A11yStack(rowAlignment: .firstTextBaseline, spacing: 10, columnSpacing: 2) {
                // the web prints the ISO string here (11303); a label row reads the calendar date
                Text(LeagueDates.monDay(h.played_on).uppercased() + (h.holes_played == 9 ? " · 9 HOLES" : "") + (h.counting ? "" : " · BUMPED"))
                  .font(CSFont.label).tracking(0.6).foregroundStyle(h.counting ? cs.mut : cs.mut)
                Spacer()
                Text("\(StandingsMath.sgn(h.pvi)) vs \(whose) number · \(CSCopy.points(h.points)) PTS")
                  .csType(.columnS).foregroundStyle(h.counting ? cs.ink : cs.mut).lineLimit(typeSize.isA11y ? nil : 1)
              }
              .padding(.vertical, 10).frame(minHeight: 44).contentShape(Rectangle())
              .overlay(alignment: .bottom) { Rectangle().fill(cs.rule).frame(height: 1) }
            }
            .buttonStyle(.plain)
            .disabled(h.round_id == nil)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(h.played_on)\(h.holes_played == 9 ? ", 9 holes" : ""), \(StandingsMath.sgn(h.pvi)) versus \(whose) number, \(CSCopy.points(h.points)) points\(h.counting ? "" : ", bumped")")
            .accessibilityHint(h.round_id == nil ? "" : "Opens the round")
          }
        }
        if row.hist.contains(where: { !$0.counting }) {
          RoomFine("Bumped rounds still happened — a better round took their monthly slot. A better round always bumps your worst counter.").padding(.top, 10)
        }
        if let pid = row.profileId {
          RoomMini(GolfersRoot.CardName.title(row.n)) { dismiss(); links.openTourCard(pid) }.padding(.top, 6)
        }
      }
    }
  }
}
