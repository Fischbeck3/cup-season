// Cup Season — the budgets, counted on the thing they are about (D274,
// UI_SYSTEM §17). `LINT-08/15/16/17/18` are RENDER-TIME probes, not greps.
//
// WHY A GREP COUNTS THE WRONG THING IN BOTH DIRECTIONS, which is the whole
// argument for this file existing:
//
//   Home's agate lines come from `CSMasthead`, `CSStoryCard`, `CSFactStrip`
//   and `CSSectionHead` — one apiece. A per-file grep counts 1 four times and
//   passes while the screen carries fourteen.
//
//   The season page's two gold objects are the leader's rail (inside
//   `CSRankRail.swift`) and the pot (inside `CSFigure.swift`). A grep over
//   `SeasonPage.swift` sees ZERO gold on the surface that carries two.
//
//   And no grep can see a `CSPanel` inside a `CSStoryCard` inside a `CSPlate`,
//   because the nesting only exists once the three are composed.
//
// So the components increment a `PreferenceKey` as they render, and the root
// reads the total for the viewport it just drew. Under `#if DEBUG` a root can
// assert; the preview tests assert in CI.

import SwiftUI

/// What one viewport spent. Every field is a budget in `UI_SYSTEM`.
public struct CSBudget: Equatable, Sendable {
  /// §1.5 — at most **ten** tracked-caps agate lines. Sentence-case agate and
  /// the tab band do not increment.
  public var agateCapsLines = 0
  /// §1.5 — exactly **one** `display`. `displayS` is a different symbol.
  public var display = 0
  /// §2.4 — **one** gold object, counted by hue.
  public var goldObjects = 0
  /// §2.4 — at most **two** ember marks, counting every fill, rule, glyph, dot
  /// and word outside the tab band.
  public var emberMarks = 0
  /// §3.1 — **zero**. A panel, leaf or plate rendering inside another.
  public var nestedContainers = 0
  /// §17's own clause: `LINT-17` counts one gold object per viewport "**with
  /// the season's leader-rail-plus-pot pair whitelisted by name**". This is
  /// that whitelist, declared by the OBJECT rather than by a table somewhere
  /// else: a component that legitimately carries the second half of a
  /// documented pair says so here, and the budget subtracts it.
  ///
  /// There are exactly two, and both are written out at their call sites:
  /// the credential's gold slot beside its medallion (`UI_SYSTEM` §19(i) — the
  /// crest and the medallion are the same glyph at two scales), and the season
  /// page's leader rail beside the pot (§15.4 — gold appears exactly twice and
  /// the spec names the pair). Anything else that reaches for a second gold is
  /// the screen where gold stops meaning *earned*.
  public var goldPaired = 0

  public init() {}

  static func + (a: CSBudget, b: CSBudget) -> CSBudget {
    var s = CSBudget()
    s.agateCapsLines = a.agateCapsLines + b.agateCapsLines
    s.display = a.display + b.display
    s.goldObjects = a.goldObjects + b.goldObjects
    s.goldPaired = a.goldPaired + b.goldPaired
    s.emberMarks = a.emberMarks + b.emberMarks
    s.nestedContainers = a.nestedContainers + b.nestedContainers
    return s
  }

  /// The budget lines this viewport broke, in the words the lint uses. Empty
  /// is the pass.
  public var breaches: [String] {
    var out: [String] = []
    if agateCapsLines > 10 { out.append("LINT-15 · \(agateCapsLines) tracked-caps agate lines, budget 10") }
    if display > 1 { out.append("LINT-16 · \(display) display roles, budget 1") }
    if goldObjects - goldPaired > 1 {
      out.append("LINT-17 · \(goldObjects) gold objects\(goldPaired > 0 ? " (\(goldPaired) paired by name)" : ""), budget 1")
    }
    if emberMarks > 2 { out.append("LINT-18 · \(emberMarks) ember marks, budget 2") }
    if nestedContainers > 0 { out.append("LINT-08 · \(nestedContainers) container(s) inside a container") }
    return out
  }
}

/// The key every counted component writes to.
public struct CSBudgetProbe: PreferenceKey {
  public static let defaultValue = CSBudget()
  public static func reduce(value: inout CSBudget, nextValue: () -> CSBudget) {
    value = value + nextValue()
  }
}

/// One component's contribution. Cheap enough to sit on every `agate` line.
///
/// **`transformPreference`, NOT `preference`, and this file shipped the wrong
/// one for nine waves.** `View.preference(key:value:)` SETS the value for the
/// modified view — it discards whatever the subtree below it produced. So
/// every container that counted itself (`CSPanel`, `CSLeaf`, `CSPlate`, all
/// three of which end their chain with `.csBudget(nested:)`) was erasing the
/// budget of everything it held: a leaf carrying a gold rule and a display
/// reported an empty budget, and `LINT-08` — a container inside a container —
/// could never fire, because the outer container overwrote the inner one's
/// count with its own.
///
/// Nothing said so, because nothing read the total: every wave since 0b
/// reported "the counters are wired; nothing reads the total", and the moment
/// `BudgetProbeTests` read it the nesting test failed. `transformPreference`
/// ADDS to what came from below, which is what a budget means.
struct CSBudgetTick: ViewModifier {
  var display = 0
  var agateCaps = 0
  var gold = 0
  var goldPaired = 0
  var ember = 0
  var nested = 0
  func body(content: Content) -> some View {
    content.transformPreference(CSBudgetProbe.self) { value in
      value.display += display
      value.agateCapsLines += agateCaps
      value.goldObjects += gold
      value.goldPaired += goldPaired
      value.emberMarks += ember
      value.nestedContainers += nested
    }
  }
}

public extension View {
  /// Count this view against the viewport's budgets.
  ///
  /// **Public, because a SURFACE can spend a metal too.** Home's floor paints
  /// its own 2px `brand` rule under the one lit door — that is an ember mark
  /// on the viewport, and a budget that only counted the marks `CSDesign`
  /// happens to draw would report a screen carrying two as carrying one.
  ///
  /// `goldPaired` is §17's named whitelist — see `CSBudget.goldPaired`. Passing
  /// it is a claim that this object is one of the two documented pairs, and the
  /// claim is written out at the call site or it is not made.
  func csBudget(display: Int = 0, agateCaps: Int = 0, gold: Int = 0,
                goldPaired: Int = 0, ember: Int = 0, nested: Int = 0) -> some View {
    modifier(CSBudgetTick(display: display, agateCaps: agateCaps, gold: gold,
                          goldPaired: goldPaired, ember: ember, nested: nested))
  }
}

// MARK: - Nesting

/// True once a container (`CSPanel`, `CSLeaf`, `CSPlate`) is on the stack. A
/// second one reads it and increments `nestedContainers` — which is how
/// `LINT-08` sees a nesting that only exists after composition.
private struct CSInContainerKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
  var csInContainer: Bool {
    get { self[CSInContainerKey.self] }
    set { self[CSInContainerKey.self] = newValue }
  }
}

// MARK: - Reading the budget at a root

public extension View {
  /// Read the budget for everything drawn inside. A root calls this and, under
  /// DEBUG, says so out loud; the preview tests assert on it in CI.
  func csBudgetProbe(_ read: @escaping @Sendable (CSBudget) -> Void) -> some View {
    onPreferenceChange(CSBudgetProbe.self) { read($0) }
  }

  /// The DEBUG form: the surface names itself and every breach prints once.
  /// Never fails a build — a golfer's screen is not a test — but a screen that
  /// spends two `display` roles says so in the console the moment it is drawn.
  func csAssertBudget(_ surface: String) -> some View {
    #if DEBUG
    return csBudgetProbe { b in
      for line in b.breaches { print("CS BUDGET · \(surface) · \(line)") }
    }
    #else
    return self
    #endif
  }
}
