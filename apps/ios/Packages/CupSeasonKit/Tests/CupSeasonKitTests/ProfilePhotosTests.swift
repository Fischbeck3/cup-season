import Foundation
import Testing
@testable import CupSeasonKit

@Suite struct ProfilePhotosTests {
  private let owner = UUID(uuidString: "FACE0000-0000-4000-8000-000000000001")!
  private let a = UUID(uuidString: "FACE0000-0000-4000-8000-000000000002")!
  private let b = UUID(uuidString: "FACE0000-0000-4000-8000-000000000003")!
  private let photo = URL(string: "https://example.invalid/profile.jpg")!

  private actor Loader {
    var calls: [[UUID]] = []
    var results: [UUID: ProfilePhotoResult]
    init(_ results: [UUID: ProfilePhotoResult]) { self.results = results }
    func load(_ ids: [UUID]) -> [UUID: ProfilePhotoResult] {
      calls.append(ids)
      return results.filter { ids.contains($0.key) }
    }
    func set(_ id: UUID, _ result: ProfilePhotoResult) { results[id] = result }
  }

  @Test func visibleFacesBatchAndDuplicateProfilesCoalesce() async {
    let loader = Loader([a: .photo(photo), b: .noPhoto])
    let cache = ProfilePhotos(load: { await loader.load($0) }, delay: .milliseconds(50))
    await cache.claim(owner)
    let values = await withTaskGroup(of: ProfilePhotoResult.self) { group in
      for id in [a, a, a, b, b] { group.addTask { await cache.photo(id, owner: owner) } }
      var values: [ProfilePhotoResult] = []
      for await value in group { values.append(value) }
      return values
    }
    #expect(values.filter { $0 == .photo(photo) }.count == 3)
    #expect(values.filter { $0 == .noPhoto }.count == 2)
    let calls = await loader.calls
    #expect(calls.count == 1 && Set(calls[0]) == Set([a, b]))
    #expect(await cache.photo(a, owner: owner) == .photo(photo))
    #expect(await loader.calls.count == 1, "returning surfaces reuse the URL")
  }

  @Test func signedOutAndOldOwnerViewsCannotStartReads() async {
    let loader = Loader([a: .photo(photo)])
    let cache = ProfilePhotos(load: { await loader.load($0) })
    #expect(await cache.photo(a, owner: owner) == .unavailable)
    await cache.claim(owner)
    #expect(await cache.photo(a, owner: nil) == .unavailable)
    await cache.claim(b)
    #expect(await cache.photo(a, owner: owner) == .unavailable)
    #expect(await loader.calls.isEmpty)
  }

  @Test func changedOrRemovedPhotoInvalidatesCachedAnswers() async {
    let loader = Loader([a: .noPhoto])
    let cache = ProfilePhotos(load: { await loader.load($0) })
    await cache.claim(owner)
    #expect(await cache.photo(a, owner: owner) == .noPhoto)
    await loader.set(a, .photo(photo))
    await cache.invalidate(a)
    #expect(await cache.photo(a, owner: owner) == .photo(photo))
    await loader.set(a, .noPhoto)
    await cache.invalidate(a)
    #expect(await cache.photo(a, owner: owner) == .noPhoto)
    #expect(await loader.calls.count == 3)
  }

  private final class Clock: @unchecked Sendable {
    private let lock = NSLock()
    private var time = Date(timeIntervalSince1970: 1000)
    func now() -> Date { lock.lock(); defer { lock.unlock() }; return time }
    func advance(_ seconds: TimeInterval) { lock.lock(); defer { lock.unlock() }; time += seconds }
  }
  @Test func expiryRetriesMissingPhotosAndTransientFailures() async {
    let clock = Clock(), loader = Loader([a: .noPhoto])
    let cache = ProfilePhotos(load: { await loader.load($0) }, now: { clock.now() })
    await cache.claim(owner)
    #expect(await cache.photo(a, owner: owner) == .noPhoto)
    await loader.set(a, .photo(photo))
    clock.advance(61)
    #expect(await cache.photo(a, owner: owner) == .photo(photo))
    await loader.set(a, .unavailable)
    clock.advance(301)
    #expect(await cache.photo(a, owner: owner) == .unavailable)
    await loader.set(a, .photo(photo))
    clock.advance(11)
    #expect(await cache.photo(a, owner: owner) == .photo(photo))
  }

  private actor Gate {
    var started: CheckedContinuation<Void, Never>?
    var response: CheckedContinuation<[UUID: ProfilePhotoResult], Never>?
    var running = false
    var count = 0
    let photo: URL
    init(_ photo: URL) { self.photo = photo }
    func load(_ ids: [UUID]) async -> [UUID: ProfilePhotoResult] {
      count += 1
      if count > 1 { return Dictionary(uniqueKeysWithValues: ids.map { ($0, .noPhoto) }) }
      return await withCheckedContinuation { continuation in
        response = continuation; running = true
        started?.resume(); started = nil
      }
    }
    func wait() async {
      if running { return }
      await withCheckedContinuation { started = $0 }
    }
    func finish(_ id: UUID) { response?.resume(returning: [id: .photo(photo)]); response = nil }
  }
  @Test func lateReadCannotLeakIntoANewAccount() async {
    let gate = Gate(photo)
    let cache = ProfilePhotos(load: { await gate.load($0) })
    await cache.claim(owner)
    let old = Task { await cache.photo(a, owner: owner) }
    await gate.wait()
    await cache.claim(b)
    #expect(await old.value == .unavailable)
    await gate.finish(a)
    #expect(await cache.photo(a, owner: b) == .noPhoto)
    #expect(await cache.photo(a, owner: owner) == .unavailable)
    #expect(await gate.count == 2)
  }
  @Test func absentLoaderResultIsTemporaryRatherThanClaimingNoPhoto() async {
    let cache = ProfilePhotos(load: { _ in [:] })
    await cache.claim(owner)
    #expect(await cache.photo(a, owner: owner) == .unavailable)
  }
}
