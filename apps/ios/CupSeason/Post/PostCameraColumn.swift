// Cup Season — the camera stands beside the number (IOS-066).
//
// **THE PROBLEM, IN THE OWNER'S ORDER.** *"Our scorecard looks good lets show
// it off."* — and the audit and the re-score both put PHOTOGRAPHY as the
// single biggest ceiling on emotional appeal and premium feel. The product
// then asked for the picture in the quietest place it owns: `Add a photo` and
// `Scan the card` were two `CSMini`s under a `Details` head, below the fold,
// beside a date chip. On an SE with the keypad up — which is the state the
// composer OPENS in, because IOS-030 focuses the gross — the whole visible
// page was the gross, a sentence and a disclaimer. Not a pixel of camera.
//
// **THE PLATE IS THE FIGURE'S TWIN, AND THAT IS WHY IT COSTS NOTHING.** The
// gross is a rule-and-figure in a 150pt column with roughly 185pt of dead
// ground to its right on the narrowest phone the product supports. The
// photograph goes THERE: 150 wide, the figure column's own width, and 100
// tall, which is 3:2 — `CSPlate(.inset32)`, the same ratio and the same object
// the receipt draws a round's photograph in. The hero row becomes two columns
// of the same size: **the number, and the picture.** It is above the fold on
// every phone with the keypad up because it takes no vertical space that was
// not already empty, and it does not compete with the gross for the screen's
// one primary (§18) because it is quiet — one hairline, a drawn glyph and one
// agate word on the page's own ground. No ember, no fill, no shout.
//
// **AN EMPTY FRAME, NOT ANOTHER BUTTON.** §17 asks empty states to be
// invitations and §27 asks for fewer controls, not more. A frame the size and
// shape of the picture it wants shows a golfer exactly what will happen and
// exactly how big it will be; a third pill under a fourth head does not. And
// §32's warning does not bite: this is not a card wrapping content, it is the
// image's own boundary, which is the one thing a rounded rectangle is for.
//
// **SCAN AND PHOTO ARE TWO OFFERS ON ONE INSTRUMENT.** They were adjacent
// pills of identical weight, which reads as one choice with two labels. They
// are not: `Add a photo` attaches a memory, `Scan the card` READS THE ROUND
// and fills the scores — it is an alternative to the keypad, not to the
// picture. So the plate is the photograph, and the scan is a plain tertiary
// beneath it, in words. What ties them is real and already in the model:
// `PostRoundModel.apply(_:row:)` sets the scan's own shot as the round photo,
// so a scan LANDS IN THIS PLATE. That is why they share a column, and why
// they are not the same control.

import SwiftUI
import CSDesign
import CupSeasonKit

struct PostCameraColumn: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @Bindable var model: PostRoundModel
  let pickPhoto: () -> Void
  let pickScan: () -> Void

  /// The figure column's width, so the two columns of the hero are twins.
  /// `PostHeroContent` draws the gross at this width; changing one without
  /// the other breaks the composition the whole argument rests on.
  static let plateWidth: CGFloat = 150
  /// 3:2 — `CSPlate(.inset32)`'s own ratio, and within a few points of the
  /// rendered height of `figureXL` + its rule + its agate label.
  static let plateHeight: CGFloat = plateWidth * 2 / 3
  /// At an accessibility size the row becomes a column and the plate would
  /// take the whole measure — but 3:2 of a 362pt measure is 241pt, and an
  /// EMPTY frame that tall, before a number has been typed, owns the screen.
  /// 180 is the height the composer's own photo preview used before IOS-066,
  /// so the cap is the product's number rather than one invented here — and it
  /// is applied to the WIDTH so `CSPlate`'s own 3:2 still does the arithmetic.
  /// (Capping the height instead does not work: `.frame(height:)` does not
  /// clip, so the plate simply overflowed its frame and drew over the scan.)
  static let plateHeightA11y: CGFloat = 180
  static let plateWidthA11y: CGFloat = plateHeightA11y * 3 / 2

  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      plate
      // ONE offer under the plate, and it is the other thing a camera does.
      if model.scanEnabled {
        CSMini(model.scanning ? PostScan.readingLabel : "Scan the card",
               glyph: .camera, busy: model.scanning, action: pickScan)
          .accessibilityHint("Photographs your scorecard and fills the round in")
      }
    }
  }

  // MARK: - The plate

  /// Tap = pick. The remove is the ✕ on the picture's own corner rather than a
  /// third control in the column, so the column is the SAME HEIGHT empty or
  /// full and nothing under it jumps when a photograph arrives. The ✕ is an
  /// overlay on the BUTTON, never a button inside a button's label.
  ///
  /// **A DRAWN FRAME, NOT A SLAB.** `CSPlateWell` is the system's empty image
  /// field: one hairline in `rule`, the drawn `.photo` glyph and one agate
  /// word. This was a `bg2` fill for one build and the shot said no — a filled
  /// tile beside an EMPTY gross box outweighed the number the screen is for.
  private var plate: some View {
    Button(action: pickPhoto) {
      CSPlate(.inset32) {
        if let img = model.photo {
          Image(uiImage: img).resizable().scaledToFill()
        } else {
          CSPlateWell(label: RoundCopy.photoAdd)
        }
      }
      .frame(maxWidth: typeSize.isA11y ? Self.plateWidthA11y : Self.plateWidth)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .overlay(alignment: .topTrailing) { if model.photo != nil { clear } }
    .frame(maxWidth: typeSize.isA11y ? .infinity : nil, alignment: .leading)
    .accessibilityLabel(model.photo == nil ? RoundCopy.photoAdd : "Round photo, attached")
    .accessibilityHint(model.photo == nil ? "Opens your camera roll" : "Replaces the photo")
  }

  /// One tap, no arming: nothing has been posted yet, so this is "wrong
  /// picture", not a deletion. (The RECEIPT's remove is two taps — D293 —
  /// because there the object and the round both already exist.)
  private var clear: some View {
    Button { model.setPhoto(nil) } label: {
      CSGlyph(.cross, size: .inline)
        .foregroundStyle(cs.ink)
        .padding(CSTokens.Space.s2)
        .background(Circle().fill(cs.bg0.opacity(CSTokens.Alpha.a88)))
        .a11yMinTarget()
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Remove the photo")
  }
}
