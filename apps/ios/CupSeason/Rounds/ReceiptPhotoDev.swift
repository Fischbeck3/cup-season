// Cup Season — `-cs_dev_receipt_photo <none|on|skew>`: the three states of the
// round receipt's photograph slot (D293 / IOS-065), over whatever round the
// receipt opened.
//
// Same reason as `-cs_dev_cred <photo|crest|…>`, and the same posture. Two of
// the three states cannot be reached on this machine: `simctl` has no finger,
// so the PhotosPicker cannot be driven, and the migration that creates
// `set_round_photo` is written and unpushed, so an attach against prod cannot
// succeed even with one. A change to this slot has to be LOOKED AT before it
// ships, so the states are drawn rather than described.
//
// It overrides exactly two things — the round's `photo_path` / `photo_url`,
// and the one note line — and nothing else on the receipt. It writes nothing
// to the server, it never posts a round, and it does not exist in Release.

#if DEBUG
import SwiftUI
import UIKit

enum ReceiptPhotoDev {
  /// `none` · his round with no photograph, the state he arrives in.
  /// `on`   · the same round after attaching one.
  /// `skew` · the honest pre-migration answer, where the finger just was.
  static var mode: String? {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_receipt_photo"), i + 1 < a.count else { return nil }
    return a[i + 1]
  }

  /// A stand-in photograph, DRAWN rather than downloaded — the media bucket is
  /// private and a simulator with an expired token would review a grey box.
  ///
  /// GREYSCALE and abstract on purpose. **No place is fabricated**: it is a
  /// sky, a horizon and a ground MASS at 3:2, which is what `CSPlate`'s
  /// geometry and the marker medallion's scrim are being tested against — the
  /// same rule `CredDev.photo` follows for the face.
  ///
  /// IOS-066 · the COMPOSER's plate (`-cs_dev_post_seed photo`) reads the same
  /// image rather than drawing a second one. One stand-in photograph in the
  /// build, and one file on LINT-04's named exemption instead of two.
  static let image: UIImage = {
    let size = CGSize(width: 1200, height: 800)
    return UIGraphicsImageRenderer(size: size).image { ctx in
      let c = ctx.cgContext
      let sky = [UIColor(white: 0.86, alpha: 1).cgColor,
                 UIColor(white: 0.62, alpha: 1).cgColor] as CFArray
      if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceGray(), colors: sky, locations: [0, 1]) {
        c.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height * 0.58), options: [])
      }
      c.setFillColor(UIColor(white: 0.34, alpha: 1).cgColor)
      c.fill(CGRect(x: 0, y: size.height * 0.58, width: size.width, height: size.height * 0.42))
      c.setFillColor(UIColor(white: 0.46, alpha: 1).cgColor)
      c.fillEllipse(in: CGRect(x: -160, y: size.height * 0.40, width: 900, height: 320))
      c.setFillColor(UIColor(white: 0.26, alpha: 1).cgColor)
      c.fillEllipse(in: CGRect(x: 620, y: size.height * 0.46, width: 760, height: 260))
    }
  }()

  /// The same image, on disk, for the receipt's `AsyncImage`.
  static let photo: URL? = {
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("cs-dev-round-photo.png")
    try? image.pngData()?.write(to: url)
    return url
  }()

  /// The path the fixture stands in for. It is never sent anywhere — the
  /// receipt reads it only to decide which slot to draw.
  static let path = "cs-dev/round-photo.png"

  /// `-cs_dev_photo_menu` — D298's source menu, open on appear, with BOTH rows.
  ///
  /// The bug the owner found was that a menu did not exist; the fix IS a menu;
  /// and a menu on this machine cannot be opened, because `simctl` has no
  /// finger and the control that opens it is a button. So it is drawn.
  ///
  /// It forces the camera row too. The simulator has no camera, so
  /// `PostPhoto.cameraAvailable` is false there and the honest menu would be a
  /// menu of ONE — which is precisely the state that hid this bug for five
  /// waves of screenshots. The shot has to show the phone's menu.
  static var menu: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_photo_menu") }
}
#endif
