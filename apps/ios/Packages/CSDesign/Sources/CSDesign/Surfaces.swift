// Cup Season — how surfaces sit (IOS-019).
//
// Depth from ground, not from borders. One hero per screen wears the wash;
// the page header lives in the scroll; sections are an eyebrow and a
// hairline; panes are a tab strip with an ember underline. Every colour here
// is a token at an opacity — nothing is invented (preflight 15).

import SwiftUI

// MARK: - The wash

/// A radial of the spine colour, ≤14% at the top-leading corner, fading to
/// nothing. Ember = live, gold = earned, `pos` = on the tee, dusk = ceremony.
/// Exactly one per screen.
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
public struct CSHero<Content: View>: View {
  @Environment(\.cs) private var cs
  let spine: Color
  let padding: CGFloat
  let content: Content
  public init(spine: Color, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
    self.spine = spine; self.padding = padding; self.content = content()
  }
  public var body: some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        ZStack {
          RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(cs.bg1)
          CSWash(spine)
        }
        .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      }
      .overlay(alignment: .leading) {
        RoundedRectangle(cornerRadius: 2).fill(spine).frame(width: 3.5).padding(.vertical, 14)
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

/// The gradient tick, a serif title, an optional mono eyebrow on the right.
/// Lives in the scroll so the glass toolbar never clips it.
public struct CSPageHeader: View {
  @Environment(\.cs) private var cs
  let title: String
  let eyebrow: String?
  let sub: String?
  public init(_ title: String, eyebrow: String? = nil, sub: String? = nil) {
    self.title = title; self.eyebrow = eyebrow; self.sub = sub
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .lastTextBaseline) {
        VStack(alignment: .leading, spacing: 8) {
          Rectangle().fill(LinearGradient(colors: CSTokens.gradStops, startPoint: .leading, endPoint: .trailing))
            .frame(width: 28, height: 3)
          Text(title).font(CSFont.heroSmall).foregroundStyle(cs.ink).lineLimit(2).minimumScaleFactor(0.8)
        }
        Spacer(minLength: 8)
        if let eyebrow { Text(eyebrow).csEyebrow() }
      }
      if let sub { Text(sub).font(CSFont.sentence).foregroundStyle(cs.mut) }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
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

/// An eyebrow over a hairline, with an optional trailing link in `dawn`.
public struct CSSectionHead: View {
  @Environment(\.cs) private var cs
  let title: String
  let trailing: String?
  let action: (() -> Void)?
  public init(_ title: String, trailing: String? = nil, action: (() -> Void)? = nil) {
    self.title = title; self.trailing = trailing; self.action = action
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        Text(title).csEyebrow()
        Spacer()
        if let trailing {
          if let action {
            Button(action: action) { Text(trailing).csEyebrow(cs.dawn) }.buttonStyle(.plain)
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

/// Panes: mono uppercase labels, an ember underline that slides on the roll.
public struct CSTabStrip<T: Hashable>: View {
  @Environment(\.cs) private var cs
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
            withAnimation(CSMotion.roll) { selection = key }
            CSHaptic.selection()
          } label: {
            VStack(spacing: 8) {
              Text(label).font(CSFont.eyebrow).tracking(1.4).textCase(.uppercase)
                .foregroundStyle(on ? cs.ink : cs.mut)
              ZStack {
                Rectangle().fill(.clear).frame(height: 2)
                if on {
                  Rectangle().fill(cs.brand).frame(height: 2)
                    .matchedGeometryEffect(id: "underline", in: ns)
                }
              }
            }
            .padding(.horizontal, 12).padding(.top, 8)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(on ? [.isSelected] : [])
        }
      }
    }
    .overlay(alignment: .bottom) { CSHairline() }
  }
}

// MARK: - Motion

/// The roll: `cubic-bezier(.16,.84,.36,1)` — fast start, long soft settle.
public enum CSMotion {
  public static let roll = Animation.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.32)
  public static let rise = Animation.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.26)
}
