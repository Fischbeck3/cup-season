// Cup Season — the door's developer hatches (DEBUG only; the web's `/?exit`
// and `?forge` family). A simulator cannot type and must never sign the
// owner out, so launch arguments stand in:
//   -cs_dev_door    present the door over the root whatever the session is
//                   (no auth call fires unless a button is tapped)
//   -cs_dev_forge   replay the Forge (screenshots, video)
//   -cs_dev_apple   render the Apple button as if the flag were on
// `-cs_dev_email` / `-cs_dev_code` live in DoorModel.devHatch.

#if DEBUG
import Foundation

enum DoorDev {
  private static let args = ProcessInfo.processInfo.arguments
  static let forced = args.contains("-cs_dev_door")
  static let replayForge = args.contains("-cs_dev_forge")
  static let forceApple = args.contains("-cs_dev_apple")
}
#endif
