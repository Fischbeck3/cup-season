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

  private let svc = SupabaseService.shared
  private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        HStack(spacing: 6) {
          ForEach(0..<3) { i in
            Capsule().fill(i <= step ? cs.brand : cs.line2).frame(height: 3)
          }
        }
        .padding(.top, 20)

        Text("Your card").csEyebrow()
        Text(title).font(CSFont.title).foregroundStyle(cs.ink)
        Text(sub).font(CSFont.subhead).foregroundStyle(cs.mut)

        switch step {
        case 0: nameStep
        case 1: markerStep
        default: numberStep
        }

        if let note { CSNote(note.0, tone: note.1) }

        CSButton(step < 2 ? "Next" : "Save my card", busy: busy) { advance() }
          .padding(.top, 6)
        if step > 0 {
          Button("Back") { step -= 1; note = nil }.font(CSFont.subhead).foregroundStyle(cs.mut)
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
        }
      Text("3–20 letters, numbers or _. It changes once every 60 days.")
        .font(CSFont.footnote).foregroundStyle(cs.dimText)
    }
  }

  private var markerStep: some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(CSMarkers.all) { m in
        Button {
          marker = m.key; CSHaptic.selection()
        } label: {
          VStack(spacing: 8) {
            CSMarkerView(m, size: 34).foregroundStyle(marker == m.key ? cs.brand : cs.ink)
            Text(m.name).font(CSFont.label).foregroundStyle(cs.mut).lineLimit(1).minimumScaleFactor(0.7)
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
      CSField("optional", text: $ghin).keyboardType(.numberPad)
    }
  }

  // MARK: actions

  private func prefill() {
    // pre-fill only when the name isn't the email-derived default the signup trigger wrote
    if let n = me.profile?.display_name, let email = store.email,
       n.lowercased().replacingOccurrences(of: " ", with: "") != email.split(separator: "@").first.map(String.init)?.lowercased() {
      name = n
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
      CSHaptic.success()
      await store.reload()
    } catch {
      note = (AuthRules.human(error, fallback: "Save failed."), .neg)
    }
  }
}
