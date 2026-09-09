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

  /// Has anybody said anything at all on this item?
  private var untouched: Bool { given.isEmpty }
  /// What people actually gave, in CANON order — never arrival order.
  private var given: [CSReactions.Reaction] {
    CSReactions.all.filter { (item.reactions[$0.key]?.n ?? 0) > 0 }
  }
  /// What the `+` reveals.
  private var rest: [CSReactions.Reaction] {
    CSReactions.all.filter { (item.reactions[$0.key]?.n ?? 0) == 0 }
  }
  private var threadOpen: Bool { store.openThreads.contains(item.id) }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      CSRule()
      FlowRow(spacing: 6) {
        // **D324 · THE BOARD GETS THE WIRE'S ROW.** D310 kept all four on the
        // face here, on the argument that a board is a room you went to. Seen
        // rendered that was wrong, and worse than the wire ever was: these are
        // FILLED tiles, so four of them plus the report and the comment is six
        // grey boxes under every post. The owner had already said what he
        // thinks of the pattern; it just had not been carried across.
        //
        // What is GIVEN stays on the face — those are facts about what
        // happened. The rest wait behind the `+`, and picking one closes it.
        ForEach(given) { r in chip(r.token) }
        if open {
          ForEach(rest) { r in chip(r.token, closesOnTap: true) }
        } else if !rest.isEmpty {
          iconButton(.plus, label: given.isEmpty ? "React to this round" : "More reactions",
                     expanded: false) {
            CSHaptic.selection()
            CSMotion.run(CSMotion.tick) { open = true }
          }
          .accessibilityActions {
            ForEach(rest) { r in
              Button(r.label) { Task { await store.toggleReaction(item.id, r.key) } }
            }
          }
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
              if !item.comments.isEmpty { Text("\(item.comments.count)").csType(.agateS) }
            }
            .foregroundStyle(cs.mut)
            .padding(.horizontal, CSTokens.Space.s3).frame(minWidth: 36, minHeight: 28)
            .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(item.comments.isEmpty ? "Comments" : "Comments, \(item.comments.count)")
          .accessibilityHint(threadOpen ? "Hides the thread" : "Shows the thread")
          .accessibilityAddTraits(threadOpen ? [.isSelected] : [])
        }
      }
      if item.threads && threadOpen { thread }
    }
    .padding(.top, 6)
    .sheet(isPresented: $reporting) { ReportSheet(item: item, store: store) }
  }

  // MARK: chips

  /// One token. **The count is drawn only when it is a count** — an untouched
  /// row shows four outlines and no figures, which is the whole of D310: a
  /// glyph with a phantom zero beside it reads as a reaction somebody left.
  private func chip(_ t: CSReactionToken, closesOnTap: Bool = false) -> some View {
    let r = item.reactions[t.key] ?? ReactionState()
    let who = r.who.joined(separator: ", ")
    let title = t.word + (who.isEmpty ? "" : " — " + who)
    return Button {
      CSHaptic.selection()
      Task { await store.toggleReaction(item.id, t.key) }
      if closesOnTap { CSMotion.run(CSMotion.tick) { open = false } }
    } label: {
      // the CHIP is 28pt (§7.2) and the TARGET is 44 — the frame goes outside
      // the fill, or a row of reactions reads as a row of grey tiles. A
      // reaction you gave INVERTS to the panel rather than filling with ember,
      // because a reaction is not live — and under a look that panel is the
      // livery's second colour (D313), so your own reactions wear it.
      HStack(spacing: CSTokens.Space.s1) {
        CSReactionGlyph(t, size: .row)
        if r.n > 0 { Text("\(r.n)").csType(.agateS) }
      }
      .padding(.horizontal, CSTokens.Space.s3)
      .frame(minWidth: 36, minHeight: 28)
      .foregroundStyle(r.me ? cs.panelInk : (untouched ? cs.dimText : cs.mut))
      .background(r.me ? cs.panel : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
      .frame(minWidth: 44, minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityValue(r.me ? "on" : "off")
    .accessibilityAddTraits(.isToggle)
  }

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
