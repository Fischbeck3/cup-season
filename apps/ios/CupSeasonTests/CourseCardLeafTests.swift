// F06 · THE COURSE CARD FITS OR SCROLLS BY ITS MEASURE, AT EVERY SIZE.
//
// The card held its rows at 20pt while their type grew, and chose to scroll by
// the type size alone, so an ordinary-size nine with yardage (358pt of grid in
// a 311pt card on an SE) clipped its Out column off the phone and AX3 printed
// `4…5…1…` in rows it overran. These tests host the real leaf at the two
// phones' measures and at the reading and AX3 sizes, and read back what a
// golfer's finger and VoiceOver meet: the hole columns in order, the total
// last, every column as wide as its widest figure, rows as tall as their type,
// and — when the card does not fit — a scroller whose first and last columns
// can both be brought into view while the key stays where it is.

import Testing
import SwiftUI
import UIKit
import CSDesign
import CupSeasonKit
@testable import CupSeason

@MainActor
@Suite struct CourseCardLeafTests {

  // MARK: an invented tee (no real course)

  static let pars = [4, 5, 3, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 4, 5, 4]
  static let hcps = [7, 3, 17, 11, 1, 15, 5, 13, 9, 8, 18, 4, 12, 2, 16, 10, 6, 14]
  static let yds = [412, 538, 176, 395, 441, 158, 547, 382, 426, 404, 167, 529, 377, 449, 184, 391, 556, 418]

  static func tee(holes n: Int = 18, yards: Bool = true, name: String = "Blue") -> CourseBookTee {
    let hs = (1...n).map { CourseHole(hole: $0, par: pars[$0 - 1], si: hcps[$0 - 1], yards: yards ? yds[$0 - 1] : nil) }
    return CourseBookTee(teeName: name, gender: "male", rating: 71.8, slope: 128, holesCount: n,
                         parTotal: hs.compactMap(\.par).reduce(0, +),
                         yards: yards ? hs.compactMap(\.yards).reduce(0, +) : nil, holes: hs)
  }

  /// The leaf as the whole-card screen sets it: inside the page's gutter.
  static func leaf(_ tee: CourseBookTee, back: Bool = false) -> some View {
    CourseCardLeaf(tee: tee, title: (back ? "The back nine · " : "The front nine · ") + tee.title,
                   range: back ? 10...18 : 1...9, totalLabel: back ? "In" : "Out")
      .padding(.horizontal, CSTokens.Space.gutter)
  }

  /// The SE's and the 17 Pro's widths, and the two sizes the program checks.
  static let phones: [CGFloat] = [375, 402]
  static let sizes: [DynamicTypeSize] = [.large, .accessibility3]

  // MARK: VoiceOver

  @Test("VoiceOver meets one element per hole, in hole order, then the total")
  func oneElementPerHoleInOrder() {
    let h = HostedLayout(Self.leaf(Self.tee()), width: 402)
    defer { h.tearDown() }
    let ids = h.elements.map(\.identifier).filter { $0.hasPrefix("course.card.") && $0 != "course.card.scroll" }
    #expect(ids == (1...9).map { "course.card.hole.\($0)" } + ["course.card.total"], "\(ids)")
    #expect(h.element("course.card.hole.1")?.label == "Hole 1. 412 yards, par 4, handicap 7.")
    #expect(h.element("course.card.hole.3")?.label == "Hole 3. 176 yards, par 3, handicap 17.")
    #expect(h.element("course.card.total")?.label == "Out. 3475 yards, par 36.")
  }

  @Test("the back nine reads ten through eighteen and says In")
  func theBackNineReadsIn() {
    let h = HostedLayout(Self.leaf(Self.tee(), back: true), width: 402)
    defer { h.tearDown() }
    let ids = h.elements(prefix: "course.card.hole.").map(\.identifier)
    #expect(ids == (10...18).map { "course.card.hole.\($0)" })
    #expect(h.element("course.card.total")?.label == "In. 3475 yards, par 36.")
  }

  @Test("a card with no yardage never speaks or prints a yardage")
  func noYardageNoYards() {
    let h = HostedLayout(Self.leaf(Self.tee(yards: false)), width: 375)
    defer { h.tearDown() }
    let cols = h.elements(prefix: "course.card.")
    #expect(!cols.isEmpty)
    for c in cols { #expect(!c.label.contains("yards"), "\(c.identifier): \(c.label)") }
    #expect(h.element("course.card.hole.1")?.label == "Hole 1. par 4, handicap 7.")
  }

  // MARK: geometry

  /// The failure the audit measured: a nine with yardage at the reading size
  /// needed 382pt and ran off an SE. Set with s1 between its figures it needs
  /// ~306, so it prints WHOLE on both phones — no scroller, the Out column on
  /// the page.
  @Test("a nine with yardage prints whole at the reading size on the SE and the 17 Pro")
  func readingSizeNineFitsBothPhones() throws {
    for width in Self.phones {
      for back in [false, true] {
        let h = HostedLayout(Self.leaf(Self.tee(), back: back), width: width)
        defer { h.tearDown() }
        #expect(h.horizontalScrollers.isEmpty, "\(width) \(back ? "back" : "front"): a card that fits does not scroll")
        let total = try #require(h.element("course.card.total"))
        #expect(total.frame.maxX <= width - CSTokens.Space.gutter + 0.5,
                "\(width): the \(back ? "In" : "Out") column sits on the page, at \(total.frame.maxX)")
        let first = try #require(h.element(back ? "course.card.hole.10" : "course.card.hole.1"))
        #expect(first.frame.minX >= CSTokens.Space.gutter + CSTokens.Space.s3 - 0.5, "\(width): the first column too")
      }
    }
  }

  /// At AX3 the nine cannot fit either phone, so it SCROLLS — the key stays
  /// put outside the scroller, the first column is in view at the start and
  /// the total comes fully into view at the end.
  @Test("at AX3 the card scrolls with its key pinned, and both its ends can be reached")
  func ax3ScrollsAndReachesBothEnds() throws {
    for width in Self.phones {
      let h = HostedLayout(Self.leaf(Self.tee()), width: width, typeSize: .accessibility3)
      defer { h.tearDown() }
      let s = try #require(h.horizontalScrollers.first, "\(width): the card must scroll when it cannot fit")
      let visible = h.visibleFrame(s)
      #expect(visible.minX > CSTokens.Space.gutter + CSTokens.Space.s3 + 20,
              "\(width): the key stays outside the scroller — pinned — so the scroller starts after it")
      h.scroll(s, toEnd: false)
      let first = try #require(h.element("course.card.hole.1"))
      #expect(first.frame.minX >= visible.minX - 0.5, "\(width): hole 1 is in view at the start")
      h.scroll(s, toEnd: true)
      let total = try #require(h.element("course.card.total"))
      #expect(total.frame.maxX <= visible.maxX + 0.5, "\(width): the Out column comes fully into view at the end")
      #expect(total.frame.maxX <= width - CSTokens.Space.gutter + 0.5, "\(width): and it never leaves the page")
    }
  }

  /// At AX3 neither phone holds the nine, and both scroll — with rows that
  /// grew: a column is at least as tall as its rows' own lines.
  @Test("at AX3 the card scrolls on both phones and its rows grow with the type")
  func ax3ScrollsWithGrownRows() throws {
    for width in Self.phones {
      let h = HostedLayout(Self.leaf(Self.tee()), width: width, typeSize: .accessibility3)
      defer { h.tearDown() }
      #expect(!h.horizontalScrollers.isEmpty, "\(width) at AX3 scrolls")
      let col = try #require(h.element("course.card.hole.1"))
      let lines = [CSType.Role.columnS, .columnS, .columnM, .columnS]
        .map { Self.lineHeight($0, .accessibility3) }.reduce(0, +) + 3 * CSTokens.Space.s2
      #expect(col.frame.height >= lines - 1,
              "\(width): a hole column is \(col.frame.height)pt for rows that need \(lines)pt — the rows did not grow")
      let reading = HostedLayout(Self.leaf(Self.tee()), width: width)
      defer { reading.tearDown() }
      let base = try #require(reading.element("course.card.hole.1"))
      #expect(col.frame.height > base.frame.height * 1.6, "\(width): AX3 rows are taller than reading-size rows")
    }
  }

  /// Every hole column is as wide as the others and at least as wide as its
  /// widest figure, at every phone and size — so nothing is ellipsised and the
  /// par rule runs straight across.
  @Test("hole columns are even and hold their widest figure, everywhere")
  func columnsAreEvenAndHoldTheirFigures() throws {
    for width in Self.phones {
      for size in Self.sizes {
        for tee in [Self.tee(), Self.tee(yards: false), Self.tee(holes: 9)] {
          let h = HostedLayout(Self.leaf(tee), width: width, typeSize: size)
          defer { h.tearDown() }
          let cols = h.elements(prefix: "course.card.hole.")
          #expect(cols.count == 9, "\(width) \(size): nine columns")
          let widths = cols.map(\.frame.width)
          let spread = (widths.max() ?? 0) - (widths.min() ?? 0)
          #expect(spread < 0.6, "\(width) \(size): columns differ by \(spread)pt")
          let widest = tee.holes.contains { $0.yards != nil }
            ? CSAdvance.width("888", .columnS, size) : CSAdvance.width("88", .columnS, size)
          #expect((widths.min() ?? 0) >= widest, "\(width) \(size): a column narrower than its figure")
        }
      }
    }
  }

  /// A nine-hole tee is a front nine and nothing else; its card still has its
  /// Out column and still decides fit or scroll by the measure.
  @Test("a nine-hole tee prints its nine and its Out on both phones")
  func nineHoleTee() throws {
    for width in Self.phones {
      let h = HostedLayout(Self.leaf(Self.tee(holes: 9)), width: width)
      defer { h.tearDown() }
      #expect(h.elements(prefix: "course.card.hole.").count == 9)
      #expect(h.element("course.card.total") != nil, "\(width): the Out column exists")
    }
  }

  /// A long tee name wraps in the leaf's title rather than widening the card.
  @Test("a long tee name wraps inside the leaf")
  func longTeeNameWraps() throws {
    let long = Self.tee(name: "Championship Tips Extended Back")
    let h = HostedLayout(Self.leaf(long), width: 375, typeSize: .accessibility3)
    defer { h.tearDown() }
    let title = try #require(h.elements.first { $0.label.localizedCaseInsensitiveContains("Championship Tips") })
    #expect(title.frame.maxX <= 375 - CSTokens.Space.gutter + 0.5, "the title stays on the page")
    #expect(title.frame.height > Self.lineHeight(.agateS, .accessibility3) * 1.5, "and it wraps to more lines")
  }

  // MARK: helpers

  static func lineHeight(_ role: CSType.Role, _ size: DynamicTypeSize) -> CGFloat {
    let pt = CSType.renderedSize(role, size)
    let face: String
    switch role.family {
    case .mono: face = role == .columnS ? CSType.monoRegular : CSType.monoMedium
    default: face = CSType.boardSemi
    }
    return UIFont(name: face, size: pt)?.lineHeight ?? pt * 1.2
  }
}
