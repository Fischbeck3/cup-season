import Foundation
import Testing
@testable import CupSeason
import CupSeasonKit

@Suite @MainActor struct PresentationHandoffTests {
  @Test(arguments: [false, true]) func incomingRouteDismissesEitherBagBeforePresenting(readOnly: Bool) async {
    let delay = PresentationPause(), presenter = Presenter(settle: { _ in await delay.pause() })
    if readOnly { presenter.bagOf = UUID(); presenter.bagOfName = "Alex" }
    else { presenter.showBag = true }
    #expect(presenter.anythingUp)
    let receipt = UUID()
    let route = presenter.handoff(isCurrent: { true }) { presenter.receipt = receipt }
    await delay.entered(1)
    #expect(!presenter.showBag && presenter.bagOf == nil && presenter.bagOfName == nil)
    #expect(presenter.receipt == nil && !presenter.stageIsClear)
    delay.release(0); await route.value
    #expect(presenter.receipt == receipt && !presenter.isTransitioning)
  }

  @Test func cancellationDuringDismissalNeverPresents() async {
    let delay = PresentationPause(), presenter = Presenter(settle: { _ in await delay.pause() })
    presenter.showBag = true
    let route = presenter.handoff(isCurrent: { true }) { presenter.receipt = UUID() }
    await delay.entered(1)
    presenter.cancelHandoff()
    delay.release(0); await route.value
    #expect(presenter.receipt == nil && presenter.stageIsClear)
  }

  @Test func laterRouteOwnsTheHandoffAndStillWaitsForTheCurtain() async {
    let delay = PresentationPause(), presenter = Presenter(settle: { _ in await delay.pause() })
    presenter.showBag = true
    let oldID = UUID(), newID = UUID()
    let old = presenter.handoff(isCurrent: { true }) { presenter.receipt = oldID }
    await delay.entered(1)
    let next = presenter.handoff(isCurrent: { true }) { presenter.receipt = newID }
    await delay.entered(2)
    delay.release(0); await old.value
    #expect(presenter.receipt == nil && presenter.isTransitioning)
    delay.release(1); await next.value
    #expect(presenter.receipt == newID)
  }

  @Test func accountChangeDuringDismissalDiscardsDestination() async {
    let delay = PresentationPause(), presenter = Presenter(settle: { _ in await delay.pause() })
    let owner = UUID(); var account: UUID? = owner
    presenter.showPost = true
    let route = presenter.handoff(isCurrent: { account == owner }) { presenter.receipt = UUID() }
    await delay.entered(1)
    account = UUID()
    delay.release(0); await route.value
    #expect(presenter.receipt == nil && presenter.stageIsClear)
  }

  @Test func authorizationIsRecheckedAfterPreparingAnActivityRound() async {
    let preparation = PresentationPause(), presenter = Presenter()
    let owner = UUID(); var account: UUID? = owner
    let route = presenter.handoff(dismissExisting: false, isCurrent: { account == owner }, prepare: {
      await preparation.pause(); return true
    }, present: { presenter.showLive = true })
    await preparation.entered(1)
    account = nil
    preparation.release(0); await route.value
    #expect(!presenter.showLive && presenter.stageIsClear)
  }

  @Test func liveRouteKeepsTheExistingLiveSurface() async {
    var waits = 0
    let presenter = Presenter(settle: { _ in waits += 1 })
    presenter.showLive = true
    var landed = false
    await presenter.handoff(dismissExisting: false, isCurrent: { true }) {
      #expect(presenter.showLive)
      landed = true
    }.value
    #expect(landed && waits == 0 && presenter.showLive)
  }

  @Test func passivePresentationDoesNotOvertakeAnIncomingRoute() async {
    let delay = PresentationPause(), presenter = Presenter(settle: { _ in await delay.pause() })
    let passive = Task { await presenter.waitForClearStage(isCurrent: { true }) }
    await delay.entered(1)
    await presenter.handoff(isCurrent: { true }) { presenter.receipt = UUID() }.value
    delay.release(0)
    #expect(await passive.value == false)
  }

  @Test func permissionReadKeepsItsMomentWhenARouteTakesTheStage() async {
    let settings = PresentationPause(), presenter = Presenter()
    let ask = PushAsk(authorization: { await settings.pause(); return .undetermined })
    ask.request(.firstRound)
    let prompt = Task { await ask.presentIfDue(while: { presenter.stageIsClear }) }
    await settings.entered(1)
    await presenter.handoff(isCurrent: { true }) { presenter.receipt = UUID() }.value
    settings.release(0); await prompt.value
    #expect(ask.presented == nil && ask.pending == .firstRound)
  }

  @Test func permissionRetryCanFinishWhileACancelledReadIsStillPending() async {
    let settings = PresentationPause()
    let ask = PushAsk(authorization: { await settings.pause(); return .denied })
    ask.request(.firstRound)
    let old = Task { await ask.presentIfDue(while: { true }) }
    await settings.entered(1)
    old.cancel()
    let retry = Task { await ask.presentIfDue(while: { true }) }
    await settings.entered(2)
    settings.release(1); await retry.value
    settings.release(0); await old.value
    #expect(ask.pending == nil && ask.presented == nil)
  }
}

/// Suspends the real handoff at its timing/settings seam, without wall-clock sleeps.
@MainActor private final class PresentationPause {
  private var waits: [CheckedContinuation<Void, Never>?] = []
  private var observers: [(Int, CheckedContinuation<Void, Never>)] = []
  func pause() async {
    await withCheckedContinuation { continuation in
      waits.append(continuation)
      let ready = observers.filter { $0.0 <= waits.count }
      observers.removeAll { $0.0 <= waits.count }
      ready.forEach { $0.1.resume() }
    }
  }
  func entered(_ count: Int) async {
    if waits.count >= count { return }
    await withCheckedContinuation { observers.append((count, $0)) }
  }
  func release(_ index: Int) {
    waits[index]?.resume(); waits[index] = nil
  }
}
