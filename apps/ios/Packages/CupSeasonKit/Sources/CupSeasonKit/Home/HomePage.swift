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

/// **THE WIRE'S DATELINE.** The four groups a rundown falls into, in reading
/// order: what is coming, today, the week just gone, and everything older.
///
/// `surfaces/home.md` §1.4 ruled that Today / This week / Earlier "survive as
/// day markers on the rows themselves, not as three more section heads", and
/// that is what shipped — a flat run of rows each carrying a 34pt date column.
/// **The owner installed it and read it as one block of text**, which is
/// exactly what a table of dated rows is. D280 reverses that clause: the
/// period is a HEAD with a real size and colour step, and the date column
/// inside a group goes away, because a row under TODAY does not need to say
/// Sun. The three words are the design's own; `ahead` is the fourth the wire
/// always needed, since its order runs OUTWARD from today and what is coming
/// leads what has gone.
public enum HomeWirePeriod: Int, Sendable, CaseIterable, Equatable, Comparable {
  case ahead = 0, today = 1, week = 2, earlier = 3

  /// The dateline the group prints.
  public var head: String {
    switch self {
    case .ahead: "Up next"
    case .today: "Today"
    case .week: "This week"
    case .earlier: "Earlier"
    }
  }

  /// Signed days from today — positive ahead, negative behind. **An undated
  /// row files under `earlier`**, for the same reason `distance(nil)` sorts it
  /// last: a row with no date cannot claim a place near the front of a rundown.
  public static func of(days: Int?) -> HomeWirePeriod {
    guard let d = days else { return .earlier }
    if d > 0 { return .ahead }
    if d == 0 { return .today }
    return d >= -6 ? .week : .earlier
  }

  public static func < (a: HomeWirePeriod, b: HomeWirePeriod) -> Bool { a.rawValue < b.rawValue }
}

/// **EVERY LEAGUE NOTE ON THE WIRE, AS ONE LINE.** D217 folded league notes to
/// one row per league per bucket and the audit (H-05) still found four of them
/// on one screen — three of which were the same two leagues at three periods.
/// A count is not news; it is a `GROUP BY` with a chevron. The wire now carries
/// **one** of these, in the quietest voice the system has, at its foot, and it
/// opens the board where the notes actually live.
public struct HomeWireNotes: Sendable, Equatable {
  /// Every league that contributed, sorted, first-seen order broken by name.
  public let leagueNames: [String]
  public let count: Int
  /// The board a tap opens — the newest note's league.
  public let leagueId: UUID?

  public init(leagueNames: [String], count: Int, leagueId: UUID?) {
    self.leagueNames = leagueNames; self.count = count; self.leagueId = leagueId
  }

  /// "Fellas & Who's the bitch? · 14 league notes". Past two leagues the names
  /// stop being an aid and become the wall again, so it counts them instead.
  public var line: String {
    let noun = "league note" + (count == 1 ? "" : "s")
    let names: String
    switch leagueNames.count {
    case 0: names = "Your leagues"
    case 1, 2: names = leagueNames.joined(separator: " & ")
    default: names = "\(leagueNames.count) leagues"
    }
    return "\(names) · \(count) \(noun)"
  }
}

public struct HomeWireRow: Identifiable {
  public enum Body {
    /// Weight 2 · a friend's round. With a photograph it is a full-bleed band;
    /// without one it is a 68pt slat, and **never a wash standing in for a
    /// picture** (§10.1).
    case round(HomeFeedRow, photoURL: URL?)
    /// Weight 4 · the season moment, on the pinned ceremony ground.
    case takeover(HomeDispatch.Item)
    /// **Weight 3 · A RANKED COMPETITION ITEM, AND IT IS NOT A QUIET LINE.**
    /// A clash that is open, a standing that has moved, a plan on the books:
    /// these are the things the ranker put above every board note, and the
    /// shipped build drew all three at `bodyS` `mut` with a 34pt date column —
    /// the same weight as "Fellas · 4 earlier league notes". They take the
    /// page's reading size in `ink`, and `stamp` is the item's own clock.
    case item(HomeDispatch.Item, stamp: String?)
    /// Weight 5 · one quiet line, with its date at the trailing edge.
    case line(marker: String?, text: String, door: HomeWireDoor?)
    /// The digest — "Since you were here…" — one line, in `ink`, at the head
    /// of the wire, because it is about the rows under it.
    case digest(HomeDigest)
    case occasion(Occasion)
  }
  public let id: String
  public let body: Body
  /// Which dateline this row files under. **`nil` files it ABOVE the first
  /// head** — the digest is a sentence about every group beneath it and does
  /// not belong inside one.
  public let period: HomeWirePeriod?
  /// The wire's own rhythm: a full-bleed band brings its own edge and needs no
  /// rule above it.
  public var leadsWithRule: Bool {
    if case .round(_, let url) = body { return url == nil }
    if case .takeover = body { return false }
    return true
  }
  public init(id: String, body: Body, period: HomeWirePeriod? = nil) {
    self.id = id; self.body = body; self.period = period
  }
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
  /// **ONE league-note line, at the foot of the wire** (D280, audit H-05).
  /// Never a row inside a group, never one per league, never one per period.
  public let notes: HomeWireNotes?
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

  /// **Does the wire run under datelines?** (D287.) True only on the branch
  /// that emits `COMING UP` / `TODAY` / `THIS WEEK` / `EARLIER` — every other
  /// state (the first-round rows, the redacted skeleton, a failed read, the
  /// wire's empty block, the roster empty) draws no head of its own and needs
  /// the block NAMED. Where a dateline opens the block, the block name is a
  /// second header for one thing and the quieter of the two, so it yields.
  ///
  /// It is decided here rather than in the view because it is the same set of
  /// branches `HomeView.wire` switches on, and a rule stated twice drifts.
  public var wireHasDatelines: Bool {
    guard !firstRound, !redacted, failed == nil, wireEmptyItem == nil, !wireEmpty else { return false }
    return rows.contains { $0.period != nil }
  }

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

    // DEF-3 · the two ways the wire knows a board post is about the golfer
    // reading it: the post's own `member_id` is one of theirs (authoritative —
    // `round_to_board()` writes `lm.id`), or the sentence opens with their own
    // name (the person-homed rail, which carries no member row at all).
    let mine = Set((me?.memberships ?? []).map(\.member_id))
    let myName = me?.profile?.display_name

    // **A ROUND IS ON THE FRONT PAGE ONCE** (D287). `HomeDigest`'s QUIET frame
    // resurfaces the best recent round so that an open never reveals nothing
    // (D27), and that file's own comment already rules that *the digest
    // yields* when something else on the page is telling the story. It was
    // handed `spent:` = the ranked deck's rounds and nobody handed it THE
    // WIRE's — so the owner's Home opened `Fri, Sep 4 — You posted 89 at UNM
    // Championship` above the first dateline and drew the same round three
    // rows below as the wire's 68pt slat, gross and all. It also put a date
    // back at the HEAD of a sentence, which is the leading column D285 deleted.
    //
    // Narrow on purpose: `.since` is a real summary of what changed and is
    // never dropped, and a quiet frame whose round the wire is NOT drawing
    // still renders, because that is the day the frame exists for.
    let wireRounds: Set<UUID> = Set(buckets.flatMap(\.items).compactMap {
      if case .round(let r, _) = $0 { return r.round_id }
      return nil
    })
    let framed: HomeDigest? = {
      guard let d = digest else { return nil }
      guard d.kind == .quiet, let id = d.roundId else { return d }
      return wireRounds.contains(id) ? nil : d
    }()

    var rows: [(sort: Int, row: HomeWireRow)] = []
    if let d = framed, !brandNew {
      // period nil · the digest is a sentence ABOUT the groups, so it sits
      // above the first dateline rather than inside one.
      rows.append((sort: -1, row: HomeWireRow(id: "digest", body: .digest(d))))
    }
    if let o = occasion, !brandNew {
      rows.append((sort: 0, row: HomeWireRow(id: "occasion-\(o.key)", body: .occasion(o))))
    }

    func filed(_ day: Int?) -> HomeWirePeriod { HomeWirePeriod.of(days: day) }

    for item in rest where !brandNew {
      let day = item.at.flatMap { CSDate.days(from: today, to: $0) }
      let per = filed(day)
      // **A ROW UNDER `TODAY` DOES NOT SAY `Today`.** The dateline said it,
      // and a stamp that repeats its own head is the date column all over again.
      let stamp = per == .today ? nil : HomeWireCopy.stamp(item.at, today: today, calendar: calendar)
      let body: HomeWireRow.Body = isCeremony(item)
        ? .takeover(item)
        : .item(item, stamp: stamp)
      rows.append((sort: distance(day),
                   row: HomeWireRow(id: "i-\(item.key)", body: body, period: per)))
    }

    // D297 · the wire's easer is the board's easer (`BoardText.easeCaps`), and
    // the names it can restore are the ones this wire already carries — the
    // golfers on its round rows and the viewer's own — so a shouted body reads
    // "Wes Tucker takes the month", never "Wes tucker takes the month".
    var names = BoardText.NameRegistry()
    names.learn(buckets.flatMap(\.items).map { item -> String? in
      if case .round(let r, _) = item { return r.golfer }
      return nil
    } + [myName])

    // The league notes, gathered across EVERY bucket. They do not enter the
    // wire as rows at all — see `notes` below.
    var noteNames: [String] = []
    var noteCount = 0
    var noteLeague: UUID?

    for bucket in buckets {
      for item in bucket.items {
        switch item {
        case .round(let r, let url):
          let day = (r.played_on).flatMap { CSDate.days(from: today, to: $0) }
          rows.append((sort: distance(day),
                       row: HomeWireRow(id: item.id, body: .round(r, photoURL: url), period: filed(day))))
        case .moment(let p, _):
          let iso = p.created_at.map { CSDate.iso($0, calendar: calendar) }
          let day = iso.flatMap { CSDate.days(from: today, to: $0) }
          // DEF-3 · the producer wrote it for a board; the wire is addressed
          // to one golfer, and this one may be its subject.
          let said = BoardText.easeCaps(p.body, names: names)
          let text: String
          if let mid = p.member_id {
            // The league rail. The member row is the authority, and it is the
            // reason two golfers who share a given name cannot be confused
            // for each other.
            text = mine.contains(mid) ? HomeWireCopy.viewerVoice(said, viewer: myName) : said
          } else {
            // D238's person-homed rail carries no member row at all. The only
            // name the rewrite can touch is the viewer's own, and a sentence
            // that names them is a sentence about them — subject or object.
            text = HomeWireCopy.viewerVoice(said, viewer: myName)
          }
          let per = filed(day)
          rows.append((sort: distance(day),
                       row: HomeWireRow(id: item.id,
                                        body: .line(marker: per == .today ? nil
                                                      : HomeWireCopy.dayMarker(iso, today: today, calendar: calendar),
                                                    text: text,
                                                    door: item.door.map(HomeWireDoor.feed)),
                                        period: per)))
        case .notes(let n):
          noteCount += n.count
          for name in n.leagueNames where !noteNames.contains(name) { noteNames.append(name) }
          if noteLeague == nil { noteLeague = n.leagueIds.first }
        }
      }
    }

    // Outward from today, and what is coming leads what has gone.
    var ordered = sayItOnce(rows.enumerated()
      .sorted { a, b in a.element.sort != b.element.sort ? a.element.sort < b.element.sort : a.offset < b.offset }
      .map(\.element.row))

    // With NO feed at all, the highest-ranked survivor is not a quiet line —
    // it is the wire's own empty block, which is the state `home-quiet` draws.
    var wireEmptyItem: HomeDispatch.Item?
    let feedIsEmpty = buckets.allSatisfy { $0.items.isEmpty }
    if feedIsEmpty, !brandNew, let first = rest.first {
      wireEmptyItem = first
      ordered.removeAll { $0.id == "i-\(first.key)" }
    }

    // The one league-note line. It is not a row: it sits under every group,
    // in the quietest voice the wire has, and it opens the board.
    let notes = (noteCount > 0 && !brandNew)
      ? HomeWireNotes(leagueNames: noteNames.sorted(), count: noteCount, leagueId: noteLeague)
      : nil

    // A wire carrying only league notes is NOT empty — it has news, folded.
    let empty = ordered.isEmpty && wireEmptyItem == nil && notes == nil
    let failed = (feedFailed && empty && !brandNew) ? EmptyRoot.failedRead() : nil

    var offered = Set<String>()
    if let l = ranked.lead, let k = floorKey(for: l.route) { offered.insert(k) }
    if let w = wireEmptyItem, let k = floorKey(for: w.route) { offered.insert(k) }

    return HomePage(
      lead: lead,
      rows: brandNew ? [] : ordered,
      wireEmptyItem: brandNew ? nil : wireEmptyItem,
      wireEmpty: !brandNew && empty && failed == nil && !loading,
      notes: notes,
      failed: failed,
      redacted: loading && ranked.lead == nil && empty,
      offered: offered,
      hasPrimary: brandNew,
      hasEmber: brandNew || (ranked.lead?.spine == .ember && !(ranked.lead?.action ?? "").isEmpty),
      firstRound: brandNew,
      starter: strip.slots.first { $0.fact == .myNumber }?.label == "STARTER",
      leadIsLive: ranked.lead?.spine == .ember)
  }

  /// **A RUNDOWN SAYS A DATE ONCE.** `Sun · Sun · Sun · Aug 31 · Aug 31` down
  /// one page is the repetition the owner read as a wall, and a dateline head
  /// alone does not remove it — three rows under `COMING UP` all still stamped
  /// `6 days` is the same column, indented. A row prints its stamp only when
  /// it differs from the row above it **inside its own group**, so the first
  /// of a run carries the date and the rest carry the sentence.
  static func sayItOnce(_ rows: [HomeWireRow]) -> [HomeWireRow] {
    var said: [HomeWirePeriod: String] = [:]
    return rows.map { row in
      guard let p = row.period else { return row }
      switch row.body {
      case .item(let i, let stamp):
        guard let stamp else { return row }
        if said[p] == stamp { return HomeWireRow(id: row.id, body: .item(i, stamp: nil), period: p) }
        said[p] = stamp
        return row
      case .line(let marker, let text, let door):
        guard let marker else { return row }
        if said[p] == marker {
          return HomeWireRow(id: row.id, body: .line(marker: nil, text: text, door: door), period: p)
        }
        said[p] = marker
        return row
      default:
        return row
      }
    }
  }

  /// How far a row is from today, in the wire's own order: today first, then
  /// tomorrow, then yesterday. An undated row sorts to the end, because a row
  /// with no date cannot claim a place in a rundown.
  static func distance(_ days: Int?) -> Int {
    guard let days else { return Int.max }
    return days >= 0 ? days * 2 : (-days * 2) + 1
  }
}
