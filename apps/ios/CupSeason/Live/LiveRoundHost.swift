// Cup Season — the tee sheet's doors: the host that routes setup ↔ live ↔
// recap, the Home banner (`renderResumeBanner` 7710, D86), and the guest
// pencil (`enterGuestLive` 7881 / the claim door 17700, D85–D88).

import SwiftUI
import CSDesign
import CupSeasonKit

/// Where the tee sheet hands off. The host wires these.
struct LiveLinks {
  var openReceipt: (UUID) -> Void = { _ in }
  var openTourCard: (UUID) -> Void = { _ in }
  var done: () -> Void = {}
}

/// `#view-play`: setup, the live sheet, and the recap after a finish.
struct LiveRoundHost: View {
  @Environment(SessionStore.self) private var session
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(\.scenePhase) private var phase
  let links: LiveLinks
  @State private var store = LiveRoundStore.shared

  var body: some View {
    Group {
      if store.state.stage == .live, store.state.active {
        LivePlayView(store: store, links: links)
      } else {
        LiveSetupView(store: store)
      }
    }
    .background(cs.bg0)
    .task {
      store.toasts = toast
      await store.configure(me: session.me, preferredLeague: session.preferredLeague)
    }
    .onChange(of: phase) { _, p in if p == .active { store.foregrounded() } }
    .onChange(of: store.leaveRequested) { _, v in if v { store.leaveRequested = false; links.done() } }
    .sheet(item: Binding(get: { store.recap }, set: { store.recap = $0 })) { r in
      LiveRecapSheet(data: r, store: store)
    }
  }
}

// MARK: - the Home banner (7710–7735)

/// Two faces: "Continue your round" or, for someone else's round, the
/// invitation ("X put you on the tee sheet · JUST TEED OFF … · JOIN").
struct LiveResumeBanner: View {
  @Environment(SessionStore.self) private var session
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  let links: LiveLinks
  /// where the banner opens the sheet
  var open: () -> Void = {}
  @State private var store = LiveRoundStore.shared

  var body: some View {
    Group {
      if let b = LiveCopy.resumeBanner(store.state), store.guest == nil {
        Button(action: open) {
          CSCard(spine: b.invite ? cs.brand : cs.pos) {
            HStack(alignment: .center, spacing: 12) {
              VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                  Circle().fill(b.invite ? cs.brand : cs.pos).frame(width: 8, height: 8)
                  Text(b.kicker).csEyebrow(b.invite ? cs.brand : cs.pos)
                }
                Text(b.line).font(CSFont.sentenceBold).foregroundStyle(cs.ink)
                Text(b.meta).font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText)
              }
              Spacer()
              Text(b.go).font(b.invite ? CSFont.monoMediumBody : CSFont.title).foregroundStyle(b.invite ? cs.brand : cs.ink)
            }
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(b.kicker). \(b.line). \(b.meta)")
      }
    }
    .task {
      store.toasts = toast
      await store.configure(me: session.me, preferredLeague: session.preferredLeague)
    }
  }
}

// MARK: - the guest pencil (7881–7941; the door 17700–17727)

/// A claim link opened on a phone with no session: a live round is a PENCIL
/// (token is identity — no account, no name pick); a finished one is the
/// door card. The same link claims the card after the finish.
struct GuestPencilScreen: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(\.scenePhase) private var phase
  let token: UUID
  /// "Enter your email to keep it" → the root's door
  var onDoor: () -> Void = {}
  @State private var store = LiveRoundStore.shared
  @State private var face: Face = .loading

  enum Face { case loading, pencil, door(ClaimDoor) }

  var body: some View {
    Group {
      switch face {
      case .loading:
        BootingView(step: "Finding your card")
      case .pencil:
        if store.state.active, store.guest?.token == token {
          NavigationStack { LivePlayView(store: store, links: LiveLinks()) }
        } else {
          BootingView(step: "Finding your card")
        }
      case .door(let d):
        door(d)
      }
    }
    .background(cs.bg0)
    .task(id: token) { await enter() }
    .onChange(of: phase) { _, p in if p == .active { store.foregrounded() } }
    .onChange(of: store.guestEnded) { _, ended in
      // the guest's link now points at a finished round — land on the claim door
      if ended != nil { Task { await loadDoor() } }
    }
  }

  private func enter() async {
    store.toasts = toast
    ClaimIntent.store(token.uuidString)
    if let d = try? await store.repo.guestState(token), d["round"]?["status"]?.string == "live",
       store.enterGuest(d, token: token, signedIn: false) {
      face = .pencil
      return
    }
    await loadDoor()
  }

  private func loadDoor() async {
    face = .door(await ClaimDoor.load(token: token))
  }

  private func door(_ d: ClaimDoor) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Spacer()
      Text("Your scorecard").csEyebrow(cs.brand)
      switch d.face {
      case .waiting(let line):
        Text(line).font(CSFont.sentence).foregroundStyle(cs.ink)
        CSButton("Enter your email to keep it") { onDoor() }
      case .claimed:
        Text("That card is already on a record.").font(CSFont.sentence).foregroundStyle(cs.ink)
        CSButton("Sign in", style: .quiet) { onDoor() }
      case .dead(let line):
        Text(line).font(CSFont.subhead).foregroundStyle(cs.neg)
        CSButton("Sign in", style: .quiet) { onDoor() }
      }
      Spacer()
    }
    .padding(28)
  }
}

// MARK: - the claim after auth (17588)

/// `claimPendingRound`: the root calls this after the card gate.
enum LiveClaimAfterAuth {
  @MainActor
  static func run(toast: CSToastCenter) async {
    let pencil = LiveRoundStore.shared.guest?.token
    if let t = await ClaimFlow.consume(livePencilToken: pencil).toast { toast.show(t) }
  }
}
