import SwiftUI
import CSDesign
import CupSeasonKit

struct WizardRulesEditor: View {
  @Environment(\.cs) private var cs
  @Bindable var model: WizardModel
  @State private var explainMinimum = false
  private let paces = ["Choose a pace", "About once a month", "About twice a month", "Most weeks"]
  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      Text("How often will most of you play?").csType(.name)
      Menu {
        ForEach(Array(paces.enumerated()), id: \.offset) { index, title in
          Button(title) { model.playingFrequency = index }
        }
      } label: {
        HStack(spacing: CSTokens.Space.s2) {
          Text(paces[model.playingFrequency]).csType(.body)
            .fixedSize(horizontal: false, vertical: true)
          Image(systemName: "chevron.up.chevron.down").csType(.bodyS)
        }
        .frame(minHeight: 44, alignment: .leading).padding(.vertical, CSTokens.Space.s2)
        .contentShape(Rectangle())
      }.buttonStyle(.plain).accessibilityLabel("Playing frequency")
        .accessibilityValue(paces[model.playingFrequency]).accessibilityIdentifier("wizard-frequency")
      if model.playingFrequency == 1 {
        Text("For a busy group, try best 2 and no minimum.").csType(.bodyS).foregroundStyle(cs.mut)
        Button("Use best 2, no minimum") { model.dials.applyBusyFriendsSuggestion() }
          .buttonStyle(.csSecondary()).accessibilityIdentifier("wizard-busy-suggestion")
      }
      WizardSetRow(lab: "Which rounds count each month?", small: "Per golfer", val: model.dials.capText,
        downLabel: "Fewer rounds count", upLabel: "More rounds count",
        down: { model.dials.stepCap(-1) }, up: { model.dials.stepCap(1) })
      Text(WizardCopy.capHelp).csType(.bodyS).foregroundStyle(cs.mut)
      if !model.reviewDials.solo {
        WizardSetRow(lab: "Require a minimum number of rounds?", small: "Per golfer each month", val: model.dials.floor == 0 ? "None" : String(model.dials.floor),
          downLabel: "Lower the minimum", upLabel: "Raise the minimum",
          down: { model.dials.stepFloor(-1) }, up: { model.dials.stepFloor(1) })
        Text(model.reviewDials.setupMinimumConsequence).csType(.bodyS).foregroundStyle(cs.mut)
        if model.dials.floor > 0 {
          DisclosureGroup("How 9-hole rounds and partial months work", isExpanded: $explainMinimum) {
            Text(WizardCopy.floorHelp).csType(.bodyS).foregroundStyle(cs.mut)
          }.tint(cs.ink)
        }
        if model.playingFrequency > 0 && model.dials.floor > (model.playingFrequency == 3 ? 4 : model.playingFrequency) {
          Text("This asks for more rounds than your group expects to play.").csType(.bodyS).foregroundStyle(cs.neg)
        }
      }
    }.foregroundStyle(cs.ink)
  }
}

struct WizardAgreementView: View {
  @Environment(\.cs) private var cs
  let agreement: WizardAgreement
  let busy: Bool
  let canChange: Bool
  let change: () -> Void
  let publish: () -> Void
  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
      Text("Review your league").csType(.agateS).foregroundStyle(cs.mut).id("top")
      Text(agreement.dials.name).csType(.displayS).fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("wizard-agreement")
      ForEach(agreement.rows) { row in
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          CSRule()
          Text(row.label).csType(.nameS)
          Text(row.value).csType(.body).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
        }.accessibilityElement(children: .combine)
      }
      Text("Score expectations are a group agreement, not an automatic eligibility check.").csType(.bodyS).foregroundStyle(cs.mut)
      Text(WizardCopy.inviteNote).csType(.bodyS).foregroundStyle(cs.mut)
      Button(WizardCopy.publish, action: publish).buttonStyle(.csPrimary(busy: busy))
        .accessibilityIdentifier("wizard-start").disabled(busy)
      if canChange {
        Button("Change your choices", action: change).buttonStyle(.csSecondary()).disabled(busy)
          .accessibilityIdentifier("wizard-change")
      } else if !busy {
        Text("Retry uses these same choices. Your season may already have started.").csType(.bodyS).foregroundStyle(cs.mut)
      }
      Text(WizardCopy.freezeNote).csType(.bodyS).foregroundStyle(cs.mut)
    }.foregroundStyle(cs.ink)
  }
}
