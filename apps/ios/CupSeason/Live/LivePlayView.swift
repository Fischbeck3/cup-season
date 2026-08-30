// Cup Season — `#playLive` (index.html 3039–3094; `renderPlay` 8386–8589,
// `renderScoreboard` 8604–8654 (D85), the group sheet 9317–9331, the
// two-tap scrap 9332–9364).

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
    VStack(spacing: 0) {
      scoreboard
      if cardView && canShowCard {
        LiveCardView(s: s) { h in
          store.state.hole = h
          cardView = false
        }
      } else if canShowCard {
        // D152 · sideways, the HOLE view must fit on one screen. The portrait
        // stack — eyebrow, header, dots, four rows, two buttons, the
        // auto-attest paragraph, scrap, then the side games — is far taller
        // than 390pt, so rotating used to hand you a scroll. Two columns, and
        // the teaching copy stands down: it is a first-round explanation, not
        // something anyone reads standing over a putt.
        landscapeHole
      } else {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          A11yStack(rowAlignment: .firstTextBaseline, columnSpacing: 4) {
            Text(s.course.eyebrow).csEyebrow().lineLimit(typeSize.isA11y ? nil : 2)
            Spacer()
            if !store.isPencilOnly {
              Button { store.backToSetup() } label: {
                Text("Change setup").font(CSFont.footnote).foregroundStyle(cs.dawn).a11yHitSlop()
              }
              .buttonStyle(.plain)
            }
          }
          holeHeader
          holeDots
          ForEach(s.players.indices, id: \.self) { pi in playerRow(pi) }
          if !store.isPencilOnly {
            CSMini("Group phones — everyone can score") { showGroup = true }
            CSButton("Finish round & post to season", busy: store.busy) { showFinish = true }
            CSFine("Scores entered together are auto-attested: the group verifies everyone's round just by playing it. Guests need no account: they play every side game, appear in the settlement, and get a recap text with their scorecard and an invite when you finish. Only league members' rounds post to the season.")
            scrapButton
          }
          Text("Side games · tracked live, settled between you").csEyebrow().padding(.top, 8)
          gameCards
        }
        .padding(20)
      }
      }
    }
    .background(cs.bg0)
    // D152 · a rotation back to portrait must never strand anyone on a view the
    // toggle no longer offers.
    .onChange(of: canShowCard) { _, wide in if !wide { cardView = false } }
    .navigationTitle("Live round")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showFinish) { LiveFinishSheet(store: store) }
    .sheet(isPresented: $showGroup) { LiveGroupSheet(store: store) }
  }

  // MARK: the scoreboard (D85)

  private var scoreboard: some View {
    let sb = LiveCopy.scoreboard(s, presence: store.presence)
    return VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        Text(sb.hero).font(CSFont.monoMediumBody).tracking(0.6).foregroundStyle(cs.ink).lineLimit(2)
        Spacer(minLength: 8)
        if canShowCard { viewToggle }
      }
      // D152 · sideways, the chips stand down in BOTH views. In CARD they are
      // restated by the table underneath — every score, every total, hole by
      // hole. In HOLE they are restated by the four rows, which carry the same
      // name / thru / net. A landscape phone has ~380pt to spend and the chips
      // cost 40 of them; spent there, the last player's row falls off the
      // bottom (it did — SwiftUI overflows a too-tall VStack symmetrically, so
      // the toggle went off the TOP at the same time and read as "missing").
      if !canShowCard {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          ForEach(Array(sb.chips.enumerated()), id: \.offset) { _, c in
            HStack(spacing: 6) {
              if c.present { Circle().fill(cs.pos).frame(width: 6, height: 6) }
              Text(c.name).font(CSFont.monoMediumBody).foregroundStyle(c.lead ? cs.gold : cs.ink)
              Text(c.line).font(CSFont.label).foregroundStyle(cs.mut)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(cs.bg2, in: Capsule())
            .overlay(Capsule().stroke(c.lead ? cs.gold : cs.line2, lineWidth: 1))
          }
        }
      }
      }
      if !(cardView && canShowCard) {
        Text(LiveCopy.syncBadge(s, presence: store.presence, queued: store.queued)).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
      }
    }
    .padding(.horizontal, 20).padding(.vertical, canShowCard ? 7 : 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg1)
    .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.updatesFrequently)   // the scoreboard moves as the group scores
  }

  /// D152 · the hole, sideways: entry left, the games right, nothing scrolling.
  private var landscapeHole: some View {
    HStack(alignment: .top, spacing: 16) {
      VStack(alignment: .leading, spacing: 6) {
        holeHeader
        holeDots
        ForEach(s.players.indices, id: \.self) { pi in playerRow(pi) }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .leading, spacing: 8) {
        gameCards
        Spacer(minLength: 0)
        if !store.isPencilOnly {
          CSButton("Finish & post", busy: store.busy) { showFinish = true }
        }
      }
      .frame(width: 290)
    }
    .padding(.horizontal, 20)
    .padding(.top, 10)
    .padding(.bottom, 12)
    .frame(maxHeight: .infinity, alignment: .top)
  }

  /// D152 · HOLE / CARD. Named for what each shows, not for the orientation —
  /// a wide window on any device can read the card, and the phrase "landscape"
  /// means nothing to someone holding one.
  private var viewToggle: some View {
    HStack(spacing: 0) {
      ForEach([false, true], id: \.self) { isCard in
        Button { cardView = isCard } label: {
          Text(isCard ? "CARD" : "HOLE")
            .font(CSFont.label).tracking(0.8)
            .foregroundStyle(cardView == isCard ? cs.bg0 : cs.dim)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(cardView == isCard ? cs.brand : .clear)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCard ? "Show the whole card" : "Show this hole")
        .accessibilityAddTraits(cardView == isCard ? [.isSelected] : [])
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 7))
    .overlay(RoundedRectangle(cornerRadius: 7).stroke(cs.line2, lineWidth: 1))
  }

  // MARK: hole header + dots

  private var holeHeader: some View {
    let h = LiveCopy.holeHeader(s)
    return HStack {
      Button { store.prevHole() } label: {
        Image(systemName: "arrow.left").font(.system(size: 16, weight: .semibold)).foregroundStyle(cs.ink).frame(width: 44, height: 44)
          .background(cs.bg2, in: Circle())
      }
      .buttonStyle(.plain).accessibilityLabel("Previous hole")
      Spacer()
      VStack(spacing: 2) {
        Text(h.num).font(CSFont.heroSmall).foregroundStyle(cs.ink)
        Text(h.meta).font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText)
      }
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isHeader)
      Spacer()
      Button { store.nextHole() } label: {
        Image(systemName: "arrow.right").font(.system(size: 16, weight: .semibold)).foregroundStyle(cs.ink).frame(width: 44, height: 44)
          .background(cs.bg2, in: Circle())
      }
      .buttonStyle(.plain).accessibilityLabel("Next hole")
    }
  }

  private var holeDots: some View {
    HStack(spacing: 4) {
      ForEach(0..<s.liveHoles, id: \.self) { k in
        Circle()
          .fill(s.holeDone(k) ? cs.brand : cs.line2)
          .frame(width: k == s.hole ? 10 : 6, height: k == s.hole ? 10 : 6)
          .overlay(Circle().stroke(k == s.hole ? cs.ink : .clear, lineWidth: 1))
          .frame(maxWidth: .infinity)
      }
    }
    .accessibilityHidden(true)
  }

  // MARK: player rows (8409–8441)

  private func playerRow(_ pi: Int) -> some View {
    let r = LiveCopy.playerRow(s, pi)
    let p = s.players[pi]
    let scoreText = r.score.map(String.init) ?? "–"
    // name + sub, then the totals and the stepper — on one line, or two at the accessibility sizes
    return A11yStack(spacing: 10, columnSpacing: 6) {
      HStack(spacing: 10) {
        RoundedRectangle(cornerRadius: 2).fill(p.guest ? cs.dim : cs.squad(p.ci)).frame(width: 4, height: 40)
        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 4) {
            Text(r.name).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink).lineLimit(typeSize.isA11y ? nil : 1)
            if r.guest { Text("GUEST").font(CSFont.label).foregroundStyle(cs.dimText) }
            ForEach(0..<r.strokeDots, id: \.self) { _ in Circle().fill(cs.gold).frame(width: 6, height: 6) }
          }
          Text(r.sub).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel("\(r.name)\(r.guest ? ", guest" : ""), \(r.sub)" + (r.strokeDots > 0 ? ", \(r.strokeDots) stroke\(r.strokeDots == 1 ? "" : "s") here" : ""))
      Spacer(minLength: 4)
      HStack(spacing: 10) {
        VStack(alignment: .trailing, spacing: 0) {
          Text(r.total ?? "—").font(CSFont.label).foregroundStyle(cs.mut)
          if let tp = r.toPar { Text(tp).font(CSFont.label).foregroundStyle(cs.mut) }
        }
        // sideways the name takes the slack first and wrapped "55 THRU / 14";
        // the running total is one line or it is not a running total
        .lineLimit(canShowCard ? 1 : nil)
        .fixedSize(horizontal: canShowCard, vertical: false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total \(r.total ?? "none")" + (r.toPar.map { ", \($0)" } ?? ""))
        .accessibilityAddTraits(.updatesFrequently)
        HStack(spacing: 0) {
          Button { store.step(pi, -1) } label: { Text("−").font(CSFont.title).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle()) }
            .buttonStyle(.plain).accessibilityLabel("Minus, \(p.n)")
          Text(scoreText).font(CSFont.stat).csTabular().foregroundStyle(r.birdie ? cs.gold : cs.ink).frame(minWidth: 34)
            .accessibilityLabel("Hole \(s.hole + 1), \(r.score.map { "\($0) stroke\($0 == 1 ? "" : "s")" } ?? "not scored")\(r.birdie ? ", under par" : "")")
            .accessibilityAddTraits(.updatesFrequently)
          Button { store.step(pi, 1) } label: { Text("+").font(CSFont.title).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle()) }
            .buttonStyle(.plain).accessibilityLabel("Plus, \(p.n)")
        }
        .foregroundStyle(cs.ink)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      }
      .padding(.leading, typeSize.isA11y ? 14 : 0)
    }
    .padding(.vertical, canShowCard ? 4 : 6)
    .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
  }

  // MARK: game cards (3070–3092)

  @ViewBuilder private var gameCards: some View {
    if let m = LiveCopy.matchCard(s) {
      gameCard(accent: cs.sq0) {
        Text(m.teams).font(CSFont.footnote).foregroundStyle(cs.mut)
        Text(m.status).font(CSFont.monoMediumBody).tracking(0.6).foregroundStyle(cs.ink)
        Text(m.meta).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
      }
    }
    if let w = LiveCopy.wolfCard(s) {
      gameCard(accent: cs.gold) {
        Text("Wolf · lone wolf plays for 3").font(CSFont.footnote).foregroundStyle(cs.mut)
        Text(w.who).font(CSFont.monoMediumBody).tracking(0.6).foregroundStyle(cs.ink)
        Text(w.meta).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
        let pick = s.wolf[s.hole]
        LiveFlow(spacing: 6) {
          ForEach([0, 1, 2, 3].filter { $0 != w.wolf }, id: \.self) { p in
            wolfButton("+ " + s.players[p].n.uppercased(), on: pick?.mode == "partner" && pick?.partner == p) { store.setWolf(.partner(p)) }
          }
          wolfButton("LONE WOLF", on: pick?.isLone == true) { store.setWolf(.lone) }
          if pick != nil { wolfButton("CLEAR", on: false) { store.setWolf(nil) } }
        }
        tally(s.players.indices.map { (s.players[$0].n, LiveFmt.pm(w.pts[$0]), w.pts[$0] > 0 ? cs.pos : w.pts[$0] < 0 ? cs.neg : cs.mut) })
      }
    }
    if let k = LiveCopy.skinsCard(s) {
      gameCard(accent: cs.gold) {
        Text("Skins · ties carry the pot").font(CSFont.footnote).foregroundStyle(cs.mut)
        Text(k.status).font(CSFont.monoMediumBody).tracking(0.6).foregroundStyle(k.hot ? cs.hot : cs.ink)
          .modifier(LiveCarryPulse(on: k.hot))
        Text(k.meta).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
        tally(s.players.indices.map { (s.players[$0].n, String(k.won[$0]), k.won[$0] > 0 ? cs.pos : cs.mut) })
      }
    }
    if let rows = LiveCopy.liveSettle(s) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Round settlement · live").font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut)
        ForEach(Array(rows.enumerated()), id: \.offset) { _, r in
          HStack {
            Text(r.label).font(CSFont.label).tracking(0.8).foregroundStyle(CSTokens.dark.ink)
            Spacer()
            Text(r.amount).font(CSFont.monoMediumBody).foregroundStyle(cs.gold)
          }
          .accessibilityElement(children: .combine)
        }
      }
      .padding(14).frame(maxWidth: .infinity, alignment: .leading)
      .background(CSDusk.surface, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(cs.brand).frame(width: 3.5).padding(.vertical, 10) }
    }
  }

  private func gameCard<C: View>(accent: Color, @ViewBuilder _ content: () -> C) -> some View {
    VStack(alignment: .leading, spacing: 6) { content() }
      .padding(14).frame(maxWidth: .infinity, alignment: .leading)
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.line, lineWidth: 1))
      .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 3.5).padding(.vertical, 10) }
  }

  private func wolfButton(_ label: String, on: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(label).font(CSFont.label).tracking(0.8)
        .foregroundStyle(on ? cs.bg0 : cs.ink)
        .padding(.horizontal, 10).frame(minHeight: 36)
        .background(on ? cs.gold : cs.bg2, in: Capsule())
        .overlay(Capsule().stroke(on ? cs.gold : cs.line2, lineWidth: 1))
        .frame(minHeight: 44).contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(on ? .isSelected : [])
  }

  /// Four figures across; at the accessibility sizes one "name · figure" line per player, so a name is never truncated.
  private func tally(_ items: [(String, String, Color)]) -> some View {
    Group {
      if typeSize.isA11y {
        VStack(alignment: .leading, spacing: 4) {
          ForEach(Array(items.enumerated()), id: \.offset) { _, it in
            HStack(spacing: 8) {
              Text(it.0.uppercased()).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
              Spacer()
              Text(it.1).font(CSFont.stat).csTabular().foregroundStyle(it.2)
            }
            .accessibilityElement(children: .combine)
          }
        }
      } else {
        HStack(spacing: 12) {
          ForEach(Array(items.enumerated()), id: \.offset) { _, it in
            VStack(spacing: 2) {
              Text(it.1).font(CSFont.stat).csTabular().foregroundStyle(it.2)
              Text(it.0.uppercased()).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
          }
        }
      }
    }
    .padding(.top, 6)
    .accessibilityAddTraits(.updatesFrequently)
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
        .font(CSFont.monoMediumBody).foregroundStyle(scrapArmed ? cs.neg : cs.dimText)
        .padding(.horizontal, 12).frame(minHeight: 44)
        .background(cs.bg2, in: Capsule())
        .overlay(Capsule().stroke(scrapArmed ? cs.neg : cs.line2, lineWidth: 1))
    }
    .buttonStyle(.plain)
    .task(id: scrapArmed) {
      guard scrapArmed else { return }
      try? await Task.sleep(for: .seconds(4))
      scrapArmed = false
    }
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
      .animation(on && !reduce ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: lit)
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
