// Cup Season — the credential's face panel: the photograph owns the card, and
// the marker owns it when there is no photograph.
//
// D199 sized the face by what it holds — 104pt for a photo, 64 for a marker —
// which was right about the diagnosis and timid about the cure. A photograph
// a golfer chose is the most specific thing on their card, so it takes the top
// of the card edge to edge and the identity rides over its bottom on a scrim.
//
// With no photo the marker is not a fallback: it is the CREST, drawn at ink on
// the look's wash, owning the same panel the photo would have. "ALWAYS the
// marker otherwise. No silhouette state." (index.html 10226) — said in a
// bigger voice.
//
// A photo would otherwise cost a golfer their glyph, so the marker rides small
// in the panel's bottom corner, opposite the name: the crest, or the corner —
// never neither, never both.

import SwiftUI
import CSDesign
import CupSeasonKit

struct CredentialFace<Sub: View, Trailing: View>: View {
  @Environment(\.dynamicTypeSize) private var typeSize

  let photoURL: URL?
  let marker: String?
  let name: String
  var badge: FoundingBadge? = nil
  /// "@handle · city · home course"
  let meta: String
  /// Passed, not read from the environment: the Tour Card's credential forces
  /// the dark palette on itself, so the ambient value is the wrong one while
  /// its body is building (D199).
  let p: CSPalette
  let accent: Color
  /// the line under the name — GHIN, member-since
  @ViewBuilder var sub: () -> Sub
  /// the panel's top corner — the gear on your own card
  @ViewBuilder var trailing: () -> Trailing

  /// The identity rides over the panel — but never at the accessibility sizes,
  /// where the copy grows into the picture. There it sits UNDER the panel on
  /// the card's own ground, which is the same trade D199 made and the same
  /// reason: legibility beats composition.
  private var riding: Bool { !typeSize.isA11y }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      panel
      if !riding { identity.padding(.horizontal, 16).padding(.top, 14) }
    }
  }

  // MARK: the panel

  private var panel: some View {
    Color.clear
      .aspectRatio(1, contentMode: .fit)
      .frame(maxWidth: .infinity)
      .overlay { fill }
      .overlay(alignment: .bottom) { if riding { scrim } }
      .overlay(alignment: .bottom) { if riding { band } }
      // the accessibility sizes take the identity off the panel, and the
      // marker was leaving with it — a photo card with no glyph anywhere is
      // the one outcome this panel is not allowed to produce
      .overlay(alignment: .bottomTrailing) { if photoURL != nil && !riding { corner.padding(14) } }
      .overlay(alignment: .topTrailing) { trailing().padding(10) }
      .clipped()
  }

  @ViewBuilder private var fill: some View {
    if let url = photoURL {
      AsyncImage(url: url) { phase in
        switch phase {
        case .success(let img): img.resizable().scaledToFill()
        // a photo that has not arrived — or will not — shows the crest, which
        // is what this golfer's card looks like without one anyway
        default: crest
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .accessibilityLabel("\(name)'s photo")
    } else {
      crest
    }
  }

  /// The marker at the size of an object rather than an avatar.
  private var crest: some View {
    ZStack {
      p.bg2
      RadialGradient(colors: [accent.opacity(0.28), .clear],
                     center: UnitPoint(x: 0.5, y: 0.34), startRadius: 0, endRadius: 280)
      GeometryReader { g in
        let side = min(g.size.width, g.size.height)
        CSMarkerView(key: marker, size: side * 0.46, lineWidth: 1.0)
          .foregroundStyle(p.ink.opacity(0.9))
          .frame(width: g.size.width, height: g.size.height, alignment: .center)
          .offset(y: -side * 0.07)   // clear of the name band
      }
    }
    .accessibilityLabel("Marker: \(CSMarkers.marker(marker).name)")
  }

  /// Bottom edge of the panel: the name at one end, the marker at the other.
  private var band: some View {
    HStack(alignment: .bottom, spacing: 12) {
      identity
      Spacer(minLength: 8)
      if photoURL != nil { corner }
    }
    .padding(16)
  }

  private var identity: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(name).font(CSFont.title).foregroundStyle(p.ink).lineLimit(2)
      FoundingTag(badge: badge).environment(\.cs, p).padding(.top, 1)
      if !meta.isEmpty {
        // over a photograph the muted token is not reliably legible — a photo
        // can be any tone under it, so the meta takes ink at a fixed remove
        Text(meta).font(CSFont.label).tracking(1.0).textCase(.uppercase)
          .foregroundStyle(riding ? p.ink.opacity(0.74) : p.mut)
      }
      sub()
    }
  }

  /// The tiny emblem — present only when the photo took the crest's place.
  private var corner: some View {
    CSMarkerView(key: marker, size: 20, lineWidth: 2)
      .foregroundStyle(p.ink)
      .padding(9)
      .background(p.bg1.opacity(0.82), in: Circle())
      .overlay(Circle().stroke(p.ink.opacity(0.3), lineWidth: 1))
      .shadow(color: .black.opacity(0.18), radius: 4, y: 1)
      .accessibilityLabel("Marker: \(CSMarkers.marker(marker).name)")
  }

  /// Ground for the name where it crosses a photograph. It is the card's own
  /// bg1, so a light-theme card gets a light scrim and dark ink — the panel
  /// stays part of the card instead of becoming a dark rectangle inside it.
  private var scrim: some View {
    LinearGradient(stops: [
      .init(color: .clear,              location: 0.0),
      .init(color: p.bg1.opacity(0.38), location: 0.34),
      .init(color: p.bg1.opacity(0.86), location: 0.7),
      // FULL bg1 at the last stop, or the panel's bottom edge shows as a seam
      // and the photograph reads as a picture pasted on the card rather than
      // the card's own top half
      .init(color: p.bg1,               location: 1.0)
    ], startPoint: .top, endPoint: .bottom)
      .frame(height: 230)
      .allowsHitTesting(false)
  }
}
