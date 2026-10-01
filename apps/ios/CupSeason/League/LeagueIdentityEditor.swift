import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import ImageIO
import CSDesign
import CupSeasonKit

struct LeagueIdentityEditor: View {
  @Environment(LeagueIdentityStore.self) private var identities
  @Environment(\.dismiss) private var dismiss
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  let leagueID: UUID
  let name: String
  @State private var description: String
  @State private var kind: LeagueIdentity.ImageKind
  @State private var image: UIImage?
  @State private var removed = false
  @State private var selection: PhotosPickerItem?
  @State private var importing = false
  @State private var busy = false
  @State private var reading = false
  @State private var error: String?
  @State private var showsDiscard = false
  private let originalDescription: String
  private let originalKind: LeagueIdentity.ImageKind

  init(leagueID: UUID, name: String, identity: LeagueIdentity?) {
    self.leagueID = leagueID; self.name = name
    originalDescription = identity?.description ?? ""
    originalKind = identity?.image_kind ?? .photo
    _description = State(initialValue: originalDescription)
    _kind = State(initialValue: originalKind)
  }
  private var dirty: Bool {
    description != originalDescription || kind != originalKind || image != nil || removed
  }
  private var hasImage: Bool { image != nil || (!removed && identities.identities[leagueID]?.image_path != nil) }
  private var descriptionLength: Int { description.unicodeScalars.count }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          HStack(spacing: CSTokens.Space.s4) {
            LeagueIdentityMark(leagueID: leagueID, name: name, imageOverride: image,
                               kindOverride: kind, hidesImage: removed)
            Text(name).csType(.displayS).fixedSize(horizontal: false, vertical: true)
          }.listRowBackground(cs.bg0)
        }
        Section("Image") {
          Picker("Display as", selection: $kind) {
            Text("Photo").tag(LeagueIdentity.ImageKind.photo)
            Text("Logo").tag(LeagueIdentity.ImageKind.logo)
          }.pickerStyle(.segmented)
          PhotosPicker(selection: $selection, matching: .images) {
            Label(hasImage ? "Replace from Photos" : "Choose from Photos", systemImage: "photo")
              .frame(minHeight: 44)
          }.accessibilityIdentifier("league.identity.photos")
          Button { importing = true } label: {
            Label("Choose from Files", systemImage: "folder").frame(minHeight: 44)
          }.accessibilityIdentifier("league.identity.files")
          if hasImage {
            Button("Remove image", role: .destructive) {
              image = nil; selection = nil; removed = true; error = nil
            }.frame(minHeight: 44).accessibilityIdentifier("league.identity.remove")
          }
          if reading {
            Text("Reading image…").csType(.bodyS).foregroundStyle(cs.mut)
              .accessibilityIdentifier("league.identity.reading")
          }
          Text("Photos fill the square. Logos fit inside it. Without an image, your league keeps its initial mark.")
            .csType(.bodyS).foregroundStyle(cs.mut)
        }
        Section("Description") {
          CSField(placeholder: "A few words about your group", text: $description, multiline: true)
            .accessibilityIdentifier("league.identity.description")
          Text("\(descriptionLength) of 160 characters").csType(.agate)
            .foregroundStyle(descriptionLength > 160 ? cs.neg : cs.mut)
        }
      }
      .disabled(busy)
      .scrollContentBackground(.hidden).background(cs.bg0)
      .safeAreaInset(edge: .bottom, spacing: 0) {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          CSRule()
          if let error {
            Text(error).csType(.bodyS).foregroundStyle(cs.neg)
              .fixedSize(horizontal: false, vertical: true)
              .accessibilityIdentifier("league.identity.error")
          }
          Button(busy ? "Saving…" : "Save") { save() }
            .buttonStyle(CSPrimaryStyle(busy: busy))
            .disabled(busy || reading || descriptionLength > 160 || !dirty)
            .accessibilityIdentifier("league.identity.save")
        }.padding(.bottom, CSTokens.Space.s3).csGutter()
          .frame(maxWidth: .infinity, alignment: .leading).background(cs.bg0)
      }
      .navigationTitle("League identity").navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Close") { if dirty { showsDiscard = true } else { dismiss() } }
            .buttonStyle(.csTertiary(.toolbar))
            .disabled(busy).accessibilityIdentifier("league.identity.close")
        }
      }
      .tint(cs.act)
      .interactiveDismissDisabled(dirty || busy)
      .confirmationDialog("Discard these changes?", isPresented: $showsDiscard, titleVisibility: .visible) {
        Button("Discard changes", role: .destructive) { dismiss() }
        Button("Keep editing", role: .cancel) {}
      }
      .fileImporter(isPresented: $importing, allowedContentTypes: [.image]) { result in
        switch result {
        case .success(let url):
          let access = url.startAccessingSecurityScopedResource()
          defer { if access { url.stopAccessingSecurityScopedResource() } }
          do {
            if let bytes = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, bytes > 64 * 1_048_576 {
              self.error = "That image is too large to read. Choose a smaller one."; return
            }
            let data = try Data(contentsOf: url)
            accept(data)
          } catch { self.error = "Could not read that image. Choose another file." }
        case .failure: error = "Could not open the file. Try choosing it again."
        }
      }
      .task(id: selection) {
        guard let selection else { return }
        reading = true
        defer { if self.selection == selection { reading = false } }
        do {
          if let data = try await selection.loadTransferable(type: Data.self), !Task.isCancelled { accept(data) }
          else if !Task.isCancelled { error = "That image could not be read. Choose another one." }
        } catch { if !Task.isCancelled { self.error = "Could not read that image. Choose another one." } }
      }
    }
  }
  private func accept(_ data: Data) {
    guard data.count <= 64 * 1_048_576 else {
      error = "That image is too large to read. Choose a smaller one."; return
    }
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1600,
            kCGImageSourceShouldCacheImmediately: true
          ] as CFDictionary) else {
      error = "Choose a photo or a PNG or JPEG logo."; return
    }
    image = UIImage(cgImage: thumbnail); removed = false; error = nil
  }
  private func encodedImage() -> Data? {
    guard let image else { return nil }
    if kind == .photo { return PostPhoto.compress(image, maxDim: 1600, quality: 0.85) }
    let scale = min(1, 1600 / max(image.size.width, image.size.height))
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1; format.opaque = false
    let size = CGSize(width: max(1, (image.size.width * scale).rounded()),
                      height: max(1, (image.size.height * scale).rounded()))
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }.pngData()
  }
  private func save() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    error = nil
    let data = encodedImage()
    if image != nil, data == nil { error = "Could not prepare that image. Choose another one."; return }
    if let data, data.count > 8_388_608 { error = "That logo is too large. Choose a smaller image."; return }
    #if DEBUG
    if ClubSpreadFixture.on {
      error = "Fixture save refused. Your changes are still here."; return
    }
    #endif
    busy = true
    Task {
      defer { busy = false }
      do {
        try await identities.save(leagueID: leagueID, description: description,
                                  imageKind: kind, image: data, removeImage: removed)
        toast.show("League identity saved", kind: .confirmed)
        dismiss()
      } catch { self.error = roomError(error, "Could not save. Your changes are still here; try again.") }
    }
  }
}
