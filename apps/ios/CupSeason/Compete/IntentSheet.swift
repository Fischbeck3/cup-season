// Cup Season — the intent sheet (D225 / O-04; IA §6.2; CORE_FLOWS §6.1).
//
// Five sentences, no object nouns. Reached from Compete's head, Home's foot
// doors, the post-round next act, and a person's page. The fifth is a MODIFIER
// and renders below a hairline as a footer line, because money is a choice ON a
// competition and never a competition (L-11, D46).
//
// This file renders `StartIntent` (Kit) and decides nothing: the lines, the
// glosses, the order and the ban on engine nouns are a producer both clients
// share, so a reword fails on the other client too (D234).
//
// NOTHING IS MINTED BY OPENING IT.

import SwiftUI
import CSDesign
import CupSeasonKit

struct IntentSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let take: (StartIntent.Resolution) -> Void
  let joinWithCode: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 4) {
        CSSheetHeader(title: StartIntent.title, sub: "PICK THE ONE THAT SOUNDS LIKE YOU")
        ForEach(StartIntent.peers) { intent in
          // The last peer drops its own hairline: the modifier's separator is
          // the rule below it, and two rules a few points apart read as a
          // mistake (it was one, in the first shot of this sheet).
          row(intent.line, intent.gloss, ember: intent == StartIntent.peers.first,
              hairline: intent != StartIntent.peers.last) {
            CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("intent:\(intent.rawValue)")])
            dismiss()
            take(intent.resolution)
          }
        }
        // The modifier, below a hairline. It attaches money to a competition
        // that already exists, or to the one being created; it never creates one.
        CSHairline().padding(.vertical, 10)
        row(StartIntent.modifierLine, StartIntent.modifierGloss, ember: false, hairline: false) {
          CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("intent:money")])
          dismiss()
          take(.whatsItOn)
        }
        Button {
          dismiss()
          joinWithCode()
        } label: {
          Text("\(StartIntent.codeDoor) →").csEyebrow(cs.mut).a11yHitSlop()
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .accessibilityLabel(StartIntent.codeDoor)
      }
      .padding(20)
    }
    .background(cs.bg0)
    // Fitted, not full-height: five sentences do not need a whole screen, and
    // a sheet with 900pt of nothing under it reads as a page that failed.
    //
    // D258 · **AT THE ACCESSIBILITY SIZES IT IS THE WHOLE PAGE.** 540 points
    // hold four sentences at the reading sizes and two of them at AX3, so the
    // sheet that says "pick the one that sounds like you" offered a golfer a
    // choice of two with nothing to say there were four. `csFittedSheet` keeps
    // the fitted height where it is right and hands over the page where it is
    // not.
    .csFittedSheet(540, large: true)
  }

  private func row(_ line: String, _ gloss: String, ember: Bool, hairline: Bool = true, action: @escaping () -> Void) -> some View {
    Button(action: { CSHaptic.selection(); action() }) {
      VStack(alignment: .leading, spacing: 3) {
        Text(line).font(CSFont.sentenceBold).foregroundStyle(ember ? cs.brand : cs.ink)
        Text(gloss).font(CSFont.footnote).foregroundStyle(cs.dimText)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 12)
      .frame(minHeight: 56)
      .overlay(alignment: .bottom) { if hairline { CSHairline() } }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(line). \(gloss)")
  }
}

/// Intent 1's fork — the one question the app genuinely cannot infer, and the
/// one tap that avoids dropping a golfer into a live scorer they did not want.
struct WhenForkSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let take: (StartIntent.WhenFork) -> Void

  var body: some View {
    // D258 · a fork with no scroller clipped its second answer at AX3. Two
    // sentences are still two sentences; they are just taller.
    ScrollView {
    VStack(alignment: .leading, spacing: 4) {
      CSSheetHeader(title: StartIntent.WhenFork.title, sub: "TWO WAYS, AND BOTH WORK")
      ForEach(StartIntent.WhenFork.allCases) { f in
        Button {
          CSHaptic.selection(); dismiss(); take(f)
        } label: {
          VStack(alignment: .leading, spacing: 3) {
            // L-40 · live keeps the ember.
            Text(f.line).font(CSFont.sentenceBold).foregroundStyle(f == .rightNow ? cs.brand : cs.ink)
            Text(f.gloss).font(CSFont.footnote).foregroundStyle(cs.dimText)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 12).frame(minHeight: 56)
          .overlay(alignment: .bottom) { if f == .rightNow { CSHairline() } }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(f.line). \(f.gloss)")
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(cs.bg0)
    .csFittedSheet(260)
  }
}

#Preview("Intent") {
  Color.clear.sheet(isPresented: .constant(true)) { IntentSheet(take: { _ in }, joinWithCode: {}) }.csTheme()
}
