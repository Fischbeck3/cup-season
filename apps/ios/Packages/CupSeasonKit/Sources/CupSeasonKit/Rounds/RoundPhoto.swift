// Cup Season — a photograph on a round you already posted (D293 / IOS-065).
//
// The owner, from his own phone on build 733: *"I just posted a round at
// Dinosaur mountain but I cant go back to add a photo. I may have missed that
// option to."* He missed nothing. `post_round`'s `p_photo_path` was the only
// path a photograph had ever taken to a round, and nothing anywhere could put
// one on a round that already existed — §16 says a posted round is not
// mutated, and D37 killed `rounds_owner_update` by name.
//
// D293 scopes §16 correctly: the law protects a NUMBER — the chain from a
// standing back to the arithmetic behind it — and a photograph is in none of
// that chain. `set_round_photo` / `clear_round_photo` touch `photo_path` and
// nothing else, on a round the caller owns, and the migration's self-check
// raises if either sentence ever stops being true of the deployed source.
//
// THE MIGRATION IS WRITTEN AND UNPUSHED, so every call here meets a database
// that does not have the function. That is handled in ONE place — `attach`
// and `remove` translate a missing function into `RoundPhotoFailure.needsPush`
// and the caller prints `RoundCopy.photoNeedsPush` — and the attach takes its
// just-uploaded object back out of the bucket on the way, because an object
// nothing points at is exactly the orphan `delete_round` had to learn about
// (`20260901140000`: "prod already carries orphans from this").

import Foundation
import Supabase

/// R-photo · **NOTHING is droppable**, for `PostRoundCall`'s reason (C-03):
/// `SupabaseService.call(_:)` retries a first failure by removing every
/// droppable key at once, and a retry that dropped `p_photo_path` would be a
/// call that attaches nothing while reporting success.
public struct SetRoundPhotoCall: RpcCall {
  public static let name = "set_round_photo"
  public static let optionalArgs: [String] = []
  public typealias Returns = JSONValue
  public var p_round: UUID
  public var p_photo_path: String
  public init(p_round: UUID, p_photo_path: String) {
    self.p_round = p_round; self.p_photo_path = p_photo_path
  }
}

/// The way back. Two names rather than one nullable argument, because
/// `set_profile`'s convention is that null LEAVES A FIELD ALONE — a single
/// call would have to mean the opposite of what this codebase's other photo
/// writer means by the same shape. `rate_course` / `unrate_course` (D289) is
/// the precedent that reads correctly.
public struct ClearRoundPhotoCall: RpcCall {
  public static let name = "clear_round_photo"
  public static let optionalArgs: [String] = []
  public typealias Returns = JSONValue
  public var p_round: UUID
  public init(p_round: UUID) { self.p_round = p_round }
}

/// Two failures, told apart because they say two different things to a golfer.
public enum RoundPhotoFailure: Error, Sendable, Equatable {
  /// The database does not have the function yet — the state this wave ships
  /// in. `RoundCopy.photoNeedsPush`.
  case needsPush
  /// No signal, a refused upload, a round that is not yours.
  /// `RoundCopy.photoFailed`.
  case failed
}

/// **What the receipt draws in the photograph's slot** — a pure function of
/// two facts, so it is asserted rather than photographed.
public enum RoundPhotoSlot: Sendable, Equatable {
  /// Somebody else's round: no plate control of any kind. The same gate the
  /// delete applies (D284).
  case none
  /// His round, no photograph: the one door, where the plate would be.
  case offer
  /// His round, a photograph on it: the plate, then replace and remove.
  case present

  public static func `for`(isMine: Bool, photoPath: String?) -> RoundPhotoSlot {
    guard isMine else { return .none }
    let p = (photoPath ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return p.isEmpty ? .offer : .present
  }
}

public struct RoundPhotoService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// The object path a round photograph is written to, and the server's own
  /// guard is `^{auth.uid()}/` — a golfer may point a round at an object under
  /// his own prefix and nowhere else. Without that fence a signed-in golfer
  /// could point his round at somebody else's private object and then read it
  /// through the round's signing call. Same shape as `PostService.uploadPhoto`.
  public static func objectPath(uid: UUID) -> String {
    "\(uid.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
  }

  /// Upload, then attach. Returns the path the round now carries.
  ///
  /// The order matters and so does the unwind: a failed attach leaves an
  /// object with nothing pointing at it, signed-URL reachable by anyone ever
  /// handed a link, so the object goes back out before the failure is thrown.
  public func attach(_ roundId: UUID, jpeg: Data, uid: UUID) async throws -> String {
    let path = RoundPhotoService.objectPath(uid: uid)
    do {
      _ = try await svc.client.storage.from("media")
        .upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: false))
    } catch {
      throw RoundPhotoFailure.failed
    }
    do {
      _ = try await svc.call(SetRoundPhotoCall(p_round: roundId, p_photo_path: path))
      return path
    } catch {
      _ = try? await svc.client.storage.from("media").remove(paths: [path])
      throw RoundPhotoService.translate(error)
    }
  }

  /// Take it off. The server reclaims the object in the same statement that
  /// drops the reference, so there is nothing for the client to clean up.
  public func remove(_ roundId: UUID) async throws {
    do { _ = try await svc.call(ClearRoundPhotoCall(p_round: roundId)) }
    catch { throw RoundPhotoService.translate(error) }
  }

  /// PGRST202 / 42883 is the database being behind this build, and it is the
  /// ONLY error that earns the push sentence. Everything else is a real
  /// failure and gets the golfer's own words.
  static func translate(_ error: Error) -> RoundPhotoFailure {
    (error as? RpcError)?.isMissingFunction == true ? .needsPush : .failed
  }
}
