// Cup Season — the climb (`#climb`, index.html 4318–4475; D26/D31): a
// you-centred window of the ranked field — the leader, the cut-line
// neighbours, you ±1 — with the cut drawn across and points-back gaps. Rungs
// re-order on the roll; the leader's rank wears the gold.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ClimbView: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.cs) private var cs
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let items = ClimbMath.items(teams: model.teams, meId: model.myTeamId, scenarios: model.scenarios)
    VStack(alignment: .leading, spacing: 0) {
      if model.teams.isEmpty {
        VStack(alignment: .leading, spacing: 6) {
          Text("THE RACE STARTS WITH THE FIRST POSTED ROUND").font(CSFont.label).tracking(1.2).foregroundStyle(cs.mut)
          Text("SHARE THE LEAGUE CODE TO FILL THE TEE SHEET").font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText)
        }
        .padding(.vertical, 8)
      } else {
        ForEach(items) { item in
          switch item {
          case .rung(let r): rung(r)
          case .cut(let label): cut(label)
          case .ellipsis(_, let hidden): ellipsis(hidden)
          }
        }
        .animation(reduceMotion ? nil : .timingCurve(0.16, 0.84, 0.36, 1, duration: 0.55), value: items.map(\.id))
        Text(ClimbMath.note(teams: model.teams, scenarios: model.scenarios))
          .font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText).padding(.top, 10)
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("The climb — your place in the season race")
  }

  private func rung(_ r: ClimbRung) -> some View {
    Button {
      if r.team.solo, let row = model.indRow(r.team.id) { router.open(.member(row)) } else { router.open(.squad(r.team)) }
    } label: {
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 10) {
          Text(String(format: "%02d", r.index + 1)).font(CSFont.monoMediumBody).csTabular()
            .foregroundStyle(r.isLead ? cs.gold : cs.mut).frame(width: 26, alignment: .leading)
          if r.team.solo {
            CSMarkerView(key: r.team.mk, size: 18).foregroundStyle(cs.ink)
          } else {
            RoundedRectangle(cornerRadius: 3).fill(cs.squad(r.team.ci)).frame(width: 10, height: 10)
          }
          Text(r.isMe ? "You · \(r.team.name)" : r.team.name).font(r.isMe ? CSFont.subhead.weight(.semibold) : CSFont.subhead)
            .foregroundStyle(cs.ink).lineLimit(1)
          if let b = r.badge {
            Text(b).font(CSFont.label).tracking(1.0).foregroundStyle(b == "LOCKED" ? cs.gold : cs.cool)
              .padding(.horizontal, 6).padding(.vertical, 2)
              .overlay(Capsule().stroke(b == "LOCKED" ? cs.gold : cs.cool, lineWidth: 1))
          }
          Spacer(minLength: 6)
          Text(CSCopy.points(r.team.pts)).font(CSFont.monoMediumBody).csTabular().foregroundStyle(r.isLead ? cs.gold : cs.ink)
          Text(r.gap).font(CSFont.monoSmall).csTabular().foregroundStyle(cs.mut).frame(minWidth: 34, alignment: .trailing)
        }
        if let v = r.voice {
          Text(v.text).font(CSFont.sentence).foregroundStyle(cs.mut).padding(.leading, 36)
        }
      }
      .padding(.vertical, 9).padding(.horizontal, 6)
      .frame(minHeight: 44)
      .background(r.isMe ? cs.bg2 : .clear, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(r.accessibility)
    .id(r.team.id)
  }

  private func cut(_ label: String) -> some View {
    HStack(spacing: 8) {
      Rectangle().fill(cs.gold.opacity(0.5)).frame(height: 1)
      Text(label).font(CSFont.label).tracking(1.2).foregroundStyle(cs.gold).fixedSize()
      Rectangle().fill(cs.gold.opacity(0.5)).frame(height: 1)
    }
    .padding(.vertical, 6)
    .accessibilityLabel(label)
  }

  private func ellipsis(_ hidden: Int) -> some View {
    Text("··· \(hidden) more ···").font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText)
      .frame(maxWidth: .infinity)
      .padding(.vertical, min(16, 3 + Double(hidden) * 1.5))   // distance looks like distance
      .accessibilityLabel("\(hidden) more between")
  }
}
