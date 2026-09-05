// Cup Season — THE BOARD, and the two sections that turn a list into a door
// (IOS-032, D245, IA §10.1/§10.2).
//
// Three things live here, all of them rows the Golfers tab draws and none of
// them a screen of its own:
//
//   * `FriendsBoardSection` — the board, form first, handicap second. The
//     SERVER computes both ranks, so the two clients cannot order the same
//     board differently; the segment only chooses which rank to read.
//   * `PlayingSoonSection` — your buddies' plans, with **Ask for a seat**,
//     which writes one `rsvp` nudge to the host and NEVER a row on the tee
//     sheet (R16, D69 intact).
//   * `YouPlayWithSection` — the golfers you actually play with and have not
//     added, from `recent_partners`. The row IA §10.1 calls "Add Ravi →".
//
// L-22, and it is the reason this file is short: there is no badge, no arrow,
// no "you dropped to 5th", and nothing here counts attention. A row is a name,
// a count of rounds, and what those rounds did against that golfer's own
// number.

import SwiftUI
import CSDesign
import CupSeasonKit

// MARK: - The board

struct FriendsBoardSection: View {
  @Environment(\.cs) private var cs
  let board: FriendsBoard?
  /// L-32 · a failed read says so in one line. It does not replace the tab.
  let failed: Bool
  @Binding var lens: FriendsBoard.Lens
  let openPerson: (UUID) -> Void

  var body: some View {
    if failed {
      CSSectionHead(FriendsBoard.head.capitalized)
      CSFine(FriendsBoard.didNotLoad)
    } else if let b = board, b.rows.count > 1 {
      // A board of ONE is not a board — it is me, alone, ranked first of one,
      // and it would sit under the tab's own "No buddies yet." root, which is
      // one page saying two things (L-34).
      CSSectionHead("\(FriendsBoard.head.capitalized) · \(lens.caption(days: b.days).capitalized)")
      // two lenses, and only two (D245 clauses 1 and 2)
      HStack(spacing: 6) {
        ForEach(FriendsBoard.Lens.allCases, id: \.self) { l in
          CSMini(l.label, tone: lens == l ? cs.pos : nil, selected: lens == l) {
            lens = l
            CSHaptic.selection()
          }
        }
      }
      .padding(.bottom, 2)
      VStack(spacing: 0) {
        let rows = b.ordered(lens)
        ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
          CSRow(last: i == rows.count - 1) { row(r) }
        }
      }
      CSFine(FriendsBoard.note)
    }
  }

  private func row(_ r: FriendsBoard.Row) -> some View {
    Button { openPerson(r.profileId) } label: {
      HStack(spacing: 12) {
        Text(String(r.rank(lens))).font(CSFont.monoSmall).foregroundStyle(cs.mut)
          .frame(minWidth: 22, alignment: .trailing)
          .accessibilityHidden(true)
        CSMarkerView(key: r.marker, size: 22).foregroundStyle(cs.ink).frame(width: 26)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 2) {
          Text(r.name).font(CSFont.subhead.weight(r.isMe ? .bold : .semibold)).foregroundStyle(cs.ink)
          Text(sub(r)).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        Text(trailing(r)).font(CSFont.monoMediumBody).csTabular().foregroundStyle(cs.mut)
      }
      .frame(minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(r.rank(lens)). \(r.name), \(sub(r))")
    .accessibilityHint("Opens their card")
  }

  /// FORM says the rounds AND what they did — the denominator is part of the
  /// fact (L-01). HANDICAP says the index and how recently it was moved.
  private func sub(_ r: FriendsBoard.Row) -> String {
    switch lens {
    case .form:
      return r.formLine
    case .handicap:
      guard let on = r.lastRoundOn else { return "No rounds posted yet" }
      return "Last round \(RivalryCopy.monthDaySpoken(on))"
    }
  }

  private func trailing(_ r: FriendsBoard.Row) -> String {
    switch lens {
    // L-14 / T-07 · the BAND, never the raw figure
    case .form:     return r.band?.uppercased() ?? "—"
    case .handicap: return r.indexText
    }
  }
}

// MARK: - PLAYING SOON, and "Ask for a seat" (R16)

struct PlayingSoonSection: View {
  @Environment(\.cs) private var cs
  let plans: [ScheduledRound]
  let openRound: (UUID) -> Void
  @State private var asked = Set<UUID>()
  @State private var busy = Set<UUID>()
  private let people = PeopleService()

  /// A buddy's plan, not mine — mine is the ME strip's NEXT fact and Home's
  /// own card, and this section restating it would be the same fact twice
  /// (L-34).
  private var theirs: [ScheduledRound] { plans.filter { !$0.isMine && $0.id != nil } }

  var body: some View {
    if !theirs.isEmpty {
      CSSectionHead("Playing soon")
      VStack(spacing: 0) {
        ForEach(Array(theirs.prefix(4).enumerated()), id: \.element.id) { i, p in
          CSRow(last: i == min(theirs.count, 4) - 1) {
            HStack(spacing: 10) {
              YouDoorRow(glyph: Text(RivalryCopy.monthDay(p.play_on ?? "")),
                         title: p.who,
                         sub: planSub(p),
                         action: { p.id.map(openRound) })
              seat(p)
            }
          }
        }
      }
    }
  }

  /// A REQUEST, never a write (D69). The row says what the tap did, and it
  /// says it once — the second tap on the same plan is not a second nudge
  /// (L-20/L-21, enforced server-side too).
  @ViewBuilder private func seat(_ p: ScheduledRound) -> some View {
    if let id = p.id {
      // A golfer already in the group has the RSVP control on the round sheet;
      // offering them a seat they hold would be a door to nowhere (L-32).
      if p.tagged_me == true {
        Text("YOU’RE IN").font(CSFont.label).tracking(0.8).foregroundStyle(cs.pos)
      } else if asked.contains(id) {
        Text("ASKED").font(CSFont.label).tracking(0.8).foregroundStyle(cs.mut)
      } else {
        CSMini("Ask for a seat", busy: busy.contains(id)) { Task { await ask(p) } }
          .accessibilityHint("Sends the host a request. It does not put you on the tee sheet.")
      }
    }
  }

  /// "GOLD CANYON · 7:10A TEE" — the venue and the time, which is what a
  /// golfer deciding whether to ask actually needs.
  private func planSub(_ p: ScheduledRound) -> String {
    [p.courseShort, TeeTime.format(p.tee_time)].compactMap { $0 }
      .filter { !$0.isEmpty }.joined(separator: " · ").uppercased()
  }

  private func ask(_ p: ScheduledRound) async {
    guard let id = p.id else { return }
    busy.insert(id)
    defer { busy.remove(id) }
    do {
      let state = try await people.askForASeat(id)
      asked.insert(id)
      ToastCenter.shared.show(seatToast(state, host: p.who))
    } catch {
      ToastCenter.shared.show(SliceFormat.human(error, "Couldn’t send that."))
    }
  }

  /// Four states, four sentences, and none of them claims a seat.
  private func seatToast(_ state: String, host: String) -> String {
    switch state {
    case "already_asked": "Already asked — it’s with them."
    case "already_in":    "You’re already in that group."
    default:              "Asked. It’s up to them now."
    }
  }
}

// MARK: - YOU PLAY WITH (not buddies yet)

struct YouPlayWithSection: View {
  @Environment(\.cs) private var cs
  let people: [Person]
  let links: CSLinks
  let onAdd: (Person) async -> Void
  @State private var busy = Set<UUID>()

  /// Only the ones who are NOT buddies — the buddies list is three rows down
  /// and a name in both is one fact twice (L-34).
  private var strangers: [Person] { people.filter { $0.rel == .none } }
  /// A section, not a directory: six is enough to recognise the crew, and the
  /// search field above finds anybody this list leaves out.
  private let shown = 6

  var body: some View {
    if !strangers.isEmpty {
      CSSectionHead("You play with")
      CSFine("Golfers you have actually been out with, who are not buddies yet.")
      VStack(spacing: 0) {
        ForEach(Array(strangers.prefix(shown).enumerated()), id: \.element.id) { i, p in
          CSRow(last: i == min(strangers.count, shown) - 1) {
            PersonRow(person: p, links: links) {
              CSMini("Add \(p.name.split(separator: " ").first.map(String.init) ?? p.name)",
                     busy: busy.contains(p.id)) {
                Task {
                  busy.insert(p.id)
                  await onAdd(p)
                  busy.remove(p.id)
                }
              }
            }
          }
        }
      }
    }
  }
}

// MARK: - WERE YOU OUT THERE? (R15, D239)

/// A tag is a CLAIM WITH A STATE, and this is the state changing. It sits at
/// the head of the tab beside the buddy requests for the same reason D177 put
/// those there: a person waiting on you outranks a search box.
///
/// L-19 · confirming says "I was out there" and nothing about the score, and
/// the section says so rather than leaving it to be assumed. Declining REMOVES
/// the row — a golfer who was not there should leave no trace of somebody's
/// claim that they were.
struct OpenTagsSection: View {
  @Environment(\.cs) private var cs
  let tags: [PeopleService.OpenTag]
  let onAnswered: () async -> Void
  @State private var busy = Set<String>()
  private let people = PeopleService()

  var body: some View {
    if !tags.isEmpty {
      CSSectionHead("Were you out there?")
      VStack(spacing: 0) {
        ForEach(Array(tags.enumerated()), id: \.element.id) { i, t in
          CSRow(last: i == tags.count - 1) {
            VStack(alignment: .leading, spacing: 8) {
              Text(t.question).font(CSFont.sentence).foregroundStyle(cs.ink)
                .fixedSize(horizontal: false, vertical: true)
              HStack(spacing: 8) {
                CSMini("Yes, I was", tone: cs.pos, busy: busy.contains(t.id)) { Task { await answer(t, true) } }
                CSMini("No", busy: busy.contains(t.id)) { Task { await answer(t, false) } }
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      CSFine(HeadToHeadCopy.notAVouch)
    }
  }

  private func answer(_ t: PeopleService.OpenTag, _ yes: Bool) async {
    guard let id = t.round_id else { return }
    busy.insert(t.id)
    defer { busy.remove(t.id) }
    do {
      _ = try await people.confirmRoundPartner(id, confirm: yes)
      ToastCenter.shared.show(yes ? "Confirmed. It counts as a round together."
                                  : "Taken off. Nothing about you stays on it.")
      await onAnswered()
    } catch {
      ToastCenter.shared.show(SliceFormat.human(error, "Couldn’t save that."))
    }
  }
}
