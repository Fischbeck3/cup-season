import SwiftUI
import CSDesign
import CupSeasonKit

/// D353 · the two ways out of an after-golf card.
///
/// They are LAYOUT controls on the item, never a new route kind: both clients
/// drop an item whose route they do not recognise (G1, the fence), so a new
/// kind would make the whole card vanish on every build already in the field.
///
/// "Add my round" keeps the ember. These stay quiet — the round is the point,
/// and these are the ways out of being asked about it. Neither needs a
/// confirmation: "Didn't play" is reversible by posting the round.
struct AfterGolfAnswers: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  let item: HomeDispatch.Item
  /// Re-read the ranker. The client never computes the snooze or hides the card
  /// from local state — it asks again and renders what comes back.
  var reload: () async -> Void = {}

  @State private var busy = false
  private let repo = HomeStreamRepository()

  var body: some View {
    if let plan = item.plan {
      A11yStack(spacing: CSTokens.Space.gutter) {
        answer(AfterGolfCopy.later, .later, plan.planId)
        answer(AfterGolfCopy.didntPlay, .didntPlay, plan.planId)
      }
      .padding(.top, CSTokens.Space.s3)
      .accessibilityElement(children: .contain)
      .accessibilityLabel(Text(AfterGolfCopy.groupLabel))
    }
  }

  private func answer(_ label: String, _ choice: PlanAnswer.Choice, _ plan: UUID) -> some View {
    CSDoor(.link(label) { Task { await send(choice, plan) } })
      .disabled(busy)
  }

  /// Both controls go dead for the round trip, so a double tap cannot send two
  /// answers. The card is hidden only by the ranker's next answer — never
  /// locally, and never on a failure.
  private func send(_ choice: PlanAnswer.Choice, _ plan: UUID) async {
    guard !busy else { return }
    busy = true
    defer { busy = false }
    do {
      let out = try await repo.answerPlan(plan, choice)
      // `applied == false` with a reason is RESOLVED, not failed: the plan was
      // already terminal, or it was never this golfer's to answer. Either way
      // the question is settled and the card goes.
      if out.applied {
        toast.show(choice == .later ? AfterGolfCopy.laterDone : AfterGolfCopy.didntPlayDone, kind: .confirmed)
      } else if out.reason == .terminal {
        toast.show(AfterGolfCopy.alreadyAnswered)
      }
      await reload()
    } catch {
      // Nothing local is written. The card stays exactly where it was.
      toast.show(HumanError.text(error, prefix: AfterGolfCopy.answerFailed), kind: .failed)
    }
  }
}

#if DEBUG
/// `-cs_dev_home_state <id>` over a signed-out root, so any state in the Home
/// matrix — including the after-golf card, which needs a plan, a session and a
/// server carrying the migration — can be photographed in both themes and at
/// accessibility text sizes. Its own view, because the root's body is already
/// at the type-checker's limit.
struct HomeFixtureOverlay: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  var body: some View {
    if CSDevHatch.fixtureHome, store.me == nil {
      // Every door is nil: a fixture is a picture of a state, not a place to
      // navigate from, and a tap that led somewhere would leave the fixture.
      NavigationStack { HomeView(links: CSLinks(), push: { _ in }) }
        .background(cs.bg0.ignoresSafeArea())
    }
  }
}
#endif
