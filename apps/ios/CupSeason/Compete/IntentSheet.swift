// Cup Season — the intent sheet (D225 / O-04; IA §6.2; CORE_FLOWS §6.1).
//
// **RE-CLOTHED, NOT RE-ARGUED** (surfaces/event.md §5). The sentences, their
// glosses, their order, the modifier's position below a rule and the code door
// are all `StartIntent`'s — a producer both clients share — and not one of them
// is touched here.
//
// WHAT CHANGED, AND ALL OF IT CAME FROM THE BLIND REVIEW, WHICH CALLED THIS
// "the least designed screen in the deck, and it was the front door":
//
//   · **The question is the serif.** `lead` 28 New York Bold, not
//     `CSFont.sentenceBold` (SF 17). The product's most consequential fork was
//     set in the system's voice — the audit's finding 7, in one line.
//   · **Nothing is pre-tinted.** The first option was `brand` while nothing was
//     selected, and two of three reviewers read it as ALREADY SELECTED. Every
//     option is now at the same weight as its peers (§16A.6).
//   · **Every option is a two-line row with a chevron at 44pt+**, which is the
//     weight blind-1 asked for.
//   · **`I have a code` is a full row.** It was the smallest thing on the sheet
//     while being the highest-frequency act an invited golfer performs — a 12pt
//     tracked-caps link with a typed arrow, under four two-line rows. It sits
//     below a hairline now, at option weight, with its own sub-line.
//   · **`Close`**, which the shipped sheet did not have at all: it was
//     gesture-only, on a fitted sheet, on the front door.
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
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        HStack {
          Spacer(minLength: 0)
          Button("Close") { dismiss() }.buttonStyle(.csTertiary(.toolbar))
        }
        Text(StartIntent.title).csType(.lead).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityAddTraits(.isHeader)
        Text("Pick the one that sounds like you").csType(.agate, caps: true).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
        VStack(alignment: .leading, spacing: 0) {
          ForEach(StartIntent.peers) { intent in
            row(intent.line, intent.gloss) {
              CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("intent:\(intent.rawValue)")])
              dismiss()
              take(intent.resolution)
            }
          }
          // **The heavy rule is what says THIS ONE IS DIFFERENT.** The shipped
          // sheet used a second hairline a few points from the first, which its
          // own comment records as having read as a mistake.
          CSRule(.heavy).padding(.vertical, CSTokens.Space.s3)
          row(StartIntent.modifierLine, StartIntent.modifierGloss, rule: false) {
            CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("intent:money")])
            dismiss()
            take(.whatsItOn)
          }
          CSRule()
          row(StartIntent.codeDoor, StartIntent.codeDoorGloss, rule: false) {
            dismiss()
            joinWithCode()
          }
        }
      }
      .padding(CSTokens.Space.gutter)
    }
    .background(cs.bg0)
    // Fitted, not full-height: five sentences do not need a whole screen, and a
    // sheet with 900pt of nothing under it reads as a page that failed.
    //
    // D258 · **AT THE ACCESSIBILITY SIZES IT IS THE WHOLE PAGE.** 540 points
    // hold four sentences at the reading sizes and two of them at AX3, so the
    // sheet that says "pick the one that sounds like you" offered a choice of
    // two with nothing to say there were four.
    .csFittedSheet(540, large: true)
  }

  /// One option. **No colour on any of them** — an un-chosen option is never
  /// pre-tinted, and the chevron is the affordance.
  private func row(_ line: String, _ gloss: String, rule: Bool = true, action: @escaping () -> Void) -> some View {
    Button(action: { CSHaptic.selection(); action() }) {
      VStack(spacing: 0) {
        HStack(spacing: CSTokens.Space.s3) {
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            Text(line).csType(.name).foregroundStyle(cs.ink)
              .fixedSize(horizontal: false, vertical: true)
            Text(gloss).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          CSGlyph(.chevron, size: .row).foregroundStyle(cs.mut)
        }
        .padding(.vertical, CSTokens.Space.s3)
        .frame(minHeight: 56)
        if rule { CSRule() }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(line). \(gloss)")
  }
}

/// Intent 1's fork — the one question the app genuinely cannot infer, and the
/// one tap that avoids dropping a golfer into a live scorer they did not want.
///
/// The same anatomy at `csFittedSheet(260)`: the question in `lead` 28, two
/// rows, and `Right now` in `brand` — which is the one tint that stays, because
/// it is the LIVE act (L-40) and not a default nobody chose.
struct WhenForkSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let take: (StartIntent.WhenFork) -> Void

  var body: some View {
    // D258 · a fork with no scroller clipped its second answer at AX3.
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        HStack {
          Spacer(minLength: 0)
          Button("Close") { dismiss() }.buttonStyle(.csTertiary(.toolbar))
        }
        Text(StartIntent.WhenFork.title).csType(.lead).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityAddTraits(.isHeader)
        Text("Two ways, and both work").csType(.agate, caps: true).foregroundStyle(cs.mut)
        VStack(alignment: .leading, spacing: 0) {
          ForEach(StartIntent.WhenFork.allCases) { f in
            Button {
              CSHaptic.selection(); dismiss(); take(f)
            } label: {
              VStack(spacing: 0) {
                HStack(spacing: CSTokens.Space.s3) {
                  VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
                    Text(f.line).csType(.name).foregroundStyle(f == .rightNow ? cs.brand : cs.ink)
                      .fixedSize(horizontal: false, vertical: true)
                    Text(f.gloss).csType(.bodyS).foregroundStyle(cs.mut)
                      .fixedSize(horizontal: false, vertical: true)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  CSGlyph(.chevron, size: .row).foregroundStyle(cs.mut)
                }
                .padding(.vertical, CSTokens.Space.s3)
                .frame(minHeight: 56)
                if f == .rightNow { CSRule() }
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(f.line). \(f.gloss)")
          }
        }
      }
      .padding(CSTokens.Space.gutter)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(cs.bg0)
    .csFittedSheet(260)
    .csBudget(ember: 1)
  }
}

#Preview("Intent") {
  Color.clear.sheet(isPresented: .constant(true)) { IntentSheet(take: { _ in }, joinWithCode: {}) }.csTheme()
}
