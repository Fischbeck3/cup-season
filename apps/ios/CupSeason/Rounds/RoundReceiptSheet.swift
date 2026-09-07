// Cup Season — the round receipt (D95; index.html `openRoundReceipt`
// 11392–11418, `enrichRoundReceipt` 11363–11391).
//
// Opens INSTANTLY with what the caller held (or what the cache held under
// this id), then enriches from `round_card()`; a missing function keeps the
// instant view. The photo rides full-bleed above the facts with the poster's
// marker medallion; it is signed on demand and never load-bearing.
//
// WAVE 7 · **THE SCORE AS AN OBJECT, AND THE RECEIPT** (`leaderboard.md` §6).
// The sheet's head was a 21pt title and a tracked-caps sub-line; it is now the
// two rule-and-figures the whole system is derived from — the gross at
// `figure` 56 over a 2pt rule with `GROSS · 18 HOLES` beneath it, and the
// points at 40 over its own — and the facts print on a LEAF, because a receipt
// is a printed grid and that is what a leaf is for. `ReceiptRows` is untouched.

import SwiftUI
import CSDesign
import CupSeasonKit

struct RoundReceiptSheet: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var typeSize
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
    let rows = ReceiptRows.build(r, capN: capN, viewerId: store.session?.user.id)
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          head(r)
          photo(r)
          if rows.isEmpty && !enriched {
            Text("Pulling the card…").csType(.body).foregroundStyle(cs.mut)
              .accessibilityAddTraits(.updatesFrequently)
          }
          CSSectionHead("The receipt")
          ReceiptLeaf(caption: "What this round was worth",
                      dateline: r.playedOn.map { RivalryCopy.monthDay($0) },
                      rows: rows)
          foot(rows)
        }
        .padding(.horizontal, CSTokens.Space.gutter)
        .padding(.top, CSTokens.Space.s3)
        .padding(.bottom, CSTokens.Space.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(cs.bg0)
      .navigationTitle("").navigationBarTitleDisplayMode(.inline)
      .csCloseButton { dismiss() }
    }
    .presentationBackground(cs.bg0)
    .task { await open() }
  }

  /// §6.2–§6.5 · the dateline, `YOUR ROUND`, the two rule-and-figures on one
  /// baseline, and the sentence with its figure run.
  @ViewBuilder private func head(_ r: ReceiptSeed) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      Text(dateline(r)).csType(.agate, caps: true).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
      Text(mine(r) ? "Your round" : "The round").csType(.displayS, caps: true).foregroundStyle(cs.ink)
      // **Two rule-and-figures on ONE BASELINE** — which is the BOTTOM here,
      // not the first text baseline: each figure sits over its own rule with
      // its own label under it, so aligning the numerals would stagger the two
      // rules and the two labels. Aligning the bottoms lines up all three.
      // At the accessibility sizes the two figures STACK and drop their
      // columns: `POINTS` under a 76pt rule breaks as `POIN / TS`, which is a
      // label describing a column that no longer exists.
      A11yStack(rowAlignment: .bottom, spacing: CSTokens.Space.s5, columnSpacing: CSTokens.Space.s4) {
        if let g = r.gross {
          CSFigure("\(g)", size: .xl,
                   label: "gross · \(r.holesPlayed == 9 ? "9" : "18") holes")
            .frame(width: typeSize.isA11y ? nil : 132, alignment: .leading)
        }
        if let p = r.points {
          CSFigure(CSCopy.points(p), size: .l, label: "points")
            .frame(width: typeSize.isA11y ? nil : 76, alignment: .leading)
        }
        if !typeSize.isA11y { Spacer(minLength: 0) }
      }
      // §6.5 · **the fix for `CSFont.sentence`'s numeric sites**: the numeral
      // is set in the BOARD FACE at the sentence's own size, so a number in a
      // sentence is still in the number's voice. The producer marks the run;
      // there is no regex over prose.
      if let marked = sentence(r) {
        CSFigureRun(marked, role: .body).foregroundStyle(cs.ink)
      }
    }
  }

  @ViewBuilder private func photo(_ r: ReceiptSeed) -> some View {
    if let url = r.photoURL {
      // §10.1 rung 1 · a golfer's own round photo, and the poster's mark is the
      // credit. `CSPlate` carries the scrim, so the medallion never sits on a
      // bright sky at 1.4:1.
      CSPlate(.inset32) {
        AsyncImage(url: url) { phase in
          if case .success(let img) = phase { img.resizable().scaledToFill() } else { Color.clear }
        }
      }
      .overlay(alignment: .bottomTrailing) {
        if r.profileId != nil { MarkerStamp(marker: r.marker).padding(CSTokens.Space.s2) }
      }
      .accessibilityLabel("Round photo")
    }
  }

  /// §6.8 · the two rows the leaf does not hold: a door and a credit line.
  @ViewBuilder private func foot(_ rows: [ReceiptRow]) -> some View {
    let mates: [String] = rows.compactMap { if case .playedWith(let m) = $0 { return m.joined(separator: ", ") } else { return nil } }
    let live: UUID? = rows.compactMap { if case .scorecard(let id) = $0 { return id } else { return nil } }.first
    if live != nil || !mates.isEmpty {
      HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
        if let live, let openScorecard {
          CSDoor(.link("See the scorecard") { openScorecard(live) })
        }
        Spacer(minLength: CSTokens.Space.s2)
        if let m = mates.first {
          Text("Played with \(m)").csType(.agateS, caps: true).foregroundStyle(cs.mut)
            .multilineTextAlignment(.trailing)
        }
      }
    }
  }

  /// `PAPAGO · BLUE · SUN SEP 6`. `ReceiptSeed.subtitle` joins the ISO date
  /// raw — it was written for a sheet title, and `2026-09-04` in tracked caps
  /// over a receipt is a database row rather than a dateline.
  private func dateline(_ r: ReceiptSeed) -> String {
    [r.courseLabel, "\(r.holesPlayed ?? 18) holes", r.playedOn.map { RivalryCopy.monthDay($0) }]
      .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
  }

  private func mine(_ r: ReceiptSeed) -> Bool {
    r.isMine ?? (r.profileId == nil || r.profileId == store.session?.user.id)
  }

  /// The one sentence, with the figure marked by the producer of the fact
  /// rather than found in the prose. Absent when the round has no verdict —
  /// a receipt with nothing to say says nothing.
  /// **The words are `CSBands`', not this view's.** The first build wrote its
  /// own — and got the sign backwards, because in this product a POSITIVE
  /// figure means you beat your playing HCP by that much. It printed "You beat
  /// your playing HCP by 2.0" over a receipt row reading `−2.0 · A LITTLE
  /// LOOSE`. One producer, one direction, three renderers.
  private func sentence(_ r: ReceiptSeed) -> String? {
    guard r.indexProvisional != true, let pvi = r.resolvedPvi else { return nil }
    let named = r.band ?? CSBands.bandName(pvi)
    let band = mine(r) ? named : CSBands.theirs(named)
    var phrase = CSBands.vsPhraseMarked(pvi)
    guard !phrase.isEmpty else { return nil }
    if !mine(r) { phrase = CSBands.theirs(phrase) }
    // The phrase is its own sentence — `Beat your playing HCP by 7.6` — and a
    // pronoun in front of it makes half the cases verbless ("You 2.0 over your
    // playing HCP"). It opens the same way the composer's does, and the two
    // read as one voice because they are one producer.
    return phrase.prefix(1).uppercased() + phrase.dropFirst() + " — " + band.lowercased() + "."
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

#Preview("An 86 on a 64.9 / 111 · Standard, 95%") {
  RoundReceiptSheet(roundId: UUID(), seed: ReceiptSeed(
    id: UUID(), gross: 86, differential: 21.5, indexAtPost: 10.0, playedOn: "2026-07-25",
    courseLabel: "Arizona Biltmore Links · Copper", holesPlayed: 18, rating: 64.9, slope: 111, pvi: -12.0, playingIndex: 9.5,
    points: 5, monthRank: 3, countingCap: 4))
  .environment(SessionStore())
  .csTheme()
}

#Preview("First round — no number yet (D124)") {
  RoundReceiptSheet(roundId: UUID(), seed: ReceiptSeed(
    id: UUID(), gross: 94, differential: 27.8, indexAtPost: 27.8, playedOn: "2026-09-03",
    courseLabel: "Papago GC", holesPlayed: 18, rating: 70.2, slope: 125, pvi: 0, points: 7, monthRank: 1, countingCap: 3,
    indexProvisional: true, provisionalRound: 1))
  .environment(SessionStore())
  .csTheme()
}
