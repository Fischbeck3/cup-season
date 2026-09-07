// Cup Season — the takeover band and the tally (UI_SYSTEM §11.3, D277).
//
// **THE CEREMONY HIERARCHY IS THE WRONG WAY UP IN THE SHIPPED PRODUCT AND THIS
// IS WHERE IT IS PUT BACK.** `SeasonCeremonyView` — the screen a golfer sees
// once, the night a season they played for four months ends — contains **zero
// animation calls and zero haptics**, while the settings accordion animates its
// disclosure. The audit scores it 4.9 and files it P0.
//
// §11.3: *the ceremony plate wipes from the rail, `display` lines arrive at a
// 60ms stagger, the final figure tallies, the medallion seals and it holds.
// This is the biggest motion in the product and it belongs to the biggest
// moment.*
//
// Three laws it keeps:
//   1 · **The rest frame is the finished state.** Under `reduceMotion` nothing
//       wipes, nothing staggers and nothing counts — the band arrives whole,
//       with every figure at its value. Never "the same animation, faster".
//   2 · **The ground is pinned.** A ceremony is `ceremony` in BOTH printings,
//       so the object a golfer screenshots is the same object in either theme.
//   3 · **One haptic, at the seal.** `.posted` — the thock — when the medallion
//       lands, and nothing on the way there. No haptic per line.

import SwiftUI

// MARK: - The tally

/// **A figure that counts to its value over 340ms and then stops.** The number
/// is the ceremony; there is no confetti.
///
/// It renders the FINAL value under reduced motion, in the first frame — the
/// accessibility floor is the finished state, and a golfer who has asked for
/// less motion still gets the score.
public struct CSTally: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let value: Double
  /// How the number is spelled — the producer's own formatter, never a
  /// `String(format:)` invented at the call site.
  let format: (Double) -> String
  let size: CSFigure.Size
  let metal: CSFigure.Metal
  let label: String?
  let over: CSRule.Ground
  let run: Bool

  @State private var shown: Double = 0

  public init(_ value: Double, format: @escaping (Double) -> String,
              size: CSFigure.Size, metal: CSFigure.Metal = .ink,
              label: String?, over: CSRule.Ground = .page, run: Bool = true) {
    self.value = value; self.format = format; self.size = size
    self.metal = metal; self.label = label; self.over = over; self.run = run
  }

  public var body: some View {
    CSFigure(format(reduceMotion ? value : shown), size: size, metal: metal, label: label, over: over)
      .accessibilityLabel([label, format(value)].compactMap { $0 }.joined(separator: ", "))
      .task(id: run) {
        guard run, !reduceMotion else { shown = value; return }
        let steps = 17                       // 340ms at 20ms a frame
        for i in 1...steps {
          try? await Task.sleep(for: .milliseconds(20))
          if Task.isCancelled { break }
          // eased out, so the last third of the count slows into the value
          let t = Double(i) / Double(steps)
          shown = value * (1 - pow(1 - t, 3))
        }
        shown = value
      }
  }
}

// MARK: - The takeover band

/// **The takeover's figure tallies, so it carries its own formatter** — the
/// producer's spelling of the number at every frame of the count, never a
/// `String(format:)` invented in the component.
///
/// **It is hoisted OUT of `CSTakeover`**, which is generic over its content: a
/// type nested in a generic cannot be named in a type position without its
/// argument, so `CSTakeover.Figure` compiles at a call site and not in a test
/// or a stored property. Wave 2 learned this on `CSCredentialGolfer` and Wave
/// 5 on `CSLeafRule`; this is the third time and the note stays.
public struct CSTakeoverFigure {
  public let value: Double
  public let format: (Double) -> String
  public let label: String
  public let earned: Bool
  public init(value: Double, format: @escaping (Double) -> String, label: String, earned: Bool = true) {
    self.value = value; self.format = format; self.label = label; self.earned = earned
  }
}

/// **The takeover** — a full-bleed ceremony field carrying an agate eyebrow,
/// one to three `display` lines, an optional figure that tallies, and the
/// golfer's medallion sealing last.
///
/// It is a BAND, not a card: radius 0, full bleed, no border, and the page it
/// sits on scrolls under it. What it replaces on the season ceremony is a
/// centred serif name, a `heroSmall` score in gold and three grey label lines
/// — a dialog, on the night a golfer won something.
public struct CSTakeover<Content: View>: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let eyebrow: String
  /// One to three lines in `display`, arriving at a 60ms stagger.
  let lines: [String]
  /// The one figure the moment is about. It tallies.
  let figure: CSTakeoverFigure?
  /// The golfer's mark, sealing last with the thock. nil = no seal.
  let marker: String?
  let content: Content

  @State private var arrived = 0        // how many lines have landed
  @State private var sealed = false

  public init(eyebrow: String, lines: [String], figure: CSTakeoverFigure? = nil, marker: String? = nil,
              @ViewBuilder content: () -> Content = { EmptyView() }) {
    self.eyebrow = eyebrow; self.lines = lines; self.figure = figure
    self.marker = marker; self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
      HStack(alignment: .top) {
        Text(eyebrow).csType(.agate, caps: true)
          .foregroundStyle(CSTokens.dark.ceremonyGold)
        Spacer(minLength: CSTokens.Space.s3)
        if let marker {
          CSMedallion(marker, size: 44)
            .scaleEffect(sealed || reduceMotion ? 1 : 0.92)
            .opacity(sealed || reduceMotion ? 1 : 0)
        }
      }
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
          Text(line).csType(.display)
            .foregroundStyle(CSTokens.dark.ceremonyInk)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(reduceMotion || i < arrived ? 1 : 0)
        }
      }
      if let f = figure {
        CSTally(f.value, format: f.format, size: .l,
                metal: f.earned ? .earned : .ink, label: f.label, over: .ceremony)
      }
      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, CSTokens.Space.gutter)
    .padding(.vertical, CSTokens.Space.s5)
    .background(CSTokens.dark.ceremony)
    .csCeremony()
    // the plate wipes from the leading edge — the rail's edge, generalised
    .mask(alignment: .leading) {
      Rectangle().scaleEffect(x: reduceMotion || arrived > 0 ? 1 : 0, anchor: .leading)
    }
    .csFeedback(.posted, trigger: sealed)
    .task {
      guard !reduceMotion else { arrived = lines.count; sealed = true; return }
      CSMotion.run(CSMotion.rise) { arrived = 1 }
      for i in 1..<max(1, lines.count) {
        try? await Task.sleep(for: .milliseconds(60))
        CSMotion.run(CSMotion.rise) { arrived = i + 1 }
      }
      try? await Task.sleep(for: .milliseconds(340))
      CSMotion.run(CSMotion.roll) { sealed = true }
    }
    .accessibilityElement(children: .contain)
  }
}
