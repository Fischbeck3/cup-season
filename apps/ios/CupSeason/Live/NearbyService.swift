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
import os

/// 1–15 chars, lowercase ASCII + hyphens — Bonjour's rule, not ours.
private let kServiceType = "cs-tee"

/// D158 · everything that crosses the wire. Three beats: HELLO (here is my
/// profile id), INVITE (come play), REPLY (yes / not me). Codable + Sendable so
/// it can cross the actor boundary the transport sits behind.
public struct NearbyMessage: Codable, Sendable, Equatable {
  public enum Kind: String, Codable, Sendable { case hello, invite, reply, teed }
  public var t: Kind
  /// the SENDER's profile id, always
  public var from: UUID
  /// invite only — who is asking, and to what
  public var name: String?
  public var course: String?
  public var game: String?
  /// reply only
  public var ok: Bool?
  /// teed only — the round now EXISTS, and this is it.
  ///
  /// D158 shipped without this and the hole was the whole point: at the moment
  /// someone accepts, there is no round yet — the starter is still on the setup
  /// screen. Accepting told the STARTER, and told the accepter nothing. Their
  /// phone sat there while a round they had agreed to play began somewhere else.
  public var lr: UUID?
}

/// An invitation as the receiving phone sees it.
public struct NearbyInvite: Identifiable, Sendable, Equatable {
  public var id: UUID { from }
  public let from: UUID
  public let name: String
  public let course: String
  public let game: String
}

/// The MultipeerConnectivity side, kept OFF the main actor on purpose.
///
/// MC is a pre-concurrency delegate API: `MCPeerID`, `MCSession` and the
/// invitation handler are not Sendable, and its callbacks arrive on arbitrary
/// queues. Holding those objects on the main actor and awaiting across them is
/// a strict-concurrency error, so they live here behind `@unchecked Sendable`
/// with one internal queue serialising every touch — and the ONLY thing that
/// ever crosses back out is a `UUID`, which is Sendable.
private let nearbyLog = Logger(subsystem: "app.cupseason.ios", category: "nearby")

private final class NearbyTransport: NSObject, @unchecked Sendable {
  private let q = DispatchQueue(label: "cs.nearby")
  private let me: UUID
  private let peer: MCPeerID
  private let session: MCSession
  private let advertiser: MCNearbyServiceAdvertiser
  private let browser: MCNearbyServiceBrowser
  private let heard: @Sendable (NearbyMessage) -> Void
  /// D168 · raised when a message could NOT be delivered. Every failure here
  /// used to be swallowed by `guard … else { return }` and `try?`, so a phone
  /// whose peer had wandered off sat on "ASKING…" forever with nothing said.
  private let undeliverable: @Sendable (UUID) -> Void
  /// profile id -> the peer holding it. Touched only on `q`.
  private var peers: [UUID: MCPeerID] = [:]

  init(me: UUID, heard: @escaping @Sendable (NearbyMessage) -> Void,
       undeliverable: @escaping @Sendable (UUID) -> Void) {
    self.me = me
    self.heard = heard
    self.undeliverable = undeliverable
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
      peers.removeAll()
    }
  }

  /// D158 · send to the phone that claimed `to`. Silently does nothing if that
  /// peer has gone — a nearby add that cannot be asked is one that does not
  /// happen, which is the correct outcome.
  func send(_ m: NearbyMessage, to: UUID) {
    q.async { [self] in
      guard let peer = peers[to] else {
        nearbyLog.error("send \(m.t.rawValue, privacy: .public): no peer known for that golfer")
        undeliverable(to); return
      }
      // a peer we heard from once may have wandered off since; MCSession keeps
      // the handle but will not carry a message to it
      guard session.connectedPeers.contains(peer) else {
        nearbyLog.error("send \(m.t.rawValue, privacy: .public): peer no longer connected")
        peers.removeValue(forKey: to); undeliverable(to); return
      }
      guard let data = try? JSONEncoder().encode(m) else { undeliverable(to); return }
      do {
        try session.send(data, toPeers: [peer], with: .reliable)
        nearbyLog.info("sent \(m.t.rawValue, privacy: .public)")
      } catch {
        nearbyLog.error("send \(m.t.rawValue, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        undeliverable(to)
      }
    }
  }

  private func remember(_ id: UUID, _ peer: MCPeerID) {
    q.async { [self] in peers[id] = peer }
  }
}

extension NearbyTransport: MCSessionDelegate {
  func session(_ s: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    nearbyLog.info("peer \(peerID.displayName, privacy: .public) -> \(String(describing: state), privacy: .public)")
    // D168 · a peer that leaves must leave the map too, or every later send
    // fails against a handle MCSession will never carry anything to
    if state == .notConnected {
      q.async { [self] in
        for (id, p) in peers where p == peerID { peers.removeValue(forKey: id); undeliverable(id) }
      }
      return
    }
    guard state == .connected else { return }
    // the profile id goes out only INSIDE the encrypted session, after both
    // sides chose to connect
    guard let hello = try? JSONEncoder().encode(NearbyMessage(t: .hello, from: me)) else { return }
    try? s.send(hello, toPeers: [peerID], with: .reliable)
  }
  func session(_ s: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    guard let m = try? JSONDecoder().decode(NearbyMessage.self, from: data), m.from != me else { return }
    // D158 · the peer that SPOKE is the peer we answer. An invitation goes back
    // down the connection it arrived on, never to a claimed id resolved some
    // other way — so a faker can only ever fool the phone it is talking to.
    remember(m.from, peerID)
    heard(m)
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
  /// D158 · someone on this tee wants you in their round.
  var onInvite: (@MainActor (NearbyInvite) -> Void)?
  /// D158 · they answered.
  var onReply: (@MainActor (UUID, Bool) -> Void)?
  /// D163 · the round they accepted has actually teed off. This is the id.
  var onTeed: (@MainActor (UUID) -> Void)?
  /// D168 · a message could not be delivered to that golfer's phone.
  var onUndeliverable: (@MainActor (UUID) -> Void)?

  private var transport: NearbyTransport?
  private var me: UUID?

  func start(myProfile: UUID) {
    guard !running else { return }
    me = myProfile
    let t = NearbyTransport(me: myProfile) { [weak self] m in
      Task { @MainActor in self?.heard(m) }
    } undeliverable: { [weak self] who in
      Task { @MainActor in self?.onUndeliverable?(who) }
    }
    transport = t
    t.start()
    running = true
  }

  /// D158 · ask, do not add. The tap that matters is on the OTHER phone.
  func invite(_ who: UUID, name: String, course: String, game: String) {
    guard let me else { return }
    transport?.send(NearbyMessage(t: .invite, from: me, name: name, course: course, game: game), to: who)
  }

  func reply(to who: UUID, ok: Bool) {
    guard let me else { return }
    transport?.send(NearbyMessage(t: .reply, from: me, ok: ok), to: who)
  }

  /// D163 · tell everyone who said yes that the round is real now.
  func teedOff(_ lr: UUID, to whom: [UUID]) {
    guard let me else { return }
    for who in whom {
      transport?.send(NearbyMessage(t: .teed, from: me, lr: lr), to: who)
    }
  }

  private func heard(_ m: NearbyMessage) {
    switch m.t {
    case .hello:  note(m.from)
    case .invite: onInvite?(NearbyInvite(from: m.from, name: m.name ?? "A golfer",
                                         course: m.course ?? "a round", game: m.game ?? ""))
    case .reply:  onReply?(m.from, m.ok == true)
    case .teed:   if let lr = m.lr { onTeed?(lr) }
    }
  }

  func stop() {
    transport?.stop()
    transport = nil
    running = false
    seen = []
    me = nil
  }

  private func note(_ id: UUID) {
    guard !seen.contains(id) else { return }
    seen.append(id)
    onChange?(seen)
  }
}
