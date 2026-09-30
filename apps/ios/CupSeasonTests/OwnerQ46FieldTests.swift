import Testing
import SwiftUI
import UIKit
import CSDesign
@testable import CupSeason

@MainActor @Suite struct OwnerQ46FieldTests {
  @Test func anUnfocusedFieldPaintsAThreeToOneEdgeInBothPrintings() throws {
    for scheme in [ColorScheme.dark, .light] {
      let host = HostedLayout(CSField(placeholder: "", text: .constant("")).environment(\.cs, scheme == .dark ? CSTokens.dark : CSTokens.light).padding(.horizontal, 20),
                              width: 375, height: 100, scheme: scheme)
      defer { host.tearDown() }
      let format = UIGraphicsImageRendererFormat(); format.scale = 1
      let image = UIGraphicsImageRenderer(size: CGSize(width: 375, height: 100), format: format).image { c in
        host.host.view.layer.render(in: c.cgContext)
      }
      let cg = try #require(image.cgImage)
      var bytes = [UInt8](repeating: 0, count: 375 * 100 * 4)
      let painted = bytes.withUnsafeMutableBytes { raw -> Bool in
        guard let context = CGContext(data: raw.baseAddress, width: 375, height: 100, bitsPerComponent: 8,
                                      bytesPerRow: 1500, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return false }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: 375, height: 100)); return true
      }
      #expect(painted)
      func luminance(_ x: Int) -> Double {
        let n = (25 * 375 + x) * 4
        let rgb = (0..<3).map { i -> Double in
          let s = Double(bytes[n + i]) / 255
          return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722
      }
      let edge = luminance(20), ground = luminance(24)
      #expect((max(edge, ground) + 0.05) / (min(edge, ground) + 0.05) >= 3,
              "\(scheme): the actual resting field edge must contrast with its fill")
    }
  }
}
