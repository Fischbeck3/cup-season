// Cup Season — where the ME strip's four facts sit, at every type size
// (D258, IOS-039; IA §4.2's own acceptance test).
//
// **The strip is set entirely in IBM Plex Mono, so its width is arithmetic
// rather than a guess.** Plex Mono's advance is 600/1000 of the em in every
// weight the strip uses (read from the three bundled files, not remembered),
// so a word's width is its character count times ONE unit — and the view hands
// that unit in, measured off a ten-character probe set in the real face at the
// real size, rather than computing it from a point size.
//
// That last part is not fussiness. The first version of this file worked the
// unit out from `UIFontMetrics(forTextStyle: .caption2).scaledValue(for: 11)`,
// which is what `Font.custom(_:size:relativeTo:)` is documented to do — and at
// AX5 the two answers differ by about five points, so the strip believed
// `NUMBER` fitted and SwiftUI broke it across two lines to disagree. A measured
// unit cannot be wrong about the face it measured.
//
// What has to fit in a column is the WIDEST UNBREAKABLE RUN: the longest word.
// `YOUR NUMBER` wraps happily into a column that holds `NUMBER`; `BUILDING` at
// the same size is longer; and at AX5, or on a narrower phone, neither fits —
// at which point the strip stops trying to be two rows of two and gives each
// fact the whole line, which is the layout that can never truncate.
//
// IA §4.2 asks for two rows of two at AX3. This says two rows of two **while
// the arithmetic says every pair fits**, and one fact per row when it does not.
// A specified reflow that truncates is not the specified reflow.

import Foundation

public enum MeStripLayout {

  /// IBM Plex Mono's advance width, as a fraction of the point size. 600 units
  /// on a 1000-unit em, identical in Regular, Medium and SemiBold — which is
  /// what "monospaced" means. Kept as the documented constant behind
  /// `unit(pointSize:tracking:)`; the view measures instead of using it.
  public static let monoAdvance: Double = 0.6

  /// The tracking `MeStrip` sets on a label (`.tracking(1.2)`), in points per
  /// character. The value line wears none.
  public static let labelTracking: Double = 1.2

  /// Ten characters of the strip's own face. The view sets this at each of the
  /// two roles, reads the rendered width and divides by ten — one unit, in the
  /// face and at the size the golfer is actually looking at.
  public static let probe = "0123456789"

  /// The width one character occupies at a given point size and tracking. The
  /// arithmetic a test reasons with; the view measures the same quantity.
  public static func unit(pointSize: Double, tracking: Double = 0) -> Double {
    pointSize * monoAdvance + tracking
  }

  /// The width of one unbreakable run.
  public static func runWidth(_ word: String, unit: Double) -> Double {
    Double(word.count) * unit
  }

  /// The longest word in a string, measured the way it will be set. A string
  /// with no spaces is one word and is measured whole — which is exactly the
  /// case that broke: `CANYON` and `BUILDING` have nowhere to break.
  public static func widestWord(_ text: String, unit: Double) -> Double {
    text.split(whereSeparator: { $0 == " " || $0 == "\u{00A0}" })
      .map { runWidth(String($0), unit: unit) }
      .max() ?? 0
  }

  /// The narrowest column this slot can be given without a word being broken
  /// across two lines.
  public static func minColumn(_ s: MeStripCopy.Slot, valueUnit: Double, labelUnit: Double) -> Double {
    max(widestWord(s.value, unit: valueUnit), widestWord(s.label, unit: labelUnit))
  }

  /// **Two rows of two, or one fact per row.**
  ///
  /// `columnWidth` is what each of the two columns' TEXT actually gets — the
  /// content width, less the gutter and the slots' own hit-slop inset, halved.
  /// Everything must fit; one slot that does not is one fact a golfer cannot
  /// read, and a fact a golfer cannot read is a fact that is not on the screen.
  ///
  /// A unit of zero means "not measured yet", and the answer is then no: the
  /// one-fact-per-row layout is the one that is never wrong.
  public static func twoUp(_ slots: [MeStripCopy.Slot], columnWidth: Double,
                           valueUnit: Double, labelUnit: Double) -> Bool {
    guard slots.count >= 2, columnWidth > 0, valueUnit > 0, labelUnit > 0 else { return false }
    return slots.allSatisfy { minColumn($0, valueUnit: valueUnit, labelUnit: labelUnit) <= columnWidth }
  }

  /// The rows the grid draws: pairs, in the strip's own reading order, with a
  /// trailing odd fact taking the left column of a final row.
  public static func pairs(_ slots: [MeStripCopy.Slot]) -> [[MeStripCopy.Slot]] {
    stride(from: 0, to: slots.count, by: 2).map { Array(slots[$0..<min($0 + 2, slots.count)]) }
  }
}
