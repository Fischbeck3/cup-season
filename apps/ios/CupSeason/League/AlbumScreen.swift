// Cup Season — the album (`renderAlbum`, index.html 16456–16505): every round
// photo this season, newest first, month dividers, one batched signing; tap
// opens the round receipt. Loads lazily on first open.

import SwiftUI
import CSDesign
import CupSeasonKit

struct AlbumScreen: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.cs) private var cs

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("The album · every round photo this season").csEyebrow()
      if let items = model.album {
        if items.isEmpty {
          Fine("Photos land here when rounds carry them — add one from the Post card.")
        } else {
          ForEach(months(items), id: \.key) { mo in
            Text(mo.label).font(CSFont.sentence).foregroundStyle(cs.mut).padding(.top, 6)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
              ForEach(mo.items) { it in
                Button { links.openReceipt(it.round.id) } label: {
                  Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                      AsyncImage(url: it.url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: Rectangle().fill(cs.bg2)
                        }
                      }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(it.golfer) — \(it.round.gross.map(String.init) ?? "") at \(it.round.course_label ?? "the course"), \(it.round.played_on)")
              }
            }
          }
        }
      } else {
        Fine("Opening the album…")
      }
    }
    .task { if model.album == nil { await model.loadAlbum() } }
  }

  private struct Month { let key: String; let label: String; let items: [AlbumItem] }
  private func months(_ items: [AlbumItem]) -> [Month] {
    var out: [Month] = []
    for it in items {
      let key = LeagueDates.monthKey(it.round.played_on)
      if out.last?.key == key { out[out.count - 1] = Month(key: key, label: out.last!.label, items: out.last!.items + [it]) }
      else {
        let parts = key.split(separator: "-")
        let m = Int(parts.count > 1 ? parts[1] : "1") ?? 1
        out.append(Month(key: key, label: "\(LeagueDates.monthsLong[max(0, min(11, m - 1))]) \(parts.first ?? "")", items: [it]))
      }
    }
    return out
  }
}
