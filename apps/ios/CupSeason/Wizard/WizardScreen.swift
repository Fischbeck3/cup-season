// Cup Season — the wizard, re-cut (D225 / O-04; IA §6.3; CORE_FLOWS §7).
//
// It asked the league name TWICE, introduced "PRO — THAT'S YOU", then asked
// "How serious is your league?" over three preset cards that recited four dials
// each (a live L-16 violation), then printed ten all-caps bylaw rows, and showed
// the first invite surface on the FIFTH screen, after Lock.
//
// It asks three questions now, in this order:
//
//   1 · Who's playing?              → and the structure is DERIVED from the answer
//   2 · How long, and when's the first tee?
//   3 · What's on it?               → and above $0, how they pay you (required)
//   then: the rules in one sentence · Name it (pre-filled) · Start the season
//
// NOTHING IS MINTED UNTIL THE LAST TAP. Prod holds six founder-alone `setup`
// leagues because "Start the league" minted a row on a typed NAME. The name is
// asked LAST, it is pre-filled from the roster, and `WizardService.publish`
// makes every write on that one tap. An abandoned wizard leaves nothing behind.
//
// THE INVITE IS ON THE SAME SCREEN AS "START THE SEASON", not five screens
// later, and the share row is the web's four controls (D114's phone half).
//
// A CLOSE ON EVERY STEP (CJ-08: it is a fullScreenCover with no exit today).

import SwiftUI
import CSDesign
import CupSeasonKit

/// Where the wizard hands off. The host wires these.
struct WizardLinks {
  /// The season is live (and the share screen was dismissed) — open it.
  var onLocked: (UUID) -> Void
  /// Cancelled; nothing was minted.
  var onCancelled: () -> Void
  /// The intent sheet's "We're playing this weekend" and the Ryder door.
  var startEvent: () -> Void
  /// A join completed.
  var onJoined: (UUID) -> Void = { _ in }
  /// Step 1's empty branch: contacts (D251, wave 8) and the person link (D241).
  var findGolfers: () -> Void = {}
}

/// D41: last season's bylaws carried into a fresh season (`window._runItBack`).
struct WizardRunBack {
  let name: String
  let bylaws: LeagueRoom.Settings?
}

struct WizardScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var model: WizardModel
  let links: WizardLinks

  init(existingLeagueId: UUID?, links: WizardLinks, runBack: WizardRunBack? = nil, initialStep: Int = 0) {
    _model = State(initialValue: WizardModel(existingLeagueId: existingLeagueId, runBack: runBack, initialStep: initialStep))
    self.links = links
  }

  var body: some View {
    Group {
      if model.loading {
        // §6.1 · the wizard's own head and first field, redacted — the step
        // the golfer is about to read, in the place they will read it.
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          Text("Setting up").csType(.agate, caps: true)
          Text("A season for the fellas").csType(.lead)
          CSRule()
          Text("Every league needs a name and a first tee.").csType(.body)
        }
        .csRedacted(true)
        .padding(CSTokens.Space.s4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      } else {
        wizard
      }
    }
    .background(cs.bg0)
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    // CJ-08 · a way out of every step, always — and §7.3's one dismiss verb,
    // in the one style, at the one position.
    .csCloseButton { close() }
    .task { await model.load(toast: toast, alreadyLocked: { links.onLocked($0) }, store: store) }
    .sheet(item: $model.share, onDismiss: { if let id = model.lockedLeague { links.onLocked(id) } }) { s in
      WizardLockShareSheet(share: s)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
  }

  // MARK: the three questions

  private var wizard: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          Text(head).csType(.displayS).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true).id("top")
          WizardDots(step: model.step)
          switch model.step {
          case 0: WizardWhoStep(model: model, findGolfers: links.findGolfers)
          case 1: WizardWhenStep(model: model)
          default: WizardStakeStep(model: model, publish: publish)
          }
          nav
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 32)
      }
      .scrollDismissesKeyboard(.interactively)
      .onChange(of: model.step) { _, _ in CSMotion.run(CSMotion.rise) { proxy.scrollTo("top", anchor: .top) } }
    }
  }

  private var head: String {
    switch model.step {
    case 0: return WizardCopy.step1
    case 1: return WizardCopy.step2
    default: return WizardCopy.step3
    }
  }

  /// Back / Next. Step 2 has no Next — its own **Start the season** is the tap.
  private var nav: some View {
    A11yStack(spacing: 10) {
      if model.step > 0 {
        Button(WizardCopy.back) { model.step = max(0, model.step - 1) }.buttonStyle(.csSecondary())
      }
      if model.step < 2 {
        Button(WizardCopy.next) { CSHaptic.selection(); model.step = min(2, model.step + 1) }.buttonStyle(.csPrimary())
      }
    }
    .padding(.top, 6)
  }

  private func close() {
    Task {
      // Nothing was minted unless this is an in-progress league from before the
      // re-cut, in which case Cancel still discards it.
      try? await model.discardIfMinted()
      links.onCancelled()
    }
  }

  private func publish() {
    Task {
      switch await model.publish() {
      case .blocked(let why): toast.show(why)
      case .failed(let msg): toast.show(msg)
      case .live(let note):
        CSHaptic.success()
        if let note { toast.show(note) }
        await store.reload()
      }
    }
  }
}

/// `.wizdots` — three dots, lit up to the current step, in ember.
struct WizardDots: View {
  @Environment(\.cs) private var cs
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let step: Int
  var body: some View {
    HStack(spacing: 6) {
      ForEach(0..<3, id: \.self) { i in
        // the step marks are ink, not ember — three steps of a form are not three
        // live actions, and only the one you are on is filled
        Rectangle().fill(i == step ? cs.ink : cs.rule).frame(width: i == step ? 22 : 8, height: 4)
          .csAnimation(CSMotion.rise, value: step)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Step \(step + 1) of 3")
  }
}

// MARK: - The model

@MainActor
@Observable
final class WizardModel {
  var dials: WizardDials
  var step: Int
  var busy = false
  var loading = false
  var showDials = false
  /// nil until the golfer is asked (four or more). Below four it is never asked
  /// and the structure is solo by derivation.
  var squadsChosen: Bool? = nil
  var buddies: [TagCandidate] = []
  var buddiesLoaded = false
  var nameTouched = false
  private(set) var leagueId: UUID?
  private(set) var code: String?
  private(set) var storedName = ""
  private(set) var runBack: WizardRunBack?
  var share: WizardLockShare?
  private(set) var lockedLeague: UUID?

  private let svc = WizardService()
  private let sched = ScheduleService()
  private let existingLeagueId: UUID?

  init(existingLeagueId: UUID?, runBack: WizardRunBack?, initialStep: Int) {
    self.existingLeagueId = existingLeagueId
    self.runBack = runBack
    self.step = max(0, min(2, initialStep))
    if let rb = runBack, let b = rb.bylaws {
      dials = WizardDials.from(b, name: rb.name)
    } else {
      dials = WizardDials(name: runBack?.name ?? "")
    }
  }

  /// The roster the season will have: me, plus everyone picked — and never
  /// fewer than the number the organiser gave at step 1 (QB-13). Everything
  /// downstream reads this: the pot line, the structure-fit line, the squads
  /// question and the first-tee default.
  var roster: Int { dials.plannedRoster }
  var portrait: WizardPortrait { WizardPortrait(dials, roster: roster) }
  var asksAboutSquads: Bool { WizardDials.asksAboutSquads(roster: roster) }

  /// The name, pre-filled from the roster until the golfer types over it.
  func syncName(myName: String?) {
    guard !nameTouched, dials.name.trimmingCharacters(in: .whitespaces).isEmpty || !nameTouched else { return }
    let names = ([myName] + dials.invitees.compactMap { id in buddies.first { $0.id == id }?.name }).compactMap { $0 }
    let s = WizardDials.suggestedName(names)
    if !s.isEmpty { dials.name = s }
  }

  func load(toast: CSToastCenter, alreadyLocked: @escaping (UUID) -> Void, store: SessionStore) async {
    if buddies.isEmpty && !buddiesLoaded {
      buddies = await sched.tagCandidates(league: nil)
      buddiesLoaded = true
      syncName(myName: store.me?.profile?.display_name)
    }
    guard let id = existingLeagueId, leagueId == nil else { return }
    loading = true
    defer { loading = false }
    do {
      guard let head = try await svc.league(id) else { toast.show("That season isn't there any more.", kind: .failed); return }
      if head.phase != "setup" { alreadyLocked(id); return }   // D40: only a setup season belongs here
      let b = try? await svc.bylaws(id)
      let s = try? await svc.season(id)
      if let b { dials = WizardDials.from(b, name: WizardCopy.isUnnamed(head.name) ? "" : head.name, season: s) }
      else { dials.name = WizardCopy.isUnnamed(head.name) ? "" : head.name }
      storedName = head.name
      code = head.code
      leagueId = id
      nameTouched = !WizardCopy.isUnnamed(head.name)
    } catch { toast.show(HumanError.text(error, prefix: "Could not open this."), kind: .failed) }
  }

  enum PublishResult { case blocked(String), failed(String), live(String?) }

  /// One tap. `create_league` → `lock_league(+ p_pay_note)` → one
  /// `invite_golfer` per picked buddy, and the share screen is the same screen.
  func publish() async -> PublishResult {
    // The one required field the wizard gains (D225).
    if dials.payNoteMissing { step = 2; return .blocked(WizardCopy.payMissing) }
    var d = dials
    d.structure = WizardDials.derivedStructure(roster: roster, squadsChosen: squadsChosen)
    if d.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { d.name = storedName }
    busy = true
    defer { busy = false }
    svc.track(.lock_attempt)

    do {
      // An in-progress league from before the re-cut already has its row.
      if let id = leagueId {
        let locked = try await svc.lock(leagueId: id, dials: d, fallbackName: storedName)
        return finish(leagueId: id, code: code ?? "", name: d.name.isEmpty ? storedName : d.name,
                      locked: locked, invited: 0, notInvited: 0, dials: d)
      }
      let p = try await svc.publish(dials: d)
      leagueId = p.leagueId; code = p.code; storedName = p.name
      return finish(leagueId: p.leagueId, code: p.code, name: p.name, locked: p.locked,
                    invited: p.invited, notInvited: p.notInvited, dials: d)
    } catch {
      return .failed(HumanError.text(error, prefix: WizardCopy.publishFailed))
    }
  }

  private func finish(leagueId id: UUID, code c: String, name: String, locked: WizardService.Locked,
                      invited: Int, notInvited: Int, dials d: WizardDials) -> PublishResult {
    lockedLeague = id
    share = WizardLockShare(leagueId: id, name: name, code: c, nextPhase: locked.nextPhase,
                            members: 1 + invited, structure: d.structure, draftType: d.draftType,
                            startsOn: locked.startsOn, weeks: d.durWeeks, invited: invited)
    // R18 · the note did not land. Named out loud rather than dropped.
    if d.stake > 0 && !locked.payNoteLanded { return .live(WizardCopy.payNoteMissedIt) }
    if notInvited > 0 {
      return .live("\(notInvited) invite\(notInvited == 1 ? "" : "s") didn't send. Share the link instead.")
    }
    return .live(nil)
  }

  /// Only an in-progress league minted BEFORE the re-cut has anything to
  /// discard. A wizard closed at step 1 has written nothing at all.
  func discardIfMinted() async throws {
    guard let id = leagueId, lockedLeague == nil else { return }
    try await svc.deleteLeague(id)
    leagueId = nil; code = nil; storedName = ""
  }
}
