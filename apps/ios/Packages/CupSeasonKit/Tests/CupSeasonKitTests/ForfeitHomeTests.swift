import Testing
import Foundation
@testable import CupSeasonKit

/// D242 · a forfeit can exist between two golfers with no season.
///
/// Two rules, and the database says both in CHECKs. This is their client twin,
/// so the sheet refuses before the server has to — and so that "exactly one
/// home" is a value a test can walk rather than a sentence in a migration.
@Suite struct ForfeitHomeTests {

  private static let a = UUID(), b = UUID(), c = UUID(), him = UUID()

  // MARK: - exactly one home, all sixteen combinations

  @Test func exactlyOneHome() {
    var checked = 0
    for l in [nil, Self.a] {
      for e in [nil, Self.b] {
        for r in [nil, Self.c] {
          for o in [nil, Self.him] {
            let h = ForfeitHome(leagueId: l, eventId: e, scheduledRoundId: r, opponent: o)
            let containers = [l, e, r].compactMap { $0 }.count
            checked += 1
            if containers > 1 {
              #expect(h.verdict == .twoHomes)
              #expect(!h.isValid)
            } else if containers == 0 && o == nil {
              #expect(h.verdict == .noHome)
              #expect(!h.isValid)
            } else {
              #expect(h.isValid, Comment(rawValue: "\(containers) containers, opponent \(o != nil)"))
            }
          }
        }
      }
    }
    #expect(checked == 16)
  }

  /// The FOURTH home the draft did not name, and the one the callout's own
  /// stake needs: two buddies who share nothing at all.
  @Test func twoBuddiesWithNoSeasonIsAHome() {
    let h = ForfeitHome(opponent: Self.him)
    #expect(h.isValid)
    #expect(h.kind == .buddies)
    #expect(h.containers == 0)
  }

  @Test func everyHomeKnowsWhichItIs() {
    #expect(ForfeitHome(leagueId: Self.a).kind == .season)
    #expect(ForfeitHome(eventId: Self.b).kind == .moment)
    #expect(ForfeitHome(scheduledRoundId: Self.c).kind == .plan)
    #expect(ForfeitHome(opponent: Self.him).kind == .buddies)
    #expect(ForfeitHome().kind == .none)
  }

  /// L-32 · a refusal a golfer can read beats a control that is missing.
  @Test func everyRefusalIsASentenceAndEveryValidHomeHasNone() {
    #expect(ForfeitHome(leagueId: Self.a, eventId: Self.b).refusal == "A pride bet hangs on one thing.")
    #expect(ForfeitHome().refusal == "Say who it is with, or what it hangs on.")
    #expect(ForfeitHome(opponent: Self.him).refusal == nil)
    #expect(ForfeitHome(leagueId: Self.a).refusal == nil)
  }

  // MARK: - no money column, ever

  /// The load-bearing rule this widening leans on
  /// (`20260724120000_forfeit_ledger.sql:10-13`): terms are PROSE, never an
  /// amount. It is the store-review posture as much as taste (D39/D64), and a
  /// widening is exactly when a rule gets quietly dropped.
  @Test func nothingInTheForfeitSheetSaysMoney() {
    // D366 · `all` is every sentence the composer shows, so a new line is
    // swept the day it is written
    let strings = ForfeitCopy.all
    #expect(strings.count >= 20)
    for s in strings {
      for w in ForfeitCopy.moneyWords {
        #expect(!s.lowercased().contains(w), Comment(rawValue: "\"\(s)\" says \(w)"))
      }
    }
  }

  // MARK: - D299 · the noun

  /// **THE TITLE NO LONGER NEEDS THE SENTENCE TO UNDO IT.** `forfeit` means
  /// conceding to anyone who has not been taught otherwise, and the owner read
  /// the control that way on build 748 — he wrote the product. The tell had
  /// been on the screen for months: the title said *Post a forfeit* and the
  /// line under it opened *A forfeit is a bet for pride*, a definition whose
  /// only job was to correct the words above it. The sentence says what the
  /// act IS now, and it stands on its own.
  @Test func theNounIsThePrideBetAndTheSentenceStandsAlone() {
    #expect(ForfeitCopy.title == "Post a pride bet")
    #expect(ForfeitCopy.definition == "A bet for pride. It settles on a tap and goes on the record — never on the books.")
    #expect(!ForfeitCopy.definition.hasPrefix("A pride bet is"))
    // the ledger's head and the control on it — the pane hides entirely when a
    // league has none, so this is the only proof those words exist
    #expect(ForfeitCopy.ledgerHead == "Pride bets · on the record")
  }

  /// The whole sheet, swept — the same shape as the money sweep above it,
  /// because a rename dies the same way a rule does: one string at a time.
  /// `forfeits` the TABLE keeps its name (a schema word is not a product
  /// word), which is exactly why the guard has to be over the STRINGS.
  @Test func nothingAGolferReadsSaysForfeit() {
    let strings = ForfeitCopy.all + [
                   ForfeitHome(leagueId: Self.a, eventId: Self.b).refusal ?? "",
                   ForfeitHome().refusal ?? "",
                   CalloutCopy.stakeForfeit, PlanCopy.stakeGloss]
    for s in strings {
      #expect(!s.lowercased().contains("forfeit"), Comment(rawValue: "\"\(s)\" still says forfeit"))
    }
  }

  // MARK: - D366 (F6) · a first-time golfer can say what the button does

  /// Purpose, parties, context, confirmation, where it appears, and league
  /// points — each answered on the sheet, and honestly record-only: it never
  /// claims the other golfer agreed or was sent anything.
  @Test func theSheetAnswersTheSixQuestionsAndNeverClaimsAcceptance() {
    #expect(ForfeitCopy.purpose.contains("nobody is asked to accept"))
    #expect(ForfeitCopy.who("Alex Rivera") == "You and Alex")
    #expect(ForfeitCopy.who(nil).hasPrefix("You and the field"))
    #expect(ForfeitCopy.context(ForfeitHome(leagueId: Self.a), name: "the Fellas") == "On the Fellas — the result never touches its points.")
    #expect(ForfeitCopy.context(ForfeitHome(opponent: Self.him)) == "Between the two of you — no season or round attached.")
    #expect(ForfeitCopy.context(ForfeitHome(scheduledRoundId: Self.b)) == "On this planned round.")
    #expect(ForfeitCopy.confirm("Alex Rivera").contains("either of you settles it with a tap"))
    #expect(ForfeitCopy.confirm("Alex Rivera").contains("Alex isn't asked to accept here"))
    #expect(ForfeitCopy.points == "It never touches league points.")
    #expect(ForfeitCopy.whereItShows.contains("Pride bets · on the record"))
    #expect(ForfeitCopy.decidesLabel == "What decides it")
    // nothing on the sheet says a challenge was SENT, or that anyone accepted
    for s in ForfeitCopy.all {
      let l = s.lowercased()
      #expect(!l.contains("challenge sent") && !l.contains("they accepted") && !l.contains("has accepted"), Comment(rawValue: s))
    }
  }

  /// The client mirror of the CHECK: the call carries no amount, and there is
  /// nowhere on it to put one.
  @Test func theCallCarriesNoAmount() throws {
    let call = CreateForfeitCall(home: ForfeitHome(opponent: Self.him),
                                 name: "The Lawn Bet", terms: "Loser mows the winner's lawn")
    let data = try JSONEncoder().encode(call)
    let obj = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    for k in obj.keys {
      #expect(!k.contains("cent") && !k.contains("amount") && !k.contains("stake"),
              Comment(rawValue: k))
    }
    // and the four homes it can name, and no fifth
    #expect(Set(obj.keys) == ["p_league", "p_name", "p_terms", "p_kind", "p_other"])
  }

  /// C-06 · a consequential write sheds NOTHING on a blind retry. A season's
  /// forfeit already sends the six keys the deployed function has (the two new
  /// arguments are nil and omitted), so there is nothing to gain and a
  /// re-homed bet and a duplicate row to lose.
  @Test func nothingIsDroppableOnAForfeit() {
    #expect(CreateForfeitCall.optionalArgs.isEmpty)
  }

  /// The proof the skew is served without a shed: a SEASON's forfeit encodes
  /// exactly the six keys every deployed `create_forfeit` has.
  @Test func aSeasonForfeitSendsTheSixKeysTheDeployedFunctionHas() throws {
    let call = CreateForfeitCall(home: ForfeitHome(leagueId: Self.b, opponent: Self.him),
                                 name: "n", terms: "t")
    let data = try JSONEncoder().encode(call)
    let obj = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(obj["p_event"] == nil && obj["p_round"] == nil)
    #expect(Set(obj.keys) == ["p_league", "p_name", "p_terms", "p_kind", "p_other"])
  }

  /// A null league is an EXPLICIT null, never an omitted key — PostgREST matches
  /// a signature by the keys it is given.
  @Test func aNullLeagueIsWrittenNotOmitted() throws {
    let call = CreateForfeitCall(home: ForfeitHome(eventId: Self.b, opponent: Self.him),
                                 name: "n", terms: "t")
    let data = try JSONEncoder().encode(call)
    let obj = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(obj["p_league"] is NSNull)
    #expect(obj["p_event"] != nil)
  }
}
