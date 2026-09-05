// Cup Season — YOUR RECORD, a destination (D232, IA §12).
//
// You had two group heads, "Your golf" and "Your seasons", and the second was
// a SECTION where a destination belongs: the career, the trophies, the
// head-to-heads, the side games, the books and the courses are six things
// behind one head, and the thing a golfer comes back for in February should
// not be something they scroll past their trophy case to reach.
//
// So You keeps two heads and the second one is a door. This is what it opens.
//
// EVERY ROW WAITS FOR ITS FACT (L-44). SEASONS renders `seasons_played` only
// where R12 has landed — the shipped `career_record` returns `seasons_done`,
// which counts *paid* seasons, holds 0 rows for every profile in prod, and
// therefore told a golfer who has finished a season that they have finished
// none. THE BOOKS renders only what was actually settled, never a $0 figure
// dressed as a stat. And the "since" clause needs `first_round_on`; there is
// no fallback, because an account's creation date is not when somebody started
// playing golf.
//
// EVERY SEASON ROW OPENS ITS STORY PAGE, not a dead table (D223/D232).

import SwiftUI
import CSDesign
import CupSeasonKit

struct RecordPage: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @Environment(\.openCompetition) private var openCompetition
  let links: YouLinks
  var openHeadToHead: (UUID) -> Void = { _ in }

  @State private var model = RecordModel()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        CSPageHeader("Your record", eyebrow: CSHeaderDate.today()) { EmptyView() }

        if let line = model.headline {
          Text(line).font(CSFont.title).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        if let sub = model.subline {
          Text(sub).font(CSFont.sentence).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }

        // ── SEASONS. Every row opens the season's story page.
        if !model.seasons.isEmpty { seasonsSection }

        // ── TROPHIES. The counts and the objects, one subject, one place.
        if model.record?.items.isEmpty == false || !TrophyCase.tiles(trophies: model.trophies, achievements: model.achievements).isEmpty {
          CSSectionHead("Trophies")
          CareerRecordView(record: model.record)
          TrophyCaseView(trophies: model.trophies, achievements: model.achievements,
                         userId: store.session?.user.id, openReceipt: links.openReceipt)
        }

        // ── HEAD TO HEAD. Each row opens the head-to-head page, which is the
        // whole point of promoting the record: a name here is a record there.
        // D232 names this section HEAD TO HEAD on the record: here it is the
        // list of records, and each row opens one. On Golfers the same
        // component keeps its own head, because there it answers "who am I up
        // against" rather than "what have I done".
        RivalriesSection(rivalries: model.rivalries, openTourCard: openHeadToHead,
                         head: "Head to head")

        // ── SIDE GAMES (R17). The game's OWN settled sentence, not a verdict
        // this client derived from a side index and two name strings.
        if !model.sideGames.isEmpty {
          CSSectionHead("Side games")
          VStack(spacing: 0) {
            ForEach(Array(model.sideGames.enumerated()), id: \.element.id) { i, g in
              CSRow(last: i == model.sideGames.count - 1) {
                VStack(alignment: .leading, spacing: 3) {
                  Text(g.title).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
                  if let s = g.story {
                    Text(s).font(CSFont.footnote).foregroundStyle(cs.dimText)
                      .fixedSize(horizontal: false, vertical: true)
                  }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
              }
            }
          }
        }

        // ── THE BOOKS. D39's posture, verbatim: a record of what friends
        // settled between themselves. Nothing owed to or by the app.
        if let money = model.record?.moneyLine {
          CSSectionHead("The books")
          CSRow(last: true) {
            VStack(alignment: .leading, spacing: 6) {
              YouStatRow(label: money.sub, value: money.amount)
              Fine(CareerRecord.moneyNote)
            }
          }
        }

        // ── COURSES. `tour_card(me).courses`, returned since D150.
        if !model.courses.isEmpty {
          CSSectionHead("Courses · \(model.courses.count)")
          VStack(spacing: 0) {
            ForEach(Array(model.courses.prefix(8).enumerated()), id: \.element.id) { i, c in
              CSRow(last: i == min(model.courses.count, 8) - 1) {
                MathRow(label: RoundCopy.course(c.name),
                        value: "\(c.rounds)")
              }
            }
          }
        }

        if model.loaded && model.isBare {
          EmptyRootView(root: RecordModel.emptyRoot) { _ in links.postRound() }
        }
      }
      .padding(20)
      .redacted(reason: model.loaded ? [] : .placeholder)
    }
    .background(cs.bg0)
    // The bar STAYS: this is a pushed page and the bar is the way back. The
    // first simulator shot of it was a record with no exit.
    .navigationTitle("Your record")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable { await model.load(me: store.me, uid: store.session?.user.id) }
    .task { await model.load(me: store.me, uid: store.session?.user.id) }
    .sliceToastHost()
  }

  /// Every season row opens the season's STORY page, not a dead table
  /// (D223/D232) — the record is what a golfer comes back for in February and
  /// a table with no narrative is a spreadsheet.
  @ViewBuilder private var seasonsSection: some View {
    CSSectionHead(seasonsHead)
    VStack(spacing: 0) {
      ForEach(Array(model.seasons.enumerated()), id: \.element.id) { i, r in
        CSRow(last: i == model.seasons.count - 1) {
          YouDoorRow(glyph: Text(Image(systemName: "flag")), title: r.name, sub: r.sub,
                     action: { openCompetition(r.id, .story) })
            .accessibilityLabel("\(r.name), \(r.spoken)")
            .accessibilityHint("Opens the season")
        }
      }
    }
  }

  /// "Seasons" · "Seasons · 3 played". The count renders only where R12 has
  /// landed — `seasons_done` is the MONEY denominator and reads 0 for
  /// everybody, so printing it here would be the defect this entry names.
  private var seasonsHead: String {
    guard let line = model.record?.seasonsLine else { return "Seasons" }
    return "Seasons · \(line)"
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
  var sideGames: [SideGame] = []
  var rounds: Int = 0
  var bestRound: TourCard.BestRound?
  var loaded = false

  struct SideGame: Identifiable, Sendable {
    let id: UUID
    let title: String
    let story: String?
  }

  /// The R17 row, hand-declared while the migration waits on the owner's push.
  struct SideGameRow: Decodable, Sendable {
    let live_round_id: UUID?
    let played_on: String?
    let game: String?
    let course_label: String?
    let players: [String]?
    let story: String?
    let status: String?
  }
  struct SideGamesCall: RpcCall {
    static let name = "my_side_games"
    static let optionalArgs: [String] = ["p_limit"]
    typealias Returns = [SideGameRow]
    var p_limit: Int?
  }

  static let emptyRoot = EmptyRoot(
    head: "Nothing on the record yet.",
    fact: nil,
    sub: "Add a round you already played and it starts here — the courses, the numbers, and every season you go on to play.",
    doors: [.addMyRound])

  /// True only once every read has ANSWERED and each one answered with
  /// nothing. A page that is still loading is not a bare record (L-32).
  var isBare: Bool {
    loaded && rounds == 0 && seasons.isEmpty && rivalries.isEmpty
      && sideGames.isEmpty && courses.isEmpty && (record?.items.isEmpty ?? true)
  }

  /// "212 rounds" — the headline, and nothing when there is no round to count.
  var headline: String? {
    guard rounds > 0 else { return nil }
    return "\(rounds) round\(rounds == 1 ? "" : "s")"
  }

  /// "Best 74 at Troon North · since March 2026" — each clause dropped rather
  /// than guessed, which is what makes the "since" clause honest (R12).
  var subline: String? {
    var bits: [String] = []
    if let b = bestRound { bits.append("Best " + b.line) }
    if let s = record?.sinceClause, let f = s.first {
      bits.append(String(f).uppercased() + s.dropFirst())
    }
    return bits.isEmpty ? nil : bits.joined(separator: " · ")
  }

  /// ONE load, not a second copy of You's. `YouRepository.load` already reads
  /// the record, the trophies, the rivalries and the season-by-season list and
  /// already names which of them failed; the record page adds exactly two
  /// reads of its own — the card (for the courses and R21's best round) and
  /// R17's side games.
  func load(me: Me?, uid: UUID?) async {
    guard let me, let uid else { loaded = true; return }
    let svc = SupabaseService.shared
    async let you = YouRepository().load(me: me, userId: uid, leagueId: nil)
    async let cardJSON = try? svc.call(Rpc.tour_card(p_profile: uid))
    async let side: [SideGameRow] = (try? await svc.call(SideGamesCall(p_limit: 8))) ?? []
    let (d, card, sg) = await (you, cardJSON, side)

    record = d.careerRecord
    trophies = d.trophies
    achievements = d.achievements
    rivalries = d.rivalries
    seasons = d.leagueRecord
    rounds = d.career?.rounds ?? 0
    if let card {
      let tc = TourCard.parse(card)
      if tc.career.rounds > 0 { rounds = tc.career.rounds }
      bestRound = tc.bestRound
      courses = tc.courses
    }
    sideGames = sg.compactMap { r in
      guard let id = r.live_round_id else { return nil }
      let game = r.game.flatMap { g -> String? in
        guard let f = g.first else { return nil }
        return String(f).uppercased() + g.dropFirst()
      }
      let head = [game, r.course_label.map(RoundCopy.course)]
        .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
      let day = r.played_on.map(RivalryCopy.monthDaySpoken) ?? ""
      return SideGame(id: id,
                      title: head.isEmpty ? (day.isEmpty ? "A live round" : day) : head,
                      story: r.story)
    }
    loaded = true
  }
}

#Preview("Record") {
  NavigationStack { RecordPage(links: .none) }.environment(SessionStore()).csTheme()
}
