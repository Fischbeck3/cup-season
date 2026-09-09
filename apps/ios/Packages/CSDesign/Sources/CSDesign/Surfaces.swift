// Cup Season — how surfaces sit (IOS-019, re-cut by D266 / D278).
//
// Depth from GROUND, not from borders, and after Wave 9 not from atmosphere
// either. What this file used to carry — the radial `CSWash`, the `CSHero`
// card that wore it, `CSDuskCard`, `CSHairline` and `CSTabStrip` — is deleted:
// a hero is a band, a divider is `CSRule`, a pane control is `CSSegment`, and
// nothing in the product paints a gradient over a page to suggest depth.
//
// What is left is the page header, the section head, the row and the motion
// vocabulary. Every colour is a token at an opacity — nothing is invented
// (preflight 15).

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - The page header

/// **§12.2's one header.** The name in `display` 34, an optional `agateS`
/// dateline flush right, and at most one trailing control (IOS-022 item 1:
/// the screen's one action rides the header row, not an empty navigation
/// bar). Lives in the scroll so the glass toolbar never clips it, and every
/// pushed screen that uses it sets `navigationTitle("")` so a name is never
/// drawn twice.
///
/// The AX3 branch stacks the three elements rather than letting them fight
/// for one row — the shipped behaviour, kept, because it is a "what works".
public struct CSPageHeader<Trailing: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let title: String
  let eyebrow: String?
  let sub: String?
  let trailing: Trailing
  public init(_ title: String, eyebrow: String? = nil, sub: String? = nil, @ViewBuilder trailing: () -> Trailing) {
    self.title = title; self.eyebrow = eyebrow; self.sub = sub; self.trailing = trailing()
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // QB-11 · **AX3 · THE HEADER'S THREE THINGS STOP FIGHTING FOR ONE ROW.**
      //
      // Title, dateline and the page's one action shared an `HStack`, so at
      // the accessibility sizes the Compete tab drew "Com / pete" broken across
      // two lines beside "START SOMET / HING" split mid-word and overlapping
      // the date. Three elements that each want the full width cannot have a
      // third of it. They stack, in reading order, at those sizes only —
      // nothing is dropped, nothing shrinks, and the reading-size layout is
      // untouched.
      if typeSize.isA11y {
        titleBlock
        if let eyebrow { Text(eyebrow).csType(.agateS, caps: true).foregroundStyle(cs.mut) }
        trailing.frame(minHeight: 44)
      } else {
        HStack(alignment: .lastTextBaseline) {
          titleBlock
          Spacer(minLength: 8)
          if let eyebrow {
            Text(eyebrow).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              .lineLimit(1).fixedSize()
          }
          // the control is its own accessibility element — never folded into the title
          trailing.frame(minWidth: 44, minHeight: 44).padding(.trailing, -8)
        }
      }
      if let sub {
        Text(sub).csType(.body).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// §12.2's anatomy, and the whole of it: **the name in `display`**, and
  /// nothing above it.
  ///
  /// The gradient tick is gone (Wave 3). It was `CSLookAccent.tick`, a 28 × 3
  /// two-stop gradient over every pushed screen's title — and a gradient is
  /// the one image state §10.1's ladder bans by name. It was also the only
  /// thing on a header that changed colour with a look, so a page's name
  /// meant "which league you last opened" rather than "which page this is".
  /// The serif went with it: `display` is the naming role, one per viewport.
  private var titleBlock: some View {
    Text(title).csType(.display, caps: true).foregroundStyle(cs.ink)
      .lineLimit(2).minimumScaleFactor(0.72)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
      // Y-33: the page's title is a heading — VoiceOver's rotor lands on it
      .accessibilityAddTraits(.isHeader)
      .csBudget(display: 1)
  }
}

public extension CSPageHeader where Trailing == EmptyView {
  init(_ title: String, eyebrow: String? = nil, sub: String? = nil) {
    self.init(title, eyebrow: eyebrow, sub: sub) { EmptyView() }
  }
}

/// "THU · AUG 27" — the header's date eyebrow.
public enum CSHeaderDate {
  public static func today(_ date: Date = Date(), calendar: Calendar = .current) -> String {
    let f = DateFormatter(); f.calendar = calendar; f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "EEE · MMM d"
    return f.string(from: date).uppercased()
  }
}

// MARK: - Sections and hairlines

/// An agate label with a 1px rule running to the margin, and a **count slot**
/// flush right.
///
/// **The right slot takes a count or a period — `LAST FIVE`, `11 KEPT`,
/// `WEEK 5` — and NEVER a proper name**, never a date range, never a filter and
/// never a league's name, which belongs in the label or in the row's own
/// sub-line (§16A.2). A section names its count ONCE, and the slot is where.
/// `trailing:` with an `action:` is still a link, for the handful of heads that
/// genuinely lead somewhere; `count:` is the slot.
public struct CSSectionHead: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la

  /// **ONE SECTION-HEAD IDIOM IN THE PRODUCT, AT TWO WEIGHTS** (D286).
  ///
  /// `.label` NAMES a block — an agate label with a rule running to the margin
  /// and an optional count. It is right above a block whose rows already carry
  /// their own weight (a table, a slat list, a form), where the head is a
  /// caption on something self-evident.
  ///
  /// `.display` is the head that is a real STEP: `displayS` 24 in `ink` over
  /// rows set at 15–17, which is a 1.6× size step and a full contrast step in
  /// one object. An eye reads that as a new section before it reads a word,
  /// and it is the answer to *"sections aren't differentiated"* — the head is
  /// spent on the surfaces where the rows are quiet type and the head is
  /// otherwise no louder than they are (Home's datelines, Compete's YOUR
  /// SEASONS). It carries **no rule and no box** (`BRIEF` §32 — structure
  /// without containers): `s5` of air above it and the size step are the
  /// separation, and a second hairline under a 24pt line would be the head
  /// competing with its own rows for the same device.
  ///
  /// It is `displayS` and never `display`: §1.5 gives a viewport exactly one
  /// `display` and the masthead has it. `count:` and `trailing:` belong to
  /// `.label`; a `.display` head is the title alone, because a 24pt line with
  /// an 11pt rider beside it is two heads.
  public enum Weight: Sendable { case label, display }

  let title: String
  let count: String?
  let trailing: String?
  let action: (() -> Void)?
  let weight: Weight
  @Environment(\.dynamicTypeSize) private var typeSize
  public init(_ title: String, count: String? = nil, trailing: String? = nil,
              weight: Weight = .label, action: (() -> Void)? = nil) {
    self.title = title; self.count = count; self.trailing = trailing
    self.weight = weight; self.action = action
  }
  /// **THE RULE RUNS BETWEEN THE LABEL AND THE COUNT** (§18's own anatomy:
  /// "agate label + rule + optional count", and §16A.2's *right-of-rule* slot).
  /// Wave 0b shipped the rule as a full-measure hairline UNDER the row, which
  /// put the count above a line it was supposed to sit beside and cost the
  /// head a line of vertical space on every surface in the product. One line,
  /// three parts.
  ///
  /// At the accessibility sizes the rule is dropped rather than squeezed: a
  /// 6pt sliver between two wrapped agate blocks is noise, and the count then
  /// takes its own line under the label.
  @ViewBuilder public var body: some View {
    switch weight {
    case .display: displayHead
    case .label:   labelHead
    }
  }

  /// The step. `fixedSize(horizontal: false)` deliberately — the label wraps
  /// at the accessibility sizes rather than holding its line, because there is
  /// no rule beside it to give way and a head wider than the page is the AX3
  /// shear the comment below records.
  private var displayHead: some View {
    Text(title).csType(.displayS)
      .foregroundStyle(cs.ink)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityAddTraits(.isHeader)
  }

  private var labelHead: some View {
    A11yStack(rowAlignment: .center, spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s2) {
      HStack(spacing: CSTokens.Space.s3) {
        // Y-33: the trait rides the title, not the row, so the trailing link
        // stays its own element and never reads as part of the heading
        // **the label never wraps; the rule gives way.** `THIS WEEK · THE
        // CLASH` broke over two lines with a 300pt rule floating beside it
        // the first time this shipped — a head is one line of type with a
        // rule filling what is left, and the flexible part is the rule.
        // **AND IT WRAPS AT THE ACCESSIBILITY SIZES, WHICH IS NOT A SOFTENING
        // OF THE RULE ABOVE.** `fixedSize(horizontal: true)` is right where the
        // rule exists: the label holds its line and the rule gives way. At AX3
        // the rule is already dropped — and `WEEK 2 · SEP 5 – SEP 8` at agate
        // ×2.2 measures ~400pt on a 362pt page, so a head that refuses to wrap
        // is a row wider than the screen. A vertical `ScrollView` then sizes
        // its content box to that row and CENTRES it, and **every block on the
        // page shifts left and the widest runs off the right edge** — the AX3
        // shear Wave 5 met on the season page, filed as unfinished, and could
        // not isolate. It is this line.
        Text(title).csEyebrow(la.eyebrow).accessibilityAddTraits(.isHeader)
          .fixedSize(horizontal: !typeSize.isA11y, vertical: true).layoutPriority(1)
        if !typeSize.isA11y {
          // **D307 · THE HEAD'S RULE WEARS THE LOOK, AND IT IS THE HEAD'S
          // RULE ONLY.** The owner, on D305: *"Only seeing one color come
          // through, lets identify a few more elements to carry colors."* Of
          // the four candidates he took this one — the section head, rule and
          // eyebrow — and it is the quietest of them and the most frequent:
          // this rule runs to the margin beside THE SEASON, RIVALS, THE
          // RECEIPT, THE ARCHIVE, on every screen, several times each. The
          // eyebrow beside it already took the look (`la.eyebrow`), so the two
          // halves of one object stop disagreeing.
          //
          // **`CSRule` is deliberately not touched.** Every divider between
          // rows stays `cs.rule`: a page of coloured hairlines is the wash
          // D270/D278 deleted, arriving one line at a time. A head is a
          // NAMED object and may wear a colour; a divider is structure.
          //
          // **D313 · AND ITS FAR THIRD TAKES THE SECOND COLOUR.** D307 gave
          // this rule `accent` and left `accent2` reaching nothing on any
          // look — its own closing line said so. The rule is one object and
          // it now carries both halves of the livery: the accent where it
          // leaves the word, the second colour on the run to the margin. It
          // is TWO SOLID SEGMENTS and not a gradient — BRIEF §4 names the
          // amber-to-ember ramp as a do-not, and D270 deleted `effect.grad`.
          // Off a look it is one neutral hairline exactly as before.
          Group {
            if la.active {
              // Two flexible rectangles in an HStack split the run EVENLY —
              // neither has an intrinsic width — so this is a half-and-half
              // rule by construction rather than by a number, which is why
              // there is no ratio to tune and no `GeometryReader` on a
              // hairline that appears several times per screen.
              HStack(spacing: 0) {
                Rectangle().fill(la.accent)
                Rectangle().fill(la.accent2)
              }
            } else {
              Rectangle().fill(cs.rule)
            }
          }
          .frame(height: CSTokens.Space.hair).frame(maxWidth: .infinity)
        }
      }
      if !typeSize.isA11y { Spacer(minLength: 0) }
      if let count {
        Text(count).csType(.agateS, caps: true).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      if let trailing {
        if let action {
          // accessibility: the eyebrow link keeps its look and gains a 44pt hit area
          Button(action: action) { Text(trailing).csEyebrow(cs.ink).a11yHitSlop() }.buttonStyle(.plain)
        } else {
          Text(trailing).csEyebrow(cs.ink)
        }
      }
    }
    .padding(.top, 10)
  }
}

/// A row inside a section: content, then a hairline. Rows never nest cards.
public struct CSRow<Content: View>: View {
  let last: Bool
  let content: Content
  public init(last: Bool = false, @ViewBuilder content: () -> Content) { self.last = last; self.content = content() }
  public var body: some View {
    VStack(spacing: 0) {
      content.padding(.vertical, 12).frame(maxWidth: .infinity, alignment: .leading)
      if !last { CSRule() }
    }
  }
}

// MARK: - Motion

/// The roll: `cubic-bezier(.16,.84,.36,1)` — fast start, long soft settle.
///
/// **L-30 has two halves and this type owns both.** One easing everywhere —
/// the roll, at three durations; nothing bounces, which is why no token here
/// has a control point above 1. And *reduced motion rests on the frame rather
/// than animating*: `curve`, `run` and `.csAnimation` all resolve to **nil**
/// when the golfer has asked for less motion, which in SwiftUI means the state
/// change lands instantly and the frame is where it always was. That is the
/// difference between "shorter" and "rests": a reduced-motion setting is not a
/// request for a faster animation.
///
/// The reduce-motion read is `UIAccessibility`'s global rather than the
/// `\.accessibilityReduceMotion` environment value on purpose — `withAnimation`
/// is called from button actions and models that have no environment to read,
/// and a rule that only holds inside a `body` is a rule with a hole in it.
public enum CSMotion {
  public static let roll = Animation.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.32)
  public static let rise = Animation.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.26)
  /// A long roll, for a list that reorders under the eye (the table, the climb).
  public static let settle = Animation.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.55)
  /// A quick roll, for a disclosure that opens under the finger.
  public static let tick = Animation.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.18)
  /// **The snap** — `cubic-bezier(.2,0,0,1)` at 180ms. The roll is how a thing
  /// ARRIVES; the snap is how a control ANSWERS A FINGER. A press that rolls
  /// for 320ms reads as lag, which is why every `ButtonStyle` in the system
  /// animates on this and nothing else does.
  public static let snap = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.18)

  /// The one repeating motion the product has: a live dot breathing. It is
  /// still the roll — `easeInOut` was a fourth curve wearing a fifth job.
  public static func breath(_ duration: Double = 1.4) -> Animation {
    Animation.timingCurve(0.16, 0.84, 0.36, 1, duration: duration).repeatForever(autoreverses: true)
  }

  /// Has the golfer asked for less motion? Read at the moment of animating,
  /// never cached: the setting can change while the app is open.
  @MainActor public static var reduced: Bool {
    #if canImport(UIKit)
    UIAccessibility.isReduceMotionEnabled
    #else
    false
    #endif
  }

  /// The animation to actually use — `nil` under reduced motion (L-30).
  @MainActor public static func curve(_ a: Animation = roll) -> Animation? { reduced ? nil : a }

  /// `withAnimation`, with L-30 applied. Every state change in the app that
  /// wants the roll goes through here, so "reduced motion rests on the frame"
  /// is one line of code rather than a habit forty call sites have to keep.
  @MainActor public static func run<R>(_ a: Animation = roll, _ body: () throws -> R) rethrows -> R {
    try withAnimation(curve(a), body)
  }
}

public extension View {
  /// `.animation(_:value:)`, with L-30 applied — the roll, and nothing at all
  /// when the golfer has asked for less motion.
  func csAnimation<V: Equatable>(_ a: Animation = CSMotion.roll, value: V) -> some View {
    modifier(CSAnimationModifier(base: a, value: value))
  }
}

private struct CSAnimationModifier<V: Equatable>: ViewModifier {
  /// The environment value, not the global, is what a `body` should read: it
  /// invalidates the view when the setting changes, which the global does not.
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let base: Animation
  let value: V
  func body(content: Content) -> some View {
    content.animation(reduceMotion ? nil : base, value: value)
  }
}

// MARK: - Sheets that survive the accessibility sizes

/// **A sheet pinned to a height is a sheet a golfer at AX3 cannot read.**
///
/// `.presentationDetents([.height(340)])` is the right answer at the reading
/// sizes — five sentences do not need a whole screen, and a sheet with 900pt of
/// nothing under it reads as a page that failed. At the accessibility sizes the
/// same 340 points hold roughly a third of the same words: the length sheet
/// drew its three rows ON TOP OF EACH OTHER and ended two of its three glosses
/// in an ellipsis, and the intent sheet showed two of its four intents with no
/// sign there were more.
///
/// So the height is a READING-SIZE detent, and the accessibility sizes get the
/// whole page. One helper, so no sheet has to remember (preflight 38 fails the
/// push on a bare `.height(` detent outside it).
public struct CSFittedSheet: ViewModifier {
  @Environment(\.dynamicTypeSize) private var typeSize
  let height: CGFloat
  let large: Bool
  public func body(content: Content) -> some View {
    content
      .presentationDetents(typeSize.isA11y ? [.large]
                           : (large ? [.height(height), .large] : [.height(height)]))
      .presentationDragIndicator(.visible)
  }
}

public extension View {
  /// A fitted sheet: `height` points at the reading sizes, the whole page at
  /// the accessibility sizes. `large: true` also offers the full page as a
  /// second detent below AX, for a sheet whose content can grow.
  func csFittedSheet(_ height: CGFloat, large: Bool = false) -> some View {
    modifier(CSFittedSheet(height: height, large: large))
  }
}

#Preview("Page header · accessibility3") {
  VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
    CSPageHeader("Cup Season", eyebrow: "THU · AUG 27") { Image(systemName: "plus").frame(width: 44, height: 44) }
    CSSectionHead("The table", count: "12 GOLFERS")
  }
  .padding(CSTokens.Space.s4)
  .environment(\.dynamicTypeSize, .accessibility3)
  .csTheme()
}
