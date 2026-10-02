// The App Store frames are photographed on the STORE cast (`-cs_dev_cast store`),
// so it has to read as natural, invented names and never as test data (Apple's
// guideline 2.1 asks that placeholder text be scrubbed). The default cast is the
// one every other test and UI test pins, so it must not move. Nothing here talks
// to a network; the worlds are built in memory.

import Testing
import Foundation
import CupSeasonKit
@testable import CupSeason

@Suite struct SyntheticCastTests {
  // MARK: the words

  /// Fragments that read as test data. Matched anywhere in a name, in any case:
  /// "Samplewood" is as bad as "Sample". "qa" is the one whole-word match, because
  /// the letters sit inside real words.
  private static let forbidden = ["fixture", "placeholder", "stub", "sample", "test", "mock", "dummy", "faux",
                                  "lorem", "example", "tbd", "todo"]

  private static func testDataFragment(in text: String) -> String? {
    let lower = text.lowercased()
    if let hit = forbidden.first(where: { lower.contains($0) }) { return hit }
    if lower.range(of: "\\bqa\\b", options: .regularExpression) != nil { return "qa" }
    return nil
  }

  // MARK: the cast tables

  @Test func theStoreCastReadsAsNaturalNames() {
    let store = SynthCast.store
    for s in store.strings {
      #expect(Self.testDataFragment(in: s) == nil, "\(s)")
      #expect(!s.contains("(") && !s.contains(")"), "the \"(fixture)\" suffix is gone: \(s)")
      #expect(!s.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    // an event is not named for a trademark
    for name in [store.liveRyder, store.finishedRyder, store.major, store.majorTrophy, store.ryderTrophy] {
      #expect(!name.lowercased().contains("ryder") && !name.lowercased().contains("masters"), "\(name)")
    }
  }

  @Test func theStoreCastKeepsTheShapeOfTheFixtureCast() {
    let f = SynthCast.fixture, s = SynthCast.store
    #expect(s.golfers.count == 12 && s.golfers.count == f.golfers.count)
    #expect(s.courses.count == 3 && s.courses.count == f.courses.count)
    #expect(s.squads.count == 3 && s.squads.count == f.squads.count)
    #expect(s.ryderTeams.count == 2 && s.ryderTeams.count == f.ryderTeams.count)
    #expect(s.clinchSquads.count == f.clinchSquads.count)
    #expect(s.bag.clubs.count == 9 && s.bag.clubs.count == f.bag.clubs.count)
    // nobody is named twice
    #expect(Set(s.golfers.map(\.name)).count == 12)
    #expect(Set(s.golfers.map(\.handle)).count == 12)
    #expect(Set(s.courses.map(\.name)).count == 3)
    #expect(Set(s.squads).count == 3)
    #expect(s.cupLeague.name != s.squadsLeague.name && s.cupLeague.code != s.squadsLeague.code)
    // nothing is left behind from the fixture cast: the one string the two share is
    // the live round's guest, a plain first name
    #expect(Set(s.strings).intersection(f.strings) == [s.guest])
    // first names are the fixture cast's own, so a sentence that says "Blake" reads
    // the same in both, and the live round's four (You, Blake, Casey, Quinn) do too
    for n in 1...12 { #expect(s.first(n) == f.first(n), "person \(n)") }
    // the long names are still long, because they exist to exercise the layout
    #expect(s.golfers[8].name.count >= 28)
    #expect(s.golfers[8].name.count > s.golfers.enumerated().filter { $0.offset != 8 }.map { $0.element.name.count }.max()!)
    #expect(s.viewerLong.count >= 36)
    // `-cs_synth_long` names the viewer longer, in either cast
    #expect(s.viewerLong.hasPrefix(s.golfers[0].name) && f.viewerLong.hasPrefix(f.golfers[0].name))
  }

  @Test func noArgumentIsTheFixtureCast() {
    #expect(SynthCast.select([]).id == "fixture")
    #expect(SynthCast.select(["-cs_dev_synthetic", "season-live"]).id == "fixture")
    #expect(SynthCast.select(["-cs_dev_cast"]).id == "fixture")
    #expect(SynthCast.select(["-cs_dev_cast", "fixture"]).id == "fixture")
    #expect(SynthCast.select(["-cs_dev_cast", "nonsense"]).id == "fixture")
    #expect(SynthCast.select(["-cs_dev_synthetic", "ceremony", "-cs_dev_cast", "store"]).id == "store")
    // this test process asked for neither
    #expect(SynthCast.current.id == "fixture")
    #expect(SynthCast.select([]).strings == SynthCast.fixture.strings)
  }

  @Test func theFixtureCastIsUnchanged() {
    let f = SynthCast.fixture
    #expect(f.golfers.map(\.name) == [
      "Avery Fixture", "Blake Sample", "Casey Placeholder", "Devon Testcase", "Emerson Mockridge", "Finley Stub",
      "Gray Dummyton", "Harper Fauxley", "Maximilian Placeholder-Worthington", "Quinn Samplewood",
      "Rowan Mockingham", "Sage Exampleton"])
    #expect(f.golfers.map(\.handle) == [
      "fixture_avery", "fixture_blake", "fixture_casey", "fixture_devon", "fixture_emerson", "fixture_finley",
      "fixture_gray", "fixture_harper", "fixture_maximilian_long", "fixture_quinn", "fixture_rowan", "fixture_sage"])
    #expect(f.golfers.map(\.city) == [
      "Fixtureville", "Fixtureville", "Sampleton", "Fixtureville", "Sampleton", "Fixtureville",
      "Mockport", "Mockport", "Fixtureville", "Sampleton", "Mockport", "Fixtureville"])
    #expect(f.viewerLong == "Avery Fixture-Montgomery Hollingsworth")
    #expect(f.courses.map(\.name) == ["North Grove (fixture)", "Sample Links (fixture)", "Placeholder Pines (fixture)"])
    #expect(f.courses.map(\.city) == ["Fixtureville", "Sampleton", "Mockport"])
    #expect(f.cupLeague.name == "Fixture Cup League" && f.cupLeague.code == "FIXCUP")
    #expect(f.squadsLeague.name == "Placeholder Squads League" && f.squadsLeague.code == "FIXSQD")
    #expect(f.squads == ["Team Placeholder", "Team Stub", "Team Sample"])
    #expect(f.ryderTeams == ["Team Placeholder", "Team Stub"])
    #expect(f.clinchSquads == ["Fixture Javelinas", "Fixture Wrens"])
    #expect(f.inviteLeague.name == "Fixture Friday League" && f.inviteLeague.code == "FIXTURE24")
    #expect(f.rivalry == "The Grove Grudge (fixture)")
    #expect([f.liveRyder, f.finishedRyder, f.major] == ["Fixture Invitational", "Fixture Autumn Cup", "The Fixture Jug"])
    #expect([f.majorTrophy, f.ryderTrophy] == ["The Sample Invitational (fixture)", "Spring Ryder (fixture)"])
    #expect(f.bag.clubs == ["Fixture 460 driver, 10.5 deg", "Sample 3-wood, 15 deg", "Placeholder hybrid, 22 deg",
                            "Sample cavity 5", "Sample cavity 7", "Sample cavity 9", "Sample cavity PW",
                            "Fixture wedge 54", "Sample blade, 34 in"])
    #expect(f.bag.sidelinedDriver == "Old fixture driver, 9 deg" && f.bag.ball == "Fixture Tour X (sample)")
    #expect(f.guest == "Quinn")
  }

  // MARK: the worlds wear them

  @Test func aWorldWearsTheCastItIsGiven() {
    let byDefault = SyntheticWorld(.seasonLive)           // no argument: the default
    #expect(byDefault.cast.id == "fixture")
    assertWorn(byDefault, SynthCast.fixture)
    let store = SyntheticWorld(.seasonLive, cast: .store)
    #expect(store.cast.id == "store")
    assertWorn(store, SynthCast.store)
  }

  private func assertWorn(_ w: SyntheticWorld, _ c: SynthCast) {
    #expect(w.people.map(\.name) == c.golfers.map(\.name))
    #expect(w.people.map(\.handle) == c.golfers.map(\.handle))
    #expect(w.people.map(\.city) == c.golfers.map(\.city))
    #expect(w.courses.map(\.name) == c.courses.map(\.name))
    #expect(w.courses.map(\.city) == c.courses.map(\.city))
    #expect(w.leagues.map(\.name) == [c.cupLeague.name, c.squadsLeague.name])
    #expect(w.leagues.map(\.code) == [c.cupLeague.code, c.squadsLeague.code])
    #expect(w.squadNames.map { $0.name } == c.squads)
    #expect(w.events.prefix(2).map(\.name) == [c.liveRyder, c.finishedRyder])
    // ids and emails are not names: they are the same in both casts
    for p in w.people {
      #expect(p.ids.hasPrefix("f1c70000-"))
      #expect(p.email.hasSuffix("@example.invalid"))
    }
    #expect(w.courses.map(\.key) == ["fixture-north-grove", "fixture-sample-links", "fixture-placeholder-pines"])
  }

  /// Every PLACE a name is read, and not only where the world is built: the rivalry
  /// in its three places, the hardware, the bag, the invitation, the guest, the
  /// Ryders and what is posted in them, the signup guess. Run for both casts, so
  /// the default's slots are held in place as well as the store's.
  @Test(arguments: [SynthCast.fixture, SynthCast.store])
  func everyPlaceANameIsReadWearsTheCast(_ c: SynthCast) throws {
    let w = SyntheticWorld(.seasonLive, cast: c)
    // the rivalry: the list, the head to head, and the epilogue of a posted round
    let rivalries = try #require(ask(w, "my_rivalries") as? [[String: Any]])
    #expect(rivalries.first?["rivalry_name"] as? String == c.rivalry)
    let h2h = try #require(ask(w, "head_to_head", ["p_opponent": fids(2)]) as? [String: Any])
    #expect(h2h["rivalry_name"] as? String == c.rivalry)
    let posted = try #require(ask(w, "post_round", ["p_payload": ["gross": 84]]) as? [String: Any])
    let rivals = try #require((posted["epilogue"] as? [String: Any])?["rivals"] as? [[String: Any]])
    #expect(rivals.first?["rivalry_name"] as? String == c.rivalry)
    // the hardware, and the league's own trophy in the finished season
    let titles = try #require(ask(w, "my_trophies") as? [[String: Any]]).compactMap { $0["title"] as? String }
    #expect(titles == [c.majorTrophy, c.ryderTrophy])
    let done = SyntheticWorld(.ceremony, cast: c)
    let doneTitles = try #require(ask(done, "my_trophies") as? [[String: Any]]).compactMap { $0["title"] as? String }
    #expect(doneTitles == [c.cupLeague.name, c.majorTrophy, c.ryderTrophy])
    // the record names the viewer's squad (the second), and only that one
    let record = try #require(ask(w, "my_league_record") as? [[String: Any]])
    #expect(Set(record.compactMap { $0["squad_name"] as? String }) == [c.squads[1]])
    // the bag
    let bag = try #require(ask(w, "bag_of", ["p_profile": fids(1)]) as? [String: Any])
    #expect((bag["clubs"] as? [[String: Any]])?.compactMap { $0["label"] as? String } == c.bag.clubs)
    #expect(((bag["sideline"] as? [[String: Any]])?.first)?["label"] as? String == c.bag.sidelinedDriver)
    #expect((bag["ball"] as? [String: Any])?["label"] as? String == c.bag.ball)
    #expect((bag["since"] as? [String: Any])?["label"] as? String == c.bag.clubs[0])
    // the invitation, by its link, in the inbox and on Home
    #expect(ask(w, "league_by_code", ["p_code": c.inviteLeague.code]) as? String == c.inviteLeague.name)
    let invites = try #require(ask(w, "my_invites") as? [[String: Any]])
    #expect(invites.first?["container_name"] as? String == c.inviteLeague.name)
    let covenant = try #require(ask(w, "join_covenant_info") as? [String: Any])
    #expect(covenant["name"] as? String == c.inviteLeague.name)
    let home = try #require(ask(w, "home_dispatch", ["p_caps": ["afterplan": true]]) as? [String: Any])
    let headlines = try #require(home["items"] as? [[String: Any]]).compactMap { $0["headline"] as? String }
    #expect(headlines.contains("\(c.first(8)) put you on \(c.inviteLeague.name)."))
    // the guest with no account
    let claim = try #require(ask(w, "claim_round_info", ["p_token": SyntheticWorld.claimToken.uuidString.lowercased()]) as? [String: Any])
    #expect(claim["guest_name"] as? String == c.guest)
    let finished = try #require(ask(w, "finish_live_round") as? [String: Any])
    #expect(((finished["guests"] as? [[String: Any]])?.first)?["name"] as? String == c.guest)
    // the course's note names its town
    let rating = try #require(ask(w, "course_rating", ["p_course_id": w.courses[0].key]) as? [String: Any])
    #expect(((rating["notes"] as? [[String: Any]])?.first)?["note"] as? String == "The best par fives in \(c.courses[0].city).")
    // the signup guess, before the card is made, is the handle
    let gate = SyntheticWorld(.cardGate, cast: c)
    #expect((gate.nativeHome()["profile"] as? [String: Any])?["display_name"] as? String == c.golfers[0].handle)

    // the Ryders, the Major and the callout, and what is posted in them
    let events = SyntheticWorld(.eventLive, cast: c)
    #expect(events.events.map(\.name) == [c.liveRyder, c.finishedRyder, c.major, "\(c.first(1)) v \(c.first(2))"])
    #expect(events.events[0].teams.map { $0.name } == c.ryderTeams)
    #expect(events.events[3].teams.map { $0.name } == [c.first(1), c.first(2)])
    let posts = events.events.map { e in events.eventPosts(e).compactMap { $0["body"] as? String } }
    let weekThree = "Week three is open: \(c.first(1)) against \(c.first(5)), \(c.first(2)) against \(c.first(7)), "
      + "\(c.first(3)) against \(c.first(6)), \(c.first(4)) against \(c.first(8))."
    let weekTwo = "Week two is in. \(c.ryderTeams[0]) lead four and a half to three and a half."
    #expect(posts[0] == [weekThree, weekTwo])
    #expect(posts[1] == ["\(c.ryderTeams[0]) take the cup, nine to seven."])
    #expect(posts[3].first?.hasPrefix("\(c.first(2)) is in. The best round by ") == true)
    let lineage = try #require(ask(events, "event_lineage", ["p_event": fids(5_001)]) as? [[String: Any]])
    #expect(lineage.first?["winner_team"] as? String == c.ryderTeams[0])
  }

  /// One request, answered by the router the app installs, parsed the way a decoder would.
  private func ask(_ w: SyntheticWorld, _ name: String, _ params: [String: Any] = [:]) -> Any? {
    guard let data = try? reply(w, "POST", "rpc/" + name, params), !data.isEmpty else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  }

  private func reply(_ w: SyntheticWorld, _ method: String, _ path: String, _ params: [String: Any]) throws -> Data? {
    var request = URLRequest(url: try #require(URL(string: SyntheticSeam.supabaseURL.absoluteString + "/rest/v1/" + path)))
    request.httpMethod = method
    let body: Data? = params.isEmpty ? nil : try JSONSerialization.data(withJSONObject: params)
    return w.answer(SynthRequest(request, body))?.body
  }

  // MARK: nothing else says it

  /// Every answer the router can give about people, places, leagues and events, read
  /// the way a screen reads it, in every scenario: no string VALUE in any of them
  /// reads as test data. (Keys are not read: `latest_played_on` is a key, and
  /// "test" sits inside "latest".) The three `fixture-…` course keys are ids, which
  /// no screen draws, and are the only value allowed to carry the word.
  @Test func theStoreWorldSaysNothingThatReadsAsTestData() throws {
    let ids = ["fixture-north-grove", "fixture-sample-links", "fixture-placeholder-pines"]
    let word = try NSRegularExpression(
      pattern: "\\b(fixture|placeholder|stub|sample|test|mock|dummy|faux|lorem|example|tbd|todo)\\w*|\\bqa\\b",
      options: [.caseInsensitive])
    var asked = 0
    for scenario in SynthScenario.allCases where scenario.signedIn {
      let w = SyntheticWorld(scenario, cast: .store)
      var requests: [(method: String, path: String, params: [String: Any])] = []
      func rpc(_ name: String, _ params: [String: Any] = [:]) { requests.append(("POST", "rpc/" + name, params)) }
      func table(_ path: String) { requests.append(("GET", path, [:])) }

      rpc("native_home")
      rpc("home_dispatch", ["p_caps": ["afterplan": true]])
      rpc("home_feed")
      rpc("posted_rounds_social", ["p_rounds": w.feedRounds.map(\.ids)])
      rpc("my_notifications"); rpc("my_invites"); rpc("join_covenant_info")
      rpc("league_by_code", ["p_code": w.cast.inviteLeague.code])
      rpc("claim_round_info", ["p_token": SyntheticWorld.claimToken.uuidString.lowercased()])
      rpc("my_friends"); rpc("friends_board"); rpc("recent_partners")
      rpc("search_golfers", ["p_q": ""])
      rpc("head_to_head", ["p_opponent": fids(2)])
      rpc("my_rivalries"); rpc("rivalry_weeks")
      rpc("my_trophies"); rpc("my_achievements"); rpc("career_record"); rpc("my_league_record")
      rpc("tour_card", ["p_profile": fids(1)]); rpc("tour_card", ["p_profile": fids(3)])
      rpc("bag_of", ["p_profile": fids(1)]); rpc("save_bag")
      rpc("major_leaderboard", ["p_event": fids(5_003)])
      rpc("event_lineage", ["p_event": fids(5_001)]); rpc("event_lineage", ["p_event": fids(5_002)])
      rpc("round_card", ["p_round": fids(4_001)]); rpc("round_card", ["p_round": fids(4_101)])
      rpc("posted_round_thread", ["p_round": fids(4_001)])
      rpc("finish_live_round")
      rpc("course_home"); rpc("my_course_books"); rpc("my_course_ratings")
      rpc("my_schedule", ["p_from": w.day(-30), "p_to": w.day(60)])
      rpc("round_detail", ["p_round": fids(7_001)]); rpc("round_detail", ["p_round": fids(7_003)])
      table("profiles"); table("v_individual_standings"); table("api_courses"); table("league_members")
      table("posts?profile_id=eq.\(fids(1))")
      for event in [5_001, 5_002, 5_003, 5_004] {
        table("events?id=eq.\(fids(event))"); table("event_teams?event_id=eq.\(fids(event))")
        table("event_players?event_id=eq.\(fids(event))"); table("posts?event_id=eq.\(fids(event))")
      }
      for course in w.courses {
        rpc("course_page", ["p_course_id": course.key]); rpc("course_rating", ["p_course_id": course.key])
      }
      for l in w.leagues {
        let league: [String: Any] = ["p_league": l.ids]
        rpc("season_book", ["p_league_id": l.ids]); rpc("league_pulse", league); rpc("season_scenarios", league)
        rpc("cup_final_race", league); rpc("season_story", league)
        rpc("counting_rounds", ["p_member": l.memberIds(1), "p_month": String(w.day(0).prefix(7))])
        table("leagues?id=eq.\(l.ids)"); table("squads?league_id=eq.\(l.ids)")
        table("league_members?league_id=eq.\(l.ids)"); table("posts?league_id=eq.\(l.ids)")
        table("season_adjustments?season_id=eq.\(l.seasonIds)")
      }

      for (method, path, params) in requests {
        guard let answer = try reply(w, method, path, params) else { continue }
        asked += 1
        guard !answer.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: answer, options: [.fragmentsAllowed]) else { continue }
        for text in Self.stringValues(in: json) where !ids.contains(text) {
          let range = NSRange(text.startIndex..., in: text)
          #expect(word.firstMatch(in: text, range: range) == nil, "\(scenario.rawValue) · \(path): \(text)")
        }
      }
    }
    // a router that answers nothing would pass the loop above in silence
    #expect(asked > 200, "asked \(asked)")
  }

  private static func stringValues(in json: Any) -> [String] {
    if let s = json as? String { return [s] }
    if let a = json as? [Any] { return a.flatMap { Self.stringValues(in: $0) } }
    if let d = json as? [String: Any] { return d.values.flatMap { Self.stringValues(in: $0) } }
    return []
  }
}
