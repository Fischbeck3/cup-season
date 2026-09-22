// Cup Season — photo consent on a shared round (W2, D380; amends D60).
//
// A round's link carries two public copies: `shared/{token}.png` (the card that
// went into the message — the link's preview) and `shared/{token}.jpg` (the
// round's photo — the public page's ground). Both are snapshots on a token
// `create_share` re-returns for as long as it lives, so the golfer's answer to
// "include round photo" has to govern a REUSED token too: when the copies on
// the token disagree with the answer, the copies are removed, the token is
// revoked and a fresh one is minted. Pure, so it is pinned in the Kit tests;
// the desk's `csShareConsentPlan` is its twin, word for word in behaviour.
//
// What no re-mint can do is take back a preview a messaging app already saved
// — the fine print says so, and nothing here promises otherwise.

import Foundation

public enum ShareConsent {
  public struct NotReady: LocalizedError, Sendable {
    public init() {}
    public var errorDescription: String? { "Round sharing needs the latest update. Try again shortly." }
  }
  public struct Plan: Sendable, Equatable {
    /// The copies and the token go, and a fresh token is minted.
    public let remint: Bool
    /// The photo copy is published (on a yes only).
    public let publishPhoto: Bool
    public init(remint: Bool, publishPhoto: Bool) { self.remint = remint; self.publishPhoto = publishPhoto }
  }

  /// `hadPhoto`: a `.jpg` copy exists on the token. `hadCard`: a `.png` copy
  /// exists. `includePhoto`: the golfer's answer for this share.
  public static func plan(hadPhoto: Bool, hadCard: Bool, includePhoto: Bool) -> Plan {
    // A PNG can contain the photo even if the separate JPEG upload failed.
    // Its pixels carry no consent metadata: an opt-out must replace it too.
    Plan(remint: (!includePhoto && (hadPhoto || hadCard)) || (!hadPhoto && includePhoto && hadCard),
         publishPhoto: includePhoto)
  }

  /// The words on the share sheet, twins of the desk's.
  public static let fine = "It shows on the public page and in the link’s preview. Turning it off later makes a new link; a preview a messaging app already saved stays with them."
}
