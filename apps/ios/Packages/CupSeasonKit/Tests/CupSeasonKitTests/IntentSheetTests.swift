import Testing
import Foundation
@testable import CupSeasonKit

/// D225 · the doors name what I want, not what the engine has.
///
/// The whole ruling rests on ONE testable property: **no string the intent sheet
/// renders may contain an engine object noun**. Everything else about the sheet
/// is layout; this is the ruling.
@Suite struct IntentSheetTests {

  // MARK: - five sentences

  @Test func fourPeersAndOneModifier() {
    // Four peers plus the money line is what the design calls "five sentences";
    // the fifth is a MODIFIER and renders below a hairline, because money is a
    // choice ON a competition and never a competition (L-11, D46).
    #expect(StartIntent.peers.count == 4)
    #expect(StartIntent.peers == StartIntent.allCases)
    #expect(!StartIntent.modifierLine.isEmpty)
  }

  @Test func theWordsAreTheDesignsOwn() {
    #expect(StartIntent.title == "What do you want to do?")
    #expect(StartIntent.playWithFriends.line == "Play with my friends")
    #expect(StartIntent.runASeason.line == "Run a season")
    #expect(StartIntent.thisWeekend.line == "We're playing this weekend")
    #expect(StartIntent.beatOneGuy.line == "I want to beat one guy")
    #expect(StartIntent.modifierLine == "Put money on it")
    #expect(StartIntent.codeDoor == "I have a code")
  }

  @Test func theGlossesAreTheDesignsOwn() {
    #expect(StartIntent.playWithFriends.gloss == "a round with whoever is around")
    #expect(StartIntent.runASeason.gloss == "weeks of golf that add up to a table")
    #expect(StartIntent.beatOneGuy.gloss == "you and him, whatever length you like")
    #expect(StartIntent.modifierGloss == "add a pot to any of the above")
  }

  /// L-32 · a door may not sell what the object does not open. A weekend mints
  /// NO trophy (D240), so the third line says "a name for it" and never
  /// "one trophy".
  @Test func theWeekendDoesNotSellATrophy() {
    let g = StartIntent.thisWeekend.gloss
    #expect(g == "one day, and a name for it")
    #expect(!g.lowercased().contains("trophy"))
    #expect(!g.lowercased().contains("cup"))
  }

  // MARK: - zero object nouns, asserted against the terminology table

  @Test func noStringNamesAnEngineObject() {
    for s in StartIntent.everyString {
      let hits = StartIntent.objectNouns(in: s)
      #expect(hits.isEmpty, Comment(rawValue: "\"\(s)\" names \(hits)"))
    }
  }

  /// The ban list is a WORD-BOUNDARY match, so a word that merely contains a
  /// banned one is not a false hit — otherwise the check would be unusable and
  /// somebody would delete it.
  @Test func theBanIsOnWordsNotSubstrings() {
    #expect(StartIntent.objectNouns(in: "Run a season").isEmpty)
    #expect(StartIntent.objectNouns(in: "seasonal golf").isEmpty)
    #expect(StartIntent.objectNouns(in: "unlocked the door").isEmpty)
    // and it really does fire on the real thing
    #expect(StartIntent.objectNouns(in: "Start a league") == ["league"])
    #expect(StartIntent.objectNouns(in: "Start an event") == ["event"])
    #expect(StartIntent.objectNouns(in: "Pick a session") == ["session"])
  }

  /// TERMINOLOGY §2.3 rules `season` the GOLFER's word for the thing you start,
  /// join, run and win — `league` survives only as the crew's standing name and
  /// is never a button. The ban list has to reflect that or the sheet cannot say
  /// its own second line.
  @Test func seasonIsAllowedAndLeagueIsNot() {
    #expect(!StartIntent.bannedNouns.contains("season"))
    #expect(StartIntent.bannedNouns.contains("league"))
    #expect(StartIntent.bannedNouns.contains("event"))
    #expect(StartIntent.bannedNouns.contains("ryder"))
    #expect(StartIntent.bannedNouns.contains("bracket"))
  }

  // MARK: - what each one resolves to

  @Test func everyIntentResolvesToSomethingThatExists() {
    #expect(StartIntent.playWithFriends.resolution == .whenFork)
    #expect(StartIntent.runASeason.resolution == .season)
    #expect(StartIntent.thisWeekend.resolution == .weekend)
    #expect(StartIntent.beatOneGuy.resolution == .pickAGolfer)
    // Every peer resolves somewhere, and no two resolve to the same place.
    let all = StartIntent.peers.map(\.resolution)
    #expect(Set(all).count == all.count)
  }

  /// Intent 1's fork is the ONE question the app cannot infer. Two answers,
  /// both of which work, and live keeps the ember (L-40).
  @Test func theForkIsTwoAnswersAndBothWork() {
    #expect(StartIntent.WhenFork.allCases.count == 2)
    #expect(StartIntent.WhenFork.rightNow.line == "Right now")
    #expect(StartIntent.WhenFork.aDayThisWeek.line == "A day this week")
    #expect(StartIntent.WhenFork.title == "When are you playing?")
    for f in StartIntent.WhenFork.allCases {
      #expect(StartIntent.objectNouns(in: f.line + " " + f.gloss).isEmpty)
    }
  }

  /// L-32 · money's empty case ends in a door, and the frozen-season branch says
  /// what CAN be done rather than hiding a control.
  @Test func moneyHasAnEmptyStateWithADoor() {
    #expect(StartIntent.Money.emptyLine.hasSuffix("Start something first."))
    #expect(!StartIntent.Money.somethingNew.isEmpty)
    let frozen = StartIntent.Money.frozen("The Fellas", firstTee: "Saturday")
    #expect(frozen.contains("forfeit"))
    #expect(frozen.contains("froze at the first tee"))
  }
}
