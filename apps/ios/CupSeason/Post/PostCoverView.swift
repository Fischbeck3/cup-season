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
}

struct PostCoverView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let links: PostLinks

  init(links: PostLinks = PostLinks()) { self.links = links }

  enum Route: Hashable { case post }

  var body: some View {
    PostCoverStack(links: links, startOnPost: (store.me?.live_round == nil && !Self.forcedCover) || Self.forcedOpen, close: { dismiss() })
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
          // the web's cover line, verbatim, as the header's sub (IOS-022 item 4)
          CSPageHeader("Golf", sub: "Golf · before, during and after the round")
          // D110: the live game leads and wears ember (the live metal, per the
          // tokens contract); posting and planning are quiet errand rows. Before
          // this, POST wore ember and the live door a squad blue — backwards.
          VStack(spacing: 0) {
            PostLiveHeroRow(title: "Play now — score the group",
                            sub: "Hole-by-hole on every phone · Match Play, Wolf & Skins · the settle-up at the end · guests welcome, no account") {
              close(); links.openLive()
            }
            PostOptionRow(tick: cs.line2, title: "Post a round — after you play",
                          sub: "Gross + tee, 20 seconds · counts on your card and in every league") { path.append(PostCoverView.Route.post) }
            PostOptionRow(tick: cs.line2, title: "Plan a tee time — before",
                          sub: "Put a round on the tee sheet · your buddies and leagues see it the moment you post", last: true) { showPlan = true }
          }
          .padding(.top, 12)
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
