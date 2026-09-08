// Cup Season — the card's own strings, produced ONCE for both clients
// (`surfaces/player-card.md` §9, `UI_SYSTEM` §6.5).
//
// These are CONSOLIDATIONS, not new facts. Every value below is already on the
// payload; what was wrong is that the same line was built twice, differently,
// so a golfer's identity line changed with the door they came through — which
// is half of GP-16 ("one object, two chromes, two aspect ratios, two meta
// strings"). One string, one place.

import Foundation

public enum CredentialCopy {

  /// `@galenm · Mesa, AZ · Papago` — handle, city, home course.
  ///
  /// **`est. Jul 2026` is NOT in it** (`UI_SYSTEM` §6.5 row 5, YRS-21): the
  /// founding fact is already the gold slot, and the third telling is the
  /// duplication GP-17 names. `TourCard.established(_:)` keeps its own call
  /// sites in Settings and is not retired.
  ///
  /// Each clause is dropped rather than guessed, and the string is uppercased
  /// **by the role** — never by `.uppercased()` (LINT-14).
  public static func identity(handle: String?, city: String?, homeCourse: String?) -> String {
    [handle.flatMap { $0.isEmpty ? nil : "@\($0)" },
     city?.isEmpty == false ? city : nil,
     homeCourse?.isEmpty == false ? RoundCopy.course(homeCourse!) : nil]
      .compactMap { $0 }
      .joined(separator: " · ")
  }

  public static func identity(_ p: TourCard.Profile) -> String {
    identity(handle: p.handle, city: p.city, homeCourse: p.homeCourse)
  }

  /// The folio's left half: `Cup Season · The Lone Tree`. The marker's NAME is
  /// a fact the product owns; the serial is not (see `CSFolio.serial`).
  ///
  /// It takes the RESOLVED name rather than the key, because the marker table
  /// is generated into `CSDesign` and the Kit sits below it — the producer
  /// stays in the Kit, where both clients read it, and the caller does the one
  /// lookup it already has in hand.
  public static func club(markerName: String?) -> String {
    guard let n = markerName, !n.isEmpty else { return "Cup Season" }
    return "Cup Season · " + n
  }

  /// **The status sentence**, with the gross marked as a figure run — braces,
  /// never a regex over prose. `nil` when there is no round: the line is not
  /// drawn, and it is certainly not a dash (L-44).
  ///
  ///     Posted {74} at Papago on Sunday.
  ///
  /// `establishing` adds the second clause the blind review asked for, which
  /// moves the denominator out of two competing rails and into English:
  /// *"Posted 79 at Papago on Aug 30. One more round sets her number."*
  public static func status(gross: Int?, course: String?, playedOn: String?,
                            roundsToEstablish: Int? = nil, isMe: Bool) -> String? {
    guard let gross else { return nil }
    var s = "Posted {\(gross)}"
    if let c = course, !c.isEmpty { s += " at \(RoundCopy.course(c))" }
    if let on = playedOn {
      let d = RivalryCopy.monthDaySpoken(on)
      if !d.isEmpty { s += " on \(d)" }
    }
    s += "."
    if let n = roundsToEstablish, n > 0 {
      s += n == 1 ? " One more round sets \(isMe ? "your" : "their") number."
                  : " \(spelled(n)) more rounds set \(isMe ? "your" : "their") number."
    }
    return s
  }

  /// The live form: `ink` with a 7pt `brand` dot leading.
  public static func live(course: String?, thru: Int?) -> String {
    var s = "Playing"
    if let c = course, !c.isEmpty { s += " \(RoundCopy.course(c))" }
    s += " right now"
    if let t = thru, t > 0 { s += " — thru \(t)" }
    return s + "."
  }

  /// Your own card's one line. It is not an action and it is not a boast: it
  /// is what the object is for.
  public static let mine = "This is how your buddies see you."

  /// §6.2 / §13.1 · **the first-card headline is a fact about the world, never
  /// the golfer's omission.** The test: could the golfer have prevented this
  /// sentence by doing something? If yes, rewrite it — which is why this is not
  /// `TourCard.noRoundsYet`, whose "hasn't posted a round yet" fails that test
  /// exactly. `noRoundsYet` survives as the block's second line, where it is a
  /// true statement of the state rather than the headline's verdict on it.
  public static func firstCard(name: String?, since: Date?, calendar: Calendar = .current) -> String {
    let who = (name?.isEmpty == false) ? name!.split(separator: " ").first.map(String.init) ?? name! : "This golfer"
    guard let since else { return "\(who) is here. It starts with a first round." }
    let f = DateFormatter()
    f.calendar = calendar; f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "MMMM"
    return "\(who) joined in \(f.string(from: since)). It starts with a first round."
  }

  /// The FORM head's count — `LAST FIVE`, or `TWO OF FIVE` when the golfer has
  /// fewer. **A posted round is a *round*; "card" is reserved for the person
  /// and for the scorecard** (T-01), which is why this never says "2 of 5
  /// cards". Spelled rather than numeric so the establishing denominator does
  /// not read as a second rail against the form row's own figures.
  public static func formCount(_ n: Int) -> String {
    n >= 5 ? "Last five" : "\(spelled(n)) of five"
  }

  /// The COURSES head's count: `11 kept`.
  public static func coursesCount(_ n: Int) -> String { "\(n) kept" }

  /// A course row's sub-line: `PHOENIX · HIS HOME COURSE` /
  /// `SCOTTSDALE · LAST PLAYED SEP 9`. Each clause dropped rather than guessed.
  public static func courseSub(city: String?, isHome: Bool, lastPlayed: String?, isMe: Bool) -> String {
    var parts: [String] = []
    if let c = city, !c.isEmpty { parts.append(c) }
    if isHome {
      parts.append(isMe ? "your home course" : "their home course")
    } else if let on = lastPlayed {
      let d = RivalryCopy.monthDaySpoken(on)
      if !d.isEmpty { parts.append("last played \(d)") }
    }
    return parts.joined(separator: " · ")
  }

  /// D150's overlap sentence — the reason two golfers start talking, fetched
  /// by `tour_card` since D150 and thrown away by the phone ever since.
  public static func overlap(_ names: [String]) -> String? {
    let n = names.filter { !$0.isEmpty }.map(RoundCopy.course)
    switch n.count {
    case 0: return nil
    case 1: return "You’ve both played \(n[0])."
    case 2: return "You’ve both played \(n[0]) and \(n[1])."
    default:
      return "You’ve both played \(n.prefix(2).joined(separator: ", ")) and \(n.count - 2) more."
    }
  }

  /// `1` → `1ST`. The one ordinal form in the product; `CSOrdinal` draws it.
  static func spelled(_ n: Int) -> String {
    let w = ["zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]
    return n > 0 && n < w.count ? w[n] : String(n)
  }
}
