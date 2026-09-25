import AppIntents
import Foundation
#if !CS_WIDGET_EXTENSION
import CupSeasonKit
#endif

struct LiveScoreIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Update your live score"
  static let isDiscoverable = false
  static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
  @Parameter(title: "Round") var round: String
  @Parameter(title: "Golfer") var owner: String
  @Parameter(title: "Hole") var hole: Int
  @Parameter(title: "Action") var action: String
  init() {}
  init(round: UUID, owner: UUID, hole: Int, action: String) {
    self.round = round.uuidString; self.owner = owner.uuidString; self.hole = hole; self.action = action
  }
  @MainActor func perform() async throws -> some IntentResult {
    #if CS_WIDGET_EXTENSION
    try requireLiveAppProcess()
    #else
    guard let round = UUID(uuidString: round), let owner = UUID(uuidString: owner),
          let action = LiveIsland.Action(rawValue: action) else { throw LiveIsland.Failure.unavailable }
    try await LiveActivityActions.run(action, round: round, owner: owner, hole: hole)
    #endif
    return .result()
  }
}

#if CS_WIDGET_EXTENSION
private func requireLiveAppProcess() throws { throw LiveScoreExecutionError.openRound }
private enum LiveScoreExecutionError: LocalizedError {
  case openRound
  var errorDescription: String? { "Open your round to continue scoring." }
}
#endif
