// Cup Season — `cropSquare` (index.html 13636–13642): centre-crop to a
// square, 512², JPEG q0.85. HEIC arrives as UIImage natively.

import UIKit

enum AvatarCrop {
  static func squareJPEG(_ data: Data, side: CGFloat, quality: CGFloat) -> Data? {
    guard let img = UIImage(data: data) else { return nil }
    let w = img.size.width, h = img.size.height
    let s = min(w, h)
    let origin = CGPoint(x: (w - s) / 2, y: (h - s) / 2)
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: {
      let f = UIGraphicsImageRendererFormat.default(); f.scale = 1; return f
    }())
    let out = renderer.image { _ in
      let scale = side / s
      img.draw(in: CGRect(x: -origin.x * scale, y: -origin.y * scale, width: w * scale, height: h * scale))
    }
    return out.jpegData(compressionQuality: quality)
  }
}
