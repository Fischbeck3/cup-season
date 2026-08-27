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
  @State private var busy = false

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // rows on ground with hairlines — never a card inside a section (IOS-019 rule 2)
      VStack(spacing: 0) {
        ForEach(LeagueCopy.bylawsRows(model.bylaws, clock: model.clock)) { r in
          HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(r.k).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(cs.dimText).frame(width: 118, alignment: .leading)
            Text(r.v).font(CSFont.subhead).foregroundStyle(cs.ink).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
          }
          .padding(.vertical, 9)
          .overlay(alignment: .bottom) { CSHairline() }
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

struct RoomScoringHelpSheet: View {
  @Environment(\.cs) private var cs
  var body: some View {
    SheetFrame("How scoring works", sub: "HANDICAPS · CUP POINTS · THE MONEY") {
      Text("Your number").csEyebrow()
      para("Your handicap index builds from your scores — no typing. Every round measures how you played against the course's difficulty (rating & slope), and your best recent rounds set your number, WHS-style. It appears once you've posted **3 rounds**; until then it shows as building.")
      para("You (or the Pro) can set a **starter** to get going sooner — but once you have 3 posted rounds, your scores take over. Manual changes are announced to your league so the crew keeps everyone honest.")
      Text("Every round → cup points").csEyebrow()
      para("Every round is scored against **your own number** — a 22-index beating their number is worth exactly what a 6-index beating theirs is:")
      CSCard(padding: 12) {
        VStack(alignment: .leading, spacing: 4) {
          band("Torched it", "beat it by 3+", "12 pts")
          band("Beat your number", "by 1–3", "9 pts")
          band("Played to it", "within 1", "7 pts")
          band("A little loose", "1–3 over", "6 pts")
          band("Posted anyway", "rough day", "5 pts")
        }
      }
      para("The 12-point ceiling caps what a padded number can buy; the 5-point floor means a posted 98 still beats an unposted 82. **You can't hurt your squad by playing badly — only by not playing.**")
      Text("What counts").csEyebrow()
      para("Your best rounds each month count for your squad — a better round always bumps your worst counter — and everyone owes a minimum number of rounds a month so nobody coasts. Miss it once and your **season bye** covers you automatically — life happens; the floor bites from the second miss. Your league's exact numbers are in **League rules**.")
      Text("The money").csEyebrow()
      para("The pot is **on the books** — Cup Season keeps the ledger and shows a settlement card; the money moves between you.")
    }
  }
  private func para(_ md: String) -> some View {
    Text((try? AttributedString(markdown: md)) ?? AttributedString(md)).font(CSFont.footnote).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
  }
  private func band(_ a: String, _ b: String, _ c: String) -> some View {
    HStack(spacing: 4) {
      Text(a).font(CSFont.footnote.weight(.semibold)).foregroundStyle(cs.ink)
      Text("· \(b) ·").font(CSFont.footnote).foregroundStyle(cs.mut)
      Text(c).font(CSFont.footnote.weight(.semibold)).foregroundStyle(cs.ink)
    }
  }
}
