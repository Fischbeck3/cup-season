// Cup Season — the You tab's "Membership & billing" card (plan §2b, deck slide 6).
//
// Replaces the PLAN · FREE · PILOT stub under the "Membership & billing"
// eyebrow in CardAndSettingsScreen (the eyebrow stays with the host). One row
// per league, a state per league:
//   A  Founding   — the gold badge, free forever
//   B  free season — this season is free; three chips carry next season's number
//   C  paid       — FUTURE: the markup exists, but nothing on the phone mints a
//                   `PricingPaid` (the Stripe phase on the web does, plan §3)
// and the constant footer line under all of them. Hidden flag → the stub, verbatim.

import SwiftUI
import CSDesign
import CupSeasonKit

struct MembershipCard: View {
  @Environment(\.cs) private var cs
  let flags: PricingFlags
  let memberships: [Me.Membership]
  /// The Pro's name per league, for State C's "renewed by"; falls back to the
  /// membership's own `commissioner_name`, then "the Pro".
  let proNames: [UUID: String]?
  /// Roster size per league, when the host knows it; else the anchor is quoted
  /// against `PricingFlags.referenceRoster`.
  var rosters: [UUID: Int] = [:]
  /// FUTURE — a paid pass per league. Nil for every league today.
  var paid: [UUID: PricingPaid] = [:]

  var body: some View {
    if flags.visible {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(memberships) { m in
          CSRow { row(m) }
        }
        PricingMarkdown("**Your golfer profile is free forever.** Index, record, rounds — yours for life, in any league or none.")
          .padding(.top, memberships.isEmpty ? 8 : 12)
      }
    } else {
      // Today's stub — verbatim, so flag-off is pixel-identical (plan §4).
      HStack { Text("PLAN").font(CSFont.label).foregroundStyle(cs.mut); Spacer(); Text("FREE · PILOT").font(CSFont.monoMediumBody).foregroundStyle(cs.ink) }
        .padding(.vertical, 8)
      Text("Cup Season membership lands at launch. Nothing to pay during the pilot.")
        .font(CSFont.footnote).foregroundStyle(cs.dimText)
    }
  }

  @ViewBuilder
  private func row(_ m: Me.Membership) -> some View {
    let state = PricingMembershipState.of(flags, leagueId: m.league_id, seasonNumber: m.season?.number,
                                          roster: rosters[m.league_id], paid: paid[m.league_id])
    VStack(alignment: .leading, spacing: 8) {
      switch state {
      case .founding(let n):
        PricingFoundingBadge(number: n)
        PricingMarkdown("**\(m.name)** — free forever.", font: CSFont.sentence, color: cs.ink)
        Text("One of the ten. Thanks for building this with us.").font(CSFont.footnote).foregroundStyle(cs.dimText)

      case .freeSeason(let season, let cents, let roster):
        PricingMarkdown("**\(m.name) · Season \(season)** — **This season is free.** Every league's first season is on us.",
                        font: CSFont.sentence, color: cs.ink)
        PricingChipRow(chips: ["After season 1 · \(PricingFlags.dollars(cents))/season",
                               "≈ \(PricingFlags.perPlayer(cents: cents, roster: roster)) a player",
                               "Paid by the Pro, from the pot"])

      case .paid(let p):
        Text(m.name).csEyebrow()
        PricingMarkdown("Season pass · paid through \(PricingDate.long(p.paidThrough)) · \(PricingFlags.dollars(p.cents)) · renewed by \(proName(m)) (the Pro) · from the pot.",
                        font: CSFont.subhead, color: cs.ink)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private func proName(_ m: Me.Membership) -> String {
    proNames?[m.league_id] ?? m.commissioner_name ?? "the Pro"
  }
}

#Preview("Membership · free season · dark") {
  PricingPreview(.dark) {
    VStack(alignment: .leading, spacing: 8) {
      Text("Membership & billing").csEyebrow()
      MembershipCard(flags: PricingSample.visible, memberships: [PricingSample.membership()], proNames: nil, rosters: [PricingSample.other: 12])
    }
  }
}
#Preview("Membership · free season · light") {
  PricingPreview(.light) {
    VStack(alignment: .leading, spacing: 8) {
      Text("Membership & billing").csEyebrow()
      MembershipCard(flags: PricingSample.visible, memberships: [PricingSample.membership()], proNames: nil, rosters: [PricingSample.other: 12])
    }
  }
}
#Preview("Membership · Founding + free · dark") {
  PricingPreview(.dark) {
    MembershipCard(flags: PricingSample.founding,
                   memberships: [PricingSample.membership(id: PricingSample.pigl, name: "PIGL"), PricingSample.membership(name: "The Back Nine")],
                   proNames: nil, rosters: [PricingSample.other: 8])
  }
}
#Preview("Membership · Founding + free · light") {
  PricingPreview(.light) {
    MembershipCard(flags: PricingSample.founding,
                   memberships: [PricingSample.membership(id: PricingSample.pigl, name: "PIGL"), PricingSample.membership(name: "The Back Nine")],
                   proNames: nil, rosters: [PricingSample.other: 8])
  }
}
#Preview("Membership · paid (future) · dark") {
  PricingPreview(.dark) {
    MembershipCard(flags: PricingSample.visible, memberships: [PricingSample.membership(seasonNumber: 2)], proNames: [PricingSample.other: "Jerecho"],
                   paid: [PricingSample.other: PricingPaid(paidThrough: "2027-09-26", cents: 7900)])
  }
}
#Preview("Membership · paid (future) · light") {
  PricingPreview(.light) {
    MembershipCard(flags: PricingSample.visible, memberships: [PricingSample.membership(seasonNumber: 2)], proNames: [PricingSample.other: "Jerecho"],
                   paid: [PricingSample.other: PricingPaid(paidThrough: "2027-09-26", cents: 7900)])
  }
}
#Preview("Membership · no league · dark") {
  PricingPreview(.dark) { MembershipCard(flags: PricingSample.visible, memberships: [], proNames: nil) }
}
#Preview("Membership · hidden → the stub") {
  PricingPreview(.dark) {
    VStack(alignment: .leading, spacing: 8) {
      Text("Membership & billing").csEyebrow()
      MembershipCard(flags: .hidden, memberships: [PricingSample.membership()], proNames: nil)
    }
  }
}
