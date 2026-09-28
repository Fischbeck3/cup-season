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
  /// Every mutating RPC the fixture answers. Reads are everything else.
  static let writeNames: Set<String> = [
    "log_growth_event", "register_device_token", "unregister_device_token", "mark_notifications_read",
    "mark_actionable_seen", "set_round_rsvp", "set_round_thread_state", "add_posted_round_comment",
    "remove_posted_round_comment", "add_round_comment", "report_content", "set_mute", "set_social_notify_prefs",
    "friend_request", "friend_respond", "set_profile", "set_handle", "set_index", "set_discoverable",
    "set_email_recap", "set_notify_rounds", "set_notify_chat", "set_scan_consent", "submit_feedback",
    "save_bag", "rate_course", "unrate_course", "post_round", "post_round_once", "finish_round_share",
    "prepare_round_share", "withdraw_round_shares", "create_share", "revoke_share", "confirm_share_cleanup",
    "declare_round", "set_event_notify", "set_rivalry_name", "hide_content", "unhide_content",
  ]

  func isWrite(_ r: SynthRequest) -> Bool {
    switch r.kind {
    case .rpc(let name): return Self.writeNames.contains(name)
    case .table: return r.method != "GET" && r.method != "HEAD"
    case .storageObject: return r.method == "POST" || r.method == "PUT" || r.method == "DELETE"
    default: return false
    }
  }

  func writeRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    guard Self.writeNames.contains(name) else { return nil }
    switch name {
    case "log_growth_event", "register_device_token", "unregister_device_token", "set_round_rsvp",
         "set_mute", "report_content", "set_discoverable", "set_email_recap", "set_notify_rounds",
         "set_notify_chat", "set_scan_consent", "submit_feedback", "set_event_notify", "set_rivalry_name",
         "hide_content", "unhide_content", "mark_actionable_seen":
      return SynthOut.void
    case "mark_notifications_read":
      return SynthOut.json(["ok": true, "unread": 0])
    case "set_round_thread_state", "remove_posted_round_comment", "confirm_share_cleanup":
      return SynthOut.json(["ok": true])
    default:
      return writeSpecial(name, r)
    }
  }

  /// Writes whose answer carries data; filled by the area that owns them.
  func writeSpecial(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    SynthOut.json(["ok": true])
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
        return SynthOut.json(["signedURL": "/object/sign/\(bucket)/\(path)?token=synthetic"])
      }
      let paths = (r.params["paths"] as? [String]) ?? []
      return SynthOut.json(paths.map { ["path": $0, "signedURL": "/object/sign/\(bucket)/\($0)?token=synthetic", "error": NSNull()] as [String: Any] })
    case .storageObject(_, let path):
      if r.method != "GET" && r.method != "HEAD" {
        return SynthOut.json(["Key": path, "Id": fids(8_900)])
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
