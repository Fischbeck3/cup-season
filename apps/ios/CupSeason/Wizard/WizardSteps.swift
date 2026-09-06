// Cup Season — the wizard's three questions (D225; IA §6.3, CORE_FLOWS §7),
// the dials behind **More settings** (`.setrow` steppers, `.seg` segments, the
// `i` help buttons) and the portrait (`wizPortrait`, 11847–11890).
//
// Who's playing? · How long, and when's the first tee? · What's on it?
// Then the rules in one sentence, the name (pre-filled, asked LAST), and
// **Start the season** — the one tap that mints anything at all.

import SwiftUI
import CSDesign
import CupSeasonKit

/// F-12 · which door labels are SENTENCES rather than labels.
///
/// L-29 splits the three voices: mono is the record — labels, eyebrows,
/// tabular numerals, never prose. `WizardCopy.textThemALink` is a full
/// sentence with a subject, a verb and an em dash, and it rendered in
/// `monoMediumBody` because every step-1 door does. Rather than tag each
/// string, the renderer asks: a label with a verb-carrying clause in it —
/// an em dash, or more than four words — is prose.
enum WizardSteps {
  static func isSentence(_ label: String) -> Bool {
    label.contains("—") || label.split(separator: " ").count > 4
  }
}

// MARK: - Step 1 · Who's playing? (IA §6.3, CORE_FLOWS §7.1)

struct WizardWhoStep: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Bindable var model: WizardModel
  let findGolfers: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if !model.buddiesLoaded {
        ProgressView().tint(cs.brand)
      } else if model.buddies.isEmpty {
        // THE EMPTY BRANCH — every first-time organiser's state, and it was
        // missing. `search_golfers` matches an exact @handle or an existing
        // relation only (L-37), so a golfer signed in an hour cannot find two
        // friends who are already on the app.
        Text(WizardCopy.step1Empty).font(CSFont.sentence).foregroundStyle(cs.mut)
        door(WizardCopy.findYourFriends, sub: WizardCopy.findYourFriendsSub, ember: true, action: findGolfers)
        door(WizardCopy.textThemALink, sub: nil, ember: false, action: findGolfers)
        door(WizardCopy.justMe, sub: WizardCopy.justMeSub, ember: false) { model.step = 1 }
      } else {
        Text(WizardCopy.step1Sub).font(CSFont.footnote).foregroundStyle(cs.dimText)
        FlowLayout(spacing: 6) {
          ForEach(model.buddies) { b in chip(b) }
        }
        door(WizardCopy.textThemALink, sub: nil, ember: false, action: findGolfers)
        // Derived, never printed as a literal (D205/D206).
        CSFine(WizardDials.rosterHint)
      }

      // The ONE question the roster is worth asking, and only at four or more.
      if model.asksAboutSquads {
        Text(WizardCopy.squadsQuestion).csEyebrow().padding(.top, 6)
        WizardSeg(options: [("solo", WizardCopy.squadsNo), ("squads", WizardCopy.squadsYes)],
                  selected: (model.squadsChosen ?? false) ? "squads" : "solo") { k in
          model.squadsChosen = (k == "squads")
        }
      }
    }
  }

  private func chip(_ b: TagCandidate) -> some View {
    let on = model.dials.invitees.contains(b.id)
    return Button {
      CSHaptic.selection()
      if on { model.dials.invitees.removeAll { $0 == b.id } } else { model.dials.invitees.append(b.id) }
      model.syncName(myName: store.me?.profile?.display_name)
    } label: {
      HStack(spacing: 6) {
        CSMarkerView(key: b.marker, size: 16).foregroundStyle(on ? cs.pos : cs.ink)
        Text(b.name).font(CSFont.monoMediumBody).foregroundStyle(on ? cs.pos : cs.ink)
      }
      .padding(.horizontal, 12).frame(minHeight: 44)
      .background(cs.bg2, in: Capsule())
      .overlay(Capsule().stroke(on ? cs.pos : cs.line2, lineWidth: 1))
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(on ? .isSelected : [])
  }

  private func door(_ label: String, sub: String?, ember: Bool, action: @escaping () -> Void) -> some View {
    Button(action: { CSHaptic.selection(); action() }) {
      VStack(alignment: .leading, spacing: 2) {
        // F-12 · L-29: mono is the RECORD — labels, eyebrows, tabular numerals,
        // never prose. Every step-1 route renders through here and one of them
        // ("Someone not here yet — text them a link") is a full sentence with a
        // subject, a verb and an em dash. A label stays mono; a sentence takes
        // the sans voice. The buddy chips beside these are legitimately mono.
        Text(label)
          .font(WizardSteps.isSentence(label) ? CSFont.subhead.weight(.medium) : CSFont.monoMediumBody)
          .foregroundStyle(ember ? cs.brand : cs.ink)
        if let sub { Text(sub).font(CSFont.footnote).foregroundStyle(cs.dimText) }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 12).padding(.vertical, 10).frame(minHeight: 50)
      .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(ember ? cs.brand : cs.line2, lineWidth: 1))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Step 2 · How long, and when's the first tee?

struct WizardWhenStep: View {
  @Environment(\.cs) private var cs
  @Bindable var model: WizardModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      WizardSetRow(lab: WizardCopy.seasonLength.0, small: WizardCopy.seasonLength.1, val: model.dials.lengthText,
                   downLabel: "Shorter season", upLabel: "Longer season",
                   down: { model.dials.stepLength(-1) }, up: { model.dials.stepLength(1) })
      A11yStack(spacing: 10, columnSpacing: 6) {
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
      // L-13, in a golfer's words, at the moment it matters.
      CSFine(WizardCopy.step2Note(endsOn: model.dials.endDate()))
    }
  }

  private var startDate: Binding<Date> {
    Binding(get: { CSDate.local(model.dials.startDate()) ?? Date() },
            set: { model.dials.startISO = CSDate.iso($0) })
  }
}

// MARK: - Step 3 · What's on it? · then the rules, the name, and Start

struct WizardStakeStep: View {
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Bindable var model: WizardModel
  let publish: () -> Void
  @State private var help: Set<String> = []
  @State private var otherOpen = false
  @State private var otherText = ""
  @State private var pricing = PricingFlags.hidden

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // L-11 · Bragging rights is SELECTED. Money is a choice, never a default.
      A11yStack(spacing: 6) {
        ForEach(WizardDials.stakeChips, id: \.self) { v in stakeChip(v) }
        otherChip
      }
      if otherOpen {
        CSField("$20", text: $otherText, font: CSFont.body)
          .keyboardType(.numberPad)
          .onChange(of: otherText) { _, t in
            let digits = t.filter(\.isNumber)
            if digits != t { otherText = digits }
            model.dials.stake = min(10_000, Int(digits) ?? 0)
          }
          .accessibilityLabel("Buy-in in dollars")
      }

      // L-10 · at $0 the whole block below is ABSENT, not greyed.
      if model.dials.stake > 0 {
        CSFine(WizardCopy.potLine(stake: model.dials.stake, roster: model.roster))
        // L-09 · the ledger line, verbatim from the constant.
        Text(MoneyCopy.ledger).font(CSFont.footnote).foregroundStyle(cs.gold)
          .fixedSize(horizontal: false, vertical: true)
        Text(WizardCopy.payLabel).csEyebrow().padding(.top, 4)
        CSField(WizardCopy.payPlaceholder, text: $model.dials.buyInNote, font: CSFont.body)
          .textInputAutocapitalization(.never).autocorrectionDisabled()
          .accessibilityLabel(WizardCopy.payLabel)
        // The ONE required field the wizard gains.
        CSFine(model.dials.payNoteMissing ? WizardCopy.payMissing : WizardCopy.payFine,
               tone: model.dials.payNoteMissing ? cs.warm : cs.dimText)
      }

      Rectangle().fill(cs.line).frame(height: 1).padding(.vertical, 4)

      // THE RULES, IN ONE SENTENCE. Every dial is still there, verbatim, behind
      // More settings (P-6: complexity hidden, never deleted).
      Text(WizardCopy.rulesHead).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
      Text(WizardCopy.rulesLine(model.dials)).font(CSFont.sentence).foregroundStyle(cs.dimText)
        .fixedSize(horizontal: false, vertical: true)
      Button {
        withAnimation(reduceMotion ? nil : .timingCurve(0.16, 0.84, 0.36, 1, duration: 0.26)) { model.showDials.toggle() }
      } label: {
        HStack(spacing: 6) {
          Text(WizardCopy.moreSettings).font(CSFont.monoMediumBody)
          Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).rotationEffect(.degrees(model.showDials ? 180 : 0))
        }
        .foregroundStyle(cs.ink).padding(.horizontal, 12).frame(minHeight: 44)
        .background(cs.bg2, in: Capsule()).overlay(Capsule().stroke(cs.line2, lineWidth: 1))
      }
      .buttonStyle(.plain)
      .accessibilityValue(model.showDials ? "expanded" : "collapsed")
      if model.showDials { WizardDialsPane(model: model, help: $help) }

      Text(WizardCopy.nameIt).csEyebrow().padding(.top, 6)
      CSField("The Fellas", text: $model.dials.name, font: CSFont.body)
        .textInputAutocapitalization(.words)
        .onChange(of: model.dials.name) { _, _ in model.nameTouched = true }
        .accessibilityLabel(WizardCopy.nameIt)

      CSButton(WizardCopy.publish, busy: model.busy) { publish() }
        .disabled(!model.dials.canPublish)
        .opacity(model.dials.canPublish ? 1 : 0.5)
      CSFine(WizardCopy.freezeNote)
      WizardPortraitCard(portrait: model.portrait)
        .task { pricing = await PricingFlags.load() }
      PricingPassCard(flags: pricing, roster: model.roster, buyInCents: model.dials.stake * 100)
    }
  }

  private func stakeChip(_ v: Int) -> some View {
    let on = !otherOpen && model.dials.stake == v
    return Button {
      CSHaptic.selection(); otherOpen = false; model.dials.stake = v
    } label: {
      Text(v == 0 ? WizardDials.braggingRights : PotMath.dollars(v))
        .font(CSFont.monoSmall).lineLimit(1).minimumScaleFactor(0.8)
        .foregroundStyle(on ? cs.bg0 : cs.ink)
        .padding(.horizontal, 10).frame(maxWidth: .infinity, minHeight: 44)
        .background(on ? cs.ink : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: on ? 0 : 1))
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(on ? [.isSelected] : [])
  }

  /// D225 · $20 was impossible: the rungs are fixed and there was no field.
  private var otherChip: some View {
    Button {
      CSHaptic.selection(); otherOpen = true
      otherText = model.dials.stake > 0 && !WizardDials.stakeChips.contains(model.dials.stake) ? String(model.dials.stake) : ""
      model.dials.stake = Int(otherText) ?? 0
    } label: {
      Text(WizardDials.otherLabel).font(CSFont.monoSmall)
        .foregroundStyle(otherOpen ? cs.bg0 : cs.ink)
        .padding(.horizontal, 10).frame(maxWidth: .infinity, minHeight: 44)
        .background(otherOpen ? cs.ink : cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: otherOpen ? 0 : 1))
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(otherOpen ? [.isSelected] : [])
  }
}

/// **More settings** — every dial, verbatim, with its ⓘ paragraph. Nothing was
/// deleted when the three questions replaced them (P-6).
struct WizardDialsPane: View {
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @Bindable var model: WizardModel
  @Binding var help: Set<String>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      eyebrow(WizardCopy.presetEyebrow, key: "preset", text: WizardCopy.presetHelp)
      ForEach(0..<3, id: \.self) { i in presetCard(i) }
      CSFine(model.dials.presetSummaryText)
      CSFine(WizardCopy.verificationNote)   // M-15: a norm the league holds, not a filter the engine applies

      WizardSetRow(lab: WizardCopy.buyIn.0, small: WizardCopy.buyIn.1, val: model.dials.stakeText,
                   downLabel: "Lower buy-in", upLabel: "Raise buy-in",
                   down: { model.dials.stepStake(-1) }, up: { model.dials.stepStake(1) })

      eyebrow(WizardCopy.teamsEyebrow, key: "structure", text: WizardCopy.teamsHelp)
      WizardSeg(options: WizardDials.structures.map { ($0, WizardDials.structLabels[$0] ?? $0) }, selected: model.dials.structure,
                dimmed: { !WizardDials.fits($0, roster: model.roster) }) { s in
        if let t = WizardDials.structToast(s, roster: model.roster) { toast.show(t) }
        model.dials.structure = s
        model.squadsChosen = (s != "solo")
      }
      CSFine(model.dials.structNote)
      CSFine(WizardDials.structFitLine(roster: model.roster), tone: cs.warm)

      eyebrow(WizardCopy.fillEyebrow, key: "draft", text: WizardCopy.fillHelp)
      WizardSeg(options: WizardDials.draftTypes.map { ($0, WizardDials.draftLabels[$0] ?? $0) },
                selected: WizardDials.draftTypes.contains(model.dials.draftType) ? model.dials.draftType : "random") { model.dials.draftType = $0 }
      CSFine(model.dials.draftNote)

      eyebrow(WizardCopy.endsEyebrow, key: "finish", text: WizardCopy.endsHelp)
      WizardSeg(options: WizardDials.finishes.map { ($0, WizardDials.finishLabels[$0] ?? $0) }, selected: model.dials.finish) { model.dials.finish = $0 }
      CSFine(model.dials.finishNote)

      eyebrow(WizardCopy.potEyebrow, key: "payout", text: WizardCopy.potHelp)
      WizardSeg(options: WizardDials.payouts.map { p in (p.map(String.init).joined(separator: ","), WizardDials.payLabels[p.map(String.init).joined(separator: ",")] ?? "") },
                selected: model.dials.payKey) { k in model.dials.payout = k.split(separator: ",").compactMap { Int($0) } }
      CSFine(model.dials.payNote)

      WizardSetRow(lab: WizardCopy.countingCap.0, small: WizardCopy.countingCap.1, val: model.dials.capText,
                   downLabel: "Fewer rounds count", upLabel: "More rounds count", help: ("cap", WizardCopy.capHelp),
                   down: { model.dials.stepCap(-1) }, up: { model.dials.stepCap(1) })
      WizardSetRow(lab: WizardCopy.floorRow.0, small: WizardCopy.floorRow.1, val: model.dials.floorText,
                   downLabel: "Lower the minimum", upLabel: "Raise the minimum", help: ("floor", WizardCopy.floorHelp),
                   down: { model.dials.stepFloor(-1) }, up: { model.dials.stepFloor(1) })
    }
    .transition(.opacity.combined(with: .move(edge: .top)))
  }

  /// `.preset` — the name, and ONE sentence. The dial recital is gone (L-16).
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
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(on ? cs.brand : cs.line, lineWidth: on ? 1.5 : 1))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(on ? [.isButton, .isSelected] : [.isButton])
  }

  private func eyebrow(_ t: String, key: String, text: String) -> some View {
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
      // label + small, then value + the two steppers; the second group takes its own line at the accessibility sizes
      A11yStack(spacing: 10, columnSpacing: 6) {
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 6) {
            Text(lab).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
            if help != nil { WizardInfoButton(label: "About \(lab.lowercased())", open: open) { open.toggle() } }
          }
          Text(small).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Spacer(minLength: 8)
        HStack(spacing: 10) {
          Text(val).font(CSFont.monoMediumBody).csTabular().foregroundStyle(cs.ink)
            .accessibilityLabel("\(lab), \(val)")
            .accessibilityAddTraits(.updatesFrequently)
          HStack(spacing: 4) {
            stepButton("−", downLabel, down)
            stepButton("+", upLabel, up)
          }
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
    // one row of pills; a column at the accessibility sizes, where three labels cannot share the width
    A11yStack(spacing: 6) {
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
        .accessibilityHint(dimmed(o.key) && !on ? "A stretch for your roster — still yours to pick" : "")
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
    .accessibilityValue(open ? "expanded" : "collapsed")
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
              Text(portrait.name).font(CSFont.sentenceBold).foregroundStyle(cs.ink).lineLimit(2)
              Text(portrait.sub).font(CSFont.footnote).foregroundStyle(cs.mut)
            }
          }
          .accessibilityElement(children: .combine)
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
    A11yStack(spacing: 10, columnSpacing: 4) {
      Text(k).font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(cs.dimText).frame(minWidth: 64, alignment: .leading)
      c()
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
  }

  private func chip(_ t: String, on: Bool) -> some View {
    Text(t).font(CSFont.label).tracking(0.6)
      .foregroundStyle(on ? cs.brand : cs.mut)
      .padding(.horizontal, 8).padding(.vertical, 4)
      .overlay(Capsule().stroke(on ? cs.brand : cs.line2, lineWidth: 1))
      .accessibilityLabel(on ? "\(t), chosen" : t)
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
        // the final block, then its name at a readable size — a 7pt caption over the block fell under the 11pt floor (IOS-003 §2.1)
        RoundedRectangle(cornerRadius: 4).fill(CSTokens.glow).frame(width: 18, height: 16)
          .overlay(RoundedRectangle(cornerRadius: 4).stroke(cs.brand, lineWidth: 1.4))
        Text("FINAL 4").font(CSFont.label).tracking(0.8).foregroundStyle(cs.brand).fixedSize()
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
