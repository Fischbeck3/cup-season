// Cup Season — the epilogue (index.html `showEpilogue` 5959–6021; D17, D57,
// D60; IOS-030 / `CORE_FLOWS.md` §11).
//
// It was a sheet of achievement rows, a share button and a link button, and
// then nothing (PP-02). It is now a PAGE with **one ranked next act** at the
// top — the sentence the round earned, and the single door that follows from
// it (P-3) — with the rows under it and the share artifacts demoted below the
// act. Demoting them is the only change to the artifacts: they are still the
// marketing (`spec/photos-arc.md`), they are simply no longer the only thing
// offered at the one moment a golfer is provably engaged.
//
// The act is produced by `PostNextAct` (the Kit) from what came back with the
// round. Nothing on this page is invented: a rung with no read does not fire,
// and the eighth rung is a true sentence with **Done**, never a blank (L-32).

import SwiftUI
import CSDesign
import CupSeasonKit

/// What the act's door needs from the shell. Every one lands on an object that
/// already exists; a door this build cannot open is simply not offered.
struct EpilogueLinks {
  var openTable: (UUID) -> Void = { _ in }
  var openPerson: (UUID) -> Void = { _ in }
  var openPeople: () -> Void = {}
  var startSomething: () -> Void = {}
}

struct EpilogueSheet: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  /// D329 · the epilogue's marks wear the golfer's look. `\.csLook` is set at
  /// the app root (D302), so this reads whatever they picked in settings and
  /// falls back to ink when no look is active.
  @Environment(\.csLookAccent) private var la
  let show: PostEpilogueShow
  let photo: UIImage?
  var links = EpilogueLinks()
  var onDone: () -> Void = {}
  @State private var share: PostShareItem?
  @State private var roundPreview = false
  @State private var linking = false
  @State private var revoking = false
  private let svc = PostService()

  private var rows: [PostEpilogueRow] { show.epilogue.rows(cap: show.cap, firstEver: show.firstEver) }
  private var act: PostNextAct? { show.act }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        CSSheetHeader(title: PostEpilogue.title(firstEver: show.firstEver), sub: show.epilogue.subtitle(course: show.course))

        // THE ACT — one sentence, one door, above everything else on the page.
        if let act {
          VStack(alignment: .leading, spacing: 10) {
            Text(act.sentence).csType(.displayS).foregroundStyle(cs.ink)
              .fixedSize(horizontal: false, vertical: true)
            let gap = EpilogueMovement.gapNote(show.epilogue.movement)
            if !gap.isEmpty {
              Text(gap).csType(.body).foregroundStyle(cs.mut)
            }
            if case .done = act.door {
              Button(act.label) { onDone() }
                .buttonStyle(.csSecondary())
            } else {
              Button(act.label) { take(act.door) }
                .buttonStyle(.csPrimary())
            }
          }
          .padding(.top, 4)
          .accessibilityElement(children: .combine)
        }

        // D326 · a mark is a glyph, a drawn marker, or nothing. The row says
        // which; this only draws it. D329 added the fourth and now usual case.
        ForEach(rows) { row in
          if case .line(_, let title, let sub) = row {
            switch row.mark {
            case .none:
              CheckRow(title: title, sub: sub) { EmptyView() }
            case .marker(let key):
              // 18pt against 17pt text — the marker's stroke reads lighter than
              // an emoji's fill, so it sits a hair larger to match its weight.
              CheckRow(glyph: CSMarkerView(key: key, size: 18), title: title, sub: sub) { EmptyView() }
            case .trophy(let g, let n):
              // **THE SAME 18pt, AND FOR THE SAME REASON**: this is line art in
              // a column of 17pt text. `CSTrophyMark`'s own default is 28,
              // which is the trophy case's shelf size and would tower here.
              //
              // **AND THE ONE PLACE A TROPHY MARK IS NOT INK.** All-drawn was
              // the right call for agreement with the case, and taken alone it
              // would have turned the app's one celebration into a monochrome
              // list. The golfer's own look carries it instead — the same
              // accent the live rule and the live dot already wear — so the
              // screen keeps its colour without borrowing gold, whose budget is
              // one object per viewport and already spent (LINT-17).
              CheckRow(glyph: CSTrophyMark(g, numeral: n, size: 18, tint: la.active ? la.accent : nil),
                       title: title, sub: sub) { EmptyView() }
            case .glyph(let g):
              CheckRow(glyph: Text(g), title: title, sub: sub) { EmptyView() }
            }
          }
        }

        // D239 · who was out there, as a claim with a state. A tag is never a
        // vouch (L-19), so the line says who and whether they have answered —
        // and nothing about attestation.
        if !show.epilogue.playedWith.isEmpty {
          Text(EpilogueSheet.playedWithLine(show.epilogue.playedWith))
            .csType(.body).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 2)
        }

        if let movement = show.epilogue.movement,
           let before = movement.rankBefore, let after = movement.rankAfter,
           before != after, before > 0, after > 0 {
          Button("Share movement") {
            share = BrandRecordCard(kind: "Standings movement",
              title: store.me?.profile?.display_name ?? "You",
              figure: String(after), statement: "Previously \(before) · position after this round",
              rows: movement.of.map { ["In a field of \($0)"] } ?? [], earned: after == 1).shareItem()
          }.buttonStyle(.csSecondary()).padding(.top, 8)
        }

        // the share artifacts, below the act
        if let gross = show.epilogue.gross, !show.ceremonyOwnsShare {
          Button(PostEpilogue.shareLabel(firstEver: show.firstEver)) {
            roundPreview = true
          }
            .buttonStyle(.csSecondary()).padding(.top, 8)
        }
        if show.epilogue.gross != nil {
          Button(PostEpilogue.linkLabel(photoTravels: show.photoTravels)) { Task { await link() } }
            .buttonStyle(.csSecondary(busy: linking)).padding(.top, 4)
          Button { Task { await revoke() } } label: {
            Text(PostEpilogue.revokeLabel).csType(.body).foregroundStyle(cs.mut).frame(maxWidth: .infinity, minHeight: 44)
          }
          .buttonStyle(.plain).disabled(revoking)
          Text(PostEpilogue.revokeFine).csType(.bodyS).foregroundStyle(cs.mut).multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .sheet(item: $share) { PostShareSheet(items: $0.items) }
    .sheet(isPresented: $roundPreview) {
      if let gross = show.epilogue.gross { RoundSharePreview(recap: recap(gross), photo: photo) }
    }
    // D104: the first posted round is one of the three moments the ask may follow
    // (raised once this sheet and the composer are down); any posted round
    // makes tonight's duel reminder moot (§7).
    .onAppear {
      if show.firstEver { PushAsk.shared.request(.firstRound) }
      Task { await PushDuelReminder.cancelAll() }
      CSTelemetry.event("epilogue_act_seen", ["act": .string(show.act?.key ?? "none")])
    }
  }

  /// "Played with Galen — he has not confirmed yet." One sentence, whatever the
  /// count, and it never claims the other golfer agreed to anything.
  static func playedWithLine(_ people: [PostEpilogue.Partner]) -> String {
    let names = EpilogueMovement.list(people.map(\.name))
    let waiting = people.filter { !$0.confirmed }.map(\.name)
    guard !waiting.isEmpty else { return "Played with \(names)." }
    if waiting.count == people.count && people.count == 1 {
      return "Played with \(names) — \(names) hasn’t confirmed yet."
    }
    return "Played with \(names) — waiting on \(EpilogueMovement.list(waiting))."
  }

  private func take(_ door: PostNextAct.Door) {
    CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["where": .string("epilogue"), "act": .string(show.act?.key ?? "none")])
    switch door {
    case .table(let id), .headToHead(let id):
      if let id { links.openTable(id) } else { onDone() }
    case .record(let id), .seasonWith(let id, _):
      if let id { links.openPerson(id) } else { links.openPeople() }
    case .startSomething: links.startSomething()
    case .findGolfers: links.openPeople()
    case .callout, .done: onDone()
    }
  }

  private func recap(_ gross: Int) -> PostRecap {
    let p = store.me?.profile
    return PostRecap(name: p?.display_name ?? "You", marker: p?.marker ?? "saguaro", gross: gross, pvi: show.epilogue.pvi,
                     points: show.epilogue.points.map { Int($0) }, course: show.course ?? "", date: show.playedOn ?? "",
                     badge: show.epilogue.earned.first.flatMap { PostRecap.badges[$0.kind] })
  }

  /// `csShareLink('round', roundId, text)` — the native share sheet, the clipboard as its fallback.
  private func link() async {
    linking = true; defer { linking = false }
    do {
      let url = try await svc.shareLink(round: show.roundId) { data in PostPhoto.compress(data: data, maxDim: 1600, quality: 0.8) }
      let text = PostEpilogue.linkText(name: store.me?.profile?.display_name, gross: show.epilogue.gross ?? 0, course: show.course)
      share = PostShareItem(items: [text, url])
    } catch { toast.show(HumanError.text(error, prefix: "Could not make the link."), kind: .failed) }
  }

  private func revoke() async {
    revoking = true; defer { revoking = false }
    do { try await svc.revokeLink(round: show.roundId); toast.show(PostEpilogue.revokedToast) }
    catch { toast.show(HumanError.text(error, prefix: "Could not revoke."), kind: .failed) }
  }
}
