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
        Text("📣 FROM THE PRO").csEyebrow(cs.gold)
        TextField("Message the league…", text: $text, axis: .vertical)
          .font(CSFont.body)
          .foregroundStyle(cs.ink)
          .lineLimit(3...8)
          .padding(12)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous)
            .stroke(focused ? cs.focus : cs.line, lineWidth: focused ? 2 : 1))
          .focused($focused)
          .onChange(of: text) { _, v in if v.count > 280 { text = String(v.prefix(280)) } }
        Text("\(text.count) / 280").font(CSFont.label).foregroundStyle(text.count >= 280 ? cs.neg : cs.dimText)
          .frame(maxWidth: .infinity, alignment: .trailing)
        CSButton("Announce", busy: busy) {
          busy = true
          Task {
            let ok = await store.announce(trimmed)
            busy = false
            if ok { dismiss() }
          }
        }
        .disabled(trimmed.isEmpty)
        .opacity(trimmed.isEmpty ? 0.6 : 1)
        Spacer()
      }
      .padding(20)
      .background(cs.bg0)
      .navigationTitle("Announce to the league")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundStyle(cs.mut) } }
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
        Text("KEEPS THE BOARDS CLEAN").csEyebrow()
        Text("What’s wrong with it? Your note goes to the founder desk with the post.")
          .font(CSFont.footnote).foregroundStyle(cs.mut)
        FlowRow(spacing: 6) {
          ForEach(reasons, id: \.self) { r in
            Button { why = r } label: {
              Text(r).font(CSFont.monoSmall)
                .padding(.horizontal, 12).frame(minHeight: 36)
                .foregroundStyle(why == r ? cs.bg0 : cs.ink)
                .background(why == r ? cs.brand : cs.bg2, in: Capsule())
                .overlay(Capsule().stroke(why == r ? cs.brand : cs.line2, lineWidth: 1))
            }
            .buttonStyle(.plain)
          }
        }
        TextField("Say what’s wrong…", text: $why, axis: .vertical)
          .font(CSFont.body)
          .foregroundStyle(cs.ink)
          .lineLimit(2...6)
          .padding(12)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
          .onChange(of: why) { _, v in if v.count > 500 { why = String(v.prefix(500)) } }
        CSButton("Send the report", busy: busy) {
          busy = true
          Task {
            let ok = await store.report(item.id, reason: why)
            busy = false
            if ok { dismiss() }
          }
        }
        CSButton("Cancel", style: .quiet) { dismiss() }
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
