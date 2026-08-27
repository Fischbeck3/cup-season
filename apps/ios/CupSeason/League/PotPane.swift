// Cup Season — the Pot pane (`#room-pot` 3497–3525, `renderPot` 6973–7050):
// the purse, the payout trio, the fine print, the buy-ins the Pro ticks as
// money moves (D39 — a ledger, never a wallet), and the D64 forfeit ledger:
// pride, on the books — never dollars.

import SwiftUI
import CSDesign
import CupSeasonKit

struct PotPane: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @State private var busy: UUID?

  var body: some View {
    let b = model.bylaws
    let free = b.stake == 0
    let trio = PotMath.trioDollars(total: model.potTotal, payout: b.payout)
    VStack(alignment: .leading, spacing: 14) {
      CSSectionHead("Season stakes")
      // the purse: gold is the pot's own metal (earned); a free league wears no spine
      CSCard(spine: free ? nil : cs.gold, padding: 18) {
        VStack(alignment: .leading, spacing: 6) {
          Text("The pot").csEyebrow(free ? nil : cs.gold)
          Text(free ? "None" : PotMath.dollars(model.potTotal)).font(CSFont.hero).csTabular().foregroundStyle(free ? cs.ink : cs.gold)
          Text(free ? "Bragging rights · no money in play"
               : "\(model.potPlayers) × \(PotMath.dollars(b.stake)) buy-in · \(collected) collected")
            .font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText)
        }
      }
      // the payout trio as one band on ground — hairline above and below
      VStack(spacing: 0) {
        CSHairline()
        HStack(alignment: .top, spacing: 10) {
          trioTile(free ? "—" : PotMath.dollars(trio.champ), "Cup champs")
          trioTile(free ? "—" : PotMath.dollars(trio.runner), "Runner-up")
          trioTile(free ? "—" : PotMath.dollars(trio.king), "Points king")
        }
        .padding(.vertical, 10)
        CSHairline()
      }
      Text((try? AttributedString(markdown: "**Cup Season keeps the books.** Buy-ins and payouts move friend-to-friend. We just make sure nobody argues at the bar.")) ?? "")
        .font(CSFont.footnote).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true)

      CSSectionHead("Buy-ins · \(free ? "Bragging rights" : "\(model.paidCount)/\(model.potPlayers)") in")
      if free {
        RoomFine("No buy-ins — this league plays for bragging rights.")
      } else {
        VStack(spacing: 0) {
          ForEach(model.members) { m in payer(m) }
          if model.members.isEmpty { payerRow(name: model.viewer?.displayName ?? "You", paid: false, busy: false) {} }
        }
      }
      ForfeitLedgerView()
    }
  }

  private var collected: String {
    let c = model.collectedDollars
    return c == c.rounded() ? "$\(Int(c))" : String(format: "$%.2f", c)
  }

  private func trioTile(_ b: String, _ sub: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(b).font(CSFont.sentenceBold).csTabular().foregroundStyle(b == "—" ? cs.ink : cs.gold)
      Text(sub).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// `.payer` — the Pro taps a name as money moves; anyone else hears why not.
  private func payer(_ m: LeagueRoom.Member) -> some View {
    let paid = model.buyIns[m.id]?.paid ?? false
    return payerRow(name: m.name, paid: paid, busy: busy == m.id) {
      if !model.isPro { toast.show("The Pro marks buy-ins as money moves between you"); return }
      if model.season == nil { toast.show("Buy-ins open once the bylaws lock"); return }
      busy = m.id
      Task {
        defer { busy = nil }
        do { try await model.markBuyIn(member: m.id, paid: !paid); CSHaptic.selection() } catch { toast.show(roomError(error, "Mark failed.")) }
      }
    }
  }

  private func payerRow(name: String, paid: Bool, busy: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Text(name).font(CSFont.subhead).foregroundStyle(cs.ink)
        Spacer()
        if busy { ProgressView().tint(cs.mut) } else {
          Text("✓").font(CSFont.monoMediumBody).foregroundStyle(paid ? cs.pos : cs.dim).opacity(paid ? 1 : 0.5)
        }
      }
      .padding(.horizontal, 4).frame(minHeight: 48)
      .contentShape(Rectangle())
      // a row, not a card: the hairline warms to `pos` once the money is in
      .overlay(alignment: .bottom) { Rectangle().fill(paid ? cs.pos.opacity(0.45) : cs.line).frame(height: 1) }
    }
    .buttonStyle(.plain)
    .disabled(busy)
    .accessibilityLabel("\(name), \(paid ? "buy-in in" : "buy-in not in")")
  }
}

/// D64 — the forfeit ledger (`renderStakes` 10939–10975). Hides entirely on skew.
struct ForfeitLedgerView: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @State private var scrapping: UUID?

  var body: some View {
    if let S = model.forfeits {
      let open = S.filter { $0.status == "open" }, done = S.filter { $0.status == "settled" }
      VStack(alignment: .leading, spacing: 8) {
        CSSectionHead("The other stakes · pride, on the books", trailing: "Post a stake") { router.open(.forfeitCreate) }
        if open.isEmpty { RoomFine("No stakes on the books. The cookout isn't going to bet itself.") }
        ForEach(open) { row($0) }
        if !done.isEmpty {
          CSSectionHead("The archive")
          ForEach(done.prefix(8)) { row($0) }
        }
      }
    }
  }

  private func row(_ s: LeagueRoom.Forfeit) -> some View {
    let meP = model.viewer?.id
    let vs = s.party_b.map { "\(model.stakeName(s.party_a)) vs \(model.stakeName($0))" } ?? "\(model.stakeName(s.party_a)) vs the field"
    let mine = meP != nil && (s.party_a == meP || s.party_b == meP || s.created_by == meP)
    return RoomCheckRow(s.name, sub: "\(vs) · \(s.terms)" + (s.hangs_on.map { " · rides on \($0)" } ?? "")) {
      Text("🤝").font(.system(size: 16))
    } trail: {
      if s.status == "open" {
        if mine {
          HStack(spacing: 6) {
            RoomMini("Settle") { router.open(.forfeitSettle(s)) }
            if s.created_by == meP {
              ArmedMini("✕", armedLabel: "Sure? Scrap", busy: scrapping == s.id) {
                scrapping = s.id
                Task { defer { scrapping = nil }; do { try await model.scrapForfeit(s.id); toast.show("Scrapped") } catch { toast.show(roomError(error)) } }
              }
            }
          }
        } else { Text("OPEN").csEyebrow() }
      } else {
        Text("\(model.stakeName(s.winner).uppercased()) TOOK IT").csEyebrow(cs.pos).multilineTextAlignment(.trailing)
      }
    }
  }
}

/// `openStakeCreate` (10990–11035): "Post a stake · Pride, on the books — never money".
struct ForfeitCreateSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  static let kinds: [(String, String)] = [("hosts", "Loser hosts"), ("course_pick", "Winner picks the course"), ("strokes", "Strokes next time"), ("bounty", "Standing bounty"), ("custom", "Name your own")]
  static let terms = ["hosts": "Loser hosts the cookout", "course_pick": "Winner picks the next course", "strokes": "Loser gives 2 a side next time", "bounty": "First ace: steak dinner from everyone", "custom": ""]
  @State private var name = ""
  @State private var kind = "hosts"
  @State private var terms = "Loser hosts the cookout"
  @State private var termsAuto = true
  @State private var other: UUID? = nil
  @State private var hangs = ""
  @State private var busy = false

  var body: some View {
    let others = model.members.filter { $0.profile_id != model.viewer?.id }
    SheetFrame("Post a stake", sub: "Pride, on the books — never money") {
      label("Name it")
      CSField("The Lawn Bet", text: $name, font: CSFont.body)
      label("The shape")
      FlowSeg(options: Self.kinds, selection: $kind)
        .onChange(of: kind) { _, k in if termsAuto || terms.isEmpty { terms = Self.terms[k] ?? ""; termsAuto = true } }
      label("The terms")
      CSField("The terms", text: $terms, font: CSFont.body).onChange(of: terms) { old, new in if new != (Self.terms[kind] ?? "") { termsAuto = false } }
      label("Against")
      Picker("Against", selection: $other) {
        Text("The field — first to hit it").tag(UUID?.none)
        ForEach(others) { m in Text(m.name).tag(UUID?.some(m.profile_id)) }
      }
      .pickerStyle(.menu).tint(cs.ink)
      .padding(.horizontal, 14).frame(minHeight: 48).frame(maxWidth: .infinity, alignment: .leading)
      .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      label("Rides on (optional)")
      CSField("Sunday's duel · first ace · the Cup Final", text: $hangs, font: CSFont.body)
      HStack(spacing: 8) {
        CSButton("Cancel", style: .quiet) { dismiss() }.frame(width: 110)
        CSButton("Put it on the books", busy: busy) {
          busy = true
          Task {
            defer { busy = false }
            do {
              try await model.createForfeit(name: name.trimmingCharacters(in: .whitespaces), terms: terms.trimmingCharacters(in: .whitespaces),
                                            kind: kind, other: other, hangs: hangs.trimmingCharacters(in: .whitespaces).isEmpty ? nil : hangs.trimmingCharacters(in: .whitespaces))
              toast.show("Stake posted — the board heard it"); dismiss()
            } catch { toast.show(roomError(error, "Could not post the stake.")) }
          }
        }
      }
      .padding(.top, 6)
      RoomFine("Stakes settle on a party's tap and archive into the record. The pot stays money; this never is.")
    }
  }
  private func label(_ s: String) -> some View { Text(s).csEyebrow().padding(.top, 4) }
}

/// A wrapping segment of pills.
struct FlowSeg: View {
  @Environment(\.cs) private var cs
  let options: [(String, String)]
  @Binding var selection: String
  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 6)], alignment: .leading, spacing: 6) {
      ForEach(options, id: \.0) { k, l in
        Button { selection = k; CSHaptic.selection() } label: {
          Text(l).font(CSFont.monoSmall).foregroundStyle(selection == k ? cs.bg0 : cs.ink)
            .padding(.horizontal, 12).frame(minHeight: 36).frame(maxWidth: .infinity)
            .background(selection == k ? cs.ink : cs.bg2, in: Capsule())
            .overlay(Capsule().stroke(cs.line2, lineWidth: selection == k ? 0 : 1))
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
      }
    }
  }
}

/// `openStakeSettle` (10977–10989).
struct ForfeitSettleSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  let forfeit: LeagueRoom.Forfeit
  @State private var note = ""
  @State private var busy: UUID?

  var body: some View {
    let opts: [(UUID, String)] = forfeit.party_b.map { [(forfeit.party_a, model.stakeName(forfeit.party_a)), ($0, model.stakeName($0))] }
      ?? model.members.map { ($0.profile_id, $0.name) }
    SheetFrame("Settle the stake", sub: "\(forfeit.name) · \(forfeit.terms)") {
      RoomFine(forfeit.party_b != nil ? "Who took it?" : "Who hit it? Anyone in the crew.")
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 6)], alignment: .leading, spacing: 6) {
        ForEach(opts, id: \.0) { pid, name in
          RoomMini(name, busy: busy == pid) {
            busy = pid
            Task {
              defer { busy = nil }
              do { try await model.settleForfeit(forfeit.id, winner: pid, note: note.isEmpty ? nil : note); toast.show("Settled — into the archive"); dismiss() }
              catch { toast.show(roomError(error)) }
            }
          }
        }
      }
      Text("A line for the archive (optional)").csEyebrow().padding(.top, 8)
      CSField("Settled on the 18th at Papago", text: $note, font: CSFont.body)
    }
  }
}
