// Cup Season — a small SVG path-data parser for the marker glyphs.
//
// Covers exactly the commands the 14 markers use (M L H V C S A Z, absolute
// and relative; tools/build-markers.mjs refuses anything else). Elliptical
// arcs are converted endpoint→center and approximated with cubic Béziers,
// the standard technique. No dependency, no runtime SVG library.

import SwiftUI

public enum SVGPath {
  /// Parse SVG path data into a SwiftUI `Path`. Returns what it managed to
  /// parse on malformed input rather than crashing — a marker that fails to
  /// draw is a bug to fix, not a reason to take the app down.
  public static func path(_ d: String) -> Path {
    var p = Path()
    let tokens = tokenize(d)
    var i = 0
    var cmd: Character = "M"
    var cur = CGPoint.zero, start = CGPoint.zero
    var lastCtrl: CGPoint? = nil
    var lastCmd: Character = "M"

    func num() -> CGFloat? {
      guard i < tokens.count, case .number(let n) = tokens[i] else { return nil }
      i += 1
      return n
    }

    while i < tokens.count {
      if case .command(let c) = tokens[i] { cmd = c; i += 1 }
      let rel = cmd.isLowercase
      let u = Character(cmd.uppercased())
      switch u {
      case "M":
        guard let x = num(), let y = num() else { return p }
        cur = rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
        p.move(to: cur); start = cur; lastCtrl = nil
        cmd = rel ? "l" : "L"   // implicit lineto after moveto
      case "L":
        guard let x = num(), let y = num() else { return p }
        cur = rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
        p.addLine(to: cur); lastCtrl = nil
      case "H":
        guard let x = num() else { return p }
        cur = CGPoint(x: rel ? cur.x + x : x, y: cur.y)
        p.addLine(to: cur); lastCtrl = nil
      case "V":
        guard let y = num() else { return p }
        cur = CGPoint(x: cur.x, y: rel ? cur.y + y : y)
        p.addLine(to: cur); lastCtrl = nil
      case "C":
        guard let x1 = num(), let y1 = num(), let x2 = num(), let y2 = num(), let x = num(), let y = num() else { return p }
        let o = rel ? cur : .zero
        let c1 = CGPoint(x: o.x + x1, y: o.y + y1)
        let c2 = CGPoint(x: o.x + x2, y: o.y + y2)
        cur = CGPoint(x: o.x + x, y: o.y + y)
        p.addCurve(to: cur, control1: c1, control2: c2); lastCtrl = c2
      case "S":
        guard let x2 = num(), let y2 = num(), let x = num(), let y = num() else { return p }
        let o = rel ? cur : .zero
        // reflect the previous control point when the previous command was a curve
        let c1: CGPoint
        if (lastCmd == "C" || lastCmd == "S"), let lc = lastCtrl {
          c1 = CGPoint(x: 2 * cur.x - lc.x, y: 2 * cur.y - lc.y)
        } else {
          c1 = cur
        }
        let c2 = CGPoint(x: o.x + x2, y: o.y + y2)
        cur = CGPoint(x: o.x + x, y: o.y + y)
        p.addCurve(to: cur, control1: c1, control2: c2); lastCtrl = c2
      case "A":
        guard let rx = num(), let ry = num(), let rot = num(), let large = num(), let sweep = num(), let x = num(), let y = num() else { return p }
        let end = rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
        arc(&p, from: cur, to: end, rx: rx, ry: ry, rotation: rot, largeArc: large != 0, sweep: sweep != 0)
        cur = end; lastCtrl = nil
      case "Z":
        p.closeSubpath(); cur = start; lastCtrl = nil
      default:
        return p
      }
      lastCmd = u
    }
    return p
  }

  // MARK: - tokenizer

  enum Token: Equatable { case command(Character), number(CGFloat) }

  private static func argCount(_ c: Character) -> Int {
    switch Character(c.uppercased()) {
    case "M", "L": 2
    case "H", "V": 1
    case "C": 6
    case "S": 4
    case "A": 7
    default: 0
    }
  }

  /// Command-aware: an arc's two flags are exactly one character each, so
  /// "0 11-2.4 0" and "012.4 0" split the way SVG intends. A second "." in a
  /// digit run starts a new number ("1.2.3" → 1.2, .3).
  static func tokenize(_ d: String) -> [Token] {
    var out: [Token] = []
    let chars = Array(d)
    var i = 0
    var cmd: Character = "M"
    var argIndex = 0
    while i < chars.count {
      let ch = chars[i]
      if ch.isLetter {
        cmd = ch; argIndex = 0; out.append(.command(ch)); i += 1; continue
      }
      if ch == " " || ch == "," || ch == "\n" || ch == "\t" || ch == "\r" {
        i += 1; continue
      }
      let isArc = cmd == "A" || cmd == "a"
      if isArc && (argIndex == 3 || argIndex == 4) {
        guard ch == "0" || ch == "1" else { return out }
        out.append(.number(ch == "1" ? 1 : 0)); argIndex += 1; i += 1
        continue
      }
      var s = ""
      if ch == "-" || ch == "+" { s.append(ch); i += 1 }
      var seenDot = false
      while i < chars.count {
        let c = chars[i]
        if c.isNumber { s.append(c); i += 1 }
        else if c == "." && !seenDot { seenDot = true; s.append(c); i += 1 }
        else { break }
      }
      guard let v = Double(s) else { return out }
      out.append(.number(CGFloat(v)))
      argIndex += 1
      let n = argCount(cmd)
      if n > 0 && argIndex >= n {
        argIndex = 0
        if cmd == "M" { cmd = "L" } else if cmd == "m" { cmd = "l" }
      }
    }
    return out
  }

  // MARK: - arcs (SVG 1.1 §F.6.5, then cubic approximation)

  private static func arc(_ p: inout Path, from p0: CGPoint, to p1: CGPoint, rx rxIn: CGFloat, ry ryIn: CGFloat, rotation deg: CGFloat, largeArc: Bool, sweep: Bool) {
    if p0 == p1 { return }
    var rx = abs(rxIn), ry = abs(ryIn)
    if rx == 0 || ry == 0 { p.addLine(to: p1); return }
    let phi = deg * .pi / 180
    let cosPhi = cos(phi), sinPhi = sin(phi)
    let dx2 = (p0.x - p1.x) / 2, dy2 = (p0.y - p1.y) / 2
    let x1p = cosPhi * dx2 + sinPhi * dy2
    let y1p = -sinPhi * dx2 + cosPhi * dy2
    let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
    if lambda > 1 { rx *= sqrt(lambda); ry *= sqrt(lambda) }
    let rx2 = rx * rx, ry2 = ry * ry
    var num = rx2 * ry2 - rx2 * y1p * y1p - ry2 * x1p * x1p
    if num < 0 { num = 0 }
    let den = rx2 * y1p * y1p + ry2 * x1p * x1p
    var coef = den > 0 ? sqrt(num / den) : 0
    if largeArc == sweep { coef = -coef }
    let cxp = coef * (rx * y1p / ry)
    let cyp = coef * -(ry * x1p / rx)
    let cx = cosPhi * cxp - sinPhi * cyp + (p0.x + p1.x) / 2
    let cy = sinPhi * cxp + cosPhi * cyp + (p0.y + p1.y) / 2

    func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
      let dot = ux * vx + uy * vy
      let len = sqrt(ux * ux + uy * uy) * sqrt(vx * vx + vy * vy)
      var a = acos(max(-1, min(1, len > 0 ? dot / len : 1)))
      if ux * vy - uy * vx < 0 { a = -a }
      return a
    }
    let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
    var dtheta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
    if !sweep && dtheta > 0 { dtheta -= 2 * .pi }
    if sweep && dtheta < 0 { dtheta += 2 * .pi }

    let segments = max(1, Int(ceil(abs(dtheta) / (.pi / 2))))
    let delta = dtheta / CGFloat(segments)
    let t = 4 / 3 * tan(delta / 4)
    var th = theta1
    func map(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: cx + rx * cosPhi * x - ry * sinPhi * y, y: cy + rx * sinPhi * x + ry * cosPhi * y)
    }
    for _ in 0..<segments {
      let cos1 = cos(th), sin1 = sin(th), cos2 = cos(th + delta), sin2 = sin(th + delta)
      let e1 = map(cos1 - t * sin1, sin1 + t * cos1)
      let e2 = map(cos2 + t * sin2, sin2 - t * cos2)
      p.addCurve(to: map(cos2, sin2), control1: e1, control2: e2)
      th += delta
    }
  }
}
