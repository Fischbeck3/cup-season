// Cup Season — the golfer card, in three steps (IOS-004 #8; audit 01 §1.2).
//
// Name + @handle → marker (required, no default — every skipper was a saguaro)
// → optional starter index and GHIN. Save order is the web's: set_handle FIRST,
// then set_profile. "Just a name and a marker to start — this card follows you
// into every league."

import SwiftUI
import CSDesign
import CupSeasonKit

struct CardGateView: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let me: Me
  @State private var step = 0
  @State private var name = ""
  @State private var handle = ""
  @State private var handleTouched = false
  @State private var marker: String? = nil
  @State private var index = ""
  @State private var ghin = ""
  @State private var busy = false
  @State private var note: (String, CSTone)? = nil
  @State private var handleCheck: (String, CSTone)? = nil
  @State private var handleTask: Task<Void, Never>? = nil
  private let claiming = ClaimIntent.pending() != nil

  private let svc = SupabaseService.shared
  /// Four across at reading sizes; two at the accessibility sizes so a marker's name is never clipped.
  private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 10), count: typeSize.isA11y ? 2 : 4) }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        HStack(spacing: 6) {
          ForEach(0..<3) { i in
            Capsule().fill(i <= step ? cs.brand : cs.line2).frame(height: 3)
          }
        }
        .padding(.top, 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step + 1) of 3")

        Text("Your card").csEyebrow()
        Text(title).font(CSFont.title).foregroundStyle(cs.ink)
        Text(sub).font(CSFont.subhead).foregroundStyle(cs.mut)
        // the claim thread (web 2906): a guest who arrived by a claim link is told the card is the last step
        if claiming {
          Text("Saving your card attaches the round you’re claiming.").font(CSFont.subhead).foregroundStyle(cs.gold)
        }

        switch step {
        case 0: nameStep
        case 1: markerStep
        default: numberStep
        }

        if let note { CSNote(note.0, tone: note.1) }

        CSButton(step < 2 ? "Next" : "Save my card", busy: busy) { advance() }
          .padding(.top, 6)
        if step > 0 {
          Button { step -= 1; note = nil } label: {
            Text("Back").font(CSFont.subhead).foregroundStyle(cs.mut).frame(minHeight: 44).contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 24).padding(.bottom, 40)
    }
    .scrollDismissesKeyboard(.interactively)
    .onAppear { prefill() }
  }

  private var title: String {
    switch step {
    case 0: "Who's on the card?"
    case 1: "Pick your ball marker"
    default: "Know your number?"
    }
  }
  private var sub: String {
    switch step {
    case 0: "Just a name and a marker to start — this card follows you into every league."
    case 1: "It's your face here until you add a photo — and your stamp on every round after."
    default: "Optional. Your index builds itself at 3 posted rounds; a starter only helps before then."
    }
  }

  private var nameStep: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Name").csEyebrow()
      CSField("First and last", text: $name, font: CSFont.body)
        .textContentType(.name)
        .onChange(of: name) { _, new in if !handleTouched { handle = Self.derive(new) } }
      Text("@handle").csEyebrow().padding(.top, 6)
      CSField("handle", text: $handle)
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .onChange(of: handle) { _, new in
          let clean = new.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
          if clean != new { handle = clean } else if !clean.isEmpty { handleTouched = true }
          checkHandle(clean)
        }
      Text("3–20 letters, numbers or _. It changes once every 60 days.")
        .font(CSFont.footnote).foregroundStyle(cs.dimText)
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
    guard h.range(of: "^[a-z0-9_]{3,20}$", options: .regularExpression) != nil else {
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

  private var markerStep: some View {
    VStack(alignment: .leading, spacing: 10) {
      markerGrid
      Text("City and home course live on your card — add them any time from the You tab.")
        .font(CSFont.footnote).foregroundStyle(cs.dimText)
    }
  }

  private var markerGrid: some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(CSMarkers.all) { m in
        Button {
          marker = m.key; CSHaptic.selection()
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

  private var numberStep: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Starter index").csEyebrow()
      CSField("e.g. 12.4", text: $index).keyboardType(.decimalPad)
      Text("GHIN (a reference on your card — we never resell or verify it)").csEyebrow().padding(.top, 6)
      CSField("GHIN # · e.g. 1234567", text: $ghin).keyboardType(.numberPad)
      Text("Links your USGA record — that's identity, not your number. Your index still comes from your posted scores.")
        .font(CSFont.footnote).foregroundStyle(cs.dimText)
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
      if !handleTouched { handle = Self.derive(appleName) }
    }
    if let h = me.profile?.handle, !h.isEmpty { handle = h; handleTouched = true }
    marker = me.profile?.marker
    if let i = me.profile?.index_current { index = CSCopy.index(i) }
  }

  private static func derive(_ name: String) -> String {
    String(name.lowercased().filter { $0.isLetter || $0.isNumber }.prefix(20))
  }

  private func advance() {
    note = nil
    switch step {
    case 0:
      guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { note = ("Your name goes on the card.", .neg); return }
      guard handle.range(of: "^[a-z0-9_]{3,20}$", options: .regularExpression) != nil else {
        note = ("A handle is 3–20 letters, numbers or underscores.", .neg); return
      }
      // a known-taken handle does not advance; an unanswered check still does (the server refuses at Save)
      if handleCheck?.1 == .neg { note = (handleCheck!.0, .neg); return }
      step = 1
    case 1:
      guard marker != nil else { note = ("Pick your ball marker — it's your face here.", .neg); return }
      step = 2
    default:
      Task { await save() }
    }
  }

  private func save() async {
    guard !busy, let marker else { return }
    busy = true
    defer { busy = false }
    let idx = Double(index.replacingOccurrences(of: "+", with: "-"))
    if let idx, !(-10...54).contains(idx) { note = ("An index runs from +10 to 54.", .neg); return }
    do {
      try await svc.call(Rpc.set_handle(p_handle: handle))
      try await svc.call(Rpc.set_profile(p_name: name.trimmingCharacters(in: .whitespaces), p_index: idx, p_marker: marker,
                                         p_ghin: ghin.isEmpty ? nil : ghin))
      CSTelemetry.product(.cardSet)   // IOS-024: the gate's successful save
      CSGrowth.profileCreated()       // growth funnel node 4, attributed to the pending claim / join
      CSHaptic.success()
      PushAsk.shared.request(.cardSaved)   // D104 §6: the ask follows the moment, once Home is up
      await store.reload()
    } catch {
      note = (AuthRules.human(error, fallback: "Save failed."), .neg)
    }
  }
}
