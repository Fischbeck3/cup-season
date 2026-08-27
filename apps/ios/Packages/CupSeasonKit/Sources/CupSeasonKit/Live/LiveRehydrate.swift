// Cup Season — resume, merge, and the guest's door (index.html 7488–7580,
// 7604–7706, 7749–7856, 7881–7941).
//
// Resume precedence: an ACTIVE in-memory round > this device's snapshot
// (not in the pending-abandon list) > the server's open `live_rounds`
// (member RLS) ∪ `my_visitor_rounds()`; rounds older than 2 days are ignored
// — a golf round is hours, not days. Every arriving edit (broadcast or the
// reconcile pull) applies ONLY if newer — LWW per cell — so replays and stale
// queue flushes can never regress a card.

import Foundation

public enum LiveMerge {
  /// `liveRecv` for one cell: apply if newer. Returns true when the card changed.
  @discardableResult
  public static func apply(_ m: LiveMessage, to s: inout LiveRoundState) -> Bool {
    s.ensureClocks()
    let cts = m.cts
    if m.t == "score" {
      guard let pid = m.pid, let pmap = s.pmap, let pi = pmap.firstIndex(of: pid), let h1 = m.h else { return false }
      let h = h1 - 1
      guard h >= 0, h < 18, pi < s.scores.count else { return false }
      if s.scts[pi][h] >= cts { return false }
      s.scores[pi][h] = m.s
      s.scts[pi][h] = cts
      return true
    }
    if m.t == "wolf" {
      guard let h1 = m.h else { return false }
      let h = h1 - 1
      guard h >= 0, h < 18 else { return false }
      if s.wcts[h] >= cts { return false }
      s.wolf[h] = LiveWolfPick(m.w)
      s.wcts[h] = cts
      return true
    }
    return false
  }

  /// `liveRecvState`: the whole round, merged cell by cell. Returns the
  /// round's status when it is no longer live (the caller ends it), else nil.
  public static func applyState(_ d: JSONValue, to s: inout LiveRoundState) -> String? {
    guard let round = d["round"], !round.isNull else { return nil }
    if let id = round["id"]?.string.flatMap(UUID.init), let lr = s.lr, id != lr { return nil }
    if let st = round["status"]?.string, st != "live" { return st }
    s.ensureClocks()
    for sc in d["scores"]?.array ?? [] {
      guard let pid = sc["player_id"]?.string.flatMap(UUID.init), let pmap = s.pmap, let pi = pmap.firstIndex(of: pid),
            let h1 = sc["hole"]?.int else { continue }
      let h = h1 - 1
      guard h >= 0, h < 18, pi < s.scores.count else { continue }
      let cts = Int64(sc["cts"]?.double ?? 0)
      if s.scts[pi][h] >= cts { continue }
      s.scores[pi][h] = sc["strokes"].flatMap { $0.isNull ? nil : $0.int }
      s.scts[pi][h] = cts
    }
    if case .object(let gs) = round["game_state"] ?? .null {
      for (k, v) in gs {
        guard k.hasPrefix("h"), let n = Int(k.dropFirst()), n >= 1, n <= 18, !v.isNull else { continue }
        let h = n - 1
        let cts = v["cts"]?.string.flatMap(LiveMerge.parseMs) ?? 0
        if s.wcts[h] >= cts { continue }
        s.wolf[h] = LiveWolfPick(v["v"])
        s.wcts[h] = cts
      }
    }
    return nil
  }

  /// `Date.parse(iso)` in ms, tolerant of Postgres' timestamptz text.
  public static func parseMs(_ iso: String) -> Int64? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: iso) { return Int64(d.timeIntervalSince1970 * 1000) }
    f.formatOptions = [.withInternetDateTime]
    if let d = f.date(from: iso) { return Int64(d.timeIntervalSince1970 * 1000) }
    // "2026-08-27 18:10:00.123+00"
    var t = iso.replacingOccurrences(of: " ", with: "T")
    if t.range(of: #"[+-]\d\d$"#, options: .regularExpression) != nil { t += ":00" }
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: t) { return Int64(d.timeIntervalSince1970 * 1000) }
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: t).map { Int64($0.timeIntervalSince1970 * 1000) }
  }
}

public enum LiveRehydrator {
  /// A still-'live' round older than this is an abandoned one (7657).
  public static let maxAge: TimeInterval = 2 * 24 * 3600

  static func idxByName(_ players: [LivePlayer]) -> (String) -> Int? {
    { nm in players.firstIndex { $0.n == nm } }
  }

  /// Sides and the wolf order from a `game_config` (7541–7553).
  static func configure(_ s: inout LiveRoundState, cfg: JSONValue?) {
    let byName = idxByName(s.players)
    if s.game == .match || s.game == .sunningdale {
      let a = (cfg?["side_a"]?.array ?? []).compactMap { $0.string.flatMap(byName) }
      let b = (cfg?["side_b"]?.array ?? []).compactMap { $0.string.flatMap(byName) }
      if !a.isEmpty, !b.isEmpty { s.teams = [a, b] } else { s.teams = LiveRoundState.defaultTeams(count: s.players.count) }
    } else { s.teams = LiveRoundState.defaultTeams(count: s.players.count) }
    if s.game == .wolf {
      let ord = (cfg?["order"]?.array ?? []).compactMap { $0.string.flatMap(byName) }
      s.wolfOrder = ord.count == s.players.count ? ord : [0, 1, 2, 3]
    }
    s.stake = cfg?["stake"]?.double ?? cfg?["unit"]?.double ?? 0
    s.mode = cfg?["mode"]?.string == "solo" ? .solo : .teams
  }

  /// `applyServerRound(mine, myPid)` (7502): a `live_rounds` row (member read
  /// or `my_visitor_rounds`) → the round, seats and course card.
  public static func fromServerRow(_ row: JSONValue, myPid: UUID?) -> LiveRoundState? {
    let players = (row["live_round_players"]?.array ?? []).sorted { ($0["position"]?.int ?? 0) < ($1["position"]?.int ?? 0) }
    guard !players.isEmpty else { return nil }
    let seats: [LivePlayer] = players.map { pl in
      if let mid = pl["member_id"]?.string.flatMap(UUID.init) {
        let prof = pl["member"]?["profile"]
        let pid = pl["member"]?["profile_id"]?.string.flatMap(UUID.init)
        let me = pid != nil && pid == myPid
        return LivePlayer(n: prof?["display_name"]?.string ?? "Member", i: (prof?["index_current"]?.double).flatMap { $0 == 0 ? nil : $0 } ?? 18,
                          ci: 1, guest: false, mid: mid, pid: pid, me: me, locked: me, team: "—")
      }
      let gpid = pl["guest_profile_id"]?.string.flatMap(UUID.init)
      return LivePlayer(n: pl["guest_name"]?.string ?? "Guest", i: (pl["guest_index"]?.double).flatMap { $0 == 0 ? nil : $0 } ?? 18,
                        ci: -1, guest: true, est: pl["index_source"]?.string == "estimated", pid: gpid, me: gpid != nil && gpid == myPid, team: nil)
    }
    let cfg = row["game_config"]
    let snap = row["course_snapshot"]
    let course = LiveCourseCard.from(snapshot: snap, courseLabel: row["course_label"]?.string, siEstimated: cfg?["si_estimated"]?.bool ?? false)
    var s = LiveRoundState.fresh(players: seats, course: course)
    s.stage = .live; s.active = true
    s.game = LiveGame(server: row["game"]?.string)
    s.holes = snap?["holes"]?.int == 9 ? 9 : 18
    s.code = row["join_code"]?.string
    s.lr = row["id"]?.string.flatMap(UUID.init)
    s.leagueId = row["league_id"]?.string.flatMap(UUID.init)
    s.pmap = players.compactMap { $0["id"]?.string.flatMap(UUID.init) }
    s.visitor = row["visitor"]?.bool ?? false
    // D86: whose round? started_by is a league_members.id — resolve it through the round's OWN player rows
    let startedBy = row["started_by"]?.string.flatMap(UUID.init)
    let starter = players.first { $0["member_id"]?.string.flatMap(UUID.init) == startedBy && startedBy != nil }
    if let starter { s.mine = starter["member"]?["profile_id"]?.string.flatMap(UUID.init) == myPid } else { s.mine = true }
    s.host = starter?["member"]?["profile"]?["display_name"]?.string
    configure(&s, cfg: cfg)
    return s
  }

  /// Overlay this device's strokes, picks and clocks for that id (7562–7577).
  public static func overlay(local cc: LiveRoundState, onto s: inout LiveRoundState) {
    guard cc.scores.count == s.players.count else { return }
    s.scores = cc.scores
    if cc.wolf.count == 18 { s.wolf = cc.wolf }
    if cc.scts.count == s.players.count { s.scts = cc.scts }
    if cc.wcts.count == 18 { s.wcts = cc.wcts }
    if cc.holes == 9 { s.holes = 9 }
    s.hole = max(0, min(s.liveHoles - 1, cc.hole))
  }

  /// `enterGuestLive(d, token, {signedIn})` (7881): the pencil's round from a
  /// `guest_live_state` pull. The pull's scores merge through `LiveMerge`.
  public static func guestRound(_ d: JSONValue, token: UUID, signedIn: Bool) -> (state: LiveRoundState, guest: LiveGuestContext)? {
    guard let round = d["round"], !round.isNull else { return nil }
    let players = (d["players"]?.array ?? []).sorted { ($0["position"]?.int ?? 0) < ($1["position"]?.int ?? 0) }
    guard !players.isEmpty else { return nil }
    let me = d["me"]?.string.flatMap(UUID.init)
    let seats: [LivePlayer] = players.map { pl in
      if let mid = pl["member_id"]?.string.flatMap(UUID.init) {
        return LivePlayer(n: pl["display_name"]?.string ?? "Member", i: (pl["index_current"]?.double).flatMap { $0 == 0 ? nil : $0 } ?? 18,
                          ci: 1, guest: false, mid: mid, pid: nil, me: false, team: "—")
      }
      return LivePlayer(n: pl["guest_name"]?.string ?? "Guest", i: (pl["guest_index"]?.double).flatMap { $0 == 0 ? nil : $0 } ?? 18,
                        ci: -1, guest: true, est: pl["index_source"]?.string == "estimated", pid: nil,
                        me: pl["id"]?.string.flatMap(UUID.init) == me && me != nil, team: nil)
    }
    let cfg = round["game_config"]
    let snap = round["course_snapshot"]
    let course = LiveCourseCard.from(snapshot: snap, courseLabel: round["course_label"]?.string, siEstimated: cfg?["si_estimated"]?.bool ?? false)
    var s = LiveRoundState.fresh(players: seats, course: course)
    s.stage = .live; s.active = true
    s.game = LiveGame(server: round["game"]?.string)
    s.holes = snap?["holes"]?.int == 9 ? 9 : 18
    s.code = round["join_code"]?.string
    // D87: never "Continue your round" — it is someone else's tee sheet
    s.mine = false; s.host = nil
    s.lr = round["id"]?.string.flatMap(UUID.init)
    s.leagueId = round["league_id"]?.string.flatMap(UUID.init)
    s.pmap = players.compactMap { $0["id"]?.string.flatMap(UUID.init) }
    configure(&s, cfg: cfg)
    return (s, LiveGuestContext(token: token, me: me, signedIn: signedIn))
  }

  public struct Outcome: Sendable {
    public var state: LiveRoundState?
    public var toast: String?
    /// the local snapshot was for a round that is already over
    public var retired = false
  }

  static func age(_ row: JSONValue) -> TimeInterval? {
    guard let s = row["started_at"]?.string, let ms = LiveMerge.parseMs(s) else { return nil }
    return Date().timeIntervalSince1970 - Double(ms) / 1000
  }

  /// `rehydrateLiveRound` (7604). `current` is the in-memory round, if any.
  public static func run(current: LiveRoundState?, myPid: UUID?, repo: LiveRepository = LiveRepository(), disk: LiveDisk = .shared) async -> Outcome {
    if let c = current, c.active, c.stage == .live, c.lr != nil {
      await disk.save(c)
      return Outcome(state: c)
    }
    await repo.drainAbandons(disk: disk)
    let dead = Set(await disk.pendingAbandons())

    // 1) LOCAL-FIRST — resume from this device's full snapshot, no network.
    var out = Outcome()
    var resumed = false
    if var local = await disk.snapshots().first(where: { $0.lr != nil && !dead.contains($0.lr!) }) {
      local.stage = .live; local.active = true
      local.hole = max(0, min(local.liveHoles - 1, local.hole))
      local.ensureClocks()
      out.state = local
      out.toast = local.mine ? "Continue your round — tap the banner on Home" : "You’re on a live tee sheet — tap the banner on Home"
      resumed = true
    }

    // 2) SERVER — validate / cover a fresh device. Never let a transient error wipe a good local resume.
    guard myPid != nil else { return out }
    var rounds: [JSONValue]
    do { rounds = try await repo.openRounds() } catch {
      print("[live-resume] server query failed: \(error.localizedDescription)")
      return out
    }
    let seen = Set(rounds.compactMap { $0["id"]?.string })
    for r in await repo.visitorRounds() where r["id"]?.string != nil && !seen.contains(r["id"]!.string!) { rounds.append(r) }

    let mineList = rounds.filter { r in
      guard let id = r["id"]?.string.flatMap(UUID.init), !dead.contains(id) else { return false }
      let inIt = (r["live_round_players"]?.array ?? []).contains { p in
        p["member"]?["profile_id"]?.string.flatMap(UUID.init) == myPid || p["guest_profile_id"]?.string.flatMap(UUID.init) == myPid
      }
      guard inIt else { return false }
      if let a = age(r) { return a < maxAge }
      return true
    }
    let openIds = Set(mineList.compactMap { $0["id"]?.string.flatMap(UUID.init) })
    let mine = mineList.first

    if resumed, let st = out.state {
      if let lr = st.lr, openIds.contains(lr) {
        // D85: a pre-sync snapshot has no channel key — the server row does
        if st.code == nil, let srv = mineList.first(where: { $0["id"]?.string.flatMap(UUID.init) == lr }), let code = srv["join_code"]?.string {
          out.state?.code = code
          if let s = out.state { await disk.save(s) }
        }
        return out
      }
      // the local round is finished / gone — retire it, then fall through
      await disk.clearSnapshots(keep: nil)
      out = Outcome(state: nil, toast: "That round was already finished", retired: true)
    }
    if let mine, var s = fromServerRow(mine, myPid: myPid), let lr = s.lr {
      if let cc = await disk.snapshot(lr) { overlay(local: cc, onto: &s) }
      await disk.clearSnapshots(keep: lr)
      out.state = s
      out.toast = !s.mine
        ? (s.host.map { "\(LiveFmt.fn1($0)) put you on the tee sheet — tap the banner on Home" } ?? "You’re on a live tee sheet — tap the banner on Home")
        : "Continue your round — tap the banner on Home"
    } else if mine == nil {
      await disk.clearSnapshots(keep: nil)
    }
    return out
  }
}
