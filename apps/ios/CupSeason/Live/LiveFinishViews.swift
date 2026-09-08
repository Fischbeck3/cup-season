// Cup Season — the finish and the recap (index.html `finishRealLiveRound`
// 9109–9177, `showLiveRecap` 9178–9308, the D78 strip 8045–8071, the
// settlement card 5727–5838, D57 share links 5857–5935).
//
// WAVE 8 · **THE SETTLEMENT CARD IS RENDERED IN-APP AT THE GEOMETRY IT EXPORTS
// AT** (UI_SYSTEM §11.3, D277). The audit calls the card the most beautiful
// object in the product and the golfer who won it never sees it: it exists only
// as a PNG in somebody else's text thread. The recap now shows the card itself,
// at 1080 × 1350 scaled to the measure — one object, one geometry, no second
// in-app rendering to drift from it.
//
// And the card is on the product's own palette at last. Every colour in it was
// a hex literal from the palette D270 replaced — `#F0F2F3` ink beside the app's
// `#F1F4EF`, `#FF5A2E` beside `#E8622C` — so the artifact a golfer shares was
// printed in the old brand while the app wore the new one. It reads the
// `ceremony` ramp now, which is pinned in both printings, and its faces are
// ROLES at a literal size (`CSType.fixed`) rather than two more PostScript
// strings: Charter is retired (D268) and the serif is New York.

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
    SheetFrame("Finish the round", sub: "ONE FINISH FOR THE WHOLE GROUP") {
      CSFine(f.intro)
      if let w = f.warning {
        Text(w).csType(.bodyS).foregroundStyle(cs.neg).fixedSize(horizontal: false, vertical: true)
      }
      Button(f.primary) { Task { if await store.finish(casual: false) { dismiss() } } }
        .buttonStyle(.csPrimary(busy: store.busy))
      Button(f.secondary) { Task { if await store.finish(casual: true) { dismiss() } } }
        .buttonStyle(.csSecondary(busy: store.busy))
    }
    .presentationDetents([.medium, .large])
  }
}

// MARK: - The recap (9178–9308) — the ceremony ground, for every viewer

struct LiveRecapSheet: View {
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  let data: LiveRecapData
  @Bindable var store: LiveRoundStore
  @State private var share: LiveShareItems?
  @State private var busy = false

  private let d = CSTokens.dark

  var body: some View {
    let o = data.outcome
    let empty = data.result == nil && o.posted.isEmpty && o.skipped.isEmpty && o.guests.isEmpty
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          takeover(o)
          VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
            if empty {
              Text("Nothing to post.").csType(.body).foregroundStyle(d.mut)
            }
            if let r = data.result {
              // **the object, at the size it ships at.** Not a second layout
              // of the same facts: the card itself, scaled to the measure.
              settlementCard(r)
              if let H = r.holes, !H.cells.isEmpty {
                LiveHoleStrip(ledger: H, hot: H.hot?.key)
                if let legend = H.legend {
                  HStack(spacing: CSTokens.Space.s2) {
                    Rectangle().fill(d.brand).frame(width: 9, height: 9)
                    Text(legend).csType(.agateS, caps: true).foregroundStyle(d.mut)
                  }
                  .accessibilityElement(children: .combine)
                }
                let hl = H.highlights
                if !hl.isEmpty {
                  LiveFlow(spacing: CSTokens.Space.s2) {
                    ForEach(hl, id: \.self) { t in CSChip(t, selected: false) }
                  }
                }
              }
            }
            if !o.posted.isEmpty || !o.skipped.isEmpty || !o.guests.isEmpty {
              CSSectionHead("The cards", count: "\(o.posted.count) posted")
            }
            ForEach(Array(o.posted.enumerated()), id: \.offset) { _, x in
              checkRow(x.name, "\(x.gross.map(String.init) ?? "—") gross · \(x.holes.map(String.init) ?? "") holes · vouched", posted: true)
            }
            ForEach(Array(o.skipped.enumerated()), id: \.offset) { _, x in
              checkRow(x.name, "Not posted · \(x.reason)", posted: false)
            }
            ForEach(Array(o.guests.enumerated()), id: \.offset) { _, g in
              A11yStack(spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s2) {
                checkRow(g.name, "Guest recap — share the link", posted: false)
                if let t = g.token {
                  CSMini("Copy") {
                    UIPasteboard.general.string = ClaimIntent.url(t).absoluteString
                    toast.show("Recap link copied", kind: .confirmed)
                  }
                  .accessibilityLabel("Copy \(g.name)'s recap link")
                }
              }
            }
            if let r = data.result {
              VStack(spacing: CSTokens.Space.s3) {
                Button("Share the card") { shareCard(r) }
                  .buttonStyle(.csPrimary(busy: busy))
                Button("Share the settlement page") { Task { await shareLink(r) } }
                  .buttonStyle(.csSecondary(busy: busy))
                Button("Revoke a shared link") { Task { await revoke() } }
                  .buttonStyle(.csTertiary(.content))
              }
              .padding(.top, CSTokens.Space.s2)
            }
          }
          .csGutter()
        }
        .padding(.bottom, CSTokens.Space.s6)
      }
      .background(CSDusk.ground)
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.hidden, for: .navigationBar)
      .csCloseButton { dismiss() }
    }
    .csCeremony()
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .presentationBackground(CSDusk.ground)
    .sheet(item: $share) { LiveShareSheet(items: $0.items) }
  }

  /// The round's own takeover: what happened, in `display`, on the ceremony
  /// ground, with the money as the figure that tallies.
  @ViewBuilder private func takeover(_ o: LiveFinishOutcome) -> some View {
    let casual = o.casual
    let line = data.result?.share ?? ""
    CSTakeover(
      eyebrow: casual ? "Casual — nothing posted" : "Round posted",
      lines: [line.isEmpty ? (casual ? "Nothing posted" : "The cards are in")
                           : String(line.prefix(64))],
      figure: nil,
      marker: nil
    ) {
      Text("\(o.posted.count) card\(o.posted.count == 1 ? "" : "s")\(store.leagueId == nil ? " posted" : " to the season")")
        .csType(.agate, caps: true).foregroundStyle(d.ceremonyMut)
    }
  }

  /// The exported object, in the app, at the geometry it exports at. It is
  /// laid out at 1080 × 1350 and scaled — so what a golfer sees here and what
  /// lands in the thread are the same picture, not two renderings of it.
  private func settlementCard(_ r: LiveResult) -> some View {
    GeometryReader { geo in
      let scale = geo.size.width / 1080
      card(r)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: geo.size.width, height: 1350 * scale)
    }
    .frame(height: nil)
    .aspectRatio(1080 / 1350, contentMode: .fit)
    .accessibilityLabel("The settlement card. \(r.share.isEmpty ? "Settled" : r.share)")
  }

  private func checkRow(_ name: String, _ sub: String, posted: Bool) -> some View {
    HStack(spacing: CSTokens.Space.s3) {
      CSGlyph(posted ? .check : .cross, size: .row)
        .foregroundStyle(posted ? d.pos : d.mut)
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(name).csType(.name).foregroundStyle(d.ink)
        Text(sub).csType(.agate, caps: true).foregroundStyle(d.mut)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, CSTokens.Space.s2)
    .frame(maxWidth: .infinity, alignment: .leading)
    .overlay(alignment: .bottom) { CSRule() }
    .accessibilityElement(children: .combine)
  }

  private func card(_ r: LiveResult) -> LiveSettlementCard {
    LiveSettlementCard(result: r, money: r.recapRow.money, game: r.game.recapLabel, course: data.course, date: data.date)
  }

  /// `shareSettlementCard` (5839): the PNG and the `share` line together.
  private func shareCard(_ r: LiveResult) {
    guard let img = card(r).render() else { toast.show("Could not make the card.", kind: .failed); return }
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
    } catch { toast.show(HumanError.text(error, prefix: "Could not make the link."), kind: .failed) }
  }

  private func revoke() async {
    do { try await store.repo.revokeShare(kind: "settlement", ref: data.lr); toast.show("Link is off — the page stops working for everyone", kind: .confirmed) }
    catch { toast.show(HumanError.text(error, prefix: "Could not revoke."), kind: .failed) }
  }
}

// MARK: - the D78 hole strip (8045–8071)

/// "3&2" states a margin; the strip states the SHAPE. The subject's holes take
/// `brand`, everyone else's `cool`, hollow halved or carried, faded unplayed —
/// on the ceremony ramp, so the strip in the recap and the strip on the card
/// are the same drawing.
struct LiveHoleStrip: View {
  let ledger: LiveLedger
  let hot: String?
  var hotColor = CSTokens.dark.ceremonyBrand
  var coolColor = CSTokens.dark.ceremonyCool

  var body: some View {
    VStack(spacing: CSTokens.Space.s2) {
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
      .csType(.agateS, caps: true).foregroundStyle(coolColor)
    }
    .padding(.top, CSTokens.Space.s2)
    .accessibilityLabel("Hole strip, \(ledger.footer.lowercased())")
  }

  private func cell(_ v: LiveCell?, tall: Bool) -> some View {
    let hollow = v == .h || v == .c
    let mine = v != nil && hot != nil && v!.key == hot!
    let fill: Color = v == nil || hollow ? .clear : (mine ? hotColor : coolColor)
    let border: Color = v == nil ? coolColor.opacity(CSTokens.Alpha.a24)
      : hollow ? CSTokens.dark.ceremonyInk.opacity(CSTokens.Alpha.a56) : (mine ? hotColor : coolColor)
    return Rectangle()
      .fill(fill)
      .overlay(Rectangle().stroke(border, lineWidth: CSTokens.Space.hair))
      .frame(maxWidth: .infinity).frame(height: tall ? 20 : 14)
      .opacity(v == nil ? CSTokens.Alpha.a24 : 1)
  }
}

// MARK: - the settlement card (`drawSettlementCard` 5727) — 1080 × 1350

/// The object that lands in a text thread, and now the object the winner sees
/// in the app. **Every value is a token on the pinned `ceremony` ramp** and
/// every face is a ROLE at a literal size — the card does not scale with a
/// reading size, because a PNG is the same picture on every phone.
struct LiveSettlementCard: View {
  let result: LiveResult
  let money: String
  let game: String
  let course: String
  let date: Date

  private let W: CGFloat = 1080, H: CGFloat = 1350
  private let d = CSTokens.dark

  var body: some View {
    let r = result
    let twoSided = r.sideA != nil && r.sideB != nil
    let won = r.winner != nil
    let wSide = r.winner == "0" ? r.sideA : r.sideB, lSide = r.winner == "0" ? r.sideB : r.sideA
    ZStack {
      d.ceremony
      // the object's own edge — the folio rule, not a border token
      Rectangle().stroke(d.ceremonyGold.opacity(CSTokens.Alpha.a24), lineWidth: 2).padding(36)
      VStack(spacing: 0) {
        Text(game).csFixed(.agate, 32).textCase(.uppercase)
          .tracking(8).foregroundStyle(d.ceremonyGold).padding(.top, 130)
        Spacer(minLength: 0)
        Group {
          if twoSided, won {
            let status = (r.status ?? "")
            let m = status.range(of: #"^(\d+)\s*up\s*thru\s*(\d+)$"#, options: [.regularExpression, .caseInsensitive])
            let hero = m != nil ? status.replacingOccurrences(of: #"\s*(?i)thru.*$"#, with: "", options: .regularExpression) : status
            let heroSub = m != nil ? "THRU " + status.replacingOccurrences(of: #"^(?i).*thru\s*"#, with: "", options: .regularExpression) : ""
            VStack(spacing: 14) {
              Text(hero).csFixed(.figureXL, 250).textCase(.uppercase)
                .foregroundStyle(d.ceremonyInk).lineLimit(1).minimumScaleFactor(0.1)
              if !heroSub.isEmpty {
                Text(heroSub).csFixed(.agate, 30).textCase(.uppercase).tracking(8).foregroundStyle(d.ceremonyMut)
              }
              Text(wSide ?? "").csFixed(.display, 52).textCase(.uppercase)
                .foregroundStyle(d.ceremonyInk).lineLimit(1).minimumScaleFactor(0.4)
              Text("DEF.").csFixed(.agate, 26).tracking(8).foregroundStyle(d.ceremonyMut)
              Text(lSide ?? "").csFixed(.display, 46).textCase(.uppercase)
                .foregroundStyle(d.ceremonyMut).lineLimit(1).minimumScaleFactor(0.4)
            }
          } else if twoSided {
            VStack(spacing: 10) {
              Text("ALL SQUARE").csFixed(.figureL, 140).textCase(.uppercase)
                .foregroundStyle(d.ceremonyInk).multilineTextAlignment(.center)
              Text(r.sideA ?? "").csFixed(.display, 46).textCase(.uppercase)
                .foregroundStyle(d.ceremonyInk).lineLimit(1).minimumScaleFactor(0.4)
              Text(r.sideB ?? "").csFixed(.display, 46).textCase(.uppercase)
                .foregroundStyle(d.ceremonyInk).lineLimit(1).minimumScaleFactor(0.4)
            }
          } else {
            VStack(spacing: 40) {
              Text(r.share.isEmpty ? "Settled" : r.share).csFixed(.lead, 76)
                .foregroundStyle(d.ceremonyInk).multilineTextAlignment(.center)
                .lineLimit(3).minimumScaleFactor(0.3)
              Text(game).csFixed(.agate, 32).textCase(.uppercase)
                .tracking(8).foregroundStyle(d.ceremonyMut)
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
              Rectangle()
                .fill(hollow ? Color.clear : (mine ? d.ceremonyBrand : d.ceremonyCool))
                .overlay(Rectangle().stroke(hollow ? d.ceremonyInk.opacity(CSTokens.Alpha.a56) : .clear, lineWidth: 2))
                .frame(maxWidth: .infinity).frame(height: isClose ? 56 : 46)
                .opacity(v == nil ? CSTokens.Alpha.a24 : 1)
            }
          }
          .padding(.horizontal, 150)
          if let legend = HL.legend {
            HStack(spacing: 12) {
              Rectangle().fill(d.ceremonyBrand).frame(width: 20, height: 20)
              Text(legend).csFixed(.agate, 24).textCase(.uppercase).foregroundStyle(d.ceremonyMut)
            }
            .padding(.top, 60)
          }
        }
        Spacer(minLength: 0)
        Text(money).csFixed(.agate, 30).textCase(.uppercase).tracking(5)
          .foregroundStyle(d.ceremonyGold).multilineTextAlignment(.center)
          .lineLimit(2).minimumScaleFactor(0.5).padding(.horizontal, 100)
        Rectangle().fill(d.folioRule).frame(width: 520, height: 1).padding(.top, 40)
        Text(course.isEmpty ? "A round" : course).csFixed(.display, 40).textCase(.uppercase)
          .foregroundStyle(d.ceremonyInk).lineLimit(1).minimumScaleFactor(0.5)
          .padding(.top, 50).padding(.horizontal, 100)
        Text(LiveSettlementCard.dateLine(date)).csFixed(.agate, 27).tracking(4)
          .foregroundStyle(d.ceremonyMut).padding(.top, 24)
        Text("Cup Season").csFixed(.display, 50).textCase(.uppercase)
          .tracking(2).foregroundStyle(d.ceremonyInk).padding(.top, 70)
        Text("cupseason.app").csFixed(.agate, 25).tracking(4)
          .foregroundStyle(d.ceremonyMut).padding(.top, 12).padding(.bottom, 100)
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
