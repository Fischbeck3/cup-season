// Cup Season — the data side of posting a round (audit 03 §2, §4).
//
// IOS-030 · the round is posted by the SERVER. `post_round` (R11) is the write:
// L-03 says a write with game consequences is an RPC, and this was the one
// consequential direct insert left on the phone. The season it scores for is
// derived server-side from `played_on` against every membership's window at
// that membership's own allowance (D229/L-13) — the client sends no league and
// no season, because one `season_id` could never express a golfer in two.
//
// The direct insert survives as the DECLARED FALLBACK and fires only on a
// function-missing error (PGRST202 / 42883): CLAUDE.md's deploy-skew rule
// covers new arguments and new columns, not a function that does not exist
// yet, and this is the composer's only post path. Its own skew retries are
// kept the phone's way — retry on ANY error by dropping `api_course_id`, then
// `photo_path`, never by sniffing the message (42501 never names its column) —
// and the served path does the same two drops inside the RPC.
//
// Everything else here is an RPC through `call`, a storage call, or an Edge
// Function — and every soft failure degrades to the typed path (D36: "cost
// fails closed; every failure lands on the two boxes").

import Foundation
import Supabase

public struct PostService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }
  private var db: SupabaseClient { svc.client }

  // MARK: - course memory (`loadCourseMemory`, 14092–14113)

  private struct MemoryRow: Decodable { let course_label: String?; let rating: Double?; let slope: Int?; let played_on: String? }

  /// Your last three courses, one tap on the quick post — from your own last
  /// 30 labelled rounds, newest first, one chip per label.
  public func courseMemory(_ uid: UUID) async -> [PostCourseMemory] {
    guard let rows: [MemoryRow] = try? await db.from("rounds").select("course_label, rating, slope, played_on")
      .eq("profile_id", value: uid).not("course_label", operator: .is, value: "null")
      .order("played_on", ascending: false).limit(30).execute().value else { return [] }
    var seen = Set<String>()
    var out: [PostCourseMemory] = []
    for r in rows {
      guard let label = r.course_label, !label.isEmpty, !seen.contains(label), let rating = r.rating, let slope = r.slope else { continue }
      seen.insert(label); out.append(PostCourseMemory(label: label, rating: rating, slope: slope))
      if out.count == 3 { break }
    }
    return out
  }

  // MARK: - the scan flag (`loadScanFlag`, 6579–6588) — fail closed

  private struct FlagRow: Decodable { let value: JSONValue? }

  /// true only when `app_flags.scan` exists and is not `enabled:false`.
  /// No row, no read, pre-migration: the button stays hidden.
  public func scanEnabled() async -> Bool {
    guard let rows: [FlagRow] = try? await db.from("app_flags").select("value").eq("key", value: "scan").limit(1).execute().value,
          let v = rows.first?.value, case .object = v else { return false }
    return v["enabled"]?.bool != false
  }

  // MARK: - the photo (6367–6377)

  /// Upload to the private bucket at `{uid}/{uuid}.jpg`. nil = "Photo didn't
  /// stick" — the round posts without it; the photo is garnish, the round is the fact.
  public func uploadPhoto(_ jpeg: Data, uid: UUID) async -> String? {
    let path = "\(uid.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
    do {
      _ = try await db.storage.from("media").upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: false))
      return path
    } catch { return nil }
  }

  // MARK: - the post (R11 `post_round`), with the insert as its declared fallback

  /// R11 · the write. **Hand-declared** rather than generated, because the
  /// migration that creates the function is written and unpushed — the
  /// documented shape while a migration awaits its contract refresh (preflight
  /// 17 tolerates it and still demands the grant).
  ///
  /// There is **no league or season argument**: D229 moved that derivation to
  /// the server, off `p_played_on` against every membership's window at that
  /// membership's own allowance (L-13). Every argument after the three the
  /// engine cannot score without is defaulted, so a database that has this
  /// function and a client that is older still meet.
  struct PostRoundCall: RpcCall {
    static let name = "post_round"
    static let optionalArgs: [String] = [
      "p_holes_played", "p_nine_rating", "p_course_id", "p_course_label",
      "p_played_on", "p_photo_path", "p_played_with",
    ]
    typealias Returns = JSONValue
    var p_gross: Int
    var p_rating: Double
    var p_slope: Int
    var p_holes_played: Int
    var p_nine_rating: Double?
    var p_course_id: String?
    var p_course_label: String?
    var p_played_on: String?
    var p_photo_path: String?
    var p_played_with: [UUID]
  }

  /// What came back from the post: the round's id, what the SERVER decided the
  /// round counts for, and the epilogue that rides back in the same response
  /// (so the ceremony and the epilogue never cost a second round trip).
  public struct PostOutcome: Sendable, Equatable {
    public let roundId: UUID
    public let seasonId: UUID?
    public let leagueName: String?
    public let squad: String?
    public let counts: Bool
    public let tagged: Int
    /// nil = the epilogue had nothing to say, or could not be read. Never a blocker.
    public let epilogue: PostEpilogue?
    /// true when the round went in through the declared fallback — the direct
    /// insert — because the server does not have `post_round` yet.
    public let viaFallback: Bool

    public init(roundId: UUID, seasonId: UUID? = nil, leagueName: String? = nil, squad: String? = nil,
                counts: Bool = false, tagged: Int = 0, epilogue: PostEpilogue? = nil, viaFallback: Bool = false) {
      self.roundId = roundId; self.seasonId = seasonId; self.leagueName = leagueName; self.squad = squad
      self.counts = counts; self.tagged = tagged; self.epilogue = epilogue; self.viaFallback = viaFallback
    }

    /// The RPC's `jsonb{round, epilogue}`, read the deploy-skew way: every key
    /// optional, an id that will not parse means the payload is not one we can
    /// trust and the caller falls back rather than inventing a round.
    public init?(json: JSONValue) {
      guard case .object = json,
            let idText = json["round"]?["id"]?.string, let id = UUID(uuidString: idText) else { return nil }
      let r = json["round"]
      self.init(roundId: id,
                seasonId: r?["season_id"]?.string.flatMap { UUID(uuidString: $0) },
                leagueName: r?["league_name"]?.string,
                squad: r?["squad"]?.string,
                counts: r?["counts"]?.bool ?? (r?["season_id"]?.string != nil),
                tagged: r?["tagged"]?.int ?? 0,
                epilogue: json["epilogue"].flatMap { PostEpilogue(json: $0) },
                viaFallback: false)
    }
  }

  /// The one condition the declared fallback fires on, as a value a test can
  /// hold: the function is not there yet. Anything else — a check constraint,
  /// a network failure, a refused rating — is a real error and is thrown, so a
  /// bad round never quietly takes the old path and posts anyway.
  public static func fallbackFires(on error: Error) -> Bool {
    (error as? RpcError)?.isMissingFunction == true
  }

  /// L-03 · the one consequential direct write on the phone becomes an RPC.
  ///
  /// `PostService.insertRound` is kept as the **declared fallback** and fires
  /// on a function-missing error (PGRST202 / 42883) — CLAUDE.md's skew rule
  /// covers new arguments and new columns, not a function that does not exist
  /// yet, and this is the only post path in the composer. The two skew retries
  /// (drop `api_course_id`, then `photo_path`) live inside the RPC now; the
  /// fallback keeps its own.
  ///
  /// `seasonId` is the fallback's ONLY use of a client-chosen season: on the
  /// served path the server derives it and the client sends nothing.
  public func postRound(_ payload: PostPayload, playedWith: [UUID] = [], fallbackSeason: UUID? = nil) async throws -> PostOutcome {
    do {
      let json = try await svc.call(PostRoundCall(
        p_gross: payload.gross, p_rating: payload.rating, p_slope: payload.slope,
        p_holes_played: payload.holes_played, p_nine_rating: payload.nine_rating,
        p_course_id: payload.api_course_id, p_course_label: payload.course_label,
        p_played_on: payload.played_on, p_photo_path: payload.photo_path,
        p_played_with: playedWith))
      if let out = PostOutcome(json: json) {
        CSTelemetry.product(.roundPosted)
        CSGrowth.log(.firstRoundPosted)
        return out
      }
      // the function answered with a shape we do not recognise: fall through
      // rather than tell a golfer their round posted when we cannot name it.
      throw RpcError(name: PostRoundCall.name, underlying: "post_round returned no round id", droppedArgs: [])
    } catch {
      guard Self.fallbackFires(on: error) else { throw error }
      var p = payload
      p.season_id = fallbackSeason
      let id = try await insertRound(p)
      return PostOutcome(roundId: id, seasonId: fallbackSeason, counts: fallbackSeason != nil,
                         epilogue: await epilogue(id), viaFallback: true)
    }
  }

  // MARK: - the insert (6378–6388) with the two skew retries — the DECLARED FALLBACK

  private struct IdRow: Decodable { let id: UUID }

  /// `insert into rounds … select id`. On ANY error, drop `api_course_id` and
  /// retry; on ANY error again, drop `photo_path` and retry; then throw.
  public func insertRound(_ payload: PostPayload) async throws -> UUID {
    var p = payload
    do { return try await insert(p) } catch {
      guard p.api_course_id != nil || p.photo_path != nil else { throw error }
      if p.api_course_id != nil {
        p.api_course_id = nil
        do { return try await insert(p) } catch { if p.photo_path == nil { throw error } }
      }
      p.photo_path = nil
      return try await insert(p)
    }
  }

  private func insert(_ p: PostPayload) async throws -> UUID {
    let row: IdRow = try await db.from("rounds").insert(p).select("id").single().execute().value
    CSTelemetry.product(.roundPosted)   // IOS-024: the insert is the fact; holes/photo are garnish
    CSGrowth.log(.firstRoundPosted)     // the server no-ops unless this was the golfer's first
    return row.id
  }

  /// Best-effort — a `round_holes` hiccup never un-posts the round (6396–6401).
  public func insertHoles(_ rows: [PostHoleRow]) async {
    guard !rows.isEmpty else { return }
    _ = try? await db.from("round_holes").insert(rows).execute()
  }

  // MARK: - breadcrumbs (`qaEvent`, 6099–6105)

  /// Fire-and-forget into `client_events`; every failure is swallowed — a
  /// breadcrumb must never break a post. One writer since IOS-024: `CSTelemetry`.
  public func event(_ name: String, _ props: [String: JSONValue] = [:]) {
    CSTelemetry.event(name, props)
  }

  // MARK: - after the post

  /// `round_epilogue(p_round)` — nil on skew or nothing to say; never blocks a post.
  public func epilogue(_ roundId: UUID) async -> PostEpilogue? {
    guard let json = try? await svc.call(Rpc.round_epilogue(p_round: roundId)) else { return nil }
    return PostEpilogue(json: json)
  }

  /// A seed for the receipt cache so the round opens instantly from any surface.
  public func remember(roundId: UUID, payload: PostPayload, profileId: UUID, marker: String?) async {
    await ReceiptCache.shared.put(ReceiptSeed(id: roundId, profileId: profileId, gross: payload.gross, playedOn: payload.played_on ?? CSDate.today(),
                                              courseLabel: payload.course_label, holesPlayed: payload.holes_played, photoPath: payload.photo_path,
                                              rating: payload.rating, slope: payload.slope, nineRating: payload.nine_rating, isMine: true, marker: marker))
  }

  // MARK: - the share link (D57 `csShareLink` 5864, D60 the photo travels)

  private struct PhotoRow: Decodable { let photo_path: String? }

  /// `create_share('round', id)` → the public page's URL. A shared round with
  /// a photo publishes a compressed copy to `shared/{token}.jpg` — best effort,
  /// the link works photo-less if any step misses. `compress` is the app's
  /// JPEG downscale (1600px, q.8) — image work stays out of the kit.
  public func shareLink(round id: UUID, compress: @Sendable (Data) async -> Data?) async throws -> URL {
    let token = try await svc.call(Rpc.create_share(p_kind: "round", p_ref: id))
    let name = token.uuidString.lowercased()
    CSGrowth.log(.artifactShared, kind: "share", token: name)   // the share ACTION, not a render
    do {
      let rows: [PhotoRow] = try await db.from("rounds").select("photo_path").eq("id", value: id).limit(1).execute().value
      if let path = rows.first?.photo_path {
        let head = try await db.storage.from("shared").list(path: "", options: SearchOptions(limit: 1, search: name + ".jpg"))
        if !head.contains(where: { $0.name == name + ".jpg" }) {
          let signed = try await db.storage.from("media").createSignedURL(path: path, expiresIn: 60)
          let (data, _) = try await URLSession.shared.data(from: signed)
          if let jpg = await compress(data) {
            do {
              _ = try await db.storage.from("shared").upload(name + ".jpg", data: jpg, options: FileOptions(contentType: "image/jpeg", upsert: false))
            } catch {
              let m = SupabaseService.describe(error).lowercased()
              if !(m.contains("exists") || m.contains("duplicate")) { throw error }
            }
          }
        }
      }
    } catch { /* [share photo] link ships photo-less */ }
    return URL(string: "https://cupseason.app/?share=\(name)")!
  }

  /// `csRevokeLink`: re-mint the live token, then kill it. A fresh share later
  /// mints a NEW token — revoked copies stay dark.
  public func revokeLink(round id: UUID) async throws {
    let token = try await svc.call(Rpc.create_share(p_kind: "round", p_ref: id))
    _ = try await svc.call(Rpc.revoke_share(p_token: token))
  }

  // MARK: - the scan (6590–6618)

  public enum ScanOutcome: Sendable, Equatable {
    case read(PostScan)
    /// `{unavailable, reason}` — `daily_cap` / `disabled` / anything else
    case unavailable(reason: String?)
    /// no players, or the function could not be reached
    case unreadable
  }

  private struct ScanBody: Encodable { let image: String; let media_type: String }

  /// The `scan` Edge Function reads the card (2200px JPEG, base64 in the body).
  public func scan(jpeg: Data) async -> ScanOutcome {
    do {
      let reply: JSONValue = try await db.functions.invoke("scan", options: .init(body: ScanBody(image: jpeg.base64EncodedString(), media_type: "image/jpeg")))
      if reply["unavailable"]?.bool == true { return .unavailable(reason: reply["reason"]?.string) }
      guard reply["ok"]?.bool == true, let scan = PostScan(json: reply) else { return .unreadable }
      return .read(scan)
    } catch { return .unavailable(reason: nil) }
  }

  // MARK: - partner claims (`scanPartnersSheet`, 6658–6692)

  /// What the partner rows need from the post, captured BEFORE the form clears.
  public struct ClaimContext: Sendable, Equatable {
    public let courseLabel: String?
    public let rating: Double
    public let slope: Int
    public let playedOn: String
    public let holes: Int
    public init(courseLabel: String?, rating: Double, slope: Int, playedOn: String, holes: Int = 18) {
      self.courseLabel = courseLabel; self.rating = rating; self.slope = slope; self.playedOn = playedOn; self.holes = holes
    }
  }

  /// `create_scan_claim` — the token behind `/?claim=`.
  public func mintClaim(_ p: PostScanPlayer, ctx: ClaimContext) async throws -> UUID {
    let token: UUID = try await svc.call(Rpc.create_scan_claim(
      p_name: p.name ?? "", p_gross: p.total ?? 0, p_strokes: .array(p.holes.map { .number(Double($0)) }),
      p_course: ctx.courseLabel ?? "", p_rating: ctx.rating, p_slope: ctx.slope, p_played: ctx.playedOn, p_holes: ctx.holes))
    CSGrowth.log(.artifactShared, kind: "claim", token: token.uuidString.lowercased())
    return token
  }

  public static func claimURL(_ token: UUID) -> URL { URL(string: "https://cupseason.app/?claim=\(token.uuidString.lowercased())")! }

  // MARK: - real pars from the course cache (`onTee` 6883–6897)

  private struct TeeRow: Decodable { let id: UUID; let tee_name: String?; let number_of_holes: Int?; let course_rating: Double? }
  private struct HoleRow: Decodable { let hole_number: Int; let par: Int? }

  /// After the `courses {action:'cache'}` call: the picked tee's holes, in
  /// order. nil on a cache miss = the typed path; the holes choice stands.
  public func teePars(courseId: String, teeName: String?, rating: Double?) async -> (pars: [Int], nine: Bool)? {
    guard let tees: [TeeRow] = try? await db.from("api_course_tees").select("id, tee_name, number_of_holes, course_rating")
      .eq("course_id", value: courseId).execute().value, !tees.isEmpty else { return nil }
    let picked = tees.first { $0.tee_name == teeName && $0.course_rating == rating } ?? tees.first { $0.tee_name == teeName } ?? tees[0]
    guard let holes: [HoleRow] = try? await db.from("api_course_holes").select("hole_number, par")
      .eq("tee_id", value: picked.id).order("hole_number", ascending: true).execute().value, !holes.isEmpty else { return nil }
    return (holes.map { $0.par ?? 4 }, picked.number_of_holes == 9)
  }
}
