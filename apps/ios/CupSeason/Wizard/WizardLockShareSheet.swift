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
  /// P-11 · the season's `starts_on` as the lock returned it — "Season is live"
  /// only once first tee has come; before it, the line names the tee.
  var startsOn: String? = nil
  /// D225 · the wizard's own answers, so the share screen can say the sentence
  /// the golfer just built rather than the seat math it used to.
  var weeks: Int? = nil
  var invited: Int = 0
  var id: UUID { leagueId }
  var line: String {
    if let w = weeks, let s = startsOn {
      return WizardCopy.liveSub(weeks: w, startsOn: s, invited: invited)
    }
    return WizardCopy.lockShareLine(nextPhase: nextPhase, members: members, structure: structure, draftType: draftType, startsOn: startsOn)
  }
  var head: String { WizardCopy.liveHead(name) }
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
        CSSheetHeader(title: share.head, sub: WizardCopy.lockShareSub)
        CSFine(share.line)
        CSBand(.tone, padding: CSTokens.Space.s3) {
          VStack(alignment: .leading, spacing: 4) {
            (Text("You're invited to ").foregroundStyle(cs.mut) + Text(share.name).bold().foregroundStyle(cs.ink) + Text(" on Cup Season").foregroundStyle(cs.mut))
              .csType(.bodyS)
            Text(WizardCopy.inviteShort(share.code)).csType(.column).foregroundStyle(cs.ink)
              .textSelection(.enabled)
          }
        }
        // D114's phone half: the URL as text (a golfer reads it aloud in a
        // group chat, which is a real thing that happens), then the web's three
        // controls beside the system sheet.
        if let url = share.url {
          A11yStack(spacing: 8) {
            CSMini(WizardCopy.copyLink) {
              UIPasteboard.general.string = url.absoluteString
              CSHaptic.selection()
              CSGrowth.log(.artifactShared, kind: "join", token: share.code, league: share.leagueId)
            }
            CSMini(WizardCopy.copyMessage) {
              UIPasteboard.general.string = "\(WizardCopy.inviteText(share.name)): \(url.absoluteString)"
              CSHaptic.selection()
              CSGrowth.log(.artifactShared, kind: "join", token: share.code, league: share.leagueId)
            }
          }
          .padding(.top, 2)
          ShareLink(item: url, subject: Text("Cup Season"), message: Text(WizardCopy.inviteText(share.name))) {
            Text(WizardCopy.shareEllipsis).csType(.name).frame(maxWidth: .infinity, minHeight: 50)
              .foregroundStyle(cs.bg0).background(cs.brand, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          }
          .simultaneousGesture(TapGesture().onEnded { CSGrowth.log(.artifactShared, kind: "join", token: share.code, league: share.leagueId) })
          .padding(.top, 4)
        }
        Button("Add golfers") { picker = true }.buttonStyle(.csSecondary())
        Button(WizardCopy.openTheSeason) { dismiss() }.buttonStyle(.csSecondary())
      }
      .padding(20)
    }
    .background(cs.bg1)
    .sheet(isPresented: $picker) {
      PeoplePickerSheet(mode: .invite(.league(share.leagueId), share: (name: share.name, code: share.code)), onDone: { picker = false })
    }
  }
}
