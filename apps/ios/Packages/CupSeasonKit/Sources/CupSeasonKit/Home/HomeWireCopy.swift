// Cup Season — the wire's own two sentences (IOS-046, `surfaces/home.md` §1.4).
//
// The wire runs at five weights and every one of them prints a producer's
// words. Two of those words did not have a producer, because the shipped feed
// card said them inside a view: **the round's own line** (weight 2, where the
// golfer's name is already on the face beside it and must not be said twice)
// and **the day marker** that leads a quiet row.
//
// Both are here so the desk prints the same sentence off the same payload,
// and so a test can argue with a clause instead of a screenshot.

import Foundation

public enum HomeWireCopy {

  /// `79 at Papago — a personal best.`
  ///
  /// **The name is NOT in it.** `HomeDigest.line` opens with "Galen set a
  /// personal best" because a digest has no face; a wire item at weight 2 is
  /// led by a 38pt `CSFace` and the golfer's name in `social` directly above,
  /// and repeating it in the sentence under its own name is the same fact
  /// twice inside 20pt.
  ///
  /// The band gloss is `CSBands`' verbatim — *"beat their playing HCP by
  /// 2.4"* — never a re-wording. The five bands and the gloss are a spec
  /// §2.2 contract with a preflight check behind it.
  public static func roundLine(_ r: HomeFeedRow) -> String {
    let course = r.course ?? "a round"
    guard let g = r.gross else {
      // No gross is not "0". A round with no number is a round that has not
      // been read, and the line says only what it knows (L-44).
      return "A round at \(course)."
    }
    if r.is_pr == true { return "\(g) at \(course) — a personal best." }
    if r.is_sub80 == true { return "\(g) at \(course) — broke 80 for the first time." }
    if r.is_first == true { return "\(g) at \(course) — a first round on the card." }
    if let p = r.pvi {
      let phrase = r.is_me == true ? CSBands.vsPhrase(p) : CSBands.theirs(CSBands.vsPhrase(p))
      return "\(g) at \(course) — \(phrase)."
    }
    return "\(g) at \(course)."
  }

  /// `Today` · `Mon` · `Aug 21` — the marker that leads a quiet row and
  /// credits a photograph.
  ///
  /// It is `mut` at `agateS` on the screen (**never `dim`**, which is 3.15 /
  /// 2.89 and may not carry a word): the marker takes its quietness from
  /// size, from column position and from the row's own rule.
  public static func dayMarker(_ iso: String?, today: String = CSDate.today(),
                               calendar: Calendar = .current) -> String? {
    guard let iso, !iso.isEmpty else { return nil }
    guard let days = CSDate.days(from: today, to: iso) else { return nil }
    if days == 0 { return "Today" }
    if abs(days) <= 6, let d = CSDate.local(iso, calendar: calendar) {
      let wd = calendar.component(.weekday, from: d)
      return LeagueDates.dow[max(0, min(6, wd - 1))]
    }
    return LeagueDates.monDay(iso, calendar: calendar)
  }

  /// **A NUMERAL RAIL HOLDS NUMERALS** (§16A.4), so the day comes out of the
  /// value and joins the label: `84 FRI · LAST` becomes `84` over `LAST · FRI`.
  ///
  /// All three blind reviewers filed `Mon` sitting in identical type beside
  /// `10.6`, `84` and `$75`; one wrote that "a weekday in identical type to
  /// three numbers reads as a rendering error". `MeStripCopy` composes the day
  /// into the value because the shipped strip drew one line per slot; this
  /// splits it back out for the rail, and it is a LAYOUT split — not a
  /// re-wording. Both halves are the producer's own words.
  public static func railCell(_ s: MeStripCopy.Slot) -> (value: String, label: String) {
    guard s.fact == .myLastRound, let sp = s.value.firstIndex(of: " ") else {
      return (s.value, s.label)
    }
    let figure = String(s.value[s.value.startIndex..<sp])
    let day = s.value[s.value.index(after: sp)...].trimmingCharacters(in: .whitespaces)
    guard !figure.isEmpty, !day.isEmpty, figure.contains(where: \.isNumber) else {
      return (s.value, s.label)
    }
    return (figure, "\(s.label) · \(day)")
  }

  /// `Of eight` — the lead chip's unit, under the rank and the movement.
  ///
  /// A field size is a **word** in a unit label and a **digit** in a figure:
  /// `OF EIGHT` sits under a 40pt numeral and reads as a phrase, where `OF 8`
  /// reads as a second number competing with the first. Past twenty the word
  /// is longer than the panel, so it goes back to digits.
  public static func chipUnit(of n: Int) -> String {
    let words = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
                 "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
                 "eighteen", "nineteen", "twenty"]
    return "Of \(n >= 1 && n < words.count ? words[n] : String(n))"
  }

  /// `Galen's round · Sun` — the credit on a photograph. A golfer's picture is
  /// credited, in agate, always: it is the difference between an image the
  /// product borrowed and an image somebody took.
  public static func photoCredit(_ r: HomeFeedRow, today: String = CSDate.today(),
                                 calendar: Calendar = .current) -> String {
    let who = r.is_me == true ? "Your" : possessive(r.golfer ?? "A golfer")
    guard let day = dayMarker(r.played_on, today: today, calendar: calendar) else { return "\(who) round" }
    return "\(who) round · \(day)"
  }

  /// `Galen` → `Galen’s`, `Chris` → `Chris’`. The typographic apostrophe, and
  /// the given name only — the feed already carries the full name on the face.
  static func possessive(_ name: String) -> String {
    let first = name.split(separator: " ").first.map(String.init) ?? name
    return first.hasSuffix("s") || first.hasSuffix("S") ? "\(first)\u{2019}" : "\(first)\u{2019}s"
  }
}
