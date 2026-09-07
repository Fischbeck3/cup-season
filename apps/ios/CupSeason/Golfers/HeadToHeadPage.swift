// Cup Season — HEAD-TO-HEAD, the rivalry as a GRAPHIC (Wave 3,
// `surfaces/profile.md` §10; IOS-032, D239, IA §10.4).
//
// The audit's biggest personality opportunity in the social slice was one
// sentence long: **"a head-to-head between two golfers with neither golfer on
// the page"** (GP-20, P0). The shipped screen opened on an agate section head
// and six facet rows; the two people it was about appeared nowhere above the
// fold.
//
// THE SHAPE: the christened name in gold · `YOU AND GALEN` in `display` 34 ·
// **the graphic** — two 64pt faces at the ends of the measure with the record
// as `figXL` 56 on a 2pt rule between them · the serif sentence that carries
// what the numeral cannot · **THE MEETING TAPE** · the facets on a leaf · one
// primary.
//
// THE TAPE IS THE SURFACE'S SIGNATURE, and the blind review named it *"an
// original scoreboard graphic, one caption away from being unambiguous"*. The
// caption is four words — **One square is one win.** — and there is no legend,
// because §9.10 bans a legend on a chart in the same breath as it bans an axis.
//
// **DEGRADE, stated.** `head_to_head` returns `last_five`, five meetings. The
// tape draws every meeting the payload carries and its dateline says which —
// `LAST FIVE` when that is all there is, which is honest and still a graphic.
// §14.5 owes it `meetings: [{on, won, facet}]`, capped ~24, oldest first.
//
// THREE THINGS THIS PAGE STILL SAYS OUT LOUD, because a record that hides them
// is a record that is quietly wrong: the same-day/same-course fallback is
// LABELLED wherever it contributed, a tag nobody has confirmed says so, and a
// meeting with no verdict is not a tie.

import SwiftUI
import CSDesign
import CupSeasonKit

struct HeadToHeadPage: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  let opponentId: UUID
  /// The name the caller already knows, so the page has a title before the
  /// read lands and never shows a bare "—" in its own header.
  var fallbackName: String?
  var openPerson: (UUID) -> Void = { _ in }
  var stageRound: ((_ playOn: String, _ tag: UUID) -> Void)? = nil

  @State private var model = HeadToHeadModel()
  @State private var naming = false
  @State private var showFacets = false

  private var name: String {
    if let n = model.h2h?.opponent.displayName, !n.isEmpty { return n }
    if let n = model.resolved, !n.isEmpty { return n }
    return fallbackName ?? "them"
  }
  private var first: String {
    name.split(separator: " ").first.map(String.init) ?? name
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        switch model.state {
        case .loading:
          skeleton
        case .failed:
          EmptyRootView(root: EmptyRoot.failedRead()) { _ in Task { await model.load(opponentId, name: fallbackName) } }
        case .empty:
          empty
        case .ready:
          if let h = model.h2h { record(h) }
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.bottom, CSTokens.Space.s6)
      .csPage("head-to-head")
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(cs.bg0)
    // §12.2 · the system bar is the way back and carries one action. **The
    // dateline is removed from this page entirely** — a today-dateline on a
    // rivalry (§10).
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) { CSSafetyMenu(profileId: opponentId, name: name) }
    }
    .refreshable { await model.load(opponentId, name: fallbackName) }
    .task(id: opponentId) { await model.load(opponentId, name: fallbackName) }
    .sheet(isPresented: $naming, onDismiss: { Task { await model.load(opponentId, name: fallbackName) } }) {
      NameRivalrySheet(opponentId: opponentId, opponentName: name, current: model.h2h?.rivalryName)
    }
    .sheet(isPresented: $showFacets) {
      if let h = model.h2h { FacetSheet(h: h, name: name) }
    }
    .sliceToastHost()
  }

  // MARK: - the record

  @ViewBuilder private func record(_ h: HeadToHead) -> some View {
    // M3/D18 · a christened rivalry wears its name, in gold — **the surface's
    // one gold object**, and absent when it is unnamed.
    if let n = h.rivalryName, !n.isEmpty {
      Text(n).csType(.agate, caps: true).foregroundStyle(cs.gold)
        .padding(.top, CSTokens.Space.s3)
        .csBudget(gold: 1)
    }
    Text(HeadToHeadCopy.pageTitle(h)).csType(.display, caps: true).foregroundStyle(cs.ink)
      .lineLimit(2).minimumScaleFactor(0.72)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.top, CSTokens.Space.s2)
      .accessibilityAddTraits(.isHeader)
      .csBudget(display: 1)

    graphic(h).padding(.top, CSTokens.Space.s4)

    // §10 · the serif carries what the numeral cannot: *"He has won the last
    // two."* One serif appearance per viewport (§1.4).
    if let sf = HeadToHeadCopy.standfirst(h) {
      Text(sf).csType(.story).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, CSTokens.Space.s4)
    }

    tape(h)

    // §10 · **the evidence is one tap away.** The viewport cannot hold the
    // hero (6–5), the tape (eleven ticks) and a leaf whose rows sum to 6–5 —
    // that is the same fact three ways on one screen (brief §28 Q7). The hero
    // and the tape stay, because one is the claim and the other is the shape
    // of it; the leaf is the evidence.
    if !h.facets.isEmpty {
      CSDoor(.link("Where it was decided", { showFacets = true }))
        .padding(.top, CSTokens.Space.s4)
    }

    doors(h)
  }

  /// §10 · **the graphic.** Two `CSFace` 64 discs, one at each end of the
  /// measure, with the record between them as `figXL` 56 tabular on a 2pt
  /// `ink` rule — a rule-and-figure at the largest tier the product has.
  ///
  /// **No per-side WINS figures.** The `6–5` says it once, and the shipped
  /// clash said it three times in one viewport (`4 WINS`, `6 WINS`,
  /// `4–6 · HE LEADS`). And the lead line names a SUBJECT — `YOU LEAD` /
  /// `GALEN LEADS` / `ALL SQUARE`, never `HE LEADS`.
  @ViewBuilder private func graphic(_ h: HeadToHead) -> some View {
    CSClash(left: me, leftName: "You",
            right: CSFace.Model(id: h.opponent.id ?? opponentId, marker: h.opponent.marker,
                                initials: Initials.of(h.opponent.displayName)),
            rightName: first,
            leftSub: mySub, rightSub: nil) {
      VStack(spacing: CSTokens.Space.s1) {
        CSFigure(h.record.line, size: .xl, label: nil)
        CSRule(.heavy)
        Text(meetingsLine(h)).csType(.agateS, caps: true).foregroundStyle(cs.mut)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(h.record.line), \(RivalryCopy.leadLabel(h.lead, them: name).lowercased()). \(meetingsLine(h))")
    }
  }

  private func meetingsLine(_ h: HeadToHead) -> String {
    "\(CSCopy.spelled(h.record.total)) meeting\(h.record.total == 1 ? "" : "s")"
  }

  /// §10 · **THE MEETING TAPE.** Every meeting the payload carries, in
  /// chronological order, above the rule when it was yours and below when it
  /// was theirs. The section head carries the ORDER; the tape's own right
  /// margin carries the two row names; one line under it carries the key.
  @ViewBuilder private func tape(_ h: HeadToHead) -> some View {
    let ms = model.meetings
    if !ms.isEmpty {
      ProfileHead("Every meeting", count: model.tapeIsAll ? "Oldest first" : "Last five")
      CSTape(meetings: ms.enumerated().map { .init(id: $0.offset, viewer: $0.element.won) },
             key: "One square is one win.",
             rows: (mine: "Yours", theirs: "Theirs"),
             dates: model.tapeDates,
             spoken: tapeSpoken(h))
        .padding(.top, CSTokens.Space.s3)
    }
  }

  /// ONE VoiceOver element for the whole tape, in the product's voice.
  private func tapeSpoken(_ h: HeadToHead) -> String {
    var s = "\(meetingsLine(h).capitalizedFirst). You won \(CSCopy.spelled(h.record.wins)), \(first) won \(CSCopy.spelled(h.record.losses))."
    if let st = h.streak {
      s += st.mine ? " You have taken the last \(CSCopy.spelled(st.n))."
                   : " \(first) has taken the last \(CSCopy.spelled(st.n))."
    }
    return s
  }

  /// §10 · one primary, and it is the live thing you can do now.
  @ViewBuilder private func doors(_ h: HeadToHead) -> some View {
    VStack(spacing: CSTokens.Space.s3) {
      CSDoor(.primary("Play \(first)", {
        stageRound?(LastRoundWith.nextSaturday(), opponentId)
      }))
      HStack(spacing: CSTokens.Space.s4) {
        CSDoor(.link("\(first)’s card", { openPerson(opponentId) }))
        CSDoor(.link(h.rivalryName == nil ? "Name it" : "Rename it", { naming = true }))
        Spacer()
      }
    }
    .padding(.top, CSTokens.Space.s5)
  }

  // MARK: - the empty

  /// §10 · **this page's biggest win over the shipped void.** The two faces
  /// are still drawn, side by side over the rule, with **no numerals at all**
  /// — never "0–0" — and the door is the REAL primary, never a text link that
  /// toasts *"Add it from the ⊕"* (GP-21).
  @ViewBuilder private var empty: some View {
    Text("Nothing counted yet").csType(.agate, caps: true).foregroundStyle(cs.mut)
      .padding(.top, CSTokens.Space.s4)
    Text(TourCard.youAndThem(name)).csType(.display, caps: true).foregroundStyle(cs.ink)
      .lineLimit(2).minimumScaleFactor(0.72)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.top, CSTokens.Space.s2)
      .accessibilityAddTraits(.isHeader)
      .csBudget(display: 1)
    CSClash(left: me, leftName: "You",
            right: CSFace.Model(id: opponentId, marker: model.marker, initials: Initials.of(model.resolved)),
            rightName: first,
            leftSub: mySub, rightSub: nil) {
      CSRule(.heavy).frame(width: 72)
    }
    .padding(.top, CSTokens.Space.s4)
    Text(HeadToHeadCopy.emptyHead).csType(.lead).foregroundStyle(cs.ink)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.top, CSTokens.Space.s4)
    Text(HeadToHeadCopy.emptySub).csType(.body).foregroundStyle(cs.mut)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.top, CSTokens.Space.s3)
    CSDoor(.primary("Play \(first)", { stageRound?(LastRoundWith.nextSaturday(), opponentId) }))
      .padding(.top, CSTokens.Space.s4)
    HStack {
      CSDoor(.link("\(first)’s card", { openPerson(opponentId) }))
      Spacer()
    }
    .padding(.top, CSTokens.Space.s3)
  }

  private var me: CSFace.Model {
    let p = store.me?.profile
    return CSFace.Model(id: p?.id ?? UUID(), marker: p?.marker,
                        initials: Initials.of(p?.display_name), isViewer: true)
  }

  /// `10.6 index · Tempe` — the two facts a golfer trades in a parking lot,
  /// each dropped rather than guessed.
  ///
  /// **DEGRADE, named.** `head_to_head` returns the opponent's id, name,
  /// handle and marker — no index and no city — so their clause is absent
  /// rather than half-invented. One clause is better than one invented one.
  private var mySub: String? {
    let parts = [store.me?.profile?.index_current.map { "\(CSCopy.index($0)) index" },
                 store.me?.profile?.city?.isEmpty == false ? store.me?.profile?.city : nil]
      .compactMap { $0 }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }

  /// §13.2 · the destination's own geometry, redacted — never a spinner.
  private var skeleton: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
      Text("You and them").csType(.display, caps: true)
      CSClash(left: me, leftName: "You",
              right: CSFace.Model(id: opponentId, marker: nil), rightName: "Them",
              leftSub: nil, rightSub: nil) {
        VStack(spacing: CSTokens.Space.s1) {
          CSFigure("0–0", size: .xl, label: nil)
          CSRule(.heavy)
          Text("Meetings").csType(.agateS, caps: true)
        }
      }
      ProfileHead("Every meeting")
    }
    .padding(.top, CSTokens.Space.s4)
    .csRedacted(true)
  }
}

// MARK: - where it was decided

/// §10 · the six facets as a **printed grid on a leaf**, behind a door.
/// A facet with no data does not render (P-6, L-44) — never "0–0".
struct FacetSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let h: HeadToHead
  let name: String

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          CSPageHeader("Where it was decided", eyebrow: h.record.line)
          CSLeaf {
            HStack(spacing: CSTokens.Space.s3) {
              Text("Facet").csType(.columnS, caps: true).foregroundStyle(cs.leafMut)
                .frame(maxWidth: .infinity, alignment: .leading)
              Text("Met").csType(.columnS, caps: true).foregroundStyle(cs.leafMut)
                .frame(width: 42, alignment: .trailing)
              Text("Record").csType(.columnS, caps: true).foregroundStyle(cs.leafMut)
                .frame(width: 62, alignment: .trailing)
            }
            .accessibilityHidden(true)
            ForEach(Array(h.facets.enumerated()), id: \.element.id) { i, f in
              if i > 0 { CSRule(over: .leaf) }
              row(f)
            }
          }
          .padding(.top, CSTokens.Space.s4)

          // L-19 · a tag says who was out there and nothing about the score.
          // It is printed where the tags are counted.
          if h.facets.contains(where: { $0.facet == .playedTogether }) {
            Text(HeadToHeadCopy.notAVouch).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
              .padding(.top, CSTokens.Space.s3)
          }
        }
        .padding(.horizontal, CSTokens.Space.gutter)
        .padding(.bottom, CSTokens.Space.s6)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(cs.bg0)
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .csCloseButton { dismiss() }
    }
  }

  private func row(_ f: HeadToHead.FacetLine) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
        Text(f.facet.head.capitalizedFirstOnly).csType(.social).foregroundStyle(cs.leafInk)
          .frame(maxWidth: .infinity, alignment: .leading)
        Text(String(f.meetings)).csType(.column).foregroundStyle(cs.leafMut)
          .frame(width: 42, alignment: .trailing)
        if let rec = f.record {
          CSFigure(rec, size: .s, label: nil, over: .leaf)
            .frame(width: 62, alignment: .trailing)
        } else {
          Text("Not settled").csType(.columnS, caps: true).foregroundStyle(cs.leafMut)
            .frame(width: 62, alignment: .trailing)
        }
      }
      if let sub = HeadToHeadCopy.facetSub(f) {
        Text(sub).csType(.agateS, caps: false).foregroundStyle(cs.leafMut)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(minHeight: 44)
    .accessibilityElement(children: .combine)
  }
}

extension String {
  /// `IN THE SEASON` → `In the season`. The facet heads are the tab's own
  /// caps and the leaf sets them in `social`, which is title case for a
  /// phrase a golfer reads rather than a label they scan (§1.3).
  var capitalizedFirstOnly: String {
    guard let f = first else { return self }
    return String(f).uppercased() + dropFirst().lowercased()
  }
}

// MARK: - The model

@MainActor
@Observable
final class HeadToHeadModel {
  enum State { case loading, failed, empty, ready }
  var state: State = .loading
  var h2h: HeadToHead?
  /// True when the record on screen came from `my_rivalries` rather than R4 —
  /// the season-only fallback, which cannot count two buddies with no league.
  var isFallback = false
  /// The name, however it was learnt — the caller's, the payload's, or the
  /// buddies list. A page titled "them" is a page that did not look.
  var resolved: String?
  var marker: String?
  private let people = PeopleService()

  /// **Oldest first**, so a run reads as a run. `last_five` arrives newest
  /// first, which is the order a list wants and the opposite of the order a
  /// chronology wants.
  var meetings: [HeadToHead.Meeting] {
    (h2h?.lastFive ?? []).reversed()
  }

  /// §14.5's degrade, said out loud in the count slot: the payload returns
  /// five, and until it returns every meeting the head says `LAST FIVE`.
  var tapeIsAll: Bool {
    guard let h = h2h else { return false }
    return h.lastFive.count >= h.record.total
  }

  var tapeDates: (first: String, last: String)? {
    let ms = meetings
    guard let f = ms.first, let l = ms.last, f.on != l.on else { return nil }
    return (RivalryCopy.monthDay(f.on), RivalryCopy.monthDay(l.on))
  }

  func load(_ opponent: UUID, name: String?) async {
    resolved = name
    #if DEBUG
    // The tape's own hatch — see `CSDevHatch.h2hFixture`. A fixture, plainly
    // labelled, because the alternative was shipping the wave's signature
    // graphic unphotographed.
    if CSDevHatch.h2hFixture {
      h2h = HeadToHeadModel.fixture(opponent, name: name ?? "Galen")
      marker = h2h?.opponent.marker
      resolved = h2h?.opponent.displayName
      state = .ready
      return
    }
    #endif
    if let h = await people.headToHead(opponent) {
      isFallback = false
      marker = h.opponent.marker
      guard h.visible else { state = .empty; h2h = nil; await resolveName(opponent); return }
      h2h = h
      state = h.record.total > 0 || !h.facets.isEmpty ? .ready : .empty
      if h.opponent.displayName == nil { await resolveName(opponent) }
      return
    }
    // The declared fallback while R4 is unpushed. Its answer is three-valued —
    // a read that did not answer, a read that answered with no record, and a
    // record — and collapsing the middle into the first is what put "Couldn't
    // load this" over a buddy with no shared history on the first screenshot.
    do {
      isFallback = true
      if let h = try await people.headToHeadFallback(opponent, name: name, marker: nil), h.record.total > 0 {
        h2h = h
        marker = h.opponent.marker
        state = .ready
        return
      }
      h2h = nil
      state = .empty
      await resolveName(opponent)
    } catch {
      // L-32 · NEITHER read answered. That is a failed read, not an empty
      // record: "nothing between you yet" over a dead network tells a golfer
      // their record was wiped.
      h2h = nil
      state = .failed
    }
  }

  #if DEBUG
  /// Eleven meetings, six of them the viewer's, with two on the run to the
  /// rival — the shape `profile-h2h.png` draws. DEBUG only.
  static func fixture(_ id: UUID, name: String) -> HeadToHead {
    let days = ["2026-06-14", "2026-06-21", "2026-06-28", "2026-07-05", "2026-07-12",
                "2026-07-19", "2026-07-26", "2026-08-09", "2026-08-23", "2026-09-07", "2026-09-21"]
    let wins: [Bool?] = [true, false, true, true, false, true, false, true, true, false, false]
    let meetings = zip(days, wins).map { HeadToHead.Meeting(on: $0.0, won: $0.1, facet: .clashes) }
    return HeadToHead(visible: true,
                      opponent: .init(id: id, displayName: name, handle: name.lowercased(), marker: "flag"),
                      league: "The Fellas",
                      record: .init(wins: 6, losses: 5, ties: 0, total: 11),
                      lead: .up, since: "2026-06-14",
                      streak: .init(who: "them", n: 2),
                      lastFive: meetings.reversed(),
                      facets: [.init(facet: .seasonWeeks, wins: 3, losses: 1, ties: 0, meetings: 4),
                               .init(facet: .clashes, wins: 2, losses: 2, ties: 0, meetings: 4),
                               .init(facet: .playedTogether, wins: 1, losses: 2, ties: 0, meetings: 3, heuristic: 2)],
                      rivalryName: "The Papago Grudge")
  }
  #endif

  /// The page's title is a person's name, and an empty record still has one.
  /// `my_friends` is the read that already knows it.
  private func resolveName(_ opponent: UUID) async {
    guard resolved == nil || resolved?.isEmpty == true else { return }
    if let lists = try? await people.friends() {
      let hit = (lists.buddies + lists.requested + lists.requests).first { $0.id == opponent }
      resolved = hit?.displayName
      if marker == nil { marker = hit?.marker }
    }
  }
}

#Preview("Head to head") {
  NavigationStack { HeadToHeadPage(opponentId: UUID(), fallbackName: "Galen") }.csTheme()
}
