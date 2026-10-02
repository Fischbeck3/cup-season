import Foundation
import Observation
import Supabase

public enum ScanConsentCopy {
  public static let title = "Scan with Claude?"
  public static let eyebrow = "ASKED ONCE · CHANGE IT IN SETTINGS"
  public static let body = "Scanning sends this photo to Anthropic’s Claude to read the scores. It isn’t used to train their models."
  public static let yes = "Scan with Claude"
  public static let no = "Type it in"
  public static let declined = "Nothing was sent — type your nines in"
  public static let setting = "Scorecard scanning with Claude"
  public static let settingNote = "A scan sends the scorecard photo to Anthropic’s Claude to read the scores. It isn’t used to train their models. Off means the next scan asks first."
  /// D403 · a scan refused for consent on a yes the golfer tapped in THIS
  /// attempt, after the server reported taking it (the web's
  /// `CS_SCAN_CONSENT.notSaved`). Also the sheet's yes failing to save.
  public static let notSaved = "Your yes to scanning didn’t save — type your nines in, or try the scan again."
  /// Settings could not turn scanning on (the web's `settingFailed`).
  public static let settingFailed = "Couldn’t change that — try again."
  /// Settings could not save a "no" to the account; the phone keeps it and resends it.
  public static let offPending = "Saved on this phone. We’ll retry syncing your choice when you reopen Settings."
}

/// D403 (corrected 2026-10-01) · what the scan door does next, decided from
/// the server's answer alone. The `scan` Edge Function reads
/// `profiles.scan_consent_at` itself and refuses (403 `no_consent`) without
/// it, and that refusal is FINAL for whatever this phone believed: a yes read
/// earlier, or one cached on the phone, is a guess about the server. So a
/// refusal never writes a yes back on the golfer's behalf — that would undo a
/// "no" given in Settings on another device. The only yes the phone writes is
/// one the golfer just tapped on the sheet, and one scan is retried on it at
/// most once.
public enum ScanConsentGate: Sendable, Equatable {
  /// The server holds the golfer's yes: open the camera.
  case scan
  /// Ask with the existing "Scan with Claude?" sheet; only its yes goes further.
  case ask
  /// A yes tapped in this attempt was refused anyway: say it did not save and
  /// stop (`ScanConsentCopy.notSaved`) — never a loop.
  case notSaved
  /// The account is closed: nothing to ask, nothing to send.
  case closed

  /// Before a scan. `serverYes` is a yes the server CONFIRMED just now.
  public static func before(serverYes: Bool) -> ScanConsentGate { serverYes ? .scan : .ask }

  /// After the function refused a scan. `freshYes` is true only when the
  /// golfer tapped yes on the sheet for this very attempt (and the server
  /// reported saving it). nil for every other reason: the caller's ordinary toast.
  public static func after(refusal reason: String?, freshYes: Bool) -> ScanConsentGate? {
    switch reason {
    case "no_consent":     return freshYes ? .notSaved : .ask
    case "account_closed": return .closed
    default:               return nil
    }
  }
}

/// D403 · a scan belongs to the golfer who started it (review of 0e463792). The photo is
/// sent, and an answer applied — a card, a refusal, a consent change, a sheet — only
/// while that golfer is still the one signed in; otherwise the attempt is dropped whole.
public struct ScanAttempt: Sendable, Equatable {
  public let owner: UUID
  public init(owner: UUID) { self.owner = owner }
  public func isCurrent(_ signedIn: UUID?) -> Bool { signedIn == owner }
}

/// Consent is scoped to the golfer, and the server's answer wins.
/// - A yes is consent only once the server took it (`permits`). A yes the
///   server did not take is a failure to report, never kept on the phone.
/// - A "no" the server did not take is kept on the phone (`pendingSync`) and
///   resent: a failed revocation must never become an apparent server success,
///   and the private direction is the one that may wait.
/// - A refusal from the scan function (`serverRefused`) drops every yes held
///   here for that golfer.
@MainActor @Observable
public final class ScanConsentStore {
  public static let shared = ScanConsentStore()
  public private(set) var owner: UUID?
  public private(set) var allowed = false
  public private(set) var busy = false
  /// A "no" saved on this phone that the account has not taken yet.
  public private(set) var pendingSync = false
  private let defaults: UserDefaults
  private let read: (UUID) async throws -> Bool
  private let write: (Bool, UUID) async throws -> Bool
  private var generation = 0

  /// D403 (review of a3115801) · the golfer a consent read or write belongs to is no
  /// longer the one signed in. Nothing was sent.
  public struct NotTheirs: Error, Equatable {}

  /// `read(owner)` and `write(on, owner)` act for `owner` ONLY. By default each resolves
  /// that golfer's token at the moment it sends (`NotTheirs` when someone else, or no
  /// one, is signed in) and sends it on a client bound to it, because the shared client
  /// would put whoever is signed in at send time on the request.
  public init(defaults: UserDefaults = .standard,
              read: ((UUID) async throws -> Bool)? = nil,
              write: ((Bool, UUID) async throws -> Bool)? = nil) {
    self.defaults = defaults
    self.read = read ?? { owner in
      guard let session = await SupabaseService.shared.session(of: owner) else { throw NotTheirs() }
      struct Row: Decodable { let scan_consent_at: String? }
      let rows: [Row] = try await SupabaseService.shared.bound(to: session.accessToken).from("profiles")
        .select("scan_consent_at").eq("id", value: owner).execute().value
      guard let row = rows.first else { throw CancellationError() }
      return row.scan_consent_at != nil
    }
    self.write = write ?? Self.boundWrite(
      tokenOf: { await SupabaseService.shared.session(of: $0)?.accessToken },
      send: { on, token in try await SupabaseService.shared.call(Rpc.set_scan_consent(p_on: on), token: token) })
  }

  /// The consent write for one golfer: `tokenOf` resolves THAT golfer's token when the
  /// write is sent (nil when the account changed), and `send` must put exactly that token
  /// on the request — production uses a client bound to it (`SupabaseService.bound(to:)`).
  nonisolated static func boundWrite(tokenOf: @escaping @Sendable (UUID) async -> String?,
                         send: @escaping @Sendable (Bool, String) async throws -> Bool) -> @Sendable (Bool, UUID) async throws -> Bool {
    { on, owner in
      guard let token = await tokenOf(owner) else { throw NotTheirs() }
      return try await send(on, token)
    }
  }
  private func key(_ owner: UUID) -> String { "cs_scan_consent.\(owner.uuidString.lowercased())" }
  /// D403 · a server-confirmed yes for this golfer, and nothing less.
  public func permits(_ owner: UUID?) -> Bool { owner != nil && owner == self.owner && allowed && !pendingSync }

  /// D403 · the scan function refused for consent: the server holds no yes
  /// for this golfer. Every yes held here is dropped, an in-flight read or
  /// write is orphaned, and nothing is written — the golfer is asked.
  public func serverRefused(owner: UUID) {
    guard self.owner == owner else { return }
    generation += 1
    allowed = false
    busy = false
    if defaults.object(forKey: key(owner)) as? Bool == true { defaults.removeObject(forKey: key(owner)) }
  }
  public func reset() { generation += 1; owner = nil; allowed = false; busy = false; pendingSync = false }

  public func load(owner: UUID) async {
    generation += 1
    let gen = generation
    self.owner = owner
    // Only a pending "no" is resent. A yes cached by an older build is not
    // the golfer's choice for THIS attempt and is dropped unwritten: writing
    // it later could undo a revocation made on another device since.
    let fallback = defaults.object(forKey: key(owner)) as? Bool
    if fallback == true { defaults.removeObject(forKey: key(owner)) }
    let pendingNo = fallback == false
    allowed = false
    pendingSync = pendingNo
    busy = true
    defer { if generation == gen { busy = false } }
    do {
      let value: Bool
      if pendingNo { value = try await write(false, owner) } else { value = try await read(owner) }
      guard generation == gen, self.owner == owner else { return }
      allowed = value; pendingSync = false
      if pendingNo { defaults.removeObject(forKey: key(owner)) }
    } catch { /* A read failure never implies permission; only an explicit yes does. */ }
  }

  /// True when the account holds the choice. A yes the account did not take
  /// leaves scanning off; a "no" it did not take is kept here and resent.
  @discardableResult public func set(_ on: Bool, owner: UUID) async -> Bool {
    guard self.owner == owner, !busy else { return false }
    generation += 1
    let gen = generation
    busy = true
    defer { if generation == gen { busy = false } }
    do {
      let value = try await write(on, owner)
      guard generation == gen, self.owner == owner else { return false }
      allowed = value; pendingSync = false; defaults.removeObject(forKey: key(owner))
      return value == on
    } catch {
      guard generation == gen, self.owner == owner else { return false }
      if on { return false }
      defaults.set(false, forKey: key(owner)); allowed = false; pendingSync = true
      return false
    }
  }
}
