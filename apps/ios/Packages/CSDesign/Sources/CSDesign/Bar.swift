// Cup Season — THE BAR, and the two things a system bar does to this design
// (the repair pass, DF-07 / DF-09 / DF-14).
//
// iOS 26 wraps every toolbar button in its own capsule. On a product whose
// first non-negotiable is that a container needs a job, that means half the
// back and dismiss controls arrive inside a `bg2` disc — while the two
// surfaces that hide their navigation bar and draw their own chevron do not.
// One product, two back buttons, two dismiss chromes, and no artboard draws
// either disc.
//
// The second thing is quieter and worse. A surface that HIDES its bar has no
// `toolbarColorScheme` to set, so the app-level `preferredColorScheme` decides
// the status bar — and on the two surfaces whose top 60pt is a pinned
// `ceremony` plate, the LIGHT printing put the dark glyph set on near-black:
// the clock, the cellular dots and the battery, unreadable, at the top of two
// flagship pages. The plate knows it is dark in both printings, so it can
// declare it — and it can only declare it while a bar exists to declare it
// ON. So the bar is kept and made INVISIBLE rather than hidden.
//
// And the third: content scrolls under the clock with nothing between them, so
// at some scroll position on every page a figure or a name renders under the
// time. On the You page it lands on the form row — five grosses on one rule,
// the object the design is proudest of.

import SwiftUI

public extension View {

  /// **A pushed surface that carries its own head.**
  ///
  /// No title (the page names itself), no bar background, no system back
  /// button and therefore no capsule. Pair it with `csBack` for the chevron.
  ///
  /// - Parameter overDarkPlate: the top of this surface is a pinned dark plate
  ///   in BOTH printings, so the status bar takes the light glyph set in both.
  ///   This is the whole reason the bar is kept and emptied rather than
  ///   hidden: `toolbarColorScheme` needs a bar.
  func csBareBar(overDarkPlate: Bool = false) -> some View {
    self
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      // **THE BAR IS HIDDEN, NOT RE-STYLED, AND THAT IS MEASURED.** The first
      // attempt kept the bar, emptied its background and hung a `.plain`
      // button in it — and iOS 26 painted its capsule anyway. A toolbar item
      // cannot be talked out of its glass on this system, so the only way to
      // have ONE back button in the product is for the page to draw it:
      // `CSBackChevron`, in the content, where it scrolls with the head the
      // way the course page's has since Wave 4.
      .toolbar(.hidden, for: .navigationBar)
  }

  /// **THE PLATE BLEEDS IN THE DARK PRINTING AND STOPS AT THE CLOCK IN THE
  /// LIGHT ONE**, and this is a deviation from the artboard, stated.
  ///
  /// A `ceremony` plate is pinned near-black in BOTH printings, so in the
  /// light printing the system's DARK status glyph set — the clock, the
  /// cellular dots, the battery — renders dark-on-dark and is effectively
  /// unreadable over the top 60pt of two flagship surfaces.
  ///
  /// Three routes were tried and measured. `toolbarColorScheme(.dark)` does
  /// not reach the status bar on a bar with no background. A surface-level
  /// `preferredColorScheme(.dark)` does not win either: the App applies
  /// `preferredColorScheme` at the scene root and the root's value is the one
  /// the hosting controller reads. Driving `UIStatusBarStyle` per surface
  /// means an observable at the root plus a UIKit read of the system scheme
  /// for the *Match device* case — a feedback loop between the override and
  /// the palette that resolves from it, to buy 60pt of one printing.
  ///
  /// So the plate stops at the safe area in the light printing and the clock
  /// reads dark on paper, the way it does on every other light surface in the
  /// product. `course-light.png` draws it bleeding with light glyphs — but a
  /// mockup draws its own status bar and the app does not get to (§19 is the
  /// list of exactly this class of artboard imperfection). Dark, which is the
  /// app's home mood and the printing every course artboard is cut in, is
  /// unchanged and still bleeds.
  func csPlateBleedsInDark(_ paper: Color) -> some View {
    modifier(CSDarkPlateTop(paper: paper))
  }

  /// **A `bg0` cap over the status bar**, for a scrolling surface whose top is
  /// the page's own ground rather than a full-bleed plate.
  ///
  /// A zero-height view that ignores the top safe area fills exactly that
  /// area, so the cap is the bar's height on every device without anybody
  /// measuring one. Never apply it to a surface that runs a photograph or a
  /// contour under the clock — there the scrim is the treatment (§10.3).
  func csStatusCap(_ ground: Color) -> some View {
    modifier(CSStatusCap(ground: ground))
  }
}

/// **The one back control in the product**: the family's own chevron,
/// flipped, at a 44pt target, with no field behind it.
///
/// `CSGlyph(.chevron)` points forward, so the back chevron is the same drawing
/// mirrored — one path in the family rather than a second one that has to
/// match it. It is placed in the PAGE, at the head of its own content, so it
/// scrolls with the head; a toolbar item cannot be talked out of iOS 26's
/// glass capsule, which is the disc that put two back buttons in one product.
public struct CSBackChevron: View {
  @Environment(\.cs) private var cs
  let tint: Color?
  let action: () -> Void
  public init(tint: Color? = nil, action: @escaping () -> Void) {
    self.tint = tint; self.action = action
  }
  public var body: some View {
    Button(action: action) {
      CSGlyph(.chevron, size: .tab)
        .scaleEffect(x: -1)
        .foregroundStyle(tint ?? cs.ink)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .padding(.leading, CSTokens.Space.gutter - 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityLabel("Back")
  }
}


/// See `csPlateBleedsInDark`.
struct CSDarkPlateTop: ViewModifier {
  @Environment(\.colorScheme) private var scheme
  let paper: Color
  /// The plate bleeds under the clock only where its own near-black is the
  /// page's mood too.
  var bleeds: Bool { scheme != .light }
  func body(content: Content) -> some View {
    content
      .ignoresSafeArea(edges: bleeds ? .top : [])
      .overlay(alignment: .top) {
        if !bleeds {
          paper.frame(height: 0).ignoresSafeArea(edges: .top).allowsHitTesting(false)
        }
      }
  }
}




/// See `csStatusCap`.
///
/// **The cap is OFFSET above its own bounds, not grown by `ignoresSafeArea`.**
/// Two constructions were measured first and neither drew anything: a
/// zero-height view is optimised away before the safe area can grow it, and a
/// one-point one inside an overlay never grows either, because the parent has
/// already claimed the area and a `GeometryReader` in there reports an inset of
/// zero. An overlay child offset above its parent's top edge is not clipped, so
/// this is the construction that actually paints — and it paints the page's own
/// ground, at the height the window says the status bar is.
struct CSStatusCap: ViewModifier {
  let ground: Color
  private var topInset: CGFloat {
    #if canImport(UIKit)
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.first?.windows.first(where: \.isKeyWindow)?.safeAreaInsets.top
        ?? scenes.first?.windows.first?.safeAreaInsets.top ?? 0
    #else
    return 0
    #endif
  }
  func body(content: Content) -> some View {
    content.overlay(alignment: .top) {
      ground
        .frame(maxWidth: .infinity)
        .frame(height: topInset)
        .offset(y: -topInset)
        .allowsHitTesting(false)
    }
  }
}
