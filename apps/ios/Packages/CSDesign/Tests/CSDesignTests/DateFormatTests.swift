import Testing
import Foundation
@testable import CSDesign

/// N4-098 · the header date, the stale line and the masthead's dateline come
/// from cached formatters now. The words are unchanged, and a cached formatter
/// never carries one caller's calendar — or its zone — into the next caller's
/// string. (A formatter prints in its own zone, not its calendar's; the first
/// run of this suite caught the cache keeping Phoenix for a UTC caller.)
@Suite struct DateFormatTests {
  private func calendar(_ tz: String) -> Calendar {
    var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: tz)!; return c
  }
  // 2026-09-27 06:30 UTC: Saturday evening in Phoenix, Sunday morning in UTC
  private let instant = Date(timeIntervalSince1970: 1_790_490_600)

  @Test func theWordsAreUnchanged() {
    let phx = calendar("America/Phoenix")
    #expect(CSHeaderDate.today(instant, calendar: phx) == "SAT · SEP 26")
    #expect(CSMasthead.dateline(instant, calendar: phx) == "SAT · SEP 26")
    #expect(CSStale.line(instant, calendar: phx) == "As of Sat 11:30 PM · offline")
  }

  @Test func aCachedFormatterTakesEachCallersCalendar() {
    let phx = calendar("America/Phoenix"), utc = calendar("UTC")
    for _ in 0..<3 {
      #expect(CSHeaderDate.today(instant, calendar: phx) == "SAT · SEP 26")
      #expect(CSHeaderDate.today(instant, calendar: utc) == "SUN · SEP 27")
    }
  }
}
