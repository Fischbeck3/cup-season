import Observation
import CupSeasonKit

@MainActor @Observable final class WidgetRouter {
  static let shared = WidgetRouter()
  var pending: WidgetDestination?
}
