// Cup Season — the finish screen (index.html `#finish` 3691–3701,
// `finishCeremony` 6040–6084, the CSS 2090–2166).
//
// A posted round ends in ceremony, not a toast: dusk-locked in every theme,
// `COURSE · SAT AUG 22` in the eyebrow, the serif gross rolling into the cup,
// the band line from the one phrase producer, and the points line in
// champagne ONLY when league points exist — "COUNTS TOWARD YOUR NUMBER" otherwise.
// The stagger is the web's (band at 2.03s, points at 2.21s, the buttons at
// 2.55s); reduced motion lands on the rest frame at once. The thock —
// `.success` through `sensoryFeedback` — fires as the screen appears
// (IOS-003 §2.8, IOS-022 item 6).

import SwiftUI
import CSDesign
import CupSeasonKit

struct FinishCeremonyView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let ceremony: PostCeremony
  let photo: UIImage?
  let onBack: () -> Void
  var roundId: UUID? = nil
  @State private var showReceipt = false
  @State private var showPreview = false

  @State private var stage = 0
  @State private var thock = false

  // **WAVE 11 · THE FINISH IS ON THE CEREMONY RAMP, NOT ON THE OLD WEB'S
  // HEXES.** Five literals were copied out of `index.html` and lived here in
  // this repo's own hex form — the one form `LINT-04`'s regex could not see —
  // so the moment a golfer finishes a round rendered in the palette D270
  // DELETED: `#2FA46A` is Fairway, the brand green the ember replaced, and
  // `#12271B` is `pine`, a token D270 removes by name. The Share control wore
  // a colour that was in no token file at all.
  //
  // Every one of them is a `ceremony` token now, which is what a pinned
  // physical moment is drawn on, and the Share button is the screen's one
  // primary — so it is EMBER (non-negotiable 4), not a retired green.
  private var eyebrowInk: Color { CSTokens.dark.ceremonyMut }
  private var bandInk: Color { CSTokens.dark.ceremonyInk }
  private var shareBg: Color { CSTokens.dark.ceremonyBrand }
  private var shareInk: Color { CSTokens.dark.ceremony }

  var body: some View {
    ZStack {
      // **AND THE WASH IS GONE.** A radial gradient over a ground is the one
      // image state D272 bans by name, and this one was drawn in a deleted
      // token. One ground, painted once (the audit's F-04 / F-05).
      CSTokens.dark.bg0.ignoresSafeArea()
      VStack { Spacer(); CSTopoField().frame(height: 110) }.allowsHitTesting(false)
      ScrollView {
      VStack(spacing: 0) {
        Spacer(minLength: 24)
        Text(ceremony.eyebrow).font(CSFont.eyebrow).tracking(2.6).textCase(.uppercase).foregroundStyle(eyebrowInk)
          .multilineTextAlignment(.center).opacity(stage >= 1 ? 1 : 0)
        if let photo {
          Image(uiImage: photo).resizable().scaledToFill()
            .frame(maxWidth: 340).frame(height: 120).clipped()
            .padding(.top, CSTokens.Space.s4).opacity(stage >= 1 ? 1 : 0)
            .accessibilityLabel("Round photograph")
        }
        PostCupRoll(rolled: stage >= 2, reduceMotion: reduceMotion).frame(height: 44).padding(.top, 18)
        // D267 / D268 · a gross is a FIGURE, and the serif it was set in is
        // Charter, which D268 retired. `figureXL` is the role: the board face,
        // tabular, capped at ×1.45 so an accessibility size grows it without
        // driving the band off the screen. It was the last `.custom("` outside
        // the type file in the product (`LINT-01`, and D258's own mechanism).
        Text("\(ceremony.gross)").csType(.figureXL).foregroundStyle(bandInk)
          .opacity(stage >= 2 ? 1 : 0).offset(y: stage >= 2 ? 0 : 6)
          .accessibilityLabel("\(ceremony.gross) gross")
        if !ceremony.band.isEmpty {
          Text(ceremony.band).csType(.story).foregroundStyle(bandInk).multilineTextAlignment(.center)
            .padding(.top, 12).opacity(stage >= 3 ? 1 : 0).offset(y: stage >= 3 ? 0 : 6)
        }
        Text(ceremony.pointsLine).font(CSFont.monoMediumBody.weight(.semibold)).tracking(2).textCase(.uppercase)
          .foregroundStyle(ceremony.earned ? CSTokens.dark.gold : eyebrowInk)
          .multilineTextAlignment(.center).padding(.top, 24).opacity(stage >= 4 ? 1 : 0).offset(y: stage >= 4 ? 0 : 6)
        Rectangle().fill(bandInk.opacity(0.1)).frame(width: 120, height: 1).padding(.top, 22).opacity(stage >= 5 ? 1 : 0)
        if roundId != nil {
          Button("View receipt") { showReceipt = true }
            .buttonStyle(.csTertiary(.toolbar))
            .padding(.top, 12).opacity(stage >= 5 ? 1 : 0)
        }
        Button { showPreview = true } label: {
          Text(PostCeremony.shareLabel).csType(.name).foregroundStyle(shareInk)
            .frame(minWidth: 220, minHeight: 46).padding(.horizontal, 28)
            .background(shareBg, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        }
        .buttonStyle(.plain).padding(.top, 26).opacity(stage >= 5 ? 1 : 0)
        Button(action: onBack) {
          Text(PostCeremony.backLabel).font(CSFont.subhead.weight(.medium)).foregroundStyle(eyebrowInk).frame(minHeight: 44).padding(.horizontal, 12)
        }
        .buttonStyle(.plain).padding(.top, 8).opacity(stage >= 5 ? 1 : 0)
        Text(CSBrandCopy.tagline).csType(.agateS, caps: true)
          .foregroundStyle(eyebrowInk).padding(.top, CSTokens.Space.s4).opacity(stage >= 5 ? 1 : 0)
        Spacer(minLength: 24)
      }
      .padding(.horizontal, 24)
      .frame(maxWidth: 440)
      .frame(maxWidth: .infinity)
      }
    }
    .environment(\.cs, CSTokens.dark)
    .environment(\.colorScheme, .dark)
    .preferredColorScheme(.dark)
    .onAppear { run(); thock = true }
    .csFeedback(.posted, trigger: thock)
    .sheet(isPresented: $showPreview) { RoundSharePreview(recap: ceremony.recap, photo: photo) }
    .sheet(isPresented: $showReceipt) {
      if let roundId { RoundReceiptSheet(roundId: roundId, seed: nil) }
    }
    .accessibilityAddTraits(.isModal)
  }

  private func run() {
    if reduceMotion { stage = 5; return }
    // L-30 · one curve. The ceremony's five stages are the roll at 0.64 and
    // the last one at 0.5 — it was `easeOut`, which is a second easing doing a
    // job the roll already does. `reduceMotion` above rests it on stage 5.
    let roll = Animation.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.64)
    let last = Animation.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.5)
    CSMotion.run(roll.delay(0.2)) { stage = 1 }
    CSMotion.run(roll.delay(0.9)) { stage = 2 }
    CSMotion.run(roll.delay(2.03)) { stage = 3 }
    CSMotion.run(roll.delay(2.21)) { stage = 4 }
    CSMotion.run(last.delay(2.55)) { stage = 5 }
  }
}

/// The ball rolls into the cup under the gross (`.finish-ball` / `.finish-cup`).
private struct PostCupRoll: View {
  let rolled: Bool
  let reduceMotion: Bool
  private var ink: Color { CSTokens.dark.ceremonyInk }
  var body: some View {
    GeometryReader { g in
      let w = g.size.width, mid = w / 2
      ZStack(alignment: .bottomLeading) {
        // the cup: a ring at centre
        Ellipse().stroke(ink.opacity(0.35), lineWidth: 1.5).frame(width: 34, height: 12).position(x: mid, y: g.size.height - 8)
        Ellipse().fill(CSDusk.ground).frame(width: 30, height: 9).position(x: mid, y: g.size.height - 8)
        // the ball
        Circle().fill(ink).frame(width: 12, height: 12)
          .position(x: rolled || reduceMotion ? mid : max(6, mid - 140), y: g.size.height - 12 + (rolled ? 3 : 0))
          .opacity(rolled ? 0 : 1)
          .animation(reduceMotion ? nil : .timingCurve(0.16, 0.84, 0.36, 1, duration: 0.9), value: rolled)
      }
    }
    .accessibilityHidden(true)
  }
}

#Preview("ceremony") {
  FinishCeremonyView(ceremony: PostCeremony(course: "Papago", date: "2026-08-22", gross: 84, vs: 2.4, points: 9, squad: "The Pines",
                                            inLeague: true, name: "Jerecho", marker: "saguaro", leagueName: "PIGL"), photo: nil, onBack: {})
}
