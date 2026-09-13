// Cup Season — the ordinary post, run once however many times Post is pressed
// (D350, built 2026-09-13).
//
// Everything the composer used to do inline — read the envelope, decide
// whether this tap is a replay, upload the photo, freeze the envelope, save it
// BEFORE the network, call the server, record what came back — is here, with
// every port injected, so the fault paths are tests rather than promises:
// a disk that cannot be read, a disk that cannot be written, a response that
// never arrived, an app that relaunched, a golfer who edited the card after
// an ambiguous failure, a server that does not have the function yet.
//
// The rules, in order:
//   1. A read that fails stops everything. Nothing is sent, the draft stays.
//   2. An envelope the server already accepted is finished, never re-sent.
//   3. An envelope that matches this card is replayed VERBATIM — photo path,
//      holes and partners included. No second upload, no recomputed payload.
//   4. An envelope that does NOT match is resolved by asking the server
//      (`round_post_status`, read-only) whether it landed. Landed → the old
//      form is finished and this card is a new round. Not landed → the old id
//      is released and this card posts under a new one.
//   5. A fresh envelope is written to disk before the call; a write that fails
//      stops everything, with a message about the phone, not the network.
//   6. The server not having the function is fail-closed: nothing else is
//      tried, the draft and the frozen request stay, and the copy says so.
//      There is no fallback to a function that cannot deduplicate.

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
    /// sent again; `photoDropped` = the upload did not stick on a fresh
    /// envelope; `receiptUnsaved` = the round posted but the acceptance could
    /// not be written to disk, so the composer must warn against a re-post.
    case accepted(PostService.PostOutcome, replayed: Bool, photoDropped: Bool, receiptUnsaved: Bool)
    /// The disk already says this request landed. Finish the form; send nothing.
    case alreadyPosted(UUID)
    /// The card was edited after an ambiguous failure, and the server says the
    /// earlier envelope DID land. The old form is done; this card is a new round.
    case earlierPosted(UUID)
    /// The card was edited after an ambiguous failure, and the server says the
    /// earlier envelope never landed. Release the id; post under a new one.
    case staleRequest
    /// The phone could not read or write its own record. Nothing was sent.
    case storageFailed(String)
    /// The server does not have `post_round_once` / `round_post_status`.
    /// Nothing else is tried. The draft and the request stay.
    case notAvailable
    /// Ambiguous or refused. The envelope stays frozen; the same id retries.
    case failed(String)
  }

  public static let readFailed = "Couldn’t read the record of your last post attempt on this phone. Nothing was sent — try again in a moment."
  public static let saveFailed = "Couldn’t keep a record of this post on your phone, so it wasn’t sent. Free up some space and press Post again."
  public static let notAvailableCopy = "Posting isn’t available on this server yet. Your round is kept here — try again after the update."
  public static let ambiguousPrefix = "Couldn’t confirm the post. Press Post again to retry the same round."
  public static let alreadyPostedCopy = "This round already posted — it’s in your history."
  public static let earlierPostedCopy = "Your earlier round posted and is in your history. This card is a new round — press Post to add it."
  public static let receiptUnsavedCopy = "Round posted. Couldn’t record that on this phone — don’t post it again."
  public static let photoDroppedCopy = "Couldn’t upload the photo. Posting the round without it."
  public static let wrongGolferCopy = "Sign in as the golfer who started this round to post it."

  /// One tap. Pure over its ports; the composer only narrates the outcome.
  @MainActor
  public static func run(owner: UUID, request: UUID, card: PostCard, payload: PostPayload,
                         playedWith: [UUID], jpeg: Data?, ports: Ports) async -> Outcome {
    // 1 · the record, or a clear stop
    let previous: OfflinePost?
    do { previous = try ports.read(owner, request) } catch { return .storageFailed(readFailed) }

    var envelope: OfflinePost
    var replayed = false
    var photoDropped = false
    if let previous {
      // 2 · finished already
      if let landed = previous.accepted { return .alreadyPosted(landed) }
      // 3 · the same card: replay the frozen envelope verbatim
      if previous.card == card && previous.playedWith == playedWith {
        envelope = previous
        replayed = true
      } else {
        // 4 · a different card under a resolved-unknown request: ask, never guess
        do {
          if let landed = try await ports.status(request) {
            var done = previous; done.accepted = landed
            try? ports.save(done)
            return .earlierPosted(landed)
          }
          return .staleRequest
        } catch {
          if (error as? RpcError)?.isMissingFunction == true { return .notAvailable }
          return .failed(HumanError.text(error, prefix: "Couldn’t confirm your earlier post."))
        }
      }
    } else {
      // 5 · a fresh envelope: upload, freeze, write BEFORE the network
      var frozen = payload
      if let jpeg {
        if let path = await ports.upload(jpeg) { frozen.photo_path = path } else { photoDropped = true }
      }
      envelope = OfflinePost(owner: owner, request: request, card: card, payload: frozen, playedWith: playedWith)
      do { try ports.save(envelope) } catch { return .storageFailed(saveFailed) }
    }

    // 6 · the call, with the one skew case fail-closed
    let outcome: PostService.PostOutcome
    do { outcome = try await ports.post(envelope) } catch {
      if (error as? RpcError)?.isMissingFunction == true { return .notAvailable }
      return .failed(HumanError.text(error, prefix: ambiguousPrefix))
    }
    envelope.accepted = outcome.roundId
    var receiptUnsaved = false
    do { try ports.save(envelope) } catch { receiptUnsaved = true }
    return .accepted(outcome, replayed: replayed, photoDropped: photoDropped, receiptUnsaved: receiptUnsaved)
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
/// how a committed round becomes two. Cleared only when the server's answer has
/// been recovered — an acceptance, or a status read that says it never landed.
public enum PostRequestStore {
  public static let key = "cs_post_request"

  static func name(_ owner: UUID) -> String { key + "." + owner.uuidString }

  public static func pending(owner: UUID, defaults: UserDefaults = .standard) -> UUID? {
    defaults.string(forKey: name(owner)).flatMap(UUID.init(uuidString:))
  }
  public static func set(_ id: UUID, owner: UUID, defaults: UserDefaults = .standard) {
    defaults.set(id.uuidString, forKey: name(owner))
  }
  public static func clear(owner: UUID, defaults: UserDefaults = .standard) {
    defaults.removeObject(forKey: name(owner))
  }
}
