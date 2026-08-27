// Cup Season — the season album (photos arc 2; index.html `renderAlbum`
// 16456–16505): every league round photo in one grid, newest first, month
// dividers, one batched signing call, tap opens the round receipt.

import SwiftUI
import CSDesign
import CupSeasonKit

struct AlbumScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  let leagueId: UUID

  @State private var rows: [RoundRow] = []
  @State private var mates: [UUID: LeagueMate] = [:]
  @State private var state: LoadState = .opening
  @State private var open: RoundRow?
  enum LoadState { case opening, empty, ready }

  private static let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

  var body: some View {
    ScrollView {
      switch state {
      case .opening:
        Fine("Opening the album…").padding(20)
      case .empty:
        Fine("Photos land here when rounds carry them — add one from the Post card.").padding(20)
      case .ready:
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
          ForEach(sections, id: \.month) { section in
            Section {
              ForEach(section.rows) { r in cell(r) }
            } header: {
              Text(section.title).csEyebrow(cs.dimText)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10).padding(.bottom, 2)
            }
          }
        }
        .padding(20)
      }
    }
    .background(cs.bg0)
    .navigationTitle("Album")
    .navigationBarTitleDisplayMode(.inline)
    .sliceToastHost()
    .task { await load() }
    .sheet(item: $open) { r in
      RoundReceiptSheet(roundId: r.id, seed: seed(r))
    }
  }

  private struct MonthSection { let month: String; let title: String; let rows: [RoundRow] }

  /// month dividers, newest first
  private var sections: [MonthSection] {
    var out: [MonthSection] = []
    for r in rows {
      let mo = String((r.played_on ?? "").prefix(7))
      if out.last?.month != mo {
        let parts = mo.split(separator: "-")
        let m = parts.count == 2 ? (Int(parts[1]) ?? 0) : 0
        let name = (1...12).contains(m) ? Self.months[m - 1] : ""
        out.append(MonthSection(month: mo, title: "\(name) \(parts.first ?? "")", rows: [r]))
      } else {
        out[out.count - 1] = MonthSection(month: mo, title: out[out.count - 1].title, rows: out[out.count - 1].rows + [r])
      }
    }
    return out
  }

  private func nameOf(_ pid: UUID?) -> String { pid.flatMap { mates[$0]?.displayName } ?? "A golfer" }

  private func seed(_ r: RoundRow) -> ReceiptSeed {
    r.seed(marker: r.profile_id.flatMap { mates[$0]?.marker }, isMine: r.profile_id == store.session?.user.id)
  }

  private func cell(_ r: RoundRow) -> some View {
    Button { open = r } label: {
      Color.clear
        .aspectRatio(1, contentMode: .fit)
        .overlay {
          AsyncImage(url: r.photo_url) { phase in
            if case .success(let img) = phase { img.resizable().scaledToFill() } else { cs.bg2 }
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(cs.line2, lineWidth: 1))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(nameOf(r.profile_id)) — \(r.gross.map(String.init) ?? "") at \(r.course_label ?? "the course"), \(r.played_on ?? "")")
  }

  private func load() async {
    let repo = RoundsRepository()
    do {
      let m = try await repo.leagueMates(leagueId: leagueId)
      mates = Dictionary(uniqueKeysWithValues: m.map { ($0.profileId, $0) })
      let ids = m.map(\.profileId)
      guard !ids.isEmpty else { state = .empty; return }
      let got = try await repo.albumRounds(profileIds: ids)
      await ReceiptCache.shared.put(got.map { seed($0) })
      rows = got
      state = got.isEmpty ? .empty : .ready
    } catch {
      state = .empty
    }
  }
}
