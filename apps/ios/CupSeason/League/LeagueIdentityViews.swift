import SwiftUI
import CSDesign
import CupSeasonKit

/// A stable league mark. Phase and personal appearance never pick its livery.
struct LeagueIdentityMark: View {
  @Environment(LeagueIdentityStore.self) private var identities
  @Environment(LookStore.self) private var looks
  @Environment(\.cs) private var cs
  @Environment(\.colorScheme) private var scheme
  let leagueID: UUID
  let name: String
  var size: CGFloat = CSFace.Size.crest.rawValue
  var fillsSquare = false
  var imageOverride: UIImage?
  var kindOverride: LeagueIdentity.ImageKind?
  var hidesImage = false

  private var identity: LeagueIdentity? { identities.identities[leagueID] }
  private var kind: LeagueIdentity.ImageKind { kindOverride ?? identity?.image_kind ?? .photo }
  private var look: CSLookSpec {
    let chosen = looks.loaded ? looks.leagueLooks[leagueID] : identity?.look
    if let chosen, let spec = CSLooks.spec(chosen), spec.window != nil { return spec }
    // UUID bytes are stable across launches; random Swift hashes aren't.
    let pairs = ["may", "teams", "holidays"]
    let index = Int(leagueID.uuid.15) % pairs.count
    return CSLooks.spec(pairs[index])!
  }
  private var fallback: some View {
    let theme: CSTheme = scheme == .light ? .light : .dark
    let ground = look.accent2(theme)
    return ZStack {
      if size <= CSFace.Size.block.rawValue { cs.bg1 }
      else {
        ground
        LeagueIdentityDiagonal().fill(look.accent(theme))
      }
      Text(LeagueIdentity.initials(name))
        .csType(size <= CSFace.Size.block.rawValue ? .figureM : .figureXL, caps: true)
        .foregroundStyle(size <= CSFace.Size.block.rawValue ? cs.ink : CSInk.on(ground))
        .lineLimit(1).minimumScaleFactor(0.4)
        .padding(CSTokens.Space.s2)
      if size <= CSFace.Size.block.rawValue {
        VStack {
          Spacer()
          HStack(spacing: 0) { look.accent(theme); ground }.frame(height: CSTokens.Space.s1)
        }
      }
    }
  }
  var body: some View {
    ZStack {
      fallback
      if !hidesImage {
        if let imageOverride { image(imageOverride) }
        else if let url = identities.imageURLs[leagueID] {
          if url.isFileURL, let local = UIImage(contentsOfFile: url.path) {
            image(local)
          } else {
            LeagueIdentityRemoteImage(url: url, kind: kind)
          }
        }
      }
    }
    .frame(width: fillsSquare ? nil : size, height: fillsSquare ? nil : size)
    .aspectRatio(1, contentMode: .fit).clipped()
    .accessibilityHidden(true)
  }
  private func image(_ image: UIImage) -> some View {
    LeagueIdentityBitmap(image: image, kind: kind)
  }
}

private struct LeagueIdentityRemoteImage: View {
  let url: URL
  let kind: LeagueIdentity.ImageKind
  @State private var image: UIImage?
  var body: some View {
    Group { if let image { LeagueIdentityBitmap(image: image, kind: kind) } }
      .task(id: url) {
        image = nil
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              !Task.isCancelled else { return }
        image = UIImage(data: data)
      }
  }
}

private struct LeagueIdentityBitmap: View {
  @Environment(\.cs) private var cs
  let image: UIImage
  let kind: LeagueIdentity.ImageKind
  var body: some View {
    if kind == .logo {
      ZStack {
        // Transparent dark and white logos both get a readable neutral backing.
        prefersLightBacking ? cs.leaf : CSTokens.dark.bg1
        Image(uiImage: image).resizable().scaledToFit().padding(CSTokens.Space.s3)
      }
    } else { Image(uiImage: image).resizable().scaledToFill() }
  }
  private var prefersLightBacking: Bool {
    guard let cg = image.cgImage else { return true }
    let side = 16
    var pixels = [UInt8](repeating: 0, count: side * side * 4)
    let measured = pixels.withUnsafeMutableBytes { bytes -> Bool in
      guard let context = CGContext(data: bytes.baseAddress, width: side, height: side,
        bitsPerComponent: 8, bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
      context.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side)); return true
    }
    guard measured else { return true }
    var brightness = 0.0, alpha = 0.0
    for i in stride(from: 0, to: pixels.count, by: 4) {
      let a = Double(pixels[i + 3]) / 255
      guard a > 0 else { continue }
      brightness += (0.2126 * Double(pixels[i]) + 0.7152 * Double(pixels[i + 1]) + 0.0722 * Double(pixels[i + 2])) / 255
      alpha += a
    }
    return alpha == 0 || brightness / alpha < 0.5
  }
}

private struct LeagueIdentityDiagonal: Shape {
  func path(in rect: CGRect) -> Path {
    Path { p in
      p.move(to: rect.origin)
      p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
      p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
      p.closeSubpath()
    }
  }
}

struct LeagueIdentityPeople: View {
  @Environment(LeagueIdentityStore.self) private var identities
  @Environment(\.cs) private var cs
  let identity: LeagueIdentity
  let viewer: UUID?

  var body: some View {
    if let line = identity.peopleLine(viewer: viewer) {
      HStack(alignment: .center, spacing: CSTokens.Space.s2) {
        HStack(spacing: CSTokens.Space.s1) {
          ForEach(Array(identity.people.prefix(3))) { person in face(person) }
        }.accessibilityHidden(true)
        Text(line).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
  private func face(_ person: LeagueIdentity.Person) -> CSFace {
    let model = CSFace.Model(id: person.id, marker: person.marker,
                            photoURL: identities.avatarURLs[person.id],
                            initials: LeagueIdentity.initials(person.name ?? ""),
                            isViewer: person.id == viewer)
    return CSFace(model, size: .inline)
  }
}

struct LeagueIdentityHeading: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let leagueID: UUID
  let name: String

  var body: some View {
    A11yStack(alignment: .leading, rowAlignment: .center, spacing: CSTokens.Space.s3) {
      LeagueIdentityMark(leagueID: leagueID, name: name, size: CSFace.Size.block.rawValue)
      Text(name).csType(.displayS).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

/// Identity first, one compact season record next. The game producer stays upstream.
struct LeagueIdentitySpread: View {
  @Environment(LeagueIdentityStore.self) private var identities
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let row: CompeteRoot.Row
  let viewer: UUID?
  let onTap: () -> Void

  private var identity: LeagueIdentity? { row.leagueId.flatMap { identities.identities[$0] } }
  private var description: String? { identity?.description.flatMap { $0.isEmpty ? nil : $0 } }
  private var fullWidthCopy: Bool {
    typeSize.isAccessibilitySize || row.title.count > 30 || (description?.count ?? 0) > 48
  }
  private var support: String { row.competitionLine ?? row.sub }
  private var standing: String? {
    row.pointsStanding ?? row.rank.map { CSCopy.ordinal($0.place) + ($0.tied ? " · Tied" : "") }
  }
  private var spoken: String {
    [row.title, description, identity?.peopleLine(viewer: viewer), row.eyebrow,
     row.points.map { "\(CSCopy.points($0)) points" }, standing,
     row.rank.map { "Out of \($0.of)" }, support]
      .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ". ")
  }

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        A11yStack(alignment: .leading, rowAlignment: .top, spacing: CSTokens.Space.s4,
                  forceColumn: row.title.count > 30) {
          if let id = row.leagueId {
            LeagueIdentityMark(leagueID: id, name: row.title, fillsSquare: true)
              .containerRelativeFrame(.horizontal) { width, _ in width * 0.35 }
          }
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            Text(row.title).csType(.display).foregroundStyle(cs.ink)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity, alignment: .leading)
            if !fullWidthCopy { copy }
          }
        }
        if fullWidthCopy { copy }
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          CSRule()
          A11yStack(alignment: .leading, rowAlignment: .firstTextBaseline,
                    spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s2) {
            Text(row.eyebrow).csType(.agate, caps: true).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity, alignment: .leading)
            if let points = row.points {
              Text([standing, "\(CSCopy.points(points)) pts"].compactMap { $0 }.joined(separator: " · "))
                .csType(.name).foregroundStyle(cs.ink)
                .fixedSize(horizontal: false, vertical: true)
            } else if let standing {
              Text(standing).csType(.name).foregroundStyle(cs.ink)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          if !support.isEmpty {
            Text(support).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
      .multilineTextAlignment(.leading)
      .padding(.vertical, CSTokens.Space.s3)
      .frame(maxWidth: .infinity, minHeight: CSTokens.Space.rail, alignment: .leading)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) { CSRule() }
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel(spoken).accessibilityHint("Opens the season")
    .accessibilityIdentifier("compete.row.\(row.id)")
  }
  @ViewBuilder private var copy: some View {
    if let description {
      Text(description).csType(.bodyS).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
    }
    if let identity { LeagueIdentityPeople(identity: identity, viewer: viewer) }
  }
}
