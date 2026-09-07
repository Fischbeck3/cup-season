// Cup Season — THE PROFILE'S BLOCKS (Wave 3, `surfaces/profile.md`; IOS-047).
//
// **The You root and the person page are the same surface with four
// differences** (§8): the chrome, one primary, rivals-vs-one-rival, and
// courses-vs-shared-courses. They were two files with two grammars for the
// same six facts — which is GP-16 one level out from the card — so the blocks
// live here once and both surfaces call them.
//
// The order is §D-2's, and it is a deviation the spec argues for by name:
// **card → season → rivals → form → courses → record.** `UI_SYSTEM` §15.2
// leaves COMPETITION out of the profile entirely and `BRIEF` §10 names it as
// the second tier, so the season and the rivals come before the golf.
//
// NOTHING HERE INVENTS A FACT. Every producer is named in §13 and consumed
// unchanged: `SeasonFacts.line`, `RivalryCopy.leadLabel`, `CredentialCopy`,
// `LeagueRecord`, `TourCard.courses`.

import SwiftUI
import CSDesign
import CupSeasonKit

// MARK: - the head

/// `s5` 32 above a section, and `CSSectionHead` already carries 10 of it.
struct ProfileHead: View {
  let title: String
  var count: String?
  init(_ title: String, count: String? = nil) { self.title = title; self.count = count }
  var body: some View {
    CSSectionHead(title, count: count).padding(.top, CSTokens.Space.s5 - 10)
  }
}

// MARK: - THE SEASON (§3)

/// **The single largest hierarchy repair on the surface.** Where a golfer sits
/// in the season was not on You at all — it was a settings row four sections
/// down, under a head that named a different scope. It is now the same object
/// it is on the season board: the 44pt rail, the two-digit numeral with its
/// leading zero, the league, the movement mark and the points — so a position
/// reads identically wherever a golfer meets it, and the whole slat is one
/// door to the table.
///
/// **DEGRADE, stated.** The block draws off `me.memberships[].standing`, which
/// is the VIEWER's own. `tour_card` carries no standing for the golfer being
/// viewed, so on somebody else's page the block is absent (§6.3, L-44) rather
/// than carrying a rank nobody computed.
struct ProfileSeasonBlock: View {
  @Environment(\.cs) private var cs
  let membership: Me.Membership
  let openTable: () -> Void

  var body: some View {
    if let st = membership.standing {
      ProfileHead("The season", count: weekCount)
      // **The whole slat is the door** (§3, §D-8): a row whose entire surface
      // is the target carries no chevron and needs no second link under it,
      // and the league's name set in `name` caps at `ink` is the affordance.
      // **No face** — this is a LEAGUE's row. A disc here would seat the
      // golfer beside their own position twice on one line.
      Button(action: openTable) {
        CSSlat(rank: st.rank,
               field: st.rank == 1 ? .earned : .mine,
               face: nil,
               name: membership.name,
               sub: sub,
               movement: movement(st),
               gap: "") {
          // the trailing column repeats down a table, so it carries no rule
          // and no label — column position is already the hierarchy (§9.2)
          if let pts = st.points { CSFigure(String(Int(pts)), size: .m, label: nil) }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint("Opens the table")
      .padding(.horizontal, -CSTokens.Space.gutter)
      .padding(.top, CSTokens.Space.s3)
      // **The standing line — one agate sentence that names the rival**
      // (§9.6). It does more competitive work than any chip, and it is
      // `SeasonFacts.line`, the producer Home's ME strip already reads, so
      // the two surfaces cannot drift.
      Text(SeasonFacts.line(membership))
        .csType(.agate, caps: true).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, CSTokens.Space.s3)
    }
  }

  private var weekCount: String? {
    guard let s = membership.season, let w = s.week_no, let total = s.weeks_total else { return nil }
    return "Week \(w) of \(total)"
  }

  /// The slat's sub-line, in the product's voice and in sentence case.
  private var sub: String {
    var bits: [String] = []
    if let n = membership.season?.number, let spelled = LeagueRecord.spelledSeason(n) {
      bits.append(spelled)
    }
    if let of = membership.standing?.of, of > 0 { bits.append("\(of) golfers") }
    return bits.joined(separator: " · ")
  }

  private func movement(_ st: Me.Standing) -> CSMovement.State? {
    guard let prev = st.prev_rank else { return nil }
    if prev == st.rank { return .held }
    return prev > st.rank ? .up(prev - st.rank) : .down(st.rank - prev)
  }
}

// MARK: - FORM (§5)

/// §9.7, verbatim: **five grosses with their dates on one rule, the best in
/// `gold`.** It says "recent form" with no legend, which is what the five dots
/// and their eleven-word sentence ("a lit dot beat your playing HCP") were
/// for — and it is the only place the last five appear, against the shipped
/// two renderings in two label faces on one screen (GP-13, YRS-04).
///
/// Colour is not the only channel: the best is marked by POSITION as well —
/// it is the newest, right-most — and by the gold on both the figure and its
/// date.
struct ProfileFormRow: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let rounds: [TourCard.Recent]

  var body: some View {
    // oldest → newest, left to right, which is how a form line is read
    let shown = Array(rounds.prefix(5).reversed())
    let best = shown.compactMap(\.gross).min()
    let bestAt = best.flatMap { b in shown.firstIndex { $0.gross == b } }
    if typeSize.isA11y {
      // §16.3 · at the accessibility sizes the row becomes five rows, each
      // `date · gross` on its own rule.
      VStack(spacing: 0) {
        ForEach(Array(shown.enumerated()), id: \.offset) { i, r in
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            HStack(alignment: .firstTextBaseline) {
              CSFigure(r.gross.map(String.init) ?? "—", size: .s,
                       metal: i == bestAt ? .earned : .ink, label: nil)
              Spacer()
              Text(RivalryCopy.monthDay(r.playedOn)).csType(.agateS, caps: true)
                .foregroundStyle(i == bestAt ? cs.gold : cs.mut)
            }
            CSRule(.heavy, metal: i == bestAt ? .earned : .ink)
          }
          .padding(.vertical, CSTokens.Space.s2)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(spoken(r, best: i == bestAt))
        }
      }
      .padding(.top, CSTokens.Space.s3)
    } else {
      HStack(alignment: .top, spacing: CSTokens.Space.s3) {
        ForEach(Array(shown.enumerated()), id: \.offset) { i, r in
          column(r, best: i == bestAt)
        }
        // **Fewer than five rounds → only the rounds that exist, left-flush,
        // on a rule spanning only them.** Three blank slots make a two-round
        // golfer's row read as a five-round row with failures in it.
        if shown.count < 5 {
          ForEach(shown.count..<5, id: \.self) { _ in Color.clear.frame(height: 1) }
        }
      }
      .padding(.top, CSTokens.Space.s3)
    }
  }

  private func column(_ r: TourCard.Recent, best: Bool) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      CSFigure(r.gross.map(String.init) ?? "—", size: .s,
               metal: best ? .earned : .ink, label: nil)
      CSRule(.heavy, metal: best ? .earned : .ink)
      Text(RivalryCopy.monthDay(r.playedOn)).csType(.agateS, caps: true)
        .foregroundStyle(best ? cs.gold : cs.mut)
        .padding(.top, CSTokens.Space.s1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken(r, best: best))
  }

  private func spoken(_ r: TourCard.Recent, best: Bool) -> String {
    "\(r.gross.map(String.init) ?? "no round"), \(RivalryCopy.monthDaySpoken(r.playedOn))\(best ? ", their best" : "")"
  }
}

// MARK: - COURSES KEPT (§6)

/// The count spelled in the slot, then 44pt slats — the name in `social` 17
/// **title case, because a course is read aloud** — with the rounds under an
/// `RDS` head (§16A.3: an unlabelled number column is a defect).
///
/// **No thumbnail** (§10.2). `tour_card.courses[]` carries a name, a round
/// count and a last-played date — nothing that keys `CourseBookStore`, so
/// there is no real par or stroke index to draw a card from. A course with
/// none of the three legal images shows no thumbnail at all and the name sets
/// flush to the margin. Fake bars as ornament are less premium than nothing.
///
/// **BEST has no producer either**, and the column is absent rather than
/// filled with the golfer's overall best repeated eleven times.
struct ProfileCoursesBlock: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let courses: [TourCard.Course]
  let homeCourse: String?
  let isMe: Bool
  /// `Courses kept` on your own page; `Courses you both keep` on somebody
  /// else's, which is the social fact and the better one.
  let head: String
  @State private var expanded = false

  var body: some View {
    if !courses.isEmpty {
      ProfileHead(head, count: CredentialCopy.coursesCount(courses.count))
      if !typeSize.isA11y {
        HStack(spacing: CSTokens.Space.s3) {
          Spacer(minLength: 0)
          Text("Rds").csType(.columnS, caps: true).foregroundStyle(cs.mut)
            .frame(width: 34, alignment: .trailing)
        }
        .padding(.top, CSTokens.Space.s3)
        .accessibilityHidden(true)
      }
      VStack(spacing: 0) {
        ForEach(Array(shown.enumerated()), id: \.offset) { _, c in row(c) }
      }
      if courses.count > 3 {
        // §16A.2 · the slot already reads ELEVEN, so the door counts what is
        // left rather than saying the same number twice.
        CSDoor(.link(expanded ? "Show fewer" : "The other \(CSCopy.spelled(courses.count - 3))",
                     { expanded.toggle() }))
          .padding(.top, CSTokens.Space.s3)
      }
    }
  }

  private var shown: [TourCard.Course] { expanded ? courses : Array(courses.prefix(3)) }

  private func row(_ c: TourCard.Course) -> some View {
    VStack(spacing: 0) {
      CSRule()
      HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          Text(RoundCopy.course(c.name)).csType(.social).foregroundStyle(cs.ink)
            .lineLimit(1).truncationMode(.tail)
          let sub = CredentialCopy.courseSub(
            city: nil,
            isHome: homeCourse.map { RoundCopy.course($0) == RoundCopy.course(c.name) } ?? false,
            lastPlayed: c.lastPlayed, isMe: isMe)
          if !sub.isEmpty {
            Text(sub).csType(.agateS, caps: true).foregroundStyle(cs.mut).lineLimit(1)
          }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        Text(String(c.rounds)).csType(.column).foregroundStyle(cs.mut)
          .frame(width: typeSize.isA11y ? nil : 34, alignment: .trailing)
      }
      .frame(minHeight: 44)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(RoundCopy.course(c.name)), \(c.rounds) round\(c.rounds == 1 ? "" : "s")")
  }
}

// MARK: - RIVALS (§4)

/// One rival, as a slat: the face, the name, the meeting count, then the
/// record and the verdict right-flush.
///
/// **A losing record is set in the same ink as a winning one.** The shipped
/// app renders a trailing record in the dim tier and a leading one in mint
/// (DD-17) — it greys out your losses, and it makes colour the only channel.
/// The verdict is a WORD, which is a second channel (§16.4) and survives
/// colour blindness.
struct RivalSlat: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let face: CSFace.Model
  let name: String
  let sub: String
  let record: String
  let verdict: String
  /// M3/D18 · a christened rivalry wears its name, in gold, above the row.
  let rivalryName: String?
  let open: () -> Void

  var body: some View {
    Button(action: open) {
      VStack(spacing: 0) {
        CSRule()
        HStack(spacing: 0) {
          CSFace(face, size: .slat)
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            if let r = rivalryName, !r.isEmpty {
              Text(r).csType(.agateS, caps: true).foregroundStyle(cs.gold)
                .lineLimit(1).truncationMode(.tail)
            }
            Text(name).csType(.name).foregroundStyle(cs.ink)
              .lineLimit(1).truncationMode(.tail)
            if !sub.isEmpty {
              Text(sub).csType(.agateS, caps: false).foregroundStyle(cs.mut)
                .lineLimit(1).truncationMode(.tail)
            }
          }
          .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
          .padding(.leading, CSTokens.Space.s3)
          if !typeSize.isA11y { trailing }
        }
        .frame(minHeight: 50)
        if typeSize.isA11y {
          HStack { Spacer(); trailing }.padding(.bottom, CSTokens.Space.s2)
        }
      }
      .padding(.trailing, CSTokens.Space.gutter)
      .padding(.leading, CSTokens.Space.gutter)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(name). \(sub). \(verdict.lowercased()) \(record).")
    .accessibilityHint("Opens the record between you")
  }

  private var trailing: some View {
    VStack(alignment: .trailing, spacing: CSTokens.Space.s1) {
      // ALWAYS `ink`, winning or losing.
      CSFigure(record, size: .s, label: nil)
      Text(verdict).csType(.agateS, caps: true).foregroundStyle(cs.mut)
        .lineLimit(1).fixedSize()
    }
  }
}
