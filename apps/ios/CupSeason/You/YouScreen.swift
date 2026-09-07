// Cup Season — YOU: **the identity page, not an account screen** (Wave 3,
// `surfaces/profile.md`; IOS-047).
//
// THE SHAPE, top to bottom, and it is §D-2's order: **the credential · the
// season · rivals · form · courses kept · the record**, then the two doors
// that are not about the golf (buddies, the bag) and the settings link.
//
// WHAT LEFT, and why each one had to (audit §2.14, YRS-01…YRS-31):
//   * `CSPageHeader("You")` — the credential IS the page's header, and a
//     serif "You" above a 34pt name says the name twice (D-7, GP-17).
//   * `YouHero` and its two gold emoji achievement capsules (YRS-03).
//   * `LifetimeTiles` — a grid of tiles inside a card (YRS-07) — and
//     `SeasonStatsStrip` and `LeagueRecordView`, which were label-left /
//     value-right SETTINGS ROWS carrying golf numbers (YRS-01, YRS-02).
//   * `RecentRoundsList` with its per-row delete × (YRS-22): an identity page
//     is not an admin tool, and deletion belongs on the round's own receipt.
//   * `CSGroupHead` ×2 — a page with six sections does not need a table of
//     contents on top of them.
//
// WHAT ARRIVED THAT THE PAYLOAD ALREADY CARRIED: **the courses**. `tour_card`
// has returned `courses[]` since D150 and the phone has thrown them away ever
// since. The You root reads the same producer the person page already calls —
// a re-use, not an endpoint (§14).
//
// WHAT SURVIVES: every `.sheet` and link the host wires, the Y-17 partial-load
// retry line, `LRWQuietStore`, `ReceiptCache` seeding, and the bag read.

import SwiftUI
import CSDesign
import CupSeasonKit

@MainActor
@Observable
final class YouModel {
  var data = YouData()
  /// Y-17 · the first load has returned (whole or partial)
  var loaded = false
  /// Y-17 · at least one block did not load — the screen offers one Retry
  var failed: Bool { data.isPartial }
  /// D150 · the card, for the courses and the best round. The You root reads
  /// the SAME producer the person page calls; there is no second endpoint.
  var card: TourCard?
  private let repo = YouRepository()

  func load(me: Me, uid: UUID, leagueId: UUID?) async {
    async let you = repo.load(me: me, userId: uid, leagueId: leagueId)
    async let cardJSON = try? SupabaseService.shared.call(Rpc.tour_card(p_profile: uid))
    let (d, json) = await (you, cardJSON)
    data = d
    card = json.map(TourCard.parse)
    await ReceiptCache.shared.put((data.career?.recent ?? []).map { $0.seed(marker: me.profile?.marker, isMine: true) })
    loaded = true
  }

  /// D262 · the bag rides in on its own, AFTER the card. nil is "the read did
  /// not happen" — a database this migration has not reached, or no signal —
  /// and the row is not drawn at all in that case. A door to a bag that
  /// cannot be opened is the one thing not permitted (L-32).
  var bag: Bag?
  func loadBag() async { bag = await BagService().load() }

  func dismissLRW(uid: UUID) {
    LRWQuietStore(userId: uid).dismiss()
    data.lastRoundWith = nil
  }

  /// The record leaf's rows — newest first, and every one of them a door to
  /// the season's own story page (D223/D232).
  func recordRows(open: @escaping (UUID) -> Void) -> [CSRecordLeaf.Row] {
    data.leagueRecord.reversed().map { r in
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
}

struct YouScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.openCompetition) private var openCompetition
  let leagueId: UUID?
  let links: YouLinks

  @State private var model = YouModel()
  @State private var reqs = BuddyRequestsModel()

  private var uid: UUID? { store.session?.user.id }
  private var league: Me.Membership? {
    store.me?.memberships.first { $0.league_id == leagueId && $0.standing != nil }
      ?? store.me?.memberships.first { $0.standing != nil }
  }
  /// Y-29 · a card with no rounds on it. Only once the rounds read has
  /// ANSWERED: a career read that failed is nil too, and a failed read is not
  /// an empty card.
  private var noRounds: Bool { model.loaded && model.data.career.map { $0.rounds == 0 } == true }

  var body: some View {
    ScrollViewReader { proxy in
    ScrollView {
      if let me = store.me, let p = me.profile {
        VStack(alignment: .leading, spacing: 0) {
          // §1 · the chrome is a 34pt row with ONE tertiary link. No page
          // header: the object below says whose page this is (D-7).
          chromeRow

          credential(me, p).padding(.top, CSTokens.Space.s2)

          Text(CredentialCopy.mine).csType(.body).foregroundStyle(cs.mut)
            .padding(.top, CSTokens.Space.s4)

          // Y-17 · one quiet line when a block did not load; the rest of the
          // page is whole, and this is the way to ask again.
          if model.failed { retryLine.padding(.top, CSTokens.Space.s3) }

          Group {
            if let m = league {
              ProfileSeasonBlock(membership: m,
                                 openTable: { openCompetition(m.league_id, .table) })
                .id("you-season")
            }
            rivals
            form
            ProfileCoursesBlock(courses: model.card?.courses ?? [],
                                homeCourse: p.home_course, isMe: true,
                                head: "Courses kept")
              .id("you-courses")
            record
          }
          .csRedacted(!model.loaded)

          // ── the two doors that are not the golf. They sit at the page's
          // foot in one rule-bounded block (§D-8): a golfer with low vision
          // gets a weight step and a position, not only a hairline.
          doors.padding(.top, CSTokens.Space.s5)

          if let lrw = model.data.lastRoundWith {
            LastRoundWithLine(lrw: lrw, stage: links.stageRound) { if let uid { model.dismissLRW(uid: uid) } }
              .padding(.top, CSTokens.Space.s4)
          }
        }
        .padding(.horizontal, CSTokens.Space.gutter)
        .padding(.bottom, CSTokens.Space.s6)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .background(cs.bg0)
    .defaultScrollAnchor(CSDevHatch.bottom ? .bottom : .top)
    .navigationTitle("")
    .toolbar(.hidden, for: .navigationBar)
    .sliceToastHost()
    .refreshable { await reload() }
    .task(id: store.me?.profile?.id) { await reload(); await reqs.load(); await model.loadBag() }
    #if DEBUG
    // `-cs_dev_scroll <anchor>` — the same door the season room has, because a
    // page three screens tall cannot be judged from its top and its bottom.
    .task(id: model.loaded) {
      let a = ProcessInfo.processInfo.arguments
      guard model.loaded, let i = a.firstIndex(of: "-cs_dev_scroll"), i + 1 < a.count else { return }
      try? await Task.sleep(for: .seconds(1))
      proxy.scrollTo("you-" + a[i + 1], anchor: .top)
    }
    #endif
    }
  }

  // MARK: - the chrome and the object

  /// §1 · `topBarTrailing` is ONE tertiary link, and on You it is `Settings`.
  /// It is spelled — a ⚙ on the page a golfer edits themselves from is an
  /// icon standing where a word fits.
  private var chromeRow: some View {
    HStack {
      Spacer()
      CSDoor(.link("Settings", links.openSettings))
    }
    .frame(minHeight: 34)
    .accessibilityLabel("Card and settings")
  }

  private func face(_ p: Me.Profile) -> CSFace.Model {
    CSFace.Model(id: p.id ?? UUID(), marker: p.marker, photoURL: model.data.extras?.avatarURL,
                 initials: Initials.of(p.display_name), isViewer: true)
  }

  /// The one object on the page with depth — and it is the SAME object the
  /// person page draws, from the same anatomy, at the same geometry (GP-16).
  @ViewBuilder private func credential(_ me: Me, _ p: Me.Profile) -> some View {
    let golfer = CSCredentialGolfer(
      face: face(p),
      name: p.display_name ?? "Your card",
      identity: CredentialCopy.identity(handle: p.handle, city: p.city, homeCourse: p.home_course),
      slot: slotLabel(p),
      credit: nil,
      figures: figures(p),
      club: CredentialCopy.club(markerName: CSMarkers.marker(p.marker).name))
    if let url = model.data.extras?.avatarURL {
      CSCredential(golfer, hasPhoto: true) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let img): img.resizable().scaledToFill()
          default: crest(p)
          }
        }
      }
    } else {
      CSCredential(golfer, hasPhoto: false) { crest(p) }
    }
  }

  private func crest(_ p: Me.Profile) -> CSCrestPlate {
    let course = p.home_course.flatMap { $0.isEmpty ? nil : $0 }
    return CSCrestPlate(marker: p.marker,
                        seed: course ?? (p.id ?? UUID()).uuidString,
                        hasCourse: course != nil)
  }

  private func slotLabel(_ p: Me.Profile) -> String? {
    switch store.founding.badge(for: p.id ?? UUID()) {
    case .founder: "Founder"
    case .member: "Founding member"
    case nil: nil
    }
  }

  /// One to three, and **a slot with no figure is ABSENT** — never a dash,
  /// never a zero, never a verb (§9.9). Your own card is the one place the
  /// position figure can render, because `me.memberships[].standing` is the
  /// viewer's own.
  private func figures(_ p: Me.Profile) -> [CSCredentialGolfer.Figure] {
    var out: [CSCredentialGolfer.Figure] = []
    if let idx = p.index_current {
      out.append(.init(CSCopy.index(idx), label: "Handicap index"))
    }
    let rounds = model.data.career?.rounds ?? model.card?.career.rounds ?? p.rounds_count ?? 0
    out.append(.init(String(rounds), label: "Rounds"))
    if let m = league, let st = m.standing {
      out.append(.init(String(st.rank), label: m.name, ordinal: CSOrdinal.suffix(st.rank)))
    } else if let best = model.card?.bestRound {
      let where_ = best.courseLabel.map { " · " + RoundCopy.course($0) } ?? ""
      out.append(.init(String(best.gross), label: "Best" + where_))
    }
    return out
  }

  // MARK: - the blocks

  /// §4 · two rows and a door. `RIVALS` was three rows of avatar + record +
  /// meeting count + league — "a table pretending to be a list" — and the
  /// door reading `ALL SEVEN` under a slot already reading `SEVEN` said the
  /// count twice (§16A.2).
  @ViewBuilder private var rivals: some View {
    let all = model.data.rivalries
    if !all.isEmpty {
      ProfileHead("Rivals", count: CSCopy.spelled(all.count))
      VStack(spacing: 0) {
        ForEach(all.prefix(2)) { r in
          RivalSlat(face: CSFace.Model(id: r.opponent, marker: r.marker, initials: Initials.of(r.name)),
                    name: r.name, sub: r.facets, record: r.record,
                    verdict: RivalryCopy.leadLabel(r.lead, them: r.name),
                    rivalryName: r.rivalryName,
                    open: { links.rival(r.opponent) })
        }
      }
      .padding(.horizontal, -CSTokens.Space.gutter)
      .padding(.top, CSTokens.Space.s3)
      if all.count > 2, let open = links.openRecord {
        CSDoor(.link("Every rival", open)).padding(.top, CSTokens.Space.s3)
      }
    } else if model.loaded && !noRounds {
      // §11 · no rivals → one empty at 56pt with the door that finds some.
      ProfileHead("Rivals")
      CSEmpty(glyph: .people,
              eyebrow: "Nobody yet",
              headline: "A rivalry starts the first week you both post.",
              fact: nil,
              door: .link("Find golfers", links.openBuddies))
        .padding(.top, CSTokens.Space.s3)
    }
  }

  @ViewBuilder private var form: some View {
    let recent = model.card?.recent ?? []
    if !recent.isEmpty {
      ProfileHead("Form", count: CredentialCopy.formCount(min(recent.count, 5)))
      ProfileFormRow(rounds: recent).id("you-form")
    } else if noRounds {
      // §11 · nothing on the card yet: ONE empty state, not three sections
      // each saying "not yet" in its own words.
      CSEmpty(glyph: .scorecard,
              eyebrow: "The first card",
              headline: "Your card fills as you play.",
              fact: YouCopy.noRoundsLine,
              door: .primary(YouCopy.postFirst, links.postRound))
        .padding(.top, CSTokens.Space.s5)
        .id("you-form")
    }
  }

  /// §7 · the archive, printed. The leaf is not drawn when there is nothing
  /// to print — an empty leaf is a card.
  @ViewBuilder private var record: some View {
    let rows = model.recordRows { openCompetition($0, .story) }
    let cabinet = TrophyCase.tiles(trophies: model.data.trophies, achievements: model.data.achievements)
    if !rows.isEmpty || !cabinet.isEmpty {
      ProfileHead("The record", count: recordCount(rows.count))
      if !rows.isEmpty {
        CSRecordLeaf(rows).padding(.top, CSTokens.Space.s3).id("you-record")
      }
      if let open = links.openRecord {
        CSDoor(.link(rows.isEmpty ? "Your record" : "The whole record", open))
          .padding(.top, CSTokens.Space.s3)
      }
    }
  }

  /// §16A.2 · the slot takes a COUNT, and a count is its one job.
  private func recordCount(_ n: Int) -> String? {
    guard n > 0 else { return nil }
    return "\(CSCopy.spelled(n)) season\(n == 1 ? "" : "s")"
  }

  /// The two doors that are not the record. `Your buddies` is the way out of
  /// a page that is otherwise all reading (D176); the bag is part of the card
  /// rather than part of the record (D262), and it renders only once its read
  /// has answered.
  @ViewBuilder private var doors: some View {
    VStack(spacing: 0) {
      CSRule()
      door("Your buddies",
           reqs.requests.isEmpty ? "Find golfers, see who you play with"
                                 : "\(reqs.requests.count) request\(reqs.requests.count == 1 ? "" : "s") waiting",
           links.openBuddies)
      if let bag = model.bag, let open = links.openBag {
        CSRule()
        door(BagCopy.yours, bag.isEmpty ? BagCopy.emptySub : BagCopy.summary(bag), open)
      }
      CSRule()
    }
    .padding(.horizontal, -CSTokens.Space.gutter)
  }

  /// §D-8 · **a row whose whole surface is the target carries no chevron.**
  /// The affordance is the verb, set in `name` caps at `ink` against `mut`
  /// glosses everywhere else on the page.
  private func door(_ title: String, _ sub: String, _ action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        Text(title).csType(.name).foregroundStyle(cs.ink)
        Text(sub).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          .lineLimit(2).multilineTextAlignment(.leading)
      }
      .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
      .padding(.horizontal, CSTokens.Space.gutter)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(title). \(sub)")
  }

  private func reload() async {
    guard let me = store.me, let uid else { return }
    await model.load(me: me, uid: uid, leagueId: leagueId)
    await model.loadBag()
  }

  /// Y-17 · "Some of your card did not load. · Retry" — one line, no banner.
  private var retryLine: some View {
    A11yStack(rowAlignment: .firstTextBaseline, spacing: 0, columnSpacing: 4) {
      Text(YouCopy.partialLine + " ").csType(.bodyS).foregroundStyle(cs.mut)
      Button { Task { await reload() } } label: {
        Text(YouCopy.retry).csType(.bodyS).foregroundStyle(cs.ink).underline().a11yHitSlop()
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Retry loading your card")
    }
    .frame(minHeight: 28)
  }
}

/// D63 · the reunion whisper, as a LINE rather than a card. It is one true
/// fact and one door — the card around it was a container with a job nothing
/// on this page needs (§3.1).
struct LastRoundWithLine: View {
  @Environment(\.cs) private var cs
  let lrw: LastRoundWith
  let stage: ((String, UUID) -> Void)?
  let later: () -> Void

  var body: some View {
    let line = lrw.line()
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      CSRule()
      (Text(line.lead) + Text(line.name).bold() + Text(line.tail))
        .csType(.body).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, CSTokens.Space.s3)
      Text(lrw.sub).csType(.agateS, caps: true).foregroundStyle(cs.mut)
      if let stage {
        CSDoor(.link("Plan a round", { stage(LastRoundWith.nextSaturday(), lrw.profileId) }))
          .padding(.top, CSTokens.Space.s2)
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityAction(named: "Quiet for a while", later)
  }
}

#Preview {
  NavigationStack { YouScreen(leagueId: nil, links: .none) }
    .environment(SessionStore())
    .csTheme()
}
