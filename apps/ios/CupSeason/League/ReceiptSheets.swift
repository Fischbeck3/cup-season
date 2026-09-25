// Cup Season — the receipts (§16: no points figure without the rounds behind it).
//   SquadReceiptSheet   `showSquadReal`  index.html 11644–11666 — plus the ledger
//                       rows WITH reasons, the one select the web never made
//   MemberHistorySheet  `openMemberHist` 11278–11288 — counting vs BUMPED

import SwiftUI
import CSDesign
import CupSeasonKit

struct SquadReceiptSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs
  @State private var book = SeasonBookStore()
  @State private var selected: SeasonBookSnapshot.Row?
  let team: Team

  private var squad: SeasonBookSnapshot.Row? {
    book.snapshot?.rows.first { $0.kind == "squad" && $0.squad_id == team.id }
  }
  private var contributions: [SeasonBookSnapshot.Row] {
    (book.snapshot?.rows ?? []).filter { $0.kind == "contribution" && $0.squad_id == team.id }
      .sorted { $0.points > $1.points }
  }
  private var names: [UUID: String] {
    Dictionary(model.members.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })
  }

  var body: some View {
    SheetFrame(team.name, sub: "Squad points") {
      if let squad {
        // The Book owns eligibility, caps and adjustments. Individual totals
        // include pre-seat rounds and must never be summed into a squad receipt.
        CSLeaf(padding: CSTokens.Space.s3) {
          RoomMathRow(k: "Rounds that count", v: String(squad.entries.filter(\.isRound).reduce(0) { $0 + $1.contribution }))
          ForEach(squad.entries.filter { !$0.isRound }) { entry in
            RoomMathRow(k: entry.reason, v: (entry.contribution > 0 ? "+" : "") + String(entry.contribution))
          }
          RoomMathRow(k: "Total", v: String(squad.points), total: true)
        }
        CSDoor(.link("Every round and adjustment") { selected = squad })
        CSSectionHead("Who built it")
        ForEach(contributions) { row in
          Button { selected = row } label: {
            HStack {
              Text(row.name).csType(.name)
              Spacer()
              CSFigure(String(row.points), size: .m, label: "points")
            }.frame(minHeight: 44).contentShape(Rectangle())
          }.buttonStyle(.plain)
            .accessibilityLabel("\(row.name), \(row.points) squad points")
            .accessibilityHint("Opens the contributions to this squad")
        }
        RoomFine("These are the points each golfer contributed to this squad. Their individual record keeps their other rounds.")
      } else {
        CSFigure(CSCopy.points(team.pts), size: .l, label: "squad points")
        RoomFine(book.error ?? (book.loading ? "Loading the rounds and adjustments…" : "The squad’s points record is unavailable."))
        Button("Try again") { Task { await load() } }.buttonStyle(.csSecondary()).disabled(book.loading)
      }
    }
    .task { await load() }
    .sheet(item: $selected) { row in
      SeasonBookReceipts(title: row.name, entries: row.entries, names: names, openRound: links.openReceipt)
    }
  }

  private func load() async {
    #if DEBUG
    if CompeteSelectedFixture.on { book.seed(CompeteSelectedFixture.book(model.leagueId)); return }
    #endif
    guard let season = model.season else { return }
    await book.load(league: model.leagueId, season: season.id)
  }
}

struct MemberHistorySheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let row: IndRow
  /// D352 · the league's stored counting rule, so the sentence that explains a
  /// round sitting outside the month can NAME the rule that put it there
  /// instead of gesturing at it. nil is Unlimited, in which case no round is
  /// ever outside and this sentence never appears.
  var cap: Int? = nil

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
                Text(LeagueDates.monDay(h.played_on).uppercased() + (h.holes_played == 9 ? " · 9 HOLES" : "") + (h.counting ? "" : " · OUTSIDE MONTHLY BEST"))
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
            .accessibilityLabel("\(h.played_on)\(h.holes_played == 9 ? ", 9 holes" : ""), \(StandingsMath.sgn(h.pvi)) versus \(whose) number, \(CSCopy.points(h.points)) points\(h.counting ? "" : ", outside the monthly best")")
            .accessibilityHint(h.round_id == nil ? "" : "Opens the round")
          }
        }
        if row.hist.contains(where: { !$0.counting }) {
          RoomFine("These rounds stay in your record. \(LeagueCopy.countingRule(cap)) A better one took the slot.").padding(.top, 10)
        }
      }
      // D376 · the rulings are listed whether or not there is round history:
      // a golfer with no rounds and a ruling still has a total to explain,
      // and the header's figure is the standings' (which read the ledger).
      rulingRows
      if !row.hist.isEmpty, let pid = row.profileId {
        RoomMini(GolfersRoot.CardName.title(row.n)) { dismiss(); links.openTourCard(pid) }.padding(.top, 6)
      }
    }
  }

  /// D376 · a ruling on this golfer sits in the ledger the room already reads
  /// and is part of the total in the header, so it is listed here with its
  /// reason — §16: no points figure without the path that produced it. The
  /// desk's receipt lists the same rows (`openMemberHist`).
  @ViewBuilder private var rulingRows: some View {
    let mid: UUID? = row.mid
    let rulings = mid.map { model.rulings(member: $0) } ?? []
    if !rulings.isEmpty {
      CSSectionHead(row.hist.isEmpty ? "Where the points came from" : "Rulings").padding(.top, CSTokens.Space.s2)
      VStack(spacing: 0) {
        ForEach(rulings) { a in
          A11yStack(rowAlignment: .firstTextBaseline, spacing: 10, columnSpacing: 2) {
            // LINT-07 · CSType is the one tracking call site — never a bare .tracking()
            Text(RulingCopy.ledgerLine(month: a.month, reason: a.reason))
              .csType(.agateS, caps: true).foregroundStyle(cs.mut)
            Spacer()
            Text("\(a.points > 0 ? "+" : "")\(a.points) PTS").csType(.columnS).foregroundStyle(cs.ink)
          }
          .padding(.vertical, 10).frame(minHeight: 44)
          .overlay(alignment: .bottom) { Rectangle().fill(cs.rule).frame(height: 1) }
          .accessibilityElement(children: .combine)
          .accessibilityLabel("\(RulingCopy.ledgerLine(month: a.month, reason: a.reason)), \(a.points) points")
        }
      }
    }
  }
}
