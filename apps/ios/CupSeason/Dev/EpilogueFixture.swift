// Cup Season — the post-round epilogue, photographable (D329 / IOS-079).
//
// **THE EPILOGUE'S ROWS ARE SERVER GRANTS**, so the state this presents cannot
// be reached on a simulator at all: it needs one round that is simultaneously a
// personal best, a first sub-80, a first sub-90, a first sub-100, a four-, an
// eight- AND a twelve-week streak, and a first-ever card. Nothing in the
// product can produce that, which is why five waves of screenshots showed this
// screen holding a line or two, and why the marks it drew went unexamined until
// the trophy case was found to disagree with them.
//
// Same posture as `CeremonyFixture` and `-cs_dev_home_state`: **DEBUG only,
// never written to the server, and every figure in it is invented.** Nobody's
// real round is in the shot.
//
// `-cs_dev_open epilogue` · every named row, in the order `rows()` builds them,
//   so the column can be read as a golfer reads it rather than one mark at a
//   time. That ORDER is the point of the fixture: the marks have to hold
//   together as a stack, and a mark judged alone is a mark judged wrongly.
// `-cs_dev_open epilogue unknown` · appends a kind no build knows, to
//   photograph the fallback — which was `✦` on the phone, a flag on the desk
//   and the drawn medal in the trophy case until D329 made all three the medal.

#if DEBUG
import Foundation
import SwiftUI
import CupSeasonKit

enum EpilogueFixture {
  /// The eight named kinds. `firstEver` is deliberately FALSE even though
  /// `first_round` is in the list: the server granted it here, so D326's
  /// safety-net insert must stay silent, and a fixture that hid that would hide
  /// the dedupe this screen depends on.
  static func show(unknown: Bool) -> PostEpilogueShow {
    var earned: [PostEpilogue.Earned] = [
      .init(kind: "personal_best", label: nil),
      .init(kind: "sub_80", label: nil),
      .init(kind: "sub_90", label: nil),
      .init(kind: "sub_100", label: nil),
      .init(kind: "streak_4", label: nil),
      .init(kind: "streak_8", label: nil),
      .init(kind: "streak_12", label: nil),
      .init(kind: "first_round", label: nil),
    ]
    if unknown { earned.append(.init(kind: "a_kind_this_build_does_not_know", label: "Longest drive")) }
    return PostEpilogueShow(
      epilogue: PostEpilogue(gross: 79, pvi: -1.3, points: 11, monthRank: 1, earned: earned),
      course: "Papago Golf Course · Blue",
      firstEver: false,
      roundId: UUID(),
      cap: 2,
      photoTravels: false,
      ceremonyOwnsShare: false)
  }
}

struct EpilogueHatch: ViewModifier {
  @Binding var up: Bool
  let unknown: Bool
  func body(content: Content) -> some View {
    content.sheet(isPresented: $up) {
      EpilogueSheet(show: EpilogueFixture.show(unknown: unknown),
                    photo: nil,
                    links: EpilogueLinks(),
                    onDone: { up = false })
        .csDevTextSize(CSDevHatch.textSize)
        // The real sheet offers `[.medium, .large]` and OPENS at medium, which
        // a golfer drags up and `simctl` cannot. Pinned to large here so the
        // whole column is in one frame — the marks have to be judged as a
        // stack, and a stack photographed four rows at a time is not one.
        .presentationDetents([.large])
    }
  }
}
#endif
