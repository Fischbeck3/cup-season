// Cup Season — the small parts the three pricing cards share (IOS-021 / D56).
//
// Three cards, one flag, no checkout. Everything here takes `PricingFlags` as
// a value — no view reads the network; the host screen loads the flag once
// (`PricingFlags.load()`) and passes it down. Colour laws (plan §0): the pass
// never wears gold — plain ink numerals; the Founding badge is the ONE gold
// thing here, because it is earned. The "first season is free" line is `pos`
// (semantic: in your favour).

import SwiftUI
import CSDesign
import CupSeasonKit

/// A line of copy with `**bold**` runs, in the fine-print voice by default.
struct PricingMarkdown: View {
  @Environment(\.cs) private var cs
  let text: String
  var font: Font = CSFont.footnote
  var color: Color? = nil
  init(_ text: String, font: Font = CSFont.footnote, color: Color? = nil) { self.text = text; self.font = font; self.color = color }
  var body: some View {
    Text((try? AttributedString(markdown: text)) ?? AttributedString(text))
      .font(font)
      .foregroundStyle(color ?? cs.dimText)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// `★ FOUNDING LEAGUE № n` — gold, earned, the only gold on any pricing surface.
struct PricingFoundingBadge: View {
  @Environment(\.cs) private var cs
  let number: Int
  var body: some View {
    Text("★ FOUNDING LEAGUE № \(number)")
      .font(CSFont.label).tracking(1.2).foregroundStyle(cs.gold)
      .padding(.horizontal, 8).padding(.vertical, 4)
      .overlay(Capsule().stroke(cs.gold.opacity(0.6), lineWidth: 1))
      .accessibilityLabel("Founding League, number \(number)")
  }
}

/// A fact chip: mono, raised ground, no colour of its own.
struct PricingChip: View {
  @Environment(\.cs) private var cs
  let text: String
  init(_ text: String) { self.text = text }
  var body: some View {
    Text(text).font(CSFont.monoSmall).foregroundStyle(cs.ink)
      .padding(.horizontal, 10).padding(.vertical, 6)
      .background(cs.bg2, in: Capsule())
      .overlay(Capsule().stroke(cs.line2, lineWidth: 1))
  }
}

/// Chips that wrap instead of clipping at the phone's width.
struct PricingChipRow: View {
  let chips: [String]
  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 6)], alignment: .leading, spacing: 6) {
      ForEach(chips, id: \.self) { PricingChip($0) }
    }
  }
}

/// The green line every launch surface leads with (plan §0: "first-season-free
/// leads every surface"): a tick and a sentence, `pos`, on a `pos` wash.
struct PricingFreeLine: View {
  @Environment(\.cs) private var cs
  let text: String
  init(_ text: String) { self.text = text }
  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text("✓").font(CSFont.monoMediumBody).foregroundStyle(cs.pos)
      PricingMarkdown(text, font: CSFont.subhead, color: cs.pos)
    }
    .padding(.horizontal, 12).padding(.vertical, 10)
    .background(cs.pos.opacity(0.10), in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .accessibilityElement(children: .combine)
  }
}

/// Calendar dates by parts (Dates.swift) — never an ISO parser.
enum PricingDate {
  /// "Sep 26, 2026" — a paid-through or season-end date, year kept.
  static func long(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso }
    let f = DateFormatter(); f.calendar = calendar
    f.setLocalizedDateFormatFromTemplate("MMM d yyyy")
    return f.string(from: d)
  }
}

// MARK: - Preview fixtures (nothing here reaches the network)

enum PricingSample {
  static let pigl = UUID(uuidString: "5c1e8b2e-2a4b-4b1e-9d3f-0a1b2c3d4e5f")!
  static let other = UUID(uuidString: "0d2f7c1a-6b3e-4a9c-8e1f-2b3c4d5e6f70")!

  /// The plan's seed, switch ON.
  static let visible = PricingFlags.seed
  /// The same, with PIGL as Founding League № 1.
  static let founding = PricingFlags(visible: true, anchorCents: PricingFlags.defaultAnchorCents, bands: PricingFlags.defaultBands,
                                     season1Free: true, founding: .init(cap: 10, closed: false, ids: [pigl.uuidString.lowercased(): 1]))

  /// A membership row as `native_home()` would hand it over — decoded from
  /// JSON because `Me.Membership` has no memberwise init outside the Kit.
  static func membership(id: UUID = other, name: String = "The Back Nine", role: String = "commissioner",
                         seasonNumber: Int = 1, endsOn: String = "2026-09-26") -> Me.Membership {
    let json = """
    {"league_id": "\(id.uuidString)", "name": "\(name)", "code": "ABCD", "phase": "season", "role": "\(role)",
     "member_id": "\(UUID().uuidString)", "commissioner_name": "Jerecho",
     "season": {"id": "\(UUID().uuidString)", "number": \(seasonNumber), "starts_on": "2026-05-03", "ends_on": "\(endsOn)", "status": "active"}}
    """
    // A fixture, not a path: the shape above is the contract's own, so a
    // failure here is a build-time fact, not a runtime one.
    return try! JSONDecoder().decode(Me.Membership.self, from: Data(json.utf8))
  }
}

/// One preview frame, one colour scheme — every card previews in both.
struct PricingPreview<Content: View>: View {
  let scheme: ColorScheme
  let content: Content
  init(_ scheme: ColorScheme, @ViewBuilder content: () -> Content) { self.scheme = scheme; self.content = content() }
  var body: some View {
    let palette = scheme == .light ? CSTokens.light : CSTokens.dark
    ScrollView { content.padding(20) }
      .background(palette.bg0)
      .environment(\.cs, palette)
      .environment(\.colorScheme, scheme)
  }
}
