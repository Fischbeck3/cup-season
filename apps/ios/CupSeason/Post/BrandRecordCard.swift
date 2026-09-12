import SwiftUI
import CSDesign

/// Verified values supplied by the existing object, never calculated by the renderer.
struct BrandRecordCard: View {
  let kind: String
  let title: String
  let figure: String?
  let statement: String?
  let rows: [String]
  var earned = false
  var body: some View {
    CSArtifactFrame(kind) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s5) {
        Text(title).csFixed(.lead, 76).lineLimit(3).minimumScaleFactor(0.6)
        if let figure {
          Text(figure).csFixed(.figureXL, 180).lineLimit(2).minimumScaleFactor(0.45)
            .foregroundStyle(earned ? CSTokens.dark.gold : CSTokens.dark.ink)
        }
        if let statement, !statement.isEmpty {
          Text(statement).csFixed(.story, 44).lineLimit(4).minimumScaleFactor(0.7)
        }
        ForEach(Array(rows.prefix(5).enumerated()), id: \.offset) { _, row in
          Rectangle().fill(CSTokens.dark.mut.opacity(CSTokens.Alpha.a24)).frame(height: 1)
          Text(row).csFixed(.columnS, 30).lineLimit(3).minimumScaleFactor(0.65)
        }
      }
    }
  }
  @MainActor func shareItem() -> PostShareItem {
    let renderer = ImageRenderer(content: self)
    renderer.scale = 1
    var items: [Any] = []
    if let image = renderer.uiImage { items.append(image) }
    items.append(([title, figure, statement].compactMap { $0 } + rows).joined(separator: "\n"))
    return PostShareItem(items: items)
  }
}
