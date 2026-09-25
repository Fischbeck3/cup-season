// Cup Season — D384 · a withdrawn photo is withdrawn (launch audit L-05).
//
// Removing a round's photo, replacing it, or deleting the round used to leave
// the public copies (`shared/{token}.jpg` and `.png`) served at their urls —
// after a delete, permanently, because nothing could learn the token again.
// The server may not delete a storage object (D303), so the work splits:
// the SERVER revokes (`clear_round_photo`, `set_round_photo` on a replace and
// `delete_round` all do), and the CLIENT removes the copies. This is the
// client half; the web's twin is `csWithdrawRoundLinks`.
//
// `withdraw_round_shares` revokes and returns every token the caller ever
// minted for the round, revoked ones included, and `shared_copy_delete`
// lets the creator remove a revoked token's copies, so this works after the
// fact and on a round that is about to be deleted.

import Foundation

public enum ShareWithdrawal {
  /// The two public copies a round link can have.
  public static func copyPaths(_ tokens: [String]) -> [String] {
    tokens.flatMap { ["\($0).jpg", "\($0).png"] }
  }

  public struct CleanupPending: LocalizedError, Sendable {
    public var errorDescription: String? { "The link is off. Public image cleanup is still pending. Retry when connected." }
  }

  public static func withdraw(round: UUID, svc: SupabaseService = .shared) async throws {
    try await perform(revoke: { try await svc.call(Rpc.withdraw_round_shares(p_round: round)) },
                      remove: { paths in _ = try await svc.client.storage.from("shared").remove(paths: paths) },
                      confirm: { token in
                        guard let id = UUID(uuidString: token) else { return false }
                        let result = try await svc.call(Rpc.confirm_share_cleanup(p_token: id))
                        return result["status"]?.string == "completed" && result["remaining"]?.int == 0
                      })
  }

  /// Revocation errors must stop the operation; byte-removal errors remain
  /// distinguishable from success and may be retried with the same paths.
  static func perform(revoke: @Sendable () async throws -> [String],
                      remove: @Sendable ([String]) async throws -> Void,
                      confirm: @Sendable (String) async throws -> Bool) async throws {
    let tokens = try await revoke()
    guard !tokens.isEmpty else { return }
    do {
      try await remove(copyPaths(tokens))
      for token in tokens {
        guard try await confirm(token) else { throw CleanupPending() }
      }
    }
    catch { throw CleanupPending() }
  }
}
