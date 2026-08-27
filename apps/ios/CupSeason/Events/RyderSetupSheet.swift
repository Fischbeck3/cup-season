// Cup Season — Start a Ryder (`openRyderSetup` 15914–16017): name, two
// teams, sessions 3–6, cadence, the first tee (a Sunday), a league to
// attach, staged players, "How it plays". `create_event` with the web's
// own skew sequence; the staged invites fire once the event has an id.
// D62: "Run it back" arrives prefilled — benches re-invited, everything editable.

import SwiftUI
import CSDesign
import CupSeasonKit

/// `RS_PREFILL` — the rematch's prefill (`ryderRunBack` 16187–16197).
struct RyderPrefill: Identifiable {
  let id = UUID()
  let name: String
  let teamA: String?
  let teamB: String?
  let sessions: Int?
  let weeks: Int?
  let league: UUID?
  let lineage: UUID
  let invitees: [Person]

  init(_ room: EventRoom, me: UUID?) {
    name = room.event.name
    teamA = room.teams.first { $0.slot == 0 }?.name
    teamB = room.teams.first { $0.slot == 1 }?.name
    sessions = room.event.session_count
    weeks = room.event.session_weeks
    league = room.event.league_id
    lineage = room.event.lineage_id ?? room.event.id
    invitees = room.players.compactMap { p in
      guard let pid = p.profileId, pid != me else { return nil }
      return Person(id: pid, displayName: p.name, handle: nil, marker: p.marker)
    }
  }
}

struct RyderSetupSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(SessionStore.self) private var store
  @State private var toasts = CSToastCenter()
  @State private var name = ""
  @State private var teamA = ""
  @State private var teamB = ""
  @State private var sessions = 3
  @State private var weeks = 1
  @State private var start: Date
  @State private var league: UUID?
  @State private var staged: [Person] = []
  @State private var picking = false
  @State private var busy = false
  private let prefill: RyderPrefill?
  private let onCreated: (UUID) -> Void
  private let repo = EventsRepository()

  init(leagueId: UUID?, prefill: RyderPrefill? = nil, onCreated: @escaping (UUID) -> Void) {
    self.prefill = prefill
    self.onCreated = onCreated
    _start = State(initialValue: CSDate.local(EventDates.nextSundayISO()) ?? Date())
    _league = State(initialValue: prefill?.league ?? leagueId)
    if let pf = prefill {
      _name = State(initialValue: pf.name)
      _teamA = State(initialValue: pf.teamA ?? "")
      _teamB = State(initialValue: pf.teamB ?? "")
      _sessions = State(initialValue: pf.sessions.map { max(3, min(6, $0)) } ?? 3)
      _weeks = State(initialValue: pf.weeks.map { max(1, min(2, $0)) } ?? 1)
      _staged = State(initialValue: pf.invitees)
    }
  }

  private var startISO: String { CSDate.iso(start) }
  private var memberships: [Me.Membership] { store.me?.memberships ?? [] }

  var body: some View {
    SheetFrame("Start a Ryder", sub: "Two teams · vs-index duels · first to the clinch") {
      EventFieldLabel(text: "Event name")
      CSField("The Grudge Match", text: $name, font: CSFont.body)
      HStack(spacing: 10) {
        VStack(alignment: .leading, spacing: 6) {
          EventFieldLabel(text: "Team A")
          CSField("Red", text: $teamA, font: CSFont.body)
        }
        VStack(alignment: .leading, spacing: 6) {
          EventFieldLabel(text: "Team B")
          CSField("Blue", text: $teamB, font: CSFont.body)
        }
      }
      EventFieldLabel(text: "Sessions")
      EventSeg(options: [3, 4, 5, 6].map { ($0, String($0)) }, selection: $sessions)
      EventFieldLabel(text: "Cadence")
      EventSeg(options: [(1, "Weekly"), (2, "Every 2 wks")], selection: $weeks)
      EventFieldLabel(text: "First tee (a Sunday)")
      DatePicker("First tee", selection: $start, displayedComponents: .date).labelsHidden().tint(cs.brand)
        .frame(maxWidth: .infinity, alignment: .leading)
      if !EventDates.isSunday(startISO) {
        // the server raises on any other day — say so before the tap
        CSFine("The Ryder starts on a Sunday — sessions run Sun to Sat", tone: cs.warm)
      }
      EventFieldLabel(text: "Attach to a league", hint: "(optional)")
      EventLeaguePicker(memberships: memberships, selection: $league)
      EventFieldLabel(text: "Add players")
      CSButton("Search the app or tap a buddy", style: .quiet) { picking = true }
      ForEach(staged) { p in EventStagedRow(person: p) { staged.removeAll { $0.id == p.id } } }
      EventFineCard(markdown: "**How it plays.** Two teams, one **session** a week. Each session you're paired 1‑on‑1 with someone on the other team; your best round that week — scored by how far you beat *your own* index — faces theirs. **Win a duel = 1 point, tie = ½ each.** First team past half the points takes the cup. Points scale to team size: 6‑a‑side over 3 weeks is 18 points, first to 9½.")
        .padding(.top, 6)
      HStack(spacing: 8) {
        CSButton("Cancel", style: .quiet) { dismiss() }.frame(maxWidth: 120)
        CSButton("Create the event", busy: busy) { create() }
      }
      .padding(.top, 6)
      CSFine("You captain Team A. Invited players get a notification to accept; you draw or assign teams from the scoreboard once they're in.")
    }
    .csToasts(toasts)
    .sheet(isPresented: $picking) {
      EventStagePicker(title: "Add players", sub: "They get an invite to accept once the event is created",
                       excludeIds: [], staged: $staged)
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  private func create() {
    let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !n.isEmpty else { toasts.show("Name the event"); return }
    busy = true
    Task {
      defer { busy = false }
      let draft = RyderDraft(name: n,
                             teamA: teamA.trimmingCharacters(in: .whitespaces).isEmpty ? "Red" : teamA.trimmingCharacters(in: .whitespaces),
                             teamB: teamB.trimmingCharacters(in: .whitespaces).isEmpty ? "Blue" : teamB.trimmingCharacters(in: .whitespaces),
                             sessions: sessions, weeks: weeks, startsOn: startISO, league: league, lineage: prefill?.lineage)
      do {
        let id = try await repo.createRyder(draft)
        // the event now has an id — fire the staged invites (organizer-gated RPC)
        await repo.invite(staged.map(\.id), to: id)
        await store.reload()
        toasts.show(staged.isEmpty ? "Event created — add your players" : "Event created — \(staged.count) invited")
        dismiss()
        onCreated(id)
      } catch {
        // the one server rule worth surfacing verbatim: the Sunday tee
        let raw = (error as? RpcError)?.underlying ?? ""
        toasts.show(raw.contains("Sunday") ? raw : BoardText.humanError(error, "Could not create the event."))
      }
    }
  }
}
