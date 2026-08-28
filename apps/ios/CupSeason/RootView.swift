// Cup Season — one switch on AppState (IOS-002 §3). No reload-as-navigation.

import SwiftUI
import CSDesign
import CupSeasonKit

struct RootView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @State private var pendingJoin: String?
  /// A guest pencil's "keep it" tap: show the door over the pending claim.
  @State private var guestDoor = false

  var body: some View {
    ZStack {
      cs.bg0.ignoresSafeArea()
      switch store.state {
      case .restoring:
        BootingView(step: "Restoring your session")
      case .signedOut:
        if let t = ClaimIntent.pending(), !guestDoor {
          GuestPencilScreen(token: t, onDoor: { guestDoor = true })
        } else {
          DoorView()
        }
      case .cardGate(let me):
        CardGateView(me: me)
      case .ready:
        MainTabView()
          .onAppear { if let j = JoinIntent.pending() { pendingJoin = j.code; JoinIntent.clear() } }
          // a claim link that came in signed-out lands the card now (D88)
          .task(id: store.me?.profile?.id) { guestDoor = false; await LiveClaimAfterAuth.run(toast: toast) }
          .sheet(item: $pendingJoin) { code in
            JoinLeagueFlow(code: code) { id in store.preferredLeague = id; Task { await store.reload() } }
          }
      case .mustUpdate(let min):
        MustUpdateView(minBuild: min)
      case .failed(let message):
        BootFailedView(message: message)
      }
    }
    .animation(.easeOut(duration: 0.26), value: stateKey)
    #if DEBUG
    // `-cs_dev_door`: the door over the root whatever the session is, so a
    // simulator signed in to a real account can show it without signing out.
    .overlay { if DoorDev.forced { DoorView().background(cs.bg0.ignoresSafeArea()) } }
    #endif
  }

  private var stateKey: String {
    switch store.state {
    case .restoring: "restoring"
    case .signedOut: "out"
    case .cardGate: "card"
    case .ready: "ready"
    case .mustUpdate: "update"
    case .failed: "failed"
    }
  }
}

/// A named boot step, not a spinner in a void — the web's `bootStep`
/// breadcrumb as a visible state.
struct BootingView: View {
  @Environment(\.cs) private var cs
  let step: String
  var body: some View {
    VStack(spacing: 14) {
      ProgressView().tint(cs.brand)
      Text(step).csEyebrow()
    }
  }
}

struct BootFailedView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  let message: String
  var body: some View {
    VStack(spacing: 18) {
      Text("Boot stalled").csEyebrow(cs.neg)
      Text(message).font(CSFont.body).foregroundStyle(cs.ink).multilineTextAlignment(.center)
      CSButton("Try again") { Task { await store.reload() } }
      Button("Sign out") { Task { await store.signOut() } }.font(CSFont.subhead).foregroundStyle(cs.mut)
    }
    .padding(28)
  }
}

struct MustUpdateView: View {
  @Environment(\.cs) private var cs
  let minBuild: Int
  var body: some View {
    VStack(spacing: 14) {
      Text("Update Cup Season").font(CSFont.title).foregroundStyle(cs.ink)
      Text("This build is behind the season. Grab the newest one from TestFlight or the App Store, then come back.")
        .font(CSFont.body).foregroundStyle(cs.mut).multilineTextAlignment(.center)
      Text("needs build \(minBuild)").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
    }
    .padding(28)
  }
}

extension String: @retroactive Identifiable { public var id: String { self } }
