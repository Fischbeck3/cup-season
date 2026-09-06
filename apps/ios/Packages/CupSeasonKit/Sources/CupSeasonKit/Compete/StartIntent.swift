// Cup Season — the intent sheet (D225 / O-04; IA §6.2; CORE_FLOWS §6.1).
//
// Three object doors — Join a league · Start a league · Start an event — and an
// event picker listing schema objects. An organiser could not say what they
// wanted; they had to already know which object expressed it. Six of six
// `setup` leagues in prod are a founder alone.
//
// THE SHEET IS A PRODUCER, NOT A SCREEN. The five sentences, their glosses, the
// modifier's position and the code door are decided here, once, for both
// clients — so "five sentences, zero object nouns" is a table test over the
// rendered strings rather than a promise about a VStack. `csStartIntent` is the
// web's twin and asserts the same literals (D234).
//
// THE FIFTH IS A MODIFIER, NOT A PEER. Money is a choice ON a competition and
// never a competition (L-11, D46 — two of two organisers in the audit met a $75
// stake they never chose), so it renders below a hairline, as a footer line.
//
// R-J · THE FOURTH INTENT IS "Go head to head". `I want to beat one guy` is
// retired everywhere, on both clients: it was the only one of the four that
// began "I want to", it read as cringe, and it was the one sentence not
// addressed to every golfer in a mixed league. The replacement is four verb
// phrases in one register — and "head to head" is the product's OWN noun for
// the record between two golfers (`head_to_head`, the page, the rivalry line),
// so the door and the thing it builds finally share a word. The retired
// phrasing is preflight 27 §4.34 now; it cannot come back quietly.
//
// Nothing is minted by opening this sheet.

import Foundation

public enum StartIntent: String, Sendable, Equatable, CaseIterable, Identifiable {
  /// A round with whoever is around — live now, or a day this week.
  case playWithFriends
  /// Weeks of golf that add up to a table.
  case runASeason
  /// One day, and a name for it.
  case thisWeekend
  /// The two of you, at a length picked in one more tap (R-F). The door and
  /// the record it builds share a word: `head_to_head` is already this
  /// product's noun for what two golfers have between them (R-J).
  case headToHead

  public var id: String { rawValue }

  /// The four PEERS, in the order the sheet draws them.
  public static let peers: [StartIntent] = [.playWithFriends, .runASeason, .thisWeekend, .headToHead]

  /// The control's own words.
  public var line: String {
    switch self {
    case .playWithFriends: return "Play with my friends"
    case .runASeason:      return "Run a season"
    case .thisWeekend:     return "We're playing this weekend"
    case .headToHead:      return "Go head to head"
    }
  }

  /// The half-sentence under it. Never names the object it resolves to.
  public var gloss: String {
    switch self {
    case .playWithFriends: return "a round with whoever is around"
    case .runASeason:      return "weeks of golf that add up to a table"
    // L-32 · "a name for it", never "one trophy": a weekend mints no trophy
    // (D240), and a door may not sell what the object does not open.
    case .thisWeekend:     return "one day, and a name for it"
    case .headToHead:      return "the two of you, at whatever length you like"
    }
  }

  /// What the sheet says at its head.
  public static let title = "What do you want to do?"

  /// The MODIFIER, below the hairline. It attaches money to a competition that
  /// already exists, or to the one being created; it never creates one.
  public static let modifierLine = "Put money on it"
  public static let modifierGloss = "add a pot to any of the above"

  /// The footer door. T-13 owns the noun: a code, not "8 digits" (L-06 owns
  /// that phrase for the email OTP, met four minutes earlier in the same flow).
  public static let codeDoor = "I have a code"

  // MARK: - the object-noun ban, as a value

  /// The engine's own vocabulary (`TERMINOLOGY.md` §3.1), plus this design's
  /// own words (§3.2). A door may name what the golfer wants; it may never name
  /// the row the engine will write. Asserted over every string above.
  ///
  /// `season` is deliberately NOT here: T-11/§2.3 rule it the GOLFER's word for
  /// the thing you start, join, run and win. `league` is here, because it is the
  /// container's name and never a button.
  public static let bannedNouns: Set<String> = [
    "league", "event", "ryder", "major", "bracket", "duel", "session",
    "commissioner", "structure", "preset", "bylaws", "lock", "wizard",
    "moment", "callout", "forfeit", "squad", "squads", "draft", "roster",
    "clubhouse", "dispatch", "tier", "pvi", "differential", "allowance",
  ]

  /// Every string the sheet renders, in draw order — the surface a lint walks.
  public static var everyString: [String] {
    peers.flatMap { [$0.line, $0.gloss] } + [title, modifierLine, modifierGloss, codeDoor]
  }

  /// The banned nouns a string actually contains, matched on word boundaries so
  /// "seasonal" and "unlocked" are not false hits.
  public static func objectNouns(in s: String) -> [String] {
    let words = s.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
    return words.filter { bannedNouns.contains($0) }
  }

  // MARK: - what each one resolves to

  /// The engine object behind a door. The golfer never meets these names; this
  /// is the mapping a caller switches on, and it is the whole of §6.2's table.
  public enum Resolution: String, Sendable, Equatable {
    /// A live round now, or a planned round — the fork is the one question the
    /// app genuinely cannot infer (CORE_FLOWS §6.3).
    case whenFork
    /// The wizard's three questions, then one publish.
    case season
    /// A plan with a name and a game (D240).
    case weekend
    /// A golfer, then the length, and all three lengths are always offered (R-F).
    case pickAGolfer
    /// What money is already on. Never creates a competition.
    case whatsItOn
  }

  public var resolution: Resolution {
    switch self {
    case .playWithFriends: return .whenFork
    case .runASeason:      return .season
    case .thisWeekend:     return .weekend
    case .headToHead:      return .pickAGolfer
    }
  }

  // MARK: - intent 1's fork (CORE_FLOWS §6.3)

  public enum WhenFork: String, Sendable, Equatable, CaseIterable, Identifiable {
    case rightNow, aDayThisWeek
    public var id: String { rawValue }
    public var line: String { self == .rightNow ? "Right now" : "A day this week" }
    public var gloss: String { self == .rightNow ? "score it live, hole by hole" : "put it on the schedule" }
    public static let title = "When are you playing?"
  }

  // MARK: - intent 5's list (CORE_FLOWS §6.4)

  /// "What's the money on?" — a list of what is actually live for me. The empty
  /// case is L-32's: one door, and a sentence that says why.
  public enum Money {
    public static let title = "What's the money on?"
    public static let somethingNew = "Something new"
    public static let emptyLine = "Nothing to put money on yet. Start something first."
    /// A season already under way. The rules froze at the first tee (L-12), and
    /// saying so is more honest than hiding the door.
    public static func frozen(_ name: String, firstTee: String) -> String {
      "\(name) started on \(firstTee) and the rules froze at the first tee. You can put a forfeit on it."
    }
  }
}
