// Cup Season — the ⊕: Golf's three tenses (index.html `#view-record`
// 2958–2975; `gateLiveRound` 4206 for the real-account copy; IA P4).
//
// Post a round — after · Play now — during · Plan a tee time — before. The ⊕
// is a verb, not a place: it presents over whichever tab you were on, and
// "Post" is the 90% case, one tap in.

import SwiftUI
import CSDesign
import CupSeasonKit

/// The doors out of the ⊕. The host wires them; a nil `openLive` means the
/// live round is not on this phone yet and the card presents the honest
/// hand-off (the web scores the group live today) — never a dead button.
struct PostLinks {
  /// "Play now" — the live round (its own slice).
  var openLive: (() -> Void)? = nil
  var openReceipt: (UUID) -> Void = { _ in }
  var openPeople: () -> Void = {}
}

struct PostCoverView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  let links: PostLinks
  @State private var path = NavigationPath()
  @State private var showPlan = false
  @State private var showLiveHandoff = false

  init(links: PostLinks = PostLinks()) { self.links = links }

  enum Route: Hashable { case post }

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text("Golf · before, during and after the round").csEyebrow()
          PostOptionCard(spine: cs.brand, title: "Post a round — after you play",
                         sub: "Gross + tee, 20 seconds · counts on your card and in every league") { path.append(Route.post) }
          PostOptionCard(spine: cs.sq0, title: "Play now — score the group live",
                         sub: "A shared pencil: match play, Wolf & the settle-up. Post your gross after — the finish screen hands it to you.") {
            if let live = links.openLive { dismiss(); live() } else { showLiveHandoff = true }
          }
          PostOptionCard(spine: cs.gold, title: "Plan a tee time — before",
                         sub: "Put a round on the tee sheet · your buddies and leagues see it the moment you post") { showPlan = true }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .navigationDestination(for: Route.self) { r in
        switch r {
        case .post: PostRoundScreen(links: links, onDone: { dismiss() })
        }
      }
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.foregroundStyle(cs.mut) } }
      .sheet(isPresented: $showPlan) { DeclareRoundSheet(leagueId: store.preferredLeague) { _ in dismiss() } }
      .sheet(isPresented: $showLiveHandoff) { PostLiveHandoffSheet() }
    }
  }
}

/// Wave 4 hand-off: the shared pencil is not on the phone yet. Honest, and a
/// real action — the web scores the group live today.
struct PostLiveHandoffSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 14) {
        Text("Play now — score the group live").csEyebrow()
        Text("The shared pencil lands on the phone in wave 4.").font(CSFont.title).foregroundStyle(cs.ink)
        Text("Until then, score the group live at cupseason.app — match play, Wolf & the settle-up. Post your gross after; the finish screen hands it to you.")
          .font(CSFont.body).foregroundStyle(cs.mut)
        Link(destination: CSConfig.webOrigin) {
          Text("Open cupseason.app").font(CSFont.button).frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(cs.bg0).background(cs.brand, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        }
        Spacer()
      }
      .padding(24).background(cs.bg0)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
    }
    .presentationDetents([.medium])
  }
}

/// `.optcard` — the spine in the tense's colour, a title, a line, the `→`.
struct PostOptionCard: View {
  @Environment(\.cs) private var cs
  let spine: Color
  let title: String
  let sub: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      CSCard(spine: spine) {
        HStack(alignment: .center, spacing: 12) {
          VStack(alignment: .leading, spacing: 4) {
            Text(title).font(CSFont.title).foregroundStyle(cs.ink).multilineTextAlignment(.leading)
            Text(sub).font(CSFont.subhead).foregroundStyle(cs.mut).multilineTextAlignment(.leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          Text("→").font(CSFont.title).foregroundStyle(spine)
        }
        .padding(.leading, 6)
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
