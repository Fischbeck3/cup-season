// Cup Season — the thirteen Home states, as payloads the ranker has to survive
// (D259 / IOS-040).
//
// The re-audit reached five of seventeen states. `-cs_dev_home_state <id>`
// makes the other twelve openable on a simulator, and `?cs_home_state=<id>`
// does the same on the desk — but a hatch nobody argues with is decoration, so
// THE SAME PAYLOADS ARE THE FIXTURES OF THIS SUITE. If a fixture stops being a
// legal Home, the build fails here rather than in a screenshot nobody takes.
//
// The payloads are generated from `tests/fixtures/home-states.json` (preflight
// 41 holds the twin fresh), so a state added for the phone is a state the web
// can open and a case this file asserts, all from one edit.

import Testing
import Foundation
@testable import CupSeasonKit

#if DEBUG
struct HomeStateFixtureTests {

  // MARK: - the set itself

  @Test func everyStateInTheBriefIsDeclared() {
    let want = ["brand_new", "rounds_no_buddies", "buddies_no_competition", "event_ahead", "event_live",
                "between_seasons", "ceremony_night", "inactive", "invited", "callout_pending",
                "preseason", "round_morning", "round_evening"]
    let got = HomeStateFixtures.all.map(\.id)
    #expect(got == want, "the ids drifted: \(got)")
    #expect(Set(HomeStateFixtures.all.map(\.matrix)).count == want.count, "two fixtures claim one matrix row")
  }

  @Test func everyFixtureDecodes() {
    for s in HomeStateFixtures.all {
      #expect(HomeStateFixtures.payload(s.id) != nil, "\(s.id) does not decode as a home_dispatch payload")
    }
    #expect(HomeStateFixtures.payload("no_such_state") == nil)
  }

  // MARK: - the dates are tokens, so a fixture never reads stale

  @Test func tokensResolveToRealCalendarDates() {
    let today = "2026-09-05"
    #expect(HomeStateFixtures.resolve("@today", today: today) == "2026-09-05")
    #expect(HomeStateFixtures.resolve("@today+6", today: today) == "2026-09-11")
    #expect(HomeStateFixtures.resolve("@today-3", today: today) == "2026-09-02")
    // the dateline eyebrow the record voice wears
    let eb = HomeStateFixtures.resolve("@eyebrow+0", today: today)
    #expect(eb == eb.uppercased() && eb.contains("·"), "an eyebrow is upper case and carries the middot: \(eb)")
  }

  @Test func noTokenSurvivesTheSubstitution() {
    for s in HomeStateFixtures.all {
      let resolved = HomeStateFixtures.resolve(s.json)
      #expect(!resolved.contains("@today"), "\(s.id) still carries an unresolved @today")
      #expect(!resolved.contains("@eyebrow"), "\(s.id) still carries an unresolved @eyebrow")
    }
  }

  @Test func everyDateInAPayloadIsARealDay() {
    for s in HomeStateFixtures.all {
      guard let p = HomeStateFixtures.payload(s.id) else { continue }
      for m in p.me?.memberships ?? [] {
        guard let season = m.season else { continue }
        #expect(CSDate.local(season.starts_on) != nil, "\(s.id): starts_on is not a date")
        #expect(CSDate.local(season.ends_on) != nil, "\(s.id): ends_on is not a date")
      }
      for r in p.me?.upcoming ?? [] {
        #expect(r.play_on == nil || CSDate.local(r.play_on!) != nil, "\(s.id): play_on is not a date")
      }
    }
  }

  // MARK: - the ranking rule, over the same payloads the screenshots use

  /// G1 · the fence. A fixture whose items have no door renders nothing, which
  /// would make its screenshot a picture of a bug in the fixture.
  @Test func everyFixtureSurvivesTheFence() {
    for s in HomeStateFixtures.all {
      guard let p = HomeStateFixtures.payload(s.id) else { continue }
      for it in p.items {
        #expect(it.route != nil, "\(s.id)/\(it.key) has no door — G1 drops it")
        #expect(!it.headline.trimmingCharacters(in: .whitespaces).isEmpty, "\(s.id)/\(it.key) has no headline")
      }
      let r = HomeRank.arrange(p.items, leadSuppress: p.leadSuppress)
      #expect(r.lead != nil, "\(s.id) arranges to no lead at all")
    }
  }

  /// G2 · the veto. Rank 1 goes to the highest item WITH A HUMAN SUBJECT — so
  /// wherever a fixture has one, the lead is it.
  @Test func theVetoHoldsInEveryState() {
    for s in HomeStateFixtures.all {
      guard let p = HomeStateFixtures.payload(s.id) else { continue }
      let r = HomeRank.arrange(p.items, leadSuppress: p.leadSuppress)
      guard p.items.contains(where: \.humanSubject) else { continue }
      #expect(r.lead?.humanSubject == true, "\(s.id) leads with a headline that has no human subject")
    }
  }

  /// G5 · the cap, and the arrangement is pure.
  @Test func theCapHoldsAndTheOrderIsStable() {
    for s in HomeStateFixtures.all {
      guard let p = HomeStateFixtures.payload(s.id) else { continue }
      let a = HomeRank.arrange(p.items, leadSuppress: p.leadSuppress)
      let b = HomeRank.arrange(p.items, leadSuppress: p.leadSuppress)
      #expect(a.deck.count <= HomeRank.deckCap, "\(s.id) renders \(a.deck.count) below the lead")
      #expect(a.lead?.key == b.lead?.key && a.deck.map(\.key) == b.deck.map(\.key), "\(s.id) reshuffles between two arranges")
    }
  }

  /// L-34 · the lead's suppress set is UNIONED onto the strip's, never swapped
  /// for it. S16's plan owns NEXT, and the strip must be told.
  @Test func theMorningOfARoundSpendsTheNextSlot() {
    let p = HomeStateFixtures.payload("round_morning")
    #expect(p?.leadSuppress.contains(.myNextRound) == true)
    let r = HomeRank.arrange(p?.items ?? [], stripSuppress: [.myNumber], leadSuppress: p?.leadSuppress ?? [])
    #expect(r.suppress.contains(.myNumber) && r.suppress.contains(.myNextRound),
            "the union lost one of its two halves")
  }

  /// F-2 · the evening after a round: the lead spends my own round, so the wire
  /// below it does not tell the same round again.
  @Test func theEveningAfterARoundSpendsIt() {
    let p = HomeStateFixtures.payload("round_evening")
    let r = HomeRank.arrange(p?.items ?? [], leadSuppress: p?.leadSuppress ?? [])
    #expect(r.spentRounds.count == 1, "the lead did not hand the wire the round it told")
  }

  // MARK: - the laws the copy has to keep

  /// G7 / L-22 · never a count of the golfer's own absence, never a sentence
  /// about what they have not done. `days_since_round` selects S9 and is never
  /// rendered — so no fixture may print the shapes that would give it away.
  @Test func noFixtureShamesTheGolfer() {
    let forbidden = ["you haven't", "you have not posted", "days since", "your streak is at risk",
                     "more active than you", "nothing posted this month"]
    for s in HomeStateFixtures.all {
      guard let p = HomeStateFixtures.payload(s.id) else { continue }
      for it in p.items {
        let line = "\(it.eyebrow) \(it.headline) \(it.standfirst ?? "") \(it.action ?? "")".lowercased()
        for bad in forbidden {
          #expect(!line.contains(bad), "\(s.id)/\(it.key) says \"\(bad)\"")
        }
      }
    }
  }

  /// R-J · the register the second sitting ruled, applied where it can be
  /// applied. A gendered pronoun inside a SENTENCE is legitimate when the same
  /// card names the person — "Galen took it by twelve… he has not posted" is
  /// four words from its own antecedent. A pronoun in a CONTROL or a DATELINE
  /// never has one, because neither is a sentence; and the phrasing R-J retired
  /// may not come back anywhere, which is the half preflight §4.34 also holds.
  @Test func noFixtureAddressesOneGolferInAMixedLeague() {
    let pronouns = ["him", "his", "her", "hers", "he", "she"]
    let retired = ["beat one guy", "one guy", "you and him", "i want to"]
    for s in HomeStateFixtures.all {
      guard let p = HomeStateFixtures.payload(s.id) else { continue }
      for it in p.items {
        for control in [it.action, it.eyebrow].compactMap({ $0 }) {
          let words = control.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
          for w in pronouns {
            #expect(!words.contains(w), "\(s.id)/\(it.key): the control \"\(control)\" carries \"\(w)\" with nothing to refer to")
          }
        }
        let line = "\(it.eyebrow) \(it.headline) \(it.standfirst ?? "") \(it.action ?? "")".lowercased()
        for bad in retired {
          #expect(!line.contains(bad), "\(s.id)/\(it.key) carries the phrasing R-J retired: \"\(bad)\"")
        }
      }
    }
  }

  /// The apostrophe. D254's numbered debt (b) is the repo-wide mix; nothing NEW
  /// may join it, and a fixture the next audit reads is copy like any other.
  /// Found by looking: S17 rendered "Galen's lead" with a typewriter quote.
  @Test func everyFixtureUsesTheTypographicApostrophe() {
    for s in HomeStateFixtures.all {
      guard let p = HomeStateFixtures.payload(s.id) else { continue }
      for it in p.items {
        let line = "\(it.eyebrow)\(it.headline)\(it.standfirst ?? "")\(it.action ?? "")"
        #expect(!line.contains("'"), "\(s.id)/\(it.key) carries a typewriter apostrophe")
      }
    }
  }

  /// The divergence the fixtures exist to make visible: the phone answers an
  /// invitation and a buddy request IN PLACE, so it drops those items; the web
  /// has no such banners and renders them. Neither is a defect, and a
  /// screenshot of S10 that did not know this would be filed as one.
  @Test func thePhoneDropsWhatItAnswersInPlace() {
    let p = HomeStateFixtures.payload("invited")
    #expect(p?.items.contains { if case .invite = $0.route { return true }; return false } == true,
            "the invited fixture no longer carries the item the two clients treat differently")
  }
}
#endif
