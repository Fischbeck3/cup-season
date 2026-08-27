// Cup Season — the scan's two sheets (`scanPickRow` 6620–6631,
// `scanPartnersSheet` 6658–6692). The model proposes, the golfer confirms;
// one scan can post the foursome — the claim is the invite (D36).

import SwiftUI
import CSDesign
import CupSeasonKit

/// "Whose card is this? — TAP YOUR ROW"
struct PostScanPickSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let scan: PostScan
  let pick: (Int) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        CSSheetHeader(title: "Whose card is this?", sub: "TAP YOUR ROW")
        ForEach(Array(scan.players.enumerated()), id: \.offset) { i, p in
          Button { pick(i); dismiss() } label: {
            CheckRow(glyph: Text("⛳"), title: p.label(i),
                     sub: (p.total.map { "\($0) GROSS · " } ?? "") + "\(p.holes_read)/18 HOLES READ") {
              Text("→").font(CSFont.subhead).foregroundStyle(cs.dimText)
            }
          }
          .buttonStyle(.plain)
        }
        CSFine("After you post, your partners’ rows can be sent to them as claim links.").padding(.top, 4)
      }
      .padding(20)
    }
    .background(cs.bg0)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}

/// "Send their rounds — ONE SCAN, THE WHOLE GROUP"
struct PostPartnersSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  let show: PostPartnersShow
  @State private var tokens: [Int: UUID] = [:]
  @State private var busy: Set<Int> = []
  @State private var share: PostShareItem?
  private let svc = PostService()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        CSSheetHeader(title: "Send their rounds", sub: "ONE SCAN, THE WHOLE GROUP")
        CSFine("Your partners’ rows came off the same card. Send each a link — one tap and the round lands on their own golfer card.")
        ForEach(Array(show.rows.enumerated()), id: \.offset) { i, p in
          CheckRow(glyph: Text("🎟️"), title: p.label(i), sub: p.total.map { "\($0) GROSS" } ?? "PARTIAL CARD") {
            HStack(spacing: 6) {
              CSMini(tokens[i] == nil ? "Copy link" : "Copied ✓", busy: busy.contains(i)) { Task { await copy(i, p) } }
              if let t = tokens[i] {
                CSMini("", systemImage: "square.and.arrow.up") { share = PostShareItem(items: [PostService.claimURL(t)]) }.accessibilityLabel("Share the link")
              }
            }
          }
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .sheet(item: $share) { PostShareSheet(items: $0.items) }
  }

  private func copy(_ i: Int, _ p: PostScanPlayer) async {
    busy.insert(i); defer { busy.remove(i) }
    do {
      let token: UUID
      if let t = tokens[i] { token = t } else { token = try await svc.mintClaim(p, ctx: show.ctx); tokens[i] = token }
      UIPasteboard.general.url = PostService.claimURL(token)
      svc.event(PostEvent.scanClaimMinted)
      CSHaptic.selection()
    } catch { toast.show(HumanError.text(error, prefix: "Could not make the link.")) }
  }
}

/// Something to hand the share sheet — an image + caption, or a URL.
struct PostShareItem: Identifiable {
  let id = UUID()
  let items: [Any]
}
