// Cup Season — the founding tag (D102; the web's `.ftag` 1585).
// Gold because it is earned; mono because it is a fact on the record.

import SwiftUI
import CSDesign
import CupSeasonKit

struct FoundingTag: View {
  @Environment(\.cs) private var cs
  let badge: FoundingBadge?

  var body: some View {
    if let badge {
      Text(badge.label)
        .font(CSFont.label).tracking(1.2).textCase(.uppercase)
        .foregroundStyle(cs.gold)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .overlay(Capsule().stroke(cs.gold.opacity(0.55), lineWidth: 1))
        .accessibilityLabel(badge.accessibilityLabel)
        .fixedSize()
    }
  }
}

#Preview("tags") {
  VStack(alignment: .leading, spacing: 8) {
    FoundingTag(badge: .founder)
    FoundingTag(badge: .member)
    FoundingTag(badge: nil)
  }
  .padding().csTheme()
}
