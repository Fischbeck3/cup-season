import XCTest
import CupSeasonKit
@testable import CupSeason

@MainActor final class OfflineCoursesModelTests: XCTestCase {
  func fixture() -> CourseBook {
    .init(id: "qa", clubName: "QA course", courseName: nil, city: nil, state: nil,
          tees: [.init(teeName: "Blue", gender: "male", rating: 71.2, slope: 128, holesCount: 18, parTotal: nil, yards: nil,
                       holes: (1...18).map { .init(hole: $0, par: 4, si: nil) })])
  }
  func testSaveFailurePreservesExistingReadyCard() async {
    let book = fixture()
    let vm = OfflineCoursesModel(read: { [book] }, download: { _ in nil })
    await vm.load(); vm.select(book.hit); await vm.save()
    XCTAssertNotNil(vm.message)
    XCTAssertTrue(vm.book?.tees.first?.offlineReady == true)
    XCTAssertFalse(vm.downloading)
  }
  func testDuplicateTapDownloadsOnceAndRetryRecovers() async {
    let book = fixture()
    var calls = 0
    var saved: [CourseBook] = []
    let started = expectation(description: "download started")
    var release: CheckedContinuation<Void, Never>?
    let vm = OfflineCoursesModel(read: { saved }, download: { _ in
      calls += 1
      if calls == 1 {
        await withCheckedContinuation { release = $0; started.fulfill() }
        return nil
      }
      saved = [book]; return book
    })
    vm.select(book.hit)
    let first = Task { await vm.save() }
    await fulfillment(of: [started], timeout: 3)
    await vm.save()
    release?.resume()
    await first.value
    XCTAssertEqual(calls, 1)
    XCTAssertNotNil(vm.message)
    await vm.save()
    XCTAssertEqual(calls, 2)
    XCTAssertNil(vm.message)
    XCTAssertTrue(vm.book?.tees.first?.offlineReady == true)
  }
}
