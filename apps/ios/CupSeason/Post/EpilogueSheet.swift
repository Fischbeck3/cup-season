// Cup Season — the epilogue (index.html `showEpilogue` 5959–6021; D17, D57,
// D60). The poster hears it first: the round's meaning (band + points +
// counting rank), what it earned, any rivalry record it moved, the first-ever
// welcome — then the card, and the link anyone can open without an account.

import SwiftUI
import CSDesign
import CupSeasonKit

struct EpilogueSheet: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  let show: PostEpilogueShow
  let photo: UIImage?
  @State private var share: PostShareItem?
  @State private var linking = false
  @State private var revoking = false
  private let svc = PostService()

  private var rows: [PostEpilogueRow] { show.epilogue.rows(cap: show.cap, firstEver: show.firstEver) }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        CSSheetHeader(title: PostEpilogue.title(firstEver: show.firstEver), sub: show.epilogue.subtitle(course: show.course))
        ForEach(rows) { row in
          if case .line(let icon, let title, let sub) = row {
            CheckRow(glyph: Text(icon), title: title, sub: sub) { EmptyView() }
          }
        }
        if let gross = show.epilogue.gross, !show.ceremonyOwnsShare {
          CSButton(PostEpilogue.shareLabel(firstEver: show.firstEver)) { share = RecapCardView.shareItem(recap(gross), photo: photo) }.padding(.top, 8)
        }
        if show.epilogue.gross != nil {
          CSButton(PostEpilogue.linkLabel(photoTravels: show.photoTravels), style: .quiet, busy: linking) { Task { await link() } }.padding(.top, 4)
          Button { Task { await revoke() } } label: {
            Text(PostEpilogue.revokeLabel).font(CSFont.subhead).foregroundStyle(cs.mut).frame(maxWidth: .infinity, minHeight: 44)
          }
          .buttonStyle(.plain).disabled(revoking)
          Text(PostEpilogue.revokeFine).font(CSFont.footnote).foregroundStyle(cs.dimText).multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .sheet(item: $share) { PostShareSheet(items: $0.items) }
  }

  private func recap(_ gross: Int) -> PostRecap {
    let p = store.me?.profile
    return PostRecap(name: p?.display_name ?? "You", marker: p?.marker ?? "saguaro", gross: gross, pvi: show.epilogue.pvi,
                     points: show.epilogue.points.map { Int($0) }, course: show.course ?? "", date: CSDate.today(),
                     badge: show.epilogue.earned.first.flatMap { PostRecap.badges[$0.kind] })
  }

  /// `csShareLink('round', roundId, text)` — the native share sheet, the clipboard as its fallback.
  private func link() async {
    linking = true; defer { linking = false }
    do {
      let url = try await svc.shareLink(round: show.roundId) { data in PostPhoto.compress(data: data, maxDim: 1600, quality: 0.8) }
      let text = PostEpilogue.linkText(name: store.me?.profile?.display_name, gross: show.epilogue.gross ?? 0, course: show.course)
      share = PostShareItem(items: [text, url])
    } catch { toast.show(HumanError.text(error, prefix: "Could not make the link.")) }
  }

  private func revoke() async {
    revoking = true; defer { revoking = false }
    do { try await svc.revokeLink(round: show.roundId); toast.show(PostEpilogue.revokedToast) }
    catch { toast.show(HumanError.text(error, prefix: "Could not revoke.")) }
  }
}
