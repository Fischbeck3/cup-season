// Cup Season — the golfer card, ONE SCROLLING FRAME (D247, IOS-033).
//
// WHAT THIS SCREEN USED TO BE. Three steps and eight surfaces: name, a REQUIRED
// @handle, a REQUIRED marker chosen from fourteen in-jokes with no default, and
// an optional index/GHIN. Two of the three required steps were choices the app
// could make, and one asked for a number most golfers do not have.
//
// WHAT IT IS NOW. One frame, one question, two defaults, and a footnote.
//
//   · THE NAME is asked, because it is the only thing on the card that is
//     genuinely theirs to say.
//   · THE HANDICAP is asked IN SCORES — "What do you usually shoot?" — and the
//     answer is a STARTER held on this device. It never reaches `profiles`:
//     D124 is an owner ruling and it declined seeding the engine from a
//     starter, so `p_index` is nil at Save and `score_round` reaches its own
//     differential exactly as D124 intended. The ME strip renders `STARTER 13`
//     (L-14) and the number becomes the golfer's own at three posted rounds.
//   · THE HANDLE is DEFAULTED from the name and shown, not asked. Still
//     editable, still checked against `handle_available`.
//   · THE MARKER is DEFAULTED from the handle and NAMED in a footnote. Tap it
//     and the fourteen open. L-24 holds: it is still the floor, still one of
//     the fourteen, still changeable, and no silhouette state is created.
//   · GHIN IS OFF ONBOARDING. It lives on the card, under You.
//
// THE GATE IS UNCHANGED AND STAYS `marker` AND `handle` (CLAUDE.md's landmine,
// `OnboardingGate` in the Kit). Defaulting is not skipping — the save writes
// both, so the m001 trigger's email-derived row still cannot pass.

import SwiftUI
import CSDesign
import CupSeasonKit

#if DEBUG
/// `-cs_dev_open card`: the gate over a signed-in simulator whatever the
/// session says. DEBUG only — the shipped build has no such door.
enum CardGateDev {
  static let forced: Bool = {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_open"), i + 1 < a.count else { return false }
    return a[i + 1] == "card"
  }()
}
#endif

struct CardGateView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let me: Me
  /// DEBUG only (`-cs_dev_open card`): show the frame as a NEW golfer meets it,
  /// on an account that already has a number. Nothing else reads it.
  var forceAsk = false
  @State private var name = ""
  @State private var handle = ""
  @State private var handleTouched = false
  @State private var marker: String = "saguaro"
  @State private var markerTouched = false
  @State private var pickingMarker = false
  @State private var band: ScoreBand? = nil
  @State private var busy = false
  @State private var note: (String, CSTone)? = nil
  @State private var handleCheck: (String, CSTone)? = nil
  @State private var handleTask: Task<Void, Never>? = nil
  private let claiming = ClaimIntent.pending() != nil

  private let svc = SupabaseService.shared
  /// Four across at reading sizes; two at the accessibility sizes so a marker's name is never clipped.
  private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 10), count: typeSize.isA11y ? 2 : 4) }
  /// A golfer who already has a number is not asked what they shoot.
  private var asksTheBand: Bool { forceAsk || me.profile?.index_current == nil }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text(OnboardingCopy.cardEyebrow).csEyebrow()
        Text(OnboardingCopy.cardTitle).font(CSFont.title).foregroundStyle(cs.ink)
        Text(OnboardingCopy.cardSub).font(CSFont.subhead).foregroundStyle(cs.mut)
        // the claim thread (web 2906): a guest who arrived by a claim link is told the card is the last step
        if claiming {
          Text("Saving your card attaches the round you’re claiming.").font(CSFont.subhead).foregroundStyle(cs.gold)
        }

        nameField
        if asksTheBand { bandQuestion }
        markerRow
        handleRow

        if let note { CSNote(note.0, tone: note.1) }

        CSButton(OnboardingCopy.save, busy: busy) { Task { await save() } }
          .padding(.top, 6)
        CSFine(OnboardingCopy.ghinMovedNote)
      }
      .padding(.horizontal, 24).padding(.bottom, 40)
      .padding(.top, 20)
    }
    .scrollDismissesKeyboard(.interactively)
    .onAppear { prefill() }
  }

  // MARK: the name

  private var nameField: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(OnboardingCopy.nameLabel).csEyebrow()
      CSField(OnboardingCopy.namePlaceholder, text: $name, font: CSFont.body)
        .textContentType(.name)
        .onChange(of: name) { _, new in
          if !handleTouched { handle = OnboardingGate.handle(from: new); checkHandle(handle) }
          if !markerTouched { marker = MarkerDefault.assign(handle: handle.isEmpty ? new.lowercased() : handle) }
        }
    }
  }

  // MARK: question 1 — in a golfer's units

  private var bandQuestion: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(OnboardingCopy.shootQuestion).csEyebrow()
      // A column at the accessibility sizes; a wrapped row otherwise. Five
      // options, each a 44pt target, none of them abbreviated.
      FlowLayout(spacing: 8) {
        ForEach(ScoreBand.allCases) { b in bandChip(b) }
      }
      // QB-08 · **SHOW THE ANSWER'S CONSEQUENCE WHERE THE ANSWER IS GIVEN.**
      //
      // `ScoreBand.stripPreview` produces `STARTER 20`, is unit-tested, and was
      // rendered nowhere — so the biggest figure on the first Home a golfer
      // ever sees arrived cold, ten minutes after the tap that caused it, and
      // three of six blind readers took it for a RANK. *"My first guess was
      // that 20 is a rank — I am 20th at something."* The band's own figure
      // belongs under the band's own chip, in the same type the strip will
      // use, so the golfer meets the number where they chose it.
      if let b = band {
        HStack(spacing: 8) {
          Text(b.stripPreview).font(CSFont.monoMediumBody).csTabular().foregroundStyle(cs.ink)
          Text(OnboardingCopy.stripPreviewNote).font(CSFont.footnote).foregroundStyle(cs.dimText)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(b.stripPreview). \(OnboardingCopy.stripPreviewNote)")
      }
      Text(OnboardingCopy.shootSub).font(CSFont.footnote).foregroundStyle(cs.dimText)
      if let b = band, b.starter != nil {
        Text(OnboardingCopy.shootStarterNote).font(CSFont.footnote).foregroundStyle(cs.mut)
      }
    }
  }

  private func bandChip(_ b: ScoreBand) -> some View {
    let on = band == b
    return Button {
      band = b; CSHaptic.selection()
    } label: {
      Text(b.title)
        .font(CSFont.monoMediumBody)
        .foregroundStyle(on ? cs.brand : cs.ink)
        .padding(.horizontal, 14).frame(minHeight: 44)
        .background(cs.bg1, in: Capsule())
        .overlay(Capsule().stroke(on ? cs.brand : cs.line, lineWidth: on ? 2 : 1))
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(b.title)
    .accessibilityAddTraits(on ? .isSelected : [])
  }

  // MARK: the marker — defaulted, named, changeable

  private var markerRow: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(OnboardingCopy.markerLabel).csEyebrow()
      Button {
        pickingMarker.toggle(); CSHaptic.selection()
      } label: {
        HStack(spacing: 12) {
          CSMarkerView(CSMarkers.marker(marker), size: 30).foregroundStyle(cs.brand)
          Text(MarkerDefault.name(marker)).font(CSFont.sentence).foregroundStyle(cs.ink)
          Spacer(minLength: 8)
          Text(pickingMarker ? "Close" : "Change").font(CSFont.footnote).foregroundStyle(cs.mut)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Ball marker, \(MarkerDefault.name(marker)). Change it.")
      if pickingMarker { markerGrid }
      CSFine(OnboardingCopy.markerFootnote(MarkerDefault.name(marker)))
    }
  }

  private var markerGrid: some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(CSMarkers.all) { m in
        Button {
          marker = m.key; markerTouched = true; pickingMarker = false; CSHaptic.selection()
        } label: {
          VStack(spacing: 8) {
            CSMarkerView(m, size: 34).foregroundStyle(marker == m.key ? cs.brand : cs.ink)
            Text(m.name).font(CSFont.label).foregroundStyle(cs.mut).lineLimit(typeSize.isA11y ? 2 : 1).minimumScaleFactor(0.7)
              .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity, minHeight: 78)
          .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous)
            .stroke(marker == m.key ? cs.brand : cs.line, lineWidth: marker == m.key ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(m.name)
        .accessibilityAddTraits(marker == m.key ? .isSelected : [])
      }
    }
  }

  // MARK: the handle — defaulted, shown, editable

  private var handleRow: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(OnboardingCopy.handleLabel).csEyebrow()
      CSField("handle", text: $handle)
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .onChange(of: handle) { _, new in
          let clean = new.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
          if clean != new { handle = clean } else if !clean.isEmpty { handleTouched = true }
          checkHandle(clean)
        }
      Text(OnboardingCopy.handleRule).font(CSFont.footnote).foregroundStyle(cs.dimText)
      if let handleCheck {
        Text(handleCheck.0).font(CSFont.footnote)
          .foregroundStyle(handleCheck.1 == .pos ? cs.pos : handleCheck.1 == .neg ? cs.neg : cs.mut)
          .accessibilityAddTraits(.updatesFrequently)
      }
    }
  }

  /// The web's `pfCheckHandle` (index.html 13043): a shape check at once, then
  /// 360 ms after the last keystroke the server answers "is it free?" —
  /// `handle_available` is the one RPC the gate calls before Save.
  private func checkHandle(_ h: String) {
    handleTask?.cancel()
    guard !h.isEmpty else { handleCheck = nil; return }
    guard OnboardingGate.handleIsLegal(h) else {
      handleCheck = ("Handle: 3–20 letters, numbers or underscores.", .mut); return
    }
    if h == me.profile?.handle { handleCheck = nil; return }   // it is already yours
    handleCheck = ("Checking @\(h)…", .mut)
    handleTask = Task {
      try? await Task.sleep(for: .milliseconds(360))
      guard !Task.isCancelled else { return }
      do {
        let free = try await svc.call(Rpc.handle_available(p_handle: h))
        guard !Task.isCancelled, handle == h else { return }
        handleCheck = free ? ("@\(h) is available ✓", .pos) : ("@\(h) is taken — tap to edit it.", .neg)
      } catch { if !Task.isCancelled, handle == h { handleCheck = nil } }
    }
  }

  // MARK: actions

  private func prefill() {
    // pre-fill only when the name isn't the email-derived default the signup trigger wrote
    if let n = me.profile?.display_name, let email = store.email,
       n.lowercased().replacingOccurrences(of: " ", with: "") != email.split(separator: "@").first.map(String.init)?.lowercased() {
      name = n
    }
    // D186 · Apple's one-shot name wins over the trigger's guess. It is the
    // only real name we will ever be given for a golfer who signed in with
    // Apple and hid their address, because the email is then a relay string
    // and the trigger derives the display name from it. Read-and-clear: it is
    // consumed here or not at all. Never overrides a name they already typed.
    if name.isEmpty, let appleName = AppleName.take() {
      name = appleName
    }
    if let h = me.profile?.handle, !h.isEmpty { handle = h; handleTouched = true }
    else if !name.isEmpty { handle = OnboardingGate.handle(from: name) }
    if let m = me.profile?.marker, !m.isEmpty { marker = m; markerTouched = true }
    else { marker = MarkerDefault.assign(handle: handle.isEmpty ? name.lowercased() : handle) }
  }

  private func save() async {
    guard !busy else { return }
    note = nil
    let typed = name.trimmingCharacters(in: .whitespaces)
    guard !typed.isEmpty else { note = (OnboardingCopy.nameMissing, .neg); return }
    // The handle is DEFAULTED, but a one-word nickname derives a handle the
    // server refuses — so it is named here rather than failing at set_handle.
    guard OnboardingGate.handleIsLegal(handle) else { note = (OnboardingCopy.handleBad, .neg); return }
    // a known-taken handle does not save; an unanswered check still does (the server refuses)
    if handleCheck?.1 == .neg { note = (handleCheck!.0, .neg); return }
    // The gate, as a value, before the write — so the two clients and the test
    // all read one predicate (CLAUDE.md: marker AND handle).
    guard OnboardingGate.passes(marker: marker, handle: handle) else {
      note = ("Your card needs a handle and a marker.", .neg); return
    }

    busy = true
    defer { busy = false }
    do {
      _ = try await svc.call(Rpc.set_handle(p_handle: handle))
      // D124's declined form: `p_index` is NIL. The band is the golfer's own
      // starting point, not the engine's input, and it stays on this device.
      _ = try await svc.call(Rpc.set_profile(p_name: typed, p_index: nil, p_marker: marker))
      if let band { StarterIndex.set(band) }
      CSTelemetry.product(.cardSet)   // IOS-024: the gate's successful save
      CSGrowth.profileCreated()       // growth funnel node 4, attributed to the pending claim / join
      CSHaptic.success()
      // D247 · the push ask does NOT follow the card any more. It follows the
      // first moment that earns it: a round, a buddy, a join.
      await store.reload()
    } catch {
      note = (AuthRules.human(error, fallback: "Save failed."), .neg)
    }
  }
}
