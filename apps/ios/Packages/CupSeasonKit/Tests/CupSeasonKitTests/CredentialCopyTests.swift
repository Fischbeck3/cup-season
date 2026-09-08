// Cup Season — the card's producers (Wave 2, IOS-047).
//
// One string, one place. These assert the consolidations rather than the
// screens: a golfer's identity line must not change with the door they came
// through, and an empty state must not blame the golfer for being new.

import Testing
import Foundation
@testable import CupSeasonKit

@Suite("The credential's copy")
struct CredentialCopyTests {

  @Test("the identity line is handle · city · home course — and never carries est.")
  func identity() {
    let s = CredentialCopy.identity(handle: "galenm", city: "Mesa, AZ", homeCourse: "Papago")
    #expect(s == "@galenm · Mesa, AZ · Papago")
    // UI_SYSTEM §6.5 row 5 / YRS-21: the founding fact is already the gold slot,
    // and a third telling is the duplication GP-17 names.
    #expect(!s.lowercased().contains("est."))
  }

  @Test("each clause is dropped rather than guessed")
  func identityDegrades() {
    #expect(CredentialCopy.identity(handle: nil, city: "Mesa, AZ", homeCourse: nil) == "Mesa, AZ")
    #expect(CredentialCopy.identity(handle: "tashb", city: nil, homeCourse: nil) == "@tashb")
    #expect(CredentialCopy.identity(handle: "", city: "", homeCourse: "").isEmpty)
    // no dash, no placeholder, no "—"
    #expect(!CredentialCopy.identity(handle: nil, city: nil, homeCourse: nil).contains("—"))
  }

  @Test("the status sentence marks the gross as a figure run, with braces and not a regex")
  func status() {
    let s = CredentialCopy.status(gross: 74, course: "Papago", playedOn: "2026-09-04", isMe: false)
    #expect(s == "Posted {74} at Papago on September 4.")
    // a regex over prose would have restyled the 4 in "September 4" too
    #expect(s?.filter { $0 == "{" }.count == 1)
  }

  @Test("no round → the line is not drawn (L-44)")
  func statusAbsent() {
    #expect(CredentialCopy.status(gross: nil, course: "Papago", playedOn: "2026-09-04", isMe: true) == nil)
  }

  @Test("the establishing clause reads as English, not as a second rail")
  func establishing() {
    let s = CredentialCopy.status(gross: 79, course: "Papago", playedOn: "2026-08-30",
                                  roundsToEstablish: 1, isMe: false)
    #expect(s == "Posted {79} at Papago on August 30. One more round sets their number.")
    let mine = CredentialCopy.status(gross: 79, course: nil, playedOn: nil,
                                     roundsToEstablish: 2, isMe: true)
    #expect(mine == "Posted {79}. Two more rounds set your number.")
  }

  @Test("the first-card headline is a fact about the world, never the golfer's omission")
  func firstCard() {
    var c = DateComponents(); c.year = 2026; c.month = 8; c.day = 3
    let since = Calendar(identifier: .gregorian).date(from: c)!
    let s = CredentialCopy.firstCard(name: "Tash Bell", since: since)
    #expect(s == "Tash joined in August. It starts with a first round.")
    // §13.1's test: could the golfer have prevented this sentence by doing
    // something? "hasn't posted a round yet" fails it; this must not say it.
    #expect(!s.contains("hasn’t") && !s.contains("hasn't") && !s.lowercased().contains("no rounds"))
  }

  @Test("with no join date it still names the world rather than the gap")
  func firstCardNoDate() {
    let s = CredentialCopy.firstCard(name: "Blake", since: nil)
    #expect(s == "Blake is here. It starts with a first round.")
  }

  @Test("the form count spells the gap; a posted round is a round, never a card (T-01)")
  func formCount() {
    #expect(CredentialCopy.formCount(5) == "Last five")
    #expect(CredentialCopy.formCount(2) == "Two of five")
    #expect(!CredentialCopy.formCount(2).lowercased().contains("card"))
  }

  @Test("the overlap sentence is D150's answer, and it degrades to nothing")
  func overlap() {
    #expect(CredentialCopy.overlap([]) == nil)
    #expect(CredentialCopy.overlap(["Papago"]) == "You’ve both played Papago.")
    #expect(CredentialCopy.overlap(["Papago", "Troon North"]) == "You’ve both played Papago and Troon North.")
  }

  @Test("the folio names the marker, and the serial is not invented")
  func club() {
    #expect(CredentialCopy.club(markerName: "The Lone Tree") == "Cup Season · The Lone Tree")
    #expect(CredentialCopy.club(markerName: nil) == "Cup Season")
  }
}

@Suite("The board column and the lead label")
struct BoardColumnTests {

  private func row(rounds: Int, beats: Int) -> FriendsBoard.Row {
    FriendsBoard.Row(profileId: UUID(), displayName: "Galen Marr", handle: "galenm",
                     marker: "saguaro", indexCurrent: 10.2, rounds: rounds, beats: beats,
                     avgVsNumber: -1.2, bestVsNumber: nil, lastRoundOn: "2026-09-02",
                     rankByForm: 1, rankByIndex: 1, isMe: false)
  }

  @Test("the denominator is part of the fact, and it is a COLUMN (L-01)")
  func beatsColumn() {
    #expect(row(rounds: 4, beats: 3).beatsColumn == "3/4")
    #expect(row(rounds: 0, beats: 0).beatsColumn == "—")
  }

  @Test("the lead line names a subject, never a gender")
  func leadLabel() {
    #expect(RivalryCopy.leadLabel(.down, them: "Galen Marr") == "GALEN LEADS")
    #expect(RivalryCopy.leadLabel(.up, them: "Galen Marr") == "YOU LEAD")
    #expect(RivalryCopy.leadLabel(.even, them: "Galen Marr") == "ALL SQUARE")
    // never `HE LEADS` / `SHE LEADS` — nobody's gender is stored, and the one
    // sentence on the clash is addressed to every golfer in a mixed league
    #expect(!RivalryCopy.leadLabel(.down, them: "Galen").contains("HE "))
  }

  @Test("with no name it falls back to the bare form rather than inventing one")
  func leadLabelDegrades() {
    #expect(RivalryCopy.leadLabel(.down, them: nil) == "THEY LEAD")
    #expect(RivalryCopy.leadLabel(.down, them: "") == "THEY LEAD")
  }
}
