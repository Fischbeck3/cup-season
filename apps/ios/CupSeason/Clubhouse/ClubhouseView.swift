// Cup Season — the Clubhouse (IOS-002 §5). Interim shell until the league
// room (wave 1A) lands: the leagues you are in, with the standing each
// carries, and doors to the board, the calendar and the album.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ClubhouseView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  let leagueId: UUID?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        if let me = store.me, !me.memberships.isEmpty {
          let current = me.memberships.first { $0.league_id == (leagueId ?? store.preferredLeague) } ?? me.memberships[0]
          Text(current.name).font(CSFont.title).foregroundStyle(cs.ink)
          Text(phaseLine(current)).font(CSFont.subhead).foregroundStyle(cs.mut)
          if let st = current.standing {
            Text("\(CSCopy.ordinal(st.rank)) of \(st.of) · \(CSCopy.points(st.points)) pts")
              .font(CSFont.monoMediumBody).foregroundStyle(cs.ink).csTabular()
          }

          HStack(spacing: 10) {
            NavigationLink(value: ClubRoute.board(current.league_id)) { door("The board", "message") }
            NavigationLink(value: ClubRoute.schedule) { door("Schedule", "calendar") }
            NavigationLink(value: ClubRoute.album(current.league_id)) { door("Album", "photo") }
          }
          .buttonStyle(.plain)

          Text("Standings, the pot and the members land here with the league room.")
            .font(CSFont.footnote).foregroundStyle(cs.dimText)

          if me.memberships.count > 1 {
            Text("Your leagues").csEyebrow().padding(.top, 10)
            ForEach(me.memberships) { m in
              Button { store.preferredLeague = m.league_id; CSHaptic.selection() } label: {
                CSCard(spine: m.league_id == current.league_id ? cs.brand : (m.squad.map { squadColor($0.color) })) {
                  HStack {
                    VStack(alignment: .leading, spacing: 3) {
                      Text(m.name).font(CSFont.button).foregroundStyle(cs.ink)
                      Text(phaseLine(m)).font(CSFont.footnote).foregroundStyle(cs.mut)
                    }
                    Spacer()
                    if m.isPro { Text("THE PRO").csEyebrow(cs.gold) }
                  }
                }
              }
              .buttonStyle(.plain)
            }
          }
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

  private func door(_ title: String, _ icon: String) -> some View {
    VStack(spacing: 6) {
      Image(systemName: icon).foregroundStyle(cs.brand)
      Text(title).font(CSFont.monoSmall).foregroundStyle(cs.ink)
    }
    .frame(maxWidth: .infinity, minHeight: 64)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
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

  private func squadColor(_ i: Int) -> Color { [cs.sq0, cs.sq1, cs.sq2, cs.sq3][max(0, min(3, i))] }
}
