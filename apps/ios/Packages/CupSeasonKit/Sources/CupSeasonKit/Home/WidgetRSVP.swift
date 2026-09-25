import Foundation

public enum WidgetRSVPError: LocalizedError {
  case signIn, expired, unavailable
  public var errorDescription: String? {
    switch self {
    case .signIn: "Open Cup Season and sign in to reply."
    case .expired: "This invitation has changed. Open the plan to check it."
    case .unavailable: "Couldn’t confirm your reply. Open the plan to check it."
    }
  }
}

/// Intent and push use the same RSVP RPC. Re-read the invitation before every write.
@MainActor public enum WidgetRSVP {
  public static func run(round: UUID, owner: UUID, status: String,
    defaults: UserDefaults? = UserDefaults(suiteName: CSAppGroup.id),
    currentOwner: () async -> UUID?,
    read: (UUID) async throws -> RoundDetail,
    save: (UUID, String) async throws -> Void,
    now: Date = Date()) async throws {
    let epoch = defaults?.string(forKey: BetweenRoundsSnapshot.epochKey)
    func ownsCache() -> Bool {
      DispatchSnapshot.belongs(to: owner, defaults: defaults) && defaults?.string(forKey: BetweenRoundsSnapshot.epochKey) == epoch
    }
    guard ["in", "out"].contains(status), ownsCache(), await currentOwner() == owner else { throw WidgetRSVPError.signIn }
    do {
      let detail = try await read(round)
      guard ownsCache(), await currentOwner() == owner else { throw WidgetRSVPError.signIn }
      guard detail.id == round, let tee = BetweenRoundsCopy.tee(detail, owner: owner, now: now), tee.allowsReply(at: now) else { throw WidgetRSVPError.expired }
      try await save(round, status)
      guard ownsCache(), await currentOwner() == owner else { throw WidgetRSVPError.signIn }
      // Do not claim success until the server acknowledges the write. Only this
      // slice's time advances; another widget's old data remains visibly old.
      var confirmed = tee; confirmed.status = status; confirmed.replyError = nil
      var snapshot = BetweenRoundsSnapshot.read(defaults) ?? .init(owner: owner)
      // A concurrent app refresh may have selected another plan; don't replace it.
      if snapshot.nextTee?.value?.id == round {
        snapshot.nextTee = .init(confirmed, at: now)
        snapshot.write(defaults, epoch: epoch)
      }
    } catch {
      if ownsCache(), var snapshot = BetweenRoundsSnapshot.read(defaults), snapshot.nextTee?.value?.id == round {
        snapshot.nextTee?.value?.replyError = "Couldn’t confirm. Open the plan."
        snapshot.write(defaults, epoch: epoch)
      }
      throw error
    }
  }
}
