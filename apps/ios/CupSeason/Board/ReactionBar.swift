// Cup Season — `socialBar` (index.html 4715–4740): the reaction chips, the
// ＋ tray, the report flag, and the comment thread on round posts.
//
//   · the 🔥 heater is the one-thumb chip, always on the card face (F11 3.1);
//     tap toggles, a ≥350 ms hold opens the tray without also toggling
//   · the tray is exclusive — opening one closes any other (store.openTray)
//   · a tray pick that is already mine is a no-op
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
  @State private var held = false
  @State private var draft = ""
  @State private var reporting = false

  private var present: [String] {
    CSReactions.all.map(\.emoji).filter { (item.reactions[$0]?.n ?? 0) > 0 }
  }
  private var trayOpen: Bool { store.openTray == item.id }
  private var threadOpen: Bool { store.openThreads.contains(item.id) }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Rectangle().fill(cs.line).frame(height: 1)
      FlowRow(spacing: 6) {
        ForEach(present, id: \.self) { e in chip(e, quick: e == CSReactions.quick) }
        if !present.contains(CSReactions.quick) { chip(CSReactions.quick, quick: true, bare: true) }
        iconButton(trayOpen ? "minus" : "plus", label: "More reactions", expanded: trayOpen) {
          store.openTray = trayOpen ? nil : item.id
        }
        if item.postId != nil {
          Button { reporting = true } label: {
            Text("⚑").font(CSFont.monoSmall).frame(minWidth: 36, minHeight: 36)
              .foregroundStyle(cs.mut)
              .background(cs.bg2, in: Capsule()).overlay(Capsule().stroke(cs.line2, lineWidth: 1))
              .a11yHitSlop(vertical: 4, horizontal: 4)   // 36pt chip, 44pt target
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Report this post")
        }
        if item.threads {
          Button {
            if threadOpen { store.openThreads.remove(item.id) } else { store.openThreads.insert(item.id) }
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "bubble.left").font(.system(size: 13, weight: .regular))
              if !item.comments.isEmpty { Text("\(item.comments.count)").font(CSFont.monoSmall.weight(.semibold)) }
            }
            .foregroundStyle(cs.mut)
            .padding(.horizontal, 10).frame(minWidth: 36, minHeight: 36)
            .background(cs.bg2, in: Capsule()).overlay(Capsule().stroke(cs.line2, lineWidth: 1))
            .a11yHitSlop(vertical: 4, horizontal: 4)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(item.comments.isEmpty ? "Comments" : "Comments, \(item.comments.count)")
          .accessibilityHint(threadOpen ? "Hides the thread" : "Shows the thread")
          .accessibilityAddTraits(threadOpen ? [.isSelected] : [])
        }
      }
      if trayOpen { tray }
      if item.threads && threadOpen { thread }
    }
    .padding(.top, 6)
    .sheet(isPresented: $reporting) { ReportSheet(item: item, store: store) }
  }

  // MARK: chips

  private func chip(_ e: String, quick: Bool, bare: Bool = false) -> some View {
    let r = item.reactions[e] ?? ReactionState()
    let who = r.who.joined(separator: ", ")
    let title = CSReactions.label(e) + (who.isEmpty ? "" : " — " + who)
    return Button {
      if held { held = false; return }   // the hold already opened the tray — don't also toggle
      CSHaptic.selection()
      Task { await store.toggleReaction(item.id, e) }
    } label: {
      HStack(spacing: bare ? 0 : 4) {
        Text(e).font(.system(size: 15))
        if !bare { Text("\(r.n)").font(CSFont.monoSmall.weight(.semibold)) }
      }
      .padding(.horizontal, quick ? 14 : 10)
      .frame(minWidth: quick ? 44 : 36, minHeight: quick ? 44 : 36)
      .foregroundStyle(r.me ? cs.bg0 : cs.mut)
      .background(r.me ? cs.brand : cs.bg2, in: Capsule())
      .overlay(Capsule().stroke(r.me ? cs.brand : cs.line2, lineWidth: 1))
      .a11yHitSlop(vertical: quick ? 0 : 4, horizontal: quick ? 0 : 4)
    }
    .buttonStyle(.plain)
    .simultaneousGesture(quick ? LongPressGesture(minimumDuration: 0.35).onEnded { _ in
      held = true
      store.openTray = item.id
    } : nil)
    .accessibilityLabel(title)
    .accessibilityValue(r.me ? "on" : "off")
    .accessibilityHint(quick ? "Double tap to toggle, or use the More reactions action" : "")
    .accessibilityAction(named: "More reactions") { store.openTray = item.id }
  }

  private func iconButton(_ symbol: String, label: String, expanded: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: 13, weight: .medium))
        .frame(minWidth: 36, minHeight: 36)
        .foregroundStyle(cs.mut)
        .background(cs.bg2, in: Capsule()).overlay(Capsule().stroke(cs.line2, lineWidth: 1))
        .a11yHitSlop(vertical: 4, horizontal: 4)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityAddTraits(expanded ? [.isSelected] : [])
  }

  // MARK: tray (`.rxpalette`)

  private var tray: some View {
    HStack(spacing: 4) {
      ForEach(CSReactions.all) { r in
        Button {
          CSHaptic.selection()
          Task { await store.pickReaction(item.id, r.emoji) }
        } label: {
          Text(r.emoji).font(.system(size: 22)).frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(r.label)
      }
    }
    .padding(.horizontal, 6)
    .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
    .transition(.opacity.combined(with: .move(edge: .top)))
  }

  // MARK: thread (`.cthread`)

  private var thread: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(item.comments) { c in
        (Text(c.who + " ").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
          + Text(c.text).font(CSFont.subhead).foregroundStyle(cs.ink))
          .fixedSize(horizontal: false, vertical: true)
      }
      HStack(spacing: 8) {
        TextField("Talk your talk…", text: $draft)
          .accessibilityLabel("Comment")
          .font(CSFont.subhead.weight(.medium))
          .foregroundStyle(cs.ink)
          .padding(.horizontal, 12)
          .frame(minHeight: 44)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
          .submitLabel(.send)
          .onSubmit(send)
        Button("Send", action: send)
          .font(CSFont.monoMediumBody)
          .foregroundStyle(cs.ink)
          .padding(.horizontal, 12).frame(minHeight: 44)
          .background(cs.bg2, in: Capsule()).overlay(Capsule().stroke(cs.line2, lineWidth: 1))
          .buttonStyle(.plain)
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
