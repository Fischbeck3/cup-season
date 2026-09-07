// Cup Season — the ground under a page, and the strip under the clock
// (D103b, Y-10, closed by D270 / D278).
//
// THE SKY IS GONE. This file used to paint a vertical band of the look's
// accent — 22% at the very top fading to nothing by 260pt — under every
// look-ground screen. `D270` named it in the "still owed" list on the day the
// palette was re-printed, and Waves 0a, 0b and 8 each deferred it because
// removing a wash changes six surfaces and none of those waves owned all six.
// Wave 9 owns the sweep, so it goes here.
//
// The argument is `UI_SYSTEM` §2 and `BRIEF` §4: depth comes from GROUND and
// from the two objects a screen is about, never from atmosphere sprayed over a
// page. A 22% tint over the top third is the same move as the border the card
// lost — a cost paid on every screen for a signal on none of them, and on the
// season page it put a coloured cast behind a masthead whose whole job is to
// be the one loud thing at the top.
//
// WHAT SURVIVES IS THE STRIP, and it earns its keep: once the page has
// scrolled ~8pt, a band the height of the top safe area paints `bg0` so the
// clock and the toolbar keep a ground while rows pass under them. It draws
// over the scroll, outside its clip, and adds nothing to layout. At rest it is
// invisible and the page underneath measures exactly as it did before.
//
// iOS 17 still gets no strip — `onScrollGeometryChange` is 18+ and there is no
// drop-in fallback from a modifier applied TO the ScrollView. That floor is
// unchanged by this wave.

import SwiftUI

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
        CSMotion.run(CSMotion.rise) { scrolled = past }
      }
    } else {
      content
    }
  }
}

/// The band under the top chrome: `bg0`, cut to the height of the top
/// safe-area inset. With the sky deleted it is the page's own ground and
/// nothing else — no hairline, no ramp, no second tone. What the strip adds is
/// OPACITY, not colour, and that is all it may ever add.
private struct CSLookStrip: View {
  @Environment(\.cs) private var cs
  let shown: Bool

  /// How far the page moves before the strip shows.
  static let threshold: CGFloat = 8

  var body: some View {
    GeometryReader { g in
      cs.bg0
        .frame(height: g.safeAreaInsets.top, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }
    .opacity(shown ? 1 : 0)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}
