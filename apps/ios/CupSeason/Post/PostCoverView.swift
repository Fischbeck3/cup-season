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

  /// D330 · what the topo is drawn from. `CSContour` §2: with no home course
  /// the curves are seeded from the GOLFER's id, and with neither there is no
  /// field — Compete's own rule is "no plate rather than one seeded from
  /// nothing", and a field seeded from a constant would be the same picture on
  /// every phone, which is the opposite of what this texture is for.
  private var startSeed: String? { store.me?.profile?.id.uuidString }

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
          CSPageHeader("Play")
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
          // **D330 · IT WAS THE QUIETEST ROW ON THE SCREEN AND IT IS THE ONE
          // NOVEL THING IN THE PRODUCT** (owner: *"Start Something in Play
          // needs a bolder section, its ur flagship offering and novel Idea.
          // Maybe add the topo element"*).
          //
          // Its own rule and its own gap were the whole of the difference, and
          // set beside three rows drawn at the same size with the same tick and
          // the same chevron, that reads as a fourth peer at the bottom of a
          // list — the LAST thing an eye reaches on a screen whose first row is
          // an ember hero. A structural difference nobody sees is not one.
          //
          // **L-25 STILL HOLDS AND IS WHY THIS IS NOT A SECOND EMBER.** The
          // live row spends the metal, and spending it twice spends it on
          // nothing. The step is made of the three things that are free:
          // **SCALE** (`CSSectionHead(.display)` — `displayS` 24 over rows set
          // at 15–17, which §18 calls a 1.6× size step and a full contrast step
          // in one object, and which the system already names as the answer to
          // *"sections aren't differentiated"*), **AIR**, and **TEXTURE**.
          //
          // **AND NO RULE, WHICH IS THE COMPONENT'S OWN LAW, NOT A LIBERTY.**
          // A `.display` head "carries no rule and no box — `s5` of air above
          // it and the size step are the separation", because a hairline under
          // a 24pt line is the head competing with its own rows for the same
          // device. So the rule that used to set this apart is what came out.
          VStack(alignment: .leading, spacing: 0) {
            PostStartBlock(seed: startSeed) { close(); links.startSomething() }
          }
          .padding(.top, CSTokens.Space.s5)
          // **FULL-BLEED, AND IT IS HALF THE STEP.** The stack below is inside
          // `.padding(20)` and `s4` IS that 20, so this takes it back and the
          // band re-pays it on its own content. It runs to both screen edges;
          // nothing else on this screen does, which is the whole point.
          //
          // **IT IS TAKEN HERE AND NOT INSIDE THE BLOCK.** Applied within the
          // Button's own label it measured correctly and drew nothing — the
          // band still stopped dead on the page margin at both edges (probed:
          // x 60→1145 of 1206, which is exactly 20pt inset twice). Negative
          // padding has to be spent OUTSIDE the button that owns the layout,
          // not inside it.
          .padding(.horizontal, -CSTokens.Space.s4)
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
/// D330 · **Start something, as a section rather than a fourth row.**
///
/// The one act on this cover that does not produce a ROUND. The three above it
/// make golf; this makes the thing golf is played FOR, and it is the product's
/// novel idea — so it is the one that had to stop looking like the last item
/// in a list.
///
/// **THE TOPO IS NOT DECORATION HERE, WHICH IS THE ONLY REASON IT IS ALLOWED.**
/// `CSContour` is the signature of a COMPETITION surface — it is what Compete
/// and a season page wear at their heads, and nothing else in the product does.
/// Putting it on this door puts the destination's own face on the way in, so
/// the block is recognisably a piece of Compete sitting inside the ⊕. A field
/// chosen because it looked good would have been a wash, and D270 deleted the
/// washes.
///
/// **IT FOLLOWS THE LIVERY** (owner, on Compete: *"topo can follow themes"*).
/// Under a look the field takes the accent; on homebase it is `mut`, the
/// neutral it has always been — the same expression as `CompeteScreen`, so a
/// golfer who changes their look changes both together.
struct PostStartBlock: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let seed: String?
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      // **THE STEP IS A GROUND, BECAUSE SCALE WAS NOT AVAILABLE.**
      //
      // The first build of this made it a `.display` head with air and no rule
      // and it came out QUIETER than the three rows above — because those rows
      // are `displayS` too, so the 1.6× step §18 promises is a step over rows
      // set at 15–17 and there is no step at all over rows set at 24. Bigger
      // was not available either: §1.5 gives a viewport exactly one `display`
      // and the masthead has it.
      //
      // So the step is the one container the screen is not already using. Every
      // other row on this cover sits on `bg0` between hairlines; this is a
      // TONE BAND, full-bleed to both edges, and a solid ground running out
      // past the page margin is a different KIND of object rather than a
      // louder row. It is also what gives the topo somewhere to live: at `a24`
      // over `bg1` the isolines read as a field the block is printed on, and
      // over `bg0` between rules they read as lines drawn across the copy.
      CSBand(.tone, padding: 0) {
      HStack(alignment: .center, spacing: CSTokens.Space.s3) {
        VStack(alignment: .leading, spacing: 0) {
          CSSectionHead("Start something", weight: .display)
          // LV-14 / L-34 · Home's door for this same act glosses it *"A season,
          // a weekend, a head to head"* and this said *"a one-off"* — one door,
          // two names for what it makes. `StartIntent.peers` is the truth of
          // it (`Run a season`, `We're playing this weekend`, `Go head to
          // head`, `Play with my friends`), and a head to head is one of the
          // four while a one-off is not one of anything.
          Text("A season, a weekend, a head to head — pick who's in and what you're playing for.")
            .csType(.bodyS)
            .foregroundStyle(cs.mut)
            .multilineTextAlignment(.leading)
            .padding(.top, CSTokens.Space.s2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // MUT, not ember: the live row above already holds this screen's metal
        // and §1.4's budget is two marks a viewport (L-25).
        CSGlyph(.chevron, size: .row).foregroundStyle(cs.mut)
      }
      .fixedSize(horizontal: false, vertical: true)
      // The band takes `padding: 0` and the air is set here instead, so the
      // field below fills the WHOLE band rather than an inset box inside it.
      .padding(.vertical, CSTokens.Space.s5)
      .padding(.horizontal, CSTokens.Space.s4)
      .background(alignment: .top) {
        if let seed {
          // **`a16`, NOT COMPETE'S `a24`, AND THE DIFFERENCE IS WHAT IS DRAWN
          // OVER IT.** On Compete the field sits behind a HEAD, in air, and
          // `CompeteScreen`'s own comment records what happened the first time
          // it did not: the curves ran down through the season rows, "where a
          // 24%-opacity line crossing a 17pt name is legibility spent on
          // nothing". Here there is no way to keep the field off the copy —
          // the block is a head AND two lines of body — so the field gives way
          // instead. A texture may sit under type; it may not cross it.
          CSContour(seed: seed, tint: (la.active ? la.accent : cs.mut).opacity(CSTokens.Alpha.a16))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // **THE FIELD MAY NOT TAKE A TOUCH** — it is drawn behind a door,
            // and `allowsHitTesting(false)` is the tool for that rather than a
            // content shape. IOS-078 is the entry that says why: a
            // `contentShape(Rectangle())` over stroked isolines would turn a
            // decorative field into a solid target, and this one sits inside a
            // Button whose own shape is declared below.
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
      }
      }
      // `.clipped()` holds the field to the band (a background draws past its
      // frame), and the content shape is what the thumb gets — the band,
      // exactly, and not the isolines. D301's asymmetry, used on purpose.
      .clipped()
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityHint("Opens the ways to start a competition")
  }
}

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
