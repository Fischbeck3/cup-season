// Cup Season — the growth funnel, from the phone (spec/claim-loop-
// instrumentation.md; migration 20260828160000_growth_events).
//
//   artifact_shared → link_opened → claim_started → profile_created → first_round_posted
//
// One writer, `log_growth_event()`, callable signed-out — the whole point is
// the edge `CSTelemetry` cannot see (a non-user opening a link). The server is
// fail-closed: a token that resolves to nothing logs nothing and answers the
// same void, `first_round_posted` is decided by the rounds count, and
// `profile_created` writes the profile's attribution once. So the phone just
// reports the moment; it never decides the fact. Fire-and-forget like
// `CSTelemetry.event`: never throws, never blocks, and a missing function
// (deploy skew) is swallowed.
//
// Hand-rolled `RpcCall` rather than `Rpc.log_growth_event` — the generated
// surface follows the prod snapshot (tools/build-db.mjs) and picks the name up
// after the push; the mirror stays byte-for-byte on the SQL signature.
// Never PII in props (the server strips the obvious keys anyway).

import Foundation

public enum CSGrowth {
  public enum Node: String, Sendable {
    case artifactShared = "artifact_shared"
    case linkOpened = "link_opened"
    case claimStarted = "claim_started"
    case profileCreated = "profile_created"
    case firstRoundPosted = "first_round_posted"
  }

  struct Call: RpcCall {
    static let name = "log_growth_event"
    static let optionalArgs: [String] = ["p_kind", "p_token", "p_props", "p_league"]
    typealias Returns = RpcVoid
    let p_node: String
    let p_kind: String?
    let p_token: String?
    let p_props: JSONValue
    let p_league: UUID?
  }

  /// `kind` is one of share · claim · join · recap · settlement (nil = none).
  public static func log(_ node: Node, kind: String? = nil, token: String? = nil,
                         league: UUID? = nil, props: [String: JSONValue] = [:]) {
    let call = Call(p_node: node.rawValue, p_kind: kind, p_token: token, p_props: .object(props), p_league: league)
    Task.detached(priority: .utility) {
      _ = try? await SupabaseService.shared.call(call)
    }
  }

  /// `profile_created` with the door's attribution: a pending claim wins over a
  /// pending join (the web's `resumeAfterProfile` order), else direct.
  public static func profileCreated() {
    if let claim = ClaimIntent.pending() {
      log(.profileCreated, kind: "claim", token: claim.uuidString.lowercased(), props: ["via": .string("claim")])
    } else if let join = JoinIntent.pending() {
      log(.profileCreated, kind: "join", token: join.code, props: ["via": .string("join")])
    } else {
      log(.profileCreated, props: ["via": .string("direct")])
    }
  }
}
