// Cup Season — Post a round as a scorecard, not a form (IOS-020; index.html
// `#view-post` 3097–3200, the logic 6119–6520). Every mechanic and every line
// of the web's copy is kept; the SHAPE is the phone's: the live gross is the
// hero, "where" is rows, the card is two big figures or the scorecard strip,
// details are pills, Post is pinned in the bottom bar, the bands fold away.
// "How this round scores" previews at the league's allowance (D178); the
// server still scores the round on the books.
// IOS-022: the rating/slope row opens only on "edit" and a picked tee fills
// it (item 4); the scoring fine print says itself once, in the hero (item 5).

import SwiftUI
import PhotosUI
import CSDesign
import CupSeasonKit

struct PostRoundScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  @Environment(\.dismiss) private var dismiss
  let links: PostLinks
  /// Where the flow lands when the ceremony and its sheets are done; nil = pop.
  var onDone: (() -> Void)? = nil

  @State private var model: PostRoundModel?
  @State private var pick: PhotosPickerItem?
  @State private var pickPurpose: PostPickPurpose = .photo
  @State private var showLibrary = false
  @State private var showCamera = false

  var body: some View {
    Group {
      if let model { PostRoundBody(model: model, links: links, pickPhoto: { present(.photo) }, pickScan: { present(.scan) }, onDone: finish) }
      else { Color.clear }
    }
    .background(cs.bg0)
    .task {
      if model == nil {
        let m = PostRoundModel(store: store, toast: toast)
        model = m
        await m.open()
        // D-offline · a card the server could not take, handed back. Seeded
        // AFTER `open()` so it wins over a restored draft — the golfer chose
        // this round explicitly, and a half-typed draft must not overwrite it.
        if let lr = LiveRoundStore.shared.pendingPost {
          LiveRoundStore.shared.pendingPost = nil
          if let st = await LiveDisk.shared.snapshotUnsynced(lr), let k = KeptCards.card(from: st) {
            m.seed(KeptCards.compose(k), from: lr)
          }
        }
        #if DEBUG
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-cs_dev_post_seed"), i + 1 < a.count { m.devSeed(a[i + 1]) }
        #endif
      }
    }
    .photosPicker(isPresented: $showLibrary, selection: $pick, matching: .images)
    .onChange(of: pick) { _, item in
      guard let item else { return }
      pick = nil
      Task { await picked(await PostPhoto.load(item)) }
    }
    .fullScreenCover(isPresented: $showCamera) {
      PostCameraPicker { img in Task { await picked(img) } }.ignoresSafeArea()
    }
  }

  private func present(_ p: PostPickPurpose) {
    pickPurpose = p
    if PostPhoto.cameraAvailable { showCamera = true } else { showLibrary = true }
  }

  private func picked(_ image: UIImage?) async {
    guard let model else { return }
    switch pickPurpose {
    case .photo: model.photoPicked(image)
    case .scan: await model.scanPicked(image)
    }
  }

  private func finish() { if let onDone { onDone() } else { dismiss() } }
}

enum PostPickPurpose { case photo, scan }

private struct PostRoundBody: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @Bindable var model: PostRoundModel
  let links: PostLinks
  let pickPhoto: () -> Void
  let pickScan: () -> Void
  let onDone: () -> Void
  @State private var ratingOpen = false
  @State private var showDate = false
  @State private var bandsOpen = false
  /// IOS-030 · the composer opens on the ONE box, so a long-press on the ⊕
  /// lands with the keyboard up and the score is two digits away.
  @FocusState private var grossFocused: Bool
  /// The nines, the 18/9 seg, the strip and the course search live behind this
  /// — complete and unchanged (P-6). Open by default only when there is no
  /// course to inherit, which is the first-ever round.
  @State private var cardOpen: Bool?

  /// **THE REVIEW'S MEASUREMENT.** IOS-064 moved `Start over` out of the
  /// pinned foot at an accessibility size, because the foot was taking
  /// "roughly a third of the viewport". On an SE at the DEFAULT reading size
  /// with the number pad up it takes 134pt of a 435pt viewport — 31 %, the
  /// same third, on the phone most likely to be held by somebody standing on
  /// a tee box. The argument was never about the type size; it was about how
  /// much room the window has, and an accessibility size is one of the two
  /// ways a window runs out of it.
  ///
  /// Read ONCE on appear, the way the door reads it: a window does not resize
  /// when a keyboard rises, so the foot cannot grow or shrink under a thumb
  /// while a golfer is typing into it. It starts at the floor — "not short" —
  /// so the tall phone's first frame is the one it already had.
  @State private var windowHeight: CGFloat = DoorLayout.ceremonyFloor

  /// **`DoorLayout.working` IS CALLED, NOT RESTATED.** The predicate is one
  /// pure function of two numbers with `DoorLayoutTests` behind it (667 is
  /// short, 844/852/956 are not; an accessibility size is short on every
  /// device), and a second surface that re-typed `isAccessibilitySize ||
  /// height < 700` would be a copy free to drift. What the predicate is about
  /// is the WINDOW rather than the door — the type it lives on is now one
  /// caller behind its own name, and a third caller should move it out.
  private var tightFoot: Bool {
    DoorLayout.working(windowHeight: windowHeight, typeSize: typeSize)
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          PostHeroCard(model: model, focus: $grossFocused, pickPhoto: pickPhoto, pickScan: pickScan)
          inheritedLine
          whoSection
          cardFold.id("card")
          bandsSection.id("bands")
          // IOS-064 · when the window is short of room — an accessibility size,
          // or a 667pt phone — the abandonment link rides HERE rather than in
          // the pinned foot. See `bottomBar`.
          if tightFoot { startOver.padding(.top, CSTokens.Space.s4) }
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
        .csPage("composer")
      }
      .onAppear { windowHeight = DoorLayout.windowHeight }
      #if DEBUG
      // `-cs_dev_post_scroll <card|bands>`: a simulator without a finger reaches the fold
      .task {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-cs_dev_post_scroll"), i + 1 < a.count else { return }
        try? await Task.sleep(for: .seconds(1))
        if a[i + 1] == "bands" { bandsOpen = true }
        // IOS-066 · `card` OPENS the fold as well as scrolling to it. A seed
        // carries a course, so the fold it lives in is folded, and the hatch
        // was scrolling to an id that was not in the tree.
        if a[i + 1] == "card" { cardOpen = true }
        grossFocused = false   // the keypad's inset is what stops the scroll short
        proxy.scrollTo(a[i + 1], anchor: .top)
      }
      #endif
    }
    .scrollDismissesKeyboard(.interactively)
    .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    .navigationTitle("Add my round")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        // "Play now" — the tee sheet stays one tap away from the composer (IOS-004 §2)
        //
        // F-11 · QUIET. The composer's ranked action is `Add my round`, an
        // ember fill at the foot; this is a LANE CHANGE. Two ember calls-to-act
        // in one viewport compete, and the rule is written in this build's own
        // code (`MeStrip`'s foot doors: "ember is the metal of act now, and
        // spending it four times in one row spends it on nothing"). The dot
        // goes with the metal — an ember dot is the live signal, and nothing
        // is live here yet.
        Button("Play now") { onDone(); links.openLive() }
          .buttonStyle(.csTertiary(.toolbar))
          .accessibilityHint("Opens live scoring for a round")
      }
    }
    .sheet(isPresented: $showDate) { PostDateSheet(day: $model.day) }
    .sheet(isPresented: $model.showPars) { PostParsSheet(model: model) }
    .sheet(isPresented: $model.showEvenPar) { PostEvenParSheet(model: model) }
    .sheet(item: $model.scanToPick) { scan in PostScanPickSheet(scan: scan) { model.apply(scan, row: $0) } }
    // the curtain closes fully before the next sheet rises — a sheet presented mid-dismissal is dropped
    .fullScreenCover(item: $model.ceremony, onDismiss: { if !model.afterCeremony() { onDone() } }) { c in
      FinishCeremonyView(ceremony: c, photo: model.recapPhoto) { model.ceremony = nil }
    }
    .sheet(item: $model.epilogue, onDismiss: onDone) { show in
      EpilogueSheet(show: show, photo: model.recapPhoto,
                    links: EpilogueLinks(openTable: { onDone(); links.openCompetition($0) },
                                         openPerson: { onDone(); links.openTourCard($0) },
                                         openPeople: { onDone(); links.openPeople() },
                                         startSomething: { onDone(); links.openPeople() }),
                    onDone: { model.epilogue = nil })
    }
    .task {
      // the composer opens ON the number — two digits and a tap (IOS-030)
      try? await Task.sleep(for: .milliseconds(350))
      if model.card.entry == nil { grossFocused = true }
    }
    .sheet(item: $model.partners, onDismiss: onDone) { PostPartnersSheet(show: $0) }
  }

  // MARK: - The inherited line (IOS-030 · course · rating/slope · date, one row)

  /// Everything the composer knows without asking: the course it inherited, the
  /// rating and slope that came with it, and the day. One editable line rather
  /// than five fields — and it says what is MISSING rather than showing a
  /// placeholder that reads like a value (PA-025: `72.1` and `128` were
  /// placeholders and every tester read them as the course's numbers).
  private var inheritedLine: some View {
    Button { CSMotion.run { cardOpen = !cardIsOpen } } label: {
      CSRow(last: true) {
        A11yStack(rowAlignment: .firstTextBaseline, spacing: 8, columnSpacing: 2) {
          Text(inheritedText).csType(.columnM).foregroundStyle(model.card.course.isEmpty ? cs.mut : cs.ink)
            .multilineTextAlignment(.leading)
          Spacer(minLength: 8)
          Text(cardIsOpen ? "Done" : "Edit").csType(.agateS, caps: true).foregroundStyle(cs.ink)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .padding(.top, 12)
    .accessibilityLabel("Course and tees: \(inheritedText)")
    // IOS-066 · the day moved INTO the fold this line summarises, so the hint
    // names it. It was a chip under a `Details` head that held nothing else.
    .accessibilityHint(cardIsOpen ? "Closes the card" : "Opens the course, the tees, the day and your nines")
  }

  /// "PAPAGO · BLUE · 71.2 / 128 · TODAY". A missing piece is an em dash, never
  /// a number nobody typed.
  private var inheritedText: String {
    let course = model.card.course.trimmingCharacters(in: .whitespaces)
    let rating = model.card.rating.isEmpty ? "—" : model.card.rating
    let slope = model.card.slope.isEmpty ? "—" : model.card.slope
    return [course.isEmpty ? "Add the course" : course, "\(rating) / \(slope)", CSHeaderDate.today(model.day)]
      .joined(separator: " · ")
  }

  /// Open when the golfer opened it, or when there is nothing to inherit.
  private var cardIsOpen: Bool { cardOpen ?? (model.card.course.isEmpty || model.card.rating.isEmpty) }

  // MARK: - Who was out there (D239 · optional, bounded, never a vouch)

  @ViewBuilder private var whoSection: some View {
    if !model.partnerChoices.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Text("Who was out there?").csEyebrow().padding(.top, 14)
        FlowLayout(spacing: 8) {
          ForEach(model.partnerChoices) { p in
            let on = model.playedWith.contains(p.id)
            // §7.2 · one chip, one selected language, and a 44pt target. These
            // were 36pt capsules tinted with ember at `a16` — a selection is
            // not a live action, and the sibling sheet's chips were already 44.
            Button { model.toggle(partner: p.id) } label: {
              CSChip(p.name, selected: on)
                .frame(minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(p.name)
            .accessibilityValue(on ? "tagged" : "not tagged")
            .accessibilityHint("Says they were out there.")
          }
        }
        CSFine("Optional. " + HeadToHeadCopy.notAVouch)
      }
    }
  }

  // MARK: - The card, behind the fold (P-6 · nothing is deleted)

  @ViewBuilder private var cardFold: some View {
    if cardIsOpen {
      VStack(alignment: .leading, spacing: 0) {
        whereSection
        cardSection
      }
      .transition(.opacity)
    }
  }

  // MARK: - Where (`#inCourse`, the chips, `#inRating` / `#inSlope`)

  private var whereSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSSectionHead("Course & tees").padding(.top, 8)
      PostCourseSearchField(text: $model.card.course, courseId: $model.card.courseId) { c, t in
        model.teePicked(course: c, tee: t)
        CSMotion.run { ratingOpen = false }   // the tee filled the line; the fields fold
      }
        .padding(.top, 12).padding(.bottom, 2)
      // course memory — ONLY while the search field is empty, so recents never read as stuck search results (they used to sit
      // under the field unconditionally and, with a failed search above them, looked exactly like a broken dropdown)
      if model.card.course.isEmpty && !model.memory.isEmpty {
        Text("Recent courses").csEyebrow().padding(.top, 6)
      }
      ForEach(model.card.course.isEmpty ? model.memory : []) { m in
        Button { model.fill(m); CSMotion.run { ratingOpen = false } } label: {
          CSRow {
            A11yStack(rowAlignment: .firstTextBaseline, spacing: 10, columnSpacing: 2) {
              Text(m.label).csType(.name).foregroundStyle(cs.ink).multilineTextAlignment(.leading)
              Spacer(minLength: 8)
              Text("\(m.ratingText) / \(m.slope)").csType(.columnM).foregroundStyle(cs.mut)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(m.label), rating \(m.ratingText), slope \(m.slope)")
        .accessibilityHint("Fills the course, rating and slope")
      }
      // rating/slope: one mono line that opens into the two fields on "edit" — always editable (D72);
      // an empty card shows "— / —" and stays folded (IOS-022 item 4)
      Button { CSMotion.run { ratingOpen.toggle() } } label: {
        // IOS-066 · always draws its hairline now: `Day played` follows it, so
        // it stopped being the section's last row.
        CSRow {
          A11yStack(rowAlignment: .firstTextBaseline, spacing: 8, columnSpacing: 2) {
            Text("Rating / slope").csType(.name).foregroundStyle(cs.mut)
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text(ratingLine).csType(.columnM).foregroundStyle(cs.ink)
              Text("·").csType(.columnM).foregroundStyle(cs.mut)
              Text(ratingFieldsShown ? "Done" : "Edit").csType(.agateS, caps: true).foregroundStyle(cs.ink)
            }
          }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Rating \(model.card.rating.isEmpty ? "not set" : model.card.rating), slope \(model.card.slope.isEmpty ? "not set" : model.card.slope)")
      .accessibilityHint(ratingFieldsShown ? "Hides the fields" : "Opens the rating and slope fields")
      if ratingFieldsShown {
        A11yStack(rowAlignment: .top, spacing: 10) {
          field("Rating") { numberField("72.1", Binding(get: { model.card.rating }, set: { model.typedRating($0) }), decimal: true).accessibilityLabel("Rating") }
          field("Slope") { numberField("128", $model.card.slope, decimal: false).accessibilityLabel("Slope") }
        }
        .padding(.top, 10)
        .transition(.opacity)
      }
      dateRow
    }
  }

  /// **IOS-066 · THE DAY IS ONE OF THE ROUND'S CIRCUMSTANCES, NOT A "DETAIL".**
  /// It was a `CSMini` under a `Details` head, and once the photograph and the
  /// scan left that head it was the only thing under it — a section head, a
  /// rule and 34pt of chrome for one chip (§27, "repetitive headers"). It
  /// belongs in the fold that already lists where the round was played, in the
  /// same row shape as the rating and the slope, under the line that already
  /// SHOWS the day and says `EDIT`.
  private var dateRow: some View {
    Button { showDate = true } label: {
      CSRow(last: true) {
        A11yStack(rowAlignment: .firstTextBaseline, spacing: 8, columnSpacing: 2) {
          Text("Day played").csType(.name).foregroundStyle(cs.mut)
          Spacer(minLength: 8)
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(CSHeaderDate.today(model.day)).csType(.columnM).foregroundStyle(cs.ink)
            Text("·").csType(.columnM).foregroundStyle(cs.mut)
            Text("Edit").csType(.agateS, caps: true).foregroundStyle(cs.ink)
          }
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Day played, \(CSHeaderDate.today(model.day))")
    .accessibilityHint("Opens the date picker")
  }

  /// Open only on "edit"; a picked tee or a course-memory row folds them back.
  private var ratingFieldsShown: Bool { ratingOpen }
  private var ratingLine: String { "\(model.card.rating.isEmpty ? "—" : model.card.rating) / \(model.card.slope.isEmpty ? "—" : model.card.slope)" }

  private func field<C: View>(_ label: String, @ViewBuilder _ content: () -> C) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.mut)
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func numberField(_ placeholder: String, _ text: Binding<String>, decimal: Bool) -> some View {
    CSField(placeholder, text: text).keyboardType(decimal ? .decimalPad : .numberPad)
  }

  // MARK: - Your card (the 18/9 seg, the two boxes, the strip)

  private var cardSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        // the eyebrow and the 18/9 seg share a line; at the accessibility sizes the seg takes the full width under it
        A11yStack(spacing: 8) {
          Text("The round").csEyebrow()   // F-13 · the FORM, not the profile
          Spacer(minLength: 8)
          PostSeg(options: [(18, "18 holes"), (9, "9 holes")], selection: model.card.side) { model.setSide($0) }
            .frame(maxWidth: typeSize.isA11y ? .infinity : 200)
        }
        CSRule()
      }
      .padding(.top, 12)
      if model.card.mode == .holes {
        PostScorecardStrip(model: model, selected: stripStart).padding(.top, 12)
      } else {
        totals.padding(.top, 12)
      }
    }
  }

  private var stripStart: Int {
    #if DEBUG
    PostRoundModel.devSelectedHole
    #else
    0
    #endif
  }

  /// D32: front & back — two large mono figures with the sum beside them in serif.
  private var totals: some View {
    let nine = model.card.side == 9
    let (f, b) = model.card.inputs
    let sum = f + b
    return VStack(alignment: .leading, spacing: 10) {
      // two big figures beside the sum; stacked at the accessibility sizes so a 28pt+ mono figure never clips
      A11yStack(rowAlignment: .top, spacing: 10) {
        bigField(nine ? "9-hole gross" : "Front 9 gross", "41", $model.card.f9)
        if !nine { bigField("Back 9 gross", "43", $model.card.b9) }
        VStack(alignment: .leading, spacing: 6) {
          CSFigure(sum > 0 ? "\(sum)" : "—", size: .m, label: "Gross")
            .contentTransition(.numericText())
        }
        .frame(minWidth: 64, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
      }
      CSFine("How most golfers keep it — 41 out, 43 in. Played just one nine? Fill that side only and it posts at half value, half a round.")
      // D34: the grid is opt-in — the seg stays hidden; this is its one door
      Button { model.setMode(.holes) } label: {
        // F-13 · the FORM's own noun. "Your card" is the profile sense (§2.1
        // row 2) and this opens the hole grid.
        Text("Enter it hole by hole")
      }
      .buttonStyle(.csTertiary(.content))
      .accessibilityHint("Opens the hole-by-hole card")
    }
  }

  private func bigField(_ label: String, _ placeholder: String, _ text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label).csType(.agate, caps: true).foregroundStyle(cs.mut)
      CSField(placeholder, text: text, font: CSFont.code).keyboardType(.numberPad).accessibilityLabel(label)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Point bands (3187–3197), folded

  /// D210 / Q-20 · the names and the points are the ENGINE's (`CSBands`, which
  /// is `cup_points()` verbatim) and the edges are the guide's, so the composer,
  /// the guide and the receipt cannot disagree. The hand-typed table this
  /// replaced named bands `CSBands` does not have and carried the pre-Q-20
  /// overlapping edges ("1–3" in two rows).
  private static let bands: [(Double, String)] = [
    (3, "beat it by 3 or more"), (1, "by 1 to 2.9"), (0, "less than 1 either way"),
    (-1, "1 to 3 over"), (-4, "more than 3 over"),
  ]

  /// D142 · the cap is the LEAGUE's, never a literal 4 — Standard counts the
  /// best 3, Cutthroat the best 2, Casual everything. With no cap in hand (an
  /// unlimited league, or no league at all) the sentence drops the number
  /// rather than naming one no league uses.
  private var countingLine: String {
    let stem = "Every posted round scores. Your best "
    let tail = " each month count toward your squad — a better round always replaces your lowest, in real time."
    guard let cap = model.membership?.settings?.counting_cap else { return stem + "few" + tail }   // the web's wording for the same unknown
    return stem + String(cap) + tail
  }

  private var bandsSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      Button { CSMotion.run { bandsOpen.toggle() } } label: {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("How points work").csEyebrow()
            Spacer()
            CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut)
              .rotationEffect(.degrees(bandsOpen ? -90 : 90))
          }
          .frame(minHeight: 34)
          CSRule()
        }
        .padding(.top, 8)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("How points work")
      .accessibilityValue(bandsOpen ? "expanded" : "collapsed")
      if bandsOpen {
        VStack(spacing: 0) {
          ForEach(Array(Self.bands.enumerated()), id: \.offset) { i, band in
            PostBandRow(label: "\(CSBands.bandName(band.0)) · \(band.1)",
                        value: String(CSBands.cupPoints(band.0)), last: i == Self.bands.count - 1)
          }
          // the fine print under the bands (web 3198)
          Text(countingLine)
            .csType(.bodyS).foregroundStyle(cs.mut)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
        }
        .transition(.opacity)
      }
    }
  }

  // MARK: - The bottom bar (`#postGrossLine`, `#postBtn`, `#postReset`)

  /// Abandonment is a real path, not a refresh: one tap empties the card.
  ///
  /// **THE 44pt MISS THE AUDIT NAMES, AND ITS CAUSE.** `// F-13` ran straight
  /// into `.foregroundStyle(cs.mut).frame(…minHeight: 44)`, so both modifiers
  /// were inside the comment: the label rendered in the inherited colour at
  /// whatever height 13pt of text is — about 20 — and the compiler had nothing
  /// to say about it. It is a tertiary now, which carries the 44pt target in
  /// the style rather than at the site.
  private var startOver: some View {
    Button("Start over — clear this round") { model.startOver() }   // F-13
      .buttonStyle(.csTertiary(.content))
      .frame(maxWidth: .infinity)
  }

  /// **IOS-064 · PINNED CHROME MAY NOT EAT THE PAGE.** `ax3-composer.png`:
  /// at AX3 this foot took roughly a THIRD of the viewport — a two-line live
  /// readout, a wrapped ember primary and a second wrapped action — and the
  /// scroll content above it was left reading four words a line through a slot
  /// the height of a business card. A pinned foot is chrome, and chrome that
  /// takes a third of a phone is not chrome any more.
  ///
  /// So when the window is short of room the foot carries only what has to be
  /// pinned: the live readout that answers the number being typed, and the one
  /// action the surface exists for. `Start over` is not urgent, is not the
  /// ranked act, and rides at the foot of the page instead — where a reader
  /// who wants to abandon can still reach it, and where it stops costing every
  /// OTHER reader a fifth of the screen they are trying to type into.
  ///
  /// **THE REVIEW WIDENED THE CONDITION FROM THE TYPE SIZE TO THE WINDOW.**
  /// `se-composer-BEFORE.png`: at the default reading size on a 375×667 phone
  /// this foot was 134pt of the 435pt the number pad leaves — 31 %, the same
  /// third the AX3 shot was condemned for. The type size was the way the
  /// damage was FOUND, not the thing that caused it.
  private var bottomBar: some View {
    VStack(spacing: 0) {
      CSRule()
      VStack(spacing: CSTokens.Space.s1) {
        Text(model.grossLine).csType(.columnM).foregroundStyle(cs.mut)
          .frame(maxWidth: .infinity).frame(minHeight: 22)
          .lineLimit(typeSize.isAccessibilitySize ? 2 : nil)
          .accessibilityAddTraits(.updatesFrequently)
        Button("Add my round") { model.tapPost() }
          .buttonStyle(.csPrimary(busy: model.busy))
        if !tightFoot { startOver }
      }
      .padding(.horizontal, 20).padding(.top, 6)
    }
    .background(cs.bg0)
  }
}

// MARK: - The hero: the live gross (IOS-020 "the gross is the hero and it is live")

/// **WAVE 7 · THE GROSS IS THE CANONICAL RULE-AND-FIGURE, AND IT LEAVES THE
/// CARD.** `leaderboard.md` §10 names this hero as the best-typeset object in
/// the product and the model the rest of the surface is derived from — and a
/// figure inside a container does not draw its rule (`CSFigure` suppresses it
/// under `csInContainer`, on purpose, because a panel's label hangs straight
/// off the numeral). So the dusk card goes, its `brand` wash with it (a
/// gradient wash is the one image state D272 bans by name), and the gross
/// stands on the page's own ground over its own 2pt rule.
private struct PostHeroCard: View {
  @Environment(\.cs) private var cs
  let model: PostRoundModel
  var focus: FocusState<Bool>.Binding
  let pickPhoto: () -> Void
  let pickScan: () -> Void
  var body: some View {
    PostHeroContent(model: model, focus: focus, pickPhoto: pickPhoto, pickScan: pickScan)
      .padding(.bottom, CSTokens.Space.s3)
      .accessibilityAddTraits(.updatesFrequently)
  }
}

/// Its own view so the hero's own arithmetic stays out of the screen's body.
private struct PostHeroContent: View {
  @Environment(\.cs) private var cs
  @Bindable var model: PostRoundModel
  var focus: FocusState<Bool>.Binding
  let pickPhoto: () -> Void
  let pickScan: () -> Void

  var body: some View {
    let p = model.preview
    VStack(alignment: .leading, spacing: 8) {
      Text(model.eyebrow).csEyebrow()
      // IOS-066 · THE NUMBER AND THE PICTURE, THE SAME SIZE, SIDE BY SIDE. The
      // figure column was 150pt wide with the rest of the measure empty, and
      // the camera was four sections below the fold. `PostCameraColumn` is the
      // figure's twin — same width, 3:2, quiet — and it costs no vertical
      // space that was not already blank. A column at the accessibility sizes,
      // where the figure grows and the plate takes the whole measure.
      // The plate is pinned to the TRAILING margin, not parked 12pt from the
      // figure: every other trailing element on this page sits on that margin
      // (the inherited row's `Edit`, the rating row's value, every band's
      // points), and a drawn box that stops 22pt short of it reads as a
      // mistake rather than as composition.
      A11yStack(rowAlignment: .top, spacing: CSTokens.Space.s3) {
        figureColumn(p)
        Spacer(minLength: CSTokens.Space.s3)
        PostCameraColumn(model: model, pickPhoto: pickPhoto, pickScan: pickScan)
      }
      // §6.5 · the sentence, and a number inside it is in the number's voice.
      CSFigureRun(sentence, role: .body).foregroundStyle(p == nil ? cs.mut : cs.ink)
      if let p {
        // **ONE agate line, and no tinted pills.** It was two: a points chip
        // and a `pos`/`neg` chip reading `+7.6 vs your playing HCP` — a signed
        // green figure saying, twelve points below it, exactly what the
        // sentence above already said (D201, one fact one place), in the
        // red/green P&L axis D273 retired. The points and the league are the
        // fact the sentence does NOT carry, so that is what stays.
        //
        // D124 (i) · with no number yet there is no points total and no signed
        // figure to show — only what the round was against the course.
        Text(p.provisional ? p.vsText : pointsText)
          .csType(.agateS, caps: true).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 2)
      }
      // D178 · it is no longer a 100% preview, so it must no longer say so.
      //
      // IOS-066 · AND IT ONLY SAYS SO WHEN THERE IS A PREVIEW. With no number
      // typed there is no calculation to disclaim, and on an SE this ran to
      // two lines of the small face at the very moment the screen has nothing
      // to preview — a caveat about arithmetic nobody has done yet. It is the
      // vertical the plate is paid for with, and §27's own list ("excessive
      // labels") names exactly this.
      if p != nil {
        CSFine("A preview — your season's own math scores it on the books.").padding(.top, 4)
      }
      if model.membership == nil {
        CSFine(LeagueCopy.noLeagueNote)
      }
    }
  }

  /// IOS-030 · ONE box, and it is the hero. A focused numeric input is a
  /// control, so it wears the mono figure face and never the serif (L-29).
  /// When the golfer opens the card and types their nines instead, the box
  /// stands down and shows what those nines add up to.
  /// THE RULE-AND-FIGURE: the numeral, a 2pt rule the width of its column,
  /// and the agate label beneath. The rule stays `ink` while the round is
  /// being typed — it is not live, and nothing here is earned.
  ///
  /// Its width is `PostCameraColumn.plateWidth`, not a literal 150, because
  /// the plate beside it is this column's TWIN and the two must move together.
  @ViewBuilder private func figureColumn(_ p: PostPreview?) -> some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
      if usesNines, let p {
        Text("\(p.gross)").csType(.figureXL).foregroundStyle(cs.ink)
          .contentTransition(.numericText())
      } else {
        // no prompt glyph: an em dash at the figure size reads as a redaction
        // bar, and the label beneath the rule already says what it wants
        TextField("", text: $model.card.whole)
          .csType(.figureXL).foregroundStyle(cs.ink)
          .keyboardType(.numberPad).focused(focus)
          .accessibilityLabel("Your gross")
      }
      CSRule(.heavy)
      Text(p.map { $0.holes == 9 ? "gross · 9 holes · half value" : "gross · 18 holes" } ?? "your gross")
        .csType(.agateS, caps: true).foregroundStyle(cs.mut)
    }
    .frame(width: PostCameraColumn.plateWidth, alignment: .leading)
  }

  /// The nines (or the strip) are carrying the card, so the one box stands down
  /// rather than offering a second place to type the same round (L-34).
  private var usesNines: Bool {
    model.card.mode == .holes || model.card.inputs.f9 > 0 || model.card.inputs.b9 > 0
  }

  /// The band phrase, the way the feed says it ("Beat your playing HCP by 2.4"); the web's empty-state lines until there is a card.
  /// The braces are `CSFigureRun`'s marks and never render; `vsPhraseMarked`
  /// is `vsPhrase`'s own words with the figure named, so the sentence and the
  /// chip beneath it can never disagree.
  private var sentence: String {
    guard let p = model.preview else { return model.calcMessage }
    if p.provisional { return p.message }   // D124 (i) · "No number yet — this round starts it"
    let s = CSBands.vsPhraseMarked(p.vs)
    return s.prefix(1).uppercased() + s.dropFirst()
  }

  /// "9 pts · PIGL" through the open league's lens; "posts to your rounds" without one.
  private var pointsText: String {
    guard let p = model.preview else { return "" }
    if let name = model.membership?.name { return "\(p.points) pts · \(name)" }
    return "posts to your rounds"
  }

}

// MARK: - A band row (the web's `table.bands` line)

private struct PostBandRow: View {
  @Environment(\.cs) private var cs
  let label: String
  let value: String
  let last: Bool
  var body: some View {
    CSRow(last: last) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(label).csType(.bodyS).foregroundStyle(cs.mut)
        Spacer(minLength: 8)
        Text(value).csType(.columnM).foregroundStyle(cs.ink)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

// MARK: - The date (`#inDate`), in a sheet

private struct PostDateSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Binding var day: Date
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      CSSheetHeader(title: "Date", sub: "THE DAY YOU PLAYED")
      DatePicker("Date", selection: $day, in: ...Calendar.current.date(byAdding: .day, value: 1, to: Date())!, displayedComponents: .date)
        .datePickerStyle(.graphical).labelsHidden().tint(cs.brand)
      Button("Set the day") { dismiss() }.buttonStyle(.csPrimary())
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(cs.bg0)
    .csFittedSheet(560, large: true)
  }
}

// MARK: - Previews: the filled states a simulator cannot type

#if DEBUG
@MainActor private func previewModel(_ seed: String) -> PostRoundModel {
  let m = PostRoundModel(store: SessionStore(), toast: CSToastCenter())
  m.devSeed(seed)
  return m
}

#Preview("front & back") {
  NavigationStack { PostRoundScreenPreview(model: previewModel("total")) }.environment(SessionStore()).csTheme()
}

#Preview("the strip") {
  NavigationStack { PostRoundScreenPreview(model: previewModel("strip")) }.environment(SessionStore()).csTheme()
}

/// IOS-022 item 9: the scorecard strip scrolls sideways under fixed cells — no figure clips.
#Preview("the strip · accessibility3") {
  NavigationStack { PostRoundScreenPreview(model: previewModel("strip")) }.environment(SessionStore())
    .environment(\.dynamicTypeSize, .accessibility3).csTheme()
}

#Preview("scan confirm") {
  NavigationStack { PostRoundScreenPreview(model: previewModel("scan")) }.environment(SessionStore()).csTheme()
}

private struct PostRoundScreenPreview: View {
  @Environment(\.cs) private var cs
  let model: PostRoundModel
  var body: some View {
    PostRoundBody(model: model, links: PostLinks(), pickPhoto: {}, pickScan: {}, onDone: {}).background(cs.bg0)
  }
}

/// IOS-066 · the composer top with a photograph already in the plate — the
/// state a scan lands in, and the one a simulator cannot type its way to.
#Preview("the plate, filled") {
  NavigationStack { PostRoundScreenPreview(model: previewModel("photo")) }.environment(SessionStore()).csTheme()
}
#endif
