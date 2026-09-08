// Cup Season — THE PLAN SHEET, rebuilt in Wave 6 as a title card in a sheet
// (surfaces/event.md §4). *A planned round is the same head as an event, with
// the countdown, the tee time, the field and the weather on one rule.*
//
// WHAT WENT, AND TWO OF THEM WERE `LINT-11` FAILURES ON THE SAME SCREEN:
//
//   · **The gold-tinted weather chip** — a `cs.gold.opacity(0.12)` fill with a
//     gold border, on a fact nobody earned.
//   · **The gold middle RSVP button.** *Gold may never touch a control.* The
//     three-button row is now one primary (**I'm in**), one secondary
//     (**Maybe**) and **"Can't make it"** as a `mut` text link with no rule —
//     a decline is not a control the sheet should advertise. §7.1 is one
//     primary, one secondary, the rest behind a door, and brief §18 names five
//     equally prominent buttons as the anti-pattern.
//   · The `"Done"` in ember at `topBarTrailing`: dismissal is **`Close`**,
//     said one way, everywhere (`LINT-25`).
//   · The bordered course header, the `☀` in the producer's own string, the
//     coloured RSVP pills and `CSCheckRow`.
//
// **`Send the link` moves to the sheet's one trailing toolbar action** (§12.2)
// and the four facts become one `CSScoreRail` on an `ink` rule — `ink`, not
// `brand`, because a plan six days out is not live; it goes `brand` on the day.
//
// EVERYTHING DEGRADES THE WAY §4 SAYS: no weather removes the fourth cell and
// the rule shortens; no tee time removes the second. **It never renders a dash
// and never shows a blank panel.**

import SwiftUI
import CSDesign
import CupSeasonKit

struct ScheduledRoundSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var vm: RoundSheetModel
  @State private var toasts: CSToastCenter
  @State private var retag: RetagRequest? = nil
  @State private var path = NavigationPath()
  @Environment(SessionStore.self) private var store
  let links: CSLinks
  let leagueId: UUID?

  init(roundId: UUID, fallback: ScheduledRound? = nil, leagueId: UUID? = nil, links: CSLinks = CSLinks()) {
    self.links = links
    self.leagueId = leagueId
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: RoundSheetModel(id: roundId, fallback: fallback, toasts: t))
  }

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        if let d = vm.detail {
          sheet(d)
        } else if vm.failed {
          // §7.3 · a sheet with nothing cached speaks once, and ends in a move.
          VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
            Text("That round didn\u{2019}t load.").csType(.lead).foregroundStyle(cs.ink)
            Text("Your phone could not reach the schedule.").csType(.bodyS).foregroundStyle(cs.mut)
            CSDoor(.primary("Try again", { Task { await vm.load() } }))
          }
          .padding(CSTokens.Space.gutter)
        } else {
          // **Loading is the destination's own geometry, redacted** (§13.2).
          sheet(RoundDetail(fallback: SchedulePlan(play_on: CSDate.today(), course_label: "A course"))).csRedacted(true)
        }
      }
      .background(cs.bg0)
      .scrollDismissesKeyboard(.interactively)
      // **Dismiss is one thing: `Close`** — a toolbar tertiary, `mut`, never
      // ember (`LINT-25`). The shipped sheet said "Done" in brand.
      .csCloseButton { dismiss() }
      .task { vm.me = store.me?.profile?.id; await vm.load() }
      .csToasts(toasts)
      .sheet(item: $retag, onDismiss: { Task { await vm.load() } }) { r in RetagSheet(request: r, leagueId: leagueId) }
      // D261 / R-N · the course is pushed from inside this sheet's own stack:
      // an object is pushed, and a sheet on a sheet was the shape the design
      // deleted.
      .navigationDestination(for: CourseSheetRef.self) { c in
        CourseScreen(courseId: c.id, label: c.label)
      }
    }
    .presentationDragIndicator(.visible)
  }

  private func sheet(_ d: RoundDetail) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
      // 1–3 · the eyebrow, the name, the dateline
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        Text("On the schedule").csType(.agate, caps: true).foregroundStyle(cs.mut)
        Text(planName(d)).csType(.display).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityAddTraits(.isHeader)
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          ForEach(Array(dateline(d).enumerated()), id: \.offset) { _, line in
            Text(line).csType(.agate, caps: true).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .accessibilityElement(children: .combine)
      }
      .csBudget(display: 1)

      // D261 / R-N · L-32 · the read failed and this is the row we already had.
      // It is said once, at the top, before any fact it qualifies.
      if vm.stale {
        Text("Cup Season can't reach the desk right now. This is the plan as your phone has it — who is in and the comments may have moved.")
          .csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }

      // 4 · the four figures on ONE rule
      CSScoreRail(facts(d), size: .m, metal: isToday(d) ? .live : .ink)

      // 5 · the weather sentence — a DRAWN glyph at the icon family's stroke,
      // and the producer's own words beside it.
      if let w = vm.weather {
        HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
          CSGlyph(weatherGlyph(w), size: .row).foregroundStyle(cs.mut)
          Text(w.line).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(w.line)
      }

      // 6 · the worth line — verbatim, and nothing at all when the server sends
      // no `worth` key (L-44).
      ForEach(Array(d.worthLines.enumerated()), id: \.offset) { _, worth in
        Text(worth).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      if let n = d.note, !n.isEmpty {
        Text("\u{201C}\(n)\u{201D}").csType(.story).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
      }
      if !d.mine, let r = RivalryTag.of(d.profileId, rivals: vm.rivals) {
        Text(r.text + " · one more round.").csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      // D290 · WHAT YOU ARE ABOUT TO PLAY. The card drawn, the three holes that
      // decide it, the turn, your record here and what your golfers thought —
      // above the field, because it is the reason a golfer opens a plan the
      // night before. Everything comes off the phone's own store, so it is
      // there on a plane (R-N).
      planCourse(d)
      // D261 / R-N · the tees, the ratings and the whole card — from the phone.
      // Offered only for a course this phone has kept, so a door can never
      // open on nothing (L-32).
      if vm.kept, let id = d.courseId {
        CSDoor(.link("The tees and the whole card", {
          path.append(CourseSheetRef(id: id, label: d.courseName))
        }))
      }

      // 7–8 · who's in
      CSSectionHead("Who\u{2019}s in", count: "\(d.inCount) of \(max(d.rsvp.count, d.inCount))")
      if d.rsvp.isEmpty {
        Text("Just you so far — tag your group.").csType(.bodyS).foregroundStyle(cs.mut)
      } else {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(d.rsvp) { r in seat(r, host: r.profileId == d.profileId) }
        }
      }

      // 9 · the stake — body, not serif: the plan is the quieter of the two
      // forfeit surfaces, and the serif is spent on the callout.
      if let terms = stake(d) {
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          Text("On it").csType(.agate, caps: true).foregroundStyle(cs.mut)
          Text(terms).csType(.body).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      // 10 · two marks, not five
      actions(d)

      // the board
      CSSectionHead("On the board", count: d.comments.isEmpty ? nil : "\(d.comments.count)")
      if d.comments.isEmpty {
        Text("No messages yet — kick it off.").csType(.bodyS).foregroundStyle(cs.mut)
      } else {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          ForEach(d.comments) { c in
            HStack(alignment: .top, spacing: CSTokens.Space.s3) {
              CSFace(.seeded(key: c.name, marker: c.marker, initials: Initials.of(c.name)), size: .slat)
              (Text(c.name).bold().foregroundStyle(cs.ink) + Text(" \(c.body)").foregroundStyle(cs.mut))
                .csType(.bodyS)
              Spacer(minLength: 0)
            }
          }
        }
      }
      HStack(spacing: CSTokens.Space.s2) {
        CSField("Say something to the group\u{2026}", text: $vm.draft, font: CSType.body)
          .onChange(of: vm.draft) { _, n in if n.count > 500 { vm.draft = String(n.prefix(500)) } }
          .onSubmit { Task { await vm.send() } }
        Button("Send") { Task { await vm.send() } }.buttonStyle(.csSecondary(busy: vm.sending))
      }

      if d.mine {
        // D253 · the plan link — the host's control alone, because the link is
        // the only thing in the product that can seat a stranger.
        PlanInviteLink(roundId: d.id, course: d.courseLabel, day: d.playOn)
        HStack(spacing: CSTokens.Space.s3) {
          CSDoor(.link("Edit group", {
            retag = RetagRequest(roundId: d.id, iso: d.playOn ?? CSDate.today(), courseLabel: d.courseLabel,
                                 tagged: d.rsvp.compactMap { $0.profileId }.filter { $0 != d.profileId })
          }))
          Spacer(minLength: 0)
        }
        CSArmedButton(label: "Cancel round", armedLabel: "Sure? Cancel it", busy: vm.scratching) {
          Task { if await vm.scratch() { dismiss() } }
        }
      }
    }
    .padding(CSTokens.Space.gutter)
  }

  // MARK: the head's parts

  /// The plan's own name if it has one, else the day and the course. **The
  /// surface never renders an empty title.** `scheduled_rounds.name` (D240) is
  /// not on `round_detail`'s payload, so today this is always the fallback —
  /// which is the branch §4.2 writes for it, not a degrade.
  private func planName(_ d: RoundDetail) -> String {
    if let n = d.name, !n.isEmpty { return n }
    let course = d.course?.name ?? d.courseLabel
    if let c = course, !c.isEmpty, let on = d.playOn {
      return "\(EventDates.weekdayLong(on)) at \(c)"
    }
    return d.title
  }

  private func dateline(_ d: RoundDetail) -> [String] {
    var lines: [String] = []
    var first: [String] = []
    if let on = d.playOn { first.append(ScheduleDates.long(on)) }
    let place = d.course?.place ?? ""
    if let c = d.course?.name ?? d.courseLabel, !c.isEmpty {
      first.append(place.isEmpty ? c : "\(c), \(place)")
    }
    if !first.isEmpty { lines.append(first.joined(separator: " · ")) }
    // the second line is omitted when both facts are absent (§4.3)
    var second: [String] = []
    if let g = d.game, !g.isEmpty { second.append(g) }
    let meta = d.course?.meta ?? ""
    if !meta.isEmpty { second.append(meta) }
    if !second.isEmpty { lines.append(second.joined(separator: " · ")) }
    return lines
  }

  /// §4.4 · `6 / DAYS OUT` · `7:40 / TEE, A.M.` · `3 / IN` · `71° / HIGH`.
  ///
  /// **A cell with no fact is REMOVED and the rule shortens** — it never renders
  /// a dash and the sheet never shows a blank panel.
  // MARK: - D290 · what you are about to play

  /// The owner's own sentence — *"future rounds should highlight holes if we
  /// have that info"* — and we do, for any course whose tee has been cached.
  ///
  /// **THE DEGRADE IS THE POINT** (L-44). No `courseId` (a course typed by
  /// hand) draws nothing at all and the sheet keeps its tee time, its field
  /// and its game. A tee whose card was never cached prints
  /// `CourseBookCopy.noCard`, which already says the right thing, rather than
  /// eighteen invented par 4s: *fake data as ornament is less premium than a
  /// plain colour* — three blind reviewers, in three sentences.
  @ViewBuilder private func planCourse(_ d: RoundDetail) -> some View {
    if d.courseId?.isEmpty == false, let book = vm.book {
      // **THE TEE THE PLAN NAMES, NOT THE LONGEST ONE.** The head above
      // already prints `BLUE · 74.5 / 140 · PAR 72` off `round_detail`, and
      // `defaultTee` returns the longest 18 — so the first build drew GOLD's
      // card under BLUE's rating and put two tees for one round in one
      // viewport (D201). `tee(named:holes:rating:)` returns the PICKED tee or
      // nil, never a near miss, and the fallback is only for a plan whose row
      // carries no tee at all.
      let tee = book.tee(named: d.course?.tee, holes: 18, rating: d.course?.rating) ?? book.defaultTee
      let holes = (tee?.holes ?? []).sorted { $0.hole < $1.hole }
      let drawn = holes.compactMap { h in
        h.par.map { CSDrawnCard.Hole(number: h.hole, par: $0, si: h.si, yards: h.yards) }
      }
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        CSRule()
        if drawn.isEmpty {
          Text(CourseBookCopy.noCard).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        } else {
          Text("The card · " + (tee?.teeName ?? "Tee"))
            .csType(.agateS, caps: true).foregroundStyle(cs.mut)
          CSDrawnCard(drawn).frame(height: 84)
          if let turn = PlanCourseCopy.turn(holes: holes, tee: tee) {
            Text(turn).csType(.columnM).foregroundStyle(cs.mut)
          }
          hardest(drawn)
        }
        if let line = PlanCourseCopy.history(book.label, played: vm.played) {
          Text(line).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        // D289 · the rating, as a PICTURE. The act lives on the course page,
        // where the rail is big enough to carry a legal half-star target.
        if let mine = vm.rating.mine ?? vm.rating.stars {
          HStack(spacing: CSTokens.Space.s2) {
            CSStarRail(mine, size: 18)
            Text(vm.rating.mine != nil
                 ? "Yours " + CSRating.format(mine)
                 : CSRating.format(mine) + " · \(vm.rating.count) rating\(vm.rating.count == 1 ? "" : "s")")
              .csType(.agateS, caps: true).foregroundStyle(cs.mut)
          }
        }
      }
    }
  }

  /// **THE THREE THAT DECIDE IT** — the three lowest stroke indexes as three
  /// figures on one rule, with `PAR 5 · 604 · SI 1` beneath each.
  ///
  /// It is a fact about the CARD and not about the golfer: a scratch player's
  /// three hardest holes are not a bogey golfer's, and the product has no
  /// model that would know the difference. The head says "decide it" rather
  /// than "your three hardest" for exactly that reason.
  @ViewBuilder private func hardest(_ holes: [CSDrawnCard.Hole]) -> some View {
    let three = holes.filter { $0.si != nil }.sorted { ($0.si ?? 99) < ($1.si ?? 99) }.prefix(3)
    if three.count == 3 {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        Text("The three that decide it").csType(.agateS, caps: true).foregroundStyle(cs.mut)
        HStack(alignment: .top, spacing: CSTokens.Space.s4) {
          ForEach(Array(three), id: \.id) { h in
            CSFigure("\(h.number)", size: .m, metal: .ink,
                     label: PlanCourseCopy.hole(par: h.par, yards: h.yards, si: h.si),
                     ordinal: CSOrdinal.suffix(h.number))
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
  }

  private func facts(_ d: RoundDetail) -> [CSScoreRail.Cell] {
    var out: [CSScoreRail.Cell] = []
    if let on = d.playOn, let days = CSDate.days(from: CSDate.today(), to: on) {
      out.append(.init(id: "days", value: String(max(0, days)),
                       label: days == 0 ? "Today" : days == 1 ? "Day out" : "Days out",
                       labelLive: days == 0,
                       spoken: days == 0 ? "Today" : "\(days) days out"))
    }
    let tee = TeeTime.format(d.teeTime)
    if !tee.isEmpty {
      let parts = tee.split(separator: " ", maxSplits: 1).map(String.init)
      out.append(.init(id: "tee", value: parts.first ?? tee,
                       label: parts.count > 1 ? "Tee, \(parts[1])" : "Tee",
                       spoken: "Tee time \(tee)"))
    }
    out.append(.init(id: "in", value: String(d.inCount), label: "In",
                     spoken: "\(d.inCount) in"))
    if let w = vm.weather {
      out.append(.init(id: "hi", value: "\(w.hi)°", label: "High", spoken: "High \(w.hi) degrees"))
    }
    return out
  }

  private func isToday(_ d: RoundDetail) -> Bool { d.playOn == CSDate.today() }

  private func weatherGlyph(_ w: Weather) -> CSGlyph.Name {
    let key = ((w.icon ?? "") + " " + (w.summary ?? "")).lowercased()
    return key.contains("cloud") || key.contains("rain") || key.contains("storm") || key.contains("snow")
      ? .cloud : .sun
  }

  /// The forfeit's own words, if this plan carries one. `forfeits` has no money
  /// column by rule (T-02 / D242), so a stake is a sentence or it is nothing.
  private func stake(_ d: RoundDetail) -> String? {
    guard let n = d.note, n.lowercased().contains("loser") || n.lowercased().contains("buys") else { return nil }
    return n
  }

  // MARK: 8 · the seats

  /// 50pt rows, one rule each · `CSFace` 38 · the name in `social` 17 (title
  /// case — a person in a social row is not the board) · the host's `HOST` in
  /// agate · the answer right-flush in agate: `IN` in `ink`, `ASKED` and `OUT`
  /// in `mut`.
  ///
  /// **`asked` is the state of the INVITATION, never a verdict on the man**
  /// (`PlanIdentity` rule 2) — and there is no chase control here, by rule.
  private func seat(_ r: RoundDetail.Rsvp, host: Bool) -> some View {
    VStack(spacing: 0) {
      CSRule()
      HStack(spacing: CSTokens.Space.s3) {
        // **A seat with no profile draws no disc**, and that is the ladder's own
        // rule rather than a degrade: §6.2a keys a pigment to the GOLFER, and a
        // bare name on a tee sheet is not one yet. Seating it on a pigment
        // derived from its marker is exactly the debt `LINT-31` is ratcheting
        // to zero, so the left column collapses and the name sets flush —
        // §10.2's rule for a course with none of the three legal images.
        if let pid = r.profileId {
          CSFace(CSFace.Model(id: pid, marker: r.marker, initials: Initials.of(r.name)), size: .list)
        }
        Text(r.name).csType(.social).foregroundStyle(cs.ink).lineLimit(1).truncationMode(.tail)
        if host {
          Text("Host").csType(.agateS, caps: true).foregroundStyle(cs.mut)
        }
        Spacer(minLength: CSTokens.Space.s2)
        // **The HOST is not "asked".** A seat with no answer is `ASKED` — the
        // state of the invitation, never a verdict on the man — but the host
        // did the asking, so their own empty answer prints nothing at all
        // rather than a word that is untrue about them.
        if let word = answer(r, host: host) {
          Text(word).csType(.agate, caps: true)
            .foregroundStyle(r.status == "in" ? cs.ink : cs.mut)
        }
      }
      .frame(minHeight: 50)
      .contentShape(Rectangle())
      .onTapGesture { if let p = r.profileId { links.openTourCard?(p) } }
      .accessibilityElement(children: .combine)
    }
  }

  private func answer(_ r: RoundDetail.Rsvp, host: Bool) -> String? {
    if let st = r.status, !st.isEmpty { return r.label }
    return host ? nil : "Asked"
  }

  // MARK: 10 · the actions — two marks, not five

  @ViewBuilder private func actions(_ d: RoundDetail) -> some View {
    if d.canRsvp {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        HStack(spacing: CSTokens.Space.s3) {
          Button("I\u{2019}m in") { Task { await vm.rsvp("in") } }
            .buttonStyle(.csPrimary(busy: vm.rsvping))
            .frame(maxWidth: .infinity)
            .layoutPriority(1.35)
            .accessibilityAddTraits(d.myRsvp == "in" ? .isSelected : [])
          Button("Maybe") { Task { await vm.rsvp("maybe") } }
            .buttonStyle(.csSecondary(busy: vm.rsvping))
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(d.myRsvp == "maybe" ? .isSelected : [])
        }
        // a decline is not a control the sheet should advertise
        Button("Can\u{2019}t make it") { Task { await vm.rsvp("out") } }
          .buttonStyle(.plain)
          .foregroundStyle(cs.mut)
          .accessibilityAddTraits(d.myRsvp == "out" ? .isSelected : [])
      }
    } else if !d.mine {
      // IOS-032 · the dead end, closed. "Ask for a seat" is a REQUEST — one
      // nudge to the host, once per person per plan — and it writes NOTHING to
      // the tee sheet, so D69 stands exactly where it stood.
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        if vm.asked {
          Text("Asked — it\u{2019}s with them").csType(.agate, caps: true).foregroundStyle(cs.mut)
            .frame(minHeight: 44, alignment: .leading)
        } else {
          CSDoor(.secondary("Ask for a seat", { Task { await vm.askForASeat() } }))
        }
        Text("It sends \(d.hostName) a note. Only they can add you to the group.")
          .csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

}

@MainActor
@Observable
final class RoundSheetModel {
  let id: UUID
  var detail: RoundDetail?
  var failed = false
  /// D261 · the detail read did not answer and what is on screen is the row we
  /// already had. Never presented as live.
  var stale = false
  /// D261 · this phone holds a course book for this round's course.
  var kept = false
  var weather: Weather?
  var rivals: [Rpc.my_rivalries.Row] = []
  var draft = ""
  var sending = false
  var rsvping = false
  var scratching = false
  /// IOS-032 · "Ask for a seat" — a REQUEST to the host (R16), never a write
  /// to the tee sheet. `asked` is the local echo of the server's own state.
  var asking = false
  var asked = false
  /// D290 · the course book behind `courseId`, off the phone's own store.
  var book: CourseBook?
  /// Your eighteens at this course, newest first — the raw material for
  /// *"you have played here four times, best 78"*. Empty is a real answer.
  var played: [Int] = []
  var rating = CourseRating.none
  /// The viewer, for the rounds read. Set by the view before `load`.
  var me: UUID?
  private let fallback: ScheduledRound?
  private let toasts: CSToastCenter
  private let sched = ScheduleService()
  private let people = PeopleService()

  init(id: UUID, fallback: ScheduledRound?, toasts: CSToastCenter) { self.id = id; self.fallback = fallback; self.toasts = toasts }

  /// One nudge, once. The server enforces the same rule, so a second tap on
  /// another device is not a second ping either (L-20/L-21).
  func askForASeat() async {
    asking = true
    defer { asking = false }
    do {
      let state = try await people.askForASeat(id)
      asked = true
      toasts.show(state == "already_asked" ? "Already asked — it’s with them."
                : state == "already_in" ? "You’re already in that group."
                : "Asked. It’s up to them now.")
    } catch {
      toasts.show(HumanError.text(error, prefix: "Couldn’t send that."))
    }
  }

  func load() async {
    do { detail = try await sched.detail(id); stale = false }
    catch {
      // deploy-skew OR no signal: `round_detail` is not live yet, or nothing is.
      // Fall back to the schedule row we were handed and SAY the read failed —
      // a screen that quietly draws a thinner version of itself is the lie
      // L-32 forbids (D261).
      if let f = fallback { detail = RoundDetail(fallback: f); stale = true }
      else { failed = true; toasts.show("Couldn’t load that round"); return }
    }
    // D261 · does the phone hold this course? The door below is drawn only if
    // it does, so it can never open on nothing.
    //
    // D290 · and the BOOK itself, because the plan now draws the course rather
    // than linking to it. Off the disk, so it is there with no signal — which
    // is the state a golfer reads a plan in most often (R-N).
    book = await CourseBookStore().book(detail?.courseId).book
    kept = book != nil
    // your record here, and what your golfers thought of it. Both are allowed
    // to answer nothing; neither takes the plan with it (L-32).
    if let cid = detail?.courseId, !cid.isEmpty {
      played = await CoursePageRepository().roundsAt(cid, me: me)
      rating = await CourseRatingService().rating(cid)
    }
    rivals = await RivalsCache.shared.rivals()
    // weather rides in async; no location or out of range → the chip just stays hidden
    if let d = detail, let c = d.course, let lat = c.lat, let lon = c.lon, let on = d.playOn {
      weather = await sched.weather(lat: lat, lon: lon, date: on, courseId: d.courseId)
    } else { weather = nil }
  }

  func rsvp(_ status: String) async {
    rsvping = true; defer { rsvping = false }
    do { try await sched.rsvp(id, status: status); CSHaptic.selection(); await load() }
    catch { toasts.show(HumanError.text(error, prefix: "RSVP did not save.")) }
  }

  func send() async {
    let v = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !v.isEmpty, !sending else { return }
    sending = true; defer { sending = false }
    do { try await sched.comment(id, body: v); draft = ""; await load() }
    catch { toasts.show(HumanError.text(error, prefix: "Could not post.")) }
  }

  func scratch() async -> Bool {
    scratching = true; defer { scratching = false }
    do { try await sched.scratch(id); toasts.show("Round scratched"); return true }
    catch { toasts.show(HumanError.text(error, prefix: "Scratch failed.")); return false }
  }
}

/// Wave 4 · the course is a PATH ELEMENT now, not a sheet item (§7.3: objects
/// are pushed). It kept its name because `MainTabView`'s `"never-kept"`
/// sentinel is written against it and because every caller reads the same two
/// fields; it gained `Hashable` so a `NavigationPath` can carry it.
struct CourseSheetRef: Identifiable, Equatable, Hashable { let id: String; let label: String }

// MARK: - Tag your group (`openRetagSheet` 16852)

struct RetagRequest: Identifiable {
  let roundId: UUID
  let iso: String
  let courseLabel: String?
  let tagged: [UUID]
  var id: UUID { roundId }
}

struct RetagSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var toasts = CSToastCenter()
  @State private var candidates: [TagCandidate] = []
  @State private var loaded = false
  @State private var tagged = Set<UUID>()
  @State private var busy = false
  let request: RetagRequest
  let leagueId: UUID?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        CSSheetHeader(title: "Tag your group", sub: ScheduleDates.long(request.iso) + (request.courseLabel.map { " · \($0.uppercased())" } ?? ""))
        if loaded {
          if candidates.isEmpty { CSFine("No one to tag yet. Add buddies from the Golfers tab.") }
          else { TagChips(candidates: candidates, tagged: $tagged, toasts: toasts) }
          CSFine("\(tagged.count) tagged")
        }
        Button("Save the group") { Task { await save() } }
          .buttonStyle(.csPrimary(busy: busy)).padding(.top, 6)
      }
      .padding(20)
    }
    .background(cs.bg0)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .csToasts(toasts)
    .task {
      candidates = await ScheduleService().tagCandidates(league: leagueId)
      let ids = Set(candidates.map(\.id))
      tagged = Set(request.tagged.filter { ids.contains($0) })
      loaded = true
    }
  }

  private func save() async {
    busy = true; defer { busy = false }
    do { try await ScheduleService().retag(request.roundId, tagged: Array(tagged)); toasts.show("Group updated"); dismiss() }
    catch { toasts.show(HumanError.text(error)) }
  }
}

#Preview("Round") {
  ScheduledRoundSheet(roundId: UUID()).csTheme()
}
