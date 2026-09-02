// Cup Season — the sky (D103b) and the strip (Y-10).
//
// A vertical band of the look's accent, ~22% at the very top fading to
// nothing by ~260pt, under the scroll content and behind the page header or
// the league hero; it ignores the top safe area so the tint runs to the
// status bar. Homebase = ember at 10%, so Fescue-only still has warmth at the
// top. Never on the door, ceremonies, settlement, share cards or the pot
// pane — those keep their own grounds. The sky never animates.
//
// The strip is the one thing here that moves: once the page has scrolled
// ~8pt, a band the height of the top safe area — status bar, or status bar
// plus the toolbar — CONTINUES the sky's own ramp on `bg0`, so the clock and
// the toolbar keep a ground while rows pass under them. It draws over the
// scroll, outside its clip, and adds nothing to layout: at rest it is
// invisible, and the page underneath measures exactly as it did before.
//
// "Invisible" is the whole specification, and it was not met until 2026-09-02.
// The strip used to fill FLAT accent at `skyStrength` — the ramp's top colour,
// held for the strip's full height — while the sky kept fading behind it, so
// its foot stepped against the band it is meant to continue (measured on the
// 17 Pro: a warm #211C13 strip against a #1C1A12 page), and a `CSHairline()`
// drew `line` — a GREEN — across that warm ground at y=61pt. Both are gone:
// the strip draws the sky's ramp, clipped, and nothing else.

import SwiftUI

public struct CSLookSky: View {
  @Environment(\.csLookAccent) private var la
  /// How far the ramp runs from the top of the screen. The strip reads the
  /// same number, so the two can never disagree about where the sky ends.
  public static let span: CGFloat = 260
  let height: CGFloat
  public init(height: CGFloat = CSLookSky.span) { self.height = height }

  /// The ramp itself, so the strip can draw THIS rather than sample its top
  /// colour. One definition; a stop added here reaches both by construction.
  static func ramp(_ la: CSLookAccent) -> LinearGradient {
    LinearGradient(colors: [la.accent.opacity(la.skyStrength), la.accent.opacity(0)],
                   startPoint: .top, endPoint: .bottom)
  }

  public var body: some View {
    Self.ramp(la)
      .frame(height: height)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .ignoresSafeArea(edges: .top)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }
}

public extension View {
  /// The screen's ground with the sky on it: `bg0`, then the band at the top,
  /// then the strip that appears once the page scrolls. Goes where
  /// `.background(cs.bg0)` went — on the scroll, under the content.
  ///
  /// Room at the foot for the floating tab bar is NOT applied here: it is
  /// applied once per tab shell (`MainTabView`, `csTabBarRoom`), so screens
  /// that paint their own ground — Card & settings, People, the board — get
  /// it too, and no screen can be inset twice.
  func csLookGround() -> some View { modifier(CSLookGround()) }
}

private struct CSLookGround: ViewModifier {
  @Environment(\.cs) private var cs
  @State private var scrolled = false

  func body(content: Content) -> some View {
    sensed(content)
      .background(alignment: .top) { CSLookSky() }
      .background(cs.bg0)
      .overlay(alignment: .top) { CSLookStrip(shown: scrolled) }
  }

  /// One Bool off the scroll geometry — "past the threshold or not" — so the
  /// action runs twice per crossing, never once per point. `contentOffset.y`
  /// rests at minus the top inset, so offset + inset is the distance scrolled
  /// from rest.
  ///
  /// **The strip DOES draw** — the note below is about the 17.0 FLOOR alone,
  /// not a claim that it never renders. Checked against the review build's
  /// screenshots (2026-09-02): an iPhone 17 Pro simulator is iOS 18+, so
  /// `#available` takes the first branch and the strip is on. The reviewer who
  /// read "iOS 17 gets no strip" as "this cannot work" read a floor as a
  /// verdict; both statements are true at once.
  ///
  /// **iOS 17 gets no strip, on all four look-ground screens.** The floor is
  /// 17 (`Package.swift`, `project.yml:15`, CLAUDE.md "The phone") and
  /// `onScrollGeometryChange` is 18+. There is no drop-in fallback from HERE:
  /// this modifier is applied TO the `ScrollView`, and a `GeometryReader` in
  /// its `.background` sits behind the scroll's frame, not inside its content,
  /// so it never moves. Every iOS 17 technique needs a reader INSIDE the
  /// scrolled content — which is the per-screen change Y-10 exists to avoid —
  /// or UIKit introspection. Until one of those is ruled on, iOS 17 keeps
  /// exactly the ground D103b gave it: the sky, and no strip.
  @ViewBuilder private func sensed(_ content: Content) -> some View {
    if #available(iOS 18, *) {
      content.onScrollGeometryChange(for: Bool.self) { g in
        g.contentOffset.y + g.contentInsets.top > CSLookStrip.threshold
      } action: { _, past in
        withAnimation(CSMotion.rise) { scrolled = past }
      }
    } else {
      content
    }
  }
}

/// The band under the top chrome: the sky's own ramp over `bg0`, cut to the
/// height of the top safe-area inset. It is the sky's construction verbatim —
/// the same gradient, at the same length, anchored to the same screen top —
/// so the ramp runs through the strip's foot without a step. Nothing else is
/// on it: no hairline, no second tone. What the strip adds is OPACITY, not
/// colour, and that is all it may ever add.
private struct CSLookStrip: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let shown: Bool

  /// How far the page moves before the strip shows.
  static let threshold: CGFloat = 8

  var body: some View {
    GeometryReader { g in
      ZStack(alignment: .top) {
        cs.bg0
        // the full ramp, drawn from the same top the sky draws from, then cut
        // to the inset — never a flat sample of its first colour
        CSLookSky.ramp(la).frame(height: CSLookSky.span)
      }
      .frame(height: g.safeAreaInsets.top, alignment: .top)
      .clipped()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .ignoresSafeArea(edges: .top)
    }
    .opacity(shown ? 1 : 0)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}
