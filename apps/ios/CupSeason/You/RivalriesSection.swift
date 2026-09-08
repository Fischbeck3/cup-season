// Cup Season — rivalries (index.html `renderRivalries` 13215–13242,
// `openRivalrySheet` 13244–13264, `openNameRivalry` 13268–13290).

import SwiftUI
import CSDesign
import CupSeasonKit

/// **§4 · rivals, as slats.** Hidden entirely when there are none.
///
/// `RIVALS` was three rows of avatar + record + meeting count + league — "a
/// table pretending to be a list" (blind-2) — with the record in `pos` when
/// you led and the `dim` tier when you did not. **A losing record is now set
/// in the same ink as a winning one** (DD-17): greying out your losses makes
/// colour the only channel, and the verdict is a WORD, which is a second one
/// (§16.4).
///
/// The `→` is gone with every other typed arrow: a row whose whole surface is
/// the target carries no chevron (§D-8, LINT-13).
struct RivalriesSection: View {
  let rivalries: [RivalryLine]
  let openTourCard: (UUID) -> Void
  /// D232 · the record calls this section "Head to head" (each row opens one);
  /// Golfers keeps the scope-naming head below, because there the question is
  /// who you are up against rather than what you have done.
  var head: String? = nil

  var body: some View {
    if !rivalries.isEmpty {
      // D177 · say the scope. `my_rivalries()` takes no league argument — this
      // is your lifetime clash record against everyone you have played, in
      // every league. §16A.2: the count goes in the slot, once.
      ProfileHead(head ?? "Rivals", count: CSCopy.spelled(rivalries.count))
      VStack(spacing: 0) {
        ForEach(rivalries) { r in
          RivalSlat(face: CSFace.Model(id: r.opponent, marker: r.marker, initials: Initials.of(r.name)),
                    name: r.name, sub: r.facets, record: r.record,
                    verdict: RivalryCopy.leadLabel(r.lead, them: r.name),
                    rivalryName: r.rivalryName,
                    open: { openTourCard(r.opponent) })
        }
      }
      .padding(.horizontal, -CSTokens.Space.gutter)
      .padding(.top, CSTokens.Space.s3)
    }
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
    SliceSheet(title: "You and \(name)", sub: [record, RivalryCopy.sheetSub].compactMap { $0 }.joined(separator: " · ")) {
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
      Button(currentName.map { "Rename “\($0)”" } ?? "Name this rivalry") { naming = true }
        .buttonStyle(.csSecondary())
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
      VStack(alignment: .leading, spacing: 2) {
        (Text(w.verdictText).foregroundStyle(verdictColor(w.verdict)) + Text(" · " + w.headline).foregroundStyle(cs.ink))
          .csType(.name)
        Text(RivalryCopy.weekSub).csType(.agateS).foregroundStyle(cs.mut)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 14).padding(.vertical, 12)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .accessibilityElement(children: .combine)
  }

  private func verdictColor(_ v: RivalryWeek.Verdict) -> Color {
    switch v { case .won: cs.pos; case .lost: cs.mut; case .halved: cs.mut }
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
    SliceSheet(title: current != nil ? "Rename the rivalry" : "Name the rivalry", sub: "YOU AND \(opponentName.uppercased())") {
      Fine(RivalryCopy.nameHelp)
      CSField(RivalryCopy.namePlaceholder, text: $text, font: CSFont.body)
        .onChange(of: text) { _, v in if v.count > 40 { text = String(v.prefix(40)) } }
      Button(current != nil ? "Save the name" : "Name it") { Task { await save(clear: false) } }
        .buttonStyle(.csPrimary(busy: busy))
        .padding(.top, 12)
      if current != nil {
        Button("Clear the name") { Task { await save(clear: true) } }
          .buttonStyle(.csSecondary(busy: busy)).padding(.top, 8)
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
