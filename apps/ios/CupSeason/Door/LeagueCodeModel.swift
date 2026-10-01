import Foundation
import Observation
import CupSeasonKit

/// W7-166: a refusal belongs to the league-code field, without discarding its input.
@MainActor @Observable final class LeagueCodeModel {
  var code = ""
  private(set) var error: String?
  private(set) var busy = false
  private let lookup: @MainActor (String) async throws -> String?
  init(lookup: @escaping @MainActor (String) async throws -> String? = { try await JoinService().leagueName($0) }) {
    self.lookup = lookup
  }
  func edited() { error = nil }
  func take() async -> (code: String, name: String)? {
    guard !busy else { return nil }
    let clean = JoinIntent.normalize(code)
    guard (4...8).contains(clean.count), clean.unicodeScalars.allSatisfy({ (65...90).contains($0.value) || (48...57).contains($0.value) }) else {
      error = "That does not look like a code."; return nil
    }
    busy = true; error = nil
    defer { busy = false }
    do {
      guard let name = try await lookup(clean), !name.isEmpty else {
        error = "No league with that code. Check with your Pro."; return nil
      }
      return (clean, name)
    } catch { self.error = AuthRules.human(error, fallback: "Could not check that code. Try again."); return nil }
  }
}
