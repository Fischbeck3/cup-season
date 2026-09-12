// Cup Season — the round photo's plumbing (`compressPhoto` 6544–6553, the
// `#postPhotoFile` / `#postScanFile` inputs 3159–3160).
//
// The camera needs `NSCameraUsageDescription` in the Info.plist or iOS kills
// the app on first use; that key lives in project.yml (not this slice's to
// edit), so the camera door opens only when the key is present.
//
// D298 · **THAT "ONLY WHEN THE KEY IS PRESENT" WAS WRITTEN AS AN EITHER/OR AND
// IT WAS THE BUG.** `if cameraAvailable { camera } else { library }` reads as a
// fallback, and on a real phone the key IS present, so the else branch never
// ran and the camera roll was unreachable from both photo doors. The owner,
// build 748: *"when I open a posted round I cant add a photo from camera roll
// only take one."* A photograph now comes through whichever door the golfer
// picks — `RoundPhotoSource` holds the list and `csPhotoSource` draws it.
//
// The SCAN keeps the camera on purpose: it photographs the card in front of
// the golfer, and the desk's own input says the same thing in one attribute
// (`capture="environment"` on `#postScanFile`, absent on `#postPhotoFile`).

import SwiftUI
import PhotosUI
import UIKit
import CupSeasonKit

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

  /// The same fact, as the MENU sees it. `-cs_dev_photo_menu` forces the camera
  /// row on so a simulator shot shows the phone's menu and not the one-row menu
  /// a camera-less machine would honestly draw. Release reads the fact.
  static var menuCameraAvailable: Bool {
    #if DEBUG
    return cameraAvailable || ReceiptPhotoDev.menu
    #else
    return cameraAvailable
    #endif
  }

  /// Load a picked library item as a UIImage; nil when it will not decode.
  static func load(_ item: PhotosPickerItem) async -> UIImage? {
    guard let data = try? await item.loadTransferable(type: Data.self) else { return nil }
    return UIImage(data: data)
  }
}

/// D298 · **THE CHOICE, IN FURNITURE THE PRODUCT ALREADY OWNS.** A
/// `confirmationDialog` is what iOS itself puts under a file input, and
/// `RootView`'s sign-out is the only other either/or in this app — so the menu
/// is the system's own idiom rather than a fourth sheet with a fourth set of
/// manners. `titleVisibility` is `.visible` because the title is the ACT the
/// golfer just pressed (`Add a photo` / `Replace photo`); without it two verbs
/// float on the screen with nothing saying what they are for.
///
/// What is IN the menu is `RoundPhotoSource.offered`'s to say, not this view's,
/// so the menu and the test that guards it read one producer.
extension View {
  func csPhotoSource(_ title: String, isPresented: Binding<Bool>,
                     pick: @escaping (RoundPhotoSource) -> Void) -> some View {
    confirmationDialog(title, isPresented: isPresented, titleVisibility: .visible) {
      ForEach(RoundPhotoSource.offered(cameraAvailable: PostPhoto.menuCameraAvailable), id: \.self) { source in
        Button(source == .library ? RoundCopy.photoFromLibrary : RoundCopy.photoFromCamera) { pick(source) }
      }
      // **NO TYPED CANCEL.** LINT-25 says the product has one dismiss verb and
      // it is `Close` — and an action sheet's cancel is not the product's word
      // to write: SwiftUI supplies one when no `.cancel` role is given, in the
      // system's own localisation, the way the PhotosPicker's own chrome does.
    }
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
  var completion: ((Bool, Bool) -> Void)? = nil
  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.completionWithItemsHandler = { _, completed, _, error in
      completion?(completed, error != nil)
    }
    return controller
  }
  func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
