import Foundation
import Observation

@MainActor @Observable final class LiveActivityRoute {
  struct Destination: Equatable {
    let round: UUID, owner: UUID
    let review: Bool
  }
  static let shared = LiveActivityRoute()
  var pending: Destination?
  @discardableResult func receive(_ url: URL) -> Bool {
    guard url.scheme == "cupseason", url.host == CSRoundActivityLink.host,
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
    func value(_ name: String) -> String? {
      let matches = components.queryItems?.filter { $0.name == name } ?? []
      return matches.count == 1 ? matches[0].value : nil
    }
    guard let round = value("round").flatMap(UUID.init), let owner = value("owner").flatMap(UUID.init) else { return false }
    pending = .init(round: round, owner: owner, review: value("review") == "1")
    return true
  }
}
