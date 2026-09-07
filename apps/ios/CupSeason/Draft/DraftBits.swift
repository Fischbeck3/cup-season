// Cup Season — draft night's parts on the dusk ground: the clock card
// (`.clock` with its accent), the squad cards (`.squad` / `.fm-squad`), the
// pool chip and row, the lock badge (`.lockbadge`) and the snake dots.

import SwiftUI
import CSDesign
import CupSeasonKit

/// `.clock` — an accent bar, k / n / m, and whatever sits under it.
struct DraftClockCard<Content: View>: View {
  @Environment(\.cs) private var cs
  let accent: Color
  let k: String
  let n: String
  let m: String
  @ViewBuilder let content: Content
  init(accent: Color, k: String, n: String, m: String, @ViewBuilder content: () -> Content) {
    self.accent = accent; self.k = k; self.n = n; self.m = m; self.content = content()
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(k).csEyebrow()
      Text(n).font(CSFont.heroSmall).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
      if !m.isEmpty { Text(m).font(CSFont.label).tracking(1.2).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true) }
      content
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(CSDusk.surface, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 3.5).padding(.vertical, 12) }
  }
}

/// `.fm-squad` — swatch · name · N PLAYERS · the members (· C for the captain) or "Empty".
struct DraftSquadCard: View {
  @Environment(\.cs) private var cs
  let squad: LeagueRoom.Squad
  let color: Color
  /// A pool player is selected — the card is a drop target (`CS.sel`).
  let selected: Bool
  let name: (UUID) -> String
  let marker: (UUID) -> String?
  let avatar: (UUID) -> URL?
  let tap: () -> Void

  var body: some View {
    Button(action: tap) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
          Text(squad.name).csType(.name).foregroundStyle(cs.ink)
          Spacer(minLength: 8)
          Text(DraftCopy.players(squad.squad_members.count)).font(CSFont.label).tracking(1.0).foregroundStyle(cs.mut)
        }
        if squad.squad_members.isEmpty {
          Text(DraftCopy.squadEmpty).csType(.bodyS).foregroundStyle(cs.mut)
        } else {
          ForEach(squad.squad_members, id: \.member_id) { seat in
            HStack(spacing: 8) {
              CSFace(.init(id: seat.member_id, marker: marker(seat.member_id), photoURL: avatar(seat.member_id)), size: .inline)
              Text(name(seat.member_id) + (squad.captain_member_id == seat.member_id ? " · C" : "")).csType(.bodyS).foregroundStyle(cs.ink)
            }
          }
        }
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(CSDusk.surface, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(selected ? cs.pos : cs.rule, lineWidth: selected ? 1.5 : 1))
      .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 3.5).padding(.vertical, 10) }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .allowsHitTesting(selected)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(a11yLabel)
    .accessibilityHint(selected ? "Puts the selected golfer on this squad" : "")
    .accessibilityRemoveTraits(selected ? [] : .isButton)
  }

  /// "The Pines, 3 players: Ed (captain), Mitch, Logan" — the card in one breath.
  private var a11yLabel: String {
    var s = squad.name + ", " + DraftCopy.players(squad.squad_members.count).lowercased()
    if squad.squad_members.isEmpty { return s + ", empty" }
    var seats: [String] = []
    for seat in squad.squad_members {
      let n = name(seat.member_id)
      seats.append(squad.captain_member_id == seat.member_id ? n + " (captain)" : n)
    }
    s += ": " + seats.joined(separator: ", ")
    return s
  }
}

/// `.squad` on the snake board — captain row (CAPT), then R1…Rn slots.
struct DraftSnakeSquadCard: View {
  @Environment(\.cs) private var cs
  let squad: LeagueRoom.Squad
  let color: Color
  let onClock: Bool
  let rounds: Int
  let picks: [DraftPickRow]
  let name: (UUID) -> String
  let index: (UUID) -> Double?

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
        Text(squad.name).csType(.name).foregroundStyle(cs.ink)
      }
      if let cap = squad.captain_member_id {
        row(name(cap), DraftCopy.captTag, bold: true)
      }
      let made = picks.sorted { $0.pick_number < $1.pick_number }
      ForEach(0..<max(0, rounds), id: \.self) { k in
        if k < made.count {
          row(name(made[k].member_id), CSCopy.index(index(made[k].member_id)), bold: false)
        } else {
          row(DraftCopy.slot(k + 1), "—", bold: false, empty: true)
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(CSDusk.surface, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(onClock ? color : cs.rule, lineWidth: onClock ? 1.5 : 1))
    .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 3.5).padding(.vertical, 10) }
  }

  private func row(_ a: String, _ b: String, bold: Bool, empty: Bool = false) -> some View {
    HStack {
      Text(a).font(bold ? CSFont.subhead.weight(.semibold) : CSFont.footnote).foregroundStyle(empty ? cs.mut : cs.ink)
      Spacer()
      Text(b).font(CSFont.label).tracking(0.8).foregroundStyle(cs.mut)
    }
    .accessibilityElement(children: .combine)
  }
}

/// A pool player as a `.mini` chip; selected = the pos ring (`CS.sel`).
struct DraftPoolChip: View {
  @Environment(\.cs) private var cs
  let id: UUID
  let name: String
  let marker: String
  let avatar: URL?
  let selected: Bool
  let tap: () -> Void
  var body: some View {
    Button(action: tap) {
      HStack(spacing: 6) {
        CSFace(.init(id: id, marker: marker, photoURL: avatar), size: .inline)
        Text(name).csType(.columnS).lineLimit(1)
      }
      .foregroundStyle(selected ? cs.pos : cs.ink)
      .padding(.horizontal, 10).frame(minHeight: 36)
      .background(CSDusk.surface, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
      .frame(minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? [.isSelected] : [])
  }
}

/// `.pool-row` — name · NUMBER · DRAFT / LOCKED.
struct DraftPoolRow: View {
  @Environment(\.cs) private var cs
  let name: String
  let idx: String
  let allowed: Bool
  let tap: () -> Void
  var body: some View {
    Button(action: tap) {
      A11yStack(spacing: 10, columnSpacing: 2) {
        Text(name).csType(.name).foregroundStyle(cs.ink)
        Spacer()
        HStack(spacing: 10) {
          Text(idx).font(CSFont.label).tracking(0.8).foregroundStyle(cs.mut)
          Text(allowed ? DraftCopy.draftTag : DraftCopy.lockedTag).font(CSFont.label).tracking(1.0).foregroundStyle(allowed ? cs.brand : cs.mut)
        }
      }
      .padding(.horizontal, 14).frame(minHeight: 48)
      .background(CSDusk.surface, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .opacity(allowed ? 1 : 0.45)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(name), \(idx)")
    .accessibilityHint(allowed ? "Puts them on a squad" : "Not your pick")
  }
}

/// `.lockbadge` — the dot and the line; pos when it's your pick, gold when it's theirs.
struct DraftLockBadge: View {
  @Environment(\.cs) private var cs
  let text: String
  let mine: Bool
  var body: some View {
    let tone = mine ? cs.pos : cs.gold
    HStack(spacing: 8) {
      Circle().fill(tone).frame(width: 7, height: 7)
      Text(text).csType(.columnS).foregroundStyle(tone)
    }
    .padding(.horizontal, 12).padding(.vertical, 8)
    .background(tone.opacity(mine ? 0.06 : 0.08), in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.updatesFrequently)
  }
}

/// `.snake` — one dot per pick: made · now · to come.
struct DraftSnakeDots: View {
  @Environment(\.cs) private var cs
  let total: Int
  let made: Int
  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 12), spacing: 5)], alignment: .leading, spacing: 5) {
      ForEach(0..<max(0, total), id: \.self) { i in
        Circle().fill(i < made ? cs.ink : i == made ? cs.brand : cs.rule).frame(width: 8, height: 8)
      }
    }
    .padding(.top, 8)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Pick \(min(made + 1, total)) of \(total)")
  }
}
