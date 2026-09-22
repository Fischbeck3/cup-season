import SwiftUI
import CSDesign
import CupSeasonKit

/// One preview of the exact image and caption passed to the native share sheet.
/// The caller supplies an accepted, owned round. No league, money or other people
/// enter this template; its photo can only be the round's own attachment.
struct RoundSharePreview: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(\.toast) private var toast
  let recap: PostRecap
  let photo: UIImage?
  /// W2 (D380) · the round the link is minted for. nil (a fixture, an older
  /// caller) shares the card alone, as before.
  var roundId: UUID? = nil
  @State private var image: UIImage?
  @State private var share: PostShareItem?
  @State private var includePhoto = true
  @State private var linking = false

  private var publicRecap: PostRecap {
    recap.publicRoundCard
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          if let image {
            Image(uiImage: image).resizable().scaledToFit()
              // The identifier names the composition that was actually
              // rendered — `RecapCardView.render` was handed the photograph or
              // it was not — so a test can read the opt-out's effect on the
              // OUTPUT rather than on the switch.
              .accessibilityIdentifier(includePhoto && photo != nil ? "round.share.card.withPhoto" : "round.share.card.noPhoto")
              .accessibilityLabel("Round card. \(publicRecap.name). \(publicRecap.gross) gross at \(publicRecap.course). \(publicRecap.date). Any time. Anywhere.")
          } else {
            Text("Couldn’t create your round card. Close and try again.").csType(.body)
          }
          if photo != nil {
            // D359 · an ordinary control takes the action colour; ember is
            // reserved for an active competition and a share sheet is not one.
            Toggle(RoundCopy.photoInclude, isOn: $includePhoto).tint(cs.act)
            // W2 · the answer governs the card, the public page and the preview
            if roundId != nil { Text(RoundCopy.photoIncludeFine).csType(.bodyS).foregroundStyle(cs.mut) }
          }
          Text(publicRecap.caption).csType(.bodyS).foregroundStyle(cs.mut)

        }
        .padding(CSTokens.Space.gutter)
      }
      .background(cs.bg0)
      .safeAreaInset(edge: .bottom) {
        Button("Share") {
          guard let image else { return }
          // W2 (D380) · ONE action: the card and the link leave together. The
          // link is minted with the toggle's answer, and the card that was
          // rendered — with or without the photo — is what the preview shows.
          guard let roundId else { share = PostShareItem(items: [image, publicRecap.caption]); return }
          linking = true
          Task {
            defer { linking = false }
            do {
              let url = try await PostService().shareLink(round: roundId, includePhoto: includePhoto && photo != nil, card: image.pngData()) { data in
                PostPhoto.compress(data: data, maxDim: 1600, quality: 0.8)
              }
              share = PostShareItem(items: [image, publicRecap.caption, url])
            } catch {
              // the link could not be minted: the card still goes, and the golfer hears why
              toast.show(HumanError.text(error, prefix: "Could not make the link."), kind: .failed)
              share = PostShareItem(items: [image, publicRecap.caption])
            }
          }
        }
        .buttonStyle(.csPrimary(busy: linking)).disabled(image == nil)
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
