// Cup Season — the board's shapes (audit 05 §1, §4).
//
// `posts` is the board. Five kinds; chat is the only one a client writes.
// Reactions are rows in `post_kudos` keyed (post_id, member_id, emoji);
// comments are `post_comments`, on ROUND posts only. The story card reads a
// `BoardRound` — the web's `window.roundCache` entry — built from `rounds` +
// `v_rounds_ranked` (season-scoped) + a signed photo URL.

import Foundation

/// The six curated reactions (index.html 4670–4676). Emoji stay emoji; the
/// label is the accessibility name (`RXLABEL`).
public enum CSReactions {
  public struct Reaction: Sendable, Hashable, Identifiable {
    public let emoji: String
    public let label: String
    public var id: String { emoji }
  }
  public static let all: [Reaction] = [
    Reaction(emoji: "🔥", label: "heater"),       // hot round, on a run
    Reaction(emoji: "🦅", label: "the eagle"),    // genuinely great, respect
    Reaction(emoji: "⛳", label: "dialed"),       // stuck it, clean golf
    Reaction(emoji: "🧊", label: "ice"),          // clutch, closed it out
    Reaction(emoji: "🐍", label: "snake"),        // playful jab, three-putt energy
    Reaction(emoji: "🚨", label: "sandbagger"),   // the friendly accusation
  ]
  /// The one-thumb quick chip (F11 3.1).
  public static let quick = "🔥"
  public static func label(_ emoji: String) -> String { all.first { $0.emoji == emoji }?.label ?? "" }
}

/// One reaction's state on one post: count, mine, who.
public struct ReactionState: Sendable, Equatable {
  public var n: Int
  public var me: Bool
  public var who: [String]
  public init(n: Int = 0, me: Bool = false, who: [String] = []) { self.n = n; self.me = me; self.who = who }

  /// `rxFlip` (4757): the optimistic half, and its revert.
  public mutating func flip(me name: String, on: Bool) {
    if on { me = true; n += 1; who.append(name) }
    else { me = false; n = max(0, n - 1); who.removeAll { $0 == name } }
  }
}

public struct BoardComment: Sendable, Equatable, Identifiable {
  public let id: UUID
  public let who: String
  public let text: String
  public init(id: UUID = UUID(), who: String, text: String) { self.id = id; self.who = who; self.text = text }
}

public enum BoardKind: String, Sendable { case chat, announce, round, moment, system }

/// One feed item — the web's `feed[]` entry (14396–14405).
public struct BoardItem: Sendable, Identifiable, Equatable {
  public let id: String              // post id, or a local key for echoes / the synthetic row
  public let postId: UUID?
  public let kind: BoardKind
  public let dateLabel: String       // "Wed · Aug 26" — the separator key (`d`)
  public let ts: Date?               // real instant for the digest's freshness check
  public let who: String             // memName(member_id)
  public let profileId: UUID?        // memPid — the founder tag, the Tour Card
  public let memberId: UUID?
  public let ci: Int                 // squad colour index 0…3 (memCi; 1 when unsquadded)
  public let text: String            // body
  public let roundId: UUID?
  public let liveRoundId: UUID?      // D92: a settlement row that opens the scorecard
  public var reactions: [String: ReactionState]
  public var comments: [BoardComment]
  public let isEcho: Bool            // an optimistic local row awaiting its real twin

  public init(id: String, postId: UUID?, kind: BoardKind, dateLabel: String, ts: Date?, who: String = "", profileId: UUID? = nil,
              memberId: UUID? = nil, ci: Int = 1, text: String, roundId: UUID? = nil, liveRoundId: UUID? = nil,
              reactions: [String: ReactionState] = [:], comments: [BoardComment] = [], isEcho: Bool = false) {
    self.id = id; self.postId = postId; self.kind = kind; self.dateLabel = dateLabel; self.ts = ts; self.who = who
    self.profileId = profileId; self.memberId = memberId; self.ci = ci; self.text = text; self.roundId = roundId
    self.liveRoundId = liveRoundId; self.reactions = reactions; self.comments = comments; self.isEcho = isEcho
  }

  /// Chat lines react but don't thread (`comments:false`, 5160). Moments and
  /// settlements are events, not conversations — they react, they don't thread.
  public var threads: Bool { kind == .round }
  /// Only a real post row carries reactions and a report affordance. D181: a
  /// moment and a settlement carry them too — they were 130 of 356 prod posts,
  /// every settlement card among them, with no way to say anything back. The
  /// Pro's announcement is the one deliberate exception: a notice, not a story.
  public var social: Bool { postId != nil && kind != .announce }
}

/// A member as the board sees them (loadLeagueData 14290–14316).
public struct BoardMember: Sendable, Identifiable, Equatable {
  public let id: UUID                // league_members.id
  public let profileId: UUID?
  public let name: String
  public let marker: String          // effective: league override → profile → saguaro
  public let role: String
  public let squadIndex: Int?        // position of their squad in the name-ordered list
  public var photoURL: URL?
  public init(id: UUID, profileId: UUID?, name: String, marker: String, role: String, squadIndex: Int?, photoURL: URL? = nil) {
    self.id = id; self.profileId = profileId; self.name = name; self.marker = marker; self.role = role
    self.squadIndex = squadIndex; self.photoURL = photoURL
  }
  /// `memCi`: squad position mod 4, else 1.
  public var ci: Int { squadIndex.map { $0 % 4 } ?? 1 }
}

/// The story card's facts — one `window.roundCache` entry (14426–14468).
public struct BoardRound: Sendable, Identifiable, Equatable {
  public let id: UUID
  public let profileId: UUID?
  public let gross: Int?
  public let differential: Double?
  public let courseLabel: String?
  public let playedOn: String?       // calendar date, as a String (CSDate)
  public let holesPlayed: Int?
  public let indexAtPost: Double?
  public let photoPath: String?
  public var photoURL: URL?
  public var pvi: Double?
  public var points: Double?
  public var monthRank: Int?
  public init(id: UUID, profileId: UUID?, gross: Int?, differential: Double? = nil, courseLabel: String?, playedOn: String?,
              holesPlayed: Int?, indexAtPost: Double? = nil, photoPath: String? = nil, photoURL: URL? = nil,
              pvi: Double? = nil, points: Double? = nil, monthRank: Int? = nil) {
    self.id = id; self.profileId = profileId; self.gross = gross; self.differential = differential; self.courseLabel = courseLabel
    self.playedOn = playedOn; self.holesPlayed = holesPlayed; self.indexAtPost = indexAtPost; self.photoPath = photoPath
    self.photoURL = photoURL; self.pvi = pvi; self.points = points; self.monthRank = monthRank
  }
}

/// The counting cap's stepper slot. D142: the ladder lives in one place —
/// `Bylaws.capVals` [2, 3, 4, 6, nil] — and the NUMBER is the truth; a slot
/// is only where the wizard's stepper sits. Prefer carrying `counting_cap`
/// itself (`BoardLogic.counting(monthRank:capN:)`) over a slot.
public enum CountingCap {
  /// `Bylaws.capIndex`: nil → unlimited (the top rung); an exact rung, else the nearest finite one.
  public static func index(_ countingCap: Int?) -> Int { Bylaws.capIndex(countingCap) }
  /// `capN` — nil means unlimited.
  public static func n(index: Int) -> Int? { Bylaws.capVals[max(0, min(Bylaws.capVals.count - 1, index))] }
}
