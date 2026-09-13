import XCTest
@testable import CupSeason
@testable import CupSeasonKit

/// F1 · the route from an after-golf door to the composer, at the seam where it
/// actually lives. `HomeView.take(_:)` puts the item's plan on `PlanHandoff` and
/// raises the composer; `PostRoundScreen` takes it back once and hands it to
/// `PostRoundModel.take(plan:)`. The UI tests prove the controls render and can
/// be tapped in every placement; this proves what the tap CARRIES, including the
/// three states that decide whether a plan may write at all.
@MainActor final class AfterGolfPlanRouteTests: XCTestCase {

  private let plan = PlanContext(planId: UUID(uuidString: "c0000000-0000-4000-8000-0000000000a1")!,
                                 playOn: "2026-09-11", courseLabel: "Papago",
                                 courseId: nil, teeTime: "08:10")

  override func tearDown() {
    PlanHandoff.shared.pending = nil
    super.tearDown()
  }

  /// Read once and cleared, so a plan cannot arrive twice or outlive its tap.
  func testTheHandoffIsReadOnceAndCleared() {
    PlanHandoff.shared.pending = plan
    XCTAssertEqual(PlanHandoff.shared.take()?.planId, plan.planId)
    XCTAssertNil(PlanHandoff.shared.take(), "a plan survived the tap that sent it")
    XCTAssertNil(PlanHandoff.shared.pending)
  }

  /// A blank composer takes the day that was PLAYED, and the course as TEXT.
  /// A blank composer dated today was the whole defect.
  func testABlankComposerTakesThePlanDayAndCourse() {
    var card = PostCard()
    card.date = "2026-09-13"                       // the stamp, not a choice
    card.fill(plan: plan)
    XCTAssertEqual(card.date, "2026-09-11")
    XCTAssertEqual(card.course, "Papago")
    XCTAssertNil(card.courseId, "a catalogue id was claimed without a tee")
    XCTAssertTrue(card.whole.isEmpty && card.f9.isEmpty && card.b9.isEmpty)
    XCTAssertFalse(card.touched, "a plan is not a scorecard")
  }

  /// A course the golfer typed is left alone, and the question says so.
  func testATypedCourseIsKeptAndTheQuestionSaysSo() {
    var card = PostCard()
    card.date = "2026-09-13"
    card.course = "Somewhere else"
    card.courseId = "mine"
    card.fill(plan: plan)
    XCTAssertEqual(card.course, "Somewhere else")
    XCTAssertEqual(card.courseId, "mine")
    XCTAssertEqual(card.date, "2026-09-11", "the day still lands — it is what closes the loop")

    let asked = PostPlanCopy.explain(plan, typedCourse: "Somewhere else")
    XCTAssertTrue(asked.contains("This changes the date, and nothing else"))
    XCTAssertTrue(asked.contains("Somewhere else stays."))
    let blank = PostPlanCopy.explain(plan, typedCourse: "")
    XCTAssertTrue(blank.contains("the date and the course"))
  }

  /// The question names the day the golfer would be starting.
  func testTheQuestionNamesTheDay() {
    XCTAssertEqual(PostPlanCopy.start(plan), "Start \(PostPlanCopy.day(plan))’s round")
    XCTAssertFalse(PostPlanCopy.day(plan).isEmpty)
    XCTAssertEqual(PostPlanCopy.keep, "Keep the round I started")
  }

  /// `isUntouched` is the gate `take(plan:)` asks before it writes anything: a
  /// card carrying only the composer's own stamp is unstarted; anything the
  /// golfer typed — the gross included — is work and must be consented to.
  func testTheConsentGateCountsEveryTypedField() {
    let stamp = "2026-09-13"
    var blank = PostCard(); blank.date = stamp
    XCTAssertTrue(blank.isUntouched(defaultDate: stamp), "a stamped card should apply silently")

    for mutate in [{ (c: inout PostCard) in c.whole = "84" },
                   { c in c.f9 = "41" }, { c in c.b9 = "43" },
                   { c in c.rating = "71.2" }, { c in c.slope = "128" },
                   { c in c.course = "Papago" }, { c in c.touched = true }] {
      var c = PostCard(); c.date = stamp; mutate(&c)
      XCTAssertFalse(c.isUntouched(defaultDate: stamp), "work was treated as an empty card")
    }
    var chosen = PostCard(); chosen.date = "2026-09-07"
    XCTAssertFalse(chosen.isUntouched(defaultDate: stamp), "a date the golfer chose is work")
  }

  /// The three identities stay apart on the draft: a plan is display context, a
  /// request is what the server deduplicates on, a kept scorecard already exists.
  func testTheDraftKeepsThePlanApartFromTheOtherTwoIdentities() throws {
    var card = PostCard(); card.date = "2026-09-11"; card.whole = "84"
    let p = UUID(), r = UUID(), live = UUID()
    let data = try XCTUnwrap(PostDraft.encode(PostDraft(card: card, sourceLive: live, request: r, plan: p)))
    let back = try XCTUnwrap(PostDraft.decode(data))
    XCTAssertEqual(back.plan, p)
    XCTAssertEqual(back.request, r)
    XCTAssertEqual(back.sourceLive, live)
  }
}
