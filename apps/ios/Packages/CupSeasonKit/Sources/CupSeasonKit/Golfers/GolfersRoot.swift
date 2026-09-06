// Cup Season — GOLFERS, the COMMUNITY destination (D222 / R-A, R-D; IA §10.1).
//
// R-D chose the name over Crew and Friends: T-08 rules *crew* a register word
// and never a list label, and the tab holds three tiers that "Friends"
// undersells — buddies, league mates, and people you have actually played with
// but have not added.
//
// This file owns the ORDER of the tab and the two roots it can land on. The
// rows themselves are the ones `PeopleScreen` already drew; promoting a screen
// to a tab is not a licence to rewrite what it says.
//
// L-32, both halves: the empty root ends in a next move, and a failed read is
// its own state with its own sentence.

import Foundation

public enum GolfersRoot {

  /// The tab's sections, in the order IA §10.1 sets them. A section with
  /// nothing in it does not render — the head is not the content.
  public enum Section: String, Sendable, CaseIterable {
    case requests, board, playingSoon, buddies, youPlayWith, leagueMates, invite

    /// The head, in the tab's own words. `REQUESTS · 2` gets its count from
    /// the screen; the head is the noun.
    public var head: String {
      switch self {
      case .requests:     "REQUESTS"
      case .board:        "THE BOARD"
      case .playingSoon:  "PLAYING SOON"
      case .buddies:      "YOUR BUDDIES"
      case .youPlayWith:  "YOU PLAY WITH"
      case .leagueMates:  "IN YOUR SEASONS"
      case .invite:       "SOMEBODY WHO ISN’T HERE"
      }
    }
  }

  /// The three tiers said once, at first contact, and nowhere else
  /// (`TERMINOLOGY.md` §1 row 7). The tab is the place the word is defined,
  /// because it is where a golfer first meets all three.
  public static let buddyDefinition =
    "A buddy is somebody who accepted you back. You see each other’s rounds, and either of you can pull the other into a season."

  /// What the tab shows when there is nobody in it. Same three-way split as
  /// Compete's, for the same reason.
  public enum State: Sendable, Equatable {
    case list
    case loading
    case failed(EmptyRoot)
    case empty(EmptyRoot)
  }

  /// `readFailed` wins. "No buddies yet" over a failed `my_friends` sends a
  /// golfer off to re-add the friends they already have, which is the exact
  /// harm L-32's second half names.
  public static func state(buddies: Int, requests: Int, loaded: Bool, readFailed: Bool) -> State {
    if readFailed { return .failed(EmptyRoot.failedRead()) }
    if !loaded { return .loading }
    // A pending request IS somebody in the tab, even at zero buddies — the
    // requests section is the head of the list and it has something to show.
    if buddies > 0 || requests > 0 { return .list }
    return .empty(empty())
  }

  /// LV-16 · ONE sentence for one act. Sending a buddy request was confirmed
  /// four ways across four new files — "Request sent" three times and "Asked to
  /// join their crew. They'll get the nudge." once, which also used *crew*,
  /// which T-08 rules a register word and never a list label. The ruled noun
  /// for the relationship is **buddy**, defined at first contact just above.
  public enum BuddyAsk {
    public static let sent = "Request sent"
    public static let accepted = "Golf buddies ✓"
    /// Both sides already asked, so the link closed it on the spot.
    public static let mutual = "You’re golf buddies now."
  }

  /// LV-05 · what a golfer's card is CALLED, in one place.
  ///
  /// "Tour Card" is retired by TERMINOLOGY §2.1 row 1 — in real golf it is a
  /// playing privilege, and it means nothing here. The card IS the person, so
  /// it takes the person's name. Every header, every title and every
  /// accessibility hint reads from this, so the name cannot drift back one
  /// surface at a time (§4 row 30 is the lint that says so).
  public enum CardName {
    /// "Galen’s card" — or, with no name in hand, a card that belongs to
    /// somebody rather than to nobody.
    public static func title(_ name: String?) -> String {
      guard let n = name?.trimmingCharacters(in: .whitespaces), !n.isEmpty else { return "A golfer’s card" }
      return "\(n)’s card"
    }
    /// The viewer's own.
    public static let mine = "Your card"
    /// The hint a face, a row or a name carries: what the tap OPENS.
    public static func hint(_ name: String? = nil) -> String {
      guard let n = name?.trimmingCharacters(in: .whitespaces), !n.isEmpty else { return "Opens their card" }
      return "Opens \(n)’s card"
    }
  }

  /// IA §10.1's empty root.
  ///
  /// **Two doors, not three.** The design's first door is "Find your friends →
  /// (contacts)". Contacts matching is **R-G / D251**, built in wave 8; a door
  /// that does not open is the one thing not permitted (L-32, L-44), so it is
  /// not offered here and lands with the mechanic that makes it real. What is
  /// offered is what works today: search, and a link that reaches somebody with
  /// no account at all (L-40).
  public static func empty() -> EmptyRoot {
    EmptyRoot(head: "No buddies yet.",
              fact: nil,
              sub: "Add the people you actually play with. They see your rounds, you see theirs, and either of you can pull the other into a season.",
              doors: [.findGolfers, .personLink])
  }
}
