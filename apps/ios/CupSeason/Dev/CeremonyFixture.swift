// Cup Season — the ceremony, photographable (Wave 8 / IOS-052).
//
// **NO SEASON ON ANY DEVICE IS `complete`**, which is stated in the wave brief
// as the ceremony's data blocker: the takeover, the two named finishers and the
// pot's printed ledger cannot be seen on real data by anybody working on this
// build. The audit's P0 is the one surface in the product nobody has ever
// LOOKED at, and rebuilding it unseen is how it stayed a P0.
//
// So `-cs_dev_open ceremony` presents the same view against an invented
// settlement, on the same posture as `-cs_dev_home_state`'s thirteen states,
// `-cs_dev_h2h_fixture` and `-cs_dev_season_fixture`: **DEBUG only, never
// written to the server, and the golfers in it are invented names on invented
// ids.** Nobody's real season is in the shot, and the shot says so.

#if DEBUG
import Foundation
import SwiftUI
import CupSeasonKit

enum CeremonyFixture {
  /// Four golfers, a $240 pot from six buy-ins, one short — so the shot
  /// carries the champion, the runner-up, the points king, what you're owed,
  /// the split, an unclaimed share and D106's "still owed" row all at once.
  static var settlement: PotMath.Settlement {
    let mine = PotMath.SettlementRow(profileId: id(4), name: "You", cents: 6000, why: ["Points king"])
    return PotMath.Settlement(
      potCents: 24000,
      collectedCents: 20000,
      owing: ["Tash"],
      rows: [
        PotMath.SettlementRow(profileId: id(1), name: "Galen Marr", cents: 10000, why: ["Cup champion"]),
        PotMath.SettlementRow(profileId: id(2), name: "Dev Anand", cents: 4000, why: ["Runner-up"]),
        mine,
      ],
      champName: "Galen Marr",
      runName: "Dev Anand",
      kingName: "You",
      mine: mine,
      s1: 87.5, s2: 83.0,
      rung: "the head-to-head",
      fromLedger: true)
  }

  private static func id(_ n: UInt8) -> UUID {
    UUID(uuid: (0xCE, 0x2E, 0x00, n, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0, n))
  }
}

/// The hatch's own modifier. It is one node on `MainTabView`'s chain rather
/// than another `.csSheet` closure, because that chain is already at the
/// type-checker's limit — a second inline closure there fails the build with
/// "unable to type-check this expression in reasonable time".
struct CeremonyHatch: ViewModifier {
  @Binding var up: Bool
  func body(content: Content) -> some View {
    content.sheet(isPresented: $up) {
      SeasonCeremonyView(settlement: CeremonyFixture.settlement, members: 6,
                         finish: "cup_final", champMarker: "saguaro")
        .csDevTextSize(CSDevHatch.textSize)
    }
  }
}
#endif
