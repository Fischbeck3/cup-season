// Cup Season — WHOSE REACTION IS THIS (D238, wave 6).
//
// `post_kudos` was keyed `(post_id, member_id, emoji)` with a foreign key into
// `league_members`, which is the fourth wall a golfer with no season hits: a
// buddy can SEE a friend's personal best in the Home wire and cannot say a
// word on it, because the reaction's foreign key requires a shared league.
// That is D28's own reopen trigger — "when a real user tries to react to a
// friend-only round and can't" — fired.
//
// The re-key is a WIDENING, not a rename. `member_id` keeps its column and
// loses only its FK, and a `before insert` trigger derives whichever of the
// two the writer did not name. So this file has to answer one question in one
// place, for both clients and for both directions of deploy skew:
//
//   · WRITING — name the profile. If the column is not there yet (the client
//     shipped ahead of the `db push`), fall back to the membership.
//   · READING — a row may carry either. The profile wins where it is present;
//     the membership resolves to a profile where it is not.
//
// L-42's six emoji are untouched. There is no count anywhere in this file that
// is not the count of a thing that happened, and there is no rank at all
// (L-22). And there is NO fallback that changes which emoji was written — the
// original guard retried the insert without `emoji` and the column default
// stamped 🔥, so a 🦅 became fire. That is the mistake this file names so it
// is never made again: identifying the SAME person by a different column is
// honest; writing a DIFFERENT reaction is not.

import Foundation

public enum BoardKudos {

  /// One `post_kudos` row as either schema can hand it over. Both keys are
  /// optional because both eras are real: pre-push rows carry `member_id`
  /// alone, post-push rows carry `profile_id`, and the migration's backfill
  /// leaves the five existing rows carrying both.
  public struct Row: Codable, Sendable, Equatable {
    public let post_id: UUID
    public let profile_id: UUID?
    public let member_id: UUID?
    public let emoji: String?
    public init(post_id: UUID, profile_id: UUID? = nil, member_id: UUID? = nil, emoji: String?) {
      self.post_id = post_id; self.profile_id = profile_id; self.member_id = member_id; self.emoji = emoji
    }
  }

  /// The emoji a row means. A row written before `emoji` existed defaults to
  /// the quick chip, which is what the column's own default already stamped.
  public static func emoji(_ r: Row) -> String { r.emoji ?? CSReactions.quick }

  /// WHO left it, as a profile. `memberToProfile` is whatever roster the
  /// caller has (a league's members, or the batch it resolved for the wire);
  /// a row that resolves to neither is nobody, and the caller drops it rather
  /// than attributing it to a name it guessed.
  public static func author(_ r: Row, memberToProfile: [UUID: UUID]) -> UUID? {
    if let p = r.profile_id { return p }
    if let m = r.member_id { return memberToProfile[m] }
    return nil
  }

  /// Is this row MINE? The one question the strip's `me` flag turns on, and
  /// the one that was wrong before the re-key: a golfer in two leagues has two
  /// member ids and the old test only ever held one of them.
  public static func isMine(_ r: Row, me: UUID?, myMemberIds: Set<UUID>,
                            memberToProfile: [UUID: UUID] = [:]) -> Bool {
    if let p = r.profile_id, let me { return p == me }
    if let m = r.member_id {
      if myMemberIds.contains(m) { return true }
      // and the roster is the second answer, because a membership the caller
      // did not happen to be holding is still MINE. That is the old defect
      // exactly: a golfer in two leagues has two member ids.
      if let me, let p = memberToProfile[m] { return p == me }
    }
    return false
  }

  /// The declared fallback's one condition. A client that ships before the
  /// `db push` names a column PostgREST has never heard of; that — and only
  /// that — retries the old shape. A refused write, a dead network or an RLS
  /// denial is NOT this, and must reach the golfer as itself.
  ///
  /// PostgREST answers an unknown column with **PGRST204**; Postgres answers
  /// with **42703**; both spell it out in the message, and the schema cache
  /// says so in its own words. Nothing else here matches an ordinary failure.
  public static func skewFallbackFires(on message: String) -> Bool {
    let m = message.lowercased()
    if m.contains("pgrst204") || m.contains("42703") { return true }
    if m.contains("column") && (m.contains("does not exist") || m.contains("could not be found")) { return true }
    if m.contains("schema cache") && m.contains("profile_id") { return true }
    return false
  }

  public static func skewFallbackFires(on error: any Error) -> Bool {
    skewFallbackFires(on: String(describing: error))
  }
}
