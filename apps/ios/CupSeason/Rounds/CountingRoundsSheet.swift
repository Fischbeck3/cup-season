// Cup Season — the rounds that count (D362): one golfer, one season's rule,
// one month. The server's `counting_rounds` is the producer — the same one the
// desk reads — and nothing here is computed on the phone. Every row is
// counting or BUMPED and opens its receipt (§16: every points figure traces to
// the rounds that produced it).

import SwiftUI
import CSDesign
import CupSeasonKit

struct CountingRoundsSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let door: ReceiptCountingDoor
  @State private var payload: JSONValue?
  @State private var failed: String?
  @State private var openRound: UUID?

  private struct Row: Identifiable {
    let id: UUID?; let playedOn: String; let holes: Int?; let gross: Int?; let course: String?
    let points: Double?
    /// **nil is UNKNOWN, and stays unknown.** A row whose `counting` the server
    /// did not send is not a counting round by default — it is a round whose
    /// status this screen does not know, and it says nothing rather than
    /// promising something (L-44).
    let counting: Bool?
  }
  private var rows: [Row] {
    (payload?["rounds"]?.array ?? []).map { r in
      Row(id: r["round_id"]?.string.flatMap(UUID.init), playedOn: r["played_on"]?.string ?? "",
          holes: r["holes_played"]?.int, gross: r["gross"]?.int, course: r["course_label"]?.string,
          points: r["points"]?.double, counting: r["counting"]?.bool)
    }
  }
  /// **The rule is only ever the LOADED payload's.** `cap` is nil for an
  /// uncapped season AND for a payload that has not arrived or failed, and the
  /// first version read both as "Every round counts" — a rule invented from a
  /// spinner. The key's presence is the difference, so the payload is asked
  /// whether it HAS a cap before the cap is read.
  private var ruleKnown: Bool { payload?["cap"] != nil }
  private var cap: Int? { payload?["cap"]?.int }
  private var who: String { door.mine ? "Your" : "Their" }
  private var when: String { door.month.flatMap(ReceiptRows.monthWord) ?? "this season" }
  private var rule: String? {
    guard ruleKnown else { return nil }
    return (cap ?? 0) > 0 ? "Best \(cap!) count each month" : "Every round counts"
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          Text([payload?["league_name"]?.string ?? door.leagueName, when, rule].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
            .csType(.agateS, caps: true).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          if let failed {
            Text(failed).csType(.body).foregroundStyle(cs.mut)
          } else if payload == nil {
            Text("Loading rounds…").csType(.body).foregroundStyle(cs.mut).accessibilityAddTraits(.updatesFrequently)
          } else if rows.isEmpty {
            Text("No rounds \(when.lowercased()) under this rule yet.").csType(.body).foregroundStyle(cs.mut)
          } else {
            VStack(spacing: 0) {
              ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                if i > 0 { CSRule() }
                Button { openRound = r.id } label: {
                  HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
                    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
                      Text("\(r.gross.map(String.init) ?? "—") at \(r.course ?? "course not recorded")")
                        .csType(.bodyS).foregroundStyle(r.counting == false ? cs.mut : cs.ink)
                        .fixedSize(horizontal: false, vertical: true)
                      Text(r.playedOn + (r.holes == 9 ? " · 9 HOLES" : "")).csType(.agateS, caps: true).foregroundStyle(cs.mut)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // an unknown status says the points and nothing about counting
                    Text((r.points.map(CSCopy.points) ?? "") + (r.counting == false ? " · BUMPED" : ""))
                      .csType(.columnS).foregroundStyle(r.counting == false ? cs.mut : cs.ink)
                    if r.id != nil { CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut) }
                  }
                  .padding(.vertical, CSTokens.Space.s3)
                  .frame(minHeight: 44)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(r.id == nil)
                .accessibilityIdentifier(r.counting == nil ? "counting.round.unknown" : (r.counting! ? "counting.round" : "counting.round.bumped"))
              }
            }
            if rows.contains(where: { $0.counting == false }) {
              Text("Bumped rounds still happened — a better round took their monthly slot.")
                .csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
            }
          }
        }
        .padding(CSTokens.Space.gutter)
      }
      .background(cs.bg0)
      .navigationTitle("\(who) rounds that count").navigationBarTitleDisplayMode(.inline)
      .csCloseButton { dismiss() }
    }
    .presentationBackground(cs.bg0)
    .task {
      do { payload = try await RoundsRepository().countingRounds(member: door.memberId, season: door.seasonId, month: door.month) }
      catch { failed = AuthRules.human(error, fallback: "Those rounds need the latest update — try again shortly.") }
    }
    .sheet(item: Binding(get: { openRound.map { Opened(id: $0) } }, set: { openRound = $0?.id })) { o in
      RoundReceiptSheet(roundId: o.id, seed: nil)
    }
    .accessibilityIdentifier("counting.sheet")
  }
  private struct Opened: Identifiable { let id: UUID }
}
