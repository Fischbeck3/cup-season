// Cup Season — the ⊕: Golf's three tenses (index.html `#view-record`
// 2958–2975; `gateLiveRound` 4206 for the real-account copy; IA P4).
//
// Post a round — after · Play now — during · Plan a tee time — before. The ⊕
// is a verb, not a place: it presents over whichever tab you were on, and
// "Post" is the 90% case — so the ⊕ opens ON the composer (IOS-004 §2) and
// this cover is one back-tap away. A golfer with a live round open lands
// here instead, where "Play now" is the door back in. The cover rises 6pt
// and fades in on `CSMotion.rise` (IOS-003 §2.7; IOS-022 item 3) — the one
// place, so whichever page opens first wears it.

import SwiftUI
import CSDesign
import CupSeasonKit

/// The doors out of the ⊕. The host wires them.
struct PostLinks {
  /// "Play now" — the tee sheet (`LiveRoundHost`).
  var openLive: () -> Void = {}
  var openReceipt: (UUID) -> Void = { _ in }
  var openPeople: () -> Void = {}
  /// The epilogue's act can land on a season's table or on a golfer's card;
  /// both are doors the shell already owns (IOS-030). D222 renamed the first —
  /// a season is Compete's object and "league" is not what it opens.
  var openCompetition: (UUID) -> Void = { _ in }
  var openTourCard: (UUID) -> Void = { _ in }
  /// "Start something" — the intent sheet. The ⊕ is the only VERB in the tab
  /// bar and it offered three ways to make a ROUND and no way to make a
  /// competition, so the funnel the brief describes — casual golf into a
  /// season — had no mouth at the place people actually press.
  var startSomething: () -> Void = {}
  /// D-offline · post a card this phone kept because the server abandoned its
  /// round before the strokes landed. It seeds the composer; it never posts.
  var postKept: (KeptCard) -> Void = { _ in }
}

struct PostCoverView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let links: PostLinks
  let startOnComposer: Bool

  /// D110 addendum: the ⊕ opens the three-door COVER (the owner tapped ⊕ and
  /// never saw the doors); only an explicit "post a round" CTA lands on the
  /// composer. The old rule (composer unless a round is live) is retired.
  init(startOnComposer: Bool = false, links: PostLinks = PostLinks()) {
    self.startOnComposer = startOnComposer; self.links = links
  }

  enum Route: Hashable { case post }

  var body: some View {
    PostCoverStack(links: links, startOnPost: (startOnComposer && !Self.forcedCover) || Self.forcedOpen, close: { dismiss() })
      .modifier(PostCoverRise())
  }

  #if DEBUG
  /// The `-cs_dev_open postround` hatch: the composer, whatever is live.
  private static var forcedOpen: Bool { ProcessInfo.processInfo.arguments.contains("postround") }
  /// `-cs_dev_post_cover`: land on the cover itself, as a golfer with a live round would.
  private static var forcedCover: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_post_cover") }
  #else
  private static let forcedOpen = false
  private static let forcedCover = false
  #endif
}

/// 6pt rise + fade, 0.26s, on the roll (IOS-003 §2.7). Reduced motion lands
/// on the rest frame at once.
private struct PostCoverRise: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var risen = false
  func body(content: Content) -> some View {
    content
      .opacity(risen ? 1 : 0)
      .offset(y: risen ? 0 : 6)
      .onAppear {
        CSMotion.run(CSMotion.rise) { risen = true }
      }
  }
}

/// The stack, with its opening page decided before the first frame — no push
/// animates on the way in when the composer is the door.
private struct PostCoverStack: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  let links: PostLinks
  let close: () -> Void
  @State private var path: NavigationPath
  @State private var showPlan = false
  @State private var kept: [KeptCard] = []

  init(links: PostLinks, startOnPost: Bool, close: @escaping () -> Void) {
    self.links = links; self.close = close
    _path = State(initialValue: startOnPost ? NavigationPath([PostCoverView.Route.post]) : NavigationPath())
  }

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          // D227 · three rows, one line of gloss each, and the ~1,000 px of
          // dead space under them closed (SV-22). The tab is Play, so the
          // cover is Play.
          CSPageHeader("Play", sub: "One live, one you just finished, or the next one — or something to play for")
          // L-40 / D110: the live game leads and wears ember (the live metal,
          // per the tokens contract); posting and planning are quiet errand
          // rows. D227 holds that clause rather than spending it: the 90 %
          // case is served by a LONG-PRESS on the ⊕, by Home's first foot door
          // and by every explicit "Add a round" CTA, all of which land on the
          // composer directly.
          VStack(spacing: 0) {
            // A-3 · **"THEY DON'T NEED THE APP" BELONGS ON THE OUTSIDE.**
            //
            // The single most useful fact in the product for a golfer whose
            // group is not on here — guests play every game, post nothing, no
            // account needed — was three scrolls inside the live setup, under
            // a headline that says the opposite. A blind reader ruled the
            // whole live game out on this row's second line ("my group has one
            // guy who still uses a flip phone"), then found the answer by
            // accident at the very end: *"That is the answer to my entire
            // question and it is buried."* One clause, on the cover.
            PostLiveHeroRow(title: "Score it live — you and the group, hole by hole",
                            sub: "One phone or four — guests need no account. It settles up at the end.") {
              close(); links.openLive()
            }
            PostOptionRow(tick: cs.rule, title: "Add a round you played",
                          sub: "Your gross and the tee — it posts to your rounds, and every season you're in reads it.") { path.append(PostCoverView.Route.post) }
            PostOptionRow(tick: cs.rule, title: "Plan a round",
                          // LV-14 · row 113: "league" is never a thing you join. The container is
                          // a SEASON.
                          sub: "Put it on the schedule; your buddies and your seasons see it.", last: true) { showPlan = true }
          }
          .padding(.top, 12)

          // **THE ROUND THIS PHONE IS STILL HOLDING.**
          //
          // A live round the server abandoned before its last strokes landed.
          // The card is kept (`LiveDisk.retire`) and this is its only door —
          // without it, the toast that promises "saved on this phone to post
          // yourself" names a surface that does not exist, and the card is as
          // lost to the golfer as it was when we deleted it.
          //
          // **It never posts itself.** `rounds` has no idempotency key, and
          // the round's scoring window has usually closed behind it — the
          // weekly clash is settled by the daily tick the morning after its
          // last day and never re-settled. A card arriving after that is not a
          // late score. So the golfer reads what was kept and decides.
          if !kept.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
              CSRule()
              Text("STILL ON THIS PHONE").csEyebrow(cs.brand).padding(.top, 14).padding(.bottom, 2)
              ForEach(Array(kept.enumerated()), id: \.element.id) { i, k in
                PostOptionRow(tick: cs.brand, title: k.line,
                              sub: k.isComplete
                                ? "Scored here, never landed. Check it and post it."
                                : "Scored here, never landed — \(18 - k.holesPlayed) holes blank.",
                              last: i == kept.count - 1) { close(); links.postKept(k) }
              }
            }
            .padding(.top, 18)
          }

          // **THE FOURTH ROW IS A DIFFERENT NOUN, SO IT IS SET APART.**
          //
          // The three rows above all produce a ROUND — live, played, planned —
          // and they share a rhythm because of it. This produces a SEASON, and
          // dropping it in as a fourth peer would have blurred what the group
          // above them is. It sits under its own rule instead, which is also
          // the honest reading order: you put golf in first, and the
          // competition is what that golf becomes.
          //
          // It is the same act as Home's `START SOMETHING` door and Compete's
          // — one sheet, `IntentSheet`, reached from wherever the thought
          // occurs. Creation starts from intent, never from configuration.
          VStack(alignment: .leading, spacing: 0) {
            CSRule()
            // L-25 · the live row already wears the ember on this screen, and
            // spending it twice spends it on nothing. What sets this row apart
            // is structural — its own rule and its own gap — not a second
            // metal competing with the one act that is genuinely happening now.
            PostOptionRow(tick: cs.rule, title: "Start something",
                          sub: "A season, a weekend, a one-off — pick who's in and what you're playing for.",
                          last: true) { close(); links.startSomething() }
          }
          .padding(.top, 20)
          // F-13 · what the long-press OPENS, named. "Your card" is the profile
          // (the exempt sense) and this opens the composer — on a screen whose
          // row above calls the same destination "Add a round you played".
          CSFine("Hold the ⊕ to go straight to Add my round.").padding(.top, 12)
        }
        .padding(20)
      }
      .background(cs.bg0)
      .navigationDestination(for: PostCoverView.Route.self) { r in
        switch r {
        case .post: PostRoundScreen(links: links, onDone: close)
        }
      }
      .csCloseButton { close() }
      .task { kept = KeptCards.rows(await LiveDisk.shared.unsynced()) }
      .sheet(isPresented: $showPlan) { DeclareRoundSheet(leagueId: store.preferredLeague) { _ in close() } }
    }
  }
}

/// D110 hero — the live door: ember spine, a breathing LIVE word, taller.
struct PostLiveHeroRow: View {
  @Environment(\.cs) private var cs
  let title: String
  let sub: String
  let action: () -> Void
  @State private var breathe = false
  var body: some View {
    Button(action: action) {
      CSRow {
        HStack(alignment: .center, spacing: 14) {
          Rectangle().fill(cs.brand).frame(width: 3).padding(.vertical, 4)
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            HStack(spacing: CSTokens.Space.s2) {
              Circle().fill(cs.brand).frame(width: 7, height: 7).opacity(breathe ? CSTokens.Alpha.a56 : 1)
              Text("Live").csType(.agate, caps: true).foregroundStyle(cs.brand)
            }
            Text(title).csType(.displayS).foregroundStyle(cs.ink).multilineTextAlignment(.leading)
            Text(sub).csType(.bodyS).foregroundStyle(cs.mut).multilineTextAlignment(.leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          // the arrow is absorbed into the row (LINT-13), and the chevron is
          // MUT: the spine, the dot and the word are already three ember marks
          // on this viewport and §1.4's budget is two
          CSGlyph(.chevron, size: .row).foregroundStyle(cs.mut)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 6)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Live: \(title). \(sub)")
    .onAppear {
      guard !UIAccessibility.isReduceMotionEnabled else { return }
      CSMotion.run(CSMotion.breath(1.1)) { breathe = true }
    }
  }
}

/// `.optcard` as a row — the tense's colour as a tick on the left, a title, a line, the `→`.
struct PostOptionRow: View {
  @Environment(\.cs) private var cs
  let tick: Color
  let title: String
  let sub: String
  var last = false
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      CSRow(last: last) {
        HStack(alignment: .center, spacing: 14) {
          Rectangle().fill(tick).frame(width: 3).padding(.vertical, 4)
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            Text(title).csType(.displayS).foregroundStyle(cs.ink).multilineTextAlignment(.leading)
            Text(sub).csType(.bodyS).foregroundStyle(cs.mut).multilineTextAlignment(.leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          CSGlyph(.chevron, size: .row).foregroundStyle(cs.mut)
        }
        .fixedSize(horizontal: false, vertical: true)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
  }
}

#Preview("the ⊕") {
  PostCoverView().environment(SessionStore()).csTheme()
}
