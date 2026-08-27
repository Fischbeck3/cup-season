// Cup Season — Up Next (`renderUpNext` 10653–10681): what's coming, one
// glance — next declared round, a buddy's plan, invites waiting, the
// month-close clock. Hides entirely when there's nothing coming.

import SwiftUI
import CSDesign
import CupSeasonKit

struct UpNextChips: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @State private var vm = UpNextModel()
  let leagueId: UUID?
  let links: CSLinks

  init(leagueId: UUID? = nil, links: CSLinks = CSLinks()) { self.leagueId = leagueId; self.links = links }

  var body: some View {
    Group {
      if !vm.chips.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(vm.chips) { c in
              HStack(spacing: 8) {
                Text(c.k).font(CSFont.label).tracking(1).textCase(.uppercase).foregroundStyle(cs.mut)
                Text(c.v).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
              }
              .padding(.horizontal, 12).frame(minHeight: 36)
              .background(cs.bg1, in: Capsule())
              .overlay(Capsule().stroke(c.k == "Month closes" ? cs.warm.opacity(0.7) : cs.line, lineWidth: 1))
              .accessibilityElement(children: .combine)
            }
          }
        }
      }
    }
    .task(id: store.me?.memberships.count) {
      await vm.load(hasMemberships: leagueId != nil || !(store.me?.memberships.isEmpty ?? true))
    }
  }
}

@MainActor
@Observable
final class UpNextModel {
  var chips: [UpChip] = []
  private let sched = ScheduleService()
  private let people = PeopleService()

  func load(hasMemberships: Bool) async {
    async let w = sched.watch()
    async let i = people.invites()
    async let f = people.friends()
    let watch = (try? await w) ?? []
    let invites = (try? await i)?.count ?? 0
    let requests = (try? await f)?.requests.count ?? 0
    chips = UpNext.chips(watch: watch, invites: invites, requests: requests, hasMemberships: hasMemberships)
  }
}

#Preview("Up Next") {
  UpNextChips().padding(20).environment(SessionStore()).csTheme()
}
