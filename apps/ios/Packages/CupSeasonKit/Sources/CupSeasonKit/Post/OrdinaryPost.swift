// Cup Season — the ordinary post, run once however many times Post is pressed
// (D350, built 2026-09-13; amended the same day after Codex's second review).
//
// ONE INTENT, ONE IDENTITY, AND THE IDENTITY IS NEVER ROTATED. The first cut
// asked `round_post_status` when the card had been edited after an ambiguous
// failure and, on a NULL answer, minted a fresh id and posted at once. NULL
// does not prove the first request will never commit: a request delayed in
// transit can land after the status read, and the fresh id then posts the
// same golf a second time. A status read cannot protect against a request
// that has not arrived yet, whatever lock it takes.
//
// So the client keeps the id for the whole life of the intent and lets the
// SERVER decide, which it already can: `post_round_once` takes an advisory
// lock per (owner, request) and keeps a receipt, so two bodies under one id
// serialise — the first to commit wins, the second is refused with "already
// has a different scorecard" and writes nothing. That is the amended-request
// contract, and it holds in every arrival order. What the client does with
// each answer:
//
//   1. A read that fails stops everything. Nothing is sent, the draft stays.
//   2. An envelope the disk says landed is FINISHED, never re-sent.
//   3. The same card replays the frozen envelope verbatim — photo path, holes
//      and partners included. No second upload, no recomputed payload.
//   4. A different card is sent under the SAME id as an amendment. If the
//      earlier body already landed, the server refuses and the client asks
//      `round_post_status` for the round that DID land, finishes this intent
//      and opens that receipt: an edit to a posted round is the existing
//      correction path (delete the round, post again), never a second round.
//   5. A fresh envelope is written to disk before the call; a write that fails
//      stops everything, with a message about the phone, not the network.
//   6. A definite refusal (the server said no: a rating out of range, a date
//      it will not take) keeps the id — nothing was written, and the corrected
//      card posts under the same request. An ambiguous failure (transport)
//      keeps the id too, and the same envelope retries. The two get different
//      sentences because one asks for a change and the other for a retry.
//   7. The server not having the function is fail-closed: nothing else is
//      tried, the draft and the request stay, and the copy says so.
//
// A golfer who has finished a recovery can start a NEW round: the finish
// clears the identity, and the next composed round mints its own.

import Foundation

public enum OrdinaryPost {
  /// The seams. All `@MainActor` because the disk is.
  public struct Ports {
    public var read: @MainActor (_ owner: UUID, _ request: UUID) throws -> OfflinePost?
    public var save: @MainActor (OfflinePost) throws -> Void
    /// `round_post_status` — the accepted round id for a request, or nil.
    public var status: @MainActor (_ request: UUID) async throws -> UUID?
    public var post: @MainActor (OfflinePost) async throws -> PostService.PostOutcome
    /// nil = the upload did not stick; the round posts without the photo.
    public var upload: @MainActor (Data) async -> String?
    public init(read: @escaping @MainActor (UUID, UUID) throws -> OfflinePost?,
                save: @escaping @MainActor (OfflinePost) throws -> Void,
                status: @escaping @MainActor (UUID) async throws -> UUID?,
                post: @escaping @MainActor (OfflinePost) async throws -> PostService.PostOutcome,
                upload: @escaping @MainActor (Data) async -> String?) {
      self.read = read; self.save = save; self.status = status; self.post = post; self.upload = upload
    }
  }

  public enum Outcome: Equatable, Sendable {
    /// The server accepted this request. `replayed` = a frozen envelope was
    /// sent again; `amended` = a different card was sent under the same id and
    /// won; `photoDropped` = the upload did not stick; `receiptUnsaved` = the
    /// round posted but the acceptance could not be written to disk.
    case accepted(PostService.PostOutcome, replayed: Bool, amended: Bool, photoDropped: Bool, receiptUnsaved: Bool)
    /// The disk already says this request landed. Finish the intent; send nothing.
    case alreadyPosted(UUID)
    /// The card was edited, but the earlier body under this id had already
    /// landed. The intent is finished with THAT round; the edit is a correction
    /// the golfer makes on the posted round, never a second one.
    case earlierPosted(UUID)
    /// The phone could not read or write its own record. Nothing was sent.
    case storageFailed(String)
    /// The server does not have `post_round_once` / `round_post_status`.
    case notAvailable
    /// The server said no, definitely, and wrote nothing. Same id; fix the card.
    case refused(String)
    /// Ambiguous transport. The envelope stays frozen; the same id retries.
    case failed(String)
  }

  public static let readFailed = "Couldn’t read the record of your last post attempt on this phone. Nothing was sent — try again in a moment."
  public static let pointerUnreadable = "The record of your last post attempt on this phone can’t be read, so nothing was sent. Reinstalling would clear it; until then, post from the web."
  public static let saveFailed = "Couldn’t keep a record of this post on your phone, so it wasn’t sent. Free up some space and press Post again."
  public static let notAvailableCopy = "Posting isn’t available on this server yet. Your round is kept here — try again after the update."
  public static let ambiguousPrefix = "Couldn’t confirm the post. Press Post again to retry the same round."
  public static let refusedSuffix = "Fix the card and press Post again — it’s still the same round."
  public static let alreadyPostedCopy = "This round already posted — it’s in your history."
  public static let earlierPostedCopy = "Your earlier card had already posted — here it is. To change it, delete that round from your history and post again."
  public static let earlierUnknownCopy = "Your earlier card may already have posted. Check your history before changing it — pressing Post again retries the same round."
  public static let receiptUnsavedCopy = "Round posted. Couldn’t record that on this phone — don’t post it again."
  public static let photoDroppedCopy = "Couldn’t upload the photo. Posting the round without it."
  public static let wrongGolferCopy = "Sign in as the golfer who started this round to post it."

  /// The server's own refusal of a second body under one id (20261021090000).
  public static func isConflict(_ error: Error) -> Bool {
    describe(error).localizedCaseInsensitiveContains("different scorecard")
  }
  /// Transport, not a verdict: the request may or may not have arrived.
  public static func isAmbiguous(_ error: Error) -> Bool {
    if error is URLError { return true }
    let m = describe(error).lowercased()
    return m.range(of: "failed to fetch|networkerror|network request|load failed|timed out|timeout|offline|could not connect|cancelled|canceled|connection", options: .regularExpression) != nil
  }
  static func describe(_ error: Error) -> String {
    ((error as? RpcError)?.underlying ?? "") + " " + ((error as? LocalizedError)?.errorDescription ?? String(describing: error))
  }

  /// One tap. Pure over its ports; the composer only narrates the outcome.
  @MainActor
  public static func run(owner: UUID, request: UUID, card: PostCard, payload: PostPayload,
                         playedWith: [UUID], jpeg: Data?, ports: Ports) async -> Outcome {
    // 1 · the record, or a clear stop
    let previous: OfflinePost?
    do { previous = try ports.read(owner, request) } catch { return .storageFailed(readFailed) }

    var envelope: OfflinePost
    var replayed = false
    var amended = false
    var photoDropped = false
    if let previous, let landed = previous.accepted {
      // 2 · finished already
      return .alreadyPosted(landed)
    }
    if let previous, previous.card == card, previous.playedWith == playedWith {
      // 3 · the same card: replay the frozen envelope verbatim
      envelope = previous
      replayed = true
    } else {
      // 4 / 5 · a fresh envelope, or an amendment under the SAME id. Written
      // to disk BEFORE the call either way.
      amended = previous != nil
      var frozen = payload
      if let jpeg {
        if let path = await ports.upload(jpeg) { frozen.photo_path = path } else { photoDropped = true }
      }
      envelope = OfflinePost(owner: owner, request: request, card: card, payload: frozen, playedWith: playedWith)
      do { try ports.save(envelope) } catch { return .storageFailed(saveFailed) }
    }

    // 6 / 7 · the call, and what each answer means
    let outcome: PostService.PostOutcome
    do { outcome = try await ports.post(envelope) } catch {
      if (error as? RpcError)?.isMissingFunction == true { return .notAvailable }
      if isConflict(error) {
        // the earlier body under this id already landed: find it, finish it
        do {
          if let landed = try await ports.status(request) {
            var done = envelope; done.accepted = landed
            try? ports.save(done)
            return .earlierPosted(landed)
          }
          return .failed(earlierUnknownCopy)
        } catch {
          if (error as? RpcError)?.isMissingFunction == true { return .notAvailable }
          return .failed(earlierUnknownCopy)
        }
      }
      if isAmbiguous(error) { return .failed(HumanError.text(error, prefix: ambiguousPrefix)) }
      return .refused(HumanError.text(error) + " " + refusedSuffix)
    }
    envelope.accepted = outcome.roundId
    var receiptUnsaved = false
    do { try ports.save(envelope) } catch { receiptUnsaved = true }
    return .accepted(outcome, replayed: replayed, amended: amended, photoDropped: photoDropped, receiptUnsaved: receiptUnsaved)
  }

  /// The real ports, over the shared disk and the service.
  @MainActor
  public static func livePorts(_ svc: PostService, owner: UUID) -> Ports {
    Ports(read: { o, r in try OfflinePostDisk.shared.read(owner: o, request: r) },
          save: { try OfflinePostDisk.shared.save($0) },
          status: { try await svc.postStatus(request: $0) },
          post: { try await svc.postOnce($0) },
          upload: { await svc.uploadPhoto($0, uid: owner) })
  }
}

/// D350 · the ordinary post's request identity, kept OUTSIDE the draft and
/// scoped to the golfer. The draft carries it too, but a draft can be cleared
/// ("Start over", a TTL) and the identity must outlive that: an id that dies
/// with the draft is an id the next tap regenerates, and a regenerated id is
/// how a committed round becomes two. Cleared only when the intent is
/// finished — the server accepted it, or the earlier body was found to have
/// landed. A value that is there but cannot be read is reported as such,
/// never treated as absent: absent mints, unreadable must not.
public enum PostRequestStore {
  public static let key = "cs_post_request"

  public enum Pending: Equatable, Sendable {
    case none
    case pending(UUID)
    /// Something is stored under the golfer's key and it is not a request id.
    case unreadable
  }

  static func name(_ owner: UUID) -> String { key + "." + owner.uuidString }

  public static func read(owner: UUID, defaults: UserDefaults = .standard) -> Pending {
    guard let raw = defaults.object(forKey: name(owner)) else { return .none }
    guard let s = raw as? String, let id = UUID(uuidString: s) else { return .unreadable }
    return .pending(id)
  }
  /// The id, when there is a readable one. Callers that must tell "none" from
  /// "unreadable" use `read`.
  public static func pending(owner: UUID, defaults: UserDefaults = .standard) -> UUID? {
    if case .pending(let id) = read(owner: owner, defaults: defaults) { return id }
    return nil
  }
  public static func set(_ id: UUID, owner: UUID, defaults: UserDefaults = .standard) {
    defaults.set(id.uuidString, forKey: name(owner))
  }
  public static func clear(owner: UUID, defaults: UserDefaults = .standard) {
    defaults.removeObject(forKey: name(owner))
  }
}
