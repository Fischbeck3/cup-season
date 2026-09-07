// Cup Season — empty, loading, stale (UI_SYSTEM §13).
//
// **THE DOOR IS A REQUIRED PARAMETER, SO THE LINT IS THE SWIFT COMPILER**
// (`LINT-21`). Three shipped call sites pass a `cta` that goes nil when a link
// is missing, so the door silently vanishes on exactly the surfaces that need
// one. `Door` is a non-optional enum, never a `View?`, never nil-able.
//
// `.elsewhere` is what makes the parameter survivable: Home's quiet wire-empty
// genuinely has no door of its own — its door IS the floor's lit door — and
// without a third case Phase 3 would either pass a dummy control or make the
// parameter optional and delete the check.

import SwiftUI

public struct CSEmpty: View {
  @Environment(\.cs) private var cs

  public enum Door {
    case primary(String, () -> Void)
    case link(String, () -> Void)
    /// A reference line, not a control: *"The four doors are at the foot of
    /// this page."*
    case elsewhere(String)
  }

  /// **A drawn object, 56–76pt, in `mut`** — the one exception to the icon
  /// scale, and it is the loudest thing on an empty screen because it should
  /// be. `rule` at 2.66 / 2.30 is a ghost, and rule separates but never states.
  ///
  /// **Two absences never share an object.** A blank scorecard means *you have
  /// no rounds*; an empty rail means *a board with nobody on it*; a schedule
  /// sheet means *nothing is scheduled*.
  let glyph: CSGlyph.Name
  let eyebrow: String
  /// **A fact about the world, never the golfer's omission.** The test: could
  /// the golfer have prevented this sentence by doing something? If yes,
  /// rewrite it. *"Nobody here has played it."* — not *"Nothing in the bag
  /// yet."*
  let headline: String
  /// One true fact, if one exists: *"Dinosaur Mountain is on the board because
  /// Galen keeps it."*
  let fact: String?
  /// A number where one exists — an unfilled star rail, a `0` in a panel, a
  /// blank rail. Not one canonical empty state in the shipped product contains
  /// an image, a shape or a number.
  let number: Number?
  let door: Door

  public enum Number {
    case panel(String, String)     // figure, unit
    case stars                     // an unfilled rail
  }

  public init(glyph: CSGlyph.Name, eyebrow: String, headline: String,
              fact: String? = nil, number: Number? = nil, door: Door) {
    self.glyph = glyph; self.eyebrow = eyebrow; self.headline = headline
    self.fact = fact; self.number = number; self.door = door
  }

  public var body: some View {
    HStack(alignment: .top, spacing: CSTokens.Space.s4) {
      CSGlyph(glyph, size: .empty, labelled: true).foregroundStyle(cs.mut)
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        Text(eyebrow).csType(.agate, caps: true).foregroundStyle(cs.mut)
        Text(headline).csType(.lead).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
        if let fact {
          Text(fact).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        if let number {
          switch number {
          case .panel(let v, let u): CSPanel(unit: u) { Text(v).csType(.figureM) }
          case .stars: CSStarRail(0)
          }
        }
        switch door {
        case .primary(let t, let a): CSDoor(.primary(t, a))
        case .link(let t, let a): CSDoor(.link(t, a))
        case .elsewhere(let line):
          Text(line).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, CSTokens.Space.s4)
  }
}

// MARK: - Loading

public extension View {
  /// **The destination's own geometry, redacted.** The real rows, the real
  /// heights, the rail slots and the rules all present; the type replaced by
  /// blocks with real-length placeholder widths.
  ///
  /// **Never a spinner inside content** (`LINT-22`) — the full-screen spinner
  /// beside the word "Loading…" is deleted. A spinner inside a CONTROL is legal
  /// and stays: it is the control saying it is working, and it is three mono
  /// dots that tally.
  @ViewBuilder func csRedacted(_ loading: Bool) -> some View {
    if loading {
      redacted(reason: .placeholder).allowsHitTesting(false).accessibilityHidden(true)
    } else {
      unredacted()
    }
  }
}

// MARK: - Stale

/// **Keep what is on screen.** Cached content renders under an agate dateline
/// reading `AS OF FRI 6:12 PM · OFFLINE`, at `mut`, with **no action
/// disabled**. A failed read is never an empty one.
public struct CSStale: View {
  @Environment(\.cs) private var cs
  let asOf: Date
  let calendar: Calendar
  public init(asOf: Date, calendar: Calendar = .current) {
    self.asOf = asOf; self.calendar = calendar
  }

  public static func line(_ d: Date, calendar: Calendar = .current) -> String {
    let f = DateFormatter(); f.calendar = calendar; f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "EEE h:mm a"
    return "As of \(f.string(from: d)) · offline"
  }

  public var body: some View {
    Text(Self.line(asOf, calendar: calendar))
      .csType(.agate, caps: true)
      .foregroundStyle(cs.mut)
      .accessibilityLabel(Self.line(asOf, calendar: calendar))
  }
}
