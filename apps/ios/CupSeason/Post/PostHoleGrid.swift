// Cup Season — the hole-by-hole card as a scorecard strip (IOS-020;
// `renderPostHoles` 6131–6162, the pars sheet `openPostParsSheet` 6272–6323,
// the even-par guard 6325–6337, the 18/9 seg 3120–3123).
//
// "Each hole starts on par — tap to adjust only what you didn't." A real card:
// an OUT row of nine cells and an IN row of nine, a total cell at the end of
// each; tap a cell to select it, and ONE big − / + under the strip drives the
// selected hole. Cells colour by result — eagle gold, birdie `pos`, bogey
// muted — exactly as the web's grid did. The selection is the view's; the
// card (`PostCard`) never knows which hole is under the thumb.

import SwiftUI
import CSDesign
import CupSeasonKit

/// The `.seg`: "18 holes / 9 holes" and the D34 mode pair.
struct PostSeg<T: Hashable>: View {
  @Environment(\.cs) private var cs
  let options: [(T, String)]
  let selection: T
  let pick: (T) -> Void
  var body: some View {
    HStack(spacing: 4) {
      ForEach(options, id: \.0) { k, l in
        let on = selection == k
        Button { pick(k) } label: {
          Text(l).font(CSFont.monoSmall).foregroundStyle(on ? cs.bg0 : cs.ink)
            .padding(.horizontal, 12).frame(minHeight: 36).frame(maxWidth: .infinity)
            .background(on ? cs.ink : cs.bg2, in: Capsule())
            .overlay(Capsule().stroke(cs.line2, lineWidth: on ? 0 : 1))
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l)
        .accessibilityAddTraits(on ? .isSelected : [])
      }
    }
  }
}

// MARK: - the strip

struct PostScorecardStrip: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @Bindable var model: PostRoundModel
  @State private var selected: Int

  init(model: PostRoundModel, selected: Int = 0) {
    self.model = model
    _selected = State(initialValue: selected)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      card
      stepper
      VStack(alignment: .leading, spacing: 0) {
        CSFine("Each hole starts on par — tap to adjust only what you didn't.")
        Button { model.showPars = true } label: {
          Text("Set the pars →").font(CSFont.footnote).foregroundStyle(cs.brand).frame(minHeight: 44)
        }
        .buttonStyle(.plain)
      }
      if model.card.scan != nil {
        // the scan's escape hatch: a bad read never traps anyone in the grid
        Button { model.scrapScan() } label: {
          Label("Scrap the scan — type front & back instead", systemImage: "xmark").font(CSFont.footnote).foregroundStyle(cs.mut)
            .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      } else {
        Button { model.setMode(.total) } label: {
          Text("Front & back").font(CSFont.footnote).foregroundStyle(cs.mut).frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Switches to two gross figures")
      }
    }
    .onChange(of: model.card.side) { _, s in selected = PostStrip.clamp(selected, side: s) }
  }

  // MARK: the card — OUT and IN, hairlines between the cells

  /// At accessibility sizes the ten cells cannot share the width without
  /// clipping a figure, so the card scrolls sideways under a fixed cell width
  /// (IOS-022 item 9) — a scorecard is a strip, and a strip reads left to right.
  @ViewBuilder private var card: some View {
    if typeSize.isAccessibilitySize {
      ScrollView(.horizontal, showsIndicators: false) { cardBody(cellWidth: 72) }
        .padding(.horizontal, -20)
        .contentMargins(.horizontal, 20, for: .scrollContent)
    } else {
      cardBody(cellWidth: nil)
    }
  }

  private func cardBody(cellWidth: CGFloat?) -> some View {
    VStack(spacing: 1) {
      row(0, cellWidth: cellWidth)
      if model.card.side == 18 { row(1, cellWidth: cellWidth) }
    }
    .padding(1)
    .background(cs.line, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .clipShape(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
  }

  private func row(_ r: Int, cellWidth: CGFloat?) -> some View {
    HStack(spacing: 1) {
      ForEach(Array(PostStrip.row(r)), id: \.self) { i in cell(i).frame(width: cellWidth) }
      totalCell(r).frame(width: cellWidth)
    }
  }

  private func tone(_ i: Int) -> Color {
    switch model.card.result(at: i) {
    case .eagle: cs.gold
    case .birdie: cs.pos
    case .bogey: cs.mut
    case .par: cs.ink
    }
  }

  private func cell(_ i: Int) -> some View {
    let par = model.card.pars[i], sc = model.card.scores[i]
    let on = selected == i
    return Button {
      withAnimation(CSMotion.rise) { selected = i }
      CSHaptic.selection()
    } label: {
      VStack(spacing: 3) {
        Text("\(i + 1)").font(CSFont.label).foregroundStyle(on ? cs.brand : cs.dimText)
        Text("\(sc)").font(CSFont.stat).csTabular().foregroundStyle(tone(i))
          .lineLimit(1).minimumScaleFactor(0.7)
          .contentTransition(.numericText())
        Text("P\(par)").font(CSFont.label).foregroundStyle(cs.dimText)
      }
      .frame(maxWidth: .infinity, minHeight: 66)
      .background(cs.bg1)
      .overlay {
        if on {
          RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(cs.brand, lineWidth: 2).padding(2)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(PostStrip.cellLabel(hole: i, par: par, score: sc))
    .accessibilityAddTraits(on ? [.isSelected] : [])
    .accessibilityHint("Selects the hole for the stepper")
  }

  private func totalCell(_ r: Int) -> some View {
    let total = PostStrip.total(model.card.scores, row: r)
    let par = PostStrip.par(model.card.pars, row: r)
    return VStack(spacing: 3) {
      Text(r == 0 ? "OUT" : "IN").font(CSFont.label).tracking(0.8).foregroundStyle(cs.mut)
      Text("\(total)").font(CSFont.stat).csTabular().foregroundStyle(cs.ink)
        .lineLimit(1).minimumScaleFactor(0.7)
        .contentTransition(.numericText())
      Text("P\(par)").font(CSFont.label).foregroundStyle(cs.dimText)
    }
    .frame(maxWidth: .infinity, minHeight: 66)
    .background(cs.bg2)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(r == 0 ? "Out" : "In"), \(total) strokes, par \(par)")
    .accessibilityAddTraits(.updatesFrequently)
  }

  // MARK: the stepper — one for the whole card

  private var stepper: some View {
    let i = PostStrip.clamp(selected, side: model.card.side)
    let par = model.card.pars[i], sc = model.card.scores[i]
    return VStack(spacing: 4) {
      HStack(spacing: 14) {
        step("−", "Minus hole \(i + 1)") { model.minus(i) }
        VStack(spacing: 0) {
          Text(PostStrip.stepperEyebrow(hole: i, par: par)).csEyebrow()
          Text("\(sc)").font(CSFont.hero).csTabular().foregroundStyle(tone(i))
            .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
        step("+", "Plus hole \(i + 1)") { model.plus(i) }
      }
      Button {
        withAnimation(CSMotion.rise) { selected = PostStrip.next(after: i, side: model.card.side) }
        CSHaptic.selection()
      } label: {
        Text("Next hole →").font(CSFont.footnote).foregroundStyle(cs.dawn).frame(maxWidth: .infinity, minHeight: 44)
      }
      .buttonStyle(.plain)
    }
  }

  private func step(_ glyph: String, _ label: String, _ action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(glyph).font(.system(size: 26, weight: .medium)).foregroundStyle(cs.ink)
        .frame(minWidth: 60, minHeight: 60)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }
}

// MARK: - Set the pars (`openPostParsSheet`)

struct PostParsSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let model: PostRoundModel
  @State private var front = ""
  @State private var back = ""
  @FocusState private var focus: Field?
  enum Field { case front, back }

  private var nine: Bool { model.card.side == 9 }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 10) {
          CSSheetHeader(title: "Set the pars", sub: ((model.card.course.isEmpty ? "Course" : model.card.course) + " · pars only").uppercased())
          sideField("Front nine", $front, .front)
          if !nine { sideField("Back nine", $back, .back) }
          HStack {
            Text("Total par").font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
            Spacer()
            let ok = PostPars.validSide(front) && (nine || PostPars.validSide(back))
            Text(ok ? "\(PostPars.sum(front) + (nine ? 0 : PostPars.sum(back)))" : "—").font(CSFont.stat).csTabular().foregroundStyle(ok ? cs.pos : cs.mut)
          }
          .accessibilityElement(children: .combine)
          .accessibilityAddTraits(.updatesFrequently)
          CSFine("Nine digits a side, 3–6. \(nine ? "Front nine only." : "Type it once.") Only matters if this course isn't par 72 — exact stroke index arrives with the course database.")
          CSButton("Done") { if model.setPars(front: front, back: back) { dismiss() } }.padding(.top, 4)
        }
        .padding(20)
      }
      .background(cs.bg0)
      .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() }.foregroundStyle(cs.mut) } }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .onAppear {
      front = model.card.pars.prefix(9).map(String.init).joined()
      back = model.card.pars.dropFirst(9).map(String.init).joined()
      focus = .front
    }
  }

  private func sideField(_ label: String, _ text: Binding<String>, _ f: Field) -> some View {
    let v = text.wrappedValue
    let sum = v.isEmpty ? "—" : "\(PostPars.sum(v))"
    let bad = v.count == 9 && !PostPars.validSide(v)
    return VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
        Spacer()
        Text(sum).font(CSFont.monoMediumBody).foregroundStyle(v.isEmpty ? cs.mut : (PostPars.validSide(v) ? cs.pos : cs.neg))
      }
      TextField(f == .front ? "453453543" : "434445345", text: text)
        .accessibilityLabel("\(label) pars, nine digits")
        .font(CSFont.code).csTabular().keyboardType(.numberPad)
        .foregroundStyle(bad ? cs.neg : cs.ink)
        .padding(.horizontal, 14).frame(minHeight: 56)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(bad ? cs.neg : (focus == f ? cs.focus : cs.line), lineWidth: focus == f ? 2 : 1))
        .focused($focus, equals: f)
        .onChange(of: v) { _, n in
          let c = PostPars.clean(n)
          if c != n { text.wrappedValue = c }
          if f == .front, !nine, c.count == 9 { focus = .back }
        }
    }
  }
}

// MARK: - the even-par guard (F2)

struct PostEvenParSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let model: PostRoundModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      CSSheetHeader(title: "Post as even par?", sub: "YOU HAVEN’T ENTERED YOUR CARD YET")
      CSFine("Each hole is still on par, so this would post an even-par \(model.card.evenParTotal) — and it counts on your card and in every league.")
      CSButton("Enter my card") { dismiss() }
      CSButton("Post even par anyway", style: .quiet) { model.postEvenParAnyway() }
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(cs.bg0)
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }
}
