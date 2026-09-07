// Cup Season — the responsive model (UI_SYSTEM §16.3, D279, IOS-054).
//
// THE AUDIT'S FINDING, IN ONE LINE: `ViewThatFits` appeared **zero** times in
// the product and `horizontalSizeClass` twice, both meaning "is the phone
// sideways" — so the SE (375pt), the 17 Pro (402) and the Max (440) rendered
// the identical view tree and every reflow in this design was a sentence in a
// document rather than a branch in the code.
//
// THE MODEL TO COPY ALREADY EXISTED AND IT IS `MeStripLayout`: it reflows on
// the **measured advance of its own characters at the size the golfer is
// actually reading**, not on a device breakpoint. This file generalises that
// to the whole product, in three pieces:
//
//   `CSAdvance`     what a string ACTUALLY measures in a role, in the real
//                   face, at the size the environment is reading. Plex Mono's
//                   0.6 em is a special case of it; the board face is not
//                   monospaced and cannot be guessed at all.
//   `CSClauseLine`  the `·`-separated agate line (§16.3 row 2), which sets on
//                   one line while it fits and **breaks on its separators**
//                   when it does not. It uses `ViewThatFits`, so the decision
//                   is made against the real proposal at the real size and
//                   there is no arithmetic to get wrong.
//   `csPage`        the page's own measure, injected as `\.csMeasure` so a
//                   component's fixed columns are derived from the width it is
//                   being read at — plus the clamp that stops one over-wide
//                   row shearing every block on the page.
//
// WHY THE CLAMP IS NOT BELT-AND-BRACES. A vertical `ScrollView` sizes its
// content box to its widest child and CENTRES a box wider than itself, so ONE
// row that refuses to shrink moves the WHOLE page — the gutter goes, the
// masthead runs off the left edge and the figures run off the right. Wave 5
// met it on the season page at AX3, clamped six candidates and could not close
// it; Wave 9's own probe lesson applies exactly — *a mechanism nothing reads is
// a mechanism nobody can know is broken*. `csPage` measures the content's
// natural width BEFORE clamping it, so under DEBUG the breach names itself
// with the page it happened on and the width it wanted.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - The measured advance

/// What a string measures, in a role, at the size being read.
///
/// This is `MeStripLayout.unit(pointSize:tracking:)` with the monospace
/// assumption removed. The strip could multiply a character count by 0.6 em
/// because it is set entirely in Plex Mono; the board face, SF Pro and New York
/// all have real per-glyph advances, so a name column, an eyebrow or a cut
/// label has to be measured rather than estimated.
public enum CSAdvance {

  /// The rendered width of `s` set in `role` at the size `d` is read at,
  /// including the role's tracking (a RATIO of the rendered size — §1.2) and
  /// the role's case law.
  ///
  /// Returns 0 for an empty string. On a platform with no UIKit it falls back
  /// to the point size × 0.6, which is the mono figure and is only ever used
  /// by a test host.
  public static func width(_ s: String, _ role: CSType.Role,
                           _ d: DynamicTypeSize = .large, caps: Bool? = nil) -> CGFloat {
    guard !s.isEmpty else { return 0 }
    let pt = CSType.renderedSize(role, d)
    let text = (caps ?? (role.textCase == .uppercase)) ? s.uppercased() : s
    #if canImport(UIKit)
    guard let font = uiFont(role, pt) else { return CGFloat(text.count) * pt * 0.6 }
    let kern = pt * CGFloat(role.track)
    let size = (text as NSString).size(withAttributes: [.font: font, .kern: kern])
    return size.width
    #else
    return CGFloat(text.count) * (pt * 0.6 + pt * CGFloat(role.track))
    #endif
  }

  /// The widest unbreakable run — the longest word. A column has to hold this
  /// or the word breaks mid-glyph; `MeStripLayout.widestWord` is the same idea
  /// and `CANYON` is still the case that proves it.
  public static func widestWord(_ s: String, _ role: CSType.Role,
                                _ d: DynamicTypeSize = .large, caps: Bool? = nil) -> CGFloat {
    s.split(whereSeparator: { $0 == " " || $0 == "\u{00A0}" })
      .map { width(String($0), role, d, caps: caps) }
      .max() ?? 0
  }

  /// Does the whole string set on ONE line in `measure` points?
  public static func fits(_ s: String, in measure: CGFloat, _ role: CSType.Role,
                          _ d: DynamicTypeSize = .large, caps: Bool? = nil) -> Bool {
    measure > 0 && width(s, role, d, caps: caps) <= measure
  }

  #if canImport(UIKit)
  static func uiFont(_ role: CSType.Role, _ pt: CGFloat) -> UIFont? {
    switch role.family {
    case .board:
      let face = (role == .name || role == .nameS || role == .social
                  || role == .agate || role == .agateS) ? CSType.boardSemi : CSType.boardBold
      if role.tabular, let tab = CSType.tabularUIFont(face, pt) { return tab }
      return UIFont(name: face, size: pt)
    case .mono:
      return UIFont(name: role == .columnS ? CSType.monoRegular : CSType.monoMedium, size: pt)
    case .sans:
      return UIFont.systemFont(ofSize: pt)
    case .serif:
      let base = UIFont.systemFont(ofSize: pt, weight: role == .lead ? .bold : .regular)
      guard let d = base.fontDescriptor.withDesign(.serif) else { return base }
      return UIFont(descriptor: d, size: pt)
    }
  }
  #endif
}

// MARK: - The page's measure

private struct CSMeasureKey: EnvironmentKey {
  /// 402 — the 17 Pro, and the width every artboard in this design was drawn
  /// at. A component that reads the measure before a page has injected one is
  /// reading the design's own default, never a device's.
  static let defaultValue: CGFloat = 402
}

public extension EnvironmentValues {
  /// **The width the page is actually being read at**, injected by `csPage`.
  /// A fixed column derived from this is a column that fits an SE; a fixed
  /// column derived from a constant is 62% of an SE spent before a character
  /// of a name (§16.3's 375pt paragraph).
  var csMeasure: CGFloat {
    get { self[CSMeasureKey.self] }
    set { self[CSMeasureKey.self] = newValue }
  }
}

/// The three measures the product is read at, named so a component can say
/// which one it is reasoning about without hard-coding a device.
public enum CSMeasureClass: Sendable {
  /// ≤ 380 — the SE and every phone that shares its width.
  case narrow
  /// 381–420 — the 17 Pro, and what the mockups were drawn at.
  case standard
  /// > 420 — the Max.
  case wide

  public init(_ measure: CGFloat) {
    self = measure <= 380 ? .narrow : (measure > 420 ? .wide : .standard)
  }
}

private struct CSNaturalWidthKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

/// **A scrolling page, clamped to its own container and told how wide it is.**
///
/// Three things, and each is load-bearing:
///
///  1. the content's NATURAL width is measured first, so a child that refuses
///     to shrink is caught rather than hidden;
///  2. the content is then clamped to the container's width, so one such child
///     can never move the other blocks — a page whose gutter is gone is a page
///     whose one law is broken, and it happened on Home at AX5;
///  3. `\.csMeasure` is injected, so `CSSlatMetrics` and anything else with a
///     fixed column derives it from the width being read rather than from 402.
///
/// Under DEBUG a breach logs the page's name and the width the content wanted.
/// It is deliberately a log and not a `precondition`: the clamp already keeps
/// the page correct, and a crash on a golfer's phone because a name is long is
/// a worse product than a name that clips.
public struct CSPage: ViewModifier {
  let name: String
  @State private var natural: CGFloat = 0
  @State private var container: CGFloat = 0

  public init(_ name: String) { self.name = name }

  public func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { g in
          Color.clear.preference(key: CSNaturalWidthKey.self, value: g.size.width)
        }
      )
      .containerRelativeFrame(.horizontal, alignment: .leading)
      .background(
        GeometryReader { g in
          Color.clear.onAppear { container = g.size.width }
            .onChange(of: g.size.width) { _, w in container = w }
        }
      )
      .environment(\.csMeasure, container > 0 ? container : CSMeasureKey.defaultValue)
      .onPreferenceChange(CSNaturalWidthKey.self) { w in natural = w }
      .onChange(of: natural) { _, w in report(w) }
      .onChange(of: container) { _, _ in report(natural) }
  }

  private func report(_ w: CGFloat) {
    #if DEBUG
    guard container > 0, w > container + 0.5 else { return }
    NSLog("CS-SHEAR %@ wants %.1f in %.1f — one row will not shrink (UI_SYSTEM §16.3)",
          name, w, container)
    #endif
  }
}

public extension View {
  /// Apply to the CONTENT of a vertical `ScrollView`, once per page.
  func csPage(_ name: String) -> some View { modifier(CSPage(name)) }
}

// MARK: - The agate line that breaks rather than truncates

/// **A `·`-separated agate line, set on one line while it fits and broken on
/// its separators when it does not** (§16.3, the `agate` row).
///
/// The shipped behaviour was a tail ellipsis, which on an SE turned Home's own
/// eyebrow into `MON · GOLD CANYON — …` at the DEFAULT reading size: a course
/// a golfer is playing today, cut off, on the front page. A name may take the
/// tail-ellipsis policy (§9.1) because a name is one token and there is nothing
/// else to do with it. **A line of clauses is not one token.**
///
/// The decision is `ViewThatFits`, so it is made against the real proposal with
/// the real characters at the real size — the audit's zero-uses finding, and
/// the reason there is no arithmetic here to be wrong about.
public struct CSClauseLine: View {
  @Environment(\.cs) private var cs
  let clauses: [String]
  let role: CSType.Role
  let caps: Bool
  let colour: Color?
  /// The lead clause takes a different colour on one surface (Home's eyebrow
  /// paints the whole line `brand`); nil means the caller has already set one.
  public init(_ clauses: [String], role: CSType.Role = .agate,
              caps: Bool = true, colour: Color? = nil) {
    self.clauses = clauses.filter { !$0.isEmpty }
    self.role = role; self.caps = caps; self.colour = colour
  }

  /// A pre-joined line, split back into its clauses. The producers in this
  /// product write `A · B · C` as one string, and re-writing forty of them to
  /// return an array would be a producer change in a layout wave.
  public init(_ line: String, role: CSType.Role = .agate,
              caps: Bool = true, colour: Color? = nil) {
    self.init(line.components(separatedBy: " · "), role: role, caps: caps, colour: colour)
  }

  public var body: some View {
    if clauses.isEmpty {
      EmptyView()
    } else if clauses.count == 1 {
      // one clause has nothing to break on; it wraps like any other line
      Text(clauses[0]).csType(role, caps: caps).foregroundStyle(colour ?? cs.mut)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(spoken)
    } else {
      ViewThatFits(in: .horizontal) {
        oneLine
        stacked
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(spoken)
    }
  }

  private var oneLine: some View {
    Text(clauses.joined(separator: " · "))
      .csType(role, caps: caps)
      .foregroundStyle(colour ?? cs.mut)
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
  }

  /// **The separators go with the break.** A stacked line still reads as one
  /// line of clauses because each clause keeps its own row; printing a hanging
  /// `·` at the end of a row would be a separator separating nothing.
  private var stacked: some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(Array(clauses.enumerated()), id: \.offset) { _, c in
        Text(c).csType(role, caps: caps).foregroundStyle(colour ?? cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  /// VoiceOver reads the clauses as one sentence either way — the layout is
  /// not a fact about the content.
  private var spoken: String { clauses.joined(separator: ", ") }
}
