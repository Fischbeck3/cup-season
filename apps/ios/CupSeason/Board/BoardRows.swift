// Cup Season — the board's rows, one per web class.
//
//   .datesep  date separator      .annrow  📌/📣 FROM THE PRO     .momrow  ✦ moment
//   .sysrow   ◆ league notice     .msgrow  chat / compact round   .digest  SINCE YOU WERE HERE

import SwiftUI
import CSDesign
import CupSeasonKit

/// `.datesep` — mono, tracked, a hairline either side.
struct DateSeparator: View {
  @Environment(\.cs) private var cs
  let label: String
  var body: some View {
    HStack(spacing: 12) {
      Rectangle().fill(cs.line).frame(height: 1)
      Text(label).font(CSFont.label).tracking(2).textCase(.uppercase).foregroundStyle(cs.dimText).fixedSize()
      Rectangle().fill(cs.line).frame(height: 1)
    }
    .padding(.top, 18).padding(.bottom, 10)
    .accessibilityElement(children: .combine)
  }
}

/// `.annrow` — the Pro's word. The latest rides pinned ("📌"), older ones inline ("📣").
struct AnnounceRow: View {
  @Environment(\.cs) private var cs
  let text: String
  let pinned: Bool
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(pinned ? "📌 FROM THE PRO" : "📣 FROM THE PRO").font(CSFont.label).tracking(1.5).foregroundStyle(cs.gold)
      Text(text).font(CSFont.subhead).foregroundStyle(cs.ink)
    }
    .padding(.horizontal, 14).padding(.vertical, 11)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(LinearGradient(colors: [cs.gold.opacity(0.10), cs.gold.opacity(0.02)], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .background(pinned ? cs.bg1 : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(cs.gold.opacity(0.35), lineWidth: 1))
    .padding(.vertical, pinned ? 0 : 2)
  }
}

/// `.momrow` — "✦ …" a moment (barrier, PB, streak, lead change).
struct MomentRow: View {
  @Environment(\.cs) private var cs
  let text: String
  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text("✦").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.brand)
      Text(text).font(CSFont.subhead).foregroundStyle(cs.ink)
    }
    .padding(.horizontal, 13).padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(LinearGradient(colors: [cs.brand.opacity(0.10), cs.brand.opacity(0.03)], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(cs.brand.opacity(0.32), lineWidth: 1))
    .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(cs.brand).frame(width: 3).padding(.vertical, 6) }
  }
}

/// `sysRowHtml` — "◆ …" a clubhouse note. A row with a live round is a door
/// (D92): gold spine, a chevron, and it opens the scorecard.
struct SystemRow: View {
  @Environment(\.cs) private var cs
  let text: String
  var opens: (() -> Void)? = nil
  var body: some View {
    Group {
      if let opens {
        Button(action: opens) { row.padding(.trailing, 22).overlay(alignment: .trailing) {
          Text("›").font(.system(size: 17)).foregroundStyle(cs.gold).padding(.trailing, 14)
        } }
        .buttonStyle(.plain)
        .accessibilityLabel("\(text) — open the scorecard")
      } else {
        row
      }
    }
  }
  private var row: some View {
    Text("◆ " + text).font(CSFont.subhead).foregroundStyle(cs.mut)
      .padding(.horizontal, 13).padding(.vertical, 10)
      .frame(maxWidth: .infinity, minHeight: opens == nil ? 0 : 44, alignment: .leading)
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(cs.line, lineWidth: 1))
      .overlay(alignment: .leading) {
        RoundedRectangle(cornerRadius: 2).fill(opens == nil ? cs.gold.opacity(0.5) : cs.gold).frame(width: 3).padding(.vertical, 6)
      }
  }
}

/// `.msgrow` — the squad-colour bar beside a text column. Chat carries the
/// name (+ the founder tag); a compact round line carries its eased body.
struct MessageRow<Content: View>: View {
  @Environment(\.cs) private var cs
  let ci: Int
  @ViewBuilder let content: Content
  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      RoundedRectangle(cornerRadius: 2).fill(cs.squad(ci)).frame(width: 3.5)
      VStack(alignment: .leading, spacing: 4) { content }.frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 13).padding(.vertical, 11)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(cs.line, lineWidth: 1))
  }
}

struct ChatRow: View {
  @Environment(\.cs) private var cs
  let item: BoardItem
  let store: BoardStore
  let links: BoardLinks
  var body: some View {
    MessageRow(ci: item.ci) {
      HStack(spacing: 6) {
        Button { if let p = item.profileId { links.openTourCard(p) } } label: {
          Text(item.who).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        }
        .buttonStyle(.plain)
        .disabled(item.profileId == nil)
        if item.profileId != nil, item.profileId == store.founderId { FounderTag() }
      }
      Text(item.text).font(CSFont.subhead).foregroundStyle(cs.ink).lineSpacing(3)
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
      Text(BoardText.easeCaps(item.text, names: store.names)).font(CSFont.subhead).foregroundStyle(cs.ink).lineSpacing(3)
      if item.social { ReactionBar(item: item, store: store) }
    }
  }
}

/// `.digest` — the quiet-day card (F13 3.3).
struct DigestCard: View {
  @Environment(\.cs) private var cs
  let lines: [String]
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("SINCE YOU WERE HERE").font(CSFont.label).tracking(1).foregroundStyle(cs.mut.opacity(0.7))
      ForEach(Array(lines.enumerated()), id: \.offset) { _, l in
        Text(l).font(CSFont.subhead).foregroundStyle(cs.mut)
      }
    }
    .padding(.horizontal, 13).padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(cs.line, lineWidth: 1))
    .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(cs.brand).frame(width: 3).padding(.vertical, 6) }
    .padding(.bottom, 10)
    .accessibilityElement(children: .combine)
  }
}

/// Redacted placeholders in the final shape — never a spinner in content.
struct BoardSkeleton: View {
  @Environment(\.cs) private var cs
  var body: some View {
    VStack(spacing: 8) {
      ForEach(0..<3, id: \.self) { i in
        HStack(alignment: .top, spacing: 10) {
          Circle().fill(cs.bg2).frame(width: 26, height: 26)
          VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4).fill(cs.bg2).frame(height: 11).frame(maxWidth: CGFloat(220 - i * 40))
            RoundedRectangle(cornerRadius: 4).fill(cs.bg2).frame(width: 120, height: 9)
          }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cs.bg1, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
    }
    .accessibilityHidden(true)
  }
}
