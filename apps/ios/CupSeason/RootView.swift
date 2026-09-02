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
  /// D82: the orientation stands where the tabs will, once, between the card
  /// and first Home. `OrientedFlag` decides on the way INTO `.ready`.
  @State private var orienting = false
  #if DEBUG
  /// `-cs_dev_live`'s way out — see the overlay below.
  @State private var devLive = true
  #endif

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
        if orienting {
          // the web's `showOrientation` (index.html 14779): the one screen,
          // then `continueAfterCard()` — a pending join or claim resumes below
          OrientationScreen { orienting = false }
        } else {
          MainTabView()
            .onAppear { if let j = JoinIntent.pending() { pendingJoin = j.code; JoinIntent.clear() } }
            // a claim link that came in signed-out lands the card now (D88)
            .task(id: store.me?.profile?.id) { guestDoor = false; await LiveClaimAfterAuth.run(toast: toast) }
            .sheet(item: $pendingJoin) { code in
              JoinLeagueFlow(code: code) { id in store.preferredLeague = id; Task { await store.reload() } }
            }
        }
      case .mustUpdate(let min):
        MustUpdateView(minBuild: min)
      case .failed(let message):
        BootFailedView(message: message)
      }
    }
    .animation(.easeOut(duration: 0.26), value: stateKey)
    .animation(.easeOut(duration: 0.26), value: orienting)
    // D82: decided once per arrival in `.ready` — after the card, or on a
    // restored session — never on a reload while the tabs are up. The flag is
    // written on show; a golfer with a league, a round or an event is oriented
    // by evidence and goes straight in.
    .onChange(of: stateKey, initial: true) { _, key in
      // leaving `.ready` (a sign-out) puts the screen down with it, so the
      // next golfer on this device is judged fresh rather than inheriting it
      guard key == "ready", let me = store.me else { orienting = false; return }
      #if DEBUG
      if OrientationDev.forced { orienting = true; return }
      #endif
      if OrientedFlag.take(me) { orienting = true }
    }
    #if DEBUG
    // `-cs_dev_door`: the door over the root whatever the session is, so a
    // simulator signed in to a real account can show it without signing out.
    .overlay { if DoorDev.forced { DoorView().background(cs.bg0.ignoresSafeArea()) } }
    // `-cs_dev_live`: the tee sheet over the root whatever the session is, the
    // same trick for the same reason — the live round (and D152's landscape
    // card) can be reviewed without an account, a league and a played round.
    // LiveRoundStore seeds itself from the same flag and never touches the
    // server, so nothing here can create or mutate a real round.
    //
    // `done` MUST dismiss, exactly as MainTabView's real `liveLinks` does. It
    // was `LiveLinks()` — whose `done` is an empty closure — and that made the
    // hatch a room with no door: scrapping the round calls done(), nothing
    // happened, the host fell through to LiveSetupView, and setup's own Close
    // calls the same dead closure. Only the app switcher freed you. A review
    // hatch that cannot exercise the exit is a hatch that hides exit bugs.
    // `-cs_dev_bar`: the D163 top bar over the door, so it can be reviewed on a
    // signed-out simulator (it normally lives above MainTabView's tabs, which
    // only exist for a signed-in session).
    .task {
      if ProcessInfo.processInfo.arguments.contains("-cs_dev_bar") {
        await LiveRoundStore.shared.configure(me: nil, preferredLeague: nil)
      }
    }
    .overlay(alignment: .top) {
      if ProcessInfo.processInfo.arguments.contains("-cs_dev_bar") {
        LiveNowBar(presented: false) {}
          .padding(.top, 60)
      }
    }
    // `-cs_dev_cred <photo|crest|hero|herocrest>`: the credential itself, over
    // the root — see CredentialDev.swift.
    .overlay { if let m = CredDev.mode { CredDevView(mode: m) } }
    .overlay {
      if (CSDevHatch.live || CSDevHatch.nearby) && devLive {
        LiveRoundHost(links: LiveLinks(done: { devLive = false }))
          .background(cs.bg0.ignoresSafeArea())
      }
    }
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
