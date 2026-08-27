// Cup Season — the live round's durable local state (index.html 7440–7478,
// 7589–7602, 14733–14736).
//
// The web keeps three things in localStorage and they all survive a kill here
// as JSON files in Application Support:
//   cs.live.<lr>       the full round snapshot — local-FIRST resume, no network
//   cs.liveq.<lr>      the write queue (300 cap) — an edit made in a canyon
//                      lands when the signal does
//   cs.pendingAbandons a scrap whose RPC failed — drained at boot / tee-off /
//                      the next scrap, and treated as DEAD by the resume path
//                      so a corpse can never come back (pilot bug)

import Foundation

/// One queued write — the same dict the web broadcasts and flushes.
public struct LiveMessage: Codable, Sendable, Equatable {
  /// 'score' · 'wolf' · 'finish' · 'gone'
  public var t: String
  public var pid: UUID?
  /// 1-based hole
  public var h: Int?
  /// strokes; nil = cleared
  public var s: Int?
  public var w: JSONValue?
  public var status: String?
  /// the write clock, ms
  public var cts: Int64
  public var tries: Int?

  public init(t: String, pid: UUID? = nil, h: Int? = nil, s: Int? = nil, w: JSONValue? = nil, status: String? = nil, cts: Int64, tries: Int? = nil) {
    self.t = t; self.pid = pid; self.h = h; self.s = s; self.w = w; self.status = status; self.cts = cts; self.tries = tries
  }

  public static func score(pid: UUID, hole0: Int, strokes: Int?, cts: Int64) -> LiveMessage {
    LiveMessage(t: "score", pid: pid, h: hole0 + 1, s: strokes, cts: cts)
  }
  public static func wolf(hole0: Int, pick: LiveWolfPick?, cts: Int64) -> LiveMessage {
    LiveMessage(t: "wolf", h: hole0 + 1, w: pick?.json ?? .null, cts: cts)
  }
  public static func finish(cts: Int64) -> LiveMessage { LiveMessage(t: "finish", status: "final", cts: cts) }
  public static func gone(cts: Int64) -> LiveMessage { LiveMessage(t: "gone", status: "abandoned", cts: cts) }

  /// The JSON the web's `liveRecv` reads: `s: null` and `w: null` are present.
  public var wire: [String: JSONValue] {
    var o: [String: JSONValue] = ["t": .string(t), "cts": .number(Double(cts))]
    if let pid { o["pid"] = .string(pid.uuidString.lowercased()) }
    if let h { o["h"] = .number(Double(h)) }
    if t == "score" { o["s"] = s.map { .number(Double($0)) } ?? .null }
    if t == "wolf" { o["w"] = w ?? .null }
    if let status { o["status"] = .string(status) }
    return o
  }

  /// A broadcast payload → message. Missing keys read as the web's `null`.
  public init?(wire v: JSONValue) {
    guard case .object = v, let t = v["t"]?.string else { return nil }
    self.t = t
    pid = v["pid"]?.string.flatMap(UUID.init)
    h = v["h"]?.int
    s = v["s"]?.int
    w = v["w"].flatMap { $0.isNull ? nil : $0 }
    status = v["status"]?.string
    cts = Int64(v["cts"]?.double ?? 0)
    tries = nil
  }
}

/// The files. An actor so two flushes never race a write.
public actor LiveDisk {
  public static let shared = LiveDisk()

  public static let queueCap = 300
  public static let abandonCap = 20

  let dir: URL
  private let enc = JSONEncoder()
  private let dec = JSONDecoder()

  public init(directory: URL? = nil) {
    if let directory { dir = directory }
    else {
      let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
        ?? FileManager.default.temporaryDirectory
      dir = base.appendingPathComponent("CupSeason/live", isDirectory: true)
    }
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
  }

  func snapshotURL(_ lr: UUID) -> URL { dir.appendingPathComponent("live-\(lr.uuidString.lowercased()).json") }
  func queueURL(_ lr: UUID) -> URL { dir.appendingPathComponent("queue-\(lr.uuidString.lowercased()).json") }
  var abandonsURL: URL { dir.appendingPathComponent("pending-abandons.json") }

  // MARK: snapshots (`persistLive` / `readLiveSnapshots` / `clearLiveCache`)

  /// Write the whole round. A guest phone never snapshots (the caller gates —
  /// a stray snapshot would haunt a later sign-up as a round they can't own).
  public func save(_ state: LiveRoundState) {
    guard state.active, let lr = state.lr else { return }
    var s = state
    s.ts = LiveFmt.now()
    if let data = try? enc.encode(s) { try? data.write(to: snapshotURL(lr), options: .atomic) }
  }

  /// Every snapshot on disk, newest first.
  public func snapshots() -> [LiveRoundState] {
    let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
    return files.filter { $0.lastPathComponent.hasPrefix("live-") }
      .compactMap { try? dec.decode(LiveRoundState.self, from: Data(contentsOf: $0)) }
      .filter { $0.lr != nil && !$0.players.isEmpty }
      .sorted { $0.ts > $1.ts }
  }

  /// Snapshot of one round, if any.
  public func snapshot(_ lr: UUID) -> LiveRoundState? {
    try? dec.decode(LiveRoundState.self, from: Data(contentsOf: snapshotURL(lr)))
  }

  /// `clearLiveCache(keep)`: every snapshot but one.
  public func clearSnapshots(keep: UUID?) {
    let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
    for f in files where f.lastPathComponent.hasPrefix("live-") {
      if let keep, f == snapshotURL(keep) { continue }
      try? FileManager.default.removeItem(at: f)
    }
  }

  public func removeSnapshot(_ lr: UUID) { try? FileManager.default.removeItem(at: snapshotURL(lr)) }

  // MARK: the write queue (`liveSync.q / saveQ`)

  public func queue(_ lr: UUID) -> [LiveMessage] {
    (try? dec.decode([LiveMessage].self, from: Data(contentsOf: queueURL(lr)))) ?? []
  }

  public func saveQueue(_ lr: UUID, _ q: [LiveMessage]) {
    let capped = Array(q.suffix(LiveDisk.queueCap))
    if let data = try? enc.encode(capped) { try? data.write(to: queueURL(lr), options: .atomic) }
  }

  public func removeQueue(_ lr: UUID) { try? FileManager.default.removeItem(at: queueURL(lr)) }

  // MARK: pending abandons (`PENDA_KEY`)

  public func pendingAbandons() -> [UUID] {
    (try? dec.decode([UUID].self, from: Data(contentsOf: abandonsURL))) ?? []
  }

  public func queueAbandon(_ id: UUID) {
    var q = pendingAbandons()
    if !q.contains(id) { q.append(id) }
    savePendingAbandons(Array(q.suffix(LiveDisk.abandonCap)))
  }

  public func savePendingAbandons(_ q: [UUID]) {
    if let data = try? enc.encode(q) { try? data.write(to: abandonsURL, options: .atomic) }
  }
}
