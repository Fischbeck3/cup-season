// Cup Season — CONTACTS MATCHING (D251 / R-G; C-11).
//
// Four things these tests hold, and the first two are privacy properties rather
// than behaviour:
//
//   1 · NORMALISATION IS STABLE AND MATCHES THE SERVER. `cs_normalise_email` /
//       `cs_normalise_phone` run the SAME cases inside the migration's own
//       self-check. If the two drift, a golfer's own email stops matching their
//       own row and nothing visible breaks — which is exactly why it is pinned
//       on both sides.
//   2 · THE CLIENT NEVER HOLDS A SALT. `digest` is plain SHA-256, asserted
//       against the published test vector. A salt smuggled in here would break
//       this AND the migration's identical assertion.
//   3 · A MATCH OF NOTHING RENDERS A SENTENCE WITH A NEXT MOVE (L-32).
//   4 · DECLINING FINISHES THE STEP. R-G's own clause: the ability to decline
//       and still finish the screen that asked.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct ContactHashTests {

  // MARK: - 1 · normalisation

  @Test func emailNormalisationIsStableAndMatchesTheServer() {
    #expect(ContactHash.normaliseEmail("  Jerecho@Example.COM ") == "jerecho@example.com")
    #expect(ContactHash.normaliseEmail("jerecho@example.com") == "jerecho@example.com")
    // NOT normalised away, deliberately: a plus-tag and a dot are part of the
    // address as far as this product is concerned. Guessing a provider's rules
    // silently WIDENS a match, which is the wrong direction to be wrong in.
    #expect(ContactHash.normaliseEmail("a.b+golf@gmail.com") == "a.b+golf@gmail.com")
    // and a non-address is not an address
    #expect(ContactHash.normaliseEmail("") == nil)
    #expect(ContactHash.normaliseEmail("jerecho") == nil)
    #expect(ContactHash.normaliseEmail("@example.com") == nil)
    #expect(ContactHash.normaliseEmail("jerecho@") == nil)
  }

  @Test func phoneNormalisationIsStableAndMatchesTheServer() {
    // the three cases the migration's self-check runs, verbatim
    #expect(ContactHash.normalisePhone("(480) 555-0134") == "+14805550134")
    #expect(ContactHash.normalisePhone("+44 20 7946 0958") == "+442079460958")
    #expect(ContactHash.normalisePhone("555-0134") == nil)   // a local fragment is not a number
    // and the same number written four ways is one hash
    let ways = ["4805550134", "480-555-0134", "(480) 555 0134", "+1 480 555 0134"]
    #expect(Set(ways.compactMap(ContactHash.normalisePhone)).count == 1)
  }

  // MARK: - 2 · the client never holds a salt

  @Test func theDigestIsPlainSha256AndCarriesNoSalt() {
    // The published SHA-256 vector for "abc". The migration asserts the SAME
    // string server-side, so a salt added to either half fails both.
    #expect(ContactHash.digest("abc")
            == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    // deterministic, lower-case hex, 64 characters
    let h = ContactHash.digest("jerecho@example.com")
    #expect(h == ContactHash.digest("jerecho@example.com"))
    #expect(h.count == 64)
    #expect(h == h.lowercased())
    #expect(h.allSatisfy { $0.isHexDigit })
    // and it is NOT the value the database stores — that is `sha256(salt || h)`
    // and nothing in this package can produce it.
    #expect(h != ContactHash.digest(h))
  }

  @Test func whatTravelsIsHashesAndOnlyHashes() {
    let hs = ContactHash.hashes(emails: ["Galen@example.com", "galen@example.com", "nope"],
                                phones: ["(480) 555-0134", "4805550134", "555-0134"])
    // two distinct contacts, de-duplicated, and nothing that failed to normalise
    #expect(hs.count == 2)
    #expect(hs.allSatisfy { $0.count == 64 })
    // no raw contact survives anywhere in the payload
    let joined = hs.joined(separator: ",")
    #expect(!joined.contains("galen"))
    #expect(!joined.contains("480"))
    #expect(!joined.contains("@"))
  }

  @Test func theCapIsTheServersOwnCap() {
    // The RPC drops everything past 1000 (`ord <= 1000`). The phone must not
    // send what the server will silently ignore — a "we checked" that quietly
    // checked two thirds of a contact book is the wrong kind of confident.
    #expect(ContactHash.maxHashes == 1000)
    let many = (0..<1500).map { "golfer\($0)@example.com" }
    #expect(ContactHash.hashes(emails: many, phones: []).count == ContactHash.maxHashes)
  }

  // MARK: - 3 · the empty result reads gracefully

  @Test func aMatchOfNothingEndsInANextMove() {
    #expect(ContactMatchService.line(.none) == "None of your contacts is here yet. Text one a link.")
    // L-32's second half: a refusal, a not-yet and a nobody are three different
    // facts and they get three different sentences.
    #expect(OnboardingCopy.contactsNone != OnboardingCopy.contactsRefused)
    #expect(OnboardingCopy.contactsNone != OnboardingCopy.contactsNotYet)
    #expect(OnboardingCopy.contactsRefused.contains("Settings"))
    // and the not-yet one is the wave's standard three-state sentence
    #expect(ContactMatchService.line(.notYet) == OnboardingCopy.contactsNotYet)
    #expect(ContactMatchService.line(.failed("Nope")) == "Nope")
  }

  @Test func aMatchIsCountedInWordsAGolferReads() {
    #expect(OnboardingCopy.contactsFound(0) == nil)
    #expect(OnboardingCopy.contactsFound(1) == "One of your friends is already here.")
    #expect(OnboardingCopy.contactsFound(3) == "3 of your friends are already here.")
    let one = MatchedGolfer(id: UUID(), handle: "galen", display_name: "Galen Ortiz", city: nil,
                            home_course: nil, marker: "island", index_current: 8.1, rel: "contact")
    #expect(ContactMatchService.line(.matched([one])) == "One of your friends is already here.")
    // an empty array is never `.matched` — the service maps it to `.none`
    #expect(ContactMatchService.line(.matched([])) == nil)
  }

  @Test func aMatchedGolferKeepsTheirRelation() {
    let friend = MatchedGolfer(id: UUID(), handle: "g", display_name: "Galen", city: "Tempe",
                               home_course: nil, marker: "island", index_current: nil, rel: "friend")
    let stranger = MatchedGolfer(id: friend.id, handle: "g", display_name: "Galen", city: nil,
                                 home_course: nil, marker: "island", index_current: nil, rel: "contact")
    #expect(friend.person.rel == .friend)     // already buddies — no Add button over a buddy
    #expect(stranger.person.rel == .none)
    #expect(stranger.person.name == "Galen")
  }

  // MARK: - 4 · consent, and declining

  @Test func theConsentSentenceSaysWhatTravelsAndWhatIsKept() {
    let c = OnboardingCopy.contactsConsent
    #expect(c == "We'll check your contacts against the golfers already here. We send hashes, never your contacts, and we keep nothing that doesn't match.")
    #expect(c.contains("hashes"))
    #expect(c.contains("never your contacts"))
    #expect(c.contains("keep nothing"))
  }

  @Test func decliningIsAnOfferedControlAndFinishesTheStep() {
    // R-G: the ability to decline and still finish the screen that asked. The
    // decline is a NAMED control, and the step's own exit does not depend on it.
    #expect(OnboardingCopy.contactsDecline == "Not now")
    #expect(!OnboardingCopy.contactsDecline.isEmpty)
    #expect(OnboardingCopy.crewRoutes.contains(.later))
    // and the step can be finished with zero buddies — that is a state, not an
    // error, and it names the first Home it produces
    #expect(OnboardingCopy.FirstHome.of(buddiesAdded: 0) == .alone)
  }

  @Test func anEmptyAskAsksNothing() async {
    // Nothing to send is not a call. A round trip that asks the server to match
    // an empty array gets a confident empty answer, which reads as "nobody" and
    // is not the same fact.
    let r = try? await ContactMatchService().match([])
    #expect(r == ContactMatchService.Result.none)
  }
}
