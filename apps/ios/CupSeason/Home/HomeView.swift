// Cup Season — Home (index.html 2792–2822 slot order; D81 one lane; D94
// doors; D27 the digest; IOS-012 hero first on the phone).
//
// Slots, top to bottom: invites banner → live-round banner → buddy requests
// (inside the banner) → hero → occasion → Up Next → digest → the one feed →
// coming up. The doors (start a league · start an event · join with a code)
// live in the toolbar `+`.

import SwiftUI
import CSDesign
import CupSeasonKit

struct HomeView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.presenter) private var presenter
  @Environment(\.cs) private var cs
  let links: CSLinks
  @State private var vm = HomeModel()

  var body: some View {
    ScrollView {
      if let me = store.me {
        let mode = HomeMode.of(me, preferredLeague: store.preferredLeague)
        VStack(alignment: .leading, spacing: 14) {
          InvitesBanner { id in store.preferredLeague = id; Task { await store.reload() } }

          if let live = me.live_round { LiveRoundBanner(round: live) }

          HomeHero(mode: mode, me: me)

          if let o = vm.occasion {
            OccasionCard(o: o, onGo: { presenter.handoff = o.go == .league ? .league : .event },
                         onDismiss: { Occasion.dismiss(o); vm.occasion = nil })
          }

          UpNextChips(leagueId: mode.membership?.league_id, links: links)

          HStack {
            Text("Around your buddies").csEyebrow()
            Spacer()
            if let lid = mode.membership?.league_id {
              NavigationLink(value: HomeRoute.league(lid)) { Text("THE BOARD ↗").csEyebrow(cs.dawn) }
            }
          }
          .padding(.top, 6)

          if let d = vm.digest { HomeDigestCard(digest: d, openReceipt: { presenter.receipt = $0 }) }

          if vm.loading && vm.buckets.isEmpty {
            ForEach(0..<3, id: \.self) { _ in skeleton }
          } else if vm.buckets.isEmpty {
            HStack(spacing: 4) {
              Text("No rounds from your buddies yet. Post one, or").font(CSFont.footnote).foregroundStyle(cs.mut)
              NavigationLink(value: HomeRoute.people) { Text("add some buddies.").font(CSFont.footnote).foregroundStyle(cs.brand) }
            }
          } else {
            ForEach(vm.buckets) { b in FeedBucketView(bucket: b, presenter: presenter) }
          }

          UpcomingRoundsSection(links: links)
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 32)
      }
    }
    .background(cs.bg0)
    .refreshable { await store.reload(); await vm.load(me: store.me) }
    .task(id: store.me?.generated_at) { await vm.load(me: store.me) }
    .navigationTitle("")
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        HStack(spacing: 8) {
          Rectangle().fill(LinearGradient(colors: CSTokens.gradStops, startPoint: .leading, endPoint: .trailing)).frame(width: 18, height: 3)
          Text("Cup Season").font(CSFont.sentenceBold).foregroundStyle(cs.ink)
        }
      }
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button { presenter.handoff = .league } label: { Label("Start a league", systemImage: "flag") }
          Button { presenter.handoff = .event } label: { Label("Start an event", systemImage: "trophy") }
          Button { presenter.join(code: nil) } label: { Label("Join with a code", systemImage: "key") }
          NavigationLink(value: HomeRoute.schedule) { Label("Your golf calendar", systemImage: "calendar") }
          NavigationLink(value: HomeRoute.people) { Label("Find golfers", systemImage: "magnifyingglass") }
        } label: {
          Image(systemName: "plus").foregroundStyle(cs.brand)
        }
      }
    }
  }

  private var skeleton: some View {
    RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(cs.bg1).frame(height: 76)
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.line, lineWidth: 1))
      .redacted(reason: .placeholder)
  }
}

@MainActor
@Observable
final class HomeModel {
  var buckets: [HomeBucket] = []
  var digest: HomeDigest?
  var occasion: Occasion?
  var loading = false
  private var markRead = false
  private var mark: Date?
  private let repo = HomeStreamRepository()

  func load(me: Me?) async {
    guard let me else { return }
    loading = true
    defer { loading = false }
    occasion = Occasion.current(leagueless: me.memberships.isEmpty)
    let r = await repo.load(memberships: me.memberships)
    buckets = HomeBuckets.bucket(r.items)
    if !markRead { mark = HomeDigest.readAndMark(profile: me.profile?.id); markRead = true }
    var urls: [UUID: URL] = [:]
    for case .round(let row, let u) in r.items { if let id = row.round_id, let u { urls[id] = u } }
    digest = HomeDigest.make(rounds: r.rounds, posts: r.posts, photoURLs: urls, mark: mark)
  }
}

// MARK: - live round banner (renderResumeBanner 7710–7735)

private struct LiveRoundBanner: View {
  @Environment(\.cs) private var cs
  let round: Me.LiveRound
  var body: some View {
    CSCard(spine: cs.pos) {
      VStack(alignment: .leading, spacing: 4) {
        Text(round.mine == true ? "Continue your round" : "You're on the tee sheet").csEyebrow(cs.pos)
        Text([round.course_label, round.league_name].compactMap { $0 }.joined(separator: " · ")).font(CSFont.sentence).foregroundStyle(cs.ink)
        Text("Live scoring lands on the phone in wave 4 — score it at cupseason.app for now.")
          .font(CSFont.footnote).foregroundStyle(cs.mut)
        Link("Open the pencil", destination: CSConfig.webOrigin).font(CSFont.button).foregroundStyle(cs.brand)
      }
    }
  }
}

// MARK: - occasion (occCard 10052–10060)

private struct OccasionCard: View {
  @Environment(\.cs) private var cs
  let o: Occasion
  let onGo: () -> Void
  let onDismiss: () -> Void
  var body: some View {
    CSCard(spine: o.earned ? cs.gold : cs.brand) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .top) {
          Text(o.k).csEyebrow(o.earned ? cs.gold : nil)
          Spacer()
          if let m = o.marker { CSMarkerView(key: m, size: 22).foregroundStyle(o.earned ? cs.gold : cs.ink) }
          Button(action: onDismiss) { Image(systemName: "xmark").font(.caption).foregroundStyle(cs.mut) }
            .accessibilityLabel("Dismiss")
        }
        Text(o.h).font(CSFont.sentenceBold).foregroundStyle(cs.ink)
        Text(o.p).font(CSFont.subhead).foregroundStyle(cs.mut)
        Button(action: onGo) {
          HStack { Text(o.act); Text("→") }.font(CSFont.button).foregroundStyle(cs.brand)
        }
        .padding(.top, 4)
      }
    }
  }
}

// MARK: - digest

private struct HomeDigestCard: View {
  @Environment(\.cs) private var cs
  let digest: HomeDigest
  let openReceipt: (UUID) -> Void
  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      if let u = digest.photoURL, let id = digest.roundId {
        Button { openReceipt(id) } label: {
          AsyncImage(url: u) { $0.resizable().scaledToFill() } placeholder: { cs.bg2 }
            .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(digest.label).csEyebrow()
        Text(digest.body).font(CSFont.subhead).foregroundStyle(cs.ink)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(cs.line, lineWidth: 1))
  }
}

// MARK: - the feed (feedRow · postRow · feedBuckets)

private struct FeedBucketView: View {
  @Environment(\.cs) private var cs
  let bucket: HomeBucket
  let presenter: Presenter
  @State private var expanded = false

  var body: some View {
    let cap = HomeBuckets.cap
    let showAll = bucket.label == "Earlier" ? expanded : (expanded || bucket.items.count <= cap + 1)
    let shown = showAll ? bucket.items : Array(bucket.items.prefix(cap))
    VStack(alignment: .leading, spacing: 10) {
      if bucket.label == "Earlier" && !expanded {
        Button("Show earlier · \(bucket.items.count)") { expanded = true }.font(CSFont.footnote).foregroundStyle(cs.dawn)
      } else {
        Text(bucket.label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
        ForEach(shown) { item in
          switch item {
          case .round(let r, let url): FeedRoundCard(r: r, photoURL: url, presenter: presenter)
          case .post(let p, let league): FeedPostCard(p: p, leagueName: league, presenter: presenter)
          }
        }
        if !showAll {
          Button("Show \(bucket.items.count - cap) more · \(bucket.label.lowercased())") { expanded = true }
            .font(CSFont.footnote).foregroundStyle(cs.dawn)
        }
      }
    }
  }
}

private struct FeedRoundCard: View {
  @Environment(\.cs) private var cs
  let r: HomeFeedRow
  let photoURL: URL?
  let presenter: Presenter

  private var who: String { HomeCopy.who(r) }
  private var milestone: String? { HomeCopy.milestone(r) }
  private var phrase: String? {
    guard let p = r.pvi else { return nil }
    let s = CSBands.vsPhrase(p)
    let out = r.is_me == true ? s : CSBands.theirs(s)
    return out.prefix(1).uppercased() + out.dropFirst()
  }
  private var meta: String { "\(r.course ?? "a round") · \(CSDate.short(r.played_on ?? ""))" }

  var body: some View {
    Button { if let id = r.round_id { presenter.receipt = id } } label: {
      if let photoURL {
        ZStack(alignment: .bottomLeading) {
          AsyncImage(url: photoURL) { $0.resizable().scaledToFill() } placeholder: { CSDusk.surface }
            .frame(height: 220).clipped()
          LinearGradient(colors: [.clear, CSDusk.ground.opacity(0.85)], startPoint: .top, endPoint: .bottom)
          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
              faceButton(size: 36)
              VStack(alignment: .leading, spacing: 1) {
                Text(who).font(CSFont.button).foregroundStyle(CSTokens.dark.ink)
                Text(meta + (milestone.map { " · \($0)" } ?? "")).font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut)
              }
            }
            HStack(alignment: .lastTextBaseline, spacing: 8) {
              Text(r.gross.map(String.init) ?? "").font(CSFont.hero).foregroundStyle(CSTokens.dark.ink)
              if let phrase { Text(phrase.lowercased()).font(CSFont.footnote).foregroundStyle(CSTokens.dark.mut) }
              Spacer()
              CSMarkerView(key: r.marker, size: 22).foregroundStyle(CSTokens.dark.ink)
            }
          }
          .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      } else {
        CSCard(spine: milestone != nil ? cs.gold : nil) {
          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
              faceButton(size: 44)
              VStack(alignment: .leading, spacing: 2) {
                Text(who).font(CSFont.button).foregroundStyle(cs.ink)
                if let line = milestone ?? phrase { Text(line).font(CSFont.footnote).foregroundStyle(milestone != nil ? cs.gold : cs.mut) }
              }
              Spacer()
              if let g = r.gross {
                VStack(alignment: .trailing, spacing: 0) {
                  Text(String(g)).font(CSFont.heroSmall).foregroundStyle(cs.ink).csTabular()
                  Text("gross").font(CSFont.label).foregroundStyle(cs.dimText)
                }
              }
            }
            Text(meta).font(CSFont.monoSmall).foregroundStyle(cs.mut)
          }
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(who) — \(r.gross.map(String.init) ?? "") at \(r.course ?? "a round")")
  }

  private func faceButton(size: CGFloat) -> some View {
    Button { if let p = r.profile_id { presenter.tourCard = p } } label: {
      CSFace(marker: r.marker, size: size)
    }
    .buttonStyle(.plain)
  }
}

private struct FeedPostCard: View {
  @Environment(\.cs) private var cs
  let p: HomePost
  let leagueName: String?
  let presenter: Presenter
  var body: some View {
    let fresh = (p.created_at.map { Date().timeIntervalSince($0) } ?? .infinity) < 48 * 3600
    let closed = (p.body ?? "").range(of: "\\bclosed\\b", options: [.regularExpression, .caseInsensitive]) != nil
    Button { if let lr = p.live_round_id { presenter.scorecard = lr } } label: {
      HStack(alignment: .top, spacing: 10) {
        Text(p.kind == "announce" ? "📣" : "🏁").font(.system(size: 20))
          .frame(width: 44, height: 44).background(cs.bg2, in: Circle())
        VStack(alignment: .leading, spacing: 3) {
          Text(HomeCopy.easeCaps(p.body ?? "")).font(CSFont.subhead).foregroundStyle(cs.ink)
          HStack(spacing: 4) {
            Text([leagueName, p.created_at.map { CSDate.short(CSDate.iso($0)) }].compactMap { $0 }.joined(separator: " · "))
              .font(CSFont.footnote).foregroundStyle(cs.mut)
            if p.live_round_id != nil { Text("· SCORECARD ›").font(CSFont.label).foregroundStyle(cs.gold) }
          }
        }
        Spacer()
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(fresh ? cs.line2 : cs.line, lineWidth: 1))
      .rotationEffect(.degrees(closed ? 1.4 : 0))   // the month seal keeps its cant — a hand set it
    }
    .buttonStyle(.plain)
    .disabled(p.live_round_id == nil)
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
    case .cupFinal, .wrapped: cs.gold
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
