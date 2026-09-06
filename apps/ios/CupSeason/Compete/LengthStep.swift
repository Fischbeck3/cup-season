// Cup Season — "Go head to head" (D237 / R-F / R-J; IA §9; CORE_FLOWS §9).
//
// The golfer, then ONE more question, and never a guess. R-F ruled the shape
// and the words:
//
//     How long?
//     ▌ This Saturday   → a live match, on one card
//     ▌ One week        → best round by Sunday takes it
//     ▌ A season        → a table, and a cup at the end
//
// ALL THREE ARE ALWAYS OFFERED. The person's state may ORDER them — a golfer
// already in a live round sees "This Saturday" first; two who share a season see
// "A season" last — but none is ever withheld, and the golfer never meets the
// object's name. `CalloutLength` (Kit) owns the words and the ordering rule, so
// both are tests rather than the way this file happens to be written.

import SwiftUI
import CSDesign
import CupSeasonKit

struct LengthStep: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let opponent: TagCandidate
  /// Already in a live round — orders "This Saturday" first.
  var liveNow: Bool = false
  /// The seasons I am in, for the shared-season read.
  var myLeagues: [UUID] = []
  let take: (CalloutLength) -> Void
  let putAForfeitOnIt: (UUID) -> Void
  /// Resolved once, from a read. Until it lands the three render in their
  /// default order — an ORDER may settle late; a WITHHELD length may not exist
  /// at all, which is why nothing here can shorten the list.
  @State private var shared: UUID? = nil

  private var shareASeason: Bool { shared != nil }
  private var lengths: [CalloutLength] { CalloutLength.offered(liveNow: liveNow, shareASeason: shareASeason) }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      CSSheetHeader(title: CalloutLength.question, sub: "YOU AND \(CSBands.fn1(opponent.name).uppercased())")
      ForEach(Array(lengths.enumerated()), id: \.element) { i, len in
        Button {
          CSHaptic.selection()
          CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("length:\(len.rawValue)")])
          dismiss(); take(len)
        } label: {
          VStack(alignment: .leading, spacing: 3) {
            Text(len.title).font(CSFont.sentenceBold).foregroundStyle(i == 0 ? cs.brand : cs.ink)
            Text(len.gloss).font(CSFont.footnote).foregroundStyle(cs.dimText)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 12).frame(minHeight: 56)
          // No rule under the last one when nothing follows it — a hairline
          // with nothing below reads as a row that failed to render.
          .overlay(alignment: .bottom) { if i < lengths.count - 1 || shareASeason { CSHairline() } }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(len.title). \(len.gloss)")
      }
      // Where the two already share a season, the fourth line is the act that
      // fits what is already running (T-02: a forfeit, never a fourth noun).
      if shareASeason {
        Button { CSHaptic.selection(); dismiss(); if let l = shared { putAForfeitOnIt(l) } } label: {
          Text("Put a forfeit on it").font(CSFont.monoMediumBody).foregroundStyle(cs.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12).frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg0)
    .presentationDetents([.height(shareASeason ? 400 : 340)])
    .presentationDragIndicator(.visible)
    .task { shared = await ForfeitService().sharedLeague(with: opponent.id, mine: myLeagues) }
  }
}

// MARK: - the callout sheet (the "One week" length)

/// D237 · one sheet on top of two small RPCs. The window is a week by default;
/// the stake, if any, is a FORFEIT in words (T-02) and never an amount.
struct CalloutSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @State private var vm: CalloutModel
  @State private var toasts: CSToastCenter
  let onSent: (UUID) -> Void

  init(opponent: TagCandidate, onSent: @escaping (UUID) -> Void) {
    self.onSent = onSent
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: CalloutModel(opponent: opponent, toasts: t))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        CSSheetHeader(title: CalloutCopy.sheetTitle(vm.opponent.name), sub: "BRAVADO WITH A RECEIPT")
        VStack(alignment: .leading, spacing: 2) {
          Text(CalloutCopy.windowRow).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
          Text(CalloutCopy.openLine(closesOn: vm.closesOn)).font(CSFont.footnote).foregroundStyle(cs.dimText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Text(CalloutCopy.stakeQuestion).csEyebrow().padding(.top, 4)
        A11yStack(spacing: 6) {
          pill(CalloutCopy.stakeNone, on: !vm.hasStake) { vm.hasStake = false }
          pill(CalloutCopy.stakeForfeit, on: vm.hasStake) { vm.hasStake = true }
        }
        if vm.hasStake {
          CSField(CalloutCopy.stakePlaceholder, text: $vm.terms, font: CSFont.body)
            .accessibilityLabel(CalloutCopy.stakeForfeit)
          CSFine(ForfeitCopy.definition)
        }

        CSButton(CalloutCopy.send, busy: vm.busy) {
          Task { if let id = await vm.send() { onSent(id); dismiss() } }
        }
        .padding(.top, 6)
        // Zero points, always (D21).
        CSFine(CalloutCopy.noPoints)
      }
      .padding(20)
    }
    .background(cs.bg0)
    .csToasts(toasts)
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  private func pill(_ label: String, on: Bool, action: @escaping () -> Void) -> some View {
    Button { CSHaptic.selection(); action() } label: {
      Text(label).font(CSFont.monoSmall).lineLimit(1).minimumScaleFactor(0.8)
        .foregroundStyle(on ? cs.bg0 : cs.ink)
        .padding(.horizontal, 10).frame(maxWidth: .infinity, minHeight: 44)
        .background(on ? cs.ink : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: on ? 0 : 1))
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(on ? [.isSelected] : [])
  }
}

@MainActor
@Observable
final class CalloutModel {
  let opponent: TagCandidate
  var hasStake = false
  var terms = ""
  var busy = false
  /// A week out, as a CALENDAR date through CSDate (L-07).
  let closesOn: String
  private let toasts: CSToastCenter
  private let svc = CalloutService()

  init(opponent: TagCandidate, toasts: CSToastCenter, today: String = CSDate.today()) {
    self.opponent = opponent
    self.toasts = toasts
    self.closesOn = CalloutLength.defaultClose(today: today)
  }

  func send() async -> UUID? {
    guard !busy else { return nil }
    busy = true; defer { busy = false }
    do {
      let id = try await svc.callOut(opponent.id, closesOn: closesOn, forfeitTerms: hasStake ? terms : nil)
      CSHaptic.success()
      toasts.show("Sent. \(CalloutCopy.openLine(closesOn: closesOn))")
      return id
    } catch {
      // Wave 6's rule: `.notYet` is not `.failed`, and "it couldn't be sent"
      // over a database that has not had the migration is a lie.
      toasts.show(CalloutService.notYet(error) ? CalloutService.notYetLine : HumanError.text(error))
      return nil
    }
  }
}

// MARK: - the recipient's door

/// Tier 1 on their Home. **I'm in** · **Not this week** — and a decline closes
/// it silently, writes no story and leaves no mark on anybody (L-22).
struct CalloutReplySheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let eventId: UUID
  let from: String
  let closesOn: String
  var terms: String? = nil
  let onAnswered: (Bool) -> Void
  @State private var busy = false
  @State private var toasts = CSToastCenter()

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      CSSheetHeader(title: CalloutCopy.received(from), sub: "IT'S FOR THE RECORD")
      Text(CalloutCopy.receivedSub(closesOn: closesOn, terms: terms))
        .font(CSFont.sentence).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      CSButton(CalloutCopy.accept, busy: busy) { answer(true) }
      CSButton(CalloutCopy.decline, style: .quiet, busy: busy) { answer(false) }
      CSFine(CalloutCopy.noPoints)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg0)
    .csToasts(toasts)
    .presentationDetents([.height(320)])
    .presentationDragIndicator(.visible)
  }

  private func answer(_ accept: Bool) {
    busy = true
    Task {
      defer { busy = false }
      do {
        _ = try await CalloutService().respond(eventId, accept: accept)
        if accept { CSHaptic.success() }
        dismiss()
        onAnswered(accept)
      } catch {
        toasts.show(CalloutService.notYet(error) ? CalloutService.notYetLine : HumanError.text(error))
      }
    }
  }
}

// MARK: - the golfer picker

/// "Who?" → buddies, then anyone I have actually played with, most-played
/// first. One tap. The empty state ends in a next move (L-32).
struct PickAGolferSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  var head: String = "Who?"
  let take: (TagCandidate) -> Void
  let findGolfers: () -> Void
  @State private var people: [TagCandidate] = []
  @State private var loaded = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        CSSheetHeader(title: head, sub: "YOUR BUDDIES")
        if !loaded {
          ProgressView().tint(cs.brand).frame(maxWidth: .infinity)
        } else if people.isEmpty {
          Text(CalloutCopy.noBuddies).font(CSFont.sentence).foregroundStyle(cs.ink)
          Button { CSHaptic.selection(); dismiss(); findGolfers() } label: {
            Text(CalloutCopy.noBuddiesDoor.uppercased()).csEyebrow(cs.brand).a11yHitSlop()
          }
          .buttonStyle(.plain)
        } else {
          ForEach(people) { p in
            Button { CSHaptic.selection(); dismiss(); take(p) } label: {
              HStack(spacing: 10) {
                CSMarkerView(key: p.marker, size: 20)
                Text(p.name).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
                Spacer(minLength: 8)
              }
              .padding(.vertical, 10).frame(minHeight: 52)
              .overlay(alignment: .bottom) { CSHairline() }
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(p.name)
          }
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    .task {
      people = await ScheduleService().tagCandidates(league: nil)
      loaded = true
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }
}

// MARK: - the forfeit sheet, reachable without a season (D242)

struct ForfeitSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let home: ForfeitHome
  var opponentName: String? = nil
  var onPosted: () -> Void = {}
  @State private var name = ""
  @State private var terms = ""
  @State private var hangs = ""
  @State private var busy = false
  @State private var toasts = CSToastCenter()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        CSSheetHeader(title: ForfeitCopy.title, sub: opponentName.map { "YOU AND \(CSBands.fn1($0).uppercased())" } ?? "BETS FOR PRIDE")
        Text(ForfeitCopy.nameLabel).csEyebrow()
        CSField(ForfeitCopy.namePlaceholder, text: $name, font: CSFont.body)
        Text(ForfeitCopy.termsLabel).csEyebrow().padding(.top, 4)
        CSField(ForfeitCopy.termsPlaceholder, text: $terms, font: CSFont.body)
        Text(ForfeitCopy.settlesLabel).csEyebrow().padding(.top, 4)
        CSField(ForfeitCopy.settlesPlaceholder, text: $hangs, font: CSFont.body)
        CSButton(ForfeitCopy.put, busy: busy) { post() }.padding(.top, 6)
        CSFine(ForfeitCopy.definition)
        CSFine(ForfeitCopy.noPush)
      }
      .padding(20)
    }
    .background(cs.bg0)
    .csToasts(toasts)
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  private func post() {
    if let why = home.refusal { toasts.show(why); return }
    busy = true
    Task {
      defer { busy = false }
      do {
        try await ForfeitService().post(home, name: name.trimmingCharacters(in: .whitespaces),
                                        terms: terms.trimmingCharacters(in: .whitespaces),
                                        hangs: hangs.trimmingCharacters(in: .whitespaces))
        CSHaptic.success()
        dismiss(); onPosted()
      } catch { toasts.show(HumanError.text(error, prefix: "Couldn’t put it on the record.")) }
    }
  }
}
