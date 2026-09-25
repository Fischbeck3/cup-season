// Cup Season — the receipt's brand moment, the phone half (D360 ledger row 8).
//
// The desk's `.rcpt-moment`: the course and the day in the metadata voice, the
// gross at the tournament figure in the BOARD face, the verdict beneath it in
// the serif, a neutral hairline, the tagline and the mark signing the corner —
// over the round's photograph under a scrim when there is one, and on the
// raised ground with a sparse contour when there is not. Every value is the
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
    ZStack(alignment: .topLeading) {
      ground
      VStack(alignment: .leading, spacing: 0) {
        if let course, !course.isEmpty {
          Text(course).csType(.agateS, caps: true).foregroundStyle(ink.opacity(0.86))
            .fixedSize(horizontal: false, vertical: true)
        }
        Text(dateline).csType(.agateS, caps: true).foregroundStyle(ink.opacity(0.86))
          .padding(.top, CSTokens.Space.s1)
        if let gross {
          // THE SCORE IS A TOURNAMENT FIGURE — the board face, never the serif
          Text("\(gross)").csType(.figureXL).foregroundStyle(ink)
            .padding(.top, CSTokens.Space.s4)
            .accessibilityLabel("\(gross) gross" + (holes.map { ", \($0) holes" } ?? ""))
        }
        if let sentence {
          // L-13 · the producer marks its figure `{2.5}`; CSFigureRun sets the
          // run in the board face and never renders (or speaks) the braces
          CSFigureRun(sentence, role: .story).foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: typeSize.isA11y ? .infinity : 300, alignment: .leading)
            .padding(.top, CSTokens.Space.s2)
        }
        CSRule(.hair, inset: 0, over: onPhoto ? .ceremony : .page)
          .frame(width: 64)
          .padding(.top, CSTokens.Space.s3)
        HStack(alignment: .center, spacing: CSTokens.Space.s3) {
          Text(CSBrandCopy.tagline.replacingOccurrences(of: "\n", with: " ")).csType(.agateS, caps: true).foregroundStyle(ink.opacity(0.7))
          Spacer(minLength: 0)
          CSBrandMark().frame(width: 34, height: 20).foregroundStyle(ink)
        }
        .padding(.top, CSTokens.Space.s4)
      }
      .padding(CSTokens.Space.s4)
      .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
    }
    .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .overlay(alignment: .topTrailing) {
      // D59 · the marker medallion rides every round photograph
      if onPhoto, let marker { MarkerStamp(marker: marker).padding(CSTokens.Space.s3) }
    }
    .task(id: photoURL) { photos.load(path: photoPath, url: photoURL) }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier(onPhoto ? "receipt.moment.photo" : "receipt.moment")
  }

  private var ink: Color { onPhoto ? CSTokens.dark.scrimInk : cs.ink }

  @ViewBuilder private var ground: some View {
    if let picture {
      ZStack {
        Image(uiImage: picture).resizable().scaledToFill()
        // the scrim: type over a photograph reads on its own ground (§10.3)
        LinearGradient(stops: [
          .init(color: CSDusk.ground.opacity(0.34), location: 0),
          .init(color: CSDusk.ground.opacity(0.62), location: 0.46),
          .init(color: CSDusk.ground.opacity(0.86), location: 1),
        ], startPoint: .top, endPoint: .bottom)
      }
    } else {
      ZStack(alignment: .trailing) {
        cs.bg1
        // the sparse contour, restrained, behind the figure's far side (§10.2)
        CSTopoField(.page, tint: cs.mut.opacity(CSTokens.Alpha.a16))
          .frame(width: 260, height: 200)
          .offset(x: 40)
      }
    }
  }
}
