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
      seeded(key: marker ?? "saguaro", marker: marker, photoURL: photoURL, initials: initials)
    }

    /// **A face keyed to a golfer the payload identifies by something other
    /// than a profile id.** A GUEST on a tee sheet is the case: they have no
    /// profile at all, and they still have a seat, a name and a mark, so they
    /// still get a coin of their own — two guests who both chose the Saguaro
    /// come out different, which is the whole point of the pigment.
    ///
    /// It is `unkeyed`'s arithmetic over a better key, and the difference is
    /// the reason `LINT-31` counts one and not the other: `unkeyed` keys to
    /// the GLYPH and is a debt, `seeded` keys to the PERSON and is not.
    public static func seeded(key: String, marker: String?, photoURL: URL? = nil,
                              initials: String = "", isViewer: Bool = false) -> Model {
      var h: UInt64 = 0xcbf29ce484222325
      for b in Array(key.utf8) { h = (h ^ UInt64(b)) &* 0x100000001b3 }
      let hi = h.byteSwapped
      let bytes = withUnsafeBytes(of: (h, hi)) { Array($0) }
      let u = UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                          bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
      return Model(id: u, marker: marker, photoURL: photoURL, initials: initials, isViewer: isViewer)
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
  /// **THE GROUND THE DISC IS DRAWN ON, NOT THE AMBIENT THEME** (DF-06).
  ///
  /// D271 freezes a golfer's pigment INDEX so their marker never moves — and
  /// the rendered VALUE was still resolving against `@Environment(\.cs)`,
  /// which follows the theme. A pinned `ceremony` plate is dark in BOTH
  /// printings, so in the light theme the event room put `YOU` on screen twice
  /// at once: a saturated brown disc with a cream cactus on the pinned title
  /// card, and a pale cream disc with a brown cactus in the clash row eleven
  /// hundred points below. One golfer, two coins, one viewport. That is the
  /// same failure mode the frozen pair exists to prevent, arriving through the
  /// theme instead of through the key.
  ///
  /// `CSRule` and `CSSlot` already take this argument; the face now does too.
  public let over: CSRule.Ground

  public init(_ model: Model, size: Size, sideRing: Color? = nil, name: String? = nil,
              over: CSRule.Ground = .page) {
    self.model = model; self.size = size; self.sideRing = sideRing
    self.name = name; self.over = over
  }

  /// The palette the disc resolves against: the page's, or the pinned dark one
  /// when the face is standing on a ceremony ground.
  private var ground: CSPalette { over == .ceremony ? CSTokens.dark : cs }

  private var d: CGFloat { size.rawValue }

  /// On cream stock the glyph takes `ink`, never `mut`: the pale tints are
  /// ~0.90 relative luminance and a `mut` stroke on them measured
  /// near-invisible in the light renders. The viewer's own mark takes `ink` in
  /// both printings.
  private var glyphInk: Color {
    over == .ceremony ? (model.isViewer ? ground.ink : ground.mut)
                      : ((scheme == .light || model.isViewer) ? cs.ink : cs.mut)
  }

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
    .overlay(Circle().inset(by: 0.5).stroke(ground.rule, lineWidth: CSTokens.Space.hair))
    .overlay {
      if let sideRing { Circle().inset(by: -1.5).stroke(sideRing, lineWidth: 2.5) }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(name ?? "")
    .accessibilityHidden(name == nil)
  }

  private var disc: some View {
    ZStack {
      Circle().fill(model.pigment(ground))
      if let key = model.marker {
        CSMarkerView(key: key, size: d * 0.55, lineWidth: 1.8, optical: true)
          .foregroundStyle(glyphInk)
      } else if !model.initials.isEmpty {
        // "chose nothing" — not a silhouette, not a fabricated face, and
        // visibly different from "chose the Saguaro"
        Text(model.initials)
          .font(.custom(CSType.boardSemi, fixedSize: d * 0.40))
          .tracking(d * 0.40 * CSTokens.Track.caps)
          .foregroundStyle(ground.ink)
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
  @Environment(\.csReduceTransparency) private var reduce
  let club: String
  /// **The serial degrades.** The product owns the marker's NAME ("The Lone
  /// Tree") and does not own a card number — there is no such column, and a
  /// stable-looking `No. 12` derived from a UUID is fake data as ornament,
  /// which D272 rules is less premium than a plain colour. Absent, then, and
  /// the folio is still a folio.
  let serial: String?
  public init(club: String, serial: String? = nil) { self.club = club; self.serial = serial }
  public var body: some View {
    VStack(spacing: CSTokens.Space.s2) {
      // §16.5 · the folio at `a16` is one of the four textures the credential
      // IS. Under Reduce Transparency it takes its composited opaque value —
      // the same arithmetic that produced `folioRule` `#8B8F8B` and gave it a
      // name, done at run time so no component carries a second hex.
      Rectangle().fill(CSOpaque.tint(CSTokens.dark.ceremonyInk, CSTokens.Alpha.a16,
                                     over: CSTokens.dark.ceremony, reduce: reduce))
        .frame(height: CSTokens.Space.hair)
      HStack {
        Text(club).csType(.agateS, caps: true)
        Spacer(minLength: CSTokens.Space.s2)
        if let serial { Text(serial).csType(.agateS, caps: true) }
      }
      .foregroundStyle(CSTokens.dark.folioRule)
    }
    // a serial is not spoken
    .accessibilityHidden(true)
  }
}

/// **Hoisted out of the generic on purpose.** `CSCredential` is generic over
/// its plate, and a type nested inside a generic cannot be NAMED without the
/// generic argument — `CSCredential.Golfer` does not compile in a type
/// position, which is where every surface needs it (a `figures:` array, a
/// `golfer:` property). `CSCredential.Golfer` remains as a typealias so the
/// object's own code reads as the anatomy it is.
/// Everything the object prints. The object owns its own anatomy so no
/// surface can re-cut it — that is the whole of GP-16.
public struct CSCredentialGolfer: Sendable {
  public let face: CSFace.Model
  public let name: String
  /// One string, product-wide: `@GALENM · MESA, AZ · PAPAGO` — handle, city,
  /// home course. **It never carries `EST. JUL 2026`**: the founding fact is
  /// already the gold slot and the folio's serial, and a third telling is the
  /// duplication YRS-21 names. Produced by `CredentialCopy.identity`, in the
  /// Kit, once, for both clients.
  public let identity: String
  /// `FOUNDER` · `CHAMPION` · `THE PRO`. Absent when nothing is earned, and
  /// then the card carries no gold FIELD at all.
  public let slot: String?
  /// Replaces the slot while a round is live — the only ember on the card.
  public let liveTag: String?
  /// The credit line over a photograph: `GALEN'S ROUND · AUG 24`. An image
  /// the product borrowed and an image somebody took are told apart by this
  /// line and by nothing else.
  public let credit: String?
  /// index · rounds · position. **One to three**, and a slot with no figure
  /// is ABSENT — never a dash, never a zero, never a verb.
  public let figures: [Figure]
  public let club: String
  public let serial: String?

  public struct Figure: Sendable {
    public let value: String
    public let label: String
    public let ordinal: String?
    public init(_ value: String, label: String, ordinal: String? = nil) {
      self.value = value; self.label = label; self.ordinal = ordinal
    }
  }

  public init(face: CSFace.Model, name: String, identity: String, slot: String? = nil,
              liveTag: String? = nil, credit: String? = nil, figures: [Figure],
              club: String, serial: String? = nil) {
    self.face = face; self.name = name; self.identity = identity; self.slot = slot
    self.liveTag = liveTag; self.credit = credit
    self.figures = Array(figures.prefix(3))
    self.club = club; self.serial = serial
  }
}

// MARK: - The credential

/// **The card.** A collectible object, not a layout — and `UI_SYSTEM` §6.5 is
/// its single anatomy of record. `profile.md` and `player-card.md` both point
/// here rather than restating it, because a second disagreeing anatomy table
/// would reopen the very defect ("one object, two chromes, two aspect ratios,
/// two meta strings") that this closes.
///
/// **362 × 312 (≈ 7:6, landscape), radius `r` 16, `shadow-lift`, ground
/// `ceremony` in every theme, MEASURE-RELATIVE** — 335 × 289 on an SE. A 3:4
/// object at the 362pt measure is 483pt tall, and with the chrome above it the
/// page's ranked action lands below the tab bar on every device. **The 3:4
/// portrait survives in exactly one place: the share PNG**, which has no fold
/// and no chrome under it.
///
/// At the accessibility sizes **the ratio is released and the object grows the
/// page** (§16.3): it never scrolls inside itself, the plate holds ~180 and the
/// figure half takes the growth.
public struct CSCredential<Plate: View>: View {
  /// See `CSCredentialGolfer` — hoisted out of the generic so a surface can
  /// name it.
  public typealias Golfer = CSCredentialGolfer

  public enum Presentation: Sendable {
    /// The You tab, the person page, the card screen — full measure.
    case hero
    /// The one 3:4 crop, exported at 2×, because a shared image has no fold.
    case sharePNG

    var ratio: CGFloat { self == .sharePNG ? 362.0 / 483.0 : 362.0 / 312.0 }
    var maxWidth: CGFloat { 362 }
  }

  @Environment(\.dynamicTypeSize) private var typeSize
  /// **The object is MEASURE-RELATIVE**, so it has to know its own width: the
  /// plate's share, the figure strip's three equal columns and the rule that
  /// spans only the columns carrying a figure are all fractions of it. One
  /// measurement drives all three — width never depends on height, so the pass
  /// converges rather than oscillating.
  @State private var measured: CGFloat = 362

  let golfer: Golfer
  let presentation: Presentation
  /// The plate: the golfer's photograph, or `CSCrestPlate`. The medallion is
  /// notched into the lower right of **both** — one slot, one size, one
  /// treatment (§6.2a, after the blind review), and the crest card additionally
  /// carries the same glyph magnified, which is the point of the frozen pair.
  let plate: Plate
  let hasPhoto: Bool

  public init(_ golfer: Golfer, presentation: Presentation = .hero,
              hasPhoto: Bool = false, @ViewBuilder plate: () -> Plate) {
    self.golfer = golfer; self.presentation = presentation
    self.hasPhoto = hasPhoto; self.plate = plate()
  }

  /// The plate's share of the object. At the accessibility sizes it stops
  /// being a fraction and becomes ~180pt, so the figures take the growth.
  private var plateFraction: CGFloat { 0.58 }
  private var cardWidth: CGFloat { min(measured, presentation.maxWidth) }
  private var cardHeight: CGFloat { cardWidth / presentation.ratio }
  private var plateHeight: CGFloat { typeSize.isA11y ? 180 : cardHeight * plateFraction }
  /// The inner measure, and a third of it. `HANDICAP INDEX` is 86pt at the
  /// default size and a third of a 362pt card is 107, so the columns fit — but
  /// only if they are actually EQUAL. `frame(maxWidth: .infinity)` inside an
  /// HStack does not make equal columns: it hands each child its ideal width
  /// first and redistributes the remainder, so the second label started 16pt
  /// left of its own numeral in the first screenshot of this card.
  private var column: CGFloat { (cardWidth - CSTokens.Space.s4 * 2) / 3 }

  // MARK: the copy band, which may not reach the slot

  /// The plate's inner measure — the room the name and the identity line set
  /// in.
  private var bandMeasure: CGFloat { max(1, cardWidth - CSTokens.Space.s4 * 2) }

  /// **The plate's HEAD BAND is reserved, and the copy band may not enter
  /// it.** The gold slot and the credit sit at `s4` from the plate's top in a
  /// 24pt field; the band beneath needs `s2` of air under them or the name
  /// prints through the slot.
  private var plateHeadBand: CGFloat { PlateBand.head }

  /// **The plate's copy arithmetic, as a free function so a test can read
  /// it.** Everything below is this, bound to the card's own state.
  public enum PlateBand {
    /// The head band the slot occupies: `s4` down, a 24pt gold field, `s2` of
    /// air. Nothing in the copy band may enter it.
    public static var head: CGFloat { CSTokens.Space.s4 + 24 + CSTokens.Space.s2 }

    /// How tall a name + identity band wants to be.
    public static func height(name: String, role: CSType.Role, identityClauses: Int,
                              measure: CGFloat, size: DynamicTypeSize) -> CGFloat {
      let m = max(1, measure)
      let lines = min(2, max(1, ceil(CSAdvance.width(name, role, size) / m)))
      var h = CSType.renderedSize(role, size) * role.leading * lines
      if identityClauses > 0 {
        h += CSTokens.Space.s1
           + CSType.renderedSize(.agateS, size) * CSType.Role.agateS.leading * CGFloat(identityClauses)
      }
      return h
    }

    /// The room under the head band.
    public static func room(plateHeight: CGFloat) -> CGFloat {
      plateHeight - head - CSTokens.Space.s3
    }

    /// The name's role: `display`, or `displayS` when the name will not set on
    /// one line.
    public static func nameRole(_ name: String, measure: CGFloat, size: DynamicTypeSize) -> CSType.Role {
      CSAdvance.fits(name, in: measure, .display, size) ? .display : .displayS
    }

    /// **Does the identity belong on the photograph?** The whole question, in
    /// one place: name + identity, at the role the name will actually take,
    /// against the room under the slot.
    public static func ridesThePlate(name: String, identityClauses: Int,
                                     measure: CGFloat, plateHeight: CGFloat,
                                     size: DynamicTypeSize) -> Bool {
      guard !size.isA11y else { return false }
      let role = nameRole(name, measure: measure, size: size)
      return height(name: name, role: role, identityClauses: identityClauses,
                    measure: measure, size: size) <= room(plateHeight: plateHeight)
    }
  }

  /// How tall the identity block wants to be at a given name role.
  ///
  /// **This is the arithmetic that was missing.** `head` laid `identityBlock`
  /// `.bottomLeading` inside a plate of FIXED height (58% of the card) while
  /// the block itself GROWS: a two-line name at `display` 34 over a three-clause
  /// identity is ~72% of a 180pt plate, so its top reached the slot at the
  /// plate's head and `JER` of `JERECHO` printed behind `FOUNDER` — on the
  /// flagship object of the design, at the DEFAULT reading size, on every
  /// device photographed. The `riding` comment guarded the AX3 case only.
  private func bandHeight(_ role: CSType.Role) -> CGFloat {
    // `CSClauseLine` breaks on its separators, so the worst case is one line
    // per clause — which is the case that has to fit.
    PlateBand.height(name: golfer.name, role: role, identityClauses: identityClauses,
                     measure: bandMeasure, size: typeSize)
  }

  /// **The clauses, not the characters.** `CSCredentialGolfer.identity` is a
  /// `·`-joined String produced by `CredentialCopy.identity`, and
  /// `CSClauseLine` breaks it on those separators — so the worst case is one
  /// line per clause. (`identity.count` is 51 for a golfer with a handle, a
  /// city and a home course, which is what this asked for first and is why the
  /// identity walked off the photograph on a card that fits it easily.)
  private var identityClauses: Int {
    golfer.identity.isEmpty ? 0
      : golfer.identity.components(separatedBy: "\u{00B7}").count
  }

  /// The room the copy band actually has, under the reserved head band.
  private var bandRoom: CGFloat { PlateBand.room(plateHeight: plateHeight) }

  /// **The name drops a size before the card gives up its composition.** A
  /// name that will not set on one line at `display` is set at `displayS` —
  /// `player-card-photo.png` bottom-anchors a ONE-line name with clear air
  /// above the identity and clear air below the slot, and the size is the
  /// cheapest of the three things that could give (the size, the plate's
  /// height, or the photograph itself).
  var nameRole: CSType.Role {
    typeSize.isA11y ? .display : PlateBand.nameRole(golfer.name, measure: bandMeasure, size: typeSize)
  }

  /// **And when even that does not fit, the identity leaves the photograph.**
  /// §6.7/§6.8's own path, which the AX branch has always taken: the name
  /// stays on the plate and the identity line sets on the card's own ground.
  /// A long name over a three-clause identity on a small measure is the case
  /// that reaches here.
  var identityRidesThePlate: Bool {
    PlateBand.ridesThePlate(name: golfer.name, identityClauses: identityClauses,
                            measure: bandMeasure, plateHeight: plateHeight, size: typeSize)
  }

  /// **WAVE 10 · THE THREE COLUMNS ARE MEASURED, NOT ASSUMED EQUAL.**
  ///
  /// Equal thirds were the fix for a real bug (`frame(maxWidth: .infinity)`
  /// inside an `HStack` hands each child its ideal width first, so the second
  /// label started 16pt left of its own numeral) and they came with a real
  /// cost: `HANDICAP INDEX` needs 118 of a 110pt third, so the product's most
  /// important label read `HANDICAP IND…` on every card, on every phone, and a
  /// league called `WHO'S THE BITCH?` read `WHO'S THE BIT…` beside it. Two of
  /// the card's three labels truncated at the DEFAULT reading size.
  ///
  /// So the cells take the width their own characters need — measured in the
  /// real face at the size being read, which is what `CSAdvance` is for — and
  /// give the surplus to the cell that needs it. Every cell still contains
  /// both its numeral and its label, so nothing can drift out from under its
  /// own figure. When the three genuinely do not fit they scale together and
  /// the longest still truncates, which is the honest degrade rather than a
  /// promise the measure cannot keep.
  private func columnWidths(_ figs: [CSCredentialGolfer.Figure]) -> [CGFloat] {
    let inner = cardWidth - CSTokens.Space.s4 * 2
    let n = max(1, figs.count)
    guard n > 1 else { return [inner / 3] }
    let need = figs.map { f -> CGFloat in
      max(CSAdvance.width(f.value + (f.ordinal ?? ""), .figureM, typeSize),
          CSAdvance.width(f.label, .agateS, typeSize, caps: true)) + CSTokens.Space.s2
    }
    let total = need.reduce(0, +)
    guard total > 0 else { return Array(repeating: inner / CGFloat(n), count: n) }
    // never wider than the card; never narrower than what a two-digit figure
    // and its rule need to stay a column
    let scale = min(1, inner / total)
    var widths = need.map { max(CSTokens.Space.rail, $0 * scale) }
    // **AND THE SURPLUS IS DISTRIBUTED, NOT DROPPED.** The measured cells fixed
    // `HANDICAP IND…`, and they left the rule spanning only the sum of the
    // cells — 55pt short of the card's inner edge on a three-figure card, with
    // the folio's own longer hairline stacked directly beneath it, so the
    // object carried two rules of two different lengths and read unfinished.
    // Every artboard printing spans the rule across the card with the last
    // column flush right. The cells scale UP to fill the measure when they
    // under-fill it, which keeps each label under its own numeral and puts the
    // rule where the artboard draws it.
    //
    // **The two-cell exception survives**: a two-cell strip under a full-width
    // rule "reads as a missing value" (blind-3), so a strip of fewer than
    // three keeps its short rule and says so.
    if n >= 3 {
      let sum = widths.reduce(0, +)
      if sum > 0, sum < inner {
        let up = inner / sum
        widths = widths.map { $0 * up }
      }
    }
    return widths
  }

  public var body: some View {
    Group {
      if typeSize.isA11y {
        // §16.3 · the ratio is released and the object GROWS THE PAGE. It
        // needs no measure: the plate is a fixed 180, the figures are rows
        // and nothing is a fraction of anything.
        object
      } else {
        // **WAVE 10 · THE MEASURE COMES FROM A `GeometryReader`, WHICH IS
        // THE ONE CONTAINER THAT NEVER GROWS TO ITS CONTENT.**
        //
        // Wave 2 measured the card from a probe in its own background — under
        // a `frame(width: cardWidth)` that is a FIXED frame, and every frame
        // above a fixed frame grows to hold it. So the probe read back the
        // width the card had already chosen (362, the `@State` default) and
        // the loop had nothing to converge on: `min(measured, 362)` is 362
        // forever. On an SE the "measure-relative" credential §16.3 promises
        // at **335 × 289** drew at 362 and ran 27pt off the right edge of the
        // phone — on the You tab, on the flagship object of the design.
        // `csPage` is what found it, by name: `CS-SHEAR you wants 402.0 in
        // 375.0`. Two other constructions were tried first and both read 362
        // back for the same reason; a `GeometryReader` takes the proposal and
        // nothing else, so what it reports is the room the card is GIVEN.
        GeometryReader { g in
          object
            .onAppear { measured = g.size.width }
            .onChange(of: g.size.width) { _, n in measured = n }
        }
        .frame(height: cardHeight)
      }
    }
    .accessibilityElement(children: .contain)
  }

  /// The object itself. Its width is `cardWidth` and it sits at the leading
  /// edge of whatever room it is in — a credential does not stretch (it would
  /// be a banner) and it does not float either.
  private var object: some View {
    CSObject {
      VStack(alignment: .leading, spacing: 0) {
        head
        foot
      }
      .frame(width: typeSize.isA11y ? nil : cardWidth,
             height: typeSize.isA11y ? nil : cardHeight, alignment: .topLeading)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(CSTokens.dark.ceremony)
      .csCeremony()
    }
    .frame(maxWidth: presentation.maxWidth, alignment: .leading)
  }

  // MARK: the plate half

  private var head: some View {
    ZStack(alignment: .bottomLeading) {
      // **The plate is sized BEFORE the ZStack, not clipped after it.** A
      // `scaledToFill` image has no intrinsic ceiling, so the stack sized to
      // the image and the name, the identity line and the slot were laid out
      // hundreds of points below the card's own foot — present, addressable by
      // VoiceOver, and invisible. The first screenshot of the photo card had
      // no name on it.
      plate
        .frame(width: typeSize.isA11y ? nil : cardWidth, height: plateHeight)
        .clipped()
      CSPhotoScrim.layer(CSPhotoScrim.title)
      // the slot and the credit sit at the plate's HEAD, where `.title` has
      // not started ramping — so they get `.top`'s own geometry under them,
      // and `CSPhotoScrim.ink(_:caption:)` gives the credit `scrimInk`
      // rather than the `scrimMut` that computes at 4.15:1 under a72.
      if hasPhoto {
        VStack(spacing: 0) {
          CSPhotoScrim.layer(CSPhotoScrim.top).frame(height: CSPhotoScrim.topHeight)
          Spacer(minLength: 0)
        }
      }
      // **`riding`, kept verbatim from `CredentialFace`: legibility beats
      // composition.** At the accessibility sizes `display` reaches ~60pt on
      // two lines and the copy band would exceed 45% of a 180pt plate — the
      // first AX3 screenshot of this card printed the name THROUGH the credit
      // line and the gold slot. The identity block drops off the photograph
      // onto the card's own ground instead (§6.7, §6.8).
      if !typeSize.isA11y {
        identityBlock(identity: identityRidesThePlate)
          .padding(.horizontal, CSTokens.Space.s4)
          .padding(.bottom, CSTokens.Space.s3)
          // **The head band is reserved, whatever the copy does.** With the
          // block bottom-anchored in a fixed plate this is what stops it
          // growing up into the slot: it can only use the room under the
          // slot's own row.
          .padding(.top, plateHeadBand)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .overlay(alignment: .topLeading) { plateHead }
    // **The medallion is on every card, in the same slot, at the same size.**
    // All three blind reviewers filed the shipped split ("on Galen it is a
    // small gold-ringed medallion in the corner; on Tash it is a giant flat
    // glyph filling a third of the card"), and §19(i) accepts the crest and
    // the medallion drawing the same glyph at two scales as the point of the
    // frozen pair rather than as a duplication. §6.5's older "crest or corner,
    // never both" is the rule this supersedes, and it is named in IOS-047.
    .overlay(alignment: .bottomTrailing) {
      CSMedallion(golfer.face.marker)
        .padding(.trailing, CSTokens.Space.s4)
        .padding(.bottom, plateMedallionDrop)
        .accessibilityLabel("Their marker, the \(CSMarkers.marker(golfer.face.marker).name)")
        .accessibilityHidden(false)
        // §17's NAMED WHITELIST, and this is one of the exactly two.
        // `LINT-17` allows one gold object per viewport; a card that has earned
        // a slot carries the slot AND this medallion, and the paragraph above
        // is the ruling that puts both here. So the medallion declares itself
        // as the paired half rather than the budget quietly failing on every
        // credential in the product — which is what the probe reported the
        // first time anything read it. A THIRD gold mark on a card still fails.
        .csBudget(goldPaired: golfer.slot != nil ? 1 : 0)
    }
    .frame(height: plateHeight)
    .clipped()
  }

  /// The medallion clears the copy band rather than sitting on the name: it is
  /// notched at the plate's lower right, above the display line's own top.
  private var plateMedallionDrop: CGFloat { CSTokens.Space.s6 + CSTokens.Space.s4 }

  var identityBlock: some View { identityBlock(identity: true) }

  @ViewBuilder func identityBlock(identity: Bool) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      Text(golfer.name)
        .csType(nameRole)
        .foregroundStyle(CSTokens.dark.ceremonyInk)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
      if identity, !golfer.identity.isEmpty {
        // **WAVE 10 · A LINE OF CLAUSES BREAKS ON ITS SEPARATORS; IT DOES NOT
        // TRUNCATE** (§16.3, the `agate` row). `@JERECHO · PHOENIX, AZ ·
        // LOOKOUT MOUNTAIN GOL…` was the shipped result on a 402 measure, and
        // on an SE it lost the city too — a golfer's own card, cutting off
        // their own home course. The tail-ellipsis policy (§9.1) is for a
        // NAME, which is one token with nowhere to break; three clauses have
        // two places to break and this takes them.
        CSClauseLine(golfer.identity, role: .agateS, caps: true,
                     colour: CSTokens.dark.ceremonyMut)
      }
    }
  }

  /// The slot and the credit share the plate's head. At the reading sizes they
  /// sit at opposite corners; at AX3 they stack, because two grown agate lines
  /// on one line print through each other.
  @ViewBuilder private var plateHead: some View {
    if typeSize.isA11y {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        slotOrTag
        creditText
      }
      .padding(CSTokens.Space.s4)
    } else {
      HStack(alignment: .top) {
        slotOrTag
        Spacer(minLength: CSTokens.Space.s3)
        creditText
      }
      .padding(CSTokens.Space.s4)
    }
  }

  @ViewBuilder private var slotOrTag: some View {
    if let live = golfer.liveTag {
      HStack(spacing: CSTokens.Space.s1) {
        Circle().fill(CSTokens.dark.ceremonyBrand).frame(width: 7, height: 7)
        Text(live).csType(.agateS, caps: true).foregroundStyle(CSTokens.dark.ceremonyBrand)
      }
      .csBudget(ember: 1)
    } else if let slot = golfer.slot {
      CSSlot(slot, over: .ceremony)
    }
  }

  @ViewBuilder private var creditText: some View {
    if let credit = golfer.credit, hasPhoto {
      // §10.3, resolved: over `.title` the credit takes `scrimInk`, not
      // `scrimMut` — the ramp reaches a88 there, but the credit sits at the
      // TOP of the plate where it reaches only a72, and `scrimMut` under a72
      // over a bright subject computes at 4.15:1.
      Text(credit).csType(.agateS, caps: true)
        .foregroundStyle(CSPhotoScrim.ink(CSPhotoScrim.top, caption: true))
        .lineLimit(2)
        .multilineTextAlignment(typeSize.isA11y ? .leading : .trailing)
    }
  }

  // MARK: the record half

  private var foot: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      if typeSize.isA11y {
        identityBlock
      } else if !identityRidesThePlate, !golfer.identity.isEmpty {
        // §6.7 · the identity on the card's own ground, because the plate
        // could not hold it without printing through the slot.
        CSClauseLine(golfer.identity, role: .agateS, caps: true,
                     colour: CSTokens.dark.ceremonyMut)
      }
      figureStrip
      CSFolio(club: golfer.club, serial: golfer.serial)
    }
    .padding(CSTokens.Space.s4)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// **One to three figures on ONE shared rule** — and the rule fits its own
  /// cells. A two-cell strip under a full-width rule "reads as a missing
  /// value" (blind-3), so the grid is three columns wide and the rule spans
  /// only the columns that carry a figure: 66% for two, 33% for one.
  ///
  /// The rule is `ceremonyInk` and never `ink`, which is **1.11:1 on
  /// `ceremony` in light** — the rule that binds the card's three figures is
  /// the last thing that may vanish in one printing.
  /// **The rule's own width, and it finally matches the paragraph above it.**
  /// Three figures fill the card's inner measure, so the rule reaches the
  /// edge the way every artboard printing draws it. Fewer than three keep the
  /// short rule — a two-cell strip under a full-width rule "reads as a missing
  /// value" (blind-3) — at the **66% / 33%** the doc comment has always
  /// claimed, rather than at whatever the measured cells happened to sum to.
  private func ruleWidth(_ widths: [CGFloat]) -> CGFloat {
    let sum = widths.reduce(0, +)
    guard widths.count < 3 else { return sum }
    let inner = cardWidth - CSTokens.Space.s4 * 2
    return max(sum, inner * CGFloat(widths.count) / 3)
  }

  @ViewBuilder private var figureStrip: some View {
    // (the AX3 branch keeps its own row-per-figure geometry)
    if typeSize.isA11y {
      // §6.8 · three ROWS, each its own cell: label leading, figure trailing,
      // each on its own rule.
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        ForEach(Array(golfer.figures.enumerated()), id: \.offset) { _, f in
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            CSFigure(f.value, size: .m, label: nil, ordinal: f.ordinal, over: .ceremony)
            CSRule(.heavy, over: .ceremony)
            Text(f.label).csType(.agateS, caps: true)
              .foregroundStyle(CSTokens.dark.ceremonyMut)
          }
        }
      }
    } else {
      let widths = columnWidths(golfer.figures)
      HStack(alignment: .top, spacing: 0) {
        ForEach(Array(golfer.figures.enumerated()), id: \.offset) { i, f in
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            CSFigure(f.value, size: .m, label: nil, ordinal: f.ordinal, over: .ceremony)
            // **A label truncates before it touches the next one**, and the
            // gutter is inside the cell so the truncation starts a word
            // earlier. With measured columns it should never fire; when the
            // three labels genuinely exceed the card it fires honestly.
            Text(f.label).csType(.agateS, caps: true)
              .foregroundStyle(CSTokens.dark.ceremonyMut)
              .lineLimit(1).truncationMode(.tail)
              .frame(width: max(0, widths[i] - CSTokens.Space.s2), alignment: .leading)
          }
          .frame(width: widths[i], alignment: .leading)
        }
        Spacer(minLength: 0)
      }
      .overlay(alignment: .topLeading) {
        // **The rule fits its own cells.** A two-cell strip under a full-width
        // rule "reads as a missing value", so the rule spans the sum of the
        // cells that carry a figure and stops there.
        CSRule(.heavy, over: .ceremony)
          .frame(width: ruleWidth(widths))
          .offset(y: CSType.renderedSize(.figureM, typeSize) + CSTokens.Space.s1)
          .allowsHitTesting(false)
      }
    }
  }
}

// MARK: - The crest plate — the marker floor, designed rather than degraded

/// A golfer with no photograph gets a **designed card**. This is canon
/// (`IOS-003` §1, `UI_SYSTEM` §6.1: no silhouette state, no fabricated face,
/// ever) and it is the state most golfers are actually in.
///
/// The contour is the plate's FIELD, seeded from the golfer's home course; the
/// crest is their own marker at ~1.5pt on a ~190pt box in `crest` `#33463B` —
/// an emboss, not a picture — **bleeding off the plate's right edge**, so the
/// object reads as printed stock rather than as an icon centred in a box.
///
/// There is no ember wash. GP-10 (the shipped 28% ember radial: "a muddy
/// ochre-brown cloud, and ember is the *live* metal, which a crest is not") is
/// killed at the token level rather than dimmed.
public struct CSCrestPlate: View {
  let marker: String?
  /// The course id, or the golfer's own id when they keep no home course.
  let seed: String
  /// **No home course → no `brand` dot.** There is no hole to point at, and a
  /// dot that means nothing is the ornament D272 forbids.
  let hasCourse: Bool

  public init(marker: String?, seed: String, hasCourse: Bool) {
    self.marker = marker; self.seed = seed; self.hasCourse = hasCourse
  }

  public var body: some View {
    ZStack(alignment: .bottomTrailing) {
      CSTokens.dark.ceremony
      CSContour(seed: seed, levels: 6, lineWidth: 1.2,
                tint: CSTokens.dark.ceremonyInk.opacity(CSTokens.Alpha.a24),
                mark: hasCourse ? CSTokens.dark.ceremonyBrand : nil,
                // **The credential's plate carries COPY.** The name sets
                // bottom-left, the slot top-left, the medallion bottom-right;
                // the upper right is the quadrant nothing else uses, and it is
                // where `player-card-marker.png` draws the mark.
                markSafe: CGRect(x: 0.58, y: 0.10, width: 0.30, height: 0.26))
      CSMarkerView(key: marker, size: 190, lineWidth: 1.5, optical: true)
        .foregroundStyle(CSTokens.dark.crest)
        .offset(x: 46, y: 6)
        .accessibilityHidden(true)
    }
    .clipped()
  }
}
