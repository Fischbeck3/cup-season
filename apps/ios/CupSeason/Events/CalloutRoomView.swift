// Cup Season — THE CALLOUT ROOM (new in Wave 6; surfaces/event.md §3).
//
// **A callout was landing in the Ryder room and being told it was in "WEEK 1
// OF 1" of a series it is not in.** `Callout.swift`'s own header names the
// failure — *"the Ryder room's grammar was written for a four-week series
// between two SIDES … so a callout does not land there"* — and
// `CalloutShape.isCallout(sessionCount:leagueId:field:)` has existed in the Kit
// since D237 and was called nowhere on the phone. The branch is one line, in
// `EventRoomScreen`; this is the room it opens.
//
// SAME OBJECTS, TWO PEOPLE. The same title card, the same rule-and-figure, the
// same primary — and **the two golfers ARE the title**: a 56pt face and
// `display` 34 for each, with a 2pt `brand` rule between them. Two names, one
// live rule. Where the Ryder has a week of clashes, the callout has the record,
// printed on a leaf.
//
// NO COURSE, NO CONTOUR, AND THAT IS THE POINT. §10.1's ladder has no fourth
// state, so the plate is simply the ceremony ground — and `event-callout` is
// the artboard that proves the head does not need an image.

import SwiftUI
import CSDesign
import CupSeasonKit

struct CalloutRoomView: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(SessionStore.self) private var store
  let model: EventRoomModel
  let room: EventRoom
  let links: EventLinks
  let back: () -> Void
  @State private var record: HeadToHead?

  private var me: UUID? { store.session?.user.id }
  private var live: Bool { !room.event.isComplete }
  private var session: EventSession? { room.sessions.first }
  private var duel: EventDuel? { room.duels.first }

  /// Me, and him. A callout has a field of two by construction (`isCallout`).
  private var mine: EventPlayer? { room.me(me) ?? room.players.first }
  private var theirs: EventPlayer? { room.players.first { $0.id != mine?.id } }

  var body: some View {
    let my = mine, their = theirs

    EventTitleCard(eyebrow: eyebrow, live: live, title: nil, dateline: [dateline], seed: nil, back: back) {
      if let my, let their {
        CalloutHead(mine: face(my), myName: my.name.uppercased(),
                    theirs: face(their), theirName: their.name.uppercased(), live: live)
      }
    }

    // ---- B · three figures on one rule -------------------------------------
    VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
      CSScoreRail(cells, size: .l, metal: live ? .live : .ink)

      // ---- C · the stake -----------------------------------------------------
      if room.event.isComplete {
        // the three closing states: the result sentence takes the serif where
        // the stake sat, and the eyebrow drops its dot.
        Text(closingLine).csType(.lead).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
      } else {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          if let terms = forfeitTerms {
            Text("On it").csType(.agate, caps: true).foregroundStyle(cs.mut)
            // **A bet is exactly the sentence §1.4 reserves the serif for**, and
            // it is the surface's one serif appearance.
            Text("“\(terms)”").csType(.story).foregroundStyle(cs.ink)
              .fixedSize(horizontal: false, vertical: true)
          }
          Text(CalloutCopy.noPoints).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      // ---- D · the primary ---------------------------------------------------
      primary
    }
    .csGutter()
    .padding(.top, CSTokens.Space.s4)

    // ---- E · the record ----------------------------------------------------
    //
    // **THE FOUR-COLUMN LEAF HAS NO PRODUCER, AND I DID NOT INVENT ONE.** §3 E
    // draws `DATE · WHERE · GALEN · YOU` with both figures and a gold rule
    // under the winning cell. `head_to_head` returns `last_five` as
    // `{on, won, facet}` — no course, and no per-meeting figures at all — so
    // three of the leaf's four columns would be fabricated. What the payload
    // DOES carry is who won each meeting in order, which is exactly the tape
    // Wave 3 built for it, on the surface that owns the full record. The leaf
    // returns the day the payload does (§10's own rule: the block does not
    // render rather than degrading into a guess).
    if let h = record, h.record.settled > 0 {
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        CSRule()
        if let line = HeadToHeadCopy.headline(h) {
          Text(line).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
        }
        if !h.lastFive.isEmpty {
          CSTape(meetings: h.lastFive.enumerated().map { .init(id: $0.offset, viewer: $0.element.won) },
                 key: "One square is one win.",
                 rows: (mine: "Yours", theirs: "Theirs"),
                 spoken: tapeSpoken(h))
        }
        // F · a tertiary link, no arrow at all — the 2px rule is the affordance
        // (§5.2, `LINT-13`).
        if let opp = theirs?.profileId {
          CSDoor(.link("Every meeting", { links.openHeadToHead(opp) }))
        }
      }
      .csGutter()
      .padding(.top, CSTokens.Space.s4)
    }

    Color.clear.frame(height: 0)
      .task(id: room.event.id) { await loadRecord() }
  }

  // MARK: the head

  private var eyebrow: String {
    if room.event.isComplete {
      let on = session?.closes_on
      return "Final" + (on.map { " · \(LeagueDates.dowMonDay($0))" } ?? "")
    }
    guard let on = session?.closes_on else { return "Live" }
    return "Live · closes \(EventDates.weekdayLong(on))"
  }

  /// `ONE ROUND EACH · ANY COURSE · BEST BY SUN SEP 13` —
  /// `CalloutCopy.openLine`'s date through `LeagueDates.dowMonDay`, the same
  /// producer the covenant clock uses.
  private var dateline: String {
    guard let on = session?.closes_on else { return "One round each · any course" }
    return "One round each · any course · best by \(LeagueDates.dowMonDay(on))"
  }

  private func face(_ p: EventPlayer) -> CSFace.Model {
    CSFace.Model(id: p.profileId ?? p.id, marker: p.marker,
                 initials: Initials.of(p.name), isViewer: p.profileId != nil && p.profileId == me)
  }

  // MARK: B · his number, mine, and the clock

  /// `+2.1` / `GALEN, FRI` · `—` / `YOU` · `3` / `DAYS LEFT`.
  ///
  /// The empty side renders `—` in `mut` and **never a zero and never a guess**.
  /// A callout's clock IS one of its three numbers, because a callout has no
  /// week structure to put it in — which is the one place §15.5a's "a countdown
  /// is not a score" does not apply, and the artboard says so.
  private var cells: [CSScoreRail.Cell] {
    guard let d = duel, let my = mine, let their = theirs else { return [] }
    let iAmA = d.a_player == my.id
    let myPvi = iAmA ? d.a_pvi : d.b_pvi
    let theirPvi = iAmA ? d.b_pvi : d.a_pvi
    var out: [CSScoreRail.Cell] = [
      CSScoreRail.Cell(id: "them", value: theirPvi.map(RoundCopy.signed) ?? "—",
                       label: CSBands.fn1(their.name), spoken: theirCellSpoken(theirPvi, their.name)),
      CSScoreRail.Cell(id: "me", value: myPvi.map(RoundCopy.signed) ?? "—",
                       label: "You", spoken: myPvi == nil ? "You, still to post" : "You, \(RoundCopy.signed(myPvi ?? 0))"),
    ]
    if !room.event.isComplete, let on = session?.closes_on, let days = EventDates.daysUntil(on), days >= 0 {
      out.append(CSScoreRail.Cell(id: "clock", value: String(days), label: "Days left", labelLive: true,
                                  spoken: days == 0 ? "Closes tonight" : "\(days) days left"))
    }
    return out
  }

  private func theirCellSpoken(_ pvi: Double?, _ name: String) -> String {
    guard let pvi else { return "\(CSBands.fn1(name)) has not posted" }
    return "\(CSBands.fn1(name)), \(RoundCopy.signed(pvi))"
  }

  /// The forfeit's own words, from the board's own post. `forfeits` has no
  /// money column by rule (T-02 / D242), so this is a sentence or it is
  /// nothing — money never appears on a callout.
  private var forfeitTerms: String? {
    room.posts.compactMap { p -> String? in
      guard let b = p.body, let r = b.range(of: "“") ?? b.range(of: "\"") else { return nil }
      let rest = b[r.upperBound...]
      guard let end = rest.range(of: "”") ?? rest.range(of: "\"") else { return nil }
      let terms = String(rest[..<end.lowerBound])
      return terms.isEmpty ? nil : terms
    }.first
  }

  /// `CalloutCopy.youTookIt` / `.theyTookIt` / `.allSquare`, verbatim.
  private var closingLine: String {
    guard let d = duel, let my = mine, let their = theirs else { return CalloutCopy.allSquare }
    let iAmA = d.a_player == my.id
    let myPvi = iAmA ? d.a_pvi : d.b_pvi
    let theirPvi = iAmA ? d.b_pvi : d.a_pvi
    let iWon = (iAmA && d.result == "a") || (!iAmA && d.result == "b")
    let theyWon = (iAmA && d.result == "b") || (!iAmA && d.result == "a")
    if iWon, let m = myPvi { return CalloutCopy.youTookIt(mine: m, theirs: theirPvi) }
    if theyWon, let t = theirPvi { return CalloutCopy.theyTookIt(their.name, theirs: t, mine: myPvi) }
    return CalloutCopy.allSquare
  }

  // MARK: D · the primary

  @ViewBuilder private var primary: some View {
    if room.event.isComplete {
      CSDoor(.secondary("Call them out again", { if let opp = theirs?.profileId { links.callOut(opp) } }))
    } else if iPosted {
      // the ember leaves the button but not the dot
      CSDoor(.secondary("See the receipt", { if let r = myRound { links.openReceipt(r) } }))
    } else {
      CSDoor(.primary("Add my round", { links.addRound() }))
    }
  }

  private var iPosted: Bool {
    guard let d = duel, let my = mine else { return false }
    return (d.a_player == my.id ? d.a_pvi : d.b_pvi) != nil
  }
  private var myRound: UUID? {
    guard let d = duel, let my = mine else { return nil }
    return d.a_player == my.id ? d.a_round : d.b_round
  }

  // MARK: E · the record

  /// ONE VoiceOver element for the whole tape, in the product's voice.
  private func tapeSpoken(_ h: HeadToHead) -> String {
    let them = CSBands.fn1(theirs?.name ?? h.opponent.name)
    return "\(HeadToHeadCopy.headline(h) ?? "") You won \(CSCopy.spelled(h.record.wins)), \(them) won \(CSCopy.spelled(h.record.losses))."
  }

  private func loadRecord() async {
    guard let opp = theirs?.profileId else { return }
    record = await PeopleService().headToHead(opp)
  }
}
