// Cup Season — the door's helpers (IOS-023): the nonce, the flag, the Forge clock.

import Testing
import Foundation
@testable import CupSeason

@Suite struct DoorNonceTests {
  @Test func nonceIsSixtyFourHexCharsAndFresh() {
    let a = DoorNonce.make(), b = DoorNonce.make()
    #expect(a.count == 64)
    #expect(a.allSatisfy { $0.isHexDigit })
    #expect(a != b)
    #expect(DoorNonce.make(bytes: 8).count == 16)
  }

  @Test func sha256IsStableAndKnown() {
    // FIPS 180-4 test vector
    #expect(DoorNonce.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    #expect(DoorNonce.sha256("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    let n = DoorNonce.make()
    #expect(DoorNonce.sha256(n) == DoorNonce.sha256(n))
    #expect(DoorNonce.sha256(n).count == 64)
    #expect(DoorNonce.sha256(n) != n)
  }
}

@Suite struct DoorFlagsTests {
  @Test func missingKeyIsClosed() {
    // the row as migration 20260827130100 seeds it
    let seeded = DoorFlags.decode(Data(#"{"min_build": 0, "note": "Raise min_build…"}"#.utf8))
    #expect(seeded == .closed)
    #expect(seeded.appleSignIn == false)
  }

  @Test func ownerWriteOpensIt() {
    #expect(DoorFlags.decode(Data(#"{"min_build": 0, "apple_sign_in": true}"#.utf8)).appleSignIn == true)
    #expect(DoorFlags.decode(Data(#"{"apple_sign_in": false}"#.utf8)).appleSignIn == false)
  }

  @Test func badShapesFailClosed() {
    #expect(DoorFlags.decode(Data("not json".utf8)) == .closed)
    #expect(DoorFlags.decode(Data(#"{"apple_sign_in": "yes"}"#.utf8)) == .closed)
    #expect(DoorFlags.decode(Data("[]".utf8)) == .closed)
    #expect(DoorFlags.decode(Data()) == .closed)
  }
}

@Suite struct ForgeTimelineTests {
  @Test func fitsInTheBudget() {
    #expect(ForgeTimeline.end <= 2.2)
    #expect(ForgeTimeline.handoff <= ForgeTimeline.end)
    #expect(ForgeTimeline.rest > ForgeTimeline.end)
  }

  @Test func heatRampFiresInOrderAndLettersLandWithTracers() {
    let starts = ForgeTimeline.tracerDraw.map(\.start)
    #expect(starts == starts.sorted())
    #expect(ForgeTimeline.letters.count == 9)   // C u p S e a s o n
    // (C,U) lands as the first tracer finishes; the survivor burns off last
    #expect(ForgeTimeline.letters[0].start >= ForgeTimeline.tracerDraw[0].end - 0.01)
    #expect(ForgeTimeline.tracerGone[2].start > ForgeTimeline.tracerGone[0].start)
    // the mark arrives as the tracers leave, never before
    #expect(ForgeTimeline.mark.start >= ForgeTimeline.tracerGone[0].start)
  }

  @Test func progressClampsAndRests() {
    let c = ForgeTimeline.Cue(start: 1, duration: 1)
    #expect(ForgeTimeline.progress(0, c) == 0)
    #expect(ForgeTimeline.progress(1, c) == 0)
    #expect(ForgeTimeline.progress(2, c) == 1)
    #expect(ForgeTimeline.progress(ForgeTimeline.rest, c) == 1)
    let mid = ForgeTimeline.progress(1.5, c)
    #expect(mid > 0 && mid < 1)
  }

  @Test func geometryIsTheWebsViewBox() {
    #expect(ForgeGeometry.tracers.count == 4)
    #expect(!ForgeGeometry.mark.isEmpty)
    let b = ForgeGeometry.markBounds
    // translate(150 46) scale(2.15) of a ~90×86 mark: inside the 460×300 box
    #expect(b.minX > 150 && b.maxX < 460 && b.minY > 46 && b.maxY < 300)
  }

  @Test func oncePerDevice() {
    let d = UserDefaults(suiteName: "cs.forge.tests")!
    d.removePersistentDomain(forName: "cs.forge.tests")
    #expect(ForgeState.hasPlayed(d) == false)
    #expect(ForgeState.shouldPlay(reduceMotion: true, defaults: d) == false)
    ForgeState.markPlayed(d)
    #expect(ForgeState.hasPlayed(d) == true)
  }
}

/// D186 — Apple hands back `fullName` on the FIRST authorization only. The
/// button requested the scope and dropped the result, so an Apple signup would
/// have reached the golfer card with an empty name and a relay address as the
/// only thing we knew. These pin the carry: format it, keep it across the
/// sign-in reload, and hand it to exactly one card.
@Suite struct AppleNameTests {
  @Test func formatsApplesComponentsAndRefusesEmpty() {
    var c = PersonNameComponents()
    c.givenName = "Jerecho"; c.familyName = "Fischbeck"
    #expect(AppleName.from(c) == "Jerecho Fischbeck")

    var first = PersonNameComponents(); first.givenName = "Mitch"
    #expect(AppleName.from(first) == "Mitch")

    // Apple withholds the name on every sign-in after the first — nil, not "".
    #expect(AppleName.from(nil) == nil)
    #expect(AppleName.from(PersonNameComponents()) == nil)
  }

  @Test func stashIsReadOnceThenGone() {
    let d = UserDefaults.standard
    d.removeObject(forKey: AppleName.key)

    // nothing stashed, nothing to take
    #expect(AppleName.take() == nil)

    AppleName.stash("Priya Nair")
    #expect(AppleName.take() == "Priya Nair")
    // read-and-clear: a second golfer on a shared phone must not inherit it
    #expect(AppleName.take() == nil)

    // a nil or empty name never displaces a real one
    AppleName.stash("Dana")
    AppleName.stash(nil)
    AppleName.stash("")
    #expect(AppleName.take() == "Dana")

    d.removeObject(forKey: AppleName.key)
  }
}
