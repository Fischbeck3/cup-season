// Cup Season — the round photo's plumbing (`compressPhoto` 6544–6553, the
// `#postPhotoFile` / `#postScanFile` inputs 3159–3160).
//
// The camera needs `NSCameraUsageDescription` in the Info.plist or iOS kills
// the app on first use; that key lives in project.yml (not this slice's to
// edit), so the camera door opens only when the key is present and falls
// back to the photo library otherwise — the web's `capture="environment"`
// was a hint, never a requirement, and the scan reads a library shot fine.

import SwiftUI
import PhotosUI
import UIKit

enum PostPhoto {
  /// `compressPhoto(file, maxDim, quality)`: bound the long side, JPEG.
  static func compress(_ image: UIImage, maxDim: CGFloat, quality: CGFloat) -> Data? {
    let w0 = image.size.width, h0 = image.size.height
    guard w0 > 0, h0 > 0 else { return nil }
    let s = min(1, maxDim / max(w0, h0))
    let size = CGSize(width: max(1, (w0 * s).rounded()), height: max(1, (h0 * s).rounded()))
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let out = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    return out.jpegData(compressionQuality: quality)
  }

  static func compress(data: Data, maxDim: CGFloat, quality: CGFloat) -> Data? {
    guard let img = UIImage(data: data) else { return nil }
    return compress(img, maxDim: maxDim, quality: quality)
  }

  /// The camera door is real only when the app may open it.
  static var cameraAvailable: Bool {
    Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil && UIImagePickerController.isSourceTypeAvailable(.camera)
  }

  /// Load a picked library item as a UIImage; nil when it will not decode.
  static func load(_ item: PhotosPickerItem) async -> UIImage? {
    guard let data = try? await item.loadTransferable(type: Data.self) else { return nil }
    return UIImage(data: data)
  }
}

/// `UIImagePickerController(.camera)` — the rear camera for the scan and the photo.
struct PostCameraPicker: UIViewControllerRepresentable {
  let onImage: (UIImage?) -> Void
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let vc = UIImagePickerController()
    vc.sourceType = .camera
    vc.cameraDevice = .rear
    vc.delegate = context.coordinator
    return vc
  }
  func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
  func makeCoordinator() -> Coordinator { Coordinator(self) }

  final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: PostCameraPicker
    init(_ parent: PostCameraPicker) { self.parent = parent }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
      let img = (info[.originalImage] as? UIImage)
      parent.onImage(img)
      parent.dismiss()
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
  }
}

/// `UIActivityViewController` — the native share sheet for the card and the link.
struct PostShareSheet: UIViewControllerRepresentable {
  let items: [Any]
  func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
  func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
