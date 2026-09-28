// Cup Season — synthetic reads for Season (see SyntheticWorld.swift).

#if DEBUG
import Foundation
import CupSeasonKit

extension SyntheticWorld {
  func seasonTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? { nil }
  func seasonRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    default: return nil
    }
  }
}
#endif
