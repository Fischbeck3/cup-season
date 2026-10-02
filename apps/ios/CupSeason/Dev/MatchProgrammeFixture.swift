// DEBUG-only walkthrough data. Never written, published to widgets, or shipped.
// Captures through this hatch are evidence about layout, not real golfers.
#if DEBUG
import Foundation
import CupSeasonKit

@MainActor enum MatchProgrammeFixture {
  static let mode = argument("-cs_dev_programme_fixture")
  static var on: Bool { mode != nil }
  private static var phone: Bool { mode?.hasPrefix("phone") == true }
  static var payload: HomeDispatch.Payload? {
    HomeStateFixtures.payload(mode == "empty" ? "brand_new" : "event_live")
  }
  static var items: [HomeItem] {
    guard on, mode != "empty" else { return [] }
    return (0..<3).compactMap { index in
      let names = mode == "long" ? ["QA golfer with a deliberately long display name", "QA second golfer", "QA third golfer"] : ["QA Mike", "QA Natalie", "QA Alex"]
      var row: [String: Any] = [
        "round_id": "C5000000-0000-4000-8000-00000000000\(index + 1)",
        "profile_id": "C5000000-0000-4000-8000-00000000001\(index + 1)",
        "golfer": phone && index == 0 ? "QA Galen" : names[index], "marker": "lonetree", "gross": phone && index == 0 ? 79 : [82, 89, 78][index],
        "course": mode == "long" ? "QA championship course with a deliberately long name" : "QA Papago",
        "played_on": CSDate.today(), "pvi": [2.4, -1.0, 0.0][index], "is_pr": false, "is_first": false,
        "is_sub80": index == 2, "is_me": false
      ]
      if phone, index == 0 {
        row["course"] = "QA Kaanapali Golf Resort — Royal Kaanapali Course · Keo Makamae (White)"
        row["pvi"] = 0.0
      }
      if mode == "missing", index == 0 { row.removeValue(forKey: "gross") }
      if index == 0, ["photo", "failed", "phone", "phone_failed"].contains(mode ?? "") {
        row["photo_path"] = "C5000000-0000-4000-8000-000000000011/qa-round.jpg"
      }
      guard let data = try? JSONSerialization.data(withJSONObject: row),
            let value = try? JSONDecoder().decode(HomeFeedRow.self, from: data) else { return nil }
      var photo: URL?
      if index == 0, mode == "photo" || mode == "phone", let path = argument("-cs_dev_programme_photo") {
        photo = URL(fileURLWithPath: path)
      } else if index == 0, mode == "failed" || mode == "phone_failed" {
        photo = URL(string: "http://127.0.0.1:1/unavailable.jpg")
      }
      return .round(value, photoURL: photo)
    }
  }
  static var social: HomeSocial.Snapshot {
    var snapshot = HomeSocial.Snapshot()
    guard phone,
          let rid = UUID(uuidString: "C5000000-0000-4000-8000-000000000001"),
          let pid = UUID(uuidString: "C5000000-0000-4000-8000-000000000021") else { return snapshot }
    snapshot.targets[rid] = .init(postId: pid, leagueId: nil)
    return snapshot
  }
  static var roundSocial: [UUID: JSONValue] {
    guard phone, let rid = UUID(uuidString: "C5000000-0000-4000-8000-000000000001") else { return [:] }
    return [rid: .object([
      "comment_count": .number(2),
      "course": .object(["api_course_id": .string("qa-course"), "name": .string("QA Kaanapali")])
    ])]
  }
  private static func argument(_ flag: String) -> String? {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: flag), i + 1 < a.count else { return nil }
    return a[i + 1]
  }
}
#endif
