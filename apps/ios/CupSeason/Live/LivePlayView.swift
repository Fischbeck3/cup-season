// Cup Season — THE LIVE SHEET (Wave 7, `surfaces/leaderboard.md` §5).
//
// The most-looked-at surface in the product, and the one the audit scored 4.8
// in portrait against 6.8 for its own landscape card. This is the portrait
// sheet rebuilt to the landscape card's standard, from the status band down.
//
// WHAT WENT, BY NAME: the two capsule chips restating four rows twelve points
// above them; the eighteen ember dots that said how FAR the round was and never
// how it was GOING; the four 4 × 40 colour bars standing in for four people on
// a screen with four people on it; the stacked `55 / THRU / 14 / -1` column
// that broke `THRU` across two lines on an SE; the `− – +` tray whose unscored
// placeholder was an en dash 34pt from the decrement glyph; and the bordered
// side-game card.
//
// WHAT SURVIVES: the 44pt hole targets and the stepper opening on par, the
// wolf's own controls, the two-tap scrap, the group-phones sheet, the sync
// badge (a round held on a phone says so), and D152's landscape card — which
// is the ceiling and is not being redesigned.
//
// THE FOUR NEW OBJECTS: the hole strip with its key (`CSHoleStrip`, chart 4);
// the score object — a bare `figure` 27 over a 2pt rule between two 44pt
// targets, **no ring and no box**, because a circled numeral between a − and a
// + reads as *this field is selected* and the paper convention and the
// selection convention must not be one shape; `TO WIN THIS HOLE`, which is
// what a foursome is actually asking while it stands there; and one full-width
// ember primary, because the live thing a golfer standing on a course can do
// is finish the round.

import SwiftUI
import CSDesign
import CupSeasonKit

struct LivePlayView: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(\.dynamicTypeSize) private var typeSize
  @Bindable var store: LiveRoundStore
  let links: LiveLinks
  @State private var showFinish = false
  @State private var showGroup = false
  @State private var scrapArmed = false
  /// §5.7 · "The scorecard" — the whole card, from the state this phone holds,
  /// so it opens on a course with no signal. In a wide window the CARD toggle
  /// is the same door and this link becomes it.
  @State private var showCard = false
  /// D152 · portrait enters, landscape reads. Offered only when the window is
  /// wide enough for eighteen columns to be legible; a rotation back to portrait
  /// drops it, so nobody can be stranded on a view they cannot leave.
  #if DEBUG
  @State private var cardView = OrientationGate.startsInCardView
  #else
  @State private var cardView = false
  #endif
  @Environment(\.horizontalSizeClass) private var hSize
  @Environment(\.verticalSizeClass) private var vSize

  private var s: LiveRoundState { store.state }
  /// D152 · "is this window wide enough to read eighteen columns".
  /// NOT horizontalSizeClass: an iPhone in landscape is still `.compact`
  /// horizontally on every model except the Max, so gating on that would have
  /// hidden the card on exactly the devices it was built for. A COMPACT
  /// VERTICAL class is the reliable "phone is sideways" signal; `.regular`
  /// horizontal picks up iPad and any genuinely wide window.
  private var canShowCard: Bool {
    #if DEBUG
    if OrientationGate.forceLandscapeForReview { return true }   // headless review
    #endif
    return vSize == .compact || hSize == .regular
  }

  var body: some View {
    Group {
      if cardView && canShowCard {
        VStack(spacing: 0) {
          landscapeBar
          LiveCardView(s: s) { h in
            store.state.hole = h
            cardView = false
          }
        }
      } else if canShowCard {
        // D152 · sideways, the HOLE view must fit on one screen. Two columns,
        // and the teaching copy stands down: it is a first-round explanation,
        // not something anyone reads standing over a putt.
        VStack(spacing: 0) {
          landscapeBar
          landscapeHole
        }
      } else {
        portrait
      }
    }
    .background(cs.bg0)
    // D152 · a rotation back to portrait must never strand anyone on a view the
    // toggle no longer offers.
    .onChange(of: canShowCard) { _, wide in if !wide { cardView = false } }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showFinish) { LiveFinishSheet(store: store) }
    .sheet(isPresented: $showGroup) { LiveGroupSheet(store: store) }
    .sheet(isPresented: $showCard) {
      NavigationStack {
        LiveCardView(s: s) { h in store.state.hole = h; showCard = false }
          .navigationTitle("").navigationBarTitleDisplayMode(.inline)
          .csCloseButton { showCard = false }
      }
    }
  }

  // MARK: - portrait, top to bottom

  private var portrait: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        eyebrow.csGutter()
        holeHeader.csGutter()
        strip.csGutter()
        VStack(spacing: 0) { ForEach(s.players.indices, id: \.self) { playerRow($0) } }
        matchState
        toWinBlock
        gameBlocks.csGutter()
        foot.csGutter()
      }
      .padding(.vertical, CSTokens.Space.s3)
    }
  }

  /// §5.2 · a 7pt `brand` dot and one line: `LIVE · PAPAGO · BLUE · 71.2 / 128`.
  /// **One line, never wrapped** — the tail is dropped before it orphans. The
  /// sync badge rides under it and only when it has something to say: a round
  /// held on a phone with no signal says so (D-offline).
  private var eyebrow: some View {
    let badge = LiveCopy.syncBadge(s, presence: store.presence, queued: store.queued, retired: store.retiredCard)
    return VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      // At the accessibility sizes the dot, the place and the setup link stop
      // fighting for one row: the eyebrow is already the longest line on the
      // screen, and a 44pt link beside it shears it into four words a line.
      A11yStack(rowAlignment: .firstTextBaseline, spacing: CSTokens.Space.s2, columnSpacing: CSTokens.Space.s2) {
        HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
          Circle().fill(cs.brand).frame(width: 7, height: 7)
          Text("Live · " + s.course.place).csType(.agate, caps: true).foregroundStyle(cs.brand)
            .lineLimit(typeSize.isA11y ? nil : 1).truncationMode(.tail)
            .fixedSize(horizontal: false, vertical: true)
        }
        if !typeSize.isA11y { Spacer(minLength: 0) }
        if !store.isPencilOnly {
          Button { store.backToSetup() } label: {
            Text("Change setup").csType(.agateS, caps: true).foregroundStyle(cs.mut).a11yHitSlop()
          }
          .buttonStyle(.plain)
          .fixedSize(horizontal: !typeSize.isA11y, vertical: true)
        }
      }
      if !badge.isEmpty {
        Text(badge).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          .accessibilityAddTraits(.updatesFrequently)
      }
    }
    .csBudget(ember: 1)
    .accessibilityElement(children: .combine)
  }

  /// §5.3 · the screen's ONE `display`, between two 44pt targets.
  private var holeHeader: some View {
    let h = LiveCopy.holeHeader(s)
    return HStack(spacing: CSTokens.Space.s3) {
      holeTarget(back: true)
      VStack(spacing: 2) {
        Text(h.num).csType(.display, caps: true).foregroundStyle(cs.ink)
        Text(h.meta).csType(.agateS, caps: true).foregroundStyle(cs.mut)
      }
      .frame(maxWidth: .infinity)
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isHeader)
      holeTarget(back: false)
    }
  }

  /// The mockup draws the two hole targets as 44pt rounded tiles rather than
  /// the shipped circles, and the score object beside every name draws the same
  /// tile: three targets on one screen, one shape. The chevron is drawn, not an
  /// SF symbol, so it is the same hand as the rest of the family.
  private func holeTarget(back: Bool) -> some View {
    Button { back ? store.prevHole() : store.nextHole() } label: {
      CSGlyph(.chevron, points: 18)
        .rotationEffect(.degrees(back ? 180 : 0))
        .foregroundStyle(cs.ink)
        .frame(width: 44, height: 44)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(back ? "Previous hole" : "Next hole")
  }

  /// §5.4 · chart 4. **This replaces the eighteen ember dots** — same
  /// countability, and it now says *how* the round is going rather than only
  /// how far.
  private var strip: some View {
    let mine = s.players.firstIndex(where: \.me) ?? 0
    let holes = (0..<s.liveHoles).map { i -> CSHoleStrip.Hole in
      let sc = s.scores.indices.contains(mine) ? s.scores[mine][i] : nil
      // N-3's degrade, obeyed: no par, no mark. `LiveCourseCard` guarantees a
      // par per hole today, and a card that ever stops doing so draws ticks.
      return .init(number: i + 1, overPar: sc.map { $0 - s.course.pars[i] })
    }
    let row = LiveCopy.playerRow(s, mine)
    return CSHoleStrip(holes: holes, current: s.hole + 1,
                       trailing: row.total.map { t in
                         "Your card · " + t.lowercased()
                           + (row.notIn > 0 ? " · \(SeasonStoryCopy.word(row.notIn)) not in" : "")
                       } ?? "Nothing in yet")
  }

  // MARK: - a golfer's row and the score object (§5.5, §5.6)

  private func playerRow(_ pi: Int) -> some View {
    let r = LiveCopy.playerRow(s, pi)
    let p = s.players[pi]
    return VStack(spacing: 0) {
      CSRule()
      A11yStack(spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s2) {
        HStack(spacing: CSTokens.Space.s3) {
          CSFace(LiveFaces.model(p), size: .list)
          VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: CSTokens.Space.s2) {
              Text(r.name).csType(.name).foregroundStyle(cs.ink)
                .lineLimit(typeSize.isA11y ? nil : 1).truncationMode(.tail)
              if r.guest { Text("Guest").csType(.agateS, caps: true).foregroundStyle(cs.mut) }
              // the strokes a golfer gets on THIS hole, drawn rather than said
              ForEach(0..<r.strokeDots, id: \.self) { _ in
                Circle().fill(cs.mut).frame(width: 5, height: 5)
              }
            }
            Text(r.sub).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              .lineLimit(typeSize.isA11y ? nil : 1).truncationMode(.tail)
          }
          .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        // §7 · AX3 · the score object goes FULL WIDTH ABOVE the name; at the
        // reading sizes it is the row's trailing column.
        scoreObject(pi, r)
      }
      .padding(.leading, CSTokens.Space.gutter)
      .padding(.trailing, CSTokens.Space.gutter)
      .padding(.vertical, CSTokens.Space.s2)
      .frame(minHeight: 70)
    }
  }

  /// §5.6 · a 44pt decrement target, **the hole's score as `figure` 27 over a
  /// 2pt rule**, a 44pt increment target.
  ///
  /// **The numeral is bare.** No ring, no box: the marks live in the strip
  /// above, where nothing is tappable, and a circled numeral between a − and a
  /// + reads as *this field is selected*.
  ///
  /// **Unscored is an em dash** (the blind review's finding 4). The first draft
  /// hung the hole's par under the rule; three reviewers read it as "they
  /// scored par". Rendering par in the value's own slot IS the guess §9.9
  /// forbids, and a ghost of it under the rule is the same guess quieter.
  private func scoreObject(_ pi: Int, _ r: LiveCopy.PlayerRow) -> some View {
    // 44 + 4 + 54 + 4 + 44 = 150, which leaves the name column 162 at the 402
    // measure — the artboard's own split, and the one that fits
    // `2 STROKES · 55 THRU 14` on one line without an ellipsis.
    HStack(spacing: CSTokens.Space.s1) {
      stepTarget("−", pi: pi, by: -1)
      VStack(spacing: CSTokens.Space.s1) {
        Text(r.score.map(String.init) ?? "\u{2014}")
          .csType(.figureM)
          .foregroundStyle(r.score == nil ? cs.mut : cs.ink)
          .contentTransition(.numericText())
          .frame(minWidth: 44)
        Rectangle().fill(r.score == nil ? cs.rule : cs.ink).frame(height: 2)
      }
      .frame(width: 54)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Hole \(s.hole + 1), \(r.score.map { "\($0) stroke\($0 == 1 ? "" : "s")" } ?? "not scored")")
      .accessibilityAddTraits(.updatesFrequently)
      stepTarget("+", pi: pi, by: 1)
    }
  }

  private func stepTarget(_ glyph: String, pi: Int, by: Int) -> some View {
    Button { store.step(pi, by) } label: {
      Text(glyph).csType(.figureS).foregroundStyle(cs.ink)
        .frame(width: 44, height: 44)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(by < 0 ? "Minus" : "Plus"), \(s.players[pi].n)")
  }

  // MARK: - the match state (§5.7)

  @ViewBuilder private var matchState: some View {
    if let m = LiveCopy.matchCard(s) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        CSRule()
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          Text(m.teams).csType(.agateS, caps: true).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          A11yStack(rowAlignment: .firstTextBaseline, columnSpacing: CSTokens.Space.s2) {
            Text(m.status).csType(.name).foregroundStyle(cs.ink)
              .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CSTokens.Space.s3)
            // "the card" is the person (T-01), so the link says *scorecard*.
            // No arrow: the 2px rule is the affordance (§5.2).
            CSDoor(.link("The scorecard") {
              if canShowCard { cardView = true } else { showCard = true }
            })
          }
          Text(m.meta).csType(.agateS, caps: true).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        .csGutter()
      }
      .accessibilityElement(children: .contain)
    }
  }

  // MARK: - the number to beat (§5, the blind review's finding 4)

  @ViewBuilder private var toWinBlock: some View {
    let rows = LiveCopy.toWinThisHole(s)
    if !rows.isEmpty {
      VStack(spacing: 0) {
        CSSectionHead("To win this hole").csGutter()
        ForEach(rows) { r in
          VStack(spacing: 0) {
            CSRule()
            HStack(spacing: CSTokens.Space.s3) {
              Text(r.mine ? "You" : r.name).csType(.name).foregroundStyle(cs.ink)
                .lineLimit(1).truncationMode(.tail)
              Spacer(minLength: CSTokens.Space.s3)
              Text(r.line).csType(.agateS, caps: false).foregroundStyle(cs.mut)
                .lineLimit(1)
            }
            .csGutter()
            .padding(.vertical, CSTokens.Space.s3)
            .accessibilityElement(children: .combine)
          }
        }
      }
      .padding(.top, CSTokens.Space.s2)
    }
  }

  // MARK: - the games, re-clothed (§10: the bordered card is deleted, not the game)

  @ViewBuilder private var gameBlocks: some View {
    if let w = LiveCopy.wolfCard(s) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        Text("Wolf · lone wolf plays for 3").csType(.agateS, caps: true).foregroundStyle(cs.mut)
        Text(w.who).csType(.name).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
        Text(w.meta).csType(.agateS, caps: true).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
        let pick = s.wolf[s.hole]
        LiveFlow(spacing: CSTokens.Space.s2) {
          ForEach([0, 1, 2, 3].filter { $0 != w.wolf }, id: \.self) { p in
            wolfButton("+ " + s.players[p].n, on: pick?.mode == "partner" && pick?.partner == p) { store.setWolf(.partner(p)) }
          }
          wolfButton("Lone wolf", on: pick?.isLone == true) { store.setWolf(.lone) }
          if pick != nil { wolfButton("Clear", on: false) { store.setWolf(nil) } }
        }
        tally(s.players.indices.map { (s.players[$0].n, LiveFmt.pm(w.pts[$0])) })
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    if let k = LiveCopy.skinsCard(s) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        Text("Skins · ties carry the pot").csType(.agateS, caps: true).foregroundStyle(cs.mut)
        Text(k.status).csType(.name).foregroundStyle(k.hot ? cs.brand : cs.ink)
          .modifier(LiveCarryPulse(on: k.hot))
          .fixedSize(horizontal: false, vertical: true)
        Text(k.meta).csType(.agateS, caps: true).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
        tally(s.players.indices.map { (s.players[$0].n, String(k.won[$0])) })
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    // D273 · money is INK and the sign is a word. The live settlement was a
    // dusk card with an ember spine and gold figures; it is a ruled list now.
    if let rows = LiveCopy.liveSettle(s) {
      VStack(alignment: .leading, spacing: 0) {
        CSSectionHead("Round settlement", count: "live")
        ForEach(Array(rows.enumerated()), id: \.offset) { _, r in
          VStack(spacing: 0) {
            CSRule()
            HStack {
              Text(r.label).csType(.agateS, caps: true).foregroundStyle(cs.ink)
              Spacer()
              Text(r.amount).csType(.columnM).foregroundStyle(cs.ink)
            }
            .padding(.vertical, CSTokens.Space.s2)
            .accessibilityElement(children: .combine)
          }
        }
      }
    }
  }

  private func wolfButton(_ label: String, on: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      CSChip(label, selected: on).frame(minHeight: 44).contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(on ? .isSelected : [])
  }

  /// The running tally: a name and a figure, on the page's own ground.
  /// **`pos`/`neg` never touch it** — a wolf's points are not a P&L (D273).
  private func tally(_ items: [(String, String)]) -> some View {
    Group {
      if typeSize.isA11y {
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          ForEach(Array(items.enumerated()), id: \.offset) { _, it in
            HStack(spacing: CSTokens.Space.s2) {
              Text(it.0).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              Spacer()
              Text(it.1).csType(.figureS).foregroundStyle(cs.ink)
            }
            .accessibilityElement(children: .combine)
          }
        }
      } else {
        HStack(spacing: CSTokens.Space.s3) {
          ForEach(Array(items.enumerated()), id: \.offset) { _, it in
            VStack(spacing: 2) {
              Text(it.1).csType(.figureS).foregroundStyle(cs.ink)
              Text(it.0).csType(.agateS, caps: true).foregroundStyle(cs.mut).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
          }
        }
      }
    }
    .padding(.top, CSTokens.Space.s1)
    .accessibilityAddTraits(.updatesFrequently)
  }

  // MARK: - the foot (§5.8)

  /// **ONE full-width PRIMARY.** On the screen a golfer is holding *while
  /// standing on the course* the live thing they can do is finish the round.
  /// The shipped sheet made it a quiet secondary and left `Close` as the only
  /// underlined control, so the loudest mark on the screen closed it and the
  /// screen had no primary at all. It stays primary at every stage; when cards
  /// are still out it carries the count in its own label and the finish sheet
  /// (which already names the missing holes) is the confirmation.
  @ViewBuilder private var foot: some View {
    if !store.isPencilOnly {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        CSDoor(.primary(finishLabel) { showFinish = true })
        HStack {
          CSDoor(.link("Group phones — everyone can score") { showGroup = true })
          Spacer(minLength: 0)
        }
        if !s.anyScored {
          CSFine("Scores entered together are vouched by the group: the group verifies everyone's round just by playing it. Guests need no account: they play every side game, appear in the settlement, and get a recap text with their scorecard and an invite when you finish. Only league members' rounds post to the season.")
        }
        scrapButton
      }
    }
  }

  /// **A card is OUT when it has a gap BEHIND the group**, not when the round
  /// is unfinished: on the 15th tee every card is missing four holes and none
  /// of them is late. The count is the same `notIn` the rows print, so the
  /// button and the sub-lines can never say different things.
  private var finishLabel: String {
    let out = s.players.indices.filter { LiveCopy.playerRow(s, $0).notIn > 0 }.count
    return out == 0 ? "Finish the round" : "Finish the round · \(out) not in"
  }

  // MARK: - landscape (D152, kept)

  /// The one row landscape keeps above the card: the eyebrow and the toggle.
  private var landscapeBar: some View {
    HStack(spacing: CSTokens.Space.s3) {
      Circle().fill(cs.brand).frame(width: 7, height: 7)
      Text("Live · " + s.course.place).csType(.agateS, caps: true).foregroundStyle(cs.brand)
        .lineLimit(1).truncationMode(.tail)
      Spacer(minLength: CSTokens.Space.s2)
      viewToggle
    }
    .padding(.horizontal, CSTokens.Space.gutter)
    .padding(.vertical, CSTokens.Space.s2)
    .overlay(alignment: .bottom) { CSRule() }
    .csBudget(ember: 1)
  }

  private var landscapeHole: some View {
    HStack(alignment: .top, spacing: CSTokens.Space.s4) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        holeHeader
        strip
        ForEach(s.players.indices, id: \.self) { pi in playerRow(pi) }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        if let m = LiveCopy.matchCard(s) {
          Text(m.teams).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          Text(m.status).csType(.name).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
        }
        ForEach(LiveCopy.toWinThisHole(s)) { r in
          HStack {
            Text(r.mine ? "You" : r.name).csType(.agateS, caps: true).foregroundStyle(cs.ink).lineLimit(1)
            Spacer(minLength: CSTokens.Space.s2)
            Text(r.line).csType(.agateS, caps: false).foregroundStyle(cs.mut).lineLimit(1)
          }
          .accessibilityElement(children: .combine)
        }
        Spacer(minLength: 0)
        if !store.isPencilOnly {
          CSDoor(.primary(finishLabel) { showFinish = true })
        }
      }
      .frame(width: 290)
    }
    .padding(.horizontal, CSTokens.Space.gutter)
    .padding(.top, CSTokens.Space.s3)
    .padding(.bottom, CSTokens.Space.s3)
    .frame(maxHeight: .infinity, alignment: .top)
  }

  /// D152 · HOLE / CARD. Named for what each shows, not for the orientation —
  /// a wide window on any device can read the card, and the phrase "landscape"
  /// means nothing to someone holding one.
  private var viewToggle: some View {
    HStack(spacing: CSTokens.Space.s2) {
      ForEach([false, true], id: \.self) { isCard in
        Button { cardView = isCard } label: {
          CSChip(isCard ? "Card" : "Hole", selected: cardView == isCard)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCard ? "Show the whole card" : "Show this hole")
        .accessibilityAddTraits(cardView == isCard ? [.isSelected] : [])
      }
    }
  }

  // MARK: scrap (two-tap; 9332)

  private var scrapButton: some View {
    Button {
      if scrapArmed {
        scrapArmed = false
        Task { await store.scrap(); links.done() }
      } else { scrapArmed = true; CSHaptic.warning() }
    } label: {
      Text(scrapArmed ? "Tap again to scrap — nothing posts, for anyone" : "Scrap this round")
        .csType(.agateS, caps: true)
        .foregroundStyle(scrapArmed ? cs.neg : cs.mut)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .task(id: scrapArmed) {
      guard scrapArmed else { return }
      try? await Task.sleep(for: .seconds(4))
      scrapArmed = false
    }
  }
}

/// **A live golfer is drawn the one legal way** (D271). A league member is
/// keyed to their profile id; a GUEST has no profile at all and is keyed to
/// their seat, so two guests who both chose the Saguaro still come out as two
/// different coins. Nobody on this screen is a 4pt colour bar any more.
enum LiveFaces {
  static func model(_ p: LivePlayer) -> CSFace.Model {
    if let pid = p.pid {
      return CSFace.Model(id: pid, marker: p.mk, initials: Initials.of(p.n), isViewer: p.me)
    }
    return CSFace.Model.seeded(key: p.id, marker: p.mk, initials: Initials.of(p.n), isViewer: p.me)
  }
}

/// D76 carry-heat: "a breath, not a blink" — the play screen's one pulse.
struct LiveCarryPulse: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduce
  let on: Bool
  @State private var lit = false
  func body(content: Content) -> some View {
    content
      .opacity(on && lit ? 0.72 : 1)
      .animation(on && !reduce ? CSMotion.breath(1.4) : nil, value: lit)
      .onAppear { lit = on }
      .onChange(of: on) { _, v in lit = v }
  }
}

// MARK: - Group phones (9317–9331)

struct LiveGroupSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Bindable var store: LiveRoundStore

  var body: some View {
    let L = store.state
    let guests = L.players.indices.filter { L.players[$0].guest && L.guestTokens[String($0)] != nil }
    SheetFrame("Group phones", sub: "EVERYONE SCORES · IT ALL SYNCS") {
      Text(LiveMarkdown.bold("League members just open the app — a **Continue your round** banner is waiting on Home. \(L.code == nil ? "**Sync is off for this round** (it started before the update) — one phone keeps the card. " : "")Any phone can fix any score; the newest edit wins."))
        .font(CSFont.footnote).foregroundStyle(cs.dimText)
      if guests.isEmpty {
        CSFine("No guests in this round.")
      } else {
        ForEach(guests, id: \.self) { i in
          // the filter above proves the token exists; `if let` keeps that a fact, not an unwrap
          if let tok = L.guestTokens[String(i)] {
          let url = ClaimIntent.url(tok)
          A11yStack(spacing: 10, columnSpacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
              Text(L.players[i].n).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
              Text("No account needed — the link is their pencil now and their recap after").font(CSFont.label).foregroundStyle(cs.dimText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            HStack(spacing: 10) {
            CSMini("Copy") { UIPasteboard.general.string = url.absoluteString; toast.show("Recap link copied") }
              .accessibilityLabel("Copy \(L.players[i].n)'s link")
            ShareLink(item: url, message: Text("Your pencil for today's round on Cup Season")) {
              Image(systemName: "square.and.arrow.up").font(.system(size: 14, weight: .semibold)).foregroundStyle(cs.ink)
                .frame(width: 44, height: 44).background(cs.bg2, in: Circle())
            }
            .accessibilityLabel("Share \(L.players[i].n)'s link")
            }
          }
          .padding(.vertical, 6)
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
  }
}
