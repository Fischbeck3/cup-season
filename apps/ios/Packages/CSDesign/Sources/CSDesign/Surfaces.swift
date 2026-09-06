// Cup Season — how surfaces sit (IOS-019).
//
// Depth from ground, not from borders. One hero per screen wears the wash;
// the page header lives in the scroll; sections are an eyebrow and a
// hairline; panes are a tab strip with an ember underline. Every colour here
// is a token at an opacity — nothing is invented (preflight 15).

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - The wash

/// A radial of the spine colour, 14% at the top-leading corner fading to
/// nothing (30% when a hero wears a look — D103b). Ember = live, gold =
/// earned, `pos` = on the tee, dusk = ceremony. Exactly one per screen.
public struct CSWash: View {
  let color: Color
  let strength: Double
  public init(_ color: Color, strength: Double = 0.14) { self.color = color; self.strength = strength }
  public var body: some View {
    GeometryReader { g in
      RadialGradient(colors: [color.opacity(strength), color.opacity(0)],
                     center: UnitPoint(x: 0.08, y: 0.0),
                     startRadius: 0, endRadius: max(g.size.width, g.size.height) * 0.9)
    }
    .allowsHitTesting(false)
  }
}

/// The hero card: `bg1`, the spine, the wash, radius `r`, no border.
///
/// `spine: nil` (the default) wears the look's accent from `\.csLook`, or
/// ember when no look applies. A caller that passes gold keeps gold — a look
/// never overrides the earned metal (D103a). Under a look the wash the accent
/// wears is 30%, not 14% (D103b); a passed spine (gold) keeps the 14%.
public struct CSHero<Content: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let spine: Color?
  let padding: CGFloat
  let content: Content
  public init(spine: Color? = nil, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
    self.spine = spine; self.padding = padding; self.content = content()
  }
  private var spineColor: Color { spine ?? la.accent }
  private var washStrength: Double { spine == nil ? la.washStrength : 0.14 }
  public var body: some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        ZStack {
          RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(cs.bg1)
          CSWash(spineColor, strength: washStrength)
        }
        .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      }
      .overlay(alignment: .leading) {
        RoundedRectangle(cornerRadius: 2).fill(spineColor).frame(width: 3.5).padding(.vertical, 14)
      }
  }
}

/// The ceremony ground as a card: dusk in every theme (IOS-003 §2.6).
public struct CSDuskCard<Content: View>: View {
  let wash: Color?
  let padding: CGFloat
  let content: Content
  public init(wash: Color? = nil, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
    self.wash = wash; self.padding = padding; self.content = content()
  }
  public var body: some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        ZStack {
          RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(CSDusk.surface)
          if let wash { CSWash(wash, strength: 0.18) }
        }
        .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      }
      .environment(\.colorScheme, .dark)
      .environment(\.cs, CSTokens.dark)
  }
}

// MARK: - The page header

/// The gradient tick, a serif title, an optional mono eyebrow on the right,
/// and an optional trailing control (the `+` on Home, the ⚙ on You — IOS-022
/// item 1: the screen's one action rides the header row, not an empty
/// navigation bar). Lives in the scroll so the glass toolbar never clips it.
public struct CSPageHeader<Trailing: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
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
        if let eyebrow { Text(eyebrow).csEyebrow() }
        trailing.frame(minHeight: 44)
      } else {
        HStack(alignment: .lastTextBaseline) {
          titleBlock
          Spacer(minLength: 8)
          if let eyebrow { Text(eyebrow).csEyebrow() }
          // the control is its own accessibility element — never folded into the title
          trailing.frame(minWidth: 44, minHeight: 44).padding(.trailing, -8)
        }
      }
      if let sub { Text(sub).font(CSFont.sentence).foregroundStyle(cs.mut) }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var titleBlock: some View {
    VStack(alignment: .leading, spacing: 8) {
      // D103b: accent → accent2 under a look; ember → amber on homebase
      Rectangle().fill(LinearGradient(colors: la.tick, startPoint: .leading, endPoint: .trailing))
        .frame(width: 28, height: 3)
      Text(title).font(CSFont.heroSmall).foregroundStyle(cs.ink)
        .lineLimit(2).minimumScaleFactor(0.8)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
    // Y-33: the page's title is a heading — VoiceOver's rotor lands on it
    .accessibilityAddTraits(.isHeader)
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

public struct CSHairline: View {
  @Environment(\.cs) private var cs
  public init() {}
  public var body: some View { Rectangle().fill(cs.line).frame(height: 1) }
}

/// An eyebrow over a hairline, with an optional trailing link in `dawn`. The
/// title wears the look's accent at full strength under a look (D103b), `mut`
/// on homebase.
public struct CSSectionHead: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let title: String
  let trailing: String?
  let action: (() -> Void)?
  public init(_ title: String, trailing: String? = nil, action: (() -> Void)? = nil) {
    self.title = title; self.trailing = trailing; self.action = action
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        // Y-33: the trait rides the title, not the row, so the trailing link
        // stays its own element and never reads as part of the heading
        Text(title).csEyebrow(la.eyebrow).accessibilityAddTraits(.isHeader)
        Spacer()
        if let trailing {
          if let action {
            // accessibility: the eyebrow link keeps its look and gains a 44pt hit area
            Button(action: action) { Text(trailing).csEyebrow(cs.dawn).a11yHitSlop() }.buttonStyle(.plain)
          } else {
            Text(trailing).csEyebrow(cs.dawn)
          }
        }
      }
      CSHairline()
    }
    .padding(.top, 10)
  }
}

/// D177 · A GROUP head: one level above `CSSectionHead`, for a page that needs
/// a spine rather than a list. It wears the brand at rest — a group head is
/// structure, not an accent moment — sits on a heavier rule, and gets real air
/// above it so the eye reads a break rather than another section.
///
/// Use sparingly. Two on a page is a spine; four is a table of contents.
public struct CSGroupHead: View {
  @Environment(\.cs) private var cs
  let title: String
  public init(_ title: String) { self.title = title }
  public var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(title).csEyebrow(cs.brand)
      Rectangle().fill(cs.line2).frame(height: 1)
    }
    .padding(.top, 26)
    .accessibilityAddTraits(.isHeader)
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
      if !last { CSHairline() }
    }
  }
}

// MARK: - The tab strip

/// Panes: mono uppercase labels, an underline that slides on the roll — the
/// look's accent under a look, ember on homebase (D103b).
public struct CSTabStrip<T: Hashable>: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let items: [(T, String)]
  @Binding var selection: T
  @Namespace private var ns
  public init(_ items: [(T, String)], selection: Binding<T>) { self.items = items; _selection = selection }
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 0) {
        ForEach(items, id: \.0) { key, label in
          let on = key == selection
          Button {
            CSMotion.run { selection = key }
            CSHaptic.selection()
          } label: {
            VStack(spacing: 8) {
              Text(label).font(CSFont.eyebrow).tracking(1.4).textCase(.uppercase)
                .foregroundStyle(on ? cs.ink : cs.mut)
              ZStack {
                Rectangle().fill(.clear).frame(height: 2)
                if on {
                  Rectangle().fill(la.accent).frame(height: 2)
                    .matchedGeometryEffect(id: "underline", in: ns)
                }
              }
            }
            .padding(.horizontal, 12).padding(.top, 8)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(label)
          .accessibilityAddTraits(on ? [.isSelected] : [])
        }
      }
    }
    // the strip scrolls sideways at every type size (IOS-022 item 9): a tab is never clipped, only off to the right
    .overlay(alignment: .bottom) { CSHairline() }
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

#Preview("Tab strip · accessibility3") {
  VStack(alignment: .leading, spacing: 20) {
    CSPageHeader("Cup Season", eyebrow: "THU · AUG 27") { Image(systemName: "plus").frame(width: 44, height: 44) }
    CSTabStrip([("a", "Standings"), ("b", "Board"), ("c", "Schedule"), ("d", "Pot"), ("e", "Album"), ("f", "League")], selection: .constant("a"))
  }
  .padding(20)
  .environment(\.dynamicTypeSize, .accessibility3)
  .csTheme()
}
