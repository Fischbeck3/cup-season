// Cup Season — the ⊕: Golf's three tenses (index.html `#view-record`
// 2958–2975; `gateLiveRound` 4206 for the real-account copy; IA P4).
//
// Post a round — after · Play now — during · Plan a tee time — before. The ⊕
// is a verb, not a place: it presents over whichever tab you were on, and
// "Post" is the 90% case — so the ⊕ opens ON the composer (IOS-004 §2) and
// this cover is one back-tap away. A golfer with a live round open lands
// here instead, where "Play now" is the door back in.

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
          CSPageHeader("Golf", eyebrow: "before · during · after")
          VStack(spacing: 0) {
            PostOptionRow(tick: cs.brand, title: "Post a round — after you play",
                          sub: "Gross + tee, 20 seconds · counts on your card and in every league") { path.append(PostCoverView.Route.post) }
            PostOptionRow(tick: cs.sq0, title: "Play now — score the group live",
                          sub: "A shared pencil: match play, Wolf & the settle-up. Post your gross after — the finish screen hands it to you.") {
              close(); links.openLive()
            }
            PostOptionRow(tick: cs.gold, title: "Plan a tee time — before",
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
