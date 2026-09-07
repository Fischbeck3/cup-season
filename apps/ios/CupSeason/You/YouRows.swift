// Cup Season — the settings-list row.
//
// **MIGRATED (Wave 8, D277).** `YouStatRow` left in Wave 3; the door row
// survives because it is the right shape for a list of doors — but it took a
// `Text` for its lead cell, which is how four surfaces came to draw an EMOJI
// there (`LINT-12`) and one to draw a typed `→` (`LINT-13`). The lead is a
// view now, so a door draws a glyph from the one family and the friends board
// draws a date; the trailing arrow is the drawn chevron.

import SwiftUI
import CSDesign
import CupSeasonKit

/// A `.check` row without the card: a glyph cell, a bold title, a mono sub,
/// and a `→` when it is a door. The whole row is the 44pt target.
struct YouDoorRow<Lead: View, Trailing: View>: View {
  @Environment(\.cs) private var cs
  let glyph: Lead
  let title: String
  let sub: String?
  var subColor: Color? = nil
  let action: (() -> Void)?
  @ViewBuilder let trailing: () -> Trailing

  init(glyph: Lead, title: String, sub: String? = nil, subColor: Color? = nil, action: (() -> Void)? = nil,
       @ViewBuilder trailing: @escaping () -> Trailing) {
    self.glyph = glyph; self.title = title; self.sub = sub; self.subColor = subColor; self.action = action; self.trailing = trailing
  }

  var body: some View {
    if let action {
      Button(action: action) { row }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    } else {
      row.accessibilityElement(children: .combine)
    }
  }

  private var row: some View {
    HStack(spacing: CSTokens.Space.s3) {
      glyph
        .csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .frame(minWidth: 30, minHeight: 30)
        .padding(.horizontal, 2)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(title).csType(.name).foregroundStyle(cs.ink)
        if let sub, !sub.isEmpty { Text(sub).csType(.agate, caps: true).foregroundStyle(subColor ?? cs.mut) }
      }
      // a Button label pushes a CENTRED alignment down the environment, so a
      // wrapped sub would centre its second line the moment `action` is set
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      trailing().foregroundStyle(cs.mut).accessibilityHidden(true)
    }
    .frame(minHeight: 44)
    .contentShape(Rectangle())
  }
}

extension YouDoorRow where Trailing == AnyView {
  /// The door's chevron, DRAWN; a row with no action shows none. It was a
  /// typed `→` in a `Text` (`LINT-13`), which no renderer could ever draw a
  /// second way.
  init(glyph: Lead, title: String, sub: String? = nil, subColor: Color? = nil, action: (() -> Void)? = nil) {
    self.init(glyph: glyph, title: title, sub: sub, subColor: subColor, action: action) {
      action == nil ? AnyView(EmptyView()) : AnyView(CSGlyph(.chevron, size: .inline))
    }
  }
}
