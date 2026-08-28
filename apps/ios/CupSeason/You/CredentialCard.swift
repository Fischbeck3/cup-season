// Cup Season — the credential (`.cred`, index.html 585–613; painted by
// `refreshWhoChip` 13086–13136 for you, `openTourCard` 13330–13355 for anyone).
//
// One charcoal OBJECT — face, index, trophies engraved on it, the golfer's
// marker as its watermark, the form row, the vs-you chip. "Fixed hexes: same
// face for every viewer, light theme included" — so it wears the DARK palette
// in every theme; every value is a token of that palette.

import SwiftUI
import CSDesign
import CupSeasonKit

struct CredentialCard<Anchor: View, Extra: View>: View {
  private let p = CSTokens.dark

  let photoURL: URL?
  let marker: String?
  let name: String
  /// D102 — `✦ Founder` / `✦ Founding member`, beside the name.
  var badge: FoundingBadge? = nil
  /// "@handle · city · home course" / "@handle · city · est. Aug 2026"
  let meta: String
  let indexCurrent: Double?
  /// rounds on the card — drives "n of 3" until the index is established
  let rounds: Int
  let trophyLines: [String]
  let form: FormRow?
  @ViewBuilder let anchor: () -> Anchor
  @ViewBuilder let extra: () -> Extra
  var settings: (() -> Void)? = nil

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: 12) {
        CSFace(photoURL: photoURL, marker: marker, size: 56).environment(\.cs, p)
        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(name).font(CSFont.title).foregroundStyle(p.ink).lineLimit(2)
            FoundingTag(badge: badge).environment(\.cs, p)
          }
          if !meta.isEmpty {
            Text(meta).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(p.mut)
          }
          anchor()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if let settings {
          Button(action: settings) {
            Text("⚙").font(CSFont.mono).foregroundStyle(p.ink)
              .frame(width: 44, height: 44)
              .background(p.ink.opacity(0.1), in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
              .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(p.ink.opacity(0.3), lineWidth: 1))
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Card & settings")
        }
      }

      HStack(alignment: .bottom, spacing: 12) {
        VStack(alignment: .leading, spacing: 3) {
          if let idx = indexCurrent {
            Text(CSCopy.index(idx)).font(CSFont.hero).foregroundStyle(p.gold).csTabular()   // EARNED: the number, once established
          } else {
            Text(Career.establishing(rounds: rounds)).font(CSFont.heroSmall).foregroundStyle(p.ink).csTabular()
          }
          Text("Handicap index").font(CSFont.label).tracking(1.8).textCase(.uppercase).foregroundStyle(p.ink.opacity(0.65))
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(indexCurrent == nil ? "Building your number — your index appears at 3 posted rounds" : "")
        Spacer(minLength: 8)
        if !trophyLines.isEmpty {
          VStack(alignment: .trailing, spacing: 3) {
            ForEach(trophyLines, id: \.self) { Text($0).font(CSFont.label).foregroundStyle(p.gold).lineLimit(1) }
          }
        }
      }
      .padding(.top, 16)

      if indexCurrent == nil {
        Text("Building your number — your index appears at 3 posted rounds")
          .font(CSFont.footnote).foregroundStyle(p.mut).padding(.top, 8)
      }
      if let form { FormRowView(form: form, palette: p) }
      extra()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      ZStack(alignment: .bottomTrailing) {
        p.bg1
        RadialGradient(colors: [p.hot.opacity(0.16), .clear], center: UnitPoint(x: 0.82, y: 0), startRadius: 0, endRadius: 260)
        CSMarkerView(key: marker, size: 150, lineWidth: 1.2)
          .foregroundStyle(p.ink).opacity(0.1)
          .offset(x: 30, y: 34)
          .accessibilityHidden(true)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(p.ink.opacity(0.07), lineWidth: 1))
    .shadow(color: CSTokens.shadowLift.color, radius: 10, y: 6)
    .environment(\.colorScheme, .dark)
  }
}

/// The `.cvs` chip: "VS YOU · 3–2 · YOU LEAD".
struct VsChip: View {
  private let p = CSTokens.dark
  let text: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(text).font(CSFont.monoMediumBody).tracking(0.6).foregroundStyle(p.ink)
        .padding(.horizontal, 10).frame(minHeight: 40)
        .background(p.ink.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(p.ink.opacity(0.28), lineWidth: 1))
    }
    .buttonStyle(.plain)
    .padding(.top, 14)
  }
}

#Preview("Established, three trophies, on a streak") {
  CredentialCard(photoURL: nil, marker: "saguaro", name: "Jerecho Fischbeck", meta: "@jerecho · Tempe, AZ · Papago GC",
                 indexCurrent: 12.4, rounds: 42, trophyLines: ["🔥 Broke 80 · '26", "📈 4-week streak · '26", "⛳ First round · '26"],
                 form: FormRow.from(beats: [true, true, true, false, true]),
                 anchor: { Text("GHIN 1234567 · Member since Jul 2026").font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut) },
                 extra: { EmptyView() }, settings: {})
    .padding(20).background(CSTokens.light.bg0)
}

#Preview("Building — 2 of 3") {
  CredentialCard(photoURL: nil, marker: "thistle", name: "New Golfer", meta: "@newg · Mesa, AZ", indexCurrent: nil, rounds: 2,
                 trophyLines: [], form: nil, anchor: { EmptyView() }, extra: { EmptyView() })
    .padding(20).background(CSTokens.dark.bg0)
}
