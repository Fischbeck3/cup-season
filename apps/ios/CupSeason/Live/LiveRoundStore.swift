// Cup Season — the live round's one state store (index.html: the classic
// side of D85, 7738–7856; setup 8720–9006; finish 9109–9177; scrap 9332–9364).
//
// The web bridged `liveSync`, `enterGuestLive`, `claimPendingRound` and the
// play globals across the classic/module line; the phone gets one store. It
// owns the round (`LiveRoundState`), the pick list (ROSTER / sel), the guest
// pencil's identity, presence and the queue depth, and it is the only thing
// that talks to the session actor. Every mutation of the card stamps a write
// clock BEFORE it travels, and snapshots to disk so a kill resumes it.

import SwiftUI
import Network
import CSDesign
import CupSeasonKit

/// What the recap sheet shows after a finish (`showLiveRecap` 9178).
struct LiveRecapData: Identifiable {
  let id = UUID()
  let outcome: LiveFinishOutcome
  let result: LiveResult?
  let lr: UUID
  let course: String
  let date: Date
}

@MainActor
@Observable
final class LiveRoundStore {
  static let shared = LiveRoundStore()

  var state: LiveRoundState = .fresh()
  /// ROSTER — the pick list (you, league mates, buddies, guests)
  var roster: [LivePlayer] = []
  /// sel — indices into `roster`, at most four
  var sel: [Int] = []
  /// the court's tap-tap pick
  var crtPicked: Int?
  var guest: LiveGuestContext?
  var presence: [String] = []
  var queued = 0
  var syncStatus: String?
  var recap: LiveRecapData?
  var busy = false
  var scoreOnPhone = false
  var localSaveError: String?
  private let offline: OfflineRounds

  /// The explicit local path never falls back from an uncertain server start.
  func prepareOffline(_ golfer: OfflineGolfer) {
    if let old = state.localOwner, old != golfer.id { state = .fresh() }
    myPid = golfer.id; myName = golfer.name; myIndex = golfer.index; myMarker = golfer.marker
    scoreOnPhone = true
    var player = LivePlayer(n: golfer.name, i: golfer.index ?? 0, ci: 1, guest: false, me: true, locked: true, mk: golfer.marker)
    player.pid = golfer.id; player.est = golfer.index == nil
    roster = [player]; sel = [0]; rosterPrimed = true
    do {
      if let current = try offline.rounds(owner: golfer.id).first(where: { $0.active }) {
        state = current; localSaveError = nil; return
      }
    } catch { localSaveError = "Couldn’t read the phone scorecards. They haven’t been removed."; return }
    if state.active { return }
    state = .fresh(); state.game = .score; state.mode = .solo
  }

  func useLocalScoring(_ enabled: Bool) {
    guard !state.active, !busy else { return }
    scoreOnPhone = enabled
    if enabled { state.game = .score; state.mode = .solo; state.stake = 0; stopNearby() }
  }

  func flushLocalCard() {
    guard state.onThisPhone, state.active else { return }
    do { try offline.save(state); localSaveError = nil }
    catch { localSaveError = "Couldn’t keep the latest scores on this phone. Keep this screen open and try again." }
  }

  private func teeOffLocally() {
    guard let owner = myPid else { toast("Sign in before preparing an offline round."); return }
    guard let player = roster.first(where: { $0.me && $0.pid == owner }) else { toast("Your golfer identity is unavailable. Reopen the round setup."); return }
    guard !state.course.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { toast("Enter the course before teeing off."); return }
    guard state.course.note != nil else { toast("Load the scorecard or enter its actual pars before scoring offline."); return }
    var s = LiveRoundState.fresh(players: [player], course: state.course)
    s.holes = state.holes; s.rating9 = state.rating9; s.mode = .solo
    s.lr = UUID(); s.localOwner = owner; s.playedDay = CSDate.iso(Date(), calendar: ScheduleDates.gregorian)
    s.startedAt = LiveFmt.now(); s.ts = s.startedAt!; s.active = true; s.stage = .live
    do { try offline.save(s); state = s; localSaveError = nil; LiveActivityHost.start(s) }
    catch { localSaveError = "Couldn’t create a scorecard on this phone. Free up storage and try again." }
  }

  func localCards() -> [LiveRoundState] {
    guard let owner = myPid else { return [] }
    do { return try offline.rounds(owner: owner).filter { $0.localCompleted == true } }
    catch { localSaveError = "Couldn’t read the phone scorecards. They haven’t been removed. Try again."; return [] }
  }
  func resumeLocal(_ id: UUID) {
    guard !state.active, let owner = myPid else { return }
    do {
      guard var s = try offline.round(owner: owner, id: id) else { return }
      if let pending = try OfflinePostDisk.shared.read(owner: owner, request: id) {
        toast(pending.accepted != nil ? "This round already posted. Open your round history when connected." : "This scorecard has a post awaiting confirmation. Retry it from Play when connected.")
        return
      }
      s.active = true; s.localCompleted = false
      try offline.save(s); state = s; scoreOnPhone = true; localSaveError = nil
    } catch { localSaveError = "Couldn’t open this phone scorecard. Try again." }
  }

  private func keepLocalRound() -> Bool {
    guard state.anyScored else { toast("Enter a score before keeping the round."); return false }
    var kept = state; kept.active = false; kept.stage = .setup; kept.localCompleted = true; kept.ts = LiveFmt.now()
    do {
      try offline.save(kept)
      state = kept; rosterPrimed = true; localSaveError = nil
      toast("Round kept on this phone. Review and post it when you have a signal.")
      return true
    } catch {
      localSaveError = "Couldn’t keep this round. Your scores are still on screen. Try again before closing."
      return false
    }
  }

  var plan: ScheduledRound?
  var planDismissed = false
  /// the kiosk guest's round ended on another phone — 'final' | 'abandoned'
  var guestEnded: String?
  /// the round ended remotely and the host should leave the play view
  var leaveRequested = false
  var toasts: CSToastCenter?

  private(set) var leagueId: UUID?
  private(set) var myPid: UUID?
  private var myName: String?
  private var myMemberId: UUID?
  private var myIndex: Double?
  /// D271 · the viewer's own mark, so their live row is a face like everyone
  /// else's rather than the one row that is not.
  private var myMarker: String?
  private var rosterLeague: UUID?
  private var rosterPrimed = false
  private var rehydrated = false

  let repo = LiveRepository()
  let disk = LiveDisk.shared
  let session = LiveRoundSession()
  private var eventTask: Task<Void, Never>?

  init(offline: OfflineRounds = .shared) {
    self.offline = offline
    eventTask = Task { [weak self] in
      guard let self else { return }
      for await e in session.events { self.handle(e) }
    }
  }

  private func toast(_ s: String) { toasts?.show(s) }

  // MARK: - identity & the pick list (`primeRealRoster` 7388)

  /// Called by the host with what the session knows. Primes the roster for
  /// the league Home leads with; never wipes an in-progress round.
  func configure(me: Me?, preferredLeague: UUID?) async {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("-cs_dev_offline_trip") {
      if myPid == nil {
        let args = ProcessInfo.processInfo.arguments
        let owner = args.firstIndex(of: "-cs_dev_offline_owner").flatMap { i in i + 1 < args.count ? UUID(uuidString: args[i + 1]) : nil }
          ?? UUID(uuidString: "00000000-0000-0000-0000-00000000F331")!
        prepareOffline(OfflineGolfer(id: owner, name: "Offline QA golfer", index: nil, marker: nil))
        if !state.active {
          state.course.label = "Offline QA course — fixture"
          state.course.save(front: Array(repeating: 4, count: 9), back: Array(repeating: 4, count: 9), nine: false)
        }
      }
      return
    }
    #endif
    if let owner = myPid, let next = me?.profile?.id, owner != next {
      state = .fresh(); scoreOnPhone = false; rosterPrimed = false; rehydrated = false
    }
    if me == nil, scoreOnPhone { return }
    let m = me?.memberships.first { $0.league_id == preferredLeague } ?? me?.memberships.first
    myPid = me?.profile?.id
    myName = me?.profile?.display_name
    myIndex = me?.profile?.index_current
    myMarker = me?.profile?.marker
    myMemberId = m?.member_id
    leagueId = m?.league_id
    #if DEBUG
    if CSDevHatch.nearby, !state.active { seedDevNearby(); return }
    // -cs_dev_bar · the D163 top bar with a round in flight, for review
    if ProcessInfo.processInfo.arguments.contains("-cs_dev_bar"), !state.active {
      if ProcessInfo.processInfo.arguments.contains("-cs_dev_bar_waiting") {
        awaitingFrom = "Jerecho Fischbeck"; return
      }
      seedDevRound(); return
    }
    if CSDevHatch.live, !state.active { seedDevRound(); LiveActivityHost.start(state); return }
    #endif
    if let owner = myPid, let local = try? offline.rounds(owner: owner).first(where: { $0.active }) {
      if let profile = me?.profile {
        prepareOffline(OfflineGolfer(id: owner, name: profile.display_name ?? "You", index: profile.index_current, marker: profile.marker))
      } else { state = local; scoreOnPhone = true }
      return
    }
    if scoreOnPhone { return }
    if !rehydrated { rehydrated = true; await rehydrate() }
    if !rosterPrimed || rosterLeague != leagueId { await primeRoster() }
    if plan == nil, !planDismissed { plan = await repo.todaysPlan() }
  }

  #if DEBUG
  /// `-cs_dev_live` — a match-play round, four players, fourteen holes in, with
  /// a real stroke index so the card's SI row is the honest one. Local only.
  /// `-cs_dev_nearby` — the setup screen with one golfer already resolved as
  /// nearby, plus a fake invitation two seconds later, so both halves of D158's
  /// handshake can be looked at on one simulator. Nothing here touches the
  /// server or the Bluetooth transport.
  private func seedDevNearby() {
    var me = LivePlayer(n: "You", i: 8.4, ci: 1, guest: false, me: true, locked: true, team: "—")
    me.pid = UUID()
    let jade = LivePlayer(id: "p:jade", n: "Jade", i: 11.2, ci: -1, guest: true, buddy: true,
                          pid: UUID(), team: nil, regular: 0, nearby: true)
    roster = [me, jade]
    sel = [0]
    rosterPrimed = true
    var fresh = LiveRoundState.fresh()
    fresh.course.label = "Bajamar Golf Club"
    state = fresh
    // …and the receiving half only when asked for, so the ask-chip can be seen
    // on its own: `-cs_dev_nearby -cs_dev_nearby_invite`
    if ProcessInfo.processInfo.arguments.contains("-cs_dev_nearby_invite") {
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(2))
        self.incoming = NearbyInvite(from: UUID(), name: "Jerecho",
                                     course: "Bajamar Golf Club", game: "Match play")
      }
    }
  }

  private func seedDevRound() {
    // Wave 7 · the four carry MARKS, because the sheet draws a `CSFace` now and
    // a screenshot of four initials would be a picture of the degrade rather
    // than of the design. They are invented golfers on an invented round; the
    // marks are invented with them, and nothing here touches the server.
    let players = [("You", 8.4, 0, false, "saguaro"), ("Danny", 12.1, 1, false, "lonetree"),
                   ("Chuck", 6.2, 2, false, "dunes"), ("Gary", 18.0, 3, true, "beer")]
      .map { LivePlayer(id: $0.0, n: $0.0, i: $0.1, ci: $0.3 ? -1 : $0.2, guest: $0.3,
                        me: $0.0 == "You", mk: $0.4) }
    var course = LiveCourseCard()
    course.pars = [4,4,3,5,4,4,3,4,5, 4,3,4,5,4,4,3,4,5]
    course.si   = [5,11,17,1,7,13,15,3,9, 6,18,12,2,8,14,16,4,10]
    course.siEst = false
    course.label = "Encanto GC — Blue"
    var st = LiveRoundState.fresh(players: players, course: course)
    st.stage = .live; st.active = true; st.game = .match; st.hole = 14
    st.teams = [[0, 1], [2, 3]]
    // …and TWO of the four are already in on the 15th, so one screenshot holds
    // both states of the score object AND the number-to-beat block, which does
    // not render until somebody has posted one.
    st.scores = [[4,3,3,5,4,5,3,4,5, 4,3,3,5,4,nil,nil,nil,nil],
                 [5,4,3,6,4,4,2,4,5, 4,3,4,6,4,3,nil,nil,nil],
                 [4,4,4,5,3,4,3,4,5, 4,3,4,5,5,5,nil,nil,nil],
                 [5,5,3,5,4,4,4,5,5, 4,4,4,5,4,nil,nil,nil,nil]]
    state = st
  }
  #endif

  /// IA P4: a real account's tee sheet starts as YOU + league mates + guests.
  func primeRoster() async {
    guard !(state.active) else { return }
    var r: [LivePlayer] = []
    r.append(LivePlayer(id: "me", n: myName ?? "You", i: myIndex ?? 18, ci: 1, guest: false, est: myIndex == nil,
                        mid: myMemberId, pid: myPid, me: true, locked: true, team: "—", mk: myMarker))
    if let lid = leagueId, let mates = try? await repo.leagueRoster(leagueId: lid) {
      for m in mates where m.profileId != myPid {
        r.append(LivePlayer(id: "m:\(m.memberId.uuidString)", n: m.displayName ?? "Member", i: m.indexCurrent ?? 18, ci: 1, guest: false,
                            est: m.indexCurrent == nil, mid: m.memberId, pid: m.profileId, team: "—", mk: m.marker))
      }
    }
    guard !state.active, !scoreOnPhone else { return }
    // keep any guests / buddies already added this session
    r.append(contentsOf: roster.filter(\.guest))
    roster = r
    sel = [0]
    rosterPrimed = true
    rosterLeague = leagueId
    var fresh = LiveRoundState.fresh()
    fresh.course = LiveCourseCard()   // the search leads; rating/slope fall back to 72/113
    fresh.leagueId = leagueId
    state = fresh
    await markRegulars()
  }

  // MARK: D156 · who is standing on this tee

  let nearby = NearbyService()
  /// Opt-in, remembered per device. Off until the golfer says yes.
  var nearbyOn: Bool {
    get { UserDefaults.standard.bool(forKey: "cs.nearby.on") }
    set { UserDefaults.standard.set(newValue, forKey: "cs.nearby.on")
          newValue ? startNearby() : nearby.stop() }
  }

  /// D158 · profiles we have ASKED and not heard back from.
  var asking: Set<UUID> = []
  /// D163 · profiles who said YES and are waiting for the round to be real.
  var accepted: Set<UUID> = []
  /// D158 · an invitation waiting on this phone.
  var incoming: NearbyInvite?

  func startNearby() {
    guard !scoreOnPhone else { return }
    // D168 · runs from the tab shell now, so it must be safe to call often and
    // from anywhere: already-running is a no-op, and a live round still stops
    // advertising (the foursome is set — there is nobody left to ask).
    guard nearbyOn, let me = myPid, !state.active, !nearby.running else {
      // D173 · say WHY it did not start. Three attempts to fix "nearby only
      // works on the schedule" have each been a guess; this prints the actual
      // failing precondition to `devicectl … --console`.
      nearbyPrint("startNearby SKIPPED — on=\(nearbyOn) pid=\(myPid != nil) activeRound=\(state.active) alreadyRunning=\(nearby.running)")
      return
    }
    nearbyPrint("startNearby OK — advertising")
    nearby.onChange = { [weak self] ids in
      Task { @MainActor in await self?.resolveNearby(ids) }
    }
    nearby.onInvite = { [weak self] inv in self?.incoming = inv }
    nearby.onReply = { [weak self] who, ok in self?.answered(who, ok) }
    nearby.onTeed = { [weak self] lr in Task { @MainActor in await self?.enterInvited(lr) } }
    nearby.onUndeliverable = { [weak self] who in self?.askFailed(who, "Couldn't reach their phone") }
    nearby.start(myProfile: me)
  }

  func stopNearby() { nearby.stop(); asking = []; accepted = []; incoming = nil }
  /// D169 · the wait is over one way or another — stop asking.
  func stopWaiting() { watcher?.cancel(); watcher = nil; awaitingFrom = nil }

  /// D158 · a nearby chip ASKS. Proximity proposes an identity; only the golfer
  /// holding that phone can confirm it, so the tap that seats them happens over
  /// there, not here. Every other add path is untouched — a league mate or a
  /// regular asserts nothing about who is standing here, and needs no witness.
  func askNearby(_ i: Int) {
    guard i < roster.count, let pid = roster[i].pid else { return }
    guard sel.count < 4 else { toast("The group is full: remove someone first"); return }   // LV-08
    asking.insert(pid)
    nearby.invite(pid,
                  name: myName ?? "A golfer",
                  course: state.course.label.isEmpty ? "a round" : state.course.label,
                  game: state.game.banner)
    toast("Asked \(roster[i].n)")
    // D168 · ASKING is a state you must be able to leave. A phone that has
    // wandered off, locked, or left the setup screen will never answer, and the
    // chip used to sit there forever saying nothing. Give up out loud.
    Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(20))
      guard let self, self.asking.contains(pid) else { return }
      self.askFailed(pid, "No answer")
    }
  }

  /// D168 · the ask did not land. Clear the chip and say why, rather than
  /// leaving a spinner that means nothing.
  func askFailed(_ who: UUID, _ reason: String) {
    guard asking.remove(who) != nil else { return }
    let name = roster.first(where: { $0.pid == who })?.n
    toast("\(reason) — ask \(name ?? "them") to start the live round")
  }

  private func answered(_ who: UUID, _ ok: Bool) {
    asking.remove(who)
    guard let i = roster.firstIndex(where: { $0.pid == who }) else { return }
    guard ok else {
      // a decline takes the chip away rather than leaving it to be re-tapped
      roster[i].nearby = nil
      toast("\(roster[i].n) is not playing")
      return
    }
    if !sel.contains(i), sel.count < 4 { sel.append(i) }
    accepted.insert(who)          // D163 · tell them when the round is real
    toast("\(roster[i].n) is in")
  }

  /// D158 · this phone's answer to someone else's tee.
  func answerIncoming(_ ok: Bool) {
    guard let inv = incoming else { return }
    incoming = nil
    nearby.reply(to: inv.from, ok: ok)
    // D163 · say what happens next. At THIS moment there is no round — the
    // starter is still on the setup screen — so the honest thing is to say we
    // are waiting, not to open an empty screen. `onTeed` lands us in it.
    if ok {
      awaitingFrom = inv.name
      toast("You're in — waiting for \(LiveFmt.fn1(inv.name)) to tee off")
      watchForRound()
    }
  }

  /// D169 · while a golfer is waiting on a round they have already agreed to
  /// play, THIS phone asks the server for it. The Bluetooth doorbell is an
  /// optimisation; it must never be the only thing that works. The waiter is
  /// standing there with the screen on, so a short bounded poll is honest —
  /// and it stops the moment the round arrives, the wait is abandoned, or ten
  /// minutes pass without a tee-off.
  private func watchForRound() {
    watcher?.cancel()
    watcher = Task { @MainActor [weak self] in
      for tick in 0..<150 {                    // 150 × 4s = 10 minutes
        try? await Task.sleep(for: .seconds(4))
        nearbyPrint("waiting tick \(tick) — myPid=\(self?.myPid != nil) active=\(self?.state.active == true)")
        guard let self, self.awaitingFrom != nil, !Task.isCancelled else { return }
        await self.refreshLive()
        if self.state.active, self.state.stage == .live {
          self.awaitingFrom = nil
          self.openRequested = true
          CSHaptic.impact(.medium)
          return
        }
      }
      self?.awaitingFrom = nil
    }
  }
  private var watcher: Task<Void, Never>?

  /// D163 · set between accepting an invitation and the round actually starting.
  /// The top bar reads it, so the wait is visible instead of being nothing.
  var awaitingFrom: String?

  /// D163 · the round we accepted is real now. Pull it and open it.
  ///
  /// `rehydrate()` already knows how to find a round this phone is seated in —
  /// the Bluetooth message is not a second source of truth, it is a doorbell
  /// that saves us waiting for a foreground or a launch.
  func enterInvited(_ lr: UUID) async {
    watcher?.cancel(); watcher = nil
    awaitingFrom = nil
    await rehydrate()
    if state.active, state.stage == .live {
      LiveActivityHost.start(state)
      leaveRequested = false
      openRequested = true      // the shell presents the round
      CSHaptic.impact(.medium)
    }
  }

  /// D163 · raised when the round should be put on screen without a tap.
  var openRequested = false

  /// The server does the naming, and only for people you already know. A
  /// stranger's phone resolves to nothing and never reaches the picker.
  private func resolveNearby(_ ids: [UUID]) async {
    let rows = await repo.nearbyResolve(ids)
    guard !rows.isEmpty else { return }
    for r in rows {
      if let i = roster.firstIndex(where: { $0.pid == r.id }) {
        roster[i].nearby = true
      } else {
        roster.append(LivePlayer(id: "p:\(r.id.uuidString)", n: r.name, i: r.index ?? 18, ci: -1,
                                 guest: true, est: r.index == nil, buddy: true,
                                 pid: r.id, team: nil, nearby: true))
      }
    }
  }

  /// D154 · fold the people you actually play with into the roster you already
  /// have. A regular who is ALSO a league mate is marked, not duplicated — the
  /// point is ordering, and a name in two lists is a worse picker, not a better
  /// one. A regular from outside the league is appended exactly as the app-wide
  /// search appends one, so nothing downstream has a new shape to handle.
  func markRegulars() async {
    let partners = await repo.recentPartners()
    guard !partners.isEmpty else { return }
    for (rank, p) in partners.enumerated() {
      if let i = roster.firstIndex(where: { $0.pid == p.id }) {
        roster[i].regular = rank
      } else {
        roster.append(LivePlayer(id: "p:\(p.id.uuidString)", n: p.name, i: p.index ?? 18, ci: -1,
                                 guest: true, est: p.index == nil, buddy: true,
                                 pid: p.id, team: nil, regular: rank))
      }
    }
  }

  var picked: [LivePlayer] { sel.compactMap { $0 < roster.count ? roster[$0] : nil } }

  /// `courtMode` (8724): four picked, a team game, teams mode.
  var teamable: Bool { state.game.teamable && sel.count == 4 && state.stage != .live }
  var courtMode: Bool { teamable && !state.solo }

  func setGame(_ g: LiveGame) { state.game = g; crtPicked = nil }
  func setMode(_ m: LiveMode) { state.mode = m; crtPicked = nil }
  func setStake(_ v: Double) { state.stake = max(0, v) }

  /// The 9/18 picker (6962).
  func setHoles(_ n: Int) {
    let n = n == 9 ? 9 : 18
    state.holes = n
    if n == 18 { state.rating9 = false }
    state.course.reindex(holes: n)
    state.hole = min(state.hole, n - 1)
  }

  func pick(_ idx: Int) {
    guard !sel.contains(idx) else { return }
    if sel.count >= 4 { toast("The group is full: remove someone first"); return }   // LV-08
    sel.append(idx)
  }
  func remove(_ idx: Int) { sel.removeAll { $0 == idx }; crtPicked = nil }

  /// `#gAdd` (8808): a guest by name; blank index = estimated 18.0.
  func addGuest(name: String, index: Double?) {
    let n = name.trimmingCharacters(in: .whitespaces)
    guard !n.isEmpty else { toast("Give your guest a name"); return }
    roster.append(LivePlayer(n: n, i: index ?? 18.0, ci: -1, guest: true, est: index == nil, team: nil))
    if sel.count < 4 { sel.append(roster.count - 1) }
    toast(n + " added" + (index == nil ? " (estimated 18.0 index)" : ""))
  }

  /// `#rosterFind` onPick (8843): anyone on the app lands as a non-posting player.
  func addFromPicker(profileId: UUID, name: String?, index: Double?) {
    if roster.contains(where: { $0.pid == profileId }) { toast("\(name ?? "That golfer") is already in the picker"); return }
    roster.append(LivePlayer(id: "p:\(profileId.uuidString)", n: name ?? "Golfer", i: index ?? 18, ci: -1, guest: true, est: index == nil, buddy: true, pid: profileId, team: nil))
    if sel.count < 4 { sel.append(roster.count - 1) }
  }
  var pickerExcluded: Set<UUID> { Set(roster.compactMap(\.pid)) }

  /// The plan bridge's "Load it →" (8365).
  func loadPlan() {
    guard let sr = plan else { return }
    if let c = sr.course_label, !c.isEmpty { state.course.label = c }
    var added = 0
    var missed: [String] = []
    for nm in sr.tagged_names ?? [] {
      if let i = roster.firstIndex(where: { $0.n.lowercased() == nm.lowercased() }) {
        if !sel.contains(i), sel.count < 4 { sel.append(i); added += 1 }
      } else { missed.append(nm) }
    }
    planDismissed = true
    plan = nil
    toast(added > 0 ? "Loaded\(missed.isEmpty ? "" : " — add \(missed.joined(separator: ", ")) below")"
                    : (sr.course_label != nil ? "Course loaded — pick your group below" : "Pick your group below"))
  }

  // MARK: the court (7253–7296, 7354–7370)

  var courtTeams: [[Int]] { LivePairings.teams(pairing: state.pairing) }

  func courtSwap(_ a: Int, _ b: Int) {
    guard let p = LivePairings.swap(pairing: state.pairing, a, b) else { return }
    state.pairing = p
    crtPicked = nil
  }

  /// tap-tap: pick, then tap someone across the line to trade places
  func courtTap(_ pos: Int) {
    guard let other = crtPicked else { crtPicked = pos; return }
    if other == pos { crtPicked = nil; return }
    let T = courtTeams
    if T[0].contains(other) == T[0].contains(pos) { crtPicked = pos } else { courtSwap(other, pos) }
  }

  // MARK: the course (6900–6934)

  /// A tee picked from the search: rating + slope + label, then the real card.
  func applyTee(course: CourseHit, tee: CourseTee) async {
    state.course.label = course.label + (tee.tee_name.map { " · \($0)" } ?? "")
    state.course.courseId = course.id
    if let t = tee.tee_name { state.course.tee = t }
    state.course.note = nil
    state.rating9 = tee.number_of_holes == 9
    state.course.rating = tee.course_rating
    state.course.slope = tee.slope_rating
    // D73: a real 9-hole tee flips the live round to a nine — its rating IS a 9-hole rating
    if tee.number_of_holes == 9 { state.holes = 9; state.rating9 = true }
    if state.course.parsCourse != course.id {
      state.course.pars = LiveCourseCard.postParStd
      state.course.siLoaded = nil
      state.course.estimate(holes: state.liveHoles)
      state.course.parsCourse = course.id
      state.course.note = nil
    }
    // OE-4 / R-N · THE BOOK FIRST, THE NETWORK UNDERNEATH. Three sequential
    // reads used to run before the phone's own card was consulted, so a golfer
    // on one bar scored against `LiveCourseCard.postParStd` — a fabricated
    // par-72 template — while they waited. The kept card is drawn immediately
    // and the server's answer, which is the authority and may be newer,
    // replaces it when it lands.
    if let saved = await repo.savedCourseHoles(courseId: course.id, teeName: tee.tee_name,
                                               rating: tee.course_rating, want: state.liveHoles) {
      state.course.load(holes: saved, playing: state.liveHoles)
    }
    if scoreOnPhone { return }
    _ = await CourseBookStore().prepare(course)
    guard state.course.courseId == course.id, state.course.tee == (tee.tee_name ?? "") else { return }
    if let rows = await repo.courseHoles(courseId: course.id, teeName: tee.tee_name,
                                         rating: tee.course_rating, want: state.liveHoles) {
      state.course.load(holes: rows, playing: state.liveHoles)
    }
  }

  func saveCard(front: [Int], back: [Int]?) {
    state.course.save(front: front, back: back, nine: state.liveHoles == 9)
    toast(scoreOnPhone ? "Pars set for this scorecard." : "Card saved: every league gets it from here")
  }

  // MARK: - tee off (8902–9006)

  func teeOff() async {
    guard !busy, !state.active else { return }
    if scoreOnPhone { teeOffLocally(); return }
    let g = state.game
    if let problem = g.teeOffProblem(players: sel.count) { toast(problem); return }
    // D107: the tee sheet is the free door — no league required. A league-less
    // round seats every player on the guest_profile_id rail below.
    let league = leagueId
    let players = picked
    var s = state
    s.players = players
    s.teams = LiveRoundState.defaultTeams(count: players.count)
    let mode: LiveMode = (g.teamable && players.count == 4) ? state.mode : .teams
    if g.teamable, players.count == 4, mode != .solo { s.teams = LivePairings.teams(pairing: state.pairing) }
    s.mode = mode
    s.stake = g.money ? max(0, state.stake) : 0
    s.wolfOrder = g == .wolf ? [0, 1, 2, 3].shuffled() : nil
    s.stage = .live; s.active = true; s.hole = 0
    s.scores = players.map { _ in Array(repeating: nil, count: 18) }
    s.wolf = Array(repeating: nil, count: 18)
    s.scts = players.map { _ in Array(repeating: 0, count: 18) }
    s.wcts = Array(repeating: 0, count: 18)
    s.code = nil; s.lr = nil; s.leagueId = league; s.pmap = nil; s.guestTokens = [:]
    s.mine = true; s.host = nil; s.visitor = false

    busy = true
    defer { busy = false }
    await repo.drainAbandons(disk: disk)
    let snap = s.course.snapshot(holes: s.liveHoles, rating9: s.rating9)
    let playersJSON: JSONValue = .array(players.map { p in
      (p.guest || league == nil)   // D107: no member tags without a league — everyone is a known golfer by profile
        ? .object(["guest_name": .string(p.n), "guest_index": p.est ? .null : .number(p.i),
                   "guest_profile": p.pid.map { .string($0.uuidString.lowercased()) } ?? .null])
        : .object(["member_id": p.mid.map { .string($0.uuidString.lowercased()) } ?? .null])
    })
    // D178 · belt AND braces. These two lines ran UNCONDITIONALLY, before the
    // per-game switch, and indexed `players` by whatever `defaultTeams` had
    // returned — which was `[[0,1],[2,3]]` for every count but 2. A round with
    // one player (the default: "Just score", only you) or three (legal for
    // skins) crashed here, on the first Tee off a tester ever taps.
    //
    // `defaultTeams` is now in-range by construction; this filter is the second
    // wall, and it matches what LiveResult.swift:111 and LiveCopy.swift:24 have
    // always done when reading the same array. Only match play and Sunningdale
    // read a side, and both refuse any count but 2 or 4.
    func side(_ t: Int) -> JSONValue {
      guard t < s.teams.count else { return .array([]) }
      return .array(s.teams[t].compactMap { players.indices.contains($0) ? .string(players[$0].n) : nil })
    }
    let sideA = side(0), sideB = side(1)
    let est: JSONValue = .bool(s.course.siEst)
    let cfg: JSONValue
    switch g {
    case .match:
      cfg = mode == .solo ? .object(["stake": .number(s.stake), "mode": .string("solo"), "si_estimated": est])
                          : .object(["stake": .number(s.stake), "side_a": sideA, "side_b": sideB, "si_estimated": est])
    case .wolf:
      // same guard: wolfOrder is [0,1,2,3] and Wolf refuses anything but four,
      // but a stale order from a rehydrate must not be able to reach past the end
      cfg = .object(["stake": .number(s.stake),
                     "order": .array((s.wolfOrder ?? []).compactMap { players.indices.contains($0) ? .string(players[$0].n) : nil }),
                     "si_estimated": est])
    case .skins:
      cfg = .object(["stake": .number(s.stake), "si_estimated": est])
    case .sunningdale:
      cfg = mode == .solo ? .object(["unit": .number(s.stake), "mode": .string("solo")])
                          : .object(["unit": .number(s.stake), "side_a": sideA, "side_b": sideB])
    case .score:
      cfg = .object([:])
    }
    do {
      let out = try await repo.start(league: league, label: s.course.label.trimmingCharacters(in: .whitespaces), snapshot: snap, game: g, players: playersJSON, config: cfg,
                                     apiCourseId: s.course.courseId)
      s.lr = out.lr
      // The server abandons an unfinished round 24h from here. The card carries
      // the moment so the phone can SAY that deadline instead of guessing it.
      s.startedAt = LiveFmt.now()
      retiredCard = false
      s.code = out.code   // D85: nil on an old DB — sync quietly off, the pencil still works
      s.pmap = out.seats.map(\.id)
      for seat in out.seats where seat.guestName != nil { if let t = seat.claimToken { s.guestTokens[String(seat.position)] = t } }
      state = s
      await disk.save(state)
      await joinSync()
      if let league { await session.announceOpen(league: league, lr: out.lr) }   // D107: no league channel to ring
      // D163 · the round is REAL now — tell everyone who accepted over Bluetooth,
      // then stop advertising. The stop used to be the first line of teeOff(),
      // which killed the wire before there was anything to announce on it: the
      // accepters were left holding a yes and nothing else.
      // D169 · announce, THEN let the wire settle. `send` only queues the
      // bytes — MultipeerConnectivity transmits asynchronously — so calling
      // stopNearby() on the next line tore the session down microseconds later
      // and the `teed` doorbell never left the phone. That is why the invited
      // golfer saw the ask, said yes, and then watched nothing happen.
      if !accepted.isEmpty {
        let who = Array(accepted)
        nearby.teedOff(out.lr, to: who)
        Task { @MainActor [weak self] in
          try? await Task.sleep(for: .seconds(3))
          self?.stopNearby()
        }
      } else {
        stopNearby()
      }
      LiveActivityHost.start(state)   // D155 · one tap back from a locked phone
      toast("On the tee, good luck everybody")
    } catch {
      toast(HumanError.text(error, prefix: "Could not start the round."))
      state.active = false; state.stage = .setup
    }
  }

  func backToSetup() {
    state.stage = .setup; state.active = false
    Task { await LiveActivityHost.end(); await session.leave() }
  }

  // MARK: - scoring (8433–8441, 7751–7757)

  func step(_ pi: Int, _ d: Int) {
    let h = state.hole
    let cur = state.scores[pi][h]
    state.scores[pi][h] = cur == nil ? state.course.pars[h] : max(1, cur! + d)
    markScore(pi, h)
    CSHaptic.selection()
    if state.holeDone(h) { CSHaptic.impact(.medium) }
  }

  private func markScore(_ pi: Int, _ h: Int) {
    state.ensureClocks()
    LiveActivityHost.update(state)   // D155 · the island follows the card
    let now = LiveFmt.now()
    state.scts[pi][h] = now
    persist()
    guard sendable, let pid = state.pmap?[safe: pi] else { return }
    let m = LiveMessage.score(pid: pid, hole0: h, strokes: state.scores[pi][h], cts: now)
    Task { await session.send(m) }
  }

  func setWolf(_ pick: LiveWolfPick?) {
    let h = state.hole
    state.wolf[h] = pick
    state.ensureClocks()
    let now = LiveFmt.now()
    state.wcts[h] = now
    persist()
    CSHaptic.selection()
    guard sendable else { return }
    let m = LiveMessage.wolf(hole0: h, pick: pick, cts: now)
    Task { await session.send(m) }
  }

  // D155 · walking holes moves the island too — it shows the hole you are on
  func prevHole() { state.hole = max(0, state.hole - 1); persist(); LiveActivityHost.update(state) }
  func nextHole() { state.hole = min(state.liveHoles - 1, state.hole + 1); persist(); LiveActivityHost.update(state) }

  private var sendable: Bool { state.active && state.code != nil }

  /// `persistLive`: a guest phone never snapshots.
  private func persist() {
    guard guest == nil, state.active, state.lr != nil else { return }
    if state.onThisPhone { state.ts = LiveFmt.now(); flushLocalCard(); return }
    let s = state
    Task { await disk.save(s) }
  }

  // MARK: - sync (D85)

  func joinSync() async {
    guard state.active, let lr = state.lr, let code = state.code else { return }
    let name = state.meIndex.map { state.players[$0].n } ?? myName ?? "A golfer"
    let key = guest?.token.uuidString.lowercased() ?? myPid?.uuidString.lowercased() ?? "p" + UUID().uuidString.lowercased().prefix(8)
    await session.join(lr: lr, code: code, guest: guest?.token, name: name, presenceKey: key)
    // D125 · and record it server-side. Presence is ephemeral; `attested` needs
    // a fact that outlives the socket. A guest pencil has no account to stamp,
    // so it stays on the claim-link path exactly as before.
    if guest == nil { await repo.liveJoin(lr) }
  }

  // MARK: - the reconnect

  /// **A phone that finds signal again drains what it is holding.**
  ///
  /// `flush()` had exactly three triggers: the next score tap, a SUCCESSFUL
  /// channel subscribe, and foregrounding. All three are things the golfer
  /// does. So a phone sitting open on the play screen, holding eighteen
  /// strokes, that walked back into coverage on the 18th green drained
  /// nothing — and if it stayed that way past the server's twenty-four hours
  /// the whole card became un-landable. The network telling us it is back is
  /// the one trigger that was missing.
  private var pathMonitor: NWPathMonitor?
  private var wasOffline = false

  func watchReachability() {
    guard pathMonitor == nil else { return }
    let m = NWPathMonitor()
    m.pathUpdateHandler = { [weak self] path in
      Task { @MainActor in
        guard let self else { return }
        let up = path.status == .satisfied
        // **The flag is written BEFORE the awaits.** In a `defer` it ran at
        // closure exit, after `flush()` had suspended and released the actor —
        // so a drop DURING the flush was overwritten by the stale `up` from
        // before it, `wasOffline` stuck false, and the reconnect disarmed
        // itself permanently under exactly the flapping signal it is for.
        let cameBack = up && self.wasOffline
        self.wasOffline = !up
        // Only on the EDGE from down to up, so a Wi-Fi/cellular flap does not
        // spin the queue, and never while there is nothing to send.
        guard cameBack, self.state.active, self.state.lr != nil else { return }
        if await self.session.isJoined { await self.session.flush(); await self.session.reconcile() }
        else { await self.joinSync() }
        self.queued = await self.session.queued()
      }
    }
    m.start(queue: DispatchQueue(label: "cs.live.path"))
    pathMonitor = m
  }

  func stopWatchingReachability() {
    pathMonitor?.cancel()
    pathMonitor = nil
    wasOffline = false
  }

  /// Phone back from a pocket: drain the queue, then pull truth.
  func foregrounded() {
    if scoreOnPhone { return }
    Task {
      // D167 · LOOK AGAIN. `rehydrate()` was latched to run once per process
      // (`if !rehydrated`), so a round that started while this app was already
      // running was never discovered: no banner, no bar, and a tapped push
      // landed on the empty tee sheet. The starter never noticed because their
      // own phone resumes from its LOCAL snapshot; only the invited golfer,
      // who has no snapshot and depends entirely on the server, saw nothing.
      if !(state.active && state.stage == .live) { await refreshLive() }
      if await session.isJoined { await session.flush(); await session.reconcile() }
      else { await joinSync() }
      queued = await session.queued()
    }
  }

  /// D167 · ask the server whether a round is waiting, ignoring the once-per-
  /// process latch. Safe to call often: it no-ops while a round is already up,
  /// and `LiveRehydrator` prefers a local snapshot over the network anyway.
  func refreshLive() async {
    guard !scoreOnPhone, myPid != nil else { return }
    guard !(state.active && state.stage == .live) else { return }
    await rehydrate()
    if state.active, state.stage == .live { LiveActivityHost.start(state) }
  }

  private func handle(_ e: LiveRoundSession.Event) {
    guard !state.onThisPhone else { return }
    switch e {
    case .message(let m):
      guard state.active else { return }
      if m.t == "finish" || m.t == "gone" { endedRemotely(m.status ?? "final"); return }
      if LiveMerge.apply(m, to: &state) { persist() }
    case .state(let d):
      guard state.active else { return }
      if let st = LiveMerge.applyState(d, to: &state) { endedRemotely(st); return }
      persist()
    case .presence(let names): presence = names
    case .queued(let n): queued = n
    case .status(let s): syncStatus = s
    case .retired(let lr):
      // The strokes cannot land any more. **The STORE keeps the card, not the
      // session** — the session can only reach the disk snapshot, and a guest
      // pencil never writes one (`persist()` refuses), so the session's own
      // retire kept nothing for the phone most likely to be scoring offline
      // while the badge told it the card was saved. The store holds the live
      // state for host and guest alike, and it is fresher than the disk.
      guard state.active, state.lr == lr else { return }
      retiredCard = true
      let card = state
      Task { await disk.retire(card, lr: lr) }
    }
  }

  /// **This round's strokes can no longer reach the server, and the card has
  /// been kept.** Set once, from the session's `retired` event. The play
  /// surface reads it to stop claiming the round is syncing and to offer the
  /// only honest way home: post it yourself.
  var retiredCard = false

  /// D-offline · the kept card the golfer has asked to post, waiting for the
  /// composer to open and take it.
  ///
  /// It lives HERE rather than on `Presenter` for a mechanical reason worth
  /// knowing: `MainTabView`'s body reads `$presenter.<member>` a few dozen
  /// times in one modifier chain, and that chain is already at the edge of
  /// what the type-checker will do in a single expression — two more members
  /// on `Presenter` tipped it over ("unable to type-check in reasonable
  /// time"), on a line nowhere near the change. This store is a singleton the
  /// composer can already reach, and it is the owner of kept cards anyway.
  var pendingPost: UUID?

  /// The cards kept on disk because their strokes could never land. Nothing
  /// removes one automatically — a golfer posts it or dismisses it.
  func keptCards() async -> [LiveRoundState] {
    guard let owner = myPid else { return [] }
    let local = (try? offline.rounds(owner: owner)) ?? []
    let remote = await disk.unsynced().filter { $0.players.contains { $0.me && $0.pid == owner } }
    return (local.filter { $0.localCompleted == true } + remote).sorted { $0.ts > $1.ts }
  }

  /// `liveRoundEndedRemotely` (7821).
  private func endedRemotely(_ status: String) {
    guard state.active else { return }
    if let g = guest {
      Task { await session.leave() }
      if g.signedIn {
        guest = nil
        state.active = false; state.stage = .setup
        if status == "final" {
          toast("Round finished — putting your card on your record")
          Task { if let t = await ClaimFlow.consume().toast { toast(t) } }
        } else { toast("That round was scrapped") }
        leaveRequested = true
        return
      }
      // the kiosk guest's link now points at a finished round — the claim door
      state.active = false
      guestEnded = status
      return
    }
    let wasVisitor = state.visitor
    // **KEEP THE CARD HERE TOO.** This is the path a fully-scored round takes
    // when the daily tick abandons it: the app is still holding the round, the
    // queue is empty so the flush retires nothing, and `reconcile()` comes
    // back "abandoned". Deleting the snapshot was the last copy of a card that
    // was still postable a second earlier — `finish_live_round` refuses only
    // `status = 'final'`. A round that FINISHED is the opposite case: its
    // cards are already in `rounds`, so any kept copy is a second post waiting
    // to happen and must go.
    let ended = state
    if let lr = state.lr {
      Task {
        if status == "final" { await disk.removeUnsynced(lr) } else { await disk.retire(ended, lr: lr) }
        await disk.removeSnapshot(lr)
      }
    }
    Task { await session.leave() }
    state.active = false; state.stage = .setup
    retiredCard = false
    toast(status != "final" ? (ended.anyScored
            ? "That round closed — your card is saved on this phone to post yourself"
            : "That round was scrapped")
      : wasVisitor ? "Round finished — ask them for your scorecard link to keep it"
      : "Round finished from another phone — the cards posted")
    leaveRequested = true
    Task { await primeRoster() }
  }

  /// The league channel's `live_open` doorbell (14713): re-read unless already in it.
  func handleLiveOpen(lr: UUID?) {
    if let lr, state.active, state.lr == lr { return }
    Task {
      // D167 · a push can land before `configure()` has set myPid on a cold
      // start, and the rehydrator returns empty-handed without it. Try, and if
      // identity was not ready yet, try once more after it is.
      await refreshLive()
      if !(state.active && state.stage == .live) {
        try? await Task.sleep(for: .milliseconds(600))
        await refreshLive()
      }
    }
  }

  /// `rehydrateLiveRound` (7604).
  func rehydrate() async {
    guard !state.onThisPhone else { return }
    let out = await LiveRehydrator.run(current: state.active ? state : nil, myPid: myPid, repo: repo, disk: disk)
    if let s = out.state {
      let was = state.lr
      state = s
      let joined = await session.isJoined
      if guest == nil, was != s.lr || !joined { await joinSync() }
    } else if out.retired {
      state = .fresh()
      rosterPrimed = false
    }
    if let t = out.toast, out.state?.lr != nil || out.retired { toast(t) }
    // D155 · a crash or force-quit can leave an island with no round behind it
    await LiveActivityHost.clearStale(hasLiveRound: state.active && state.stage == .live)
    if state.active, state.stage == .live { LiveActivityHost.start(state) }
    queued = await session.queued()
  }

  // MARK: - the guest pencil (7881)

  /// `enterGuestLive(d, token, {signedIn})`.
  func enterGuest(_ d: JSONValue, token: UUID, signedIn: Bool) -> Bool {
    guard let (s, g) = LiveRehydrator.guestRound(d, token: token, signedIn: signedIn) else { return false }
    var st = s
    _ = LiveMerge.applyState(d, to: &st)   // the pull came with the door — merge its scores now
    st.hole = st.firstOpenHole
    state = st
    guest = g
    guestEnded = nil
    Task { await joinSync() }
    return true
  }

  /// D88/D85: a pencil scores but never finishes, scraps, or re-configures.
  var isPencilOnly: Bool { guest != nil || state.visitor }

  // MARK: - finish (9109–9177)

  func finish(casual: Bool) async -> Bool {
    guard !busy else { return false }
    if state.onThisPhone {
      let kept = keepLocalRound()
      if kept { await LiveActivityHost.end() }
      return kept
    }
    guard let lr = state.lr else { toast("This round never left your phone — tee off again to post it"); return false }
    await LiveActivityHost.end()          // D155 · nothing outlives its round
    busy = true
    defer { busy = false }
    let result = LiveResultBuilder.gameResult(state)
    do {
      let out = try await repo.finish(lr: lr, cards: LiveCopy.cards(state), casual: casual, result: casual ? nil : result?.json)
      if sendable { await session.send(.finish(cts: LiveFmt.now()), broadcastOnly: true) }
      await session.leave()
      await disk.removeSnapshot(lr)
      await disk.removeQueue(lr)
      // The round landed. Any card kept for it is now a duplicate waiting to
      // be posted twice.
      await disk.removeUnsynced(lr)
      let course = state.course.label
      state.active = false; state.stage = .setup
      retiredCard = false
      recap = LiveRecapData(outcome: out, result: casual ? nil : result, lr: lr, course: course, date: Date())
      CSHaptic.success()
      await primeRoster()
      return true
    } catch {
      toast(HumanError.text(error, prefix: "Finish failed."))
      return false
    }
  }

  // MARK: - scrap (9332)

  func scrap() async {
    if let owner = state.localOwner, let id = state.lr {
      do {
        try offline.remove(owner: owner, id: id)
        state = .fresh(); localSaveError = nil
        await LiveActivityHost.end()
        toast("Round discarded — nothing posted")
      } catch { localSaveError = "Couldn’t discard this scorecard. Try again." }
      return
    }
    await LiveActivityHost.end()          // D155 · nothing outlives its round
    if sendable { await session.send(.gone(cts: LiveFmt.now()), broadcastOnly: true) }
    await session.leave()
    if let lr = state.lr {
      do { try await repo.abandon(lr) } catch {
        // the abandon MUST eventually land or this corpse resurrects on the next boot — queue it
        await disk.queueAbandon(lr)
      }
      await repo.drainAbandons(disk: disk)
      await disk.removeQueue(lr)
      // Scrapping is the golfer saying he does not want it. Keeping a card
      // behind his back is the corpse this path exists to bury.
      await disk.removeUnsynced(lr)
    }
    await disk.clearSnapshots(keep: nil)
    state = .fresh()
    retiredCard = false
    rosterPrimed = false
    await primeRoster()
    toast("Round scrapped — nothing posted")
  }
}

extension Array {
  subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
