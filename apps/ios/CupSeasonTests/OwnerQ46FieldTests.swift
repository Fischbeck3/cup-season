import Testing
import SwiftUI
import UIKit
import CSDesign
@testable import CupSeason

@MainActor @Suite struct OwnerQ46FieldTests {
  @Test func anUnfocusedFieldPaintsAThreeToOneEdgeInBothPrintings() throws {
    for scheme in [ColorScheme.dark, .light] {
      // layer.render(in:) and drawHierarchy both paint an offscreen SwiftUI
      // host black in the unit runner; ImageRenderer draws the view itself
      let renderer = ImageRenderer(content: CSField(placeholder: "", text: .constant(""))
        .environment(\.cs, scheme == .dark ? CSTokens.dark : CSTokens.light)
        .environment(\.colorScheme, scheme)
        .padding(.horizontal, 20)
        .frame(width: 375, height: 100, alignment: .top))
      renderer.scale = 1
      let cg = try #require(renderer.cgImage)
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
