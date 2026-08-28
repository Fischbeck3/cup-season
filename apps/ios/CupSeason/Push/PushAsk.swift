// Cup Season — the contextual ask (push-contract §6, D104 item 6). Never on
// launch. A moment (card saved · first round posted · league joined) REQUESTS
// the ask; the tab shell PRESENTS it once nothing else is on stage, and only
// if the system prompt has not been answered and "Not now" is older than
// fourteen days. One explainer sheet, three lines in voice, then the system
// prompt through the same `PushService.enable()` the Settings switch uses.

import SwiftUI
import UserNotifications
import CSDesign
import CupSeasonKit

@MainActor
@Observable
final class PushAsk {
  static let shared = PushAsk()

  /// A moment happened; the shell will present when the stage is clear.
  private(set) var pending: PushAskReason?
  /// The sheet's item.
  var presented: PushAskReason?

  func request(_ reason: PushAskReason) {
    if pending == nil { pending = reason }
  }

  /// Called by the shell with nothing else presented. Consumes `pending`
  /// whether or not the sheet shows — a moment asks once.
  func presentIfDue() async {
    guard let reason = pending else { return }
    pending = nil
    let s = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    let status: PushAskPolicy.Status = switch s {
    case .notDetermined: .undetermined
    case .authorized, .provisional, .ephemeral: .authorized
    default: .denied
    }
    let declined = UserDefaults.standard.object(forKey: PushAskPolicy.declinedKey) as? Date
    var due = PushAskPolicy.shouldAsk(status: status, declinedAt: declined)
    #if DEBUG
    if PushDev.forcePrompt { due = true }
    #endif
    guard due else { return }
    CSTelemetry.event("push_prompt_shown", ["reason": .string(reason.rawValue)])
    presented = reason
  }

  #if DEBUG
  /// `-cs_dev_push_prompt`: the explainer whatever the system says.
  func force() { pending = .cardSaved }
  #endif

  func declined() {
    if let r = presented { CSTelemetry.event("push_prompt_declined", ["reason": .string(r.rawValue)]) }
    UserDefaults.standard.set(Date(), forKey: PushAskPolicy.declinedKey)
    presented = nil
  }

  /// The system prompt, then registration — `PushService.enable()` is the one door.
  func accepted() async -> String {
    if let r = presented { CSTelemetry.event("push_prompt_accepted", ["reason": .string(r.rawValue)]) }
    let msg = await PushService.shared.enable()
    presented = nil
    return msg
  }
}

/// The explainer. Three lines, two buttons, 44pt targets.
struct PushPromptSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  let reason: PushAskReason
  @State private var ask = PushAsk.shared
  @State private var busy = false

  private var eyebrow: String {
    switch reason {
    case .cardSaved: "YOUR CARD IS IN"
    case .firstRound: "FIRST ONE ON THE BOARD"
    case .leagueJoined: "YOU’RE ON THE ROSTER"
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      CSSheetHeader(title: "Hear it when it happens", sub: eyebrow)
      VStack(alignment: .leading, spacing: 10) {
        line("flag.fill", "A round lands on the board. A duel is closing. The table moves.")
        line("person.2.fill", "A buddy request, a tee time, an invite — answered from the lock screen.")
        line("moon.zzz.fill", "Nothing else. No streaks, no noise, no badge you didn’t earn.")
      }
      .padding(.vertical, 4)
      VStack(spacing: 8) {
        CSButton("Turn on notifications", busy: busy) {
          busy = true
          Task { let msg = await ask.accepted(); busy = false; toast.show(msg) }
        }
        Button { ask.declined() } label: {
          Text("Not now").font(CSFont.subhead).foregroundStyle(cs.mut).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
      }
      .padding(.top, 4)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg0)
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
    .interactiveDismissDisabled(busy)
    .onDisappear { if ask.presented != nil { ask.declined() } }   // a swipe-down is a "Not now"
  }

  private func line(_ icon: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(cs.brand).frame(width: 22)
      Text(text).font(CSFont.body).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
    }
  }
}

#Preview("Push ask") {
  PushPromptSheet(reason: .firstRound).csTheme()
}
