// Cup Season — a post can be homed on a person (D238 / C-1, wave 6).
//
// The migration is what widens `posts_home_check` and re-keys `post_kudos`;
// what THIS file holds is the half a golfer can see, and it is two claims:
//
//   1 · A ROUND THAT LANDS IN NO SEASON WINDOW STILL REACHES A BOARD. On the
//       client that means the Home wire's reaction strip, which used to be
//       ABSENT on exactly those rows — `HomeSocial`'s own comment said so:
//       "rows with no shared-league post get no strip at all". That was 14 of
//       39 prod profiles, plus every member between seasons, unable to be
//       congratulated on a round their friends could already see.
//
//   2 · KUDOS SURVIVE THE RE-KEY. `member_id` is not dropped, it is unkeyed —
//       so a row from before the push, a row from after it, and a backfilled
//       row carrying both must all name the same golfer and must all know
//       whether that golfer is me. A golfer in TWO leagues has two member ids
//       and the old test only ever held one of them.

import Testing
import Foundation
@testable import CupSeasonKit

private let me      = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
private let galen   = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
private let lone    = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
private let myMemA  = UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!
private let myMemB  = UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000002")!
private let galenMem = UUID(uuidString: "bbbbbbbb-0000-0000-0000-000000000001")!

private let leagueOne = UUID(uuidString: "cccccccc-0000-0000-0000-000000000001")!
private let leagueTwo = UUID(uuidString: "cccccccc-0000-0000-0000-000000000002")!

private let roundLeagued  = UUID(uuidString: "dddddddd-0000-0000-0000-000000000001")!
private let roundLeagueless = UUID(uuidString: "dddddddd-0000-0000-0000-000000000002")!

private let postInLeague  = UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000001")!
private let postOtherLeague = UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000002")!
private let postOnPerson  = UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000003")!

private func at(_ s: Int) -> Date { Date(timeIntervalSince1970: 1_756_000_000 + Double(s)) }

private let names: [UUID: String] = [me: "Jerecho", galen: "Galen", lone: "Blake"]
private let roster: [UUID: UUID] = [myMemA: me, myMemB: me, galenMem: galen]

// MARK: - 1 · the round with no season reaches a board

@Suite("D238 · a round in no season window still reaches a board")
struct PersonHomedPostTests {

  /// THE WHOLE POINT. Before D238 this round had no post at all, so
  /// `HomeSocial.pick` returned nothing for it and the strip was not drawn.
  @Test func aLeaguelessRoundNowHasATarget() {
    let posts = [
      HomeSocial.PostLite(id: postOnPerson, league_id: nil, profile_id: lone,
                          round_id: roundLeagueless, created_at: at(10)),
    ]
    let t = HomeSocial.pick(posts: posts, currentLeague: nil)
    #expect(t[roundLeagueless]?.postId == postOnPerson)
    // and it carries NO league, which is what the write path has to survive
    #expect(t[roundLeagueless]?.leagueId == nil)
  }

  /// A post homed on NOTHING is not a strip. The CHECK forbids the row, but a
  /// client that trusts a payload it did not write is how a blank affordance
  /// ships — so the fence is here too.
  @Test func aPostHomedOnNothingIsNotATarget() {
    let posts = [
      HomeSocial.PostLite(id: postOnPerson, league_id: nil, profile_id: nil,
                          round_id: roundLeagueless, created_at: at(10)),
    ]
    #expect(HomeSocial.pick(posts: posts, currentLeague: nil).isEmpty)
  }

  /// The order is written down once, in `pick`. A league post outranks a
  /// person-homed one, and the OPEN league outranks another league's.
  @Test func theOpenLeagueWinsThenAnyLeagueThenThePerson() {
    let posts = [
      HomeSocial.PostLite(id: postOnPerson, league_id: nil, profile_id: galen, round_id: roundLeagued, created_at: at(1)),
      HomeSocial.PostLite(id: postOtherLeague, league_id: leagueTwo, profile_id: nil, round_id: roundLeagued, created_at: at(2)),
      HomeSocial.PostLite(id: postInLeague, league_id: leagueOne, profile_id: nil, round_id: roundLeagued, created_at: at(3)),
    ]
    #expect(HomeSocial.pick(posts: posts, currentLeague: leagueOne)[roundLeagued]?.postId == postInLeague)
    // with no league open, the OLDEST league post wins — one deterministic
    // choice, not whichever row PostgREST happened to return first
    #expect(HomeSocial.pick(posts: posts, currentLeague: nil)[roundLeagued]?.postId == postOtherLeague)
  }

  /// Both rows on one Home: a league friend's round and a leagueless friend's.
  /// Both get a strip; neither borrows the other's.
  @Test func bothKindsOfRoundOnOneHome() {
    let posts = [
      HomeSocial.PostLite(id: postInLeague, league_id: leagueOne, profile_id: nil, round_id: roundLeagued, created_at: at(1)),
      HomeSocial.PostLite(id: postOnPerson, league_id: nil, profile_id: lone, round_id: roundLeagueless, created_at: at(2)),
    ]
    let t = HomeSocial.pick(posts: posts, currentLeague: leagueOne)
    #expect(t.count == 2)
    #expect(t[roundLeagued]?.postId == postInLeague)
    #expect(t[roundLeagueless]?.postId == postOnPerson)
  }
}

// MARK: - 2 · kudos survive the re-key

@Suite("D238 · kudos survive the re-key")
struct PersonHomedKudosTests {

  /// A row written BEFORE the push carries only `member_id`; a row written
  /// after carries `profile_id`; the backfill leaves the five existing rows
  /// carrying both. All three name the same golfer.
  @Test func allThreeErasNameTheSameGolfer() {
    let legacy  = BoardKudos.Row(post_id: postInLeague, member_id: galenMem, emoji: "azalea")
    let modern  = BoardKudos.Row(post_id: postInLeague, profile_id: galen, emoji: "azalea")
    let both    = BoardKudos.Row(post_id: postInLeague, profile_id: galen, member_id: galenMem, emoji: "azalea")
    for r in [legacy, modern, both] {
      #expect(BoardKudos.author(r, memberToProfile: roster) == galen)
    }
  }

  /// A row that resolves to nobody is nobody. The board has always said
  /// "Someone" rather than guessing, and `author` returning nil is what makes
  /// that the only available answer.
  @Test func anUnresolvableRowIsNobody() {
    let orphan = BoardKudos.Row(post_id: postInLeague, member_id: UUID(), emoji: "azalea")
    #expect(BoardKudos.author(orphan, memberToProfile: roster) == nil)
    #expect(BoardKudos.author(BoardKudos.Row(post_id: postInLeague, emoji: "azalea"), memberToProfile: roster) == nil)
  }

  /// THE DEFECT THE RE-KEY FIXES. A golfer in two leagues has two member ids.
  /// Under the old key, "is this mine" was a comparison against ONE of them —
  /// so my own 🔥, left through my second membership, read as somebody else's.
  @Test func myOwnReactionThroughEitherMembershipIsMine() {
    let viaA = BoardKudos.Row(post_id: postInLeague, member_id: myMemA, emoji: "azalea")
    let viaB = BoardKudos.Row(post_id: postInLeague, member_id: myMemB, emoji: "azalea")
    let viaProfile = BoardKudos.Row(post_id: postOnPerson, profile_id: me, emoji: "azalea")
    // the OLD test: one membership in hand, and no roster to resolve the other
    #expect(BoardKudos.isMine(viaA, me: me, myMemberIds: [myMemA]) == true)
    #expect(BoardKudos.isMine(viaB, me: me, myMemberIds: [myMemA]) == false)   // the bug
    // the NEW key: the person. It holds for a profile-keyed row with NO
    // membership in hand at all, and for a legacy row the roster resolves.
    #expect(BoardKudos.isMine(viaProfile, me: me, myMemberIds: []) == true)
    #expect(BoardKudos.isMine(viaB, me: me, myMemberIds: [myMemA], memberToProfile: roster) == true)
    #expect(BoardKudos.isMine(viaB, me: me, myMemberIds: [myMemA, myMemB]) == true)
    // and somebody else is still somebody else, by either road
    #expect(BoardKudos.isMine(BoardKudos.Row(post_id: postOnPerson, profile_id: galen, emoji: "azalea"),
                              me: me, myMemberIds: [myMemA, myMemB]) == false)
    #expect(BoardKudos.isMine(BoardKudos.Row(post_id: postOnPerson, member_id: galenMem, emoji: "azalea"),
                              me: me, myMemberIds: [myMemA, myMemB], memberToProfile: roster) == false)
  }

  /// Folding a mixed set: one legacy row, one modern row, both on the SAME
  /// post and the same emoji. Two reactions, two names, and mine is mine.
  @Test func aMixedSetFoldsIntoOneHonestStrip() {
    let kudos = [
      HomeSocial.KudoLite(post_id: postOnPerson, member_id: galenMem, emoji: "azalea", created_at: at(1)),
      HomeSocial.KudoLite(post_id: postOnPerson, profile_id: me, emoji: "azalea", created_at: at(2)),
      HomeSocial.KudoLite(post_id: postOnPerson, profile_id: galen, emoji: "eagle", created_at: at(3)),
    ]
    let rx = HomeSocial.fold(kudos: kudos, names: names, me: me, myMemberIds: [myMemA], memberToProfile: roster)
    #expect(rx[postOnPerson]?["azalea"]?.n == 2)
    #expect(rx[postOnPerson]?["azalea"]?.me == true)
    #expect(rx[postOnPerson]?["azalea"]?.who.sorted() == ["Galen", "Jerecho"])
    // D309 · the vocabulary is the four tokens now, and the rule survives the
    // change intact: an eagle stays an eagle and never becomes the quick token
    #expect(rx[postOnPerson]?["eagle"]?.n == 1)
    #expect(rx[postOnPerson]?["eagle"]?.me == false)
  }

  /// A row written before `emoji` existed still means the quick chip — which
  /// is what the column's own default already stamped. This is NOT the same
  /// as the retired fallback that turned a 🦅 into a 🔥: that one changed a
  /// reaction somebody actually chose.
  @Test func aRowWithNoEmojiIsTheQuickChip() {
    #expect(BoardKudos.emoji(BoardKudos.Row(post_id: postOnPerson, profile_id: me, emoji: nil)) == CSReactions.quick)
    #expect(BoardKudos.emoji(BoardKudos.Row(post_id: postOnPerson, profile_id: me, emoji: "rake")) == "rake")
  }

  /// The declared fallback's one condition, as a value. A column PostgREST has
  /// never heard of retries the old shape; a refused write, a dead network or
  /// an RLS denial is NOT this and must reach the golfer as itself.
  @Test func theSkewFallbackFiresOnlyOnAMissingColumn() {
    #expect(BoardKudos.skewFallbackFires(on: "PGRST204: Could not find the 'profile_id' column of 'post_kudos'"))
    #expect(BoardKudos.skewFallbackFires(on: "column \"profile_id\" does not exist"))
    #expect(BoardKudos.skewFallbackFires(on: "42703"))
    #expect(BoardKudos.skewFallbackFires(on: "new row violates row-level security policy") == false)
    #expect(BoardKudos.skewFallbackFires(on: "The Internet connection appears to be offline.") == false)
    #expect(BoardKudos.skewFallbackFires(on: "duplicate key value violates unique constraint") == false)
  }

  /// The digest reads the same rows and must not tell me about my own 🔥.
  /// With the re-key the "not me" test is the person, so a second membership
  /// no longer smuggles my own reaction into my own news (L-22).
  @Test func theDigestNeverReportsMyOwnReaction() {
    var snap = HomeSocial.Snapshot()
    snap.me = me
    snap.myMemberIds = [myMemA]
    snap.names = names
    snap.targets = [roundLeagueless: HomeSocial.Target(postId: postOnPerson, leagueId: nil)]
    snap.raw = [
      HomeSocial.KudoLite(post_id: postOnPerson, member_id: myMemB, emoji: "azalea", created_at: at(100)),
      HomeSocial.KudoLite(post_id: postOnPerson, profile_id: galen, emoji: "eagle", created_at: at(101)),
    ]
    let rows = [HomeFeedRow(round_id: roundLeagueless, profile_id: me, golfer: "Jerecho", marker: nil, handle: nil,
                            gross: 84, pvi: nil, played_on: "2026-09-01", created_at: at(90),
                            course: "Papago", is_pr: nil, is_first: nil, is_sub80: nil, is_me: true, photo_path: nil)]
    let m = snap.mentions(rounds: rows, since: at(0), memberToProfile: roster)
    #expect(m.count == 1)
    #expect(m.first?.who == "Galen")
  }
}
