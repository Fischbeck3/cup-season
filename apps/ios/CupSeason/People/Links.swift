// Cup Season — where a row goes when tapped. The host wires these; a nil
// link means the slice handles it in place (the round sheet) or the row is
// simply not a door (the Tour Card, another slice).

import Foundation
import SwiftUI
import CSDesign
import CupSeasonKit

struct CSLinks {
  var openTourCard: ((UUID) -> Void)? = nil
  var openRound: ((UUID) -> Void)? = nil
  var openLeague: ((UUID) -> Void)? = nil
}

// MARK: - The bits the web's `openSheet` / `.mini` / `.ptag` / `.check` were

/// `openSheet(title, sub, …)`: a serif title over a mono eyebrow.
struct CSSheetHeader: View {
  @Environment(\.cs) private var cs
  let title: String
  let sub: String?
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).font(CSFont.title).foregroundStyle(cs.ink)
      if let sub, !sub.isEmpty { Text(sub).csEyebrow() }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// `.mini` — a small bordered capsule, mono, 36pt tall (44pt hit).
struct CSMini: View {
  @Environment(\.cs) private var cs
  let label: String
  var tone: Color? = nil
  var systemImage: String? = nil
  var busy = false
  let action: () -> Void

  init(_ label: String, tone: Color? = nil, systemImage: String? = nil, busy: Bool = false, action: @escaping () -> Void) {
    self.label = label; self.tone = tone; self.systemImage = systemImage; self.busy = busy; self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let systemImage { Image(systemName: systemImage).font(.system(size: 13, weight: .semibold)) }
        if !label.isEmpty { Text(label).font(CSFont.monoMediumBody) }
      }
      .foregroundStyle(tone ?? cs.ink)
      .padding(.horizontal, label.isEmpty ? 10 : 12)
      .frame(minWidth: 36, minHeight: 36)
      .background(cs.bg2, in: Capsule())
      .overlay(Capsule().stroke(tone ?? cs.line2, lineWidth: 1))
      .opacity(busy ? 0.5 : 1)
      .frame(minWidth: 44, minHeight: 44)   // accessibility: an icon-only mini is still a 44pt target
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(busy)
  }
}

/// `.ptag` — the tag a row wears: `ok` (pos), `pos`, or plain.
struct CSTag: View {
  @Environment(\.cs) private var cs
  let text: String
  var tone: Color? = nil
  var body: some View {
    Text(text).font(CSFont.label).tracking(0.8).textCase(.uppercase)
      .foregroundStyle(tone ?? cs.mut)
      .padding(.horizontal, 8).padding(.vertical, 5)
      .overlay(Capsule().stroke((tone ?? cs.line2).opacity(0.7), lineWidth: 1))
  }
}

/// `.check` — a marker, a bold line, a small line, and a trailing slot.
struct CSCheckRow<Trailing: View>: View {
  @Environment(\.cs) private var cs
  let marker: String?
  let title: Text
  let sub: Text?
  var spine: Color? = nil
  @ViewBuilder let trailing: Trailing

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      CSFace(marker: marker, size: 36)
      VStack(alignment: .leading, spacing: 3) {
        title.font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        if let sub { sub.font(CSFont.monoSmall).foregroundStyle(cs.mut) }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      trailing
    }
    .padding(.vertical, 8).padding(.horizontal, 12)
    .frame(minHeight: 52)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(spine ?? cs.line, lineWidth: 1))
  }
}

/// The list row (IOS-019 rule 2): a marker, a bold line, a small line, a
/// trailing slot — on ground, parted from the next by a hairline. An optional
/// spine on the leading edge (a request wears ember). The bordered
/// `CSCheckRow` stays for sheets and pickers; lists use this.
struct RoomLineRow<Trailing: View>: View {
  @Environment(\.cs) private var cs
  let marker: String?
  let title: Text
  let sub: Text?
  var spine: Color? = nil
  @ViewBuilder let trailing: Trailing

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      CSFace(marker: marker, size: 36)
      VStack(alignment: .leading, spacing: 3) {
        title.font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        if let sub { sub.font(CSFont.monoSmall).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true) }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      trailing
    }
    .padding(.vertical, 10).padding(.horizontal, 4)
    .frame(minHeight: 56)
    .overlay(alignment: .leading) {
      if let spine { RoundedRectangle(cornerRadius: 2).fill(spine).frame(width: 3.5).padding(.vertical, 12).padding(.leading, -6) }
    }
    .overlay(alignment: .bottom) { CSHairline() }
  }
}

/// `.fine` — helper copy in `mut` (the web's `dim` → `cs.dimText`).
struct CSFine: View {
  @Environment(\.cs) private var cs
  let text: String
  var tone: Color? = nil
  init(_ text: String, tone: Color? = nil) { self.text = text; self.tone = tone }
  var body: some View {
    Text(text).font(CSFont.footnote).foregroundStyle(tone ?? cs.dimText).frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// A two-tap destructive arm ("Sure?") — never an alert (IOS-003 §4).
struct CSArmedButton: View {
  @Environment(\.cs) private var cs
  let label: String
  let armedLabel: String
  var busy = false
  let action: () -> Void
  @State private var armed = false

  var body: some View {
    CSMini(armed ? armedLabel : label, tone: armed ? cs.neg : cs.mut, busy: busy) {
      if armed { action() } else { armed = true; CSHaptic.warning() }
    }
    .task(id: armed) {
      guard armed else { return }
      try? await Task.sleep(for: .seconds(4))
      armed = false
    }
  }
}
