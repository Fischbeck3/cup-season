// Cup Season — THE TITLE CARD (UI_SYSTEM §15.5, surfaces/event.md §2 A).
//
// *The graphic that comes up before the coverage starts.* One full-bleed
// ceremony plate carrying the eyebrow, the title, the dateline and the whole
// field — running edge to edge and under the status bar, so it can never read
// as a box (§3.4). The ground is `ceremony` in BOTH printings: a title card is
// a physical object, and `event-light` is the proof that it is the same object
// in the morning room.
//
// WHAT IT REPLACES: `EventHeaderRow` — the event's name as a 12pt tracked-caps
// eyebrow with a gold status chip flush right, over a `CSCard` holding
// `A 6½ – 4½ B` in a border. Box inside box inside box, and the score of a live
// competition set smaller than the label above it.
//
// THE IMAGE LADDER HAS TWO RUNGS HERE AND ONLY TWO (§7.7). There is **no
// photograph on this surface, ever** — an event is not a place and the product
// has no picture of one. It is the contour, seeded from the event's course if
// it has one, or **nothing at all**. `event-callout` is the rendered proof that
// the bare ceremony ground is not a degraded state.

import SwiftUI
import CSDesign
import CupSeasonKit

struct EventTitleCard<Field: View>: View {
  /// `Live · week 2 of 3 · 2 days left` — the surface's whole LIVE signal, and
  /// where the countdown lives (§15.5a: a countdown is not a score).
  let eyebrow: String
  /// The 7pt dot rides the eyebrow while the clock is running and leaves with
  /// it. **No ember band** — §2.4 forbids a saturated field wider than a chip.
  let live: Bool
  /// `display` 34, wrapping to two lines. One `display` per viewport, and this
  /// is it. `nil` when the FIELD is the title — which is the callout, where the
  /// two golfers' names are the graphic.
  let title: String?
  /// One dateline, one or two lines, never three metadata blocks (§13 D-2).
  let dateline: [String]
  /// The contour's seed — the event's course. `nil` draws the bare ground.
  let seed: String?
  let back: (() -> Void)?
  @ViewBuilder let field: Field

  var body: some View {
    ZStack(alignment: .topLeading) {
      CSTokens.dark.ceremony
      if let seed {
        // §2 A.1 · six nested closed curves, cropped hard off their own
        // centre, with one `brand` dot on the hardest hole. Deterministic from
        // the course: same course, same plot, forever.
        CSContour(seed: seed, lineWidth: 1.2,
                  tint: CSTokens.dark.ceremonyMut.opacity(CSTokens.Alpha.a24),
                  mark: CSTokens.dark.ceremonyBrand)
          .allowsHitTesting(false)
      }
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        if let back {
          Button(action: back) {
            CSGlyph(.chevron, size: .tab)
              .scaleEffect(x: -1)
              .foregroundStyle(CSTokens.dark.ceremonyInk)
              .frame(width: 44, height: 44)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Back")
          .padding(.leading, -CSTokens.Space.s3)
        }
        HStack(spacing: CSTokens.Space.s1) {
          // **The dot IS the ember**, and it and its own eyebrow are ONE mark:
          // both are the same clock and the eyebrow names it.
          if live {
            Circle().fill(CSTokens.dark.ceremonyBrand).frame(width: 7, height: 7)
              .accessibilityHidden(true)
          }
          Text(eyebrow).csType(.agate, caps: true)
            .foregroundStyle(live ? CSTokens.dark.ceremonyBrand : CSTokens.dark.ceremonyMut)
            .fixedSize(horizontal: false, vertical: true)
        }
        if let title {
          Text(title).csType(.display).foregroundStyle(CSTokens.dark.ceremonyInk)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
        }
        // **DF-22 · EYEBROW → TITLE → DATELINE → ROSTER.** The dateline sat
        // BELOW the field, so a block of six faces separated the event's name
        // from its own subtitle and a reader had to jump the roster to learn
        // where and when it is played. `event-ryder-live.png` puts the
        // dateline directly under the title, where a subtitle goes.
        if !dateline.isEmpty {
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            ForEach(Array(dateline.enumerated()), id: \.offset) { _, line in
              Text(line).csType(.agate, caps: true).foregroundStyle(CSTokens.dark.ceremonyMut)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .accessibilityElement(children: .combine)
        }
        field
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      // the status-bar band: the chevron and the eyebrow clear the clock
      .padding(.top, back == nil ? CSTokens.Space.s4 : 54)
      .padding(.bottom, CSTokens.Space.s4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .fixedSize(horizontal: false, vertical: true)
    .clipped()
    // every token inside a ceremony ground resolves to its DARK value, in both
    // themes — the light theme does not reach inside a physical object (D-1)
    .csCeremony()
    .csBudget(display: title == nil ? 0 : 1, ember: live ? 1 : 0)
  }
}

extension EventTitleCard where Field == EmptyView {
  init(eyebrow: String, live: Bool, title: String?, dateline: [String],
       seed: String? = nil, back: (() -> Void)? = nil) {
    self.init(eyebrow: eyebrow, live: live, title: title, dateline: dateline,
              seed: seed, back: back, field: { EmptyView() })
  }
}

// MARK: - the callout's head

/// **The two golfers ARE the title** (§3): a 56pt face and `display` 34 for
/// you, a 2pt `brand` rule across the full measure, then the same pair for him.
/// The rule between the two names is the whole graphic — two names, one live
/// rule — and it goes to `ink` the moment the callout closes.
struct CalloutHead: View {
  let mine: CSFace.Model
  let myName: String
  let theirs: CSFace.Model
  let theirName: String
  let live: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      // **You are the top name.** §3's own order — "a 56pt face and `display`
      // 34 for you, a 2pt `brand` rule, then the same pair for him" — and the
      // reason is that the row a reader is IN leads on every surface in the
      // product, from the board's own `YOU` to the week's first clash.
      name(mine, myName)
      CSRule(.heavy, metal: live ? .live : .ink, over: .ceremony)
      name(theirs, theirName)
    }
    .padding(.vertical, CSTokens.Space.s2)
    // **Two names at `display` are ONE display object**, not two: the pair and
    // the rule between them are a single graphic, drawn once, and the budget
    // counts objects rather than `Text` views (§1.5).
    .csBudget(display: 1)
  }

  private func name(_ f: CSFace.Model, _ n: String) -> some View {
    HStack(spacing: CSTokens.Space.s3) {
      CSFace(f, size: .block)
      Text(n).csType(.display).foregroundStyle(CSTokens.dark.ceremonyInk)
        .lineLimit(2).minimumScaleFactor(0.7)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(n)
  }
}
