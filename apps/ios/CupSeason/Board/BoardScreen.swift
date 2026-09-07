// Cup Season — the board (audit 08 §1.2: `#boardFull` becomes a screen —
// the chat wants a keyboard-anchored list). `BoardScreen` is the full board
// with the composer; `BoardCompactList` is the room pane's `#feedList`.
//
// Both draw from one `BoardStore` per league: the pinned announcement, the
// quiet-day digest, date separators, and every row kind. The full board
// tells the round as a story card; the compact one as a reactable line.

import SwiftUI
import CSDesign
import CupSeasonKit

struct BoardScreen: View {
  @Environment(SessionStore.self) private var session
  @Environment(\.cs) private var cs
  let leagueId: UUID
  let links: BoardLinks
  @State private var store: BoardStore?
  @State private var draft = ""
  @State private var sending = false
  @State private var announcing = false
  @State private var scorecard: UUID?
  @FocusState private var composing: Bool

  init(leagueId: UUID, links: BoardLinks) { self.leagueId = leagueId; self.links = links }

  var body: some View {
    Group {
      if let store {
        content(store)
          .boardToasts(store)
          .safeAreaInset(edge: .bottom, spacing: 0) { composer(store) }
          .sheet(isPresented: $announcing) { AnnounceSheet(store: store) }
          .sheet(item: $scorecard) { id in ScorecardSheet(liveRoundId: id) }
          .refreshable { await store.load() }
      } else {
        ScrollView { BoardSkeleton().padding(20) }
      }
    }
    .background(cs.bg0)
    .navigationTitle("The board")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack(spacing: 1) {
          Text("The board").csType(.agate, caps: true).foregroundStyle(cs.ink)
          Text(store?.leagueName ?? "").csType(.agateS, caps: true).foregroundStyle(cs.mut)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
      }
    }
    .task(id: leagueId) {
      let s = makeBoardStore(leagueId: leagueId, session: session)
      store = s
      await s.load()
      await s.start()
    }
    .onDisappear { let s = store; Task { await s?.stop() } }
  }

  private func content(_ store: BoardStore) -> some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          if store.hasEarlier {
            Button {
              Task { await store.loadEarlier() }
            } label: {
              Text(store.loadingEarlier ? "Loading…" : "Earlier").csType(.nameS).foregroundStyle(cs.mut)
                .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(store.loadingEarlier)
            .accessibilityLabel("Load earlier posts")
          }
          if !store.loaded, store.loading { BoardSkeleton() }
          if let pin = store.pinnedIndex { AnnounceRow(text: store.items[pin].text, pinned: true) }
          if let lines = store.digest { DigestCard(lines: lines) }
          BoardRowsList(store: store, links: links, full: true, openScorecard: { scorecard = $0 })
          Color.clear.frame(height: 1).id("board-end")
        }
        .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 12)
      }
      .scrollDismissesKeyboard(.interactively)
      .onChange(of: store.items.last?.id) { _, _ in
        // force scrolls to the newest on open + fresh chat; otherwise the
        // reader's place is preserved (a reaction mid-scroll never yanks)
        if store.loaded, store.digest == nil { CSMotion.run { proxy.scrollTo("board-end", anchor: .bottom) } }
      }
      .onChange(of: store.loaded) { _, loaded in
        if loaded, store.digest == nil { proxy.scrollTo("board-end", anchor: .bottom) }
      }
    }
  }

  /// `.composer` — "Message the league…" · 📣 (the Pro) · Send. At the accessibility
  /// sizes the field takes the full width and the two buttons sit under it.
  private func composer(_ store: BoardStore) -> some View {
    A11yStack(alignment: .trailing, spacing: 8) {
      TextField("Message the league…", text: $draft, axis: .vertical)
        .accessibilityLabel("Message the league")
        .csType(.body)
        .foregroundStyle(cs.ink)
        .lineLimit(1...4)
        .padding(.horizontal, CSTokens.Space.s3).padding(.vertical, CSTokens.Space.s3)
        .frame(minHeight: 44)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        // §7.2 · no border; focus is the one 2px brand ring
        .overlay {
          if composing {
            RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous)
              .stroke(cs.brand, lineWidth: 2)
          }
        }
        .focused($composing)
        .submitLabel(.send)
        .frame(maxWidth: .infinity)
      HStack(spacing: 8) {
        if store.isPro {
          Button { announcing = true } label: {
            CSGlyph(.send, size: .row).foregroundStyle(cs.mut)
              .frame(minWidth: 44, minHeight: 44)
              .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Announce to the league")
        }
        // the board's one primary — and a DISABLED primary is never ember
        // (§7.1), which is why the opacity dodge is gone
        Button("Send") { send(store) }
          .buttonStyle(.csPrimary(busy: sending))
          .fixedSize(horizontal: true, vertical: false)
          .disabled(sending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          .accessibilityLabel("Send")
      }
    }
    .padding(.horizontal, 16).padding(.vertical, 10)
    .background(cs.bg0)
    .overlay(alignment: .top) { Rectangle().fill(cs.rule).frame(height: 1) }
  }

  private func send(_ store: BoardStore) {
    let v = draft
    draft = ""
    sending = true
    Task {
      if let back = await store.sendChat(v) { draft = back }
      sending = false
    }
  }
}

/// The room pane's `#feedList` — the same feed, compact rows.
struct BoardCompactList: View {
  @Environment(SessionStore.self) private var session
  @Environment(\.cs) private var cs
  let leagueId: UUID
  let links: BoardLinks
  @State private var store: BoardStore?
  @State private var scorecard: UUID?

  init(leagueId: UUID, links: BoardLinks) { self.leagueId = leagueId; self.links = links }

  var body: some View {
    Group {
      if let store {
        LazyVStack(alignment: .leading, spacing: 0) {
          if let pin = store.pinnedIndex { AnnounceRow(text: store.items[pin].text, pinned: true) }
          if let lines = store.digest { DigestCard(lines: lines) }
          if !store.loaded, store.loading { BoardSkeleton() }
          BoardRowsList(store: store, links: links, full: false, openScorecard: { scorecard = $0 })
        }
        .boardToasts(store)
        .sheet(item: $scorecard) { id in ScorecardSheet(liveRoundId: id) }
      } else {
        BoardSkeleton()
      }
    }
    .task(id: leagueId) {
      let s = makeBoardStore(leagueId: leagueId, session: session)
      store = s
      await s.load()
      await s.start()
    }
    .onDisappear { let s = store; Task { await s?.stop() } }
  }
}

/// The chronology: date separators and one row per item. The pinned
/// announcement is drawn by the caller and skipped here — never twice.
struct BoardRowsList: View {
  let store: BoardStore
  let links: BoardLinks
  let full: Bool
  let openScorecard: (UUID) -> Void

  var body: some View {
    let pin = store.pinnedIndex
    ForEach(Array(store.items.enumerated()), id: \.element.id) { i, f in
      if i != pin {   // pinned above — never twice (5142)
        if i == 0 || store.items[i - 1].dateLabel != f.dateLabel { DateSeparator(label: f.dateLabel) }
        row(f)
      }
    }
  }

  @ViewBuilder
  private func row(_ f: BoardItem) -> some View {
    switch f.kind {
    case .round:
      if full, let rid = f.roundId, let r = store.rounds[rid], r.gross != nil {
        RoundStoryCard(item: f, round: r, store: store, links: links)
      } else if full {
        SystemRow(text: BoardText.easeCaps(f.text, names: store.names), item: f, store: store)
      } else {
        CompactRoundRow(item: f, store: store)
      }
    case .announce: AnnounceRow(text: f.text, pinned: false)
    case .moment: MomentRow(text: BoardText.easeCaps(f.text, names: store.names), item: f, store: store)
    case .system:
      SystemRow(text: BoardText.easeCaps(f.text, names: store.names),
                opens: f.liveRoundId.map { id in { openScorecard(id) } },
                item: f, store: store)
    case .chat: ChatRow(item: f, store: store, links: links)
    }
  }
}

extension UUID: @retroactive Identifiable { public var id: UUID { self } }
