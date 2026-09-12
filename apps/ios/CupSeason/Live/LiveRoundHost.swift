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
        // D173 · the live sheet needs a way out too, and for the same reason
        // the setup sheet did (D110 addendum, below): this is a full-screen
        // cover, and a cover with no toolbar is a room with no door. The owner
        // hit it the moment D163 started pulling an INVITED golfer straight
        // into a round — they were dropped here and could not reach the rest of
        // the app. `LivePlayView` even sets .navigationTitle("Live round"),
        // which did nothing, because nothing wrapped it in a NavigationStack.
        //
        // Close DISMISSES, it does not leave the round: the round keeps running
        // on the server and on the wire, and LiveNowBar (D163) sits above every
        // tab offering the way back. Scrap and Finish remain the only ways to
        // actually end it.
        NavigationStack {
          LivePlayView(store: store, links: links)
            // §5.1 · **the one dismiss verb, at `topBarTrailing`, as a
            // TOOLBAR tertiary** — `ink` label, 1px `mut` rule, never ember.
            // A dismiss verb is neither live nor primary, and the loudest
            // control on the live sheet is never the one that closes it.
            .toolbar {
              ToolbarItem(placement: .topBarTrailing) {
                Button("Close") {
                  store.flushLocalCard()
                  if store.localSaveError == nil { links.done() }
                }
                  .buttonStyle(.csTertiary(.toolbar))
                  .accessibilityHint("Leaves this screen — the round keeps going, and the bar at the top brings you back")
              }
            }
        }
      } else {
        // D110 addendum: setup had NO exit — a full-screen cover with no toolbar
        // (the owner got stuck; only the app switcher freed them). Close leaves
        // nothing behind: before tee-off there is no server round to abandon.
        NavigationStack {
          LiveSetupView(store: store)
            .csCloseButton { links.done() }
        }
      }
    }
    .background(cs.bg0)
    // D152 · the ONE screen allowed to rotate. Everything else answers portrait,
    // so no other view had to be audited for a rotation it never performs.
    .csAllowsLandscape()
    .task {
      store.toasts = toast
      await store.configure(me: session.me, preferredLeague: session.preferredLeague)
      // The round sheet is the only place a queue can be held, so the monitor
      // lives exactly as long as the sheet does.
      store.watchReachability()
    }
    .onDisappear { store.flushLocalCard(); store.stopWatchingReachability() }
    .onChange(of: phase) { _, p in if p == .active { store.foregrounded() } else { store.flushLocalCard() } }
    .onChange(of: store.leaveRequested) { _, v in if v { store.leaveRequested = false; links.done() } }
    .sheet(item: Binding(get: { store.recap }, set: { store.recap = $0 })) { r in
      LiveRecapSheet(data: r, store: store)
    }
  }
}

// MARK: - the Home banner (7710–7735)

/// Two faces: "Continue your round" or, for someone else's round, the
/// invitation ("X started a live round with you · JUST TEED OFF … · JOIN").
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
        // D266 · the resume banner was a `CSCard(spine:)` — a bordered box with
        // a 3.5pt coloured edge, which is the grammar the audit measured as
        // meaning "a box" rather than meaning anything. It is a BAND now: a 2pt
        // rule whose metal IS the state (ember while a round is open, ink
        // otherwise), the eyebrow with its own live dot, the line, the meta.
        // Same three facts, same target, no container.
        Button(action: open) {
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            CSRule(.heavy, metal: b.invite ? .live : .ink)
            HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
              VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
                HStack(spacing: CSTokens.Space.s2) {
                  if b.invite {
                    Circle().fill(cs.brand).frame(width: 7, height: 7)
                  }
                  Text(b.kicker).csType(.agate, caps: true)
                    .foregroundStyle(b.invite ? cs.brand : cs.mut)
                }
                Text(b.line).csType(.name).foregroundStyle(cs.ink)
                  .fixedSize(horizontal: false, vertical: true)
                Text(b.meta).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              }
              Spacer(minLength: CSTokens.Space.s3)
              Text(b.go).csType(.body).foregroundStyle(b.invite ? cs.brand : cs.ink)
            }
          }
          .frame(minHeight: 52)
          .contentShape(Rectangle())
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
  /// "Keep this round" → the root's door
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
        Text(line).csType(.story).foregroundStyle(cs.ink)
        Button("Keep this round") { onDoor() }
          .buttonStyle(.csPrimary())
      case .claimed:
        Text("That card is already on a record.").csType(.story).foregroundStyle(cs.ink)
        Button("Sign in") { onDoor() }
          .buttonStyle(.csSecondary())
      case .dead(let line):
        Text(line).csType(.body).foregroundStyle(cs.neg)
        Button("Sign in") { onDoor() }
          .buttonStyle(.csSecondary())
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

// MARK: - D175 · the doorbell follows the app

/// The nearby invitation, presentable from anywhere.
///
/// D168 and D170 moved the RADIO to the app — advertising starts from the tab
/// shell the moment the session loads, and the device console confirms it
/// (`startNearby OK — advertising`, before any screen is opened). But the
/// ALERT — the thing the golfer actually has to tap — stayed pinned to
/// `LiveSetupView`. So a phone was discoverable everywhere and answerable in
/// exactly one place, which is why the owner kept reporting the same sentence
/// after three "fixes": *"it still sits at asking unless I am in the post round
/// section."* The radio followed the app; the door didn't.
///
/// Two hosts, because an alert cannot present from a view that a full-screen
/// cover is sitting on top of: the tab shell carries it while the cover is
/// down, and the setup sheet carries it while the cover is up.
///
/// The binding's setter is deliberately EMPTY. The obvious `set: { if !$0 {
/// answerIncoming(false) } }` turns any programmatic dismissal — the cover
/// going up underneath it, for one — into a silent decline of a round the
/// golfer never saw. Both buttons clear `incoming` themselves, and an alert
/// cannot be swiped away, so nothing is lost.
extension View {
  func csNearbyInvite(_ store: LiveRoundStore, enabled: Bool = true) -> some View {
    alert("Join this round?", isPresented: Binding(get: { enabled && store.incoming != nil },
                                                   set: { _ in })) {
      // D158 · "Not me" is not a decline of the golf — it is the honest answer
      // when the name on the other phone is not actually you.
      Button("Join") { store.answerIncoming(true) }
      Button("Not me", role: .cancel) { store.answerIncoming(false) }
    } message: {
      if let inv = store.incoming {
        Text("\(inv.name) wants you in a round at \(inv.course)\(inv.game.isEmpty ? "" : " · \(inv.game)").")
      }
    }
  }
}
