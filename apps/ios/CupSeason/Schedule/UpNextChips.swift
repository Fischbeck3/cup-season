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
  /// D176 · where a tapped chip goes. Home owns the routing; this view only
  /// says which door was knocked on.
  var go: (UpChip.Go) -> Void = { _ in }

  init(leagueId: UUID? = nil, links: CSLinks = CSLinks(), go: @escaping (UpChip.Go) -> Void = { _ in }) {
    self.leagueId = leagueId; self.links = links; self.go = go
  }

  var body: some View {
    // A VStack, not a Group: Group forwards its modifiers to its children, and
    // with no chips it has none — so the `.task` below never ran and the strip
    // could never load its first chip. The stack exists even while empty.
    VStack(spacing: 0) {
      if !vm.chips.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(vm.chips) { c in
              Button { if let d = c.go { CSHaptic.selection(); go(d) } } label: { chip(c) }
                .buttonStyle(.plain)
                .disabled(c.go == nil)
                .accessibilityHint(c.go == nil ? "" : "Opens \(hint(c.go!))")
            }
          }
          .padding(.vertical, 1)
        }
      }
    }
    .task(id: store.me?.memberships.count) {
      await vm.load(hasMemberships: leagueId != nil || !(store.me?.memberships.isEmpty ?? true))
    }
  }

  /// D176 · amber means URGENT, so it is spent only where it is. The chip
  /// appears from ten days out (that is when planning helps); it turns warm at
  /// three, when the arithmetic stops being advisory.
  private func chip(_ c: UpChip) -> some View {
    let hot = c.k == "Month closes" && isSoon(c.v)
    return HStack(spacing: 8) {
      Text(c.k).font(CSFont.label).tracking(1).textCase(.uppercase).foregroundStyle(hot ? cs.warm : cs.mut)
      Text(c.v).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
      if c.go != nil { Text("›").font(CSFont.subhead).foregroundStyle(cs.brand) }
    }
    .padding(.horizontal, 12).frame(minHeight: 36)
    .contentShape(Capsule())
    .background(cs.bg1, in: Capsule())
    .overlay(Capsule().stroke(hot ? cs.warm.opacity(0.7) : cs.line, lineWidth: 1))
    .accessibilityElement(children: .combine)
  }

  /// "today" · "in 1 day" · "in 2 days" · "in 3 days" — and nothing past that.
  private func isSoon(_ v: String) -> Bool {
    if v == "today" { return true }
    guard let n = Int(v.filter(\.isNumber)) else { return false }
    return n <= 3
  }

  private func hint(_ g: UpChip.Go) -> String {
    switch g {
    case .round:     return "the round"
    case .calendar:  return "your golf calendar"
    case .people:    return "your buddies"
    case .standings: return "the league"
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
