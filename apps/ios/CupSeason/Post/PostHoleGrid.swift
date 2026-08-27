// Cup Season — the hole-by-hole card (`renderPostHoles` 6131–6162, the pars
// sheet `openPostParsSheet` 6272–6323, the even-par guard 6325–6337, the
// 18/9 seg 3120–3123).
//
// "Each hole starts on par — tap to adjust only what you didn't." Cells colour
// by result — eagle gold, birdie `pos`, bogey muted — and every ± is a 44pt
// target with a selection tick (IOS-003 §2.8).

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
        .accessibilityAddTraits(on ? .isSelected : [])
      }
    }
  }
}

struct PostHoleGrid: View {
  @Environment(\.cs) private var cs
  @Bindable var model: PostRoundModel

  private let columns = [GridItem(.adaptive(minimum: 104), spacing: 6)]

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      side(0..<9)
      if model.card.side == 18 { side(9..<18).padding(.top, 2) }
      HStack(spacing: 0) {
        Text("Each hole starts on par — tap to adjust only what you didn't. ").font(CSFont.footnote).foregroundStyle(cs.dimText)
        Button("Set the pars →") { model.showPars = true }.font(CSFont.footnote).foregroundStyle(cs.brand)
      }
      .padding(.top, 6)
      .fixedSize(horizontal: false, vertical: true)
      if model.card.scan != nil {
        // the scan's escape hatch: a bad read never traps anyone in the grid
        Button { model.scrapScan() } label: {
          Label("Scrap the scan — type front & back instead", systemImage: "xmark").font(CSFont.footnote).foregroundStyle(cs.mut)
        }
        .frame(minHeight: 44)
      } else {
        Button { model.setMode(.total) } label: {
          Text("Front & back").font(CSFont.footnote).foregroundStyle(cs.mut)
        }
        .frame(minHeight: 44)
      }
    }
  }

  private func side(_ r: Range<Int>) -> some View {
    LazyVGrid(columns: columns, spacing: 6) {
      ForEach(Array(r), id: \.self) { i in cell(i) }
    }
  }

  private func cell(_ i: Int) -> some View {
    let par = model.card.pars[i], sc = model.card.scores[i]
    let tone: Color = switch model.card.result(at: i) {
    case .eagle: cs.gold
    case .birdie: cs.pos
    case .bogey: cs.mut
    case .par: cs.ink
    }
    return VStack(spacing: 2) {
      Text("\(i + 1) · P\(par)").font(CSFont.label).tracking(0.4).foregroundStyle(cs.dimText)
      HStack(spacing: 3) {
        step("−", "Minus hole \(i + 1)") { model.minus(i) }
        Text("\(sc)").font(CSFont.monoMediumBody.weight(.semibold)).csTabular().foregroundStyle(tone).frame(minWidth: 22)
        step("+", "Plus hole \(i + 1)") { model.plus(i) }
      }
    }
    .padding(.vertical, 5).padding(.horizontal, 2)
    .frame(maxWidth: .infinity)
    .background(cs.bg2, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(cs.line, lineWidth: 0.5))
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Hole \(i + 1), par \(par), \(sc) strokes")
  }

  private func step(_ glyph: String, _ label: String, _ action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(glyph).font(.system(size: 15)).foregroundStyle(cs.ink)
        .frame(width: 30, height: 30)
        .background(cs.bg0, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(cs.line, lineWidth: 0.5))
        .frame(width: 44, height: 44)
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
