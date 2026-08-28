// Cup Season — the Forge (IOS-003 §1 "The Forge door", §2.7; IOS-023).
//
// The web's Entry V5 show, rebuilt in code so the rest frame is the LIVE logo
// (never a poster frame) and reduced motion can rest on it immediately. Four
// tracers draw on the heat ramp (warm → hot → fire → ink), the wordmark sears
// in letter by letter, the fuse burns under it, the three cooler tracers burn
// off and the survivor (fire) hands its line to the mark. Once per device
// (`cs_forge`, the web's key); the door rests on the mark ever after.
//
// The whole frame is a pure function of elapsed time (`ForgeFrame(t:)`), so
// the rest frame IS the frame at t ≥ end — the two cannot drift. Timings are
// the web's keyframe seconds through ONE compression (`ForgeTimeline.k`),
// which lands the 5.6s show inside 2.2s. No springs: the CSS curves the web
// uses (`ease`, `ease-out`, the roll) are the curves here.

import SwiftUI
import CSDesign

// MARK: - The timeline (index.html 1668–1760, 2572–2627)

enum ForgeTimeline {
  /// 5.6s on the web → ≤ 2.2s on the phone. The one number that compresses.
  static let k: Double = 0.38

  struct Cue: Sendable {
    let start: Double
    let duration: Double
    var end: Double { start + duration }
  }
  /// A web cue (delay, duration — seconds as written in the CSS), compressed.
  static func cue(_ delay: Double, _ duration: Double) -> Cue { Cue(start: delay * k, duration: duration * k) }

  /// `csDraw 1.05s ease` at .30 / .85 / 1.40 / 1.95 — the heat-ramp firing order.
  static let tracerDraw: [Cue] = [cue(0.30, 1.05), cue(0.85, 1.05), cue(1.40, 1.05), cue(1.95, 1.05)]
  /// `csGone` — three at 4.6s/.8s; the survivor (fire) at 4.8s/.6s.
  static let tracerGone: [Cue] = [cue(4.6, 0.8), cue(4.6, 0.8), cue(4.8, 0.6), cue(4.6, 0.8)]
  /// `.ob-amb`: csFade 1.2s at 1s, csGone .8s at 4.6s.
  static let ambientIn = cue(1.0, 1.2)
  static let ambientGone = cue(4.6, 0.8)
  /// `.obspark` — one landing echo per tracer: 1.35 / 1.9 / 2.45 / 3.0, .3s.
  static let sparks: [Cue] = [cue(1.35, 0.3), cue(1.9, 0.3), cue(2.45, 0.3), cue(3.0, 0.3)]
  /// `obSear .9s ease` per letter: (C,U)(P,S)(E,A)(S,O,N) land with the tracers.
  static let letterDelays: [Double] = [1.35, 1.45, 1.9, 2.0, 2.45, 2.55, 3.0, 3.1, 3.2]
  static let letters: [Cue] = letterDelays.map { cue($0, 0.9) }
  /// `obRule` / `obFuse` 1.1s ease-out at 3.15s.
  static let fuse = cue(3.15, 1.1)
  /// `csForge .9s var(--roll)` at 4.7s — the mark's arrival.
  static let mark = cue(4.7, 0.9)
  /// The door rises with the mark (the web's #obDoor follows the forge).
  static let handoff: Double = mark.start
  /// When the frame stops changing: the rest frame from here on.
  static let end: Double = mark.end
  /// Any t past `end` renders the rest frame exactly.
  static let rest: Double = end + 1

  // the CSS curves, by name
  static let ease = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.25, y: 0.1), endControlPoint: UnitPoint(x: 0.25, y: 1))
  static let easeOut = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0, y: 0), endControlPoint: UnitPoint(x: 0.58, y: 1))
  static let roll = CSTokens.Motion.roll

  /// 0…1 through `cue` at time `t`, eased. Clamped on both ends.
  static func progress(_ t: Double, _ cue: Cue, _ curve: UnitCurve = ease) -> Double {
    let raw = (t - cue.start) / cue.duration
    return curve.value(at: min(1, max(0, raw)))
  }
}

// MARK: - The geometry (the web's 460×300 viewBox)

enum ForgeGeometry {
  static let viewBox = CGSize(width: 460, height: 300)
  /// The visible band of the viewBox: the mark lives in rows 65–230, the
  /// tracers fly in from above and outside it and are not clipped.
  static let top: CGFloat = 40
  static let visibleHeight: CGFloat = 200
  static let cup = CGPoint(x: 230, y: 226)

  /// The four tracers, verbatim (index.html 2589–2592).
  static let tracers: [String] = [
    "M-24 96 C 80 118, 160 176, 224 224",
    "M96 -20 C 140 66, 190 160, 227 222",
    "M372 -16 C 352 44, 310 150, 249 199",
    "M484 96 C 380 118, 300 176, 236 224",
  ]

  /// The mark, icon weight (index.html 2611–2614): the comet, the cup, the
  /// stick, the flag — in mark units, placed by translate(150 46) scale(2.15).
  static let mark: Path = {
    var p = SVGPath.path("M88 12 C 82 36, 70 59, 54 73 C 51 76, 47 75, 46 72 C 60 60, 73 38, 83 13 C 84 10, 87 9, 88 12 Z")
    p.addEllipse(in: CGRect(x: 38 - 17, y: 79 - 6.5, width: 34, height: 13))
    p.addRoundedRect(in: CGRect(x: 27, y: 13, width: 10, height: 68), cornerSize: CGSize(width: 5, height: 5))
    p.addPath(SVGPath.path("M36 13 L74 26 L36 39 Z"))
    return p.applying(CGAffineTransform(scaleX: 2.15, y: 2.15).concatenating(CGAffineTransform(translationX: 150, y: 46)))
  }()
  static let markBounds: CGRect = mark.boundingRect
  /// `transform-origin: 40% 70%` of the mark, as a fraction of the visible band.
  static let markAnchor = UnitPoint(
    x: (markBounds.minX + markBounds.width * 0.4) / viewBox.width,
    y: (markBounds.minY + markBounds.height * 0.7 - top) / visibleHeight)
}

/// A viewBox path drawn into a rect: scaled by width, the visible band lifted.
struct ForgePathShape: Shape {
  let path: Path
  func path(in rect: CGRect) -> Path {
    let s = rect.width / ForgeGeometry.viewBox.width
    return path.applying(CGAffineTransform(translationX: 0, y: -ForgeGeometry.top).concatenating(CGAffineTransform(scaleX: s, y: s)))
  }
}

// MARK: - The view

/// The crest of the door. `play` runs the show once from appearance; false
/// rests on the logo immediately. `onHandoff` fires when the door may rise.
struct ForgeView: View {
  let play: Bool
  let onHandoff: () -> Void
  @State private var began: Date? = nil
  @State private var finished = false

  var body: some View {
    if play && !finished {
      TimelineView(.animation(paused: finished)) { ctx in
        ForgeFrame(t: began.map { ctx.date.timeIntervalSince($0) } ?? 0)
      }
      .task {
        began = Date()
        try? await Task.sleep(for: .seconds(ForgeTimeline.handoff))
        if Task.isCancelled { return }
        onHandoff()
        try? await Task.sleep(for: .seconds(ForgeTimeline.end - ForgeTimeline.handoff))
        finished = true
      }
      .accessibilityHidden(true)
    } else {
      ForgeFrame(t: ForgeTimeline.rest)
        .onAppear { if !play { onHandoff() } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cup Season")
    }
  }
}

/// One frame of the Forge at time `t`. Pure: the same `t` always draws the
/// same picture, and `t ≥ ForgeTimeline.end` is the rest frame.
struct ForgeFrame: View {
  @Environment(\.cs) private var cs
  let t: Double
  /// `.ob-crest{width:min(64vw,300px)}` — the phone sits at 260.
  private let width: CGFloat = 260
  private var s: CGFloat { width / ForgeGeometry.viewBox.width }
  private var height: CGFloat { ForgeGeometry.visibleHeight * s }

  var body: some View {
    let markP = ForgeTimeline.progress(t, ForgeTimeline.mark, ForgeTimeline.roll)
    VStack(spacing: 0) {
      canvas.frame(width: width, height: height)
      wordmark.padding(.top, 2)
      fuse.padding(.top, 12)
      VStack(spacing: 2) {
        Text("Rally your crew. Post real rounds.").font(CSFont.sentence).foregroundStyle(cs.mut)
        Text("Take the cup.").font(CSFont.sentenceBold).italic().foregroundStyle(cs.ink)
      }
      .multilineTextAlignment(.center)
      .padding(.top, 14)
      .opacity(markP)
      .offset(y: 8 * (1 - markP))
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: the canvas — ambient, tracers, sparks, the mark

  private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: (y - ForgeGeometry.top) * s) }

  private var canvas: some View {
    ZStack {
      ambient
      ForEach(0..<4, id: \.self) { i in tracer(i) }
      ForEach(0..<4, id: \.self) { i in spark(i) }
      mark
    }
  }

  /// `.ob-amb`: the ember floor under the cup — the radial and three rings.
  private var ambient: some View {
    let o = ForgeTimeline.progress(t, ForgeTimeline.ambientIn) * (1 - ForgeTimeline.progress(t, ForgeTimeline.ambientGone))
    return ZStack {
      Ellipse()
        .fill(RadialGradient(colors: [cs.hot.opacity(0.26), cs.hot.opacity(0.08), cs.hot.opacity(0)],
                             center: .center, startRadius: 0, endRadius: 150 * s))
        .frame(width: 300 * s, height: 88 * s)
        .position(pt(230, 238))
      ring(rx: 118, ry: 32, y: 236, opacity: 0.10)
      ring(rx: 78, ry: 22, y: 233, opacity: 0.18)
      ring(rx: 44, ry: 13, y: 230, opacity: 0.30)
    }
    .opacity(o)
  }

  private func ring(rx: CGFloat, ry: CGFloat, y: CGFloat, opacity: Double) -> some View {
    Ellipse().stroke(cs.hot.opacity(opacity), lineWidth: 1.5 * s)
      .frame(width: rx * 2 * s, height: ry * 2 * s)
      .position(pt(230, y))
  }

  private var heat: [Color] { [cs.warm, cs.hot, cs.fire, cs.ink] }

  /// `.obtr`: draw on `csDraw`, leave on `csGone`. Width 2.6, round caps, .85.
  private func tracer(_ i: Int) -> some View {
    let draw = ForgeTimeline.progress(t, ForgeTimeline.tracerDraw[i])
    let gone = ForgeTimeline.progress(t, ForgeTimeline.tracerGone[i])
    return ForgePathShape(path: SVGPath.path(ForgeGeometry.tracers[i]))
      .trim(from: 0, to: draw)
      .stroke(heat[i], style: StrokeStyle(lineWidth: 2.6 * s, lineCap: .round))
      .opacity(0.85 * (1 - gone))
  }

  /// `.obspark`: a one-shot echo at the cup per landing — warm, hot, fire, ink.
  private func spark(_ i: Int) -> some View {
    let cue = ForgeTimeline.sparks[i]
    let p = ForgeTimeline.progress(t, cue, ForgeTimeline.easeOut)
    let live = t >= cue.start && t < cue.end
    let o = live ? (p < 0.22 ? p / 0.22 * 0.95 : 0.95 * (1 - (p - 0.22) / 0.78)) : 0
    return Ellipse().stroke(heat[i], lineWidth: 1.5 * s)
      .frame(width: 24 * s, height: 9 * s)
      .scaleEffect(0.45 + 1.45 * p)
      .opacity(o)
      .position(pt(230, 226))
  }

  /// `.ob-mark` on `csForge`: opacity 0→1 by 60%, scale .94 → 1.015 → 1,
  /// around 40%/70% of its own box. Base state VISIBLE: at rest this IS the door.
  private var mark: some View {
    let p = ForgeTimeline.progress(t, ForgeTimeline.mark, ForgeTimeline.roll)
    let o = min(1, p / 0.6)
    let scale: CGFloat = p < 0.6 ? 0.94 + 0.075 * (p / 0.6) : 1.015 - 0.015 * ((p - 0.6) / 0.4)
    return ForgePathShape(path: ForgeGeometry.mark)
      .fill(cs.brand)
      .scaleEffect(scale, anchor: ForgeGeometry.markAnchor)
      .opacity(o)
  }

  // MARK: the wordmark — `obSear`, letter by letter

  private static let glyphs: [Character] = Array("Cup Season").filter { $0 != " " }

  private var wordmark: some View {
    HStack(spacing: 1.5) {
      ForEach(Array(Self.glyphs.enumerated()), id: \.offset) { i, ch in
        letter(String(ch), cue: ForgeTimeline.letters[i])
        if i == 2 { Spacer().frame(width: 12) }   // "Cup" · "Season"
      }
    }
  }

  /// white-hot with an ember halo → ember → ink, scale 1.35 → 1. Tokens only:
  /// `fire` stands in for the web's white-hot, `hot` for its ember, `ink` rests.
  private func letter(_ ch: String, cue: ForgeTimeline.Cue) -> some View {
    let p = ForgeTimeline.progress(t, cue)
    let o = min(1, p / 0.25)
    let fireLayer = p < 0.25 ? 1.0 : max(0, 1 - (p - 0.25) / 0.35)
    let hotLayer = p < 0.6 ? 1.0 : max(0, 1 - (p - 0.6) / 0.4)
    let halo = 1 - p
    return ZStack {
      Text(ch).foregroundStyle(cs.ink)
      Text(ch).foregroundStyle(cs.hot).opacity(hotLayer)
      Text(ch).foregroundStyle(cs.fire).opacity(fireLayer)
    }
    .font(CSFont.wordmark)
    .blur(radius: 3 * (1 - o))
    .shadow(color: cs.brand.opacity(0.85 * halo), radius: 9 * halo)
    .scaleEffect(1 + 0.35 * (1 - p))
    .opacity(o)
  }

  // MARK: the fuse — `obRule` + `obFuse`

  private var fuse: some View {
    let p = ForgeTimeline.progress(t, ForgeTimeline.fuse, ForgeTimeline.easeOut)
    let live = t >= ForgeTimeline.fuse.start && t < ForgeTimeline.fuse.end
    let dot = live ? (p < 0.06 ? p / 0.06 : p > 0.88 ? (1 - p) / 0.12 : 1) : 0
    return ZStack(alignment: .leading) {
      Rectangle()
        .fill(LinearGradient(stops: [
          .init(color: cs.hot.opacity(0), location: 0), .init(color: cs.hot, location: 0.18),
          .init(color: cs.hot, location: 0.82), .init(color: cs.hot.opacity(0), location: 1),
        ], startPoint: .leading, endPoint: .trailing))
        .frame(height: 2)
        .scaleEffect(x: max(0.001, p), y: 1, anchor: .leading)
        .opacity(p > 0 ? 1 : 0)   // an unlit fuse draws nothing, not a sliver
      Circle().fill(cs.fire).frame(width: 8, height: 8)
        .shadow(color: cs.fire.opacity(0.8), radius: 6)
        .offset(x: width * p - 4)
        .opacity(dot)
    }
    .frame(width: width, height: 8)
  }
}

// MARK: - Once per device

enum ForgeState {
  /// The web's key, verbatim: the ceremony has played on this device.
  static let key = "cs_forge"
  static func hasPlayed(_ defaults: UserDefaults = .standard) -> Bool { defaults.bool(forKey: key) }
  static func markPlayed(_ defaults: UserDefaults = .standard) { defaults.set(true, forKey: key) }

  /// Play now? Reduced motion rests immediately, always. Otherwise once per
  /// device — or on demand for a screenshot (`-cs_dev_forge`, DEBUG only).
  static func shouldPlay(reduceMotion: Bool, defaults: UserDefaults = .standard) -> Bool {
    if reduceMotion { return false }
    #if DEBUG
    if DoorDev.replayForge { return true }
    #endif
    return !hasPlayed(defaults)
  }
}
