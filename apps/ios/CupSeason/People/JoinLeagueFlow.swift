// Cup Season — join by code, signed in (index.html 15197–15220 `#joinGo`;
// `covenantGate` 15176; `openLeagueWelcome` ~19433; `openScoringHelp` ~19409).
//
// validate (`league_by_code`) → the covenant when there is a stake
// (`join_covenant_info`, FAILS CLOSED here) → `join_league` → the welcome.
// The welcome's "How scoring works" is `ScoringHelpSheet` — `GuideCopy` is
// the one producer of that text (Y-25); nothing here retypes the bands.

import SwiftUI
import CSDesign
import CupSeasonKit

struct JoinLeagueFlow: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @State private var vm: JoinModel
  @State private var toasts: CSToastCenter
  let onJoined: (UUID) -> Void

  /// `code` nil = show the code field; a code = go straight to the gate.
  init(code: String? = nil, onJoined: @escaping (UUID) -> Void) {
    self.onJoined = onJoined
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: JoinModel(code: code, toasts: t))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          CSSheetHeader(title: "Join a league", sub: "I HAVE A LEAGUE CODE")   // Q-16: one noun for the code (D47)
          if vm.presetCode == nil {
            CSField("League code", text: $vm.code)
              .textInputAutocapitalization(.characters).autocorrectionDisabled()
              .accessibilityLabel("League code")
          } else {
            Text(vm.code).font(CSFont.code).foregroundStyle(cs.ink)
          }
          if let name = vm.leagueName { CSFine("You're invited to \(name).", tone: cs.ink) }
          CSButton("Join", busy: vm.busy) { Task { await vm.go() } }
          if let note = vm.note { CSNote(note, tone: .neg) }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() }.foregroundStyle(cs.mut) } }
      .task { if vm.presetCode != nil { await vm.go() } }
      .sheet(item: $vm.covenant) { c in
        CovenantSheet(covenant: c, onJoin: { vm.covenant = nil; Task { await vm.join() } }, onNo: { vm.covenant = nil })
      }
      .sheet(item: $vm.welcome, onDismiss: { if let id = vm.joinedId { PushAsk.shared.request(.leagueJoined); onJoined(id); dismiss() } }) { w in
        LeagueWelcomeSheet(welcome: w)
      }
      .task(id: vm.joinedId) {
        guard vm.joinedId != nil else { return }
        await store.reload()
        vm.welcome(from: store.me)
      }
      .csToasts(toasts)
    }
    .presentationDragIndicator(.visible)
  }
}

@MainActor
@Observable
final class JoinModel {
  let presetCode: String?
  var code: String
  var leagueName: String? = nil
  var busy = false
  var note: String? = nil
  var covenant: Covenant? = nil
  var joinedId: UUID? = nil
  var welcome: LeagueWelcome? = nil
  private let toasts: CSToastCenter
  private let joins = JoinService()

  init(code: String?, toasts: CSToastCenter) {
    self.presetCode = code.map(JoinIntent.normalize)
    self.code = self.presetCode ?? ""
    self.toasts = toasts
  }

  /// `#joinGo`, signed in: validate first, then the gate.
  func go() async {
    let c = JoinIntent.normalize(code)
    guard !c.isEmpty else { toasts.show("Enter the league code"); return }
    guard !busy else { return }
    busy = true; defer { busy = false }
    note = nil
    do {
      guard let name = try await joins.leagueName(c) else {
        note = "No league with that code — check with your Pro"; return
      }
      leagueName = name
      if let cov = try await joins.covenant(c) { covenant = cov; return }   // the stake, named BEFORE join_league
      await join()
    } catch { note = JoinService.joinError(error) }
  }

  func join() async {
    let c = JoinIntent.normalize(code)
    busy = true; defer { busy = false }
    do {
      let id = try await joins.join(c)
      JoinIntent.clear()
      CSHaptic.success()
      toasts.show("Joined \(leagueName ?? "the league")")
      joinedId = id
    } catch { note = JoinService.joinError(error) }
  }

  func welcome(from me: Me?) {
    let m = me?.memberships.first { $0.league_id == joinedId }
    welcome = LeagueWelcome(name: m?.name ?? leagueName ?? "the league", code: m?.code, buyinCents: m?.settings?.buyin_cents ?? 0,
                            solo: m?.settings?.structure.map { $0 == "solo" })
  }
}

// MARK: - The covenant (setup-QA S3-01)

struct CovenantSheet: View {
  @Environment(\.cs) private var cs
  let covenant: Covenant
  let onJoin: () -> Void
  let onNo: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        CSSheetHeader(title: "Before you join \(covenant.name)", sub: "THE FINE PRINT, UP FRONT")
        byrow("BUY-IN", covenant.buyinLine)
        if let p = covenant.presetLine { byrow("PRESET", p) }
        if let f = covenant.floorLine { byrow("PARTICIPATION FLOOR", f) }
        byrow("FINISH", covenant.finishLine)
        CSFine(covenant.potLine).padding(.top, 10)
        CSButton(covenant.joinLabel, action: onJoin).padding(.top, 10)
        CSButton("Not now", style: .quiet, action: onNo)
      }
      .padding(20)
    }
    .background(cs.bg0)
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  private func byrow(_ k: String, _ v: String) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(k).csEyebrow()
      Spacer()
      Text(v).font(CSFont.monoMediumBody).foregroundStyle(cs.ink).multilineTextAlignment(.trailing)
    }
    .padding(.vertical, 8)
    .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
  }
}

// MARK: - The welcome (decision D3: the three rules that kill the fear at the door)

struct LeagueWelcome: Identifiable, Equatable {
  let name: String
  let code: String?
  let buyinCents: Int
  /// D205 · true = a solo league (no squad to hurt, no floor to dock); nil = not known yet.
  var solo: Bool? = nil
  var id: String { name }
  var usd: Int { Int((Double(buyinCents) / 100).rounded()) }
}

struct LeagueWelcomeSheet: View {
  @Environment(\.cs) private var cs
  let welcome: LeagueWelcome
  @State private var scoring = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        CSSheetHeader(title: "Welcome to \(welcome.name)", sub: "THREE THINGS TO KNOW")
        if welcome.usd > 0 {
          // setup-QA S3-01: the auto-join path reaches this covenant without ever seeing the stake — name the number here.
          // One fact, one place (brand canon §3): the stake line names the number and who tracks it;
          // the ledger sentence belongs to "The pot lives on the books" below and is said once on this sheet.
          (Text("You're on the pot sheet: $\(welcome.usd) buy-in.").foregroundStyle(cs.gold).bold() + Text(" The Pro tracks who's paid."))
            .font(CSFont.footnote).foregroundStyle(cs.dimText)
        }
        // D205 · "your squad" is a lie in a solo league; "your standing" is
        // true in BOTH — so only a KNOWN squad league gets the squad wording,
        // and an unknown structure never asserts a squad the golfer may not have.
        rule(welcome.solo == false ? "You can't hurt your squad by playing badly." : "You can't hurt your standing by playing badly.",
             " Only by not playing. Every posted round scores — a rough day is still points on the board.")
        rule("Rounds score against your own number.", " Beat your handicap and it's a big day, whatever you shot. Your best rounds each month count; a better round always bumps your worst.")
        rule("The pot lives on the books.", " \(MoneyCopy.ledger) The settlement card shows who owes what.")
        Button("How scoring works →") { scoring = true }.font(CSFont.footnote).foregroundStyle(cs.brand).padding(.bottom, 4)
        Rectangle().fill(cs.line).frame(height: 1)
        rule("Who else plays with you?", " Growing the league isn't the Pro's chore — any member's link works.")
        if let code = welcome.code {
          ShareLink(item: URL(string: "https://cupseason.app/?join=\(code)")!, subject: Text("Cup Season"),
                    message: Text("You're invited to \(welcome.name) on Cup Season")) {
            Text("Share the invite link").font(CSFont.button).foregroundStyle(cs.ink)
              .frame(maxWidth: .infinity, minHeight: 50)
              .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
              .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
          }
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .sheet(isPresented: $scoring) { ScoringHelpSheet(solo: welcome.solo).presentationDetents([.large]) }
  }

  private func rule(_ b: String, _ rest: String) -> some View {
    (Text(b).bold().foregroundStyle(cs.ink) + Text(rest)).font(CSFont.footnote).foregroundStyle(cs.dimText)
  }
}

#Preview("Covenant") {
  CovenantSheet(covenant: Covenant(name: "PIGL", buyinCents: 5000, preset: "standard", floor: 2, finish: "cup_final"), onJoin: {}, onNo: {}).csTheme()
}

#Preview("Welcome") {
  LeagueWelcomeSheet(welcome: LeagueWelcome(name: "PIGL", code: "PIGL2026", buyinCents: 5000)).csTheme()
}
