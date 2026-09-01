// Cup Season — the You hero (IOS-019 rule 1): your credential as the one
// hero on the screen. Same bones as `.cred` (index.html 585–613) — face,
// name, the index in gold once EARNED, the trophies engraved on it, the
// marker NAMED as the mono eyebrow, the form row — on the CSHero wash, in
// the screen's own theme. The Tour Card keeps `CredentialCard` (fixed dark
// face). IOS-022 item 2: the 220pt watermark went — at 10% it was a smudge
// on charcoal and a stain on paper; "THE SAGUARO" in the scorer's voice says
// the same thing legibly, in a screenshot and to VoiceOver.

import SwiftUI
import CSDesign
import CupSeasonKit

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
  /// "🔥 Broke 80 · '26" …
  let trophyChips: [String]
  /// "+N more in the case" — the last chip, quieter
  let moreChip: String?
  let form: FormRow?
  /// IOS-029 call 1 · the face is a DOOR: the photo picker when there is no
  /// photo, the card editor when there is. It was inert — the most obvious
  /// tap target on the screen did nothing, and 1 profile in 39 had a photo.
  var onTapFace: (() -> Void)? = nil
  @ViewBuilder let anchor: () -> Anchor

  private var established: Bool { indexCurrent != nil }

  /// The face at 88, with the ember `+` when there is no photo yet. Wrapped in
  /// a Button only when the host gave it somewhere to go, so a preview or a
  /// read-only host never renders a control that cannot do anything.
  @ViewBuilder private var faceDoor: some View {
    let face = ZStack(alignment: .bottomTrailing) {
      CSFace(photoURL: photoURL, marker: marker, size: 88)
      if photoURL == nil && onTapFace != nil {
        Image(systemName: "plus")
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(cs.bg0)
          .frame(width: 28, height: 28)
          .background(cs.brand, in: Circle())
          .overlay(Circle().stroke(cs.bg1, lineWidth: 2))
      }
    }
    if let onTapFace {
      Button(action: onTapFace) { face }
        .buttonStyle(.plain)
        .accessibilityLabel(photoURL == nil ? "Add your photo" : "Edit your card")
    } else {
      face
    }
  }

  var body: some View {
    // gold once the index is established (earned); otherwise the personal look's accent, ember when none (IOS-025)
    CSHero(spine: established ? cs.gold : nil, padding: 20) {
      VStack(alignment: .leading, spacing: 0) {
          // the marker's name as the eyebrow — the web's `.cred` watermark, said out loud
          // D103b: the hero eyebrow wears the personal look's accent; mut on homebase (gold stays the number's)
          Text(CSMarkers.marker(marker).name).csEyebrow(la.eyebrow).padding(.bottom, 12)
            .accessibilityLabel("Marker: \(CSMarkers.marker(marker).name)")
          HStack(alignment: .center, spacing: 14) {
            // IOS-028 A1 / IOS-029 · 56 was web parity, not a size decision.
            // On the phone this credential is the ONE hero on a full screen
            // (IOS-019 rule 1), and the face was the smallest element on it
            // carrying the largest share of the identity.
            faceDoor
            VStack(alignment: .leading, spacing: 3) {
              Text(name).font(CSFont.title).foregroundStyle(cs.ink).lineLimit(2)
              FoundingTag(badge: session.founding.badge(for: session.me?.profile?.id)).padding(.vertical, 2)
              if !meta.isEmpty {
                Text(meta).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(cs.mut)
              }
              anchor()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }

          VStack(alignment: .leading, spacing: 4) {
            if let idx = indexCurrent {
              Text(CSCopy.index(idx)).font(CSFont.hero).foregroundStyle(cs.gold).csTabular()   // EARNED: the number, once established
            } else {
              Text(Career.establishing(rounds: rounds)).font(CSFont.hero).foregroundStyle(cs.ink).csTabular()
            }
            Text("Handicap index").font(CSFont.label).tracking(1.8).textCase(.uppercase).foregroundStyle(cs.mut)
          }
          .padding(.top, 18)
          .accessibilityElement(children: .combine)
          .accessibilityHint(established ? "" : "Building your number — your index appears at 3 posted rounds")

          if !established {
            Text("Building your number — your index appears at 3 posted rounds")
              .font(CSFont.footnote).foregroundStyle(cs.mut).padding(.top, 8)
          }

          if !trophyChips.isEmpty || moreChip != nil {
            // bleeds to the card edge so a clipped chip reads as "more to the right", not a cut
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 6) {
                ForEach(trophyChips, id: \.self) { YouTrophyChip(text: $0, earned: true) }
                if let moreChip { YouTrophyChip(text: moreChip, earned: false) }
              }
              .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
            .padding(.top, 14)
            .accessibilityElement(children: .combine)
          }

          if let form { FormRowView(form: form, palette: cs) }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
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

#Preview("Established, three trophies, on a streak") {
  ScrollView {
    YouHero(photoURL: nil, marker: "saguaro", name: "Jerecho Fischbeck", meta: "@jerecho · Tempe, AZ · Papago GC",
            indexCurrent: 12.4, rounds: 42, trophyChips: ["🔥 Broke 80 · '26", "📈 4-week streak · '26", "⛳ First round · '26"],
            moreChip: "+2 more in the case", form: FormRow.from(beats: [true, true, true, false, true]),
            anchor: { Text("GHIN 1234567 · Member since Jul 2026").font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut) })
      .padding(20)
  }
  .background(CSTokens.dark.bg0).csTheme()
}

#Preview("Building — 2 of 3, light") {
  ScrollView {
    YouHero(photoURL: nil, marker: "thistle", name: "New Golfer", meta: "@newg · Mesa, AZ", indexCurrent: nil, rounds: 2,
            trophyChips: [], moreChip: nil, form: nil, anchor: { EmptyView() })
      .padding(20)
  }
  .background(CSTokens.light.bg0).environment(\.colorScheme, .light).csTheme()
}
