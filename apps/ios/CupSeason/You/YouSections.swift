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
      .padding(.horizontal, 14).padding(.vertical, 12).frame(minHeight: 44)
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(cs.line, lineWidth: 1))
    }
    .buttonStyle(.plain)
  }
}

// MARK: - the founder's desk (owner only; the SERVER is the gate)

struct FounderDeskCard: View {
  let openDesk: () -> Void
  let fieldNote: (() -> Void)?
  var body: some View {
    CSCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("Founder's desk").csEyebrow()
        HStack(spacing: 8) {
          if let fieldNote { MiniButton(label: "✏️ Field note", action: fieldNote) }
          MiniButton(label: "📈 Open the desk", action: openDesk)
        }
        Fine("Notes land in the feedback ledger · the desk shows signups, activity, errors, feedback.")
      }
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
    CSCard(padding: 14) {
      if let r = record {
        VStack(alignment: .leading, spacing: 0) {
          if r.items.isEmpty {
            Fine(CareerRecord.noSilverware)
          } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
              ForEach(r.items) { i in
                VStack(spacing: 4) {
                  Text(String(i.n)).font(CSFont.heroSmall).foregroundStyle(cs.gold).csTabular()   // EARNED
                  Text(i.label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.mut)
                }
                .padding(.vertical, 9).padding(.horizontal, 10).frame(maxWidth: .infinity)
                .background(cs.bg1, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(cs.line, lineWidth: 1))
                .accessibilityElement(children: .combine)
              }
            }
          }
          if let money = r.moneyLine {
            HStack(alignment: .firstTextBaseline) {
              VStack(alignment: .leading, spacing: 2) {
                Text(money.amount).font(CSFont.stat).csTabular().foregroundStyle(cs.ink)
                Text(money.sub).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(cs.mut)
              }
            }
            .padding(.top, 10).padding(.top, 2)
            .overlay(alignment: .top) { Rectangle().fill(cs.line).frame(height: 1) }
            .padding(.top, 12)
            Fine(CareerRecord.moneyNote).padding(.top, 8)
          }
        }
      } else {
        Fine(CareerRecord.emptyLine)
      }
    }
  }
}

// MARK: - the lifetime tiles

struct LifetimeTiles: View {
  let career: Career?
  var body: some View {
    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
      CSStat("Rounds posted", value: career?.roundsText ?? "—", sub: "All time")
      CSStat("Lowest differential", value: career?.bestText ?? "—", sub: "Career best")
      CSStat("Avg vs index", value: career?.avgText ?? "—", sub: "vs your index")
      CSStat("Cups & events", value: career?.playedText ?? "—", sub: "Played in")
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
    CSCard(padding: 12) {
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
    Text("This season · \(leagueName)").csEyebrow()
    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
      CSStat("Rounds posted", value: stats?.roundsText ?? "—", sub: "This season")
      CSStat("Avg vs index", value: stats?.avgText ?? "—", sub: "vs your index")
      CSStat("Best round", value: stats?.bestText ?? "—", sub: "vs index · season")
      CSStat("Index move", value: stats?.deltaText ?? "—", sub: "Season to date")
    }
  }
}

// MARK: - D4: the league record

struct LeagueRecordView: View {
  let rows: [LeagueRecordRow]
  var body: some View {
    if !rows.isEmpty {
      Text("League record").csEyebrow()
      VStack(spacing: 8) {
        ForEach(rows) { r in
          CheckRow(glyph: Text(Image(systemName: "flag")), title: r.name, sub: r.sub) { EmptyView() }
        }
      }
    }
  }
}
