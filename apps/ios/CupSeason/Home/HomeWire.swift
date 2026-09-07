// Cup Season — THE WIRE, and its five weights (IOS-046, `surfaces/home.md` §1.4).
//
// **The wave is one sentence: do not make every feed item visually equal.**
// The audit's finding is that ceremony night and a brand-new account render as
// the same card with a different eyebrow word, and four `N league notes` rows
// with chevrons are a database's GROUP BY drawn as a feed.
//
// So five weights, and what differs between them is **how much of the page an
// item is allowed to take** and **what kind of object leads it**:
//
//   1 · a competition moment  a serif sentence with a bone chip — THE LEAD,
//                             and it is `HomeLead`, not this file
//   2 · a friend's round      a full-bleed photograph, a 38pt face, a gross
//                             panel — or, with no photograph, a 68pt slat with
//                             a right-flush rule-and-figure
//   3 · a course discovery    a 68–84pt slat led by a thumbnail and a rating
//   4 · a season moment       a full-bleed ceremony band, `ceremonyInk` in
//                             BOTH themes, because a ceremony is a physical
//                             object and does not re-print when the room does
//   5 · minor activity        one 44pt line with a day marker
//
// Nothing differs in colour language, radius or container between them,
// **because there are no containers**. The rhythm is rule · type · photograph ·
// rule · quiet line, so scrolling reads as a rundown rather than a stack.

import SwiftUI
import CSDesign
import CupSeasonKit

// MARK: - The section head

/// `THE WIRE` — agate at `mut` with a 1px rule running to the margin.
///
/// Home draws its own rather than taking `CSSectionHead`, which still sets its
/// title through `csEyebrow` and the old tracked-mono voice; that component
/// belongs to every other surface until Wave 8 migrates it, and changing it
/// here would restyle nine screens that have not had their wave yet.
struct HomeSectionRule: View {
  @Environment(\.cs) private var cs
  let title: String
  init(_ title: String) { self.title = title }
  var body: some View {
    HStack(alignment: .center, spacing: CSTokens.Space.s3) {
      Text(title).csType(.agate, caps: true).foregroundStyle(cs.mut)
        .fixedSize()
        .accessibilityAddTraits(.isHeader)
      CSRule()
    }
  }
}

// MARK: - Weight 2 · a friend's round, with a photograph

/// A full-bleed 2.1:1 band. The face leads it, the sentence sets over the
/// scrim's own leading anchor, and the gross sits in the **bone** panel in both
/// themes — a photograph carries its own dusk, and the light theme's ink panel
/// would vanish into it.
struct HomeWireBand: View {
  @Environment(\.cs) private var cs
  let row: HomeFeedRow
  let photo: URL
  let open: () -> Void
  let openPerson: () -> Void

  private var name: String { HomeCopy.who(row) }
  private var line: String { HomeWireCopy.roundLine(row) }

  var body: some View {
    Button(action: open) {
      ZStack(alignment: .bottomLeading) {
        AsyncImage(url: photo) { $0.resizable().scaledToFill() } placeholder: { CSTokens.dark.bg1 }
          .frame(maxWidth: .infinity)
          .frame(height: 168)
          .clipped()
        // the two named geometries, used as named: `.band` for the copy at the
        // leading edge, `.top` for the credit riding the head of the picture
        CSPhotoScrim.layer(CSPhotoScrim.band, leading: true)
        CSPhotoScrim.layer(CSPhotoScrim.top).frame(height: CSPhotoScrim.topHeight)
          .frame(maxHeight: .infinity, alignment: .top)
        VStack(alignment: .trailing) {
          Text(HomeWireCopy.photoCredit(row)).csType(.agateS, caps: true)
            // §10.3's sixth conflict: `.top` reaches only a72, so a caption
            // under it takes `scrimInk` and not `scrimMut`.
            .foregroundStyle(CSPhotoScrim.ink(CSPhotoScrim.top, caption: true))
          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(CSTokens.Space.s3)
        HStack(alignment: .bottom, spacing: CSTokens.Space.s3) {
          CSFace(.init(id: row.profile_id ?? UUID(), marker: row.marker), size: .list, name: name)
            .onTapGesture { openPerson() }
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            // §1.3 · a person in a wire row is never caps.
            Text(name).csType(.social).foregroundStyle(CSTokens.dark.scrimInk)
              .lineLimit(1).truncationMode(.tail)
            Text(line).csType(.bodyS).foregroundStyle(CSTokens.dark.scrimInk)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          if let g = row.gross {
            CSPanel(.overPhoto, unit: "Gross", width: 60, height: 60) {
              Text("\(g)").csType(.figureM)
            }
          }
        }
        .padding(.horizontal, CSTokens.Space.gutter)
        .padding(.bottom, CSTokens.Space.s3)
      }
      .frame(maxWidth: .infinity)
      .clipped()
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(name). \(line)")
    .accessibilityHint("Opens the round")
  }
}

/// **Weight 2 with no photograph — the majority case today, and it must be
/// beautiful.** A 68pt slat on the page's own ground: the face, the name, the
/// sentence, and the gross as a right-flush rule-and-figure. No placeholder
/// image, no gradient wash, no tinted block — *a wash standing in for a
/// photograph is forbidden outright* (§10.1).
struct HomeWireSlat: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let row: HomeFeedRow
  let open: () -> Void
  let openPerson: () -> Void

  private var name: String { HomeCopy.who(row) }
  private var line: String { HomeWireCopy.roundLine(row) }

  var body: some View {
    Button(action: open) {
      A11yStack(alignment: .leading, spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s3) {
        HStack(spacing: CSTokens.Space.s3) {
          CSFace(.init(id: row.profile_id ?? UUID(), marker: row.marker), size: .list, name: name)
            .onTapGesture { openPerson() }
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            Text(name).csType(.social).foregroundStyle(cs.ink)
              .lineLimit(1).truncationMode(.tail)
            Text(line).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let g = row.gross {
          CSFigure("\(g)", size: .m, label: "Gross")
            .frame(minWidth: 62, alignment: typeSize.isA11y ? .leading : .trailing)
        }
      }
      .padding(.vertical, CSTokens.Space.s3)
      .frame(minHeight: 68)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(name). \(line)")
    .accessibilityHint("Opens the round")
  }
}

/// The reaction line under a round — 34pt, the used reactions with their
/// counts, the day flush right. **Emoji appear here and nowhere else on Home**
/// (§5.3), and the count beside each is set in the system's own agate rather
/// than in mono, so the emoji is the only foreign object on the screen.
struct HomeWireReactions: View {
  @Environment(\.cs) private var cs
  let state: [String: ReactionState]
  let day: String?
  let onToggle: (String) -> Void

  /// The reactions PRESENT, plus the bare heater when nobody has fired yet —
  /// F11 3.1: the one-thumb chip is always on the row, and never a lone `+`.
  private var shown: [CSReactions.Reaction] {
    let used = CSReactions.all.filter { (state[$0.emoji]?.n ?? 0) > 0 }
    if !used.isEmpty { return used }
    return CSReactions.all.filter { $0.emoji == CSReactions.quick }
  }

  var body: some View {
    HStack(spacing: CSTokens.Space.s4) {
      ForEach(shown) { rx in
        let st = state[rx.emoji] ?? ReactionState()
        Button { CSHaptic.selection(); onToggle(rx.emoji) } label: {
          HStack(spacing: CSTokens.Space.s2) {
            Text(rx.emoji).csType(.bodyS)
            if st.n > 0 {
              Text("\(st.n)").csType(.agateS, caps: true).foregroundStyle(st.me ? cs.ink : cs.mut)
            }
          }
          .frame(minHeight: 34)
          .a11yHitSlop(vertical: 5, horizontal: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(rx.label), \(st.n)\(st.me ? ", yours" : "")")
        .accessibilityValue(st.me ? "on" : "off")
        .accessibilityAddTraits(.isToggle)
      }
      Spacer(minLength: CSTokens.Space.s2)
      if let day {
        Text(day).csType(.agateS, caps: true).foregroundStyle(cs.mut).accessibilityHidden(true)
      }
    }
    .frame(minHeight: 34)
  }
}

// MARK: - Weight 3 · a course discovery

/// A 68–84pt editorial slat: a drawn thumbnail, the course in `name` caps, an
/// agate sub-line, and the rating as a figure and a star rail — **in `ink`,
/// never gold, because an average of opinions is not earned** (§2.4).
///
/// **NOTHING EMITS ONE YET.** `home_dispatch` has no `course` kind and the
/// product has no ratings table at all (`home.md` §5.1, §5.2). The spec's
/// DEGRADE is explicit — *with no such item, weight 3 does not render and Home
/// runs on four weights* — so this is the shape the day the producer lands,
/// and it is drawn from a struct rather than invented from a feed row, because
/// a course discovery composed on the client would be the client inventing a
/// fact (L-44).
struct HomeCourseDiscovery: Identifiable, Equatable {
  let id: String
  let name: String
  let sub: String
  /// nil = `NOT RATED`, beside a full-size unfilled rail (§9.11).
  let rating: Double?
  let ratingCount: Int
}

struct HomeWireCourse: View {
  @Environment(\.cs) private var cs
  let item: HomeCourseDiscovery
  let open: () -> Void
  var thumbnail: URL?

  var body: some View {
    Button(action: open) {
      HStack(spacing: CSTokens.Space.s3) {
        // §10.2 · a course with neither a card nor a photo shows NO thumbnail
        // at all — the column collapses and the name sets flush to the margin.
        if let thumbnail {
          AsyncImage(url: thumbnail) { $0.resizable().scaledToFill() } placeholder: { cs.bg1 }
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
        }
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          Text(item.name).csType(.name).foregroundStyle(cs.ink)
            .lineLimit(1).truncationMode(.tail)
          Text(item.sub).csType(.agateS, caps: false).foregroundStyle(cs.mut)
            .lineLimit(1).truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        VStack(alignment: .trailing, spacing: CSTokens.Space.s1) {
          if let r = item.rating {
            Text(String(format: "%.1f", r)).csType(.figureS).foregroundStyle(cs.ink)
            CSStarRail(r, size: 14)
          } else {
            Text("Not rated").csType(.agateS, caps: true).foregroundStyle(cs.mut)
            CSStarRail(0, size: 14)
          }
        }
      }
      .padding(.vertical, CSTokens.Space.s3)
      .frame(minHeight: 68)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(item.rating.map { "\(item.name), rated \(String(format: "%.1f", $0)). \(item.sub)" }
                        ?? "\(item.name), not rated. \(item.sub)")
  }
}

// MARK: - Weight 4 · the season moment

/// The takeover band — the biggest static object on Home, and it belongs to
/// the biggest moment: a Cup Final opening, a season wrapping. Full bleed on
/// the `ceremony` ground with `ceremonyInk` type **in both themes**, because a
/// ceremony is a physical object and does not change colour when the room
/// does. **Never more than one per viewport.**
///
/// DEGRADE, and it is named rather than faked: §1.4 draws the course contour
/// behind it at `a24` with one `brand` dot on the hardest hole. The contour
/// plate is `D272` rung 3 and Wave 4's work; there is no renderer for it yet,
/// so the band is the ground and the words, and **a gradient wash is not one
/// of the three legal images** and may not stand in for it.
struct HomeWireTakeover: View {
  let item: HomeDispatch.Item
  let open: () -> Void

  var body: some View {
    Button(action: open) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        Text(item.eyebrow).csType(.agate, caps: true)
          .foregroundStyle(CSTokens.dark.ceremonyBrand)
          .lineLimit(2)
        Text(item.headline).csType(.display)
          .foregroundStyle(CSTokens.dark.ceremonyInk)
          .fixedSize(horizontal: false, vertical: true)
        if let s = item.standfirst, !s.isEmpty {
          Text(s).csType(.agateS, caps: false)
            .foregroundStyle(CSTokens.dark.ceremonyMut)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.vertical, CSTokens.Space.s4)
      .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
      .background(CSTokens.dark.ceremony)
      .csCeremony()
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel([item.eyebrow, item.headline, item.standfirst].compactMap { $0 }.joined(separator: ". "))
  }
}

// MARK: - Weight 5 · minor activity

/// One 44pt line: a day marker in `agateS` `mut`, the sentence in `bodyS`
/// `mut`, and a drawn chevron **only when the line knows where it goes**
/// (D219). A line that knows nothing is a note — plain text, no glyph disc, no
/// chevron, never a dimmed button.
///
/// The marker is `mut` and never `dim`: `dim` is 3.15 / 2.89 and may not carry
/// a word (§16.1). Its quietness comes from size, from column position and
/// from the row's own rule.
struct HomeWireLine: View {
  @Environment(\.cs) private var cs
  let marker: String?
  let text: String
  let ink: Color?
  let act: (() -> Void)?

  init(marker: String?, text: String, ink: Color? = nil, act: (() -> Void)? = nil) {
    self.marker = marker; self.text = text; self.ink = ink; self.act = act
  }

  var body: some View {
    if let act {
      Button(action: act) { line.contentShape(Rectangle()) }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([marker, text].compactMap { $0 }.joined(separator: ". "))
    } else {
      line.accessibilityElement(children: .combine)
    }
  }

  private var line: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
      if let marker {
        Text(marker).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          .frame(width: 34, alignment: .leading)
          .fixedSize(horizontal: true, vertical: false)
      }
      Text(text).csType(.bodyS).foregroundStyle(ink ?? cs.mut)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
      if act != nil {
        CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut)
          .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 3 }
      }
    }
    .padding(.vertical, CSTokens.Space.s3)
    .frame(minHeight: 44)
  }
}
