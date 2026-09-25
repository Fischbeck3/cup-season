import AppIntents
import Foundation
#if !CS_WIDGET_EXTENSION
import CupSeasonKit
#endif

struct ReplyToTeeIntent: AppIntent {
  static let title: LocalizedStringResource = "Reply to a tee time"
  static let isDiscoverable = false
  static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
  @Parameter(title: "Round") var round: String
  @Parameter(title: "Golfer") var owner: String
  @Parameter(title: "Reply") var status: String
  init() {}
  init(round: UUID, owner: UUID, status: String) {
    self.round = round.uuidString; self.owner = owner.uuidString; self.status = status
  }
  @MainActor func perform() async throws -> some IntentResult {
    #if CS_WIDGET_EXTENSION
    // The app-only conformance below selects the app process, where auth lives.
    // Never report success if the OS unexpectedly invokes the extension stub.
    try requireAppProcess()
    #else
    guard let round = UUID(uuidString: round), let owner = UUID(uuidString: owner) else { throw WidgetRSVPError.expired }
    BetweenRoundsFeed.shared.invalidate()
    let svc = SupabaseService.shared
    do { try await WidgetRSVP.run(round: round, owner: owner, status: status,
      currentOwner: { await svc.currentSession()?.user.id },
      read: { try await ScheduleService(svc).detail($0) },
      save: { try await ScheduleService(svc).rsvp($0, status: $1) })
    } catch let error as WidgetRSVPError { throw error }
    catch { throw WidgetRSVPError.unavailable }
    #endif
    return .result()
  }
}

#if CS_WIDGET_EXTENSION
private func requireAppProcess() throws { throw ReplyExecutionError.openApp }
private enum ReplyExecutionError: LocalizedError {
  case openApp
  var errorDescription: String? { "Open Cup Season to reply to this invitation." }
}
#else
// iOS 17–25: run in the app in the background without sharing credentials with
// the extension. This remains Apple's compatibility path on the iOS 17 floor.
extension ReplyToTeeIntent: ForegroundContinuableIntent {}
#endif
