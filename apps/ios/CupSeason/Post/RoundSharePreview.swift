import SwiftUI
import CSDesign
import CupSeasonKit

/// One preview of the exact image and caption passed to the native share sheet.
/// The caller supplies an accepted, owned round. No league, money or other people
/// enter this template; its photo can only be the round's own attachment.
struct RoundSharePreview: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let recap: PostRecap
  let photo: UIImage?
  @State private var image: UIImage?
  @State private var share: PostShareItem?
  @State private var includePhoto = true

  private var publicRecap: PostRecap {
    recap.publicRoundCard
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          if let image {
            Image(uiImage: image).resizable().scaledToFit()
              .accessibilityLabel("Round card. \(publicRecap.name). \(publicRecap.gross) gross at \(publicRecap.course). \(publicRecap.date). Any time. Anywhere.")
          } else {
            Text("Couldn’t create your round card. Close and try again.").csType(.body)
          }
          if photo != nil {
            Toggle("Include round photo", isOn: $includePhoto).tint(cs.brand)
          }
          Text(publicRecap.caption).csType(.bodyS).foregroundStyle(cs.mut)

        }
        .padding(CSTokens.Space.gutter)
      }
      .background(cs.bg0)
      .safeAreaInset(edge: .bottom) {
        Button("Share") {
          guard let image else { return }
          share = PostShareItem(items: [image, publicRecap.caption])
        }
        .buttonStyle(.csPrimary()).disabled(image == nil)
        .accessibilityIdentifier("round.share.send")
        .padding(CSTokens.Space.gutter).background(cs.bg0)
      }
      .navigationTitle("Share round").navigationBarTitleDisplayMode(.inline)
      .csCloseButton { dismiss() }
    }
    .task {
      #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-cs_dev_share_no_photo") { includePhoto = false }
      #endif
      render()
    }
    .onChange(of: includePhoto) { _, _ in render() }
    .sheet(item: $share) { item in
      PostShareSheet(items: item.items) { completed, failed in
        CSTelemetry.event(failed ? "round_share_failed" : completed ? "round_share_completed" : "round_share_cancelled")
      }
    }
  }

  private func render() {
    image = RecapCardView.render(publicRecap, photo: includePhoto ? photo : nil)
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("-cs_dev_round_share_fixture") || ProcessInfo.processInfo.arguments.contains("-cs_dev_share_preview") || ProcessInfo.processInfo.arguments.contains("-cs_dev_share_export"),
       let png = image?.pngData() {
      let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      try? png.write(to: folder.appendingPathComponent(includePhoto && photo != nil ? "round-share-with-photo.png" : "round-share-no-photo.png"))
    }
    #endif
    if image != nil { CSTelemetry.event("round_share_generated", ["has_photo": .bool(includePhoto && photo != nil)]) }
  }
}
