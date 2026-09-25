import Foundation

/// Existing read contracts, flattened while the app is alive. The extension has no credentials.
@MainActor public final class BetweenRoundsFeed {
  public static let shared = BetweenRoundsFeed()
  private var generation = UUID()
  private let svc: SupabaseService
  public init(svc: SupabaseService = .shared) { self.svc = svc }

  public func invalidate() { generation = UUID() }

  public func refresh(me: Me, preferredLeague: UUID?) async {
    guard let owner = me.profile?.id else { return }
    let defaults = UserDefaults(suiteName: CSAppGroup.id)
    guard DispatchSnapshot.belongs(to: owner, defaults: defaults) else { return }
    let epoch = defaults?.string(forKey: BetweenRoundsSnapshot.epochKey)
    let token = UUID(); generation = token
    let member = me.memberships.first { $0.league_id == preferredLeague && $0.season != nil }
      ?? me.memberships.first { $0.season != nil }
    async let race = attempt { try await self.loadRace(member) }
    async let tee = attempt { try await self.loadTee(owner: owner) }
    async let record = attempt { try await self.loadRecord(lastRound: me.profile?.last_round_id, owner: owner) }
    async let rival = attempt { try await self.loadRivalry() }
    let values = await (race, tee, record, rival)
    guard token == generation, !Task.isCancelled,
          DispatchSnapshot.belongs(to: owner, defaults: defaults),
          defaults?.string(forKey: BetweenRoundsSnapshot.epochKey) == epoch else { return }
    // Each successful read owns its own clock. A failed read keeps its OLD clock.
    var snapshot = BetweenRoundsSnapshot.read(defaults) ?? .init(owner: owner)
    if let value = values.0 { snapshot.race = value }
    if let value = values.1 { snapshot.nextTee = value }
    if let value = values.2 { snapshot.record = value }
    if let value = values.3 { snapshot.rivalry = value }
    snapshot.write(defaults, epoch: epoch)
  }

  private func attempt<T>(_ load: () async throws -> T?) async -> WidgetSlice<T>? where T: Codable & Sendable & Equatable {
    do { return WidgetSlice(try await load()) } catch { return nil }
  }

  private func loadRace(_ member: Me.Membership?) async throws -> BetweenRoundsSnapshot.Race? {
    guard let member, let season = member.season else { return nil }
    let raw = try await svc.call(Rpc.season_book(p_league_id: member.league_id, p_season_id: season.id))
    let book = try JSONDecoder().decode(SeasonBookSnapshot.self, from: JSONEncoder().encode(raw))
    try book.validate(league: member.league_id, season: season.id)
    return BetweenRoundsCopy.race(book)
  }
  private func loadTee(owner: UUID) async throws -> BetweenRoundsSnapshot.Tee? {
    let rows = try await ScheduleService(svc).watch()
    let candidates = rows.filter { $0.isMyPlan && $0.my_rsvp != "out" }
      .sorted { ($0.play_on ?? "", $0.tee_time ?? "99:99", $0.id?.uuidString ?? "") < ($1.play_on ?? "", $1.tee_time ?? "99:99", $1.id?.uuidString ?? "") }
    for row in candidates {
      guard let id = row.id, let day = row.play_on,
            let closing = BetweenRoundsCopy.closesAt(day: day, time: row.tee_time), closing > Date() else { continue }
      return BetweenRoundsCopy.tee(try await ScheduleService(svc).detail(id), owner: owner)
    }
    return nil
  }
  private func loadRecord(lastRound: UUID?, owner: UUID) async throws -> BetweenRoundsSnapshot.Record? {
    let achievements = try await YouRepository(svc).myAchievements()
    let milestone = achievements.filter { $0.round_id != nil && ["sub_80", "sub_90", "sub_100", "personal_best", "low_round", "first_round"].contains($0.kind ?? "") }
      .sorted { ($0.earned_on ?? "") > ($1.earned_on ?? "") }.first
    guard let id = milestone?.round_id ?? lastRound else { return nil }
    let receipt = ReceiptSeed.from(json: try await RoundsRepository(svc).roundCard(id))
    guard receipt.profileId == owner, let gross = receipt.gross, let holes = receipt.holesPlayed else { return nil }
    let card = await RoundScorecardService(svc).load(id, gross: gross, holesPlayed: holes)
    let headline = milestone.map { TrophyMeta.meta(kind: $0.kind, label: $0.label).title } ?? "Your last round."
    return .init(id: id, headline: headline, course: receipt.courseLabel.map(RoundCopy.course) ?? "Your round",
                 date: receipt.playedOn.map { CSDate.short($0) } ?? "", gross: gross, holes: holes,
                 out: card?.out, inn: card?.inn, earned: milestone != nil, company: receipt.playedWith.isEmpty ? nil : "with " + receipt.playedWith.map { CSBands.fn1($0) }.prefix(3).joined(separator: " · "))
  }
  private func loadRivalry() async throws -> BetweenRoundsSnapshot.Rivalry? {
    let rows = try await svc.call(Rpc.my_rivalries())
    // The deepest weekly history; stable identity breaks equal meeting counts.
    guard let row = rows.filter({ ($0.meetings ?? 0) > 0 && $0.opponent != nil })
      .sorted(by: { ($0.meetings ?? 0) == ($1.meetings ?? 0) ? ($0.opponent?.uuidString ?? "") < ($1.opponent?.uuidString ?? "") : ($0.meetings ?? 0) > ($1.meetings ?? 0) }).first,
      let opponent = row.opponent else { return nil }
    let weeks = try await svc.call(Rpc.rivalry_weeks(p_opponent: opponent))
    return BetweenRoundsCopy.rivalry(row, latest: weeks.sorted { ($0.wk ?? "") > ($1.wk ?? "") }.first)
  }
}

public enum BetweenRoundsCopy {
  public static func race(_ book: SeasonBookSnapshot) -> BetweenRoundsSnapshot.Race? {
    guard ["active", "cup_final", "complete"].contains(book.status) else { return nil }
    let rows = book.rows.filter { $0.kind == (book.hasSquads ? "squad" : "golfer") }
      .sorted { $0.points == $1.points ? $0.id < $1.id : $0.points > $1.points }
    guard let index = rows.firstIndex(where: \.mine), let leader = rows.first else { return nil }
    let mine = rows[index]
    let start = min(max(0, index - 1), max(0, rows.count - 3))
    let window = rows.dropFirst(start).prefix(3).map {
      BetweenRoundsSnapshot.Race.Row(id: $0.id, name: $0.mine && $0.kind == "golfer" ? "You" : $0.name,
        rank: $0.points_rank.map { ($0 > 9 ? "" : "0") + String($0) } ?? "—", points: $0.points, mine: $0.mine)
    }
    let gap = leader.points - mine.points
    let story = gap == 0 ? (mine.tied ? "Tied for the lead." : (book.hasSquads ? "Your squad leads." : "You lead.")) : "\(gap) back of \(leader.name)."
    let context = book.status == "complete" ? "Final points" : "Week \(book.current_week) · Cup points"
    return .init(league: book.league_id, name: book.name, context: context,
      standing: "\(mine.standing ?? "Unranked") of \(rows.count)", story: story, rows: Array(window))
  }

  public static func closesAt(day: String, time: String?, calendar: Calendar = ScheduleDates.gregorian) -> Date? {
    guard let date = CSDate.local(day, calendar: calendar), CSDate.iso(date, calendar: calendar) == day else { return nil }
    if let time {
      let bits = time.split(separator: ":").compactMap { Int($0) }
      guard bits.count >= 2, (0...23).contains(bits[0]), (0...59).contains(bits[1]) else { return nil }
      return calendar.date(bySettingHour: bits[0], minute: bits[1], second: 0, of: date)
    }
    return calendar.date(byAdding: .day, value: 1, to: date)
  }

  public static func tee(_ detail: RoundDetail, owner: UUID? = nil, now: Date = Date()) -> BetweenRoundsSnapshot.Tee? {
    guard detail.canRsvp, let day = detail.playOn, let date = CSDate.local(day),
          let close = closesAt(day: day, time: detail.teeTime), close > now else { return nil }
    let df = DateFormatter(); df.calendar = ScheduleDates.gregorian; df.dateFormat = "MMM"
    let month = df.string(from: date)
    let company = detail.rsvp.filter { $0.status == "in" && $0.profileId != nil && $0.profileId != owner }
      .map { CSBands.fn1($0.name) }.prefix(3).joined(separator: " · ")
    let time: String
    if detail.teeTime != nil { df.setLocalizedDateFormatFromTemplate("jmm"); time = df.string(from: close) }
    else { time = "Time to come" }
    return .init(id: detail.id, playOn: day, day: String(ScheduleDates.gregorian.component(.day, from: date)), month: month,
      dateLine: ScheduleDates.long(day), time: time, course: RoundCopy.course(detail.courseName), company: company,
      closesAt: close, status: detail.myRsvp, canReply: detail.canRsvp)
  }

  public static func rivalry(_ row: Rpc.my_rivalries.Row, latest: Rpc.rivalry_weeks.Row?) -> BetweenRoundsSnapshot.Rivalry? {
    guard let opponent = row.opponent, (row.meetings ?? 0) > 0 else { return nil }
    let name = CSBands.fn1(row.display_name)
    let story: String
    switch latest?.winner {
    case "me": story = "You took the last one."
    case "them": story = "\(name) took the last one."
    case "tie", "halve", "halved", "draw": story = "The last week was tied."
    default: story = RivalryCopy.leadLabel(wins: row.wins ?? 0, losses: row.losses ?? 0).capitalized + "."
    }
    return .init(opponent: opponent, name: name, scope: "Weekly clashes · All time", story: story,
      detail: latest?.wk.map { "Week of \(CSDate.short($0))" }, wins: row.wins ?? 0, losses: row.losses ?? 0, ties: row.ties ?? 0)
  }
}
