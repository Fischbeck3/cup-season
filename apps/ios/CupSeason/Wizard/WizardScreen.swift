// Cup Season — `#view-wizard` (index.html 3208–3332; renderWizard 12706;
// the name sheet 17159–17206; the lock button 15226–15261; wizCancel 15278).
//
// Three steps — name + the Pro · competitiveness + the dials · review & lock —
// with the `.wizdots` rail in ember (cs.brand — never `pos`, D76) and the
// Cancel / ← Back / Next → nav. The desktop's "Your league so far" portrait
// rides inside step 1 as a card on the phone. A league row is minted only
// after a name (the "My Cup husks" lesson), and the flow ends on the SHARE
// moment, never a Done toast — a league is only real once the crew is in it.

import SwiftUI
import CSDesign
import CupSeasonKit

/// Where the wizard hands off. The host wires these.
struct WizardLinks {
  /// The bylaws locked (and the share sheet was dismissed) — open the league.
  var onLocked: (UUID) -> Void
  /// Step-0 Cancel discarded the league, or the host should just close.
  var onCancelled: () -> Void
  /// The league-less door "Start an event" (the event picker is another slice).
  var startEvent: () -> Void
  /// The league-less door "Join a league" completed.
  var onJoined: (UUID) -> Void = { _ in }
}

/// D41: last season's bylaws carried into a fresh league (`window._runItBack`).
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
        VStack(spacing: 12) { ProgressView().tint(cs.brand); Text("Loading the wizard…").csEyebrow() }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if model.leagueId == nil {
        nameSheet
      } else {
        wizard
      }
    }
    .background(cs.bg0)
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .task { await model.load(toast: toast, alreadyLocked: { links.onLocked($0) }) }
    .sheet(item: $model.share, onDismiss: { if let id = model.lockedLeague { links.onLocked(id) } }) { s in
      WizardLockShareSheet(share: s)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
  }

  // MARK: the name sheet (`#wCreate`) — a row is minted only after a name

  private var nameSheet: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        CSSheetHeader(title: WizardCopy.nameSheetTitle, sub: WizardCopy.nameSheetSub)
        CSField(WizardCopy.namePlaceholder, text: $model.dials.name, font: CSFont.body)
          .textInputAutocapitalization(.words)
          .submitLabel(.go)
          .onSubmit { create() }
          .accessibilityLabel(WizardCopy.nameLabel)
        CSFine(WizardCopy.nameSheetFine)
        CSButton(WizardCopy.nameSheetGo, busy: model.busy) { create() }.padding(.top, 4)
        CSButton(WizardCopy.cancel, style: .quiet) { links.onCancelled() }
      }
      .padding(20)
    }
    .scrollDismissesKeyboard(.interactively)
  }

  private func create() {
    guard store.session != nil else { toast.show(WizardCopy.signInFirst); return }
    Task {
      if let t = await model.create() { toast.show(t) }
    }
  }

  // MARK: the three steps

  private var wizard: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          Text(WizardCopy.eyebrow).csEyebrow().id("top")
          WizardDots(step: model.step)
          switch model.step {
          case 0: WizardNameStep(model: model)
          case 1: WizardPresetStep(model: model)
          default: WizardReviewStep(model: model, lock: lock)
          }
          nav
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 32)
      }
      .scrollDismissesKeyboard(.interactively)
      .onChange(of: model.step) { _, _ in withAnimation(reduceMotion ? nil : .timingCurve(0.16, 0.84, 0.36, 1, duration: 0.26)) { proxy.scrollTo("top", anchor: .top) } }
    }
  }

  /// `.wiznav` — step 0: Cancel replaces Back; step 2: Next hides. Two across; stacked at the accessibility sizes.
  private var nav: some View {
    A11yStack(spacing: 10) {
      if model.step == 0 {
        WizardCancelButton(busy: model.busy) { discard() }
      } else {
        CSButton(WizardCopy.back, style: .quiet) { model.step = max(0, model.step - 1) }
      }
      if model.step < 2 {
        CSButton(WizardCopy.next) { CSHaptic.selection(); model.step = min(2, model.step + 1) }
      }
    }
    .padding(.top, 6)
  }

  private func discard() {
    Task {
      do {
        try await model.discard()
        toast.show(WizardCopy.discarded)
        links.onCancelled()
      } catch { toast.show(HumanError.text(error, prefix: WizardCopy.couldNotDiscard)) }
    }
  }

  /// `#lockBtn` (15226–15261): telemetry, the D5 unnamed guard, the one `lock_league` call (D111), the share moment.
  private func lock() {
    Task {
      switch await model.lock() {
      case .blocked: toast.show(WizardCopy.nameTheLeagueFirst)
      case .failed(let msg): toast.show(msg)
      case .locked:
        CSHaptic.success()
        toast.show(WizardCopy.bylawsLocked)
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
        Capsule().fill(i <= step ? cs.brand : cs.line2).frame(width: i == step ? 22 : 8, height: 4)
          .animation(reduceMotion ? nil : .timingCurve(0.16, 0.84, 0.36, 1, duration: 0.26), value: step)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Step \(step + 1) of 3")
  }
}

/// Step-0 Cancel: two taps — the web used `confirm()`, the phone never alerts.
struct WizardCancelButton: View {
  @Environment(\.cs) private var cs
  let busy: Bool
  let action: () -> Void
  @State private var armed = false
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      CSButton(armed ? "Sure? Discard it" : WizardCopy.cancel, style: .quiet, busy: busy) {
        if armed { action() } else { armed = true; CSHaptic.warning() }
      }
      if armed { CSFine(WizardCopy.cancelConfirm) }
    }
    .task(id: armed) {
      guard armed else { return }
      try? await Task.sleep(for: .seconds(4))
      armed = false
    }
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
  private(set) var leagueId: UUID?
  private(set) var code: String?
  /// The name on the row (the lock's fallback; "My Cup" is the scaffold, D5).
  private(set) var storedName = ""
  /// `wizRoster()` — the roster the wizard can see: this league's seats (you, at least).
  private(set) var roster = 1
  private(set) var runBack: WizardRunBack?
  var share: WizardLockShare?
  private(set) var lockedLeague: UUID?

  private let svc = WizardService()
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

  var portrait: WizardPortrait { WizardPortrait(dials, roster: roster) }
  var structFit: String { WizardDials.structFitLine(roster: roster) }

  /// An existing setup-phase league opens on its stored dials (`enterLeague` → `applyBylaws`).
  func load(toast: CSToastCenter, alreadyLocked: @escaping (UUID) -> Void) async {
    guard let id = existingLeagueId, leagueId == nil else { return }
    loading = true
    defer { loading = false }
    do {
      guard let head = try await svc.league(id) else { toast.show("No league with that id — it may have been deleted."); return }
      if head.phase != "setup" { alreadyLocked(id); return }   // D40: only a setup league belongs in the wizard
      let b = try? await svc.bylaws(id)
      let s = try? await svc.season(id)
      if let b { dials = WizardDials.from(b, name: WizardCopy.isUnnamed(head.name) ? "" : head.name, season: s) }
      else { dials.name = WizardCopy.isUnnamed(head.name) ? "" : head.name }
      storedName = head.name
      code = head.code
      leagueId = id
      roster = await svc.memberCount(id)
    } catch { toast.show(HumanError.text(error, prefix: "Could not open the wizard.")) }
  }

  /// `#nlGo` (17177–17206): create the row, then the wizard. Returns the toast.
  func create() async -> String? {
    let name = dials.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return WizardCopy.nameFirst }
    busy = true
    defer { busy = false }
    do {
      let c = try await svc.createLeague(name: name)
      leagueId = c.leagueId; code = c.code; storedName = c.name
      dials.name = name
      step = 0
      if runBack != nil { runBack = nil; return WizardCopy.runBackCarried }
      return WizardCopy.onTheBooks(name)
    } catch {
      runBack = nil
      return HumanError.text(error, prefix: WizardCopy.couldNotCreate)
    }
  }

  enum LockResult { case blocked, failed(String), locked }

  func lock() async -> LockResult {
    guard let id = leagueId else { return .failed(WizardCopy.lockFailed) }
    svc.track(.lock_attempt)
    let typed = dials.name.trimmingCharacters(in: .whitespacesAndNewlines)
    if typed.isEmpty && WizardCopy.isUnnamed(storedName) {
      svc.track(.lock_blocked, ["reason": .string("unnamed")])
      step = 0
      return .blocked
    }
    busy = true
    defer { busy = false }
    do {
      let r = try await svc.lock(leagueId: id, dials: dials, fallbackName: storedName)
      let name = typed.isEmpty ? storedName : typed
      storedName = name
      lockedLeague = id
      let n = await svc.memberCount(id)
      svc.track(.invite_open, ["sent": .number(0)])
      share = WizardLockShare(leagueId: id, name: name, code: code ?? "", nextPhase: r.nextPhase, members: n,
                              structure: dials.structure, draftType: dials.draftType, startsOn: r.startsOn)
      return .locked
    } catch { return .failed(HumanError.text(error, prefix: WizardCopy.lockFailed)) }
  }

  /// `wizCancel`: the row exists, so abandoning discards it (delete_league is setup/draft-only).
  func discard() async throws {
    busy = true
    defer { busy = false }
    if let id = leagueId { try await svc.deleteLeague(id) }
    leagueId = nil; code = nil; storedName = ""
    dials = WizardDials()
  }
}
