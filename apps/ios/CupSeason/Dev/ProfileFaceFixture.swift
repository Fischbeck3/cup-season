#if DEBUG
import SwiftUI
import CSDesign

/// An explicitly labelled test image, never a fabricated person or customer photo.
@MainActor enum ProfileFaceFixture {
  static var on: Bool {
    CompeteSelectedFixture.on && CompeteSelectedFixture.screen == "faces"
  }
  static let owner = UUID(uuidString: "FACE0000-0000-4000-8000-000000000001")!
  static var removed: Bool { ProcessInfo.processInfo.arguments.contains("-cs_face_removed") }
  static var imageURL: URL? { URL(string: CompeteSelectedFixture.arg("-cs_face_image", "")) }
  nonisolated static func id(_ tail: String) -> UUID { UUID(uuidString: "FACE0000-0000-4000-8000-\(tail)")! }
  static var photos: CSFacePhotoSource {
    let url = imageURL, removed = removed
    return CSFacePhotoSource(scope: owner, refreshProfile: removed ? id("000000000002") : nil) { id in
      if removed, id == Self.id("000000000002") { return .noPhoto }
      if id == Self.id("000000000002"), let url { return .photo(url) }
      if id == Self.id("000000000004") { return .photo(URL(string: "http://127.0.0.1:1/absent.png")!) }
      return .noPhoto
    }
  }
}

struct ProfileFaceFixtureView: View {
  @Environment(\.cs) private var cs
  private let sizes: [CSFace.Size] = [.inline, .slat, .list, .block, .crest]
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        CSPageHeader("Profile photos")
        Text("TEST IMAGE · NO REAL PROFILE DATA").csType(.agate).foregroundStyle(cs.mut)
        row("Photo", id: "000000000002", marker: "saguaro")
        row("No photo", id: "000000000003", marker: "lonetree")
        row("Failed load", id: "000000000004", marker: "shark")
        CSFace(.seeded(key: "QA guest", marker: "azalea"), size: .list, name: "Guest without profile")
        Text("Guest keeps their icon").csType(.bodyS)
      }
      .padding(CSTokens.Space.s5)
    }
    .background(cs.bg0)
  }
  private func row(_ title: String, id: String, marker: String) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      Text(title).csType(.bodyS)
      HStack(spacing: CSTokens.Space.s2) {
        ForEach(sizes, id: \.rawValue) { size in
          CSFace(.init(id: ProfileFaceFixture.id(id), marker: marker,
                       photoURL: ProfileFaceFixture.removed && id == "000000000002" ? ProfileFaceFixture.imageURL : nil), size: size,
                 name: "\(title) \(Int(size.rawValue))")
        }
      }
      CSRule()
    }
  }
}
#endif
