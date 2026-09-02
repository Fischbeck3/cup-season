// Cup Season — the credential (`.cred`, index.html 585–613; painted by
// `refreshWhoChip` 13086–13136 for you, `openTourCard` 13330–13355 for anyone).
//
// One charcoal OBJECT — the face panel, index, trophies engraved on it, the
// form row, the vs-you chip. "Fixed hexes: same face for every viewer, light
// theme included" — so it wears the DARK palette in every theme; every value
// is a token of that palette.
//
// D202 — the photograph owns the top of the card (`CredentialFace`); the
// marker owns it when there is none. The card below the panel is the record.

import SwiftUI
import CSDesign
import CupSeasonKit

struct CredentialCard<Anchor: View, Extra: View>: View {
  private let p = CSTokens.dark
  @Environment(\.dynamicTypeSize) private var typeSize
  /// The gear's box follows the type size for the same reason the corner
  /// marker does (`CredentialFace`): the glyph rides the box, and a grown
  /// glyph in a box fixed at 44 spills out of its own ground.
  /// CLAMPED AT BOTH ENDS — the marker leaves the panel at the accessibility
  /// sizes and this control does not, and a body-relative 44 reaches ~135pt at
  /// AX5: a gear the size of a fist over the photograph. The FLOOR matters as
  /// much: `@ScaledMetric` tracks the content size category downward too, so at
  /// `.xSmall` 44 becomes ~36 — and this frame is the whole hit area of the
  /// settings button (`.buttonStyle(.plain)` hands the label's frame to the
  /// target). `docs/ios/accessibility.md:25` puts the floor at 44, full stop.
  @ScaledMetric(relativeTo: .body) private var gearSide: CGFloat = 44
  private var gearBox: CGFloat { min(max(gearSide, 44), 72) }
  /// The glyph is sized FROM the clamped box, not from the type size, so it
  /// can never outgrow the ground it sits on: ~20pt at the 44 floor, which is
  /// the You header's gear (`YouScreen.swift`), and ~32 at the 72 ceiling.
  private var gearGlyph: CGFloat { gearBox * 0.45 }
  /// D199 — the card's wash takes the LOOK's accent. Read as the spec and
  /// resolved against the DARK palette by hand rather than through
  /// `\.csLookAccent`: this view forces `colorScheme` to dark at the end of its
  /// body, so the ambient value is still `.light` while the body is building
  /// and the environment accessor would hand back the light-theme accent for a
  /// card that is always dark. With no look in scope the accent is `cs.brand`,
  /// which is where this card already was.
  @Environment(\.csLook) private var look
  private var accent: Color { CSLookAccent(look: look, cs: CSTokens.dark, theme: .dark).accent }

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
  /// EVERY engraved line — "🔥 Broke 80 · '26" … The card shows
  /// `TrophyMeta.credentialChips` of them and adds the rest IN PLACE, the way
  /// the You hero does (`YouHero.trophyChips`). It used to be handed the
  /// already-capped list with a "+N more" string on the end, which rendered as
  /// one more plain line: a "+2 more" that looked like a door and was not one.
  let trophyLines: [String]
  let form: FormRow?
  /// Whose card this is — the form key is written in the right person
  /// (`YouCopy.formKeyCard`). No default: the Tour Card is usually somebody
  /// else's, and a caller that has not thought about which is a caller about
  /// to put "your playing number" on a stranger's record.
  let isMe: Bool
  @ViewBuilder let anchor: () -> Anchor
  @ViewBuilder let extra: () -> Extra
  var settings: (() -> Void)? = nil

  @State private var trophiesExpanded = false
  private var shownTrophies: [String] {
    trophiesExpanded ? trophyLines : Array(trophyLines.prefix(TrophyMeta.credentialChips))
  }
  private var hiddenTrophies: Int { max(0, trophyLines.count - TrophyMeta.credentialChips) }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CredentialFace(photoURL: photoURL, marker: marker, name: name, badge: badge, meta: meta,
                     p: p, accent: accent,
                     sub: { anchor() },
                     trailing: {
                       if let settings {
                         Button(action: settings) {
                           // The screenshot pass: this was `Text("⚙")`. U+2699 carries
                           // Emoji_Presentation on iOS, so it rendered as a
                           // full-colour emoji gear and `foregroundStyle` was
                           // silently dropped — a control that matched nothing
                           // else on the card. The SF Symbol takes the tint,
                           // and it is the same glyph the You header wears.
                           Image(systemName: "gearshape")
                             .font(.system(size: gearGlyph, weight: .semibold)).foregroundStyle(p.ink)
                             .frame(width: gearBox, height: gearBox)
                             .background(p.bg1.opacity(0.72), in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
                             .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(p.ink.opacity(0.3), lineWidth: 1))
                         }
                         .buttonStyle(.plain)
                         .accessibilityLabel("Card & settings")
                       }
                     })

      VStack(alignment: .leading, spacing: 0) {
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
          // A figure under its name is a VALUE under a LABEL, not one combined
          // string: VoiceOver reads "Handicap index, 12.4" rather than "12.4,
          // handicap index", and the rotor can find it by the name. The hint
          // this carried repeated, word for word, the line rendered under it
          // whenever it fired — so VoiceOver said it twice (D201, one fact,
          // one place). The line stays; the hint goes.
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("Handicap index")
          .accessibilityValue(indexCurrent == nil ? Career.establishing(rounds: rounds) : CSCopy.index(indexCurrent))
          Spacer(minLength: 8)
          if !trophyLines.isEmpty {
            VStack(alignment: typeSize.isA11y ? .leading : .trailing, spacing: 3) {
              // by index, not by the line itself: two milestones of the same
              // kind and year engrave the same words, and `id: \.self` folded
              // them into one row
              VStack(alignment: typeSize.isA11y ? .leading : .trailing, spacing: 3) {
                ForEach(Array(shownTrophies.enumerated()), id: \.offset) { _, line in
                  Text(line).font(CSFont.label).foregroundStyle(p.gold).lineLimit(typeSize.isA11y ? nil : 1)
                }
              }
              .accessibilityElement(children: .combine)
              .accessibilityLabel("Trophies: " + shownTrophies.map(TrophyMeta.spoken).joined(separator: ", "))
              // the expansion goes both ways — the same door, folded back.
              // `moreInCase` is the You hero's suffix and points at the trophy
              // case two sections down; there is no case of theirs to open
              // from here, so this one just says how many.
              if hiddenTrophies > 0 {
                Button {
                  withAnimation(.easeOut(duration: 0.18)) { trophiesExpanded.toggle() }
                } label: {
                  Text(trophiesExpanded ? TrophyMeta.showFewer : TrophyMeta.moreLine(hiddenTrophies, suffix: " more"))
                    .font(CSFont.label).foregroundStyle(p.mut)
                    .a11yHitSlop(vertical: 15, horizontal: 10)   // 45pt of target, no extra height on the card
                }
                .buttonStyle(.plain)
                .accessibilityLabel(trophiesExpanded ? "Show fewer milestones"
                                                     : "\(hiddenTrophies) more milestone\(hiddenTrophies == 1 ? "" : "s")")
                .accessibilityHint(trophiesExpanded ? "Folds the list back" : "Adds them to this list")
              }
            }
          }
        }

        if indexCurrent == nil {
          Text(YouCopy.buildingNumber)
            .font(CSFont.footnote).foregroundStyle(p.mut).padding(.top, 8)
        }
        // Y-08 · the dots' key, on the card too. The You tab's FORM row got
        // its legend and this one did not — on the surface headed "this is
        // how your buddies see you", which is the one place the reader is
        // LEAST likely to know what a lit dot means. Same producer as the You
        // caption, the card's short form, in the person this card is about.
        if let form { FormRowView(form: form, palette: p, caption: YouCopy.formKeyCard(mine: isMe)) }
        extra()
      }
      .padding(16)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      ZStack(alignment: .bottomTrailing) {
        p.bg1
        RadialGradient(colors: [accent.opacity(0.22), .clear], center: UnitPoint(x: 0.82, y: 0), startRadius: 0, endRadius: 300)
        /* the emblem as a SHADOW behind the record — but only when the panel is
           a photograph. With no photo the marker is already the crest up top,
           and drawing it twice on one card makes it decoration instead of
           identity.

           Y-11: the blur is an offscreen pass, and it rasterises the view at
           its OWN bounds — the 250pt frame — so a stroke that overshoots the
           frame was cut square before it was blurred, and the watermark read
           as a rectangle with a marker in it. Padding gives the stroke and
           the blur's fall-off room inside the raster; the compositing group
           makes that padded frame the thing the blur is applied to. The
           offset grows by the padding so the glyph sits where it did.

           And the blur SCALES with the glyph. A fixed 2.5 is enough to take
           the drawn edge off a hairline; this stroke is lineWidth × size/24 =
           ~15pt wide, so 2.5 softened nothing and the mark read as a flat
           block behind the trophy column — measured, two grounds under one
           set of badges. `markSize / 12` is a radius that belongs to the mark
           it is blurring. The radial mask then takes the edge off entirely:
           it reaches clear inside the padded raster (endRadius · 0.72 of the
           glyph covers its half-diagonal), so there is no boundary anywhere
           for the eye to find — an atmosphere behind the record, which is
           what D202 keeps the watermark for. */
        if photoURL != nil {
          CSMarkerView(key: marker, size: Watermark.size, lineWidth: 1.4)
            .foregroundStyle(p.ink)
            .padding(Watermark.pad)
            .compositingGroup()
            .blur(radius: Watermark.blur)
            .mask {
              RadialGradient(stops: [
                .init(color: .white, location: 0.0),
                .init(color: .white.opacity(0.86), location: 0.42),
                .init(color: .white.opacity(0.34), location: 0.76),
                .init(color: .clear, location: 1.0)
              ], center: .center, startRadius: 0, endRadius: Watermark.fade)
            }
            .opacity(0.13)
            .offset(x: Watermark.origin.width + Watermark.pad, y: Watermark.origin.height + Watermark.pad)
            .accessibilityHidden(true)
        }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(p.ink.opacity(0.07), lineWidth: 1))
    .shadow(color: CSTokens.shadowLift.color, radius: 10, y: 6)
    .environment(\.colorScheme, .dark)
  }
}

/// The watermark's numbers, in one place. Outside the view because
/// `CredentialCard` is generic and a generic type cannot hold a static stored
/// property.
private enum Watermark {
  static let size: CGFloat = 250
  /// scaled with the glyph, not with the screen — see the note at the mark
  static let blur: CGFloat = size / 12
  /// room inside the raster for the stroke AND the blur's fall-off
  static let pad: CGFloat = 24 + blur * 2
  /// where the glyph sits, measured from the card's bottom-trailing corner
  /// with NO padding; the padding is added back at the offset.
  static let origin = CGSize(width: 50, height: 57)
  /// clear well inside the padded raster, so the mark has no boundary at all
  static let fade: CGFloat = size * 0.72
}

/// The `.cvs` chip: "VS YOU · 3–2 · YOU LEAD".
struct VsChip: View {
  private let p = CSTokens.dark
  let text: String
  /// Spoken form of the chip — the middots and small caps read badly aloud.
  /// A pill is a figure with a name, so the NAME is the accessibility label
  /// and the FIGURE is its value: VoiceOver reads "Versus you, 3–2, you lead"
  /// either way, but the rotor can find the chip by its name and a changed
  /// record is announced as a changed value. nil falls back to the text.
  var spokenLabel: String? = nil
  var spokenValue: String? = nil
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
    .accessibilityLabel(spokenLabel ?? text)
    .accessibilityValue(spokenValue ?? "")
    .accessibilityHint("Opens the rivalry")
  }
}

#Preview("Established, five milestones, on a streak") {
  CredentialCard(photoURL: nil, marker: "saguaro", name: "Jerecho Fischbeck", meta: "@jerecho · Tempe, AZ · Papago GC",
                 indexCurrent: 12.4, rounds: 42,
                 // five: three engraved, "+2 more" opens the rest in place
                 trophyLines: ["🔥 Broke 80 · '26", "📈 4-week streak · '26", "⛳ First round · '26",
                               "🎯 Broke 90 · '25", "📉 Personal best · '25"],
                 form: FormRow.from(beats: [true, true, true, false, true]), isMe: true,
                 anchor: { Text("GHIN 1234567 · est. Jul 2026").font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut) },
                 extra: { EmptyView() }, settings: {})
    .padding(20).background(CSTokens.light.bg0)
}

#Preview("Building — 2 of 3") {
  CredentialCard(photoURL: nil, marker: "thistle", name: "New Golfer", meta: "@newg · Mesa, AZ", indexCurrent: nil, rounds: 2,
                 trophyLines: [], form: nil, isMe: false, anchor: { EmptyView() }, extra: { EmptyView() })
    .padding(20).background(CSTokens.dark.bg0)
}
