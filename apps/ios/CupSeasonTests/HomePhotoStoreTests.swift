// D361 · each Home round owns its photograph's state. The transitions the
// owner's case depends on, driven with a stub fetcher and no network.
import Testing
import Foundation
import UIKit
@testable import CupSeason

@MainActor
struct HomePhotoStoreTests {
  static func png(_ tone: CGFloat) -> Data {
    UIGraphicsImageRenderer(size: CGSize(width: 40, height: 30)).image { ctx in
      UIColor(white: tone, alpha: 1).setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 30))
    }.pngData()!
  }
  /// a fetcher whose answers are handed to it one at a time, in any order
  final class Gate: @unchecked Sendable {
    var waiters: [String: CheckedContinuation<HomePhotoStore.Outcome, Never>] = [:]
    /// an answer given before the request arrived — the store's task may not
    /// have started yet when the test answers
    var pending: [String: HomePhotoStore.Outcome] = [:]
    var count = 0
    func fetch(_ url: URL) async -> HomePhotoStore.Outcome {
      count += 1
      if let ready = pending.removeValue(forKey: url.absoluteString) { return ready }
      return await withCheckedContinuation { c in waiters[url.absoluteString] = c }
    }
    func answer(_ url: URL, _ o: HomePhotoStore.Outcome) {
      if let c = waiters.removeValue(forKey: url.absoluteString) { c.resume(returning: o) } else { pending[url.absoluteString] = o }
    }
  }
  static func settle() async { for _ in 0..<20 { await Task.yield() }; try? await Task.sleep(nanoseconds: 30_000_000) }

  let a = URL(string: "sig://media/a.png?t=1")!, b = URL(string: "sig://media/b.png?t=1")!

  @Test("reversed completion: the second picture landing first leaves the first loading, then both are loaded")
  func reversedOrder() async {
    let gate = Gate()
    let store = HomePhotoStore(fetch: { await gate.fetch($0) }, maxPixel: 200)
    store.load(path: "a.png", url: a); store.load(path: "b.png", url: b)
    #expect(store.state(for: "a.png").isLoading && store.state(for: "b.png").isLoading)
    await Self.settle()
    gate.answer(b, .data(Self.png(0.5))); await Self.settle()
    #expect(store.state(for: "b.png").image != nil, "the second picture is up")
    #expect(store.state(for: "a.png").isLoading, "the first is still loading — untouched by the second")
    gate.answer(a, .data(Self.png(0.9))); await Self.settle()
    #expect(store.state(for: "a.png").image != nil && store.state(for: "b.png").image != nil, "both photographs stay up together")
    #expect(gate.count == 2)
  }

  @Test("a refresh with a new signed URL keeps the picture on screen while the fetch is out, and does not refetch an unchanged URL")
  func refreshKeepsThePicture() async {
    let gate = Gate()
    let store = HomePhotoStore(fetch: { await gate.fetch($0) }, maxPixel: 200)
    store.load(path: "a.png", url: a); gate.answer(a, .data(Self.png(0.9))); await Self.settle()
    let shown = store.state(for: "a.png").image
    #expect(shown != nil)
    // returning Home with the same URL: nothing goes out
    store.load(path: "a.png", url: a); await Self.settle()
    #expect(gate.count == 1, "an unchanged URL is not fetched again")
    // a refresh re-signed it: the picture stays while the new fetch is out
    let a2 = URL(string: "sig://media/a.png?t=2")!
    store.load(path: "a.png", url: a2)
    #expect(store.state(for: "a.png").isLoading && store.state(for: "a.png").image === shown, "loading keeps the last good picture")
    gate.answer(a2, .transient); await Self.settle()
    #expect(store.state(for: "a.png").image === shown, "a transient miss keeps the last good picture")
    if case .failed = store.state(for: "a.png") {} else { Issue.record("a transient miss is recorded as failed, not removed") }
  }

  @Test("cancellation: a URL superseded mid-flight never lands")
  func cancellation() async {
    let gate = Gate()
    let store = HomePhotoStore(fetch: { await gate.fetch($0) }, maxPixel: 200)
    store.load(path: "a.png", url: a)
    let a2 = URL(string: "sig://media/a.png?t=2")!
    store.load(path: "a.png", url: a2)
    gate.answer(a, .data(Self.png(0.2))); await Self.settle()
    #expect(store.state(for: "a.png").isLoading, "the stale answer did not land")
    gate.answer(a2, .data(Self.png(0.7))); await Self.settle()
    #expect(store.state(for: "a.png").image != nil)
  }

  @Test("gone is gone: a 4xx removes the picture; no URL at all is removal; reconcile forgets a path the wire dropped")
  func removal() async {
    let gate = Gate()
    let store = HomePhotoStore(fetch: { await gate.fetch($0) }, maxPixel: 200)
    store.load(path: "a.png", url: a); store.load(path: "b.png", url: b)
    gate.answer(a, .data(Self.png(0.9))); gate.answer(b, .data(Self.png(0.4))); await Self.settle()
    let a2 = URL(string: "sig://media/a.png?t=2")!
    store.load(path: "a.png", url: a2); gate.answer(a2, .gone); await Self.settle()
    #expect(store.state(for: "a.png") == .removed, "access withdrawn or object gone → the record")
    store.load(path: "b.png", url: nil)
    #expect(store.state(for: "b.png").image != nil, "a credential this load could not get is NOT removal — the picture stays")
    store.load(path: "b.png", credential: .denied)
    #expect(store.state(for: "b.png") == .removed, "the storage's refusal is removal")
    store.reconcile(paths: ["c.png"])
    #expect(store.state(for: "a.png") == .none && store.state(for: "b.png") == .none, "paths the wire no longer carries are forgotten")
  }

  @Test("a credential this load could not get is not removal: the picture stays; a never-loaded round is a miss the next credential retries")
  func unavailableIsNotRemoval() async {
    let gate = Gate()
    let store = HomePhotoStore(fetch: { await gate.fetch($0) }, maxPixel: 200)
    store.load(path: "a.png", url: a); gate.answer(a, .data(Self.png(0.9))); await Self.settle()
    let shown = store.state(for: "a.png").image
    store.load(path: "a.png", credential: .unavailable)
    #expect(store.state(for: "a.png").image === shown, "a transient signing failure took the picture down")
    if case .failed = store.state(for: "a.png") {} else { Issue.record("unavailable is recorded as a miss, not removal") }
    store.load(path: "b.png", credential: .unavailable)
    #expect(store.state(for: "b.png") == .failed(prior: nil), "never loaded + no credential → a miss (the record), not removed")
    store.load(path: "b.png", url: b); gate.answer(b, .data(Self.png(0.4))); await Self.settle()
    #expect(store.state(for: "b.png").image != nil, "the next credential loads it")
    store.load(path: "a.png", credential: .denied)
    #expect(store.state(for: "a.png") == .removed, "the storage's own refusal is removal")
  }

  @Test("a failed first download recovers on the SAME URL, bounded: not on every appearance, and again after a pull")
  func boundedRecovery() async {
    let gate = Gate()
    let store = HomePhotoStore(fetch: { await gate.fetch($0) }, maxPixel: 200)
    store.load(path: "a.png", url: a); gate.answer(a, .transient); await Self.settle()
    #expect(store.state(for: "a.png") == .failed(prior: nil) && gate.count == 1)
    // the next appearance, inside the backoff: nothing goes out
    store.load(path: "a.png", url: a); await Self.settle()
    #expect(gate.count == 1, "a miss was retried on the very next appearance")
    // a pull asks again now, on the same URL
    store.retryMisses()
    store.load(path: "a.png", url: a); gate.answer(a, .data(Self.png(0.6))); await Self.settle()
    #expect(gate.count == 2 && store.state(for: "a.png").image != nil, "the same URL was not retried after a pull")
  }

  @Test("an old decode never repopulates cleared state or overwrites a newer picture")
  func decodeAfterClear() async {
    let gate = Gate()
    final class DecodeGate: @unchecked Sendable {
      var c: CheckedContinuation<UIImage?, Never>?
      func wait() async -> UIImage? { await withCheckedContinuation { self.c = $0 } }
      func release(_ img: UIImage?) { c?.resume(returning: img); c = nil }
    }
    let dg = DecodeGate()
    let store = HomePhotoStore(fetch: { await gate.fetch($0) }, decode: { _, _ in await dg.wait() }, maxPixel: 200)
    store.load(path: "a.png", url: a); gate.answer(a, .data(Self.png(0.9))); await Self.settle()
    // the bytes are decoding; the account changes underneath
    store.clear()
    dg.release(UIImage(data: Self.png(0.9))); await Self.settle()
    #expect(store.state(for: "a.png") == .none, "a decode that finished after clear repopulated the state")
    // and a newer credential wins over an older decode
    let a2 = URL(string: "sig://media/a.png?t=2")!
    store.load(path: "a.png", url: a); gate.answer(a, .data(Self.png(0.2))); await Self.settle()
    store.load(path: "a.png", url: a2)
    dg.release(UIImage(data: Self.png(0.2))); await Self.settle()   // the OLD decode finishes
    #expect(store.state(for: "a.png").isLoading, "an old decode overwrote a newer load")
    gate.answer(a2, .data(Self.png(0.7))); await Self.settle()
    dg.release(UIImage(data: Self.png(0.7))); await Self.settle()
    #expect(store.state(for: "a.png").image != nil)
  }

  @Test("the decode is downsampled at the source")
  func downsampled() async {
    let big = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 2000)).image { ctx in
      UIColor.gray.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 3000, height: 2000))
    }.pngData()!
    let img = await HomePhotoStore.decode(big, maxPixel: 1400)
    #expect(img != nil && max(img!.size.width, img!.size.height) <= 1400)
  }
}
