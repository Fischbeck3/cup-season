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
          .font(CSFont.subhead).foregroundStyle(cs.ink)
          .padding(.horizontal, 16).padding(.vertical, 11)
          .background(cs.bg0, in: Capsule())
          .overlay(Capsule().stroke(cs.line2, lineWidth: 1))
          .padding(.bottom, 20).padding(.horizontal, 24)
          .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
          .accessibilityAddTraits(.updatesFrequently)
      }
    }
    .animation(.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.32), value: center.message)
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
          Text(title).font(CSFont.title).foregroundStyle(cs.ink)
          if !sub.isEmpty { Text(sub).font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText) }
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
struct CheckRow<Trailing: View>: View {
  @Environment(\.cs) private var cs
  let glyph: Text
  let title: String
  let sub: String?
  let subColor: Color?
  @ViewBuilder let trailing: () -> Trailing

  init(glyph: Text, title: String, sub: String?, subColor: Color? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
    self.glyph = glyph; self.title = title; self.sub = sub; self.subColor = subColor; self.trailing = trailing
  }

  var body: some View {
    // glyph + text across; the trailing control drops under them at the accessibility sizes
    A11yStack(spacing: 12, columnSpacing: 8) {
      HStack(spacing: 12) {
        glyph
          .font(CSFont.monoSmall).foregroundStyle(cs.mut)
          .frame(minWidth: 26, minHeight: 26)
          .padding(.horizontal, 2)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(cs.line2, lineWidth: 1))
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 2) {
          Text(title).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
          if let sub, !sub.isEmpty { Text(sub).font(CSFont.label).tracking(0.8).foregroundStyle(subColor ?? cs.dimText) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      trailing()
    }
    .padding(.horizontal, 14).padding(.vertical, 13)
    .frame(minHeight: 44)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(cs.line, lineWidth: 1))
  }
}

extension CheckRow where Trailing == Text {
  /// The `→` door.
  init(glyph: Text, title: String, sub: String?) {
    self.init(glyph: glyph, title: title, sub: sub) { Text("→") }
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
      CheckRow(glyph: glyph, title: title, sub: sub) { Text("→").font(CSFont.subhead).foregroundStyle(cs.dimText) }
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
      Text(label).font(sub ? CSFont.monoSmall : CSFont.subhead).foregroundStyle(cs.dimText)
      Spacer(minLength: 8)
      Text(value)
        .font(sub ? CSFont.monoMediumBody : CSFont.subhead.weight(.semibold))
        .foregroundStyle(tone ?? (sub ? cs.mut : cs.ink))
        .multilineTextAlignment(typeSize.isA11y ? .leading : .trailing)
    }
    .padding(.vertical, sub ? 7 : 9)
    .overlay(alignment: .top) { Rectangle().fill(cs.line).frame(height: 1) }
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
      Text(label).font(CSFont.monoMediumBody).foregroundStyle(tone ?? cs.ink)
        .padding(.horizontal, 14).frame(minHeight: 44)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
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
    text.font(CSFont.subhead).foregroundStyle(cs.dimText).lineSpacing(3)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - the streak tag and the form row (D76 FORM L5)

struct StreakTag: View {
  @Environment(\.cs) private var cs
  let text: String
  let hot: Bool
  var body: some View {
    Text(text).font(CSFont.label).tracking(0.8)
      .foregroundStyle(hot ? cs.hot : cs.warm)
      .padding(.horizontal, 5).padding(.vertical, 1)
      .overlay(RoundedRectangle(cornerRadius: 4).stroke(hot ? cs.hot : cs.warm, lineWidth: 1))
  }
}

/// `.cform` on the credential: "FORM" · five dots oldest→newest · the streak tag.
struct FormRowView: View {
  let form: FormRow
  let palette: CSPalette
  var body: some View {
    HStack(spacing: 6) {
      Text("FORM").font(CSFont.label).tracking(1.6).foregroundStyle(palette.mut).padding(.trailing, 2)
      ForEach(Array(form.dots.enumerated()), id: \.offset) { _, on in
        Circle()
          .fill(on == true ? palette.hot : palette.ink.opacity(0.14))
          .frame(width: 9, height: 9)
          .shadow(color: on == true ? palette.hot.opacity(0.55) : .clear, radius: 3.5)
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
