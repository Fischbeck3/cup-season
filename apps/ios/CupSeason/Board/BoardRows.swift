// Cup Season — the board's rows, one per web class.
//
//   .datesep  date separator      .annrow  from the Pro     .momrow  a moment
//   .sysrow   a clubhouse note    .msgrow  chat / compact round   .digest  since you were here
//
// WAVE 8 · **THE FOUR GRADIENT WASHES ARE GONE** (D277, non-negotiable 7). The
// Pro's word and every moment sat inside a rounded box filled with a
// gold-to-transparent and a brand-to-transparent ramp — the one image state
// D272 bans by name, arriving as decoration rather than as a picture, and
// spending a metal on every row of a scrolling feed while doing it. What
// carried the meaning was always the 3.5pt spine beside them; the spine stays,
// the box and the wash go, and the row sits on the page's own ground.
//
// The typed marks go with them: `📌`/`📣` (emoji, `LINT-12`), `✦`, `◆` and the
// `›` chevron (`LINT-13`) are drawn glyphs from the one family now.

import SwiftUI
import CSDesign
import CupSeasonKit

/// `.datesep` — agate, tracked, a rule either side.
struct DateSeparator: View {
  @Environment(\.cs) private var cs
  let label: String
  var body: some View {
    HStack(spacing: CSTokens.Space.s3) {
      Rectangle().fill(cs.rule).frame(height: CSTokens.Space.hair)
      Text(label).csType(.agateS, caps: true).foregroundStyle(cs.mut).fixedSize()
      Rectangle().fill(cs.rule).frame(height: CSTokens.Space.hair)
    }
    .padding(.top, CSTokens.Space.s4).padding(.bottom, CSTokens.Space.s3)
    .accessibilityElement(children: .combine)
  }
}

/// The spine every board row hangs off: 3pt, full height, and the only thing
/// that ever said which KIND of row this was.
private struct BoardSpine<Content: View>: View {
  let metal: Color
  var ground: Color? = nil
  @ViewBuilder let content: Content
  var body: some View {
    HStack(alignment: .top, spacing: CSTokens.Space.s3) {
      Rectangle().fill(metal).frame(width: 3)
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) { content }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, CSTokens.Space.s3)
        .padding(.trailing, CSTokens.Space.s3)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ground ?? Color.clear)
  }
}

/// `.annrow` — the Pro's word. The latest rides pinned, older ones inline.
struct AnnounceRow: View {
  @Environment(\.cs) private var cs
  let text: String
  let pinned: Bool
  var body: some View {
    BoardSpine(metal: cs.gold, ground: pinned ? cs.bg1 : nil) {
      Text("From the Pro").csType(.agate, caps: true).foregroundStyle(cs.gold)
        .accessibilityLabel(pinned ? "Pinned, from the Pro" : "From the Pro")
      Text(text).csType(.body).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
    .accessibilityElement(children: .combine)
    .padding(.vertical, CSTokens.Space.s1)
  }
}

/// `.momrow` — a moment (barrier, PB, streak, lead change).
/// D181: the bar rides inside the row, as it does on the web — a moment is not
/// a door, so there is nothing for a chip to be swallowed by.
struct MomentRow: View {
  @Environment(\.cs) private var cs
  let text: String
  var item: BoardItem? = nil
  var store: BoardStore? = nil
  var body: some View {
    BoardSpine(metal: cs.brand) {
      HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
        CSGlyph(.dot, size: .inline).foregroundStyle(cs.brand).accessibilityHidden(true)
        Text(text).csType(.body).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
      .accessibilityLabel("A moment: \(text)")
      if let item, let store, item.social { ReactionBar(item: item, store: store) }
    }
  }
}

/// `sysRowHtml` — a clubhouse note. A row with a live round is a door
/// (D92): a gold spine, a chevron, and it opens the scorecard.
struct SystemRow: View {
  @Environment(\.cs) private var cs
  let text: String
  var opens: (() -> Void)? = nil
  var item: BoardItem? = nil
  var store: BoardStore? = nil
  var body: some View {
    // D181 · the bar is a SIBLING of the row, never inside it: a settled-game
    // row is a Button, and chips nested in a Button open the scorecard on every
    // tap. The web keeps them apart with `.sysgrp` for the same reason.
    VStack(alignment: .leading, spacing: 0) {
      if let opens {
        Button(action: opens) {
          row.overlay(alignment: .trailing) {
            CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut)
              .padding(.trailing, CSTokens.Space.s3)
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(text) — open the scorecard")
      } else {
        row
      }
      if let item, let store, item.social {
        ReactionBar(item: item, store: store).padding(.leading, CSTokens.Space.s4).padding(.bottom, CSTokens.Space.s1)
      }
    }
  }

  /// A quiet note sits on ground with its spine; a door takes `bg1` and a
  /// 44pt target, because it is interactive.
  private var row: some View {
    BoardSpine(metal: opens == nil ? cs.gold.opacity(CSTokens.Alpha.a56) : cs.gold,
               ground: opens == nil ? nil : cs.bg1) {
      Text(text).csType(.bodyS).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(text)
    }
    .frame(minHeight: opens == nil ? 0 : 44)
  }
}

/// `.msgrow` — the squad-colour spine beside a text column. Chat carries the
/// name (+ the founder tag); a compact round line carries its eased body.
/// A row on ground, parted from the next by a rule (IOS-019 rule 2).
struct MessageRow<Content: View>: View {
  @Environment(\.cs) private var cs
  let ci: Int
  @ViewBuilder let content: Content
  var body: some View {
    HStack(alignment: .top, spacing: CSTokens.Space.s3) {
      Rectangle().fill(cs.squad(ci)).frame(width: 3)
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) { content }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, CSTokens.Space.s3)
    .overlay(alignment: .bottom) { CSRule() }
  }
}

struct ChatRow: View {
  @Environment(\.cs) private var cs
  let item: BoardItem
  let store: BoardStore
  let links: BoardLinks
  var body: some View {
    MessageRow(ci: item.ci) {
      HStack(spacing: CSTokens.Space.s2) {
        Button { if let p = item.profileId { links.openTourCard(p) } } label: {
          Text(item.who).csType(.name).foregroundStyle(cs.ink).a11yHitSlop()   // the name is a 44pt door
        }
        .buttonStyle(.plain)
        .disabled(item.profileId == nil)
        .accessibilityLabel(item.who)
        .accessibilityHint(item.profileId == nil ? "" : GolfersRoot.CardName.hint())
        if item.profileId != nil, item.profileId == store.founderId { FounderTag() }
      }
      Text(item.text).csType(.body).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      if item.social { ReactionBar(item: item, store: store) }
    }
  }
}

/// The compact board's round line: "the round line IS the reactable story".
struct CompactRoundRow: View {
  @Environment(\.cs) private var cs
  let item: BoardItem
  let store: BoardStore
  var body: some View {
    MessageRow(ci: item.ci) {
      Text(BoardText.easeCaps(item.text, names: store.names)).csType(.body).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      if item.social { ReactionBar(item: item, store: store) }
    }
  }
}

/// `.digest` — the quiet-day block (F13 3.3).
struct DigestCard: View {
  @Environment(\.cs) private var cs
  let lines: [String]
  var body: some View {
    BoardSpine(metal: cs.brand, ground: cs.bg1) {
      Text("Since you were here").csType(.agate, caps: true).foregroundStyle(cs.mut)
      ForEach(Array(lines.enumerated()), id: \.offset) { _, l in
        Text(l).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.top, CSTokens.Space.s1).padding(.bottom, CSTokens.Space.s3)
    .accessibilityElement(children: .combine)
  }
}

/// **Loading is the destination's own geometry, redacted** (§13.2) — the real
/// rows at their real heights, not three grey tiles that look like a different
/// screen. `.redacted(.placeholder)` blanks the type and leaves the structure.
struct BoardSkeleton: View {
  @Environment(\.cs) private var cs
  private static let sample = [
    ("Galen Marr", "Posted 82 at Papago — two better than his playing HCP."),
    ("Dev Anand", "In for Saturday. Anyone else?"),
    ("Tash", "Broke 90 for the first time."),
  ]
  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(Self.sample.enumerated()), id: \.offset) { i, s in
        MessageRow(ci: i) {
          Text(s.0).csType(.name).foregroundStyle(cs.ink)
          Text(s.1).csType(.body).foregroundStyle(cs.ink)
        }
      }
    }
    .csRedacted(true)
  }
}
