// Cup Season — the You hero (IOS-019 rule 1): your credential as the one
// hero on the screen. Same bones as `.cred` (index.html 585–613) — the face
// panel, name, the index in gold once EARNED, the trophies engraved on it,
// the marker NAMED as the mono eyebrow, the form row — on the CSHero wash, in
// the screen's own theme. The Tour Card keeps `CredentialCard` (fixed dark
// face).
//
// D202 — the photograph owns the top of the card, or the marker does
// (`CredentialFace`). IOS-022 item 2 killed a 220pt watermark at 10%, which
// was a smudge on charcoal and a stain on paper; a crest at ink on the look's
// wash is the opposite object, and the eyebrow still says the marker's name
// out loud — under the panel now, where it reads as its caption.

import SwiftUI
import CSDesign
import CupSeasonKit

/// Y-11 · how far the trailing fade on the milestone row ramps, and how much
/// room the row leaves past its last chip so that chip is never the thing
/// being faded. (A file constant because `YouHero` is generic, and a generic
/// type cannot hold a static stored property.)
private enum HeroChips { static let fade: CGFloat = 24 }

struct YouHero<Anchor: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  @Environment(SessionStore.self) private var session

  let photoURL: URL?
  let marker: String?
  let name: String
  /// "@handle · city · home course"
  let meta: String
  let indexCurrent: Double?
  /// rounds on the card — drives "n of 3" until the index is established
  let rounds: Int
  /// EVERY engraved line — "🔥 Broke 80 · '26" … The card shows
  /// `TrophyMeta.credentialChips` of them; "+N more in the case" adds the rest
  /// to the row in place (P3 nit: a chip that only says "more" and goes
  /// nowhere is a dead end, and the case is two sections down).
  let trophyChips: [String]
  let form: FormRow?
  @ViewBuilder let anchor: () -> Anchor

  @State private var expanded = false

  private var established: Bool { indexCurrent != nil }
  private var shown: [String] { expanded ? trophyChips : Array(trophyChips.prefix(TrophyMeta.credentialChips)) }
  private var hidden: Int { max(0, trophyChips.count - TrophyMeta.credentialChips) }

  var body: some View {
    // gold once the index is established (earned); otherwise the personal look's accent, ember when none (IOS-025)
    CSHero(spine: established ? cs.gold : nil, padding: 20) {
      VStack(alignment: .leading, spacing: 0) {
          // the panel bleeds to the card's edges — the 20pt hero padding is
          // for the record below it, not for the face
          CredentialFace(photoURL: photoURL, marker: marker, name: name,
                         badge: session.founding.badge(for: session.me?.profile?.id),
                         meta: meta, p: cs, accent: la.accent,
                         sub: { anchor() }, trailing: { EmptyView() })
            .padding(.horizontal, -20).padding(.top, -20)

          // the marker's name — the web's `.cred` watermark, said out loud, as
          // the CAPTION of the panel above it.
          // Y-08 · it used to be `csEyebrow`, the same face, size and tracking
          // as every stat label on the page, sitting directly over "11.3 ·
          // HANDICAP INDEX" — so "THE NO. 2" read as a rank. Its own mark
          // beside it in the sentence face can only be what it is. D103b's
          // look accent moves to the mark, so the personal dial still shows.
          HStack(spacing: 6) {
            CSMarkerView(key: marker, size: 15).foregroundStyle(la.accent)
            Text(CSMarkers.marker(marker).name).font(CSFont.footnote).foregroundStyle(cs.mut)
          }
          .padding(.top, 16)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("Marker: \(CSMarkers.marker(marker).name)")

          VStack(alignment: .leading, spacing: 4) {
            if let idx = indexCurrent {
              Text(CSCopy.index(idx)).font(CSFont.hero).foregroundStyle(cs.gold).csTabular()   // EARNED: the number, once established
            } else {
              Text(Career.establishing(rounds: rounds)).font(CSFont.hero).foregroundStyle(cs.ink).csTabular()
            }
            Text("Handicap index").font(CSFont.label).tracking(1.8).textCase(.uppercase).foregroundStyle(cs.mut)
          }
          .padding(.top, 10)
          .accessibilityElement(children: .combine)

          if !established {
            // P3 nit: this sentence used to be the hint on the row above it as
            // well, so VoiceOver said it twice. It is visible; that is enough.
            Text(YouCopy.buildingNumber)
              .font(CSFont.footnote).foregroundStyle(cs.mut).padding(.top, 8)
          }

          if !trophyChips.isEmpty {
            // bleeds to the card edge so a clipped chip reads as "more to the
            // right", not a cut.
            // Y-11 · that only worked while the bleed carried a FADE. Without
            // one the card's own `clipShape` cut the third chip through the
            // middle of a glyph ("Broke 1|") with nothing to say the row
            // scrolled. The mask ramps the last `chipFade` points out, and the
            // row's trailing inset is that much wider — so at the far right
            // the last chip stops before the ramp and is never dimmed, and the
            // fade only ever eats empty space or a chip there IS more of.
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 6) {
                // by index: two milestones of the same kind and year engrave the same line
                ForEach(Array(shown.enumerated()), id: \.offset) { _, line in
                  YouTrophyChip(text: line, earned: true)
                    .accessibilityLabel(TrophyMeta.spoken(line))   // Y-33 · VoiceOver says "Broke 80", not "fire, Broke 80"
                }
                // P3 nit: the expansion goes both ways. It used to be a
                // one-way door — the "+N more" chip vanished on the first tap
                // and the row could never be folded again.
                if hidden > 0 {
                  Button { withAnimation(.easeOut(duration: 0.18)) { expanded.toggle() } } label: {
                    YouTrophyChip(text: expanded ? TrophyMeta.showFewer : TrophyMeta.moreLine(hidden, suffix: TrophyMeta.moreInCase), earned: false)
                  }
                  .buttonStyle(.plain)
                  .accessibilityLabel(expanded ? "Show fewer milestones" : "\(hidden) more milestone\(hidden == 1 ? "" : "s")")
                  .accessibilityHint(expanded ? "Folds the row back" : "Adds them to this row")
                }
              }
              .padding(.leading, 20).padding(.trailing, 20 + HeroChips.fade)
            }
            .padding(.horizontal, -20)
            .mask { chipFadeMask }   // iOS 15+ overload; the deprecated `mask(_:)` takes no alignment
            .padding(.top, 14)
          }

          // Y-08 · the dots' key rides the row itself, so the sentence has one
          // home. Nothing on the page said what a lit dot meant unless a streak
          // pill happened to be sitting beside them, and a VoiceOver label is
          // not a legend for the eye.
          if let form { FormRowView(form: form, palette: cs, caption: YouCopy.formKey) }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
  }

  /// An ALPHA ramp, not a colour: opaque to the card's right edge, then out
  /// over `chipFade` points. Hit-testing is untouched, so the last chip stays
  /// reachable — a mask hides pixels, never touches.
  private var chipFadeMask: some View {
    HStack(spacing: 0) {
      Rectangle().fill(.black)
      LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .leading, endPoint: .trailing)
        .frame(width: HeroChips.fade)
    }
  }
}

/// One engraved line as a chip: gold for hardware, quiet for "+N more".
struct YouTrophyChip: View {
  @Environment(\.cs) private var cs
  let text: String
  let earned: Bool
  var body: some View {
    Text(text).font(CSFont.label).tracking(0.4).lineLimit(1)
      .foregroundStyle(earned ? cs.gold : cs.mut)
      .padding(.horizontal, 10).frame(minHeight: 28)
      .background((earned ? cs.gold : cs.ink).opacity(0.08), in: Capsule())
      .overlay(Capsule().stroke(earned ? cs.gold.opacity(0.35) : cs.line2, lineWidth: 1))
  }
}

#Preview("Established, five milestones, on a streak") {
  ScrollView {
    YouHero(photoURL: nil, marker: "saguaro", name: "Jerecho Fischbeck", meta: "@jerecho · Tempe, AZ · Papago GC",
            indexCurrent: 12.4, rounds: 42,
            trophyChips: ["🔥 Broke 80 · '26", "📈 4-week streak · '26", "⛳ First round · '26", "🎯 Broke 90 · '25", "📉 Personal best · '25"],
            form: FormRow.from(beats: [true, true, true, false, true]),
            anchor: { Text("GHIN 1234567 · est. Jul 2026").font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut) })
      .padding(20)
  }
  .background(CSTokens.dark.bg0).csTheme()
}

#Preview("Building — 2 of 3, light") {
  ScrollView {
    YouHero(photoURL: nil, marker: "thistle", name: "New Golfer", meta: "@newg · Mesa, AZ", indexCurrent: nil, rounds: 2,
            trophyChips: [], form: nil, anchor: { EmptyView() })
      .padding(20)
  }
  .background(CSTokens.light.bg0).environment(\.colorScheme, .light).csTheme()
}
