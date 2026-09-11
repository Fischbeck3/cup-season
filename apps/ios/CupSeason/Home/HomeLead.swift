// Cup Season — THE LEAD, weight 1 (IOS-046, `surfaces/home.md` §1.2).
//
// The rank-1 item as a **block on the ground**: the sentence in the left
// column, the chip in the right, and nothing drawn around either of them. It
// replaces `HomeLeadCard`'s `CSHero(spine:)` frame — the ember-spine reasoning
// and the two-up clash survive as DATA, the frame does not — and it deletes
// `HomeDeckCard` outright: ranked items 2–5 enter the wire at the weight their
// kind earns rather than as four smaller copies of the lead (audit H-01).
//
// **THE CHIP CARRIES THE RANK, AND IT IS THE ONLY THING THAT DOES** (§16A.4).
// The first draft said the reader's rank three times inside 400pt — in the
// headline, in a chip, and in a `▲2 SPOTS` rule-and-figure sharing a baseline
// with the schedule link. All three blind reviewers filed it. The chip now
// carries the figure, the ordinal and the movement in ONE 84 × 90 block, the
// `SPOTS` rule-and-figure is deleted, and the copy runs the full column.
//
// **THE CHIP'S NUMBER IS A CLIENT-SIDE JOIN, NOT NEW DATA.** The dispatch item
// carries no figure; `item.leagueId` → `me.memberships[].standing` reads
// `rank` / `of` / `prev_rank`, two facts the payload already ships. **A chip
// is never invented to fill the column**: an invitation, a buddy request and a
// first round have no figure, and the sentence takes the whole measure.

import SwiftUI
import CSDesign
import CupSeasonKit

struct HomeLead: View {
  @Environment(\.cs) private var cs
  let item: HomeDispatch.Item
  /// The item's own season, joined by `leagueId`. nil = no chip.
  let membership: Me.Membership?
  /// The one door the ranker put under it.
  let act: () -> Void

  /// `LIVE` is a clock running, and it is the item's own spine — ember means
  /// live, and it is the eyebrow, the dot and the door's rule, which is ONE
  /// ember object however many marks it takes to draw it.
  private var live: Bool { item.spine == .ember }

  /// The league tag, flush right on the eyebrow's baseline — and **only when
  /// the eyebrow does not already name it**, because `THE DEW SWEEPERS ·
  /// SEASON COMPLETE` beside a `THE DEW SWEEPERS` tag is the same four words
  /// twice on one line.
  private var tag: String? {
    guard let name = membership?.name, !name.isEmpty else { return nil }
    let e = item.eyebrow.lowercased()
    return e.contains(name.lowercased()) ? nil : name
  }

  /// `CHAMPION · MIKE FENNER` — the gold slot, and the viewport's one gold
  /// object. It renders only for an EARNED item (`spine == .gold`) that has a
  /// champion to name; an earned item with nobody on the end of it prints no
  /// slot rather than an empty one.
  private var credit: (slot: String, name: String)? {
    guard item.spine == .gold, let last = membership?.last_season,
          let who = last.champion_name, !who.isEmpty else { return nil }
    return (slot: last.champion_is_me == true ? "Champion · you" : "Champion", name: who)
  }

  private var door: CSDoor.Kind? {
    guard let a = item.action, !a.isEmpty else { return nil }
    // §1.5's one-ember rule: the lead's door wears the live metal only while
    // the lead IS live. Between seasons nothing is running, so the same door
    // is a `mut` rule and the floor's lit door becomes the screen's one ember.
    return live ? .primary(a, act) : .link(a, act)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      CSRule()
      Text(item.eyebrow).csType(.agateS, caps: true).foregroundStyle(live ? cs.brand : cs.mut)
      A11yStack(rowAlignment: .top, spacing: CSTokens.Space.s3) {
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          Text(item.headline).csType(.story).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
          if let detail = item.standfirst {
            Text(detail).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
        }.frame(maxWidth: .infinity, alignment: .leading)
        if let chip = HomeLeadChip.make(membership) {
          CSFigure(String(chip.rank), size: .m, label: "of \(chip.of)", ordinal: CSOrdinal.suffix(chip.rank))
            .fixedSize(horizontal: true, vertical: false)
        }
      }
      if let action = item.action, !action.isEmpty { CSDoor(.link(action, act)) }
      if let credit { Text("\(credit.slot) · \(credit.name)").csType(.agateS).foregroundStyle(cs.gold) }
    }
    // §7 · ONE VoiceOver element for the whole block, in the product's voice,
    // with the door as its action — never eyebrow, headline, standfirst, chip
    // and movement as five stops down one page.
    .accessibilityElement(children: .contain)
    .accessibilityLabel(spoken)
  }

  private var spoken: String {
    var parts = [live ? "Live" : nil, item.eyebrow, item.headline, item.standfirst].compactMap { $0 }
    if let chip = HomeLeadChip.make(membership) {
      parts.append("You are \(CSCopy.ordinal(chip.rank)) of \(chip.of)")
      if let m = chip.move { parts.append(m.spokenPhrase) }
    }
    return parts.joined(separator: ". ")
  }
}

// MARK: - The chip

/// `2ND / ▲2 / OF EIGHT` — 84 × 90, radius `p` 3, no border and no shadow.
/// One figure, one movement mark, one unit label, and **never a sentence**
/// (`LINT-19`).
struct HomeLeadChip: View {
  let rank: Int
  let of: Int
  let move: CSMovement.State?

  /// The join, and the only place it happens.
  ///
  /// The LIVE table first; a season that has ended has no `standing` at all,
  /// and then the chip reads `last_season.my_rank` — which is the finish, and
  /// a finish never moves, so it carries no movement mark.
  static func make(_ m: Me.Membership?) -> HomeLeadChip? {
    if let s = m?.standing, s.rank > 0, s.of > 0 {
      return HomeLeadChip(rank: s.rank, of: s.of, move: movement(s))
    }
    if let last = m?.last_season, let r = last.my_rank, let of = last.of, r > 0, of > 0 {
      return HomeLeadChip(rank: r, of: of, move: nil)
    }
    return nil
  }

  /// **`▼` means exactly one thing: you fell.** A rank whose previous value is
  /// unknown has no mark at all — an unknown is not a "held", and drawing the
  /// bar for it would tell a golfer their position did not move on the one
  /// morning the client cannot say.
  static func movement(_ s: Me.Standing) -> CSMovement.State? {
    guard let prev = s.prev_rank, prev > 0 else { return nil }
    if prev == s.rank { return .held }
    return prev > s.rank ? .up(prev - s.rank) : .down(s.rank - prev)
  }

  var body: some View {
    CSPanel(unit: HomeWireCopy.chipUnit(of: of), width: 84, height: 90) {
      CSFigure("\(rank)", size: .l, label: nil,
               ordinal: String(CSCopy.ordinal(rank).dropFirst("\(rank)".count)), over: .panel)
      if let move { CSMovement(move, over: .panel) }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(CSCopy.ordinal(rank)) of \(of)"
                        + (move.map { ", \($0.spokenPhrase)" } ?? ""))
  }
}

extension CSMovement.State {
  /// §16.4 · every drawn indicator carries a written label, and the movement
  /// mark's is *"up two spots"* — never "triangle" and never "2".
  var spokenPhrase: String {
    switch self {
    case .up(let n): "up \(n) spot\(n == 1 ? "" : "s")"
    case .down(let n): "down \(n) spot\(n == 1 ? "" : "s")"
    case .held: "held"
    }
  }
}
