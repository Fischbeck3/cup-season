// Cup Season — THE HEAD-TO-HEAD (IOS-032, D239, IA §10.4).
//
// "You're playing Jake Saturday. Jake has beaten you 3 of the last 5." is the
// brief's own target sentence, and until this page the app could not say the
// second half of it for two golfers who share no season — every one of the
// three implementations of "the record between us" joins `league_members ×
// seasons`.
//
// The page is the six facets, each with its own basis, over one summary that
// is the SUM of the same rows the facets counted. The server guarantees that
// (R4 materialises every meeting once); this screen never re-adds anything.
//
// THREE THINGS THIS PAGE SAYS OUT LOUD, because a record that hides them is a
// record that is quietly wrong:
//   * the same-day/same-course fallback is LABELLED wherever it contributed
//   * a tag nobody has confirmed says so
//   * a meeting with no verdict is not a tie — it is counted as a meeting and
//     as nobody's win
//
// P-17 rides the top bar (L-38): this is a surface about another golfer, and
// report and mute have to be reachable from it.

import SwiftUI
import CSDesign
import CupSeasonKit

struct HeadToHeadPage: View {
  @Environment(\.cs) private var cs
  let opponentId: UUID
  /// The name the caller already knows, so the page has a title before the
  /// read lands and never shows a bare "—" in its own header.
  var fallbackName: String?
  var openPerson: (UUID) -> Void = { _ in }
  var stageRound: ((_ playOn: String, _ tag: UUID) -> Void)? = nil

  @State private var model = HeadToHeadModel()
  @State private var naming = false

  private var name: String {
    if let n = model.h2h?.opponent.displayName, !n.isEmpty { return n }
    if let n = model.resolved, !n.isEmpty { return n }
    return fallbackName ?? "them"
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        CSPageHeader("You and \(name)", eyebrow: eyebrow) { EmptyView() }

        switch model.state {
        case .loading:
          skeleton
        case .failed:
          EmptyRootView(root: EmptyRoot.failedRead()) { _ in Task { await model.load(opponentId, name: fallbackName) } }
        case .empty:
          EmptyRootView(root: HeadToHeadCopy.empty(name)) { take($0) }
        case .ready:
          if let h = model.h2h { body(h) }
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    // The bar stays, so there is a way back; P-17 rides its trailing edge.
    .navigationTitle(name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) { CSSafetyMenu(profileId: opponentId, name: name) }
    }
    .refreshable { await model.load(opponentId, name: fallbackName) }
    .task(id: opponentId) { await model.load(opponentId, name: fallbackName) }
    .sheet(isPresented: $naming, onDismiss: { Task { await model.load(opponentId, name: fallbackName) } }) {
      NameRivalrySheet(opponentId: opponentId, opponentName: name, current: model.h2h?.rivalryName)
    }
    .sliceToastHost()
  }

  /// M3/D18 · a christened rivalry wears its name, in gold, above everything.
  private var eyebrow: String {
    if let n = model.h2h?.rivalryName, !n.isEmpty { return "“\(n.uppercased())”" }
    return CSHeaderDate.today()
  }

  @ViewBuilder private func body(_ h: HeadToHead) -> some View {
    if let head = HeadToHeadCopy.headline(h) {
      Text(head).font(CSFont.title).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
    if let sf = HeadToHeadCopy.standfirst(h) {
      Text(sf).font(CSFont.sentence).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
    }

    // ── LAST FIVE, as dots, oldest → newest, with the legend on the row
    if !h.lastFive.isEmpty { lastFive(h) }

    // ── the facets. A facet with nothing in it never got here (P-6).
    if !h.facets.isEmpty {
      Text("HOW IT ADDS UP").csEyebrow().padding(.top, 8)
      VStack(spacing: 0) {
        ForEach(Array(h.facets.enumerated()), id: \.element.id) { i, f in
          CSRow(last: i == h.facets.count - 1) { facetRow(f, name: name) }
        }
      }
    }

    // L-19 · a tag says who was out there and nothing about the score. It is
    // printed where the tags are counted, not buried in a help sheet.
    if h.facets.contains(where: { $0.facet == .playedTogether }) {
      CSFine(HeadToHeadCopy.notAVouch).padding(.top, 6)
    }

    // ── the doors
    Text("WHAT NOW").csEyebrow().padding(.top, 12)
    VStack(spacing: 0) {
      CSRow {
        YouDoorRow(glyph: Text(Image(systemName: "person.crop.circle")),
                   title: "Open \(name)’s card", sub: nil,
                   action: { openPerson(opponentId) })
      }
      if let stage = stageRound {
        CSRow {
          YouDoorRow(glyph: Text("SAT"), title: TourCard.Length.saturday.label,
                     sub: TourCard.Length.saturday.sub,
                     action: { stage(LastRoundWith.nextSaturday(), opponentId) })
        }
      }
      CSRow(last: true) {
        YouDoorRow(glyph: Text(Image(systemName: "textformat")),
                   title: h.rivalryName == nil ? "Name it" : "Rename “\(h.rivalryName ?? "")”",
                   sub: RivalryCopy.namePlaceholder,
                   action: { naming = true })
      }
    }
  }

  /// The dots read oldest → newest, ember when the meeting was mine — the same
  /// grammar the credential's FORM row uses, so one glyph means one thing on
  /// both surfaces (L-25: ember is live/mine, never decorative).
  @ViewBuilder private func lastFive(_ h: HeadToHead) -> some View {
    Text(TourCard.rowLastFive).csEyebrow().padding(.top, 8)
    HStack(spacing: 6) {
      ForEach(h.lastFive.reversed()) { m in
        Circle()
          .fill(m.won == true ? cs.brand : cs.bg2)
          .overlay(Circle().stroke(m.won == nil ? cs.line2 : Color.clear, lineWidth: 1))
          .frame(width: 10, height: 10)
      }
      Text(lastFiveLegend(h)).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
        .padding(.leading, 6)
    }
    .frame(minHeight: 28)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Last five meetings")
    .accessibilityValue(lastFiveSpoken(h))
  }

  private func lastFiveLegend(_ h: HeadToHead) -> String {
    let mine = h.lastFive.filter { $0.won == true }.count
    return "\(mine) OF \(h.lastFive.count) TO YOU"
  }

  private func lastFiveSpoken(_ h: HeadToHead) -> String {
    h.lastFive.reversed().map { m in
      m.won == true ? "you" : m.won == false ? name : "halved"
    }.joined(separator: ", ")
  }

  private func facetRow(_ f: HeadToHead.FacetLine, name: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(f.facet.head).font(CSFont.label).tracking(1.1).foregroundStyle(cs.mut)
        Spacer(minLength: 8)
        if let rec = f.record {
          VStack(alignment: .trailing, spacing: 2) {
            Text(rec).font(CSFont.monoMediumBody).csTabular()
              .foregroundStyle(f.lead == .up ? cs.pos : f.lead == .down ? cs.dimText : cs.mut)
            Text(RivalryCopy.leadLabel(f.lead)).csEyebrow(cs.mut)
          }
        } else {
          // no verdict yet — say the meetings, never a record that is not one
          Text("\(f.meetings) SO FAR").font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
        }
      }
      if let sub = HeadToHeadCopy.facetSub(f) {
        Text(sub).font(CSFont.footnote).foregroundStyle(cs.dimText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }

  private func take(_ door: EmptyRoot.Door) {
    switch door {
    case .addMyRound: ToastCenter.shared.show("Add it from the ⊕")
    default: openPerson(opponentId)
    }
  }

  private var skeleton: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(0..<4, id: \.self) { _ in
        RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(cs.bg1).frame(height: 44)
      }
    }
    .redacted(reason: .placeholder)
  }
}

// MARK: - The model

@MainActor
@Observable
final class HeadToHeadModel {
  enum State { case loading, failed, empty, ready }
  var state: State = .loading
  var h2h: HeadToHead?
  /// True when the record on screen came from `my_rivalries` rather than R4 —
  /// the season-only fallback, which cannot count two buddies with no league.
  var isFallback = false
  /// The name, however it was learnt — the caller's, the payload's, or the
  /// buddies list. A page titled "them" is a page that did not look.
  var resolved: String?
  private let people = PeopleService()

  func load(_ opponent: UUID, name: String?) async {
    resolved = name
    if let h = await people.headToHead(opponent) {
      isFallback = false
      guard h.visible else { state = .empty; h2h = nil; await resolveName(opponent); return }
      h2h = h
      state = h.record.total > 0 || !h.facets.isEmpty ? .ready : .empty
      if h.opponent.displayName == nil { await resolveName(opponent) }
      return
    }
    // The declared fallback while R4 is unpushed. Its answer is three-valued —
    // a read that did not answer, a read that answered with no record, and a
    // record — and collapsing the middle into the first is what put "Couldn't
    // load this" over a buddy with no shared history on the first screenshot.
    do {
      isFallback = true
      if let h = try await people.headToHeadFallback(opponent, name: name, marker: nil), h.record.total > 0 {
        h2h = h
        state = .ready
        return
      }
      h2h = nil
      state = .empty
      await resolveName(opponent)
    } catch {
      // L-32 · NEITHER read answered. That is a failed read, not an empty
      // record: "nothing between you yet" over a dead network tells a golfer
      // their record was wiped.
      h2h = nil
      state = .failed
    }
  }

  /// The page's title is a person's name, and an empty record still has one.
  /// `my_friends` is the read that already knows it.
  private func resolveName(_ opponent: UUID) async {
    guard resolved == nil || resolved?.isEmpty == true else { return }
    if let lists = try? await people.friends() {
      resolved = (lists.buddies + lists.requested + lists.requests).first { $0.id == opponent }?.displayName
    }
  }
}

#Preview("Head to head") {
  NavigationStack { HeadToHeadPage(opponentId: UUID(), fallbackName: "Galen") }.csTheme()
}
