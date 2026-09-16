// Cup Season — the good hole, said once (F13 / D368).
//
// A restrained ember stroke beside the card, the word, the hole, and then it
// leaves. Never a modal, never confetti, never a sound; the next-hole target
// stays exactly where it was and is never covered. This is the narrow earned
// play-moment exception D368 records: it is NOT a competition mark (F11) and
// it does NOT repaint the score grid (D267) — it sits beside the header for
// one hole and is gone.

import SwiftUI
import CSDesign
import CupSeasonKit

/// What the store hands the view: which moment, on which hole (1-based).
struct LiveHoleMomentData: Equatable {
  let kind: HoleMoment
  let hole: Int
}

struct LiveHoleMomentView: View {
  @Environment(\.cs) private var cs
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let data: LiveHoleMomentData

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
      // the one ember object: a 2pt stroke, the same hand as a live rule
      Rectangle().fill(cs.brand).frame(width: 2)
        .padding(.vertical, CSTokens.Space.s1)
      // an eagle is more pronounced than a birdie — by SIZE, never by a
      // second colour or a second object
      Text(data.kind.word)
        .csType(data.kind == .eagle ? .lead : .name, caps: true)
        .foregroundStyle(cs.brand)
      Text("on \(data.hole)").csType(.agateS, caps: true).foregroundStyle(cs.mut)
      Spacer(minLength: 0)
    }
    .fixedSize(horizontal: false, vertical: true)
    .csBudget(ember: 1)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(data.kind.spoken(hole: data.hole))
    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
  }
}

/// `1 EAGLE · 1 BIRDIE` — the round's quiet factual line. Facts, not form.
struct LiveMomentTally: View {
  @Environment(\.cs) private var cs
  let line: String
  var body: some View {
    Text(line).csType(.agateS, caps: true).foregroundStyle(cs.mut)
      .accessibilityLabel(line)
  }
}
