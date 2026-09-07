// Cup Season — where a row goes when tapped, and the small shared parts every
// surface outside the seven Phase-3 waves is built from.
//
// WAVE 8 · PROPAGATE (D277 / IOS-052). These four — the mini, the tag, the
// check row and the list row — are the vocabulary the door, the schedule, the
// composer, the wizard, the board and every picker draw themselves in, so
// migrating them is what stops the product being half in the new system and
// half in the old. Each is now the system's own shape rather than a shape of
// its own:
//
//   CSMini      → §7.1's tertiary link (or §7.2's chip when it is a CHOICE)
//   CSTag       → §7.2's chip shape — a 3pt rectangle, because there is no pill
//   CSCheckRow  → a row on the page's ground, parted by a rule — no border
//   RoomLineRow → the same, with a 3pt rail when it carries a spine
//
// AND THE FACE IS KEYED TO THE GOLFER (`LINT-31`). Both rows took a marker
// STRING and seated the golfer on a pigment derived from the glyph, so two
// golfers who both chose the Lone Tree shared a coin — the one thing pigments
// exist to prevent. They take a `CSFace.Model` now; `Faces.of` is the one place
// that decides, and a golfer with no profile id (a guest on a tee sheet) is
// seeded from their NAME, which keys to the person and is not a debt.

import Foundation
import SwiftUI
import CSDesign
import CupSeasonKit

struct CSLinks {
  var openTourCard: ((UUID) -> Void)? = nil
  var openRound: ((UUID) -> Void)? = nil
  /// D222 · one door, resolving a season or a moment — `openLeague` was
  /// named for a table and a season is not a table (route map §13.2).
  var openCompetition: ((UUID) -> Void)? = nil
}

/// **The one place a row decides how to draw a person.** A profile id keys the
/// pigment to the GOLFER (§6.2a); a golfer the payload identifies only by name
/// — a guest, a comment's author — is seeded from the name, which is still the
/// person and still comes out different for two golfers who chose one glyph.
enum Faces {
  static func of(_ id: UUID?, marker: String?, name: String?, isViewer: Bool = false) -> CSFace.Model {
    if let id {
      return CSFace.Model(id: id, marker: marker, initials: Initials.of(name), isViewer: isViewer)
    }
    return .seeded(key: name ?? marker ?? "golfer", marker: marker,
                   initials: Initials.of(name), isViewer: isViewer)
  }
}

// MARK: - The bits the web's `openSheet` / `.mini` / `.ptag` / `.check` were

/// A sheet's head: the title in `displayS`, the eyebrow in agate beneath it.
struct CSSheetHeader: View {
  @Environment(\.cs) private var cs
  let title: String
  let sub: String?
  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      Text(title).csType(.displayS).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let sub, !sub.isEmpty {
        Text(sub).csType(.agate, caps: true).foregroundStyle(cs.mut)
      }
    }
    .multilineTextAlignment(.leading)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// **A small inline action — §7.1's tertiary, and nothing of its own.** It was
/// a bordered mono capsule at 36pt; there is no pill in the system and a
/// bordered small button is a container with no job. `selected:` makes it a
/// CHOICE instead, and a choice is a chip that inverts to the panel.
struct CSMini: View {
  @Environment(\.cs) private var cs
  let label: String
  /// One family (D277): the drawn glyph, never an SF Symbol beside it.
  var glyph: CSGlyph.Name? = nil
  var busy = false
  /// Y-33 · a mini standing in a set of choices says which one is chosen; the
  /// tone alone is only visible. nil = it is an action, not a choice.
  var selected: Bool? = nil
  /// The armed half of a two-tap destructive — `neg`, and the copy is "Sure?".
  var destructive = false
  let action: () -> Void

  init(_ label: String, glyph: CSGlyph.Name? = nil, busy: Bool = false,
       selected: Bool? = nil, destructive: Bool = false, action: @escaping () -> Void) {
    self.label = label; self.glyph = glyph; self.busy = busy
    self.selected = selected; self.destructive = destructive; self.action = action
  }

  var body: some View {
    Button(action: action) { inner }
      .buttonStyle(.plain)
      .disabled(busy)
      .accessibilityAddTraits(selected == true ? [.isSelected] : [])
  }

  @ViewBuilder private var inner: some View {
    if let selected {
      CSChip(label, selected: selected)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    } else {
      HStack(spacing: CSTokens.Space.s2) {
        if let glyph { CSGlyph(glyph, size: .inline) }
        if !label.isEmpty {
          VStack(alignment: .leading, spacing: 3) {
            Text(label).csType(.nameS).lineLimit(2)
            Rectangle().fill(destructive ? cs.neg : cs.mut).frame(height: 2)
          }
          .fixedSize(horizontal: true, vertical: false)
        }
      }
      .foregroundStyle(destructive ? cs.neg : cs.ink)
      .opacity(busy ? CSTokens.Alpha.a56 : 1)
      .frame(minWidth: 44, minHeight: 44)
      .contentShape(Rectangle())
    }
  }
}

/// `.ptag` — the tag a row wears. §7.2's chip shape: a 3pt rectangle, agate,
/// never a bordered capsule.
struct CSTag: View {
  @Environment(\.cs) private var cs
  let text: String
  var tone: Color? = nil
  var body: some View {
    Text(text).csType(.agateS, caps: true)
      .foregroundStyle(tone ?? cs.mut)
      .padding(.horizontal, CSTokens.Space.s3)
      .frame(height: 24)
      .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
  }
}

/// A row inside a sheet or a picker: a face, a name, a small line, a trailing
/// slot — **on the sheet's own ground, parted by a rule.** It was a bordered
/// tile, which is a container with no job (non-negotiable 1).
struct CSCheckRow<Trailing: View>: View {
  @Environment(\.cs) private var cs
  let face: CSFace.Model
  let title: Text
  let sub: Text?
  var spine: Color? = nil
  @ViewBuilder let trailing: Trailing

  var body: some View {
    HStack(alignment: .center, spacing: CSTokens.Space.s3) {
      // the title names the person; the marker inside the face would name itself too
      CSFace(face, size: .list).accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 3) {
        title.csType(.name).foregroundStyle(cs.ink)
        if let sub { sub.csType(.agate).foregroundStyle(cs.mut) }
      }
      // a leading stack says leading OUT LOUD: these rows sit inside sheet and
      // picker buttons, and a button label hands its children a centred text
      // alignment — a name or a sub that wraps would set line 2 centred under a
      // leading line 1 (the invite row on Buddies did exactly that).
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      trailing
    }
    .padding(.vertical, CSTokens.Space.s3)
    .frame(minHeight: 56)
    .overlay(alignment: .leading) {
      if let spine { Rectangle().fill(spine).frame(width: 3).padding(.vertical, 10).padding(.leading, -8) }
    }
    .overlay(alignment: .bottom) { CSRule() }
  }
}

/// The list row (IOS-019 rule 2): a face, a bold line, a small line, a
/// trailing slot — on ground, parted from the next by a rule. An optional
/// spine on the leading edge (a request wears ember).
///
/// Y-23 · with `onTap`, the face and the two lines are ONE button (the person),
/// read as one element with `hint`; the trailing slot keeps its own controls.
struct RoomLineRow<Trailing: View>: View {
  @Environment(\.cs) private var cs
  let face: CSFace.Model
  let title: Text
  let sub: Text?
  var spine: Color? = nil
  var onTap: (() -> Void)? = nil
  var hint: String? = nil
  /// Y-33 · what the combined element SAYS, when the drawn title carries a
  /// glyph VoiceOver would spell out (the founder's ✦). nil = the combined
  /// children speak for themselves.
  var label: String? = nil
  @ViewBuilder let trailing: Trailing

  var body: some View {
    HStack(alignment: .center, spacing: CSTokens.Space.s3) {
      if let onTap {
        spoken(Button(action: onTap) { lead }
          .buttonStyle(.plain)
          .accessibilityElement(children: .combine)
          .accessibilityHint(hint ?? ""))
      } else {
        spoken(lead.accessibilityElement(children: .combine))
      }
      trailing
    }
    .padding(.vertical, CSTokens.Space.s3)
    .frame(minHeight: 56)
    .overlay(alignment: .leading) {
      if let spine { Rectangle().fill(spine).frame(width: 3).padding(.vertical, 12).padding(.leading, -8) }
    }
    .overlay(alignment: .bottom) { CSRule() }
  }

  /// `.accessibilityLabel("")` would SILENCE an element rather than leave it
  /// as combined, so the modifier only goes on when there is a label to say.
  @ViewBuilder private func spoken(_ v: some View) -> some View {
    if let label { v.accessibilityLabel(label) } else { v }
  }

  /// The part of the row that IS the person: face, name, small line.
  private var lead: some View {
    HStack(alignment: .center, spacing: CSTokens.Space.s3) {
      // the title names the person; the marker inside the face would name itself too
      CSFace(face, size: .list).accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 3) {
        title.csType(.name).foregroundStyle(cs.ink)
        if let sub {
          sub.csType(.agate).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
        }
      }
      // Y-23 made the lead a Button, and a button label's children inherit a
      // CENTRED alignment: "@handle · City" wrapping would centre its second
      // line under the name. The stack is leading, and now says so.
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .contentShape(Rectangle())
  }
}

/// `.fine` — helper copy in `mut`, at the system's small body size.
struct CSFine: View {
  @Environment(\.cs) private var cs
  let text: String
  var tone: Color? = nil
  init(_ text: String, tone: Color? = nil) { self.text = text; self.tone = tone }
  var body: some View {
    // the frame is leading, so the wrapped lines are too — helper copy lands
    // inside button and menu labels, which otherwise centre what they wrap.
    Text(text).csType(.bodyS).foregroundStyle(tone ?? cs.mut)
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// A two-tap destructive arm ("Sure?") — never an alert (IOS-003 §4).
struct CSArmedButton: View {
  let label: String
  let armedLabel: String
  var busy = false
  /// The arm state, for a caller that shows the web's `confirm()` sentence while armed.
  var onArm: ((Bool) -> Void)? = nil
  let action: () -> Void
  @State private var armed = false

  var body: some View {
    CSMini(armed ? armedLabel : label, busy: busy, destructive: armed) {
      if armed { action() } else { armed = true; CSHaptic.warning() }
    }
    .task(id: armed) {
      onArm?(armed)
      guard armed else { return }
      try? await Task.sleep(for: .seconds(4))
      armed = false
    }
  }
}
