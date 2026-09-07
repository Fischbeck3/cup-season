// Cup Season — the season ceremony (`openSeasonCeremony` / `csSettlement`,
// index.html 11465–11600; D66). Renders from `season_payouts` when the server
// wrote them; the client math only when no rows exist, labelled "preview".
// Once per member per season (`cs_cer_<season>`), re-openable from the room.

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
  private let d = CSTokens.dark   // the dusk room keeps the charcoal ink in every theme

  private let givenSettlement: PotMath.Settlement?
  private let givenMembers: Int?
  private let givenFinish: String?
  private let givenSeasonId: UUID?
  private let givenRunItBack: (() -> Void)?

  /// The room's initialiser: everything comes from the environment model.
  init() {
    givenSettlement = nil; givenMembers = nil; givenFinish = nil; givenSeasonId = nil; givenRunItBack = nil
  }

  /// **The value initialiser (HOME_STATE_MATRIX.md S8).** Present the same
  /// ceremony straight from `home_dispatch` — the champion, the margin, the
  /// tiebreak rung, the runner-up, the points king and the pay rows — with no
  /// room fetch behind it. `seasonId` is what the once-per-member key is
  /// written under; pass nil and the ceremony simply does not mark itself
  /// seen, which is honest rather than wrong.
  init(settlement: PotMath.Settlement?, members: Int, finish: String?, seasonId: UUID? = nil,
       onRunItBack: (() -> Void)? = nil) {
    givenSettlement = settlement; givenMembers = members; givenFinish = finish
    givenSeasonId = seasonId; givenRunItBack = onRunItBack
  }

  private var settlement: PotMath.Settlement? { givenSettlement ?? model?.settlement }
  private var memberCount: Int { givenMembers ?? model?.members.count ?? 0 }
  private var finish: String? { givenFinish ?? model?.bylaws.finish }
  private var runItBack: (() -> Void)? { givenRunItBack ?? links.runItBack }

  var body: some View {
    let cup = finish == "cup_final"
    SheetFrame(cup ? "The Cup Final" : "The season", dusk: true) {
      if let st = settlement {
        VStack(alignment: .center, spacing: 10) {
          Text("Season complete").csEyebrow(d.gold)
          Text(st.champName).font(CSFont.hero).foregroundStyle(d.ink).multilineTextAlignment(.center)
          Text(cup ? "took the Cup Final" : "took the Cup").font(CSFont.sentence).foregroundStyle(d.mut)
          if let s1 = st.s1, let s2 = st.s2 {
            let margin = ((s1 - s2) * 10).rounded() / 10
            VStack(spacing: 2) {
              Text("\(PotMath.score(s1))–\(PotMath.score(s2))").font(CSFont.heroSmall).csTabular().foregroundStyle(d.gold)
              Text(margin > 0 ? "by \(PotMath.score(margin))" : "level — the ladder decided it").font(CSFont.label).tracking(1.0).foregroundStyle(d.mut)
            }
          }
          if let rung = st.rung { Text("decided on \(rung)").font(CSFont.label).tracking(1.2).foregroundStyle(d.mut) }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)

        block {
          if !st.runName.isEmpty { cerRow("Runner-up", st.runName, gold: false) }
          if !st.kingName.isEmpty { cerRow("Points king", st.kingName, gold: true) }
        }
        if let mine = st.mine, st.potCents > 0 {
          VStack(alignment: .leading, spacing: 2) {
            Text("You're owed \(PotMath.money(mine.cents))").font(CSFont.sentenceBold).foregroundStyle(d.gold)
            Text(mine.why.joined(separator: " + ")).font(CSFont.label).tracking(0.8).foregroundStyle(d.mut)
          }
          .padding(14).frame(maxWidth: .infinity, alignment: .leading)
          .background(CSDusk.surface, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(d.gold.opacity(0.5), lineWidth: 1))
        }
        if !st.rows.isEmpty && st.potCents > 0 {
          block {
            HStack {
              // D106: the pot is what the roster owes; collected is the cash the split was paid from
              Text("The pot — \(PotMath.money(st.potCents))" + (st.stillOwedCents > 0 ? " · collected \(PotMath.money(st.collectedCents))" : ""))
                .font(CSFont.title).foregroundStyle(d.ink)
              if !st.fromLedger { Text("PREVIEW").csEyebrow(d.brand) }
            }
            Text("\(memberCount) golfers · \(st.stillOwedCents > 0 ? "paid from what was collected" : "what each is owed")").font(CSFont.footnote).foregroundStyle(d.mut)
            ForEach(st.rows) { r in payRow(r.name, r.why.joined(separator: " + "), r.cents) }
            // a share with no eligible finisher (an empty squad) must not silently vanish (§16)
            if st.unclaimedCents > 0 { payRow("Unclaimed", "no eligible finisher", st.unclaimedCents) }
            // D106: the truth about the shortfall, by name
            if st.stillOwedCents > 0 { payRow("Still owed to the pot", st.owing.joined(separator: ", "), st.stillOwedCents) }
            Text(MoneyCopy.ledger)
              .font(CSFont.footnote).foregroundStyle(d.mut).padding(.top, 6).fixedSize(horizontal: false, vertical: true)
          }
        }
        // D243 · role-gated, for the same reason the wrapped hero is.
        if let rb = runItBack {
          CSButton(RunItBack.title(isPro: model?.isPro ?? false,
                                   proFirstName: (model?.proName).flatMap { $0 == "—" ? nil : $0 }),
                   style: .primary) { dismiss(); rb() }.padding(.top, 8)   // LV-21 · L-25
        }
        Button { dismiss() } label: {
          Text("Close").font(CSFont.subhead).foregroundStyle(d.mut).frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      } else {
        Text("The result posts once the season closes.").font(CSFont.body).foregroundStyle(d.mut)
      }
    }
    // Once per member. From the room the model owns the key; from Home the
    // same device-local key is written directly, so a ceremony fired from
    // either door is not shown twice.
    .onAppear {
      if let model { model.markCeremonySeen() }
      else if let id = givenSeasonId { UserDefaults.standard.set(true, forKey: LeagueRoomModel.ceremonyKey(id)) }
    }
  }

  private func block<C: View>(@ViewBuilder _ c: () -> C) -> some View {
    VStack(alignment: .leading, spacing: 8) { c() }
      .padding(14).frame(maxWidth: .infinity, alignment: .leading)
      .background(CSDusk.surface, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
  }
  private func cerRow(_ k: String, _ v: String, gold: Bool) -> some View {
    A11yStack(columnSpacing: 2) {
      Text(k).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(d.mut)
      Spacer()
      Text(v).font(CSFont.sentenceBold).foregroundStyle(gold ? d.gold : d.ink)
    }
    .accessibilityElement(children: .combine)
  }
  private func payRow(_ who: String, _ why: String, _ cents: Int) -> some View {
    A11yStack(rowAlignment: .firstTextBaseline, columnSpacing: 2) {
      VStack(alignment: .leading, spacing: 1) {
        Text(who).font(CSFont.subhead).foregroundStyle(d.ink)
        Text(why).font(CSFont.label).tracking(0.6).foregroundStyle(d.mut)
      }
      Spacer()
      Text(PotMath.money(cents)).font(CSFont.monoMediumBody).csTabular().foregroundStyle(d.gold)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }
}
