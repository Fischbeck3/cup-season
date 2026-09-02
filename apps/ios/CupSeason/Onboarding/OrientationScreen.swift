// Cup Season — D82: the one orientation screen, between the golfer card and
// first Home (index.html `#obOrient` ~2883–2910, `showOrientation` ~14779).
//
// Two teachings only — the four places, and the two ways to play (the
// switcher's own words: the long game / the short game) — then one button.
// Skippable in one tap; reopenable forever from You › ⚙ › How it works
// (`GuideCopy` carries the same content). Depth stays AT the doors.
//
// Y-15 · the doors ride along. The web puts the crew step (D151) right after
// this screen — Join · Start a league · Start an event — and the phone has
// no crew step, so the league-less doors sit here, under the teaching, and
// route where they route everywhere else on the phone (`LeaguelessDoors`).
// "Take me in" is the one door D82 asks for, and it is pinned so it is never
// below the fold.
//
// Shown once per device: the flag (`CSConfig.orientedKey`) is written on the
// DECISION, not on dismiss — the first time a golfer reaches `.ready`,
// whatever the answer — so a crash mid-screen never traps anyone in it, and a
// golfer oriented by evidence today never meets it on a later, emptier day.
// (The web writes it on SHOW, inside `showOrientation`; the phone decides and
// writes in one place, `OrientedFlag.take`.) A golfer who already holds a
// league, a round or an event is oriented by evidence and never sees it, and
// neither does an invited one (D116 amends D82 for them).

import SwiftUI
import CSDesign
import CupSeasonKit

/// The orientation's copy — the web's `#obOrient` block, verbatim, with the
/// phone's doors where the doors differ (Y-05: the middle tab is labelled
/// "Post"). The "both at once" line is `GuideCopy`'s, not retyped.
enum OrientationCopy {
  struct Place: Identifiable {
    let symbol: String
    let title: String
    let sub: String
    var id: String { title }
  }
  struct Way {
    let eyebrow: String
    let title: String
    let sub: String
  }

  /// Two lines, as the web breaks them.
  static let title = "Four places.\nTwo ways to play."
  static let sub = "Thirty seconds, then you're in."
  /// The tab bar's own glyphs, so each row teaches the icon it names.
  static let places: [Place] = [
    Place(symbol: "house", title: "Home", sub: "Everything you're in, one feed"),
    Place(symbol: "flag", title: "Clubhouse", sub: "One league: table, board, pot"),
    Place(symbol: "plus.circle.fill", title: "Post", sub: "Before, during and after a round"),
    Place(symbol: "person.text.rectangle", title: "You", sub: "Your card, record and buddies"),
  ]
  static let longGame = Way(eyebrow: "The long game", title: "A league", sub: "Months. Every round counts toward a table.")
  static let shortGame = Way(eyebrow: "The short game", title: "An event", sub: "A weekend or a few weeks. Its own little trophy.")
  /// "You can run both at once. An event stands alone, or attaches to a league." — the guide's closing line.
  static var both: String { GuideCopy.sheets["games"]?.paragraphs.last ?? "" }
  static let go = "Take me in"
  /// The middle step of the exit line is the ⚙ at the top of You. As a
  /// CHARACTER it has no glyph in the text faces, so it fell through to Apple
  /// Color Emoji mid-sentence — a colour gear in a grey footer, with the
  /// `foregroundStyle` silently dropped on the way past. It is drawn as the SF
  /// Symbol the You header actually wears (`YouScreen`: `gearshape`), so the
  /// sentence points at the button by its real face and takes the tint.
  static let reopenLead = "Reopen this any time from You › "
  static let reopenGlyph = "gearshape"
  static let reopenTail = " › How it works."
  /// The same sentence in words — what VoiceOver says, and the plain-text
  /// twin for anywhere a symbol cannot be drawn.
  static let reopenSpoken = "Reopen this any time from You › Card & settings › How it works."
}

/// Once per device, and only for a golfer with nothing yet.
enum OrientedFlag {
  /// True exactly once: the flag is written on the way out, whatever the
  /// answer, so a golfer who is oriented by evidence today (a league, a
  /// round, an event) is never shown it on a later, emptier day.
  ///
  /// D116 item 3 AMENDS D82 for the invited: a pending code or claim is
  /// already carrying this golfer somewhere, and the join's own review is
  /// their teaching — the orientation would be noise in front of it. The flag
  /// is still written ("so it never fires later by surprise"), and You › ⚙ ›
  /// How it works reopens the same content whenever they want it.
  static func take(_ me: Me, defaults: UserDefaults = .standard) -> Bool {
    guard !defaults.bool(forKey: CSConfig.orientedKey) else { return false }
    defaults.set(true, forKey: CSConfig.orientedKey)
    let invited = JoinIntent.pending(defaults: defaults) != nil || ClaimIntent.pending(defaults: defaults) != nil
    guard !invited else { return false }
    return me.memberships.isEmpty && me.events.isEmpty && (me.profile?.rounds_count ?? 0) == 0
  }
}

#if DEBUG
/// `-cs_dev_open orientation`: the screen over a signed-in simulator whatever
/// the flag says; the flag itself is left alone. DEBUG only — the shipped
/// build has no such door.
enum OrientationDev {
  static let forced: Bool = {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_open"), i + 1 < a.count else { return false }
    return a[i + 1] == "orientation"
  }()
}
#endif

struct OrientationScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  /// The one way out. Called once, after any sheet or cover on this screen has come down.
  let done: () -> Void
  @State private var events = false
  @State private var leaving = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        CSPageHeader(OrientationCopy.title, sub: OrientationCopy.sub).padding(.top, 20)

        // the four places — rows, not tiles (IOS-019 rule 2); none is a door here
        VStack(spacing: 0) {
          ForEach(Array(OrientationCopy.places.enumerated()), id: \.element.id) { i, p in
            CSRow(last: i == OrientationCopy.places.count - 1) {
              YouDoorRow(glyph: glyph(p), title: p.title, sub: p.sub)
            }
          }
        }

        // the two ways to play — the long game wears ember, the short game gold (the web's colours)
        A11yStack(rowAlignment: .top, spacing: 10) {
          way(OrientationCopy.longGame, spine: cs.brand)
          way(OrientationCopy.shortGame, spine: cs.gold)
        }
        .fixedSize(horizontal: false, vertical: true)
        CSFine(OrientationCopy.both)

        // Y-15 · the doors, where the web's crew step would be
        LeaguelessDoors(links: doorLinks).padding(.top, 6)
      }
      .padding(.horizontal, 20).padding(.bottom, 24)
    }
    .csLookGround()   // D103b: bg0 with the sky behind the page header
    .safeAreaInset(edge: .bottom, spacing: 0) { foot }
    .sheet(isPresented: $events) {
      EventPickerSheet(links: EventLinks(openEvent: { id in
        // the tab shell lands the room the way it lands a tapped notification:
        // one pending route, drained once Home exists (D104)
        events = false
        PushRouter.shared.pending = .event(id)
        leave("event")
      }))
    }
    .onAppear { CSTelemetry.event("orientation_shown", ["platform": .string("ios")]) }
  }

  /// The ⊕ wears ember in the bar; it wears ember here.
  private func glyph(_ p: OrientationCopy.Place) -> Text {
    let t = Text(Image(systemName: p.symbol))
    return p.symbol == "plus.circle.fill" ? t.foregroundStyle(cs.brand) : t
  }

  private func way(_ w: OrientationCopy.Way, spine: Color) -> some View {
    CSCard(spine: spine, padding: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text(w.eyebrow).csEyebrow(spine)
        Text(w.title).font(CSFont.sentenceBold).foregroundStyle(cs.ink)
        Text(w.sub).font(CSFont.footnote).foregroundStyle(cs.mut)
      }
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .accessibilityElement(children: .combine)
  }

  /// "Take me in", pinned: the skip is one tap wherever the page is scrolled.
  private var foot: some View {
    VStack(spacing: 0) {
      CSHairline()
      VStack(spacing: 8) {
        CSButton(OrientationCopy.go, busy: leaving) { leave("in") }
        (Text(OrientationCopy.reopenLead)
         + Text(Image(systemName: OrientationCopy.reopenGlyph))
         + Text(OrientationCopy.reopenTail))
          .font(CSFont.footnote).foregroundStyle(cs.dimText)
          .multilineTextAlignment(.center).frame(maxWidth: .infinity)
          .accessibilityLabel(OrientationCopy.reopenSpoken)
      }
      .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 6)
    }
    .background(cs.bg0)
  }

  /// The doors, wired as the Clubhouse and Card & settings wire them: a lock
  /// or a join sets the preferred league and reloads the store behind it, then
  /// the tabs rise with that league on Home.
  private var doorLinks: WizardLinks {
    WizardLinks(
      onLocked: { id in store.preferredLeague = id; Task { await store.reload() }; leave("league") },
      onCancelled: { Task { await store.reload() } },
      startEvent: { events = true },
      onJoined: { id in PushAsk.shared.request(.leagueJoined); store.preferredLeague = id; Task { await store.reload() }; leave("code") })
  }

  /// One exit. `how` ∈ in · code · league · event — the web's
  /// `crew_step_done { how }` vocabulary where the doors are the same doors.
  /// Anything but "Take me in" arrives with a sheet or a cover on its way
  /// down, so the hand-off waits a beat — a screen swapped out mid-dismissal
  /// snaps.
  private func leave(_ how: String) {
    guard !leaving else { return }
    leaving = true
    CSTelemetry.event("orientation_done", ["how": .string(how), "platform": .string("ios")])
    Task {
      if how != "in" { try? await Task.sleep(for: .milliseconds(450)) }
      done()
    }
  }
}

#Preview("Orientation") {
  OrientationScreen {}.environment(SessionStore()).csTheme()
}

/// IOS-022 item 9: the two ways stack, the doors stack, the title still reads.
#Preview("Orientation · accessibility3") {
  OrientationScreen {}.environment(SessionStore())
    .environment(\.dynamicTypeSize, .accessibility3).csTheme()
}
