// Cup Season — the controls (D269, UI_SYSTEM §7).
//
// THE SINGLE HIGHEST-LEVERAGE CHANGE THE AUDIT NAMES: primary / secondary /
// tertiary are **`ButtonStyle`s, not a `View`**. That one move removes the
// reason four sites hand-copied the ember fill, gives every button a pressed
// state for free, and lets `ShareLink`, `NavigationLink` and `Menu` wear the
// brand. 90 of ~317 tappables carried a shared definition; the target is all
// of them.
//
// `configuration.isPressed` and `isEnabled` are read **0 times** in the
// shipped product. That is the finding behind non-negotiable 9, and it is why
// every style in this file names all five states.
//
// **ONE PRIMARY PER SCREEN, AND IT IS EMBER. THERE IS NO GOLD BUTTON** — the
// tier does not exist, `CSButtonStyle.gold` is deleted, and gold may never
// touch a control. **A DISABLED PRIMARY IS NEVER EMBER.**

import SwiftUI

// MARK: - The three tiers

/// 50pt, `rc` 10, `brand` fill, `bg0` label. The screen's one live action.
public struct CSPrimaryStyle: ButtonStyle {
  @Environment(\.cs) private var cs
  @Environment(\.isEnabled) private var enabled
  let busy: Bool
  /// **The developer harness, and nothing else.** A pressed state cannot be
  /// photographed by `simctl` — there is no finger — so the specimen sheet
  /// draws the real style with this set rather than hand-copying the pressed
  /// fill, which is precisely the class of duplication this file exists to
  /// remove. A surface that sets it is a surface lying about a control.
  let held: Bool
  public init(busy: Bool = false, held: Bool = false) { self.busy = busy; self.held = held }

  public func makeBody(configuration: Configuration) -> some View {
    let pressed = configuration.isPressed || held
    return ZStack {
      configuration.label
        .csType(.name)
        .opacity(busy ? 0 : (pressed ? 0.92 : 1))
      // never a spinner: three mono dots that tally, so the control says it is
      // working without borrowing the loading language of a whole screen
      if busy { CSTallyDots(tint: enabled ? cs.bg0 : cs.mut) }
    }
    .frame(maxWidth: .infinity, minHeight: 50)
    .foregroundStyle(enabled ? cs.bg0 : cs.mut)
    .background(fill(pressed),
                in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .csBudget(ember: enabled ? 1 : 0)
    .csAnimation(CSMotion.snap, value: configuration.isPressed)
  }

  /// **A disabled primary is never ember.** It falls to `bg1` with a `mut`
  /// label — because a control that cannot be used should not be wearing the
  /// colour that means "this is the live thing you can do now".
  private func fill(_ pressed: Bool) -> Color {
    guard enabled else { return cs.bg1 }
    return pressed ? cs.brand.opacity(1 - CSTokens.Alpha.a16) : cs.brand
  }
}

/// 50pt, `rc` 10, `bg2` fill, `ink` label.
public struct CSSecondaryStyle: ButtonStyle {
  @Environment(\.cs) private var cs
  @Environment(\.isEnabled) private var enabled
  let busy: Bool
  /// The harness's window onto the pressed state — see `CSPrimaryStyle.held`.
  let held: Bool
  public init(busy: Bool = false, held: Bool = false) { self.busy = busy; self.held = held }
  public func makeBody(configuration: Configuration) -> some View {
    let pressed = configuration.isPressed || held
    return ZStack {
      configuration.label.csType(.name).opacity(busy ? 0 : (pressed ? 0.92 : 1))
      if busy { CSTallyDots(tint: cs.ink) }
    }
    .frame(maxWidth: .infinity, minHeight: 50)
    .foregroundStyle(enabled ? cs.ink : cs.mut)
    .background(enabled ? (pressed ? cs.rule : cs.bg2) : cs.bg1,
                in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .csAnimation(CSMotion.snap, value: configuration.isPressed)
  }
}

/// The link. Intrinsic width, a 44pt target, `name` 15 with a rule beneath.
///
/// **The tertiary's rule is where ember kept leaking back, so the tier is split
/// into three and the split is a ruling, not a preference.** Ember has exactly
/// two jobs; a *dismiss* verb is neither, a *Settings* link is neither, a
/// *Share* link is neither. The first draft gave every tertiary a 2px `brand`
/// rule, and the consequence was countable: four screens whose only
/// content-area ember was the word `CLOSE`, and one sheet carrying three ember
/// rules and a fill.
///
/// `mut` at 7.07 / 5.85 is the underline in both quiet cases, **never `rule`**
/// (2.66 / 2.30): when the underline IS the affordance, taking it below 3:1
/// stops it being a control.
public struct CSTertiaryStyle: ButtonStyle {
  @Environment(\.cs) private var cs
  @Environment(\.isEnabled) private var enabled
  public enum Placement: Sendable {
    case live       // 2px brand — only when the link IS the screen's one live action
    case content    // 2px mut
    case toolbar    // 1px mut — the toolbar's position is already an affordance
    var weight: CGFloat { self == .toolbar ? 1 : 2 }
  }
  let placement: Placement
  /// The harness's window onto the pressed state — see `CSPrimaryStyle.held`.
  let held: Bool
  public init(_ placement: Placement = .content, held: Bool = false) {
    self.placement = placement; self.held = held
  }

  public func makeBody(configuration: Configuration) -> some View {
    let pressed = configuration.isPressed || held
    // **THE RULE MUST BE AS WIDE AS THE WORDS AND NO WIDER**, and WAVE 10
    // stops that being a choice between two wrong answers.
    //
    // Hugging (`fixedSize`) is right: a `VStack` in a column proposes the
    // column to its `Rectangle`, so a hugged rule underlines the link and an
    // unhugged one draws a divider under a paragraph. But a hugged 300pt
    // label at AX3 shears the page's left edge — so Wave 0b pinned two lines
    // and Wave 1 hugged, and each shipped the other's defect: `SETTINGS`, one
    // word, drew a full-measure rule directly above the credential (Wave 3's
    // own note), and `START OVER — CLEAR THIS ROUND` truncated at AX5.
    //
    // `ViewThatFits` decides it against the real proposal at the real size:
    // the hugged one-line form while it fits, the wrapped full-measure form
    // when it does not, and **no line limit in the wrapped form** — a link is
    // words, and a word a golfer cannot read is not a link.
    return ViewThatFits(in: .horizontal) {
      block(configuration, pressed: pressed, hugs: true)
      block(configuration, pressed: pressed, hugs: false)
    }
    .opacity(pressed ? 0.92 : 1)
    .foregroundStyle(enabled ? cs.ink : cs.mut)
    .a11yHitSlop()
    .frame(minHeight: 44)
    // **THE FRAME IS NOT THE TARGET UNTIL SOMETHING SHAPES IT**, and this one
    // line is why `Settings` could not be tapped on the You page.
    //
    // `a11yHitSlop` pads, sets `contentShape`, then pads back NEGATIVE — so the
    // shape it installs is the size of the words, and the layout bounds shrink
    // to the words too. `.frame(minHeight: 44)` then draws a 44pt row around a
    // ~20pt hit region: a link that measures as a legal target, reports as one
    // to every audit that greps for `44`, and misses the thumb. Every one of
    // the product's tertiary links had it, so the shared idiom for "go here"
    // was the least reliable control in the app.
    //
    // Shaping AFTER the frame makes the whole 44pt row the target. The slop
    // above still earns its keep at the horizontal edges and at AX sizes, where
    // the words can be shorter than the row. `CSTertiaryTargetTests` pins the
    // order; if anyone reorders these two lines the test fails rather than the
    // golfer.
    .contentShape(Rectangle())
    .csBudget(ember: placement == .live && enabled ? 1 : 0)
    .csAnimation(CSMotion.snap, value: configuration.isPressed)
  }

  @ViewBuilder
  private func block(_ configuration: Configuration, pressed: Bool, hugs: Bool) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      configuration.label.csType(.nameS).lineLimit(hugs ? 1 : nil)
      Rectangle().fill(rule(pressed)).frame(height: placement.weight)
    }
    .fixedSize(horizontal: hugs, vertical: false)
  }

  private func rule(_ pressed: Bool) -> Color {
    guard enabled else { return cs.mut }
    switch placement {
    case .live: return pressed ? cs.brand.opacity(1 - CSTokens.Alpha.a16) : cs.brand
    case .content, .toolbar: return pressed ? cs.ink : cs.mut
    }
  }
}

/// The armed destructive: `bg2` fill, `neg` label, and the copy is **"Sure?"**
/// — never an `alert()`.
public struct CSDestructiveStyle: ButtonStyle {
  @Environment(\.cs) private var cs
  /// **The busy state, added in Wave 9 because two sheets were hand-rolling
  /// it.** `SeasonAdminSheets` drew its own `ZStack { label.opacity(busy ? 0 :
  /// 1); if busy { ProgressView() } }` over its own `RoundedRectangle` — a
  /// third button tier, invisible to every check that counts tiers, with a
  /// spinner in it where the primary tallies. It is the style's job.
  let busy: Bool
  public init(busy: Bool = false) { self.busy = busy }
  public func makeBody(configuration: Configuration) -> some View {
    ZStack {
      configuration.label
        .csType(.name)
        .opacity(busy ? 0 : 1)
      // never a spinner, here either: the same three dots the primary tallies
      if busy { CSTallyDots(tint: cs.neg) }
    }
    .frame(maxWidth: .infinity, minHeight: 50)
    .foregroundStyle(cs.neg)
    .background(configuration.isPressed ? cs.neg.opacity(CSTokens.Alpha.a16) : cs.bg2,
                in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .csAnimation(CSMotion.snap, value: configuration.isPressed)
  }
}

/// Three mono dots that tally. A spinner belongs inside a CONTROL and nowhere
/// else (`LINT-22`); this is the control's own form of it, and it is countable
/// rather than perpetual.
struct CSTallyDots: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let tint: Color
  @State private var lit = 0
  var body: some View {
    HStack(spacing: CSTokens.Space.s1) {
      ForEach(0..<3, id: \.self) { i in
        Circle().fill(tint).frame(width: 4, height: 4)
          .opacity(reduceMotion ? 1 : (i <= lit ? 1 : CSTokens.Alpha.a24))
      }
    }
    .task {
      guard !reduceMotion else { return }
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(320))
        lit = (lit + 1) % 3
      }
    }
    .accessibilityLabel("Working")
  }
}

public extension ButtonStyle where Self == CSPrimaryStyle {
  static var csPrimary: CSPrimaryStyle { CSPrimaryStyle() }
  static func csPrimary(busy: Bool = false, held: Bool = false) -> CSPrimaryStyle {
    CSPrimaryStyle(busy: busy, held: held)
  }
}
public extension ButtonStyle where Self == CSSecondaryStyle {
  static var csSecondary: CSSecondaryStyle { CSSecondaryStyle() }
  static func csSecondary(busy: Bool = false, held: Bool = false) -> CSSecondaryStyle {
    CSSecondaryStyle(busy: busy, held: held)
  }
}
public extension ButtonStyle where Self == CSTertiaryStyle {
  static var csTertiary: CSTertiaryStyle { CSTertiaryStyle(.content) }
  static func csTertiary(_ p: CSTertiaryStyle.Placement, held: Bool = false) -> CSTertiaryStyle {
    CSTertiaryStyle(p, held: held)
  }
}
public extension ButtonStyle where Self == CSDestructiveStyle {
  static var csDestructive: CSDestructiveStyle { CSDestructiveStyle() }
  static func csDestructive(busy: Bool) -> CSDestructiveStyle { CSDestructiveStyle(busy: busy) }
}

// MARK: - The chip

/// 28pt tall, radius `p` 3, `agate` label. **Selected INVERTS to the panel** —
/// which also fixes the finding that the shipped *selected* pill was visually
/// quieter than the unselected one.
///
/// Budget: one chip row per screen, at most six chips. Twenty-two declared chip
/// types at five heights, five paddings, two shapes and three "selected"
/// languages become this.
public struct CSChip: View {
  @Environment(\.cs) private var cs
  let label: String
  let selected: Bool
  let enabled: Bool
  public init(_ label: String, selected: Bool, enabled: Bool = true) {
    self.label = label; self.selected = selected; self.enabled = enabled
  }
  public var body: some View {
    Text(label)
      .csType(.agateS, caps: true)
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
      .foregroundStyle(enabled ? (selected ? cs.panelInk : cs.mut) : cs.dim)
      .padding(.horizontal, CSTokens.Space.s3)
      .frame(height: 28)
      .background(enabled ? (selected ? cs.panel : cs.bg2) : cs.bg1,
                  in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
      // **WAVE 10 · THE CHIP CARRIES ITS OWN 44pt TARGET** (§16.2). The drawn
      // shape is 28 and stays 28 — that is the design — but the thing a thumb
      // has to hit is not the drawn shape. Nineteen chip sites shipped after
      // Wave 8 and exactly three added a target by hand, so the live round's
      // HOLE/CARD toggle (the audit's named ~22pt miss, 28 after the sweep),
      // the composer's golfer chips (~36) and fourteen more were all under the
      // floor. `a11yHitSlop` sets the hit shape and hands the space straight
      // back to the layout, so nothing moves by a point and every chip in the
      // product is 44 tall from this line.
      .a11yHitSlop(vertical: 8, horizontal: 0)
      .accessibilityAddTraits(selected ? [.isSelected] : [])
  }
}

// MARK: - The segment

/// A 44pt row, **no pill**, with a 2px **ink** underline on the selected item —
/// never ember, because a tab is not live. One component replaces `PostSeg`,
/// `WizardSeg`, `EventSeg`, `FlowSeg`, `LiveSeg` and `CSTabStrip`.
public struct CSSegment<T: Hashable>: View {
  @Environment(\.cs) private var cs
  let items: [(T, String)]
  @Binding var selection: T
  public init(_ items: [(T, String)], selection: Binding<T>) {
    self.items = items; _selection = selection
  }
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 0) {
        ForEach(items, id: \.0) { key, label in
          let on = key == selection
          Button {
            CSMotion.run(CSMotion.snap) { selection = key }
            CSHaptic.selection()
          } label: {
            VStack(spacing: CSTokens.Space.s2) {
              Text(label).csType(.agateS, caps: true).foregroundStyle(on ? cs.ink : cs.mut)
              Rectangle().fill(on ? cs.ink : Color.clear).frame(height: 2)
            }
            .padding(.horizontal, CSTokens.Space.s3)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(label)
          .accessibilityAddTraits(on ? [.isSelected] : [])
        }
      }
    }
    .overlay(alignment: .bottom) { CSRule() }
  }
}

// MARK: - The field

/// 50pt, `rc` 10, `bg2` fill, **no border**. Focus is a 2px `brand` ring.
///
/// **The full family, which is the audit's "inputs" item**: label in agate
/// above · value · caption in `body` 15 at `mut` beneath, which doubles as the
/// error line in `neg` · a character counter that appears at 80% of a limit
/// (four fields currently clamp silently inside `.onChange` and tell the golfer
/// nothing) · disabled · loading. The shipped field has two states and a cliff
/// between them.
public struct CSField: View {
  @Environment(\.cs) private var cs
  @Environment(\.isEnabled) private var enabled
  public enum Kind: Sendable {
    /// A sentence. SF Pro — email, a name, a note, a search.
    case prose
    /// A code, a handle, a time or a score. Plex Mono, and nothing else.
    case code
  }
  let label: String?
  let placeholder: String
  @Binding var text: String
  let caption: String?
  let error: String?
  let limit: Int?
  let kind: Kind
  let loading: Bool
  @FocusState private var focused: Bool

  public init(label: String? = nil, placeholder: String = "", text: Binding<String>,
              caption: String? = nil, error: String? = nil, limit: Int? = nil,
              kind: Kind = .prose, loading: Bool = false) {
    self.label = label; self.placeholder = placeholder; _text = text
    self.caption = caption; self.error = error; self.limit = limit
    self.kind = kind; self.loading = loading
  }

  /// The shipped positional form, kept so ~20 call sites keep working while
  /// their surfaces are rewritten. **Removed in Wave 8 (propagate)**, when the
  /// last of them has taken the label/caption/error family.
  public init(_ placeholder: String, text: Binding<String>, font: Font = CSType.body) {
    self.init(placeholder: placeholder, text: text,
              kind: font == CSType.column || font == CSType.columnM ? .code : .prose)
  }

  private var counterShows: Bool {
    guard let limit else { return false }
    return Double(text.count) >= Double(limit) * 0.8
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      if let label {
        Text(label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
      }
      TextField(placeholder, text: $text)
        .csType(kind == .code ? .column : .body)
        .foregroundStyle(enabled ? cs.ink : cs.mut)
        .padding(.horizontal, CSTokens.Space.s3)
        .frame(minHeight: 50)
        .background(enabled ? cs.bg2 : cs.bg1,
                    in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay {
          // the ONE outline a field is allowed: the focus ring
          if focused {
            RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous)
              .stroke(cs.brand, lineWidth: 2)
          }
        }
        .overlay(alignment: .trailing) {
          if loading { CSTallyDots(tint: cs.mut).padding(.trailing, CSTokens.Space.s3) }
        }
        .focused($focused)
      HStack(alignment: .top) {
        if let error {
          Text(error).csType(.bodyS).foregroundStyle(cs.neg)
        } else if let caption {
          Text(caption).csType(.bodyS).foregroundStyle(cs.mut)
        }
        if counterShows, let limit {
          Spacer(minLength: CSTokens.Space.s2)
          Text("\(text.count)/\(limit)").csType(.agateS, caps: true)
            .foregroundStyle(text.count >= limit ? cs.neg : cs.mut)
        }
      }
    }
  }
}

// MARK: - The stepper

/// 44pt, `bg2`, value in `figure` 20, **bare — no ring and no box**.
///
/// §9.4: the score mark and the input are not the same object. A circled
/// numeral between a − and a + reads as *selected*, not as a birdie — so the
/// paper convention and the selection convention would be one shape. The
/// field is the numeral's own underline.
public struct CSStepper: View {
  @Environment(\.cs) private var cs
  let value: Int
  let range: ClosedRange<Int>
  let label: String
  let onChange: (Int) -> Void
  public init(value: Int, range: ClosedRange<Int> = 1...15, label: String, onChange: @escaping (Int) -> Void) {
    self.value = value; self.range = range; self.label = label; self.onChange = onChange
  }
  public var body: some View {
    HStack(spacing: 0) {
      step("−", to: value - 1)
      Text("\(value)").csType(.figureS).foregroundStyle(cs.ink)
        .frame(minWidth: 44)
      step("+", to: value + 1)
    }
    .frame(minHeight: 44)
    .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
    .accessibilityValue("\(value)")
    .accessibilityAdjustableAction { d in
      onChange(min(range.upperBound, max(range.lowerBound, value + (d == .increment ? 1 : -1))))
    }
  }
  private func step(_ glyph: String, to next: Int) -> some View {
    Button { CSHaptic.selection(); onChange(min(range.upperBound, max(range.lowerBound, next))) } label: {
      Text(glyph).csType(.figureS).foregroundStyle(cs.mut).frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!range.contains(next))
    .accessibilityHidden(true)
  }
}

// MARK: - The door

/// A primary, a secondary or a tertiary link — P-8's one shape. A dead end
/// becomes a next move, and the tier says how consequential the move is.
public struct CSDoor: View {
  public enum Kind {
    case primary(String, () -> Void)
    case secondary(String, () -> Void)
    case link(String, () -> Void)
    /// The tertiary at `.live`: a 2px `brand` rule, and it is the screen's ONE
    /// live act. Home's lead uses it while a clock is running and drops to
    /// `.link` the moment nothing is (§1.5's one-ember rule) — the tier is the
    /// door's, so the page never hand-paints an underline to say "now".
    case liveLink(String, () -> Void)
  }
  let kind: Kind
  public init(_ kind: Kind) { self.kind = kind }
  public var body: some View {
    switch kind {
    case .primary(let t, let a): Button(t, action: a).buttonStyle(.csPrimary)
    case .secondary(let t, let a): Button(t, action: a).buttonStyle(.csSecondary)
    case .link(let t, let a): Button(t, action: a).buttonStyle(.csTertiary(.content))
    case .liveLink(let t, let a): Button(t, action: a).buttonStyle(.csTertiary(.live))
    }
  }
}

// MARK: - The door row

/// **A VERB AND ITS GLOSS ON ONE 48pt ROW** — the product's page-foot grammar,
/// and the shape a list of acts takes when it is not a stack of buttons.
///
/// Four tracked-caps text links in two ragged columns (audit H-07, *"buttons
/// that look like links"*) become a verb in `nameS` caps at the leading edge
/// and one line of `agateS` flush right, separated by rules. At most one row
/// in a foot is ever lit, and **the lit state is a 2px `brand` rule under the
/// verb** — the verb itself never changes colour, because a control that
/// changes colour to mean *recommended* is a control wearing state (§7).
///
/// It lived three times in `HomeFacts.swift` — the floor's row, the
/// first-round row, and the floor's collapsed row — with the second carrying
/// the comment *"drawn in the floor's own grammar so the page has one row
/// shape and not two"*, which is the argument for this type existing. Compete
/// is the fourth caller (D286).
///
/// **AND IT IS THE PAGE'S AX5 SHEAR IF THE VERB HOLDS ITS LINE.** The verb
/// carried `fixedSize(horizontal: true)` so its ember rule would stop at the
/// end of the word — right at the reading sizes, and at AX5 `Start something`
/// in `nameS` measures more than the phone, refuses to shrink, and makes the
/// whole page 466pt wide. A vertical `ScrollView` then centres a content box
/// wider than itself and every block on the page slides left. At the
/// accessibility sizes the row becomes a COLUMN: the verb takes the measure
/// (so its rule does too, which is the same lit state) and the gloss sets
/// under it flush left instead of fighting it for the line (§16.3).
public struct CSDoorRow: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let verb: String
  let gloss: String
  let lit: Bool
  /// nil for a row that STATES rather than opens — the brand-new Home's three
  /// facts about the product. It then carries no button trait and no hit area.
  let action: (() -> Void)?

  public init(verb: String, gloss: String, lit: Bool = false, action: (() -> Void)? = nil) {
    self.verb = verb; self.gloss = gloss; self.lit = lit; self.action = action
  }

  public var body: some View {
    Group {
      if let action {
        Button(action: action) { line }
          .buttonStyle(.plain)
          .accessibilityAddTraits(.isButton)
      } else {
        line
      }
    }
    .csBudget(ember: lit ? 1 : 0)
    // VoiceOver reads a tracked all-caps verb letter by letter; give it the
    // sentence, with the gloss folded in (§7).
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(verb). \(gloss)")
  }

  private var line: some View {
    A11yStack(rowAlignment: .firstTextBaseline,
              spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s2) {
      VStack(alignment: .leading, spacing: 3) {
        Text(verb).csType(.nameS).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
        Rectangle().fill(lit ? cs.brand : Color.clear).frame(height: 2)
      }
      .fixedSize(horizontal: !typeSize.isA11y, vertical: false)
      if !typeSize.isA11y { Spacer(minLength: CSTokens.Space.s3) }
      Text(gloss).csType(.agateS, caps: false).foregroundStyle(cs.mut)
        .multilineTextAlignment(typeSize.isA11y ? .leading : .trailing)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, CSTokens.Space.s3)
    .frame(minHeight: 48)
    .contentShape(Rectangle())
  }
}

// MARK: - Dismiss, said once

public extension View {
  /// **Dismiss is one thing: `Close`** — a TOOLBAR tertiary at
  /// `topBarTrailing`, `mut`, 1px rule, never ember, in every sheet and every
  /// cover. No xmark circle, no coloured "Done" (`LINT-25`). The confirming
  /// action lives in the body, at the foot, as the sheet's one primary: a
  /// sheet's loudest control is never the one that closes it.
  func csCloseButton(_ dismiss: @escaping () -> Void) -> some View {
    toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Close", action: dismiss)
          .buttonStyle(.csTertiary(.toolbar))

      }
    }
  }
}
