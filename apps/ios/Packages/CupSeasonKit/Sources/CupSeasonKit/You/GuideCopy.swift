// Cup Season — D82: the guide sheets — the orientation's content, reopenable
// forever (index.html `GUIDE` ~14840–14860, `openScoringHelp` ~19409–19432).
//
// Copy is grounded in the shipped labels; the model taught here must never
// drift from the doors that teach themselves. Verbatim with the web, with the
// web's <b> as markdown bold — the web mirrors THIS file's strings.
//
// Y-05 · the doors are the phone's doors: the middle tab is labelled "Post"
// (`MainTabView` — the web's bar says "Post" too, the guide's "⊕" was stale on
// both), the ⚙ sits at the top of You and opens Card & settings (`YouScreen`,
// web `#youProfile`), golfers are found under "Your buddies" (`YouScreen`, web
// You page), and the Clubhouse pages between leagues by swipe (D203).
//
// ONE line here is NOT verbatim across the clients, and mirroring it would
// write a fresh lie: the Clubhouse switcher. The phone swipes (D203); the web
// still switches with chips (`renderClubGroups`, index.html ~10927). A door
// sentence names the door THAT client ships — so the web keeps "switch groups
// with the chips up top" until its switcher changes. Everything else below
// mirrors word for word.
//
// The scoring guide is ONE producer (Y-25): the welcome, Card & settings and
// the room all render `scoring(solo:)`; nobody retypes the bands. The bands'
// names and points come from `CSBands` (the engine rule, half-open at −1.0),
// so the table can never disagree with the receipt (Q-20/D123). D205 makes
// "What counts" structure-aware: a solo floor never assesses (D140), so the
// guide stops promising a penalty the engine cannot fire.

import Foundation

public struct GuideSheet: Sendable, Identifiable, Equatable {
  public let key: String
  public let title: String
  public let sub: String
  /// Paragraphs, markdown-bold.
  public let paragraphs: [String]
  public var id: String { key }
}

public enum GuideCopy {
  public struct Row: Sendable, Identifiable, Equatable {
    public let key: String
    public let glyph: String
    public let title: String
    public let sub: String
    public var id: String { key }
  }

  /// The five `.check` rows under "How it works", in order.
  public static let rows: [Row] = [
    Row(key: "places", glyph: "◱", title: "The four places", sub: "Home · Clubhouse · Post · You"),
    Row(key: "games", glyph: "⛳", title: "Leagues vs events", sub: "The long game and the short game"),
    Row(key: "posting", glyph: "✎", title: "Posting a round", sub: "Basic, live, and the scan"),
    Row(key: "buddies", glyph: "◆", title: "Buddies, invites and claims", sub: "Three different links, three jobs"),
    Row(key: "scoring", glyph: "◷", title: "How scoring works", sub: "How rounds become points"),
  ]

  public static let sheets: [String: GuideSheet] = [
    "places": GuideSheet(key: "places", title: "The four places", sub: "ONE APP, FOUR ROOMS", paragraphs: [
      "**Home** is everything you're in, one feed — your standing up top, your buddies' rounds under it.",
      "**Clubhouse** is one league's room: Standings, the Board, the Schedule, the Pot, the Album, the League — swipe sideways to move between your leagues.",
      "**Post**, in the middle of the bar, is one door for before, during and after a round: post after, score the group live during, put a tee time up before.",
      "**You** is your card, your record, your trophies and your buddies. The gear up top opens Card & settings, which runs everything else.",
    ]),
    "games": GuideSheet(key: "games", title: "Leagues vs events", sub: "THE LONG GAME · THE SHORT GAME", paragraphs: [
      "**A league is the long game.** A full season — weeks or months, squads or solo, every round you post counts toward a table, and the endgame settles it: a Cup Final or the points table.",
      "**An event is the short game.** A weekend or a few weeks, its own little trophy: the Ryder (two teams, weekly duels), or a Major (one window, every card on one board, one name on the jug).",
      "You can run both at once. An event stands alone, or attaches to a league.",
    ]),
    "posting": GuideSheet(key: "posting", title: "Posting a round", sub: "POST · BEFORE, DURING, AFTER", paragraphs: [
      "**After you play:** front nine, back nine, pick the course — twenty seconds. It counts on your card and in every league you're in. **Scan the card** and the app reads it for you, the whole group at once.",
      "**During:** Play now is the shared pencil — match play, Wolf, skins, the settle-up. Everyone's card posts at the end, attested by the group.",
      "**Before:** put a tee time on the sheet. Your buddies see it and tap in.",
    ]),
    "buddies": GuideSheet(key: "buddies", title: "Buddies, invites and claims", sub: "THREE LINKS, THREE JOBS", paragraphs: [
      "**A buddy** is mutual — open Your buddies on You to find golfers by name or @handle. Buddies see each other's rounds and share a tee sheet. Nothing to do with leagues or points.",
      "**An invite link** carries a league's code — whoever opens it reviews the league and joins if they're in.",
      "**A claim link** hands one round to a guest you played with, so the score lands on their card. No league, no buddy — just the round.",
    ]),
  ]

  /// `openScoringHelp` — sections of (eyebrow, paragraphs); the bands table is
  /// its own section so it can render as a card.
  public struct ScoringSection: Sendable, Identifiable, Equatable {
    public let eyebrow: String
    public let paragraphs: [String]
    public let bands: [String]
    public var id: String { eyebrow }
  }
  public static let scoringTitle = "How scoring works"
  public static let scoringSub = "HANDICAPS · CUP POINTS · THE MONEY"

  /// The guide with no league in hand: both structures, so it promises nothing
  /// the engine cannot do. Prefer `scoring(solo:)` wherever a league is known.
  public static var scoring: [ScoringSection] { scoring(solo: nil) }

  /// D205 · the scoring guide for one structure. `solo` true = a solo league
  /// (the floor is a habit — D140: there is no squad to dock); false = squads
  /// (everyone owes the minimum, the bye covers one miss); nil = unknown, and
  /// the floor paragraph says both.
  public static func scoring(solo: Bool?) -> [ScoringSection] {
    let counts: String
    switch solo {
    case true:
      counts = "Your best rounds each month count — a better round always bumps your worst counter. In a solo league the monthly minimum is a habit, not a penalty — there's no squad to dock. Your league's exact numbers are in **League rules**."
    case false:
      counts = "Your best rounds each month count for your squad — a better round always bumps your worst counter — and everyone owes a minimum number of rounds a month so nobody coasts. Miss it once and your **season bye** covers you automatically — life happens; the floor bites from the second miss. Your league's exact numbers are in **League rules**."
    default:
      counts = "Your best rounds each month count — a better round always bumps your worst counter. In a squad league everyone owes a minimum number of rounds a month so nobody coasts: miss it once and your **season bye** covers you automatically — life happens; the floor bites from the second miss. In a solo league that minimum is a habit, not a penalty — there's no squad to dock. Your league's exact numbers are in **League rules**."
    }
    // D3's covenant line; "your squad" is a lie in a solo league and "your
    // standing" is true in BOTH — so only a KNOWN squad league gets the squad
    // wording. nil is the league-less reader in Card & settings, whose "What
    // counts" paragraph two blocks down was written to cover both structures.
    let covenant = solo == false
      ? "**You can't hurt your squad by playing badly — only by not playing.**"
      : "**You can't hurt your standing by playing badly — only by not playing.**"
    return [
      ScoringSection(eyebrow: "Your number", paragraphs: [
        "Your handicap index builds from your scores — no typing. Every round measures how you played against the course's difficulty (rating & slope), and your best recent rounds set your number, WHS-style. It appears once you've posted **3 rounds**; until then it shows as building.",
        "You (or the Pro) can set a **starter** to get going sooner — but once you have 3 posted rounds, your scores take over. Manual changes are announced to your league so the crew keeps everyone honest.",
      ], bands: []),
      ScoringSection(eyebrow: "Every round → cup points", paragraphs: [
        "Every round is scored against **your own number** — a 22-index beating their number is worth exactly what a 6-index beating theirs is:",
      ], bands: [
        // one value inside each band; the name and the points are the engine's (CSBands), the edge is said in words
        band(3, "beat it by 3 or more"),
        band(1, "by 1 to 2.9"),
        band(0, "less than 1 either way"),
        band(-1, "1 to 3 over"),
        band(-4, "more than 3 over"),
      ]),
      ScoringSection(eyebrow: "", paragraphs: [
        // Y-31 · the allowance is the one number a receipt cannot be reverse-engineered from
        "The number the bands measure from is your **playing number** — your number with the league's allowance applied: \(Bylaws.presetNames[1]) scores you against \(Bylaws.allow[1])% of it, \(Bylaws.presetNames[0]) \(Bylaws.allow[0])%, \(Bylaws.presetNames[2]) \(Bylaws.allow[2])%.",
        "The 12-point ceiling caps what a padded number can buy; the 5-point floor means a posted 98 still beats an unposted 82. \(covenant)",
      ], bands: []),
      ScoringSection(eyebrow: "What counts", paragraphs: [counts], bands: []),
      ScoringSection(eyebrow: "The money", paragraphs: [
        "The pot is **on the books**. \(MoneyCopy.ledger) The settlement card shows who owes what.",
      ], bands: []),
    ]
  }

  /// One row of the bands card: "**Torched it** · beat it by 3 or more · **12 pts**".
  /// `vs` is any value inside the band; `CSBands` names it and scores it.
  private static func band(_ vs: Double, _ edge: String) -> String {
    "**\(CSBands.bandName(vs))** · \(edge) · **\(CSBands.cupPoints(vs)) pts**"
  }
}
