// Cup Season — Start a Major (`openMajorSetup` 16021–16140, D42–D46): name
// the jug, the final day, a 2/3/4-day window, the buy-in (money is a
// choice — the split shows only when > 0), a league to run it with, staged
// golfers, "How it plays". `create_major` with the skew retry dropping
// `p_lineage`. D61: "Run it back — same jug, next year" arrives prefilled.

import SwiftUI
import CSDesign
import CupSeasonKit

/// `MJ_PREFILL` — the annual's prefill (`majorRunBack` 16173–16186).
struct MajorPrefill: Identifiable {
  let id = UUID()
  let name: String
  let days: Int
  let final: String?
  let buy: Double
  let split: String
  let league: UUID?
  let lineage: UUID
  let invitees: [Person]

  init(_ room: EventRoom, me: UUID?) {
    let s = room.sessions.first
    name = room.event.name
    days = s.map { (CSDate.days(from: $0.opens_on, to: $0.closes_on) ?? 3) + 1 } ?? 4
    final = s.flatMap { EventDates.isoPlus($0.closes_on, 364) }   // same weekday, next year
    buy = room.event.buy_in ?? 0
    split = room.event.pot_split ?? "places"
    league = room.event.league_id
    lineage = room.event.lineage_id ?? room.event.id
    invitees = room.players.compactMap { p in
      guard let pid = p.profileId, pid != me else { return nil }
      return Person(id: pid, displayName: p.name, handle: nil, marker: p.marker)
    }
  }
}

struct MajorSetupSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(SessionStore.self) private var store
  @State private var toasts = CSToastCenter()
  @State private var name = ""
  @State private var final: Date
  @State private var days = 4
  @State private var buy = "0"
  @State private var split = "places"
  @State private var league: UUID?
  @State private var staged: [Person] = []
  @State private var picking = false
  @State private var busy = false
  private let prefill: MajorPrefill?
  private let onCreated: (UUID) -> Void
  private let repo = EventsRepository()

  init(leagueId: UUID?, prefill: MajorPrefill? = nil, onCreated: @escaping (UUID) -> Void) {
    self.prefill = prefill
    self.onCreated = onCreated
    _final = State(initialValue: CSDate.local(prefill?.final ?? EventDates.nextSundayISO()) ?? Date())
    _league = State(initialValue: prefill?.league ?? leagueId)
    if let pf = prefill {
      _name = State(initialValue: pf.name)
      _days = State(initialValue: max(2, min(4, pf.days)))
      _buy = State(initialValue: pf.buy == pf.buy.rounded() ? String(Int(pf.buy)) : String(pf.buy))
      _split = State(initialValue: pf.split)
      _staged = State(initialValue: pf.invitees)
    }
  }

  private var finalISO: String { CSDate.iso(final) }
  private var buyIn: Double { Double(buy.trimmingCharacters(in: .whitespaces)) ?? 0 }
  private var memberships: [Me.Membership] { store.me?.memberships ?? [] }

  var body: some View {
    SheetFrame("Start a Major", sub: "One window · every card on one board · one name on the jug") {
      EventFieldLabel(text: "Name the jug")
      CSField("The PIGL Championship", text: $name, font: CSFont.body)
      EventFieldLabel(text: "The final day")
      DatePicker("The final day", selection: $final, displayedComponents: .date).labelsHidden().tint(cs.brand)
        .frame(maxWidth: .infinity, alignment: .leading)
      EventFieldLabel(text: "Window")
      EventSeg(options: [2, 3, 4].map { ($0, "\($0) days") }, selection: $days)
      if let when = MajorMath.whenLine(finalOn: finalISO, days: days) { CSFine(when) }
      EventFieldLabel(text: "Buy-in per player", hint: "($0 = bragging rights)")
      CSField("0", text: $buy, font: CSFont.mono).keyboardType(.numberPad)
      if buyIn > 0 {
        EventFieldLabel(text: "The pot pays")
        EventSeg(options: [("places", "Top 3 · 60/25/15"), ("wta", "Winner takes all")], selection: $split)
      }
      EventFieldLabel(text: "Run it with a league", hint: "(optional)")
      EventLeaguePicker(memberships: memberships, selection: $league)
      EventFieldLabel(text: "Add golfers")
      CSButton("Search the app or tap a buddy", style: .quiet) { picking = true }
      ForEach(staged) { p in EventStagedRow(person: p) { staged.removeAll { $0.id == p.id } } }
      EventFineCard(markdown: "**How it plays.** Everyone posts inside the window — any course, any day it's open. Your **best 18-hole card**, scored against *your own* number, is your score; post as many as the weekend allows. An established number (3 posted rounds) contends for the jug; newer golfers play **exhibition** — on the board, official by the next one. Ties settle on countback: second-best card, then earliest posted, then a logged coin flip.")
        .padding(.top, 6)
      HStack(spacing: 8) {
        CSButton("Cancel", style: .quiet) { dismiss() }.frame(maxWidth: 120)
        CSButton("Set the Major", busy: busy) { create() }
      }
      .padding(.top, 6)
      CSFine("A league Major shows on the crew's board and any member can enter. The window opens on its first morning; the jug settles the morning after the final day.")
    }
    .csToasts(toasts)
    .sheet(isPresented: $picking) {
      EventStagePicker(title: "Add golfers", sub: "They get an invite to accept once the Major is set",
                       excludeIds: [], staged: $staged)
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  private func create() {
    let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !n.isEmpty else { toasts.show("Name the jug — a Major needs a name"); return }
    busy = true
    Task {
      defer { busy = false }
      let draft = MajorDraft(name: n, finalOn: finalISO, days: days, buyIn: buyIn, potSplit: split, league: league, lineage: prefill?.lineage)
      do {
        let id = try await repo.createMajor(draft)
        await repo.invite(staged.map(\.id), to: id)
        await store.reload()
        toasts.show(staged.isEmpty ? "The Major is set — build the field" : "The Major is set — \(staged.count) invited")
        dismiss()
        onCreated(id)
      } catch {
        let raw = (error as? RpcError)?.underlying ?? String(describing: error)
        toasts.show(MajorMath.createFailure(raw))
      }
    }
  }
}
