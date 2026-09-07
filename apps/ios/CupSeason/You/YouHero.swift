// Cup Season — the You hero IS the card (Wave 2, `surfaces/player-card.md` §8;
// IOS-047).
//
// **One object, one chrome, one ratio, one meta string.** The You tab drew a
// `CSHero` wash with a gold spine, a `CredentialFace` panel at a different
// aspect ratio from the Tour Card's, a second identity line built from
// different clauses, a scrolling row of emoji milestone chips with a trailing
// fade, and a dot row — five things the person page did differently for the
// same golfer. It is now `CSCredential` at hero size, which is the same object
// the card screen and the person page draw, from the same producer.
//
// WHAT LEFT WITH IT: `CSHero`'s wash and the gold spine (the spine is retired
// product-wide, `UI_SYSTEM` §0.3), and the milestone chip row — **milestones
// move to the record, without emoji** (YRS-03, CH-01). `trophyChips:` stays in
// the signature so `YouScreen` is untouched by this wave; **Wave 3 removes the
// parameter** when it rebuilds the tab around the record.
//
// WHAT STAYS UNTIL WAVE 3: the dot form row. `FormRow` carries verdicts, not
// grosses, and §9.7's row is five GROSSES with their dates on one rule with the
// best in gold — which needs `career.recent`, which is the You tab's own read
// and the You tab's own wave. Deleting the dots here would take the form off
// the tab for a wave rather than replace it, so the row is kept and the wave
// that replaces it is named.

import SwiftUI
import CSDesign
import CupSeasonKit

struct YouHero<Anchor: View>: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var session

  let photoURL: URL?
  let marker: String?
  let name: String
  /// The identity line. `CredentialCopy.identity` produces it once for both
  /// clients; this parameter is what the caller already computed and Wave 3
  /// retires in favour of the producer.
  let meta: String
  let indexCurrent: Double?
  let rounds: Int
  /// **Unused, and named as such.** Milestones move to the record (YRS-03);
  /// Wave 3 deletes the parameter with the section that fed it.
  let trophyChips: [String]
  let form: FormRow?
  @ViewBuilder let anchor: () -> Anchor

  private var profileId: UUID? { session.me?.profile?.id }

  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      CSCredential(golfer, hasPhoto: photoURL != nil) { plate }
      anchor()
      if let form { FormRowView(form: form, palette: cs, caption: YouCopy.formKey) }
    }
  }

  private var golfer: CSCredentialGolfer {
    var figures: [CSCredentialGolfer.Figure] = []
    if let idx = indexCurrent {
      figures.append(.init(CSCopy.index(idx), label: "Handicap index"))
    }
    figures.append(.init(String(rounds), label: "Rounds"))
    if let m = session.me?.memberships.first(where: { $0.standing != nil }), let st = m.standing {
      figures.append(.init(String(st.rank), label: m.name, ordinal: CSOrdinal.suffix(st.rank)))
    }
    return CSCredentialGolfer(
      face: CSFace.Model(id: profileId ?? UUID(), marker: marker, photoURL: photoURL,
                         initials: Initials.of(name), isViewer: true),
      name: name,
      identity: meta,
      slot: slot,
      figures: figures,
      club: CredentialCopy.club(markerName: CSMarkers.marker(marker).name))
  }

  /// The one gold object on the surface, and absent when nothing was earned.
  private var slot: String? {
    switch session.founding.badge(for: profileId) {
    case .founder: "Founder"
    case .member: "Founding member"
    case nil: nil
    }
  }

  @ViewBuilder private var plate: some View {
    if let photoURL {
      AsyncImage(url: photoURL) { phase in
        switch phase {
        case .success(let img): img.resizable().scaledToFill()
        default: crest
        }
      }
    } else {
      crest
    }
  }

  private var crest: CSCrestPlate {
    let course = session.me?.profile?.home_course.flatMap { $0.isEmpty ? nil : $0 }
    return CSCrestPlate(marker: marker,
                        seed: course ?? profileId?.uuidString ?? "cup-season",
                        hasCourse: course != nil)
  }
}

#Preview("The hero is the card") {
  ScrollView {
    YouHero(photoURL: nil, marker: "saguaro", name: "Jerecho Fischbeck",
            meta: "@jerecho · Tempe, AZ · Papago",
            indexCurrent: 12.4, rounds: 42, trophyChips: [],
            form: FormRow.from(beats: [true, true, true, false, true]),
            anchor: { EmptyView() })
      .padding(20)
  }
  .background(CSTokens.dark.bg0)
  .environment(SessionStore())
  .csTheme()
}
