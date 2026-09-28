// Cup Season — synthetic reads for Events (see SyntheticWorld.swift).

#if DEBUG
import Foundation
import CupSeasonKit

extension SyntheticWorld {
  func eventsTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? { nil }
  func eventsForMe() -> [[String: Any]] { [] }
  func eventsRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    default: return nil
    }
  }
}
#endif
