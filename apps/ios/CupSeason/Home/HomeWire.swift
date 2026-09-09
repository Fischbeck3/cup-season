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
//   3 · a ranked item         a 56pt row at `body` 17 in `ink` with its own
//                             clock — a clash, a standing, a plan; and a
//                             course discovery, the day a producer emits one
//   4 · a season moment       a full-bleed ceremony band, `ceremonyInk` in
//                             BOTH themes, because a ceremony is a physical
//                             object and does not re-print when the room does
//   5 · minor activity        one 44pt line at `bodyS` 15 in `mut`, its date
//                             stamped at the trailing edge
//
// Nothing differs in colour language, radius or container between them,
// **because there are no containers**. The rhythm is rule · type · photograph ·
// rule · quiet line, so scrolling reads as a rundown rather than a stack.
//
// D280 · AND THE OWNER READ THE SHIPPED WIRE AS A WALL OF TEXT, BECAUSE FOUR
// OF THE FIVE WEIGHTS HAD NO DATA AND THE FIFTH DREW EVERYTHING. Weights 2 and
// 4 need a photograph and a finished season; weight 3 has no producer at all
// (`BUILD_REPORT` §3). So a clash, a standing, a milestone and four `N league
// notes` counts all rendered as weight 5, ten deep, each behind a 34pt date
// column. The three answers are here and in `HomePage`: the wire runs under
// **datelines** with a real size step, the ranked items take **weight 3**, and
// every league note on the page folds into **one** line at the foot.

import SwiftUI
import CSDesign
import CupSeasonKit

// MARK: - The section head

/// Home's own **block name** — `agate` at `mut` with a 1px rule running to the
/// margin. Home draws this one rather than taking `CSSectionHead(.label)`,
/// which still sets its title through `csEyebrow` and the old tracked-mono
/// voice; that component belongs to every other surface until Wave 8 migrates
/// it, and changing it here would restyle nine screens that have not had their
/// wave yet.
///
/// **THE HEAVY HEAD IS NOT HERE.** The wire's dateline and Compete's YOUR
/// SEASONS are the same object — `CSSectionHead(…, weight: .display)` — and
/// it lives in `CSDesign` because there is ONE section-head idiom in the
/// product and the surface that proves it is the second one to use it (D286).
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
          // **THE RULE IS THE WIDTH OF ITS COLUMN** (§0.2), and without this it
          // was the width of half the page: `CSRule` is a bare `Rectangle`, so
          // the figure's stack reads as FLEXIBLE inside an `HStack` and took
          // an equal share — which left "89 at UNM Championship — 1.4 over your
          // playing HCP." breaking over four lines beside a 2pt rule running to
          // the margin. `fixedSize` proposes the column its own ideal width,
          // which is the label's, and hands the rest back to the sentence.
          CSFigure("\(g)", size: .m, label: "Gross")
            .fixedSize(horizontal: true, vertical: false)
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

/// The reaction line under a round — the tokens GIVEN with their counts, a
/// `+` that reveals the rest, and the day flush right.
///
/// **THE ROW IS QUIET UNTIL SOMEBODY SPEAKS (D310, amended).** D310 removed the
/// tray on the argument that four fit on the row, and on the BOARD that is
/// right — a board is a room you went to. On Home's wire it is not: the owner,
/// looking at four tokens under every round in `THIS WEEK` and `EARLIER`,
/// *"maybe hide emojis under a plus."* A feed is scanned, and four marks under
/// every row is four times the furniture for the same one thumb.
///
/// So the wire shows **what has actually happened** — nothing, or the tokens
/// people gave — and a `+` opens the four inline. The board keeps all four on
/// the face. That is a surface rule and not a reversal: what D310 removed was
/// the pre-loaded quick chip that read as a reaction somebody had left, and
/// nothing here brings it back. An untouched round shows a `+` and no tally.
///
/// The reveal is LOCAL STATE and not the store's: the tray D310 deleted was
/// exclusive across the whole board and needed a shared flag, four close paths
/// and a capture/restore pass. One row opening its own four needs none of that.
struct HomeWireReactions: View {
  @Environment(\.cs) private var cs
  let state: [String: ReactionState]
  let day: String?
  let onToggle: (String) -> Void
  @State private var open = false

  /// The tokens somebody has actually given, in CANON order — never arrival
  /// order, so the row is the same row every time you look at it.
  private var given: [CSReactions.Reaction] {
    CSReactions.all.filter { (state[$0.key]?.n ?? 0) > 0 }
  }
  /// What the `+` reveals: everything not already on the row.
  private var rest: [CSReactions.Reaction] {
    CSReactions.all.filter { (state[$0.key]?.n ?? 0) == 0 }
  }

  var body: some View {
    HStack(spacing: CSTokens.Space.s4) {
      ForEach(given) { rx in chip(rx, mine: state[rx.key]?.me == true, n: state[rx.key]?.n ?? 0) }
      if open {
        // **THE REVEAL IS FOR ONE CHOICE, THEN IT CLOSES.** The owner, on the
        // first build of this: *"When I click + for emotes they reappear lets
        // keep them hidden with exception to when one is selected."* Left
        // open, the row silently becomes the four-token row the `+` was added
        // to remove — and it stays that way for the rest of the session. So
        // picking one collapses the row back to what is GIVEN plus the `+`,
        // and his own worked example is the result: give the azalea, and the
        // next person sees a `+` and an azalea — open the `+` for a different
        // one, or tap the azalea to add to it.
        ForEach(rest) { rx in chip(rx, mine: false, n: 0, closesOnTap: true) }
      } else if !rest.isEmpty {
        Button {
          CSHaptic.selection()
          CSMotion.run(CSMotion.tick) { open = true }
        } label: {
          CSGlyph(.plus, size: .inline)
            .foregroundStyle(cs.mut)
            .frame(minHeight: 34)
            .a11yHitSlop(vertical: 5, horizontal: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(given.isEmpty ? "React to this round" : "More reactions")
        // VoiceOver never has to open anything: the four are actions here.
        .accessibilityActions {
          ForEach(rest) { rx in Button(rx.label) { onToggle(rx.key) } }
        }
      }
      Spacer(minLength: CSTokens.Space.s2)
      if let day {
        Text(day).csType(.agateS, caps: true).foregroundStyle(cs.mut).accessibilityHidden(true)
      }
    }
    .frame(minHeight: 34)
  }

  /// A figure is drawn only where there IS one (D310) — a glyph with a phantom
  /// zero beside it reads as a reaction somebody left.
  private func chip(_ rx: CSReactions.Reaction, mine: Bool, n: Int,
                    closesOnTap: Bool = false) -> some View {
    Button {
      CSHaptic.selection()
      onToggle(rx.key)
      if closesOnTap { CSMotion.run(CSMotion.tick) { open = false } }
    } label: {
      HStack(spacing: CSTokens.Space.s2) {
        CSReactionGlyph(rx.token, size: .row)
          .foregroundStyle(mine ? cs.ink : cs.mut)
        if n > 0 {
          Text("\(n)").csType(.agateS, caps: true).foregroundStyle(mine ? cs.ink : cs.mut)
        }
      }
      .frame(minHeight: 34)
      .a11yHitSlop(vertical: 5, horizontal: 6)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(rx.label), \(n)\(mine ? ", yours" : "")")
    .accessibilityValue(mine ? "on" : "off")
    .accessibilityAddTraits(.isToggle)
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

// MARK: - Weight 3 · a ranked competition item

/// **THE RANKER PUT THIS ABOVE EVERY BOARD NOTE; THE PAGE HAS TO SAY SO.**
/// A clash that is open, a standing that has moved, a plan on the books — the
/// shipped wire drew all three at `bodyS` 15 `mut` behind a 34pt date column,
/// which is the same object it drew *"Fellas · 4 earlier league notes"* with.
/// Ten rows of one weight is the wall the owner photographed.
///
/// So it takes the page's reading size in `ink` — `body` 17, one step up and
/// one contrast step brighter than the quiet line beneath it — and its stamp
/// is a **clock** rather than a date, because a clash that closes in six days
/// has a clock and "Sun" is not one.
///
/// **IT DOES NOT WEAR EMBER.** §2.4 gives the live metal exactly two seats per
/// viewport and the lead already holds both (its dot and its door). A live
/// thing on the wire reads as live through its clock and its weight, which is
/// how a printed board does it and costs the page no metal.
struct HomeWireItem: View {
  @Environment(\.cs) private var cs
  let headline: String
  let stamp: String?
  let act: (() -> Void)?

  var body: some View {
    if let act {
      Button(action: act) { row.contentShape(Rectangle()) }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([headline, stamp].compactMap { $0 }.joined(separator: ". "))
    } else {
      row.accessibilityElement(children: .combine)
    }
  }

  private var row: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
      Text(headline).csType(.body).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
      if let stamp {
        Text(stamp).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          .fixedSize(horizontal: true, vertical: false)
      }
      if act != nil {
        CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut)
          .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 3 }
      }
    }
    .padding(.vertical, CSTokens.Space.s3)
    .frame(minHeight: 56)
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

/// One 44pt line: the sentence in `bodyS` `mut`, its date as a stamp at the
/// **trailing** edge, and a drawn chevron **only when the line knows where it
/// goes** (D219). A line that knows nothing is a note — plain text, no glyph
/// disc, no chevron, never a dimmed button.
///
/// **THE DATE CAME OUT OF THE LEFT COLUMN, AND THAT IS HALF OF WHY THE WIRE
/// STOPPED READING AS A TABLE** (D280). A 34pt leading column of `Sun Sun Sun
/// Aug 31 Aug 31` in front of every sentence is a database's date field, and
/// it pushed every headline off the margin the masthead, the lead, the ME
/// strip and the floor all align to. With the stamp trailing, the wire is a
/// column of sentences that starts where the page starts; the dateline head
/// above carries the period, and a row prints its own date only where it adds
/// something the head did not say.
///
/// The stamp is `mut` and never `dim`: `dim` is 3.15 / 2.89 and may not carry
/// a word (§16.1). Its quietness comes from size and from the row's own rule.
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
        .accessibilityLabel([text, marker].compactMap { $0 }.joined(separator: ". "))
    } else {
      line.accessibilityElement(children: .combine)
    }
  }

  private var line: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
      Text(text).csType(.bodyS).foregroundStyle(ink ?? cs.mut)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
      if let marker {
        Text(marker).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          .fixedSize(horizontal: true, vertical: false)
      }
      if act != nil {
        CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut)
          .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 3 }
      }
    }
    .padding(.vertical, CSTokens.Space.s3)
    .frame(minHeight: 44)
  }
}

// MARK: - Weight 3b · a bag change, as an object

/// **A CARD, BECAUSE A BAG IS A THING AND NOT AN ASIDE** (D312, amended).
///
/// The owner, on the line this replaces: *"I think we need a card so this isnt
/// just a line of text."* He is right and the reason is structural rather than
/// decorative — every other quiet line on the wire reports something that
/// happened somewhere else (a league note, a milestone, a standing that moved).
/// A bag change is the only row on Home whose door opens a **place you can go
/// and look at**, and a row that leads somewhere should not be set in the same
/// type as a row that does not.
///
/// It is a ruled block and **not a filled tile**: §32 is structure without
/// containers, and D278 deleted the product's last washes. What makes it a card
/// is the drawn object, the reading size and its own edges — not a fill.
struct HomeWireBag: View {
  @Environment(\.cs) private var cs
  let text: String
  let marker: String?
  let act: (() -> Void)?

  var body: some View {
    Button { act?() } label: {
      VStack(alignment: .leading, spacing: 0) {
        CSRule()
        HStack(alignment: .top, spacing: CSTokens.Space.s3) {
          // The bag's own glyph, in the look's accent where one is on — the
          // object announcing itself before the sentence does.
          CSGlyph(.bag, size: .block)
            .foregroundStyle(cs.brand)
            .padding(.top, 2)
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            Text(text).csType(.body).foregroundStyle(cs.ink)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: CSTokens.Space.s2) {
              Text("See the bag").csEyebrow(cs.mut)
              if let marker {
                Spacer(minLength: CSTokens.Space.s2)
                Text(marker).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              }
            }
          }
        }
        .padding(.vertical, CSTokens.Space.s4)
        CSRule()
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(act == nil)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(text)
    .accessibilityHint(act == nil ? "" : "Opens the bag")
  }
}
