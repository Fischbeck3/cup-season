// Cup Season — the settings-list row.
//
// **RETIRED (Wave 3). Removed in Wave 8.** `YouStatRow` is deleted here with
// the You tab's stat sections — a golf number set label-left / value-right in
// a settings list is YRS-01 and YRS-02, and the figures now live on rules.
// `YouDoorRow` survives ONLY because three surfaces this wave does not own
// still draw it: `Settings/CardAndSettingsScreen`, `Golfers/FriendsBoard` and
// `You/GuideSheets`. Wave 8 takes those three and this file goes with them.
// Nothing new may be written against it — `LINT-30` counts the sites.

import SwiftUI
import CSDesign
import CupSeasonKit

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
      // a Button label pushes a CENTRED alignment down the environment, so a
      // wrapped sub would centre its second line the moment `action` is set
      .multilineTextAlignment(.leading)
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
