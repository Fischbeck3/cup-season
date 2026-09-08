// Cup Season — what the League pane left behind (D223, IOS-031).
//
// The pane itself is gone: its rows are the rules page's "Who's in" section
// (everyone) and the Pro's verb row (the Pro), which is IOS-031's split — two
// surfaces, not one pane with a role branch inside it. Its all-caps bylaws
// card went with it; the rules are sentences now (§7.4).
//
// What stays here is what the rest of the season still calls: the Pro's
// notices switch, the season's cancel and delete sheets (D71), and the two
// small helpers they need.

import SwiftUI
import CSDesign
import CupSeasonKit
import UIKit

/// The Pro's "League notices" switch (`leagues.notify_system`, push wave 7).
/// On: floors, closes and season notices reach the crew's phones. Off: only
/// rounds, chat and the board — each golfer's own pings are untouched. The
/// server checks is_commissioner; a member sees the setting as a line.
struct NoticesRoomSection: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @State private var busy = false

  private var on: Bool { model.league?.noticesOn ?? true }

  var body: some View {
    if model.isPro {
      RoomCheckRow("League notices", sub: NoticesCopy.sub(on)) {
        Image(systemName: "bell").font(.system(size: 15, weight: .regular)).foregroundStyle(cs.ink)
      } trail: {
        Toggle("League notices", isOn: Binding(get: { on }, set: { set($0) }))
          .labelsHidden()
          .tint(cs.brand)
          .disabled(busy)
          .accessibilityLabel("League notices")
          .accessibilityHint(NoticesCopy.sub(on))
      }
    } else {
      HStack(spacing: 10) {
        Image(systemName: on ? "bell" : "bell.slash").font(.system(size: 13, weight: .regular)).foregroundStyle(cs.mut)
        Text(NoticesCopy.memberLine(on)).csType(.agateS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(minHeight: 44)
      .accessibilityElement(children: .combine)
    }
  }

  /// The toast speaks in voice on success and carries the server's words on refusal.
  private func set(_ next: Bool) {
    guard !busy, next != on else { return }
    CSHaptic.selection()
    busy = true
    Task {
      defer { busy = false }
      do {
        try await model.setNotifySystem(next)
        toast.show(NoticesCopy.toast(model.league?.noticesOn ?? next))
      } catch {
        toast.show(roomError(error, "Could not change league notices."), kind: .failed)
      }
    }
  }
}

enum NoticesCopy {
  static func sub(_ on: Bool) -> String {
    on ? "Minimums, closes and season notices reach the crew's phones" : "Only rounds, chat and the board"
  }
  static func memberLine(_ on: Bool) -> String {
    on ? "League notices reach your phone — minimums, closes, season news" : "League notices are off — only rounds, chat and the board"
  }
  static func toast(_ on: Bool) -> String {
    on ? "Notices are on — minimums, closes and season news reach the crew" : "Notices are off — only rounds, chat and the board ring"
  }
}

extension URL: @retroactive Identifiable { public var id: String { absoluteString } }

/// The system share sheet for a link minted a moment ago.
struct ActivityView: UIViewControllerRepresentable {
  let items: [Any]
  func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
  func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

/// D71 — "Cancel <name>? · THE SEASON IS UNDER WAY" (15628–15646).
struct CancelLeagueSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  @State private var busy = false
  var body: some View {
    let nm = model.league?.name ?? "the league"
    SheetFrame("Cancel \(nm)?", sub: "THE SEASON IS UNDER WAY") {
      RoomFine("A free league cancels now. If there's a buy-in, every member must approve and each gets their buy-in back. Either way the league, its board and pot go — but every posted round stays where it is.")
      Button {
        busy = true
        Task {
          defer { busy = false }
          do {
            let r = try await model.requestCancel()
            dismiss()
            if r == "done" { toast.show("\(nm) cancelled. Every round stays on its golfer.", kind: .confirmed); links.leagueGone() }
            else { toast.show("Cancellation requested — every member must approve.", kind: .confirmed) }
          } catch { toast.show(roomError(error), kind: .failed) }
        }
      } label: {
        // D266 · this was a fourth button tier hand-rolled in a sheet: its own
        // fill, its own radius, its own busy state and a SPINNER where every
        // other control in the product tallies three dots. `csDestructive`
        // gained `busy:` for it, so the two sheets and the one style agree.
        Text("Start the cancellation")
      }
      .buttonStyle(.csDestructive(busy: busy)).disabled(busy)
      Button("Keep it") { dismiss() }
        .buttonStyle(.csSecondary())
    }
  }
}

/// Pre-tee delete (15648–15683): plain when alone, the typed-name gate when others are in.
struct DeleteLeagueSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  let others: Int
  @State private var typed = ""
  @State private var busy = false
  var body: some View {
    let nm = model.league?.name ?? "the league"
    SheetFrame("Delete \(nm)?", sub: others == 0 ? "ONLY POSSIBLE BEFORE THE FIRST TEE" : "THIS TAKES EVERYONE’S SEAT") {
      if others == 0 {
        RoomFine("It's just you in it — the league, its board and settings go completely. Your rounds stay where they are.")
      } else {
        RoomFine("This deletes \(nm) for everyone in it: golfers, board, pot, squads. Every golfer's rounds stay where they are. Type the league name to confirm.")
        CSField(nm, text: $typed, font: CSFont.body)
      }
      Button {
        if others > 0, typed.trimmingCharacters(in: .whitespaces).lowercased() != nm.trimmingCharacters(in: .whitespaces).lowercased() {
          toast.show("Name didn’t match: nothing deleted", kind: .failed); return
        }
        busy = true
        Task {
          defer { busy = false }
          do { try await model.deleteLeague(); dismiss(); toast.show("\(nm) deleted. Every round stays on its golfer.", kind: .confirmed); links.leagueGone() }
          catch { toast.show(roomError(error), kind: .failed) }
        }
      } label: {
        Text(others == 0 ? "Delete the league" : "Delete for everyone")
      }
      .buttonStyle(.csDestructive(busy: busy)).disabled(busy)
      Button("Keep it") { dismiss() }
        .buttonStyle(.csSecondary())
    }
  }
}
