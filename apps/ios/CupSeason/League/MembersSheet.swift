// Cup Season — Members & invites (`openMembersSheet`, index.html 16891–17020).
// Rows with faces; the Pro's tools as two-tap arms (never an alert): Set
// index (a sheet), Bye, Remove (setup only), Make Pro; "Marker here" — your
// marker in THIS league (D59); Add golfers; Share the invite link.

import SwiftUI
import CSDesign
import CupSeasonKit

struct MembersSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var busy: UUID?
  @State private var reason: (UUID, String)? = nil   // the armed control's confirm sentence
  @State private var setIndexFor: LeagueRoom.Member?
  @State private var markerOpen = false
  @State private var pending: [String] = []

  var body: some View {
    let n = model.members.count
    SheetFrame("Members & invites", sub: "\(n) PLAYER\(n == 1 ? "" : "S") · CODE \(model.league?.code ?? "—")") {
      VStack(spacing: 0) {
        ForEach(model.members) { m in memberRow(m) }
      }
      if markerOpen { LeagueMarkerPicker(busy: $busy) }
      if !pending.isEmpty {
        Text("Invites out").csEyebrow()
        ForEach(pending, id: \.self) { e in
          Text("✉ \(e) · WAITING").font(CSFont.footnote).foregroundStyle(cs.dimText)
            .accessibilityLabel("\(e), invite waiting")
        }
      }
      if model.isPro { CSButton("Add golfers") { dismiss(); links.addGolfers() }.padding(.top, 8) }
      if let url = model.inviteURL {
        ShareLink(item: url, subject: Text("Cup Season"), message: Text(model.inviteText)) {
          Text("Share the invite link").font(CSFont.button).frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(cs.ink).background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
        }
        .simultaneousGesture(TapGesture().onEnded { CSGrowth.log(.artifactShared, kind: "join", token: model.league?.code, league: model.league?.id) })
      }
    }
    .sheet(item: $setIndexFor) { m in SetIndexSheet(member: m).environment(model).presentationDetents([.medium]) }
    .task { pending = await model.pendingInviteEmails() }
  }

  private func memberRow(_ m: LeagueRoom.Member) -> some View {
    let isMe = m.id == model.myMember?.id
    let sub = [m.profile?.handle.map { "@\($0)" },
               m.profile?.index_current.map { "INDEX \(CSCopy.index($0))" },
               model.squadName(m.id).isEmpty ? nil : model.squadName(m.id).uppercased()].compactMap { $0 }.joined(separator: " · ")
    return VStack(alignment: .leading, spacing: 0) {
      // face + name across; "Marker here" drops under them at the accessibility sizes
      A11yStack(spacing: 12, columnSpacing: 6) {
        HStack(spacing: 12) {
          Button { dismiss(); links.openTourCard(m.profile_id) } label: {
            CSFace(photoURL: model.avatarURL[m.profile_id], marker: m.mk, size: 36).a11yHitSlop(vertical: 4, horizontal: 4)
          }
          .buttonStyle(.plain).accessibilityLabel("\(m.name)'s Tour Card")
          VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
              Text(m.name).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
              if m.isPro { Text("THE PRO").csEyebrow(cs.gold).fixedSize() }
            }
            Text(sub.isEmpty ? "GOLFER" : sub).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        Spacer(minLength: 6)
        if isMe { RoomMini("Marker here") { markerOpen.toggle() }.accessibilityHint("Your marker in this league") }
      }
      if model.isPro && !isMe {
        // the web's three confirm() bodies (16959 · 16974 · 16988) ride the arm: the reason shows while it is armed
        let removeWhy = "Their profile and rounds are untouched. They just leave this league."
        let byeWhy = "Their one season bye — it waives this month's floor. (A missed floor auto-uses it anyway; this is for a known absence.)"
        let proWhy = "You become a player. Only they can hand it back."
        // the Pro's tools wrap rather than clip (three pills never fit one line at the accessibility sizes)
        FlowRow(spacing: 6) {
          RoomMini("Set index") { setIndexFor = m }
          if model.league?.phase == "setup" {
            ArmedMini("Remove", armedLabel: "Sure? Remove", busy: busy == m.id, onArm: { reason = $0 ? (m.id, removeWhy) : nil }) {
              run(m.id) { try await model.removeMember(m.id); toast.show("Removed. The board knows."); dismiss() }
            }
            .accessibilityHint(removeWhy)
          } else {
            let mon = LeagueDates.monthLong(model.clock.today)
            ArmedMini("Bye", armedLabel: "Sure? Bye for \(String(mon.prefix(3)))", busy: busy == m.id, onArm: { reason = $0 ? (m.id, byeWhy) : nil }) {
              run(m.id) { try await model.setMemberBye(member: m.id, month: LeagueDates.firstOfMonth(model.clock.today)); toast.show("Bye granted — posted to the board"); dismiss() }
            }
            .accessibilityHint(byeWhy)
          }
          ArmedMini("Make Pro", armedLabel: "Sure? Hand it off", busy: busy == m.id, onArm: { reason = $0 ? (m.id, proWhy) : nil }) {
            // the web reloads here (16995): a role change reshapes the whole room
            run(m.id) { try await model.transferPro(to: m.id); toast.show("The shop has a new Pro"); await model.refresh(); dismiss() }
          }
          .accessibilityHint(proWhy)
        }
        .padding(.leading, typeSize.isA11y ? 0 : 48).padding(.top, 4)
        if let reason, reason.0 == m.id {
          RoomFine(reason.1).padding(.leading, typeSize.isA11y ? 0 : 48).padding(.top, 2).transition(.opacity)
        }
      }
    }
    .padding(.vertical, 10)
    .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
  }

  private func run(_ id: UUID, _ op: @escaping @MainActor () async throws -> Void) {
    busy = id
    Task { defer { busy = nil }; do { try await op() } catch { toast.show(roomError(error)) } }
  }
}

/// D59 (2d): your marker in THIS league — the override lives on `league_members`.
struct LeagueMarkerPicker: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @Binding var busy: UUID?
  var body: some View {
    let cur = model.myMember?.marker ?? model.viewer?.marker
    VStack(spacing: 8) {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: typeSize.isA11y ? 2 : 4), spacing: 8) {
        ForEach(CSMarkers.all) { mk in
          Button { set(mk.key) } label: {
            VStack(spacing: 4) {
              CSMarkerView(mk, size: 24).foregroundStyle(cur == mk.key ? cs.pos : cs.ink)
              Text(mk.name.uppercased()).font(CSFont.label).tracking(0.6).foregroundStyle(cur == mk.key ? cs.pos : cs.mut)
                .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.8)
            }
            .padding(.vertical, 10).padding(.horizontal, 4).frame(maxWidth: .infinity, minHeight: 64)
            .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cur == mk.key ? cs.pos : cs.line2, lineWidth: 1))
          }
          .buttonStyle(.plain)
          .accessibilityLabel(mk.name)
          .accessibilityAddTraits(cur == mk.key ? .isSelected : [])
        }
      }
      RoomMini("Use my profile marker") { set(nil) }
    }
    .padding(.vertical, 6)
    .disabled(busy != nil)
  }
  private func set(_ key: String?) {
    busy = model.myMember?.id
    Task {
      defer { busy = nil }
      do { try await model.setLeagueMarker(key); toast.show(key == nil ? "Back to your card marker" : "Marker set for this league") }
      catch { toast.show(roomError(error, "Could not set the marker.")) }
    }
  }
}

/// `Starter index` (17000–17019): an in-app sheet, never a prompt().
struct SetIndexSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  let member: LeagueRoom.Member
  @State private var text = ""
  @State private var busy = false
  var body: some View {
    SheetFrame("Starter index", sub: "A NUMBER TO START FROM") {
      RoomFine("A starting number for \(member.name). Once they post 3 rounds, their own scores take over.")
      CSField("e.g. 12.4", text: $text).keyboardType(.numbersAndPunctuation)
      CSButton("Set the index", busy: busy) {
        guard let idx = Double(text.replacingOccurrences(of: ",", with: ".")), idx >= -10, idx <= 54 else { toast.show("Index looks off: expected -10 to 54"); return }
        busy = true
        Task {
          defer { busy = false }
          do { try await model.setMemberIndex(member: member.id, index: idx); toast.show("Starter index set — posted to the board"); dismiss() }
          catch { toast.show(roomError(error)) }
        }
      }
      CSButton("Cancel", style: .quiet) { dismiss() }
    }
    .onAppear { if let v = member.profile?.index_current { text = String(format: "%.1f", v) } }
  }
}
