// Cup Season — the composer's state (index.html `state.post` and the
// `#postBtn` handler 6325–6500, `onTee` 6863, the photo/scan wiring 6521–6657).
//
// One model per opening of the ⊕. The card is a value (`PostCard`, kit); this
// object adds what only the phone knows — the golfer, the open league, the
// photo bytes, the draft timer — and runs the post: upload → insert → holes →
// breadcrumbs → ceremony → epilogue or partner claims. The web's order, kept.

import SwiftUI
import CSDesign
import CupSeasonKit

@MainActor
@Observable
final class PostRoundModel {
  var card = PostCard() { didSet { recalc(); scheduleDraft() } }
  var preview: PostPreview?
  /// `#inDate` — mirrored into `card.date` as a calendar String.
  var day = Date() { didSet { let iso = CSDate.iso(day, calendar: ScheduleDates.gregorian); if card.date != iso { card.date = iso } } }
  var memory: [PostCourseMemory] = []
  var scanEnabled = false
  var photo: UIImage?
  var photoJPEG: Data?
  var busy = false
  var scanning = false
  var draftRestored = false

  // sheets and the ceremony
  var showPars = false
  var showEvenPar = false
  var scanToPick: PostScan?
  var ceremony: PostCeremony?
  var epilogue: PostEpilogueShow?
  var partners: PostPartnersShow?
  var pendingEpilogue: PostEpilogueShow?
  var pendingPartners: PostPartnersShow?
  /// `_lastPostPhoto` — the recap card rides it
  var recapPhoto: UIImage?
  var acceptedRoundId: UUID?
  /// D239 · who was out there. Optional, bounded by the buddies and league
  /// mates the golfer actually plays with, and never a vouch (L-19).
  var partnerChoices: [Person] = []
  var playedWith: [UUID] = []

  private let draftOwner: UUID?
  private let store: SessionStore
  private let toast: CSToastCenter
  private let svc = PostService()
  private let sched = ScheduleService()
  private let people = PeopleService()
  private var draftTask: Task<Void, Never>?
  private var openedAt = Date()
  private var typedSomething = false

  /// D349 · the date this composer stamped into the card at construction.
  /// `isUntouched(defaultDate:)` needs it to tell the machine's date from the
  /// golfer's, and every draft gate below asks that question rather than
  /// `isBlank`, which `card.date` had already made permanently false.
  @ObservationIgnored private var defaultDay = CSDate.iso(Date(), calendar: ScheduleDates.gregorian)
  /// D350 · the ordinary post's request identity. Minted once for the round
  /// being composed and **frozen across retries** — regenerating it after a
  /// timeout is exactly how a committed round becomes two. Mirrored into
  /// `PostRequestStore` (owner-scoped, outside the draft) the moment it is
  /// minted, and released only when the server's answer has been RECOVERED:
  /// an acceptance, or a status read that says the request never landed.
  /// "Start over" does not release it — the next post under a different card
  /// resolves it through `round_post_status` rather than guessing.
  @ObservationIgnored private var ordinaryRequest: UUID?
  /// D354 · the plan this composer is filling in. A THIRD identity, and
  /// deliberately not mixed with the other two: `seededFrom` is a kept
  /// scorecard that already exists, `ordinaryRequest` is what the server
  /// deduplicates the post on, and this is display context. It never travels
  /// with the round.
  private(set) var plan: PlanContext?
  /// Set when a plan arrived but could not be applied without the golfer
  /// saying so. The screen puts the question; nothing is written until it does.
  var planAsking: PlanContext?
  /// D350 · the owner-scoped request pointer exists and cannot be read. The
  /// composer refuses to post rather than mint over an identity it cannot see.
  @ObservationIgnored private var requestUnreadable = false
  /// D350 · a recovery finished with a round that had already landed. The
  /// screen opens its receipt so the golfer sees the round the server holds.
  var recoveredRoundId: UUID?

  init(store: SessionStore, toast: CSToastCenter) {
    self.store = store; self.toast = toast; self.draftOwner = store.session?.user.id
    let iso = CSDate.iso(day, calendar: ScheduleDates.gregorian)
    defaultDay = iso
    card.date = iso
  }

  /// D-offline · take a whole card from somewhere else — today, a live round
  /// the server abandoned before its strokes landed (`KeptCards.compose`). The
  /// grid is set to holes so the golfer SEES the strokes that were kept and
  /// can fix a gap, rather than being handed a total he has to trust.
  /// The kept round this composer was seeded from, released once it posts.
  var seededFrom: UUID?

  /// D354 · what a plan may do to this composer, and the three states that
  /// decide it. Returns true when the card was filled in; false when the
  /// golfer has to be asked first (`planAsking` carries the question) or when
  /// the composer is not free to take it at all.
  @discardableResult
  func take(plan ctx: PlanContext) -> Bool {
    // 1 · a kept phone scorecard is never replaced. It is a card that already
    //     exists, with strokes in it; a plan is a line in a diary.
    if seededFrom != nil {
      planAsking = nil
      toast.show("Finish your kept scorecard first.", kind: .failed)
      return false
    }
    // 2 · a round is already out there under a frozen request. Rewriting the
    //     date would change the body of a request the server may already hold,
    //     and D350's whole guarantee is that the body does not move.
    if ordinaryRequest != nil || requestUnreadable {
      planAsking = nil
      toast.show("Finish the round you already sent first.", kind: .failed)
      return false
    }
    // 3 · the same plan again is a resume, not a question.
    if plan?.planId == ctx.planId, !card.isUntouched(defaultDate: defaultDay) {
      plan = ctx
      return true
    }
    // 4 · a card the golfer has started is their work. It is not replaced
    //     without a tap that says so.
    guard card.isUntouched(defaultDate: defaultDay) else {
      planAsking = ctx
      return false
    }
    applyPlan(ctx)
    return true
  }

  /// The only place a plan writes to the card.
  func applyPlan(_ ctx: PlanContext) {
    planAsking = nil
    plan = ctx
    card.fill(plan: ctx)
    if let iso = card.date, let d = CSDate.local(iso, calendar: ScheduleDates.gregorian) { day = d }
    typedSomething = true
    recalc()
    scheduleDraft()
  }

  func seed(_ c: PostCard, from lr: UUID? = nil) {
    seededFrom = lr
    if let lr, let uid, let pending = try? OfflinePostDisk.shared.read(owner: uid, request: lr) {
      card = pending.card
    } else { card = c }
    seededFrom = lr
    if let iso = card.date, let d = CSDate.local(iso, calendar: ScheduleDates.gregorian) { day = d }
    typedSomething = true
    recalc()
  }

  // MARK: - who and where

  var uid: UUID? { store.session?.user.id == draftOwner ? draftOwner : nil }
  var profile: Me.Profile? { store.me?.profile }
  /// D229 · the membership this round belongs to is derived from the DATE, the
  /// same way `post_round` derives it on the server — never from
  /// `preferredLeague`, which is navigation memory and was answering a scoring
  /// question it had no business answering (D123/L-13). The composer uses it
  /// for the allowance it previews at, and the ceremony's league name comes
  /// back from the server with the round.
  var membership: Me.Membership? {
    PostSeasonRule.membership(playedOn: card.date, memberships: store.me?.memberships ?? [])
  }
  var myIndex: Double? { profile?.index_current }
  /// "Add my round · your index 12.4" — the REAL number (landmine 7.12).
  /// No minted number = say "building", not a dash (web 14242, setup-QA S6-03).
  ///
  /// NW-5 · it says **index**, not "your number". R-M's accepted cost is that
  /// two handicap nouns now coexist — your *index* (the figure on your card)
  /// and your *playing HCP* (that index under this league's allowance) — and
  /// that they be "distinguished once, at first contact, and never used
  /// interchangeably". THIS IS THE SCREEN THAT SHOWS BOTH: the preview chip a
  /// few rows below reads "2.4 vs your playing HCP", and under a Standard
  /// league's 95% the two figures differ by about half a shot. "Your number"
  /// above "your playing HCP" made them look like one figure printed twice.
  var eyebrow: String {
    myIndex == nil ? "Add my round · your index builds at 3 rounds" : "Add my round · your index " + CSCopy.index(myIndex)
  }

  // MARK: - open (`switchView('post')`, 4159)

  func open() async {
    openedAt = Date()
    svc.event(PostEvent.open)
    restoreDraft()
    // D350 · a request that outlived its draft (a "Start over", a TTL, a
    // relaunch) is picked up here so the next post resolves it rather than
    // minting a second id beside it. A stored value that cannot be read is
    // NOT absent: it is reported, and this composer will not mint over it.
    if let uid {
      switch PostRequestStore.read(owner: uid) {
      case .pending(let id): if ordinaryRequest == nil { ordinaryRequest = id }
      case .unreadable: requestUnreadable = true
      case .none: break
      }
    }
    if let uid { memory = await svc.courseMemory(uid) }
    scanEnabled = await svc.scanEnabled()
    partnerChoices = await people.playedWith()
  }

  func toggle(partner id: UUID) {
    if let i = playedWith.firstIndex(of: id) { playedWith.remove(at: i) } else if playedWith.count < 7 { playedWith.append(id) }
    CSHaptic.selection()
  }

  // MARK: - the preview

  private func recalc() {
    // D178 · at the league's allowance, not at 100%. `membership` is the same
    // preferred-league pick the rest of the sheet uses; no league = nil = 100%.
    preview = PostCalc.preview(card, myIndex: myIndex, allowance: membership?.settings?.handicap_allowance)
    if !card.isUntouched(defaultDate: defaultDay) { typedSomething = true }
  }
  var calcMessage: String { preview?.message ?? (typedSomething ? PostCalc.emptyMessageAfterTyping : PostCalc.emptyMessage) }
  var grossLine: String { preview?.grossLine ?? PostCalc.emptyGrossLine }

  /// A hand-typed rating is assumed to be an 18-hole rating (D72): only
  /// manual entry clears `rating9`; a tee pick sets it afterwards.
  func typedRating(_ s: String) { card.rating = s; card.rating9 = false }

  func setSide(_ n: Int) { guard card.side != n else { return }; card.side = n; CSHaptic.selection() }
  func setMode(_ m: PostMode) {
    guard card.mode != m else { return }
    card.mode = m
    svc.event(PostEvent.modeSwitch, ["to": .string(m.rawValue)])
  }

  // MARK: - course

  func fill(_ m: PostCourseMemory) { card.fill(memory: m); toast.show(PostCourseMemory.filledToast) }

  /// The tee-pick handler (6748–6756) + `onTee` (6863–6902).
  func teePicked(course: CourseHit, tee: CourseTee) {
    let nine = tee.number_of_holes == 9
    card.teePicked(courseId: course.id, label: course.label + (tee.tee_name.map { " · \($0)" } ?? ""),
                   rating: tee.course_rating ?? 0, slope: tee.slope_rating ?? 0, nineHoleTee: nine)
    toast.show("Tees set — rating and slope filled", kind: .confirmed)
    Task {
      await sched.cacheCourse(course.id)
      guard let (pars, teeNine) = await svc.teePars(courseId: course.id, teeName: tee.tee_name, rating: tee.course_rating),
            card.courseId == course.id else { return }
      card.loadPars(pars, nineHoleTee: teeNine)
    }
  }

  // MARK: - the grid

  func plus(_ i: Int) { card.plus(i); CSHaptic.selection() }
  func minus(_ i: Int) { card.minus(i); CSHaptic.selection() }

  func setPars(front: String, back: String) -> Bool {
    guard let p = PostPars.parse(front: front, back: back, nine: card.side == 9, current: card.pars) else { toast.show(PostPars.rejectToast); return false }
    card.pars = p; card.scores = p
    toast.show(PostPars.setToast)
    return true
  }

  func startOver() {
    if seededFrom != nil {
      toast.show("Close this scorecard to keep it. Open a new round separately."); return
    }
    card.startOver(); setPhoto(nil); clearDraft(); toast.show("Card cleared", kind: .confirmed)
  }
  func scrapScan() { card.scrapScan(); toast.show("Scan scrapped — type your nines in", kind: .confirmed) }

  // MARK: - photo (6521–6578)

  func setPhoto(_ image: UIImage?) {
    photo = image
    photoJPEG = image.flatMap { PostPhoto.compress($0, maxDim: 1600, quality: 0.82) }
  }

  func photoPicked(_ image: UIImage?) {
    guard let image else { toast.show("Couldn’t read that image", kind: .failed); return }
    setPhoto(image)
  }

  // MARK: - scan (6590–6657)

  func scanPicked(_ image: UIImage?) async {
    guard let image, let shot = PostPhoto.compress(image, maxDim: 2200, quality: 0.9) else { toast.show(PostScan.restingToast); return }
    scanning = true; defer { scanning = false }
    switch await svc.scan(jpeg: shot) {
    case .unavailable(let reason):
      toast.show(reason == "daily_cap" ? PostScan.capToast : PostScan.restingToast)
      if reason == "disabled" { scanEnabled = false }
    case .unreadable:
      toast.show(PostScan.unreadableToast)
    case .read(let scan):
      pendingScanShot = image
      if scan.players.count == 1 { apply(scan, row: 0) } else { scanToPick = scan }
    }
  }
  private var pendingScanShot: UIImage?

  func apply(_ scan: PostScan, row: Int) {
    scanToPick = nil
    let misses = scan.apply(row: row, to: &card)
    if let d = card.date, let date = CSDate.local(d, calendar: ScheduleDates.gregorian), CSDate.iso(day, calendar: ScheduleDates.gregorian) != d { day = date }
    if let shot = pendingScanShot { setPhoto(shot) }   // the scan doubles as the round photo
    pendingScanShot = nil
    toast.show(PostScan.readToast(misses: misses))
  }

  // MARK: - picks (6217–6270)

  private var draftKey: String { PostDraft.key + "." + (draftOwner?.uuidString ?? "signed-out") }

  private func scheduleDraft() {
    draftTask?.cancel()
    let snapshot = card
    let source = seededFrom
    let request = ordinaryRequest
    let planId = plan?.planId
    draftTask = Task {
      try? await Task.sleep(for: .milliseconds(350))
      guard !Task.isCancelled else { return }
      if snapshot.isUntouched(defaultDate: defaultDay) { UserDefaults.standard.removeObject(forKey: draftKey); return }
      if let data = PostDraft.encode(PostDraft(card: snapshot, sourceLive: source, request: request, plan: planId)) { UserDefaults.standard.set(data, forKey: draftKey) }
    }
  }
  /// A draft flush is never proof of server acceptance.
  func flushDraft() {
    draftTask?.cancel()
    if card.isUntouched(defaultDate: defaultDay) { UserDefaults.standard.removeObject(forKey: draftKey); return }
    if let data = PostDraft.encode(PostDraft(card: card, sourceLive: seededFrom, request: ordinaryRequest, plan: plan?.planId)) {
      UserDefaults.standard.set(data, forKey: draftKey)
    }
  }

  private func clearDraft() { draftTask?.cancel(); UserDefaults.standard.removeObject(forKey: draftKey) }

  private func restoreDraft() {
    guard !draftRestored else { return }
    draftRestored = true
    guard let d = PostDraft.decode(UserDefaults.standard.data(forKey: draftKey)) else {
      UserDefaults.standard.removeObject(forKey: draftKey); return
    }
    guard card.isUntouched(defaultDate: defaultDay) else { return }
    seededFrom = d.sourceLive
    // D350 · the frozen request id comes back with the card, so a retry after a
    // relaunch is the same request and not a second round. The owner-scoped
    // store is the second copy, for a draft written before the id existed.
    ordinaryRequest = d.request ?? uid.flatMap { PostRequestStore.pending(owner: $0) }
    // D354 · the plan comes back with the draft so the composer still knows
    // which day it is filling in, and so the same plan does not ask again.
    // Only the id survives a relaunch; the card already carries the facts.
    if let p = d.plan { plan = PlanContext(planId: p, playOn: d.card.date) }
    card = d.card
    if let iso = d.card.date, let date = CSDate.local(iso, calendar: ScheduleDates.gregorian) { day = date }
    toast.show(PostDraft.restoredToast)
  }

  // MARK: - Post (the `#postBtn` handler)

  /// IOS-030 · which field is missing, if any. The composer marks it.
  var blocked: PostCalc.Blocked? { PostCalc.blocked(card) }

  func tapPost() {
    if let b = blocked {
      toast.show(b.message)
      svc.event("post_blocked", ["reason": .string(b.reason)])
      return
    }
    guard preview != nil else { toast.show(PostCalc.Blocked.noCard.message); return }
    if card.needsEvenParGuard { showEvenPar = true; return }
    Task { await submit() }
  }

  func postEvenParAnyway() {
    svc.event(PostEvent.evenParConfirmed)
    card.touched = true
    showEvenPar = false
    Task { await submit() }
  }

  private func submit() async {
    guard !busy, preview != nil else { return }
    // Account switch: the composer was opened by one golfer and the session
    // now belongs to another. Say so rather than returning in silence.
    guard let uid else { toast.show(OrdinaryPost.wrongGolferCopy, kind: .failed); return }
    if seededFrom == nil, requestUnreadable { toast.show(OrdinaryPost.pointerUnreadable, kind: .failed); return }
    busy = true; defer { busy = false }
    // D350 · mint the request identity BEFORE the draft is written, and write
    // it to the owner-scoped store, so the id is durable before anything can
    // go wrong with the call that uses it.
    if seededFrom == nil, ordinaryRequest == nil { ordinaryRequest = UUID() }
    if seededFrom == nil, let r = ordinaryRequest { PostRequestStore.set(r, owner: uid) }
    flushDraft()
    let m = membership
    // D229 · no season on the payload. The server derives it.
    var payload = PostPayload.build(card, seasonId: nil)
    let outcome: PostService.PostOutcome
    /// True when the accepted round already carries its hole detail, because
    /// the server wrote it in the same transaction that accepted the round.
    var holesWritten = false
    do {
      if let lr = seededFrom {
        var pending: OfflinePost
        if let previous = try OfflinePostDisk.shared.read(owner: uid, request: lr) {
          guard previous.accepted == nil else {
            toast.show("This round already posted. Open your round history to view it.", kind: .confirmed); return
          }
          guard previous.card == card else {
            toast.show("A previous post still needs confirmation. Reopen this phone scorecard to retry the original round before editing it.", kind: .failed); return
          }
          pending = previous
        } else {
          guard card.date != nil else { toast.show("Choose the date you played.", kind: .failed); return }
          if card.mode == .holes, card.scores.prefix(payload.holes_played).contains(where: { $0 <= 0 }) {
            toast.show("Fill every hole on this scorecard before posting.", kind: .failed); return
          }
          if let jpeg = photoJPEG {
            guard let path = await svc.uploadPhoto(jpeg, uid: uid) else {
              toast.show("Couldn’t upload the photo. Your scorecard is still on this phone.", kind: .failed); return
            }
            payload.photo_path = path
          }
          pending = OfflinePost(owner: uid, request: lr, card: card, payload: payload, playedWith: playedWith)
          try OfflinePostDisk.shared.save(pending)
        }
        outcome = try await svc.postOnce(pending)
        pending.accepted = outcome.roundId
        try OfflinePostDisk.shared.save(pending)
      } else {
        // D350 (built, amended) · the ordinary round, through `OrdinaryPost`:
        // ONE request id for the life of the intent, never rotated; a frozen
        // envelope written before the call; the same card replayed verbatim;
        // an edited card sent as an amendment under the same id, with the
        // server deciding which body won. No fallback: a server without the
        // function is told to the golfer, not routed around.
        let request = ordinaryRequest ?? UUID()
        let ports = OrdinaryPost.livePorts(svc, owner: uid)
        let result = await OrdinaryPost.run(owner: uid, request: request, card: card, payload: payload,
                                            playedWith: playedWith, jpeg: photoJPEG, ports: ports)
        switch result {
        case .accepted(let out, _, _, let photoDropped, let receiptUnsaved):
          if photoDropped { toast.show(OrdinaryPost.photoDroppedCopy, kind: .failed) }
          if receiptUnsaved { toast.show(OrdinaryPost.receiptUnsavedCopy, kind: .failed) }
          outcome = out
          // post_round_once writes round_holes inside the same transaction.
          holesWritten = true
          // the envelope's photo path is the one that posted
          if let path = (try? OfflinePostDisk.shared.read(owner: uid, request: request))?.payload.photo_path { payload.photo_path = path }
          ordinaryRequest = nil
          PostRequestStore.clear(owner: uid)
        case .alreadyPosted(let landed):
          // It posted. Finish the intent exactly once — a cleared id over a
          // full card is how the next tap minted a second round.
          finishAccepted(landed, owner: uid, message: OrdinaryPost.alreadyPostedCopy)
          return
        case .earlierPosted(let landed):
          // The earlier body under this id landed. This intent is FINISHED
          // with that round; the edit is a correction on a posted round
          // (delete it, post again), never a second round. The receipt opens.
          finishAccepted(landed, owner: uid, message: OrdinaryPost.earlierPostedCopy)
          recoveredRoundId = landed
          return
        case .storageFailed(let msg):
          toast.show(msg, kind: .failed); return
        case .notAvailable:
          toast.show(OrdinaryPost.notAvailableCopy, kind: .failed); return
        case .refused(let msg):
          // definite: nothing was written, the id stays, the card needs a change
          toast.show(msg, kind: .failed); return
        case .failed(let msg):
          toast.show(msg, kind: .failed); return
        }
      }
    } catch {
      let message = seededFrom != nil && PostService.fallbackFires(on: error)
        ? "Posting saved scorecards isn’t available yet. Your round is still kept here."
        : HumanError.text(error, prefix: "Couldn’t confirm the post. Your phone scorecard is kept for retry.")
      toast.show(message, kind: .failed); return
    }
    let roundId = outcome.roundId
    let postedFromPhone = seededFrom != nil

    // D-offline · the kept card LANDED. Release it now and only now — a card
    // released on the way into the composer would be gone if the post failed,
    // and one never released would sit there inviting a second post.
    if let lr = seededFrom {
      await LiveDisk.shared.removeUnsynced(lr)
      do { try OfflineRounds.shared.remove(owner: uid, id: lr) }
      catch { toast.show("Round posted. Couldn’t remove the phone copy — don’t post it again.", kind: .failed) }
      seededFrom = nil
    }

    if !postedFromPhone && !holesWritten { await svc.insertHoles(PostPayload.holeRows(card, roundId: roundId)) }
    svc.event(PostEvent.submit, [
      "mode": .string(card.mode.rawValue), "secs": .number(Date().timeIntervalSince(openedAt).rounded()),
      "holes": .number(Double(payload.holes_played)),
    ])
    var claim: PostPartnersShow?
    if let scan = card.scan {
      let acc = PostScan.accuracy(read: scan.read, scores: card.scores)
      svc.event(PostEvent.scanPost, ["fixed": .number(Double(acc.fixed)), "misses": .number(Double(acc.misses))])
      let rows = scan.others.filter(\.claimable)
      if !rows.isEmpty {
        claim = PostPartnersShow(rows: rows, ctx: PostService.ClaimContext(courseLabel: payload.course_label, rating: payload.rating, slope: payload.slope,
                                                                            playedOn: payload.played_on ?? CSDate.today(), holes: 18))
      }
    }
    await svc.remember(roundId: roundId, payload: payload, profileId: uid, marker: profile?.marker)

    acceptedRoundId = roundId
    recapPhoto = payload.photo_path == nil ? nil : photo
    let course = payload.course_label
    let firstEver = (profile?.rounds_count ?? 0) == 0
    // The SERVER says what the round counts for; the local rule is what answers
    // when the round went in through the declared fallback (D229).
    let counts = outcome.viaFallback
      ? PostSeasonRule.counts(playedOn: payload.played_on, season: m?.season, hasLeague: m != nil)
      : outcome.counts
    ceremony = PostCeremony(course: course ?? "A round", date: payload.played_on ?? CSDate.today(), gross: outcome.epilogue?.gross ?? payload.gross, vs: outcome.epilogue?.pvi,
                            points: counts ? outcome.epilogue?.points.flatMap { Int(exactly: $0) } : nil, squad: outcome.squad ?? m?.squad?.name, inLeague: counts,
                            name: profile?.display_name ?? "You", marker: profile?.marker ?? "saguaro",
                            leagueName: outcome.leagueName ?? m?.name,
                            /* D122 · why it did not score for the league, in words */
                            seasonNote: PostSeasonRule.note(playedOn: payload.played_on, season: m?.season, hasLeague: m != nil))
    CSHaptic.success()

    // clear the form so a posted round never reads as "didn't submit"
    clearAfterAccepted(owner: uid)

    // one sheet gets the moment: partner claims when the scan carried the group, else the epilogue
    pendingPartners = claim
    if claim == nil {
      let cap = m?.settings?.counting_cap
      // R11 returns the epilogue INSIDE its answer, so the page is on screen
      // without a second round trip; the fallback path fetches it as before.
      let epi = outcome.epilogue
      let act = PostNextAct.choose(epi, seasonId: outcome.seasonId ?? m?.season?.id,
                                   context: await nextActContext(cap: cap, roundsAfter: (profile?.rounds_count ?? 0) + 1))
      if epi != nil || firstEver {
        pendingEpilogue = PostEpilogueShow(epilogue: epi ?? PostEpilogue(gross: payload.gross, pvi: nil, points: nil, monthRank: nil),
                                           course: course, firstEver: firstEver, roundId: roundId, cap: cap,
                                           photoTravels: payload.photo_path != nil, ceremonyOwnsShare: true, act: act, playedOn: payload.played_on)
      }
    }
    Task { await store.reload() }   // the home feed, the standing, the count
  }

  /// The one place the form is put down after the server has accepted a round
  /// — the normal post and the accepted-recovery path both land here, so the
  /// two can never disagree about what "finished" means.
  private func clearAfterAccepted(owner uid: UUID) {
    setPhoto(nil)
    card.clearAfterPost()
    clearDraft()
    day = Date()
    // The reset stamps a date the same way `init` does, and across midnight it
    // is a DIFFERENT one — so the gate has to learn it, or a blank just-posted
    // card reads as a draft worth keeping.
    defaultDay = CSDate.iso(day, calendar: ScheduleDates.gregorian)
    ordinaryRequest = nil
    PostRequestStore.clear(owner: uid)
    openedAt = Date()
    playedWith = []
  }

  /// D350 (built) · the accepted-recovery finish. The disk says this request
  /// landed — the round is on the board, the form is finished exactly once,
  /// and the golfer is told where it is. Nothing is sent.
  private func finishAccepted(_ roundId: UUID, owner uid: UUID, message: String) {
    acceptedRoundId = roundId
    clearAfterAccepted(owner: uid)
    toast.show(message, kind: .confirmed)
    CSHaptic.success()
    Task { await store.reload() }
  }

  /// Everything the next act is allowed to know, and nothing else. A count that
  /// was not read is left absent so the rung that needs it does not fire.
  ///
  /// **F-3 tail · `buddiesPlayedThisWeek` was hard-coded `nil`,** so rung 6 —
  /// *"Two of yours played this week. Nobody is playing for anything." → Start
  /// something* — could never fire for anybody. It is the same idea as the
  /// Compete tab's own best line, already written, already tested, one wire
  /// short: *"already written, one wire short of working."*
  ///
  /// It is read here rather than guessed: `home_feed` over seven days, distinct
  /// golfers who are not me. A read that does not answer leaves the count
  /// ABSENT, and the rung stands down — which is the same rule as before, just
  /// no longer the only outcome (L-44).
  ///
  /// **B-1** · and `leagueless` is `nothingRunning`, not `memberships.isEmpty`:
  /// a golfer between seasons is in this state, and a membership pointing at a
  /// finished season is not a competition.
  private func nextActContext(cap: Int?, roundsAfter: Int) async -> PostNextAct.Context {
    let nothingRunning = Occasion.nothingRunning(store.me?.memberships ?? [])
    var buddies: Int? = nil
    if nothingRunning, let rows = try? await SupabaseService.shared.call(Rpc.home_feed(p_days: 7)) {
      buddies = Set(rows.filter { $0.is_me != true }.compactMap(\.profile_id)).count
    }
    return PostNextAct.Context(
      leagueless: nothingRunning,
      buddiesPlayedThisWeek: buddies,
      roundsCount: roundsAfter,
      countingCap: cap,
      monthName: PostNextAct.monthName(card.date ?? CSDate.today()))
  }

  /// The curtain has closed: hand the moment to whichever sheet is waiting.
  /// Returns false when nothing is — the caller lands back on the board.
  func afterCeremony() -> Bool {
    if let p = pendingPartners { pendingPartners = nil; partners = p; return true }
    if let e = pendingEpilogue { pendingEpilogue = nil; epilogue = e; return true }
    return false
  }
}

#if DEBUG
extension PostRoundModel {
  /// `-cs_dev_post_seed <total|strip|scan|photo>` — a filled card for a
  /// simulator without a finger (IOS-020's "look" step). DEBUG-only; never posts.
  ///   total · 41 out, 43 in on Papago Blue
  ///   strip · the scorecard strip open with a few holes off par
  ///   scan  · the strip as the scan's confirm surface: two unread cells, one partner row
  ///   photo · IOS-066 · the hero's plate FILLED, which is where a scan lands
  ///           and the one state `simctl` cannot reach — the PhotosPicker
  ///           needs a finger. The image is `ReceiptPhotoDev`'s drawn stand-in,
  ///           so the build carries one fabricated photograph and not two.
  func devSeed(_ kind: String) {
    card.course = "Papago Golf Course · Blue"; card.rating = "71.2"; card.slope = "128"
    switch kind {
    case "photo":
      card.f9 = "41"; card.b9 = "43"
      setPhoto(ReceiptPhotoDev.image)
    case "strip", "scan":
      card.mode = .holes
      card.plus(0); card.plus(3); card.minus(5); card.plus(10); card.plus(10); card.minus(12); card.minus(12); card.plus(16)
      if kind == "scan" {
        var read = card.scores; read[7] = 0; read[14] = 0
        card.scan = PostScanContext(read: read, others: [PostScanPlayer(name: "Ed", holes: Array(repeating: 4, count: 18), total: 72, holes_read: 18)])
      }
    default:
      card.f9 = "41"; card.b9 = "43"
    }
  }
  /// The strip's opening selection under the seed: hole 7, so the ring shows.
  static var devSelectedHole: Int { ProcessInfo.processInfo.arguments.contains("-cs_dev_post_seed") ? 6 : 0 }
}
#endif

/// What the epilogue sheet needs (`showEpilogue(epi, course, firstEver, roundId)`).
struct PostEpilogueShow: Identifiable {
  let epilogue: PostEpilogue
  let course: String?
  let firstEver: Bool
  let roundId: UUID
  let cap: Int?
  let photoTravels: Bool
  let ceremonyOwnsShare: Bool
  /// The one ranked next act (P-3). Defaulted so an older caller still compiles.
  var act: PostNextAct? = nil
  var playedOn: String? = nil
  var id: UUID { roundId }
}

/// What the partner-claims sheet needs (`scanPartnersSheet(ctx)`).
struct PostPartnersShow: Identifiable, Equatable {
  let rows: [PostScanPlayer]
  let ctx: PostService.ClaimContext
  var id: String { ctx.playedOn + (ctx.courseLabel ?? "") }
}
