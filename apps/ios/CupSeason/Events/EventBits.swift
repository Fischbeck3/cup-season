// Cup Season — the small grammar both rooms and both setup sheets share:
// the eyebrow-with-chip header, the team swatch, the "How it plays" card,
// the staged-invitee row, the segmented pills, and C10's rise.

import SwiftUI
import CSDesign
import CupSeasonKit

/// `<div class="eyebrow">NAME <span class="fine" style="color:gold">CHIP</span></div>`
struct EventHeaderRow: View {
  @Environment(\.cs) private var cs
  let name: String
  let chip: String
  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
      Text(name).csEyebrow(cs.ink).lineLimit(2)
      Spacer(minLength: 8)
      Text(chip).font(CSFont.label).tracking(0.8).foregroundStyle(cs.gold).multilineTextAlignment(.trailing)
    }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isHeader)
  }
}

/// `.sw` — the 12pt team swatch in the squad colour (`SQHEX[c]`).
struct EventTeamSwatch: View {
  @Environment(\.cs) private var cs
  let colorIndex: Int
  var body: some View {
    RoundedRectangle(cornerRadius: 3).fill(cs.squad(colorIndex)).frame(width: 12, height: 12)
      .accessibilityHidden(true)
  }
}

/// The `bg2` card with the rule paragraph (setup sheets, the fine print).
struct EventFineCard: View {
  @Environment(\.cs) private var cs
  let markdown: String
  var body: some View {
    Text((try? AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(markdown))
      .font(CSFont.footnote).foregroundStyle(cs.dimText).lineSpacing(3)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 13).padding(.vertical, 11)
      .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.line, lineWidth: 1))
  }
}

/// `.seg` — the setup sheets' segmented pills (sessions, cadence, window, split).
struct EventSeg<T: Hashable>: View {
  @Environment(\.cs) private var cs
  let options: [(T, String)]
  @Binding var selection: T
  var body: some View {
    // one row of pills; a column at the accessibility sizes
    A11yStack(spacing: 6) {
      ForEach(options, id: \.0) { k, l in
        Button { selection = k; CSHaptic.selection() } label: {
          Text(l).font(CSFont.monoSmall).foregroundStyle(selection == k ? cs.bg0 : cs.ink)
            .padding(.horizontal, 10).frame(minHeight: 40).frame(maxWidth: .infinity)
            .background(selection == k ? cs.ink : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: selection == k ? 0 : 1))
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == k ? .isSelected : [])
      }
    }
  }
}

/// `label.f` — the field label above an input.
struct EventFieldLabel: View {
  @Environment(\.cs) private var cs
  let text: String
  var hint: String? = nil
  var body: some View {
    HStack(spacing: 6) {
      Text(text).csEyebrow()
      if let hint { Text(hint).font(CSFont.label).foregroundStyle(cs.dimText) }
    }
    .padding(.top, 6)
  }
}

/// A staged invitee — `renderRsPicked` / `renderMjPicked` (15963, 16090):
/// marker · name · @handle · Remove.
struct EventStagedRow: View {
  @Environment(\.cs) private var cs
  let person: Person
  let remove: () -> Void
  var body: some View {
    A11yStack(spacing: 8, columnSpacing: 4) {
      HStack(spacing: 8) {
        CSMarkerView(key: person.marker, size: 18).foregroundStyle(cs.ink).accessibilityHidden(true)
        Text(person.name).font(CSFont.subhead).foregroundStyle(cs.ink)
        Text("@\(person.handle ?? "?")").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
      }
      Spacer()
      CSMini("Remove", action: remove).accessibilityLabel("Remove \(person.name)")
    }
    .frame(minHeight: 44)
  }
}

/// A league `<select>` — "Standalone — invite anyone" or one of mine.
struct EventLeaguePicker: View {
  @Environment(\.cs) private var cs
  let memberships: [Me.Membership]
  @Binding var selection: UUID?
  var body: some View {
    Picker("League", selection: $selection) {
      Text("Standalone — invite anyone").tag(UUID?.none)
      ForEach(memberships) { m in Text(m.name).tag(UUID?.some(m.league_id)) }
    }
    .pickerStyle(.menu)
    .tint(cs.ink)
    .accessibilityLabel("League")
    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
    .padding(.horizontal, 8)
    .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
  }
}

/// C10 — the taunt lands: an incoming duel target chips onto your green —
/// arcs in, squashes at touch, settles. Banter, never gold, never >350ms.
/// Reduced motion rests immediately (the web's media block, 2239).
struct EventRiseModifier: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let rise: Bool
  @State private var landed = false
  func body(content: Content) -> some View {
    content
      .offset(x: rise && !landed ? -10 : 0, y: rise && !landed ? -18 : 0)
      .opacity(rise && !landed ? 0 : 1)
      .onAppear {
        guard rise, !reduceMotion else { landed = true; return }
        withAnimation(.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.3)) { landed = true }
      }
  }
}

extension View {
  func eventRise(_ rise: Bool) -> some View { modifier(EventRiseModifier(rise: rise)) }
}
