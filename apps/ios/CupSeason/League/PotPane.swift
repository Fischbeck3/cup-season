// Cup Season — THE POT (Wave 5, `surfaces/season.md` §1.6).
//
// The money surface of a product about money between friends had no ledger
// character: a gold-spined card, a serif payout trio in gold, a tick list whose
// paid state was a `✓` at 50% opacity, a handshake emoji in a stroked circle
// and an `✕` used as a button label. All of that is §2.7 of the audit's "what
// feels cheap", and all of it is gone.
//
// WHAT IS HERE INSTEAD: the pot as a rule-and-figure in gold (the surface's
// second and last gold object), the split as three figures in INK on one 2pt
// ink rule, and the buy-ins as a **printed leaf** — a grid with faces, the sign
// as a WORD, the amount right-flush, and a collected total. **No colour
// anywhere on the leaf**: no `pos`, no `neg`, and no gold, because gold ink on
// bone is 1.68:1.
//
// D273 · MONEY IS `ink`; the pot and anything won are `gold`; the sign is a
// word in agate; `pos` and `neg` never touch money. **The ledger line renders
// verbatim from `MoneyCopy.ledger`, ONCE per client, at the foot of this
// surface, under a hairline** (§16A.1 — it appeared on eight of thirty-four
// renders, twice on one screen 250pt apart).
//
// CONSUMED UNCHANGED: `PotMath.trioCents` (the settlement's own split, to the
// cent), `SeasonFacts.owe` (the Pro's payment words — built, tested, and called
// from nowhere in the shipped UI until now), `PotPassCard` and
// `PricingPotFinePrint`, which move below the ledger.

import SwiftUI
import UIKit
import CSDesign
import CupSeasonKit

struct PotPane: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var busy: UUID?
  /// D56 / IOS-021: the Pro's season-pass card + the fine print; hidden until the flag says otherwise
  @State private var pricing = PricingFlags.hidden

  var body: some View {
    let b = model.bylaws
    // M1 · the pane shows what the settlement will pay, to the cent.
    let trio = PotMath.trioCents(potCents: model.potTotal * 100, payout: b.payout)
    let mine = store.me?.memberships.first { $0.league_id == model.leagueId }
    VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
      // **The pot names itself ONCE**: the head carries the count, the figure
      // carries the rule and its own caption (§16A.2).
      CSSectionHead("The pot", count: SeasonBoardCopy.potIn(model.potPlayers))
        .csGutter()
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        CSFigure(PotMath.dollars(model.potTotal), size: .l, metal: .earned,
                 label: SeasonBoardCopy.potCaption(stake: b.stake, trio: trio))
          .contentTransition(.numericText())   // the web's odometer (csOdo, 7000)
          .csAnimation(CSMotion.roll, value: model.potTotal)
        // the split: three figures in INK on one shared 2pt ink heavy rule.
        // The shipped gold serif trio is re-inked — gold is the pot, once.
        split(trio)
      }
      .csGutter()

      CSSectionHead("Who is in", count: SeasonBoardCopy.paid(model.paidCount, of: model.potPlayers))
        .csGutter()
      ledger
        .csGutter()

      // QB-04 · **THE PRO'S PAYMENT WORDS.** A member who owes arrived here
      // from the red figure on Home and found the purse, the split and a tick
      // list — and no answer to the one question he came with.
      if let m = mine, let owe = SeasonFacts.owe(m) {
        Text(owe).csType(.body).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
          .csGutter()
          .accessibilityLabel(owe)
      }

      // §16A.1 · THE LEDGER LINE, ONCE, AT THE FOOT OF THE MONEY SURFACE,
      // UNDER A HAIRLINE, VERBATIM FROM ONE CONSTANT. A retyped copy is a
      // defect the day it is written.
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        CSRule()
        Text(MoneyCopy.ledger).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      .csGutter()

      if let m = mine {
        PotPassCard(flags: pricing, league: m, isPro: model.isPro, yearStartsOn: model.season?.starts_on, roster: model.potPlayers)
          .csGutter()
      }
      PricingPotFinePrint(flags: pricing)
        .csGutter()
        .task { pricing = await PricingFlags.load() }
      ForfeitLedgerView()
        .csGutter()
    }
  }

  /// `$288 · $120 · $72` on ONE 2pt ink rule, three agate labels beneath.
  ///
  /// §3.1 · **at the accessibility sizes it becomes a stacked list, label
  /// leading and figure trailing** — the same reflow the story page's
  /// three-figures rule takes. Three bare dollar amounts down the left margin
  /// with their labels dropped is a split nobody can read: the reader cannot
  /// tell the champion's share from the points king's.
  @ViewBuilder private func split(_ trio: (champ: Int, runner: Int, king: Int)) -> some View {
    let rows = [("Cup champ", PotMath.money(trio.champ)),
                ("Runner-up", PotMath.money(trio.runner)),
                ("Points king", PotMath.money(trio.king))]
    Group {
      if typeSize.isA11y {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(rows, id: \.0) { r in
            HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
              Text(r.0).csType(.agateS, caps: true).foregroundStyle(cs.mut)
                .fixedSize(horizontal: false, vertical: true)
              Spacer(minLength: CSTokens.Space.s2)
              Text(r.1).csType(.figureM).csTabular().foregroundStyle(cs.ink)
            }
            .padding(.vertical, CSTokens.Space.s2)
            .overlay(alignment: .bottom) { CSRule() }
          }
        }
      } else {
        VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
          HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
            ForEach(rows, id: \.0) { r in
              Text(r.1).csType(.figureM).csTabular().foregroundStyle(cs.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          CSRule(.heavy)
          HStack(spacing: CSTokens.Space.s3) {
            ForEach(rows, id: \.0) { r in
              Text(r.0).csType(.agateS, caps: true).foregroundStyle(cs.mut)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("The split. Cup champ \(PotMath.money(trio.champ)), runner-up \(PotMath.money(trio.runner)), points king \(PotMath.money(trio.king)).")
  }

  // MARK: - the leaf

  /// **A printed ledger**: column heads in `leafMut`, a hairline, one 29pt row
  /// per member — a 24pt face, the name in `social` (title case; a person in a
  /// row is not the board), the sign as a WORD, the amount right-flush — a
  /// closing hairline and a `COLLECTED` total.
  ///
  /// D-4 · the leaf's licence names "a receipt". A pot ledger is a receipt of
  /// who has paid, it is a grid, and it passes the leaf's own test.
  private var ledger: some View {
    CSLeaf {
      VStack(spacing: 0) {
        if !typeSize.isA11y {
          HStack(spacing: CSTokens.Space.s3) {
            Text("Golfer").frame(maxWidth: .infinity, alignment: .leading)
            Text("In").frame(width: 80, alignment: .leading)
            Text("Amount").frame(width: 64, alignment: .trailing)
          }
          .csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
          .padding(.bottom, CSTokens.Space.s2)
          .accessibilityHidden(true)
          CSRule(over: .leaf)
        }
        ForEach(model.members) { m in payer(m) }
        if model.members.isEmpty { payerRow(m: nil, name: model.viewer?.displayName ?? "You", paid: false, mine: true, busy: false) {} }
        CSRule(over: .leaf)
        HStack(spacing: CSTokens.Space.s3) {
          Text("Collected").csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
            .frame(maxWidth: .infinity, alignment: .leading)
          Text(collected).csType(.columnM).csTabular().foregroundStyle(cs.leafInk)
            .frame(width: 64, alignment: .trailing)
        }
        .padding(.top, CSTokens.Space.s3)
        .accessibilityElement(children: .combine)
      }
    }
  }

  private var collected: String {
    let c = model.collectedDollars
    return c == c.rounded() ? "$\(Int(c))" : String(format: "$%.2f", c)
  }

  /// `.payer` — the Pro taps a name as money moves; anyone else hears why not.
  private func payer(_ m: LeagueRoom.Member) -> some View {
    let paid = model.buyIns[m.id]?.paid ?? false
    let mine = m.profile_id == (model.viewer?.id ?? store.me?.profile?.id)
    return payerRow(m: m, name: m.name, paid: paid, mine: mine, busy: busy == m.id) {
      if !model.isPro {
        // QB-04 · a tap on your OWN unpaid row hands you the Pro's words and
        // puts them on the clipboard, which is the act a golfer performs next.
        if mine,
           let mem = store.me?.memberships.first(where: { $0.league_id == model.leagueId }),
           let owe = SeasonFacts.owe(mem) {
          if let note = mem.buy_in?.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            UIPasteboard.general.string = note
            CSHaptic.selection()
            toast.show("\(owe) \u{00B7} copied", kind: .confirmed)
          } else {
            toast.show(owe)
          }
          return
        }
        toast.show("Only the Pro marks buy-ins."); return
      }
      if model.season == nil { toast.show("Buy-ins open once the season starts"); return }
      busy = m.id
      Task {
        defer { busy = nil }
        do { try await model.markBuyIn(member: m.id, paid: !paid); CSHaptic.selection() } catch { toast.show(roomError(error, "Mark failed."), kind: .failed) }
      }
    }
  }

  private func payerRow(m: LeagueRoom.Member?, name: String, paid: Bool, mine: Bool,
                        busy: Bool, action: @escaping () -> Void) -> some View {
    let amount = m.flatMap { model.buyIns[$0.id]?.amount_cents }
      .map { PotMath.money($0) } ?? PotMath.dollars(model.bylaws.stake)
    return Button(action: action) {
      A11yStack(rowAlignment: .center, spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s1) {
        HStack(spacing: CSTokens.Space.s2) {
          if let m {
            CSFace(.init(id: m.profile_id, marker: m.mk, photoURL: model.avatarURL[m.profile_id],
                         isViewer: mine), size: .inline)
          }
          Text(mine ? "You" : name).csType(.nameS, caps: false).foregroundStyle(cs.leafInk)
            .lineLimit(1).truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // **THE SIGN IS A WORD** — never a tick, never opacity, never a hue.
        Text(SeasonBoardCopy.sign(paid: paid, mine: mine))
          .csType(.agateS, caps: true)
          .foregroundStyle(paid ? cs.leafMut : cs.leafInk)
          .frame(width: typeSize.isA11y ? nil : 80, alignment: .leading)
        Text(amount).csType(.columnM).csTabular().foregroundStyle(cs.leafInk)
          .frame(width: typeSize.isA11y ? nil : 64, alignment: .trailing)
      }
      .frame(minHeight: 29)
      .padding(.vertical, CSTokens.Space.s1)
      .contentShape(Rectangle())
      .opacity(busy ? 0.5 : 1)
    }
    .buttonStyle(.plain)
    .disabled(busy)
    .accessibilityLabel("\(mine ? "You" : name), \(SeasonBoardCopy.sign(paid: paid, mine: mine)), \(amount)")
    .accessibilityHint(model.isPro ? "Marks the buy-in \(paid ? "not in" : "in")" : "The Pro marks buy-ins")
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
        CSSectionHead("Bets for pride · on the record", trailing: "Post a forfeit") { router.open(.forfeitCreate) }
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
                Task { defer { scrapping = nil }; do { try await model.scrapForfeit(s.id); toast.show("Scrapped", kind: .confirmed) } catch { toast.show(roomError(error), kind: .failed) } }
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

/// `openStakeCreate` (10990–11035): "Post a forfeit · Pride, on the books — never money".
struct ForfeitCreateSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
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
    // LV-02 · ONE forfeit composer, one set of words. This sheet and
    // `ForfeitSheet` (the season-less one) are two views over one object, and
    // they said opposite things: "on the books" here against T-02's ruling
    // that a forfeit goes on the record and never on the books (L-34).
    SheetFrame("Post a forfeit", sub: ForfeitCopy.definition) {
      label(ForfeitCopy.nameLabel)
      CSField(ForfeitCopy.namePlaceholder, text: $name, font: CSFont.body)
      label("The shape")
      FlowSeg(options: Self.kinds, selection: $kind)
        .onChange(of: kind) { _, k in if termsAuto || terms.isEmpty { terms = Self.terms[k] ?? ""; termsAuto = true } }
      label(ForfeitCopy.termsLabel)
      CSField(ForfeitCopy.termsLabel, text: $terms, font: CSFont.body).onChange(of: terms) { old, new in if new != (Self.terms[kind] ?? "") { termsAuto = false } }
      label("Against")
      Picker("Against", selection: $other) {
        Text("\(ForfeitCopy.theField) — first to hit it").tag(UUID?.none)
        ForEach(others) { m in Text(m.name).tag(UUID?.some(m.profile_id)) }
      }
      .pickerStyle(.menu).tint(cs.ink)
      .accessibilityLabel("Against")
      .padding(.horizontal, 14).frame(minHeight: 48).frame(maxWidth: .infinity, alignment: .leading)
      .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      label("Rides on (optional)")
      CSField(ForfeitCopy.settlesPlaceholder, text: $hangs, font: CSFont.body)
      A11yStack(spacing: 8) {
        Button("Close") { dismiss() }
          .buttonStyle(.csSecondary()).frame(maxWidth: typeSize.isA11y ? .infinity : 110)
        Button(ForfeitCopy.put) {
          busy = true
          Task {
            defer { busy = false }
            do {
              try await model.createForfeit(name: name.trimmingCharacters(in: .whitespaces), terms: terms.trimmingCharacters(in: .whitespaces),
                                            kind: kind, other: other, hangs: hangs.trimmingCharacters(in: .whitespaces).isEmpty ? nil : hangs.trimmingCharacters(in: .whitespaces))
              toast.show("Stake posted — the board heard it", kind: .confirmed); dismiss()
            } catch { toast.show(roomError(error, "Could not post the stake."), kind: .failed) }
          }
        }
          .buttonStyle(.csPrimary(busy: busy))
      }
      .padding(.top, 6)
      RoomFine(ForfeitCopy.noPush)
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
          Text(l).csType(.columnS).foregroundStyle(selection == k ? cs.bg0 : cs.ink)
            .padding(.horizontal, 12).frame(minHeight: 36).frame(maxWidth: .infinity)
            .background(selection == k ? cs.ink : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
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
              do { try await model.settleForfeit(forfeit.id, winner: pid, note: note.isEmpty ? nil : note); toast.show("Settled — into the archive", kind: .confirmed); dismiss() }
              catch { toast.show(roomError(error), kind: .failed) }
            }
          }
        }
      }
      Text("A line for the archive (optional)").csEyebrow().padding(.top, 8)
      CSField("Settled on the 18th at Papago", text: $note, font: CSFont.body)
    }
  }
}
