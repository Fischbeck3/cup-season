import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct SignedURLCacheTests {
  @Test("a signing call in flight when the cache is cleared for a new account does not repopulate it")
  func inFlightSigningCannotRepopulateAClearedCache() async {
    let cache = SignedURLCache()
    let u = URL(string: "sig://media/a.png?t=1")!
    let r = await cache.resolve(["a.png"]) { _ in
      await cache.clear()                    // the account changed while we were signing
      return ["a.png": .url(u)]
    }
    #expect(r.urls["a.png"] == u, "the caller still gets this load's answer")
    #expect(await cache.count == 0, "but the cleared cache did not keep it")
  }

  @Test("denied is forgotten, unavailable is reported, a good URL is kept until near expiry")
  func outcomes() async {
    let cache = SignedURLCache()
    let u = URL(string: "sig://media/a.png?t=1")!
    let r = await cache.resolve(["a.png", "b.png", "c.png"]) { _ in ["a.png": .url(u), "b.png": .denied] }
    #expect(r.urls["a.png"] == u && r.denied.contains("b.png") && r.unavailable.contains("c.png"))
    var signed = 0
    let again = await cache.resolve(["a.png"]) { _ in signed += 1; return [:] }
    #expect(again.urls["a.png"] == u && signed == 0, "an unexpired path is not signed again")
  }
}
