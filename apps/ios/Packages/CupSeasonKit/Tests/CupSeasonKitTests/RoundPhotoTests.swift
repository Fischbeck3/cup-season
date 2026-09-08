// Cup Season — a photograph on a round you already posted (D293 / IOS-065).
//
// What is asserted here is what a screenshot cannot see: the two call
// contracts, the object path the server's own `^{uid}/` guard requires, the
// slot the receipt draws, and that the pre-migration sentence names the push
// rather than a code. The migration is written and unpushed, so the honest
// state is the state every golfer meets today and it is worth a test.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite struct RoundPhotoTests {

  // MARK: - the contracts

  /// C-03's rule, applied to a second consequential write. `optionalArgs` is
  /// the set `SupabaseService.call` may DROP on a first failure — a retry that
  /// dropped `p_photo_path` would attach nothing and report success, and one
  /// that dropped `p_round` would be a call with no round at all.
  @Test("nothing on either photo call is droppable")
  func nothingIsDroppable() {
    #expect(SetRoundPhotoCall.optionalArgs.isEmpty)
    #expect(ClearRoundPhotoCall.optionalArgs.isEmpty)
  }

  @Test("the two functions are named the way the migration spells them")
  func theNamesMatchTheMigration() {
    #expect(SetRoundPhotoCall.name == "set_round_photo")
    #expect(ClearRoundPhotoCall.name == "clear_round_photo")
  }

  /// Two names, not one nullable argument: `set_profile`'s convention is that
  /// null LEAVES A FIELD ALONE, so a single call would mean the opposite of
  /// what this codebase's other photo writer means by the same shape.
  @Test("the attach carries a path and the clear carries none")
  func theShapesAreDistinct() {
    let id = UUID()
    let set = SetRoundPhotoCall(p_round: id, p_photo_path: "x/y.jpg")
    #expect(set.p_round == id)
    #expect(set.p_photo_path == "x/y.jpg")
    #expect(ClearRoundPhotoCall(p_round: id).p_round == id)
  }

  // MARK: - the path the server will accept

  /// `set_round_photo` refuses any path that does not start `{auth.uid()}/`,
  /// because without that fence a signed-in golfer could point his own round
  /// at somebody else's private object and then read it through the round's
  /// signing call. The client has to build a path that clears the fence.
  @Test("the object path opens with the golfer's own lowercased uid")
  func thePathIsFencedToTheCaller() {
    let uid = UUID()
    let path = RoundPhotoService.objectPath(uid: uid)
    #expect(path.hasPrefix(uid.uuidString.lowercased() + "/"))
    #expect(path.hasSuffix(".jpg"))
    #expect(path.range(of: uid.uuidString.uppercased()) == nil)   // never the upper form
  }

  @Test("two photographs on one round never collide")
  func everyPathIsItsOwn() {
    let uid = UUID()
    #expect(RoundPhotoService.objectPath(uid: uid) != RoundPhotoService.objectPath(uid: uid))
  }

  // MARK: - the slot the receipt draws

  /// The affordance is a pure function of two facts, which is why it is here
  /// and not in a screenshot.
  @Test("his round with no photograph offers the one door")
  func anEmptyRoundOffers() {
    #expect(RoundPhotoSlot.for(isMine: true, photoPath: nil) == .offer)
    #expect(RoundPhotoSlot.for(isMine: true, photoPath: "") == .offer)
    #expect(RoundPhotoSlot.for(isMine: true, photoPath: "   ") == .offer)
  }

  @Test("his round with a photograph offers replace and remove")
  func aPhotographedRoundIsReplaceable() {
    #expect(RoundPhotoSlot.for(isMine: true, photoPath: "abc/def.jpg") == .present)
  }

  /// The same gate the delete applies (D284): somebody else's round carries no
  /// control at all, in either state.
  @Test("somebody else's round carries nothing, photographed or not")
  func anotherGolfersRoundIsUntouchable() {
    #expect(RoundPhotoSlot.for(isMine: false, photoPath: nil) == .none)
    #expect(RoundPhotoSlot.for(isMine: false, photoPath: "abc/def.jpg") == .none)
  }

  // MARK: - the honest pre-migration state

  /// L-32 · a failed write says so in the golfer's words. The push sentence is
  /// the one `csRateCourse` set the form for, and it must name the push — a
  /// golfer told "something went wrong" tries again forever.
  @Test("the pre-migration sentence names the database push and no code")
  func theSkewSentenceIsHonest() {
    let s = RoundCopy.photoNeedsPush
    #expect(s.contains("database push"))
    #expect(!s.contains("PGRST"))
    #expect(!s.contains("42883"))
    #expect(!s.lowercased().contains("error"))
  }

  @Test("a real failure and a missing function say different things")
  func thetwoFailuresAreToldApart() {
    #expect(RoundCopy.photoNeedsPush != RoundCopy.photoFailed)
    #expect(RoundCopy.photoFailed != RoundCopy.photoRemoveFailed)
    #expect(!RoundCopy.photoFailed.contains("database push"))
  }

  /// Only PGRST202 / 42883 earns the push sentence. Anything else is a real
  /// failure and gets the golfer's own words — a round that is not yours, or
  /// no signal, must never read as "the owner owes a migration".
  @Test("only a missing function is read as deploy skew")
  func onlyAMissingFunctionIsSkew() {
    let missing = RpcError(name: "set_round_photo",
                           underlying: "Could not find the function public.set_round_photo",
                           droppedArgs: [])
    let refused = RpcError(name: "set_round_photo", underlying: "Not your round", droppedArgs: [])
    #expect(RoundPhotoService.translate(missing) == .needsPush)
    #expect(RoundPhotoService.translate(refused) == .failed)
    #expect(RoundPhotoService.translate(URLError(.notConnectedToInternet)) == .failed)
  }

  /// The composer says "Add a photo" and so does the receipt — one act, one
  /// control, two places (D234). The replace and the remove are the two the
  /// composer never had to say, because a draft has no round yet.
  @Test("the six sentences are one producer's")
  func theCopyIsOneProducers() {
    #expect(RoundCopy.photoAdd == "Add a photo")
    #expect(RoundCopy.photoReplace == "Replace photo")
    #expect(RoundCopy.photoRemove == "Remove photo")
    #expect(RoundCopy.photoRemoveArmed == "Sure?")
  }
}
