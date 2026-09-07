// Cup Season — the event room, rebuilt in Wave 6.
//
// **IT ROUTES ON THREE THINGS NOW, NOT ONE.** `events.kind` gives the Major;
// `CalloutShape.isCallout(sessionCount:leagueId:field:)` — one session, no
// league, a field of two — gives the callout its own room instead of telling
// two buddies who bet on Saturday that they are in "WEEK 1 OF 1" of a series.
// The predicate has been in the Kit since D237 and was called nowhere on the
// phone; this is the one line.
//
// THE TITLE CARD RUNS FULL-BLEED UNDER THE STATUS BAR, which is why the scroll
// view ignores the top safe area and the navigation bar is hidden: a plate
// under a bar means the platform's back button arrives inside a translucent
// disc sitting on the graphic. The chevron is drawn on the plate itself, in
// `ceremonyInk`, by `EventTitleCard`.
//
// `navigationTitle("")` — §12.2's double-naming defect was this screen setting
// `navigationTitle(event.name)` while the room drew the name again underneath.

import SwiftUI
import CSDesign
import CupSeasonKit

struct EventRoomScreen: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(SessionStore.self) private var store
  @State private var model: EventRoomModel
  let links: EventLinks

  init(eventId: UUID, links: EventLinks) {
    _model = State(initialValue: EventRoomModel(eventId: eventId))
    self.links = links
  }

  /// The routing predicate, and it is the Kit's — not this file's taste.
  private func isCallout(_ room: EventRoom) -> Bool {
    CalloutShape.isCallout(sessionCount: room.event.session_count,
                           leagueId: room.event.league_id,
                           field: room.players.count)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        if let room = model.room {
          if room.event.isMajor {
            MajorRoomView(model: model, room: room, links: links, back: { dismiss() })
          } else if isCallout(room) {
            CalloutRoomView(model: model, room: room, links: links, back: { dismiss() })
          } else {
            RyderRoomView(model: model, room: room, links: links, back: { dismiss() })
          }
        } else if let err = model.error {
          // §7.3 · only a room with NOTHING cached speaks: one `lead` line, one
          // `body` line, and **Try again** as the primary. The
          // `CSCard(spine: cs.neg)` went with the card.
          VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
            Text("The room didn't load.").csType(.lead).foregroundStyle(cs.ink)
              .fixedSize(horizontal: false, vertical: true)
            Text(err).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
            CSDoor(.primary("Try again", { Task { await model.load() } }))
            CSDoor(.link("Close", { dismiss() }))
          }
          .csGutter()
          .padding(.top, 72)
        } else {
          // §7.1 · **loading is the destination's own geometry, redacted** — the
          // plate paints immediately, the rail draws its cells and its rule, and
          // the clash rows draw their rules and their faces. The shipped
          // `CSFine("No event loaded.")` is deleted (`LINT-22`).
          placeholder.csRedacted(true)
        }
      }
      .padding(.bottom, CSTokens.Space.s6)
      // **THE PAGE IS PINNED TO THE CONTAINER, AND THAT IS NOT BELT AND
      // BRACES.** A vertical `ScrollView` sizes its content box to its widest
      // child and CENTRES a box wider than itself, so ONE row that refuses to
      // compress — a horizontal rail at AX3, an un-wrapping agate line — slides
      // EVERY block on the screen left and runs the widest one off the right
      // edge. Wave 5 met it on the season page and could not close it; this
      // wave found one cause (a tertiary link hugging a 57-character label) and
      // fixes the class here: the content is the container's width, full stop,
      // and a child that overflows clips instead of moving the page.
      .containerRelativeFrame(.horizontal)
    }
    .csPlateBleedsInDark(cs.bg0)
    .background(cs.bg0.ignoresSafeArea())

    // **THE BAR IS EMPTIED, NOT HIDDEN** (`csBareBar`, DF-07). Hiding it left
    // nothing to hang `toolbarColorScheme` on, so in the LIGHT printing the
    // system put its DARK glyph set on this page's near-black `ceremony`
    // plate: the clock, the cellular dots and the battery, unreadable, over
    // the top 60pt of a flagship surface. The plate is dark in both
    // printings and now says so. Nothing else about the bar changes — it
    // paints no background, carries no title and shows no system back button.
    .csBareBar(overDarkPlate: true)
    .refreshable { await model.load() }
    .task(id: model.eventId) {
      #if DEBUG
      // `-cs_dev_event_fixture [complete|callout|major]` — the signed-in
      // account has NO event on its payload, so every object this wave built
      // lives in a room nobody on this Mac can open. DEBUG only, never written,
      // and every shot taken through it is a fixture rather than anybody's real
      // competition.
      if let kind = EventFixture.kind, !model.loaded {
        model.room = EventFixture.room(kind, me: store.session?.user.id)
        model.loaded = true
        return
      }
      #endif
      if !model.loaded { await model.load() }
    }
    .csAssertBudget("event-room")
  }

  /// The room's own shape with no facts in it. Nothing here is a spinner and
  /// nothing here is a fabricated name — the redaction blanks the type.
  private var placeholder: some View {
    VStack(alignment: .leading, spacing: 0) {
      EventTitleCard(eyebrow: "Loading", live: false, title: "The event",
                     dateline: ["A course", "A date range · four in the field"],
                     back: { dismiss() })
      VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
        CSScoreRail([.init(id: "a", value: "0", label: "Side one"),
                     .init(id: "b", value: "0", label: "Side two")], size: .l)
        Text("First to five.").csType(.bodyS).foregroundStyle(cs.mut)
      }
      .csGutter()
      .padding(.top, CSTokens.Space.s4)
    }
  }
}
