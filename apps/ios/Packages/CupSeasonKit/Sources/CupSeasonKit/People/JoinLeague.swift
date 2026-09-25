// Cup Season — join by code (audit 02 §1.3 E; index.html 15176–15220,
// 17257–17267, 17313–17318, 17560–17575).
//
// Three entrances on the web, one RPC at the end (`join_league`). The phone
// keeps the same keys (`cs_code`, `cs_code_name`) so a code that arrives by
// Universal Link before sign-in is consumed after the card gate, exactly as
// `resumeAfterProfile` does it — and is REMOVED before the attempt so a
// failure can never loop.

import Foundation

public enum JoinIntent {
  public static let codeKey = "cs_code"
  public static let nameKey = "cs_code_name"

  /// Codes are typed in any case; the RPCs compare upper (15198).
  public static func normalize(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
  }

  public static func store(_ code: String, name: String? = nil, defaults: UserDefaults = .standard) {
    defaults.set(normalize(code), forKey: codeKey)
    if let name { defaults.set(name, forKey: nameKey) } else { defaults.removeObject(forKey: nameKey) }
  }

  public static func pending(defaults: UserDefaults = .standard) -> (code: String, name: String?)? {
    guard let c = defaults.string(forKey: codeKey), !c.isEmpty else { return nil }
    return (c, defaults.string(forKey: nameKey))
  }

  /// A late acceptance must not consume a newer invitation.
  public static func clear(ifMatching code: String, defaults: UserDefaults = .standard) {
    guard let pending = pending(defaults: defaults), normalize(pending.code) == normalize(code) else { return }
    clear(defaults: defaults)
  }

  public static func clear(defaults: UserDefaults = .standard) {
    defaults.removeObject(forKey: codeKey)
    defaults.removeObject(forKey: nameKey)
  }

  /// `/?join=CODE` (17560): the only query the app claims besides `?claim=`.
  public static func code(from url: URL) -> String? {
    guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
          let v = items.first(where: { $0.name == "join" })?.value, !v.isEmpty else { return nil }
    return normalize(v)
  }
}

/// `league_by_code` returns `text` that is NULL for an unknown code (15202–15204).
/// The generator maps a scalar return to a non-optional; this declaration
/// keeps the null so "no league" and "the RPC failed" stay distinguishable.
struct LeagueByCodeCall: RpcCall {
  static let name = "league_by_code"
  static let optionalArgs: [String] = []
  typealias Returns = String?
  let p_code: String
}

/// `join_covenant_info` + R9 (D225; IA §6.4; CORE_FLOWS §5.1).
///
/// L-12: EVERY join passes the covenant, at every stake INCLUDING $0. Both
/// clients failed open at $0 (`JoinService.covenant` returned nil unless the
/// stake was above zero), so a golfer joining a free season never met the Pro,
/// the length, the rules or the ending. It renders now, always.
///
/// THE SIX ADDED FACTS, and every one of them is READ, never assumed:
///
///   1 · WHO      the Pro's name and who else is in       `roster`
///   2 · WHEN     the first tee                           `starts_on`
///   3 · HOW LONG the number of weeks                     `weeks`
///   4 · THE RULE "best three a month count"              `counting_cap`
///   5 · THE SPLIT what the stake buys, above $0 only     `split`
///   6 · THE PAY  that there is somewhere to send it      `has_pay_note` / `buy_in_due_on`
///
/// Facts 1–5 come from R9 and reach SIGNED-IN callers only, with the anon
/// signature unchanged (`join_covenant_info` is one of L-45's twelve anon
/// endpoints and none of this may ride that path). Fact 6 was on the payload all
/// along and was dropped on the floor by this initialiser.
///
/// L-44 · A FACT WITH NO READ RENDERS NOTHING. Every added field is optional and
/// every line producer returns nil when its fact is absent, so a client that
/// ships ahead of the migration shows exactly the covenant it shows today.
public struct Covenant: Sendable, Equatable, Identifiable {
  public var id: String { name }
  public let name: String
  public let buyinCents: Int
  public let preset: String?
  public let floor: Int
  public let finish: String?
  public let structure: String?

  // R9
  public let proName: String?
  public let rosterCount: Int?
  public let rosterNames: [String]
  public let startsOn: String?
  public let weeks: Int?
  public let countingCap: Int?
  public let split: Split?
  public let hasPayNote: Bool?
  public let buyInDueOn: String?
  /// D161/D112 — where the league stands before the OTP.
  public let phase: String?
  /// D353 · the allowance every points figure is scored at (`index × allowance
  /// / 100`, D178). nil = not in the payload (an older server); never guessed.
  public let handicapAllowance: Int?
  /// D353 · `true` = the league counts every round (a stored cap of NULL). A
  /// real boolean, so Unlimited is distinguishable from "not in the payload".
  public let everyRoundCounts: Bool?
  /// D353 · the last day of the season, when the payload carries it.
  public let endsOn: String?
  /// D375 · which season this yes is for; whether the golfer is a member
  /// being asked again (a re-up); whether the yes is already on record; and
  /// their own finish last season when the server could compute it (L-44).
  public let seasonNumber: Int?
  public let reup: Bool?
  public let agreed: Bool?
  public let lastSeason: LastSeason?

  public struct LastSeason: Sendable, Equatable {
    public let myRank: Int?
    public let of: Int?
    public let myPoints: Double?
    public init(myRank: Int?, of: Int?, myPoints: Double?) { self.myRank = myRank; self.of = of; self.myPoints = myPoints }
  }

  public struct Split: Sendable, Equatable {
    public let champion: Int
    public let runnerUp: Int
    public let pointsKing: Int
    public init(champion: Int, runnerUp: Int, pointsKing: Int) {
      self.champion = champion; self.runnerUp = runnerUp; self.pointsKing = pointsKing
    }
  }

  public init(name: String, buyinCents: Int, preset: String?, floor: Int, finish: String?,
              proName: String? = nil, rosterCount: Int? = nil, rosterNames: [String] = [],
              startsOn: String? = nil, weeks: Int? = nil, countingCap: Int? = nil,
              split: Split? = nil, hasPayNote: Bool? = nil, buyInDueOn: String? = nil, phase: String? = nil,
              handicapAllowance: Int? = nil, everyRoundCounts: Bool? = nil, endsOn: String? = nil,
              seasonNumber: Int? = nil, reup: Bool? = nil, agreed: Bool? = nil, lastSeason: LastSeason? = nil, structure: String? = nil) {
    self.structure = structure
    self.name = name; self.buyinCents = buyinCents; self.preset = preset; self.floor = floor; self.finish = finish
    self.proName = proName; self.rosterCount = rosterCount; self.rosterNames = rosterNames
    self.startsOn = startsOn; self.weeks = weeks; self.countingCap = countingCap
    self.split = split; self.hasPayNote = hasPayNote; self.buyInDueOn = buyInDueOn; self.phase = phase
    self.handicapAllowance = handicapAllowance; self.everyRoundCounts = everyRoundCounts; self.endsOn = endsOn
    self.seasonNumber = seasonNumber; self.reup = reup; self.agreed = agreed; self.lastSeason = lastSeason
  }

  public init?(_ v: JSONValue) {
    guard case .object = v else { return nil }
    let roster = v["roster"]
    let sp = v["split"]
    self.init(name: v["name"]?.string ?? "this league",
              buyinCents: v["buyin_cents"]?.int ?? Int(v["buyin_cents"]?.string ?? "") ?? 0,
              preset: v["preset"]?.string,
              floor: v["floor"]?.int ?? Int(v["floor"]?.string ?? "") ?? 0,
              finish: v["finish"]?.string,
              proName: roster?["pro_name"]?.string,
              rosterCount: roster?["count"]?.int,
              rosterNames: (roster?["names"]?.array ?? []).compactMap { $0.string },
              startsOn: v["starts_on"]?.string,
              weeks: v["weeks"]?.int,
              countingCap: v["counting_cap"]?.int,
              split: sp.flatMap { s in
                guard let c = s["champion"]?.int, let r = s["runner_up"]?.int, let k = s["points_king"]?.int else { return nil }
                return Split(champion: c, runnerUp: r, pointsKing: k)
              },
              hasPayNote: v["pay"]?["has_note"]?.bool ?? v["has_pay_note"]?.bool,
              buyInDueOn: v["pay"]?["due_on"]?.string ?? v["buy_in_due_on"]?.string,
              phase: v["phase"]?.string,
              handicapAllowance: v["handicap_allowance"]?.int,
              everyRoundCounts: v["every_round_counts"]?.bool,
              endsOn: v["ends_on"]?.string,
              seasonNumber: v["season_number"]?.int,
              reup: v["reup"]?.bool,
              agreed: v["agreed"]?.bool,
              lastSeason: v["last_season"].flatMap { ls in
                guard case .object = ls else { return nil }
                return LastSeason(myRank: ls["my_rank"]?.int, of: ls["of"]?.int, myPoints: ls["my_points"]?.double)
              }, structure: v["structure"]?.string)
  }

  /// `Math.round(buyin_cents/100)`
  public var usd: Int { Int((Double(buyinCents) / 100).rounded()) }
  public var paid: Bool { buyinCents > 0 }
  /// How many of the crew the WHO line names before it counts the rest. R9
  /// returns at most this many, so the client never has more to say than the
  /// payload gave it.
  public static let namesShown = 6

  // MARK: - the six facts, as sentences. A missing fact renders NOTHING (L-44).

  /// 1 · WHO COMES BEFORE THE MONEY. "Galen runs the season (the Pro). Marcus,
  /// Dev and two more are in." D132's noun, finally DEFINED at first contact.
  public var whoLine: String? {
    var parts: [String] = []
    if let pro = proName?.trimmingCharacters(in: .whitespaces), !pro.isEmpty {
      parts.append("\(pro) runs the season (the Pro).")
    }
    let named = rosterNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
      .prefix(Self.namesShown).map { CSBands.fn1($0) }
    if !named.isEmpty {
      // the count includes the Pro, so the unnamed remainder is count − 1 − named
      let rest = max(0, (rosterCount ?? (named.count + 1)) - 1 - named.count)
      let list: String
      if rest > 0 {
        list = named.joined(separator: ", ") + " and \(rest) more"
      } else if named.count == 1 {
        list = named[0]
      } else {
        list = named.dropLast().joined(separator: ", ") + " and " + named[named.count - 1]
      }
      parts.append("\(list) \(named.count == 1 && rest == 0 ? "is" : "are") in.")
    } else if rosterCount == 1, proName != nil {
      // One golfer in, and it is the Pro. True, and not a lie about a crew.
      parts.append("Nobody else yet.")
    }
    return parts.isEmpty ? nil : parts.joined(separator: " ")
  }

  /// 2 + 3 · "Thirteen weeks from Saturday, Sep 12." Either half alone still
  /// says something true; neither renders a guess.
  public var lengthLine: String? {
    // SeasonStoryCopy.word and LeagueDates.dowMonDay are the PRODUCERS — a
    // second number-word table or a second date format would be exactly the
    // drift §4's check 27 forbids.
    let weeksText: String? = weeks.map {
      SeasonStoryCopy.cap(SeasonStoryCopy.word($0)) + " week" + ($0 == 1 ? "" : "s")
    }
    switch (weeksText, startsOn) {
    case let (.some(w), .some(d)): return "\(w) from \(LeagueDates.dowMonDay(d))."
    case let (.some(w), .none):    return "\(w)."
    case let (.none, .some(d)):    return "First tee \(LeagueDates.dowMonDay(d))."
    default: return nil
    }
  }

  /// 4 · "Standard rules: honest scores, best three a month count, two a month
  /// keeps you in." The rounds that count is R9's; the payload's `floor` is the
  /// OTHER number and always was.
  ///
  /// D353 · and the two rules that were unsayable: an Unlimited league says
  /// "every round counts" (off the payload's real boolean, never off an absent
  /// key), and the allowance says what every points figure is scored at, in
  /// the wizard's own words (`WizardCopy.rulesLine`: "95 percent of your
  /// index"), so the Pro's agreement and the joiner's covenant read alike.
  public var rulesLine: String? {
    var clauses: [String] = ["honest scores"]
    if everyRoundCounts == true { clauses.append("every round counts") }
    else if let c = countingCap { clauses.append("best \(SeasonStoryCopy.word(c)) a month count") }
    if floor > 0, structure != "solo" { clauses.append("\(SeasonStoryCopy.word(floor)) a month keeps you in") }
    // D373 · the clause says what the allowance does, in R-M's shape — verbatim
    // with the web's `csCovenantFacts` rules clause (tests/app-tests.js "D373")
    if let a = handicapAllowance { clauses.append("scored against your playing HCP — your index at \(a) percent") }
    let head = presetLine.map { "\($0) rules: " } ?? "The rules: "
    return head + clauses.joined(separator: ", ") + "."
  }

  /// The ending, in D126's own words rather than a dial name.
  public var endingLine: String {
    if finish == "points_table" { return "The season's points decide it. No reset." }
    if finish == "cup_final", structure == "squads2" { return "Both squads play a four-week Cup Final, scored fresh. The leading squad carries a 10-point head start." }
    if finish == "cup_final", let structure {
      return structure == "solo" ? "The top two golfers qualify for a four-week Cup Final, scored fresh." : "The top two squads qualify for a four-week Cup Final, scored fresh."
    }
    if finish == "cup_final" { return "It ends with a four-week Cup Final between the top two." }
    return "The season’s ending will appear here when its rules are set."
  }

  /// 5 · "If you take it: sixty percent to the champion, twenty-five to the
  /// runner-up, fifteen to the points king." ABOVE $0 ONLY (L-10), and the trio
  /// is the Pro's own, printed rather than assumed.
  public var splitLine: String? {
    guard paid, let s = split else { return nil }
    var awards: [String] = []
    if s.champion > 0 { awards.append("\(s.champion) percent to the champion") }
    if s.runnerUp > 0 { awards.append("\(s.runnerUp) percent to the runner-up") }
    if s.pointsKing > 0 { awards.append("\(s.pointsKing) percent to the Points King, the individual season-points leader") }
    return awards.isEmpty ? nil : "The split: " + awards.joined(separator: "; ") + "."
  }

  /// 6 · that there is somewhere to send it. A BOOLEAN and a DATE — never the
  /// note itself, which is D129's fail-closed rule and is not weakened here.
  public var payLine: String? {
    guard paid else { return nil }
    let due = buyInDueOn.map { " by \(LeagueDates.dowMonDay($0))" } ?? ""
    if hasPayNote == true { return "The Pro has said how to pay\(due). You'll see it on the pot." }
    if hasPayNote == false { return "The Pro hasn't said how to pay yet. It'll be on the pot when they do." }
    return nil
  }

  // MARK: - the money block, above $0 only (L-10, L-09, L-11)

  /// "$50 each."
  public var stakeLine: String? { paid ? "$\(usd) each." : nil }
  /// L-09 · verbatim from the constant, never retyped.
  public var potLine: String? { paid ? MoneyCopy.ledger : nil }

  /// The button. At $0 it names the season rather than a number.
  /// `csCovenantButton`: a re-up says which season the yes is for.
  public var joinLabel: String {
    if isReUp, let n = seasonNumber { return paid ? "I’m in for season \(n) — $\(usd)" : "I’m in for season \(n)" }
    return paid ? "Join — I’m in for $\(usd)" : "Join \(name)"
  }

  // MARK: - D375 · the re-up frame (twins of csCovenantIsReUp / Title / Eyebrow)

  public var isReUp: Bool { reup == true && (seasonNumber ?? 0) > 1 }
  /// `csCovenantEyebrow`
  public var eyebrow: String { isReUp ? "SAME RULES — EVERYTHING BEFORE YOU TAP" : "EVERYTHING BEFORE YOU TAP" }
  /// The stop when the yes is already on record — the sheet shows this and no join.
  public var alreadyInLine: String { ReUpCopy.alreadyIn(seasonNumber: seasonNumber) }
  /// 0 · which season this yes is for, said first when it is not the first;
  /// the golfer's own finish last season renders only when the server could
  /// compute it (L-44). Twin of the desk's `csCovenantFacts` season fact.
  public var seasonLine: String? {
    guard let n = seasonNumber, n > 1 else { return nil }
    var t = "Season \(n)."
    if let ls = lastSeason, let rank = ls.myRank, rank > 0, let of = ls.of, of > 0 {
      t += " Last season you finished \(CSCopy.ordinal(rank)) of \(of)"
      if let p = ls.myPoints { t += " with \(CSCopy.points(p)) point\(p == 1 ? "" : "s")" }
      t += "."
    }
    return t
  }
  public static let notNow = "Not now"

  /// The starter clause, above $0 AND below it, whenever the joiner has fewer
  /// than three posted rounds: `score_round` reaches `profiles.index_current`
  /// before its own-differential fallback, so a starter number really does score
  /// the first cards, and a golfer joining the night before a first tee is
  /// entitled to know that before she taps (D124).
  public static let starterClause = "With no posted rounds your starter number scores your first cards until three of your own take over."
  public static func starterLine(postedRounds: Int?) -> String? {
    guard let n = postedRounds, n < 3 else { return nil }
    return starterClause
  }

  /// "Standard"
  public var presetLine: String? { preset.map { $0.prefix(1).uppercased() + $0.dropFirst() } }
  /// "2 rounds / mo"
  public var floorLine: String? { floor > 0 ? "\(floor) round\(floor == 1 ? "" : "s") / mo" : nil }
  /// "Points table crowns it" / "Cup Final · final 4 weeks"
  public var finishLine: String { finish == "points_table" ? "Points table crowns it" : "Cup Final · final 4 weeks" }
  /// "$50 / player · on the pot" — kept for the row form.
  public var buyinLine: String { "$\(usd) / golfer · on the books" }   // T-12: "pot" retires

  /// The head, and the order the screen draws the facts in. WHO comes before the
  /// money, and that order is a value rather than the way a View happens to be
  /// written.
  /// `csCovenantTitle`: "Season 2 of the Fellas" for a re-up, else the first-join head.
  public var head: String { isReUp && seasonNumber != nil ? "Season \(seasonNumber!) of \(name)" : "Before you join \(name)" }
  public enum Fact: String, Sendable, Equatable, CaseIterable { case season, who, length, structure, rules, ending, stake, ledger, split, pay, starter }
  /// Every fact this covenant can actually say, in order. A fact with no read is
  /// simply not in the list (L-44) — which is what makes "absent facts render
  /// nothing" a test rather than a promise.
  public func facts(postedRounds: Int? = nil) -> [(Fact, String)] {
    var out: [(Fact, String)] = []
    if let s = seasonLine { out.append((.season, s)) }
    if let s = whoLine    { out.append((.who, s)) }
    if let s = lengthLine { out.append((.length, s)) }
    if let structure {
      out.append((.structure, structure == "solo" ? "Every golfer plays for their own place." : structure == "squads2" ? "Two squads. Your round points contribute to your squad’s season." : "Squads compete together. Your round points contribute to your squad’s season."))
    }
    if let s = rulesLine  { out.append((.rules, s)) }
    out.append((.ending, endingLine))
    if let s = stakeLine  { out.append((.stake, s)) }
    if let s = potLine    { out.append((.ledger, s)) }
    if let s = splitLine  { out.append((.split, s)) }
    if let s = payLine    { out.append((.pay, s)) }
    if let s = Self.starterLine(postedRounds: postedRounds) { out.append((.starter, s)) }
    return out
  }
}

public struct JoinService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// nil = no league with that code. Throws when the lookup itself failed.
  public func leagueName(_ code: String) async throws -> String? {
    try await svc.call(LeagueByCodeCall(p_code: JoinIntent.normalize(code)))
  }

  /// THE GATE, AND IT IS NEVER OPTIONAL (L-12, D225).
  ///
  /// This returned nil unless the stake was above $0, so a golfer joining a
  /// FREE season never met the Pro, the length, the rules or the ending — the
  /// covenant's whole job, skipped on the most common league in the product.
  /// It now returns a covenant whenever the payload decodes, at every stake,
  /// and throws when the read fails (fail-closed, as it always did): a stake
  /// that goes unnamed is exactly what S3-01 exists to prevent.
  public func covenant(_ code: String) async throws -> Covenant {
    let info = try await svc.call(Rpc.join_covenant_info(p_code: JoinIntent.normalize(code)))
    guard let c = Covenant(info) else {
      throw RpcError(name: "join_covenant_info", underlying: "Couldn’t read the terms — try again.", droppedArgs: [])
    }
    return c
  }

  /// D351 (built) · the covenant for an INVITATION, by its own id.
  ///
  /// The first cut read `leagues.code` and then called the code door — a read
  /// `leagues_read` refuses an invitee, so it could not succeed for its only
  /// caller. `join_covenant_for_invite` (20261026090000 + 20261029090000)
  /// resolves the league through the invitation itself, returns the SAME
  /// object the code door returns, and never the code.
  ///
  /// Three answers, because two of them look alike if collapsed:
  ///   `.terms`        · read them; the join waits on the tap
  ///   `.notADoor`     · the invitation is answered, or somebody else's, or an
  ///                     event with no terms to read (the caller knows which)
  ///   `.notAvailable` · the server has not got the function: FAIL-CLOSED —
  ///                     nothing is accepted, the invitation is kept
  /// Anything else throws, and the caller says so without seating anybody.
  public enum CovenantRead: Sendable, Equatable {
    case terms(Covenant)
    case notADoor
    case notAvailable
  }
  struct JoinCovenantForInviteCall: RpcCall {
    static let name = "join_covenant_for_invite"
    static let optionalArgs: [String] = []
    typealias Returns = JSONValue
    let p_invite: UUID
  }
  public func covenantForInvite(_ inviteId: UUID) async throws -> CovenantRead {
    let json: JSONValue
    do { json = try await svc.call(JoinCovenantForInviteCall(p_invite: inviteId)) }
    catch {
      if (error as? RpcError)?.isMissingFunction == true { return .notAvailable }
      throw error
    }
    if json.isNull { return .notADoor }
    guard let c = Covenant(json) else {
      throw RpcError(name: JoinCovenantForInviteCall.name, underlying: "Couldn’t read the terms — try again.", droppedArgs: [])
    }
    return .terms(c)
  }
  public static let termsNotAvailable = "The terms can’t be read on this server yet. Nothing was accepted — try again after the update."
  public static let invitationAnswered = "That invitation was already answered — nothing changed."

  /// `join_league` → the league id.
  public func join(_ code: String) async throws -> UUID {
    try await svc.call(Rpc.join_league(p_code: JoinIntent.normalize(code)))
  }

  /// Error copy (17150, 15338): an "invalid" code reads as the Pro's problem.
  public static func joinError(_ error: Error) -> String {
    let m = ((error as? LocalizedError)?.errorDescription ?? String(describing: error)).lowercased()
    return m.contains("invalid") ? "No league with that code. Check with your Pro" : HumanError.text(error, prefix: "Could not join.")
  }
}
