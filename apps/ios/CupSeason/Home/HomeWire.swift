// Cup Season — Home round records. Identity, course and result share the
// full measure; an optional photograph sits below rather than squeezing facts.
// The remaining story weights, reactions, and earned ceremonies keep their jobs.

import SwiftUI
#if DEBUG
import UIKit
#endif
import CSDesign
import CupSeasonKit

// MARK: - The section head

/// Home landmarks stay quiet beside the people and photographs they file.
struct HomeSectionRule: View {
  let title: String
  init(_ title: String) { self.title = title }
  var body: some View { CSSectionHead(title, weight: .label) }
}

// MARK: - Weight 2 · the programme round, with an optional photograph

struct HomeWireBand: View {
  let row: HomeFeedRow
  let photo: URL?
  var photos: HomePhotoStore = .shared
  var denied = false
  var showDay = true
  var holes: Int? = nil
  let open: () -> Void
  let openPerson: () -> Void
  private var credential: HomePhotoStore.Credential {
    if let photo { return .url(photo) }
    return denied ? .denied : .unavailable
  }
  @ViewBuilder var body: some View {
    #if DEBUG
    if let photo, photo.isFileURL, let image = UIImage(contentsOfFile: photo.path) {
      record(Image(uiImage: image))
    } else { cachedRecord }
    #else
    cachedRecord
    #endif
  }
  private var cachedRecord: some View {
    // Keep D361's last good image through expired credentials/transient misses.
    // Until a picture exists, the complete programme record owns the space.
    record(photos.state(for: row.photo_path).image.map { Image(uiImage: $0) })
      .task(id: credential) { photos.load(path: row.photo_path, credential: credential) }
  }
  private func record(_ image: Image?) -> some View {
    HomeProgrammeRound(row: row, photo: image, showDay: showDay, holes: holes,
                       open: open, openPerson: openPerson)
  }
  #if DEBUG
  // Existing visual probes inject a loaded picture through this entry point.
  func band(_ image: Image) -> some View { record(image) }
  #endif
}

struct HomeWireSlat: View {
  let row: HomeFeedRow
  var showDay = true
  let open: () -> Void
  let openPerson: () -> Void
  var points: Int? = nil
  var monthRank: Int? = nil
  var cap: Int? = nil
  var holes: Int? = nil
  var body: some View {
    HomeProgrammeRound(row: row, showDay: showDay, holes: holes,
                       points: points, monthRank: monthRank, cap: cap,
                       open: open, openPerson: openPerson)
  }
}

/// Full-measure facts, with optional imagery below. Golfer and round remain
/// independent targets; large text reflows the course and result. D404 scopes the matte metal to the score.
private struct HomeProgrammeRound: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let row: HomeFeedRow
  var photo: Image? = nil
  var showDay = true
  var holes: Int? = nil
  var points: Int? = nil
  var monthRank: Int? = nil
  var cap: Int? = nil
  let open: () -> Void
  let openPerson: () -> Void

  private var name: String { HomeCopy.who(row) }
  private var day: String? { HomeWireCopy.dayMarker(row.played_on) }
  private var course: (club: String, tee: String?) {
    HomeWireCopy.courseTitle(row.course ?? "")
  }
  private var story: String? {
    HomeWireCopy.roundStory(row, points: points, monthRank: monthRank, cap: cap, holes: holes)
  }
  private var spoken: String {
    let line: String
    if let points, let monthRank,
       let story = HomeWireCopy.roundStory(row, points: points, monthRank: monthRank, cap: cap, holes: holes),
       let gross = row.gross {
      line = "\(gross) at \(course.club.isEmpty ? "Course not recorded" : row.course ?? course.club). \(story)"
    } else { line = HomeWireCopy.roundLine(row, holes: holes) }
    let needsPerformance = (points != nil && monthRank != nil) || row.is_first == true ||
      row.is_pr == true || HomeWireCopy.claimsSub80(row, holes: holes)
    let phrase = CSBands.scoreMetal(row.pvi) == .neutral ? "" : CSBands.vsPhrase(row.pvi)
    let performance = needsPerformance ? (row.is_me == true ? phrase : CSBands.theirs(phrase)) : ""
    return [name, line, performance.isEmpty ? nil : performance, day].compactMap { $0 }.joined(separator: ". ")
  }

  private var metal: CSBands.ScoreMetal { CSBands.scoreMetal(row.pvi) }
  private var scoreFill: Color {
    switch metal {
    case .gold: cs.scoreGold
    case .silver: cs.scoreSilver
    case .bronze: cs.scoreBronze
    case .neutral: cs.bg2
    }
  }
  private var scoreInk: Color { metal == .neutral ? cs.ink : cs.scoreInk }

  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      HStack(alignment: .center, spacing: CSTokens.Space.s3) {
        person
        if showDay, let day {
          Text(day).csType(.agateS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      Button(action: open) {
        A11yStack(alignment: .leading, rowAlignment: .center,
                  spacing: CSTokens.Space.s4, columnSpacing: CSTokens.Space.s3) {
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            Text(course.club.isEmpty ? "Course not recorded" : course.club)
              .csType(.social).foregroundStyle(cs.ink)
              .fixedSize(horizontal: false, vertical: true)
            if let tee = course.tee {
              Text(tee).csType(.agateS).foregroundStyle(cs.mut)
                .fixedSize(horizontal: false, vertical: true)
            }
            if let story {
              Text(story).csType(.story).foregroundStyle(cs.ink)
                .padding(.top, CSTokens.Space.s1)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          if let gross = row.gross {
            CSScorePanel("\(gross)", label: HomeWireCopy.grossUnit(holes: holes),
                         fill: scoreFill, ink: scoreInk)
          }
        }
        .frame(maxWidth: .infinity, minHeight: CSTokens.Space.rail, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .multilineTextAlignment(.leading)
      .accessibilityLabel(spoken)
      .accessibilityHint("Opens the round")
      .accessibilityIdentifier("home.round.\(row.round_id?.uuidString ?? "unknown")")
      if let photo {
        Button(action: open) {
          Color.clear
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .overlay {
              GeometryReader { proxy in
                photo.resizable().scaledToFill()
                  .frame(width: proxy.size.width, height: proxy.size.height)
                  .clipped()
              }
              .allowsHitTesting(false)
            }
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
      }
    }
    .padding(.vertical, CSTokens.Space.s3)
    .accessibilityElement(children: .contain)
  }

  private var person: some View {
    Button(action: openPerson) {
      HStack(spacing: CSTokens.Space.s3) {
        CSFace(.init(id: row.profile_id ?? UUID(), marker: row.marker), size: .list, name: name)
        Text(name).csType(.social).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, minHeight: CSTokens.Space.rail, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("View \(name)'s golfer card")
    .accessibilityIdentifier("home.round.person.\(row.profile_id?.uuidString ?? "unknown")")
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
/// D365 · **the reaction menu is gone.** One control — the applause glyph and
/// its count — where the given tokens and the `+` used to be. The signature is
/// kept so every caller (Home, the fixtures) hands in the same fold; the
/// toggle is always `Applause.key`.
struct HomeWireReactions: View {
  @Environment(\.cs) private var cs
  let state: [String: ReactionState]
  let day: String?
  var commentCount: Int? = nil
  var openComments: (() -> Void)? = nil
  let onToggle: (String) -> Void

  var body: some View {
    HStack(spacing: CSTokens.Space.s4) {
      ApplauseControl(state: Applause.state(state)) { onToggle(Applause.key) }
      if let openComments {
        Button(action: openComments) {
          HStack(spacing: CSTokens.Space.s1) {
            CSGlyph(.comment, size: .inline)
            // `1 comment`, never `1 comments` — the Kit counts, the view prints
            Text(HomeWireCopy.commentsDoor(commentCount)).csType(.bodyS)
          }
          .foregroundStyle(cs.ink)
          .frame(minWidth: 44, minHeight: 44)
          // the frame is not the target until something shapes it (see
          // `CSTertiaryStyle`): without this the door was its 18pt words
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.round.comments")
      }
      Spacer(minLength: CSTokens.Space.s2)
      if let day {
        Text(day).csType(.agateS, caps: true).foregroundStyle(cs.mut).accessibilityHidden(true)
      }
    }
    .frame(minHeight: 44)
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
/// which is the same object it drew *"North Grove (fixture) · 4 earlier league notes"* with.
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
  /// MW-02 · the league, printed only when the sentence alone would not say which.
  var context: String? = nil
  let act: (() -> Void)?

  init(headline: String, stamp: String?, context: String? = nil, act: (() -> Void)?) {
    self.headline = headline; self.stamp = stamp; self.context = context; self.act = act
  }

  var body: some View {
    if let act {
      Button(action: act) { row.contentShape(Rectangle()) }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([context, headline, stamp].compactMap { $0 }.joined(separator: ". "))
    } else {
      row.accessibilityElement(children: .combine)
    }
  }

  private var row: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        if let context {
          Text(context).csType(.agateS, caps: true).foregroundStyle(cs.mut)
        }
        Text(headline).csType(.body).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
      }
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
        Text(item.localHeadline()).csType(.display)
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
    .accessibilityLabel([item.eyebrow, item.localHeadline(), item.standfirst].compactMap { $0 }.joined(separator: ". "))
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
  /// W3 twin · the attribution an announce post carries, as on the board
  static let fromPro = "From the Pro"
  let marker: String?
  let text: String
  let ink: Color?
  /// An agate attribution over the sentence (`From the Pro`), in `mut` —
  /// the web's `.hfpro`. nil for every other line.
  let label: String?
  let act: (() -> Void)?

  init(marker: String?, text: String, ink: Color? = nil, label: String? = nil, act: (() -> Void)? = nil) {
    self.marker = marker; self.text = text; self.ink = ink; self.label = label; self.act = act
  }

  var body: some View {
    if let act {
      Button(action: act) { line.contentShape(Rectangle()) }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([label, text, marker].compactMap { $0 }.joined(separator: ". "))
    } else {
      line.accessibilityElement(children: .combine)
    }
  }

  private var line: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
      VStack(alignment: .leading, spacing: 2) {
        if let label {
          Text(label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
        }
        Text(text).csType(.bodyS).foregroundStyle(ink ?? cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
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
          // D359 / F4 · the bag is ordinary decoration, not a live competition
          CSGlyph(.bag, size: .block)
            .foregroundStyle(cs.mut)
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
