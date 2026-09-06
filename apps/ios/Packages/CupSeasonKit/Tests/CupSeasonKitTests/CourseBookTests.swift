// D261 / R-N · the offline course store.
//
// The three things R-N says it must make work with no signal are the three
// things asserted here — a lookup, a hole card the tee sheet can score off,
// and a composer row — plus the honesty rules, because those are the half a
// screenshot cannot prove: a cached figure that does not say it is cached is
// the defect, not the missing figure.

import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct CourseBookTests {

  private func tmpDisk() -> CourseDisk {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("cs-course-tests-\(UUID().uuidString)", isDirectory: true)
    return CourseDisk(directory: dir)
  }

  private func book(_ id: String, label: String = "Papago", tees: Int = 1, holes: Int = 18,
                    used: Date = Date(), saved: Date = Date()) -> CourseBook {
    let card = (1...holes).map { CourseHole(hole: $0, par: $0 % 3 == 0 ? 3 : 4, si: $0) }
    return CourseBook(id: id, clubName: label, courseName: nil, city: "Tempe", state: "AZ",
                      tees: (0..<tees).map { i in
                        CourseBookTee(teeName: ["Blue", "White", "Gold"][i % 3], gender: "male",
                                      rating: 71.2 + Double(i), slope: 128 + i,
                                      holesCount: holes, parTotal: 72, yards: 6500, holes: card)
                      },
                      planned: false, played: true, nextPlayOn: nil, lastPlayedOn: "2026-08-20",
                      savedAt: saved, usedAt: used)
  }

  // MARK: - the payload

  @Test("a my_course_books row becomes a book, and a row with no id is dropped")
  func decodesTheRow() throws {
    let json = """
    [{"id":"012345","club_name":"Papago","course_name":"Papago","city":"Phoenix","state":"AZ",
      "planned":true,"played":false,"next_play_on":"2026-09-12","last_played_on":null,
      "tees":[{"tee_name":"Blue","gender":"male","course_rating":71.2,"slope_rating":128,
               "number_of_holes":18,"par_total":72,"total_yards":6590,
               "holes":[{"hole":1,"par":4,"si":7},{"hole":2,"par":3,"si":17}]}]},
     {"club_name":"No id here","tees":[]}]
    """
    let v = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
    let books = (v.array ?? []).compactMap(CourseBookStore.book(from:))
    #expect(books.count == 1)                       // the id-less row is DROPPED, never defaulted
    let b = try #require(books.first)
    #expect(b.label == "Papago")                    // club == course, printed once
    #expect(b.place == "Phoenix, AZ")
    #expect(b.planned && !b.played && b.nextPlayOn == "2026-09-12")
    #expect(b.tees.first?.rating == 71.2 && b.tees.first?.slope == 128)
    #expect(b.tees.first?.firstHole?.par == 4 && b.tees.first?.firstHole?.si == 7)
  }

  @Test("a tee whose card was never cached says so — it never invents eighteen par 4s")
  func neverInventsACard() {
    let tee = CourseBookTee(teeName: "Blue", gender: "male", rating: 71.2, slope: 128,
                            holesCount: 18, parTotal: nil, yards: nil, holes: [])
    #expect(tee.pars(want: 18) == nil)
    #expect(tee.card(want: 18) == nil)
    #expect(tee.firstHole == nil)
    // a PARTIAL card is not a card either — nine holes cannot answer for eighteen
    let nine = CourseBookTee(teeName: "Blue", gender: nil, rating: 71.2, slope: 128, holesCount: 18,
                             parTotal: nil, yards: nil,
                             holes: (1...9).map { CourseHole(hole: $0, par: 4, si: $0) })
    #expect(nine.pars(want: 18) == nil)
    #expect(nine.pars(want: 9)?.count == 9)
  }

  // MARK: - the disk

  @Test("R-N · the airplane case: a book survives a write and reads back whole")
  func roundTrips() async {
    let disk = tmpDisk()
    await disk.save(book("abc"))
    let back = await disk.book("abc")
    #expect(back?.id == "abc")
    #expect(back?.tees.first?.slope == 128)
    #expect(back?.tees.first?.card(want: 18)?.count == 18)   // pars AND stroke indexes
    #expect(back?.tees.first?.card(want: 18)?[2].par == 3)
  }

  @Test("R-N · the store is capped and evicts LEAST RECENTLY USED")
  func evictsLRU() async {
    let disk = tmpDisk()
    let base = Date(timeIntervalSince1970: 1_700_000_000)
    for i in 0..<(CourseDisk.cap + 5) {
      await disk.save(book("c\(i)", used: base.addingTimeInterval(Double(i))))
    }
    let kept = await disk.books()
    #expect(kept.count == CourseDisk.cap)
    // the five oldest are gone, the newest is first
    #expect(kept.first?.id == "c\(CourseDisk.cap + 4)")
    #expect(await disk.book("c0") == nil)
    #expect(await disk.book("c4") == nil)
    #expect(await disk.book("c5") != nil)
  }

  @Test("reading TOUCHES a book, which is what makes the eviction order 'used'")
  func readTouches() async {
    let disk = tmpDisk()
    let old = Date(timeIntervalSince1970: 1_700_000_000)
    await disk.save(book("a", used: old))
    await disk.save(book("b", used: old.addingTimeInterval(60)))
    _ = await disk.book("a")
    #expect(await disk.books().first?.id == "a")
  }

  @Test("a refresh MERGES: it keeps the eviction order and never forgets a card it holds")
  func mergeKeepsWhatItKnows() async {
    let disk = tmpDisk()
    let used = Date(timeIntervalSince1970: 1_700_000_000)
    await disk.save(book("a", used: used))
    // the server row came back with the course but no tees (the tee cache has
    // not been filled). A thinner read is not permission to forget (L-44).
    let thin = CourseBook(id: "a", clubName: "Papago", courseName: nil, city: nil, state: nil,
                          tees: [], planned: true, played: false, nextPlayOn: "2026-09-12",
                          lastPlayedOn: nil, savedAt: Date(), usedAt: Date())
    await disk.merge([thin])
    let back = await disk.book("a")
    #expect(back?.tees.count == 1)
    #expect(back?.tees.first?.holes.count == 18)
    #expect(back?.planned == true && back?.nextPlayOn == "2026-09-12")
  }

  @Test("a course id off the network can never climb out of the directory")
  func fileNameIsSafe() {
    #expect(CourseDisk.fileName("../../etc/passwd") == "course-------etc-passwd.json")
    #expect(!CourseDisk.fileName("a/b/c").contains("/"))
    #expect(CourseDisk.fileName("012345") == "course-012345.json")
  }

  @Test("the offline search answers off the phone, and only for what the phone kept")
  func searchesTheStore() async {
    let disk = tmpDisk()
    await disk.save(book("a", label: "Papago Golf Course"))
    await disk.save(book("b", label: "Encanto 9"))
    #expect(await disk.search("papa").map(\.id) == ["a"])
    #expect(await disk.search("tempe").count == 2)      // the place matches too
    #expect(await disk.search("pebble").isEmpty)         // never played, never kept
    #expect(await disk.search("p").isEmpty)              // one letter is not a search
  }

  // MARK: - the honesty rules (L-32)

  @Test("L-32 · a cached course always says when it is from, and never says 'live'")
  func alwaysSaysWhenItIsFrom() {
    let cal = Calendar(identifier: .gregorian)
    let now = Date(timeIntervalSince1970: 1_757_030_400)     // a fixed clock
    let b = book("a", saved: now)
    let line = b.savedLine(now: now, calendar: cal)
    #expect(line == "Saved on your phone today")
    #expect(!line.lowercased().contains("live"))
    #expect(!line.lowercased().contains("updated"))
    let older = book("a", saved: now.addingTimeInterval(-86_400))
    #expect(older.savedLine(now: now, calendar: cal) == "Saved on your phone yesterday")
    let old = book("a", saved: now.addingTimeInterval(-5 * 86_400))
    #expect(old.savedLine(now: now, calendar: cal).hasPrefix("Saved on your phone "))
    #expect(!old.savedLine(now: now, calendar: cal).contains("today"))
  }

  @Test("a LIVE answer wears no offline caveat, and every other answer says something")
  func theAnswerCarriesItsSource() {
    #expect(CourseAnswer(book: nil, source: .live).line().isEmpty)
    #expect(CourseAnswer(book: nil, source: .failed).line() == CourseBookCopy.readFailed)
    #expect(CourseAnswer(book: nil, source: .neverKept).line() == CourseBookCopy.neverKept)
    let b = book("a")
    let saved = CourseAnswer(book: b, source: .saved(b.savedAt)).line()
    #expect(saved.hasPrefix("Saved on your phone"))
    // a course this phone never kept says so and offers what it can — it is
    // never a blank screen and never an invented tee
    #expect(CourseBookCopy.neverKept.contains("not on your phone"))
    #expect(CourseBookCopy.readFailed.contains("kept"))
  }

  @Test("an offline search result set says it is offline; a live one never does")
  func searchAnswerIsHonest() {
    #expect(CourseSearchAnswer(hits: [], offline: true).note == CourseBookCopy.searchOffline)
    #expect(CourseSearchAnswer(hits: [], offline: false).note.isEmpty)
    // the empty OFFLINE answer is still honest: it says no signal, not "no such course"
    #expect(CourseSearchAnswer(hits: [], offline: true).note.contains("No signal"))
  }

  @Test("R-N · the composer offers a kept course as an ordinary search row")
  func bookRendersAsASearchRow() {
    let hit = book("a", label: "Papago", tees: 3).hit
    #expect(hit.id == "a")
    #expect(hit.label == "Papago")
    #expect(hit.tees.count == 3)                       // every tee keeps its rating and slope
    #expect(hit.tees.allSatisfy { $0.course_rating != nil && $0.slope_rating != nil })
    #expect(hit.subline == "Tempe, AZ · 3 tees")
  }
}
