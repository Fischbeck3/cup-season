// Cup Season — the event room (`#view-event`, `renderEvent` 12197): one
// screen that routes on `events.kind` — the Ryder's scoreboard or the
// Major's leaderboard. "No event loaded." until `CS_EVENT` is set (12200);
// a failed load ends in a next move.

import SwiftUI
import CSDesign
import CupSeasonKit

struct EventRoomScreen: View {
  @Environment(\.cs) private var cs
  @State private var model: EventRoomModel
  let links: EventLinks

  init(eventId: UUID, links: EventLinks) {
    _model = State(initialValue: EventRoomModel(eventId: eventId))
    self.links = links
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        if let room = model.room {
          if room.event.isMajor { MajorRoomView(model: model, room: room, links: links) }
          else { RyderRoomView(model: model, room: room, links: links) }
        } else if let err = model.error {
          CSCard(spine: cs.neg) {
            VStack(alignment: .leading, spacing: 10) {
              Text("The room did not load").csEyebrow(cs.neg)
              Text(err).font(CSFont.body).foregroundStyle(cs.ink)
              CSButton("Try again", style: .quiet) { Task { await model.load() } }
            }
          }
        } else {
          CSFine("No event loaded.").padding(.horizontal, 4).padding(.vertical, 12)
        }
      }
      .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 32)
    }
    .background(cs.bg0)
    .navigationTitle(model.room?.event.name ?? "Event")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable { await model.load() }
    .task(id: model.eventId) { if !model.loaded { await model.load() } }
  }
}
