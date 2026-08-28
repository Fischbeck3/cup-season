// Cup Season — the two look dials (D103a, IOS-025).
//
// The PERSON's dial lives under Appearance in Settings: follow the calendar
// (default) · Fescue only · one look all year. The PRO's dial lives on the
// League pane: follow the calendar (clear) · one of the nine calendar looks.
// Same rows, same swatch; the two phase looks are listed but never picked —
// the season turns them on. Every colour is a token or a catalogue entry.

import SwiftUI
import CSDesign
import CupSeasonKit

// MARK: - The person's dial (Settings → Appearance → Palette)

struct LookPaletteDial: View {
  @Environment(LookStore.self) private var looks
  @Environment(\.cs) private var cs

  var body: some View {
    let today = looks.calendarLook()
    VStack(alignment: .leading, spacing: 0) {
      LookPickRow(title: "Follow the calendar", sub: LookCopy.calendarLine(today), swatch: today,
                  selected: looks.personal == .calendar) { pick(.calendar) }
      LookPickRow(title: "Fescue only", sub: "Homebase, all year", swatch: nil,
                  selected: looks.personal == .none) { pick(.none) }
      ForEach(CSLooks.calendar) { s in
        LookPickRow(title: s.name, sub: LookRowCopy.sub(s), swatch: s,
                    selected: looks.personal == .fixed(s.key)) { pick(.fixed(s.key)) }
      }
      Text("Turned on by the season").font(CSFont.footnote).foregroundStyle(cs.dimText).padding(.top, 12).padding(.bottom, 2)
      ForEach(CSLooks.phases) { s in
        LookPickRow(title: s.name, sub: "\(s.motif) \(s.eyebrow)", swatch: s, selected: false, enabled: false) {}
      }
    }
  }

  private func pick(_ p: PersonalLook) {
    guard looks.personal != p else { return }
    CSHaptic.selection()
    withAnimation(CSMotion.roll) { looks.personal = p }
  }
}

// MARK: - The Pro's dial (League pane → Dress the room)

struct LookRoomSection: View {
  @Environment(LookStore.self) private var looks
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  let leagueId: UUID
  let isPro: Bool
  @State private var open = CSDevHatch.dress
  @State private var busy = false

  private var current: CSLookSpec? { looks.leagueLooks[leagueId].flatMap(CSLooks.spec) }
  /// `-cs_dev_dress` (DEBUG) also renders the Pro's dial for a member, to be LOOKED at —
  /// a tap still meets `is_commissioner()` at the database and comes back with the server's words.
  private var showsDial: Bool { isPro || CSDevHatch.dress }

  var body: some View {
    if showsDial {
      DisclosureGroup(isExpanded: $open) {
        VStack(alignment: .leading, spacing: 0) {
          Text("Every member's room wears it. The calendar looks still take their turn when nothing is set.")
            .font(CSFont.footnote).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true)
            .padding(.top, 6).padding(.bottom, 4)
          let today = looks.calendarLook()
          LookPickRow(title: "Follow the calendar", sub: LookCopy.calendarLine(today), swatch: today,
                      selected: current == nil, enabled: !busy) { set(nil) }
          ForEach(CSLooks.calendar) { s in
            LookPickRow(title: s.name, sub: LookRowCopy.sub(s), swatch: s,
                        selected: current?.key == s.key, enabled: !busy) { set(s.key) }
          }
        }
      } label: {
        HStack(spacing: 8) {
          Text("Dress the room").csEyebrow()
          Spacer()
          LookSwatch(spec: current, size: 16)
          Text(current?.name ?? "Calendar").font(CSFont.monoSmall).foregroundStyle(cs.mut)
        }
        .frame(minHeight: 44)
      }
      .tint(cs.mut)
      .padding(.top, 4)
      .accessibilityLabel("Dress the room, \(current?.name ?? "following the calendar")")
    } else {
      HStack(spacing: 10) {
        LookSwatch(spec: current, size: 16)
        Text(LookCopy.roomLine(current)).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
      }
      .frame(minHeight: 44)
      .accessibilityElement(children: .combine)
    }
  }

  /// Optimistic in the store; the toast speaks in voice on success and carries the server's words on refusal.
  private func set(_ key: String?) {
    guard !busy, current?.key != key else { return }
    CSHaptic.selection()
    busy = true
    Task {
      defer { busy = false }
      do {
        try await looks.setLeagueLook(leagueId: leagueId, key: key)
        toast.show(LookCopy.dressed(key.flatMap(CSLooks.spec)))
      } catch {
        toast.show(roomError(error, "Could not dress the room."))
      }
    }
  }
}

// MARK: - Rows

enum LookRowCopy {
  /// "🌬 Links · Jul 10 – 24" — the motif, the eyebrow word, the window.
  static func sub(_ s: CSLookSpec) -> String {
    [s.motif + " " + s.eyebrow, LookCopy.window(s)].compactMap { $0 }.joined(separator: " · ")
  }
}

/// One row of a dial: swatch · name + sub-line · the check. 44pt, a hairline under.
struct LookPickRow: View {
  @Environment(\.cs) private var cs
  let title: String
  let sub: String
  let swatch: CSLookSpec?
  let selected: Bool
  var enabled = true
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        LookSwatch(spec: swatch, size: 22)
        VStack(alignment: .leading, spacing: 2) {
          Text(title).font(CSFont.subhead.weight(selected ? .semibold : .regular)).foregroundStyle(enabled ? cs.ink : cs.mut)
          Text(sub).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 8)
        if selected {
          Image(systemName: "checkmark").font(.system(size: 14, weight: .semibold)).foregroundStyle(cs.brand)
        }
      }
      .padding(.vertical, 10)
      .frame(minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
    .overlay(alignment: .bottom) { CSHairline() }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Palette, \(title)\(selected ? ", selected" : "")")
    .accessibilityHint(enabled ? sub : "Turned on by the season")
    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : [.isButton])
  }
}

/// A 22pt swatch: the look's accent on the left, accent2 on the right.
/// nil = Fescue — the ground itself with a hairline.
struct LookSwatch: View {
  @Environment(\.cs) private var cs
  @Environment(\.colorScheme) private var scheme
  let spec: CSLookSpec?
  var size: CGFloat = 22

  var body: some View {
    let theme: CSTheme = scheme == .light ? .light : .dark
    ZStack {
      if let spec {
        Circle().fill(spec.accent(theme))
        Circle().trim(from: 0.25, to: 0.75).fill(spec.accent2(theme)).rotationEffect(.degrees(-90))
      } else {
        Circle().fill(cs.bg0)
      }
    }
    .overlay(Circle().stroke(cs.line2, lineWidth: 1))
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

#Preview("The person's dial") {
  ScrollView {
    VStack(alignment: .leading, spacing: 10) {
      Text("Palette").csEyebrow()
      LookPaletteDial()
    }
    .padding(20)
  }
  .background(CSTokens.dark.bg0)
  .environment(LookStore(defaults: UserDefaults(suiteName: "look-preview")!))
  .csTheme()
}

#Preview("Dress the room · Pro") {
  ScrollView {
    LookRoomSection(leagueId: UUID(), isPro: true).padding(20)
  }
  .background(CSTokens.dark.bg0)
  .environment(LookStore(defaults: UserDefaults(suiteName: "look-preview")!))
  .csTheme()
}
