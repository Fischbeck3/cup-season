// Cup Season — a person is drawn exactly ONE way (D271, UI_SYSTEM §6).
//
// `CSFace` is the only legal path. The bare-glyph path — `FriendsBoard.swift`
// and five siblings — is deleted, not patched, because it is the reason a
// golfer with a photograph structurally could not show it on the people tab.
//
// THE MARKER IS A FROZEN PAIR. `(pigment, glyph)` is resolved ONCE from the
// profile row and never re-derived per surface, per theme, per size or per
// component. All three blind reviewers filed the same class of defect and two
// called it a brand failure rather than a bug: "Galen's marker is brown here
// and maroon there"; "Sam carries a tee here and a cactus on his own card". A
// marker that drifts is not an identity system; it is decoration that happens
// to be circular.
//
// AND THERE IS NO INITIALS RUNG. The marker IS the floor. Initials draw only
// when a golfer chose nothing — which is visibly different from choosing the
// Saguaro, and is neither a silhouette nor a fabricated face.

import SwiftUI

public struct CSFace: View {
  /// Resolved once, from the profile row.
  public struct Model: Hashable, Sendable {
    public let id: UUID
    /// The glyph key — frozen. `nil` means the golfer chose nothing.
    public let marker: String?
    public let photoURL: URL?
    /// Drawn ONLY when `marker == nil`.
    public let initials: String
    /// The viewer's own mark takes `ink` rather than `mut`.
    public let isViewer: Bool

    public init(id: UUID, marker: String?, photoURL: URL? = nil,
                initials: String = "", isViewer: Bool = false) {
      self.id = id; self.marker = marker; self.photoURL = photoURL
      self.initials = initials; self.isViewer = isViewer
    }

    /// **The pigment index, and it must not move between launches.**
    ///
    /// `Hashable.hashValue` in Swift is seeded per PROCESS, so `hash(id) % 6`
    /// would give a golfer one pigment this morning and another this afternoon
    /// — the exact drift §6.2a exists to forbid, arriving through the one line
    /// that looks most like the spec. This is FNV-1a over the UUID's sixteen
    /// bytes: same id, same pigment, every launch, every device, both themes.
    public var pigmentIndex: Int {
      var h: UInt64 = 0xcbf29ce484222325
      withUnsafeBytes(of: id.uuid) { raw in
        for byte in raw { h = (h ^ UInt64(byte)) &* 0x100000001b3 }
      }
      return Int(h % 6)
    }

    /// **A face drawn before its surface has plumbed the profile id through.**
    ///
    /// §6.2a keys the pigment to the GOLFER, so that two Saguaros in one list
    /// become two different coins. Four shipped call sites — the two person
    /// rows in `People/Links.swift`, the scheduled round's comment list and the
    /// upcoming-rounds row — receive a marker string and no id, and plumbing
    /// one through means changing their view models and every caller of those
    /// rows, which is the surface work of **Waves 1, 3 and 8**.
    ///
    /// Until then those four seat the golfer on a pigment derived from the
    /// MARKER KEY. The consequence is stated rather than hidden: two golfers
    /// who both chose the Lone Tree get the same pigment there, which is the
    /// one thing pigments exist to prevent. It is deterministic, it is frozen,
    /// and `LINT-31` counts the call sites and fails on a rise, so the debt
    /// ratchets to zero instead of spreading.
    public static func unkeyed(marker: String?, photoURL: URL? = nil, initials: String = "") -> Model {
      var h: UInt64 = 0xcbf29ce484222325
      for b in Array((marker ?? "saguaro").utf8) { h = (h ^ UInt64(b)) &* 0x100000001b3 }
      let hi = h.byteSwapped
      let bytes = withUnsafeBytes(of: (h, hi)) { Array($0) }
      let u = UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                          bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
      return Model(id: u, marker: marker, photoURL: photoURL, initials: initials)
    }

    public func pigment(_ p: CSPalette) -> Color {
      switch pigmentIndex {
      case 0: p.pig0
      case 1: p.pig1
      case 2: p.pig2
      case 3: p.pig3
      case 4: p.pig4
      default: p.pig5
      }
    }
  }

  /// Five sizes, tokenised. Nothing draws a person at any other diameter.
  public enum Size: CGFloat, Sendable {
    case inline = 24, slat = 30, list = 38, block = 56, crest = 120
  }

  @Environment(\.cs) private var cs
  @Environment(\.colorScheme) private var scheme
  public let model: Model
  public let size: Size
  /// 2.5pt, **team events only** — the side a golfer is playing for. It is the
  /// one thing allowed to ring a face, and squad colour never touches the disc
  /// itself: the disc's job is WHICH PERSON.
  public let sideRing: Color?
  /// The person's name, for VoiceOver — the face's one word. `nil` = silent,
  /// because the name sits beside it in the row. It never names the marker: a
  /// golfer is "Maya", never "Acorn".
  public let name: String?

  public init(_ model: Model, size: Size, sideRing: Color? = nil, name: String? = nil) {
    self.model = model; self.size = size; self.sideRing = sideRing; self.name = name
  }

  private var d: CGFloat { size.rawValue }

  /// On cream stock the glyph takes `ink`, never `mut`: the pale tints are
  /// ~0.90 relative luminance and a `mut` stroke on them measured
  /// near-invisible in the light renders. The viewer's own mark takes `ink` in
  /// both printings.
  private var glyphInk: Color { (scheme == .light || model.isViewer) ? cs.ink : cs.mut }

  public var body: some View {
    ZStack {
      if let url = model.photoURL {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let img): img.resizable().scaledToFill()
          default: disc
          }
        }
        .frame(width: d, height: d)
        .clipShape(Circle())
      } else {
        disc
      }
    }
    .frame(width: d, height: d)
    // the 1px inset ring — a ring on a circle, not a box, and one of the four
    // outlines the system permits at all
    .overlay(Circle().inset(by: 0.5).stroke(cs.rule, lineWidth: CSTokens.Space.hair))
    .overlay {
      if let sideRing { Circle().inset(by: -1.5).stroke(sideRing, lineWidth: 2.5) }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(name ?? "")
    .accessibilityHidden(name == nil)
  }

  private var disc: some View {
    ZStack {
      Circle().fill(model.pigment(cs))
      if let key = model.marker {
        CSMarkerView(key: key, size: d * 0.55, lineWidth: 1.8, optical: true)
          .foregroundStyle(glyphInk)
      } else if !model.initials.isEmpty {
        // "chose nothing" — not a silhouette, not a fabricated face, and
        // visibly different from "chose the Saguaro"
        Text(model.initials)
          .font(.custom(CSType.boardSemi, fixedSize: d * 0.40))
          .tracking(d * 0.40 * CSTokens.Track.caps)
          .foregroundStyle(cs.ink)
      }
    }
  }
}

// MARK: - A row of people

/// Overlapping is a **group**; spaced with names is a **roster**. Each is used
/// where it is true, which is what stops "who of yours has played it" and "the
/// event's field" from being the same picture of two different facts.
public struct CSFaceRow: View {
  @Environment(\.cs) private var cs
  public enum Style: Sendable { case overlapped, roster }
  let faces: [CSFace.Model]
  let style: Style
  let names: [String]
  let size: CSFace.Size

  public init(_ faces: [CSFace.Model], style: Style, names: [String] = [], size: CSFace.Size = .list) {
    self.faces = faces; self.style = style; self.names = names; self.size = size
  }

  public var body: some View {
    switch style {
    case .overlapped:
      HStack(spacing: -12) {
        ForEach(Array(faces.enumerated()), id: \.offset) { _, f in
          CSFace(f, size: .slat)
            // each disc ringed in the page's ground so the stack reads
            .overlay(Circle().inset(by: -1).stroke(cs.bg0, lineWidth: 2))
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(faces.count) golfers")
    case .roster:
      HStack(alignment: .top, spacing: CSTokens.Space.s3) {
        ForEach(Array(faces.enumerated()), id: \.offset) { i, f in
          VStack(spacing: CSTokens.Space.s2) {
            CSFace(f, size: size)
            if i < names.count {
              Text(names[i]).csType(.agateS, caps: true).foregroundStyle(cs.mut)
                .lineLimit(1)
            }
          }
        }
      }
    }
  }
}

// MARK: - The medallion

/// A disc of the `ceremony` ground carrying the marker in **gold** on a 1px
/// gold ring, notched into the lower-right of any photograph, plate or object
/// the golfer owns.
///
/// It is the one place a marker takes a metal, and it means *this is theirs*.
public struct CSMedallion: View {
  let marker: String?
  let size: CGFloat
  public init(_ marker: String?, size: CGFloat = 44) { self.marker = marker; self.size = size }
  public var body: some View {
    ZStack {
      Circle().fill(CSTokens.dark.ceremony)
      Circle().inset(by: 0.5).stroke(CSTokens.dark.ceremonyGold, lineWidth: CSTokens.Space.hair)
      CSMarkerView(key: marker, size: size * 0.55, lineWidth: 1.8, optical: true)
        .foregroundStyle(CSTokens.dark.ceremonyGold)
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
    .csBudget(gold: 1)
  }
}

// MARK: - The slot

/// A 24pt gold field with `panelInk` agate, for a thing that was **won**:
/// `FOUNDER` · `CHAMPION` · `THE PRO`. One per surface — it *is* the surface's
/// gold object, and when nothing is earned the slot is absent and the card
/// carries no gold at all.
public struct CSSlot: View {
  @Environment(\.cs) private var cs
  let label: String
  let over: CSRule.Ground
  public init(_ label: String, over: CSRule.Ground = .page) { self.label = label; self.over = over }
  public var body: some View {
    Text(label)
      .csType(.agateS, caps: true)
      .foregroundStyle(over == .ceremony ? CSTokens.dark.ceremony : cs.panelInk)
      .padding(.horizontal, CSTokens.Space.s2)
      .frame(height: 24)
      .background(over == .ceremony ? CSTokens.dark.ceremonyGold : cs.gold)
      .csBudget(gold: 1)
  }
}

// MARK: - The folio

/// The rule and the serial line at the foot of an object: `CUP SEASON · THE
/// LONE TREE` flush left, `No. 12` flush right, in `folioRule` — the opaque
/// value `ceremonyInk` at `a56` composites to, **named in `tokens.json` so
/// nothing is invented in Swift** (preflight 15).
public struct CSFolio: View {
  let club: String
  let serial: String
  public init(club: String, serial: String) { self.club = club; self.serial = serial }
  public var body: some View {
    VStack(spacing: CSTokens.Space.s2) {
      Rectangle().fill(CSTokens.dark.ceremonyInk.opacity(CSTokens.Alpha.a16))
        .frame(height: CSTokens.Space.hair)
      HStack {
        Text(club).csType(.agateS, caps: true)
        Spacer(minLength: CSTokens.Space.s2)
        Text(serial).csType(.agateS, caps: true)
      }
      .foregroundStyle(CSTokens.dark.folioRule)
    }
  }
}

// MARK: - The credential

/// **The card.** A collectible object, not a layout — and `UI_SYSTEM` §6.5 is
/// its single anatomy of record. `profile.md` and `player-card.md` both point
/// here rather than restating it, because a second disagreeing anatomy table
/// would reopen the very defect ("one object, two chromes, two aspect ratios")
/// that this closes.
///
/// **362 × 312 (≈ 7:6, landscape), radius `r` 16, `shadow-lift`, ground
/// `ceremony` in every theme.** A 3:4 object at the 362pt measure is 483pt
/// tall, and with the chrome above it the page's ranked action lands below the
/// tab bar on every device. **The 3:4 portrait survives in exactly one place:
/// the share PNG**, which has no fold and no chrome under it.
public struct CSCredential<Plate: View>: View {
  /// Everything the object prints. Wave 2 maps the app's profile onto it; the
  /// object owns its own anatomy so no surface can re-cut it.
  public struct Golfer: Sendable {
    public let face: CSFace.Model
    public let name: String
    /// One string, product-wide: `@GALENM · MESA, AZ · PAPAGO`. Never carries
    /// `EST. JUL 2026` — the founding fact is already the slot and the serial,
    /// and saying it a third time is the defect this closes.
    public let identity: String
    /// `FOUNDER` · `CHAMPION` · `THE PRO`. Absent when nothing is earned.
    public let slot: String?
    /// Replaces the slot while a round is live — the only ember on the card.
    public let liveTag: String?
    /// index · rounds · position, each with its agate label.
    public let figures: [(String, String, String?)]   // value, label, ordinal
    public let club: String
    public let serial: String

    public init(face: CSFace.Model, name: String, identity: String, slot: String? = nil,
                liveTag: String? = nil, figures: [(String, String, String?)],
                club: String, serial: String) {
      self.face = face; self.name = name; self.identity = identity; self.slot = slot
      self.liveTag = liveTag; self.figures = figures; self.club = club; self.serial = serial
    }
  }

  public enum Presentation: Sendable {
    case hero, held, sharePNG
    var scale: CGFloat { self == .held ? 0.82 : 1 }
    var size: CGSize { self == .sharePNG ? CGSize(width: 362, height: 483) : CGSize(width: 362, height: 312) }
  }

  let golfer: Golfer
  let presentation: Presentation
  /// The plate: the golfer's photograph, or the crest. **Crest OR corner
  /// medallion, never both** — on a crest card the crest IS the mark.
  let plate: Plate
  let hasPhoto: Bool

  public init(_ golfer: Golfer, presentation: Presentation = .hero,
              hasPhoto: Bool = false, @ViewBuilder plate: () -> Plate) {
    self.golfer = golfer; self.presentation = presentation
    self.hasPhoto = hasPhoto; self.plate = plate()
  }

  public var body: some View {
    CSObject {
      VStack(alignment: .leading, spacing: 0) {
        ZStack(alignment: .bottomLeading) {
          plate.frame(height: presentation.size.height * 0.58).clipped()
          LinearGradient(stops: CSPhotoScrim.title.map {
            .init(color: CSTokens.dark.ceremony.opacity($0.alpha), location: $0.at)
          }, startPoint: .top, endPoint: .bottom)
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            if let live = golfer.liveTag {
              HStack(spacing: CSTokens.Space.s1) {
                Circle().fill(CSTokens.dark.ceremonyBrand).frame(width: 7, height: 7)
                Text(live).csType(.agateS, caps: true).foregroundStyle(CSTokens.dark.ceremonyBrand)
              }
              .csBudget(ember: 1)
            } else if let slot = golfer.slot {
              CSSlot(slot, over: .ceremony)
            }
            Text(golfer.name).csType(.display).foregroundStyle(CSTokens.dark.ceremonyInk)
              .lineLimit(1).minimumScaleFactor(0.7)
            Text(golfer.identity).csType(.agateS, caps: true).foregroundStyle(CSTokens.dark.ceremonyMut)
              .lineLimit(1).minimumScaleFactor(0.8)
          }
          .padding(CSTokens.Space.s3)
        }
        .overlay(alignment: .bottomTrailing) {
          if hasPhoto {
            CSMedallion(golfer.face.marker).padding(CSTokens.Space.s2)
          }
        }
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          // three figures on ONE rule — `ink` is 1.11:1 on `ceremony` in
          // light and forbidden here; the rule that binds the card's three
          // figures is the last thing that may vanish in one printing
          HStack(alignment: .top, spacing: 0) {
            ForEach(Array(golfer.figures.enumerated()), id: \.offset) { _, f in
              VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
                CSFigure(f.0, size: .m, label: nil, ordinal: f.2, over: .ceremony)
                Text(f.1).csType(.agateS, caps: true).foregroundStyle(CSTokens.dark.ceremonyMut)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          .overlay(alignment: .top) {
            CSRule(.heavy, over: .ceremony)
              .padding(.top, CSType.renderedSize(.figureM, .large) + CSTokens.Space.s1)
          }
          CSFolio(club: golfer.club, serial: golfer.serial)
        }
        .padding(CSTokens.Space.s3)
      }
      .frame(width: presentation.size.width, height: presentation.size.height)
      .background(CSTokens.dark.ceremony)
      .csCeremony()
    }
    .scaleEffect(presentation.scale)
    .frame(width: presentation.size.width * presentation.scale,
           height: presentation.size.height * presentation.scale)
  }
}
