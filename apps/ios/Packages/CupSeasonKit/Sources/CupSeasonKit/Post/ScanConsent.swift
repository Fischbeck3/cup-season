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
}

/// Consent is scoped to the golfer. A failed write stays on this phone and is
/// retried; a failed revocation must never become an apparent server success.
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
  public func permits(_ owner: UUID?) -> Bool { owner != nil && owner == self.owner && allowed }
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
