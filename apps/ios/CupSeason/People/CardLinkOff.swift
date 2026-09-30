import SwiftUI
import CSDesign
import CupSeasonKit

/// X38 · the web's CS_CARD_LINK_OFF words, beside the card's share door.
@MainActor @Observable final class CardLinkOffModel {
  static let label = "Turn off my card link"
  static let armedLabel = "Sure? The old link stops working"
  static let done = "Your card link is off. Sharing your card again makes a new link."
  var armed = false
  private(set) var busy = false
  private(set) var status: String?
  private(set) var failed = false
  private let revoke: @MainActor (UUID) async throws -> Bool

  init(revoke: @escaping @MainActor (UUID) async throws -> Bool = { profile in
    let service = SupabaseService.shared
    let token = try await service.call(Rpc.create_share(p_kind: "person", p_ref: profile))
    return try await service.call(Rpc.revoke_share(p_token: token))
  }) { self.revoke = revoke }

  func tap(_ profile: UUID) async {
    guard !busy else { return }
    guard armed else { armed = true; CSHaptic.warning(); return }
    armed = false; busy = true; status = nil; failed = false
    defer { busy = false }
    do {
      guard try await revoke(profile) else {
        failed = true; status = "Could not turn off your card link. Try again."; return
      }
      status = Self.done
    } catch {
      failed = true
      status = AuthRules.human(error, fallback: "Could not turn off your card link. Try again.")
    }
  }

  func sharedAgain() { armed = false; status = nil; failed = false }
}

struct CardLinkOffControl: View {
  @Environment(\.cs) private var cs
  @Bindable var model: CardLinkOffModel
  let profile: UUID?
  var sharing = false

  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      Button { if let profile { Task { await model.tap(profile) } } } label: {
        Text(model.armed ? CardLinkOffModel.armedLabel : CardLinkOffModel.label)
      }
      .buttonStyle(CardLinkOffStyle(armed: model.armed))
      .disabled(profile == nil || sharing || model.busy)
      .accessibilityIdentifier("cardLink.off")
      .accessibilityHint(model.busy ? "Turning off your card link" : "")
      if let status = model.status {
        Text(status).csType(.bodyS).foregroundStyle(model.failed ? cs.neg : cs.mut)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityIdentifier("cardLink.status")
          .accessibilityAddTraits(.updatesFrequently)
      }
    }
  }
}

/// A destructive tertiary stays a word and a rule, with neg only while armed.
private struct CardLinkOffStyle: ButtonStyle {
  @Environment(\.cs) private var cs
  @Environment(\.isEnabled) private var enabled
  let armed: Bool
  func makeBody(configuration: Configuration) -> some View {
    ViewThatFits(in: .horizontal) {
      label(configuration, hugs: true)
      label(configuration, hugs: false)
    }
    .foregroundStyle(enabled ? (armed ? cs.neg : cs.ink) : cs.mut)
    .frame(minHeight: 44, alignment: .center)
    .contentShape(Rectangle())
    .background(configuration.isPressed && armed ? cs.neg.opacity(CSTokens.Alpha.a16) : .clear)
  }

  private func label(_ configuration: Configuration, hugs: Bool) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      configuration.label.csType(.nameS).lineLimit(hugs ? 1 : nil)
      Rectangle().fill(armed && enabled ? cs.neg : cs.mut).frame(height: 2)
    }
    .fixedSize(horizontal: hugs, vertical: false)
  }
}
