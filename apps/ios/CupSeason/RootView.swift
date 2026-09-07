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
            .csSheet(item: $pendingJoin) { code in
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
    .csAnimation(CSMotion.rise, value: stateKey)
    .csAnimation(CSMotion.rise, value: crewing)
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
    // `-cs_dev_developer`: every component in the system, in every state it
    // declares, over the root — see Dev/DeveloperHarness.swift. It is the
    // component wave's only acceptance evidence and every later wave's
    // regression check.
    .overlay { if DeveloperHarness.on { DeveloperHarnessView() } }
    // `-cs_dev_compete_fixture`: the COMPETE tab over the root, on a named
    // payload — the same trick, for the same reason (D286). Compete lives
    // behind the tab bar and the tab bar lives behind a session; this wave
    // opened with the simulator's refresh token expired, and a screen that
    // cannot be photographed is a screen nobody looked at. It reads a fixture
    // and never the server, so nothing here can touch anybody's real season.
    .overlay {
      if CompeteFixture.on {
        NavigationStack { CompeteScreen(links: CSLinks()) }
          .background(cs.bg0.ignoresSafeArea())
      }
    }
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
    // §6.1 · loading is the destination's own geometry, never a spinner
    // (`LINT-22`). At BOOT there is no destination yet — so the geometry is the
    // one thing every screen behind this shares: the masthead, held. The named
    // step keeps the web's `bootStep` breadcrumb visible under it.
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      Text("Cup Season").csType(.display).foregroundStyle(cs.ink)
      CSRule(.heavy)
      Text(step).csType(.agate, caps: true).foregroundStyle(cs.mut)
    }
    .padding(.horizontal, CSTokens.Space.s4)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// OE-1 · **THE BOOT THAT FAILED IS NOT AN EMPTY SCREEN.**
///
/// `SessionStore.reload()` is the only path into `.ready`, and it is a network
/// read with no cache, so a cold launch on a plane — with a perfectly good
/// Keychain session — landed here and this screen WAS the whole app. Everything
/// the phone already held was behind it: the course books R-N put there for
/// exactly this moment, and a live round in `LiveDisk`.
///
/// So when a session exists the screen carries what the phone knows on its own:
///   · the last successful Home, from the App Group snapshot the widget already
///     reads, under its own AS OF line — never presented as live, and its verb
///     drops itself once the read is a day old (`DispatchSnapshot.verb`);
///   · a door onto the courses on this phone, which needs no session at all.
///
/// OE-2 · and `Sign out` no longer fires on one tap. It is the only other
/// button here, it is a hair from `Try again`, and offline it succeeds locally
/// while leaving the golfer with an emailed code as the only way back.
struct BootFailedView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  let message: String
  @State private var snapshot: DispatchSnapshot? = nil
  @State private var courses = false
  @State private var askSignOut = false

  private var signedIn: Bool { store.session != nil }

  var body: some View {
    ScrollView {
      VStack(spacing: 18) {
        Text("Boot stalled").csEyebrow(cs.neg)
        Text(message).csType(.body).foregroundStyle(cs.ink).multilineTextAlignment(.center)
        Button("Try again") { Task { await store.reload() } }
          .buttonStyle(.csPrimary())

        if signedIn {
          if let s = snapshot { lastKnown(s) }
          Button { courses = true } label: {
            HStack(spacing: 8) {
              Text("Courses on your phone").csType(.body).foregroundStyle(cs.brand)
              Text("›").csType(.body).foregroundStyle(cs.brand)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          Text("Tees, ratings, slopes and cards, saved on this phone. No signal needed.")
            .csType(.bodyS).foregroundStyle(cs.mut)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }

        Button("Sign out") { askSignOut = true }.csType(.body).foregroundStyle(cs.mut)
          .padding(.top, 6)
      }
      .padding(28)
      .frame(maxWidth: .infinity)
    }
    .background(cs.bg0.ignoresSafeArea())
    .task { snapshot = DispatchSnapshot.read() }
    // OE-1 · the boot-failed door onto the courses this phone kept. It reads
    // `CourseDisk` and needs no session, so it works on this screen unchanged
    // — and it carries its own stack, because the course page inside it is a
    // push and there is no tab bar under this screen to push onto.
    .csSheet(isPresented: $courses) {
      NavigationStack {
        CoursesScreen()
          .navigationDestination(for: CourseSheetRef.self) { c in
            CourseScreen(courseId: c.id, label: c.label)
          }
          .csCloseButton { courses = false }
      }
    }
    // OE-2 · it names what is lost, because on this screen the golfer cannot
    // get any of it back until they have a signal AND an email.
    .confirmationDialog("Sign out of Cup Season?", isPresented: $askSignOut, titleVisibility: .visible) {
      Button("Sign out", role: .destructive) { Task { await store.signOut() } }
      Button("Stay signed in", role: .cancel) { }
    } message: {
      Text("Signing back in needs a code emailed to you, so it needs a signal. Try again first if you might not have one.")
    }
  }

  /// The last Home this phone actually loaded. L-32: it says when it is from,
  /// and it never wears a door — the verb is the lead's own act and offering it
  /// off a read that may be a day old is the lie L-44 forbids, which is why
  /// `DispatchSnapshot.verb` withholds it once stale.
  @ViewBuilder private func lastKnown(_ s: DispatchSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(s.asOf()).csEyebrow()
      if let row = s.seasonRow {
        Text(row).csType(.columnS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      if let eyebrow = s.leadEyebrow { Text(eyebrow).csEyebrow() }
      if let head = s.leadHeadline {
        Text(head).csType(.story).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
      }
      if !s.facts.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          ForEach(Array(s.facts.enumerated()), id: \.offset) { _, f in
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text(f.label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              Text(f.value).csType(.columnS).foregroundStyle(cs.ink)
            }
          }
        }
        .padding(.top, 2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
  }
}

struct MustUpdateView: View {
  @Environment(\.cs) private var cs
  let minBuild: Int
  var body: some View {
    VStack(spacing: 14) {
      Text("Update Cup Season").csType(.displayS).foregroundStyle(cs.ink)
      Text("This build is behind the season. Grab the newest one from TestFlight or the App Store, then come back.")
        .csType(.body).foregroundStyle(cs.mut).multilineTextAlignment(.center)
      Text("needs build \(minBuild)").csType(.columnS).foregroundStyle(cs.mut)
    }
    .padding(28)
  }
}

extension String: @retroactive Identifiable { public var id: String { self } }
