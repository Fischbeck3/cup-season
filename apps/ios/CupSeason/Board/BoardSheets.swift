// Cup Season — the board's two action sheets.
//
//   AnnounceSheet  the Pro's 📣 (index.html 13862–13871) → `announce` RPC, 1–280 chars.
//                  The web overloads the chat input; native gives it its own sheet.
//   ReportSheet    `reportPost` (4834–4859) → `report_content`. An in-app sheet,
//                  never a system prompt — installed PWAs swallowed prompt() and a
//                  report died silently on a MODERATION path.

import SwiftUI
import CSDesign
import CupSeasonKit

struct AnnounceSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let store: BoardStore
  @State private var text = ""
  @State private var busy = false
  @FocusState private var focused: Bool

  private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 14) {
        Text("From the Pro").csType(.agate, caps: true).foregroundStyle(cs.gold)
        TextField("Message the league…", text: $text, axis: .vertical)
          .csType(.body)
          .foregroundStyle(cs.ink)
          .lineLimit(3...8)
          .padding(CSTokens.Space.s3)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          // §7.2 · no border; focus is the one 2px brand ring
          .overlay {
            if focused {
              RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous)
                .stroke(cs.brand, lineWidth: 2)
            }
          }
          .focused($focused)
          .onChange(of: text) { _, v in if v.count > 280 { text = String(v.prefix(280)) } }
        Text("\(text.count) / 280").csType(.agateS).foregroundStyle(text.count >= 280 ? cs.neg : cs.mut)
          .frame(maxWidth: .infinity, alignment: .trailing)
        Button("Announce") {
          busy = true
          Task {
            let ok = await store.announce(trimmed)
            busy = false
            if ok { dismiss() }
          }
        }
          .buttonStyle(.csPrimary(busy: busy))
        .disabled(trimmed.isEmpty)
        Spacer()
      }
      .padding(20)
      .background(cs.bg0)
      .navigationTitle("Announce to the league")
      .navigationBarTitleDisplayMode(.inline)
      .csCloseButton { dismiss() }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(CSTokens.Radius.rs)
    .onAppear { focused = true }
  }
}

struct ReportSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let item: BoardItem
  let store: BoardStore
  @State private var why = ""
  @State private var busy = false

  /// Quick reasons that prefill the note — the note itself is what travels.
  private let reasons = ["Spam", "Harassment", "Not their round", "Something else"]

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        Text("Keeps the boards clean").csType(.agate, caps: true).foregroundStyle(cs.mut)
        Text("What’s wrong with it? Your note goes to the founder desk with the post.")
          .csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
        FlowRow(spacing: 6) {
          ForEach(reasons, id: \.self) { r in
            Button { why = r } label: {
              CSChip(r, selected: why == r).frame(minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
        TextField("Say what’s wrong…", text: $why, axis: .vertical)
          .csType(.body)
          .foregroundStyle(cs.ink)
          .lineLimit(2...6)
          .padding(CSTokens.Space.s3)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .onChange(of: why) { _, v in if v.count > 500 { why = String(v.prefix(500)) } }
        Button("Send the report") {
          busy = true
          Task {
            let ok = await store.report(item.id, reason: why)
            busy = false
            if ok { dismiss() }
          }
        }
          .buttonStyle(.csPrimary(busy: busy))
        Button("Not now") { dismiss() }.buttonStyle(.csSecondary())
        Spacer()
      }
      .padding(20)
      .background(cs.bg0)
      .navigationTitle("Report this post")
      .navigationBarTitleDisplayMode(.inline)
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(CSTokens.Radius.rs)
  }
}
