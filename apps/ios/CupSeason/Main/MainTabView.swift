// Cup Season — the four places (D82, IOS-011): Home · Clubhouse · ⊕ · You.

import SwiftUI
import CSDesign
import CupSeasonKit

struct MainTabView: View {
  @Environment(\.cs) private var cs
  @State private var tab: Tab = .home
  @State private var showPost = false
  enum Tab: Hashable { case home, clubhouse, post, you }

  var body: some View {
    TabView(selection: $tab) {
      NavigationStack { HomeView() }
        .tabItem { Label("Home", systemImage: "house") }
        .tag(Tab.home)
      NavigationStack { ClubhouseView() }
        .tabItem { Label("Clubhouse", systemImage: "flag") }
        .tag(Tab.clubhouse)
      Color.clear
        .tabItem { Label("Post", systemImage: "plus.circle.fill") }
        .tag(Tab.post)
      NavigationStack { YouView() }
        .tabItem { Label("You", systemImage: "person.text.rectangle") }
        .tag(Tab.you)
    }
    .tint(cs.brand)
    .onChange(of: tab) { old, new in
      // the ⊕ is a verb, not a place: it presents, and the selection snaps back
      if new == .post { showPost = true; tab = old == .post ? .home : old }
    }
    .fullScreenCover(isPresented: $showPost) { PostCoverView() }
  }
}
