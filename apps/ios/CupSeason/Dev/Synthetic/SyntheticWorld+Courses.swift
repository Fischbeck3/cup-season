// Cup Season — synthetic reads for Courses (see SyntheticWorld.swift).

#if DEBUG
import Foundation
import CupSeasonKit

extension SyntheticWorld {
  func coursesTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? { nil }
  func coursesFunction(_ f: String, _ r: SynthRequest) -> SyntheticReply? { nil }
  func coursesRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    case "my_course_books": return SynthOut.json([Any]())
    default: return nil
    }
  }
}
#endif
