import Foundation

/// A retry carries the identity of the exact text and reply target first sent.
/// Keep this after an uncertain network result; retire it only on acceptance.
public struct CommentIntent: Sendable, Equatable {
  public let id: UUID
  public let body: String
  public let parentId: UUID?

  public init(body: String, parentId: UUID?, id: UUID = UUID()) {
    self.id = id
    self.body = body.trimmingCharacters(in: .whitespacesAndNewlines)
    self.parentId = parentId
  }

  public func forRetry(body: String, parentId: UUID?) -> CommentIntent {
    let next = body.trimmingCharacters(in: .whitespacesAndNewlines)
    return next == self.body && parentId == self.parentId
      ? self : CommentIntent(body: next, parentId: parentId)
  }
}
