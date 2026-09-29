// Cup Season — the receipt's brand moment, the phone half (D360 ledger row 8).
//
// The desk's `.rcpt-moment`: the course and the day in the metadata voice, the
// gross at the tournament figure in the BOARD face, the verdict beneath it in
// the serif, a neutral hairline, the tagline and the mark signing the corner —
// under the round's photograph, a 3:2 plate, when there is one (§10.3, N4-070),
// and on the raised ground with a sparse contour when there is not. Every value is the
// round's own; a missing fact leaves its line absent. No invented round facts,
// no decorative ember: the only colours are ink, muted ink, the ground and the
// photograph.
//
// The photograph is read through `HomePhotoStore` by the round's own path, so
// a picture already up on Home is the same picture here — no second download
// — and a transient miss keeps what the store has.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ReceiptMoment: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let dateline: String
  let course: String?
  let gross: Int?
  let holes: Int?
  let sentence: String?
  let photoPath: String?
  let photoURL: URL?
  let marker: String?
  var photos: HomePhotoStore = .shared

  private var state: HomePhotoStore.State { photos.state(for: photoPath) }
  private var picture: UIImage? { state.image }
  private var onPhoto: Bool { picture != nil }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // N4-070 · root's ruling (UI_SYSTEM §10.3): a round photo "is a 3:2
      // plate when inset (the album, the receipt, the course page)". It is the
      // PLATE at the top of the moment, and the copy sets on the card's own
      // ground under it. The copy used to fill the card on the photograph
      // under an unnamed 0.34→0.86 wash, and its small lines measured 2.0 to
      // 3.4:1; there is no fourth scrim geometry to invent for that.
      if let picture {
        CSPlate(.inset32) { Image(uiImage: picture).resizable().scaledToFill() }
          // D59 · the marker medallion rides every round photograph
          .overlay(alignment: .topTrailing) {
            if let marker { MarkerStamp(marker: marker) }
          }
          .padding([.horizontal, .top], CSTokens.Space.s4)
          .accessibilityHidden(true)
      }
      ZStack(alignment: .topLeading) {
        // S9 · the ground is drawn, not read: VoiceOver reads the moment's
        // words, and the moment's focus ring is the card
        ground.accessibilityHidden(true)
        copy
      }
    }
    .background(cs.bg1)
    .clipShape(card)
    .task(id: photoURL) { photos.load(path: photoPath, url: photoURL) }
    .accessibilityElement(children: .combine)
    // S9 · the focus ring is the card. Hiding the ground was not enough: the
    // combined element still took the union of its children's frames (the
    // contour's offset), so it ran past the side of an SE. The accessibility
    // shape is the card's own.
    .contentShape(.accessibility, card)
    // the desk's alt: a moment over a photograph says it has one
    .accessibilityValue(onPhoto ? "Round photo" : "")
    .accessibilityIdentifier(onPhoto ? "receipt.moment.photo" : "receipt.moment")
  }

  /// The words, on the card's own ground whether or not there is a photograph.
  private var copy: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let course, !course.isEmpty {
        Text(course).csType(.agateS, caps: true).foregroundStyle(cs.ink.opacity(0.86))
          .fixedSize(horizontal: false, vertical: true)
      }
      Text(dateline).csType(.agateS, caps: true).foregroundStyle(cs.ink.opacity(0.86))
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, CSTokens.Space.s1)
      if let gross {
        // THE SCORE IS A TOURNAMENT FIGURE — the board face, never the serif
        Text("\(gross)").csType(.figureXL).foregroundStyle(cs.ink)
          .padding(.top, CSTokens.Space.s4)
          .accessibilityLabel("\(gross) gross" + (holes.map { ", \($0) holes" } ?? ""))
      }
      if let sentence {
        // L-13 · the producer marks its figure `{2.5}`; CSFigureRun sets the
        // run in the board face and never renders (or speaks) the braces
        CSFigureRun(sentence, role: .story).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: typeSize.isA11y ? .infinity : 300, alignment: .leading)
          .padding(.top, CSTokens.Space.s2)
      }
      CSRule(.hair, inset: 0, over: .page)
        .frame(width: 64)
        .padding(.top, CSTokens.Space.s3)
      HStack(alignment: .center, spacing: CSTokens.Space.s3) {
        Text(CSBrandCopy.tagline.replacingOccurrences(of: "\n", with: " ")).csType(.agateS, caps: true).foregroundStyle(cs.ink.opacity(0.7))
        Spacer(minLength: 0)
        CSBrandMark().frame(width: 34, height: 20).foregroundStyle(cs.ink)
      }
      .padding(.top, CSTokens.Space.s4)
    }
    .padding(CSTokens.Space.s4)
    // the photograph above carries the moment's height; without one the copy
    // holds the card open on its own ground
    .frame(maxWidth: .infinity, minHeight: onPhoto ? nil : 280, alignment: .topLeading)
  }

  /// The card's one shape: what it is clipped to, and the accessibility
  /// frame VoiceOver draws round it.
  private var card: RoundedRectangle { RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous) }

  /// The card's own ground: the sparse contour behind the figure's far side
  /// when there is no photograph (§10.2). Under a photograph's plate the copy
  /// sits on the plain ground.
  @ViewBuilder private var ground: some View {
    if !onPhoto {
      ZStack(alignment: .trailing) {
        cs.bg1
        CSTopoField(.page, tint: cs.mut.opacity(CSTokens.Alpha.a16))
          .frame(width: 260, height: 200)
          .offset(x: 40)
      }
    }
  }
}
