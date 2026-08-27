// Cup Season — `openLockShare` (index.html 13931–13960): the wizard's last
// screen is the invite link — "one link fills the league" (D40). Seat math
// from the structure the Pro just picked; the share is the system sheet;
// "Add golfers" is the same people picker the members sheet uses
// (`invite_golfer`, the D97 home of in-app invites).

import SwiftUI
import CSDesign
import CupSeasonKit

struct WizardLockShare: Identifiable, Equatable {
  let leagueId: UUID
  let name: String
  let code: String
  let nextPhase: String
  let members: Int
  let structure: String
  let draftType: String
  var id: UUID { leagueId }
  var line: String { WizardCopy.lockShareLine(nextPhase: nextPhase, members: members, structure: structure, draftType: draftType) }
  var url: URL? { WizardCopy.inviteURL(code) }
}

struct WizardLockShareSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  let share: WizardLockShare
  @State private var picker = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        CSSheetHeader(title: WizardCopy.lockShareTitle, sub: WizardCopy.lockShareSub)
        CSFine(share.line)
        CSCard(padding: 12) {
          VStack(alignment: .leading, spacing: 4) {
            (Text("You're invited to ").foregroundStyle(cs.dimText) + Text(share.name).bold().foregroundStyle(cs.ink) + Text(" on Cup Season").foregroundStyle(cs.dimText))
              .font(CSFont.footnote)
            Text(WizardCopy.inviteShort(share.code)).font(CSFont.mono).foregroundStyle(cs.ink)
              .textSelection(.enabled)
          }
        }
        if let url = share.url {
          ShareLink(item: url, subject: Text("Cup Season"), message: Text(WizardCopy.inviteText(share.name))) {
            Text(WizardCopy.shareInvite).font(CSFont.button).frame(maxWidth: .infinity, minHeight: 50)
              .foregroundStyle(cs.bg0).background(cs.brand, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          }
          .padding(.top, 4)
        }
        CSButton("Add golfers", style: .quiet) { picker = true }
        CSButton(WizardCopy.later, style: .quiet) { dismiss() }
      }
      .padding(20)
    }
    .background(cs.bg1)
    .sheet(isPresented: $picker) {
      PeoplePickerSheet(mode: .invite(.league(share.leagueId), share: (name: share.name, code: share.code)), onDone: { picker = false })
    }
  }
}
