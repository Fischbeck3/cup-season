import Testing
import Foundation
@testable import CupSeasonKit

/// W2 (D380) · the consent plan is the desk's, case for case (tests/app-tests.js "W2").
@Suite struct ShareConsentTests {
  @Test func theCopiesFollowTheAnswerOnAReusedToken() {
    #expect(ShareConsent.plan(hadPhoto: true, hadCard: true, includePhoto: false) == .init(remint: true, publishPhoto: false))
    #expect(ShareConsent.plan(hadPhoto: false, hadCard: false, includePhoto: true) == .init(remint: false, publishPhoto: true))
    #expect(ShareConsent.plan(hadPhoto: false, hadCard: true, includePhoto: true) == .init(remint: true, publishPhoto: true))
    #expect(ShareConsent.plan(hadPhoto: false, hadCard: false, includePhoto: false) == .init(remint: false, publishPhoto: false))
    #expect(ShareConsent.plan(hadPhoto: true, hadCard: true, includePhoto: true) == .init(remint: false, publishPhoto: true))
    // a declined photo with no card yet: the jpg goes with the token, nothing is published
    #expect(ShareConsent.plan(hadPhoto: true, hadCard: false, includePhoto: false) == .init(remint: true, publishPhoto: false))
    // The card upload succeeded with a photo but the separate JPEG failed.
    // Opting out must not reuse that photo-bearing PNG.
    #expect(ShareConsent.plan(hadPhoto: false, hadCard: true, includePhoto: false) == .init(remint: true, publishPhoto: false))
  }

  @Test func theWordsPromiseNothingARemintCannotDo() {
    #expect(RoundCopy.photoInclude == "Include round photo")
    #expect(ShareConsent.fine.contains("already saved stays with them"))
  }
}
