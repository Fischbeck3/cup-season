// Cup Season — the league-less doors (`renderHomeStart`, index.html 9736–9773)
// and the D41 run-it-back card (9739–9752, `runItBack` 14177–14184).
//
// D225 · THE THREE OBJECT DOORS ARE GONE. "Join a league · Start a league ·
// Start an event" made a golfer choose which object expressed what they wanted
// before they had said what they wanted. There is ONE door now — **Start
// something** — and it opens the intent sheet, whose five sentences name no
// object at all. "I have a code" stays as its own quiet door, because a golfer
// holding a code is not choosing anything.
//
// When a season has wrapped the run-back card sits ahead of them. "Run it back"
// is the wizard with last season's bylaws carried in and a "· S2" name.

import SwiftUI
import CSDesign
import CupSeasonKit

struct LeaguelessDoors: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.presenter) private var presenter
  @Environment(\.cs) private var cs
  let links: WizardLinks
  @State private var wizard = false
  @State private var join = false

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let done = store.me?.memberships.first(where: { $0.phase == "complete" }) {
        RunItBackCard(leagueId: done.league_id, links: links)
      }
      // Two doors: the intent sheet, and the one a golfer holding a code needs.
      A11yStack(spacing: 8) {
        door("Start something") { presenter.showIntent = true }
        door(StartIntent.codeDoor) { join = true }
      }
      if store.me?.memberships.isEmpty ?? true { CSFine(WizardCopy.leaguelessLine) }
    }
    .fullScreenCover(isPresented: $wizard) {
      NavigationStack {
        WizardScreen(existingLeagueId: nil, links: WizardLinks(
          onLocked: { id in wizard = false; links.onLocked(id) },
          onCancelled: { wizard = false; links.onCancelled() },
          startEvent: links.startEvent, onJoined: links.onJoined))
      }
    }
    .sheet(isPresented: $join) {
      JoinLeagueFlow(code: nil) { id in join = false; links.onJoined(id) }
    }
  }

  /// `.startjoin` — a quiet door, 44pt, the label wrapping.
  private func door(_ label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      // one line on every phone: the text column is ~103pt across three doors
      // and "Start a league" needs ~118pt at full size, so 1/2/2 lines made the
      // trio look ragged. The 0.7 floor covers the SE and the non-a11y xxxLarge
      // sizes; at the accessibility sizes A11yStack is a column and nothing scales.
      Text(label).csType(.nameS).multilineTextAlignment(.center)
        .lineLimit(1).minimumScaleFactor(0.8)   // L-29 · 14 × 0.8 = 11.2, the floor
        .foregroundStyle(cs.ink)
        .padding(.horizontal, 6).frame(maxWidth: .infinity, minHeight: 50)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

/// `.runback` — D243 · RUN IT BACK CARRIES THE ROSTER, and the card has two
/// seats.
///
/// It used to open the WIZARD with last season's bylaws carried in and a "· S2"
/// name, which mints a NEW league and a NEW code — so every member re-types one
/// to play the season they already agreed to. And it was drawn for EVERY
/// member, so a member who tapped it was silently made the founder of a
/// different league with the same name. A persona walk backed out of exactly
/// that.
///
/// Now: the Pro runs it back (R10 mints season 2 under the SAME league, and
/// nobody re-types anything); a member ASKS, once, and the ask is one line on
/// the board — not a `push_nudges` row, because D248's own clause says the
/// run-back ask ships with a recipient's Home item or it does not ship, and
/// that item is not built.
struct RunItBackCard: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  let leagueId: UUID
  let links: WizardLinks
  @State private var busy = false
  @State private var asked = false
  @State private var reviewing = false

  private var membership: Me.Membership? { store.me?.memberships.first { $0.league_id == leagueId } }
  private var isPro: Bool { RunItBack.isPro(role: membership?.role) }

  var body: some View {
    let m = membership
    CSBand(.tone, padding: CSTokens.Space.s3) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 12) {
          // D277 · one icon family, and gold is not a decoration. An SF Symbol
          // trophy in the earned metal, decorating a door nobody has won
          // anything through, is both halves of the rule at once.
          CSTrophyMark("cup", size: 26).frame(width: 34).accessibilityHidden(true)
          VStack(alignment: .leading, spacing: 2) {
            Text(RunItBack.eyebrow).csEyebrow()
            Text(m?.name ?? "Your league").csType(.name).foregroundStyle(cs.ink)
          }
        }
        .accessibilityElement(children: .combine)
        // LV-21 · L-25: gold on a button is a defect. Ember is the act metal.
        Button(RunItBack.title(isPro: isPro, proFirstName: proFirstName)) {
          if isPro { reviewing = true } else { Task { await askThem() } }
        }
          .buttonStyle(.csPrimary(busy: busy))
        .disabled(busy || (asked && !isPro))
        CSFine(RunItBack.sub(isPro: isPro))
      }
    }
    .confirmationDialog("Run it back?", isPresented: $reviewing, titleVisibility: .visible) {
      Button("Run it back") { Task { await runIt() } }
      Button("Close", role: .cancel) {}
    } message: {
      Text("Start the next season of \(membership?.name ?? "your league") with the existing crew and rules. If a season is already open, you’ll return to it.")
    }
    .onAppear { asked = UserDefaults.standard.bool(forKey: RunItBack.askKey(league: leagueId)) }
  }

  /// The Pro's name comes from the payload's own roster when it carries one;
  /// the producer says "the Pro" when it does not, and never invents a name.
  private var proFirstName: String? {
    guard let n = membership?.commissioner_name, !n.isEmpty else { return nil }
    return n.split(separator: " ").first.map(String.init)
  }

  private func runIt() async {
    guard !busy else { return }
    busy = true
    defer { busy = false }
    switch await RunItBackService().run(leagueId) {
    case .ran(let r):
      toast.show(r.line)
      store.preferredLeague = leagueId
      await store.reload()
      links.onLocked(leagueId)
    case .notYet:
      toast.show(RunItBack.notYetLine)
    case .refused(let msg):
      toast.show(msg)
    }
  }

  private func askThem() async {
    guard !busy, !asked else { return }
    guard let member = membership?.member_id else { toast.show(RunItBack.noSeatLine); return }
    busy = true
    defer { busy = false }
    let first = store.me?.profile?.display_name?.split(separator: " ").first.map(String.init)
    let line = await RunItBackService().ask(league: leagueId, season: nil, member: member, myFirstName: first)
    asked = UserDefaults.standard.bool(forKey: RunItBack.askKey(league: leagueId))
    toast.show(line)
  }
}
