// Cup Season — the season album (photos arc 2; index.html `renderAlbum`
// 16456–16505): every league round photo in one grid, newest first, month
// dividers, one batched signing call, tap opens the round receipt.
//
// F16 · **A FAILED READ IS NEVER AN EMPTY ALBUM.** Both reads used to land in
// one `catch` that set `.empty`, whose sentence sends the golfer off to add
// photographs — so a dropped signal told him his memories were not there.
// The album now knows six things apart: loading, a read that answered with
// nothing, a read that failed, a read that failed for want of a signal, the
// retry that lands, and a refresh that fails with photographs already up —
// which keeps them up and says it could not refresh.

import SwiftUI
import CSDesign
import CupSeasonKit

/// F16 · what the album knows, and nothing it does not. The reads are
/// injected so the six states are tests rather than hopes.
@MainActor
@Observable
final class AlbumModel {
  enum Phase: Equatable {
    case loading
    /// the reads answered, and no round in this league carries a photograph
    case empty
    case ready
    /// nothing is on screen and the read failed
    case failed(offline: Bool)
  }
  /// A refresh that failed while photographs were on screen: they stay, and
  /// the page says it could not refresh.
  struct RefreshNote: Equatable { let offline: Bool; let asOf: Date }

  typealias Read = @MainActor (UUID) async throws -> (mates: [LeagueMate], rows: [RoundRow])

  let leagueId: UUID
  private(set) var rows: [RoundRow] = []
  private(set) var mates: [UUID: LeagueMate] = [:]
  private(set) var phase: Phase = .loading
  /// the failed read's why, in the product's words (`HumanError`) — a dropped
  /// signal says so; a refusal says so
  private(set) var why: String?
  private(set) var refreshNote: RefreshNote?
  private var loadedAt: Date?
  private let read: Read
  private var request = UUID()

  init(leagueId: UUID, read: Read? = nil) {
    self.leagueId = leagueId
    self.read = read ?? { league in
      let repo = RoundsRepository()
      let m = try await repo.leagueMates(leagueId: league)
      let ids = m.map(\.profileId)
      // no golfer in the league is an answer, not a failure
      guard !ids.isEmpty else { return (m, []) }
      return (m, try await repo.albumRounds(profileIds: ids))
    }
  }

  func load() async {
    let token = UUID(); request = token
    // a retry from nothing shows the loading state again; a refresh keeps
    // whatever is on screen while it asks
    if rows.isEmpty { phase = .loading }
    do {
      let got = try await read(leagueId)
      guard request == token else { return }
      mates = Dictionary(got.mates.map { ($0.profileId, $0) }, uniquingKeysWith: { a, _ in a })
      rows = got.rows
      phase = got.rows.isEmpty ? .empty : .ready
      refreshNote = nil
      why = nil
      loadedAt = Date()
    } catch is CancellationError {
      return
    } catch {
      guard request == token else { return }
      let offline = Self.isOffline(error)
      if rows.isEmpty {
        phase = .failed(offline: offline)
        // no signal is said as that, deterministically: a bare transport error
        // carries no sentence of its own for `HumanError` to read
        why = offline ? AlbumCopy.offlineWhy : HumanError.text(error)
        refreshNote = nil
      } else {
        refreshNote = RefreshNote(offline: offline, asOf: loadedAt ?? Date())
      }
    }
  }

  /// A read that failed for want of a signal, as opposed to one the server
  /// refused — `HumanError.isOffline`, the one rule Home's stale line reads too.
  static func isOffline(_ error: Error) -> Bool { HumanError.isOffline(error) }
}

enum AlbumCopy {
  static let loading = "Opening the album…"
  /// D293 · the composer is no longer the only door: a round you already
  /// posted takes a photograph from its own receipt.
  static let empty = "Photos land here when rounds carry them — open a round and add one."
  /// the desk's words (`renderAlbum`): the head, then one line of why
  static let failedHead = "The album didn’t load"
  static let retry = "Try again"
  /// the product's own sentence for a dropped signal (`HumanError`'s words)
  static let offlineWhy = "Connection hiccup \u{2014} check your signal and try again."
  /// a refresh that failed with photographs up: they stay, and this says so
  static let refreshFailed = "The album didn’t refresh."
}

struct AlbumScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  let leagueId: UUID

  @State private var model: AlbumModel
  @State private var open: RoundRow?

  init(leagueId: UUID) {
    self.leagueId = leagueId
    _model = State(initialValue: AlbumModel(leagueId: leagueId))
  }

  private static let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

  var body: some View {
    ScrollView {
      switch model.phase {
      case .loading:
        Fine(AlbumCopy.loading).padding(20)
          .accessibilityIdentifier("album.loading")
      case .empty:
        Fine(AlbumCopy.empty).padding(20)
          .accessibilityIdentifier("album.empty")
      case .failed(let offline):
        // L-32 · a failed read ends in a move, and it is never dressed as an
        // empty one: one lead line, one body line, and Try again.
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          Text(AlbumCopy.failedHead)
            .csType(.lead).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
          // the why: offline reads as a dropped signal, a refusal as itself
          Text(model.why ?? HumanError.text(URLError(.unknown))).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          CSDoor(.primary(AlbumCopy.retry) { Task { await load() } })
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(offline ? "album.offline" : "album.failed")
      case .ready:
        VStack(alignment: .leading, spacing: 0) {
          if let note = model.refreshNote { refreshLine(note) }
          grid
        }
      }
    }
    .background(cs.bg0)
    .navigationTitle("Album")
    .navigationBarTitleDisplayMode(.inline)
    .sliceToastHost()
    .task { await load() }
    .refreshable { await load() }
    .sheet(item: $open) { r in
      RoundReceiptSheet(roundId: r.id, seed: seed(r))
    }
  }

  /// F16 · a refresh that failed keeps the photographs up and says so, with
  /// the way to ask again. Offline, it reads the product's stale line.
  private func refreshLine(_ note: AlbumModel.RefreshNote) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      if note.offline {
        CSStale(asOf: note.asOf)
      } else {
        Text(AlbumCopy.refreshFailed).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      CSDoor(.link(AlbumCopy.retry) { Task { await load() } })
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20).padding(.top, 20)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("album.refreshFailed")
  }

  private var grid: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
      ForEach(sections, id: \.month) { section in
        Section {
          ForEach(section.rows) { r in cell(r) }
        } header: {
          Text(section.title).csEyebrow(cs.mut)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10).padding(.bottom, 2)
        }
      }
    }
    .padding(20)
  }

  private struct MonthSection { let month: String; let title: String; let rows: [RoundRow] }

  /// month dividers, newest first
  private var sections: [MonthSection] {
    var out: [MonthSection] = []
    for r in model.rows {
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

  private func nameOf(_ pid: UUID?) -> String { pid.flatMap { model.mates[$0]?.displayName } ?? "A golfer" }

  private func seed(_ r: RoundRow) -> ReceiptSeed {
    r.seed(marker: r.profile_id.flatMap { model.mates[$0]?.marker }, isMine: r.profile_id == store.session?.user.id)
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
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(nameOf(r.profile_id)) — \(r.gross.map(String.init) ?? "") at \(r.course_label ?? "the course"), \(r.played_on ?? "")")
  }

  private func load() async {
    await model.load()
    if model.phase == .ready { await ReceiptCache.shared.put(model.rows.map { seed($0) }) }
  }
}
