import Foundation

/// D353 · **what this build can do, said to the server.**
///
/// `p_today` was never a capability. It says the client knows its own calendar
/// day, which every candidate build already said, and it was the only gate the
/// after-golf band had — so the band went live on a client with no Later, no
/// Didn't play and no date prefill, and a golfer could neither answer it nor
/// make it go away. A capability is added to this list only when the code that
/// implements it ships in the same build.
public enum HomeCapability {
  /// The after-golf card: the two answers, and a composer that opens on the day
  /// that was played.
  public static let afterPlan = "afterplan.v1"
  public static let all: [String] = [afterPlan]
}

/// D353 · what `answer_plan_followup` says it did.
///
/// `applied == false` with a reason is a RESOLVED end state, not a failure:
/// the card goes either way. Only a thrown error keeps the card on Home.
public struct PlanAnswer: Decodable, Sendable, Equatable {
  public enum Choice: String, Sendable, CaseIterable {
    case later, didntPlay = "didnt_play"
  }
  /// `terminal` — already answered "Didn't play", which D345 makes final.
  /// `notAvailable` — scratched, or never this golfer's to answer. ONE reason
  /// for both, deliberately: a distinct answer would tell a stranger whether a
  /// given plan id exists.
  public enum Reason: String, Sendable { case terminal, notAvailable = "not_available" }

  public let planId: UUID?
  public let answer: String?
  public let snoozeUntil: String?
  public let applied: Bool
  public let reason: Reason?

  private enum CodingKeys: String, CodingKey {
    case plan_id, answer, snooze_until, applied, reason
  }
  public init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    func opt<T: Decodable>(_ t: T.Type, _ k: CodingKeys) -> T? { (try? c.decodeIfPresent(t, forKey: k)) ?? nil }
    planId = opt(UUID.self, .plan_id)
    answer = opt(String.self, .answer)
    snoozeUntil = opt(String.self, .snooze_until)
    applied = opt(Bool.self, .applied) ?? false
    reason = opt(String.self, .reason).flatMap(Reason.init(rawValue:))
  }
  public init(planId: UUID?, answer: String?, snoozeUntil: String?, applied: Bool, reason: Reason?) {
    self.planId = planId; self.answer = answer; self.snoozeUntil = snoozeUntil
    self.applied = applied; self.reason = reason
  }
  /// The card leaves Home on anything the server actually settled.
  public var resolved: Bool { applied || reason != nil }
}

/// D354 · the plan's own facts, carried on the item so a client can fill the
/// composer in faithfully.
///
/// Before this, the plan id existed only inside the display key and there was
/// no raw course label at all — only the uppercased one inside `eyebrow` — so a
/// client had to parse a display string to answer, and could not prefill a
/// course without inventing its spelling.
///
/// This is DISPLAY CONTEXT, never identity. It does not travel with the round,
/// it does not touch the frozen post request, and it adds no partners: a plan
/// carries no score and no attendance.
public struct PlanContext: Decodable, Sendable, Equatable {
  public let planId: UUID
  /// The day that was played, as the server wrote it. A String, per L-07.
  public let playOn: String?
  /// The course as the plan spells it. A label only — see `PostCard.fill(plan:)`.
  public let courseLabel: String?
  /// The catalogue id, when the plan named one. **Never stamped onto a card.**
  public let courseId: String?
  public let teeTime: String?

  private enum CodingKeys: String, CodingKey { case plan_id, play_on, course_label, course_id, tee_time }
  public init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    func opt<T: Decodable>(_ t: T.Type, _ k: CodingKeys) -> T? { (try? c.decodeIfPresent(t, forKey: k)) ?? nil }
    guard let id = opt(UUID.self, .plan_id) else {
      throw DecodingError.dataCorruptedError(forKey: .plan_id, in: c, debugDescription: "a plan context without a plan is not one")
    }
    planId = id
    playOn = opt(String.self, .play_on)
    courseLabel = opt(String.self, .course_label)
    courseId = opt(String.self, .course_id)
    teeTime = opt(String.self, .tee_time)
  }
  public init(planId: UUID, playOn: String? = nil, courseLabel: String? = nil,
              courseId: String? = nil, teeTime: String? = nil) {
    self.planId = planId; self.playOn = playOn; self.courseLabel = courseLabel
    self.courseId = courseId; self.teeTime = teeTime
  }
}

/// D354 · the plan on its way to the composer, mirroring how a kept scorecard
/// is handed over (`LiveRoundStore.pendingPost`). It is read once and cleared,
/// so a plan cannot arrive twice or outlive the tap that sent it.
@MainActor public final class PlanHandoff {
  public static let shared = PlanHandoff()
  public var pending: PlanContext?
  public func take() -> PlanContext? { defer { pending = nil }; return pending }
  private init() {}
}

/// The copy for the card's two ways out, and for what an answer did. Brief on
/// purpose: the round is the point, and these are the ways out of being asked.
public enum AfterGolfCopy {
  public static let later = "Later"
  public static let didntPlay = "Didn’t play"
  /// "Later" never promises when the question comes back. The client does not
  /// compute the snooze; it re-reads dispatch.
  public static let laterDone = "Okay — it’s off Home for now."
  public static let didntPlayDone = "Okay — nothing posted for that day."
  public static let alreadyAnswered = "That one was already answered."
  public static let answerFailed = "Couldn’t send that — try again."
  public static let groupLabel = "Answer about this round"
}
