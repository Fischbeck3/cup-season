// Cup Season — THE RECORD, the almanac (Wave 3, `surfaces/profile.md` §9;
// D232, IOS-047).
//
// **The densest surface in the product and the quietest.** No ember at all —
// there is nothing live on a page about the past, and a page about the past
// with an ember pill on it is the product shouting at a golfer reading. Gold
// only under a season that was won. `column` for every figure. A leaf carrying
// the table.
//
// THE SHAPE: the header · the one serif sentence · the career on one rule ·
// SEASONS as the leaf · TROPHIES as slats · HEAD TO HEAD.
//
// THE HEADLINE READS THE FIELD THE RAIL READS. The blind review's first
// finding was that *"the best of them an 80, at Papago"* sat 200pt above
// `74 BEST` and a trophy reading `74 at Troon North` — three numbers for one
// fact, and on the page whose promise is that every number shows its work,
// that costs more credibility than any spacing error. `RecordModel.headline`
// is built from `bestRound`, which is the SAME value the career rule reads.
//
// **`SINCE MARCH 2026`, not today's date** (YRS-12). A today-dateline on a
// page about the past is the defect, and `CareerRecord.firstRoundOn` is the
// producer — with no fallback, because an account's creation date is not when
// somebody started playing golf.
//
// EVERY SEASON ROW OPENS ITS STORY PAGE, not a dead table (D223/D232).

import SwiftUI
import CSDesign
import CupSeasonKit

struct RecordPage: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(SessionStore.self) private var store
  @Environment(\.openCompetition) private var openCompetition
  let links: YouLinks
  var openHeadToHead: (UUID) -> Void = { _ in }

  @State private var model = RecordModel()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        CSBackChevron { dismiss() }
        CSPageHeader("The record", eyebrow: model.since)

        // §1.4 · the page's ONE serif appearance, and it is the voice the
        // audit called the surface's best asset — promoted out of grey body
        // copy into the page's own sentence (YRS-11).
        if let line = model.headline {
          CSFigureRun(line, role: .lead).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, CSTokens.Space.s4)
        }

        career.padding(.top, CSTokens.Space.s5)

        seasons
        trophies
        rivals

        if model.loaded && model.isBare {
          CSEmpty(glyph: .rack,
                  eyebrow: "Nothing on it yet",
                  headline: "A record starts with one round.",
                  fact: RecordModel.emptyFact,
                  door: .primary("Add my round", links.postRound))
            .padding(.top, CSTokens.Space.s5)
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.bottom, CSTokens.Space.s6)
      .frame(maxWidth: .infinity, alignment: .leading)
      .csRedacted(!model.loaded)
      .csPage("record")
    }
    .background(cs.bg0)
    .defaultScrollAnchor(CSDevHatch.bottom ? .bottom : .top)
    // §12.2 · the system bar carries the back chevron and nothing else — and
    // on iOS 26 "nothing else" included a translucent `bg2` capsule around
    // the chevron, which is a boxed control on a system whose first
    // non-negotiable is that a container needs a job. The page draws the
    // family's own chevron instead, the way the course page and the event
    // room already do, so the product has ONE back button.
    .csBareBar()
    // DF-14 · and the page's own ground sits under the clock, so a figure
    // never renders through the time.
    .csStatusCap(cs.bg0)
    .refreshable { await model.load(me: store.me, uid: store.session?.user.id) }
    .task { await model.load(me: store.me, uid: store.session?.user.id) }
    .sliceToastHost()
  }

  // MARK: - the career

  /// §9 · four figures on ONE shared 2pt `ink` rule with their labels beneath:
  /// `18 ROUNDS · 3 SEASONS · 74 BEST · $80 MONEY`. **Money in ink** (§9.5) —
  /// the pot is gold, what a golfer settled with their friends is ink, and
  /// `pos`/`neg` never touch money.
  @ViewBuilder private var career: some View {
    let cells = model.careerCells
    if !cells.isEmpty {
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        HStack(alignment: .lastTextBaseline, spacing: CSTokens.Space.s3) {
          ForEach(Array(cells.enumerated()), id: \.offset) { _, c in
            Text(c.value).csType(.figureM).csTabular().foregroundStyle(cs.ink)
              .frame(maxWidth: .infinity, alignment: c.trailing ? .trailing : .leading)
              .lineLimit(1).minimumScaleFactor(0.6)
          }
        }
        CSRule(.heavy)
        HStack(alignment: .top, spacing: CSTokens.Space.s3) {
          ForEach(Array(cells.enumerated()), id: \.offset) { _, c in
            Text(c.label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              .frame(maxWidth: .infinity, alignment: c.trailing ? .trailing : .leading)
          }
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(cells.map { "\($0.value) \($0.label)" }.joined(separator: ", "))
    }
  }

  // MARK: - the leaf

  @ViewBuilder private var seasons: some View {
    let rows = model.recordRows { openCompetition($0, .story) }
    if !rows.isEmpty {
      ProfileHead("Seasons", count: model.seasonsCount)
      CSRecordLeaf(rows).padding(.top, CSTokens.Space.s3)
      // §9.5 · the ledger line renders beneath the leaf on any viewport that
      // shows a money figure, verbatim, from one constant (LINT-23).
      if model.showsMoney {
        Text(MoneyCopy.ledger).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, CSTokens.Space.s3)
      }
    }
  }

  // MARK: - the trophies

  /// 44pt slats, top `rule`, **a drawn glyph at 28pt in `ink`**. No tiles, no
  /// card-in-a-card (YRS-07), no emoji (YRS-03), and **none of them is the
  /// pennant** (§5.1, LINT-28) — the Tracer's flag is the tab band and the
  /// app icon, and a flag on LOW ROUND OF THE SEASON with the Compete tab's
  /// identical flag 400pt below it is ICO-12 reopened on the core symbol.
  ///
  /// The engraver ceremony survives verbatim onto the slat: it is the one
  /// real ceremony on this surface and the audit calls it a "what works".
  @ViewBuilder private var trophies: some View {
    let tiles = model.tiles
    if !tiles.isEmpty {
      ProfileHead("Trophies", count: CSCopy.spelled(tiles.count))
      TrophySlats(tiles: tiles, userId: store.session?.user.id, openReceipt: links.openReceipt)
        .padding(.horizontal, -CSTokens.Space.gutter)
        .padding(.top, CSTokens.Space.s3)
    } else if model.loaded && model.rounds > 0 {
      // D291 · a golfer WITH rounds and no trophies is told what fills the
      // case, in the case's own marks. A golfer with nothing at all falls to
      // the page's one bare empty below, not to two empties stacked (Y-02).
      ProfileHead("Trophies")
      TrophyCaseEmpty().padding(.top, CSTokens.Space.s3)
    }
  }

  // MARK: - head to head

  /// §9 · the rivals list, below the trophies — **reachable, not clipped.**
  /// It is cut by the tab bar on the shipped page. Same component as Golfers,
  /// same slat: a name here is a record there.
  @ViewBuilder private var rivals: some View {
    RivalriesSection(rivalries: model.rivalries, openTourCard: openHeadToHead,
                     head: "Head to head")
  }
}

// MARK: - the trophy slats

/// The display case, as slats. `TrophyCaseView`'s grid of dusk-ground tiles is
/// gone — a card inside a card inside a page (YRS-07) — and what survives is
/// the thing that was worth keeping: the engraver.
struct TrophySlats: View {
  @Environment(\.cs) private var cs
  let tiles: [TrophyTile]
  let userId: UUID?
  var openReceipt: ((UUID) -> Void)? = nil

  @State private var fresh: Set<String> = []
  @State private var stamped = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      let groups = TrophyCase.shelves(tiles)
      ForEach(Array(groups.enumerated()), id: \.element.shelf) { i, group in
        // The FIRST head hangs off the section head above it, not off a
        // 32pt gap — "is it first", never "is it hardware": an account with
        // no silverware opens on BESTS and must not open on a hole.
        Text(group.shelf.head).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          .padding(.horizontal, CSTokens.Space.gutter)
          .padding(.top, i == 0 ? 0 : CSTokens.Space.s5)
          .padding(.bottom, CSTokens.Space.s2)
        ForEach(group.tiles) { t in
          // THE DOOR IS THE MIDDLE SHELF'S, and only its. Three shelves have
          // to read as three RANKS: hardware takes the 44pt mark and its
          // year, a best takes the door into the round it was won on, and the
          // quiet shelf takes neither. A first round's receipt is still
          // reachable from Recent rounds, the board and the form row.
          if let rid = t.roundId, t.shelf == .bests, let openReceipt {
            Button { openReceipt(rid) } label: { slat(t).contentShape(Rectangle()) }
              .buttonStyle(.plain)
              .accessibilityHint("Opens the round")
          } else {
            slat(t)
          }
        }
      }
    }
    .onChange(of: tiles.map(\.id), initial: true) { _, ids in stamp(ids) }
  }

  /// D291 · **three sizes, and the size is the shelf's.** A Cup is drawn at
  /// 44pt with its name at `nameL` and its year trailing; a best and a
  /// milestone stay at 28. The quiet shelf takes `mut` for the mark and the
  /// name too, because "quiet" has to be visible somewhere other than a head.
  private func slat(_ t: TrophyTile) -> some View {
    let hw = t.shelf == .hardware
    let quiet = t.shelf == .along
    return VStack(spacing: 0) {
      CSRule()
      HStack(alignment: .center, spacing: CSTokens.Space.s3) {
        CSTrophyMark(t.glyph, numeral: t.numeral, size: t.shelf.mark)
          .frame(width: max(CSTokens.Space.rail - CSTokens.Space.s3, t.shelf.mark), alignment: .center)
          .opacity(quiet ? CSTokens.Alpha.a56 : 1)
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          EngravedName(t.title, engrave: fresh.contains(t.id), quiet: quiet)
          if !t.sub.isEmpty {
            Text(t.sub).csType(.agateS, caps: false).foregroundStyle(cs.mut)
              .lineLimit(2).multilineTextAlignment(.leading)
          }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        // The year sits on the hardware line, right-flush — §16A.2's slot,
        // and it is the one fact that tells two Cups apart at a glance.
        if let trail = t.trail {
          Text(trail).csType(.columnM).csTabular().foregroundStyle(cs.mut)
        } else if t.roundId != nil && t.shelf == .bests && openReceipt != nil {
          CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut)
        }
      }
      .padding(.leading, CSTokens.Space.gutter)
      .padding(.trailing, CSTokens.Space.gutter)
      .frame(minHeight: hw ? 68 : 50)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(t.title). \(t.sub)")
  }

  /// Decide once per set of ids which tiles are arrivals, then remember them.
  private func stamp(_ ids: [String]) {
    guard let userId, !ids.isEmpty else { return }
    let store = TrophySeenStore(userId: userId)
    if !stamped {
      fresh = TrophySeenStore.fresh(tiles, seen: store.load())
      stamped = true
    }
    store.save(Set(ids).union(store.load() ?? []))
  }
}

/// **D291 · the empty, given a shape** (§17). Four marks a golfer has not cut
/// yet, drawn at 12% in a row, under the case's own head and one sentence.
/// No card, no button — the ⊕ is a permanent tab an inch below (D177).
struct TrophyCaseEmpty: View {
  @Environment(\.cs) private var cs
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSRule()
      HStack(alignment: .center, spacing: CSTokens.Space.s4) {
        ForEach(Array(TrophyCase.emptyMarks.enumerated()), id: \.offset) { _, m in
          CSTrophyMark(m.glyph, numeral: m.numeral, size: 28)
        }
      }
      .opacity(0.12)
      .padding(.top, CSTokens.Space.s4)
      Text(TrophyCase.emptyHead).csType(.name).foregroundStyle(cs.ink)
        .padding(.top, CSTokens.Space.s4)
      Text(TrophyCase.emptyLead).csType(.bodyS).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, CSTokens.Space.s2)
    }
    .accessibilityElement(children: .combine)
  }
}

/// C4's engraver, kept: **a 2pt gold needle sliding a cover off a fresh
/// trophy's name over 1.1s**, once, on arrival. It is the one real ceremony on
/// this surface and the only place gold moves in the product.
struct EngravedName: View {
  @Environment(\.cs) private var cs
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let title: String
  let engrave: Bool
  /// D291 · the quiet shelf's names are `mut`, so "quiet" is visible on the
  /// row and not only in the head above it.
  var quiet = false
  @State private var coverGone = false

  init(_ title: String, engrave: Bool, quiet: Bool = false) {
    self.title = title; self.engrave = engrave; self.quiet = quiet
  }

  var body: some View {
    Text(title).csType(.name).foregroundStyle(quiet ? cs.mut : cs.ink)
      .lineLimit(2).multilineTextAlignment(.leading)
      .overlay {
        if engrave && !reduceMotion {
          GeometryReader { g in
            Rectangle().fill(cs.bg0)
              .overlay(alignment: .leading) { Rectangle().fill(cs.gold).frame(width: 2) }
              .offset(x: coverGone ? g.size.width * 1.05 : 0)
          }
          .clipped()
          .allowsHitTesting(false)
        }
      }
      .clipped()
      .onAppear {
        guard engrave, !reduceMotion else { return }
        CSMotion.run(.timingCurve(0.16, 0.84, 0.36, 1, duration: 1.1)) { coverGone = true }
      }
  }
}

// MARK: - The model

@MainActor
@Observable
final class RecordModel {
  var record: CareerRecord?
  var trophies: [Rpc.my_trophies.Row] = []
  var achievements: [Achievement] = []
  var seasons: [LeagueRecordRow] = []
  var rivalries: [RivalryLine] = []
  var courses: [TourCard.Course] = []
  var rounds: Int = 0
  /// D291 · the five newest rounds, for the BESTS slats' own sub-lines.
  var recent: [RoundRow] = []
  var bestRound: TourCard.BestRound?
  var loaded = false

  static let emptyFact =
    "Add a round you already played and it starts here — the courses, the numbers, and every season you go on to play."

  /// True only once every read has ANSWERED and each one answered with
  /// nothing. A page that is still loading is not a bare record (L-32).
  var isBare: Bool {
    loaded && rounds == 0 && seasons.isEmpty && rivalries.isEmpty
      && courses.isEmpty && tiles.isEmpty && (record?.items.isEmpty ?? true)
  }

  /// D291 · the case, with what the phone knows about the rounds its
  /// milestones were won on. `Career.recent` is FIVE rounds, so most Bests
  /// slats fall back to `79 · Aug 24` — which is the honest degrade and the
  /// same one the desk takes when a round is older than its 400.
  var tiles: [TrophyTile] {
    TrophyCase.tiles(trophies: trophies, achievements: achievements) { id in
      guard let r = recent.first(where: { $0.id == id }) else { return nil }
      return MilestoneRound(gross: r.gross, courseLabel: r.course_label, playedOn: r.played_on)
    }
  }

  /// §9 · `SINCE MARCH 2026` — **not today's date.** nil until `first_round_on`
  /// arrives, because an account's creation date is not when somebody started
  /// playing golf, and the slot is then empty rather than wrong.
  var since: String? {
    guard let c = record?.sinceClause else { return nil }
    return c.uppercased()
  }

  /// The one serif sentence, with its numeral marked as a figure run — braces
  /// from the producer, never a regex over prose. **The number it names is
  /// the same `bestRound` the career rule reads**, which is the blind
  /// review's first finding answered.
  var headline: String? {
    guard rounds > 0 else { return nil }
    var s = "\(CSCopy.spelled(rounds).capitalizedFirst) round\(rounds == 1 ? "" : "s")"
    if let m = record?.firstRoundOn, let month = HeadToHeadCopy.monthYear(m) {
      s += " since \(month)"
    }
    s += "."
    if let b = bestRound {
      s += " The best of them a {\(b.gross)}"
      if let c = b.courseLabel, !c.isEmpty { s += ", at \(RoundCopy.course(c))" }
      s += "."
    }
    return s
  }

  struct Cell { let value: String; let label: String; var trailing = false }

  /// Four figures, and **a cell with no fact is absent rather than a dash**.
  var careerCells: [Cell] {
    var out: [Cell] = []
    if rounds > 0 { out.append(Cell(value: String(rounds), label: "Rounds")) }
    if let n = record?.seasonsPlayed, n > 0 { out.append(Cell(value: String(n), label: "Seasons")) }
    if let b = bestRound { out.append(Cell(value: String(b.gross), label: "Best")) }
    if let cents = record?.earningsCents, cents > 0 {
      out.append(Cell(value: CSCopy.dollars(cents: cents), label: "Money", trailing: true))
    }
    return out
  }

  var showsMoney: Bool { (record?.earningsCents ?? 0) > 0 }

  /// §16A.2 · the slot carries a COUNT. `SINCE 2026` was a date in a count's
  /// seat while the header two lines above already carried the join date.
  var seasonsCount: String? {
    guard !seasons.isEmpty else { return nil }
    return "\(CSCopy.spelled(seasons.count)) season\(seasons.count == 1 ? "" : "s")"
  }

  /// Newest first — an archive reads from the present backwards.
  func recordRows(open: @escaping (UUID) -> Void) -> [CSRecordLeaf.Row] {
    seasons.reversed().map { r in
      CSRecordLeaf.Row(id: r.id.uuidString,
                       year: r.year.map(String.init),
                       competition: r.name,
                       qualifier: r.qualifier,
                       finish: r.finish,
                       line: r.line,
                       won: r.won,
                       spoken: "\(r.name), \(r.spoken)",
                       open: { open(r.id) })
    }
  }

  /// ONE load, not a second copy of You's. `YouRepository.load` already reads
  /// the record, the trophies, the rivalries and the season-by-season list and
  /// already names which of them failed; the record page adds exactly one read
  /// of its own — the card, for the courses and R21's best round.
  func load(me: Me?, uid: UUID?) async {
    guard let me, let uid else { loaded = true; return }
    let svc = SupabaseService.shared
    async let you = YouRepository().load(me: me, userId: uid, leagueId: nil)
    async let cardJSON = try? svc.call(Rpc.tour_card(p_profile: uid))
    let (d, card) = await (you, cardJSON)

    record = d.careerRecord
    trophies = d.trophies
    achievements = d.achievements
    rivalries = d.rivalries
    seasons = d.leagueRecord
    rounds = d.career?.rounds ?? 0
    recent = d.career?.recent ?? []
    if let card {
      let tc = TourCard.parse(card)
      if tc.career.rounds > 0 { rounds = tc.career.rounds }
      bestRound = tc.bestRound
      courses = tc.courses
    }
    loaded = true
  }
}

#Preview("Record") {
  NavigationStack { RecordPage(links: .none) }.environment(SessionStore()).csTheme()
}
