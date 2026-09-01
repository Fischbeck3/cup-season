// Cup Season — a shared Tour Card, opened from a link (D188, IOS-028 E8).
//
// `?share=` is a Universal Link now, and this is the reason it is allowed to
// be: opening the app to Home from a card link would be worse than opening
// Safari, which at least shows the card and takes the tap. The card renders
// here in the SAME object the owner sees — `CredentialCard`, the brand's fixed
// dark face (D30) — so a card looks identical from the outside and the inside.
//
// Anon-safe by construction: `share_info` is one of the twelve public
// endpoints, so a signed-OUT phone still sees the card. It only needs an
// account to press the button, and the token waits in `ShareIntent` until
// there is one.

import SwiftUI
import SafariServices
import CSDesign
import CupSeasonKit

extension Notification.Name {
  /// D188 · a `?share=` Universal Link landed. Raised by `onOpenURL`, consumed
  /// by the tab shell, which owns every sheet (IOS-002 §2).
  static let csOpenSharedCard = Notification.Name("cs.openSharedCard")
}

struct SharedCardSheet: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let token: UUID
  /// D188 · the golfer tapped "Add me on Cup Season" while signed out and has
  /// since made a card. Do the thing they already asked for rather than making
  /// them ask twice — the same resumption the web does.
  var autoAdd = false

  @State private var card: SharedCard?
  @State private var failed = false
  /// D188 · the AASA cannot inspect a token, so claiming `?share=` claims all
  /// four kinds. A round, settlement or recap is a LIVE link this build does
  /// not draw — it goes to its own good web page, in-app, rather than being
  /// called dead. Without this, adding the Universal Link would have broken
  /// three link types that work today.
  @State private var web: URL?
  @State private var busy = false
  /// nil until answered; then "friend" / "requested" / "self".
  @State private var outcome: String?
  private let repo = SharedCardRepository()

  var body: some View {
    Group {
      if let card {
        loaded(card)
      } else if let web {
        SafariSheet(url: web)
      } else if failed {
        // D57's law from the reader's side: a dead token is not an error the
        // reader caused, and it is never told apart from a revoked one.
        SliceSheet(title: "Cup Season", sub: "THIS LINK IS DEAD") {
          Fine("Whoever sent it can share a fresh one from their card.")
          CSButton("Close", style: .quiet) { dismiss() }.padding(.top, 8)
        }
      } else {
        SliceSheet(title: "Cup Season", sub: "OPENING THE CARD…") { Fine("Pulling the card…") }
      }
    }
    .task { await load() }
  }

  private func load() async {
    switch await repo.load(token) {
    case .card(let c): card = c
    case .web: web = SharedCardRepository.webURL(token)
    case .dead: failed = true
    }
    // consumed on every branch: a token must not follow the golfer around,
    // dead or handed off
    ShareIntent.clear()
    if autoAdd {
      ShareIntent.clearAdd()          // cleared BEFORE the attempt, so a failure cannot loop
      if card != nil, store.session != nil { await add() }
    }
  }

  private func loaded(_ c: SharedCard) -> some View {
    SliceSheet(title: c.name, sub: c.handle.map { "@" + $0.uppercased() } ?? "ON CUP SEASON") {
      CredentialCard(photoURL: c.photoURL(token: token), marker: c.marker, name: c.name,
                     meta: c.metaLine,
                     indexCurrent: c.indexCurrent, rounds: c.rounds,
                     trophyLines: c.trophyLines(), form: FormRow.from(beats: c.beats),
                     anchor: { EmptyView() }, extra: { EmptyView() })

      buddyAction(c)

      Text("Career").csEyebrow().padding(.top, 8)
      VStack(spacing: 0) {
        MathRow(label: "Rounds", value: String(c.rounds))
        MathRow(label: "Best diff", value: c.bestDiff.map(RoundCopy.f1) ?? "—")
        if let hc = c.homeCourse, !hc.isEmpty { MathRow(label: "Home course", value: hc) }
      }
      // The number is absent when the server withheld it (discoverable =
      // 'friends', viewer is not a buddy). Say so rather than leave a hole —
      // "no index" reads as "no golfer" otherwise.
      if c.indexCurrent == nil {
        Fine("Their handicap index is only shown to their buddies.").padding(.top, 6)
      }
    }
  }

  @ViewBuilder private func buddyAction(_ c: SharedCard) -> some View {
    if let outcome {
      Text(outcome == "friend" ? "Golf buddies ✓" : outcome == "self" ? "This is your card" : "Request sent ✓")
        .font(CSFont.label).tracking(0.8)
        .foregroundStyle(outcome == "self" ? cs.mut : cs.pos)
        .padding(.top, 10)
    } else if store.session == nil {
      // Signed out is the COMMON case on a shared link, not an error. The
      // token is already stored; the door is the next step and the request
      // lands the moment a golfer card exists.
      VStack(alignment: .leading, spacing: 6) {
        CSButton("Add me on Cup Season") { ShareIntent.storeAdd(token); dismiss() }
        Fine("You'll make your golfer card first — name, marker, number.")
      }
      .padding(.top, 10)
    } else if store.session?.user.id != nil {
      CSButton("Add \(c.name.split(separator: " ").first.map(String.init) ?? "them") on Cup Season", busy: busy) {
        Task { await add() }
      }
      .padding(.top, 10)
    }
  }

  private func add() async {
    busy = true
    defer { busy = false }
    do { outcome = try await repo.addBuddy(token) }
    catch { ToastCenter.shared.show(SliceFormat.human(error, "Could not send that.")) }
  }
}


/// `SFSafariViewController` — the in-app browser. Deliberately NOT
/// `UIApplication.open`: this app CLAIMS `?share=`, so opening one of its own
/// Universal Links would route straight back here and loop. Safari-in-app
/// renders the page without re-entering the link handler.
struct SafariSheet: UIViewControllerRepresentable {
  let url: URL
  func makeUIViewController(context: Context) -> SFSafariViewController {
    let c = SFSafariViewController.Configuration()
    c.entersReaderIfAvailable = false
    return SFSafariViewController(url: url, configuration: c)
  }
  func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
