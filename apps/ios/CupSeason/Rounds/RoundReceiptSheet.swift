// Cup Season — the round receipt (D95; index.html `openRoundReceipt`
// 11392–11418, `enrichRoundReceipt` 11363–11391).
//
// Opens INSTANTLY with what the caller held (or what the cache held under
// this id), then enriches from `round_card()`; a missing function keeps the
// instant view. The photo rides full-bleed above the facts with the poster's
// marker medallion; it is signed on demand and never load-bearing.
//
// WAVE 7 · **THE SCORE AS AN OBJECT, AND THE RECEIPT** (`leaderboard.md` §6).
// The sheet's head was a 21pt title and a tracked-caps sub-line; it is now the
// two rule-and-figures the whole system is derived from — the gross at
// `figure` 56 over a 2pt rule with `GROSS · 18 HOLES` beneath it, and the
// points at 40 over its own — and the facts print on a LEAF, because a receipt
// is a printed grid and that is what a leaf is for. `ReceiptRows` is untouched.
//
// D294 / IOS-067 · **THE CARD IS ON THE ROUND'S OWN PAGE.** The owner: *"Our
// scorecard looks good lets show it off."* The product drew a real card — the
// bone leaf with par and stroke index — in exactly one place, inside the course
// page, and a ROUND showed one number and a receipt of arithmetic. It now
// carries `RoundCardLeaf` between the figures and the receipt: the figures are
// what the round was WORTH, the card is what the round WAS, and the receipt is
// how the one became the other. `See the scorecard` stays where it was, because
// that sheet is a different object — the whole group's card, one row per
// player, for a live round.
//
// D293 / IOS-065 · **A PHOTOGRAPH GOES ON A ROUND YOU ALREADY POSTED, AND
// THIS IS WHERE.** `post_round`'s `p_photo_path` was the only path a
// photograph had ever taken to a round, so a golfer who did not have the
// picture when he typed the score — which is most golfers, because the score
// is typed in the car park — had no second chance, and one who attached the
// wrong picture had no way back either. The act lands in the photograph's own
// slot on the round's own receipt, which is where D284 put the delete and for
// the same reason: this is the object page for a round, and every surface
// that shows a round opens it.

import SwiftUI
import PhotosUI
import CSDesign
import CupSeasonKit

struct RoundReceiptSheet: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var typeSize
  let roundId: UUID
  let initialSeed: ReceiptSeed?
  /// "See the scorecard" — the hand-off to the live-round card (D92).
  var openScorecard: ((UUID) -> Void)? = nil

  @State private var seed: ReceiptSeed?
  @State private var enriched = false
  @State private var loadFailed = false
  /// **The round's own delete**, two steps, on the object it removes.
  @State private var armed = false
  @State private var deleting = false
  @State private var deleteFailed: String?
  /// D293 · the photograph's own controls. `photoNote` is the one line the
  /// golfer reads when a write does not land, and it sits under his thumb
  /// rather than in a toast that has already gone (L-32).
  @State private var pick: PhotosPickerItem?
  @State private var showLibrary = false
  @State private var showCamera = false
  /// D298 · the golfer picks the door. Was: the camera, always, on any phone.
  @State private var askSource = false
  @State private var photoBusy = false
  @State private var photoNote: String?
  /// D294 · the round's own card. Loaded after the enrich, because the seal on
  /// the fallback path needs the gross the enrich supplies. nil is a real
  /// answer and draws nothing (L-44).
  @State private var card: RoundScorecard?
  @State private var share: PostShareItem?
  @State private var roundPreview = false
  @State private var sharePhoto: UIImage?
  @State private var shareBusy = false
  #if DEBUG
  @State private var artifactPreview = false
  @State private var reviewPhoto: UIImage?
  #endif

  init(roundId: UUID, seed: ReceiptSeed?, openScorecard: ((UUID) -> Void)? = nil) {
    self.roundId = roundId; self.initialSeed = seed; self.openScorecard = openScorecard
    _seed = State(initialValue: seed)
  }

  private var capN: Int? {
    let m = store.me?.memberships.first { $0.league_id == store.preferredLeague } ?? store.me?.memberships.first
    return m?.settings?.counting_cap
  }

  var body: some View {
    let r = seed ?? ReceiptSeed(id: roundId)
    let rows = ReceiptRows.build(r, capN: capN, viewerId: store.session?.user.id)
    NavigationStack {
      ScrollView {
        ScrollViewReader { proxy in
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          head(r)
          photo(r)
          photoActions(r)
          if enriched, r.profileId == store.session?.user.id, recap(r) != nil {
            CSMini("Share round", glyph: .share, busy: shareBusy) {
              Task { await previewRound(r) }
            }
            .accessibilityIdentifier("round.share.preview")
          }
          scorecard(r)
            #if DEBUG
            // `-cs_dev_round_card` puts the card on screen without a finger.
            // At an accessibility size the head alone fills the viewport, so a
            // hatch that seeds a card and cannot show it photographs nothing.
            .onChange(of: card == nil) { _, gone in
              guard !gone, RoundCardDev.mode != nil else { return }
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                CSMotion.run(CSMotion.rise) { proxy.scrollTo(Self.cardAnchor, anchor: .top) }
              }
            }
            #endif
          if rows.isEmpty && !enriched {
            // "Pulling the card…" until D294; the word CARD now names a real
            // object twenty points up the page and cannot also mean this.
            Text("Loading round…").csType(.body).foregroundStyle(cs.mut)
              .accessibilityAddTraits(.updatesFrequently)
          }
          if loadFailed {
            Text("Couldn’t load this round.").csType(.body).foregroundStyle(cs.mut)
            CSDoor(.link("Try again") { Task { await open() } })
          }
          CSSectionHead("The receipt")
          ReceiptLeaf(caption: "What this round was worth",
                      dateline: r.playedOn.map { RivalryCopy.monthDay($0) },
                      rows: rows)
          foot(rows)
          remove(r)
        }
        .padding(.horizontal, CSTokens.Space.gutter)
        .padding(.top, CSTokens.Space.s3)
        .padding(.bottom, CSTokens.Space.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .background(cs.bg0)
      .navigationTitle("").navigationBarTitleDisplayMode(.inline)
      .csCloseButton { dismiss() }
    }
    .presentationBackground(cs.bg0)
    .task { await open() }
    // The composer's own door, so the two surfaces open the same camera roll —
    // and D298 is why "the same" is now worth saying: this read `the camera
    // when the app may open it, the library otherwise`, which on a phone means
    // the camera and nothing else.
    .csPhotoSource(pickerTitle, isPresented: $askSource, pick: choose)
    .photosPicker(isPresented: $showLibrary, selection: $pick, matching: .images)
    .onChange(of: pick) { _, item in
      guard let item else { return }
      pick = nil
      Task { await attach(await PostPhoto.load(item)) }
    }
    .fullScreenCover(isPresented: $showCamera) {
      PostCameraPicker { img in Task { await attach(img) } }.ignoresSafeArea()
    }
    .sheet(item: $share) { PostShareSheet(items: $0.items) }
    .sheet(isPresented: $roundPreview) {
      if let seed, let recap = recap(seed) { RoundSharePreview(recap: recap, photo: sharePhoto) }
    }
    #if DEBUG
    .fullScreenCover(isPresented: $artifactPreview) { artifactShot }
    #endif
  }

  /// §6.2–§6.5 · the dateline, `YOUR ROUND`, the two rule-and-figures on one
  /// baseline, and the sentence with its figure run.
  @ViewBuilder private func head(_ r: ReceiptSeed) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      Text(dateline(r)).csType(.agate, caps: true).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
      Text(mine(r) ? "Your round" : "The round").csType(.displayS, caps: true).foregroundStyle(cs.ink)
      // **Two rule-and-figures on ONE BASELINE** — which is the BOTTOM here,
      // not the first text baseline: each figure sits over its own rule with
      // its own label under it, so aligning the numerals would stagger the two
      // rules and the two labels. Aligning the bottoms lines up all three.
      // At the accessibility sizes the two figures STACK and drop their
      // columns: `POINTS` under a 76pt rule breaks as `POIN / TS`, which is a
      // label describing a column that no longer exists.
      A11yStack(rowAlignment: .bottom, spacing: CSTokens.Space.s5, columnSpacing: CSTokens.Space.s4) {
        if let g = r.gross {
          CSFigure("\(g)", size: .xl,
                   label: "gross · \(r.holesPlayed == 9 ? "9" : "18") holes")
            .frame(width: typeSize.isA11y ? nil : 132, alignment: .leading)
        }
        if let p = r.points {
          CSFigure(CSCopy.points(p), size: .l, label: "points")
            .frame(width: typeSize.isA11y ? nil : 76, alignment: .leading)
        }
        if !typeSize.isA11y { Spacer(minLength: 0) }
      }
      // §6.5 · **the fix for `CSFont.sentence`'s numeric sites**: the numeral
      // is set in the BOARD FACE at the sentence's own size, so a number in a
      // sentence is still in the number's voice. The producer marks the run;
      // there is no regex over prose.
      if let marked = sentence(r) {
        CSFigureRun(marked, role: .body).foregroundStyle(cs.ink)
      }
    }
  }

  @ViewBuilder private func photo(_ r: ReceiptSeed) -> some View {
    if let url = r.photoURL {
      // §10.1 rung 1 · a golfer's own round photo, and the poster's mark is the
      // credit. `CSPlate` carries the scrim, so the medallion never sits on a
      // bright sky at 1.4:1.
      CSPlate(.inset32) {
        AsyncImage(url: url) { phase in
          if case .success(let img) = phase { img.resizable().scaledToFill() } else { Color.clear }
        }
      }
      // D301's rule, applied where the photograph actually is. `CSPlate` fills
      // to a ratio and a `scaledToFill` image covers it, so this overhangs one
      // axis. Nothing is swallowed today — `photoActions` and the sheet's
      // Close are both drawn after it — and that is a fact about today's
      // layout, not about the view. Shaped here rather than inside `CSPlate`,
      // which also hosts the transparent `CSPlateWell` empty state and would
      // become a solid blocker if the rule were applied to the component.
      .contentShape(Rectangle())
      .overlay(alignment: .bottomTrailing) {
        if r.profileId != nil { MarkerStamp(marker: r.marker).padding(CSTokens.Space.s2) }
      }
      .accessibilityLabel("Round photo")
    }
  }

  /// D293 · **the photograph's own slot, and it is his round only.**
  /// `RoundPhotoSlot` is a pure function of two facts and is asserted in
  /// `RoundPhotoTests` rather than photographed. `CSMini` is the control the
  /// composer already uses for this exact act (§7.1's tertiary with the drawn
  /// glyph), so one act reads the same on both surfaces; the remove is
  /// `CSArmedButton`, two taps, because the object goes with the reference.
  @ViewBuilder private func photoActions(_ r: ReceiptSeed) -> some View {
    let slot = RoundPhotoSlot.for(isMine: mine(r), photoPath: r.photoPath)
    if slot != .none {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        FlowLayout(spacing: 8) {
          CSMini(slot == .offer ? RoundCopy.photoAdd : RoundCopy.photoReplace,
                 glyph: .photo, busy: photoBusy) { openPicker() }
          if slot == .present {
            CSArmedButton(label: RoundCopy.photoRemove,
                          armedLabel: RoundCopy.photoRemoveArmed,
                          busy: photoBusy) { Task { await removePhoto() } }
          }
        }
        if let photoNote {
          Text(photoNote).csType(.bodyS).foregroundStyle(cs.neg)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  /// D294 · **the card, and the act it earns.** The section is drawn only when
  /// there is a card to draw — a round posted as one number has none, and an
  /// empty grid with an invitation under it would be the product asking for
  /// something a posted round can no longer supply (§16: a round is not
  /// mutated, and holes are not a photograph).
  @ViewBuilder private func scorecard(_ r: ReceiptSeed) -> some View {
    if let card, !card.isEmpty {
      CSSectionHead(RoundCopy.cardHead).id(Self.cardAnchor)
      RoundCardLeaf(card: card, mine: mine(r))
      // His round only: the artifact carries HIS name and HIS marker, and
      // neither is in the payload for anybody else's round.
      if mine(r), let recap = recap(r) {
        CSMini(RoundCopy.cardShare, glyph: .share) {
          share = RoundCardArtifact.shareItem(recap, card: card, mine: true)
          CSHaptic.selection()
        }
      }
    }
  }

  /// The artifact's furniture, from the producer the recap card already uses —
  /// so the caption that lands in a group thread is one producer's words
  /// whichever artifact carried it (D2/D60a: no differential, no index, no
  /// league name).
  private func recap(_ r: ReceiptSeed) -> PostRecap? {
    guard let gross = r.gross else { return nil }
    return PostRecap(
      name: store.me?.profile?.display_name ?? "",
      marker: r.marker ?? store.me?.profile?.marker ?? "",
      gross: gross, pvi: r.indexProvisional == true ? nil : r.resolvedPvi, points: r.points.map { Int($0) },
      course: RoundCopy.course(r.courseLabel) , date: r.playedOn ?? "", badge: nil)
  }

  /// The card's own scroll anchor. Named once so the hatch and the view agree.
  private static let cardAnchor = "cs.receipt.card"

  /// The word over the menu is the act the golfer pressed, so the sheet that
  /// opens is plainly the one his finger asked for.
  private var pickerTitle: String {
    RoundPhotoSlot.for(isMine: true, photoPath: seed?.photoPath) == .present
      ? RoundCopy.photoReplace : RoundCopy.photoAdd
  }

  private func openPicker() {
    photoNote = nil
    if RoundPhotoSource.asks(cameraAvailable: PostPhoto.cameraAvailable) { askSource = true }
    else { showLibrary = true }
  }

  /// The menu's answer, in one place, so the two doors cannot drift apart.
  private func choose(_ source: RoundPhotoSource) {
    switch source {
    case .library: showLibrary = true
    case .camera: showCamera = true
    }
  }

  /// Upload, attach, then draw it. The composer's own compression (1600px,
  /// 0.82) so a round photographed on Tuesday is the same weight as one
  /// photographed at post time.
  private func attach(_ image: UIImage?) async {
    guard !photoBusy, let uid = store.session?.user.id else { return }
    guard let image, let jpeg = PostPhoto.compress(image, maxDim: 1600, quality: 0.82) else {
      photoNote = "Couldn’t read that image"; return
    }
    photoBusy = true; photoNote = nil
    defer { photoBusy = false }
    // D303 · the path this round carried before the write. The server may not
    // reclaim it, so the client hands it over and the service takes it out.
    let was = seed?.photoPath
    do {
      let path = try await RoundPhotoService().attach(roundId, jpeg: jpeg, uid: uid, replacing: was)
      var next = seed ?? ReceiptSeed(id: roundId)
      next.photoPath = path
      next.photoURL = await RoundsRepository().signedURL(path)
      seed = next
      await ReceiptCache.shared.put([next])
      CSHaptic.success()
    } catch {
      photoNote = (error as? RoundPhotoFailure) == .needsPush
        ? RoundCopy.photoNeedsPush : RoundCopy.photoFailed
    }
  }

  private func removePhoto() async {
    guard !photoBusy else { return }
    photoBusy = true; photoNote = nil
    defer { photoBusy = false }
    let was = seed?.photoPath
    do {
      try await RoundPhotoService().remove(roundId, object: was)
      var next = seed ?? ReceiptSeed(id: roundId)
      next.photoPath = nil
      next.photoURL = nil
      seed = next
      await ReceiptCache.shared.put([next])
      CSHaptic.success()
    } catch {
      photoNote = (error as? RoundPhotoFailure) == .needsPush
        ? RoundCopy.photoNeedsPush : RoundCopy.photoRemoveFailed
    }
  }

  /// §6.8 · the two rows the leaf does not hold: a door and a credit line.
  @ViewBuilder private func foot(_ rows: [ReceiptRow]) -> some View {
    let mates: [String] = rows.compactMap { if case .playedWith(let m) = $0 { return m.joined(separator: ", ") } else { return nil } }
    let live: UUID? = rows.compactMap { if case .scorecard(let id) = $0 { return id } else { return nil } }.first
    if live != nil || !mates.isEmpty {
      HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
        if let live, let openScorecard {
          CSDoor(.link("See the scorecard") { openScorecard(live) })
        }
        Spacer(minLength: CSTokens.Space.s2)
        if let m = mates.first {
          Text("Played with \(m)").csType(.agateS, caps: true).foregroundStyle(cs.mut)
            .multilineTextAlignment(.trailing)
        }
      }
    }
  }

  /// **DELETION BELONGS ON THE ROUND'S OWN RECEIPT** — `YouScreen` says so in
  /// as many words, having removed the per-row `×` from `RecentRoundsList` in
  /// Wave 3. The receipt never got one, so for four waves the phone had **no
  /// way at all** to remove a round a golfer had posted wrong, while the desk
  /// kept its owner-only `×` and its `delete_round` call — two clients
  /// differing on a capability, which D234 / R-C forbids.
  ///
  /// Two steps, because it is not reversible and because it leaves the card
  /// AND every league standing the round counted toward: a tertiary that arms,
  /// then the destructive with the consequence spelled out beside it. The
  /// owner's round only — the same gate the desk applies.
  @ViewBuilder private func remove(_ r: ReceiptSeed) -> some View {
    if mine(r) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
        CSRule()
        if armed {
          Text(RoundCopy.deleteConsequence).csType(.bodyS).foregroundStyle(cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          HStack(spacing: CSTokens.Space.s3) {
            Button("Delete this round") { Task { await remove() } }
              .buttonStyle(.csDestructive(busy: deleting))
            CSDoor(.link("Keep it") { armed = false })
          }
        } else {
          CSDoor(.link("Delete this round") { armed = true; CSHaptic.selection() })
        }
        if let deleteFailed {
          Text(deleteFailed).csType(.bodyS).foregroundStyle(cs.neg)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .padding(.top, CSTokens.Space.s4)
    }
  }

  private func remove() async {
    guard !deleting else { return }
    deleting = true; deleteFailed = nil
    do {
      try await YouRepository().deleteRound(roundId)
      CSHaptic.success()
      dismiss()
    } catch {
      // L-32 · a failed write says so where the finger is, and never with a code
      deleteFailed = RoundCopy.deleteFailed
      deleting = false
    }
  }

  /// `PAPAGO · BLUE · SUN SEP 6`. `ReceiptSeed.subtitle` joins the ISO date
  /// raw — it was written for a sheet title, and `2026-09-04` in tracked caps
  /// over a receipt is a database row rather than a dateline.
  private func dateline(_ r: ReceiptSeed) -> String {
    [r.courseLabel, "\(r.holesPlayed ?? 18) holes", r.playedOn.map { RivalryCopy.monthDay($0) }]
      .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
  }

  private func mine(_ r: ReceiptSeed) -> Bool {
    r.isMine ?? (r.profileId == nil || r.profileId == store.session?.user.id)
  }

  /// The one sentence, with the figure marked by the producer of the fact
  /// rather than found in the prose. Absent when the round has no verdict —
  /// a receipt with nothing to say says nothing.
  /// **The words are `CSBands`', not this view's.** The first build wrote its
  /// own — and got the sign backwards, because in this product a POSITIVE
  /// figure means you beat your playing HCP by that much. It printed "You beat
  /// your playing HCP by 2.0" over a receipt row reading `−2.0 · A LITTLE
  /// LOOSE`. One producer, one direction, three renderers.
  private func sentence(_ r: ReceiptSeed) -> String? {
    guard r.indexProvisional != true, let pvi = r.resolvedPvi else { return nil }
    let named = r.band ?? CSBands.bandName(pvi)
    let band = mine(r) ? named : CSBands.theirs(named)
    var phrase = CSBands.vsPhraseMarked(pvi)
    guard !phrase.isEmpty else { return nil }
    if !mine(r) { phrase = CSBands.theirs(phrase) }
    // The phrase is its own sentence — `Beat your playing HCP by 7.6` — and a
    // pronoun in front of it makes half the cases verbless ("You 2.0 over your
    // playing HCP"). It opens the same way the composer's does, and the two
    // read as one voice because they are one producer.
    return phrase.prefix(1).uppercased() + phrase.dropFirst() + " — " + band.lowercased() + "."
  }

  private func previewRound(_ r: ReceiptSeed) async {
    guard !shareBusy else { return }
    shareBusy = true
    defer { shareBusy = false }
    sharePhoto = nil
    // Only the photograph attached to this accepted, owned round; no course fallback.
    if let url = r.photoURL, let (data, response) = try? await URLSession.shared.data(from: url),
       (response as? HTTPURLResponse)?.statusCode == 200 {
      sharePhoto = UIImage(data: data)
    }
    roundPreview = true
  }

  private func open() async {
    loadFailed = false
    if seed == nil, let cached = await ReceiptCache.shared.get(roundId) { seed = cached }
    let repo = RoundsRepository()
    // the second pass: one read, then redraw in place
    async let payload = repo.roundCard(roundId)
    if seed?.photoURL == nil, let path = seed?.photoPath, let url = await repo.signedURL(path) {
      seed?.photoURL = url
    }
    if let json = try? await payload {
      var merged = (seed ?? ReceiptSeed(id: roundId)).merged(with: json)
      if merged.photoURL == nil, let path = merged.photoPath, let url = await repo.signedURL(path) { merged.photoURL = url }
      seed = merged
    } else {
      loadFailed = seed?.gross == nil
    }
    enriched = true
    if seed?.gross != nil { CSTelemetry.event("receipt_viewed") }
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("-cs_dev_share_preview"), let r = seed,
       r.profileId == store.session?.user.id { await previewRound(r) }
    #endif
    #if DEBUG
    if (ProcessInfo.processInfo.arguments.contains("-cs_dev_brand_export") || ProcessInfo.processInfo.arguments.contains("-cs_dev_brand_finish")),
       let r = seed, mine(r), let recap = recap(r) {
      var image: UIImage?
      if let url = r.photoURL, let (data, _) = try? await URLSession.shared.data(from: url) {
        image = UIImage(data: data)
      }
      reviewPhoto = image
      if ProcessInfo.processInfo.arguments.contains("-cs_dev_brand_finish") { artifactPreview = true }
      if let png = RecapCardView.render(recap, photo: image)?.pngData() {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? png.write(to: folder.appendingPathComponent("brand-round-review.png"))
      }
    }
    #endif
    #if DEBUG
    applyPhotoHatch()
    // `-cs_dev_photo_menu` — the source menu, OPEN, on its own guard rather
    // than inside `applyPhotoHatch`'s: the one thing D298 changed IS a menu,
    // and this machine has no finger to open it with. It draws and picks
    // nothing. (`RoundPhotoSource.offered` is false-by-simulator, so the menu
    // is forced open here; what it CONTAINS is the hatch's other half.)
    if ReceiptPhotoDev.menu { askSource = true }
    if ReceiptPhotoDev.probe { await runPhotoProbe() }
    if let hatched = RoundCardDev.card {
      card = hatched
      if RoundCardDev.artifact { artifactPreview = true }
      return
    }
    #endif
    // The card is the round showing off, never a fact the receipt depends on:
    // it arrives after everything else and its absence is silent.
    card = await RoundScorecardService().load(roundId, gross: seed?.gross, holesPlayed: seed?.holesPlayed)
  }

  #if DEBUG
  /// `-cs_dev_card_artifact` — the share PNG, on screen, because `simctl`
  /// cannot open a share sheet and an artifact has to be looked at.
  @ViewBuilder private var artifactShot: some View {
    let r = seed ?? ReceiptSeed(id: roundId)
    if ProcessInfo.processInfo.arguments.contains("-cs_dev_brand_finish"), let rc = recap(r) {
      FinishCeremonyView(ceremony: PostCeremony(course: rc.course, date: rc.date,
        gross: rc.gross, vs: rc.pvi, points: rc.points, squad: nil,
        inLeague: rc.points != nil, name: rc.name, marker: rc.marker, leagueName: nil),
        photo: reviewPhoto, onBack: { artifactPreview = false }, roundId: roundId)
        .csDevTextSize(CSDevHatch.textSize)
    } else if let card, let rc = recap(r), let img = RoundCardArtifact.render(rc, card: card, mine: true) {
      Image(uiImage: img).resizable().scaledToFit()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cs.bg0)
        .onTapGesture { artifactPreview = false }
    } else {
      Color.clear.onTapGesture { artifactPreview = false }
    }
  }

  /// `-cs_dev_photo_probe` — the two halves of the attach, run for real, raw.
  private func runPhotoProbe() async {
    guard let uid = store.session?.user.id else { photoNote = "PROBE · not signed in"; return }
    guard let jpeg = PostPhoto.compress(ReceiptPhotoDev.image, maxDim: 1600, quality: 0.82) else {
      photoNote = "PROBE · compress returned nil"; return
    }
    photoNote = await RoundPhotoService().probe(roundId, uid: uid, jpeg: jpeg, priorPath: seed?.photoPath)
  }

  /// `-cs_dev_receipt_photo <none|on|skew>` — see `ReceiptPhotoDev`. It moves
  /// the photograph's two facts and the one note line, and nothing else on the
  /// receipt; the round, the figures and the leaf are the account's own.
  private func applyPhotoHatch() {
    guard let m = ReceiptPhotoDev.mode else { return }
    var s = seed ?? ReceiptSeed(id: roundId)
    switch m {
    case "none":
      s.photoPath = nil; s.photoURL = nil; photoNote = nil
    case "on":
      s.photoPath = ReceiptPhotoDev.path; s.photoURL = ReceiptPhotoDev.photo; photoNote = nil
    case "skew":
      s.photoPath = nil; s.photoURL = nil; photoNote = RoundCopy.photoNeedsPush
    default:
      return
    }
    seed = s
  }
  #endif
}

#Preview("An 86 on a 64.9 / 111 · Standard, 95%") {
  RoundReceiptSheet(roundId: UUID(), seed: ReceiptSeed(
    id: UUID(), gross: 86, differential: 21.5, indexAtPost: 10.0, playedOn: "2026-07-25",
    courseLabel: "Arizona Biltmore Links · Copper", holesPlayed: 18, rating: 64.9, slope: 111, pvi: -12.0, playingIndex: 9.5,
    points: 5, monthRank: 3, countingCap: 4))
  .environment(SessionStore())
  .csTheme()
}

#Preview("First round — no number yet") {
  RoundReceiptSheet(roundId: UUID(), seed: ReceiptSeed(
    id: UUID(), gross: 94, differential: 27.8, indexAtPost: 27.8, playedOn: "2026-09-03",
    courseLabel: "Papago GC", holesPlayed: 18, rating: 70.2, slope: 125, pvi: 0, points: 7, monthRank: 1, countingCap: 3,
    indexProvisional: true, provisionalRound: 1))
  .environment(SessionStore())
  .csTheme()
}
