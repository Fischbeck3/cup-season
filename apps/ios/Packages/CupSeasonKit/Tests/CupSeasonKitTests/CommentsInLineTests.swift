import Foundation
import Testing
@testable import CupSeasonKit

/// D405 · comments live in line under the round they are on, and say whose round
/// it is. The words and the maps below are the web's (`csTalkPlaceholder`,
/// `csTalkRoundTitle`, `csTalkHead`, `csTalkChoice`, `CS_INBOX.line`), and the
/// names are invented.
struct CommentsInLineTests {
  private func json(_ value: String) throws -> JSONValue { try JSONDecoder().decode(JSONValue.self, from: Data(value.utf8)) }

  // MARK: · the copy

  @Test func theComposerSaysWhatItIsWritingOn() {
    #expect(TalkCopy.placeholder(owner: "Theo Park", gross: 84, mine: false) == "Comment on Theo’s 84…")
    #expect(TalkCopy.placeholder(owner: "Theo Park", gross: nil, mine: false) == "Comment on Theo’s round…")
    #expect(TalkCopy.placeholder(owner: nil, gross: 84, mine: false) == "Comment on this round…")
    #expect(TalkCopy.placeholder(owner: "  ", gross: 84, mine: false) == "Comment on this round…")
    #expect(TalkCopy.placeholder(owner: "Theo Park", gross: 79, mine: true) == "Comment on your 79…")
    #expect(TalkCopy.placeholder(owner: nil, gross: nil, mine: true) == "Comment on your round…")
  }

  @Test func theRoundsPageAndItsConversationNameTheGolfer() {
    #expect(TalkCopy.roundTitle("Theo Park") == "Theo’s round")
    #expect(TalkCopy.roundTitle(nil) == "The round" && TalkCopy.roundTitle("") == "The round")
    #expect(TalkCopy.conversationHead(owner: "Theo Park", gross: 84, mine: false) == "On Theo’s 84")
    #expect(TalkCopy.conversationHead(owner: "Theo Park", gross: nil, mine: false) == "On Theo’s round")
    #expect(TalkCopy.conversationHead(owner: "Theo Park", gross: 79, mine: true) == "On your 79")
    #expect(TalkCopy.conversationHead(owner: nil, gross: 84, mine: false) == "Conversation")
    #expect(TalkCopy.earlier(4) == "Earlier comments (4)")
    #expect(TalkCopy.preview(author: "Blake Hartwell", body: "Did the putt on 18 drop?") == "Blake: Did the putt on 18 drop?")
  }

  @Test func noWordInTheThreadsCopyIsFollow() {
    // D25 · the product has no follows. Every string the conversation can say.
    var said = [TalkCopy.head, TalkCopy.empty, TalkCopy.add, TalkCopy.reply, TalkCopy.send, TalkCopy.sendReply,
                TalkCopy.notifyHead, TalkCopy.mutedHint, TalkCopy.followHint, TalkCopy.replyHint, TalkCopy.offHint,
                TalkCopy.placeholder(owner: "Theo Park", gross: 84, mine: false), TalkCopy.roundTitle("Theo Park"),
                TalkCopy.conversationHead(owner: "Theo Park", gross: 84, mine: false), TalkCopy.earlier(2)]
    said += TalkCopy.Notify.allCases.map(\.label)
    for text in said { #expect(!text.localizedCaseInsensitiveContains("follow"), "“\(text)”") }
  }

  // MARK: · what a golfer hears about

  @Test func theThreeAnswersMapOntoTheStoredState() {
    #expect(TalkCopy.Notify.every.state == "following" && TalkCopy.Notify.replies.state == "replies" && TalkCopy.Notify.nothing.state == "muted")
    // a golfer who is not the owner: no row is the baseline, "replies"
    #expect(TalkCopy.notify(state: "none", isMine: false, ownRoundOn: true) == .replies)
    #expect(TalkCopy.notify(state: "replies", isMine: false, ownRoundOn: true) == .replies)
    #expect(TalkCopy.notify(state: "following", isMine: false, ownRoundOn: true) == .every)
    #expect(TalkCopy.notify(state: "muted", isMine: false, ownRoundOn: true) == .nothing)
    // the owner hears every comment for free while `own_round` is on…
    #expect(TalkCopy.notify(state: "none", isMine: true, ownRoundOn: true) == .every)
    #expect(TalkCopy.notify(state: "replies", isMine: true, ownRoundOn: true) == .every)
    #expect(TalkCopy.notify(state: "muted", isMine: true, ownRoundOn: true) == .nothing)
    // …and with it switched off they are an ordinary golfer again
    #expect(TalkCopy.notify(state: "none", isMine: true, ownRoundOn: false) == .replies)
    #expect(TalkCopy.notify(state: "following", isMine: true, ownRoundOn: false) == .every)
  }

  @Test func theOwnerIsOfferedOnlyWhatTheServerDoesForThem() {
    #expect(TalkCopy.notifyOptions(isMine: false, ownRoundOn: true) == [.every, .replies, .nothing])
    #expect(TalkCopy.notifyOptions(isMine: true, ownRoundOn: true) == [.every, .nothing])
    #expect(TalkCopy.notifyOptions(isMine: true, ownRoundOn: false) == [.every, .replies, .nothing])
  }

  @Test func theLineUnderTheComposerTellsTheOwnerTheTruth() {
    // the owner is told about every comment, not "replies to you"
    #expect(TalkCopy.hint(state: "none", followedOn: true, repliesOn: true, isMine: true, ownRoundOn: true) == TalkCopy.followHint)
    #expect(TalkCopy.hint(state: "muted", followedOn: true, repliesOn: true, isMine: true, ownRoundOn: true) == TalkCopy.mutedHint)
    #expect(TalkCopy.hint(state: "none", followedOn: true, repliesOn: true, isMine: true, ownRoundOn: false) == TalkCopy.replyHint)
    #expect(TalkCopy.hint(state: "replies", followedOn: true, repliesOn: true) == TalkCopy.replyHint)
    // existing callers (no owner) read exactly as they did
    #expect(TalkCopy.hint(state: "none", followedOn: true, repliesOn: false) == TalkCopy.offHint)
  }

  // MARK: · the thread, from the server's own payload

  private func thread(_ extra: String = "", comments n: Int = 5, count: Int? = nil) throws -> PostedRoundThread {
    let rows = (1...max(n, 1)).prefix(n).map { i in
      "{\"id\":\"00000000-0000-4000-8000-0000000000\(String(format: "%02d", i))\",\"author\":{\"id\":\"33333333-3333-4333-8333-333333333333\",\"name\":\"Blake Hartwell\"},\"body\":\"c\(i)\"}"
    }.joined(separator: ",")
    return PostedRoundThread(try json("""
      {"ok":true,"can_comment":true,"count":\(count ?? n),
       "round":{"owner":{"id":"44444444-4444-4444-8444-444444444444","name":"Theo Park","marker":"lonetree"},"gross":84,"is_mine":false},
       "notify_prefs":{"own_round":true,"replies":true,"followed":true},
       "thread":{"state":"none"}\(extra),"comments":[\(rows)]}
      """))
  }

  @Test func theThreadKnowsWhoseRoundItIsAndWhatItWas() throws {
    let t = try thread()
    #expect(t.ownerName == "Theo Park" && t.gross == 84 && !t.isMine && t.ownerMarker == "lonetree")
    #expect(t.placeholder == "Comment on Theo’s 84…" && t.conversationHead == "On Theo’s 84")
    #expect(t.notify == .replies && t.notifyOptions == [.every, .replies, .nothing])
    // the owner's own thread
    let mine = PostedRoundThread(try json("""
      {"ok":true,"can_comment":true,"count":0,"round":{"owner":{"id":"44444444-4444-4444-8444-444444444444","name":"Avery"},"gross":79,"is_mine":true},
       "notify_prefs":{"own_round":true},"thread":{"state":"none"},"comments":[]}
      """))
    #expect(mine.isMine && mine.placeholder == "Comment on your 79…" && mine.conversationHead == "On your 79")
    #expect(mine.notify == .every && mine.notifyOptions == [.every, .nothing] && mine.hint == TalkCopy.followHint)
    // a server's payload with no round block degrades to the plain words
    let bare = PostedRoundThread(try json("{\"ok\":true,\"can_comment\":true,\"count\":0,\"comments\":[]}"))
    #expect(bare.placeholder == "Comment on this round…" && bare.conversationHead == "Conversation")
  }

  @Test func theInLineViewShowsTheNewestThreeAndCountsTheRest() throws {
    let t = try thread(comments: 5)
    #expect(t.recent().map(\.body) == ["c3", "c4", "c5"], "the newest three, oldest first")
    #expect(t.earlierCount(showing: t.recent().count) == 2)
    let few = try thread(comments: 2)
    #expect(few.recent().map(\.body) == ["c1", "c2"] && few.earlierCount(showing: 2) == 0)
    // 240 comments exist but the server sent its newest page: the count is the server's
    let big = try thread(comments: 5, count: 240)
    #expect(big.earlierCount(showing: 3) == 237)
    #expect(try thread(comments: 0, count: 0).recent().isEmpty)
  }

  @Test func aStateChosenOnPurposePassesThrough() throws {
    #expect(try thread(",\"x\":0").state == "none")
    let replies = PostedRoundThread(try json("{\"ok\":true,\"thread\":{\"state\":\"replies\"},\"comments\":[]}"))
    #expect(replies.state == "replies" && replies.notify == .replies)
  }

  // MARK: · the door Home and the board draw

  @Test func theDoorCarriesTheNewestComment() throws {
    let d = RoundSocialDoor(try json("""
      {"round_id":"22222222-2222-4222-8222-222222222222","comment_count":3,"thread_state":"following",
       "latest":{"id":"33333333-3333-4333-8333-333333333333","author":{"id":"44444444-4444-4444-8444-444444444444","name":"Blake Hartwell"},
                 "body":"Did the putt on 18 drop?","created_at":"2026-09-25T17:02:11.123456+00:00"}}
      """))
    #expect(d.commentCount == 3 && d.threadState == "following")
    #expect(d.latest?.author.name == "Blake Hartwell" && d.latest?.body == "Did the putt on 18 drop?")
    #expect(d.previewLine == "Blake: Did the putt on 18 drop?")
  }

  @Test func aServerBeforeTheMigrationDrawsTheCountAlone() throws {
    let old = RoundSocialDoor(try json("{\"round_id\":\"22222222-2222-4222-8222-222222222222\",\"comment_count\":3}"))
    #expect(old.commentCount == 3 && old.latest == nil && old.previewLine == nil && old.threadState == "none")
    // no comment, or a blank one: nothing extra is drawn
    let none = RoundSocialDoor(try json("{\"comment_count\":0,\"latest\":null}"))
    #expect(none.previewLine == nil)
    let blank = RoundSocialDoor(try json("""
      {"comment_count":1,"latest":{"id":"33333333-3333-4333-8333-333333333333","author":{"id":"44444444-4444-4444-8444-444444444444","name":"Blake"},"body":"   "}}
      """))
    #expect(blank.previewLine == nil)
  }

  /// A thread opened under a round on an older server tells the door how many comments it holds, but
  /// the door still draws no newest comment (the web, which reads the same `latest` key, does not either).
  @Test func aDoorFromAServerBeforeTheMigrationStaysACountWhenAThreadSpeaks() throws {
    let comment = try #require(SocialComment(try json("""
      {"id":"33333333-3333-4333-8333-333333333333","author":{"id":"44444444-4444-4444-8444-444444444444","name":"Blake Hartwell"},
       "body":"Did the putt on 18 drop?","created_at":"2026-09-25T18:10:00Z"}
      """)))
    let old = RoundSocialDoor(try json("{\"round_id\":\"22222222-2222-4222-8222-222222222222\",\"comment_count\":3}"))
    #expect(old.sendsLatest == false)
    let grown = old.updating(count: 4, newest: comment)
    #expect(grown.commentCount == 4 && grown.latest == nil && grown.previewLine == nil && grown.sendsLatest == false)
    // from the migration on the key is always there, null for a round nobody has spoken on
    let fresh = RoundSocialDoor(try json("{\"round_id\":\"22222222-2222-4222-8222-222222222222\",\"comment_count\":0,\"latest\":null}"))
    #expect(fresh.sendsLatest == true)
    let first = fresh.updating(count: 1, newest: comment)
    #expect(first.previewLine == "Blake: Did the putt on 18 drop?" && first.sendsLatest == true)
  }

  // MARK: · the notices name the round

  private func notice(_ kind: String, owner: String? = "Theo Park", mine: Bool? = false, course: String? = "North Grove") throws -> SocialNotice {
    let ownerJSON = owner.map { ",\"round_owner_name\":\"\($0)\"" } ?? ""
    let mineJSON = mine.map { ",\"round_is_mine\":\($0)" } ?? ""
    let courseJSON = course.map { ",\"course_name\":\"\($0)\"" } ?? ""
    return try #require(SocialNotice(try json("""
      {"id":"11111111-1111-4111-8111-111111111111","kind":"\(kind)","actor":{"id":"44444444-4444-4444-8444-444444444444","name":"Blake Hartwell"},
       "round_id":"22222222-2222-4222-8222-222222222222","comment_id":"33333333-3333-4333-8333-333333333333",
       "created_at":"2026-09-25T17:02:11Z","read":false,"excerpt":"x"\(ownerJSON)\(mineJSON)\(courseJSON)}
      """)))
  }

  @Test func aNoticeSaysWhichRoundItIsOn() throws {
    #expect(try notice("followed").sentence == "Blake commented on Theo’s round at North Grove.")
    #expect(try notice("followed", course: nil).sentence == "Blake commented on Theo’s round.")
    #expect(try notice("reply").sentence == "Blake replied to you on Theo’s round.")
    #expect(try notice("reply", mine: true).sentence == "Blake replied to you on your round.")
    #expect(try notice("own_round", mine: true).sentence == "Blake commented on your round.")
    // the owner who asked for every comment (own-round notice off) is told about their own round as one
    #expect(try notice("followed", mine: true).sentence == "Blake commented on your round.")
  }

  @Test func aServerBeforeTheMigrationKeepsTheOlderWords() throws {
    // no round_is_mine: it cannot be told whose round a reply is on, so it does not guess
    #expect(try notice("reply", mine: nil).sentence == "Blake replied to your comment.")
    #expect(try notice("reply", owner: nil, mine: false).sentence == "Blake replied to your comment.")
    #expect(try notice("followed", owner: nil, mine: nil, course: nil).sentence == "Blake commented in a conversation you’re in.")
    #expect(try notice("followed", owner: "  ").sentence == "Blake commented in a conversation you’re in.")
    // a real older server (D391) already sends the owner's name and the course, and not round_is_mine:
    // it cannot be told whether the round is the golfer's own, so the older words stand
    #expect(try notice("followed", mine: nil).sentence == "Blake commented in a conversation you’re in.")
  }

  @Test func theOwnersOwnCommentRepeatsTheNameBecauseThereIsOneRule() throws {
    let n = try #require(SocialNotice(try json("""
      {"id":"11111111-1111-4111-8111-111111111111","kind":"reply","actor":{"id":"44444444-4444-4444-8444-444444444444","name":"Theo Park"},
       "round_id":"22222222-2222-4222-8222-222222222222","comment_id":"33333333-3333-4333-8333-333333333333",
       "created_at":"2026-09-25T17:02:11Z","round_owner_name":"Theo Park","round_is_mine":false}
      """)))
    #expect(n.sentence == "Theo replied to you on Theo’s round.")
  }

  // MARK: · the Home digest counts the round's own conversation

  private let me = UUID(), roundMine = UUID(), roundTheirs = UUID()
  private func row(_ id: UUID, mine: Bool, gross: Int) -> HomeFeedRow {
    HomeFeedRow(round_id: id, profile_id: mine ? me : UUID(), golfer: "G", marker: nil, handle: nil,
                gross: gross, pvi: nil, played_on: "2026-09-01", created_at: SocialStamp.parse("2026-09-01T12:00:00Z"),
                course: "North Grove", is_pr: nil, is_first: nil, is_sub80: nil, is_me: mine, photo_path: nil)
  }
  private func comment(on round: UUID, actor: String, stamp: String) throws -> SocialNotice {
    try #require(SocialNotice(try json("""
      {"id":"\(UUID().uuidString)","kind":"own_round","actor":{"id":"\(UUID().uuidString)","name":"\(actor)"},
       "round_id":"\(round.uuidString)","comment_id":"\(UUID().uuidString)","created_at":"\(stamp)","read":false,"excerpt":"x"}
      """)))
  }

  @Test func theDigestCountsCommentsOnTheRoundsOwnThread() throws {
    let rows = [row(roundMine, mine: true, gross: 84), row(roundTheirs, mine: false, gross: 70)]
    // a mark after the first comment and before the second
    let mark = try #require(SocialStamp.parse("2026-09-21T23:30:00Z"))
    let notices = [try comment(on: roundMine, actor: "Blake Hartwell", stamp: "2026-09-21T23:00:00Z"),
                   try comment(on: roundMine, actor: "Mara Quinn", stamp: "2026-09-22T08:15:30.123456+00:00"),
                   try comment(on: roundTheirs, actor: "Blake Hartwell", stamp: "2026-09-22T09:00:00Z")]
    let m = HomeSocial.threadMentions(notices: notices, rounds: rows, since: mark)
    #expect(m.count == 1, "only a comment on MY round, after the mark")
    // the name as the other mentions carry it: a person's reaction and their comment are one name in a sentence
    #expect(m.first?.who == "Mara Quinn" && m.first?.gross == 84 && m.first?.roundId == roundMine && m.first?.emoji == nil)
    #expect(HomeDigest.mention(try #require(m.first), gross: "84") == "Mara Quinn chimed in on your 84")
    #expect(HomeSocial.threadMentions(notices: [], rounds: rows, since: mark).isEmpty)
  }

  @Test func aTimestampParsesWithOrWithoutItsFraction() {
    #expect(SocialStamp.parse("2026-09-25T17:02:11Z") != nil)
    #expect(SocialStamp.parse("2026-09-25T17:02:11.123456+00:00") != nil)
    #expect(SocialStamp.parse("not a date") == nil)
  }

  @Test func aCommentSaysHowLongAgoInTheWebsWords() throws {
    let now = try #require(SocialStamp.parse("2026-09-25T18:00:00Z"))
    #expect(SocialStamp.when("2026-09-25T17:59:30Z", now: now) == "Now")
    #expect(SocialStamp.when("2026-09-25T17:48:00Z", now: now) == "12m")
    #expect(SocialStamp.when("2026-09-25T16:00:00Z", now: now) == "2h")
    #expect(SocialStamp.when("2026-09-20T12:00:00Z", now: now).hasPrefix("Sep"))
    #expect(SocialStamp.when("2026-09-25T18:00:05Z", now: now) == "Now", "a clock a little ahead is still now")
    #expect(SocialStamp.when("garbage", now: now) == "")
  }

  // MARK: · a failed buddy list is not an empty one

  @Test func aFailedBuddyListOffersNothingToAdd() {
    let pid = UUID()
    #expect(BuddyRelation.from(nil as [Rpc.my_friends.Row]?, profile: pid) == .unknown)
    #expect(BuddyRelation.unknown.actionLabel == nil && BuddyRelation.unknown.tag == nil)
    // an answered, empty list is still "not a buddy"
    #expect(BuddyRelation.from([] as [Rpc.my_friends.Row]?, profile: pid) == .none)
    #expect(BuddyRelation.none.actionLabel == "Add buddy")
  }
}

@Suite struct ThreadWordsTests {
  @Test func aWordSaidAfterAReadWasAskedStandsAndOneSaidBeforeDoesNot() {
    var words = ThreadWords()
    let round = UUID(), other = UUID()
    words.note(round)                       // said before the read was asked
    let asked = words.now
    #expect(!words.spoke(for: round, after: asked), "a word from before the read is the read's to replace")
    words.note(round)                       // said while the read was out
    #expect(words.spoke(for: round, after: asked), "a word from after it stands")
    #expect(!words.spoke(for: other, after: asked), "another round's door is the read's")
    let later = words.now                   // a read asked after the word is the news again
    #expect(!words.spoke(for: round, after: later))
  }

  @Test func theClockOnlyMovesForward() {
    var words = ThreadWords()
    let round = UUID()
    let a = words.now
    words.note(round); words.note(round)
    #expect(words.now == a + 2)
  }
}

/// D405 · a round post on the board carries the same door as one on Home: its
/// comment count and its newest comment, read once with the social layer, and
/// corrected in place when the thread open under it sends or removes a comment.
@MainActor @Suite struct BoardDoorsTests {
  private func json(_ value: String) throws -> JSONValue { try JSONDecoder().decode(JSONValue.self, from: Data(value.utf8)) }

  @Test func aRoundPostCarriesItsDoorAndAnInLineCommentUpdatesIt() async throws {
    let league = UUID(), round = UUID(), post = UUID(), member = UUID()
    let author = try #require(SocialPerson(.object(["id": .string(UUID().uuidString), "name": .string("Blake Hartwell")])))
    let door = RoundSocialDoor(roundId: round, commentCount: 3,
                               latest: .init(id: UUID(), author: author, body: "Did the putt on 18 drop?", createdAt: ""))
    let repo = DoorsBoardFixture(post: PostRow(id: post, kind: "round", body: nil, created_at: Date(), member_id: member,
                                               round_id: round, live_round_id: nil), door: door)
    let store = BoardStore(leagueId: league, leagueName: "North Grove (fixture)", membership: nil, profileId: UUID(), repo: repo)
    await store.load()
    #expect(store.roundDoors[round]?.commentCount == 3)
    #expect(store.roundDoors[round]?.previewLine == "Blake: Did the putt on 18 drop?")
    // an open thread re-reads when the board does: the counter it watches moves with each read
    #expect(store.socialLoads == 1)
    await store.refreshSocial()
    #expect(store.socialLoads == 2)

    // a comment sent in line: four comments, and the newest is the one just said
    let mine = try #require(SocialComment(try json("""
      {"id":"33333333-3333-4333-8333-333333333333","author":{"id":"44444444-4444-4444-8444-444444444444","name":"Avery Fixture"},
       "body":"Level par on the back?","created_at":"2026-09-25T18:10:00Z","is_mine":true}
      """)))
    store.noteThread(round, count: 4, newest: mine)
    #expect(store.roundDoors[round]?.commentCount == 4)
    #expect(store.roundDoors[round]?.previewLine == "Avery: Level par on the back?")
    // the last comment removed: a door with no newest comment draws nothing under the post
    store.noteThread(round, count: 0, newest: nil)
    #expect(store.roundDoors[round]?.commentCount == 0 && store.roundDoors[round]?.previewLine == nil)
  }

  /// A doors read asked before a comment landed answers with the count from before it. The thread that sent the
  /// comment has already told the door, and its word stands; a read asked after it is the news again.
  @Test func aDoorsReadAskedBeforeAThreadSpokeDoesNotTakeItsWordBack() async throws {
    let league = UUID(), round = UUID(), post = UUID()
    let author = try #require(SocialPerson(.object(["id": .string(UUID().uuidString), "name": .string("Blake Hartwell")])))
    let door = RoundSocialDoor(roundId: round, commentCount: 3,
                               latest: .init(id: UUID(), author: author, body: "Did the putt on 18 drop?", createdAt: ""))
    let repo = DoorsBoardFixture(post: PostRow(id: post, kind: "round", body: nil, created_at: Date(), member_id: nil,
                                               round_id: round, live_round_id: nil), door: door)
    let store = BoardStore(leagueId: league, leagueName: "North Grove (fixture)", membership: nil, profileId: UUID(), repo: repo)
    await store.load()
    let mine = try #require(SocialComment(try json("""
      {"id":"33333333-3333-4333-8333-333333333333","author":{"id":"44444444-4444-4444-8444-444444444444","name":"Avery Fixture"},
       "body":"Level par on the back?","created_at":"2026-09-25T18:10:00Z","is_mine":true}
      """)))
    // the thread sends a comment while the board's read (which will answer with three comments) is out
    await repo.speakWhileAsking { store.noteThread(round, count: 4, newest: mine) }
    await store.refreshSocial()
    #expect(store.roundDoors[round]?.commentCount == 4, "the stale answer did not take the count back")
    #expect(store.roundDoors[round]?.previewLine == "Avery: Level par on the back?", "nor the newest comment")
    // the next read is asked after the word was said: it is the news now
    await store.refreshSocial()
    #expect(store.roundDoors[round]?.commentCount == 3)
  }

  @Test func aThreadSpeakingForARoundWithNoDoorMakesACountAlone() {
    let store = BoardStore(leagueId: UUID(), leagueName: "North Grove (fixture)", membership: nil, profileId: UUID(),
                           repo: DoorsBoardFixture(post: PostRow(id: UUID(), kind: "chat", body: "hi", created_at: Date(), member_id: nil,
                                                                  round_id: nil, live_round_id: nil), door: nil))
    let round = UUID()
    let comment = SocialComment(.object(["id": .string(UUID().uuidString),
                                         "author": .object(["id": .string(UUID().uuidString), "name": .string("Blake Hartwell")]),
                                         "body": .string("Did the putt on 18 drop?"), "created_at": .string("2026-09-25T18:10:00Z")]))
    store.noteThread(round, count: 1, newest: comment)
    #expect(store.roundDoors[round]?.commentCount == 1 && store.roundDoors[round]?.previewLine == nil,
            "a door made from a thread alone does not draw a newest comment the server was never heard to send")
  }

  @Test func aRepositoryThatCannotReadDoorsLeavesTheBoardWithoutThem() async {
    let league = UUID(), round = UUID(), post = UUID()
    let repo = DoorsBoardFixture(post: PostRow(id: post, kind: "round", body: nil, created_at: Date(), member_id: nil,
                                               round_id: round, live_round_id: nil), door: nil)
    let store = BoardStore(leagueId: league, leagueName: "North Grove (fixture)", membership: nil, profileId: UUID(), repo: repo)
    await store.load()
    #expect(store.roundDoors.isEmpty, "no door is drawn that the server did not answer")
    #expect(store.items.contains { $0.roundId == round })
  }

  @Test func aDoorTheServerNoLongerShowsGoesAndAReadThatDidNotHappenKeepsWhatIsThere() async throws {
    let league = UUID(), round = UUID(), post = UUID()
    let author = try #require(SocialPerson(.object(["id": .string(UUID().uuidString), "name": .string("Blake Hartwell")])))
    let door = RoundSocialDoor(roundId: round, commentCount: 2,
                               latest: .init(id: UUID(), author: author, body: "Same tees next week?", createdAt: ""))
    let repo = DoorsBoardFixture(post: PostRow(id: post, kind: "round", body: nil, created_at: Date(), member_id: nil,
                                               round_id: round, live_round_id: nil), door: door)
    let store = BoardStore(leagueId: league, leagueName: "North Grove (fixture)", membership: nil, profileId: UUID(), repo: repo)
    await store.load()
    #expect(store.roundDoors[round]?.commentCount == 2)
    // the read did not happen: the board keeps what it has
    await repo.set(.unread)
    await store.refreshSocial()
    #expect(store.roundDoors[round]?.commentCount == 2, "a failed read never wipes a door")
    // the server answered and left the round out (the owner muted the viewer, or it was voided): its door goes
    await repo.set(.hidden)
    await store.refreshSocial()
    #expect(store.roundDoors[round] == nil, "a round that is no longer visible keeps no count and no newest comment")
  }
}

private final class DoorsMode: @unchecked Sendable {
  var mode: DoorsBoardFixture.Mode = .normal
  /// runs once, while the next doors read is out (a thread speaking in the middle of it)
  var whileAsking: (@Sendable @MainActor () -> Void)?
}
private struct DoorsBoardFixture: BoardRepository {
  enum Mode { case normal, unread, hidden }
  let post: PostRow
  let door: RoundSocialDoor?
  private let state = DoorsMode()
  init(post: PostRow, door: RoundSocialDoor?) { self.post = post; self.door = door }
  func set(_ mode: Mode) async { state.mode = mode }
  func speakWhileAsking(_ speak: @escaping @Sendable @MainActor () -> Void) async { state.whileAsking = speak }
  func leagueData(league: UUID, season: UUID?) async throws -> BoardLeagueData { BoardLeagueData(members: [], squads: []) }
  func posts(league: UUID, limit: Int, before: Date?) async throws -> [PostRow] { [post] }
  func rounds(ids: [UUID], season: UUID?) async throws -> [UUID: BoardRound] { [:] }
  func social(postIds: [UUID]) async throws -> (kudos: [KudoRow], comments: [CommentRow]) { ([], []) }
  func roundDoors(ids: [UUID]) async -> [UUID: RoundSocialDoor]? {
    switch state.mode {
    case .unread: return nil
    case .hidden: return [:]
    case .normal:
      guard let door else { return nil }
      if let speak = state.whileAsking { state.whileAsking = nil; await speak() }
      guard let id = door.roundId, ids.contains(id) else { return [:] }
      return [id: door]
    }
  }
  func signedURLs(paths: [String]) async -> [String: URL] { [:] }
  func founderId() async -> UUID? { nil }
  func insertChat(league: UUID, season: UUID?, member: UUID, body: String) async throws {}
  func writeKudo(post: UUID, profile: UUID?, member: UUID?, emoji: String, had: Bool) async throws {}
  func insertComment(post: UUID, member: UUID, body: String) async throws {}
  func announce(league: UUID, body: String) async throws {}
  func report(post: UUID, reason: String) async throws {}
  func scorecard(liveRound: UUID) async throws -> JSONValue { .null }
}
