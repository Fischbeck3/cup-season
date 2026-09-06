// Cup Season — THE PERSON PAGE (IOS-032, IA §10.3).
//
// Every face in the app opens a Tour Card from twenty-three call sites, and
// the card was a SHEET — a peek, dismissed by a swipe, with nowhere to go
// from it. D222 makes a golfer a destination: the sheet is promoted to a page,
// and the sheet survives for the in-context peek from a round card.
//
// WHAT THE PROMOTION ADDS, beyond a bigger canvas:
//   * a NARRATIVE head — what this golfer has done, and what they have done to
//     you — instead of a stat block a stranger has to assemble themselves
//   * YOU AND <NAME>, which is a DOOR to the head-to-head page rather than a
//     chip that opened a week list
//   * the three lengths (R-F), asked as one step and never guessed
//   * `courses` and `shared_courses`, returned by `tour_card` since D150 and
//     discarded by the phone ever since (`TourCard.swift:93-126`)
//   * P-17, in the toolbar. `TourCardSheet` carries mute and the two-step
//     report today; promoting it to a page without them would drop report and
//     block from the surface a golfer most often reaches a person on, which
//     L-38 forbids and Guideline 1.2 rejects.
//
// EVERY ROW WAITS FOR ITS FACT. TROPHIES and BEST need R21, YOU AND <NAME>
// needs R4, THIS SEASON needs a shared season. A row whose fact did not arrive
// is not drawn as a dash — it is not drawn (L-44).

import SwiftUI
import CSDesign
import CupSeasonKit

struct PersonPage: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @Environment(\.presenter) private var presenter
  @Environment(\.openCompetition) private var openCompetition
  let profileId: UUID
  /// Pushed by the host — the head-to-head page, and the tee sheet with this
  /// golfer already tagged.
  var openHeadToHead: (UUID) -> Void = { _ in }
  var openReceipt: (UUID) -> Void = { _ in }
  var stageRound: ((_ playOn: String, _ tag: UUID) -> Void)? = nil
  var startSomething: () -> Void = {}

  @State private var model = PersonModel()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        switch model.state {
        case .loading:
          skeleton
        case .failed(let root):
          EmptyRootView(root: root) { _ in Task { await model.load(profileId) } }
        case .hidden:
          // the privacy gate, said plainly, with the one door that can change it
          VStack(alignment: .leading, spacing: 10) {
            CSPageHeader(GolfersRoot.CardName.title(model.name), eyebrow: "PRIVATE") { EmptyView() }
            CSFine(TourCard.privateLine)
            if model.relation.actionLabel != nil { buddyAction }
          }
        case .card(let load):
          card(load)
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    // The bar STAYS. A pushed page with `toolbar(.hidden)` has no back button,
    // and the first simulator screenshot of this page was a golfer's card with
    // no way off it — the bar is the back, and P-17 rides its trailing edge
    // where the design puts it ("mounted in the page's overflow").
    .navigationTitle(model.name ?? GolfersRoot.CardName.title(nil))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if !model.isMe, let name = model.name {
        ToolbarItem(placement: .topBarTrailing) { CSSafetyMenu(profileId: profileId, name: name) }
      }
    }
    .refreshable { await model.load(profileId) }
    .task(id: profileId) { await model.load(profileId) }
    .sliceToastHost()
  }

  // MARK: the card

  @ViewBuilder private func card(_ l: TourCardLoad) -> some View {
    let c = l.card, p = c.profile
    let est = p.memberSince.map { TourCard.established($0) }
    let meta = [p.handle.map { "@\($0)" }, p.city, p.homeCourse, est].compactMap { $0 }
      .filter { !$0.isEmpty }.joined(separator: " · ")

    CredentialCard(photoURL: l.avatarURL, marker: p.marker, name: p.displayName ?? "—",
                   badge: store.founding.badge(for: profileId), meta: meta,
                   indexCurrent: p.indexCurrent, rounds: c.career.rounds,
                   trophyLines: TrophyMeta.credChips(c.trophies),
                   form: FormRow.from(beats: c.recent.map(\.beat)),
                   isMe: p.isMe,
                   // F-8 · a 1:1 panel is ~350pt on the biggest iPhone, and with
                   // four identity lines, the index, the buddy chip and the
                   // narrative under it the page's ONLY actions landed below
                   // the tab bar. This is the page `PushRoute.headToHead` lands
                   // a callout on, so it may not ask for a scroll to answer.
                   aspect: 16.0 / 10.0,
                   anchor: { EmptyView() }, extra: { EmptyView() })

    // ── the narrative head. Two clauses, each dropped rather than guessed.
    if let line = HeadToHeadCopy.personNarrative(card: c, h2h: model.h2h) {
      Text(line).font(CSFont.sentence).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 2)
    }

    if !p.isMe { buddyAction }

    // ── R-F · THE THREE LENGTHS, hoisted (F-8). The owner ruled that beating
    // one guy asks how long it runs; that question is the page's ranked
    // action, so it sits above the record rather than under it.
    if !p.isMe { lengths(p.displayName ?? "them") }

    // ── the five rows. Each renders only when its fact arrived.
    VStack(spacing: 0) {
      if let h = model.h2h, h.record.total > 0 {
        CSRow {
          YouDoorRow(glyph: Text("VS"),
                     title: TourCard.youAndThem(p.displayName),
                     sub: youAndThemSub(h),
                     action: { openHeadToHead(profileId) })
            .accessibilityHint("Opens the record between you")
        }
      }
      if let vs = c.vsYou, vs.total > 0, model.h2h == nil {
        // the fallback while R4 is unpushed: the season-only figure the card
        // has always returned, under a label that says which one it is
        CSRow {
          YouDoorRow(glyph: Text("VS"),
                     title: TourCard.youAndThem(p.displayName),
                     sub: "\(vs.record) in the seasons you share",
                     action: { openHeadToHead(profileId) })
        }
      }
      if let seasonRow = model.sharedSeason {
        CSRow {
          YouDoorRow(glyph: Text(Image(systemName: "flag")),
                     title: TourCard.rowThisSeason,
                     sub: seasonRow.sub,
                     action: { openCompetition(seasonRow.leagueId, .table) })
        }
      }
      if !c.recent.isEmpty {
        CSRow { MathRow(label: TourCard.rowLastFive, value: lastFive(c)) }
      }
      // R21 · the best round, as the sentence a golfer says
      if let best = c.bestRound {
        CSRow { MathRow(label: TourCard.rowBest, value: best.line) }
      }
      // R21 · the actual silverware, off the viewed golfer's own trophies
      if !c.cabinet.isEmpty {
        CSRow(last: true) { MathRow(label: TourCard.rowTrophies, value: caseLine(c.cabinet)) }
      }
    }

    // ── the career block, the lens named once (D209), verbatim from the sheet.
    // A golfer with NO rounds gets one true sentence instead of three dashes —
    // the first screenshot of this page was a buddy with an empty card and a
    // column of em dashes, which says nothing three times (L-44).
    if c.career.rounds > 0 {
      Text(TourCard.careerEyebrow(playingLens: c.playingLens, isMe: p.isMe)).csEyebrow().padding(.top, 8)
      VStack(spacing: 0) {
        MathRow(label: TourCard.roundsLabel, value: String(c.career.rounds))
        MathRow(label: TourCard.bestLabel(playingLens: c.playingLens), value: c.bestText)
        MathRow(label: TourCard.avgLabel(playingLens: c.playingLens, isMe: p.isMe), value: c.avgText)
      }
      if !c.playingLens { CSFine(TourCard.careerSignsLine(isMe: p.isMe)).padding(.top, 6) }
    } else {
      CSFine(TourCard.noRoundsYet(p.displayName)).padding(.top, 8)
    }

    // ── D150's two answers, returned since D150 and never rendered here
    if !model.sharedCourses.isEmpty {
      Text("You’ve both played").csEyebrow().padding(.top, 8)
      CSFine(model.sharedCourses.prefix(3).joined(separator: " · ")
             + (model.sharedCourses.count > 3 ? " +\(model.sharedCourses.count - 3) more" : ""))
    }

    if !c.recent.isEmpty {
      Text("Recent rounds").csEyebrow().padding(.top, 8)
      ForEach(c.recent) { r in
        CheckRow(glyph: Text(RivalryCopy.monthDay(r.playedOn)),
                 title: "\(r.gross.map(String.init) ?? "—") GROSS\(r.holesPlayed == 9 ? " · 9 HOLES" : "")",
                 sub: (r.courseLabel.map { RoundCopy.course($0).uppercased() + " · " } ?? "")
                      + "VS COURSE " + (r.differential.map(RoundCopy.f1) ?? "—")) { EmptyView() }
      }
    }
  }

  // MARK: the three lengths (R-F)

  @ViewBuilder private func lengths(_ name: String) -> some View {
    Text(TourCard.lengthsHead).csEyebrow().padding(.top, 12)
    CSFine(TourCard.lengthsSub)
    VStack(spacing: 0) {
      ForEach(Array(TourCard.Length.allCases.enumerated()), id: \.offset) { i, len in
        CSRow(last: i == TourCard.Length.allCases.count - 1) {
          YouDoorRow(glyph: Text(glyph(len)), title: len.label, sub: sub(len),
                     action: take(len))
        }
      }
    }
  }

  private func glyph(_ l: TourCard.Length) -> String {
    switch l { case .saturday: "SAT"; case .week: "WK"; case .season: "SSN" }
  }

  /// R-F: all three are always offered. The one that has no object yet says so
  /// in its own sub rather than being hidden — the owner ruled that the golfer
  /// is asked the length, and a length quietly missing is a guess.
  ///
  /// QB-01 / F-9 · the sentence is `TourCard.weekNotYet` now, produced once in
  /// the Kit for both clients. It no longer teaches the golfer the product's
  /// private noun inside a failure, and it ends in a move.
  private func sub(_ l: TourCard.Length) -> String {
    l == .week ? l.sub + " · " + TourCard.weekNotYet : l.sub
  }

  private func take(_ l: TourCard.Length) -> (() -> Void)? {
    switch l {
    case .saturday:
      guard let stage = stageRound else { return nil }
      return { stage(LastRoundWith.nextSaturday(), profileId) }
    case .week:
      // D237 / R19 is wave 7. A door that does not open is the one thing not
      // permitted (L-32/L-44), so this one says what it is waiting on and
      // does not pretend to mint anything.
      return nil
    case .season:
      return { startSomething() }
    }
  }

  // MARK: bits

  @ViewBuilder private var buddyAction: some View {
    if let tag = model.relation.tag {
      Text(tag).font(CSFont.label).tracking(0.8)
        .foregroundStyle(model.relation == .friend ? cs.pos : cs.mut).padding(.top, 4)
    } else if let label = model.relation.actionLabel {
      CSButton(label, style: .quiet, busy: model.busyAdd) { Task { await model.addBuddy(profileId) } }
    }
  }

  private func youAndThemSub(_ h: HeadToHead) -> String {
    var s = h.record.settled > 0 ? h.record.line + " · " + RivalryCopy.leadLabel(h.lead).lowercased() : ""
    if s.isEmpty { s = "\(h.record.total) together" }
    if HeadToHeadCopy.usesHeuristic(h) { s += " · some matched by day and course" }
    return s
  }

  private func lastFive(_ c: TourCard) -> String {
    let grosses = c.recent.compactMap(\.gross).prefix(5).map(String.init)
    return grosses.isEmpty ? "—" : grosses.joined(separator: " · ")
  }

  private func caseLine(_ cabinet: [TourCard.Cabinet]) -> String {
    let lines = cabinet.compactMap(\.line)
    guard !lines.isEmpty else { return "—" }
    return lines.prefix(3).joined(separator: " · ") + (lines.count > 3 ? " +\(lines.count - 3)" : "")
  }

  private var skeleton: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(0..<4, id: \.self) { _ in
        RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(cs.bg1).frame(height: 56)
      }
    }
    .redacted(reason: .placeholder)
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
  var sharedSeason: SharedSeason?
  var isMe = false
  var name: String?

  struct SharedSeason { let leagueId: UUID; let sub: String }

  private let repo = TourCardRepository()
  private let people = PeopleService()

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
    guard l.card.visible else { state = .hidden; return }
    sharedCourses = l.card.sharedCourseNames
    state = .card(l)

    guard !l.card.profile.isMe else { return }
    // R4 rides in after the card — the page is useful without it, and a slow
    // read never holds the credential back.
    if let h = await people.headToHead(id) {
      h2h = h.visible ? h : nil
    } else {
      // the declared fallback; a read that answers with no record leaves the
      // row off the page rather than putting an error on a card that loaded
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

#Preview("Person") {
  NavigationStack { PersonPage(profileId: UUID()) }
    .environment(SessionStore())
    .csTheme()
}
