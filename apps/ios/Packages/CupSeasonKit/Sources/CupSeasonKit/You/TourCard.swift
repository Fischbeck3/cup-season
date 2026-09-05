// Cup Season — the Tour Card: any golfer's whole card (index.html
// `openTourCard` 13293–13457; `tour_card()` 20260726190000).
//
// Visibility is enforced server-side (shared league/event, accepted buddy, or
// discoverable=everyone) — `visible:false` is the whole answer. The buddy
// relationship is derived from `my_friends` (fetched alongside, not after);
// the mute set from `my_mutes`. The avatar is signed from the profile's
// `photo_path` when that row is readable; the marker is the floor.

import Foundation
import Supabase

public struct TourCard: Sendable {
  public struct Profile: Sendable, Equatable {
    public let id: UUID?
    public let displayName: String?
    public let handle: String?
    public let marker: String?
    public let city: String?
    public let homeCourse: String?
    public let indexCurrent: Double?
    public let ghin: String?
    public let memberSince: Date?
    public let isMe: Bool
  }
  /// D209 · ONE lens. `20260902180000_one_lens_on_the_tour_card.sql` moves
  /// `career.avg_pvi` onto the allowance number the You tab already speaks,
  /// adds `best_pvi` beside it, and preserves the old 100% average under the
  /// new name `avg_vs_index`. So the block carries BOTH shapes and says which
  /// one it is holding.
  ///
  /// The switch is the FIGURES, not the keys. A leagueless golfer has no row
  /// in `v_rounds_ranked` at all, so the new server sends the allowance keys
  /// as JSON null — four real profiles are in exactly that state — and
  /// switching on key presence alone would print a dash where a real number
  /// used to be. `playingLens` is therefore true only when an allowance
  /// figure actually arrived; otherwise the block falls back to the 100%
  /// average under the 100% label, and the phone never prints the You tab's
  /// words over a figure that is not the You tab's number.
  public struct CareerBlock: Sendable, Equatable {
    public let rounds: Int
    /// `career.best` — the OLD figure: the lowest round against the course
    /// rating. Lower is better, and it is not a delta against any number.
    /// Untouched by the migration; still the fallback's "best".
    public let best: Double?
    /// `career.avg_pvi` — the average against the PLAYING number. Nil on an
    /// old payload (where that key held the 100% figure, decoded into
    /// `avgVsIndex` instead) and nil for a golfer with no ranked rounds.
    public let avgPvi: Double?
    /// `career.best_pvi` — the best round against the PLAYING number (the max
    /// of the allowance figures, exactly as `Career.best` computes it on You).
    public let bestPvi: Double?
    /// The 100% average, `index_at_post − differential`: `avg_vs_index` on the
    /// new payload, `avg_pvi` on the old one. This is what the fallback row
    /// prints, and it is genuinely "vs your number".
    public let avgVsIndex: Double?
    /// true when an allowance figure actually arrived — see the note above
    public let playingLens: Bool

    public init(rounds: Int, best: Double?, avgPvi: Double?, bestPvi: Double? = nil,
                avgVsIndex: Double? = nil, playingLens: Bool = false) {
      self.rounds = rounds; self.best = best; self.avgPvi = avgPvi
      self.bestPvi = bestPvi; self.avgVsIndex = avgVsIndex; self.playingLens = playingLens
    }
  }
  /// R21 · one real trophy off the viewed golfer's own `trophies` rows. The
  /// table's RLS is self-only and stays self-only; `tour_card` is SECURITY
  /// DEFINER and has already decided this viewer may see this card, so it is
  /// the one place a case may be read from. Absent on a payload that predates
  /// R21, and the row simply does not render (L-44).
  public struct Cabinet: Sendable, Equatable, Identifiable {
    public let kind: String?
    public let title: String?
    public let subtitle: String?
    public let placement: String?
    public let seasonYear: Int?
    /// A calendar date as a String — never through an ISO parser (L-07).
    public let earnedOn: String?
    public var id: String { "\(kind ?? "")|\(title ?? "")|\(earnedOn ?? "")|\(seasonYear.map(String.init) ?? "")" }

    public init(kind: String?, title: String?, subtitle: String? = nil, placement: String? = nil,
                seasonYear: Int? = nil, earnedOn: String? = nil) {
      self.kind = kind; self.title = title; self.subtitle = subtitle
      self.placement = placement; self.seasonYear = seasonYear; self.earnedOn = earnedOn
    }

    /// "Cup · 2026" — the object, and the year it was won. A trophy with no
    /// title is not drawn; there is nothing honest to call it.
    public var line: String? {
      guard let t = title, !t.isEmpty else { return nil }
      return seasonYear.map { "\(t) · \($0)" } ?? t
    }
  }

  /// R21 · the best round as the sentence a golfer actually says: "74 at
  /// Troon North, May 3". Nil until R21 lands, and the row does not render.
  public struct BestRound: Sendable, Equatable {
    public let gross: Int
    public let courseLabel: String?
    /// A calendar date as a String (L-07).
    public let playedOn: String?
    public let differential: Double?

    public init(gross: Int, courseLabel: String?, playedOn: String?, differential: Double? = nil) {
      self.gross = gross; self.courseLabel = courseLabel
      self.playedOn = playedOn; self.differential = differential
    }

    /// "74 at Troon North, May 3" — each clause dropped rather than guessed.
    public var line: String {
      var s = String(gross)
      if let c = courseLabel, !c.isEmpty { s += " at \(RoundCopy.course(c))" }
      if let on = playedOn {
        let d = RivalryCopy.monthDaySpoken(on)
        if !d.isEmpty { s += ", \(d)" }
      }
      return s
    }
  }

  public struct Recent: Sendable, Equatable, Identifiable {
    public let playedOn: String
    public let courseLabel: String?
    public let gross: Int?
    public let differential: Double?
    public let holesPlayed: Int?
    public let beat: Bool?
    public var id: String { "\(playedOn)|\(gross ?? 0)|\(courseLabel ?? "")" }
  }
  /// D150 · a course this golfer has played, and how often. Returned by
  /// `tour_card` since D150 and DISCARDED by the phone ever since; IOS-032
  /// renders it.
  public struct Course: Sendable, Equatable, Identifiable {
    public let name: String
    public let rounds: Int
    /// A calendar date as a String (L-07).
    public let lastPlayed: String?
    public var id: String { name }
    public init(name: String, rounds: Int, lastPlayed: String? = nil) {
      self.name = name; self.rounds = rounds; self.lastPlayed = lastPlayed
    }
  }

  /// D150 · "you've both played Papago" — the reason two strangers start
  /// talking, fetched and thrown away until now.
  public struct SharedCourse: Sendable, Equatable, Identifiable {
    public let name: String
    public let mine: Int
    public let theirs: Int
    public var id: String { name }
    public init(name: String, mine: Int, theirs: Int) {
      self.name = name; self.mine = mine; self.theirs = theirs
    }
  }

  public struct VsYou: Sendable, Equatable {
    public let wins: Int, losses: Int, ties: Int
    public var total: Int { wins + losses + ties }
    public var record: String { RivalryCopy.record(wins: wins, losses: losses, ties: ties) }
    public var lead: String { RivalryCopy.leadLabel(wins: wins, losses: losses) }
    /// "VS YOU · 3–2 · YOU LEAD"
    public var chip: String { "VS YOU · \(record) · \(lead)" }
  }

  public let visible: Bool
  public let profile: Profile
  public let career: CareerBlock
  /// The MILESTONES, under the key they have always had (`achievements`).
  public let trophies: [Rpc.my_achievements.Row]
  /// R21 · the actual silverware (`trophies`). Empty until the migration lands.
  public let cabinet: [Cabinet]
  /// R21 · the lowest eighteen-hole gross, with where and when.
  public let bestRound: BestRound?
  public let recent: [Recent]
  public let vsYou: VsYou?
  /// D150 · the course history, and the overlap with mine.
  public let courses: [Course]
  public let sharedCourses: [SharedCourse]

  public static let privateLine = "This golfer keeps their card private, or you don’t share a league yet."

  /// The names of the courses you have both played, in the order the server
  /// ranks them (most of theirs first).
  public var sharedCourseNames: [String] { sharedCourses.map(\.name) }

  public static func parse(_ json: JSONValue) -> TourCard {
    let p = json["profile"], c = json["career"]
    let profile = Profile(
      id: p?["id"]?.string.flatMap(UUID.init), displayName: p?["display_name"]?.string, handle: p?["handle"]?.string,
      marker: p?["marker"]?.string, city: p?["city"]?.string, homeCourse: p?["home_course"]?.string,
      indexCurrent: p?["index_current"]?.double, ghin: p?["ghin"]?.string,
      memberSince: p?["member_since"]?.string.flatMap(Self.timestamp), isMe: p?["is_me"]?.bool ?? false)
    // Which SHAPE the server speaks is key presence; which LENS the card
    // wears is whether a figure actually came back. On the old payload
    // `avg_pvi` IS the 100% average, so it is decoded as `avgVsIndex` and the
    // allowance fields stay nil; on the new one the 100% figure has moved to
    // its own key and `avg_pvi` means what its name says.
    let newShape = c?["avg_vs_index"] != nil || c?["best_pvi"] != nil
    let avgPvi = newShape ? c?["avg_pvi"]?.double : nil
    let bestPvi = c?["best_pvi"]?.double
    let career = CareerBlock(rounds: c?["rounds"]?.int ?? 0, best: c?["best"]?.double, avgPvi: avgPvi,
                             bestPvi: bestPvi,
                             avgVsIndex: newShape ? c?["avg_vs_index"]?.double : c?["avg_pvi"]?.double,
                             playingLens: avgPvi != nil || bestPvi != nil)
    let trophies: [Rpc.my_achievements.Row] = (json["trophies"]?.array ?? []).compactMap { t in
      guard let data = try? JSONEncoder().encode(t) else { return nil }
      return try? JSONDecoder().decode(Rpc.my_achievements.Row.self, from: data)
    }
    let recent: [Recent] = (json["recent"]?.array ?? []).compactMap { r in
      guard let on = r["played_on"]?.string else { return nil }
      return Recent(playedOn: on, courseLabel: r["course_label"]?.string, gross: r["gross"]?.int, differential: r["differential"]?.double,
                    holesPlayed: r["holes_played"]?.int, beat: r["beat"]?.bool)
    }
    var vs: VsYou? = nil
    if let v = json["vs_you"], case .object = v {
      vs = VsYou(wins: v["wins"]?.int ?? 0, losses: v["losses"]?.int ?? 0, ties: v["ties"]?.int ?? 0)
    }
    // R21 · both are ABSENT-SAFE. A server that predates the migration sends
    // neither key and both rows stay off the page rather than printing a dash
    // over a fact nobody can read (L-44).
    let cabinet: [Cabinet] = (json["case"]?.array ?? []).compactMap { t in
      guard let title = t["title"]?.string, !title.isEmpty else { return nil }
      return Cabinet(kind: t["kind"]?.string, title: title, subtitle: t["subtitle"]?.string,
                     placement: t["placement"]?.string, seasonYear: t["season_year"]?.int,
                     earnedOn: t["earned_on"]?.string)
    }
    var best: BestRound? = nil
    if let b = c?["best_round"], case .object = b, let g = b["gross"]?.int {
      best = BestRound(gross: g, courseLabel: b["course_label"]?.string,
                       playedOn: b["played_on"]?.string, differential: b["differential"]?.double)
    }
    let courses: [Course] = (json["courses"]?.array ?? []).compactMap { c in
      guard let n = c["name"]?.string, !n.isEmpty else { return nil }
      return Course(name: n, rounds: c["rounds"]?.int ?? 0, lastPlayed: c["last_played"]?.string)
    }
    let shared: [SharedCourse] = (json["shared_courses"]?.array ?? []).compactMap { c in
      guard let n = c["name"]?.string, !n.isEmpty else { return nil }
      return SharedCourse(name: n, mine: c["mine"]?.int ?? 0, theirs: c["theirs"]?.int ?? 0)
    }
    return TourCard(visible: json["visible"]?.bool ?? false, profile: profile, career: career,
                    trophies: trophies, cabinet: cabinet, bestRound: best, recent: recent, vsYou: vs,
                    courses: courses, sharedCourses: shared)
  }

  /// A Postgres timestamptz as jsonb writes it (with or without fractional
  /// seconds). This is an instant, not a calendar date, so ISO parsing is right.
  static func timestamp(_ s: String) -> Date? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: s) { return d }
    f.formatOptions = [.withInternetDateTime]
    if let d = f.date(from: s) { return d }
    // "2026-07-06 14:03:11.12345+00" — the space form
    let g = DateFormatter(); g.locale = Locale(identifier: "en_US_POSIX"); g.timeZone = TimeZone(secondsFromGMT: 0)
    for fmt in ["yyyy-MM-dd HH:mm:ss.SSSSSSxx", "yyyy-MM-dd HH:mm:ssxx", "yyyy-MM-dd'T'HH:mm:ss.SSSSSSxx"] {
      g.dateFormat = fmt
      if let d = g.date(from: s) { return d }
    }
    return nil
  }

  /// "est. Aug 2026" — month + year of an instant. The word is "est." on every
  /// surface (Y-26); "Member since" is retired.
  public static func monthYear(_ d: Date, calendar: Calendar = .current) -> String {
    let f = DateFormatter(); f.calendar = calendar; f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "MMM yyyy"
    // non-breaking: "Jul 2026" is one fact and never breaks across two lines
    return f.string(from: d).replacingOccurrences(of: " ", with: "\u{00A0}")
  }

  /// "est. Aug 2026" — the one form of the founding date, for the credential
  /// and for settings alike. A retyped copy is the version that will drift.
  public static func established(_ d: Date, calendar: Calendar = .current) -> String { "est.\u{00A0}" + monthYear(d, calendar: calendar) }

  // MARK: - the Career block, its figures and the words that name them

  /// D209 · true once the server sends the allowance figures.
  public var playingLens: Bool { career.playingLens }

  /// The best round. Under the allowance lens it is a delta and signs like
  /// every other figure on the card; before it, the old course score, which
  /// runs the other way and is never given a `+`.
  public var bestText: String {
    career.playingLens ? (career.bestPvi.map(RoundCopy.signed) ?? "—") : (career.best.map(RoundCopy.f1) ?? "—")
  }
  /// Under the lens, the allowance average; before it, the 100% one — which
  /// is a real number for a golfer no season has ever ranked, and the reason
  /// this row does not go to a dash the day the migration lands.
  public var avgText: String {
    (career.playingLens ? career.avgPvi : career.avgVsIndex).map(RoundCopy.signed) ?? "—"
  }

  /// D209 · the lens is named ONCE, in the section's eyebrow, instead of being
  /// buried in every row label. Before the allowance keys arrive the block
  /// holds two different measurements and there is no single lens to name, so
  /// the eyebrow stays bare and the rows keep their own words.
  public static func careerEyebrow(playingLens: Bool, isMe: Bool) -> String {
    guard playingLens else { return careerTitle }
    return careerTitle + " · " + (isMe ? YouCopy.vsPlayingNumber : RoundCopy.theirs(YouCopy.vsPlayingNumber))
  }
  public static let careerTitle = "Career"
  public static let roundsLabel = "Rounds"

  // MARK: - The PERSON page's own rows (IOS-032, IA §10.3)
  //
  // The page is the sheet promoted to a destination, and these are the five
  // rows the design draws down its left edge. Each renders only when its fact
  // arrived: TROPHIES and BEST wait on R21, YOU AND HIM on R4, THIS SEASON on
  // the shared season. A row with no fact is not drawn as a dash.

  public static let rowYouAndThem = "YOU AND THEM"
  public static let rowThisSeason = "THIS SEASON"
  public static let rowLastFive   = "LAST FIVE"
  public static let rowBest       = "BEST"
  public static let rowTrophies   = "TROPHIES"

  /// "YOU AND GALEN" — the row label with the name in it, which is what the
  /// page actually prints; the bare form above is the fallback for a card
  /// whose profile carries no name.
  public static func youAndThem(_ name: String?) -> String {
    guard let n = name, !n.isEmpty else { return rowYouAndThem }
    return "YOU AND \(n.uppercased())"
  }

  /// The three lengths, R-F's ruling: asked as one step, never guessed, all
  /// three always offered. The words are the owner's.
  public enum Length: String, Sendable, CaseIterable {
    case saturday, week, season
    public var label: String {
      switch self {
      case .saturday: "This Saturday"
      case .week:     "One week"
      case .season:   "A season"
      }
    }
    /// What each one lands on. Every one of these is an object that already
    /// exists — R-F's own condition — and the sheet never names the object.
    public var sub: String {
      switch self {
      case .saturday: "A round on the tee sheet, with them in it"
      case .week:     "A one-week head-to-head"
      case .season:   "A season with them in it"
      }
    }
  }
  /// A golfer whose card is empty. One true sentence beats three em dashes,
  /// and it is not an apology — it is the state, and the state is normal for
  /// somebody who joined this week (L-44, L-32's voice).
  public static func noRoundsYet(_ name: String?) -> String {
    let who = (name?.isEmpty == false) ? name! : "This golfer"
    return "\(who) hasn’t posted a round yet. Their card fills in from the first one."
  }

  public static let lengthsHead = "PLAY THEM"
  public static let lengthsSub = "How long do you want it to run?"

  /// Under the lens this is the You tab's own row, word for word
  /// (`YouCopy.bestRound`), so the two surfaces read as one number.
  public static func bestLabel(playingLens: Bool) -> String {
    playingLens ? YouCopy.bestRound : "Best round vs course"
  }
  /// The tail of "Avg vs your playing number" lives in the eyebrow above it;
  /// the old figure keeps the whole label, because the old figure is a
  /// different number.
  public static func avgLabel(playingLens: Bool, isMe: Bool) -> String {
    playingLens ? "Avg" : "Avg vs \(isMe ? "your" : "their") number"
  }

  /// The two OLD figures run opposite ways — a course score where lower wins
  /// sits beside a delta where `+` wins — and one table cannot sign both the
  /// same way. So the table says which is which. It goes with them.
  public static func careerSignsLine(isMe: Bool) -> String {
    "Lower is better against the course; against \(isMe ? "your" : "their") number, + is better."
  }
}

/// The buddy relationship with the card's golfer, from `my_friends`.
public enum BuddyRelation: Sendable, Equatable {
  case none
  case friend
  case incoming(friendshipId: UUID)
  case requested

  public static func from(_ friends: [Rpc.my_friends.Row], profile: UUID) -> BuddyRelation {
    guard let f = friends.first(where: { $0.profile_id == profile }) else { return .none }
    if f.status == "accepted" { return .friend }
    if f.incoming == true, let fid = f.friendship_id { return .incoming(friendshipId: fid) }
    return .requested
  }

  /// The button label, when there is one to tap.
  public var actionLabel: String? {
    switch self {
    case .none: "Add buddy"
    case .incoming: "Accept buddy request"
    case .friend, .requested: nil
    }
  }
  /// The settled tag, when there is nothing to tap.
  public var tag: String? {
    switch self {
    case .friend: "Buddies"
    case .requested: "Requested"
    default: nil
    }
  }
}

public struct TourCardLoad: Sendable {
  public let card: TourCard
  public let relation: BuddyRelation
  public let muted: Bool
  public let avatarURL: URL?
}

public struct TourCardRepository: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  private struct PhotoRow: Decodable { let photo_path: String? }

  /// `tour_card` + `my_friends` + `my_mutes` in parallel; the avatar best-effort.
  public func load(_ profileId: UUID) async throws -> TourCardLoad {
    async let cardJSON = svc.call(Rpc.tour_card(p_profile: profileId))
    async let friends: [Rpc.my_friends.Row] = (try? await svc.call(Rpc.my_friends())) ?? []
    async let mutes: [UUID] = (try? await svc.call(Rpc.my_mutes())) ?? []
    async let avatar: URL? = signedAvatar(profileId)
    let card = TourCard.parse(try await cardJSON)
    return TourCardLoad(card: card, relation: BuddyRelation.from(await friends, profile: profileId),
                        muted: await mutes.contains(profileId), avatarURL: await avatar)
  }

  private func signedAvatar(_ profileId: UUID) async -> URL? {
    let rows: [PhotoRow]? = try? await svc.client.from("profiles").select("photo_path").eq("id", value: profileId).execute().value
    guard let path = rows?.first?.photo_path, !path.isEmpty else { return nil }
    return try? await svc.client.storage.from("media").createSignedURL(path: path, expiresIn: 3600)
  }

  /// `friend_request` → "friend" (they had asked first) or "requested".
  public func friendRequest(_ profileId: UUID) async throws -> BuddyRelation {
    let r = try await svc.call(Rpc.friend_request(p_profile: profileId))
    return r == "friend" ? .friend : .requested
  }

  public func acceptRequest(_ friendshipId: UUID) async throws {
    _ = try await svc.call(Rpc.friend_respond(p_id: friendshipId, p_accept: true))
  }

  public func setMute(_ profileId: UUID, on: Bool) async throws {
    _ = try await svc.call(Rpc.set_mute(p_profile: profileId, p_on: on))
  }

  /// D59 moderation: lands on the founder desk.
  public func reportPhoto(_ profileId: UUID) async throws {
    _ = try await svc.call(Rpc.report_content(p_post: nil, p_reason: "profile photo", p_kind: "profile_photo", p_profile: profileId))
  }

  /// P-17 · a report about a GOLFER rather than about one photo, with the
  /// reason the reporter picked. Same endpoint, same desk (L-38).
  public func report(_ profileId: UUID, reason: String) async throws {
    _ = try await svc.call(Rpc.report_content(p_post: nil, p_reason: reason, p_kind: "profile", p_profile: profileId))
  }

  public func rivalryWeeks(_ opponent: UUID) async throws -> [Rpc.rivalry_weeks.Row] {
    try await svc.call(Rpc.rivalry_weeks(p_opponent: opponent))
  }

  public func setRivalryName(_ opponent: UUID, name: String) async throws {
    _ = try await svc.call(Rpc.set_rivalry_name(p_opponent: opponent, p_name: name))
  }
}
