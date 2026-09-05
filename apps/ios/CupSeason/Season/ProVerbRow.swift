// Cup Season — the Pro's verbs (D223 §7.5, IOS-031).
//
// A ROW AT THE FOOT, NEVER A MODE. The old League pane branched on role
// inside itself, so a member and a Pro read the same rows with different
// controls bolted on; the audit's joiner landed on the Pro's configuration
// tool more than once. Here the rules are everyone's page and the verbs are
// the Pro's row, at the foot, after the season the verbs are about.
//
// Seven verbs, each already a definer RPC, each with a moment where it makes
// sense. Nothing here is a new power — `close_roster`, `set_member_bye`,
// `set_league_finish`, `mark_buy_in`, `announce`, `invite_golfer` and
// `request_league_cancel` all exist and the server re-checks every one. What
// changes is that a member never sees them, and the Pro never has to find
// them behind a disclosure inside a pane.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ProVerbRow: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @State private var busy = false
  /// Where the page should scroll for a verb whose surface is on it (the pot).
  var scrollTo: (String) -> Void = { _ in }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      CSHairline()
      Text("You run this season").csEyebrow(cs.gold)
      FlowRow(spacing: 8) {
        RoomMini("Invite golfers") { links.addGolfers() }
        if model.bylaws.stake > 0 {
          RoomMini("Mark a payment") { scrollTo(SeasonPane.pot.anchor) }
        }
        RoomMini("Announce") { links.openBoard() }
        roster
        RoomMini("Grant a bye") { router.open(.members) }
        finish
        end
      }
      Text(note).font(CSFont.footnote).foregroundStyle(cs.dimText)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.top, 6)
  }

  /// D180 · closing the roster turns off a link the Pro has already texted to
  /// people, so it is armed. Reopening is not.
  @ViewBuilder private var roster: some View {
    let door = model.rosterDoor
    if door.isOpen {
      ArmedMini("Close the roster", armedLabel: "Sure? The link stops working", busy: busy) {
        run { try await model.setRoster(open: false); toast.show("Roster's set") }
      }
    } else {
      RoomMini("Reopen the roster", busy: busy) {
        run { try await model.setRoster(open: true); toast.show("Roster's open — the link works again") }
      }
    }
  }

  /// D112 · the finish is one of the season's terms, so it moves only before
  /// the first tee. After it, the row states the rule instead of offering a
  /// control the server would refuse.
  @ViewBuilder private var finish: some View {
    if model.clock.phase != .season || model.clock.atStarter {
      let d = LeagueCopy.finishDial(current: model.bylaws.finish)
      RoomMini("Set the finish", busy: busy) {
        run { try await model.setFinish(d.next); toast.show(d.toast) }
      }
      .accessibilityHint(d.label)
    }
  }

  /// D71 · never surfaced anywhere else, and behind the sheet that states what
  /// happens to the money and to the rounds.
  @ViewBuilder private var end: some View {
    if !model.isComplete {
      let d = LeagueCopy.danger(model.clock)
      RoomMini(d.preTee ? "Delete the season" : "End the season", tone: cs.neg, busy: busy) {
        if d.preTee { Task { router.open(.deleteLeague(others: await model.othersCount())) } }
        else { router.open(.cancelLeague) }
      }
      .accessibilityHint(d.note)
    }
  }

  private var note: String {
    model.clock.phase == .season && !model.clock.atStarter
      ? "The bylaws froze at the first tee. Everything here is posted to the board."
      : "Everything here is posted to the board."
  }

  private func run(_ op: @escaping @MainActor () async throws -> Void) {
    busy = true
    Task { defer { busy = false }; do { try await op() } catch { toast.show(roomError(error)) } }
  }
}
