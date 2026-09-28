// Cup Season — synthetic WRITES, table reads and storage.
//
// A write in a synthetic launch is answered here, on the device, with the
// deterministic response its RPC would give — and it is logged `WRITE`. It
// never leaves the device, it never mints anything real, and it changes only
// `SynthState` for the rest of this launch. The list of every RPC that can be
// answered as a write is `writeNames`; anything else that mutates is a MISS.

#if DEBUG
import Foundation
import UIKit
import CupSeasonKit

extension SyntheticWorld {
  /// Every mutating RPC the fixture answers. Reads are everything else. Each
  /// is answered on the device with the shape its caller decodes, and none
  /// of them leaves the simulator.
  static let writeNames: Set<String> = [
    "log_growth_event", "register_device_token", "unregister_device_token", "mark_notifications_read",
    "mark_actionable_seen", "set_round_rsvp", "set_round_thread_state", "add_posted_round_comment",
    "remove_posted_round_comment", "add_round_comment", "report_content", "set_mute", "set_social_notify_prefs",
    "friend_request", "friend_respond", "unfriend", "set_profile", "set_handle", "set_index", "set_discoverable",
    "set_email_recap", "set_notify_rounds", "set_notify_chat", "set_scan_consent", "submit_feedback", "founder_note",
    "save_bag", "rate_course", "unrate_course", "post_round", "post_round_once", "finish_round_share",
    "prepare_round_share", "withdraw_round_shares", "create_share", "revoke_share", "confirm_share_cleanup",
    "declare_round", "scratch_round", "retag_round", "ask_for_a_seat", "confirm_round_partner", "set_event_notify",
    "set_rivalry_name", "hide_content", "unhide_content", "answer_plan_followup", "respond_invite", "delete_account",
    "set_event_team", "generate_pairings", "resolve_session", "delete_event", "enter_major", "open_major", "settle_major",
    "create_event", "create_major", "invite_golfer", "call_out", "respond_callout", "create_forfeit", "create_scan_claim",
    "finish_live_round", "abandon_live_round", "live_join", "start_live_round", "start_live_round_from_plan",
    "live_set_score", "live_set_wolf", "join_league", "mark_buy_in", "adjust_points", "set_member_bye",
    "set_round_photo", "clear_round_photo", "delete_round", "claim_round", "claim_scan_round",
  ]

  func isWrite(_ r: SynthRequest) -> Bool {
    switch r.kind {
    case .rpc(let name): return Self.writeNames.contains(name)
    case .table: return r.method != "GET" && r.method != "HEAD"
    case .storageObject: return r.method == "POST" || r.method == "PUT" || r.method == "DELETE"
    case .broadcast: return true
    default: return false
    }
  }

  func writeRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    guard Self.writeNames.contains(name) else { return nil }
    switch name {
    case "log_growth_event", "register_device_token", "unregister_device_token", "set_round_rsvp",
         "set_mute", "report_content", "set_discoverable", "set_notify_rounds", "set_notify_chat",
         "set_event_notify", "set_rivalry_name", "hide_content", "unhide_content", "set_index",
         "mark_buy_in", "adjust_points", "set_member_bye", "delete_round", "clear_round_photo", "set_round_photo":
      return SynthOut.void
    case "set_handle":
      state.set("handle", r.string("p_handle") ?? me.handle); return SynthOut.void
    case "set_profile":
      if let n = r.string("p_name") { state.set("name", n) }
      if let m = r.string("p_marker") { state.set("marker", m) }
      if scenario == .cardGate, state.get("handle", "") == "" { state.set("handle", me.handle) }
      return SynthOut.void
    case "mark_actionable_seen": return SynthOut.json(0)
    case "mark_notifications_read": return SynthOut.json(["ok": true, "unread": 0])
    case "set_round_thread_state", "remove_posted_round_comment": return SynthOut.json(["ok": true])
    case "confirm_share_cleanup": return SynthOut.json(["status": "completed", "remaining": 0])
    case "withdraw_round_shares": return SynthOut.json([fids(8_202)])
    case "prepare_round_share":
      return SynthOut.json(["token": fids(8_202), "created": true, "include_photo": (r.params["p_include_photo"] as? Bool) ?? false,
                            "state": "prepared", "active": true])
    case "finish_round_share":
      return SynthOut.json(["attempt": r.string("p_attempt") ?? fids(8_203), "state": "completed", "token": fids(8_202),
                            "created": true, "active": true, "cleanup_pending": false])
    case "create_scan_claim": return SynthOut.json(fids(8_301))
    case "post_round_once", "post_round": return postRound(r)
    case "join_league": return SynthOut.json(fids(1_003))
    default:
      return SynthOut.json(["ok": true])
    }
  }

  /// A posted round, answered on the device. `-cs_synth_post_fail` makes the
  /// server refuse it (the composer's failure toast), `offline` fails it at
  /// the transport before it gets here.
  func postRound(_ r: SynthRequest) -> SyntheticReply {
    if ProcessInfo.processInfo.arguments.contains("-cs_synth_post_fail") {
      return SynthOut.error("Hole scores do not match gross", code: "P0001", status: 400)
    }
    let payload = (r.params["p_payload"] as? [String: Any]) ?? [:]
    let gross = (payload["gross"] as? NSNumber)?.intValue ?? 84
    let l = leagues.first
    let first = myRounds.isEmpty
    return SynthOut.json([
      "round": ["id": fids(4_901), "season_id": l?.seasonIds ?? NSNull(), "league_id": l?.ids ?? NSNull(),
                "league_name": l?.name ?? NSNull(), "squad": NSNull(), "played_on": payload["played_on"] ?? day(0),
                "gross": gross, "holes_played": payload["holes_played"] ?? 18, "course_label": payload["course_label"] ?? courses[0].name,
                "api_course_id": payload["api_course_id"] ?? NSNull(), "photo_path": NSNull(), "counts": l != nil, "tagged": 0],
      "epilogue": [
        "gross": gross, "holes": payload["holes_played"] ?? 18, "pvi": 1.6, "points": l == nil ? NSNull() as Any : 9 as Any,
        "month_rank": 2, "earned": first ? [["kind": "first_round", "label": NSNull()]] : [["kind": "personal_best", "label": NSNull()]],
        "rivals": hasBuddies ? [["name": person(2).name, "handle": person(2).handle, "wins": 3, "losses": 1, "ties": 0, "lead": "up",
                                 "rivalry_name": "The Grove Grudge (fixture)"]] : [[String: Any]](),
        "season_id": l?.seasonIds ?? NSNull(), "rank_before": 3, "rank_after": 2, "of": l?.members.count ?? 0,
        "passed": l == nil ? [String]() : [person(4).first], "gap_to_next_after": 2, "played_with": [[String: Any]](),
      ] as [String: Any],
    ])
  }

  func writeTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? {
    let table = t.components(separatedBy: "?").first ?? t
    switch table {
    case "client_events", "post_kudos", "posts", "post_comments":
      let prefer = r.headers["Prefer"] ?? r.headers["prefer"] ?? ""
      if prefer.contains("return=representation") {
        var row = r.params
        row["id"] = row["id"] ?? fids(8_800 + state.next("row"))
        return SynthOut.json([row], status: 201)
      }
      return SyntheticReply(status: 201, headers: [:], body: Data())
    default:
      return nil
    }
  }

  func readTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? {
    let table = t.components(separatedBy: "?").first ?? t
    let areas: [(String, SynthRequest) -> SyntheticReply?] = [homeTable, seasonTable, eventsTable, youTable, coursesTable, roundsTable]
    for area in areas { if let reply = area(table, r) { return reply } }
    return nil
  }

  // MARK: storage

  /// Signed URLs point back at the synthetic host; downloading one returns the
  /// DRAWN stand-in photograph (`ReceiptPhotoDev.image` — a sky, a horizon and
  /// a ground mass, no place and no face), or 404 for a broken photo.
  func storage(_ r: SynthRequest) -> SyntheticReply? {
    switch r.kind {
    case .storageSign(let bucket, let path):
      if let path {
        // Avatars: no golfer in this world has a profile photograph, so the
        // sign is refused the way storage refuses a missing object.
        if path.hasSuffix("/avatar.jpg") {
          return SynthOut.json(["statusCode": "404", "error": "not_found", "message": "Object not found"], status: 400)
        }
        return SynthOut.json(["signedURL": "/object/sign/\(bucket)/\(path)?token=synthetic"])
      }
      let paths = (r.params["paths"] as? [String]) ?? []
      return SynthOut.json(paths.map { ["path": $0, "signedURL": "/object/sign/\(bucket)/\($0)?token=synthetic", "error": NSNull()] as [String: Any] })
    case .storageObject(let bucket, let path):
      if bucket == "list" || (r.method == "DELETE" && (r.params["prefixes"] != nil)) {
        return SynthOut.json([Any]())   // a listing or a removal: nothing kept
      }
      if r.method != "GET" && r.method != "HEAD" {
        return SynthOut.json(["Key": "\(bucket)/\(path)", "Id": fids(8_900)])
      }
      if brokenPaths.contains(where: { path.hasSuffix($0) }) {
        // Storage's own error shape: `statusCode` is a STRING, or the client
        // cannot tell a denied object from a transient failure.
        return SynthOut.json(["statusCode": "404", "error": "not_found", "message": "Object not found"], status: 404)
      }
      return SynthOut.bytes(Self.photoBytes(for: path), type: "image/jpeg")
    default:
      return nil
    }
  }

  var brokenPaths: [String] { rounds.filter { $0.photo == .broken }.compactMap(\.photoPath) }

  /// One drawn photograph, mirrored or cropped by the path's hash so two
  /// rounds never wear the identical picture. No colour is invented here.
  static func photoBytes(for path: String) -> Data {
    let base = ReceiptPhotoDev.image
    let variant = path.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % 997 } % 3
    let size = base.size
    let out = UIGraphicsImageRenderer(size: size).image { ctx in
      switch variant {
      case 1:
        ctx.cgContext.translateBy(x: size.width, y: 0); ctx.cgContext.scaleBy(x: -1, y: 1)
        base.draw(in: CGRect(origin: .zero, size: size))
      case 2:
        base.draw(in: CGRect(x: -size.width * 0.15, y: -size.height * 0.1, width: size.width * 1.3, height: size.height * 1.3))
      default:
        base.draw(in: CGRect(origin: .zero, size: size))
      }
    }
    return out.jpegData(compressionQuality: 0.82) ?? Data()
  }
}
#endif
