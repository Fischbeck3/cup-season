// Cup Season — HOME, arranged (IOS-046, `surfaces/home.md` §1.2, §1.4, §1.5).
//
// `HomeRank` decides the ORDER. This decides the **weight**: which form the
// lead takes, what each surviving item is drawn as, and what the floor already
// knows the page is offering. It is pure over what is in hand, so the same
// payload always produces the same Home and a test can argue with a clause
// rather than with a screenshot.
//
// **THE ITEM KEY IS THE WEIGHT MAP** (`home.md` §4). `clash:` `floor:` `move:`
// `firsttee:` `live:` are competition moments; `chapter:` and `lastseason:`
// are a season's own truth; `plan:` `story:` `friend:` `invite:` are the
// circle; `runitback:` `first_round` `find_golfers` are the empties and the
// floor. Nothing is read out of the prose — that is a guess (L-44).
//
// THE ORDER THE WIRE RUNS IN: **outward from today**, and where a day has
// both, what is coming leads what has gone. A wire sorted newest-first puts
// Saturday's tee time above this morning's round, which reads as a calendar;
// sorted oldest-first it reads as an archive. Outward from today reads as a
// rundown, which is what §1.4 asks the wire to be.

import Foundation

public struct HomeWireRow: Identifiable {
  public enum Body {
    /// Weight 2 · a friend's round. With a photograph it is a full-bleed band;
    /// without one it is a 68pt slat, and **never a wash standing in for a
    /// picture** (§10.1).
    case round(HomeFeedRow, photoURL: URL?)
    /// Weight 4 · the season moment, on the pinned ceremony ground.
    case takeover(HomeDispatch.Item)
    /// Weight 5 · one quiet line with a day marker.
    case line(marker: String?, text: String, door: HomeWireDoor?)
    /// The digest — "Since you were here…" — one line, in `ink`, at the head
    /// of the wire, because it is about the rows under it.
    case digest(HomeDigest)
    case occasion(Occasion)
  }
  public let id: String
  public let body: Body
  /// The wire's own rhythm: a full-bleed band brings its own edge and needs no
  /// rule above it.
  public var leadsWithRule: Bool {
    if case .round(_, let url) = body { return url == nil }
    if case .takeover = body { return false }
    return true
  }
  public init(id: String, body: Body) { self.id = id; self.body = body }
}

/// Where a wire row's tap lands, as a VALUE — the Kit never holds a closure,
/// so an arranged page stays something a test can hold.
public enum HomeWireDoor {
  case feed(HomeFeedDoor)
  case item(HomeDispatch.Item)
}

public struct HomePage {

  /// The lead's three forms, and the fourth is none at all — **no lead is a
  /// legal answer**, and it is what a golfer with nothing pressing gets.
  public enum Lead {
    case none
    /// Weight 1 · the serif sentence with the 84 × 90 chip.
    case block(HomeDispatch.Item)
    /// **The night a season ends.** A ceremony is a physical object: the
    /// takeover band, `ceremonyInk` in both themes. This is what makes
    /// ceremony night and a brand-new account two visibly different surfaces
    /// rather than the same card with a different eyebrow word (audit H-03).
    case ceremony(HomeDispatch.Item)
    /// **The empty IS the page.** A brand-new golfer gets a drawn scorecard,
    /// the producer's own sentences and ONE primary button.
    case empty(HomeDispatch.Item)

    public var item: HomeDispatch.Item? {
      switch self {
      case .none: nil
      case .block(let i), .ceremony(let i), .empty(let i): i
      }
    }
  }

  public let lead: Lead
  public let rows: [HomeWireRow]
  /// The wire's empty, as an editorial block: the highest-ranked item nothing
  /// else has spent. Its door is the floor's lit door (§13.1) — a reference,
  /// not a second control on a screen that should carry one act.
  public let wireEmptyItem: HomeDispatch.Item?
  /// The roster empty — `EmptyRoot.wireEmpty(me:)`, and **never "add some
  /// buddies" to a golfer who has a season** (QB-05).
  public let wireEmpty: Bool
  public let failed: EmptyRoot?
  public let redacted: Bool
  /// The floor keys the page is ALREADY offering above the floor.
  public let offered: Set<String>
  /// The page carries its own ember PRIMARY, so the floor collapses to one row.
  public let hasPrimary: Bool
  /// **The page already spends the ember**, so the floor is entirely quiet.
  /// §1.5: exactly one ember object on the screen, and it is the single act
  /// the golfer should take now. A live lead's door wears the 2px `brand`
  /// rule; if the floor also lit a door, the screen would carry two acts in
  /// the live metal pointing at different places — which is H-06, closed by
  /// construction rather than by review.
  public let hasEmber: Bool
  /// The brand-new Home's three rows replace the wire entirely.
  public let firstRound: Bool
  /// The number in seat one is a starter, so the strip's line is the gloss.
  public let starter: Bool
  public let leadIsLive: Bool

  public var wireTitle: String { firstRound ? HomeFirstRound.eyebrow : "The wire" }

  // MARK: - The weight map

  static func family(_ key: String) -> String {
    key.split(separator: ":", maxSplits: 1).first.map(String.init) ?? key
  }

  /// A **ceremony**: a season that has just changed hands or just finished,
  /// and the golfer has not seen it yet. `spine == .gold` is the server saying
  /// EARNED, and `move:` / `chapter:` are the families that carry a season's
  /// own moment. `lastseason:` is deliberately NOT one: it is the season that
  /// ended a while ago, whose ceremony has been seen, and it leads as a quiet
  /// gold-slot block — which is exactly the difference between the two Homes
  /// the audit says look identical today.
  public static func isCeremony(_ item: HomeDispatch.Item) -> Bool {
    item.spine == .gold && ["move", "chapter"].contains(family(item.key))
  }

  /// The floor key a door lands on, so "the page already offers this" is
  /// decided on the ROUTE and never on the prose.
  public static func floorKey(for route: HomeDispatch.Route?) -> String? {
    switch route {
    // both put a round on the card; `ADD MY ROUND` beside `PUT A ROUND ON THE
    // SCHEDULE` is the same act twice at two weights, 380pt apart
    case .composer, .declare: "add_my_round"
    case .people: "find_golfers"
    case .invite: "join_with_a_code"
    default: nil
    }
  }

  // MARK: - The arrangement

  public static func make(me: Me?,
                          strip: MeStripCopy.Strip,
                          ranked: HomeRank.Ranked,
                          buckets: [HomeFeedBucket],
                          digest: HomeDigest? = nil,
                          occasion: Occasion? = nil,
                          loading: Bool = false,
                          feedFailed: Bool = false,
                          today: String = CSDate.today(),
                          calendar: Calendar = .current) -> HomePage {

    // **Brand new**: no season, and no round of their own. The empty is the
    // page, its door is the page's one primary, and the wire becomes the three
    // rows a first round turns on.
    let noSeasons = (me?.memberships ?? []).isEmpty
    let noRounds = (me?.profile?.rounds_count ?? 0) == 0
    let brandNew = noSeasons && noRounds && ranked.lead != nil

    let lead: Lead = {
      guard let l = ranked.lead else { return .none }
      if brandNew { return .empty(l) }
      if isCeremony(l) { return .ceremony(l) }
      return .block(l)
    }()

    // The ranked items that are NOT the lead. They enter the wire at the
    // weight their kind earns — never as four smaller copies of it.
    let rest = ranked.deck + ranked.overflow

    var rows: [(sort: Int, row: HomeWireRow)] = []
    if let d = digest, !brandNew {
      rows.append((sort: -1, row: HomeWireRow(id: "digest", body: .digest(d))))
    }
    if let o = occasion, !brandNew {
      rows.append((sort: 0, row: HomeWireRow(id: "occasion-\(o.key)", body: .occasion(o))))
    }

    for item in rest where !brandNew {
      let day = item.at.flatMap { CSDate.days(from: today, to: $0) }
      let body: HomeWireRow.Body = isCeremony(item)
        ? .takeover(item)
        : .line(marker: HomeWireCopy.dayMarker(item.at, today: today, calendar: calendar),
                text: item.headline, door: .item(item))
      rows.append((sort: distance(day), row: HomeWireRow(id: "i-\(item.key)", body: body)))
    }

    for bucket in buckets {
      for item in bucket.items {
        switch item {
        case .round(let r, let url):
          let day = (r.played_on).flatMap { CSDate.days(from: today, to: $0) }
          rows.append((sort: distance(day),
                       row: HomeWireRow(id: item.id, body: .round(r, photoURL: url))))
        case .moment(let p, _):
          let iso = p.created_at.map { CSDate.iso($0, calendar: calendar) }
          rows.append((sort: distance(iso.flatMap { CSDate.days(from: today, to: $0) }),
                       row: HomeWireRow(id: item.id,
                                        body: .line(marker: HomeWireCopy.dayMarker(iso, today: today, calendar: calendar),
                                                    text: HomeCopy.easeCaps(p.body ?? ""),
                                                    door: item.door.map(HomeWireDoor.feed)))))
        case .notes(let n):
          let iso = n.newest?.created_at.map { CSDate.iso($0, calendar: calendar) }
          rows.append((sort: distance(iso.flatMap { CSDate.days(from: today, to: $0) }),
                       row: HomeWireRow(id: item.id,
                                        body: .line(marker: HomeWireCopy.dayMarker(iso, today: today, calendar: calendar),
                                                    text: n.line(bucket: bucket.label),
                                                    door: item.door.map(HomeWireDoor.feed)))))
        }
      }
    }

    // Outward from today, and what is coming leads what has gone.
    var ordered = rows.enumerated()
      .sorted { a, b in a.element.sort != b.element.sort ? a.element.sort < b.element.sort : a.offset < b.offset }
      .map(\.element.row)

    // With NO feed at all, the highest-ranked survivor is not a quiet line —
    // it is the wire's own empty block, which is the state `home-quiet` draws.
    var wireEmptyItem: HomeDispatch.Item?
    let feedIsEmpty = buckets.allSatisfy { $0.items.isEmpty }
    if feedIsEmpty, !brandNew, let first = rest.first {
      wireEmptyItem = first
      ordered.removeAll { $0.id == "i-\(first.key)" }
    }

    let empty = ordered.isEmpty && wireEmptyItem == nil
    let failed = (feedFailed && empty && !brandNew) ? EmptyRoot.failedRead() : nil

    var offered = Set<String>()
    if let l = ranked.lead, let k = floorKey(for: l.route) { offered.insert(k) }
    if let w = wireEmptyItem, let k = floorKey(for: w.route) { offered.insert(k) }

    return HomePage(
      lead: lead,
      rows: brandNew ? [] : ordered,
      wireEmptyItem: brandNew ? nil : wireEmptyItem,
      wireEmpty: !brandNew && empty && failed == nil && !loading,
      failed: failed,
      redacted: loading && ranked.lead == nil && empty,
      offered: offered,
      hasPrimary: brandNew,
      hasEmber: brandNew || (ranked.lead?.spine == .ember && !(ranked.lead?.action ?? "").isEmpty),
      firstRound: brandNew,
      starter: strip.slots.first { $0.fact == .myNumber }?.label == "STARTER",
      leadIsLive: ranked.lead?.spine == .ember)
  }

  /// How far a row is from today, in the wire's own order: today first, then
  /// tomorrow, then yesterday. An undated row sorts to the end, because a row
  /// with no date cannot claim a place in a rundown.
  static func distance(_ days: Int?) -> Int {
    guard let days else { return Int.max }
    return days >= 0 ? days * 2 : (-days * 2) + 1
  }
}
