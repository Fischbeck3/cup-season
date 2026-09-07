// Cup Season — the contour plate (D272 rung 3, UI_SYSTEM §10.1).
//
// "A deterministic topographic plot seeded from the course id — a seeded
// value-noise field sampled at 5–7 isolevels (marching squares over a 32 × 32
// grid), cropped hard off its own centre, carrying one `brand` dot on the
// hardest hole by stroke index. Same course, same plot, forever."
//
// **NOT NESTED ELLIPSES**, and the system says why in as many words: six
// near-concentric circles with a radial line is a radar sweep, and it is the
// same "three near-identical concentric ovals" failure that bans the contour
// at thumbnail scale, arriving at plate scale instead. A noise field is what
// makes two courses look like two places — and it is the reason this file
// exists rather than a `ForEach` of inset `Ellipse()`s, which is what the
// mockup draws and what would have been a third of the work.
//
// It is built HERE, in Wave 2, because the credential's marker floor is the
// state most golfers are actually in and §2 of `surfaces/player-card.md` puts
// the contour behind its crest: "a designed card, not a degraded one". Wave 4
// owns the course page's hero and inherits this component rather than writing
// a second one.

import SwiftUI

/// A seeded topographic field. Same seed, same plot, every launch and every
/// device — the seed is hashed with FNV-1a, never with `Hashable.hashValue`,
/// which Swift seeds per process (the same trap `CSFace.pigmentIndex` names).
public struct CSContour: View {
  /// §16.5 · the contour at `a56`/`a24` is one of the four textures the
  /// credential and the title card ARE made of. Under Reduce Transparency the
  /// isolines take their **composited opaque value** over the ceremony ground
  /// they are always drawn on — the picture is the same picture and no line is
  /// see-through. Resolved here rather than at the three call sites, so a
  /// fourth plate cannot forget.
  @Environment(\.csReduceTransparency) private var reduce
  /// The course id, or — with no home course — the golfer's own id. §2: "No
  /// home course → the curves are seeded from the golfer's id instead, and the
  /// `brand` dot is omitted (there is no hole to point at)."
  let seed: String
  let levels: Int
  let lineWidth: CGFloat
  let tint: Color
  /// The hardest hole by stroke index, placed deterministically in the field.
  /// `nil` when there is no card to read a stroke index from.
  let mark: Color?
  /// **Where the mark is allowed to land, in unit coordinates of the drawn
  /// box.** The dot is placed in the FIELD's own coordinate space, which knows
  /// nothing about the copy on top of it — so on the credential's crest it
  /// landed inside the line of `GALEN MARR`, over the name's letterforms,
  /// where at 7pt on a display-weight name it reads as a dust speck and spends
  /// the card's only ember mark on nothing a golfer can interpret.
  ///
  /// `nil` is the whole box, which is right on the course page: §7 gives the
  /// dot its meaning there, because there is a hole to point at and the plate
  /// is the plate. A caller with copy on the plate passes the quadrant the
  /// copy does not occupy.
  let markSafe: CGRect?

  public init(seed: String, levels: Int = 6, lineWidth: CGFloat = 1.2,
              tint: Color, mark: Color? = nil, markSafe: CGRect? = nil) {
    self.seed = seed
    self.levels = min(7, max(5, levels))
    self.lineWidth = lineWidth
    self.tint = tint
    self.mark = mark
    self.markSafe = markSafe
  }

  /// The stroke actually laid down: the tint as given, or flattened over the
  /// ceremony ground when Reduce Transparency is on.
  private var inkedTint: Color {
    reduce ? CSOpaque.composite(tint, 1, over: CSTokens.dark.ceremony) : tint
  }

  /// The sampling grid. 32 × 32 is the system's number; the marching-squares
  /// pass walks 31 × 31 cells over it.
  static let grid = 32
  /// The lattice the value noise is built on. Four cells across the plate is
  /// what makes the isolines read as a ridge and a basin rather than as a
  /// texture — at eight the field is noise, at two it is one hill.
  static let lattice = 4

  public var body: some View {
    Canvas(rendersAsynchronously: false) { ctx, size in
      // **Cropped hard off its own centre.** The field is drawn at 1.7× the
      // box and pushed up and left, so the plate carries a piece of a place
      // rather than a diagram centred in a frame.
      let side = max(size.width, size.height) * 1.7
      let originX = -side * 0.22
      let originY = -side * 0.30
      let field = Self.field(seed: seed)
      for i in 0..<levels {
        // levels sit inside the field's own range, never at 0 or 1, where
        // marching squares degenerates into the box's own edge
        let t = 0.18 + (0.64 / Double(levels - 1)) * Double(i)
        var path = Path()
        Self.isoline(field, level: t, into: &path)
        let placed = path.applying(
          CGAffineTransform(translationX: originX, y: originY).scaledBy(x: side, y: side))
        ctx.stroke(placed, with: .color(inkedTint),
                   style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
      }
      if let mark {
        // the hardest hole: seeded from the same field, so it lands ON the
        // plot rather than floating over it
        let p = Self.hardestHole(seed: seed)
        var at = CGPoint(x: originX + p.x * side, y: originY + p.y * side)
        if let safe = markSafe {
          // the seeded variation survives; it is only kept out of the band the
          // caller says carries copy
          at.x = min(max(at.x, safe.minX * size.width), safe.maxX * size.width)
          at.y = min(max(at.y, safe.minY * size.height), safe.maxY * size.height)
        }
        ctx.fill(Path(ellipseIn: CGRect(x: at.x - 4, y: at.y - 4, width: 8, height: 8)),
                 with: .color(mark))
      }
    }
    .accessibilityHidden(true)
  }

  // MARK: - the field

  /// A `grid × grid` value-noise field in 0...1, smoothstep-interpolated off a
  /// `lattice × lattice` set of hashed corner values.
  static func field(seed: String) -> [Double] {
    let n = grid, l = lattice
    var corners = [Double](repeating: 0, count: (l + 1) * (l + 1))
    for y in 0...l {
      for x in 0...l { corners[y * (l + 1) + x] = hash01(seed, x, y) }
    }
    var out = [Double](repeating: 0, count: n * n)
    for gy in 0..<n {
      for gx in 0..<n {
        let fx = Double(gx) / Double(n - 1) * Double(l)
        let fy = Double(gy) / Double(n - 1) * Double(l)
        let x0 = min(l - 1, Int(fx)), y0 = min(l - 1, Int(fy))
        let tx = smooth(fx - Double(x0)), ty = smooth(fy - Double(y0))
        let a = corners[y0 * (l + 1) + x0], b = corners[y0 * (l + 1) + x0 + 1]
        let c = corners[(y0 + 1) * (l + 1) + x0], d = corners[(y0 + 1) * (l + 1) + x0 + 1]
        out[gy * n + gx] = (a + (b - a) * tx) + ((c + (d - c) * tx) - (a + (b - a) * tx)) * ty
      }
    }
    return out
  }

  static func smooth(_ t: Double) -> Double { t * t * (3 - 2 * t) }

  /// FNV-1a over the seed and the lattice coordinate. **Not `hashValue`** —
  /// that is seeded per process and would give one course two plots in one day.
  static func hash01(_ seed: String, _ x: Int, _ y: Int) -> Double {
    var h: UInt64 = 0xcbf29ce484222325
    for b in Array(seed.utf8) { h = (h ^ UInt64(b)) &* 0x100000001b3 }
    for b in [UInt8(truncatingIfNeeded: x), UInt8(truncatingIfNeeded: y), 0x5f] {
      h = (h ^ UInt64(b)) &* 0x100000001b3
    }
    return Double(h % 10_000) / 10_000
  }

  /// Where the hardest hole sits, in the field's own unit square.
  static func hardestHole(seed: String) -> CGPoint {
    CGPoint(x: 0.22 + hash01(seed, 91, 7) * 0.5,
            y: 0.24 + hash01(seed, 13, 61) * 0.46)
  }

  // MARK: - marching squares

  /// One isoline of the field, in the unit square, as line segments. Segments
  /// rather than closed curves on purpose: a closed-contour tracer buys a
  /// smoother join and costs a state machine, and at 1.2pt with round caps the
  /// seam is not visible at any scale this plate is drawn at.
  static func isoline(_ f: [Double], level: Double, into path: inout Path) {
    let n = grid
    let step = 1.0 / Double(n - 1)
    for y in 0..<(n - 1) {
      for x in 0..<(n - 1) {
        let tl = f[y * n + x], tr = f[y * n + x + 1]
        let bl = f[(y + 1) * n + x], br = f[(y + 1) * n + x + 1]
        var code = 0
        if tl > level { code |= 8 }
        if tr > level { code |= 4 }
        if br > level { code |= 2 }
        if bl > level { code |= 1 }
        if code == 0 || code == 15 { continue }
        let x0 = Double(x) * step, y0 = Double(y) * step
        func lerp(_ a: Double, _ b: Double) -> Double {
          let d = b - a
          return abs(d) < 1e-9 ? 0.5 : (level - a) / d
        }
        let top = CGPoint(x: x0 + lerp(tl, tr) * step, y: y0)
        let bottom = CGPoint(x: x0 + lerp(bl, br) * step, y: y0 + step)
        let left = CGPoint(x: x0, y: y0 + lerp(tl, bl) * step)
        let right = CGPoint(x: x0 + step, y: y0 + lerp(tr, br) * step)
        func seg(_ a: CGPoint, _ b: CGPoint) { path.move(to: a); path.addLine(to: b) }
        switch code {
        case 1, 14: seg(left, bottom)
        case 2, 13: seg(bottom, right)
        case 3, 12: seg(left, right)
        case 4, 11: seg(top, right)
        case 6, 9:  seg(top, bottom)
        case 7, 8:  seg(left, top)
        // the two saddles: resolved the same way every time, so the plot is
        // stable rather than merely deterministic-looking
        case 5:     seg(left, top); seg(bottom, right)
        case 10:    seg(left, bottom); seg(top, right)
        default:    break
        }
      }
    }
  }
}
