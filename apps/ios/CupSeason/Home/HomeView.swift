// Cup Season — Home (IOS-002 §4, IOS-012). Hero first, dispatched on the
// lifecycle the web already encodes; the doors live in the toolbar.
//
// M0 renders the hero with the REAL standing and the three tiles. The
// live-round banner, "your match this week", Up Next, the digest and the
// stream arrive in M1 against `native_home`.

import SwiftUI
import CSDesign
import CupSeasonKit

struct HomeView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs

  var body: some View {
    ScrollView {
      if let me = store.me {
        let mode = HomeMode.of(me, preferredLeague: store.preferredLeague)
        VStack(alignment: .leading, spacing: 14) {
          HomeHero(mode: mode, me: me)
          tiles(me: me, mode: mode)
          milestoneNote
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 32)
      }
    }
    .background(cs.bg0)
    .refreshable { await store.reload() }
    .navigationTitle("")
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        HStack(spacing: 8) {
          Rectangle().fill(LinearGradient(colors: CSTokens.gradStops, startPoint: .leading, endPoint: .trailing)).frame(width: 18, height: 3)
          Text("Cup Season").font(CSFont.sentenceBold).foregroundStyle(cs.ink)
        }
      }
    }
  }

  private func tiles(me: Me, mode: HomeMode) -> some View {
    let p = me.profile
    let rounds = p?.rounds_count ?? 0
    let indexValue: String = p?.index_current != nil ? CSCopy.index(p?.index_current) : "\(min(rounds, 3)) of 3"
    let indexSub: String? = p?.index_current == nil ? "building your number" : nil
    let m = mode.membership
    return HStack(spacing: 10) {
      CSStat("Your index", value: indexValue, tone: p?.index_current != nil ? cs.gold : cs.ink, sub: indexSub)
      CSStat("Rounds", value: "\(rounds)")
      if let st = m?.standing { CSStat("Points", value: CSCopy.points(st.points)) }
    }
  }

  private var milestoneNote: some View {
    Text("M0: this is the scaffold — it boots, wears the palette, and signs you in with a real standing. The board, the round and push follow.")
      .font(CSFont.footnote).foregroundStyle(cs.dimText).padding(.top, 8)
  }
}

/// The hero: the standing MOVE (D81 "the standing is a verb").
struct HomeHero: View {
  @Environment(\.cs) private var cs
  let mode: HomeMode
  let me: Me

  var body: some View {
    CSCard(spine: spine, padding: 18) {
      VStack(alignment: .leading, spacing: 8) {
        Text(eyebrow).csEyebrow(earned ? cs.gold : nil)
        HStack(alignment: .firstTextBaseline, spacing: 10) {
          Text(figure).font(CSFont.hero).foregroundStyle(cs.ink).csTabular()
          if let move { moveChip(move) }
        }
        Text(line).font(CSFont.sentence).foregroundStyle(cs.ink)
        if let foot { Text(foot).font(CSFont.monoSmall).foregroundStyle(cs.mut).padding(.top, 4) }
      }
    }
  }

  private var earned: Bool { if case .season(let m) = mode { return m.standing?.rank == 1 }; return false }
  private var spine: Color? {
    switch mode {
    case .season: earned ? cs.gold : cs.brand
    case .cupFinal: cs.gold
    case .wrapped: cs.gold
    default: cs.brand
    }
  }

  private var eyebrow: String {
    switch mode {
    case .leagueless: return "Your card"
    case .forming(let m): return "\(m.name) · forming"
    case .preseason(let m): return "\(m.name) · season live"
    case .season(let m):
      if case .season(let w, let of) = SeasonPhase.of(m) { return "\(m.name) · week \(w) of \(of)" }
      return m.name
    case .cupFinal(let m): return "\(m.name) · cup final"
    case .wrapped(let m): return "\(m.name) · season wrapped"
    }
  }

  private var figure: String {
    switch mode {
    case .leagueless(let rung): return rung == 7 ? "\(min(me.profile?.rounds_count ?? 0, 3)) of 3" : CSCopy.index(me.profile?.index_current)
    case .forming(let m):
      if let s = m.season, let d = CSDate.days(from: CSDate.today(), to: s.starts_on), d >= 0 { return "\(d)d" }
      return "—"
    case .preseason(let m):
      if let s = m.season, let d = CSDate.days(from: CSDate.today(), to: s.starts_on) { return "\(max(d, 0))d" }
      return "—"
    case .season(let m), .cupFinal(let m), .wrapped(let m):
      if let r = m.standing?.rank { return CSCopy.ordinal(r) }
      return "—"
    }
  }

  private var move: (String, Color)? {
    guard case .season(let m) = mode, let st = m.standing, let prev = st.prev_rank else { return nil }
    if st.rank < prev { return ("▲ up \(prev - st.rank)", prev - st.rank >= 2 ? cs.hot : cs.warm) }
    if st.rank > prev { return ("▼ down \(st.rank - prev)", cs.cool) }
    return ("— held", cs.mut)
  }

  private func moveChip(_ m: (String, Color)) -> some View {
    Text(m.0).font(CSFont.monoMediumBody).foregroundStyle(m.1)
      .padding(.horizontal, 8).padding(.vertical, 3)
      .overlay(Capsule().stroke(m.1.opacity(0.5), lineWidth: 1))
  }

  private var line: String {
    switch mode {
    case .leagueless(let rung):
      return rung == 7 ? "Three rounds and your index goes live. Nothing else needed."
                       : "Established. Nobody's seen it yet — you haven't joined a league."
    case .forming(let m):
      return m.isPro ? "Your league is still forming. Lock the bylaws and the invite link is yours."
                     : "The bylaws lock at the tee."
    case .preseason: return "The season's on. Rounds count from first tee."
    case .season(let m):
      guard let st = m.standing else { return "Standings start at the first posted round." }
      if st.rank == 1 {
        if let g = st.gap_to_next, g > 0 { return "You lead by \(CSCopy.points(g)) points." }
        return "Level at the top. Your next round breaks the tie."
      }
      if let g = st.gap_to_leader { return g == 0 ? "Level with the lead." : "\(CSCopy.points(g)) points back of the lead." }
      return "In the race."
    case .cupFinal(let m):
      if case .cupFinal(let w) = SeasonPhase.of(m) { return "Four weeks, scored fresh. Whoever's hottest takes the cup. \(w) left." }
      return "Four weeks, scored fresh."
    case .wrapped(let m):
      if let s = m.season, let champ = s.champion_squad_id, champ == m.squad?.id { return "Your name goes on the cup." }
      return "The cup's been lifted. Run it back."
    }
  }

  private var foot: String? {
    guard let m = mode.membership else { return nil }
    if let p = m.pulse, let floor = p.floor, floor > 0 {
      let credits = p.credits ?? 0
      if p.partial == true { return "Partial month · floors waived" }
      return credits >= Double(floor) ? "Month floor met · \(CSCopy.points(credits))/\(floor)" : "Month floor \(CSCopy.points(credits))/\(floor) · \(CSCopy.points(Double(floor) - credits)) more"
    }
    if let cap = m.settings?.counting_cap { return "Best \(cap) rounds a month count" }
    return nil
  }
}
