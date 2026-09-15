// Cup Season — "Go head to head" (D237 / R-F / R-J; IA §9; CORE_FLOWS §9).
//
// The golfer, then ONE more question, and never a guess. R-F ruled the shape;
// D363 (owner, 2026-09-15) reworded the three so none reads as a date:
//
//     Play with Alex
//     ▌ Play a round      → one round together — now, or on the schedule
//     ▌ Go head to head   → each of you posts a round before it closes
//     ▌ Start a season    → rounds over time — a table, and a cup at the end
//
// ALL THREE ARE ALWAYS OFFERED. The person's state may ORDER them — a golfer
// already in a live round sees "Play a round" first; two who share a season see
// "Start a season" last — but none is ever withheld, and the golfer never meets
// the object's name. `CalloutLength` (Kit) owns the words and the ordering
// rule, so both are tests rather than the way this file happens to be written.
// And the PERSON RIDES: every route lands with Alex already in it (`PlayRoute`).

import SwiftUI
import CSDesign
import CupSeasonKit

struct LengthStep: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let opponent: TagCandidate
  /// Already in a live round — orders "Play a round" first.
  var liveNow: Bool = false
  /// The seasons I am in, for the shared-season read.
  var myLeagues: [UUID] = []
  /// D363 · the route, WITH the person. `.aRound` forks into now / schedule
  /// on this same sheet before anything is taken.
  let take: (PlayRoute) -> Void
  let putAForfeitOnIt: (UUID) -> Void
  /// Resolved once, from a read. Until it lands the three render in their
  /// default order — an ORDER may settle late; a WITHHELD length may not exist
  /// at all, which is why nothing here can shorten the list.
  @State private var shared: UUID? = nil
  /// The second page: "Play a round" asks now-or-schedule.
  @State private var roundFork = false

  private var shareASeason: Bool { shared != nil }
  private var lengths: [CalloutLength] { CalloutLength.offered(liveNow: liveNow, shareASeason: shareASeason) }

  var body: some View {
    // D258 · **THIS SHEET WAS THE WORST AX3 FAILURE IN THE BUILD.** Three
    // rows and a header in 340 fixed points at the accessibility sizes drew
    // the rows ON TOP OF EACH OTHER and ended two of the three glosses in an
    // ellipsis — "best round by Sunday ta…", on the screen whose whole job is
    // to explain what the three lengths mean. A scroller and an AX-aware
    // detent, and nothing is clipped at any size.
    ScrollView {
    VStack(alignment: .leading, spacing: 4) {
      if roundFork { fork } else { three }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(cs.bg0)
    .csFittedSheet(shareASeason ? 400 : 340)
    .accessibilityIdentifier("play.with.sheet")
    .task { shared = await ForfeitService().sharedLeague(with: opponent.id, mine: myLeagues) }
  }

  /// The three routes. No row wears ember: choosing where to play is an
  /// ordinary action (D359), not a live competition.
  @ViewBuilder private var three: some View {
    CSSheetHeader(title: CalloutLength.head(opponent.name), sub: "THREE WAYS · PICK ONE")
    ForEach(Array(lengths.enumerated()), id: \.element) { i, len in
      Button {
        CSHaptic.selection()
        CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("length:\(len.rawValue)")])
        switch len {
        case .aRound:     CSMotion.run(CSMotion.tick) { roundFork = true }
        case .headToHead: dismiss(); take(.headToHead)
        case .aSeason:    dismiss(); take(.season)
        }
      } label: {
        VStack(alignment: .leading, spacing: 3) {
          Text(len.title).csType(.name).foregroundStyle(cs.ink)
          Text(len.gloss).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12).frame(minHeight: 56)
        // No rule under the last one when nothing follows it — a hairline
        // with nothing below reads as a row that failed to render.
        .overlay(alignment: .bottom) { if i < lengths.count - 1 || shareASeason { CSRule() } }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("play.with.\(len.rawValue)")
      .accessibilityElement(children: .combine)
      .accessibilityLabel("\(len.title). \(len.gloss)")
    }
    // Where the two already share a season, the fourth line is the act that
    // fits what is already running (T-02: a forfeit, never a fourth noun).
    if shareASeason {
      Button { CSHaptic.selection(); dismiss(); if let l = shared { putAForfeitOnIt(l) } } label: {
        Text("Put a pride bet on it").csType(.nameS).foregroundStyle(cs.ink)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 12).frame(minHeight: 50)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  /// "Play a round" → now, or on the schedule. The person rides into either.
  @ViewBuilder private var fork: some View {
    CSSheetHeader(title: PlayWithCopy.roundHead, sub: "A ROUND WITH \(CSBands.fn1(opponent.name).uppercased())")
    forkRow(PlayWithCopy.nowTitle, PlayWithCopy.nowGloss, id: "play.with.now", rule: true) { dismiss(); take(.liveNow) }
    forkRow(PlayWithCopy.laterTitle, PlayWithCopy.laterGloss, id: "play.with.plan", rule: false) { dismiss(); take(.plan) }
    Button { CSHaptic.selection(); CSMotion.run(CSMotion.tick) { roundFork = false } } label: {
      Text(PlayWithCopy.back).csType(.nameS).foregroundStyle(cs.mut)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Back to the three ways")
  }

  private func forkRow(_ title: String, _ gloss: String, id: String, rule: Bool, action: @escaping () -> Void) -> some View {
    Button {
      CSHaptic.selection()
      CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string(id)])
      action()
    } label: {
      VStack(alignment: .leading, spacing: 4) {
        Text(title).csType(.name).foregroundStyle(cs.ink)
        Text(gloss).csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 12).frame(minHeight: 56)
      .overlay(alignment: .bottom) { if rule { CSRule() } }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(id)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(title). \(gloss)")
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
        CSSheetHeader(title: CalloutCopy.sheetTitle(vm.opponent.name), sub: CalloutCopy.sheetSub)
        // D363 · the three facts a first-timer needs BEFORE any stake: the day
        // it closes (the real one, from the shared Sunday rule), how it is
        // decided, and what the other golfer sees. Then that nothing scores.
        VStack(alignment: .leading, spacing: 8) {
          Text(CalloutCopy.closesRow(closesOn: vm.closesOn)).csType(.name).foregroundStyle(cs.ink)
            .accessibilityIdentifier("callout.closes")
          Text(CalloutCopy.basis).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          Text(CalloutCopy.invitation(vm.opponent.name)).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("callout.invitation")
          // Zero points, always (D21).
          CSFine(CalloutCopy.noPoints)
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

        Button(CalloutCopy.send) {
          Task { if let id = await vm.send() { onSent(id); dismiss() } }
        }
          .buttonStyle(.csPrimary(busy: vm.busy))
          .accessibilityIdentifier("callout.send")
        .padding(.top, 6)
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
      Text(label).csType(.columnS).multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(on ? cs.bg0 : cs.ink)
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(on ? cs.ink : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
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
    // D258 · the reply is two buttons and a sentence, and at AX3 the sentence
    // alone was taller than the 320 points it was pinned to.
    ScrollView {
    VStack(alignment: .leading, spacing: 12) {
      CSSheetHeader(title: CalloutCopy.received(from), sub: "IT'S FOR THE RECORD")
      Text(CalloutCopy.receivedSub(closesOn: closesOn, terms: terms))
        .csType(.story).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      Button(CalloutCopy.accept) { answer(true) }
        .buttonStyle(.csPrimary(busy: busy))
      Button(CalloutCopy.decline) { answer(false) }
        .buttonStyle(.csSecondary(busy: busy))
      CSFine(CalloutCopy.noPoints)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(cs.bg0)
    .csToasts(toasts)
    .csFittedSheet(320)
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
          // §6.1 · the destination's own geometry, redacted — three rows the
          // width of the rows that are coming, so the sheet does not resize
          // under the golfer when they arrive.
          VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { _ in
              CSRule()
              HStack { Text("A golfer’s name").csType(.name); Spacer() }
                .frame(minHeight: 52)
            }
          }
          .csRedacted(true)
        } else if people.isEmpty {
          Text(CalloutCopy.noBuddies).csType(.story).foregroundStyle(cs.ink)
          Button { CSHaptic.selection(); dismiss(); findGolfers() } label: {
            Text(CalloutCopy.noBuddiesDoor.uppercased()).csEyebrow(cs.brand).a11yHitSlop()
          }
          .buttonStyle(.plain)
        } else {
          ForEach(people) { p in
            Button { CSHaptic.selection(); dismiss(); take(p) } label: {
              HStack(spacing: 10) {
                CSMarkerView(key: p.marker, size: 20)
                Text(p.name).csType(.name).foregroundStyle(cs.ink)
                Spacer(minLength: 8)
              }
              .padding(.vertical, 10).frame(minHeight: 52)
              .overlay(alignment: .bottom) { CSRule() }
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

  /// D366 · the season, contest or plan this hangs on, named when the door knows it.
  var contextName: String? = nil

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        // D366 (F6) · WHAT THIS IS, before any field: a record of an agreement
        // made between you — not a challenge, not a contest, not a form that
        // scores anything. Who, where it lives, what decides it, how it is
        // confirmed, where it shows, and that league points are untouched.
        CSSheetHeader(title: ForfeitCopy.title, sub: ForfeitCopy.sub)
        CSFine(ForfeitCopy.purpose).accessibilityIdentifier("pride.purpose")
        Text(ForfeitCopy.whoLabel).csEyebrow().padding(.top, 4)
        Text(ForfeitCopy.who(opponentName)).csType(.name).foregroundStyle(cs.ink)
          .accessibilityIdentifier("pride.who")
        Text(ForfeitCopy.whereLabel).csEyebrow().padding(.top, 4)
        Text(ForfeitCopy.context(home, name: contextName)).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityIdentifier("pride.context")
        Text(ForfeitCopy.nameLabel).csEyebrow().padding(.top, 4)
        CSField(ForfeitCopy.namePlaceholder, text: $name, font: CSFont.body)
        Text(ForfeitCopy.termsLabel).csEyebrow().padding(.top, 4)
        CSField(ForfeitCopy.termsPlaceholder, text: $terms, font: CSFont.body)
        Text("\(ForfeitCopy.decidesLabel) · \(ForfeitCopy.decidesOptional)").csEyebrow().padding(.top, 4)
        CSField(ForfeitCopy.settlesPlaceholder, text: $hangs, font: CSFont.body)
        CSFine(ForfeitCopy.confirm(opponentName)).accessibilityIdentifier("pride.confirm")
        CSFine(ForfeitCopy.points)
        CSFine(ForfeitCopy.whereItShows)
        Button(ForfeitCopy.put) { post() }
          .buttonStyle(.csPrimary(busy: busy)).padding(.top, 6)
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
