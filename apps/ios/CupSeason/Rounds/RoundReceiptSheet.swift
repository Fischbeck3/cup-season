// Cup Season — the round receipt (D95; index.html `openRoundReceipt`
// 11392–11418, `enrichRoundReceipt` 11363–11391).
//
// Opens INSTANTLY with what the caller held (or what the cache held under
// this id), then enriches from `round_card()`; a missing function keeps the
// instant view. The photo rides full-bleed above the facts with the poster's
// marker medallion; it is signed on demand and never load-bearing.

import SwiftUI
import CSDesign
import CupSeasonKit

struct RoundReceiptSheet: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  let roundId: UUID
  let initialSeed: ReceiptSeed?
  /// "See the scorecard" — the hand-off to the live-round card (D92).
  var openScorecard: ((UUID) -> Void)? = nil

  @State private var seed: ReceiptSeed?
  @State private var enriched = false

  init(roundId: UUID, seed: ReceiptSeed?, openScorecard: ((UUID) -> Void)? = nil) {
    self.roundId = roundId; self.initialSeed = seed; self.openScorecard = openScorecard
    _seed = State(initialValue: seed)
  }

  private var capN: Int? {
    let m = store.me?.memberships.first { $0.league_id == store.preferredLeague } ?? store.me?.memberships.first
    return m?.settings?.counting_cap
  }

  var body: some View {
    let r = seed ?? ReceiptSeed(id: roundId)
    SliceSheet(title: r.title, sub: r.subtitle) {
      if let url = r.photoURL {
        AsyncImage(url: url) { phase in
          if case .success(let img) = phase {
            img.resizable().scaledToFill()
              .frame(maxWidth: .infinity).frame(height: 240)
              .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
              .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(cs.line2, lineWidth: 1))
              .overlay(alignment: .bottomTrailing) {
                if r.profileId != nil { MarkerStamp(marker: r.marker) }
              }
              .accessibilityLabel("Round photo")
          }
        }
        .padding(.bottom, 4)
      }
      let rows = ReceiptRows.build(r, capN: capN, viewerId: store.session?.user.id)
      if rows.isEmpty && !enriched {
        Text("Pulling the card…").font(CSFont.subhead).foregroundStyle(cs.dimText)
      }
      VStack(spacing: 0) {
        ForEach(rows) { row in
          switch row {
          case .math(let label, let value, let sub):
            MathRow(label: label, value: value, sub: sub)
          case .playedWith(let mates):
            (Text("Played with ").foregroundStyle(cs.dimText) + Text(mates.joined(separator: ", ")).foregroundStyle(cs.mut).bold())
              .font(CSFont.subhead).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10)
          case .scorecard(let live):
            if let openScorecard {
              CSButton("See the scorecard", style: .quiet) { openScorecard(live) }.padding(.top, 12)
            }
          }
        }
      }
    }
    .task { await open() }
  }

  private func open() async {
    if seed == nil, let cached = await ReceiptCache.shared.get(roundId) { seed = cached }
    let repo = RoundsRepository()
    // the second pass: one read, then redraw in place
    async let card = repo.roundCard(roundId)
    if seed?.photoURL == nil, let path = seed?.photoPath, let url = await repo.signedURL(path) {
      seed?.photoURL = url
    }
    if let json = try? await card {
      var merged = (seed ?? ReceiptSeed(id: roundId)).merged(with: json)
      if merged.photoURL == nil, let path = merged.photoPath, let url = await repo.signedURL(path) { merged.photoURL = url }
      seed = merged
    }
    enriched = true
  }
}

#Preview("An 86 on a 64.9 / 111") {
  RoundReceiptSheet(roundId: UUID(), seed: ReceiptSeed(
    id: UUID(), gross: 86, differential: 21.5, indexAtPost: 10.0, playedOn: "2026-07-25",
    courseLabel: "Arizona Biltmore Links · Copper", holesPlayed: 18, rating: 64.9, slope: 111, points: 5, monthRank: 3, countingCap: 4))
  .environment(SessionStore())
  .csTheme()
}
