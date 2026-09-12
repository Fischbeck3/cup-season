import SwiftUI

/// Abstract golf terrain for brand surfaces, not a map of a real course.
/// Open approach contours meet asymmetric green surrounds and bunker pockets.
/// The app-icon master is intentionally independent of this page treatment.
public struct CSTopoField: View {
  public enum Composition: Sendable { case accent, page }
  @Environment(\.cs) private var cs
  private let tint: Color?
  private let composition: Composition
  public init(_ composition: Composition = .accent, tint: Color? = nil) {
    self.composition = composition
    self.tint = tint
  }

  public var body: some View {
    Canvas(rendersAsynchronously: false) { context, size in
      let scale = size.width / 420
      // A width-based drawing keeps the shapes and line weight consistent.
      // Page backgrounds ignore the keyboard at the call site. Geometry is
      // fixed, with no random seed or time-driven animation.
      let y = composition == .page ? 30 * scale : -36 * scale
      let transform = CGAffineTransform(translationX: 0, y: y).scaledBy(x: scale, y: scale)
      let color = tint ?? cs.mut.opacity(CSTokens.Alpha.a24)
      context.stroke(CSGolfTerrain.surrounds.applying(transform), with: .color(color),
                     style: StrokeStyle(lineWidth: CSTokens.Space.hair / 2, lineCap: .round, lineJoin: .round))
      context.stroke(CSGolfTerrain.edges.applying(transform), with: .color(color),
                     style: StrokeStyle(lineWidth: CSTokens.Space.hair, lineCap: .round, lineJoin: .round))

    }
    .clipped().allowsHitTesting(false).accessibilityHidden(true)
  }
}

/// Deliberately drawn contours; independent curves, never scaled ellipses.
/// The green and bunker outlines are stylized brand geometry, not course data.
private enum CSGolfTerrain {
  static let edges = SVGPath.path("""
    M 336 57 C 358 38 386 42 395 60 C 404 77 391 91 386 107 C 380 125 385 145 366 153 C 346 162 316 151 309 132 C 303 115 318 106 320 90 C 322 77 324 66 336 57 Z
    M 294 83 C 301 76 310 77 311 87 C 312 98 299 105 297 116 C 294 126 287 129 281 121 C 274 111 283 95 294 83 Z
    M 393 169 C 402 157 414 155 420 163 C 427 173 414 179 410 188 C 405 200 393 207 386 199 C 379 190 385 180 393 169 Z
    """)
  static let surrounds = SVGPath.path("""
    M 322 29 C 350 8 398 12 421 41 C 444 67 429 102 419 124 C 412 150 419 163 389 183 C 359 202 318 191 293 166 C 270 143 274 119 285 97 C 295 75 296 48 322 29 Z
    M 306 15 C 342 -14 402 -9 435 26 C 467 65 449 105 438 134 C 425 169 429 185 396 204 C 363 223 319 213 287 185 C 257 159 251 131 261 104 C 272 76 277 39 306 15
    M 252 -10 C 241 24 220 54 216 92 C 208 151 210 186 256 224 C 303 262 359 276 414 255 C 446 243 466 218 478 195
    M 162 -9 C 184 22 170 62 166 104 C 161 151 164 195 193 236 C 222 277 258 289 278 329 C 299 371 303 407 330 446 C 356 483 393 509 436 526
    M 56 -12 C 105 14 121 58 119 105 C 116 167 117 207 140 257 C 163 307 190 332 211 373 C 233 417 247 469 282 506 C 324 551 380 576 435 582
    M -6 39 C 32 55 56 85 61 125 C 70 183 58 230 76 281 C 91 324 119 364 139 404 C 175 483 202 532 270 579 C 324 616 388 642 450 650
    """)

}

public struct CSBrandLockup: View {
  @Environment(\.cs) private var cs
  public init() {}
  public var body: some View {
    HStack(spacing: CSTokens.Space.s3) {
      CSBrandMark().frame(width: CSTokens.Space.s6, height: CSTokens.Space.s6)
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        Text("CUP SEASON").csType(.name, caps: true)
        Text(CSBrandCopy.tagline).csType(.agateS, caps: true)
      }
    }
    .foregroundStyle(cs.ink)
    .accessibilityElement(children: .ignore).accessibilityLabel("Cup Season. \(CSBrandCopy.tagline)")
  }
}

/// Owner-selected brand line. Product terminology and ledger copy are separate.
public enum CSBrandCopy {
  public static let tagline = "ANY TIME.\nANYWHERE."
  public static let extended = "ANY TIME.\nANYWHERE.\nALL SEASON."
}

/// A restrained brand signature, separate from facts and primary actions.
public struct CSBrandSignature: View {
  @Environment(\.cs) private var cs
  private let showsTopo: Bool
  public init(showsTopo: Bool = true) { self.showsTopo = showsTopo }
  public var body: some View {
    HStack(spacing: CSTokens.Space.s3) {
      Text(CSBrandCopy.tagline).csType(.agateS, caps: true)
      Spacer(minLength: CSTokens.Space.s2)
      CSBrandMark(ground: cs.bg0).frame(width: CSTokens.Space.s6, height: CSTokens.Space.s5)
        .background { if showsTopo { CSTopoField() } }
    }
    .foregroundStyle(cs.mut)
    .padding(.vertical, CSTokens.Space.s4)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Cup Season. \(CSBrandCopy.tagline)")
  }
}
