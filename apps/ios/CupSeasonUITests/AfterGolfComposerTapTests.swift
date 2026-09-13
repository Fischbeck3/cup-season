// The after-golf door, tapped for real — the composer it opens, and the day
// it opens on (D354).
//
// `AfterGolfAnswerTests` proves the door is there and can be tapped; it cannot
// prove what the tap OPENS, because signed out the fixture renders Home beside
// the door with no presenter to raise the composer. Signed in, the same
// `-cs_dev_home_state` fixture lands inside the real tab shell, `take` hands
// the plan to `PlanHandoff` and flips the presenter, and `PostRoundScreen`
// reads the handoff on open. This walks that path with a finger and reads the
// composer's own header: the day PLAYED, not today, and the plan's course as
// text. Signed out it skips, like every other signed-in suite here.
//
// The fixture is a fixture: no plan exists on the server and nothing is written.

import XCTest

final class AfterGolfComposerTapTests: XCTestCase {

  override func setUp() { super.setUp(); continueAfterFailure = false }

  @MainActor func testTheDoorOpensTheComposerOnTheDayPlayed() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-cs_dev_home_state", "after_golf", "-cs_dev_look", "none"]
    app.launch()
    // The tab shell is the signed-in tell: signed out the fixture renders with
    // no tab bar, and there is nothing behind the door to open.
    // The shell's bar is its own control, not a UITabBar: its doors are plain
    // buttons carrying the tab names, so one of the other tabs is the tell.
    let golfersTab = app.buttons.element(matching: NSPredicate(format: "label =[c] %@", "Golfers"))
    guard golfersTab.waitForExistence(timeout: 30) else {
      throw XCTSkip("Not signed in on this simulator — the door has no presenter behind it.")
    }
    let door = app.buttons["Add my round"].firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 25), "the after-golf door never rendered")
    for _ in 0..<40 where !door.isHittable { app.scrollViews.firstMatch.swipeUp(); _ = door.waitForExistence(timeout: 1) }
    XCTAssertTrue(door.isHittable, "the door rendered but cannot be tapped")
    door.tap()

    // The fixture's plan is `@today-2`; the composer prints its day in the
    // header exactly as `CSHeaderDate.today` does.
    let played = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    let f = DateFormatter(); f.calendar = .current; f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "EEE · MMM d"
    let expected = f.string(from: played).uppercased()
    let header = app.staticTexts[expected]
    XCTAssertTrue(header.waitForExistence(timeout: 20),
                  "the composer did not open on the day played (\(expected)); texts: \(app.staticTexts.allElementsBoundByIndex.prefix(14).map { $0.label })")
    let today = f.string(from: Date()).uppercased()
    XCTAssertFalse(today == expected || app.staticTexts[today].exists, "the composer opened on today rather than the day played")

    // The course rides as TEXT — the fixture names Papago with no catalogue id.
    let course = app.textFields.element(matching: NSPredicate(format: "value == %@", "Papago"))
    XCTAssertTrue(course.waitForExistence(timeout: 10), "the plan's course was not carried as text")

    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "after-golf-door-opened-composer"; shot.lifetime = .keepAlways; add(shot)
  }
}
