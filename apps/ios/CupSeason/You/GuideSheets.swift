// Cup Season — D82: "How it works" — the guide sheets and the scoring help
// (index.html `GUIDE` ~14840–14860, `openScoringHelp` ~19409–19432). The
// text is `GuideCopy`'s, and `ScoringHelpSheet` is the ONE scoring guide on
// the phone (Y-25): the welcome, Card & settings and the room all present it
// (`LeagueRoomScreen.swift` renders `ScoringHelpSheet(solo:)`; `BylawsCard`'s
// own `RoomScoringHelpSheet` is gone).

import SwiftUI
import CSDesign
import CupSeasonKit

struct GuideSheetView: View {
  let sheet: GuideSheet
  var body: some View {
    SliceSheet(title: sheet.title, sub: sheet.sub) {
      ForEach(Array(sheet.paragraphs.enumerated()), id: \.offset) { _, p in
        Fine(markdown: p).padding(.bottom, 4)
      }
    }
    .presentationDetents([.medium, .large])
  }
}

struct ScoringHelpSheet: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store: SessionStore?
  /// D205 · the structure the guide describes. Pass it where a league is in
  /// hand (the welcome, the room); nil falls back to the preferred league, and
  /// with no league at all the floor paragraph covers both structures.
  var solo: Bool? = nil
  /// Q-27 · the league's minimum, so "What counts" states it in the one floor
  /// sentence. Pass it with `solo` from the same league; when neither is
  /// passed both come from the preferred league, so they never describe two.
  var minimum: GuideCopy.Minimum? = nil

  private var preferred: Me.Membership? {
    guard let store, let me = store.me else { return nil }
    return me.memberships.first { $0.league_id == store.preferredLeague } ?? me.memberships.first
  }

  private var structureSolo: Bool? {
    if let solo { return solo }
    if let minimum { return minimum.solo }
    return preferred?.settings?.structure.map { $0 == "solo" }
  }

  private var leagueMinimum: GuideCopy.Minimum? {
    if let minimum { return minimum }
    guard solo == nil else { return nil }   // a caller's league, not the preferred one
    return GuideCopy.Minimum(preferred?.settings)
  }

  var body: some View {
    SliceSheet(title: GuideCopy.scoringTitle, sub: GuideCopy.scoringSub) {
      ForEach(GuideCopy.scoring(solo: structureSolo, minimum: leagueMinimum)) { s in
        if !s.eyebrow.isEmpty { Text(s.eyebrow).csEyebrow().padding(.top, 6) }
        ForEach(Array(s.paragraphs.enumerated()), id: \.offset) { _, p in Fine(markdown: p) }
        if !s.bands.isEmpty {
          // D266 · the five band lines were in a bordered card inside a sheet
          // that is already a container. A rule sets them apart; a box around
          // them was the product paying the full cost of over-carding for
          // nothing. `CSLeaf` is not right either — this is prose, not a grid.
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            CSRule()
            ForEach(s.bands, id: \.self) { b in Fine(markdown: b) }
          }
          .padding(.top, CSTokens.Space.s1)
        }
      }
    }
  }
}

/// The five `.check` rows under "How it works".
struct HowItWorks: View {
  let open: (GuideCopy.Row) -> Void
  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(GuideCopy.rows.enumerated()), id: \.element.id) { i, r in
        CSRow(last: i == GuideCopy.rows.count - 1) {
          YouDoorRow(glyph: CSGlyph(GuideGlyph.of(r.key), size: .row), title: r.title, sub: r.sub, action: { open(r) })
        }
      }
    }
  }
}

/// The guide's five rows, in the one drawn family (D277). `GuideCopy.Row.glyph`
/// still carries the web's character — one of them is the ⛳ emoji `LINT-12`
/// forbids — so the phone maps the row's KEY to a drawn mark rather than
/// rendering whatever character the producer happens to hold.
enum GuideGlyph {
  static func of(_ key: String) -> CSGlyph.Name {
    switch key {
    case "places": .home
    // never the flag — LINT-28 reserves it to the tab band and the app icon
    case "games": .calendar
    case "posting": .scorecard
    case "buddies": .people
    default: .clock
    }
  }
}
