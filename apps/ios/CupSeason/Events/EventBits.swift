// Cup Season — the small grammar both rooms and both setup sheets share.
//
// **THREE OF THESE ARE DELETED IN WAVE 6, AND WHY IS THE WAVE'S ARGUMENT:**
//
//   `EventHeaderRow` — the event's NAME set as an eyebrow (12pt tracked caps)
//     with the status chip beside it in **gold**. The one screen in the product
//     where the score of a live competition was smaller than the section label
//     above it, and gold on a status is not "earned" (`LINT-11`). The head is
//     `EventTitleCard` now — a full-bleed ceremony plate at `display` 34.
//   `EventFineCard` — a bordered `bg2` card holding a paragraph. §3 has three
//     containers and none of them holds prose; fine print is `body` 15 at `mut`
//     on the page's own ground.
//   `EventSeg` — the product's FIFTH segmented control. `CSSegment` is the one.
//
// `EventTeamSwatch` survives as the 3pt squad RULE (§2 B, §2 D) — a rule under
// a name, never a 12pt rounded square floating beside one, because a rounded
// rectangle in a squad colour is the identity mark `CSFace` owns (CS-11).

import SwiftUI
import CSDesign
import CupSeasonKit

/// The 3pt squad rule. It is drawn UNDER something and never beside it: a
/// swatch says "a colour exists"; a rule under a name says "this is that
/// side's". Colour is never the only channel — the name is always with it.
struct EventTeamSwatch: View {
  @Environment(\.cs) private var cs
  let colorIndex: Int
  var width: CGFloat = 26
  var body: some View {
    Rectangle().fill(cs.squadMark(colorIndex)).frame(width: width, height: 3)
      .accessibilityHidden(true)
  }
}

/// The field label above an input — `agate` at `mut`, on the ground.
struct EventFieldLabel: View {
  @Environment(\.cs) private var cs
  let text: String
  var hint: String? = nil
  var body: some View {
    HStack(spacing: CSTokens.Space.s2) {
      Text(text).csType(.agate, caps: true).foregroundStyle(cs.mut)
      if let hint { Text(hint).csType(.agateS, caps: false).foregroundStyle(cs.mut) }
    }
    .padding(.top, CSTokens.Space.s2)
    .accessibilityAddTraits(.isHeader)
  }
}

/// The fine print, on the page's own ground. **`body` 15 at `mut`, no tile, no
/// border** — a paragraph is not a container's job.
struct EventFinePrint: View {
  @Environment(\.cs) private var cs
  let text: String
  var body: some View {
    Text(text).csType(.bodyS).foregroundStyle(cs.mut)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// A staged invitee — the setup sheets stage people BEFORE the event exists,
/// then fire the invites once `create_event` returns an id.
struct EventStagedRow: View {
  @Environment(\.cs) private var cs
  let person: Person
  let remove: () -> Void
  var body: some View {
    VStack(spacing: 0) {
      CSRule()
      A11yStack(spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s2) {
        HStack(spacing: CSTokens.Space.s3) {
          CSFace(.init(id: person.id, marker: person.marker, initials: Initials.of(person.name)), size: .slat)
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            Text(person.name).csType(.social).foregroundStyle(cs.ink).lineLimit(1).truncationMode(.tail)
            Text("@\(person.handle ?? "?")").csType(.columnS).foregroundStyle(cs.mut).lineLimit(1)
          }
        }
        Spacer(minLength: CSTokens.Space.s2)
        Button("Remove", action: remove).buttonStyle(.csTertiary(.content))
          .accessibilityLabel("Remove \(person.name)")
      }
      .frame(minHeight: 50)
    }
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
    .overlay(alignment: .bottom) { CSRule() }
  }
}
