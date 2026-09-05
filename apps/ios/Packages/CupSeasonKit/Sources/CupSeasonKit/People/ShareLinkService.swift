// Cup Season — minting and redeeming the two new links (D241, D253).
//
// Both halves ship ahead of the owner's `db push`, so both halves have THREE
// states, not two — the pattern wave 5 wrote down after a simulator shot
// caught "The board didn't load." over an account whose board was simply not
// deployed yet:
//
//   .ok        it worked
//   .notYet    the value or the function is not deployed — say nothing is
//              wrong, keep the token, offer nothing that would fail
//   .failed    it failed, and the golfer is told so in their own words
//
// `create_share` exists today and REFUSES an unknown kind with its own
// sentence ("Nothing to share"), and `shares_kind_check` refuses the row; both
// read as `.notYet` until the migration lands, and neither is an error the
// golfer caused. `redeem_share` does not exist at all until then, which is
// PGRST202 — `PostService.fallbackFires(on:)` is the predicate, unchanged.

import Foundation

/// `redeem_share(p_token)` — hand-declared, because the migration that creates
/// it is written and unpushed (the documented shape while a migration awaits
/// its contract refresh; preflight 17 still demands the grant). The argument
/// is defaulted on the server so either deploy order renders honestly.
struct RedeemShareCall: RpcCall {
  static let name = "redeem_share"
  static let optionalArgs: [String] = ["p_token"]
  typealias Returns = JSONValue
  var p_token: UUID?
}

public struct ShareLinkService: Sendable {
  public enum Mint: Sendable, Equatable {
    case ok(URL)
    /// The kind is not deployed yet. NOT an error, and NOT a door: the caller
    /// says so once and offers nothing that would fail.
    case notYet
    case failed(String)
  }
  public enum Redeem: Sendable, Equatable {
    case ok(ShareRedeem)
    case notYet
    case failed(String)
  }

  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// Ask the server for the one live token of this kind for this ref.
  /// `shares_one_live` keys on (kind, ref_id, created_by), so asking twice
  /// hands back the same link — a golfer's person link is stable, which is
  /// what makes it worth putting in a signature or a text thread.
  public func mint(_ kind: ShareIntent, ref: UUID) async -> Mint {
    do {
      let token = try await svc.call(Rpc.create_share(p_kind: kind.shareKind, p_ref: ref))
      CSGrowth.log(.artifactShared, kind: kind.growthKind, token: token.uuidString.lowercased())
      return .ok(kind.url(token))
    } catch {
      if Self.kindNotDeployed(error) { return .notYet }
      return .failed(AuthRules.human(error, fallback: "Could not make that link."))
    }
  }

  /// Spend a pending token. Called once, after sign-in and after the golfer
  /// card exists — the same place `claimPendingRound` is called from — because
  /// a buddy request from a golfer with no name on it is not a request
  /// anybody can answer.
  public func redeem(_ token: UUID) async -> Redeem {
    do {
      let v = try await svc.call(RedeemShareCall(p_token: token))
      return .ok(ShareRedeem.parse(v))
    } catch {
      if PostService.fallbackFires(on: error) { return .notYet }
      return .failed(AuthRules.human(error, fallback: "Could not open that link."))
    }
  }

  /// What a golfer is told when the kind is not deployed yet. It is the
  /// SCORECARD's own sentence, retargeted — `BoardStore.loadScorecard` has said
  /// "needs the latest update — try again shortly" since D92, and inventing a
  /// second voice for the same situation is how two clients start disagreeing.
  /// The row STAYS: a control that vanishes when you tap it is worse than one
  /// that tells you to come back, and after the owner's `db push` it works
  /// with no client change at all.
  public static let notYetLine = "Links need the latest update — try again shortly."

  /// The one condition that means "the migration has not landed yet". A kind
  /// the CHECK does not admit fails as a check violation (23514) or as
  /// `create_share`'s own refusal; neither is a sentence to show a golfer,
  /// because both mean the same thing: this door opens after the next deploy.
  public static func kindNotDeployed(_ error: any Error) -> Bool {
    let m = String(describing: error).lowercased()
    return m.contains("23514") || m.contains("shares_kind_check") || m.contains("nothing to share")
  }
}
