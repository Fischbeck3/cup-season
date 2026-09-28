// Cup Season — synthetic reads for Rounds (see SyntheticWorld.swift).

#if DEBUG
import Foundation
import CupSeasonKit

extension SyntheticWorld {
  func roundsTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? {
    switch t {
    case "live_rounds": return SynthOut.rows([], r)
    default: return nil
    }
  }
  func roundsRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    default: return nil
    }
  }
}
#endif
