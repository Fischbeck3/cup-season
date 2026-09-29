import Testing
import Foundation
@testable import CupSeasonKit

/// N4-013 · Home's stale line said "offline" for every failed read. Only the
/// transport's own no-network answers are "offline" now; a server that
/// answered with an error, or a read that timed out on a signal, is not.
@Suite struct HumanErrorOfflineTests {
  @Test func onlyTheTransportsNoNetworkAnswersAreOffline() {
    for code: URLError.Code in [.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff] {
      #expect(HumanError.isOffline(URLError(code)), "\(code)")
    }
    for code: URLError.Code in [.badServerResponse, .timedOut, .cannotParseResponse, .userAuthenticationRequired] {
      #expect(!HumanError.isOffline(URLError(code)), "\(code)")
    }
  }

  @Test func aWrappedTransportErrorStillReadsAsNoSignal() {
    let wrapped = NSError(domain: "PostgREST", code: 1,
                          userInfo: [NSUnderlyingErrorKey: URLError(.notConnectedToInternet)])
    #expect(HumanError.isOffline(wrapped))
    #expect(!HumanError.isOffline(NSError(domain: "PostgREST", code: 500)))
  }

  @Test func aFeedResultIsNotOfflineUnlessItSaysSo() {
    let r = HomeStreamRepository.Result(items: [], rounds: [], posts: [], failed: true)
    #expect(r.failed && !r.offline)
  }
}
