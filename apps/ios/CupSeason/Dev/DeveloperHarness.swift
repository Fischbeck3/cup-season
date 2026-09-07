// Cup Season — `-cs_dev_developer`: every component in the system, in every
// state it declares, on one scroll.
//
// WHY IT EXISTS. The component wave has no surface to photograph — that is the
// definition of the wave — so without this screen its only evidence would be a
// green test suite, and D197 shipped two regressions past a green test suite.
// A component is a thing you have to see. This is also how every later wave
// checks a regression: change `CSFigure` in Wave 5 and you look here first.
//
// It is arranged as the three system specimens are — 1 type and the figure ·
// 2 controls and states · 3 states and AX3 — so a shot of it can be laid
// beside `system-mockups/renders/cs-system-{a,b,c}.png` and read row for row.
//
// DEBUG only. It reads nothing, writes nothing, and invents no person: every
// face here is a MARKER on a pigment, which is the product's own avatar floor,
// and there is not one fabricated photograph of a human being on it.

#if DEBUG
import SwiftUI
import CSDesign

enum DeveloperHarness {
  static var on: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_developer") }
  /// `-cs_dev_developer <a|b|c>` — one specimen per launch, because a
  /// simulator driven by `simctl` has no finger and cannot scroll. The three
  /// pages are the three system specimens, so a shot lands beside
  /// `cs-system-a/b/c.png` without cropping. No argument = all three, for a
  /// human with a trackpad.
  static var page: String {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_developer"), i + 1 < a.count else { return "all" }
    let next = a[i + 1]
    return ["a", "a2", "b", "c"].contains(next) ? next : "all"
  }
}

struct DeveloperHarnessView: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var chip = 0
  @State private var segment = 0
  @State private var gross = "89"
  @State private var code = "FELLAS-24"
  @State private var strokes = 4
  @State private var budget = CSBudget()

  /// Six ids that land on six different pigments, so the row proves the
  /// deterministic seat rather than illustrating it. Fixed strings, so the
  /// screenshot is the same picture every run.
  private static let ids: [UUID] = {
    var found: [Int: UUID] = [:]
    var n = 0
    while found.count < 6 && n < 4000 {
      let u = UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!
      let m = CSFace.Model(id: u, marker: nil)
      if found[m.pigmentIndex] == nil { found[m.pigmentIndex] = u }
      n += 1
    }
    return (0..<6).compactMap { found[$0] }
  }()

  private static let markers = ["saguaro", "lonetree", "dunes", "thistle", "no2", "jug"]

  private func face(_ i: Int, marker: Bool = true, viewer: Bool = false) -> CSFace.Model {
    CSFace.Model(id: Self.ids[i % Self.ids.count],
                 marker: marker ? Self.markers[i % Self.markers.count] : nil,
                 initials: marker ? "" : "TB", isViewer: viewer)
  }

  private var page: String { DeveloperHarness.page }
  private func on(_ p: String) -> Bool { page == "all" || page == p }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s5) {
        if on("a") { specimenA }
        if on("a2") { specimenA2 }
        if on("b") { specimenB }
        if on("c") { specimenC }
        budgetLine
      }
      // the measure, held: a specimen that overflows sideways is a specimen
      // that photographs the scroll view rather than the system
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.vertical, CSTokens.Space.s5)
    }
    .scrollClipDisabled(false)
    .background(cs.bg0.ignoresSafeArea())
    .csBudgetProbe { b in Task { @MainActor in budget = b } }
  }

  @ViewBuilder private var specimenA: some View {
    Group {
      head("The system · 1 · type and the figure")
      typeSpecimen
      rule
      head("The rule-and-figure · ink / live / earned")
      figures
      rule
      head("Pressed · every tier answers a finger")
      pressedRow
    }
  }

  @ViewBuilder private var specimenA2: some View {
    Group {
      head("The panel · one figure or one word · max 96 × 96")
      panels
      rule
      head("The leaf · a printed grid, and only a printed grid")
      leaf
      rule
      head("The disc · six pigments, keyed to the golfer's id")
      discs
        rule
      head("The board · rail, slat, the merged change cell")
      board
    }
  }

  @ViewBuilder private var specimenB: some View {
    Group {
      head("The system · 2 · controls and states")
      buttons
      rule
      head("Chips · one shape, one height, selected inverts")
      chips
      rule
      head("The field · label, value, caption, error")
      fields
      rule
      head("Movement · a drawn mark on the page's own ground")
      movement
        rule
      head("Empty · a shape, a number, a fact about the world, one door")
      empties
    }
  }

  @ViewBuilder private var specimenC: some View {
    Group {
      head("The system · 3 · states and AX3")
      head2("Loading · the destination's own geometry, redacted")
      loading
      rule
      head2("The toast · one shape, a leading rail, a drawn glyph")
      toasts
      rule
      head2("The drawn family · one hand, 1.7pt on a 24 box")
      glyphs
        rule
      head2("The chrome · the masthead and the tab band")
      chrome
    }
  }

  // MARK: pieces

  private func head(_ t: String) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      Text(t).csType(.agate, caps: true).foregroundStyle(cs.mut)
      CSRule()
    }
  }
  private func head2(_ t: String) -> some View {
    Text(t).csType(.agateS, caps: true).foregroundStyle(cs.mut)
  }
  private var rule: some View { CSRule().padding(.vertical, CSTokens.Space.s2) }

  private var typeSpecimen: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      Text("Display 34 · caps").csType(.display).foregroundStyle(cs.ink)
      Text("Lead 28 · the serif, once a surface").csType(.lead).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text("Title 24 · caps").csType(.displayS).foregroundStyle(cs.ink)
      Text("Name 17 · the board").csType(.name).foregroundStyle(cs.ink)
      Text("Social 17 · a person in a row").csType(.social).foregroundStyle(cs.ink)
      Text("Body 17 · SF Pro. Prose, standfirsts and every sentence the product says out loud.")
        .csType(.body).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
      Text("Agate 12 · the metadata voice").csType(.agate, caps: true).foregroundStyle(cs.mut)
      // the tabular proof: two rows of different digits, and they line up.
      // Stacked rather than side by side, because at AX3 two 60pt runs on one
      // line is 324 of a 362 measure and the specimen would be proving the
      // wrong thing.
      VStack(alignment: .leading, spacing: 0) {
        Text("Col 14 · 4 5 3 4 4 · 36").csType(.columnM).foregroundStyle(cs.mut)
        Text("Col 14 · 1 1 1 1 1 · 09").csType(.columnM).foregroundStyle(cs.mut)
      }
      .lineLimit(1).minimumScaleFactor(0.5)
      VStack(alignment: .leading, spacing: 0) {
        Text("0000").csType(.figureL).foregroundStyle(cs.ink)
        Text("1111").csType(.figureL).foregroundStyle(cs.mut)
      }
      Text("Tabular · the two runs above are the same width, or the board is a lie")
        .csType(.agateS, caps: false).foregroundStyle(cs.mut)
    }
  }

  private var figures: some View {
    A11yStack(rowAlignment: .top, spacing: CSTokens.Space.s4, columnSpacing: CSTokens.Space.s4) {
      CSFigure("10.6", size: .l, metal: .ink, label: "Handicap index")
      CSFigure("02", size: .l, metal: .live, label: "Days out")
      CSFigure("$480", size: .l, metal: .earned, label: "The pot")
    }
  }

  private var panels: some View {
    A11yStack(rowAlignment: .top, spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s3) {
      CSPanel(unit: "Of eight") {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          Text("2").csType(.figureXL)
          Text("nd").csType(.agate, caps: true)
        }
      }
      CSPanel(unit: "Gross") { Text("79").csType(.figureL) }
      CSPanel { Text("Posted").csType(.name) }
      Text("A panel never holds a sentence. If it ever does, it has become a card.")
        .csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var leaf: some View {
    CSLeaf {
      Grid(alignment: .leading, horizontalSpacing: CSTokens.Space.s3, verticalSpacing: CSTokens.Space.s2) {
        GridRow {
          Text("Hole").csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
          ForEach(1...6, id: \.self) { i in
            Text("\(i)").csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
          }
          Text("Out").csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
        }
        GridRow {
          Text("You").csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
          CSScoreMark(-1, numeral: "3", size: 26)
          CSScoreMark(0, numeral: "5", size: 26)
          CSScoreMark(1, numeral: "4", size: 26)
          CSScoreMark(0, numeral: "4", size: 26)
          CSScoreMark(2, numeral: "7", size: 26)
          CSScoreMark(-2, numeral: "2", size: 26)
          Text("38").csType(.columnM)
        }
      }
      Text("Ring birdie · double ring eagle · box bogey · double box worse · no colour")
        .csType(.agateS, caps: true).foregroundStyle(cs.leafMut)
        .padding(.top, CSTokens.Space.s2)
    }
  }

  private var discs: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      HStack(spacing: CSTokens.Space.s2) {
        ForEach(0..<6, id: \.self) { i in CSFace(face(i), size: .list) }
        CSFace(face(0, marker: false), size: .list)
        CSMedallion("jug", size: 38)
      }
      HStack(spacing: CSTokens.Space.s3) {
        ForEach([CSFace.Size.inline, .slat, .list, .block], id: \.rawValue) { s in
          CSFace(face(1), size: s)
        }
        CSFace(face(2, viewer: true), size: .block, sideRing: cs.sq0)
      }
      Text("Five sizes · the initials rung only when a golfer chose nothing · the side ring is team events only")
        .csType(.agateS, caps: false).foregroundStyle(cs.mut)
    }
  }

  private var board: some View {
    CSStandingsBoard(count: 3, cut: "Cut · top two play the Cup Final", cutAfter: 2) { i, abbreviate in
      let names = ["Galen Marr", "You", "Priya Raghunathan"]
      let name = i == 1 ? "You" : (abbreviate ? initialled(names[i]) : names[i])
      CSSlat(rank: i + 1,
             field: i == 0 ? .earned : (i == 1 ? .mine : .none),
             face: face(i + 2),
             name: name,
             sub: i == 0 ? "11 rounds · best 74" : "3 rounds · one short",
             squad: i == 2 ? (cs.sq1, "Mudsharks") : nil,
             movement: i == 0 ? .held : (i == 1 ? .up(2) : .down(1)),
             gap: i == 0 ? nil : (i == 1 ? "+9" : "+12")) {
        Text(["104", "95", "88"][i]).csType(.figureM).foregroundStyle(i == 0 ? cs.gold : cs.ink)
      }
    }
  }

  private func initialled(_ full: String) -> String {
    let parts = full.split(separator: " ")
    guard parts.count > 1, let f = parts.first?.first else { return full }
    return "\(f). " + parts.dropFirst().joined(separator: " ")
  }

  private var buttons: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      A11yStack(spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s3) {
        Button("Add my round") {}.buttonStyle(.csPrimary)
        Button("Put it on the plan") {}.buttonStyle(.csSecondary)
      }
      A11yStack(spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s3) {
        Button("Pressed") {}.buttonStyle(.csPrimary(held: true))
        Button("Disabled") {}.buttonStyle(.csPrimary).disabled(true)
        Button("Working") {}.buttonStyle(.csPrimary(busy: true))
      }
      A11yStack(spacing: CSTokens.Space.s4, columnSpacing: CSTokens.Space.s3) {
        Button("The season's story") {}.buttonStyle(.csTertiary(.live))
        Button("Settings") {}.buttonStyle(.csTertiary(.content))
        Button("Close") {}.buttonStyle(.csTertiary(.toolbar))
      }
      Button("Sure?") {}.buttonStyle(.csDestructive).frame(maxWidth: 200)
      Text("A disabled primary is never ember · one primary per screen · there is no gold button")
        .csType(.agateS, caps: false).foregroundStyle(cs.mut)
    }
  }

  /// Every tier, held. The styles draw their own pressed body — nothing here
  /// hand-copies a fill, which is the duplication `Controls.swift` exists to
  /// remove.
  private var pressedRow: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      A11yStack(spacing: CSTokens.Space.s3, columnSpacing: CSTokens.Space.s3) {
        Button("Primary held") {}.buttonStyle(.csPrimary(held: true))
        Button("Secondary held") {}.buttonStyle(.csSecondary(held: true))
      }
      A11yStack(spacing: CSTokens.Space.s4, columnSpacing: CSTokens.Space.s3) {
        Button("Live link") {}.buttonStyle(.csTertiary(.live, held: true))
        Button("Content") {}.buttonStyle(.csTertiary(.content, held: true))
        Button("Toolbar") {}.buttonStyle(.csTertiary(.toolbar, held: true))
      }
      Text("Held · the fill darkens by a16, the label to 92%, the rule steps up")
        .csType(.agateS, caps: false).foregroundStyle(cs.mut)
    }
  }

  private var chips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: CSTokens.Space.s2) {
      ForEach(Array(["All eight", "This month", "Counting"].enumerated()), id: \.offset) { i, t in
        Button { chip = i } label: { EmptyView() }.buttonStyle(.plain).frame(width: 0, height: 0)
        CSChip(t, selected: chip == i).onTapGesture { chip = i }
      }
        CSChip("Squads", selected: false, enabled: false)
      }
    }
  }

  private var fields: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
      CSField(label: "Your gross", placeholder: "89", text: $gross,
              caption: "Front and back, or the whole card.", kind: .code)
      CSField(label: "League code", placeholder: "FELLAS-24", text: $code,
              error: "That code has expired. Ask the Pro for a new one.",
              limit: 12, kind: .code)
      CSField(label: "Disabled", placeholder: "Nothing to type", text: .constant(""),
              caption: "A disabled field is bg1 with a mut value.").disabled(true)
      HStack(spacing: CSTokens.Space.s4) {
        CSStepper(value: strokes, label: "Strokes") { strokes = $0 }
        CSSegment([(0, "Standings"), (1, "Board"), (2, "Pot")], selection: $segment)
      }
    }
  }

  private var movement: some View {
    HStack(spacing: CSTokens.Space.s4) {
      CSMovement(.up(2))
      CSMovement(.down(1))
      CSMovement(.held)
      Text("Up · down · held").csType(.agateS, caps: true).foregroundStyle(cs.mut)
    }
  }

  private var empties: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s5) {
      CSEmpty(glyph: .scorecard, eyebrow: "The first card",
              headline: "Nobody here has played it.",
              fact: "Dinosaur Mountain is on the board because Galen keeps it.",
              door: .link("Post a round here", {}))
      CSEmpty(glyph: .scheduleSheet, eyebrow: "The schedule",
              headline: "Nothing is on the schedule this week.",
              number: .panel("0", "Planned"),
              door: .elsewhere("The four doors are at the foot of this page."))
    }
  }

  private var loading: some View {
    VStack(spacing: 0) {
      ForEach(0..<2, id: \.self) { i in
        CSSlat(rank: i + 1, field: .none, face: face(i), name: "Loading name",
               sub: "3 rounds · held", movement: .held, gap: "+4") {
          Text("104").csType(.figureM)
        }
      }
    }
    .csRedacted(true)
  }

  private var toasts: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      toast(.confirmed, "Round posted. It counts — 9 points.", action: nil)
      toast(.failed, "That reaction did not save.", action: "Retry")
      toast(.neutral, "Working on it.", action: nil)
    }
  }

  private func toast(_ kind: CSToastCenter.Kind, _ text: String, action: String?) -> some View {
    HStack(spacing: CSTokens.Space.s3) {
      Rectangle().fill(kind == .confirmed ? cs.pos : (kind == .failed ? cs.neg : cs.rule)).frame(width: 3)
      if kind == .confirmed { CSGlyph(.check).foregroundStyle(cs.pos) }
      if kind == .failed { CSGlyph(.cross).foregroundStyle(cs.neg) }
      Text(text).csType(.bodyS).foregroundStyle(cs.ink)
      if let action {
        Spacer(minLength: CSTokens.Space.s2)
        Button(action) {}.buttonStyle(.csTertiary(.content))
      }
    }
    .padding(.horizontal, CSTokens.Space.s3)
    .frame(minHeight: 46)
    .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
  }

  private var glyphs: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      ForEach(Array(stride(from: 0, to: CSGlyph.Name.allCases.count, by: 6)), id: \.self) { start in
        HStack(spacing: CSTokens.Space.s4) {
          Spacer(minLength: 0).frame(width: 0)
          ForEach(Array(CSGlyph.Name.allCases[start..<min(start + 6, CSGlyph.Name.allCases.count)]), id: \.self) { n in
            CSGlyph(n, size: .block).foregroundStyle(n == .play ? cs.brand : cs.mut)
          }
        }
      }
    }
  }

  private var chrome: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
      CSMasthead(date: Date(timeIntervalSince1970: 1_788_652_800))
      CSFactStrip([
        .init(value: "10.6", label: "Your number"),
        .init(value: "79", label: "Last round"),
        .init(value: "2", label: "Position", ordinal: "nd"),
      ], standing: "The Fellas · 2nd of 8 · 4 back of Galen")
      CSStakeLine(.pot, amount: "$480")
      CSSeasonCalendar(weeks: 13, played: 6, now: 6, months: ["Jul", "Aug", "Sep"])
      CSTabBand([
        .init(id: 0, glyph: .home, label: "Home"),
        .init(id: 1, glyph: .pennant, label: "Compete"),
        .init(id: 2, glyph: .play, label: "Play", isPlay: true),
        .init(id: 3, glyph: .people, label: "Golfers"),
        .init(id: 4, glyph: .card, label: "You"),
      ], selection: .constant(0))
    }
  }

  /// The budgets, read back off the screen that just drew — which is the only
  /// place they can be counted. A harness deliberately spends more than a
  /// surface may, so the numbers here are a READING, not a pass mark.
  private var budgetLine: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
      head2("The probe · what this viewport spent")
      Text("Agate caps \(budget.agateCapsLines) · display \(budget.display) · gold \(budget.goldObjects) · ember \(budget.emberMarks) · nested \(budget.nestedContainers)")
        .csType(.columnS).foregroundStyle(cs.mut)
      Text("A harness is not a surface: it spends every budget on purpose. The number a wave cares about is the one its own root reads.")
        .csType(.agateS, caps: false).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
#endif
