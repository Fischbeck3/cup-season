// Cup Season — P-17, THE SAFETY BLOCK (L-38; App Store Guideline 1.2;
// COMPONENT_SYSTEM.md §4 P-17).
//
// L-38 is in the immutable wall and this redesign is exactly the kind of change
// that loses it: `TourCardSheet` carries mute and the two-step report today,
// and wave 5 promotes that sheet to a PAGE. Promoting it without these controls
// drops report and block from the surface a golfer most often reaches a person
// on. So the block is built ONCE, here, and mounted on every surface that
// renders another golfer's content — the person page, the head-to-head page,
// the board rows, and the peek sheet, which keeps its own copy too.
//
// WHAT THE MENU HOLDS, AND WHY IT IS NOT FOUR ITEMS.
// P-17's anatomy lists report · block · hide · mute. This product has
// `report_content`, `set_mute` and a device-local hide. It has NO block
// mechanic, and `hide_content` is a MODERATOR verb (a Pro takes a post down),
// not "hide this from me". L-38's own wording settles it —
//
//     "Report, block (mute), hide/unhide, suspend, delete account"
//
// — and `docs/ios/app-review-notes.md:105` already tells App Review, in terms,
// that Mute IS the block on this app. So the menu is Mute · Hide this · Report,
// the mute item names what it actually delivers, and NO item labelled Block is
// drawn over a mechanic that does not exist (L-32, L-44). A real block —
// mutual invisibility with the read policies to enforce it — is a class-C
// mechanic with its own entry, not a menu label.
//
// COPY RULE: function first, no euphemism, and never a consequence the app
// cannot deliver. "Mute" says *hide their rounds from your feeds*, not "you
// won't hear from them". The report keeps its TWO steps — a reason, then a
// confirmation — because one tap is an accident.
//
// STATES: it renders immediately and needs no data; it is never empty; a failed
// report keeps the sheet open and says so; a failed mute reverts the row.

import SwiftUI
import CSDesign
import CupSeasonKit

/// The words, in one place, so the phone and the desk say the same thing.
enum SafetyCopy {
  static let more = "More actions"
  static func moreFor(_ name: String) -> String { "More actions for \(name)" }
  static func mute(_ name: String) -> String { "Mute \(name)" }
  static func unmute(_ name: String) -> String { "Unmute \(name)" }
  static let muteSub = "Hide their rounds from your feeds"
  static let unmuteSub = "Show their rounds again"
  static let hideThis = "Hide this"
  static let hideSub = "This one item, on this device"
  static let report = "Report"
  static let reportTitle = "Report"
  static let reportSub = "PICK A REASON, THEN CONFIRM"
  static let reportHelp =
    "It goes to the founder desk with the golfer’s handle and what you picked. Nothing is sent until you confirm."
  static let reportSent = "Reported — the founder desk sees it"
  static let reportFailed = "Could not send that report."
  static let muteFailed = "Could not change that."
  static func muted(_ name: String) -> String { "Muted. \(name)’s rounds drop off your boards." }
  static let unmuted = "Unmuted."
  static let hidden = "Hidden here. It stays on their card."

  /// The reasons, in the order a reporter scans them. "Something else" is last
  /// and is not a free-text box — a report is a signal to the desk, not a
  /// message to a person.
  static let reasons: [String] = [
    "A made-up score", "Harassment or abuse", "An inappropriate photo",
    "Spam", "Something else",
  ]
}

/// The `⋯` control and its menu. Trailing, 44×44, `mut` on the ground, never
/// an accent — a safety control that competes with the page's own act is a
/// safety control somebody taps by mistake.
struct CSSafetyMenu: View {
  @Environment(\.cs) private var cs
  let profileId: UUID
  let name: String
  /// The one item this surface is showing, when it has one. Absent on the
  /// person page and the head-to-head, which are about a golfer rather than
  /// about a thing they posted — so "Hide this" is not drawn there.
  var hideThis: (() -> Void)? = nil

  @State private var muted = false
  @State private var busyMute = false
  @State private var reporting = false
  private let people = PeopleService()
  private let repo = TourCardRepository()

  var body: some View {
    Menu {
      Button(muted ? SafetyCopy.unmute(name) : SafetyCopy.mute(name), systemImage: muted ? "speaker.wave.2" : "speaker.slash") {
        Task { await toggleMute() }
      }
      if let hideThis {
        Button(SafetyCopy.hideThis, systemImage: "eye.slash") {
          hideThis()
          ToastCenter.shared.show(SafetyCopy.hidden)
        }
      }
      Button(SafetyCopy.report, systemImage: "flag") { reporting = true }
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(cs.mut)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .accessibilityLabel(SafetyCopy.moreFor(name))
    .disabled(busyMute)
    .task { await loadMute() }
    .sheet(isPresented: $reporting) {
      ReportGolferSheet(profileId: profileId, name: name)
    }
  }

  private func loadMute() async {
    guard let mutes: [UUID] = try? await SupabaseService.shared.call(Rpc.my_mutes()) else { return }
    muted = mutes.contains(profileId)
  }

  private func toggleMute() async {
    let on = !muted
    busyMute = true
    defer { busyMute = false }
    do {
      try await repo.setMute(profileId, on: on)
      muted = on
      ToastCenter.shared.show(on ? SafetyCopy.muted(name) : SafetyCopy.unmuted)
    } catch {
      // a failed mute REVERTS the row and says why (P-17's error state)
      ToastCenter.shared.show(SliceFormat.human(error, SafetyCopy.muteFailed))
    }
  }
}

/// Step one is the reason, step two is the confirmation. Never an alert
/// (L-32), and the sheet stays open when the send fails.
struct ReportGolferSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let profileId: UUID
  let name: String

  @State private var reason: String?
  @State private var sending = false
  @State private var failed: String?
  private let repo = TourCardRepository()

  var body: some View {
    SliceSheet(title: SafetyCopy.reportTitle, sub: SafetyCopy.reportSub) {
      Fine(SafetyCopy.reportHelp)
      VStack(spacing: 0) {
        ForEach(Array(SafetyCopy.reasons.enumerated()), id: \.offset) { i, r in
          CSRow(last: i == SafetyCopy.reasons.count - 1) {
            Button { reason = r; failed = nil } label: {
              HStack {
                Text(r).font(CSFont.subhead).foregroundStyle(cs.ink)
                Spacer(minLength: 8)
                if reason == r { Text("✓").font(CSFont.subhead).foregroundStyle(cs.brand) }
              }
              .frame(minHeight: 44)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(reason == r ? .isSelected : [])
          }
        }
      }
      if let failed {
        Text(failed).font(CSFont.subhead).foregroundStyle(cs.neg)
          .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
      }
      CSButton(reason == nil ? "Pick a reason" : "Send this report", busy: sending) {
        Task { await send() }
      }
      .disabled(reason == nil || sending)
      .padding(.top, 12)
    }
    .presentationDetents([.medium])
  }

  private func send() async {
    guard let reason else { return }
    sending = true
    do {
      try await repo.report(profileId, reason: reason)
      ToastCenter.shared.show(SafetyCopy.reportSent)
      dismiss()
    } catch {
      sending = false
      failed = SliceFormat.human(error, SafetyCopy.reportFailed)
    }
  }
}

/// A device-local hide — "this one item, on this device". It is not a
/// moderation act and it makes no claim about anybody else's screen, which is
/// exactly what the menu's sub says.
struct HiddenItems {
  private static let key = "cs_hidden_items"
  static func hidden(_ id: String) -> Bool {
    (UserDefaults.standard.array(forKey: key) as? [String] ?? []).contains(id)
  }
  static func hide(_ id: String) {
    var all = UserDefaults.standard.array(forKey: key) as? [String] ?? []
    guard !all.contains(id) else { return }
    all.append(id)
    UserDefaults.standard.set(Array(all.suffix(500)), forKey: key)
  }
}
