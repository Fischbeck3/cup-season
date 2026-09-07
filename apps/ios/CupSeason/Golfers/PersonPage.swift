// Cup Season — THE CARD (Wave 2, `surfaces/player-card.md`; IOS-047).
//
// **One object, one chrome, one ratio, one meta string.** The person page and
// the Tour Card were the same golfer told twice — two aspect ratios, two
// identity lines, two records, two sets of words — which is GP-16, the defect
// this file closes. `TourCardSheet` is deleted; this is the surface, and it is
// what `presenter.tourCard` presents and what `openPerson` pushes.
//
// THE SHAPE, top to bottom: the credential · the status sentence · ONE primary
// · FORM · the league · the head-to-head · COURSES · the overlap sentence. The
// card carries only the four facts that are PERMANENT (face, name, number,
// position); the three that move live in the rows beneath it, in the order a
// golfer asks for them. Nothing under the card is boxed — the card is the only
// thing on the screen with depth, which is what makes it an object.
//
// WHAT SURVIVES UNCHANGED, because the audit says the producers and the
// accessibility work are assets: `PersonModel.load`'s card → bag → head-to-head
// cascade, every copy producer it reads, the L-32 failed-is-never-private
// branch, the privacy gate's own words, and R-F's three lengths — which now
// open from the page's ONE primary through `LengthStep` rather than from three
// settings-list rows, so all three are still always offered and the page is no
// longer a form.
//
// WHAT DEGRADES, and it is named rather than faked: the league block needs a
// STANDING. `tour_card` does not carry one — `PersonModel.sharedSeason` was
// declared and read and never once assigned, so THIS SEASON has never rendered
// for anybody — and `me.memberships[].standing` is the viewer's own. So the
// block draws on your own card and is ABSENT on somebody else's, which is
// §6.3's own rule ("each block is independently absent") rather than an
// invented rank.

import SwiftUI
import CSDesign
import CupSeasonKit

struct PersonPage: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @Environment(\.presenter) private var presenter
  @Environment(\.openCompetition) private var openCompetition
  let profileId: UUID
  var openHeadToHead: (UUID) -> Void = { _ in }
  var openReceipt: (UUID) -> Void = { _ in }
  var stageRound: ((_ playOn: String, _ tag: UUID) -> Void)? = nil
  var startSomething: () -> Void = {}
  /// R-F · the golfer, then the length. All three lengths, always — asked as
  /// one step from the page's one primary.
  var playThem: ((TagCandidate) -> Void)? = nil

  @State private var model = PersonModel()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        switch model.state {
        case .loading:
          skeleton
        case .failed(let root):
          EmptyRootView(root: root) { _ in Task { await model.load(profileId) } }
        case .hidden:
          privateCard
        case .card(let load):
          card(load)
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.bottom, CSTokens.Space.s6)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .defaultScrollAnchor(CSDevHatch.bottom ? .bottom : .top)
    .background(cs.bg0)
    // §12.2, half obeyed and half deviated, and the deviation is recorded in
    // the spec: the card's `display` name IS the page's naming object, so a
    // page header would print the name twice and put two `display` roles in
    // one viewport. Empty title, system back, ONE trailing action.
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { ToolbarItem(placement: .topBarTrailing) { shareAction } }
    .refreshable { await model.load(profileId) }
    .task(id: profileId) { await model.load(profileId) }
    .sliceToastHost()
  }

  // MARK: - the object

  @ViewBuilder private func card(_ l: TourCardLoad) -> some View {
    let c = l.card, p = c.profile
    credential(l)
      .padding(.top, CSTokens.Space.s3)

    // ── the status sentence. No round → the line is NOT DRAWN (L-44).
    statusSentence(c)

    // ── the action. One primary, and the tier is chosen by the relationship
    // rather than by the screen.
    action(p)

    formBlock(c)
    leagueBlock(p)
    rivalryBlock(c, name: p.displayName)
    coursesBlock(c, isMe: p.isMe)
    bagBlock(isMe: p.isMe)

    // ── D150's overlap sentence, returned since D150 and thrown away ever
    // since: the reason two golfers start talking.
    if let line = CredentialCopy.overlap(model.sharedCourses) {
      Text(line).csType(.body).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, CSTokens.Space.s4)
    }

    // P-17 · report and mute stay reachable FROM the surface a golfer most
    // often reaches a person on (L-38, Guideline 1.2). They are off the chrome
    // — the toolbar carries the one trailing action the design gives it — and
    // at the page's foot, where a safety act belongs.
    if !p.isMe, let name = p.displayName {
      HStack { Spacer(); CSSafetyMenu(profileId: profileId, name: name); Spacer() }
        .padding(.top, CSTokens.Space.s5)
    }
  }

  @ViewBuilder private func credential(_ l: TourCardLoad) -> some View {
    let c = l.card, p = c.profile
    let golfer = CSCredentialGolfer(
      face: face(p, photo: l.avatarURL),
      name: p.displayName ?? "—",
      identity: CredentialCopy.identity(p),
      slot: slotLabel(p),
      liveTag: nil,
      credit: credit(c, name: p.displayName),
      figures: figures(c),
      club: CredentialCopy.club(markerName: CSMarkers.marker(p.marker).name))
    if let url = l.avatarURL {
      CSCredential(golfer, hasPhoto: true) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let img): img.resizable().scaledToFill()
          default: crestPlate(p)
          }
        }
      }
    } else {
      CSCredential(golfer, hasPhoto: false) { crestPlate(p) }
    }
  }

  /// The marker floor, designed rather than degraded: the contour of their
  /// home course, and their own marker as a crest bleeding off the right edge.
  private func crestPlate(_ p: TourCard.Profile) -> CSCrestPlate {
    let course = p.homeCourse.flatMap { $0.isEmpty ? nil : $0 }
    return CSCrestPlate(marker: p.marker,
                        seed: course ?? profileId.uuidString,
                        hasCourse: course != nil)
  }

  private func face(_ p: TourCard.Profile, photo: URL?) -> CSFace.Model {
    CSFace.Model(id: p.id ?? profileId, marker: p.marker, photoURL: photo,
                 initials: Initials.of(p.displayName), isViewer: p.isMe)
  }

  /// **The slot is the surface's one gold object, and it is absent when
  /// nothing was earned** — then the card carries no gold field at all.
  /// `FoundingBadge.label` ships a `✦`, which LINT-12 fails; the slot takes
  /// the words and the role does the uppercasing.
  private func slotLabel(_ p: TourCard.Profile) -> String? {
    switch store.founding.badge(for: p.id ?? profileId) {
    case .founder: "Founder"
    case .member: "Founding member"
    case nil: nil
    }
  }

  /// `GALEN'S ROUND · AUG 24` — a photograph the product borrowed and a
  /// photograph somebody took are told apart by this line and by nothing else.
  private func credit(_ c: TourCard, name: String?) -> String? {
    guard let r = c.recent.first else { return nil }
    let who = name?.split(separator: " ").first.map(String.init) ?? "Their"
    let day = RivalryCopy.monthDay(r.playedOn)
    return day.isEmpty ? nil : "\(who)’s round · \(day)"
  }

  /// One to three. **A slot with no figure is ABSENT** — never a dash, never a
  /// zero, never a verb. The position figure needs a standing, and the payload
  /// carries one only for the viewer, so somebody else's third cell falls to
  /// their best round, which is a fact the card already holds.
  private func figures(_ c: TourCard) -> [CSCredentialGolfer.Figure] {
    var out: [CSCredentialGolfer.Figure] = []
    if let idx = c.profile.indexCurrent {
      out.append(.init(CSCopy.index(idx), label: "Handicap index"))
    }
    out.append(.init(String(c.career.rounds), label: "Rounds"))
    if c.profile.isMe, let m = standing, let st = m.standing {
      out.append(.init(String(st.rank), label: m.name, ordinal: CSOrdinal.suffix(st.rank)))
    } else if let best = c.bestRound {
      let where_ = best.courseLabel.map { " · " + RoundCopy.course($0) } ?? ""
      out.append(.init(String(best.gross), label: "Best" + where_))
    }
    return out
  }

  /// The viewer's own live membership — the only standing this payload holds.
  private var standing: Me.Membership? {
    store.me?.memberships.first { $0.standing != nil && $0.season?.status == "active" }
      ?? store.me?.memberships.first { $0.standing != nil }
  }

  // MARK: - the sentence and the action

  @ViewBuilder private func statusSentence(_ c: TourCard) -> some View {
    let p = c.profile
    let toEstablish = (p.indexCurrent == nil && c.career.rounds < 3) ? 3 - c.career.rounds : nil
    if p.isMe, c.recent.isEmpty {
      Text(CredentialCopy.mine).csType(.body).foregroundStyle(cs.mut)
        .padding(.top, CSTokens.Space.s4)
    } else if let r = c.recent.first,
              let line = CredentialCopy.status(gross: r.gross, course: r.courseLabel,
                                               playedOn: r.playedOn,
                                               roundsToEstablish: toEstablish, isMe: p.isMe) {
      CSFigureRun(line, role: .body)
        .foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, CSTokens.Space.s4)
    } else if p.isMe {
      Text(CredentialCopy.mine).csType(.body).foregroundStyle(cs.mut)
        .padding(.top, CSTokens.Space.s4)
    }
  }

  /// **One primary, and the alternative is a link** (§16A.5). A buddy gets
  /// `Play Galen` alone; a stranger gets `Add buddy` with `Play Tash` as a
  /// tier-3 link centred under it — two ember-weight decisions side by side is
  /// the thing the blind review filed. A pending ask is a TAG, because there
  /// is nothing to tap that can do anything. **Your own card carries no action
  /// at all, and the screen carries no ember.**
  @ViewBuilder private func action(_ p: TourCard.Profile) -> some View {
    if !p.isMe {
      let first = p.displayName?.split(separator: " ").first.map(String.init) ?? "them"
      VStack(spacing: CSTokens.Space.s3) {
        if model.relation == .friend {
          // a buddy → ONE primary, alone. The settled tag is for a state with
          // nothing to tap; "Buddies" printed over a live primary is a label
          // about the past sitting on top of the page's one live act.
          play(first, tier: .primary)
        } else if let label = model.relation.actionLabel {
          Button(label) { Task { await model.addBuddy(profileId) } }
            .buttonStyle(.csPrimary(busy: model.busyAdd))
          // §16A.5 · the alternative is a LINK, centred, at the same place on
          // every card. Two ember-weight decisions side by side is the thing
          // the blind review filed.
          play(first, tier: .link)
        } else if let tag = model.relation.tag {
          // **a pending ask is a TAG** — there is nothing to tap that can do
          // anything, so nothing is drawn as if there were.
          Text(tag).csType(.agateS, caps: true).foregroundStyle(cs.mut)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(.top, CSTokens.Space.s3)
    }
  }

  private enum Tier { case primary, link }

  @ViewBuilder private func play(_ first: String, tier: Tier) -> some View {
    let take: () -> Void = {
      guard let playThem else { stageRound?(LastRoundWith.nextSaturday(), profileId); return }
      playThem(TagCandidate(id: profileId, name: model.name ?? first, marker: model.marker))
    }
    switch tier {
    case .primary: CSDoor(.primary("Play \(first)", take))
    case .link: HStack { Spacer(); CSDoor(.link("Play \(first)", take)); Spacer() }
    }
  }

  /// `s5` 32 between sections — `CSSectionHead` carries 10 of it itself.
  private func sectionHead(_ title: String, count: String?) -> some View {
    CSSectionHead(title, count: count).padding(.top, CSTokens.Space.s5 - 10)
  }

  // MARK: - FORM

  @ViewBuilder private func formBlock(_ c: TourCard) -> some View {
    let rounds = Array(c.recent.prefix(5))
    if rounds.isEmpty {
      firstCard(c)
    } else {
      sectionHead("Form", count: CredentialCopy.formCount(rounds.count))
      // oldest → newest, left to right, which is how a form line is read.
      let shown = Array(rounds.reversed())
      let best = shown.compactMap(\.gross).min()
      // **Fewer than five rounds → only the rounds that exist, left-flush, on
      // a rule spanning only them.** No blank slots and no em dash: three
      // empty slots make a two-round golfer's row read as a five-round row
      // with failures in it, and the head's count is the honest statement.
      HStack(alignment: .top, spacing: CSTokens.Space.s3) {
        ForEach(Array(shown.enumerated()), id: \.offset) { i, r in
          formColumn(r, best: best != nil && r.gross == best
                             && shown.firstIndex(where: { $0.gross == best }) == i)
        }
        if shown.count < 5 {
          ForEach(shown.count..<5, id: \.self) { _ in Color.clear.frame(height: 1) }
        }
      }
      .padding(.top, CSTokens.Space.s3)
    }
  }

  private func formColumn(_ r: TourCard.Recent, best: Bool) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      CSFigure(r.gross.map(String.init) ?? "—", size: .s,
               metal: best ? .earned : .ink, label: nil)
      CSRule(.heavy, metal: best ? .earned : .ink)
      Text(RivalryCopy.monthDay(r.playedOn)).csType(.agateS, caps: true)
        .foregroundStyle(best ? cs.gold : cs.mut)
        .padding(.top, CSTokens.Space.s1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(r.gross.map(String.init) ?? "no round"), \(RivalryCopy.monthDaySpoken(r.playedOn))\(best ? ", their best" : "")")
  }

  /// §6.2 · a golfer with no rounds. **A fact about the world, never the
  /// golfer's omission**, and the door is required rather than optional.
  @ViewBuilder private func firstCard(_ c: TourCard) -> some View {
    let name = c.profile.displayName
    let first = name?.split(separator: " ").first.map(String.init) ?? "They"
    CSEmpty(glyph: .scorecard,
            eyebrow: "The first card",
            headline: CredentialCopy.firstCard(name: name, since: c.profile.memberSince),
            fact: c.profile.homeCourse.flatMap {
              $0.isEmpty ? nil : "\(RoundCopy.course($0)) is on the board because \(first) keeps it."
            } ?? TourCard.noRoundsYet(name),
            // **The door is required and never nil** — and it is never a
            // second copy of the page's own primary either. `Play Galen` is
            // already the ember above; a second ember pill 300pt below it,
            // with the same verb, is one act offered twice at two weights
            // (§16A.5, and Home's own floor rule from Wave 1). On somebody
            // else's card the block takes `.elsewhere`, which is a reference
            // line rather than a control; on your own card the page carries
            // no action at all, so the door IS the primary.
            door: c.profile.isMe
              ? .primary("Add my round", { presenter.postOnComposer = true; presenter.showPost = true })
              : .elsewhere("Play \(first), and the round they post lands here."))
      .padding(.top, CSTokens.Space.s5)
  }

  // MARK: - the league, the rivalry, the courses

  /// **DEGRADE, stated.** The block draws off `me.memberships[].standing`,
  /// which is the VIEWER's own. `tour_card` carries no `standing` for the
  /// golfer being viewed, so on somebody else's card the whole block is absent
  /// (§6.3) rather than carrying a rank nobody computed.
  @ViewBuilder private func leagueBlock(_ p: TourCard.Profile) -> some View {
    if p.isMe, let m = standing, let st = m.standing {
      sectionHead(m.name, count: weekCount(m))
      CSSlat(rank: st.rank,
             field: .mine,
             face: face(p, photo: nil),
             name: "You",
             sub: countingSub(m),
             movement: movement(st),
             gap: st.gap_to_leader.map { $0 > 0 ? "+\(Int($0))" : "" } ?? "") {
        // the trailing column repeats down a table, so it carries no rule and
        // no label — column position is already the hierarchy (§9.2)
        if let pts = st.points { CSFigure(String(Int(pts)), size: .m, label: nil) }
      }
      .padding(.horizontal, -CSTokens.Space.gutter)
      .padding(.top, CSTokens.Space.s3)
      CSDoor(.link("\(m.name) table", { openCompetition(m.league_id, .table) }))
        .padding(.top, CSTokens.Space.s3)
    }
  }

  private func weekCount(_ m: Me.Membership) -> String? {
    guard let s = m.season, let w = s.week_no, let total = s.weeks_total else { return nil }
    return "Week \(w) of \(total)"
  }

  private func countingSub(_ m: Me.Membership) -> String {
    let cap = m.settings?.counting_cap ?? 0
    guard cap > 0 else {
      return m.standing?.points.map { "\(Int($0)) points" } ?? ""
    }
    return "Best \(cap) count"
  }

  private func movement(_ st: Me.Standing) -> CSMovement.State? {
    guard let prev = st.prev_rank, prev != st.rank else { return nil }
    return prev > st.rank ? .up(prev - st.rank) : .down(st.rank - prev)
  }

  /// The head-to-head, as an overlapping pair rather than as a chip: **no
  /// rail**, because it is not a ranked row.
  @ViewBuilder private func rivalryBlock(_ c: TourCard, name: String?) -> some View {
    let record: (String, String, String)? = {
      if let h = model.h2h, h.record.total > 0 {
        return (h.record.line, RivalryCopy.leadLabel(h.lead, them: name),
                sinceLine(h))
      }
      if let vs = c.vsYou, vs.total > 0 {
        return (vs.record,
                RivalryCopy.leadLabel(vs.wins > vs.losses ? .up : vs.wins < vs.losses ? .down : .even, them: name),
                "\(vs.total) meeting\(vs.total == 1 ? "" : "s") in the seasons you share")
      }
      return nil
    }()
    if let (line, lead, sub) = record, !c.profile.isMe {
      Button { openHeadToHead(profileId) } label: {
        VStack(spacing: 0) {
          CSRule()
          HStack(spacing: 0) {
            Color.clear.frame(width: CSTokens.Space.rail, height: 1)
            CSFaceRow([me(), face(c.profile, photo: nil)], style: .overlapped)
            VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
              Text(TourCard.youAndThem(name)).csType(.name).foregroundStyle(cs.ink)
                .lineLimit(1).truncationMode(.tail)
              Text(sub).csType(.agateS, caps: true).foregroundStyle(cs.mut).lineLimit(1)
            }
            .padding(.leading, CSTokens.Space.s3)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: CSTokens.Space.s1) {
              CSFigure(line, size: .s, label: nil)
              Text(lead).csType(.agateS, caps: true).foregroundStyle(cs.mut)
            }
            .frame(width: 74, alignment: .trailing)
          }
          .frame(minHeight: 52)
        }
      }
      .buttonStyle(.plain)
      .padding(.horizontal, -CSTokens.Space.gutter)
      .padding(.top, CSTokens.Space.s3)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(TourCard.youAndThem(name)). \(line), \(lead.lowercased()). \(sub)")
      .accessibilityHint("Opens the record between you")
    }
  }

  private func sinceLine(_ h: HeadToHead) -> String {
    var s = "\(h.record.total) meeting\(h.record.total == 1 ? "" : "s")"
    if let on = h.since {
      let d = RivalryCopy.monthDaySpoken(on)
      if !d.isEmpty { s += " · since \(d)" }
    }
    return s
  }

  private func me() -> CSFace.Model {
    let p = store.me?.profile
    return CSFace.Model(id: p?.id ?? UUID(), marker: p?.marker,
                        initials: Initials.of(p?.display_name), isViewer: true)
  }

  /// D150's course history — returned since D150 and never rendered here.
  ///
  /// **No thumbnail.** §10.2's drawn card needs real par and stroke index, and
  /// `tour_card.courses[]` carries a NAME and nothing that keys the course
  /// book — so the left column collapses and the name sets flush to the
  /// margin, which is what the system says a course with none of the three
  /// legal images does. Fake bars as ornament are less premium than nothing.
  @ViewBuilder private func coursesBlock(_ c: TourCard, isMe: Bool) -> some View {
    if !c.courses.isEmpty {
      sectionHead("Courses", count: CredentialCopy.coursesCount(c.courses.count))
      VStack(spacing: 0) {
        ForEach(Array(c.courses.prefix(3).enumerated()), id: \.offset) { _, course in
          VStack(spacing: 0) {
            CSRule()
            HStack(alignment: .center, spacing: CSTokens.Space.s3) {
              VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
                Text(RoundCopy.course(course.name)).csType(.social).foregroundStyle(cs.ink)
                  .lineLimit(1).truncationMode(.tail)
                let sub = CredentialCopy.courseSub(
                  city: nil,
                  isHome: c.profile.homeCourse.map { RoundCopy.course($0) == RoundCopy.course(course.name) } ?? false,
                  lastPlayed: course.lastPlayed, isMe: isMe)
                if !sub.isEmpty {
                  Text(sub).csType(.agateS, caps: true).foregroundStyle(cs.mut).lineLimit(1)
                }
              }
              .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
              Text("\(course.rounds) round\(course.rounds == 1 ? "" : "s")")
                .csType(.agateS, caps: true).foregroundStyle(cs.mut)
            }
            .frame(minHeight: 52)
          }
          .accessibilityElement(children: .combine)
        }
      }
      .padding(.top, CSTokens.Space.s3)
      if c.courses.count > 3 {
        CSDoor(.link("All \(c.courses.count) courses", { model.showAllCourses.toggle() }))
          .padding(.top, CSTokens.Space.s3)
      }
      if model.showAllCourses {
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          ForEach(Array(c.courses.dropFirst(3).enumerated()), id: \.offset) { _, course in
            HStack {
              Text(RoundCopy.course(course.name)).csType(.body).foregroundStyle(cs.ink)
              Spacer()
              Text("\(course.rounds)").csType(.column).foregroundStyle(cs.mut)
            }
          }
        }
        .padding(.top, CSTokens.Space.s3)
      }
    }
  }

  /// D262 · R-O · the bag. Drawn only when the read answered AND there is
  /// something in it: an empty "In the bag" head on somebody else's page is a
  /// sentence about them that they did not write (L-44).
  @ViewBuilder private func bagBlock(isMe: Bool) -> some View {
    if let bag = model.bag, !bag.isEmpty {
      sectionHead(BagCopy.head(isMe: isMe), count: "\(bag.clubs.count) clubs")
      if let since = bag.since {
        Text(BagCopy.sinceLine(since, isMe: isMe)).csType(.body).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, CSTokens.Space.s3)
      }
      VStack(spacing: 0) {
        ForEach(bag.clubs) { club in
          bagRow(club.slotLabel.isEmpty ? "Club" : club.slotLabel, club.label)
        }
        if let ball = bag.ball { bagRow("Ball", ball.label) }
      }
      .padding(.top, CSTokens.Space.s3)
      if !bag.sideline.isEmpty {
        Text(bag.sideline.map(\.line).joined(separator: " · "))
          .csType(.agateS, caps: true).foregroundStyle(cs.mut)
          .padding(.top, CSTokens.Space.s3)
      }
    }
  }

  private func bagRow(_ label: String, _ value: String) -> some View {
    VStack(spacing: 0) {
      CSRule()
      HStack {
        Text(label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
        Spacer(minLength: CSTokens.Space.s3)
        Text(value).csType(.body).foregroundStyle(cs.ink).lineLimit(1).truncationMode(.tail)
      }
      .frame(minHeight: 44)
    }
  }

  // MARK: - the other three states

  /// §6.4 · **Private is not an error and is never dressed as one.** The card
  /// renders as its object outline and `TourCard.privateLine` speaks verbatim.
  @ViewBuilder private var privateCard: some View {
    CSCredential(
      CSCredentialGolfer(face: CSFace.Model(id: profileId, marker: nil),
                          name: "", identity: "", figures: [],
                          club: "Cup Season"),
      hasPhoto: false
    ) { CSTokens.dark.ceremony }
      .padding(.top, CSTokens.Space.s3)
    Text("This card is private.").csType(.lead).foregroundStyle(cs.ink)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.top, CSTokens.Space.s4)
    Text(TourCard.privateLine).csType(.body).foregroundStyle(cs.mut)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.top, CSTokens.Space.s3)
    if let label = model.relation.actionLabel {
      Button(label) { Task { await model.addBuddy(profileId) } }
        .buttonStyle(.csPrimary(busy: model.busyAdd))
        .padding(.top, CSTokens.Space.s3)
    }
  }

  /// §6.1 · **the destination's own geometry, redacted.** The card's shape
  /// appearing instantly is the point: the object is what the golfer came for.
  private var skeleton: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSCredential(
        CSCredentialGolfer(face: CSFace.Model(id: profileId, marker: nil),
                            name: "Loading name", identity: "@handle · city · course",
                            figures: [.init("00.0", label: "Handicap index"),
                                      .init("00", label: "Rounds")],
                            club: "Cup Season"),
        hasPhoto: false
      ) { CSTokens.dark.ceremony }
        .padding(.top, CSTokens.Space.s3)
      ForEach(0..<2, id: \.self) { _ in
        CSSectionHead("Section", count: "Count")
        ForEach(0..<3, id: \.self) { _ in
          VStack(spacing: 0) {
            CSRule()
            HStack { Text("A golfer’s row").csType(.name); Spacer() }.frame(minHeight: 52)
          }
        }
      }
    }
    .csRedacted(true)
  }

  /// The one trailing action. **`SHARE`, spelled, in both themes** — a `…` on
  /// the most shareable screen in the app hides the only verb that matters.
  @ViewBuilder private var shareAction: some View {
    if case .card(let l) = model.state {
      ShareLink(item: shareText(l), subject: Text(l.card.profile.displayName ?? "A Cup Season card")) {
        Text("Share")
      }
      .buttonStyle(.csTertiary(.toolbar))
    }
  }

  private func shareText(_ l: TourCardLoad) -> String {
    let p = l.card.profile
    let who = p.isMe ? "My" : "\(p.displayName ?? "A golfer")’s"
    return "\(who) card on Cup Season — \(CredentialCopy.identity(p))"
  }
}

/// The initials a golfer gets when they chose NO marker. There is no initials
/// rung below the marker (§6.2a); this is the "chose nothing" case only.
enum Initials {
  static func of(_ name: String?) -> String {
    let parts = (name ?? "").split(separator: " ").prefix(2)
    return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
  }
}

// MARK: - The model

@MainActor
@Observable
final class PersonModel {
  enum State {
    case loading
    case failed(EmptyRoot)
    case hidden
    case card(TourCardLoad)
  }

  var state: State = .loading
  var relation: BuddyRelation = .none
  var busyAdd = false
  /// R4. nil is either "not read yet" or "the read is not there yet" — either
  /// way the page falls back to `tour_card.vs_you`, which is the season-only
  /// record both clients show today.
  var h2h: HeadToHead?
  var sharedCourses: [String] = []
  /// D262 · nil is "the read did not happen" (no signal, or a database this
  /// migration has not reached) and draws NOTHING — never an empty bag.
  var bag: Bag?
  var isMe = false
  var name: String?
  var marker: String?
  var showAllCourses = false

  private let repo = TourCardRepository()
  private let people = PeopleService()

  /// UNCHANGED (Wave 2 rebuilds the view, not the read): card → bag →
  /// head-to-head, each riding in after the card, so a slow read never holds
  /// the credential back.
  func load(_ id: UUID) async {
    let load: TourCardLoad?
    do { load = try await repo.load(id) } catch { load = nil }
    guard let l = load else {
      // L-32 · a failed read is never a private card. A golfer told "they keep
      // their card private" by a dead network will believe it.
      state = .failed(EmptyRoot.failedRead())
      return
    }
    relation = l.relation
    isMe = l.card.profile.isMe
    name = l.card.profile.displayName
    marker = l.card.profile.marker
    guard l.card.visible else { state = .hidden; return }
    sharedCourses = l.card.sharedCourseNames
    state = .card(l)

    bag = await BagService().load(id)

    guard !l.card.profile.isMe else { return }
    if let h = await people.headToHead(id) {
      h2h = h.visible ? h : nil
    } else {
      h2h = try? await people.headToHeadFallback(id, name: l.card.profile.displayName, marker: l.card.profile.marker)
    }
  }

  func addBuddy(_ id: UUID) async {
    busyAdd = true
    defer { busyAdd = false }
    do {
      if case .incoming(let fid) = relation {
        try await repo.acceptRequest(fid)
        ToastCenter.shared.show("Golf buddies ✓")
        relation = .friend
      } else {
        relation = try await repo.friendRequest(id)
        ToastCenter.shared.show(relation == .friend ? GolfersRoot.BuddyAsk.accepted : GolfersRoot.BuddyAsk.sent)
      }
    } catch { ToastCenter.shared.show(SliceFormat.human(error, "Could not send.")) }
  }
}

#Preview("The card") {
  NavigationStack { PersonPage(profileId: UUID()) }
    .environment(SessionStore())
    .csTheme()
}
