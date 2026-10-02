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
  /// D405 · a round post's door: how many comments, and the newest
  private var door: RoundSocialDoor? { item.roundId.flatMap { store.roundDoors[$0] } }
  private var commentCount: Int { item.roundId != nil ? (door?.commentCount ?? 0) : item.comments.count }

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
        if item.canReport(viewer: store.profileId) {
          // never a flag — `LINT-28` reserves the pennant to the tab band and
          // the app icon, and this one was a report control wearing it.
          // N4-065 · the "···" chip is what it looks like, a More menu, and the
          // report is an item in it that says so — not a bare grey chip whose
          // one meaning was hidden until it opened a sheet
          Menu {
            Button("Report this post") { reporting = true }
          } label: {
            CSGlyph(.more, size: .inline)
              .frame(minWidth: 36, minHeight: 28)
              .foregroundStyle(cs.mut)
              .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
              .frame(minWidth: 44, minHeight: 44)
              .contentShape(Rectangle())
          }
          .accessibilityLabel("More")
        }
        if item.threads {
          Button {
            if threadOpen { store.openThreads.remove(item.id) } else { openThread() }
          } label: {
            HStack(spacing: CSTokens.Space.s1) {
              CSGlyph(.comment, size: .inline)
              if commentCount > 0 { Text("\(commentCount)").csType(.agateS) }
            }
            .foregroundStyle(cs.mut)
            .padding(.horizontal, CSTokens.Space.s3).frame(minWidth: 36, minHeight: 28)
            .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(commentCount == 0 ? "Comments" : "Comments, \(commentCount)")
          .accessibilityHint(threadOpen ? "Hides the thread" : "Shows the thread")
          .accessibilityAddTraits(threadOpen ? [.isSelected] : [])
        }
      }
      if item.threads {
        if let roundId = item.roundId {
          // D405 · the round's one conversation, in line: the newest comment
          // beneath the post until it is opened, then the thread itself
          InlineRoundThread(roundId: roundId, door: door, isOpen: threadOpen, reloadKey: store.socialLoads,
                            idPrefix: "board.round", open: { openThread() })
        } else if threadOpen { thread }
      }
    }
    .padding(.top, 6)
    .sheet(isPresented: $reporting) { ReportSheet(item: item, store: store) }
    // the door follows its conversation, whichever view of it spoke last (see `followsThread`)
    .followsThread(item.roundId) { round, count, newest in store.noteThread(round, count: count, newest: newest) }
  }

  /// Opening a post's thread: an empty conversation puts the cursor in its composer.
  private func openThread() {
    if let round = item.roundId { CommentDrafts.talk(round).autoFocused = false }
    store.openThreads.insert(item.id)
  }

  // MARK: thread (`.cthread`)

  private var thread: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(item.comments) { c in
        CommentSafetyRow(name: c.who, text: c.text, author: c.author,
                         target: c.persisted && c.author != store.profileId
                           ? CommentSafety(id: c.id, kind: .comment, author: c.author, name: c.who) : nil,
                         refresh: { await store.load() })
      }
      HStack(spacing: 8) {
        TextField("Say something…", text: $draft)
          .accessibilityLabel("Comment")
          .csType(.body)
          .foregroundStyle(cs.ink)
          .padding(.horizontal, CSTokens.Space.s3)
          .frame(minHeight: 44)
          // Q46 · the field keeps its visible mut edge
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .csFieldEdge()
          .submitLabel(.send)
          .onSubmit(send)
        Button("Send", action: send).buttonStyle(.csTertiary(.content))
      }
    }
    .padding(.top, 4)
  }

  private func send() {
    // clear BEFORE sending: the echo re-renders synchronously. D403 · and a
    // refusal hands the words back, as the chat composer's does.
    let v = draft
    draft = ""
    Task { if let back = await store.sendComment(item.id, v) { draft = back } }
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
