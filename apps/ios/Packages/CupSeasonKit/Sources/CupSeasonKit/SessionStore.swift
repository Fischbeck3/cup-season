// Cup Season — who is signed in, and what state the app is in (IOS-002 §3).
//
// One store, one enum, driven by the auth stream. No reload-as-navigation.
// Auth events are handled on the main actor in their own task turn — the
// deferral that keeps any auth call made from a handler off the SDK's lock.

import Foundation
import Observation
import Supabase

public enum AppState: Sendable {
  case restoring
  case signedOut
  case cardGate(Me)          // signed in; marker or handle missing
  case ready(Me)
  case mustUpdate(minBuild: Int)
  case failed(String)        // bootstrap failed; retry offered
}

@MainActor
@Observable
public final class SessionStore {
  public private(set) var state: AppState = .restoring
  /// D102 — who is the founder, who are the founding members (one read per load).
  public private(set) var founding = FoundingIds()
  public private(set) var session: Session?
  public private(set) var loading = false
  /// The league Home leads with (the web's `cs_last_league`).
  public var preferredLeague: UUID? {
    didSet { UserDefaults.standard.set(preferredLeague?.uuidString, forKey: CSConfig.lastLeagueKey) }
  }

  private let svc: SupabaseService
  private let repo: any MeRepository
  private var listener: Task<Void, Never>?
  public let build: Int
  /// IOS-024 `signed_in`: set by a SIGNED_IN event, cleared by the first
  /// `.ready` after it — a Keychain restore (INITIAL_SESSION) never fires it.
  private var signInPending = false

  public init(svc: SupabaseService = .shared, repo: any MeRepository = SupabaseMeRepository(), build: Int = SessionStore.bundleBuild()) {
    self.svc = svc; self.repo = repo; self.build = build
    self.preferredLeague = UserDefaults.standard.string(forKey: CSConfig.lastLeagueKey).flatMap(UUID.init)
  }

  public static func bundleBuild() -> Int {
    Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0
  }

  /// Restore from the Keychain and start listening. Idempotent.
  public func start() {
    guard listener == nil else { return }
    listener = Task { [weak self] in
      guard let self else { return }
      for await (event, session) in svc.client.auth.authStateChanges {
        await self.handle(event, session)
      }
    }
  }

  private func handle(_ event: AuthChangeEvent, _ session: Session?) async {
    self.session = session
    await svc.forwardRealtimeAuth(session)
    switch event {
    case .initialSession, .signedIn:
      if session != nil {
        if case .ready = state, event == .signedIn { return }   // already in; a re-emit
        if event == .signedIn { signInPending = true }
        await reload()
      } else {
        state = .signedOut
      }
    case .signedOut, .userDeleted:
      state = .signedOut
    case .tokenRefreshed, .userUpdated, .passwordRecovery, .mfaChallengeVerified:
      break
    }
  }

  /// Re-read `Me` and re-derive the state. Safe to call from pull-to-refresh.
  public func reload() async {
    guard let uid = session?.user.id else { state = .signedOut; return }
    guard !loading else { return }
    loading = true
    defer { loading = false }
    do {
      async let ids = FoundingIds.load(svc)
      let me = try await loadWithSkewRetry(uid)
      founding = await ids
      if let min = me.minIOSBuild, build > 0, build < min {
        state = .mustUpdate(minBuild: min)
      } else if me.needsCard {
        state = .cardGate(me)
      } else {
        // D229 · navigation memory, and nothing else — but memory of a season
        // this golfer is no longer in is not memory, it is a dead route. The
        // Clubhouse used to swallow that silently (it fell back to the first
        // membership when the remembered id matched none); the season page
        // loads exactly the id it is given, so the id is checked HERE, once,
        // rather than by every door that reads it.
        if let want = preferredLeague, !me.memberships.contains(where: { $0.league_id == want }) {
          preferredLeague = nil
        }
        if preferredLeague == nil { preferredLeague = me.memberships.first?.league_id }
        if let p = me.profile, p.id == uid {
          OfflineGolfer(id: p.id, name: p.display_name ?? "You", index: p.index_current, marker: p.marker).keep()
        }
        state = .ready(me)
        if signInPending { signInPending = false; CSTelemetry.product(.signedIn) }
        // D261 / R-N · fill the offline course store off the back of a boot
        // that already succeeded. Detached because it must never delay a
        // screen, and silent because a failure means the phone keeps the books
        // it already has — which is the whole point.
        // OE-2 · and the books belong to a GOLFER: a different one arriving is
        // what clears them (`claim`), not a sign-out that may be a mis-tap on
        // a dead screen.
        let mine = me.profile?.id
        Task.detached(priority: .utility) {
          await CourseBookStore().claim(mine)
          await CourseBookStore().refresh()
        }
      }
    } catch {
      // `.failed` is the BOOT's state ("retry offered" — RootView swaps the
      // tabs out for it). A refresh that fails with a payload already in hand
      // keeps that payload: a pull on a bad connection, or any of the many
      // screens that call reload() after a write, must never evict a
      // signed-in golfer to "Boot stalled" and throw away every tab's
      // navigation. Only a session with nothing on screen falls to it.
      // `.cardGate` is NOT kept: the gate holds no navigation worth saving,
      // and its one caller reloads right after the save RPCs — kept, the
      // golfer would sit on step 2 with the card already saved and no sign
      // that only Home failed. "Boot stalled · Try again" is that sign.
      switch state {
      case .ready: break
      default:
        // A dead session is removed by the SDK, which emits `.signedOut` on
        // its own turn — that can land mid-reload, and the RPC then fails as
        // anon ("Sign in first"). The door is the honest end of that story,
        // but only when the session is really gone: a door sign-in whose
        // first reload fails still holds one and must reach Try again.
        state = session == nil ? .signedOut
          : .failed(AuthRules.human(error, fallback: "Could not load your card."))
      }
    }
  }

  /// PGRST303 "JWT issued at future": a freshly refreshed token whose `iat`
  /// is a second or two ahead of PostgREST's clock (device clock drift). It
  /// clears itself; one retry after a beat beats a "boot stalled" screen.
  private func loadWithSkewRetry(_ uid: UUID) async throws -> Me {
    do { return try await repo.load(userId: uid) }
    catch {
      let text = String(describing: error)
      guard text.contains("PGRST303") || text.localizedCaseInsensitiveContains("issued at future") else { throw error }
      try? await Task.sleep(for: .seconds(2.5))
      return try await repo.load(userId: uid)
    }
  }

  public func signOut() async {
    try? await svc.signOut()
    // OE-2 · the course books are NOT deleted here. D261's rule — a shared
    // phone does not hand one golfer's schedule and rounds to the next — is
    // kept, and enforced where the next golfer actually appears:
    // `CourseBookStore.claim(_:)`, on the first `.ready` of a sign-in. Deleting
    // them here meant a mis-tap on `Boot stalled`, offline, destroyed the only
    // thing the app could still show. Nothing signed-out can read them.
    //
    // P3f · the WIDGET's snapshot is cleared here, and the difference is the
    // door. The course books sit inside the app behind a session; the home
    // screen has no session, so a season row, an index and a lead headline
    // left on a widget is a signed-out golfer still broadcasting to whoever
    // picks the phone up. The next successful Home writes it again.
    DispatchSnapshot.forget()
    state = .signedOut
  }

  public var me: Me? {
    switch state {
    case .ready(let me), .cardGate(let me): me
    default: nil
    }
  }

  public var email: String? { session?.user.email }
}
