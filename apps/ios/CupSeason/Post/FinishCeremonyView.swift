// Cup Season — the finish screen (index.html `#finish` 3691–3701,
// `finishCeremony` 6040–6084, the CSS 2090–2166).
//
// A posted round ends in ceremony, not a toast: dusk-locked in every theme,
// `COURSE · SAT AUG 22` in the eyebrow, the serif gross rolling into the cup,
// the band line from the one phrase producer, and the points line in
// champagne ONLY when league points exist — "COUNTS ON YOUR CARD" otherwise.
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
  /// E2 · when known, the card share carries the round's public link too.
  var roundId: UUID? = nil
  let photo: UIImage?
  let onBack: () -> Void

  @State private var stage = 0
  @State private var thock = false
  @State private var share: PostShareItem?
  @ScaledMetric(relativeTo: .largeTitle) private var grossSize: CGFloat = 88

  // the web's finish palette, verbatim (2098, 2145–2148, 2153)
  private let eyebrowInk = Color(hex: 0x8FA096)
  private let bandInk = Color(hex: 0xECEEF2)
  private let shareBg = Color(hex: 0x2FA46A)
  private let shareInk = Color(hex: 0x06130B)
  private let glow = Color(hex: 0x12271B)

  var body: some View {
    ZStack {
      CSDusk.ground.ignoresSafeArea()
      RadialGradient(colors: [glow, CSDusk.ground], center: UnitPoint(x: 0.5, y: -0.1), startRadius: 0, endRadius: 520).ignoresSafeArea()
      VStack(spacing: 0) {
        Spacer(minLength: 24)
        Text(ceremony.eyebrow).font(CSFont.eyebrow).tracking(2.6).textCase(.uppercase).foregroundStyle(eyebrowInk)
          .multilineTextAlignment(.center).opacity(stage >= 1 ? 1 : 0)
        PostCupRoll(rolled: stage >= 2, reduceMotion: reduceMotion).frame(height: 44).padding(.top, 18)
        Text("\(ceremony.gross)").font(.custom("Charter-Bold", size: grossSize, relativeTo: .largeTitle)).foregroundStyle(bandInk)
          .csTabular().opacity(stage >= 2 ? 1 : 0).offset(y: stage >= 2 ? 0 : 6)
          .accessibilityLabel("\(ceremony.gross) gross")
        if !ceremony.band.isEmpty {
          Text(ceremony.band).font(CSFont.sentence).foregroundStyle(bandInk).multilineTextAlignment(.center)
            .padding(.top, 12).opacity(stage >= 3 ? 1 : 0).offset(y: stage >= 3 ? 0 : 6)
        }
        Text(ceremony.pointsLine).font(CSFont.monoMediumBody.weight(.semibold)).tracking(2).textCase(.uppercase)
          .foregroundStyle(ceremony.earned ? CSTokens.dark.gold : eyebrowInk)
          .multilineTextAlignment(.center).padding(.top, 24).opacity(stage >= 4 ? 1 : 0).offset(y: stage >= 4 ? 0 : 6)
        Rectangle().fill(bandInk.opacity(0.1)).frame(width: 120, height: 1).padding(.top, 22).opacity(stage >= 5 ? 1 : 0)
        Button { Task { await shareCard() } } label: {
          Text(PostCeremony.shareLabel).font(CSFont.button).foregroundStyle(shareInk)
            .frame(minWidth: 220, minHeight: 46).padding(.horizontal, 28)
            .background(shareBg, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        }
        .buttonStyle(.plain).padding(.top, 26).opacity(stage >= 5 ? 1 : 0)
        Button(action: onBack) {
          Text(PostCeremony.backLabel).font(CSFont.subhead.weight(.medium)).foregroundStyle(eyebrowInk).frame(minHeight: 44).padding(.horizontal, 12)
        }
        .buttonStyle(.plain).padding(.top, 8).opacity(stage >= 5 ? 1 : 0)
        Spacer(minLength: 24)
      }
      .padding(.horizontal, 24)
      .frame(maxWidth: 440)
    }
    .onAppear { run(); thock = true }
    .csFeedback(.posted, trigger: thock)
    .sheet(item: $share) { PostShareSheet(items: $0.items) }
    .accessibilityAddTraits(.isModal)
  }

  private func run() {
    if reduceMotion { stage = 5; return }
    let roll = Animation.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.64)
    withAnimation(roll.delay(0.2)) { stage = 1 }
    withAnimation(roll.delay(0.9)) { stage = 2 }
    withAnimation(roll.delay(2.03)) { stage = 3 }
    withAnimation(roll.delay(2.21)) { stage = 4 }
    withAnimation(.easeOut(duration: 0.5).delay(2.55)) { stage = 5 }
  }

  /// E2 (IOS-028) · the card leaves with its link. Best effort: no round id,
  /// or a mint that fails, and the card still shares exactly as it did.
  private func shareCard() async {
    var url: URL?
    if let roundId {
      url = try? await PostService().shareLink(round: roundId) { data in PostPhoto.compress(data: data, maxDim: 1600, quality: 0.8) }
    }
    share = RecapCardView.shareItem(ceremony.recap, photo: photo, url: url)
  }
}

/// The ball rolls into the cup under the gross (`.finish-ball` / `.finish-cup`).
private struct PostCupRoll: View {
  let rolled: Bool
  let reduceMotion: Bool
  private let ink = Color(hex: 0xECEEF2)
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
