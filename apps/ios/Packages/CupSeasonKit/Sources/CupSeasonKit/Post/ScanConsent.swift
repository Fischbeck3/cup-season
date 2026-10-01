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
  /// D403 · the scan was refused for consent and the one re-save of the
  /// golfer's yes did not land (the web's `CS_SCAN_CONSENT.notSaved`).
  public static let notSaved = "Your yes to scanning didn’t save — type your nines in, or try the scan again."
}

/// D403 · what the scan door does next, decided from the server's answer
/// alone. The `scan` Edge Function now reads `profiles.scan_consent_at` itself
/// and refuses (403 `no_consent`) without it, so a yes that only this phone
/// holds is not consent: a scan sent on it would be refused every time.
public enum ScanConsentGate: Sendable, Equatable {
  /// The server holds the golfer's yes: open the camera.
  case scan
  /// A yes the golfer gave on this phone never reached the server: write it
  /// once more before anything is sent.
  case retryYes
  /// Ask again with the existing "Scan with Claude?" sheet.
  case ask
  /// The account is closed: nothing to ask, nothing to send.
  case closed

  /// Before a scan. `serverYes` is a yes the server CONFIRMED; `localYesPending`
  /// is a yes saved only on this phone; `retried` is whether the one retry has
  /// already run. Never `.scan` without the server's yes.
  public static func before(serverYes: Bool, localYesPending: Bool, retried: Bool) -> ScanConsentGate {
    if serverYes { return .scan }
    if localYesPending && !retried { return .retryYes }
    return .ask
  }

  /// After the function refused a scan. A refusal for consent means the
  /// server does not hold a yes, whatever this phone thought — so a yes the
  /// golfer gave on this phone is written once more (and the scan asked once
  /// more only if the server then holds it), and otherwise the golfer meets
  /// the sheet again. After the one retry, `.ask` means "say it did not save"
  /// (`ScanConsentCopy.notSaved`) — the web's flow, step for step. nil for
  /// every other reason: the caller's ordinary toast.
  public static func after(refusal reason: String?, saidYesHere: Bool, retried: Bool) -> ScanConsentGate? {
    switch reason {
    case "no_consent":     return saidYesHere && !retried ? .retryYes : .ask
    case "account_closed": return .closed
    default:               return nil
    }
  }
}

/// Consent is scoped to the golfer. A failed write stays on this phone and is
/// retried; a failed revocation must never become an apparent server success.
/// D403 · and a yes only this phone holds never PERMITS a scan: `allowed` is
/// the golfer's choice (what Settings shows), `permits` is the server's.
@MainActor @Observable
public final class ScanConsentStore {
  public static let shared = ScanConsentStore()
  public private(set) var owner: UUID?
  public private(set) var allowed = false
  public private(set) var busy = false
  public private(set) var pendingSync = false
  private let defaults: UserDefaults
  private let read: (UUID) async throws -> Bool
  private let write: (Bool) async throws -> Bool
  private var generation = 0

  public init(defaults: UserDefaults = .standard,
              read: ((UUID) async throws -> Bool)? = nil,
              write: ((Bool) async throws -> Bool)? = nil) {
    self.defaults = defaults
    self.read = read ?? { owner in
      struct Row: Decodable { let scan_consent_at: String? }
      let rows: [Row] = try await SupabaseService.shared.client.from("profiles")
        .select("scan_consent_at").eq("id", value: owner).execute().value
      guard let row = rows.first else { throw CancellationError() }
      return row.scan_consent_at != nil
    }
    self.write = write ?? { try await SupabaseService.shared.call(Rpc.set_scan_consent(p_on: $0)) }
  }
  private func key(_ owner: UUID) -> String { "cs_scan_consent.\(owner.uuidString.lowercased())" }
  /// D403 · a server-confirmed yes, and nothing less. A yes saved only on
  /// this phone (`pendingSync`) is the golfer's choice but not consent the
  /// `scan` function can see, so it does not open the camera.
  public func permits(_ owner: UUID?) -> Bool { owner != nil && owner == self.owner && allowed && !pendingSync }
  /// A yes the golfer gave on this phone that the server has not yet taken.
  public func localYesPending(_ owner: UUID?) -> Bool { owner != nil && owner == self.owner && allowed && pendingSync }

  /// D403 · the function refused a scan for consent: the server is the
  /// source of truth. The device-only yes is dropped and the golfer's yes is
  /// written ONCE more. True only when the server took it; a failure leaves
  /// no yes anywhere — never a phone-only one that would be refused forever.
  @discardableResult public func reconfirm(owner: UUID) async -> Bool {
    guard self.owner == owner else { return false }
    generation += 1
    let gen = generation
    allowed = false; pendingSync = false
    defaults.removeObject(forKey: key(owner))
    busy = true
    defer { if generation == gen { busy = false } }
    let value = (try? await write(true)) ?? false
    guard generation == gen, self.owner == owner else { return false }
    allowed = value
    return value
  }
  public func reset() { generation += 1; owner = nil; allowed = false; busy = false; pendingSync = false }

  public func load(owner: UUID) async {
    generation += 1
    let gen = generation
    self.owner = owner
    let fallback = defaults.object(forKey: key(owner)) as? Bool
    allowed = fallback ?? false
    pendingSync = fallback != nil
    busy = true
    defer { if generation == gen { busy = false } }
    do {
      let value: Bool
      if let fallback { value = try await write(fallback) } else { value = try await read(owner) }
      guard generation == gen else { return }
      allowed = value; pendingSync = false
      defaults.removeObject(forKey: key(owner))
    } catch { /* A read failure never implies permission; only an explicit yes does. */ }
  }

  /// Returns false when only this device could save the choice.
  @discardableResult public func set(_ on: Bool, owner: UUID) async -> Bool {
    guard self.owner == owner, !busy else { return false }
    generation += 1
    let gen = generation
    busy = true
    defer { if generation == gen { busy = false } }
    do {
      let value = try await write(on)
      guard generation == gen, self.owner == owner else { return false }
      allowed = value; pendingSync = false; defaults.removeObject(forKey: key(owner))
      return true
    } catch {
      guard generation == gen, self.owner == owner else { return false }
      defaults.set(on, forKey: key(owner)); allowed = on; pendingSync = true
      return false
    }
  }
}
