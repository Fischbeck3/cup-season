// Cup Season — `-cs_dev_cred <photo|crest|earned|empty|private|loading|long>`:
// **the harness that renders all seven states of `player-card.md` §6**, over
// the root, whatever the session is.
//
// Same reason as `-cs_dev_door` and `-cs_dev_live`: the card is the most
// reviewed object in the app and the hardest to reach — it needs an account, a
// season, a photograph and a founding row. This shows it with none of them, so
// a change to it can be LOOKED AT before it ships. D197 shipped two regressions
// past a green test suite; a card is a thing you have to see.
//
// The harness takes a state argument because `simctl` has no finger and cannot
// scroll: one state per launch, and a human with a trackpad gets all of them by
// passing `all`.
//
// DEBUG only. Nothing here touches the server.

#if DEBUG
import SwiftUI
import CSDesign
import CupSeasonKit

enum CredDev {
  static var mode: String? {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_cred"), i + 1 < a.count else { return nil }
    return a[i + 1]
  }

  /// A stand-in photograph, DRAWN rather than downloaded — a simulator with no
  /// account and no network reviews nothing if the plate is a spinner.
  ///
  /// GREYSCALE on purpose, and not only to keep preflight 15 honest: a NEARLY
  /// WHITE subject under the name is the worst case the scrim has to survive,
  /// and a plausible warm portrait would have flattered it. **No face is
  /// fabricated**: it is a head-and-shoulders MASS, which is what the scrim's
  /// arithmetic is being tested against.
  static let photo: URL? = {
    let size = CGSize(width: 900, height: 1200)
    let img = UIGraphicsImageRenderer(size: size).image { ctx in
      let c = ctx.cgContext
      let sky = [UIColor(white: 0.74, alpha: 1).cgColor,
                 UIColor(white: 0.40, alpha: 1).cgColor] as CFArray
      if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceGray(), colors: sky, locations: [0, 1]) {
        c.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
      }
      c.setFillColor(UIColor(white: 0.82, alpha: 1).cgColor)
      c.fillEllipse(in: CGRect(x: 250, y: 210, width: 420, height: 500))     // the head
      c.setFillColor(UIColor(white: 0.96, alpha: 1).cgColor)
      c.fillEllipse(in: CGRect(x: 140, y: 660, width: 640, height: 720))     // the shoulders
    }
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("cs-dev-face.png")
    try? img.pngData()?.write(to: url)
    return url
  }()

  /// A fixed id, so the pigment and the plot are the same in every screenshot.
  static let id = UUID(uuidString: "b0000000-0000-4000-8000-0000000000c2")!
  /// A second fixed id, so the clash seats two golfers on two pigments.
  static let other = UUID(uuidString: "b0000000-0000-4000-8000-0000000000d7")!
}

struct CredDevView: View {
  @Environment(\.cs) private var cs
  let mode: String

  private var states: [String] {
    mode == "all" ? ["photo", "crest", "earned", "empty", "clash", "private", "loading", "long"] : [mode]
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s5) {
        ForEach(states, id: \.self) { s in
          VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
            Text(s).csType(.agate, caps: true).foregroundStyle(cs.mut)
            state(s)
          }
        }
      }
      .padding(CSTokens.Space.gutter)
    }
    .background(cs.bg0.ignoresSafeArea())
  }

  @ViewBuilder private func state(_ s: String) -> some View {
    switch s {
    // 1 · the flagship: the ladder's TOP legal rung, a photograph owning the
    // plate edge to edge, the earned slot, three figures on one rule.
    case "photo":
      CSCredential(golfer(slot: "Founder", figures: three), hasPhoto: true) {
        AsyncImage(url: CredDev.photo) { $0.resizable().scaledToFill() } placeholder: { crest }
      }
    // 2 · the marker floor, and it must be as designed as the photo version:
    // the contour of the home course, the crest bleeding off the right edge,
    // and NO gold field, because nothing was earned.
    case "crest":
      CSCredential(golfer(slot: nil, figures: two), hasPhoto: false) { crest }
    // 3 · earned, on the marker floor — the slot is the one gold field.
    case "earned":
      CSCredential(golfer(slot: "Founding member", figures: three), hasPhoto: false) { crest }
    // 4 · §6.2 · a golfer with no rounds: one figure, and the card still
    // renders. The form block below it is `CSEmpty`, on the page.
    case "empty":
      CSCredential(golfer(slot: nil, figures: [.init("0", label: "Rounds")]), hasPhoto: false) { crest }
    // 5 · §3 · **the clash** — two 56pt faces facing across ONE rule-and-figure,
    // on the page's own ground. No box, no shadow, no per-side WINS figures,
    // and a lead line that names a subject rather than a gender. It has a
    // harness state because it needs two golfers with a real record between
    // them, and the signed-in account has none.
    case "clash":
      CSClash(left: .init(id: CredDev.id, marker: "saguaro", isViewer: true), leftName: "You",
              right: .init(id: CredDev.other, marker: "thistle"), rightName: "Galen Marr",
              leftSub: "10.6 index · Tempe", rightSub: "10.2 index · Mesa") {
        VStack(spacing: CSTokens.Space.s1) {
          CSFigure("6–5", size: .l, label: nil)
          CSRule(.heavy)
          Text("You lead").csType(.agate, caps: true).foregroundStyle(cs.mut)
        }
        .frame(maxWidth: 120)
      }
    // 6 · §6.4 · private is not an error and is never dressed as one.
    case "private":
      CSCredential(
        CSCredentialGolfer(face: .init(id: CredDev.id, marker: nil), name: "", identity: "",
                            figures: [], club: "Cup Season"),
        hasPhoto: false) { CSTokens.dark.ceremony }
    // 7 · §6.1 · the destination's own geometry, redacted. No spinner.
    case "loading":
      CSCredential(golfer(slot: "Founder", figures: three), hasPhoto: false) { crest }
        .csRedacted(true)
    // 8 · §6.7 · a long name takes two lines and the object grows with it —
    // no tightening, no `minimumScaleFactor`.
    case "long":
      CSCredential(golfer(slot: "Founder", name: "Bartholomew Fotherington-Vance",
                          figures: three), hasPhoto: false) { crest }
    default:
      CSCredential(golfer(slot: nil, figures: two), hasPhoto: false) { crest }
    }
  }

  private var crest: CSCrestPlate {
    CSCrestPlate(marker: "saguaro", seed: "papago-golf-course", hasCourse: true)
  }

  private var three: [CSCredentialGolfer.Figure] {
    [.init("10.2", label: "Handicap index"),
     .init("31", label: "Rounds"),
     .init("1", label: "The Fellas", ordinal: "ST")]
  }
  private var two: [CSCredentialGolfer.Figure] {
    [.init("2", label: "Rounds"), .init("79", label: "Best · Papago")]
  }

  private func golfer(slot: String?, name: String = "Galen Marr",
                      figures: [CSCredentialGolfer.Figure]) -> CSCredentialGolfer {
    CSCredentialGolfer(
      face: .init(id: CredDev.id, marker: "saguaro", initials: "GM"),
      name: name,
      identity: CredentialCopy.identity(handle: "galenm", city: "Mesa, AZ", homeCourse: "Papago"),
      slot: slot,
      credit: "Galen’s round · Aug 24",
      figures: figures,
      club: CredentialCopy.club(markerName: CSMarkers.marker("saguaro").name))
  }
}
#endif
