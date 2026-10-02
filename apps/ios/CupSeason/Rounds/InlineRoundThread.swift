// Cup Season — under a round, on Home or the board: its newest comment, or its conversation (D405).
//
// The owner's own first use of it: *"if I click comment it takes me to a new
// page that gets cluttered and impersonal."* The conversation is where the round
// is read. Collapsed, the newest comment shows under the card — *"Blake: Did the
// putt on 18 drop?"* — so the banter is visible before a tap; the comment door
// opens the whole thread directly beneath the round, composer at the foot. The
// receipt keeps the full page, and it is still where a notice opens.

import SwiftUI
import CSDesign
import CupSeasonKit

struct InlineRoundThread: View {
  @Environment(\.cs) private var cs
  let roundId: UUID
  let door: RoundSocialDoor?
  let isOpen: Bool
  var reloadKey = 0
  /// the surface's own prefix for the accessibility ids (`home.round`, `board.round`)
  var idPrefix = "round"
  let open: () -> Void

  var body: some View {
    if isOpen {
      RoundConversation(roundId: roundId, style: .inline, autoFocus: (door?.commentCount ?? 0) == 0,
                        reloadKey: reloadKey)
        .padding(.leading, CSTokens.Space.s3)
        .overlay(alignment: .leading) {
          Rectangle().fill(cs.mut.opacity(CSTokens.Alpha.a16)).frame(width: 1)
        }
        .padding(.top, CSTokens.Space.s1)
        // the container is its own element: an identifier set straight on it would
        // replace every child's (the draft, Send, each comment), the outer one wins
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(idPrefix).thread")
    } else if let line = door?.previewLine {
      Button(action: open) {
        Text(styled(line)).csType(.bodyS).lineLimit(1)
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Latest comment. \(line)")
      .accessibilityHint("Opens the conversation here")
      // per round: a screen of rounds has several, and a test (or a switch control) must be able to say which
      .accessibilityIdentifier("\(idPrefix).preview.\(roundId.uuidString)")
    }
  }

  /// the name in ink, what they said in muted ink: a quiet line, not a second headline
  private func styled(_ line: String) -> AttributedString {
    var out = AttributedString(line)
    out.foregroundColor = cs.mut
    if let colon = line.firstIndex(of: ":"), let range = out.range(of: String(line[...colon])) {
      out[range].foregroundColor = cs.ink
    }
    return out
  }
}
