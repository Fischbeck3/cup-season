import Foundation

public struct LinkConfirmation: Identifiable, Sendable, Equatable {
  public enum Kind: String, CaseIterable, Sendable { case person, plan, claim }
  public let kind: Kind
  public let token: UUID
  public let owner: UUID
  public let info: JSONValue
  public var id: UUID { token }
  public init(kind: Kind, token: UUID, owner: UUID, info: JSONValue) {
    self.kind = kind; self.token = token; self.owner = owner; self.info = info
  }
  public static let eyebrow = "FROM A LINK YOU OPENED"
  public static let dismiss = "Not now"
  public var title: String {
    switch kind { case .person: "A buddy link"; case .plan: "A plan link"; case .claim: "A scorecard link" }
  }
  public var button: String {
    switch kind { case .person: "Add as a buddy"; case .plan: "Take the seat"; case .claim: "Add it to my record" }
  }
  public var marker: String? { info["marker"]?.string }
  public var name: String {
    let value = info[kind == .plan ? "host" : "name"]?.string?.trimmingCharacters(in: .whitespacesAndNewlines)
    return value?.isEmpty == false ? value! : (kind == .person ? "this golfer" : "A golfer")
  }
  public var question: String {
    switch kind {
    case .person: return "Add \(name) as a buddy?"
    case .plan:
      let course = (info["course"]?.string ?? "").components(separatedBy: " — ").first ?? ""
      let day = Self.day(info["play_on"]?.string)
      return "\(name)’s round at \(course.isEmpty ? "the course" : course)\(day.isEmpty ? "" : " on \(day)") — take a seat?"
    case .claim:
      let gross = info["gross"]?.int
      let course = info["course_label"]?.string ?? "the course"
      return (gross.map { "Add this \($0) at \(course)" } ?? "Add this card from \(course)") + " to your record?"
    }
  }
  public var note: String {
    switch kind {
    case .person: "Buddies see each other’s rounds and plans."
    case .plan: "Taking the seat puts you down as in and sends \(name) a buddy request."
    case .claim: "It posts to your rounds and counts in your seasons."
    }
  }
  public var facts: String? {
    if kind == .person { return info["index"]?.double.map { "Index \(String(format: "%.1f", $0))" } }
    if kind == .claim {
      return [info["guest_name"]?.string.map { "Scored as \($0)" }, Self.day(info["played_on"]?.string)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
    return info["tee"]?.string
  }
  private static func day(_ iso: String?) -> String {
    guard let iso, let date = CSDate.local(iso) else { return "" }
    let formatter = DateFormatter(); formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
    return formatter.string(from: date)
  }
  public static func pending(_ kind: Kind, defaults: UserDefaults = .standard) -> UUID? {
    switch kind { case .person: ShareIntent.person.pending(defaults: defaults); case .plan: ShareIntent.plan.pending(defaults: defaults); case .claim: ClaimIntent.pending(defaults: defaults) }
  }
  public func isCurrent(owner: UUID?, defaults: UserDefaults = .standard) -> Bool {
    owner == self.owner && Self.pending(kind, defaults: defaults) == token
  }
  public func clear(defaults: UserDefaults = .standard) {
    guard Self.pending(kind, defaults: defaults) == token else { return }
    switch kind { case .person: ShareIntent.person.clear(defaults: defaults); case .plan: ShareIntent.plan.clear(defaults: defaults); case .claim: ClaimIntent.clear(defaults: defaults) }
  }

  public static func preview(kind: Kind, token: UUID, svc: SupabaseService = .shared) async throws -> JSONValue? {
    if kind != .claim {
      let value = try await svc.call(Rpc.share_info(p_token: token))
      return value.isNull ? nil : value
    }
    let value = try await svc.call(Rpc.claim_round_info(p_token: token))
    if !value.isNull { return value }
    do {
      let scan = try await svc.call(Rpc.scan_claim_info(p_token: token))
      return scan.isNull ? nil : scan
    } catch {
      // scan_claim_info raises for an unknown token. Transport/auth errors
      // retain the link, so reconnecting cannot silently discard a scorecard.
      let text = String(describing: error).lowercased()
      if text.contains("claim link not recognized") || text.contains("claim not found") || text.contains("claim expired") || text.contains("no such claim") { return nil }
      throw error
    }
  }
}
