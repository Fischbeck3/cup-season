// Cup Season — the bundled faces, resolved at RUNTIME (D258, D268, IOS-044).
//
// Preflight 38(b) proves that every name `CSFont` asks for exists in a file in
// `Resources/Fonts`, and that both `UIAppFonts` arrays name that file. Neither
// of those proves the last step: that iOS actually REGISTERED the face for
// this bundle and will hand it back. That is the step D258 fell down — three
// mono roles rendered in SF Pro for weeks with no crash, no log and nothing on
// screen that said so.
//
// This suite is hosted by the app, so `UIFont(name:)` here is asking the same
// CoreText registry `Font.custom` asks at draw time. If a face is missing from
// the plist, misspelled, or dropped from the target's resources, exactly one
// thing happens: this fails.
//
// It also pins the advance: the board face is CONDENSED, so at the same point
// size it must be narrower than the system sans. A file that registered under
// the right name but shipped the wrong cut would pass every string check above
// and fail here.

import Testing
import UIKit
import CSDesign
@testable import CupSeason

@Suite struct BundledFaceTests {
  /// Every PostScript name the design system asks for, and what it is for.
  static let faces: [(String, String)] = [
    (CSFont.monoRegular, "the scorer's tent"),
    (CSFont.monoMedium, "the scorer's tent, medium"),
    (CSFont.monoSemibold, "the scorer's tent, semibold"),
    (CSFont.boardSemibold, "the board face — the figure, the rail, every title"),
    (CSFont.boardBold, "the board face, bold"),
  ]

  @Test func everyBundledFaceResolves() {
    for (name, job) in Self.faces {
      #expect(UIFont(name: name, size: 17) != nil,
              "\(name) (\(job)) did not resolve — Font.custom is silently drawing SF Pro (D258)")
    }
  }

  @Test func aResolvedFaceIsTheFaceItSaysItIs() {
    for (name, _) in Self.faces {
      guard let f = UIFont(name: name, size: 17) else { continue }   // the miss is the test above
      #expect(f.fontName == name, "asked for \(name) and CoreText handed back \(f.fontName)")
    }
  }

  /// The board face earns its name: condensed is NARROWER. `28` is the widest
  /// two-digit figure and the one the rank rail and the panel actually draw.
  @Test func theBoardFaceIsActuallyCondensed() {
    guard let board = UIFont(name: CSFont.boardSemibold, size: 40) else {
      Issue.record("the board face did not resolve; the width comparison cannot run")
      return
    }
    let system = UIFont.systemFont(ofSize: 40, weight: .semibold)
    let w = { (f: UIFont) in ("28" as NSString).size(withAttributes: [.font: f]).width }
    #expect(w(board) < w(system),
            "the board face measured \(w(board))pt against the system's \(w(system))pt — that is not a condensed cut")
  }

  /// The mono faces are monospaced, which is the whole reason a column of
  /// figures lines up. `MeStripLayout` does arithmetic on this advance.
  @Test func theMonoFaceIsActuallyMonospaced() {
    guard let mono = UIFont(name: CSFont.monoRegular, size: 17) else {
      Issue.record("the mono face did not resolve")
      return
    }
    let w = { (s: String) in (s as NSString).size(withAttributes: [.font: mono]).width }
    #expect(abs(w("1111") - w("MMMM")) < 0.01, "the mono face is not advancing uniformly")
  }
}
