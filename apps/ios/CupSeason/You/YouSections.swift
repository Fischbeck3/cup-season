// Cup Season — the You tab's blocks (index.html 2829–2917): the feedback
// chip, the founder's desk, last round with (D63), the record (D67), the
// lifetime tiles, recent rounds with the owner's delete, the season strip, the
// league record (D4).

import SwiftUI
import CSDesign
import CupSeasonKit

// MARK: - the feedback chip (F8)

struct FeedbackChip: View {
  @Environment(\.cs) private var cs
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 9) {
        Text("💬 Tell us how it's going").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        Spacer()
        Text("→").font(CSFont.subhead).foregroundStyle(cs.dimText)
      }
      .frame(minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

// MARK: - the founder's desk (owner only; the SERVER is the gate)

/// A quiet row group under its own eyebrow (IOS-019 rule 2), not a card.
struct FounderDeskRows: View {
  let openDesk: () -> Void
  let fieldNote: (() -> Void)?
  var body: some View {
    CSSectionHead("Founder's desk")
    VStack(spacing: 0) {
      if let fieldNote {
        CSRow { YouDoorRow(glyph: Text("✏️"), title: "Field note", action: fieldNote) }
      }
      CSRow(last: true) { YouDoorRow(glyph: Text("📈"), title: "Open the desk", action: openDesk) }
      Fine("Notes land in the feedback ledger · the desk shows signups, activity, errors, feedback.").padding(.top, 6)
    }
  }
}

// MARK: - D63: last round with — the reunion whisper

struct LastRoundWithCard: View {
  @Environment(\.cs) private var cs
  let lrw: LastRoundWith
  let stage: ((String, UUID) -> Void)?
  let later: () -> Void
  var body: some View {
    let line = lrw.line()
    CSCard {
      HStack(alignment: .center, spacing: 12) {
        CSMarkerView(key: lrw.marker, size: 24).foregroundStyle(cs.ink)
        VStack(alignment: .leading, spacing: 2) {
          (Text(line.lead) + Text(line.name).bold() + Text(line.tail))
            .font(CSFont.sentence).foregroundStyle(cs.ink)
          Text(lrw.sub).font(CSFont.footnote).foregroundStyle(cs.dimText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        VStack(spacing: 6) {
          if let stage { MiniButton(label: "Stage it") { stage(LastRoundWith.nextSaturday(), lrw.profileId) } }
          MiniButton(label: "Later", action: later).accessibilityLabel("Quiet for a while")
        }
      }
    }
  }
}

// MARK: - D67: the record

struct CareerRecordView: View {
  @Environment(\.cs) private var cs
  let record: CareerRecord?
  var body: some View {
    // the silverware as one strip of gold figures, then the money as a row (IOS-019: no card in a card)
    if let r = record {
      VStack(alignment: .leading, spacing: 0) {
        if r.items.isEmpty {
          Fine(CareerRecord.noSilverware).padding(.vertical, 6)
        } else {
          HStack(alignment: .top, spacing: 0) {
            ForEach(r.items) { i in
              VStack(alignment: .leading, spacing: 2) {
                Text(String(i.n)).font(CSFont.heroSmall).foregroundStyle(cs.gold).csTabular()   // EARNED
                Text(i.label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.mut).lineLimit(1).minimumScaleFactor(0.85)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .accessibilityElement(children: .combine)
            }
          }
          .padding(.vertical, 8)
        }
        if let money = r.moneyLine {
          CSHairline()
          YouStatRow(label: money.sub, value: money.amount).padding(.vertical, 10)
          Fine(CareerRecord.moneyNote)
        }
      }
    } else {
      Fine(CareerRecord.emptyLine).padding(.vertical, 6)
    }
  }
}

// MARK: - the lifetime tiles

struct LifetimeTiles: View {
  let career: Career?
  var body: some View {
    VStack(spacing: 0) {
      CSRow { YouStatRow(label: "Rounds posted", value: career?.roundsText ?? "—", sub: "All time") }
      CSRow { YouStatRow(label: "Lowest differential", value: career?.bestText ?? "—", sub: "Career best") }
      CSRow { YouStatRow(label: "Avg vs index", value: career?.avgText ?? "—", sub: "vs your index") }
      CSRow(last: true) { YouStatRow(label: "Cups & events", value: career?.playedText ?? "—", sub: "Played in") }
    }
  }
}

// MARK: - recent rounds, with the owner's delete (two-tap arm, never an alert)

struct RecentRoundsList: View {
  @Environment(\.cs) private var cs
  let recent: [RoundRow]
  let open: (RoundRow) -> Void
  let delete: (RoundRow) async -> Void
  let postFirst: () -> Void
  @State private var armed: UUID?
  @State private var deleting: UUID?

  var body: some View {
    Group {
      if recent.isEmpty {
        CSEmptyState(icon: "⛳", line: "No rounds yet — your card fills as you play.", cta: "Post your first round", action: postFirst)
      } else {
        VStack(spacing: 0) {
          ForEach(recent) { r in
            VStack(alignment: .leading, spacing: 6) {
              HStack(spacing: 12) {
                Button { open(r) } label: {
                  HStack(spacing: 8) {
                    Text("\(r.played_on ?? "") · \((r.course_label ?? "").isEmpty ? "ROUND" : (r.course_label ?? "").uppercased())\(r.holes_played == 9 ? " · 9" : "")")
                      .font(CSFont.footnote).foregroundStyle(cs.dimText).lineLimit(1)
                    Spacer(minLength: 6)
                    if r.photo_path != nil || r.photo_url != nil {
                      Image(systemName: "photo").font(.system(size: 13)).foregroundStyle(cs.dimText).accessibilityLabel("Round photo")
                    }
                    Text("\(r.gross.map(String.init) ?? "—") · \(SliceFormat.raw(r.differential))")
                      .font(CSFont.monoMediumBody).csTabular().foregroundStyle(cs.ink)
                  }
                  .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open the round")
                Button {
                  if armed == r.id { Task { await confirmDelete(r) } } else { armed = r.id; CSHaptic.warning() }
                } label: {
                  Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(armed == r.id ? cs.neg : cs.dimText)
                    .frame(width: 36, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(deleting == r.id)
                .accessibilityLabel(armed == r.id ? "Sure? Delete this round" : "Delete round")
              }
              if armed == r.id {
                VStack(alignment: .leading, spacing: 8) {
                  Fine("Delete this round? It leaves your card and any league standings it counted toward.")
                  HStack(spacing: 8) {
                    MiniButton(label: deleting == r.id ? "Deleting…" : "Sure? Delete", tone: cs.neg, busy: deleting == r.id) { Task { await confirmDelete(r) } }
                    MiniButton(label: "Keep") { armed = nil }
                  }
                }
                .padding(.bottom, 8)
              }
            }
            .overlay(alignment: .bottom) { if r.id != recent.last?.id { Rectangle().fill(cs.line).frame(height: 1) } }
          }
        }
      }
    }
  }

  private func confirmDelete(_ r: RoundRow) async {
    deleting = r.id
    await delete(r)
    deleting = nil; armed = nil
  }
}

// MARK: - "This season · league"

struct SeasonStatsStrip: View {
  let stats: SeasonStats?
  let leagueName: String
  var body: some View {
    CSSectionHead("This season · \(leagueName)")
    VStack(spacing: 0) {
      CSRow { YouStatRow(label: "Rounds posted", value: stats?.roundsText ?? "—", sub: "This season") }
      CSRow { YouStatRow(label: "Avg vs index", value: stats?.avgText ?? "—", sub: "vs your index") }
      CSRow { YouStatRow(label: "Best round", value: stats?.bestText ?? "—", sub: "vs index · season") }
      CSRow(last: true) { YouStatRow(label: "Index move", value: stats?.deltaText ?? "—", sub: "Season to date") }
    }
  }
}

// MARK: - D4: the league record

struct LeagueRecordView: View {
  let rows: [LeagueRecordRow]
  var body: some View {
    if !rows.isEmpty {
      CSSectionHead("League record")
      VStack(spacing: 0) {
        ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
          CSRow(last: i == rows.count - 1) { YouDoorRow(glyph: Text(Image(systemName: "flag")), title: r.name, sub: r.sub) }
        }
      }
    }
  }
}
