// Cup Season — the League pane (`#room-league`, index.html 3527–3552):
// Members & invites · Share the season (D57) · Squads · League rules & Pro
// Shop; plus the delete / cancel sheets (15618–15683, D71).

import SwiftUI
import CSDesign
import CupSeasonKit
import UIKit

struct LeaguePane: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  #if DEBUG
  // Developer hatch: `-cs_dev_rules` opens the bylaws disclosure on a simulator without a finger.
  @State private var rulesOpen = ProcessInfo.processInfo.arguments.contains("-cs_dev_rules")
  #else
  @State private var rulesOpen = false
  #endif
  @State private var shareURL: URL?
  @State private var sharing = false
  @State private var rosterBusy = false

  /// D180 · "ROSTER OPEN · 5 IN" and, for the Pro, the handle. The sub-line is
  /// `RosterDoor.line()` — the same three facts `_join_gate` reads, so the
  /// screen and the server cannot say different things.
  @ViewBuilder private var rosterRow: some View {
    let door = model.rosterDoor
    RoomCheckRow(door.eyebrow(members: model.members.count), sub: door.line()) {
      Image(systemName: door.isOpen ? "door.left.hand.open" : "door.left.hand.closed")
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(door.isOpen ? cs.brand : cs.mut)
    } trail: {
      if model.isPro {
        if door.isOpen {
          // armed, because closing it turns off a link the Pro has already
          // texted to people — recoverable, but not a stray tap
          ArmedMini("Roster's set", armedLabel: "Sure? The link stops working", busy: rosterBusy) {
            setRoster(open: false)
          }
          .accessibilityHint("Turns off the invite link. You can still add golfers yourself until the halfway turn.")
        } else {
          RoomMini("Reopen", busy: rosterBusy) { setRoster(open: true) }
        }
      }
    }
  }

  private func setRoster(open: Bool) {
    rosterBusy = true
    Task {
      defer { rosterBusy = false }
      do {
        try await model.setRoster(open: open)
        toast.show(open ? "Roster's open — the link works again" : "Roster's set")
      } catch { toast.show(roomError(error, "Could not change the roster.")) }
    }
  }

  var body: some View {
    let n = model.members.count
    VStack(alignment: .leading, spacing: 0) {
      CSSectionHead("League")
      RoomCheckRow("Members & invites", sub: "\(n) player\(n == 1 ? "" : "s")") {
        Image(systemName: "flag").font(.system(size: 15, weight: .regular)).foregroundStyle(cs.ink)
      } trail: { RoomMini("View") { router.open(.members) } }
      RoomCheckRow("Share the season", sub: "A public page — the standings so far, no account needed") {
        Text("🔗").font(.system(size: 15))
      } trail: {
        HStack(spacing: 6) {
          RoomMini("Link", busy: sharing) {
            if model.season == nil { toast.show("The season page opens at first tee"); return }
            sharing = true
            Task { defer { sharing = false }; do { shareURL = try await model.seasonShareURL() } catch { toast.show(roomError(error, "Could not make the link.")) } }
          }
          ArmedMini("✕", armedLabel: "Sure? Turn it off") {
            guard model.season != nil else { return }
            Task { do { try await model.revokeSeasonShare(); toast.show("Link is off — the page stops working for everyone") } catch { toast.show(roomError(error, "Could not revoke.")) } }
          }
          .accessibilityLabel("Turn off this link — the page stops working for everyone who has it")
        }
      }
      // D180 · the roster door. It sits directly under Members & invites
      // because it governs exactly that: who can still get in with the code.
      // The Pro gets the handle; a member reads the state and nothing else.
      rosterRow

      RoomCheckRow("Squads", sub: LeagueCopy.squadsSub(model.clock, solo: model.solo)) {
        Image(systemName: "person.2").font(.system(size: 15, weight: .regular)).foregroundStyle(cs.ink)
      } trail: { RoomMini("View") { links.openDraft() } }

      // IOS-025 / D103a: the Pro dresses the room; members read the choice
      LookRoomSection(leagueId: model.leagueId, isPro: model.isPro)

      // push wave 7: the Pro curates league notices; members read the setting
      NoticesRoomSection()

      DisclosureGroup(isExpanded: $rulesOpen) {
        VStack(alignment: .leading, spacing: 10) {
          CSSectionHead("The bylaws · locked at first tee")
          BylawsCard()
          // D183 · the Pro Shop teaser is DELETED, not rewritten — four
          // features under two nouns D132 retired, three of them unbuilt,
          // behind a "COMING AT LAUNCH" banner that is no longer true of
          // anything. Free until a thousand golfers: this pane sells nothing.
        }
      } label: {
        Text("League rules").csEyebrow().frame(minHeight: 44)
      }
      .tint(cs.mut)
      .padding(.top, 4)
    }
    .sheet(item: $shareURL) { url in
      ActivityView(items: [url, "\(model.league?.name ?? "Our league") on Cup Season — the season so far"]).presentationDetents([.medium, .large])
    }
  }
}

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
        Image(systemName: on ? "bell" : "bell.slash").font(.system(size: 13, weight: .regular)).foregroundStyle(cs.dimText)
        Text(NoticesCopy.memberLine(on)).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
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
        toast.show(roomError(error, "Could not change league notices."))
      }
    }
  }
}

enum NoticesCopy {
  static func sub(_ on: Bool) -> String {
    on ? "Floors, closes and season notices reach the crew's phones" : "Only rounds, chat and the board"
  }
  static func memberLine(_ on: Bool) -> String {
    on ? "League notices reach your phone — floors, closes, season news" : "League notices are off — only rounds, chat and the board"
  }
  static func toast(_ on: Bool) -> String {
    on ? "Notices are on — floors, closes and season news reach the crew" : "Notices are off — only rounds, chat and the board ring"
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
      RoomFine("A free league cancels now. If there's a buy-in, every member must approve and each gets their buy-in back. Either way the league, its board and pot go — but every posted round stays on its golfer's card.")
      Button {
        busy = true
        Task {
          defer { busy = false }
          do {
            let r = try await model.requestCancel()
            dismiss()
            if r == "done" { toast.show("\(nm) cancelled. Every round stays on its golfer."); links.leagueGone() }
            else { toast.show("Cancellation requested — every member must approve.") }
          } catch { toast.show(roomError(error)) }
        }
      } label: {
        ZStack { Text("Start the cancellation").font(CSFont.button).opacity(busy ? 0 : 1); if busy { ProgressView().tint(cs.bg0) } }
          .frame(maxWidth: .infinity, minHeight: 50).foregroundStyle(cs.bg0)
          .background(cs.neg, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      }
      .buttonStyle(.plain).disabled(busy)
      CSButton("Keep it", style: .quiet) { dismiss() }
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
        RoomFine("It's just you in it — the league, its board and settings go completely. Rounds stay on your golfer card.")
      } else {
        RoomFine("This deletes \(nm) for everyone in it: members, board, pot sheet, squads. Rounds stay on every golfer's profile. Type the league name to confirm.")
        CSField(nm, text: $typed, font: CSFont.body)
      }
      Button {
        if others > 0, typed.trimmingCharacters(in: .whitespaces).lowercased() != nm.trimmingCharacters(in: .whitespaces).lowercased() {
          toast.show("Name didn’t match: nothing deleted"); return
        }
        busy = true
        Task {
          defer { busy = false }
          do { try await model.deleteLeague(); dismiss(); toast.show("\(nm) deleted. Every round stays on its golfer."); links.leagueGone() }
          catch { toast.show(roomError(error)) }
        }
      } label: {
        ZStack { Text(others == 0 ? "Delete the league" : "Delete for everyone").font(CSFont.button).opacity(busy ? 0 : 1); if busy { ProgressView().tint(cs.bg0) } }
          .frame(maxWidth: .infinity, minHeight: 50).foregroundStyle(cs.bg0)
          .background(cs.neg, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      }
      .buttonStyle(.plain).disabled(busy)
      CSButton("Keep it", style: .quiet) { dismiss() }
    }
  }
}
