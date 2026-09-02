// Cup Season — `-cs_dev_cred <photo|crest|hero|herocrest>`: one credential
// over the root, in the state named, whatever the session is.
//
// Same trick and same reason as `-cs_dev_door` and `-cs_dev_live`: the card is
// the most reviewed object in the app and the hardest to reach — it needs an
// account, a season, trophies and a photograph. This shows it with none of
// them, so a change to it can be LOOKED AT before it ships. D197 shipped two
// regressions past a green test suite; a card is a thing you have to see.
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
  /// account and no network reviews nothing if the panel is a spinner.
  ///
  /// GREYSCALE on purpose, and not only to keep preflight 15 honest: a NEARLY
  /// WHITE subject under the name is the worst case the scrim has to survive,
  /// and a plausible warm portrait would have flattered it.
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
}

struct CredDevView: View {
  @Environment(\.cs) private var cs
  let mode: String

  private var withPhoto: Bool { mode == "photo" || mode == "hero" }
  private var isHero: Bool { mode.hasPrefix("hero") }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text(mode.uppercased()).csEyebrow()
        if isHero {
          YouHero(photoURL: withPhoto ? CredDev.photo : nil, marker: "saguaro", name: "Jerecho Fischbeck",
                  meta: "@jerecho · Tempe, AZ · Papago GC", indexCurrent: 12.4, rounds: 42,
                  trophyChips: ["🔥 Broke 80 · '26", "📈 4-week streak · '26", "⛳ First round · '26", "🎯 Broke 90 · '25", "📉 Personal best · '25"],
                  form: FormRow.from(beats: [true, true, true, false, true]),
                  anchor: { Text("GHIN 1234567 · est. Jul 2026").font(CSFont.footnote).foregroundStyle(cs.mut) })
        } else {
          CredentialCard(photoURL: withPhoto ? CredDev.photo : nil, marker: "saguaro", name: "Jerecho Fischbeck",
                         badge: .founder, meta: "@jerecho · Tempe, AZ · Papago GC",
                         indexCurrent: 12.4, rounds: 42,
                         trophyLines: ["🔥 Broke 80 · '26", "📈 4-week streak · '26", "⛳ First round · '26"],
                         // somebody ELSE's card: the form key's usual person, and the
                         // one worth looking at
                         form: FormRow.from(beats: [true, true, true, false, true]), isMe: false,
                         anchor: { Text("GHIN 1234567 · est. Jul 2026").font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut) },
                         extra: { EmptyView() }, settings: {})
        }
      }
      .padding(20)
    }
    .background(cs.bg0.ignoresSafeArea())
  }
}
#endif
