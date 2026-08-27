// Cup Season — the tee sheet data layer (spec/scheduled-rounds-arc.md).
//
// RPCs through `call` (the skew retry drops `declare_round`'s optional args on
// ANY error — the web did the same by message, 16712). The two Edge Functions
// (`courses`, `weather`) fail SOFT: the course search stands on the cache, and
// the weather chip hides on any miss — never a blank panel.

import Foundation
import Supabase

public struct ScheduleService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  // MARK: reads

  /// `my_schedule(p_from, p_to)` — the RPC does the visibility math.
  public func schedule(from: String, to: String) async throws -> [ScheduledRound] {
    try await svc.call(Rpc.my_schedule(p_from: from, p_to: to))
  }

  /// `loadSchedule` (15685): the visible month.
  public func month(_ m: CalendarMonth) async throws -> [ScheduledRound] {
    try await schedule(from: m.firstISO, to: m.lastISO)
  }

  /// `loadWatchList` (15706): a cursor-independent 14-day window, today → +14.
  public func watch(today: String = CSDate.today()) async throws -> [ScheduledRound] {
    let cal = ScheduleDates.gregorian
    guard let t = CSDate.local(today, calendar: cal), let e = cal.date(byAdding: .day, value: 14, to: t) else { return [] }
    return try await schedule(from: today, to: CSDate.iso(e, calendar: cal))
  }

  public func detail(_ id: UUID) async throws -> RoundDetail {
    guard let d = RoundDetail(try await svc.call(Rpc.round_detail(p_round: id))) else {
      throw RpcError(name: "round_detail", underlying: "Couldn’t load that round", droppedArgs: [])
    }
    return d
  }

  // MARK: writes

  /// `declare_round` (16704). `tee` is "HH:MM"; `courseId` stamps the cache row.
  public func declare(playOn: String, course: String, note: String, tagged: [UUID], tee: String?, courseId: String?) async throws -> UUID {
    try await svc.call(Rpc.declare_round(p_play_on: playOn, p_course: course, p_note: note, p_tagged: tagged, p_tee: tee, p_course_id: courseId))
  }

  public func scratch(_ id: UUID) async throws { _ = try await svc.call(Rpc.scratch_round(p_id: id)) }
  public func retag(_ id: UUID, tagged: [UUID]) async throws { _ = try await svc.call(Rpc.retag_round(p_id: id, p_tagged: tagged)) }
  public func rsvp(_ id: UUID, status: String) async throws { _ = try await svc.call(Rpc.set_round_rsvp(p_round: id, p_status: status)) }
  public func comment(_ id: UUID, body: String) async throws { _ = try await svc.call(Rpc.add_round_comment(p_round: id, p_body: body)) }

  // MARK: weather (Stage 5) — nil on ANY miss

  private struct WeatherBody: Encodable { let lat: Double?; let lon: Double?; let date: String; let course_id: String? }
  private struct WeatherReply: Decodable { let ok: Bool?; let unavailable: Bool?; let weather: Weather? }

  public func weather(lat: Double?, lon: Double?, date: String, courseId: String?) async -> Weather? {
    guard lat != nil || courseId != nil else { return nil }
    do {
      let r: WeatherReply = try await svc.client.functions.invoke("weather", options: .init(body: WeatherBody(lat: lat, lon: lon, date: date, course_id: courseId)))
      if r.unavailable == true { return nil }
      return r.weather
    } catch { return nil }
  }

  // MARK: week by week (14417)

  public func snapshots(season: UUID) async throws -> [WeekSnapshot] {
    try await svc.client.from("standings_snapshots").select("week_no, standings").eq("season_id", value: season).order("week_no").execute().value
  }

  private struct SquadRow: Decodable { let id: UUID; let name: String }
  public func squadNames(season: UUID) async throws -> [UUID: String] {
    let rows: [SquadRow] = try await svc.client.from("squads").select("id, name").eq("season_id", value: season).execute().value
    return Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0.name) })
  }

  // MARK: tag candidates (16627)

  private struct MemberRow: Decodable { struct P: Decodable { let display_name: String?; let marker: String? }; let profile_id: UUID?; let profile: P? }

  /// Accepted buddies + the current league's mates, deduped, minus you.
  public func tagCandidates(league: UUID?) async -> [TagCandidate] {
    var out: [TagCandidate] = []
    var seen = Set<UUID>()
    let me = await svc.currentSession()?.user.id
    if let friends = try? await svc.call(Rpc.my_friends()) {
      for f in friends where f.status == "accepted" {
        guard let id = f.profile_id, !seen.contains(id) else { continue }
        seen.insert(id); out.append(TagCandidate(id: id, name: f.display_name ?? "—", marker: f.marker))
      }
    }
    if let league {
      let rows: [MemberRow]? = try? await svc.client.from("league_members").select("profile_id, profile:profiles(display_name, marker)").eq("league_id", value: league).execute().value
      for m in rows ?? [] {
        guard let id = m.profile_id, id != me, !seen.contains(id) else { continue }
        seen.insert(id); out.append(TagCandidate(id: id, name: m.profile?.display_name ?? "—", marker: m.profile?.marker))
      }
    }
    return out
  }

  // MARK: course search (6784–6812) — cache first, then the API, merged

  private struct CacheRow: Decodable {
    let id: String; let club_name: String?; let course_name: String?; let city: String?; let state: String?
    let api_course_tees: [CourseTee]?
  }

  /// Our own cache answers instantly, costs no API call, and keeps working
  /// when the API doesn't.
  public func searchCache(_ q: String) async -> [CourseHit] {
    let safe = q.replacingOccurrences(of: "[,()%_*]", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    guard safe.count >= 3 else { return [] }
    let like = "%\(safe)%"
    do {
      let rows: [CacheRow] = try await svc.client.from("api_courses")
        .select("id, club_name, course_name, city, state, api_course_tees(tee_name, gender, course_rating, slope_rating, number_of_holes)")
        .or("course_name.ilike.\(like),club_name.ilike.\(like)").limit(12).execute().value
      return rows.map { CourseHit(id: $0.id, club: $0.club_name, course: $0.course_name, city: $0.city, state: $0.state, tees: $0.api_course_tees ?? []) }
        .filter { !$0.tees.isEmpty }
    } catch { return [] }
  }

  private struct SearchBody: Encodable { let action = "search"; let q: String }
  private struct RemoteCourse: Decodable { let id: String; let club_name: String?; let course_name: String?; let city: String?; let state: String?; let tees: [CourseTee]? }
  private struct SearchReply: Decodable { let courses: [RemoteCourse]? }

  /// `courses {action:'search', q}` — adds courses we have never seen.
  public func searchRemote(_ q: String) async throws -> [CourseHit] {
    let r: SearchReply = try await svc.client.functions.invoke("courses", options: .init(body: SearchBody(q: q)))
    return (r.courses ?? []).map { CourseHit(id: $0.id, club: $0.club_name, course: $0.course_name, city: $0.city, state: $0.state, tees: $0.tees ?? []) }
      .filter { !$0.tees.isEmpty }
  }

  /// Local first, remote deduped in, twelve at most (6810).
  public static func merge(local: [CourseHit], remote: [CourseHit]) -> [CourseHit] {
    let seen = Set(local.map(\.id))
    return Array((local + remote.filter { !seen.contains($0.id) }).prefix(12))
  }

  private struct CacheBody: Encodable { let action = "cache"; let id: String }

  /// `courses {action:'cache', id}` — fire and forget on a tee pick (6754).
  public func cacheCourse(_ id: String) async {
    try? await svc.client.functions.invoke("courses", options: .init(body: CacheBody(id: id)))
  }
}
