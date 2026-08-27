// Cup Season — the finish and the recap (index.html `finishRealLiveRound`
// 9109–9177, `showLiveRecap` 9178–9308, the D78 strip 8045–8071, the
// settlement card 5727–5838, D57 share links 5857–5935).

import SwiftUI
import UIKit
import CSDesign
import CupSeasonKit

// MARK: - Finish the round (9127–9139)

struct LiveFinishSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Bindable var store: LiveRoundStore

  var body: some View {
    let f = LiveCopy.finishSheet(store.state)
    SheetFrame("Finish the round", sub: "ONE FINISH — EVERY MEMBER’S CARD POSTS") {
      CSFine(f.intro)
      if let w = f.warning { Text(w).font(CSFont.footnote).foregroundStyle(cs.neg).fixedSize(horizontal: false, vertical: true) }
      CSButton(f.primary, busy: store.busy) { Task { if await store.finish(casual: false) { dismiss() } } }
      CSButton(f.secondary, style: .quiet, busy: store.busy) { Task { if await store.finish(casual: true) { dismiss() } } }
    }
    .presentationDetents([.medium, .large])
  }
}

// MARK: - The recap (9178–9308) — the ceremony ground, for every viewer

struct LiveRecapSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  let data: LiveRecapData
  @Bindable var store: LiveRoundStore
  @State private var share: LiveShareItems?
  @State private var busy = false

  private let ink = CSTokens.dark.ink
  private let mut = CSTokens.dark.mut

  var body: some View {
    let d = data.outcome
    let title = d.casual ? "Casual — nothing posted" : "Round posted"
    let sub = "\(d.posted.count) CARD\(d.posted.count == 1 ? "" : "S") TO THE SEASON"
    let empty = data.result == nil && d.posted.isEmpty && d.skipped.isEmpty && d.guests.isEmpty
    SheetFrame(title, sub: sub, dusk: true) {
      if empty { Text("Nothing to post.").font(CSFont.footnote).foregroundStyle(mut) }
      if let r = data.result {
        let row = r.recapRow
        checkRow(row.icon, row.line, row.money)
        if let H = r.holes, !H.cells.isEmpty {
          LiveHoleStrip(ledger: H, hot: H.hot?.key)
          if let legend = H.legend {
            HStack(spacing: 6) {
              RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xFF5A2E)).frame(width: 9, height: 9)
              Text(legend.uppercased()).font(CSFont.label).tracking(1.2).foregroundStyle(mut)
            }
          }
          let hl = H.highlights
          if !hl.isEmpty {
            LiveFlow(spacing: 6) {
              ForEach(hl, id: \.self) { t in
                Text(t).font(CSFont.label).tracking(1).foregroundStyle(Color(hex: 0xE9BE62))
                  .padding(.horizontal, 9).padding(.vertical, 3)
                  .overlay(Capsule().stroke(Color(hex: 0xE9BE62, opacity: 0.35), lineWidth: 1))
              }
            }
          }
        }
      }
      ForEach(Array(d.posted.enumerated()), id: \.offset) { _, x in
        checkRow("⛳", "\(x.name) · \(x.gross.map(String.init) ?? "")", "POSTED · \(x.holes.map(String.init) ?? "") HOLES · ✓ ATTESTED")
      }
      ForEach(Array(d.skipped.enumerated()), id: \.offset) { _, x in
        checkRow("—", x.name, "NOT POSTED · \(x.reason.uppercased())")
      }
      ForEach(Array(d.guests.enumerated()), id: \.offset) { _, g in
        HStack(spacing: 10) {
          checkRow("🎟️", g.name, "GUEST RECAP — SHARE THE LINK")
          if let t = g.token {
            CSMini("Copy") { UIPasteboard.general.string = ClaimIntent.url(t).absoluteString; toast.show("Recap link copied") }
              .environment(\.cs, CSTokens.dark)
          }
        }
      }
      if let r = data.result {
        VStack(spacing: 10) {
          CSButton("Share the card", busy: busy) { shareCard(r) }
          CSButton("Share the settlement — no account needed", style: .quiet, busy: busy) { Task { await shareLink(r) } }
          Button("Revoke a shared link") { Task { await revoke() } }
            .font(CSFont.footnote).foregroundStyle(mut).frame(minHeight: 44)
        }
        .environment(\.cs, CSTokens.dark)
        .padding(.top, 8)
      }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .presentationBackground(CSDusk.ground)
    .sheet(item: $share) { LiveShareSheet(items: $0.items) }
  }

  private func checkRow(_ icon: String, _ line: String, _ sub: String) -> some View {
    HStack(spacing: 12) {
      Text(icon).font(CSFont.monoSmall).foregroundStyle(mut).frame(minWidth: 26, minHeight: 26)
        .background(CSDusk.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      VStack(alignment: .leading, spacing: 2) {
        Text(line).font(CSFont.subhead.weight(.semibold)).foregroundStyle(ink)
        Text(sub).font(CSFont.label).tracking(0.8).foregroundStyle(mut)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func card(_ r: LiveResult) -> LiveSettlementCard {
    LiveSettlementCard(result: r, money: r.recapRow.money, game: r.game.recapLabel, course: data.course, date: data.date)
  }

  /// `shareSettlementCard` (5839): the PNG and the `share` line together.
  private func shareCard(_ r: LiveResult) {
    guard let img = card(r).render() else { toast.show("Could not make the card."); return }
    share = LiveShareItems(items: [img, r.share.isEmpty ? "Settled on the course" : r.share])
  }

  /// `csShareLink('settlement', …)` (5857): mint, publish the card, share the page.
  private func shareLink(_ r: LiveResult) async {
    busy = true
    defer { busy = false }
    do {
      let tok = try await store.repo.mintShare(kind: "settlement", ref: data.lr)
      if let png = card(r).render()?.pngData() { await store.repo.publishSettlementCard(token: tok, png: png) }
      let url = URL(string: "https://cupseason.app/?share=\(tok.uuidString.lowercased())")!
      let text = String((r.share.isEmpty ? "The match is settled" : r.share).prefix(70))
      share = LiveShareItems(items: [text, url])
    } catch { toast.show(HumanError.text(error, prefix: "Could not make the link.")) }
  }

  private func revoke() async {
    do { try await store.repo.revokeShare(kind: "settlement", ref: data.lr); toast.show("Link is off — the page stops working for everyone") }
    catch { toast.show(HumanError.text(error, prefix: "Could not revoke.")) }
  }
}

// MARK: - the D78 hole strip (8045–8071)

/// "3&2" states a margin; the strip states the SHAPE. Heat is the subject's
/// holes, slate is everyone else's, hollow halved or carried, faded unplayed.
struct LiveHoleStrip: View {
  let ledger: LiveLedger
  let hot: String?
  var hotColor = Color(hex: 0xFF5A2E)
  var coolColor = Color(hex: 0x8E979E)

  var body: some View {
    VStack(spacing: 7) {
      HStack(alignment: .bottom, spacing: 3) {
        ForEach(0..<max(1, ledger.n), id: \.self) { i in
          let v = i < ledger.cells.count ? ledger.cells[i] : nil
          let isClose = ledger.closed == i + 1
          cell(v, tall: isClose)
        }
      }
      HStack {
        Text("1")
        Spacer()
        Text(ledger.footer).foregroundStyle(ledger.closed != nil ? hotColor : coolColor)
        Spacer()
        Text(String(ledger.n))
      }
      .font(CSFont.label).tracking(1.4).foregroundStyle(coolColor)
    }
    .padding(.top, 6)
    .accessibilityLabel("Hole strip, \(ledger.footer.lowercased())")
  }

  private func cell(_ v: LiveCell?, tall: Bool) -> some View {
    let hollow = v == .h || v == .c
    let mine = v != nil && hot != nil && v!.key == hot!
    let fill: Color = v == nil || hollow ? .clear : (mine ? hotColor : coolColor)
    let border: Color = v == nil ? Color(hex: 0x8E979E, opacity: 0.30) : hollow ? Color.white.opacity(0.42) : (mine ? hotColor : coolColor)
    return RoundedRectangle(cornerRadius: 2)
      .fill(fill)
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(border, lineWidth: 1))
      .frame(maxWidth: .infinity).frame(height: tall ? 20 : 14)
      .opacity(v == nil ? 0.28 : 1)
  }
}

// MARK: - the settlement card (`drawSettlementCard` 5727) — 1080 × 1350

/// The PNG that lands in a text thread. Every colour is the web's canvas
/// palette verbatim; the web draws it on a fixed dark ground in every theme.
struct LiveSettlementCard: View {
  let result: LiveResult
  let money: String
  let game: String
  let course: String
  let date: Date

  private let W: CGFloat = 1080, H: CGFloat = 1350
  private let bg = Color(hex: 0x0C0D0F), panel = Color(hex: 0x17191C), ink = Color(hex: 0xF0F2F3), mut = Color(hex: 0x8E979E)
  private let gold = Color(hex: 0xE9BE62), hot = Color(hex: 0xFF5A2E), slate = Color(hex: 0x66707A)

  private func mono(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
    Font.custom(weight == .medium ? "IBMPlexMono-Medium" : "IBMPlexMono-SemiBold", fixedSize: size)
  }
  private func serif(_ size: CGFloat) -> Font { Font.custom("Charter-Bold", fixedSize: size) }

  var body: some View {
    let r = result
    let twoSided = r.sideA != nil && r.sideB != nil
    let won = r.winner != nil
    let wSide = r.winner == "0" ? r.sideA : r.sideB, lSide = r.winner == "0" ? r.sideB : r.sideA
    ZStack {
      bg
      RoundedRectangle(cornerRadius: 28).fill(panel).padding(36)
      RoundedRectangle(cornerRadius: 28).stroke(Color(hex: 0xE9BE62, opacity: 0.35), lineWidth: 2).padding(36)
      VStack(spacing: 0) {
        Text(game.uppercased()).font(mono(32)).tracking(8).foregroundStyle(gold).padding(.top, 130)
        Spacer(minLength: 0)
        Group {
          if twoSided, won {
            let status = (r.status ?? "").uppercased()
            let m = status.range(of: #"^(\d+)\s*UP\s*THRU\s*(\d+)$"#, options: .regularExpression)
            let hero = m != nil ? status.replacingOccurrences(of: #"\s*THRU.*$"#, with: "", options: .regularExpression) : status
            let heroSub = m != nil ? "THRU " + status.replacingOccurrences(of: #"^.*THRU\s*"#, with: "", options: .regularExpression) : ""
            VStack(spacing: 14) {
              Text(hero).font(serif(260)).foregroundStyle(ink).lineLimit(1).minimumScaleFactor(0.1)
              if !heroSub.isEmpty { Text(heroSub).font(mono(30, .medium)).tracking(8).foregroundStyle(mut) }
              Text((wSide ?? "").uppercased()).font(mono(44)).tracking(6).foregroundStyle(ink).lineLimit(1).minimumScaleFactor(0.4)
              Text("DEF.").font(mono(26, .medium)).tracking(8).foregroundStyle(mut)
              Text((lSide ?? "").uppercased()).font(mono(40)).tracking(6).foregroundStyle(mut).lineLimit(1).minimumScaleFactor(0.4)
            }
          } else if twoSided {
            VStack(spacing: 10) {
              Text("ALL").font(serif(150)).foregroundStyle(ink)
              Text("SQUARE").font(serif(150)).foregroundStyle(ink)
              Text((r.sideA ?? "").uppercased()).font(mono(40)).tracking(6).foregroundStyle(ink).lineLimit(1).minimumScaleFactor(0.4)
              Text((r.sideB ?? "").uppercased()).font(mono(40)).tracking(6).foregroundStyle(ink).lineLimit(1).minimumScaleFactor(0.4)
            }
          } else {
            VStack(spacing: 40) {
              Text(r.share.isEmpty ? "SETTLED" : r.share).font(serif(76)).foregroundStyle(ink).multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.3)
              Text(game.uppercased()).font(mono(32, .medium)).tracking(8).foregroundStyle(mut)
            }
          }
        }
        .padding(.horizontal, 110)
        Spacer(minLength: 0)
        if let HL = r.holes, !HL.cells.isEmpty {
          HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<max(1, HL.n), id: \.self) { i in
              let v = i < HL.cells.count ? HL.cells[i] : nil
              let isClose = HL.closed == i + 1
              let hollow = v == nil || v == .h || v == .c
              let mine = v != nil && HL.hot != nil && v!.key == HL.hot!.key
              RoundedRectangle(cornerRadius: 4)
                .fill(hollow ? Color.clear : (mine ? hot : slate))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(hollow ? Color.white.opacity(0.42) : .clear, lineWidth: 2))
                .frame(maxWidth: .infinity).frame(height: isClose ? 56 : 46)
                .opacity(v == nil ? 0.28 : 1)
            }
          }
          .padding(.horizontal, 150)
          if let legend = HL.legend {
            HStack(spacing: 12) {
              RoundedRectangle(cornerRadius: 4).fill(hot).frame(width: 20, height: 20)
              Text(legend.uppercased()).font(mono(24, .medium)).foregroundStyle(mut)
            }
            .padding(.top, 60)
          }
        }
        Spacer(minLength: 0)
        Text(money.uppercased()).font(mono(30)).tracking(5).foregroundStyle(gold).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.5).padding(.horizontal, 100)
        Rectangle().fill(Color.white.opacity(0.1)).frame(width: 520, height: 1).padding(.top, 40)
        Text((course.isEmpty ? "A ROUND" : course).uppercased()).font(mono(34)).tracking(4).foregroundStyle(ink).lineLimit(1).minimumScaleFactor(0.5).padding(.top, 50).padding(.horizontal, 100)
        Text(LiveSettlementCard.dateLine(date)).font(mono(27, .medium)).tracking(4).foregroundStyle(mut).padding(.top, 24)
        Text("Cup Season").font(serif(50)).foregroundStyle(ink).padding(.top, 70)
        Text("cupseason.app").font(mono(25, .medium)).tracking(4).foregroundStyle(mut).padding(.top, 12).padding(.bottom, 100)
      }
    }
    .frame(width: W, height: H)
  }

  /// "SAT · AUG 22"
  static func dateLine(_ d: Date, calendar: Calendar = .current) -> String {
    let DW = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], MO = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    let c = calendar.dateComponents([.weekday, .month, .day], from: d)
    return "\(DW[max(0, (c.weekday ?? 1) - 1)]) · \(MO[max(0, (c.month ?? 1) - 1)]) \(c.day ?? 1)"
  }

  @MainActor
  func render() -> UIImage? {
    let r = ImageRenderer(content: self)
    r.scale = 1
    r.proposedSize = ProposedViewSize(width: W, height: H)
    return r.uiImage
  }
}

// MARK: - the share sheet (`navigator.share({files, text})`)

struct LiveShareItems: Identifiable {
  let id = UUID()
  let items: [Any]
}

struct LiveShareSheet: UIViewControllerRepresentable {
  let items: [Any]
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }
  func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
