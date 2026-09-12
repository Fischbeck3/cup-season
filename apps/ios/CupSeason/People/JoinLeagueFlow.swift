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
          // QB-08 · an invited joiner arrives with the code ALREADY IN HAND and
          // was shown the manual-entry screen anyway: *"nobody sent me a code.
          // Wrong screen. Where's Cancel?"* When the code came from a link the
          // sheet says whose season it is; when it is being typed, the old
          // frame is still exactly right.
          CSSheetHeader(title: vm.presetCode == nil ? "Join with a code" : (vm.leagueName.map { "You're joining \($0)" } ?? "You're joining a season"),
                        sub: vm.presetCode == nil ? "WHOEVER'S RUNNING IT WILL HAVE SENT YOU ONE" : "THE LINK BROUGHT THE CODE WITH IT")   // T-13: one noun for the code (D47)
          if vm.presetCode == nil {
            CSField("League code", text: $vm.code)
              .textInputAutocapitalization(.characters).autocorrectionDisabled()
              .accessibilityLabel("League code")
          } else {
            Text(vm.code).font(CSFont.code).foregroundStyle(cs.ink)
          }
          if vm.presetCode == nil, let name = vm.leagueName { CSFine("You're invited to \(name).", tone: cs.ink) }
          Button("Join") { Task { await vm.go() } }
            .buttonStyle(.csPrimary(busy: vm.busy))
          if let note = vm.note { CSNote(note, tone: .neg) }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .csCloseButton { dismiss() }
      .task { if vm.presetCode != nil { await vm.go() } }
      .sheet(item: $vm.covenant) { c in
        // QB-08 · `postedRounds` was never passed, so `Covenant.starterClause`
        // — the one sentence in the covenant written for a beginner, with a
        // producer and a test — never rendered, and the beginner is exactly
        // the golfer it was written for. A nil count still renders nothing
        // (L-44); a real zero renders the clause.
        CovenantSheet(covenant: c, postedRounds: store.me?.profile?.rounds_count,
                      onJoin: { vm.covenant = nil; Task { await vm.join() } }, onNo: { vm.covenant = nil })
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
        note = "No season with that code. Check with whoever sent it."; return
      }
      leagueName = name
      // L-12 · the covenant, at EVERY stake including $0 (D225). It used to
      // fire only above $0, so a golfer joining a free season never met the
      // Pro, the length, the rules or the ending.
      covenant = try await joins.covenant(c)
    } catch { note = JoinService.joinError(error) }
  }

  func join() async {
    guard !busy else { return }
    let c = JoinIntent.normalize(code)
    busy = true; defer { busy = false }
    do {
      let id = try await joins.join(c)
      JoinIntent.clear(ifMatching: c)
      CSHaptic.success()
      toasts.show("Joined \(leagueName ?? "the season")")
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
  /// The joiner's own posted rounds, for the starter clause. nil = not read, so
  /// the clause is omitted rather than guessed (L-44).
  var postedRounds: Int? = nil
  let onJoin: () -> Void
  let onNo: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        CSSheetHeader(title: covenant.head, sub: "EVERYTHING BEFORE YOU TAP")
        // WHO comes before the money. The order is the producer's, not this
        // file's — `Covenant.facts` decides it, and a fact with no read is
        // simply not in the list (L-44).
        ForEach(covenant.facts(postedRounds: postedRounds), id: \.0) { fact, line in
          Text(line)
            .font(fact == .who ? CSFont.sentenceBold : CSFont.sentence)
            .foregroundStyle(fact == .stake ? cs.gold : cs.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(line)
        }
        Button(covenant.joinLabel) { onJoin() }
          .buttonStyle(.csPrimary()).padding(.top, 8)
        Button(Covenant.notNow) { onNo() }
          .buttonStyle(.csSecondary())
      }
      .padding(20)
    }
    .background(cs.bg0)
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
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
          (Text("You're on the pot: $\(welcome.usd) buy-in.").foregroundStyle(cs.gold).bold() + Text(" The Pro tracks who's paid."))
            .csType(.bodyS).foregroundStyle(cs.mut)
        }
        // D205 · "your squad" is a lie in a solo league; "your standing" is
        // true in BOTH — so only a KNOWN squad league gets the squad wording,
        // and an unknown structure never asserts a squad the golfer may not have.
        rule(welcome.solo == false ? "You can't hurt your squad by playing badly." : "You can't hurt your standing by playing badly.",
             " Only by not playing. Every posted round scores — a rough day is still points on the board.")
        rule("Rounds score against your playing HCP.", " Beat your handicap and it's a big day, whatever you shot. Your best rounds each month count; a better round always bumps your worst.")
        rule("The pot lives on the books.", " \(MoneyCopy.ledger) The settlement card shows who owes what.")
        Button("How scoring works") { scoring = true }.csType(.bodyS).foregroundStyle(cs.brand).padding(.bottom, 4)
        Rectangle().fill(cs.rule).frame(height: 1)
        rule("Who else plays with you?", " Any member's link works — yours included.")
        if let code = welcome.code {
          ShareLink(item: URL(string: "https://cupseason.app/?join=\(code)")!, subject: Text("Cup Season"),
                    message: Text("You're invited to \(welcome.name) on Cup Season")) {
            Text("Share the invite link").csType(.name).foregroundStyle(cs.ink)
              .frame(maxWidth: .infinity, minHeight: 50)
              .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
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
    (Text(b).bold().foregroundStyle(cs.ink) + Text(rest)).csType(.bodyS).foregroundStyle(cs.mut)
  }
}

#Preview("Covenant") {
  CovenantSheet(covenant: Covenant(name: "the Fellas", buyinCents: 5000, preset: "standard", floor: 2, finish: "cup_final",
                                   proName: "Galen Fischbeck", rosterCount: 8,
                                   rosterNames: ["Marcus Webb", "Dev Patel", "Tash Boyle", "Ravi Shah", "Jules Kerr"],
                                   startsOn: "2026-09-12", weeks: 13, countingCap: 3,
                                   split: .init(champion: 60, runnerUp: 25, pointsKing: 15),
                                   hasPayNote: true, phase: "setup"),
                postedRounds: 0, onJoin: {}, onNo: {}).csTheme()
}

#Preview("Welcome") {
  LeagueWelcomeSheet(welcome: LeagueWelcome(name: "PIGL", code: "PIGL2026", buyinCents: 5000)).csTheme()
}
