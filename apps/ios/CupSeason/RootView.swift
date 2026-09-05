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
  /// D233 · the CREW STEP stands where the tabs will, once, between the card
  /// and first Home. `CrewFlag` decides on the way INTO `.ready`.
  ///
  /// D224 retires the orientation screen it replaces. That screen taught two
  /// things — the places, and the two ways to play — and the brief bans
  /// explainer slides outright. Both are taught where they are needed now: the
  /// five places ARE the tab bar, and the long game / the short game is the
  /// intent sheet's five sentences, met at the moment somebody wants to start
  /// something. What stands here instead is a QUESTION, which is the one thing
  /// the frame was always worth spending.
  @State private var crewing = false
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
        if crewing {
          CrewStep { crewing = false }
        } else {
          MainTabView()
            // IOS-033 · THE LINK SURVIVES THE BOOT. The code used to be CLEARED
            // here, on appear — before the covenant sheet had resolved — so a
            // golfer who backgrounded the app on the covenant, or whose join
            // failed, lost the code they had been sent and had no way back to
            // it. It is spent when the join is ANSWERED, and nowhere else
            // (`PendingLink.spend`).
            .onAppear { if let j = JoinIntent.pending() { pendingJoin = j.code } }
            // a claim link that came in signed-out lands the card now (D88)
            .task(id: store.me?.profile?.id) { guestDoor = false; await LiveClaimAfterAuth.run(toast: toast) }
            .sheet(item: $pendingJoin) { code in
              JoinLeagueFlow(code: code) { id in
                PendingLink.join.spend()
                store.preferredLeague = id
                Task { await store.reload() }
              }
              // A covenant declined, or the sheet swiped away, is an ANSWER
              // too: the golfer decided. What it must not do is leave the code
              // pending so the sheet rises again on the next boot.
              .onDisappear { PendingLink.join.spend() }
            }
        }
      case .mustUpdate(let min):
        MustUpdateView(minBuild: min)
      case .failed(let message):
        BootFailedView(message: message)
      }
    }
    .animation(.easeOut(duration: 0.26), value: stateKey)
    .animation(.easeOut(duration: 0.26), value: crewing)
    // D233: decided once per arrival in `.ready` — after the card, or on a
    // restored session — never on a reload while the tabs are up. The flag is
    // written on the DECISION, so a crash mid-screen never traps anyone; a
    // golfer with a league, a round or an event has a crew by evidence and
    // goes straight in, and an INVITED golfer skips it because a join's own
    // covenant is their teaching (D116, carried over from the retired screen).
    .onChange(of: stateKey, initial: true) { _, key in
      // leaving `.ready` (a sign-out) puts the screen down with it, so the
      // next golfer on this device is judged fresh rather than inheriting it
      guard key == "ready", let me = store.me else { crewing = false; return }
      #if DEBUG
      if CrewDev.forced { crewing = true; return }
      #endif
      if CrewFlag.take(me) { crewing = true }
    }
    #if DEBUG
    // `-cs_dev_door`: the door over the root whatever the session is, so a
    // simulator signed in to a real account can show it without signing out.
    .overlay { if DoorDev.forced { DoorView().background(cs.bg0.ignoresSafeArea()) } }
    // `-cs_dev_open card`: the CARD GATE over a signed-in simulator, so the one
    // frame D247 rewrote can be photographed without a fresh account. It writes
    // nothing until Save is tapped, exactly as the real gate does.
    .overlay {
      if CardGateDev.forced, let me = store.me {
        CardGateView(me: me, forceAsk: true).background(cs.bg0.ignoresSafeArea())
      }
    }
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
