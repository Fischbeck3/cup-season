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

  /// D314 · the league the plate is seeded from — the first live season's, then
  /// the first finished one's, then the golfer. `nil` only when there is
  /// neither, and then no plate is drawn rather than one seeded from nothing.
  private var plateSeed: String? {
    let l = list
    let league = (l.seasons.first(where: { $0.leagueId != nil })
                  ?? l.finished.first(where: { $0.leagueId != nil }))?.leagueId
    return league?.uuidString ?? me?.profile?.id.uuidString
  }

  var body: some View {
    ScrollView {
      // §4 rule 2 · the gap between two blocks is the block's own, taken at
      // the head that opens it, so a section carries its air with it. The
      // shipped page put 14pt between EVERY child — masthead, head, row, head,
      // row — which is why the two heads read as two more rows.
      VStack(alignment: .leading, spacing: 0) {
        // **D314 · COMPETE STANDS SOMEWHERE.** The contour plate is a real
        // generator — seeded value noise, marching squares, five to seven
        // isolines, *"same course, same plot, forever"* — and it draws behind
        // the credential's crest and on the course hero. Compete called it
        // NOWHERE, which is why the tab a season lives in looked like a list.
        //
        // **Behind the page head, at hero scale, and only there.** The system
        // BANS the contour at thumbnail scale in its own words — small, it
        // reads as three near-identical concentric ovals — so a plate per
        // season CARD was rejected on the existing rule rather than on taste.
        //
        // **Seeded from the league**, so the Fellas and Who's the bitch? are
        // two places and each is the same place every time. With no league at
        // all it falls to the golfer's own id, which is exactly what the
        // person card does when a golfer has no home course. **A league is not
        // a course**: the plot means nothing about the golf, it is identity and
        // not information, and no copy on this page claims otherwise — which
        // is also why it carries NO `mark` (there is no hole to point at).
        CSPageHeader("Compete", eyebrow: CSHeaderDate.today()) {
          // IA §6.1 · one primary door at the head — and it is the page's ONE
          // ember (L-25), which is why the foot's two doors are quiet.
          //
          // **THE ARROW IS GONE, AND IT WAS BREAKING THE HEAD.** `START
          // SOMETHING ↗` measures wider than the 362pt measure leaves beside
          // `COMPETE` and `MON · SEP 7`, so the glyph wrapped onto a second
          // line under the words and sat beside the dateline. It was also the
          // only typed arrow left in the phone: `LINT-13` deletes them by name
          // — *movement is a drawn mark; a link's arrow is absorbed into its
          // underline* — and this was the one that got away.
          Button { presenter.showIntent = true } label: {
            Text("START SOMETHING").csEyebrow(cs.brand).lineLimit(1).fixedSize().a11yHitSlop()
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Start something")
        }
        .background(alignment: .top) {
          if let seed = plateSeed {
            // **CLIPPED, because the field draws past its frame.** `CSContour`
            // strokes isolines in its own coordinate space and a `frame(height:)`
            // alone does not stop them: the first build ran the curves down
            // through YOUR SEASONS and behind the first two season rows, where
            // a 24%-opacity line crossing a 17pt name is legibility spent on
            // texture. It clips to the head's own measure.
            //
            // `.clipped()` clips DRAWING and not touches (D301) — which is why
            // `allowsHitTesting(false)` is here too and not instead.
            // **THE TOPO FOLLOWS THE LIVERY** (owner: *"topo can follow
            // themes"*). Under a look the field takes the accent; on homebase
            // it is `mut`, the neutral it has always been. It is the ACCENT and
            // not the second colour: the panel and the tick already carry
            // accent2, and a third object in it would be the wash D270 deleted
            // arriving as a texture.
            CSContour(seed: seed, tint: (la.active ? la.accent : cs.mut).opacity(CSTokens.Alpha.a08))
              .frame(maxWidth: .infinity)
              .frame(height: 132)
              .clipped()
              .allowsHitTesting(false)
              .accessibilityHidden(true)
          }
        }

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

  /// **THE HEAD IS A REAL STEP, AND IT IS THE PRODUCT'S ONE HEAD** (D286).
  ///
  /// `YOUR SEASONS` shipped as `csEyebrow` — mono 12 tracked caps in `mut` —
  /// over rows whose own name was 17pt caps in `ink`. The head was the
  /// QUIETEST thing in its own section, so the page read as one flat list with
  /// two labels in it. `CSSectionHead(.display)` is `displayS` 24 in `ink`:
  /// the same object Home's wire runs its datelines under, used here for the
  /// second time, which is what makes it an idiom rather than a one-off.
  @ViewBuilder private func section(_ head: String, _ rows: [CompeteRoot.Row], first: Bool = false) -> some View {
    if !rows.isEmpty {
      CSSectionHead(head, weight: .display)
        .padding(.top, first ? CSTokens.Space.s4 : CSTokens.Space.s5)
        .padding(.bottom, CSTokens.Space.s2)
      if rows.contains(where: { $0.rank != nil }) {
        CSCompetitionBand {
          ForEach(rows) { row in
            CompeteRowView(row: row) { open(row) }
              .environment(\.csLook, look(row))
          }
        }
        .padding(.horizontal, -CSTokens.Space.gutter)
      } else {
        ForEach(rows) { row in
          CompeteRowView(row: row) { open(row) }
            .environment(\.csLook, look(row))
        }
      }
    }
  }

  /// **THE FOOT — AND THE HONEST ANSWER TO A SCREEN AND A HALF OF NOTHING.**
  ///
  /// A golfer with two seasons and one moment has a short page, and the space
  /// under it is not a design problem to be filled: §27 forbids decorative UI
  /// with no purpose, and §32 forbids answering it with a card. What the space
  /// IS good for is the two acts this tab offers that the masthead does not —
  /// and the masthead's door is at the top-right corner of a phone, which is
  /// the one place a thumb cannot reach.
  ///
  /// So: `s6` (§4's own token — *before a ceremony or a page foot*), a heavy
  /// rule, and the two doors `CompeteRoot.empty` already names as the
  /// alternatives to starting something. **Neither is lit**: L-25 allows the
  /// page exactly one ember and the masthead is wearing it, so a second one
  /// here would spend it on nothing. Everything below them stays empty, which
  /// is what a short page should look like.
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
      CSSectionHead(CompeteRoot.Head.seasons, weight: .display)
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
        if let r = row.rank {
          // `fixedSize(horizontal: true)` is the same line the round slat
          // needed: `CSRule` is a bare `Rectangle`, so a figure's stack reads
          // as FLEXIBLE inside an `HStack` and takes an equal share of it —
          // the 2pt rule then runs half the page and the sentence beside it
          // breaks over four lines. The rule is the width of its column (§0.2).
          CSFigure("\(r.place)", size: .m, label: "of \(r.of)",
                   ordinal: CSOrdinal.suffix(r.place))
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 62, alignment: typeSize.isA11y ? .leading : .trailing)
        }
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          Text(row.eyebrow).csEyebrow()
          Text(row.title).csType(.name).foregroundStyle(cs.ink)
          Text(row.sub).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)

      }
      .padding(.vertical, CSTokens.Space.s4)
      .padding(.horizontal, row.rank == nil ? 0 : CSTokens.Space.gutter)
      .frame(minHeight: 68)
      .overlay(alignment: .bottom) { CSRule() }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(row.title), \(row.eyebrow).\(spokenRank ?? "") \(row.sub)")
    .accessibilityHint(row.kind == .season ? "Opens the season" : "Opens it")
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
