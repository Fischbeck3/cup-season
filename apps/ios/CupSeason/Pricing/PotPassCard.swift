// Cup Season — the pot pane's pass card, Pro view (plan §2c, deck slide 7).
//
// Mounts in PotPane after the Season-stakes card + payout trio; members see
// the pane as today (this renders nothing for them), the Pro sees the pass.
// Founding leagues swap to the gold badge + "free forever". The fine print
// under the trio — `PricingPotFinePrint` — updates for EVERYONE, and carries
// today's sentence pair when the flag is off so it can replace the existing
// Text in place.
//
// "run-it-back opens with the recap" is static copy at launch — the surface
// itself is the Stripe phase (plan §2e). Nothing here is tappable; nothing
// here is a purchase.

import SwiftUI
import CSDesign
import CupSeasonKit

struct PotPassCard: View {
  @Environment(\.cs) private var cs
  let flags: PricingFlags
  let league: Me.Membership
  let isPro: Bool
  /// "YYYY-MM-DD" — the first tee of the league's year; the free year runs
  /// twelve months from it. The pass table owns this once checkout exists;
  /// until then the host passes the current season's `starts_on`. Nil → the
  /// static line only.
  let yearStartsOn: String?
  /// The pane's `potPlayers`, when the host passes it; else the reference roster.
  var roster: Int? = nil

  var body: some View {
    if flags.visible && isPro {
      CSCard(padding: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("League pass · Pro only").csEyebrow()
          if let n = flags.foundingNumber(leagueId: league.league_id) {
            PricingFoundingBadge(number: n)
            PricingMarkdown("**\(league.name)** — free forever.", font: CSFont.sentence, color: cs.ink)
          } else {
            let r = roster ?? PricingFlags.referenceRoster
            let band = flags.passFor(roster: r)
            let price = PricingFlags.dollars(band.cents)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text("Year 1 — free.").font(CSFont.sentenceBold).foregroundStyle(cs.ink)
              Text(price).font(CSFont.monoMediumBody).strikethrough().foregroundStyle(cs.dimText)
                .accessibilityLabel("\(price), waived")
            }
            Text(endsLine).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
              .fixedSize(horizontal: false, vertical: true)
            /* The words "paid from the pot" shipped in the binary until 2026-09-01,
               one boolean flip away from rendering. Arizona’s social-gambling
               exemption (A.R.S. §13-3301) turns on nobody but the players receiving
               a benefit from the stakes — so a sentence saying the pot pays Cup
               Season’s fee is the sentence that makes this a rake. The Pro may
               still choose to fund it that way; the PRODUCT must not say so. */
            Text("Next year it’s \(price) for the league — about \(PricingFlags.perPlayer(cents: band.cents, roster: r)) a player, with every season included.")
              .font(CSFont.subhead).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
      .accessibilityElement(children: .combine)
    }
  }

  private var endsLine: String {
    if let start = yearStartsOn, let end = PricingDate.yearAfter(start) { return "Your year runs to \(PricingDate.long(end)) · every season till then is covered" }
    return "Every season you run this year is covered"
  }
}

/// The sentence pair under the payout trio. Flag on: the D56 pair (the pass is
/// the one line paid to Cup Season — the pot never is). Flag off: today's pair,
/// verbatim, so the host can swap the existing Text for this view outright.
struct PricingPotFinePrint: View {
  let flags: PricingFlags
  var body: some View {
    PricingMarkdown(flags.visible
      ? "**Cup Season keeps the books.** Buy-ins and payouts move friend-to-friend on Venmo or cash. The pass is the one line paid to Cup Season — it never comes out of the prize money."
      : "**Cup Season keeps the books.** Buy-ins and payouts move friend-to-friend. We just make sure nobody argues at the bar.")
  }
}

#Preview("Pot pass · Pro · dark") {
  PricingPreview(.dark) {
    VStack(alignment: .leading, spacing: 14) {
      PricingPotFinePrint(flags: PricingSample.visible)
      PotPassCard(flags: PricingSample.visible, league: PricingSample.membership(), isPro: true, yearStartsOn: "2026-05-03", roster: 12)
    }
  }
}
#Preview("Pot pass · Pro · light") {
  PricingPreview(.light) {
    VStack(alignment: .leading, spacing: 14) {
      PricingPotFinePrint(flags: PricingSample.visible)
      PotPassCard(flags: PricingSample.visible, league: PricingSample.membership(), isPro: true, yearStartsOn: "2026-05-03", roster: 12)
    }
  }
}
#Preview("Pot pass · Founding · dark") {
  PricingPreview(.dark) {
    PotPassCard(flags: PricingSample.founding, league: PricingSample.membership(id: PricingSample.pigl, name: "PIGL"), isPro: true, yearStartsOn: "2026-05-03")
  }
}
#Preview("Pot pass · Founding · light") {
  PricingPreview(.light) {
    PotPassCard(flags: PricingSample.founding, league: PricingSample.membership(id: PricingSample.pigl, name: "PIGL"), isPro: true, yearStartsOn: "2026-05-03")
  }
}
#Preview("Pot pass · member (nothing) + today's fine print") {
  PricingPreview(.dark) {
    VStack(alignment: .leading, spacing: 14) {
      PricingPotFinePrint(flags: .hidden)
      PotPassCard(flags: PricingSample.visible, league: PricingSample.membership(role: "player"), isPro: false, yearStartsOn: "2026-05-03")
    }
  }
}
