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
      // D266 · same removal as `PotPassCard`. The block's own eyebrow over a
      // rule is the whole of what the border was doing.
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        CSRule()
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          Text("The league pass").csEyebrow()
          VStack(alignment: .leading, spacing: 4) {
            Text("One pass, the whole league, every season you run for a year —").csType(.story).foregroundStyle(cs.ink)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
              Text(price).csType(.figureS).foregroundStyle(cs.ink)
              Text(bragging ? "· ≈ \(each) a golfer · split it on Venmo — less than a sleeve each"
                            : "· ≈ \(each) a golfer a year · one line on the buy-in")
                .font(CSFont.label).tracking(0.6).foregroundStyle(cs.mut)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .accessibilityElement(children: .combine)
          PricingFreeLine("**Your first year is free.** The pass starts if you're still running it a year from your first tee.")
          PricingMarkdown("**Where the money goes:** the pass is paid to Cup Season. The pot never is — " + MoneyCopy.ledger)
        }
      }
      .padding(.vertical, CSTokens.Space.s2)
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
