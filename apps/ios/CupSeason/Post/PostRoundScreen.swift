// Cup Season — Post a round as a scorecard, not a form (IOS-020; index.html
// `#view-post` 3097–3200, the logic 6119–6520). Every mechanic and every line
// of the web's copy is kept; the SHAPE is the phone's: the live gross is the
// hero, "where" is rows, the card is two big figures or the scorecard strip,
// details are pills, Post is pinned in the bottom bar, the bands fold away.
// "How this round scores" previews at 100%; the server scores the round.
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

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          PostHeroCard(model: model)
          whereSection
          cardSection.id("card")
          detailsSection.id("details")
          bandsSection.id("bands")
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
      }
      #if DEBUG
      // `-cs_dev_post_scroll <card|details|bands>`: a simulator without a finger reaches the fold
      .task {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-cs_dev_post_scroll"), i + 1 < a.count else { return }
        try? await Task.sleep(for: .seconds(1))
        if a[i + 1] == "bands" { bandsOpen = true }
        proxy.scrollTo(a[i + 1], anchor: .top)
      }
      #endif
    }
    .scrollDismissesKeyboard(.interactively)
    .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    .navigationTitle("Post a round")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        // "Play now" — the tee sheet stays one tap away from the composer (IOS-004 §2)
        Button { onDone(); links.openLive() } label: {
          Text("Play now").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.dawn)
        }
        .accessibilityHint("Opens the tee sheet to score a round live")
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
    .sheet(item: $model.epilogue, onDismiss: onDone) { EpilogueSheet(show: $0, photo: model.recapPhoto) }
    .sheet(item: $model.partners, onDismiss: onDone) { PostPartnersSheet(show: $0) }
  }

  // MARK: - Where (`#inCourse`, the chips, `#inRating` / `#inSlope`)

  private var whereSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSSectionHead("Course & tees").padding(.top, 8)
      PostCourseSearchField(text: $model.card.course, courseId: $model.card.courseId) { c, t in
        model.teePicked(course: c, tee: t)
        withAnimation(CSMotion.roll) { ratingOpen = false }   // the tee filled the line; the fields fold
      }
        .padding(.top, 12).padding(.bottom, 2)
      // course memory — ONLY while the search field is empty, so recents never read as stuck search results (they used to sit
      // under the field unconditionally and, with a failed search above them, looked exactly like a broken dropdown)
      if model.card.course.isEmpty && !model.memory.isEmpty {
        Text("Recent courses").csEyebrow().padding(.top, 6)
      }
      ForEach(model.card.course.isEmpty ? model.memory : []) { m in
        Button { model.fill(m); withAnimation(CSMotion.roll) { ratingOpen = false } } label: {
          CSRow {
            A11yStack(rowAlignment: .firstTextBaseline, spacing: 10, columnSpacing: 2) {
              Text(m.label).font(CSFont.subhead).foregroundStyle(cs.ink).multilineTextAlignment(.leading)
              Spacer(minLength: 8)
              Text("\(m.ratingText) / \(m.slope)").font(CSFont.monoSmall).foregroundStyle(cs.mut).csTabular()
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
      Button { withAnimation(CSMotion.roll) { ratingOpen.toggle() } } label: {
        CSRow(last: !ratingFieldsShown) {
          A11yStack(rowAlignment: .firstTextBaseline, spacing: 8, columnSpacing: 2) {
            Text("Rating / slope").font(CSFont.subhead).foregroundStyle(cs.mut)
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text(ratingLine).font(CSFont.monoSmall).foregroundStyle(cs.ink).csTabular()
              Text("·").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
              Text(ratingFieldsShown ? "done" : "edit").font(CSFont.monoSmall).foregroundStyle(cs.dawn)
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
    }
  }

  /// Open only on "edit"; a picked tee or a course-memory row folds them back.
  private var ratingFieldsShown: Bool { ratingOpen }
  private var ratingLine: String { "\(model.card.rating.isEmpty ? "—" : model.card.rating) / \(model.card.slope.isEmpty ? "—" : model.card.slope)" }

  private func field<C: View>(_ label: String, @ViewBuilder _ content: () -> C) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
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
          Text("Your card").csEyebrow()
          Spacer(minLength: 8)
          PostSeg(options: [(18, "18 holes"), (9, "9 holes")], selection: model.card.side) { model.setSide($0) }
            .frame(maxWidth: typeSize.isA11y ? .infinity : 200)
        }
        CSHairline()
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
          Text("Gross").font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
          Text(sum > 0 ? "\(sum)" : "—").font(CSFont.heroSmall).csTabular().foregroundStyle(sum > 0 ? cs.ink : cs.dimText)
            .frame(minHeight: 48).contentTransition(.numericText())
        }
        .frame(minWidth: 64, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
      }
      CSFine("How most golfers keep it — 41 out, 43 in. Played just one nine? Fill that side only and it posts at half value, half a round.")
      // D34: the grid is opt-in — the seg stays hidden; this is its one door
      Button { model.setMode(.holes) } label: {
        Text("Enter your card").font(CSFont.footnote).foregroundStyle(cs.brand).frame(minHeight: 44).contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint("Opens the hole-by-hole card")
    }
  }

  private func bigField(_ label: String, _ placeholder: String, _ text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
      CSField(placeholder, text: text, font: CSFont.code).keyboardType(.numberPad).accessibilityLabel(label)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Details (`#inDate`, `#postPhotoRow`)

  private var detailsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      CSSectionHead("Details").padding(.top, 8)
      FlowLayout(spacing: 8) {
        CSMini(CSHeaderDate.today(model.day), systemImage: "calendar") { showDate = true }
          .accessibilityLabel("Date, \(CSHeaderDate.today(model.day))")
        if model.scanEnabled {
          CSMini(model.scanning ? PostScan.readingLabel : "Scan the card", systemImage: "camera", busy: model.scanning, action: pickScan)
        }
        CSMini(model.photo == nil ? "Add a photo" : "Change photo", systemImage: "photo", action: pickPhoto)
        if model.photo != nil { CSMini("Remove", systemImage: "xmark") { model.setPhoto(nil) } }
      }
      .padding(.top, 2)
      if let img = model.photo {
        Image(uiImage: img).resizable().scaledToFill()
          .frame(maxWidth: .infinity).frame(height: 180).clipped()
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(cs.line2, lineWidth: 1))
          .accessibilityLabel("Round photo, attached")
      }
    }
  }

  // MARK: - Point bands (3187–3197), folded

  private static let bands = [("Beat your index by 3+", "12"), ("Beat it by 1–3", "9"), ("Within a stroke either way", "7"), ("Over by 1–3", "6"), ("Rough day, posted anyway", "5")]

  private var bandsSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      Button { withAnimation(CSMotion.roll) { bandsOpen.toggle() } } label: {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("How points work").csEyebrow()
            Spacer()
            Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(cs.mut)
              .rotationEffect(.degrees(bandsOpen ? 180 : 0))
          }
          .frame(minHeight: 34)
          CSHairline()
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
            PostBandRow(label: band.0, value: band.1, last: i == Self.bands.count - 1)
          }
          // the fine print under the bands (web 3198)
          Text("Every posted round scores. Your best 4 each month count toward your squad — a better round always replaces your lowest, in real time.")
            .font(CSFont.footnote).foregroundStyle(cs.dimText)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
        }
        .transition(.opacity)
      }
    }
  }

  // MARK: - The bottom bar (`#postGrossLine`, `#postBtn`, `#postReset`)

  private var bottomBar: some View {
    VStack(spacing: 0) {
      CSHairline()
      VStack(spacing: 4) {
        Text(model.grossLine).font(CSFont.monoSmall).foregroundStyle(cs.mut).csTabular()
          .frame(maxWidth: .infinity).frame(minHeight: 22)
          .accessibilityAddTraits(.updatesFrequently)
        CSButton("Post round", busy: model.busy) { model.tapPost() }
        // abandonment is a real path, not a refresh: one tap empties the card
        Button { model.startOver() } label: {
          Text("Start over — clear this card").font(CSFont.footnote).foregroundStyle(cs.mut).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 20).padding(.top, 6)
    }
    .background(cs.bg0)
  }
}

// MARK: - The hero: the live gross (IOS-020 "the gross is the hero and it is live")

private struct PostHeroCard: View {
  @Environment(\.cs) private var cs
  let model: PostRoundModel
  var body: some View {
    CSDuskCard(wash: cs.brand) { PostHeroContent(model: model) }
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.updatesFrequently)
  }
}

/// Its own view so `cs` resolves to the dusk card's dark palette.
private struct PostHeroContent: View {
  @Environment(\.cs) private var cs
  let model: PostRoundModel

  var body: some View {
    let p = model.preview
    VStack(alignment: .leading, spacing: 8) {
      Text(model.eyebrow).csEyebrow()
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(p.map { "\($0.gross)" } ?? "—").font(CSFont.figure).csTabular().foregroundStyle(p == nil ? cs.dimText : cs.ink)   // the empty dash is quiet, not a bar
          .contentTransition(.numericText())
        Text(p.map { $0.holes == 9 ? "9 holes · half value" : "18 holes" } ?? "gross").font(CSFont.monoSmall).foregroundStyle(cs.mut)
      }
      Text(sentence).font(CSFont.sentence).foregroundStyle(p == nil ? cs.mut : cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let p {
        FlowLayout(spacing: 8) {
          chip(pointsText, tone: cs.ink)
          chip(p.vsText + " vs your index", tone: p.vs >= 0 ? cs.pos : cs.neg)
        }
        .padding(.top, 2)
      }
      CSFine("A preview at 100% of your number — your league's own math scores it on the books.").padding(.top, 4)
      if model.membership == nil {
        CSFine("No league yet? The round still counts on your card — points apply in any league you join.")
      }
    }
  }

  /// The band phrase, the way the feed says it ("Beat your number by 2.4"); the web's empty-state lines until there is a card.
  private var sentence: String {
    guard let p = model.preview else { return model.calcMessage }
    let s = CSBands.vsPhrase(p.vs)
    return s.prefix(1).uppercased() + s.dropFirst()
  }

  /// "9 pts · PIGL" through the open league's lens; "counts on your card" without one.
  private var pointsText: String {
    guard let p = model.preview else { return "" }
    if let name = model.membership?.name { return "\(p.points) pts · \(name)" }
    return "counts on your card"
  }

  private func chip(_ text: String, tone: Color) -> some View {
    Text(text).font(CSFont.monoMediumBody).csTabular().foregroundStyle(tone).fixedSize(horizontal: false, vertical: true)
      .padding(.horizontal, 10).padding(.vertical, 6)
      .background(tone.opacity(0.12), in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
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
        Text(label).font(CSFont.subhead).foregroundStyle(cs.dimText)
        Spacer(minLength: 8)
        Text(value).font(CSFont.monoMediumBody).csTabular().foregroundStyle(cs.ink)
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
      CSButton("Done") { dismiss() }
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(cs.bg0)
    .presentationDetents([.height(560), .large])
    .presentationDragIndicator(.visible)
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
#endif
