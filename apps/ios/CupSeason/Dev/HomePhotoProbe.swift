// Cup Season — `-cs_dev_photo_probe_home`: MEASURE the Home photograph path.
//
// The owner's report: two adjacent photo rounds on Home, and loading one
// removed the other. Before changing anything, this writes down what the
// current path actually costs on the signed-in simulator — signing time, the
// bytes and time of a download with a FRESH signed URL and again with the SAME
// one (which is the difference between a cache miss and a hit), the decode of
// the full picture against a downsampled one, and whether the project's
// storage answers an image transform at all.
//
// It reads; it changes nothing. It writes one JSON file to Documents so the
// numbers can be copied out of the container. DEBUG only.

#if DEBUG
import Foundation
import UIKit
import ImageIO
import Supabase
import CupSeasonKit

enum HomePhotoProbe {
  static var wanted: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_photo_probe_home") }

  struct Fetch: Codable { var status: Int; var bytes: Int; var ms: Double; var cacheHitBefore: Bool; var cacheControl: String? }
  struct Decode: Codable { var ms: Double; var width: Int; var height: Int }
  struct Row: Codable {
    var path: String
    var signMs: Double
    var fresh: Fetch?
    var again: Fetch?
    var full: Decode?
    var downsampled: Decode?
    var transform: Fetch?
  }
  struct Report: Codable {
    var when: String
    var paths: Int
    var batchSignMs: Double
    var rows: [Row]
    var note: String
  }

  static func run(client: SupabaseClient) async {
    let iso = ISO8601DateFormatter().string(from: Date())
    var rows: [Row] = []
    var note = ""
    // the same rows Home reads, the same cap Home signs
    let feed: [HomeFeedRow] = (try? await SupabaseService.shared.call(Rpc.home_feed(p_days: 21))) ?? []
    let paths = Array(feed.compactMap(\.photo_path).prefix(14))
    var batchMs = 0.0
    if !paths.isEmpty {
      let t = Date()
      _ = try? await client.storage.from("media").createSignedURLs(paths: paths, expiresIn: 3600)
      batchMs = Date().timeIntervalSince(t) * 1000
    } else {
      note = "the signed-in account's circle has no photo rounds in the last 21 days"
    }
    for path in paths.prefix(4) {
      var row = Row(path: path, signMs: 0)
      let t0 = Date()
      guard let url = try? await client.storage.from("media").createSignedURL(path: path, expiresIn: 3600) else {
        row.signMs = -1; rows.append(row); continue
      }
      row.signMs = Date().timeIntervalSince(t0) * 1000
      // 1 · a fresh signed URL — what every Home load does today
      let (data1, f1) = await fetch(url)
      row.fresh = f1
      // 2 · the SAME URL again — what a reused URL would do
      let (_, f2) = await fetch(url)
      row.again = f2
      if let d = data1 {
        row.full = decode(d, maxPixel: nil)
        row.downsampled = decode(d, maxPixel: 1400)
      }
      // 3 · a server-side transform, if the project's plan answers one
      if let turl = try? await client.storage.from("media").createSignedURL(
        path: path, expiresIn: 300, transform: TransformOptions(width: 1200, quality: 75)) {
        let (_, f3) = await fetch(turl)
        row.transform = f3
      }
      rows.append(row)
    }
    let report = Report(when: iso, paths: paths.count, batchSignMs: batchMs, rows: rows, note: note)
    if let json = try? JSONEncoder().encode(report) {
      let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      try? json.write(to: folder.appendingPathComponent("photo-probe.json"))
      NSLog("[photo-probe] wrote %@", folder.appendingPathComponent("photo-probe.json").path)
    }
  }

  private static func fetch(_ url: URL) async -> (Data?, Fetch) {
    let req = URLRequest(url: url)
    let hit = URLCache.shared.cachedResponse(for: req) != nil
    let t = Date()
    do {
      let (data, resp) = try await URLSession.shared.data(for: req)
      let http = resp as? HTTPURLResponse
      return (data, Fetch(status: http?.statusCode ?? 0, bytes: data.count, ms: Date().timeIntervalSince(t) * 1000,
                          cacheHitBefore: hit, cacheControl: http?.value(forHTTPHeaderField: "Cache-Control")))
    } catch {
      return (nil, Fetch(status: -1, bytes: 0, ms: Date().timeIntervalSince(t) * 1000, cacheHitBefore: hit, cacheControl: nil))
    }
  }

  private static func decode(_ data: Data, maxPixel: Int?) -> Decode? {
    let t = Date()
    guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    var opts: [CFString: Any] = [kCGImageSourceShouldCacheImmediately: true]
    let img: CGImage?
    if let maxPixel {
      opts[kCGImageSourceCreateThumbnailFromImageAlways] = true
      opts[kCGImageSourceThumbnailMaxPixelSize] = maxPixel
      img = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
    } else {
      img = CGImageSourceCreateImageAtIndex(src, 0, opts as CFDictionary)
    }
    guard let img else { return nil }
    // force the decode to actually happen
    _ = UIImage(cgImage: img).cgImage?.dataProvider?.data
    return Decode(ms: Date().timeIntervalSince(t) * 1000, width: img.width, height: img.height)
  }
}
#endif
