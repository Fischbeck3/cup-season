#if DEBUG
import SwiftUI
import CSDesign
import CupSeasonKit

/// Illustrative data only; actions prove the distinct destinations without server reads.
/// D361 · `-cs_dev_photo_stability` — the owner's case, made deterministic:
/// TWO ADJACENT PHOTO ROUNDS on one store whose fetcher answers late, in the
/// order the launch asks for, and can be told to miss. No network.
///
///   -cs_dev_photo_order reversed   the second round's picture lands first
///   -cs_dev_photo_fail second      the second round's REFRESH misses (transient)
///   -cs_dev_photo_gone second      the second round's refresh says the object is gone
///   -cs_dev_photo_fail_first first the first round's FIRST fetch misses; the retry lands
///   -cs_dev_photo_unsignable second the second round's re-sign yields no credential (transient)
///
/// The fixture's own toolbar re-signs (new URLs, as a Home refresh does) and
/// removes the second attachment, and prints how many fetches went out.
@MainActor final class HomePhotoStabilityStub {
  static let shared = HomePhotoStabilityStub()
  let store: HomePhotoStore
  var round = 0
  private static let args = ProcessInfo.processInfo.arguments
  private static func arg(_ k: String) -> String? {
    guard let i = args.firstIndex(of: k), i + 1 < args.count else { return nil }
    return args[i + 1]
  }
  /// the one stand-in photograph in the build (`ReceiptPhotoDev.image`, LINT-04's
  /// named exemption), served for both rounds — the fixture proves the STATES,
  /// and two copies of one picture are still two pictures.
  static func picture(_ tone: CGFloat) -> Data { ReceiptPhotoDev.image.pngData()! }
  init() {
    let order = Self.arg("-cs_dev_photo_order") ?? "normal"
    let fail = Self.arg("-cs_dev_photo_fail")
    let gone = Self.arg("-cs_dev_photo_gone")
    let failFirst = Self.arg("-cs_dev_photo_fail_first")
    let first = Self.picture(0.82), second = Self.picture(0.58)
    var seen: [String: Int] = [:]
    store = HomePhotoStore(fetch: { url in
      // which round, and which fetch of it (the refresh is the second)
      let which = url.lastPathComponent.contains("first") ? "first" : "second"
      let n = await MainActor.run { seen[which, default: 0] += 1; return seen[which]! }
      // slow enough for a UI test to watch the frame; the refresh answers faster
      let slow: UInt64 = n >= 2 ? 1500 : 5000, fast: UInt64 = 600
      let delayMs: UInt64 = (which == "first") == (order == "reversed") ? slow : fast
      try? await Task.sleep(nanoseconds: delayMs * 1_000_000)
      if n == 1, which == failFirst { return .transient }
      if n >= 2, which == fail { return .transient }
      if n >= 2, which == gone { return .gone }
      return .data(which == "first" ? first : second)
    })
  }
}

struct HomeNoPhotoFixture: View {
  @Environment(\.cs) private var cs
  @State private var destination: String?
  @State private var reactions: [Int: [String: ReactionState]] = [:]
  @State private var signing = 0
  @State private var removedSecond = false
  private var unsignable: String? { ProcessInfo.processInfo.arguments.firstIndex(of: "-cs_dev_photo_unsignable").map { ProcessInfo.processInfo.arguments[$0 + 1] } }
  private var stability: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_photo_stability") }
  private var stub: HomePhotoStabilityStub { HomePhotoStabilityStub.shared }
  /// the two rows the owner photographed, adjacent, each with its own path
  private var photoRows: [HomeFeedRow] {
    let json = """
    [{"round_id":"b0000000-0000-4000-8000-000000000001","profile_id":"b0000000-0000-4000-8000-000000000011","golfer":"FIXTURE · Galen","marker":"azalea","gross":81,"course":"Encanto","pvi":0.2,"played_on":"2026-09-13","photo_path":"fixture/first.png"},
     {"round_id":"b0000000-0000-4000-8000-000000000002","profile_id":"b0000000-0000-4000-8000-000000000012","golfer":"FIXTURE · Jade","marker":"azalea","gross":77,"course":"Aguila","pvi":2.6,"played_on":"2026-09-13","photo_path":"fixture/second.png"}]
    """
    // removal is the attachment leaving the ROW, exactly as `clear_round_photo` does
    let text = removedSecond ? json.replacingOccurrences(of: ",\"photo_path\":\"fixture/second.png\"", with: "") : json
    return (try? JSONDecoder().decode([HomeFeedRow].self, from: Data(text.utf8))) ?? []
  }
  /// a "signed URL": the path plus a token that changes on every re-sign,
  /// exactly as the real one does. `-cs_dev_photo_unsignable <which>` withholds
  /// the credential on a re-sign — the transient signing failure Codex named.
  private func url(_ row: HomeFeedRow) -> URL? {
    guard let p = row.photo_path else { return nil }
    if signing >= 1, let u = unsignable, p.contains(u) { return nil }
    return URL(string: "fixture://media/\(p)?token=\(signing)")
  }
  private let examples: [HomeFeedRow] = {
    let json = """
    [{"round_id":"a0000000-0000-4000-8000-000000000001","profile_id":"a0000000-0000-4000-8000-000000000011","golfer":"You","marker":"azalea","gross":89,"course":"UNM Championship Course","is_me":true,"pvi":-2.0,"played_on":"2026-09-12"},
     {"round_id":"a0000000-0000-4000-8000-000000000002","profile_id":"a0000000-0000-4000-8000-000000000012","golfer":"FIXTURE · Sam","marker":"azalea","gross":79,"course":"Papago","is_pr":true,"played_on":"2026-09-09"},
     {"round_id":"a0000000-0000-4000-8000-000000000003","profile_id":"a0000000-0000-4000-8000-000000000013","golfer":"FIXTURE · A golfer with a long display name","marker":"azalea","gross":108,"course":"Gold Canyon — Dinosaur Mountain · Championship tees","played_on":"2026-09-08"},
     {"round_id":"a0000000-0000-4000-8000-000000000004","profile_id":"a0000000-0000-4000-8000-000000000014","golfer":"FIXTURE · Priya","marker":"azalea","gross":79,"course":"Aguila","pvi":3.1,"played_on":"2026-09-11"}]
    """
    return (try? JSONDecoder().decode([HomeFeedRow].self, from: Data(json.utf8))) ?? []
  }()
  var body: some View {
    if stability { stabilityBody } else { designBody }
  }

  private var stabilityBody: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        Text("Home · photo stability fixture").csType(.agateS).padding(.vertical, CSTokens.Space.s4)
        HStack(spacing: CSTokens.Space.s3) {
          Button("Re-sign") { signing += 1 }.accessibilityIdentifier("home.photo.resign")
          Button("Remove second") { removedSecond = true; stub.store.reconcile(paths: photoRows.compactMap(\.photo_path).filter { !$0.contains("second") }) }.accessibilityIdentifier("home.photo.remove")
          Button("Pull") { stub.store.retryMisses(); signing += 0 }.accessibilityIdentifier("home.photo.pull")
          Text("fetches \(stub.store.fetches)").csType(.agateS)
            .accessibilityIdentifier("home.photo.fetches")
        }
        .padding(.bottom, CSTokens.Space.s3)
        Text("This week").csType(.display).padding(.bottom, CSTokens.Space.s3)
        ForEach(Array(photoRows.enumerated()), id: \.offset) { index, row in
          CSRule()
          if row.photo_path != nil {
            HomeWireBand(row: row, photo: url(row), photos: stub.store,
                         open: { destination = "Round · \(row.course ?? "")" },
                         openPerson: { destination = "Golfer · \(row.golfer ?? "")" })
              .padding(.horizontal, -CSTokens.Space.gutter)
          } else {
            HomeWireSlat(row: row, open: { destination = "Round · \(row.course ?? "")" },
                         openPerson: { destination = "Golfer · \(row.golfer ?? "")" })
          }
          HomeWireReactions(state: reactions[index] ?? [:], day: HomeWireCopy.dayMarker(row.played_on)) { key in
            var value = reactions[index]?[key] ?? ReactionState()
            value.flip(me: "You", on: !value.me)
            reactions[index, default: [:]][key] = value
          }
        }
        // room to scroll, so the bands leave and re-enter the viewport
        Color.clear.frame(height: 900)
        Text("the end").csType(.agateS).accessibilityIdentifier("home.photo.end")
      }.padding(.horizontal, CSTokens.Space.gutter)
    }
    .accessibilityIdentifier("home.photo.fixture")
    .background(cs.bg0.ignoresSafeArea())
    .sheet(isPresented: Binding(get: { destination != nil }, set: { if !$0 { destination = nil } })) {
      Text(destination ?? "").csType(.name).padding()
    }
  }

  private var designBody: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        Text("Home · design fixture").csType(.agateS).padding(.vertical, CSTokens.Space.s4)
        Text("This week").csType(.display).padding(.bottom, CSTokens.Space.s3)
        ForEach(Array(examples.enumerated()), id: \.offset) { index, row in
          CSRule()
          if ProcessInfo.processInfo.arguments.contains("-cs_dev_loaded_photo") {
            // A labelled render fixture for the successful photo state; no network.
            HomeWireBand(row: row, photo: URL(string: "about:blank")!,
                         open: { destination = "Round · \(row.course ?? "")" },
                         openPerson: { destination = "Golfer · \(row.golfer ?? "")" })
              .band(Image(systemName: "photo"))
              .padding(.horizontal, -CSTokens.Space.gutter)
          } else if ProcessInfo.processInfo.arguments.contains("-cs_dev_failed_photo") {
            HomeWireBand(row: row, photo: URL(string: "data:image/png;base64,invalid")!,
                         open: { destination = "Round · \(row.course ?? "")" },
                         openPerson: { destination = "Golfer · \(row.golfer ?? "")" })
              .padding(.horizontal, -CSTokens.Space.gutter)
          } else {
            // the fourth row is the consequence case: `home_feed` does not
            // carry points or the month rank yet, so the fixture hands them
            // over to prove the producer. Labelled a fixture on its face.
            HomeWireSlat(row: row, open: { destination = "Round · \(row.course ?? "")" },
                         openPerson: { destination = "Golfer · \(row.golfer ?? "")" },
                         points: index == 3 ? 9 : nil, monthRank: index == 3 ? 2 : nil, cap: index == 3 ? 4 : nil)
          }
          let photoRow = ProcessInfo.processInfo.arguments.contains("-cs_dev_loaded_photo")
          HomeWireReactions(state: reactions[index] ?? [:], day: photoRow ? HomeWireCopy.dayMarker(row.played_on) : nil) { key in
            var value = reactions[index]?[key] ?? ReactionState()
            value.flip(me: "You", on: !value.me)
            reactions[index, default: [:]][key] = value
          }
        }
      }.padding(.horizontal, CSTokens.Space.gutter)
    }
    .accessibilityIdentifier("home.no-photo.fixture")
    .background(cs.bg0.ignoresSafeArea())
    .sheet(isPresented: Binding(get: { destination != nil }, set: { if !$0 { destination = nil } })) {
      Text(destination ?? "").csType(.name).padding()
    }
  }
}
#endif
