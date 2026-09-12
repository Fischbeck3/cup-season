// Cup Season — the dispatch (D228, D231, IOS-029b).
//
// Home files ONE ranked dispatch a day: a lead with a human subject, at most
// four items below it, each one sentence with one door. `home_dispatch(p_days)`
// scores every item on the server (six bands, modifiers capped at +99) and
// returns `tier`, `rank`, `rank_reason`, `route` and `suppress` per item —
// which is what lets the second client render a LIST instead of reimplementing
// a ladder (UX_PRINCIPLES.md §5.4 rule 1).
//
// This file is the payload model and `HomeRank`, the arrangement rule.
//
// WHY THE GATES RUN TWICE, ON PURPOSE. The server applies G1 (the fence), G2
// (the veto) and G5 (the cap); `HomeRank.arrange` applies them again over
// whatever comes back. It is the same rule twice deliberately: a ranker bug
// then produces a SHORTER screen rather than a standing in the lead slot, and
// the veto becomes a unit test rather than a SQL assertion. It is also the one
// arrangement rule the FALLBACK path can share, so an old payload and a new
// one are laid out by the same code.
//
// Every field is optional-tolerant. The owner deploys the database and the
// clients separately; a payload with a key this build has never heard of is
// ignored, and a payload missing one renders nothing in its place (L-44).

import Foundation

public enum HomeDispatch {

  // MARK: - The six tiers

  /// The bands, in the order `UX_PRINCIPLES.md` §5.1 states them. The raw
  /// values are the server's words; an unknown tier decodes to `.opportunity`,
  /// which is the lowest band and therefore the safest place to put a fact
  /// this build does not recognise.
  public enum Tier: String, Sendable, Equatable, CaseIterable {
    case closing, changed, coming, circle, chapter, opportunity

    /// The band's weight, used when the server sent no score — the fallback
    /// path, and any payload that predates `score`.
    public var band: Int {
      switch self {
      case .closing: 1000
      case .changed: 800
      case .coming: 600
      case .circle: 400
      case .chapter: 200
      case .opportunity: 100
      }
    }

    /// The static, tier-less order the declared fallback sorts by:
    /// CLOSING → CHANGED → COMING → CIRCLE, then everything else.
    public var fallbackOrder: Int {
      switch self {
      case .closing: 0
      case .changed: 1
      case .coming: 2
      case .circle: 3
      case .chapter: 4
      case .opportunity: 5
      }
    }
  }

  /// The 3.5-px spine does the state signalling (IOS-003 §1): ember = LIVE,
  /// gold = EARNED, a mut hairline for quiet-and-true. Gold never appears on
  /// a control (L-25) — this is a spine, not a button.
  public enum Spine: String, Sendable, Equatable {
    case ember, gold, mut
  }

  /// Where an item's one door leads. Every case exists on the phone today;
  /// a route this build cannot resolve decodes to nil and the item is dropped
  /// by the fence rather than rendered as a dead sentence.
  public enum Route: Sendable, Equatable {
    case composer
    case people
    case declare
    case live(UUID)
    case receipt(UUID)
    case plan(UUID)
    case season(UUID, pane: String?)
    case pot(UUID)
    case invite(UUID, kind: String?)

    static func make(kind: String?, id: UUID?, pane: String?) -> Route? {
      switch kind {
      case "composer": return .composer
      case "people": return .people
      case "declare": return .declare
      case "live": return id.map(Route.live)
      case "receipt": return id.map(Route.receipt)
      case "plan": return id.map(Route.plan)
      case "season": return id.map { .season($0, pane: pane) }
      case "pot": return id.map(Route.pot)
      case "invite": return id.map { .invite($0, kind: pane) }
      default: return nil
      }
    }
  }

  // MARK: - One item

  public struct Item: Decodable, Sendable, Equatable, Identifiable {
    /// Stable across opens, so two consecutive loads never reshuffle and a
    /// dedupe can tell one fact from another.
    public let key: String
    public let tier: Tier
    /// The server's own answer. nil on the fallback path.
    public let rank: Int?
    public let score: Int?
    /// The arithmetic in words — dumped by `-cs_dev_dispatch`, never rendered.
    public let rankReason: String?
    public let subject: String?
    /// G2 · the veto reads THIS. An item whose headline has no human subject
    /// keeps its score and is ineligible for rank 1.
    public let humanSubject: Bool
    public let eyebrow: String
    public let headline: String
    public let standfirst: String?
    public let action: String?
    /// G1 · the fence reads THIS. No door, no render.
    public let route: Route?
    public let leagueId: UUID?
    /// L-34 · what this item has spent. The lead's set is unioned with the ME
    /// strip's and everything below honours the union.
    public let suppress: Set<MeStripCopy.Fact>
    public let spine: Spine
    /// A calendar date or an instant, as the server wrote it — a String, per
    /// L-07. Used for the tie-break only; never parsed for arithmetic.
    public let at: String?

    /// Calendar-date plans use the same local day as their adjacent stamp.
    public func localHeadline(today: String = CSDate.today(), calendar: Calendar = .current) -> String {
      guard key.hasPrefix("plan:"), let at, at.count == 10,
            CSDate.local(at, calendar: calendar) != nil,
            let subject, !subject.isEmpty else { return headline }
      let day = MeStripCopy.dayWord(at, today: today, calendar: calendar)
      let when = (day == "today" || day == "tomorrow") ? day : "on \(day)"
      return subject == "you" ? "You have a round \(when)." : "\(subject) has you down for \(day)."
    }

    public var id: String { key }

    public init(key: String, tier: Tier, rank: Int? = nil, score: Int? = nil, rankReason: String? = nil,
                subject: String? = nil, humanSubject: Bool = false, eyebrow: String, headline: String,
                standfirst: String? = nil, action: String? = nil, route: Route? = nil, leagueId: UUID? = nil,
                suppress: Set<MeStripCopy.Fact> = [], spine: Spine = .mut, at: String? = nil) {
      self.key = key; self.tier = tier; self.rank = rank; self.score = score; self.rankReason = rankReason
      self.subject = subject; self.humanSubject = humanSubject; self.eyebrow = eyebrow; self.headline = headline
      self.standfirst = standfirst; self.action = action; self.route = route; self.leagueId = leagueId
      self.suppress = suppress; self.spine = spine; self.at = at
    }

    /// The score the arrangement sorts by: the server's when it sent one, the
    /// band otherwise. Never negative.
    public var weight: Int { max(0, score ?? tier.band) }

    private enum CodingKeys: String, CodingKey {
      case key, tier, rank, score, rank_reason, subject, human_subject, eyebrow
      case headline, standfirst, action, route, league_id, suppress, spine, at
    }
    private struct RouteSpec: Decodable { let kind: String?; let id: UUID?; let pane: String? }

    public init(from decoder: any Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      // One flattening helper: `try? decodeIfPresent` is `T??`, and every key
      // here is optional in BOTH senses — absent, or present and null.
      func opt<T: Decodable>(_ type: T.Type, _ k: CodingKeys) -> T? {
        (try? c.decodeIfPresent(type, forKey: k)) ?? nil
      }
      tier = opt(String.self, .tier).flatMap(Tier.init(rawValue:)) ?? .opportunity
      rank = opt(Int.self, .rank)
      score = opt(Int.self, .score)
      rankReason = opt(String.self, .rank_reason)
      subject = opt(String.self, .subject)
      humanSubject = opt(Bool.self, .human_subject) ?? false
      eyebrow = opt(String.self, .eyebrow) ?? ""
      headline = opt(String.self, .headline) ?? ""
      // C-12 · the key is DETERMINISTIC even for a payload this build did not
      // expect. `UUID().uuidString` gave a keyless item a fresh identity on
      // every decode, which broke the docstring's own promise — key is
      // `Identifiable.id` and the sort tie-break, so the deck reshuffled and
      // SwiftUI re-created every row on each load.
      key = opt(String.self, .key) ?? "\(tier.rawValue):\(headline)"
      standfirst = opt(String.self, .standfirst)
      action = opt(String.self, .action)
      let spec = opt(RouteSpec.self, .route)
      route = Route.make(kind: spec?.kind, id: spec?.id, pane: spec?.pane)
      leagueId = opt(UUID.self, .league_id)
      suppress = Set((opt([String].self, .suppress) ?? []).compactMap(MeStripCopy.Fact.init(rawValue:)))
      spine = opt(String.self, .spine).flatMap(Spine.init(rawValue:)) ?? .mut
      at = opt(String.self, .at)
    }
  }

  // MARK: - The payload

  /// `{ me, items, lead_suppress, generated_at }`.
  ///
  /// `me` is `native_home()`'s own payload, returned INSIDE this one so Home
  /// makes exactly one read and the strip and the items describe one instant.
  /// It is optional: a server that only sends items still renders, against the
  /// session's cached payload.
  public struct Payload: Decodable, Sendable {
    public let me: Me?
    public let items: [Item]
    public let leadSuppress: Set<MeStripCopy.Fact>
    public let generatedAt: Date?

    private enum CodingKeys: String, CodingKey { case me, items, lead_suppress, generated_at }

    public init(me: Me? = nil, items: [Item] = [], leadSuppress: Set<MeStripCopy.Fact> = [], generatedAt: Date? = nil) {
      self.me = me; self.items = items; self.leadSuppress = leadSuppress; self.generatedAt = generatedAt
    }

    public init(from decoder: any Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      func opt<T: Decodable>(_ type: T.Type, _ k: CodingKeys) -> T? {
        (try? c.decodeIfPresent(type, forKey: k)) ?? nil
      }
      me = opt(Me.self, .me)
      items = opt([Item].self, .items) ?? []
      leadSuppress = Set((opt([String].self, .lead_suppress) ?? []).compactMap(MeStripCopy.Fact.init(rawValue:)))
      generatedAt = opt(Date.self, .generated_at)
    }
  }
}

// MARK: - The arrangement rule

/// One lead, at most four items, and the three gates that make the lead
/// trustworthy. Pure: the same items always produce the same screen.
public enum HomeRank {

  /// One lead plus at most four (G5). `HOME_STATE_MATRIX.md` §2.3.
  public static let deckCap = 4

  public struct Ranked: Sendable, Equatable {
    /// The rank-1 item, or none. NO card is a legal answer — with only bands
    /// 5 and 6 the CHAPTER or the OPPORTUNITY *is* the lead, and with nothing
    /// at all Home is the strip, the wire and the four doors.
    public let lead: HomeDispatch.Item?
    /// Items 2…5, in rank order.
    public let deck: [HomeDispatch.Item]
    /// L-34 · the union of the ME strip's spent facts and the lead's own. It
    /// is a UNION and never a replacement: the strip already stands down the
    /// hero's owe line and the next-round chip, and dropping its set would
    /// bring both back on the same screen as the fact they repeat.
    public let suppress: Set<MeStripCopy.Fact>
    /// How many ranked items were cut by the cap — the fourth item's foot
    /// says so rather than the screen pretending they do not exist.
    public let cut: Int
    /// QB-18 · the items the cap cut, in rank order. The foot link opened the
    /// GOLFERS TAB, whatever the elided item was — so a season card's "1 more"
    /// landed a golfer in his address book with no way back to whatever he had
    /// been about to see. The link opens the item now, and names it.
    public let overflow: [HomeDispatch.Item]
    /// F-2 · the ROUNDS this arrangement has already told a story about.
    ///
    /// A-6's worked example in `UX_PRINCIPLES` §3 is exactly this: a buddy's
    /// personal best in the ranked deck and again in the wire one scroll
    /// below. The mechanism the design names — "the lead hands the deck a
    /// suppress" — was typed `Set<MeStripCopy.Fact>`, four ME facts, which
    /// cannot name a round. This can: `HomeFeedFold.fold` takes it and the
    /// wire drops the row the card already spent.
    public let spentRounds: Set<UUID>
    /// **What the MAIN COLUMN has already said** — the lead's facts plus every
    /// surviving deck item's. `HOME_STATE_MATRIX` §3 row 3 forbids the ME strip
    /// rendering "any fact the lead or the deck also renders", so the strip is
    /// built from THIS, after the arrangement, and yields to it. It is a
    /// one-way precedence — lead → deck → strip — and never a negotiation.
    public let columnFacts: Set<MeStripCopy.Fact>
    /// **Does the column already say where I stand?** The ME strip's season
    /// row — `2ND OF 2 · 4 BACK OF GALEN · A FINAL BETWEEN THE TWO OF YOU` —
    /// is the same sentence a CHANGED or CHAPTER card makes its headline out
    /// of, so on a morning when one of those leads, the row underneath was
    /// saying it a second time in smaller grey type. It is not a ME fact, so
    /// `columnFacts` cannot carry it; it travels as its own answer.
    public let saysStanding: Bool

    public var isEmpty: Bool { lead == nil && deck.isEmpty }

    public init(lead: HomeDispatch.Item?, deck: [HomeDispatch.Item],
                suppress: Set<MeStripCopy.Fact>, cut: Int, spentRounds: Set<UUID> = [],
                overflow: [HomeDispatch.Item] = [], columnFacts: Set<MeStripCopy.Fact> = [],
                saysStanding: Bool = false) {
      self.lead = lead; self.deck = deck; self.suppress = suppress
      self.cut = cut; self.spentRounds = spentRounds; self.overflow = overflow
      self.columnFacts = columnFacts; self.saysStanding = saysStanding
    }
  }

  /// An item whose whole point is where I stand in a season. The families are
  /// the ranker's own: `need:` (*"You are 4 back of Galen with 8 weeks left"* —
  /// rank, gap, name and clock, which is the season row's entire content),
  /// `move:` (CHANGED — the rank moved), `chapter:` (the season's standing
  /// truth), `lastseason:` and `runitback:` (last season's table). Keyed on
  /// the family, never on the prose.
  static func saysStanding(_ item: HomeDispatch.Item) -> Bool {
    ["need", "move", "chapter", "lastseason", "runitback"]
      .contains(item.key.split(separator: ":", maxSplits: 1).first.map(String.init) ?? "")
  }

  /// **What an item has spent — the missing `fact_ids`.**
  ///
  /// `INFORMATION_ARCHITECTURE` §R1 specifies every dispatch item carrying
  /// `fact_ids` alongside `suppress`. The server sends none, the client
  /// modelled none, and `suppress` itself is `'[]'::jsonb` on all but one
  /// producer — so G3 had nothing to compare and the whole de-dupe layer was
  /// inert on both sides of the wire.
  ///
  /// The server's own answer wins whenever it gave one. Where it did not, the
  /// set is derived from the item's KEY FAMILY — `plan:<id>`, `clash:<league>`
  /// — which is structure the server really does send. It is never derived
  /// from the headline: that is prose, and reading a fact out of prose is a
  /// guess (L-44). A family this table does not know spends nothing, which is
  /// the safe answer — an unknown item is shown, never silently dropped.
  static func facts(_ item: HomeDispatch.Item) -> Set<MeStripCopy.Fact> {
    if !item.suppress.isEmpty { return item.suppress }
    switch item.key.split(separator: ":", maxSplits: 1).first.map(String.init) ?? "" {
    // The weekly clash, when I have posted into it: the number the card puts
    // up for someone to answer is my last round. (The server sets this one
    // itself; the fall-back covers the fallback producer, which does not.)
    case "clash":            return [.myLastRound]
    // A dated plan of mine — the same tee the strip's NEXT slot names.
    case "plan", "firsttee": return [.myNextRound]
    default:                 return []
    }
  }

  /// The round an item has spent, when it has one. Derived from what the item
  /// already carries — its door, and the `story:<round>` key both producers
  /// mint — so nothing new travels on the wire and the SERVED path gets the
  /// de-dupe for free.
  static func spentRound(_ item: HomeDispatch.Item) -> UUID? {
    if case .receipt(let id) = item.route { return id }
    let parts = item.key.split(separator: ":", maxSplits: 1)
    if parts.count == 2, parts[0] == "story" { return UUID(uuidString: String(parts[1])) }
    return nil
  }

  /// The rule, in one function.
  ///
  /// 1. **G1 · the fence.** An item with no door, or with nothing to say,
  ///    scores nothing and does not render.
  /// 2. **The order.** The server's `rank` when every item carries one;
  ///    otherwise the score, then the tie-breaks: newer before older, then
  ///    the key, so two consecutive opens never reshuffle.
  /// 3. **G2 · the veto.** Rank 1 goes to the highest item WITH A HUMAN
  ///    SUBJECT. A bare standing keeps its score and sits in the deck.
  /// 4. **G5 · the cap.** One lead and at most four below it.
  ///
  /// `stripSuppress` is a set the CALLER already knows is spent. It is folded
  /// into `suppress` for the chips and it does NOT drop deck items: the strip
  /// yields to the column, never the other way round (§3 row 3). Home passes
  /// nothing and builds its strip from `columnFacts` afterwards.
  /// `useServerRank` chooses the ORDER (the server's `rank`, or the score);
  /// `allowLead` chooses whether there is a LEAD CARD AT ALL. They are two
  /// different questions and R-06 is about the second: the declared fallback
  /// orders its items and renders no lead.
  public static func arrange(_ items: [HomeDispatch.Item],
                             stripSuppress: Set<MeStripCopy.Fact> = [],
                             leadSuppress: Set<MeStripCopy.Fact> = [],
                             useServerRank: Bool = true,
                             allowLead: Bool = true) -> Ranked {
    // G1 · the fence.
    let live = items.filter { $0.route != nil && !$0.headline.trimmingCharacters(in: .whitespaces).isEmpty }
    guard !live.isEmpty else {
      return Ranked(lead: nil, deck: [], suppress: stripSuppress.union(leadSuppress), cut: 0, spentRounds: [],
                    columnFacts: leadSuppress)
    }

    let ranked = live.allSatisfy { $0.rank != nil }
    let sorted: [HomeDispatch.Item]
    if useServerRank && ranked {
      sorted = live.sorted { a, b in
        if a.rank != b.rank { return (a.rank ?? .max) < (b.rank ?? .max) }
        return a.key < b.key
      }
    } else {
      sorted = live.sorted { a, b in
        if a.weight != b.weight { return a.weight > b.weight }
        // newer before older; an item with no date sorts after one with one
        let (x, y) = (a.at ?? "", b.at ?? "")
        if x != y { return x > y }
        return a.key < b.key
      }
    }

    // G2 · the veto.
    //
    // R-06 · and the fallback leads with NOTHING. UX_PRINCIPLES §5.4 rule 2 —
    // restated verbatim in `HomeView`'s header and this file's — says the
    // declared fallback renders no lead card, "because a guessed lead is the
    // exact failure the veto exists to prevent". The web obeyed it (every
    // `csFallbackItems` item is `human_subject: false`) and the phone did not,
    // so the two clients drew a structurally different Home on the day the
    // ranker was unreachable — which, until the migrations land, is every day.
    let leadIndex = allowLead ? sorted.firstIndex(where: \.humanSubject) : nil
    let lead = leadIndex.map { sorted[$0] }
    var rest = sorted
    if let i = leadIndex { rest.remove(at: i) }

    // G3 · SUPPRESSION. **This rule was specified and never built.**
    //
    // `HOME_STATE_MATRIX` §2.3 G3: *"the lead publishes `suppress: Set<Fact>`;
    // any item whose ENTIRE fact set is suppressed is dropped."* Until now the
    // set was computed here, handed to `UpNextChips`, and to nothing else — so
    // the deck was `rest.prefix(cap)` verbatim and every fact the lead had
    // already spent could be spent again two cards below it. On a golfer in two
    // leagues that rendered *"Galen has today to answer your 89"* as the lead
    // and *"Jade has today to answer your 89"* as deck item 1: one round of
    // mine, reported twice, because two leagues each had a row about it.
    //
    // Partial overlap survives, exactly as G3 allows: an item that says
    // something the lead did NOT say keeps its place.
    let leadSpent = leadSuppress.union(lead?.suppress ?? [])
    let kept = rest.filter { item in
      let f = facts(item)
      return f.isEmpty || !f.isSubset(of: leadSpent)
    }
    let deck = Array(kept.prefix(deckCap))
    let overflow = Array(kept.dropFirst(deck.count))
    // The strip yields to the column, so the column's own facts are collected
    // here; `suppress` stays the full union, which is what the chips read.
    let column = leadSpent.union(deck.flatMap(facts))
    let spent = stripSuppress.union(column)
    // F-2 · every round the cards on screen have already told.
    let rounds = Set(([lead].compactMap { $0 } + deck).compactMap(spentRound))
    return Ranked(lead: lead, deck: deck, suppress: spent,
                  cut: overflow.count, spentRounds: rounds, overflow: overflow,
                  columnFacts: column,
                  saysStanding: ([lead].compactMap { $0 } + deck).contains(where: saysStanding))
  }

  /// The declared fallback's order — the static, tier-less
  /// **CLOSING → CHANGED → COMING → CIRCLE** of `UX_PRINCIPLES.md` §5.4 rule
  /// 2, with no lead card at all. Items that arrive with no tier take the
  /// same order, at the bottom.
  public static func fallbackOrder(_ items: [HomeDispatch.Item]) -> [HomeDispatch.Item] {
    items.filter { $0.route != nil }
      .sorted { a, b in
        if a.tier.fallbackOrder != b.tier.fallbackOrder { return a.tier.fallbackOrder < b.tier.fallbackOrder }
        let (x, y) = (a.at ?? "", b.at ?? "")
        if x != y { return x > y }
        return a.key < b.key
      }
  }
}
