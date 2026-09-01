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
  @Environment(\.dynamicTypeSize) private var typeSize
  /// D199 — the card's wash takes the LOOK's accent. Read as the spec and
  /// resolved against the DARK palette by hand rather than through
  /// `\.csLookAccent`: this view forces `colorScheme` to dark at the end of its
  /// body, so the ambient value is still `.light` while the body is building
  /// and the environment accessor would hand back the light-theme accent for a
  /// card that is always dark. With no look in scope the accent is `cs.brand`,
  /// which is where this card already was.
  @Environment(\.csLook) private var look
  private var accent: Color { CSLookAccent(look: look, cs: CSTokens.dark, theme: .dark).accent }

  /// A marker is a small drawing and wants to stay small; a photograph is a
  /// FACE and wants room. One size for both was the actual defect.
  private var faceSize: CGFloat { photoURL != nil ? 104 : 64 }
  /// The name rides over the photo's trailing edge — but only with a photo to
  /// ride over, and never at accessibility sizes, where the text grows into
  /// the overlap and legibility beats composition.
  private var riding: Bool { photoURL != nil && !typeSize.isA11y }

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
      HStack(alignment: riding ? .bottom : .center, spacing: riding ? -(faceSize * 0.20) : 12) {
        CSFace(photoURL: photoURL, marker: marker, size: faceSize, badge: !riding).environment(\.cs, p)
        VStack(alignment: .leading, spacing: 2) {
          if riding {
            Text(name).font(CSFont.title).foregroundStyle(p.ink).lineLimit(2)
            FoundingTag(badge: badge).environment(\.cs, p).padding(.top, 1)
          } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text(name).font(CSFont.title).foregroundStyle(p.ink).lineLimit(2)
              FoundingTag(badge: badge).environment(\.cs, p)
            }
          }
          if !meta.isEmpty {
            Text(meta).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(p.mut)
          }
          anchor()
        }
        .padding(.leading, riding ? 12 : 0)
        .padding(.bottom, riding ? 6 : 0)
        /* the scrim, and only as wide as the overlap: the name has to stay
           legible where it crosses a photograph, and the card's own ground has
           to stay visible everywhere else — a full-width scrim would paint a
           rectangle over the wash and the emblem. */
        .background(alignment: .leading) {
          if riding {
            LinearGradient(stops: [
              .init(color: p.bg1.opacity(0.95), location: 0.0),
              .init(color: p.bg1.opacity(0.86), location: 0.62),
              .init(color: .clear,              location: 1.0)
            ], startPoint: .leading, endPoint: .trailing)
              .frame(width: faceSize * 1.05)
              .blur(radius: 10)
              .padding(.vertical, -10)
              .allowsHitTesting(false)
          }
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

      // the index beside the engraved trophies; the trophies drop under it at the accessibility sizes
      A11yStack(rowAlignment: .bottom, spacing: 12, columnSpacing: 8) {
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
          VStack(alignment: typeSize.isA11y ? .leading : .trailing, spacing: 3) {
            ForEach(trophyLines, id: \.self) { Text($0).font(CSFont.label).foregroundStyle(p.gold).lineLimit(typeSize.isA11y ? nil : 1) }
          }
          .accessibilityElement(children: .combine)
          .accessibilityLabel("Trophies: " + trophyLines.joined(separator: ", "))
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
        RadialGradient(colors: [accent.opacity(0.22), .clear], center: UnitPoint(x: 0.82, y: 0), startRadius: 0, endRadius: 300)
        /* the emblem as a SHADOW rather than a decal. At 320 it crops to a
           curve instead of a picture, which is what makes it read as depth;
           the stroke scales with the glyph (lineWidth × size/24 → ~21pt here),
           and the blur takes the last of the drawn edge off it. */
        CSMarkerView(key: marker, size: 250, lineWidth: 1.4)
          .foregroundStyle(p.ink).opacity(0.11)
          .blur(radius: 2.5)
          .offset(x: 50, y: 57)
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
