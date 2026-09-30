import SwiftUI
import WidgetKit
import CSDesign
#if !CS_WIDGET_EXTENSION
import CupSeasonKit
#endif

/// D400 · What's On — Home's own ranked cards on the home screen.
///
/// Every sentence here was written by `home_dispatch` and copied by
/// `BetweenRoundsCopy.whatsOn`; this view only lays them out (L-34). The
/// featured card turns every 20 minutes (`step`), from the snapshot in hand, so
/// the tile moves through the day even when nothing new has been read. Past
/// the 24-hour stale line it offers no verbs and every door is Home (L-44).
/// Shared with the DEBUG gallery so the review renders the real view.
struct WhatsOnWidgetView: View {
  @Environment(\.widgetFamily) private var systemFamily
  var previewFamily: WidgetFamily? = nil
  private var family: WidgetFamily { previewFamily ?? systemFamily }
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var contrast
  @Environment(\.dynamicTypeSize) private var typeSize
  let snapshot: BetweenRoundsSnapshot?
  let date: Date
  var step: Int = 0

  private var cs: CSPalette {
    let base = scheme == .light ? CSTokens.light : CSTokens.dark
    return contrast == .increased ? base.increasedContrast : base
  }
  private var stale: Bool { snapshot?.isStale(.whatsOn, at: date) ?? true }
  private var all: [BetweenRoundsSnapshot.WhatsOn.Item] { snapshot?.whatsOn?.value?.items ?? [] }
  /// The featured item first, then the rest in the ranker's order after it
  private var turned: [BetweenRoundsSnapshot.WhatsOn.Item] { snapshot?.whatsOn?.value?.rotated(step) ?? [] }
  private var ax: Bool { typeSize.isAccessibilitySize }
  private var home: URL { URL(string: "cupseason://home")! }

  var body: some View {
    Group {
      if family == .accessoryRectangular { accessory }
      else {
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          content
          Spacer(minLength: 0)
          if let snapshot {
            Text(ax ? snapshot.asOfShort(.whatsOn, at: date) : snapshot.asOf(.whatsOn, at: date))
              .csType(.agateS).foregroundStyle(cs.mut)
              .lineLimit(1).minimumScaleFactor(0.85)
          }
        }
        .padding(CSTokens.Space.s3)
        .foregroundStyle(cs.ink)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .containerBackground(cs.bg0, for: .widget)
    .widgetURL(door(turned.first))
    .privacySensitive()
  }

  private func door(_ item: BetweenRoundsSnapshot.WhatsOn.Item?) -> URL {
    guard let snapshot, !stale else { return home }
    return snapshot.link(for: item)
  }

  @ViewBuilder private var content: some View {
    if turned.isEmpty { empty }
    else {
      switch family {
      case .systemLarge: large
      case .systemMedium: medium
      default: small
      }
    }
  }

  // MARK: sizes

  private var small: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      head
      if let item = turned.first { card(item, lines: 3, role: .bodyS, inlineVerb: false) }
    }
  }

  private var medium: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      head
      if let item = turned.first { card(item, lines: 2, role: .story, inlineVerb: true) }
      // the next item in the turn, one line, its own door
      if !ax, let next = turned.dropFirst().first {
        Rectangle().fill(cs.rule).frame(height: CSTokens.Space.hair)
        row(next, lines: 1)
      }
    }
  }

  /// The large tile is the whole list in the ranker's order: nothing turns,
  /// because everything is already on it.
  private var large: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      head
      ForEach(Array(all.prefix(ax ? 3 : BetweenRoundsCopyLimit.value).enumerated()), id: \.element.id) { i, item in
        if i > 0 { Rectangle().fill(cs.rule).frame(height: CSTokens.Space.hair) }
        // the lead keeps Home's serif; the deck below it reads in the body face
        Link(destination: door(item)) { card(item, lines: 2, role: i == 0 ? .story : .bodyS, inlineVerb: true) }
      }
    }
  }

  // MARK: pieces

  private var head: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
      Text(BetweenRoundsKind.whatsOn.title).csType(.agate).textCase(.uppercase).lineLimit(1)
      Spacer(minLength: 0)
      // where the turn is: "2 of 4" (the large tile shows them all, and says so)
      if all.count > 1, family != .systemLarge {
        Text("\(turnIndex + 1) of \(all.count)").csType(.agateS).lineLimit(1)
          .accessibilityLabel("Item \(turnIndex + 1) of \(all.count)")
      }
    }
    .foregroundStyle(cs.mut)
  }
  private var turnIndex: Int { all.isEmpty ? 0 : ((step % all.count) + all.count) % all.count }

  /// One Home card: its spine, its eyebrow in the spine's colour, the
  /// headline, and the verb (never once the snapshot is stale).
  private func card(_ item: BetweenRoundsSnapshot.WhatsOn.Item, lines: Int, role: CSType.Role, inlineVerb: Bool) -> some View {
    let verb = stale ? nil : item.action.flatMap { $0.isEmpty ? nil : $0 }
    return HStack(alignment: .top, spacing: CSTokens.Space.s2) {
      Rectangle().fill(spine(item)).frame(width: 3.5)
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
          Text(item.eyebrow).csType(.agateS).textCase(.uppercase)
            .foregroundStyle(item.spine == "mut" ? cs.mut : spine(item)).lineLimit(1)
          if inlineVerb, let verb {
            Spacer(minLength: 0)
            Text(verb).csType(.agateS).foregroundStyle(cs.act).lineLimit(1)
          }
        }
        Text(item.headline).csType(role)
          .multilineTextAlignment(.leading)
          .lineLimit(lines).minimumScaleFactor(0.8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
        if !inlineVerb, let verb {
          Text(verb).csType(.agate).foregroundStyle(cs.act).lineLimit(1)
        }
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .accessibilityElement(children: .combine)
  }

  /// A following item on the medium tile: one line, its own door.
  private func row(_ item: BetweenRoundsSnapshot.WhatsOn.Item, lines: Int) -> some View {
    Link(destination: door(item)) {
      HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
        Circle().fill(spine(item)).frame(width: 5, height: 5).alignmentGuide(.firstTextBaseline) { $0[.bottom] }
        Text(item.headline).csType(.bodyS).lineLimit(lines)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel("\(item.eyebrow). \(item.headline)")
    }
  }

  private func spine(_ item: BetweenRoundsSnapshot.WhatsOn.Item) -> Color {
    switch item.spine {
    case "ember": cs.brand
    case "gold": cs.gold
    default: cs.rule
    }
  }

  /// L-32 · an empty state ends in a next move. "Catch up" is for a widget the
  /// app has never filled; a filled snapshot with nothing on it is a quiet day.
  private var empty: some View {
    let neverFilled = snapshot?.whatsOn == nil
    return VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      head
      Text(neverFilled ? "Open Cup Season to catch up." : "Quiet for now. The next round, clash or tee time lands here.")
        .csType(family == .systemSmall ? .bodyS : .story).multilineTextAlignment(.leading)
        .lineLimit(ax ? 3 : 4).minimumScaleFactor(0.85)
      Text(neverFilled ? "Open to refresh" : "Open Cup Season")
        .csType(.agate).foregroundStyle(cs.act)
    }
  }

  @ViewBuilder private var accessory: some View {
    VStack(alignment: .leading, spacing: 0) {
      if !stale, let item = turned.first {
        Text(item.eyebrow).font(.caption).lineLimit(1)
        Text(item.headline).font(ax ? .caption2 : .headline).lineLimit(ax ? 1 : 2).minimumScaleFactor(0.75)
      } else {
        Text(BetweenRoundsKind.whatsOn.title).font(.headline)
        Text("Open to refresh").font(.caption)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

/// The large tile's length, which is the producer's limit; spelled here so the
/// extension (which compiles the snapshot, not the Kit) does not reach for it.
enum BetweenRoundsCopyLimit { static let value = 5 }
