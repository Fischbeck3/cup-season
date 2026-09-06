// Cup Season — WHAT'S IN THE BAG (D262, IOS-042, R-O).
//
// Fourteen clubs, each of them free text in the golfer's own words, ordered
// driver → putter, plus the ball — and beside them THE SIDELINE, the clubs
// they own that swap in. The sideline is the differentiated half: most bag
// features are a static fourteen, and a 3-iron that replaces the 5-wood
// *sometimes* is what makes "is Galen bringing the new driver?" a question
// with an answer.
//
// THERE IS NO EQUIPMENT DATABASE, and that is a written refusal (R-O, D250
// sense): no brand, model, loft or shaft table, no third-party catalogue.
// `label` is a sentence the golfer types. `slot` is one word the golfer types
// — "Driver", "3-wood" — and it exists only because the canon's own sentence
// ("Galen put a new driver in the bag") is not sayable without it; every
// producer here degrades to "a new club" when it is blank.
//
// THE LINE WORTH BUILDING CAREFULLY. A bag is a state over time and rounds are
// already timestamped, so with no shot tracking whatsoever the card can say
// "Since the new driver went in: four rounds, two beat your playing HCP." The
// arithmetic is the SERVER's (`bag_of`), because the count is against the
// allowance lens `v_rounds_ranked` and a second implementation would drift;
// this file only says it. R-M's noun, and the boundary is the engine's own
// (`CSBands.bandName` beats at pvi >= 1), so the count can never disagree with
// the chip on a round it counts.

import Foundation

public struct Bag: Sendable, Equatable {

  /// One club, or the ball. `addedOn` / `removedOn` are calendar dates as
  /// Strings and never go through an ISO parser (L-07).
  public struct Item: Sendable, Equatable, Identifiable, Hashable {
    /// The server's id — nil for a row the golfer has just typed. It is NOT
    /// the `Identifiable` id: two brand-new rows would then share one (nil)
    /// and a `ForEach` over them would bind both editors to one field.
    public let serverId: UUID?
    public var slot: String?
    public var label: String
    public var addedOn: String?
    public var removedOn: String?
    /// The row's identity for the editor, stable across a save that mints a
    /// server id.
    public let localId: UUID
    public var id: UUID { localId }

    public init(serverId: UUID? = nil, slot: String? = nil, label: String,
                addedOn: String? = nil, removedOn: String? = nil, localId: UUID = UUID()) {
      self.serverId = serverId; self.slot = slot; self.label = label
      self.addedOn = addedOn; self.removedOn = removedOn; self.localId = localId
    }

    /// "DRIVER" — the slot as a label, empty when the golfer left it blank.
    public var slotLabel: String { (slot ?? "").trimmingCharacters(in: .whitespaces).uppercased() }
    /// What the row reads when there is one line for it: "Driver · TSR3 9°".
    public var line: String {
      let s = (slot ?? "").trimmingCharacters(in: .whitespaces)
      return s.isEmpty ? label : "\(s) · \(label)"
    }
  }

  /// The server's answer to "how have the rounds gone since the newest club
  /// went in". `beat` is nil — never zero — when no season has scored a single
  /// one of them: "four rounds" is still true and there is no claim about the
  /// playing HCP available to make (L-44).
  public struct Since: Sendable, Equatable {
    public let slot: String?
    public let label: String
    public let addedOn: String
    public let rounds: Int
    public let beat: Int?
    public init(slot: String?, label: String, addedOn: String, rounds: Int, beat: Int?) {
      self.slot = slot; self.label = label; self.addedOn = addedOn; self.rounds = rounds; self.beat = beat
    }
  }

  public let visible: Bool
  public let isMe: Bool
  public let clubs: [Item]
  public let sideline: [Item]
  public let ball: Item?
  public let since: Since?

  public init(visible: Bool, isMe: Bool, clubs: [Item] = [], sideline: [Item] = [],
              ball: Item? = nil, since: Since? = nil) {
    self.visible = visible; self.isMe = isMe; self.clubs = clubs
    self.sideline = sideline; self.ball = ball; self.since = since
  }

  /// Nothing has been filled in. A bag like this is not drawn on somebody
  /// else's page at all — an empty section is a sentence about a person that
  /// the person did not write (L-44).
  public var isEmpty: Bool { clubs.isEmpty && sideline.isEmpty && ball == nil }

  public static func parse(_ json: JSONValue) -> Bag {
    guard json["visible"]?.bool == true else {
      return Bag(visible: false, isMe: json["is_me"]?.bool ?? false)
    }
    let item: (JSONValue) -> Item? = { j in
      guard let label = j["label"]?.string, !label.isEmpty else { return nil }
      return Item(serverId: j["id"]?.string.flatMap(UUID.init), slot: j["slot"]?.string, label: label,
                  addedOn: j["added_on"]?.string, removedOn: j["removed_on"]?.string)
    }
    var since: Since? = nil
    if let s = json["since"], case .object = s,
       let label = s["label"]?.string, let on = s["added_on"]?.string, let n = s["rounds"]?.int, n > 0 {
      since = Since(slot: s["slot"]?.string, label: label, addedOn: on, rounds: n, beat: s["beat"]?.int)
    }
    return Bag(visible: true,
               isMe: json["is_me"]?.bool ?? false,
               clubs: (json["clubs"]?.array ?? []).compactMap(item),
               sideline: (json["sideline"]?.array ?? []).compactMap(item),
               ball: json["ball"].flatMap(item),
               since: since)
  }
}

// MARK: - the words

public enum BagCopy {
  /// R-O · fourteen. The server refuses a fifteenth; this is what the screen
  /// says before it gets there.
  public static let cap = 14

  public static let yours = "Your bag"
  public static let inTheBag = "In the bag"
  public static let sideline = "The sideline"
  public static let ballHead = "The ball"
  public static let sidelineWhat = "Clubs you own that swap in."
  public static let full = "That is fourteen — the bag is full. Move one to the sideline first."
  public static let noneYet = "Nothing in it yet"
  public static let addClub = "Add a club"
  public static let slotPlaceholder = "Driver"
  public static let labelPlaceholder = "TSR3 9° · Ventus Blue"
  public static let ballPlaceholder = "Pro V1"
  public static let saved = "Bag saved"
  /// What the door on You says when the bag is empty. It says what a bag IS
  /// here, because the golfer has never seen one.
  public static let emptySub = "Fourteen clubs, in your own words"

  /// The You row's sub: "13 clubs · Pro V1", "13 clubs · 2 on the sideline".
  public static func summary(_ bag: Bag) -> String {
    guard !bag.isEmpty else { return noneYet }
    var bits: [String] = []
    if !bag.clubs.isEmpty { bits.append("\(bag.clubs.count) club\(bag.clubs.count == 1 ? "" : "s")") }
    if !bag.sideline.isEmpty { bits.append("\(bag.sideline.count) on the sideline") }
    if let b = bag.ball { bits.append(b.label) }
    return bits.joined(separator: " · ")
  }

  /// two → "two". Small counts read as words in a sentence and as digits in a
  /// figure; this is the sentence.
  public static func spelled(_ n: Int) -> String {
    switch n {
    case 1: "one"; case 2: "two"; case 3: "three"; case 4: "four"; case 5: "five"
    case 6: "six"; case 7: "seven"; case 8: "eight"; case 9: "nine"; case 10: "ten"
    default: String(n)
    }
  }

  /// "driver" out of "Driver"; "TSR3" left exactly as it is, because an
  /// all-caps word is an acronym and lower-casing it destroys it (the R-M
  /// lesson: two producers shipped "playing hcp"). Blank → "club".
  /// The SQL twin is `public.bag_word`.
  public static func word(_ slot: String?) -> String {
    let s = (slot ?? "").trimmingCharacters(in: .whitespaces)
    if s.isEmpty { return "club" }
    if s == s.uppercased() { return s }
    return s.lowercased()
  }

  /// R-O's own line, and the reason the dates are modelled at all.
  ///
  ///   "Since the new driver went in: four rounds, two beat your playing HCP."
  ///
  /// Every clause is dropped rather than guessed: no `beat` figure means the
  /// sentence stops after the rounds. `isMe: false` turns the possessive over
  /// through the one producer that does it (`CSBands.theirs`).
  public static func sinceLine(_ s: Bag.Since, isMe: Bool = true) -> String {
    let rounds = "\(spelled(s.rounds)) round\(s.rounds == 1 ? "" : "s")"
    var line = "Since the new \(word(s.slot)) went in: \(rounds)"
    if let b = s.beat {
      line += b == 0 ? ", none of them beat your playing HCP" : ", \(spelled(b)) beat your playing HCP"
    }
    line += "."
    return isMe ? line : CSBands.theirs(line)
  }

  /// The section head on somebody else's page. Never "Galen's bag" beside a
  /// name that is already at the top of the page (one fact, one place).
  public static func head(isMe: Bool) -> String { isMe ? yours : inTheBag }
}
