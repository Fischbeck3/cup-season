// Cup Season — the five budgets, ASSERTED, not printed (D278, IOS-053).
//
// `UI_SYSTEM` §17 names twenty-nine checks and says five of them are not
// greps: `LINT-08` (no container in a container), `LINT-15` (ten agate lines),
// `LINT-16` (one display), `LINT-17` (one gold object) and `LINT-18` (two
// ember marks). They are not greps because a VIEWPORT is assembled from a
// dozen files and a per-file grep counts the wrong thing in both directions —
// Home's fourteen agate lines arrive one apiece from four components, and the
// season page's two gold objects live in `CSRankRail.swift` and `CSFigure.swift`
// so a grep over `SeasonPage.swift` sees none.
//
// `CSBudgetProbe` has existed since Wave 0b and every wave since has reported
// the same deferral: "the counters are wired; nothing reads the total".
// THIS FILE READS THE TOTAL. It hosts a view for real, lays it out, and asserts
// on what the components actually incremented while rendering — which is the
// only counting that matches what a golfer sees.
//
// WHY A HOSTING CONTROLLER AND NOT `ImageRenderer`: preferences propagate on a
// layout pass. `ImageRenderer` produces a bitmap without giving the
// `onPreferenceChange` callback a run loop to fire on, so the budget comes back
// empty and every assertion passes vacuously — a green suite that checks
// nothing, which is worse than no suite. The harness therefore puts the view in
// a real window, forces layout, and pumps the run loop until the preference
// lands.

import Testing
import SwiftUI
import UIKit
import CSDesign
@testable import CupSeason

/// A budget that outlives the callback that filled it. `final class` at file
/// scope, not nested in `measure` — a type nested in a generic function cannot
/// be constructed, which is the third time this codebase has met that rule.
private final class CSBudgetBox: @unchecked Sendable { var value = CSBudget() }

@MainActor
enum CSBudgetHarness {
  /// The 17 Pro's own measure, because every budget in `UI_SYSTEM` is stated
  /// against a viewport and a viewport has a size.
  static let viewport = CGSize(width: 402, height: 874)

  /// Render `view` for real and hand back what it spent.
  static func measure(_ view: some View, size: CGSize = viewport) async -> CSBudget {
    let box = CSBudgetBox()
    let host = UIHostingController(
      rootView: AnyView(
        view
          .environment(\.cs, CSTokens.dark)
          .frame(width: size.width, height: size.height, alignment: .top)
          .csBudgetProbe { b in Task { @MainActor in box.value = b } }
      )
    )
    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.rootViewController = host
    window.isHidden = false
    host.view.frame = CGRect(origin: .zero, size: size)
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    /* The preference lands on a LATER turn of the main run loop, so the
       harness has to give it one. `RunLoop.run(until:)` is unavailable from an
       async context (it would block the cooperative pool), so this awaits
       instead: on a `@MainActor` async function every `await` hands the main
       run loop back, which is exactly the turn the preference needs. */
    for _ in 0..<12 {
      try? await Task.sleep(for: .milliseconds(8))
      host.view.layoutIfNeeded()
    }
    window.isHidden = true
    return box.value
  }
}

@MainActor
@Suite struct BudgetProbeTests {

  // MARK: - The harness itself, proved in BOTH directions

  /// **A test that cannot fail is not a test.** If the harness ever stops
  /// seeing what a component increments, every assertion below passes on an
  /// empty budget and the five probes are decoration. So the first two tests
  /// are about the harness: one viewport that spends, and one that does not.
  @Test func theHarnessSeesWhatAViewportSpends() async {
    let b = await CSBudgetHarness.measure(
      VStack {
        Text("CUP SEASON").csType(.display)
        Text("THE FELLAS").csType(.agate, caps: true)
        Text("WEEK 12").csType(.agate, caps: true)
      }
    )
    #expect(b.display == 1, "the probe read \(b.display) display roles — the harness is blind")
    #expect(b.agateCapsLines == 2, "the probe read \(b.agateCapsLines) agate lines — the harness is blind")
  }

  @Test func anEmptyViewportSpendsNothing() async {
    let b = await CSBudgetHarness.measure(Color.clear)
    #expect(b == CSBudget(), "an empty frame spent \(b)")
  }

  // MARK: - LINT-16 · one display per viewport

  /// The masthead's wordmark is the page's one `display`. A second one is the
  /// defect §1.5 exists to name: two things the same size means neither is the
  /// most important thing on the screen.
  @Test func lint16OneDisplayPerViewport() async {
    let ok = await CSBudgetHarness.measure(
      VStack {
        Text("CUP SEASON").csType(.display)
        Text("The fellas held the line").csType(.lead)
        Text("Papago").csType(.displayS)          // displayS is a different symbol
      }
    )
    #expect(ok.breaches.isEmpty, "\(ok.breaches)")

    let broken = await CSBudgetHarness.measure(
      VStack { Text("CUP SEASON").csType(.display); Text("PAPAGO").csType(.display) }
    )
    #expect(broken.display == 2)
    #expect(broken.breaches.contains { $0.hasPrefix("LINT-16") }, "two displays did not breach: \(broken.breaches)")
  }

  // MARK: - LINT-15 · the agate line budget

  /// Ten tracked-caps lines. Eleven is the screen the audit found: 260pt of an
  /// 874pt frame spent on LABELS before a word of content.
  @Test func lint15TenAgateLines() async {
    let ten = await CSBudgetHarness.measure(
      VStack { ForEach(0..<10, id: \.self) { i in Text("LINE \(i)").csType(.agate, caps: true) } }
    )
    #expect(ten.agateCapsLines == 10)
    #expect(ten.breaches.isEmpty, "ten is the budget, not the breach: \(ten.breaches)")

    let eleven = await CSBudgetHarness.measure(
      VStack { ForEach(0..<11, id: \.self) { i in Text("LINE \(i)").csType(.agate, caps: true) } }
    )
    #expect(eleven.breaches.contains { $0.hasPrefix("LINT-15") }, "eleven agate lines did not breach: \(eleven.breaches)")
  }

  /// **Sentence-case agate does not increment.** §1.5's counting rule is about
  /// TRACKED CAPS — the voice that reads as a label — and a slat's sub-line is
  /// agate in sentence case, which is prose.
  @Test func lint15SentenceCaseAgateIsNotALabel() async {
    let b = await CSBudgetHarness.measure(
      VStack { ForEach(0..<14, id: \.self) { i in Text("Held since week \(i)").csType(.agate) } }
    )
    #expect(b.agateCapsLines == 0, "sentence-case agate counted \(b.agateCapsLines) label lines")
    #expect(b.breaches.isEmpty)
  }

  // MARK: - LINT-08 · no container inside a container

  /// D266's hardest rule, and the one no grep can see: the nesting only exists
  /// once the three are composed, in three different files.
  @Test func lint08NoContainerInsideAContainer() async {
    let flat = await CSBudgetHarness.measure(
      HStack {
        CSPanel(unit: "PTS") { Text("27").csType(.figureM) }
        CSPanel(unit: "GAP") { Text("4").csType(.figureM) }
      }
    )
    #expect(flat.nestedContainers == 0, "two panels side by side are not nested")
    #expect(flat.breaches.isEmpty, "\(flat.breaches)")

    let nested = await CSBudgetHarness.measure(
      CSLeaf { CSPanel(unit: "PTS") { Text("27").csType(.figureM) } }
    )
    #expect(nested.breaches.contains { $0.hasPrefix("LINT-08") },
            "a panel inside a leaf did not breach: \(nested.breaches)")
  }

  // MARK: - LINT-17 / LINT-18 · the two metals

  /// One gold object per viewport, counted by HUE. The rail and the pot are the
  /// season's whitelisted pair; anything else that reaches for a second is the
  /// screen where gold stops meaning *earned*.
  @Test func lint17OneGoldObject() async {
    let one = await CSBudgetHarness.measure(
      VStack { Text("01").csType(.figureL).csBudget(gold: 1) }
    )
    #expect(one.goldObjects == 1)
    #expect(one.breaches.isEmpty)

    let two = await CSBudgetHarness.measure(
      VStack {
        Text("01").csType(.figureL).csBudget(gold: 1)
        Text("$240").csType(.figureL).csBudget(gold: 1)
      }
    )
    #expect(two.breaches.contains { $0.hasPrefix("LINT-17") }, "two gold objects did not breach: \(two.breaches)")
  }

  /// Two ember marks, counting every fill, rule, glyph, dot and word — which is
  /// the counting rule that could finally see the four screens whose only ember
  /// was the word `CLOSE`.
  @Test func lint18TwoEmberMarks() async {
    let two = await CSBudgetHarness.measure(
      VStack {
        Text("LIVE").csType(.agate, caps: true).csBudget(agateCaps: 0, ember: 1)
        Text("Add my round").csBudget(ember: 1)
      }
    )
    #expect(two.emberMarks == 2)
    #expect(two.breaches.isEmpty, "two is the budget: \(two.breaches)")

    let three = await CSBudgetHarness.measure(
      VStack {
        Text("LIVE").csBudget(ember: 1)
        Text("Add my round").csBudget(ember: 1)
        Text("CLOSE").csBudget(ember: 1)
      }
    )
    #expect(three.breaches.contains { $0.hasPrefix("LINT-18") }, "three ember marks did not breach: \(three.breaches)")
  }

  // MARK: - The objects the product actually ships

  /// The credential is the one object that appears on four surfaces, so its own
  /// budget is the one that would spread furthest if it drifted: **one display
  /// (the name), one gold object (the slot or the medallion), and no nesting.**
  @Test func theCredentialHoldsItsOwnBudget() async {
    let b = await CSBudgetHarness.measure(
      CSCredential(
        CSCredentialGolfer(
          face: CSFace.Model(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
                             marker: "saguaro"),
          name: "Galen Meyer", identity: "@galenm · Mesa, AZ · Papago",
          slot: "FOUNDER",
          figures: [.init("10.2", label: "Handicap index"),
                    .init("79", label: "Best · Papago")],
          club: "The Saguaro"),
        hasPhoto: false
      ) { CSTokens.dark.ceremony }
    )
    #expect(b.display <= 1, "the credential spent \(b.display) display roles")
    #expect(b.nestedContainers == 0, "the credential nests \(b.nestedContainers) container(s)")
    /* TWO gold marks and one of them is paired by name: the slot the golfer
       earned, and the medallion §19(i) puts on every card. That pair is the
       ruling; a THIRD would not be, and this pins the number so nothing can
       add one quietly. */
    #expect(b.goldObjects == 2 && b.goldPaired == 1,
            "the credential spent \(b.goldObjects) gold, \(b.goldPaired) paired")
    #expect(b.breaches.isEmpty, "the credential breaches its own budget: \(b.breaches)")
  }

  /// And the other direction: a card with **nothing earned** carries the
  /// medallion and no slot, so it spends exactly ONE gold mark and pairs none.
  /// If the whitelist ever started firing unconditionally it would hide a real
  /// second gold on every card in the product, so it is asserted from both
  /// sides — the same posture as the `lint` ratchet's own self-tests.
  @Test func aCardWithNothingEarnedSpendsOneGold() async {
    let b = await CSBudgetHarness.measure(
      CSCredential(
        CSCredentialGolfer(
          face: CSFace.Model(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!,
                             marker: "lonetree"),
          name: "Tash Okafor", identity: "@tash · Tempe, AZ",
          figures: [.init("14.1", label: "Handicap index")],
          club: "The Lone Tree"),
        hasPhoto: false
      ) { CSTokens.dark.ceremony }
    )
    #expect(b.goldObjects == 1 && b.goldPaired == 0,
            "an unearned card spent \(b.goldObjects) gold, \(b.goldPaired) paired")
    #expect(b.breaches.isEmpty, "\(b.breaches)")
  }
}
