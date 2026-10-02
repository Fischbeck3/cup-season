// Cup Season — the synthetic cast: what the invented world's golfers, courses,
// leagues, squads and events are CALLED.
//
// Two casts, one world. Ids, scores, points, dates and every shape a screen
// decodes are the same for both; only the names differ.
//
//   fixture · the default, and the one every unit and UI test pins. It reads as
//             test data on purpose ("Avery Fixture", "North Grove (fixture)",
//             "Team Stub"): nobody can mistake it for a real person or place.
//   store   · `-cs_dev_cast store`, for the App Store screenshots only. Apple's
//             guideline 2.1 asks that placeholder text be scrubbed before
//             submission, so a store page cannot show "Team Stub" or
//             "Fixtureville". Every name here is invented and reads as natural.
//
// ONE launch argument selects the cast and nothing else does. No argument, or
// any value but `store`, is `fixture`: a launch that does not ask for the store
// cast behaves exactly as it did before this file existed.
//
// RULES FOR THE STORE CAST (`SyntheticCastTests` holds the checkable ones)
//   · no real person: no tour pro, no celebrity, nobody from the pilot crew;
//   · no real course (and none of the Phoenix-area ones), league or brand;
//   · none of: fixture, placeholder, stub, sample, test, mock, dummy, faux,
//     lorem, example, QA, TBD, TODO;
//   · no "Ryder" or "Masters" in an event's own name;
//   · the SHAPE of the fixture cast: twelve golfers beside the viewer, three
//     courses, two leagues, three squads, one long name for the layout.
// Ids stay fixture ids in both casts (`fid`, the `fixture-…` course keys): they
// are never drawn. The email stays `@example.invalid`.
//
// The whole file is DEBUG-only, like the folder it sits in.

#if DEBUG
import Foundation

struct SynthCast: Sendable {
  struct Golfer: Sendable { let name: String; let handle: String; let city: String }
  struct Course: Sendable { let name: String; let city: String }
  struct League: Sendable { let name: String; let code: String }
  struct Bag: Sendable {
    /// One label per club, in the order `SyntheticWorld.bag` slots them (driver first).
    let clubs: [String]
    let sidelinedDriver: String
    let ball: String
  }

  /// "fixture" | "store".
  let id: String
  /// The viewer's name under `-cs_synth_long` (the layout probe).
  let viewerLong: String
  /// The viewer first (person 1), then persons 2…12.
  let golfers: [Golfer]
  /// The three courses, in `SyntheticWorld.courses` order.
  let courses: [Course]
  /// The solo league (Blake runs it) and the squads league (the viewer is its Pro).
  let cupLeague: League
  let squadsLeague: League
  /// The squads league's three sides, in `squadNames` order. The viewer plays for
  /// the second.
  let squads: [String]
  /// The live and the finished Ryder's two teams, slot 0 (the viewer captains it) and 1.
  let ryderTeams: [String]
  /// `-cs_synth_clinch`'s two squads.
  let clinchSquads: [String]
  /// The league the viewer is invited to, and the code its link carries.
  let inviteLeague: League
  /// The name the viewer and Blake gave their rivalry.
  let rivalry: String
  /// The live Ryder, the finished one, and the Major.
  let liveRyder: String
  let finishedRyder: String
  let major: String
  /// The two hardware rows on the record (a Major and a Ryder won earlier).
  let majorTrophy: String
  let ryderTrophy: String
  let bag: Bag
  /// The live round's golfer with no account, by first name.
  let guest: String

  /// Person `n`'s (1 = the viewer) first name.
  func first(_ n: Int) -> String {
    let name = golfers[n - 1].name
    return String(name.split(separator: " ").first ?? Substring(name))
  }

  // MARK: which cast

  /// The cast THIS launch wears.
  static var current: SynthCast { select(ProcessInfo.processInfo.arguments) }

  /// `-cs_dev_cast store` is the store cast. Anything else — no argument, no
  /// value, an unknown value — is the fixture cast.
  static func select(_ arguments: [String]) -> SynthCast {
    guard let i = arguments.firstIndex(of: "-cs_dev_cast"), i + 1 < arguments.count else { return .fixture }
    return arguments[i + 1] == "store" ? .store : .fixture
  }

  /// Every string the cast holds, however deeply nested. The tests read this, so
  /// a field added later is checked without anybody remembering to list it.
  var strings: [String] {
    func walk(_ value: Any) -> [String] {
      if let s = value as? String { return [s] }
      return Mirror(reflecting: value).children.flatMap { walk($0.value) }
    }
    return walk(self)
  }

  // MARK: the fixture cast (the default — do not edit: the tests pin it)

  static let fixture = SynthCast(
    id: "fixture",
    viewerLong: "Avery Fixture-Montgomery Hollingsworth",
    golfers: [
      Golfer(name: "Avery Fixture", handle: "fixture_avery", city: "Fixtureville"),
      Golfer(name: "Blake Sample", handle: "fixture_blake", city: "Fixtureville"),
      Golfer(name: "Casey Placeholder", handle: "fixture_casey", city: "Sampleton"),
      Golfer(name: "Devon Testcase", handle: "fixture_devon", city: "Fixtureville"),
      Golfer(name: "Emerson Mockridge", handle: "fixture_emerson", city: "Sampleton"),
      Golfer(name: "Finley Stub", handle: "fixture_finley", city: "Fixtureville"),
      Golfer(name: "Gray Dummyton", handle: "fixture_gray", city: "Mockport"),
      Golfer(name: "Harper Fauxley", handle: "fixture_harper", city: "Mockport"),
      Golfer(name: "Maximilian Placeholder-Worthington", handle: "fixture_maximilian_long", city: "Fixtureville"),
      Golfer(name: "Quinn Samplewood", handle: "fixture_quinn", city: "Sampleton"),
      Golfer(name: "Rowan Mockingham", handle: "fixture_rowan", city: "Mockport"),
      Golfer(name: "Sage Exampleton", handle: "fixture_sage", city: "Fixtureville"),
    ],
    courses: [
      Course(name: "North Grove (fixture)", city: "Fixtureville"),
      Course(name: "Sample Links (fixture)", city: "Sampleton"),
      Course(name: "Placeholder Pines (fixture)", city: "Mockport"),
    ],
    cupLeague: League(name: "Fixture Cup League", code: "FIXCUP"),
    squadsLeague: League(name: "Placeholder Squads League", code: "FIXSQD"),
    squads: ["Team Placeholder", "Team Stub", "Team Sample"],
    ryderTeams: ["Team Placeholder", "Team Stub"],
    clinchSquads: ["Fixture Javelinas", "Fixture Wrens"],
    inviteLeague: League(name: "Fixture Friday League", code: "FIXTURE24"),
    rivalry: "The Grove Grudge (fixture)",
    liveRyder: "Fixture Invitational",
    finishedRyder: "Fixture Autumn Cup",
    major: "The Fixture Jug",
    majorTrophy: "The Sample Invitational (fixture)",
    ryderTrophy: "Spring Ryder (fixture)",
    bag: Bag(clubs: ["Fixture 460 driver, 10.5 deg", "Sample 3-wood, 15 deg", "Placeholder hybrid, 22 deg",
                     "Sample cavity 5", "Sample cavity 7", "Sample cavity 9", "Sample cavity PW",
                     "Fixture wedge 54", "Sample blade, 34 in"],
             sidelinedDriver: "Old fixture driver, 9 deg", ball: "Fixture Tour X (sample)"),
    guest: "Quinn")

  // MARK: the store cast (`-cs_dev_cast store`)

  /// An invented Arizona friend group: Palo Blanco, Mesquite Wells and Sundown
  /// Wash are the three towns; the leagues and events are what friends call such
  /// things. First names are the fixture cast's own, so a sentence that names
  /// "Blake" reads the same in both.
  ///
  /// THE SQUADS ARE NAMED FOR THEIR CAPTAINS ("Team Avery": the viewer captains
  /// the second, Finley the first, Blake the third), and the Ryder's two teams for
  /// theirs (the viewer and Emerson). A pun here is likely a name somebody has
  /// already printed on a shirt: two golf-pun names were tried for the squads and
  /// leagues and dropped, one a golf apparel brand and one a registered golf mark.
  ///
  /// TWO LENGTHS ARE ON PURPOSE. The squads league and the rivalry are long
  /// enough to wrap to two lines in a page's head, as "Placeholder Squads League"
  /// and "The Grove Grudge (fixture)" did. A name that fits on one line moves the
  /// page up a line, and the frame then shows a slice of the next row (a third
  /// squad on the ceremony, a Share button on the rivalry) cut off by the tab bar.
  static let store = SynthCast(
    id: "store",
    viewerLong: "Avery Linwood-Montgomery Hollingsworth",
    golfers: [
      Golfer(name: "Avery Linwood", handle: "averylinwood", city: "Palo Blanco"),
      Golfer(name: "Blake Hartwell", handle: "blakehartwell", city: "Palo Blanco"),
      Golfer(name: "Casey Moreno", handle: "caseymoreno", city: "Mesquite Wells"),
      Golfer(name: "Devon Okafor", handle: "devonokafor", city: "Palo Blanco"),
      Golfer(name: "Emerson Pryce", handle: "emersonpryce", city: "Mesquite Wells"),
      Golfer(name: "Finley Strand", handle: "finleystrand", city: "Palo Blanco"),
      Golfer(name: "Gray Fenwick", handle: "grayfenwick", city: "Sundown Wash"),
      Golfer(name: "Harper Delgado", handle: "harperdelgado", city: "Sundown Wash"),
      Golfer(name: "Maximilian Ashworth-Lindqvist", handle: "maxashworth", city: "Palo Blanco"),
      Golfer(name: "Quinn Whitcomb", handle: "quinnwhitcomb", city: "Mesquite Wells"),
      Golfer(name: "Rowan Castellano", handle: "rowancastellano", city: "Sundown Wash"),
      Golfer(name: "Sage Brannigan", handle: "sagebrannigan", city: "Palo Blanco"),
    ],
    courses: [
      Course(name: "Larkspur Hollow", city: "Palo Blanco"),
      Course(name: "Heronsford Links", city: "Mesquite Wells"),
      Course(name: "Tinaja Pines", city: "Sundown Wash"),
    ],
    cupLeague: League(name: "Mulligan Cup League", code: "MULC26"),
    squadsLeague: League(name: "Wednesday Night Squads League", code: "WNSL26"),
    squads: ["Team Finley", "Team Avery", "Team Blake"],
    ryderTeams: ["Team Avery", "Team Emerson"],
    clinchSquads: ["Team Quinn", "Team Sage"],
    inviteLeague: League(name: "Sunrise Fourball League", code: "SUNF26"),
    rivalry: "The Larkspur Hollow Grudge",
    liveRyder: "Cactus Showdown",
    finishedRyder: "Harvest Cup",
    major: "The Copper Jug",
    majorTrophy: "The Juniper Invitational",
    ryderTrophy: "Spring Showdown",
    bag: Bag(clubs: ["460cc driver, 10.5 deg", "3-wood, 15 deg", "Hybrid, 22 deg",
                     "Cavity-back 5", "Cavity-back 7", "Cavity-back 9", "Cavity-back PW",
                     "Wedge 54", "Blade putter, 34 in"],
             sidelinedDriver: "Old driver, 9 deg", ball: "Three-piece urethane ball"),
    guest: "Quinn")
}
#endif
