// Cup Season — the bylaws card (`renderBylaws`, index.html 11889–11947) and
// the Pro's endgame dial (`set_league_finish`, until the final window opens),
// plus "How scoring works" (`openScoringHelp`, 17021–17043).

import SwiftUI
import CSDesign
import CupSeasonKit

struct BylawsCard: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var busy = false

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // rows on ground with hairlines — never a card inside a section (IOS-019 rule 2);
      // the key sits over its value at the accessibility sizes instead of beside it
      VStack(spacing: 0) {
        ForEach(LeagueCopy.bylawsRows(model.bylaws, clock: model.clock)) { r in
          A11yStack(rowAlignment: .firstTextBaseline, spacing: 12, columnSpacing: 3) {
            Text(r.k).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(cs.dimText)
              .frame(width: typeSize.isA11y ? nil : 118, alignment: .leading)
            Text(r.v).font(CSFont.subhead).foregroundStyle(cs.ink).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
          }
          .padding(.vertical, 9)
          .overlay(alignment: .bottom) { CSHairline() }
          .accessibilityElement(children: .combine)
        }
        // the endgame dial (migration 008): flippable until the final window opens — after that it's settled, argue never
        if model.isPro && model.clock.phase == .season && !model.clock.isCupFinal && !model.isComplete {
          let d = LeagueCopy.finishDial(current: model.bylaws.finish)
          RoomMini(d.label, busy: busy) {
            busy = true
            Task {
              defer { busy = false }
              do { try await model.setFinish(d.next); toast.show(d.toast) } catch { toast.show(roomError(error)) }
            }
          }
          .padding(.top, 8)
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      RoomMini("How scoring & handicaps work →") { router.open(.scoringHelp) }
    }
  }
}

// Y-25 / D201 · `RoomScoringHelpSheet` is GONE. It was a second, hand-retyped
// copy of the scoring guide: its bands disagreed with `CSBands` at the edges,
// it promised a squad floor inside a solo league (D205/D140), and it retyped
// the ledger sentence with "between you" — the softening brand-canon §3 bans
// by name. The room now opens the ONE producer, `ScoringHelpSheet`, with its
// own structure in hand (LeagueRoomScreen `.scoringHelp`).
