// Cup Season — the small grammar this slice shares between the receipt, the
// You tab and the Tour Card: the sheet frame (`openSheet(title, sub, body)`),
// the `.check` row, the `.mathrow`, the `.mini` pill, the `.cred` face, and a
// toast that outlives the sheet that raised it.

import SwiftUI
import CSDesign
import CupSeasonKit

// MARK: - Toast (bottom pill, ink on bg0, rolls out)

/// One toast lane for the app: a sheet can dismiss itself and still leave its
/// line behind ("Muted. Their posts drop off your boards.").
@MainActor
@Observable
final class ToastCenter {
  static let shared = ToastCenter()
  private(set) var message: String?
  private var gen = 0
  func show(_ text: String) {
    gen += 1
    let g = gen
    message = text
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(2.6))
      if g == gen { message = nil }
    }
  }
}

private struct ToastHostModifier: ViewModifier {
  @Environment(\.cs) private var cs
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let center = ToastCenter.shared
  func body(content: Content) -> some View {
    content.overlay(alignment: .bottom) {
      if let m = center.message {
        Text(m)
          .csType(.body).foregroundStyle(cs.ink)
          .padding(.horizontal, 16).padding(.vertical, 11)
          .background(cs.bg0, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
          .padding(.bottom, 20).padding(.horizontal, 24)
          .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
          .accessibilityAddTraits(.updatesFrequently)
      }
    }
    .csAnimation(CSMotion.roll, value: center.message)
  }
}

extension View {
  /// Mount once per screen that can raise a toast.
  func sliceToastHost() -> some View { modifier(ToastHostModifier()) }
}

// MARK: - Sheet frame

/// The web's `openSheet(title, sub, body)`: a title, a mono sub, a body.
struct SliceSheet<Content: View>: View {
  @Environment(\.cs) private var cs
  let title: String
  let sub: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(title).csType(.displayS).foregroundStyle(cs.ink)
          if !sub.isEmpty { Text(sub).csType(.agateS).foregroundStyle(cs.mut) }
        }
        .padding(.bottom, 4)
        content()
      }
      .padding(20).padding(.top, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(cs.bg0)
    .presentationDragIndicator(.visible)
    .presentationBackground(cs.bg0)
    .sliceToastHost()
  }
}

// MARK: - .check row

/// `.check`: a 26pt mono glyph cell · bold title · mono small sub · trailing.
///
/// D326 · the glyph cell is GENERIC and OPTIONAL. It used to be `Text`, which
/// meant a row's mark could only ever be a typed character — so a drawn marker
/// could not sit in it, and "no mark at all" could only be spelled as an empty
/// box with a background still painted around it. Both are now expressible: a
/// `Text`, any view (a `CSMarkerView`), or nothing, in which case the cell is
/// not drawn rather than drawn empty.
struct CheckRow<Glyph: View, Trailing: View>: View {
  @Environment(\.cs) private var cs
  let glyph: Glyph
  /// false = the row has no mark, and the 26pt cell is not laid out at all.
  let showsGlyph: Bool
  let title: String
  let sub: String?
  let subColor: Color?
  @ViewBuilder let trailing: () -> Trailing

  init(glyph: Glyph, title: String, sub: String?, subColor: Color? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
    self.glyph = glyph; self.showsGlyph = true
    self.title = title; self.sub = sub; self.subColor = subColor; self.trailing = trailing
  }

  var body: some View {
    // glyph + text across; the trailing control drops under them at the accessibility sizes
    A11yStack(spacing: 12, columnSpacing: 8) {
      HStack(spacing: 12) {
        if showsGlyph {
          glyph
            .csType(.columnS).foregroundStyle(cs.mut)
            .frame(minWidth: 26, minHeight: 26)
            .padding(.horizontal, 2)
            .background(cs.bg2, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
        }
        VStack(alignment: .leading, spacing: 2) {
          Text(title).csType(.name).foregroundStyle(cs.ink)
          if let sub, !sub.isEmpty { Text(sub).csType(.agateS).foregroundStyle(subColor ?? cs.mut) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      trailing()
    }
    .padding(.horizontal, 14).padding(.vertical, 13)
    .frame(minHeight: 44)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
  }
}

extension CheckRow where Trailing == CSGlyph {
  /// The door: the DRAWN chevron, not a typed `→` (`LINT-13`, §5.2).
  init(glyph: Glyph, title: String, sub: String?) {
    self.init(glyph: glyph, title: title, sub: sub) { CSGlyph(.chevron, size: .inline) }
  }
}

extension CheckRow where Glyph == EmptyView {
  /// D326 · a row whose fact leads. No cell, no empty background box.
  init(title: String, sub: String?, subColor: Color? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
    self.glyph = EmptyView(); self.showsGlyph = false
    self.title = title; self.sub = sub; self.subColor = subColor; self.trailing = trailing
  }
}

/// A tappable `.check` door (44pt target, whole row).
struct CheckDoor: View {
  @Environment(\.cs) private var cs
  let glyph: Text
  let title: String
  let sub: String?
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      CheckRow(glyph: glyph, title: title, sub: sub) { CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut) }
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
  }
}

// MARK: - .mathrow

/// `.mathrow`: label left, bold value right; `sub` is the quieter arithmetic tier.
struct MathRow: View {
  @Environment(\.cs) private var cs
  let label: String
  let value: String
  var sub = false
  var tone: Color? = nil
  @Environment(\.dynamicTypeSize) private var typeSize
  var body: some View {
    A11yStack(rowAlignment: .firstTextBaseline, spacing: 10, columnSpacing: 2) {
      Text(label).font(sub ? CSFont.monoSmall : CSFont.subhead).foregroundStyle(cs.mut)
      Spacer(minLength: 8)
      Text(value)
        .font(sub ? CSFont.monoMediumBody : CSFont.subhead.weight(.semibold))
        .foregroundStyle(tone ?? (sub ? cs.mut : cs.ink))
        .multilineTextAlignment(typeSize.isA11y ? .leading : .trailing)
    }
    .padding(.vertical, sub ? 7 : 9)
    .overlay(alignment: .top) { Rectangle().fill(cs.rule).frame(height: 1) }
    .accessibilityElement(children: .combine)
  }
}

// MARK: - .mini pill

/// `.mini`: mono, bg2, line2 border, 36pt+.
struct MiniButton: View {
  @Environment(\.cs) private var cs
  let label: String
  var tone: Color? = nil
  var busy = false
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(label).csType(.nameS).foregroundStyle(tone ?? cs.ink)
        .padding(.horizontal, 14).frame(minHeight: 44)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .opacity(busy ? 0.5 : 1)
    }
    .buttonStyle(.plain)
    .disabled(busy)
  }
}

// MARK: - Fine print

/// `.fine`: 13px, the muted tier, 1.6 line height.
struct Fine: View {
  @Environment(\.cs) private var cs
  let text: Text
  init(_ s: String) { text = Text(s) }
  init(markdown s: String) { text = Text((try? AttributedString(markdown: s)) ?? AttributedString(s)) }
  var body: some View {
    text.csType(.body).foregroundStyle(cs.mut).lineSpacing(3)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - the streak tag and the form row (D76 FORM L5)

struct StreakTag: View {
  @Environment(\.cs) private var cs
  let text: String
  let hot: Bool
  var body: some View {
    Text(text).csType(.agateS, caps: true)
      .foregroundStyle(hot ? cs.brand : cs.brand)
      .padding(.horizontal, 5).padding(.vertical, 1)
      .overlay(RoundedRectangle(cornerRadius: 4).stroke(hot ? cs.brand : cs.brand, lineWidth: 1))
  }
}

/// `.cform` on the credential: "FORM" · five dots oldest→newest · the streak tag.
///
/// `caption` is the dots' visible key (Y-08). Every caller takes it from the
/// one producer (`YouCopy.formKey` / `YouCopy.formKeyCard`) so the sentence
/// has ONE home; the credential passes the CARD's short form, in the person
/// that card is about — it can be somebody else's, and "your playing number"
/// would be a lie on it.
struct FormRowView: View {
  let form: FormRow
  let palette: CSPalette
  var caption: String? = nil
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      dots
      if let caption {
        Text(caption).csType(.bodyS).foregroundStyle(palette.mut)
      }
    }
  }

  private var dots: some View {
    HStack(spacing: 6) {
      // F-14 · TERMINOLOGY line 90 rules the row's label: a dot row with no
      // label is a puzzle, and FORM was the puzzle's name.
      Text("LAST FIVE").csType(.agateS, caps: true).foregroundStyle(palette.mut).padding(.trailing, 2)
      ForEach(Array(form.dots.enumerated()), id: \.offset) { _, on in
        Circle()
          .fill(on == true ? palette.brand : palette.ink.opacity(0.14))
          .frame(width: 9, height: 9)
          .shadow(color: on == true ? palette.brand.opacity(0.55) : .clear, radius: 3.5)
      }
      if let tag = form.tag { StreakTag(text: tag, hot: form.hot).padding(.leading, 4).environment(\.cs, palette) }
    }
    .padding(.top, 14)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(form.accessibilityLabel)
  }
}

// MARK: - the marker medallion on a photo (`.mkstamp`, D59)

struct MarkerStamp: View {
  @Environment(\.cs) private var cs
  let marker: String?
  var body: some View {
    CSMarkerView(key: marker, size: 15, lineWidth: 2)
      .foregroundStyle(cs.ink)
      .frame(width: 26, height: 26)
      .background(cs.bg0.opacity(0.55), in: Circle())
      .padding(10)
      .accessibilityHidden(true)
  }
}

// MARK: - helpers

enum SliceFormat {
  /// A JSON number as the web prints it raw: "9" or "9.1".
  static func raw(_ v: Double?) -> String { CSCopy.points(v) }
  /// `humanError(e, fallback)`.
  static func human(_ e: Error, _ fallback: String) -> String { AuthRules.human(e, fallback: fallback) }
}
