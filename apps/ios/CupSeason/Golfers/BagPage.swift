// Cup Season — THE BAG, AS A PLACE (D312).
//
// The owner: *"I feel like we need a homebase for 'my bag' in the tour card.
// Maybe a bag Icon in the corner. I should be able to click on Galen, click the
// bag icon and see whats in it. Then 'galen updated his bag' can be on the feed
// and you can click in to see the card and associated info. Then its more built
// out."*
//
// **THIS PAGE READS; `BagSheet` EDITS.** They are not two versions of one
// screen. `BagSheet` is fourteen text fields and a save — it can only ever be
// about YOUR bag, and it says so in its own header (*"the one place it is
// edited"*). This shows ANYONE'S, yours and Galen's identically, and its one
// action on your own is a door back to that editor. The alternative — one
// screen that is two different things depending on whose it is — is how the
// tour card got complicated, and §7.3 already says objects are pushed and
// actions are presented.
//
// **WHY A PAGE AND NOT THE SECTION THAT ALREADY EXISTED.** `PersonPage` draws
// the bag today, four scrolls down, only when it is non-empty, with nothing on
// the card announcing it. The section stays; what it lacked was a place a feed
// row could LAND on — and D312's other half is the door that now leads here.
//
// **AN EMPTY DOOR IS A BROKEN PROMISE.** Nothing links here for a golfer whose
// bag is hidden or unfilled: `Bag.visible` is the gate, `isEmpty` is the
// second, and the corner glyph on the tour card is drawn only when both pass.
// If this page is reached anyway — a stale route, a bag emptied since the row
// was drawn — it says so plainly rather than drawing fourteen blank rows.

import SwiftUI
import CSDesign
import CupSeasonKit

struct BagPage: View {
  @Environment(\.cs) private var cs
  @Environment(\.presenter) private var presenter
  let profileId: UUID
  /// The name for the head. Passed in where the caller has it (a feed row, a
  /// tour card) so the page does not read a profile just to print a word.
  var name: String?

  @State private var bag: Bag?
  @State private var loading = true
  @State private var failed = false

  private var isMe: Bool { bag?.isMe == true }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        CSPageHeader(isMe ? BagCopy.yours : BagCopy.inTheBag,
                     // LINT-14 · the eyebrow ROLE sets the case; a string that
                     // uppercases itself breaks VoiceOver and localisation.
                     eyebrow: isMe ? nil : name) {
          // §7.1 · one act on the page, and only on your own bag. It is a
          // tertiary and not a primary: the page is a thing to look at.
          if isMe {
            CSDoor(.link("Edit") { presenter.showBag = true })
          }
        }

        if loading {
          // The destination's own geometry, redacted — never a spinner
          // (LINT-22).
          bagBody(Bag.placeholder).csRedacted(true)
        } else if failed {
          // L-32 · a failed read is never an empty bag. Saying "nothing in it"
          // about a golfer whose fourteen clubs are on the other side of a
          // dead network is the lie this branch refuses.
          VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
            Text("Could not open the bag.").csType(.lead).foregroundStyle(cs.ink)
            Text("Nothing has been changed.").csType(.body).foregroundStyle(cs.mut)
            CSDoor(.link("Try again") { Task { await load() } })
          }
        } else if let bag, !bag.isEmpty, bag.visible {
          bagBody(bag)
        } else {
          // Reached anyway — a stale row, or a bag emptied since. §13.1: a
          // drawn object, a fact about the WORLD, and a door.
          //
          // **LINT-21 makes the door non-optional and that is the right
          // pressure here.** On somebody else's empty bag there is nothing for
          // this viewer to do, and `.elsewhere` is the case for exactly that —
          // a reference line, not a control. The alternative would have been
          // an optional door and a screen that quietly ends in nothing.
          CSEmpty(glyph: .bag,
                  eyebrow: BagCopy.inTheBag,
                  headline: isMe
                    ? "Fourteen clubs is the limit. Yours is still empty."
                    // The name where we have it, and a THEY/THEM sentence where
                    // we do not — never a pronoun guessed from a name (D77,
                    // `CSBands.theirs`). A naive interpolation produces "They
                    // hasn't" here, so the two readings are two sentences
                    // rather than one with a hole in it.
                    : (name.map { "\($0) hasn't filled the bag in yet." }
                       ?? "They haven't filled the bag in yet."),
                  door: isMe
                    ? .link(BagCopy.addClub, { presenter.showBag = true })
                    : .elsewhere("Yours is on your own card."))
        }
      }
      .padding(.horizontal, CSTokens.Space.gutter)
      .padding(.bottom, CSTokens.Space.s6)
      .frame(maxWidth: .infinity, alignment: .leading)
      .csPage("bag")
    }
    .background(cs.bg0)
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .csStatusCap(cs.bg0)
    .refreshable { await load() }
    .task(id: profileId) { await load() }
  }

  /// **THE SENTENCE THE WHOLE FEATURE EXISTS FOR, AT THE TOP.** `bag_of`
  /// already computes it — *"Since the new driver went in: four rounds, two
  /// beat your playing HCP"* — against the allowance lens `v_rounds_ranked`,
  /// so the count can never disagree with the chip on a round it counts. It has
  /// been returned since D262 and nothing on Home has ever pointed at it.
  @ViewBuilder private func bagBody(_ bag: Bag) -> some View {
    if let since = bag.since {
      Text(BagCopy.sinceLine(since, isMe: bag.isMe))
        .csType(.story).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
    }

    CSSectionHead(BagCopy.inTheBag, count: "\(bag.clubs.count) of \(BagCopy.cap)")
    VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(bag.clubs.enumerated()), id: \.element.id) { i, club in
        if i > 0 { CSRule() }
        row(club.slotLabel.isEmpty ? "Club" : club.slotLabel, club.label)
      }
      if let ball = bag.ball {
        CSRule()
        row(BagCopy.ballHead, ball.label)
      }
    }

    // The differentiated half (D262): most bag features are a static fourteen,
    // and a 3-iron that replaces the 5-wood *sometimes* is what makes "is
    // Galen bringing the new driver?" a question with an answer.
    if !bag.sideline.isEmpty {
      CSSectionHead(BagCopy.sideline, count: "\(bag.sideline.count)")
      CSFine(BagCopy.sidelineWhat)
      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(bag.sideline.enumerated()), id: \.element.id) { i, club in
          if i > 0 { CSRule() }
          row(club.slotLabel.isEmpty ? "Club" : club.slotLabel, club.label)
        }
      }
    }
  }

  private func row(_ label: String, _ value: String) -> some View {
    A11yStack(rowAlignment: .firstTextBaseline, spacing: CSTokens.Space.s3,
              columnSpacing: CSTokens.Space.s1) {
      Text(label).csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .frame(minWidth: 78, alignment: .leading)
      Text(value).csType(.body).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, CSTokens.Space.s3)
    .accessibilityElement(children: .combine)
  }

  private func load() async {
    failed = false
    let read = await BagService().load(profileId)
    bag = read
    failed = read == nil
    loading = false
  }
}

extension Bag {
  /// The shape the redacted state draws — never rendered as content, so the
  /// words are placeholders and not a claim about anybody's clubs.
  static let placeholder = Bag(
    visible: true, isMe: false,
    clubs: (0..<5).map { _ in Item(slot: "Club", label: "A club in the bag") },
    ball: Item(slot: nil, label: "A ball"))
}
