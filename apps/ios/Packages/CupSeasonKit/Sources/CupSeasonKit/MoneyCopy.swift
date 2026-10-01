// Cup Season — the ledger sentence, verbatim, in one place.
//
// D39 fixed this line and the brand canon (§3) records it as a LAW rather than
// a suggestion: "Cup Season keeps the ledger; the money moves between friends"
// — verbatim everywhere money appears. The voice audit of 2026-09-01 found it
// written twenty-two ways across the two clients, and on four surfaces it was
// still the promise D39 RETIRED: "never through us" (mailed to every member of
// every finished league), "never the money" (the You tab, under a dollar
// figure), "takes no fee or cut of any prize pool" (the live legal page).
//
// The reason it drifted is worth writing down, because it is structural rather
// than careless. Every OTHER law in §3 is enforceable by grep — "commissioner",
// "PvI", "differential" are TOKENS, and a token can be found. A *verbatim* law
// has no violating token; it has only near-misses, and near-misses are
// invisible to search. So each money surface retyped it slightly better than
// the last and nothing ever failed. The named bands survived the same year
// intact because `GuideCopy` holds them and everyone calls them.
//
// A law written as a fixed phrase needs a fixed home, or it is only a wish.
//
// Never soften "between friends" to "between you". The first names what the
// transaction IS; the second addresses the reader as a party to it — and this
// sentence is the canon's anti-"betting app" vaccine, so which of those it says
// is the entire point.

public enum MoneyCopy {
  /// The canon line. Verbatim, D39 / brand-canon §3.
  public static let ledger = "Cup Season keeps the ledger; the money moves between friends."
}

/// D192 / D402 · **ONE CEILING FOR EVERY DOLLAR FIELD A GOLFER TYPES INTO.**
/// The season buy-in was capped at $200 at every layer (the `league_settings`
/// CHECK, 0–20,000 cents; `WizardDials.maxStake`; the web wizard), and the web
/// capped the live-round stake to the same number (`CS_STAKE_MAX`). The phone's
/// live stake was a free decimal with a floor and no ceiling — the one field in
/// the product that scaled from "a friendly five" to a figure that reads as
/// wagering. The server now refuses a new or changed live stake above it too
/// ("Stakes top out at $200 a golfer."); the field and the store clamp first so
/// a golfer never meets that refusal.
///
/// It bounds what a golfer can ENTER. It never rewrites an amount already on
/// the record: a rehydrated round, a settlement and the ledger read what was
/// stored.
public enum MoneyLimits {
  /// Dollars a golfer, for a season buy-in or a live-round stake.
  public static let maxStake = 200
  /// The fine line under every capped field, in the wizard's words.
  public static let upTo = "Up to $\(maxStake) a golfer."

  /// A typed live stake, bounded to 0…`maxStake`. Anything that is not a
  /// finite number is no stake at all.
  public static func clampStake(_ v: Double) -> Double {
    guard v.isFinite else { return 0 }
    return min(Double(maxStake), max(0, v))
  }
}
