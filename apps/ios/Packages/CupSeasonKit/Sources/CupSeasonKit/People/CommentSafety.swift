import Foundation

public struct CommentSafety: Sendable, Equatable, Identifiable {
  public enum Kind: String, Sendable { case comment, roundComment = "round_comment" }
  public let id: UUID
  public let kind: Kind
  public let author: UUID?
  public let name: String
  public init(id: UUID, kind: Kind, author: UUID?, name: String) {
    self.id = id; self.kind = kind; self.author = author; self.name = name
  }
  public func report(reason: String) -> Rpc.report_content {
    Rpc.report_content(p_reason: String(reason.prefix(500)), p_kind: kind.rawValue, p_comment: id)
  }
}
