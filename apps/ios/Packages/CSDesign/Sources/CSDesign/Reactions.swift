// Cup Season — THE REACTION TOKENS, DRAWN (D309).
//
// The six emoji were the last foreign objects in the product. AP-5 states the
// rule everything else keeps — *"emoji are the six reaction glyphs and nothing
// else"* — and D277's Wave 8 collapsed four icon systems into one; the
// reactions were the fifth that survived, rendered in whatever face the phone
// supplies at whatever weight Apple ships this year, beside a drawn family at a
// fixed 1.8 stroke.
//
// **TWO OF THE FOUR WERE ALREADY DRAWN.** The Azalea and the Jug are markers #9
// and #10 of the fourteen — same 24 grid, same stroke, shipped since the marker
// picker. The owner named both by their meaning: *"the Azalea (giving them
// their flowers), the Jug (cheers)"*. They are **referenced from the marker
// table, never copied into this file**: a marker edit must reach the reaction,
// and two copies of one drawing is how a drawing starts to disagree with
// itself.
//
// **THE BOUNDARY THAT IS BENT, NAMED.** A marker is the IDENTITY primitive —
// `CSMarkerView` is deliberately internal so that *"a person is drawn exactly
// one way"*. Nothing here draws a person and nothing here uses `CSMarkerView`;
// this reads the same path table from inside the same module. But a golfer
// whose marker is the Azalea will meet their own glyph as a reaction, and that
// is accepted rather than unnoticed (D309).
//
// **THE SIZE FLOOR IS 17.** The azalea is six subpaths inside 14 of the 24
// grid; at 13pt its petals fill in and it reads as a blot. Every call site in
// the product renders at `.row` (17) or larger, and `Size` does not offer
// smaller — a floor the type system carries beats a floor in a comment.

import SwiftUI

/// The four. `key` is what the database stores (D309: the column is named
/// `emoji` and holds a NAME — the column keeps its name so an older installed
/// build still writes something readable rather than failing outright).
///
/// `word` is what a golfer reads and what VoiceOver says. The owner chose the
/// MEANING over the object: *flowers*, not *the azalea*.
public enum CSReactionToken: String, CaseIterable, Sendable, Identifiable, Hashable {
  case azalea, jug, eagle, rake

  public var id: String { rawValue }
  public var key: String { rawValue }

  /// The crew's word. Two seats of the six stay empty on purpose (D309) —
  /// nothing here covers momentum or a pure jab, and four right beats six with
  /// two nobody chose.
  public var word: String {
    switch self {
    case .azalea: "flowers"
    case .jug: "cheers"
    case .eagle: "the eagle"
    case .rake: "sandbagger"
    }
  }

  /// The one-thumb token (D310). It is the azalea and not a heater: the most
  /// common thing a golfer wants to say to a buddy is respect, not heat.
  public static let quick: CSReactionToken = .azalea

  /// An unknown key is NOT a reaction. Six rows of history fold to `azalea` in
  /// the migration, so in practice this answers only for a row written by a
  /// build that shipped before D309 — and the caller drops it rather than
  /// drawing a token the writer did not choose. That is the D25 correction's
  /// own lesson: identifying the same person by another column is honest;
  /// rendering a DIFFERENT reaction is not.
  public static func of(_ key: String?) -> CSReactionToken? {
    guard let key else { return nil }
    return CSReactionToken(rawValue: key)
  }

  /// The 24 × 24 path. The two markers are read from the marker table; the two
  /// new ones are drawn here.
  var path: String {
    switch self {
    case .azalea, .jug: CSMarkers.marker(rawValue).path
    // Two rings — what a scorecard already draws for an eagle. The one glyph in
    // the set nobody has to be taught.
    case .eagle:
      "M12 3.8a8.2 8.2 0 100 16.4 8.2 8.2 0 000-16.4M12 7.7a4.3 4.3 0 100 8.6 4.3 4.3 0 000-8.6"
    // The bunker rake: the accusation drawn as the thing you leave behind in
    // the sand. Handle, head, three tines — the centre tine continues the
    // handle's line, which is what a rake actually looks like.
    case .rake:
      "M4.5 20.5L12 13M9.2 10.2L14.8 15.8M10 11l1.9-1.9M12 13l1.9-1.9M14 15l1.9-1.9"
    }
  }
}

/// One reaction token, drawn. Optically fitted for the same reason a column of
/// markers is (`CSMarkerView`): the four were not drawn to a common extent —
/// the eagle runs the full 24 grid and the azalea sits inside 14 of it — so a
/// bounding-box fit puts a big ring beside a small flower and the row reads
/// ragged. The optical fit normalises the drawn HEIGHT, which is what makes
/// four hands look like one.
public struct CSReactionGlyph: View {
  /// **No size below 17.** See the file header: the azalea blots at 13.
  public enum Size: CGFloat, Sendable {
    case row = 17, chip = 20, tray = 26
  }

  public let token: CSReactionToken
  public let size: CGFloat
  /// A glyph beside its own count and word is decoration; a glyph alone is the
  /// control. Only the second one speaks (Y-33's rule for markers, same logic).
  public let labelled: Bool

  public init(_ token: CSReactionToken, size: Size = .row, labelled: Bool = false) {
    self.token = token; self.size = size.rawValue; self.labelled = labelled
  }

  public init(_ token: CSReactionToken, points: CGFloat, labelled: Bool = false) {
    self.token = token; self.size = max(17, points); self.labelled = labelled
  }

  public var body: some View {
    let raw = SVGPath.path(token.path)
    let t = CSMarkerView.opticalTransform(raw.boundingRect, into: size)
    // The stroke is ON THE 24 GRID and scales with the glyph — unscaled in an
    // optical fit it draws a 2.1pt line on an 18pt mark (Marker.swift).
    let scale = sqrt(abs(t.a * t.d))
    return raw
      .applying(t)
      .stroke(style: StrokeStyle(lineWidth: max(0.8, 1.8 * scale), lineCap: .round, lineJoin: .round))
      .frame(width: size, height: size)
      .accessibilityLabel(labelled ? token.word : "")
      .accessibilityHidden(!labelled)
  }
}
