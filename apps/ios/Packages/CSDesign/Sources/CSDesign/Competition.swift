// Cup Season — the competition band (F11 · option 2, Scoreboard).
//
// **ONE broad, flat ember surface per competition, and the type on it is dark.**
// The owner's application board asked for a recognisable competition room built
// from the colours the product already has: fescue and cream stay the everyday
// app, green stays the ordinary action, gold stays earned, and ember stops
// being a hairline accent and becomes the identity of a competition.
//
// Three rules this component exists to keep:
//
// 1 · **The ink flips with the printing.** Ember is a bright #E8622C on the
//     dark ground and a dark #A13F0E on paper, so one ink cannot serve both:
//     fescue measures 5.27:1 on the first and 2.74:1 on the second. `brandInk`
//     is the token that flips, and nothing here may hard-code either value.
//
// 2 · **It is flat.** No gradient, no inner shadow, no second ember object
//     inside it. The board is a colour and composition reference, not a
//     licence to restyle the product's surfaces.
//
// 3 · **Colour never carries the state.** Ember now marks a competition in
//     ANY state, so the band always prints `state.word` — Upcoming, Live or
//     Final — and says the same thing to VoiceOver. A band with no state word
//     would be the exact ambiguity broadening the rule introduced.
//
// It counts as ONE ember mark against LINT-18's budget, declared here rather
// than at each call site: a single object is one mark however large it is.

import SwiftUI

public struct CSCompetitionBand: View {
  @Environment(\.cs) private var cs

  /// The competition's own name — a season, an event, a clash.
  public let title: String
  /// Where it is in its own run: "Week 7 of 13", "Closes Sunday", "Final".
  public let meta: String?
  /// Upcoming · Live · Final, printed and spoken. Never implied by the colour.
  public let state: String
  /// The one figure worth the space — a rank ordinal, a score. Optional: an
  /// upcoming season has no standing yet, and a band may be all words.
  public let figure: String?
  public let ordinal: String?
  /// The sentence beside the figure — "9 points clear", "Closes Sunday".
  public let note: String?
  /// What VoiceOver hears first, so the state never arrives as colour alone.
  public let spokenState: String

  public init(title: String, meta: String? = nil, state: String, figure: String? = nil,
              ordinal: String? = nil, note: String? = nil, spokenState: String) {
    self.title = title; self.meta = meta; self.state = state
    self.figure = figure; self.ordinal = ordinal; self.note = note
    self.spokenState = spokenState
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      // the name, and the state — the state is a WORD, always present
      HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
        Text(title).csType(.agate, caps: true)
        Spacer(minLength: CSTokens.Space.s2)
        Text(state).csType(.agate, caps: true)
      }
      .foregroundStyle(cs.brandInk)

      if figure != nil || note != nil {
        HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s4) {
          if let figure {
            CSFigure(figure, size: .l, label: nil, ordinal: ordinal, over: .ember)
          }
          if let note {
            Text(note).csType(.story).foregroundStyle(cs.brandInk)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }

      if let meta {
        Text(meta).csType(.agateS, caps: true).foregroundStyle(cs.brandInk)
      }
    }
    .padding(CSTokens.Space.s4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.brand, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .accessibilityElement(children: .combine)
    .accessibilityLabel([spokenState, title, meta, figure.map { "\($0)\(ordinal ?? "")" }, note]
      .compactMap { $0 }.joined(separator: ", "))
    .csBudget(ember: 1)
  }
}
