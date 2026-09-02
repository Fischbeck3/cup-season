// Cup Season — the Tour Card: any golfer's whole card, viewable (index.html
// `openTourCard` 13293–13457). The identity object was owner-only; now every
// name is a door. Visibility is enforced server-side.
//
// The buddy action rides directly under the credential — it is the reason
// most people opened this sheet. Settled states render as a tag, not a
// button, so there is nothing to tap that cannot do anything. Mute lives on
// the card (W4) — the one place you already are when someone's posts are the
// problem. Report photo is two-tap; no native confirm (S4-03 lesson).

import SwiftUI
import CSDesign
import CupSeasonKit

struct TourCardSheet: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let profileId: UUID
  let links: YouLinks

  @State private var load: TourCardLoad?
  @State private var failed = false
  @State private var relation: BuddyRelation = .none
  @State private var muted = false
  @State private var busyAdd = false
  @State private var busyMute = false
  @State private var report: ReportState = .idle
  @State private var rivalry: RivalryLine?

  enum ReportState { case idle, armed, sending, done }
  private let repo = TourCardRepository()

  var body: some View {
    Group {
      if let load {
        if load.card.visible { card(load) } else {
          SliceSheet(title: "Tour Card", sub: "PRIVATE") { Fine(TourCard.privateLine) }
        }
      } else if failed {
        // a load failure is not privacy — say so, and offer the retry
        SliceSheet(title: "Tour Card", sub: "COULD NOT LOAD") {
          VStack(alignment: .leading, spacing: 10) {
            Fine("Could not pull the card — check your signal and try again.")
            Button("Try again") { failed = false; Task { await fetch() } }.font(CSFont.subhead).foregroundStyle(cs.dawn)
          }
        }
      } else {
        SliceSheet(title: "Tour Card", sub: "LOADING…") { Fine("Pulling the card…") }
      }
    }
    .task { await fetch() }
    .sheet(item: $rivalry) { r in
      RivalrySheet(opponentId: r.opponent, name: r.name, record: r.record, rivalryName: r.rivalryName)
    }
  }

  private func fetch() async {
    do {
      let l = try await repo.load(profileId)
      relation = l.relation; muted = l.muted; load = l
    } catch { failed = true }
  }

  private func card(_ l: TourCardLoad) -> some View {
    let c = l.card, p = c.profile
    let est = p.memberSince.map { TourCard.established($0) }
    let meta = [p.handle.map { "@\($0)" }, p.city, est].compactMap { $0 }.joined(separator: " · ")
    let vs = c.vsYou
    let canReport = l.avatarURL != nil && profileId != store.session?.user.id
    let form = FormRow.from(beats: c.recent.map(\.beat))
    return SliceSheet(title: p.isMe ? "Your Tour Card" : "Tour Card",
                      sub: p.isMe ? "THIS IS HOW YOUR BUDDIES SEE YOU" : (p.handle.map { "@" + $0.uppercased() } ?? "")) {
      CredentialCard(photoURL: l.avatarURL, marker: p.marker, name: p.displayName ?? "—", badge: store.founding.badge(for: profileId), meta: meta,
                     indexCurrent: p.indexCurrent, rounds: c.career.rounds,
                     // EVERY line: the card caps them at `credentialChips` and
                     // opens the rest in place, so "+N more" is a door now
                     trophyLines: TrophyMeta.credChips(c.trophies), form: form, isMe: p.isMe,
                     anchor: { EmptyView() },
                     extra: {
                       if let vs, vs.total > 0 {
                         VsChip(text: vs.chip, spokenLabel: "Versus you", spokenValue: "\(vs.record), \(vs.lead.lowercased())") {
                           rivalry = RivalryLine(opponent: profileId, name: p.displayName ?? "them", marker: p.marker, facets: "",
                                                 record: vs.record, lead: .even, rivalryName: nil)
                         }
                       }
                     })
      if canReport { reportLine }
      if !p.isMe { buddyAction }

      // D209 · ONE lens, and the eyebrow is where it is named — not buried in
      // each row label. Your own Tour Card and You › All time were printing
      // the same golfer's average with opposite signs, separated on screen by
      // the single word "playing". `tour_card()` now RETURNS the allowance
      // figures (`avg_pvi` corrected to the allowance mean, `best_pvi` added —
      // migration 20260902180000), so under the lens these rows are the You
      // tab's rows, word for word.
      //
      // The fallback is not only for a pre-push server: a golfer no season has
      // ever ranked has no allowance figure at all, and for them the block
      // keeps the 100% average under the 100% label ("Avg vs your number",
      // which is what `avg_vs_index` honestly is) and the course score under
      // "Best round vs course". The phone never prints the You tab's words
      // over a figure that is not the You tab's number.
      //
      // D210 · the banned word leaves the card, abbreviated or not, in either
      // shape.
      Text(TourCard.careerEyebrow(playingLens: c.playingLens, isMe: p.isMe)).csEyebrow().padding(.top, 8)
      VStack(spacing: 0) {
        MathRow(label: TourCard.roundsLabel, value: String(c.career.rounds))
        MathRow(label: TourCard.bestLabel(playingLens: c.playingLens), value: c.bestText)
        MathRow(label: TourCard.avgLabel(playingLens: c.playingLens, isMe: p.isMe), value: c.avgText)
        if let hc = p.homeCourse, !hc.isEmpty { MathRow(label: "Home course", value: RoundCopy.course(hc)) }
        if let g = p.ghin, !g.isEmpty { MathRow(label: "GHIN", value: g) }
      }
      // 8c · the two old figures run opposite ways — a course score where
      // lower wins, beside a delta where + wins — and no single sign is right
      // for both. Under the allowance lens they are one measurement, signed
      // the same way, and this line has nothing left to explain.
      if !c.playingLens {
        Fine(TourCard.careerSignsLine(isMe: p.isMe)).padding(.top, 6)
      }

      if !c.recent.isEmpty {
        Text("Recent rounds").csEyebrow().padding(.top, 8)
        ForEach(c.recent) { r in
          CheckRow(glyph: Text(RivalryCopy.monthDay(r.playedOn)),
                   title: "\(r.gross.map(String.init) ?? "—") GROSS\(r.holesPlayed == 9 ? " · 9 HOLES" : "")",
                   sub: (r.courseLabel.map { RoundCopy.course($0).uppercased() + " · " } ?? "") + "VS COURSE " + (r.differential.map(RoundCopy.f1) ?? "—")) { EmptyView() }
        }
      }

      if !p.isMe {
        MiniButton(label: muted ? "🔈 Unmute — show their posts again" : "🔇 Mute — hide their posts from your boards",
                   tone: cs.mut, busy: busyMute) { Task { await toggleMute() } }
          .padding(.top, 8)
          .accessibilityLabel(muted ? "Unmute, show their posts again" : "Mute, hide their posts from your boards")
      }
    }
  }

  // D59: a visible photo that isn't yours can be reported — two-tap, lands on the founder desk
  private var reportLine: some View {
    Button {
      switch report {
      case .idle: report = .armed; CSHaptic.warning()
      case .armed: Task { await sendReport() }
      default: break
      }
    } label: {
      Text(reportLabel).font(CSFont.footnote).foregroundStyle(report == .armed ? cs.neg : cs.dimText)
        .frame(minHeight: 44, alignment: .leading)
    }
    .buttonStyle(.plain)
    .disabled(report == .sending || report == .done)
    .accessibilityHint(report == .idle ? "Asks once more before it sends" : "")
  }
  private var reportLabel: String {
    switch report {
    case .idle: "Report photo"
    case .armed: "Sure? Report this photo"
    case .sending: "Reporting…"
    case .done: "Reported — the founder desk sees it"
    }
  }
  private func sendReport() async {
    report = .sending
    do { try await repo.reportPhoto(profileId); report = .done }
    catch { report = .idle; ToastCenter.shared.show(SliceFormat.human(error, "Could not send that report.")) }
  }

  @ViewBuilder private var buddyAction: some View {
    if let tag = relation.tag {
      Text(tag).font(CSFont.label).tracking(0.8).foregroundStyle(relation == .friend ? cs.pos : cs.mut).padding(.top, 4)
    } else if let label = relation.actionLabel {
      CSButton(label, style: .quiet, busy: busyAdd) { Task { await addBuddy() } }
    }
  }
  private func addBuddy() async {
    busyAdd = true
    defer { busyAdd = false }
    if case .incoming(let fid) = relation {
      do { try await repo.acceptRequest(fid); ToastCenter.shared.show("Golf buddies ✓"); relation = .friend }
      catch { ToastCenter.shared.show(SliceFormat.human(error, "Could not accept.")) }
    } else {
      do {
        let r = try await repo.friendRequest(profileId)
        ToastCenter.shared.show(r == .friend ? "Golf buddies ✓" : "Request sent")
        relation = r
      } catch { ToastCenter.shared.show(SliceFormat.human(error, "Could not send.")) }
    }
  }

  private func toggleMute() async {
    let on = !muted
    busyMute = true
    do {
      try await repo.setMute(profileId, on: on)
      muted = on
      dismiss()
      ToastCenter.shared.show(on ? "Muted. Their posts drop off your boards." : "Unmuted.")
    } catch {
      busyMute = false
      ToastCenter.shared.show(SliceFormat.human(error, "Could not change that."))
    }
  }
}
