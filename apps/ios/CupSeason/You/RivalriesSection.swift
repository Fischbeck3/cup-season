// Cup Season — rivalries (index.html `renderRivalries` 13215–13242,
// `openRivalrySheet` 13244–13264, `openNameRivalry` 13268–13290).

import SwiftUI
import CSDesign
import CupSeasonKit

/// "Rivalries · your record" — hidden entirely when there are none.
struct RivalriesSection: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let rivalries: [RivalryLine]
  let openTourCard: (UUID) -> Void

  var body: some View {
    if !rivalries.isEmpty {
      CSSectionHead("Rivalries · your record")
      VStack(spacing: 0) {
        ForEach(Array(rivalries.enumerated()), id: \.element.id) { i, r in
          CSRow(last: i == rivalries.count - 1) {
            Button { openTourCard(r.opponent) } label: {
              A11yStack(spacing: 12, columnSpacing: 4) {
                HStack(spacing: 12) {
                  CSMarkerView(key: r.marker, size: 22).foregroundStyle(cs.ink).frame(width: 28).accessibilityHidden(true)
                  VStack(alignment: .leading, spacing: 2) {
                    if let named = r.rivalryName {
                      Text(named).csEyebrow(cs.gold)   // M3: a christened rivalry wears its name in gold
                    }
                    Text(r.name).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
                    if !r.facets.isEmpty { Text(r.facets).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText) }
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(r.record).font(CSFont.monoMediumBody).csTabular().foregroundStyle(recordColor(r.lead))
                  .padding(.leading, typeSize.isA11y ? 40 : 0)
              }
              .frame(minHeight: 44)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the Tour Card")
          }
        }
      }
    }
  }

  /// `.rivrec.up` pos · `.dn` dim · `.ev` mut
  private func recordColor(_ lead: RivalryLead) -> Color {
    switch lead { case .up: cs.pos; case .down: cs.dimText; case .even: cs.mut }
  }
}

/// "You vs NAME" — the receipts behind the record (§16).
struct RivalrySheet: View {
  @Environment(\.cs) private var cs
  let opponentId: UUID
  var name: String = "them"
  var record: String? = nil
  var rivalryName: String? = nil

  @State private var weeks: [RivalryWeek]?
  @State private var currentName: String?
  @State private var naming = false
  private let repo = TourCardRepository()

  init(opponentId: UUID, name: String = "them", record: String? = nil, rivalryName: String? = nil) {
    self.opponentId = opponentId; self.name = name; self.record = record; self.rivalryName = rivalryName
    _currentName = State(initialValue: (rivalryName ?? "").isEmpty ? nil : rivalryName)
  }

  var body: some View {
    SliceSheet(title: "You vs \(name)", sub: [record, RivalryCopy.sheetSub].compactMap { $0 }.joined(separator: " · ")) {
      if let cur = currentName {
        Text("“\(cur.uppercased())”").csEyebrow(cs.gold).padding(.bottom, 4)
      }
      if let weeks {
        if weeks.isEmpty {
          Fine(RivalryCopy.noWeeks)
        } else {
          ForEach(weeks) { w in weekRow(w) }
        }
      } else {
        Fine("Pulling the weeks…")
      }
      CSButton(currentName.map { "Rename “\($0)”" } ?? "Name this rivalry", style: .quiet) { naming = true }
        .padding(.top, 12)
    }
    .task { await load() }
    .sheet(isPresented: $naming, onDismiss: { Task { await refreshName() } }) {
      NameRivalrySheet(opponentId: opponentId, opponentName: name, current: currentName)
    }
  }

  private func weekRow(_ w: RivalryWeek) -> some View {
    HStack(spacing: 12) {
      Text(w.wkLabel).font(CSFont.label).multilineTextAlignment(.center).foregroundStyle(cs.mut)
        .frame(minWidth: 44, minHeight: 34)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(cs.line2, lineWidth: 1))
      VStack(alignment: .leading, spacing: 2) {
        (Text(w.verdictText).foregroundStyle(verdictColor(w.verdict)) + Text(" · " + w.headline).foregroundStyle(cs.ink))
          .font(CSFont.subhead.weight(.semibold))
        Text(RivalryCopy.weekSub).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 14).padding(.vertical, 12)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.line, lineWidth: 1))
    .accessibilityElement(children: .combine)
  }

  private func verdictColor(_ v: RivalryWeek.Verdict) -> Color {
    switch v { case .won: cs.pos; case .lost: cs.dimText; case .halved: cs.mut }
  }

  private func load() async {
    let rows = (try? await repo.rivalryWeeks(opponentId)) ?? []
    weeks = rows.compactMap { RivalryWeek.from($0, opponentName: name) }
  }

  /// The christened name lives on `my_rivalries` — re-read after the naming sheet.
  private func refreshName() async {
    guard let rows = try? await SupabaseService.shared.call(Rpc.my_rivalries()) else { return }
    let n = rows.first { $0.opponent == opponentId }?.rivalry_name ?? ""
    currentName = n.isEmpty ? nil : n
  }
}

/// M3/D18: the naming sheet. Naming requires real history (enforced
/// server-side); either rival can rename or clear — that's the misuse valve.
struct NameRivalrySheet: View {
  @Environment(\.dismiss) private var dismiss
  let opponentId: UUID
  let opponentName: String
  let current: String?
  @State private var text: String
  @State private var busy = false
  private let repo = TourCardRepository()

  init(opponentId: UUID, opponentName: String, current: String?) {
    self.opponentId = opponentId; self.opponentName = opponentName; self.current = current
    _text = State(initialValue: current ?? "")
  }

  var body: some View {
    SliceSheet(title: current != nil ? "Rename the rivalry" : "Name the rivalry", sub: "YOU VS \(opponentName.uppercased())") {
      Fine(RivalryCopy.nameHelp)
      CSField(RivalryCopy.namePlaceholder, text: $text, font: CSFont.body)
        .onChange(of: text) { _, v in if v.count > 40 { text = String(v.prefix(40)) } }
      CSButton(current != nil ? "Save the name" : "Name it", busy: busy) { Task { await save(clear: false) } }
        .padding(.top, 12)
      if current != nil {
        CSButton("Clear the name", style: .quiet, busy: busy) { Task { await save(clear: true) } }.padding(.top, 8)
      }
    }
    .presentationDetents([.medium, .large])
  }

  private func save(clear: Bool) async {
    let val = clear ? "" : text.trimmingCharacters(in: .whitespacesAndNewlines)
    busy = true
    do {
      try await repo.setRivalryName(opponentId, name: val)
      ToastCenter.shared.show(clear ? "Name cleared" : "Rivalry named — “\(val)”")
      dismiss()
    } catch {
      busy = false
      ToastCenter.shared.show(SliceFormat.human(error, "Could not save."))
    }
  }
}
