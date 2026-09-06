// Cup Season — the ⊕: Golf's three tenses (index.html `#view-record`
// 2958–2975; `gateLiveRound` 4206 for the real-account copy; IA P4).
//
// Post a round — after · Play now — during · Plan a tee time — before. The ⊕
// is a verb, not a place: it presents over whichever tab you were on, and
// "Post" is the 90% case — so the ⊕ opens ON the composer (IOS-004 §2) and
// this cover is one back-tap away. A golfer with a live round open lands
// here instead, where "Play now" is the door back in. The cover rises 6pt
// and fades in on `CSMotion.rise` (IOS-003 §2.7; IOS-022 item 3) — the one
// place, so whichever page opens first wears it.

import SwiftUI
import CSDesign
import CupSeasonKit

/// The doors out of the ⊕. The host wires them.
struct PostLinks {
  /// "Play now" — the tee sheet (`LiveRoundHost`).
  var openLive: () -> Void = {}
  var openReceipt: (UUID) -> Void = { _ in }
  var openPeople: () -> Void = {}
  /// The epilogue's act can land on a season's table or on a golfer's card;
  /// both are doors the shell already owns (IOS-030). D222 renamed the first —
  /// a season is Compete's object and "league" is not what it opens.
  var openCompetition: (UUID) -> Void = { _ in }
  var openTourCard: (UUID) -> Void = { _ in }
}

struct PostCoverView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let links: PostLinks
  let startOnComposer: Bool

  /// D110 addendum: the ⊕ opens the three-door COVER (the owner tapped ⊕ and
  /// never saw the doors); only an explicit "post a round" CTA lands on the
  /// composer. The old rule (composer unless a round is live) is retired.
  init(startOnComposer: Bool = false, links: PostLinks = PostLinks()) {
    self.startOnComposer = startOnComposer; self.links = links
  }

  enum Route: Hashable { case post }

  var body: some View {
    PostCoverStack(links: links, startOnPost: (startOnComposer && !Self.forcedCover) || Self.forcedOpen, close: { dismiss() })
      .modifier(PostCoverRise())
  }

  #if DEBUG
  /// The `-cs_dev_open postround` hatch: the composer, whatever is live.
  private static var forcedOpen: Bool { ProcessInfo.processInfo.arguments.contains("postround") }
  /// `-cs_dev_post_cover`: land on the cover itself, as a golfer with a live round would.
  private static var forcedCover: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_post_cover") }
  #else
  private static let forcedOpen = false
  private static let forcedCover = false
  #endif
}

/// 6pt rise + fade, 0.26s, on the roll (IOS-003 §2.7). Reduced motion lands
/// on the rest frame at once.
private struct PostCoverRise: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var risen = false
  func body(content: Content) -> some View {
    content
      .opacity(risen ? 1 : 0)
      .offset(y: risen ? 0 : 6)
      .onAppear {
        if reduceMotion { risen = true } else { withAnimation(CSMotion.rise) { risen = true } }
      }
  }
}

/// The stack, with its opening page decided before the first frame — no push
/// animates on the way in when the composer is the door.
private struct PostCoverStack: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  let links: PostLinks
  let close: () -> Void
  @State private var path: NavigationPath
  @State private var showPlan = false

  init(links: PostLinks, startOnPost: Bool, close: @escaping () -> Void) {
    self.links = links; self.close = close
    _path = State(initialValue: startOnPost ? NavigationPath([PostCoverView.Route.post]) : NavigationPath())
  }

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          // D227 · three rows, one line of gloss each, and the ~1,000 px of
          // dead space under them closed (SV-22). The tab is Play, so the
          // cover is Play.
          CSPageHeader("Play", sub: "One live, one you just finished, or the next one")
          // L-40 / D110: the live game leads and wears ember (the live metal,
          // per the tokens contract); posting and planning are quiet errand
          // rows. D227 holds that clause rather than spending it: the 90 %
          // case is served by a LONG-PRESS on the ⊕, by Home's first foot door
          // and by every explicit "Add a round" CTA, all of which land on the
          // composer directly.
          VStack(spacing: 0) {
            // A-3 · **"THEY DON'T NEED THE APP" BELONGS ON THE OUTSIDE.**
            //
            // The single most useful fact in the product for a golfer whose
            // group is not on here — guests play every game, post nothing, no
            // account needed — was three scrolls inside the live setup, under
            // a headline that says the opposite. A blind reader ruled the
            // whole live game out on this row's second line ("my group has one
            // guy who still uses a flip phone"), then found the answer by
            // accident at the very end: *"That is the answer to my entire
            // question and it is buried."* One clause, on the cover.
            PostLiveHeroRow(title: "Score it live — you and the group, hole by hole",
                            sub: "One phone or four — guests need no account. It settles up at the end.") {
              close(); links.openLive()
            }
            PostOptionRow(tick: cs.line2, title: "Add a round you played",
                          sub: "Your gross and the tee — it posts to your rounds, and every season you're in reads it.") { path.append(PostCoverView.Route.post) }
            PostOptionRow(tick: cs.line2, title: "Plan a round",
                          // LV-14 · row 113: "league" is never a thing you join. The container is
                          // a SEASON.
                          sub: "Put it on the schedule; your buddies and your seasons see it.", last: true) { showPlan = true }
          }
          .padding(.top, 12)
          // F-13 · what the long-press OPENS, named. "Your card" is the profile
          // (the exempt sense) and this opens the composer — on a screen whose
          // row above calls the same destination "Add a round you played".
          CSFine("Hold the ⊕ to go straight to Add my round.").padding(.top, 12)
        }
        .padding(20)
      }
      .background(cs.bg0)
      .navigationDestination(for: PostCoverView.Route.self) { r in
        switch r {
        case .post: PostRoundScreen(links: links, onDone: close)
        }
      }
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { close() }.foregroundStyle(cs.mut) } }
      .sheet(isPresented: $showPlan) { DeclareRoundSheet(leagueId: store.preferredLeague) { _ in close() } }
    }
  }
}

/// D110 hero — the live door: ember spine, a breathing LIVE word, taller.
struct PostLiveHeroRow: View {
  @Environment(\.cs) private var cs
  let title: String
  let sub: String
  let action: () -> Void
  @State private var breathe = false
  var body: some View {
    Button(action: action) {
      CSRow {
        HStack(alignment: .center, spacing: 14) {
          RoundedRectangle(cornerRadius: 2).fill(cs.brand).frame(width: 3.5).padding(.vertical, 4)
          VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
              Circle().fill(cs.brand).frame(width: 7, height: 7).opacity(breathe ? 0.35 : 1)
              Text("LIVE").font(CSFont.monoSmall.weight(.semibold)).foregroundStyle(cs.brand).tracking(1.6)
            }
            Text(title).font(CSFont.title).foregroundStyle(cs.ink).multilineTextAlignment(.leading)
            Text(sub).font(CSFont.subhead).foregroundStyle(cs.mut).multilineTextAlignment(.leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          Text("→").font(CSFont.title).foregroundStyle(cs.brand)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 6)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Live: \(title). \(sub)")
    .onAppear {
      guard !UIAccessibility.isReduceMotionEnabled else { return }
      withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { breathe = true }
    }
  }
}

/// `.optcard` as a row — the tense's colour as a tick on the left, a title, a line, the `→`.
struct PostOptionRow: View {
  @Environment(\.cs) private var cs
  let tick: Color
  let title: String
  let sub: String
  var last = false
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      CSRow(last: last) {
        HStack(alignment: .center, spacing: 14) {
          RoundedRectangle(cornerRadius: 2).fill(tick).frame(width: 3.5).padding(.vertical, 4)
          VStack(alignment: .leading, spacing: 4) {
            Text(title).font(CSFont.title).foregroundStyle(cs.ink).multilineTextAlignment(.leading)
            Text(sub).font(CSFont.subhead).foregroundStyle(cs.mut).multilineTextAlignment(.leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          Text("→").font(CSFont.title).foregroundStyle(tick)
        }
        .fixedSize(horizontal: false, vertical: true)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
  }
}

#Preview("the ⊕") {
  PostCoverView().environment(SessionStore()).csTheme()
}
