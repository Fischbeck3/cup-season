// Cup Season — the season's story, at length (D223, R-H).
//
// "The season's story →" opens the arc as a page: a week-by-week column of
// what actually happened, from the same read the story line was chosen from.
// It is the thing a golfer screenshots in February, and it is what every
// season row in the record opens onto instead of a dead table.
//
// EVERY LINE IS A COUNT OVER A NAMED READ. `SeasonStoryCopy.arc` refuses any
// row whose `source` is not one of the reads this build knows, so a server
// that starts sending a new kind renders one fewer line rather than a
// sentence nobody can trace (R-H's fence, L-01).

import SwiftUI
import CSDesign
import CupSeasonKit

struct SeasonStoryPane: View {
  @Environment(\.cs) private var cs
  let model: LeagueRoomModel
  let links: LeagueRoomLinks

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        if let line = model.storyLine {
          Text(line.text).font(CSFont.sentence).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        arc
        archive
      }
      .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .csLookGround()
    .navigationTitle("The season's story")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: the arc

  @ViewBuilder private var arc: some View {
    let rows = (model.seasonStory?.arc ?? []).compactMap { a -> (SeasonStory.Arc, String)? in
      SeasonStoryCopy.arc(a).map { (a, $0) }
    }
    VStack(alignment: .leading, spacing: 0) {
      CSSectionHead("Week by week")
      if rows.isEmpty {
        // L-32 · an empty state ends in a next move, and a season with no
        // story yet has exactly one: play.
        //
        // C-09 · a read that did NOT ANSWER says so and offers the retry. It
        // used to say the story had not started, which for a season with
        // eleven weeks of story and a bad signal is a false fact about the
        // season, told with the season's own voice.
        if model.storyRead == .failed {
          let e = EmptyRoot.failedRead()
          CSEmptyState(icon: "📖", line: "\(e.head) \(e.sub)", cta: "Try again") {
            Task { await model.reloadStory() }
          }
        } else {
          CSEmptyState(icon: "📖",
                       line: model.seasonStory == nil
                         ? "The story arrives with the season's first weekly snapshot."
                         : "Nothing has happened yet. The first posted round starts the story.",
                       cta: links.openRecord == nil ? nil : "Add my round") { links.openRecord?() }
        }
      }
      ForEach(Array(rows.enumerated()), id: \.offset) { _, pair in
        let (a, text) = pair
        VStack(alignment: .leading, spacing: 3) {
          if let wk = SeasonStoryCopy.arcWeek(a) {
            Text(wk).font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText)
          }
          Text(text).font(CSFont.body).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) { Rectangle().fill(cs.rule).frame(height: 1) }
        .accessibilityElement(children: .combine)
      }
    }
  }

  // MARK: the archive — every season this league has played

  @ViewBuilder private var archive: some View {
    let seasons = model.seasonStory?.archive ?? []
    if seasons.count > 1 {
      VStack(alignment: .leading, spacing: 0) {
        CSSectionHead("Every season")
        ForEach(seasons) { s in
          VStack(alignment: .leading, spacing: 3) {
            Text("Season \(s.number.map(String.init) ?? "—")")
              .font(CSFont.subhead.weight(s.is_current == true ? .semibold : .regular)).foregroundStyle(cs.ink)
            Text(SeasonStoryCopy.archiveLine(s)).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity, alignment: .leading)
          .overlay(alignment: .bottom) { Rectangle().fill(cs.rule).frame(height: 1) }
          .accessibilityElement(children: .combine)
        }
      }
    }
  }
}
