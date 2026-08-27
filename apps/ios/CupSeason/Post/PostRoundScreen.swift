// Cup Season — Post a round (index.html `#view-post` 3097–3200; the logic
// 6119–6520). The 20-second quick post: course & tees, rating/slope (always
// editable), the card — front & back by default, the par-prefilled grid as
// the opt-in — the date, the photo and the scan, the live gross line, Post.
// "How this round scores" previews at 100%; the server scores the round.

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
  @Bindable var model: PostRoundModel
  let links: PostLinks
  let pickPhoto: () -> Void
  let pickScan: () -> Void
  let onDone: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text(model.eyebrow).csEyebrow()
        card
        calc
        bands
      }
      .padding(20)
    }
    .scrollDismissesKeyboard(.interactively)
    .navigationTitle("Post a round")
    .navigationBarTitleDisplayMode(.inline)
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

  // MARK: - the card (`.card`)

  private var card: some View {
    CSCard {
      VStack(alignment: .leading, spacing: 10) {
        field("Course & tees") {
          PostCourseSearchField(text: $model.card.course, courseId: $model.card.courseId) { model.teePicked(course: $0, tee: $1) }
          if !model.memory.isEmpty {
            FlowLayout(spacing: 6) {
              ForEach(model.memory) { m in CSMini(m.chip) { model.fill(m) } }
            }
          }
        }
        HStack(alignment: .top, spacing: 10) {
          field("Rating") { numberField("72.1", Binding(get: { model.card.rating }, set: { model.typedRating($0) }), decimal: true) }
          field("Slope") { numberField("128", $model.card.slope, decimal: false) }
        }
        HStack(alignment: .center, spacing: 8) {
          Text("Your card").font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
          Spacer(minLength: 0)
          PostSeg(options: [(18, "18 holes"), (9, "9 holes")], selection: model.card.side) { model.setSide($0) }.frame(maxWidth: 220)
        }
        .padding(.top, 2)

        if model.card.mode == .holes {
          PostHoleGrid(model: model)
        } else {
          let nine = model.card.side == 9
          HStack(alignment: .top, spacing: 10) {
            field(nine ? "9-hole gross" : "Front 9 gross") { numberField("41", $model.card.f9, decimal: false) }
            if !nine { field("Back 9 gross") { numberField("43", $model.card.b9, decimal: false) } }
          }
          CSFine("How most golfers keep it — 41 out, 43 in. Played just one nine? Fill that side only and it posts at half value, half a round.")
          // D34: the grid is opt-in — the seg stays hidden; this is its one door
          Button { model.setMode(.holes) } label: {
            Text("Enter your card").font(CSFont.footnote).foregroundStyle(cs.brand)
          }
          .frame(minHeight: 44)
        }

        field("Date") {
          DatePicker("Date", selection: $model.day, in: ...Calendar.current.date(byAdding: .day, value: 1, to: Date())!, displayedComponents: .date)
            .labelsHidden().tint(cs.brand)
        }

        photoRow

        Text(model.grossLine)
          .font(CSFont.subhead.weight(.bold)).foregroundStyle(cs.ink)
          .frame(maxWidth: .infinity, minHeight: 44)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
          .padding(.top, 4)
          .accessibilityAddTraits(.updatesFrequently)
        CSButton("Post round", busy: model.busy) { model.tapPost() }.padding(.top, 4)
        Button { model.startOver() } label: {
          Text("Start over — clear this card").font(CSFont.footnote).foregroundStyle(cs.mut).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
      }
    }
  }

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

  // MARK: - photo + scan (`#postPhotoRow`)

  private var photoRow: some View {
    VStack(alignment: .leading, spacing: 8) {
      FlowLayout(spacing: 8) {
        if model.scanEnabled {
          CSMini(model.scanning ? PostScan.readingLabel : "Scan the card", systemImage: "camera", busy: model.scanning, action: pickScan)
        }
        CSMini(model.photo == nil ? "Add a photo" : "Change photo", systemImage: "photo", action: pickPhoto)
        if model.photo != nil { CSMini("Remove", systemImage: "xmark") { model.setPhoto(nil) } }
      }
      if let img = model.photo {
        Image(uiImage: img).resizable().scaledToFill()
          .frame(maxWidth: .infinity).frame(height: 180).clipped()
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(cs.line2, lineWidth: 1))
          .accessibilityLabel("Round photo")
      }
    }
    .padding(.top, 2)
  }

  // MARK: - "How this round scores" (`.calc`)

  private var calc: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("How this round scores").csEyebrow().padding(.top, 8)
      CSCard {
        VStack(alignment: .leading, spacing: 6) {
          Text("League points this round").font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(cs.dimText)
          Text(model.preview.map { "\($0.points)" } ?? "–").font(CSFont.hero).csTabular().foregroundStyle(cs.ink)
          Text(model.calcMessage).font(CSFont.subhead).foregroundStyle(cs.mut)
          HStack(spacing: 18) {
            trio(model.preview.map { "\($0.gross)" } ?? "–", "Gross", tone: nil)
            trio(model.preview?.vsText ?? "–", "vs your index", tone: model.preview.map { $0.vs >= 0 ? cs.pos : cs.neg })
          }
          .padding(.top, 6)
          CSFine("No league yet? The round still counts on your card — points apply in any league you join.").padding(.top, 4)
          CSFine("A preview at 100% of your number — your league's own math scores it on the books.")
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.updatesFrequently)
    }
  }

  private func trio(_ v: String, _ k: String, tone: Color?) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(v).font(CSFont.stat).csTabular().foregroundStyle(tone ?? cs.ink)
      Text(k).font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText)
    }
  }

  // MARK: - Point bands (3187–3197)

  private var bands: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Point bands").csEyebrow().padding(.top, 8)
      CSCard {
        VStack(spacing: 0) {
          ForEach([("Beat your index by 3+", "12"), ("Beat it by 1–3", "9"), ("Within a stroke either way", "7"), ("Over by 1–3", "6"), ("Rough day, posted anyway", "5")], id: \.0) { k, v in
            MathRow(label: k, value: v)
          }
          CSFine("Every posted round scores. Your best 4 each month count toward your squad — a better round always replaces your lowest, in real time.").padding(.top, 10)
        }
      }
    }
  }
}
