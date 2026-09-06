// Cup Season — the wizard's dials, ladders and copy, verbatim from index.html:
//   state + ladders        3768–3800   (STAKES, DURS, CAPS, durLabel, durMonths)
//   the preset cards       3228–3245   PRESET_SUMMARY 7997, PRESETS 8150
//   the dials' copy        3248–3312   (setrow labels, ihelp, seg notes)
//   season dates           7081–7099   (defaultStart, seasonEndDate, renderSeasonDates)
//   structure fit          11812–11835 (STRUCT_MIN, STRUCT_NOTES, renderStructFit)
//   the portrait           11847–11890 (wizPortrait)
//   the lock call          17194–17248 (lockBylaws → lock_league, D111)
//   applyBylaws            14144–14175 (run it back / an existing league)
//   codeFor                12815
// Nothing here talks to the network; WizardService does.

import Foundation

/// `state` as the wizard reads it. Stake in DOLLARS (the lock writes cents).
public struct WizardDials: Sendable, Equatable {
  /// D225 · the ladder, plus **Other**. $20 was impossible: the rungs are fixed
  /// and there was no field. `otherStake` is the escape hatch and the ladder is
  /// otherwise unchanged — L-11 keeps $0 (bragging rights) selected.
  public static let stakes = [0, 25, 50, 75, 100, 150, 200]
  /// M4 · **THE DATABASE'S OWN CEILING, IN DOLLARS.**
  /// `league_settings_buyin_range` (20260901220000:77-79, applied in production)
  /// is `buyin_cents >= 0 and buyin_cents <= 20000`. Both Other fields clamped
  /// to 10,000 DOLLARS and both send `stake × 100`, so a Pro who typed 250 got
  /// a raw check-constraint message out of `lock_league` — AFTER `create_league`
  /// had already run, leaving exactly the unlocked founder-alone husk D225
  /// exists to remove. The ladder's own top rung is this number; nothing else
  /// may offer more than the database will take.
  public static let maxStake = 200
  /// The four the wizard OFFERS as chips, in D225's order. Everything else on
  /// the ladder is still reachable through the stepper in More settings.
  public static let stakeChips = [0, 25, 50, 100]
  public static let otherLabel = "Other"
  public static let braggingRights = "Bragging rights"
  public static let durs = [2, 3, 4, 5, 6, 8, 10, 13, 17, 22, 26, 39, 52]
  public static let caps = Bylaws.capLabels
  public static let capVals = Bylaws.capVals
  public static let structures = ["solo", "squads2", "squads3", "squads4"]
  public static let structLabels = ["solo": "Solo", "squads2": "2 Squads", "squads3": "3 Squads", "squads4": "4 Squads"]
  public static let structNames = Bylaws.structNames
  public static let structMin = Bylaws.structMin
  public static let structNotes = [
    "solo": "Individual · everyone for themselves — works at any size (2+). No squads; the top two meet in the Cup Final in the final four weeks.",   // LV-18
    "squads2": "2 squads · fits 4–7 players. Both squads reach the Cup Final; the regular-season leader carries a +10 head start.",
    "squads3": "3 squads · fits 6+. Cut line after 2nd: top 2 advance.",
    "squads4": "4 squads · the full cup experience for 8+ players.",
  ]
  /// The wizard offers only these two (3272–3275); snake/live are stored values a league may carry (S4-02).
  public static let draftTypes = ["random", "assign"]
  public static let draftLabels = ["random": "Random draw", "assign": "Assign"]
  public static let draftNotes = [
    "random": "Random draw: the server shuffles every joined player into squads and posts the reveal. Argument-proof.",
    "assign": "Assign: no draw. You place each player onto a squad yourself, like teams picked in the group chat.",
  ]
  public static let finishes = ["cup_final", "points_table"]
  public static let finishLabels = ["cup_final": "Cup Final", "points_table": "Points table"]
  public static let finishNotes = [
    "cup_final": "Cup Final: the last four weeks reset and score fresh — top seeds only, whoever’s hottest takes the cup.",
    "points_table": "Points table: whoever leads when the season ends takes the cup. The whole year is the race — no reset.",
  ]
  public static let payouts: [[Int]] = [[60, 25, 15], [70, 20, 10], [50, 30, 20]]
  public static let payLabels = ["60,25,15": "Balanced", "70,20,10": "Winner-heavy", "50,30,20": "Spread it"]
  public static let payNotes = [
    "60,25,15": "Balanced: champ 60% · runner-up 25% · Points King 15%.",
    "70,20,10": "Winner-heavy: champ 70% · runner-up 20% · Points King 10%.",
    "50,30,20": "Spread it: champ 50% · runner-up 30% · Points King 20%.",
  ]

  /// `PRESETS` (8150–8154): the cap as a NUMBER (nil = unlimited) · floor · name.
  /// D142: Standard counts the best 3, Cutthroat the best 2, Casual everything.
  public struct Preset: Sendable, Equatable {
    public let cap: Int?
    public let floor: Int
    public let name: String
    public let lead: String
    public let line: String
    /// The stepper slot for this preset's cap.
    public var capIdx: Int { Bylaws.capIndex(cap) }
  }
  /// M-15: verification is described as what the league asks of a golfer,
  /// never as something the engine checks ("GHIN-verified" was a claim the
  /// app cannot make — ship audit 2026-08-31).
  /// D225 / L-16 · THE CARDS STOP NAMING DIALS. "95% hcp · post what you'd post
  /// to GHIN · best 3 / mo count · 2-round floor" recited four dials on a card
  /// a golfer meets before they have met any of them — a live L-16 violation on
  /// the shipping client. Each card is ONE SENTENCE now, and the wording is
  /// TERMINOLOGY §2.3's own cell, cited rather than restated. `line` survives as
  /// the empty string so nothing that reads it breaks; the dials themselves are
  /// all still there, verbatim, behind **More settings** (P-6: complexity is
  /// hidden, never deleted).
  public static let presets = [
    Preset(cap: nil, floor: 0, name: "Casual", lead: "Honest scores, and everything counts.", line: ""),
    Preset(cap: 3, floor: 2, name: "Standard", lead: "The default. Honest scores, light guardrails.", line: ""),
    Preset(cap: 2, floor: 3, name: "Cutthroat", lead: "Tight. Vouched where you can, and the screws in.", line: ""),
  ]
  public static let presetSummary = [
    "Casual: 100% handicap, honor-system scores, any course. Beer-league friendly — everything counts, nobody’s benched.",
    "Standard: 95% handicap, post what you’d post to GHIN, your best 3 a month count, post 2 or the squad feels it. The default for a reason.",
    "Cutthroat: 90% handicap, vouched by the group where you can and the Pro rules on the rest, rated tees, best 2 a month, a 3-round floor. For crews that want the screws tight.",
  ]
  /// The DB's own words for the three presets (14890–14895).
  public static let presetKeys = ["casual", "standard", "cutthroat"]
  public static let verificationKeys = ["honor", "attested", "ghin"]
  public static let penaltyKeys = ["none", "deduct", "forfeit"]

  public var name: String
  public var preset: Int
  public var stake: Int
  public var durWeeks: Int
  /// "" = the default first tee (next Saturday), like `state.startISO` before the date input is touched.
  public var startISO: String
  public var structure: String
  public var draftType: String
  public var finish: String
  public var payout: [Int]
  public var cap: Int
  public var floor: Int
  /// D225 / R18 · how they pay you. REQUIRED above $0, and written in the SAME
  /// TRANSACTION as the publish (L-41) — `set_buy_in_terms` has zero call sites
  /// on the phone, so a Pro on iOS could not record it at all and two persona
  /// walks ended owing money with nowhere to look.
  public var buyInNote: String = ""
  /// The golfers picked in step 1. Each becomes an `invite_golfer` on publish —
  /// NOT `add_friend_to_league`, which seats a golfer with no covenant
  /// (CORE_FLOWS §0 A-1; L-12).
  public var invitees: [UUID] = []
  /// QB-13 · **HOW MANY OF YOU ARE THERE.** The number the organiser knows
  /// before she opens the app, and the one number the wizard never learned.
  ///
  /// Squads-or-solo, the pot maths, the structure-fit line and the "four opens
  /// squads" hint all derived from who was ALREADY INSTALLED, which for a new
  /// organiser is always exactly one — so a six-person Saturday league minted
  /// solo and step 3 printed "One in makes $50" for a season its own link had
  /// just been texted to six people. The wizard asks now, at step 1, before
  /// anything derives from a roster of one.
  ///
  /// It is a COUNT, not a roster: it seats nobody, invites nobody and mints
  /// nothing. It sizes what the wizard SAYS, and — only when the organiser
  /// then answers the squads question out loud — what the wizard MINTS. D206
  /// ruled against squads-for-one *by derivation*, and that ruling stands:
  /// `squadsChosen` is still nil unless somebody taps it.
  public var expectedRoster: Int? = nil

  /// `resetWizard` (13885): a REAL league starts at bragging rights (S2-03).
  /// D206: 13 weeks by default (a quarter — one whole calendar month is
  /// guaranteed, so the floor and the cap both get to matter); D142: the cap
  /// slot is Standard's "Best 3".
  public init(name: String = "", preset: Int = 1, stake: Int = 0, durWeeks: Int = 13, startISO: String = "",
              structure: String = "squads2", draftType: String = "random", finish: String = "cup_final",
              payout: [Int] = [60, 25, 15], cap: Int = Bylaws.capIndex(3), floor: Int = 2) {
    self.name = name; self.preset = preset; self.stake = stake; self.durWeeks = durWeeks; self.startISO = startISO
    self.structure = structure; self.draftType = draftType; self.finish = finish; self.payout = payout
    self.cap = cap; self.floor = floor
  }

  // MARK: the presets (7163–7172)

  public mutating func applyPreset(_ i: Int) {
    let p = Self.presets[max(0, min(2, i))]
    preset = max(0, min(2, i)); cap = p.capIdx; floor = p.floor
  }
  /// `toast(pr.name+' rules locked for the season')`
  public var presetToast: String { "\(Self.presets[preset].name) rules locked for the season" }
  public var presetSummaryText: String { Self.presetSummary[preset] }

  // MARK: the steppers (7104–7112)

  static func step(_ arr: [Int], _ cur: Int, _ dir: Int) -> Int {
    guard let i = arr.firstIndex(of: cur) else { return arr.first ?? cur }
    let j = i + dir
    return (j >= 0 && j < arr.count) ? arr[j] : cur
  }
  public mutating func stepStake(_ dir: Int) { stake = Self.step(Self.stakes, stake, dir) }
  public mutating func stepLength(_ dir: Int) { durWeeks = Self.step(Self.durs, durWeeks, dir) }
  public mutating func stepCap(_ dir: Int) { cap = max(0, min(Self.caps.count - 1, cap + dir)) }
  public mutating func stepFloor(_ dir: Int) { floor = max(0, min(4, floor + dir)) }

  /// `#stakeVal`: "None" at $0, else "$75".
  public var stakeText: String { stake == 0 ? "None" : PotMath.dollars(stake) }
  /// `durLabel`
  public var lengthText: String { LeagueDates.durLabel(durWeeks) }
  public var capText: String { Bylaws.capLabel(capN) }
  public var floorText: String { "\(floor) / mo" }
  public var capN: Int? { Self.capVals[max(0, min(Self.capVals.count - 1, cap))] }
  public var solo: Bool { structure == "solo" }

  // MARK: - D225 · what the wizard asks, and what it derives

  /// THE STRUCTURE IS DERIVED, NOT ASKED. Solo at two, a question at four or
  /// more. This kills `squads2`-minted-for-a-roster-of-one (D206) and the
  /// "2 Squads selected and greyed out at the same time" state in one move.
  public static func derivedStructure(roster n: Int, squadsChosen: Bool?) -> String {
    guard n >= (structMin["squads2"] ?? 4) else { return "solo" }
    return (squadsChosen ?? false) ? "squads2" : "solo"
  }
  /// The question is only worth asking at four or more.
  public static func asksAboutSquads(roster n: Int) -> Bool { n >= (structMin["squads2"] ?? 4) }
  /// "Two is a season. Four opens squads." — derived from `structMin`, never a
  /// literal.
  public static var rosterHint: String {
    "\(WizardCopy.numberWord(structMin["solo"] ?? 2).capitalized) is a season. "
      + "\(WizardCopy.numberWord(structMin["squads2"] ?? 4).capitalized) opens squads."
  }

  /// The ONE required field the wizard gains. Above $0 with no note, **Start
  /// the season** is disabled and the field says why.
  public var payNoteMissing: Bool {
    stake > 0 && buyInNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  public var canPublish: Bool { !payNoteMissing }

  /// The name, pre-filled from the roster and asked LAST. "Galen & Jerecho" at
  /// two; the crew's own shape above that. Never minted for them — the field
  /// opens with this in it and the golfer may type over it.
  public static func suggestedName(_ names: [String]) -> String {
    let firsts = names.map { CSBands.fn1($0) }.filter { !$0.isEmpty }
    switch firsts.count {
    case 0: return ""
    case 1: return firsts[0]
    case 2: return "\(firsts[0]) & \(firsts[1])"
    default: return "\(firsts[0]), \(firsts[1]) & \(firsts.count - 2) more"
    }
  }
  public var payKey: String { payout.map(String.init).joined(separator: ",") }
  public var structNote: String { Self.structNotes[structure] ?? "" }
  public var draftNote: String { Self.draftNotes[draftType] ?? Self.draftNotes["random"]! }
  public var finishNote: String { Self.finishNotes[finish] ?? Self.finishNotes["cup_final"]! }
  public var payNote: String { Self.payNotes[payKey] ?? Self.payNotes["60,25,15"]! }

  // MARK: season dates (7081–7099)

  /// `defaultStart()` — the next upcoming Saturday, never today.
  public static func defaultStart(today: String = CSDate.today(), calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(today, calendar: calendar) else { return today }
    let dow = calendar.component(.weekday, from: d) - 1     // 0 = Sunday, like JS getDay()
    var add = (6 - dow + 7) % 7
    if add == 0 { add = 7 }
    return LeagueDates.addDays(today, add, calendar: calendar)
  }

  /// QB-06 · **THE SAME SATURDAY, BUT NOT TOMORROW'S.**
  ///
  /// The first tee is the most consequential default in the product: the rules
  /// freeze there AND the invite link closes there (L-18). On a Friday night
  /// "the next upcoming Saturday" is TOMORROW, so an organiser with nobody in
  /// yet was handed, unmarked, a season that gave her crew less than 27 hours
  /// to find the App Store — and the link would have died before anyone
  /// tapped it, with nothing anywhere to say why.
  ///
  /// So a season **whose roster is still just the organiser** starts at the
  /// first Saturday at least two weeks out. A season that already has people
  /// in it keeps the near Saturday, which is the guess that made a blind
  /// walker say the app had read his mind. Both are Saturdays; only the
  /// distance changes, and the golfer can move it either way.
  public static func defaultStart(today: String = CSDate.today(), roster: Int,
                                  calendar: Calendar = .current) -> String {
    let near = defaultStart(today: today, calendar: calendar)
    guard roster <= 1 else { return near }
    var d = near
    while (CSDate.days(from: today, to: d) ?? 99) < 14 { d = LeagueDates.addDays(d, 7, calendar: calendar) }
    return d
  }

  /// The roster this season is being built for: everyone picked, plus me, and
  /// never fewer than the count the organiser gave at step 1.
  public var plannedRoster: Int { max(1 + invitees.count, expectedRoster ?? 0) }

  public func startDate(today: String = CSDate.today()) -> String {
    startISO.isEmpty ? Self.defaultStart(today: today, roster: plannedRoster) : startISO
  }
  /// `seasonEndDate()` — start + N whole weeks → the same weekday.
  public func endDate(today: String = CSDate.today()) -> String { LeagueDates.addDays(startDate(today: today), durWeeks * 7) }
  /// `#seasonSpan` — "Sat Sep 5 – Sat Mar 6", the REAL weekdays (§14.0 v1.1).
  public func spanText(today: String = CSDate.today()) -> String {
    "\(LeagueDates.dowMonDay(startDate(today: today))) – \(LeagueDates.dowMonDay(endDate(today: today)))"
  }
  /// `durMonths` — `season_months` DESCRIBES the window (D143: the dates are the
  /// truth and `lock_league` re-derives it from them); 1..12 like the web,
  /// so 13 weeks says 3 and a 2-week pilot says 1, never a clamped 3.
  public static func durMonths(_ weeks: Int) -> Int { min(12, max(1, Int((Double(weeks) / 4.345).rounded()))) }

  // MARK: structure fit (11812–11835)

  /// `wizRoster()` — the wizard sees you (D97: staging is gone). A league that
  /// already has members counts them.
  public static func structFitLine(roster n: Int) -> String {
    var fits: [String] = []
    for s in structures where s != "solo" {
      if n >= (structMin[s] ?? 2) { fits.append(String((structNames[s] ?? s).split(separator: " ").first ?? "")) }
    }
    return "\(n) golfer\(n == 1 ? "" : "s") staged — "
      + (fits.isEmpty ? "solo fits" : "solo or up to \(fits.last!) squads fit")
      + ". Bigger squads open up as more join, by code or invite."
  }
  /// The guidance toast on a structure tap — never a block.
  public static func structToast(_ structure: String, roster n: Int) -> String? {
    let min = structMin[structure] ?? 2
    guard n < min else { return nil }
    return "\(structNames[structure] ?? structure) plays best at \(min)+ — fine if more join by code"
  }
  public static func fits(_ structure: String, roster n: Int) -> Bool { structure == "solo" || n >= (structMin[structure] ?? 2) }

  // MARK: the bylaws card

  /// The renderers' shape, for `LeagueCopy.bylawsRows` and the room's card.
  public var bylaws: Bylaws {
    Bylaws(stake: stake, floor: floor, cap: capN, presetIdx: preset, fmtIdx: 0, structure: structure,
           payout: payout, finish: finish, draftType: draftType)
  }
  public func clock(today: String = CSDate.today()) -> RoomClock {
    RoomClock(phase: .setup, startsOn: startDate(today: today), endsOn: endDate(today: today), status: nil, finish: finish, today: today)
  }
  /// `renderBylaws` (11891–11908) over the wizard's preview dates.
  public func bylawsRows(today: String = CSDate.today()) -> [BylawRow] { LeagueCopy.bylawsRows(bylaws, clock: clock(today: today)) }

  // MARK: applyBylaws (14144–14175) — an existing league, or run it back

  public static func from(_ b: LeagueRoom.Settings, name: String, season: LeagueRoom.Season? = nil) -> WizardDials {
    let base = Bylaws.from(b)
    var d = WizardDials(name: name)
    d.stake = base.stake
    if let s = season {
      d.durWeeks = max(1, Int((Double(CSDate.days(from: s.starts_on, to: s.ends_on) ?? 0) / 7).rounded()))
      d.startISO = s.starts_on
    } else {
      d.durWeeks = max(2, Int((Double(b.season_months ?? 3) * 4.345).rounded()))
    }
    d.floor = base.floor
    d.cap = base.capIdx
    d.preset = base.presetIdx
    d.structure = base.structure
    d.payout = base.payout
    d.finish = base.finish
    d.draftType = base.draftType
    return d
  }
}

// MARK: - The portrait (`wizPortrait`, 11847–11890)

public struct WizardPortrait: Sendable, Equatable {
  public let name: String
  public let squads: Int
  public let structLine: String
  public let cup: Bool
  public let canCup: Bool
  public let stake: Int
  public let roster: Int
  public let pot: Int
  public let payout: [Int]
  /// Month blocks drawn in the season band (1…6).
  public let months: Int
  public let durLabel: String

  public init(_ d: WizardDials, roster: Int) {
    let sqN = ["solo": 0, "squads2": 2, "squads3": 3, "squads4": 4][d.structure] ?? 4
    let draft = ["random": "Random draw", "assign": "The Pro picks", "snake": "Snake", "live": "Live picks"][d.draftType] ?? "Random draw"
    name = d.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Your league" : d.name.trimmingCharacters(in: .whitespaces)
    squads = sqN
    structLine = sqN > 0 ? "\(sqN) SQUADS · \(draft.uppercased())" : "SOLO · EVERY GOLFER"   // LV-10/LV-18
    cup = d.finish == "cup_final"
    canCup = cup && d.durWeeks >= 6
    stake = d.stake
    self.roster = max(1, roster)
    pot = d.stake * max(1, roster)
    payout = d.payout
    months = max(1, min(6, Int((Double(d.durWeeks) / 4.345).rounded())))
    durLabel = LeagueDates.durLabel(d.durWeeks)
  }

  public var sub: String { "Forming — the rules aren’t locked in yet" }
  /// "$75 / player · 3 in so far · 60/25/15"
  public var potSub: String { "\(PotMath.dollars(stake)) / player · \(roster) in so far · \(payout.map(String.init).joined(separator: "/"))" }
  /// The split bar widths, proportional (the web's `p*1.36`, min 5 of 150).
  public var bar: [Double] { payout.map { max(5, Double($0) * 1.36) } }
  public var seasonTail: String { durLabel + (canCup ? "" : " · POINTS TABLE") }
}

// MARK: - The code (`codeFor`, 12815)

public enum WizardCode {
  /// Four letters of the name (A–Z only, upper; "CUP" when none) + four base-36 characters.
  public static func codeFor(_ name: String, random: () -> String = randomTail) -> String {
    let letters = String(name.unicodeScalars.filter { ($0.value >= 65 && $0.value <= 90) || ($0.value >= 97 && $0.value <= 122) }.map(Character.init))
    let head = String(letters.uppercased().prefix(4))
    return (head.isEmpty ? "CUP" : head) + random()
  }
  public static func randomTail() -> String {
    let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    return String((0..<4).map { _ in alphabet[Int.random(in: 0..<alphabet.count)] })
  }
}

// MARK: - The lock call (`lockBylaws` → `lock_league`, 17194–17248)

/// D111 · the ONE write the lock makes — `lock_league`, with exactly the args
/// the web sends. `p_season_format` is `'points'`: the column's DEFAULT is
/// `'hybrid'` and only this write turns the +15/month off (audit 02 §7.13).
/// `p_season_months` only DESCRIBES the window — D143 has the RPC re-derive it
/// from the dates, which are the truth.
///
/// This wraps the generated `Rpc.lock_league` for one reason: the generated
/// binding OMITS a nil arg, which lets the SQL default (Best 3) stand — but an
/// unlimited cap IS null and must reach the database as an explicit null, the
/// way the web's `p_counting_cap: null` does (`coalesce(null, counting_cap)`
/// keeps the fresh row's null). Every arg is written, that one as null.
public struct WizardLockCall: RpcCall {
  public static let name = Rpc.lock_league.name
  /// NOTHING is droppable. `SupabaseService.call(_:)` retries by dropping
  /// EVERY droppable arg at once, so handing it the generated list would let a
  /// skew retry lock the league on the SQL defaults — standard · 95 · cap 3 ·
  /// squads2 · $0 · six months · starts today — and still report "Bylaws
  /// locked". D206: a bylaw the founder never saw is not a bylaw. There is
  /// also nothing to retry INTO: every deployed `lock_league` since
  /// `20260829220000` carries all eighteen args (confirmed against prod
  /// 2026-09-02), and the web's own skew path (`index.html:17239-17248`) falls
  /// back only when the FUNCTION is missing, never by shedding arguments —
  /// "a real refusal must reach the golfer".
  public static let optionalArgs: [String] = []
  public typealias Returns = JSONValue

  public let args: Rpc.lock_league
  /// R18 · the twentieth argument, sent ONLY when there is a note. A $0 season
  /// sends the nineteen keys every deployed `lock_league` has had since
  /// 20260829220000, so the common path never depends on the migration at all.
  ///
  /// C-01: that is only safe because 20260924103000 DROPS the 19-argument
  /// signature. PostgREST resolves by key name, so while both signatures were
  /// live a nineteen-key body matched two candidates and nobody could publish.
  /// One function, twenty parameters, the last one defaulted: nineteen keys
  /// resolve to it, twenty keys resolve to it, and a client running ahead of
  /// the database takes PGRST202 and drops the note through `withoutPayNote`.
  public let payNote: String?

  public init(_ d: WizardDials, leagueId: UUID, name: String, today: String = CSDate.today()) {
    let note = d.buyInNote.trimmingCharacters(in: .whitespacesAndNewlines)
    payNote = note.isEmpty ? nil : note
    args = Rpc.lock_league(
      p_league: leagueId,
      p_name: name,
      p_preset: WizardDials.presetKeys[d.preset],
      p_handicap_allowance: Bylaws.allow[d.preset],
      p_verification: WizardDials.verificationKeys[d.preset],
      p_counting_cap: d.capN,
      p_participation_floor: d.floor,
      p_floor_penalty: WizardDials.penaltyKeys[d.preset],
      p_season_format: "points",
      p_structure: d.structure,
      p_buyin_cents: d.stake * 100,
      p_season_months: WizardDials.durMonths(d.durWeeks),
      p_draft_type: d.draftType,
      p_finish: d.finish,
      p_payout_champ: d.payout[0],
      p_payout_runnerup: d.payout[1],
      p_payout_king: d.payout[2],
      p_starts_on: d.startDate(today: today),
      p_ends_on: d.endDate(today: today))
  }

  struct Key: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(_ s: String) { stringValue = s }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: Key.self)
    try c.encode(args.p_league, forKey: Key("p_league"))
    try c.encodeIfPresent(args.p_name, forKey: Key("p_name"))
    try c.encodeIfPresent(args.p_preset, forKey: Key("p_preset"))
    try c.encodeIfPresent(args.p_handicap_allowance, forKey: Key("p_handicap_allowance"))
    try c.encodeIfPresent(args.p_verification, forKey: Key("p_verification"))
    try c.encode(args.p_counting_cap, forKey: Key("p_counting_cap"))          // null = unlimited, written explicitly
    try c.encodeIfPresent(args.p_participation_floor, forKey: Key("p_participation_floor"))
    try c.encodeIfPresent(args.p_floor_penalty, forKey: Key("p_floor_penalty"))
    try c.encodeIfPresent(args.p_season_format, forKey: Key("p_season_format"))
    try c.encodeIfPresent(args.p_structure, forKey: Key("p_structure"))
    try c.encodeIfPresent(args.p_buyin_cents, forKey: Key("p_buyin_cents"))
    try c.encodeIfPresent(args.p_season_months, forKey: Key("p_season_months"))
    try c.encodeIfPresent(args.p_draft_type, forKey: Key("p_draft_type"))
    try c.encodeIfPresent(args.p_finish, forKey: Key("p_finish"))
    try c.encodeIfPresent(args.p_payout_champ, forKey: Key("p_payout_champ"))
    try c.encodeIfPresent(args.p_payout_runnerup, forKey: Key("p_payout_runnerup"))
    try c.encodeIfPresent(args.p_payout_king, forKey: Key("p_payout_king"))
    try c.encodeIfPresent(args.p_starts_on, forKey: Key("p_starts_on"))
    try c.encodeIfPresent(args.p_ends_on, forKey: Key("p_ends_on"))
    try c.encodeIfPresent(payNote, forKey: Key("p_pay_note"))
  }

  /// The same call with the note stripped — the ONE fallback, and it fires on a
  /// missing FUNCTION only (PGRST202 / 42883), never on a refusal. A season that
  /// locked through it is live with no note, and `WizardService` says so out
  /// loud rather than letting the fact go quiet.
  public var withoutPayNote: WizardLockCall { WizardLockCall(args: args, payNote: nil) }
  init(args: Rpc.lock_league, payNote: String?) { self.args = args; self.payNote = payNote }
}

// MARK: - Copy the screens print

public enum WizardCopy {
  // F-5 · check 5 bans "lock it in"; this said "lock them in" and walked past
  // it, on the wizard's own eyebrow. §2.3: the season STARTS; nothing locks.
  // LV-14 · and "league" is never the thing you create — a season is.
  public static let eyebrow = "Set the rules once, then start the season"
  public static let namePlaceholder = "The Big Slice, The Sunday Cup, Dew Sweepers…"
  public static let nameLabel = "League name"
  public static let proLabel = "Pro — that’s you"
  public static let proSub = "you run this league"
  public static let proTag = "THE PRO"

  // the name sheet (`#wCreate`, 17172–17176)
  public static let nameSheetTitle = "Name your league"
  public static let nameSheetSub = "The banner everything hangs under"
  public static let nameSheetFine = "You can rename it any time before the season starts."
  public static let nameSheetGo = "Start the season"
  public static let nameFirst = "Give the league its name first"
  public static func onTheBooks(_ name: String) -> String { "\(name) is on the books — set the rules" }
  public static let runBackCarried = "Run it back — last season’s rules carried over. Review and start."
  public static let couldNotCreate = "Could not start the season."
  public static let signInFirst = "Sign in to start a season."

  // step 1
  public static let presetEyebrow = "How serious is your league?"
  public static let presetHelp = "One pick, made now, that sets the fairness rules for the whole season — how much of your index you play off, how scores are vouched for, which courses count. Casual is an honor-system beer league. Standard asks you to post what you’d post to GHIN. Cutthroat wants receipts: vouched by the group where you can; the Pro rules on the rest. Deciding this before anyone tees off is what keeps October friendly."
  /// M-15 · the footnote under the preset cards: verification is a norm, not a filter.
  public static let verificationNote = "Verification is a norm the league holds, not a filter the engine applies."
  public static let fastPath = "Use these defaults →"
  public static let customize = "Customize"
  public static let hideOptions = "Hide options"
  public static let buyIn = ("Buy-in", "Per player · $0 = bragging rights")
  public static let seasonLength = ("Season length", "Weeks or months · ends the same weekday")
  public static let firstTee = ("First tee", "Pick any day")
  public static let teamsEyebrow = "Teams"
  public static let teamsHelp = "How the league is organized. Solo means everyone competes individually: no squads. Squad modes split the league into teams the Pro picks or draws; more squads want more players (4 squads plays best at 8+)."
  public static let fillEyebrow = "How teams fill"
  public static let fillHelp = "How squads get filled. Random draw shuffles everyone server-side and announces the reveal to the board, so nobody can rig the hat. Picking them yourself lets you place players, for groups who picked teams in the group chat. Live picking with a clock isn’t built yet."
  public static let endsEyebrow = "How it ends"
  public static let endsHelp = "How the champion is crowned. Cup Final resets for the last four weeks — top seeds race fresh, anyone can catch fire, playoff drama. Points table crowns whoever leads when the season ends: the whole year is the race, no reset."
  public static let potEyebrow = "The pot split"
  public static let potHelp = "How the pot pays out at season’s end. Every split rewards the champion, the runner-up, and the Points King (best individual all year). The pot lives on the books here — " + MoneyCopy.ledger
  public static let countingCap = ("Rounds that count", "Your best N each month score")
  public static let capHelp = "The core fairness dial. Only your best N rounds each month score for the squad, so the retiree who plays daily can’t bury the dad who plays weekly. A better round automatically replaces your worst counter, so posting never stops mattering."
  public static let floorRow = ("The monthly minimum", "ROUNDS A MONTH · −5 SQUAD POINTS SHORT")
  public static let floorHelp = "The anti-ghosting rule. Every golfer posts at least this many rounds a month, or the squad takes a penalty: −5 points per round short under Standard rules. One Pro-approved bye month per season covers vacations and injuries."
  public static let asideTitle = "Your league so far"
  public static let asideHint = "Turn the dials — the rules fill in here. They freeze at the first tee."

  // step 2
  public static let reviewEyebrow = "Review the rules, then start the season"
  /// D205 · every minimum derives from `structMin` (solo → 2, squads → 4).
  public static let inviteNote = "Lock opens the invite link — one link fills the league. The code works until first tee, or until you close the roster. Squads need \(numberWord(WizardDials.structMin["squads2"] ?? 4)) to tee off; solo tees off at \(numberWord(WizardDials.structMin["solo"] ?? 2))."
  /// D205 · a solo league has no squads to form (D161's rename of the button itself is deferred).
  public static func lockButton(solo: Bool) -> String { solo ? "Start the season" : "Start the season & form the squads" }
  /// D205 · "four", "two" — the one place a minimum becomes a word.
  public static func numberWord(_ n: Int) -> String {
    let words = ["two", "three", "four", "five", "six", "seven", "eight"]
    return (2...8).contains(n) ? words[n - 2] : String(n)
  }
  public static let nameTheLeagueFirst = "Name the league first: top of the wizard"
  public static let bylawsLocked = "Season started"
  public static let lockFailed = "Lock failed."

  // nav
  public static let cancel = "Cancel"
  public static let back = "← Back"
  public static let next = "Next →"
  public static let cancelConfirm = "Cancel this league? It hasn’t started, so this discards it completely."
  public static let discarded = "League discarded"
  public static let couldNotDiscard = "Could not discard."

  // the lock share (`openLockShare`, 13931–13960)
  public static let lockShareTitle = "Season started"
  public static let lockShareSub = "One link fills the league"
  public static let shareInvite = "Share the invite link"
  public static let later = "Later — it lives in the league room"
  /// P-11 · "Season is live" only once first tee has come (`starts_on <= today`);
  /// a solo league locked ahead of its start names the first tee instead.
  public static func lockShareLine(nextPhase: String, members n: Int, structure: String, draftType: String,
                                   startsOn: String? = nil, today: String = CSDate.today()) -> String {
    let min = WizardDials.structMin[structure] ?? 4
    let need = max(0, min - n)
    let structName = (WizardDials.structNames[structure] ?? "the squads").lowercased()
    let forms = draftType == "assign" ? "you seat the squads" : "the draw runs"
    if nextPhase == "season" {
      if let s = startsOn, s > today { return "First tee \(LeagueDates.dowMonDay(s)) — every golfer you add posts from day one." }
      return "Season is live — every golfer you add posts from day one."
    }
    if need > 0 { return "\(n) in so far — \(need) more fills \(structName), and \(forms) when the crew is in." }
    return "\(n) in — enough for \(structName). \(draftType == "assign" ? "Seat the squads" : "Run the draw") whenever you’re ready."
  }
  public static func inviteText(_ league: String) -> String { "You’re invited to \(league) on Cup Season" }
  public static func inviteURL(_ code: String) -> URL? {
    guard let enc = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
    return URL(string: "\(CSConfig.webOrigin.absoluteString)/?join=\(enc)")
  }
  public static func inviteShort(_ code: String) -> String { "cupseason.app/?join=\(code)" }

  // the league-less doors (`renderHomeStart`, 9736–9773) and the D96 hero (9900–9946)
  // LV-14 · row 113: league is never a button, a tab or a thing you join.
  public static let startLeague = "Start a season"
  public static let startEvent = "Start an event"
  public static let joinLeague = "Join with a code"
  public static let leaguelessLine = "Add a round — it posts to your rounds. Seasons score it when you join one."
  public static let runBackK = "Season wrapped"
  public static let runBack = "Run it back — Season 2"
  public static let runBackSub = "Same crew, same rules, fresh table — change anything in the wizard."
  /// `runItBack` (14177): strip a trailing "· S<n>" and append "· S2".
  public static func runBackName(_ old: String) -> String {
    var base = old.isEmpty ? "Your league" : old
    if let r = base.range(of: #"\s*·\s*S\d+\s*$"#, options: [.regularExpression, .caseInsensitive]) { base.removeSubrange(r) }
    return base.trimmingCharacters(in: .whitespaces) + " · S2"
  }
  /// "My Cup" is the pre-wizard scaffold name, not a choice (D5).
  public static func isUnnamed(_ name: String?) -> Bool {
    let t = (name ?? "").trimmingCharacters(in: .whitespaces)
    return t.isEmpty || t.lowercased() == "my cup"
  }
  public static let ctaName = "Name your league"
  public static let ctaLock = "Start the season and invite your crew"

  // MARK: - D225 · the three questions, in order (IA §6.3, CORE_FLOWS §7)

  /// 1 · WHO
  public static let step1 = "Who’s playing?"
  public static let step1Sub = "Pick from your buddies, or send a link when you’re done."
  /// The empty branch — every first-time organiser's state, and it was missing.
  /// `search_golfers` matches an exact @handle or an existing relation only
  /// (L-37), so a golfer signed in an hour cannot find two friends who are
  /// already on the app. Without these three doors the sheet's first screen is
  /// a dead end for exactly the golfer it was written for.
  /// QB-10 · **three doors, and it said two.** Two blind walkers counted the
  /// boxes twice and one of them wrote that "two ways in over three boxes
  /// makes me feel like the screen isn't looking at itself". Derived from the
  /// door list rather than typed, so it cannot drift again.
  public static var step1Empty: String { "No buddies yet. \(numberWord(step1Doors).capitalized) ways in." }
  /// Find your friends · Text them a link · Just me for now.
  public static let step1Doors = 3
  public static let findYourFriends = "Find your friends"
  public static let findYourFriendsSub = "check your contacts for golfers already here"
  public static let textThemALink = "Someone not here yet — text them a link"
  public static let justMe = "Just me for now"
  public static let justMeSub = "you can add people any time before the first tee"
  /// The one question the roster is worth asking, and only at four or more.
  ///
  /// LV-18 · "everyone for themselves", which is the ruled phrase (row 121)
  /// and what `LeagueCopy.structNames["solo"]`, `LiveSetupView` and
  /// `LiveCopy` already say in five places. The wizard is the one screen where
  /// a NEW organiser — who may not be a man — makes this choice.
  /// QB-13 · question one, before anything derives from a roster of one.
  /// The chips carry exact numbers, not bands, because the whole point is that
  /// the pot line can then say `$300` instead of `One in makes $50`.
  public static let howManyQuestion = "How many of you?"
  public static let howManyFine =
    "Counting you. It sizes the pot and decides which questions are worth asking \u{2014} you can still add anyone before the first tee."
  public static let howManyChips: [Int] = [2, 3, 4, 5, 6, 8, 10, 12]
  public static func howManyLabel(_ n: Int) -> String {
    n == howManyChips.last ? "\(n)+" : "\(n)"
  }

  public static let squadsQuestion = "Squads, or everyone for themselves?"
  public static let squadsYes = "Squads"
  public static let squadsNo = "Everyone for themselves"

  /// 2 · WHEN
  public static let step2 = "How long, and when’s the first tee?"
  /// L-13, in a golfer's words, at the moment it matters.
  public static func step2Note(endsOn: String) -> String {
    "Ends \(LeagueDates.dowMonDay(endsOn)). Rounds you post before the first tee still build your number."
  }

  /// QB-06 · **WHAT THE FIRST TEE COSTS, WHERE THE FIRST TEE IS CHOSEN.**
  ///
  /// Both consequences were true and neither was on this screen. The rules
  /// freeze at the first tee (`freezeNote`, one line above **Start the
  /// season**, three panes later) and the invite link closes there
  /// (`RosterDoor`, inside the season's rules pane, AFTER publication). An
  /// organiser accepted the default, published, texted six people, and only
  /// found the second fact by hunting. It is one sentence and it belongs
  /// beside the date picker.
  public static func step2Consequence(startsOn: String) -> String {
    "After \(LeagueDates.dowMonDay(startsOn)) the rules freeze and the invite link closes \u{2014} leave the crew room to join."
  }

  /// 3 · WHAT'S ON IT
  public static let step3 = "What’s on it?"
  public static let payLabel = "How do they pay you?"
  public static let payPlaceholder = "Venmo @galen"
  public static let payFine = "Everyone who owes will see this. It’s the only place they can look."
  /// The one required field the wizard gains (D225).
  public static let payMissing = "They’ll need somewhere to send it."
  /// L-09 · printed from the constant, never retyped.
  public static func potLine(stake: Int, roster: Int) -> String {
    "$\(stake) each. \(WizardCopy.numberWord(max(1, roster)).capitalized) in makes \(PotMath.dollars(stake * max(1, roster)))."
  }

  /// THEN, AND ONLY THEN.
  public static let rulesHead = "Standard rules."
  public static func rulesLine(_ d: WizardDials) -> String {
    var clauses = ["Honest scores"]
    if let c = d.capN { clauses.append("best \(numberWord(c)) a month count") }
    if d.floor > 0 { clauses.append("\(numberWord(d.floor)) a month keeps you in") }
    clauses.append("\(Bylaws.allow[d.preset]) percent of your index")
    return clauses.joined(separator: ", ") + "."
  }
  public static let moreSettings = "More settings"
  public static let nameIt = "Name it"
  public static let publish = "Start the season"
  /// T-11 · the state, not the word. Nothing "locks".
  public static let freezeNote = "The rules freeze at the first tee."
  public static let close = "Close"

  /// The publish, and its one half-state. `create_league` and `lock_league` are
  /// two calls; `lock_league` is idempotent on `locked_at`, which is what makes
  /// the retry safe — and a retap after this sentence gets the standing truth
  /// rather than a second season.
  public static let publishFailedHalf = "The season was created but the rules did not lock. Try again — it will not make a second one."
  public static let publishFailed = "Couldn’t start the season."
  /// R18 · the note did not land because the database has not had the migration.
  /// Named out loud rather than dropped (D225).
  public static let payNoteMissedIt = "The season is live. Add how they pay you from the pot."

  /// The share screen, which is the SAME screen (D114's phone half).
  public static func liveHead(_ name: String) -> String { "\(name) is live." }
  public static func liveSub(weeks: Int, startsOn: String, invited: Int) -> String {
    let crew = invited > 0
      ? "\(WizardCopy.numberWord(invited + 1).capitalized) in, and the link works for anyone."
      : "The link works for anyone."
    return "\(numberWord(weeks).capitalized) weeks from \(LeagueDates.dowMonDay(startsOn)). \(crew)"
  }
  public static let copyLink = "Copy link"
  public static let copyMessage = "Copy message"
  public static let shareEllipsis = "Share…"
  public static let openTheSeason = "Open the season"
}
