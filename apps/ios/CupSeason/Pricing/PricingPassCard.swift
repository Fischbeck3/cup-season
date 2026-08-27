// Cup Season — the wizard's pass card (plan §2a, deck slide 5).
//
// Mounts on the stakes step AFTER the pot preview, BEFORE the pot-split
// eyebrow. Numbers are live: `passFor(roster)` against the wizard's roster
// estimate, recomputed on roster and buy-in changes by the host. A $0 buy-in
// swaps the per-player tail to the bragging-rights framing (discovery §1.5)
// and never hides the card. Hidden flag → nothing at all.
//
// Laws: the pass never wears gold — the number is plain ink. The pass is paid
// TO Cup Season; the pot is never held BY it — the fine print keeps them in
// separate sentences (D39).

import SwiftUI
import CSDesign
import CupSeasonKit

struct PricingPassCard: View {
  @Environment(\.cs) private var cs
  let flags: PricingFlags
  let roster: Int
  let buyInCents: Int?

  var body: some View {
    if flags.visible {
      let band = flags.passFor(roster: roster)
      let price = PricingFlags.dollars(band.cents)
      let each = PricingFlags.perPlayer(cents: band.cents, roster: roster)
      let bragging = (buyInCents ?? 0) == 0
      CSCard(padding: 16) {
        VStack(alignment: .leading, spacing: 10) {
          Text("The season pass").csEyebrow()
          VStack(alignment: .leading, spacing: 4) {
            Text("One pass, whole league, all season —").font(CSFont.sentence).foregroundStyle(cs.ink)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
              Text(price).font(CSFont.stat).csTabular().foregroundStyle(cs.ink)
              Text(bragging ? "· ≈ \(each) a player · split it on Venmo — less than a sleeve each"
                            : "· ≈ \(each) a player · one line on the buy-in")
                .font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .accessibilityElement(children: .combine)
          PricingFreeLine("**Your first season is free.** The pass starts if you run it back.")
          PricingMarkdown("**Where the money goes:** the pass is paid to Cup Season. The pot never is — buy-ins and payouts move friend-to-friend, and the app keeps the books so nobody argues at the bar.")
        }
      }
    }
  }
}

#Preview("Pass · 12 · $75 buy-in · dark") {
  PricingPreview(.dark) { PricingPassCard(flags: PricingSample.visible, roster: 12, buyInCents: 7500) }
}
#Preview("Pass · 12 · $75 buy-in · light") {
  PricingPreview(.light) { PricingPassCard(flags: PricingSample.visible, roster: 12, buyInCents: 7500) }
}
#Preview("Pass · 8 · bragging rights · dark") {
  PricingPreview(.dark) { PricingPassCard(flags: PricingSample.visible, roster: 8, buyInCents: 0) }
}
#Preview("Pass · 8 · bragging rights · light") {
  PricingPreview(.light) { PricingPassCard(flags: PricingSample.visible, roster: 8, buyInCents: 0) }
}
#Preview("Pass · 16 · dark") {
  PricingPreview(.dark) { PricingPassCard(flags: PricingSample.visible, roster: 16, buyInCents: 10000) }
}
#Preview("Pass · hidden (renders nothing)") {
  PricingPreview(.dark) { PricingPassCard(flags: .hidden, roster: 12, buyInCents: 7500) }
}
