// Cup Season — the individual race (`renderIndStatsReal`, index.html
// 11250–11296): the trio (Points King / Most Improved / Iron Man) and the
// every-player table from `indRows`. In season the trio is a projection; once
// the season closes the Points King is the stored `points_king_member_id`.

import SwiftUI
import CSDesign
import CupSeasonKit

struct IndividualRaceView: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize

  var body: some View {
    let rows = model.indRows
    let ax = typeSize.isA11y
    VStack(alignment: .leading, spacing: 10) {
      // the trio as one band — three columns on ground, a hairline under (IOS-019 rule 2); stacked at the accessibility sizes
      VStack(alignment: .leading, spacing: 6) {
        if let aw = model.awards {
          A11yStack(rowAlignment: .top, spacing: 10, columnSpacing: 0) {
            tile(kingName(aw), sub: kingSub(aw), gold: true)
            tile(aw.improved, sub: aw.improvedSub)
            tile(aw.iron, sub: aw.ironSub)
          }
          if !model.isComplete {
            Text("PROJECTED — THE ENGINE CROWNS AT CLOSE").font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText)
          }
        } else {
          A11yStack(rowAlignment: .top, spacing: 10, columnSpacing: 0) {
            tile("—", sub: "Points King", gold: true); tile("—", sub: "Most Improved"); tile("—", sub: "Iron Man")
          }
        }
      }
      .padding(.vertical, 4)
      .overlay(alignment: .bottom) { CSHairline() }
      VStack(spacing: 0) {
        if rows.isEmpty {
          // the web's sentence (11258), ending in the one move that fills it
          CSEmptyState(icon: "⛳", line: "The race fills in once your league season is live and rounds land.",
                       cta: links.openRecord == nil ? nil : "Post a round") { links.openRecord?() }
            .padding(.vertical, 8)
        } else {
          if !ax {
            HStack(spacing: 10) {
              Text("").frame(width: 26)
              Text("Player").frame(maxWidth: .infinity, alignment: .leading)
              Text("R").frame(width: 28, alignment: .trailing)
              Text("Avg vs index").frame(width: 70, alignment: .trailing)
              Text("Pts").frame(width: 40, alignment: .trailing)
            }
            .font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(cs.dimText)
            .padding(.horizontal, 4).padding(.vertical, 8)
            .overlay(alignment: .bottom) { CSHairline() }
            .accessibilityHidden(true)
          }
          ForEach(Array(rows.enumerated()), id: \.element.id) { i, p in
            Button { router.open(.member(p)) } label: {
              // five columns at reading sizes; the figures take a second line at the accessibility sizes, each named
              A11yStack(spacing: 10, columnSpacing: 4) {
                HStack(spacing: 10) {
                  Text(String(format: "%02d", i + 1)).font(CSFont.monoSmall).csTabular().foregroundStyle(cs.mut).frame(minWidth: 26, alignment: .leading)
                  HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3).fill(cs.squad(p.ci)).frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 1) {
                      Text(p.n).font(CSFont.subhead).foregroundStyle(cs.ink).lineLimit(ax ? nil : 1)
                      Text(p.sq).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
                    }
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 10) {
                  if ax { Text("R").font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText) }
                  Text("\(p.r)").font(CSFont.monoSmall).csTabular().foregroundStyle(cs.mut).frame(minWidth: ax ? nil : 28, alignment: .trailing)
                  if ax { Text("· VS INDEX").font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText) }
                  Text(p.r > 0 ? StandingsMath.sgn(p.avg) : "—").font(CSFont.monoSmall).csTabular()
                    .foregroundStyle(p.avg >= 0 ? cs.pos : cs.neg).frame(minWidth: ax ? nil : 70, alignment: .trailing)
                  if ax { Text("· PTS").font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText) }
                  Text(CSCopy.points(p.pts)).font(CSFont.monoMediumBody).csTabular().foregroundStyle(cs.ink).frame(minWidth: ax ? nil : 40, alignment: .trailing)
                }
                .padding(.leading, ax ? 22 : 0)
              }
              .padding(.horizontal, 4).padding(.vertical, 10)
              .frame(minHeight: 48)
              .background(p.me ? cs.bg2.opacity(0.7) : .clear, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
              .contentShape(Rectangle())
              // the leader's hairline is gold (IOS-003 §2.10); every other row parts on `line`
              .overlay(alignment: .bottom) { Rectangle().fill(i == 0 && p.pts > 0 ? cs.gold.opacity(0.55) : cs.line).frame(height: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(CSCopy.ordinal(i + 1)), \(p.n), \(p.r) round\(p.r == 1 ? "" : "s"), \(CSCopy.points(p.pts)) points")
            .accessibilityHint("Opens their rounds")
          }
        }
      }
      RoomFine("Points King takes \(model.bylaws.payout[2])% of the pot at season's end. Most Improved is index drop since Week 1; Iron Man is most rounds posted. All three run in parallel with the squad race — see How scoring works.")
    }
  }

  /// Once complete, the stored king (audit 02 §8) — never the client's projection.
  private func kingName(_ aw: StandingsMath.Awards) -> String {
    if model.isComplete, let k = model.season?.points_king_member_id, let m = model.member(k) { return StandingsMath.firstName(m.profile?.display_name) }
    return aw.king
  }
  private func kingSub(_ aw: StandingsMath.Awards) -> String {
    if model.isComplete, let k = model.season?.points_king_member_id, let r = model.indRow(k) { return "Points King · \(CSCopy.points(r.pts)) pts" }
    return aw.kingSub
  }

  /// One column of the trio — the name in the honor voice, gold only on the King (earned).
  private func tile(_ b: String, sub: String, gold: Bool = false) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(b).font(CSFont.sentenceBold).foregroundStyle(gold && b != "—" ? cs.gold : cs.ink).lineLimit(typeSize.isA11y ? nil : 1).minimumScaleFactor(0.8)
      Text(sub).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity, alignment: .topLeading)
  }
}
