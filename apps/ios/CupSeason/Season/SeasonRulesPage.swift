// Cup Season — the rules, behind a door (D223 §7.4, D244).
//
// One page in plain sentences, not ten all-caps rows. It retires "COUNTING
// CAP", "PARTICIPATION FLOOR", "HANDICAP ALLOWANCE 95%", "VERIFICATION",
// "STRUCTURE" and "PRESET" from every user surface — the engine's nouns are
// not the golfer's. Two phrases survive because they are RULED and not
// leaked: *"scored fresh"* is D126's own wording, and the allowance sentence
// is D128(2)'s.
//
// It also carries the thing nobody else noticed was missing: LEAVE THE SEASON
// (D244). There has never been a member exit on either client — "Cancel" in
// the room hero is the Pro's — so a member who wanted out had to ask for the
// whole season to be cancelled or quietly stop posting.

import SwiftUI
import CSDesign
import CupSeasonKit

struct SeasonRulesPage: View {
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  let model: LeagueRoomModel
  let router: RoomRouter
  let links: LeagueRoomLinks
  @State private var busy = false
  @State private var shareURL: URL?
  @State private var sharing = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        sections
        whosIn
        leave
      }
      .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .csLookGround()
    .environment(model)
    .environment(router)
    .environment(\.roomLinks, links)
    .navigationTitle("The rules")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $shareURL) { url in
      ActivityView(items: [url, "\(model.league?.name ?? "Our season") on Cup Season — the season so far"])
        .presentationDetents([.medium, .large])
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(SeasonRules.title(league: model.league?.name, number: model.season?.number))
        .font(CSFont.heroSmall).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let span = SeasonRules.span(startsOn: model.clock.startsOn, endsOn: model.clock.endsOn) {
        Text(span).font(CSFont.sentence).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var sections: some View {
    VStack(alignment: .leading, spacing: 14) {
      ForEach(SeasonRules.sections(model.bylaws, clock: model.clock,
                                   pro: model.proName, members: model.members.count)) { s in
        VStack(alignment: .leading, spacing: 4) {
          Text(s.head).csEyebrow()
          Text(s.body).font(CSFont.body).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
      }
      Button { router.open(.scoringHelp) } label: {
        // F-12 · a full clause is prose, and L-29 keeps prose out of mono.
        Text("How scoring and handicaps work →").font(CSFont.subhead.weight(.medium)).foregroundStyle(cs.dawn)
          .frame(minHeight: 44).contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  /// Who is in it, how they get in, and what the season looks like from
  /// outside — the three rows the League pane carried, without its role
  /// branch. The Pro's verbs live on the page's own row (`ProVerbRow`).
  private var whosIn: some View {
    let n = model.members.count
    return VStack(alignment: .leading, spacing: 0) {
      CSSectionHead("Who's in")
      // LV-10 · row 161 retires "members" and "players": a season's list is
      // THE ROSTER, and a headcount counts GOLFERS.
      RoomCheckRow("The roster", sub: "\(n) golfer\(n == 1 ? "" : "s")") {
        Image(systemName: "flag").font(.system(size: 15, weight: .regular)).foregroundStyle(cs.ink)
      } trail: { RoomMini("View") { router.open(.members) } }
      let door = model.rosterDoor
      RoomCheckRow(door.eyebrow(members: n), sub: door.line()) {
        Image(systemName: door.isOpen ? "door.left.hand.open" : "door.left.hand.closed")
          .font(.system(size: 15, weight: .regular)).foregroundStyle(door.isOpen ? cs.brand : cs.mut)
      } trail: {
        if let url = model.inviteURL, door.isOpen {
          ShareLink(item: url, subject: Text("Cup Season"), message: Text(model.inviteText)) {
            Text("Invite").font(CSFont.monoSmall).foregroundStyle(cs.ink)
              .padding(.horizontal, 12).frame(minHeight: 36)
              .background(cs.bg2, in: Capsule()).overlay(Capsule().stroke(cs.line2, lineWidth: 1))
              .frame(minHeight: 44)
          }
          .simultaneousGesture(TapGesture().onEnded {
            CSGrowth.log(.artifactShared, kind: "join", token: model.league?.code, league: model.league?.id)
          })
        }
      }
      RoomCheckRow("Squads", sub: LeagueCopy.squadsSub(model.clock, solo: model.solo)) {
        Image(systemName: "person.2").font(.system(size: 15, weight: .regular)).foregroundStyle(cs.ink)
      } trail: { RoomMini("View") { links.openDraft() } }
      RoomCheckRow("Share the season", sub: "A public page — the standings so far, no account needed") {
        Text("🔗").font(.system(size: 15))
      } trail: {
        HStack(spacing: 6) {
          RoomMini("Link", busy: sharing) {
            if model.season == nil { toast.show("The season page opens at first tee"); return }
            sharing = true
            Task {
              defer { sharing = false }
              do { shareURL = try await model.seasonShareURL() }
              catch { toast.show(roomError(error, "Could not make the link.")) }
            }
          }
          ArmedMini("✕", armedLabel: "Sure? Turn it off") {
            guard model.season != nil else { return }
            Task {
              do { try await model.revokeSeasonShare(); toast.show("Link is off — the page stops working for everyone") }
              catch { toast.show(roomError(error, "Could not revoke.")) }
            }
          }
          .accessibilityLabel("Turn off this link — the page stops working for everyone who has it")
        }
      }
      // IOS-025 / D103a: the Pro dresses the season; members read the choice
      LookRoomSection(leagueId: model.leagueId, isPro: model.isPro)
      NoticesRoomSection()
    }
  }

  /// D244 · forward-only, member-only, two taps, and the copy says exactly
  /// what happens. The Pro is told WHY rather than shown nothing.
  @ViewBuilder private var leave: some View {
    VStack(alignment: .leading, spacing: 8) {
      CSHairline()
      Text(LeaveSeason.head).csEyebrow()
      switch model.leaveGate {
      case .offer:
        RoomFine(LeaveSeason.body)
        ArmedMini(LeaveSeason.head, armedLabel: LeaveSeason.armed, busy: busy) {
          busy = true
          Task {
            defer { busy = false }
            do {
              let r = try await model.leaveSeason()
              toast.show(r.already == true ? LeaveSeason.leftNote : LeaveSeason.done(r.league ?? model.league?.name))
            } catch {
              toast.show(roomError(error))
            }
          }
        }
      case .proMustHandOver:
        RoomFine(LeaveSeason.proNote)
      case .alreadyLeft:
        RoomFine(LeaveSeason.leftNote)
      }
    }
    .padding(.top, 8)
  }
}
