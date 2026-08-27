// Cup Season — the wizard's three panes (index.html 3214–3312), the dials
// (`.setrow` steppers, `.seg` segments, the `i` help buttons) and the
// portrait (`wizPortrait`, 11847–11890) as a card in the flow.

import SwiftUI
import CSDesign
import CupSeasonKit

// MARK: - Step 0 · name + the Pro (3214–3227)

struct WizardNameStep: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Bindable var model: WizardModel

  var body: some View {
    CSCard {
      VStack(alignment: .leading, spacing: 8) {
        Text(WizardCopy.nameLabel).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.mut)
        CSField(WizardCopy.namePlaceholder, text: $model.dials.name, font: CSFont.body)
          .textInputAutocapitalization(.words)
          .accessibilityLabel(WizardCopy.nameLabel)
        Text(WizardCopy.proLabel).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.mut).padding(.top, 10)
        // `renderProChip` (13898): the Pro is always the creator — a fixed identity, not a dead email field
        let p = store.me?.profile
        let handle = p?.handle.map { "@\($0)" } ?? store.email ?? ""
        HStack(spacing: 12) {
          CSFace(marker: p?.marker, size: 36)
          VStack(alignment: .leading, spacing: 2) {
            Text(p?.display_name ?? "You").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
            Text("\(handle) · \(WizardCopy.proSub)").font(CSFont.monoSmall).foregroundStyle(cs.mut).lineLimit(1)
          }
          Spacer(minLength: 8)
          CSTag(text: WizardCopy.proTag, tone: cs.brand)
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      }
    }
  }
}

// MARK: - Step 1 · competitiveness + the dials (3229–3312)

struct WizardPresetStep: View {
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @Bindable var model: WizardModel
  @State private var help: Set<String> = []

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      eyebrow(WizardCopy.presetEyebrow, help: "preset", text: WizardCopy.presetHelp)
      ForEach(0..<3, id: \.self) { i in presetCard(i) }
      CSFine(model.dials.presetSummaryText)
      CSButton(WizardCopy.fastPath) { CSHaptic.selection(); model.step = 2 }
      Button {
        withAnimation(.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.26)) { model.showDials.toggle() }
      } label: {
        HStack(spacing: 6) {
          Text(model.showDials ? WizardCopy.hideOptions : WizardCopy.customize).font(CSFont.monoMediumBody)
          Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).rotationEffect(.degrees(model.showDials ? 180 : 0))
        }
        .foregroundStyle(cs.ink).padding(.horizontal, 12).frame(minHeight: 44)
        .background(cs.bg2, in: Capsule()).overlay(Capsule().stroke(cs.line2, lineWidth: 1))
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(model.showDials ? [.isSelected] : [])
      if model.showDials { dials }
      WizardPortraitCard(portrait: model.portrait)
    }
  }

  /// `.preset` (3230–3245): name ✓ · lead · the bundle line.
  private func presetCard(_ i: Int) -> some View {
    let p = WizardDials.presets[i]
    let on = model.dials.preset == i
    return Button {
      CSHaptic.selection()
      model.dials.applyPreset(i)
      toast.show(model.dials.presetToast)
    } label: {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text(p.name).font(CSFont.title).foregroundStyle(cs.ink)
          if on { Text("✓").font(CSFont.monoMediumBody).foregroundStyle(cs.brand) }
        }
        Text(p.lead).font(CSFont.sentence).foregroundStyle(cs.ink)
        Text(p.line).font(CSFont.footnote).foregroundStyle(cs.mut)
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(on ? cs.brand : cs.line, lineWidth: on ? 1.5 : 1))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(on ? [.isSelected] : [])
  }

  /// `#wizDials` — every dial, in the web's order.
  private var dials: some View {
    VStack(alignment: .leading, spacing: 10) {
      WizardSetRow(lab: WizardCopy.buyIn.0, small: WizardCopy.buyIn.1, val: model.dials.stakeText,
                   downLabel: "Lower buy-in", upLabel: "Raise buy-in",
                   down: { model.dials.stepStake(-1) }, up: { model.dials.stepStake(1) })
      WizardSetRow(lab: WizardCopy.seasonLength.0, small: WizardCopy.seasonLength.1, val: model.dials.lengthText,
                   downLabel: "Shorter season", upLabel: "Longer season",
                   down: { model.dials.stepLength(-1) }, up: { model.dials.stepLength(1) })
      // first tee — any day (§14.0 v1.1); the small line is the REAL weekday span
      HStack(alignment: .center, spacing: 10) {
        VStack(alignment: .leading, spacing: 2) {
          Text(WizardCopy.firstTee.0).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
          Text(model.dials.spanText()).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
        }
        Spacer(minLength: 8)
        DatePicker("", selection: startDate, displayedComponents: .date)
          .labelsHidden().tint(cs.brand).frame(minHeight: 44)
          .accessibilityLabel(WizardCopy.firstTee.0)
      }
      .padding(.vertical, 8)
      .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }

      eyebrow(WizardCopy.teamsEyebrow, help: "structure", text: WizardCopy.teamsHelp)
      WizardSeg(options: WizardDials.structures.map { ($0, WizardDials.structLabels[$0] ?? $0) }, selected: model.dials.structure,
                dimmed: { !WizardDials.fits($0, roster: model.roster) }) { s in
        if let t = WizardDials.structToast(s, roster: model.roster) { toast.show(t) }
        model.dials.structure = s
      }
      CSFine(model.dials.structNote)
      CSFine(model.structFit, tone: cs.warm)

      eyebrow(WizardCopy.fillEyebrow, help: "draft", text: WizardCopy.fillHelp)
      WizardSeg(options: WizardDials.draftTypes.map { ($0, WizardDials.draftLabels[$0] ?? $0) },
                selected: WizardDials.draftTypes.contains(model.dials.draftType) ? model.dials.draftType : "random") { model.dials.draftType = $0 }
      CSFine(model.dials.draftNote)

      eyebrow(WizardCopy.endsEyebrow, help: "finish", text: WizardCopy.endsHelp)
      WizardSeg(options: WizardDials.finishes.map { ($0, WizardDials.finishLabels[$0] ?? $0) }, selected: model.dials.finish) { model.dials.finish = $0 }
      CSFine(model.dials.finishNote)

      eyebrow(WizardCopy.potEyebrow, help: "payout", text: WizardCopy.potHelp)
      WizardSeg(options: WizardDials.payouts.map { p in (p.map(String.init).joined(separator: ","), WizardDials.payLabels[p.map(String.init).joined(separator: ",")] ?? "") },
                selected: model.dials.payKey) { k in model.dials.payout = k.split(separator: ",").compactMap { Int($0) } }
      CSFine(model.dials.payNote)

      WizardSetRow(lab: WizardCopy.countingCap.0, small: WizardCopy.countingCap.1, val: model.dials.capText,
                   downLabel: "Lower counting cap", upLabel: "Raise counting cap", help: ("cap", WizardCopy.capHelp),
                   down: { model.dials.stepCap(-1) }, up: { model.dials.stepCap(1) })
      WizardSetRow(lab: WizardCopy.floorRow.0, small: WizardCopy.floorRow.1, val: model.dials.floorText,
                   downLabel: "Lower floor", upLabel: "Raise floor", help: ("floor", WizardCopy.floorHelp),
                   down: { model.dials.stepFloor(-1) }, up: { model.dials.stepFloor(1) })
    }
    .transition(.opacity.combined(with: .move(edge: .top)))
  }

  private var startDate: Binding<Date> {
    Binding(get: { CSDate.local(model.dials.startDate()) ?? Date() },
            set: { model.dials.startISO = CSDate.iso($0) })
  }

  /// `.eyebrow` + the `i` button, with its `.ihelp` paragraph underneath.
  private func eyebrow(_ t: String, help key: String, text: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Text(t).csEyebrow()
        WizardInfoButton(label: "About \(t.lowercased())", open: help.contains(key)) {
          if help.contains(key) { help.remove(key) } else { help.insert(key) }
        }
      }
      if help.contains(key) { CSFine(text) }
    }
    .padding(.top, 6)
  }
}

// MARK: - Step 2 · review & lock (3305–3312)

struct WizardReviewStep: View {
  @Environment(\.cs) private var cs
  @Bindable var model: WizardModel
  let lock: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(WizardCopy.reviewEyebrow).csEyebrow()
      CSCard {
        VStack(spacing: 0) {
          ForEach(model.dials.bylawsRows()) { r in
            HStack(alignment: .firstTextBaseline, spacing: 12) {
              Text(r.k).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(cs.dimText)
              Spacer(minLength: 8)
              Text(r.v).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink).multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 7)
            .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
          }
        }
      }
      CSFine(WizardCopy.inviteNote)
      CSButton(WizardCopy.lockButton, busy: model.busy) { lock() }
    }
  }
}

// MARK: - The dials' bits

/// `.setrow` — label + small · the value · − / + (44pt each).
struct WizardSetRow: View {
  @Environment(\.cs) private var cs
  let lab: String
  let small: String
  let val: String
  let downLabel: String
  let upLabel: String
  var help: (key: String, text: String)? = nil
  let down: () -> Void
  let up: () -> Void
  @State private var open = false

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .center, spacing: 10) {
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 6) {
            Text(lab).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
            if help != nil { WizardInfoButton(label: "About \(lab.lowercased())", open: open) { open.toggle() } }
          }
          Text(small).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
        }
        Spacer(minLength: 8)
        Text(val).font(CSFont.monoMediumBody).csTabular().foregroundStyle(cs.ink)
        HStack(spacing: 4) {
          stepButton("−", downLabel, down)
          stepButton("+", upLabel, up)
        }
      }
      if open, let help { CSFine(help.text) }
    }
    .padding(.vertical, 8)
    .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
  }

  private func stepButton(_ glyph: String, _ label: String, _ action: @escaping () -> Void) -> some View {
    Button { CSHaptic.selection(); action() } label: {
      Text(glyph).font(CSFont.monoMediumBody).foregroundStyle(cs.ink)
        .frame(width: 44, height: 44)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }
}

/// `.seg` — one row of options, the chosen one in ink; dimmed ones still tap (guidance, never a block).
struct WizardSeg: View {
  @Environment(\.cs) private var cs
  let options: [(key: String, label: String)]
  let selected: String
  var dimmed: (String) -> Bool = { _ in false }
  let pick: (String) -> Void

  var body: some View {
    HStack(spacing: 6) {
      ForEach(options, id: \.key) { o in
        let on = o.key == selected
        Button { CSHaptic.selection(); pick(o.key) } label: {
          Text(o.label).font(CSFont.monoSmall).lineLimit(1).minimumScaleFactor(0.8)
            .foregroundStyle(on ? cs.bg0 : cs.ink)
            .padding(.horizontal, 10).frame(maxWidth: .infinity, minHeight: 44)
            .background(on ? cs.ink : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: on ? 0 : 1))
            .opacity(dimmed(o.key) && !on ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isSelected] : [])
      }
    }
  }
}

/// `.ibtn` — the little "i" that opens a help paragraph.
struct WizardInfoButton: View {
  @Environment(\.cs) private var cs
  let label: String
  let open: Bool
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Text("i").font(CSFont.label).foregroundStyle(open ? cs.bg0 : cs.mut)
        .frame(width: 20, height: 20)
        .background(open ? cs.mut : cs.bg2, in: Circle())
        .overlay(Circle().stroke(cs.line2, lineWidth: 1))
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityAddTraits(open ? [.isSelected] : [])
  }
}

/// `wizPortrait` — the league drawn live from the dials: the flag, the squad
/// dots, the endgame chips, the pot with its split bar, the season band.
struct WizardPortraitCard: View {
  @Environment(\.cs) private var cs
  let portrait: WizardPortrait

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(WizardCopy.asideTitle).csEyebrow()
      CSCard {
        VStack(alignment: .leading, spacing: 10) {
          HStack(spacing: 12) {
            flag.frame(width: 64, height: 34)
            VStack(alignment: .leading, spacing: 2) {
              Text(portrait.name).font(CSFont.sentenceBold).foregroundStyle(cs.ink).lineLimit(1)
              Text(portrait.sub).font(CSFont.footnote).foregroundStyle(cs.mut)
            }
          }
          row("Squads") {
            HStack(spacing: 5) {
              if portrait.squads > 0 {
                ForEach(0..<portrait.squads, id: \.self) { i in Circle().fill(cs.squad(i)).frame(width: 9, height: 9) }
              } else { Circle().fill(cs.mut).frame(width: 9, height: 9) }
              Text(portrait.structLine).font(CSFont.label).tracking(0.8).foregroundStyle(cs.mut)
            }
          }
          row("Endgame") {
            HStack(spacing: 6) {
              chip("Cup Final", on: portrait.cup)
              chip("Points table", on: !portrait.cup)
            }
          }
          if portrait.stake > 0 {
            row("The pot") {
              HStack(spacing: 8) {
                Text(PotMath.dollars(portrait.pot)).font(CSFont.stat).csTabular().foregroundStyle(cs.gold)
                splitBar
              }
            }
            Text(portrait.potSub).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
          } else {
            row("The pot") {
              HStack(spacing: 8) {
                Text("Bragging rights").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
                Text("$0 STAKE").font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
              }
            }
          }
          row("Season") {
            HStack(spacing: 6) {
              seasonBand
              Text(portrait.seasonTail).font(CSFont.label).tracking(0.6).foregroundStyle(cs.mut)
            }
          }
        }
      }
      CSFine(WizardCopy.asideHint)
    }
  }

  private func row<C: View>(_ k: String, @ViewBuilder _ c: () -> C) -> some View {
    HStack(alignment: .center, spacing: 10) {
      Text(k).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(cs.dimText).frame(width: 64, alignment: .leading)
      c()
      Spacer(minLength: 0)
    }
  }

  private func chip(_ t: String, on: Bool) -> some View {
    Text(t).font(CSFont.label).tracking(0.6)
      .foregroundStyle(on ? cs.brand : cs.mut)
      .padding(.horizontal, 8).padding(.vertical, 4)
      .overlay(Capsule().stroke(on ? cs.brand : cs.line2, lineWidth: 1))
  }

  /// Three segments in ember at 1 · .55 · .3, widths from the split.
  private var splitBar: some View {
    let w = portrait.bar
    return HStack(spacing: 3) {
      RoundedRectangle(cornerRadius: 4).fill(cs.brand).frame(width: w[0] * 0.6, height: 8)
      RoundedRectangle(cornerRadius: 4).fill(cs.brand.opacity(0.55)).frame(width: w[1] * 0.6, height: 8)
      RoundedRectangle(cornerRadius: 4).fill(cs.brand.opacity(0.3)).frame(width: w[2] * 0.6, height: 8)
    }
    .accessibilityHidden(true)
  }

  /// Month blocks, then the FINAL 4 block with the flag when the Cup Final fits.
  private var seasonBand: some View {
    HStack(spacing: 4) {
      ForEach(0..<portrait.months, id: \.self) { _ in
        RoundedRectangle(cornerRadius: 4).stroke(cs.line2, lineWidth: 1.2).frame(width: 26, height: 16)
      }
      if portrait.canCup {
        VStack(spacing: 1) {
          Text("FINAL 4").font(.system(size: 7, design: .monospaced)).tracking(0.8).foregroundStyle(cs.brand)
          RoundedRectangle(cornerRadius: 4).fill(CSTokens.glow).frame(width: 18, height: 16)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(cs.brand, lineWidth: 1.4))
        }
      }
    }
    .accessibilityHidden(true)
  }

  /// The two tracers into the cup, and the flag in gold.
  private var flag: some View {
    Canvas { ctx, size in
      let sx = size.width / 100, sy = size.height / 52
      var l = Path(); l.move(to: CGPoint(x: 4 * sx, y: 10 * sy)); l.addCurve(to: CGPoint(x: 48 * sx, y: 42 * sy), control1: CGPoint(x: 30 * sx, y: 18 * sy), control2: CGPoint(x: 42 * sx, y: 30 * sy))
      var r = Path(); r.move(to: CGPoint(x: 96 * sx, y: 10 * sy)); r.addCurve(to: CGPoint(x: 52 * sx, y: 42 * sy), control1: CGPoint(x: 70 * sx, y: 18 * sy), control2: CGPoint(x: 58 * sx, y: 30 * sy))
      ctx.stroke(l, with: .color(cs.sq0), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
      ctx.stroke(r, with: .color(cs.sq1), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
      ctx.fill(Path(ellipseIn: CGRect(x: 43 * sx, y: 40.4 * sy, width: 14 * sx, height: 5.2 * sy)), with: .color(cs.bg0))
      var pole = Path(); pole.move(to: CGPoint(x: 53 * sx, y: 41 * sy)); pole.addLine(to: CGPoint(x: 53 * sx, y: 16 * sy))
      ctx.stroke(pole, with: .color(cs.ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
      var f = Path(); f.move(to: CGPoint(x: 53 * sx, y: 16 * sy)); f.addLine(to: CGPoint(x: 67 * sx, y: 21 * sy)); f.addLine(to: CGPoint(x: 53 * sx, y: 26 * sy)); f.closeSubpath()
      ctx.fill(f, with: .color(cs.gold))
    }
    .accessibilityHidden(true)
  }
}
