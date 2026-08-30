// Cup Season — D156 · who is standing on this tee.
//
// Bluetooth / local peer discovery, never CoreLocation. No location permission,
// nothing about anyone's whereabouts on a server, and it works in a canyon with
// no signal — which is a golf course. "We are standing on the same tee" is
// literally the signal, measured instead of inferred from two coordinates.
//
// The privacy shape is the decision, so it is spelled out here:
//
//   · NOTHING identifying goes out in the clear. `MCPeerID.displayName` is
//     visible to every browser on the network, so it is a random token per
//     session — never the golfer's name, handle, or profile id.
//   · Profile ids are exchanged only INSIDE the encrypted session, after both
//     sides chose to connect.
//   · A peer is NAMED only by the server, and only if `nearby_resolve` says the
//     two accounts are already buddies or league mates. A stranger's phone
//     produces nothing at all — not a name, not a count, not "someone nearby".
//   · Advertising runs only while the Add-players screen is open and only after
//     an explicit opt-in. Leaving the screen stops it. There is no background
//     mode and this file must never acquire one.
//
// A nearby phone fills the picker; it never fills the round. You still tap.

import Foundation
import MultipeerConnectivity

/// 1–15 chars, lowercase ASCII + hyphens — Bonjour's rule, not ours.
private let kServiceType = "cs-tee"

/// The MultipeerConnectivity side, kept OFF the main actor on purpose.
///
/// MC is a pre-concurrency delegate API: `MCPeerID`, `MCSession` and the
/// invitation handler are not Sendable, and its callbacks arrive on arbitrary
/// queues. Holding those objects on the main actor and awaiting across them is
/// a strict-concurrency error, so they live here behind `@unchecked Sendable`
/// with one internal queue serialising every touch — and the ONLY thing that
/// ever crosses back out is a `UUID`, which is Sendable.
private final class NearbyTransport: NSObject, @unchecked Sendable {
  private let q = DispatchQueue(label: "cs.nearby")
  private let me: UUID
  private let peer: MCPeerID
  private let session: MCSession
  private let advertiser: MCNearbyServiceAdvertiser
  private let browser: MCNearbyServiceBrowser
  private let found: @Sendable (UUID) -> Void

  init(me: UUID, found: @escaping @Sendable (UUID) -> Void) {
    self.me = me
    self.found = found
    // a random display name: the peer id is broadcast in the CLEAR, so it
    // carries nothing about the golfer holding the phone
    peer = MCPeerID(displayName: String(UUID().uuidString.prefix(8)))
    session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
    advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: kServiceType)
    browser = MCNearbyServiceBrowser(peer: peer, serviceType: kServiceType)
    super.init()
    session.delegate = self
    advertiser.delegate = self
    browser.delegate = self
  }

  func start() {
    q.async { [self] in advertiser.startAdvertisingPeer(); browser.startBrowsingForPeers() }
  }

  func stop() {
    q.async { [self] in
      advertiser.stopAdvertisingPeer()
      browser.stopBrowsingForPeers()
      session.disconnect()
    }
  }
}

extension NearbyTransport: MCSessionDelegate {
  func session(_ s: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    guard state == .connected else { return }
    // the profile id goes out only INSIDE the encrypted session, after both
    // sides chose to connect
    try? s.send(Data(me.uuidString.utf8), toPeers: [peerID], with: .reliable)
  }
  func session(_ s: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    guard let text = String(data: data, encoding: .utf8), let id = UUID(uuidString: text), id != me else { return }
    found(id)
  }
  func session(_ s: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
  func session(_ s: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
  func session(_ s: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

extension NearbyTransport: MCNearbyServiceAdvertiserDelegate {
  func advertiser(_ a: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                  withContext: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    invitationHandler(true, session)
  }
  func advertiser(_ a: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {}
}

extension NearbyTransport: MCNearbyServiceBrowserDelegate {
  func browser(_ b: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo: [String: String]?) {
    b.invitePeer(peerID, to: session, withContext: nil, timeout: 12)
  }
  func browser(_ b: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
  func browser(_ b: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}
}

@MainActor
@Observable
final class NearbyService {

  /// profile ids seen on this tee, in the order they appeared
  private(set) var seen: [UUID] = []
  private(set) var running = false

  /// Raised whenever `seen` grows, so the caller can ask the server for names.
  var onChange: (@MainActor ([UUID]) -> Void)?

  private var transport: NearbyTransport?

  func start(myProfile: UUID) {
    guard !running else { return }
    let t = NearbyTransport(me: myProfile) { [weak self] id in
      Task { @MainActor in self?.note(id) }
    }
    transport = t
    t.start()
    running = true
  }

  func stop() {
    transport?.stop()
    transport = nil
    running = false
    seen = []
  }

  private func note(_ id: UUID) {
    guard !seen.contains(id) else { return }
    seen.append(id)
    onChange?(seen)
  }
}
