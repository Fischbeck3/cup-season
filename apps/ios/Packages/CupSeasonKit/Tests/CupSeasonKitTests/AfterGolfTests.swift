import Testing
import Foundation
@testable import CupSeasonKit

/// D353 · the band waits for a client that can answer it, and the item carries
/// the plan it is about. D354 · a plan fills the composer in, and never
/// overwrites work without being told to.
@Suite struct AfterGolfContractTests {

  private func item(_ json: String) throws -> HomeDispatch.Item {
    try JSONDecoder().decode(HomeDispatch.Item.self, from: Data(json.utf8))
  }

  private let full = """
  {"key":"afterplan:c0000000-0000-4000-8000-0000000000a1","tier":"changed","rank":1,"score":806,
   "subject":"you","human_subject":true,"eyebrow":"SAT · PAPAGO",
   "headline":"You planned a round for yesterday.","standfirst":"Nothing posted yet.",
   "action":"Add my round","route":{"kind":"composer"},"spine":"ember","at":"2026-09-12",
   "context":{"plan_id":"c0000000-0000-4000-8000-0000000000a1","play_on":"2026-09-12",
              "course_label":"Papago","course_id":null,"tee_time":null}}
  """

  @Test func theItemCarriesThePlanOutsideTheDisplayKey() throws {
    let it = try item(full)
    #expect(it.plan?.planId == UUID(uuidString: "c0000000-0000-4000-8000-0000000000a1"))
    #expect(it.plan?.playOn == "2026-09-12")
    // the RAW label, not the uppercased one inside the eyebrow
    #expect(it.plan?.courseLabel == "Papago")
    #expect(it.plan?.courseId == nil)
    #expect(it.answerable)
    #expect(it.route == .composer, "and the door stays one every shipped build knows")
  }

  /// An older server sends no context. The card is then a door and nothing
  /// more — which is safe, because that same server has no capability gate and
  /// so sends no afterplan item at all.
  @Test func anItemWithoutContextIsNotAnswerable() throws {
    let it = try item("""
    {"key":"afterplan:c0000000-0000-4000-8000-0000000000a1","tier":"changed","eyebrow":"SAT",
     "headline":"You planned a round for yesterday.","action":"Add my round",
     "route":{"kind":"composer"},"at":"2026-09-12"}
    """)
    #expect(it.plan == nil)
    #expect(it.answerable == false)
    #expect(it.route == .composer, "it still opens the composer — it just cannot be answered")
  }

  @Test func anotherItemIsNeverAnswerable() throws {
    let it = try item("""
    {"key":"plan:c0000000-0000-4000-8000-0000000000a1","tier":"coming","eyebrow":"SAT",
     "headline":"You have a round today.","action":"See the plan",
     "route":{"kind":"plan","id":"c0000000-0000-4000-8000-0000000000a1"},"at":"2026-09-12",
     "context":{"plan_id":"c0000000-0000-4000-8000-0000000000a1","play_on":"2026-09-12"}}
    """)
    #expect(it.answerable == false, "the answers belong to the after-golf card alone")
  }

  @Test func theBuildNamesOnlyWhatItImplements() {
    #expect(HomeCapability.all == ["afterplan.v1"])
    #expect(HomeCapability.afterPlan == "afterplan.v1")
  }

  /// The retry drops the capability AND the day together, which is the shape a
  /// server that has never heard of either can answer.
  @Test func bothNewArgumentsAreDroppedTogether() {
    #expect(HomeStreamRepository.DispatchCall.optionalArgs == ["p_today", "p_caps"])
    let call = HomeStreamRepository.DispatchCall(p_days: 21)
    #expect(call.p_caps == HomeCapability.all)
    #expect(call.p_today == CSDate.today())
  }

  /// The answer identifies the day, so the server never decides "has this
  /// happened yet" from its own clock.
  @Test func theAnswerNeverDropsTheGolfersDay() {
    #expect(HomeStreamRepository.AnswerPlanCall.optionalArgs.isEmpty)
  }

  @Test func anAnswerSaysWhatItDid() throws {
    func decode(_ s: String) throws -> PlanAnswer {
      try JSONDecoder().decode(PlanAnswer.self, from: Data(s.utf8))
    }
    let ok = try decode(#"{"plan_id":"c0000000-0000-4000-8000-0000000000a1","answer":"later","snooze_until":"2026-09-14","applied":true,"reason":null}"#)
    #expect(ok.applied && ok.reason == nil && ok.resolved)
    #expect(ok.snoozeUntil == "2026-09-14", "the snooze is the server's, never computed here")

    let terminal = try decode(#"{"plan_id":"c0000000-0000-4000-8000-0000000000a1","answer":"didnt_play","snooze_until":null,"applied":false,"reason":"terminal"}"#)
    #expect(!terminal.applied && terminal.reason == .terminal)
    #expect(terminal.resolved, "already answered is settled, not failed — the card still goes")

    let gone = try decode(#"{"plan_id":"c0000000-0000-4000-8000-0000000000a1","answer":null,"snooze_until":null,"applied":false,"reason":"not_available"}"#)
    #expect(gone.reason == .notAvailable && gone.resolved)

    // an older shape, or a reason this build has never heard of
    let bare = try decode(#"{"applied":false}"#)
    #expect(!bare.resolved, "nothing settled and nothing claimed")
  }

  @Test func theTwoAnswersAreTheOnesTheServerAccepts() {
    #expect(PlanAnswer.Choice.later.rawValue == "later")
    #expect(PlanAnswer.Choice.didntPlay.rawValue == "didnt_play")
    #expect(PlanAnswer.Choice.allCases.count == 2)
  }
}

/// D354 · what a plan may write onto a card.
@Suite struct PlanPrefillTests {
  private let ctx = PlanContext(planId: UUID(), playOn: "2026-09-12",
                                courseLabel: "Papago", courseId: "gc-991", teeTime: "08:00")

  @Test func theDayThatWasPlayedIsTheOneFactThatClosesTheLoop() {
    var c = PostCard(); c.date = "2026-09-13"
    c.fill(plan: ctx)
    #expect(c.date == "2026-09-12")
  }

  /// A course id without a tee has no rating and no slope. Stamping one would
  /// claim the catalogue supplied figures the golfer is about to type.
  @Test func theCourseGoesInAsTextAndNeverAsAnIdentity() {
    var c = PostCard(); c.courseId = "stale"
    c.fill(plan: ctx)
    #expect(c.course == "Papago")
    #expect(c.courseId == nil)
    #expect(c.rating.isEmpty && c.slope.isEmpty, "no figures are invented")
  }

  @Test func aCourseTheGolferNamedIsLeftAlone() {
    var c = PostCard(); c.course = "Somewhere else"; c.courseId = "mine"
    c.fill(plan: ctx)
    #expect(c.course == "Somewhere else")
    #expect(c.courseId == "mine")
    #expect(c.date == "2026-09-12", "the date still lands — it is the fact that closes the loop")
  }

  @Test func nothingElseIsEverFilledIn() {
    var c = PostCard()
    c.fill(plan: ctx)
    #expect(c.whole.isEmpty && c.f9.isEmpty && c.b9.isEmpty)
    #expect(c.touched == false, "a plan is not a scorecard")
    #expect(c.scores == PostCard.parStd, "and it enters no strokes")
  }

  @Test func aPlanWithNothingToSaySaysNothing() {
    var c = PostCard(); c.date = "2026-09-13"; c.course = ""
    c.fill(plan: PlanContext(planId: UUID()))
    #expect(c.date == "2026-09-13")
    #expect(c.course.isEmpty)
  }

  /// The three identities stay apart on disk: a plan is display context, a
  /// request is what the server deduplicates on, a kept scorecard already exists.
  @Test func theDraftKeepsThreeSeparateIdentities() throws {
    var c = PostCard(); c.date = "2026-09-12"; c.whole = "84"
    let plan = UUID(), request = UUID(), live = UUID()
    let data = try #require(PostDraft.encode(PostDraft(card: c, sourceLive: live, request: request, plan: plan)))
    let back = try #require(PostDraft.decode(data))
    #expect(back.plan == plan)
    #expect(back.request == request)
    #expect(back.sourceLive == live)
  }

  /// A draft written before plans existed still decodes.
  @Test func anOlderDraftStillOpens() throws {
    var c = PostCard(); c.whole = "84"
    let data = try #require(PostDraft.encode(PostDraft(card: c, request: UUID())))
    let back = try #require(PostDraft.decode(data))
    #expect(back.plan == nil)
  }

  @Test func theQuestionNamesTheDayAndOnlyWhatChanges() {
    let withCourse = PostPlanCopyProbe.explain(ctx)
    #expect(withCourse.contains("date and course"))
    let bare = PostPlanCopyProbe.explain(PlanContext(planId: UUID(), playOn: "2026-09-12"))
    #expect(bare.contains("date") && !bare.contains("course"))
    for word in ["score", "point", "count"] {
      #expect(!withCourse.lowercased().contains(word), "a plan promises nothing about scoring: \(word)")
    }
  }
}

/// The app target owns `PostPlanCopy`; this mirrors its one rule so the Kit can
/// hold it. If the two ever disagree the app's dialog is the one that ships —
/// keep them identical.
enum PostPlanCopyProbe {
  static func explain(_ ctx: PlanContext) -> String {
    let what = (ctx.courseLabel?.isEmpty == false) ? "date and course" : "date"
    return "Your card keeps whatever you have typed. This changes the \(what), and nothing else."
  }
}
