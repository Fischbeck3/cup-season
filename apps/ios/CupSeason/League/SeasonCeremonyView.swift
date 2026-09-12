// Cup Season — the season ceremony (`openSeasonCeremony` / `csSettlement`,
// index.html 11465–11600; D66). Renders from `season_payouts` when the server
// wrote them; the client math only when no rows exist, labelled "preview".
// Once per member per season (`cs_cer_<season>`), re-openable from the room.
//
// WAVE 8 · **THE TAKEOVER, WHICH IS THE ANSWER TO THE AUDIT'S P0** (D277,
// UI_SYSTEM §11.3). The screen a golfer sees once, the night a season they
// played for four months ends, had **zero animation calls and zero haptics** —
// while the settings accordion animated its disclosure. It also read as a
// dialog: a centred serif name, a `heroSmall` margin in gold, three grey label
// lines and a rounded tile per block.
//
// It is a takeover now: a full-bleed ceremony band whose plate wipes from the
// leading edge, whose `display` lines arrive at a 60ms stagger, whose margin
// TALLIES, and whose medallion seals last with the thock. Under the band the
// settlement is a printed ledger — the two named finishers on rules, what
// you're owed as a `CSStakeLine`, the pay rows as a leaf, and the ledger line
// once at the foot, verbatim from the constant.

import SwiftUI
import CSDesign
import CupSeasonKit

struct SeasonCeremonyView: View {
  /// The room's model, when the ceremony is opened from inside the room.
  /// **Optional on purpose (IOS-029b).** Home has to be able to fire the
  /// takeover — a member who never opens the Clubhouse the night their season
  /// ends never sees it end — and Home must not drag in the season page's
  /// whole model to do it. So the view takes its facts as VALUES through the
  /// initialiser below, and reads the model only when one is in the
  /// environment. Nothing about the room's path changes.
  @Environment(LeagueRoomModel.self) private var model: LeagueRoomModel?
  @Environment(\.roomLinks) private var links
  @Environment(\.dismiss) private var dismiss
  @State private var share: PostShareItem?
  private let d = CSTokens.dark   // the ceremony keeps its ink in every theme

  private let givenSettlement: PotMath.Settlement?
  private let givenMembers: Int?
  private let givenFinish: String?
  private let givenSeasonId: UUID?
  /// The champion's mark, for the medallion that seals the takeover. The room
  /// reads it off the member list; a ceremony fired from Home has no member
  /// list, so it is passed — and when neither has one the band simply carries
  /// no seal, which is the honest degrade.
  private let givenChampMarker: String?
  private let givenRunItBack: (() -> Void)?

  /// The room's initialiser: everything comes from the environment model.
  init() {
    givenSettlement = nil; givenMembers = nil; givenFinish = nil; givenSeasonId = nil
    givenChampMarker = nil; givenRunItBack = nil
  }

  /// **The value initialiser (HOME_STATE_MATRIX.md S8).** Present the same
  /// ceremony straight from `home_dispatch` — the champion, the margin, the
  /// tiebreak rung, the runner-up, the points king and the pay rows — with no
  /// room fetch behind it. `seasonId` is what the once-per-member key is
  /// written under; pass nil and the ceremony simply does not mark itself
  /// seen, which is honest rather than wrong.
  init(settlement: PotMath.Settlement?, members: Int, finish: String?, seasonId: UUID? = nil,
       champMarker: String? = nil, onRunItBack: (() -> Void)? = nil) {
    givenSettlement = settlement; givenMembers = members; givenFinish = finish
    givenSeasonId = seasonId; givenChampMarker = champMarker; givenRunItBack = onRunItBack
  }

  private var settlement: PotMath.Settlement? { givenSettlement ?? model?.settlement }
  private var memberCount: Int { givenMembers ?? model?.members.count ?? 0 }
  private var finish: String? { givenFinish ?? model?.bylaws.finish }
  private var runItBack: (() -> Void)? { givenRunItBack ?? links.runItBack }

  var body: some View {
    let cup = finish == "cup_final"
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          if let st = settlement {
            takeover(st, cup: cup)
            if st.fromLedger, !st.champName.isEmpty, let season = model?.season, let league = model?.league {
              Button("Share season result") {
                share = BrandRecordCard(kind: cup ? "Cup result" : "Season result",
                  title: st.champName, figure: nil, statement: cup ? "Cup champion" : "Season champion",
                  rows: ["\(league.name) · \(season.starts_on) – \(season.ends_on)", st.runName.isEmpty ? nil : "Runner-up · \(st.runName)", st.kingName.isEmpty ? nil : "Points King · \(st.kingName)"].compactMap { $0 },
                  earned: true).shareItem()
              }.buttonStyle(.csSecondary()).csGutter()
            }
            VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
              finishers(st)
              if let mine = st.mine, st.potCents > 0 {
                VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
                  // the reason rides the figure's own label rather than
                  // sitting under it as a second agate line — two stacked
                  // labels under one rule read as two labels, not as a cause
                  CSFigure(PotMath.money(mine.cents), size: .l, metal: .earned,
                           label: (["You're owed"] + mine.why).joined(separator: " · "))
                }
              }
              if !st.rows.isEmpty && st.potCents > 0 { ledger(st) }
              // D243 · role-gated, for the same reason the wrapped hero is.
              if let rb = runItBack {
                Button(RunItBack.title(isPro: model?.isPro ?? false,
                                       proFirstName: (model?.proName).flatMap { $0 == "—" ? nil : $0 })) {
                  dismiss(); rb()
                }
                .buttonStyle(.csPrimary())   // LV-21 · L-25
                .padding(.top, CSTokens.Space.s2)
              }
            }
            .csGutter()
          } else {
            Text("The result posts once the season closes.")
              .csType(.body).foregroundStyle(d.mut).csGutter()
              .padding(.top, CSTokens.Space.s5)
          }
        }
        .padding(.bottom, CSTokens.Space.s6)
      }
      .background(CSDusk.ground)
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.hidden, for: .navigationBar)
      .csCloseButton { dismiss() }
    }
    .sheet(item: $share) { PostShareSheet(items: $0.items) }
    .csCeremony()
    // Once per member. From the room the model owns the key; from Home the
    // same device-local key is written directly, so a ceremony fired from
    // either door is not shown twice.
    .onAppear {
      if let model { model.markCeremonySeen() }
      else if let id = givenSeasonId { UserDefaults.standard.set(true, forKey: LeagueRoomModel.ceremonyKey(id)) }
    }
  }

  // MARK: the band

  /// **The champion's name is the `display` line and the margin is the
  /// figure.** Not "Season complete" over a serif name over a gold score: the
  /// name is the biggest thing on the biggest moment, and the number under it
  /// counts to itself.
  @ViewBuilder private func takeover(_ st: PotMath.Settlement, cup: Bool) -> some View {
    let margin: Double? = {
      guard let s1 = st.s1, let s2 = st.s2 else { return nil }
      return ((s1 - s2) * 10).rounded() / 10
    }()
    CSTakeover(
      eyebrow: cup ? "The Cup Final" : "Season complete",
      lines: [st.champName, cup ? "took the Cup Final" : "took the Cup"],
      // **the margin takes INK.** §1.4 allows one gold object a viewport and
      // this surface already spends its pair on the moment's own name and on
      // the money won; a margin is arithmetic, not a thing anybody was given.
      figure: margin.map { m in
        CSTakeoverFigure(value: m, format: { v in m > 0 ? PotMath.score(v) : "LEVEL" },
                          label: m > 0 ? "The margin" : "The ladder decided it",
                          earned: false)
      },
      marker: givenChampMarker ?? model?.members.first(where: { $0.name == st.champName })?.marker
    ) {
      if let rung = st.rung {
        Text("Decided on \(rung)").csType(.agate, caps: true)
          .foregroundStyle(d.ceremonyMut)
      }
    }
  }

  // MARK: the two named finishers

  @ViewBuilder private func finishers(_ st: PotMath.Settlement) -> some View {
    if !st.runName.isEmpty || !st.kingName.isEmpty {
      VStack(spacing: 0) {
        if !st.runName.isEmpty { cerRow("Runner-up", st.runName) }
        if !st.kingName.isEmpty { cerRow("Points king", st.kingName) }
      }
    }
  }

  private func cerRow(_ k: String, _ v: String) -> some View {
    A11yStack(columnSpacing: CSTokens.Space.s1) {
      Text(k).csType(.agate, caps: true).foregroundStyle(d.mut)
      Spacer(minLength: CSTokens.Space.s3)
      Text(v).csType(.name).foregroundStyle(d.ink)
    }
    .padding(.vertical, CSTokens.Space.s3)
    .overlay(alignment: .bottom) { CSRule() }
    .accessibilityElement(children: .combine)
  }

  // MARK: the pot, printed

  @ViewBuilder private func ledger(_ st: PotMath.Settlement) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      CSSectionHead("The pot", count: PotMath.money(st.potCents))
      // D106: the pot is what the roster owes; collected is the cash the split was paid from
      Text("\(memberCount) golfers · \(st.stillOwedCents > 0 ? "paid from what was collected — \(PotMath.money(st.collectedCents))" : "what each is owed")")
        .csType(.bodyS).foregroundStyle(d.mut)
        .fixedSize(horizontal: false, vertical: true)
      if !st.fromLedger {
        Text("Preview").csType(.agate, caps: true).foregroundStyle(d.brand)
      }
      CSLeaf {
        ForEach(st.rows) { r in payRow(r.name, r.why.joined(separator: " + "), r.cents) }
        // a share with no eligible finisher (an empty squad) must not silently vanish (§16)
        if st.unclaimedCents > 0 { payRow("Unclaimed", "no eligible finisher", st.unclaimedCents) }
        // D106: the truth about the shortfall, by name
        if st.stillOwedCents > 0 { payRow("Still owed to the pot", st.owing.joined(separator: ", "), st.stillOwedCents) }
      }
      // **THE FOOT, AND ONLY THE FOOT.** D273 puts the line at the foot of the
      // money surface, and this surface printed it in TWO places — once
      // mid-page above `THE POT` beside the figure you are owed, and once
      // here — so which one a golfer read depended on whether they had won
      // anything. It is here, under the leaf, once, in `agateS` like every
      // other printing of it in the product.
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        CSRule()
        Text(MoneyCopy.ledger).csType(.agateS, caps: false).foregroundStyle(d.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.top, CSTokens.Space.s2)
    }
  }

  private func payRow(_ who: String, _ why: String, _ cents: Int) -> some View {
    A11yStack(rowAlignment: .firstTextBaseline, columnSpacing: CSTokens.Space.s1) {
      VStack(alignment: .leading, spacing: 1) {
        Text(who).csType(.name).foregroundStyle(CSTokens.dark.leafInk)
        Text(why).csType(.agateS, caps: true).foregroundStyle(CSTokens.dark.leafMut)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: CSTokens.Space.s2)
      Text(PotMath.money(cents)).csType(.columnM).foregroundStyle(CSTokens.dark.leafInk)
    }
    .padding(.vertical, CSTokens.Space.s2)
    .overlay(alignment: .top) {
      Rectangle().fill(CSTokens.dark.leafInk.opacity(CSTokens.Alpha.a16)).frame(height: CSTokens.Space.hair)
    }
    .accessibilityElement(children: .combine)
  }
}
