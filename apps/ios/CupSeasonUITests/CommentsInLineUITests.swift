import XCTest

/// D405 · comments live in line under the round they are on, and say whose round
/// it is. Over the synthetic world: Home shows the newest comment under a round,
/// its comment door opens the conversation in place (no sheet, no new page), one
/// thread is open at a time, a comment sent appears at once, and nothing in the
/// conversation says Follow.
final class CommentsInLineUITests: N2UITestCase {
  /// Home, scrolled until `element` can be tapped
  @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication, tries: Int = 10) {
    for _ in 0..<tries where !(element.exists && element.isHittable) { app.swipeUp() }
  }

  /// the composer the golfer can reach now. With the round's page up over Home there are two in the tree (the page's,
  /// and the one in line beneath it); only the page's can be hit
  @MainActor private func reachableDraft(_ app: XCUIApplication) -> XCUIElement? {
    app.textFields.matching(identifier: "round.comment.draft").allElementsBoundByIndex.first { $0.exists && $0.isHittable }
  }

  @MainActor private func reachableSend(_ app: XCUIApplication) -> XCUIElement? {
    app.buttons.matching(identifier: "round.comment.send").allElementsBoundByIndex.first { $0.exists && $0.isHittable }
  }

  /// the card (the round's own button) a thing sits under: the nearest one above it, scrolling up to reach it
  @MainActor private func cardAbove(_ element: XCUIElement, in app: XCUIApplication) -> XCUIElement? {
    let cards = app.buttons.matching(NSPredicate(format: "identifier MATCHES %@", "home\\.round\\.[0-9A-Fa-f-]{36}"))
    var card: XCUIElement?
    for _ in 0..<6 {
      let above = cards.allElementsBoundByIndex.filter { $0.exists && $0.frame.minY < element.frame.minY }
      card = above.max { $0.frame.minY < $1.frame.minY }
      if let c = card, c.isHittable { break }
      app.swipeDown()
    }
    return card
  }

  /// the round's page, when one is up (its title is the page's own; Home's markers stay in the tree under a sheet)
  @MainActor private func roundPageIsUp(_ app: XCUIApplication) -> Bool {
    app.staticTexts["round.title"].exists
  }

  @MainActor func testHomeShowsTheNewestCommentAndOpensTheThreadInPlace() {
    let app = launch("season-live", "home")
    _ = root(app, "home")
    let preview = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "home.round.preview.")).firstMatch
    XCTAssertTrue(preview.waitForExistence(timeout: 20), "a round with comments shows its newest one under the card")
    XCTAssertTrue(preview.label.hasPrefix("Latest comment. "), preview.label)
    XCTAssertTrue(preview.label.contains(": "), "it says who said it: \(preview.label)")
    // this round's own newest comment: it is the one that must come back when its thread folds
    let previewId = preview.identifier
    reveal(preview, in: app)
    attach(app, "d405-home-collapsed")

    // pressing it opens the conversation IN PLACE: no round page opens, Home is still the screen, and the
    // newest comment is in the thread now, not also under the card
    preview.tap()
    let thread = app.descendants(matching: .any)["home.round.thread"].firstMatch
    XCTAssertTrue(thread.waitForExistence(timeout: 10), "the thread opened under the round")
    XCTAssertFalse(roundPageIsUp(app), "no round page opened: the conversation is in place")
    XCTAssertTrue(app.descendants(matching: .any)["cs.screen.home"].exists, "Home is still the page")
    let draft = app.textFields["round.comment.draft"]
    XCTAssertTrue(draft.waitForExistence(timeout: 10), "the composer sits at the foot of the thread")
    let wrote = draft.placeholderValue ?? ""
    XCTAssertTrue(wrote.hasPrefix("Comment on ") && wrote.hasSuffix("…"), "the composer says what it is on: \(wrote)")
    XCTAssertTrue(wrote.contains("’s "), "and whose round: \(wrote)")
    XCTAssertFalse(app.buttons[previewId].exists, "an open thread has its newest comment in it, not also under the card")
    attach(app, "d405-home-open")

    // the door is a toggle: pressing it folds the thread away, and THIS round's newest comment is back under it
    let open = app.buttons.matching(NSPredicate(format: "identifier == %@ AND selected == true", "home.round.comments")).firstMatch
    XCTAssertTrue(open.waitForExistence(timeout: 5), "the open conversation's door says it is open")
    open.tap()
    XCTAssertTrue(app.buttons[previewId].waitForExistence(timeout: 10), "the round whose thread folded shows its own newest comment again")
    XCTAssertFalse(app.textFields["round.comment.draft"].exists, "the thread folded")
    XCTAssertFalse(roundPageIsUp(app), "folding never opens the round's page")
  }

  @MainActor func testACommentSentInLineAppearsAtOnceAndJoinsTheConversation() {
    let app = launch("season-live", "home")
    _ = root(app, "home")
    let door = app.buttons["home.round.comments"].firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 20))
    reveal(door, in: app)
    door.tap()
    let draft = app.textFields["round.comment.draft"]
    XCTAssertTrue(draft.waitForExistence(timeout: 10))
    app.tapToType(draft)
    draft.typeText("Level par on the back?")
    app.buttons["round.comment.send"].tap()
    XCTAssertTrue(app.staticTexts["Level par on the back?"].waitForExistence(timeout: 10), "the comment appears in line")
    XCTAssertFalse(roundPageIsUp(app), "and no round page opened to hold it: Home is still the page")
    XCTAssertTrue(app.descendants(matching: .any)["cs.screen.home"].exists)
    // commenting is joining: what the golfer will hear about changed with it
    XCTAssertTrue(app.staticTexts["Updates from this conversation are on."].waitForExistence(timeout: 10),
                  "commenting turned this conversation's notices on")
    attach(app, "d405-home-sent")
  }

  /// one conversation, more than one view of it: the words typed under the round are the same words on the
  /// round's own page, and a comment sent there leaves nothing to send again when the page closes (the thread in
  /// line used to keep the words, look unsent, and a second Send was a second comment)
  @MainActor func testADraftIsOneDraftWhereverTheConversationIsOpenedFrom() {
    let app = launch("season-live", "home")
    _ = root(app, "home")
    let door = app.buttons["home.round.comments"].firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 20))
    reveal(door, in: app)
    door.tap()
    let inLine = app.textFields["round.comment.draft"]
    XCTAssertTrue(inLine.waitForExistence(timeout: 10))
    app.tapToType(inLine)
    inLine.typeText("Same words, both places")
    let keyboard = app.buttons["Close keyboard"].firstMatch
    if keyboard.exists { keyboard.tap() }

    // the card the thread sits under opens the round's page
    guard let card = cardAbove(inLine, in: app) else { return XCTFail("the round's card, above its thread, was not found") }
    card.tap()
    XCTAssertTrue(app.staticTexts["round.title"].waitForExistence(timeout: 15), "the round's page opened")
    for _ in 0..<8 where reachableDraft(app) == nil { app.swipeUp() }
    guard let onThePage = reachableDraft(app) else { return XCTFail("the page's composer could not be reached") }
    XCTAssertEqual(onThePage.value as? String, "Same words, both places", "the words typed in line are the words on the page")
    attach(app, "d405-draft-on-the-page")

    // sent from the page: it lands there, and the page closes onto a thread with nothing left to send
    guard let send = reachableSend(app) else { return XCTFail("the page's Send could not be reached") }
    send.tap()
    XCTAssertTrue(app.staticTexts["Same words, both places"].firstMatch.waitForExistence(timeout: 10), "the comment landed on the page")
    app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Close")).firstMatch.tap()
    XCTAssertTrue(app.staticTexts["round.title"].waitForNonExistence(timeout: 10), "the page closed")
    let after = app.textFields["round.comment.draft"].firstMatch
    XCTAssertTrue(after.waitForExistence(timeout: 10), "the thread in line is still open")
    // an empty field answers with nothing, or with its prompt
    let held = after.value as? String ?? ""
    XCTAssertTrue(held.isEmpty || held == after.placeholderValue,
                  "the composer in line is empty: its words went with the comment (it holds \(held))")
    XCTAssertTrue(app.staticTexts["Same words, both places"].firstMatch.waitForExistence(timeout: 10),
                  "and the thread in line shows the comment that was sent from the page")
    attach(app, "d405-draft-after-the-page")
  }

  /// the door under a round follows its conversation, whichever view spoke last: a comment sent on the round's own
  /// page, with the thread in line closed, is in the door's count and the newest-comment line when the page closes
  @MainActor func testACommentSentOnTheRoundsPageUpdatesTheDoorUnderIt() {
    let app = launch("season-live", "home")
    _ = root(app, "home")
    let door = app.buttons["home.round.comments"].firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 20))
    reveal(door, in: app)
    let had = Int(door.label.split(separator: " ").first ?? "") ?? 0
    guard let card = cardAbove(door, in: app) else { return XCTFail("the round's card, above its door, was not found") }
    card.tap()
    XCTAssertTrue(app.staticTexts["round.title"].waitForExistence(timeout: 15), "the round's page opened")
    for _ in 0..<8 where reachableDraft(app) == nil { app.swipeUp() }
    guard let onThePage = reachableDraft(app) else { return XCTFail("the page's composer could not be reached") }
    app.tapToType(onThePage)
    onThePage.typeText("The door follows")
    guard let send = reachableSend(app) else { return XCTFail("the page's Send could not be reached") }
    send.tap()
    XCTAssertTrue(app.staticTexts["The door follows"].firstMatch.waitForExistence(timeout: 10), "the comment landed on the page")
    app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Close")).firstMatch.tap()
    XCTAssertTrue(app.staticTexts["round.title"].waitForNonExistence(timeout: 10), "the page closed")
    // the thread in line was never opened: the door, and the line under the card, say what was just sent
    let now = had + 1
    let said = "\(now) comment\(now == 1 ? "" : "s")"
    XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier == %@ AND label == %@", "home.round.comments", said)).firstMatch
      .waitForExistence(timeout: 10), "the door under the round counts the comment sent on its page: \(said)")
    XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "home.round.preview.", "The door follows"))
      .firstMatch.waitForExistence(timeout: 10), "and the newest comment under the card is the one just sent")
    attach(app, "d405-door-follows-the-page")
  }

  /// a comment the server refuses keeps its words and says so, and says so again when the thread is opened again
  /// (a thread folded while its comment was on the way has no screen to say it on)
  @MainActor func testARefusedCommentKeepsItsWordsAndTheRefusalWithThem() {
    let app = launch("season-live", "home")
    _ = root(app, "home")
    let door = app.buttons["home.round.comments"].firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 20))
    reveal(door, in: app)
    door.tap()
    let draft = app.textFields["round.comment.draft"]
    XCTAssertTrue(draft.waitForExistence(timeout: 10))
    app.tapToType(draft)
    draft.typeText("[refuse] not today")
    app.buttons["round.comment.send"].tap()
    let refusal = app.staticTexts["round.comment.error"]
    XCTAssertTrue(refusal.waitForExistence(timeout: 10), "a refused comment says so")
    XCTAssertTrue(refusal.label.lowercased().contains("try again in a minute"), "it says why: \(refusal.label)")
    XCTAssertEqual(draft.value as? String, "[refuse] not today", "and the words are still in the box")

    // folded and opened again: the words and the refusal are still with the conversation
    let open = app.buttons.matching(NSPredicate(format: "identifier == %@ AND selected == true", "home.round.comments")).firstMatch
    XCTAssertTrue(open.waitForExistence(timeout: 5))
    open.tap()
    XCTAssertFalse(app.textFields["round.comment.draft"].exists, "the thread folded")
    reveal(door, in: app)
    door.tap()
    XCTAssertTrue(app.staticTexts["round.comment.error"].waitForExistence(timeout: 10), "the refusal is still with the words")
    XCTAssertEqual(app.textFields["round.comment.draft"].value as? String, "[refuse] not today")
    attach(app, "d405-refused-comment")
  }

  /// the case the refusal is kept for: the thread is folded while its comment is still on the way, and the refusal
  /// comes back to a screen that is no longer there. It is waiting with the words when the thread opens again.
  @MainActor func testARefusalThatArrivesAfterTheThreadFoldedIsWaitingWhenItOpens() {
    let app = launch("season-live", "home")
    _ = root(app, "home")
    let door = app.buttons["home.round.comments"].firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 20))
    reveal(door, in: app)
    door.tap()
    let draft = app.textFields["round.comment.draft"]
    XCTAssertTrue(draft.waitForExistence(timeout: 10))
    app.tapToType(draft)
    draft.typeText("[slow][refuse] folded first")
    app.buttons["round.comment.send"].tap()
    // folded while it is on the way (the synthetic refusal is three seconds late)
    let open = app.buttons.matching(NSPredicate(format: "identifier == %@ AND selected == true", "home.round.comments")).firstMatch
    XCTAssertTrue(open.waitForExistence(timeout: 5))
    open.tap()
    XCTAssertFalse(app.textFields["round.comment.draft"].exists, "the thread folded")
    sleep(5)
    XCTAssertFalse(app.staticTexts["round.comment.error"].exists, "nothing on screen to say it on")
    reveal(door, in: app)
    door.tap()
    XCTAssertTrue(app.staticTexts["round.comment.error"].waitForExistence(timeout: 10), "the refusal that came back to a folded thread is waiting")
    XCTAssertEqual(app.textFields["round.comment.draft"].value as? String, "[slow][refuse] folded first", "with the words it was refused for")
    attach(app, "d405-refusal-after-fold")
  }

  @MainActor func testTheConversationNeverSaysFollowAndOffersOneSetting() {
    let app = launch("season-live", "home")
    _ = root(app, "home")
    let door = app.buttons["home.round.comments"].firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 20))
    reveal(door, in: app)
    door.tap()
    let options = app.buttons["round.comment.options"].firstMatch
    XCTAssertTrue(options.waitForExistence(timeout: 10))
    XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'follow'")).count, 0, "no control reads Follow")
    options.tap()
    for label in ["Every comment", "Replies to me", "Nothing"] {
      XCTAssertTrue(app.buttons[label].waitForExistence(timeout: 5), "the menu offers \(label)")
    }
    XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'follow'")).count, 0, "the menu never says Follow")
    attach(app, "d405-notify-menu")
  }

  /// a round nobody has commented on has a door that says "Comments", and opening it is opening to
  /// WRITE: the cursor is in the composer, under "The conversation is yours to start."
  @MainActor func testAnEmptyConversationOpensWithTheCursorReady() {
    let app = launch("season-live", "home")
    _ = root(app, "home")
    let door = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label == %@", "home.round.comments", "Comments")).firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 20), "a round with no comments has a door that just says Comments")
    reveal(door, in: app)
    door.tap()
    let draft = app.textFields["round.comment.draft"]
    XCTAssertTrue(draft.waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["The conversation is yours to start."].waitForExistence(timeout: 5))
    let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: draft)
    XCTAssertEqual(XCTWaiter().wait(for: [ready], timeout: 6), .completed, "opened to be written in: the cursor is in the composer")
    attach(app, "d405-home-empty-open")
  }

  /// the same thread at the largest accessibility size: the composer is still reachable and the
  /// comment rows still read (a screenshot for the review, and the composer must be tappable)
  @MainActor func testTheThreadStaysUsableAtAccessibilitySize() {
    let app = launch("season-live", "home", size: "AX3")
    _ = root(app, "home")
    let door = app.buttons["home.round.comments"].firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 20))
    reveal(door, in: app)
    door.tap()
    let draft = app.textFields["round.comment.draft"]
    XCTAssertTrue(draft.waitForExistence(timeout: 10))
    reveal(draft, in: app)
    XCTAssertTrue(draft.isHittable, "the composer can be tapped at AX3")
    attach(app, "d405-home-open-AX3")
  }

  /// the light printing: the thread, its rule and its muted lines read on the paper ground too
  @MainActor func testTheThreadReadsInTheLightPrinting() {
    let app = launch("season-live", "home", theme: "light")
    _ = root(app, "home")
    let door = app.buttons["home.round.comments"].firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 20))
    reveal(door, in: app)
    door.tap()
    XCTAssertTrue(app.textFields["round.comment.draft"].waitForExistence(timeout: 10))
    attach(app, "d405-home-open-light")
  }

  /// the league board's round post opens its conversation in line, as it always did, with the
  /// same composer — and now the newest comment under a post before a tap
  @MainActor func testTheBoardOpensARoundsThreadInLineToo() {
    let app = launch("season-live", "board")
    let door = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Comments")).firstMatch
    XCTAssertTrue(door.waitForExistence(timeout: 30), "a round post on the board has a comment door")
    reveal(door, in: app)
    XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "board.round.preview.")).firstMatch.waitForExistence(timeout: 10),
                  "a post with comments shows its newest one before a tap")
    door.tap()
    XCTAssertTrue(app.descendants(matching: .any)["board.round.thread"].firstMatch.waitForExistence(timeout: 10))
    XCTAssertTrue(app.textFields["round.comment.draft"].waitForExistence(timeout: 10))
    XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'follow'")).count, 0, "no control reads Follow")
    attach(app, "d405-board-open")
  }

  @MainActor func testTheRoundsPageNamesWhoseRoundItIs() {
    let app = launch("season-live", "receipt-other")
    _ = root(app, "receipt")
    let title = app.staticTexts["round.title"]
    XCTAssertTrue(title.waitForExistence(timeout: 20))
    XCTAssertTrue(title.label.lowercased().hasSuffix("’s round"), "the page says whose round it is: \(title.label)")
    XCTAssertNotEqual(title.label.lowercased(), "the round")
    let draft = app.textFields["round.comment.draft"]
    for _ in 0..<8 where !draft.exists { app.swipeUp() }
    XCTAssertTrue(draft.waitForExistence(timeout: 10))
    XCTAssertTrue((draft.placeholderValue ?? "").hasPrefix("Comment on "), draft.placeholderValue ?? "")
    attach(app, "d405-receipt-other")
  }

  @MainActor func testYourOwnRoundSaysYoursAndTheComposerSaysSo() {
    let app = launch("season-live", "receipt")
    _ = root(app, "receipt")
    XCTAssertTrue(app.staticTexts["round.title"].waitForExistence(timeout: 20))
    XCTAssertEqual(app.staticTexts["round.title"].label.lowercased(), "your round")
    let draft = app.textFields["round.comment.draft"]
    for _ in 0..<8 where !draft.exists { app.swipeUp() }
    XCTAssertTrue(draft.waitForExistence(timeout: 10))
    XCTAssertTrue((draft.placeholderValue ?? "").hasPrefix("Comment on your "), draft.placeholderValue ?? "")
  }
}
