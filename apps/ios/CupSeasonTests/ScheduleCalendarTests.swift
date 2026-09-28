// F15 · EVERY DAY ON THE CALENDAR IS A 44 × 44 TARGET, ON AN SE TOO.
//
// Seven flexible columns with six 4pt gaps inside the band's 12s and the
// page's 20s left each day (375 − 88) / 7 = 41pt wide on a 375pt phone, and a
// `minHeight: 44` on a 41pt-wide button is not a 44pt target. These tests host
// the real month grid inside the page's own gutter at the two phones' widths
// and at the reading and AX3 sizes, and measure every day's actual frame: at
// least 44 × 44, and no two days sharing a point.

import Testing
import SwiftUI
import UIKit
import CSDesign
import CupSeasonKit
@testable import CupSeason

@MainActor
@Suite struct ScheduleCalendarTests {

  /// The grid as the schedule screen sets it: inside the page's 20pt padding.
  static func grid(_ month: CalendarMonth, today: String, byDay: [Int: [CalendarItem]] = [:]) -> some View {
    ScheduleMonthGrid(month: month, byDay: byDay, today: today) { _ in }
      .padding(20)
  }

  /// September 2026 opens on a Tuesday and has 30 days; March 2026 opens on a
  /// Sunday and has 31 — a month boundary on each edge of the grid.
  static let months: [(CalendarMonth, String)] = [
    (CalendarMonth(year: 2026, month: 9), "2026-09-28"),
    (CalendarMonth(year: 2026, month: 3), "2026-03-01"),
    (CalendarMonth(year: 2026, month: 5), "2026-05-31"),
  ]

  @Test("every day is at least 44 × 44 at 375 and 402, reading size and AX3")
  func everyDayIsAFullTarget() throws {
    for width in [CGFloat(375), 402] {
      for size in [DynamicTypeSize.large, .accessibility3] {
        for (month, today) in Self.months {
          let h = HostedLayout(Self.grid(month, today: today), width: width, typeSize: size)
          defer { h.tearDown() }
          let days = h.elements(prefix: "schedule.day.")
          #expect(days.count == month.daysInMonth, "\(width) \(size) \(month.title): every day is an element")
          for d in days {
            #expect(d.frame.width >= 44 - 0.01 && d.frame.height >= 44 - 0.01,
                    "\(width) \(size) \(d.identifier): \(d.frame.width) × \(d.frame.height)")
          }
        }
      }
    }
  }

  /// A month that opens mid-week keeps its first days, in their own columns:
  /// the grid keyed its leading blanks 0, 1, 2… — the same keys as the 1st,
  /// 2nd, 3rd — and a lazy grid drew one child per key, so September 2026
  /// (a Tuesday) printed no 1st and May 2026 (a Friday) no 1st to 4th.
  @Test("the first days of a month that opens mid-week are drawn, under their own weekday")
  func monthBoundaryKeepsItsFirstDays() throws {
    for (month, today) in Self.months {
      let h = HostedLayout(Self.grid(month, today: today), width: 375)
      defer { h.tearDown() }
      for d in 1...7 {
        let day = try #require(h.element("schedule.day.\(d)"), "\(month.title): day \(d) is drawn")
        let week = try #require(h.element("schedule.day.\(d + 7)"))
        #expect(abs(day.frame.minX - week.frame.minX) < 0.6,
                "\(month.title): day \(d) sits in the same weekday column as day \(d + 7)")
        #expect(day.frame.maxY <= week.frame.minY + 0.5, "\(month.title): day \(d) is in the week above")
      }
    }
  }

  /// The legend stays inside its band at every width and size: every key is
  /// drawn above whatever follows the grid. A row-or-column switch here once
  /// drew three stacked keys in a band measured for one row.
  @Test("the legend's keys stay inside the band, above what follows it")
  func legendStaysInsideTheBand() throws {
    for width in [CGFloat(375), 402] {
      for size in [DynamicTypeSize.large, .xxxLarge, .accessibility3] {
        let (month, today) = Self.months[0]
        let h = HostedLayout(VStack(spacing: 0) { Self.grid(month, today: today); Text("After the band") },
                             width: width, typeSize: size)
        defer { h.tearDown() }
        let after = try #require(h.elements.first { $0.label == "After the band" })
        for key in ["ON THE SCHEDULE", "IN YOUR SEASONS", "SEASON DATE"] {
          let k = try #require(h.elements.first { $0.label.localizedCaseInsensitiveCompare(key) == .orderedSame },
                               "\(width) \(size): the \(key) key is drawn")
          #expect(k.frame.maxY <= after.frame.minY - 20 + 0.5,
                  "\(width) \(size): \(key) ends at \(k.frame.maxY), the band's foot must clear it before \(after.frame.minY)")
          #expect(k.frame.maxX <= width - 20 - CSTokens.Space.s3 + 0.5, "\(width) \(size): \(key) stays inside the band")
        }
      }
    }
  }

  @Test("no two days share hit space, and each week reads left to right")
  func daysNeverOverlap() throws {
    for width in [CGFloat(375), 402] {
      for size in [DynamicTypeSize.large, .accessibility3] {
        let (month, today) = Self.months[0]
        let h = HostedLayout(Self.grid(month, today: today), width: width, typeSize: size)
        defer { h.tearDown() }
        let days = h.elements(prefix: "schedule.day.")
        for i in days.indices {
          for j in days.indices where j > i {
            let x = days[i].frame.intersection(days[j].frame)
            #expect(x.isNull || x.width * x.height < 0.5,
                    "\(width) \(size): \(days[i].identifier) and \(days[j].identifier) overlap by \(x)")
          }
        }
        // day 1 (Tuesday) sits right of day 6 (Sunday)'s column start, and a
        // week runs left to right
        let byDay = Dictionary(uniqueKeysWithValues: days.map { ($0.identifier, $0.frame) })
        if let d6 = byDay["schedule.day.6"], let d7 = byDay["schedule.day.7"], let d12 = byDay["schedule.day.12"] {
          #expect(d6.minX < d7.minX && d7.minX < d12.minX, "\(width) \(size): a week reads left to right")
        }
      }
    }
  }

  @Test("the seven columns fill the band exactly, so the SE's day is 44.4pt wide")
  func theColumnsFillTheBand() throws {
    for (width, expected) in [(CGFloat(375), (375 - 40 - 24) / 7.0), (402, (402 - 40 - 24) / 7.0)] {
      let (month, today) = Self.months[0]
      let h = HostedLayout(Self.grid(month, today: today), width: width)
      defer { h.tearDown() }
      let d = try #require(h.element("schedule.day.8"))
      #expect(abs(d.frame.width - expected) < 0.6, "\(width): a day is \(d.frame.width)pt, expected \(expected)")
    }
  }

  @Test("today and a planned day speak their date and what is on it")
  func daysSpeakTheirDates() throws {
    let (month, today) = Self.months[0]
    let round = ScheduledRoundFixture.one(on: "2026-09-30")
    let h = HostedLayout(Self.grid(month, today: today, byDay: [30: [.round(round)]]), width: 375)
    defer { h.tearDown() }
    let d30 = try #require(h.element("schedule.day.30"))
    #expect(d30.label.hasSuffix(", 1 on the schedule"), "\(d30.label)")
    let d28 = try #require(h.element("schedule.day.28"))
    #expect(d28.label == ScheduleDates.long("2026-09-28"), "\(d28.label)")
    #expect(!d28.traits.contains(.notEnabled), "today is tappable")
    let d27 = try #require(h.element("schedule.day.27"))
    #expect(d27.traits.contains(.notEnabled), "an empty past day is not a target at all")
  }
}

/// A scheduled round with invented values — no real golfer, course or date
/// anybody played.
enum ScheduledRoundFixture {
  static func one(on iso: String) -> ScheduledRound {
    ScheduledRound(id: UUID(uuidString: "00000000-0000-4000-8000-00000000f15a"),
                   display_name: "Fixture golfer", play_on: iso, course_label: "Fixture Links",
                   is_friend: false, shared_league: false, tagged_me: false)
  }
}
