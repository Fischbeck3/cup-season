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

  private let store: SessionStore
  private let toast: CSToastCenter
  private let svc = PostService()
  private let sched = ScheduleService()
  private var draftTask: Task<Void, Never>?
  private var openedAt = Date()
  private var typedSomething = false

  init(store: SessionStore, toast: CSToastCenter) {
    self.store = store; self.toast = toast
    card.date = CSDate.iso(day, calendar: ScheduleDates.gregorian)
  }

  // MARK: - who and where

  var uid: UUID? { store.session?.user.id }
  var profile: Me.Profile? { store.me?.profile }
  /// The open league (`CS.league` / `CS.season`): Home's preferred membership.
  var membership: Me.Membership? {
    store.me?.memberships.first { $0.league_id == store.preferredLeague } ?? store.me?.memberships.first
  }
  var myIndex: Double? { profile?.index_current }
  /// "Post a round · your index 12.4" — the REAL number (landmine 7.12).
  var eyebrow: String { "Post a round · your index " + CSCopy.index(myIndex) }

  // MARK: - open (`switchView('post')`, 4159)

  func open() async {
    openedAt = Date()
    svc.event(PostEvent.open)
    restoreDraft()
    if let uid { memory = await svc.courseMemory(uid) }
    scanEnabled = await svc.scanEnabled()
  }

  // MARK: - the preview

  private func recalc() {
    preview = PostCalc.preview(card, myIndex: myIndex)
    if !card.isBlank { typedSomething = true }
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
    toast.show("Tees set — rating and slope filled")
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

  func startOver() { card.startOver(); setPhoto(nil); clearDraft(); toast.show("Card cleared") }
  func scrapScan() { card.scrapScan(); toast.show("Scan scrapped — type your nines in") }

  // MARK: - photo (6521–6578)

  func setPhoto(_ image: UIImage?) {
    photo = image
    photoJPEG = image.flatMap { PostPhoto.compress($0, maxDim: 1600, quality: 0.82) }
  }

  func photoPicked(_ image: UIImage?) {
    guard let image else { toast.show("Couldn’t read that image"); return }
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

  // MARK: - drafts (6217–6270)

  private func scheduleDraft() {
    draftTask?.cancel()
    let snapshot = card
    draftTask = Task {
      try? await Task.sleep(for: .milliseconds(350))
      guard !Task.isCancelled else { return }
      if snapshot.isBlank { UserDefaults.standard.removeObject(forKey: PostDraft.key); return }
      if let data = PostDraft.encode(PostDraft(card: snapshot)) { UserDefaults.standard.set(data, forKey: PostDraft.key) }
    }
  }
  private func clearDraft() { draftTask?.cancel(); UserDefaults.standard.removeObject(forKey: PostDraft.key) }

  private func restoreDraft() {
    guard !draftRestored else { return }
    draftRestored = true
    guard let d = PostDraft.decode(UserDefaults.standard.data(forKey: PostDraft.key)) else {
      UserDefaults.standard.removeObject(forKey: PostDraft.key); return
    }
    guard card.isBlank else { return }
    card = d.card
    if let iso = d.card.date, let date = CSDate.local(iso, calendar: ScheduleDates.gregorian) { day = date }
    toast.show(PostDraft.restoredToast)
  }

  // MARK: - Post (the `#postBtn` handler)

  func tapPost() {
    guard preview != nil else { toast.show("Enter at least one nine first"); return }
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
    guard !busy, let preview, let uid else { return }
    busy = true; defer { busy = false }
    let m = membership
    var payload = PostPayload.build(card, seasonId: m?.season?.id)
    if let jpeg = photoJPEG {
      if let path = await svc.uploadPhoto(jpeg, uid: uid) { payload.photo_path = path }
      else { toast.show("Photo didn’t stick — posting the round without it") }
    }
    let roundId: UUID
    do { roundId = try await svc.insertRound(payload) }
    catch { toast.show(HumanError.text(error, prefix: "Post failed.")); return }

    await svc.insertHoles(PostPayload.holeRows(card, roundId: roundId))
    svc.event(PostEvent.submit, [
      "mode": .string(card.mode.rawValue), "secs": .number(Date().timeIntervalSince(openedAt).rounded()),
      "gross": .number(Double(payload.gross)), "holes": .number(Double(payload.holes_played)),
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

    recapPhoto = photo
    let course = payload.course_label
    let firstEver = (profile?.rounds_count ?? 0) == 0
    let counts = PostSeasonRule.counts(playedOn: payload.played_on, season: m?.season, hasLeague: m != nil)
    ceremony = PostCeremony(course: course ?? "A round", date: payload.played_on ?? CSDate.today(), gross: payload.gross, vs: preview.vs,
                            points: counts ? preview.points : nil, squad: m?.squad?.name, inLeague: counts,
                            name: profile?.display_name ?? "You", marker: profile?.marker ?? "saguaro", leagueName: m?.name)
    CSHaptic.success()

    // clear the form so a posted round never reads as "didn't submit"
    setPhoto(nil)
    card.clearAfterPost()
    clearDraft()
    day = Date()
    openedAt = Date()

    // one sheet gets the moment: partner claims when the scan carried the group, else the epilogue
    pendingPartners = claim
    if claim == nil {
      let cap = m?.settings?.counting_cap
      if let epi = await svc.epilogue(roundId), !epi.rows(cap: cap, firstEver: firstEver).isEmpty || firstEver {
        pendingEpilogue = PostEpilogueShow(epilogue: epi, course: course, firstEver: firstEver, roundId: roundId, cap: cap,
                                           photoTravels: payload.photo_path != nil, ceremonyOwnsShare: true)
      } else if firstEver {
        pendingEpilogue = PostEpilogueShow(epilogue: PostEpilogue(gross: payload.gross, pvi: nil, points: nil, monthRank: nil), course: course,
                                           firstEver: true, roundId: roundId, cap: cap, photoTravels: payload.photo_path != nil, ceremonyOwnsShare: true)
      }
    }
    Task { await store.reload() }   // the home feed, the standing, the count
  }

  /// The curtain has closed: hand the moment to whichever sheet is waiting.
  /// Returns false when nothing is — the caller lands back on the board.
  func afterCeremony() -> Bool {
    if let p = pendingPartners { pendingPartners = nil; partners = p; return true }
    if let e = pendingEpilogue { pendingEpilogue = nil; epilogue = e; return true }
    return false
  }
}

/// What the epilogue sheet needs (`showEpilogue(epi, course, firstEver, roundId)`).
struct PostEpilogueShow: Identifiable {
  let epilogue: PostEpilogue
  let course: String?
  let firstEver: Bool
  let roundId: UUID
  let cap: Int?
  let photoTravels: Bool
  let ceremonyOwnsShare: Bool
  var id: UUID { roundId }
}

/// What the partner-claims sheet needs (`scanPartnersSheet(ctx)`).
struct PostPartnersShow: Identifiable, Equatable {
  let rows: [PostScanPlayer]
  let ctx: PostService.ClaimContext
  var id: String { ctx.playedOn + (ctx.courseLabel ?? "") }
}
