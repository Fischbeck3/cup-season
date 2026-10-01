import BackgroundTasks
import CupSeasonKit

/// D400 · the OS's side of `WidgetBackgroundRead`: register once at launch,
/// ask again whenever the app leaves the screen and after every run. iOS owns
/// the cadence (it learns from how the phone is used); 90 minutes is the
/// soonest this ever asks for.
enum WidgetRefreshTask {
  static let id = "app.cupseason.ios.widgets.refresh"
  static let interval: TimeInterval = 90 * 60

  /// Must run before launch finishes (`didFinishLaunching`).
  static func register() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: id, using: nil) { task in
      let box = TaskBox(task)
      schedule()
      let work = Task { @MainActor in
        let ok = await WidgetBackgroundRead.run()
        box.task.setTaskCompleted(success: ok)
      }
      task.expirationHandler = { work.cancel() }
    }
  }

  static func schedule() {
    #if DEBUG
    // the review fixtures and synthetic launches never ask the OS for anything
    if ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("-cs_dev") }) { return }
    #endif
    let request = BGAppRefreshTaskRequest(identifier: id)
    request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
    // a pending request is replaced, not stacked; failure (simulator, Low
    // Power Mode, the setting off) leaves the app exactly as it was
    try? BGTaskScheduler.shared.submit(request)
  }

  /// `BGTask` is not Sendable; the handler hands it to the main actor once and
  /// nothing else touches it.
  private final class TaskBox: @unchecked Sendable {
    let task: BGTask
    init(_ task: BGTask) { self.task = task }
  }
}
