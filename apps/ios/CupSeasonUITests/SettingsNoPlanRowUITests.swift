import XCTest

/// D411 · Settings says nothing about a plan. The "Membership" eyebrow, its
/// PLAN · FREE row and the line under it read as the free tier of a
/// subscription the product does not have, so they left both clients with
/// nothing in their place. The pane is a plain stack, so everything on it is in
/// the tree whether or not it is on screen; the positive anchors make sure the
/// pane really rendered before the absences are believed.
final class SettingsNoPlanRowUITests: N2UITestCase {
  @MainActor func testSettingsHasNoPlanRow() {
    let app = launch("season-live", "settings", extra: ["-cs_dev_settings_pane", "1"])
    _ = root(app, "settings")
    let palette = app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", "Palette")).firstMatch
    XCTAssertTrue(palette.waitForExistence(timeout: 15), "the Settings pane rendered")
    let courses = app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", "Courses on your phone")).firstMatch
    for _ in 0..<8 where !(courses.exists && courses.isHittable) { app.swipeUp() }
    XCTAssertTrue(courses.exists && courses.isHittable, "the courses door follows the look dials")

    for gone in ["Membership", "PLAN", "FREE"] {
      XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", gone)).firstMatch.exists,
                     "Settings no longer shows \(gone)")
    }
    XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Everything is free")).firstMatch.exists,
                   "the free line went with the plan row")
    attach(app, "d411-settings-no-plan-row")
  }
}
