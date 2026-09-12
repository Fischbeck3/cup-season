// Cup Season — COMPETE, the tab root (D222 / R-A, R-D; IOS-028; IA §6.1).
//
// Every season and every moment I am in, as PEERS. The Clubhouse was one room
// with the others behind a swipe; this is a list, and a finished season sits in
// it under its own head with the champion named rather than disappearing the
// moment a live one exists.
//
// The screen decides NOTHING. `CompeteRoot` (Kit) owns the order, the sentences
// and the three states — list, empty and failed — so the rules are tests rather
// than the way this file happens to be written.

import SwiftUI
import CSDesign
import CupSeasonKit

struct CompeteScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(LookStore.self) private var looks
  @Environment(\.presenter) private var presenter
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let links: CSLinks
  var push: (CompeteRoute) -> Void = { _ in }
  var openGolfers: () -> Void = {}
  @State private var buddies: Int?
  @State private var readFailed = false
  @State private var loaded = false

  /// The payload the tab draws. `-cs_dev_compete_fixture` substitutes ONE
  /// VALUE — the `Me` — and nothing else changes: the same `CompeteRoot.make`,
  /// the same heads, the same rows. It is `nil` in Release by construction.
  private var me: Me? {
    #if DEBUG
    if let f = CompeteFixture.me { return f }
    #endif
    return store.me
  }

  private var list: CompeteRoot.List {
    CompeteRoot.make(me, upcoming: me?.upcoming ?? [])
  }

  private var mastheadPalette: CSPalette {
    CSTokens.dark.wearing(looks.personalLook(), theme: .dark)
  }

  private var masthead: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      CSPageHeader("Compete") { EmptyView() }
      Text(CSBrandCopy.tagline.replacingOccurrences(of: "\n", with: " "))
        .csType(.agateS, caps: true).foregroundStyle(mastheadPalette.mut)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(CSTokens.Space.gutter)
    .padding(.vertical, CSTokens.Space.s2)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      ZStack {
        mastheadPalette.bg1
        CSTopoField(tint: mastheadPalette.mut.opacity(CSTokens.Alpha.a24))
      }
    }
    .environment(\.cs, mastheadPalette)
    .padding(.horizontal, -CSTokens.Space.gutter)
    .padding(.bottom, CSTokens.Space.s2)
  }

  var body: some View {
    ScrollView {
      // §4 rule 2 · the gap between two blocks is the block's own, taken at
      // the head that opens it, so a section carries its air with it. The
      // shipped page put 14pt between EVERY child — masthead, head, row, head,
      // row — which is why the two heads read as two more rows.
      VStack(alignment: .leading, spacing: 0) {
        masthead

        switch CompeteRoot.state(list: list, loaded: loaded, readFailed: readFailed, buddies: buddies) {
        case .loading:
          skeleton
        case .failed(let root):
          EmptyRootView(root: root, take: take)
        case .empty(let root):
          EmptyRootView(root: root, take: take)
          // Finished seasons still render under an empty root: "nothing
          // running" is true and "you have never played one" is not.
          section(CompeteRoot.Head.finished, list.finished)
        case .list:
          section(CompeteRoot.Head.seasons, list.seasons, first: true)
          Button { presenter.showIntent = true } label: {
            HStack(spacing: CSTokens.Space.s3) {
              Text("Start something").csType(.name)
              Spacer(minLength: CSTokens.Space.s2)
              CSGlyph(.chevron, size: .row)
            }
            .padding(.horizontal, CSTokens.Space.s4)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
          }
          .buttonStyle(.csPrimary())
          .padding(.top, CSTokens.Space.s3)
          .accessibilityLabel("Start something")
          section(CompeteRoot.Head.moments, list.moments, first: list.seasons.isEmpty)
          section(CompeteRoot.Head.finished, list.finished,
                  first: list.seasons.isEmpty && list.moments.isEmpty)
          foot
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter).padding(.top, 4).padding(.bottom, CSTokens.Space.s5)
    }
    .csLookGround()
    .environment(\.csLook, looks.personalLook())
    .navigationTitle("")
    .toolbar(.hidden, for: .navigationBar)
    // **DF-14 · A FIGURE MAY NOT RENDER UNDER THE CLOCK.** Content scrolled
    // straight under the status bar with no scroll-edge treatment, so at some
    // scroll position on every page a name, a rule or a gross rendered under
    // the time and the Dynamic Island. On the You page it landed on the form
    // row — five grosses on one rule, the object the design is proudest of.
    // The page's own ground fills exactly the top safe area; a surface whose
    // top is a photograph or a contour uses the scrim instead (§10.3).
    .csStatusCap(cs.bg0)
    .refreshable { await store.reload(); await countBuddies() }
    .task(id: store.me?.generated_at) {
      loaded = me != nil
      await countBuddies()
    }
  }

  /// Owner visual refinement: league names and ranks lead; section names
  /// remain the same quiet navigation landmarks. No change to peer ordering.
  @ViewBuilder private func section(_ head: String, _ rows: [CompeteRoot.Row], first: Bool = false) -> some View {
    if !rows.isEmpty {
      CSSectionHead(head, weight: .label)
        .padding(.top, first ? CSTokens.Space.s4 : CSTokens.Space.s5)
        .padding(.bottom, CSTokens.Space.s2)
      ForEach(rows) { row in
        CompeteRowView(row: row) { open(row) }
          .environment(\.csLook, look(row))
      }
    }
  }

  /// Secondary doors stay below the season and moment records. The primary
  /// action is Start something, after Your Seasons; joining and finding
  /// golfers remain quiet, familiar rows separated by a rule.
  private var foot: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSRule(.heavy)
      CSDoorRow(verb: "Join with a code", gloss: "Someone sent you one") {
        CSHaptic.selection()
        CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("join_with_a_code")])
        presenter.join(code: nil)
      }
      CSRule()
      CSDoorRow(verb: "Find golfers", gloss: "The people you play with") {
        CSHaptic.selection()
        CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("find_golfers")])
        openGolfers()
      }
    }
    .padding(.top, CSTokens.Space.s6)
  }

  private func look(_ row: CompeteRoot.Row) -> CSLookSpec? {
    guard let id = row.leagueId, let m = me?.memberships.first(where: { $0.league_id == id }) else { return nil }
    return looks.look(for: m)
  }

  /// Every row is a door, and the object decides which one.
  private func open(_ row: CompeteRoot.Row) {
    if let id = row.leagueId { push(.season(id, pane: .table)); store.preferredLeague = id }
    // D325 · an event is an object and objects are pushed (§7.3). This line
    // and the one above it were the whole bug: two adjacent rows in one list,
    // one pushing a season and one raising a full-screen cover.
    else if let id = row.eventId { push(.event(id)) }
    else if let id = row.roundId { presenter.scheduledRound = id }
  }

  /// L-32 · the empty root's doors, wired to things that exist.
  private func take(_ door: EmptyRoot.Door) {
    switch door {
    case .startSomething: presenter.showIntent = true
    case .joinWithCode:   presenter.join(code: nil)
    case .findGolfers:    openGolfers()
    case .personLink:     openGolfers()
    case .addMyRound:     presenter.postOnComposer = true; presenter.showPost = true
    case .retry:          Task { readFailed = false; await store.reload(); await countBuddies() }
    }
  }

  /// The one true fact the empty root is allowed to print, read once. A read
  /// that fails leaves `buddies` nil, and the fact is then OMITTED rather than
  /// guessed at (L-44) — but the tab itself is not called failed for it: the
  /// seasons come from a payload that already landed.
  private func countBuddies() async {
    guard store.me != nil else { return }
    if let l = try? await PeopleService().friends() { buddies = l.buddies.count }
  }

  /// **LOADING IS THE DESTINATION'S OWN GEOMETRY, REDACTED** (§13.2) — and
  /// this screen was drawing two 68pt rounded rectangles in `bg1`, which is
  /// the audit's finding 1 (a card standing in for content) on the one frame
  /// where nobody would think to look for it. It is now the head and two rows
  /// this page is about to render, in the same type at the same size.
  private var skeleton: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSSectionHead(CompeteRoot.Head.seasons, weight: .label)
        .padding(.top, CSTokens.Space.s4)
        .padding(.bottom, CSTokens.Space.s2)
      ForEach(0..<2, id: \.self) { i in
        CompeteRowView(row: .init(id: "skeleton:\(i)", kind: .season, eyebrow: "Week 8 of 15",
                                  title: "A season you are in", sub: "4 back of the lead",
                                  clock: nil, rank: .init(place: 2, of: 8))) {}
      }
    }
    .csRedacted(true)
  }
}

/// One peer, as a **slat**: the stage eyebrow, the name, the one true
/// sentence — and, on a season, the standing as a rule-and-figure at the
/// trailing edge (D286, `UI_SYSTEM` §9.1/§9.2).
///
/// **THE ROW IS THE PAGE'S SUBJECT AND IT SHIPPED AS THREE GREY LINES.** This
/// is the tab a competitive golfer opens to see where he stands; the standing
/// was the fourth clause of a 12pt mono sentence, drawn no louder than the
/// week or the money. The figure is the same object the leaderboard's rail and
/// the ME strip already are, in the same face at the same size, so a rank
/// reads as a rank everywhere in the product.
///
/// A moment and a weekend carry **no figure** and are quieter for it — `BRIEF`
/// §7: do not make every item visually equal.
private struct CompeteRowView: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let row: CompeteRoot.Row
  let onTap: () -> Void

  /// "2nd of 8" — the row's own standing said the way a person says it, for
  /// VoiceOver, which never hears a rule-and-figure.
  private var spokenRank: String? {
    row.rank.map { " \(CSCopy.ordinal($0.place)) of \($0.of)." }
  }

  var body: some View {
    Button(action: onTap) {
      A11yStack(alignment: .leading, rowAlignment: .center,
                spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s3) {
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          Text(row.title).csType(row.kind == .season ? .displayS : .name).foregroundStyle(cs.ink)
          Text(row.eyebrow).csEyebrow()
          Text(row.sub).csType(.bodyS).foregroundStyle(row.kind == .season ? cs.ink : cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        if let r = row.rank {
          // `fixedSize(horizontal: true)` is the same line the round slat
          // needed: `CSRule` is a bare `Rectangle`, so a figure's stack reads
          // as FLEXIBLE inside an `HStack` and takes an equal share of it —
          // the 2pt rule then runs half the page and the sentence beside it
          // breaks over four lines. The rule is the width of its column (§0.2).
          CSFigure("\(r.place)", size: row.kind == .season ? .l : .m, label: "of \(r.of)",
                   ordinal: CSOrdinal.suffix(r.place))
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 62, alignment: typeSize.isA11y ? .leading : .trailing)
        }
      }
      .padding(.vertical, row.kind == .season ? CSTokens.Space.s4 : CSTokens.Space.s3)
      .frame(minHeight: 68)
      .overlay(alignment: .bottom) { CSRule() }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(row.title), \(row.eyebrow).\(spokenRank ?? "") \(row.sub)")
    .accessibilityHint(row.kind == .season ? "Opens the season" : "Opens it")
    .accessibilityIdentifier("compete.row." + row.id)
  }
}

/// L-32 rendered once, for both tabs: a head, an optional true fact, the line
/// that says what this place is for, and at least one door.
struct EmptyRootView: View {
  @Environment(\.cs) private var cs
  let root: EmptyRoot
  let take: (EmptyRoot.Door) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(root.head).csType(.displayS).foregroundStyle(cs.ink)
      if let fact = root.fact {
        Text(fact).csType(.columnS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
      }
      Text(root.sub).csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
      A11yStack(alignment: .leading, rowAlignment: .firstTextBaseline, spacing: 18, columnSpacing: 14) {
        ForEach(Array(root.doors.enumerated()), id: \.offset) { i, d in
          Button {
            CSHaptic.selection()
            CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string(String(describing: d))])
            take(d)
          } label: {
            // L-25 · the first door wears the ember; the rest are quiet and
            // equally present. Spending ember on every door spends it on none.
            Text(d.title.uppercased()).csEyebrow(i == 0 ? cs.brand : cs.mut).a11yHitSlop()
          }
          .buttonStyle(.plain)
          .accessibilityLabel(d.title)
        }
      }
      .padding(.top, 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, 6)
  }
}

#Preview("Compete") {
  NavigationStack { CompeteScreen(links: CSLinks()) }.csTheme()
}
