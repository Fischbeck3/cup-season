// Cup Season — a view hosted for real, and read back the way a finger and
// VoiceOver meet it (the ten program, 2026-09-28).
//
// `TertiaryTargetTests` measures one control's size; the course card and the
// calendar need more than a size. They need to know WHERE each hole column and
// each day landed, whether a horizontal scroller was needed, and what
// VoiceOver will read in what order. SwiftUI answers all three through the
// hosting view's accessibility tree — every element carries its label, its
// identifier and its frame in window coordinates — and through the
// `UIScrollView` a `ScrollView` is backed by. Both are read here off a real
// `UIWindow` after a real layout pass, at an explicit width, reading size and
// printing, so the geometry is the geometry a phone produces, not arithmetic
// about it.

import SwiftUI
import UIKit
import CSDesign
@testable import CupSeason

@MainActor
final class HostedLayout {
  struct Element {
    let label: String
    let identifier: String
    let frame: CGRect
    let traits: UIAccessibilityTraits
  }

  let window: UIWindow
  let host: UIHostingController<AnyView>

  /// **SwiftUI builds its accessibility tree only for a client that asks.** A
  /// unit-test process has no VoiceOver and no UI-automation session, so the
  /// hosting view reports ZERO elements until accessibility automation is
  /// switched on for the process — the same switch KIF and the snapshot
  /// libraries throw. It lives in the simulator's `libAccessibility`, is
  /// looked up at run time and affects this test process only; nothing here
  /// reaches the app's own code or a build that ships.
  private static let automation: Bool = {
    guard let lib = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
          let sym = dlsym(lib, "_AXSSetAutomationEnabled") else { return false }
    typealias SetEnabled = @convention(c) (Int32) -> Void
    unsafeBitCast(sym, to: SetEnabled.self)(1)
    // the switch propagates on a later turn of the run loop
    RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    return true
  }()

  /// `view`, `width` points wide, at `typeSize`, in the named printing, with
  /// the palette resolved the way the app resolves it (`csTheme`).
  init(_ view: some View, width: CGFloat, height: CGFloat = 1600,
       typeSize: DynamicTypeSize = .large, scheme: ColorScheme = .dark) {
    _ = Self.automation
    host = UIHostingController(rootView: AnyView(
      view
        .frame(width: width)
        .frame(maxHeight: .infinity, alignment: .top)
        .environment(\.dynamicTypeSize, typeSize)
        .environment(\.colorScheme, scheme)
        .csTheme()
    ))
    window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
    window.rootViewController = host
    window.isHidden = false
    host.view.frame = window.bounds
    settle()
  }

  /// A layout pass, then a few turns of the run loop so `ViewThatFits`, the
  /// scroll view's content size and the accessibility tree have all caught
  /// up with it.
  func settle() {
    for _ in 0..<6 {
      host.view.setNeedsLayout()
      host.view.layoutIfNeeded()
      RunLoop.main.run(until: Date().addingTimeInterval(0.02))
    }
  }

  func tearDown() { window.isHidden = true }

  // MARK: the accessibility tree

  /// Every accessibility ELEMENT under the hosting view, in the order
  /// VoiceOver would visit them.
  var elements: [Element] {
    var out: [Element] = []
    Self.walk(host.view, into: &out, depth: 0)
    return out
  }

  func elements(prefix: String) -> [Element] { elements.filter { $0.identifier.hasPrefix(prefix) } }
  func element(_ identifier: String) -> Element? { elements.first { $0.identifier == identifier } }

  /// SwiftUI's nodes answer `accessibilityIdentifier` without adopting the
  /// UIKit protocol that declares it, so it is asked for by name.
  private static func identifier(of node: NSObject) -> String {
    if let id = (node as? UIAccessibilityIdentification)?.accessibilityIdentifier, !id.isEmpty { return id }
    let sel = NSSelectorFromString("accessibilityIdentifier")
    guard node.responds(to: sel) else { return "" }
    return node.value(forKey: "accessibilityIdentifier") as? String ?? ""
  }

  private static func walk(_ node: NSObject, into out: inout [Element], depth: Int) {
    guard depth < 80 else { return }
    if node.isAccessibilityElement {
      out.append(Element(label: node.accessibilityLabel ?? "",
                         identifier: identifier(of: node),
                         frame: node.accessibilityFrame, traits: node.accessibilityTraits))
      return
    }
    var children: [NSObject] = []
    if let listed = node.accessibilityElements as? [NSObject], !listed.isEmpty {
      children = listed
    } else {
      let n = node.accessibilityElementCount()
      if n != NSNotFound, n > 0 {
        for i in 0..<n { if let e = node.accessibilityElement(at: i) as? NSObject { children.append(e) } }
      }
    }
    if children.isEmpty, let v = node as? UIView { children = v.subviews }
    for c in children { walk(c, into: &out, depth: depth + 1) }
  }

  // MARK: the scrollers

  /// Every horizontal scroller under the hosting view: a `UIScrollView` whose
  /// content is wider than itself.
  var horizontalScrollers: [UIScrollView] {
    var out: [UIScrollView] = []
    func walk(_ v: UIView) {
      if let s = v as? UIScrollView, s.contentSize.width > s.bounds.width + 0.5 { out.append(s) }
      v.subviews.forEach(walk)
    }
    walk(host.view)
    return out
  }

  /// A scroller's visible frame, in window coordinates.
  func visibleFrame(_ s: UIScrollView) -> CGRect { s.convert(s.bounds, to: window) }

  /// Scroll `s` to its far end (or back to its start) and let the tree update.
  func scroll(_ s: UIScrollView, toEnd: Bool) {
    let x = toEnd ? max(0, s.contentSize.width - s.bounds.width + s.adjustedContentInset.right) : -s.adjustedContentInset.left
    s.setContentOffset(CGPoint(x: x, y: s.contentOffset.y), animated: false)
    settle()
  }
}
