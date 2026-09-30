#if DEBUG
import SwiftUI
import CSDesign
import CupSeasonKit

/// Signed-out visual proof of the real launch sheets. No refresh, server data
/// or write is invoked. The ruling model has no season and refuses a write.
struct LaunchSheetFixture: View {
  @State private var presented = true
  @State private var opened = false
  @State private var model = LeagueRoomModel(leagueId: UUID())
  @Environment(\.cs) private var cs
  var body: some View {
    Color.clear.overlay {
      if opened { Text("North Grove (fixture) opened").accessibilityIdentifier("recipient.opened") }
    }.sheet(isPresented: $presented) {
      if ProcessInfo.processInfo.arguments.contains("-cs_dev_launch_ruling") {
        RulingSheet(member: LeagueRoom.Member(id: UUID(), role: "member", profile_id: UUID()))
          .environment(model).presentationDetents([.medium, .large])
      } else if ProcessInfo.processInfo.arguments.contains("-cs_dev_join_agreed") {
        CovenantSheet(covenant: Covenant(name: "North Grove (fixture)", buyinCents: 0,
          preset: "standard", floor: 2, finish: "cup_final", seasonNumber: 2, reup: true, agreed: true),
          onJoin: { fatalError("An agreed season must not join again") }, onNo: { presented = false },
          onOpen: { opened = true; presented = false })
      } else {
        CovenantSheet(covenant: Covenant(name: "QA season", buyinCents: 5000,
          preset: "standard", floor: 2, finish: "cup_final", proName: "QA host", rosterCount: 1,
          handicapAllowance: 95, seasonNumber: 2, reup: true, agreed: false,
          lastSeason: .init(myRank: 3, of: 8, myPoints: 41)),
          onJoin: { presented = false }, onNo: { presented = false })
      }
    }
  }
}
#endif
