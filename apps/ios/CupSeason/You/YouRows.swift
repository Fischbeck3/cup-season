// Cup Season — the You tab's rows (IOS-019 rule 2): a section is an eyebrow
// over a hairline, and what sits under it is rows separated by hairlines —
// never a card inside a card, never a grid of tiles.

import SwiftUI
import CSDesign
import CupSeasonKit

/// A stat as a row: label + sub on the left, the mono figure on the right.
struct YouStatRow: View {
  @Environment(\.cs) private var cs
  let label: String
  let value: String
  var sub: String? = nil
  var tone: Color? = nil
  var body: some View {
    // label + sub beside the figure; the figure drops under them at the accessibility sizes
    A11yStack(rowAlignment: .firstTextBaseline, spacing: 12, columnSpacing: 2) {
      VStack(alignment: .leading, spacing: 2) {
        Text(label).font(CSFont.subhead).foregroundStyle(cs.ink)
        if let sub { Text(sub).font(CSFont.label).tracking(0.8).textCase(.uppercase).foregroundStyle(cs.dimText) }
      }
      Spacer(minLength: 8)
      Text(value).font(CSFont.stat).csTabular().foregroundStyle(tone ?? cs.ink)
    }
    .frame(minHeight: 32)
    .accessibilityElement(children: .combine)
  }
}

/// A `.check` row without the card: a glyph cell, a bold title, a mono sub,
/// and a `→` when it is a door. The whole row is the 44pt target.
struct YouDoorRow<Trailing: View>: View {
  @Environment(\.cs) private var cs
  let glyph: Text
  let title: String
  let sub: String?
  var subColor: Color? = nil
  let action: (() -> Void)?
  @ViewBuilder let trailing: () -> Trailing

  init(glyph: Text, title: String, sub: String? = nil, subColor: Color? = nil, action: (() -> Void)? = nil,
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
    HStack(spacing: 12) {
      glyph
        .font(CSFont.monoSmall).foregroundStyle(cs.mut)
        .frame(minWidth: 30, minHeight: 30)
        .padding(.horizontal, 2)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        if let sub, !sub.isEmpty { Text(sub).font(CSFont.label).tracking(0.8).foregroundStyle(subColor ?? cs.dimText) }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      trailing().foregroundStyle(cs.dimText).accessibilityHidden(true)
    }
    .frame(minHeight: 44)
    .contentShape(Rectangle())
  }
}

extension YouDoorRow where Trailing == Text {
  /// The `→` door; a row with no action shows no arrow.
  init(glyph: Text, title: String, sub: String? = nil, subColor: Color? = nil, action: (() -> Void)? = nil) {
    self.init(glyph: glyph, title: title, sub: sub, subColor: subColor, action: action) {
      Text(action == nil ? "" : "→").font(CSFont.subhead)
    }
  }
}
