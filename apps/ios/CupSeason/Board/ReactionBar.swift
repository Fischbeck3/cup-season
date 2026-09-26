// Cup Season — `socialBar`: the reaction chips, the report control, and the
// comment thread on round posts.
//
// **THE TRAY IS GONE (D310).** Six reactions needed one: a ≥350 ms hold on the
// quick chip opened a palette holding the five that did not fit on the row,
// exclusively, with a `held` flag so the hold did not also toggle. **Four fit
// on the row.** So the palette, the hold, the flag and `store.openTray` all
// retire, and a reaction is one tap at one size, everywhere — which is a
// simpler product than the one the six required.
//
//   · all four are always on the face, in CANON order — never arrival order,
//     so the row is the same row every time you look at it
//   · a row nobody has touched shows the quick token's OUTLINE with no figure:
//     an invitation, which cannot be read as a tally somebody already left
//   · every write is optimistic and reverts with the web's toast on failure
//   · chat lines react but don't thread; the thread's open state lives in the
//     store so a refresh never collapses the one you're typing in

import SwiftUI
import CSDesign
import CupSeasonKit

struct ReactionBar: View {
  @Environment(\.cs) private var cs
  let item: BoardItem
  @Bindable var store: BoardStore
  @State private var draft = ""
  /// D324 · the reveal is LOCAL, like the wire's — one row opening its own
  /// four needs none of the exclusive-tray machinery D310 deleted.
  @State private var open = false
  @State private var reporting = false

  private var threadOpen: Bool { store.openThreads.contains(item.id) }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      CSRule()
      FlowRow(spacing: 6) {
        // D365 · **the reaction menu is gone.** The board draws the one
        // applause control the wire draws — glyph and count — beside the
        // report control and the thread. Nothing else is offered.
        ApplauseControl(state: Applause.state(item.reactions)) {
          Task { await store.toggleReaction(item.id, Applause.key) }
        }
        if item.postId != nil {
          // never a flag — `LINT-28` reserves the pennant to the tab band and
          // the app icon, and this one was a report control wearing it
          iconButton(.more, label: "Report this post", expanded: false) { reporting = true }
        }
        if item.threads {
          Button {
            if threadOpen { store.openThreads.remove(item.id) } else { store.openThreads.insert(item.id) }
          } label: {
            HStack(spacing: CSTokens.Space.s1) {
              CSGlyph(.comment, size: .inline)
              if item.roundId == nil && !item.comments.isEmpty { Text("\(item.comments.count)").csType(.agateS) }
            }
            .foregroundStyle(cs.mut)
            .padding(.horizontal, CSTokens.Space.s3).frame(minWidth: 36, minHeight: 28)
            .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(item.roundId != nil || item.comments.isEmpty ? "Comments" : "Comments, \(item.comments.count)")
          .accessibilityHint(threadOpen ? "Hides the thread" : "Shows the thread")
          .accessibilityAddTraits(threadOpen ? [.isSelected] : [])
        }
      }
      if item.threads && threadOpen {
        if let roundId = item.roundId {
          RoundConversation(roundId: roundId)
        } else { thread }
      }
    }
    .padding(.top, 6)
    .sheet(isPresented: $reporting) { ReportSheet(item: item, store: store) }
  }

  // MARK: the report control

  private func iconButton(_ glyph: CSGlyph.Name, label: String, expanded: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      CSGlyph(glyph, size: .inline)
        .frame(minWidth: 36, minHeight: 28)
        .foregroundStyle(cs.mut)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityAddTraits(expanded ? [.isSelected] : [])
  }

  // MARK: thread (`.cthread`)

  private var thread: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(item.comments) { c in
        (Text(c.who + " ").font(CSType.font(.name)).foregroundStyle(cs.ink)
          + Text(c.text).font(CSType.font(.body)).foregroundStyle(cs.ink))
          .fixedSize(horizontal: false, vertical: true)
      }
      HStack(spacing: 8) {
        TextField("Say something…", text: $draft)
          .accessibilityLabel("Comment")
          .csType(.body)
          .foregroundStyle(cs.ink)
          .padding(.horizontal, CSTokens.Space.s3)
          .frame(minHeight: 44)
          // §7.2 · a field has no border
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .submitLabel(.send)
          .onSubmit(send)
        Button("Send", action: send).buttonStyle(.csTertiary(.content))
      }
    }
    .padding(.top, 4)
  }

  private func send() {
    // clear BEFORE sending: the echo re-renders synchronously
    let v = draft
    draft = ""
    Task { await store.sendComment(item.id, v) }
  }
}

/// A wrapping row of chips (the web's `.rxbar` is `flex-wrap`).
struct FlowRow: Layout {
  var spacing: CGFloat = 6

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let width = proposal.width ?? .infinity
    var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
    for s in subviews {
      let sz = s.sizeThatFits(.unspecified)
      if x > 0, x + sz.width > width { x = 0; y += rowH + spacing; rowH = 0 }
      x += sz.width + spacing
      rowH = max(rowH, sz.height)
    }
    return CGSize(width: width == .infinity ? x : width, height: y + rowH)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
    for s in subviews {
      let sz = s.sizeThatFits(.unspecified)
      if x > bounds.minX, x + sz.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
      s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
      x += sz.width + spacing
      rowH = max(rowH, sz.height)
    }
  }
}
