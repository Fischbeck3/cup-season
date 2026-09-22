import Testing
import Foundation
@testable import CupSeasonKit

/// D375 · season two is a re-up: the phone says the desk's sentences, verbatim.
@Suite struct ReUpTests {
  @Test func whatTheProsTapDid() throws {
    #expect(ReUpCopy.runItBackDone(seasonNumber: 2, asked: 3) == "Season 2 is on. 3 invitations are out — the table fills as they say yes.")
    #expect(ReUpCopy.runItBackDone(seasonNumber: 2, asked: 1) == "Season 2 is on. One invitation is out — the table fills as they say yes.")
    #expect(ReUpCopy.runItBackDone(seasonNumber: 2, asked: 0) == "Season 2 is on. You’re in — share the code and the rest follow.")
    #expect(ReUpCopy.runItBackDone(seasonNumber: nil, asked: nil) == "The next season is on.")
    // the result decodes `asked`, falls back to `invited`, then to the bare sentence
    let asked = try JSONDecoder().decode(RunItBackResult.self, from: Data(#"{"season":{"number":2},"asked":3,"invited":3}"#.utf8))
    #expect(asked.line == "Season 2 is on. 3 invitations are out — the table fills as they say yes.")
    let older = try JSONDecoder().decode(RunItBackResult.self, from: Data(#"{"season":{"number":2},"invited":1}"#.utf8))
    #expect(older.line == "Season 2 is on. One invitation is out — the table fills as they say yes.")
    let bare = try JSONDecoder().decode(RunItBackResult.self, from: Data(#"{"season":{"number":3}}"#.utf8))
    #expect(bare.line == "Season 3 is on.")
  }

  @Test func theMembersYesTheStopAndTheAskAgain() {
    #expect(ReUpCopy.reUpDone(seasonNumber: 2) == "You’re in for season 2. Same rules — the table starts fresh.")
    #expect(ReUpCopy.reUpDone(seasonNumber: nil) == "You’re in for the new season. Same rules — the table starts fresh.")
    #expect(ReUpCopy.alreadyIn(seasonNumber: 2) == "You’re already in for season 2.")
    #expect(ReUpCopy.alreadyIn(seasonNumber: nil) == "You’re already in.")
    #expect(ReUpCopy.askedAgain(firstName: "Danny") == "Danny is asked again — it rings on their phone.")
    #expect(ReUpCopy.askedAgain(firstName: nil) == "They’re asked again — it rings on their phone.")
    #expect(ReUpCopy.notInYet == "NOT IN YET")
    #expect(ReUpCopy.inForLine(count: 5, seasonNumber: 2) == "5 IN FOR SEASON 2")
  }

  @Test func theRosterMarksOnlyAMissingYesInASecondSeason() {
    #expect(ReUpCopy.inFor(agreedSeasons: [1], seasonNumber: 1))
    #expect(ReUpCopy.inFor(agreedSeasons: nil, seasonNumber: 2))          // an older database: no record, nobody marked
    #expect(ReUpCopy.inFor(agreedSeasons: [1, 2], seasonNumber: 2))
    #expect(!ReUpCopy.inFor(agreedSeasons: [1], seasonNumber: 2))
    let member = LeagueRoom.Member(id: UUID(), role: "member", profile_id: UUID(), agreed_seasons: [1])
    #expect(!ReUpCopy.inFor(agreedSeasons: member.agreed_seasons, seasonNumber: 2))
  }

  @Test func theInvitationSaysWhichSeason() {
    let first = Invite(id: UUID(), kind: "league", containerId: UUID(), containerName: "the Fellas", inviter: "Galen", startsOn: nil)
    #expect(first.title == "League invite" && first.subline == "from Galen")
    let reup = Invite(id: UUID(), kind: "league", containerId: UUID(), containerName: "the Fellas", inviter: "Galen", startsOn: nil,
                      seasonNumber: 2, reup: true)
    #expect(reup.isReUp && reup.title == "Season 2 invite")
    #expect(reup.subline == "Season 2 of the Fellas is on. Same rules, fresh table.")
    let row = InviteRow(id: UUID(), kind: "league", container_id: UUID(), container_name: "PIGL", inviter: "Jerecho", starts_on: nil,
                        season_number: 2, reup: true)
    #expect(Invite(row)?.title == "Season 2 invite")
    // a first-season row on the new server is not a re-up
    #expect(ReUpCopy.inviteTitle(reup: true, seasonNumber: 1) == "League invite")
  }

  @Test func theCovenantFramesAReUpAndStopsOnARecordedYes() throws {
    let json: JSONValue = .object([
      "name": .string("the Fellas"), "buyin_cents": .number(5000), "preset": .string("standard"), "floor": .number(2),
      "finish": .string("cup_final"), "season_number": .number(2), "reup": .bool(true), "agreed": .bool(false),
      "last_season": .object(["number": .number(1), "my_rank": .number(3), "of": .number(8), "my_points": .number(41)]),
    ])
    let c = try #require(Covenant(json))
    #expect(c.isReUp && c.seasonNumber == 2 && c.agreed == false)
    #expect(c.head == "Season 2 of the Fellas")
    #expect(c.eyebrow == "SAME RULES — EVERYTHING BEFORE YOU TAP")
    #expect(c.joinLabel == "I’m in for season 2 — $50")
    #expect(c.seasonLine == "Season 2. Last season you finished 3rd of 8 with 41 points.")
    #expect(c.facts().first?.0 == .season)
    // the yes already on record: the sheet stops, in the desk's words
    let agreed = try #require(Covenant(.object(["name": .string("the Fellas"), "season_number": .number(2), "reup": .bool(true), "agreed": .bool(true)])))
    #expect(agreed.agreed == true && agreed.alreadyInLine == "You’re already in for season 2.")
    // a first join reads as it always did
    let first = Covenant(name: "the Fellas", buyinCents: 0, preset: "standard", floor: 2, finish: nil,
                         proName: "The host", rosterCount: 1)
    #expect(!first.isReUp && first.head == "Before you join the Fellas" && first.eyebrow == "EVERYTHING BEFORE YOU TAP"
            && first.joinLabel == "Join the Fellas" && first.seasonLine == nil && first.facts().first?.0 == .who)
    // L-44 · a finish the server could not compute renders nothing beyond the season
    let noFinish = try #require(Covenant(.object(["name": .string("x"), "season_number": .number(2), "reup": .bool(true)])))
    #expect(noFinish.seasonLine == "Season 2.")
  }
}
