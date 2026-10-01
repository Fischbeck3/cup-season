// Cup Season — the word filter's refusal, verbatim, in one place (D403).
//
// The database refuses slurs, explicit sexual content and threat phrases on
// every column a golfer writes words into — board posts and comments, plan
// names and notes, league names and identity lines, names and handles, pride
// bets, rivalry, squad, event and team names, bag labels and live guests. It
// raises ONE sentence, as a plain `raise exception` (SQLSTATE P0001), and it
// never names the matched word.
//
// The phone never writes this sentence to a golfer itself — the server does.
// It lives here so the two mappers (`BoardText.humanError`, `AuthRules.human`)
// can name it on their allowlist rather than trusting the shape gate to pass
// it, and so a test can hold the exact words both clients agree on. If the
// migration's wording ever changes, this constant changes in the same commit.

public enum ModerationCopy {
  /// The server's refusal, exactly as `raise exception` writes it.
  public static let refusal = "Cup Season can't take that wording — no slurs, sexual content or threats. Edit it and try again."
  /// D403 · a closed account's refusal, as the server writes it (PT403). The
  /// phone says the same words where a refusal arrives without a sentence —
  /// a scan refused `account_closed`.
  public static let closed = "This account has been closed."
}
