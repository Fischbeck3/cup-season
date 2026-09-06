// Cup Season — the dispatch card (D228, D231, IOS-029b).
//
// One shape, two weights. The LEAD is the rank-1 item, drawn as a hero with a
// spine; a DECK item is the same grammar at a smaller weight. Neither knows
// anything about what it is saying — the sentences are the ranker's, the
// arrangement is `HomeRank`'s, and this file only lays them out.
//
// THE CARD GRAMMAR, and it is the same on both clients (UX_PRINCIPLES.md §4):
//
//     mono dateline  ·  serif headline  ·  sans standfirst  ·  one ember verb
//
// The 3.5-px spine does the state signalling: ember for a clock, gold for
// something earned, a mut hairline for quiet-and-true. Gold never touches the
// verb — a verb is a control, and gold on a control is a defect, not a taste
// call (L-25).
//
// It replaces the four-faced D176 card, whose ladder is now a written desk
// rule on the server. What it keeps from that card is the discipline: ONE
// card at the top, never a stack, and no card at all is a legal answer.

import SwiftUI
import CSDesign
import CupSeasonKit

struct HomeLeadCard: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let item: HomeDispatch.Item
  /// The card's single action — the one door the ranker put under it.
  let act: () -> Void

  private var spine: Color {
    switch item.spine {
    case .ember: cs.brand
    case .gold:  cs.gold
    case .mut:   la.active ? la.accent : cs.line2
    }
  }

  var body: some View {
    CSHero(spine: spine, padding: 18) {
      VStack(alignment: .leading, spacing: 8) {
        Text(item.eyebrow).csEyebrow(item.spine == .gold ? cs.gold : (item.spine == .ember ? cs.brand : la.eyebrow))
          .fixedSize(horizontal: false, vertical: true)
        // AX3 · the headline wraps; it never truncates and never shrinks below
        // the type scale's own floor.
        Text(item.headline).font(CSFont.sentenceBold).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
        if let s = item.standfirst, !s.isEmpty {
          Text(s).font(CSFont.subhead).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        if let a = item.action, !a.isEmpty {
          Button(action: act) {
            HStack(spacing: 6) { Text(a); Text("→") }
              .font(CSFont.button).foregroundStyle(cs.brand).a11yHitSlop()
          }
          .buttonStyle(.plain)
          .accessibilityLabel(a)
          .padding(.top, 2)
        }
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel([item.eyebrow, item.headline, item.standfirst].compactMap { $0 }.joined(separator: ". "))
  }
}

/// A deck item: the same grammar, one weight down, still one sentence and one
/// door. The cap is four of these (`HomeRank.deckCap`) and a shorter deck is a
/// SHORTER DECK — never a padded one (§3's never-empty rule).
struct HomeDeckCard: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let item: HomeDispatch.Item
  /// D229 · when the cap bites, the last card's foot says how many seasons'
  /// items did not fit rather than the screen pretending they do not exist.
  var moreCut: Int = 0
  let act: () -> Void
  var onMore: () -> Void = {}

  private var spine: Color {
    switch item.spine {
    case .ember: cs.brand
    case .gold:  cs.gold
    case .mut:   la.active ? la.accent : cs.line2
    }
  }

  var body: some View {
    CSCard(spine: spine) {
      VStack(alignment: .leading, spacing: 6) {
        Text(item.eyebrow).csEyebrow(item.spine == .gold ? cs.gold : la.eyebrow)
          .fixedSize(horizontal: false, vertical: true)
        Text(item.headline).font(CSFont.sentenceBold).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
        if let s = item.standfirst, !s.isEmpty {
          Text(s).font(CSFont.footnote).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        if let a = item.action, !a.isEmpty {
          Button(action: act) {
            HStack(spacing: 6) { Text(a); Text("→") }
              .font(CSFont.monoSmall).foregroundStyle(cs.brand).a11yHitSlop()
          }
          .buttonStyle(.plain)
          .accessibilityLabel(a)
          .padding(.top, 2)
        }
        if moreCut > 0 {
          Button(action: onMore) {
            Text("\(moreCut) more →").font(CSFont.label).foregroundStyle(cs.mut).a11yHitSlop()
          }
          .buttonStyle(.plain)
          .accessibilityLabel("\(moreCut) more, in Golfers")
        }
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel([item.eyebrow, item.headline, item.standfirst].compactMap { $0 }.joined(separator: ". "))
  }
}

#Preview("The lead · a clash closing") {
  HomeLeadCard(item: .init(key: "clash", tier: .closing, rank: 1, score: 1056,
                           subject: "Galen", humanSubject: true,
                           eyebrow: "THE FELLAS · THE CLASH · CLOSES IN 2 DAYS",   // LV-23 · a neutral fixture; a preview is a screenshot source
                           headline: "Galen has two days to answer your 89.",
                           standfirst: "Your round is the number to beat.",
                           action: "See the receipt", route: .composer, spine: .ember),
               act: {})
    .padding(20).csTheme()
}

#Preview("A deck item · the chapter") {
  HomeDeckCard(item: .init(key: "chapter", tier: .chapter, rank: 3, score: 205,
                           subject: "Galen", humanSubject: true,
                           eyebrow: "FELLAS · WEEK 7 OF 26",
                           headline: "Galen is the one to catch.",
                           standfirst: "4 back of Galen.",
                           action: "Open the season", route: .composer, spine: .mut),
               act: {})
    .padding(20).csTheme()
}
