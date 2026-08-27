// Cup Season — D82: the guide sheets — the orientation's content, reopenable
// forever (index.html `GUIDE` 13011–13034, `openScoringHelp` 17025–17044).
//
// Copy is grounded in the shipped labels; the model taught here must never
// drift from the doors that teach themselves. Verbatim, with the web's <b>
// as markdown bold. Copy never says "the Post tab" — it is "the ⊕ in the middle".

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
    Row(key: "places", glyph: "◱", title: "The four places", sub: "Home · Clubhouse · the ⊕ · You"),
    Row(key: "games", glyph: "⛳", title: "Leagues vs events", sub: "The long game and the short game"),
    Row(key: "posting", glyph: "✎", title: "Posting a round", sub: "Basic, live, and the scan"),
    Row(key: "buddies", glyph: "◆", title: "Buddies, invites and claims", sub: "Three different links, three jobs"),
    Row(key: "scoring", glyph: "◷", title: "How scoring works", sub: "How rounds become points"),
  ]

  public static let sheets: [String: GuideSheet] = [
    "places": GuideSheet(key: "places", title: "The four places", sub: "ONE APP, FOUR ROOMS", paragraphs: [
      "**Home** is everything you're in, one feed — your standing up top, your buddies' rounds under it.",
      "**Clubhouse** is one league's room: Standings, the Board, the Schedule, the Pot, the Album, the League — switch groups with the chips up top.",
      "**The ⊕ in the middle** is one door for before, during and after a round: post after, score the group live during, put a tee time up before.",
      "**You** is your card, your record, your trophies and your buddies. The ⚙ on your card runs everything else.",
    ]),
    "games": GuideSheet(key: "games", title: "Leagues vs events", sub: "THE LONG GAME · THE SHORT GAME", paragraphs: [
      "**A league is the long game.** A full season — weeks or months, squads or solo, every round you post counts toward a table, and the endgame settles it: a Cup Final or the points table.",
      "**An event is the short game.** A weekend or a few weeks, its own little trophy: the Ryder (two teams, weekly duels), or a Major (one window, every card on one board, one name on the jug).",
      "You can run both at once. An event stands alone, or attaches to a league.",
    ]),
    "posting": GuideSheet(key: "posting", title: "Posting a round", sub: "THE ⊕ · BEFORE, DURING, AFTER", paragraphs: [
      "**After you play:** front nine, back nine, pick the course — twenty seconds. It counts on your card and in every league you're in. **Scan the card** and the app reads it for you, the whole group at once.",
      "**During:** Play now is the shared pencil — match play, Wolf, skins, the settle-up. Everyone's card posts at the end, attested by the group.",
      "**Before:** put a tee time on the sheet. Your buddies see it and tap in.",
    ]),
    "buddies": GuideSheet(key: "buddies", title: "Buddies, invites and claims", sub: "THREE LINKS, THREE JOBS", paragraphs: [
      "**A buddy** is mutual — the magnifier up top finds golfers by name or @handle. Buddies see each other's rounds and share a tee sheet. Nothing to do with leagues or points.",
      "**An invite link** carries a league's code — whoever opens it joins that league.",
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
  public static let scoring: [ScoringSection] = [
    ScoringSection(eyebrow: "Your number", paragraphs: [
      "Your handicap index builds from your scores — no typing. Every round measures how you played against the course's difficulty (rating & slope), and your best recent rounds set your number, WHS-style. It appears once you've posted **3 rounds**; until then it shows as building.",
      "You (or the Pro) can set a **starter** to get going sooner — but once you have 3 posted rounds, your scores take over. Manual changes are announced to your league so the crew keeps everyone honest.",
    ], bands: []),
    ScoringSection(eyebrow: "Every round → cup points", paragraphs: [
      "Every round is scored against **your own number** — a 22-index beating their number is worth exactly what a 6-index beating theirs is:",
    ], bands: [
      "**Torched it** · beat it by 3+ · **12 pts**",
      "**Beat your number** · by 1–3 · **9 pts**",
      "**Played to it** · within 1 · **7 pts**",
      "**A little loose** · 1–3 over · **6 pts**",
      "**Posted anyway** · rough day · **5 pts**",
    ]),
    ScoringSection(eyebrow: "", paragraphs: [
      "The 12-point ceiling caps what a padded number can buy; the 5-point floor means a posted 98 still beats an unposted 82. **You can't hurt your squad by playing badly — only by not playing.**",
    ], bands: []),
    ScoringSection(eyebrow: "What counts", paragraphs: [
      "Your best rounds each month count for your squad — a better round always bumps your worst counter — and everyone owes a minimum number of rounds a month so nobody coasts. Miss it once and your **season bye** covers you automatically — life happens; the floor bites from the second miss. Your league's exact numbers are in **League rules**.",
    ], bands: []),
    ScoringSection(eyebrow: "The money", paragraphs: [
      "The pot is **on the books** — Cup Season keeps the ledger and shows a settlement card; the money moves between you.",
    ], bands: []),
  ]
}
