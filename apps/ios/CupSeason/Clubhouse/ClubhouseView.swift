// Cup Season — the Clubhouse (IOS-002 §5). M0: the leagues you are in, with
// the standing each carries. Standings proper (the sentence, the climb, the
// table, receipts) are M1.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ClubhouseView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Your leagues").csEyebrow()
        if let me = store.me, !me.memberships.isEmpty {
          ForEach(me.memberships) { m in
            CSCard(spine: m.squad.map { squadColor($0.color) }) {
              VStack(alignment: .leading, spacing: 6) {
                HStack {
                  Text(m.name).font(CSFont.title).foregroundStyle(cs.ink)
                  Spacer()
                  if m.isPro { Text("THE PRO").csEyebrow(cs.gold) }
                }
                Text(phaseLine(m)).font(CSFont.subhead).foregroundStyle(cs.mut)
                if let st = m.standing {
                  Text("\(CSCopy.ordinal(st.rank)) of \(st.of) · \(CSCopy.points(st.points)) pts")
                    .font(CSFont.monoMediumBody).foregroundStyle(cs.ink).csTabular()
                }
                if let sq = m.squad {
                  Text(sq.name).font(CSFont.monoSmall).foregroundStyle(squadColor(sq.color))
                }
              }
            }
            .onTapGesture { store.preferredLeague = m.league_id; CSHaptic.selection() }
          }
          Text("Tap a league to lead Home with it. Standings, the board and the pot land here in M1.")
            .font(CSFont.footnote).foregroundStyle(cs.dimText)
        } else {
          CSEmptyState(icon: "⛳", line: "No league yet — your golf still counts. Leagues score it when you join one.")
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    .navigationTitle("Clubhouse")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable { await store.reload() }
  }

  private func phaseLine(_ m: Me.Membership) -> String {
    switch SeasonPhase.of(m) {
    case .forming: "Forming · the bylaws lock at the tee"
    case .preseason: "Before first tee"
    case .season(let w, let of): "Week \(w) of \(of)"
    case .cupFinal(let left): "Cup Final · \(left) weeks left"
    case .wrapped: "Season wrapped"
    }
  }

  private func squadColor(_ i: Int) -> Color {
    [cs.sq0, cs.sq1, cs.sq2, cs.sq3][max(0, min(3, i))]
  }
}
