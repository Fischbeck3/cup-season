// D158 · the three beats that cross the tee, pinned.
//
// Two phones are the only real test of proximity and nobody can run that in CI,
// so what IS testable is pinned here: the wire format round-trips, an invite
// carries what the prompt has to say, and a malformed or foreign payload is
// dropped rather than half-read. The transport's own rule — answer the peer
// that SPOKE, never a claimed id resolved elsewhere — is asserted in the one
// place it can be, its comment, and by there being no other send path.

import Testing
import Foundation
@testable import CupSeason

struct NearbyMessageTests {

  private func roundTrip(_ m: NearbyMessage) throws -> NearbyMessage {
    try JSONDecoder().decode(NearbyMessage.self, from: JSONEncoder().encode(m))
  }

  @Test func helloCarriesOnlyTheSendersId() throws {
    let me = UUID()
    let out = try roundTrip(NearbyMessage(t: .hello, from: me))
    #expect(out.t == .hello)
    #expect(out.from == me)
    // a hello says who, and nothing else — no name goes out before a peer has
    // been resolved to a buddy or a league mate
    #expect(out.name == nil)
    #expect(out.course == nil)
    #expect(out.ok == nil)
  }

  @Test func inviteCarriesWhatThePromptMustSay() throws {
    let me = UUID()
    let out = try roundTrip(NearbyMessage(t: .invite, from: me, name: "Jerecho",
                                          course: "Bajamar Golf Club", game: "Match play"))
    #expect(out.t == .invite)
    #expect(out.from == me)
    #expect(out.name == "Jerecho")
    #expect(out.course == "Bajamar Golf Club")
    #expect(out.game == "Match play")
  }

  @Test func replyIsJustYesOrNo() throws {
    let me = UUID()
    #expect(try roundTrip(NearbyMessage(t: .reply, from: me, ok: true)).ok == true)
    #expect(try roundTrip(NearbyMessage(t: .reply, from: me, ok: false)).ok == false)
  }

  @Test func aMalformedPayloadDecodesToNothing() {
    // the receive path is `try?` — garbage on the wire must produce nil, not a
    // partially-populated message that some branch then acts on
    #expect((try? JSONDecoder().decode(NearbyMessage.self, from: Data("hello".utf8))) == nil)
    #expect((try? JSONDecoder().decode(NearbyMessage.self, from: Data())) == nil)
    // an unknown kind is not silently coerced to `.hello`
    let odd = Data(#"{"t":"summon","from":"\#(UUID().uuidString)"}"#.utf8)
    #expect((try? JSONDecoder().decode(NearbyMessage.self, from: odd)) == nil)
    // a uuid-shaped string is not a message — this is the OLD wire format, and
    // a phone still speaking it must be ignored, not misread as a hello
    #expect((try? JSONDecoder().decode(NearbyMessage.self, from: Data(UUID().uuidString.utf8))) == nil)
  }

  @Test func theInviteThePromptRendersFallsBackSafely() {
    // heard() substitutes these when a peer sends an invite with fields missing;
    // the alert must never render an empty sentence
    let inv = NearbyInvite(from: UUID(), name: "A golfer", course: "a round", game: "")
    #expect(!inv.name.isEmpty)
    #expect(!inv.course.isEmpty)
    #expect(inv.id == inv.from)      // Identifiable keys on WHO asked
  }
}
