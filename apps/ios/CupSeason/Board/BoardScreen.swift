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
          Text("THE BOARD").font(CSFont.label).tracking(1.6).foregroundStyle(cs.pos)
          Text((store?.leagueName ?? "").uppercased()).font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText)
        }
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
              Text(store.loadingEarlier ? "Loading…" : "Earlier").font(CSFont.monoMediumBody).foregroundStyle(cs.mut)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .disabled(store.loadingEarlier)
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
        if store.loaded, store.digest == nil { withAnimation { proxy.scrollTo("board-end", anchor: .bottom) } }
      }
      .onChange(of: store.loaded) { _, loaded in
        if loaded, store.digest == nil { proxy.scrollTo("board-end", anchor: .bottom) }
      }
    }
  }

  /// `.composer` — "Message the league…" · 📣 (the Pro) · Send.
  private func composer(_ store: BoardStore) -> some View {
    HStack(spacing: 8) {
      TextField("Message the league…", text: $draft, axis: .vertical)
        .font(CSFont.body)
        .foregroundStyle(cs.ink)
        .lineLimit(1...4)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(minHeight: 44)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous)
          .stroke(composing ? cs.focus : cs.line, lineWidth: composing ? 2 : 1))
        .focused($composing)
        .submitLabel(.send)
      if store.isPro {
        Button { announcing = true } label: {
          Text("📣").font(.system(size: 18)).frame(minWidth: 44, minHeight: 44)
            .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Announce to the league")
      }
      Button { send(store) } label: {
        Text("Send").font(CSFont.button).foregroundStyle(cs.bg0)
          .padding(.horizontal, 18).frame(minHeight: 44)
          .background(cs.brand, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      }
      .buttonStyle(.plain)
      .disabled(sending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
    }
    .padding(.horizontal, 16).padding(.vertical, 10)
    .background(cs.bg0)
    .overlay(alignment: .top) { Rectangle().fill(cs.line).frame(height: 1) }
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
        SystemRow(text: BoardText.easeCaps(f.text, names: store.names))
      } else {
        CompactRoundRow(item: f, store: store)
      }
    case .announce: AnnounceRow(text: f.text, pinned: false)
    case .moment: MomentRow(text: BoardText.easeCaps(f.text, names: store.names))
    case .system:
      SystemRow(text: BoardText.easeCaps(f.text, names: store.names),
                opens: f.liveRoundId.map { id in { openScorecard(id) } })
    case .chat: ChatRow(item: f, store: store, links: links)
    }
  }
}

extension UUID: @retroactive Identifiable { public var id: UUID { self } }
