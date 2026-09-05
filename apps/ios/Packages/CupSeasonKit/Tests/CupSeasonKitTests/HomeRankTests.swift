// Cup Season — the desk rule, as a table (D231, UX_PRINCIPLES.md §5).
//
// The whole difference between this Home and the shipped one is one clause:
// **the lead must have a human subject.** The shipped Home led with
// `2nd of 2 — held`, a chip that had said "held" since Sunday, over a 40-word
// paragraph about Cup Final seeding. That is a database report with a serif
// face on it, and this suite is what makes "never again" enforceable.
//
// Thirteen states in (the state matrix's A…N), six tiers, the veto, the fence
// and the tie-breaks out.

import Testing
import Foundation
@testable import CupSeasonKit

/// One item, with only the fields the ranker reads.
private func item(_ key: String, _ tier: HomeDispatch.Tier, score: Int? = nil, rank: Int? = nil,
                  human: Bool = true, door: Bool = true, at: String? = nil,
                  suppress: Set<MeStripCopy.Fact> = [], headline: String? = nil) -> HomeDispatch.Item {
  .init(key: key, tier: tier, rank: rank, score: score, subject: human ? "Galen" : nil, humanSubject: human,
        eyebrow: key.uppercased(), headline: headline ?? "\(human ? "Galen" : "Second of eight") — \(key).",
        action: "Open it", route: door ? .composer : nil, suppress: suppress, at: at)
}

@Suite struct HomeRankTests {

  // MARK: - the veto

  @Test("G2 · THE VETO — a bare standing can never lead, however high it scores")
  func theVeto() {
    // the standing outscores everything and still does not lead
    let r = HomeRank.arrange([item("standing", .closing, score: 1056, human: false),
                             item("clash", .circle, score: 412)])
    #expect(r.lead?.key == "clash")
    #expect(r.deck.map(\.key) == ["standing"])       // it KEEPS its score and sits in the deck
  }

  @Test("G2 · with nothing human on the screen there is NO lead — a lead is never manufactured")
  func vetoLeavesNoLead() {
    let r = HomeRank.arrange([item("standing", .closing, score: 1000, human: false),
                             item("table", .chapter, score: 200, human: false)])
    #expect(r.lead == nil)
    #expect(r.deck.count == 2)
    #expect(!r.isEmpty)                              // the deck still renders
  }

  @Test("the veto is satisfied by a first-person verb as well as a name")
  func firstPersonPasses() {
    let mine = item("live", .closing, score: 1070, headline: "You are on the card right now.")
    #expect(HomeRank.arrange([mine]).lead?.key == "live")
  }

  // MARK: - the fence

  @Test("G1 · THE FENCE — an item with no door does not render at all, whatever its band")
  func theFence() {
    let r = HomeRank.arrange([item("doorless", .closing, score: 1000, door: false),
                             item("chapter", .chapter, score: 200)])
    #expect(r.lead?.key == "chapter")
    #expect(r.deck.isEmpty)
  }

  @Test("G1 · a sentence with no words is not an item either")
  func emptyHeadlineFenced() {
    let blank = HomeDispatch.Item(key: "blank", tier: .closing, score: 1000, humanSubject: true,
                                  eyebrow: "BLANK", headline: "   ", action: "Go", route: .composer)
    #expect(HomeRank.arrange([blank]).isEmpty)
  }

  // MARK: - the six tiers

  @Test("the six bands sort in the order UX_PRINCIPLES §5.1 states them")
  func sixTiers() {
    let all = HomeDispatch.Tier.allCases.map { item($0.rawValue, $0) }.shuffled()
    let r = HomeRank.arrange(all, useServerRank: false)
    #expect(r.lead?.tier == .closing)
    #expect(r.deck.map(\.tier) == [.changed, .coming, .circle, .chapter])   // G5 cuts the sixth
    #expect(r.cut == 1)
    #expect(HomeDispatch.Tier.allCases.map(\.band) == [1000, 800, 600, 400, 200, 100])
  }

  // MARK: - the cap

  @Test("G5 · THE CAP — one lead and at most four, and the overflow is COUNTED, never hidden")
  func theCap() {
    let many = (1...9).map { item("i\($0)", .circle, score: 400 - $0) }
    let r = HomeRank.arrange(many, useServerRank: false)
    #expect(r.lead?.key == "i1")
    #expect(r.deck.count == HomeRank.deckCap)
    #expect(r.cut == 4)
  }

  // MARK: - the tie-breaks

  @Test("the tie-breaks are deterministic: score, then newer before older, then the key")
  func tieBreaks() {
    let a = item("a", .circle, score: 400, at: "2026-09-01")
    let b = item("b", .circle, score: 400, at: "2026-09-04")
    let c = item("c", .circle, score: 400, at: "2026-09-04")
    let once = HomeRank.arrange([a, b, c], useServerRank: false)
    #expect([once.lead!.key] + once.deck.map(\.key) == ["b", "c", "a"])
    // and two consecutive opens never reshuffle
    #expect(HomeRank.arrange([c, a, b], useServerRank: false).deck.map(\.key) == once.deck.map(\.key))
  }

  @Test("the server's own rank wins when EVERY item carries one — the second client renders a list, it does not re-rank")
  func serverRankIsHonoured() {
    // deliberately perverse scores: the server ranked them the other way
    let items = [item("third", .closing, score: 1000, rank: 3),
                 item("first", .chapter, score: 100, rank: 1),
                 item("second", .circle, score: 400, rank: 2)]
    let r = HomeRank.arrange(items)
    #expect(r.lead?.key == "first")
    #expect(r.deck.map(\.key) == ["second", "third"])
    // one item without a rank and the client falls back to the score
    let mixed = HomeRank.arrange(items.map { $0.key == "second" ? item("second", .circle, score: 400) : $0 })
    #expect(mixed.lead?.key == "third")
  }

  @Test("an item with no score at all is worth its BAND — a payload that predates `score` still sorts")
  func bandIsTheFallbackScore() {
    #expect(item("x", .changed).weight == 800)
    #expect(item("x", .changed, score: 860).weight == 840 + 20)
    let r = HomeRank.arrange([item("late", .chapter), item("early", .closing)], useServerRank: false)
    #expect(r.lead?.key == "early")
  }

  // MARK: - suppression (L-34)

  @Test("L-34 · the lead's suppress set is UNIONED onto the strip's, never swapped for it")
  func suppressUnions() {
    let lead = item("clash", .closing, score: 1000, suppress: [.myLastRound])
    let r = HomeRank.arrange([lead], stripSuppress: [.myNextRound, .myMoney], leadSuppress: [.myNumber])
    #expect(r.suppress == [.myNumber, .myLastRound, .myNextRound, .myMoney])
  }

  @Test("an empty dispatch suppresses exactly what the strip does — no more, no less")
  func emptySuppress() {
    let r = HomeRank.arrange([], stripSuppress: [.myNextRound])
    #expect(r.lead == nil && r.deck.isEmpty && r.suppress == [.myNextRound])
  }

  // MARK: - the thirteen states

  /// The state matrix's own thirteen (A…N), each as the set of items its reads
  /// would produce, with the lead the matrix names. This is the table test: it
  /// is the only place the whole rule is exercised end to end.
  @Test("the thirteen states each produce the lead the matrix names — or, where the matrix says so, none")
  func theThirteenStates() {
    struct Case { let state: String; let items: [HomeDispatch.Item]; let lead: String?; let tier: HomeDispatch.Tier? }
    let cases: [Case] = [
      // A · brand new: only band 6 fires, and that IS the lead
      .init(state: "A", items: [item("first_round", .opportunity, score: 140)],
            lead: "first_round", tier: .opportunity),
      // B · rounds, no buddies: the chapter leads over the opportunity
      .init(state: "B", items: [item("chapter", .chapter, score: 200), item("find", .opportunity, score: 140)],
            lead: "chapter", tier: .chapter),
      // C · buddies, no competition: a dated plan outranks a rivalry fact
      .init(state: "C", items: [item("plan", .coming, score: 630), item("h2h", .circle, score: 412)],
            lead: "plan", tier: .coming),
      // D · a moment ahead
      .init(state: "D", items: [item("event", .coming, score: 620), item("rsvp", .closing, score: 1000, human: false)],
            lead: "event", tier: .coming),
      // E · a session open: the clock I can change
      .init(state: "E", items: [item("duel", .closing, score: 1054), item("event", .circle, score: 412)],
            lead: "duel", tier: .closing),
      // F1 · nothing closing: the chapter is the lead and says something slow and true
      .init(state: "F1", items: [item("chapter", .chapter, score: 205), item("standing", .changed, score: 800, human: false)],
            lead: "chapter", tier: .chapter),
      // F3 · I posted, they have not
      .init(state: "F3", items: [item("clash", .closing, score: 1056), item("move", .changed, score: 860)],
            lead: "clash", tier: .closing),
      // F4 · D216's yield: the idle clash is a COMING item and something else leads
      .init(state: "F4", items: [item("clash", .coming, score: 600), item("chapter", .chapter, score: 205)],
            lead: "clash", tier: .coming),
      // G · between seasons
      .init(state: "G", items: [item("lastseason", .chapter, score: 200), item("runitback", .opportunity, score: 100)],
            lead: "lastseason", tier: .chapter),
      // H · the night it ends
      .init(state: "H", items: [item("ceremony", .changed, score: 840)], lead: "ceremony", tier: .changed),
      // J · invited
      .init(state: "J", items: [item("invite", .closing, score: 1012), item("friend", .closing, score: 1008)],
            lead: "invite", tier: .closing),
      // K · a live round, the highest score the function can produce
      .init(state: "K", items: [item("live", .closing, score: 1070), item("clash", .closing, score: 1056)],
            lead: "live", tier: .closing),
      // N · offline with nothing cached: no items, no lead, and the doors carry the screen
      .init(state: "N", items: [], lead: nil, tier: nil),
    ]
    for c in cases {
      let r = HomeRank.arrange(c.items, useServerRank: false)
      #expect(r.lead?.key == c.lead, "state \(c.state): expected \(c.lead ?? "no lead"), got \(r.lead?.key ?? "none")")
      #expect(r.lead?.tier == c.tier, "state \(c.state): wrong tier")
      // and in EVERY state the lead, when there is one, has a human subject
      if let lead = r.lead { #expect(lead.humanSubject, "state \(c.state): the veto let a bare fact lead") }
      // and never more than five cards on the screen
      #expect(r.deck.count <= HomeRank.deckCap, "state \(c.state): the cap did not bite")
    }
  }

  // MARK: - the fallback's own order

  @Test("the declared fallback's order is static and tier-less: CLOSING → CHANGED → COMING → CIRCLE, then the rest")
  func fallbackOrderIsStatic() {
    let items = [item("chapter", .chapter, score: 9999),   // a score cannot buy its way up here
                 item("circle", .circle),
                 item("closing", .closing),
                 item("opportunity", .opportunity),
                 item("changed", .changed),
                 item("coming", .coming),
                 item("doorless", .closing, door: false)]
    #expect(HomeRank.fallbackOrder(items).map(\.key)
              == ["closing", "changed", "coming", "circle", "chapter", "opportunity"])
  }
}
