// Cup Season — the League pane (`#room-league`, index.html 3527–3552):
// Members & invites · Share the season (D57) · Squads · League rules & Pro
// Shop; plus the delete / cancel sheets (15618–15683, D71).

import SwiftUI
import CSDesign
import CupSeasonKit
import UIKit

struct LeaguePane: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  @State private var rulesOpen = false
  @State private var shareURL: URL?
  @State private var sharing = false

  var body: some View {
    let n = model.members.count
    VStack(alignment: .leading, spacing: 0) {
      Text("League").csEyebrow()
      CheckRow("Members & invites", sub: "\(n) player\(n == 1 ? "" : "s")") {
        Image(systemName: "flag").font(.system(size: 15, weight: .regular)).foregroundStyle(cs.ink)
      } trail: { CSMini("View") { router.open(.members) } }
      CheckRow("Share the season", sub: "A public page — the standings so far, no account needed") {
        Text("🔗").font(.system(size: 15))
      } trail: {
        HStack(spacing: 6) {
          CSMini("Link", busy: sharing) {
            if model.season == nil { toast.show("The season page opens at first tee"); return }
            sharing = true
            Task { defer { sharing = false }; do { shareURL = try await model.seasonShareURL() } catch { toast.show(roomError(error, "Could not make the link.")) } }
          }
          ArmedMini("✕", armedLabel: "Sure? Turn it off") {
            guard model.season != nil else { return }
            Task { do { try await model.revokeSeasonShare(); toast.show("Link is off — the page stops working for everyone") } catch { toast.show(roomError(error, "Could not revoke.")) } }
          }
          .accessibilityLabel("Turn off this link — the page stops working for everyone who has it")
        }
      }
      CheckRow("Squads", sub: LeagueCopy.squadsSub(model.clock, solo: model.solo)) {
        Image(systemName: "person.2").font(.system(size: 15, weight: .regular)).foregroundStyle(cs.ink)
      } trail: { CSMini("View") { links.openDraft() } }

      DisclosureGroup(isExpanded: $rulesOpen) {
        VStack(alignment: .leading, spacing: 10) {
          Text("The bylaws · locked at first tee").csEyebrow().padding(.top, 10)
          BylawsCard()
          Text("The Pro Shop").csEyebrow().padding(.top, 6)
          CSCard {
            VStack(alignment: .leading, spacing: 8) {
              Text("Pro Shop").font(CSFont.title).foregroundStyle(cs.ink)
              Text("CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE").font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText)
              ForEach(["Custom rules, every dial unlocked", "Live draft night with pick timer", "Trades & waiver wire", "Multi-season history & records"], id: \.self) { s in
                HStack(spacing: 8) {
                  Text("SOON").font(CSFont.label).tracking(1.0).foregroundStyle(cs.brand)
                    .padding(.horizontal, 6).padding(.vertical, 2).overlay(Capsule().stroke(cs.brand.opacity(0.6), lineWidth: 1))
                  Text(s).font(CSFont.subhead).foregroundStyle(cs.mut)
                }
              }
              Text("Coming at launch").font(CSFont.button).foregroundStyle(cs.dimText).frame(maxWidth: .infinity, minHeight: 50)
                .background(cs.bg2.opacity(0.55), in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
                .accessibilityLabel("Coming at launch")
            }
          }
        }
      } label: {
        Text("League rules & Pro Shop").csEyebrow().frame(minHeight: 44)
      }
      .tint(cs.mut)
      .padding(.top, 4)
    }
    .sheet(item: $shareURL) { url in
      ActivityView(items: [url, "\(model.league?.name ?? "Our league") on Cup Season — the season so far"]).presentationDetents([.medium, .large])
    }
  }
}

extension URL: @retroactive Identifiable { public var id: String { absoluteString } }

/// The system share sheet for a link minted a moment ago.
struct ActivityView: UIViewControllerRepresentable {
  let items: [Any]
  func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
  func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

/// D71 — "Cancel <name>? · THE SEASON IS UNDER WAY" (15628–15646).
struct CancelLeagueSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  @State private var busy = false
  var body: some View {
    let nm = model.league?.name ?? "the league"
    SheetFrame("Cancel \(nm)?", sub: "THE SEASON IS UNDER WAY") {
      Fine("A free league cancels now. If there's a buy-in, every member must approve and each gets their buy-in back. Either way the league, its board and pot go — but every posted round stays on its golfer's card.")
      Button {
        busy = true
        Task {
          defer { busy = false }
          do {
            let r = try await model.requestCancel()
            dismiss()
            if r == "done" { toast.show("\(nm) cancelled. Every round stays on its golfer."); links.leagueGone() }
            else { toast.show("Cancellation requested — every member must approve.") }
          } catch { toast.show(roomError(error)) }
        }
      } label: {
        ZStack { Text("Start the cancellation").font(CSFont.button).opacity(busy ? 0 : 1); if busy { ProgressView().tint(cs.bg0) } }
          .frame(maxWidth: .infinity, minHeight: 50).foregroundStyle(cs.bg0)
          .background(cs.neg, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      }
      .buttonStyle(.plain).disabled(busy)
      CSButton("Keep it", style: .quiet) { dismiss() }
    }
  }
}

/// Pre-tee delete (15648–15683): plain when alone, the typed-name gate when others are in.
struct DeleteLeagueSheet: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(\.roomLinks) private var links
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs
  let others: Int
  @State private var typed = ""
  @State private var busy = false
  var body: some View {
    let nm = model.league?.name ?? "the league"
    SheetFrame("Delete \(nm)?", sub: others == 0 ? "ONLY POSSIBLE BEFORE THE FIRST TEE" : "THIS TAKES EVERYONE’S SEAT") {
      if others == 0 {
        Fine("It's just you in it — the league, its board and settings go completely. Rounds stay on your golfer card.")
      } else {
        Fine("This deletes \(nm) for everyone in it: members, board, pot sheet, squads. Rounds stay on every golfer's profile. Type the league name to confirm.")
        CSField(nm, text: $typed, font: CSFont.body)
      }
      Button {
        if others > 0, typed.trimmingCharacters(in: .whitespaces).lowercased() != nm.trimmingCharacters(in: .whitespaces).lowercased() {
          toast.show("Name didn’t match: nothing deleted"); return
        }
        busy = true
        Task {
          defer { busy = false }
          do { try await model.deleteLeague(); dismiss(); toast.show("\(nm) deleted. Every round stays on its golfer."); links.leagueGone() }
          catch { toast.show(roomError(error)) }
        }
      } label: {
        ZStack { Text(others == 0 ? "Delete the league" : "Delete for everyone").font(CSFont.button).opacity(busy ? 0 : 1); if busy { ProgressView().tint(cs.bg0) } }
          .frame(maxWidth: .infinity, minHeight: 50).foregroundStyle(cs.bg0)
          .background(cs.neg, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      }
      .buttonStyle(.plain).disabled(busy)
      CSButton("Keep it", style: .quiet) { dismiss() }
    }
  }
}
