import Foundation

/// D405 · a thread's word about its round (how many comments it holds, which is newest), stamped when it arrives.
///
/// A door (on Home, on the board) is read from the server in one call and corrected by the open thread in another;
/// the two can pass each other. A doors read that was ASKED before a thread spoke carries the count from before
/// it, and must not take the thread's word back; a read asked after the word is the news again. The surface notes
/// each word and, when its read returns, keeps the words said after the read was asked.
public struct ThreadWords: Sendable {
  private var clock = 0
  private var stamped: [UUID: Int] = [:]
  public init() {}

  /// the stamp to remember when a doors read is ASKED
  public var now: Int { clock }

  /// a thread said something about `round`
  public mutating func note(_ round: UUID) {
    clock += 1
    stamped[round] = clock
  }

  /// whether the thread spoke for `round` after a read was asked at `asked`
  public func spoke(for round: UUID, after asked: Int) -> Bool { (stamped[round] ?? 0) > asked }
}
