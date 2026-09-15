#if DEBUG
import SwiftUI
import CSDesign
import CupSeasonKit

/// Illustrative data only; actions prove the distinct destinations without server reads.
struct HomeNoPhotoFixture: View {
  @Environment(\.cs) private var cs
  @State private var destination: String?
  @State private var reactions: [Int: [String: ReactionState]] = [:]
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
