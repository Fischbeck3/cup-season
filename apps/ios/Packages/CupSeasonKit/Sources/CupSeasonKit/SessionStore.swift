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
      let me = try await repo.load(userId: uid)
      if let min = me.minIOSBuild, build > 0, build < min {
        state = .mustUpdate(minBuild: min)
      } else if me.needsCard {
        state = .cardGate(me)
      } else {
        if preferredLeague == nil { preferredLeague = me.memberships.first?.league_id }
        state = .ready(me)
      }
    } catch {
      state = .failed(AuthRules.human(error, fallback: "Could not load your card."))
    }
  }

  public func signOut() async {
    try? await svc.signOut()
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
