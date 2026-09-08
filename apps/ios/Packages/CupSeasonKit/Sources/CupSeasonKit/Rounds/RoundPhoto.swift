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

/// **WHERE A PHOTOGRAPH COMES FROM, AND THE ROLL IS NEVER NOT OFFERED** (D298).
///
/// The owner, on build 748: *"when I open a posted round I cant add a photo
/// from camera roll only take one."* The door was ONE LINE, and the same line
/// on both photo surfaces —
///
///     if PostPhoto.cameraAvailable { showCamera = true } else { showLibrary = true }
///
/// — which reads as a FALLBACK: the roll is what the phone gets when the app
/// may not open the camera. But `NSCameraUsageDescription` is in the Info.plist
/// and every real phone has a camera, so the branch that ran was ALWAYS the
/// camera, on every device, forever. The roll was unreachable from both doors.
/// The simulator is the reason it was never seen: `cameraAvailable` is false
/// there, so every screenshot this repo has ever taken went down the OTHER
/// branch and showed the picker the phone could not open.
///
/// **The desk never had this bug.** `<input type="file" accept="image/*">` with
/// no `capture` gives iOS its own menu — Photo Library · Take Photo · Choose
/// File — so the two clients differed on a capability, which is the class D234
/// forbids and the same class as the receipt's missing delete (D284).
///
/// A pure function of one fact, like `RoundPhotoSlot` above it, so the fix is
/// asserted rather than photographed — and the assertion is the one no grep
/// could make, because every grep for `showLibrary` found it: that the roll is
/// in the list AT ALL.
public enum RoundPhotoSource: String, Sendable, Equatable, CaseIterable {
  case library, camera

  /// The doors, in the order they are offered. **The roll is first**, and that
  /// is D293's own argument applied to the door instead of the act: the score
  /// is typed in the car park and the picture was taken on the 12th.
  public static func offered(cameraAvailable: Bool) -> [RoundPhotoSource] {
    cameraAvailable ? [.library, .camera] : [.library]
  }

  /// One door needs no question, two do — a simulator, or an iPad with no
  /// camera, goes straight to the roll rather than reading a menu of one.
  public static func asks(cameraAvailable: Bool) -> Bool {
    offered(cameraAvailable: cameraAvailable).count > 1
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
  /// `replacing` is the path the round carried BEFORE this call (D303): the
  /// server may not delete a storage object, so whoever knows the old path has
  /// to reclaim it.
  public func attach(_ roundId: UUID, jpeg: Data, uid: UUID, replacing oldPath: String? = nil) async throws -> String {
    let path = RoundPhotoService.objectPath(uid: uid)
    do {
      _ = try await svc.client.storage.from("media")
        .upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: false))
    } catch {
      throw RoundPhotoFailure.failed
    }
    do {
      _ = try await svc.call(SetRoundPhotoCall(p_round: roundId, p_photo_path: path))
      await reclaim(oldPath, keeping: path)
      return path
    } catch {
      _ = try? await svc.client.storage.from("media").remove(paths: [path])
      throw RoundPhotoService.translate(error)
    }
  }

  /// Take it off. **The server used to reclaim the object in the same statement
  /// that drops the reference, and the platform will not allow that** (D303) —
  /// it drops the reference and `reclaim` takes the object out afterwards.
  public func remove(_ roundId: UUID, object path: String? = nil) async throws {
    do { _ = try await svc.call(ClearRoundPhotoCall(p_round: roundId)) }
    catch { throw RoundPhotoService.translate(error) }
    await reclaim(path, keeping: nil)
  }

  /// D303 · **the object is the caller's to reclaim, and never load-bearing.**
  /// Supabase forbids `delete from storage.objects` outright, so the server
  /// drops the reference and this takes the object out through the Storage
  /// API — the one route the platform allows, and one a golfer is entitled to
  /// take under `media_delete` (his own `{uid}/` prefix and nowhere else).
  ///
  /// It runs AFTER the reference is gone and it swallows its own failure, in
  /// that order and on purpose: an orphan is unreachable except by a signed
  /// URL nobody holds, while a round pointing at a deleted object draws a
  /// broken photograph on the front page of the product.
  private func reclaim(_ path: String?, keeping: String?) async {
    guard let path, !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          path != keeping else { return }
    _ = try? await svc.client.storage.from("media").remove(paths: [path])
  }

  #if DEBUG
  /// **THE PROBE** — `-cs_dev_photo_probe`. The owner, on a build with the
  /// migration live in prod: *"when trying to post photo 'the photo didnt
  /// attach, check your signal and try again'."*
  ///
  /// That sentence is `RoundCopy.photoFailed`, and L-32 is why it says nothing
  /// more: a golfer never reads a code. The cost of that rule is that a failure
  /// the owner can reproduce is a failure NOBODY CAN READ — not him, not me,
  /// and the two halves of `attach` (the storage upload and the RPC) collapse
  /// into the same word. Everything checkable from outside checks out: prod is
  /// at 222 with `set_round_photo` live, the round is his, the bucket takes
  /// `image/jpeg` up to 8 MB, and the INSERT policy fences the same
  /// `{uid}/` prefix the client writes. So the answer is in the response, and
  /// this is how the response gets read.
  ///
  /// It runs the REAL two steps against prod, on the simulator's copy of the
  /// owner's own session, and reports each one raw. **It unwinds whatever it
  /// did** — the round goes back to no photograph and the object goes back out
  /// of the bucket — so his data is where it started. DEBUG only; there is no
  /// such door in the shipped build.
  public func probe(_ roundId: UUID, uid: UUID, jpeg: Data, priorPath: String?) async -> String {
    var log = "PROBE round=\(roundId.uuidString.prefix(8)) bytes=\(jpeg.count)\n"
    var uploaded: [String] = []

    /// Upload one object and point the round at it. Returns the path, or nil
    /// after writing the failure into the log.
    func step(_ name: String, replacing old: String?) async -> String? {
      let path = RoundPhotoService.objectPath(uid: uid)
      do {
        _ = try await svc.client.storage.from("media")
          .upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: false))
        uploaded.append(path)
      } catch {
        log += "\(name) UPLOAD FAILED · " + String(describing: error) + "\n"; return nil
      }
      do {
        _ = try await svc.call(SetRoundPhotoCall(p_round: roundId, p_photo_path: path))
        log += "\(name) OK\n"
        return path
      } catch {
        log += "\(name) RPC FAILED · " + SupabaseService.describe(error) + "\n"; return nil
      }
    }

    // 1 · ATTACH — the branch that has no object to reclaim. This one worked
    //     the moment D300 landed, and it is why D303 stayed hidden for a run.
    guard let first = await step("1 attach", replacing: nil) else { return await finish(log, uploaded) }
    // 2 · REPLACE — `set_round_photo`'s reclaim branch, which raised 42501.
    _ = await step("2 replace", replacing: first)
    // 3 · REMOVE — `clear_round_photo`'s, which raised the same.
    do { _ = try await svc.call(ClearRoundPhotoCall(p_round: roundId)); log += "3 remove OK\n" }
    catch { log += "3 remove FAILED · " + SupabaseService.describe(error) + "\n" }

    // Put the round back exactly as it was found. A probe that leaves a
    // photograph on a golfer's round is a diagnostic that damages its subject
    // — which is not hypothetical: the first run of this did that.
    if let priorPath, !priorPath.isEmpty {
      do { _ = try await svc.call(SetRoundPhotoCall(p_round: roundId, p_photo_path: priorPath))
           log += "restored the photograph it had\n" }
      catch { log += "RESTORE FAILED · " + SupabaseService.describe(error) + "\n" }
    } else {
      log += "round left with no photograph, as it started\n"
    }
    return await finish(log, uploaded)
  }

  /// Take every object this probe made back out, through the Storage API.
  private func finish(_ log: String, _ paths: [String]) async -> String {
    for p in paths { _ = try? await svc.client.storage.from("media").remove(paths: [p]) }
    return log + "reclaimed \(paths.count) object(s)"
  }

  #endif

  /// PGRST202 / 42883 is the database being behind this build, and it is the
  /// ONLY error that earns the push sentence. Everything else is a real
  /// failure and gets the golfer's own words.
  static func translate(_ error: Error) -> RoundPhotoFailure {
    (error as? RpcError)?.isMissingFunction == true ? .needsPush : .failed
  }
}
