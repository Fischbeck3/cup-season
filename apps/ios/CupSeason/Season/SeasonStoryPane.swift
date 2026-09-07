// Cup Season — THE STORY (Wave 5, `surfaces/season.md` §1.8).
//
// A pushed screen that opens with a DIFFERENT OBJECT from the season page
// (§15): the eyebrow, `display` THE STORY, and three figures on one 2pt ink
// rule — weeks played · weeks in all · in the field.
//
// THE ARC IS WEIGHTED IN THREE TIERS, which is the P0 this page closes: eight
// entries at one weight made a milestone, a notice and a database row
// typographically identical (CS-29). Now:
//
//   the chapter   `agate` WEEK 5 + rule + the date range flush right
//   the lead      the newest chapter's ladder sentence, `lead` 28 — ONE per
//                 viewport, and only in the newest chapter (D-2a)
//   a moment      `body` 17 in ink + an agate dateline + a `panel` with the gross
//   a result      `body` 17 in ink + a face pair or a movement mark
//   a notice      `body` 15 in `mut`, quiet by construction
//
// EVERY LINE IS STILL A COUNT OVER A NAMED READ. `SeasonStoryCopy.arc` refuses
// any row whose `source` is not one this build knows, so a server that starts
// sending a new kind renders one fewer line rather than a sentence nobody can
// trace (R-H's fence, L-01).

import SwiftUI
import CSDesign
import CupSeasonKit

struct SeasonStoryPane: View {
  @Environment(\.cs) private var cs
  let model: LeagueRoomModel
  let links: LeagueRoomLinks

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        head
        arc
        archive
      }
      .padding(.top, CSTokens.Space.s2).padding(.bottom, CSTokens.Space.s6)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .csLookGround()
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: the head — three figures on ONE rule

  private var head: some View {
    let f = model.seasonStory?.facts
    let played = f?.week_no ?? model.clock.currentWeek
    let total = f?.weeks_total ?? model.clock.totalWeeks
    let field = f?.field ?? model.teams.count
    return VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      Text(SeasonBoardCopy.dateline(number: model.season?.number, span: model.league?.name ?? "", pro: nil))
        .csType(.agate, caps: true).foregroundStyle(cs.mut)
      Text("The story").csType(.display).foregroundStyle(cs.ink)
      CSFactStrip([
        .init(value: String(format: "%02d", played), label: "weeks played"),
        .init(value: String(format: "%02d", total), label: "weeks in all"),
        .init(value: String(format: "%02d", field), label: "in the field"),
      ])
    }
    .csGutter()
  }

  // MARK: the arc, in chapters

  /// The arc grouped by week, newest first. A chapter is a WEEK; every entry
  /// under it is a tier.
  private var chapters: [(week: Int?, rows: [(SeasonStory.Arc, String)])] {
    let rows = (model.seasonStory?.arc ?? []).compactMap { a -> (SeasonStory.Arc, String)? in
      SeasonStoryCopy.arc(a).map { (a, $0) }
    }
    var order: [Int?] = []
    var byWeek: [Int: [(SeasonStory.Arc, String)]] = [:]
    var loose: [(SeasonStory.Arc, String)] = []
    for r in rows {
      if let w = r.0.week {
        if byWeek[w] == nil { order.append(w); byWeek[w] = [] }
        byWeek[w]!.append(r)
      } else {
        if loose.isEmpty { order.append(nil) }
        loose.append(r)
      }
    }
    return order.map { w in (w, w.flatMap { byWeek[$0] } ?? loose) }
  }

  @ViewBuilder private var arc: some View {
    let chs = chapters
    if chs.isEmpty {
      emptyArc.csGutter()
    } else {
      VStack(alignment: .leading, spacing: CSTokens.Space.s5) {
        ForEach(Array(chs.enumerated()), id: \.offset) { i, ch in
          VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
            CSSectionHead(ch.week.map { "Week \($0)" } ?? "Earlier", count: range(ch.week))
            // **D-2a · the chapter headline is the serif, one per chapter, and
            // only the TOP chapter's is `lead` 28.** The first draft rendered
            // four serif blocks on this page and the serif stopped meaning
            // "slow down here".
            if i == 0, let line = model.storyLine {
              Text(line.text).csType(.lead).foregroundStyle(cs.ink)
                .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(ch.rows.enumerated()), id: \.offset) { _, pair in
              entry(pair.0, pair.1, serif: i > 0 && pair.0.kind == "lead_change")
            }
          }
          .csGutter()
        }
      }
    }
  }

  private func range(_ week: Int?) -> String? {
    guard let w = week, let start = model.clock.startsOn else { return nil }
    let a = LeagueDates.addDays(start, (w - 1) * 7)
    let b = LeagueDates.addDays(start, w * 7 - 1)
    return "\(LeagueDates.monDay(a)) – \(LeagueDates.monDay(b))"
  }

  /// One entry, at its tier.
  @ViewBuilder private func entry(_ a: SeasonStory.Arc, _ text: String, serif: Bool) -> some View {
    switch tier(a) {
    case .moment:
      HStack(alignment: .top, spacing: CSTokens.Space.s3) {
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          Text(text).csType(.body).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
          if let d = dateline(a) {
            Text(d).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // §13 · NEW DATA, and the surface degrades cleanly without it.
        // `SeasonStory.Arc` carries no numeric field, so the panel cannot be
        // filled from the arc and the tier falls back to a bare report. See
        // the file's own note and the wave's report.
      }
      .accessibilityElement(children: .combine)
    case .result:
      HStack(alignment: .center, spacing: CSTokens.Space.s3) {
        if a.kind == "clash", let faces = clashFaces(a) {
          CSFaceRow(faces, style: .overlapped)
        }
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          Text(text).csType(serif ? .story : .body).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
          if let d = dateline(a) {
            Text(d).csType(.agateS, caps: false).foregroundStyle(cs.mut)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if a.kind == "lead_change" { CSMovement(.up(1)) }
        if a.kind == "clash", a.subject == nil { CSMovement(.held) }
      }
      .accessibilityElement(children: .combine)
    case .notice:
      Text(text).csType(.bodyS).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private enum Tier { case moment, result, notice }

  private func tier(_ a: SeasonStory.Arc) -> Tier {
    switch a.kind {
    case "lead_change", "clash": return .result
    case "post":
      // **The arc only ever carries two post kinds**, because `season_story`'s
      // own select is `po.kind in ('moment', 'system')`: a `moment` is a round,
      // a first or a personal best and reads as a report in `body` 17 ink; a
      // `system` post is a month close or a first tee and is a NOTICE, quiet by
      // construction. Guessing at a longer list put every entry on the page at
      // the notice weight, which is CS-29 arriving through the tier that was
      // supposed to close it.
      return (a.post_kind ?? "") == "moment" ? .moment : .notice
    default: return .notice
    }
  }

  /// `Sat Sep 5 · Papago` — **sentence case**, because it is a phrase and not a
  /// label, and so it costs none of the viewport's ten tracked-caps lines.
  /// **Clamped to today**: a week-5 item dated tomorrow on a device reading
  /// today is a story about the future.
  private func dateline(_ a: SeasonStory.Arc) -> String? {
    guard let on = a.on, CSDate.local(on) != nil else { return nil }
    let today = model.clock.today
    let day = on > today ? today : on
    return LeagueDates.dowMonDay(day)
  }

  private func clashFaces(_ a: SeasonStory.Arc) -> [CSFace.Model]? {
    let names = [a.subject, a.other].compactMap { $0 }
    guard names.count == 2 else { return nil }
    let faces = names.compactMap { n -> CSFace.Model? in
      guard let m = model.members.first(where: { $0.name.lowercased() == n.lowercased() })
              ?? (n.lowercased() == "you" ? model.myMember : nil) else { return nil }
      return CSFace.Model(id: m.profile_id, marker: m.mk, photoURL: model.avatarURL[m.profile_id],
                          isViewer: model.viewer?.id == m.profile_id)
    }
    return faces.count == 2 ? faces : nil
  }

  /// L-32 · an empty state ends in a next move. C-09 · a read that did NOT
  /// ANSWER says so and offers the retry, rather than telling a season with
  /// eleven weeks of story that nothing has happened.
  @ViewBuilder private var emptyArc: some View {
    if model.storyRead == .failed {
      let e = EmptyRoot.failedRead()
      CSEmpty(glyph: .scheduleSheet, eyebrow: "The story",
              headline: e.head, fact: e.sub,
              door: .primary("Try again") { Task { await model.reloadStory() } })
    } else {
      CSEmpty(glyph: .scheduleSheet, eyebrow: "The story",
              headline: "A season's story starts with the first posted round.",
              fact: model.seasonStory == nil ? "The story arrives with the season's first weekly snapshot." : nil,
              door: links.openRecord.map { go in .primary("Add my round", go) }
                ?? .elsewhere("The board carries every round as it lands."))
    }
  }

  // MARK: the archive — every season this league has played

  @ViewBuilder private var archive: some View {
    let seasons = model.seasonStory?.archive ?? []
    if seasons.count > 1 {
      VStack(alignment: .leading, spacing: 0) {
        CSSectionHead("Every season", count: SeasonStoryCopy.word(seasons.count))
        ForEach(seasons) { s in
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            Text("Season \(s.number.map(String.init) ?? "—")").csType(.social).foregroundStyle(cs.ink)
            Text(SeasonStoryCopy.archiveLine(s)).csType(.agateS, caps: true).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(.vertical, CSTokens.Space.s3)
          .frame(maxWidth: .infinity, alignment: .leading)
          .overlay(alignment: .bottom) { CSRule() }
          .accessibilityElement(children: .combine)
        }
      }
      .csGutter()
    }
  }
}
