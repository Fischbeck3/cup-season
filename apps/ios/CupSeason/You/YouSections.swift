// Cup Season — the You tab's blocks (index.html 2829–2917): last round with
// (D63), the record (D67), the lifetime tiles, recent rounds with the owner's
// delete, the season strip, the league record (D4). The feedback chip and the
// founder's desk moved behind the build line in Settings (IOS-022 item 8).

import SwiftUI
import CSDesign
import CupSeasonKit

// MARK: - D63: last round with — the reunion whisper

struct LastRoundWithCard: View {
  @Environment(\.cs) private var cs
  let lrw: LastRoundWith
  let stage: ((String, UUID) -> Void)?
  let later: () -> Void
  var body: some View {
    let line = lrw.line()
    CSCard {
      A11yStack(spacing: 12, columnSpacing: 10) {
        HStack(alignment: .center, spacing: 12) {
          CSMarkerView(key: lrw.marker, size: 24).foregroundStyle(cs.ink).accessibilityHidden(true)
          VStack(alignment: .leading, spacing: 2) {
            (Text(line.lead) + Text(line.name).bold() + Text(line.tail))
              .font(CSFont.sentence).foregroundStyle(cs.ink)
            Text(lrw.sub).font(CSFont.footnote).foregroundStyle(cs.dimText)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityElement(children: .combine)
        }
        HStack(spacing: 6) {
          if let stage { MiniButton(label: "Stage it") { stage(LastRoundWith.nextSaturday(), lrw.profileId) }.accessibilityHint("Puts a round with \(line.name) on the tee sheet") }
          MiniButton(label: "Later", action: later).accessibilityLabel("Quiet for a while")
        }
      }
    }
  }
}

// MARK: - D67: the record

struct CareerRecordView: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let record: CareerRecord?
  var body: some View {
    // the silverware as one strip of gold figures, then the money as a row (IOS-019: no card in a card).
    // Y-02 · no titles, no strip — the case under it carries the one empty line.
    if let r = record, !r.items.isEmpty || r.moneyLine != nil {
      VStack(alignment: .leading, spacing: 0) {
        if !r.items.isEmpty {
          // the silverware across; one figure per line at the accessibility sizes
          CSRow(last: r.moneyLine == nil) {
            A11yStack(rowAlignment: .top, spacing: 0, columnSpacing: 8) {
              ForEach(r.items) { i in
                VStack(alignment: .leading, spacing: 2) {
                  Text(String(i.n)).font(CSFont.heroSmall).foregroundStyle(cs.gold).csTabular()   // EARNED
                  Text(i.label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.mut).lineLimit(typeSize.isA11y ? nil : 1).minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
              }
            }
          }
        }
        if let money = r.moneyLine {
          CSRow(last: true) {
            VStack(alignment: .leading, spacing: 6) {
              YouStatRow(label: money.sub, value: money.amount)
              Fine(CareerRecord.moneyNote)
            }
          }
        }
      }
    }
  }
}

// MARK: - the lifetime tiles

/// D209 · every figure is the allowance PvI off `v_rounds_ranked`, and says
/// so; D210 · no "differential", no bare float; D208 · "Leagues & events".
///
/// Y-14 · this panel and `SeasonStatsStrip` are the SAME three rows in the
/// same order under the same names — rounds, best, average — with one row of
/// its own at the bottom. They used to drift on all four axes at once: "Best
/// round" here against "Best vs your playing number" there, best-then-average
/// here against average-then-best there, a lens sub on one and none on the
/// other. One pair of stats, one grammar.
struct LifetimeTiles: View {
  let career: Career?
  /// Y-28 · the career read FAILED (not "no rounds"). A dash says why it is
  /// one, and the scope line is the opposite of why here.
  var failed: Bool = false
  var body: some View {
    VStack(spacing: 0) {
      // Y-14 · no "All time" sub: the section head above this row is called
      // "All time" (brand canon §3 — the fact belongs to one element).
      CSRow { YouStatRow(label: YouCopy.roundsPosted, value: career?.roundsText ?? "—", sub: failed ? YouCopy.didNotLoad : nil) }
      // Y-14 · both figures name their denominator. With one counting round
      // they ARE the same number, and "Rounds posted 17" above counts a
      // different set — every round on the card, scored or not.
      CSRow { YouStatRow(label: YouCopy.bestVsPlayingNumber, value: career?.bestText ?? "—", sub: career?.figureScope ?? (failed ? YouCopy.didNotLoad : nil)) }
      CSRow { YouStatRow(label: YouCopy.avgVsPlayingNumber, value: career?.avgText ?? "—", sub: career?.figureScope ?? (failed ? YouCopy.didNotLoad : nil)) }
      CSRow(last: true) { YouStatRow(label: YouCopy.leaguesAndEvents, value: career?.playedText ?? "—", sub: failed ? YouCopy.didNotLoad : YouCopy.playedIn) }
    }
  }
}

// MARK: - recent rounds, with the owner's delete (two-tap arm, never an alert)

/// Y-12 · each round is a door: the day in the glyph cell, "85 gross" as the
/// title, the nine-hole marker IN it, the engine's figure named for what it
/// is — and the `→` every door on this page wears. The × arms once and asks
/// in a line, never an alert.
///
/// Y-16 · one open-affordance for the whole tab. These rows wore a
/// `chevron.right`, the league rows an arrow and the rivalry rows nothing —
/// three grammars for "this row opens something" on one screen. `YouDoorRow`
/// already owns the arrow; every door here uses it.
struct RecentRoundsList: View {
  @Environment(\.cs) private var cs
  /// Y-12 · the photo and × glyphs grow with the text they sit beside
  @ScaledMetric(relativeTo: .footnote) private var glyphSize: CGFloat = 13
  let recent: [RoundRow]
  /// D209 · the one figure for a round — `Career.figure(for:)`; nil = card-only
  let figure: (RoundRow) -> Double?
  let open: (RoundRow) -> Void
  let delete: (RoundRow) async -> Void
  @State private var armed: UUID?
  @State private var deleting: UUID?

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(recent.enumerated()), id: \.element.id) { i, r in
        CSRow(last: i == recent.count - 1) {
          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
              YouDoorRow(glyph: Text(glyph(r)), title: title(r), sub: sub(r), action: { open(r) }) {
                HStack(spacing: 8) {
                  // the photo mark is an ATTRIBUTE of the round, not an
                  // affordance — the arrow beside it is the door
                  if r.photo_path != nil || r.photo_url != nil {
                    Image(systemName: "photo").font(.system(size: glyphSize))
                  }
                  Text("→").font(CSFont.subhead)
                }
              }
              .accessibilityLabel(spoken(r))
              .accessibilityHint("Opens the round")
              Button {
                if armed == r.id { Task { await confirmDelete(r) } } else { armed = r.id; CSHaptic.warning() }
              } label: {
                Image(systemName: "xmark").font(.system(size: glyphSize, weight: .semibold))
                  .foregroundStyle(armed == r.id ? cs.neg : cs.dimText)
                  .frame(width: 44, height: 44).contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .disabled(deleting == r.id)
              .accessibilityLabel(armed == r.id ? "Sure? Delete this round" : "Delete round")
            }
            if armed == r.id {
              VStack(alignment: .leading, spacing: 8) {
                Fine("Delete this round? It leaves your card and any league standings it counted toward.")
                HStack(spacing: 8) {
                  MiniButton(label: deleting == r.id ? "Deleting…" : "Sure? Delete", tone: cs.neg, busy: deleting == r.id) { Task { await confirmDelete(r) } }
                  MiniButton(label: "Keep") { armed = nil }
                }
              }
            }
          }
        }
      }
    }
  }

  /// "85 gross" — the number and what it is; "35 gross · 9 holes" when it is
  /// half a round. Y-15 · the nine used to live in the grey line under the
  /// title, so a 35 headlined a list of 85s and 90s and read as an 18-hole
  /// score. The Tour Card row already says it in the title ("· 9 HOLES",
  /// `TourCardSheet.swift:107`); this is the same fact in this row's own case.
  private func title(_ r: RoundRow) -> String {
    "\(r.gross.map(String.init) ?? "—") gross" + (r.holes_played == 9 ? " · 9 holes" : "")
  }
  /// "Papago GC" then, on its own line, "+2.4 vs your playing number"
  private func sub(_ r: RoundRow) -> String {
    // Y-13 · the stored label carries the upstream API's casing ("Palo Verde
    // Gc"); `RoundCopy.course` repairs the acronym and nothing else.
    let course = RoundCopy.course(r.course_label)
    let where_ = course.isEmpty ? YouCopy.unnamedCourse : course
    guard let v = figure(r) else { return where_ }
    return where_ + "\n" + RoundCopy.signed(v) + " " + YouCopy.vsPlayingNumber
  }
  /// "JUN 1" for the glyph cell; an em dash when the round carries no date,
  /// so the cell is never blank.
  private func glyph(_ r: RoundRow) -> String {
    let d = RivalryCopy.monthDay(r.played_on ?? "")
    return d.isEmpty ? "—" : d
  }
  /// Y-33 · VoiceOver spells a three-letter capital abbreviation, so the
  /// spoken twin takes the natural-case day ("June 1"), never the glyph.
  private func spoken(_ r: RoundRow) -> String {
    let label = RoundCopy.course(r.course_label)
    let course = label.isEmpty ? "a round" : label
    let day = RivalryCopy.monthDaySpoken(r.played_on ?? "")
    // Y-15 · spoken in the order it is written: the day, the score, the nine, the course
    var s = "\(day.isEmpty ? "Undated" : day), \(r.gross.map(String.init) ?? "no gross") gross\(r.holes_played == 9 ? ", 9 holes" : ""), \(course)"
    if let v = figure(r) { s += ", \(RoundCopy.signed(v)) \(YouCopy.vsPlayingNumber)" }
    return s
  }

  private func confirmDelete(_ r: RoundRow) async {
    deleting = r.id
    await delete(r)
    deleting = nil; armed = nil
  }
}

// MARK: - "This season · league"

/// Y-28 · every figure says its lens; a dash says why it is one.
struct SeasonStatsStrip: View {
  let stats: SeasonStats?
  let leagueName: String
  /// Y-28 · the season read FAILED. Without this a nil block told a golfer
  /// they "need 2 rounds" when the truth is that nothing came back.
  var failed: Bool = false
  var body: some View {
    CSSectionHead("This season · \(leagueName)")
    VStack(spacing: 0) {
      // Y-14 · the same three rows, in the same order, as "All time" above.
      // Brand canon §3 "one fact, one place": the head names the scope, so no
      // row repeats it; each row carries only what the head cannot say.
      CSRow { YouStatRow(label: YouCopy.roundsPosted, value: stats?.roundsText ?? "—", sub: failed ? YouCopy.didNotLoad : nil) }
      CSRow { YouStatRow(label: YouCopy.bestVsPlayingNumber, value: stats?.bestText ?? "—", sub: stats?.figureScope ?? (failed ? YouCopy.didNotLoad : nil)) }
      CSRow { YouStatRow(label: YouCopy.avgVsPlayingNumber, value: stats?.avgText ?? "—", sub: stats?.figureScope ?? (failed ? YouCopy.didNotLoad : nil)) }
      CSRow(last: true) { YouStatRow(label: YouCopy.indexMove, value: stats?.deltaText ?? "—", sub: stats?.deltaSub ?? (failed ? YouCopy.didNotLoad : YouCopy.needsTwoRounds)) }
    }
  }
}

// MARK: - D4: the league record

struct LeagueRecordView: View {
  @Environment(\.openLeague) private var openLeague
  let rows: [LeagueRecordRow]
  var body: some View {
    if !rows.isEmpty {
      // D177 · "League record" was the THIRD heading on this page meaning
      // "record", and the only one that was not one: it is a season-by-season
      // list of where you finished, in every league you have played.
      CSSectionHead("Every season")
      VStack(spacing: 0) {
        ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
          // Y-16 · the row is a door into the league's room in the Clubhouse
          CSRow(last: i == rows.count - 1) {
            YouDoorRow(glyph: Text(Image(systemName: "flag")), title: r.name, sub: r.sub, action: { openLeague(r.id) })
              .accessibilityLabel("\(r.name), \(r.spoken)")   // Y-33 · "Season 2", not "S E A S O N I I"
              .accessibilityHint("Opens the league in the Clubhouse")
          }
        }
      }
    }
  }
}
